// How web_tests/vo/c13_snackbar_vo.spec.js judges and repeats its
// VoiceOver walks. Kept apart from the spec, with no VoiceOver and no
// browser, so that web_tests/c13_snackbar.spec.js can test it on made-up
// walks in CI. Written after C04's c04_vo_walks.js (not imported: that file
// is another technique's). A C13 walk reads a screen whose message is shown,
// and a banner's message sits above the screen's description, so the judge
// takes the whole screen as one list.

/** The heading every example screen has, as VoiceOver reads it. */
export const EXAMPLE_HEADING = 'heading level 2 Example';

/**
 * What each C13 example screen shows above its "Example" heading, as
 * VoiceOver reads it: the screen's title as a level 1 heading, the line
 * that says whether it is a good or a bad example, and a bad example's
 * defect (ExampleScreen in lib/app/screens.dart, with the titles and
 * defects of lib/techniques/c13_snackbar/c13_snackbar.dart). No C13 example
 * is a custom solution (docs/custom-solutions.md), so no screen has the
 * note. web_tests/c13_snackbar.spec.js checks that each screen shows these
 * texts, so that a change to them is caught.
 */
export const EXAMPLE_SCREENS = {
  'good-action': ['SnackBar with an action', 'Good example for Snackbar and transient messages. Material.'],
  'good-message': ['SnackBar whose news is also on the page', 'Good example for Snackbar and transient messages. Material.'],
  'good-banner': ['MaterialBanner', 'Good example for Snackbar and transient messages. Material.'],
  'bad-action-times-out': [
    'Action that times out', 'Bad example for Snackbar and transient messages. Material.',
    'Defect: Undo goes after four seconds, and nothing gives more time.',
  ],
  'bad-only-in-message': [
    'Information only in a SnackBar', 'Bad example for Snackbar and transient messages. Material.',
    'Defect: The code is shown for four seconds and nowhere else.',
  ],
  'bad-inline-banner': [
    'Banner put in the page', 'Bad example for Snackbar and transient messages. Material.',
    'Defect: The banner is not announced.',
  ],
};

/** The stops VoiceOver reads above the "Example" heading of `slug`'s screen. */
export const screenStops = (slug) => {
  const [title, ...lines] = EXAMPLE_SCREENS[slug];
  return [`heading level 1 ${title}`, ...lines];
};

/**
 * Judges one walk: `stops` in order, whether the walk reached the end of the
 * screen (two moves in a row that changed nothing), and `whole`, everything
 * VoiceOver must say from the stop after Back to the end of the screen, in
 * order. The walk must read exactly `whole`, every stop in its place and
 * nothing else. Returns `{ verdict, reason }`, the verdict one of:
 *
 * - "wrong": a stop that is not the one expected in its place (a stop read
 *   in other words, an empty phrase, a stop skipped so that a later one
 *   comes early, a stop after the last expected one), or a walk that
 *   reached the end of the screen with any expected stop not read. This
 *   fails the test whichever try it is in.
 * - "complete": the walk reached the end and read exactly `whole`.
 * - "incomplete": a walk cut short before the end (it ran out of moves)
 *   with nothing wrong so far. Only such a walk may be walked again.
 *
 * There is no exception for an empty first stop, as in C04.
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
 * Walks up to `tries` times with `walkOnce()`, which resolves to
 * `{ stops, reachedEnd }`, and judges each walk with
 * `judge(stops, reachedEnd)`. `log(walk, stops, judged)` is called for
 * every try. Stops at the first walk that is "wrong" or "complete" and
 * returns its verdict, with the number of walks made; if no try was either,
 * "incomplete". A wrong walk is never followed by another try.
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

/**
 * The whole screen of each example whose message stays, once it is shown,
 * as VoiceOver reads it from the stop after Back. Set from the first two
 * recordings (2026-11-22, docs/evidence/probes/c13/voiceover-web-round1-fail.md.txt
 * and voiceover-web-round2-fail.md.txt): the message is the group's name,
 * read with "group" on entering it, and is not a stop of its own inside
 * it; VoiceOver says "end of" the group on leaving it. The banner is read
 * straight after the screen's title, before its description, where it is
 * drawn.
 *
 * The browsers differ at Close, and at nothing else: Chromium read it
 * "Close Close", with no role, in both recordings, and WebKit "Close
 * button" in both. After the second recording's walk, Close's tooltip was
 * shown in both browsers. While it is shown the tree names the button
 * "Close Close" and keeps its role, a button
 * (docs/evidence/probes/c13/close_probe.txt; FL-249). Each browser's list
 * is exact.
 */
const CLOSE = { chromium: 'Close Close', webkit: 'Close button' };

/** The whole expected walk of `slug`, with its message shown, in `browserName`. */
export function shownWalk(slug, browserName) {
  if (!(browserName in CLOSE)) throw new Error(`no expected walk for ${browserName}`);
  switch (slug) {
    case 'good-action':
      return [
        ...screenStops('good-action'),
        EXAMPLE_HEADING,
        'Archive message button',
        'Archived: 1',
        'Message archived group',
        'Undo button',
        CLOSE[browserName],
        'end of Message archived group',
      ];
    case 'good-banner':
      return [
        screenStops('good-banner')[0],
        'You are offline. group',
        'Go online button',
        'end of You are offline. group',
        ...screenStops('good-banner').slice(1),
        EXAMPLE_HEADING,
        'Go offline button',
        'Status: offline',
      ];
    default:
      throw new Error(`no expected walk for ${slug}`);
  }
}

/** The examples whose screen is walked with the message shown. */
export const SHOWN_SLUGS = ['good-action', 'good-banner'];
