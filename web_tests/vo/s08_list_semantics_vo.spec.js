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
// The expected lists are what VoiceOver said in the first recording
// (2026-11-26, docs/evidence/probes/s08/voiceover-web-round1-fail.md.txt),
// which was judged against predictions written before any recording and
// failed: every list item was read with its place, and a list item whose
// text is merged into it as "empty group" (FL-315). The same was heard in
// Chromium and WebKit for every example but `good-material`, which has
// WebKit's reading only: Chromium quit during that walk, and VoiceOver read
// its crash dialog. So `good-material`'s list is measured for WebKit and a
// prediction for Chromium.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { walkToEnd } from './vo_helpers.js';
import { EXAMPLE_HEADING, judgeExampleWalk, runWalks, screenStops } from './s08_vo_walks.js';

test.describe.configure({ retries: 0 });

const GROCERIES = ['Milk', 'Eggs', 'Bread'];
const STEPS = ['1. Fork the repository', '2. Make the change', '3. Open a pull request'];

/** A list item as VoiceOver read it: "Milk empty group (1 of 3) 1 of 3". */
const item = (text, i, kind) => `${text} ${kind} (${i + 1} of 3) ${i + 1} of 3`;

// slug -> everything VoiceOver speaks after the "Example" heading, to the
// end of the screen, in order, one entry for each element its cursor stops
// on. Because every stop is listed, the lists also show what is not spoken.
const EXAMPLES = {
  // The list with its number of items; each item with "empty group" and
  // its place, twice; then the end of the list (FL-315).
  'good-bulleted': ['list 3 items', ...GROCERIES.map((g, i) => item(g, i, 'empty group')), 'end of list'],
  'good-numbered': ['list 3 items', ...STEPS.map((s, i) => item(s, i, 'empty group')), 'end of list'],
  // Each tile a button with its place; the list items are not stops
  // (WebKit; Chromium not recorded yet).
  'good-material': ['list 3 items', ...GROCERIES.map((g, i) => `${g} button ${i + 1} of 3`), 'end of list', 'Chosen: none'],
  // The list named by its header.
  'good-cupertino': ['list Groceries 3 items', ...GROCERIES.map((g, i) => item(g, i, 'empty group')), 'end of list'],
  // Bad examples: the defect must be audible where the web shows it.
  // One text, no list.
  'bad-one-text': [GROCERIES.join(' ')],
  // Three texts, no list.
  'bad-no-list': GROCERIES,
  // Each tile a list item, read as a group and not as a button (FL-262).
  'bad-tile-in-item': ['list 3 items', ...GROCERIES.map((g, i) => item(g, i, 'group')), 'end of list', 'Chosen: none'],
  // No list; the orders the page holds when it opens (FL-011).
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
