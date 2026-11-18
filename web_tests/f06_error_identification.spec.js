// L3 for F06 Error identification and announcement on web: what the browser
// exposes for a field in error, what reaches Flutter's announcement
// elements, and where focus goes. Spec: docs/specs/F06-error-identification.md.
// Runs against the release build in build/web.
import { test, expect } from '@playwright/test';
import { byId, technique } from './support/techniques.js';

const NAME_ERROR = 'Enter your name.';
const EMAIL_ERROR = 'Enter an email address with an @, like name@example.com.';

// Waits for the example's count, then a moment more: Flutter attaches its
// text editing a moment after the tree appears.
const { open: openExample, expectCount } = technique('F06', { countLabel: 'Sent', settle: 600 });

/**
 * Opens an example and records everything Flutter writes to its two
 * announcement elements. Flutter empties them again after 300 ms, so reading
 * them once is a race (docs/flutter-limitations.md, FL-012).
 */
async function open(page, slug) {
  await openExample(page, slug);
  await page.evaluate(() => {
    window.announced = [];
    for (const politeness of ['polite', 'assertive']) {
      const element = document.querySelector(`flt-announcement-${politeness}`);
      new MutationObserver(() => {
        const text = element.textContent.replace(/ /g, ' ').trim();
        if (text) window.announced.push(`${politeness}: ${text}`);
      }).observe(element, { childList: true, characterData: true, subtree: true });
    }
  });
}

const announced = (page) => page.evaluate(() => window.announced);

/** The <input> inside the node carrying a test identifier. */
const field = (page, id) => byId(page, id).locator('input');

const isFocused = (locator) => locator.evaluate((e) => e === document.activeElement);

/**
 * Sends the form with the keyboard, as a screen reader user would: focus on
 * Send, then Enter, or Space for a CupertinoButton, which Enter does not
 * activate on the web (FL-002).
 */
async function send(page, slug) {
  const button = byId(page, `f06-${slug}-send`);
  await button.focus();
  await page.waitForTimeout(150);
  await page.keyboard.press(slug === 'good-cupertino' ? 'Space' : 'Enter');
}

/** Waits for the announcements to settle and returns them. */
async function settledAnnouncements(page) {
  await page.waitForTimeout(1500);
  return announced(page);
}

async function type(page, locator, text) {
  await locator.click();
  await page.waitForTimeout(250);
  await page.keyboard.type(text, { delay: 30 });
  await expect(locator).toHaveValue(text);
}

const good = {
  'good-form': [['f06-good-form-name', 'Name', NAME_ERROR], ['f06-good-form-email', 'Email', EMAIL_ERROR]],
  'good-cupertino': [['f06-good-cupertino-name', 'Name', NAME_ERROR], ['f06-good-cupertino-email', 'Email', EMAIL_ERROR]],
};

