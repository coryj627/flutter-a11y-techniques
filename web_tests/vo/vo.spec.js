// L4 on web for C01 Button, first cut (docs/plan.md, finding K5): VoiceOver
// on macOS reading the good-text example, three runs per browser.
// Needs Guidepup's setup and macOS automation permissions on the machine.
// Run from web_tests/vo: npx playwright test
import { execFile } from 'node:child_process';
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';

const APP_IDS = { chromium: 'com.google.chrome.for.testing', webkit: 'org.webkit.Playwright' };

// Guidepup's navigateToWebContent() activates the browser inside an
// AppleScript transaction, which these browser builds never answer on
// macOS 27 (AppleEvent timeout). A plain activate works.
const activate = (id) =>
  new Promise((resolve, reject) =>
    execFile('/usr/bin/osascript', ['-e', `tell application id "${id}" to activate`],
      { timeout: 20000 }, (err) => (err ? reject(err) : resolve())));

const step = async (name, promise, ms = 15000) => {
  const result = await Promise.race([
    promise,
    new Promise((_, reject) => setTimeout(() => reject(new Error(`${name} timed out after ${ms}ms`)), ms)),
  ]);
  console.log(`VO STEP ok: ${name}`);
  return result;
};

for (const run of [1, 2, 3]) {
  test(`voiceover reads good-text, run ${run}`, async ({ page, voiceOver, browserName }) => {
    await page.goto('/#/t/C01/good-text', { waitUntil: 'load' });
    const save = page.locator('[flt-semantics-identifier="c01-good-text-filled"]');
    await expect(save).toBeVisible();
    await step('activate browser', activate(APP_IDS[browserName]));
    await page.bringToFront();
    // Put keyboard focus on the first button; VoiceOver follows it.
    await step('focus Save', save.focus());
    await page.waitForTimeout(1500);
    // Guidepup only records speech that follows one of its own commands, so
    // step back once and then walk forward through the buttons.
    await step('previous', voiceOver.previous());
    const before = await voiceOver.lastSpokenPhrase();
    const phrases = [];
    for (let i = 0; i < 4; i++) {
      await step(`next ${i}`, voiceOver.next());
      phrases.push(await voiceOver.lastSpokenPhrase());
    }
    console.log(`VO RUN ${run} ${browserName} before=${JSON.stringify(before)} ${JSON.stringify(phrases)}`);
    expect(phrases).toEqual(['Save button', 'Cancel button', 'Learn more button', 'Activations: 0']);

    // Live region: activate Save from the keyboard. Guidepup records only
    // speech that follows its own commands, so the "Activations: 1"
    // announcement does not reach its log; the log is printed for evidence
    // and the announcement itself is asserted at L3 (flt-announcement-polite).
    await step('focus Save again', save.focus());
    await page.waitForTimeout(1000);
    await step('press Enter', page.keyboard.press('Enter'));
    await page.waitForTimeout(3000);
    console.log(`VO LOG ${run} ${browserName} ${JSON.stringify(await voiceOver.spokenPhraseLog())}`);
  });
}
