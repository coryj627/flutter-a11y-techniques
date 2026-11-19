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
// changed in both and agree are what focus drew, and its contrast is taken
// against the colours next to it in the focused screenshot (compare, below),
// never from the theme.
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
  'bad-checked-checkbox': [['alerts', 'Weather alerts', 'checkbox']],
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
// Two colours are one flat colour if no channel differs by more than this.
const FLAT = 4;

/**
 * What focus drew in `region` ({x, y, width, height} in pixels), given the
 * screenshot before focus `u` and two after, `f1` and `f2`.
 *
 * A pixel has changed if it differs from `u` in both and `f1` and `f2`
 * agree. Every changed pixel is part of the indicator, whatever it
 * replaced: Understanding 1.4.11 does not compare the focused and unfocused
 * states. (What replaced what is used once, to tell a drawing that moved
 * from one that focus added to: `moved`.) The indicator is split into
 * bands, one per flat colour (pixels that share their colour with a
 * horizontal and a vertical neighbour; anti-aliased edges are left out),
 * and each band is taken against the colours adjacent to it in `f1`, read
 * across at most four pixels of anti-aliased edge. A band drawn where the
 * page was, outside the control, must contrast with the page; a band drawn
 * on the control, inside it or on its border, must contrast with every
 * colour that makes up a fifth or more of what is next to it (with the
 * page, if nothing does). The page's colour is the commonest along the
 * region's edge in `u`.
 */
function compare(u, f1, f2, region) {
  const l = Math.max(0, Math.floor(region.x)), t = Math.max(0, Math.floor(region.y));
  const r = Math.min(u.width, Math.ceil(region.x + region.width));
  const b = Math.min(u.height, Math.ceil(region.y + region.height));
  const inside = (x, y) => x >= l && x < r && y >= t && y < b;
  const edge = new Map();
  for (let x = l; x < r; x++) for (const y of [t, t + 1, b - 2, b - 1]) edge.set(u.at(x, y), (edge.get(u.at(x, y)) ?? 0) + 1);
  const page = [...edge.entries()].sort((p, q) => q[1] - p[1])[0][0];
  const same = (x, y, c) => inside(x, y) && channelDiff(f1.at(x, y), c) <= FLAT;
  const solid = (x, y) => {
    const c = f1.at(x, y);
    return (same(x - 1, y, c) || same(x + 1, y, c)) && (same(x, y - 1, c) || same(x, y + 1, c));
  };
  const across = (x, y, dx, dy, colour) => {
    while (same(x + dx, y + dy, colour)) { x += dx; y += dy; }
    for (let i = 0; i < 4; i++) {
      x += dx; y += dy;
      if (!inside(x, y)) return undefined;
      const c = f1.at(x, y);
      if (channelDiff(c, colour) > THRESHOLD && solid(x, y)) return c;
    }
    return undefined;
  };
  let changed = 0, unstable = 0;
  const groups = new Map();
  const newColours = new Map(), oldColours = new Map();
  for (let y = t; y < b; y++) {
    for (let x = l; x < r; x++) {
      const a = u.at(x, y), p = f1.at(x, y), q = f2.at(x, y);
      const d1 = channelDiff(a, p) > THRESHOLD, d2 = channelDiff(a, q) > THRESHOLD;
      if (d1 && d2 && channelDiff(p, q) <= THRESHOLD) {
        changed++;
        newColours.set(p, (newColours.get(p) ?? 0) + 1);
        oldColours.set(a, (oldColours.get(a) ?? 0) + 1);
        if (!solid(x, y)) continue;
        const onPage = channelDiff(a, page) <= THRESHOLD;
        const key = `${p}:${onPage}`;
        if (!groups.has(key)) groups.set(key, { colour: p, onPage, pixels: [] });
        groups.get(key).pixels.push([x, y]);
      } else if (d1 || d2) unstable++;
    }
  }
  const bands = [];
  let strong = 0;
  for (const { colour, onPage, pixels } of groups.values()) {
    const next = new Map();
    for (const [x, y] of pixels) {
      for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
        const c = across(x, y, dx, dy, colour);
        if (c !== undefined) next.set(c, (next.get(c) ?? 0) + 1);
      }
    }
    const total = [...next.values()].reduce((s, n) => s + n, 0);
    let against = [page];
    if (!onPage && total > 0) {
      const major = [...next.entries()].filter(([, n]) => n * 5 >= total).map(([c]) => c);
      if (major.length) against = major;
    }
    const contrast = Math.min(...against.map((c) => ratio(colour, c)));
    if (contrast >= 3) strong += pixels.length;
    bands.push({ colour, onPage, pixels: pixels.length, contrast, against });
  }
  bands.sort((p, q) => q.pixels - p.pixels);
  let swapped = 0;
  for (const [c, n] of newColours) swapped += Math.min(n, oldColours.get(c) ?? 0);
  const result = {
    changed, unstable, swapped, indicator: changed, strong, page, bands,
    // The drawing moved rather than focus adding to it: half or more of the
    // colours the changed pixels took were there before, among them.
    moved: changed > 0 && swapped * 2 >= changed,
    ratio: bands.length ? bands[0].contrast : 1,
  };
  const band = (d) => `${d.pixels} px ${hex(d.colour)} ${d.onPage ? 'on the page' : 'on the control'} ${d.contrast.toFixed(2)} against ${d.against.map(hex).join(', ')}`;
  result.text = `changed ${changed}, unstable ${unstable}, swapped ${swapped}, indicator ${changed}, `
    + `3:1 or more: ${strong}, page ${hex(page)}; ${bands.slice(0, 3).map(band).join('; ')}`;
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
 * Presses Tab, expects the stop to be `c` and the control not to have
 * moved, waits for the drawing to settle, and measures what changed round
 * `locator` against `before`. A control that moved (scrolled into view by
 * Tab, say) would show its own drawing moved as a change, so the test fails
 * instead; and so it does if what changed is a drawing that moved.
 */
