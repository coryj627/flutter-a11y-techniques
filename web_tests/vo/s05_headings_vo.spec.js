// L4 on web for S05 Headings: what VoiceOver on macOS speaks for each example.
// Needs Guidepup's setup and macOS automation permissions on the machine.
// Run through `python3 tool/voiceover_web.py S05`, which also writes the transcript.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { walkFromBack } from './vo_helpers.js';

// slug -> [phrases that must be spoken, phrases that must not be, last element].
const EXAMPLES = {
  'good-levels': [
    ['heading level 3 Profile', 'heading level 4 Contact details',
      'heading level 4 Email preferences', 'heading level 3 Security',
      'Choose which messages you receive.'],
    [],
    'Manage your password and sign-in methods.',
  ],
  'good-cupertino': [['heading level 3 Notifications'], [], 'Offers'],
  // Bad examples: the defect must be audible.
  'bad-visual-only': [['Profile'], ['heading level 3 Profile'],
    'Your name and photo are shown to other members.'],
  'bad-fake-label': [['Profile, heading'], ['heading level 3 Profile'],
    'Your name and photo are shown to other members.'],
  'bad-skipped-level': [['heading level 3 Profile', 'heading level 5 Contact details'], [],
    'We use these to reach you about your account.'],
  // Flutter limitation FL-004: header with no level is always level 2 on web.
  'bad-header-only': [['heading level 2 Profile'], ['heading level 3 Profile'],
    'Your name and photo are shown to other members.'],
  'bad-emphasis-heading': [['heading level 4 Please check your address before you pay.'], [],
    'We cannot change an address after dispatch.'],
  // Flutter limitation: CupertinoListSection does not expose its header.
  'bad-cupertino-section-header': [['Notifications'], ['heading level 3 Notifications'], 'Offers'],
};

for (const [slug, [must, mustNot, last]] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/S05/${slug}`, { waitUntil: 'load' });
    await expect(page.getByRole('heading', { name: 'Example', level: 2 })).toBeVisible();
    const spoken = await walkFromBack(page, voiceOver, browserName, (p) => p === last);
    console.log(`S05VO ${browserName} ${slug} | ${spoken.join(' / ')}`);
    // Every screen starts with its title as the level 1 heading.
    expect(spoken[0], slug).toMatch(/^heading level 1 /);
    for (const phrase of must) expect(spoken, slug).toContain(phrase);
    for (const phrase of mustNot) expect(spoken, slug).not.toContain(phrase);
  });
}
