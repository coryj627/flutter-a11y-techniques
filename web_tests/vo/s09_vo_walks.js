// How web_tests/vo/s09_content_grouping_vo.spec.js judges and repeats its
// VoiceOver walks. Kept apart from the spec, with no VoiceOver and no
// browser, so that web_tests/s09_content_grouping.spec.js can test it on
// made-up walks in CI. A copy of C04's c04_vo_walks.js, by way of C18's (not
// imported: those files are other techniques'), with S09's screens; the
// judge is S08's (s08_vo_walks.js, on the principal's rule of 2026-11-26),
// which walks an empty capture again and leaves out VoiceOver's help
// message.

import { VO_HELP } from './vo_logic.js';

/** The heading every example screen has, as VoiceOver reads it. */
export const EXAMPLE_HEADING = 'heading level 2 Example';

/**
 * What each S09 example screen shows above its "Example" heading, as
 * VoiceOver reads it: the screen's title as a level 1 heading, the line
 * that says whether it is a good or a bad example, and a bad example's
 * defect (ExampleScreen in lib/app/screens.dart, with the titles and
 * defects of lib/techniques/s09_content_grouping/s09_content_grouping.dart).
 * No S09 example is flagged as a custom solution, so no screen has the
 * custom solution note. web_tests/s09_content_grouping.spec.js checks that
 * each screen shows these texts, so that a change to them is caught.
 */
export const EXAMPLE_SCREENS = {
  'good-merged-facts': [
    'Each label merged with its value', 'Good example for Content grouping. Widgets layer.',
  ],
  'good-cupertino': [
    'Cupertino rows, each one element', 'Good example for Content grouping. Cupertino.',
  ],
  'good-named-group': [
    'Buttons in a group named by its question', 'Good example for Content grouping. Material.',
  ],
  'good-tap-target': [
    'Icon and text as one button', 'Good example for Content grouping. Material.',
  ],
  'bad-split-facts': [
    'Labels and values in separate rows', 'Bad example for Content grouping. Widgets layer.',
    'Defect: Both labels are read first, then both values.',
  ],
  'bad-merged-group': [
    'Question and buttons merged', 'Bad example for Content grouping. Material.',
    "Defect: The question and both buttons are one button, whose action is On's.",
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
 * - "wrong": a stop that READ something other than the one expected in its
 *   place (a stop read in other words, a stop skipped so that a later one
 *   comes early, a stop after the last expected one), or a walk that
 *   reached the end of the screen with any expected stop not read, the
 *   title, the description, the heading, or a control included. This
 *   fails the test whichever try it is in, and is looked for first: a walk
 *   with a wrong reading is wrong even if a capture in it also failed.
 * - "incomplete": a walk whose capture failed or fell short, with nothing
 *   wrong read in it: a stop read as an empty phrase (the AppleScript read
 *   of VoiceOver's last phrase gave nothing for a move that changed the
 *   cursor's position), or a walk cut short before the end (it ran out of
 *   moves) with every stop so far the expected one in its place. Only such
 *   a walk may be walked again (runWalks, at most three walks, each
 *   logged), and an empty phrase never passes: no expected stop is empty,
 *   so three such walks fail the test.
 * - "complete": the walk reached the end and read exactly the whole screen,
 *   with no empty stop.
 *
 * A stop that is VoiceOver's help message ("You are currently on …", VO_HELP) is left out first, wherever it is:
 * it says where the cursor already is. Its words are never checked, and a
 * help message given in place of an element's own speech leaves that
 * element unread, which fails as a missing stop. S08's fourth recording
 * (docs/evidence/probes/s08/voiceover-web-round4-fail.md.txt, WebKit) read
 * every expected stop and then one more, the list's help message; no S09
 * recording has had one yet.
 *
 * An empty stop holds the place of the stop expected there: the walk that
 * gave one (S09's first recording, WebKit, bad-merged-group, the screen's
 * level 1 heading; docs/evidence/probes/s09/voiceover-web-round1-fail.md.txt,
 * as in S08's second and third) read every later stop in its place. This is the rule the
 * principal set on 2026-11-26: an empty reading is a failed capture, walked
 * again, and a reading of the wrong words fails for good. C04's and S06's
 * judges count an empty phrase as a wrong stop; C02's lets it stand for
 * WebKit's level 1 heading. S08's and S09's let it stand for nothing.
 */
export function judgeExampleWalk(walked, reachedEnd, expected, screen = []) {
  // VoiceOver's own help message (VO_HELP, vo_logic.js) is its speech about
  // where its cursor already is, not a stop of the page: it is left out
  // before the walk is judged. The walk itself already puts the phrase
  // logged for a move in place of a help message (walkToEnd's
  // `loggedForHelp`, phraseForMove); what is left out here is a help
  // message that came anyway, such as one given after a pause on the last
  // element, where the cursor no longer moves.
  const stops = walked.filter((stop) => !VO_HELP.test(stop));
  const whole = [...screen, EXAMPLE_HEADING, ...expected];
  const empty = [];
  for (let i = 0; i < stops.length; i++) {
    if (stops[i] === '') {
      empty.push(i + 1);
      continue;
    }
    if (i >= whole.length) {
      return { verdict: 'wrong', reason: `"${stops[i]}" was read after the last expected stop` };
    }
    if (stops[i] !== whole[i]) {
      return { verdict: 'wrong', reason: `stop ${i + 1} was "${stops[i]}" where "${whole[i]}" was expected` };
    }
  }
  if (reachedEnd && stops.length < whole.length) {
    return {
      verdict: 'wrong',
      reason: `the walk reached the end after ${stops.length} of the ${whole.length} expected stops; "${whole[stops.length]}" was never read`,
    };
  }
  if (empty.length > 0) {
    return {
      verdict: 'incomplete',
      reason: `the capture failed: stop${empty.length > 1 ? 's' : ''} ${empty.join(', ')} read as an empty phrase, nothing else wrong`,
    };
  }
  if (stops.length === whole.length) {
    return reachedEnd
      ? { verdict: 'complete', reason: 'the whole screen, every stop in its place' }
      : { verdict: 'incomplete', reason: 'every expected stop was read, but the walk did not reach the end' };
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
