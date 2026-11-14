// The Widgetbook shows each example with its documentation (DOC-2) and
// carries the independence statement (DOC-6).
// Build first: cd widgetbook && flutter build web
// Run: npx playwright test -c widgetbook.config.js
import { test, expect } from '@playwright/test';

async function openUseCase(page, name) {
  await page.goto('about:blank');
  await page.goto('/');
  await page.getByRole('button', { name, exact: true }).click();
}

test('navigation lists every example, labelled good or bad', async ({ page }) => {
  await page.goto('/');
  // The navigation is a lazy list, so only entries near the top are in the
  // tree (FL-011). C01 Button, the first technique, has 6 good and 7 bad.
  await expect(page.getByRole('button', { name: 'Text buttons (good)' })).toBeVisible();
  const c01 = page.getByRole('button', { name: /\((good|bad)\)$/ });
  expect(await c01.count()).toBeGreaterThanOrEqual(13);
});

// One test per link, each in a fresh page.
for (const [path, heading] of [
  ['components/c01-button/text-buttons-(good)', 'Example'],
  ['semantics-and-content/s05-headings/headings-with-levels-(good)', 'Profile'],
  ['forms/f01-text-fields-and-labels/fields-with-a-label-(good)', 'Example'],
]) {
  test(`a use case opens by its link: ${path.split('/')[1]}`, async ({ page }) => {
    await page.goto(`/#/?path=${path}`);
    await expect(page.getByRole('heading', { name: heading }).first()).toBeAttached();
    if (path.startsWith('forms/')) {
      await expect(page.getByRole('textbox', { name: 'Email' })).toBeAttached();
    }
  });
}

test('a good use case shows the live example and the technique doc', async ({ page }) => {
  await openUseCase(page, 'Text buttons (good)');
  await expect(page).toHaveURL(/path=components\/c01-button\//);
  const save = page.locator('[flt-semantics-identifier="c01-good-text-filled"]');
  await expect(save).toHaveRole('button');
  await expect(save).toHaveAccessibleName('Save');
  await save.click();
  await expect(page.locator('[flt-semantics-identifier="c01-good-text-count"]')).toHaveText('Activations: 1');
  await expect(page.getByRole('heading', { name: 'Documentation', level: 2 })).toBeAttached();
  await expect(page.getByRole('heading', { name: 'Flutter limitations', level: 3 })).toBeAttached();
  await expect(page.getByRole('link', { name: 'FL-001' })).toHaveAttribute('href', /flutter-limitations\.md#fl-001$/);
});

test('a SnackBar example shows and announces its message', async ({ page }) => {
  await page.goto('/#/?path=interaction-and-input/i12-announcements-and-live-regions/snackbar-(good)');
  const action = page.locator('[flt-semantics-identifier="i12-good-snackbar-action"]');
  await action.waitFor();
  await page.waitForTimeout(900);
  await page.evaluate(() => {
    window.announced = [];
    const element = document.querySelector('flt-announcement-polite');
    new MutationObserver(() => {
      const text = element.textContent.replace(/\u00a0/g, ' ').trim();
      if (text) window.announced.push(text);
    }).observe(element, { childList: true, characterData: true, subtree: true });
  });
  await action.click();
  // The message is on screen in the SnackBar (and, briefly, in the announcer).
  await expect(page.locator('flt-semantics', { hasText: 'Message archived' }).last()).toBeVisible();
  await expect.poll(() => page.evaluate(() => window.announced)).toContain('Message archived');
});

test('a bad use case states its defect in text', async ({ page }) => {
  await openUseCase(page, 'Icon button with no name (bad)');
  await expect(page.getByText('Defect: The icon button has no accessible name.')).toBeAttached();
  await expect(page.locator('[flt-semantics-identifier="c01-bad-unlabelled-icon-close"]')).toHaveAccessibleName('');
});

test('the independence statement is in the Widgetbook', async ({ page }) => {
  // Opened by its link: the navigation is a lazy list, so entries below the
  // fold are not in the tree to click (docs/flutter-limitations.md, FL-011).
  await page.goto('about:blank');
  await page.goto('/#/?path=about/about-this-project/independence-and-references');
  await expect(page.getByText(/no material connection to CVS Health/)).toBeAttached();
});
