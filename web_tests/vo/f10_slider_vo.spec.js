// L4 on web for F10 Slider: what VoiceOver on macOS speaks for each
// example. Needs Guidepup's setup and macOS automation permissions on the
// machine. Run through `python3 tool/voiceover_web.py F10`, which also
// writes the transcript.
import { appendFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { lastPhrase, walkFromBack } from './vo_helpers.js';

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
// whole page (FL-029). In Playwright's WebKit build VoiceOver's cursor
// leaves the page after the screen title on every one of these screens,
// and walks the others normally; in Chromium all of them are walked.
const MATERIAL = ['good-material', 'good-value-text', 'bad-unlabelled', 'bad-indicator-label', 'bad-percent-value'];

// Where this run's notes go: whether the slider's input was disabled while
// VoiceOver read it, and how many pointer events the page had. Not speech,
// so not in the transcript.
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

for (const [slug, expected] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/F10/${slug}`, { waitUntil: 'load' });
    await expect(page.locator(`[flt-semantics-identifier="f10-${slug}-count"]`)).toBeVisible();
    await watch(page);
    // A Material Slider puts an empty element over the page (FL-029), so
    // the walk's first click is made with the mouse at a position.
    const spoken = await walkFromBack(page, voiceOver, browserName, (p) => p === COUNT, 16, true);
    console.log(`F10VO ${browserName} ${slug} | ${spoken.join(' / ')}`);
    note(`${browserName} ${slug} ${JSON.stringify(await seen(page))}`);
    expect(spoken[0], `${slug}: capture is working and the cursor started in the page`).toMatch(/^heading level 1 /);
    const start = spoken.indexOf(EXAMPLE);
    if (browserName === 'webkit' && MATERIAL.includes(slug)) {
      // Recorded, and asserted as it is today: the cursor never reaches
      // the example. The cause is not proven; the empty element is the
      // only difference found between these screens and the others.
      // Written to fail if VoiceOver starts reaching the slider here.
      expect(start, `${slug}: the cursor left the page before the example`).toBe(-1);
      return;
    }
    expect(start, `${slug}: reached the example`).toBeGreaterThanOrEqual(0);
    expect(spoken.slice(start + 1), slug).toEqual([...expected, COUNT]);
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
