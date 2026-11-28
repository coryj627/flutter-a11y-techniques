// How web_tests/vo/s11_reading_traversal_order_vo.spec.js judges and
// repeats its VoiceOver walks. Kept apart from the spec, with no VoiceOver
// and no browser, so that web_tests/s11_reading_traversal_order.spec.js can
// test it on made-up walks in CI. A copy of S08's s08_vo_walks.js (branch
// s08-list-semantics; not imported: that file is another technique's), with
// S11's screens; the judge is the same, with S08's later fix to VoiceOver's
// help message (left out only when the cursor's position and its role tie it
// to the stop before it), so its rules for an empty phrase and for help are
// S08's.

import { VO_HELP } from './vo_logic.js';

/** The heading every example screen has, as VoiceOver reads it. */
export const EXAMPLE_HEADING = 'heading level 2 Example';

/**
 * What each S11 example screen shows above its "Example" heading, as
 * VoiceOver reads it: the screen's title as a level 1 heading, the line
 * that says whether it is a good or a bad example, and a bad example's
 * defect (ExampleScreen in lib/app/screens.dart, with the titles and
 * defects of
 * lib/techniques/s11_reading_traversal_order/s11_reading_traversal_order.dart).
 * No S11 example is a custom solution, so no screen has the custom solution
 * note. web_tests/s11_reading_traversal_order.spec.js checks that each
 * screen shows these texts, so that a change to them is caught.
 */
export const EXAMPLE_SCREENS = {
  'good-columns': ['Two columns, each kept together', 'Good example for Reading and traversal order. Material.'],
  'good-sort-keys': [
    'Columns laid out row by row, given an order',
    'Good example for Reading and traversal order. Widgets layer.',
  ],
  'bad-columns-mixed': [
    'Two columns read row by row', 'Bad example for Reading and traversal order. Material.',
    'Defect: A screen reader reads across the two columns, mixing the route with what to bring.',
  ],
  'bad-key-missing': [
    'One part with no sort key', 'Bad example for Reading and traversal order. Widgets layer.',
    'Defect: The "Bring" title has no sort key, so a screen reader reads it before the route.',
  ],
};

/** The stops VoiceOver reads above the "Example" heading of `slug`'s screen. */
export const screenStops = (slug) => {
  const [title, ...lines] = EXAMPLE_SCREENS[slug];
  return [`heading level 1 ${title}`, ...lines];
};

/** The role a help message names: "list" for "You are currently on a list, …". */
export function helpRole(phrase) {
  const m = /^You are currently on (?:an? )?(.+?)(?:,| inside of |\.)/.exec(phrase);
  return m ? m[1].trim() : null;
}

/**
 * The role VoiceOver spoke in a stop's reading, from where VoiceOver puts
 * it, or null for a stop that has none: "heading level 3" for "heading
 * level 3 Route" (a heading's role comes first), "button" for "Save route
 * button" (a button's comes last). A plain text or a count, such as "A map"
 * or "List saves: 0", has no role, whatever words its label holds. These
 * are the only roles on S11's screens; the screens' titles ("heading level
 * 1 ...") and the "Example" heading are headings too.
 */
export function spokenRole(reading) {
  const heading = /^(heading level \d+) \S/.exec(reading);
  if (heading) return heading[1];
  if (/\S button$/.test(reading)) return 'button';
  return null;
}

/**
 * Whether stop `i` of a walk is a help message about the stop before it:
 * VO_HELP, the cursor at the same position as for stop `i - 1` (from
 * `positions`, the walk's record of where the cursor was at each stop), the
 * stop before it a reading, neither empty nor a help message, and the role
 * the help names the role spoken in that reading (spokenRole): "heading
 * level 3", or "heading", for a level 3 heading's reading, "button" for a
 * button's. The help's role is matched against the reading's role, never
 * against its label, so "on a list" after "Save list button" or "List
 * saves: 0" is not left out. False whenever any of that cannot be shown,
 * `positions` missing included. S08's rule, mirrored, with the role read
 * from where VoiceOver speaks it.
 */
export function helpAfterStop(stops, positions, i) {
  if (!VO_HELP.test(stops[i]) || i === 0 || !Array.isArray(positions)) return false;
  if (positions.length !== stops.length || positions[i] !== positions[i - 1]) return false;
  const before = stops[i - 1];
  if (before === '' || VO_HELP.test(before)) return false;
  const named = helpRole(stops[i]);
  const spoken = spokenRole(before);
  if (named === null || spoken === null) return false;
  const role = named.toLowerCase();
  return role === spoken || (role === 'heading' && spoken.startsWith('heading level '));
}

