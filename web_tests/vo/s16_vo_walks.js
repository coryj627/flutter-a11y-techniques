// How web_tests/vo/s16_language_page_parts_vo.spec.js judges and repeats
// its VoiceOver walks. Kept apart from the spec, with no VoiceOver and no
// browser, so that web_tests/s16_language_page_parts.spec.js can test it on
// made-up walks in CI. A copy of S08's s08_vo_walks.js (not imported: that
// file is another technique's), with S16's screens and roles; the judge is
// the same.
//
// What a walk can show: VoiceOver's last phrase is text. Whether a part
// was spoken in another voice is not in it, so these lists judge words,
// and a passage read in French and one read in English give the same
// stop. The language is judged by web_tests/s16_language_page_parts.spec.js
// (the page's and each part's lang).

import { VO_HELP } from './vo_logic.js';

/** The heading every example screen has, as VoiceOver reads it. */
export const EXAMPLE_HEADING = 'heading level 2 Example';

/**
 * What each S16 example screen shows above its "Example" heading, as
 * VoiceOver reads it: the screen's title as a level 1 heading, the line
 * that says whether it is a good or a bad example, and a bad example's
 * defect (ExampleScreen in lib/app/screens.dart, with the titles and
 * defects of lib/techniques/s16_language_page_parts/s16_language_page_parts.dart).
 * No S16 example is a custom solution, so no screen has the custom solution
 * note. web_tests/s16_language_page_parts.spec.js checks that each screen
 * shows these texts, so that a change to them is caught.
 */
export const EXAMPLE_SCREENS = {
  'good-passage': ['Passage in another language', 'Good example for Language of page and parts. Widgets layer.'],
  'good-phrase': ['Phrase in another language', 'Good example for Language of page and parts. Widgets layer.'],
  'good-language-menu': ['Language menu', 'Good example for Language of page and parts. Material.'],
  'bad-unmarked': [
    'Passage not marked', 'Bad example for Language of page and parts. Widgets layer.',
    "Defect: The French passage has the app's language, English.",
  ],
  'bad-title-in-tile': [
    'Language set inside each tile', 'Bad example for Language of page and parts. Material.',
    "Defect: Each language's name has the app's language, English.",
  ],
  'bad-region-tag': [
    'Language with a country', 'Bad example for Language of page and parts. Widgets layer.',
    'Defect: On the web the passage is not taken as French.',
  ],
  'bad-override': [
    'Localizations.override', 'Bad example for Language of page and parts. Widgets layer.',
    'Defect: Once opened, the app is French until it is restarted.',
  ],
};

const LEAD = 'The sign at the door reads:';
const PASSAGE = 'Bienvenue à tous nos visiteurs.';
const MENU = ['Français button', 'Español button', 'Deutsch button', 'Chosen: none'];

