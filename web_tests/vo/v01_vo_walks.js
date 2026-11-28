// How web_tests/vo/v01_colour_contrast_vo.spec.js walks, judges and repeats
// its VoiceOver walks, and how web_tests/v01_colour_contrast.spec.js judges
// the committed transcript again. Kept apart from the spec, with no VoiceOver
// and no browser, so that the web tree spec can test it on made-up walks in
// CI. The screens, the expected stops, and the roles spokenRole knows are
// V01's own; everything else is a copy of S16's s16_vo_walks.js (on main)
// with the update the S08 to S12 judges have on branch
// origin/web-vo-judges-s08-s12 (s12_vo_walks.js there, read, not imported:
// both files are other techniques'): every walk logs the cursor's position
// at each stop on a row of its own (`-positions`); a stop's "/" and "\" are
// escaped in its row (stopsText), so that " / " only ever separates two
// stops; judgeTranscript judges a help message by the rule the walk was
// judged by, and checks the end witness and each unresolved read against the
// recorded positions; VoiceOver's help message is taken in both its
// wordings, "You are currently on ..." and "You are currently in ...", and
// the end witness's move back may read that help about the stop before the
// last, at exactly that stop's recorded position (witnessBackHolds).
//
// The text fields: V01's own rules, the principal's decisions of 2026-11-28
// after the first web recording (docs/evidence/probes/v01/
// voiceover-web-round1-fail.md.txt) and the fields' elements
// (docs/evidence/probes/v01/fields_web.txt). A field with a hint gets
// aria-label "Email\nRequired" and placeholder "Required" when it has DOM
// focus, which VoiceOver's cursor gives it, so VoiceOver read the same field
// "Email edit text", "Email Required edit text" or "Email Required Required
// edit text" depending on focus, once both forms one after the other at the
// same position, and on a return to the last stop (a field) read "" there.
// So, and for these stops only:
//
// - the three fields with a hint (good-material's "Email", good-cupertino's,
//   bad-cupertino-placeholder's) are marked in EXPECTED_STOPS as text fields
//   with a hint (fieldWithHint), each judged by FIELD_PATTERN in its place,
//   one stop; how many times "Required" is read is recorded, not judged.
//   bad-faint-edge's field (no hint) is marked a text field (textField), its
//   words judged exactly, for the end witness's rule only;
// - a reading that matches FIELD_PATTERN at exactly the position of the
//   stop before it, when that stop is a field with a hint, is that stop read
//   again (a re-read): not a stop; it stays in the walk's row, and its
//   position is written "re-read <bounds>" on the walk's positions row
//   (positionsText, walkReadings), from which judgeTranscript reads it back;
// - the end witness, when the last stop is a marked field: the move forward
//   may read an empty phrase or another form of that stop, at exactly its
//   recorded position (witnessForwardHolds); the move back may read the stop
//   before the last in its other field form only if that stop is a field
//   with a hint, at exactly its recorded position (witnessBackHolds).
//
// Every other stop is judged exactly as before.
//
// What a walk can show: VoiceOver's last phrase is text. A colour is drawn,
// not spoken, so no V01 defect is in it: these lists judge words, and a
// bad example's controls are expected to read as a good example's do. The
// contrast is judged by web_tests/v01_colour_contrast.spec.js, from
// Chromium's screenshots.

/**
 * How VoiceOver's own help message for the element under its cursor starts,
 * in both its wordings: "You are currently on a button, …", and "You are
 * currently in a empty group.", first captured in S08's ninth web recording
 * (2026-11-28), which the principal decided is the same kind of message.
 * Defined here, not taken from vo_logic.js, whose VO_HELP on main has only
 * the first wording (the second is on branch origin/web-vo-judges-s08-s12);
 * the VoiceOver spec tests with this one.
 */
export const VO_HELP = /^You are currently (?:on|in) /;

/**
 * A phrase as the walk records it: every run of white space, a line break
 * included, one space, and none at either end. VoiceOver's last phrase,
 * read over AppleScript, comes so already (runAppleScript in vo_logic.js);
 * the phrase Guidepup logs is made so in the VoiceOver spec. The Cupertino
 * fields' names hold a line break ("Email\nRequired", their aria-label), and
 * a line break in a phrase would cut the walk's console row in two:
 * tool/voiceover_web.py reads each row to the end of its line only.
 */
export const spokenText = (raw) => String(raw).replace(/\s+/g, ' ').trim();

