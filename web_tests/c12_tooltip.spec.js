// L3 for C12 Tooltip on web: what the browser's accessibility tree exposes
// for each example's control, before and while its tooltip is shown, and
// what a hover, a move onto the tooltip, Tab, Escape, and the keys do.
// Spec: docs/specs/C12-tooltip.md. Runs against the release build in
// build/web.
//
// A tooltip is drawn on Flutter's canvas. Whether it is drawn is read from
// screenshots: the pixels of a band under the control that differ from a
// screenshot taken before anything was done (`drawn`, after the C12 probe,
// docs/evidence/probes/c12/README.md). A box of text there differs in more
// than 1000 pixels; the band is otherwise unchanged (0 in the probe). While
// a tooltip is shown its text is also an element of the page (FL-249).
import { test, expect } from '@playwright/test';
import zlib from 'node:zlib';
import { byId, tabTo, technique } from './support/techniques.js';
import { EXAMPLE_HEADING, EXAMPLE_SCREENS, judgeExampleWalk, runWalks, screenStops } from './vo/c12_vo_walks.js';

const { open, expectCount } = technique('C12', { countLabel: 'Activations', settle: 600 });

const GOOD = ['good-material', 'good-cupertino', 'good-description'];
const CONTROL = {
  'good-material': 'c12-good-material-delete',
  'good-cupertino': 'c12-good-cupertino-delete',
  'good-description': 'c12-good-description-download',
  'bad-not-hoverable': 'c12-bad-not-hoverable-delete',
  'bad-hover-only': 'c12-bad-hover-only-info',
  'bad-repeats-name': 'c12-bad-repeats-name-download',
  'bad-outside-button': 'c12-bad-outside-button-tooltip',
};
const TIP = {
  'good-material': 'Delete draft',
  'good-cupertino': 'Delete draft',
  'good-description': 'Saves a PDF copy',
  'bad-not-hoverable': 'Delete draft',
  'bad-hover-only': 'At least 8 characters',
  'bad-repeats-name': 'Download',
  'bad-outside-button': 'Delete draft',
};
// Each good control's name, as measured (the probe's t05 for a tooltip
// merged into a button with text: on the web the tooltip comes first, FL-251).
const NAME = {
  'good-material': 'Delete draft',
  'good-cupertino': 'Delete draft',
  'good-description': 'Saves a PDF copy Download',
};

// --- Pixels (V14's decoder, copied: the pixel helpers are per layer) -------

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

/** The pixels of the band under the control box `c`: 40 high, 300 wide. */
async function band(page, c) {
  const png = decodePng(await page.screenshot());
  const pixels = [];
  const y0 = Math.round(c.y + c.height), y1 = Math.min(png.height - 1, y0 + 40);
  const x0 = Math.max(0, Math.round(c.x - 10)), x1 = Math.min(png.width - 1, x0 + 300);
  for (let y = y0; y < y1; y++) for (let x = x0; x < x1; x++) pixels.push(png.at(x, y));
  return pixels;
}

function differing(a, b) {
  let n = 0;
  for (let i = 0; i < a.length; i++) {
    const p = a[i], q = b[i];
    const d = Math.max(Math.abs((p >> 16) - (q >> 16)), Math.abs(((p >> 8) & 255) - ((q >> 8) & 255)), Math.abs((p & 255) - (q & 255)));
    if (d > 40) n++;
  }
  return n;
}

/**
 * Watches one example's tooltip: `box` is the control's, `base` the band
 * before anything was done. `drawn()` is whether more than 1000 pixels of
 * the band now differ. `waitFor(true|false)` waits up to `ms` for it.
 */
async function watcher(page, locator) {
  const box = await locator.boundingBox();
  const base = await band(page, box);
  const count = async () => differing(await band(page, box), base);
  return {
    box,
    centre: { x: box.x + box.width / 2, y: box.y + box.height / 2 },
    // A point on the tooltip, under the control: Material puts its box 24
    // under the centre of a 48 high target, the RawTooltips at the
    // control's bottom edge.
    onTip: { x: box.x + box.width / 2, y: box.y + box.height + 12 },
    drawn: async () => (await count()) > 1000,
    async waitFor(expected, ms = 2000) {
      const end = Date.now() + ms;
      let n = await count();
      while ((n > 1000) !== expected && Date.now() < end) {
        await page.waitForTimeout(100);
        n = await count();
      }
      return n;
    },
  };
}

