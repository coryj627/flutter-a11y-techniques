// How web_tests/vo/s10_content_group_replacement_vo.spec.js judges and
// repeats its VoiceOver walks. Kept apart from the spec, with no VoiceOver
// and no browser, so that web_tests/s10_content_group_replacement.spec.js
// can test it on made-up walks in CI. A copy of S08's s08_vo_walks.js (not
// imported: that file is another technique's), with S10's screens and
// expected stops, and with spokenRole and helpRole extended to the roles
// S10's stops have (a text, a progress indicator); the judge is the same.

import { VO_HELP } from './vo_logic.js';

/** The heading every example screen has, as VoiceOver reads it. */
export const EXAMPLE_HEADING = 'heading level 2 Example';

/**
 * What each S10 example screen shows above its "Example" heading, as
 * VoiceOver reads it: the screen's title as a level 1 heading, the line
 * that says whether it is a good or a bad example, and a bad example's
 * defect (ExampleScreen in lib/app/screens.dart, with the titles and
 * defects of
 * lib/techniques/s10_content_group_replacement/s10_content_group_replacement.dart).
 * No S10 example is a custom solution, so no screen has the custom solution
 * note. web_tests/s10_content_group_replacement.spec.js checks that each
 * screen shows these texts, so that a change to them is caught.
 */
export const EXAMPLE_SCREENS = {
  'good-exclude-semantics': [
    'Rating replaced with excludeSemantics',
    'Good example for Content group replacement. Material.',
  ],
  'good-hidden-pieces': [
    'Rating merged, with every piece hidden',
    'Good example for Content group replacement. Material.',
  ],
  'good-stars': ['Star rating replaced', 'Good example for Content group replacement. Widgets layer.'],
  'bad-pieces': [
    'Star rating left as pieces', 'Bad example for Content group replacement. Widgets layer.',
    'Defect: The stars are not read, and nothing says what 3.4 and 856 are.',
  ],
  'bad-merged': [
    'Rating merged, not replaced', 'Bad example for Content group replacement. Material.',
    'Defect: The rating is read with a stray 68 from the bar.',
  ],
  'bad-not-excluded': [
    'Label with the pieces left in', 'Bad example for Content group replacement. Material.',
    'Defect: The rating is read twice, with a stray 68.',
  ],
  'bad-hides-control': [
    'Replacement that hides a button', 'Bad example for Content group replacement. Material.',
    'Defect: A screen reader cannot find the Reviews button.',
  ],
  'bad-stale': [
    'Replacement with a fixed label', 'Bad example for Content group replacement. Material.',
    'Defect: After a review is added, a screen reader still hears 856.',
  ],
};

const WORDS = 'Rating: 3.4 out of 5 stars, based on 856 reviews';
const WORDS_AFTER = 'Rating: 3.4 out of 5 stars, based on 857 reviews';
const ADD = 'Add a 5-star review button';
// The bar row's texts, as one name (Chromium joins the lines with spaces).
const PIECES = 'Rating: 3.4 / 5 Reviews: 856';

// slug -> everything VoiceOver speaks (web_tests/vo/s10_content_group_replacement_vo.spec.js,
// which judges each walk against it) after the "Example" heading, to the
// end of the screen, in order, one entry for each element its cursor stops
// on. Because every stop is listed, the lists also show what is not spoken.
// They were written before any S10 recording, from the semantics tree the
// web probe and the tree spec measured (docs/evidence/probes/s10/web.txt)
// and from what VoiceOver read for the same kinds of element in other
// techniques' transcripts: a text element as its text, a button with
// "button", and a progress bar as its name, then its value as a percentage,
// then "progress indicator" (docs/evidence/C26/voiceover-web.md). The
// recording of 2026-11-27 (docs/evidence/S10/voiceover-web.md) read every
// one exactly, in Chromium and WebKit (one WebKit walk walked again after
// an empty title, a failed capture).
export const EXPECTED_STOPS = {
  // One text that says what the rating means; nothing of its pieces.
  'good-exclude-semantics': [WORDS, ADD],
  'good-hidden-pieces': [WORDS],
  'good-stars': [WORDS],
  // Bad examples: the defect must be audible where the web shows it.
  // The two numbers, and nothing for the stars.
  'bad-pieces': ['3.4', '(856)'],
  // One progress bar named by the pieces, its value in its name (FL-037)
  // and again as a percentage (FL-027), as C26's bars were read (FL-330).
  'bad-merged': [`${PIECES} 68 68% progress indicator`],
  // The label, then the pieces again, as one progress bar.
  'bad-not-excluded': [`${WORDS} ${PIECES} 68 68% progress indicator`],
  // The rating, and the count; no Reviews button.
  'bad-hides-control': [WORDS, 'Reviews opened: 0'],
  'bad-stale': [WORDS, ADD],
};

