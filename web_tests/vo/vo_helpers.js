// Shared by the VoiceOver specs in this folder.
// The guard must be the first import: without FLUTTER_A11Y_VOICEOVER_RUN it
// stops the spec loading before anything else runs.
import './voiceover_run_guard.js';
import { execFile } from 'node:child_process';
import { VO_HELP, phraseForMove, runAppleScript, stopsToEnd, untilQuiet } from './vo_logic.js';

export { VO_HELP, phraseForMove, runAppleScript, stopsToEnd, untilQuiet };

const APP_IDS = { chromium: 'com.google.chrome.for.testing', webkit: 'org.webkit.Playwright' };

// Guidepup's navigateToWebContent() activates the browser inside an
// AppleScript transaction, which times out on macOS 27. A plain activate works.
export const activateBrowser = (browserName) =>
  new Promise((resolve, reject) =>
    execFile('/usr/bin/osascript', ['-e', `tell application id "${APP_IDS[browserName]}" to activate`],
      { timeout: 20000 }, (err) => (err ? reject(err) : resolve())));

/**
 * Puts keyboard focus, and with it VoiceOver's cursor, on the Back button,
 * the first control on every example screen. See walkFromBack for
 * `clickAtPoint`.
 */
async function startAtBack(page, browserName, clickAtPoint) {
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
  // VoiceOver reads the button, then about a second later its help message
  // for it ("You are currently on a button…"), then an empty phrase. A walk
  // that starts before those have passed gets one of them in place of a
  // later element's speech. Wait until nothing new has come for two seconds.
  // If it never goes quiet the walk would be contaminated, so that is an
  // error and not a reason to carry on.
  const { phrase, quiet } = await untilQuiet({
    read: lastPhrase, sleep: (ms) => page.waitForTimeout(ms), quietMs: 2000, limitMs: 10000 });
  if (!quiet) {
    throw new Error(`VoiceOver did not go quiet within 10 seconds of focusing Back; it last said "${phrase}"`);
  }
}

/** Moves VoiceOver to the next element and returns what it then spoke. */
async function nextPhrase(page, voiceOver) {
  await voiceOver.next();
  let phrase = (await voiceOver.lastSpokenPhrase()).replace(/\s+/g, ' ').trim();
  // Guidepup sometimes returns before VoiceOver has spoken; give it a moment.
  for (let wait = 0; wait < 3 && phrase === ''; wait++) {
    await page.waitForTimeout(400);
    phrase = (await voiceOver.lastSpokenPhrase()).replace(/\s+/g, ' ').trim();
  }
  return phrase;
}

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
  await startAtBack(page, browserName, clickAtPoint);
  const spoken = [];
  for (let i = 0; i < max; i++) {
    const phrase = await nextPhrase(page, voiceOver);
    spoken.push(phrase);
    if (isLast(phrase, i)) break;
  }
  return spoken;
}

/**
 * Starts from the Back button and moves VoiceOver forward to the end of the
 * screen, reading what VoiceOver spoke and the position of its cursor after
 * every move. See stopsToEnd for what is returned.
 *
 * Both are read from VoiceOver directly over AppleScript, which throws when
 * a read fails. Guidepup's own record of the speech is not used here: it
 * turns a failed read into an empty phrase, and an empty phrase at an
 * unchanged position is what the end of the screen looks like. The one
 * exception is `loggedForHelp`, see phraseForMove.
 */
export async function walkToEnd(page, voiceOver, browserName, max = 40, { loggedForHelp = false } = {}) {
  await startAtBack(page, browserName, false);
  const step = async () => {
    await voiceOver.next();
    let phrase = await lastPhrase();
    if (loggedForHelp && VO_HELP.test(phrase)) {
      const logged = (await voiceOver.lastSpokenPhrase()).replace(/\s+/g, ' ').trim();
      phrase = phraseForMove(phrase, logged);
    }
    return { phrase, position: await cursorBounds() };
  };
  return stopsToEnd(step, await cursorBounds(), max);
}

// --- Announcements -------------------------------------------------------
// Guidepup only records speech that follows one of its own commands, so it
// never sees a live region announcement. VoiceOver's "last phrase" can be
// read directly over AppleScript at any time, which is how announcements are
// observed here: the keyboard drives, VoiceOver is polled.

/**
 * Where VoiceOver's cursor is on the screen, as "left, top, right, bottom".
 * Throws if it cannot be read.
 */
export const cursorBounds = () =>
  runAppleScript('tell application "VoiceOver" to get bounds of vo cursor');

/** The last phrase VoiceOver was given to speak. Throws if it cannot be read. */
export const lastPhrase = () =>
  runAppleScript('tell application "VoiceOver" to get content of last phrase');

/**
 * Waits until VoiceOver's last phrase has not changed for `quietMs`, and
 * returns it. After focus lands on a control VoiceOver reads the control and,
 * a few seconds later, a long usage hint; an announcement must not be
 * mistaken for either. Returns the last phrase at `limitMs` too: callers
 * here go on to listen, and judge what they then hear.
 */
export async function waitUntilQuiet(page, quietMs = 4000, limitMs = 20000) {
  const { phrase } = await untilQuiet({
    read: lastPhrase, sleep: (ms) => page.waitForTimeout(ms), quietMs, limitMs });
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