/**
 * The names Chromium itself gives the page's buttons, read from its
 * accessibility tree over the DevTools protocol. Playwright's own name
 * computation does not follow `aria-owns`, which is how the page puts a
 * shown tooltip's text inside its control (the probe, t01 and t06).
 */
async function buttonNames(page) {
  const cdp = await page.context().newCDPSession(page);
  const { nodes } = await cdp.send('Accessibility.getFullAXTree');
  await cdp.detach();
  return nodes.filter((n) => !n.ignored && n.role?.value === 'button').map((n) => n.name?.value ?? '');
}

const isActive = (locator) => locator.evaluate((e) => e === document.activeElement || e.contains(document.activeElement));

/** Elements of the page, other than the control, whose own text is `text`. */
const textElements = (page, text, control) => page.evaluate(([t, id]) =>
  [...document.querySelectorAll('flt-semantics-host *')].filter((e) =>
    !e.closest(`[flt-semantics-identifier="${id}"]`) &&
    [...e.childNodes].some((n) => n.nodeType === 3 && n.textContent.trim() === t)).length, [text, control]);

// --- Good examples ---------------------------------------------------------

test.describe('good examples', () => {
  for (const slug of GOOD) {
    const id = CONTROL[slug];
    const name = NAME[slug];

    test(`${slug}: one button with its name, and none but Back`, async ({ page }) => {
      await open(page, slug);
      const control = byId(page, id);
      await expect(control).toHaveRole('button');
      await expect(control).toHaveAccessibleName(name);
      await expect(control).toHaveAccessibleDescription('');
      await expect(page.getByRole('button')).toHaveCount(2);
      await expect(page.getByRole('button', { name: 'Back' })).toHaveCount(1);
      expect((await buttonNames(page)).sort()).toEqual(['Back', name].sort());
    });

    test(`${slug}: a hover shows the tooltip, which stays eight seconds and goes when the pointer leaves`, async ({ page }) => {
      await open(page, slug);
      const control = byId(page, id);
      const tip = await watcher(page, control);
      expect(await tip.drawn()).toBe(false);
      expect(await textElements(page, TIP[slug], id)).toBe(0);
      await page.mouse.move(tip.centre.x, tip.centre.y);
      expect(await tip.waitFor(true)).toBeGreaterThan(1000);
      // FL-249: while shown, the tooltip's text is an element of its own in
      // the page, outside the control; the control's name stays. Written to
      // fail when that changes.
      await page.waitForTimeout(800);
      expect(await textElements(page, TIP[slug], id)).toBe(1);
      expect((await buttonNames(page)).sort()).toEqual(['Back', name].sort());
      await page.waitForTimeout(8000);
      expect(await tip.drawn()).toBe(true);
      await page.mouse.move(5, 5);
      expect(await tip.waitFor(false)).toBeLessThanOrEqual(1000);
      await page.waitForTimeout(500);
      expect(await textElements(page, TIP[slug], id)).toBe(0);
    });

    test(`${slug}: the pointer can move onto the tooltip, and it stays`, async ({ page }) => {
      await open(page, slug);
      const tip = await watcher(page, byId(page, id));
      await page.mouse.move(tip.centre.x, tip.centre.y);
      expect(await tip.waitFor(true)).toBeGreaterThan(1000);
      await page.mouse.move(tip.onTip.x, tip.onTip.y, { steps: 10 });
      await page.waitForTimeout(600);
      expect(await tip.drawn()).toBe(true);
      await page.waitForTimeout(3000);
      expect(await tip.drawn()).toBe(true);
    });

    // FL-248: written to fail when a tooltip shows on keyboard focus.
    test(`${slug}: Tab to the control does not show the tooltip; a hover in the same load does`, async ({ page }) => {
      await open(page, slug);
      const control = byId(page, id);
      const tip = await watcher(page, control);
      expect(await tabTo(page, control)).toBe(true);
      await page.waitForTimeout(2000);
      expect(await isActive(control)).toBe(true);
      expect(await tip.drawn()).toBe(false);
      await page.mouse.move(tip.centre.x, tip.centre.y);
      expect(await tip.waitFor(true)).toBeGreaterThan(1000);
    });

    test(`${slug}: with focus on the control, Escape hides the hovered tooltip and leaves focus there`, async ({ page }) => {
      await open(page, slug);
      const control = byId(page, id);
      const tip = await watcher(page, control);
      expect(await tabTo(page, control)).toBe(true);
      await page.mouse.move(tip.centre.x, tip.centre.y);
      expect(await tip.waitFor(true)).toBeGreaterThan(1000);
      await page.keyboard.press('Escape');
      expect(await tip.waitFor(false)).toBeLessThanOrEqual(1000);
      expect(await isActive(control)).toBe(true);
      await page.waitForTimeout(1500);
      expect(await tip.drawn()).toBe(false);
    });

    // FL-482: written to fail when Escape starts to hide a tooltip with no
    // element of the page focused.
    test(`${slug}: with no element of the page focused, Escape does not hide the tooltip`, async ({ page }) => {
      await open(page, slug);
      const tip = await watcher(page, byId(page, id));
      await page.mouse.move(tip.centre.x, tip.centre.y);
      expect(await tip.waitFor(true)).toBeGreaterThan(1000);
      await page.evaluate(() => document.activeElement?.blur());
      expect(await page.evaluate(() => document.activeElement === document.body)).toBe(true);
      await page.keyboard.press('Escape');
      await page.waitForTimeout(1500);
      expect(await tip.drawn()).toBe(true);
      // The positive control in the same load: a click on an empty part of
      // the page gives Flutter focus, and Escape then hides it.
      await page.mouse.move(400, 700);
      expect(await tip.waitFor(false)).toBeLessThanOrEqual(1000);
      await page.mouse.click(400, 700);
      await page.mouse.move(tip.centre.x, tip.centre.y);
      expect(await tip.waitFor(true)).toBeGreaterThan(1000);
      await page.keyboard.press('Escape');
      expect(await tip.waitFor(false)).toBeLessThanOrEqual(1000);
    });

    test(`${slug}: a click, Enter, and Space each activate the control once`, async ({ page }) => {
      await open(page, slug);
      const control = byId(page, id);
      await control.click();
      await expectCount(page, slug, 1);
      expect(await tabTo(page, control)).toBe(true);
      await page.keyboard.press('Enter');
      await expectCount(page, slug, 2);
      await page.keyboard.press('Space');
      await expectCount(page, slug, 3);
    });
  }
});

