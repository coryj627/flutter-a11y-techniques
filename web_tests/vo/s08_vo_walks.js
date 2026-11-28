// How web_tests/vo/s08_list_semantics_vo.spec.js walks, judges and repeats
// its VoiceOver walks, and how web_tests/s08_list_semantics.spec.js judges
// the committed transcript again. Kept apart from the spec, with no VoiceOver
// and no browser, so that the web tree spec can test it on made-up walks in
// CI. The screens, the expected stops, and the help-message rule (helpRole,
// spokenRole, helpAfterStop) are S08's own; the judge (judgeExampleWalk,
// judgeWalk), the collector (collectWalk), the retry loop (runWalks) and the
// transcript judge (judgeTranscript) are a copy of S16's s16_vo_walks.js
// (read, not imported: that file is another technique's). Added to S16's, in
// S17's form (s17_vo_walks.js, on S17's branch, read, not imported): every
// walk logs the cursor's position at each stop on a row of its own
// (`-positions`), and judgeTranscript judges a help message by the rule the
// walk was judged by, and checks the end witness and each unresolved read
// against the recorded positions.

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

/** bad-lazy-list's orders, all 30 of the fixture (`orderCount` in its examples.dart). */
const ORDERS = Array.from({ length: 30 }, (_, i) => `Order ${i + 1}`);

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
  // No list. The orders the page holds when it opens, 1 to 13 (FL-011);
  // judged, in both browsers, as 1 to N for N from 13 to 30 (STOP_RANGES).
  'bad-lazy-list': ORDERS.slice(0, 13),
};

/**
 * Where how far a browser's walk reads varies between recordings, and so is
 * recorded and not judged: browser -> slug -> the range of the last order
 * read. `bad-lazy-list`, in both browsers: in the six recordings before the
 * end witness (rounds 1 to 5 and the sixth,
 * voiceover-web-before-judge-update.md.txt; no witness, no positions) its
 * walk ended after "Order 13" in Chromium and WebKit. With the witness
 * (2026-11-28, docs/evidence/probes/s08/voiceover-web-round7-fail.md.txt,
 * round8 and round9), each end witnessed, Chromium's ended after "Order 30",
 * "Order 22" and "Order 30", and WebKit's after "Order 13", "Order 13" and
 * "Order 21", VoiceOver scrolling the list as it moved. The cause was not
 * found. The page holds orders 1 to 13 when it opens (in both browsers,
 * measured without VoiceOver), and the fixture has 30. So the walk must
 * read orders 1, 2, … N, consecutive, for some N from 13 to 30, and nothing
 * after; its end witness is still required. It proves only that the first
 * thirteen orders are read with no list role, and that whatever is read
 * beyond them is consecutive orders.
 */
const LAZY_RANGE = { 'bad-lazy-list': { min: 13, max: 30 } };
export const STOP_RANGES = { chromium: LAZY_RANGE, webkit: LAZY_RANGE };

/**
 * The number of a ranged walk's last stop when that is "Order K", held
 * between the range's ends, or the range's least when the last stop is
 * anything else; null for a slug with no range in `browser`. Only the
 * reason of a wrong walk uses it (judgeByRange), and the tests, to read
 * how far a recorded walk went.
 */
export function ordersRead(slug, browser, walked = []) {
  const range = STOP_RANGES[browser]?.[slug];
  if (!range) return null;
  const m = /^Order (\d+)$/.exec(walked[walked.length - 1] ?? '');
  const n = m ? Number(m[1]) : range.min;
  return Math.min(Math.max(n, range.min), range.max);
}

/**
 * The stops `browser`'s walk of `slug` must read after the "Example"
 * heading when it reads no further than it must: EXPECTED_STOPS, or for a
 * ranged slug orders 1 to the range's least. A ranged walk is judged by
 * judgeByRange, against every N of its range.
 */
export function expectedStops(slug, browser) {
  const range = STOP_RANGES[browser]?.[slug];
  return range ? ORDERS.slice(0, range.min) : EXPECTED_STOPS[slug];
}

/**
 * Judges `walked`, a walk's stops, of `slug` in `browser` with
 * `judge(expected)`, which judges the walk against one expected list after
 * the heading (judgeWalk or judgeCollectedWalk, with the walk's own empty
 * stops, gaps, and end). For a slug with no range that list is
 * EXPECTED_STOPS. For a ranged slug every N of the range is tried, orders 1
 * to N, and the walk is:
 *
 * - "complete" if it is complete for some N;
 * - else "incomplete" if it is incomplete for some N: an empty stop holds
 *   the place of the order expected there, and across a gap the walk may
 *   have passed an order, so the walk is consistent with that N, and is
 *   walked again and never passed;
 * - else "wrong", judged against orders 1 to the N of its last stop
 *   (ordersRead): a wrong, skipped, repeated, or excess order, a walk short
 *   of the least or past the most, or anything after the last order.
 *
 * Returns the verdict with `orders`, the N (complete), the Ns it is
 * consistent with (incomplete, [least, most]), or the N it was judged
 * against (wrong), and the reason with that added; `orders` is null for a
 * slug with no range. Codex's first review of #222: N was taken from the
 * last stop alone, so a walk of orders 1 to 21 and then an empty stop was
 * judged against 13 orders and wrong for good, where it is a failed
 * capture of order 22.
 */
