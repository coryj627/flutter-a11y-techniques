// L4 on web for C06 Disclosure: what VoiceOver on macOS speaks for each
// example, closed and again after a click has opened it. Needs Guidepup's
// setup and macOS automation permissions on the machine. Run through
// `python3 tool/voiceover_web.py C06`, which also writes the transcript.
//
// No test in this file is retried by the runner (the configure call
// below): the shared config retries a failed test twice, and a retry that
// passes makes the run pass, so a wrong reading on a first attempt would be
// hidden. Each test retries instead, itself, only a walk cut short before
// the end of the screen with every stop right so far (runWalks and
// judgeExampleWalk in c06_vo_walks.js, which
// web_tests/c06_disclosure.spec.js tests on made-up walks). Every walk must
// read the whole screen, the title, the description (and a bad example's
// defect), the "Example" heading, and every expected stop after it, each in
// its place: a wrong stop, or a walk that reached the end with any expected
// stop not read, fails the test for good, and every try is logged, so every
// attempt is in the transcript.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { activateBrowser, cursorBounds, lastPhrase, stopsToEnd, untilQuiet, walkToEnd } from './vo_helpers.js';
import { EXAMPLE_HEADING, judgeExampleWalk, runWalks, screenStops } from './c06_vo_walks.js';

test.describe.configure({ retries: 0 });

const TITLE = 'Details';
const PANEL_TEXT = 'Orders ship in two days.';
const PANEL_ACTION = 'Change address button';
const COUNT = 'Presses: 0';

// The tiles' state is their hint, which a browser on macOS gets as the
// accessible description with a touch instruction (the tree spec tests
// each platform; VoiceOver on macOS always runs on the macOS one). The
// readings are written after C05's recorded readings of the same widgets
// (docs/evidence/C05/voiceover-web.md: "Shipping Collapsed double tap to
// expand button", and open, the Cupertino tile's header and panel text
// read as one button). C06's own have not been recorded yet.
const CLOSED_TILE = `${TITLE} Collapsed double tap to expand button`;
const OPEN_TILE = `${TITLE} Expanded double tap to collapse button`;

// slug -> every stop after the "Example" heading, to the end of the screen,
// closed and after the control has been opened.
const tile = {
  closed: [CLOSED_TILE, COUNT],
  open: [OPEN_TILE, PANEL_TEXT, PANEL_ACTION, COUNT],
};
const EXAMPLES = {
  'good-material': tile,
  // The defect, no button role, is on Android and iOS; on the web it is
  // read as good-material.
  'bad-expansion-tile': tile,
  // No state in any words: a button named by its label (the tree spec).
  'bad-expand-icon': {
    closed: [`${TITLE} button`, COUNT],
    open: [`${TITLE} button`, PANEL_TEXT, PANEL_ACTION, COUNT],
  },
  // The defect is the keyboard (the tree spec). Open, the control and its
  // panel's text are one button (FL-265); its panel has no button.
  'bad-cupertino-expansion-tile': {
    closed: [CLOSED_TILE, COUNT],
    open: [`${TITLE} ${PANEL_TEXT} Expanded double tap to collapse button`, COUNT],
  },
};

/**
 * walkToEnd (vo_helpers.js), with its first click made with the mouse at
 * the "Example" heading's place instead of Playwright's checked click on
 * the heading, as C05's spec does, for the same reason: once a
 * `CupertinoExpansionTile` has been opened, an empty element the size of
 * the view lies over the page and takes pointer events (FL-029, as C05
 * found; asserted in the tree spec, "the empty element over the page"),
 * and a checked click on the heading is refused. The click only brings
 * keyboard focus into the page; focus is then put on Back as walkToEnd
 * does, and the walk is walkToEnd's, step for step.
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
        console.log(`C06VO ${browserName} ${label}-walk-${walk} | ${shown} (${judged.verdict}: ${judged.reason})`);
      },
    });
  expect(verdict, `${label}, walk ${walks}: ${reason}`).toBe('complete');
}

/** Loads the example `slug` and waits for its count. */
async function load(page, slug) {
  await page.goto(`/#/t/C06/${slug}`, { waitUntil: 'load' });
  await expect(page.locator(`[flt-semantics-identifier="c06-${slug}-count"]`)).toBeVisible();
  await page.waitForTimeout(600);
}

for (const [slug, { closed, open }] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await load(page, slug);
    await read(page, voiceOver, browserName, slug, closed, screenStops(slug));
    // bad-cupertino-expansion-tile: its open walk is made on a fresh load,
    // so that it is the first walk on that page, as C05's spec does after
    // its WebKit probe (docs/evidence/probes/c05/voiceover-web-round3-probe.md.txt:
    // second walks on one load of that tile failed to walk the page). It
    // changes only where the walk starts: the walk is judged as every walk
    // is, and a wrong reading fails for good.
    if (slug === 'bad-cupertino-expansion-tile') {
      await page.goto('about:blank');
      await load(page, slug);
    }
    await page.getByRole('button', { name: TITLE, exact: true }).click();
    // The panel must be there before the walk, so a reading from before
    // the click cannot pass: the open walk expects the panel's text.
    await expect(page.getByText(PANEL_TEXT).or(page.getByRole('button', { name: new RegExp(PANEL_TEXT) }))).toHaveCount(1);
    await read(page, voiceOver, browserName, `${slug}-open`, open, screenStops(slug),
      { clickAtPoint: slug === 'bad-cupertino-expansion-tile' });
  });
}
