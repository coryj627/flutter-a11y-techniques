// How web_tests/vo/c05_accordion_vo.spec.js judges its VoiceOver walks.
// Kept apart from the spec, with no VoiceOver and no browser, so that
// web_tests/c05_accordion.spec.js can test it on made-up walks in CI.

/** The heading every example screen has, as VoiceOver reads it. */
export const EXAMPLE_HEADING = 'heading level 2 Example';

/**
 * What each C05 example screen shows above its "Example" heading: the
 * screen's title (a level 1 heading), the line that says whether it is a
 * good or a bad example, and a bad example's defect (ExampleScreen in
 * lib/app/screens.dart, with the titles and defects of
 * lib/techniques/c05_accordion/c05_accordion.dart).
 * web_tests/c05_accordion.spec.js checks that each screen shows these
 * texts, so that a change to them is caught.
 */
export const EXAMPLE_SCREENS = {
  'good-material': ['Material accordion', 'Good example for Accordion. Material.'],
  'good-cupertino': ['Cupertino accordion', 'Good example for Accordion. Cupertino.'],
  'good-custom': ['Accordion built from Semantics', 'Good example for Accordion. Widgets layer.'],
  'bad-no-state': [
    'Headers with no state', 'Bad example for Accordion. Widgets layer.',
    'Defect: Nothing says whether a section is open or closed.',
  ],
  'bad-heading-on-button': [
    'Heading on the button', 'Bad example for Accordion. Widgets layer.',
    'Defect: On the web each header is a heading only: not a button, and with no state.',
  ],
  'bad-no-heading': [
    'Headers that are not headings', 'Bad example for Accordion. Widgets layer.',
    'Defect: The headers look like headings but are not headings.',
  ],
  'bad-hidden-panel': [
    'Closed sections kept hidden', 'Bad example for Accordion. Widgets layer.',
    'Defect: Tab goes into closed sections, to buttons that are not shown.',
  ],
  'bad-expansion-tile': [
    'Material ExpansionTile', 'Bad example for Accordion. Material.',
    'Defect: The headers have no open or closed state, and on Android and iOS are not buttons.',
  ],
  'bad-cupertino-expansion-tile': [
    'CupertinoExpansionTile', 'Bad example for Accordion. Cupertino.',
    'Defect: A keyboard cannot reach the headers, so it opens nothing.',
  ],
};

/**
 * The readings VoiceOver may give for the screen's stops before the
 * "Example" heading: the title as a level 1 heading (WebKit has read it as
 * an empty phrase, C03's transcript), then the other lines as they are.
 */
export function screenStops(slug) {
  const [title, ...rest] = EXAMPLE_SCREENS[slug];
  return { title: [`heading level 1 ${title}`, ''], rest };
}

const isPrefix = (part, whole) => part.length <= whole.length && part.every((s, i) => s === whole[i]);

/**
 * Judges one walk: `stops` in order from the Back button, whether the walk
 * reached the end of the screen, the `expected` stops after the "Example"
 * heading, to the end, and the screen's own stops before it (screenStops).
 * Every stop is judged. Returns `{ verdict, reason }`:
 *
 * - "complete": the stops before the heading are the screen's, the end was
 *   reached, and the stops after the heading are exactly `expected`.
 * - "incomplete": the walk fell short with nothing wrong in what it read:
 *   nothing read; only the start of the screen's stops; or the heading and
 *   then only the start of `expected` with the end not reached. It may be
 *   tried again.
 * - "wrong": anything else: a stop before the heading that is not the
 *   screen's, or after it that is not the next expected one, or a walk
 *   that reached the end with stops missing or extra. It fails the test
 *   whichever try it is in.
 */
export function judgeWalk(stops, reachedEnd, expected, screen) {
  const lead = [screen.title, ...screen.rest.map((r) => [r])];
  const fitsLead = (part) => part.length <= lead.length && part.every((s, i) => lead[i].includes(s));
  const heading = stops.indexOf(EXAMPLE_HEADING);
  if (heading < 0) {
    if (stops.length === 0) return { verdict: 'incomplete', reason: 'nothing was read' };
    if (fitsLead(stops) && !reachedEnd) return { verdict: 'incomplete', reason: 'the walk stopped before the Example heading' };
    return { verdict: 'wrong', reason: `no Example heading in: ${stops.join(' / ')}` };
  }
  const before = stops.slice(0, heading);
  if (!(before.length === lead.length && fitsLead(before))) {
    return { verdict: 'wrong', reason: `before the heading: ${before.join(' / ') || '(nothing)'}` };
  }
  const content = stops.slice(heading + 1);
  if (!isPrefix(content, expected)) {
    return { verdict: 'wrong', reason: `after the heading: ${content.join(' / ') || '(nothing)'}` };
  }
  if (!reachedEnd) return { verdict: 'incomplete', reason: 'the walk did not reach the end' };
  if (content.length !== expected.length) {
    return { verdict: 'wrong', reason: `the end came after ${content.length} of ${expected.length} stops` };
  }
  return { verdict: 'complete', reason: 'every stop as expected, to the end' };
}

/**
 * Runs `walk()` and judges it with `judge(stops, reachedEnd)`, again while
 * the verdict is "incomplete", at most `tries` times, calling
 * `log(try, stops, judged)` for every try. Returns the last verdict, its
 * reason, and the number of tries. A "wrong" verdict ends it at once.
 */
export async function runWalks(walk, judge, { tries = 3, log = () => {} } = {}) {
  let judged = { verdict: 'incomplete', reason: 'not run' };
  for (let n = 1; n <= tries; n++) {
    const { stops, reachedEnd } = await walk();
    judged = judge(stops, reachedEnd);
    log(n, stops, judged);
    if (judged.verdict !== 'incomplete') return { ...judged, walks: n };
  }
  return { ...judged, walks: tries };
}
