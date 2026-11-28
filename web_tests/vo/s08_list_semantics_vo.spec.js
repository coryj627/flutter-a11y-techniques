// L4 on web for S08 List semantics: what VoiceOver on macOS speaks for each
// example. Needs Guidepup's setup and macOS automation permissions on the
// machine. Run through `python3 tool/voiceover_web.py S08`, which also
// writes the transcript.
//
// No test in this file is retried by the runner. The shared config retries
// a failed test twice, and a retry that passes makes the run pass, so a wrong
// reading on the first attempt would be hidden. Each test walks again
// instead, itself, only a walk with nothing wrong read in it whose capture
// failed: a stop read as an empty phrase, or an unresolved read, a move that
// read nothing new mid-walk (runWalks, collectWalk, and judgeCollectedWalk
// in s08_vo_walks.js, S16's). Such a walk never passes, and at most three
// walks are made. Every walk must read the whole screen, the title and the
// description, the "Example" heading, and every expected stop after it, each
// in its place, and its end must be witnessed by a move back and a move
// forward again. A stop past the last expected one, a wrong stop before or
// across an unresolved read, a failed witness, a walk that ran out of moves,
// or one that reached the end with an expected stop not read, fails the test
// for good, and no later walk is made. Every try is logged with its start
// capture, the cursor's position at each stop, its unresolved reads, and its
// end witness, so every attempt is in the transcript.
//
// VoiceOver's help message ("You are currently on ...") is left out only at
// the position of a stop already judged whose spoken role is the one it
// names (helpAfterStop); it stays in the logged row, and the web tree spec's
// judgeTranscript leaves it out by the same rule, from the positions row.
// That rule is still tested only on made-up walks: no S08 recording has had
// a help message. In S16's recording (docs/evidence/S16/voiceover-web.md)
// the start capture on Back read an empty phrase in all 14 walks, and it did
// in S17's recordings too (made on S17's own branch); why was not looked
// into. With an empty start, the first move is compared with "", and any
// phrase it reads is a stop.
//
// The expected lists are what VoiceOver said in the first recording
// (2026-11-26, docs/evidence/probes/s08/voiceover-web-round1-fail.md.txt),
// which was judged against predictions written before any recording and
// failed: every list item was read with its place, and a list item whose
// text is merged into it as "empty group" (FL-315). The same was heard in
// Chromium and WebKit for every example but `good-material`, which has
// WebKit's reading only: Chromium quit during that walk, and VoiceOver read
// its crash dialog. Every later recording read good-material in Chromium as
// WebKit had; the fifth passed whole, and so did the sixth
// (docs/evidence/probes/s08/voiceover-web-before-judge-update.md.txt). Both
// were made before the walk took S16's rules, and logged only what follows
// the "Example" heading of a complete walk, so neither passes
// judgeTranscript now.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { VO_HELP, cursorBounds, lastPhrase, phraseForMove, walkToEnd } from './vo_helpers.js';
import {
  EXPECTED_STOPS, collectWalk, judgeCollectedWalk, positionsText, runWalks, screenStops,
  startText, stopsText, unresolvedText, witnessText,
} from './s08_vo_walks.js';

test.describe.configure({ retries: 0 });

/**
 * One walk of the screen: walkToEnd with no moves starts it exactly as the
 * shared walk does (from Back, once VoiceOver is quiet), and collectWalk
 * (s08_vo_walks.js) captures the phrase and position on Back first, makes
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

for (const [slug, expected] of Object.entries(EXPECTED_STOPS)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/S08/${slug}`, { waitUntil: 'load' });
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
          // Every try is logged whole, the screen's own stops and any help
          // message included, so that the committed transcript keeps each
          // walk's browser, example, try, and every stop it read, as
          // stopsText writes them: an empty phrase "(empty)", a walk with
          // no stops "(nothing)", and "/" in a stop "\/". Every walk logs
          // its start capture (`<slug>-walk-<n>-start`), the cursor's
          // position at each stop
          // (`-positions`), and its unresolved reads (`-unresolved`, "none"
          // or each); a walk that read its end witness logs it (`-end`).
          // judgeTranscript in s08_vo_walks.js reads them back, and
          // web_tests/s08_hiding_content.spec.js judges the committed
          // transcript again from these rows alone.
          const shown = stopsText(stops);
          console.log(`S08VO ${browserName} ${slug}-walk-${walk} | ${shown} (${judged.verdict}: ${judged.reason})`);
          console.log(`S08VO ${browserName} ${slug}-walk-${walk}-start | ${startText(latest.start)}`);
          console.log(`S08VO ${browserName} ${slug}-walk-${walk}-positions | ${positionsText(latest.positions)}`);
          if (latest.witness) console.log(`S08VO ${browserName} ${slug}-walk-${walk}-end | ${witnessText(latest.witness)}`);
          console.log(`S08VO ${browserName} ${slug}-walk-${walk}-unresolved | ${unresolvedText(latest.unresolved)}`);
        },
      });
    expect(verdict, `${slug}, walk ${walks}: ${reason}`).toBe('complete');
  });
}
