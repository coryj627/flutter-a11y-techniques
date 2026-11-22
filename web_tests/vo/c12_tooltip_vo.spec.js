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
// The lists below were written before any C12 recording, from the tree
// tests and from C01's transcript (docs/evidence/C01/voiceover-web.md):
// there VoiceOver in Chromium read an IconButton's tooltip a second time,
// as a stop of its own followed by an empty one, and in WebKit once
// (FL-008). While a Flutter tooltip is shown its text is an element of the
// page (FL-249, the tree spec), which would explain it if VoiceOver's
// cursor shows the tooltip. Every example here is Flutter's own Tooltip, so
// each is expected to do the same in Chromium. That is a prediction; the
// first recording settles it.
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
// its cursor stops on.
const shownAgain = (stop, text, rest) => ({
  chromium: [stop, text, '', ...rest],
  webkit: [stop, ...rest],
});
const EXAMPLES = {
  // The name, then (Chromium) the shown tooltip's text and an empty stop.
  'good-material': shownAgain('Delete draft button', 'Delete draft', [DRAFTS, COUNT]),
  'good-cupertino': shownAgain('Delete draft button', 'Delete draft', [DRAFTS, COUNT]),
  // The tooltip joins the name, before the button's text (FL-251).
  'good-description': shownAgain('Saves a PDF copy Download button', 'Saves a PDF copy', [FILE, COUNT]),
  // The defect is the pointer's, not the screen reader's.
  'bad-not-hoverable': shownAgain('Delete draft button', 'Delete draft', [DRAFTS, COUNT]),
  // The rule is read, as the icon's text; the defect is the keyboard's.
  'bad-hover-only': {
    chromium: ['Password rules', 'At least 8 characters', 'Sign up button', 'You can change it later.', COUNT],
    webkit: ['Password rules', 'At least 8 characters', 'Sign up button', 'You can change it later.', COUNT],
  },
  // The name twice.
  'bad-repeats-name': shownAgain('Download Download button', 'Download', [FILE, COUNT]),
  // The tooltip's words on an element of their own, then a button with no
  // name.
  'bad-outside-button': {
    chromium: ['Delete draft', 'button', 'Delete draft', '', DRAFTS, COUNT],
    webkit: ['Delete draft', 'button', DRAFTS, COUNT],
  },
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
