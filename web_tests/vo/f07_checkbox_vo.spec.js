// L4 on web for F07 Checkbox: what VoiceOver on macOS speaks for each
// example. Needs Guidepup's setup and macOS automation permissions on the
// machine. Run through `python3 tool/voiceover_web.py F07`, which also
// writes the transcript.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { walkToEnd } from './vo_helpers.js';

const EXAMPLE = 'heading level 2 Example';
// The change count is the last element of every example.
const COUNT = 'Changes: 0';
const UPDATES = 'Email me product updates';

// slug -> everything VoiceOver speaks after the "Example" heading and before
// the change count, in order, one entry for each element its cursor
// stops on. Because every stop is listed, the list also shows what is not
// spoken.
const EXAMPLES = {
  'good-tile': [`${UPDATES} unchecked checkbox`],
  'good-cupertino': [`${UPDATES} unchecked checkbox`],
  'good-custom': [`${UPDATES} unchecked checkbox`],
  // "Select all" is mixed and is read as unchecked (FL-044). Written to
  // fail if VoiceOver starts to say "mixed".
  'good-mixed': ['Select all unchecked checkbox', 'Email checked checkbox', 'Text message unchecked checkbox'],
  // The question is the name of a group, said on the way in and again on
  // the way out.
  'good-group': [
    'Contact me by group',
    'Phone unchecked checkbox',
    'Post unchecked checkbox',
    'end of Contact me by group',
  ],
  // Bad examples: the defect must be audible where it can be.
  // The checkbox has no name. Playwright's WebKit build guesses one from
  // the text beside it, as it did in S01; Chromium does not.
  'bad-unlabelled': {
    chromium: ['unchecked checkbox', UPDATES],
    webkit: [`${UPDATES} unchecked checkbox`, UPDATES],
  },
  'bad-no-state': [`${UPDATES} button`],
  // The same words as good-mixed: on the web the two cannot be told apart.
  'bad-mixed-as-unchecked': ['Select all unchecked checkbox', 'Email checked checkbox', 'Text message unchecked checkbox'],
  'bad-group-unlabelled': ['Contact me by', 'Phone unchecked checkbox', 'Post unchecked checkbox'],
};

for (const [slug, expected] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/F07/${slug}`, { waitUntil: 'load' });
    await expect(page.locator(`[flt-semantics-identifier="f07-${slug}-count"]`)).toBeVisible();
    // VoiceOver follows a checkbox that has no name with its help message
    // at once; at such a move the walk records Guidepup's phrase for that
    // move (vo_helpers.js, phraseForMove).
    const { stops, reachedEnd } = await walkToEnd(page, voiceOver, browserName, 40, { loggedForHelp: true });
    console.log(`F07VO ${browserName} ${slug} | ${stops.join(' / ')}`);
    expect(reachedEnd, `${slug}: the walk reached the end of the screen`).toBe(true);
    const start = stops.indexOf(EXAMPLE);
    expect(start, `${slug}: reached the example`).toBeGreaterThanOrEqual(0);
    const content = Array.isArray(expected) ? expected : expected[browserName];
    // No fallback to another browser's speech: it differs, which is the point.
    expect(content, `${slug}: no expected speech for ${browserName}`).toBeDefined();
    expect(stops.slice(start + 1), slug).toEqual([...content, COUNT]);
  });
}
