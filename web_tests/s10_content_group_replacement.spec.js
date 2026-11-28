// L3 for S10 Content group replacement on web: what the page's semantics
// elements and Chromium's accessibility tree expose for each example, and
// what a click and the keys do. Spec:
// docs/specs/S10-content-group-replacement.md. Runs against the release
// build in build/web.
import { readFileSync } from 'node:fs';
import { test, expect } from '@playwright/test';
import { byId, tabTo, technique } from './support/techniques.js';
import {
  EXPECTED_AFTER_ADDING, BROWSERS, EXAMPLE_HEADING, EXAMPLE_SCREENS, EXPECTED_STOPS, TRANSCRIPT_ROWS,
  collectWalk, endRow, helpRole, judgeCollectedWalk, judgeExampleWalk, judgeTranscript, judgeWalk, positionsRow,
  runWalks, screenStops, spokenRole, startRow, stopsOf, stopsText, transcriptRow, unresolvedRow,
} from './vo/s10_vo_walks.js';

// The example screen's own "Example" heading; the technique's page has
// "Good examples" and "Bad examples", so the name must match exactly.
const exampleHeading = (page) => page.getByRole('heading', { name: 'Example', exact: true, level: 2 });
const { open } = technique('S10', { ready: exampleHeading, settle: 600 });

const WORDS = 'Rating: 3.4 out of 5 stars, based on 856 reviews';
const WORDS_AFTER = 'Rating: 3.4 out of 5 stars, based on 857 reviews';
// The bar row's pieces as Flutter joins them in a merged node's label.
const PIECES = 'Rating:\n3.4 / 5\nReviews: 856';
const PIECE_TEXTS = ['Rating:', '3.4 / 5', 'Reviews: 856', '3.4', '(856)'];

/**
 * Every semantics element of the page after the "Example" heading that a
 * screen reader can stop on: one with a role, or with a label, or holding
 * text of its own and no other semantics element. Each is given as
 * "role | name | value": the role attribute (or "text"), the aria-label or
 * the text, and aria-valuenow. A container with nothing of its own is left
 * out.
 */
async function exampleElements(page) {
  return page.evaluate(() => {
    const host = document.querySelector('flt-semantics-host');
    const all = [...host.querySelectorAll('flt-semantics, h1, h2, h3')];
    const heading = all.findIndex((e) => e.tagName === 'H2' && e.textContent.trim() === 'Example');
    if (heading < 0) throw new Error('no Example heading');
    const out = [];
    for (const e of all.slice(heading + 1)) {
      const role = e.getAttribute('role');
      const label = e.getAttribute('aria-label');
      const leaf = !e.querySelector('flt-semantics');
      const text = leaf ? e.textContent : '';
      if (!role && label == null && text.trim() === '') continue;
      const value = e.getAttribute('aria-valuenow');
      out.push([role ?? 'text', label ?? text, ...(value == null ? [] : [value])].join(' | '));
    }
    return out;
  });
}

/** The replacement element of `slug`. */
const rating = (page, slug) => byId(page, `s10-${slug}-rating`);

/** The add button of `slug`. */
const addButton = (page, slug) => byId(page, `s10-${slug}-add`);

/** No element of the page is a piece of the rating, by its own text or label. */
async function expectNoPieces(page) {
  const own = await page.evaluate(() =>
    [...document.querySelectorAll('flt-semantics-host flt-semantics')]
      .filter((e) => !e.querySelector('flt-semantics'))
      .map((e) => e.getAttribute('aria-label') ?? e.textContent),
  );
  for (const piece of PIECE_TEXTS) expect(own, piece).not.toContain(piece);
}

