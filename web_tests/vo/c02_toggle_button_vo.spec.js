// L4 on web for C02 Toggle button: what VoiceOver on macOS speaks for each
// example, as it opens and again after its first control has been changed
// once. Needs Guidepup's setup and macOS automation permissions on the
// machine. Run through `python3 tool/voiceover_web.py C02`, which also
// writes the transcript.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { walkToEnd } from './vo_helpers.js';
import { CONTROL_HTML, runControlWalks } from './c02_control_html.js';

const EXAMPLE = 'heading level 2 Example';

// slug -> the identifier of the control that is changed once, and
// everything VoiceOver speaks after the "Example" heading and before the
// change count, in order, one entry for each element its cursor stops on:
// as the example opens, and after the change. Because every stop is
// listed, the lists also show what is not spoken. Flutter has no pressed
// state (FL-200): no example is read as a toggle button.
const EXAMPLES = {
  'good-icon-button': {
    control: 'c02-good-icon-button-bold',
    before: ['Bold off switch'],
    after: ['Bold on switch'],
  },
  'good-toggle-buttons': {
    control: 'c02-good-toggle-buttons-bold',
    before: ['Bold unchecked checkbox', 'Italic unchecked checkbox', 'Underline unchecked checkbox'],
    after: ['Bold checked checkbox', 'Italic unchecked checkbox', 'Underline unchecked checkbox'],
  },
  'good-cupertino': {
    control: 'c02-good-cupertino-mute',
    before: ['Mute off switch'],
    after: ['Mute on switch'],
  },
  'good-custom': {
    control: 'c02-good-custom-mute',
    before: ['Mute off switch'],
    after: ['Mute on switch'],
  },
  // Bad examples: the defect must be audible. Off is read as a plain
  // button; on is aria-current, "current item" (FL-201).
  'bad-selected-only': {
    control: 'c02-bad-selected-only-bold',
    before: ['Bold button'],
    after: ['Bold current item button'],
  },
  'bad-no-state': {
    control: 'c02-bad-no-state-mute',
    before: ['Mute button'],
    after: ['Mute button'],
  },
  'bad-label-changes': {
    control: 'c02-bad-label-changes-mute',
    before: ['Mute off switch'],
    after: ['Unmute on switch'],
  },
};

/** Walks the screen and returns the stops after the "Example" heading. */
async function read(page, voiceOver, browserName, label) {
  const { stops, reachedEnd } = await walkToEnd(page, voiceOver, browserName, 40);
  const start = stops.indexOf(EXAMPLE);
  console.log(`C02VO ${browserName} ${label} | ${(start >= 0 ? stops.slice(start + 1) : stops).join(' / ')}`);
  expect(reachedEnd, `${label}: the walk reached the end of the screen`).toBe(true);
  expect(start, `${label}: reached the example`).toBeGreaterThanOrEqual(0);
  return stops.slice(start + 1);
}

for (const [slug, { control, before, after }] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/C02/${slug}`, { waitUntil: 'load' });
    const count = page.locator(`[flt-semantics-identifier="c02-${slug}-count"]`);
    await expect(count).toBeVisible();
    expect(await read(page, voiceOver, browserName, slug), slug).toEqual([...before, 'Changes: 0']);
    await page.locator(`[flt-semantics-identifier="${control}"]`).click();
    await expect(count).toHaveText('Changes: 1');
    // The walk must end at the new count, so a reading from before the
    // change cannot pass.
    expect(await read(page, voiceOver, browserName, `${slug}-changed`), `${slug} after one change`)
      .toEqual([...after, 'Changes: 1']);
  });
}

// For comparison, a plain HTML page with no Flutter: what VoiceOver says
// for a toggle button with aria-pressed, off and on, and for a button with
// aria-current, which is what Flutter writes for `selected`.
//
// The walk helpers are made for the app's screens, and on this page a walk
// now and then missed the heading or the first button (the third run, both
// browsers: docs/evidence/probes/c02/README.md, "Native controls"). So the
// page is walked up to three times, and every try is logged with its
// verdict. Each walk is judged by judgeControlWalk (c02_control_html.js,
// tested on made-up walks in web_tests/c02_toggle_button.spec.js, which CI
// runs): a button read in other words, however that is worded, fails the
// test at once in whichever try; an empty or partial walk is a failed try;
// the test passes only on a complete one.
//
// The config retries a failed test twice, and a retry that passes makes
// the run pass (tool/voiceover_web.py reports PASS when Playwright exits 0,
// lists the test under "Walks that needed a retry", and keeps the last
// attempt's rows). So this test is not retried by the runner: its only
// retry is its own, for incomplete walks, in runControlWalks, which stops
// at the first wrong walk.
test.describe('control-html', () => {
  test.describe.configure({ retries: 0 });

  test('voiceover reads control-html', async ({ page, voiceOver, browserName }) => {
    await page.goto('about:blank');
    await page.setContent(CONTROL_HTML);
    const { verdict, reason, walks } = await runControlWalks(
      () => walkToEnd(page, voiceOver, browserName, 40),
      {
        log: (walk, stops, judged) => console.log(
          `C02VO ${browserName} control-html-walk-${walk} | ${stops.join(' / ') || '(nothing)'} (${judged.verdict}: ${judged.reason})`),
      });
    expect(verdict, `control-html, walk ${walks}: ${reason}`).toBe('complete');
  });
});
