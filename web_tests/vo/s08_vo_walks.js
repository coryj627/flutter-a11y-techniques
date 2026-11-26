// How web_tests/vo/s08_list_semantics_vo.spec.js judges and repeats its
// VoiceOver walks. Kept apart from the spec, with no VoiceOver and no
// browser, so that web_tests/s08_list_semantics.spec.js can test it on
// made-up walks in CI. A copy of C04's c04_vo_walks.js (not imported: that
// file is another technique's), with S08's screens; the judge is the same.

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

/** The stops VoiceOver reads above the "Example" heading of `slug`'s screen. */
export const screenStops = (slug) => {
  const [title, ...lines] = EXAMPLE_SCREENS[slug];
  return [`heading level 1 ${title}`, ...lines];
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
 * C04 walk showed it (docs/evidence/C04/voiceover-web.md: every walk
 * complete on its first try), so here, as in C04, it is a wrong stop like
 * any other.
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
