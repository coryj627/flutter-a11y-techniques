// L3 for C18 Card on web: what the browser's accessibility tree exposes for
// each card's parts, and what a click and the keys do. Spec:
// docs/specs/C18-card.md. Runs against the release build in build/web.
import { test, expect } from '@playwright/test';
import { byId, tabTo, technique } from './support/techniques.js';
import { EXAMPLE_HEADING, EXAMPLE_SCREENS, judgeExampleWalk, runWalks, screenStops } from './vo/c18_vo_walks.js';

// The example screen's own "Example" heading; the technique's page has
// "Good examples" and "Bad examples", so the name must match exactly.
const exampleHeading = (page) => page.getByRole('heading', { name: 'Example', exact: true, level: 2 });
const { open } = technique('C18', { ready: exampleHeading, settle: 600 });

const TRAIL = 'Ridge trail';
const TEXT = 'A 6 km climb with a view.';
const PICTURE = 'Sunrise over the valley';
// What Chromium names a node whose label is the title, a line break, and
// the text.
const CARD = `${TRAIL} ${TEXT}`;

/** The count with the identifier c18-<slug>-<name>, as a number. */
async function count(page, slug, name) {
  const text = await byId(page, `c18-${slug}-${name}`).textContent();
  return Number(text.split(': ').pop());
}

/** Every count of `slug` in `names`, by name. */
async function counts(page, slug, names) {
  const out = {};
  for (const n of names) out[n] = await count(page, slug, n);
  return out;
}

/** Waits up to 3 seconds for the counts of `slug` to be `expected`. */
async function expectCounts(page, slug, expected) {
  await expect.poll(() => counts(page, slug, Object.keys(expected)), { timeout: 3000 }).toEqual(expected);
}

/**
 * The roles and names of the example's own elements, in the page's order,
 * from Chromium's accessibility tree: everything after the "Example"
 * heading up to the first count. Static text inside a named element is
 * left out.
 */
async function cardTree(page) {
  const snapshot = await page.locator('flt-semantics-host').ariaSnapshot();
  const lines = snapshot.split('\n');
  const start = lines.findIndex((l) => l.includes('heading "Example" [level=2]'));
  const end = lines.findIndex((l, i) => i > start && /(Saves|Shares|Opens): \d/.test(l));
  expect(start, 'the Example heading').toBeGreaterThanOrEqual(0);
  return lines.slice(start + 1, end < 0 ? undefined : end).map((l) => l.trim());
}

const controls = {
  'good-material': [
    { id: 'c18-good-material-save', name: `Save ${TRAIL}`, count: 'saves' },
    { id: 'c18-good-material-share', name: `Share ${TRAIL}`, count: 'shares' },
  ],
  'good-tappable': [{ id: 'c18-good-tappable-card', name: CARD, count: 'opens' }],
};

test.describe('good examples', () => {
  test('good-material: a heading, the text, the picture, and two buttons, in that order', async ({ page }) => {
    await open(page, 'good-material');
    expect(await cardTree(page)).toEqual([
      `- heading "${TRAIL}" [level=3]`,
      `- text: ${TEXT}`,
      `- img "${PICTURE}"`,
      `- button "Save ${TRAIL}"`,
      `- button "Share ${TRAIL}"`,
    ]);
    await expect(page.getByRole('heading', { name: TRAIL, exact: true, level: 3 })).toHaveCount(1);
    // Nothing of the card is inside the heading.
    const heading = page.getByRole('heading', { name: TRAIL, exact: true, level: 3 });
    await expect(heading.getByRole('button')).toHaveCount(0);
    await expect(heading.getByRole('img')).toHaveCount(0);
    // The buttons, and Back, are the only buttons; there is no link.
    await expect(page.getByRole('button')).toHaveCount(3);
    await expect(page.getByRole('link')).toHaveCount(0);
  });

  test('good-tappable: one button named by the title and the text, and no heading', async ({ page }) => {
    await open(page, 'good-tappable');
    expect(await cardTree(page)).toEqual([`- button "${CARD}"`]);
    const card = byId(page, 'c18-good-tappable-card');
    await expect(card).toHaveRole('button');
    await expect(card).toHaveAccessibleName(CARD);
    await expect(page.getByRole('heading', { level: 3 })).toHaveCount(0);
    await expect(page.getByRole('button')).toHaveCount(2);
  });

  test('good-cupertino: a heading, the text, and the picture, and no control', async ({ page }) => {
    await open(page, 'good-cupertino');
    expect(await cardTree(page)).toEqual([
      `- heading "${TRAIL}" [level=3]`,
      `- text: ${TEXT}`,
      `- img "${PICTURE}"`,
    ]);
    await expect(page.getByRole('button')).toHaveCount(1);
  });

  test('good-material: Tab goes Back, Save, Share', async ({ page }) => {
    await open(page, 'good-material');
    const stops = [];
    for (let i = 0; i < 3; i++) {
      await page.keyboard.press('Tab');
      await page.waitForTimeout(150);
      stops.push(await page.evaluate(() => document.activeElement.textContent.trim()));
    }
    expect(stops).toEqual(['Back', `Save ${TRAIL}`, `Share ${TRAIL}`]);
  });

  for (const [slug, list] of Object.entries(controls)) {
    const names = list.map((c) => c.count);
    const zero = Object.fromEntries(names.map((n) => [n, 0]));
    for (const c of list) {
      test(`${slug}: a click on ${c.id} adds one to its own count, and to no other`, async ({ page }) => {
        await open(page, slug);
        await expectCounts(page, slug, zero);
        await byId(page, c.id).click();
        await expectCounts(page, slug, { ...zero, [c.count]: 1 });
      });

      test(`${slug}: a click from assistive technology on ${c.id} adds one to its own count`, async ({ page }) => {
        await open(page, slug);
        await byId(page, c.id).dispatchEvent('click');
        await expectCounts(page, slug, { ...zero, [c.count]: 1 });
      });

      for (const key of ['Enter', 'Space']) {
        test(`${slug}: Tab reaches ${c.id} and ${key} adds one to its own count, and to no other`, async ({ page }) => {
          await open(page, slug);
          expect(await tabTo(page, byId(page, c.id)), 'Tab reaches it').toBe(true);
          await expect(byId(page, c.id)).toHaveAccessibleName(c.name);
          await page.keyboard.press(key);
          await expectCounts(page, slug, { ...zero, [c.count]: 1 });
        });
      }
    }
  }
});

