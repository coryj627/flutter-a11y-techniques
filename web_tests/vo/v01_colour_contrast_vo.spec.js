// L4 on web for V01 Colour contrast: what VoiceOver on macOS speaks for
// each example. Needs Guidepup's setup and macOS automation permissions on
// the machine. Run through `python3 tool/voiceover_web.py V01`, which also
// writes the transcript.
//
// No test in this file is retried by the runner. The shared config retries
// a failed test twice, and a retry that passes makes the run pass, so a wrong
// reading on the first attempt would be hidden. Each test walks again
// instead, itself, only a walk with nothing wrong read in it whose capture
// failed: a stop read as an empty phrase, or an unresolved read, a move that
// read nothing new mid-walk (runWalks, collectWalk, and judgeCollectedWalk
// in v01_vo_walks.js, S16's with the S08 to S12 judge update). Such a walk
// never passes, and at most three walks are made. Every walk must read the
// whole screen, the title and the description (and a bad example's
// defect), the "Example" heading, and every expected stop after it, each in
// its place, and its end must be witnessed by a move back and a move
// forward again. A stop past the last expected one, a wrong stop before or
// across an unresolved read, a failed witness, a walk that ran out of moves,
// or one that reached the end with an expected stop not read, fails the test
// for good, and no later walk is made. Every try is logged with its start
// capture, the cursor's position at each stop, its unresolved reads, and its
// end witness, so every attempt is in the transcript.
//
// VoiceOver's help message, in either wording ("You are currently on ..."
// or "You are currently in ...", VO_HELP in v01_vo_walks.js), is left out
// only at the position of a stop already judged whose spoken role is the
// one it names (helpAfterStop); it stays in the logged row, and the web tree
// spec's judgeTranscript leaves it out by the same rule, from the positions
// row. That rule is tested only on made-up walks: no V01 walk has been
// recorded.
//
// Every phrase is recorded with its white space made single spaces
// (spokenText): the Cupertino fields' names hold a line break, and a line
// break would cut a logged row in two (tool/voiceover_web.py reads each to
// the end of its line).
//
// VoiceOver's last phrase is text, and a colour is drawn, not spoken: no
// V01 defect is in what is judged, which is the words and the stops. The
// expected lists are predictions (v01_vo_walks.js says from what); no V01
// walk has been recorded. The browser's colour scheme here is Playwright's
// default, light, whatever the Mac's is.
// Each test opens its example in a page of its own, from a fresh load, so
// that nothing one example does reaches another.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { cursorBounds, lastPhrase, walkToEnd } from './vo_helpers.js';
import {
  EXPECTED_STOPS, VO_HELP, collectWalk, judgeCollectedWalk, runWalks, screenStops, spokenText, walkLogLines,
} from './v01_vo_walks.js';

test.describe.configure({ retries: 0 });

/**
 * One walk of the screen: walkToEnd with no moves starts it exactly as the
 * shared walk does (from Back, once VoiceOver is quiet), and collectWalk
 * (v01_vo_walks.js) captures the phrase and position on Back first, makes
 * the moves, keeps each stop's cursor position and every unchanged read,
 * and accepts the end only with its witness, a move back and a move forward
 * again. A help message VoiceOver gives for a move, in either wording, is
 * replaced by the phrase Guidepup logged for it, the rule of phraseForMove
 * in vo_logic.js (which on main knows only the first wording); one that
 * comes anyway is left out by the judge only when it is about the stop
 * before it, at the same position.
 */
async function walkOnce(page, voiceOver, browserName, max = 40) {
  await walkToEnd(page, voiceOver, browserName, 0);
  const capture = async () => {
    let phrase = spokenText(await lastPhrase());
    if (VO_HELP.test(phrase)) phrase = spokenText(await voiceOver.lastSpokenPhrase());
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

for (const [slug, expected] of Object.entries(EXPECTED_STOPS)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/V01/${slug}`, { waitUntil: 'load' });
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
          // Every try is logged whole (walkLogLines), the screen's own stops
          // and any help message included, so that the committed transcript
          // keeps each walk's browser, example, try, and every stop it
          // read, as stopsText writes them: an empty phrase "(empty)", a
          // walk with no stops "(nothing)", and "/" in a stop "\/". Every
          // walk logs its start capture (`<slug>-walk-<n>-start`), the
          // cursor's position at each stop (`-positions`), and its
          // unresolved reads (`-unresolved`, "none" or each); a walk that
          // read its end witness logs it (`-end`). judgeTranscript in
          // v01_vo_walks.js reads them back, and
          // web_tests/v01_colour_contrast.spec.js judges the committed
          // transcript again from these rows alone, and the lines' way
          // through tool/voiceover_web.py on made-up walks.
          for (const line of walkLogLines(browserName, slug, walk, judged, latest)) console.log(line);
        },
      });
    expect(verdict, `${slug}, walk ${walks}: ${reason}`).toBe('complete');
  });
}
