// L3 for F08 Radio group on web: what the browser's accessibility tree
// exposes. Spec: docs/specs/F08-radio-group.md. Runs against the release
// build in build/web.
import { test, expect } from '@playwright/test';

const byId = (page, id) => page.locator(`[flt-semantics-identifier="${id}"]`);

async function open(page, slug) {
  await page.goto('about:blank');
  await page.goto(`/#/t/F08/${slug}`);
  await byId(page, `f08-${slug}-count`).waitFor();
}

const expectCount = (page, slug, n) =>
  expect(byId(page, `f08-${slug}-count`)).toHaveText(`Changes: ${n}`);

const options = { standard: 'Standard', express: 'Express', 'next-day': 'Next day' };

/** The id segment of the one option that is checked. */
async function chosen(page, slug) {
  const checked = [];
  for (const option of Object.keys(options)) {
    if ((await byId(page, `f08-${slug}-${option}`).getAttribute('aria-checked')) === 'true') checked.push(option);
  }
  expect(checked, 'exactly one option is checked').toHaveLength(1);
  return checked[0];
}

// Examples whose options are radio buttons in the tree, "Express" chosen.
const radioExamples = ['good-group', 'good-cupertino', 'good-custom', 'bad-group-unlabelled', 'bad-checked-only'];
// Examples built on RadioGroup, which supplies the arrow keys.
const grouped = ['good-group', 'good-cupertino', 'good-custom'];

test.describe('radio buttons', () => {
  for (const slug of radioExamples) {
    test(`${slug}: three radio buttons with their names, "Express" checked`, async ({ page }) => {
      await open(page, slug);
      await expect(page.getByRole('radio')).toHaveCount(3);
      for (const [option, name] of Object.entries(options)) {
        const radio = byId(page, `f08-${slug}-${option}`);
        await expect(radio).toHaveRole('radio');
        await expect(radio).toHaveAccessibleName(name);
        await expect(radio).toHaveAttribute('aria-checked', option === 'express' ? 'true' : 'false');
        await expect(radio).toBeEnabled();
        // The label is part of the radio button, not text beside it.
        await expect(page.locator('flt-semantics-host').getByText(name, { exact: true })).toHaveCount(0);
      }
    });

    test(`${slug}: a click chooses one option and clears the other`, async ({ page }) => {
      await open(page, slug);
      await byId(page, `f08-${slug}-standard`).click();
      // The count is waited for; the states are then read once.
      await expectCount(page, slug, 1);
      await expect(byId(page, `f08-${slug}-standard`)).toHaveAttribute('aria-checked', 'true');
      expect(await chosen(page, slug)).toBe('standard');
      await byId(page, `f08-${slug}-next-day`).click();
      await expectCount(page, slug, 2);
      await expect(byId(page, `f08-${slug}-next-day`)).toHaveAttribute('aria-checked', 'true');
      expect(await chosen(page, slug)).toBe('next-day');
    });
  }

  for (const slug of grouped) {
    test(`${slug}: Tab goes to the chosen option, and the arrow keys move the choice and wrap`, async ({ page }) => {
      await open(page, slug);
      // The Back button, then the group: focus lands on "Express".
      await page.keyboard.press('Tab');
      await page.keyboard.press('Tab');
      await page.waitForTimeout(200);
      const focused = (option) =>
        byId(page, `f08-${slug}-${option}`).evaluate((e) => e === document.activeElement);
      expect(await focused('express'), 'focus is on the chosen option').toBe(true);
      await page.keyboard.press('ArrowDown');
      await expectCount(page, slug, 1);
      await expect(byId(page, `f08-${slug}-next-day`)).toHaveAttribute('aria-checked', 'true');
      expect(await chosen(page, slug)).toBe('next-day');
      await page.waitForTimeout(200);
      expect(await focused('next-day'), 'focus follows the choice').toBe(true);
      await page.keyboard.press('ArrowDown');
      await expectCount(page, slug, 2);
      await expect(byId(page, `f08-${slug}-standard`)).toHaveAttribute('aria-checked', 'true');
      expect(await chosen(page, slug)).toBe('standard');
      await page.keyboard.press('ArrowUp');
      await expectCount(page, slug, 3);
      await expect(byId(page, `f08-${slug}-next-day`)).toHaveAttribute('aria-checked', 'true');
      expect(await chosen(page, slug)).toBe('next-day');
      // One more Tab leaves the group: no other option takes focus.
      await page.keyboard.press('Tab');
      await page.waitForTimeout(200);
      for (const option of Object.keys(options)) expect(await focused(option), option).toBe(false);
    });
  }
});

test.describe('the group and its question', () => {
  for (const [slug, question, count] of [
    ['good-group', 'Delivery speed', 3],
    ['good-cupertino', 'Delivery speed', 3],
    ['good-custom', 'Delivery speed', 3],
    ['good-context', 'Are you at home?', 2],
  ]) {
    test(`${slug}: a radio group named "${question}"`, async ({ page }) => {
      await open(page, slug);
      // The visible question is a Text inside the RadioGroup, which makes
      // it the name of the group itself.
      const radiogroup = page.getByRole('radiogroup');
      await expect(radiogroup).toHaveCount(1);
      await expect(radiogroup).toHaveAccessibleName(question);
      await expect(radiogroup.getByRole('radio')).toHaveCount(count);
      // The question is not a second element in the tree.
      await expect(page.locator('flt-semantics-host').getByText(question, { exact: true })).toHaveCount(0);
    });
  }

  test('good-context: each answer has a name that carries the question', async ({ page }) => {
    await open(page, 'good-context');
    await expect(byId(page, 'f08-good-context-yes')).toHaveAccessibleName('Yes, I am at home');
    await expect(byId(page, 'f08-good-context-no')).toHaveAccessibleName('No, I am not at home');
    await expect(byId(page, 'f08-good-context-no')).toHaveAttribute('aria-checked', 'true');
    await byId(page, 'f08-good-context-yes').click();
    await expect(byId(page, 'f08-good-context-yes')).toHaveAttribute('aria-checked', 'true');
    await expect(byId(page, 'f08-good-context-no')).toHaveAttribute('aria-checked', 'false');
  });
});