test.describe('bad examples have their defect', () => {
  test('bad-default-container: the heading and the text are one level 3 heading, which holds the button', async ({ page }) => {
    await open(page, 'bad-default-container');
    const heading = page.getByRole('heading', { level: 3 });
    await expect(heading).toHaveCount(1);
    await expect(heading).toHaveAccessibleName(CARD);
    // The heading element holds the card's button.
    await expect(heading.getByRole('button', { name: `Save ${TRAIL}` })).toHaveCount(1);
    await expect(page.getByRole('heading', { name: TRAIL, exact: true })).toHaveCount(0);
    // Positive control: the button inside still works.
    await byId(page, 'c18-bad-default-container-save').click();
    await expectCounts(page, 'bad-default-container', { saves: 1 });
  });

  for (const key of ['Enter', 'Space']) {
    test(`bad-default-container: Tab reaches the button inside the heading, and ${key} activates it`, async ({ page }) => {
      // VoiceOver's next did not stop on this button (round 1); the
      // keyboard, with no screen reader, does.
      await open(page, 'bad-default-container');
      const save = byId(page, 'c18-bad-default-container-save');
      expect(await tabTo(page, save), 'Tab reaches the button').toBe(true);
      await expect(save).toHaveRole('button');
      await expect(save).toHaveAccessibleName(`Save ${TRAIL}`);
      await page.keyboard.press(key);
      await expectCounts(page, 'bad-default-container', { saves: 1 });
    });
  }

  test('bad-heading-button: the card is a level 3 heading and not a button (FL-262)', async ({ page }) => {
    await open(page, 'bad-heading-button');
    const card = byId(page, 'c18-bad-heading-button-card');
    await expect(card).toHaveRole('heading');
    expect(await card.evaluate((e) => e.tagName)).toBe('H3');
    await expect(card).toHaveAccessibleName(CARD);
    // No button but Back: the card's button role is gone.
    await expect(page.getByRole('button')).toHaveCount(1);
    await expect(page.getByRole('button', { name: 'Back' })).toHaveCount(1);
    expect(await cardTree(page)).toEqual([`- heading "${CARD}" [level=3]`]);
  });

  test('bad-heading-button: what still works: a click, and Tab then Enter', async ({ page }) => {
    // The defect is the role. Positive controls, each from a fresh load.
    await open(page, 'bad-heading-button');
    await byId(page, 'c18-bad-heading-button-card').click();
    await expectCounts(page, 'bad-heading-button', { opens: 1 });
    await open(page, 'bad-heading-button');
    expect(await tabTo(page, byId(page, 'c18-bad-heading-button-card'))).toBe(true);
    await page.keyboard.press('Enter');
    await expectCounts(page, 'bad-heading-button', { opens: 1 });
  });

  test('bad-heading-button: a click from assistive technology does nothing, where a mouse click opens it', async ({ page }) => {
    // A screen reader activates an element with a DOM click, with no
    // pointer events before it. On the card's <h3> it runs nothing
    // (docs/evidence/probes/c18/web_round2.txt). Positive controls in the
    // same load: a mouse click on the same element runs the handler, and a
    // DOM click on Back, the same path, acts.
    await open(page, 'bad-heading-button');
    const card = byId(page, 'c18-bad-heading-button-card');
    await card.dispatchEvent('click');
    await page.waitForTimeout(1000);
    await expectCounts(page, 'bad-heading-button', { opens: 0 });
    await card.click();
    await expectCounts(page, 'bad-heading-button', { opens: 1 });
    await page.getByRole('button', { name: 'Back' }).dispatchEvent('click');
    await expect(exampleHeading(page)).toHaveCount(0);
  });

  test('bad-ink-well: a button on the web, as any tappable node is (FL-006)', async ({ page }) => {
    // The defect is on Android and iOS (FL-401); the web is not affected.
    await open(page, 'bad-ink-well');
    const card = byId(page, 'c18-bad-ink-well-card');
    await expect(card).toHaveRole('button');
    await expect(card).toHaveAccessibleName(CARD);
    expect(await tabTo(page, card)).toBe(true);
    await page.keyboard.press('Enter');
    await expectCounts(page, 'bad-ink-well', { opens: 1 });
  });

  test('bad-read-more: a link named "Read more", outside the heading and the text', async ({ page }) => {
    await open(page, 'bad-read-more');
    expect(await cardTree(page)).toEqual([
      `- heading "${TRAIL}" [level=3]`,
      `- text: ${TEXT}`,
      `- link "Read more":`,
      `- /url: "#/t/C18"`,
    ]);
    const link = byId(page, 'c18-bad-read-more-link');
    await expect(link).toHaveRole('link');
    await expect(link).toHaveAccessibleName('Read more');
    await expect(link).toHaveAccessibleDescription('');
    await expect(link).toHaveAttribute('href', '#/t/C18');
    // Not in the heading, and the heading not in it; nothing names or
    // describes it by the heading.
    const heading = page.getByRole('heading', { name: TRAIL, exact: true, level: 3 });
    await expect(heading.getByRole('link')).toHaveCount(0);
    for (const attr of ['aria-labelledby', 'aria-describedby', 'aria-label']) {
      expect(await link.getAttribute(attr), attr).toBeNull();
    }
    // Positive control: Tab reaches it and Enter follows it.
    expect(await tabTo(page, link)).toBe(true);
    await page.keyboard.press('Enter');
    await expect(page).toHaveURL(/#\/t\/C18$/);
    await expect(page.getByRole('heading', { name: 'Card', level: 1 })).toBeVisible();
  });
});

// What the VoiceOver spec expects above each example's "Example" heading
// (EXAMPLE_SCREENS in vo/c18_vo_walks.js): each screen must show those
// texts, so that a change to a title or a defect is caught here.
test.describe('the stops the VoiceOver spec expects above each example', () => {
  for (const [slug, [title, ...lines]] of Object.entries(EXAMPLE_SCREENS)) {
    test(`${slug} shows its title and its lines`, async ({ page }) => {
      await open(page, slug);
      await expect(page.getByRole('heading', { level: 1, name: title, exact: true })).toHaveCount(1);
      for (const line of lines) {
        await expect(page.locator('flt-semantics-host').getByText(line, { exact: true })).toHaveCount(1);
      }
    });
  }
});

// How the web VoiceOver spec judges one walk of an example screen
// (judgeExampleWalk), and repeats one that fell short (runWalks). The walks
// here are made up; VoiceOver is not used.
test.describe('the VoiceOver example walks are judged on every walk', () => {
  const heading = `heading level 3 ${TRAIL}`;
  const expected = [heading, TEXT, `Sunrise over the valley image`, `Save ${TRAIL} button`, `Share ${TRAIL} button`, 'Saves: 0', 'Shares: 0'];
  const own = screenStops('good-material');
  const screen = (...content) => [...own, EXAMPLE_HEADING, ...content];
  const cases = [
    ['a correct walk', screen(...expected), true, 'complete'],
    // A stop read in other words, or out of its place: wrong at once.
    ['the heading and the text as one heading', screen(`heading level 3 ${CARD}`, ...expected.slice(2)), true, 'wrong'],
    ['the heading with no role', screen(TRAIL, ...expected.slice(1)), true, 'wrong'],
    ['a button with no role', screen(...expected.slice(0, 3), `Save ${TRAIL}`, ...expected.slice(4)), true, 'wrong'],
    ['the buttons swapped', screen(...expected.slice(0, 3), expected[4], expected[3], ...expected.slice(5)), true, 'wrong'],
    ['an empty reading', screen('', ...expected), true, 'wrong'],
    ['a stop read twice', screen(heading, heading, ...expected.slice(1)), true, 'wrong'],
    ['a stop after the counts', screen(...expected, 'end of main'), true, 'wrong'],
    ['a wrong reading in a walk cut short', screen(heading, TRAIL), false, 'wrong'],
    // A walk that reached the end with an expected stop not read: wrong,
    // not a short capture to be walked again.
    ['a walk that reached the end without the picture', screen(heading, TEXT, ...expected.slice(3)), true, 'wrong'],
    ['a walk that reached the end without the last count', screen(...expected.slice(0, -1)), true, 'wrong'],
    ['a walk that skipped the text and was cut short', screen(heading, expected[2]), false, 'wrong'],
    ['a walk with no title', [own[1], EXAMPLE_HEADING, ...expected], true, 'wrong'],
    ['a walk with no description', [own[0], EXAMPLE_HEADING, ...expected], true, 'wrong'],
    ['a walk with no heading', [...own, ...expected], true, 'wrong'],
    ['a walk of the card alone', [...expected], true, 'wrong'],
    ['a walk that reached the end having read nothing', [], true, 'wrong'],
    ['a walk that reached the end after the screen\'s own stops', [...own], true, 'wrong'],
    ['the screen\'s own stops out of their order', [own[1], own[0], EXAMPLE_HEADING, ...expected], true, 'wrong'],
    ['a stop that is not the screen\'s before the heading', ['Back button', ...own, EXAMPLE_HEADING, ...expected], true, 'wrong'],
    ['an empty first stop for the title', ['', ...own.slice(1), EXAMPLE_HEADING, ...expected], true, 'wrong'],
    ['an empty stop just before the heading', [...own, '', EXAMPLE_HEADING, ...expected], true, 'wrong'],
    // Cut short before the end, with every stop right so far: may be walked
    // again.
    ['an empty walk cut short', [], false, 'incomplete'],
    ['a walk cut short after the title', [own[0]], false, 'incomplete'],
    ['a walk cut short after the heading', [...own, EXAMPLE_HEADING], false, 'incomplete'],
    ['a walk cut short after the card\'s heading', screen(heading), false, 'incomplete'],
    ['every stop read, but the end not reached', screen(...expected), false, 'incomplete'],
  ];
  for (const [what, stops, reachedEnd, verdict] of cases) {
    test(`${what}: ${verdict}`, () => {
      expect(judgeExampleWalk(stops, reachedEnd, expected, own).verdict).toBe(verdict);
    });
  }

  test('a bad example\'s own stops include its defect', () => {
    expect(screenStops('bad-read-more').at(-1)).toMatch(/^Defect: /);
  });

  test('bad-default-container: the measured walk is complete, and a stop on the button is wrong', () => {
    // The expected list of web_tests/vo/c18_card_vo.spec.js, from round 1
    // (docs/evidence/probes/c18/voiceover-web-round1-fail.md.txt).
    const measured = [`heading level 3 ${CARD}`, 'Saves: 0'];
    const ownStops = screenStops('bad-default-container');
    const walk = (...content) => [...ownStops, EXAMPLE_HEADING, ...content];
    expect(judgeExampleWalk(walk(...measured), true, measured, ownStops).verdict).toBe('complete');
    expect(judgeExampleWalk(walk(measured[0], `Save ${TRAIL} button`, 'Saves: 0'), true, measured, ownStops).verdict)
      .toBe('wrong');
    expect(judgeExampleWalk(walk(measured[0]), true, measured, ownStops).verdict).toBe('wrong');
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
  const short = { stops: screen(heading), reachedEnd: false };

  for (const [what, walk] of [
    ['a wrong reading', { stops: screen(`heading level 3 ${CARD}`), reachedEnd: true }],
    ['a walk that reached the end without the picture', { stops: screen(heading, TEXT, ...expected.slice(3)), reachedEnd: true }],
    ['a walk with no title', { stops: [own[1], EXAMPLE_HEADING, ...expected], reachedEnd: true }],
    ['a walk with no heading', { stops: [...own, ...expected], reachedEnd: true }],
  ]) {
    test(`${what} followed by a right walk fails, and no second walk is made`, async () => {
      const { walkOnce, made } = sequence(walk, right);
      expect((await runWalks(walkOnce, judge)).verdict).toBe('wrong');
      expect(made()).toBe(1);
    });
  }

  test('a wrong walk after a short one still fails, and no third walk is made', async () => {
    const { walkOnce, made } = sequence(short, { stops: screen(heading, TEXT, ...expected.slice(3)), reachedEnd: true }, right);
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
