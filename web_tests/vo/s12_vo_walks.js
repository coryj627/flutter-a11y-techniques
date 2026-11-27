// How web_tests/vo/s12_hiding_content_vo.spec.js judges and repeats its
// VoiceOver walks. Kept apart from the spec, with no VoiceOver and no
// browser, so that web_tests/s12_hiding_content.spec.js can test it on
// made-up walks in CI. A copy of S08's s08_vo_walks.js (not imported: that
// file is another technique's), with S12's screens; the judge is the same,
// and `spokenRole` knows the roles S12's lists expect (a switch, a button).

import { VO_HELP } from './vo_logic.js';

/** The heading every example screen has, as VoiceOver reads it. */
export const EXAMPLE_HEADING = 'heading level 2 Example';

/**
 * What each S12 example screen shows above its "Example" heading, as
 * VoiceOver reads it: the screen's title as a level 1 heading, the line
 * that says whether it is a good or a bad example, and a bad example's
 * defect (ExampleScreen in lib/app/screens.dart, with the titles and
 * defects of lib/techniques/s12_hiding_content/s12_hiding_content.dart). No
 * S12 example is a custom solution, so no screen has the custom solution
 * note. web_tests/s12_hiding_content.spec.js checks that each screen shows
 * these texts, so that a change to them is caught.
 */
export const EXAMPLE_SCREENS = {
  'good-decoration': ['Ornaments hidden from AT', 'Good example for Hiding content from AT. Widgets layer.'],
  'good-badge': ['Repeated count hidden from AT', 'Good example for Hiding content from AT. Material.'],
  'good-visibility': ['Panel hidden from everyone', 'Good example for Hiding content from AT. Material.'],
  'bad-decoration-read': [
    'Ornaments read aloud', 'Bad example for Hiding content from AT. Widgets layer.',
    'Defect: A screen reader stops on each ornament and reads it.',
  ],
  'bad-hidden-control': [
    'Button hidden with an ornament', 'Bad example for Hiding content from AT. Material.',
    'Defect: A screen reader cannot find the Share button; the keyboard still reaches it.',
  ],
  'bad-opacity': [
    'Panel hidden by opacity', 'Bad example for Hiding content from AT. Material.',
    'Defect: While the panel is hidden, the keyboard still reaches its button, which no screen reader can find.',
  ],
  'bad-maintain': [
    'Panel hidden only from sight', 'Bad example for Hiding content from AT. Material.',
    'Defect: While the panel is hidden, a screen reader still reads it and the keyboard still reaches its button.',
  ],
};

const QUOTE = 'Walk the ridge before the sun is up.';
const SOURCE = 'Trail guide';
const SWITCH_OFF = 'Show tracking off switch';

// slug -> everything VoiceOver speaks (web_tests/vo/s12_hiding_content_vo.spec.js,
// which judges each walk against it) after the "Example" heading, to the
// end of the screen, in order, one entry for each element its cursor stops
// on. Because every stop is listed, the lists also show what is not spoken.
//
// Written as predictions, before any web VoiceOver recording of S12, from
// the page's elements (web_tests/s12_hiding_content.spec.js) and from what
// VoiceOver read for the same kinds of element in other techniques'
// recordings: a SwitchListTile "Bluetooth off switch" (F09), a TextButton
// "<name> button", a plain text by its words. The recording of 2026-11-27
// (docs/evidence/S12/voiceover-web.md) read every list as written, in
// Chromium and WebKit, each walk complete on its first walk. The ornaments'
// stops are the characters as VoiceOver's last phrase gives them; how the
// voice pronounced them is not recorded.
export const EXPECTED_STOPS = {
  // The quote and who said it: no ornament.
  'good-decoration': [QUOTE, SOURCE],
  // The words alone: no "3" from the badge.
  'good-badge': ['Inbox: 3 unread'],
  // Hidden: the switch and the count; nothing of the panel.
  'good-visibility': [SWITCH_OFF, 'Copies: 0'],
  // Each ornament read, around the quote.
  'bad-decoration-read': ['❝', QUOTE, SOURCE, '✦ ✦ ✦'],
  // The quote and the count: no Share button.
  'bad-hidden-control': [QUOTE, 'Shares: 0'],
  // Hidden: as good-visibility; the keyboard's reach is in the tree spec.
  'bad-opacity': [SWITCH_OFF, 'Copies: 0'],
  // Hidden, and read all the same: the number and its button.
  'bad-maintain': [SWITCH_OFF, 'Tracking number: 1Z 999', 'Copy number button', 'Copies: 0'],
};

/** The stops VoiceOver reads above the "Example" heading of `slug`'s screen. */
export const screenStops = (slug) => {
  const [title, ...lines] = EXAMPLE_SCREENS[slug];
  return [`heading level 1 ${title}`, ...lines];
};

