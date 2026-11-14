// L4 on web for S01 Accessible names: what VoiceOver on macOS speaks for each
// example. Needs Guidepup's setup and macOS automation permissions on the
// machine. Run through `python3 tool/voiceover_web.py S01`, which also writes
// the transcript.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { walkFromBack } from './vo_helpers.js';

// The slider's own phrase, not the title or the defect text that mention one.
const isSlider = (p) => /slider/.test(p) && !/^(heading|Defect)/.test(p);

// slug -> [phrases that must be spoken, phrases that must not be]. The walk
// stops at the last phrase in the first list.
const EXAMPLES = {
  'good-visible-label': [
    ['Email me order updates unchecked checkbox', 'Dark mode off switch'], []],
  'good-merged-label': [
    ['Remember this device unchecked checkbox', 'Wi-Fi off switch'], []],
  'good-specific-names': [
    ['Order updates, email off switch', 'Order updates, text message off switch'],
    ['Order updates off switch'],
  ],
  'good-cupertino': [['Airplane mode off switch'], []],
  // Bad examples: the defect must be audible.
  'bad-role-in-name': [['Dark mode switch off switch'], []],
};

for (const [slug, [must, mustNot]] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/S01/${slug}`, { waitUntil: 'load' });
    await expect(page.getByRole('heading', { name: 'Example', level: 2 })).toBeVisible();
    const last = must[must.length - 1];
    const spoken = await walkFromBack(page, voiceOver, browserName, (p) => p === last);
    console.log(`S01VO ${browserName} ${slug} | ${spoken.join(' / ')}`);
    for (const phrase of must) expect(spoken, slug).toContain(phrase);
    for (const phrase of mustNot) expect(spoken, slug).not.toContain(phrase);
  });
}

// The checkbox has no name. In Chromium VoiceOver reads it with none. In
// Playwright's WebKit build VoiceOver reads the text beside it as if it were
// the name: a guess from the layout, which the tree tests show is not exposed.
test('voiceover reads bad-unassociated-label', async ({ page, voiceOver, browserName }) => {
  const slug = 'bad-unassociated-label';
  await page.goto(`/#/t/S01/${slug}`, { waitUntil: 'load' });
  await expect(page.getByRole('heading', { name: 'Example', level: 2 })).toBeVisible();
  const spoken = await walkFromBack(page, voiceOver, browserName, (p) => p === 'I accept the terms');
  console.log(`S01VO ${browserName} ${slug} | ${spoken.join(' / ')}`);
  expect(spoken, slug).toContain('I accept the terms');
  if (browserName === 'chromium') {
    expect(spoken, slug).toContain('unchecked checkbox');
    expect(spoken, slug).not.toContain('I accept the terms unchecked checkbox');
  } else {
    expect(spoken, slug).toContain('I accept the terms unchecked checkbox');
  }
});

test('voiceover reads bad-duplicate-names', async ({ page, voiceOver, browserName }) => {
  const slug = 'bad-duplicate-names';
  await page.goto(`/#/t/S01/${slug}`, { waitUntil: 'load' });
  await expect(page.getByRole('heading', { name: 'Example', level: 2 })).toBeVisible();
  // Stop at the second switch: both are read with the same words.
  let seen = 0;
  const spoken = await walkFromBack(page, voiceOver, browserName,
    (p) => p === 'Order updates off switch' && ++seen === 2);
  console.log(`S01VO ${browserName} ${slug} | ${spoken.join(' / ')}`);
  expect(spoken.filter((p) => p === 'Order updates off switch'), slug).toHaveLength(2);
});

// Flutter limitation FL-028, in Chromium: VoiceOver reads the wrapper as a
// group called "Volume", then the slider with its value and no name. If it
// starts saying "Volume" with the slider after a Flutter upgrade, this fails
// and FL-028 is fixed.
//
// Playwright's WebKit build is recorded and not judged. There VoiceOver's
// cursor usually leaves the page content after the screen title and never
// reaches the slider. This test cannot tell a fault of the page from the
// harness losing focus, so nothing about the slider is asserted for WebKit;
// the walk is kept in the transcript as an observation (FL-029).
test('voiceover reads bad-slider-name-web', async ({ page, voiceOver, browserName }) => {
  const slug = 'bad-slider-name-web';
  await page.goto(`/#/t/S01/${slug}`, { waitUntil: 'load' });
  await expect(page.getByRole('heading', { name: 'Example', level: 2 })).toBeVisible();
  const spoken = await walkFromBack(page, voiceOver, browserName, isSlider, 12, true);
  console.log(`S01VO ${browserName} ${slug} | ${spoken.join(' / ')}`);
  // Capture is working and the cursor started in the page.
  expect(spoken[0], slug).toBe('heading level 1 Slider whose name is lost on web');
  if (browserName !== 'chromium') return;
  const slider = spoken.filter(isSlider);
  expect(spoken, slug).toContain('Volume group');
  expect(slider, slug).toHaveLength(1);
  expect(slider[0], slug).toContain('40%');
  expect(slider[0], slug).not.toContain('Volume');
});