// slug -> everything VoiceOver speaks (web_tests/vo/s16_language_page_parts_vo.spec.js,
// which judges each walk against it; kept here so that the web tree spec
// can judge the committed transcripts with it too) after the "Example"
// heading, to the end of the screen, in order, one entry for each element
// its cursor stops on. Predicted before any recording, from the page's
// elements (the web tree spec); the first recording (2026-11-27,
// docs/evidence/probes/s16/voiceover-web-round1-pass.md.txt) read every
// one as predicted, in Chromium and WebKit. The words
// are the same whatever language a stop is in.
export const EXPECTED_STOPS = {
  'good-passage': [LEAD, PASSAGE],
  'good-phrase': ['The guide said bon voyage as we left.'],
  'good-language-menu': MENU,
  'bad-unmarked': [LEAD, PASSAGE],
  'bad-title-in-tile': MENU,
  'bad-region-tag': [LEAD, PASSAGE],
  'bad-override': [LEAD, PASSAGE],
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
 * Language menu"; "button" for "Français button". Null for a reading with
 * no role part, such as a plain text: such a stop allows no help message
 * after it. These are the roles S16's screens have.
 */
export function spokenRole(reading) {
  if (/^heading level \d+ /.test(reading)) return 'heading';
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
 * A stop that is VoiceOver's help message ("You are currently on a button,
 * inside of web content. …", VO_HELP) is left out only when it is tied to
 * the stop before it (helpAfterStop): `positions`, the cursor's position at
 * each stop as the walk recorded it, shows the cursor had not moved, the
 * stop before it is a reading (neither empty nor help), and the role the
 * help names ("on a button") is the role spoken in that reading, from its
 * role part only (spokenRole: "Français button" is a button's; "heading
 * level 1 Language menu" is a heading's, whatever its name says). It is
 * then VoiceOver's speech about the element just judged. Any other help
 * message is a stop like any other, and since no expected stop is a help
 * message it is wrong and fails for good: one at a new position (an
 * element nothing else was read for), one naming a role the reading before
 * it does not have, one with no stop before it, and every help message in
 * a walk with no positions. A help message given in place of an element's
 * own speech is at a new position, and fails. S08's fourth recording
 * (docs/evidence/probes/s08/voiceover-web-round4-fail.md.txt, WebKit,
 * good-numbered) read every expected stop and then the list's help message
 * after "end of list"; it recorded no positions, so such a walk judges
 * wrong. The rule for a help message is tested only on made-up walks
 * (web_tests/s16_language_page_parts.spec.js): no S16 walk has been
 * recorded.
 *
 * An empty stop holds the place of the stop expected there: the walks that
 * gave one in S08 (its second and third recordings, WebKit, the screen's
 * level 1 heading; docs/evidence/probes/s08/voiceover-web-round2-fail.md.txt
 * and round 3) read every later stop in its place. This is the rule the
 * principal set on 2026-11-26: an empty reading is a failed capture, walked
 * again, and a reading of the wrong words fails for good.
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

/** How the VoiceOver spec logs an empty phrase, and a walk with no stops. */
export const EMPTY_STOP = '(empty)';
export const NO_STOPS = '(nothing)';

/** The browsers every S16 recording walks in, each once. */
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

/**
 * Judges a committed web VoiceOver transcript (docs/evidence/S16/voiceover-web.md)
 * again, from its rows alone, never from stops rebuilt from the
 * expectations. The VoiceOver spec logs every try whole, the screen's own
 * stops included, as `<slug>-walk-<n>`, its unresolved reads as
 * `<slug>-walk-<n>-unresolved`, and the last walk's end witness as
 * `<slug>-walk-<n>-end`; tool/voiceover_web.py writes them under a heading
 * per browser. Returns the problems found, empty when the transcript is
 * right. Written for S16 to the rules S12's judge follows (S12's
 * s12_vo_walks.js, read, not imported):
 *
 * - every table row must be one of the three kinds, in a known browser's
 *   section; a malformed one, or one outside a browser's section, is a
 *   problem; a section for an unknown browser is a problem;
 * - every browser in BROWSERS and every example in EXPECTED_STOPS must have
 *   walks, numbered 1, 2, … with no gap and no repeat, at most three, and
 *   nothing else may have any; so an empty transcript fails, and so do
 *   fourteen copies of one row;
 * - every walk is judged again by judgeExampleWalk on the stops it
 *   recorded: the last must be recorded complete and judge complete (as
 *   having reached the end); every earlier one must be recorded incomplete
 *   and judge incomplete as a walk cut short;
 * - every walk must have its unresolved-reads row, once: "none" for the
 *   last walk; an earlier walk with unresolved reads is incomplete whatever
 *   its stops say;
 * - the last walk must have its end witness row, and no other walk may
 *   have one: the move back read the stop before the last, not empty, at a
 *   position other than the move forward's, which read the last stop; both
 *   positions must be cursor bounds (BOUNDS). So a transcript with its end
 *   rows removed fails.
 *
 * The transcript holds no cursor positions for the stops, so a help
 * message the judge left out by its position counts as a stop here and
 * fails: this errs toward failing.
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
        const judged = reads !== undefined && reads !== 'none'
          ? 'incomplete'
          : judgeExampleWalk(stops, last, EXPECTED_STOPS[slug], screenStops(slug)).verdict;
        if (last && (was !== 'complete' || judged !== 'complete')) {
          problems.push(`${key}: the last walk, ${n}, was recorded ${was} and judges ${judged}`);
        }
        if (!last && (was !== 'incomplete' || judged !== 'incomplete')) {
          problems.push(`${key}: walk ${n}, before the last, was recorded ${was} and judges ${judged}`);
        }
        const end = ends.get(`${key} ${n}`);
        ends.delete(`${key} ${n}`);
        if (last) {
          const before = stops[stops.length - 2];
          const lastStop = stops[stops.length - 1];
          if (!end) {
            problems.push(`${key}: the last walk, ${n}, has no end witness`);
          } else if (end.back !== before || end.forward !== lastStop || end.back === '' || end.backAt === end.forwardAt) {
            problems.push(`${key}: walk ${n}'s end witness read back "${end.back}" at ${end.backAt} and forward "${end.forward}" at ${end.forwardAt}, where "${before}" and then "${lastStop}" at another position were expected`);
          }
        }
      }
    }
  }
  for (const key of ends.keys()) problems.push(`${key}: an end witness for a walk that is not the last, or that does not exist`);
  for (const key of unresolvedRows.keys()) problems.push(`${key}: an unresolved-reads row for a walk that does not exist`);
  return problems;
}

/** One transcript row, as the VoiceOver spec logs a walk and the tool writes it. */
export function transcriptRow(slug, n, stops, verdict, reason) {
  const shown = stops.map((s) => (s === '' ? EMPTY_STOP : s)).join(' / ') || NO_STOPS;
  return `| \`${slug}-walk-${n}\` | ${shown} (${verdict}: ${reason}) |`;
}

// --- The walk and its end witness -----------------------------------------
//
// Written for S16 to the rules of the collector S12 uses (S12's
// s12_vo_walks.js, read, not imported). collectWalk moves VoiceOver's
// cursor forward through a screen and keeps every stop with the cursor's
// position. Its moves and its capture are passed in, so that the web tree
// spec can drive it with made-up screens and captures.
//
// A move is a stop when the cursor moved or a new, non-empty phrase was
// spoken. A move that does neither, an unchanged read, is kept, never
// dropped:
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
 * `{ phrase, position }`) after each, from `start` (the cursor's position
 * before the first move); at most `max` moves. At the apparent end, moves
 * back with `previous()` and forward again with `next()`, capturing after
 * each (the witness). Resolves to `{ stops, positions, reachedEnd, witness,
 * problem, unresolved }`: `witness` is `{ back, forward }`, each a capture,
 * when it was read; `problem` says why the walk failed for good, or is
 * null; `unresolved` lists the unresolved reads.
 */
export async function collectWalk({ next, previous, capture, start, max = 40 }) {
  const stops = [];
  const positions = [];
  const unresolved = [];
  let position = start;
  let unmoved = 0;
  let pending = null;
  const done = (reachedEnd, witness, problem) => ({ stops, positions, reachedEnd, witness, problem, unresolved });
  for (let i = 0; i < max; i++) {
    await next();
    const { phrase, position: now } = await capture();
    const spokeAnew = phrase !== '' && stops.length > 0 && phrase !== stops[stops.length - 1];
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
 * Judges a collected walk: a failed witness is wrong for good; a walk with
 * an unresolved read is incomplete; otherwise judgeExampleWalk on its stops
 * and positions.
 */
export function judgeCollectedWalk(walk, expected, screen) {
  if (walk.problem) return { verdict: 'wrong', reason: walk.problem };
  if (walk.unresolved.length > 0) {
    return { verdict: 'incomplete', reason: `${unresolvedText(walk.unresolved)}: a move mid-walk read no new element and the walk moved on, so an element may be missing from it` };
  }
  return judgeExampleWalk(walk.stops, walk.reachedEnd, expected, screen, walk.positions);
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