test.describe('good examples', () => {
  for (const slug of ['good-exclude-semantics', 'good-hidden-pieces', 'good-stars']) {
    test(`${slug}: one text element that says what the rating means, with no role, value, or tab stop`, async ({ page }) => {
      await open(page, slug);
      const el = rating(page, slug);
      await expect(el).toHaveCount(1);
      await expect(el).toHaveText(WORDS);
      for (const attr of ['role', 'aria-label', 'aria-valuenow', 'tabindex']) {
        await expect(el, attr).not.toHaveAttribute(attr, /.*/);
      }
      await expect(page.getByText(WORDS, { exact: true })).toHaveCount(1);
      await expect(page.getByRole('progressbar')).toHaveCount(0);
      await expectNoPieces(page);
    });
  }

  test('good-exclude-semantics: the rating, then the button, and nothing else', async ({ page }) => {
    await open(page, 'good-exclude-semantics');
    expect(await exampleElements(page)).toEqual([`text | ${WORDS}`, 'button | Add a 5-star review']);
    await expect(page.getByRole('button')).toHaveCount(2);
  });

  for (const slug of ['good-hidden-pieces', 'good-stars']) {
    test(`${slug}: the rating, and nothing else`, async ({ page }) => {
      await open(page, slug);
      expect(await exampleElements(page)).toEqual([`text | ${WORDS}`]);
      await expect(page.getByRole('button')).toHaveCount(1);
    });
  }

  test('good-exclude-semantics: Tab goes Back, the button, and never to the rating', async ({ page }) => {
    await open(page, 'good-exclude-semantics');
    const stops = [];
    for (let i = 0; i < 2; i++) {
      await page.keyboard.press('Tab');
      await page.waitForTimeout(150);
      stops.push(await page.evaluate(() => document.activeElement?.textContent.trim() ?? ''));
    }
    expect(stops).toEqual(['Back', 'Add a 5-star review']);
  });

  for (const [how, press] of [
    ['a click', (page) => addButton(page, 'good-exclude-semantics').click()],
    ['a DOM click', (page) => addButton(page, 'good-exclude-semantics').evaluate((e) => e.click())],
    ['Tab and Enter', async (page) => {
      expect(await tabTo(page, addButton(page, 'good-exclude-semantics'))).toBe(true);
      await page.keyboard.press('Enter');
    }],
    ['Tab and Space', async (page) => {
      expect(await tabTo(page, addButton(page, 'good-exclude-semantics'))).toBe(true);
      await page.keyboard.press('Space');
    }],
  ]) {
    test(`good-exclude-semantics: after ${how} on the button the replacement says 857 reviews`, async ({ page }) => {
      await open(page, 'good-exclude-semantics');
      await expect(rating(page, 'good-exclude-semantics')).toHaveText(WORDS);
      await press(page);
      await expect(rating(page, 'good-exclude-semantics')).toHaveText(WORDS_AFTER, { timeout: 3000 });
      await expect(page.getByRole('progressbar')).toHaveCount(0);
      await expectNoPieces(page);
    });
  }
});

