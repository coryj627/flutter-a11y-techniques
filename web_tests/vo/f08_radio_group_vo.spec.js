// L4 on web for F08 Radio group: what VoiceOver on macOS speaks for each
// example. Needs Guidepup's setup and macOS automation permissions on the
// machine. Run through `python3 tool/voiceover_web.py F08`, which also
// writes the transcript.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { walkToEnd } from './vo_helpers.js';

const EXAMPLE = 'heading level 2 Example';
// The change count is the last element of every example.
const COUNT = 'Changes: 0';

// slug -> everything VoiceOver speaks after the "Example" heading and before
// the change count, in order, one entry for each element its cursor
// stops on. Because every stop is listed, the list also shows what is not
// spoken.
// In a browser on an Apple device Flutter gives the radio buttons that are
// not chosen the description "Not selected" (FL-047), which VoiceOver reads
// between the name and the role.
const SPEED = [
  'Delivery speed group',
  'Standard Not selected radio button, 1 of 3',
  'Express selected radio button, 2 of 3',
  'Next day Not selected radio button, 3 of 3',
  'end of Delivery speed group',
];
const EXAMPLES = {
  // The question is the name of a group, said on the way in and again on
  // the way out. The radio group inside it has no name (FL-046) and is not
  // announced; it is where "1 of 3" comes from.
  'good-group': SPEED,
  'good-cupertino': SPEED,
  'good-custom': SPEED,
  'good-context': [
    'Are you at home? group',
    'Yes, I am at home Not selected radio button, 1 of 2',
    'No, I am not at home selected radio button, 2 of 2',
    'end of Are you at home? group',
  ],
  // Bad examples: the defect must be audible where it can be.
  // The radio buttons have no names, and their stray texts have become the
  // name of the radio group.
  'bad-unlabelled': [
    'Delivery speed',
    'Standard Express Next day radio group',
    'radio button, 1 of 3',
    'selected radio button, 2 of 3',
    'radio button, 3 of 3',
    'end of Standard Express Next day radio group',
  ],
  // The question is plain text, and no group is announced.
  'bad-group-unlabelled': [
    'Delivery speed',
    'Standard Not selected radio button, 1 of 3',
    'Express selected radio button, 2 of 3',
    'Next day Not selected radio button, 3 of 3',
  ],
  'bad-no-state': ['Delivery speed', 'Standard button', 'Express button', 'Next day button'],
  'bad-checkbox-role': [
    'Delivery speed',
    'Standard unchecked checkbox',
    'Express checked checkbox',
    'Next day unchecked checkbox',
  ],
  // Correct radio buttons on the web: the defect of this example is on
  // iOS. With no radio group around them there is no "1 of 3".
  'bad-checked-only': [
    'Delivery speed',
    'Standard radio button',
    'Express selected radio button',
    'Next day radio button',
  ],
};

for (const [slug, expected] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/F08/${slug}`, { waitUntil: 'load' });
    await expect(page.locator(`[flt-semantics-identifier="f08-${slug}-count"]`)).toBeVisible();
    // VoiceOver follows a control that has no name with its help message at
    // once; at such a move the walk records Guidepup's phrase for that move
    // (vo_helpers.js, phraseForMove).
    const { stops, reachedEnd } = await walkToEnd(page, voiceOver, browserName, 40, { loggedForHelp: true });
    console.log(`F08VO ${browserName} ${slug} | ${stops.join(' / ')}`);
    expect(reachedEnd, `${slug}: the walk reached the end of the screen`).toBe(true);
    const start = stops.indexOf(EXAMPLE);
    expect(start, `${slug}: reached the example`).toBeGreaterThanOrEqual(0);
    const content = Array.isArray(expected) ? expected : expected[browserName];
    // No fallback to another browser's speech: it differs, which is the point.
    expect(content, `${slug}: no expected speech for ${browserName}`).toBeDefined();
    expect(stops.slice(start + 1), slug).toEqual([...content, COUNT]);
  });
}
