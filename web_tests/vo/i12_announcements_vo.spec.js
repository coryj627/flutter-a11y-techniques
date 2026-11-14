// L4 on web for I12 Announcements: what VoiceOver on macOS announces after
// each example's button is pressed. Needs Guidepup's setup and macOS
// automation permissions on the machine.
// Run through `python3 tool/voiceover_web.py I12`, which also writes the transcript.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { activateBrowser, assertCaptureIsLive, heardAfter, waitUntilQuiet } from './vo_helpers.js';

// slug -> { must: text that has to be announced, mustNot: text that must
// not be, atLeast: how many separate announcements are needed }.
const EXAMPLES = {
  'good-live-region': { must: ['1 item in cart'] },
  'good-announce': { must: ['Link copied'] },
  'good-snackbar': { must: ['Message archived'] },
  // Bad examples.
  'bad-silent-update': { mustNot: ['item in cart'] },
  'bad-chatty-live-region': { must: ['Uploading:'], atLeast: 4, listenMs: 7000 },
  // On web these two are announced: the browser treats the roles as live
  // regions. Their defect is on Android (FL-017); this pins down web.
  'bad-status-role-only': { must: ['1 item in cart'] },
  'bad-alert-role-only': { must: ['Could not save. Attempt 1 failed.'] },
};

for (const [slug, { must = [], mustNot = [], atLeast = 1, listenMs }] of Object.entries(EXAMPLES)) {
  test(`voiceover announces ${slug}`, async ({ page, voiceOver, browserName }) => {
    // Playwright's WebKit build does not pass live region changes to
    // VoiceOver at all: a plain HTML page with aria-live, role="status", and
    // role="alert" is silent there too. Announcements are checked in
    // Chromium only.
    test.skip(browserName === 'webkit', 'WebKit test build does not announce live regions');
    expect(voiceOver).toBeTruthy();

    await page.goto(`/#/t/I12/${slug}`, { waitUntil: 'load' });
    const action = page.locator(`[flt-semantics-identifier="i12-${slug}-action"]`);
    await expect(action).toBeVisible();
    await activateBrowser(browserName);
    await page.bringToFront();
    // A real click puts keyboard focus in the page; then onto the button.
    await page.getByRole('heading', { name: 'Example', level: 2 }).click();
    await action.focus();
    const quiet = await waitUntilQuiet(page);

    // The keyboard activates the button; VoiceOver is only listened to.
    const heard = await heardAfter(page, () => page.keyboard.press('Enter'), quiet, listenMs);
    console.log(`I12VO ${browserName} ${slug} | ${heard.join(' / ') || '(nothing)'}`);

    // Silence only counts if capture is still working: every read above
    // throws on failure, and here VoiceOver is made to say something.
    if (mustNot.length) await assertCaptureIsLive(page, voiceOver);

    const all = heard.join(' | ');
    for (const text of must) expect(all, slug).toContain(text);
    for (const text of mustNot) expect(all, slug).not.toContain(text);
    if (must.length) expect(heard.length, `${slug}: separate announcements`).toBeGreaterThanOrEqual(atLeast);
  });
}
