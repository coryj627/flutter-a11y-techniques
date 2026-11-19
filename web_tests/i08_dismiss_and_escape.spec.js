// L3 for I08 Dismiss and escape on web: what Escape does to each example's
// layers, where Tab and Shift+Tab go while they are shown, and what each
// switch is. Keyboard focus is read from document.activeElement after
// every key; every check that a key did nothing presses it alone, reads
// the layers and the stop again a second later, and shows in the same test
// that keys arrive (Space turns the focused switch).
// Spec: docs/specs/I08-dismiss-and-escape.md. Runs against the release
// build in build/web.
import { test, expect } from '@playwright/test';
import { byId, technique } from './support/techniques.js';

const { open, expectCount } = technique('I08', { countLabel: 'Closed' });

const good = ['good-material', 'good-cupertino', 'good-widgets'];
const all = [...good, 'bad-not-dismissible', 'bad-no-escape', 'bad-back-leaves'];
// The examples whose layers are a route of their own.
const routes = ['good-material', 'good-cupertino', 'bad-not-dismissible'];
const escapeCloses = [...good, 'bad-back-leaves'];

const control = (page, slug, part) => byId(page, `i08-${slug}-${part}`);
const layer = (page, slug, part) => control(page, slug, part);

/**
 * Names the element that has DOM focus: 'back', a part of the example
 * ('open', 'contours', 'campsites'), 'outside' when focus is on no element
 * of the page's content (the body, or the Flutter view itself), or a
 * description of anything else.
 */
const stop = (page, slug) => page.evaluate((prefix) => {
  const e = document.activeElement;
  if (!e || e === document.body || e.tagName === 'FLUTTER-VIEW') return 'outside';
  const owner = e.closest('[flt-semantics-identifier]');
  const id = owner?.getAttribute('flt-semantics-identifier');
  if (id && id.startsWith(prefix)) return id.slice(prefix.length);
  if (e.getAttribute('role') === 'button' && e.textContent.trim() === 'Back') return 'back';
  return `other: ${e.tagName} ${e.getAttribute('role') ?? ''} ${e.textContent.trim().slice(0, 30)}`;
}, `i08-${slug}-`);

async function press(page, key) {
  await page.keyboard.press(key);
  // Flutter moves DOM focus on the next frame; a route takes longer.
  await page.waitForTimeout(400);
}

/** Presses `key` `n` times and names the stop after each. */
async function tabs(page, slug, n, key = 'Tab') {
  const stops = [];
  for (let i = 0; i < n; i++) {
    await press(page, key);
    stops.push(await stop(page, slug));
  }
  return stops;
}

/** Both switches are on the page, or both are gone. */
async function expectShown(page, slug, shown) {
  for (const part of ['contours', 'campsites']) {
    await expect(layer(page, slug, part), part).toHaveCount(shown ? 1 : 0);
  }
}

/**
 * Opens the example, tabs to Map layers (Back first) and presses Enter,
 * then Tab until the first switch has focus: a route leaves focus on its
 * own scope, the overlay puts it on the first switch.
 */
async function showByKeyboard(page, slug) {
  await open(page, slug);
  expect(await tabs(page, slug, 2)).toEqual(['back', 'open']);
  await press(page, 'Enter');
  await expectShown(page, slug, true);
  if (routes.includes(slug)) {
    expect(await stop(page, slug)).toBe('outside');
    expect(await tabs(page, slug, 1)).toEqual(['contours']);
  } else {
    expect(await stop(page, slug)).toBe('contours');
  }
}

