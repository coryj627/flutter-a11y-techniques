// L3 for S03 Decorative images on web: what the browser's accessibility tree
// exposes. Spec: docs/specs/S03-decorative-images.md. Runs against the
// release build in build/web. Images have no controls to identify, so they
// are found by role and name.
import { test, expect } from '@playwright/test';

async function open(page, slug) {
  await page.goto('about:blank');
  await page.goto(`/#/t/S03/${slug}`);
  await page.getByRole('heading', { name: 'Example', level: 2 }).waitFor();
  // The photo is decoded after the first frame.
  await page.waitForTimeout(500);
}

const images = (page) => page.getByRole('img');
const text = (page, value) => page.getByText(value, { exact: true });

async function expectWelcomeText(page) {
  await expect(text(page, 'Welcome back, Ana.')).toHaveCount(1);
  await expect(text(page, 'You have 2 new messages.')).toHaveCount(1);
}

test.describe('good examples', () => {
  for (const slug of ['good-image-excluded', 'good-background-image']) {
    test(`${slug}: the banner is not exposed`, async ({ page }) => {
      await open(page, slug);
      await expectWelcomeText(page);
      await expect(images(page)).toHaveCount(0);
    });
  }

  test('good-icon-no-label: only the words are exposed', async ({ page }) => {
    await open(page, 'good-icon-no-label');
    await expect(text(page, 'Shipping')).toHaveCount(1);
    await expect(text(page, 'Returns')).toHaveCount(1);
    await expect(text(page, 'Delivery takes 2 to 4 days.')).toHaveCount(1);
    await expect(images(page)).toHaveCount(0);
  });

  test('good-exclude-semantics: the initials are not exposed', async ({ page }) => {
    await open(page, 'good-exclude-semantics');
    await expect(text(page, 'Ana Kovac')).toHaveCount(1);
    await expect(page.getByText('AK')).toHaveCount(0);
    await expect(images(page)).toHaveCount(0);
  });

  test('good-merged-row: the row is text, not an image', async ({ page }) => {
    await open(page, 'good-merged-row');
    await expect(page.getByText(/^Trail guide\s+12 routes$/)).toHaveCount(1);
    await expect(images(page)).toHaveCount(0);
  });
});

test.describe('bad examples', () => {
  for (const slug of ['bad-not-excluded', 'bad-empty-label']) {
    test(`${slug}: the banner is an image with no name`, async ({ page }) => {
      await open(page, slug);
      await expectWelcomeText(page);
      await expect(images(page)).toHaveCount(1);
      await expect(images(page)).toHaveAccessibleName('');
      await expect(images(page)).not.toHaveAttribute('aria-label');
      await expect(images(page)).not.toHaveAttribute('aria-hidden');
    });
  }

  test('bad-redundant-label: every word is exposed twice', async ({ page }) => {
    await open(page, 'bad-redundant-label');
    await expect(text(page, 'Shipping')).toHaveCount(2);
    await expect(text(page, 'Returns')).toHaveCount(2);
  });

  test('bad-merged-image: the row of text is an image', async ({ page }) => {
    await open(page, 'bad-merged-image');
    await expect(images(page)).toHaveCount(1);
    await expect(images(page)).toHaveAccessibleName(/^Trail guide\s+12 routes$/);
  });
});
