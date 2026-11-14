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
 * moves VoiceOver forward until `isLast(phrase, index)` is true. Returns what
 * was spoken at each step.
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
    if (isLast(phrase, i)) break;
  }
  return spoken;
}

// --- Announcements -------------------------------------------------------
// Guidepup only records speech that follows one of its own commands, so it
// never sees a live region announcement. VoiceOver's "last phrase" can be
// read directly over AppleScript at any time, which is how announcements are
// observed here: the keyboard drives, VoiceOver is polled.

const osascript = (script) =>
  new Promise((resolve) =>
    execFile('/usr/bin/osascript', ['-e', script], { timeout: 5000 },
      (err, out) => resolve(err ? '' : out.replace(/\s+/g, ' ').trim())));

/** The last phrase VoiceOver was given to speak. */
export const lastPhrase = () => osascript('tell application "VoiceOver" to get content of last phrase');

/**
 * Waits until VoiceOver's last phrase has not changed for `quietMs`, and
 * returns it. After focus lands on a control VoiceOver reads the control and,
 * a few seconds later, a long usage hint; an announcement must not be
 * mistaken for either.
 */
export async function waitUntilQuiet(page, quietMs = 4000, limitMs = 20000) {
  let phrase = await lastPhrase();
  let since = Date.now();
  const limit = Date.now() + limitMs;
  while (Date.now() - since < quietMs && Date.now() < limit) {
    await page.waitForTimeout(250);
    const now = await lastPhrase();
    if (now !== phrase) {
      phrase = now;
      since = Date.now();
    }
  }
  return phrase;
}

/**
 * Runs `action`, then collects each new phrase VoiceOver is given for
 * `listenMs`. `ignore` is the phrase from before the action.
 */
export async function heardAfter(page, action, ignore, listenMs = 6000) {
  await action();
  const heard = [];
  const end = Date.now() + listenMs;
  while (Date.now() < end) {
    const now = await lastPhrase();
    if (now && now !== ignore && now !== heard[heard.length - 1]) heard.push(now);
    await page.waitForTimeout(150);
  }
  return heard;
}
