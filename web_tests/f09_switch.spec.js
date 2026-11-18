// L3 for F09 Switch on web: what the browser's accessibility tree exposes.
// Spec: docs/specs/F09-switch.md. Runs against the release build in
// build/web.
import { test, expect } from '@playwright/test';
import { byId, tabTo, technique } from './support/techniques.js';

const { open, expectCount } = technique('F09', { countLabel: 'Changes' });

const bluetooth = 'Bluetooth';

// slug, identifier, name, whether Enter toggles it. Each starts off.
const switches = [
  ['good-tile', 'f09-good-tile-bluetooth', bluetooth, true],
  // Flutter 3.47.5: on web Enter is ButtonActivateIntent, which
  // CupertinoSwitch does not handle (docs/flutter-limitations.md, FL-002).
  // The APG Switch pattern makes Enter optional and requires Space.
  ['good-cupertino', 'f09-good-cupertino-bluetooth', bluetooth, false],
  ['good-custom', 'f09-good-custom-bluetooth', bluetooth, true],
  ['good-group', 'f09-good-group-messages', 'Messages', true],
  ['good-group', 'f09-good-group-reminders', 'Reminders', true],
];

test.describe('switches', () => {
  for (const [slug, id, name, enterToggles] of switches) {
    test(`${id}: a switch named "${name}", off`, async ({ page }) => {
      await open(page, slug);
      const control = byId(page, id);
      await expect(control).toHaveRole('switch');
      await expect(control).toHaveAccessibleName(name);
      await expect(control).not.toBeChecked();
      await expect(control).toHaveAttribute('aria-checked', 'false');
      await expect(control).toBeEnabled();
      // One element carries the name: the label is not a second element.
      await expect(page.getByRole('switch', { name, exact: true })).toHaveCount(1);
      await expect(page.locator('flt-semantics-host').getByText(name, { exact: true })).toHaveCount(0);
    });

    test(`${id}: a click and Space each change the state, and the name stays`, async ({ page }) => {
      await open(page, slug);
      const control = byId(page, id);
      await control.click();
      await expect(control).toBeChecked();
      await expect(control).toHaveAttribute('aria-checked', 'true');
      await expectCount(page, slug, 1);
      await expect(control).toHaveAccessibleName(name);
      expect(await tabTo(page, control, 10), 'Tab reaches the switch').toBe(true);
      await page.keyboard.press('Space');
      await expect(control).not.toBeChecked();
      await expectCount(page, slug, 2);
      await expect(control).toHaveAccessibleName(name);
    });

    test(`${id}: Enter ${enterToggles ? 'changes' : 'does not change'} the state`, async ({ page }) => {
      await open(page, slug);
      const control = byId(page, id);
      expect(await tabTo(page, control, 10), 'Tab reaches the switch').toBe(true);
      await page.keyboard.press('Enter');
      if (enterToggles) {
        await expect(control).toBeChecked();
        await expectCount(page, slug, 1);
      } else {
        // Written to fail when Flutter starts to handle Enter here (FL-002).
        await page.waitForTimeout(500);
        await expect(control).not.toBeChecked();
        await expectCount(page, slug, 0);
      }
    });
  }

  test('good-tile: a click on the label text changes the switch', async ({ page }) => {
    await open(page, 'good-tile');
    const control = byId(page, 'f09-good-tile-bluetooth');
    // The whole row is the element; click near its left edge, on the text.
    const at = await control.boundingBox();
    await page.mouse.click(at.x + 20, at.y + at.height / 2);
    await expect(control).toBeChecked();
    await expectCount(page, 'good-tile', 1);
  });
});

test.describe('good-group', () => {
  test('the question names a group that contains both switches', async ({ page }) => {
    await open(page, 'good-group');
    const group = byId(page, 'f09-good-group-notify');
    await expect(group).toHaveRole('group');
    await expect(group).toHaveAccessibleName('Notify me about');
    await expect(group.getByRole('switch')).toHaveCount(2);
    await expect(
      page.getByRole('group', { name: 'Notify me about' }).getByRole('switch', { name: 'Messages' }),
    ).toHaveCount(1);
    // The visible text is not a second element in the semantics tree.
    await expect(page.locator('flt-semantics-host').getByText('Notify me about', { exact: true })).toHaveCount(0);
  });
});

test.describe('bad examples have their defect', () => {
  test('bad-unlabelled: a switch with no name, and text that is not its label', async ({ page }) => {
    await open(page, 'bad-unlabelled');
    const control = page.getByRole('switch');
    await expect(control).toHaveCount(1);
    await expect(control).toHaveAccessibleName('');
    const text = page.locator('flt-semantics-host').getByText(bluetooth, { exact: true });
    await expect(text).toHaveCount(1);
    // A click on the text does not change the switch. The text's element
    // takes no pointer events, so click at its position.
    const at = await text.boundingBox();
    await page.mouse.click(at.x + at.width / 2, at.y + at.height / 2);
    await page.waitForTimeout(300);
    await expectCount(page, 'bad-unlabelled', 0);
    await expect(control).not.toBeChecked();
    await control.click();
    await expectCount(page, 'bad-unlabelled', 1);
    await expect(control).toBeChecked();
  });

  test('bad-tile-not-merged: a button named "Bluetooth" with no state, around a switch with no name', async ({ page }) => {
    await open(page, 'bad-tile-not-merged');
    const row = page.getByRole('button', { name: bluetooth, exact: true });
    await expect(row).toHaveCount(1);
    await expect(page.getByRole('switch', { name: bluetooth })).toHaveCount(0);
    const inner = row.getByRole('switch');
    await expect(inner).toHaveCount(1);
    await expect(inner).toHaveAccessibleName('');
    for (const [clicks, checked] of [[0, 'false'], [1, 'true']]) {
      await expect(row).not.toHaveAttribute('aria-checked', /.*/);
      await expect(row).not.toHaveAttribute('aria-pressed', /.*/);
      await expect(inner).toHaveAttribute('aria-checked', checked);
      await expectCount(page, 'bad-tile-not-merged', clicks);
      if (clicks === 0) {
        const at = await row.boundingBox();
        await page.mouse.click(at.x + 20, at.y + at.height / 2);
      }
    }
  });

  test('bad-label-changes: the name says the state and changes with it', async ({ page }) => {
    await open(page, 'bad-label-changes');
    const control = byId(page, 'f09-bad-label-changes-bluetooth');
    await expect(control).toHaveRole('switch');
    await expect(control).toHaveAccessibleName('Bluetooth off');
    await expect(control).not.toBeChecked();
    await control.click();
    await expect(control).toBeChecked();
    await expect(control).toHaveAccessibleName('Bluetooth on');
    // The switch can no longer be found by the name it had.
    await expect(page.getByRole('switch', { name: 'Bluetooth off' })).toHaveCount(0);
    await expectCount(page, 'bad-label-changes', 1);
  });

  test('bad-no-state: a button with no state, before and after it is used', async ({ page }) => {
    await open(page, 'bad-no-state');
    const control = byId(page, 'f09-bad-no-state-bluetooth');
    await expect(page.getByRole('switch')).toHaveCount(0);
    for (let clicks = 0; clicks < 2; clicks++) {
      await expect(control).toHaveRole('button');
      await expect(control).toHaveAccessibleName(bluetooth);
      await expect(control).not.toHaveAttribute('aria-checked', /.*/);
      await expect(control).not.toHaveAttribute('aria-pressed', /.*/);
      await expect(control).not.toHaveAttribute('aria-selected', /.*/);
      await control.click();
      await expectCount(page, 'bad-no-state', clicks + 1);
    }
  });
});
