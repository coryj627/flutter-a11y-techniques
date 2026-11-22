// How web_tests/vo/c04_links_inline_with_text_vo.spec.js judges and repeats
// its VoiceOver walks. Kept apart from the spec, with no VoiceOver and no
// browser, so that web_tests/c04_links_inline_with_text.spec.js can test it
// on made-up walks in CI. Written after C02's c02_vo_walks.js (not imported:
// that file is another technique's), for screens that end with the example
// and have no count after it.

/** The heading every example screen has, as VoiceOver reads it. */
export const EXAMPLE_HEADING = 'heading level 2 Example';

/**
 * The note a custom solution shows above its "Example" heading
 * (CustomSolutionNote in lib/app/widgets.dart): the label, then the
 * example's own reason, its `customSolution` in
 * lib/techniques/c04_links_inline_with_text/
 * c04_links_inline_with_text.dart.
 * docs/custom-solutions.md lists the custom solutions.
 */
const customSolution = (reason) => 'Custom solution: not vetted by a real-world example. '
  + 'It is tested here in isolation, with screen-reader transcripts, but has not been built into a real app '
  + `and tested in a user journey. Do not treat it as a vetted technique. Why it is flagged: ${reason}`;

/**
 * What each C04 example screen shows above its "Example" heading, as
 * VoiceOver reads it: the screen's title as a level 1 heading, the line
 * that says whether it is a good or a bad example, a custom solution's
 * note (customSolution, above), and a bad example's defect
 * (ExampleScreen in lib/app/screens.dart, with the titles, reasons, and
 * defects of lib/techniques/c04_links_inline_with_text/
 * c04_links_inline_with_text.dart). web_tests/c04_links_inline_with_text.spec.js
 * checks that each screen shows these texts, so that a change to them is
 * caught.
 */
export const EXAMPLE_SCREENS = {
  'good-material': [
    'Material links in a sentence', 'Good example for Links inline with text. Material.',
    customSolution('An inline link built by hand: Semantics(link: true, linkUrl:) round an InkWell in a WidgetSpan, with key bindings, a focus ring, and sort keys; a TextSpan link takes no keyboard focus (FL-240).'),
  ],
  'good-cupertino': [
    'Cupertino links in a sentence', 'Good example for Links inline with text. Cupertino.',
    customSolution('An inline link built by hand from FocusableActionDetector, Semantics, and a GestureDetector in a WidgetSpan, in Cupertino\'s blue; Flutter has no link widget (FL-221) and a TextSpan link takes no focus (FL-240).'),
  ],
  'good-custom': [
    'Widgets-layer links in a sentence', 'Good example for Links inline with text. Widgets layer.',
    customSolution('An inline link built by hand from FocusableActionDetector, Semantics, and a GestureDetector in a WidgetSpan; a TextSpan link takes no keyboard focus (FL-240).'),
  ],
  'bad-text-span': [
    'Link in a text span', 'Bad example for Links inline with text. Widgets layer.',
    'Defect: A keyboard cannot reach the link.',
  ],
  'bad-out-of-order': [
    'Links read after their sentence', 'Bad example for Links inline with text. Material.',
    'Defect: A screen reader reads the sentence without its links, then the links.',
  ],
  'bad-colour-only': [
    'Links shown by colour alone', 'Bad example for Links inline with text. Material.',
    'Defect: Only a colour close to the text tells the links apart.',
  ],
  'bad-merged': [
    'Sentence and links as one element', 'Bad example for Links inline with text. Material.',
    'Defect: A screen reader finds the sentence as one link, and not the second link.',
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
 * C04 walk has shown it (docs/evidence/C04/voiceover-web.md: every walk
 * complete on its first try), so here it is a wrong stop like any other.
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
