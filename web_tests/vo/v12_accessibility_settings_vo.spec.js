// L4 on web for V12 Detecting accessibility settings: what VoiceOver on
// macOS speaks for each example. Needs Guidepup's setup and macOS
// automation permissions on the machine. Run through `python3
// tool/voiceover_web.py V12`, which also writes the transcript.
//
// A copy of S16's s16_language_page_parts_vo.spec.js, whole, with V12's
// screens (v12_vo_walks.js, itself a copy of s16_vo_walks.js).
//
// No test in this file is retried by the runner. The shared config retries
// a failed test twice, and a retry that passes makes the run pass, so a wrong
// reading on the first attempt would be hidden. Each test retries instead,
// itself, only a walk cut short before the end of the screen with every stop
// right so far, or a walk whose capture failed (a stop read as an empty
// phrase, or a move that read nothing new mid-walk) with nothing wrong
// read in it (runWalks, collectWalk, and judgeCollectedWalk in
// v12_vo_walks.js). Every walk must read the whole screen, the title and
// the description, the "Example" heading, and every expected stop after it,
// each in its place, and its end must be witnessed by a move back and a
// move forward again: a wrong stop, a failed witness, or a walk that
// reached the end with any expected stop not read, fails the test for
// good, and every try is logged, so every attempt is in the transcript.
//
// What is judged is what each line says. VoiceOver running does not change
// it on the web: the web engine's accessible navigation is whether the
// app's semantics are on (FL-500), and the app turns them on at start. The
// expected lists were predictions from the web tree spec's measurements
// (v12_vo_walks.js), and the first recording (recorded 2026-11-28,
// docs/evidence/V12/voiceover-web.md) read every one as predicted, in
// Chromium and WebKit, each on its first walk. The browsers' colour scheme,
// reduced motion, forced colours, and contrast are Playwright's defaults
// (light, no-preference, none, no-preference: its documented defaults,
// which this config does not change), not the Mac's: this Mac's appearance
// was Dark during the recording, and every walk read "Dark mode: off".
// Each test opens its example in a page of its own, from a fresh load.
// V12 does not use Guidepup's `voiceOverTest` fixture as it is: it swallows a
// failed `stop()`. This fixture does what that one does (the same start
// options, the same `navigateToWebContent`, from @guidepup/playwright's
// lib/voiceOverTest.js, read) inside withVoiceOverState (v12_vo_state.js),
// which reads the Mac's VoiceOver state with `pgrep -x VoiceOver` before it
// starts, puts that state back after the walk and Guidepup's stop (Guidepup's
// own restart of the user's VoiceOver if it was on, `killall VoiceOver` if it
// was off), reads it again the same way, and fails the test on a failed
// start, stop, or restore, Playwright keeping the walk's own failure beside
// it. Each state is logged on a `V12VOSTATE` line.
import { test as base, expect } from '@playwright/test';
import { voiceOver as guidepupVoiceOver } from '@guidepup/guidepup';
import applicationIds from '@guidepup/playwright/lib/applicationIdMap.js';
import navigation from '@guidepup/playwright/lib/navigateVoiceOverToWebContent.js';
import userVoiceOver from '@guidepup/guidepup/lib/macOS/VoiceOver/startUserVoiceOver.js';
import { quitVoiceOver, voiceOverRunning, withVoiceOverState } from './v12_vo_state.js';
import { VO_HELP, cursorBounds, lastPhrase, phraseForMove, walkToEnd } from './vo_helpers.js';
import {
  EMPTY_STOP, EXPECTED_STOPS, NO_STOPS, collectWalk, judgeCollectedWalk, runWalks, screenStops, startText,
  unresolvedText, witnessText,
} from './v12_vo_walks.js';

