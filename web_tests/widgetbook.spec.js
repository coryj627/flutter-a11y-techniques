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
  // C01 Button has 6 good and 7 bad; S05 Headings has 2 good and 6 bad.
  await expect(page.getByRole('button', { name: /\((good|bad)\)$/ })).toHaveCount(21);
  await expect(page.getByRole('button', { name: /\(good\)$/ })).toHaveCount(8);
  await expect(page.getByRole('button', { name: 'Headings with levels (good)' })).toBeVisible();
});

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
