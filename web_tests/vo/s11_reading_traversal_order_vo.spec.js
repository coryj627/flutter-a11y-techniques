// L4 on web for S11 Reading and traversal order: the order VoiceOver on
// macOS moves through each example in, and what it says at each stop.
// Needs Guidepup's setup and macOS automation permissions on the machine.
// Run through `python3 tool/voiceover_web.py S11`, which also writes the
// transcript.
//
// No test in this file is retried by the runner. The shared config retries
// a failed test twice, and a retry that passes makes the run pass, so a wrong
// reading on the first attempt would be hidden. Each test retries instead,
// itself, only a walk cut short before the end of the screen with every stop
// right so far, or a walk whose capture failed (a stop read as an empty
// phrase) with nothing wrong read in it (runWalks and judgeExampleWalk in
// s11_vo_walks.js, S08's judge). Every walk must read the whole screen, the
// title and the description, the "Example" heading, and every expected stop
// after it, each in its place: a wrong stop, or a walk that reached the end
// with any expected stop not read, fails the test for good, and every try is
// logged, so every attempt is in the transcript.
//
// The expected lists were written before any S11 recording, from the order
// of the elements in the page, which the web tree spec measures
// (web_tests/s11_reading_traversal_order.spec.js), and from how VoiceOver
// read headings, text, and buttons in earlier techniques' recordings. The
// first recording (2026-11-26, docs/evidence/S11/voiceover-web.md) read
// exactly these lists in Chromium and WebKit: every walk complete on its
// first try but WebKit's bad-columns-mixed, whose first walk read the
// screen's title as an empty phrase and whose second was complete. No help
// message came in any walk.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { VO_HELP, cursorBounds, lastPhrase, phraseForMove, walkToEnd } from './vo_helpers.js';
import { EXAMPLE_HEADING, judgeExampleWalk, runWalks, screenStops } from './s11_vo_walks.js';

test.describe.configure({ retries: 0 });

/**
 * walkToEnd (vo_helpers.js), keeping the cursor's position at each stop, so
 * that the judge can tie a help message to the stop before it (S08's walk,
 * mirrored). walkToEnd returns no positions, so the walk is made here:
 * walkToEnd with no moves starts it exactly as the shared walk does (from
 * Back, once VoiceOver is quiet), and the moves follow its rule (stopsToEnd
 * in vo_logic.js: a move is a stop when the cursor moved or a new phrase was
 * spoken; two moves in a row that do neither are the end), with
 * `loggedForHelp` as the form techniques use it (phraseForMove). The one
 * difference is that each stop's position is kept. Resolves to
 * `{ stops, positions, reachedEnd }`.
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

const ROUTE = ['heading level 3 Route', 'Park at the gate.', 'Climb the ridge.', 'Walk back.', 'Save route button'];
const BRING = ['heading level 3 Bring', 'Water', 'A map', 'Save list button'];
const COUNTS = ['Route saves: 0', 'List saves: 0'];

// slug -> everything VoiceOver speaks after the "Example" heading, to the
// end of the screen, in order, one entry for each element its cursor stops
// on. Because every stop is listed, the lists also show the order.
const EXAMPLES = {
  // One column, then the other.
  'good-columns': [...ROUTE, ...BRING, ...COUNTS],
  'good-sort-keys': [...ROUTE, ...BRING, ...COUNTS],
  // Bad examples: the defect must be audible. Row by row, both titles
  // first, as the page's order is in Chromium at the default window.
  'bad-columns-mixed': [
    ROUTE[0], BRING[0], ROUTE[1], BRING[1], ROUTE[2], BRING[2], ROUTE[3], ROUTE[4], BRING[3], ...COUNTS,
  ],
  // The Bring title second, then the route, then the list with no title.
  'bad-key-missing': [ROUTE[0], BRING[0], ...ROUTE.slice(1), ...BRING.slice(1), ...COUNTS],
};

for (const [slug, expected] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/S11/${slug}`, { waitUntil: 'load' });
    await expect(page.getByRole('heading', { name: 'Example', exact: true, level: 2 })).toBeVisible();
    await page.waitForTimeout(600);
    let positions;
    const { verdict, reason, walks } = await runWalks(
      // A help message VoiceOver gives for a move is replaced by the phrase
      // Guidepup logged for it (phraseForMove); one that comes anyway is
      // left out by the judge only when it is about the stop before it, at
      // the same position.
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
          console.log(`S11VO ${browserName} ${slug}-walk-${walk} | ${shown} (${judged.verdict}: ${judged.reason})`);
        },
      });
    expect(verdict, `${slug}, walk ${walks}: ${reason}`).toBe('complete');
  });
}
