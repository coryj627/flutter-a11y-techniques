// L4 on web for V13 Minimum touch target size: what VoiceOver on macOS
// speaks for each example. Needs Guidepup's setup and macOS automation
// permissions on the machine. Run through
// `python3 tool/voiceover_web.py V13`, which also writes the transcript.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { walkToEnd } from './vo_helpers.js';

const EXAMPLE = 'heading level 2 Example';
// The press count is the last element of every example.
const COUNT = 'Presses: 0';
const PLAYER = ['Previous button', 'Play button', 'Next button'];

// slug -> everything VoiceOver speaks after the "Example" heading and before
// the count, in order, one entry for each element its cursor stops on. Size
// is not heard: the 18 pixel buttons are read as the 48 pixel ones.
const EXAMPLES = {
  'good-material': PLAYER,
  'good-cupertino': PLAYER,
  'good-custom': PLAYER,
  'good-inline-link': ['Read the', 'trail rules link', 'before you set off.'],
  'bad-shrinkwrap': PLAYER,
  'bad-zero-padding-web': PLAYER,
  'bad-cupertino-small': PLAYER,
  'bad-custom-small': PLAYER,
};

for (const [slug, expected] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/V13/${slug}`, { waitUntil: 'load' });
    await expect(page.locator(`[flt-semantics-identifier="v13-${slug}-count"]`)).toBeVisible();
    const { stops, reachedEnd } = await walkToEnd(page, voiceOver, browserName, 40);
    console.log(`V13VO ${browserName} ${slug} | ${stops.join(' / ')}`);
    expect(reachedEnd, `${slug}: the walk reached the end of the screen`).toBe(true);
    const start = stops.indexOf(EXAMPLE);
    expect(start, `${slug}: reached the example`).toBeGreaterThanOrEqual(0);
    expect(stops.slice(start + 1), slug).toEqual([...expected, COUNT]);
  });
}
