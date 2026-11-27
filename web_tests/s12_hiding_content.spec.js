// L3 for S12 Hiding content from AT on web: what the page exposes for each
// example, and where Tab, Enter, Space, and a click go. Spec:
// docs/specs/S12-hiding-content.md. Runs against the release build in
// build/web.
import { test, expect } from '@playwright/test';
import { byId, tabTo, technique } from './support/techniques.js';
import {
  EXAMPLE_HEADING, EXAMPLE_SCREENS, EXPECTED_STOPS, helpRole, judgeExampleWalk, runWalks, screenStops, spokenRole,
} from './vo/s12_vo_walks.js';

// The example screen's own "Example" heading; the technique's page has
// "Good examples" and "Bad examples", so the name must match exactly.
const exampleHeading = (page) => page.getByRole('heading', { name: 'Example', exact: true, level: 2 });
const { open } = technique('S12', { ready: exampleHeading, settle: 600 });

const QUOTE = 'Walk the ridge before the sun is up.';
const SOURCE = 'Trail guide';
const TRACKING = 'Tracking number: 1Z 999';

/**
 * The example's own elements in the page's order: every semantics element
 * after the "Example" heading up to the example's count (or the end of the
 * screen) that has a role, a name, or text of its own, written as
 * `role "name"`. Unlike Chromium's ARIA snapshot, which runs neighbouring
 * texts into one line, this keeps one entry per element.
 */
async function exampleElements(page) {
  return page.evaluate(() => {
    const host = document.querySelector('flt-semantics-host');
    const all = [...host.querySelectorAll('flt-semantics, h1, h2, h3, h4, h5, h6')];
    const start = all.findIndex((e) => /^H2$/.test(e.tagName) && e.textContent.trim() === 'Example');
    const out = [];
    for (const e of all.slice(start + 1)) {
      const id = e.getAttribute('flt-semantics-identifier') ?? '';
      if (/^s12-.*-count$/.test(id)) break;
      const role = e.getAttribute('role') ?? (/^H\d$/.test(e.tagName) ? e.tagName.toLowerCase() : null);
      const label = e.getAttribute('aria-label');
      const own = [...e.childNodes].filter((n) => n.nodeType === 3 || n.tagName === 'SPAN')
        .map((n) => n.textContent).join('');
      const name = label ?? own;
      if (!role && !name) continue;
      out.push(`${role ?? 'text'} "${name.replace(/\n/g, '\\n')}"`);
    }
    if (start < 0) out.unshift('(no Example heading)');
    return out;
  });
}

/** Every name or text in the page's semantics, for checks that nothing shows a word. */
async function allTexts(page) {
  return page.evaluate(() => [...document.querySelectorAll('flt-semantics-host *')]
    .map((e) => e.getAttribute('aria-label') ?? (e.children.length === 0 ? e.textContent : ''))
    .filter((s) => s));
}

/** What has DOM focus: a Flutter element's text, or "(TAG)" for the page. */
const active = (page) => page.evaluate(() => {
  const e = document.activeElement;
  return e?.closest('flt-semantics-host') ? (e.getAttribute('aria-label') ?? e.textContent.trim()) : `(${e?.tagName})`;
});

const countOf = (page, slug) => byId(page, `s12-${slug}-count`).textContent();

/** Tab from the start of the screen through one whole cycle, back to Back. */
async function tabCycle(page) {
  const stops = [];
  for (let i = 0; i < 10; i++) {
    await page.keyboard.press('Tab');
    await page.waitForTimeout(150);
    const now = await active(page);
    if (i > 0 && now === 'Back' && stops[stops.length - 1] !== 'Back') return stops;
    stops.push(now);
  }
  throw new Error(`focus did not come back to Back: ${stops.join(' -> ')}`);
}

