// L3 for C05 Accordion on web: what the browser's accessibility tree
// exposes for each header and panel, and what a click, a click from
// assistive technology, Tab, Enter, and Space do. Spec:
// docs/specs/C05-accordion.md. Runs against the release build in build/web.
//
// The good examples follow APG's markup: each header is a button with
// aria-expanded inside a heading of level 3, and a closed panel is not in
// the page.
import { test, expect } from '@playwright/test';
import { byId, technique } from './support/techniques.js';
import { EXAMPLE_HEADING, EXAMPLE_SCREENS, judgeExampleWalk, runWalks, screenStops } from './vo/c05_vo_walks.js';

const exampleHeading = (page) => page.getByRole('heading', { name: 'Example', exact: true, level: 2 });
const { open, count } = technique('C05', { ready: exampleHeading, settle: 600 });

const SHIPPING = 'Shipping';
const RETURNS = 'Returns';
const SHIPPING_TEXT = 'Orders ship in two days.';
const SHIPPING_ACTION = 'Track a parcel';
const RETURNS_ACTION = 'Start a return';

const good = ['good-material', 'good-cupertino', 'good-custom'];
const id = (slug, key) => `c05-${slug}-${key}`;

/** What has DOM focus: its role and its accessible name, or "(page)". */
async function focused(page) {
  return page.evaluate(() => {
    const e = document.activeElement;
    if (!e || e === document.body || e.tagName === 'FLUTTER-VIEW') return '(page)';
    return (e.getAttribute('aria-label') || e.textContent || '').trim();
  });
}

/** The name of each stop of `tabs` presses of Tab, from where focus is. */
async function tabStops(page, tabs) {
  const stops = [];
  for (let i = 0; i < tabs; i++) {
    await page.keyboard.press('Tab');
    await page.waitForTimeout(150);
    stops.push(await focused(page));
  }
  return stops;
}

/** Tab until the header `name` has focus, at most six times. */
async function tabToHeader(page, name) {
  for (let i = 0; i < 6; i++) {
    await page.keyboard.press('Tab');
    await page.waitForTimeout(150);
    if ((await focused(page)) === name) return true;
  }
  return false;
}

/** Whether `text` is in the page, as an element's text or in its name. */
async function shown(page, text) {
  return page.locator('flt-semantics-host').evaluate(
    (host, text) => [...host.querySelectorAll('*')].some((e) => (e.getAttribute('aria-label') || '').includes(text) || [...e.childNodes].some((n) => n.nodeType === 3 && n.textContent.includes(text))),
    text,
  );
}

/** The text of every element of the example in DOM order, from the first header to the count. */
async function reading(page) {
  const texts = await page.locator('flt-semantics-host').evaluate((host) => {
    const out = [];
    for (const e of host.querySelectorAll('*')) {
      const own = [...e.childNodes].filter((n) => n.nodeType === 3).map((n) => n.textContent.trim()).join('');
      const name = e.getAttribute('aria-label') || own;
      if (name) out.push(name);
    }
    return out;
  });
  const start = texts.indexOf(SHIPPING);
  const end = texts.findIndex((t) => t.startsWith('Presses: '));
  expect(start, 'the first header is in the page').toBeGreaterThanOrEqual(0);
  expect(end, 'the count comes last').toBeGreaterThan(start);
  return texts.slice(start, end);
}

