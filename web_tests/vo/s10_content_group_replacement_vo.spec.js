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
// expected stop after it, each in its place: a wrong stop, or a walk that
// reached the end with any expected stop not read, fails the test for good,
// and every try is logged, so every attempt is in the transcript.
//
// The expected lists were written before any S10 recording, from the
// semantics tree the web probe and the tree spec measured
// (docs/evidence/probes/s10/web.txt) and from what VoiceOver read for the
// same kinds of element in other techniques' transcripts: a text element as
// its text, a button with "button", and a progress bar as its name, then its
// value as a percentage, then "progress indicator"
// (docs/evidence/C26/voiceover-web.md). They are predictions until the
// first recording.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { walkToEnd } from './vo_helpers.js';
import { EXAMPLE_HEADING, judgeExampleWalk, runWalks, screenStops } from './s10_vo_walks.js';

test.describe.configure({ retries: 0 });

const WORDS = 'Rating: 3.4 out of 5 stars, based on 856 reviews';
const WORDS_AFTER = 'Rating: 3.4 out of 5 stars, based on 857 reviews';
const ADD = 'Add a 5-star review button';
// The bar row's texts, as one name (Chromium joins the lines with spaces).
const PIECES = 'Rating: 3.4 / 5 Reviews: 856';

// slug -> everything VoiceOver speaks after the "Example" heading, to the
// end of the screen, in order, one entry for each element its cursor stops
// on. Because every stop is listed, the lists also show what is not spoken.
const EXAMPLES = {
  // One text that says what the rating means; nothing of its pieces.
  'good-exclude-semantics': [WORDS, ADD],
  'good-hidden-pieces': [WORDS],
  'good-stars': [WORDS],
  // Bad examples: the defect must be audible where the web shows it.
  // The two numbers, and nothing for the stars.
  'bad-pieces': ['3.4', '(856)'],
  // One progress bar named by the pieces, its value in its name (FL-037)
  // and again as a percentage (FL-027), as C26's bars were read.
  'bad-merged': [`${PIECES} 68 68% progress indicator`],
  // The label, then the pieces again, as one progress bar.
  'bad-not-excluded': [`${WORDS} ${PIECES} 68 68% progress indicator`],
  // The rating, and the count; no Reviews button.
  'bad-hides-control': [WORDS, 'Reviews opened: 0'],
  'bad-stale': [WORDS, ADD],
};

// The same screens after a 5-star review is added with a mouse click on
// the button, before VoiceOver starts: the good replacement follows the
// row, the stale one does not.
const AFTER_ADDING = {
  'good-exclude-semantics': [WORDS_AFTER, ADD],
  'bad-stale': [WORDS, ADD],
};

async function walkScreen(page, voiceOver, browserName, slug, expected, row) {
  const { verdict, reason, walks } = await runWalks(
    // A help message VoiceOver gives for a move is replaced by the phrase
    // Guidepup logged for it (vo_helpers.js, phraseForMove); one that comes
    // anyway is left out by the judge.
    () => walkToEnd(page, voiceOver, browserName, 40, { loggedForHelp: true }),
    (stops, reachedEnd) => judgeExampleWalk(stops, reachedEnd, expected, screenStops(slug)),
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

for (const [slug, expected] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await openScreen(page, slug);
    await walkScreen(page, voiceOver, browserName, slug, expected, slug);
  });
}

for (const [slug, expected] of Object.entries(AFTER_ADDING)) {
  test(`voiceover reads ${slug} after a review is added`, async ({ page, voiceOver, browserName }) => {
    await openScreen(page, slug);
    const add = page.locator(`[flt-semantics-identifier="s10-${slug}-add"]`);
    await add.click();
    await expect(page.getByText(slug === 'bad-stale' ? WORDS : WORDS_AFTER, { exact: true })).toHaveCount(1);
    // The pointer is moved off the button, so that nothing is hovered.
    await page.mouse.move(0, 0);
    await page.waitForTimeout(600);
    await walkScreen(page, voiceOver, browserName, slug, expected, `${slug}-after`);
  });
}