test.describe('bad examples have their defect', () => {
  test('bad-pieces: two texts, "3.4" and "(856)", and nothing for the stars', async ({ page }) => {
    await open(page, 'bad-pieces');
    const elements = await exampleElements(page);
    expect(elements).toEqual(['text | 3.4', 'text | (856)']);
    await expect(page.getByRole('img')).toHaveCount(0);
    for (const word of ['star', 'Star', 'out of', 'review', 'Rating']) {
      expect(elements.join(' '), word).not.toContain(word);
    }
  });

  test('bad-merged: one progress bar at 68, named by the pieces and its value', async ({ page }) => {
    await open(page, 'bad-merged');
    expect(await exampleElements(page)).toEqual([`progressbar | ${PIECES} 68 | 68`]);
    const bar = page.getByRole('progressbar');
    await expect(bar).toHaveCount(1);
    await expect(bar).toHaveAccessibleName('Rating: 3.4 / 5 Reviews: 856 68');
    await expect(bar).toHaveAttribute('aria-valuenow', '68');
    await expect(bar).toHaveAttribute('flt-semantics-identifier', 's10-bad-merged-rating');
  });

  test('bad-not-excluded: one progress bar at 68, named by the label, the pieces, and its value', async ({ page }) => {
    await open(page, 'bad-not-excluded');
    expect(await exampleElements(page)).toEqual([`progressbar | ${WORDS}\n${PIECES} 68 | 68`]);
    const bar = page.getByRole('progressbar');
    await expect(bar).toHaveCount(1);
    await expect(bar).toHaveAccessibleName(`${WORDS} Rating: 3.4 / 5 Reviews: 856 68`);
    await expect(bar).toHaveAttribute('aria-valuenow', '68');
  });

  test('bad-hides-control: no element for the Reviews button; the keyboard reaches it with DOM focus left on Back', async ({ page }) => {
    await open(page, 'bad-hides-control');
    expect(await exampleElements(page)).toEqual([`text | ${WORDS}`, 'text | Reviews opened: 0']);
    await expect(page.getByRole('button')).toHaveCount(1);
    await expect(page.getByRole('button', { name: 'Back' })).toHaveCount(1);
    await expect(page.getByText('Reviews', { exact: true })).toHaveCount(0);
    // The first Tab puts focus on Back. The second puts Flutter's keyboard
    // focus on the hidden button, which has no element: DOM focus stays on
    // Back, and Enter then runs Reviews, not Back.
    await page.keyboard.press('Tab');
    await page.waitForTimeout(150);
    await page.keyboard.press('Tab');
    await page.waitForTimeout(150);
    expect(await page.evaluate(() => document.activeElement?.textContent.trim())).toBe('Back');
    await page.keyboard.press('Enter');
    await expect(byId(page, 's10-bad-hides-control-opens')).toHaveText('Reviews opened: 1', { timeout: 3000 });
    await expect(exampleHeading(page)).toHaveCount(1);
  });

  test('bad-hides-control: one Tab and Enter run Back (the positive control for the keys)', async ({ page }) => {
    await open(page, 'bad-hides-control');
    await page.keyboard.press('Tab');
    await page.waitForTimeout(150);
    expect(await page.evaluate(() => document.activeElement?.textContent.trim())).toBe('Back');
    await page.keyboard.press('Enter');
    await expect(exampleHeading(page)).toHaveCount(0, { timeout: 3000 });
  });

  test('bad-stale: after the button the row shows 857 (the witness) and the replacement still says 856', async ({ page }) => {
    await open(page, 'bad-stale');
    await expect(rating(page, 'bad-stale')).toHaveText(WORDS);
    await expect(byId(page, 's10-bad-stale-shows-856')).toHaveCount(1);
    await addButton(page, 'bad-stale').click();
    // The row's own text is hidden from the semantics tree, and the canvas
    // cannot be read: the test-only witness, an empty node whose identifier
    // says what the row shows, says 857. Only then is the stale replacement
    // judged.
    await expect(byId(page, 's10-bad-stale-shows-857')).toHaveCount(1, { timeout: 3000 });
    await expect(rating(page, 'bad-stale')).toHaveText(WORDS);
    await expect(page.getByText(/857/)).toHaveCount(0);
  });

  test('bad-stale: with the click left out, the witness never says 857 (the control for the gate)', async ({ page }) => {
    await open(page, 'bad-stale');
    // The same gate as above, with no click: it must fail.
    await expect(expect(byId(page, 's10-bad-stale-shows-857')).toHaveCount(1, { timeout: 1500 })).rejects.toThrow();
    await expect(byId(page, 's10-bad-stale-shows-856')).toHaveCount(1);
  });

  test('the witness is an empty node with no role, name, value, text, or tab stop', async ({ page }) => {
    for (const slug of ['good-exclude-semantics', 'bad-stale']) {
      await open(page, slug);
      const witness = byId(page, `s10-${slug}-shows-856`);
      await expect(witness).toHaveCount(1);
      await expect(page.locator(`[flt-semantics-identifier^="s10-${slug}-shows-"]`)).toHaveCount(1);
      for (const attr of ['role', 'aria-label', 'aria-valuenow', 'tabindex']) {
        await expect(witness, `${slug} ${attr}`).not.toHaveAttribute(attr, /.*/);
      }
      await expect(witness).toHaveText('');
      expect(await witness.evaluate((e) => e.children.length), slug).toBe(0);
    }
  });

  test('good-exclude-semantics: the witness says 857 once the button has added a review', async ({ page }) => {
    await open(page, 'good-exclude-semantics');
    await addButton(page, 'good-exclude-semantics').click();
    await expect(byId(page, 's10-good-exclude-semantics-shows-857')).toHaveCount(1, { timeout: 3000 });
    await expect(byId(page, 's10-good-exclude-semantics-shows-856')).toHaveCount(0);
  });

  test('bad-stale\'s positive control: good-exclude-semantics follows the same click', async ({ page }) => {
    await open(page, 'good-exclude-semantics');
    await addButton(page, 'good-exclude-semantics').click();
    await expect(rating(page, 'good-exclude-semantics')).toHaveText(WORDS_AFTER, { timeout: 1500 });
  });
});

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
  const own = screenStops('good-exclude-semantics');
  const ADD = 'Add a 5-star review button';
  const expected = EXPECTED_STOPS['good-exclude-semantics'];
  // Made-up help messages: no S10 recording has captured one, and no help
  // for a text, a button, or a progress indicator has been heard in this
  // project's recordings; the wording follows the list's that S08 heard.
  const TEXT_HELP = 'You are currently on a text element, inside of web content. To exit this web area, press '
    + 'Control-Option-Shift-Up Arrow.';
  const BUTTON_HELP = 'You are currently on a button, inside of web content. To click this button, press Control-Option-Space.';
  const PROGRESS_HELP = 'You are currently on a progress indicator, inside of web content.';
  const screen = (...content) => [...own, EXAMPLE_HEADING, ...content];
  const cases = [
    ['the whole screen, every stop in its place', screen(...expected), true, 'complete'],
    ['the pieces read in place of the replacement', screen('Rating:', '68 68% progress indicator', '3.4 / 5', 'Reviews: 856', ADD), true, 'wrong'],
    ['the stale count', screen(WORDS_AFTER, ADD), true, 'wrong'],
    ['a stop read in other words', screen(WORDS, 'Add a review button'), true, 'wrong'],
    ['the rating missing', screen(ADD), true, 'wrong'],
    ['the button missing at the end', screen(WORDS), true, 'wrong'],
    ['a stop after the last expected one', screen(...expected, 'Extra'), true, 'wrong'],
    ['an empty stop put in, so that every later stop comes late', screen('', ...expected), true, 'wrong'],
    // An empty phrase is a failed capture: walked again, never passed.
    ['the title read as an empty phrase, every later stop right', ['', ...own.slice(1), EXAMPLE_HEADING, ...expected], true, 'incomplete'],
    ['the rating read as an empty phrase, every other stop right', screen('', ADD), true, 'incomplete'],
    ['an empty first stop and a wrong reading later', ['', ...own.slice(1), EXAMPLE_HEADING, 'Rating:', ADD], true, 'wrong'],
    ['an empty first stop and a walk that reached the end short', ['', ...own.slice(1), EXAMPLE_HEADING, WORDS], true, 'wrong'],
    // The bounds check comes first: an empty stop past the end is wrong.
    ['an empty phrase after the last expected stop', screen(...expected, ''), true, 'wrong'],
    ['every stop an empty phrase', Array(5).fill(''), true, 'incomplete'],
    ['more empty stops than the screen has', Array(own.length + 1 + expected.length + 1).fill(''), true, 'wrong'],
    // A help message with no positions recorded is a stop like any other.
    ['a help message after the last stop, with no positions', screen(...expected, BUTTON_HELP), true, 'wrong'],
    ['no title', [own[1], EXAMPLE_HEADING, ...expected], true, 'wrong'],
    ['no heading', [...own, ...expected], true, 'wrong'],
    // A walk that did not reach its end ran out of moves: wrong for good.
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
  // that reading (helpAfterStop in s10_vo_walks.js). Tested only here, on
  // made-up walks.
  const at = (stops, same = []) => {
    const out = [];
    stops.forEach((_, i) => out.push(same.includes(i) ? out[i - 1] : `p${i}`));
    return out;
  };
  const whole = screen(...expected);
  const n = whole.length;
  const r = own.length + 1; // the index of the replacement's stop
  const merged = EXPECTED_STOPS['bad-merged'];
  const mergedWhole = [...screenStops('bad-merged'), EXAMPLE_HEADING, ...merged];
  const helpCases = [
    ['button help after the button, at its position: left out', [...whole, BUTTON_HELP], at([...whole, BUTTON_HELP], [n]), expected, own, 'complete'],
    ['text help after the replacement, at its position: left out',
      screen(WORDS, TEXT_HELP, ADD), at(screen(WORDS, TEXT_HELP, ADD), [r + 1]), expected, own, 'complete'],
    ['progress help after bad-merged\'s bar, at its position: left out',
      [...mergedWhole, PROGRESS_HELP], at([...mergedWhole, PROGRESS_HELP], [mergedWhole.length]), merged, screenStops('bad-merged'), 'complete'],
    ['help at a new position after the whole screen (an extra element): fails', [...whole, BUTTON_HELP], at([...whole, BUTTON_HELP]), expected, own, 'wrong'],
    ['text help after the button, at its position (a role it does not have): fails',
      [...whole, TEXT_HELP], at([...whole, TEXT_HELP], [n]), expected, own, 'wrong'],
    ['button help after the replacement, a text, at its position: fails',
      screen(WORDS, BUTTON_HELP, ADD), at(screen(WORDS, BUTTON_HELP, ADD), [r + 1]), expected, own, 'wrong'],
    ['progress help after a text, at its position: fails',
      screen(WORDS, PROGRESS_HELP, ADD), at(screen(WORDS, PROGRESS_HELP, ADD), [r + 1]), expected, own, 'wrong'],
    ['help in place of an expected stop: fails', screen(TEXT_HELP, ADD), at(screen(TEXT_HELP, ADD)), expected, own, 'wrong'],
    ['help after an empty stop, at its position: fails', [...screen(WORDS, ''), BUTTON_HELP],
      at([...screen(WORDS, ''), BUTTON_HELP], [n]), expected, own, 'wrong'],
    ['help with positions of the wrong length: fails', [...whole, BUTTON_HELP], at(whole), expected, own, 'wrong'],
    ['help and a wrong reading: fails', [...screen('Rating:', ADD), BUTTON_HELP],
      at([...screen('Rating:', ADD), BUTTON_HELP], [n]), expected, own, 'wrong'],
    ['two help messages after one stop, at its position: fails', [...whole, BUTTON_HELP, BUTTON_HELP],
      at([...whole, BUTTON_HELP, BUTTON_HELP], [n, n + 1]), expected, own, 'wrong'],
    ['no help message', whole, at(whole), expected, own, 'complete'],
    // The role is the spoken role, never a word of the name.
    ['text help after the screen\'s level 1 heading, at its position: fails',
      [own[0], TEXT_HELP, ...whole.slice(1)], at([own[0], TEXT_HELP, ...whole.slice(1)], [1]), expected, own, 'wrong'],
  ];
  test(`a help message is left out only when tied to the stop before it, by position and spoken role (${helpCases.length} cases)`, () => {
    for (const [what, stops, positions, exp, scr, verdict] of helpCases) {
      expect(judgeWalk(stops, true, exp, scr, positions).verdict, what).toBe(verdict);
    }
  });

  test('a reading\'s spoken role comes from its role part only, a help message names its role, and every expected stop has a role the judge knows', () => {
    const roles = [
      ['heading level 1 Rating merged, not replaced', 'heading'],
      ['heading level 2 Example', 'heading'],
      [ADD, 'button'],
      [merged[0], 'progress indicator'],
      [EXPECTED_STOPS['bad-not-excluded'][0], 'progress indicator'],
      [WORDS, 'text'],
      ['3.4', 'text'],
      ['Reviews opened: 0', 'text'],
      // A name with a role word in it is still the role it is spoken with.
      ['Defect: A screen reader cannot find the Reviews button.', 'text'],
      ['Defect: The rating is read with a stray 68 from the bar.', 'text'],
      ['', null],
      [BUTTON_HELP, null],
    ];
    for (const [reading, role] of roles) expect(spokenRole(reading), reading).toBe(role);
    expect(helpRole(BUTTON_HELP)).toBe('button');
    expect(helpRole(TEXT_HELP)).toBe('text');
    expect(helpRole(PROGRESS_HELP)).toBe('progress indicator');
    expect(helpRole(WORDS)).toBe(null);
    for (const list of [...Object.values(EXPECTED_STOPS), ...Object.values(EXPECTED_AFTER_ADDING)]) {
      for (const stop of list) expect(spokenRole(stop), stop).not.toBe(null);
    }
  });
});

