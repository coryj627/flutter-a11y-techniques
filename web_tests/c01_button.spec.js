// L3 for C01 Button on web: what the browser's accessibility tree exposes.
// Spec: docs/specs/C01-button.md. Runs against the release build in build/web.
import { test, expect } from '@playwright/test';

const byId = (page, id) => page.locator(`[flt-semantics-identifier="${id}"]`);

async function open(page, slug) {
  await page.goto('about:blank');
  await page.goto(`/#/t/C01/${slug}`);
  await byId(page, `c01-${slug}-count`).waitFor();
}

const expectCount = (page, slug, n) =>
  expect(byId(page, `c01-${slug}-count`)).toHaveText(`Activations: ${n}`);

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

const enabledGood = {
  'good-text': {
    'c01-good-text-filled': 'Save',
    'c01-good-text-outlined': 'Cancel',
    'c01-good-text-text': 'Learn more',
  },
  'good-icon': { 'c01-good-icon-close': 'Close' },
  'good-unique-names': {
    'c01-good-unique-names-username': 'Edit username',
    'c01-good-unique-names-email': 'Edit email',
    'c01-good-unique-names-password': 'Edit password',
  },
  'good-cupertino': { 'c01-good-cupertino-save': 'Save' },
  'good-custom': { 'c01-good-custom-save': 'Save' },
};

const disabledGood = {
  'good-disabled': { 'c01-good-disabled-submit': 'Submit' },
  'good-cupertino': { 'c01-good-cupertino-delete': 'Delete' },
};

test.describe('good examples', () => {
  for (const [slug, buttons] of Object.entries(enabledGood)) {
    test(`${slug}: role, name, and click`, async ({ page }) => {
      await open(page, slug);
      let n = 0;
      for (const [id, name] of Object.entries(buttons)) {
        const button = byId(page, id);
        await expect(button).toHaveRole('button');
        await expect(button).toHaveAccessibleName(name);
        await expect(button).toBeEnabled();
        await expect(page.getByRole('button', { name, exact: true })).toHaveCount(1);
        await button.click();
        await expectCount(page, slug, ++n);
      }
    });

    test(`${slug}: Tab reaches each button in order; Enter and Space activate`, async ({ page }) => {
      await open(page, slug);
      let n = 0;
      for (const id of Object.keys(buttons)) {
        expect(await tabTo(page, byId(page, id)), `Tab reaches ${id}`).toBe(true);
        await page.keyboard.press('Enter');
        if (id.includes('cupertino')) {
          // Flutter limitation (3.47.5): on web Enter is ButtonActivateIntent,
          // which CupertinoButton does not handle, so Enter does nothing.
          // If this starts passing after an upgrade, the limitation is fixed.
          await page.waitForTimeout(300);
          await expectCount(page, slug, n);
        } else {
          await expectCount(page, slug, ++n);
        }
        await page.keyboard.press('Space');
        await expectCount(page, slug, ++n);
      }
    });
  }

  for (const [slug, buttons] of Object.entries(disabledGood)) {
    test(`${slug}: disabled button is exposed as disabled and cannot act`, async ({ page }) => {
      await open(page, slug);
      for (const [id, name] of Object.entries(buttons)) {
        const button = byId(page, id);
        await expect(button).toHaveRole('button');
        await expect(button).toHaveAccessibleName(name);
        await expect(button).toHaveAttribute('aria-disabled', 'true');
        await expect(button).toBeDisabled();
        await button.click({ force: true });
        expect(await tabTo(page, button), `Tab skips ${id}`).toBe(false);
      }
      await expectCount(page, slug, 0);
    });
  }

  test('activation is announced through a polite live region', async ({ page }) => {
    await open(page, 'good-text');
    await byId(page, 'c01-good-text-filled').click();
    await expect(page.locator('flt-announcement-polite')).toHaveText(/Activations: 1/);
  });
});

// VAL-3: each bad example is asserted to have its named defect.
test.describe('bad examples have their defect', () => {
  test('bad-unlabelled-icon: a button with an empty name', async ({ page }) => {
    await open(page, 'bad-unlabelled-icon');
    const button = byId(page, 'c01-bad-unlabelled-icon-close');
    await expect(button).toHaveRole('button');
    await expect(button).toHaveAccessibleName('');
  });

  test('bad-gesture-only: cannot be reached or activated from the keyboard', async ({ page }) => {
    await open(page, 'bad-gesture-only');
    const target = byId(page, 'c01-bad-gesture-only-save');
    // Flutter web gives every tappable node role="button", so on web the role
    // is present and the defect is keyboard access only.
    await expect(target).toHaveRole('button');
    await expect(target).not.toHaveAttribute('tabindex');
    expect(await tabTo(page, target)).toBe(false);
    await expectCount(page, 'bad-gesture-only', 0);
    await target.click();
    await expectCount(page, 'bad-gesture-only', 1);
  });

  test('bad-role-in-name: the name ends with the role', async ({ page }) => {
    await open(page, 'bad-role-in-name');
    await expect(byId(page, 'c01-bad-role-in-name-close')).toHaveAccessibleName(/button$/i);
  });

  test('bad-duplicate-names: three buttons share one name', async ({ page }) => {
    await open(page, 'bad-duplicate-names');
    await expect(page.getByRole('button', { name: 'Edit', exact: true })).toHaveCount(3);
  });

  test('bad-name-mismatch: the name does not contain "Edit"', async ({ page }) => {
    await open(page, 'bad-name-mismatch');
    const button = byId(page, 'c01-bad-name-mismatch-edit');
    await expect(button).toHaveAccessibleName('Change username');
    await expect(button).not.toHaveAccessibleName(/edit/i);
  });

  test('bad-fake-disabled: reported as enabled and still acts', async ({ page }) => {
    await open(page, 'bad-fake-disabled');
    const button = byId(page, 'c01-bad-fake-disabled-submit');
    await expect(button).not.toHaveAttribute('aria-disabled');
    await button.click();
    await expectCount(page, 'bad-fake-disabled', 1);
  });

  test('bad-cupertino-disabled: no disabled state (Flutter limitation)', async ({ page }) => {
    await open(page, 'bad-cupertino-disabled');
    const button = byId(page, 'c01-bad-cupertino-disabled-delete');
    await expect(button).toHaveRole('button');
    await expect(button).not.toHaveAttribute('aria-disabled');
    await button.click({ force: true });
    await expectCount(page, 'bad-cupertino-disabled', 0);
  });
});
