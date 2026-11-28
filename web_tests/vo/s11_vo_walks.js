// How web_tests/vo/s11_reading_traversal_order_vo.spec.js walks, judges and
// repeats its VoiceOver walks, and how
// web_tests/s11_reading_traversal_order.spec.js judges the committed
// transcript again. Kept apart from the spec, with no VoiceOver and no
// browser, so that the web tree spec can test it on made-up walks in CI. The
// screens, the expected stops, and the help-message rule (helpRole,
// spokenRole with the heading's level, helpAfterStop) are S11's own; the
// judge (judgeExampleWalk, judgeWalk), the collector (collectWalk), the retry
// loop (runWalks) and the transcript judge (judgeTranscript) are a copy of
// S16's s16_vo_walks.js (read, not imported: that file is another
// technique's). Added to S16's, in S17's form (s17_vo_walks.js, on S17's
// branch, read, not imported): every walk logs the cursor's position at each
// stop on a row of its own (`-positions`), and judgeTranscript judges a help
// message by the rule the walk was judged by, and checks the end witness and
// each unresolved read against the recorded positions.

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

const ROUTE = ['heading level 3 Route', 'Park at the gate.', 'Climb the ridge.', 'Walk back.', 'Save route button'];
const BRING = ['heading level 3 Bring', 'Water', 'A map', 'Save list button'];
const COUNTS = ['Route saves: 0', 'List saves: 0'];

// slug -> everything VoiceOver speaks (web_tests/vo/s11_reading_traversal_order_vo.spec.js,
// which judges each walk against it; kept here so that the web tree spec
// can judge the committed transcript with it too) after the "Example"
// heading, to the end of the screen, in order, one entry for each element
// its cursor stops on. Because every stop is listed, the lists also show
// the order. Written before any S11 recording, from the order of the
// elements in the page, which the web tree spec measures, and from how
// VoiceOver read headings, text, and buttons in earlier techniques'
// recordings; both S11 recordings read exactly these lists in Chromium and
// WebKit (docs/evidence/probes/s11/voiceover-web-round1.md.txt and
// docs/evidence/probes/s11/voiceover-web-before-judge-update.md.txt).
export const EXPECTED_STOPS = {
  // One column, then the other.
  'good-columns': [...ROUTE, ...BRING, ...COUNTS],
  'good-sort-keys': [...ROUTE, ...BRING, ...COUNTS],
  // Bad examples: the defect must be audible. Row by row, both titles
  // first, as the page's order is in Chromium at the default window.
  'bad-columns-mixed': [
    ROUTE[0], BRING[0], ROUTE[1], BRING[1], ROUTE[2], BRING[2], ROUTE[3], ROUTE[4], BRING[3], ...COUNTS,
  ],
  // The Bring title second, then the route, then the list with no title.
  'bad-key-missing': [ROUTE[0], BRING[0], ...ROUTE.slice(1), ...BRING.slice(1), ...COUNTS],
};

/**
 * Every row name of a transcript (`<row>-walk-<n>`), with the stops its
 * walk must read after the "Example" heading (`expected`) and the screen's
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

/** The browsers every S11 recording walks in, each once. */
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
 * Judges a committed web VoiceOver transcript (docs/evidence/S11/voiceover-web.md)
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
    for (const [slug, { expected, screen }] of Object.entries(TRANSCRIPT_ROWS)) {
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
        const witnessed = Boolean(end) && stops.length >= 2 && end.back === before && end.forward === lastStop
          && end.back !== '' && end.backAt !== end.forwardAt
          && (positions === undefined || (end.backAt !== lastAt && end.forwardAt === lastAt));
        if (end && !witnessed) {
          problems.push(`${key}: walk ${n}'s end witness read back "${end.back}" at ${end.backAt} and forward "${end.forward}" at ${end.forwardAt}, where "${before}" and then "${lastStop}" at another position were expected`);
        }
        if (last && !end) problems.push(`${key}: the last walk, ${n}, has no end witness`);
        // Every walk judged again with judgeWalk, its gaps included: a wrong
        // verdict always wins, so a wrong earlier walk fails the transcript.
        const judged = judgeWalk(stops, witnessed, expected, screen, positions, gaps).verdict;
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
//   its phrase and its position. A frozen capture reads the last stop at
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