test.describe('good examples', () => {
  for (const slug of good) {
    test(`${slug}: each header is a button with aria-expanded inside a level 3 heading`, async ({ page }) => {
      await open(page, slug);
      for (const [key, name] of [['shipping', SHIPPING], ['returns', RETURNS]]) {
        const header = byId(page, id(slug, key));
        await expect(header).toHaveRole('button');
        await expect(header).toHaveAccessibleName(name);
        await expect(header).toHaveAttribute('aria-expanded', 'false');
        // The heading holds the button, as APG's <h3><button> does.
        const heading = page.getByRole('heading', { name, exact: true, level: 3 });
        await expect(heading).toHaveCount(1);
        await expect(heading.getByRole('button', { name, exact: true, expanded: false })).toHaveCount(1);
        expect(await header.evaluate((e) => e.parentElement.tagName)).toBe('H3');
      }
      // Two headers, the only buttons but Back, and two level 3 headings.
      await expect(page.getByRole('button')).toHaveCount(3);
      await expect(page.getByRole('heading', { level: 3 })).toHaveCount(2);
      // A closed panel is not in the page.
      await expect(page.getByText(SHIPPING_TEXT)).toHaveCount(0);
      expect(await reading(page)).toEqual([SHIPPING, RETURNS]);
    });

    test(`${slug}: a click opens a section straight after its header, and a second closes it`, async ({ page }) => {
      await open(page, slug);
      const header = byId(page, id(slug, 'shipping'));
      await expect(header).not.toHaveAttribute('aria-controls');
      await header.click();
      await expect(header).toHaveAttribute('aria-expanded', 'true');
      await expect(byId(page, id(slug, 'returns'))).toHaveAttribute('aria-expanded', 'false');
      // aria-controls names the open panel's element (FL-266).
      const panel = byId(page, `${id(slug, 'shipping')}-panel`);
      await expect(panel).toHaveCount(1);
      const panelElement = await panel.getAttribute('id');
      await expect(header).toHaveAttribute('aria-controls', panelElement);
      await expect(byId(page, id(slug, 'returns'))).not.toHaveAttribute('aria-controls');
      await expect(page.getByText(SHIPPING_TEXT)).toHaveCount(1);
      expect(await reading(page)).toEqual([SHIPPING, SHIPPING_TEXT, SHIPPING_ACTION, RETURNS]);
      await header.click();
      await expect(header).toHaveAttribute('aria-expanded', 'false');
      await expect(page.getByText(SHIPPING_TEXT)).toHaveCount(0);
    });

    test(`${slug}: a click from assistive technology opens it`, async ({ page }) => {
      // A screen reader activates an element with a DOM click, with no
      // pointer events before it.
      await open(page, slug);
      const header = byId(page, id(slug, 'shipping'));
      await header.dispatchEvent('click');
      await expect(header).toHaveAttribute('aria-expanded', 'true');
      await expect(page.getByText(SHIPPING_TEXT)).toHaveCount(1);
    });

    for (const key of ['Enter', 'Space']) {
      test(`${slug}: Tab reaches a header and ${key} opens and closes it`, async ({ page }) => {
        await open(page, slug);
        const header = byId(page, id(slug, 'shipping'));
        expect(await tabToHeader(page, SHIPPING), 'Tab reaches the header').toBe(true);
        await page.keyboard.press(key);
        await expect(header).toHaveAttribute('aria-expanded', 'true');
        await expect(page.getByText(SHIPPING_TEXT)).toHaveCount(1);
        expect(await focused(page), 'focus stays on the header').toBe(SHIPPING);
        await page.keyboard.press(key);
        await expect(header).toHaveAttribute('aria-expanded', 'false');
        await expect(page.getByText(SHIPPING_TEXT)).toHaveCount(0);
      });
    }

    test(`${slug}: Tab skips closed panels and goes into an open one, whose button Enter presses`, async ({ page }) => {
      await open(page, slug);
      expect(await tabStops(page, 3)).toEqual(['Back', SHIPPING, RETURNS]);
      await byId(page, id(slug, 'shipping')).click();
      await expect(page.getByText(SHIPPING_TEXT)).toHaveCount(1);
      await page.evaluate(() => document.activeElement?.blur());
      expect(await tabToHeader(page, SHIPPING)).toBe(true);
      expect(await tabStops(page, 2)).toEqual([SHIPPING_ACTION, RETURNS]);
      await page.keyboard.press('Shift+Tab');
      await page.waitForTimeout(150);
      expect(await focused(page)).toBe(SHIPPING_ACTION);
      await page.keyboard.press('Enter');
      await expect(count(page, slug)).toHaveText('Presses: 1');
    });
  }
});

