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
import { activateBrowser, cursorBounds, lastPhrase, stopsToEnd, untilQuiet, walkToEnd } from './vo_helpers.js';
import { EXAMPLE_HEADING, judgeExampleWalk, runWalks, screenStops } from './c05_vo_walks.js';

test.describe.configure({ retries: 0 });

// Set only for the round 3 probe at the end of this file.
const PROBE = process.env.C05_VO_PROBE === '1';

const SHIPPING_TEXT = 'Orders ship in two days.';
const SHIPPING_ACTION = 'Track a parcel button';
const COUNT = 'Presses: 0';

// The SDK tiles' hint, as VoiceOver read it on a macOS browser.
const CLOSED_TILE = (name) => `${name} Collapsed double tap to expand button`;
const OPEN_HINT = 'Expanded double tap to collapse';

// What VoiceOver is expected to say for a header, by what it is.
// The first recording (docs/evidence/probes/c05/voiceover-web-round1-fail.md.txt)
// heard every reading below for the good examples and the hand-built bad
// ones, closed and open, in Chromium and WebKit; for the two SDK tiles it
// heard the closed readings only (see below). The second
// (docs/evidence/probes/c05/voiceover-web-round2-fail.md.txt) heard
// bad-expansion-tile open as well.
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
  // A button on the web (FL-006); the defect, no button role, is on
  // Android and iOS. The state is in its description, the tile's hint,
  // which on a macOS browser is a touch instruction: closed, as the first
  // recording heard it in Chromium and WebKit
  // (docs/evidence/probes/c05/voiceover-web-round1-fail.md.txt); open, as
  // the second heard it (voiceover-web-round2-fail.md.txt).
  'bad-expansion-tile': {
    closed: [CLOSED_TILE('Shipping'), CLOSED_TILE('Returns'), COUNT],
    open: [`Shipping ${OPEN_HINT} button`, SHIPPING_TEXT, CLOSED_TILE('Returns'), COUNT],
  },
  // The defect is the keyboard (see the tree spec); the same description
  // as bad-expansion-tile, closed, as heard. Open, the header and its
  // panel's text are one button (the tree spec); not heard yet: the
  // second recording's test ran into its timeout before the open walk
  // (see walkToEndClickingAtPoint).
  'bad-cupertino-expansion-tile': {
    closed: [CLOSED_TILE('Shipping'), CLOSED_TILE('Returns'), COUNT],
    open: [`Shipping ${SHIPPING_TEXT} ${OPEN_HINT} button`, CLOSED_TILE('Returns'), COUNT],
  },
};

const tile = (slug) => slug.endsWith('expansion-tile');

/**
 * walkToEnd (vo_helpers.js), with its first click made with the mouse at
 * the "Example" heading's place instead of Playwright's checked click on
 * the heading, as walkFromBack's `clickAtPoint` does for FL-029.
 *
 * Why: once a section of `CupertinoExpansionTile` has been opened, an empty
 * element the size of the view lies over the page in the semantics DOM and
 * takes pointer events (FL-029, extended; measured without VoiceOver in
 * docs/evidence/probes/c05/click_probe.txt). A checked click on the heading
 * there is refused (the probe: "intercepts pointer events", then its
 * timeout). In the second recording this example's test ran into the
 * test's timeout after its closed walk, with no open walk logged
 * (docs/evidence/probes/c05/voiceover-web-round2-fail.md.txt); its output
 * does not say which step was running.
 * The click is only there to bring keyboard focus into the page; focus is
 * then put on Back as walkToEnd does, and the walk is walkToEnd's, step for
 * step (stopsToEnd over VoiceOver's last phrase and cursor position).
 */
async function walkToEndClickingAtPoint(page, voiceOver, browserName, max = 40) {
  await activateBrowser(browserName);
  await page.bringToFront();
  const heading = page.getByRole('heading', { name: 'Example', exact: true, level: 2 });
  const box = await heading.boundingBox();
  if (!box) throw new Error(`The "Example" heading has no box to click on ${page.url()}`);
  await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
  await page.getByRole('button', { name: 'Back' }).focus();
  const { phrase, quiet } = await untilQuiet({
    read: lastPhrase, sleep: (ms) => page.waitForTimeout(ms), quietMs: 2000, limitMs: 10000 });
  if (!quiet) {
    throw new Error(`VoiceOver did not go quiet within 10 seconds of focusing Back; it last said "${phrase}"`);
  }
  const step = async () => {
    await voiceOver.next();
    return { phrase: await lastPhrase(), position: await cursorBounds() };
  };
  return stopsToEnd(step, await cursorBounds(), max);
}

