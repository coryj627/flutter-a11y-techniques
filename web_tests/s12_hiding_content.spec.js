// L3 for S12 Hiding content from AT on web: what the page exposes for each
// example, and where Tab, Enter, Space, and a click go. Spec:
// docs/specs/S12-hiding-content.md. Runs against the release build in
// build/web.
import { readFileSync } from 'node:fs';
import { test, expect } from '@playwright/test';
import { byId, tabTo, technique } from './support/techniques.js';
import {
  BROWSERS, EXAMPLE_HEADING, EXAMPLE_SCREENS, EXPECTED_STOPS, TRANSCRIPT_ROWS, collectWalk, endRow, helpRole,
  judgeCollectedWalk, judgeExampleWalk, judgeTranscript, judgeWalk, positionsRow, runWalks, screenStops,
  spokenRole, startRow, stopsOf, stopsText, transcriptRow, unresolvedRow,
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
    test(`good-visibility: hidden, the Tab after the switch leaves Flutter's elements, with no stop for Copy; ${key} on the switch shows the panel and copies nothing; then Tab to Copy and ${key} copies`, async ({ page }) => {
      await open(page, 'good-visibility');
      const show = byId(page, 's12-good-visibility-show');
      // Back, the switch, then out of Flutter's elements (FL-421): no stop
      // for Copy while it is hidden. No key is pressed there: a key on the
      // page would have no effect to witness.
      expect(await tabTo(page, show)).toBe(true);
      await page.keyboard.press('Tab');
      await page.waitForTimeout(150);
      expect(await active(page)).toMatch(/^\(/);
      // In the same load: the switch, and the key on it. The witness that
      // the key acted is the switch turned on; only then is "copies
      // nothing" a claim.
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

// How the web VoiceOver spec judges one walk's stops (judgeWalk, S16's, on
// S08's judgeExampleWalk). The walks here are made up; VoiceOver is not
// used. Each test names every case it holds.
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
    // A walk that ran out of moves is wrong (Codex, fourth review): with
    // 40 moves it can only have gone on past the screen.
    ['an empty walk that ran out of moves', [], false, 'wrong'],
    ['a walk that ran out of moves after the heading', screen(), false, 'wrong'],
    ['every stop read, but the end not reached', screen(...expected), false, 'wrong'],
  ];
  test(`the judge: whole screens, wrong readings, short walks, and empty captures (${cases.length} cases)`, () => {
    for (const [what, stops, reachedEnd, verdict] of cases) {
      expect(judgeWalk(stops, reachedEnd, expected, own).verdict, what).toBe(verdict);
    }
  });

  // A help message is left out only when the walk's positions tie it to the
  // stop before it: same position, a reading before it, and its role in
  // that reading (helpAfterStop). This rule is tested only on these made-up
  // walks: no S12 recording has had a help message.
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
  test(`a help message is left out only when tied to the stop before it, by position and spoken role (${helpCases.length} cases)`, () => {
    for (const [what, stops, positions, verdict] of helpCases) {
      expect(judgeWalk(stops, true, expected, own, positions).verdict, what).toBe(verdict);
    }
  });

  test('a reading\'s spoken role comes from its role part only, and a help message names its role', () => {
    const roles = [
      ['heading level 1 Panel hidden from everyone', 'heading'],
      ['Show tracking off switch', 'switch'],
      ['Show tracking on switch', 'switch'],
      ['Copy number button', 'button'],
      ['Copies: 0', null],
      [TRACKING, null],
      ['Defect: A screen reader cannot find the Share button; the keyboard still reaches it.', null],
    ];
    for (const [reading, role] of roles) expect(spokenRole(reading), reading).toBe(role);
    expect(helpRole(HELP)).toBe('switch');
    expect(helpRole(BUTTON_HELP)).toBe('button');
    // VoiceOver's other wording (S08's ninth web recording).
    expect(helpRole('You are currently in a empty group.')).toBe('group');
    expect(helpRole('You are currently in a list, inside of web content.')).toBe('list');
    expect(helpRole('Copies: 0')).toBe(null);
  });
});

// S16's regression cases (web_tests/s16_language_page_parts.spec.js),
// carried over to S12's screens. VO_SLUG is the example the made-up walks
// are drawn on; WRONG_TITLE is another S12 example's title, read where
// VO_SLUG's is expected; TIED is a help message that the positions tie to
// the stop before it (helpAfterStop), at `after` in the whole screen of
// `slug`.
const VO_SLUG = 'bad-maintain';
const WRONG_TITLE = `heading level 1 ${EXAMPLE_SCREENS['good-visibility'][0]}`;
const TIED = {
  slug: 'bad-maintain',
  after: screenStops('bad-maintain').length + 1,
  help: 'You are currently on a switch, inside of web content. To exit this web area, press Control-Option-Shift-Up Arrow.',
};
const VO_HELP_PREFIX = /^You are currently (?:on|in) /;

// How the walks are made again (runWalks), judged by judgeWalk as the
// VoiceOver spec's walks are, and the screens and lists every judge reads.
// Each test names every case it holds, and fails on the first case whose
// verdict is not the one given, with the case's name.
test.describe('the VoiceOver walks are made again only while incomplete', () => {
  const own = screenStops(VO_SLUG);
  const expected = EXPECTED_STOPS[VO_SLUG];
  const whole = [...own, EXAMPLE_HEADING, ...expected];

  test('every screen: a bad example\'s own stops end with its defect, no screen has a custom solution note, and no expected stop is empty or help', () => {
    for (const slug of Object.keys(EXAMPLE_SCREENS)) {
      if (slug.startsWith('bad-')) expect(screenStops(slug).at(-1), slug).toMatch(/^Defect: /);
      expect(screenStops(slug).some((s) => s.startsWith('Custom solution')), slug).toBe(false);
    }
    for (const [row, { expected: stops, screen }] of Object.entries(TRANSCRIPT_ROWS)) {
      for (const s of [...screen, ...stops]) expect(s !== '' && !VO_HELP_PREFIX.test(s), `${row}: "${s}"`).toBe(true);
    }
  });

  test('walks are made again only while incomplete, at most three, every try is logged, and a wrong walk ends the example', async () => {
    const judge = (stops, reachedEnd) => judgeWalk(stops, reachedEnd, expected, own);
    const right = { stops: whole, reachedEnd: true };
    const short = { stops: whole.slice(0, 3), reachedEnd: false };
    const wrong = { stops: [WRONG_TITLE, ...whole.slice(1)], reachedEnd: true };
    const emptyTitle = { stops: ['', ...whole.slice(1)], reachedEnd: true };
    const pastEnd = { stops: [...whole, ''], reachedEnd: true };
    const cases = [
      ['a wrong reading, then a right walk', [wrong, right], 'wrong', 1],
      ['a complete walk plus an empty stop past the end, then a right walk', [pastEnd, right], 'wrong', 1],
      ['an empty first stop, then a right walk', [emptyTitle, right], 'complete', 2],
      ['an empty first stop, then a wrong reading, then a right walk', [emptyTitle, wrong, right], 'wrong', 2],
      ['three empty captures, then a right walk', [emptyTitle, emptyTitle, emptyTitle, right], 'incomplete', 3],
      // A walk that ran out of moves is wrong for good (judgeWalk, rule 4).
      ['a walk that ran out of moves, then a right one', [short, right], 'wrong', 1],
      ['an empty first stop, then a walk that ran out of moves, then a right one', [emptyTitle, short, right], 'wrong', 2],
    ];
    for (const [what, walks, verdict, made] of cases) {
      let i = 0;
      const logged = [];
      const result = await runWalks(async () => walks[i++], judge, { log: (w, stops, judged) => logged.push([w, judged.verdict]) });
      expect(result.verdict, what).toBe(verdict);
      expect(i, `${what}: walks made`).toBe(made);
      expect(logged.map(([w]) => w), `${what}: every try logged`).toEqual(Array.from({ length: made }, (_, k) => k + 1));
    }
  });
});

// The walk (collectWalk in web_tests/vo/s12_vo_walks.js), driven by made-up
// screens and captures: a screen is a list of elements, each a phrase at a
// position; `next` and `previous` move a cursor over it, and `capture`
// reads what a capture function makes of the element the cursor is on.
test.describe('the VoiceOver walk keeps every unchanged read and needs a witness for its end', () => {
  const slug = VO_SLUG;
  const own = screenStops(slug);
  const expected = EXPECTED_STOPS[slug];
  const words = [...own, EXAMPLE_HEADING, ...expected];
  const at = (i) => `${10 + i}, ${100 + 20 * i}, 300, ${118 + 20 * i}`;
  // The capture before the first move: the walk begins on Back.
  const START = { phrase: 'Back button', position: '10, 60, 300, 78' };
  /** A screen of `elements` ({ phrase, position }) and a capture rule. */
  const drive = (elements, reads = (cursor, el, count) => el, max = 40) => {
    let cursor = -1;
    let count = 0;
    return collectWalk({
      next: async () => { cursor = Math.min(cursor + 1, elements.length - 1); },
      previous: async () => { cursor = Math.max(cursor - 1, 0); },
      capture: async () => { count++; return reads(cursor, elements[cursor], count); },
      start: START,
      max,
    });
  };
  const screen = words.map((phrase, i) => ({ phrase, position: at(i) }));
  const judge = (walk) => judgeCollectedWalk(walk, expected, own);
  const heading = own.length; // the index of the Example heading
  const extra = { phrase: 'Extra', position: at(90) };
  const injected = [...screen.slice(0, heading + 1), extra, ...screen.slice(heading + 1)];
  // A capture that loses the move onto the element at `index` of
  // `elements`, once: it reads the previous element again (stale), or an
  // empty phrase at the previous bounds. A later capture there, the end
  // witness's included, reads the element.
  const losing = (elements, index, as = 'stale') => {
    let lost = false;
    return (c, el) => {
      if (c !== index || lost) return el;
      lost = true;
      return as === 'stale' ? elements[index - 1] : { phrase: '', position: elements[index - 1].position };
    };
  };
  const wrongTitle = [{ phrase: WRONG_TITLE, position: at(0) }, ...screen.slice(1)];
  const atStart = (c, el, n) => (n === 1 ? { phrase: WRONG_TITLE, position: START.position } : el);
  const run = async (walks) => {
    let i = 0;
    let latest;
    const result = await runWalks(async () => { latest = walks[i++]; return latest; }, () => judge(latest));
    return { ...result, made: i };
  };

  test('made-up walks: a whole screen passes, and each fault fails or is not complete', async () => {
    const right = await drive(screen);
    expect(judge(right).verdict, 'the whole screen').toBe('complete');
    expect(right.witness.back).toEqual(screen.at(-2));
    expect(right.witness.forward).toEqual(screen.at(-1));
    expect(right.unresolved).toEqual([]);
    expect(right.positions).toEqual(screen.map((e) => e.position));

    let frozenAt = -1;
    const cases = [
      // The capture froze at the heading: every later element reads as the
      // heading at its position, so the walk looks ended there, and the
      // move back reads the heading again at its own position.
      ['a frozen capture with elements after it', await drive(screen, (c, el) => {
        if (el.phrase === EXAMPLE_HEADING && frozenAt < 0) frozenAt = c;
        return frozenAt >= 0 ? screen[frozenAt] : el;
      }), 'wrong'],
      // From the heading on every read is an empty phrase at the heading's
      // position.
      ['empty phrases with frozen bounds', await drive(screen, (c, el) => (c >= heading
        ? { phrase: '', position: at(heading) } : el)), 'wrong'],
      // The move back at the end reads the last element again where it is.
      ['a wrong witness: the move back reads the last stop', await drive(screen, (c, el, n) => (n === words.length + 3
        ? screen.at(-1) : el)), 'wrong'],
      ['a wrong witness: the move back reads an empty phrase', await drive(screen, (c, el, n) => (n === words.length + 3
        ? { phrase: '', position: at(words.length - 2) } : el)), 'wrong'],
      ['a wrong witness: the move back reads the right words at the last stop\'s position', await drive(screen, (c, el, n) => (n === words.length + 3
        ? { phrase: words.at(-2), position: at(words.length - 1) } : el)), 'wrong'],
      ['a wrong witness: the move forward reads another place', await drive(screen, (c, el, n) => (n === words.length + 4
        ? { phrase: words.at(-1), position: '1, 1, 1, 1' } : el)), 'wrong'],
      ['a wrong witness: the move forward reads another stop', await drive(screen, (c, el, n) => (n === words.length + 4
        ? { phrase: 'Extra', position: at(words.length - 1) } : el)), 'wrong'],
      // One stale read at an element mid-walk (the previous phrase and
      // bounds), then the walk moves on: that element is never a stop.
      ['one stale read at an unexpected element mid-walk', await drive(injected,
        (c, el) => (el === extra ? screen[heading] : el)), 'incomplete'],
      // One empty read at an element mid-walk, at the previous bounds.
      ['one empty read at an unexpected element mid-walk', await drive(injected,
        (c, el) => (el === extra ? { phrase: '', position: screen[heading].position } : el)), 'incomplete'],
      // A repeated heading mid-walk at the heading's bounds.
      ['the Example heading read again mid-walk at its bounds', await drive(
        [...screen.slice(0, heading + 1), screen[heading], ...screen.slice(heading + 1)]), 'incomplete'],
      // A walk that runs out of moves is wrong for good (judgeWalk, rule 4).
      ['a walk exhausted at the move limit', await drive(screen, undefined, 3), 'wrong'],
      ['a screen of one stop', await drive(screen.slice(0, 1)), 'wrong'],
      // A help message read after the last element, at its position, is a
      // stop (new words), the walk's last; the witness's move back then
      // reads the element before it, not the stop before the last, so the
      // walk fails for good: the help rule cannot leave it out. (S08's
      // fourth recording read a list's help after "end of list".)
      ['a help message at the last element\'s position, after its reading', await drive(screen, (c, el, n) => (
        n > words.length && c === words.length - 1 ? { phrase: TIED.help, position: at(words.length - 1) } : el)), 'wrong'],
    ];
    for (const [what, walk, verdict] of cases) {
      expect(judge(walk).verdict, `${what}: ${JSON.stringify(walk)}`).toBe(verdict);
    }
  });

  test('the reviewer\'s frozen capture, with elements after the last expected stop, would pass without the witness, and fails with it', async () => {
    const elements = [...screen, { phrase: 'Extra 0', position: at(80) }, extra];
    const walk = await drive(elements, (c, el) => (c >= screen.length ? screen.at(-1) : el));
    expect(walk.stops).toEqual(words);
    expect(judgeExampleWalk(walk.stops, true, expected, own).verdict).toBe('complete');
    expect(walk.witness.back).toEqual(screen.at(-1));
    expect(walk.problem).toMatch(/^the end is not witnessed/);
    expect(judge(walk).verdict).toBe('wrong');
  });

  test('a lost capture (stale, or empty at the old bounds) is a gap: incomplete when nothing is wrong, wrong for good otherwise', async () => {
    // At an unexpected element mid-walk: the stops are exactly the screen,
    // and only the unresolved read shows an element went unrecorded.
    for (const as of ['stale', 'empty']) {
      const walk = await drive(injected, losing(injected, heading + 1, as));
      expect(walk.stops, as).toEqual(words);
      expect(walk.reachedEnd, as).toBe(true);
      expect(walk.problem, as).toBeNull();
      // Without the unresolved read the stops would judge complete.
      expect(judgeExampleWalk(walk.stops, true, expected, own).verdict, as).toBe('complete');
      const phrase = as === 'empty' ? '' : EXAMPLE_HEADING;
      expect(walk.unresolved, as).toEqual([{ after: heading + 1, phrase, position: at(heading) }]);
      expect(judge(walk).verdict, as).toBe('incomplete');
      expect(unresolvedRow(slug, 1, walk.unresolved), as).toBe(
        `| \`${slug}-walk-1-unresolved\` | after stop ${heading + 1}: "${phrase}" at ${at(heading)} |`);
    }
    // At an expected stop: the stops lack it, which alone judges wrong; the
    // gap makes the walk incomplete, walked again.
    // Three from the end, so that neither of the last two, which the
    // witness reads, is the one lost.
    const lostAt = words.length - 3;
    const lost = await drive(screen, losing(screen, lostAt));
    expect(lost.stops).toEqual(words.filter((_, i) => i !== lostAt));
    expect(lost.unresolved).toEqual([{ after: lostAt, phrase: words[lostAt - 1], position: at(lostAt - 1) }]);
    expect(judgeExampleWalk(lost.stops, true, expected, own).verdict).toBe('wrong');
    expect(judge(lost).verdict).toBe('incomplete');
    // At the stop before the last: the move back reads it, which the stops
    // do not have before the last, so the witness fails, for good.
    const beforeLast = await drive(screen, losing(screen, screen.length - 2));
    expect(beforeLast.unresolved).toHaveLength(1);
    expect(beforeLast.problem).toMatch(/^the end is not witnessed: a move back read/);
    expect(judge(beforeLast).verdict).toBe('wrong');
  });

  // judgeWalk: an unresolved read is a gap in the walk, never a pass for
  // what was captured around it.
  test('a wrong verdict wins over a gap, and a gap passes over at most the next expected stop', async () => {
    const extraFirst = [...screen.slice(0, heading + 1), extra, { phrase: 'Extra 2', position: at(91) }, ...screen.slice(heading + 1)];
    const wrongAfter = [...screen.slice(0, heading + 1), extra, { phrase: 'Wrong', position: at(92) }, ...screen.slice(heading + 2)];
    const cases = [
      ['a wrong title, then one stale read', await drive(wrongTitle, losing(wrongTitle, 2)), 'wrong'],
      ['a wrong title, then one empty read', await drive(wrongTitle, losing(wrongTitle, 2, 'empty')), 'wrong'],
      // An extra stop captured before the read that was lost.
      ['an extra stop before the lost read', await drive(extraFirst, losing(extraFirst, heading + 2)), 'wrong'],
      // A wrong stop captured after the gap.
      ['a wrong stop after the gap', await drive(wrongAfter, losing(wrongAfter, heading + 1)), 'wrong'],
      // A right prefix, one lost read, then the next expected stop (the
      // lost read was an extra element) or the one after it (the lost read
      // was the next expected stop): both stay incomplete.
      ['a right prefix, one lost extra element, then the next expected stop', await drive(injected, losing(injected, heading + 1)), 'incomplete'],
      ['a right prefix, one lost expected stop, then the one after it', await drive(screen, losing(screen, words.length - 3)), 'incomplete'],
    ];
    for (const [what, walk, verdict] of cases) {
      expect(judge(walk).verdict, `${what}: ${JSON.stringify(walk.stops)} ${JSON.stringify(walk.unresolved)}`).toBe(verdict);
    }
    // The same rule on stops alone, with gaps given as "after stop K".
    const byGaps = (stops, gaps, reachedEnd = true) => judgeWalk(stops, reachedEnd, expected, own, undefined, gaps).verdict;
    const gapCases = [
      ['a gap after the heading, then the next expected stop', words, [heading + 1], 'incomplete'],
      ['a gap after the heading, then the stop after the next', words.filter((_, i) => i !== heading + 1), [heading + 1], 'incomplete'],
      ['a gap, then a stop two places on', [...words.slice(0, heading), words.at(-1)], [heading], 'wrong'],
      ['a wrong title before a gap', [WRONG_TITLE, ...words.slice(1)], [heading + 1], 'wrong'],
      ['a stop past the end after a gap', [...words, 'Extra'], [heading + 1], 'wrong'],
      ['the end reached with an expected stop neither read nor lost', words.slice(0, -1), [1], 'wrong'],
      ['a walk that ran out of moves, with a gap', words, [heading + 1], 'wrong', false],
      ['no gap, every stop right', words, [], 'complete'],
    ];
    for (const [what, stops, gaps, verdict, reachedEnd] of gapCases) {
      expect(byGaps(stops, gaps, reachedEnd), what).toBe(verdict);
    }
  });

  // The fourth review of S16's walk: the first capture reads a wrong title
  // at the start's bounds (Back's, which had not changed yet). Compared
  // with the start capture, its words are new, so it is a stop, judged
  // wrong.
  test('a wrong first title at the start bounds is a stop, judged wrong, not a gap', async () => {
    const elements = [{ phrase: 'x', position: START.position }, ...screen.slice(1)];
    const walk = await drive(elements, atStart);
    expect(walk.unresolved).toEqual([]);
    expect(walk.stops[0]).toBe(WRONG_TITLE);
    expect(walk.start).toEqual(START);
    expect(judge(walk).verdict).toBe('wrong');
    // A first capture that repeats the start at its bounds is a gap, and
    // the next stop the title: incomplete, walked again.
    const repeat = await drive([{ phrase: 'x', position: START.position }, ...screen],
      (c, el, n) => (n === 1 ? START : el));
    expect(repeat.unresolved).toEqual([{ after: 0, phrase: START.phrase, position: START.position }]);
    expect(judge(repeat).verdict).toBe('incomplete');
    // No unresolved read carries words other than the previous stop's.
    for (const w of [walk, repeat]) {
      for (const u of w.unresolved) expect([w.stops[u.after - 1] ?? START.phrase, '']).toContain(u.phrase);
    }
  });

  test('in the retry loop a wrong walk ends the example, and a clean walk after it is never made', async () => {
    const cases = [
      ['a wrong first title at the start bounds', [await drive([{ phrase: 'x', position: START.position }, ...screen.slice(1)], atStart)]],
      ['a wrong title, then one stale read', [await drive(wrongTitle, losing(wrongTitle, 2))]],
      ['a wrong title, then one empty read', [await drive(wrongTitle, losing(wrongTitle, 2, 'empty'))]],
      ['a walk exhausted at the move limit', [await drive(screen, undefined, 3)]],
      ['a wrong title, then a stale read, after a walk with a gap and nothing wrong', [await drive(injected, losing(injected, heading + 1)),
        await drive(wrongTitle, losing(wrongTitle, 2))]],
    ];
    for (const [what, walks] of cases) {
      const result = await run([...walks, await drive(screen)]);
      expect(result.verdict, what).toBe('wrong');
      expect(result.made, what).toBe(walks.length);
    }
    // A walk with a gap and nothing wrong, then a clean one: complete on the second.
    const healed = await run([await drive(injected, losing(injected, heading + 1)), await drive(screen)]);
    expect(healed).toMatchObject({ verdict: 'complete', walks: 2, made: 2 });
  });

  test('an unchanged read at the true end is the end, through the witness, and every row is logged', async () => {
    const walk = await drive(screen);
    expect(walk.reachedEnd).toBe(true);
    expect(unresolvedRow(slug, 1, walk.unresolved)).toBe(`| \`${slug}-walk-1-unresolved\` | none |`);
    expect(endRow(slug, 1, walk.witness)).toBe(
      `| \`${slug}-walk-1-end\` | back "${words.at(-2)}" at ${at(words.length - 2)} / forward "${words.at(-1)}" at ${at(words.length - 1)} |`);
    expect(startRow(slug, 1, walk.start)).toBe(`| \`${slug}-walk-1-start\` | "Back button" at 10, 60, 300, 78 |`);
    expect(positionsRow(slug, 1, walk.positions)).toBe(
      `| \`${slug}-walk-1-positions\` | ${words.map((_, i) => at(i)).join(' / ')} |`);
    const lost = await drive(injected, losing(injected, heading + 1));
    expect(lost.reachedEnd).toBe(true);
    expect(lost.witness).toEqual({ back: screen.at(-2), forward: screen.at(-1) });
    expect(judge(lost).verdict).toBe('incomplete');
  });
});

// The committed web VoiceOver transcript, judged again from its rows alone
// (judgeTranscript in web_tests/vo/s12_vo_walks.js), never skipped: every
// browser and row once, walks in order, the last complete, each walk with
// its start, positions and unresolved-reads rows and the last with its end
// witness row. Made-up transcripts test the judge first.
test.describe('the web VoiceOver transcript is judged again from what it recorded', () => {
  const rows = Object.keys(TRANSCRIPT_ROWS);
  const R = rows[0];
  const whole = (row) => [...TRANSCRIPT_ROWS[row].screen, EXAMPLE_HEADING, ...TRANSCRIPT_ROWS[row].expected];
  const pos = (i) => `318, ${251 + 40 * i}, 1011, ${271 + 40 * i}`;
  const placesOf = (stops) => stops.map((_, i) => pos(i));
  const witnessOf = (stops) => ({ back: { phrase: stops.at(-2), position: pos(stops.length - 2) }, forward: { phrase: stops.at(-1), position: pos(stops.length - 1) } });
  const BACK = { phrase: '', position: '30, 147, 70, 187' };
  // A walk's rows as the VoiceOver spec logs them; `end` false leaves out
  // the end row, as for a walk that ran out of moves.
  const walkRows = (row, n, stops, verdict, { end = true, unresolved = [], positions = placesOf(stops), start = BACK } = {}) => [
    transcriptRow(row, n, stops, verdict, 'x'), startRow(row, n, start), positionsRow(row, n, positions),
    ...(end ? [endRow(row, n, witnessOf(stops))] : []), unresolvedRow(row, n, unresolved)];
  const rowsOf = (row, n = 1) => walkRows(row, n, whole(row), 'complete');
  const section = (browser, lines) => ['', `## ${browser}`, '', '| Example | Spoken, in order |', '| --- | --- |', ...lines];
  const transcript = (rowsFor) => ['# S12 Hiding content from AT: VoiceOver transcript (web, macOS)', '',
    'Result: PASS', ...BROWSERS.flatMap((b) => section(b, rowsFor(b)))].join('\n');
  const right = () => rows.flatMap((row) => rowsOf(row));
  // R's walks replaced by `first`, then a complete second walk.
  const thenRight = (first) => transcript(() => [...first, ...rowsOf(R, 2), ...rows.slice(1).flatMap((x) => rowsOf(x))]);
  const replaced = (prefix, line) => transcript(() => right().map((r) => (r.startsWith(`| \`${R}-walk-1${prefix}\``) ? line : r)));
  const w = whole(R);
  const h = w.indexOf(EXAMPLE_HEADING);
  // The tied help message, in TIED.slug's walk, at the position of the stop
  // before it, or at a new one.
  const helped = [...whole(TIED.slug).slice(0, TIED.after + 1), TIED.help, ...whole(TIED.slug).slice(TIED.after + 1)];
  const tiedAt = placesOf(helped).map((p, i) => (i === TIED.after + 1 ? pos(TIED.after) : p));
  const withHelp = (positions) => transcript(() => rows.flatMap((row) => (row === TIED.slug
    ? walkRows(row, 1, helped, 'complete', { positions }) : rowsOf(row))));
  const ROW_KINDS = ['', '-start', '-positions', '-end', '-unresolved'];

  test('made-up transcripts: a right one passes, and each wrong one names its problem', () => {
    const one = transcriptRow(R, 1, w, 'complete', 'x');
    // A stop with " / " or a backslash in it is written escaped and read
    // back whole (S10's bad-merged reads "3.4 / 5").
    const odd = ['Rating: 3.4 / 5 Reviews', '', 'a\\b', '(x)'];
    expect(stopsOf(stopsText(odd))).toEqual(odd);
    expect(stopsText(odd).split(' / ')).toHaveLength(odd.length);
    const exhausted = Array.from({ length: 20 }, (_, i) => w[i % w.length]);
    const cases = [
      ['a whole walk of every row in both browsers', transcript(right), true],
      ['an empty transcript', '', false],
      ['fourteen copies of one walk row', transcript(() => Array(7).fill(one)), false],
      ['fourteen copies of one walk\'s rows', transcript(() => Array(7).fill(rowsOf(R)).flat()), false],
      // Each kind of row removed, from every walk.
      ...ROW_KINDS.map((kind) => [`every ${kind || 'walk'} row removed`,
        transcript(() => right().filter((r) => !new RegExp(`^\\| \`[a-z-]+-walk-\\d+${kind}\` \\|`).test(r))), false]),
      // Each kind of row removed from one walk only.
      ...ROW_KINDS.map((kind) => [`${R}'s ${kind || 'walk'} row removed in WebKit`,
        transcript((b) => right().filter((r) => b !== 'webkit' || !r.startsWith(`| \`${R}-walk-1${kind}\` |`))), false]),
      // Each kind of row given twice.
      ...ROW_KINDS.map((kind) => [`${R}'s ${kind || 'walk'} row twice`,
        transcript(() => { const all = right(); return [...all, all.find((r) => r.startsWith(`| \`${R}-walk-1${kind}\` |`))]; }), false]),
      // Each kind of row for a walk that is not there.
      ...ROW_KINDS.slice(1).map((kind) => [`a ${kind} row for a walk that is not there`,
        transcript(() => [...right(), rowsOf(R, 2).find((r) => r.startsWith(`| \`${R}-walk-2${kind}\` |`))]), false]),
      ['a row missing in one browser', transcript((b) => (b === 'webkit' ? right().slice(5) : right())), false],
      ['a browser section missing', ['Result: PASS', ...section('chromium', right())].join('\n'), false],
      ['an unknown browser section', [transcript(right), ...section('firefox', [])].join('\n'), false],
      ['an unknown example', transcript(() => [...right(), ...walkRows('good-other', 1, w, 'complete')]), false],
      ['a malformed row', transcript(() => [...right(), `| \`${R}-walk-x\` | something |`]), false],
      ['a row outside any section', [one, transcript(right)].join('\n'), false],
      ['walk 2 with no walk 1', transcript(() => right().map((r) => r.replace(`${R}-walk-1`, `${R}-walk-2`))), false],
      ['the last walk recorded wrong', replaced('', transcriptRow(R, 1, w, 'wrong', 'x')), false],
      ['the last walk recorded incomplete', replaced('', transcriptRow(R, 1, w, 'incomplete', 'x')), false],
      ['the old form, only what follows the heading', transcript(() => rows.flatMap((row) =>
        walkRows(row, 1, TRANSCRIPT_ROWS[row].expected, 'complete'))), false],
      ['another row\'s screen stops', replaced('', transcriptRow(R, 1, [...TRANSCRIPT_ROWS[rows.at(-1)].screen, ...w.slice(h)], 'complete', 'x')), false],
      ['a walk whose title is an empty phrase', replaced('', transcriptRow(R, 1, ['', ...w.slice(1)], 'complete', 'x')), false],
      ['a stop past the end, empty', transcript(() => rows.flatMap((row) => (row === R ? walkRows(R, 1, [...w, ''], 'complete') : rowsOf(row)))), false],
      // The end witness row.
      ['an end row whose positions are one word', replaced('-end', `| \`${R}-walk-1-end\` | back "x" at here / forward "y" at here |`), false],
      ['an end witness that read back the last stop', replaced('-end', endRow(R, 1, { back: witnessOf(w).forward, forward: witnessOf(w).forward })), false],
      ['an end witness that read back an empty phrase', replaced('-end', endRow(R, 1, { back: { phrase: '', position: '1, 2, 3, 4' }, forward: witnessOf(w).forward })), false],
      ['an end witness whose move back read the right words at the last position', replaced('-end',
        endRow(R, 1, { back: { phrase: witnessOf(w).back.phrase, position: witnessOf(w).forward.position }, forward: witnessOf(w).forward })), false],
      ['an end witness whose move forward read another stop', replaced('-end',
        endRow(R, 1, { back: witnessOf(w).back, forward: { phrase: 'Extra', position: witnessOf(w).forward.position } })), false],
      // The start row.
      ['a start row whose position is one word', replaced('-start', `| \`${R}-walk-1-start\` | "Back button" at here |`), false],
      // The positions row.
      ['a positions row with one position too few', replaced('-positions', positionsRow(R, 1, placesOf(w).slice(1))), false],
      ['a positions row with a position that is one word', replaced('-positions', positionsRow(R, 1, [...placesOf(w).slice(1), 'here'])), false],
      // The unresolved-reads row.
      ['the last walk with an unresolved read', replaced('-unresolved', unresolvedRow(R, 1, [{ after: 3, phrase: '', position: pos(2) }])), false],
      ['an unresolved-reads row whose position is one word', replaced('-unresolved', `| \`${R}-walk-1-unresolved\` | after stop 3: "" at here |`), false],
      ['malformed unresolved reads', replaced('-unresolved', `| \`${R}-walk-1-unresolved\` | lost one |`), false],
      // Earlier walks: each judged again, and a wrong one fails the
      // transcript however clean the walk after it.
      ['an empty first title, walked again, then complete', thenRight(walkRows(R, 1, ['', ...w.slice(1)], 'incomplete')), true],
      ['a first walk with an unresolved read, witnessed at its end, recorded incomplete though its stops judge complete, then complete',
        thenRight(walkRows(R, 1, w, 'incomplete', { unresolved: [{ after: h + 1, phrase: '', position: pos(h) }] })), true],
      ['an unresolved read after the start that repeats the start, then complete',
        thenRight(walkRows(R, 1, w, 'incomplete', {
          start: { phrase: 'Back button', position: BACK.position },
          unresolved: [{ after: 0, phrase: 'Back button', position: BACK.position }],
        })), true],
      ['a right prefix, one lost read, then the stop after the next; then complete',
        thenRight(walkRows(R, 1, w.filter((_, i) => i !== h + 1), 'incomplete', { unresolved: [{ after: h + 1, phrase: EXAMPLE_HEADING, position: pos(h) }] })), true],
      ['a first walk exhausted at the move limit (no end row), then complete',
        thenRight(walkRows(R, 1, exhausted, 'incomplete', { end: false, unresolved: exhausted.map((_, i) => ({ after: i, phrase: '', position: i === 0 ? BACK.position : pos(i - 1) })) })), false],
      ['the same exhausted walk given an end row, then complete',
        thenRight(walkRows(R, 1, exhausted, 'incomplete', { unresolved: exhausted.map((_, i) => ({ after: i, phrase: '', position: i === 0 ? BACK.position : pos(i - 1) })) })), false],
      ['a first walk cut short with no end row, then complete', thenRight(walkRows(R, 1, w.slice(0, 3), 'incomplete', { end: false })), false],
      ['a wrong first walk recorded wrong, then complete', thenRight(walkRows(R, 1, [WRONG_TITLE, ...w.slice(1)], 'wrong')), false],
      ['a wrong title, then a stale read, witnessed, then complete',
        thenRight(walkRows(R, 1, [WRONG_TITLE, ...w.slice(1)], 'incomplete', { unresolved: [{ after: 1, phrase: WRONG_TITLE, position: pos(0) }] })), false],
      ['a wrong title, then an empty read, witnessed, then complete',
        thenRight(walkRows(R, 1, [WRONG_TITLE, ...w.slice(1)], 'incomplete', { unresolved: [{ after: 1, phrase: '', position: pos(0) }] })), false],
      ['a wrong stop after the gap, witnessed, then complete',
        thenRight(walkRows(R, 1, [...w.slice(0, h + 1), 'Wrong', ...w.slice(h + 2)], 'incomplete', { unresolved: [{ after: h + 1, phrase: '', position: pos(h) }] })), false],
      ['a first walk with an unresolved read recorded complete, then complete',
        thenRight(walkRows(R, 1, w, 'complete', { unresolved: [{ after: h + 1, phrase: '', position: pos(h) }] })), false],
      // An unresolved read is an unchanged read (S17's checks).
      ['an unresolved read at a position other than the one before it',
        thenRight(walkRows(R, 1, w, 'incomplete', { unresolved: [{ after: h + 1, phrase: '', position: pos(h + 5) }] })), false],
      ['an unresolved read after a stop the walk does not have',
        thenRight(walkRows(R, 1, w, 'incomplete', { unresolved: [{ after: w.length + 1, phrase: '', position: pos(w.length) }] })), false],
      ['an end witness whose move forward read the last stop away from its recorded position', replaced('-end',
        endRow(R, 1, { back: witnessOf(w).back, forward: { phrase: w.at(-1), position: '9, 9, 9, 9' } })), false],
      ['an end witness whose move back read at the last stop\'s recorded position', transcript(() => rows.flatMap((row) => (row === R
        ? walkRows(R, 1, w, 'complete', { positions: [...placesOf(w).slice(0, -1), pos(w.length - 2)] }) : rowsOf(row)))), false],
      // An unresolved read hides no words.
      ['an unresolved read after the start that read a wrong title, then a clean walk',
        thenRight(walkRows(R, 1, w.slice(1), 'incomplete', { unresolved: [{ after: 0, phrase: WRONG_TITLE, position: BACK.position }] })), false],
      ['an unresolved read mid-walk whose words differ from the stop before it',
        thenRight(walkRows(R, 1, w, 'incomplete', { unresolved: [{ after: 3, phrase: 'Extra', position: pos(2) }] })), false],
      // A help message, judged by the walk's rule from the positions row.
      ['a help message tied by its position to the stop before it, whose role it names', withHelp(tiedAt), true],
      ['the same help message at a new position', withHelp(placesOf(helped)), false],
      ['the same help message with the positions row one short', withHelp(tiedAt.slice(1)), false],
      ['the same help message with no positions row', transcript(() => rows.flatMap((row) => (row === TIED.slug
        ? walkRows(row, 1, helped, 'complete', { positions: tiedAt }).filter((r) => !r.includes('-positions`')) : rowsOf(row)))), false],
    ];
    for (const [what, text, ok] of cases) {
      const problems = judgeTranscript(text);
      expect(problems.length === 0, `${what}: ${problems.join('; ') || 'no problems'}`).toBe(ok);
    }
  });

  test('the recording made before the walk recorded its start capture and positions (voiceover-web-before-judge-update.md.txt) fails for that alone', () => {
    const text = readFileSync(new URL('../docs/evidence/probes/s12/voiceover-web-before-judge-update.md.txt', import.meta.url), 'utf8');
    const problems = judgeTranscript(text);
    // Every pair lacks its start row and its positions row, and nothing
    // else is wrong with it.
    const pairs = BROWSERS.length * rows.length;
    expect(problems.filter((p) => / has no start row$/.test(p))).toHaveLength(pairs);
    expect(problems.filter((p) => / has no positions row$/.test(p))).toHaveLength(pairs);
    expect(problems, problems.join('; ')).toHaveLength(2 * pairs);
  });

  test('the committed recording (docs/evidence/S12/voiceover-web.md) is right, every browser and row once', () => {
    // Never skipped: a missing file fails here.
    const text = readFileSync(new URL('../docs/evidence/S12/voiceover-web.md', import.meta.url), 'utf8');
    expect(judgeTranscript(text)).toEqual([]);
  });
});
