// L4 on web for V14 Focus indicators: what VoiceOver on macOS speaks for
// each example. Needs Guidepup's setup and macOS automation permissions on
// the machine. Run through `python3 tool/voiceover_web.py V14`, which also
// writes the transcript.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { walkToEnd } from './vo_helpers.js';

const EXAMPLE = 'heading level 2 Example';
// The "Last used" line is the last element of every example.
const LAST = 'Last used: none';
const TRAILS = ['Ridge trail', 'Lake loop', 'Summit path', 'Forest walk', 'River run', 'Canyon climb']
  .map((t) => `${t} button`);
const NOTICE = 'Trail conditions are updated every morning.';

// slug -> everything VoiceOver speaks after the "Example" heading and before
// the "Last used" line, one entry for each element its cursor stops on. A
// focus indicator is drawn, not spoken: the bad examples are read as the
// good ones, and a trail under the notice is read like any other.
const EXAMPLES = {
  'good-material': ['Weather alerts unchecked checkbox', 'Save button'],
  'good-cupertino': ['Weather alerts off switch', 'Save button'],
  'good-widgets': ['Ridge trail button'],
  'good-notice-below': [...TRAILS, NOTICE],
  'bad-indicator-removed': ['Save button'],
  'bad-checkbox-halo': ['Weather alerts unchecked checkbox'],
  'bad-cupertino-ring': ['Save button'],
  'bad-notice-over-list': [...TRAILS, NOTICE],
};

for (const [slug, expected] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/V14/${slug}`, { waitUntil: 'load' });
    await expect(page.locator(`[flt-semantics-identifier="v14-${slug}-count"]`)).toBeVisible();
    const { stops, reachedEnd } = await walkToEnd(page, voiceOver, browserName, 40);
    console.log(`V14VO ${browserName} ${slug} | ${stops.join(' / ')}`);
    expect(reachedEnd, `${slug}: the walk reached the end of the screen`).toBe(true);
    const start = stops.indexOf(EXAMPLE);
    expect(start, `${slug}: reached the example`).toBeGreaterThanOrEqual(0);
    expect(stops.slice(start + 1), slug).toEqual([...expected, LAST]);
  });
}
