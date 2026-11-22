// L4 on web for C05 Accordion: what VoiceOver on macOS speaks for each
// example, with both sections closed and again after Shipping has been
// opened by a click. Needs Guidepup's setup and macOS automation
// permissions on the machine. Run through `python3 tool/voiceover_web.py
// C05`, which also writes the transcript.
//
// No test in this file is retried by the runner (the configure call
// below): the shared config retries a failed test twice, and a retry that
// passes makes the run pass, so a wrong reading on a first attempt would be
// hidden. Each test retries instead, itself, only a walk cut short before
// the end of the screen with every stop right so far (runWalks and
// judgeExampleWalk in c05_vo_walks.js, which
// web_tests/c05_accordion.spec.js tests on made-up walks). Every walk must
// read the whole screen, the title, the description (and a bad example's
// defect), the "Example" heading, and every expected stop after it, each in
// its place: a wrong stop, or a walk that reached the end with any expected
// stop not read, fails the test for good, and every try is logged, so every
// attempt is in the transcript.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { walkToEnd } from './vo_helpers.js';
import { EXAMPLE_HEADING, judgeExampleWalk, runWalks, screenStops } from './c05_vo_walks.js';

test.describe.configure({ retries: 0 });

const SHIPPING_TEXT = 'Orders ship in two days.';
const SHIPPING_ACTION = 'Track a parcel button';
const COUNT = 'Presses: 0';

// What VoiceOver is expected to say for a header, by what it is.
// EXPECTED READINGS NOT YET RECORDED: the phrases below follow what
// VoiceOver said for other controls in this project's transcripts and have
// not been heard for an accordion. The first recording decides them.
const collapsed = (name) => `${name} collapsed button`;
const expanded = (name) => `${name} expanded button`;
const inHeading = (reading) => `heading level 3 ${reading}`;

// slug -> every stop after the "Example" heading, to the end of the screen,
// closed and after Shipping has been opened.
const EXAMPLES = {
  ...Object.fromEntries(['good-material', 'good-cupertino', 'good-custom'].map((slug) => [slug, {
    closed: [inHeading(collapsed('Shipping')), inHeading(collapsed('Returns')), COUNT],
    open: [inHeading(expanded('Shipping')), SHIPPING_TEXT, SHIPPING_ACTION, inHeading(collapsed('Returns')), COUNT],
  }])),
  // Bad examples: the defect must be audible where the web shows it.
  'bad-no-state': {
    closed: [inHeading('Shipping button'), inHeading('Returns button'), COUNT],
    open: [inHeading('Shipping button'), SHIPPING_TEXT, SHIPPING_ACTION, inHeading('Returns button'), COUNT],
  },
  'bad-heading-on-button': {
    closed: ['heading level 3 Shipping', 'heading level 3 Returns', COUNT],
    open: ['heading level 3 Shipping', SHIPPING_TEXT, SHIPPING_ACTION, 'heading level 3 Returns', COUNT],
  },
  'bad-no-heading': {
    closed: [collapsed('Shipping'), collapsed('Returns'), COUNT],
    open: [expanded('Shipping'), SHIPPING_TEXT, SHIPPING_ACTION, collapsed('Returns'), COUNT],
  },
  // The defect is in where Tab goes, which this walk does not use.
  'bad-hidden-panel': {
    closed: [inHeading(collapsed('Shipping')), inHeading(collapsed('Returns')), COUNT],
    open: [inHeading(expanded('Shipping')), SHIPPING_TEXT, SHIPPING_ACTION, inHeading(collapsed('Returns')), COUNT],
  },
  // A button on the web (FL-006), with its state only in its
  // description; the defect, no button role, is on Android and iOS.
  'bad-expansion-tile': {
    closed: ['Shipping button', 'Returns button', COUNT],
    open: ['Shipping button', SHIPPING_TEXT, 'Returns button', COUNT],
  },
  'bad-cupertino-expansion-tile': {
    closed: ['Shipping button', 'Returns button', COUNT],
    open: [`Shipping ${SHIPPING_TEXT} button`, 'Returns button', COUNT],
  },
};

const tile = (slug) => slug.endsWith('expansion-tile');

/**
 * Walks the screen until a walk is complete or wrong, at most three times,
 * logging each try as `<label>-walk-<n>` with its verdict: the stops after
 * the "Example" heading for a complete walk, every stop for any other.
 */
async function read(page, voiceOver, browserName, label, expected, screen) {
  const { verdict, reason, walks } = await runWalks(
    () => walkToEnd(page, voiceOver, browserName, 40),
    (stops, reachedEnd) => judgeExampleWalk(stops, reachedEnd, expected, screen),
    {
      log: (walk, stops, judged) => {
        const start = stops.indexOf(EXAMPLE_HEADING);
        const shown = (judged.verdict === 'complete' ? stops.slice(start + 1) : stops).join(' / ') || '(nothing)';
        console.log(`C05VO ${browserName} ${label}-walk-${walk} | ${shown} (${judged.verdict}: ${judged.reason})`);
      },
    });
  expect(verdict, `${label}, walk ${walks}: ${reason}`).toBe('complete');
}

for (const [slug, { closed, open }] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/C05/${slug}`, { waitUntil: 'load' });
    const count = page.locator(`[flt-semantics-identifier="c05-${slug}-count"]`);
    await expect(count).toBeVisible();
    await page.waitForTimeout(600);
    await read(page, voiceOver, browserName, slug, closed, screenStops(slug));
    const header = tile(slug)
      ? page.getByRole('button', { name: 'Shipping', exact: true })
      : page.locator(`[flt-semantics-identifier="c05-${slug}-shipping"]`);
    await header.click();
    // The walk must end with the panel's text read, so a reading from
    // before the click cannot pass.
    await expect(page.getByText(SHIPPING_TEXT).or(page.getByRole('button', { name: new RegExp(SHIPPING_TEXT) }))).toHaveCount(1);
    await read(page, voiceOver, browserName, `${slug}-open`, open, screenStops(slug));
  });
}
