// L3 for V13 Minimum touch target size on web: how big each control's
// element is, what a click near it does, and the keyboard.
// Spec: docs/specs/V13-touch-target-size.md. Runs against the release
// build in build/web, in Chromium on this machine's desktop operating
// system, so Flutter's platform is macOS (or Linux on CI) and the Material
// theme adds no padding to buttons (FL-412).
//
// On the web a click on a node's element is turned into that node's tap
// action (FL-411), so the element's box, which is Flutter's semantics node,
// is where clicks are taken (docs/evidence/probes/v13/README.md).
import { test, expect } from '@playwright/test';
import { byId, tabTo, technique } from './support/techniques.js';

const { open, count, expectCount } = technique('V13', { countLabel: 'Presses' });

const names = { previous: 'Previous', play: 'Play', next: 'Next' };
const link = 'good-inline-link';
const ids = (slug) => (slug === link ? [`v13-${link}-rules`] : Object.keys(names).map((c) => `v13-${slug}-${c}`));

// Each control's element in CSS pixels, with Flutter's platform a desktop
// one. bad-zero-padding-web is 48 by 48 on Android and iOS.
const SIZE = {
  'good-material': 40,
  'good-cupertino': 48,
  'good-custom': 48,
  'bad-shrinkwrap': 18,
  'bad-zero-padding-web': 18,
  'bad-cupertino-small': 18,
  'bad-custom-small': 18,
};
const good = ['good-material', 'good-cupertino', 'good-custom'];
const bad = ['bad-shrinkwrap', 'bad-zero-padding-web', 'bad-cupertino-small', 'bad-custom-small'];
const MINIMUM = 24;

/** The box of an element in CSS pixels: { x, y, r, b, w, h }. */
async function box(locator) {
  const b = await locator.boundingBox();
  expect(b, 'the element has a box').not.toBeNull();
  return { x: b.x, y: b.y, r: b.x + b.width, b: b.y + b.height, w: b.width, h: b.height };
}

/**
 * The targets that fail WCAG 2.5.8 among `targets` (id -> box): an
 * undersized one passes only if a circle 24 across, centred on it, meets no
 * other target and no other undersized target's circle. The same rule as
 * wcag258Failures in the widget tests.
 */
function wcag258Failures(targets) {
  const undersized = (t) => t.w < MINIMUM || t.h < MINIMUM;
  const centre = (t) => [(t.x + t.r) / 2, (t.y + t.b) / 2];
  const failures = [];
  for (const [id, t] of Object.entries(targets)) {
    if (!undersized(t)) continue;
    const [cx, cy] = centre(t);
    for (const [other, o] of Object.entries(targets)) {
      if (other === id) continue;
      const nx = Math.min(Math.max(cx, o.x), o.r);
      const ny = Math.min(Math.max(cy, o.y), o.b);
      const [ox, oy] = centre(o);
      if (Math.hypot(nx - cx, ny - cy) < MINIMUM / 2) failures.push(`${id}: its circle meets ${other}`);
      else if (undersized(o) && Math.hypot(ox - cx, oy - cy) < MINIMUM) failures.push(`${id}: its circle meets the circle of ${other}`);
    }
  }
  return failures;
}

/** The roles of the nodes named `name` in Chromium's accessibility tree. */
async function axNodes(page, name) {
  const cdp = await page.context().newCDPSession(page);
  const { nodes } = await cdp.send('Accessibility.getFullAXTree');
  await cdp.detach();
  return nodes.filter((n) => n.name?.value === name).map((n) => n.role?.value);
}

async function presses(page, slug) {
  const text = (await count(page, slug).textContent()) ?? '';
  const m = /^Presses: (\d+)$/.exec(text.trim());
  expect(m, `the count reads "${text}"`).not.toBeNull();
  return Number(m[1]);
}

/** Clicks at (x, y) and expects `n` more presses than before. */
async function clickExpecting(page, slug, x, y, n, why) {
  const before = await presses(page, slug);
  await page.mouse.click(x, y);
  if (n === 0) await page.waitForTimeout(700);
  await expect(count(page, slug), why).toHaveText(`Presses: ${before + n}`);
}

/** A click that must do nothing, then the positive control: a click at the centre of `id`. */
async function expectNothingAt(page, slug, id, x, y, why) {
  await clickExpecting(page, slug, x, y, 0, `${id}: ${why}`);
  const b = await box(byId(page, id));
  await clickExpecting(page, slug, (b.x + b.r) / 2, (b.y + b.b) / 2, 1, `${id}: the click at its centre after ${why}`);
}

test.describe('every control', () => {
  for (const slug of [...good, link, ...bad]) {
    test(`${slug}: role, name, and size`, async ({ page }) => {
      await open(page, slug);
      for (const id of ids(slug)) {
        const element = byId(page, id);
        if (slug === link) {
          // An <a> with no href, which Playwright's own role check does not
          // count as a link; Chromium's accessibility tree does.
          expect(await element.evaluate((e) => e.tagName)).toBe('A');
          expect(await axNodes(page, 'trail rules')).toContain('link');
        } else {
          await expect(element).toHaveRole('button');
          await expect(element).toHaveAccessibleName(names[id.split('-').pop()]);
          const b = await box(element);
          expect(b.w, `${id} width`).toBeCloseTo(SIZE[slug], 0);
          expect(b.h, `${id} height`).toBeCloseTo(SIZE[slug], 0);
        }
      }
    });
  }
});

