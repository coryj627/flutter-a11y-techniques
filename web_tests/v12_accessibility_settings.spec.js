// L3 for V12 Detecting accessibility settings on web: what each example's
// lines say when it opens, and after a browser setting is changed while it
// is open. Spec: docs/specs/V12-accessibility-settings.md. Runs against the
// release build in build/web.
//
// The settings are changed with Playwright's emulateMedia (the media
// features prefers-color-scheme, prefers-reduced-motion, forced-colors and
// prefers-contrast, as the browser would set them from the system), and
// the text size with the page's root font size, standing in for the
// browser's own font size setting, which no Playwright call sets
// (docs/evidence/probes/v12/web.txt). Each change is made once; each
// reading is waited for in a bounded loop. Where a line must not change,
// the witness that the change reached the app is the app's own look: the
// screen goes dark (MaterialApp's dark theme), or the line's own text is
// drawn larger.
import { test, expect } from '@playwright/test';
import zlib from 'node:zlib';
import { readFileSync } from 'node:fs';
import { byId, technique } from './support/techniques.js';
import {
  BROWSERS, EXAMPLE_HEADING, EXAMPLE_SCREENS, EXPECTED_STOPS, collectWalk, endRow, helpRole, judgeCollectedWalk, judgeExampleWalk, startRow,
  judgeTranscript, runWalks, screenStops, spokenRole, transcriptRow, unresolvedRow,
} from './vo/v12_vo_walks.js';

const exampleHeading = (page) => page.getByRole('heading', { name: 'Example', exact: true, level: 2 });
const { open } = technique('V12', { ready: exampleHeading, settle: 600 });

const KEYS = ['navigation', 'bold', 'contrast', 'invert', 'animations', 'labels', 'dark', 'scale'];
// What both settings lists say when they open in a browser with no setting
// changed. Accessible navigation is on with no screen reader running: the
// app turns its semantics on at start (lib/main.dart, as Flutter's web
// accessibility guide says to), and on the web the engine reports
// accessibleNavigation as whether semantics are on (FL-500).
const OPENED = [
  'Accessible navigation: on',
  'Bold text: off',
  'High contrast: off',
  'Invert colours: off',
  'Disable animations: off',
  'Switch labels: off',
  'Dark mode: off',
  'Text scale: 100%',
];

/** What the element with `id` says: its label, or its text. */
const textOf = (page, id) => byId(page, id).evaluate((e) => (e.getAttribute('aria-label') || e.textContent || '').trim());

/** Every line of a settings list, in order. */
const lines = (page, slug) => Promise.all(KEYS.map((k) => textOf(page, `v12-${slug}-${k}`)));

/** Waits, at most five seconds, for the line `key` of `slug` to say `want`. */
async function expectLine(page, slug, key, want) {
  await expect.poll(() => textOf(page, `v12-${slug}-${key}`), { timeout: 5000 }).toBe(want);
}

// --- Pixels, for the witness that the screen went dark ------------------

/** Decodes a PNG of 8-bit RGB or RGBA, not interlaced, as the browsers write. */
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

const lin = (v) => { const s = v / 255; return s <= 0.04045 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4; };
const luminance = (c) => 0.2126 * lin((c >> 16) & 255) + 0.7152 * lin((c >> 8) & 255) + 0.0722 * lin(c & 255);

/** The mean relative luminance of the page, sampled every 8 pixels. */
async function meanLuminance(page) {
  const img = decodePng(await page.screenshot());
  let sum = 0, n = 0;
  for (let y = 0; y < img.height; y += 8) {
    for (let x = 0; x < img.width; x += 8) { sum += luminance(img.at(x, y)); n++; }
  }
  return sum / n;
}

/**
 * The width of the element with `id`, in CSS pixels. A line is one line of
 * text, so its width grows with the text size; its height does not tell,
 * since an element is cut to the part of it in view.
 */
const widthOf = async (page, id) => (await byId(page, id).boundingBox()).width;

// Keep the mouse off every control: nothing here has a tooltip, but the
// pointer stays in a corner all the same (FL-484).
test.beforeEach(async ({ page }) => {
  await page.mouse.move(0, 0);
});

