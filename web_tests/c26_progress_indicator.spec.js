// L3 for C26 Progress indicator on web: what the browser's accessibility
// tree exposes for each example's indicator, at rest and while its task
// runs; what Flutter writes to its announcement elements; and where Tab
// goes. Spec: docs/specs/C26-progress-indicator.md. Runs against the
// release build in build/web.
//
// Flutter writes an announcement to `flt-announcement-polite` and empties
// it 300 ms later, so every value it is given is recorded with a
// MutationObserver from before the button is pressed (I12's recorder).
import { test, expect } from '@playwright/test';
import { byId, tabTo, technique } from './support/techniques.js';
import { EXAMPLE_HEADING, EXAMPLE_SCREENS, WALKS, judgeExampleWalk, runWalks, screenStops } from './vo/c26_vo_walks.js';

const status = (page, slug) => byId(page, `c26-${slug}-status`);
const { open } = technique('C26', { ready: status, settle: 900 });

const start = (page, slug) => byId(page, `c26-${slug}-start`);
const BAR = {
  'good-linear': 'c26-good-linear-bar',
  'bad-no-label': 'c26-bad-no-label-bar',
  'bad-silent-end': 'c26-bad-silent-end-bar',
  'bad-cupertino-bar': 'c26-bad-cupertino-bar-bar',
};
const SPINNER = {
  'good-circular': 'c26-good-circular-spinner',
  'good-cupertino': 'c26-good-cupertino-spinner',
  'bad-adaptive': 'c26-bad-adaptive-spinner',
};
const UPLOAD = ['Not started', 'Upload started', 'Half uploaded', 'Upload complete'];
const LOAD = ['Inbox not loaded', 'Loading started', 'Inbox loaded'];

/** Starts recording every value Flutter writes to its announcement elements. */
async function record(page) {
  await page.evaluate(() => {
    window.announced = [];
    for (const politeness of ['polite', 'assertive']) {
      const element = document.querySelector(`flt-announcement-${politeness}`);
      new MutationObserver(() => {
        const text = element.textContent.replace(/ /g, ' ').trim();
        if (text) window.announced.push(`${politeness}: ${text}`);
      }).observe(element, { childList: true, characterData: true, subtree: true });
    }
  });
}

const announced = (page) => page.evaluate(() => window.announced);

/** The element's role, accessible name, and value attributes, as Chromium computes the name. */
async function exposed(page, context, locator) {
  const attrs = await locator.evaluate((e) => ({
    role: e.getAttribute('role'),
    label: e.getAttribute('aria-label'),
    now: e.getAttribute('aria-valuenow'),
    min: e.getAttribute('aria-valuemin'),
    max: e.getAttribute('aria-valuemax'),
    text: e.getAttribute('aria-valuetext'),
    tabindex: e.getAttribute('tabindex'),
  }));
  return attrs;
}

/** Chromium's own accessibility nodes whose role is progressbar, with their names and values. */
async function chromiumProgressBars(page) {
  const cdp = await page.context().newCDPSession(page);
  const { nodes } = await cdp.send('Accessibility.getFullAXTree');
  await cdp.detach();
  return nodes.filter((n) => !n.ignored && n.role?.value === 'progressbar')
    .map((n) => ({ name: n.name?.value ?? '', value: String(n.value?.value ?? '') }));
}

/** Opens `slug`, records announcements, and presses its button with Enter after a Tab to it. */
async function openAndStart(page, slug) {
  await open(page, slug);
  await record(page);
  expect(await tabTo(page, start(page, slug))).toBe(true);
  await page.keyboard.press('Enter');
}

test.describe('good-linear', () => {
  test('the bar is a progress bar named by the words above it, its value the percentage at each step', async ({ page, context }) => {
    await open(page, 'good-linear');
    const bar = byId(page, BAR['good-linear']);
    expect(await exposed(page, context, bar)).toEqual({
      role: 'progressbar', label: 'Report upload 0', now: '0', min: '0', max: '100', text: null, tabindex: null,
    });
    // The value is appended to the name on the web (FL-037).
    await expect(bar).toHaveAccessibleName('Report upload 0');
    expect(await chromiumProgressBars(page)).toEqual([{ name: 'Report upload 0', value: '0' }]);
    // The words above the bar are not a stop of their own.
    await expect(page.getByText('Report upload', { exact: true })).toHaveCount(0);
    await openAndStart(page, 'good-linear');
    const seen = [];
    for (const now of ['25', '50', '75', '100']) {
      await expect(bar).toHaveAttribute('aria-valuenow', now, { timeout: 3000 });
      seen.push(now);
    }
    expect(seen).toEqual(['25', '50', '75', '100']);
    await expect(bar).toHaveAccessibleName('Report upload 100');
  });

  test('the start, the halfway point, and the end are announced politely, once each, and DOM focus stays on the button', async ({ page }) => {
    await openAndStart(page, 'good-linear');
    await expect(status(page, 'good-linear')).toHaveText('Upload complete', { timeout: 8000 });
    await page.waitForTimeout(1000);
    expect(await announced(page)).toEqual(UPLOAD.slice(1).map((t) => `polite: ${t}`));
    expect(await start(page, 'good-linear').evaluate((e) => e === document.activeElement)).toBe(true);
  });
});

