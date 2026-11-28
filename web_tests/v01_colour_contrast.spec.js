// L3 for V01 Colour contrast on web: each example's role, name and state in
// Chromium's accessibility tree, and the contrast of what Flutter draws,
// measured from Chromium's screenshots, light and dark. Spec:
// docs/specs/V01-colour-contrast.md. Runs against the release build in
// build/web.
//
// Every contrast here is read from pixels, never from the theme, with the
// three measures of the widget tests (test/techniques/v01_colour_contrast_test.dart),
// step for step: the text measure (textContrast), the edge measure (edge),
// and the marks (marks). The page is 400 by 800 at a device scale factor of
// 3, the widget tests' pixel ratio, so that the letters are drawn in a real
// font at the size the measures were written for, and a text's colour is
// the colour of its strokes' cores.
//
// What differs from the widget tests, and why:
//
// - Where a text is a semantics element of its own (the body text, the
//   caption), its paragraph's rectangle is the element's, as in the widget
//   tests. Where a text is merged into a control (a field's label and hint,
//   a tile's title, a button's text), the page has no element for it, so
//   its rectangle is found from the pixels (inkBox): in a region of the
//   control that holds only that text, the pixels that differ from the
//   region's commonest colour by more than 12 in some channel, joined into
//   shapes; a shape that touches the region's edge (a line coming in from
//   outside, such as the outline beside a floating label) or that is a line
//   (two logical pixels or less across and ten or more long, or three or
//   less wide and fourteen or more tall: an outline, or a text cursor) is
//   left out; the text's rectangle is the box round the rest. The measure
//   then takes the colours round the text 6 pixels above and below that
//   box, as the widget tests do 6 above and below the paragraph's, which is
//   taller: on a flat background, and on the caption's picture, whose
//   colours change only from left to right, both give the same colours. A
//   letter that touched the region's edge would be left out; the tests
//   would then find fewer text pixels, or none, and fail, not pass.
// - A focused field draws a blinking cursor; each screenshot of a field is
//   taken when the cursor is not drawn in it (caretFree), at most 3 s.
// - The checkbox and the radio buttons have no element of their own (each
//   is merged into its tile), so each is found as the shape drawn in the
//   tile's control part (inkBox again), and the edge measure walks from 4
//   logical pixels outside it. Every walk checks that it begins on the
//   page's colour, and fails if not.
// - The light and dark modes are the browser's own setting
//   (page.emulateMedia({ colorScheme })), which the app follows (it sets no
//   themeMode); each test checks the media query matches and that the page
//   is drawn in the mode's colour (#FBF8FF, #121318) before it measures,
//   and after it sets light again checks that the page is drawn light.
//
// States: every example at rest, light and dark; then, for the good
// examples' texts, light and dark: keyboard focus on each control, a mouse
// hover, focus and hover together, and a mouse button held down, measured
// at 300 ms (as the widget tests hold a finger) and at 2 s (once the
// press's ripple, InkRipple, which spreads over 1 s, covers the control).
// Focus is by Tab, except good-selection's Day, which no Tab or Shift+Tab
// reaches (measured below): it is focused by Up from Week, which chooses it
// too. The mouse is moved off every control before each keyboard step
// (FL-484). The text cursor of a focused field is not measured (it is not
// text, and it blinks).
import fs from 'node:fs';
import zlib from 'node:zlib';
import { test, expect } from '@playwright/test';
import { byId, technique } from './support/techniques.js';
import {
  BROWSERS, EXAMPLE_HEADING, EXAMPLE_SCREENS, EXPECTED_STOPS, collectWalk, endRow, helpRole, judgeCollectedWalk, judgeExampleWalk, startRow,
  judgeTranscript, runWalks, screenStops, spokenRole, transcriptRow, unresolvedRow,
} from './vo/v01_vo_walks.js';

// The example screen's own "Example" heading; the technique's page has
// "Good examples" and "Bad examples", so the name must match exactly.
const exampleHeading = (page) => page.getByRole('heading', { name: 'Example', exact: true, level: 2 });
const { open } = technique('V01', { ready: exampleHeading, settle: 800 });

const DPR = 3;
test.use({ viewport: { width: 400, height: 800 }, deviceScaleFactor: DPR });

const MODES = ['light', 'dark'];
/** The page's colour in each mode: the scheme's surface. */
const PAGE = { light: 0xfbf8ff, dark: 0x121318 };
/** The part of the page every screenshot takes, in logical pixels. */
const CLIP = { x: 0, y: 0, width: 400, height: 440 };

const control = (page, slug, name) => byId(page, `v01-${slug}-${name}`);

// --- Pixels -------------------------------------------------------------

/** Decodes a PNG of 8-bit RGB or RGBA, not interlaced, as Chromium writes (V14's). */
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

/** A screenshot of CLIP, decoded; one logical pixel is DPR of its pixels. */
const shot = async (page) => decodePng(await page.screenshot({ clip: CLIP }));

const diff = (a, b) => Math.max(
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

/** The page's colour: the bottom right of the screenshot, where nothing is drawn. */
const pageColour = (s) => s.at(s.width - 3, s.height - 3);

/** A logical rectangle ({ left, top, right, bottom }) in the screenshot's pixels. */
const px = (r) => ({ left: r.left * DPR, top: r.top * DPR, right: r.right * DPR, bottom: r.bottom * DPR });

/** The logical rectangle of `locator`'s element. */
async function rectOf(locator) {
  const b = await locator.boundingBox();
  expect(b, 'the element is on the page').not.toBeNull();
  return { left: b.x, top: b.y, right: b.x + b.width, bottom: b.y + b.height, width: b.width, height: b.height, cx: b.x + b.width / 2, cy: b.y + b.height / 2 };
}

/**
 * The text measure (the spec, section 6, item 1; _textContrast in the
 * widget tests): `box` is the text's rectangle in the screenshot's pixels.
 * For each column the colours round the text are the pixels 6 above the box
 * and 6 below it; a pixel of the box that differs from both by more than 12
 * in some channel is a text pixel; the text's colour is the commonest text
 * pixel; and the contrast is the lowest, over every column with a pixel of
 * exactly that colour, of the text's colour against either colour round it
 * there. More than 20 text pixels are required.
 */
function textContrast(s, box) {
  const l = Math.floor(box.left), r = Math.ceil(box.right) - 1;
  const t = Math.floor(box.top), b = Math.ceil(box.bottom) - 1;
  const above = t - 6, below = b + 6;
  expect(above >= 0 && below < s.height, `box off the screen: ${JSON.stringify(box)}`).toBe(true);
  const counts = new Map();
  let textPixels = 0;
  for (let x = l; x <= r; x++) {
    const up = s.at(x, above), down = s.at(x, below);
    for (let y = t; y <= b; y++) {
      const c = s.at(x, y);
      if (diff(c, up) > 12 && diff(c, down) > 12) {
        textPixels++;
        counts.set(c, (counts.get(c) ?? 0) + 1);
      }
    }
  }
  expect(textPixels, `no text found in ${JSON.stringify(box)}`).toBeGreaterThan(20);
  let colour = 0, most = -1;
  for (const [c, n] of counts) if (n > most || (n === most && c < colour)) { colour = c; most = n; }
  let lowest = Infinity, under = 0;
  for (let x = l; x <= r; x++) {
    let has = false;
    for (let y = t; y <= b && !has; y++) has = s.at(x, y) === colour;
    if (!has) continue;
    for (const c of [s.at(x, above), s.at(x, below)]) {
      const q = ratio(colour, c);
      if (q < lowest) { lowest = q; under = c; }
    }
  }
  return {
    colour, lowest, under, textPixels, core: most,
    text: `text ${hex(colour)}, lowest ${lowest.toFixed(2)}:1 over ${hex(under)} (${most} of ${textPixels} pixels the text colour)`,
  };
}

/** The commonest colour of `region` (pixels, right and bottom excluded). */
function commonest(s, l, t, r, b) {
  const counts = new Map();
  for (let y = t; y < b; y++) for (let x = l; x < r; x++) counts.set(s.at(x, y), (counts.get(s.at(x, y)) ?? 0) + 1);
  let colour = 0, most = -1;
  for (const [c, n] of counts) if (n > most || (n === most && c < colour)) { colour = c; most = n; }
  return colour;
}

/**
 * The rectangle of what is drawn in `region` (pixels): the pixels that
 * differ from the region's commonest colour by more than 12 in some
 * channel, joined into shapes (8-connected); shapes that touch the
 * region's edge, and lines (2 logical pixels or less across and 10 or more
 * long, or 3 or less wide and 14 or more tall) are left out. Null if
 * nothing is left.
 */
function inkBox(s, region) {
  const l = Math.max(0, Math.round(region.left)), t = Math.max(0, Math.round(region.top));
  const r = Math.min(s.width, Math.round(region.right)), b = Math.min(s.height, Math.round(region.bottom));
  const w = r - l, h = b - t;
  const background = commonest(s, l, t, r, b);
  const ink = new Uint8Array(w * h);
  for (let y = t; y < b; y++) for (let x = l; x < r; x++) ink[(y - t) * w + (x - l)] = diff(s.at(x, y), background) > 12 ? 1 : 0;
  const seen = new Uint8Array(w * h);
  let box = null, dropped = 0;
  for (let i0 = 0; i0 < w * h; i0++) {
    if (!ink[i0] || seen[i0]) continue;
    seen[i0] = 1;
    const stack = [i0];
    let x0 = Infinity, y0 = Infinity, x1 = -1, y1 = -1;
    while (stack.length) {
      const i = stack.pop();
      const x = i % w, y = (i - x) / w;
      x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, y); y1 = Math.max(y1, y);
      for (let dy = -1; dy <= 1; dy++) {
        for (let dx = -1; dx <= 1; dx++) {
          const nx = x + dx, ny = y + dy;
          if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
          const j = ny * w + nx;
          if (ink[j] && !seen[j]) { seen[j] = 1; stack.push(j); }
        }
      }
    }
    const cw = x1 - x0 + 1, ch = y1 - y0 + 1;
    const touches = x0 === 0 || y0 === 0 || x1 === w - 1 || y1 === h - 1;
    const line = (ch <= 2 * DPR && cw >= 10 * DPR) || (cw <= 3 * DPR && ch >= 14 * DPR);
    if (touches || line) { dropped++; continue; }
    box = box
      ? { left: Math.min(box.left, l + x0), top: Math.min(box.top, t + y0), right: Math.max(box.right, l + x1 + 1), bottom: Math.max(box.bottom, t + y1 + 1) }
      : { left: l + x0, top: t + y0, right: l + x1 + 1, bottom: t + y1 + 1 };
  }
  return box && { ...box, background, dropped };
}

/** The text measure on the text found in `region` (logical) by inkBox. */
function textIn(s, region) {
  const box = inkBox(s, px(region));
  expect(box, `nothing drawn in ${JSON.stringify(region)}`).not.toBeNull();
  return textContrast(s, box);
}

