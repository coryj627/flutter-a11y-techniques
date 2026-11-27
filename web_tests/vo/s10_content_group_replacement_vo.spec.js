// L4 on web for S10 Content group replacement: what VoiceOver on macOS
// speaks for each example. Needs Guidepup's setup and macOS automation
// permissions on the machine. Run through
// `python3 tool/voiceover_web.py S10`, which also writes the transcript.
//
// No test in this file is retried by the runner. The shared config retries
// a failed test twice, and a retry that passes makes the run pass, so a wrong
// reading on the first attempt would be hidden. Each test retries instead,
// itself, only a walk cut short before the end of the screen with every stop
// right so far, or a walk whose capture failed (a stop read as an empty
// phrase) with nothing wrong read in it (runWalks and judgeExampleWalk in
// s10_vo_walks.js, a copy of S08's judge). Every walk must read the whole
// screen, the title and the description, the "Example" heading, and every
// expected stop after it, each in its place: a wrong stop, a stop past the
// expected end (empty or not), or a walk that reached the end with any
// expected stop not read, fails the test for good, and every try is logged,
// so every attempt is in the transcript. A help message is left out only
// when it is at the position of the stop before it and names that stop's
// spoken role (helpAfterStop).
//
// The expected lists (EXPECTED_STOPS and EXPECTED_AFTER_ADDING in
// s10_vo_walks.js) were written before any S10 recording; the recording
// of 2026-11-27 (docs/evidence/S10/voiceover-web.md) read every one
// exactly, in Chromium and WebKit (one WebKit walk walked again after an
// empty title, a failed capture).
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { VO_HELP, cursorBounds, lastPhrase, phraseForMove, walkToEnd } from './vo_helpers.js';
import {
  EXAMPLE_HEADING, EXPECTED_AFTER_ADDING, EXPECTED_STOPS, judgeExampleWalk, runWalks, screenStops,
} from './s10_vo_walks.js';

test.describe.configure({ retries: 0 });

const WORDS = 'Rating: 3.4 out of 5 stars, based on 856 reviews';
const WORDS_AFTER = 'Rating: 3.4 out of 5 stars, based on 857 reviews';

/**
 * walkToEnd (vo_helpers.js), keeping the cursor's position at each stop, so
 * that the judge can tie a help message to the stop before it. A copy of
 * S08's walkWithPositions: walkToEnd with no moves starts it exactly as the
 * shared walk does (from Back, once VoiceOver is quiet), and the moves
 * follow its rule (stopsToEnd in vo_logic.js: a move is a stop when the
 * cursor moved or a new phrase was spoken; two moves in a row that do
 * neither are the end), with `loggedForHelp` as the form techniques use it
 * (phraseForMove). The one difference is that each stop's position is
 * kept. Resolves to `{ stops, positions, reachedEnd }`.
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

async function walkScreen(page, voiceOver, browserName, slug, expected, row) {
  let positions;
  const { verdict, reason, walks } = await runWalks(
    async () => {
      const walk = await walkWithPositions(page, voiceOver, browserName, 40);
      positions = walk.positions;
      return walk;
    },
    (stops, reachedEnd) => judgeExampleWalk(stops, reachedEnd, expected, screenStops(slug), positions),
    {
      log: (walk, stops, judged) => {
        // A complete walk read the screen's own stops exactly as listed, so
        // only what follows the heading is shown; any other try is shown
        // whole.
        const start = stops.indexOf(EXAMPLE_HEADING);
        const shown = (judged.verdict === 'complete' ? stops.slice(start + 1) : stops).join(' / ') || '(nothing)';
        console.log(`S10VO ${browserName} ${row}-walk-${walk} | ${shown} (${judged.verdict}: ${judged.reason})`);
      },
    });
  expect(verdict, `${row}, walk ${walks}: ${reason}`).toBe('complete');
}

async function openScreen(page, slug) {
  await page.goto(`/#/t/S10/${slug}`, { waitUntil: 'load' });
  await expect(page.getByRole('heading', { name: 'Example', exact: true, level: 2 })).toBeVisible();
  await page.waitForTimeout(600);
}

for (const [slug, expected] of Object.entries(EXPECTED_STOPS)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await openScreen(page, slug);
    await walkScreen(page, voiceOver, browserName, slug, expected, slug);
  });
}

for (const [slug, expected] of Object.entries(EXPECTED_AFTER_ADDING)) {
  test(`voiceover reads ${slug} after a review is added`, async ({ page, voiceOver, browserName }) => {
    await openScreen(page, slug);
    await page.locator(`[flt-semantics-identifier="s10-${slug}-add"]`).click();
    // The witness: the row shows 857 (the identifier of a test-only empty node),
    // so a click that did nothing cannot pass as a stale replacement.
    await expect(page.locator(`[flt-semantics-identifier="s10-${slug}-shows-857"]`)).toHaveCount(1);
    await expect(page.getByText(slug === 'bad-stale' ? WORDS : WORDS_AFTER, { exact: true })).toHaveCount(1);
    // The pointer is moved off the button, so that nothing is hovered.
    await page.mouse.move(0, 0);
    await page.waitForTimeout(600);
    await walkScreen(page, voiceOver, browserName, slug, expected, `${slug}-after`);
  });
}
