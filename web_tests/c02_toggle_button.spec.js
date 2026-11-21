// L3 for C02 Toggle button on web: what the browser's accessibility tree
// exposes. Spec: docs/specs/C02-toggle-button.md. Runs against the release
// build in build/web.
import { test, expect } from '@playwright/test';
import { byId, tabTo, technique } from './support/techniques.js';

const { open, expectCount } = technique('C02', { countLabel: 'Changes' });

// slug, identifier, name, role. Each starts off. Flutter 3.47.5 writes no
// aria-pressed for any node (docs/flutter-limitations.md, FL-200): a
// toggled node is a switch and a checked one a checkbox, with
// aria-checked.
const toggles = [
  ['good-icon-button', 'c02-good-icon-button-bold', 'Bold', 'switch'],
  ['good-toggle-buttons', 'c02-good-toggle-buttons-bold', 'Bold', 'checkbox'],
  ['good-toggle-buttons', 'c02-good-toggle-buttons-italic', 'Italic', 'checkbox'],
  ['good-toggle-buttons', 'c02-good-toggle-buttons-underline', 'Underline', 'checkbox'],
  ['good-cupertino', 'c02-good-cupertino-mute', 'Mute', 'switch'],
  ['good-custom', 'c02-good-custom-mute', 'Mute', 'switch'],
];

/** Expects `control` to have no state attribute but `aria-checked`. */
async function expectOnlyChecked(control) {
  // Written to fail when Flutter starts to write aria-pressed (FL-200).
  await expect(control).not.toHaveAttribute('aria-pressed', /.*/);
  await expect(control).not.toHaveAttribute('aria-current', /.*/);
  await expect(control).not.toHaveAttribute('aria-selected', /.*/);
}

test.describe('toggles', () => {
  for (const [slug, id, name, role] of toggles) {
    test(`${id}: a ${role} named "${name}", off`, async ({ page }) => {
      await open(page, slug);
      const control = byId(page, id);
      await expect(control).toHaveRole(role);
      await expect(control).toHaveAccessibleName(name);
      await expect(control).toHaveAttribute('aria-checked', 'false');
      await expect(control).toBeEnabled();
      await expectOnlyChecked(control);
      // One element carries the name.
      await expect(page.getByRole(role, { name, exact: true })).toHaveCount(1);
      await expect(page.getByRole('button', { name, exact: true })).toHaveCount(0);
    });

    test(`${id}: a click, Space, and Enter each change the state, and the name stays`, async ({ page }) => {
      await open(page, slug);
      const control = byId(page, id);
      await control.click();
      await expect(control).toHaveAttribute('aria-checked', 'true');
      await expectCount(page, slug, 1);
      await expect(control).toHaveAccessibleName(name);
      await expectOnlyChecked(control);
      expect(await tabTo(page, control, 10), 'Tab reaches the control').toBe(true);
      await page.keyboard.press('Space');
      await expect(control).toHaveAttribute('aria-checked', 'false');
      await expectCount(page, slug, 2);
      await page.keyboard.press('Enter');
      await expect(control).toHaveAttribute('aria-checked', 'true');
      await expectCount(page, slug, 3);
      await expect(control).toHaveAccessibleName(name);
    });
  }

  test('good-toggle-buttons: each button changes only itself', async ({ page }) => {
    await open(page, 'good-toggle-buttons');
    await byId(page, 'c02-good-toggle-buttons-italic').click();
    await expect(byId(page, 'c02-good-toggle-buttons-italic')).toHaveAttribute('aria-checked', 'true');
    await expect(byId(page, 'c02-good-toggle-buttons-bold')).toHaveAttribute('aria-checked', 'false');
    await expect(byId(page, 'c02-good-toggle-buttons-underline')).toHaveAttribute('aria-checked', 'false');
    await expectCount(page, 'good-toggle-buttons', 1);
  });
});

test.describe('bad examples have their defect', () => {
  test('bad-selected-only: a button whose state is aria-current, said only when it is on', async ({ page }) => {
    await open(page, 'bad-selected-only');
    const control = byId(page, 'c02-bad-selected-only-bold');
    await expect(page.getByRole('switch')).toHaveCount(0);
    await expect(page.getByRole('checkbox')).toHaveCount(0);
    for (const [clicks, current] of [[0, 'false'], [1, 'true'], [2, 'false']]) {
      await expect(control).toHaveRole('button');
      await expect(control).toHaveAccessibleName('Bold');
      // aria-current is a different state from pressed: this is the web's
      // 4.1.2 failure (FL-201). Written to fail when Flutter writes a
      // pressed or checked state here.
      await expect(control).toHaveAttribute('aria-current', current);
      await expect(control).not.toHaveAttribute('aria-pressed', /.*/);
      await expect(control).not.toHaveAttribute('aria-checked', /.*/);
      await expectCount(page, 'bad-selected-only', clicks);
      if (clicks === 0) await control.click();
      if (clicks === 1) {
        expect(await tabTo(page, control, 10), 'Tab reaches the button').toBe(true);
        await page.keyboard.press('Space');
      }
    }
  });

  test('bad-no-state: a button with no state, before and after it is used', async ({ page }) => {
    await open(page, 'bad-no-state');
    const control = byId(page, 'c02-bad-no-state-mute');
    await expect(page.getByRole('switch')).toHaveCount(0);
    for (let clicks = 0; clicks < 3; clicks++) {
      await expectCount(page, 'bad-no-state', clicks);
      await expect(control).toHaveRole('button');
      await expect(control).toHaveAccessibleName('Mute');
      for (const state of ['aria-pressed', 'aria-checked', 'aria-current', 'aria-selected']) {
        await expect(control).not.toHaveAttribute(state, /.*/);
      }
      if (clicks < 2) await control.click();
    }
  });

  test('bad-label-changes: the name changes with the state', async ({ page }) => {
    await open(page, 'bad-label-changes');
    const control = byId(page, 'c02-bad-label-changes-mute');
    await expect(control).toHaveRole('switch');
    await expect(control).toHaveAccessibleName('Mute');
    await expect(control).toHaveAttribute('aria-checked', 'false');
    await control.click();
    await expect(control).toHaveAttribute('aria-checked', 'true');
    await expect(control).toHaveAccessibleName('Unmute');
    // The control can no longer be found by the name it had.
    await expect(page.getByRole('switch', { name: 'Mute', exact: true })).toHaveCount(0);
    await expectCount(page, 'bad-label-changes', 1);
  });
});