/**
 * Whether no text cursor is drawn in `region` (logical): no column has a
 * run of pixels, differing from the region's commonest colour by more than
 * 12, 14 logical pixels or more tall. No letter of these texts is that tall.
 */
function caretFree(s, region) {
  const { left, top, right, bottom } = px(region);
  const l = Math.round(left), t = Math.round(top), r = Math.round(right), b = Math.round(bottom);
  const background = commonest(s, l, t, r, b);
  for (let x = l; x < r; x++) {
    let run = 0;
    for (let y = t; y < b; y++) {
      run = diff(s.at(x, y), background) > 12 ? run + 1 : 0;
      if (run >= 14 * DPR) return false;
    }
  }
  return true;
}

/** A screenshot with no cursor drawn in any of `regions`, waiting at most 3 s. */
async function shotWithoutCaret(page, regions) {
  for (let i = 0; i < 30; i++) {
    const s = await shot(page);
    if (regions.every((r) => caretFree(s, r))) return s;
    await page.waitForTimeout(100);
  }
  throw new Error('a text cursor stayed drawn for 3 s');
}

/**
 * The edge measure (section 6, item 2; _edge in the widget tests): from the
 * pixel (x0, y0), outside the control, `steps` pixels in the direction
 * (dx, dy); the edge is the pixel on the way that contrasts most with the
 * first, and it is taken against the first (outside) and the last
 * (inside).
 */
function edge(s, x0, y0, dx, dy, steps) {
  x0 = Math.round(x0); y0 = Math.round(y0);
  const start = s.at(x0, y0);
  let e = start;
  for (let i = 1; i <= steps; i++) {
    const c = s.at(x0 + dx * i, y0 + dy * i);
    if (ratio(c, start) > ratio(e, start)) e = c;
  }
  const end = s.at(x0 + dx * steps, y0 + dy * steps);
  const outside = ratio(e, start), inside = ratio(e, end);
  return { start, edge: e, end, outside, inside, text: `edge ${hex(e)}: ${outside.toFixed(2)}:1 against ${hex(start)}, ${inside.toFixed(2)}:1 against ${hex(end)}` };
}

/** Expects the walk `e` to have begun on the page's colour. */
function expectOnPage(e, mode, what) {
  expect(hex(e.start), `${what}: the walk did not begin on the page (${e.text})`).toBe(hex(PAGE[mode]));
}

/** The pixels of `area` (logical) that are 3:1 or more against `against` (section 6, item 3). */
function marks(s, area, against) {
  const a = px(area);
  let n = 0;
  for (let y = Math.floor(a.top); y < Math.ceil(a.bottom); y++) {
    for (let x = Math.floor(a.left); x < Math.ceil(a.right); x++) if (ratio(s.at(x, y), against) >= 3) n++;
  }
  return n;
}

// The regions, in logical pixels, that hold one text or one mark of a
// control, from the control's element's rectangle `r` (seen in the
// screenshots: docs/evidence/probes/v01/).

/** An outlined field's floating label, which sits on the outline's top. */
const outlinedLabel = (r) => ({ left: r.left - 2, top: r.top - 10, right: r.left + r.width / 2, bottom: r.top + 9 });
/** Inside an outlined field, clear of its outline: the hint. */
const outlinedInside = (r) => ({ left: r.left + 4, top: r.top + 6, right: r.right - 4, bottom: r.bottom - 4 });
/** The text above a Cupertino field, its visible label. */
const labelAbove = (r) => ({ left: r.left - 2, top: r.top - 25, right: r.left + r.width / 2, bottom: r.top - 2 });
/** Inside a Cupertino field, clear of its edge: the placeholder. */
const cupertinoInside = (r) => ({ left: r.left + 3, top: r.top + 3, right: r.right - 3, bottom: r.bottom - 3 });
/** Inside a button, clear of its edge and its rounded ends. */
const buttonInside = (r, x, y) => ({ left: r.left + x, top: r.top + y, right: r.right - x, bottom: r.bottom - y });
/** A checkbox tile's title, at the start; and its checkbox, at the end. */
const tileTitle = (r) => ({ left: r.left + 2, top: r.top + 2, right: r.left + r.width * 0.7, bottom: r.bottom - 2 });
const tileCheckbox = (r) => ({ left: r.left + r.width * 0.7, top: r.top + 2, right: r.right - 2, bottom: r.bottom - 2 });
/**
 * A radio tile's radio button, at the start (its ring is 20 across and its
 * hover and focus overlay 40, centred 32 in), and its title after 56.
 */
const radioRing = (r) => ({ left: r.left + 2, top: r.top + 2, right: r.left + 56, bottom: r.bottom - 2 });
const radioTitle = (r) => ({ left: r.left + 56, top: r.top + 2, right: r.right - 2, bottom: r.bottom - 2 });
/** A list tile with only a title. */
const tileInside = (r) => ({ left: r.left + 2, top: r.top + 2, right: r.right - 2, bottom: r.bottom - 2 });

/** The shape inkBox finds in `region` (logical), in logical pixels. */
function shapeIn(s, region, what) {
  const b = inkBox(s, px(region));
  expect(b, `${what}: nothing drawn`).not.toBeNull();
  return { left: b.left / DPR, top: b.top / DPR, right: b.right / DPR, bottom: b.bottom / DPR, cx: (b.left + b.right) / 2 / DPR, cy: (b.top + b.bottom) / 2 / DPR };
}

// --- The browser's colour scheme, the mouse, and the keyboard -----------------

/** Moves the mouse to the bottom right of the page, over nothing. */
const park = (page) => page.mouse.move(398, 798);

/**
 * Sets the browser's colour scheme to `mode`, opens `slug`, and checks that
 * the media query matches and that the page is drawn in the mode's colour.
 */
async function openIn(page, slug, mode) {
  await page.emulateMedia({ colorScheme: mode });
  await open(page, slug);
  await park(page);
  expect(await page.evaluate((m) => matchMedia(`(prefers-color-scheme: ${m})`).matches, mode), `the media query matches ${mode}`).toBe(true);
  await expect.poll(async () => hex(pageColour(await shot(page))), { message: `the page is drawn ${mode}` }).toBe(hex(PAGE[mode]));
}

/** Sets the colour scheme back to light, Playwright's default, and checks it took. */
async function restore(page) {
  await page.emulateMedia({ colorScheme: 'light' });
  expect(await page.evaluate(() => matchMedia('(prefers-color-scheme: light)').matches), 'the media query matches light again').toBe(true);
  await expect.poll(async () => hex(pageColour(await shot(page))), { message: 'the page is drawn light again' }).toBe(hex(PAGE.light));
}

/** Whether keyboard focus is on `locator`'s element or inside it. */
const hasFocus = (locator) => locator.evaluate((e) => e.contains(document.activeElement));

/** Presses Tab until focus is on `locator`, at most 12 times, the mouse off every control. */
async function focusByTab(page, locator) {
  await park(page);
  for (let i = 0; i < 12; i++) {
    const before = await page.evaluateHandle(() => document.activeElement);
    await page.keyboard.press('Tab');
    // Flutter moves DOM focus on the next frame.
    await page.waitForFunction((e) => document.activeElement !== e, before, { timeout: 1000 }).catch(() => {});
    await page.waitForTimeout(100);
    if (await hasFocus(locator)) return true;
  }
  return false;
}

/** What Chromium's accessibility tree has for `locator`'s element: role, name, description, properties. */
async function axOf(page, locator) {
  const cdp = await page.context().newCDPSession(page);
  await locator.evaluate((e) => e.setAttribute('data-v01-ax', ''));
  try {
    const { result } = await cdp.send('Runtime.evaluate', { expression: 'document.querySelector("[data-v01-ax]")' });
    const { nodes } = await cdp.send('Accessibility.getPartialAXTree', { objectId: result.objectId, fetchRelatives: false });
    const n = nodes[0];
    return {
      role: n.role?.value,
      name: n.name?.value,
      description: n.description?.value ?? null,
      props: Object.fromEntries((n.properties ?? []).map((p) => [p.name, p.value.value])),
    };
  } finally {
    await locator.evaluate((e) => e.removeAttribute('data-v01-ax'));
    await cdp.detach();
  }
}

/** The states a property list can give a control's choice. */
const STATES = ['checked', 'selected', 'pressed', 'expanded'];
const statesOf = (ax) => Object.fromEntries(STATES.filter((k) => k in ax.props).map((k) => [k, ax.props[k]]));

// --- Tests --------------------------------------------------------------

test.describe('the measure', () => {
  test('the contrast ratio is WCAG\'s, on known pairs', () => {
    expect(ratio(0x000000, 0xffffff)).toBeCloseTo(21, 2);
    expect(ratio(0x767676, 0xffffff)).toBeCloseTo(4.54, 2);
    expect(ratio(0x949494, 0xffffff)).toBeCloseTo(3.03, 2);
    expect(ratio(0xffffff, 0xffffff)).toBe(1);
  });

  // A made-up screenshot: on white, a line 1 logical pixel thick across a
  // region (an outline), a cursor 2 wide and 18 tall, and a "text", a block
  // of #767676 9 tall with a lighter border (anti-aliasing): inkBox leaves
  // out the line and the cursor, the measure finds #767676 at 4.54:1, and
  // caretFree sees the cursor.
  // In the picture's own pixels, DPR to a logical pixel.
  const picture = (withCaret) => {
    const w = 60 * DPR, h = 40 * DPR;
    const p = new Int32Array(w * h).fill(0xffffff);
    const fill = (l, t, r, b, c) => { for (let y = t; y < b; y++) for (let x = l; x < r; x++) p[y * w + x] = c; };
    fill(0, 15, 180, 18, 0x767680);
    fill(59, 44, 121, 73, 0xb0b0b0);
    fill(60, 45, 120, 72, 0x767676);
    if (withCaret) fill(48, 33, 54, 87, 0x515b92);
    return { width: w, height: h, at: (x, y) => p[y * w + x] };
  };

  test('on a made-up picture inkBox leaves out a line and a cursor, and the text measure gives the text\'s ratio', () => {
    const region = { left: 2, top: 3, right: 58, bottom: 37 };
    for (const withCaret of [false, true]) {
      const s = picture(withCaret);
      const box = inkBox(s, px(region));
      expect(box, `cursor ${withCaret}`).toMatchObject({ left: 59, top: 44, right: 121, bottom: 73 });
      expect(box.dropped, `cursor ${withCaret}`).toBe(withCaret ? 2 : 1);
      const m = textContrast(s, box);
      expect(hex(m.colour)).toBe('#767676');
      expect(m.lowest).toBeCloseTo(4.54, 2);
      expect(caretFree(s, region), `cursor ${withCaret}`).toBe(!withCaret);
    }
  });

  test('the edge measure takes the strongest pixel on the way against both ends', () => {
    const s = picture(false);
    const e = edge(s, 10 * DPR, 2 * DPR, 0, 1, 6 * DPR);
    expect(hex(e.start)).toBe('#FFFFFF');
    expect(hex(e.edge)).toBe('#767680');
    expect(hex(e.end)).toBe('#FFFFFF');
    expect(e.outside).toBeCloseTo(ratio(0x767680, 0xffffff), 5);
  });
});

