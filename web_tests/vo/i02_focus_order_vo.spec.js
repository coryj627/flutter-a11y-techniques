// L4 on web for I02 Keyboard focus order: what VoiceOver on macOS speaks
// for each example, moving with its own cursor. Needs Guidepup's setup and
// macOS automation permissions on the machine. Run through
// `python3 tool/voiceover_web.py I02`, which also writes the transcript.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { walkToEnd } from './vo_helpers.js';

const EXAMPLE = 'heading level 2 Example';
// The save count is the last element of every example.
const COUNT = 'Saves: 0';
const box = (name) => `${name} unchecked checkbox`;
const SAVE = 'Save plan button';

// Each column is a semantics container named by its title, which the web
// makes a group.
const COLUMNS = [
  'Pack group', box('Map'), box('Water'), box('First aid'), 'end of Pack group',
  'Send me group', box('Weather'), box('Closures'), 'end of Send me group',
  SAVE,
];
// The numbered examples have no column widget: each title is text of its
// own, placed by its sort key.
const NUMBERED = [
  'Pack', box('Map'), box('Water'), box('First aid'),
  'Send me', box('Weather'), box('Closures'),
  SAVE,
];

// slug -> everything VoiceOver speaks after the "Example" heading and before
// the count, in order, one entry for each element its cursor stops on.
// VoiceOver's cursor follows the order of the elements in the document,
// which is one column, then the other, in every example. The keyboard's
// order is not heard: the two bad examples read like the good ones.
const EXAMPLES = {
  'good-material': COLUMNS,
  'good-cupertino': COLUMNS,
  'good-ordered': NUMBERED,
  'bad-columns-mixed': COLUMNS,
  'bad-order-missing': NUMBERED,
};

for (const [slug, expected] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/I02/${slug}`, { waitUntil: 'load' });
    await expect(page.locator(`[flt-semantics-identifier="i02-${slug}-count"]`)).toBeVisible();
    const { stops, reachedEnd } = await walkToEnd(page, voiceOver, browserName, 40);
    console.log(`I02VO ${browserName} ${slug} | ${stops.join(' / ')}`);
    expect(reachedEnd, `${slug}: the walk reached the end of the screen`).toBe(true);
    const start = stops.indexOf(EXAMPLE);
    expect(start, `${slug}: reached the example`).toBeGreaterThanOrEqual(0);
    expect(stops.slice(start + 1), slug).toEqual([...expected, COUNT]);
  });
}