for (const slug of ['good-circular', 'good-cupertino']) {
  test.describe(slug, () => {
    test('the spinner is there only while loading, named "Loading inbox", with no role and no value', async ({ page, context }) => {
      await open(page, slug);
      const spinner = byId(page, SPINNER[slug]);
      await expect(spinner).toHaveCount(0);
      await openAndStart(page, slug);
      await expect(spinner).toHaveCount(1, { timeout: 3000 });
      if (slug === 'good-circular') {
        // Material's spinner: a plain element named by aria-label (FL-256).
        expect(await exposed(page, context, spinner)).toEqual({
          role: null, label: 'Loading inbox', now: null, min: null, max: null, text: null, tabindex: null,
        });
        await expect(spinner).toHaveAccessibleName('Loading inbox');
      } else {
        // Semantics(label:) round a CupertinoActivityIndicator: text.
        expect(await exposed(page, context, spinner)).toEqual({
          role: null, label: null, now: null, min: null, max: null, text: null, tabindex: null,
        });
        await expect(spinner).toHaveText('Loading inbox');
      }
      expect(await chromiumProgressBars(page)).toEqual([]);
      await expect(status(page, slug)).toHaveText('Inbox loaded', { timeout: 8000 });
      await expect(spinner).toHaveCount(0);
    });

    test('the start and the end of loading are announced politely, and DOM focus stays on the button', async ({ page }) => {
      await openAndStart(page, slug);
      await expect(status(page, slug)).toHaveText('Inbox loaded', { timeout: 8000 });
      await page.waitForTimeout(1000);
      expect(await announced(page)).toEqual(['polite: Loading started', 'polite: Inbox loaded']);
      expect(await start(page, slug).evaluate((e) => e === document.activeElement)).toBe(true);
    });
  });
}

for (const slug of ['good-linear', 'good-circular', 'good-cupertino']) {
  test(`${slug}: Tab goes Back, the button, and out of the view; never to the indicator, while it runs too`, async ({ page }) => {
    await openAndStart(page, slug);
    await page.waitForTimeout(1200);
    const indicator = byId(page, BAR[slug] ?? SPINNER[slug]);
    await expect(indicator).toHaveCount(1);
    await page.keyboard.press('Shift+Tab');
    await page.waitForTimeout(150);
    const stops = [];
    for (let i = 0; i < 3; i++) {
      await page.keyboard.press('Tab');
      await page.waitForTimeout(150);
      stops.push(await page.evaluate((id) => {
        const a = document.activeElement;
        if (a?.closest(`[flt-semantics-identifier="${id}"]`)) return 'indicator';
        if (a?.closest('[flt-semantics-identifier$="-start"]')) return 'button';
        return a?.textContent?.trim() === 'Back' ? 'Back' : 'other';
      }, BAR[slug] ?? SPINNER[slug]));
    }
    // From Back: the button, then out of Flutter's view (FL-421), then Back.
    expect(stops).not.toContain('indicator');
    expect(stops[0]).toBe('button');
    expect(await indicator.evaluate((e) => e.getAttribute('tabindex'))).toBeNull();
  });
}

