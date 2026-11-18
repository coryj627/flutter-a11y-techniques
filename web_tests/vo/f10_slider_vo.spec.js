// L4 on web for F10 Slider: what VoiceOver on macOS speaks for each
// example. Needs Guidepup's setup and macOS automation permissions on the
// machine. Run through `python3 tool/voiceover_web.py F10`, which also
// writes the transcript.
import { appendFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { activateBrowser, lastPhrase, walkFromBack } from './vo_helpers.js';

const EXAMPLE = 'heading level 2 Example';
// The change count is the last element of every example.
const COUNT = 'Changes: 0';

// slug -> everything VoiceOver speaks after the "Example" heading and before
// the change count, in order, one entry for each stop. The slider has no
// name of its own (FL-028): the label is read as a group around it.
const volume = ['Volume group', '40% dimmed slider', 'end of Volume group'];
const EXAMPLES = {
  'good-material': volume,
  'good-cupertino': [...volume, 'Volume down button', 'Volume up button'],
  'good-custom': volume,
  'good-value-text': ['Rating group', '4 out of 10 dimmed slider', 'end of Rating group'],
  // Bad examples: the defect must be audible where it can be.
  // The text is read on its own, and no group names the slider.
  'bad-unlabelled': ['Volume', '40% dimmed slider'],
  // The number above the thumb is part of the name.
  'bad-indicator-label': ['Volume 4 group', '40% dimmed slider', 'end of Volume 4 group'],
  'bad-percent-value': ['Rating group', '40% dimmed slider', 'end of Rating group'],
  // The keyboard and pointer defects are not heard.
  'bad-no-keyboard': volume,
  'bad-drag-only': volume,
};

// The examples with a Material Slider, which puts an empty element over the
// whole page (FL-029). In Playwright's WebKit build VoiceOver reads only
// the page's web area after the screen title on every one of these
// screens, and walks the others normally; in Chromium all of them are
// walked.
const MATERIAL = ['good-material', 'good-value-text', 'bad-unlabelled', 'bad-indicator-label', 'bad-percent-value'];

// Where this run's notes go: how many pointer events the page had during
// each walk, every change to the slider's input's `disabled` property, and
// whether it was disabled straight after the walk. Not speech, so not in
// the transcript; a copy of a run's notes is kept in
// docs/evidence/probes/f10/voiceover-web-notes.txt.
const here = dirname(fileURLToPath(import.meta.url));
const NOTES = join(here, '..', 'test-results', 'f10-vo-notes.txt');
function note(line) {
  mkdirSync(dirname(NOTES), { recursive: true });
  appendFileSync(NOTES, `${new Date().toISOString()} ${line}\n`);
}

/**
 * Records, from before the walk, every pointer event the page receives and
 * every change to the `disabled` property of the slider's input: the web
 * engine disables it for half a second after any pointer event
 * (incrementable.dart).
 */
const watch = (page) =>
  page.evaluate(() => {
    window.__f10 = { pointer: 0, disabled: [] };
    for (const type of ['pointerdown', 'pointermove', 'mousemove', 'mousedown', 'wheel']) {
      window.addEventListener(type, () => window.__f10.pointer++, true);
    }
    const input = document.querySelector('input[type="range"]');
    if (input) {
      new MutationObserver(() => window.__f10.disabled.push(input.disabled)).observe(input, {
        attributes: true,
        attributeFilter: ['disabled'],
      });
      window.__f10.disabledAtStart = input.disabled;
    }
  });

const seen = (page) =>
  page.evaluate(() => ({ ...window.__f10, disabledNow: document.querySelector('input[type="range"]')?.disabled }));

/**
 * Brings the browser forward, clicks in the page, focuses the Back button,
 * and waits up to five seconds for VoiceOver to read it. True only if
 * VoiceOver's last phrase then names the Back button, which shows that
 * speech capture is working.
 */
async function readsBackOnFocus(page, browserName) {
  // As the walk's start does: bring the browser to the front, then a real
  // click in the page, at a position, since setting focus from script
  // alone may leave keyboard focus outside the page.
  await activateBrowser(browserName);
  await page.bringToFront();
  const box = await page.getByRole('heading', { name: 'Example', level: 2 }).boundingBox();
  await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
  await page.getByRole('button', { name: 'Back' }).focus();
  const heard = [];
  for (let i = 0; i < 20; i++) {
    await page.waitForTimeout(250);
    const phrase = await lastPhrase();
    if (phrase !== heard[heard.length - 1]) heard.push(phrase);
    // Chromium reads "Back button"; WebKit, coming back to its window,
    // reads the window's title and then "Back button has keyboard focus".
    if (/^Back\b|\bBack button has keyboard focus$/.test(phrase)) return true;
  }
  note(`${browserName} Back not read; heard ${JSON.stringify(heard)}`);
  return false;
}

for (const [slug, expected] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/F10/${slug}`, { waitUntil: 'load' });
    await expect(page.locator(`[flt-semantics-identifier="f10-${slug}-count"]`)).toBeVisible();
    await watch(page);
    if (browserName === 'webkit') {
      // In WebKit the walk sometimes began with VoiceOver's cursor outside
      // the page (an empty first phrase, most often on the first WebKit
      // walk of a run). Requiring VoiceOver to read Back once first puts
      // it in the page and shows capture is live before the walk.
      expect(await readsBackOnFocus(page, browserName), `${slug}: VoiceOver read Back before the walk`).toBe(true);
    }
    // A Material Slider puts an empty element over the page (FL-029), so
    // the walk's first click is made with the mouse at a position.
    const spoken = await walkFromBack(page, voiceOver, browserName, (p) => p === COUNT, 16, true);
    console.log(`F10VO ${browserName} ${slug} | ${spoken.join(' / ')}`);
    const watched = await seen(page);
    note(`${browserName} ${slug} ${JSON.stringify(watched)}`);
    // FL-127: the page had pointer events during the walk. The counts are
    // kept in the notes, not asserted.
    expect(watched.pointer, `${slug}: pointer events during the walk`).toBeGreaterThan(0);
    const start = spoken.indexOf(EXAMPLE);
    if (browserName === 'webkit' && MATERIAL.includes(slug)) {
      // What was seen on every one of these walks: VoiceOver read Back
      // (checked above), and then, moving on from it, at most the screen
      // title and after that only the page's own web area, "<document
      // title> web content", with empty phrases between, and never the
      // example. That reading is required here, at least twice, so a walk
      // that heard nothing, or heard something else, fails and is not
      // taken as the cursor leaving. The cause is not proven; the empty element is
      // the only difference found between these screens and the others.
      // Written to fail if VoiceOver starts reaching the slider here.
      const webArea = `${await page.title()} web content`;
      const after = spoken.filter((p) => p !== '');
      if (/^heading level 1 /.test(after[0] ?? '')) after.shift();
      expect(start, `${slug}: the example was not reached`).toBe(-1);
      expect(after.filter((p) => p === webArea).length, `${slug}: "${webArea}" was read`).toBeGreaterThanOrEqual(2);
      expect(after.filter((p) => p !== webArea), `${slug}: nothing else was read`).toEqual([]);
      // And capture was still live at the end: focus Back, a known element,
      // and VoiceOver must read it.
      expect(await readsBackOnFocus(page, browserName), `${slug}: VoiceOver read Back after the walk`).toBe(true);
      return;
    }
    expect(spoken[0], `${slug}: capture is working and the cursor started in the page`).toMatch(/^heading level 1 /);
    expect(start, `${slug}: reached the example`).toBeGreaterThanOrEqual(0);
    expect(spoken.slice(start + 1), slug).toEqual([...expected, COUNT]);
    // FL-127: after a walk that read the slider "dimmed", its input was
    // disabled. (After the WebKit walks that leave the page it is disabled
    // and enabled again with each burst of pointer events, and was found
    // either way, so it is not asserted there.)
    expect(watched.disabledNow, `${slug}: the slider's input was disabled after the walk`).toBe(true);
  });
}