export function judgeByRange(slug, browser, walked, judge) {
  const range = STOP_RANGES[browser]?.[slug];
  if (!range) return { ...judge(EXPECTED_STOPS[slug]), orders: null };
  const consistent = [];
  let first = null;
  for (let n = range.min; n <= range.max; n++) {
    const judged = judge(ORDERS.slice(0, n));
    if (judged.verdict === 'complete') return { ...judged, orders: n, reason: `${judged.reason}; read to Order ${n}` };
    if (judged.verdict === 'incomplete') {
      consistent.push(n);
      first ??= judged;
    }
  }
  if (first) {
    const [a, b] = [consistent[0], consistent[consistent.length - 1]];
    return { ...first, orders: [a, b], reason: `${first.reason}; consistent with orders 1 to ${a === b ? a : `N, N from ${a} to ${b}`}` };
  }
  const n = ordersRead(slug, browser, walked);
  const judged = judge(ORDERS.slice(0, n));
  return { ...judged, orders: n, reason: `${judged.reason}; judged against orders 1 to ${n}` };
}

/**
 * Judges a collected walk of `slug` in `browser` as the VoiceOver spec
 * does: judgeCollectedWalk against its list, or for a ranged slug through
 * judgeByRange.
 */
export function judgeWalkOf(slug, browser, walk) {
  return judgeByRange(slug, browser, walk.stops, (expected) => judgeCollectedWalk(walk, expected, screenStops(slug)));
}

/** The stops VoiceOver reads above the "Example" heading of `slug`'s screen. */
export const screenStops = (slug) => {
  const [title, ...lines] = EXAMPLE_SCREENS[slug];
  return [`heading level 1 ${title}`, ...lines];
};

/**
 * The role a help message names: "list" for "You are currently on a list, …".
 * Both of VoiceOver's wordings, "You are currently on a …" and "You are
 * currently in a …" (VO_HELP); "empty group" in the second, as S08's ninth
 * recording heard it, is taken as a group (VoiceOver reads S08's
 * text-only list items as "Milk empty group (1 of 3) 1 of 3", FL-315).
 */