test.describe('bad examples have their defect', () => {
  test('bad-no-label: the bar is named by its value alone; good-linear\'s is named', async ({ page, context }) => {
    await open(page, 'bad-no-label');
    const bar = byId(page, BAR['bad-no-label']);
    expect(await exposed(page, context, bar)).toEqual({
      role: 'progressbar', label: '0', now: '0', min: '0', max: '100', text: null, tabindex: null,
    });
    await expect(bar).toHaveAccessibleName('0');
    // The words are text of their own, outside the bar.
    await expect(page.getByText('Report upload', { exact: true })).toHaveCount(1);
    expect(await bar.evaluate((e) => e.textContent.includes('Report upload'))).toBe(false);
    await open(page, 'good-linear');
    await expect(byId(page, BAR['good-linear'])).toHaveAccessibleName('Report upload 0');
  });

  test('bad-silent-end: nothing is announced, while good-linear\'s end is, by the same recorder', async ({ page }) => {
    await openAndStart(page, 'bad-silent-end');
    await expect(status(page, 'bad-silent-end')).toHaveText('Upload complete', { timeout: 8000 });
    await expect(byId(page, BAR['bad-silent-end'])).toHaveAttribute('aria-valuenow', '100');
    await page.waitForTimeout(1000);
    expect(await announced(page)).toEqual([]);
    expect(await page.locator('flt-semantics-host [aria-live]').count()).toBe(0);
    await openAndStart(page, 'good-linear');
    await expect(status(page, 'good-linear')).toHaveText('Upload complete', { timeout: 8000 });
    await page.waitForTimeout(600);
    expect(await announced(page)).toContain('polite: Upload complete');
  });

  test('bad-cupertino-bar: the bar has no role, no name, and no value, at rest and while running', async ({ page, context }) => {
    await open(page, 'bad-cupertino-bar');
    const bar = byId(page, BAR['bad-cupertino-bar']);
    const nothing = { role: null, label: null, now: null, min: null, max: null, text: null, tabindex: null };
    expect(await exposed(page, context, bar)).toEqual(nothing);
    await expect(bar).toHaveText('');
    await openAndStart(page, 'bad-cupertino-bar');
    await expect(status(page, 'bad-cupertino-bar')).toHaveText('Half uploaded', { timeout: 4000 });
    expect(await exposed(page, context, bar)).toEqual(nothing);
    await expect(bar).toHaveText('');
    expect(await chromiumProgressBars(page)).toEqual([]);
  });
});

// bad-adaptive's defect depends on the operating system the page reports:
// Flutter takes the platform from `navigator.platform`, and a Mac's makes
// the theme's platform macOS, where CircularProgressIndicator.adaptive
// draws Cupertino's spinner and drops its label (FL-257). CI runs on
// Linux, so each test sets the platform with Chromium's own override
// before the page loads.
async function asPlatform(page, platform) {
  const cdp = await page.context().newCDPSession(page);
  const userAgent = await page.evaluate(() => navigator.userAgent);
  await cdp.send('Emulation.setUserAgentOverride', { userAgent, platform });
  return cdp;
}

test.describe('bad-adaptive', () => {
  test('in a browser on a Mac the spinner exposes nothing; good-circular in the same page is named', async ({ page, context }) => {
    await page.goto('about:blank');
    await asPlatform(page, 'MacIntel');
    await openAndStart(page, 'bad-adaptive');
    expect(await page.evaluate(() => navigator.platform)).toBe('MacIntel');
    const spinner = byId(page, SPINNER['bad-adaptive']);
    await expect(spinner).toHaveCount(1, { timeout: 3000 });
    expect(await exposed(page, context, spinner)).toEqual({
      role: null, label: null, now: null, min: null, max: null, text: null, tabindex: null,
    });
    await expect(spinner).toHaveText('');
    await expect(page.locator('flt-semantics-host [aria-label="Loading inbox"]')).toHaveCount(0);
    await openAndStart(page, 'good-circular');
    await expect(byId(page, SPINNER['good-circular'])).toHaveAccessibleName('Loading inbox', { timeout: 3000 });
  });

  test('in a browser on Linux the spinner is Material\'s, named', async ({ page }) => {
    await page.goto('about:blank');
    await asPlatform(page, 'Linux x86_64');
    await openAndStart(page, 'bad-adaptive');
    expect(await page.evaluate(() => navigator.platform)).toBe('Linux x86_64');
    await expect(byId(page, SPINNER['bad-adaptive'])).toHaveAccessibleName('Loading inbox', { timeout: 3000 });
  });
});

// The stops the VoiceOver spec expects above each example's "Example"
// heading are on the screen (c26_vo_walks.js), so that a change to a
// title, a description, or a defect is caught here and not first in a
// VoiceOver run.
for (const slug of Object.keys(EXAMPLE_SCREENS)) {
  test(`${slug}: the screen shows the title and the lines the VoiceOver walk expects`, async ({ page }) => {
    await open(page, slug);
    const [title, ...lines] = EXAMPLE_SCREENS[slug];
    await expect(page.getByRole('heading', { name: title, level: 1 })).toBeVisible();
    for (const line of lines) await expect(page.getByText(line, { exact: true })).toBeVisible();
  });
}