/** The heading every example screen has, as VoiceOver reads it. */
export const EXAMPLE_HEADING = 'heading level 2 Example';

/**
 * What each V01 example screen shows above its "Example" heading, as
 * VoiceOver reads it: the screen's title as a level 1 heading, the line
 * that says whether it is a good or a bad example, and a bad example's
 * defect (ExampleScreen in lib/app/screens.dart, with the titles and
 * defects of lib/techniques/v01_colour_contrast/v01_colour_contrast.dart).
 * No V01 example is a custom solution, so no screen has the custom solution
 * note. web_tests/v01_colour_contrast.spec.js checks that each screen
 * shows these texts, so that a change to them is caught.
 */
export const EXAMPLE_SCREENS = {
  'good-material': ["Material form at the theme's defaults", 'Good example for Colour contrast. Material.'],
  'good-cupertino': ['Cupertino field with stronger greys', 'Good example for Colour contrast. Cupertino.'],
  'good-caption': ['Caption on a bar of its own', 'Good example for Colour contrast. Material.'],
  'good-selection': ['Choice shown by a shape', 'Good example for Colour contrast. Material.'],
  'bad-cupertino-placeholder': [
    'Default Cupertino placeholder', 'Bad example for Colour contrast. Cupertino.',
    'Defect: The placeholder is too faint to read.',
  ],
  'bad-caption': [
    'Caption straight on the picture', 'Bad example for Colour contrast. Material.',
    'Defect: The caption fades into the pale part of the picture.',
  ],
  'bad-colour-only': [
    'Choice shown by colour alone', 'Bad example for Colour contrast. Material.',
    'Defect: The chosen view differs from the others only by colour.',
  ],
  'bad-faint-edge': [
    'Field with a faint edge', 'Bad example for Colour contrast. Material.',
    "Defect: The field's edge is too faint to see where it is.",
  ],
};

/**
 * How a text field with a hint may be read, after its white space is made
 * single spaces (spokenText): "Email", "Required" none, once or twice, then
 * "edit text". The principal's decision of 2026-11-28: VoiceOver read
 * "Email Required edit text" for a Cupertino field without focus, whose
 * aria-label is "Email\nRequired", and "Email Required Required edit text"
 * for a field with DOM focus, which also has placeholder "Required"; a
 * Material field without focus has aria-label "Email".
 */
export const FIELD_PATTERN = /^Email( Required){0,2} edit text$/;

/** Whether `reading` is a form of a text field with a hint (FIELD_PATTERN). */
export const fieldForm = (reading) => FIELD_PATTERN.test(spokenText(reading));

/**
 * A stop of an expected list that is a text field with a hint (a
 * field-pattern stop): judged by FIELD_PATTERN, not by its words. `sample` is
 * a reading the first recording heard for it, for made-up walks only.
 */
const fieldWithHint = (sample) => Object.freeze({ kind: 'text field with a hint', pattern: FIELD_PATTERN, sample });

/**
 * A stop of an expected list that is a text field with no hint: its words
 * are judged exactly (`text`); the mark matters only to the end witness's
 * move forward (witnessForwardHolds).
 */
const textField = (text) => Object.freeze({ kind: 'text field', text, sample: text });

/** Whether an expected stop is a text field with a hint (fieldWithHint). */
export const isFieldWithHint = (entry) => entry !== null && typeof entry === 'object' && entry.kind === 'text field with a hint';

/** Whether an expected stop is marked a text field, with a hint or not. */
export const isMarkedField = (entry) => isFieldWithHint(entry)
  || (entry !== null && typeof entry === 'object' && entry.kind === 'text field');

/**
 * Whether `reading` is the expected stop `entry`: a plain stop and a text
 * field with no hint by their words exactly, a text field with a hint by
 * FIELD_PATTERN.
 */
export function matchesStop(reading, entry) {
  if (isFieldWithHint(entry)) return fieldForm(reading);
  if (isMarkedField(entry)) return reading === entry.text;
  return reading === entry;
}

/** A reading of an expected stop, for made-up walks: its words, or a field's sample. */
export const readingOf = (entry) => (typeof entry === 'string' ? entry : entry.sample);

/** An expected stop as a judge's reason names it. */
export const stopLabel = (entry) => (isFieldWithHint(entry)
  ? `a text field with a hint, ${entry.pattern}` : `"${readingOf(entry)}"`);

