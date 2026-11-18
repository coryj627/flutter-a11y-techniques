// L3 for F10 Slider on web: what the browser's accessibility tree exposes.
// Spec: docs/specs/F10-slider.md. Runs against the release build in
// build/web.
//
// Flutter draws a slider as a `flt-semantics` element that carries the
// label, with an `<input type="range" role="slider">` inside it that takes
// focus and has the value. The wrapper is found by its identifier and the
// slider is the input inside it.
import { test, expect } from '@playwright/test';
import { byId, tabTo, technique } from './support/techniques.js';

const { open, expectCount } = technique('F10', { countLabel: 'Changes' });

const sliderId = (slug) => (/value-text|percent-value/.test(slug) ? `f10-${slug}-rating` : `f10-${slug}-volume`);
const wrapper = (page, slug) => byId(page, sliderId(slug));
const slider = (page, slug) => wrapper(page, slug).getByRole('slider');
const valueOf = (page, slug) => slider(page, slug).getAttribute('aria-valuetext');

// slug -> [the label on the wrapper (null for none), the value at the start,
// one step up, one step down, the first value, the last value].
const EXAMPLES = {
  'good-material': ['Volume', '40%', '50%', '30%', '0%', '100%'],
  'good-cupertino': ['Volume', '40%', '50%', '30%', '0%', '100%'],
  'good-custom': ['Volume', '40%', '50%', '30%', '0%', '100%'],
  'good-value-text': ['Rating', '4 out of 10', '5 out of 10', '3 out of 10', '0 out of 10', '10 out of 10'],
  'bad-unlabelled': [null, '40%', '50%', '30%', '0%', '100%'],
  'bad-indicator-label': ['Volume\n4', '40%', '50%', '30%', '0%', '100%'],
  'bad-percent-value': ['Rating', '40%', '50%', '30%', '0%', '100%'],
  'bad-no-keyboard': ['Volume', '40%', '50%', '30%', '0%', '100%'],
  'bad-drag-only': ['Volume', '40%', '50%', '30%', '0%', '100%'],
};

// The examples with a Material Slider, which adds an empty element over
// the whole screen (FL-029).
const MATERIAL = ['good-material', 'good-value-text', 'bad-unlabelled', 'bad-indicator-label', 'bad-percent-value'];

/** The empty `flt-semantics` elements the size of the whole page. */
const fullScreenEmpty = (page) =>
  page.evaluate(() =>
    [...document.querySelectorAll('flt-semantics')].filter((e) => {
      const r = e.getBoundingClientRect();
      return (
        e.childElementCount === 0 &&
        e.textContent === '' &&
        e.attributes.length === 2 && // id and style only
        r.width >= window.innerWidth - 1 &&
        r.height >= window.innerHeight - 1
      );
    }).map((e) => e.style.pointerEvents));

/** What a hit test at the centre of `locator` finds: its identifier, its role, or "empty". */
const hitAt = async (page, locator) => {
  const box = await locator.boundingBox();
  return page.evaluate(([x, y]) => {
    const e = document.elementFromPoint(x, y);
    return e.getAttribute('flt-semantics-identifier') || e.getAttribute('role') || (e.textContent === '' ? 'empty' : e.tagName);
  }, [box.x + box.width / 2, box.y + box.height / 2]);
};

/** A real mouse click at `fraction` of the width of `locator`, and `down` of its height. */
async function clickAt(page, locator, fraction, down = 0.5) {
  const box = await locator.boundingBox();
  await page.mouse.click(box.x + box.width * fraction, box.y + box.height * down);
}

/**
 * Where a pointer reaches the slider: the input spans the whole control,
 * which for the custom sliders is the text above the track as well, inside
 * a focus ring 8 pixels wide. `along` is a fraction of the track's width.
 */
async function trackPoint(page, slug, along) {
  const box = await slider(page, slug).boundingBox();
  if (/custom|no-keyboard|drag-only/.test(slug)) {
    // The drawn track is the bottom 48 pixels inside the ring.
    return [box.x + 8 + (box.width - 16) * along, box.y + box.height - 8 - 24];
  }
  return [box.x + box.width * along, box.y + box.height / 2];
}

async function clickTrack(page, slug, along) {
  const [x, y] = await trackPoint(page, slug, along);
  await page.mouse.click(x, y);
}

