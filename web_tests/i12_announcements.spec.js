// L3 for I12 Announcements and live regions on web: what reaches the
// browser's live regions. Spec: docs/specs/I12-announcements.md.
// Runs against the release build in build/web.
import { test, expect } from '@playwright/test';

const byId = (page, id) => page.locator(`[flt-semantics-identifier="${id}"]`);

/**
 * Opens an example and starts recording everything Flutter writes to its two
 * announcement elements. Flutter empties them again after 300 ms, so reading
 * them once is a race (docs/flutter-limitations.md, FL-012).
 */
async function open(page, slug) {
  await page.goto('about:blank');
  await page.goto(`/#/t/I12/${slug}`);
  await byId(page, `i12-${slug}-action`).waitFor();
  // Let the announcements made as the screen opens come and go first.
  await page.waitForTimeout(900);
  await page.evaluate(() => {
    window.announced = [];
    for (const politeness of ['polite', 'assertive']) {
      const element = document.querySelector(`flt-announcement-${politeness}`);
      new MutationObserver(() => {
        const text = element.textContent.replace(/ /g, ' ').trim();
        if (text) window.announced.push(`${politeness}: ${text}`);
      }).observe(element, { childList: true, characterData: true, subtree: true });
    }
  });
}

const announced = (page) => page.evaluate(() => window.announced);

const press = (page, slug) => byId(page, `i12-${slug}-action`).click();

test.describe('good examples', () => {
  test('good-live-region: a change is announced politely, once', async ({ page }) => {
    await open(page, 'good-live-region');
    await expect(byId(page, 'i12-good-live-region-status')).toHaveText('Cart is empty');
    await press(page, 'good-live-region');
    await expect(byId(page, 'i12-good-live-region-status')).toHaveText('1 item in cart');
    await expect.poll(() => announced(page)).toEqual(['polite: 1 item in cart']);
    // Focus stays on the button.
    expect(await byId(page, 'i12-good-live-region-action').evaluate((e) => e === document.activeElement)).toBe(true);
  });

  test('good-announce: announced from code once, and not also by a live region', async ({ page }) => {
    await open(page, 'good-announce');
    await press(page, 'good-announce');
    await expect(byId(page, 'i12-good-announce-status')).toHaveText('Link copied');
    await expect.poll(() => announced(page)).toEqual(['polite: Link copied']);
    await page.waitForTimeout(1200);
    expect(await announced(page)).toEqual(['polite: Link copied']);
  });

  test('good-snackbar: the SnackBar message is announced', async ({ page }) => {
    await open(page, 'good-snackbar');
    await press(page, 'good-snackbar');
    await expect.poll(() => announced(page)).toContain('polite: Message archived');
  });
});

// VAL-3: each bad example is asserted to have its named defect.
test.describe('bad examples have their defect', () => {
  test('bad-silent-update: the text changes and nothing is announced', async ({ page }) => {
    await open(page, 'bad-silent-update');
    await press(page, 'bad-silent-update');
    const status = byId(page, 'i12-bad-silent-update-status');
    await expect(status).toHaveText('1 item in cart');
    await page.waitForTimeout(1500);
    expect(await announced(page)).toEqual([]);
    await expect(status).not.toHaveAttribute('role');
    await expect(status).not.toHaveAttribute('aria-live');
  });

  test('bad-chatty-live-region: a new announcement every second', async ({ page }) => {
    await open(page, 'bad-chatty-live-region');
    await press(page, 'bad-chatty-live-region');
    await page.waitForTimeout(4500);
    const heard = await announced(page);
    expect(heard.length).toBeGreaterThanOrEqual(4);
    expect(new Set(heard).size).toBe(heard.length);
    expect(heard[0]).toMatch(/^polite: Uploading: \d+ seconds$/);
  });

  // On web these two do work: the browser treats role="status" and
  // role="alert" as live regions. The defect is on Android, where the same
  // widget is silent (FL-017). These tests pin down what web exposes.
  for (const [slug, role, message] of [
    ['bad-status-role-only', 'status', '1 item in cart'],
    ['bad-alert-role-only', 'alert', 'Could not save. Attempt 1 failed.'],
  ]) {
    test(`${slug}: exposed with role="${role}", outside Flutter's own announcer`, async ({ page }) => {
      await open(page, slug);
      await press(page, slug);
      const status = byId(page, `i12-${slug}-status`);
      await expect(status).toHaveRole(role);
      // The message is carried as the node's name.
      await expect(status).toHaveAccessibleName(message);
      await page.waitForTimeout(1200);
      expect(await announced(page)).toEqual([]);
    });
  }
});