// The Cupertino field's name is its Semantics label and its placeholder,
// "Email\nRequired" in the page (aria-label, with a line break); Chromium's
// tree names it "Email Required" (web_tests/v01_colour_contrast.spec.js),
// and the walk records the line break as a space (spokenText). Without
// focus VoiceOver read it "Email Required edit text", with focus "Email
// Required Required edit text" (the first recording).
const CUPERTINO_FIELD = fieldWithHint('Email Required edit text');
// good-selection's RadioGroup: the group is named by its "Calendar view"
// text, and each radio button not chosen has the description "Not
// selected" (aria-description), as F08's group was read.
const CHOICE = [
  'Calendar view radio group', 'Day Not selected radio button, 1 of 3', 'Week selected radio button, 2 of 3',
  'Month Not selected radio button, 3 of 3', 'end of Calendar view radio group',
];

// slug -> everything VoiceOver speaks (web_tests/vo/v01_colour_contrast_vo.spec.js,
// which judges each walk against it; kept here so that the web tree spec
// can judge the committed transcript with it too) after the "Example"
// heading, to the end of the screen, in order, one entry for each element
// its cursor stops on. Predicted before any recording, from the page's
// elements and Chromium's accessibility tree (the web tree spec), and from
// what earlier recordings read for the same kinds of element: F01's "Email
// edit text", F07's "... unchecked checkbox", F08's radio group and radio
// buttons, and C02's "Bold current item button" for a button with
// aria-current="true". The first recording (2026-11-28,
// docs/evidence/probes/v01/voiceover-web-round1-fail.md.txt) read every
// stop as predicted but the three fields with a hint, which it read in two
// forms by focus; those three are marked fieldWithHint and judged by
// FIELD_PATTERN, and bad-faint-edge's field is marked textField (the
// principal's decisions of 2026-11-28; this file's header).
export const EXPECTED_STOPS = {
  'good-material': [
    'We reply within two days.', fieldWithHint('Email Required Required edit text'),
    'Send me updates unchecked checkbox', 'Send button',
  ],
  'good-cupertino': [CUPERTINO_FIELD, 'Send button'],
  'good-caption': ['Harbour'],
  'good-selection': CHOICE,
  'bad-cupertino-placeholder': [CUPERTINO_FIELD],
  'bad-caption': ['Harbour'],
  'bad-colour-only': ['Calendar view', 'Day button', 'Week current item button', 'Month button'],
  'bad-faint-edge': [textField('Email edit text')],
};

/** The stops VoiceOver reads above the "Example" heading of `slug`'s screen. */
export const screenStops = (slug) => {
  const [title, ...lines] = EXAMPLE_SCREENS[slug];
  return [`heading level 1 ${title}`, ...lines];
};

/**
 * Everything a walk must read, in order: `screen` (screenStops), the
 * "Example" heading, then `expected`. collectWalk takes it to know which
 * stops are marked text fields (its re-reads and its end witness).
 */
export const wholeScreen = (expected, screen = []) => [...screen, EXAMPLE_HEADING, ...expected];

/**
 * The role a help message names: "button" for "You are currently on a
 * button, …". Both of VoiceOver's wordings, "You are currently on a …" and
 * "You are currently in a …" (VO_HELP); "empty group" in the second, as
 * S08's ninth recording heard it, is taken as a group.
 */
export function helpRole(phrase) {
  const m = /^You are currently (?:on|in) (?:an? )?(.+?)(?:,| inside of |\.)/.exec(phrase);
  return m ? m[1].trim().replace(/^empty /, '') : null;
}

/**
 * The role VoiceOver spoke in a reading, from the role part of the reading
 * only, never from the element's name: "heading" for "heading level 1
 * Choice shown by a shape"; "button" for "Week current item button";
 * "checkbox" for "Send me updates unchecked checkbox"; "radio button" for
 * "Day Not selected radio button, 1 of 3"; "radio group" for "Calendar view
 * radio group"; "text field", the words of VoiceOver's help message, for
 * "Email edit text". Null for a reading with no role part, such as a plain
 * text, and for the end of a group ("end of Calendar view radio group"):
 * such a stop allows no help message after it. These are the roles V01's
 * lists expect.
 */