test.describe('roles, names, and states in Chromium\'s accessibility tree', () => {
  test('good-material: a text field named "Email", an unchecked checkbox, and a button', async ({ page }) => {
    await open(page, 'good-material');
    const email = control(page, 'good-material', 'email').locator('input');
    await expect(email).toHaveRole('textbox');
    await expect(email).toHaveAccessibleName('Email');
    expect(await axOf(page, email)).toMatchObject({ role: 'textbox', name: 'Email', description: null });
    const updates = control(page, 'good-material', 'updates');
    await expect(updates).toHaveRole('checkbox');
    await expect(updates).toHaveAccessibleName('Send me updates');
    await expect(updates).not.toBeChecked();
    expect(statesOf(await axOf(page, updates))).toEqual({ checked: 'false' });
    const send = control(page, 'good-material', 'send');
    await expect(send).toHaveRole('button');
    await expect(send).toHaveAccessibleName('Send');
    // Counted: one field, one checkbox, and Back and Send.
    await expect(page.getByRole('textbox')).toHaveCount(1);
    await expect(page.getByRole('checkbox')).toHaveCount(1);
    await expect(page.getByRole('button')).toHaveCount(2);
    await expect(page.getByText('We reply within two days.', { exact: true })).toHaveCount(1);
  });

  // The field's name is its Semantics label and its placeholder: the page
  // has aria-label "Email\nRequired", which Chromium's tree gives as
  // "Email Required". The "Email" text above the field is not an element.
  for (const slug of ['good-cupertino', 'bad-cupertino-placeholder']) {
    test(`${slug}: a text field named "Email Required" in Chromium's tree, and the label above it no element of its own`, async ({ page }) => {
      await open(page, slug);
      const email = control(page, slug, 'email').locator('input');
      await expect(email).toHaveRole('textbox');
      await expect(email).toHaveAttribute('aria-label', 'Email\nRequired');
      expect(await axOf(page, email)).toMatchObject({ role: 'textbox', name: 'Email Required', description: null });
      await expect(page.getByRole('textbox')).toHaveCount(1);
      await expect(page.locator('flt-semantics-host').getByText('Email', { exact: true })).toHaveCount(0);
      if (slug === 'good-cupertino') {
        const send = control(page, slug, 'send');
        await expect(send).toHaveRole('button');
        await expect(send).toHaveAccessibleName('Send');
        await expect(page.getByRole('button')).toHaveCount(2);
      } else {
        await expect(page.getByRole('button')).toHaveCount(1);
      }
    });
  }

  for (const slug of ['good-caption', 'bad-caption']) {
    test(`${slug}: the caption is one text, "Harbour", and the picture no element`, async ({ page }) => {
      await open(page, slug);
      await expect(page.getByText('Harbour', { exact: true })).toHaveCount(1);
      await expect(page.getByRole('img')).toHaveCount(0);
      await expect(page.getByRole('button')).toHaveCount(1);
    });
  }

  test('good-selection: a radio group named "Calendar view", three radio buttons, Week checked; a click on Day checks Day', async ({ page }) => {
    await open(page, 'good-selection');
    await expect(page.getByRole('radiogroup')).toHaveCount(1);
    await expect(page.getByRole('radiogroup')).toHaveAccessibleName('Calendar view');
    await expect(page.getByRole('radio')).toHaveCount(3);
    const check = async (chosen) => {
      for (const v of ['Day', 'Week', 'Month']) {
        const r = control(page, 'good-selection', v.toLowerCase());
        await expect(r).toHaveRole('radio');
        await expect(r).toHaveAccessibleName(v);
        if (v === chosen) await expect(r).toBeChecked();
        else await expect(r).not.toBeChecked();
        const ax = await axOf(page, r);
        expect(statesOf(ax), v).toEqual({ checked: v === chosen ? 'true' : 'false' });
        // Flutter gives a radio button not chosen the description "Not
        // selected" (aria-description), and the chosen one none.
        expect(ax.description, v).toBe(v === chosen ? null : 'Not selected');
      }
    };
    await check('Week');
    await control(page, 'good-selection', 'day').click();
    await expect(control(page, 'good-selection', 'day')).toBeChecked();
    await check('Day');
  });

  // Why Day's focused state is measured while it is chosen (focusRadio): a
  // whole cycle of Tab, and one of Shift+Tab, from Back until focus is on
  // Back again, with Week chosen, stops on Week and Month and never on Day.
  // Measured; why Flutter skips Day was not looked into.
  for (const [key, order] of [['Tab', ['week', 'month']], ['Shift+Tab', ['month', 'week']]]) {
    test(`good-selection: a whole ${key} cycle stops on Week and Month, and never on Day`, async ({ page }) => {
      await open(page, 'good-selection');
      await park(page);
      const where = () => page.evaluate(() => {
        const e = document.activeElement;
        if (!e || e === document.body) return 'none';
        const id = e.closest('[flt-semantics-identifier]')?.getAttribute('flt-semantics-identifier');
        if (id) return id;
        return (e.textContent ?? '').trim() === 'Back' ? 'back' : `other: ${e.tagName}`;
      });
      const press = async () => {
        const before = await page.evaluateHandle(() => document.activeElement);
        await page.keyboard.press(key);
        await page.waitForFunction((e) => document.activeElement !== e, before, { timeout: 1000 }).catch(() => {});
        await page.waitForTimeout(100);
        return where();
      };
      // To Back first: when the page opens DOM focus can be on Back while
      // Flutter's is nowhere.
      let at = 'none';
      for (let i = 0; i < 12 && at !== 'back'; i++) at = await press();
      expect(at).toBe('back');
      const stops = [];
      for (let i = 0; i < 12; i++) {
        at = await press();
        if (at === 'back') break;
        stops.push(at);
      }
      expect(at, `the cycle came back to Back: ${stops.join(', ')}`).toBe('back');
      console.log(`V01 web good-selection ${key} cycle: ${stops.join(', ')}`);
      expect(stops.filter((s) => s.startsWith('v01-good-selection-')), stops.join(', ')).toEqual(order.map((v) => `v01-good-selection-${v}`));
    });
  }

  // The finding: in Chromium's tree a selected ListTile is a button with
  // no state. Flutter writes the selection as aria-current="true" on the
  // element (and "false" on the others); Chromium's tree, read over the
  // DevTools protocol, has no property for aria-current, and has no
  // selected, checked, pressed, or expanded state on any of the three.
  test('bad-colour-only: three buttons with no state in Chromium\'s tree; the page marks Week aria-current="true"; a click on Day moves it', async ({ page }) => {
    await open(page, 'bad-colour-only');
    await expect(page.getByText('Calendar view', { exact: true })).toHaveCount(1);
    await expect(page.getByRole('button')).toHaveCount(4);
    await expect(page.getByRole('radio')).toHaveCount(0);
    await expect(page.getByRole('checkbox')).toHaveCount(0);
    const check = async (chosen) => {
      for (const v of ['Day', 'Week', 'Month']) {
        const b = control(page, 'bad-colour-only', v.toLowerCase());
        await expect(b).toHaveRole('button');
        await expect(b).toHaveAccessibleName(v);
        await expect(b).toHaveAttribute('aria-current', v === chosen ? 'true' : 'false');
        for (const a of ['aria-selected', 'aria-pressed', 'aria-checked']) await expect(b, `${v} ${a}`).not.toHaveAttribute(a);
        const ax = await axOf(page, b);
        expect(ax.role, v).toBe('button');
        expect(statesOf(ax), v).toEqual({});
        expect(ax.description, v).toBe(null);
      }
    };
    await check('Week');
    await control(page, 'bad-colour-only', 'day').click();
    await expect(control(page, 'bad-colour-only', 'day')).toHaveAttribute('aria-current', 'true');
    await check('Day');
  });

  test('bad-faint-edge: a text field named "Email"', async ({ page }) => {
    await open(page, 'bad-faint-edge');
    const email = control(page, 'bad-faint-edge', 'email').locator('input');
    await expect(email).toHaveRole('textbox');
    await expect(email).toHaveAccessibleName('Email');
    expect(await axOf(page, email)).toMatchObject({ role: 'textbox', name: 'Email', description: null });
    await expect(page.getByRole('textbox')).toHaveCount(1);
  });
});

test.describe('the stops the VoiceOver spec expects above each example', () => {
  for (const [slug, [title, ...lines]] of Object.entries(EXAMPLE_SCREENS)) {
    test(`${slug} shows its title and its lines`, async ({ page }) => {
      await open(page, slug);
      await expect(page.getByRole('heading', { name: title, exact: true, level: 1 })).toHaveCount(1);
      for (const line of lines) await expect(page.getByText(line, { exact: true })).toHaveCount(1);
    });
  }
});

/** Logs one measure, as the widget tests print theirs. */
const report = (slug, what, state, mode, m) => console.log(`V01 web ${slug} ${what} ${state} ${mode}: ${m.text}`);

