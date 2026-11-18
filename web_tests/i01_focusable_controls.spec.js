// L3 for I01 Focusable and clickable controls on web: what the browser's
// accessibility tree exposes, and what the keyboard and the pointer do.
// Spec: docs/specs/I01-focusable-controls.md. Runs against the release
// build in build/web.
import { test, expect } from '@playwright/test';
import { byId, tabTo, technique } from './support/techniques.js';

const { open, count, expectCount } = technique('I01', { countLabel: 'Activations' });

const trail = 'Ridge trail';
const control = (page, slug) => byId(page, `i01-${slug}-trail`);
const back = (page) => page.getByRole('button', { name: 'Back' });
const isActive = (locator) => locator.evaluate((e) => e === document.activeElement);

const good = ['good-material', 'good-cupertino', 'good-custom'];
const all = [...good, 'bad-inkwell-no-role', 'bad-no-focus', 'bad-no-key-action', 'bad-tap-down'];
// Tab reaches these, and Enter and Space activate them.
const keyboard = [...good, 'bad-inkwell-no-role', 'bad-tap-down'];
// These act when the pointer is let go, not when it goes down.
const actOnRelease = [...good, 'bad-inkwell-no-role', 'bad-no-focus', 'bad-no-key-action'];

/** Presses the control at its centre and waits `holdMs` with the button down. */
async function press(page, slug, holdMs) {
  const box = await control(page, slug).boundingBox();
  await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
  await page.mouse.down();
  await page.waitForTimeout(holdMs);
  return box;
}

test.describe('every example', () => {
  for (const slug of all) {
    test(`${slug}: a button named "${trail}"`, async ({ page }) => {
      await open(page, slug);
      const element = control(page, slug);
      // bad-inkwell-no-role is a button here too: on the web any node with a
      // tap action is a button (FL-006). Its defect is on Android and iOS.
      await expect(element).toHaveRole('button');
      await expect(element).toHaveAccessibleName(trail);
      await expect(page.getByRole('button', { name: trail, exact: true })).toHaveCount(1);
    });

    test(`${slug}: a click activates it once`, async ({ page }) => {
      await open(page, slug);
      await control(page, slug).click();
      await expectCount(page, slug, 1);
    });

    test(`${slug}: a click event on the element, as a screen reader sends, activates it once`, async ({ page }) => {
      await open(page, slug);
      await control(page, slug).dispatchEvent('click');
      await expectCount(page, slug, 1);
    });
  }
});

test.describe('keyboard', () => {
  for (const slug of keyboard) {
    test(`${slug}: Tab reaches it, and Enter and Space each activate it once`, async ({ page }) => {
      await open(page, slug);
      const element = control(page, slug);
      await expect(element).toHaveAttribute('tabindex', '0');
      expect(await tabTo(page, element), 'Tab reaches the control').toBe(true);
      await page.keyboard.press('Enter');
      await expectCount(page, slug, 1);
      expect(await isActive(element), 'focus stays after Enter').toBe(true);
      await page.keyboard.press('Space');
      await expectCount(page, slug, 2);
      expect(await isActive(element), 'focus stays after Space').toBe(true);
    });
  }

  test('bad-no-focus: no tabindex, and Tab never reaches it', async ({ page }) => {
    await open(page, 'bad-no-focus');
    const element = control(page, 'bad-no-focus');
    await expect(element).not.toHaveAttribute('tabindex', /.*/);
    // The keys arrive: the first Tab puts focus on Back, as on every
    // example screen. Enter and Space are not pressed while it is there.
    expect(await tabTo(page, back(page), 1), 'the first Tab reaches Back').toBe(true);
    // The second Tab is where a control that can take focus gets it (the
    // keyboard tests above); here focus leaves Back and is not on the card.
    // Then six more never reach it.
    await page.keyboard.press('Tab');
    await page.waitForTimeout(100);
    expect(await isActive(back(page)), 'the second Tab left Back').toBe(false);
    expect(await isActive(element), 'the second Tab did not reach the card').toBe(false);
    expect(await tabTo(page, element, 6), 'Tab never reaches the control').toBe(false);
    await expectCount(page, 'bad-no-focus', 0);
  });

  for (const key of ['Enter', 'Space']) {
    test(`bad-no-key-action: Tab reaches it, and ${key} does nothing`, async ({ page }) => {
      await open(page, 'bad-no-key-action');
      const element = control(page, 'bad-no-key-action');
      await expect(element).toHaveAttribute('tabindex', '0');
      expect(await tabTo(page, element), 'Tab reaches the control').toBe(true);
      await page.keyboard.press(key);
      await page.waitForTimeout(500);
      await expectCount(page, 'bad-no-key-action', 0);
      expect(await isActive(element), `focus is still on the control after ${key}`).toBe(true);
      // The control, in the same page: Shift+Tab back to Back, and the same
      // key there leaves the screen, so the key was arriving.
      await page.keyboard.press('Shift+Tab');
      await page.waitForTimeout(100);
      expect(await isActive(back(page)), 'Shift+Tab reaches Back').toBe(true);
      await page.keyboard.press(key);
      await expect(count(page, 'bad-no-key-action'), `${key} on Back leaves the screen`).toHaveCount(0);
    });
  }
});

test.describe('pointer', () => {
  for (const slug of actOnRelease) {
    test(`${slug}: nothing happens while it is held, or when the pointer leaves it before it is let go`, async ({ page }) => {
      await open(page, slug);
      const box = await press(page, slug, 600);
      await expectCount(page, slug, 0);
      await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2 + 300, { steps: 10 });
      await page.mouse.up();
      await page.waitForTimeout(500);
      await expectCount(page, slug, 0);
    });
  }

  test('bad-tap-down: it acts while it is held, and moving off before letting go does not take it back', async ({ page }) => {
    await open(page, 'bad-tap-down');
    // On the web the engine holds a press on a tappable element back for a
    // moment before passing it on (seen in the probe: nothing at 100 ms,
    // the activation by 300 ms), so the press is held longer than that.
    const box = await press(page, 'bad-tap-down', 600);
    await expectCount(page, 'bad-tap-down', 1);
    await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2 + 300, { steps: 10 });
    await page.mouse.up();
    await page.waitForTimeout(500);
    await expectCount(page, 'bad-tap-down', 1);
  });
});
