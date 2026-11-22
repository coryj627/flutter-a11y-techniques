// L3 for C04 Links inline with text on web: what the browser's
// accessibility tree exposes for links inside a sentence, and what a click,
// the keys, and a click from assistive technology do. Spec:
// docs/specs/C04-links-inline-with-text.md. Runs against the release build
// in build/web.
//
// Each sentence has two links, to C04's own page and to C03's. On the web
// the good links are <a href> and the browser follows them; the app does not
// (FL-013). "Followed once" is checked by the app's Back button: one press
// must bring the example back.
//
// The colour and underline of a link are drawn on Flutter's canvas, not in
// the page, so this layer cannot see bad-colour-only's defect; the widget
// tests assert it.
import { test, expect } from '@playwright/test';
import { byId, tabTo, technique } from './support/techniques.js';
import { EXAMPLE_HEADING, EXAMPLE_SCREENS, judgeExampleWalk, runWalks, screenStops } from './vo/c04_vo_walks.js';

const exampleHeading = (page) => page.getByRole('heading', { name: 'Example', exact: true, level: 2 });
const { open } = technique('C04', { ready: exampleHeading, settle: 600 });

const LINKS = [
  { name: 'links in text', href: '#/t/C04', page: 'Links inline with text', url: /#\/t\/C04$/ },
  { name: 'stand-alone links', href: '#/t/C03', page: 'Stand-alone link', url: /#\/t\/C03$/ },
];
const SENTENCE = ['Read about', 'links in text', 'and', 'stand-alone links', 'first.'];
// The page only bad-text-span opens (TextSpanPage).
const TEXT_SPAN_PAGE = 'About links in text';
const GOOD = ['good-material', 'good-cupertino', 'good-custom'];

const linkId = (slug, n) => `c04-${slug}-link-${n}`;

/** The page `link` goes to is on screen, and the example is not. */
async function expectOn(page, link) {
  await expect(page).toHaveURL(link.url);
  await expect(page.getByRole('heading', { name: link.page, exact: true, level: 1 })).toBeVisible();
  await expect(exampleHeading(page)).toHaveCount(0);
}

/** One press of the app's Back button brings the example back. */
async function backToExample(page, slug) {
  await page.getByRole('button', { name: 'Back' }).click();
  await expect(exampleHeading(page)).toBeVisible();
  await expect(page).toHaveURL(new RegExp(`#/t/C04/${slug}$`));
}

/** Waits, then checks that the example is still on screen, unfollowed. */
async function expectStillOnExample(page, slug) {
  await page.waitForTimeout(1000);
  await expect(page).toHaveURL(new RegExp(`#/t/C04/${slug}$`));
  await expect(exampleHeading(page)).toBeVisible();
}

/** The text of each child element of the sentence, in the page's order. */
async function sentenceParts(page, slug) {
  return byId(page, linkId(slug, 1)).evaluate((link) =>
    [...link.parentElement.children].map((e) => (e.getAttribute('aria-label') || e.textContent).trim()));
}

/** What has keyboard focus, as a short description. */
async function focusedName(page) {
  return page.evaluate(() => {
    const e = document.activeElement;
    if (!e || !e.closest('flt-semantics-host')) return '(page)';
    return (e.getAttribute('aria-label') || e.textContent).replace(/\s+/g, ' ').trim();
  });
}

test.describe('good examples', () => {
  for (const slug of GOOD) {
    test(`${slug}: two links with their href and name, and no other control but Back`, async ({ page }) => {
      await open(page, slug);
      for (const [i, link] of LINKS.entries()) {
        const el = byId(page, linkId(slug, i + 1));
        await expect(el).toHaveRole('link');
        await expect(el).toHaveAccessibleName(link.name);
        await expect(el).toHaveAttribute('href', link.href);
        expect(await el.evaluate((e) => e.tagName)).toBe('A');
        await expect(el.getByRole('button')).toHaveCount(0);
      }
      await expect(page.getByRole('link')).toHaveCount(2);
      await expect(page.getByRole('button')).toHaveCount(1);
    });

    test(`${slug}: the sentence is its words and links in order`, async ({ page }) => {
      await open(page, slug);
      expect(await sentenceParts(page, slug)).toEqual(SENTENCE);
      // Each link sits between the words round it: element 1 and 3.
      const roles = await byId(page, linkId(slug, 1)).evaluate((link) =>
        [...link.parentElement.children].map((e) => e.tagName));
      expect(roles).toEqual(['FLT-SEMANTICS', 'A', 'FLT-SEMANTICS', 'A', 'FLT-SEMANTICS']);
    });

    test(`${slug}: Tab goes Back, the first link, the second link`, async ({ page }) => {
      await open(page, slug);
      const stops = [];
      for (let i = 0; i < 3; i++) {
        await page.keyboard.press('Tab');
        await page.waitForTimeout(150);
        stops.push(await focusedName(page));
      }
      expect(stops).toEqual(['Back', LINKS[0].name, LINKS[1].name]);
    });

    for (const [i, link] of LINKS.entries()) {
      const id = linkId(slug, i + 1);
      test(`${slug}: a click follows link ${i + 1} once, in this tab`, async ({ page, context }) => {
        await open(page, slug);
        await byId(page, id).click();
        await expectOn(page, link);
        expect(context.pages()).toHaveLength(1);
        await backToExample(page, slug);
      });

      test(`${slug}: a click from assistive technology follows link ${i + 1} once`, async ({ page }) => {
        // A DOM click with no pointer events before it, in place of what a
        // screen reader sends; what VoiceOver itself sends was not measured.
        await open(page, slug);
        await byId(page, id).dispatchEvent('click');
        await expectOn(page, link);
        await backToExample(page, slug);
      });

      test(`${slug}: Tab reaches link ${i + 1} and Enter follows it once`, async ({ page }) => {
        await open(page, slug);
        expect(await tabTo(page, byId(page, id)), 'Tab reaches the link').toBe(true);
        await page.keyboard.press('Enter');
        await expectOn(page, link);
        await backToExample(page, slug);
      });

      test(`${slug}: Space does not follow link ${i + 1}, as for any link; Enter then does`, async ({ page }) => {
        await open(page, slug);
        const el = byId(page, id);
        expect(await tabTo(page, el), 'Tab reaches the link').toBe(true);
        await page.keyboard.press('Space');
        await expectStillOnExample(page, slug);
        // The positive control, through the same focus in the same load.
        await expect(el).toBeFocused();
        await page.keyboard.press('Enter');
        await expectOn(page, link);
      });

      test(`${slug}: Command- or Ctrl-click opens link ${i + 1} in a new tab and leaves this one`, async ({ page, context }) => {
        await open(page, slug);
        const opened = context.waitForEvent('page');
        await byId(page, id).click({ modifiers: ['ControlOrMeta'] });
        const tab = await opened;
        await expect(tab).toHaveURL(link.url);
        await expectStillOnExample(page, slug);
      });
    }
  }
});

test.describe('bad examples have their defect', () => {
  const spanLink = 'c04-bad-text-span-link-1';

  test('bad-text-span: an <a> with no href that Tab never reaches', async ({ page }) => {
    await open(page, 'bad-text-span');
    const el = byId(page, spanLink);
    expect(await el.evaluate((e) => e.tagName)).toBe('A');
    await expect(el).not.toHaveAttribute('href');
    await expect(el).not.toHaveAttribute('tabindex');
    await expect(el).toHaveText(LINKS[0].name);
    // HTML gives an <a> with no href no link role (Chromium's own tree
    // still calls it a link: docs/evidence/probes/c04/web.txt).
    await expect(page.getByRole('link')).toHaveCount(0);
    // The positive control: Tab does reach Back, the one other control.
    expect(await tabTo(page, page.getByRole('button', { name: 'Back' })), 'Tab reaches Back').toBe(true);
    await page.locator('body').click({ position: { x: 1, y: 1 } });
    expect(await tabTo(page, el), 'Tab skips the link').toBe(false);
    // A click still opens its page, which is what hides the defect.
    await el.click();
    await expect(page.getByRole('heading', { name: TEXT_SPAN_PAGE, level: 1 })).toBeVisible();
  });

  for (const key of ['Enter', 'Space']) {
    test(`bad-text-span: no key opens its page; Tab stops only on Back, and ${key} there goes elsewhere`, async ({ page }) => {
      await open(page, 'bad-text-span');
      // Every control eight presses of Tab stop on: only Back. Stops
      // outside the semantics tree (the page itself, when focus goes round,
      // FL-421) are not controls and are left out.
      const stops = new Set();
      for (let i = 0; i < 8; i++) {
        await page.keyboard.press('Tab');
        await page.waitForTimeout(100);
        stops.add(await focusedName(page));
      }
      expect([...stops].filter((s) => s !== '(page)')).toEqual(['Back']);
      expect(await tabTo(page, page.getByRole('button', { name: 'Back' })), 'Tab reaches Back').toBe(true);
      await page.keyboard.press(key);
      await expect(page.getByRole('heading', { name: 'Links inline with text', level: 1 })).toBeVisible();
      await expect(page.getByRole('heading', { name: TEXT_SPAN_PAGE, level: 1 })).toHaveCount(0);
    });
  }

  test('bad-out-of-order: the sentence is a group named without its links, and the links are inside it after its words', async ({ page }) => {
    await open(page, 'bad-out-of-order');
    const first = byId(page, linkId('bad-out-of-order', 1));
    const group = first.locator('xpath=..');
    await expect(group).toHaveRole('group');
    await expect(group).toHaveAccessibleName('Read about and first.');
    // Inside it, the two links and nothing else.
    expect(await group.evaluate((g) => [...g.children].map((e) => e.textContent.trim()))).toEqual([
      LINKS[0].name,
      LINKS[1].name,
    ]);
    await expect(page.getByRole('link')).toHaveCount(2);
  });

  test('bad-merged: one link, the whole sentence, to the first link\'s page', async ({ page }) => {
    await open(page, 'bad-merged');
    const el = byId(page, 'c04-bad-merged-sentence');
    await expect(el).toHaveRole('link');
    await expect(el).toHaveAccessibleName('Read about links in text and stand-alone links first.');
    await expect(el).toHaveAttribute('href', LINKS[0].href);
    await expect(page.getByRole('link')).toHaveCount(1);
  });

  // Where the parts of the sentence are drawn, measured from the sentence's
  // top left in good-material, whose sentence is laid out the same
  // (docs/evidence/probes/c04/web_merged.txt): the first link's words, the
  // second link's, and the first words, "Read about".
  for (const part of ['the first link', 'the second link', 'the words "Read about"']) {
    test(`bad-merged: a click on ${part} opens the first link's page`, async ({ page }) => {
      await open(page, 'good-material');
      const sentence = await byId(page, linkId('good-material', 1)).evaluate((e) => {
        const r = e.parentElement.getBoundingClientRect();
        return { x: r.x, y: r.y, height: r.height };
      });
      let box = { x: sentence.x, y: sentence.y, width: 20, height: Math.min(sentence.height, 24) };
      if (part === 'the first link') box = await byId(page, linkId('good-material', 1)).boundingBox();
      if (part === 'the second link') box = await byId(page, linkId('good-material', 2)).boundingBox();
      await open(page, 'bad-merged');
      const merged = await byId(page, 'c04-bad-merged-sentence').boundingBox();
      const x = merged.x + (box.x - sentence.x) + box.width / 2;
      const y = merged.y + (box.y - sentence.y) + box.height / 2;
      // The point is on the one element, so the click is its.
      expect(await page.evaluate(([x, y]) => document.elementFromPoint(x, y)?.getAttribute('flt-semantics-identifier'), [x, y]))
        .toBe('c04-bad-merged-sentence');
      await page.mouse.click(x, y);
      await expectOn(page, LINKS[0]);
    });
  }

  for (const tabs of [2, 3]) {
    test(`bad-merged: after ${tabs} Tabs focus is on the one element, and Enter follows the first link`, async ({ page }) => {
      await open(page, 'bad-merged');
      const whole = 'Read about links in text and stand-alone links first.';
      const stops = [];
      for (let i = 0; i < tabs; i++) {
        await page.keyboard.press('Tab');
        await page.waitForTimeout(150);
        stops.push(await focusedName(page));
      }
      // Back, then the one element once for each of the two links' focus
      // nodes, which are still there. After three Tabs Flutter's focus is on
      // the second link; the key goes to the browser, which follows the
      // element's one href.
      expect(stops).toEqual(['Back', ...Array(tabs - 1).fill(whole)]);
      await page.keyboard.press('Enter');
      await expectOn(page, LINKS[0]);
    });
  }
});

// The VoiceOver spec takes these texts as the only stops that may come
// before an example's "Example" heading (EXAMPLE_SCREENS). Each screen must
// show them, so that a change to a title or a defect is caught here.
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
  const expected = ['Read about', 'link links in text', 'and', 'link stand-alone links', 'first.'];
  const own = screenStops('good-material');
  const screen = (...content) => [...own, EXAMPLE_HEADING, ...content];
  const cases = [
    ['a correct walk', screen(...expected), true, 'complete'],
    // A stop read in other words, or out of its place: wrong at once.
    ['a link with no role', screen('Read about', 'links in text', 'and', 'link stand-alone links', 'first.'), true, 'wrong'],
    ['the sentence without its links, then the links', screen('Read about and first. group', 'link links in text', 'link stand-alone links'), true, 'wrong'],
    ['one link for the whole sentence', screen('link Read about links in text and stand-alone links first.'), true, 'wrong'],
    ['an empty reading', screen('', ...expected), true, 'wrong'],
    ['the links swapped', screen('Read about', 'link stand-alone links', 'and', 'link links in text', 'first.'), true, 'wrong'],
    ['a stop read twice', screen('Read about', 'link links in text', 'link links in text', 'and', 'link stand-alone links', 'first.'), true, 'wrong'],
    ['a stop after the sentence', screen(...expected, 'end of main'), true, 'wrong'],
    ['a wrong reading in a walk cut short', screen('Read about', 'links in text'), false, 'wrong'],
    // A walk that reached the end with an expected stop not read: wrong,
    // not a short capture to be walked again (Codex round 1, finding 1).
    ['a walk that reached the end without the first link', screen('Read about', 'and', 'link stand-alone links', 'first.'), true, 'wrong'],
    ['a walk that reached the end without the last words', screen('Read about', 'link links in text', 'and', 'link stand-alone links'), true, 'wrong'],
    ['a walk that skipped the first link and was cut short', screen('Read about', 'and'), false, 'wrong'],
    ['a walk with no title', [own[1], EXAMPLE_HEADING, ...expected], true, 'wrong'],
    ['a walk with no title and no description', [EXAMPLE_HEADING, ...expected], true, 'wrong'],
    ['a walk with no description', [own[0], EXAMPLE_HEADING, ...expected], true, 'wrong'],
    ['a walk with no heading', [...own, ...expected], true, 'wrong'],
    ['a walk of the sentence alone', [...expected], true, 'wrong'],
    ['a walk that reached the end having read nothing', [], true, 'wrong'],
    ['a walk that reached the end after the screen\'s own stops', [...own], true, 'wrong'],
    ['the screen\'s own stops out of their order', [own[1], own[0], EXAMPLE_HEADING, ...expected], true, 'wrong'],
    ['a stop that is not the screen\'s before the heading', ['Back button', ...own, EXAMPLE_HEADING, ...expected], true, 'wrong'],
    // No exception for an empty first stop in C04 (no C04 walk has shown it).
    ['an empty first stop for the title', ['', ...own.slice(1), EXAMPLE_HEADING, ...expected], true, 'wrong'],
    ['an empty first stop alone', [''], false, 'wrong'],
    ['an empty stop just before the heading', [...own, '', EXAMPLE_HEADING, ...expected], true, 'wrong'],
    // Cut short before the end, with every stop right so far: may be walked
    // again.
    ['an empty walk cut short', [], false, 'incomplete'],
    ['a walk cut short after the title', [own[0]], false, 'incomplete'],
    ['a walk cut short after the heading', [...own, EXAMPLE_HEADING], false, 'incomplete'],
    ['a walk cut short after the first link', screen('Read about', 'link links in text'), false, 'incomplete'],
    ['every stop read, but the end not reached', screen(...expected), false, 'incomplete'],
  ];
  for (const [what, stops, reachedEnd, verdict] of cases) {
    test(`${what}: ${verdict}`, () => {
      expect(judgeExampleWalk(stops, reachedEnd, expected, own).verdict).toBe(verdict);
    });
  }

  test('a bad example\'s own stops include its defect', () => {
    expect(screenStops('bad-merged').at(-1)).toMatch(/^Defect: /);
  });

  const judge = (stops, reachedEnd) => judgeExampleWalk(stops, reachedEnd, expected, own);
  const sequence = (...list) => {
    let i = 0;
    return { walkOnce: async () => list[i++], made: () => i };
  };
  const right = { stops: screen(...expected), reachedEnd: true };
  const short = { stops: screen('Read about'), reachedEnd: false };

  for (const [what, walk] of [
    ['a wrong reading', { stops: screen('Read about', 'links in text'), reachedEnd: true }],
    ['a walk that reached the end without the first link', { stops: screen('Read about', 'and', 'link stand-alone links', 'first.'), reachedEnd: true }],
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
    const { walkOnce, made } = sequence(short, { stops: screen('Read about', 'and', 'link stand-alone links', 'first.'), reachedEnd: true }, right);
    expect((await runWalks(walkOnce, judge)).verdict).toBe('wrong');
    expect(made()).toBe(2);
  });

  test('an empty walk cut short, followed by a right one, passes on the second', async () => {
    const { walkOnce } = sequence({ stops: [], reachedEnd: false }, right);
    expect(await runWalks(walkOnce, judge)).toMatchObject({ verdict: 'complete', walks: 2 });
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
