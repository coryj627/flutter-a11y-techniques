// L4 on web for S02 Informative images: what VoiceOver on macOS speaks for
// each example. Needs Guidepup's setup and macOS automation permissions on
// the machine. Run through `python3 tool/voiceover_web.py S02`, which also
// writes the transcript.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { walkFromBack } from './vo_helpers.js';

// slug -> [phrases that must be spoken, phrases that must not be]. The walk
// stops at the last phrase in the first list.
const EXAMPLES = {
  'good-image-label': [
    ['Sunrise over green hills image', 'Taken from the east ridge trail.'], []],
  'good-icon-label': [
    ['Delivered Order 1042', 'Delayed Order 1043'], ['Order 1042', 'Delivered', 'image']],
  'good-group-description': [['Sunrise at 6:35 am'], ['6:35 am', 'image']],
  'good-chart': [
    ['Bar chart: orders rose every quarter of 2025 image',
      'Orders in 2025: Q1 20, Q2 35, Q3 50, Q4 80.'], []],
  // Bad examples: the defect must be audible.
  // The photo is announced as an image and nothing more.
  'bad-no-label': [['image', 'Taken from the east ridge trail.'], []],
  'bad-icon-no-label': [['Order 1042', 'Order 1043'], ['Delivered Order 1042', 'Delayed Order 1043']],
  'bad-role-in-label': [['Image of a sunrise over green hills image'], []],
  'bad-filename-label': [['IMG_2041.png image'], []],
};

for (const [slug, [must, mustNot]] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/S02/${slug}`, { waitUntil: 'load' });
    await expect(page.getByRole('heading', { name: 'Example', level: 2 })).toBeVisible();
    const last = must[must.length - 1];
    const spoken = await walkFromBack(page, voiceOver, browserName, (p) => p === last);
    console.log(`S02VO ${browserName} ${slug} | ${spoken.join(' / ')}`);
    for (const phrase of must) expect(spoken, slug).toContain(phrase);
    for (const phrase of mustNot) expect(spoken, slug).not.toContain(phrase);
    // Nothing in the example mentions the picture's content unless it has a
    // text alternative.
    if (slug === 'bad-no-label') {
      expect(spoken.filter((p) => /sunrise/i.test(p)), slug).toHaveLength(0);
    }
  });
}
