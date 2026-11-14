// L3 for S01 Accessible names on web: what the browser's accessibility tree
// exposes. Spec: docs/specs/S01-accessible-names.md. Runs against the release
// build in build/web.
import { test, expect } from '@playwright/test';

const byId = (page, id) => page.locator(`[flt-semantics-identifier="${id}"]`);

async function open(page, slug, firstId) {
  await page.goto('about:blank');
  await page.goto(`/#/t/S01/${slug}`);
  await byId(page, firstId).waitFor();
}

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

// id: [role, accessible name]
const named = {
  'good-visible-label': {
    's01-good-visible-label-updates': ['checkbox', 'Email me order updates'],
    's01-good-visible-label-dark': ['switch', 'Dark mode'],
  },
  'good-merged-label': {
    's01-good-merged-label-remember': ['checkbox', 'Remember this device'],
    's01-good-merged-label-wifi': ['switch', 'Wi-Fi'],
  },
  'good-specific-names': {
    's01-good-specific-names-email': ['switch', 'Order updates, email'],
    's01-good-specific-names-sms': ['switch', 'Order updates, text message'],
  },
  'good-cupertino': {
    's01-good-cupertino-airplane': ['switch', 'Airplane mode'],
  },
};

test.describe('good examples', () => {
  for (const [slug, controls] of Object.entries(named)) {
    const ids = Object.keys(controls);

    test(`${slug}: role, name, and click`, async ({ page }) => {
      await open(page, slug, ids[0]);
      for (const [id, [role, name]] of Object.entries(controls)) {
        const control = byId(page, id);
        await expect(control).toHaveRole(role);
        await expect(control).toHaveAccessibleName(name);
        await expect(control).not.toBeChecked();
        // One control has this name, and the text is not a second element.
        await expect(page.getByRole(role, { name, exact: true })).toHaveCount(1);
        await expect(page.getByText(name, { exact: true })).toHaveCount(0);
        await control.click();
        await expect(control).toBeChecked();
      }
    });

    test(`${slug}: Tab reaches each control and Space operates it`, async ({ page }) => {
      await open(page, slug, ids[0]);
      for (const id of ids) {
        const control = byId(page, id);
        expect(await tabTo(page, control), `Tab reaches ${id}`).toBe(true);
        await page.keyboard.press('Space');
        await expect(control).toBeChecked();
      }
    });
  }
});

test.describe('bad examples', () => {
  test('bad-unassociated-label: the checkbox has no name', async ({ page }) => {
    const id = 's01-bad-unassociated-label-terms';
    await open(page, 'bad-unassociated-label', id);
    const checkbox = byId(page, id);
    await expect(checkbox).toHaveRole('checkbox');
    await expect(checkbox).toHaveAccessibleName('');
    // The text is on the page, outside the checkbox.
    await expect(page.getByText('I accept the terms', { exact: true })).toHaveCount(1);
    await expect(page.getByRole('checkbox', { name: 'I accept the terms' })).toHaveCount(0);
    await checkbox.click();
    await expect(checkbox).toBeChecked();
  });

  test('bad-duplicate-names: two switches share one name', async ({ page }) => {
    await open(page, 'bad-duplicate-names', 's01-bad-duplicate-names-email');
    await expect(page.getByRole('switch', { name: 'Order updates', exact: true })).toHaveCount(2);
  });

  test('bad-role-in-name: the name ends with the role', async ({ page }) => {
    const id = 's01-bad-role-in-name-dark';
    await open(page, 'bad-role-in-name', id);
    await expect(byId(page, id)).toHaveRole('switch');
    await expect(byId(page, id)).toHaveAccessibleName('Dark mode switch');
  });

  // Flutter limitation FL-028. If this test fails after a Flutter upgrade
  // because the slider has the name "Volume", the limitation is fixed: move
  // the example to the good examples and update the entry.
  test('bad-slider-name-web: the name is on a wrapper, not on the slider', async ({ page }) => {
    const id = 's01-bad-slider-name-web-volume';
    await open(page, 'bad-slider-name-web', id);
    const wrapper = byId(page, id);
    const slider = wrapper.locator('input[role="slider"]');
    await expect(slider).toHaveCount(1);
    await expect(page.getByRole('slider')).toHaveCount(1);
    await expect(wrapper).toHaveAttribute('aria-label', 'Volume');
    await expect(wrapper).not.toHaveAttribute('role');
    await expect(slider).not.toHaveAttribute('aria-label');
    await expect(slider).not.toHaveAttribute('aria-labelledby');
    await expect(slider).toHaveAccessibleName('');
    await expect(page.getByRole('slider', { name: 'Volume' })).toHaveCount(0);
    // The value is exposed; only the name is missing.
    await expect(slider).toHaveAttribute('aria-valuetext', '40%');
    // The slider still works from the keyboard.
    expect(await tabTo(page, slider), 'Tab reaches the slider').toBe(true);
    await page.keyboard.press('ArrowRight');
    await expect(slider).toHaveAttribute('aria-valuetext', '50%');
  });
});
