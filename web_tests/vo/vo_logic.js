// The parts of the VoiceOver helpers that need neither VoiceOver nor a
// browser, so that web_tests/vo_helpers.spec.js can test them without the
// guard in voiceover_run_guard.js. The VoiceOver specs import them through
// vo_helpers.js.
import { execFile } from 'node:child_process';

/**
 * Calls `step()` until the end of the screen. `step` moves VoiceOver forward
 * once and resolves to `{ phrase, position }`: what was spoken and where
 * VoiceOver's cursor then is. `start` is the cursor's position before the
 * first move. Returns `{ stops, reachedEnd }`: the phrase spoken at each
 * element the cursor stopped on, in order, and whether the end was reached
 * within `max` moves.
 *
 * Speech alone cannot show the end, or tell two elements that read the same
 * from one element read twice, so the cursor's position is used as well. A
 * move is a stop on a new element when the position changed, or when a
 * phrase was spoken that differs from the last stop's (two elements can sit
 * in the same place). A stop is kept even when no new phrase is reported
 * for it. A move that changes neither is not a stop, and two of those in a
 * row are the end of the screen.
 *
 * What this cannot tell apart: two elements in the same place that read the
 * same. The tree tests, which count elements, cover that case.
 */
export async function stopsToEnd(step, start, max = 40) {
  const stops = [];
  let position = start;
  let unmoved = 0;
  for (let i = 0; i < max; i++) {
    const { phrase, position: now } = await step();
    const spokeAnew = phrase !== '' && stops.length > 0 && phrase !== stops[stops.length - 1];
    if (now === position && !spokeAnew) {
      unmoved++;
      if (unmoved === 2) return { stops, reachedEnd: true };
      continue;
    }
    unmoved = 0;
    position = now;
    stops.push(phrase);
  }
  return { stops, reachedEnd: false };
}

/** How VoiceOver's own help message for the element under its cursor starts. */
export const VO_HELP = /^You are currently on /;

/**
 * What to record for one move. On a text field with a description VoiceOver
 * follows the field's own speech at once with its help message ("You are
 * currently on a text field…"), which is then its last phrase. `logged` is
 * what Guidepup recorded for the same move, read straight after it, so the
 * two belong to one command. It is used only in place of a help message: a
 * failed read there is an empty phrase, which no expected list contains.
 */
export const phraseForMove = (direct, logged) => (VO_HELP.test(direct) ? logged : direct);

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

/**
 * Polls `read()` until what it returns has not changed for `quietMs`, or
 * until `limitMs` has passed. Resolves to `{ phrase, quiet }`: the last
 * value read, and whether the quiet interval was completed. `quiet` is
 * false when the limit came first. `read`, `sleep`, and `now` are passed in
 * so this can be tested without VoiceOver.
 */
export async function untilQuiet({ read, sleep, now = Date.now, quietMs, limitMs, pollMs = 250 }) {
  let phrase = await read();
  let since = now();
  const limit = now() + limitMs;
  while (now() - since < quietMs && now() < limit) {
    await sleep(pollMs);
    const latest = await read();
    if (latest !== phrase) {
      phrase = latest;
      since = now();
    }
  }
  return { phrase, quiet: now() - since >= quietMs };
}
