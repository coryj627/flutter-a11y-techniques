// L4 on web for F09 Switch: what VoiceOver on macOS speaks for each
// example. Needs Guidepup's setup and macOS automation permissions on the
// machine. Run through `python3 tool/voiceover_web.py F09`, which also
// writes the transcript.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { walkToEnd } from './vo_helpers.js';

const EXAMPLE = 'heading level 2 Example';
// The change count is the last element of every example.
const COUNT = 'Changes: 0';
const BLUETOOTH = 'Bluetooth';

// slug -> everything VoiceOver speaks after the "Example" heading and before
// the change count, in order, one entry for each element its cursor
// stops on. Because every stop is listed, the list also shows what is not
// spoken.
const EXAMPLES = {
  'good-tile': [`${BLUETOOTH} off switch`],
  'good-cupertino': [`${BLUETOOTH} off switch`],
  'good-custom': [`${BLUETOOTH} off switch`],
  // The question is the name of a group, said on the way in and again on
  // the way out.
  'good-group': [
    'Notify me about group',
    'Messages off switch',
    'Reminders off switch',
    'end of Notify me about group',
  ],
  // Bad examples: the defect must be audible where it can be.
  'bad-unlabelled': [BLUETOOTH, 'off switch'],
  // The switch is inside the button, and the content of a button is
  // presentational: VoiceOver never moves into it, so the switch and its
  // state are not heard at all. Chromium adds "group" for the button's
  // content; WebKit does not.
  'bad-tile-not-merged': {
    chromium: [`${BLUETOOTH} button, group`],
    webkit: [`${BLUETOOTH} button`],
  },
  // The state is said twice, once as part of the name.
  'bad-label-changes': [`${BLUETOOTH} off off switch`],
  'bad-no-state': [`${BLUETOOTH} button`],
};

for (const [slug, expected] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/F09/${slug}`, { waitUntil: 'load' });
    await expect(page.locator(`[flt-semantics-identifier="f09-${slug}-count"]`)).toBeVisible();
    // VoiceOver follows a control that has no name with its help message at
    // once; at such a move the walk records Guidepup's phrase for that move
    // (vo_helpers.js, phraseForMove).
    const { stops, reachedEnd } = await walkToEnd(page, voiceOver, browserName, 40, { loggedForHelp: true });
    console.log(`F09VO ${browserName} ${slug} | ${stops.join(' / ')}`);
    expect(reachedEnd, `${slug}: the walk reached the end of the screen`).toBe(true);
    const start = stops.indexOf(EXAMPLE);
    expect(start, `${slug}: reached the example`).toBeGreaterThanOrEqual(0);
    const content = Array.isArray(expected) ? expected : expected[browserName];
    // No fallback to another browser's speech: it differs, which is the point.
    expect(content, `${slug}: no expected speech for ${browserName}`).toBeDefined();
    expect(stops.slice(start + 1), slug).toEqual([...content, COUNT]);
  });
}
