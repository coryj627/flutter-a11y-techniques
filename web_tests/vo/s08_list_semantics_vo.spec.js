// L4 on web for S08 List semantics: what VoiceOver on macOS speaks for each
// example. Needs Guidepup's setup and macOS automation permissions on the
// machine. Run through `python3 tool/voiceover_web.py S08`, which also
// writes the transcript.
//
// No test in this file is retried by the runner. The shared config retries
// a failed test twice, and a retry that passes makes the run pass, so a wrong
// reading on the first attempt would be hidden. Each test retries instead,
// itself, only a walk cut short before the end of the screen with every stop
// right so far, or a walk whose capture failed (a stop read as an empty
// phrase) with nothing wrong read in it (runWalks and judgeExampleWalk in
// s08_vo_walks.js). Every
// walk must read the whole screen, the title and the description, the
// "Example" heading, and every expected stop after it, each in its place:
// a wrong stop, or a walk that reached the end with any expected stop not
// read, fails the test for good, and every try is logged, so every attempt
// is in the transcript.
//
// The expected lists are what VoiceOver said in the first recording
// (2026-11-26, docs/evidence/probes/s08/voiceover-web-round1-fail.md.txt),
// which was judged against predictions written before any recording and
// failed: every list item was read with its place, and a list item whose
// text is merged into it as "empty group" (FL-315). The same was heard in
// Chromium and WebKit for every example but `good-material`, which has
// WebKit's reading only: Chromium quit during that walk, and VoiceOver read
// its crash dialog. Every later recording read good-material in Chromium
// as WebKit had; the fifth passed whole (docs/evidence/S08/voiceover-web.md).
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { VO_HELP, cursorBounds, lastPhrase, phraseForMove, walkToEnd } from './vo_helpers.js';
import { EXAMPLE_HEADING, EXPECTED_STOPS, judgeExampleWalk, runWalks, screenStops } from './s08_vo_walks.js';

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
    await page.goto(`/#/t/S08/${slug}`, { waitUntil: 'load' });
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
          // A complete walk read the screen's own stops exactly as listed,
          // so only what follows the heading is shown; any other try is
          // shown whole.
          const start = stops.indexOf(EXAMPLE_HEADING);
          const shown = (judged.verdict === 'complete' ? stops.slice(start + 1) : stops).join(' / ') || '(nothing)';
          console.log(`S08VO ${browserName} ${slug}-walk-${walk} | ${shown} (${judged.verdict}: ${judged.reason})`);
        },
      });
    expect(verdict, `${slug}, walk ${walks}: ${reason}`).toBe('complete');
  });
}
