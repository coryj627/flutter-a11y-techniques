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
//   The box found is the ink's own rectangle, not grown: Android's layer
//   grows it by 2 pixels (the spec, section 6, says "grown by 2 pixels"),
//   the web's and iOS's do not.
// - The text's colour is the commonest text pixel; where two colours are
//   equally common, the first met, columns left to right and each column
//   top to bottom, as in the widget tests.
// - A focused field draws a blinking cursor; each screenshot of a field is
//   taken when the cursor is not drawn in it (caretFree), at most 3 s.
// - The checkbox and the radio buttons have no element of their own (each
//   is merged into its tile), so each is found as the shape drawn in the
//   tile's control part (inkBox again), and the edge measure walks from 4
//   logical pixels outside it (the widget tests walk from inside the
//   Checkbox's or Radio's own rectangle). Every walk checks that it begins
//   on the page's colour, and fails if not.
// - bad-caption's dark end is read 8 logical pixels past the caption's ink
//   box on the same line (the widget tests read 4 pixels inside the
//   GridTileBar's right end); bad-colour-only's "nothing else drawn" leaves
//   out the title's ink box grown by 2 logical pixels (the widget tests,
//   its paragraph grown by 2 pixels).
// - The light and dark modes are the browser's own setting
//   (page.emulateMedia({ colorScheme })), which the app follows (it sets no
//   themeMode). Each test reads the scheme the page had first, sets the
//   mode, checks that the media query matches and that the page is drawn in
//   the mode's colour (#FBF8FF, #121318) before it measures, and afterwards,
//   pass or fail, sets back the scheme it read and checks the media query
//   and the page's colour again.
//
// States: every example at rest, light and dark; then, for the good
// examples' texts, light and dark: keyboard focus on each control, a mouse
// hover, focus and hover together, and a mouse button held down, measured
// after 2 s and after 4 s, each from a steady screenshot, the two required
// to agree.
// Focus is by Tab, except good-selection's Day, which no Tab or Shift+Tab
// reaches (measured below): it is focused by Up from Week, which chooses it
// too, and Down puts the choice back on Week. The mouse is moved off every
// control before each keyboard step (FL-484). The text cursor of a focused
// field is not measured (it is not text, and it blinks).
//
// Each state is shown set before a pixel is read, by a witness that is not
// the measured text: focus by the page's focus (document.activeElement); a
// hover by the mouse cursor Flutter sets on the page's body for the control
// under the mouse ("text" over a field, "pointer" over a button or a tile;
// none over nothing), since a Cupertino field draws nothing on a hover; a
// press by the focus a mouse button pressed on a control gives it, which it
// did not have before, and the cursor. A choice or a check is shown by the
// element's state in the tree, and a mode by the page's colour. Each state
// is then undone: the mouse is moved off the control before the button is
// let go (so the press is no click: nothing is checked or chosen), focus is
// moved to Back with Shift+Tab, a choice or a check is put back as it was;
// and the undoing is checked: no cursor, focus on Back, the state in the
// tree as at first, and every pixel of the control and its texts as in the
// screenshot at rest. Every measure is taken from two screenshots, 250 ms
// apart, that agree in every pixel of what is measured (steadyShot), so
// that no state still moving is measured.
import fs from 'node:fs';
import zlib from 'node:zlib';
import { test, expect } from '@playwright/test';
import { voiceOverRunning, withVoiceOverState } from './vo/v01_vo_state.js';
import { byId, technique } from './support/techniques.js';
import {
  BROWSERS, EXAMPLE_HEADING, EXAMPLE_SCREENS, EXPECTED_STOPS, FIELD_PATTERN, REREAD, TRANSCRIPT_ROWS, VO_HELP,
  collectWalk, endRow, helpRole, isFieldWithHint, isMarkedField, judgeCollectedWalk, judgeExampleWalk, judgeTranscript,
  judgeWalk, matchesStop, positionsOf, positionsRow, readingOf, rereadAt, runWalks, screenStops, splitReadings,
  spokenRole, spokenText, startRow, stopsOf, stopsText, transcriptRow, unresolvedRow, walkLogLines, walkReadings,
  wholeScreen, witnessBackHolds, witnessForwardHolds,
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

// The thresholds, as each criterion is written. No text in these examples
// is large text (18 point, or 14 point bold), and none is disabled, so
// 1.4.3's 3:1 for large text and its exception for inactive components do
// not apply.
/** 1.4.3 Contrast (Minimum): text against its background. */
const TEXT = { min: 4.5, sc: '1.4.3, 4.5:1' };
/** 1.4.11 Non-text Contrast: a control's boundary, its state marks, against what is next to them. */
const NON_TEXT = { min: 3, sc: '1.4.11, 3:1' };
/**
 * 1.4.1 Use of Color: colour must not be the only visual means of showing
 * a state; Understanding 1.4.1 counts a lightness difference of 3:1 or more
 * between the colours as more than colour (the spec, section 3, R6).
 */
const USE_OF_COLOR = { min: 3, sc: '1.4.1, 3:1 lightness difference' };
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
  // The commonest; of two as common, the first met (the Map keeps the order
  // the pixels were met in), as the widget tests' reduce keeps the first.
  let colour = 0, most = -1;
  for (const [c, n] of counts) if (n > most) { colour = c; most = n; }
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

/** The pixels of `regions` (logical) where `s` differs from `base` by more than `by` in some channel. */
function changedIn(s, base, regions, by = 12) {
  let n = 0;
  const seen = new Set();
  for (const region of regions) {
    const a = px(region);
    for (let y = Math.max(0, Math.floor(a.top)); y < Math.min(s.height, Math.ceil(a.bottom)); y++) {
      for (let x = Math.max(0, Math.floor(a.left)); x < Math.min(s.width, Math.ceil(a.right)); x++) {
        const i = y * s.width + x;
        if (seen.has(i)) continue;
        seen.add(i);
        if (diff(s.at(x, y), base.at(x, y)) > by) n++;
      }
    }
  }
  return n;
}

/**
 * A screenshot to measure: the later of two in a row, 250 ms apart, each
 * with no text cursor drawn in `caret` (logical regions), that agree in
 * every pixel of `regions` (logical), so that what is measured is no longer
 * moving. Fails if no two agree within 5 s.
 */
async function steadyShot(page, regions, caret = []) {
  const take = () => (caret.length ? shotWithoutCaret(page, caret) : shot(page));
  let last = await take();
  for (let i = 0; i < 20; i++) {
    await page.waitForTimeout(250);
    const now = await take();
    if (changedIn(now, last, regions, 0) === 0) return now;
    last = now;
  }
  throw new Error(`what is measured did not stay still for 250 ms within 5 s: ${JSON.stringify(regions)}`);
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

/** The colour scheme the page's media query matches now: "light" or "dark". */
const schemeOf = (page) => page.evaluate(() => (matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'));

/** page -> the colour scheme it had before openIn set one, and whether the example opened. */
const before = new WeakMap();

/**
 * Reads the browser's colour scheme, sets it to `mode`, opens `slug`, and
 * checks that the media query matches and that the page is drawn in the
 * mode's colour.
 */
async function openIn(page, slug, mode) {
  before.set(page, { scheme: await schemeOf(page), opened: false });
  await page.emulateMedia({ colorScheme: mode });
  await open(page, slug);
  before.get(page).opened = true;
  await park(page);
  expect(await page.evaluate((m) => matchMedia(`(prefers-color-scheme: ${m})`).matches, mode), `the media query matches ${mode}`).toBe(true);
  await expect.poll(async () => hex(pageColour(await shot(page))), { message: `the page is drawn ${mode}` }).toBe(hex(PAGE[mode]));
}

/**
 * Sets the colour scheme back to the one openIn read, and checks it took:
 * the media query, and, once the example had opened, the page's colour.
 * Run after every test, pass or fail.
 */
async function restore(page) {
  const was = before.get(page);
  if (!was) return;
  before.delete(page);
  await page.emulateMedia({ colorScheme: was.scheme });
  expect(await schemeOf(page), `the media query matches ${was.scheme} again`).toBe(was.scheme);
  if (was.opened) {
    await expect.poll(async () => hex(pageColour(await shot(page))), { message: `the page is drawn ${was.scheme} again` }).toBe(hex(PAGE[was.scheme]));
  }
}

/** Whether keyboard focus is on `locator`'s element or inside it. */
const hasFocus = (locator) => locator.evaluate((e) => e.contains(document.activeElement));

/**
 * The mouse cursor Flutter has set for what is under the mouse: the page's
 * body's cursor style, "text" over a field, "pointer" over a button or a
 * tile, "" over nothing (seen in Chromium with this build). The witness of
 * a hover: Flutter's own record of the control under the mouse.
 */
const cursorOf = (page) => page.evaluate(() => document.body.style.cursor);

/** The screen's Back button. */
const backButton = (page) => page.getByRole('button', { name: 'Back', exact: true });

/**
 * Moves focus to Back with Shift+Tab, the mouse off every control, and
 * checks it is there: how a test undoes a focus, a keyboard one or the one a
 * mouse press gives.
 */
async function focusBack(page) {
  await park(page);
  for (let i = 0; i < 12 && !(await hasFocus(backButton(page))); i++) {
    const was = await page.evaluateHandle(() => document.activeElement);
    await page.keyboard.press('Shift+Tab');
    await page.waitForFunction((e) => document.activeElement !== e, was, { timeout: 1000 }).catch(() => {});
    await page.waitForTimeout(100);
  }
  expect(await hasFocus(backButton(page)), 'focus is back on Back').toBe(true);
}

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

/** The whole of every screenshot, in logical pixels. */
const WHOLE = { left: 0, top: 0, right: CLIP.width, bottom: CLIP.height };

/** Expects a text's measure to meet 1.4.3's 4.5:1. */
const expectText = (m, what) => expect(m.lowest, `${TEXT.sc}: "${what}": ${m.text}`).toBeGreaterThanOrEqual(TEXT.min);

/** Expects an edge's contrast `q` (one side of the walk `e`) to meet 1.4.11's 3:1. */
const expectNonText = (q, what, e) => expect(q, `${NON_TEXT.sc}: ${what}: ${e.text}`).toBeGreaterThanOrEqual(NON_TEXT.min);

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
      const s = await steadyShot(page, [WHOLE], [outlinedInside(field)]);
      for (const [t, m] of [
        ['We reply within two days.', textContrast(s, px(body))],
        ['Email', textIn(s, outlinedLabel(field))],
        ['Required', textIn(s, outlinedInside(field))],
        ['Send me updates', textIn(s, tileTitle(tile))],
        ['Send', textIn(s, buttonInside(send, 12, 4))],
      ]) {
        report(slug, `"${t}"`, 'rest', mode, m);
        expectText(m, t);
      }
      const e = edge(s, field.left * DPR - 12, field.cy * DPR, 1, 0, 30);
      report(slug, 'field', 'rest', mode, e);
      expectOnPage(e, mode, 'field');
      expectNonText(e.outside, 'the field\'s edge against the page', e);
      const box = shapeIn(s, tileCheckbox(tile), 'the checkbox');
      const boxEdge = edge(s, (box.right + 4) * DPR, box.cy * DPR, -1, 0, 30);
      report(slug, 'checkbox', 'rest', mode, boxEdge);
      expectOnPage(boxEdge, mode, 'checkbox');
      expectNonText(boxEdge.outside, 'the checkbox\'s border against the page', boxEdge);
      const outline = edge(s, send.left * DPR - 6, send.cy * DPR, 1, 0, 30);
      report(slug, 'outline', 'rest', mode, outline);
      expectOnPage(outline, mode, 'outline');
      expectNonText(outline.outside, 'the button\'s outline against the page', outline);
    });

    test('good-material: the checkbox checked, its fill 3:1 or more against the page and its mark 3:1 or more against the fill; unchecked again after', async ({ page }) => {
      const slug = 'good-material';
      await openIn(page, slug, mode);
      const updates = control(page, slug, 'updates');
      await expect(updates).not.toBeChecked();
      await updates.click();
      // The witness: the checkbox's state in the tree. The click's focus is
      // moved to Back, so that what is measured is checked, not focused.
      await expect(updates).toBeChecked();
      await focusBack(page);
      const tile = await rectOf(updates);
      const s = await steadyShot(page, [WHOLE]);
      const box = shapeIn(s, tileCheckbox(tile), 'the checkbox');
      const fill = edge(s, (box.right + 4) * DPR, box.cy * DPR, -1, 0, 30);
      report(slug, 'checked fill', 'rest', mode, fill);
      expectOnPage(fill, mode, 'fill');
      expectNonText(fill.outside, 'the checked fill against the page', fill);
      const mark = marks(s, { left: box.cx - 5, top: box.cy - 5, right: box.cx + 5, bottom: box.cy + 5 }, fill.edge);
      console.log(`V01 web ${slug} checked mark rest ${mode}: ${mark} pixels 3:1 or more against ${hex(fill.edge)}`);
      expect(mark, `${NON_TEXT.sc}: a mark 3:1 or more against the fill ${hex(fill.edge)}`).toBeGreaterThan(30);
      const m = textIn(s, tileTitle(tile));
      report(slug, '"Send me updates" checked', 'rest', mode, m);
      expectText(m, 'Send me updates');
      // Undone: unchecked again, and the page's focus off the tile.
      await updates.click();
      await expect(updates).not.toBeChecked();
      await focusBack(page);
      expect(await hasFocus(updates), 'the tile no longer has focus').toBe(false);
    });

    test('good-cupertino: the label, the placeholder, and the button\'s text 4.5:1 or more; the field\'s edge 3:1 or more against the page and the field', async ({ page }) => {
      const slug = 'good-cupertino';
      await openIn(page, slug, mode);
      const field = await rectOf(control(page, slug, 'email'));
      const send = await rectOf(control(page, slug, 'send'));
      const s = await steadyShot(page, [WHOLE], [cupertinoInside(field)]);
      for (const [t, m] of [
        ['Email', textIn(s, labelAbove(field))],
        ['Required', textIn(s, cupertinoInside(field))],
        ['Send', textIn(s, buttonInside(send, 10, 8))],
      ]) {
        report(slug, `"${t}"`, 'rest', mode, m);
        expectText(m, t);
      }
      const e = edge(s, field.left * DPR - 6, field.cy * DPR, 1, 0, 18);
      report(slug, 'field', 'rest', mode, e);
      expectOnPage(e, mode, 'field');
      expectNonText(e.outside, 'the field\'s edge against the page', e);
      expectNonText(e.inside, 'the field\'s edge against the field', e);
    });

    test('good-caption: the caption 4.5:1 or more over the whole picture', async ({ page }) => {
      const slug = 'good-caption';
      await openIn(page, slug, mode);
      const s = await steadyShot(page, [WHOLE]);
      const m = textContrast(s, px(await rectOf(page.getByText('Harbour', { exact: true }))));
      report(slug, '"Harbour"', 'rest', mode, m);
      expectText(m, 'Harbour');
    });

    test('good-selection: each option 4.5:1 or more, each radio button\'s ring 3:1 or more, only the chosen one has a dot; a click on Day moves the dot, and one on Week moves it back', async ({ page }) => {
      const slug = 'good-selection';
      await openIn(page, slug, mode);
      const radio = (v) => control(page, slug, v.toLowerCase());
      const dots = async (when) => {
        const s = await steadyShot(page, [WHOLE]);
        const out = {};
        for (const v of ['Day', 'Week', 'Month']) {
          const tile = await rectOf(radio(v));
          const ring = shapeIn(s, radioRing(tile), `${v}'s radio button`);
          const e = edge(s, (ring.left - 4) * DPR, ring.cy * DPR, 1, 0, Math.round((4 + (ring.right - ring.left) / 2) * DPR));
          report(slug, `${v} ring ${when}`, 'rest', mode, e);
          expectOnPage(e, mode, `${v} ring`);
          expectNonText(e.outside, `${v}'s ring against the page`, e);
          const title = textIn(s, radioTitle(tile));
          report(slug, `"${v}" ${when}`, 'rest', mode, title);
          expectText(title, v);
          // The dot: the middle of the ring, 4 logical pixels each way.
          out[v] = marks(s, { left: ring.cx - 4, top: ring.cy - 4, right: ring.cx + 4, bottom: ring.cy + 4 }, PAGE[mode]);
        }
        console.log(`V01 web ${slug} dots ${when} ${mode}: ${JSON.stringify(out)}`);
        return out;
      };
      // The dot is a mark of 1.4.11 (the state of the radio button), 3:1 or
      // more against the page, and the only sign of the choice but the
      // colour (1.4.1).
      const dotMessage = (o) => `${NON_TEXT.sc}, the chosen radio button's dot against the page: ${JSON.stringify(o)}`;
      await expect(radio('Week')).toBeChecked();
      const first = await dots('before');
      expect(first.Week, dotMessage(first)).toBeGreaterThan(100);
      expect(first.Day, dotMessage(first)).toBe(0);
      expect(first.Month, dotMessage(first)).toBe(0);
      // The witness of the new choice: Day's state in the tree. The click's
      // focus is moved to Back before the measure.
      await radio('Day').click();
      await expect(radio('Day')).toBeChecked();
      await focusBack(page);
      const after = await dots('after');
      expect(after.Day, dotMessage(after)).toBeGreaterThan(100);
      expect(after.Week, dotMessage(after)).toBe(0);
      expect(after.Month, dotMessage(after)).toBe(0);
      // Undone: Week chosen again, its dot back.
      await radio('Week').click();
      await expect(radio('Week')).toBeChecked();
      await focusBack(page);
      const back = await dots('back');
      expect(back.Week, dotMessage(back)).toBeGreaterThan(100);
      expect(back.Day, dotMessage(back)).toBe(0);
    });

    // --- Bad examples: each defect, measured, written to fail if Flutter
    // draws it otherwise, with a lower bound that shows it was drawn.

    test('bad-cupertino-placeholder: the placeholder under 4.5:1; the label and the field\'s edge as in good-cupertino', async ({ page }) => {
      const slug = 'bad-cupertino-placeholder';
      await openIn(page, slug, mode);
      const field = await rectOf(control(page, slug, 'email'));
      const s = await steadyShot(page, [WHOLE], [cupertinoInside(field)]);
      const placeholder = textIn(s, cupertinoInside(field));
      report(slug, '"Required"', 'rest', mode, placeholder);
      expect(placeholder.lowest, `the defect, under ${TEXT.sc}: ${placeholder.text}`).toBeLessThan(TEXT.min);
      expect(placeholder.lowest, `the placeholder is drawn: ${placeholder.text}`).toBeGreaterThan(1.2);
      const label = textIn(s, labelAbove(field));
      report(slug, '"Email"', 'rest', mode, label);
      expectText(label, 'Email');
      const e = edge(s, field.left * DPR - 6, field.cy * DPR, 1, 0, 18);
      report(slug, 'field', 'rest', mode, e);
      expectOnPage(e, mode, 'field');
      expectNonText(e.outside, 'the field\'s edge against the page', e);
    });

    test('bad-caption: the caption under 4.5:1 over the pale part of the picture, in a colour 4.5:1 or more over its dark end', async ({ page }) => {
      const slug = 'bad-caption';
      await openIn(page, slug, mode);
      const s = await steadyShot(page, [WHOLE]);
      const box = await rectOf(page.getByText('Harbour', { exact: true }));
      const whole = textContrast(s, px(box));
      report(slug, '"Harbour"', 'rest', mode, whole);
      expect(whole.lowest, `the defect, under ${TEXT.sc}: ${whole.text}`).toBeLessThan(TEXT.min);
      expect(whole.lowest, `the caption is drawn: ${whole.text}`).toBeGreaterThan(1);
      // The dark end of the picture, at the right of the same bar, 8 past
      // the caption's box (the picture is 16 to 384).
      const dark = s.at(Math.round((box.right + 8) * DPR), Math.round(box.cy * DPR));
      console.log(`V01 web ${slug} dark end ${mode}: ${hex(dark)}, ${ratio(whole.colour, dark).toFixed(2)}:1 against the caption`);
      expect(ratio(whole.colour, dark), `the positive control, ${TEXT.sc}: the caption's colour over the dark end ${hex(dark)}`)
        .toBeGreaterThanOrEqual(TEXT.min);
    });

    test('bad-colour-only: the chosen title differs from the others by colour alone, under 3:1 against theirs; each 4.5:1 or more against the page; a click on Day moves the colour, and one on Week moves it back', async ({ page }) => {
      const slug = 'bad-colour-only';
      await openIn(page, slug, mode);
      const tileOf = (v) => control(page, slug, v.toLowerCase());
      const titles = async (when) => {
        const s = await steadyShot(page, [WHOLE]);
        const out = {};
        for (const v of ['Day', 'Week', 'Month']) {
          const tile = await rectOf(tileOf(v));
          const box = inkBox(s, px(tileInside(tile)));
          expect(box, `${v}: nothing drawn`).not.toBeNull();
          const m = textContrast(s, box);
          report(slug, `"${v}" ${when}`, 'rest', mode, m);
          expectText(m, v);
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
          expect(other, `${USE_OF_COLOR.sc}: ${v}: ${other} pixels besides the title`).toBe(0);
        }
        return out;
      };
      await expect(tileOf('Week')).toHaveAttribute('aria-current', 'true');
      const first = await titles('before');
      const chosen = first.Week.colour;
      for (const v of ['Day', 'Month']) {
        const q = ratio(chosen, first[v].colour);
        console.log(`V01 web ${slug} ${mode}: Week ${hex(chosen)} against ${v} ${hex(first[v].colour)} ${q.toFixed(2)}:1`);
        expect(hex(first[v].colour)).not.toBe(hex(chosen));
        expect(q, `the defect, under ${USE_OF_COLOR.sc}: Week against ${v}`).toBeLessThan(USE_OF_COLOR.min);
        expect(q, `Week against ${v}: the colours differ`).toBeGreaterThan(1);
      }
      // The witness of the new choice: aria-current on Day. The click's
      // focus is moved to Back before the measure.
      await tileOf('Day').click();
      await expect(tileOf('Day')).toHaveAttribute('aria-current', 'true');
      await focusBack(page);
      const after = await titles('after');
      expect(hex(after.Day.colour), 'the colour moved to Day').toBe(hex(chosen));
      expect(hex(after.Week.colour)).toBe(hex(first.Day.colour));
      // Undone: Week chosen again, in the tree and in its colour.
      await tileOf('Week').click();
      await expect(tileOf('Week')).toHaveAttribute('aria-current', 'true');
      await expect(tileOf('Day')).toHaveAttribute('aria-current', 'false');
      await focusBack(page);
      const again = await titles('back');
      expect(hex(again.Week.colour), 'the colour moved back to Week').toBe(hex(chosen));
    });

    test('bad-faint-edge: the field\'s edge under 3:1 against the page at rest; with focus by Tab the same measure finds it 3:1 or more, and under 3:1 again once focus leaves', async ({ page }) => {
      const slug = 'bad-faint-edge';
      await openIn(page, slug, mode);
      const locator = control(page, slug, 'email');
      const field = await rectOf(locator);
      const walk = (s) => edge(s, field.left * DPR - 12, field.cy * DPR, 1, 0, 30);
      let s = await steadyShot(page, [WHOLE]);
      const rest = walk(s);
      report(slug, 'field', 'rest', mode, rest);
      expectOnPage(rest, mode, 'field');
      expect(rest.outside, `the defect, under ${NON_TEXT.sc}: ${rest.text}`).toBeLessThan(NON_TEXT.min);
      expect(rest.outside, `the edge is drawn: ${rest.text}`).toBeGreaterThan(1.2);
      const label = textIn(s, outlinedLabel(field));
      report(slug, '"Email"', 'rest', mode, label);
      expectText(label, 'Email');
      // The positive control: focus on the field, by Tab; its witness the
      // page's focus.
      expect(await hasFocus(locator), 'the field has no focus at first').toBe(false);
      expect(await focusByTab(page, locator), 'Tab reaches the field').toBe(true);
      s = await steadyShot(page, [WHOLE], [outlinedInside(field)]);
      expect(await hasFocus(locator), 'the field still has focus').toBe(true);
      const focused = walk(s);
      report(slug, 'field', 'focused', mode, focused);
      expectOnPage(focused, mode, 'field focused');
      expectNonText(focused.outside, 'the focused field\'s edge against the page', focused);
      // Undone: focus on Back, and the edge as at rest.
      await focusBack(page);
      expect(await hasFocus(locator), 'the field no longer has focus').toBe(false);
      const after = walk(await steadyShot(page, [WHOLE]));
      expect(hex(after.edge), `the edge as at rest once focus leaves: ${after.text}`).toBe(hex(rest.edge));
    });
  });
}

