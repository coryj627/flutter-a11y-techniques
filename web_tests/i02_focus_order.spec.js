// L3 for I02 Keyboard focus order on web: the order Tab and Shift+Tab
// move in, read stop by stop from document.activeElement, what happens past
// the last stop, and what the arrow keys do.
// Spec: docs/specs/I02-focus-order.md. Runs against the release build in
// build/web.
import { test, expect } from '@playwright/test';
import { byId, technique } from './support/techniques.js';

const { open, expectCount } = technique('I02', { countLabel: 'Saves' });

const good = ['good-material', 'good-cupertino', 'good-ordered'];
const all = [...good, 'bad-columns-mixed', 'bad-order-missing'];
const boxes = ['map', 'water', 'aid', 'weather', 'closures'];
const names = { map: 'Map', water: 'Water', aid: 'First aid', weather: 'Weather', closures: 'Closures' };

const columnOrder = ['map', 'water', 'aid', 'weather', 'closures', 'save'];
// Tab from the screen as it opens; Back comes first. The same orders as in
// the widget tests.
const tabOrder = {
  'good-material': ['back', ...columnOrder],
  'good-cupertino': ['back', ...columnOrder],
  'good-ordered': ['back', ...columnOrder],
  'bad-columns-mixed': ['back', 'map', 'weather', 'water', 'closures', 'aid', 'save'],
  'bad-order-missing': ['back', 'map', 'water', 'weather', 'closures', 'save', 'aid'],
};

const control = (page, slug, c) => byId(page, `i02-${slug}-${c}`);

/**
 * Names the element that has DOM focus: 'back', a control of the example,
 * 'outside' when focus has left the page's content (the body, or nothing),
 * or a description of anything else.
 */
const stop = (page, slug) => page.evaluate((prefix) => {
  const e = document.activeElement;
  if (!e || e === document.body || e.tagName === 'FLUTTER-VIEW') return 'outside';
  const id = e.getAttribute('flt-semantics-identifier');
  if (id && id.startsWith(prefix)) return id.slice(prefix.length);
  if (e.getAttribute('role') === 'button' && e.textContent.trim() === 'Back') return 'back';
  return `other: ${e.tagName} ${id ?? ''} ${e.getAttribute('role') ?? ''} ${e.textContent.slice(0, 30)}`;
}, `i02-${slug}-`);

/** Presses `key` `n` times and names the stop after each. */
async function walk(page, slug, n, key = 'Tab') {
  const stops = [];
  for (let i = 0; i < n; i++) {
    await page.keyboard.press(key);
    // Flutter moves DOM focus on the next frame.
    await page.waitForTimeout(150);
    stops.push(await stop(page, slug));
  }
  return stops;
}

/** Presses Tab until `c` has focus, at most 10 times. */
async function tabTo(page, slug, c) {
  for (let i = 0; i < 10; i++) {
    if ((await stop(page, slug)) === c) return true;
    await page.keyboard.press('Tab');
    await page.waitForTimeout(150);
  }
  return (await stop(page, slug)) === c;
}

const checked = (page, slug, c) => control(page, slug, c).getAttribute('aria-checked');

test.describe('every example', () => {
  for (const slug of all) {
    test(`${slug}: five named checkboxes and a Save plan button, each in the Tab order`, async ({ page }) => {
      await open(page, slug);
      for (const box of boxes) {
        const element = control(page, slug, box);
        await expect(element, box).toHaveRole('checkbox');
        await expect(element, box).toHaveAccessibleName(names[box]);
        await expect(element, box).toHaveAttribute('aria-checked', 'false');
        await expect(element, box).toHaveAttribute('tabindex', '0');
      }
      const save = control(page, slug, 'save');
      await expect(save).toHaveRole('button');
      await expect(save).toHaveAccessibleName('Save plan');
      await expect(save).toHaveAttribute('tabindex', '0');
    });

    // The order a screen reader on the web follows is the order of the
    // elements in the document. It is the column order in every example;
    // the keyboard's order is the subject of the tests below.
    test(`${slug}: the document has the controls one column, then the other`, async ({ page }) => {
      await open(page, slug);
      const order = await page.evaluate((prefix) => [...document.querySelectorAll('[flt-semantics-identifier]')]
        .map((e) => e.getAttribute('flt-semantics-identifier'))
        .filter((id) => id.startsWith(prefix) && !id.endsWith('-count'))
        .map((id) => id.slice(prefix.length)), `i02-${slug}-`);
      expect(order).toEqual(columnOrder);
    });
  }
});

