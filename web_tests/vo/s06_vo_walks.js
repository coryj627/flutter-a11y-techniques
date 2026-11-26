// How web_tests/vo/s06_screen_titles_vo.spec.js judges and repeats its
// VoiceOver walks. Kept apart from the spec, with no VoiceOver and no
// browser, so that web_tests/s06_screen_titles.spec.js can test it on
// made-up walks in CI. Written after C04's c04_vo_walks.js (not imported:
// that file is another technique's).

/** The heading every example screen has, as VoiceOver reads it. */
export const EXAMPLE_HEADING = 'heading level 2 Example';

/**
 * What each S06 example screen shows above its "Example" heading, as
 * VoiceOver reads it: the screen's title as a level 1 heading, the line
 * that says whether it is a good or a bad example, and a bad example's
 * defect (ExampleScreen in lib/app/screens.dart, with the titles and
 * defects of lib/techniques/s06_screen_titles/s06_screen_titles.dart). No
 * S06 example is a custom solution, so no screen has the note.
 * web_tests/s06_screen_titles.spec.js checks that each screen shows these
 * texts, so that a change to them is caught.
 */
export const EXAMPLE_SCREENS = {
  'good-material': ['Material screen title', 'Good example for Screen and page titles. Material.'],
  'good-cupertino': ['Cupertino screen title', 'Good example for Screen and page titles. Cupertino.'],
  'bad-no-title': [
    'Screen with no title', 'Bad example for Screen and page titles. Material.',
    'Defect: The screen has no title, only large text.',
  ],
  'bad-vague-title': [
    'Screen titled Details', 'Bad example for Screen and page titles. Material.',
    'Defect: The title does not say what the screen is about.',
  ],
  'bad-no-document-title': [
    'Screen with no document title', 'Bad example for Screen and page titles. Material.',
    'Defect: The browser tab keeps the title of the screen before.',
  ],
  'bad-cupertino-unnamed': [
    'Cupertino bar that names no screen', 'Bad example for Screen and page titles. Cupertino.',
    'Defect: On Android, TalkBack is not told the screen\'s name.',
  ],
};

/** The stops VoiceOver reads above the "Example" heading of `slug`'s screen. */
export const screenStops = (slug) => {
  const [title, ...lines] = EXAMPLE_SCREENS[slug];
  return [`heading level 1 ${title}`, ...lines];
};

/**
 * Judges one walk of a screen: `stops` in order, whether the walk reached
 * the end of the screen (two moves in a row that changed nothing), and
 * `whole`, every stop the screen must read, in order. Returns
 * `{ verdict, reason }`, the verdict one of:
 *
 * - "wrong": a stop that is not the one expected in its place (a stop read
 *   in other words, an empty phrase, a stop skipped so that a later one
 *   comes early, a stop after the last expected one), or a walk that
 *   reached the end of the screen with any expected stop not read. This
 *   fails the test whichever try it is in.
 * - "complete": the walk reached the end and read exactly the whole screen.
 * - "incomplete": a walk cut short before the end (it ran out of moves)
 *   with nothing wrong so far. Only such a walk may be walked again.
 */
export function judgeWalk(stops, reachedEnd, whole) {
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
 * An example screen's walk: `screen` (screenStops), the "Example" heading,
 * then `expected`, everything after the heading to the end of the screen.
 */
export const judgeExampleWalk = (stops, reachedEnd, expected, screen = []) =>
  judgeWalk(stops, reachedEnd, [...screen, EXAMPLE_HEADING, ...expected]);

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