for (const mode of MODES) {
  test.describe(`at rest, ${mode}`, () => {
    test.afterEach(async ({ page }) => restore(page));

    test('good-material: every text 4.5:1 or more, and the field\'s edge, the checkbox, and the button\'s outline 3:1 or more', async ({ page }) => {
      const slug = 'good-material';
      await openIn(page, slug, mode);
      const field = await rectOf(control(page, slug, 'email'));
      const tile = await rectOf(control(page, slug, 'updates'));
      const send = await rectOf(control(page, slug, 'send'));
      const body = await rectOf(page.getByText('We reply within two days.', { exact: true }));
      const s = await shotWithoutCaret(page, [outlinedInside(field)]);
      for (const [t, m] of [
        ['We reply within two days.', textContrast(s, px(body))],
        ['Email', textIn(s, outlinedLabel(field))],
        ['Required', textIn(s, outlinedInside(field))],
        ['Send me updates', textIn(s, tileTitle(tile))],
        ['Send', textIn(s, buttonInside(send, 12, 4))],
      ]) {
        report(slug, `"${t}"`, 'rest', mode, m);
        expect(m.lowest, `"${t}": ${m.text}`).toBeGreaterThanOrEqual(4.5);
      }
      const e = edge(s, field.left * DPR - 12, field.cy * DPR, 1, 0, 30);
      report(slug, 'field', 'rest', mode, e);
      expectOnPage(e, mode, 'field');
      expect(e.outside, `field ${e.text}`).toBeGreaterThanOrEqual(3);
      const box = shapeIn(s, tileCheckbox(tile), 'the checkbox');
      const boxEdge = edge(s, (box.right + 4) * DPR, box.cy * DPR, -1, 0, 30);
      report(slug, 'checkbox', 'rest', mode, boxEdge);
      expectOnPage(boxEdge, mode, 'checkbox');
      expect(boxEdge.outside, `box ${boxEdge.text}`).toBeGreaterThanOrEqual(3);
      const outline = edge(s, send.left * DPR - 6, send.cy * DPR, 1, 0, 30);
      report(slug, 'outline', 'rest', mode, outline);
      expectOnPage(outline, mode, 'outline');
      expect(outline.outside, `outline ${outline.text}`).toBeGreaterThanOrEqual(3);
    });

    test('good-material: the checkbox checked, its fill 3:1 or more against the page and its mark 3:1 or more against the fill', async ({ page }) => {
      const slug = 'good-material';
      await openIn(page, slug, mode);
      const updates = control(page, slug, 'updates');
      await updates.click();
      await expect(updates).toBeChecked();
      await park(page);
      await page.waitForTimeout(800);
      const tile = await rectOf(updates);
      const s = await shot(page);
      const box = shapeIn(s, tileCheckbox(tile), 'the checkbox');
      const fill = edge(s, (box.right + 4) * DPR, box.cy * DPR, -1, 0, 30);
      report(slug, 'checked fill', 'rest', mode, fill);
      expectOnPage(fill, mode, 'fill');
      expect(fill.outside, `fill ${fill.text}`).toBeGreaterThanOrEqual(3);
      const mark = marks(s, { left: box.cx - 5, top: box.cy - 5, right: box.cx + 5, bottom: box.cy + 5 }, fill.edge);
      console.log(`V01 web ${slug} checked mark rest ${mode}: ${mark} pixels 3:1 or more against ${hex(fill.edge)}`);
      expect(mark, 'a mark 3:1 or more on the fill').toBeGreaterThan(30);
      const m = textIn(s, tileTitle(tile));
      report(slug, '"Send me updates" checked', 'rest', mode, m);
      expect(m.lowest, m.text).toBeGreaterThanOrEqual(4.5);
    });

    test('good-cupertino: the label, the placeholder, and the button\'s text 4.5:1 or more; the field\'s edge 3:1 or more against the page and the field', async ({ page }) => {
      const slug = 'good-cupertino';
      await openIn(page, slug, mode);
      const field = await rectOf(control(page, slug, 'email'));
      const send = await rectOf(control(page, slug, 'send'));
      const s = await shotWithoutCaret(page, [cupertinoInside(field)]);
      for (const [t, m] of [
        ['Email', textIn(s, labelAbove(field))],
        ['Required', textIn(s, cupertinoInside(field))],
        ['Send', textIn(s, buttonInside(send, 10, 8))],
      ]) {
        report(slug, `"${t}"`, 'rest', mode, m);
        expect(m.lowest, `"${t}": ${m.text}`).toBeGreaterThanOrEqual(4.5);
      }
      const e = edge(s, field.left * DPR - 6, field.cy * DPR, 1, 0, 18);
      report(slug, 'field', 'rest', mode, e);
      expectOnPage(e, mode, 'field');
      expect(e.outside, e.text).toBeGreaterThanOrEqual(3);
      expect(e.inside, e.text).toBeGreaterThanOrEqual(3);
    });

    test('good-caption: the caption 4.5:1 or more over the whole picture', async ({ page }) => {
      const slug = 'good-caption';
      await openIn(page, slug, mode);
      const s = await shot(page);
      const m = textContrast(s, px(await rectOf(page.getByText('Harbour', { exact: true }))));
      report(slug, '"Harbour"', 'rest', mode, m);
      expect(m.lowest, m.text).toBeGreaterThanOrEqual(4.5);
    });

    test('good-selection: each option 4.5:1 or more, each radio button\'s ring 3:1 or more, only the chosen one has a dot; a click on Day moves the dot', async ({ page }) => {
      const slug = 'good-selection';
      await openIn(page, slug, mode);
      const dots = async (when) => {
        const s = await shot(page);
        const out = {};
        for (const v of ['Day', 'Week', 'Month']) {
          const tile = await rectOf(control(page, slug, v.toLowerCase()));
          const ring = shapeIn(s, radioRing(tile), `${v}'s radio button`);
          const e = edge(s, (ring.left - 4) * DPR, ring.cy * DPR, 1, 0, Math.round((4 + (ring.right - ring.left) / 2) * DPR));
          report(slug, `${v} ring ${when}`, 'rest', mode, e);
          expectOnPage(e, mode, `${v} ring`);
          expect(e.outside, `${v} ring ${e.text}`).toBeGreaterThanOrEqual(3);
          const title = textIn(s, radioTitle(tile));
          report(slug, `"${v}" ${when}`, 'rest', mode, title);
          expect(title.lowest, `${v}: ${title.text}`).toBeGreaterThanOrEqual(4.5);
          // The dot: the middle of the ring, 4 logical pixels each way.
          out[v] = marks(s, { left: ring.cx - 4, top: ring.cy - 4, right: ring.cx + 4, bottom: ring.cy + 4 }, PAGE[mode]);
        }
        console.log(`V01 web ${slug} dots ${when} ${mode}: ${JSON.stringify(out)}`);
        return out;
      };
      const before = await dots('before');
      expect(before.Week, JSON.stringify(before)).toBeGreaterThan(100);
      expect(before.Day, JSON.stringify(before)).toBe(0);
      expect(before.Month, JSON.stringify(before)).toBe(0);
      await control(page, slug, 'day').click();
      await expect(control(page, slug, 'day')).toBeChecked();
      await park(page);
      await page.waitForTimeout(800);
      const after = await dots('after');
      expect(after.Day, JSON.stringify(after)).toBeGreaterThan(100);
      expect(after.Week, JSON.stringify(after)).toBe(0);
      expect(after.Month, JSON.stringify(after)).toBe(0);
    });

    // --- Bad examples: each defect, measured, written to fail if Flutter
    // draws it otherwise, with a lower bound that shows it was drawn.

    test('bad-cupertino-placeholder: the placeholder under 4.5:1; the label and the field\'s edge as in good-cupertino', async ({ page }) => {
      const slug = 'bad-cupertino-placeholder';
      await openIn(page, slug, mode);
      const field = await rectOf(control(page, slug, 'email'));
      const s = await shotWithoutCaret(page, [cupertinoInside(field)]);
      const placeholder = textIn(s, cupertinoInside(field));
      report(slug, '"Required"', 'rest', mode, placeholder);
      expect(placeholder.lowest, placeholder.text).toBeLessThan(4.5);
      expect(placeholder.lowest, `the placeholder is drawn: ${placeholder.text}`).toBeGreaterThan(1.2);
      const label = textIn(s, labelAbove(field));
      report(slug, '"Email"', 'rest', mode, label);
      expect(label.lowest, label.text).toBeGreaterThanOrEqual(4.5);
      const e = edge(s, field.left * DPR - 6, field.cy * DPR, 1, 0, 18);
      report(slug, 'field', 'rest', mode, e);
      expectOnPage(e, mode, 'field');
      expect(e.outside, e.text).toBeGreaterThanOrEqual(3);
    });

    test('bad-caption: the caption under 4.5:1 over the pale part of the picture, in a colour 4.5:1 or more over its dark end', async ({ page }) => {
      const slug = 'bad-caption';
      await openIn(page, slug, mode);
      const s = await shot(page);
      const box = await rectOf(page.getByText('Harbour', { exact: true }));
      const whole = textContrast(s, px(box));
      report(slug, '"Harbour"', 'rest', mode, whole);
      expect(whole.lowest, whole.text).toBeLessThan(4.5);
      expect(whole.lowest, `the caption is drawn: ${whole.text}`).toBeGreaterThan(1);
      // The dark end of the picture, at the right of the same bar, 8 past
      // the caption's box (the picture is 16 to 384).
      const dark = s.at(Math.round((box.right + 8) * DPR), Math.round(box.cy * DPR));
      console.log(`V01 web ${slug} dark end ${mode}: ${hex(dark)}, ${ratio(whole.colour, dark).toFixed(2)}:1 against the caption`);
      expect(ratio(whole.colour, dark)).toBeGreaterThanOrEqual(4.5);
    });

    test('bad-colour-only: the chosen title differs from the others by colour alone, under 3:1 against theirs; each 4.5:1 or more against the page; a click on Day moves the colour', async ({ page }) => {
      const slug = 'bad-colour-only';
      await openIn(page, slug, mode);
      const titles = async (when) => {
        const s = await shot(page);
        const out = {};
        for (const v of ['Day', 'Week', 'Month']) {
          const tile = await rectOf(control(page, slug, v.toLowerCase()));
          const box = inkBox(s, px(tileInside(tile)));
          expect(box, `${v}: nothing drawn`).not.toBeNull();
          const m = textContrast(s, box);
          report(slug, `"${v}" ${when}`, 'rest', mode, m);
          expect(m.lowest, `${v}: ${m.text}`).toBeGreaterThanOrEqual(4.5);
          out[v] = m;
          // Nothing but the title is drawn on the tile: every pixel of the
          // tile outside the title's box (2 logical pixels wider each way)
          // is within 2 of the tile's corner pixel.
          const t = px(tile);
          const corner = s.at(Math.round(t.left) + 1, Math.round(t.top) + 1);
          expect(hex(corner), `${v}: the tile is the page's colour`).toBe(hex(PAGE[mode]));
          let other = 0;
          for (let y = Math.ceil(t.top); y < Math.floor(t.bottom); y++) {
            for (let x = Math.ceil(t.left); x < Math.floor(t.right); x++) {
              const inTitle = x >= box.left - 2 * DPR && x < box.right + 2 * DPR && y >= box.top - 2 * DPR && y < box.bottom + 2 * DPR;
              if (!inTitle && diff(s.at(x, y), corner) > 2) other++;
            }
          }
          expect(other, `${v}: ${other} pixels besides the title`).toBe(0);
        }
        return out;
      };
      const before = await titles('before');
      const chosen = before.Week.colour;
      for (const v of ['Day', 'Month']) {
        const q = ratio(chosen, before[v].colour);
        console.log(`V01 web ${slug} ${mode}: Week ${hex(chosen)} against ${v} ${hex(before[v].colour)} ${q.toFixed(2)}:1`);
        expect(hex(before[v].colour)).not.toBe(hex(chosen));
        expect(q, `Week against ${v}`).toBeLessThan(3);
        expect(q, `Week against ${v}: the colours differ`).toBeGreaterThan(1);
      }
      await control(page, slug, 'day').click();
      await expect(control(page, slug, 'day')).toHaveAttribute('aria-current', 'true');
      await park(page);
      await page.waitForTimeout(800);
      const after = await titles('after');
      expect(hex(after.Day.colour), 'the colour moved to Day').toBe(hex(chosen));
      expect(hex(after.Week.colour)).toBe(hex(before.Day.colour));
    });

    test('bad-faint-edge: the field\'s edge under 3:1 against the page at rest; with focus by Tab the same measure finds it 3:1 or more', async ({ page }) => {
      const slug = 'bad-faint-edge';
      await openIn(page, slug, mode);
      const locator = control(page, slug, 'email');
      const field = await rectOf(locator);
      let s = await shot(page);
      const rest = edge(s, field.left * DPR - 12, field.cy * DPR, 1, 0, 30);
      report(slug, 'field', 'rest', mode, rest);
      expectOnPage(rest, mode, 'field');
      expect(rest.outside, rest.text).toBeLessThan(3);
      expect(rest.outside, `the edge is drawn: ${rest.text}`).toBeGreaterThan(1.2);
      const label = textIn(s, outlinedLabel(field));
      report(slug, '"Email"', 'rest', mode, label);
      expect(label.lowest, label.text).toBeGreaterThanOrEqual(4.5);
      // The positive control: focus on the field, by Tab.
      expect(await focusByTab(page, locator), 'Tab reaches the field').toBe(true);
      await page.waitForTimeout(800);
      s = await shot(page);
      const focused = edge(s, field.left * DPR - 12, field.cy * DPR, 1, 0, 30);
      report(slug, 'field', 'focused', mode, focused);
      expectOnPage(focused, mode, 'field focused');
      expect(focused.outside, focused.text).toBeGreaterThanOrEqual(3);
    });
  });
}

