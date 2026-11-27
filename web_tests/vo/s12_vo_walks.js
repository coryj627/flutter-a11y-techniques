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
 *   A walk that ran out of moves without reaching the end is wrong too
 *   (Codex, fourth review): with 40 moves and at most nine stops on a
 *   screen, it can only have gone on past the screen.
 * - "incomplete": a walk that reached the end with nothing wrong read in
 *   it, whose capture failed: a stop read as an empty phrase (the
 *   AppleScript read of VoiceOver's last phrase gave nothing for a move
 *   that changed the cursor's position), or a gap, an unresolved read
 *   (`gaps`, collectWalk's "after stop K"). Only such a walk may be walked
 *   again (runWalks, at most three walks, each logged), and it never
 *   passes, so three such walks fail the test. An empty stop past the last
 *   expected one is not a failed capture but an element the screen does
 *   not have: it is wrong, as any stop there is.
 * - "complete": the walk reached the end and read exactly the whole screen,
 *   with no empty stop and no gap.
 *
 * A gap does not hide a wrong stop (Codex, fourth review): the stops are
 * judged whatever the gaps. The stops before the first gap must be the
 * expected ones exactly. Across a gap after a stop in place i, the next
 * stop must be the one expected in place i + 1 (the lost read was an extra
 * or repeated element: which, cannot be told) or in place i + 2 (the lost
 * read was the one in place i + 1); anything else is wrong. The walk must
 * end at the end of the expected list: a stop past it is wrong, and so is
 * an end reached with an expected stop not read and not lost in a gap.
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
export function judgeExampleWalk(walked, reachedEnd, expected, screen = [], positions = undefined, gaps = []) {
  // VoiceOver's own help message (VO_HELP, vo_logic.js), when it is about
  // the element just read, is not a stop of the page (helpAfterStop).
  const kept = walked.map((stop, i) => !helpAfterStop(walked, positions, i));
  const stops = walked.filter((_, i) => kept[i]);
  // A gap "after stop K" of the walk is before stop K of the kept stops,
  // counted from 0.
  const gapBefore = new Set(gaps.filter((k) => k <= walked.length).map((k) => kept.slice(0, k).filter(Boolean).length));
  const whole = [...screen, EXAMPLE_HEADING, ...expected];
  const empty = [];
  // Where in `whole` the walk may be: one place, until a gap lets the lost
  // read have been an extra element (the place stays) or the expected one
  // (the place moves on by one). A stop no place allows is wrong for good.
  let places = new Set([0]);
  for (let i = 0; i < stops.length; i++) {
    if (gapBefore.has(i)) places = new Set([...places].flatMap((j) => [j, j + 1]));
    const open = [...places].filter((j) => j < whole.length).sort((x, y) => x - y);
    // A stop past the end of the screen is wrong, empty or not: an empty
    // phrase there is an element the screen does not have, not a failed
    // capture of one it does.
    if (open.length === 0) {
      return { verdict: 'wrong', reason: `"${stops[i]}" was read after the last expected stop` };
    }
    // An empty phrase holds the place of the stop expected there.
    if (stops[i] === '') empty.push(i + 1);
    const next = open.filter((j) => stops[i] === '' || stops[i] === whole[j]).map((j) => j + 1);
    if (next.length === 0) {
      return {
        verdict: 'wrong',
        reason: `stop ${i + 1} was "${stops[i]}" where ${open.map((j) => `"${whole[j]}"`).join(' or ')} was expected`,
      };
    }
    places = new Set(next);
  }
  if (!reachedEnd) {
    return { verdict: 'wrong', reason: `the walk ran out of moves after ${stops.length} stops without reaching the end of the screen` };
  }
  if (!places.has(whole.length)) {
    const at = Math.max(...places);
    return {
      verdict: 'wrong',
      reason: `the walk reached the end after ${stops.length} of the ${whole.length} expected stops; "${whole[at]}" was never read`,
    };
  }
  const failed = [];
  if (empty.length > 0) failed.push(`stop${empty.length > 1 ? 's' : ''} ${empty.join(', ')} read as an empty phrase`);
  if (gapBefore.size > 0) {
    failed.push(`${gapBefore.size} unresolved read${gapBefore.size > 1 ? 's' : ''} (a move that read no new element), so an element may be missing`);
  }
  if (failed.length > 0) {
    return { verdict: 'incomplete', reason: `the capture failed: ${failed.join('; ')}; nothing wrong read` };
  }
  return { verdict: 'complete', reason: 'the whole screen, every stop in its place' };
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

/** The browsers every S12 recording walks in. */
export const BROWSERS = ['chromium', 'webkit'];

const ROW = /^\| `([a-z-]+)-walk-(\d+)` \| (.*) \((complete|wrong|incomplete): (.*)\) \|$/;
const END_ROW = /^\| `([a-z-]+)-walk-(\d+)-end` \| back "(.*)" at (.*) \/ forward "(.*)" at (.*) \|$/;
const UNRESOLVED_ROW = /^\| `([a-z-]+)-walk-(\d+)-unresolved` \| (.*) \|$/;

/**
 * Judges a committed web VoiceOver transcript (docs/evidence/S12/voiceover-web.md)
 * again, from its rows alone. The VoiceOver spec logs every try whole, the
 * screen's own stops included, as `<slug>-walk-<n>`, and tool/voiceover_web.py
 * writes them under a heading per browser. Returns the problems found, empty
 * when the transcript is right:
 *
 * - every table row must be a walk row in a known browser's section; a
 *   malformed one, or one outside a browser's section, is a problem;
 * - every browser in BROWSERS and every example in EXPECTED_STOPS must have
 *   walks, numbered 1, 2, … with no gap and no repeat, at most three, and
 *   nothing else may have any;
 * - every walk must have its unresolved-reads row
 *   (`<slug>-walk-<n>-unresolved`, collectWalk's unresolved reads), once,
 *   well formed: "none" for the last walk;
 * - every walk is judged again by judgeExampleWalk on the stops it
 *   recorded, with nothing put back, its unresolved reads as gaps, as
 *   having reached the end: the last must be recorded complete and judge
 *   complete; every earlier one must be recorded incomplete and judge
 *   incomplete, so a wrong earlier walk fails the transcript;
 * - every walk must have its end witness row (`<slug>-walk-<n>-end`,
 *   collectWalk's witness), since a walk that is not wrong reached the
 *   end: the move back read the stop before the last, at a position other
 *   than the move forward's, which read the last stop; none may appear
 *   twice or belong to a walk that is not there. The
 *   transcript holds no cursor positions, so a help message the judge left
 *   out by its position counts as a stop here and fails: this errs toward
 *   failing.
 */
export function judgeTranscript(text) {
  const problems = [];
  const walks = new Map(); // "browser slug" -> Map(n -> { stops, was })
  const ends = new Map(); // "browser slug n" -> the end witness
  const unresolvedRows = new Map(); // "browser slug n" -> "none" or the reads
  let browser = null;
  for (const line of text.split('\n')) {
    const section = /^## (\S+)$/.exec(line);
    if (section) {
      browser = section[1];
      if (!BROWSERS.includes(browser)) problems.push(`a section for an unknown browser, "${browser}"`);
      continue;
    }
    if (!line.startsWith('| ') || line.startsWith('| Example |') || line.startsWith('| --- |')) continue;
    const unresolvedRow = UNRESOLVED_ROW.exec(line);
    if (unresolvedRow) {
      const [, slug, n, reads] = unresolvedRow;
      const key = `${browser} ${slug} ${n}`;
      if (!BROWSERS.includes(browser) || !(slug in EXPECTED_STOPS)) {
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
      if (!BROWSERS.includes(browser) || !(slug in EXPECTED_STOPS)) {
        problems.push(`an end row for an unknown browser or example: ${line}`);
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
    if (!(slug in EXPECTED_STOPS)) {
      problems.push(`${browser}: a row for an unknown example, "${slug}"`);
      continue;
    }
    const key = `${browser} ${slug}`;
    if (!walks.has(key)) walks.set(key, new Map());
    if (walks.get(key).has(Number(n))) {
      problems.push(`${key}: walk ${n} appears twice`);
      continue;
    }
    const stops = shown === NO_STOPS ? [] : shown.split(' / ').map((s) => (s === EMPTY_STOP ? '' : s));
    walks.get(key).set(Number(n), { stops, was });
  }
  for (const b of BROWSERS) {
    for (const slug of Object.keys(EXPECTED_STOPS)) {
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
        if (last && reads !== undefined && reads !== 'none') {
          problems.push(`${key}: the last walk, ${n}, had unresolved reads: ${reads}`);
        }
        const gaps = gapsOf(reads ?? 'none');
        if (gaps === null) problems.push(`${key}: walk ${n}'s unresolved reads are malformed: ${reads}`);
        // Every walk is judged on its stops with its gaps, as
        // judgeCollectedWalk judged it, and as having reached the end: a
        // walk that is not wrong reached it, and its end row shows it.
        const judged = judgeExampleWalk(stops, true, EXPECTED_STOPS[slug], screenStops(slug), undefined, gaps ?? []).verdict;
        if (last && (was !== 'complete' || judged !== 'complete')) {
          problems.push(`${key}: the last walk, ${n}, was recorded ${was} and judges ${judged}`);
        }
        if (!last && (was !== 'incomplete' || judged !== 'incomplete')) {
          problems.push(`${key}: walk ${n}, before the last, was recorded ${was} and judges ${judged}`);
        }
        const end = ends.get(`${key} ${n}`);
        ends.delete(`${key} ${n}`);
        // Every walk that is not wrong reached the end with its witness, the
        // walks before the last included.
        const before = stops[stops.length - 2];
        const lastStop = stops[stops.length - 1];
        if (!end) {
          problems.push(`${key}: walk ${n} has no end witness`);
        } else if (end.back !== before || end.forward !== lastStop || end.back === '' || end.backAt === end.forwardAt) {
          problems.push(`${key}: walk ${n}'s end witness read back "${end.back}" at ${end.backAt} and forward "${end.forward}" at ${end.forwardAt}, where "${before}" and then "${lastStop}" at another position were expected`);
        }
      }
    }
  }
  for (const key of ends.keys()) problems.push(`${key}: an end witness for a walk that does not exist`);
  for (const key of unresolvedRows.keys()) problems.push(`${key}: an unresolved-reads row for a walk that does not exist`);
  return problems;
}

/**
 * The gaps of an unresolved-reads row ("none", or `after stop K: "…" at …`
 * joined by " ; "), as the K of each; null when the row is malformed.
 */
function gapsOf(reads) {
  if (reads === 'none') return [];
  const gaps = [];
  for (const read of reads.split(' ; ')) {
    const m = /^after stop (\d+): ".*" at .+$/.exec(read);
    if (!m) return null;
    gaps.push(Number(m[1]));
  }
  return gaps;
}

/** One transcript row, as the VoiceOver spec logs a walk and the tool writes it. */
export function transcriptRow(slug, n, stops, verdict, reason) {
  const shown = stops.map((s) => (s === '' ? EMPTY_STOP : s)).join(' / ') || NO_STOPS;
  return `| \`${slug}-walk-${n}\` | ${shown} (${verdict}: ${reason}) |`;
}

// --- The walk and its end witness -----------------------------------------
//
// collectWalk moves VoiceOver's cursor forward through a screen and keeps
// every stop with the cursor's position. Its capture and move functions are
// passed in, so that the web tree spec can drive it with made-up screens and
// captures, and other techniques can copy it with this comment.
//
// A move is a stop when the cursor moved or a new, non-empty phrase was
// spoken; two moves in a row that do neither look like the end of the
// screen (the shared walk's rule, stopsToEnd in vo_logic.js). But a capture
// that froze looks the same: the phrase and the position stop changing
// while the cursor goes on to elements nobody reads. So the end is accepted
// only with a witness, read after those two moves:
//
// 1. one move back, whose fresh capture must be the stop before the last,
//    by its recorded phrase, at a position other than the last stop's;
// 2. one move forward, whose capture must be the last stop again, by its
//    phrase and its position.
//
// A frozen capture reads the last stop at the last position for the move
// back; an empty one reads "". Either fails the witness, and a failed
// witness fails the walk for good ("wrong"), not as an incomplete walk to
// try again: the empty-capture rule (an empty phrase in an expected place
// is a failed capture, walked again) is for the walk's own stops, which
// have a moved cursor to show they are new; at the witness an empty phrase
// cannot be told from a frozen capture, so it is not trusted. Both witness
// readings are logged with the walk.
//
// A single unchanged read mid-walk, a move that neither moved the cursor
// nor spoke a new phrase, followed by a move that does, is unresolved: the
// move may have reached an element whose capture was lost (stale speech
// and the old bounds, or an empty phrase), and the next capture skips
// past it. A real transient capture failure looks like that: the read came
// before VoiceOver had updated its last phrase and cursor, and the next
// move reads fresh. So it is treated as the empty-capture rule treats an
// empty phrase: a failed capture, not a wrong reading. Each unresolved
// read is a gap in the walk, after the stop it came after; the stops are
// still judged (judgeExampleWalk): a wrong stop before or after a gap is
// wrong for good, and a walk with a gap and nothing wrong is "incomplete",
// walked again, at most three walks; an incomplete walk never passes, so
// three such walks fail. Each walk logs its unresolved reads ("none", or each with the stop
// it came after, its phrase, and its position). Two unchanged reads in a
// row are still the end, with its witness.
//
// What the witness cannot show: that the last stop is the screen's last
// element. If the capture froze exactly at the screen's real last element,
// or if VoiceOver itself stops moving early (two moves that change
// nothing) while elements follow, the move back and forward read true
// stops and the walk ends there; the elements after it are then missing
// from the walk, and the judge, which needs every expected stop, fails it
// only if one of them was expected. An element that VoiceOver never moves
// to is not seen at all.

/**
 * Walks forward with `next()` (one move), reading `capture()` (resolves to
 * `{ phrase, position }`) after each, from `start` (the cursor's position
 * before the first move); at most `max` moves. At the apparent end, moves
 * back with `previous()` and forward again with `next()`, capturing after
 * each (the witness, above). Resolves to `{ stops, positions, reachedEnd,
 * witness, problem }`: `witness` is `{ back, forward }`, each a capture,
 * when it was read; `problem` says why the walk failed for good, or is
 * null.
 */
export async function collectWalk({ next, previous, capture, start, max = 40 }) {
  const stops = [];
  const positions = [];
  const unresolved = [];
  let position = start;
  let unmoved = 0;
  let pending = null;
  // Every return carries the unresolved reads, so the log shows them.
  const done = (reachedEnd, witness, problem) => ({ stops, positions, reachedEnd, witness, problem, unresolved });
  for (let i = 0; i < max; i++) {
    await next();
    const { phrase, position: now } = await capture();
    const spokeAnew = phrase !== '' && stops.length > 0 && phrase !== stops[stops.length - 1];
    if (now === position && !spokeAnew) {
      unmoved++;
      if (unmoved < 2) {
        // An unchanged read: the start of the end, or a read that lost a
        // move. Which, only the next move shows.
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
      if (back.phrase === '' || back.phrase !== before || back.position === lastAt) {
        return done(false, witness,
          `the end is not witnessed: a move back read "${back.phrase}" at ${back.position}, where "${before}" was expected away from ${lastAt}`);
      }
      if (forward.phrase !== last || forward.position !== lastAt) {
        return done(false, witness,
          `the end is not witnessed: a move forward again read "${forward.phrase}" at ${forward.position}, where "${last}" was expected at ${lastAt}`);
      }
      return done(true, witness, null);
    }
    // The walk moved on after one unchanged read: that read is unresolved.
    // The move may have reached an element that was never captured.
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
 * Judges a collected walk: a failed witness is wrong for good; otherwise
 * judgeExampleWalk on its stops, positions, and gaps (each unresolved read
 * is a gap after the stop it came after). The stops are judged whatever the
 * gaps: a wrong stop is wrong with or without them.
 */
export function judgeCollectedWalk(walk, expected, screen) {
  if (walk.problem) return { verdict: 'wrong', reason: walk.problem };
  return judgeExampleWalk(walk.stops, walk.reachedEnd, expected, screen, walk.positions,
    walk.unresolved.map((u) => u.after));
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

/** A walk's end witness row, as the VoiceOver spec logs it and the tool writes it. */
export function endRow(slug, n, witness) {
  return `| \`${slug}-walk-${n}-end\` | ${witnessText(witness)} |`;
}

/** A walk's unresolved-reads row, as the VoiceOver spec logs it and the tool writes it. */
export function unresolvedRow(slug, n, unresolved) {
  return `| \`${slug}-walk-${n}-unresolved\` | ${unresolvedText(unresolved)} |`;
}
