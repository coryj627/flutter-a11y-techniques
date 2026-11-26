// L3 for S06 Screen and page titles on web: the document title the browser
// is given when each example's screen opens and when it closes, the
// screen's heading, what the semantics tree says of the route, and what
// the keys do. Spec: docs/specs/S06-screen-titles.md. Runs against the
// release build in build/web.
import { test, expect } from '@playwright/test';
import { byId, tabTo, technique } from './support/techniques.js';
import { EXAMPLE_HEADING, EXAMPLE_SCREENS, judgeExampleWalk, screenStops } from './vo/s06_vo_walks.js';

const exampleHeading = (page) => page.getByRole('heading', { name: 'Example', exact: true, level: 2 });
const { open } = technique('S06', { ready: exampleHeading, settle: 600 });

const APP = 'Flutter A11Y Techniques';
const TEXT = 'Three orders in the last 30 days.';

// slug -> the example screen's own title, which the app's PageScaffold
// gives the document ("<title> - Flutter A11Y Techniques").
const TITLES = {
  'good-material': 'Material screen title',
  'good-cupertino': 'Cupertino screen title',
  'bad-no-title': 'Screen with no title',
  'bad-vague-title': 'Screen titled Details',
  'bad-no-document-title': 'Screen with no document title',
  'bad-cupertino-unnamed': 'Cupertino bar that names no screen',
};
const SLUGS = Object.keys(TITLES);
const exampleTitle = (slug) => `${TITLES[slug]} - ${APP}`;

// slug -> the opened screen: the document title once it is open, and its
// level 1 heading (null: none).
const OPENED = {
  'good-material': { title: 'Orders', heading: 'Orders' },
  'good-cupertino': { title: 'Orders', heading: 'Orders' },
  // No Title and no app bar title: the document keeps the example
  // screen's title, and the large text is no heading.
  'bad-no-title': { title: null, heading: null },
  'bad-vague-title': { title: 'Details', heading: 'Details' },
  // No Title: the document keeps the example screen's title.
  'bad-no-document-title': { title: null, heading: 'Orders' },
  'bad-cupertino-unnamed': { title: 'Orders', heading: 'Orders' },
};
const openedTitle = (slug) => OPENED[slug].title ?? exampleTitle(slug);

const screenText = (page) => page.getByText(TEXT, { exact: true });

/** The name of Chromium's root web area, which is the document's title. */
async function rootName(page) {
  const cdp = await page.context().newCDPSession(page);
  const { nodes } = await cdp.send('Accessibility.getFullAXTree');
  await cdp.detach();
  return nodes.find((n) => n.role?.value === 'RootWebArea')?.name?.value;
}

/** Opens the example's screen with a click on its button. */
async function clickOpen(page, slug) {
  await byId(page, `s06-${slug}-open`).click();
  await expect(screenText(page)).toBeVisible();
  await page.waitForTimeout(300);
}

/** The app's Back button: the first element named Back (Cupertino's has a second inside it, FL-303). */
const backButton = (page) => page.getByRole('button', { name: 'Back', exact: true }).first();

test.describe('the document title', () => {
  for (const slug of SLUGS) {
    test(`${slug}: the example screen's title, then the opened screen's, which stays after Back (FL-300)`, async ({ page }) => {
      await open(page, slug);
      await expect(page).toHaveTitle(exampleTitle(slug));
      await clickOpen(page, slug);
      await expect(page).toHaveTitle(openedTitle(slug));
      expect(await rootName(page)).toBe(openedTitle(slug));
      await page.mouse.move(0, 0);
      await backButton(page).click();
      await expect(exampleHeading(page)).toBeVisible();
      await expect(screenText(page)).toHaveCount(0);
      await page.waitForTimeout(500);
      // Written to fail when Flutter gives the screen shown its title back:
      // the closed screen's title stays.
      await expect(page).toHaveTitle(openedTitle(slug));
      expect(await rootName(page)).toBe(openedTitle(slug));
    });
  }

  test('good-material: the browser\'s own Back closes the screen, and the title stays the closed screen\'s (FL-300)', async ({ page }) => {
    await open(page, 'good-material');
    await clickOpen(page, 'good-material');
    await page.goBack();
    await expect(exampleHeading(page)).toBeVisible();
    await expect(screenText(page)).toHaveCount(0);
    await page.waitForTimeout(500);
    await expect(page).toHaveTitle('Orders');
  });

  test('positive control: the example screen opened by its address has its own title, which Back would have to restore', async ({ page }) => {
    await open(page, 'good-material');
    await expect(page).toHaveTitle(exampleTitle('good-material'));
    expect(await rootName(page)).toBe(exampleTitle('good-material'));
  });
});