const test = base.extend({
  voiceOver: async ({ browserName, page }, use, testInfo) => {
    const applicationId = applicationIds.applicationIdMap[browserName];
    if (!applicationId) throw new Error(`Browser ${browserName} is not recognised.`);
    guidepupVoiceOver.navigateToWebContent = ({ capture } = {}) => navigation.navigateVoiceOverToWebContent({
      voiceOver: guidepupVoiceOver, page, applicationId, capture,
    });
    await withVoiceOverState({
      isRunning: () => voiceOverRunning(),
      start: () => guidepupVoiceOver.start({ capture: 'initial' }),
      use: () => use(guidepupVoiceOver),
      stop: () => guidepupVoiceOver.stop(),
      restart: () => userVoiceOver.startUserVoiceOver(),
      quit: () => quitVoiceOver(),
      log: (line) => console.log(`V12VOSTATE ${browserName} ${testInfo.title} | ${line}`),
    });
  },
});

test.describe.configure({ retries: 0 });

const EXAMPLES = EXPECTED_STOPS;

/**
 * One walk of the screen: walkToEnd with no moves starts it exactly as the
 * shared walk does (from Back, once VoiceOver is quiet), and collectWalk
 * (v12_vo_walks.js) makes the moves, keeps each stop's cursor position and
 * every unchanged read, and accepts the end only with its witness, a move
 * back and a move forward again. A help message VoiceOver gives for a move
 * is replaced by the phrase Guidepup logged for it (phraseForMove), as the
 * form techniques' walks do; one that comes anyway is left out by the
 * judge only when it is about the stop before it, at the same position.
 */
async function walkOnce(page, voiceOver, browserName, max = 40) {
  await walkToEnd(page, voiceOver, browserName, 0);
  const capture = async () => {
    let phrase = await lastPhrase();
    if (VO_HELP.test(phrase)) {
      phrase = phraseForMove(phrase, (await voiceOver.lastSpokenPhrase()).replace(/\s+/g, ' ').trim());
    }
    return { phrase, position: await cursorBounds() };
  };
  return collectWalk({
    next: () => voiceOver.next(),
    previous: () => voiceOver.previous(),
    capture,
    // The capture before the first move, on Back, which the first move is
    // compared with like every other.
    start: await capture(),
    max,
  });
}

for (const [slug, expected] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/V12/${slug}`, { waitUntil: 'load' });
    await expect(page.getByRole('heading', { name: 'Example', exact: true, level: 2 })).toBeVisible();
    await page.waitForTimeout(600);
    let latest;
    const { verdict, reason, walks } = await runWalks(
      async () => {
        latest = await walkOnce(page, voiceOver, browserName, 40);
        return latest;
      },
      // A failed end witness is wrong for good, and an unresolved read
      // makes the walk incomplete (judgeCollectedWalk).
      () => judgeCollectedWalk(latest, expected, screenStops(slug)),
      {
        log: (walk, stops, judged) => {
          // Every try is logged whole, the screen's own stops included, so
          // that the committed transcript keeps each walk's browser,
          // example, try, and every stop it read. An empty phrase is written
          // "(empty)" and a walk with no stops "(nothing)". A walk that read
          // its end witness logs it on a row of its own,
          // `<slug>-walk-<n>-end`, and every walk logs its start capture,
          // `<slug>-walk-<n>-start`, and its unresolved reads, `<slug>-walk-<n>-unresolved` ("none" or each).
          // judgeTranscript in v12_vo_walks.js reads them back, and
          // web_tests/v12_accessibility_settings.spec.js judges the committed
          // transcript again from these rows alone.
          const shown = stops.map((s) => (s === '' ? EMPTY_STOP : s)).join(' / ') || NO_STOPS;
          console.log(`V12VO ${browserName} ${slug}-walk-${walk} | ${shown} (${judged.verdict}: ${judged.reason})`);
          console.log(`V12VO ${browserName} ${slug}-walk-${walk}-start | ${startText(latest.start)}`);
          if (latest.witness) console.log(`V12VO ${browserName} ${slug}-walk-${walk}-end | ${witnessText(latest.witness)}`);
          console.log(`V12VO ${browserName} ${slug}-walk-${walk}-unresolved | ${unresolvedText(latest.unresolved)}`);
        },
      });
    expect(verdict, `${slug}, walk ${walks}: ${reason}`).toBe('complete');
  });
}
