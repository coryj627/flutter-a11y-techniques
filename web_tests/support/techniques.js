// What every technique's L3 tree spec on web shares: finding an element by
// its test identifier, opening an example, reading its count, and tabbing.
// Not a spec itself: Playwright runs only files named *.spec.js.
import { expect } from '@playwright/test';

/** The element carrying the test identifier `id` (`Semantics(identifier:)`). */
export const byId = (page, id) => page.locator(`[flt-semantics-identifier="${id}"]`);

/** The "Example" heading that every example screen has. */
export const exampleHeading = (page) => page.getByRole('heading', { name: 'Example', level: 2 });

/**
 * Loads the example `slug` of `technique` from about:blank, so that every
 * test gets a fresh page, and waits for `ready`, a locator for something
 * on that example's screen; then for `settle` milliseconds more.
 */
export async function openExample(page, technique, slug, ready, { settle = 0 } = {}) {
  await page.goto('about:blank');
  await page.goto(`/#/t/${technique}/${slug}`);
  await ready.waitFor();
  if (settle) await page.waitForTimeout(settle);
}

/**
 * The helpers for one technique, `id` as in the app's routes ("C01"):
 *
 * - `open(page, slug)` opens an example and waits for `ready(page, slug)`,
 *   by default the example's count, then for `settle` milliseconds.
 * - `count(page, slug)` is the example's count, identified
 *   `<id>-<slug>-count`.
 * - `expectCount(page, slug, n)` expects it to read "<countLabel>: <n>";
 *   `countLabel` is "Activations" or "Changes".
 */
export function technique(id, { countLabel, ready, settle = 0 } = {}) {
  const count = (page, slug) => byId(page, `${id.toLowerCase()}-${slug}-count`);
  return {
    count,
    open: (page, slug) => openExample(page, id, slug, (ready ?? count)(page, slug), { settle }),
    expectCount: (page, slug, n) => {
      if (!countLabel) throw new Error(`technique ${id} was given no countLabel`);
      return expect(count(page, slug)).toHaveText(`${countLabel}: ${n}`);
    },
  };
}

/** Press Tab until `locator` has focus. Returns false if it never does. */
export async function tabTo(page, locator, max = 8) {
  for (let i = 0; i < max; i++) {
    await page.keyboard.press('Tab');
    // Flutter moves DOM focus on the next frame.
    await page.waitForTimeout(100);
    if (await locator.evaluate((e) => e === document.activeElement)) return true;
  }
  return false;
}
