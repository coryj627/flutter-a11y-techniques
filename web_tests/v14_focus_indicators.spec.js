// L3 for V14 Focus indicators on web: what Flutter draws when the keyboard
// moves focus, read from Chromium's screenshots, and where a focused control
// is against what is drawn over it. Spec: docs/specs/V14-focus-indicators.md.
// Runs against the release build in build/web.
//
// Flutter draws the page on a canvas, and the elements the browser focuses
// are transparent (the engine sets `filter: opacity(0%)` on them), so a CSS
// outline is never what is seen. The indicator is measured from pixels: a
// screenshot before Tab reaches a control and two after, 700 ms apart once
// the drawing has stopped changing; the pixels round the control that
// changed in both and agree are what focus drew. Its contrast is worked out
// from the colours in the screenshots, never from the theme.
import zlib from 'node:zlib';
import { test, expect } from '@playwright/test';
import { byId, technique } from './support/techniques.js';

// Flutter attaches its keyboard handling a moment after the page loads.
const { open, expectCount } = technique('V14', { countLabel: 'Last used', settle: 800 });

const control = (page, slug, c) => byId(page, `v14-${slug}-${c}`);
const back = (page) => page.getByRole('button', { name: 'Back' });

// The controls of each example outside a scrolling list, in Tab order.
const CONTROLS = {
  'good-material': [['alerts', 'Weather alerts', 'checkbox'], ['save', 'Save', 'button']],
  'good-cupertino': [['alerts', 'Weather alerts', 'switch'], ['save', 'Save', 'button']],
  'good-widgets': [['trail', 'Ridge trail', 'button']],
  'bad-indicator-removed': [['save', 'Save', 'button']],
  'bad-checkbox-halo': [['alerts', 'Weather alerts', 'checkbox']],
  'bad-cupertino-ring': [['save', 'Save', 'button']],
};
const TRAILS = ['Ridge trail', 'Lake loop', 'Summit path', 'Forest walk', 'River run', 'Canyon climb'];

/** The test identifier of the element with DOM focus, "back", or "none". */
async function stop(page, slug) {
  return page.evaluate((prefix) => {
    const e = document.activeElement;
    if (!e || e === document.body) return 'none';
    const id = e.closest('[flt-semantics-identifier]')?.getAttribute('flt-semantics-identifier') ?? '';
    if (id.startsWith(prefix)) return id.slice(prefix.length);
    if ((e.getAttribute('aria-label') ?? e.textContent ?? '').trim() === 'Back') return 'back';
    return `other: ${id} ${e.getAttribute('aria-label') ?? ''}`;
  }, `v14-${slug}-`);
}

/** Presses Tab and waits, at most a second, for DOM focus to move. */
async function tab(page) {
  const before = await page.evaluateHandle(() => document.activeElement);
  await page.keyboard.press('Tab');
  // Flutter moves DOM focus on the next frame.
  await page.waitForFunction((e) => document.activeElement !== e, before, { timeout: 1000 }).catch(() => {});
  await page.waitForTimeout(100);
}

// --- Pixels -------------------------------------------------------------

/** Decodes a PNG of 8-bit RGB or RGBA, not interlaced, as Chromium writes. */
function decodePng(buffer) {
  let pos = 8;
  let width, height, channels;
  const idat = [];
  while (pos < buffer.length) {
    const length = buffer.readUInt32BE(pos);
    const type = buffer.toString('ascii', pos + 4, pos + 8);
    const body = buffer.subarray(pos + 8, pos + 8 + length);
    pos += 12 + length;
    if (type === 'IHDR') {
      width = body.readUInt32BE(0);
      height = body.readUInt32BE(4);
      if (body[8] !== 8 || body[12] !== 0) throw new Error('unsupported PNG');
      channels = { 2: 3, 6: 4 }[body[9]];
    } else if (type === 'IDAT') idat.push(body);
    else if (type === 'IEND') break;
  }
  const raw = zlib.inflateSync(Buffer.concat(idat));
  const stride = width * channels;
  const out = new Uint32Array(width * height);
  let prev = new Uint8Array(stride);
  for (let y = 0; y < height; y++) {
    const filter = raw[y * (stride + 1)];
    const line = Uint8Array.from(raw.subarray(y * (stride + 1) + 1, (y + 1) * (stride + 1)));
    for (let x = 0; x < stride; x++) {
      const a = x >= channels ? line[x - channels] : 0;
      const b = prev[x];
      const c = x >= channels ? prev[x - channels] : 0;
      let p = 0;
      if (filter === 1) p = a;
      else if (filter === 2) p = b;
      else if (filter === 3) p = (a + b) >> 1;
      else if (filter === 4) {
        const q = a + b - c;
        const pa = Math.abs(q - a), pb = Math.abs(q - b), pc = Math.abs(q - c);
        p = pa <= pb && pa <= pc ? a : pb <= pc ? b : c;
      }
      line[x] = (line[x] + p) & 255;
    }
    for (let x = 0; x < width; x++) {
      const o = x * channels;
      out[y * width + x] = (line[o] << 16) | (line[o + 1] << 8) | line[o + 2];
    }
    prev = line;
  }
  return { width, height, at: (x, y) => out[y * width + x] };
}

