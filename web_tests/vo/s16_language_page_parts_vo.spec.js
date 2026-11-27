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
// phrase) with nothing wrong read in it (runWalks and judgeExampleWalk in
// s16_vo_walks.js). Every walk must read the whole screen, the title and
// the description, the "Example" heading, and every expected stop after it,
// each in its place: a wrong stop, or a walk that reached the end with any
// expected stop not read, fails the test for good, and every try is logged,
// so every attempt is in the transcript. The walk and the judge are S08's.
//
// VoiceOver's last phrase is text: whether a French part was spoken in a
// French voice is not in it. What is judged is the words and the stops.
// The expected lists were predictions, and the first recording
// (2026-11-27, docs/evidence/probes/s16/voiceover-web-round1-pass.md.txt)
// read every example as predicted, in Chromium and WebKit, each on its
// first walk. That recording showed only what follows the "Example"
// heading of a complete walk; every walk is now logged whole, and the
// second recording (2026-11-27, docs/evidence/S16/voiceover-web.md) passed
// with every walk whole.
// Each test opens its example in a page of its own, from a fresh load, so
// that bad-override's French (FL-360) does not reach another example.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { VO_HELP, cursorBounds, lastPhrase, phraseForMove, walkToEnd } from './vo_helpers.js';
import { EXPECTED_STOPS, judgeExampleWalk, runWalks, screenStops } from './s16_vo_walks.js';

test.describe.configure({ retries: 0 });

const EXAMPLES = EXPECTED_STOPS;

/**
 * walkToEnd (vo_helpers.js), keeping the cursor's position at each stop, so
 * that the judge can tie a help message to the stop before it. walkToEnd
 * returns no positions, so the walk is made here: walkToEnd with no moves
 * starts it exactly as the shared walk does (from Back, once VoiceOver is
 * quiet), and the moves follow its rule (stopsToEnd in vo_logic.js: a move
 * is a stop when the cursor moved or a new phrase was spoken; two moves in
 * a row that do neither are the end), with `loggedForHelp` as the form
 * techniques use it (phraseForMove). The one difference is that each
 * stop's position is kept. Resolves to `{ stops, positions, reachedEnd }`.
 */
async function walkWithPositions(page, voiceOver, browserName, max = 40) {
  await walkToEnd(page, voiceOver, browserName, 0);
  const stops = [];
  const positions = [];
  let position = await cursorBounds();
  let unmoved = 0;
  for (let i = 0; i < max; i++) {
    await voiceOver.next();
    let phrase = await lastPhrase();
    if (VO_HELP.test(phrase)) {
      phrase = phraseForMove(phrase, (await voiceOver.lastSpokenPhrase()).replace(/\s+/g, ' ').trim());
    }
    const now = await cursorBounds();
    const spokeAnew = phrase !== '' && stops.length > 0 && phrase !== stops[stops.length - 1];
    if (now === position && !spokeAnew) {
      unmoved++;
      if (unmoved === 2) return { stops, positions, reachedEnd: true };
      continue;
    }
    unmoved = 0;
    position = now;
    stops.push(phrase);
    positions.push(now);
  }
  return { stops, positions, reachedEnd: false };
}

for (const [slug, expected] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/S16/${slug}`, { waitUntil: 'load' });
    await expect(page.getByRole('heading', { name: 'Example', exact: true, level: 2 })).toBeVisible();
    await page.waitForTimeout(600);
    let positions;
    const { verdict, reason, walks } = await runWalks(
      // A help message VoiceOver gives for a move is replaced by the phrase
      // Guidepup logged for it (phraseForMove), as the form techniques'
      // walks do; one that comes anyway is left out by the judge only when
      // it is about the stop before it, at the same position.
      async () => {
        const walk = await walkWithPositions(page, voiceOver, browserName, 40);
        positions = walk.positions;
        return walk;
      },
      (stops, reachedEnd) => judgeExampleWalk(stops, reachedEnd, expected, screenStops(slug), positions),
      {
        log: (walk, stops, judged) => {
          // Every try is shown whole, the screen's own stops (title,
          // description, defect, heading) included, so that the committed
          // transcript can be judged again from what was recorded
          // (judgeTranscript in s16_vo_walks.js), never from stops rebuilt
          // from the expectations.
          const shown = stops.join(' / ') || '(nothing)';
          console.log(`S16VO ${browserName} ${slug}-walk-${walk} | ${shown} (${judged.verdict}: ${judged.reason})`);
        },
      });
    expect(verdict, `${slug}, walk ${walks}: ${reason}`).toBe('complete');
  });
}