/**
 * Judges one walk of an example screen: `stops` in order, whether the walk
 * reached the end of the screen (two moves in a row that changed nothing),
 * `expected`, everything VoiceOver must say after the "Example" heading to
 * the end of the screen, in order, and `screen`, the stops the screen has
 * before the heading (screenStops), and `positions`, the cursor's position
 * at each stop, when the walk recorded them. The walk must read the whole screen:
 * `screen`, then the heading, then `expected`, every stop in its place and
 * nothing else. Returns `{ verdict, reason }`, the verdict one of:
 *
 * - "wrong": a stop that READ something other than the one expected in its
 *   place (a stop read in other words, a stop skipped so that a later one
 *   comes early, a stop after the last expected one, empty or not), or a walk that
 *   reached the end of the screen with any expected stop not read, the
 *   title, the description, the heading, or a list item included. This
 *   fails the test whichever try it is in, and is looked for first: a walk
 *   with a wrong reading is wrong even if a capture in it also failed.
 * - "incomplete": a walk whose capture failed or fell short, with nothing
 *   wrong read in it: a stop read as an empty phrase (the AppleScript read
 *   of VoiceOver's last phrase gave nothing for a move that changed the
 *   cursor's position), or a walk cut short before the end (it ran out of
 *   moves) with every stop so far the expected one in its place. Only such
 *   a walk may be walked again (runWalks, at most three walks, each
 *   logged), and an empty phrase never passes: no expected stop is empty,
 *   so three such walks fail the test.
 * - "complete": the walk reached the end and read exactly the whole screen,
 *   with no empty stop.
 *
 * A stop that is VoiceOver's help message ("You are currently on a list,
 * inside of web content. …", VO_HELP) is left out only when it is tied to
 * the stop before it (helpAfterStop): `positions`, the cursor's position at
 * each stop as the walk recorded it, shows the cursor had not moved, the
 * stop before it is a reading (neither empty nor help), and the role the
 * help names ("on a button") is the role spoken in that reading ("Save
 * route button", spokenRole), not a word of its label. It
 * is then VoiceOver's speech about the element just judged. Any other help
 * message is a stop like any other, and since no expected stop is a help
 * message it is wrong and fails for good: one at a new position (an element
 * nothing else was read for), one naming a role the reading before it does
 * not have, one with no stop before it, and every help message in a walk
 * with no positions. A help message given in place of an element's own
 * speech is at a new position, and fails. S08's fourth recording (WebKit)
 * read every expected stop and then a list's help message after the last
 * one; it recorded no positions, so such a walk judges wrong here.
 *
 * An empty stop holds the place of the stop expected there: the S08 walks
 * that gave one (its second and third recordings, WebKit, the screen's
 * level 1 heading) read every later stop in its place. This is the rule the
 * principal set on 2026-11-26: an empty reading is a failed capture, walked
 * again, and a reading of the wrong words fails for good. S11's first
 * recording (2026-11-26, the judge before review) gave one such walk:
 * WebKit, bad-columns-mixed, the screen's title read as an empty phrase,
 * every later stop right; the second walk was complete. The second
 * recording (2026-11-27) gave none. No help message came in either, so the
 * help rule above is tested here only by the made-up walks in the web tree
 * spec.
 */
export function judgeExampleWalk(walked, reachedEnd, expected, screen = [], positions = undefined) {
  // VoiceOver's own help message (VO_HELP, vo_logic.js), when it is about
  // the element just read, is not a stop of the page (helpAfterStop).
  const stops = walked.filter((stop, i) => !helpAfterStop(walked, positions, i));
  const whole = [...screen, EXAMPLE_HEADING, ...expected];
  const empty = [];
  for (let i = 0; i < stops.length; i++) {
    // A stop past the last expected one is wrong for good, an empty one
    // too: this is checked before an empty phrase is let stand as a failed
    // capture, so that an extra element at the end cannot be walked away.
    if (i >= whole.length) {
      return { verdict: 'wrong', reason: `"${stops[i]}" was read after the last expected stop` };
    }
    if (stops[i] === '') {
      empty.push(i + 1);
      continue;
    }
    if (stops[i] !== whole[i]) {
      return { verdict: 'wrong', reason: `stop ${i + 1} was "${stops[i]}" where "${whole[i]}" was expected` };
    }
  }
  if (reachedEnd && stops.length < whole.length) {
    return {
      verdict: 'wrong',
      reason: `the walk reached the end after ${stops.length} of the ${whole.length} expected stops; "${whole[stops.length]}" was never read`,
    };
  }
  if (empty.length > 0) {
    return {
      verdict: 'incomplete',
      reason: `the capture failed: stop${empty.length > 1 ? 's' : ''} ${empty.join(', ')} read as an empty phrase, nothing else wrong`,
    };
  }
  if (stops.length === whole.length) {
    return reachedEnd
      ? { verdict: 'complete', reason: 'the whole screen, every stop in its place' }
      : { verdict: 'incomplete', reason: 'every expected stop was read, but the walk did not reach the end' };
  }
  return { verdict: 'incomplete', reason: `the walk was cut short after ${stops.length} of the ${whole.length} expected stops, all right so far` };
}

/**
 * Walks up to `tries` times with `walkOnce()`, which resolves to
 * `{ stops, reachedEnd }`, and judges each walk with
 * `judge(stops, reachedEnd)`. `log(walk, stops, judged)` is called for
 * every try, so every attempt is kept. Stops at the first walk that is
 * "wrong" or "complete" and returns its verdict, with the number of walks
 * made; if no try was either, "incomplete". A wrong walk is never followed
 * by another try, so a later correct walk cannot hide it.
 */
export async function runWalks(walkOnce, judge, { tries = 3, log = () => {} } = {}) {
  let judged = { verdict: 'incomplete', reason: 'no walk was made' };
  for (let walk = 1; walk <= tries; walk++) {
    const { stops, reachedEnd } = await walkOnce();
    judged = judge(stops, reachedEnd);
    log(walk, stops, judged);
    if (judged.verdict !== 'incomplete') return { ...judged, walks: walk };
  }
  return { ...judged, walks: tries };
}
