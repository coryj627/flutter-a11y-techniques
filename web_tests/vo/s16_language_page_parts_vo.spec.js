// L4 on web for S16 Language of page and parts: what VoiceOver on macOS
// speaks for each example. Needs Guidepup's setup and macOS automation
// permissions on the machine. Run through `python3 tool/voiceover_web.py
// S16`, which also writes the transcript.
//
// No test in this file is retried by the runner. The shared config retries
// a failed test twice, and a retry that passes makes the run pass, so a wrong
// reading on the first attempt would be hidden. Each test retries instead,
// itself, only a walk cut short before the end of the screen with every stop
// right so far, or a walk whose capture failed (a stop read as an empty
// phrase, or a move that read nothing new mid-walk) with nothing wrong
// read in it (runWalks, collectWalk, and judgeCollectedWalk in
// s16_vo_walks.js). Every walk must read the whole screen, the title and
// the description, the "Example" heading, and every expected stop after it,
// each in its place, and its end must be witnessed by a move back and a
// move forward again: a wrong stop, a failed witness, or a walk that
// reached the end with any expected stop not read, fails the test for
// good, and every try is logged, so every attempt is in the transcript.
// The judge of a walk's stops is S08's; the walk is written to the rules of
// S12's collector.
//
// VoiceOver's last phrase is text: whether a French part was spoken in a
// French voice is not in it. What is judged is the words and the stops.
// The expected lists were predictions, and the first recording
// (2026-11-27, docs/evidence/probes/s16/voiceover-web-round1-pass.md.txt)
// read every example as predicted, in Chromium and WebKit, each on its
// first walk. That recording showed only what follows the "Example"
// heading of a complete walk. The second
// (docs/evidence/probes/s16/voiceover-web-round2-pass.md.txt) logged every
// walk whole and passed, before the walk kept its unchanged reads and
// witnessed its end; it has no end or unresolved-reads rows.
// Each test opens its example in a page of its own, from a fresh load, so
// that bad-override's French (FL-360) does not reach another example.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { VO_HELP, cursorBounds, lastPhrase, phraseForMove, walkToEnd } from './vo_helpers.js';
import {
  EMPTY_STOP, EXPECTED_STOPS, NO_STOPS, collectWalk, judgeCollectedWalk, runWalks, screenStops, unresolvedText,
  witnessText,
} from './s16_vo_walks.js';

test.describe.configure({ retries: 0 });

const EXAMPLES = EXPECTED_STOPS;

/**
 * One walk of the screen: walkToEnd with no moves starts it exactly as the
 * shared walk does (from Back, once VoiceOver is quiet), and collectWalk
 * (s16_vo_walks.js) makes the moves, keeps each stop's cursor position and
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
    start: await cursorBounds(),
    max,
  });
}

for (const [slug, expected] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/S16/${slug}`, { waitUntil: 'load' });
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
          // `<slug>-walk-<n>-end`, and every walk logs its unresolved
          // reads, `<slug>-walk-<n>-unresolved` ("none" or each).
          // judgeTranscript in s16_vo_walks.js reads them back, and
          // web_tests/s16_language_page_parts.spec.js judges the committed
          // transcript again from these rows alone.
          const shown = stops.map((s) => (s === '' ? EMPTY_STOP : s)).join(' / ') || NO_STOPS;
          console.log(`S16VO ${browserName} ${slug}-walk-${walk} | ${shown} (${judged.verdict}: ${judged.reason})`);
          if (latest.witness) console.log(`S16VO ${browserName} ${slug}-walk-${walk}-end | ${witnessText(latest.witness)}`);
          console.log(`S16VO ${browserName} ${slug}-walk-${walk}-unresolved | ${unresolvedText(latest.unresolved)}`);
        },
      });
    expect(verdict, `${slug}, walk ${walks}: ${reason}`).toBe('complete');
  });
}