// Flutter's radio widgets give the options that are not chosen the hint
// "Not selected" on iOS and macOS only, where it stands in for a state iOS
// cannot expose (docs/flutter-limitations.md, FL-047). The web build
// decides by the system the browser runs on, so the hint is an
// aria-description in a browser on an Apple device and is absent anywhere
// else, such as the Linux machine CI uses.
test.describe('the "Not selected" description', () => {
  const onApple = (page) => page.evaluate(() => /Mac|iPhone|iPad/.test(navigator.platform));

  async function expectDescriptions(page, slug, chosenOption) {
    const apple = await onApple(page);
    for (const option of Object.keys(options)) {
      const radio = byId(page, `f08-${slug}-${option}`);
      if (apple && option !== chosenOption) {
        await expect(radio, option).toHaveAttribute('aria-description', 'Not selected');
      } else {
        await expect(radio, option).not.toHaveAttribute('aria-description', /.*/);
      }
    }
  }

  for (const slug of grouped) {
    test(`${slug}: on the options that are not chosen, on Apple systems only, and it follows the choice`, async ({ page }) => {
      await open(page, slug);
      await expectDescriptions(page, slug, 'express');
      await byId(page, `f08-${slug}-standard`).click();
      await expectCount(page, slug, 1);
      await expect(byId(page, `f08-${slug}-standard`)).toHaveAttribute('aria-checked', 'true');
      await expectDescriptions(page, slug, 'standard');
    });
  }

  test('bad-checked-only: no option has it on any system', async ({ page }) => {
    await open(page, 'bad-checked-only');
    await expect(page.locator('[aria-description]')).toHaveCount(0);
  });
});

test.describe('bad examples have their defect', () => {
  test('bad-unlabelled: three radio buttons with no names', async ({ page }) => {
    await open(page, 'bad-unlabelled');
    const radios = page.getByRole('radio');
    await expect(radios).toHaveCount(3);
    for (let i = 0; i < 3; i++) await expect(radios.nth(i)).toHaveAccessibleName('');
    await expect(page.getByRole('radio', { name: 'Standard' })).toHaveCount(0);
  });

  test('bad-group-unlabelled: the radio group has no name and nothing named is around it', async ({ page }) => {
    await open(page, 'bad-group-unlabelled');
    const radiogroup = page.getByRole('radiogroup');
    await expect(radiogroup).toHaveCount(1);
    await expect(radiogroup).toHaveAccessibleName('');
    await expect(page.getByRole('radiogroup', { name: 'Delivery speed' })).toHaveCount(0);
    // The question is text beside the group.
    await expect(page.locator('flt-semantics-host').getByText('Delivery speed', { exact: true })).toHaveCount(1);
  });

  test('bad-no-state: three buttons with no state, before and after one is chosen', async ({ page }) => {
    await open(page, 'bad-no-state');
    await expect(page.getByRole('radio')).toHaveCount(0);
    for (let pass = 0; pass < 2; pass++) {
      for (const [option, name] of Object.entries(options)) {
        const control = byId(page, `f08-bad-no-state-${option}`);
        await expect(control).toHaveRole('button');
        await expect(control).toHaveAccessibleName(name);
        await expect(control).not.toHaveAttribute('aria-checked', /.*/);
        await expect(control).not.toHaveAttribute('aria-pressed', /.*/);
        await expect(control).not.toHaveAttribute('aria-selected', /.*/);
        await expect(control).not.toHaveAttribute('aria-current', /.*/);
      }
      await byId(page, 'f08-bad-no-state-standard').click();
      await expectCount(page, 'bad-no-state', 1);
    }
  });

  test('bad-checkbox-role: three checkboxes, of which choosing one clears another', async ({ page }) => {
    await open(page, 'bad-checkbox-role');
    await expect(page.getByRole('radio')).toHaveCount(0);
    await expect(page.getByRole('checkbox')).toHaveCount(3);
    await expect(byId(page, 'f08-bad-checkbox-role-express')).toBeChecked();
    await byId(page, 'f08-bad-checkbox-role-standard').click();
    await expect(byId(page, 'f08-bad-checkbox-role-standard')).toBeChecked();
    await expect(byId(page, 'f08-bad-checkbox-role-express')).not.toBeChecked();
  });

  test('bad-checked-only: radio buttons with no radio group around them', async ({ page }) => {
    // The defect of this example is on iOS. On the web the buttons are
    // correct radio buttons; what is missing is the group.
    await open(page, 'bad-checked-only');
    await expect(page.getByRole('radio')).toHaveCount(3);
    await expect(page.getByRole('radiogroup')).toHaveCount(0);
  });
});
