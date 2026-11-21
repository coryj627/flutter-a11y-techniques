// The comparison page of web_tests/vo/c02_toggle_button_vo.spec.js, and how
// one VoiceOver walk of it is judged. Kept apart from the spec, with no
// VoiceOver and no browser, so that web_tests/c02_toggle_button.spec.js can
// test the judging on made-up walks in CI.

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

const mentions = (stop, name) => new RegExp(`\\b${name}\\b`, 'i').test(stop);

/**
 * Judges one walk of the page: `stops` in order, and whether the walk
 * reached the end. Returns `{ verdict, reason }`, the verdict one of:
 *
 * - "wrong": a button was read in other words than expected. A stop is
 *   taken as a button's when it names the button, however it is worded
 *   ("Bold", "selected Bold toggle button"), or when it lies between the
 *   page's stops before and after the buttons ("Text styles" and
 *   "Changes: 0"), whatever it says, an empty phrase included. Either way
 *   it must be one of the expected readings, and a named one must be that
 *   button's own. This fails the test whichever try it is in.
 * - "complete": the end was reached, and the stops between "Text styles"
 *   and "Changes: 0" are exactly the three expected readings, in order.
 * - "incomplete": anything else, such as an empty walk, a walk that never
 *   reached the buttons or the end, or one that went past a button
 *   without reading it. The walk may be tried again.
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
  const between = after >= 0 ? stops.slice(before + 1, after) : [];
  const phrases = BUTTONS.map((b) => b.phrase);
  const stray = between.find((stop) => !phrases.includes(stop));
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