const shot = async (page) => decodePng(await page.screenshot());

const channelDiff = (a, b) => Math.max(
  Math.abs(((a >> 16) & 255) - ((b >> 16) & 255)),
  Math.abs(((a >> 8) & 255) - ((b >> 8) & 255)),
  Math.abs((a & 255) - (b & 255)),
);
const lin = (v) => { const s = v / 255; return s <= 0.04045 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4; };
const luminance = (c) => 0.2126 * lin((c >> 16) & 255) + 0.7152 * lin((c >> 8) & 255) + 0.0722 * lin(c & 255);
/** WCAG's contrast ratio between two colours. */
const ratio = (a, b) => {
  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x);
  return (hi + 0.05) / (lo + 0.05);
};
const hex = (c) => `#${c.toString(16).padStart(6, '0').toUpperCase()}`;
const THRESHOLD = 12;

/**
 * What focus drew in `region` ({x, y, width, height} in pixels), given the
 * screenshot before focus `u` and two after, `f1` and `f2`. Changed pixels
 * differ from `u` in both and agree; a mark is a changed pixel drawn where
 * the page was, or 3:1 or more from the colour it replaced (a tinted fill
 * or a border a shade darker is not one); strong marks are 3:1 or more
 * against the page, whose colour is the commonest along the region's edge.
 */
function compare(u, f1, f2, region) {
  const l = Math.max(0, Math.floor(region.x)), t = Math.max(0, Math.floor(region.y));
  const r = Math.min(u.width, Math.ceil(region.x + region.width));
  const b = Math.min(u.height, Math.ceil(region.y + region.height));
  const edge = new Map();
  for (let x = l; x < r; x++) for (const y of [t, t + 1, b - 2, b - 1]) edge.set(u.at(x, y), (edge.get(u.at(x, y)) ?? 0) + 1);
  const page = [...edge.entries()].sort((p, q) => q[1] - p[1])[0][0];
  let changed = 0, unstable = 0, marks = 0, strong = 0;
  const colours = new Map();
  const strongColours = new Map();
  for (let y = t; y < b; y++) {
    for (let x = l; x < r; x++) {
      const a = u.at(x, y), p = f1.at(x, y), q = f2.at(x, y);
      const d1 = channelDiff(a, p) > THRESHOLD, d2 = channelDiff(a, q) > THRESHOLD;
      if (d1 && d2 && channelDiff(p, q) <= THRESHOLD) {
        changed++;
        if (channelDiff(p, page) > THRESHOLD && (channelDiff(a, page) <= THRESHOLD || ratio(p, a) >= 3)) {
          marks++;
          colours.set(p, (colours.get(p) ?? 0) + 1);
          if (ratio(p, page) >= 3) {
            strong++;
            strongColours.set(p, (strongColours.get(p) ?? 0) + 1);
          }
        }
      } else if (d1 || d2) unstable++;
    }
  }
  const top = [...colours.entries()].sort((p, q) => q[1] - p[1])[0];
  const strongTop = [...strongColours.entries()].sort((p, q) => q[1] - p[1])[0];
  const colour = top?.[0];
  const result = {
    changed, unstable, marks, strong, page,
    colour, ratio: colour === undefined ? 1 : ratio(colour, page),
    strongColour: strongTop?.[0],
  };
  result.text = `changed ${changed}, unstable ${unstable}, marks ${marks}, page ${hex(page)}, `
    + `commonest mark ${colour === undefined ? 'none' : hex(colour)} (${result.ratio.toFixed(2)}), `
    + `3:1 or more: ${strong}${strongTop ? ` (${hex(strongTop[0])}, ${ratio(strongTop[0], page).toFixed(2)})` : ''}`;
  return result;
}

const inflate = (box, by = 8) => ({ x: box.x - by, y: box.y - by, width: box.width + 2 * by, height: box.height + 2 * by });

/**
 * Waits, at most 3 s, until the screen stops changing in `region`: two
 * screenshots 300 ms apart that differ in no more than 1% of its pixels
 * (a caret may blink). Returns the last.
 */
async function settled(page, region) {
  let last = await shot(page);
  for (let i = 0; i < 10; i++) {
    await page.waitForTimeout(300);
    const next = await shot(page);
    const c = compare(last, next, next, region);
    last = next;
    if (c.changed + c.unstable <= region.width * region.height * 0.01) return last;
  }
  throw new Error('the screen did not settle');
}