// --- Bad examples ----------------------------------------------------------

test.describe('bad examples have their defect', () => {
  test('bad-not-hoverable: the tooltip goes when the pointer moves onto it', async ({ page }) => {
    const slug = 'bad-not-hoverable';
    await open(page, slug);
    const tip = await watcher(page, byId(page, CONTROL[slug]));
    await page.mouse.move(tip.centre.x, tip.centre.y);
    // The positive control: the hover shows it.
    expect(await tip.waitFor(true)).toBeGreaterThan(1000);
    await page.mouse.move(tip.onTip.x, tip.onTip.y, { steps: 10 });
    expect(await tip.waitFor(false)).toBeLessThanOrEqual(1000);
    await page.waitForTimeout(600);
    expect(await tip.drawn()).toBe(false);
    // Back on the button, it shows again.
    await page.mouse.move(tip.centre.x, tip.centre.y, { steps: 10 });
    expect(await tip.waitFor(true)).toBeGreaterThan(1000);
  });

  test('bad-hover-only: no Tab stop, Enter, or Space shows the rule; a hover does', async ({ page }) => {
    const slug = 'bad-hover-only';
    await open(page, slug);
    const info = byId(page, CONTROL[slug]);
    // Its tooltip is its text: Chromium gives it no role.
    await expect(info).toHaveText('At least 8 characters');
    await expect(info).not.toHaveAttribute('tabindex');
    await expect(info).not.toHaveRole('button');
    const tip = await watcher(page, info);
    const signUp = byId(page, 'c12-bad-hover-only-sign-up');
    const stops = [];
    for (let i = 0; i < 3; i++) {
      await page.keyboard.press('Tab');
      await page.waitForTimeout(300);
      stops.push(await page.evaluate(() => (document.activeElement?.closest('flt-semantics-host') ? (document.activeElement.getAttribute('aria-label') || document.activeElement.textContent).trim() : '(page)')));
      expect(await isActive(info)).toBe(false);
      expect(await tip.drawn()).toBe(false);
    }
    // Back, Sign up, then out of Flutter's tree (FL-421).
    expect(stops.slice(0, 2)).toEqual(['Back', 'Sign up']);
    expect(await tabTo(page, signUp)).toBe(true);
    await page.keyboard.press('Enter');
    await expectCount(page, slug, 1);
    expect(await tip.drawn()).toBe(false);
    await page.keyboard.press('Space');
    await expectCount(page, slug, 2);
    expect(await tip.drawn()).toBe(false);
    // The positive control: a hover shows the rule.
    await page.mouse.move(tip.box.x + tip.box.width / 2, tip.box.y + tip.box.height / 2);
    expect(await tip.waitFor(true)).toBeGreaterThan(1000);
  });

  test('bad-repeats-name: the button is named "Download Download", and the shown tooltip is a third "Download"', async ({ page }) => {
    const slug = 'bad-repeats-name';
    await open(page, slug);
    const control = byId(page, CONTROL[slug]);
    await expect(control).toHaveRole('button');
    await expect(control).toHaveAccessibleName('Download Download');
    expect((await buttonNames(page)).sort()).toEqual(['Back', 'Download Download']);
    const tip = await watcher(page, control);
    await page.mouse.move(tip.centre.x, tip.centre.y);
    expect(await tip.waitFor(true)).toBeGreaterThan(1000);
    // While it is shown, the tooltip's text is an element of its own in
    // the page, outside the button; the button's name stays. (In the probe,
    // t06, where nothing came between the tooltip and its MergeSemantics,
    // the button owned that element and Chromium added it to the name.)
    await page.waitForTimeout(800);
    expect((await buttonNames(page)).sort()).toEqual(['Back', 'Download Download']);
    expect(await textElements(page, 'Download', CONTROL[slug])).toBe(1);
    await page.mouse.move(5, 5);
    expect(await tip.waitFor(false)).toBeLessThanOrEqual(1000);
    await page.waitForTimeout(500);
    expect(await textElements(page, 'Download', CONTROL[slug])).toBe(0);
  });

  test('bad-outside-button: the tooltip is on an element of its own round a button with no name', async ({ page }) => {
    const slug = 'bad-outside-button';
    await open(page, slug);
    const outer = byId(page, CONTROL[slug]);
    await expect(outer).toHaveAccessibleName('Delete draft');
    await expect(outer).not.toHaveRole('button');
    const button = outer.getByRole('button');
    await expect(button).toHaveCount(1);
    await expect(button).toHaveAccessibleName('');
    await expect(page.getByRole('button')).toHaveCount(2);
    await expect(page.getByRole('button', { name: 'Delete draft' })).toHaveCount(0);
  });
});

