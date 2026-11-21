// L4 on web for C04 Links inline with text: what VoiceOver on macOS speaks
// for each example. Needs Guidepup's setup and macOS automation permissions
// on the machine. Run through `python3 tool/voiceover_web.py C04`, which also
// writes the transcript.
//
// No test in this file is retried by the runner. The shared config retries
// a failed test twice, and a retry that passes makes the run pass, so a wrong
// reading on the first attempt would be hidden. Each test retries instead,
// itself, only a walk cut short before the end of the screen with every stop
// right so far (runWalks and judgeExampleWalk in c04_vo_walks.js). Every
// walk must read the whole screen, the title and the description, the
// "Example" heading, and every expected stop after it, each in its place:
// a wrong stop, or a walk that reached the end with any expected stop not
// read, fails the test for good, and every try is logged, so every attempt
// is in the transcript.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { walkToEnd } from './vo_helpers.js';
import { EXAMPLE_HEADING, judgeExampleWalk, runWalks, screenStops } from './c04_vo_walks.js';

test.describe.configure({ retries: 0 });

const FIRST = 'link links in text';
const SECOND = 'link stand-alone links';
const IN_ORDER = ['Read about', FIRST, 'and', SECOND, 'first.'];

// slug -> everything VoiceOver speaks after the "Example" heading, to the
// end of the screen, in order, one entry for each element its cursor stops
// on. Because every stop is listed, the lists also show what is not spoken.
const EXAMPLES = {
  // The sentence is read in its order, each link in its place, with its
  // role and name.
  'good-material': IN_ORDER,
  'good-cupertino': IN_ORDER,
  'good-custom': IN_ORDER,
  // Bad examples: the defect must be audible where the web shows it. An <a>
  // with no href is read as a link (FL-032, as in C03's bad-no-address); the
  // defect is the keyboard (see the tree spec).
  'bad-text-span': ['Read about', FIRST, 'first.'],
  // The sentence without its links, as a group, then the links inside it
  // (FL-413, as in V13's first build).
  'bad-out-of-order': [
    'Read about and first. group',
    FIRST,
    SECOND,
    'end of Read about and first. group',
  ],
  // The defect is in what is drawn, not in what is heard.
  'bad-colour-only': IN_ORDER,
  // One link, the whole sentence.
  'bad-merged': ['link Read about links in text and stand-alone links first.'],
};

for (const [slug, expected] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/C04/${slug}`, { waitUntil: 'load' });
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
          console.log(`C04VO ${browserName} ${slug}-walk-${walk} | ${shown} (${judged.verdict}: ${judged.reason})`);
        },
      });
    expect(verdict, `${slug}, walk ${walks}: ${reason}`).toBe('complete');
  });
}
