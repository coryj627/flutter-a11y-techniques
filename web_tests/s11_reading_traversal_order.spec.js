// L3 for S11 Reading and traversal order on web: the order of the example's
// elements in the page, which is the order a screen reader reads them in,
// at the default window and at a phone's width; Chromium's own
// accessibility tree in the same order; the order Tab and Shift+Tab move
// in, and what happens past the last control; and what a click and the keys
// do. Spec: docs/specs/S11-reading-traversal-order.md. Runs against the
// release build in build/web.
import { test, expect } from '@playwright/test';
import { byId, technique } from './support/techniques.js';
import { EXAMPLE_HEADING, EXAMPLE_SCREENS, judgeExampleWalk, runWalks, screenStops } from './vo/s11_vo_walks.js';

const exampleHeading = (page) => page.getByRole('heading', { name: 'Example', exact: true, level: 2 });
const { open } = technique('S11', { ready: exampleHeading, settle: 600 });

const good = ['good-columns', 'good-sort-keys'];
const bad = ['bad-columns-mixed', 'bad-key-missing'];
const all = [...good, ...bad];

// The order meant, as each element is in the page: the route column, then
// the bring column, then the two counts.
const MEANT = [
  'h3 Route', 'Park at the gate.', 'Climb the ridge.', 'Walk back.', 'button Save route',
  'h3 Bring', 'Water', 'A map', 'button Save list', 'Route saves: 0', 'List saves: 0',
];

// The orders measured, by window size. bad-columns-mixed's rests on the
// parts' positions (FL-420): the browser's fonts lay the steps out on one
// line each at both sizes, so its rows are level.
const ORDERS = {
  'good-columns': { wide: MEANT, phone: MEANT },
  'good-sort-keys': { wide: MEANT, phone: MEANT },
  'bad-columns-mixed': {
    wide: [
      'h3 Route', 'h3 Bring', 'Park at the gate.', 'Water', 'Climb the ridge.', 'A map', 'Walk back.',
      'button Save route', 'button Save list', 'Route saves: 0', 'List saves: 0',
    ],
    phone: [
      'h3 Route', 'h3 Bring', 'Park at the gate.', 'Water', 'Climb the ridge.', 'A map', 'Walk back.',
      'button Save route', 'button Save list', 'Route saves: 0', 'List saves: 0',
    ],
  },
  'bad-key-missing': {
    wide: [
      'h3 Route', 'h3 Bring', 'Park at the gate.', 'Climb the ridge.', 'Walk back.', 'button Save route',
      'Water', 'A map', 'button Save list', 'Route saves: 0', 'List saves: 0',
    ],
    phone: [
      'h3 Route', 'h3 Bring', 'Park at the gate.', 'Climb the ridge.', 'Walk back.', 'button Save route',
      'Water', 'A map', 'button Save list', 'Route saves: 0', 'List saves: 0',
    ],
  },
};

const SIZES = { wide: { width: 1280, height: 720 }, phone: { width: 320, height: 640 } };

/**
 * The example's elements in the page's order, after the "Example" heading:
 * each element with a role, a name, or text of its own, as "h3 Route",
 * "button Save route", or its text. This is the document's order, which
 * Flutter writes in its own reading order and which a screen reader on the
 * web follows.
 */
const pageOrder = (page) => page.evaluate(() => {
  const host = document.querySelector('flt-semantics-host');
  const out = [];
  let after = false;
  for (const e of host.querySelectorAll('*')) {
    const own = [...e.childNodes].filter((n) => n.nodeType === 3).map((n) => n.textContent.trim()).join('');
    const name = e.getAttribute('aria-label') || own;
    if (!name) continue;
    if (/^H[1-6]$/.test(e.tagName) && name === 'Example') {
      after = true;
      continue;
    }
    if (!after) continue;
    const role = e.getAttribute('role');
    if (/^H[1-6]$/.test(e.tagName)) out.push(`${e.tagName.toLowerCase()} ${name}`);
    else if (role === 'button') out.push(`button ${name}`);
    else if (role) out.push(`${role} ${name}`);
    else out.push(name);
  }
  return out;
});

