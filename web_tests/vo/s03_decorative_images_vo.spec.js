// L4 on web for S03 Decorative images: what VoiceOver on macOS speaks for
// each example. Needs Guidepup's setup and macOS automation permissions on
// the machine. Run through `python3 tool/voiceover_web.py S03`, which also
// writes the transcript.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { walkToEnd } from './vo_helpers.js';

const WELCOME = ['Welcome back, Ana.', 'You have 2 new messages.'];
const DELIVERY = 'Delivery takes 2 to 4 days.';
const EXAMPLE = 'heading level 2 Example';

// VoiceOver stops on the icon's label and then on the word, which are the
// same text. The repeated word is expected at the second stop; an empty
// phrase is accepted too, for a VoiceOver that reports nothing new there.
// That it is a stop on another element is known from the cursor's position
// (walkToEnd).
const again = (word) => [word, ''];

// slug -> everything VoiceOver speaks after the "Example" heading, in order,
// one entry for each element its cursor stops on. An entry that is a list
// names the phrases that are accepted at that stop. Because every stop to
// the end of the screen is listed, the list also shows what is not spoken.
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
    const { stops, reachedEnd } = await walkToEnd(page, voiceOver, browserName);
    console.log(`S03VO ${browserName} ${slug} | ${stops.join(' / ')}`);
    expect(reachedEnd, `${slug}: the walk reached the end of the screen`).toBe(true);
    const start = stops.indexOf(EXAMPLE);
    expect(start, `${slug}: reached the example`).toBeGreaterThanOrEqual(0);
    const content = stops.slice(start + 1);
    expect(content.length, `${slug}: stops in ${content.join(' / ')}`).toBe(expected.length);
    expected.forEach((accepted, i) => {
      expect([accepted].flat(), `${slug}: stop ${i + 1} of ${content.join(' / ')}`).toContain(content[i]);
    });
  });
}