test.describe('bad examples have their defect', () => {
  test('bad-no-state: buttons in headings, with no aria-expanded before or after a click that opens one', async ({ page }) => {
    await open(page, 'bad-no-state');
    const header = byId(page, id('bad-no-state', 'shipping'));
    await expect(header).toHaveRole('button');
    await expect(page.getByRole('heading', { name: SHIPPING, exact: true, level: 3 })).toHaveCount(1);
    await expect(header).not.toHaveAttribute('aria-expanded');
    await header.click();
    // The positive control: the click opened the section.
    await expect(page.getByText(SHIPPING_TEXT)).toHaveCount(1);
    await expect(header).not.toHaveAttribute('aria-expanded');
  });

  test('bad-heading-on-button: each header is a heading only, with no button role and no aria-expanded', async ({ page }) => {
    await open(page, 'bad-heading-on-button');
    const header = byId(page, id('bad-heading-on-button', 'shipping'));
    expect(await header.evaluate((e) => e.tagName)).toBe('H3');
    await expect(header).toHaveRole('heading');
    await expect(header).not.toHaveAttribute('aria-expanded');
    await expect(header.getByRole('button')).toHaveCount(0);
    // Back is the only button on the screen.
    await expect(page.getByRole('button')).toHaveCount(1);
    // It still opens by a click and by the keys, which is what hides the
    // defect from someone who does not use a screen reader.
    await header.click();
    await expect(page.getByText(SHIPPING_TEXT)).toHaveCount(1);
    await expect(header).not.toHaveAttribute('aria-expanded');
  });

  test('bad-no-heading: buttons with aria-expanded and no heading', async ({ page }) => {
    await open(page, 'bad-no-heading');
    const header = byId(page, id('bad-no-heading', 'shipping'));
    await expect(header).toHaveRole('button');
    await expect(header).toHaveAttribute('aria-expanded', 'false');
    await expect(page.getByRole('heading', { level: 3 })).toHaveCount(0);
    // The only headings are the screen's own: its title and "Example".
    await expect(page.getByRole('heading')).toHaveCount(2);
  });

  test('bad-hidden-panel: closed panels are not in the page, but Tab leaves the page for them and Enter presses one', async ({ page }) => {
    await open(page, 'bad-hidden-panel');
    await expect(page.getByText(SHIPPING_TEXT)).toHaveCount(0);
    await expect(page.getByRole('button', { name: SHIPPING_ACTION })).toHaveCount(0);
    expect(await reading(page)).toEqual([SHIPPING, RETURNS]);
    // Flutter's focus goes to the hidden buttons, which have no element:
    // the page's focus stays on the last header it had.
    expect(await tabStops(page, 5)).toEqual(['Back', SHIPPING, RETURNS, RETURNS, RETURNS]);
    await expect(count(page, 'bad-hidden-panel')).toHaveText('Presses: 0');
    // Focus is now on the second hidden button (the widget tests show the
    // first is Shipping's). Enter presses it, and both sections stay closed.
    await page.keyboard.press('Enter');
    await expect(count(page, 'bad-hidden-panel')).toHaveText('Presses: 1');
    for (const key of ['shipping', 'returns']) {
      await expect(byId(page, id('bad-hidden-panel', key))).toHaveAttribute('aria-expanded', 'false');
    }
    await expect(page.getByRole('button', { name: SHIPPING_ACTION })).toHaveCount(0);
    await expect(page.getByRole('button', { name: RETURNS_ACTION })).toHaveCount(0);
  });

  test('bad-hidden-panel: the positive control, Enter on a header opens it', async ({ page }) => {
    await open(page, 'bad-hidden-panel');
    expect(await tabToHeader(page, RETURNS)).toBe(true);
    await page.keyboard.press('Enter');
    await expect(byId(page, id('bad-hidden-panel', 'returns'))).toHaveAttribute('aria-expanded', 'true');
    await expect(count(page, 'bad-hidden-panel')).toHaveText('Presses: 0');
  });

  test('bad-expansion-tile: a button with no aria-expanded; the state is in its description', async ({ page }) => {
    await open(page, 'bad-expansion-tile');
    const header = page.getByRole('button', { name: SHIPPING, exact: true });
    await expect(header).toHaveCount(1);
    await expect(header).not.toHaveAttribute('aria-expanded');
    await expect(header).toHaveAccessibleDescription(/^Collapsed/);
    await expect(page.getByRole('heading', { level: 3 })).toHaveCount(0);
    await header.click();
    await expect(page.getByText(SHIPPING_TEXT)).toHaveCount(1);
    await expect(header).not.toHaveAttribute('aria-expanded');
    await expect(header).toHaveAccessibleDescription(/^Expanded/);
  });

  for (const key of ['Enter', 'Space']) {
    test(`bad-cupertino-expansion-tile: Tab reaches only Back, and ${key} there leaves the example`, async ({ page }) => {
      await open(page, 'bad-cupertino-expansion-tile');
      const stops = await tabStops(page, 4);
      // Every stop in Flutter's tree is Back; going round, focus can pass
      // through the page itself (FL-421), which holds no control.
      expect(stops.filter((s) => s !== '(page)')).toEqual(stops.filter((s) => s !== '(page)').map(() => 'Back'));
      expect(stops).toContain('Back');
      expect(stops).not.toContain(SHIPPING);
      // Put focus on Back and press the key: Back acts, the positive control.
      await page.evaluate(() => document.activeElement?.blur());
      expect(await tabToHeader(page, 'Back')).toBe(true);
      await page.keyboard.press(key);
      await expect(exampleHeading(page)).toHaveCount(0);
      await expect(page).toHaveURL(/#\/t\/C05$/);
    });
  }

  test('bad-cupertino-expansion-tile: the header takes no focus and has no aria-expanded; a click opens it', async ({ page }) => {
    await open(page, 'bad-cupertino-expansion-tile');
    const header = page.getByRole('button', { name: SHIPPING, exact: true });
    await expect(header).toHaveCount(1);
    await expect(header).not.toHaveAttribute('tabindex');
    await expect(header).not.toHaveAttribute('aria-expanded');
    // The state is text in its description, the tile's hint (on a macOS
    // browser, where the tile gives one: FL-265).
    await expect(header).toHaveAccessibleDescription(/^Collapsed/);
    expect(await shown(page, SHIPPING_TEXT)).toBe(false);
    await header.click();
    await expect.poll(() => shown(page, SHIPPING_TEXT)).toBe(true);
    // Open, the header is one button with the panel's text, still with no
    // aria-expanded, its description now "Expanded".
    const merged = page.getByRole('button', { name: `${SHIPPING} ${SHIPPING_TEXT}` });
    await expect(merged).toHaveCount(1);
    await expect(merged).not.toHaveAttribute('aria-expanded');
    await expect(merged).toHaveAccessibleDescription(/^Expanded/);
  });
});

// Once a CupertinoExpansionTile has been opened, an empty element the size
// of the view lies over the page and takes pointer events (FL-029,
// extended; found when the web VoiceOver walk's checked click on the
// "Example" heading never succeeded). Written as F10's test of the same
// element, to fail when it goes. The other examples have none.
test.describe('the empty element over the page', () => {
  const fullScreenEmpty = (page) =>
    page.evaluate(() =>
      [...document.querySelectorAll('flt-semantics')].filter((e) => {
        const r = e.getBoundingClientRect();
        return (
          e.childElementCount === 0 &&
          e.textContent === '' &&
          e.attributes.length === 2 && // id and style only
          r.width >= window.innerWidth - 1 &&
          r.height >= window.innerHeight - 1
        );
      }).map((e) => e.style.pointerEvents));
  const exampleHeadingIsHit = (page) =>
    page.evaluate(() => {
      const h = [...document.querySelectorAll('h2')].find((e) => e.textContent === 'Example');
      const r = h.getBoundingClientRect();
      return document.elementFromPoint(r.x + r.width / 2, r.y + r.height / 2) === h;
    });
  const openShipping = async (page, slug) => {
    const header = slug.endsWith('expansion-tile')
      ? page.getByRole('button', { name: SHIPPING, exact: true })
      : byId(page, id(slug, 'shipping'));
    await header.click();
    await expect.poll(() => shown(page, SHIPPING_TEXT)).toBe(true);
    await page.waitForTimeout(1000);
  };

  for (const slug of [...good, 'bad-no-state', 'bad-heading-on-button', 'bad-no-heading', 'bad-hidden-panel', 'bad-expansion-tile', 'bad-cupertino-expansion-tile']) {
    const appears = slug === 'bad-cupertino-expansion-tile';
    test(`${slug}: ${appears ? 'none while closed, one once opened' : 'none, closed or open'}`, async ({ page }) => {
      await open(page, slug);
      expect(await fullScreenEmpty(page)).toEqual([]);
      expect(await exampleHeadingIsHit(page)).toBe(true);
      await openShipping(page, slug);
      expect(await fullScreenEmpty(page)).toEqual(appears ? ['auto'] : []);
      expect(await exampleHeadingIsHit(page)).toBe(!appears);
    });
  }

  test('bad-cupertino-expansion-tile: once opened, a checked click on the heading is refused, and a real mouse click still reaches Flutter', async ({ page }) => {
    await open(page, 'bad-cupertino-expansion-tile');
    await openShipping(page, 'bad-cupertino-expansion-tile');
    const heading = exampleHeading(page);
    await expect(heading.click({ timeout: 1500 })).rejects.toThrow(/intercepts pointer events|Timeout/);
    // A real mouse click at the Returns header's place opens Returns.
    const returns = page.getByRole('button', { name: RETURNS, exact: true });
    const box = await returns.boundingBox();
    await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
    await expect.poll(() => shown(page, 'Return items within 30 days.')).toBe(true);
  });
});

// How the web VoiceOver spec judges one walk of an example screen
// (judgeExampleWalk), and repeats one that fell short (runWalks), as C04's
// does. The walks here are made up; VoiceOver is not used.
test.describe('the VoiceOver example walks are judged on every walk', () => {
  const expected = ['heading level 3 Shipping collapsed button', 'heading level 3 Returns collapsed button', 'Presses: 0'];
  const own = screenStops('good-custom');
  const screen = (...content) => [...own, EXAMPLE_HEADING, ...content];
  const cases = [
    ['a correct walk', screen(...expected), true, 'complete'],
    // A stop read in other words, or out of its place: wrong at once.
    ['a header with no state', screen('heading level 3 Shipping button', ...expected.slice(1)), true, 'wrong'],
    ['the headers swapped', screen(expected[1], expected[0], expected[2]), true, 'wrong'],
    ['an empty reading', screen('', ...expected), true, 'wrong'],
    ['a stop read twice', screen(expected[0], ...expected), true, 'wrong'],
    ['a stop after the count', screen(...expected, 'end of main'), true, 'wrong'],
    ['a wrong reading in a walk cut short', screen('heading level 3 Shipping'), false, 'wrong'],
    // A walk that reached the end with an expected stop not read: wrong,
    // not a short capture to be walked again.
    ['a walk that reached the end without the second header', screen(expected[0], expected[2]), true, 'wrong'],
    ['a walk that reached the end without the count', screen(expected[0], expected[1]), true, 'wrong'],
    ['a walk that skipped the first header and was cut short', screen(expected[1]), false, 'wrong'],
    ['a walk with no title', [own[1], EXAMPLE_HEADING, ...expected], true, 'wrong'],
    ['a walk with no description', [own[0], EXAMPLE_HEADING, ...expected], true, 'wrong'],
    ['a walk with no heading', [...own, ...expected], true, 'wrong'],
    ['a walk of the example alone', [...expected], true, 'wrong'],
    ['a walk that reached the end having read nothing', [], true, 'wrong'],
    ["a walk that reached the end after the screen's own stops", [...own], true, 'wrong'],
    ["the screen's own stops out of their order", [own[1], own[0], EXAMPLE_HEADING, ...expected], true, 'wrong'],
    ["a stop that is not the screen's before the heading", ['Back button', ...own, EXAMPLE_HEADING, ...expected], true, 'wrong'],
    // No exception for an empty first stop.
    ['an empty first stop for the title', ['', ...own.slice(1), EXAMPLE_HEADING, ...expected], true, 'wrong'],
    ['an empty first stop alone', [''], false, 'wrong'],
    ['an empty stop just before the heading', [...own, '', EXAMPLE_HEADING, ...expected], true, 'wrong'],
    // Cut short before the end, with every stop right so far: may be walked
    // again.
    ['an empty walk cut short', [], false, 'incomplete'],
    ['a walk cut short after the title', [own[0]], false, 'incomplete'],
    ['a walk cut short after the heading', [...own, EXAMPLE_HEADING], false, 'incomplete'],
    ['a walk cut short after the first header', screen(expected[0]), false, 'incomplete'],
    ['every stop read, but the end not reached', screen(...expected), false, 'incomplete'],
  ];
  for (const [what, stops, reachedEnd, verdict] of cases) {
    test(`${what}: ${verdict}`, () => {
      expect(judgeExampleWalk(stops, reachedEnd, expected, own).verdict).toBe(verdict);
    });
  }

  test("a bad example's own stops include its defect", () => {
    expect(screenStops('bad-no-state').at(-1)).toMatch(/^Defect: /);
  });

  const judge = (stops, reachedEnd) => judgeExampleWalk(stops, reachedEnd, expected, own);
  const sequence = (...list) => {
    let i = 0;
    return { walkOnce: async () => list[i++], made: () => i };
  };
  const right = { stops: screen(...expected), reachedEnd: true };
  const short = { stops: screen(expected[0]), reachedEnd: false };

  for (const [what, walk] of [
    ['a wrong reading', { stops: screen('heading level 3 Shipping button', ...expected.slice(1)), reachedEnd: true }],
    ['a walk that reached the end without the second header', { stops: screen(expected[0], expected[2]), reachedEnd: true }],
    ['a walk with no title', { stops: [own[1], EXAMPLE_HEADING, ...expected], reachedEnd: true }],
    ['a walk with no heading', { stops: [...own, ...expected], reachedEnd: true }],
  ]) {
    test(`${what} followed by a right walk fails, and no second walk is made`, async () => {
      const { walkOnce, made } = sequence(walk, right);
      expect((await runWalks(walkOnce, judge)).verdict).toBe('wrong');
      expect(made()).toBe(1);
    });
  }

  // bad-cupertino-expansion-tile's open walk is made on a fresh load (the
  // VoiceOver spec): that moves where a walk starts, and nothing else. A
  // wrong reading on that walk still fails for good, with no further walk.
  test('the open Cupertino tile: a wrong reading on the walk after a fresh load fails, and no second walk is made', async () => {
    const tileOpen = ['Shipping Orders ship in two days. Expanded double tap to collapse button',
      'Returns Collapsed double tap to expand button', 'Presses: 0'];
    const tileScreen = screenStops('bad-cupertino-expansion-tile');
    const whole = [...tileScreen, EXAMPLE_HEADING, ...tileOpen];
    const webArea = ['CupertinoExpansionTile - Flutter A11Y Techniques web content'];
    const { walkOnce, made } = sequence({ stops: webArea, reachedEnd: true }, { stops: whole, reachedEnd: true });
    const tileJudge = (stops, reachedEnd) => judgeExampleWalk(stops, reachedEnd, tileOpen, tileScreen);
    expect((await runWalks(walkOnce, tileJudge)).verdict).toBe('wrong');
    expect(made()).toBe(1);
  });

  test('a wrong walk after a short one still fails, and no third walk is made', async () => {
    const { walkOnce, made } = sequence(short, { stops: screen(expected[0], expected[2]), reachedEnd: true }, right);
    expect((await runWalks(walkOnce, judge)).verdict).toBe('wrong');
    expect(made()).toBe(2);
  });

  test('an empty walk cut short, followed by a right one, passes on the second', async () => {
    const { walkOnce } = sequence({ stops: [], reachedEnd: false }, right);
    expect(await runWalks(walkOnce, judge)).toMatchObject({ verdict: 'complete', walks: 2 });
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

  for (const [slug, [title, ...rest]] of Object.entries(EXAMPLE_SCREENS)) {
    test(`${slug}: the screen shows the texts the VoiceOver judge expects`, async ({ page }) => {
      await open(page, slug);
      await expect(page.getByRole('heading', { name: title, exact: true, level: 1 })).toHaveCount(1);
      for (const text of rest) await expect(page.getByText(text, { exact: true })).toHaveCount(1);
    });
  }
});
