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
import fs from 'node:fs';
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
// An anti-aliased edge is read across at most this many pixels.
const BLUR = 4;
// How many strong pixels a good control's indicator must have in these
// tests: about a line one pixel wide round a 40 by 40 control. The tests'
// own threshold, kept apart from the contrast measure: 1.4.11 sets no size
// (2.4.13, AAA, does).
const OUR_MINIMUM = 150;

/**
 * What focus drew in `region` ({x, y, width, height} in pixels), given the
 * screenshot before focus `u` and two after, `f1` and `f2`. The measure of
 * the V14 spec, section 6, which lists what it is known not to do; the
 * widget tests' _compare is the same, step for step.
 *
 * A pixel has changed if it differs from `u` in both and `f1` and `f2`
 * agree. Every changed pixel is part of the indicator, whatever it
 * replaced: Understanding 1.4.11 does not compare the focused and unfocused
 * states. (What replaced what is used once, to tell a drawing that moved
 * from one that focus added to: `moved`.)
 *
 * A pixel of `f1` is solid if it has a 4-neighbour of its colour (within
 * FLAT) and is not anti-aliasing: a pixel whose colour lies between the
 * colours either side of it, across or down or on a diagonal, where those
 * two differ. A one pixel line is solid. Solid changed pixels are joined
 * into bands: 4-connected, each within FLAT of the next. A band is on the
 * page if most of it was drawn where the page was before focus, and on the
 * control if not.
 *
 * Each band is taken against its neighbours, spatially: from every pixel
 * on its edge, outward, across pixels of the edge pixel's own colour and at
 * most BLUR pixels of an anti-aliased edge being crossed (each between the
 * pixels before and after it on the way), to the first solid pixel (or the
 * last of those BLUR, so that no neighbour is passed over for being
 * blurred, unless focus drew it). A walk that meets a blurred pixel that is
 * not between them, but is a blend some other way, is going along an edge,
 * not across it, and finds nothing; a blurred pixel that is a blend no way
 * is texture (a dither), and is the neighbour. A band on the control, inside it or on
 * its border, must contrast with every neighbour found, whatever it is
 * (Understanding: both adjacent colours). A band on the page, outside the
 * control, must contrast with the background: the walk goes on across the
 * rest of what focus drew, and a neighbour that was not the page before
 * focus (the control itself) is not one it must contrast with. A band's
 * contrast is its lowest against any of them (with none, against the
 * page): the least contrasting part decides. Its pixels are strong if that
 * is 3:1 or more. The page's colour is the commonest along the region's
 * top and bottom edges in `u`.
 */
