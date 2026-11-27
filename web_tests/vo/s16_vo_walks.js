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
    'Defect: The French passage is read as English.',
  ],
  'bad-title-in-tile': [
    'Language set inside each tile', 'Bad example for Language of page and parts. Material.',
    'Defect: Each language is read as English.',
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

/** The browsers every web VoiceOver recording walks, each once. */
export const BROWSERS = ['chromium', 'webkit'];

/**
 * Judges a committed web VoiceOver transcript (the markdown
 * tool/voiceover_web.py writes) again with today's judge, from the stops
 * it recorded, never from stops rebuilt from the expectations: every walk
 * is logged whole, the screen's own stops included
 * (s16_language_page_parts_vo.spec.js). Returns the list of problems;
 * empty when the transcript is right. It is right only when:
 *
 * - it has one section for each of BROWSERS, and no other, each once;
 * - every row that starts as a walk's row does is `| \`<slug>-walk-<n>\` |
 *   <stops> (<verdict>: <reason>) |`, inside a section, for a slug of
 *   EXAMPLE_SCREENS; any other such row is malformed;
 * - each browser and example has walks 1 to n, each once, in order, so a
 *   duplicated row, a missing walk, or a row copied for another pair
 *   fails, and every browser and example pair is there;
 * - each walk before the last recorded "incomplete" and is judged so again
 *   (walked again only for a failed or short capture, with nothing wrong
 *   read), and the last recorded "complete" and is judged so again, the
 *   title, the description, and the heading included.
 *
 * The transcript records no cursor positions, so a help message in it is
 * a stop like any other, and fails.
 */
export function judgeTranscript(text) {
  const problems = [];
  const walks = new Map();
  const sections = [];
  let browser = null;
  for (const [i, line] of text.split('\n').entries()) {
    const section = /^## (.+)$/.exec(line);
    if (section) {
      browser = section[1].trim();
      if (!BROWSERS.includes(browser)) problems.push(`line ${i + 1}: unknown section "${browser}"`);
      if (sections.includes(browser)) problems.push(`line ${i + 1}: a second "${browser}" section`);
      sections.push(browser);
      continue;
    }
    if (!line.startsWith('| `')) continue;
    const row = /^\| `([a-z0-9-]+)-walk-(\d+)` \| (.*) \((complete|wrong|incomplete): (.*)\) \|$/.exec(line);
    if (!row || browser === null) {
      problems.push(`line ${i + 1}: malformed row "${line}"`);
      continue;
    }
    const [, slug, n, spoken, verdict] = row;
    if (!(slug in EXAMPLE_SCREENS)) {
      problems.push(`line ${i + 1}: unknown example "${slug}"`);
      continue;
    }
    const key = `${browser} ${slug}`;
    if (!walks.has(key)) walks.set(key, []);
    walks.get(key).push({ n: Number(n), stops: spoken === '(nothing)' ? [] : spoken.split(' / '), verdict, line: i + 1 });
  }
  for (const b of BROWSERS) if (!sections.includes(b)) problems.push(`no "${b}" section`);
  for (const b of BROWSERS) {
    for (const slug of Object.keys(EXAMPLE_SCREENS)) {
      const key = `${b} ${slug}`;
      const tries = walks.get(key);
      if (!tries) {
        problems.push(`${key}: no walk`);
        continue;
      }
      tries.forEach((t, k) => {
        if (t.n !== k + 1) problems.push(`${key}: walk ${t.n} where walk ${k + 1} was expected (line ${t.line})`);
        const last = k === tries.length - 1;
        const want = last ? 'complete' : 'incomplete';
        const again = judgeExampleWalk(t.stops, last, EXPECTED_STOPS[slug], screenStops(slug));
        if (t.verdict !== want) problems.push(`${key}: walk ${t.n} recorded "${t.verdict}", where a ${last ? 'last' : 'repeated'} walk must be "${want}"`);
        if (again.verdict !== want) problems.push(`${key}: walk ${t.n} judges "${again.verdict}" again: ${again.reason}`);
      });
    }
  }
  return problems;
}
