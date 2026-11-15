// L3 for S13 Roles and traits on web: what the browser's accessibility tree
// exposes. Spec: docs/specs/S13-roles-and-traits.md. Runs against the
// release build in build/web.
import { test, expect } from '@playwright/test';

const byId = (page, id) => page.locator(`[flt-semantics-identifier="${id}"]`);

async function open(page, slug) {
  await page.goto('about:blank');
  await page.goto(`/#/t/S13/${slug}`);
  await byId(page, `s13-${slug}-count`).waitFor();
}

const expectCount = (page, slug, n) =>
  expect(byId(page, `s13-${slug}-count`)).toHaveText(`Activations: ${n}`);

/** Press Tab until `locator` has focus. Returns false if it never does. */
async function tabTo(page, locator, max = 8) {
  for (let i = 0; i < max; i++) {
    await page.keyboard.press('Tab');
    // Flutter moves DOM focus on the next frame.
    await page.waitForTimeout(100);
    if (await locator.evaluate((e) => e === document.activeElement)) return true;
  }
  return false;
}

/**
 * Activates an element with a click sent to the element itself, with no
 * pointer position. Which events a screen reader's activation command
 * sends was not recorded; this is the nearest thing a tree test can do. Flutter listens for it only
 * on an element whose node has a tap action.
 */
const domClick = (locator) => locator.evaluate((e) => e.click());

// Identifier -> [accessible name, role].
const good = {
  'good-standard': {
    's13-good-standard-save': ['Save', 'button'],
    's13-good-standard-wifi': ['Wi-Fi', 'switch'],
    's13-good-standard-remember': ['Remember me', 'checkbox'],
  },
  'good-cupertino': {
    's13-good-cupertino-save': ['Save', 'button'],
    's13-good-cupertino-wifi': ['Wi-Fi', 'switch'],
  },
  'good-custom-button': { 's13-good-custom-button-scan': ['Scan barcode', 'button'] },
  'good-custom-switch': { 's13-good-custom-switch-dark': ['Dark mode', 'switch'] },
  'good-selected': {
    's13-good-selected-day': ['Day', 'button'],
    's13-good-selected-week': ['Week', 'button'],
    's13-good-selected-month': ['Month', 'button'],
  },
};

test.describe('good examples', () => {
  for (const [slug, controls] of Object.entries(good)) {
    test(`${slug}: role, name, state, and activation`, async ({ page }) => {
      await open(page, slug);
      let n = 0;
      for (const [id, [name, role]] of Object.entries(controls)) {
        const control = byId(page, id);
        await expect(control).toHaveRole(role);
        await expect(control).toHaveAccessibleName(name);
        await expect(control).toBeEnabled();
        await expect(page.getByRole(role, { name, exact: true })).toHaveCount(1);
        if (role !== 'button') await expect(control).toBeChecked({ checked: false });
        await control.click();
        await expectCount(page, slug, ++n);
        if (role !== 'button') await expect(control).toBeChecked();
        // Activation with no pointer position.
        await domClick(control);
        await expectCount(page, slug, ++n);
        if (role !== 'button') await expect(control).toBeChecked({ checked: false });
      }
    });

    test(`${slug}: Tab reaches each control in order; the keyboard operates it`, async ({ page }) => {
      await open(page, slug);
      let n = 0;
      for (const [id, [, role]] of Object.entries(controls)) {
        expect(await tabTo(page, byId(page, id)), `Tab reaches ${id}`).toBe(true);
        if (role === 'button') {
          await page.keyboard.press('Enter');
          await expectCount(page, slug, ++n);
        }
        // Space is the key a switch or checkbox must answer to (APG); Enter
        // is optional there, and a CupertinoSwitch ignores it on web.
        await page.keyboard.press('Space');
        await expectCount(page, slug, ++n);
        if (role !== 'button') await expect(byId(page, id)).toBeChecked();
      }
    });
  }

  test('good-selected: the chosen button is the current one', async ({ page }) => {
    await open(page, 'good-selected');
    const current = async () =>
      Object.fromEntries(
        await Promise.all(
          ['day', 'week', 'month'].map(async (v) => [
            v,
            await byId(page, `s13-good-selected-${v}`).getAttribute('aria-current'),
          ]),
        ),
      );
    // Flutter's web engine writes `selected` on a button as aria-current.
    expect(await current()).toEqual({ day: 'false', week: 'true', month: 'false' });
    await byId(page, 's13-good-selected-month').click();
    await expectCount(page, 'good-selected', 1);
    expect(await current()).toEqual({ day: 'false', week: 'false', month: 'true' });
  });
});