// bad-read-once reads its settings as its screen is first built. Opened
// from its address, that is the app's first frame, which comes before the
// app's first semantics update, and the web engine turns accessibleNavigation
// on only at that update (the engine's EngineSemantics.updateSemantics,
// source read). So it read accessible navigation off, and never reads again.
const OPENED_ONCE = ['Accessible navigation: off', ...OPENED.slice(1)];

test.describe('what each example says when it opens', () => {
  test('good-media-query: one element per setting, in order, accessible navigation on with no screen reader (FL-500)', async ({ page }) => {
    await open(page, 'good-media-query');
    expect(await lines(page, 'good-media-query')).toEqual(OPENED);
    // Eight lines, each its own element, and no other identified element
    // in the example.
    expect(await page.locator('[flt-semantics-identifier^="v12-good-media-query-"]').count()).toBe(8);
  });

  test('bad-read-once: one element per setting, in order, accessible navigation read off as the app started, and kept (FL-500)', async ({ page }) => {
    await open(page, 'bad-read-once');
    expect(await lines(page, 'bad-read-once')).toEqual(OPENED_ONCE);
    expect(await page.locator('[flt-semantics-identifier^="v12-bad-read-once-"]').count()).toBe(8);
    // The witness that accessibleNavigation is on in this page by now:
    // good-media-query, opened in the same page by its address, says so.
    await page.goto('/#/t/V12/good-media-query');
    await expectLine(page, 'good-media-query', 'navigation', 'Accessible navigation: on');
  });

  for (const slug of ['good-motion', 'bad-animations-only']) {
    test(`${slug}: one element, "Reduce motion: off"`, async ({ page }) => {
      await open(page, slug);
      expect(await textOf(page, `v12-${slug}-motion`)).toBe('Reduce motion: off');
      expect(await page.locator(`[flt-semantics-identifier^="v12-${slug}-"]`).count()).toBe(1);
    });
  }
  for (const [slug, navigation] of [['good-media-query', 'on'], ['bad-read-once', 'off']]) {
    test(`${slug}: opened with dark mode, reduced motion and forced colours on, says so`, async ({ page }) => {
      await page.emulateMedia({ colorScheme: 'dark', reducedMotion: 'reduce', forcedColors: 'active' });
      await open(page, slug);
      expect(await lines(page, slug)).toEqual([
        `Accessible navigation: ${navigation}`, 'Bold text: off', 'High contrast: on', 'Invert colours: off',
        'Disable animations: on', 'Switch labels: off', 'Dark mode: on', 'Text scale: 100%',
      ]);
    });
  }
});

