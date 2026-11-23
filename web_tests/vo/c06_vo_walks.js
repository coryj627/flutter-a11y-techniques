// How web_tests/vo/c06_disclosure_vo.spec.js judges and repeats its
// VoiceOver walks. Kept apart from the spec, with no VoiceOver and no
// browser, so that web_tests/c06_disclosure.spec.js can test it on made-up
// walks in CI. Copied from C05's c05_vo_walks.js, itself written after
// C04's (not imported: those files are other techniques').

/** The heading every example screen has, as VoiceOver reads it. */
export const EXAMPLE_HEADING = 'heading level 2 Example';

/**
 * What each C06 example screen shows above its "Example" heading, as
 * VoiceOver reads it: the screen's title as a level 1 heading, the line
 * that says whether it is a good or a bad example, and a bad example's
 * defect (ExampleScreen in lib/app/screens.dart, with the titles and
 * defects of lib/techniques/c06_disclosure/c06_disclosure.dart). No C06
 * example is a custom solution, so none shows that note.
 * web_tests/c06_disclosure.spec.js checks that each screen shows these
 * texts, so that a change to them is caught.
 */
export const EXAMPLE_SCREENS = {
  'good-material': ['ExpansionTile as a button', 'Good example for Disclosure. Material.'],
  'bad-expansion-tile': [
    'ExpansionTile as it comes', 'Bad example for Disclosure. Material.',
    'Defect: On Android and iOS the control is not a button.',
  ],
  'bad-expand-icon': [
    'ExpandIcon beside a label', 'Bad example for Disclosure. Material.',
    'Defect: Nothing says whether the section is open, not even in words.',
  ],
  'bad-cupertino-expansion-tile': [
    'CupertinoExpansionTile', 'Bad example for Disclosure. Cupertino.',
    'Defect: A keyboard cannot reach the control, so it opens nothing.',
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
 *   reached the end of the screen with any expected stop not read. This
 *   fails the test whichever try it is in.
 * - "complete": the walk reached the end and read exactly the whole screen.
 * - "incomplete": a walk cut short before the end (it ran out of moves)
 *   with nothing wrong so far: every stop it read is the expected one in
 *   its place. Only such a walk may be walked again.
 *
 * There is no exception for an empty first stop: as in C04, an empty
 * phrase anywhere is a wrong stop.
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
