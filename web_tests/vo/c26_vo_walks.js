// How web_tests/vo/c26_progress_indicator_vo.spec.js judges and repeats its
// VoiceOver walks. Kept apart from the spec, with no VoiceOver and no
// browser, so that web_tests/c26_progress_indicator.spec.js can test it on
// made-up walks in CI. Copied from C04's c04_vo_walks.js (not imported:
// that file is another technique's), with C26's screens.

/** The heading every example screen has, as VoiceOver reads it. */
export const EXAMPLE_HEADING = 'heading level 2 Example';

/**
 * What each C26 example screen shows above its "Example" heading, as
 * VoiceOver reads it: the screen's title as a level 1 heading, the line
 * that says whether it is a good or a bad example, and a bad example's
 * defect (ExampleScreen in lib/app/screens.dart, with the titles and
 * defects of lib/techniques/c26_progress_indicator/
 * c26_progress_indicator.dart). No C26 example is a custom solution, so no
 * screen has the note. web_tests/c26_progress_indicator.spec.js checks that
 * each screen shows these texts, so that a change to them is caught.
 */
export const EXAMPLE_SCREENS = {
  'good-linear': ['Material progress bar', 'Good example for Progress indicator. Material.'],
  'bad-no-role': [
    'Material spinner', 'Bad example for Progress indicator. Material.',
    'Defect: A screen reader hears a name and no role: Flutter gives no spinner one.',
  ],
  'bad-cupertino-no-role': [
    'Cupertino spinner', 'Bad example for Progress indicator. Cupertino.',
    'Defect: A screen reader hears a name and no role: Flutter gives no spinner one.',
  ],
  'bad-no-label': [
    'Progress bar with no name', 'Bad example for Progress indicator. Material.',
    'Defect: A screen reader reads the bar as a number with no name.',
  ],
  'bad-silent-end': [
    'Upload that ends in silence', 'Bad example for Progress indicator. Material.',
    'Defect: Nothing tells a screen reader that the upload has finished.',
  ],
  'bad-adaptive': [
    'Adaptive spinner', 'Bad example for Progress indicator. Material.',
    'Defect: On iOS and on a Mac, a screen reader finds no spinner.',
  ],
  'bad-cupertino-bar': [
    'Cupertino progress bar', 'Bad example for Progress indicator. Cupertino.',
    'Defect: A screen reader finds no bar and no value.',
  ],
};

/** The stops VoiceOver reads above the "Example" heading of `slug`'s screen. */
export const screenStops = (slug) => {
  const [title, ...lines] = EXAMPLE_SCREENS[slug];
  return [`heading level 1 ${title}`, ...lines];
};

/**
 * slug -> browser -> everything VoiceOver speaks after the "Example"
 * heading, to the end of the screen, in order, at rest: the button, the
 * bar where there is one, and the status line. A spinner is shown only
 * while loading, so it is not in a walk at rest.
 *
 * These are what the first recording read
 * (docs/evidence/probes/c26/voiceover-web-round1-fail.md.txt), the same in
 * Chromium and WebKit. It had been written from predictions, which
 * expected a bar to be read with its value once; VoiceOver read the name,
 * which holds the value on the web (FL-037), and then the value again as
 * a percentage, "0%" (FL-027).
 */
const both = (list) => ({ chromium: list, webkit: list });

/**
 * The words that would say a spinner is a progress or busy indicator:
 * VoiceOver's word for a `progressbar`, taken from C26's own bar reading
 * ("Report upload 0 0% progress indicator"), and the other words one could
 * be read with. A spinner's expected reading (SPINNER_READINGS) must hold
 * none of them: a reading that did would mean the spinner has a role, and
 * this bad example must then fail. Matched whole, case ignored.
 *
 * "group" is not one of them. VoiceOver says it for a named element with
 * no role of its own: FL-028's slider wrapper, a `flt-semantics` element
 * with `aria-label` and no role, is read "Volume group" in both browsers
 * (docs/evidence/F10/voiceover-web.md), and Material's spinner is such an
 * element (the tree spec; docs/evidence/probes/c26/web-spinner-ax.txt,
 * where Chromium gives it the role "generic").
 */