test.describe('a setting changed while the example is open', () => {
  // Each media feature, on and then off again, with the line it sets.
  const MEDIA = [
    ['prefers-color-scheme: dark', { colorScheme: 'dark' }, { colorScheme: 'light' }, 'dark', 'Dark mode'],
    ['prefers-reduced-motion: reduce', { reducedMotion: 'reduce' }, { reducedMotion: 'no-preference' }, 'animations', 'Disable animations'],
    ['forced-colors: active', { forcedColors: 'active' }, { forcedColors: 'none' }, 'contrast', 'High contrast'],
  ];
  for (const [name, on, off, key, label] of MEDIA) {
    test(`good-media-query: ${name} turned on and off again, the line follows it and no other line changes`, async ({ page }) => {
      await open(page, 'good-media-query');
      await page.emulateMedia(on);
      await expectLine(page, 'good-media-query', key, `${label}: on`);
      const changed = OPENED.map((l) => (l.startsWith(`${label}:`) ? `${label}: on` : l));
      expect(await lines(page, 'good-media-query')).toEqual(changed);
      await page.emulateMedia(off);
      await expectLine(page, 'good-media-query', key, `${label}: off`);
      expect(await lines(page, 'good-media-query')).toEqual(OPENED);
    });
  }

  test('good-media-query: a root font size of 32 pixels gives "Text scale: 200%", and back 100%', async ({ page }) => {
    await open(page, 'good-media-query');
    await page.evaluate(() => { document.documentElement.style.fontSize = '32px'; });
    await expectLine(page, 'good-media-query', 'scale', 'Text scale: 200%');
    await page.evaluate(() => { document.documentElement.style.fontSize = ''; });
    await expectLine(page, 'good-media-query', 'scale', 'Text scale: 100%');
  });

  test('good-media-query: prefers-contrast: more leaves "High contrast: off"; only forced colours set it (FL-501)', async ({ page }) => {
    await open(page, 'good-media-query');
    await page.emulateMedia({ contrast: 'more' });
    // The witness that the browser has the setting: the page's own media
    // query matches it.
    expect(await page.evaluate(() => matchMedia('(prefers-contrast: more)').matches)).toBe(true);
    // Given time to arrive; written to fail when Flutter starts to read it.
    await page.waitForTimeout(1500);
    expect(await lines(page, 'good-media-query')).toEqual(OPENED);
    // The control, through the same path in the same page: forced colours
    // does set it.
    await page.emulateMedia({ contrast: 'no-preference', forcedColors: 'active' });
    await expectLine(page, 'good-media-query', 'contrast', 'High contrast: on');
  });

  test('bad-read-once: dark mode turned on, the line still says off, though the screen went dark', async ({ page }) => {
    await open(page, 'bad-read-once');
    const light = await meanLuminance(page);
    expect(light).toBeGreaterThan(0.6);
    await page.emulateMedia({ colorScheme: 'dark' });
    // The witness: the app's dark theme is drawn.
    await expect.poll(() => meanLuminance(page), { timeout: 5000 }).toBeLessThan(0.2);
    expect(await lines(page, 'bad-read-once')).toEqual(OPENED_ONCE);
  });

  test('bad-read-once: reduced motion and forced colours turned on, the lines still say off', async ({ page }) => {
    await open(page, 'bad-read-once');
    await page.emulateMedia({ reducedMotion: 'reduce', forcedColors: 'active' });
    // No witness on this screen shows either change, so the same change is
    // made on good-media-query in the same page after it, and must show.
    await page.waitForTimeout(1500);
    expect(await lines(page, 'bad-read-once')).toEqual(OPENED_ONCE);
    await page.emulateMedia({ reducedMotion: 'no-preference', forcedColors: 'none' });
    await open(page, 'good-media-query');
    await page.emulateMedia({ reducedMotion: 'reduce', forcedColors: 'active' });
    await expectLine(page, 'good-media-query', 'animations', 'Disable animations: on');
    await expectLine(page, 'good-media-query', 'contrast', 'High contrast: on');
  });

  test('bad-read-once: a root font size of 32 pixels, the line still says 100%, though its text is drawn larger', async ({ page }) => {
    await open(page, 'bad-read-once');
    const before = await widthOf(page, 'v12-bad-read-once-scale');
    await page.evaluate(() => { document.documentElement.style.fontSize = '32px'; });
    // The witness: the line's own text is laid out at twice the size.
    await expect.poll(() => widthOf(page, 'v12-bad-read-once-scale'), { timeout: 5000 }).toBeGreaterThan(before * 1.6);
    expect(await textOf(page, 'v12-bad-read-once-scale')).toBe('Text scale: 100%');
  });

  for (const slug of ['good-motion', 'bad-animations-only']) {
    test(`${slug}: prefers-reduced-motion turned on and off again, "Reduce motion: on", then "off"`, async ({ page }) => {
      // On the web the engine sets both reduceMotion and disableAnimations
      // from the one media feature, so bad-animations-only's defect, iOS's,
      // is not seen here.
      await open(page, slug);
      await page.emulateMedia({ reducedMotion: 'reduce' });
      await expectLine(page, slug, 'motion', 'Reduce motion: on');
      await page.emulateMedia({ reducedMotion: 'no-preference' });
      await expectLine(page, slug, 'motion', 'Reduce motion: off');
    });
  }
});

// The web VoiceOver spec's judge, collector, and transcript judge
// (web_tests/vo/v12_vo_walks.js, S16's, copied whole), tested here on
// made-up walks and transcripts, as S16's web tree spec tests its own.
test.describe('the stops the VoiceOver spec expects above each example', () => {
  for (const [slug, [title, ...lines]] of Object.entries(EXAMPLE_SCREENS)) {
    test(`${slug} shows its title and its lines`, async ({ page }) => {
      await open(page, slug);
      await expect(page.getByRole('heading', { name: title, exact: true, level: 1 })).toHaveCount(1);
      for (const line of lines) await expect(page.getByText(line, { exact: true })).toHaveCount(1);
    });
  }
});

