// L4 on web for C26 Progress indicator: what VoiceOver on macOS reads on
// each example's screen at rest, and what it announces while each task
// runs, with keyboard focus left on the button that started it. Needs
// Guidepup's setup and macOS automation permissions on the machine. Run
// through `python3 tool/voiceover_web.py C26`, which also writes the
// transcript.
//
// No test in this file is retried by the runner. A walk retries itself
// only when it was cut short before the end of the screen with every stop
// right so far (runWalks and judgeExampleWalk in c26_vo_walks.js); a wrong
// stop, or a walk that reached the end with any expected stop not read,
// fails for good, and every try is logged.
//
// The walk lists (WALKS in c26_vo_walks.js) are what the first recording
// read, in both browsers (docs/evidence/probes/c26/
// voiceover-web-round1-fail.md.txt). That recording failed six walks, the
// three with a bar in each browser, on lists written as predictions: a bar
// was read with its value twice, in its name and then as a percentage.
//
// The spinners are also read while they load (`-loading`): each must be
// read exactly as measured for its browser (SPINNER_READINGS: the name,
// and no word that says it is an indicator, FL-256), judged by
// judgeSpinnerReading in c26_vo_walks.js.
//
// This spec runs in a browser on a Mac, so bad-adaptive's spinner is the
// Cupertino one, with nothing for VoiceOver (FL-257).
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import {
  activateBrowser, assertCaptureIsLive, cursorBounds, heardAfter, lastPhrase, untilQuiet, waitUntilQuiet,
  walkToEnd,
} from './vo_helpers.js';
import {
  EXAMPLE_HEADING, SPINNER_READINGS, WALKS, judgeExampleWalk, judgeSpinnerReading, runWalks, screenStops,
} from './c26_vo_walks.js';

const SPINNER_NAME = 'Loading inbox';

test.describe.configure({ retries: 0 });

// slug -> what VoiceOver must announce once the task has run, or must not.
const ANNOUNCED = {
  'good-linear': { must: ['Half uploaded', 'Upload complete'] },
  'bad-no-role': { must: ['Loading started', 'Inbox loaded'] },
  'bad-cupertino-no-role': { must: ['Loading started', 'Inbox loaded'] },
  // The status line is no live region, and the bar's changes are not
  // announced (FL-254).
  'bad-silent-end': { mustNot: ['Upload started', 'Half uploaded', 'Upload complete'] },
};

const start = (page, slug) => page.locator(`[flt-semantics-identifier="c26-${slug}-start"]`);

const norm = (phrase) => phrase.replace(/\s+/g, ' ').trim();

/**
 * Waits, after a VoiceOver move, until its last phrase is a new non-empty
 * one, or `limitMs` has passed, and returns the phrase and the cursor's
 * bounds then. The first recording read the phrase straight after the
 * move and, in Chromium, got the announcement from before it twice
 * (docs/evidence/probes/c26/voiceover-web-round3-fail.md.txt).
 */
async function afterMove(page, previous, limitMs = 1200) {
  const end = Date.now() + limitMs;
  for (;;) {
    const phrase = norm(await lastPhrase());
    const position = await cursorBounds();
    if ((phrase && phrase !== previous.phrase) || Date.now() >= end) return { phrase, position };
    await page.waitForTimeout(150);
  }
}

