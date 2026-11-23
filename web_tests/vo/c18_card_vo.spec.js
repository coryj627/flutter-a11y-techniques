// L4 on web for C18 Card: what VoiceOver on macOS speaks for each example.
// Needs Guidepup's setup and macOS automation permissions on the machine.
// Run through `python3 tool/voiceover_web.py C18`, which also writes the
// transcript.
//
// No test in this file is retried by the runner. The shared config retries
// a failed test twice, and a retry that passes makes the run pass, so a wrong
// reading on the first attempt would be hidden. Each test retries instead,
// itself, only a walk cut short before the end of the screen with every stop
// right so far (runWalks and judgeExampleWalk in c18_vo_walks.js). Every
// walk must read the whole screen, the title and the description, the
// "Example" heading, and every expected stop after it, each in its place:
// a wrong stop, or a walk that reached the end with any expected stop not
// read, fails the test for good, and every try is logged, so every attempt
// is in the transcript.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { walkToEnd } from './vo_helpers.js';
import { EXAMPLE_HEADING, judgeExampleWalk, runWalks, screenStops } from './c18_vo_walks.js';

test.describe.configure({ retries: 0 });

const TRAIL = 'Ridge trail';
const TEXT = 'A 6 km climb with a view.';
const PICTURE = 'Sunrise over the valley image';
const HEADING = `heading level 3 ${TRAIL}`;
const CARD = `${TRAIL} ${TEXT}`;

// slug -> everything VoiceOver speaks after the "Example" heading, to the
// end of the screen, in order, one entry for each element its cursor stops
// on, the counts under the card included. Because every stop is listed, the
// lists also show what is not spoken.
const EXAMPLES = {
  // Each part on its own: the heading, the text, the picture, each button.
  'good-material': [HEADING, TEXT, PICTURE, `Save ${TRAIL} button`, `Share ${TRAIL} button`, 'Saves: 0', 'Shares: 0'],
  // One button, named by the title and the text.
  'good-tappable': [`${CARD} button`, 'Opens: 0'],
  'good-cupertino': [HEADING, TEXT, PICTURE],
  // Bad examples: the defect must be audible where the web shows it. The
  // heading and the text are one heading, which holds the button. In round
  // 1 (docs/evidence/probes/c18/voiceover-web-round1-fail.md.txt) VoiceOver's
  // next went from the heading to the count in Chromium and WebKit alike,
  // and did not stop on the button inside the heading: these are the
  // measured stops.
  'bad-default-container': [`heading level 3 ${CARD}`, 'Saves: 0'],
  // A heading, and no button (FL-268).
  'bad-heading-button': [`heading level 3 ${CARD}`, 'Opens: 0'],
  // The web is not affected: a button, as any tappable node is (FL-006).
  'bad-ink-well': [`${CARD} button`, 'Opens: 0'],
  // The link says only "Read more".
  'bad-read-more': [HEADING, TEXT, 'link Read more'],
};

for (const [slug, expected] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/C18/${slug}`, { waitUntil: 'load' });
    await expect(page.getByRole('heading', { name: 'Example', exact: true, level: 2 })).toBeVisible();
    await page.waitForTimeout(600);
    const { verdict, reason, walks } = await runWalks(
      () => walkToEnd(page, voiceOver, browserName, 40),
      (stops, reachedEnd) => judgeExampleWalk(stops, reachedEnd, expected, screenStops(slug)),
      {
        log: (walk, stops, judged) => {
          // A complete walk read the screen's own stops exactly as listed,
          // so only what follows the heading is shown; any other try is
          // shown whole.
          const start = stops.indexOf(EXAMPLE_HEADING);
          const shown = (judged.verdict === 'complete' ? stops.slice(start + 1) : stops).join(' / ') || '(nothing)';
          console.log(`C18VO ${browserName} ${slug}-walk-${walk} | ${shown} (${judged.verdict}: ${judged.reason})`);
        },
      });
    expect(verdict, `${slug}, walk ${walks}: ${reason}`).toBe('complete');
  });
}