test.describe('good examples', () => {
  test('good-decoration: the quote and who said it, and no ornament anywhere in the page', async ({ page }) => {
    await open(page, 'good-decoration');
    expect(await exampleElements(page)).toEqual([`text "${QUOTE}"`, `text "${SOURCE}"`]);
    for (const t of await allTexts(page)) {
      expect(t).not.toContain('❝');
      expect(t).not.toContain('✦');
    }
    await expect(page.getByRole('button')).toHaveCount(1);
  });

  test('good-badge: the words alone, and no element "3"', async ({ page }) => {
    await open(page, 'good-badge');
    expect(await exampleElements(page)).toEqual(['text "Inbox: 3 unread"']);
    expect((await allTexts(page)).filter((t) => t.includes('3'))).toEqual(['Inbox: 3 unread']);
    await expect(page.getByRole('img')).toHaveCount(0);
  });

  test('good-visibility: hidden, the panel has no element and a whole Tab cycle is Back and the switch; shown, Tab reaches Copy', async ({ page }) => {
    await open(page, 'good-visibility');
    const show = byId(page, 's12-good-visibility-show');
    expect(await exampleElements(page)).toEqual(['switch "Show tracking"']);
    await expect(show).toHaveAttribute('aria-checked', 'false');
    expect(await allTexts(page)).not.toContain(TRACKING);
    await expect(page.getByRole('button', { name: 'Copy number' })).toHaveCount(0);
    const hidden = await tabCycle(page);
    expect(hidden.slice(0, 2)).toEqual(['Back', 'Show tracking']);
    expect(hidden.slice(2).every((s) => s.startsWith('(')), hidden.join(' -> ')).toBe(true);
    // Positive control, in the same load: shown, the panel is there, and
    // the keyboard reaches its button.
    await show.click();
    await expect(show).toHaveAttribute('aria-checked', 'true');
    expect(await exampleElements(page)).toEqual(['switch "Show tracking"', `text "${TRACKING}"`, 'button "Copy number"']);
    expect(await tabTo(page, byId(page, 's12-good-visibility-copy'))).toBe(true);
  });

  for (const key of ['Enter', 'Space']) {
    test(`good-visibility: hidden, Tab goes to the switch and then out of Flutter, and ${key} there copies nothing; shown, Tab to Copy and ${key} copies`, async ({ page }) => {
      await open(page, 'good-visibility');
      const show = byId(page, 's12-good-visibility-show');
      // Back, the switch, then out of Flutter's elements (FL-421).
      expect(await tabTo(page, show)).toBe(true);
      await page.keyboard.press('Tab');
      await page.waitForTimeout(150);
      expect(await active(page)).toMatch(/^\(/);
      await page.keyboard.press(key);
      await page.waitForTimeout(800);
      expect(await countOf(page, 'good-visibility')).toBe('Copies: 0');
      // In the same load: the switch, shown with the key, then Copy.
      expect(await tabTo(page, show)).toBe(true);
      await page.keyboard.press(key);
      await expect(show).toHaveAttribute('aria-checked', 'true');
      expect(await countOf(page, 'good-visibility')).toBe('Copies: 0');
      expect(await tabTo(page, byId(page, 's12-good-visibility-copy'))).toBe(true);
      await page.keyboard.press(key);
      await expect.poll(() => countOf(page, 'good-visibility'), { timeout: 3000 }).toBe('Copies: 1');
    });
  }

  test('good-visibility: shown, a click and a click from assistive technology on Copy each copy', async ({ page }) => {
    await open(page, 'good-visibility');
    await byId(page, 's12-good-visibility-show').click();
    await byId(page, 's12-good-visibility-copy').click();
    await expect.poll(() => countOf(page, 'good-visibility'), { timeout: 3000 }).toBe('Copies: 1');
    await byId(page, 's12-good-visibility-copy').evaluate((e) => e.click());
    await expect.poll(() => countOf(page, 'good-visibility'), { timeout: 3000 }).toBe('Copies: 2');
  });
});

test.describe('bad examples have their defect', () => {
  test('bad-decoration-read: each ornament is an element of its own, around the quote', async ({ page }) => {
    await open(page, 'bad-decoration-read');
    expect(await exampleElements(page)).toEqual(['text "❝"', `text "${QUOTE}"`, `text "${SOURCE}"`, 'text "✦ ✦ ✦"']);
  });

  test('bad-hidden-control: no element for Share, and no button but Back', async ({ page }) => {
    await open(page, 'bad-hidden-control');
    expect(await exampleElements(page)).toEqual([`text "${QUOTE}"`]);
    expect(await allTexts(page)).not.toContain('Share');
    await expect(page.getByRole('button')).toHaveCount(1);
    await expect(page.getByRole('button', { name: 'Back' })).toHaveCount(1);
  });

  for (const key of ['Enter', 'Space']) {
    test(`bad-hidden-control: after the second Tab the page's focus stays on Back, and ${key} shares and leaves the screen open; one Tab and ${key} leave it`, async ({ page }) => {
      await open(page, 'bad-hidden-control');
      for (let i = 0; i < 2; i++) {
        await page.keyboard.press('Tab');
        await page.waitForTimeout(200);
      }
      expect(await active(page)).toBe('Back');
      await page.keyboard.press(key);
      await expect.poll(() => countOf(page, 'bad-hidden-control'), { timeout: 3000 }).toBe('Shares: 1');
      await expect(exampleHeading(page)).toHaveCount(1);
      // Positive control, another load: the same key with focus on Back
      // leaves the screen.
      await open(page, 'bad-hidden-control');
      await page.keyboard.press('Tab');
      await page.waitForTimeout(200);
      expect(await active(page)).toBe('Back');
      await page.keyboard.press(key);
      await expect(exampleHeading(page)).toHaveCount(0, { timeout: 5000 });
    });
  }

  test('bad-hidden-control: a click where Share is drawn shares', async ({ page }) => {
    await open(page, 'bad-hidden-control');
    const quote = await page.locator('flt-semantics-host').getByText(QUOTE, { exact: true }).boundingBox();
    const count = await byId(page, 's12-bad-hidden-control-count').boundingBox();
    // Share is drawn between the quote and the count, after the ornament.
    const y = (quote.y + quote.height + count.y) / 2;
    let shared = false;
    for (const x of [100, 120, 140, 160]) {
      await page.mouse.click(quote.x + x, y);
      await page.waitForTimeout(500);
      if ((await countOf(page, 'bad-hidden-control')) !== 'Shares: 0') {
        shared = true;
        break;
      }
    }
    expect(shared, 'a click where Share is drawn').toBe(true);
  });

  test('bad-opacity: hidden, no element for the number or Copy; the third Tab leaves the page\'s focus on the switch, and Enter copies with the switch still off', async ({ page }) => {
    await open(page, 'bad-opacity');
    const show = byId(page, 's12-bad-opacity-show');
    expect(await exampleElements(page)).toEqual(['switch "Show tracking"']);
    expect(await allTexts(page)).not.toContain(TRACKING);
    await expect(page.getByRole('button', { name: 'Copy number' })).toHaveCount(0);
    expect(await tabTo(page, show)).toBe(true);
    await page.keyboard.press('Tab');
    await page.waitForTimeout(200);
    expect(await active(page)).toBe('Show tracking');
    await page.keyboard.press('Enter');
    await expect.poll(() => countOf(page, 'bad-opacity'), { timeout: 3000 }).toBe('Copies: 1');
    await expect(show).toHaveAttribute('aria-checked', 'false');
  });

  test('bad-opacity: hidden, Space at the same stop copies; and a click where Copy is laid out copies', async ({ page }) => {
    await open(page, 'bad-opacity');
    const show = byId(page, 's12-bad-opacity-show');
    expect(await tabTo(page, show)).toBe(true);
    await page.keyboard.press('Tab');
    await page.waitForTimeout(200);
    await page.keyboard.press('Space');
    await expect.poll(() => countOf(page, 'bad-opacity'), { timeout: 3000 }).toBe('Copies: 1');
    await expect(show).toHaveAttribute('aria-checked', 'false');
    const s = await show.boundingBox();
    const c = await byId(page, 's12-bad-opacity-count').boundingBox();
    // The panel's two lines lie between the switch and the count: Copy is the second.
    await page.mouse.click(s.x + 40, c.y - 20);
    await expect.poll(() => countOf(page, 'bad-opacity'), { timeout: 3000 }).toBe('Copies: 2');
  });

  test('bad-maintain: hidden, the number and Copy are elements as if shown, and Tab and Enter and Space copy with the switch off', async ({ page }) => {
    await open(page, 'bad-maintain');
    const show = byId(page, 's12-bad-maintain-show');
    expect(await exampleElements(page)).toEqual(['switch "Show tracking"', `text "${TRACKING}"`, 'button "Copy number"']);
    await expect(show).toHaveAttribute('aria-checked', 'false');
    const copy = byId(page, 's12-bad-maintain-copy');
    expect(await tabTo(page, copy)).toBe(true);
    await page.keyboard.press('Enter');
    await expect.poll(() => countOf(page, 'bad-maintain'), { timeout: 3000 }).toBe('Copies: 1');
    await page.keyboard.press('Space');
    await expect.poll(() => countOf(page, 'bad-maintain'), { timeout: 3000 }).toBe('Copies: 2');
    await expect(show).toHaveAttribute('aria-checked', 'false');
  });
});

// What the VoiceOver spec expects above each example's "Example" heading
// (EXAMPLE_SCREENS in vo/s12_vo_walks.js): each screen must show those
// texts, so that a change to a title or a defect is caught here.
test.describe('the stops the VoiceOver spec expects above each example', () => {
  for (const [slug, [title, ...lines]] of Object.entries(EXAMPLE_SCREENS)) {
    test(`${slug} shows its title and its lines`, async ({ page }) => {
      await open(page, slug);
      await expect(page.getByRole('heading', { name: title, exact: true, level: 1 })).toHaveCount(1);
      for (const line of lines) await expect(page.getByText(line, { exact: true })).toHaveCount(1);
    });
  }
});

// How the web VoiceOver spec judges one walk (judgeExampleWalk, S08's judge)
// and repeats one that fell short (runWalks). The walks here are made up;
// VoiceOver is not used.
test.describe('the VoiceOver example walks are judged on every walk', () => {
  const own = screenStops('bad-maintain');
  const expected = EXPECTED_STOPS['bad-maintain'];
  const [sw, number, copy, count] = expected;
  const HELP = 'You are currently on a switch, inside of web content. To exit this web area, press Control-Option-Shift-Up Arrow.';
  const BUTTON_HELP = 'You are currently on a button, inside of web content. To click this button, press Control-Option-Space.';
  const screen = (...content) => [...own, EXAMPLE_HEADING, ...content];
  const cases = [
    ['the whole screen, every stop in its place', screen(...expected), true, 'complete'],
    ['the hidden panel not read', screen(sw, count), true, 'wrong'],
    ['a stop read in other words', screen(sw, number, 'Copy button', count), true, 'wrong'],
    ['the stops swapped', screen(sw, copy, number, count), true, 'wrong'],
    ['the count missing', screen(sw, number, copy), true, 'wrong'],
    ['a stop after the last expected one', screen(...expected, 'Extra'), true, 'wrong'],
    ['an empty stop put in, so that every later stop comes late', screen('', ...expected), true, 'wrong'],
    ['the title read as an empty phrase, every later stop right', ['', ...own.slice(1), EXAMPLE_HEADING, ...expected], true, 'incomplete'],
    ['a stop read as an empty phrase, every other stop right', screen(sw, '', copy, count), true, 'incomplete'],
    ['an empty first stop and a wrong reading later', ['', ...own.slice(1), EXAMPLE_HEADING, sw, 'Copy', copy, count], true, 'wrong'],
    ['an empty first stop and a walk that reached the end short', ['', ...own.slice(1), EXAMPLE_HEADING, sw], true, 'wrong'],
    ['an empty phrase after the last expected stop', screen(...expected, ''), true, 'wrong'],
    ['every stop an empty phrase', Array(8).fill(''), true, 'incomplete'],
    ['a help message, with no positions', screen(sw, HELP, number, copy, count), true, 'wrong'],
    ['no title', [own[1], EXAMPLE_HEADING, ...expected], true, 'wrong'],
    ['no defect', [own[0], own[1], EXAMPLE_HEADING, ...expected], true, 'wrong'],
    ['no heading', [...own, ...expected], true, 'wrong'],
    ['an empty walk cut short', [], false, 'incomplete'],
    ['a walk cut short after the heading', screen(), false, 'incomplete'],
    ['every stop read, but the end not reached', screen(...expected), false, 'incomplete'],
  ];
  for (const [what, stops, reachedEnd, verdict] of cases) {
    test(`${what}: ${verdict}`, () => {
      expect(judgeExampleWalk(stops, reachedEnd, expected, own).verdict).toBe(verdict);
    });
  }

  // A help message is left out only when the walk's positions tie it to the
  // stop before it: same position, a reading before it, and its role in
  // that reading (helpAfterStop). This rule is tested only on these made-up
  // walks: no recording has had a help message with positions.
  const at = (stops, same = []) => {
    const out = [];
    stops.forEach((_, i) => out.push(same.includes(i) ? out[i - 1] : `p${i}`));
    return out;
  };
  const whole = screen(...expected);
  const n = whole.length;
  const afterSwitch = own.length + 2;
  const helpCases = [
    ['switch help after the switch, at its position: left out',
      screen(sw, HELP, number, copy, count), at(screen(sw, HELP, number, copy, count), [afterSwitch]), 'complete'],
    ['button help after Copy, at its position: left out',
      screen(sw, number, copy, BUTTON_HELP, count), at(screen(sw, number, copy, BUTTON_HELP, count), [afterSwitch + 2]), 'complete'],
    ['switch help at a new position after the whole screen (an extra element): fails', [...whole, HELP], at([...whole, HELP]), 'wrong'],
    ['button help after the count, a text with no role, at its position: fails', [...whole, BUTTON_HELP], at([...whole, BUTTON_HELP], [n]), 'wrong'],
    ['switch help after Copy, at its position: fails (the roles differ)',
      screen(sw, number, copy, HELP, count), at(screen(sw, number, copy, HELP, count), [afterSwitch + 2]), 'wrong'],
    ['help in place of an expected stop: fails', screen(sw, HELP, copy, count), at(screen(sw, HELP, copy, count)), 'wrong'],
    ['help after an empty stop, at its position: fails', screen(sw, '', HELP, copy, count),
      at(screen(sw, '', HELP, copy, count), [afterSwitch + 1]), 'wrong'],
    ['help with positions of the wrong length: fails', [...whole, HELP], at(whole), 'wrong'],
    ['switch help after the title heading, at its position: fails', [own[0], HELP, ...whole.slice(1)],
      at([own[0], HELP, ...whole.slice(1)], [1]), 'wrong'],
  ];
  for (const [what, stops, positions, verdict] of helpCases) {
    test(`${what}: ${verdict}`, () => {
      expect(judgeExampleWalk(stops, true, expected, own, positions).verdict).toBe(verdict);
    });
  }

  test('a reading\'s spoken role comes from its role part only', () => {
    expect(spokenRole('heading level 1 Panel hidden from everyone')).toBe('heading');
    expect(spokenRole('Show tracking off switch')).toBe('switch');
    expect(spokenRole('Show tracking on switch')).toBe('switch');
    expect(spokenRole('Copy number button')).toBe('button');
    expect(spokenRole('Copies: 0')).toBe(null);
    expect(spokenRole(TRACKING)).toBe(null);
    expect(spokenRole('Defect: A screen reader cannot find the Share button; the keyboard still reaches it.')).toBe(null);
  });

  test('a help message names the role it is about', () => {
    expect(helpRole(HELP)).toBe('switch');
    expect(helpRole(BUTTON_HELP)).toBe('button');
    expect(helpRole('Copies: 0')).toBe(null);
  });

  test('a bad example\'s own stops include its defect', () => {
    for (const slug of Object.keys(EXAMPLE_SCREENS).filter((s) => s.startsWith('bad-'))) {
      expect(screenStops(slug).at(-1), slug).toMatch(/^Defect: /);
    }
  });

  test('no screen has a custom solution note', () => {
    for (const slug of Object.keys(EXAMPLE_SCREENS)) {
      expect(screenStops(slug).some((s) => s.startsWith('Custom solution')), slug).toBe(false);
    }
  });

  const judge = (stops, reachedEnd) => judgeExampleWalk(stops, reachedEnd, expected, own);
  const sequence = (...list) => {
    let i = 0;
    return { walkOnce: async () => list[i++], made: () => i };
  };
  const right = { stops: screen(...expected), reachedEnd: true };
  const short = { stops: screen(sw), reachedEnd: false };

  for (const [what, walk] of [
    ['a wrong reading', { stops: screen(sw, count), reachedEnd: true }],
    ['a walk that reached the end without Copy', { stops: screen(sw, number, count), reachedEnd: true }],
  ]) {
    test(`${what} followed by a right walk fails, and no second walk is made`, async () => {
      const { walkOnce, made } = sequence(walk, right);
      expect((await runWalks(walkOnce, judge)).verdict).toBe('wrong');
      expect(made()).toBe(1);
    });
  }

  const emptyTitle = { stops: ['', ...own.slice(1), EXAMPLE_HEADING, ...expected], reachedEnd: true };

  test('an empty first stop is walked again, and a right walk then passes on the second', async () => {
    const { walkOnce, made } = sequence(emptyTitle, right);
    expect(await runWalks(walkOnce, judge)).toMatchObject({ verdict: 'complete', walks: 2 });
    expect(made()).toBe(2);
  });

  test('an empty first stop, then a wrong reading on the re-walk, fails, and no third walk is made', async () => {
    const { walkOnce, made } = sequence(emptyTitle, { stops: screen(sw, count), reachedEnd: true }, right);
    expect((await runWalks(walkOnce, judge)).verdict).toBe('wrong');
    expect(made()).toBe(2);
  });

  test('three empty captures fail, and no fourth walk is made', async () => {
    const { walkOnce, made } = sequence(emptyTitle, emptyTitle, emptyTitle, right);
    expect(await runWalks(walkOnce, judge)).toMatchObject({ verdict: 'incomplete', walks: 3 });
    expect(made()).toBe(3);
  });

  test('a complete walk plus an empty stop past the end fails, and no second walk is made', async () => {
    const { walkOnce, made } = sequence({ stops: screen(...expected, ''), reachedEnd: true }, right);
    expect((await runWalks(walkOnce, judge)).verdict).toBe('wrong');
    expect(made()).toBe(1);
  });

  test('a wrong walk after a short one still fails, and no third walk is made', async () => {
    const { walkOnce, made } = sequence(short, { stops: screen(sw, count), reachedEnd: true }, right);
    expect((await runWalks(walkOnce, judge)).verdict).toBe('wrong');
    expect(made()).toBe(2);
  });

  test('a walk cut short followed by a right one passes on the second', async () => {
    const { walkOnce, made } = sequence(short, right);
    expect(await runWalks(walkOnce, judge)).toMatchObject({ verdict: 'complete', walks: 2 });
    expect(made()).toBe(2);
  });

  test('three walks cut short fail', async () => {
    const { walkOnce } = sequence(short, short, short, right);
    expect(await runWalks(walkOnce, judge)).toMatchObject({ verdict: 'incomplete', walks: 3 });
  });

  test('every try of an example walk is logged', async () => {
    const { walkOnce } = sequence(short, short, right);
    const logged = [];
    await runWalks(walkOnce, judge, { log: (n, stops, judged) => logged.push([n, judged.verdict]) });
    expect(logged).toEqual([[1, 'incomplete'], [2, 'incomplete'], [3, 'complete']]);
  });
});