export const INDICATOR_WORDS = [
  'progress indicator', 'progress bar', 'progressbar', 'progress', 'busy indicator', 'busy',
  'activity indicator', 'loading indicator', 'spinner', 'timer',
];

/**
 * slug -> browser -> what VoiceOver must say, exactly, when its cursor
 * reaches the spinner while it loads. Measured in the recording at
 * 7b9dc5c (docs/evidence/probes/c26/voiceover-web-round3-fail.md.txt),
 * except where this says otherwise.
 *
 * - Material's spinner is an element with no role, an `aria-label`, and no
 *   children (FL-256). WebKit read it "Loading inbox empty group": the
 *   name, then "group", as for FL-028's role-less named slider wrapper
 *   ("Volume group"; that element has a child, and no "empty" was said).
 *   Chromium's reading is not measured yet: in that recording the capture
 *   after each move was still the announcement made before it (the spec,
 *   section 7). The Chromium entry is WebKit's reading, written as a
 *   prediction, which the next recording confirms or fails.
 * - Cupertino's spinner is `Semantics(label:)` round a widget with no
 *   semantics: plain text, read "Loading inbox" in both browsers.
 */
export const SPINNER_READINGS = {
  'bad-no-role': { chromium: 'Loading inbox empty group', webkit: 'Loading inbox empty group' },
  'bad-cupertino-no-role': { chromium: 'Loading inbox', webkit: 'Loading inbox' },
};

/** How long a C26 spinner is shown after its button is pressed. */
export const SPINNER_MS = 4000;

const indicatorWords = (text) =>
  INDICATOR_WORDS.filter((w) => new RegExp(`\\b${w}\\b`, 'i').test(text));

/**
 * Judges a spinner's reading while it loads (FL-256). `before` is
 * `{ phrase, position }`, VoiceOver's last phrase and the bounds of its
 * cursor just before the first move; `moves` is each move after the press,
 * in order: `{ phrase, position, ms, shown }`, the phrase and the cursor's
 * bounds once the move had spoken, the milliseconds since the press, and
 * whether the spinner's element was in the page then. `name` is the
 * spinner's name and `expected` its whole reading (SPINNER_READINGS).
 * Returns `{ verdict, reason }`, the verdict "right" or "wrong"; anything
 * not shown right is wrong:
 *
 * - `expected` must hold `name` and none of INDICATOR_WORDS, so that a
 *   reading with a role cannot be written in as the expectation;
 * - every move's phrase must be non-empty, and no move may leave both the
 *   phrase and the cursor where they were (before the first move, where
 *   `before` has them), so that an empty or stale capture cannot pass. A
 *   move that speaks the same words at a new place is not stale: the
 *   status line says "Loading started", the words of the announcement
 *   before it;
 * - the first move that reads `name` is the spinner's reading. It must come
 *   while the spinner was shown and within SPINNER_MS of the press, and it
 *   must be `expected`, exactly. If no move read `name`, the spinner was
 *   not reached, and that is a failure, not a pass.
 *
 * The test makes no move after the one that reads `name`.
 */
export function judgeSpinnerReading(before, moves, name, expected) {
  if (!expected || !expected.includes(name)) {
    return { verdict: 'wrong', reason: `the expected reading "${expected}" does not hold the name "${name}"` };
  }
  const named = indicatorWords(expected);
  if (named.length) {
    return { verdict: 'wrong', reason: `the expected reading "${expected}" says it is an indicator: ${named.join(', ')}` };
  }
  let previous = before;
  for (let i = 0; i < moves.length; i++) {
    const { phrase, position, ms, shown } = moves[i];
    if (!phrase) return { verdict: 'wrong', reason: `move ${i + 1} read an empty phrase` };
    if (phrase === previous.phrase && position === previous.position) {
      return {
        verdict: 'wrong',
        reason: `move ${i + 1} left the cursor at ${position} and spoke nothing new ("${phrase}"): the capture is stale`,
      };
    }
    previous = moves[i];
    if (!phrase.includes(name)) continue;
    if (!shown || ms > SPINNER_MS) {
      return { verdict: 'wrong', reason: `the spinner was not reached in time: "${phrase}" at ${ms} ms, spinner ${shown ? 'shown' : 'gone'}` };
    }
    if (phrase !== expected) return { verdict: 'wrong', reason: `"${phrase}", not "${expected}"` };
    return { verdict: 'right', reason: `"${phrase}" at ${ms} ms, exactly the reading expected` };
  }
  const heard = moves.map((m) => `"${m.phrase}" at ${m.position}`).join(', ') || 'no move';
  return { verdict: 'wrong', reason: `the spinner was not reached: no move read "${name}" (${heard})` };
}