/** Waits, at most a second, for focus to be on `locator`. */
const focusLands = (locator) => expect.poll(() => hasFocus(locator), { timeout: 1000 }).toBe(true).then(() => true, () => false);

/**
 * Puts keyboard focus on one of good-selection's radio buttons, with Week
 * chosen and focus on Back or nowhere. Tab never reaches Day (the Tab cycle
 * test above), so Day is reached by Tab to Week and then Up, which chooses
 * Day as well (checked here; unfocusRadio puts the choice back); Week by
 * Tab; and Month by Tab past Week, which leaves Week chosen.
 */
async function focusRadio(page, name) {
  const radio = (v) => control(page, 'good-selection', v);
  await expect(radio('week')).toBeChecked();
  if (name !== 'day') return focusByTab(page, radio(name));
  if (!(await focusByTab(page, radio('week')))) return false;
  await park(page);
  await page.keyboard.press('ArrowUp');
  if (!(await focusLands(radio('day')))) return false;
  await expect(radio('day')).toBeChecked();
  return true;
}

/**
 * Undoes what focusRadio did beyond the focus: after Day, Down chooses Week
 * again (checked, with focus on Week). Focus is then moved to Back.
 */
async function unfocusRadio(page, name) {
  const radio = (v) => control(page, 'good-selection', v);
  if (name === 'day') {
    await park(page);
    await page.keyboard.press('ArrowDown');
    expect(await focusLands(radio('week')), 'Down from Day reaches Week').toBe(true);
  }
  await expect(radio('week')).toBeChecked();
  await focusBack(page);
}

