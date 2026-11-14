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
 *
 * `clickAtPoint` makes that click with the mouse at the heading's position,
 * without Playwright's check that nothing covers it. It is for a screen with
 * a Material `Slider`, which on web adds an empty full-screen element above
 * the others, so the checked click never succeeds
 * (docs/flutter-limitations.md, FL-029).
 */
export async function walkFromBack(page, voiceOver, browserName, isLast, max = 24, clickAtPoint = false) {
  await activateBrowser(browserName);
  await page.bringToFront();
  // A real click, on inert text: the browser can come up with keyboard focus
  // in its own toolbar, and setting DOM focus from script does not move it
  // into the page, which left VoiceOver's cursor in the tab bar on about
  // every other walk.
  const heading = page.getByRole('heading', { name: 'Example', level: 2 });
  if (clickAtPoint) {
    const box = await heading.boundingBox();
    if (!box) {
      throw new Error(`The "Example" heading has no box to click on ${page.url()}: ` +
        `${await heading.count()} matching element(s), none on screen.`);
    }
    await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
  } else {
    await heading.click();
  }
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

/**
 * Runs an AppleScript and returns its output. Rejects on any error or
 * timeout: a failed read must never look like "VoiceOver said nothing",
 * or a check for silence would pass when capture is broken.
 */
export const runAppleScript = (script) =>
  new Promise((resolve, reject) =>
    execFile('/usr/bin/osascript', ['-e', script], { timeout: 5000 }, (err, out, stderr) =>
      err
        ? reject(new Error(`AppleScript failed: ${(stderr || err.message).trim()}`))
        : resolve(out.replace(/\s+/g, ' ').trim())));

/** The last phrase VoiceOver was given to speak. Throws if it cannot be read. */
export const lastPhrase = () =>
  runAppleScript('tell application "VoiceOver" to get content of last phrase');

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

/**
 * Proves that speech capture is working right now: moves VoiceOver's cursor
 * and requires the last phrase to change to something non-empty. Call it
 * after listening for silence, so "nothing was announced" cannot be the
 * result of capture having stopped.
 */
export async function assertCaptureIsLive(page, voiceOver) {
  const before = await lastPhrase();
  for (let attempt = 0; attempt < 4; attempt++) {
    await voiceOver.previous();
    await page.waitForTimeout(600);
    const now = await lastPhrase();
    if (now && now !== before) return now;
  }
  throw new Error(`VoiceOver capture is not live: last phrase stayed "${before}" after moving the cursor`);
}
