// L4 on web for I01 Focusable and clickable controls: what VoiceOver on
// macOS speaks for each example. Needs Guidepup's setup and macOS
// automation permissions on the machine. Run through
// `python3 tool/voiceover_web.py I01`, which also writes the transcript.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { walkToEnd } from './vo_helpers.js';

const EXAMPLE = 'heading level 2 Example';
// The activation count is the last element of every example.
const COUNT = 'Activations: 0';
const TRAIL = 'Ridge trail button';

// slug -> everything VoiceOver speaks after the "Example" heading and before
// the count, in order, one entry for each element its cursor stops on.
// Every card is read the same way. On the web any node with a tap action
// is a button (FL-006), so bad-inkwell-no-role has the role here that it
// lacks on Android and iOS; and the keyboard and pointer defects are not
// heard. The walk records that they sound like the good examples.
const EXAMPLES = {
  'good-material': [TRAIL],
  'good-cupertino': [TRAIL],
  'good-custom': [TRAIL],
  'bad-inkwell-no-role': [TRAIL],
  'bad-no-focus': [TRAIL],
  'bad-no-key-action': [TRAIL],
  'bad-tap-down': [TRAIL],
};

for (const [slug, expected] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/I01/${slug}`, { waitUntil: 'load' });
    await expect(page.locator(`[flt-semantics-identifier="i01-${slug}-count"]`)).toBeVisible();
    const { stops, reachedEnd } = await walkToEnd(page, voiceOver, browserName, 40);
    console.log(`I01VO ${browserName} ${slug} | ${stops.join(' / ')}`);
    expect(reachedEnd, `${slug}: the walk reached the end of the screen`).toBe(true);
    const start = stops.indexOf(EXAMPLE);
    expect(start, `${slug}: reached the example`).toBeGreaterThanOrEqual(0);
    expect(stops.slice(start + 1), slug).toEqual([...expected, COUNT]);
  });
}
