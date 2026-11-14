// L4 on web for S03 Decorative images: what VoiceOver on macOS speaks for
// each example. Needs Guidepup's setup and macOS automation permissions on
// the machine. Run through `python3 tool/voiceover_web.py S03`, which also
// writes the transcript.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { walkFromBack } from './vo_helpers.js';

const WELCOME = ['Welcome back, Ana.', 'You have 2 new messages.'];
const DELIVERY = 'Delivery takes 2 to 4 days.';
const EXAMPLE = 'heading level 2 Example';

// VoiceOver stops on the icon's label and then on the word, which are the
// same text. Guidepup reports no new phrase at the second of two stops that
// read the same, so that stop is recorded as '' here; the repeated word is
// accepted as well, in case a later Guidepup reports it.
const again = (word) => ['', word];

// slug -> everything VoiceOver speaks after the "Example" heading, in order,
// one entry for each stop. An entry that is a list names the phrases that
// are accepted at that stop. Because every stop is listed, the list also
// shows what is not spoken.
const EXAMPLES = {
  'good-image-excluded': WELCOME,
  'good-icon-no-label': ['Shipping', 'Returns', DELIVERY],
  'good-background-image': WELCOME,
  'good-exclude-semantics': ['Ana Kovac'],
  'good-merged-row': ['Trail guide 12 routes'],
  // Bad examples: the defect must be audible.
  // VoiceOver stops on the banner and has only its role to say.
  'bad-not-excluded': [WELCOME[0], 'image', WELCOME[1]],
  'bad-empty-label': [WELCOME[0], 'image', WELCOME[1]],
  'bad-redundant-label': ['Shipping', again('Shipping'), 'Returns', again('Returns'), DELIVERY],
  'bad-merged-image': ['Trail guide 12 routes image'],
};

for (const [slug, expected] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/S03/${slug}`, { waitUntil: 'load' });
    await expect(page.getByRole('heading', { name: 'Example', level: 2 })).toBeVisible();
    // Walk as many steps past the "Example" heading as the example has
    // elements, and one more. At the end of the screen VoiceOver says nothing
    // or repeats the last element, so that extra step shows nothing follows.
    const spoken = [];
    await walkFromBack(page, voiceOver, browserName, (phrase) => {
      spoken.push(phrase);
      const start = spoken.indexOf(EXAMPLE);
      return start >= 0 && spoken.length === start + 1 + expected.length + 1;
    });
    console.log(`S03VO ${browserName} ${slug} | ${spoken.join(' / ')}`);
    const start = spoken.indexOf(EXAMPLE);
    expect(start, `${slug}: reached the example`).toBeGreaterThanOrEqual(0);
    const content = spoken.slice(start + 1);
    expect(content.length, `${slug}: walked one step past the example`).toBe(expected.length + 1);
    expected.forEach((accepted, i) => {
      expect([accepted].flat(), `${slug}: stop ${i + 1} of ${content.join(' / ')}`).toContain(content[i]);
    });
    const last = expected[expected.length - 1];
    expect(['', last], `${slug}: nothing follows the last element`).toContain(content[expected.length]);
  });
}