/** The same from Chromium's accessibility tree, depth first, in its own order. */
async function axOrder(page) {
  const cdp = await page.context().newCDPSession(page);
  const { nodes } = await cdp.send('Accessibility.getFullAXTree');
  const byNode = new Map(nodes.map((n) => [n.nodeId, n]));
  const out = [];
  const visit = (n) => {
    if (!n) return;
    const name = n.name?.value ?? '';
    const role = n.role?.value;
    if (!n.ignored && name && ['heading', 'button', 'StaticText'].includes(role)) {
      const level = (n.properties ?? []).find((p) => p.name === 'level')?.value?.value;
      if (role === 'heading') out.push(`h${level} ${name}`);
      else if (role === 'button') out.push(`button ${name}`);
      else if (!['heading', 'button'].includes(byNode.get(n.parentId)?.role?.value)) out.push(name);
    }
    for (const c of n.childIds ?? []) visit(byNode.get(c));
  };
  visit(nodes.find((n) => !n.parentId));
  await cdp.detach();
  const start = out.indexOf('h2 Example');
  expect(start, 'the Example heading').toBeGreaterThanOrEqual(0);
  return out.slice(start + 1);
}

/**
 * Names the element that has DOM focus: 'back', 'save-route', 'save-list',
 * 'outside' when focus has left the page's content, or a description.
 */
const stop = (page, slug) => page.evaluate((prefix) => {
  const e = document.activeElement;
  if (!e || e === document.body || e.tagName === 'FLUTTER-VIEW') return 'outside';
  const id = e.getAttribute('flt-semantics-identifier');
  if (id && id.startsWith(prefix)) return id.slice(prefix.length);
  if (e.getAttribute('role') === 'button' && e.textContent.trim() === 'Back') return 'back';
  return `other: ${e.tagName} ${id ?? ''} ${e.getAttribute('role') ?? ''} ${e.textContent.slice(0, 30)}`;
}, `s11-${slug}-`);

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

async function counts(page, slug) {
  const read = async (name) => Number((await byId(page, `s11-${slug}-${name}`).textContent()).split(': ').pop());
  return { route: await read('route-saves'), list: await read('list-saves') };
}

const expectCounts = (page, slug, expected) =>
  expect.poll(() => counts(page, slug), { timeout: 3000 }).toEqual(expected);

test.describe('the reading order', () => {
  for (const slug of all) {
    for (const [size, viewport] of Object.entries(SIZES)) {
      test(`${slug}: the page's order at ${viewport.width} by ${viewport.height}`, async ({ page }) => {
        await page.setViewportSize(viewport);
        await open(page, slug);
        const order = await pageOrder(page);
        expect(order).toEqual(ORDERS[slug][size]);
        // Chromium's tree has the same order.
        expect(await axOrder(page)).toEqual(order);
        // Nothing in the page reorders it for assistive technology.
        await expect(page.locator('[aria-owns], [aria-flowto]')).toHaveCount(0);
      });
    }
  }

  test('the good examples are read in the order meant, and the bad ones are not', () => {
    for (const slug of good) {
      for (const size of Object.keys(SIZES)) expect(ORDERS[slug][size], `${slug} ${size}`).toEqual(MEANT);
    }
    for (const slug of bad) {
      for (const size of Object.keys(SIZES)) {
        const order = ORDERS[slug][size];
        expect(order, `${slug} ${size}`).not.toEqual(MEANT);
        // Both titles first, one after the other.
        expect(order.slice(0, 2), `${slug} ${size}`).toEqual(['h3 Route', 'h3 Bring']);
        expect([...order].sort(), `${slug} ${size}: every part is read`).toEqual([...MEANT].sort());
      }
    }
  });

  for (const slug of all) {
    test(`${slug}: two level 3 headings, two buttons and Back, and every part an element of its own`, async ({ page }) => {
      await open(page, slug);
      await expect(page.getByRole('heading', { level: 3 })).toHaveCount(2);
      await expect(page.getByRole('heading', { name: 'Route', exact: true, level: 3 })).toHaveCount(1);
      await expect(page.getByRole('heading', { name: 'Bring', exact: true, level: 3 })).toHaveCount(1);
      await expect(page.getByRole('button')).toHaveCount(3);
      await expect(byId(page, `s11-${slug}-save-route`)).toHaveRole('button');
      await expect(byId(page, `s11-${slug}-save-route`)).toHaveAccessibleName('Save route');
      await expect(byId(page, `s11-${slug}-save-list`)).toHaveRole('button');
      await expect(byId(page, `s11-${slug}-save-list`)).toHaveAccessibleName('Save list');
    });
  }
});

