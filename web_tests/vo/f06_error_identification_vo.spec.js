// L4 on web for F06 Error identification and announcement: what VoiceOver
// on macOS is given after each example's form is sent with the keyboard,
// and where its cursor is then. Needs Guidepup's setup and macOS automation
// permissions. Run through `python3 tool/voiceover_web.py F06`, which also
// writes the transcript.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import {
  activateBrowser, assertCaptureIsLive, heardAfter, lastPhrase, phraseForMove, waitUntilQuiet,
} from './vo_helpers.js';

const NAME_ERROR = 'Enter your name.';
const EMAIL_ERROR = 'Enter an email address with an @, like name@example.com.';

// slug -> { heard: text each of which must be in what VoiceOver is given
// after Send, mustNot: text that must not be, cursor: text the cursor's
// element must read afterwards }.
const EXAMPLES = {
  'good-form': { heard: [NAME_ERROR], mustNot: [EMAIL_ERROR], cursor: 'Name' },
  'good-cupertino': { heard: [NAME_ERROR], mustNot: [EMAIL_ERROR], cursor: 'Name' },
  // Focus goes to the field; nothing says what is wrong.
  'bad-color-only': { heard: [], mustNot: ['Enter', 'Invalid'], cursor: 'Email' },
  'bad-vague-message': { heard: ['Invalid.'], mustNot: [EMAIL_ERROR], cursor: 'Email' },
  // Nothing is announced, and the cursor stays on Send.
  'bad-not-announced': { heard: [], mustNot: [EMAIL_ERROR], cursor: 'Send' },
  'bad-merged-error': { heard: [EMAIL_ERROR], mustNot: [], cursor: 'Email' },
};

const clean = (s) => (s ?? '').replace(/\s+/g, ' ').trim();

for (const [slug, { heard: must, mustNot, cursor }] of Object.entries(EXAMPLES)) {
  test(`voiceover announces ${slug}`, async ({ page, voiceOver, browserName }) => {
    // Playwright's WebKit build passes no live region or announcement to
    // VoiceOver; a plain HTML page is silent there too (I12). Chromium only.
    test.skip(browserName === 'webkit', 'WebKit test build does not announce');
    expect(voiceOver).toBeTruthy();
    await page.goto(`/#/t/F06/${slug}`, { waitUntil: 'load' });
    const send = page.locator(`[flt-semantics-identifier="f06-${slug}-send"]`);
    await expect(send).toBeVisible();
    await activateBrowser(browserName);
    await page.bringToFront();
    await page.getByRole('heading', { name: 'Example', level: 2 }).click();
    await send.focus();
    const quiet = await waitUntilQuiet(page);
    // Enter does not activate a CupertinoButton on the web (FL-002).
    const key = slug === 'good-cupertino' ? 'Space' : 'Enter';
    const heard = (await heardAfter(page, () => page.keyboard.press(key), quiet, 8000)).map(clean);
    // Where the cursor is: one move forward and one back reads it. A text
    // field with a description is followed at once by VoiceOver's help
    // message; for that move the phrase Guidepup logged is used
    // (vo_logic.js, phraseForMove).
    const move = async (step) => {
      await step();
      await page.waitForTimeout(800);
      return clean(phraseForMove(await lastPhrase(), await voiceOver.lastSpokenPhrase()));
    };
    const forward = await move(() => voiceOver.next());
    const back = await move(() => voiceOver.previous());
    console.log(`F06VO ${browserName} ${slug} | on Send: ${clean(quiet)} / after Send: ${heard.join(' / ') || '(nothing)'} / forward: ${forward} / back: ${back}`);

    // Send acted: the example's visible change is on the page.
    const shown = {
      'bad-color-only': null, 'bad-vague-message': 'Invalid.', 'bad-not-announced': EMAIL_ERROR,
      'bad-merged-error': null,
    }[slug] ?? NAME_ERROR;
    if (slug === 'bad-color-only' || slug === 'bad-merged-error') {
      await expect(page.locator(`[flt-semantics-identifier="f06-${slug}-email"] input`)).toHaveAttribute('aria-invalid', 'true');
    } else {
      await expect(page.getByText(shown, { exact: true }).first()).toBeAttached();
    }
    // Silence counts only if capture is working.
    if (!must.length) await assertCaptureIsLive(page, voiceOver);

    const all = heard.join(' | ');
    for (const text of must) expect(all, slug).toContain(text);
    for (const text of mustNot) expect(all, slug).not.toContain(text);
    expect(back, `${slug}: where the cursor is`).toContain(cursor);
  });
}