function compare(u, f1, f2, region) {
  const l = Math.max(0, Math.floor(region.x)), t = Math.max(0, Math.floor(region.y));
  const r = Math.min(u.width, Math.ceil(region.x + region.width));
  const b = Math.min(u.height, Math.ceil(region.y + region.height));
  const w = r - l, h = b - t;
  const inside = (x, y) => x >= l && x < r && y >= t && y < b;
  const at = (x, y) => (y - t) * w + (x - l);
  const edge = new Map();
  for (let x = l; x < r; x++) for (const y of [t, t + 1, b - 2, b - 1]) edge.set(u.at(x, y), (edge.get(u.at(x, y)) ?? 0) + 1);
  let page = 0, most = -1;
  for (const [c, n] of edge) if (n > most || (n === most && c < page)) { page = c; most = n; }
  const isChanged = new Uint8Array(w * h);
  let changed = 0, unstable = 0;
  const newColours = new Map(), oldColours = new Map();
  for (let y = t; y < b; y++) {
    for (let x = l; x < r; x++) {
      const a = u.at(x, y), p = f1.at(x, y), q = f2.at(x, y);
      const d1 = channelDiff(a, p) > THRESHOLD, d2 = channelDiff(a, q) > THRESHOLD;
      if (d1 && d2 && channelDiff(p, q) <= THRESHOLD) {
        changed++;
        isChanged[at(x, y)] = 1;
        newColours.set(p, (newColours.get(p) ?? 0) + 1);
        oldColours.set(a, (oldColours.get(a) ?? 0) + 1);
      } else if (d1 || d2) unstable++;
    }
  }
  const same = (x, y, c) => inside(x, y) && channelDiff(f1.at(x, y), c) <= FLAT;
  const between = (c, a, z) => [16, 8, 0].every((s) => {
    const v = (c >> s) & 255, p = (a >> s) & 255, q = (z >> s) & 255;
    return v >= Math.min(p, q) - FLAT && v <= Math.max(p, q) + FLAT;
  });
  // Whether (x, y) lies between the pixels either side of it along
  // (dx, dy): a pixel of an anti-aliased edge crossed that way.
  const blendAlong = (x, y, dx, dy) => {
    if (!inside(x - dx, y - dy) || !inside(x + dx, y + dy)) return false;
    const c = f1.at(x, y), a = f1.at(x - dx, y - dy), z = f1.at(x + dx, y + dy);
    return channelDiff(a, z) > THRESHOLD && channelDiff(c, a) > FLAT && channelDiff(c, z) > FLAT && between(c, a, z);
  };
  const blend = (x, y) => blendAlong(x, y, 1, 0) || blendAlong(x, y, 0, 1) || blendAlong(x, y, 1, 1) || blendAlong(x, y, 1, -1);
  const solidAt = new Uint8Array(w * h);
  for (let y = t; y < b; y++) {
    for (let x = l; x < r; x++) {
      const c = f1.at(x, y);
      solidAt[at(x, y)] = (same(x - 1, y, c) || same(x + 1, y, c) || same(x, y - 1, c) || same(x, y + 1, c)) && !blend(x, y) ? 1 : 0;
    }
  }
  const onPageAt = (x, y) => channelDiff(u.at(x, y), page) <= THRESHOLD;
  const steps = [[1, 0], [-1, 0], [0, 1], [0, -1]];
  const bandOf = new Int32Array(w * h).fill(-1);
  // The neighbour of the edge pixel (x, y) of band `id` in the direction
  // (dx, dy), or undefined if the walk finds none it must contrast with.
  const neighbour = (x, y, dx, dy, onPage, id) => {
    const c0 = f1.at(x, y);
    // How thick the band is here, along the way.
    let thick = 0;
    for (let bx = x, by = y; inside(bx, by) && bandOf[at(bx, by)] === id; bx -= dx, by -= dy) thick++;
    let same = 0, blurred = 0;
    for (;;) {
      x += dx; y += dy;
      if (!inside(x, y)) return undefined;
      const i = at(x, y), c = f1.at(x, y);
      // The band itself, or a pixel of its colour that focus also drew.
      if (bandOf[i] === id) continue;
      if (isChanged[i] && channelDiff(c, c0) <= FLAT) continue;
      // On the page, the rest of what focus drew is crossed: the band is
      // taken against the background.
      if (onPage && isChanged[i]) continue;
      const ours = !(onPage && !onPageAt(x, y));
      if (!isChanged[i] && c === c0) {
        // A run of exactly the band's colour that was there before, no
        // wider than the band: the same shape made thicker. A wider one is
        // a neighbour, at 1:1.
        if (++same <= thick) continue;
        return ours ? c : undefined;
      }
      if (solidAt[i]) return ours ? c : undefined;
      if (!blendAlong(x, y, dx, dy)) {
        // A blend some other way is the side of an anti-aliased edge that
        // runs along the way, not one being crossed: the neighbour beyond
        // it is found by the walks that cross it.
        if (blend(x, y)) return undefined;
        // A blend no way is texture (a dither, a pattern), not
        // anti-aliasing: it is the neighbour.
        return ours ? c : undefined;
      }
      // Blurred all the way: what is there is the neighbour, unless focus
      // drew it (the indicator's own anti-aliased edge is not a neighbour
      // of it).
      if (++blurred === BLUR) return ours && !isChanged[i] ? c : undefined;
    }
  };
  const bands = [];
  let strong = 0;
  for (let y0 = t; y0 < b; y0++) {
    for (let x0 = l; x0 < r; x0++) {
      const i0 = at(x0, y0);
      if (!isChanged[i0] || !solidAt[i0] || bandOf[i0] >= 0) continue;
      const id = bands.length;
      const pixels = [[x0, y0]];
      bandOf[i0] = id;
      for (let k = 0; k < pixels.length; k++) {
        const [x, y] = pixels[k];
        for (const [dx, dy] of steps) {
          const nx = x + dx, ny = y + dy;
          if (!inside(nx, ny)) continue;
          const j = at(nx, ny);
          if (!isChanged[j] || !solidAt[j] || bandOf[j] >= 0) continue;
          if (channelDiff(f1.at(nx, ny), f1.at(x, y)) > FLAT) continue;
          bandOf[j] = id;
          pixels.push([nx, ny]);
        }
      }
      const onPage = pixels.filter(([x, y]) => onPageAt(x, y)).length * 2 > pixels.length;
      let contrast = Infinity, lowest = page;
      const next = new Map();
      for (const [x, y] of pixels) {
        for (const [dx, dy] of steps) {
          if (inside(x + dx, y + dy) && bandOf[at(x + dx, y + dy)] === id) continue;
          const n = neighbour(x, y, dx, dy, onPage, id);
          if (n === undefined) continue;
          next.set(n, (next.get(n) ?? 0) + 1);
          const c = ratio(f1.at(x, y), n);
          if (c < contrast) { contrast = c; lowest = n; }
        }
      }
      const counts = new Map();
      for (const [x, y] of pixels) counts.set(f1.at(x, y), (counts.get(f1.at(x, y)) ?? 0) + 1);
      let colour = 0, top = -1;
      for (const [c, n] of counts) if (n > top || (n === top && c < colour)) { colour = c; top = n; }
      // Nothing found to measure against: on the page, the page; on the
      // control, the measure is inconclusive and the band is not strong.
      if (next.size === 0) { contrast = onPage ? ratio(colour, page) : 1; lowest = onPage ? page : colour; }
      if (contrast >= 3) strong += pixels.length;
      const sorted = [...next.entries()].sort((p, q) => (q[1] !== p[1] ? q[1] - p[1] : p[0] - q[0]));
      bands.push({ colour, onPage, pixels: pixels.length, contrast, lowest, next: sorted.slice(0, 3), id });
    }
  }
  bands.sort((p, q) => (q.pixels !== p.pixels ? q.pixels - p.pixels : p.id - q.id));
  let swapped = 0;
  for (const [c, n] of newColours) swapped += Math.min(n, oldColours.get(c) ?? 0);
  const flat = bands.reduce((s, d) => s + d.pixels, 0);
  const result = {
    changed, unstable, swapped, indicator: changed, strong, flat, page, bands,
    // The drawing moved rather than focus adding to it: half or more of the
    // colours the changed pixels took were there before, among them.
    moved: changed > 0 && swapped * 2 >= changed,
    ratio: bands.length ? bands[0].contrast : 1,
  };
  const band = (d) => {
    const total = d.next.reduce((s, [, n]) => s + n, 0);
    return `${d.pixels} px ${hex(d.colour)} ${d.onPage ? 'on the page' : 'on the control'} ${d.contrast.toFixed(2)} against ${hex(d.lowest)}; next to it `
      + d.next.slice(0, 2).map(([c, n]) => `${hex(c)} ${ratio(d.colour, c).toFixed(2)} ${Math.floor((100 * n) / Math.max(total, 1))}%`).join(', ');
  };
  result.text = `changed ${changed}, unstable ${unstable}, swapped ${swapped}, indicator ${changed}, in bands ${flat}, `
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

// The measure itself, on the cases of
// test/techniques/v14_focus_indicators_measure_cases.json, which the widget
// tests, the iOS UI tests, and the probe analyser read too, and the Android
// test holds a copy of: among them the pass and fail figures of
// Understanding 1.4.11's section on focus indicators, the first review's
// reproductions, and the measure's known limits.
const CASES = JSON.parse(fs.readFileSync(new URL('../test/techniques/v14_focus_indicators_measure_cases.json', import.meta.url), 'utf8')).cases;
const colourOf = (h) => parseInt(h.slice(1), 16);

/** A case's picture, its `layers` painted in order on white at pixel ratio `s`. */
function paint(layers, width, height, s) {
  const px = new Int32Array(width * height).fill(0xffffff);
  for (const layer of layers) {
    const [l, t, r, b] = layer.rect ? layer.rect.map((v) => v * s) : [0, 0, width, height];
    const ring = (layer.ring ?? 0) * s;
    for (let y = t; y < b; y++) {
      for (let x = l; x < r; x++) {
        if (ring > 0 && x >= l + ring && x < r - ring && y >= t + ring && y < b - ring) continue;
        const along = layer.axis === 'y' ? y - t : x - l;
        const length = layer.axis === 'y' ? b - t : r - l;
        let c;
        if (layer.checker) c = colourOf(layer.checker[(Math.floor((x - l) / (layer.period * s)) + Math.floor((y - t) / (layer.period * s))) % 2]);
        else if (layer.stripes) c = colourOf(layer.stripes[Math.floor(along / (layer.period * s)) % layer.stripes.length]);
        else if (layer.gradient) {
          const a = colourOf(layer.gradient[0]), z = colourOf(layer.gradient[1]);
          const n = length - 1;
          c = 0;
          for (const sh of [16, 8, 0]) c |= Math.floor((((a >> sh) & 255) * (n - along) + ((z >> sh) & 255) * along + Math.floor(n / 2)) / n) << sh;
        } else c = colourOf(layer.colour ?? layer.fill);
        px[y * width + x] = c;
      }
    }
  }
  return { width, height, at: (x, y) => px[y * width + x] };
}

/** What a case's measure at pixel ratio `s` gets wrong: none, if it passes. */
function checkCase(c, s) {
  const w = c.size[0] * s, h = c.size[1] * s;
  const u = paint(c.before, w, h, s), f1 = paint(c.after, w, h, s);
  const f2 = c.after2 ? paint(c.after2, w, h, s) : f1;
  const ind = compare(u, f1, f2, { x: 0, y: 0, width: w, height: h });
  const e = c.expect;
  const problems = [];
  const want = (ok, what) => { if (!ok) problems.push(`${what}: ${ind.text}`); };
  const some = (v, n) => (v === 'none' ? n === 0 : n > 0);
  if (e.changed) want(some(e.changed, ind.changed), `changed ${e.changed}`);
  if (e.unstable) want(some(e.unstable, ind.unstable), `unstable ${e.unstable}`);
  if (e.moved !== undefined) want(ind.moved === e.moved, `moved ${e.moved}`);
  if (e.strong === 'all') want(ind.flat > 0 && ind.strong === ind.flat, 'strong all');
  if (e.strong === 'none') want(ind.strong === 0, 'strong none');
  if (e.strong === 'some') want(ind.strong > 0 && ind.strong < ind.flat, 'strong some');
  if (e.strongPixels !== undefined) want(ind.strong === e.strongPixels * s * s, `strong pixels ${e.strongPixels * s * s}`);
  if (e.ratio) want(Math.abs(ind.ratio - e.ratio[0]) <= e.ratio[1], `ratio ${e.ratio[0]}`);
  if (e.ratioBelow !== undefined) want(ind.ratio < e.ratioBelow, `ratio below ${e.ratioBelow}`);
  if (e.onPage !== undefined) want(ind.bands.length > 0 && ind.bands[0].onPage === e.onPage, `on the page ${e.onPage}`);
  return problems;
}

test.describe('the measure', () => {
  for (const c of CASES) {
    for (const s of c.scales) {
      test(`${c.name} (pixel ratio ${s})`, () => {
        expect(checkCase(c, s)).toEqual([]);
      });
    }
  }
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
        expect(ind.strong, `${c}: ${ind.text}`).toBeGreaterThan(OUR_MINIMUM);
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
