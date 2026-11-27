// L3 for S10 Content group replacement on web: what the page's semantics
// elements and Chromium's accessibility tree expose for each example, and
// what a click and the keys do. Spec:
// docs/specs/S10-content-group-replacement.md. Runs against the release
// build in build/web.
import { test, expect } from '@playwright/test';
import { byId, tabTo, technique } from './support/techniques.js';
import {
  EXAMPLE_HEADING, EXAMPLE_SCREENS, EXPECTED_AFTER_ADDING, EXPECTED_STOPS, helpRole, judgeExampleWalk, runWalks,
  screenStops, spokenRole,
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

  test('bad-stale: after the button the replacement still says 856, and 857 is in no element', async ({ page }) => {
    await open(page, 'bad-stale');
    await expect(rating(page, 'bad-stale')).toHaveText(WORDS);
    await addButton(page, 'bad-stale').click();
    // The row now shows 857 reviews; wait as long as good-exclude-semantics
    // takes to say so, and check that nothing does.
    await page.waitForTimeout(1500);
    await expect(rating(page, 'bad-stale')).toHaveText(WORDS);
    await expect(page.getByText(/857/)).toHaveCount(0);
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

test.describe('the VoiceOver example walks are judged on every walk', () => {
  const own = screenStops('good-exclude-semantics');
  const ADD = 'Add a 5-star review button';
  const expected = EXPECTED_STOPS['good-exclude-semantics'];
  // Made-up help messages: no S10 recording has been made, and no help for
  // a text or a button has been heard in this project's recordings; the
  // wording follows the list's that S08 heard.
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
    ['an empty walk cut short', [], false, 'incomplete'],
    ['a walk cut short after the heading', screen(), false, 'incomplete'],
    ['every stop read, but the end not reached', screen(...expected), false, 'incomplete'],
  ];
  // One test for every case, each case named in its own expectation: one
  // test a case made the default config's test listing larger than
  // check_spec_selection.js can read (it is read with execFileSync's
  // default buffer).
  test('every made-up walk is judged as expected', () => {
    for (const [what, stops, reachedEnd, verdict] of cases) {
      expect(judgeExampleWalk(stops, reachedEnd, expected, own).verdict, what).toBe(verdict);
    }
    expect(cases.length).toBe(21);
  });

  // A help message is left out only when the walk's positions tie it to the
  // stop before it: same position, a reading before it, and its role in
  // that reading (helpAfterStop in s10_vo_walks.js). Tested only here, on
  // made-up walks.
  // One position per stop, each new but where `same` lists the stops (by
  // index) that are at the position of the stop before them.
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
  test('every made-up help message is judged as expected', () => {
    for (const [what, stops, positions, exp, scr, verdict] of helpCases) {
      expect(judgeExampleWalk(stops, true, exp, scr, positions).verdict, what).toBe(verdict);
    }
    expect(helpCases.length).toBe(14);
  });

  test('a reading\'s spoken role comes from its role part only', () => {
    expect(spokenRole('heading level 1 Rating merged, not replaced')).toBe('heading');
    expect(spokenRole('heading level 2 Example')).toBe('heading');
    expect(spokenRole(ADD)).toBe('button');
    expect(spokenRole(merged[0])).toBe('progress indicator');
    expect(spokenRole(EXPECTED_STOPS['bad-not-excluded'][0])).toBe('progress indicator');
    expect(spokenRole(WORDS)).toBe('text');
    expect(spokenRole('3.4')).toBe('text');
    expect(spokenRole('Reviews opened: 0')).toBe('text');
    // A name with a role word in it is still the role it is spoken with.
    expect(spokenRole('Defect: A screen reader cannot find the Reviews button.')).toBe('text');
    expect(spokenRole('Defect: The rating is read with a stray 68 from the bar.')).toBe('text');
    expect(spokenRole('')).toBe(null);
    expect(spokenRole(BUTTON_HELP)).toBe(null);
  });

  test('a help message names the role it is about', () => {
    expect(helpRole(BUTTON_HELP)).toBe('button');
    expect(helpRole(TEXT_HELP)).toBe('text');
    expect(helpRole(PROGRESS_HELP)).toBe('progress indicator');
    expect(helpRole(WORDS)).toBe(null);
  });

  test('every expected stop is spoken with a role the judge knows', () => {
    for (const list of [...Object.values(EXPECTED_STOPS), ...Object.values(EXPECTED_AFTER_ADDING)]) {
      for (const stop of list) expect(spokenRole(stop), stop).not.toBe(null);
    }
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
  const short = { stops: screen(WORDS), reachedEnd: false };
  const wrong = { stops: screen('Rating:', ADD), reachedEnd: true };

  for (const [what, walk] of [
    ['a wrong reading', wrong],
    ['a walk that reached the end without the button', { stops: screen(WORDS), reachedEnd: true }],
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
    const { walkOnce, made } = sequence(emptyTitle, wrong, right);
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
    const { walkOnce, made } = sequence(short, wrong, right);
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
