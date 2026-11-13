// L4 on web for C01 Button: what VoiceOver on macOS speaks for each example.
// Needs Guidepup's setup and macOS automation permissions on the machine.
// Run through tool/voiceover_web_c01.py, which also writes the transcript.
import { execFile } from 'node:child_process';
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';

const APP_IDS = { chromium: 'com.google.chrome.for.testing', webkit: 'org.webkit.Playwright' };

// Guidepup's navigateToWebContent() activates the browser inside an
// AppleScript transaction, which times out on macOS 27. A plain activate works.
const activate = (id) =>
  new Promise((resolve, reject) =>
    execFile('/usr/bin/osascript', ['-e', `tell application id "${id}" to activate`],
      { timeout: 20000 }, (err) => (err ? reject(err) : resolve())));

// slug -> [phrases that must be spoken, phrases that must not be].
const EXAMPLES = {
  'good-text': [['Save button', 'Cancel button', 'Learn more button'], []],
  'good-icon': [['Close button'], []],
  'good-disabled': [['Submit dimmed button'], []],
  'good-unique-names': [
    ['Edit username button', 'Edit email button', 'Edit password button'],
    ['Edit button'],
  ],
  'good-cupertino': [['Save button', 'Delete dimmed button'], []],
  'good-custom': [['Save button'], []],
  // Bad examples: the defect must be audible.
  'bad-unlabelled-icon': [['button'], ['Close button']],
  // Flutter web gives every tappable node role="button", so on web this one
  // is announced as a button. Its defect on web is keyboard access, which the
  // tree suite asserts (c01_button.spec.js).
  'bad-gesture-only': [['Save button'], []],
  'bad-role-in-name': [['Close button button'], []],
  'bad-duplicate-names': [['Edit button'], ['Edit username button']],
  'bad-name-mismatch': [['Change username button'], ['Edit button']],
  'bad-fake-disabled': [['Submit button'], ['Submit dimmed button']],
  'bad-cupertino-disabled': [['Delete button'], ['Delete dimmed button']],
};

for (const [slug, [must, mustNot]] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/C01/${slug}`, { waitUntil: 'load' });
    await expect(page.locator(`[flt-semantics-identifier="c01-${slug}-count"]`)).toBeVisible();
    await activate(APP_IDS[browserName]);
    await page.bringToFront();
    // Start from the Back button, the first control on every example screen,
    // and swipe forward to the activation count, the last element.
    await page.getByRole('button', { name: 'Back' }).focus();
    await page.waitForTimeout(1500);
    const spoken = [];
    for (let i = 0; i < 20; i++) {
      await voiceOver.next();
      const phrase = (await voiceOver.lastSpokenPhrase()).replace(/\s+/g, ' ').trim();
      spoken.push(phrase);
      if (phrase.startsWith('Activations:')) break;
    }
    console.log(`C01VO ${browserName} ${slug} | ${spoken.join(' / ')}`);
    for (const phrase of must) expect(spoken, slug).toContain(phrase);
    for (const phrase of mustNot) expect(spoken, slug).not.toContain(phrase);
  });
}
