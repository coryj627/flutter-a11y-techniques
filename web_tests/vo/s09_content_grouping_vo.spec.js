// L4 on web for S09 Content grouping: what VoiceOver on macOS speaks for
// each example.
// Needs Guidepup's setup and macOS automation permissions on the machine.
// Run through `python3 tool/voiceover_web.py S09`, which also writes the
// transcript.
//
// No test in this file is retried by the runner. The shared config retries
// a failed test twice, and a retry that passes makes the run pass, so a wrong
// reading on the first attempt would be hidden. Each test retries instead,
// itself, only a walk cut short before the end of the screen with every stop
// right so far, or a walk whose capture failed (a stop read as an empty
// phrase) with nothing wrong read in it (runWalks and judgeExampleWalk in
// s09_vo_walks.js, S08's judge). Every
// walk must read the whole screen, the title and the description, the
// "Example" heading, and every expected stop after it, each in its place:
// a wrong stop, or a walk that reached the end with any expected stop not
// read, fails the test for good, and every try is logged, so every attempt
// is in the transcript. VoiceOver's own help message ("You are currently on
// …") is not a stop of the page: the walk puts the phrase Guidepup logged
// for a move in place of one, and the judge leaves out any that comes
// anyway.
//
// The first recording (2026-11-26,
// docs/evidence/probes/s09/voiceover-web-round1-fail.md.txt) read every
// walk as listed here but one: WebKit's bad-merged-group, whose first stop,
// the screen's title, was an empty phrase, every later stop right. The judge
// now walks such a capture again.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { walkToEnd } from './vo_helpers.js';
import { EXAMPLE_HEADING, judgeExampleWalk, runWalks, screenStops } from './s09_vo_walks.js';

test.describe.configure({ retries: 0 });

const GROUP = 'Kitchen light';

// slug -> everything VoiceOver speaks after the "Example" heading, to the
// end of the screen, in order, one entry for each element its cursor stops
// on, the status lines under the controls included. Because every stop is
// listed, the lists also show what is not spoken. Written before any S09
// web VoiceOver recording, from how the merged and the grouped elements
// were read in C18's and F07's recordings (docs/evidence/C18/voiceover-web.md,
// docs/evidence/F07/voiceover-web.md): a line break in a name is read as a
// space, and a group is announced on the way in and on the way out. The
// first S09 recording read every one of them so, in Chromium and WebKit.
const EXAMPLES = {
  // Each label read with its value, as one stop.
  'good-merged-facts': ['City Boston', 'Founded 1630'],
  'good-cupertino': ['City Boston', 'Founded 1630'],
  // A group named by the question, with the buttons inside it.
  'good-named-group': [`${GROUP} group`, 'On button', 'Off button', `end of ${GROUP} group`, 'Light: not set'],
  // One button, named by its text.
  'good-tap-target': ['App information button', 'Opens: 0'],
  // Bad examples: the defect must be audible where the web shows it. Both
  // labels, then both values.
  'bad-split-facts': ['City', 'Founded', 'Boston', '1630'],
  // One button, the question and both buttons' words.
  'bad-merged-group': [`${GROUP} On Off button`, 'Light: not set'],
};

for (const [slug, expected] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/S09/${slug}`, { waitUntil: 'load' });
    await expect(page.getByRole('heading', { name: 'Example', exact: true, level: 2 })).toBeVisible();
    await page.waitForTimeout(600);
    const { verdict, reason, walks } = await runWalks(
      // A help message VoiceOver gives for a move is replaced by the phrase
      // Guidepup logged for it (vo_helpers.js, phraseForMove), as S08's and
      // the form techniques' walks do; one that comes anyway is left out by
      // the judge.
      () => walkToEnd(page, voiceOver, browserName, 40, { loggedForHelp: true }),
      (stops, reachedEnd) => judgeExampleWalk(stops, reachedEnd, expected, screenStops(slug)),
      {
        log: (walk, stops, judged) => {
          // A complete walk read the screen's own stops exactly as listed,
          // so only what follows the heading is shown; any other try is
          // shown whole.
          const start = stops.indexOf(EXAMPLE_HEADING);
          const shown = (judged.verdict === 'complete' ? stops.slice(start + 1) : stops).join(' / ') || '(nothing)';
          console.log(`S09VO ${browserName} ${slug}-walk-${walk} | ${shown} (${judged.verdict}: ${judged.reason})`);
        },
      });
    expect(verdict, `${slug}, walk ${walks}: ${reason}`).toBe('complete');
  });
}