// The good examples' texts in each state. For each control in turn: the
// control is checked to be as at rest (no focus on it, no mouse cursor, and
// every pixel of it and its texts as in the screenshot at rest); the state
// is set and shown set (the header says by what); the control's texts are
// measured; and the state is undone and shown undone the same way. A press
// is measured twice while it is held, after 2 s and after 4 s, each from
// two screenshots that agree (steadyShot), and the two readings must be
// the same. Every other state is measured from two screenshots that agree.
// Every text is measured and logged in every state
// (soft expectations), and the test fails if any is under 4.5:1 (1.4.3).
// `cursor` is the mouse cursor Flutter sets over the control.
const STATE_CONTROLS = {
  'good-material': [
    { name: 'email', cursor: 'text', texts: (r) => ({ Email: outlinedLabel(r), Required: outlinedInside(r) }), caret: outlinedInside },
    { name: 'updates', cursor: 'pointer', texts: (r) => ({ 'Send me updates': tileTitle(r) }), checkbox: true },
    { name: 'send', cursor: 'pointer', texts: (r) => ({ Send: buttonInside(r, 12, 4) }) },
  ],
  'good-cupertino': [
    { name: 'email', cursor: 'text', texts: (r) => ({ Email: labelAbove(r), Required: cupertinoInside(r) }), caret: cupertinoInside },
    { name: 'send', cursor: 'pointer', texts: (r) => ({ Send: buttonInside(r, 10, 8) }) },
  ],
  'good-selection': ['Day', 'Week', 'Month'].map((v) => ({
    name: v.toLowerCase(),
    cursor: 'pointer',
    texts: (r) => ({ [v]: radioTitle(r) }),
    focus: (page) => focusRadio(page, v.toLowerCase()),
    unfocus: (page) => unfocusRadio(page, v.toLowerCase()),
  })),
};
const STATE_NAMES = ['focused', 'hovered', 'focused and hovered', 'pressed'];

// A press is a mouse button held on the control. good-material and
// good-selection are under the theme with no ink splash (WithoutSplash, for
// FL-515): with the default splash, a press held on their button and tiles
// took a text under 4.5:1 (docs/evidence/probes/v01/probe3_web.txt). The
// press is measured once it has settled: a steady screenshot (two agreeing
// 250 ms apart) after 2 s held, and another after 4 s, which must agree
// with it; both are asserted.
for (const mode of MODES) {
  test.describe(`the good examples' texts in each state, ${mode}`, () => {
    test.afterEach(async ({ page }) => restore(page));

    for (const [slug, controls] of Object.entries(STATE_CONTROLS)) {
      for (const state of STATE_NAMES) {
        test(`${slug}: each control's text 4.5:1 or more when ${state}`, async ({ page }) => {
          // A press is held 4 s on each control.
          if (state === 'pressed') test.setTimeout(120_000);
          await openIn(page, slug, mode);
          // Each text's rectangle is found at rest, with nothing focused,
          // hovered, or pressed: a state's overlay, and a press's ripple
          // part way across, can join the letters to shapes that touch the
          // region's edge. The texts do not move in any of these states.
          const rest = await steadyShot(page, [WHOLE]);
          const found = {};
          for (const c of controls) {
            const r = await rectOf(control(page, slug, c.name));
            const regions = c.texts(r);
            found[c.name] = { r, boxes: {}, around: [r, ...Object.values(regions)] };
            for (const [t, region] of Object.entries(regions)) {
              const box = inkBox(rest, px(region));
              expect(box, `${c.name} "${t}": nothing drawn at rest`).not.toBeNull();
              found[c.name].boxes[t] = box;
            }
          }
          for (const c of controls) {
            const locator = control(page, slug, c.name);
            const { r, boxes, around } = found[c.name];
            expect(await rectOf(locator), `${c.name} did not move`).toEqual(r);
            const caret = c.caret ? [c.caret(r)] : [];
            // As at rest: what the last control's undoing is checked by too.
            const asAtRest = async (when) => {
              await expect.poll(async () => {
                const s = caret.length ? await shotWithoutCaret(page, caret) : await shot(page);
                return { focus: await hasFocus(locator), cursor: await cursorOf(page), changed: changedIn(s, rest, around) };
              }, { message: `${c.name} ${when}: no focus, no cursor, and drawn as at rest`, timeout: 3000 })
                .toEqual({ focus: false, cursor: '', changed: 0 });
              if (c.checkbox) await expect(locator, `${c.name} ${when}: not checked`).not.toBeChecked();
              if (slug === 'good-selection') await expect(control(page, slug, 'week'), `${when}: Week chosen`).toBeChecked();
            };
            const measure = (s, when) => {
              for (const [t, box] of Object.entries(boxes)) {
                const m = textContrast(s, box);
                report(slug, `${c.name} "${t}"`, when, mode, m);
                expect.soft(m.lowest, `${TEXT.sc}: ${c.name} "${t}" ${when}: ${m.text}`).toBeGreaterThanOrEqual(TEXT.min);
                readings[`${t} ${when}`] = m.text;
              }
            };
            const readings = {};
            // Shows each part of the state set, by its witness.
            const witness = async (when) => {
              if (state.includes('focused') || state === 'pressed') {
                expect(await hasFocus(locator), `${c.name} ${when}: the page's focus is on it`).toBe(true);
              }
              if (state.includes('hovered') || state === 'pressed') {
                expect(await cursorOf(page), `${c.name} ${when}: Flutter's cursor for it`).toBe(c.cursor);
              }
            };
            await asAtRest('before');
            if (state.includes('focused')) {
              expect(await (c.focus ?? ((p) => focusByTab(p, locator)))(page), `focus reaches ${c.name}`).toBe(true);
            }
            if (state.includes('hovered') || state === 'pressed') {
              await page.mouse.move(r.cx, r.cy);
              await expect.poll(() => cursorOf(page), { message: `${c.name}: Flutter's cursor for it`, timeout: 2000 }).toBe(c.cursor);
            }
            if (state === 'pressed') {
              await page.mouse.down();
              await page.waitForTimeout(2000);
              // A mouse button pressed on a control gives it focus, which it
              // did not have before (asAtRest).
              await witness('pressed 2 s');
              measure(await steadyShot(page, around, caret), 'pressed 2 s');
              await page.waitForTimeout(2000);
              await witness('pressed 4 s');
              measure(await steadyShot(page, around, caret), 'pressed 4 s');
              for (const t of Object.keys(boxes)) {
                expect.soft(readings[`${t} pressed 4 s`], `${c.name} "${t}": the press had settled by 2 s`)
                  .toBe(readings[`${t} pressed 2 s`]);
              }
              // Off the control before the button is let go: no click.
              await park(page);
              await page.mouse.up();
            } else {
              await witness(state);
              const s = await steadyShot(page, around, caret);
              await witness(state);
              measure(s, state);
            }
            // Undone, and shown undone.
            await park(page);
            if (state.includes('focused') || state === 'pressed') await (c.unfocus ?? focusBack)(page);
            await asAtRest('after');
          }
        });
      }
    }
  });
}


// --- The web VoiceOver judge ----------------------------------------------
//
// S16's tests of its walk and judge (web_tests/s16_language_page_parts.spec.js
// on main), with the S08 to S12 judge update's (s12_hiding_content.spec.js on
// branch origin/web-vo-judges-s08-s12): the positions row, a stop's " / "
// escaped, both wordings of VoiceOver's help message, and the end witness's
// move back reading that help. Drawn on V01's screens. VO_SLUG is the
// example the made-up walks are drawn on; WRONG_TITLE is another V01
// example's title, read where VO_SLUG's is expected; TIED is a help message
// that the positions tie to the stop before it (helpAfterStop), at `after`
// in the whole screen of `slug`.
const VO_SLUG = 'bad-colour-only';
const WRONG_TITLE = `heading level 1 ${EXAMPLE_SCREENS['bad-faint-edge'][0]}`;
const BUTTON_HELP = 'You are currently on a button, inside of web content. To click this button, press Control-Option-Space.';
const TIED = {
  slug: VO_SLUG,
  // Day's button: the screen's own stops, the heading, "Calendar view", Day.
  after: screenStops(VO_SLUG).length + 2,
  help: BUTTON_HELP,
};
// The end witness's move back may read VoiceOver's help about the stop
// before the last (witnessBackHolds; the principal's decision of
// 2026-11-28): `pair` is a reading with a spoken role and a stop after it,
// `help` names that role, `wrongHelp` another; `row` is the transcript row
// whose stop before the last is `pair`'s first.
const WITNESS = {
  row: 'good-material',
  help: 'You are currently on a checkbox, inside of web content. To select or deselect this checkbox, press Control-Option-Space.',
  wrongHelp: BUTTON_HELP,
  pair: ['Send me updates unchecked checkbox', 'Send button'],
};

// How the web VoiceOver spec judges one walk's stops (judgeWalk, S16's, on
// S08's judgeExampleWalk). The walks here are made up; VoiceOver is not
// used. Each test names every case it holds, and fails on the first case
// whose verdict is not the one given, with the case's name.
test.describe('the VoiceOver example walks are judged on every walk', () => {
  const own = screenStops(VO_SLUG);
  const expected = EXPECTED_STOPS[VO_SLUG];
  const [calendar, day, week, month] = expected;
  const TEXT_FIELD_HELP = 'You are currently on a text field, inside of web content.';
  const HEADING_HELP = 'You are currently on a heading level 1, inside of web content.';
  // VoiceOver's other wording, as S08's ninth web recording read it.
  const IN_BUTTON_HELP = 'You are currently in a button, inside of web content.';
  const IN_GROUP_HELP = 'You are currently in a empty group.';
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
      ['a help message with no positions recorded', 'wrong', [...whole, BUTTON_HELP], true],
      ['no title', 'wrong', [...own.slice(1), EXAMPLE_HEADING, ...expected], true],
      ['no defect', 'wrong', [own[0], own[1], EXAMPLE_HEADING, ...expected], true],
      ['no heading', 'wrong', [...own, ...expected], true],
      // A walk that ran out of moves is wrong (judgeWalk, rule 4): with 40
      // moves it can only have gone on past the screen.
      ['an empty walk that ran out of moves', 'wrong', [], false],
      ['a walk that ran out of moves after the heading', 'wrong', screen(), false],
      ['every stop read, but the end not reached', 'wrong', whole, false],
    ], (stops, reachedEnd) => judgeWalk(stops, reachedEnd, expected, own));
  });

  test('a help message, in either wording, is left out only when tied to the stop before it, by position and spoken role', () => {
    const h = own.length + 1; // the index of the first stop after the heading
    check([
      ['help after the last tile\'s stop, at its position', 'complete',
        screen(calendar, day, week, month, BUTTON_HELP), at(screen(calendar, day, week, month, BUTTON_HELP), [h + 4])],
      ['help after the chosen tile\'s stop, at its position', 'complete',
        screen(calendar, day, week, BUTTON_HELP, month), at(screen(calendar, day, week, BUTTON_HELP, month), [h + 3])],
      ['help in the other wording after Day\'s stop, at its position', 'complete',
        screen(calendar, day, IN_BUTTON_HELP, week, month), at(screen(calendar, day, IN_BUTTON_HELP, week, month), [h + 2])],
      ['"in a empty group" after Day\'s stop, at its position (the roles differ)', 'wrong',
        screen(calendar, day, IN_GROUP_HELP, week, month), at(screen(calendar, day, IN_GROUP_HELP, week, month), [h + 2])],
      ['help in the other wording at a new position after the whole screen', 'wrong', [...whole, IN_BUTTON_HELP], at([...whole, IN_BUTTON_HELP])],
      ['help at a new position after the whole screen (an extra element)', 'wrong', [...whole, BUTTON_HELP], at([...whole, BUTTON_HELP])],
      ['a text field\'s help at a new position after the whole screen', 'wrong', [...whole, TEXT_FIELD_HELP], at([...whole, TEXT_FIELD_HELP])],
      ['button help after a text with no role, at its position', 'wrong', screen(calendar, BUTTON_HELP, day, week, month),
        at(screen(calendar, BUTTON_HELP, day, week, month), [h + 1])],
      ['help naming another role than the stop before it, at its position', 'wrong',
        screen(calendar, day, TEXT_FIELD_HELP, week, month), at(screen(calendar, day, TEXT_FIELD_HELP, week, month), [h + 2])],
      ['help in place of an expected stop', 'wrong', screen(calendar, day, BUTTON_HELP, month), at(screen(calendar, day, BUTTON_HELP, month))],
      ['help after an empty stop, at its position', 'wrong', screen(calendar, '', BUTTON_HELP, week, month),
        at(screen(calendar, '', BUTTON_HELP, week, month), [h + 2])],
      ['help with positions of the wrong length', 'wrong', screen(calendar, day, BUTTON_HELP, week, month), at(whole)],
      ['help and a wrong reading', 'wrong', screen(calendar, 'Day', BUTTON_HELP, week, month),
        at(screen(calendar, 'Day', BUTTON_HELP, week, month), [h + 2])],
      // helpRole gives "heading level 1", which is not spokenRole's
      // "heading": a made-up heading help is not left out (the rule errs
      // toward failing).
      ['a heading help with its level after the title, at its position', 'wrong', [own[0], HEADING_HELP, ...whole.slice(1)],
        at([own[0], HEADING_HELP, ...whole.slice(1)], [1])],
      ['button help after the title heading, at its position', 'wrong', [own[0], BUTTON_HELP, ...whole.slice(1)],
        at([own[0], BUTTON_HELP, ...whole.slice(1)], [1])],
      ['no help message', 'complete', whole, at(whole)],
    ], (stops, positions) => judgeWalk(stops, true, expected, own, positions));
  });

  test('a reading\'s spoken role comes from its role part only, and a help message, in either wording, names its role', () => {
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
    expect(helpRole(BUTTON_HELP)).toBe('button');
    expect(helpRole(TEXT_FIELD_HELP)).toBe('text field');
    expect(helpRole(IN_BUTTON_HELP)).toBe('button');
    expect(helpRole(IN_GROUP_HELP)).toBe('group');
    expect(helpRole('Calendar view')).toBe(null);
    for (const help of [BUTTON_HELP, TEXT_FIELD_HELP, IN_BUTTON_HELP, IN_GROUP_HELP]) expect(VO_HELP.test(help), help).toBe(true);
    expect(VO_HELP.test('You are currently at the top.')).toBe(false);
  });
});

