// L4 on web for C01 Button: what VoiceOver on macOS speaks for each example.
// Needs Guidepup's setup and macOS automation permissions on the machine.
// Run through `python3 tool/voiceover_web.py C01`, which also writes the transcript.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { walkFromBack } from './vo_helpers.js';

// slug -> [phrases that must be spoken, phrases that must not be].
const EXAMPLES = {
  'good-text': [['Save button', 'Cancel button', 'Learn more button'], []],
  'good-icon': [['Close button'], []],
  'good-disabled': [['Submit dimmed button'], []],
  'good-unique-names': [
    ['Edit username button', 'Edit email button', 'Edit password button'],
    ['Edit button'],
  ],
  'good-cupertino': [['Save button', 'Delete dimmed button'], []],
  'good-custom': [['Save button'], []],
  // Bad examples: the defect must be audible.
  'bad-unlabelled-icon': [['button'], ['Close button']],
  // Flutter web gives every tappable node role="button", so on web this one
  // is announced as a button. Its defect on web is keyboard access, which the
  // tree suite asserts (c01_button.spec.js).
  'bad-gesture-only': [['Save button'], []],
  'bad-role-in-name': [['Close button button'], []],
  'bad-duplicate-names': [['Edit button'], ['Edit username button']],
  'bad-name-mismatch': [['Change username button'], ['Edit button']],
  'bad-fake-disabled': [['Submit button'], ['Submit dimmed button']],
  'bad-cupertino-disabled': [['Delete button'], ['Delete dimmed button']],
};

for (const [slug, [must, mustNot]] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/C01/${slug}`, { waitUntil: 'load' });
    await expect(page.locator(`[flt-semantics-identifier="c01-${slug}-count"]`)).toBeVisible();
    // Swipe forward to the activation count, the last element.
    const spoken = await walkFromBack(page, voiceOver, browserName, (p) => p.startsWith('Activations:'));
    console.log(`C01VO ${browserName} ${slug} | ${spoken.join(' / ')}`);
    for (const phrase of must) expect(spoken, slug).toContain(phrase);
    for (const phrase of mustNot) expect(spoken, slug).not.toContain(phrase);
  });
}