/** Waits, at most a second, for focus to be on `locator`. */
const focusLands = (locator) => expect.poll(() => hasFocus(locator), { timeout: 1000 }).toBe(true).then(() => true, () => false);

/**
 * Puts keyboard focus on one of good-selection's radio buttons, called for
 * Day, Week, and Month in turn. Tab never reaches Day (the Tab cycle test
 * above), so Day is reached by Tab to Week and then Up, which chooses Day
 * as well (checked here); Week by Down from Day, which chooses Week again;
 * and Month by Tab from Week, which leaves Week chosen.
 */
async function focusRadio(page, name) {
  const radio = (v) => control(page, 'good-selection', v);
  if (name === 'month') return focusByTab(page, radio('month'));
  if (name === 'day') {
    if (!(await focusByTab(page, radio('week')))) return false;
    await park(page);
    await page.keyboard.press('ArrowUp');
  } else {
    await park(page);
    await page.keyboard.press('ArrowDown');
  }
  if (!(await focusLands(radio(name)))) return false;
  await expect(radio(name)).toBeChecked();
  return true;
}

// The good examples' texts in each state. For each control in turn: the
// state is set, the drawing left 800 ms to settle, the control's texts
// measured, and the state undone (the button let go, the mouse parked).
// A press is measured twice while it is held: at 300 ms, as the widget
// tests do with a finger, and at 2 s, once the press's ripple (InkRipple,
// which spreads over 1 s) and highlight cover the control. Every text is
// measured and logged in every state (soft expectations), and the test
// fails if any is under 4.5:1.
const STATE_CONTROLS = {
  'good-material': [
    { name: 'email', texts: (r) => ({ Email: outlinedLabel(r), Required: outlinedInside(r) }), caret: outlinedInside },
    { name: 'updates', texts: (r) => ({ 'Send me updates': tileTitle(r) }) },
    { name: 'send', texts: (r) => ({ Send: buttonInside(r, 12, 4) }) },
  ],
  'good-cupertino': [
    { name: 'email', texts: (r) => ({ Email: labelAbove(r), Required: cupertinoInside(r) }), caret: cupertinoInside },
    { name: 'send', texts: (r) => ({ Send: buttonInside(r, 10, 8) }) },
  ],
  'good-selection': ['Day', 'Week', 'Month'].map((v) => ({
    name: v.toLowerCase(), texts: (r) => ({ [v]: radioTitle(r) }), focus: (page) => focusRadio(page, v.toLowerCase()),
  })),
};
const STATE_NAMES = ['focused', 'hovered', 'focused and hovered', 'pressed'];

// FL-515: on the web, a press held with the mouse lowers some of the good
// examples' texts under 4.5:1 (the highlight, the hover, and the ripple
// over the control; the cause was not measured). These were measured under
// 4.5:1 in every run (docs/evidence/probes/v01/web_pressed.txt), and are
// asserted under it, so that the test fails when Flutter changes; every
// other text in every state is asserted 4.5:1 or more. Two readings at
// 0.3 s are only logged, as they are taken while the ripple is still
// spreading and moved across the threshold between runs: good-material's
// "Send" in light mode (4.52:1) and its "Send me updates" in dark mode
// (4.25:1 in two runs, 4.65:1 in a third). At 2 s each reading was the same
// as at 4 s.
const FL515 = new Set([
  'good-material|send|pressed 2 s|light',
  'good-material|updates|pressed 2 s|dark',
  'good-selection|day|pressed 2 s|dark',
  'good-selection|week|pressed 2 s|dark',
  'good-selection|month|pressed 2 s|dark',
]);
const LOGGED_ONLY = new Set([
  'good-material|send|pressed 0.3 s|light',
  'good-material|updates|pressed 0.3 s|dark',
]);

for (const mode of MODES) {
  test.describe(`the good examples' texts in each state, ${mode}`, () => {
    test.afterEach(async ({ page }) => restore(page));

    for (const [slug, controls] of Object.entries(STATE_CONTROLS)) {
      for (const state of STATE_NAMES) {
        test(`${slug}: each control's text 4.5:1 or more when ${state}${state === 'pressed' ? ', but for FL-515' : ''}`, async ({ page }) => {
          await openIn(page, slug, mode);
          // Each text's rectangle is found at rest, with nothing focused,
          // hovered, or pressed: a state's overlay, and a press's ripple
          // part way across, can join the letters to shapes that touch the
          // region's edge. The texts do not move in any of these states.
          const rest = await shot(page);
          const found = {};
          for (const c of controls) {
            found[c.name] = { r: await rectOf(control(page, slug, c.name)), boxes: {} };
            for (const [t, region] of Object.entries(c.texts(found[c.name].r))) {
              const box = inkBox(rest, px(region));
              expect(box, `${c.name} "${t}": nothing drawn at rest`).not.toBeNull();
              found[c.name].boxes[t] = box;
            }
          }
          for (const c of controls) {
            const locator = control(page, slug, c.name);
            const { r, boxes } = found[c.name];
            expect(await rectOf(locator), `${c.name} did not move`).toEqual(r);
            const measure = async (when) => {
              const s = c.caret ? await shotWithoutCaret(page, [c.caret(r)]) : await shot(page);
              for (const [t, box] of Object.entries(boxes)) {
                const m = textContrast(s, box);
                report(slug, `${c.name} "${t}"`, when, mode, m);
                const key = `${slug}|${c.name}|${when}|${mode}`;
                if (LOGGED_ONLY.has(key)) continue;
                if (FL515.has(key)) {
                  expect.soft(m.lowest, `FL-515 ${c.name} "${t}" ${when}: ${m.text}`).toBeLessThan(4.5);
                  expect.soft(m.lowest, `${c.name} "${t}" ${when} drawn`).toBeGreaterThan(1.5);
                } else {
                  expect.soft(m.lowest, `${c.name} "${t}" ${when}: ${m.text}`).toBeGreaterThanOrEqual(4.5);
                }
              }
            };
            if (state.includes('focused')) {
              expect(await (c.focus ?? ((p) => focusByTab(p, locator)))(page), `focus reaches ${c.name}`).toBe(true);
            }
            if (state.includes('hovered')) await page.mouse.move(r.cx, r.cy);
            if (state === 'pressed') {
              await page.mouse.move(r.cx, r.cy);
              await page.mouse.down();
              await page.waitForTimeout(300);
              await measure('pressed 0.3 s');
              await page.waitForTimeout(1700);
              await measure('pressed 2 s');
              await page.mouse.up();
            } else {
              await page.waitForTimeout(800);
              if (state.includes('focused')) expect(await hasFocus(locator), `${c.name} still has focus`).toBe(true);
              await measure(state);
            }
            await park(page);
            await page.waitForTimeout(400);
          }
        });
      }
    }
  });
}

const VO_HELP_PREFIX = /^You are currently on /;

