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

/** The heading, which is the page's one stop before "Text styles". */
const CONTROL_HEADING = 'heading level 2 Example';

const mentions = (stop, name) => new RegExp(`\\b${name}\\b`, 'i').test(stop);

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
 * Judges one walk of the page: `stops` in order, and whether the walk
 * reached the end. Returns `{ verdict, reason }`, the verdict one of:
 *
 * - "wrong": a stop that cannot be explained. Any stop that names a
 *   button, however it is worded ("Bold", "selected Bold toggle button"),
 *   must be that button's expected reading. And every stop of the part of
 *   the walk where the buttons are must be an expected reading, each at
 *   most once and in page order, whatever it says, an empty phrase
 *   included. That part starts after "Text styles", the page's stop before
 *   the buttons; in a walk that did not read "Text styles" it starts at the
 *   first stop, or after the heading if the walk began with it, since the
 *   heading is the only stop known to come before "Text styles". It ends
 *   at "Changes: 0", the stop after the buttons, or, in a walk that did not
 *   read it, at the end of the walk, leaving out a last "end of main".
 *   Before "Text styles" only the heading may stand (read as an empty
 *   phrase by WebKit), and after "Changes: 0" only "end of main". This
 *   fails the test whichever try it is in.
 * - "complete": "Text styles" and "Changes: 0" were read, the end was
 *   reached, and the stops between them are exactly the three expected
 *   readings, in order.
 * - "incomplete": a walk that fell short with nothing unexplained in it: an
 *   empty walk, one that read only the heading, or one that read only some
 *   of the expected readings, in order, or did not pass both neighbours or
 *   reach the end. The walk may be tried again.
 *
 * In a walk without "Text styles", an empty first stop is taken as a
 * button's, and so is wrong, although WebKit reads the heading as an empty
 * phrase: it cannot be told apart from a button read as nothing.
 */
export function judgeControlWalk(stops, reachedEnd) {
  for (const stop of stops) {
    for (const { name, phrase } of BUTTONS) {
      if (mentions(stop, name) && stop !== phrase) {
        return { verdict: 'wrong', reason: `${name} was read "${stop}", not "${phrase}"` };
      }
    }
  }
  if (stops.length === 0) return { verdict: 'incomplete', reason: 'nothing was read' };
  const before = stops.indexOf(BEFORE);
  // Before "Text styles" the page has one stop, the heading, which WebKit
  // reads as an empty phrase: nothing else may stand there.
  if (before >= 0) {
    const lead = stops.slice(0, before);
    if (lead.length > 1 || (lead.length === 1 && lead[0] !== CONTROL_HEADING && lead[0] !== '')) {
      return { verdict: 'wrong', reason: `before "${BEFORE}": ${lead.join(' / ')}` };
    }
  }
  const start = before >= 0 ? before + 1 : stops[0] === CONTROL_HEADING ? 1 : 0;
  const after = stops.indexOf(AFTER, start);
  // After "Changes: 0" the page has only "end of main".
  if (after >= 0) {
    const tail = stops.slice(after + 1);
    if (tail.length > 1 || (tail.length === 1 && tail[0] !== 'end of main')) {
      return { verdict: 'wrong', reason: `after "${AFTER}": ${tail.join(' / ')}` };
    }
  }
  const candidates = after >= 0 ? stops.slice(start, after)
    : stops.slice(start).filter((stop, i, rest) => !(stop === 'end of main' && i === rest.length - 1));
  const phrases = BUTTONS.map((b) => b.phrase);
  const stray = outOfPlace(candidates, phrases);
  if (stray !== undefined) {
    return {
      verdict: 'wrong',
      reason: `"${stray}" stands where a button is, and is not the next expected reading`,
    };
  }
  if (before >= 0 && after >= 0 && reachedEnd && candidates.length === phrases.length) {
    return { verdict: 'complete', reason: 'the three buttons were read in order, then the count' };
  }
  if (!reachedEnd) return { verdict: 'incomplete', reason: 'the walk did not reach the end' };
  if (before < 0 || after < 0) return { verdict: 'incomplete', reason: 'the walk did not pass both neighbours of the buttons' };
  return { verdict: 'incomplete', reason: `between the neighbours: ${candidates.join(' / ') || '(nothing)'}` };
}

/** The heading every example screen has, as VoiceOver reads it. */
export const EXAMPLE_HEADING = 'heading level 2 Example';