test.describe('Tab order', () => {
  for (const slug of all) {
    const order = tabOrder[slug];

    test(`${slug}: Tab goes ${order.join(', ')}`, async ({ page }) => {
      await open(page, slug);
      expect(await walk(page, slug, order.length)).toEqual(order);
    });

    test(`${slug}: Shift+Tab goes the same way backwards`, async ({ page }) => {
      await open(page, slug);
      expect(await tabTo(page, slug, order.at(-1)), `Tab reaches ${order.at(-1)}`).toBe(true);
      const back = [...order].reverse().slice(1);
      expect(await walk(page, slug, back.length, 'Shift+Tab')).toEqual(back);
    });

    test(`${slug}: Space at each stop changes the box that has focus, and no other`, async ({ page }) => {
      await open(page, slug);
      await walk(page, slug, 1); // Back
      const done = [];
      for (const expected of order.slice(1)) {
        expect(await walk(page, slug, 1)).toEqual([expected]);
        await page.keyboard.press('Space');
        if (expected === 'save') {
          await expectCount(page, slug, 1);
          continue;
        }
        done.push(expected);
        for (const box of boxes) {
          await expect(control(page, slug, box), `after Space on ${expected}, ${box}`)
            .toHaveAttribute('aria-checked', done.includes(box) ? 'true' : 'false');
        }
      }
    });
  }

  // Past the last control in Flutter's order, Flutter lets the browser
  // have the Tab (TraversalEdgeBehavior.leaveFlutterView), and focus
  // leaves the page's content.
  for (const slug of [...good, 'bad-columns-mixed']) {
    test(`${slug}: Tab past Save plan leaves the content`, async ({ page }) => {
      await open(page, slug);
      expect(await tabTo(page, slug, 'save')).toBe(true);
      expect(await walk(page, slug, 1)).toEqual(['outside']);
    });
  }

  // FL-421. Flutter's last stop is First aid, which is not the last control
  // in the document. The browser takes the Tab from there to the next
  // element in the document, Weather; Flutter takes over again, and Tab
  // goes round Weather, Closures, Save plan, and First aid for ever.
  // Shift+Tab still gets out. Written to fail when Tab leaves the content.
  test('bad-order-missing: Tab past First aid goes round to Weather and never leaves the content', async ({ page }) => {
    await open(page, 'bad-order-missing');
    expect(await tabTo(page, 'bad-order-missing', 'aid')).toBe(true);
    expect(await walk(page, 'bad-order-missing', 8)).toEqual([
      'weather', 'closures', 'save', 'aid', 'weather', 'closures', 'save', 'aid',
    ]);
    // Shift+Tab gets out of the loop, back to Back and out of the content.
    expect(await walk(page, 'bad-order-missing', 6, 'Shift+Tab')).toEqual([
      'save', 'closures', 'weather', 'water', 'map', 'back',
    ]);
  });
});

test.describe('arrow keys', () => {
  // On the web WidgetsApp maps the arrow keys to scrolling, not to moving
  // focus (read in the source: WidgetsApp's web shortcuts). Focus stays
  // where it is.
  for (const slug of all) {
    test(`${slug}: the arrow keys do not move focus`, async ({ page }) => {
      for (const key of ['ArrowDown', 'ArrowRight', 'ArrowUp', 'ArrowLeft']) {
        await open(page, slug);
        expect(await tabTo(page, slug, 'map')).toBe(true);
        await page.keyboard.press(key);
        await page.waitForTimeout(300);
        expect(await stop(page, slug), key).toBe('map');
      }
    });
  }
});