// The VoiceOver judge (web_tests/vo/v01_vo_walks.js, S16's), on made-up
// walks. Each test names every case it holds, and fails on the first case
// whose verdict is not the one given, with the case's name.
test.describe('the VoiceOver example walks are judged on every walk', () => {
  const own = screenStops('bad-colour-only');
  const expected = EXPECTED_STOPS['bad-colour-only'];
  const [calendar, day, week, month] = expected;
  const HELP = 'You are currently on a button, inside of web content. To click this button, press Control-Option-Space.';
  const TEXT_FIELD_HELP = 'You are currently on a text field, inside of web content.';
  const HEADING_HELP = 'You are currently on a heading level 1, inside of web content.';
  const screen = (...content) => [...own, EXAMPLE_HEADING, ...content];
  const whole = screen(...expected);
  const n = whole.length;
  // One position per stop, each new but where `same` lists the stops (by
  // index) that are at the position of the stop before them.
  const at = (stops, same = []) => {
    const out = [];
    stops.forEach((_, i) => out.push(same.includes(i) ? out[i - 1] : `p${i}`));
    return out;
  };
  const check = (cases, judge) => {
    for (const [what, verdict, ...args] of cases) {
      expect(judge(...args).verdict, what).toBe(verdict);
    }
  };

  test('the judge: whole screens, wrong readings, short walks, and empty captures', () => {
    check([
      ['the whole screen, every stop in its place', 'complete', whole, true],
      ['a tile read without its role', 'wrong', screen(calendar, 'Day', week, month), true],
      ['the chosen tile read without its state', 'wrong', screen(calendar, day, 'Week button', month), true],
      ['a stop read in other words', 'wrong', screen('Calendar views', day, week, month), true],
      ['a tile missing', 'wrong', screen(calendar, day, month), true],
      ['the last stop missing', 'wrong', screen(calendar, day, week), true],
      ['the tiles in another order', 'wrong', screen(calendar, week, day, month), true],
      ['a stop after the last expected one', 'wrong', [...whole, 'Extra'], true],
      ['another example\'s screen', 'wrong', [...screenStops('bad-faint-edge'), EXAMPLE_HEADING, ...expected], true],
      ['an empty stop put in, so that every later stop comes late', 'wrong', screen('', ...expected), true],
      ['the title read as an empty phrase, every later stop right', 'incomplete', ['', ...own.slice(1), EXAMPLE_HEADING, ...expected], true],
      ['a tile read as an empty phrase, every other stop right', 'incomplete', screen(calendar, '', week, month), true],
      ['an empty first stop and a wrong reading later', 'wrong', ['', ...own.slice(1), EXAMPLE_HEADING, calendar, 'Day', week, month], true],
      ['an empty first stop and a walk that reached the end short', 'wrong', ['', ...own.slice(1), EXAMPLE_HEADING, calendar], true],
      ['an empty phrase after the last expected stop', 'wrong', [...whole, ''], true],
      ['every stop an empty phrase', 'incomplete', Array(n).fill(''), true],
      ['a help message with no positions recorded', 'wrong', [...whole, HELP], true],
      ['no title', 'wrong', [...own.slice(1), EXAMPLE_HEADING, ...expected], true],
      ['no heading', 'wrong', [...own, ...expected], true],
      ['an empty walk cut short', 'incomplete', [], false],
      ['a walk cut short after the heading', 'incomplete', screen(), false],
      ['every stop read, but the end not reached', 'incomplete', whole, false],
    ], (stops, reachedEnd) => judgeExampleWalk(stops, reachedEnd, expected, own));
  });

  test('a help message is left out only when tied to the stop before it, by position and spoken role', () => {
    const h = own.length + 1; // the index of the first stop after the heading
    check([
      ['help after the last tile\'s stop, at its position', 'complete',
        screen(calendar, day, week, month, HELP), at(screen(calendar, day, week, month, HELP), [h + 4])],
      ['help after the chosen tile\'s stop, at its position', 'complete',
        screen(calendar, day, week, HELP, month), at(screen(calendar, day, week, HELP, month), [h + 3])],
      ['help at a new position after the whole screen (an extra element)', 'wrong', [...whole, HELP], at([...whole, HELP])],
      ['a text field\'s help at a new position after the whole screen', 'wrong', [...whole, TEXT_FIELD_HELP], at([...whole, TEXT_FIELD_HELP])],
      ['button help after a text with no role, at its position', 'wrong', screen(calendar, HELP, day, week, month),
        at(screen(calendar, HELP, day, week, month), [h + 1])],
      ['help naming another role than the stop before it, at its position', 'wrong',
        screen(calendar, day, TEXT_FIELD_HELP, week, month), at(screen(calendar, day, TEXT_FIELD_HELP, week, month), [h + 2])],
      ['help in place of an expected stop', 'wrong', screen(calendar, day, HELP, month), at(screen(calendar, day, HELP, month))],
      ['help after an empty stop, at its position', 'wrong', screen(calendar, '', HELP, week, month),
        at(screen(calendar, '', HELP, week, month), [h + 2])],
      ['help with positions of the wrong length', 'wrong', screen(calendar, day, HELP, week, month), at(whole)],
      ['help and a wrong reading', 'wrong', screen(calendar, 'Day', HELP, week, month),
        at(screen(calendar, 'Day', HELP, week, month), [h + 2])],
      // helpRole gives "heading level 1", which is not spokenRole's
      // "heading": a made-up heading help is not left out (the rule errs
      // toward failing).
      ['a heading help with its level after the title, at its position', 'wrong', [own[0], HEADING_HELP, ...whole.slice(1)],
        at([own[0], HEADING_HELP, ...whole.slice(1)], [1])],
      ['button help after the title heading, at its position', 'wrong', [own[0], HELP, ...whole.slice(1)],
        at([own[0], HELP, ...whole.slice(1)], [1])],
      ['no help message', 'complete', whole, at(whole)],
    ], (stops, positions) => judgeExampleWalk(stops, true, expected, own, positions));
  });

  test('a reading\'s spoken role comes from its role part only, and a help message names its role', () => {
    const roles = [
      ['heading level 1 Choice shown by colour alone', 'heading'],
      ['heading level 2 Example', 'heading'],
      ['Week current item button', 'button'],
      ['Send button', 'button'],
      ['Send me updates unchecked checkbox', 'checkbox'],
      ['Day Not selected radio button, 1 of 3', 'radio button'],
      ['Calendar view radio group', 'radio group'],
      ['end of Calendar view radio group', null],
      ['Email edit text', 'text field'],
      ['Email Required edit text', 'text field'],
      ['Calendar view', null],
      ['Harbour', null],
      ['We reply within two days.', null],
      ['Good example for Colour contrast. Material.', null],
      ['Defect: The chosen view differs from the others only by colour.', null],
    ];
    for (const [reading, role] of roles) expect(spokenRole(reading), reading).toBe(role);
    expect(helpRole(HELP)).toBe('button');
    expect(helpRole(TEXT_FIELD_HELP)).toBe('text field');
    expect(helpRole('Calendar view')).toBe(null);
  });

  test('every screen: a bad example\'s own stops end with its defect, no screen has a custom solution note, and no expected stop is empty, help, or holds the row separator', () => {
    for (const slug of Object.keys(EXAMPLE_SCREENS)) {
      if (slug.startsWith('bad-')) expect(screenStops(slug).at(-1), slug).toMatch(/^Defect: /);
      expect(screenStops(slug).some((s) => s.startsWith('Custom solution')), slug).toBe(false);
    }
    for (const [slug, stops] of Object.entries(EXPECTED_STOPS)) {
      for (const s of [...screenStops(slug), ...stops]) {
        expect(s !== '' && !VO_HELP_PREFIX.test(s) && !s.includes(' / ') && !s.includes('\n'), `${slug}: "${s}"`).toBe(true);
      }
    }
    expect(Object.keys(EXPECTED_STOPS)).toEqual(Object.keys(EXAMPLE_SCREENS));
  });

  test('walks are made again only while incomplete, at most three, and every try is logged', async () => {
    const judge = (stops, reachedEnd) => judgeExampleWalk(stops, reachedEnd, expected, own);
    const right = { stops: whole, reachedEnd: true };
    const short = { stops: screen(calendar), reachedEnd: false };
    const wrong = { stops: screen(calendar, 'Day', week, month), reachedEnd: true };
    const emptyTitle = { stops: ['', ...own.slice(1), EXAMPLE_HEADING, ...expected], reachedEnd: true };
    const pastEnd = { stops: [...whole, ''], reachedEnd: true };
    const cases = [
      ['a wrong reading, then a right walk', [wrong, right], 'wrong', 1],
      ['a complete walk plus an empty stop past the end, then a right walk', [pastEnd, right], 'wrong', 1],
      ['an empty first stop, then a right walk', [emptyTitle, right], 'complete', 2],
      ['an empty first stop, then a wrong reading, then a right walk', [emptyTitle, wrong, right], 'wrong', 2],
      ['three empty captures, then a right walk', [emptyTitle, emptyTitle, emptyTitle, right], 'incomplete', 3],
      ['a short walk, then a wrong one, then a right one', [short, wrong, right], 'wrong', 2],
      ['a short walk, then a right one', [short, right], 'complete', 2],
      ['three short walks, then a right one', [short, short, short, right], 'incomplete', 3],
    ];
    for (const [what, walks, verdict, made] of cases) {
      let i = 0;
      const logged = [];
      const result = await runWalks(async () => walks[i++], judge, { log: (w, stops, judged) => logged.push([w, judged.verdict]) });
      expect(result.verdict, what).toBe(verdict);
      expect(i, `${what}: walks made`).toBe(made);
      expect(logged.map(([w]) => w), `${what}: every try logged`).toEqual(Array.from({ length: made }, (_, k) => k + 1));
    }
  });
});

