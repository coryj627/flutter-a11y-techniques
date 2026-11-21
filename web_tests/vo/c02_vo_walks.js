// How web_tests/vo/c02_toggle_button_vo.spec.js judges and repeats its
// VoiceOver walks: of the examples, and of its plain HTML comparison page.
// Kept apart from the spec, with no VoiceOver and no browser, so that
// web_tests/c02_toggle_button.spec.js can test it on made-up walks in CI.

/** A plain HTML page with no Flutter: two toggle buttons and a button with aria-current. */
export const CONTROL_HTML = `<main>
    <button>Back</button>
    <h2>Example</h2>
    <p>Text styles</p>
    <button aria-pressed="false">Bold</button>
    <button aria-pressed="true">Italic</button>
    <button aria-current="true">Underline</button>
    <p>Changes: 0</p>
  </main>`;

/** The page's stops just before and just after the three buttons. */
export const BEFORE = 'Text styles';
export const AFTER = 'Changes: 0';

/** Each button's name and what VoiceOver must say for it, in page order. */
export const BUTTONS = [
  { name: 'Bold', phrase: 'Bold toggle button' },
  { name: 'Italic', phrase: 'Italic selected toggle button' },
  { name: 'Underline', phrase: 'Underline current item button' },
];

/** The page's own stops after the buttons, which are not a button's. */
const AFTER_BUTTONS = new Set([AFTER, 'end of main']);

const mentions = (stop, name) => new RegExp(`\\b${name}\\b`, 'i').test(stop);

/**
 * Judges one walk of the page: `stops` in order, and whether the walk
 * reached the end. Returns `{ verdict, reason }`, the verdict one of:
 *
 * - "wrong": a button was read in other words than expected. A stop is
 *   taken as a button's when it names the button, however it is worded
 *   ("Bold", "selected Bold toggle button"), or when it comes after "Text
 *   styles", the page's stop before the buttons, and before "Changes: 0",
 *   the stop after them, whatever it says, an empty phrase included. When
 *   the walk stopped before "Changes: 0", every stop after "Text styles"
 *   is taken as a button's, apart from "end of main". Either way it must
 *   be one of the expected readings, and a named one must be that
 *   button's own. This fails the test whichever try it is in.
 * - "complete": the end was reached, and the stops between "Text styles"
 *   and "Changes: 0" are exactly the three expected readings, in order.
 * - "incomplete": anything else, such as an empty walk, a walk that never
 *   reached the buttons or the end, or one that went past a button
 *   without reading it. The walk may be tried again. A walk that did not
 *   pass "Text styles" has no stop that can be told for a button's except
 *   by its name, so an empty or nameless reading in it is not seen.
 */
export function judgeControlWalk(stops, reachedEnd) {
  for (const stop of stops) {
    for (const { name, phrase } of BUTTONS) {
      if (mentions(stop, name) && stop !== phrase) {
        return { verdict: 'wrong', reason: `${name} was read "${stop}", not "${phrase}"` };
      }
    }
  }
  const before = stops.indexOf(BEFORE);
  const after = before >= 0 ? stops.indexOf(AFTER, before + 1) : -1;
  const candidates = before < 0 ? []
    : after >= 0 ? stops.slice(before + 1, after)
      : stops.slice(before + 1).filter((stop) => !AFTER_BUTTONS.has(stop));
  const between = after >= 0 ? candidates : [];
  const phrases = BUTTONS.map((b) => b.phrase);
  const stray = candidates.find((stop) => !phrases.includes(stop));
  if (stray !== undefined) {
    return { verdict: 'wrong', reason: `a button was read "${stray}"` };
  }
  if (reachedEnd && between.length === phrases.length && between.every((s, i) => s === phrases[i])) {
    return { verdict: 'complete', reason: 'the three buttons were read in order, then the count' };
  }
  if (stops.length === 0) return { verdict: 'incomplete', reason: 'nothing was read' };
  if (!reachedEnd) return { verdict: 'incomplete', reason: 'the walk did not reach the end' };
  if (after < 0) return { verdict: 'incomplete', reason: 'the walk did not pass both neighbours of the buttons' };
  return { verdict: 'incomplete', reason: `between the neighbours: ${between.join(' / ') || '(nothing)'}` };
}

/** The heading every example screen has, as VoiceOver reads it. */
export const EXAMPLE_HEADING = 'heading level 2 Example';

/**
 * Judges one walk of an example screen: `stops` in order, whether the walk
 * reached the end, and `expected`, everything VoiceOver must say after the
 * "Example" heading, in order, ending with the change count. Returns
 * `{ verdict, reason }`, the verdict one of:
 *
 * - "wrong": after the heading, a stop that is not in `expected` (an empty
 *   phrase included, or a count that is not the expected one), or the
 *   expected stops out of order or read twice. This fails the test
 *   whichever try it is in.
 * - "complete": the end was reached and the stops after the heading are
 *   exactly `expected`.
 * - "incomplete": a capture that fell short and said nothing wrong: an
 *   empty walk, a walk that never reached the heading, or one that read
 *   only some of the expected stops, in order, or did not reach the end.
 *   The walk may be tried again.
 *
 * Stops before the heading are the screen's own and are not judged.
 */
export function judgeExampleWalk(stops, reachedEnd, expected) {
  if (stops.length === 0) return { verdict: 'incomplete', reason: 'nothing was read' };
  const start = stops.indexOf(EXAMPLE_HEADING);
  if (start < 0) return { verdict: 'incomplete', reason: 'the walk did not reach the "Example" heading' };
  const content = stops.slice(start + 1);
  const stray = content.find((stop) => !expected.includes(stop));
  if (stray !== undefined) return { verdict: 'wrong', reason: `"${stray}" is not one of the expected readings` };
  let at = -1;
  for (const stop of content) {
    const next = expected.indexOf(stop, at + 1);
    if (next < 0) return { verdict: 'wrong', reason: `"${stop}" is out of order or read twice` };
    at = next;
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

/** runWalks for the comparison page, judged by judgeControlWalk. */
export const runControlWalks = (walkOnce, options) => runWalks(walkOnce, judgeControlWalk, options);