// The judge of the VoiceOver walks, on made-up walks.
test.describe('the VoiceOver walk judge', () => {
  const expected = WALKS['good-linear'].chromium;
  const screen = screenStops('good-linear');
  const whole = [...screen, EXAMPLE_HEADING, ...expected];

  test('a walk of the whole screen, every stop in its place, is complete', () => {
    expect(judgeExampleWalk(whole, true, expected, screen).verdict).toBe('complete');
  });
  test('a wrong stop is wrong, wherever it is', () => {
    const wrong = [...whole];
    wrong[whole.length - 2] = 'Report upload 0 progress indicator';
    expect(judgeExampleWalk(wrong, true, expected, screen).verdict).toBe('wrong');
    expect(judgeExampleWalk(wrong.slice(0, -1), false, expected, screen).verdict).toBe('wrong');
  });
  test('a walk that reached the end with a stop missing is wrong', () => {
    expect(judgeExampleWalk(whole.slice(0, -1), true, expected, screen).verdict).toBe('wrong');
  });
  test('a stop after the last expected one is wrong', () => {
    expect(judgeExampleWalk([...whole, 'more'], true, expected, screen).verdict).toBe('wrong');
  });
  test('a walk cut short with every stop right so far is incomplete', () => {
    expect(judgeExampleWalk(whole.slice(0, 4), false, expected, screen).verdict).toBe('incomplete');
    expect(judgeExampleWalk(whole, false, expected, screen).verdict).toBe('incomplete');
  });
  test('an empty walk that reached the end is wrong, and one cut short is incomplete', () => {
    expect(judgeExampleWalk([], true, expected, screen).verdict).toBe('wrong');
    expect(judgeExampleWalk([], false, expected, screen).verdict).toBe('incomplete');
  });
  test('runWalks walks again only after an incomplete walk, and stops at a wrong one', async () => {
    const walks = [{ stops: whole.slice(0, 3), reachedEnd: false }, { stops: ['x'], reachedEnd: true }, { stops: whole, reachedEnd: true }];
    let i = 0;
    const logged = [];
    const result = await runWalks(async () => walks[i++],
      (stops, reachedEnd) => judgeExampleWalk(stops, reachedEnd, expected, screen),
      { log: (walk, stops, judged) => logged.push(`${walk} ${judged.verdict}`) });
    expect(result.verdict).toBe('wrong');
    expect(result.walks).toBe(2);
    expect(logged).toEqual(['1 incomplete', '2 wrong']);
  });

  // Regression, from the first recording
  // (docs/evidence/probes/c26/voiceover-web-round1-fail.md.txt): a bar was
  // read "Report upload 0 0% progress indicator", the same in Chromium and
  // WebKit, where the first lists expected "Report upload 0 progress
  // indicator". The lists now hold what was read; a walk that reads the bar
  // with its value once, as first predicted, must be wrong, and the
  // recorded walks must be complete.
  test('the first recording\'s bar walks are complete against the lists, in both browsers', () => {
    const recorded = {
      'good-linear': ['Upload report button', 'Report upload 0 0% progress indicator', 'Not started'],
      'bad-silent-end': ['Upload report button', 'Report upload 0 0% progress indicator', 'Not started'],
      'bad-no-label': ['Upload report button', 'Report upload', '0 0% progress indicator', 'Not started'],
    };
    for (const [slug, stops] of Object.entries(recorded)) {
      for (const browser of ['chromium', 'webkit']) {
        const screenOf = screenStops(slug);
        const walk = [...screenOf, EXAMPLE_HEADING, ...stops];
        expect(judgeExampleWalk(walk, true, WALKS[slug][browser], screenOf).verdict, `${slug} ${browser}`).toBe('complete');
      }
    }
  });
  test('a bar read with its value once, as first predicted, is wrong', () => {
    const screenOf = screenStops('bad-no-label');
    const predicted = [...screenOf, EXAMPLE_HEADING, 'Upload report button', 'Report upload', '0 progress indicator', 'Not started'];
    expect(judgeExampleWalk(predicted, true, WALKS['bad-no-label'].chromium, screenOf).verdict).toBe('wrong');
    const linear = [...screen, EXAMPLE_HEADING, 'Upload report button', 'Report upload 0 progress indicator', 'Not started'];
    expect(judgeExampleWalk(linear, true, expected, screen).verdict).toBe('wrong');
  });
});
