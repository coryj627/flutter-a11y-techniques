// L4 on web for S22 Semantics identifiers for testing: what VoiceOver on
// macOS speaks for each example. Needs Guidepup's setup and macOS automation
// permissions on the machine. Run through `python3 tool/voiceover_web.py
// S22`, which also writes the transcript.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { walkToEnd } from './vo_helpers.js';

const EXAMPLE = 'heading level 2 Example';
// The change count is the last element of every example.
const COUNT = 'Changes: 0';

// slug -> everything VoiceOver speaks after the "Example" heading and before
// the change count, in order, one entry for each element its cursor
// stops on. Because every stop is listed, the list also shows what is not
// spoken: no identifier is in any of them.
const EXAMPLES = {
  'good-merged': ['Save draft button'],
  'good-cupertino': ['Save draft button'],
  'good-custom': ['Save draft button'],
  'good-field': ['Project name edit text'],
  // On the web the button's name comes from its content, so the button
  // keeps its name here; Android and iOS lose it (FL-007).
  'bad-inside': ['Save draft button'],
  // Nothing is different for a VoiceOver user in these two.
  'bad-wrapper': ['Save draft button'],
  'bad-duplicate': ['Save draft button', 'Discard draft button'],
  // The identifier is not a name.
  'bad-id-as-name': ['button'],
};

for (const [slug, expected] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/S22/${slug}`, { waitUntil: 'load' });
    await expect(page.locator(`[flt-semantics-identifier="s22-${slug}-count"]`)).toBeVisible();
    // VoiceOver can follow a text field with its help message at once; at
    // such a move the walk records Guidepup's phrase for that move
    // (vo_helpers.js, phraseForMove).
    const { stops, reachedEnd } = await walkToEnd(page, voiceOver, browserName, 40, { loggedForHelp: true });
    console.log(`S22VO ${browserName} ${slug} | ${stops.join(' / ')}`);
    expect(reachedEnd, `${slug}: the walk reached the end of the screen`).toBe(true);
    // An identifier is never spoken, anywhere on the screen.
    expect(stops.join(' ').toLowerCase(), slug).not.toContain('s22');
    const start = stops.indexOf(EXAMPLE);
    expect(start, `${slug}: reached the example`).toBeGreaterThanOrEqual(0);
    const content = Array.isArray(expected) ? expected : expected[browserName];
    // No fallback to another browser's speech: it differs, which is the point.
    expect(content, `${slug}: no expected speech for ${browserName}`).toBeDefined();
    expect(stops.slice(start + 1), slug).toEqual([...content, COUNT]);
  });
}