// The walk (collectWalk in web_tests/vo/v01_vo_walks.js), driven by made-up
// screens and captures: a screen is a list of elements, each a phrase at a
// position; `next` and `previous` move a cursor over it, and `capture`
// reads what a capture function makes of the element the cursor is on.
test.describe('the VoiceOver walk keeps every unchanged read and needs a witness for its end', () => {
  const slug = 'bad-colour-only';
  const own = screenStops(slug);
  const expected = EXPECTED_STOPS[slug];
  const words = [...own, EXAMPLE_HEADING, ...expected];
  const at = (i) => `${10 + i}, ${100 + 20 * i}, 300, ${118 + 20 * i}`;
  // The capture before the first move: the walk begins on Back.
  const START = { phrase: 'Back button', position: '10, 60, 300, 78' };
  const WRONG_TITLE = 'heading level 1 Field with a faint edge';
  /** A screen of `elements` ({ phrase, position }) and a capture rule. */
  const drive = (elements, reads = (cursor, el, count) => el, max = 40) => {
    let cursor = -1;
    let count = 0;
    return collectWalk({
      next: async () => { cursor = Math.min(cursor + 1, elements.length - 1); },
      previous: async () => { cursor = Math.max(cursor - 1, 0); },
      capture: async () => { count++; return reads(cursor, elements[cursor], count); },
      start: START,
      max,
    });
  };
  const screen = words.map((phrase, i) => ({ phrase, position: at(i) }));
  const judge = (walk) => judgeCollectedWalk(walk, expected, own);

  test('made-up walks: a whole screen passes, and each fault fails or is not complete', async () => {
    const right = await drive(screen);
    expect(judge(right).verdict, 'the whole screen').toBe('complete');
    expect(right.witness.back).toEqual(screen.at(-2));
    expect(right.witness.forward).toEqual(screen.at(-1));
    expect(right.unresolved).toEqual([]);

    let frozenAt = -1;
    const cases = [
      // The capture froze at the heading: every later element reads as the
      // heading at its position, so the walk looks ended there, and the
      // move back reads the heading again at its own position.
      ['a frozen capture with elements after it', await drive(screen, (c, el) => {
        if (el.phrase === EXAMPLE_HEADING && frozenAt < 0) frozenAt = c;
        return frozenAt >= 0 ? screen[frozenAt] : el;
      }), 'wrong'],
      // From the heading on every read is an empty phrase at the heading's
      // position.
      ['empty phrases with frozen bounds', await drive(screen, (c, el) => (c >= own.length
        ? { phrase: '', position: at(own.length) } : el)), 'wrong'],
      // The move back at the end reads the last element again where it is.
      ['a wrong witness: the move back reads the last stop', await drive(screen, (c, el, n) => (n === words.length + 3
        ? screen.at(-1) : el)), 'wrong'],
      ['a wrong witness: the move back reads an empty phrase', await drive(screen, (c, el, n) => (n === words.length + 3
        ? { phrase: '', position: at(words.length - 2) } : el)), 'wrong'],
      ['a wrong witness: the move forward reads another place', await drive(screen, (c, el, n) => (n === words.length + 4
        ? { phrase: expected.at(-1), position: '1, 1, 1, 1' } : el)), 'wrong'],
      // One stale read at an element mid-walk (the previous phrase and
      // bounds), then the walk moves on: that element is never a stop.
      ['one stale read at an unexpected element mid-walk', await drive(
        [...screen.slice(0, own.length + 2), { phrase: 'Extra', position: at(90) }, ...screen.slice(own.length + 2)],
        (c, el) => (el.phrase === 'Extra' ? screen[own.length + 1] : el)), 'incomplete'],
      // One empty read at an element mid-walk, at the previous bounds.
      ['one empty read at an unexpected element mid-walk', await drive(
        [...screen.slice(0, own.length + 2), { phrase: 'Extra', position: at(90) }, ...screen.slice(own.length + 2)],
        (c, el) => (el.phrase === 'Extra' ? { phrase: '', position: screen[own.length + 1].position } : el)), 'incomplete'],
      // A repeated heading mid-walk at the heading's bounds.
      ['the Example heading read again mid-walk at its bounds', await drive(
        [...screen.slice(0, own.length + 1), { phrase: EXAMPLE_HEADING, position: at(own.length) }, ...screen.slice(own.length + 1)]), 'incomplete'],
      // A walk that runs out of moves is wrong for good (judgeWalk, rule 4).
      ['a walk that runs out of moves', await drive(screen, undefined, 3), 'wrong'],
    ];
    for (const [what, walk, verdict] of cases) {
      expect(judge(walk).verdict, `${what}: ${JSON.stringify(walk)}`).toBe(verdict);
    }
  });

  // S12's regression cases, carried over by S16, on V01's screens.
  const heading = own.length; // the index of the Example heading
  const extra = { phrase: 'Extra', position: at(90) };
  const injected = [...screen.slice(0, heading + 1), extra, ...screen.slice(heading + 1)];
  // A capture that loses the move onto the element at `index` of
  // `elements`, once: it reads the previous element again (stale), or an
  // empty phrase at the previous bounds. A later capture there, the end
  // witness's included, reads the element.
  const losing = (elements, index, as = 'stale') => {
    let lost = false;
    return (c, el) => {
      if (c !== index || lost) return el;
      lost = true;
      return as === 'stale' ? elements[index - 1] : { phrase: '', position: elements[index - 1].position };
    };
  };

  test('the reviewer\'s frozen capture, with elements after the last expected stop, would pass without the witness, and fails with it', async () => {
    const elements = [...screen, { phrase: 'Week current item button', position: at(80) }, extra];
    const walk = await drive(elements, (c, el) => (c >= screen.length ? screen.at(-1) : el));
    expect(walk.stops).toEqual(words);
    expect(judgeExampleWalk(walk.stops, true, expected, own).verdict).toBe('complete');
    expect(walk.witness.back).toEqual(screen.at(-1));
    expect(walk.problem).toMatch(/^the end is not witnessed/);
    expect(judge(walk).verdict).toBe('wrong');
  });

  test('a lost capture mid-walk (stale, or empty at the old bounds) is unresolved, and the walk is incomplete', async () => {
    for (const as of ['stale', 'empty']) {
      const walk = await drive(injected, losing(injected, heading + 1, as));
      expect(walk.stops, as).toEqual(words);
      expect(walk.reachedEnd, as).toBe(true);
      expect(walk.problem, as).toBeNull();
      // Without the unresolved read the stops would judge complete.
      expect(judgeExampleWalk(walk.stops, true, expected, own).verdict, as).toBe('complete');
      const phrase = as === 'empty' ? '' : EXAMPLE_HEADING;
      expect(walk.unresolved, as).toEqual([{ after: heading + 1, phrase, position: at(heading) }]);
      expect(judge(walk).verdict, as).toBe('incomplete');
      expect(unresolvedRow(slug, 1, walk.unresolved), as).toBe(
        `| \`${slug}-walk-1-unresolved\` | after stop ${heading + 1}: "${phrase}" at ${at(heading)} |`);
    }
  });

  test('a lost capture of an expected stop is unresolved too, so the walk is walked again', async () => {
    const lostAt = heading + 2; // Day button
    const walk = await drive(screen, losing(screen, lostAt));
    expect(walk.stops).toEqual(words.filter((_, i) => i !== lostAt));
    expect(walk.unresolved).toEqual([{ after: lostAt, phrase: words[lostAt - 1], position: at(lostAt - 1) }]);
    expect(judgeExampleWalk(walk.stops, true, expected, own).verdict).toBe('wrong');
    expect(judge(walk).verdict).toBe('incomplete');
  });

  test('a lost capture of the stop before the last fails the witness, and is wrong for good', async () => {
    const walk = await drive(screen, losing(screen, screen.length - 2));
    expect(walk.unresolved).toHaveLength(1);
    expect(walk.problem).toMatch(/^the end is not witnessed: a move back read/);
    expect(judge(walk).verdict).toBe('wrong');
  });

  // judgeWalk (web_tests/vo/v01_vo_walks.js): an unresolved read is a gap
  // in the walk, never a pass for what was captured around it.
  test('a wrong verdict wins over a gap, and a gap passes over at most the next expected stop', async () => {
    const wrongTitle = [{ phrase: WRONG_TITLE, position: at(0) }, ...screen.slice(1)];
    const extraFirst = [...screen.slice(0, heading + 1), extra, { phrase: 'Extra 2', position: at(91) }, ...screen.slice(heading + 1)];
    const cases = [
      ['a wrong title, then one stale read', await drive(wrongTitle, losing(wrongTitle, 2)), 'wrong'],
      ['a wrong title, then one empty read', await drive(wrongTitle, losing(wrongTitle, 2, 'empty')), 'wrong'],
      // An extra stop captured before the read that was lost.
      ['an extra stop before the lost read', await drive(extraFirst, losing(extraFirst, heading + 2)), 'wrong'],
      // A wrong stop captured after the gap.
      ['a wrong stop after the gap', await drive(
        [...screen.slice(0, heading + 1), extra, { phrase: 'Wrong', position: at(92) }, ...screen.slice(heading + 2)],
        losing([...screen.slice(0, heading + 1), extra], heading + 1)), 'wrong'],
      // A right prefix, one lost read, then the next expected stop (the
      // lost read was an extra element) or the one after it (the lost read
      // was the next expected stop): both stay incomplete.
      ['a right prefix, one lost extra element, then the next expected stop', await drive(injected, losing(injected, heading + 1)), 'incomplete'],
      ['a right prefix, one lost expected stop, then the one after it', await drive(screen, losing(screen, heading + 1)), 'incomplete'],
    ];
    for (const [what, walk, verdict] of cases) {
      expect(judge(walk).verdict, `${what}: ${JSON.stringify(walk.stops)} ${JSON.stringify(walk.unresolved)}`).toBe(verdict);
    }
  });

  // S16's fourth review's reproduction: the first capture reads a wrong
  // title at the start's bounds (Back's, which had not changed yet).
  // Compared with the start capture, its words are new, so it is a stop,
  // judged wrong.
  test('a wrong first title at the start bounds is a stop, judged wrong, not a gap', async () => {
    const atStart = (c, el, n) => (n === 1 ? { phrase: WRONG_TITLE, position: START.position } : el);
    const elements = [{ phrase: 'x', position: START.position }, ...screen.slice(1)];
    const walk = await drive(elements, atStart);
    expect(walk.unresolved).toEqual([]);
    expect(walk.stops[0]).toBe(WRONG_TITLE);
    expect(judge(walk).verdict).toBe('wrong');
    // A first capture that repeats the start at its bounds is a gap, and
    // the next stop the title: incomplete, walked again.
    const repeat = await drive([{ phrase: 'x', position: START.position }, ...screen],
      (c, el, n) => (n === 1 ? START : el));
    expect(repeat.unresolved).toEqual([{ after: 0, phrase: START.phrase, position: START.position }]);
    expect(judge(repeat).verdict).toBe('incomplete');
    // No unresolved read carries words other than the previous stop's.
    for (const w of [walk, repeat]) {
      for (const u of w.unresolved) expect([w.stops[u.after - 1] ?? START.phrase, '']).toContain(u.phrase);
    }
  });

  test('in the retry loop a wrong first title at the start bounds ends the example, and a clean retry is never made', async () => {
    const atStart = (c, el, n) => (n === 1 ? { phrase: WRONG_TITLE, position: START.position } : el);
    const walks = [await drive([{ phrase: 'x', position: START.position }, ...screen.slice(1)], atStart), await drive(screen)];
    let i = 0;
    let latest;
    const result = await runWalks(async () => { latest = walks[i++]; return latest; }, () => judge(latest));
    expect(result.verdict).toBe('wrong');
    expect(i).toBe(1);
  });

  test('in the retry loop a wrong walk with a gap ends the example, and a clean walk after it is never made', async () => {
    const wrongTitle = [{ phrase: WRONG_TITLE, position: at(0) }, ...screen.slice(1)];
    for (const as of ['stale', 'empty']) {
      const walks = [await drive(wrongTitle, losing(wrongTitle, 2, as)), await drive(screen)];
      let i = 0;
      let latest;
      const result = await runWalks(async () => { latest = walks[i++]; return latest; }, () => judge(latest));
      expect(result.verdict, as).toBe('wrong');
      expect(i, as).toBe(1);
    }
    // A walk that ran out of moves, then a clean one: wrong, one walk made.
    const walks = [await drive(screen, undefined, 3), await drive(screen)];
    let i = 0;
    let latest;
    const result = await runWalks(async () => { latest = walks[i++]; return latest; }, () => judge(latest));
    expect(result.verdict).toBe('wrong');
    expect(i).toBe(1);
    // A walk with a gap and nothing wrong, then a clean one: complete on the second.
    const healed = [await drive(injected, losing(injected, heading + 1)), await drive(screen)];
    i = 0;
    const again = await runWalks(async () => { latest = healed[i++]; return latest; }, () => judge(latest));
    expect(again).toMatchObject({ verdict: 'complete', walks: 2 });
  });

  test('an unchanged read at the true end is the end, through the witness, and logged', async () => {
    const walk = await drive(screen);
    expect(walk.reachedEnd).toBe(true);
    expect(unresolvedRow(slug, 1, walk.unresolved)).toBe(`| \`${slug}-walk-1-unresolved\` | none |`);
    expect(endRow(slug, 1, walk.witness)).toBe(
      `| \`${slug}-walk-1-end\` | back "${words.at(-2)}" at ${at(words.length - 2)} / forward "${words.at(-1)}" at ${at(words.length - 1)} |`);
    const lost = await drive(injected, losing(injected, heading + 1));
    expect(lost.reachedEnd).toBe(true);
    expect(lost.witness).toEqual({ back: screen.at(-2), forward: screen.at(-1) });
    expect(judge(lost).verdict).toBe('incomplete');
  });
});

