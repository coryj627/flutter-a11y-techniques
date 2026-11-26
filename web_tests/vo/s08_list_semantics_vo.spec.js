// L4 on web for S08 List semantics: what VoiceOver on macOS speaks for each
// example. Needs Guidepup's setup and macOS automation permissions on the
// machine. Run through `python3 tool/voiceover_web.py S08`, which also
// writes the transcript.
//
// No test in this file is retried by the runner. The shared config retries
// a failed test twice, and a retry that passes makes the run pass, so a wrong
// reading on the first attempt would be hidden. Each test retries instead,
// itself, only a walk cut short before the end of the screen with every stop
// right so far (runWalks and judgeExampleWalk in s08_vo_walks.js). Every
// walk must read the whole screen, the title and the description, the
// "Example" heading, and every expected stop after it, each in its place:
// a wrong stop, or a walk that reached the end with any expected stop not
// read, fails the test for good, and every try is logged, so every attempt
// is in the transcript.
//
// The expected lists below were written before any VoiceOver recording of
// these examples was made: no recording of a Flutter list on the web had
// been made in this project (docs/specs/S08-list-semantics.md, section 7).
// They are what VoiceOver is predicted to say from the elements the web
// tree test measures; the first recording decides them.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { walkToEnd } from './vo_helpers.js';
import { EXAMPLE_HEADING, judgeExampleWalk, runWalks, screenStops } from './s08_vo_walks.js';

test.describe.configure({ retries: 0 });

const GROCERIES = ['Milk', 'Eggs', 'Bread'];
const STEPS = ['1. Fork the repository', '2. Make the change', '3. Open a pull request'];

// slug -> everything VoiceOver speaks after the "Example" heading, to the
// end of the screen, in order, one entry for each element its cursor stops
// on. Because every stop is listed, the lists also show what is not spoken.
const EXAMPLES = {
  // The list, with its number of items, then each item.
  'good-bulleted': ['list 3 items', ...GROCERIES],
  'good-numbered': ['list 3 items', ...STEPS],
  'good-material': ['list 3 items', ...GROCERIES.map((g) => `${g} button`), 'Chosen: none'],
  'good-cupertino': ['Groceries list 3 items', ...GROCERIES],
  // Bad examples: the defect must be audible where the web shows it.
  // One text, no list.
  'bad-one-text': [GROCERIES.join(' ')],
  // Three texts, no list.
  'bad-no-list': GROCERIES,
  // Each tile a list item, and no button (FL-262).
  'bad-tile-in-item': ['list 3 items', ...GROCERIES, 'Chosen: none'],
  // No list; the orders the page holds when it opens (the web tree test
  // measured 1 to 13 of 30, FL-011).
  'bad-lazy-list': Array.from({ length: 13 }, (_, i) => `Order ${i + 1}`),
};

for (const [slug, expected] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/S08/${slug}`, { waitUntil: 'load' });
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
          console.log(`S08VO ${browserName} ${slug}-walk-${walk} | ${shown} (${judged.verdict}: ${judged.reason})`);
        },
      });
    expect(verdict, `${slug}, walk ${walks}: ${reason}`).toBe('complete');
  });
}
