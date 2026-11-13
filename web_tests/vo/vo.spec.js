// THROWAWAY: spike K5. VoiceOver speech for the fixture, three runs.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';

for (const run of [1, 2, 3]) {
  test(`voiceover walk run ${run}`, async ({ page, voiceOver }) => {
    await page.goto('/#/t/X00/fixture', { waitUntil: 'load' });
    await expect(page.getByRole('button', { name: 'Save copy' })).toBeVisible();
    await voiceOver.navigateToWebContent();
    const phrases = [];
    for (let i = 0; i < 26; i++) {
      await voiceOver.next();
      phrases.push(await voiceOver.lastSpokenPhrase());
    }
    console.log(`VO RUN ${run} ${JSON.stringify(phrases)}`);
  });
}

test('voiceover live region', async ({ page, voiceOver }) => {
  await page.goto('/#/t/X00/fixture', { waitUntil: 'load' });
  await expect(page.getByRole('button', { name: 'Save copy' })).toBeVisible();
  await voiceOver.navigateToWebContent();
  await page.getByRole('button', { name: 'Save copy' }).focus();
  await page.keyboard.press('Enter');
  await page.waitForTimeout(3000);
  console.log(`VO LIVE ${JSON.stringify(await voiceOver.spokenPhraseLog())}`);
});