test.describe('every example', () => {
  for (const slug of all) {
    test(`${slug}: a Map layers button, the count, and two named switches`, async ({ page }) => {
      await open(page, slug);
      await expect(control(page, slug, 'open')).toHaveRole('button');
      await expect(control(page, slug, 'open')).toHaveAccessibleName('Map layers');
      await expectCount(page, slug, 0);
      await expectShown(page, slug, false);
      await control(page, slug, 'open').click();
      for (const [part, name, on] of [['contours', 'Contour lines', 'true'], ['campsites', 'Campsites', 'false']]) {
        const element = layer(page, slug, part);
        await expect(element, part).toHaveRole('switch');
        await expect(element, part).toHaveAccessibleName(name);
        await expect(element, part).toHaveAttribute('aria-checked', on);
      }
    });

    test(`${slug}: Enter shows the layers, and Space turns a layer`, async ({ page }) => {
      await showByKeyboard(page, slug);
      await press(page, 'Space');
      await expect(layer(page, slug, 'contours')).toHaveAttribute('aria-checked', 'false');
    });
  }
});

test.describe('Tab while the layers are shown', () => {
  // The overlay examples keep Tab in their own scope. A sheet or popup
  // route uses the Navigator's default, which on the web lets Tab past the
  // last switch leave the page (DOM focus on nothing of it, for two Tabs
  // here: the browser's own stops), and the Tab after that comes back to
  // the first switch; Shift+Tab the same way backwards. The page behind is
  // never reached.
  for (const slug of all) {
    const inRoute = routes.includes(slug);
    test(`${slug}: Tab and Shift+Tab ${inRoute ? 'go round the switches and out of the page' : 'go round the two switches'}`, async ({ page }) => {
      await showByKeyboard(page, slug);
      const forward = await tabs(page, slug, 4);
      const back = await tabs(page, slug, 4, 'Shift+Tab');
      if (inRoute) {
        expect(forward).toEqual(['campsites', 'outside', 'outside', 'contours']);
        expect(back).toEqual(['outside', 'campsites', 'contours', 'outside']);
      } else {
        expect(forward).toEqual(['campsites', 'contours', 'campsites', 'contours']);
        expect(back).toEqual(['campsites', 'contours', 'campsites', 'contours']);
      }
    });
  }
});