export const WALKS = {
  'good-linear': both(['Upload report button', 'Report upload 0 0% progress indicator', 'Not started']),
  'bad-no-role': both(['Load inbox button', 'Inbox not loaded']),
  'bad-cupertino-no-role': both(['Load inbox button', 'Inbox not loaded']),
  // The bar is named by its value alone; the words are text before it.
  'bad-no-label': both(['Upload report button', 'Report upload', '0 0% progress indicator', 'Not started']),
  'bad-silent-end': both(['Upload report button', 'Report upload 0 0% progress indicator', 'Not started']),
  // In a browser on a Mac the adaptive spinner is Cupertino's, with nothing
  // in it (FL-257); it is shown only while loading in any case.
  'bad-adaptive': both(['Load inbox button', 'Inbox not loaded']),
  // The bar is not there.
  'bad-cupertino-bar': both(['Upload report button', 'Report upload', 'Not started']),
};

/**
 * Judges one walk of an example screen: `stops` in order, whether the walk
 * reached the end of the screen (two moves in a row that changed nothing),
 * `expected`, everything VoiceOver must say after the "Example" heading to
 * the end of the screen, in order, and `screen`, the stops the screen has
 * before the heading (screenStops). The walk must read the whole screen:
 * `screen`, then the heading, then `expected`, every stop in its place and
 * nothing else. Returns `{ verdict, reason }`, the verdict one of:
 *
 * - "wrong": a stop that is not the one expected in its place (a stop read
 *   in other words, an empty phrase, a stop skipped so that a later one
 *   comes early, a stop after the last expected one), or a walk that
 *   reached the end of the screen with any expected stop not read, the
 *   title, the description, the heading, or a link included. This fails the
 *   test whichever try it is in.
 * - "complete": the walk reached the end and read exactly the whole screen.
 * - "incomplete": a walk cut short before the end (it ran out of moves)
 *   with nothing wrong so far: every stop it read is the expected one in
 *   its place. Only such a walk may be walked again.
 *
 * There is no exception for an empty first stop. C02 measured WebKit
 * reading a screen's level 1 heading as an empty phrase and allows it; no
 * C04 walk showed it (docs/evidence/C04/voiceover-web.md), so here, as in
 * C04, it is a wrong stop like any other.
 */
export function judgeExampleWalk(stops, reachedEnd, expected, screen = []) {
  const whole = [...screen, EXAMPLE_HEADING, ...expected];
  for (let i = 0; i < stops.length; i++) {
    if (i >= whole.length) {
      return { verdict: 'wrong', reason: `"${stops[i]}" was read after the last expected stop` };
    }
    if (stops[i] !== whole[i]) {
      return { verdict: 'wrong', reason: `stop ${i + 1} was "${stops[i]}" where "${whole[i]}" was expected` };
    }
  }
  if (stops.length === whole.length) {
    return reachedEnd
      ? { verdict: 'complete', reason: 'the whole screen, every stop in its place' }
      : { verdict: 'incomplete', reason: 'every expected stop was read, but the walk did not reach the end' };
  }
  if (reachedEnd) {
    return {
      verdict: 'wrong',
      reason: `the walk reached the end after ${stops.length} of the ${whole.length} expected stops; "${whole[stops.length]}" was never read`,
    };
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