/**
 * Presses Tab, expects the stop to be `c`, waits for the drawing to settle,
 * and measures what changed round `locator` against `before`.
 */
async function tabAndMeasure(page, slug, c, locator, before) {
  await tab(page);
  expect(await stop(page, slug), `Tab stops on ${c}`).toBe(c);
  const region = inflate(await locator.boundingBox());
  const f1 = await settled(page, region);
  await page.waitForTimeout(700);
  const f2 = await shot(page);
  return compare(before, f1, f2, region);
}

/** Tabs from the top of the screen until the stop before `c`. */
async function tabToBefore(page, slug, c) {
  const order = ['back', ...CONTROLS[slug].map(([x]) => x)];
  const target = order[order.indexOf(c) - 1];
  // At least one Tab: when the page opens, DOM focus can already be on
  // Back while Flutter's focus is nowhere; the first Tab puts it there.
  for (let i = 0; i < 8; i++) {
    await tab(page);
    if ((await stop(page, slug)) === target) break;
  }
  expect(await stop(page, slug)).toBe(target);
}

// --- Tests --------------------------------------------------------------

test('the contrast ratio is WCAG\'s', () => {
  expect(ratio(0xffffff, 0x000000)).toBeCloseTo(21, 3);
  expect(ratio(0x767676, 0xffffff)).toBeCloseTo(4.54, 2);
});

test.describe('names, roles, and keys', () => {
  for (const [slug, controls] of Object.entries(CONTROLS)) {
    test(`${slug}: each control has its role and name, takes focus in order after Back, and Space uses it`, async ({ page }) => {
      await open(page, slug);
      for (const [c, name, role] of controls) {
        await expect(control(page, slug, c)).toHaveRole(role);
        await expect(control(page, slug, c)).toHaveAccessibleName(name);
      }
      await tab(page);
      expect(await stop(page, slug)).toBe('back');
      for (const [c, name] of controls) {
        await tab(page);
        expect(await stop(page, slug)).toBe(c);
        await page.keyboard.press('Space');
        await expectCount(page, slug, name);
      }
    });
  }

  for (const slug of ['good-notice-below', 'bad-notice-over-list']) {
    test(`${slug}: six trail buttons, reached in order after Back`, async ({ page }) => {
      await open(page, slug);
      await tab(page);
      expect(await stop(page, slug)).toBe('back');
      for (let i = 1; i <= 6; i++) {
        await expect(control(page, slug, `trail${i}`)).toHaveRole('button');
        await expect(control(page, slug, `trail${i}`)).toHaveAccessibleName(TRAILS[i - 1]);
        await tab(page);
        expect(await stop(page, slug)).toBe(`trail${i}`);
      }
      await page.keyboard.press('Space');
      await expectCount(page, slug, 'Canyon climb');
    });
  }
});

