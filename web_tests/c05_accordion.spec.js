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
import { EXAMPLE_HEADING, EXAMPLE_SCREENS, judgeWalk, runWalks, screenStops } from './vo/c05_vo_walks.js';

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
    expect(await shown(page, SHIPPING_TEXT)).toBe(false);
    await header.click();
    await expect.poll(() => shown(page, SHIPPING_TEXT)).toBe(true);
  });
});

// The VoiceOver spec's judge (web_tests/vo/c05_vo_walks.js), tested here on
// made-up walks so that CI runs it: a wrong reading fails at once, a walk
// that fell short may be tried again, and only a whole walk passes.
test.describe('the VoiceOver walk judge', () => {
  const screen = screenStops('good-custom');
  const lead = ['heading level 1 Accordion built from Semantics', 'Good example for Accordion. Widgets layer.', EXAMPLE_HEADING];
  const expected = ['A', 'B', 'Presses: 0'];

  test('a whole walk is complete; WebKit\'s empty title is accepted', () => {
    expect(judgeWalk([...lead, ...expected], true, expected, screen).verdict).toBe('complete');
    expect(judgeWalk(['', ...lead.slice(1), ...expected], true, expected, screen).verdict).toBe('complete');
  });

  test('a stop that is not the next expected one is wrong, before or after the heading', () => {
    expect(judgeWalk([...lead, 'A', 'X', 'Presses: 0'], true, expected, screen).verdict).toBe('wrong');
    expect(judgeWalk([...lead, 'A', 'B', 'Presses: 0', 'Extra'], true, expected, screen).verdict).toBe('wrong');
    expect(judgeWalk(['Stray', ...lead, ...expected], true, expected, screen).verdict).toBe('wrong');
    expect(judgeWalk([...lead, 'A', 'B'], true, expected, screen).verdict).toBe('wrong');
    expect(judgeWalk(['', '', ''], true, expected, screen).verdict).toBe('wrong');
  });

  test('a walk that fell short with nothing wrong may be tried again', () => {
    expect(judgeWalk([], false, expected, screen).verdict).toBe('incomplete');
    expect(judgeWalk(lead.slice(0, 1), false, expected, screen).verdict).toBe('incomplete');
    expect(judgeWalk([...lead, 'A'], false, expected, screen).verdict).toBe('incomplete');
  });

  test('runWalks tries again only after a walk that fell short, and logs every try', async () => {
    const walks = [{ stops: [], reachedEnd: false }, { stops: [...lead, 'A', 'X'], reachedEnd: true }, { stops: [...lead, ...expected], reachedEnd: true }];
    const logged = [];
    const result = await runWalks(async () => walks.shift(), (s, e) => judgeWalk(s, e, expected, screen), { log: (n, s, j) => logged.push(`${n} ${j.verdict}`) });
    expect(result.verdict).toBe('wrong');
    expect(logged).toEqual(['1 incomplete', '2 wrong']);
  });

  for (const [slug, [title, ...rest]] of Object.entries(EXAMPLE_SCREENS)) {
    test(`${slug}: the screen shows the texts the VoiceOver judge expects`, async ({ page }) => {
      await open(page, slug);
      await expect(page.getByRole('heading', { name: title, exact: true, level: 1 })).toHaveCount(1);
      for (const text of rest) await expect(page.getByText(text, { exact: true })).toHaveCount(1);
    });
  }
});