// The VoiceOver spec takes these texts as the only stops that may come
// before an example's "Example" heading (EXAMPLE_SCREENS). Each screen must
// show them, so that a change to a title or a defect is caught here.
test.describe('the stops the VoiceOver spec expects above each example', () => {
  for (const [slug, [title, ...lines]] of Object.entries(EXAMPLE_SCREENS)) {
    test(`${slug} shows its title and its lines`, async ({ page }) => {
      await open(page, slug);
      await expect(page.getByRole('heading', { level: 1, name: title, exact: true })).toHaveCount(1);
      for (const line of lines) {
        await expect(page.locator('flt-semantics-host').getByText(line, { exact: true })).toHaveCount(1);
      }
    });
  }
});

// How the web VoiceOver spec judges one walk of an example screen
// (judgeExampleWalk), and repeats one that fell short (runWalks). The walks
// here are made up; VoiceOver is not used.
test.describe('the VoiceOver example walks are judged on every walk', () => {
  const expected = ['Delete draft button', 'Drafts are kept for 30 days.', 'Activations: 0'];
  const own = screenStops('good-material');
  const screen = (...content) => [...own, EXAMPLE_HEADING, ...content];
  const cases = [
    ['a correct walk', screen(...expected), true, 'complete'],
    ['the tooltip read again after the button', screen('Delete draft button', 'Delete draft', '', 'Drafts are kept for 30 days.', 'Activations: 0'), true, 'wrong'],
    ['the name read twice', screen('Delete draft Delete draft button', 'Drafts are kept for 30 days.', 'Activations: 0'), true, 'wrong'],
    ['a button with no name', screen('button', 'Drafts are kept for 30 days.', 'Activations: 0'), true, 'wrong'],
    ['an empty reading', screen('', ...expected), true, 'wrong'],
    ['a stop read twice', screen('Delete draft button', 'Delete draft button', 'Drafts are kept for 30 days.', 'Activations: 0'), true, 'wrong'],
    ['a stop after the count', screen(...expected, 'end of main'), true, 'wrong'],
    ['a wrong reading in a walk cut short', screen('button'), false, 'wrong'],
    ['a walk that reached the end without the button', screen('Drafts are kept for 30 days.', 'Activations: 0'), true, 'wrong'],
    ['a walk that reached the end without the count', screen('Delete draft button', 'Drafts are kept for 30 days.'), true, 'wrong'],
    ['a walk with no title', [own[1], EXAMPLE_HEADING, ...expected], true, 'wrong'],
    ['a walk with no description', [own[0], EXAMPLE_HEADING, ...expected], true, 'wrong'],
    ['a walk with no heading', [...own, ...expected], true, 'wrong'],
    ['a walk of the example alone', [...expected], true, 'wrong'],
    ['a walk that reached the end having read nothing', [], true, 'wrong'],
    ['the screen\'s own stops out of their order', [own[1], own[0], EXAMPLE_HEADING, ...expected], true, 'wrong'],
    ['a stop that is not the screen\'s before the heading', ['Back button', ...own, EXAMPLE_HEADING, ...expected], true, 'wrong'],
    ['an empty first stop for the title', ['', ...own.slice(1), EXAMPLE_HEADING, ...expected], true, 'wrong'],
    ['an empty walk cut short', [], false, 'incomplete'],
    ['a walk cut short after the heading', [...own, EXAMPLE_HEADING], false, 'incomplete'],
    ['a walk cut short after the button', screen('Delete draft button'), false, 'incomplete'],
    ['every stop read, but the end not reached', screen(...expected), false, 'incomplete'],
  ];
  for (const [what, stops, reachedEnd, verdict] of cases) {
    test(`${what}: ${verdict}`, () => {
      expect(judgeExampleWalk(stops, reachedEnd, expected, own).verdict).toBe(verdict);
    });
  }

  test('a bad example\'s own stops include its defect', () => {
    expect(screenStops('bad-repeats-name').at(-1)).toMatch(/^Defect: /);
  });

  const judge = (stops, reachedEnd) => judgeExampleWalk(stops, reachedEnd, expected, own);
  const sequence = (...list) => {
    let i = 0;
    return { walkOnce: async () => list[i++], made: () => i };
  };
  const right = { stops: screen(...expected), reachedEnd: true };
  const short = { stops: screen('Delete draft button'), reachedEnd: false };

  for (const [what, walk] of [
    ['a wrong reading', { stops: screen('button'), reachedEnd: true }],
    ['a walk that reached the end without the count', { stops: screen('Delete draft button', 'Drafts are kept for 30 days.'), reachedEnd: true }],
    ['a walk with no title', { stops: [own[1], EXAMPLE_HEADING, ...expected], reachedEnd: true }],
  ]) {
    test(`${what} followed by a right walk fails, and no second walk is made`, async () => {
      const { walkOnce, made } = sequence(walk, right);
      expect((await runWalks(walkOnce, judge)).verdict).toBe('wrong');
      expect(made()).toBe(1);
    });
  }

  test('a wrong walk after a short one still fails, and no third walk is made', async () => {
    const { walkOnce, made } = sequence(short, { stops: screen('button'), reachedEnd: true }, right);
    expect((await runWalks(walkOnce, judge)).verdict).toBe('wrong');
    expect(made()).toBe(2);
  });

  test('a walk cut short followed by a right one passes on the second', async () => {
    const { walkOnce, made } = sequence(short, right);
    expect(await runWalks(walkOnce, judge)).toMatchObject({ verdict: 'complete', walks: 2 });
    expect(made()).toBe(2);
  });

  test('three walks cut short fail', async () => {
    const { walkOnce } = sequence(short, short, short, right);
    expect(await runWalks(walkOnce, judge)).toMatchObject({ verdict: 'incomplete', walks: 3 });
  });

  test('every try of an example walk is logged', async () => {
    const { walkOnce } = sequence(short, short, right);
    const logged = [];
    await runWalks(walkOnce, judge, { log: (n, stops, judged) => logged.push([n, judged.verdict]) });
    expect(logged).toEqual([[1, 'incomplete'], [2, 'incomplete'], [3, 'complete']]);
  });
});
