// L3 for F02 Input instructions on web: what the browser exposes.
// Spec: docs/specs/F02-input-instructions.md. Runs against the release build in build/web.
import { test, expect } from '@playwright/test';
import { byId, tabTo, technique } from './support/techniques.js';

// Waits for the count, then a moment more: Flutter attaches its text editing
// a moment after the tree appears.
const { open, expectCount } = technique('F02', { countLabel: 'Changes', settle: 600 });

/** The <input> inside the node carrying a test identifier. */
const field = (page, id) => byId(page, id).locator('input');

async function type(page, locator, text) {
  await locator.click();
  await page.waitForTimeout(250);
  await page.keyboard.type(text, { delay: 40 });
  await expect(locator).toHaveValue(text);
}

const USERNAME = 'Username';
const RULE = '4 to 10 characters, no spaces.';
const DISPLAY_RULE = 'Shown on your posts. 2 to 30 letters or numbers.';

// slug -> identifier. Each field is named "Username" and has the rule on the
// page and as its description.
const GOOD = {
  'good-helper': 'f02-good-helper-username',
  'good-cupertino': 'f02-good-cupertino-username',
  'good-before': 'f02-good-before-username',
};

test.describe('good examples', () => {
  for (const [slug, id] of Object.entries(GOOD)) {
    test(`${slug}: a text box named "${USERNAME}" described by the instruction, before and after typing`, async ({ page }) => {
      await open(page, slug);
      const box = field(page, id);
      for (const value of ['', 'abc']) {
        if (value) await type(page, box, value);
        await expect(box).toHaveRole('textbox');
        await expect(box).toHaveAccessibleName(USERNAME);
        await expect(box).toHaveAccessibleDescription(RULE);
        // Flutter sets the hint as aria-description; nothing else describes it.
        await expect(box).toHaveAttribute('aria-description', RULE);
        await expect(box).not.toHaveAttribute('aria-describedby');
      }
      await expectCount(page, slug, 3);
    });

    test(`${slug}: the instruction is text on the page, once, and is not in the name`, async ({ page }) => {
      await open(page, slug);
      const rule = page.getByText(RULE, { exact: true });
      await expect(rule).toHaveCount(1);
      await expect(rule).toBeVisible();
      await expect(page.getByRole('textbox', { name: USERNAME, exact: true })).toHaveCount(1);
      // The visible label is not exposed a second time as text.
      await expect(page.getByText(USERNAME, { exact: true })).toHaveCount(0);
    });

    test(`${slug}: Tab reaches the field`, async ({ page }) => {
      await open(page, slug);
      expect(await tabTo(page, field(page, id))).toBe(true);
    });
  }

  test('good-before: the instruction comes before the field in the page', async ({ page }) => {
    await open(page, 'good-before');
    const rule = page.getByText(RULE, { exact: true });
    const before = await rule.evaluate(
      (text, input) => Boolean(text.compareDocumentPosition(input) & Node.DOCUMENT_POSITION_FOLLOWING),
      await field(page, GOOD['good-before']).elementHandle(),
    );
    expect(before).toBe(true);
  });

  test('good-helper: the helper text sits inside the field\'s element, beside the input (FL-140)', async ({ page }) => {
    await open(page, 'good-helper');
    await expect(byId(page, GOOD['good-helper']).getByText(RULE, { exact: true })).toHaveCount(1);
  });
});

// VAL-3: each bad example is asserted to have its named defect.
test.describe('bad examples have their defect', () => {
  test('bad-helper-only: the text box has no description, and the instruction is only text beside it', async ({ page }) => {
    await open(page, 'bad-helper-only');
    const id = 'f02-bad-helper-only-username';
    const box = field(page, id);
    for (const value of ['', 'abc']) {
      if (value) await type(page, box, value);
      await expect(box).toHaveAccessibleName(USERNAME);
      // Written to fail if Flutter starts to describe a field by its helper text.
      await expect(box).toHaveAccessibleDescription('');
      await expect(box).not.toHaveAttribute('aria-description');
      await expect(box).not.toHaveAttribute('aria-describedby');
      await expect(byId(page, id).getByText(RULE, { exact: true })).toBeVisible();
    }
  });

  test('bad-placeholder-format: the format is in the page only while the field is focused and empty', async ({ page }) => {
    await open(page, 'bad-placeholder-format');
    const box = field(page, 'f02-bad-placeholder-format-birthday');
    const format = 'DD/MM/YYYY';
    // Not focused: the format is nowhere.
    await expect(box).toHaveAttribute('aria-label', 'Date of birth');
    await expect(box).not.toHaveAttribute('placeholder');
    await expect(box).toHaveAccessibleDescription('');
    await expect(page.getByText(format)).toHaveCount(0);
    // Focused and empty: Flutter adds it to the name and sets a placeholder.
    await box.click();
    await page.waitForTimeout(500);
    await expect(box).toHaveAttribute('aria-label', `Date of birth\n${format}`);
    await expect(box).toHaveAttribute('placeholder', format);
    // One character in: gone from the name, and a placeholder is not shown
    // for a field with a value.
    await page.keyboard.type('a', { delay: 40 });
    await expect(box).toHaveValue('a');
    await expect(box).toHaveAttribute('aria-label', 'Date of birth');
    await expect(box).toHaveAccessibleName('Date of birth');
    await expect(box).toHaveAccessibleDescription('');
  });

  test('bad-helper-cut-off: the whole instruction is in the page and is the description', async ({ page }) => {
    // The defect is on the screen: at 200% text Flutter cuts the helper to
    // one line. This build runs at Flutter's default text scale, and the
    // DOM holds the whole text either way, so the cut cannot be seen here;
    // the widget tests assert it. What this layer shows is that the tree
    // keeps all of it.
    await open(page, 'bad-helper-cut-off');
    const box = field(page, 'f02-bad-helper-cut-off-name');
    await expect(box).toHaveAccessibleName('Display name');
    await expect(box).toHaveAccessibleDescription(DISPLAY_RULE);
    await expect(page.getByText(DISPLAY_RULE, { exact: true })).toHaveCount(1);
  });
});
