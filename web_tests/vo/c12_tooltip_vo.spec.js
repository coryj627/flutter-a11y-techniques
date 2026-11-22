// L4 on web for C12 Tooltip: what VoiceOver on macOS speaks for each
// example. Needs Guidepup's setup and macOS automation permissions on the
// machine. Run through `python3 tool/voiceover_web.py C12`, which also
// writes the transcript.
//
// No test in this file is retried by the runner. Each test retries instead,
// itself, only a walk cut short before the end of the screen with every stop
// right so far (runWalks and judgeExampleWalk in c12_vo_walks.js). Every
// walk must read the whole screen, the title and the description, the
// "Example" heading, and every expected stop after it to the count, each in
// its place: a wrong stop, or a walk that reached the end with any expected
// stop not read, fails the test for good, and every try is logged.
//
// The lists are what the first recording read, in both browsers
// (docs/evidence/probes/c12/voiceover-web-round1-fail.md.txt). It had been
// written from predictions, which expected Chromium to read a shown
// tooltip's text as an extra stop, as C01's transcript had for an
// IconButton (FL-008); no walk showed a tooltip, and nothing was read
// twice in either browser, so seven walks failed on their expectations.
// With these lists the second recording passed, every walk complete on
// its first try (docs/evidence/C12/voiceover-web.md).
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { walkToEnd } from './vo_helpers.js';
import { EXAMPLE_HEADING, judgeExampleWalk, runWalks, screenStops } from './c12_vo_walks.js';

test.describe.configure({ retries: 0 });

const COUNT = 'Activations: 0';
const DRAFTS = 'Drafts are kept for 30 days.';
const FILE = 'The file is 2 MB.';

// slug -> browser -> everything VoiceOver speaks after the "Example"
// heading, to the end of the screen, in order, one entry for each element
// its cursor stops on. Chromium and WebKit read the same.
const both = (list) => ({ chromium: list, webkit: list });
const EXAMPLES = {
  // The tooltip's words once, as the name.
  'good-material': both(['Delete draft button', DRAFTS, COUNT]),
  'good-cupertino': both(['Delete draft button', DRAFTS, COUNT]),
  // The tooltip joins the name, before the button's text (FL-251).
  'good-description': both(['Saves a PDF copy Download button', FILE, COUNT]),
  // The defect is the pointer's, not the screen reader's.
  'bad-not-hoverable': both(['Delete draft button', DRAFTS, COUNT]),
  // The rule is read, as the icon's text; the defect is the keyboard's.
  'bad-hover-only': both(['Password rules', 'At least 8 characters', 'Sign up button', 'You can change it later.', COUNT]),
  // The name twice.
  'bad-repeats-name': both(['Download Download button', FILE, COUNT]),
  // A group named by the tooltip, holding a button with no name; then
  // "Delete draft" once more inside the group (what that stop is was not
  // measured; the page snapshot when the walk ended had no element with
  // those words but the group).
  'bad-outside-button': both(['Delete draft group', 'button', 'Delete draft', 'end of Delete draft group', DRAFTS, COUNT]),
};

for (const [slug, byBrowser] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    const expected = byBrowser[browserName];
    expect(expected, `no list for ${browserName}`).toBeDefined();
    await page.goto(`/#/t/C12/${slug}`, { waitUntil: 'load' });
    await expect(page.getByRole('heading', { name: 'Example', exact: true, level: 2 })).toBeVisible();
    await page.waitForTimeout(600);
    const { verdict, reason, walks } = await runWalks(
      () => walkToEnd(page, voiceOver, browserName, 40),
      (stops, reachedEnd) => judgeExampleWalk(stops, reachedEnd, expected, screenStops(slug)),
      {
        log: (walk, stops, judged) => {
          const start = stops.indexOf(EXAMPLE_HEADING);
          const shown = (judged.verdict === 'complete' ? stops.slice(start + 1) : stops).join(' / ') || '(nothing)';
          console.log(`C12VO ${browserName} ${slug}-walk-${walk} | ${shown} (${judged.verdict}: ${judged.reason})`);
        },
      });
    expect(verdict, `${slug}, walk ${walks}: ${reason}`).toBe('complete');
  });
}
