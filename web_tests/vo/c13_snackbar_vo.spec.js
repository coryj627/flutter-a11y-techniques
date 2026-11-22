// L4 on web for C13 Snackbar and transient messages: what VoiceOver on
// macOS announces when each example's message is shown, with keyboard
// focus left on the button that showed it, and, for the messages that
// stay, what it reads walking the screen once the message is there. Needs
// Guidepup's setup and macOS automation permissions on the machine. Run
// through `python3 tool/voiceover_web.py C13`, which also writes the
// transcript.
//
// No test in this file is retried by the runner, so a wrong reading on a
// first attempt cannot be hidden by a retry that passes. A walk retries
// itself only when it was cut short before the end of the screen with
// every stop right so far (runWalks and judgeWalk in c13_vo_walks.js); a
// wrong stop, or a walk that reached the end with any expected stop not
// read, fails for good, and every try is logged.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import {
  activateBrowser, assertCaptureIsLive, heardAfter, waitUntilQuiet, walkToEnd,
} from './vo_helpers.js';
import { SHOWN_WALKS, judgeWalk, runWalks } from './c13_vo_walks.js';

test.describe.configure({ retries: 0 });

// slug -> what must be announced once the button is pressed, or what must
// not be.
const ANNOUNCED = {
  'good-action': { must: 'Message archived' },
  'good-message': { must: 'Draft saved' },
  'good-banner': { must: 'You are offline.' },
  // The defects of these two are in time, not in what is announced.
  'bad-action-times-out': { must: 'Message archived' },
  'bad-only-in-message': { must: 'Booked. Code: K7Q2' },
  // A banner put in the page is not a live region (FL-295).
  'bad-inline-banner': { mustNot: 'offline' },
};

const show = (page, slug) => page.locator(`[flt-semantics-identifier="c13-${slug}-show"]`);

/** Opens the example and puts keyboard focus, and VoiceOver, on its button. */
async function openAtButton(page, browserName, slug) {
  await page.goto(`/#/t/C13/${slug}`, { waitUntil: 'load' });
  await expect(show(page, slug)).toBeVisible();
  await page.waitForTimeout(600);
  await activateBrowser(browserName);
  await page.bringToFront();
  // A real click puts keyboard focus in the page; then onto the button.
  await page.getByRole('heading', { name: 'Example', level: 2 }).click();
  await show(page, slug).focus();
  return waitUntilQuiet(page);
}

for (const [slug, { must, mustNot }] of Object.entries(ANNOUNCED)) {
  test(`voiceover announces ${slug}`, async ({ page, voiceOver, browserName }) => {
    // Playwright's WebKit build passes no live region changes to VoiceOver
    // (I12's spec: a plain HTML live region is silent there too).
    test.skip(browserName === 'webkit', 'WebKit test build does not announce live regions');
    expect(voiceOver).toBeTruthy();
    const quiet = await openAtButton(page, browserName, slug);
    const heard = await heardAfter(page, () => page.keyboard.press('Enter'), quiet, 6000);
    console.log(`C13VO ${browserName} ${slug}-announced | ${heard.join(' / ') || '(nothing)'}`);
    // The button acted: the page's line changed.
    await expect(page.locator(`[flt-semantics-identifier="c13-${slug}-count"]`)).not.toHaveText(/: 0$|online$/);
    // Silence counts only if capture is still working.
    if (mustNot) await assertCaptureIsLive(page, voiceOver);
    const all = heard.join(' | ');
    if (must) expect(all, slug).toContain(must);
    if (mustNot) expect(all, slug).not.toContain(mustNot);
  });
}

for (const [slug, whole] of Object.entries(SHOWN_WALKS)) {
  test(`voiceover reads ${slug} with its message shown`, async ({ page, voiceOver, browserName }) => {
    expect(voiceOver).toBeTruthy();
    await openAtButton(page, browserName, slug);
    await page.keyboard.press('Enter');
    await page.waitForTimeout(1500);
    const { verdict, reason, walks } = await runWalks(
      () => walkToEnd(page, voiceOver, browserName, 40),
      (stops, reachedEnd) => judgeWalk(stops, reachedEnd, whole),
      {
        log: (walk, stops, judged) => {
          console.log(`C13VO ${browserName} ${slug}-walk-${walk} | ${stops.join(' / ') || '(nothing)'} (${judged.verdict}: ${judged.reason})`);
        },
      });
    if (slug === 'good-action') {
      // A diagnostic, judged by nobody: whether Close's tooltip was shown
      // when the walk ended. While it is shown, the tree names Close
      // "Close Close" (FL-249; docs/specs/C13-snackbar.md, section 7). Read
      // once, after the walk, not at Close's stop.
      const owns = await page.evaluate(() => [...document.querySelectorAll('flt-semantics[role="button"]')]
        .filter((e) => e.textContent.trim() === 'Close' && e.hasAttribute('aria-owns')).length);
      console.log(`C13VO ${browserName} ${slug}-close-tooltip-after-walk | ${owns ? 'shown' : 'not shown'}`);
    }
    expect(verdict, `${slug}, walk ${walks}: ${reason}`).toBe('complete');
  });
}