test.describe('the keyboard', () => {
  for (const slug of all) {
    test(`${slug}: Tab goes Back, Save route, Save list, then out of the content; Shift+Tab the same backwards`, async ({ page }) => {
      await open(page, slug);
      expect(await walk(page, slug, 4)).toEqual(['back', 'save-route', 'save-list', 'outside']);
      await open(page, slug);
      expect(await walk(page, slug, 3)).toEqual(['back', 'save-route', 'save-list']);
      expect(await walk(page, slug, 3, 'Shift+Tab')).toEqual(['save-route', 'back', 'outside']);
    });
  }

  test('the good examples: the buttons are reached in their reading order', () => {
    for (const slug of good) {
      for (const size of Object.keys(SIZES)) {
        const read = ORDERS[slug][size].filter((p) => p.startsWith('button ')).map((p) => p.slice(7));
        expect(read, `${slug} ${size}`).toEqual(['Save route', 'Save list']);
      }
    }
  });

  for (const slug of all) {
    for (const [name, count] of [['save-route', 'route'], ['save-list', 'list']]) {
      const one = { route: count === 'route' ? 1 : 0, list: count === 'list' ? 1 : 0 };
      test(`${slug}: a click on ${name} adds one to its own count, and to no other`, async ({ page }) => {
        await open(page, slug);
        await expectCounts(page, slug, { route: 0, list: 0 });
        await byId(page, `s11-${slug}-${name}`).click();
        await expectCounts(page, slug, one);
      });

      test(`${slug}: a click from assistive technology on ${name} adds one to its own count`, async ({ page }) => {
        await open(page, slug);
        await byId(page, `s11-${slug}-${name}`).dispatchEvent('click');
        await expectCounts(page, slug, one);
      });

      for (const key of ['Enter', 'Space']) {
        test(`${slug}: Tab reaches ${name} and ${key} adds one to its own count, and to no other`, async ({ page }) => {
          await open(page, slug);
          const stops = await walk(page, slug, name === 'save-route' ? 2 : 3);
          expect(stops.at(-1)).toBe(name);
          await page.keyboard.press(key);
          await expectCounts(page, slug, one);
        });
      }
    }
  }
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

test.describe('the VoiceOver example walks are judged on every walk', () => {
  const own = screenStops('good-columns');
  // good-columns' list in web_tests/vo/s11_reading_traversal_order_vo.spec.js.
  const expected = [
    'heading level 3 Route', 'Park at the gate.', 'Climb the ridge.', 'Walk back.', 'Save route button',
    'heading level 3 Bring', 'Water', 'A map', 'Save list button', 'Route saves: 0', 'List saves: 0',
  ];
  // VoiceOver's help message, as S08's fourth recording read one.
  const HELP = 'You are currently on a heading level 3, inside of web content. To exit this web area, press '
    + 'Control-Option-Shift-Up Arrow.';
  const screen = (...content) => [...own, EXAMPLE_HEADING, ...content];
  const mixed = [
    'heading level 3 Route', 'heading level 3 Bring', 'Park at the gate.', 'Water', 'Climb the ridge.', 'A map',
    'Walk back.', 'Save route button', 'Save list button', 'Route saves: 0', 'List saves: 0',
  ];
  const cases = [
    ['the whole screen, every stop in its place', screen(...expected), true, 'complete'],
    ['the columns read row by row', screen(...mixed), true, 'wrong'],
    ['two stops the other way round', screen(expected[0], expected[2], expected[1], ...expected.slice(3)), true, 'wrong'],
    ['a stop read in other words', screen(...expected.slice(0, -1), 'List saves: 1'), true, 'wrong'],
    ['a step missing', screen(...expected.filter((s) => s !== 'Climb the ridge.')), true, 'wrong'],
    ['the last count missing', screen(...expected.slice(0, -1)), true, 'wrong'],
    ['a stop after the last expected one', screen(...expected, 'Extra'), true, 'wrong'],
    ['an empty stop put in, so that every later stop comes late', screen('', ...expected), true, 'wrong'],
    // An empty phrase is a failed capture: walked again, never passed.
    ['the title read as an empty phrase, every later stop right', ['', ...own.slice(1), EXAMPLE_HEADING, ...expected], true, 'incomplete'],
    ['a step read as an empty phrase, every other stop right', screen(expected[0], '', ...expected.slice(2)), true, 'incomplete'],
    ['an empty first stop and a wrong reading later', ['', ...own.slice(1), EXAMPLE_HEADING, ...mixed], true, 'wrong'],
    ['an empty first stop and a walk that reached the end short', ['', ...own.slice(1), EXAMPLE_HEADING, expected[0]], true, 'wrong'],
    ['an empty phrase after the last expected stop', screen(...expected, ''), true, 'incomplete'],
    ['every stop an empty phrase', Array(14).fill(''), true, 'incomplete'],
    // VoiceOver's help message is not a stop of the page.
    ['a help message after the last stop', screen(...expected, HELP), true, 'complete'],
    ['a help message in the middle', screen(...expected.slice(0, 3), HELP, ...expected.slice(3)), true, 'complete'],
    ['a help message in place of an expected stop', screen(...expected.slice(0, 3), HELP, ...expected.slice(4)), true, 'wrong'],
    ['a help message in place of the last stop', screen(...expected.slice(0, -1), HELP), true, 'wrong'],
    ['only help messages', [HELP, HELP], true, 'wrong'],
    ['no title', [own[1], EXAMPLE_HEADING, ...expected], true, 'wrong'],
    ['no heading', [...own, ...expected], true, 'wrong'],
    ['an empty walk cut short', [], false, 'incomplete'],
    ['a walk cut short after the heading', screen(), false, 'incomplete'],
    ['every stop read, but the end not reached', screen(...expected), false, 'incomplete'],
  ];
  for (const [what, stops, reachedEnd, verdict] of cases) {
    test(`${what}: ${verdict}`, () => {
      expect(judgeExampleWalk(stops, reachedEnd, expected, own).verdict).toBe(verdict);
    });
  }

  test('a bad example\'s own stops include its defect', () => {
    for (const slug of Object.keys(EXAMPLE_SCREENS).filter((s) => s.startsWith('bad-'))) {
      expect(screenStops(slug).at(-1), slug).toMatch(/^Defect: /);
    }
  });

  test('no screen has a custom solution note', () => {
    for (const slug of Object.keys(EXAMPLE_SCREENS)) {
      expect(screenStops(slug).some((s) => s.startsWith('Custom solution')), slug).toBe(false);
    }
  });

  const judge = (stops, reachedEnd) => judgeExampleWalk(stops, reachedEnd, expected, own);
  const sequence = (...list) => {
    let i = 0;
    return { walkOnce: async () => list[i++], made: () => i };
  };
  const right = { stops: screen(...expected), reachedEnd: true };
  const short = { stops: screen(expected[0]), reachedEnd: false };
  const wrong = { stops: screen(...mixed), reachedEnd: true };
  const emptyTitle = { stops: ['', ...own.slice(1), EXAMPLE_HEADING, ...expected], reachedEnd: true };

  for (const [what, walk] of [
    ['a wrong reading', wrong],
    ['a walk that reached the end without a step', { stops: screen(...expected.filter((s) => s !== 'Walk back.')), reachedEnd: true }],
  ]) {
    test(`${what} followed by a right walk fails, and no second walk is made`, async () => {
      const { walkOnce, made } = sequence(walk, right);
      expect((await runWalks(walkOnce, judge)).verdict).toBe('wrong');
      expect(made()).toBe(1);
    });
  }

  test('an empty first stop is walked again, and a right walk then passes on the second', async () => {
    const { walkOnce, made } = sequence(emptyTitle, right);
    expect(await runWalks(walkOnce, judge)).toMatchObject({ verdict: 'complete', walks: 2 });
    expect(made()).toBe(2);
  });

  test('an empty first stop, then a wrong reading on the re-walk, fails, and no third walk is made', async () => {
    const { walkOnce, made } = sequence(emptyTitle, wrong, right);
    expect((await runWalks(walkOnce, judge)).verdict).toBe('wrong');
    expect(made()).toBe(2);
  });

  test('three empty captures fail, and no fourth walk is made', async () => {
    const { walkOnce, made } = sequence(emptyTitle, emptyTitle, emptyTitle, right);
    expect(await runWalks(walkOnce, judge)).toMatchObject({ verdict: 'incomplete', walks: 3 });
    expect(made()).toBe(3);
  });

  test('a wrong walk after a short one still fails, and no third walk is made', async () => {
    const { walkOnce, made } = sequence(short, wrong, right);
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
