// L4 on web for S04 Functional images: what VoiceOver on macOS speaks for
// each example. Needs Guidepup's setup and macOS automation permissions on
// the machine. Run through `python3 tool/voiceover_web.py S04`, which also
// writes the transcript.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { walkToEnd } from './vo_helpers.js';

const EXAMPLE = 'heading level 2 Example';
// The activation count is the last element of every example.
const COUNT = 'Activations: 0';

// slug -> everything VoiceOver speaks after the "Example" heading and before
// the activation count, in order, one entry for each element its cursor
// stops on. Because every stop is listed, the list also shows what is not
// spoken.
const EXAMPLES = {
  'good-image-button': ['Open trail guide button'],
  'good-icon-label': ['Search button'],
  'good-image-with-text': ['Trail guide button', 'Print button'],
  'good-cupertino': ['Search button'],
  'good-custom': ['Open trail guide button'],
  'good-image-regions': ['West trail button', 'East trail button'],
  // Bad examples: the defect must be audible.
  'bad-no-name': ['button'],
  'bad-label-on-image': ['Open trail guide button'],
  'bad-tap-gesture': ['Open trail guide image'],
  'bad-describes-picture': ['Magnifying glass button'],
  'bad-image-not-excluded': ['Trail guide button'],
  'bad-redundant-label': ['Printer Print button'],
};

for (const [slug, expected] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/S04/${slug}`, { waitUntil: 'load' });
    await expect(page.locator(`[flt-semantics-identifier="s04-${slug}-count"]`)).toBeVisible();
    const { stops, reachedEnd } = await walkToEnd(page, voiceOver, browserName);
    console.log(`S04VO ${browserName} ${slug} | ${stops.join(' / ')}`);
    expect(reachedEnd, `${slug}: the walk reached the end of the screen`).toBe(true);
    const start = stops.indexOf(EXAMPLE);
    expect(start, `${slug}: reached the example`).toBeGreaterThanOrEqual(0);
    expect(stops.slice(start + 1), slug).toEqual([...expected, COUNT]);
  });
}