export function helpRole(phrase) {
  const m = /^You are currently (?:on|in) (?:an? )?(.+?)(?:,| inside of |\.)/.exec(phrase);
  return m ? m[1].trim().replace(/^empty /, '') : null;
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
 * Every row name of a transcript (`<row>-walk-<n>`), with the stops its
 * walk must read after the "Example" heading (`expected`, which
 * judgeTranscript tries, for a ranged slug, against every N of its range,
 * judgeByRange) and the screen's
 * own stops before it (`screen`): one per example.
 */
export const TRANSCRIPT_ROWS = Object.fromEntries(Object.entries(EXPECTED_STOPS)
  .map(([slug, expected]) => [slug, { expected, screen: screenStops(slug) }]));

/**
 * Judges one walk of an example screen with no gaps: `walked`, its stops in
 * order, whether the walk reached the end of the screen, `expected`,
 * everything VoiceOver must say after the "Example" heading to the end of
 * the screen, in order, `screen`, the stops the screen has before the
 * heading (screenStops), and `positions`, the cursor's position at each
 * stop, when the walk recorded them. The walk must read the whole screen:
 * `screen`, then the heading, then `expected`, every stop in its place and
 * nothing else. S08's judge, as S16's copy has it. Returns
 * `{ verdict, reason }`, the verdict one of:
 *
 * - "wrong": a stop past the last expected one, empty or not, which is
 *   looked for before anything else (an empty phrase there is an element
 *   the screen does not have, not a failed capture of one it does); a stop
 *   that READ something other than the one expected in its place; or a walk
 *   that reached the end with any expected stop not read. A walk with a
 *   wrong reading is wrong even if a capture in it also failed.
 * - "incomplete": a stop read as an empty phrase (a failed capture, which
 *   holds the place of the stop expected there), with nothing wrong read;
 *   or a walk that did not reach its end, every stop so far right (judgeWalk
 *   makes that one wrong: a walk that ran out of moves is wrong for good).
 *   No expected stop is empty, so an empty phrase never passes.
 * - "complete": the walk reached the end and read exactly the whole screen,
 *   with no empty stop.
 *
 * A help message (VO_HELP) is left out only when helpAfterStop ties it to
 * the stop before it; any other is a stop like any other, and since no
 * expected stop is a help message it is wrong.
 */
export function judgeExampleWalk(walked, reachedEnd, expected, screen = [], positions = undefined) {
  const stops = walked.filter((stop, i) => !helpAfterStop(walked, positions, i));
  const whole = [...screen, EXAMPLE_HEADING, ...expected];
  const empty = [];
  for (let i = 0; i < stops.length; i++) {
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

/** How the VoiceOver spec logs an empty phrase, and a walk with no stops. */
export const EMPTY_STOP = '(empty)';
export const NO_STOPS = '(nothing)';

/** The browsers every S08 recording walks in, each once. */
export const BROWSERS = ['chromium', 'webkit'];

/**
 * A cursor position as VoiceOver's AppleScript gives it, "left, top, right,
 * bottom" (cursorBounds in vo_helpers.js): four whole numbers. A position
 * in a transcript row that is not one is malformed.
 */
export const BOUNDS = /^-?\d+, -?\d+, -?\d+, -?\d+$/;

const ROW = /^\| `([a-z-]+)-walk-(\d+)` \| (.*) \((complete|wrong|incomplete): (.*)\) \|$/;
const END_ROW = /^\| `([a-z-]+)-walk-(\d+)-end` \| back "(.*)" at (.*) \/ forward "(.*)" at (.*) \|$/;
const UNRESOLVED_ROW = /^\| `([a-z-]+)-walk-(\d+)-unresolved` \| (.*) \|$/;
const START_ROW = /^\| `([a-z-]+)-walk-(\d+)-start` \| "(.*)" at (.*) \|$/;
const POSITIONS_ROW = /^\| `([a-z-]+)-walk-(\d+)-positions` \| (.*) \|$/;

/**
 * Judges a committed web VoiceOver transcript (docs/evidence/S08/voiceover-web.md)
 * again, from its rows alone, never from stops rebuilt from the
 * expectations. The VoiceOver spec logs every try whole, the screen's own
 * stops included, as `<row>-walk-<n>`, and with it the walk's start
 * capture (`-start`), the cursor's position at each stop (`-positions`), its
 * unresolved reads (`-unresolved`), and, when it read one, its end witness
 * (`-end`); tool/voiceover_web.py writes them under a heading per browser.
 * `<row>` is a key of TRANSCRIPT_ROWS. Returns the problems found, empty
 * when the transcript is right. S16's judgeTranscript (s16_vo_walks.js,
 * read, not imported), with S17's positions row and the checks S17's
 * judgeTranscript makes with it (s17_vo_walks.js, on S17's branch, read,
 * not imported): an unresolved read must be at the position before it, and
 * the end witness's move forward at the last stop's recorded position and
 * its move back elsewhere:
 *
 * - every table row must be one of the five kinds, in a known browser's
 *   section; a malformed one, or one outside a browser's section, is a
 *   problem; a section for an unknown browser is a problem;
 * - every browser in BROWSERS and every row in TRANSCRIPT_ROWS must have
 *   walks, numbered 1, 2, … with no gap and no repeat, at most three, and
 *   nothing else may have any; so an empty transcript fails, and so do
 *   fourteen copies of one row;
 * - every walk must have its start row, once (the capture before its first
 *   move, at cursor bounds), its positions row, once (one cursor bounds per
 *   stop), and its unresolved-reads row, once ("none", or each read "after
 *   stop K"); an unresolved read whose phrase is not empty and not the
 *   phrase of the stop it came after (or of the start, after none) hides
 *   words, and fails, and so does one after a stop the walk does not have,
 *   or at a position other than the one before it (the start's, or the
 *   stop's it came after); and the last walk its end witness row: the move
 *   back read the stop before the last, not empty, at a position other
 *   than the last stop's, and the move forward read the last stop at its
 *   recorded position; every position must be cursor bounds (BOUNDS). An earlier walk has an end row when it reached its end
 *   (the VoiceOver spec logs every witness); one without has not, and
 *   judges wrong. So a transcript with any kind of row removed fails;
 * - every walk is judged again by judgeWalk on the stops it recorded, with
 *   its positions, its gaps, and whether it was witnessed at its end: the
 *   last must be recorded complete and judge complete; every earlier one
 *   must be recorded incomplete and judge incomplete, so a wrong earlier
 *   walk, or one that ran out of moves, fails the transcript, whatever came
 *   after.
 *
 * Because the positions are recorded, a help message is judged here by the
 * rule the walk was judged by (helpAfterStop): left out only at the
 * position of the stop before it, whose spoken role is the one it names. A
 * walk whose positions row is malformed is judged with no positions, so
 * that every help message in it is a stop, and fails.
 */
export function judgeTranscript(text) {
  const problems = [];
  const walks = new Map(); // "browser row" -> Map(n -> { stops, was })
  const ends = new Map(); // "browser row n" -> the end witness
  const unresolvedRows = new Map(); // "browser row n" -> "none" or the reads
  const starts = new Map(); // "browser row n" -> the start capture
  const positionRows = new Map(); // "browser row n" -> the positions' text
  let browser = null;
  const known = (slug) => BROWSERS.includes(browser) && Object.hasOwn(TRANSCRIPT_ROWS, slug);
  for (const line of text.split('\n')) {
    const section = /^## (\S+)$/.exec(line);
    if (section) {
      browser = section[1];
      if (!BROWSERS.includes(browser)) problems.push(`a section for an unknown browser, "${browser}"`);
      continue;
    }
    if (!line.startsWith('| ') || line.startsWith('| Example |') || line.startsWith('| --- |')) continue;
    const startRow = START_ROW.exec(line);
    if (startRow) {
      const [, slug, n, phrase, position] = startRow;
      const key = `${browser} ${slug} ${n}`;
      if (!known(slug)) {
        problems.push(`a start row for an unknown browser or example: ${line}`);
      } else if (!BOUNDS.test(position)) {
        problems.push(`${browser} ${slug}: walk ${n}'s start row has a position that is not cursor bounds: ${line}`);
      } else if (starts.has(key)) {
        problems.push(`${browser} ${slug}: the start of walk ${n} appears twice`);
      } else {
        starts.set(key, { phrase, position });
      }
      continue;
    }
    const positionsRow = POSITIONS_ROW.exec(line);
    if (positionsRow) {
      const [, slug, n, shown] = positionsRow;
      const key = `${browser} ${slug} ${n}`;
      if (!known(slug)) {
        problems.push(`a positions row for an unknown browser or example: ${line}`);
      } else if (positionRows.has(key)) {
        problems.push(`${browser} ${slug}: the positions of walk ${n} appear twice`);
      } else {
        positionRows.set(key, shown);
      }
      continue;
    }
    const unresolvedRow = UNRESOLVED_ROW.exec(line);
    if (unresolvedRow) {
      const [, slug, n, reads] = unresolvedRow;
      const key = `${browser} ${slug} ${n}`;
      if (!known(slug)) {
        problems.push(`an unresolved-reads row for an unknown browser or example: ${line}`);
      } else if (unresolvedRows.has(key)) {
        problems.push(`${browser} ${slug}: the unresolved reads of walk ${n} appear twice`);
      } else {
        unresolvedRows.set(key, reads);
      }
      continue;
    }
    const end = END_ROW.exec(line);
    if (end) {
      const [, slug, n, back, backAt, forward, forwardAt] = end;
      const key = `${browser} ${slug}`;
      if (!known(slug)) {
        problems.push(`an end row for an unknown browser or example: ${line}`);
      } else if (!BOUNDS.test(backAt) || !BOUNDS.test(forwardAt)) {
        problems.push(`${key}: walk ${n}'s end row has positions that are not cursor bounds: ${line}`);
      } else if (ends.has(`${key} ${n}`)) {
        problems.push(`${key}: the end of walk ${n} appears twice`);
      } else {
        ends.set(`${key} ${n}`, { back, backAt, forward, forwardAt });
      }
      continue;
    }
    const m = ROW.exec(line);
    if (!m) {
      problems.push(`a malformed row: ${line}`);
      continue;
    }
    const [, slug, n, shown, was] = m;
    if (!BROWSERS.includes(browser)) {
      problems.push(`a row outside a browser's section: ${line}`);
      continue;
    }
    if (!Object.hasOwn(TRANSCRIPT_ROWS, slug)) {
      problems.push(`${browser}: a row for an unknown example, "${slug}"`);
      continue;
    }
    const key = `${browser} ${slug}`;
    if (!walks.has(key)) walks.set(key, new Map());
    if (walks.get(key).has(Number(n))) {
      problems.push(`${key}: walk ${n} appears twice`);
      continue;
    }
    const stops = stopsOf(shown);
    walks.get(key).set(Number(n), { stops, was });
  }
  for (const b of BROWSERS) {
    for (const [slug, { screen }] of Object.entries(TRANSCRIPT_ROWS)) {
      const key = `${b} ${slug}`;
      const tries = walks.get(key);
      if (!tries) {
        problems.push(`${key}: no walk`);
        continue;
      }
      const numbers = [...tries.keys()].sort((x, y) => x - y);
      if (numbers.some((n, i) => n !== i + 1) || numbers.length > 3) {
        problems.push(`${key}: walks numbered ${numbers.join(', ')}`);
        continue;
      }
      for (const n of numbers) {
        const { stops, was } = tries.get(n);
        const last = n === numbers.length;
        const reads = unresolvedRows.get(`${key} ${n}`);
        unresolvedRows.delete(`${key} ${n}`);
        if (reads === undefined) problems.push(`${key}: walk ${n} has no unresolved-reads row`);
        const start = starts.get(`${key} ${n}`);
        starts.delete(`${key} ${n}`);
        if (!start) problems.push(`${key}: walk ${n} has no start row`);
        const shownAt = positionRows.get(`${key} ${n}`);
        positionRows.delete(`${key} ${n}`);
        if (shownAt === undefined) problems.push(`${key}: walk ${n} has no positions row`);
        const at = shownAt === undefined ? null : positionsOf(shownAt);
        if (shownAt !== undefined && (at === null || at.length !== stops.length)) {
          problems.push(`${key}: walk ${n}'s positions row does not give cursor bounds for each of its ${stops.length} stops: ${shownAt}`);
        }
        const positions = at !== null && at.length === stops.length ? at : undefined;
        const read = reads === undefined ? [] : readsOf(reads);
        if (read === null) problems.push(`${key}: walk ${n}'s unresolved-reads row is malformed: ${reads}`);
        // An unresolved read hides no words: its phrase is empty, or the
        // phrase of the stop it came after (or of the start, after none).
        for (const r of read ?? []) {
          const before = r.after === 0 ? start?.phrase : stops[r.after - 1];
          if (r.phrase !== '' && r.phrase !== before) {
            problems.push(`${key}: walk ${n}'s unresolved read after stop ${r.after} read "${r.phrase}", where only "" or "${before}" is a gap: those words are a stop`);
          }
        }
        // An unresolved read is an unchanged read: after a stop the walk
        // has, at the position the cursor had before it (the start's, or
        // the stop's before it). S17's check (s17_vo_walks.js, read, not
        // imported).
        for (const r of read ?? []) {
          const prior = r.after === 0 ? start?.position : positions?.[r.after - 1];
          if (r.after > stops.length || (prior !== undefined && r.position !== prior)) {
            problems.push(`${key}: walk ${n} has an unresolved read that is not an unchanged one: after stop ${r.after} at ${r.position}`);
          }
        }
        const gaps = (read ?? []).map((r) => r.after);
        // The walk reached its end only if its end row is there and is a
        // witness: the move back read the stop before the last, not empty,
        // at a position other than the last stop's, and the move forward
        // read the last stop at its recorded position (S17's check, from
        // the positions row; with no usable positions row, S16's: the two
        // readings at different positions).
        const end = ends.get(`${key} ${n}`);
        ends.delete(`${key} ${n}`);
        const before = stops[stops.length - 2];
        const lastStop = stops[stops.length - 1];
        const lastAt = positions ? positions[positions.length - 1] : undefined;
        // The move back is judged by witnessBackHolds, from the positions
        // row; with no usable positions row, by S16's rule only (the stop
        // before the last, at a position other than the move forward's),
        // so a help message there then fails.
        const backHolds = Boolean(end) && (positions === undefined
          ? end.back !== '' && end.back === before && end.backAt !== end.forwardAt
          : witnessBackHolds({ phrase: end.back, position: end.backAt }, stops, positions));
        const witnessed = Boolean(end) && stops.length >= 2 && backHolds && end.forward === lastStop
          && (positions === undefined || end.forwardAt === lastAt);
        if (end && !witnessed) {
          problems.push(`${key}: walk ${n}'s end witness read back "${end.back}" at ${end.backAt} and forward "${end.forward}" at ${end.forwardAt}, where "${before}" and then "${lastStop}" at another position were expected`);
        }
        if (last && !end) problems.push(`${key}: the last walk, ${n}, has no end witness`);
        // Every walk judged again with judgeWalk, its gaps included: a wrong
        // verdict always wins, so a wrong earlier walk fails the transcript.
        // The browser's own list; where how far the walk reads varies,
        // every N of its range (judgeByRange, STOP_RANGES).
        const judged = judgeByRange(slug, b, stops,
          (expected) => judgeWalk(stops, witnessed, expected, screen, positions, gaps)).verdict;
        if (last && (was !== 'complete' || judged !== 'complete')) {
          problems.push(`${key}: the last walk, ${n}, was recorded ${was} and judges ${judged}`);
        }
        if (!last && (was !== 'incomplete' || judged !== 'incomplete')) {
          problems.push(`${key}: walk ${n}, before the last, was recorded ${was} and judges ${judged}`);
        }
      }
    }
  }
  for (const key of ends.keys()) problems.push(`${key}: an end witness for a walk that does not exist`);
  for (const key of unresolvedRows.keys()) problems.push(`${key}: an unresolved-reads row for a walk that does not exist`);
  for (const key of starts.keys()) problems.push(`${key}: a start row for a walk that does not exist`);
  for (const key of positionRows.keys()) problems.push(`${key}: a positions row for a walk that does not exist`);
  return problems;
}

/**
 * A walk's stops as its row writes them: " / " between two stops, an empty
 * phrase "(empty)", no stops "(nothing)", and in a stop every backslash
 * and "/" written with a backslash before it, so that " / " only ever
 * separates two stops. Not in S16's: S10's bad-merged reads "Rating: 3.4 /
 * 5 Reviews: 856 68 68% progress indicator", which S16's row would split
 * into two stops.
 */
export function stopsText(stops) {
  return stops.map((s) => (s === '' ? EMPTY_STOP : s.replace(/[\\/]/g, '\\$&'))).join(' / ') || NO_STOPS;
}

/** The stops of a walk row's text (stopsText), each as it was read. */
export function stopsOf(shown) {
  if (shown === NO_STOPS) return [];
  return shown.split(' / ').map((s) => (s === EMPTY_STOP ? '' : s.replace(/\\(.)/g, '$1')));
}

/** One transcript row, as the VoiceOver spec logs a walk and the tool writes it. */
export function transcriptRow(slug, n, stops, verdict, reason) {
  return `| \`${slug}-walk-${n}\` | ${stopsText(stops)} (${verdict}: ${reason}) |`;
}

// --- The walk and its end witness -----------------------------------------
//
// S16's collector (s16_vo_walks.js, read, not imported). collectWalk moves
// VoiceOver's cursor forward through a screen and keeps every stop with the
// cursor's position. Its moves and its capture are passed in, so that the
// web tree spec can drive it with made-up screens and captures.
//
// The walk begins with a capture on Back, before the first move (its start
// row), and every move, the first included, is compared with the stop
// before it, or with that start capture. A move is a stop when the cursor
// moved or a non-empty phrase other than that one was spoken, even at
// unchanged bounds; so a move that is not a stop, an unchanged read, is an
// empty phrase or a repeat, and hides no words. An unchanged read is kept,
// never dropped:
//
// - One unchanged read followed by a move that moves on is unresolved: the
//   move may have reached an element whose capture was lost (the old
//   phrase and bounds given again, or an empty phrase at the old bounds),
//   and the next capture skips past it. A walk with any unresolved read is
//   "incomplete" whatever its stops say (they may lack an element), is
//   walked again, at most three walks, and never passes. Each walk logs
//   its unresolved reads.
// - Two unchanged reads in a row look like the end of the screen, and so
//   does a capture that froze. So the end is accepted only with a witness:
//   one move back, whose fresh capture must be the stop before the last,
//   by its phrase, not empty, at a position other than the last stop's;
//   then one move forward, whose capture must be the last stop again, by
//   its phrase and its position. The move back may instead read
//   VoiceOver's help message about the stop before the last, at exactly
//   that stop's recorded position (witnessBackHolds, the principal's
//   decision of 2026-11-28). A frozen capture reads the last stop at
//   its position for the move back, an empty one reads "": either fails,
//   for good ("wrong"). Both readings are logged as the walk's end row.
//
// What the witness cannot show: that the last stop is the screen's last
// element. If the capture froze exactly at the screen's last element, or
// VoiceOver stops moving early while elements follow, the walk ends there,
// and the judge fails it only if an element it needed is missing.

/**
 * Walks forward with `next()` (one move), reading `capture()` (resolves to
 * `{ phrase, position }`) after each, from `start`, the capture before the
 * first move (`{ phrase, position }`, where the walk begins, on Back); at
 * most `max` moves. At the apparent end, moves back with `previous()` and
 * forward again with `next()`, capturing after each (the witness). Resolves
 * to `{ stops, positions, reachedEnd, witness, problem, unresolved, start }`:
 * `witness` is `{ back, forward }`, each a capture, when it was read;
 * `problem` says why the walk failed for good, or is null; `unresolved`
 * lists the unresolved reads.
 */
export async function collectWalk({ next, previous, capture, start, max = 40 }) {
  const stops = [];
  const positions = [];
  const unresolved = [];
  let position = start.position;
  let unmoved = 0;
  let pending = null;
  const done = (reachedEnd, witness, problem) => ({ stops, positions, reachedEnd, witness, problem, unresolved, start });
  for (let i = 0; i < max; i++) {
    await next();
    const { phrase, position: now } = await capture();
    // Compared with the stop before it, or with the start capture before
    // the first stop: a changed, non-empty phrase is a stop even where the
    // cursor's bounds did not change, so an unresolved read is only ever an
    // empty phrase or the previous one, and hides no words.
    const previousPhrase = stops.length > 0 ? stops[stops.length - 1] : start.phrase;
    const spokeAnew = phrase !== '' && phrase !== previousPhrase;
    if (now === position && !spokeAnew) {
      unmoved++;
      if (unmoved < 2) {
        pending = { after: stops.length, phrase, position: now };
        continue;
      }
      if (stops.length < 2) return done(false, null, 'the end is not witnessed: fewer than two stops');
      await previous();
      const back = await capture();
      await next();
      const forward = await capture();
      const witness = { back, forward };
      const before = stops[stops.length - 2];
      const last = stops[stops.length - 1];
      const lastAt = positions[positions.length - 1];
      if (!witnessBackHolds(back, stops, positions)) {
        return done(false, witness,
          `the end is not witnessed: a move back read "${back.phrase}" at ${back.position}, where "${before}" (or VoiceOver's help about it, at ${positions[positions.length - 2]}) was expected away from ${lastAt}`);
      }
      if (forward.phrase !== last || forward.position !== lastAt) {
        return done(false, witness,
          `the end is not witnessed: a move forward again read "${forward.phrase}" at ${forward.position}, where "${last}" was expected at ${lastAt}`);
      }
      return done(true, witness, null);
    }
    if (unmoved === 1 && pending) unresolved.push(pending);
    unmoved = 0;
    pending = null;
    position = now;
    stops.push(phrase);
    positions.push(now);
  }
  return done(false, null, null);
}

/**
 * Whether the end witness's move back holds, for a walk's `stops` and
 * `positions`. It must read something other than an empty phrase, at a
 * position other than the last stop's, and either:
 *
 * - the stop before the last, by its phrase (S16's rule); or
 * - VoiceOver's help message about that stop (VO_HELP, either wording),
 *   whose role (helpRole) is the role spoken in that stop's reading, at
 *   exactly the position recorded for that stop during the walk
 *   (helpAfterStop, this technique's own rule, on the stop and the move
 *   back). The principal's decision, 2026-11-28, after S08's ninth and tenth
 *   web recordings read "You are currently in a empty group." there: the
 *   position recorded during the walk ties the help to that element, and a
 *   new phrase at another position than the last stop's shows the capture
 *   is live. Such a witness shows liveness and position, not the element's
 *   words.
 *
 * Help of another role, help at any other position, an empty or a frozen
 * reading fail. Without positions, only the first form can hold.
 */
export function witnessBackHolds(back, stops, positions) {
  if (stops.length < 2 || back.phrase === '') return false;
  const before = stops[stops.length - 2];
  const lastAt = Array.isArray(positions) ? positions[positions.length - 1] : undefined;
  if (back.position === lastAt) return false;
  if (back.phrase === before) return true;
  if (!Array.isArray(positions) || positions.length !== stops.length) return false;
  return helpAfterStop([before, back.phrase], [positions[positions.length - 2], back.position], 1);
}

/**
 * Judges a collected walk: a failed witness is wrong for good; otherwise
 * judgeWalk on its stops, positions, whether it reached its end, and its
 * unresolved reads as gaps.
 */
export function judgeCollectedWalk(walk, expected, screen) {
  if (walk.problem) return { verdict: 'wrong', reason: walk.problem };
  return judgeWalk(walk.stops, walk.reachedEnd, expected, screen, walk.positions, walk.unresolved.map((u) => u.after));
}

/**
 * The reads of an unresolved-reads row's text: [] for "none", each
 * "after stop K: "phrase" at position" as `{ after, phrase, position }`
 * otherwise, or null when the text is neither.
 */
export function readsOf(text) {
  if (text === 'none') return [];
  const reads = text.split(' ; ').map((r) => /^after stop (\d+): "(.*)" at (.*)$/.exec(r));
  if (reads.some((g) => !g || !BOUNDS.test(g[3]))) return null;
  return reads.map((g) => ({ after: Number(g[1]), phrase: g[2], position: g[3] }));
}

/**
 * Judges a walk's captured stops with its gaps: `gaps` lists, for each
 * unresolved read, the number of stops captured before it ("after stop
 * K"), a place where the walk may have passed an element it never
 * captured. S16's rule, in order:
 *
 * 1. A wrong verdict always wins: the captured stops are judged even when
 *    there are gaps.
 * 2. Before the first gap the stops must be the expected list (the screen's
 *    own stops, the heading, the example's) exactly, each in its place; a
 *    stop read as an empty phrase holds the place of the stop expected
 *    there (judgeExampleWalk's empty-capture rule).
 * 3. Across a gap the next captured stop must be the next expected one (the
 *    lost read was an extra or a repeated element; which, it cannot tell)
 *    or the one after it (the lost read was the next expected one); with n
 *    gaps at one place, up to n expected stops may be passed over. Any
 *    other stop is wrong for good, and so is a stop past the expected end.
 * 4. A walk that did not reach its end (it ran out of moves) is wrong for
 *    good, with or without gaps; one that reached its end with an expected
 *    stop unread, beyond what its trailing gaps may have passed over, is
 *    wrong.
 * 5. A walk with no wrong stop and at least one gap, or one stop read as an
 *    empty phrase, is incomplete: walked again, at most three walks, and
 *    never passed. Only a walk with neither is complete.
 *
 * With no gaps this is judgeExampleWalk, help-message rule included, except
 * that a walk that did not reach its end is wrong (4). With gaps, a help
 * message left out by judgeExampleWalk's rule is left out first, and the
 * gaps are counted in the stops that remain.
 */
export function judgeWalk(walked, reachedEnd, expected, screen = [], positions = undefined, gaps = []) {
  if (gaps.length === 0) {
    const judged = judgeExampleWalk(walked, reachedEnd, expected, screen, positions);
    if (!reachedEnd && judged.verdict === 'incomplete') {
      return { verdict: 'wrong', reason: `the walk did not reach its end: ${judged.reason}` };
    }
    return judged;
  }
  const keep = walked.map((_, i) => !helpAfterStop(walked, positions, i));
  const stops = walked.filter((_, i) => keep[i]);
  const at = gaps.map((after) => keep.slice(0, after).filter(Boolean).length);
  const whole = [...screen, EXAMPLE_HEADING, ...expected];
  // Every place in `whole` the walk can be at, given what it captured.
  let places = new Set([0]);
  let empty = false;
  for (let i = 0; i < stops.length; i++) {
    const lost = at.filter((g) => g === i).length;
    if (lost > 0) {
      const wider = new Set();
      for (const c of places) for (let d = 0; d <= lost; d++) wider.add(c + d);
      places = wider;
    }
    const next = new Set();
    for (const c of places) {
      if (c >= whole.length) continue;
      if (stops[i] === '' || stops[i] === whole[c]) next.add(c + 1);
    }
    if (stops[i] === '') empty = true;
    if (next.size === 0) {
      const wanted = [...places].filter((c) => c < whole.length).map((c) => `"${whole[c]}"`);
      return {
        verdict: 'wrong',
        reason: wanted.length === 0
          ? `"${stops[i]}" was read after the last expected stop`
          : `stop ${i + 1} was "${stops[i]}" where ${wanted.join(' or ')} was expected${lost > 0 ? ', across a gap' : ''}`,
      };
    }
    places = next;
  }
  if (!reachedEnd) return { verdict: 'wrong', reason: 'the walk did not reach its end' };
  const trailing = at.filter((g) => g === stops.length).length;
  if (![...places].some((c) => whole.length - c <= trailing)) {
    const c = Math.max(...places);
    return { verdict: 'wrong', reason: `the walk reached the end with "${whole[c]}" never read` };
  }
  return {
    verdict: 'incomplete',
    reason: `${gaps.length} unresolved read${gaps.length > 1 ? 's' : ''} (after stop${gaps.length > 1 ? 's' : ''} ${gaps.join(', ')})${empty ? ' and an empty stop' : ''}, every captured stop in an expected place: an element may be missing, so the walk is walked again`,
  };
}

/** The transcript row's text for a walk's unresolved reads: "none", or each read. */
export function unresolvedText(unresolved) {
  if (unresolved.length === 0) return 'none';
  return unresolved.map((u) => `after stop ${u.after}: "${u.phrase}" at ${u.position}`).join(' ; ');
}

/** The transcript row's text for a walk's end witness. */
export function witnessText(witness) {
  if (!witness) return 'no witness';
  const side = (w) => `"${w.phrase}" at ${w.position}`;
  return `back ${side(witness.back)} / forward ${side(witness.forward)}`;
}

/** The transcript row's text for a walk's start capture. */
export function startText(start) {
  return `"${start.phrase}" at ${start.position}`;
}

/** The transcript row's text for the cursor's position at each stop of a walk. */
export function positionsText(positions) {
  return positions.join(' / ') || NO_STOPS;
}

/**
 * The positions of a positions row's text, one per stop, [] for a walk with
 * no stops; null when one of them is not cursor bounds (BOUNDS).
 */
export function positionsOf(text) {
  if (text === NO_STOPS) return [];
  const positions = text.split(' / ');
  return positions.every((p) => BOUNDS.test(p)) ? positions : null;
}

/** A walk's start row: the capture before its first move. */
export function startRow(slug, n, start) {
  return `| \`${slug}-walk-${n}-start\` | ${startText(start)} |`;
}

/** A walk's positions row: the cursor's position at each of its stops. */
export function positionsRow(slug, n, positions) {
  return `| \`${slug}-walk-${n}-positions\` | ${positionsText(positions)} |`;
}

/** A walk's end witness row, as the VoiceOver spec logs it and the tool writes it. */
export function endRow(slug, n, witness) {
  return `| \`${slug}-walk-${n}-end\` | ${witnessText(witness)} |`;
}

/** A walk's unresolved-reads row, as the VoiceOver spec logs it and the tool writes it. */
export function unresolvedRow(slug, n, unresolved) {
  return `| \`${slug}-walk-${n}-unresolved\` | ${unresolvedText(unresolved)} |`;
}