test.describe('the opened screen', () => {
  for (const slug of SLUGS) {
    test(`${slug}: its headings`, async ({ page }) => {
      await open(page, slug);
      await clickOpen(page, slug);
      const { heading } = OPENED[slug];
      // Only the opened screen is in the tree: the example screen under it
      // is hidden from assistive technology while it is covered.
      await expect(page.getByRole('heading', { name: 'Example', exact: true })).toHaveCount(0);
      if (heading) {
        await expect(page.getByRole('heading', { level: 1 })).toHaveCount(1);
        await expect(page.getByRole('heading', { level: 1 })).toHaveAccessibleName(heading);
        await expect(page.getByRole('heading')).toHaveCount(1);
      } else {
        await expect(page.getByRole('heading')).toHaveCount(0);
        // The large text is there, as plain text.
        await expect(page.getByText('Orders', { exact: true })).toBeVisible();
      }
    });
  }
});

// What the route's element says, by the platform the browser reports:
// Flutter's web engine reads navigator.platform, and AppBar names its route
// on Linux and Windows but not on macOS (material/app_bar.dart, read in the
// source; the probe's p01, with navigator.platform as it is on a Mac and
// set to "Linux x86_64", in docs/evidence/probes/s06/web.txt). CI's
// browser runs on Linux, a local one here on a Mac, so each case sets the
// value before the page loads: an override, not a browser on that system.
const PLATFORMS = { mac: 'MacIntel', linux: 'Linux x86_64' };

/** The route elements: each element with aria-describedby, and the text of what it points to. */
async function routeElements(page) {
  return page.evaluate(() => [...document.querySelectorAll('flt-semantics[aria-describedby]')].map((e) => {
    const target = document.getElementById(e.getAttribute('aria-describedby'));
    return {
      role: e.getAttribute('role'),
      label: e.getAttribute('aria-label'),
      describedBy: target ? (target.getAttribute('aria-label') || target.textContent) : null,
    };
  }));
}

/** Chromium's nodes with a description: role, name, and description. */
async function describedNodes(page) {
  const cdp = await page.context().newCDPSession(page);
  const { nodes } = await cdp.send('Accessibility.getFullAXTree');
  await cdp.detach();
  return nodes.filter((n) => !n.ignored && n.description?.value)
    .map((n) => ({ role: n.role?.value, name: n.name?.value ?? '', description: n.description.value }));
}

// slug -> platform -> what the route is described by (null: no element).
const ROUTE_NAMES = {
  'good-material': { mac: null, linux: 'Orders' },
  'good-cupertino': { mac: 'Orders', linux: 'Orders' },
  'bad-cupertino-unnamed': { mac: null, linux: null },
};

test.describe('the route in the semantics tree', () => {
  for (const [slug, byPlatform] of Object.entries(ROUTE_NAMES)) {
    for (const [platform, name] of Object.entries(byPlatform)) {
      test(`${slug} as ${platform}: ${name ? `a generic element described by "${name}", with no role` : 'no element describes the route'}`, async ({ page }) => {
        await page.addInitScript((value) => {
          Object.defineProperty(Navigator.prototype, 'platform', { get: () => value });
        }, PLATFORMS[platform]);
        await open(page, slug);
        expect(await page.evaluate(() => navigator.platform)).toBe(PLATFORMS[platform]);
        await clickOpen(page, slug);
        const routes = await routeElements(page);
        const described = await describedNodes(page);
        if (name) {
          expect(routes).toEqual([{ role: null, label: null, describedBy: name }]);
          // Written to fail when Flutter gives a route a role (a landmark
          // or region, as 3.50 is said to): today it is a generic element
          // with no name, and only a description.
          expect(described).toEqual([{ role: 'generic', name: '', description: name }]);
        } else {
          expect(routes).toEqual([]);
          expect(described).toEqual([]);
        }
        // No route is a dialog or a region, on any platform.
        await expect(page.locator('flt-semantics[role="dialog"], flt-semantics[role="region"]')).toHaveCount(0);
      });
    }
  }
});