// FL-029: the empty element over the page does not stop VoiceOver from
// pressing the control beside a slider. Back is pressed with VoiceOver's
// own command and the app must go back. Chromium only: in WebKit the
// cursor does not stay in the page on this screen.
test('voiceover presses Back beside a Material slider', async ({ page, voiceOver, browserName }) => {
  test.skip(browserName !== 'chromium', 'VoiceOver leaves the page on this screen in WebKit');
  await page.goto('/#/t/F10/good-material', { waitUntil: 'load' });
  await expect(page.locator('[flt-semantics-identifier="f10-good-material-count"]')).toBeVisible();
  await walkFromBack(page, voiceOver, browserName, () => true, 1, true);
  await voiceOver.previous();
  await page.waitForTimeout(800);
  const onBack = await lastPhrase();
  note(`${browserName} press: on "${onBack}"`);
  expect(onBack).toMatch(/^Back/);
  await voiceOver.act();
  await expect(page).not.toHaveURL(/good-material/, { timeout: 5000 });
});

// A control, in plain HTML: the shape Flutter gives a slider (a labelled
// element around an unlabelled range input with a stand-in range and a
// value text), enabled and disabled, and a native labelled range input.
// It shows what makes VoiceOver say "dimmed", and that a label on the
// input is read with the slider.
const PLAIN = {
  'flutter-shape': '<div aria-label="Volume"><input type="range" min="0" max="2" value="1" aria-valuetext="40%"></div>',
  'flutter-shape-disabled': '<div aria-label="Volume"><input type="range" min="0" max="2" value="1" aria-valuetext="40%" disabled></div>',
  'labelled-input': '<label>Volume <input type="range" min="0" max="100" value="40" aria-valuetext="40%"></label>',
};

for (const [name, html] of Object.entries(PLAIN)) {
  test(`voiceover reads plain HTML ${name}`, async ({ page, voiceOver, browserName }) => {
    await page.setContent(
      `<button>Back</button><h1>Plain ${name}</h1><h2>Example</h2>${html}<p>${COUNT}</p>`);
    const spoken = await walkFromBack(page, voiceOver, browserName, (p) => p === COUNT, 10, true);
    console.log(`F10VO ${browserName} plain-${name} | ${spoken.join(' / ')}`);
    const start = spoken.indexOf(EXAMPLE);
    expect(start, `${name}: reached the example`).toBeGreaterThanOrEqual(0);
    const slider = spoken.slice(start + 1).filter((p) => /slider/.test(p));
    expect(slider, name).toHaveLength(1);
    // The disabled input is "dimmed"; the enabled ones are not.
    if (name.endsWith('disabled')) expect(slider[0], name).toContain('dimmed');
    else expect(slider[0], name).not.toContain('dimmed');
    if (name === 'labelled-input') expect(slider[0], name).toContain('Volume');
  });
}
