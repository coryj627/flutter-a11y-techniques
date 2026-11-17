// L3 for S14 Values and state descriptions on web: what the browser's
// accessibility tree exposes. Spec:
// docs/specs/S14-values-and-state-descriptions.md. Runs against the release
// build in build/web.
import { test, expect } from '@playwright/test';
import { byId, tabTo, technique } from './support/techniques.js';

const { open, expectCount } = technique('S14', { countLabel: 'Changes' });

// On web an adjustable node is an <input type="range"> inside the element
// that carries the identifier and the name.
const slider = (page, id) => byId(page, id).locator('input[role="slider"]');

test.describe('good examples', () => {
  test('good-rating: a slider whose value text is the rating', async ({ page }) => {
    await open(page, 'good-rating');
    const id = 's14-good-rating-rating';
    await expect(slider(page, id)).toHaveCount(1);
    await expect(slider(page, id)).toHaveAttribute('aria-valuetext', '3 out of 5');
    // Flutter 3.47.5: the name is on the element around the slider, so the
    // slider itself has none (FL-028). Written to fail if that is fixed.
    await expect(byId(page, id)).toHaveAttribute('aria-label', 'Rating');
    await expect(slider(page, id)).toHaveAccessibleName('');
    // The stars are not exposed one by one.
    await expect(page.getByRole('img')).toHaveCount(0);
    expect(await page.getByRole('button').count()).toBe(1); // Back
  });

  test('good-rating: the arrow keys change the value text', async ({ page }) => {
    await open(page, 'good-rating');
    const input = slider(page, 's14-good-rating-rating');
    expect(await tabTo(page, input), 'Tab reaches the rating').toBe(true);
    await page.keyboard.press('ArrowRight');
    await expect(input).toHaveAttribute('aria-valuetext', '4 out of 5');
    await expectCount(page, 'good-rating', 1);
    await page.keyboard.press('ArrowLeft');
    await page.keyboard.press('ArrowLeft');
    await expect(input).toHaveAttribute('aria-valuetext', '2 out of 5');
    await expectCount(page, 'good-rating', 3);
  });

  test('good-step: one element that reads the step', async ({ page }) => {
    await open(page, 'good-step');
    const progress = byId(page, 's14-good-step-progress');
    // On web the value follows the label in the element's text (FL-037).
    await expect(progress).toHaveText('Progress Step 2 of 4');
    for (const n of ['1', '2', '3', '4']) {
      await expect(page.getByText(n, { exact: true })).toHaveCount(0);
    }
    await byId(page, 's14-good-step-next').click();
    await expect(progress).toHaveText('Progress Step 3 of 4');
    await expectCount(page, 'good-step', 1);
  });

  test('good-button-value: a button that reads its mode', async ({ page }) => {
    await open(page, 'good-button-value');
    const button = byId(page, 's14-good-button-value-repeat');
    await expect(button).toHaveRole('button');
    // On web the value is part of the accessible name (FL-037).
    await expect(button).toHaveAccessibleName('Repeat Off');
    await button.click();
    await expect(button).toHaveAccessibleName('Repeat All');
    expect(await tabTo(page, button), 'Tab reaches the button').toBe(true);
    await page.keyboard.press('Enter');
    await expect(button).toHaveAccessibleName('Repeat One');
    await page.keyboard.press('Space');
    await expect(button).toHaveAccessibleName('Repeat Off');
    await expectCount(page, 'good-button-value', 3);
  });

  test('good-slider-format: the value text is in minutes', async ({ page }) => {
    await open(page, 'good-slider-format');
    const id = 's14-good-slider-format-timer';
    const input = slider(page, id);
    await expect(input).toHaveAttribute('aria-valuetext', '15 minutes');
    await expect(byId(page, id)).toHaveAttribute('aria-label', 'Timer');
    expect(await tabTo(page, input), 'Tab reaches the slider').toBe(true);
    await page.keyboard.press('ArrowRight');
    await expect(input).toHaveAttribute('aria-valuetext', '20 minutes');
    await expectCount(page, 'good-slider-format', 1);
  });
});

test.describe('bad examples have their defect', () => {
  test('bad-rating-no-value: a slider with no value text', async ({ page }) => {
    await open(page, 'bad-rating-no-value');
    const input = slider(page, 's14-bad-rating-no-value-rating');
    await expect(input).toHaveAttribute('aria-valuetext', '');
    // With no increasedValue or decreasedValue the web slider has nowhere
    // to go: its minimum and maximum are the same.
    expect(await input.getAttribute('aria-valuemin')).toBe(await input.getAttribute('aria-valuemax'));
    await expect(page.getByText('out of 5')).toHaveCount(0);
    // The arrow keys still change the rating, through Flutter's own key
    // handling, so the missing value is the defect and not a dead control.
    // Whether a screen reader's adjust command can move a slider with a
    // range of one point was not tested.
    expect(await tabTo(page, input), 'Tab reaches the rating').toBe(true);
    await page.keyboard.press('ArrowRight');
    await expectCount(page, 'bad-rating-no-value', 1);
    await page.keyboard.press('ArrowLeft');
    await expectCount(page, 'bad-rating-no-value', 2);
    await expect(input).toHaveAttribute('aria-valuetext', '');
  });

  test('bad-stale-value: the value text does not follow the rating', async ({ page }) => {
    await open(page, 'bad-stale-value');
    const input = slider(page, 's14-bad-stale-value-rating');
    await expect(input).toHaveAttribute('aria-valuetext', '3 out of 5');
    expect(await tabTo(page, input), 'Tab reaches the rating').toBe(true);
    await page.keyboard.press('ArrowRight');
    await expectCount(page, 'bad-stale-value', 1);
    await page.keyboard.press('ArrowRight');
    await expectCount(page, 'bad-stale-value', 2);
    await expect(input).toHaveAttribute('aria-valuetext', '3 out of 5');
  });

  test('bad-step-no-value: four numbers and no current step', async ({ page }) => {
    await open(page, 'bad-step-no-value');
    for (const n of ['1', '2', '3', '4']) {
      await expect(page.getByText(n, { exact: true })).toHaveCount(1);
    }
    await expect(page.getByText('Progress')).toHaveCount(0);
    await expect(page.getByText(/Step \d of 4/)).toHaveCount(0);
    await expect(page.locator('flt-semantics-host [aria-current]')).toHaveCount(0);
    await expect(page.locator('flt-semantics-host [aria-selected]')).toHaveCount(0);
  });

  test('bad-button-no-value: the same name in every mode', async ({ page }) => {
    await open(page, 'bad-button-no-value');
    const button = byId(page, 's14-bad-button-no-value-repeat');
    for (let n = 0; n < 3; n++) {
      await expect(button).toHaveRole('button');
      await expect(button).toHaveAccessibleName('Repeat');
      for (const state of ['aria-pressed', 'aria-checked', 'aria-current']) {
        await expect(button).not.toHaveAttribute(state);
      }
      await button.click();
      await expectCount(page, 'bad-button-no-value', n + 1);
    }
  });

  test('bad-value-on-switch: the value becomes part of the name', async ({ page }) => {
    await open(page, 'bad-value-on-switch');
    const control = byId(page, 's14-bad-value-on-switch-alarm');
    await expect(control).toHaveRole('switch');
    // The name changes when the switch does, and says the state a second
    // time (FL-036).
    await expect(control).toHaveAccessibleName('Home alarm Deactivated');
    await expect(control).toBeChecked({ checked: false });
    await control.click();
    await expect(control).toHaveAccessibleName('Home alarm Activated');
    await expect(control).toBeChecked();
  });
});