/**
 * Walks the screen until a walk is complete or wrong, at most three times,
 * logging each try as `<label>-walk-<n>` with its verdict: the stops after
 * the "Example" heading for a complete walk, every stop for any other.
 */
async function read(page, voiceOver, browserName, label, expected, screen, { clickAtPoint = false } = {}) {
  const walk = clickAtPoint ? walkToEndClickingAtPoint : walkToEnd;
  const { verdict, reason, walks } = await runWalks(
    () => walk(page, voiceOver, browserName, 40),
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
    test.skip(PROBE, 'the round 3 probe is running instead');
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
    // Open, the Cupertino tile leaves an empty element over the page that
    // takes pointer events (see walkToEndClickingAtPoint).
    await read(page, voiceOver, browserName, `${slug}-open`, open, screenStops(slug),
      { clickAtPoint: slug === 'bad-cupertino-expansion-tile' });
  });
}

// ---------------------------------------------------------------------------
// Probe (round 3), run only with C05_VO_PROBE=1 set, through the tool:
//   C05_VO_PROBE=1 python3 tool/voiceover_web.py C05
// With it set, the tests above are skipped and only these run, in WebKit
// only. They judge nothing: each walk logs every stop (VoiceOver's last
// phrase and its cursor's position), so that the third recording's WebKit
// reading of the open bad-cupertino-expansion-tile, the page's web area as
// its only stop (docs/evidence/probes/c05/voiceover-web-round3-fail.md.txt),
// can be told apart: does it come from the screen once the tile is open,
// or from how the walk starts (a mouse click at a point)? Four starts, each
// on a fresh load and walked twice:
//
// - closed-keyboard: the tile closed; no click at all, Back focused by
//   script after the browser is brought to the front.
// - closed-point: the tile closed; the mouse click at the "Example"
//   heading's place that the open walk uses (walkToEndClickingAtPoint).
// - open-keyboard: the tile opened by a click on its header first; then as
//   closed-keyboard.
// - open-point: the tile opened; then as closed-point, as the third
//   recording's open walk did.
//
// Each row also logs, before the first move, what VoiceOver last said and
// where its cursor was once Back had been focused and VoiceOver went quiet.

async function probeWalk(page, voiceOver, browserName, { clickAtPoint }) {
  await activateBrowser(browserName);
  await page.bringToFront();
  if (clickAtPoint) {
    const box = await page.getByRole('heading', { name: 'Example', exact: true, level: 2 }).boundingBox();
    await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
  }
  await page.getByRole('button', { name: 'Back' }).focus();
  const { phrase, quiet } = await untilQuiet({
    read: lastPhrase, sleep: (ms) => page.waitForTimeout(ms), quietMs: 2000, limitMs: 10000 });
  const start = { phrase, quiet, position: await cursorBounds() };
  const moves = [];
  const step = async () => {
    await voiceOver.next();
    const move = { phrase: await lastPhrase(), position: await cursorBounds() };
    moves.push(move);
    return move;
  };
  const { stops, reachedEnd } = await stopsToEnd(step, start.position, 40);
  return { start, moves, stops, reachedEnd };
}

if (PROBE) {
  const starts = [
    ['closed-keyboard', false, false],
    ['closed-point', false, true],
    ['open-keyboard', true, false],
    ['open-point', true, true],
  ];
  for (const [name, opened, clickAtPoint] of starts) {
    test(`probe bad-cupertino-expansion-tile ${name}`, async ({ page, voiceOver, browserName }) => {
      test.skip(browserName !== 'webkit', 'the probe is for WebKit only');
      await page.goto('/#/t/C05/bad-cupertino-expansion-tile', { waitUntil: 'load' });
      await expect(page.locator('[flt-semantics-identifier="c05-bad-cupertino-expansion-tile-count"]')).toBeVisible();
      await page.waitForTimeout(600);
      if (opened) {
        await page.getByRole('button', { name: 'Shipping', exact: true }).click();
        await expect(page.getByText(SHIPPING_TEXT)).toHaveCount(1);
        await page.waitForTimeout(1000);
      }
      for (let n = 1; n <= 2; n++) {
        const { start, moves, stops, reachedEnd } = await probeWalk(page, voiceOver, browserName, { clickAtPoint });
        console.log(`C05VO ${browserName} probe-${name}-${n} | start: "${start.phrase}" ` +
          `(quiet: ${start.quiet}) at ${start.position} / stops: ${stops.join(' / ') || '(none)'} ` +
          `/ reached end: ${reachedEnd} / moves: ${moves.map((m) => `"${m.phrase}" at ${m.position}`).join('; ')}`);
      }
    });
  }
}