test.describe('WCAG 2.5.8', () => {
  for (const slug of good) {
    test(`${slug}: no target under 24 by 24, so it passes`, async ({ page }) => {
      await open(page, slug);
      const targets = {};
      for (const id of ids(slug)) targets[id] = await box(byId(page, id));
      for (const t of Object.values(targets)) {
        expect(t.w).toBeGreaterThanOrEqual(MINIMUM);
        expect(t.h).toBeGreaterThanOrEqual(MINIMUM);
      }
      expect(wcag258Failures(targets)).toEqual([]);
    });
  }

  for (const slug of bad) {
    test(`${slug}: 18 by 18 targets 4 apart, and each fails, spacing included`, async ({ page }) => {
      await open(page, slug);
      const targets = {};
      for (const id of ids(slug)) targets[id] = await box(byId(page, id));
      const list = Object.values(targets);
      expect(list[1].x - list[0].r).toBeCloseTo(4, 0);
      expect(list[2].x - list[1].r).toBeCloseTo(4, 0);
      const failing = new Set(wcag258Failures(targets).map((f) => f.split(':')[0]));
      expect([...failing].sort()).toEqual(Object.keys(targets).sort());
    });
  }

  test(`${link}: under 24 high, in the middle of its sentence`, async ({ page }) => {
    await open(page, link);
    const b = await box(byId(page, `v13-${link}-rules`));
    expect(b.h).toBeLessThan(MINIMUM);
    // It is in the sentence: the sentence's element holds the text before
    // and after it, and spans it.
    const sentence = page.locator('flt-semantics[role="group"][aria-label]', { has: byId(page, `v13-${link}-rules`) });
    await expect(sentence).toHaveCount(1);
    expect((await sentence.getAttribute('aria-label')).replace(/\s+/g, ' ')).toBe('Read the before you set off.');
    const s = await box(sentence);
    expect(s.x).toBeLessThan(b.x);
    expect(s.r).toBeGreaterThan(b.r);
  });
});

test.describe('clicks', () => {
  for (const slug of [...good, ...bad]) {
    test(`${slug}: each control takes a click at its centre and 2 pixels inside its bottom edge, and not 2 outside it`, async ({ page }) => {
      await open(page, slug);
      for (const id of ids(slug)) {
        const b = await box(byId(page, id));
        const cx = (b.x + b.r) / 2;
        await clickExpecting(page, slug, cx, (b.y + b.b) / 2, 1, `${id} centre`);
        await clickExpecting(page, slug, cx, b.b - 2, 1, `${id} 2 inside its bottom edge`);
        await expectNothingAt(page, slug, id, cx, b.b + 2, '2 below its bottom edge');
      }
    });
  }

  for (const slug of good) {
    test(`${slug}: nothing 2 pixels right of the last control`, async ({ page }) => {
      await open(page, slug);
      const id = ids(slug).at(-1);
      const b = await box(byId(page, id));
      await expectNothingAt(page, slug, id, b.r + 2, (b.y + b.b) / 2, '2 right of its right edge');
    });
  }

  // FL-411: the label of a small element is its text, which runs out of
  // the element to the right and takes clicks there. Written to fail when
  // the label stops spilling out of the element.
  for (const slug of bad) {
    test(`${slug} (FL-411): a click 2 pixels right of the last button presses it, and one below it does not`, async ({ page }) => {
      await open(page, slug);
      const id = ids(slug).at(-1);
      const b = await box(byId(page, id));
      await clickExpecting(page, slug, b.r + 2, (b.y + b.b) / 2, 1, `${id}: 2 right of its right edge`);
      const under = await page.evaluate(([x, y]) => document.elementFromPoint(x, y)?.getAttribute('flt-semantics-identifier'), [b.r + 2, (b.y + b.b) / 2]);
      expect(under, 'the element under the pointer there').toBe(id);
      await expectNothingAt(page, slug, id, (b.x + b.r) / 2, b.b + 2, '2 below its bottom edge');
    });
  }

  // FL-411 again: the link's text runs out of the bottom of its element,
  // and a click there is the link's. Written to fail when it stops.
  test(`${link} (FL-411): a click on the link and 2 pixels below it press it, and 2 above it does not`, async ({ page }) => {
    await open(page, link);
    const id = `v13-${link}-rules`;
    const b = await box(byId(page, id));
    const cx = (b.x + b.r) / 2;
    await clickExpecting(page, link, cx, (b.y + b.b) / 2, 1, 'centre');
    await clickExpecting(page, link, cx, b.b + 2, 1, '2 below it');
    const under = await page.evaluate(([x, y]) => document.elementFromPoint(x, y)?.getAttribute('flt-semantics-identifier'), [cx, b.b + 2]);
    expect(under, 'the element under the pointer 2 below the link').toBe(id);
    await expectNothingAt(page, link, id, cx, b.y - 2, '2 above it');
  });
});

test.describe('keyboard', () => {
  for (const slug of [...good, link]) {
    test(`${slug}: Tab reaches each control, and Enter and Space press it`, async ({ page }) => {
      await open(page, slug);
      let n = 0;
      for (const id of ids(slug)) {
        expect(await tabTo(page, byId(page, id)), `Tab reaches ${id}`).toBe(true);
        await page.keyboard.press('Enter');
        await expectCount(page, slug, ++n);
        await page.keyboard.press('Space');
        await expectCount(page, slug, ++n);
      }
    });
  }
});