// The committed web VoiceOver transcript, judged again from its rows alone
// (judgeTranscript in web_tests/vo/v01_vo_walks.js), never skipped: every
// browser and example once, walks in order, the last complete, with its end
// witness row and its unresolved-reads row. Made-up transcripts test the
// judge first.
test.describe('the web VoiceOver transcript is judged again from what it recorded', () => {
  const FIRST = 'good-material';
  const whole = (slug) => [...screenStops(slug), EXAMPLE_HEADING, ...EXPECTED_STOPS[slug]];
  const witness = (slug) => {
    const w = whole(slug);
    return { back: { phrase: w.at(-2), position: '10, 300, 300, 318' }, forward: { phrase: w.at(-1), position: '10, 320, 300, 338' } };
  };
  const BACK = { phrase: 'Back button', position: '10, 60, 300, 78' };
  const rowsOf = (slug, n = 1) => [transcriptRow(slug, n, whole(slug), 'complete', 'the whole screen, every stop in its place'),
    startRow(slug, n, BACK),
    endRow(slug, n, witness(slug)), unresolvedRow(slug, n, [])];
  const section = (browser, rows) => ['', `## ${browser}`, '', '| Example | Spoken, in order |', '| --- | --- |', ...rows];
  const transcript = (rowsFor) => ['# V01 Colour contrast: VoiceOver transcript (web, macOS)', '',
    'Result: PASS', ...BROWSERS.flatMap((b) => section(b, rowsFor(b)))].join('\n');
  const right = () => Object.keys(EXAMPLE_SCREENS).flatMap((slug) => rowsOf(slug));
  const rest = () => Object.keys(EXAMPLE_SCREENS).slice(1).flatMap((x) => rowsOf(x));
  const short = (slug) => [transcriptRow(slug, 1, whole(slug).slice(0, 3), 'incomplete', 'cut short'), startRow(slug, 1, BACK), unresolvedRow(slug, 1, [])];
  const startsWith = (prefix, replacement) => () => right().map((r) => (r.startsWith(prefix) ? replacement : r));

  test('made-up transcripts: a right one passes, and each wrong one names its problem', () => {
    expect(Object.keys(EXAMPLE_SCREENS)[0]).toBe(FIRST);
    const first = transcriptRow(FIRST, 1, whole(FIRST), 'complete', 'x');
    const cases = [
      ['a whole walk of every example in both browsers', transcript(right), true],
      // A first walk that ran out of moves (no end row) is wrong for good,
      // and a complete second walk cannot rescue it.
      ['a first walk exhausted at the move limit, then a complete second', transcript(() => [...short(FIRST),
        ...rowsOf(FIRST, 2), ...rest()]), false],
      ['an empty transcript', '', false],
      ['every end row removed', transcript(() => right().filter((r) => !r.includes('-end`'))), false],
      ['every unresolved-reads row removed', transcript(() => right().filter((r) => !r.includes('-unresolved`'))), false],
      ['an end row whose positions are one word', transcript(startsWith(`| \`${FIRST}-walk-1-end\``,
        `| \`${FIRST}-walk-1-end\` | back "x" at here / forward "y" at here |`)), false],
      ['an end witness that read back the last stop', transcript(startsWith(`| \`${FIRST}-walk-1-end\``,
        endRow(FIRST, 1, { back: witness(FIRST).forward, forward: witness(FIRST).forward }))), false],
      ['an end witness that read back an empty phrase', transcript(startsWith(`| \`${FIRST}-walk-1-end\``,
        endRow(FIRST, 1, { back: { phrase: '', position: '1, 2, 3, 4' }, forward: witness(FIRST).forward }))), false],
      ['the last walk with an unresolved read', transcript(startsWith(`| \`${FIRST}-walk-1-unresolved\``,
        unresolvedRow(FIRST, 1, [{ after: 3, phrase: '', position: '1, 2, 3, 4' }]))), false],
      ['sixteen copies of one row', transcript(() => Array(8).fill(first)), false],
      ['one walk row twice', transcript(() => [...right(), first]), false],
      ['an example missing in one browser', transcript((b) => (b === 'webkit' ? right().slice(4) : right())), false],
      ['a browser section missing', ['Result: PASS', ...section('chromium', right())].join('\n'), false],
      ['an unknown browser section', [transcript(right), ...section('firefox', [])].join('\n'), false],
      ['an unknown example', transcript(() => [...right(), transcriptRow('good-other', 1, whole(FIRST), 'complete', 'x')]), false],
      ['a malformed row', transcript(() => [...right(), `| \`${FIRST}-walk-x\` | something |`]), false],
      ['a row outside any section', [first, transcript(right)].join('\n'), false],
      ['walk 2 with no walk 1', transcript(() => right().map((r) => r.replace(`${FIRST}-walk-1`, `${FIRST}-walk-2`))), false],
      ['the last walk recorded wrong', transcript(() => right().map((r) => (r.startsWith(`| \`${FIRST}-walk-1\``) ? r.replace('(complete:', '(wrong:') : r))), false],
      ['only what follows the heading', transcript(() => Object.keys(EXAMPLE_SCREENS).flatMap((slug) => [
        transcriptRow(slug, 1, EXPECTED_STOPS[slug], 'complete', 'x'), startRow(slug, 1, BACK), endRow(slug, 1, witness(slug)), unresolvedRow(slug, 1, [])])), false],
      ['another example\'s screen stops', transcript(startsWith(`| \`${FIRST}-walk-1\``,
        transcriptRow(FIRST, 1, [...screenStops('bad-caption'), EXAMPLE_HEADING, ...EXPECTED_STOPS[FIRST]], 'complete', 'x'))), false],
      // bad-colour-only's chosen tile read without its state.
      ['the chosen tile read as a plain button', transcript(startsWith('| `bad-colour-only-walk-1`', transcriptRow('bad-colour-only', 1,
        whole('bad-colour-only').map((s) => (s === 'Week current item button' ? 'Week button' : s)), 'complete', 'x'))), false],
      // S12's cases, carried over by S16.
      ['a walk whose title is an empty phrase', transcript(startsWith(`| \`${FIRST}-walk-1\``,
        transcriptRow(FIRST, 1, ['', ...whole(FIRST).slice(1)], 'complete', 'x'))), false],
      ['an end witness whose move back read the right words at the last position', transcript(startsWith(`| \`${FIRST}-walk-1-end\``,
        endRow(FIRST, 1, { back: { phrase: witness(FIRST).back.phrase, position: witness(FIRST).forward.position }, forward: witness(FIRST).forward }))), false],
      ['an end witness whose move forward read another stop', transcript(startsWith(`| \`${FIRST}-walk-1-end\``,
        endRow(FIRST, 1, { back: witness(FIRST).back, forward: { phrase: 'Extra', position: witness(FIRST).forward.position } }))), false],
      ['an end witness row twice', transcript(() => [...right(), endRow(FIRST, 1, witness(FIRST))]), false],
      ['an end witness row for a walk that is not there', transcript(() => [...right(), endRow(FIRST, 2, witness(FIRST))]), false],
      ['an unresolved-reads row twice', transcript(() => [...right(), unresolvedRow(FIRST, 1, [])]), false],
      ['an unresolved-reads row for a walk that is not there', transcript(() => [...right(), unresolvedRow(FIRST, 2, [])]), false],
      ['a first walk with no unresolved-reads row, walked again', transcript(() => [
        transcriptRow(FIRST, 1, whole(FIRST).slice(0, 3), 'incomplete', 'cut short'),
        ...rowsOf(FIRST, 2), ...rest()]), false],
      ['a first walk with an unresolved read, witnessed at its end, recorded incomplete though its stops judge complete, then complete', transcript(() => [
        transcriptRow(FIRST, 1, whole(FIRST), 'incomplete', 'unresolved'),
        startRow(FIRST, 1, BACK),
        endRow(FIRST, 1, witness(FIRST)),
        unresolvedRow(FIRST, 1, [{ after: 3, phrase: '', position: '1, 2, 3, 4' }]),
        ...rowsOf(FIRST, 2), ...rest()]), true],
      // S16's fourth review's cases: an unresolved read hides no words.
      ['a first walk whose unresolved read after the start read a wrong title, then a clean walk', transcript(() => [
        transcriptRow(FIRST, 1, whole(FIRST).slice(1), 'incomplete', 'unresolved'),
        startRow(FIRST, 1, BACK),
        endRow(FIRST, 1, witness(FIRST)),
        unresolvedRow(FIRST, 1, [{ after: 0, phrase: 'heading level 1 Field with a faint edge', position: BACK.position }]),
        ...rowsOf(FIRST, 2), ...rest()]), false],
      ['an unresolved read mid-walk whose words differ from the stop before it', transcript(() => [
        transcriptRow(FIRST, 1, whole(FIRST), 'incomplete', 'unresolved'),
        startRow(FIRST, 1, BACK),
        endRow(FIRST, 1, witness(FIRST)),
        unresolvedRow(FIRST, 1, [{ after: 3, phrase: 'Extra', position: '1, 2, 3, 4' }]),
        ...rowsOf(FIRST, 2), ...rest()]), false],
      ['an unresolved read after the start that repeats the start, then complete', transcript(() => [
        transcriptRow(FIRST, 1, whole(FIRST), 'incomplete', 'unresolved'),
        startRow(FIRST, 1, BACK),
        endRow(FIRST, 1, witness(FIRST)),
        unresolvedRow(FIRST, 1, [{ after: 0, phrase: BACK.phrase, position: BACK.position }]),
        ...rowsOf(FIRST, 2), ...rest()]), true],
      ['every start row removed', transcript(() => right().filter((r) => !r.includes('-start`'))), false],
      ['a start row twice', transcript(() => [...right(), startRow(FIRST, 1, BACK)]), false],
      ['a start row whose position is one word', transcript(startsWith(`| \`${FIRST}-walk-1-start\``,
        `| \`${FIRST}-walk-1-start\` | "Back button" at here |`)), false],
      ['a first walk with an unresolved read recorded complete, then complete', transcript(() => [
        transcriptRow(FIRST, 1, whole(FIRST), 'complete', 'x'),
        unresolvedRow(FIRST, 1, [{ after: 3, phrase: '', position: '1, 2, 3, 4' }]),
        ...rowsOf(FIRST, 2), ...rest()]), false],
      // judgeWalk's regressions in a transcript: each first walk fails the
      // transcript despite the complete second.
      ...[
        ['a wrong title, then one stale read', ['heading level 1 Field with a faint edge', ...whole(FIRST).slice(1)], 2],
        ['a wrong stop after the gap', [...whole(FIRST).slice(0, 3), 'Extra', ...whole(FIRST).slice(4)], 3],
      ].map(([what, stops, after]) => [`${what}, witnessed, then a complete walk`, transcript(() => [
        transcriptRow(FIRST, 1, stops, 'incomplete', 'unresolved'),
        endRow(FIRST, 1, witness(FIRST)),
        unresolvedRow(FIRST, 1, [{ after, phrase: 'x', position: '1, 2, 3, 4' }]),
        ...rowsOf(FIRST, 2), ...rest()]), false]),
      ['an unresolved-reads row whose position is one word', transcript(startsWith(`| \`${FIRST}-walk-1-unresolved\``,
        `| \`${FIRST}-walk-1-unresolved\` | after stop 3: "x" at here |`)), false],
      ['a wrong first walk followed by a complete one', transcript(() => [
        transcriptRow(FIRST, 1, ['x'], 'wrong', 'x'), unresolvedRow(FIRST, 1, []),
        ...rowsOf(FIRST, 2), ...rest()]), false],
    ];
    for (const [what, text, ok] of cases) {
      const problems = judgeTranscript(text);
      expect(problems.length === 0, `${what}: ${problems.join('; ')}`).toBe(ok);
    }
  });

  test('the committed recording (docs/evidence/V01/voiceover-web.md) is right, every browser and example once', () => {
    // Never skipped: a missing file fails here, with what to do.
    const file = new URL('../docs/evidence/V01/voiceover-web.md', import.meta.url);
    expect(fs.existsSync(file),
      'docs/evidence/V01/voiceover-web.md is missing: the web VoiceOver recording has not been made yet '
      + '(python3 tool/voiceover_web.py V01, run by the principal only)').toBe(true);
    expect(judgeTranscript(fs.readFileSync(file, 'utf8'))).toEqual([]);
  });
});