test.describe('focus indicators, measured from the pixels', () => {
  test('the browser\'s own outline is not what is seen: the focused element is transparent', async ({ page }) => {
    await open(page, 'good-widgets');
    await tab(page);
    await tab(page);
    expect(await stop(page, 'good-widgets')).toBe('trail');
    // Some ancestor of the focused element, or the element, has an opacity
    // filter of 0%, so whatever outline the browser draws for it is not
    // painted.
    const hidden = await page.evaluate(() => {
      for (let e = document.activeElement; e; e = e.parentElement) {
        if (getComputedStyle(e).filter.includes('opacity(0)')) return true;
      }
      return false;
    });
    expect(hidden).toBe(true);
  });

  for (const slug of ['good-material', 'good-cupertino', 'good-widgets']) {
    test(`${slug}: each control draws an indicator of 3:1 or more against the page, which goes when focus moves on`, async ({ page }) => {
      await open(page, slug);
      const controls = CONTROLS[slug];
      await tabToBefore(page, slug, controls[0][0]);
      let lastBefore;
      for (const [c] of controls) {
        const locator = control(page, slug, c);
        lastBefore = await settled(page, inflate(await locator.boundingBox()));
        const ind = await tabAndMeasure(page, slug, c, locator, lastBefore);
        console.log(`V14 web ${slug} ${c}: ${ind.text}`);
        expect(ind.strong, `${c}: ${ind.text}`).toBeGreaterThan(150);
      }
      // Off again: Tab on, and the last control's region is as it was.
      await tab(page);
      const last = control(page, slug, controls.at(-1)[0]);
      expect(await stop(page, slug)).not.toBe(controls.at(-1)[0]);
      const region = inflate(await last.boundingBox());
      const off = await settled(page, region);
      const gone = compare(lastBefore, off, off, region);
      expect(gone.changed, `after focus left: ${gone.text}`).toBe(0);
    });
  }

  test('bad-indicator-removed: Tab to Save changes no pixel; Tab to Back, the positive control, does', async ({ page }) => {
    const slug = 'bad-indicator-removed';
    await open(page, slug);
    const save = control(page, slug, 'save');
    const before = await settled(page, inflate(await save.boundingBox()));
    const onBack = await tabAndMeasure(page, slug, 'back', back(page), before);
    console.log(`V14 web ${slug} back: ${onBack.text}`);
    expect(onBack.marks, onBack.text).toBeGreaterThan(100);
    const onSave = await tabAndMeasure(page, slug, 'save', save, before);
    console.log(`V14 web ${slug} save: ${onSave.text}`);
    // Written to fail if a FilledButton starts to show focus some other way.
    expect(onSave.changed, onSave.text).toBe(0);
    expect(onSave.unstable, onSave.text).toBe(0);
    await page.keyboard.press('Space');
    await expectCount(page, slug, 'Save');
  });

  test('bad-checkbox-halo: the halo is drawn outside the box and is under 3:1 against the page', async ({ page }) => {
    const slug = 'bad-checkbox-halo';
    await open(page, slug);
    const locator = control(page, slug, 'alerts');
    const before = await settled(page, inflate(await locator.boundingBox()));
    await tabToBefore(page, slug, 'alerts');
    const ind = await tabAndMeasure(page, slug, 'alerts', locator, before);
    console.log(`V14 web ${slug}: ${ind.text}`);
    expect(ind.marks, ind.text).toBeGreaterThan(500);
    // Written to fail if Flutter makes the halo stand out.
    expect(ind.ratio, ind.text).toBeLessThan(1.5);
    expect(ind.strong, ind.text).toBeLessThan(ind.marks * 0.02);
  });

  test('bad-cupertino-ring: in light mode the ring is under 3:1 against the page', async ({ page }) => {
    const slug = 'bad-cupertino-ring';
    await open(page, slug);
    const locator = control(page, slug, 'save');
    const before = await settled(page, inflate(await locator.boundingBox()));
    await tabToBefore(page, slug, 'save');
    const ind = await tabAndMeasure(page, slug, 'save', locator, before);
    console.log(`V14 web ${slug}: ${ind.text}`);
    expect(ind.marks, ind.text).toBeGreaterThan(500);
    // Written to fail if Flutter darkens the ring.
    expect(ind.ratio, ind.text).toBeLessThan(3);
    expect(ind.strong, ind.text).toBeLessThan(ind.marks * 0.02);
  });
});

test.describe('the focused trail and the notice (2.4.11)', () => {
  /** How much of trail `i` is in sight: inside the page's view and the box, and not under the notice. */
  async function visible(page, slug, i) {
    const t = await control(page, slug, `trail${i}`).boundingBox();
    const box = await byId(page, `v14-${slug}-list`).boundingBox();
    const notice = await byId(page, `v14-${slug}-notice`).boundingBox();
    const view = page.viewportSize();
    const top = Math.max(t.y, box.y, 0);
    const bottom = Math.min(t.y + t.height, box.y + box.height, view.height);
    if (bottom <= top) return 0;
    const hidden = Math.max(0, Math.min(bottom, notice.y + notice.height) - Math.max(top, notice.y));
    return (bottom - top - hidden) / t.height;
  }

  test('good-notice-below: every trail Tab reaches is wholly in sight', async ({ page }) => {
    const slug = 'good-notice-below';
    await open(page, slug);
    await tab(page);
    for (let i = 1; i <= 6; i++) {
      await tab(page);
      expect(await stop(page, slug)).toBe(`trail${i}`);
      expect(await visible(page, slug, i), `trail${i}`).toBeCloseTo(1, 2);
    }
  });

  test('bad-notice-over-list: Tab reaches trails 4 to 6 entirely under the notice; trails 1 and 2 are in sight', async ({ page }) => {
    const slug = 'bad-notice-over-list';
    await open(page, slug);
    await tab(page);
    const seen = [];
    for (let i = 1; i <= 6; i++) {
      await tab(page);
      expect(await stop(page, slug)).toBe(`trail${i}`);
      seen.push(await visible(page, slug, i));
    }
    console.log(`V14 web ${slug} visible: ${seen.map((v) => v.toFixed(2)).join(' ')}`);
    // The positive control, through the same measure.
    expect(seen[0]).toBeCloseTo(1, 2);
    expect(seen[1]).toBeCloseTo(1, 2);
    // Written to fail if Flutter starts to scroll a focused control out
    // from under what is drawn over its view.
    for (const i of [4, 5, 6]) expect(seen[i - 1], `trail${i}`).toBe(0);
  });
});
