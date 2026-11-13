// L3 for F01 Text fields and labels on web: what the browser exposes.
// Spec: docs/specs/F01-text-fields.md. Runs against the release build in build/web.
import { test, expect } from '@playwright/test';

/** The <input> or <textarea> inside the node carrying a test identifier. */
const field = (page, id) =>
  page.locator(`[flt-semantics-identifier="${id}"]`).locator('input,textarea');

async function open(page, slug) {
  await page.goto('about:blank');
  await page.goto(`/#/t/F01/${slug}`);
  await page.getByRole('heading', { name: 'Example', level: 2 }).waitFor();
  // Flutter attaches its text editing a moment after the tree appears.
  await page.waitForTimeout(600);
}

async function type(page, locator, text) {
  await locator.click();
  await page.waitForTimeout(250);
  await page.keyboard.type(text, { delay: 40 });
  await expect(locator).toHaveValue(text);
}

const good = {
  'good-label': { 'f01-good-label-email': 'Email', 'f01-good-label-message': 'Message' },
  'good-label-above': { 'f01-good-label-above-name': 'Full name' },
  'good-cupertino': { 'f01-good-cupertino-email': 'Email' },
};

test.describe('good examples', () => {
  for (const [slug, fields] of Object.entries(good)) {
    test(`${slug}: a real text box with a name that survives typing`, async ({ page }) => {
      await open(page, slug);
      for (const [id, name] of Object.entries(fields)) {
        const box = field(page, id);
        await expect(box).toHaveRole('textbox');
        await expect(box).toHaveAccessibleName(name);
        await expect(page.getByRole('textbox', { name, exact: true })).toHaveCount(1);
        await type(page, box, 'abc');
        await expect(box).toHaveAccessibleName(name);
        // The name is an explicit label, not a placeholder fallback.
        await expect(box).toHaveAttribute('aria-label', name);
      }
    });
  }

  test('good-label: single-line and multi-line fields are input and textarea', async ({ page }) => {
    await open(page, 'good-label');
    expect(await field(page, 'f01-good-label-email').evaluate((e) => e.tagName)).toBe('INPUT');
    expect(await field(page, 'f01-good-label-message').evaluate((e) => e.tagName)).toBe('TEXTAREA');
  });

  test('good-label: Tab moves from one field to the next', async ({ page }) => {
    await open(page, 'good-label');
    const email = field(page, 'f01-good-label-email');
    await type(page, email, 'a@b.c');
    await page.keyboard.press('Tab');
    await page.waitForTimeout(300);
    await page.keyboard.type('hello', { delay: 40 });
    await expect(field(page, 'f01-good-label-message')).toHaveValue('hello');
    await expect(email).toHaveValue('a@b.c');
  });

  for (const [slug, name] of [['good-label-above', 'Full name'], ['good-cupertino', 'Email']]) {
    test(`${slug}: the visible label is not exposed a second time`, async ({ page }) => {
      await open(page, slug);
      await expect(page.getByText(name, { exact: true })).toHaveCount(0);
      await expect(page.getByRole('textbox', { name, exact: true })).toHaveCount(1);
    });
  }
});

// VAL-3: each bad example is asserted to have its named defect.
test.describe('bad examples have their defect', () => {
  for (const [slug, id] of [
    ['bad-placeholder-only', 'f01-bad-placeholder-only-email'],
    ['bad-cupertino-placeholder', 'f01-bad-cupertino-placeholder-email'],
  ]) {
    test(`${slug}: once text is typed the explicit label is gone and only a placeholder is left`, async ({ page }) => {
      await open(page, slug);
      const box = field(page, id);
      await expect(box).toHaveAttribute('aria-label', 'Email');
      await type(page, box, 'abc');
      // Flutter drops the label. The browser falls back to the placeholder
      // attribute for a name, which is the weakest naming source it has and
      // is no longer shown on screen.
      await expect(box).not.toHaveAttribute('aria-label');
      await expect(box).toHaveAttribute('placeholder', 'Email');
    });
  }

  for (const [slug, id] of [
    ['bad-unassociated-label', 'f01-bad-unassociated-label-email'],
    ['bad-cupertino-prefix', 'f01-bad-cupertino-prefix-email'],
  ]) {
    test(`${slug}: "Email" is on the page but the text box has no name`, async ({ page }) => {
      await open(page, slug);
      await expect(page.getByText('Email', { exact: true })).toBeVisible();
      const box = field(page, id);
      await expect(box).toHaveRole('textbox');
      await expect(box).toHaveAccessibleName('');
      await expect(page.getByRole('textbox', { name: 'Email' })).toHaveCount(0);
    });
  }

  test('bad-no-label: a text box with no name', async ({ page }) => {
    await open(page, 'bad-no-label');
    const box = field(page, 'f01-bad-no-label-search');
    await expect(box).toHaveRole('textbox');
    await expect(box).toHaveAccessibleName('');
  });

  test('bad-name-mismatch: the name does not contain the visible label', async ({ page }) => {
    await open(page, 'bad-name-mismatch');
    const box = field(page, 'f01-bad-name-mismatch-email');
    await expect(box).toHaveAccessibleName('Contact address');
    await expect(box).not.toHaveAccessibleName(/email/i);
  });
});
