// How web_tests/vo/v12_accessibility_settings_vo.spec.js keeps the Mac's
// VoiceOver as it found it. V12's own file; no other technique imports it.
//
// Guidepup's `voiceOverTest` fixture swallows a failed `stop()`, and
// Guidepup's restart of a VoiceOver that was already running catches its own
// errors (`@guidepup/playwright` lib/voiceOverTest.js, `@guidepup/guidepup`
// lib/macOS/VoiceOver/VoiceOver.js, read), so a walk that passed could leave
// VoiceOver on, or the user's own VoiceOver off, and say nothing. Here the
// state is read by an independent means, `pgrep -x VoiceOver` run directly
// (whether a process named VoiceOver is running; Guidepup is not asked),
// before VoiceOver is started; after the walk and Guidepup's stop it is read
// the same way, put back if it differs, and read again; a failed start, a
// failed stop, or a state that could not be put back fails the test, with
// every error kept, the walk's own included.
//
// Kept apart from the spec, with no VoiceOver and no browser, so that
// web_tests/v12_accessibility_settings.spec.js can test it on doubles in CI.
// It imports nothing that starts VoiceOver.
import { execFileSync } from 'node:child_process';

/**
 * Whether a process named VoiceOver is running: `pgrep -x VoiceOver`, which
 * exits 0 when one is and 1 when none is. Any other result is not an
 * answer, and throws: the state is unknown. `exec` is for the tests.
 */
export function voiceOverRunning(exec = execFileSync) {
  try {
    exec('/usr/bin/pgrep', ['-x', 'VoiceOver'], { stdio: 'ignore', timeout: 5000 });
    return true;
  } catch (error) {
    if (error && error.status === 1) return false;
    throw new Error(`VoiceOver's state could not be read (pgrep -x VoiceOver: ${error && (error.status ?? error.message)})`);
  }
}

/** Quits VoiceOver outside Guidepup: `killall VoiceOver`. */
export function quitVoiceOver(exec = execFileSync) {
  exec('/usr/bin/killall', ['VoiceOver'], { stdio: 'ignore', timeout: 5000 });
}

/** Waits up to `ms` for `isRunning()` to be `want`; returns what it last read. */
export async function waitForState(isRunning, want, { ms = 15000, step = 250, sleep } = {}) {
  const pause = sleep ?? ((t) => new Promise((r) => setTimeout(r, t)));
  const end = Date.now() + ms;
  let now = isRunning();
  while (now !== want && Date.now() < end) {
    await pause(step);
    now = isRunning();
  }
  return now;
}

const say = (on) => (on ? 'on' : 'off');

/**
 * Runs a VoiceOver walk and keeps the Mac's VoiceOver as it was found:
 *
 * 1. `isRunning()` read before anything is started (a failure to read it
 *    fails at once, and nothing is started);
 * 2. `start()`, then `use()` (the test; in the fixture Playwright records a
 *    failed test itself, and `use()` returns), each error kept;
 * 3. `stop()`, its error kept, never swallowed;
 * 4. the state read again (waited for, as VoiceOver takes a moment to quit
 *    or come back); if it is not what was found, `restart()` (found on) or
 *    `quit()` (found off), and read again; still not what was found is a
 *    failed restore.
 *
 * Throws one error naming every failure, in order, when there is any, so
 * that a failed stop or restore fails the test even when the walk failed
 * too. `log` gets one line for the state found and one for the state left.
 * Returns the state found.
 */
export async function withVoiceOverState({ isRunning, start, use, stop, restart, quit, wait, log = () => {} }) {
  const waitFor = wait ?? ((want) => waitForState(isRunning, want));
  const before = isRunning();
  log(`found ${say(before)}`);
  const errors = [];
  try {
    await start();
    await use();
  } catch (error) {
    errors.push(`the walk: ${error && error.message ? error.message : error}`);
  }
  try {
    await stop();
  } catch (error) {
    errors.push(`VoiceOver's stop failed: ${error && error.message ? error.message : error}`);
  }
  try {
    let now = await waitFor(before);
    if (now !== before) {
      if (before) await restart(); else await quit();
      now = await waitFor(before);
    }
    log(`left ${say(now)}`);
    if (now !== before) errors.push(`VoiceOver not put back: found ${say(before)}, left ${say(now)}`);
  } catch (error) {
    errors.push(`VoiceOver not put back ${say(before)}: ${error && error.message ? error.message : error}`);
  }
  if (errors.length) throw new Error(errors.join('; '));
  return before;
}
