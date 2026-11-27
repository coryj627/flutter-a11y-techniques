// L4 on web for S12 Hiding content from AT: what VoiceOver on macOS speaks
// for each example. Needs Guidepup's setup and macOS automation permissions
// on the machine. Run through `python3 tool/voiceover_web.py S12`, which
// also writes the transcript.
//
// No test in this file is retried by the runner. The shared config retries
// a failed test twice, and a retry that passes makes the run pass, so a wrong
// reading on the first attempt would be hidden. Each test retries instead,
// itself, only a walk cut short before the end of the screen with every stop
// right so far, or a walk whose capture failed (a stop read as an empty
// phrase) with nothing wrong read in it (runWalks and judgeExampleWalk in
// s12_vo_walks.js, a copy of S08's). Every walk must read the whole screen,
// the title and the description, the "Example" heading, and every expected
// stop after it, each in its place: a wrong stop, or a walk that reached the
// end with any expected stop not read, fails the test for good, and every
// try is logged, so every attempt is in the transcript.
//
// The expected lists (EXPECTED_STOPS in s12_vo_walks.js) were written as
// predictions; the first recording, 2026-11-27
// (docs/evidence/S12/voiceover-web.md), read every one as written.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { VO_HELP, cursorBounds, lastPhrase, phraseForMove, walkToEnd } from './vo_helpers.js';
import {
  EMPTY_STOP, EXPECTED_STOPS, NO_STOPS, collectWalk, judgeCollectedWalk, runWalks, screenStops, unresolvedText,
  witnessText,
} from './s12_vo_walks.js';

test.describe.configure({ retries: 0 });

const EXAMPLES = EXPECTED_STOPS;

/**
 * One walk of the screen: walkToEnd with no moves starts it exactly as the
 * shared walk does (from Back, once VoiceOver is quiet), and collectWalk
 * (s12_vo_walks.js) makes the moves, keeps each stop's cursor position, and
 * accepts the end only with its witness, a move back and a move forward
 * again. A help message VoiceOver gives for a move is replaced by the
 * phrase Guidepup logged for it (phraseForMove), as the form techniques'
 * walks do; one that comes anyway is left out by the judge only when it is
 * about the stop before it, at the same position.
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
    start: await cursorBounds(),
    max,
  });
}

for (const [slug, expected] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/S12/${slug}`, { waitUntil: 'load' });
    await expect(page.getByRole('heading', { name: 'Example', exact: true, level: 2 })).toBeVisible();
    await page.waitForTimeout(600);
    let latest;
    const { verdict, reason, walks } = await runWalks(
      async () => {
        latest = await walkOnce(page, voiceOver, browserName, 40);
        return latest;
      },
      // A failed end witness is wrong for good (judgeCollectedWalk).
      () => judgeCollectedWalk(latest, expected, screenStops(slug)),
      {
        log: (walk, stops, judged) => {
          // Every try is logged whole, the screen's own stops included, so
          // that the transcript keeps each walk's identity: its browser, its
          // example, its try, and the title, description, and heading it
          // read. An empty phrase is written "(empty)" and a walk with no
          // stops "(nothing)". A walk that read its end witness logs it on
          // a row of its own, `<slug>-walk-<n>-end`, and every walk logs its
          // unresolved reads, `<slug>-walk-<n>-unresolved` ("none" or each). judgeTranscript in
          // s12_vo_walks.js reads them back, and
          // web_tests/s12_hiding_content.spec.js judges the committed
          // transcript again from these rows alone.
          const shown = stops.map((s) => (s === '' ? EMPTY_STOP : s)).join(' / ') || NO_STOPS;
          console.log(`S12VO ${browserName} ${slug}-walk-${walk} | ${shown} (${judged.verdict}: ${judged.reason})`);
          if (latest.witness) console.log(`S12VO ${browserName} ${slug}-walk-${walk}-end | ${witnessText(latest.witness)}`);
          console.log(`S12VO ${browserName} ${slug}-walk-${walk}-unresolved | ${unresolvedText(latest.unresolved)}`);
        },
      });
    expect(verdict, `${slug}, walk ${walks}: ${reason}`).toBe('complete');
  });
}
