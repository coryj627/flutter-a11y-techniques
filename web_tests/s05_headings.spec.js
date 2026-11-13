// L3 for S05 Headings on web: the heading structure the browser exposes.
// Spec: docs/specs/S05-headings.md. Runs against the release build in build/web.
import { test, expect } from '@playwright/test';

async function open(page, slug) {
  await page.goto('about:blank');
  await page.goto(`/#/t/S05/${slug}`);
  await page.getByRole('heading', { name: 'Example', level: 2 }).waitFor();
}

/** Every heading on the page, in document order, as "level text". */
const outline = (page) =>
  page.locator('h1,h2,h3,h4,h5,h6,[role=heading]').evaluateAll((elements) =>
    elements.map((e) => {
      // aria-level wins; then the element's own level; a role="heading" with
      // neither has the ARIA default level of 2.
      const fromTag = /^H[1-6]$/.test(e.tagName) ? e.tagName.slice(1) : '2';
      const level = e.getAttribute('aria-level') || fromTag;
      return `${level} ${e.textContent}`;
    }));

/** Levels may go up by at most one from one heading to the next. */
const skips = (headings) =>
  headings
    .map((h) => Number(h.split(' ')[0]))
    .filter((level, i, levels) => i > 0 && level - levels[i - 1] > 1);

test.describe('good examples', () => {
  test('good-levels: real heading elements in an outline with no skipped level', async ({ page }) => {
    await open(page, 'good-levels');
    const headings = await outline(page);
    expect(headings).toEqual([
      '1 Headings with levels',
      '2 Example',
      '3 Profile',
      '4 Contact details',
      '4 Email preferences',
      '3 Security',
    ]);
    expect(skips(headings)).toEqual([]);
    await expect(page.getByRole('heading', { name: 'Contact details', level: 4 })).toBeVisible();
    // Body text is not a heading.
    await expect(page.getByRole('heading', { name: /Choose which messages/ })).toHaveCount(0);
  });

  test('good-cupertino: the section header is a level 3 heading', async ({ page }) => {
    await open(page, 'good-cupertino');
    await expect(page.getByRole('heading', { name: 'Notifications', level: 3 })).toBeVisible();
    expect(skips(await outline(page))).toEqual([]);
  });

  test('every screen has exactly one level 1 heading, its title', async ({ page }) => {
    for (const [hash, title] of [
      ['/', 'Flutter A11Y Techniques'],
      ['/about', 'About'],
      ['/t/S05', 'Headings'],
      ['/t/S05/good-levels', 'Headings with levels'],
    ]) {
      await page.goto('about:blank');
      await page.goto(`/#${hash}`);
      await expect(page.getByRole('heading', { level: 1 })).toHaveText(title);
      await expect(page.getByRole('heading', { level: 1 })).toHaveCount(1);
    }
  });

  test('the technique screen outline has no skipped level', async ({ page }) => {
    await page.goto('about:blank');
    await page.goto('/#/t/S05');
    await expect(page.getByRole('heading', { name: 'Sources', level: 2 })).toBeAttached();
    expect(skips(await outline(page))).toEqual([]);
  });
});

// VAL-3: each bad example is asserted to have its named defect.
test.describe('bad examples have their defect', () => {
  test('bad-visual-only: the text is not a heading', async ({ page }) => {
    await open(page, 'bad-visual-only');
    await expect(page.getByText('Profile', { exact: true })).toBeVisible();
    await expect(page.getByRole('heading', { name: 'Profile' })).toHaveCount(0);
    expect(await outline(page)).toEqual(['1 Heading by appearance only', '2 Example']);
  });

  test('bad-fake-label: "heading" is in the text, and it is still not a heading', async ({ page }) => {
    await open(page, 'bad-fake-label');
    await expect(page.getByText('Profile, heading', { exact: true })).toBeAttached();
    await expect(page.getByRole('heading', { name: /Profile/ })).toHaveCount(0);
  });

  test('bad-skipped-level: level 5 follows level 3', async ({ page }) => {
    await open(page, 'bad-skipped-level');
    const headings = await outline(page);
    expect(headings.slice(2)).toEqual(['3 Profile', '5 Contact details']);
    expect(skips(headings)).toEqual([5]);
  });

  test('bad-header-only: header with no level is always level 2 (Flutter limitation)', async ({ page }) => {
    await open(page, 'bad-header-only');
    // FL-004. Written to fail if Flutter starts giving these another level.
    await expect(page.getByRole('heading', { name: 'Profile', level: 2 })).toBeVisible();
    // So content under the level 2 "Example" section sits beside it, not under it.
    expect((await outline(page)).slice(1)).toEqual(['2 Example', '2 Profile']);
  });

  test('bad-emphasis-heading: a sentence is exposed as a heading', async ({ page }) => {
    await open(page, 'bad-emphasis-heading');
    await expect(
      page.getByRole('heading', { name: 'Please check your address before you pay.', level: 4 }),
    ).toBeVisible();
  });

  test('bad-cupertino-section-header: not a heading (Flutter limitation)', async ({ page }) => {
    await open(page, 'bad-cupertino-section-header');
    await expect(page.getByText('Notifications', { exact: true })).toBeVisible();
    await expect(page.getByRole('heading', { name: 'Notifications' })).toHaveCount(0);
  });
});