/** The role a help message names: "switch" for "You are currently on a switch, …". */
export function helpRole(phrase) {
  const m = /^You are currently on (?:an? )?(.+?)(?:,| inside of |\.)/.exec(phrase);
  return m ? m[1].trim() : null;
}

/**
 * The role VoiceOver spoke in a reading, from the role part of the reading
 * only, never from the element's name: "heading" for "heading level 1
 * Ornaments hidden from AT"; "switch" for "Show tracking off switch" (and
 * "on switch"); "button" for "Copy number button". Null for a reading with
 * no role part, such as a plain text: such a stop allows no help message
 * after it. These are the roles S12's lists expect.
 */
export function spokenRole(reading) {
  if (/^heading level \d+ /.test(reading)) return 'heading';
  if (/ (?:on|off) switch$/.test(reading)) return 'switch';
  if (/ button$/.test(reading)) return 'button';
  return null;
}

/**
 * Whether stop `i` of a walk is a help message about the stop before it:
 * VO_HELP, the cursor at the same position as for stop `i - 1` (from
 * `positions`, the walk's record of where the cursor was at each stop), the
 * stop before it a reading, neither empty nor a help message, and the role
 * the help names the same as the role spoken in that reading (spokenRole),
 * never a word of the element's name. False whenever any of that cannot be
 * shown, `positions` missing included.
 */
export function helpAfterStop(stops, positions, i) {
  if (!VO_HELP.test(stops[i]) || i === 0 || !Array.isArray(positions)) return false;
  if (positions.length !== stops.length || positions[i] !== positions[i - 1]) return false;
  const before = stops[i - 1];
  if (before === '' || VO_HELP.test(before)) return false;
  const role = helpRole(stops[i]);
  return role !== null && role === spokenRole(before);
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
 *   comes early, a stop after the last expected one), or a walk that
 *   reached the end of the screen with any expected stop not read, the
 *   title, the description, the heading, or any element of the example. This
 *   fails the test whichever try it is in, and is looked for first: a walk
 *   with a wrong reading is wrong even if a capture in it also failed.
 * - "incomplete": a walk whose capture failed or fell short, with nothing
 *   wrong read in it: a stop read as an empty phrase (the AppleScript read
 *   of VoiceOver's last phrase gave nothing for a move that changed the
 *   cursor's position), or a walk cut short before the end (it ran out of
 *   moves) with every stop so far the expected one in its place. Only such
 *   a walk may be walked again (runWalks, at most three walks, each
 *   logged), and an empty phrase never passes: no expected stop is empty,
 *   so three such walks fail the test. An empty stop past the last expected
 *   one is not a failed capture but an element the screen does not have:
 *   it is wrong, as any stop there is.
 * - "complete": the walk reached the end and read exactly the whole screen,
 *   with no empty stop.
 *
 * A stop that is VoiceOver's help message ("You are currently on a switch,
 * inside of web content. …", VO_HELP) is left out only when it is tied to
 * the stop before it (helpAfterStop): `positions`, the cursor's position at
 * each stop as the walk recorded it, shows the cursor had not moved, the
 * stop before it is a reading (neither empty nor help), and the role the
 * help names ("on a switch") is the role spoken in that reading, from its
 * role part only (spokenRole: "Show tracking off switch" is a switch's;
 * "heading level 1 Ornaments hidden from AT" is a heading's, whatever its
 * name says). It is then
 * VoiceOver's speech about the element just judged. Any other help message
 * is a stop like any other, and since no expected stop is a help message it
 * is wrong and fails for good: one at a new position (an element nothing
 * else was read for), one naming a role the reading before it does not
 * have, one with no stop before it, and every help message in a walk with
 * no positions. A help message given in place of an element's own speech
 * is at a new position, and fails. The rule for a help message is tested
 * only on made-up walks (web_tests/s12_hiding_content.spec.js): S08's
 * recordings, where it was written, never had one come with positions.
 *
 * An empty stop holds the place of the stop expected there: S08's
 * recordings had walks that gave one (WebKit, the screen's level 1
 * heading; docs/evidence/probes/s08/voiceover-web-round2-fail.md.txt and
 * round 3) and read every later stop in its place. This is the rule the
 * principal set on 2026-11-26: an empty reading is a failed capture, walked
 * again, and a reading of the wrong words fails for good. An empty reading
 * stands for nothing.
 */
export function judgeExampleWalk(walked, reachedEnd, expected, screen = [], positions = undefined) {
  // VoiceOver's own help message (VO_HELP, vo_logic.js), when it is about
  // the element just read, is not a stop of the page (helpAfterStop).
  const stops = walked.filter((stop, i) => !helpAfterStop(walked, positions, i));
  const whole = [...screen, EXAMPLE_HEADING, ...expected];
  const empty = [];
  for (let i = 0; i < stops.length; i++) {
    // A stop past the end of the screen is wrong, empty or not: an empty
    // phrase there is an element the screen does not have, not a failed
    // capture of one it does.
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
