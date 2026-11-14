// L3 for S02 Informative images on web: what the browser's accessibility tree
// exposes. Spec: docs/specs/S02-informative-images.md. Runs against the
// release build in build/web. Images have no controls to identify, so they
// are found by role and name.
import { test, expect } from '@playwright/test';

async function open(page, slug) {
  await page.goto('about:blank');
  await page.goto(`/#/t/S02/${slug}`);
  await page.getByRole('heading', { name: 'Example', level: 2 }).waitFor();
  // The photo is decoded after the first frame.
  await page.waitForTimeout(500);
}

const images = (page) => page.getByRole('img');

test.describe('good examples', () => {
  test('good-image-label: an image with a name', async ({ page }) => {
    await open(page, 'good-image-label');
    await expect(images(page)).toHaveCount(1);
    await expect(images(page)).toHaveAccessibleName('Sunrise over green hills');
    await expect(page.getByText('Taken from the east ridge trail.', { exact: true })).toHaveCount(1);
  });

  test('good-icon-label: each row reads its status and its order as one element', async ({ page }) => {
    await open(page, 'good-icon-label');
    await expect(page.getByText(/^Delivered\s+Order 1042$/)).toHaveCount(1);
    await expect(page.getByText(/^Delayed\s+Order 1043$/)).toHaveCount(1);
    // The status is not a second element, and the icon is not an unnamed image.
    await expect(page.getByText('Delivered', { exact: true })).toHaveCount(0);
    await expect(page.getByText('Order 1042', { exact: true })).toHaveCount(0);
    await expect(images(page)).toHaveCount(0);
  });

  test('good-group-description: one description, parts not exposed', async ({ page }) => {
    await open(page, 'good-group-description');
    await expect(page.getByText('Sunrise at 6:35 am', { exact: true })).toHaveCount(1);
    await expect(page.getByText('6:35 am', { exact: true })).toHaveCount(0);
    await expect(images(page)).toHaveCount(0);
  });

  test('good-chart: an image with a short name, and its data in text', async ({ page }) => {
    await open(page, 'good-chart');
    await expect(images(page)).toHaveCount(1);
    await expect(images(page)).toHaveAccessibleName('Bar chart: orders rose every quarter of 2025');
    await expect(page.getByText('Orders in 2025: Q1 20, Q2 35, Q3 50, Q4 80.', { exact: true })).toHaveCount(1);
  });
});

test.describe('bad examples', () => {
  test('bad-no-label: an image with no name', async ({ page }) => {
    await open(page, 'bad-no-label');
    await expect(images(page)).toHaveCount(1);
    await expect(images(page)).toHaveAccessibleName('');
    await expect(images(page)).not.toHaveAttribute('aria-label');
    await expect(page.getByText(/sunrise/i)).toHaveCount(0);
  });

  test('bad-icon-no-label: the rows are order numbers only', async ({ page }) => {
    await open(page, 'bad-icon-no-label');
    await expect(page.getByText('Order 1042', { exact: true })).toHaveCount(1);
    await expect(page.getByText('Order 1043', { exact: true })).toHaveCount(1);
    await expect(page.getByText(/Delivered|Delayed/)).toHaveCount(0);
    await expect(images(page)).toHaveCount(0);
  });

  test('bad-role-in-label: the name starts with the role', async ({ page }) => {
    await open(page, 'bad-role-in-label');
    await expect(images(page)).toHaveCount(1);
    await expect(images(page)).toHaveAccessibleName(/^Image of /);
  });

  test('bad-filename-label: the name is a file name', async ({ page }) => {
    await open(page, 'bad-filename-label');
    await expect(images(page)).toHaveCount(1);
    await expect(images(page)).toHaveAccessibleName('IMG_2041.png');
  });
});
