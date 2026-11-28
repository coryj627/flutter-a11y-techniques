// L4 on web for S10 Content group replacement: what VoiceOver on macOS
// speaks for each example. Needs Guidepup's setup and macOS automation
// permissions on the machine. Run through
// `python3 tool/voiceover_web.py S10`, which also writes the transcript.
//
// No test in this file is retried by the runner. The shared config retries
// a failed test twice, and a retry that passes makes the run pass, so a wrong
// reading on the first attempt would be hidden. Each test walks again
// instead, itself, only a walk with nothing wrong read in it whose capture
// failed: a stop read as an empty phrase, or an unresolved read, a move that
// read nothing new mid-walk (runWalks, collectWalk, and judgeCollectedWalk
// in s10_vo_walks.js, S16's). Such a walk never passes, and at most three
// walks are made. Every walk must read the whole screen, the title and the
// description, the "Example" heading, and every expected stop after it, each
// in its place, and its end must be witnessed by a move back and a move
// forward again. A stop past the last expected one, a wrong stop before or
// across an unresolved read, a failed witness, a walk that ran out of moves,
// or one that reached the end with an expected stop not read, fails the test
// for good, and no later walk is made. Every try is logged with its start
// capture, the cursor's position at each stop, its unresolved reads, and its
// end witness, so every attempt is in the transcript. A row with `-after`
// (`<slug>-after-walk-<n>`) was walked once a review had been added with a
// mouse click, and only once the witness node shows that the click took
// effect.
//
// VoiceOver's help message ("You are currently on ...") is left out only at
// the position of a stop already judged whose spoken role is the one it
// names (helpAfterStop); it stays in the logged row, and the web tree spec's
// judgeTranscript leaves it out by the same rule, from the positions row.
// That rule is still tested only on made-up walks: no S10 recording has had
// a help message. In S16's recording (docs/evidence/S16/voiceover-web.md)
// the start capture on Back read an empty phrase in all 14 walks, and it did
// in S17's recordings too (made on S17's own branch); why was not looked
// into. With an empty start, the first move is compared with "", and any
// phrase it reads is a stop.
//
// The expected lists (EXPECTED_STOPS and EXPECTED_AFTER_ADDING in
// s10_vo_walks.js) were written before any S10 recording; the recording of
// 2026-11-27 (docs/evidence/probes/s10/voiceover-web-before-judge-update.md.txt)
// read every one exactly, in Chromium and WebKit (one WebKit walk walked
// again after an empty title, a failed capture). It was made before the walk
// took S16's rules, and logged only what follows the "Example" heading of a
// complete walk, so it does not pass judgeTranscript now.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { VO_HELP, cursorBounds, lastPhrase, phraseForMove, walkToEnd } from './vo_helpers.js';
import {
  EXPECTED_AFTER_ADDING, EXPECTED_STOPS, collectWalk, judgeCollectedWalk, positionsText,
  runWalks, screenStops, startText, stopsText, unresolvedText, witnessText,
} from './s10_vo_walks.js';

test.describe.configure({ retries: 0 });

const WORDS = 'Rating: 3.4 out of 5 stars, based on 856 reviews';
const WORDS_AFTER = 'Rating: 3.4 out of 5 stars, based on 857 reviews';

/**
 * One walk of the screen: walkToEnd with no moves starts it exactly as the
 * shared walk does (from Back, once VoiceOver is quiet), and collectWalk
 * (s10_vo_walks.js) captures the phrase and position on Back first, makes
 * the moves, keeps each stop's cursor position and every unchanged read,
 * and accepts the end only with its witness, a move back and a move forward
 * again. A help message VoiceOver gives for a move is replaced by the phrase
 * Guidepup logged for it (phraseForMove), as the form techniques' walks do;
 * one that comes anyway is left out by the judge only when it is about the
 * stop before it, at the same position.
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

/** Walks `slug`'s screen, up to three times, logging each walk as `row`. */
async function walkScreen(page, voiceOver, browserName, slug, expected, row) {
  let latest;
  const { verdict, reason, walks } = await runWalks(
    async () => {
      latest = await walkOnce(page, voiceOver, browserName, 40);
      return latest;
    },
    // A failed end witness is wrong for good, and an unresolved read makes
    // the walk incomplete (judgeCollectedWalk).
    () => judgeCollectedWalk(latest, expected, screenStops(slug)),
    {
      log: (walk, stops, judged) => {
        // Every try is logged whole, the screen's own stops and any help
        // message included, so that the committed transcript keeps each
        // walk's browser, row, try, and every stop it read, as stopsText
        // writes them: an empty phrase "(empty)", a walk with no stops
        // "(nothing)", and "/" in a stop "\/" (bad-merged's "3.4 / 5").
        // Every walk logs its start capture (`<row>-walk-<n>-start`), the
        // cursor's position at each stop (`-positions`), and its unresolved
        // reads (`-unresolved`, "none" or each); a walk that read its end
        // witness logs it (`-end`). judgeTranscript in s10_vo_walks.js reads
        // them back, and web_tests/s10_content_group_replacement.spec.js
        // judges the committed transcript again from these rows alone.
        const shown = stopsText(stops);
        console.log(`S10VO ${browserName} ${row}-walk-${walk} | ${shown} (${judged.verdict}: ${judged.reason})`);
        console.log(`S10VO ${browserName} ${row}-walk-${walk}-start | ${startText(latest.start)}`);
        console.log(`S10VO ${browserName} ${row}-walk-${walk}-positions | ${positionsText(latest.positions)}`);
        if (latest.witness) console.log(`S10VO ${browserName} ${row}-walk-${walk}-end | ${witnessText(latest.witness)}`);
        console.log(`S10VO ${browserName} ${row}-walk-${walk}-unresolved | ${unresolvedText(latest.unresolved)}`);
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
