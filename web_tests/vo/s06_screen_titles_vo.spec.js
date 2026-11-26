// L4 on web for S06 Screen and page titles: what VoiceOver on macOS speaks
// on each example screen, when its screen opens, and on the screen opened.
// Needs Guidepup's setup and macOS automation permissions on the machine.
// Run through `python3 tool/voiceover_web.py S06`, which also writes the
// transcript.
//
// No test in this file is retried by the runner. Each test retries instead,
// itself, only a walk cut short before the end of the screen with every stop
// right so far (runWalks and judgeWalk in s06_vo_walks.js). Every walk must
// read the whole screen, each stop in its place: a wrong stop, or a walk
// that reached the end with any expected stop not read, fails the test for
// good, and every try is logged, so every attempt is in the transcript.
//
// The opening rows (`-opening`) are recorded, not judged: what VoiceOver
// says in the six seconds after Enter opens the screen has not been
// measured on the web before this recording, and a reading measured once
// is not a prediction (docs/specs/S06-screen-titles.md, section 6). The
// row fails only if nothing at all was heard, so that an empty capture
// cannot pass for silence; it proves nothing about what is said.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import {
  activateBrowser, cursorBounds, heardAfter, lastPhrase, stopsToEnd, waitUntilQuiet, walkToEnd,
} from './vo_helpers.js';
import { EXAMPLE_HEADING, judgeExampleWalk, judgeWalk, runWalks, screenStops } from './s06_vo_walks.js';

test.describe.configure({ retries: 0 });

const TEXT = 'Three orders in the last 30 days.';

// slug -> everything VoiceOver speaks after the "Example" heading, to the
// end of the example screen: the one button.
const EXAMPLES = {
  'good-material': ['Open orders button'],
  'good-cupertino': ['Open orders button'],
  'bad-no-title': ['Open orders button'],
  'bad-vague-title': ['Open orders button'],
  'bad-no-document-title': ['Open orders button'],
  'bad-cupertino-unnamed': ['Open orders button'],
};

// slug -> everything VoiceOver speaks on the opened screen after its Back
// button, to the end of the screen. The title is the level 1 heading
// (headingLevel: 1); bad-no-title's large text is plain text.
const OPENED = {
  'good-material': ['heading level 1 Orders', TEXT],
  'good-cupertino': ['heading level 1 Orders', TEXT],
  'bad-no-title': ['Orders', TEXT],
  'bad-vague-title': ['heading level 1 Details', TEXT],
  'bad-no-document-title': ['heading level 1 Orders', TEXT],
  'bad-cupertino-unnamed': ['heading level 1 Orders', TEXT],
};

/** Walks the opened screen from its Back button, which has keyboard focus once it opens. */
async function walkOpened(page, voiceOver, browserName) {
  await activateBrowser(browserName);
  await page.bringToFront();
  await page.getByRole('button', { name: 'Back', exact: true }).first().focus();
  await waitUntilQuiet(page, 2000, 10000);
  const step = async () => {
    await voiceOver.next();
    return { phrase: await lastPhrase(), position: await cursorBounds() };
  };
  return stopsToEnd(step, await cursorBounds(), 12);
}

for (const [slug, expected] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/S06/${slug}`, { waitUntil: 'load' });
    await expect(page.getByRole('heading', { name: 'Example', exact: true, level: 2 })).toBeVisible();
    await page.waitForTimeout(600);

    // The example screen, walked whole.
    const atRest = await runWalks(
      () => walkToEnd(page, voiceOver, browserName, 40),
      (stops, reachedEnd) => judgeExampleWalk(stops, reachedEnd, expected, screenStops(slug)),
      {
        log: (walk, stops, judged) => {
          const start = stops.indexOf(EXAMPLE_HEADING);
          const shown = (judged.verdict === 'complete' ? stops.slice(start + 1) : stops).join(' / ') || '(nothing)';
          console.log(`S06VO ${browserName} ${slug}-walk-${walk} | ${shown} (${judged.verdict}: ${judged.reason})`);
        },
      });
    expect(atRest.verdict, `${slug}, walk ${atRest.walks}: ${atRest.reason}`).toBe('complete');

    // Opening the screen: keyboard focus on the button, Enter, and every
    // phrase for six seconds. Recorded, not judged (above).
    const button = page.locator(`[flt-semantics-identifier="s06-${slug}-open"]`);
    await button.focus();
    const before = await waitUntilQuiet(page, 2000, 10000);
    const heard = await heardAfter(page, () => page.keyboard.press('Enter'), before, 6000);
    await expect(page.getByText(TEXT, { exact: true })).toBeVisible();
    console.log(`S06VO ${browserName} ${slug}-opening | ${heard.join(' / ') || '(nothing)'} (recorded, not judged; document title "${await page.title()}")`);
    expect(heard.length, `${slug}: nothing was heard after Enter; the capture is not shown to be live`).toBeGreaterThan(0);

    // The opened screen, walked whole from its Back button.
    const opened = await runWalks(
      () => walkOpened(page, voiceOver, browserName),
      (stops, reachedEnd) => judgeWalk(stops, reachedEnd, OPENED[slug]),
      {
        log: (walk, stops, judged) => {
          console.log(`S06VO ${browserName} ${slug}-opened-walk-${walk} | ${stops.join(' / ') || '(nothing)'} (${judged.verdict}: ${judged.reason})`);
        },
      });
    expect(opened.verdict, `${slug} opened, walk ${opened.walks}: ${opened.reason}`).toBe('complete');
  });
}