export function spokenRole(reading) {
  if (/^heading level \d+ /.test(reading)) return 'heading';
  if (/^end of /.test(reading)) return null;
  if (/ button$/.test(reading)) return 'button';
  if (/ checkbox$/.test(reading)) return 'checkbox';
  if (/ radio button, \d+ of \d+$/.test(reading)) return 'radio button';
  if (/ radio group$/.test(reading)) return 'radio group';
  if (/ edit text$/.test(reading)) return 'text field';
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
 *
 * An expected stop is matched by matchesStop: a text field with a hint by
 * FIELD_PATTERN, every other stop by its words exactly. `rereads` lists the
 * walk's re-reads (`{ after, phrase, position }`, collectWalk): each must
 * hold by rereadProblem, and the stop it re-reads must be judged in the
 * place of a text field with a hint; otherwise the walk is wrong. A re-read
 * is not a stop.
 */
export function judgeExampleWalk(walked, reachedEnd, expected, screen = [], positions = undefined, rereads = []) {
  const keep = walked.map((_, i) => !helpAfterStop(walked, positions, i));
  const stops = walked.filter((_, i) => keep[i]);
  const whole = wholeScreen(expected, screen);
  const reread = rereadPlaces(walked, positions, keep, rereads);
  if (typeof reread === 'string') return { verdict: 'wrong', reason: reread };
  const empty = [];
  for (let i = 0; i < stops.length; i++) {
    if (i >= whole.length) {
      return { verdict: 'wrong', reason: `"${stops[i]}" was read after the last expected stop` };
    }
    if (reread.has(i) && !isFieldWithHint(whole[i])) {
      return { verdict: 'wrong', reason: `stop ${i + 1}, "${stops[i]}", was read again at its position, where ${stopLabel(whole[i])}, no text field with a hint, was expected` };
    }
    if (stops[i] === '') {
      empty.push(i + 1);
      continue;
    }
    if (!matchesStop(stops[i], whole[i])) {
      return { verdict: 'wrong', reason: `stop ${i + 1} was "${stops[i]}" where ${stopLabel(whole[i])} was expected` };
    }
  }
  if (reachedEnd && stops.length < whole.length) {
    return {
      verdict: 'wrong',
      reason: `the walk reached the end after ${stops.length} of the ${whole.length} expected stops; ${stopLabel(whole[stops.length])} was never read`,
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
 * Why a re-read `r` (`{ after, phrase, position }`: read after stop `after`
 * of `walked`, counted from 1) is not one, or null when it is: the stop it
 * follows must be a stop of the walk (not a help message left out), read
 * in a form of a text field with a hint (fieldForm), and the re-read must
 * be such a form too, at exactly the position recorded for that stop
 * (`positions`, one per stop of `walked`). With no positions it cannot be
 * shown, and is not one. The principal's decision 3 of 2026-11-28.
 */
export function rereadProblem(walked, positions, keep, r) {
  const k = r.after;
  if (!Number.isInteger(k) || k < 1 || k > walked.length || !keep[k - 1]) {
    return `a re-read "${r.phrase}" after stop ${k}, which the walk does not have`;
  }
  if (!fieldForm(walked[k - 1])) {
    return `a re-read "${r.phrase}" after stop ${k}, "${walked[k - 1]}", which is not read as a text field with a hint`;
  }
  if (!fieldForm(r.phrase)) {
    return `a re-read "${r.phrase}" after stop ${k}, which is not a form of a text field with a hint (${FIELD_PATTERN})`;
  }
  if (!Array.isArray(positions) || positions.length !== walked.length || positions[k - 1] !== r.position) {
    return `a re-read "${r.phrase}" after stop ${k} at ${r.position}, not at that stop's recorded position`;
  }
  return null;
}

/**
 * The places, among the stops that `keep` keeps, of the stops `rereads`
 * re-read (a Set of indices), or the reason one of them is not a re-read
 * (rereadProblem), as a string.
 */
function rereadPlaces(walked, positions, keep, rereads) {
  const places = new Set();
  for (const r of rereads) {
    const problem = rereadProblem(walked, positions, keep, r);
    if (problem) return problem;
    places.add(keep.slice(0, r.after).filter(Boolean).length - 1);
  }
  return places;
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

/** The browsers every V01 recording walks in, each once. */
export const BROWSERS = ['chromium', 'webkit'];

/**
 * A cursor position as VoiceOver's AppleScript gives it, "left, top, right,
 * bottom" (cursorBounds in vo_helpers.js): four whole numbers. A position
 * in a transcript row that is not one is malformed.
 */
export const BOUNDS = /^-?\d+, -?\d+, -?\d+, -?\d+$/;

/**
 * How the positions row writes a re-read's position (collectWalk): "re-read
 * " before its cursor bounds, in the re-read's place among the walk row's
 * readings.
 */
export const REREAD = 're-read ';
export const rereadAt = (position) => `${REREAD}${position}`;

const ROW = /^\| `([a-z-]+)-walk-(\d+)` \| (.*) \((complete|wrong|incomplete): (.*)\) \|$/;
const END_ROW = /^\| `([a-z-]+)-walk-(\d+)-end` \| back "(.*)" at (.*) \/ forward "(.*)" at (.*) \|$/;
const UNRESOLVED_ROW = /^\| `([a-z-]+)-walk-(\d+)-unresolved` \| (.*) \|$/;
const START_ROW = /^\| `([a-z-]+)-walk-(\d+)-start` \| "(.*)" at (.*) \|$/;
const POSITIONS_ROW = /^\| `([a-z-]+)-walk-(\d+)-positions` \| (.*) \|$/;

/**
 * Judges a committed web VoiceOver transcript (docs/evidence/V01/voiceover-web.md)
 * again, from its rows alone, never from stops rebuilt from the
 * expectations. The VoiceOver spec logs every try whole, the screen's own
 * stops included, as `<row>-walk-<n>`, and with it the walk's start
 * capture (`-start`), the cursor's position at each stop (`-positions`), its
 * unresolved reads (`-unresolved`), and, when it read one, its end witness
 * (`-end`); tool/voiceover_web.py writes them under a heading per browser.
 * `<row>` is a key of TRANSCRIPT_ROWS. Returns the problems found, empty
 * when the transcript is right. S16's judgeTranscript (s16_vo_walks.js),
 * as the S08 to S12 judge update has it (s12_vo_walks.js on branch
 * origin/web-vo-judges-s08-s12, which took S17's positions row and the
 * checks S17's judgeTranscript makes with it; each read, not imported): an
 * unresolved read must be at the position before it, and
 * the end witness's move forward at the last stop's recorded position and
 * its move back elsewhere:
 *
 * - every table row must be one of the five kinds, in a known browser's
 *   section; a malformed one, or one outside a browser's section, is a
 *   problem; a section for an unknown browser is a problem;
 * - every browser in BROWSERS and every row in TRANSCRIPT_ROWS must have
 *   walks, numbered 1, 2, … with no gap and no repeat, at most three, and
 *   nothing else may have any; so an empty transcript fails, and so do
 *   sixteen copies of one row;
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
 *
 * The text fields (this file's header), from the rows alone: the walk row
 * holds every reading, re-reads included; a re-read is a reading whose
 * position the positions row writes "re-read <bounds>" (REREAD), and only
 * such a reading is one; it must hold by rereadProblem (a form of a text
 * field with a hint, at exactly the recorded position of the stop before
 * it, itself such a form) and that stop must be judged in the place of a
 * text field with a hint (judgeWalk), or the walk is wrong. A reading the
 * positions row does not mark is a stop, so a re-read missing from the
 * positions row is a second stop, and fails; with no usable positions row
 * no reading is a re-read. An unresolved read may repeat the stop's
 * re-reads as well as the stop. The end witness is judged by
 * witnessBackHolds and witnessForwardHolds with the row's whole screen, as
 * collectWalk judged it; with no usable positions row, by S16's rule only.
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
      const all = wholeScreen(expected, screen);
      for (const n of numbers) {
        const { stops: readings, was } = tries.get(n);
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
        if (shownAt !== undefined && (at === null || at.length !== readings.length)) {
          problems.push(`${key}: walk ${n}'s positions row does not give cursor bounds for each of its ${readings.length} readings: ${shownAt}`);
        }
        const usable = at !== null && at.length === readings.length;
        // The re-reads, only where the positions row marks them; every
        // other reading is a stop.
        const { stops, positions, rereads } = usable
          ? splitReadings(readings, at) : { stops: readings, positions: undefined, rereads: [] };
        const read = reads === undefined ? [] : readsOf(reads);
        if (read === null) problems.push(`${key}: walk ${n}'s unresolved-reads row is malformed: ${reads}`);
        // An unresolved read hides no words: its phrase is empty, or the
        // phrase of the stop it came after (or of the start, after none),
        // or of one of that stop's re-reads.
        for (const r of read ?? []) {
          const before = r.after === 0 ? start?.phrase : stops[r.after - 1];
          const heard = [before, ...rereads.filter((x) => x.after === r.after).map((x) => x.phrase)];
          if (r.phrase !== '' && !heard.includes(r.phrase)) {
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
        // The move back and the move forward are judged by
        // witnessBackHolds and witnessForwardHolds, from the positions row
        // and with the row's whole screen (its marked text fields), as
        // collectWalk judged them; with no usable positions row, by S16's
        // rule only (the stop before the last, at a position other than the
        // move forward's, then the last stop's words), so a help message, a
        // field's other form, or an empty phrase there then fails.
        const backHolds = Boolean(end) && (positions === undefined
          ? end.back !== '' && end.back === before && end.backAt !== end.forwardAt
          : witnessBackHolds({ phrase: end.back, position: end.backAt }, stops, positions, all));
        const forwardHolds = Boolean(end) && (positions === undefined
          ? end.forward === lastStop
          : witnessForwardHolds({ phrase: end.forward, position: end.forwardAt }, stops, positions, all));
        const witnessed = Boolean(end) && stops.length >= 2 && backHolds && forwardHolds;
        if (end && !witnessed) {
          problems.push(`${key}: walk ${n}'s end witness read back "${end.back}" at ${end.backAt} and forward "${end.forward}" at ${end.forwardAt}, where "${before}" and then "${lastStop}" at another position were expected`);
        }
        if (last && !end) problems.push(`${key}: the last walk, ${n}, has no end witness`);
        // Every walk judged again with judgeWalk, its gaps and re-reads
        // included: a wrong verdict always wins, so a wrong earlier walk
        // fails the transcript.
        const judged = judgeWalk(stops, witnessed, expected, screen, positions, gaps, rereads).verdict;
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
// - V01's text fields (this file's header), given the screen's whole
//   expected list (`whole`): a reading that matches FIELD_PATTERN, at
//   exactly the position of the stop before it, read itself in such a form,
//   on a screen with a text field with a hint, is a re-read, kept apart from
//   the stops (`rereads`) and compared with like a stop for the next move;
//   and the witness is judged by witnessBackHolds and witnessForwardHolds
//   with `whole`. Without `whole`, S16's rules exactly.
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
 * forward again with `next()`, capturing after each (the witness). `whole`
 * is the screen's whole expected list (wholeScreen), for V01's text-field
 * rules; without it, none apply. Resolves to `{ stops, positions,
 * reachedEnd, witness, problem, unresolved, rereads, start }`: `witness` is
 * `{ back, forward }`, each a capture, when it was read; `problem` says why
 * the walk failed for good, or is null; `unresolved` lists the unresolved
 * reads; `rereads` the re-reads, each `{ after, phrase, position }`, read
 * after stop `after` (counted from 1).
 */
export async function collectWalk({ next, previous, capture, start, max = 40, whole = undefined }) {
  const stops = [];
  const positions = [];
  const unresolved = [];
  const rereads = [];
  const rereading = Array.isArray(whole) && whole.some(isFieldWithHint);
  let position = start.position;
  // The last phrase read at the current stop: its reading, or its latest
  // re-read; the start's before the first stop.
  let heard = start.phrase;
  let unmoved = 0;
  let pending = null;
  const done = (reachedEnd, witness, problem) => ({ stops, positions, reachedEnd, witness, problem, unresolved, rereads, start });
  for (let i = 0; i < max; i++) {
    await next();
    const { phrase, position: now } = await capture();
    // Compared with the stop before it (or its latest re-read), or with the
    // start capture before the first stop: a changed, non-empty phrase is a
    // stop even where the cursor's bounds did not change, so an unresolved
    // read is only ever an empty phrase or the previous one, and hides no
    // words.
    const spokeAnew = phrase !== '' && phrase !== heard;
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
      if (!witnessBackHolds(back, stops, positions, whole)) {
        return done(false, witness,
          `the end is not witnessed: a move back read "${back.phrase}" at ${back.position}, where "${before}" (or VoiceOver's help about it, at ${positions[positions.length - 2]}) was expected away from ${lastAt}`);
      }
      if (!witnessForwardHolds(forward, stops, positions, whole)) {
        return done(false, witness,
          `the end is not witnessed: a move forward again read "${forward.phrase}" at ${forward.position}, where "${last}" was expected at ${lastAt}`);
      }
      return done(true, witness, null);
    }
    if (unmoved === 1 && pending) unresolved.push(pending);
    unmoved = 0;
    pending = null;
    heard = phrase;
    // A text field with a hint read again where it is, in another form: not
    // a stop (the principal's decision 3 of 2026-11-28).
    if (rereading && now === position && stops.length > 0 && fieldForm(stops[stops.length - 1]) && fieldForm(phrase)) {
      rereads.push({ after: stops.length, phrase, position: now });
      continue;
    }
    position = now;
    stops.push(phrase);
    positions.push(now);
  }
  return done(false, null, null);
}

/**
 * Whether the end witness's move forward holds, for a walk's `stops` and
 * `positions`, on a screen whose whole expected list is `whole`
 * (wholeScreen): it must be at exactly the position recorded for the last
 * stop, and read the last stop's phrase (S16's rule). When the screen's
 * last expected stop is a marked text field and the walk's last stop is it
 * (matchesStop), it may instead read an empty phrase, or, for a text field
 * with a hint, another form of it (FIELD_PATTERN). The principal's decision
 * 4 of 2026-11-28: the first recording's moves forward onto a field read ""
 * at its exact position, and a field with a hint read in either form. No
 * other last stop has this leniency; without `whole` or positions, none.
 */
export function witnessForwardHolds(forward, stops, positions, whole = undefined) {
  if (stops.length < 1 || !Array.isArray(positions) || positions.length !== stops.length) return false;
  const last = stops[stops.length - 1];
  if (forward.position !== positions[positions.length - 1]) return false;
  if (forward.phrase === last) return true;
  const entry = Array.isArray(whole) ? whole[whole.length - 1] : undefined;
  if (!isMarkedField(entry) || !matchesStop(last, entry)) return false;
  return forward.phrase === '' || (isFieldWithHint(entry) && fieldForm(forward.phrase));
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
 * - when the screen's stop before the last (in `whole`, wholeScreen) is a
 *   text field with a hint and the walk's stop before the last is it
 *   (matchesStop): another form of it (FIELD_PATTERN), at exactly the
 *   position recorded for that stop. The principal's decision 4 of
 *   2026-11-28, for good-cupertino's Chromium walk in the first recording,
 *   whose move back read "Email Required Required edit text" where the walk
 *   had read "Email Required edit text".
 *
 * Help of another role, help at any other position, an empty or a frozen
 * reading fail, and so does a field's other form at any other position or
 * for any other stop. Without positions, only the first form can hold.
 */
export function witnessBackHolds(back, stops, positions, whole = undefined) {
  if (stops.length < 2 || back.phrase === '') return false;
  const before = stops[stops.length - 2];
  const lastAt = Array.isArray(positions) ? positions[positions.length - 1] : undefined;
  if (back.position === lastAt) return false;
  if (back.phrase === before) return true;
  if (!Array.isArray(positions) || positions.length !== stops.length) return false;
  const entry = Array.isArray(whole) && whole.length >= 2 ? whole[whole.length - 2] : undefined;
  if (isFieldWithHint(entry) && matchesStop(before, entry) && fieldForm(back.phrase)) {
    return back.position === positions[positions.length - 2];
  }
  return helpAfterStop([before, back.phrase], [positions[positions.length - 2], back.position], 1);
}

/**
 * Judges a collected walk: a failed witness is wrong for good; otherwise
 * judgeWalk on its stops, positions, whether it reached its end, its
 * unresolved reads as gaps, and its re-reads.
 */
export function judgeCollectedWalk(walk, expected, screen) {
  if (walk.problem) return { verdict: 'wrong', reason: walk.problem };
  return judgeWalk(walk.stops, walk.reachedEnd, expected, screen, walk.positions, walk.unresolved.map((u) => u.after),
    walk.rereads ?? []);
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
 *
 * Every expected stop is matched by matchesStop (a text field with a hint
 * by FIELD_PATTERN), and `rereads` are judged as judgeExampleWalk judges
 * them: each must hold by rereadProblem, and the stop it re-reads may be
 * placed only where a text field with a hint is expected.
 */
export function judgeWalk(walked, reachedEnd, expected, screen = [], positions = undefined, gaps = [], rereads = []) {
  if (gaps.length === 0) {
    const judged = judgeExampleWalk(walked, reachedEnd, expected, screen, positions, rereads);
    if (!reachedEnd && judged.verdict === 'incomplete') {
      return { verdict: 'wrong', reason: `the walk did not reach its end: ${judged.reason}` };
    }
    return judged;
  }
  const keep = walked.map((_, i) => !helpAfterStop(walked, positions, i));
  const stops = walked.filter((_, i) => keep[i]);
  const reread = rereadPlaces(walked, positions, keep, rereads);
  if (typeof reread === 'string') return { verdict: 'wrong', reason: reread };
  const at = gaps.map((after) => keep.slice(0, after).filter(Boolean).length);
  const whole = wholeScreen(expected, screen);
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
      if (reread.has(i) && !isFieldWithHint(whole[c])) continue;
      if (stops[i] === '' || matchesStop(stops[i], whole[c])) next.add(c + 1);
    }
    if (stops[i] === '') empty = true;
    if (next.size === 0) {
      const wanted = [...places].filter((c) => c < whole.length).map((c) => stopLabel(whole[c]));
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
    return { verdict: 'wrong', reason: `the walk reached the end with ${stopLabel(whole[c])} never read` };
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

/**
 * The transcript row's text for the cursor's position at each reading of a
 * walk: a stop's bounds, or a re-read's written "re-read <bounds>"
 * (rereadAt; walkReadings makes the list).
 */
export function positionsText(positions) {
  return positions.join(' / ') || NO_STOPS;
}

/**
 * The positions of a positions row's text, one per reading of the walk row,
 * each cursor bounds (BOUNDS), or "re-read " and cursor bounds for a
 * re-read; [] for a walk with no readings; null when one of them is
 * neither.
 */
export function positionsOf(text) {
  if (text === NO_STOPS) return [];
  const positions = text.split(' / ');
  const ok = (p) => BOUNDS.test(p.startsWith(REREAD) ? p.slice(REREAD.length) : p);
  return positions.every(ok) ? positions : null;
}

/**
 * A walk's readings in the order they were read, as its row writes them
 * (every stop, and each re-read right after the stop it re-reads), and
 * their positions, each re-read's marked (rereadAt): for walkLogLines.
 */
export function walkReadings(walk) {
  const readings = [];
  const places = [];
  const rereads = walk.rereads ?? [];
  for (let k = 0; k <= walk.stops.length; k++) {
    if (k > 0) {
      readings.push(walk.stops[k - 1]);
      places.push(walk.positions[k - 1]);
    }
    for (const r of rereads.filter((x) => x.after === k)) {
      readings.push(r.phrase);
      places.push(rereadAt(r.position));
    }
  }
  return { readings, places };
}

/**
 * A walk row's readings split by its positions row (positionsOf, one per
 * reading): a reading whose position is marked "re-read " is a re-read of
 * the stop before it (`{ after, phrase, position }`); every other reading
 * is a stop, with its position. walkReadings' inverse.
 */
export function splitReadings(readings, places) {
  const stops = [];
  const positions = [];
  const rereads = [];
  readings.forEach((phrase, i) => {
    if (places[i].startsWith(REREAD)) {
      rereads.push({ after: stops.length, phrase, position: places[i].slice(REREAD.length) });
    } else {
      stops.push(phrase);
      positions.push(places[i]);
    }
  });
  return { stops, positions, rereads };
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

/**
 * The console lines the VoiceOver spec prints for one try of `slug` in
 * `browser`: `walk` its number, `judged` its verdict, `latest` the
 * collected walk (collectWalk). tool/voiceover_web.py turns each line
 * "V01VO <browser> <row> | <text>" into the transcript row "| `<row>` |
 * <text> |" under the browser's heading, reading <text> to the end of its
 * line, so no line may hold a line break (spokenText). The walk row holds
 * every reading, a re-read included, and the positions row marks each
 * re-read's position (walkReadings); a stop number in a reason counts the
 * stops only.
 */
export function walkLogLines(browser, slug, walk, judged, latest) {
  const at = `V01VO ${browser} ${slug}-walk-${walk}`;
  const { readings, places } = walkReadings(latest);
  return [
    `${at} | ${stopsText(readings)} (${judged.verdict}: ${judged.reason})`,
    `${at}-start | ${startText(latest.start)}`,
    `${at}-positions | ${positionsText(places)}`,
    ...(latest.witness ? [`${at}-end | ${witnessText(latest.witness)}`] : []),
    `${at}-unresolved | ${unresolvedText(latest.unresolved)}`,
  ];
}