/** The element with keyboard focus: its aria-label, or its text. */
const focusedName = (page) => page.evaluate(() => document.activeElement?.getAttribute('aria-label')
  || document.activeElement?.textContent);

test.describe('keyboard', () => {
  for (const slug of SLUGS) {
    for (const key of ['Enter', 'Space']) {
      test(`${slug}: Tab reaches the button, and ${key} opens the screen and moves focus to its Back button`, async ({ page }) => {
        await open(page, slug);
        await page.mouse.move(0, 0);
        expect(await tabTo(page, byId(page, `s06-${slug}-open`))).toBe(true);
        await expect(screenText(page)).toHaveCount(0);
        await page.keyboard.press(key);
        await expect(screenText(page)).toBeVisible();
        await expect(page).toHaveTitle(openedTitle(slug));
        // The web engine puts keyboard focus on the new route's first
        // control (the probe: Back on every fixture with one).
        await expect.poll(() => focusedName(page), { timeout: 3000 }).toBe('Back');
      });
    }
  }

  test('good-material: Tab and Enter on Back close the screen, focus goes back to the button, and the title stays (FL-300)', async ({ page }) => {
    await open(page, 'good-material');
    await page.mouse.move(0, 0);
    expect(await tabTo(page, byId(page, 's06-good-material-open'))).toBe(true);
    await page.keyboard.press('Enter');
    await expect(screenText(page)).toBeVisible();
    await expect.poll(() => focusedName(page), { timeout: 3000 }).toBe('Back');
    // Enter at once, with DOM focus on Back, closed nothing in the probe;
    // after a Tab, which leaves DOM focus on Back, Enter closed the screen
    // (docs/evidence/probes/s06/web_back.txt). Focus on a new screen is
    // I03's subject; here Tab comes first.
    await page.keyboard.press('Tab');
    await expect.poll(() => focusedName(page), { timeout: 3000 }).toBe('Back');
    await page.keyboard.press('Enter');
    await expect(exampleHeading(page)).toBeVisible();
    await expect(screenText(page)).toHaveCount(0);
    await expect.poll(() => page.evaluate(() => document.activeElement?.getAttribute('flt-semantics-identifier')), { timeout: 3000 })
      .toBe('s06-good-material-open');
    await expect(page).toHaveTitle('Orders');
  });
});

test.describe('the VoiceOver walk judge (web_tests/vo/s06_vo_walks.js)', () => {
  test('each example screen shows the stops the VoiceOver spec expects above its heading', async ({ page }) => {
    for (const slug of SLUGS) {
      await open(page, slug);
      for (const line of EXAMPLE_SCREENS[slug]) {
        await expect(page.getByText(line, { exact: true }).first()).toBeVisible();
      }
    }
  });

  const screen = screenStops('good-material');
  const expected = ['Open orders button'];
  test('a whole walk is complete', () => {
    expect(judgeExampleWalk([...screen, EXAMPLE_HEADING, ...expected], true, expected, screen).verdict).toBe('complete');
  });
  test('a wrong stop is wrong', () => {
    expect(judgeExampleWalk([...screen, EXAMPLE_HEADING, 'Open orders'], true, expected, screen).verdict).toBe('wrong');
  });
  test('a walk that reached the end with a stop missing is wrong', () => {
    expect(judgeExampleWalk([...screen, EXAMPLE_HEADING], true, expected, screen).verdict).toBe('wrong');
  });
  test('a walk cut short with every stop right is incomplete', () => {
    expect(judgeExampleWalk([...screen], false, expected, screen).verdict).toBe('incomplete');
  });
  test('a stop after the last is wrong', () => {
    expect(judgeExampleWalk([...screen, EXAMPLE_HEADING, ...expected, 'Back button'], true, expected, screen).verdict).toBe('wrong');
  });
});
