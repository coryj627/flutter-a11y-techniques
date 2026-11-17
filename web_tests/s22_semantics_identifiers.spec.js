// L3 for S22 Semantics identifiers for testing on web: where the
// identifier is in the page, and that it is not part of what the browser
// exposes to assistive technology.
// Spec: docs/specs/S22-semantics-identifiers.md. Runs against the release
// build in build/web.
import { test, expect } from '@playwright/test';
import { byId, tabTo, technique } from './support/techniques.js';

// On web `Semantics(identifier:)` is the attribute flt-semantics-identifier,
// which byId finds.
const { open, expectCount } = technique('S22', { countLabel: 'Changes' });

/**
 * The identifier is in no attribute that names or describes an element and
 * in no text: the accessibility tree of the page does not contain it.
 */
async function expectIdentifiersNotExposed(page) {
  expect(await page.locator('flt-semantics-host').ariaSnapshot()).not.toContain('s22-');
  await expect(
    page.locator('[aria-label*="s22-"],[aria-description*="s22-"],[title*="s22-"],[id*="s22-"]'),
  ).toHaveCount(0);
}

const buttons = [
  ['good-merged', 's22-good-merged-save', 'Save draft'],
  ['good-cupertino', 's22-good-cupertino-save', 'Save draft'],
  ['good-custom', 's22-good-custom-save', 'Save draft'],
  ['bad-id-as-name', 's22-bad-id-as-name-close', ''],
];

test.describe('buttons found by identifier', () => {
  for (const [slug, id, name] of buttons) {
    test(`${slug}: the element with the identifier is the button, named "${name}"`, async ({ page }) => {
      await open(page, slug);
      const button = byId(page, id);
      await expect(button).toHaveCount(1);
      await expect(button).toHaveRole('button');
      await expect(button).toHaveAccessibleName(name);
      expect(await page.getByRole('button').count()).toBe(2); // Back and this one
      await expectIdentifiersNotExposed(page);
    });

    test(`${slug}: click, Enter, and Space`, async ({ page }) => {
      await open(page, slug);
      const button = byId(page, id);
      await button.click();
      await expectCount(page, slug, 1);
      expect(await tabTo(page, button), 'Tab reaches the button').toBe(true);
      await page.keyboard.press('Enter');
      await expectCount(page, slug, 2);
      await page.keyboard.press('Space');
      await expectCount(page, slug, 3);
      await expect(button).toHaveAccessibleName(name);
    });
  }
});

test('good-field: the identifier is on the element around the input, which keeps its name', async ({ page }) => {
  await open(page, 'good-field');
  await expect(byId(page, 's22-good-field-project')).toHaveCount(1);
  // The engine puts the identifier on the field's flt-semantics element and
  // the name on the <input> inside it.
  const input = byId(page, 's22-good-field-project').locator('input');
  await expect(input).toHaveRole('textbox');
  await expect(input).toHaveAccessibleName('Project name');
  await expectIdentifiersNotExposed(page);
  // A click puts the field in editing mode; typing follows a frame later.
  await input.click();
  await page.waitForTimeout(300);
  await page.keyboard.type('a', { delay: 40 });
  await expectCount(page, 'good-field', 1);
  await expect(input).toHaveValue('a');
});

test.describe('bad examples have their defect', () => {
  test('bad-inside: the identifier is on an element inside the button, not on the button', async ({ page }) => {
    await open(page, 'bad-inside');
    const marked = byId(page, 's22-bad-inside-save');
    await expect(marked).toHaveCount(1);
    // Flutter 3.47.5: the identifier makes the text a node of its own
    // (FL-007). Written to fail if the identifier starts to land on the
    // button.
    await expect(marked).not.toHaveAttribute('role', /.*/);
    await expect(marked).toHaveText('Save draft');
    const button = page.locator('[role="button"]', { has: marked });
    await expect(button).toHaveCount(1);
    await expect(button).not.toHaveAttribute('flt-semantics-identifier', /.*/);
    // On the web the button's name is computed from its content, so it
    // keeps the name here. Android and iOS lose it.
    await expect(button).toHaveAccessibleName('Save draft');
    await button.click();
    await expectCount(page, 'bad-inside', 1);
  });

  test('bad-wrapper: the identifier is on an element around the button, with no role', async ({ page }) => {
    await open(page, 'bad-wrapper');
    const marked = byId(page, 's22-bad-wrapper-save');
    await expect(marked).toHaveCount(1);
    // Flutter 3.47.5: FilledButton is a semantics container, so the
    // identifier stays on a node of its own. Written to fail if it starts
    // to join the button.
    await expect(marked).not.toHaveAttribute('role', /.*/);
    await expect(marked).not.toHaveAttribute('flt-tappable', /.*/);
    const button = marked.locator('[role="button"]');
    await expect(button).toHaveCount(1);
    await expect(button).toHaveAccessibleName('Save draft');
    await expect(button).not.toHaveAttribute('flt-semantics-identifier', /.*/);
    await button.click();
    await expectCount(page, 'bad-wrapper', 1);
  });

  test('bad-id-as-name: the identifier gives the button no name', async ({ page }) => {
    await open(page, 'bad-id-as-name');
    const button = byId(page, 's22-bad-id-as-name-close');
    await expect(button).toHaveRole('button');
    await expect(button).toHaveAccessibleName('');
    await expect(button).toHaveAccessibleDescription('');
    await expect(button).toHaveText('');
  });

  test('bad-duplicate: one identifier finds two buttons', async ({ page }) => {
    await open(page, 'bad-duplicate');
    const marked = byId(page, 's22-bad-duplicate-action');
    await expect(marked).toHaveCount(2);
    await expect(marked.nth(0)).toHaveAccessibleName('Save draft');
    await expect(marked.nth(1)).toHaveAccessibleName('Discard draft');
    // Playwright refuses to act on a locator that matches two elements.
    await expect(marked.click({ timeout: 2000 })).rejects.toThrow(/strict mode violation/);
    await expectCount(page, 'bad-duplicate', 0);
  });
});
