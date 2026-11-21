// L4 on web for C02 Toggle button: what VoiceOver on macOS speaks for each
// example, as it opens and again after its first control has been changed
// once. Needs Guidepup's setup and macOS automation permissions on the
// machine. Run through `python3 tool/voiceover_web.py C02`, which also
// writes the transcript.
//
// No test in this file is retried by the runner. The shared config retries
// a failed test twice, and a retry that passes makes the run pass:
// tool/voiceover_web.py reports PASS when Playwright exits 0, names the test
// under "Walks that needed a retry", and keeps only the last attempt's rows,
// so a wrong reading on the first attempt would be hidden. Each test
// retries instead, itself, only a capture that fell short (runWalks in
// c02_vo_walks.js): a walk with a wrong reading fails the test for good,
// and every try is logged, so every attempt is in the transcript.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { walkToEnd } from './vo_helpers.js';
import { CONTROL_HTML, EXAMPLE_HEADING, judgeExampleWalk, runControlWalks, runWalks } from './c02_vo_walks.js';

test.describe.configure({ retries: 0 });

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

/**
 * Walks the screen until a walk is complete or wrong, at most three times,
 * judging each against `expected` (judgeExampleWalk) and logging each try
 * as `<label>-walk-<n>`: the stops after the "Example" heading, or every
 * stop if the heading was not reached, and the verdict.
 */
async function read(page, voiceOver, browserName, label, expected) {
  const { verdict, reason, walks } = await runWalks(
    () => walkToEnd(page, voiceOver, browserName, 40),
    (stops, reachedEnd) => judgeExampleWalk(stops, reachedEnd, expected),
    {
      log: (walk, stops, judged) => {
        const start = stops.indexOf(EXAMPLE_HEADING);
        const shown = (start >= 0 ? stops.slice(start + 1) : stops).join(' / ') || '(nothing)';
        console.log(`C02VO ${browserName} ${label}-walk-${walk} | ${shown} (${judged.verdict}: ${judged.reason})`);
      },
    });
  expect(verdict, `${label}, walk ${walks}: ${reason}`).toBe('complete');
}

for (const [slug, { control, before, after }] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/C02/${slug}`, { waitUntil: 'load' });
    const count = page.locator(`[flt-semantics-identifier="c02-${slug}-count"]`);
    await expect(count).toBeVisible();
    await read(page, voiceOver, browserName, slug, [...before, 'Changes: 0']);
    await page.locator(`[flt-semantics-identifier="${control}"]`).click();
    await expect(count).toHaveText('Changes: 1');
    // The walk must end at the new count, so a reading from before the
    // change cannot pass: "Changes: 0" there is a wrong reading.
    await read(page, voiceOver, browserName, `${slug}-changed`, [...after, 'Changes: 1']);
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
// verdict. Each walk is judged by judgeControlWalk (c02_vo_walks.js,
// tested on made-up walks in web_tests/c02_toggle_button.spec.js, which CI
// runs): a button read in other words, however that is worded, fails the
// test at once in whichever try; an empty or partial walk is a failed try;
// the test passes only on a complete one. Like every test in this file it
// is not retried by the runner (the configure call at the top).
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
