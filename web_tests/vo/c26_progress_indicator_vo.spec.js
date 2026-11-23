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
// The walk lists are predictions, written before any VoiceOver recording
// of C26 on the web, from Chromium's tree (web_tests/
// c26_progress_indicator.spec.js) and from how VoiceOver read a button and
// plain text in earlier techniques. The first recording will say whether
// they hold; where they do not, they are set to what it read and the
// failed recording is kept in the probe folder, as C12 and C13 did.
//
// This spec runs in a browser on a Mac, so bad-adaptive's spinner is the
// Cupertino one, with nothing for VoiceOver (FL-257).
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import {
  activateBrowser, assertCaptureIsLive, heardAfter, waitUntilQuiet, walkToEnd,
} from './vo_helpers.js';
import { EXAMPLE_HEADING, judgeExampleWalk, runWalks, screenStops } from './c26_vo_walks.js';

test.describe.configure({ retries: 0 });

// slug -> browser -> everything VoiceOver speaks after the "Example"
// heading, to the end of the screen, in order, at rest: the button, the
// bar where there is one, and the status line. A spinner is shown only
// while loading, so it is not in a walk at rest.
const both = (list) => ({ chromium: list, webkit: list });
const EXAMPLES = {
  // The bar's name holds its value on the web (FL-037).
  'good-linear': both(['Upload report button', 'Report upload 0 progress indicator', 'Not started']),
  'good-circular': both(['Load inbox button', 'Inbox not loaded']),
  'good-cupertino': both(['Load inbox button', 'Inbox not loaded']),
  // The bar is named by its value alone; the words are text before it.
  'bad-no-label': both(['Upload report button', 'Report upload', '0 progress indicator', 'Not started']),
  'bad-silent-end': both(['Upload report button', 'Report upload 0 progress indicator', 'Not started']),
  'bad-adaptive': both(['Load inbox button', 'Inbox not loaded']),
  // The bar is not there; the words are text.
  'bad-cupertino-bar': both(['Upload report button', 'Report upload', 'Not started']),
};

// slug -> what VoiceOver must announce once the task has run, or must not.
const ANNOUNCED = {
  'good-linear': { must: ['Half uploaded', 'Upload complete'] },
  'good-circular': { must: ['Loading started', 'Inbox loaded'] },
  'good-cupertino': { must: ['Loading started', 'Inbox loaded'] },
  // The status line is no live region, and the bar's changes are not
  // announced (FL-254).
  'bad-silent-end': { mustNot: ['Uploaded', 'complete'] },
};

const start = (page, slug) => page.locator(`[flt-semantics-identifier="c26-${slug}-start"]`);

for (const [slug, byBrowser] of Object.entries(EXAMPLES)) {
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
