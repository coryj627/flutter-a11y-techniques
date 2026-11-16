// L3 for F07 Checkbox on web: what the browser's accessibility tree
// exposes. Spec: docs/specs/F07-checkbox.md. Runs against the release build
// in build/web.
import { test, expect } from '@playwright/test';
import { byId, tabTo, technique } from './support/techniques.js';

const { open, expectCount } = technique('F07', { countLabel: 'Changes' });

const updates = 'Email me product updates';

// slug, identifier, name. Each starts not checked.
const boxes = [
  ['good-tile', 'f07-good-tile-updates', updates],
  ['good-cupertino', 'f07-good-cupertino-updates', updates],
  ['good-custom', 'f07-good-custom-updates', updates],
  ['good-group', 'f07-good-group-phone', 'Phone'],
  ['good-group', 'f07-good-group-post', 'Post'],
  ['bad-group-unlabelled', 'f07-bad-group-unlabelled-phone', 'Phone'],
];

test.describe('checkboxes', () => {
  for (const [slug, id, name] of boxes) {
    test(`${id}: a checkbox named "${name}", not checked`, async ({ page }) => {
      await open(page, slug);
      const box = byId(page, id);
      await expect(box).toHaveRole('checkbox');
      await expect(box).toHaveAccessibleName(name);
      await expect(box).not.toBeChecked();
      await expect(box).toHaveAttribute('aria-checked', 'false');
      await expect(box).toBeEnabled();
      // One element carries the name: the label is not a second element.
      await expect(page.getByRole('checkbox', { name, exact: true })).toHaveCount(1);
      await expect(page.locator('flt-semantics-host').getByText(name, { exact: true })).toHaveCount(0);
    });

    test(`${id}: a click and Space each change the state`, async ({ page }) => {
      await open(page, slug);
      const box = byId(page, id);
      await box.click();
      await expect(box).toBeChecked();
      await expectCount(page, slug, 1);
      expect(await tabTo(page, box, 10), 'Tab reaches the checkbox').toBe(true);
      await page.keyboard.press('Space');
      await expect(box).not.toBeChecked();
      await expectCount(page, slug, 2);
      await expect(box).toHaveAccessibleName(name);
    });
  }
});

test.describe('good-mixed', () => {
  test('"Select all" follows the two boxes and sets both', async ({ page }) => {
    await open(page, 'good-mixed');
    const all = byId(page, 'f07-good-mixed-all');
    const email = byId(page, 'f07-good-mixed-email');
    const text = byId(page, 'f07-good-mixed-text');
    await expect(all).toHaveRole('checkbox');
    await expect(all).toHaveAccessibleName('Select all');
    await expect(email).toBeChecked();
    await expect(text).not.toBeChecked();
    await text.click();
    await expect(all).toBeChecked();
    await all.click();
    await expect(all).not.toBeChecked();
    await expect(email).not.toBeChecked();
    await expect(text).not.toBeChecked();
    await all.click();
    await expect(email).toBeChecked();
    await expect(text).toBeChecked();
  });

  test('the mixed state is exposed as not checked (FL-044)', async ({ page }) => {
    await open(page, 'good-mixed');
    const all = byId(page, 'f07-good-mixed-all');
    await expect(byId(page, 'f07-good-mixed-email')).toBeChecked();
    await expect(byId(page, 'f07-good-mixed-text')).not.toBeChecked();
    // Flutter 3.47.5: the web engine writes "true" or "false" for a
    // checkbox and never "mixed" (docs/flutter-limitations.md, FL-044).
    // The APG pattern requires aria-checked="mixed" here. Written to fail
    // when Flutter starts to expose it.
    await expect(all).toHaveAttribute('aria-checked', 'false');
    await expect(page.locator('[aria-checked="mixed"]')).toHaveCount(0);
  });
});

test.describe('good-group', () => {
  test('the question names a group that contains both checkboxes', async ({ page }) => {
    await open(page, 'good-group');
    const group = byId(page, 'f07-good-group-contact');
    await expect(group).toHaveRole('group');
    await expect(group).toHaveAccessibleName('Contact me by');
    await expect(group.getByRole('checkbox')).toHaveCount(2);
    await expect(page.getByRole('group', { name: 'Contact me by' }).getByRole('checkbox', { name: 'Phone' })).toHaveCount(1);
    // The visible text is not a second element in the semantics tree.
    await expect(page.locator('flt-semantics-host').getByText('Contact me by', { exact: true })).toHaveCount(0);
  });
});

test.describe('bad examples have their defect', () => {
  test('bad-unlabelled: a checkbox with no name, and text that is not its label', async ({ page }) => {
    await open(page, 'bad-unlabelled');
    const box = page.getByRole('checkbox');
    await expect(box).toHaveCount(1);
    await expect(box).toHaveAccessibleName('');
    const text = page.locator('flt-semantics-host').getByText(updates, { exact: true });
    await expect(text).toHaveCount(1);
    // A click on the text does not change the checkbox.
    // The text's element takes no pointer events, so click at its position.
    const at = await text.boundingBox();
    await page.mouse.click(at.x + at.width / 2, at.y + at.height / 2);
    await page.waitForTimeout(300);
    await expectCount(page, 'bad-unlabelled', 0);
    await expect(box).not.toBeChecked();
    await box.click();
    await expectCount(page, 'bad-unlabelled', 1);
    await expect(box).toBeChecked();
  });

  test('bad-no-state: a button with no state, before and after it is used', async ({ page }) => {
    await open(page, 'bad-no-state');
    const control = byId(page, 'f07-bad-no-state-updates');
    await expect(page.getByRole('checkbox')).toHaveCount(0);
    for (let clicks = 0; clicks < 2; clicks++) {
      await expect(control).toHaveRole('button');
      await expect(control).toHaveAccessibleName(updates);
      await expect(control).not.toHaveAttribute('aria-checked', /.*/);
      await expect(control).not.toHaveAttribute('aria-pressed', /.*/);
      await expect(control).not.toHaveAttribute('aria-selected', /.*/);
      await control.click();
      await expectCount(page, 'bad-no-state', clicks + 1);
    }
  });

  test('bad-mixed-as-unchecked: "Select all" is not checked while one box under it is', async ({ page }) => {
    await open(page, 'bad-mixed-as-unchecked');
    await expect(byId(page, 'f07-bad-mixed-as-unchecked-email')).toBeChecked();
    await expect(byId(page, 'f07-bad-mixed-as-unchecked-text')).not.toBeChecked();
    await expect(byId(page, 'f07-bad-mixed-as-unchecked-all')).toHaveAttribute('aria-checked', 'false');
  });

  test('bad-group-unlabelled: the question is text beside the checkboxes, and no group has a name', async ({ page }) => {
    await open(page, 'bad-group-unlabelled');
    await expect(page.locator('flt-semantics-host').getByText('Contact me by', { exact: true })).toHaveCount(1);
    await expect(page.getByRole('group', { name: 'Contact me by' })).toHaveCount(0);
    await expect(page.locator('[role="group"][aria-label]')).toHaveCount(0);
    await expect(page.getByRole('checkbox')).toHaveCount(2);
  });
});