// S16's regression cases (web_tests/s16_language_page_parts.spec.js),
// carried over to S10's screens. VO_SLUG is the example the made-up walks
// are drawn on; WRONG_TITLE is another S10 example's title, read where
// VO_SLUG's is expected; TIED is a help message that the positions tie to
// the stop before it (helpAfterStop), at `after` in the whole screen of
// `slug`.
const VO_SLUG = 'good-exclude-semantics';
const WRONG_TITLE = `heading level 1 ${EXAMPLE_SCREENS['bad-stale'][0]}`;
const TIED = {
  slug: 'good-exclude-semantics',
  after: screenStops('good-exclude-semantics').length + 1,
  help: 'You are currently on a text element, inside of web content. To exit this web area, press Control-Option-Shift-Up Arrow.',
};
const VO_HELP_PREFIX = /^You are currently on /;

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

// The walk (collectWalk in web_tests/vo/s10_vo_walks.js), driven by made-up
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
// (judgeTranscript in web_tests/vo/s10_vo_walks.js), never skipped: every
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
  const transcript = (rowsFor) => ['# S10 Content group replacement: VoiceOver transcript (web, macOS)', '',
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

  test('the recording made before the walk took S16\'s rules (voiceover-web-before-judge-update.md.txt) lacks every new row, and fails for that', () => {
    const text = readFileSync(new URL('../docs/evidence/probes/s10/voiceover-web-before-judge-update.md.txt', import.meta.url), 'utf8');
    const problems = judgeTranscript(text);
    const walkRows = text.split('\n').filter((l) => /^\| `[a-z-]+-walk-\d+` \|/.test(l));
    expect(walkRows).toHaveLength(21);
    // Every walk lacks its start, positions, and unresolved-reads rows, and
    // every last walk its end witness row.
    for (const kind of ['start', 'positions', 'unresolved-reads']) {
      expect(problems.filter((p) => p.endsWith(` has no ${kind} row`)), kind).toHaveLength(walkRows.length);
    }
    expect(problems.filter((p) => / has no end witness$/.test(p))).toHaveLength(BROWSERS.length * rows.length);
    // The rest: each walk, having no end row, did not reach its end, and
    // judges wrong. Its row is in the old form too: a complete walk logged
    // only what follows the "Example" heading, exactly the expected list.
    const rest = problems.filter((p) => !/ has no (start|positions|unresolved-reads) row$| has no end witness$/.test(p));
    expect(rest.every((p) => / was recorded (complete|incomplete) and judges wrong$/.test(p)), rest.join('; ')).toBe(true);
    expect(rest).toHaveLength(walkRows.length);
    let section = null;
    for (const line of text.split('\n')) {
      section = /^## (\S+)$/.exec(line)?.[1] ?? section;
      const m = /^\| `([a-z-]+)-walk-\d+` \| (.*) \(complete: .*\) \|$/.exec(line);
      if (m) expect(m[2], `${section} ${m[1]}`).toBe(TRANSCRIPT_ROWS[m[1]].expected.join(' / '));
    }
  });

  test('the committed recording (docs/evidence/S10/voiceover-web.md) is right, every browser and row once', () => {
    // Never skipped: a missing file fails here.
    const text = readFileSync(new URL('../docs/evidence/S10/voiceover-web.md', import.meta.url), 'utf8');
    expect(judgeTranscript(text)).toEqual([]);
  });
});