async function tabAndMeasure(page, slug, c, locator, before) {
  const where = await locator.boundingBox();
  await tab(page);
  expect(await stop(page, slug), `Tab stops on ${c}`).toBe(c);
  expect(await locator.boundingBox(), `${c} did not move`).toEqual(where);
  const region = inflate(where);
  const f1 = await settled(page, region);
  await page.waitForTimeout(700);
  const f2 = await shot(page);
  const ind = compare(before, f1, f2, region);
  expect(ind.moved, `the drawing moved: ${ind.text}`).toBe(false);
  return ind;
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

// The measure itself, on pictures made up for the purpose, among them the
// pass and fail figures of Understanding 1.4.11's section on focus
// indicators: a blue button (#4189B9) on a white page.
test.describe('the measure', () => {
  const WHITE = 0xffffff, BLUE = 0x4189b9, BLACK = 0x000000;
  const region = { x: 0, y: 0, width: 60, height: 60 };
  const within = (x, y, l, t, r, b) => x >= l && x < r && y >= t && y < b;
  const button = (x, y) => (within(x, y, 15, 20, 45, 40) ? BLUE : WHITE);
  const picture = (at) => ({ width: 60, height: 60, at });
  // `colour` on a band `width` wide, `gap` outside the rectangle (a
  // negative gap is inside it), and `rest` elsewhere.
  const ring = (gap, width, colour, rest) => (x, y) => {
    const outer = within(x, y, 15 - gap - width, 20 - gap - width, 45 + gap + width, 40 + gap + width);
    const inner = within(x, y, 15 - gap, 20 - gap, 45 + gap, 40 + gap);
    return outer && !inner ? colour : rest(x, y);
  };
  const focus = (at) => compare(picture(button), picture(at), picture(at), region);

  test('an inner yellow ring on the blue button passes (3.55:1 against the blue)', () => {
    const ind = focus(ring(-6, 3, 0xffff00, button));
    expect(ind.bands).toHaveLength(1);
    expect(ind.bands[0].onPage).toBe(false);
    expect(ind.ratio).toBeCloseTo(3.55, 1);
    expect(ind.strong).toBe(ind.indicator);
  });

  test('an outer yellow ring on the white page fails (1.07:1)', () => {
    const ind = focus(ring(2, 3, 0xffff00, button));
    expect(ind.bands[0].onPage).toBe(true);
    expect(ind.ratio).toBeLessThan(1.1);
    expect(ind.strong).toBe(0);
  });

  test('an outer green ring on the white page passes (5.14:1)', () => {
    const ind = focus(ring(2, 3, 0x008000, button));
    expect(ind.ratio).toBeCloseTo(5.14, 1);
    expect(ind.strong).toBe(ind.indicator);
  });

  test('the button\'s edge turning green (#4B933A) fails: it is on the control and does not contrast with the blue inside', () => {
    const ind = focus(ring(-3, 3, 0x4b933a, button));
    expect(ind.bands[0].onPage).toBe(false);
    expect(ind.strong).toBe(0);
  });

  test('with a black border, an inner white border passes and an inner dark green one fails', () => {
    const bordered = ring(-2, 2, BLACK, button);
    for (const [colour, passes] of [[WHITE, true], [0x008000, false]]) {
      const f = picture(ring(-4, 2, colour, bordered));
      const ind = compare(picture(bordered), f, f, region);
      expect(ind.strong === ind.indicator && ind.indicator > 0, `${hex(colour)}: ${ind.text}`).toBe(passes);
    }
  });

  test('artwork that moves is not an indicator: the drawing moved', () => {
    const at = (dx) => (x, y) => (within(x, y, 20 + dx, 20, 30 + dx, 30) ? BLACK : WHITE);
    const moved = picture(at(4));
    const ind = compare(picture(at(0)), moved, moved, region);
    // The square's new edge is black on the page, 21:1: without this check
    // it would pass as a ring.
    expect(ind.strong).toBeGreaterThan(0);
    expect(ind.moved).toBe(true);
  });

  test('nothing drawn is no indicator', () => {
    const ind = focus(button);
    expect(ind.changed).toBe(0);
    expect(ind.strong).toBe(0);
  });

  test('a mark in one capture only (a blinking caret) is unstable, not an indicator', () => {
    const caret = picture((x, y) => (x === 30 && y >= 22 && y < 38 ? BLACK : button(x, y)));
    const ind = compare(picture(button), caret, picture(button), region);
    expect(ind.changed).toBe(0);
    expect(ind.unstable).toBeGreaterThan(0);
  });
});


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
    expect(onBack.indicator, onBack.text).toBeGreaterThan(100);
    const onSave = await tabAndMeasure(page, slug, 'save', save, before);
    console.log(`V14 web ${slug} save: ${onSave.text}`);
    // Written to fail if a FilledButton starts to show focus some other way.
    expect(onSave.changed, onSave.text).toBe(0);
    expect(onSave.unstable, onSave.text).toBe(0);
    await page.keyboard.press('Space');
    await expectCount(page, slug, 'Save');
  });

  test('bad-checked-checkbox: the halo is drawn on the page, under 3:1 against it, and nothing else changes', async ({ page }) => {
    const slug = 'bad-checked-checkbox';
    await open(page, slug);
    const locator = control(page, slug, 'alerts');
    const before = await settled(page, inflate(await locator.boundingBox()));
    await tabToBefore(page, slug, 'alerts');
    const ind = await tabAndMeasure(page, slug, 'alerts', locator, before);
    console.log(`V14 web ${slug}: ${ind.text}`);
    expect(ind.indicator, ind.text).toBeGreaterThan(500);
    expect(ind.bands[0].onPage, ind.text).toBe(true);
    // Written to fail if Flutter makes the halo stand out, or adds anything
    // else at 3:1.
    expect(ind.ratio, ind.text).toBeLessThan(1.5);
    expect(ind.strong, ind.text).toBeLessThan(ind.indicator * 0.02);
  });

  test('bad-cupertino-ring: in light mode the ring is under 3:1 against the page', async ({ page }) => {
    const slug = 'bad-cupertino-ring';
    await open(page, slug);
    const locator = control(page, slug, 'save');
    const before = await settled(page, inflate(await locator.boundingBox()));
    await tabToBefore(page, slug, 'save');
    const ind = await tabAndMeasure(page, slug, 'save', locator, before);
    console.log(`V14 web ${slug}: ${ind.text}`);
    expect(ind.indicator, ind.text).toBeGreaterThan(500);
    expect(ind.bands[0].onPage, ind.text).toBe(true);
    // Written to fail if Flutter darkens the ring, or adds anything else
    // at 3:1.
    expect(ind.ratio, ind.text).toBeLessThan(3);
    expect(ind.strong, ind.text).toBeLessThan(ind.indicator * 0.02);
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