test.describe('Escape (2.1.2)', () => {
  for (const slug of escapeCloses) {
    test(`${slug}: Escape closes the layers, and focus goes back to Map layers`, async ({ page }) => {
      await showByKeyboard(page, slug);
      await press(page, 'Escape');
      await expectShown(page, slug, false);
      await expectCount(page, slug, 1);
      expect(await stop(page, slug)).toBe('open');
    });
  }

  // The good example each bad one is made from, by its title on the
  // technique's screen.
  const goodOf = {
    'bad-not-dismissible': ['good-material', 'A Material bottom sheet that can be dismissed'],
    'bad-no-escape': ['good-widgets', 'Layers drawn in the overlay, closed by every dismiss command'],
  };

  // The defects. Escape alone, from each switch; a second later the layers
  // are still there and focus has not moved; then Space on the stop turns
  // its layer, so keys arrive. Then, on the same page, the positive control
  // for Escape itself: the layers are closed with the mouse, Back goes to
  // the technique's screen, the good example the bad one is made from is
  // opened from there, and the same Escape closes its layers. Written to
  // fail when Escape closes the bad example's layers.
  for (const slug of ['bad-not-dismissible', 'bad-no-escape']) {
    test(`${slug}: Escape does nothing, from either switch`, async ({ page }) => {
      await showByKeyboard(page, slug);
      for (const [part, before] of [['contours', 'true'], ['campsites', 'false']]) {
        if (part === 'campsites') expect(await tabs(page, slug, 1)).toEqual(['campsites']);
        await press(page, 'Escape');
        await page.waitForTimeout(1000);
        await expectShown(page, slug, true);
        expect(await stop(page, slug), `after Escape on ${part}`).toBe(part);
        await press(page, 'Space');
        await expect(layer(page, slug, part)).not.toHaveAttribute('aria-checked', before);
      }
      // Close with the mouse: a drag down the sheet, or a click on the
      // barrier above the layers.
      const size = page.viewportSize();
      if (slug === 'bad-not-dismissible') {
        const box = await layer(page, slug, 'contours').boundingBox();
        await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
        await page.mouse.down();
        await page.mouse.move(box.x + box.width / 2, size.height - 2, { steps: 20 });
        await page.mouse.up();
      } else {
        await page.mouse.click(size.width / 2, 40);
      }
      await expectShown(page, slug, false);
      await page.getByRole('button', { name: 'Back' }).click();
      const [good, title] = goodOf[slug];
      await page.getByRole('button', { name: new RegExp(`^${title}`) }).click();
      await expect(control(page, good, 'count')).toBeVisible();
      await control(page, good, 'open').click();
      await expectShown(page, good, true);
      // Escape from the same stop as in the bad example, Contour lines,
      // once keyboard focus is known to be in the layers: a route's own
      // scope ('outside'), then Tab; the overlay's first switch at once.
      // On CI, Escape pressed straight after the click once did not close
      // good-material's sheet.
      await expect.poll(() => stop(page, good)).toBe(routes.includes(good) ? 'outside' : 'contours');
      if (routes.includes(good)) expect(await tabs(page, good, 1)).toEqual(['contours']);
      await press(page, 'Escape');
      // Closed on the good example's own screen: both switches gone, its
      // count at 1, and DOM focus back on its Map layers.
      await expectShown(page, good, false);
      await expectCount(page, good, 1);
      expect(await stop(page, good)).toBe('open');
    });
  }

  // Tab and Shift+Tab never leave bad-no-escape's layers on the web
  // either; the browser's Back does (below).
  test('bad-no-escape: ten Tabs and ten Shift+Tabs never leave the two switches', async ({ page }) => {
    const slug = 'bad-no-escape';
    await showByKeyboard(page, slug);
    const stops = [...await tabs(page, slug, 10), ...await tabs(page, slug, 10, 'Shift+Tab')];
    expect([...new Set(stops)].sort()).toEqual(['campsites', 'contours']);
  });
});

// The browser's Back. Its keyboard shortcut (Alt+Left, Command+[) could not
// be sent: Playwright's keys go to the page and bypass the browser's own
// shortcuts, and in the I08 probe neither chord went back
// (docs/evidence/probes/i08/web_back.txt). So what is measured is the
// history event the browser's Back makes, through page.goBack(), and not
// the key. Flutter's web engine answers it with popRoute (read in the
// source: SingleEntryBrowserHistory.onPopState), as Android's Back.
test.describe('the browser\'s Back (the history event)', () => {
  for (const slug of [...good, 'bad-not-dismissible', 'bad-no-escape']) {
    for (const part of ['contours', 'campsites']) {
      test(`${slug}: history back from ${part} closes the layers and the screen stays`, async ({ page }) => {
        await showByKeyboard(page, slug);
        if (part === 'campsites') expect(await tabs(page, slug, 1)).toEqual(['campsites']);
        await page.goBack({ waitUntil: 'commit' });
        await expectShown(page, slug, false);
        await expectCount(page, slug, 1);
        expect(await stop(page, slug)).toBe('open');
        expect(page.url()).toMatch(new RegExp(`#/t/I08/${slug}$`));
      });
    }
  }

  // The defect, on the web too: history back with the layers shown leaves
  // the example's screen for the technique's. Written to fail when it
  // closes the layers instead.
  test('bad-back-leaves: history back leaves the screen with the layers shown', async ({ page }) => {
    const slug = 'bad-back-leaves';
    await showByKeyboard(page, slug);
    await page.goBack({ waitUntil: 'commit' });
    await expect(page.getByRole('heading', { name: 'Dismiss and escape', level: 1 })).toBeVisible();
    await expect(control(page, slug, 'count')).toHaveCount(0);
    await expectShown(page, slug, false);
    expect(page.url()).toMatch(/#\/t\/I08$/);
  });
});

