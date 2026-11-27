// L3 for S12 Hiding content from AT on web: what the page exposes for each
// example, and where Tab, Enter, Space, and a click go. Spec:
// docs/specs/S12-hiding-content.md. Runs against the release build in
// build/web.
import { readFileSync } from 'node:fs';
import { test, expect } from '@playwright/test';
import { byId, tabTo, technique } from './support/techniques.js';
import {
  BROWSERS, EXAMPLE_HEADING, EXAMPLE_SCREENS, EXPECTED_STOPS, collectWalk, endRow, helpRole, judgeCollectedWalk,
  judgeExampleWalk, judgeTranscript, runWalks, screenStops, spokenRole, transcriptRow,
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

// A cursor position as cursorBounds gives it: "left, top, right, bottom",
// numbers with commas and spaces ("318, 411, 1011, 431"). Made-up walks and
// rows use this form, so that a pattern reading a position as one word fails
// here as it would on a real transcript (S17's finding in its copy).
const pos = (i) => `318, ${251 + 40 * i}, 1011, ${271 + 40 * i}`;
const POS_BACK = pos(90);
const POS_LAST = pos(91);
const POS_OTHER = pos(92);

// The walk's end witness (collectWalk in vo/s12_vo_walks.js), on made-up
// screens: the cursor moves over `elements`; `capture` reads the element
// under it, unless the case freezes or empties the capture after the
// `after`-th move. The reviewer's case (Codex, review of 90edde5): after
// good-badge's expected stops the capture froze while the cursor went on
// through an exposed "3" and an unexpected button; under the end rule alone
// (two moves that change nothing) that walk judged complete.
test.describe('the walk ends only with a witness that the cursor is at the last stop', () => {
  const slug = 'good-badge';
  const whole = [...screenStops(slug), EXAMPLE_HEADING, ...EXPECTED_STOPS[slug]];
  const fake = (elements, { after = Infinity, capture = 'live', back = null, forward = null } = {}) => {
    let at = -1;
    let moves = 0;
    let frozen = null;
    // 0 during the walk; 1 after the witness's move back; 2 after its move
    // forward again. The overrides apply to those two reads only.
    let witness = 0;
    const live = () => ({ phrase: elements[at] ?? '', position: pos(at) });
    return {
      next: async () => { moves++; if (witness === 1) witness = 2; if (at < elements.length - 1) at++; },
      previous: async () => { moves++; witness = 1; if (at > 0) at--; },
      capture: async () => {
        if (moves > after && capture !== 'live') {
          frozen ??= { phrase: capture === 'empty' ? '' : elements[after - 1], position: pos(after - 1) };
          return frozen;
        }
        if (witness === 1 && back) return back;
        if (witness === 2 && forward) return forward;
        return live();
      },
      start: pos(-1),
    };
  };
  const run = (screen, max) => collectWalk({ ...screen, max });
  const judged = (walk) => judgeCollectedWalk(walk, EXPECTED_STOPS[slug], screenStops(slug)).verdict;

  test('every made-up walk ends, or fails, as its case says', async () => {
    const extra = [...whole, '3', 'Extra button'];
    const cases = [
      ['the whole screen, the witness right', await run(fake(whole)), 'complete'],
      ['the capture frozen after the last expected stop, while the cursor goes on through "3" and a button',
        await run(fake(extra, { after: whole.length, capture: 'frozen' })), 'wrong'],
      ['empty phrases with frozen bounds after the last expected stop',
        await run(fake(extra, { after: whole.length, capture: 'empty' })), 'wrong'],
      ['the move back reads another stop', await run(fake(whole, { back: { phrase: '3', position: POS_OTHER } })), 'wrong'],
      ['the move back reads the right words at the last stop\'s position',
        await run(fake(whole, { back: { phrase: whole.at(-2), position: pos(whole.length - 1) } })), 'wrong'],
      ['the move back reads an empty phrase', await run(fake(whole, { back: { phrase: '', position: POS_OTHER } })), 'wrong'],
      ['the move forward again reads another stop',
        await run(fake(whole, { forward: { phrase: 'Extra button', position: POS_OTHER } })), 'wrong'],
      ['the move forward again reads the last words elsewhere',
        await run(fake(whole, { forward: { phrase: whole.at(-1), position: POS_OTHER } })), 'wrong'],
      ['a walk that runs out of moves', await run(fake(whole), 3), 'incomplete'],
      ['a screen of one stop', await run(fake([whole[0]])), 'wrong'],
    ];
    for (const [what, walk, verdict] of cases) {
      expect(judged(walk), `${what}: ${walk.problem ?? ''}`).toBe(verdict);
      if (verdict === 'wrong') expect(walk.problem, what).toMatch(/^the end is not witnessed/);
      if (verdict !== 'incomplete' && what !== 'a screen of one stop') expect(walk.stops, what).toEqual(whole);
    }
  });

  test('the reviewer\'s frozen capture would pass without the witness, and the witness is recorded', async () => {
    const walk = await run(fake([...whole, '3', 'Extra button'], { after: whole.length, capture: 'frozen' }));
    // The stops are exactly the expected screen: only the witness shows the
    // capture had frozen.
    expect(walk.stops).toEqual(whole);
    expect(judgeExampleWalk(walk.stops, true, EXPECTED_STOPS[slug], screenStops(slug)).verdict).toBe('complete');
    expect(walk.witness.back).toEqual({ phrase: whole.at(-1), position: pos(whole.length - 1) });
    expect(walk.problem).toMatch(/^the end is not witnessed/);
    const right = await run(fake(whole));
    expect(right.witness).toEqual({
      back: { phrase: whole.at(-2), position: pos(whole.length - 2) },
      forward: { phrase: whole.at(-1), position: pos(whole.length - 1) },
    });
    expect(endRow(slug, 1, right.witness)).toBe(
      `| \`${slug}-walk-1-end\` | back "${whole.at(-2)}" at ${pos(whole.length - 2)} / forward "${whole.at(-1)}" at ${pos(whole.length - 1)} |`);
  });
});

// The committed web VoiceOver transcript, judged again with today's judge
// from its rows alone (judgeTranscript in vo/s12_vo_walks.js): every
// browser and example exactly once, walks numbered from 1, no duplicate or
// malformed row, and each walk judged on the stops it recorded, the screen's
// title, description, and heading included, with nothing put back. The
// judge is tested first on made-up transcripts; each case is named.
test.describe('the committed web VoiceOver transcript is judged from its rows alone', () => {
  const walk = (slug) => [...screenStops(slug), EXAMPLE_HEADING, ...EXPECTED_STOPS[slug]];
  // A walk row, and for a complete walk its end witness row (the move back
  // read the stop before the last, the move forward the last, at two
  // positions), as the VoiceOver spec logs them.
  const row = (slug, n, stops, verdict, end = verdict === 'complete') => [
    transcriptRow(slug, n, stops, verdict, 'x'),
    ...(end ? [endRow(slug, n, {
      back: { phrase: stops.at(-2), position: POS_BACK }, forward: { phrase: stops.at(-1), position: POS_LAST },
    })] : []),
  ].join('\n');
  const right = (slug) => row(slug, 1, walk(slug), 'complete');
  const transcript = (sections) => Object.entries(sections)
    .map(([b, rows]) => [`## ${b}`, '', '| Example | Spoken, in order |', '| --- | --- |', ...rows, ''].join('\n'))
    .join('\n');
  const all = () => Object.fromEntries(BROWSERS.map((b) => [b, Object.keys(EXPECTED_STOPS).map(right)]));

  test('every made-up transcript is judged as its case says', () => {
    const slugs = Object.keys(EXPECTED_STOPS);
    const first = right(slugs[0]);
    const withRows = (edit) => {
      const t = all();
      edit(t);
      return transcript(t);
    };
    const cases = [
      ['every browser and example once, each complete', transcript(all()), true],
      ['fourteen copies of the first Chromium row', transcript({ chromium: Array(7).fill(first), webkit: Array(7).fill(first) }), false],
      ['one example missing in WebKit', withRows((t) => t.webkit.pop()), false],
      ['a browser missing', transcript({ chromium: all().chromium }), false],
      ['an unknown browser added', withRows((t) => { t.firefox = [first]; }), false],
      ['a row repeated', withRows((t) => t.chromium.push(t.chromium[0])), false],
      ['a malformed row', withRows((t) => t.chromium.push('| `good-badge-walk-2` | Inbox: 3 unread |')), false],
      ['a row for an unknown example', withRows((t) => t.webkit.push(right('good-badge').replace('good-badge', 'good-other'))), false],
      ['good-visibility\'s walk under bad-opacity\'s name', withRows((t) => {
        t.chromium[slugs.indexOf('bad-opacity')] = row('bad-opacity', 1, walk('good-visibility'), 'complete');
      }), false],
      ['a walk recorded as the old transcripts did, after the heading only', withRows((t) => {
        t.webkit[0] = row(slugs[0], 1, EXPECTED_STOPS[slugs[0]], 'complete');
      }), false],
      ['a walk with no title', withRows((t) => {
        t.webkit[1] = row(slugs[1], 1, walk(slugs[1]).slice(1), 'complete');
      }), false],
      ['a walk whose title is an empty phrase', withRows((t) => {
        t.webkit[2] = row(slugs[2], 1, ['', ...walk(slugs[2]).slice(1)], 'complete');
      }), false],
      ['a last walk recorded wrong', withRows((t) => {
        t.chromium[0] = row(slugs[0], 1, walk(slugs[0]), 'wrong');
      }), false],
      ['a walk 2 with no walk 1', withRows((t) => {
        t.chromium[0] = row(slugs[0], 2, walk(slugs[0]), 'complete');
      }), false],
      ['an empty first walk walked again, then complete', withRows((t) => {
        t.chromium.splice(0, 1,
          row(slugs[0], 1, ['', ...walk(slugs[0]).slice(1)], 'incomplete'),
          row(slugs[0], 2, walk(slugs[0]), 'complete'));
      }), true],
      ['a wrong first walk followed by a complete one', withRows((t) => {
        t.chromium.splice(0, 1,
          row(slugs[0], 1, [...walk(slugs[0]), 'Extra'], 'incomplete'),
          row(slugs[0], 2, walk(slugs[0]), 'complete'));
      }), false],
      // The end witness (collectWalk), as the transcript records it.
      ['a complete walk with no end witness row', withRows((t) => {
        t.chromium[0] = row(slugs[0], 1, walk(slugs[0]), 'complete', false);
      }), false],
      ['an end witness whose move back read the last stop again (a frozen capture)', withRows((t) => {
        const w = walk(slugs[0]);
        t.chromium[0] = [transcriptRow(slugs[0], 1, w, 'complete', 'x'),
          endRow(slugs[0], 1, { back: { phrase: w.at(-1), position: POS_LAST }, forward: { phrase: w.at(-1), position: POS_LAST } })].join('\n');
      }), false],
      ['an end witness whose move back read the right words at the last position', withRows((t) => {
        const w = walk(slugs[1]);
        t.chromium[1] = [transcriptRow(slugs[1], 1, w, 'complete', 'x'),
          endRow(slugs[1], 1, { back: { phrase: w.at(-2), position: POS_LAST }, forward: { phrase: w.at(-1), position: POS_LAST } })].join('\n');
      }), false],
      ['an end witness whose move back read an empty phrase', withRows((t) => {
        const w = walk(slugs[2]);
        t.webkit[2] = [transcriptRow(slugs[2], 1, w, 'complete', 'x'),
          endRow(slugs[2], 1, { back: { phrase: '', position: POS_BACK }, forward: { phrase: w.at(-1), position: POS_LAST } })].join('\n');
      }), false],
      ['an end witness whose move forward read another stop', withRows((t) => {
        const w = walk(slugs[3]);
        t.webkit[3] = [transcriptRow(slugs[3], 1, w, 'complete', 'x'),
          endRow(slugs[3], 1, { back: { phrase: w.at(-2), position: POS_BACK }, forward: { phrase: 'Extra button', position: POS_OTHER } })].join('\n');
      }), false],
      ['an end witness row twice', withRows((t) => {
        t.webkit[4] = `${t.webkit[4]}\n${t.webkit[4].split('\n')[1]}`;
      }), false],
      ['an end witness row for a walk that is not there', withRows((t) => {
        t.webkit[5] = `${t.webkit[5]}\n${endRow(slugs[5], 2, { back: { phrase: 'a', position: POS_BACK }, forward: { phrase: 'b', position: POS_LAST } })}`;
      }), false],
      ['a stop past the end', withRows((t) => {
        t.webkit[3] = row(slugs[3], 1, [...walk(slugs[3]), ''], 'complete');
      }), false],
    ];
    for (const [what, text, passes] of cases) {
      const problems = judgeTranscript(text);
      expect(problems.length === 0, `${what}: ${problems.join('; ') || 'no problems'}`).toBe(passes);
    }
  });

  const committed = readFileSync(new URL('../docs/evidence/S12/voiceover-web.md', import.meta.url), 'utf8');
  // The transcript committed at 90edde5 was recorded before the walk read
  // an end witness, so it has no `-walk-<n>-end` rows and cannot be judged
  // by the present rules. Until the principal records it again, this test
  // is skipped, with that reason; once any end row is in it, it runs.
  const recordedWithWitness = /^\| `[a-z-]+-walk-\d+-end` \|/m.test(committed);
  test('the committed transcript (docs/evidence/S12/voiceover-web.md) is right', () => {
    test.skip(!recordedWithWitness,
      'recorded before the end witness (collectWalk): the web VoiceOver transcript is to be recorded again');
    expect(judgeTranscript(committed)).toEqual([]);
    // Every end row of the committed transcript is read whole, positions
    // with their commas and spaces included: one per browser and example.
    const ends = committed.split('\n').filter((l) => /^\| `[a-z-]+-walk-\d+-end` \|/.test(l));
    expect(ends).toHaveLength(BROWSERS.length * Object.keys(EXPECTED_STOPS).length);
    for (const line of ends) expect(line, line).toMatch(/ at \d+, \d+, \d+, \d+ \/ forward ".*" at \d+, \d+, \d+, \d+ \|$/);
  });
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
  // Every mutation of a walk in one test; each case is named in its
  // message, so a failure says which.
  test(`every made-up walk is judged as its case says (${cases.length} cases)`, () => {
    for (const [what, stops, reachedEnd, verdict] of cases) {
      expect(judgeExampleWalk(stops, reachedEnd, expected, own).verdict, what).toBe(verdict);
    }
  });

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
  test(`every made-up walk with a help message is judged as its case says (${helpCases.length} cases)`, () => {
    for (const [what, stops, positions, verdict] of helpCases) {
      expect(judgeExampleWalk(stops, true, expected, own, positions).verdict, what).toBe(verdict);
    }
  });

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