test.describe('every slider', () => {
  for (const [slug, [label, start, up]] of Object.entries(EXAMPLES)) {
    test(`${slug}: one slider at ${start}, named only on the element around it`, async ({ page }) => {
      await open(page, slug);
      await expect(page.getByRole('slider')).toHaveCount(1);
      if (label === null) {
        await expect(wrapper(page, slug)).not.toHaveAttribute('aria-label', /.*/);
      } else {
        await expect(wrapper(page, slug)).toHaveAttribute('aria-label', label);
      }
      // Flutter 3.47.5: the label is on the wrapper and not on the slider,
      // which has no name at all (FL-028). Written to fail when Flutter
      // copies the label onto the input, as 3.50's source does.
      await expect(slider(page, slug)).toHaveAccessibleName('');
      await expect(slider(page, slug)).not.toHaveAttribute('aria-label', /.*/);
      await expect(slider(page, slug)).toHaveAttribute('aria-valuetext', start);
      // The range is a stand-in, whatever the slider's own range is: one
      // step either side of the middle of three (FL-125).
      await expect(slider(page, slug)).toHaveAttribute('aria-valuemin', '0');
      await expect(slider(page, slug)).toHaveAttribute('aria-valuenow', '1');
      await expect(slider(page, slug)).toHaveAttribute('aria-valuemax', '2');
      await expect(slider(page, slug)).toBeEnabled();
      // A change through the input, as a screen reader's adjust command
      // makes it, moves the slider one step.
      await slider(page, slug).focus();
      await slider(page, slug).evaluate((e) => {
        e.value = '2';
        e.dispatchEvent(new Event('change'));
      });
      await expectCount(page, slug, 1);
      await expect(slider(page, slug)).toHaveAttribute('aria-valuetext', up);
      await expect(slider(page, slug)).toHaveAttribute('aria-valuenow', '2');
      await expect(slider(page, slug)).toHaveAttribute('aria-valuemax', '3');
    });
  }
});

test.describe('the keyboard', () => {
  const withKeyboard = Object.keys(EXAMPLES).filter((slug) => slug !== 'bad-no-keyboard');
  for (const slug of withKeyboard) {
    const [, start, up, down, first, last] = EXAMPLES[slug];
    test(`${slug}: Tab reaches the slider; the arrow keys move it a step, Home and End to the ends`, async ({ page }) => {
      await open(page, slug);
      expect(await tabTo(page, slider(page, slug)), 'Tab reaches the slider').toBe(true);
      let changes = 0;
      for (const [key, expected] of [
        ['ArrowRight', up], ['ArrowLeft', start], ['ArrowUp', up], ['ArrowDown', start],
        ['ArrowDown', down], ['End', last], ['Home', first],
      ]) {
        await page.keyboard.press(key);
        await expectCount(page, slug, ++changes);
        await expect(slider(page, slug), key).toHaveAttribute('aria-valuetext', expected);
      }
      expect(await slider(page, slug).evaluate((e) => e === document.activeElement), 'focus stays on the slider').toBe(true);
    });
  }

  // Flutter's focus order leaves this slider out. On the web the browser
  // then moves focus by its own order, and the slider's input element is
  // the next one it can focus after Back, so Tab does land on it here; with
  // a Flutter control after it, Tab skips it (the probe's fixtures 06 to
  // 08). The keys then reach the browser's input, which turns any change
  // into one step: End moves one step and not to the end, and there is no
  // focus ring.
  test('bad-no-keyboard: only the browser\'s own order reaches the slider, and End moves one step', async ({ page }) => {
    await open(page, 'bad-no-keyboard');
    expect(await tabTo(page, slider(page, 'bad-no-keyboard'))).toBe(true);
    await page.keyboard.press('End');
    await expectCount(page, 'bad-no-keyboard', 1);
    await expect(slider(page, 'bad-no-keyboard')).toHaveAttribute('aria-valuetext', '50%');
    await page.keyboard.press('Home');
    await expectCount(page, 'bad-no-keyboard', 2);
    await expect(slider(page, 'bad-no-keyboard')).toHaveAttribute('aria-valuetext', '40%');
  });
});