// The spinners' defect (FL-256), read while loading: keyboard focus, and
// with it VoiceOver's cursor, on the button; Enter; VoiceOver's speech for
// the press let settle (the announcement "Loading started" in Chromium:
// until the last phrase holds for 400 ms, at most one second); then at most
// two VoiceOver moves forward while the spinner is shown (four seconds),
// each read once it has spoken (afterMove), with the cursor's bounds, the
// time since Enter, and whether the spinner's element was in the page.
// judgeSpinnerReading requires the browser's measured reading exactly
// (SPINNER_READINGS), and fails a capture that is empty, stale, or late.
// In Chromium and WebKit.
for (const slug of Object.keys(SPINNER_READINGS)) {
  test(`voiceover reads ${slug}'s spinner while it loads`, async ({ page, voiceOver, browserName }) => {
    expect(voiceOver).toBeTruthy();
    const expected = SPINNER_READINGS[slug][browserName];
    expect(expected, `no reading for ${browserName}`).toBeDefined();
    await page.goto(`/#/t/C26/${slug}`, { waitUntil: 'load' });
    await expect(start(page, slug)).toBeVisible();
    await page.waitForTimeout(600);
    await activateBrowser(browserName);
    await page.bringToFront();
    await page.getByRole('heading', { name: 'Example', level: 2 }).click();
    await start(page, slug).focus();
    await waitUntilQuiet(page);
    const spinner = page.locator(`[flt-semantics-identifier="c26-${slug}-spinner"]`);
    await page.keyboard.press('Enter');
    const t0 = Date.now();
    await spinner.waitFor({ timeout: 2000 });
    const { quiet } = await untilQuiet({
      read: lastPhrase, sleep: (ms) => page.waitForTimeout(ms), quietMs: 400, limitMs: 1000 });
    const before = { phrase: norm(await lastPhrase()), position: await cursorBounds() };
    const settled = `${Date.now() - t0} ms, ${quiet ? 'quiet' : 'not quiet'}`;
    const moves = [];
    for (let i = 0; i < 2; i++) {
      await voiceOver.next();
      const { phrase, position } = await afterMove(page, moves[i - 1] ?? before);
      moves.push({ phrase, position, ms: Date.now() - t0, shown: (await spinner.count()) > 0 });
      if (phrase.includes(SPINNER_NAME)) break;
    }
    const { verdict, reason } = judgeSpinnerReading(before, moves, SPINNER_NAME, expected);
    const shown = moves.map((m) =>
      `${m.phrase || '(empty)'} (${m.ms} ms, spinner ${m.shown ? 'shown' : 'gone'}, at ${m.position})`).join(' / ');
    console.log(`C26VO ${browserName} ${slug}-loading | before (${settled}): ${before.phrase || '(empty)'} ` +
      `(at ${before.position}) / ${shown} (${verdict}: ${reason})`);
    expect(verdict, `${slug}: ${reason}`).toBe('right');
  });
}

for (const [slug, byBrowser] of Object.entries(WALKS)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    const expected = byBrowser[browserName];
    expect(expected, `no list for ${browserName}`).toBeDefined();
    await page.goto(`/#/t/C26/${slug}`, { waitUntil: 'load' });
    await expect(page.getByRole('heading', { name: 'Example', exact: true, level: 2 })).toBeVisible();
    await page.waitForTimeout(600);
    const { verdict, reason, walks } = await runWalks(
      () => walkToEnd(page, voiceOver, browserName, 40),
      (stops, reachedEnd) => judgeExampleWalk(stops, reachedEnd, expected, screenStops(slug)),
      {
        log: (walk, stops, judged) => {
          const begin = stops.indexOf(EXAMPLE_HEADING);
          const shown = (judged.verdict === 'complete' ? stops.slice(begin + 1) : stops).join(' / ') || '(nothing)';
          console.log(`C26VO ${browserName} ${slug}-walk-${walk} | ${shown} (${judged.verdict}: ${judged.reason})`);
        },
      });
    expect(verdict, `${slug}, walk ${walks}: ${reason}`).toBe('complete');
  });
}

for (const [slug, { must = [], mustNot = [] }] of Object.entries(ANNOUNCED)) {
  test(`voiceover announces ${slug}`, async ({ page, voiceOver, browserName }) => {
    // Playwright's WebKit build passes no live region changes to VoiceOver
    // (I12's spec: a plain HTML live region is silent there too).
    test.skip(browserName === 'webkit', 'WebKit test build does not announce live regions');
    expect(voiceOver).toBeTruthy();
    await page.goto(`/#/t/C26/${slug}`, { waitUntil: 'load' });
    await expect(start(page, slug)).toBeVisible();
    await page.waitForTimeout(600);
    await activateBrowser(browserName);
    await page.bringToFront();
    // A real click puts keyboard focus in the page; then onto the button.
    await page.getByRole('heading', { name: 'Example', level: 2 }).click();
    await start(page, slug).focus();
    const quiet = await waitUntilQuiet(page);
    const heard = await heardAfter(page, () => page.keyboard.press('Enter'), quiet, 8000);
    console.log(`C26VO ${browserName} ${slug}-announced | ${heard.join(' / ') || '(nothing)'}`);
    // The task ran: its status line says it ended.
    await expect(page.locator(`[flt-semantics-identifier="c26-${slug}-status"]`)).toHaveText(/complete|loaded$/);
    // Silence counts only if capture is still working.
    if (mustNot.length) await assertCaptureIsLive(page, voiceOver);
    const all = heard.join(' | ');
    for (const phrase of must) expect(all, slug).toContain(phrase);
    for (const phrase of mustNot) expect(all, slug).not.toContain(phrase);
  });
}
