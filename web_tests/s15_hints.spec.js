// L3 for S15 Hints on web: what the browser's accessibility tree exposes.
// Spec: docs/specs/S15-hints.md. Runs against the release build in
// build/web.
import { test, expect } from '@playwright/test';
import { byId, tabTo, technique } from './support/techniques.js';

const { open, expectCount } = technique('S15', { countLabel: 'Changes' });

/** The <input> inside the node carrying a test identifier. */
const field = (page, id) => byId(page, id).locator('input');

/**
 * Every element on the page that carries a hint: `aria-description`, or the
 * engine's fallback, `aria-describedby` pointing at a `flt-hint-` element.
 * Off Apple platforms the route element has an `aria-describedby` of its
 * own, pointing at the screen's title; that is not a hint.
 */
const described = (page) =>
  page.locator('[aria-description],[aria-describedby^="flt-hint-"]');

// On web a hint is aria-description: the accessible description of the
// element, apart from its name.
const buttons = [
  ['good-result', 's15-good-result-favorite', 'Favorite', 'Adds this item to your favorites.'],
  ['good-row', 's15-good-row-song', 'Night Ferry The Lanterns', 'Plays the song.'],
  ['good-cupertino', 's15-good-cupertino-share', 'Share', 'Shares the current page.'],
  ['good-custom', 's15-good-custom-archive', 'Archive', 'Moves this message out of the inbox.'],
  ['bad-gesture', 's15-bad-gesture-favorite', 'Favorite', 'Double tap to add this item to your favorites.'],
  ['bad-repeats-label', 's15-bad-repeats-label-delete', 'Delete', 'Delete'],
  ['bad-control-type', 's15-bad-control-type-share', 'Share', 'This button shares the current page.'],
  ['bad-no-hint', 's15-bad-no-hint-song', 'Night Ferry The Lanterns', ''],
];

const rule = '3 to 12 letters or numbers.';

test.describe('buttons', () => {
  for (const [slug, id, name, hint] of buttons) {
    test(`${slug}: a button named "${name}" described as "${hint}"`, async ({ page }) => {
      await open(page, slug);
      const button = byId(page, id);
      await expect(button).toHaveRole('button');
      await expect(button).toHaveAccessibleName(name);
      await expect(button).toHaveAccessibleDescription(hint);
      // The hint is on the button and nowhere else, and is not in its name.
      await expect(described(page)).toHaveCount(hint ? 1 : 0);
      if (hint) await expect(button).toHaveAttribute('aria-description', hint);
      expect(await page.getByRole('button').count()).toBe(2); // Back and this one
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
      await expect(button).toHaveAccessibleDescription(hint);
    });
  }
});

test.describe('fields', () => {
  test('good-field: the rule describes the field and is also text on the page', async ({ page }) => {
    await open(page, 'good-field');
    const input = field(page, 's15-good-field-username');
    await expect(input).toHaveRole('textbox');
    await expect(input).toHaveAccessibleName('Username');
    await expect(input).toHaveAccessibleDescription(rule);
    await expect(page.getByText(rule, { exact: true })).toHaveCount(1);
    // A click puts the field in editing mode; typing follows a frame later.
    await input.click();
    await page.waitForTimeout(300);
    await page.keyboard.type('a', { delay: 40 });
    await expectCount(page, 'good-field', 1);
    await expect(input).toHaveAccessibleDescription(rule);
  });

  test('bad-hint-only: the rule describes the field and is not on the page', async ({ page }) => {
    await open(page, 'bad-hint-only');
    const input = field(page, 's15-bad-hint-only-username');
    await expect(input).toHaveAccessibleName('Username');
    await expect(input).toHaveAccessibleDescription(rule);
    await expect(page.getByText(/3 to 12/)).toHaveCount(0);
  });
});

test.describe('bad examples have their defect', () => {
  test('bad-hint-detached: the hint is not in the page at all', async ({ page }) => {
    await open(page, 'bad-hint-detached');
    const button = page.getByRole('button', { name: 'Favorite', exact: true });
    await expect(button).toHaveCount(1);
    // Flutter 3.47.5: the hint is on a node of its own with no name, and the
    // web engine renders no description for a node with no name (FL-040,
    // FL-041). Written to fail if the hint starts to reach the page.
    await expect(button).toHaveAccessibleDescription('');
    await expect(described(page)).toHaveCount(0);
    await expect(page.getByText(/Adds this item/)).toHaveCount(0);
    expect(await page.content()).not.toContain('Adds this item');
    await button.click();
    await expectCount(page, 'bad-hint-detached', 1);
  });
});