// The same screens after a 5-star review is added with a mouse click on
// the button, before VoiceOver starts: the good replacement follows the
// row, the stale one does not.
export const EXPECTED_AFTER_ADDING = {
  'good-exclude-semantics': [WORDS_AFTER, ADD],
  'bad-stale': [WORDS, ADD],
};

/** The stops VoiceOver reads above the "Example" heading of `slug`'s screen. */
export const screenStops = (slug) => {
  const [title, ...lines] = EXAMPLE_SCREENS[slug];
  return [`heading level 1 ${title}`, ...lines];
};

/**
 * The role a help message names: "button" for "You are currently on a
 * button, …". "text element" and "text" are both "text". VoiceOver's help
 * for a text element or a progress indicator has not been heard in any
 * recording of this project; the wording is assumed to follow the list's
 * and the button's, and the rule is tested only on made-up walks.
 */
export function helpRole(phrase) {
  const m = /^You are currently on (?:an? )?(.+?)(?:,| inside of |\.)/.exec(phrase);
  if (!m) return null;
  const role = m[1].trim();
  return role === 'text element' ? 'text' : role;
}

/**
 * The role VoiceOver spoke in a reading, from the role part of the reading
 * only, never from the element's name: "heading" for "heading level 1
 * Star rating replaced"; "list" for a list's own announcements ("list 3
 * items", "end of list"); "button" for "Add a 5-star review button";
 * "group" for "Milk empty group (1 of 3) 1 of 3"; "progress indicator" for
 * a progress bar's "… 68 68% progress indicator". A reading with none of
 * these role parts is VoiceOver's reading of plain text, which speaks no
 * role: "text" (S10's replacement, "3.4", "Reviews opened: 0"). Null for an
 * empty reading and for a help message, which allow no help after them.
 */
export function spokenRole(reading) {
  if (reading === '' || VO_HELP.test(reading)) return null;
  if (/^heading level \d+ /.test(reading)) return 'heading';
  if (/^list (?:.+ )?\d+ items?$/.test(reading) || reading === 'end of list') return 'list';
  if (/ button(?: \d+ of \d+)?$/.test(reading)) return 'button';
  if (/ (?:empty )?group \(\d+ of \d+\) \d+ of \d+$/.test(reading)) return 'group';
  if (/ \d+% progress indicator$/.test(reading)) return 'progress indicator';
  return 'text';
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
 *   title, the description, the heading, or any stop of the example. This
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
 * A stop that is VoiceOver's help message ("You are currently on …",
 * VO_HELP) is left out only when it is tied to the stop before it
 * (helpAfterStop): `positions`, the cursor's position at each stop as the
 * walk recorded it, shows the cursor had not moved, the stop before it is
 * a reading (neither empty nor help), and the role the help names ("on a
 * button") is the role spoken in that reading, from its role part only
 * (spokenRole: "heading level 1 Rating merged, not replaced" is a
 * heading's, whatever its name says). It is then VoiceOver's speech about
 * the element just judged. Any other help message is a stop like any
 * other, and since no expected stop is a help message it is wrong and
 * fails for good: one at a new position (an element nothing else was read
 * for), one naming a role the reading before it does not have, one with no
 * stop before it, and every help message in a walk with no positions. A
 * help message given in place of an element's own speech is at a new
 * position, and fails. S08's fourth recording read a list's help message
 * after its last stop (S08's spec, section 7). S10's recording of
 * 2026-11-27 captured no help message, so S10's help rule is tested only
 * on made-up walks.
 *
 * An empty stop holds the place of the stop expected there: S08's walks
 * that gave one (its second and third recordings, WebKit, the screen's
 * level 1 heading) read every later stop in its place. This is the rule
 * the principal set on 2026-11-26: an empty reading is a failed capture,
 * walked again, and a reading of the wrong words fails for good.
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
