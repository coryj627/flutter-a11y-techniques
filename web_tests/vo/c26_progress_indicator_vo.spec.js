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
// The spinners are also reached for while they load: each must do what was
// measured for its browser (SPINNER_READINGS in c26_vo_walks.js): read
// exactly as measured, with the name and no word that says it is an
// indicator (`-loading`, FL-256), or, Material's spinner in Chromium,
// passed over by VoiceOver's next (`-loading-passed-over`).
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
  EXAMPLE_HEADING, SPINNER_READINGS, WALKS, judgeExampleWalk, judgeSpinnerRow, runWalks, screenStops,
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

// The spinners' defect (FL-256), while loading, one test for each row of
// SPINNER_READINGS, in its own browser: keyboard focus, and with it
// VoiceOver's cursor, on the button; Enter; VoiceOver's speech for the
// press let settle (the announcement "Loading started" in Chromium: until
// the last phrase holds for 400 ms, at most one second); then VoiceOver
// moves forward while the spinner is shown (four seconds), each read once
// it has spoken (afterMove), with the cursor's bounds, the time since
// Enter, and whether the spinner's element was in the page.
//
// - A `read` row (`-loading`): at most two moves; the spinner's reading
//   must be the one measured, exactly (judgeSpinnerReading).
// - A `passedOver` row (`-loading-passed-over`, Chromium with Material's
//   spinner): one move, which must land on the status line below the
//   spinner's place, and must not read the spinner (judgeSpinnerPassedOver).
//   The spinner's place on the screen is its box in the page moved by as
//   much as the button's: the button's box against the cursor's bounds on
//   it before the move.
//
// Every row fails a capture that is empty, stale, or late.
const ROWS = Object.entries(SPINNER_READINGS).flatMap(([slug, byBrowser]) =>
  Object.entries(byBrowser).map(([browser, row]) => ({ slug, browser, row })));

for (const { slug, browser, row } of ROWS) {
  const label = row.passedOver !== undefined ? 'passes over' : 'reads';
  test(`${browser}: voiceover ${label} ${slug}'s spinner while it loads`, async ({ page, voiceOver, browserName }) => {
    test.skip(browserName !== browser, `a ${browser} row`);
    expect(voiceOver).toBeTruthy();
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
    const buttonBox = await start(page, slug).boundingBox();
    const spinnerBox = await spinner.boundingBox();
    expect(buttonBox && spinnerBox, 'the button and the spinner have boxes').toBeTruthy();
    // The cursor must be on the button before the first move: its bounds the
    // button's size, to within 2 points.
    const [left, top, right, bottom] = before.position.split(',').map(Number);
    expect(Math.abs(right - left - buttonBox.width) <= 2 && Math.abs(bottom - top - buttonBox.height) <= 2,
      `VoiceOver's cursor at ${before.position} is not on the button (${buttonBox.width} by ${buttonBox.height})`).toBe(true);
    const spinnerBottom = Math.round(top - buttonBox.y + spinnerBox.y + spinnerBox.height);
    const moves = [];
    const most = row.passedOver !== undefined ? 1 : 2;
    for (let i = 0; i < most; i++) {
      await voiceOver.next();
      const { phrase, position } = await afterMove(page, moves[i - 1] ?? before);
      moves.push({ phrase, position, ms: Date.now() - t0, shown: (await spinner.count()) > 0 });
      if (phrase.includes(SPINNER_NAME)) break;
    }
    const { verdict, reason } = judgeSpinnerRow(row, before, moves, SPINNER_NAME, { status: 'Loading started', spinnerBottom });
    const shown = moves.map((m) =>
      `${m.phrase || '(empty)'} (${m.ms} ms, spinner ${m.shown ? 'shown' : 'gone'}, at ${m.position})`).join(' / ');
    const suffix = row.passedOver !== undefined ? 'loading-passed-over' : 'loading';
    console.log(`C26VO ${browserName} ${slug}-${suffix} | before (${settled}): ${before.phrase || '(empty)'} ` +
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
