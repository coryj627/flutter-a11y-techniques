// How web_tests/vo/c04_links_inline_with_text_vo.spec.js judges and repeats
// its VoiceOver walks. Kept apart from the spec, with no VoiceOver and no
// browser, so that web_tests/c04_links_inline_with_text.spec.js can test it
// on made-up walks in CI. Written after C02's c02_vo_walks.js (not imported:
// that file is another technique's), for screens that end with the example
// and have no count after it.

/** The heading every example screen has, as VoiceOver reads it. */
export const EXAMPLE_HEADING = 'heading level 2 Example';

/**
 * What each C04 example screen shows above its "Example" heading, as
 * VoiceOver reads it: the screen's title as a level 1 heading, the line
 * that says whether it is a good or a bad example, and a bad example's
 * defect (ExampleScreen in lib/app/screens.dart, with the titles and
 * defects of lib/techniques/c04_links_inline_with_text/
 * c04_links_inline_with_text.dart). web_tests/c04_links_inline_with_text.spec.js
 * checks that each screen shows these texts, so that a change to them is
 * caught.
 */
export const EXAMPLE_SCREENS = {
  'good-material': ['Material links in a sentence', 'Good example for Links inline with text. Material.'],
  'good-cupertino': ['Cupertino links in a sentence', 'Good example for Links inline with text. Cupertino.'],
  'good-custom': ['Widgets-layer links in a sentence', 'Good example for Links inline with text. Widgets layer.'],
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
 * Whether `content` is made only of readings in `expected`, each at most
 * once and in the order of `expected`. Returns the first stop that breaks
 * that, or undefined.
 */
function outOfPlace(content, expected) {
  let at = -1;
  for (const stop of content) {
    const next = expected.indexOf(stop, at + 1);
    if (next < 0) return stop;
    at = next;
  }
  return undefined;
}

/**
 * Judges one walk of an example screen: `stops` in order, whether the walk
 * reached the end, `expected`, everything VoiceOver must say after the
 * "Example" heading to the end of the screen, in order, and `screen`, the
 * stops known to come before the heading (screenStops). Returns
 * `{ verdict, reason }`, the verdict one of:
 *
 * - "wrong": a stop that cannot be explained. The example's part of the
 *   walk is everything after the heading; in a walk that did not read the
 *   heading, everything after the run of `screen` stops it began with.
 *   Every stop there must be in `expected`, each at most once and in its
 *   order: anything else (an empty phrase, a stop read in other words, one
 *   of the screen's own stops out of its place) fails the test whichever
 *   try it is in. Before the heading, in a walk that read it, only the
 *   screen's own stops may stand, each at most once and in their order; the
 *   one exception is an empty phrase as the first stop, in the place of the
 *   screen's level 1 heading, which WebKit was seen to read so in C02.
 * - "complete": the heading was read, the end was reached, and the stops
 *   after the heading are exactly `expected`.
 * - "incomplete": a walk that fell short with nothing unexplained in it: an
 *   empty walk, one that read only the screen's own stops, or one whose
 *   example part is some of `expected`, in order, without the heading or
 *   without reaching the end. The walk may be tried again.
 */
export function judgeExampleWalk(stops, reachedEnd, expected, screen = []) {
  if (stops.length === 0) return { verdict: 'incomplete', reason: 'nothing was read' };
  const heading = stops.indexOf(EXAMPLE_HEADING);
  let from = heading + 1;
  if (heading < 0) {
    from = 0;
    let at = -1;
    while (from < stops.length && screen.indexOf(stops[from], at + 1) > at) {
      at = screen.indexOf(stops[from], at + 1);
      from++;
    }
  } else {
    let lead = stops.slice(0, heading);
    let own = screen;
    if (lead[0] === '') {
      lead = lead.slice(1);
      own = screen.slice(1);
    }
    const odd = outOfPlace(lead, own);
    if (odd !== undefined) {
      return { verdict: 'wrong', reason: `"${odd}" before the heading is not one of the screen's own stops in its place` };
    }
  }
  const content = stops.slice(from);
  const stray = outOfPlace(content, expected);
  if (stray !== undefined) {
    return { verdict: 'wrong', reason: `"${stray}" is not the next expected reading` };
  }
  if (heading < 0) {
    return {
      verdict: 'incomplete',
      reason: content.length
        ? 'the walk did not read the "Example" heading; what it read after the screen\'s own stops is right so far'
        : 'the walk read only the screen\'s own stops',
    };
  }
  if (reachedEnd && content.length === expected.length) {
    return { verdict: 'complete', reason: 'every expected stop, in order' };
  }
  if (!reachedEnd) return { verdict: 'incomplete', reason: 'the walk did not reach the end' };
  return { verdict: 'incomplete', reason: `read ${content.length} of the ${expected.length} expected stops` };
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
