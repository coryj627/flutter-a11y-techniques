// L3 for S04 Functional images on web: what the browser's accessibility tree
// exposes. Spec: docs/specs/S04-functional-images.md. Runs against the
// release build in build/web.
import { test, expect } from '@playwright/test';
import { byId, tabTo, technique } from './support/techniques.js';

const { open, expectCount } = technique('S04', { countLabel: 'Activations', settle: 500 });

const good = {
  'good-image-button': { 's04-good-image-button-guide': 'Open trail guide' },
  'good-icon-label': { 's04-good-icon-label-search': 'Search' },
  'good-image-with-text': {
    's04-good-image-with-text-guide': 'Trail guide',
    's04-good-image-with-text-print': 'Print',
  },
  'good-cupertino': { 's04-good-cupertino-search': 'Search' },
  'good-custom': { 's04-good-custom-guide': 'Open trail guide' },
  'good-image-regions': {
    's04-good-image-regions-west': 'West trail',
    's04-good-image-regions-east': 'East trail',
  },
};

test.describe('good examples', () => {
  for (const [slug, buttons] of Object.entries(good)) {
    test(`${slug}: a named button, no image, and click`, async ({ page }) => {
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
      // Neither the button nor anything in it is an image.
      await expect(page.getByRole('img')).toHaveCount(0);
    });

    test(`${slug}: Tab reaches each button in order; Enter and Space activate`, async ({ page }) => {
      await open(page, slug);
      let n = 0;
      for (const id of Object.keys(buttons)) {
        expect(await tabTo(page, byId(page, id)), `Tab reaches ${id}`).toBe(true);
        await page.keyboard.press('Enter');
        await expectCount(page, slug, ++n);
        await page.keyboard.press('Space');
        await expectCount(page, slug, ++n);
      }
    });
  }
});

test.describe('bad examples have their defect', () => {
  test('bad-no-name: a button with no name', async ({ page }) => {
    await open(page, 'bad-no-name');
    const button = byId(page, 's04-bad-no-name-guide');
    await expect(button).toHaveRole('button');
    await expect(button).toHaveAccessibleName('');
    // On web the picture's image flag is not exposed on the button.
    await expect(page.getByRole('img')).toHaveCount(0);
  });

  test('bad-label-on-image: the name is on an image inside the button', async ({ page }) => {
    await open(page, 'bad-label-on-image');
    // The second button on the screen; the first is Back.
    const button = page.getByRole('button', { name: 'Open trail guide', exact: true });
    await expect(button).toHaveCount(1);
    // The button has no label of its own. Chromium computes its name from
    // the image inside it, so on web the defect is in the structure only:
    // an image element nested in a button. Android and iOS expose a button
    // with no name (see the device tests).
    await expect(button).not.toHaveAttribute('aria-label');
    expect(await button.evaluate((e) => [...e.childNodes].filter((n) => n.nodeType === 3).length)).toBe(0);
    const image = button.getByRole('img', { name: 'Open trail guide', exact: true });
    await expect(image).toHaveCount(1);
    await expect(image).toHaveAttribute('aria-label', 'Open trail guide');
    await button.click();
    await expectCount(page, 'bad-label-on-image', 1);
  });

  test('bad-tap-gesture: an image, not a button, and no keyboard access', async ({ page }) => {
    await open(page, 'bad-tap-gesture');
    const image = page.getByRole('img', { name: 'Open trail guide', exact: true });
    await expect(image).toHaveCount(1);
    await expect(page.getByRole('button', { name: 'Open trail guide' })).toHaveCount(0);
    // Neither the image nor the element around it takes focus.
    const wrapper = image.locator('xpath=..');
    await expect(wrapper).not.toHaveAttribute('role');
    await expect(wrapper).not.toHaveAttribute('tabindex');
    await expect(image).not.toHaveAttribute('tabindex');
    expect(await tabTo(page, image), 'Tab skips the image').toBe(false);
    expect(await tabTo(page, wrapper), 'Tab skips its wrapper').toBe(false);
    await expectCount(page, 'bad-tap-gesture', 0);
    // It still works with a pointer, which is what hides the defect.
    await page.getByRole('img').click();
    await expectCount(page, 'bad-tap-gesture', 1);
  });

  test('bad-describes-picture: the name describes the icon', async ({ page }) => {
    await open(page, 'bad-describes-picture');
    const button = byId(page, 's04-bad-describes-picture-search');
    await expect(button).toHaveRole('button');
    await expect(button).toHaveAccessibleName('Magnifying glass');
  });

  test('bad-image-not-excluded: on web the button is not an image', async ({ page }) => {
    await open(page, 'bad-image-not-excluded');
    const button = byId(page, 's04-bad-image-not-excluded-guide');
    // The defect cannot be seen on web: Flutter's web engine gives the
    // merged node the button role alone. Android and iOS expose it as an
    // image as well (see the device tests). If this changes, the example's
    // doc needs to say so.
    await expect(button).toHaveRole('button');
    await expect(button).toHaveAccessibleName('Trail guide');
    await expect(page.getByRole('img')).toHaveCount(0);
  });

  test('bad-redundant-label: the name has the icon label and the text', async ({ page }) => {
    await open(page, 'bad-redundant-label');
    const button = byId(page, 's04-bad-redundant-label-print');
    await expect(button).toHaveRole('button');
    await expect(button).toHaveAccessibleName('Printer Print');
    await expect(page.getByText('Print', { exact: true })).toHaveCount(0);
  });
});
