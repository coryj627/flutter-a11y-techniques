// L3 for F03 Keyboard types on web: what the browser is told about each
// field. Spec: docs/specs/F03-keyboard-types.md. Runs against the release
// build in build/web.
//
// A browser picks its on-screen keyboard from the `<input>`'s `type` and
// `inputmode`, its Enter key from `enterkeyhint`, and what it may fill in
// from `autocomplete`. Those attributes are what is checked here, before
// the field is focused, while it is being edited, and after it is left.
// Flutter writes `inputmode` and `enterkeyhint` only when it believes the
// browser runs on Android or iOS (read in the engine source,
// `configureInputMode` and `configureInputAction`), so a second group runs
// with an Android phone's user agent.
import { test, expect } from '@playwright/test';
import { byId, technique, tabTo } from './support/techniques.js';

const { open, expectCount } = technique('F03', { countLabel: 'Changes', settle: 600 });

const input = (page, id) => byId(page, id).locator('input');

/** The attributes that choose a keyboard and autofill, as the page has them. */
const ATTRS = ['type', 'inputmode', 'autocomplete', 'enterkeyhint', 'name'];
async function attrs(locator) {
  return locator.evaluate((el, names) => Object.fromEntries(
    names.filter((n) => el.hasAttribute(n)).map((n) => [n, el.getAttribute(n)])), ATTRS);
}

/** Clicks into the field, then leaves it for the Back button. */
async function edit(page, locator) {
  await locator.click();
  await page.waitForTimeout(300);
  await expect(locator).toBeFocused();
}
async function leave(page) {
  await page.getByRole('button', { name: 'Back' }).focus();
  await page.waitForTimeout(300);
}

// slug -> fields: id, name, and the attributes before, while, and after
// editing, on a desktop browser. A missing attribute is left out.
// FL-161: an autofill hint reaches `autocomplete` only on an obscured
// field, and only once it has been edited; every other single-line field
// has "off", except one with the email keyboard type, which has "email".
// Written to fail when the hints reach the page.
const OFF = { type: 'text', autocomplete: 'off' };
const EMAIL = { type: 'text', inputmode: 'email', autocomplete: 'email' };
const TEL = { type: 'tel', autocomplete: 'off' };
const FIELDS = {
  'good-contact': [
    { id: 'f03-good-contact-name', name: 'Name', before: OFF, editing: { ...OFF, name: 'name' } },
    { id: 'f03-good-contact-email', name: 'Email', before: EMAIL, editing: { ...EMAIL, name: 'email' } },
    { id: 'f03-good-contact-phone', name: 'Phone', before: TEL, editing: { ...TEL, name: 'tel' } },
  ],
  'good-amount': [
    { id: 'f03-good-amount-amount', name: 'Amount', before: OFF, editing: OFF },
  ],
  'good-cupertino': [
    { id: 'f03-good-cupertino-email', name: 'Email', before: EMAIL, editing: { ...EMAIL, name: 'email' } },
    { id: 'f03-good-cupertino-phone', name: 'Phone', before: TEL, editing: { ...TEL, name: 'tel' } },
  ],
  'good-sign-in': [
    { id: 'f03-good-sign-in-username', name: 'Username', before: OFF, editing: { ...OFF, name: 'username' } },
    // A password is a password input, and keeps its hint once edited.
    { id: 'f03-good-sign-in-password', name: 'Password', before: { type: 'password', autocomplete: 'off' },
      editing: { type: 'password', autocomplete: 'current-password', name: 'current-password' } },
  ],
  // Bad examples: the attributes show the defect where this layer can.
  // A number keyboard is not visible on a desktop browser (see the mobile
  // group below); the name hint is lost as on every field (FL-161).
  'bad-number-for-name': [
    { id: 'f03-bad-number-for-name-name', name: 'Name', before: OFF, editing: { ...OFF, name: 'name' } },
  ],
  // No email keyboard type: no email input mode, and so no autocomplete
  // either; the email hint is lost (FL-161).
  'bad-default-keyboard': [
    { id: 'f03-bad-default-keyboard-email', name: 'Email', before: OFF, editing: { ...OFF, name: 'email' } },
  ],
  // No hint: not even the name attribute while editing.
  'bad-no-purpose': [
    { id: 'f03-bad-no-purpose-name', name: 'Name', before: OFF, editing: OFF },
  ],
  // The defect is Android's (FL-160); the page is as good-contact's email.
  'bad-email-no-suggestions': [
    { id: 'f03-bad-email-no-suggestions-email', name: 'Email', before: EMAIL, editing: { ...EMAIL, name: 'email' } },
  ],
};