test.describe('good examples', () => {
  for (const [slug, fields] of Object.entries(good)) {
    test(`${slug}: every field in error is invalid, named by its label, and described by its error`, async ({ page }) => {
      await open(page, slug);
      for (const [id, name] of fields) {
        const box = field(page, id);
        await expect(box).toHaveRole('textbox');
        await expect(box).toHaveAccessibleName(name);
        await expect(box).toHaveAttribute('aria-invalid', 'false');
        await expect(box).not.toHaveAttribute('aria-description');
      }
      await send(page, slug);
      for (const [id, name, error] of fields) {
        const box = field(page, id);
        await expect(box).toHaveAttribute('aria-invalid', 'true');
        await expect(box).toHaveAccessibleName(name);
        await expect(box).toHaveAccessibleDescription(error);
        // The visible message is on the page once, as text.
        await expect(page.getByText(error, { exact: true })).toHaveCount(1);
      }
      // The first error, and only the first, is announced, assertively.
      expect(await settledAnnouncements(page)).toEqual([`assertive: ${NAME_ERROR}`]);
      // Focus is on the first field in error.
      expect(await isFocused(field(page, fields[0][0]))).toBe(true);
      await expectCount(page, slug, 0);
    });

    test(`${slug}: the next error is announced and focused, and the form is sent once right`, async ({ page }) => {
      await open(page, slug);
      const [[name], [email]] = fields;
      await type(page, field(page, name), 'Ana');
      await type(page, field(page, email), 'abc');
      await send(page, slug);
      await expect(field(page, name)).toHaveAttribute('aria-invalid', 'false');
      await expect(field(page, email)).toHaveAttribute('aria-invalid', 'true');
      expect(await settledAnnouncements(page)).toEqual([`assertive: ${EMAIL_ERROR}`]);
      expect(await isFocused(field(page, email))).toBe(true);
      // Focus moved by the app selects the field's text. Flutter attaches
      // its text editing a moment later; then the right arrow puts the
      // caret after "abc".
      await page.waitForTimeout(500);
      await page.keyboard.press('ArrowRight');
      await page.waitForTimeout(150);
      await page.keyboard.type('@example.com', { delay: 30 });
      await expect(field(page, email)).toHaveValue('abc@example.com');
      await send(page, slug);
      await expectCount(page, slug, 1);
      await expect(field(page, email)).toHaveAttribute('aria-invalid', 'false');
      await expect(field(page, email)).not.toHaveAttribute('aria-description');
      expect(await settledAnnouncements(page)).toEqual([`assertive: ${EMAIL_ERROR}`]);
    });
  }

  test('good-form: Tab goes from Name to Email to Send', async ({ page }) => {
    await open(page, 'good-form');
    await field(page, 'f06-good-form-name').click();
    await page.keyboard.press('Tab');
    await page.waitForTimeout(150);
    expect(await isFocused(field(page, 'f06-good-form-email'))).toBe(true);
    await page.keyboard.press('Tab');
    await page.waitForTimeout(150);
    expect(await isFocused(byId(page, 'f06-good-form-send'))).toBe(true);
  });
});

// VAL-3: each bad example is asserted to have its named defect.
test.describe('bad examples have their defect', () => {
  test('bad-color-only: the field is invalid, and no words say why', async ({ page }) => {
    await open(page, 'bad-color-only');
    const box = field(page, 'f06-bad-color-only-email');
    const textBefore = await page.locator('flt-semantics-host').innerText();
    await send(page, 'bad-color-only');
    await expect(box).toHaveAttribute('aria-invalid', 'true');
    await expect(box).toHaveAccessibleName('Email');
    await expect(box).toHaveAccessibleDescription('');
    expect(await settledAnnouncements(page)).toEqual([]);
    expect(await page.locator('flt-semantics-host').innerText()).toBe(textBefore);
    expect(await isFocused(box)).toBe(true);
  });

  test('bad-vague-message: the error says "Invalid." and nothing more', async ({ page }) => {
    await open(page, 'bad-vague-message');
    const box = field(page, 'f06-bad-vague-message-email');
    await send(page, 'bad-vague-message');
    await expect(box).toHaveAttribute('aria-invalid', 'true');
    await expect(box).toHaveAccessibleDescription('Invalid.');
    expect(await settledAnnouncements(page)).toEqual(['assertive: Invalid.']);
  });

  test('bad-not-announced: the error appears and nothing is announced; focus stays on Send', async ({ page }) => {
    await open(page, 'bad-not-announced');
    const box = field(page, 'f06-bad-not-announced-email');
    await send(page, 'bad-not-announced');
    await expect(box).toHaveAccessibleDescription(EMAIL_ERROR);
    await expect(box).toHaveAttribute('aria-invalid', 'true');
    expect(await settledAnnouncements(page)).toEqual([]);
    expect(await isFocused(byId(page, 'f06-bad-not-announced-send'))).toBe(true);
  });

  test('bad-merged-error: the error is in the field\'s name as well as its description', async ({ page }) => {
    await open(page, 'bad-merged-error');
    const box = field(page, 'f06-bad-merged-error-email');
    await expect(box).toHaveAccessibleName('Email');
    await send(page, 'bad-merged-error');
    await expect(box).toHaveAccessibleName(`Email ${EMAIL_ERROR}`);
    await expect(box).toHaveAccessibleDescription(EMAIL_ERROR);
    await expect(page.getByText(EMAIL_ERROR, { exact: true })).toHaveCount(0);
  });
});
