// Shared by the VoiceOver specs in this folder.
import { execFile } from 'node:child_process';

const APP_IDS = { chromium: 'com.google.chrome.for.testing', webkit: 'org.webkit.Playwright' };

// Guidepup's navigateToWebContent() activates the browser inside an
// AppleScript transaction, which times out on macOS 27. A plain activate works.
export const activateBrowser = (browserName) =>
  new Promise((resolve, reject) =>
    execFile('/usr/bin/osascript', ['-e', `tell application id "${APP_IDS[browserName]}" to activate`],
      { timeout: 20000 }, (err) => (err ? reject(err) : resolve())));

/**
 * Starts from the Back button, the first control on every example screen, and
 * moves VoiceOver forward until `isLast(phrase)` is true. Returns what was
 * spoken at each step.
 */
export async function walkFromBack(page, voiceOver, browserName, isLast, max = 24) {
  await activateBrowser(browserName);
  await page.bringToFront();
  // A real click, on inert text: the browser can come up with keyboard focus
  // in its own toolbar, and setting DOM focus from script does not move it
  // into the page, which left VoiceOver's cursor in the tab bar on about
  // every other walk.
  await page.getByRole('heading', { name: 'Example', level: 2 }).click();
  await page.getByRole('button', { name: 'Back' }).focus();
  await page.waitForTimeout(1500);
  const spoken = [];
  for (let i = 0; i < max; i++) {
    await voiceOver.next();
    let phrase = (await voiceOver.lastSpokenPhrase()).replace(/\s+/g, ' ').trim();
    // Guidepup sometimes returns before VoiceOver has spoken; give it a moment.
    for (let wait = 0; wait < 3 && phrase === ''; wait++) {
      await page.waitForTimeout(400);
      phrase = (await voiceOver.lastSpokenPhrase()).replace(/\s+/g, ' ').trim();
    }
    spoken.push(phrase);
    if (isLast(phrase)) break;
  }
  return spoken;
}