test.describe('every field', () => {
  for (const [slug, fields] of Object.entries(FIELDS)) {
    test(`${slug}: a named text box with its keyboard and purpose attributes`, async ({ page }) => {
      await open(page, slug);
      for (const field of fields) {
        const box = input(page, field.id);
        await expect(box).toHaveRole('textbox');
        await expect(box).toHaveAccessibleName(field.name);
        expect(await attrs(box), `${field.id} before editing`).toEqual(field.before);
        await edit(page, box);
        expect(await attrs(box), `${field.id} while editing`).toEqual(field.editing);
        await page.keyboard.type('12', { delay: 40 });
        expect(await attrs(box), `${field.id} after typing`).toEqual(field.editing);
        await leave(page);
        expect(await attrs(box), `${field.id} after leaving`).toEqual(field.editing);
      }
      await expectCount(page, slug, 2 * fields.length);
    });

    test(`${slug}: Tab reaches every field in order`, async ({ page }) => {
      await open(page, slug);
      for (const field of fields) {
        expect(await tabTo(page, input(page, field.id)), field.id).toBe(true);
      }
    });
  }

  test('good-sign-in: what is typed into the password is held by a password input', async ({ page }) => {
    await open(page, 'good-sign-in');
    const box = input(page, 'f03-good-sign-in-password');
    await edit(page, box);
    await page.keyboard.type('abc', { delay: 40 });
    await expectCount(page, 'good-sign-in', 3);
    // The text is in a password input, which the browser masks and does
    // not expose as text; it is in no other element of the page.
    await expect(box).toHaveAttribute('type', 'password');
    await expect(box).toHaveValue('abc');
    await expect(page.getByText('abc')).toHaveCount(0);
    await expect(page.locator('input:not([type="password"])')).not.toHaveValue('abc');
  });

  for (const [slug, first, second] of [
    ['good-contact', 'f03-good-contact-name', 'f03-good-contact-email'],
    ['good-sign-in', 'f03-good-sign-in-username', 'f03-good-sign-in-password'],
  ]) {
    test(`${slug}: Enter on ${first}, whose action is "next", moves to ${second}`, async ({ page }) => {
      await open(page, slug);
      await edit(page, input(page, first));
      await page.keyboard.press('Enter');
      await page.waitForTimeout(300);
      await expect(input(page, second)).toBeFocused();
    });
  }
});

// What a phone's browser is told. Flutter decides that it runs on Android
// from `navigator.platform` and the user agent (the engine's
// detectOperatingSystem). Playwright's device emulation leaves the
// platform "MacIntel", which Flutter takes for macOS, so the platform an
// Android phone reports is given as well.
test.describe('as on an Android phone', () => {
  test.use({
    userAgent: 'Mozilla/5.0 (Linux; Android 14; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) '
      + 'Chrome/120.0.0.0 Mobile Safari/537.36',
    viewport: { width: 412, height: 915 },
    hasTouch: true,
    isMobile: true,
  });
  test.beforeEach(async ({ page }) => {
    await page.addInitScript(() =>
      Object.defineProperty(Navigator.prototype, 'platform', { get: () => 'Linux armv8l' }));
  });

  // id -> type, inputmode, and enterkeyhint while editing. FL-162: the
  // number and decimal keyboard types leave nothing in the page, so a
  // phone's browser shows its general keyboard for them. Written to fail
  // when `inputmode="numeric"` or `"decimal"` arrives.
  const MOBILE = {
    'good-contact': { 'f03-good-contact-name': ['text', null, 'next'],
      'f03-good-contact-email': ['text', 'email', 'next'], 'f03-good-contact-phone': ['tel', null, 'done'] },
    'good-amount': { 'f03-good-amount-amount': ['text', null, 'done'] },
    'good-cupertino': { 'f03-good-cupertino-email': ['text', 'email', 'next'],
      'f03-good-cupertino-phone': ['tel', null, 'done'] },
    'good-sign-in': { 'f03-good-sign-in-username': ['text', null, 'next'],
      'f03-good-sign-in-password': ['password', null, 'done'] },
    // On a phone's browser this name field gets the general keyboard
    // (FL-162): the defect is not there on the web.
    'bad-number-for-name': { 'f03-bad-number-for-name-name': ['text', null, 'done'] },
    // The defect: an email field with no email keyboard.
    'bad-default-keyboard': { 'f03-bad-default-keyboard-email': ['text', null, 'done'] },
    'bad-no-purpose': { 'f03-bad-no-purpose-name': ['text', null, 'done'] },
    'bad-email-no-suggestions': { 'f03-bad-email-no-suggestions-email': ['text', 'email', 'done'] },
  };

  for (const [slug, fields] of Object.entries(MOBILE)) {
    test(`${slug}: the keyboard and the Enter key each field asks for`, async ({ page }) => {
      await open(page, slug);
      expect(await page.evaluate(() => navigator.platform)).toBe('Linux armv8l');
      for (const [id, [type, inputmode, enterkeyhint]] of Object.entries(fields)) {
        const box = input(page, id);
        await box.tap();
        await page.waitForTimeout(300);
        await expect(box).toBeFocused();
        const now = await attrs(box);
        expect(now.type, `${id} type`).toBe(type);
        expect(now.inputmode ?? null, `${id} inputmode`).toBe(inputmode);
        expect(now.enterkeyhint ?? null, `${id} enterkeyhint`).toBe(enterkeyhint);
      }
    });
  }
});