test.describe('the pointer', () => {
  for (const [slug, expected] of [
    ['good-material', '100%'], ['good-custom', '100%'], ['good-value-text', '10 out of 10'],
  ]) {
    test(`${slug}: a click near the end of the track sets the value`, async ({ page }) => {
      await open(page, slug);
      await clickTrack(page, slug, 0.99);
      await expectCount(page, slug, 1);
      await expect(slider(page, slug)).toHaveAttribute('aria-valuetext', expected);
    });
  }

  test('good-cupertino: a click on the track does nothing; the step buttons move it', async ({ page }) => {
    await open(page, 'good-cupertino');
    // A CupertinoSlider answers a drag of its thumb only (FL-121).
    await clickTrack(page, 'good-cupertino', 0.95);
    await page.waitForTimeout(500);
    await expectCount(page, 'good-cupertino', 0);
    await expect(byId(page, 'f10-good-cupertino-up')).toHaveRole('button');
    await expect(byId(page, 'f10-good-cupertino-up')).toHaveAccessibleName('Volume up');
    await expect(byId(page, 'f10-good-cupertino-down')).toHaveAccessibleName('Volume down');
    await byId(page, 'f10-good-cupertino-up').click();
    await expectCount(page, 'good-cupertino', 1);
    await expect(slider(page, 'good-cupertino')).toHaveAttribute('aria-valuetext', '50%');
    await byId(page, 'f10-good-cupertino-down').click();
    await byId(page, 'f10-good-cupertino-down').click();
    await expectCount(page, 'good-cupertino', 3);
    await expect(slider(page, 'good-cupertino')).toHaveAttribute('aria-valuetext', '30%');
  });

  test('bad-drag-only: a click on the track does nothing, and a drag moves it', async ({ page }) => {
    await open(page, 'bad-drag-only');
    await clickTrack(page, 'bad-drag-only', 0.99);
    await clickTrack(page, 'bad-drag-only', 0.01);
    await page.waitForTimeout(500);
    await expectCount(page, 'bad-drag-only', 0);
    const [x, y] = await trackPoint(page, 'bad-drag-only', 0.4);
    const [end] = await trackPoint(page, 'bad-drag-only', 0.99);
    await page.mouse.move(x, y);
    await page.mouse.down();
    await page.mouse.move(end, y, { steps: 20 });
    await page.mouse.up();
    await expect(slider(page, 'bad-drag-only')).toHaveAttribute('aria-valuetext', '100%');
  });
});

// FL-029: a Material Slider adds one empty element the size of the page,
// last in the page and on top of the other elements. Written to fail when
// Flutter stops adding it.
test.describe('the empty element over the page', () => {
  for (const slug of Object.keys(EXAMPLES)) {
    const material = MATERIAL.includes(slug);
    test(`${slug}: ${material ? 'one' : 'none'}`, async ({ page }) => {
      await open(page, slug);
      expect(await fullScreenEmpty(page)).toEqual(material ? ['auto'] : []);
      const back = page.getByRole('button', { name: 'Back' });
      // Hit testing anywhere on the page finds the empty element, not the
      // control under the pointer.
      expect(await hitAt(page, back)).toBe(material ? 'empty' : 'button');
    });
  }

  test('good-material: the Back button beside the slider still works by mouse and by a screen reader click', async ({ page }) => {
    await open(page, 'good-material');
    const back = page.getByRole('button', { name: 'Back' });
    // Playwright's own click refuses: the empty element is on top.
    await expect(back.click({ timeout: 1500 })).rejects.toThrow(/intercepts pointer events|Timeout/);
    // A real mouse click at its position reaches Flutter, which goes back.
    await clickAt(page, back, 0.5);
    await expect(page).not.toHaveURL(/good-material/);
    // A click event sent to the button element, as a screen reader's
    // activation is, works as well.
    await open(page, 'good-material');
    await back.dispatchEvent('click');
    await expect(page).not.toHaveURL(/good-material/);
  });
});

test.describe('bad examples have their defect', () => {
  test('bad-unlabelled: the text "Volume" is beside the slider and names nothing', async ({ page }) => {
    await open(page, 'bad-unlabelled');
    await expect(page.locator('flt-semantics-host').getByText('Volume', { exact: true })).toHaveCount(1);
    await expect(page.locator('[aria-label="Volume"]')).toHaveCount(0);
  });

  test('bad-indicator-label: the number is in the label, which changes at every step', async ({ page }) => {
    await open(page, 'bad-indicator-label');
    expect(await tabTo(page, slider(page, 'bad-indicator-label'))).toBe(true);
    await page.keyboard.press('ArrowRight');
    await expectCount(page, 'bad-indicator-label', 1);
    await expect(wrapper(page, 'bad-indicator-label')).toHaveAttribute('aria-label', 'Volume\n5');
  });

  test('bad-percent-value: the value is a percentage', async ({ page }) => {
    await open(page, 'bad-percent-value');
    await expect(slider(page, 'bad-percent-value')).toHaveAttribute('aria-valuetext', '40%');
  });

  test('good-value-text: the visible value is not in the page', async ({ page }) => {
    // Its counterpart: the words are the value, and the visible text with
    // the same words is left out.
    await open(page, 'good-value-text');
    await expect(page.locator('flt-semantics-host').getByText('4 out of 10')).toHaveCount(0);
    await expect(wrapper(page, 'good-value-text')).toHaveAttribute('aria-label', 'Rating');
  });
});