// How the walks are made again (runWalks), judged by judgeWalk as the
// VoiceOver spec's walks are, and the screens and lists every judge reads.
test.describe('the VoiceOver walks are made again only while incomplete', () => {
  const own = screenStops(VO_SLUG);
  const expected = EXPECTED_STOPS[VO_SLUG];
  const whole = [...own, EXAMPLE_HEADING, ...expected];

  test('every screen: a bad example\'s own stops end with its defect, no screen has a custom solution note, and no expected stop is empty, help, or anything a recorded phrase cannot be', () => {
    for (const slug of Object.keys(EXAMPLE_SCREENS)) {
      if (slug.startsWith('bad-')) expect(screenStops(slug).at(-1), slug).toMatch(/^Defect: /);
      expect(screenStops(slug).some((s) => s.startsWith('Custom solution')), slug).toBe(false);
    }
    for (const [row, { expected: stops, screen }] of Object.entries(TRANSCRIPT_ROWS)) {
      // A recorded phrase is spokenText's: no line break, no white space
      // doubled or at either end. A marked text field's sample reading is
      // one, and is the stop (matchesStop).
      for (const entry of [...screen, ...stops]) {
        const s = readingOf(entry);
        expect(s !== '' && !VO_HELP.test(s) && spokenText(s) === s && matchesStop(s, entry), `${row}: "${s}"`).toBe(true);
      }
    }
    expect(Object.keys(EXPECTED_STOPS)).toEqual(Object.keys(EXAMPLE_SCREENS));
    expect(Object.keys(TRANSCRIPT_ROWS)).toEqual(Object.keys(EXAMPLE_SCREENS));
  });

  test('walks are made again only while incomplete, at most three, every try is logged, and a wrong walk ends the example', async () => {
    const judge = (stops, reachedEnd) => judgeWalk(stops, reachedEnd, expected, own);
    const right = { stops: whole, reachedEnd: true };
    const short = { stops: whole.slice(0, 3), reachedEnd: false };
    const wrong = { stops: [WRONG_TITLE, ...whole.slice(1)], reachedEnd: true };
    const emptyTitle = { stops: ['', ...whole.slice(1)], reachedEnd: true };
    const pastEnd = { stops: [...whole, ''], reachedEnd: true };
    const cases = [
      ['a wrong reading, then a right walk', [wrong, right], 'wrong', 1],
      ['a complete walk plus an empty stop past the end, then a right walk', [pastEnd, right], 'wrong', 1],
      ['an empty first stop, then a right walk', [emptyTitle, right], 'complete', 2],
      ['an empty first stop, then a wrong reading, then a right walk', [emptyTitle, wrong, right], 'wrong', 2],
      ['three empty captures, then a right walk', [emptyTitle, emptyTitle, emptyTitle, right], 'incomplete', 3],
      // A walk that ran out of moves is wrong for good (judgeWalk, rule 4).
      ['a walk that ran out of moves, then a right one', [short, right], 'wrong', 1],
      ['an empty first stop, then a walk that ran out of moves, then a right one', [emptyTitle, short, right], 'wrong', 2],
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
  const slug = VO_SLUG;
  const own = screenStops(slug);
  const expected = EXPECTED_STOPS[slug];
  const words = [...own, EXAMPLE_HEADING, ...expected];
  const at = (i) => `${10 + i}, ${100 + 20 * i}, 300, ${118 + 20 * i}`;
  // The capture before the first move: the walk begins on Back.
  const START = { phrase: 'Back button', position: '10, 60, 300, 78' };
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
  const wrongTitle = [{ phrase: WRONG_TITLE, position: at(0) }, ...screen.slice(1)];
  const atStart = (c, el, n) => (n === 1 ? { phrase: WRONG_TITLE, position: START.position } : el);
  const run = async (walks) => {
    let i = 0;
    let latest;
    const result = await runWalks(async () => { latest = walks[i++]; return latest; }, () => judge(latest));
    return { ...result, made: i };
  };

  test('made-up walks: a whole screen passes, and each fault fails or is not complete', async () => {
    const right = await drive(screen);
    expect(judge(right).verdict, 'the whole screen').toBe('complete');
    expect(right.witness.back).toEqual(screen.at(-2));
    expect(right.witness.forward).toEqual(screen.at(-1));
    expect(right.unresolved).toEqual([]);
    expect(right.positions).toEqual(screen.map((e) => e.position));

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
      ['empty phrases with frozen bounds', await drive(screen, (c, el) => (c >= heading
        ? { phrase: '', position: at(heading) } : el)), 'wrong'],
      // The move back at the end reads the last element again where it is.
      ['a wrong witness: the move back reads the last stop', await drive(screen, (c, el, n) => (n === words.length + 3
        ? screen.at(-1) : el)), 'wrong'],
      ['a wrong witness: the move back reads an empty phrase', await drive(screen, (c, el, n) => (n === words.length + 3
        ? { phrase: '', position: at(words.length - 2) } : el)), 'wrong'],
      ['a wrong witness: the move back reads the right words at the last stop\'s position', await drive(screen, (c, el, n) => (n === words.length + 3
        ? { phrase: words.at(-2), position: at(words.length - 1) } : el)), 'wrong'],
      ['a wrong witness: the move forward reads another place', await drive(screen, (c, el, n) => (n === words.length + 4
        ? { phrase: words.at(-1), position: '1, 1, 1, 1' } : el)), 'wrong'],
      ['a wrong witness: the move forward reads another stop', await drive(screen, (c, el, n) => (n === words.length + 4
        ? { phrase: 'Extra', position: at(words.length - 1) } : el)), 'wrong'],
      // One stale read at an element mid-walk (the previous phrase and
      // bounds), then the walk moves on: that element is never a stop.
      ['one stale read at an unexpected element mid-walk', await drive(injected,
        (c, el) => (el === extra ? screen[heading] : el)), 'incomplete'],
      // One empty read at an element mid-walk, at the previous bounds.
      ['one empty read at an unexpected element mid-walk', await drive(injected,
        (c, el) => (el === extra ? { phrase: '', position: screen[heading].position } : el)), 'incomplete'],
      // A repeated heading mid-walk at the heading's bounds.
      ['the Example heading read again mid-walk at its bounds', await drive(
        [...screen.slice(0, heading + 1), screen[heading], ...screen.slice(heading + 1)]), 'incomplete'],
      // A walk that runs out of moves is wrong for good (judgeWalk, rule 4).
      ['a walk exhausted at the move limit', await drive(screen, undefined, 3), 'wrong'],
      ['a screen of one stop', await drive(screen.slice(0, 1)), 'wrong'],
      // A help message read after the last element, at its position, is a
      // stop (new words), the walk's last; the witness's move back then
      // reads the element before it, not the stop before the last, so the
      // walk fails for good: the help rule cannot leave it out.
      ['a help message at the last element\'s position, after its reading', await drive(screen, (c, el, n) => (
        n > words.length && c === words.length - 1 ? { phrase: TIED.help, position: at(words.length - 1) } : el)), 'wrong'],
    ];
    for (const [what, walk, verdict] of cases) {
      expect(judge(walk).verdict, `${what}: ${JSON.stringify(walk)}`).toBe(verdict);
    }
  });

  test('the reviewer\'s frozen capture, with elements after the last expected stop, would pass without the witness, and fails with it', async () => {
    const elements = [...screen, { phrase: 'Week current item button', position: at(80) }, extra];
    const walk = await drive(elements, (c, el) => (c >= screen.length ? screen.at(-1) : el));
    expect(walk.stops).toEqual(words);
    expect(judgeExampleWalk(walk.stops, true, expected, own).verdict).toBe('complete');
    expect(walk.witness.back).toEqual(screen.at(-1));
    expect(walk.problem).toMatch(/^the end is not witnessed/);
    expect(judge(walk).verdict).toBe('wrong');
  });

  test('a lost capture (stale, or empty at the old bounds) is a gap: incomplete when nothing is wrong, wrong for good otherwise', async () => {
    // At an unexpected element mid-walk: the stops are exactly the screen,
    // and only the unresolved read shows an element went unrecorded.
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
    // At an expected stop: the stops lack it, which alone judges wrong; the
    // gap makes the walk incomplete, walked again. Three from the end, so
    // that neither of the last two, which the witness reads, is the one lost.
    const lostAt = words.length - 3;
    const lost = await drive(screen, losing(screen, lostAt));
    expect(lost.stops).toEqual(words.filter((_, i) => i !== lostAt));
    expect(lost.unresolved).toEqual([{ after: lostAt, phrase: words[lostAt - 1], position: at(lostAt - 1) }]);
    expect(judgeExampleWalk(lost.stops, true, expected, own).verdict).toBe('wrong');
    expect(judge(lost).verdict).toBe('incomplete');
    // At the stop before the last: the move back reads it, which the stops
    // do not have before the last, so the witness fails, for good.
    const beforeLast = await drive(screen, losing(screen, screen.length - 2));
    expect(beforeLast.unresolved).toHaveLength(1);
    expect(beforeLast.problem).toMatch(/^the end is not witnessed: a move back read/);
    expect(judge(beforeLast).verdict).toBe('wrong');
  });

  // judgeWalk: an unresolved read is a gap in the walk, never a pass for
  // what was captured around it.
  test('a wrong verdict wins over a gap, and a gap passes over at most the next expected stop', async () => {
    const extraFirst = [...screen.slice(0, heading + 1), extra, { phrase: 'Extra 2', position: at(91) }, ...screen.slice(heading + 1)];
    const wrongAfter = [...screen.slice(0, heading + 1), extra, { phrase: 'Wrong', position: at(92) }, ...screen.slice(heading + 2)];
    const cases = [
      ['a wrong title, then one stale read', await drive(wrongTitle, losing(wrongTitle, 2)), 'wrong'],
      ['a wrong title, then one empty read', await drive(wrongTitle, losing(wrongTitle, 2, 'empty')), 'wrong'],
      // An extra stop captured before the read that was lost.
      ['an extra stop before the lost read', await drive(extraFirst, losing(extraFirst, heading + 2)), 'wrong'],
      // A wrong stop captured after the gap.
      ['a wrong stop after the gap', await drive(wrongAfter, losing(wrongAfter, heading + 1)), 'wrong'],
      // A right prefix, one lost read, then the next expected stop (the
      // lost read was an extra element) or the one after it (the lost read
      // was the next expected stop): both stay incomplete.
      ['a right prefix, one lost extra element, then the next expected stop', await drive(injected, losing(injected, heading + 1)), 'incomplete'],
      ['a right prefix, one lost expected stop, then the one after it', await drive(screen, losing(screen, words.length - 3)), 'incomplete'],
    ];
    for (const [what, walk, verdict] of cases) {
      expect(judge(walk).verdict, `${what}: ${JSON.stringify(walk.stops)} ${JSON.stringify(walk.unresolved)}`).toBe(verdict);
    }
    // The same rule on stops alone, with gaps given as "after stop K".
    const byGaps = (stops, gaps, reachedEnd = true) => judgeWalk(stops, reachedEnd, expected, own, undefined, gaps).verdict;
    const gapCases = [
      ['a gap after the heading, then the next expected stop', words, [heading + 1], 'incomplete'],
      ['a gap after the heading, then the stop after the next', words.filter((_, i) => i !== heading + 1), [heading + 1], 'incomplete'],
      ['a gap, then a stop two places on', [...words.slice(0, heading), words.at(-1)], [heading], 'wrong'],
      ['a wrong title before a gap', [WRONG_TITLE, ...words.slice(1)], [heading + 1], 'wrong'],
      ['a stop past the end after a gap', [...words, 'Extra'], [heading + 1], 'wrong'],
      ['the end reached with an expected stop neither read nor lost', words.slice(0, -1), [1], 'wrong'],
      ['a walk that ran out of moves, with a gap', words, [heading + 1], 'wrong', false],
      ['no gap, every stop right', words, [], 'complete'],
    ];
    for (const [what, stops, gaps, verdict, reachedEnd] of gapCases) {
      expect(byGaps(stops, gaps, reachedEnd), what).toBe(verdict);
    }
  });

  // The fourth review of S16's walk: the first capture reads a wrong title
  // at the start's bounds (Back's, which had not changed yet). Compared
  // with the start capture, its words are new, so it is a stop, judged
  // wrong.
  test('a wrong first title at the start bounds is a stop, judged wrong, not a gap', async () => {
    const elements = [{ phrase: 'x', position: START.position }, ...screen.slice(1)];
    const walk = await drive(elements, atStart);
    expect(walk.unresolved).toEqual([]);
    expect(walk.stops[0]).toBe(WRONG_TITLE);
    expect(walk.start).toEqual(START);
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

  test('in the retry loop a wrong walk ends the example, and a clean walk after it is never made', async () => {
    const cases = [
      ['a wrong first title at the start bounds', [await drive([{ phrase: 'x', position: START.position }, ...screen.slice(1)], atStart)]],
      ['a wrong title, then one stale read', [await drive(wrongTitle, losing(wrongTitle, 2))]],
      ['a wrong title, then one empty read', [await drive(wrongTitle, losing(wrongTitle, 2, 'empty'))]],
      ['a walk exhausted at the move limit', [await drive(screen, undefined, 3)]],
      ['a wrong title, then a stale read, after a walk with a gap and nothing wrong', [await drive(injected, losing(injected, heading + 1)),
        await drive(wrongTitle, losing(wrongTitle, 2))]],
    ];
    for (const [what, walks] of cases) {
      const result = await run([...walks, await drive(screen)]);
      expect(result.verdict, what).toBe('wrong');
      expect(result.made, what).toBe(walks.length);
    }
    // A walk with a gap and nothing wrong, then a clean one: complete on the second.
    const healed = await run([await drive(injected, losing(injected, heading + 1)), await drive(screen)]);
    expect(healed).toMatchObject({ verdict: 'complete', walks: 2, made: 2 });
  });

  test('an unchanged read at the true end is the end, through the witness, and every row is logged', async () => {
    const walk = await drive(screen);
    expect(walk.reachedEnd).toBe(true);
    expect(unresolvedRow(slug, 1, walk.unresolved)).toBe(`| \`${slug}-walk-1-unresolved\` | none |`);
    expect(endRow(slug, 1, walk.witness)).toBe(
      `| \`${slug}-walk-1-end\` | back "${words.at(-2)}" at ${at(words.length - 2)} / forward "${words.at(-1)}" at ${at(words.length - 1)} |`);
    expect(startRow(slug, 1, walk.start)).toBe(`| \`${slug}-walk-1-start\` | "Back button" at 10, 60, 300, 78 |`);
    expect(positionsRow(slug, 1, walk.positions)).toBe(
      `| \`${slug}-walk-1-positions\` | ${words.map((_, i) => at(i)).join(' / ')} |`);
    const lost = await drive(injected, losing(injected, heading + 1));
    expect(lost.reachedEnd).toBe(true);
    expect(lost.witness).toEqual({ back: screen.at(-2), forward: screen.at(-1) });
    expect(judge(lost).verdict).toBe('incomplete');
  });
});

// The committed web VoiceOver transcript, judged again from its rows alone
// (judgeTranscript in web_tests/vo/v01_vo_walks.js), never skipped: every
// browser and row once, walks in order, the last complete, each walk with
// its start, positions and unresolved-reads rows and the last with its end
// witness row. Made-up transcripts test the judge first.
test.describe('the web VoiceOver transcript is judged again from what it recorded', () => {
  const rows = Object.keys(TRANSCRIPT_ROWS);
  const R = rows[0];
  // A row's whole screen as a made-up walk reads it (a marked text field
  // read as its sample, readingOf).
  const whole = (row) => wholeScreen(TRANSCRIPT_ROWS[row].expected, TRANSCRIPT_ROWS[row].screen).map(readingOf);
  const pos = (i) => `318, ${251 + 40 * i}, 1011, ${271 + 40 * i}`;
  const placesOf = (stops) => stops.map((_, i) => pos(i));
  const witnessOf = (stops) => ({ back: { phrase: stops.at(-2), position: pos(stops.length - 2) }, forward: { phrase: stops.at(-1), position: pos(stops.length - 1) } });
  const BACK = { phrase: '', position: '30, 147, 70, 187' };
  // A walk's rows as the VoiceOver spec logs them; `end` false leaves out
  // the end row, as for a walk that ran out of moves.
  const walkRows = (row, n, stops, verdict, { end = true, unresolved = [], positions = placesOf(stops), start = BACK } = {}) => [
    transcriptRow(row, n, stops, verdict, 'x'), startRow(row, n, start), positionsRow(row, n, positions),
    ...(end ? [endRow(row, n, witnessOf(stops))] : []), unresolvedRow(row, n, unresolved)];
  const rowsOf = (row, n = 1) => walkRows(row, n, whole(row), 'complete');
  const section = (browser, lines) => ['', `## ${browser}`, '', '| Example | Spoken, in order |', '| --- | --- |', ...lines];
  const transcript = (rowsFor) => ['# V01 Colour contrast: VoiceOver transcript (web, macOS)', '',
    'Result: PASS', ...BROWSERS.flatMap((b) => section(b, rowsFor(b)))].join('\n');
  const right = () => rows.flatMap((row) => rowsOf(row));
  // R's walks replaced by `first`, then a complete second walk.
  const thenRight = (first) => transcript(() => [...first, ...rowsOf(R, 2), ...rows.slice(1).flatMap((x) => rowsOf(x))]);
  const replaced = (prefix, line) => transcript(() => right().map((r) => (r.startsWith(`| \`${R}-walk-1${prefix}\``) ? line : r)));
  const w = whole(R);
  const h = w.indexOf(EXAMPLE_HEADING);
  // The tied help message, in TIED.slug's walk, at the position of the stop
  // before it, or at a new one.
  const helped = [...whole(TIED.slug).slice(0, TIED.after + 1), TIED.help, ...whole(TIED.slug).slice(TIED.after + 1)];
  const tiedAt = placesOf(helped).map((p, i) => (i === TIED.after + 1 ? pos(TIED.after) : p));
  const withHelp = (positions) => transcript(() => rows.flatMap((row) => (row === TIED.slug
    ? walkRows(row, 1, helped, 'complete', { positions }) : rowsOf(row))));
  const ROW_KINDS = ['', '-start', '-positions', '-end', '-unresolved'];

  test('made-up transcripts: a right one passes, and each wrong one names its problem', () => {
    const one = transcriptRow(R, 1, w, 'complete', 'x');
    // A stop with " / " or a backslash in it is written escaped and read
    // back whole (S10's bad-merged reads "3.4 / 5").
    const odd = ['Rating: 3.4 / 5 Reviews', '', 'a\\b', '(x)'];
    expect(stopsOf(stopsText(odd))).toEqual(odd);
    expect(stopsText(odd).split(' / ')).toHaveLength(odd.length);
    expect(helped[TIED.after], 'TIED.after is the stop the help is about').toBe('Day button');
    const exhausted = Array.from({ length: 20 }, (_, i) => w[i % w.length]);
    const cases = [
      ['a whole walk of every row in both browsers', transcript(right), true],
      ['an empty transcript', '', false],
      ['sixteen copies of one walk row', transcript(() => Array(8).fill(one)), false],
      ['sixteen copies of one walk\'s rows', transcript(() => Array(8).fill(rowsOf(R)).flat()), false],
      // Each kind of row removed, from every walk.
      ...ROW_KINDS.map((kind) => [`every ${kind || 'walk'} row removed`,
        transcript(() => right().filter((r) => !new RegExp(`^\\| \`[a-z-]+-walk-\\d+${kind}\` \\|`).test(r))), false]),
      // Each kind of row removed from one walk only.
      ...ROW_KINDS.map((kind) => [`${R}'s ${kind || 'walk'} row removed in WebKit`,
        transcript((b) => right().filter((r) => b !== 'webkit' || !r.startsWith(`| \`${R}-walk-1${kind}\` |`))), false]),
      // Each kind of row given twice.
      ...ROW_KINDS.map((kind) => [`${R}'s ${kind || 'walk'} row twice`,
        transcript(() => { const all = right(); return [...all, all.find((r) => r.startsWith(`| \`${R}-walk-1${kind}\` |`))]; }), false]),
      // Each kind of row for a walk that is not there.
      ...ROW_KINDS.slice(1).map((kind) => [`a ${kind} row for a walk that is not there`,
        transcript(() => [...right(), rowsOf(R, 2).find((r) => r.startsWith(`| \`${R}-walk-2${kind}\` |`))]), false]),
      ['a row missing in one browser', transcript((b) => (b === 'webkit' ? right().slice(5) : right())), false],
      ['a browser section missing', ['Result: PASS', ...section('chromium', right())].join('\n'), false],
      ['an unknown browser section', [transcript(right), ...section('firefox', [])].join('\n'), false],
      ['an unknown example', transcript(() => [...right(), ...walkRows('good-other', 1, w, 'complete')]), false],
      ['a malformed row', transcript(() => [...right(), `| \`${R}-walk-x\` | something |`]), false],
      ['a row outside any section', [one, transcript(right)].join('\n'), false],
      ['walk 2 with no walk 1', transcript(() => right().map((r) => r.replace(`${R}-walk-1`, `${R}-walk-2`))), false],
      ['the last walk recorded wrong', replaced('', transcriptRow(R, 1, w, 'wrong', 'x')), false],
      ['the last walk recorded incomplete', replaced('', transcriptRow(R, 1, w, 'incomplete', 'x')), false],
      ['the old form, only what follows the heading', transcript(() => rows.flatMap((row) =>
        walkRows(row, 1, TRANSCRIPT_ROWS[row].expected.map(readingOf), 'complete'))), false],
      ['another row\'s screen stops', replaced('', transcriptRow(R, 1, [...TRANSCRIPT_ROWS[rows.at(-1)].screen, ...w.slice(h)], 'complete', 'x')), false],
      ['a walk whose title is an empty phrase', replaced('', transcriptRow(R, 1, ['', ...w.slice(1)], 'complete', 'x')), false],
      ['a stop past the end, empty', transcript(() => rows.flatMap((row) => (row === R ? walkRows(R, 1, [...w, ''], 'complete') : rowsOf(row)))), false],
      // bad-colour-only's chosen tile read without its state.
      ['the chosen tile read as a plain button', transcript(() => rows.flatMap((row) => (row === 'bad-colour-only'
        ? walkRows(row, 1, whole(row).map((s) => (s === 'Week current item button' ? 'Week button' : s)), 'complete') : rowsOf(row)))), false],
      // The end witness row.
      ['an end row whose positions are one word', replaced('-end', `| \`${R}-walk-1-end\` | back "x" at here / forward "y" at here |`), false],
      ['an end witness that read back the last stop', replaced('-end', endRow(R, 1, { back: witnessOf(w).forward, forward: witnessOf(w).forward })), false],
      ['an end witness that read back an empty phrase', replaced('-end', endRow(R, 1, { back: { phrase: '', position: '1, 2, 3, 4' }, forward: witnessOf(w).forward })), false],
      ['an end witness whose move back read the right words at the last position', replaced('-end',
        endRow(R, 1, { back: { phrase: witnessOf(w).back.phrase, position: witnessOf(w).forward.position }, forward: witnessOf(w).forward })), false],
      ['an end witness whose move forward read another stop', replaced('-end',
        endRow(R, 1, { back: witnessOf(w).back, forward: { phrase: 'Extra', position: witnessOf(w).forward.position } })), false],
      // The start row.
      ['a start row whose position is one word', replaced('-start', `| \`${R}-walk-1-start\` | "Back button" at here |`), false],
      // The positions row.
      ['a positions row with one position too few', replaced('-positions', positionsRow(R, 1, placesOf(w).slice(1))), false],
      ['a positions row with a position that is one word', replaced('-positions', positionsRow(R, 1, [...placesOf(w).slice(1), 'here'])), false],
      // The unresolved-reads row.
      ['the last walk with an unresolved read', replaced('-unresolved', unresolvedRow(R, 1, [{ after: 3, phrase: '', position: pos(2) }])), false],
      ['an unresolved-reads row whose position is one word', replaced('-unresolved', `| \`${R}-walk-1-unresolved\` | after stop 3: "" at here |`), false],
      ['malformed unresolved reads', replaced('-unresolved', `| \`${R}-walk-1-unresolved\` | lost one |`), false],
      // Earlier walks: each judged again, and a wrong one fails the
      // transcript however clean the walk after it.
      ['an empty first title, walked again, then complete', thenRight(walkRows(R, 1, ['', ...w.slice(1)], 'incomplete')), true],
      ['a first walk with an unresolved read, witnessed at its end, recorded incomplete though its stops judge complete, then complete',
        thenRight(walkRows(R, 1, w, 'incomplete', { unresolved: [{ after: h + 1, phrase: '', position: pos(h) }] })), true],
      ['an unresolved read after the start that repeats the start, then complete',
        thenRight(walkRows(R, 1, w, 'incomplete', {
          start: { phrase: 'Back button', position: BACK.position },
          unresolved: [{ after: 0, phrase: 'Back button', position: BACK.position }],
        })), true],
      ['a right prefix, one lost read, then the stop after the next; then complete',
        thenRight(walkRows(R, 1, w.filter((_, i) => i !== h + 1), 'incomplete', { unresolved: [{ after: h + 1, phrase: EXAMPLE_HEADING, position: pos(h) }] })), true],
      ['a first walk exhausted at the move limit (no end row), then complete',
        thenRight(walkRows(R, 1, exhausted, 'incomplete', { end: false, unresolved: exhausted.map((_, i) => ({ after: i, phrase: '', position: i === 0 ? BACK.position : pos(i - 1) })) })), false],
      ['the same exhausted walk given an end row, then complete',
        thenRight(walkRows(R, 1, exhausted, 'incomplete', { unresolved: exhausted.map((_, i) => ({ after: i, phrase: '', position: i === 0 ? BACK.position : pos(i - 1) })) })), false],
      ['a first walk cut short with no end row, then complete', thenRight(walkRows(R, 1, w.slice(0, 3), 'incomplete', { end: false })), false],
      ['a wrong first walk recorded wrong, then complete', thenRight(walkRows(R, 1, [WRONG_TITLE, ...w.slice(1)], 'wrong')), false],
      ['a wrong title, then a stale read, witnessed, then complete',
        thenRight(walkRows(R, 1, [WRONG_TITLE, ...w.slice(1)], 'incomplete', { unresolved: [{ after: 1, phrase: WRONG_TITLE, position: pos(0) }] })), false],
      ['a wrong title, then an empty read, witnessed, then complete',
        thenRight(walkRows(R, 1, [WRONG_TITLE, ...w.slice(1)], 'incomplete', { unresolved: [{ after: 1, phrase: '', position: pos(0) }] })), false],
      ['a wrong stop after the gap, witnessed, then complete',
        thenRight(walkRows(R, 1, [...w.slice(0, h + 1), 'Wrong', ...w.slice(h + 2)], 'incomplete', { unresolved: [{ after: h + 1, phrase: '', position: pos(h) }] })), false],
      ['a first walk with an unresolved read recorded complete, then complete',
        thenRight(walkRows(R, 1, w, 'complete', { unresolved: [{ after: h + 1, phrase: '', position: pos(h) }] })), false],
      // An unresolved read is an unchanged read.
      ['an unresolved read at a position other than the one before it',
        thenRight(walkRows(R, 1, w, 'incomplete', { unresolved: [{ after: h + 1, phrase: '', position: pos(h + 5) }] })), false],
      ['an unresolved read after a stop the walk does not have',
        thenRight(walkRows(R, 1, w, 'incomplete', { unresolved: [{ after: w.length + 1, phrase: '', position: pos(w.length) }] })), false],
      ['an end witness whose move forward read the last stop away from its recorded position', replaced('-end',
        endRow(R, 1, { back: witnessOf(w).back, forward: { phrase: w.at(-1), position: '9, 9, 9, 9' } })), false],
      ['an end witness whose move back read at the last stop\'s recorded position', transcript(() => rows.flatMap((row) => (row === R
        ? walkRows(R, 1, w, 'complete', { positions: [...placesOf(w).slice(0, -1), pos(w.length - 2)] }) : rowsOf(row)))), false],
      // An unresolved read hides no words.
      ['an unresolved read after the start that read a wrong title, then a clean walk',
        thenRight(walkRows(R, 1, w.slice(1), 'incomplete', { unresolved: [{ after: 0, phrase: WRONG_TITLE, position: BACK.position }] })), false],
      ['an unresolved read mid-walk whose words differ from the stop before it',
        thenRight(walkRows(R, 1, w, 'incomplete', { unresolved: [{ after: 3, phrase: 'Extra', position: pos(2) }] })), false],
      // A help message, judged by the walk's rule from the positions row.
      ['a help message tied by its position to the stop before it, whose role it names', withHelp(tiedAt), true],
      ['the same help message at a new position', withHelp(placesOf(helped)), false],
      ['the same help message with the positions row one short', withHelp(tiedAt.slice(1)), false],
      ['the same help message with no positions row', transcript(() => rows.flatMap((row) => (row === TIED.slug
        ? walkRows(row, 1, helped, 'complete', { positions: tiedAt }).filter((r) => !r.includes('-positions`')) : rowsOf(row)))), false],
    ];
    for (const [what, text, ok] of cases) {
      const problems = judgeTranscript(text);
      expect(problems.length === 0, `${what}: ${problems.join('; ') || 'no problems'}`).toBe(ok);
    }
  });

  test('the end witness\'s move back: the stop before the last, or VoiceOver\'s help about it, in either wording, at exactly its recorded position', async () => {
    const [a, b] = WITNESS.pair;
    const at = (i) => `318, ${251 + 40 * i}, 1011, ${271 + 40 * i}`;
    const stops = ['heading level 2 Example', a, b];
    const positions = [at(0), at(1), at(2)];
    const inHelp = WITNESS.help.replace(/^You are currently on /, 'You are currently in ');
    const cases = [
      ['the stop before the last, read again', { phrase: a, position: at(1) }, positions, true],
      ['help naming its role, at its recorded position', { phrase: WITNESS.help, position: at(1) }, positions, true],
      ['help in the other wording naming its role, at its recorded position', { phrase: inHelp, position: at(1) }, positions, true],
      ['help naming another role, at its recorded position', { phrase: WITNESS.wrongHelp, position: at(1) }, positions, false],
      ['help naming its role, at another position', { phrase: WITNESS.help, position: at(7) }, positions, false],
      ['help naming its role, at the last stop\'s position', { phrase: WITNESS.help, position: at(2) }, positions, false],
      ['help naming its role, with no positions', { phrase: WITNESS.help, position: at(1) }, undefined, false],
      ['help naming its role, with positions one short', { phrase: WITNESS.help, position: at(1) }, positions.slice(1), false],
      ['an empty reading at its recorded position', { phrase: '', position: at(1) }, positions, false],
      ['the last stop again at its position (a frozen capture)', { phrase: b, position: at(2) }, positions, false],
    ];
    for (const [what, back, p, holds] of cases) expect(witnessBackHolds(back, stops, p), what).toBe(holds);
    // The collector, on a made-up screen of those stops, whose move back
    // reads the help at the stop's position, or elsewhere.
    const walk = async (back) => {
      let cursor = -1;
      let witnessing = false;
      return collectWalk({
        next: async () => { cursor = Math.min(cursor + 1, stops.length - 1); },
        previous: async () => { witnessing = true; cursor = Math.max(cursor - 1, 0); },
        capture: async () => (witnessing && cursor === 1 ? back : { phrase: stops[cursor], position: at(cursor) }),
        start: { phrase: '', position: '1, 1, 1, 1' },
      });
    };
    const held = await walk({ phrase: WITNESS.help, position: at(1) });
    expect(held.reachedEnd, 'help at the recorded position').toBe(true);
    expect(held.problem, 'help at the recorded position').toBeNull();
    expect(held.witness.back.phrase, 'the end row keeps the help as captured').toBe(WITNESS.help);
    for (const back of [{ phrase: WITNESS.help, position: at(7) }, { phrase: WITNESS.wrongHelp, position: at(1) }]) {
      const failed = await walk(back);
      expect(failed.problem, JSON.stringify(back)).toMatch(/^the end is not witnessed: a move back read/);
    }
    // judgeTranscript, from the positions row.
    const wr = WITNESS.row;
    const ws = whole(wr);
    const wp = placesOf(ws);
    expect(ws.at(-2), 'the row\'s stop before the last is the pair\'s reading').toBe(a);
    const helpEnd = (phrase, position, { noPositions = false } = {}) => transcript(() => rows.flatMap((row) => (row !== wr ? rowsOf(row) : [
      transcriptRow(wr, 1, ws, 'complete', 'x'), startRow(wr, 1, BACK),
      ...(noPositions ? [] : [positionsRow(wr, 1, wp)]),
      endRow(wr, 1, { back: { phrase, position }, forward: { phrase: ws.at(-1), position: wp.at(-1) } }),
      unresolvedRow(wr, 1, [])])));
    const transcripts = [
      ['help naming its role at the stop\'s recorded position', helpEnd(WITNESS.help, wp.at(-2)), true],
      ['the same in the other wording', helpEnd(inHelp, wp.at(-2)), true],
      ['help naming another role there', helpEnd(WITNESS.wrongHelp, wp.at(-2)), false],
      ['help at another position', helpEnd(WITNESS.help, '9, 9, 9, 9'), false],
      ['help at the last stop\'s position', helpEnd(WITNESS.help, wp.at(-1)), false],
      ['help at the recorded position, with no positions row', helpEnd(WITNESS.help, wp.at(-2), { noPositions: true }), false],
    ];
    for (const [what, text, ok] of transcripts) {
      const problems = judgeTranscript(text);
      expect(problems.length === 0, `${what}: ${problems.join('; ') || 'no problems'}`).toBe(ok);
    }
  });

  // The Cupertino fields' names hold a line break: the page's aria-label is
  // "Email\nRequired". tool/voiceover_web.py reads each console line
  // "V01VO <browser> <row> | <text>" to the end of the line only (its
  // regular expression, `^V01VO (\S+) (\S+) \| (.*)$` with re.M, copied in
  // toolRows), so a phrase holding a line break would cut its row in two.
  // The walk records every phrase through spokenText; this test drives the
  // collector with captures that hold line breaks, prints the lines as the
  // VoiceOver spec does (walkLogLines), turns them into the transcript as
  // the tool does, and judges it.
  test('a phrase with a line break (the Cupertino field\'s "Email\\nRequired") survives the walk\'s console row and the transcript row', async () => {
    const toolRows = (log) => {
      const out = new Map();
      for (const [, browser, slug, spoken] of log.matchAll(/^V01VO (\S+) (\S+) \| (.*)$/gm)) out.set(`${browser} ${slug}`, spoken);
      return BROWSERS.flatMap((b) => section(b, [...out].filter(([k]) => k.startsWith(`${b} `))
        .map(([k, spoken]) => `| \`${k.slice(b.length + 1)}\` | ${spoken} |`)));
    };
    const transcriptOf = (log) => ['# V01 Colour contrast: VoiceOver transcript (web, macOS)', '', 'Result: PASS', ...toolRows(log)].join('\n');
    const raw = (s) => s.replace('Email Required', 'Email\nRequired');
    expect(raw(readingOf(EXPECTED_STOPS['good-cupertino'][0])), 'the field\'s name as the page has it').toBe('Email\nRequired edit text');
    expect(spokenText('Email\nRequired  edit text\n')).toBe('Email Required edit text');
    // One walk of every example in both browsers, each capture made as the
    // VoiceOver spec makes it, from raw phrases with the page's line break,
    // through `record`.
    const walkLog = async (record) => {
      const lines = [];
      for (const b of BROWSERS) {
        for (const row of rows) {
          const words = whole(row);
          let cursor = -1;
          const latest = await collectWalk({
            next: async () => { cursor = Math.min(cursor + 1, words.length - 1); },
            previous: async () => { cursor = Math.max(cursor - 1, 0); },
            capture: async () => ({ phrase: record(raw(words[cursor])), position: pos(cursor) }),
            start: { phrase: '', position: '30, 147, 70, 187' },
            whole: wholeScreen(TRANSCRIPT_ROWS[row].expected, TRANSCRIPT_ROWS[row].screen),
          });
          const judged = judgeCollectedWalk(latest, TRANSCRIPT_ROWS[row].expected, TRANSCRIPT_ROWS[row].screen);
          lines.push(...walkLogLines(b, row, 1, judged, latest));
        }
      }
      return lines.join('\n');
    };
    const log = await walkLog(spokenText);
    expect(log.split('\n').every((l) => l.startsWith('V01VO ')), 'every printed line is a row').toBe(true);
    expect(log).toContain('| heading level 1 Cupertino field with stronger greys / Good example for Colour contrast. Cupertino. / heading level 2 Example / Email Required edit text / Send button (complete:');
    expect(judgeTranscript(transcriptOf(log))).toEqual([]);
    // The control: phrases recorded with their line break. The cut rows
    // lose the rest of their walk, and the transcript fails.
    const cut = await walkLog((s) => s);
    expect(cut.split('\n').some((l) => !l.startsWith('V01VO ')), 'a line break cuts a row').toBe(true);
    expect(judgeTranscript(transcriptOf(cut)).length).toBeGreaterThan(0);
  });

  test('the committed recording (docs/evidence/V01/voiceover-web.md) is right, every browser and row once', () => {
    // Never skipped: a missing file fails here, with what to do.
    const file = new URL('../docs/evidence/V01/voiceover-web.md', import.meta.url);
    expect(fs.existsSync(file),
      'docs/evidence/V01/voiceover-web.md is missing: the web VoiceOver recording has not been made yet '
      + '(python3 tool/voiceover_web.py V01, run by the principal only)').toBe(true);
    expect(judgeTranscript(fs.readFileSync(file, 'utf8'))).toEqual([]);
  });
});

// --- The web VoiceOver text fields ------------------------------------------
//
// The principal's decisions of 2026-11-28, after the first web recording
// (docs/evidence/probes/v01/voiceover-web-round1-fail.md.txt), which failed
// on the text fields only (the header of web_tests/vo/v01_vo_walks.js): the
// three fields with a hint are one stop each, judged by FIELD_PATTERN; such a
// field read again in a form of it at exactly its position is a re-read, not
// a stop, marked on the positions row; the end witness on a marked text field
// may read "" or another form of it forward, at exactly its position, and,
// back, the stop before the last in its other form only when that stop is a
// field with a hint, at exactly its position. Nothing else is relaxed.
//
// Each case is a made-up walk through collectWalk and judgeCollectedWalk,
// then the same walk's rows (walkLogLines, as the tool writes them),
// recorded "complete" whatever it judged, in a transcript of right walks,
// through judgeTranscript, which must come to the same verdict from the rows
// alone. Then the first recording's own rows, judged again. Never skipped.
test.describe('the text fields: one stop by FIELD_PATTERN, a same-position re-read, and the end witness on a field', () => {
  const P = (i) => `318, ${251 + 40 * i}, 1011, ${271 + 40 * i}`;
  const START = { phrase: '', position: '30, 147, 70, 187' };
  const ER = 'Email Required edit text';
  const ERR = 'Email Required Required edit text';
  const WRONG_FORMS = ['Email Required Required Required edit text', 'Email edit', 'Email Required edit text button'];
  const HINTED = ['good-material', 'good-cupertino', 'bad-cupertino-placeholder'];
  const allOf = (slug) => wholeScreen(EXPECTED_STOPS[slug], screenStops(slug));
  const fieldAt = (slug) => allOf(slug).findIndex(isMarkedField);
  const headingAt = (slug) => screenStops(slug).length;
  const elementsOf = (slug) => allOf(slug).map((e, i) => ({ phrase: readingOf(e), position: P(i) }));
  /** `slug`'s elements with `extra` put in after the element at `after`. */
  const withAfter = (slug, after, extra) => {
    const els = elementsOf(slug);
    return [...els.slice(0, after + 1), extra, ...els.slice(after + 1)];
  };
  /**
   * A walk of `elements` (by default `slug`'s screen, each element its
   * sample reading at P(i)) with `slug`'s whole screen given to collectWalk.
   * `reads({ cursor, visit, phase })` may give another capture: `visit`
   * counts the captures at the cursor's element, `phase` is "walk", then
   * "back" and "forward" for the end witness.
   */
  const walkOn = (slug, reads = () => undefined, elements = elementsOf(slug)) => {
    let cursor = -1;
    let phase = 'walk';
    const visits = new Map();
    return collectWalk({
      next: async () => {
        if (phase === 'back') phase = 'forward';
        cursor = Math.min(cursor + 1, elements.length - 1);
      },
      previous: async () => { phase = 'back'; cursor = Math.max(cursor - 1, 0); },
      capture: async () => {
        const visit = (visits.get(cursor) ?? 0) + 1;
        visits.set(cursor, visit);
        return reads({ cursor, visit, phase }) ?? elements[cursor];
      },
      start: START,
      whole: allOf(slug),
    });
  };
  /** Reads the element at `index` as `phrase` at its own position, every time. */
  const readAs = (index, phrase) => ({ cursor }) => (cursor === index ? { phrase, position: P(index) } : undefined);
  /** Reads the witness's move `side` ("back" or "forward") as `capture`. */
  const witnessReads = (side, capture) => ({ phase }) => (phase === side ? capture : undefined);
  // The tool's way from console lines to the transcript (the line-break
  // test above has the same).
  const transcriptOf = (lines) => {
    const out = new Map();
    for (const [, b, row, spoken] of lines.join('\n').matchAll(/^V01VO (\S+) (\S+) \| (.*)$/gm)) out.set(`${b} ${row}`, spoken);
    return ['# V01 Colour contrast: VoiceOver transcript (web, macOS)', '', 'Result: PASS',
      ...BROWSERS.flatMap((b) => ['', `## ${b}`, '', '| Example | Spoken, in order |', '| --- | --- |',
        ...[...out].filter(([k]) => k.startsWith(`${b} `)).map(([k, spoken]) => `| \`${k.slice(b.length + 1)}\` | ${spoken} |`)]),
    ].join('\n');
  };
  /**
   * judgeTranscript's problems for a transcript of right walks of every row
   * in both browsers, but `slug`'s in Chromium, which is `walk`, recorded
   * "complete" whatever it judged.
   */
  const transcriptProblems = async (slug, walk) => {
    const lines = [];
    for (const b of BROWSERS) {
      for (const s of Object.keys(EXPECTED_STOPS)) {
        const w = b === 'chromium' && s === slug ? walk : await walkOn(s);
        lines.push(...walkLogLines(b, s, 1, { verdict: 'complete', reason: 'x' }, w));
      }
    }
    return judgeTranscript(transcriptOf(lines));
  };
  /** Each case `[what, slug, walk, verdict]`: the walk judges `verdict`, and its rows pass judgeTranscript only if complete. */
  const check = async (cases) => {
    for (const [what, slug, walking, verdict] of cases) {
      const walk = await walking;
      const judged = judgeCollectedWalk(walk, EXPECTED_STOPS[slug], screenStops(slug));
      expect(judged.verdict, `${what}: ${judged.reason}: ${JSON.stringify(walkReadings(walk).readings)}`).toBe(verdict);
      const problems = await transcriptProblems(slug, walk);
      expect(problems.length === 0, `${what}, from the transcript's rows: ${problems.join('; ') || 'no problems'}`)
        .toBe(verdict === 'complete');
    }
  };

  test('exactly the three fields with a hint are field-pattern stops, and bad-faint-edge\'s field a text field', async () => {
    const marked = Object.entries(EXPECTED_STOPS).flatMap(([slug, list]) => list
      .map((entry, i) => [slug, i, entry]).filter(([, , entry]) => typeof entry !== 'string'));
    expect(marked.map(([slug, i, entry]) => [slug, i, entry.kind])).toEqual([
      ['good-material', 1, 'text field with a hint'],
      ['good-cupertino', 0, 'text field with a hint'],
      ['bad-cupertino-placeholder', 0, 'text field with a hint'],
      ['bad-faint-edge', 0, 'text field'],
    ]);
    expect(String(FIELD_PATTERN)).toBe('/^Email( Required){0,2} edit text$/');
    for (const [, , entry] of marked) expect(isMarkedField(entry)).toBe(true);
    expect(EXPECTED_STOPS['bad-faint-edge'][0].text).toBe('Email edit text');
    expect(isFieldWithHint(EXPECTED_STOPS['bad-faint-edge'][0])).toBe(false);
    // The pattern is matched after white space is made single spaces.
    const hint = EXPECTED_STOPS['good-cupertino'][0];
    for (const form of ['Email edit text', ER, ERR, 'Email\nRequired edit text', ' Email  Required edit text ']) {
      expect(matchesStop(form, hint), form).toBe(true);
    }
    for (const form of ['', ...WRONG_FORMS, 'email edit text', 'Required edit text', 'Email Required']) {
      expect(matchesStop(form, hint), form).toBe(false);
    }
    // A text field with no hint, by its words exactly.
    expect(matchesStop('Email edit text', EXPECTED_STOPS['bad-faint-edge'][0])).toBe(true);
    expect(matchesStop(ER, EXPECTED_STOPS['bad-faint-edge'][0])).toBe(false);
    // Every walk of the right screens passes.
    await check(Object.keys(EXPECTED_STOPS).map((slug) => [`${slug}, its right walk`, slug, walkOn(slug), 'complete']));
  });

  test('a field with a hint is one stop in any of its three forms; any other form, and a heading read with a word repeated, is wrong', async () => {
    const cases = [];
    for (const slug of HINTED) {
      const f = fieldAt(slug);
      for (const form of ['Email edit text', ER, ERR]) cases.push([`${slug}: the field read "${form}"`, slug, walkOn(slug, readAs(f, form)), 'complete']);
      for (const form of WRONG_FORMS) cases.push([`${slug}: the field read "${form}"`, slug, walkOn(slug, readAs(f, form)), 'wrong']);
    }
    for (const slug of ['good-material', 'good-caption', 'bad-cupertino-placeholder']) {
      cases.push([`${slug}: the heading read "heading level 2 Example Example"`, slug,
        walkOn(slug, readAs(headingAt(slug), 'heading level 2 Example Example')), 'wrong']);
    }
    // bad-faint-edge's field has no hint: its words, exactly.
    cases.push(['bad-faint-edge: the field read "Email Required edit text"', 'bad-faint-edge',
      walkOn('bad-faint-edge', readAs(fieldAt('bad-faint-edge'), ER)), 'wrong']);
    await check(cases);
  });

  test('a field with a hint read again at exactly its position is that stop read again; anything else is a stop', async () => {
    const bad = 'bad-cupertino-placeholder';
    const f = fieldAt(bad);
    // The first recording's Chromium walk of bad-cupertino-placeholder:
    // "Email Required edit text", then "Email Required Required edit text"
    // at the same position, and that form again for the witness's move
    // forward.
    const round1 = await walkOn(bad, ({ cursor, visit }) => (cursor === f && visit > 1 ? { phrase: ERR, position: P(f) } : undefined));
    expect(round1.rereads).toEqual([{ after: f + 1, phrase: ERR, position: P(f) }]);
    expect(round1.stops).toEqual(allOf(bad).map(readingOf));
    expect(round1.witness.forward).toEqual({ phrase: ERR, position: P(f) });
    const { readings, places } = walkReadings(round1);
    expect(readings).toEqual([...allOf(bad).map(readingOf), ERR]);
    expect(places.at(-1)).toBe(rereadAt(P(f)));
    expect(positionsRow(bad, 1, places)).toBe(`| \`${bad}-walk-1-positions\` | ${[...round1.positions, `${REREAD}${P(f)}`].join(' / ')} |`);
    expect(splitReadings(readings, positionsOf(places.join(' / ')))).toEqual(
      { stops: round1.stops, positions: round1.positions, rereads: round1.rereads });
    const gm = 'good-material';
    const g = fieldAt(gm);
    const cup = 'good-cupertino';
    const faint = 'bad-faint-edge';
    await check([
      ['the first recording\'s same-position re-read (bad-cupertino-placeholder, Chromium)', bad, round1, 'complete'],
      // How many times "Required" is read is recorded, not judged.
      ['the field read in one form, the other, and the first again, all at its position', bad,
        walkOn(bad, ({ cursor, visit }) => (cursor === f && visit === 2 ? { phrase: ERR, position: P(f) } : undefined)), 'complete'],
      // good-material's field reads "Email Required Required edit text"
      // (its sample), then "Email edit text" at its position.
      ['good-material\'s field read again in another form at its position, mid-walk', gm,
        walkOn(gm, undefined, withAfter(gm, g, { phrase: 'Email edit text', position: P(g) })), 'complete'],
      ['good-cupertino\'s field read again in another form at its position, mid-walk', cup,
        walkOn(cup, undefined, withAfter(cup, fieldAt(cup), { phrase: ERR, position: P(fieldAt(cup)) })), 'complete'],
      // A second field reading at a different position is a second stop.
      ['a second field reading at another position, after the last stop', bad,
        walkOn(bad, undefined, withAfter(bad, f, { phrase: ERR, position: P(99) })), 'wrong'],
      ['a second field reading at another position, mid-walk', gm,
        walkOn(gm, undefined, withAfter(gm, g, { phrase: ERR, position: P(98) })), 'wrong'],
      // A different phrase at the same position is a stop, as before.
      ['"Email Required Required Required edit text" at the field\'s position after it', gm,
        walkOn(gm, undefined, withAfter(gm, g, { phrase: WRONG_FORMS[0], position: P(g) })), 'wrong'],
      ['a field form at the position of a stop that is no field', gm,
        walkOn(gm, undefined, withAfter(gm, g - 1, { phrase: 'Email edit text', position: P(g - 1) })), 'wrong'],
      ['a field form at the heading\'s position after it', bad,
        walkOn(bad, undefined, withAfter(bad, headingAt(bad), { phrase: ER, position: P(headingAt(bad)) })), 'wrong'],
      // bad-faint-edge's field has no hint: no re-read on its screen.
      ['bad-faint-edge\'s field read again as "Email Required edit text" at its position', faint,
        walkOn(faint, undefined, withAfter(faint, fieldAt(faint), { phrase: ER, position: P(fieldAt(faint)) })), 'wrong'],
    ]);
  });

  test('the end witness on a marked text field: forward "" or a form of it at exactly its position; back, the other form only for a field with a hint at its position', async () => {
    const faint = 'bad-faint-edge';
    const ff = fieldAt(faint);
    const bad = 'bad-cupertino-placeholder';
    const bf = fieldAt(bad);
    const cup = 'good-cupertino';
    const cf = fieldAt(cup);
    const lastAt = (slug) => P(allOf(slug).length - 1);
    await check([
      // The move forward.
      ['bad-faint-edge: forward "" at the field\'s position (the first recording)', faint,
        walkOn(faint, witnessReads('forward', { phrase: '', position: P(ff) })), 'complete'],
      ['bad-faint-edge: forward "" at another position', faint, walkOn(faint, witnessReads('forward', { phrase: '', position: P(50) })), 'wrong'],
      ['bad-faint-edge: forward "Email Required edit text" at its position', faint,
        walkOn(faint, witnessReads('forward', { phrase: ER, position: P(ff) })), 'wrong'],
      ['bad-cupertino-placeholder: forward "" at the field\'s position', bad,
        walkOn(bad, witnessReads('forward', { phrase: '', position: P(bf) })), 'complete'],
      ['bad-cupertino-placeholder: forward the other form at its position', bad,
        walkOn(bad, witnessReads('forward', { phrase: ERR, position: P(bf) })), 'complete'],
      ['bad-cupertino-placeholder: forward the other form at another position', bad,
        walkOn(bad, witnessReads('forward', { phrase: ERR, position: P(50) })), 'wrong'],
      ['bad-cupertino-placeholder: forward "Email Required Required Required edit text" at its position', bad,
        walkOn(bad, witnessReads('forward', { phrase: WRONG_FORMS[0], position: P(bf) })), 'wrong'],
      // No leniency for any other last stop.
      ['good-material: forward "" on its last stop, a button, at its position', 'good-material',
        walkOn('good-material', witnessReads('forward', { phrase: '', position: lastAt('good-material') })), 'wrong'],
      ['good-cupertino: forward "" on its last stop, a button, at its position', cup,
        walkOn(cup, witnessReads('forward', { phrase: '', position: lastAt(cup) })), 'wrong'],
      ['good-caption: forward "" on its last stop, a text, at its position', 'good-caption',
        walkOn('good-caption', witnessReads('forward', { phrase: '', position: lastAt('good-caption') })), 'wrong'],
      // The move back.
      ['good-cupertino: back the field\'s other form at its recorded position (the first recording, Chromium)', cup,
        walkOn(cup, witnessReads('back', { phrase: ERR, position: P(cf) })), 'complete'],
      ['good-cupertino: back "Email edit text" at the field\'s recorded position', cup,
        walkOn(cup, witnessReads('back', { phrase: 'Email edit text', position: P(cf) })), 'complete'],
      ['good-cupertino: back the field\'s other form at another position', cup,
        walkOn(cup, witnessReads('back', { phrase: ERR, position: P(50) })), 'wrong'],
      ['good-cupertino: back "Email Required Required Required edit text" at its position', cup,
        walkOn(cup, witnessReads('back', { phrase: WRONG_FORMS[0], position: P(cf) })), 'wrong'],
      ['good-cupertino: back "" at the field\'s position', cup, walkOn(cup, witnessReads('back', { phrase: '', position: P(cf) })), 'wrong'],
      ['good-material: back a field form at the position of its stop before the last, a checkbox', 'good-material',
        walkOn('good-material', witnessReads('back', { phrase: ERR, position: P(allOf('good-material').length - 2) })), 'wrong'],
      ['bad-cupertino-placeholder: back a field form at the heading\'s position', bad,
        walkOn(bad, witnessReads('back', { phrase: ER, position: P(headingAt(bad)) })), 'wrong'],
    ]);
    // The rules as functions; with no screen given, S16's exactly.
    const stops = [EXAMPLE_HEADING, ER];
    const positions = [P(0), P(1)];
    expect(witnessForwardHolds({ phrase: '', position: P(1) }, stops, positions)).toBe(false);
    expect(witnessForwardHolds({ phrase: ER, position: P(1) }, stops, positions)).toBe(true);
    expect(witnessForwardHolds({ phrase: '', position: P(1) }, stops, positions, allOf(bad))).toBe(true);
    expect(witnessForwardHolds({ phrase: '', position: P(1) }, stops, undefined, allOf(bad))).toBe(false);
    expect(witnessBackHolds({ phrase: ERR, position: P(0) }, [ER, 'Send button'], positions)).toBe(false);
    expect(witnessBackHolds({ phrase: ERR, position: P(0) }, [ER, 'Send button'], positions, allOf(cup))).toBe(true);
  });

  test('judgeWalk takes a re-read only of a field with a hint, at exactly its recorded position', () => {
    const judge = (slug, rereads, { positions = allOf(slug).map((_, i) => P(i)), gaps = [] } = {}) => judgeWalk(
      allOf(slug).map(readingOf), true, EXPECTED_STOPS[slug], screenStops(slug), positions, gaps, rereads).verdict;
    const gm = 'good-material';
    const g = fieldAt(gm) + 1; // the field, as "after stop K"
    const faint = 'bad-faint-edge';
    const ff = fieldAt(faint) + 1;
    const cases = [
      ['a re-read of good-material\'s field at its position', judge(gm, [{ after: g, phrase: ER, position: P(g - 1) }]), 'complete'],
      ['the same, with a gap before it', judge(gm, [{ after: g, phrase: ER, position: P(g - 1) }], { gaps: [1] }), 'incomplete'],
      ['a re-read at another position', judge(gm, [{ after: g, phrase: ER, position: P(70) }]), 'wrong'],
      ['a re-read with no positions recorded', judge(gm, [{ after: g, phrase: ER, position: P(g - 1) }], { positions: null }), 'wrong'],
      ['a re-read in a form no field has', judge(gm, [{ after: g, phrase: WRONG_FORMS[2], position: P(g - 1) }]), 'wrong'],
      ['a re-read of a stop that is no field (the paragraph)', judge(gm, [{ after: g - 1, phrase: ER, position: P(g - 2) }]), 'wrong'],
      ['a re-read before any stop', judge(gm, [{ after: 0, phrase: ER, position: START.position }]), 'wrong'],
      ['a re-read after a stop the walk does not have', judge(gm, [{ after: 99, phrase: ER, position: P(98) }]), 'wrong'],
      // bad-faint-edge's field reads as a field form, but is no field with
      // a hint: no re-read of it is taken, with or without a gap.
      ['a re-read of bad-faint-edge\'s field at its position', judge(faint, [{ after: ff, phrase: ER, position: P(ff - 1) }]), 'wrong'],
      ['the same, with a gap before it', judge(faint, [{ after: ff, phrase: ER, position: P(ff - 1) }], { gaps: [1] }), 'wrong'],
    ];
    for (const [what, verdict, want] of cases) expect(verdict, what).toBe(want);
  });

  test('the first recording\'s rows pass by these rules, with its re-read marked, and fail with any of these faults', () => {
    // Never skipped: the first recording is committed; a missing file throws.
    const round1 = fs.readFileSync(new URL('../docs/evidence/probes/v01/voiceover-web-round1-fail.md.txt', import.meta.url), 'utf8');
    // Its walk rows as recorded "complete" (it recorded the walks wrong by
    // the rules of the time).
    const asComplete = (text) => text.split('\n').map((l) => (/^\| `[a-z-]+-walk-\d+` \|/.test(l)
      ? l.replace(/ \((?:complete|wrong|incomplete): .*\) \|$/, ' (complete: x) |') : l)).join('\n');
    // `f` applied to the row named `row` in `browser`'s section only.
    const edit = (text, browser, row, f) => {
      let b = null;
      return text.split('\n').map((l) => {
        const section = /^## (\S+)$/.exec(l);
        if (section) [, b] = section;
        return b === browser && l.startsWith(`| \`${row}\` |`) ? f(l) : l;
      }).join('\n');
    };
    const changed = (text, browser, row, f) => {
      const out = edit(text, browser, row, f);
      expect(out, `${browser} ${row} was changed`).not.toBe(text);
      return out;
    };
    const plain = asComplete(round1);
    const FIELD = '318, 367, 1014, 409'; // bad-cupertino-placeholder's field in Chromium
    const marked = changed(plain, 'chromium', 'bad-cupertino-placeholder-walk-1-positions',
      (l) => l.replace(` / ${FIELD} |`, ` / ${rereadAt(FIELD)} |`));
    expect(judgeTranscript(marked)).toEqual([]);
    const headingTwice = changed(changed(marked, 'chromium', 'good-caption-walk-1-positions',
      (l) => l.replace(' / 334, 399, 994, 415 |', ` / ${rereadAt('318, 259, 1006, 287')} / 334, 399, 994, 415 |`)),
    'chromium', 'good-caption-walk-1', (l) => l.replace('/ heading level 2 Example /', '/ heading level 2 Example / heading level 2 Example /'));
    const cases = [
      ['as it was recorded, walks wrong', round1],
      // The same-position re-read missing from its row: a second stop.
      ['the re-read not marked on the positions row', plain],
      ['the re-read\'s reading missing from the walk row, its position marked', changed(marked, 'chromium', 'bad-cupertino-placeholder-walk-1',
        (l) => l.replace(` / ${ERR} (complete: x) |`, ' (complete: x) |'))],
      ['the re-read marked at another position', changed(marked, 'chromium', 'bad-cupertino-placeholder-walk-1-positions',
        (l) => l.replace(rereadAt(FIELD), rereadAt('318, 400, 1014, 442')))],
      ['the second field reading at another position, not marked', changed(plain, 'chromium', 'bad-cupertino-placeholder-walk-1-positions',
        (l) => l.replace(` / ${FIELD} |`, ' / 318, 400, 1014, 442 |'))],
      ['a re-read marked on a stop that is no field (the heading read again)', headingTwice],
      // The end witness.
      ['good-cupertino\'s back witness in the other form at another position', changed(marked, 'chromium', 'good-cupertino-walk-1-end',
        (l) => l.replace(`back "${ERR}" at 318, 335, 1014, 377`, `back "${ERR}" at 318, 300, 1014, 342`))],
      ['bad-faint-edge\'s forward witness "Email Required edit text"', changed(marked, 'chromium', 'bad-faint-edge-walk-1-end',
        (l) => l.replace('forward "" at', `forward "${ER}" at`))],
      ['bad-faint-edge\'s forward witness "" at another position', changed(marked, 'webkit', 'bad-faint-edge-walk-1-end',
        (l) => l.replace('forward "" at 526, 308, 1228, 364', 'forward "" at 526, 300, 1228, 356'))],
      ['an empty forward witness on good-material\'s last stop, a button', changed(marked, 'chromium', 'good-material-walk-1-end',
        (l) => l.replace('forward "Send button"', 'forward ""'))],
      // The words.
      ...WRONG_FORMS.map((form) => [`good-material's field read "${form}"`, changed(marked, 'webkit', 'good-material-walk-1',
        (l) => l.replace(` / ${ERR} / `, ` / ${form} / `))]),
      ['a heading read "heading level 2 Example Example"', changed(marked, 'chromium', 'good-caption-walk-1',
        (l) => l.replace('/ heading level 2 Example /', '/ heading level 2 Example Example /'))],
    ];
    for (const [what, text] of cases) {
      expect(judgeTranscript(text).length, what).toBeGreaterThan(0);
    }
  });
});


// The web VoiceOver fixture's keeping of the Mac's VoiceOver state, V12's
// regressions copied
// (withVoiceOverState in web_tests/vo/v01_vo_state.js), on doubles: a
// made-up VoiceOver whose process state is a variable, and whose start,
// stop, restart and quit do what each case says. No VoiceOver is started.
test.describe('the web VoiceOver fixture puts the Mac\'s VoiceOver back as it found it, and fails if it cannot', () => {
  /** A made-up Mac: `on` is whether a VoiceOver process is running. */
  function mac({ on, startFails = false, walkFails = false, stopFails = false, stopLeavesOn = false,
    stopRestoresUser = true, restartFails = false, quitFails = false, readFails = false } = {}) {
    const m = { on, calls: [], lines: [] };
    let userQuit = false;
    m.isRunning = () => {
      if (readFails) throw new Error("VoiceOver's state could not be read (pgrep -x VoiceOver: 2)");
      return m.on;
    };
    m.start = async () => {
      m.calls.push('start');
      if (startFails) throw new Error('start failed');
      if (m.on) userQuit = true; // as Guidepup quits the user's own VoiceOver
      m.on = true;
    };
    m.use = async () => {
      m.calls.push('walk');
      if (walkFails) throw new Error('the walk read a wrong stop');
    };
    m.stop = async () => {
      m.calls.push('stop');
      if (stopFails) throw new Error('stop failed');
      if (!stopLeavesOn) m.on = userQuit && stopRestoresUser;
    };
    m.restart = async () => { m.calls.push('restart'); if (restartFails) throw new Error('restart failed'); m.on = true; };
    m.quit = async () => { m.calls.push('quit'); if (!quitFails) m.on = false; };
    m.run = () => withVoiceOverState({
      isRunning: m.isRunning, start: m.start, use: m.use, stop: m.stop, restart: m.restart, quit: m.quit,
      wait: async () => m.isRunning(), log: (l) => m.lines.push(l),
    });
    return m;
  }

  test('found off, a walk that passed: off again, no error', async () => {
    const m = mac({ on: false });
    expect(await m.run()).toBe(false);
    expect(m.on).toBe(false);
    expect(m.calls).toEqual(['start', 'walk', 'stop']);
    expect(m.lines).toEqual(['found off', 'left off']);
  });

  test('found on, Guidepup restoring it: on again, nothing more done', async () => {
    const m = mac({ on: true });
    expect(await m.run()).toBe(true);
    expect(m.on).toBe(true);
    expect(m.calls).toEqual(['start', 'walk', 'stop']);
  });

  test('found on, Guidepup not restoring it: restarted here, and on again', async () => {
    const m = mac({ on: true, stopRestoresUser: false });
    expect(await m.run()).toBe(true);
    expect(m.on).toBe(true);
    expect(m.calls).toEqual(['start', 'walk', 'stop', 'restart']);
  });

  test('a failed walk: VoiceOver still put back, and the walk\'s error reported', async () => {
    const m = mac({ on: false, walkFails: true });
    await expect(m.run()).rejects.toThrow(/the walk: the walk read a wrong stop/);
    expect(m.on).toBe(false);
  });

  test('a failed stop fails the test, even with VoiceOver then put back', async () => {
    const m = mac({ on: false, stopFails: true });
    await expect(m.run()).rejects.toThrow(/VoiceOver's stop failed: stop failed/);
    expect(m.calls).toEqual(['start', 'walk', 'stop', 'quit']);
    expect(m.on).toBe(false);
  });

  test('a stop that leaves VoiceOver on is put right by a quit, and passes', async () => {
    const m = mac({ on: false, stopLeavesOn: true });
    expect(await m.run()).toBe(false);
    expect(m.calls).toEqual(['start', 'walk', 'stop', 'quit']);
  });

  test('a failed restore fails the test: found on and not restarted, or found off and not quit', async () => {
    const on = mac({ on: true, stopRestoresUser: false, restartFails: true });
    await expect(on.run()).rejects.toThrow(/VoiceOver not put back on: restart failed/);
    const off = mac({ on: false, stopLeavesOn: true, quitFails: true });
    await expect(off.run()).rejects.toThrow(/VoiceOver not put back: found off, left on/);
  });

  test('a failed walk and a failed stop and restore are all reported', async () => {
    const m = mac({ on: false, walkFails: true, stopFails: true, quitFails: true });
    await expect(m.run()).rejects.toThrow(
      /the walk: the walk read a wrong stop; VoiceOver's stop failed: stop failed; VoiceOver not put back: found off, left on/);
  });

  test('a failed start is reported, and VoiceOver is still read and left as found', async () => {
    const m = mac({ on: false, startFails: true });
    await expect(m.run()).rejects.toThrow(/the walk: start failed/);
    expect(m.calls).toEqual(['start', 'stop']);
    expect(m.on).toBe(false);
  });

  test('a state that cannot be read fails before VoiceOver is started', async () => {
    const m = mac({ on: false, readFails: true });
    await expect(m.run()).rejects.toThrow(/could not be read/);
    expect(m.calls).toEqual([]);
  });

  test('the independent read is pgrep -x VoiceOver: running, not running, and no answer', () => {
    const calls = [];
    const exec = (status) => (file, args) => {
      calls.push([file, ...args].join(' '));
      if (status === 0) return '';
      const e = new Error('exit'); e.status = status; throw e;
    };
    expect(voiceOverRunning(exec(0))).toBe(true);
    expect(voiceOverRunning(exec(1))).toBe(false);
    expect(() => voiceOverRunning(exec(2))).toThrow(/could not be read/);
    expect(calls[0]).toBe('/usr/bin/pgrep -x VoiceOver');
  });
});