const VO_HELP_PREFIX = /^You are currently on /;

// The VoiceOver judge (web_tests/vo/v12_vo_walks.js, S16's copy of S08's), on made-up
// walks. Each test names every case it holds, and fails on the first case
// whose verdict is not the one given, with the case's name.
test.describe('the VoiceOver example walks are judged on every walk', () => {
  // good-media-query's screen, with a made-up content of four stops, one of
  // them a button: V12's own lines are plain text, and the help-message
  // rule needs a stop with a role to tie a help message to.
  const own = screenStops('good-media-query');
  const expected = ['Accessible navigation: on', 'Bold text: off', 'Refresh button', 'Text scale: 100%'];
  const [fr, es, de, chosenLine] = expected;
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
      ['a line read with another value', 'wrong', screen('Accessible navigation: off', es, de, chosenLine), true],
      ['a stop read in other words', 'wrong', screen(fr, es, de, 'Text scale: 200%'), true],
      ['a line missing', 'wrong', screen(fr, de, chosenLine), true],
      ['the last stop missing', 'wrong', screen(fr, es, de), true],
      ['the lines in another order', 'wrong', screen(es, fr, de, chosenLine), true],
      ['a stop after the last expected one', 'wrong', [...whole, 'Extra'], true],
      ['another example\'s screen', 'wrong', [...screenStops('bad-read-once'), EXAMPLE_HEADING, ...expected], true],
      ['an empty stop put in, so that every later stop comes late', 'wrong', screen('', ...expected), true],
      ['the title read as an empty phrase, every later stop right', 'incomplete', ['', ...own.slice(1), EXAMPLE_HEADING, ...expected], true],
      ['a line read as an empty phrase, every other stop right', 'incomplete', screen(fr, '', de, chosenLine), true],
      ['an empty first stop and a wrong reading later', 'wrong', ['', ...own.slice(1), EXAMPLE_HEADING, 'Accessible navigation: off', es, de, chosenLine], true],
      ['an empty first stop and a walk that reached the end short', 'wrong', ['', ...own.slice(1), EXAMPLE_HEADING, fr], true],
      ['an empty phrase after the last expected stop', 'wrong', [...whole, ''], true],
      ['every stop an empty phrase', 'incomplete', Array(n).fill(''), true],
      ['a help message with no positions recorded', 'wrong', [...whole, HELP], true],
      ['no title', 'wrong', [own[1], EXAMPLE_HEADING, ...expected], true],
      ['no heading', 'wrong', [...own, ...expected], true],
      ['an empty walk cut short', 'incomplete', [], false],
      ['a walk cut short after the heading', 'incomplete', screen(), false],
      ['every stop read, but the end not reached', 'incomplete', whole, false],
    ], (stops, reachedEnd) => judgeExampleWalk(stops, reachedEnd, expected, own));
  });

  test('a help message is left out only when tied to the stop before it, by position and spoken role', () => {
    check([
      ['help after the button\'s stop, at its position', 'complete',
        screen(fr, es, de, HELP, chosenLine), at(screen(fr, es, de, HELP, chosenLine), [own.length + 4])],
      ['help at a new position after the whole screen (an extra element)', 'wrong', [...whole, HELP], at([...whole, HELP])],
      ['a text field\'s help at a new position after the whole screen', 'wrong', [...whole, TEXT_FIELD_HELP], at([...whole, TEXT_FIELD_HELP])],
      ['button help after a text with no role, at its position', 'wrong', [...whole, HELP], at([...whole, HELP], [n])],
      ['help naming another role than the stop before it, at its position', 'wrong',
        screen(fr, TEXT_FIELD_HELP, es, de, chosenLine), at(screen(fr, TEXT_FIELD_HELP, es, de, chosenLine), [own.length + 2])],
      ['help in place of an expected stop', 'wrong', screen(fr, HELP, de, chosenLine), at(screen(fr, HELP, de, chosenLine))],
      ['help after an empty stop, at its position', 'wrong', screen(fr, '', HELP, de, chosenLine),
        at(screen(fr, '', HELP, de, chosenLine), [own.length + 3])],
      ['help with positions of the wrong length', 'wrong', screen(fr, HELP, es, de, chosenLine), at(whole)],
      ['help and a wrong reading', 'wrong', screen('Accessible navigation: off', HELP, es, de, chosenLine),
        at(screen('Accessible navigation: off', HELP, es, de, chosenLine), [own.length + 2])],
      // helpRole gives "heading level 1", which is not spokenRole's
      // "heading": a made-up heading help is not left out (S08's rule errs
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
      ['heading level 1 Settings read once', 'heading'],
      ['heading level 2 Example', 'heading'],
      ['Refresh button', 'button'],
      ['Accessible navigation: on', null],
      ['Text scale: 100%', null],
      ['Good example for Detecting accessibility settings. Widgets layer.', null],
      ['Defect: A setting changed while this is open is not shown.', null],
    ];
    for (const [reading, role] of roles) expect(spokenRole(reading), reading).toBe(role);
    expect(helpRole(HELP)).toBe('button');
    expect(helpRole(TEXT_FIELD_HELP)).toBe('text field');
    expect(helpRole('Accessible navigation: on')).toBe(null);
  });

  test('every screen: a bad example\'s own stops end with its defect, no screen has a custom solution note, and no expected stop is empty or help', () => {
    for (const slug of Object.keys(EXAMPLE_SCREENS)) {
      if (slug.startsWith('bad-')) expect(screenStops(slug).at(-1), slug).toMatch(/^Defect: /);
      expect(screenStops(slug).some((s) => s.startsWith('Custom solution')), slug).toBe(false);
    }
    for (const [slug, stops] of Object.entries(EXPECTED_STOPS)) {
      for (const s of stops) expect(s !== '' && !VO_HELP_PREFIX.test(s), `${slug}: "${s}"`).toBe(true);
    }
  });

  test('walks are made again only while incomplete, at most three, and every try is logged', async () => {
    const judge = (stops, reachedEnd) => judgeExampleWalk(stops, reachedEnd, expected, own);
    const right = { stops: whole, reachedEnd: true };
    const short = { stops: screen(fr), reachedEnd: false };
    const wrong = { stops: screen('Accessible navigation: off', es, de, chosenLine), reachedEnd: true };
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

// The walk (collectWalk in web_tests/vo/v12_vo_walks.js), driven by made-up
// screens and captures: a screen is a list of elements, each a phrase at a
// position; `next` and `previous` move a cursor over it, and `capture`
// reads what a capture function makes of the element the cursor is on.
test.describe('the VoiceOver walk keeps every unchanged read and needs a witness for its end', () => {
  const slug = 'good-media-query';
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

  // S12's regression cases, carried over to S16's screens, and here to V12's.
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
    const elements = [...screen, { phrase: 'Extra line', position: at(80) }, extra];
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
    const lostAt = heading + 2; // Bold text: off
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

  // judgeWalk (web_tests/vo/v12_vo_walks.js): an unresolved read is a gap
  // in the walk, never a pass for what was captured around it.
  test('a wrong verdict wins over a gap, and a gap passes over at most the next expected stop', async () => {
    const wrongTitle = [{ phrase: 'heading level 1 Settings read once', position: at(0) }, ...screen.slice(1)];
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

  // The fourth review's reproduction: the first capture reads a wrong title
  // at the start's bounds (Back's, which had not changed yet). Compared with
  // the start capture, its words are new, so it is a stop, judged wrong.
  test('a wrong first title at the start bounds is a stop, judged wrong, not a gap', async () => {
    const atStart = (c, el, n) => (n === 1 ? { phrase: 'heading level 1 Settings read once', position: START.position } : el);
    const elements = [{ phrase: 'x', position: START.position }, ...screen.slice(1)];
    const walk = await drive(elements, atStart);
    expect(walk.unresolved).toEqual([]);
    expect(walk.stops[0]).toBe('heading level 1 Settings read once');
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
    const atStart = (c, el, n) => (n === 1 ? { phrase: 'heading level 1 Settings read once', position: START.position } : el);
    const walks = [await drive([{ phrase: 'x', position: START.position }, ...screen.slice(1)], atStart), await drive(screen)];
    let i = 0;
    let latest;
    const result = await runWalks(async () => { latest = walks[i++]; return latest; }, () => judge(latest));
    expect(result.verdict).toBe('wrong');
    expect(i).toBe(1);
  });

  test('in the retry loop a wrong walk with a gap ends the example, and a clean walk after it is never made', async () => {
    const wrongTitle = [{ phrase: 'heading level 1 Settings read once', position: at(0) }, ...screen.slice(1)];
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
// (judgeTranscript in web_tests/vo/v12_vo_walks.js), never skipped: every
// browser and example once, walks in order, the last complete, with its end
// witness row and its unresolved-reads row. Made-up transcripts test the
// judge first.
test.describe('the web VoiceOver transcript is judged again from what it recorded', () => {
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
  const transcript = (rowsFor) => ['# V12 Detecting accessibility settings: VoiceOver transcript (web, macOS)', '',
    'Result: PASS', ...BROWSERS.flatMap((b) => section(b, rowsFor(b)))].join('\n');
  const right = () => Object.keys(EXAMPLE_SCREENS).flatMap((slug) => rowsOf(slug));
  const short = (slug) => [transcriptRow(slug, 1, whole(slug).slice(0, 3), 'incomplete', 'cut short'), startRow(slug, 1, BACK), unresolvedRow(slug, 1, [])];

  test('made-up transcripts: a right one passes, and each wrong one names its problem', () => {
    const firstRow = transcriptRow('good-media-query', 1, whole('good-media-query'), 'complete', 'x');
    const cases = [
      ['a whole walk of every example in both browsers', transcript(right), true],
      // A first walk that ran out of moves (no end row) is wrong for good,
      // and a complete second walk cannot rescue it.
      ['a first walk exhausted at the move limit, then a complete second', transcript(() => [...short('good-media-query'),
        ...rowsOf('good-media-query', 2), ...Object.keys(EXAMPLE_SCREENS).slice(1).flatMap((s) => rowsOf(s))]), false],
      ['an empty transcript', '', false],
      ['every end row removed', transcript(() => right().filter((r) => !r.includes('-end`'))), false],
      ['every unresolved-reads row removed', transcript(() => right().filter((r) => !r.includes('-unresolved`'))), false],
      ['an end row whose positions are one word', transcript(() => right().map((r) => (r.startsWith('| `good-media-query-walk-1-end`')
        ? '| `good-media-query-walk-1-end` | back "x" at here / forward "y" at here |' : r))), false],
      ['an end witness that read back the last stop', transcript(() => right().map((r) => (r.startsWith('| `good-media-query-walk-1-end`')
        ? endRow('good-media-query', 1, { back: witness('good-media-query').forward, forward: witness('good-media-query').forward }) : r))), false],
      ['an end witness that read back an empty phrase', transcript(() => right().map((r) => (r.startsWith('| `good-media-query-walk-1-end`')
        ? endRow('good-media-query', 1, { back: { phrase: '', position: '1, 2, 3, 4' }, forward: witness('good-media-query').forward }) : r))), false],
      ['the last walk with an unresolved read', transcript(() => right().map((r) => (r.startsWith('| `good-media-query-walk-1-unresolved`')
        ? unresolvedRow('good-media-query', 1, [{ after: 3, phrase: '', position: '1, 2, 3, 4' }]) : r))), false],
      ['eight copies of one row', transcript(() => Array(4).fill(firstRow)), false],
      ['one walk row twice', transcript(() => [...right(), firstRow]), false],
      ['an example missing in one browser', transcript((b) => (b === 'webkit' ? right().slice(3) : right())), false],
      ['a browser section missing', ['Result: PASS', ...section('chromium', right())].join('\n'), false],
      ['an unknown browser section', [transcript(right), ...section('firefox', [])].join('\n'), false],
      ['an unknown example', transcript(() => [...right(), transcriptRow('good-other', 1, whole('good-media-query'), 'complete', 'x')]), false],
      ['a malformed row', transcript(() => [...right(), '| `good-media-query-walk-x` | something |']), false],
      ['a row outside any section', [firstRow, transcript(right)].join('\n'), false],
      ['walk 2 with no walk 1', transcript(() => right().map((r) => r.replace('good-media-query-walk-1', 'good-media-query-walk-2'))), false],
      ['the last walk recorded wrong', transcript(() => right().map((r) => (r.startsWith('| `good-media-query-walk-1`') ? r.replace('(complete:', '(wrong:') : r))), false],
      ['the first recording\'s form, only what follows the heading', transcript(() => Object.keys(EXAMPLE_SCREENS).flatMap((slug) => [
        transcriptRow(slug, 1, EXPECTED_STOPS[slug], 'complete', 'x'), endRow(slug, 1, witness(slug)), unresolvedRow(slug, 1, [])])), false],
      ['another example\'s screen stops', transcript(() => right().map((r) => (r.startsWith('| `good-media-query-walk-1`')
        ? transcriptRow('good-media-query', 1, [...screenStops('bad-read-once'), EXAMPLE_HEADING, ...EXPECTED_STOPS['good-media-query']], 'complete', 'x') : r))), false],
      // S12's cases, carried over.
      ['a walk whose title is an empty phrase', transcript(() => right().map((r) => (r.startsWith('| `good-media-query-walk-1`')
        ? transcriptRow('good-media-query', 1, ['', ...whole('good-media-query').slice(1)], 'complete', 'x') : r))), false],
      ['an end witness whose move back read the right words at the last position', transcript(() => right().map((r) => (r.startsWith('| `good-media-query-walk-1-end`')
        ? endRow('good-media-query', 1, { back: { phrase: witness('good-media-query').back.phrase, position: witness('good-media-query').forward.position }, forward: witness('good-media-query').forward }) : r))), false],
      ['an end witness whose move forward read another stop', transcript(() => right().map((r) => (r.startsWith('| `good-media-query-walk-1-end`')
        ? endRow('good-media-query', 1, { back: witness('good-media-query').back, forward: { phrase: 'Extra', position: witness('good-media-query').forward.position } }) : r))), false],
      ['an end witness row twice', transcript(() => [...right(), endRow('good-media-query', 1, witness('good-media-query'))]), false],
      ['an end witness row for a walk that is not there', transcript(() => [...right(), endRow('good-media-query', 2, witness('good-media-query'))]), false],
      ['an unresolved-reads row twice', transcript(() => [...right(), unresolvedRow('good-media-query', 1, [])]), false],
      ['an unresolved-reads row for a walk that is not there', transcript(() => [...right(), unresolvedRow('good-media-query', 2, [])]), false],
      ['a first walk with no unresolved-reads row, walked again', transcript(() => [
        transcriptRow('good-media-query', 1, whole('good-media-query').slice(0, 3), 'incomplete', 'cut short'),
        ...rowsOf('good-media-query', 2), ...Object.keys(EXAMPLE_SCREENS).slice(1).flatMap((x) => rowsOf(x))]), false],
      ['a first walk with an unresolved read, witnessed at its end, recorded incomplete though its stops judge complete, then complete', transcript(() => [
        transcriptRow('good-media-query', 1, whole('good-media-query'), 'incomplete', 'unresolved'),
        startRow('good-media-query', 1, BACK),
        endRow('good-media-query', 1, witness('good-media-query')),
        unresolvedRow('good-media-query', 1, [{ after: 3, phrase: '', position: '1, 2, 3, 4' }]),
        ...rowsOf('good-media-query', 2), ...Object.keys(EXAMPLE_SCREENS).slice(1).flatMap((x) => rowsOf(x))]), true],
      // The fourth review's cases: an unresolved read hides no words.
      ['a first walk whose unresolved read after the start read a wrong title, then a clean walk', transcript(() => [
        transcriptRow('good-media-query', 1, whole('good-media-query').slice(1), 'incomplete', 'unresolved'),
        startRow('good-media-query', 1, BACK),
        endRow('good-media-query', 1, witness('good-media-query')),
        unresolvedRow('good-media-query', 1, [{ after: 0, phrase: 'heading level 1 Settings read once', position: BACK.position }]),
        ...rowsOf('good-media-query', 2), ...Object.keys(EXAMPLE_SCREENS).slice(1).flatMap((x) => rowsOf(x))]), false],
      ['an unresolved read mid-walk whose words differ from the stop before it', transcript(() => [
        transcriptRow('good-media-query', 1, whole('good-media-query'), 'incomplete', 'unresolved'),
        startRow('good-media-query', 1, BACK),
        endRow('good-media-query', 1, witness('good-media-query')),
        unresolvedRow('good-media-query', 1, [{ after: 3, phrase: 'Extra', position: '1, 2, 3, 4' }]),
        ...rowsOf('good-media-query', 2), ...Object.keys(EXAMPLE_SCREENS).slice(1).flatMap((x) => rowsOf(x))]), false],
      ['an unresolved read after the start that repeats the start, then complete', transcript(() => [
        transcriptRow('good-media-query', 1, whole('good-media-query'), 'incomplete', 'unresolved'),
        startRow('good-media-query', 1, BACK),
        endRow('good-media-query', 1, witness('good-media-query')),
        unresolvedRow('good-media-query', 1, [{ after: 0, phrase: BACK.phrase, position: BACK.position }]),
        ...rowsOf('good-media-query', 2), ...Object.keys(EXAMPLE_SCREENS).slice(1).flatMap((x) => rowsOf(x))]), true],
      ['every start row removed', transcript(() => right().filter((r) => !r.includes('-start`'))), false],
      ['a start row twice', transcript(() => [...right(), startRow('good-media-query', 1, BACK)]), false],
      ['a start row whose position is one word', transcript(() => right().map((r) => (r.startsWith('| `good-media-query-walk-1-start`')
        ? '| `good-media-query-walk-1-start` | "Back button" at here |' : r))), false],
      ['a first walk with an unresolved read recorded complete, then complete', transcript(() => [
        transcriptRow('good-media-query', 1, whole('good-media-query'), 'complete', 'x'),
        unresolvedRow('good-media-query', 1, [{ after: 3, phrase: '', position: '1, 2, 3, 4' }]),
        ...rowsOf('good-media-query', 2), ...Object.keys(EXAMPLE_SCREENS).slice(1).flatMap((x) => rowsOf(x))]), false],
      // judgeWalk's regressions in a transcript: each first walk fails the
      // transcript despite the complete second.
      ...[
        ['a wrong title, then one stale read', ['heading level 1 Settings read once', ...whole('good-media-query').slice(1)], 2],
        ['a wrong stop after the gap', [...whole('good-media-query').slice(0, 3), 'Extra', ...whole('good-media-query').slice(4)], 3],
      ].map(([what, stops, after]) => [`${what}, witnessed, then a complete walk`, transcript(() => [
        transcriptRow('good-media-query', 1, stops, 'incomplete', 'unresolved'),
        endRow('good-media-query', 1, witness('good-media-query')),
        unresolvedRow('good-media-query', 1, [{ after, phrase: 'x', position: '1, 2, 3, 4' }]),
        ...rowsOf('good-media-query', 2), ...Object.keys(EXAMPLE_SCREENS).slice(1).flatMap((x) => rowsOf(x))]), false]),
      ['an unresolved-reads row whose position is one word', transcript(() => right().map((r) => (r.startsWith('| `good-media-query-walk-1-unresolved`')
        ? '| `good-media-query-walk-1-unresolved` | after stop 3: "x" at here |' : r))), false],
      ['a wrong first walk followed by a complete one', transcript(() => [
        transcriptRow('good-media-query', 1, ['x'], 'wrong', 'x'), unresolvedRow('good-media-query', 1, []),
        ...rowsOf('good-media-query', 2), ...Object.keys(EXAMPLE_SCREENS).slice(1).flatMap((x) => rowsOf(x))]), false],
    ];
    for (const [what, text, ok] of cases) {
      const problems = judgeTranscript(text);
      expect(problems.length === 0, `${what}: ${problems.join('; ')}`).toBe(ok);
    }
  });

  test('the committed recording (docs/evidence/V12/voiceover-web.md) is right, every browser and example once', () => {
    // Never skipped: a missing file fails here, as it does until the first
    // recording is made.
    const text = readFileSync(new URL('../docs/evidence/V12/voiceover-web.md', import.meta.url), 'utf8');
    expect(judgeTranscript(text)).toEqual([]);
  });
});
