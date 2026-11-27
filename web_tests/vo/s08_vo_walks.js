// How web_tests/vo/s08_list_semantics_vo.spec.js judges and repeats its
// VoiceOver walks. Kept apart from the spec, with no VoiceOver and no
// browser, so that web_tests/s08_list_semantics.spec.js can test it on
// made-up walks in CI. A copy of C04's c04_vo_walks.js (not imported: that
// file is another technique's), with S08's screens; the judge is the same.

import { VO_HELP } from './vo_logic.js';

/** The heading every example screen has, as VoiceOver reads it. */
export const EXAMPLE_HEADING = 'heading level 2 Example';

/**
 * What each S08 example screen shows above its "Example" heading, as
 * VoiceOver reads it: the screen's title as a level 1 heading, the line
 * that says whether it is a good or a bad example, and a bad example's
 * defect (ExampleScreen in lib/app/screens.dart, with the titles and
 * defects of lib/techniques/s08_list_semantics/s08_list_semantics.dart). No S08
 * example is a custom solution, so no screen has the custom solution note.
 * web_tests/s08_list_semantics.spec.js checks that each screen shows these texts, so
 * that a change to them is caught.
 */
export const EXAMPLE_SCREENS = {
  'good-bulleted': ['Bulleted list', 'Good example for List semantics. Widgets layer.'],
  'good-numbered': ['Numbered list', 'Good example for List semantics. Widgets layer.'],
  'good-material': ['List of Material list tiles', 'Good example for List semantics. Material.'],
  'good-cupertino': ['Cupertino list section', 'Good example for List semantics. Cupertino.'],
  'bad-one-text': [
    'List in one text', 'Bad example for List semantics. Widgets layer.',
    'Defect: The items are read as one paragraph, not as a list.',
  ],
  'bad-no-list': [
    'Lines with no list role', 'Bad example for List semantics. Widgets layer.',
    'Defect: Nothing says that the lines are a list.',
  ],
  'bad-tile-in-item': [
    'List tiles merged into their items', 'Bad example for List semantics. Material.',
    'Defect: On the web each tile is a list item and not a button.',
  ],
  'bad-lazy-list': [
    'Long list in a ListView', 'Bad example for List semantics. Widgets layer.',
    'Defect: On Android and the web nothing says that it is a list.',
  ],
};

const GROCERIES = ['Milk', 'Eggs', 'Bread'];
const STEPS = ['1. Fork the repository', '2. Make the change', '3. Open a pull request'];

/** A list item as VoiceOver read it: "Milk empty group (1 of 3) 1 of 3". */
const item = (text, i, kind) => `${text} ${kind} (${i + 1} of 3) ${i + 1} of 3`;

// slug -> everything VoiceOver speaks (web_tests/vo/s08_list_semantics_vo.spec.js,
// which judges each walk against it; kept here so that the web tree spec
// can judge the committed transcripts with it too) after the "Example" heading, to the
// end of the screen, in order, one entry for each element its cursor stops
// on. Because every stop is listed, the lists also show what is not spoken.
export const EXPECTED_STOPS = {
  // The list with its number of items; each item with "empty group" and
  // its place, twice; then the end of the list (FL-315).
  'good-bulleted': ['list 3 items', ...GROCERIES.map((g, i) => item(g, i, 'empty group')), 'end of list'],
  'good-numbered': ['list 3 items', ...STEPS.map((s, i) => item(s, i, 'empty group')), 'end of list'],
  // Each tile a button with its place; the list items are not stops
  // (WebKit in every recording, Chromium from the second on).
  'good-material': ['list 3 items', ...GROCERIES.map((g, i) => `${g} button ${i + 1} of 3`), 'end of list', 'Chosen: none'],
  // The list named by its header.
  'good-cupertino': ['list Groceries 3 items', ...GROCERIES.map((g, i) => item(g, i, 'empty group')), 'end of list'],
  // Bad examples: the defect must be audible where the web shows it.
  // One text, no list.
  'bad-one-text': [GROCERIES.join(' ')],
  // Three texts, no list.
  'bad-no-list': GROCERIES,
  // Each tile a list item, read as a group and not as a button (FL-262).
  'bad-tile-in-item': ['list 3 items', ...GROCERIES.map((g, i) => item(g, i, 'group')), 'end of list', 'Chosen: none'],
  // No list; the orders the page holds when it opens (FL-011).
  'bad-lazy-list': Array.from({ length: 13 }, (_, i) => `Order ${i + 1}`),
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
 * The role VoiceOver spoke in a reading, from the role part of the reading
 * only, never from the element's name: "heading" for "heading level 1
 * Bulleted list"; "list" for the list's own announcements, "list 3 items",
 * "list Groceries 3 items", and "end of list"; "button" for "Milk button 1
 * of 3"; "group" for a list item read as "Milk empty group (1 of 3) 1 of 3"
 * or "Milk group (1 of 3) 1 of 3". Null for a reading with no role part,
 * such as a plain text: such a stop allows no help message after it.
 */
export function spokenRole(reading) {
  if (/^heading level \d+ /.test(reading)) return 'heading';
  if (/^list (?:.+ )?\d+ items?$/.test(reading) || reading === 'end of list') return 'list';
  if (/ button(?: \d+ of \d+)?$/.test(reading)) return 'button';
  if (/ (?:empty )?group \(\d+ of \d+\) \d+ of \d+$/.test(reading)) return 'group';
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
 *   so three such walks fail the test. An empty stop past the last expected
 *   one is not a failed capture but an element the screen does not have:
 *   it is wrong, as any stop there is.
 * - "complete": the walk reached the end and read exactly the whole screen,
 *   with no empty stop.
 *
 * A stop that is VoiceOver's help message ("You are currently on a list,
 * inside of web content. …", VO_HELP) is left out only when it is tied to
 * the stop before it (helpAfterStop): `positions`, the cursor's position at
 * each stop as the walk recorded it, shows the cursor had not moved, the
 * stop before it is a reading (neither empty nor help), and the role the
 * help names ("on a list") is the role spoken in that reading, from its
 * role part only (spokenRole: "end of list" and "list 3 items" are the
 * list's; "heading level 1 Bulleted list" is a heading's, whatever its
 * name says). It is then
 * VoiceOver's speech about the element just judged. Any other help message
 * is a stop like any other, and since no expected stop is a help message it
 * is wrong and fails for good: one at a new position (an element nothing
 * else was read for), one naming a role the reading before it does not
 * have, one with no stop before it, and every help message in a walk with
 * no positions. A help message given in place of an element's own speech
 * is at a new position, and fails. The fourth recording
 * (docs/evidence/probes/s08/voiceover-web-round4-fail.md.txt, WebKit,
 * good-numbered) read every expected stop and then the list's help message
 * after "end of list"; it recorded no positions, so its walk still judges
 * wrong.
 *
 * An empty stop holds the place of the stop expected there: the walks that
 * gave one (the second and third recordings, WebKit, the screen's level 1
 * heading; docs/evidence/probes/s08/voiceover-web-round2-fail.md.txt and
 * round 3) read every later stop in its place. This is the rule the
 * principal set on 2026-11-26: an empty reading is a failed capture, walked
 * again, and a reading of the wrong words fails for good. C04's and S06's
 * judges count an empty phrase as a wrong stop; C02's lets it stand for
 * WebKit's level 1 heading. S08's lets it stand for nothing.
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