/**
 * What each C02 example screen shows above its "Example" heading, as
 * VoiceOver reads it: the screen's title as a level 1 heading, the line
 * that says whether it is a good or a bad example, and a bad example's
 * defect (ExampleScreen in lib/app/screens.dart, with the titles and
 * defects of lib/techniques/c02_toggle_button/c02_toggle_button.dart).
 * web_tests/c02_toggle_button.spec.js checks that each screen shows these
 * texts, so that a change to them is caught.
 */
export const EXAMPLE_SCREENS = {
  'good-icon-button': ['Icon button that stays pressed', 'Good example for Toggle button. Material.'],
  'good-toggle-buttons': ['Row of toggle buttons', 'Good example for Toggle button. Material.'],
  'good-cupertino': ['Cupertino button that stays pressed', 'Good example for Toggle button. Cupertino.'],
  'good-custom': ['Custom toggle button with an on or off state', 'Good example for Toggle button. Widgets layer.'],
  'bad-selected-only': [
    'Icon button with isSelected alone', 'Bad example for Toggle button. Material.',
    'Defect: While off it is read only "Bold, button": nothing says it is a toggle. On, it is "selected", and on the web "current item", a state that is not pressed.',
  ],
  'bad-no-state': [
    'Custom toggle button exposed as a plain button', 'Bad example for Toggle button. Widgets layer.',
    'Defect: A screen reader says "Mute, button" whether it is on or off: only the drawing changes.',
  ],
  'bad-label-changes': [
    'Toggle button whose name changes with its state', 'Bad example for Toggle button. Material.',
    'Defect: The name is "Mute", then "Unmute": it changes every time the state does, and "Unmute" with "on" can be taken either way.',
  ],
};

/** The stops VoiceOver reads above the "Example" heading of `slug`'s screen. */
export const screenStops = (slug) => {
  const [title, ...lines] = EXAMPLE_SCREENS[slug];
  return [`heading level 1 ${title}`, ...lines];
};

/**
 * Judges one walk of an example screen: `stops` in order, whether the walk
 * reached the end, `expected`, everything VoiceOver must say after the
 * "Example" heading, in order, ending with the change count, and `screen`,
 * the stops known to come before the heading (screenStops). Returns
 * `{ verdict, reason }`, the verdict one of:
 *
 * - "wrong": a stop that cannot be explained. The example's part of the
 *   walk is everything after the heading; in a walk that did not read the
 *   heading, everything after the run of `screen` stops it began with.
 *   Every stop there must be in `expected`, each at most once and in its
 *   order: anything else (an empty phrase, a count that is not the
 *   expected one, one of the screen's own stops out of its place) fails
 *   the test whichever try it is in.
 * - "complete": the heading was read, the end was reached, and the stops
 *   after the heading are exactly `expected`.
 * - "incomplete": a walk that fell short with nothing unexplained in it: an
 *   empty walk, one that read only the screen's own stops, or one whose
 *   example part is some of `expected`, in order, without the heading or
 *   without reaching the end. The walk may be tried again.
 *
 * Before the heading, in a walk that read it, only the screen's own stops
 * may stand, each at most once and in their order; anything else there is
 * "wrong" too. The one exception: an empty phrase as the first stop, in the
 * place of the screen's level 1 heading, which WebKit was seen to read so.
 * In a walk that did not read the heading an empty stop is "wrong".
 */
export function judgeExampleWalk(stops, reachedEnd, expected, screen = []) {
  if (stops.length === 0) return { verdict: 'incomplete', reason: 'nothing was read' };
  const heading = stops.indexOf(EXAMPLE_HEADING);
  let from = heading + 1;
  if (heading < 0) {
    // The run of the screen's own stops the walk began with, in their order.
    from = 0;
    let at = -1;
    while (from < stops.length && screen.indexOf(stops[from], at + 1) > at) {
      at = screen.indexOf(stops[from], at + 1);
      from++;
    }
  } else {
    // Before the heading, only the screen's own stops, in their order. The
    // first of them, the screen's level 1 heading, may be read as an empty
    // phrase: WebKit did so on three screens in one run (review round 4,
    // docs/evidence/probes/c02/voiceover-web-round4-fail.md.txt), for a
    // reason not known. Only as the first stop, in that heading's place, and
    // only in a walk that read the "Example" heading.
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

/** runWalks for the comparison page, judged by judgeControlWalk. */
export const runControlWalks = (walkOnce, options) => runWalks(walkOnce, judgeControlWalk, options);
