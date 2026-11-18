// L4 on web for I03 Focus management: where VoiceOver on macOS goes, and
// what it says, when the question opens and closes and when a trail is
// removed, with VoiceOver's own activation. Needs Guidepup's setup and
// macOS automation permissions on the machine. Run through
// `python3 tool/voiceover_web.py I03`, which also writes the transcript.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { activateBrowser, cursorBounds, lastPhrase, waitUntilQuiet } from './vo_helpers.js';

const pressToAsk = ['good-material', 'good-cupertino', 'good-widgets', 'bad-focus-left-behind'];

const control = (page, slug, part) => page.locator(`[flt-semantics-identifier="i03-${slug}-${part}"]`);
// The test identifier is on the button's own element (TestId).
const button = control;

/**
 * The text of the smallest element of the page under VoiceOver's cursor,
 * found by comparing the cursor's bounds on the screen with each
 * element's. Throws if the cursor cannot be read.
 */
async function under(page) {
  const bounds = (await cursorBounds()).split(',').map((v) => Number(v.trim()));
  return page.evaluate(([l, t, r, b]) => {
    const cx = (l + r) / 2;
    const cy = (t + b) / 2;
    const top = window.screenY + (window.outerHeight - window.innerHeight);
    const left = window.screenX;
    let best = null;
    for (const e of document.querySelectorAll('flt-semantics, flt-semantics span, [role]')) {
      const rect = e.getBoundingClientRect();
      if (rect.width === 0 || rect.height === 0) continue;
      const x0 = left + rect.left;
      const y0 = top + rect.top;
      if (cx >= x0 && cx <= x0 + rect.width && cy >= y0 && cy <= y0 + rect.height) {
        const area = rect.width * rect.height;
        const text = (e.getAttribute('aria-label') || e.textContent || '').trim();
        if (text && (!best || area < best.area)) best = { area, text };
      }
    }
    return best ? best.text : '(nothing under the cursor)';
  }, bounds);
}

const tidy = (phrase) => phrase.replace(/\s+/g, ' ').trim();

/**
 * Runs `action` with VoiceOver's own command, then collects every new
 * phrase VoiceOver is given for `ms` milliseconds. The phrase from before
 * the action is left out, so a stale phrase cannot pass for one the
 * action caused; every read throws if VoiceOver cannot be read.
 */
async function heardAfter(page, action, ms = 4000) {
  const before = tidy(await lastPhrase());
  await action();
  const out = [];
  const end = Date.now() + ms;
  while (Date.now() < end) {
    const now = tidy(await lastPhrase());
    if (now && now !== before && now !== out[out.length - 1]) out.push(now);
    await page.waitForTimeout(200);
  }
  return out;
}

/** Puts DOM focus, and with it VoiceOver's cursor, on `locator`, and waits for quiet. */
async function cursorTo(page, locator) {
  await locator.focus();
  await waitUntilQuiet(page, 2000, 10000);
}

async function start(page, browserName, slug) {
  await page.goto(`/#/t/I03/${slug}`, { waitUntil: 'load' });
  await expect(control(page, slug, 'count')).toBeVisible();
  await activateBrowser(browserName);
  await page.bringToFront();
  // A real click, on inert text, puts keyboard focus in the page.
  await page.getByRole('heading', { name: 'Example', level: 2 }).click();
}

for (const slug of pressToAsk) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    test.skip(browserName === 'webkit', 'measured in Chromium only');
    await start(page, browserName, slug);
    // Open the question with VoiceOver's own command.
    const act = () => voiceOver.act();
    await cursorTo(page, button(page, slug, 'remove-lake'));
    const opened = await heardAfter(page, act);
    const openedOn = await under(page);
    // Cancel, with VoiceOver's cursor moved there.
    await cursorTo(page, button(page, slug, 'cancel'));
    const cancelled = await heardAfter(page, act);
    const cancelledOn = await under(page);
    // Remove Lake loop again, and Remove.
    await cursorTo(page, button(page, slug, 'remove-lake'));
    await heardAfter(page, act, 2000);
    await cursorTo(page, button(page, slug, 'confirm'));
    const removed = await heardAfter(page, act, 5000);
    const removedOn = await under(page);
    console.log(`I03VO ${browserName} ${slug} | opened: ${opened.join(' / ')} [on ${openedOn}] | cancelled: ${cancelled.join(' / ')} [on ${cancelledOn}] | removed: ${removed.join(' / ')} [on ${removedOn}]`);
    // Into the question: VoiceOver reads it and its cursor is in it, on
    // its title, on the whole sheet, or on Cancel where the general dialog
    // puts focus.
    expect(openedOn, slug).toMatch(/Remove Lake loop\?|^Cancel$/);
    expect(opened.length, `${slug}: VoiceOver said something when the question opened`).toBeGreaterThan(0);
    expect(cancelledOn, slug).toBe('Remove Lake loop');
    expect(cancelled.join(' | '), slug).toContain('Remove Lake loop');
    expect(removedOn, slug).toBe('Remove Summit path');
    expect(removed.join(' | '), slug).toContain('Remove Summit path');
  });
}

// On the web VoiceOver's cursor gives the element DOM focus, and DOM focus
// gives the button Flutter's keyboard focus, so the defect happens to a
// VoiceOver user as it does to a keyboard user: moving the cursor onto a
// Remove button asks. Written to fail when it stops asking.
test('voiceover reads bad-opens-on-focus', async ({ page, voiceOver, browserName }) => {
  test.skip(browserName === 'webkit', 'measured in Chromium only');
  const slug = 'bad-opens-on-focus';
  await start(page, browserName, slug);
  await cursorTo(page, page.getByRole('button', { name: 'Back' }));
  await expect(page.getByText(/\?$/)).toHaveCount(0);
  // VoiceOver's own moves, from Back down the screen, until the question
  // appears. Every move before the Remove button asks nothing: the moves
  // arrive, and only the one onto the button asks.
  const asked = () => page.getByText('Remove Ridge trail?').count();
  const spoken = [];
  for (let i = 0; i < 12 && !(await asked()); i++) {
    await voiceOver.next();
    await page.waitForTimeout(800);
    spoken.push(tidy(await lastPhrase()));
  }
  const onButton = spoken.findIndex((p) => p.startsWith('Remove Ridge trail'));
  console.log(`I03VO ${browserName} ${slug} | moving from Back: ${spoken.join(' / ')} | asked: ${await asked() > 0}`);
  expect(spoken.length, 'VoiceOver moved').toBeGreaterThan(1);
  await expect(page.getByText('Remove Ridge trail?')).toBeVisible();
  // The question came on the move onto Remove Ridge trail, or the move
  // after it, which reads the question.
  expect(onButton, 'the cursor reached Remove Ridge trail').toBeGreaterThanOrEqual(0);
  expect(spoken.length - 1 - onButton, 'asked on reaching the button').toBeLessThanOrEqual(1);
});
