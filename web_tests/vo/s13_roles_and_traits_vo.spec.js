// L4 on web for S13 Roles and traits: what VoiceOver on macOS speaks for
// each example. Needs Guidepup's setup and macOS automation permissions on
// the machine. Run through `python3 tool/voiceover_web.py S13`, which also
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
  'good-standard': ['Save button', 'Wi-Fi off switch', 'Remember me unchecked checkbox'],
  'good-cupertino': ['Save button', 'Wi-Fi off switch'],
  'good-custom-button': ['Scan barcode button'],
  'good-custom-switch': ['Dark mode off switch'],
  // `selected` on a button is aria-current on web, read as "current item".
  'good-selected': ['Day button', 'Week current item button', 'Month button'],
  // On web every node with a tap action is a button (FL-006), so the
  // missing role cannot be heard here.
  'bad-no-role': ['Scan barcode button'],
  // Bad examples: the defect must be audible.
  'bad-wrong-role': ['Dark mode button'],
  'bad-role-on-text': ['Free delivery button'],
  // One stop. In Chromium the button around the button is heard as a
  // group; Playwright's WebKit build reads a plain button.
  'bad-role-on-standard': { chromium: ['Save button, group'], webkit: ['Save button'] },
  // Read the same as the good custom button: the missing action is not
  // spoken. The tree test shows that activation does nothing.
  'bad-action-hidden': ['Scan barcode button'],
  // The defect is on iOS only (FL-033).
  'bad-switch-not-enabled': ['Dark mode off switch'],
};

for (const [slug, expected] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/S13/${slug}`, { waitUntil: 'load' });
    await expect(page.locator(`[flt-semantics-identifier="s13-${slug}-count"]`)).toBeVisible();
    const { stops, reachedEnd } = await walkToEnd(page, voiceOver, browserName);
    console.log(`S13VO ${browserName} ${slug} | ${stops.join(' / ')}`);
    expect(reachedEnd, `${slug}: the walk reached the end of the screen`).toBe(true);
    const start = stops.indexOf(EXAMPLE);
    expect(start, `${slug}: reached the example`).toBeGreaterThanOrEqual(0);
    const content = Array.isArray(expected) ? expected : expected[browserName];
    // No fallback to another browser's speech: it differs, which is the point.
    expect(content, `${slug}: no expected speech for ${browserName}`).toBeDefined();
    expect(stops.slice(start + 1), slug).toEqual([...content, COUNT]);
  });
}