test.describe('bad examples have their defect', () => {
  test('bad-no-role: on web the control is a button all the same', async ({ page }) => {
    await open(page, 'bad-no-role');
    const control = byId(page, 's13-bad-no-role-scan');
    // The defect cannot be seen on web: Flutter's web engine gives every
    // node with a tap action the button role (FL-006). Android and iOS
    // expose no role (see the device tests). If this changes, the example's
    // doc needs to say so.
    await expect(control).toHaveRole('button');
    await expect(control).toHaveAccessibleName('Scan barcode');
    await domClick(control);
    await expectCount(page, 'bad-no-role', 1);
  });

  test('bad-wrong-role: a button with no state', async ({ page }) => {
    await open(page, 'bad-wrong-role');
    const control = byId(page, 's13-bad-wrong-role-dark');
    for (let n = 0; n < 2; n++) {
      await expect(control).toHaveRole('button');
      await expect(control).toHaveAccessibleName('Dark mode');
      for (const state of ['aria-checked', 'aria-pressed', 'aria-current', 'aria-selected']) {
        await expect(control).not.toHaveAttribute(state);
      }
      await expect(page.getByRole('switch')).toHaveCount(0);
      await control.click();
      await expectCount(page, 'bad-wrong-role', n + 1);
    }
  });

  test('bad-role-on-text: a button that nothing can activate', async ({ page }) => {
    await open(page, 'bad-role-on-text');
    const control = byId(page, 's13-bad-role-on-text-delivery');
    await expect(control).toHaveRole('button');
    await expect(control).toHaveAccessibleName('Free delivery');
    await expect(control).not.toHaveAttribute('tabindex');
    await expect(control).not.toHaveAttribute('flt-tappable');
    await control.click();
    await domClick(control);
    expect(await tabTo(page, control), 'Tab skips the text').toBe(false);
    await page.keyboard.press('Enter');
    await expectCount(page, 'bad-role-on-text', 0);
  });

  test('bad-role-on-standard: a button inside a button', async ({ page }) => {
    await open(page, 'bad-role-on-standard');
    // Both take their name from the text, so there are two buttons "Save".
    const buttons = page.getByRole('button', { name: 'Save', exact: true });
    await expect(buttons).toHaveCount(2);
    const outer = buttons.first();
    const inner = outer.getByRole('button', { name: 'Save', exact: true });
    await expect(inner).toHaveCount(1);
    // The outer one has no label, no action, and no place in the Tab order.
    await expect(outer).not.toHaveAttribute('aria-label');
    await expect(outer).not.toHaveAttribute('flt-tappable');
    await expect(outer).not.toHaveAttribute('tabindex');
    await expect(inner).toHaveAttribute('flt-tappable');
    await inner.click();
    await expectCount(page, 'bad-role-on-standard', 1);
  });

  test('bad-action-hidden: pointer and keys work; activation without a pointer does not', async ({ page }) => {
    await open(page, 'bad-action-hidden');
    const control = byId(page, 's13-bad-action-hidden-scan');
    await expect(control).toHaveRole('button');
    await expect(control).toHaveAccessibleName('Scan barcode');
    await expect(control).toBeEnabled();
    await expect(control).not.toHaveAttribute('flt-tappable');
    // A click sent to the element does nothing.
    await domClick(control);
    await page.waitForTimeout(300);
    await expectCount(page, 'bad-action-hidden', 0);
    // A pointer and the keyboard both work, which is what hides the defect.
    await control.click();
    await expectCount(page, 'bad-action-hidden', 1);
    expect(await tabTo(page, control), 'Tab reaches the control').toBe(true);
    await page.keyboard.press('Enter');
    await expectCount(page, 'bad-action-hidden', 2);
  });

  test('bad-switch-not-enabled: on web the switch is not disabled', async ({ page }) => {
    await open(page, 'bad-switch-not-enabled');
    const control = byId(page, 's13-bad-switch-not-enabled-dark');
    // The defect is on iOS only (FL-033): VoiceOver reads the switch as
    // dimmed. The web exposes an ordinary switch.
    await expect(control).toHaveRole('switch');
    await expect(control).toHaveAccessibleName('Dark mode');
    await expect(control).not.toHaveAttribute('aria-disabled');
    await expect(control).toBeChecked({ checked: false });
    await control.click();
    await expect(control).toBeChecked();
  });
});
