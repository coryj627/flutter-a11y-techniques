// L3 for S08 List semantics on web: what Chromium's accessibility tree
// exposes for each list and its items, and what a click and the keys do on
// the lists of tiles. Spec: docs/specs/S08-list-semantics.md. Runs against
// the release build in build/web.
import { test, expect } from '@playwright/test';
import { byId, technique } from './support/techniques.js';
import { EXAMPLE_HEADING, EXAMPLE_SCREENS, judgeExampleWalk, runWalks, screenStops } from './vo/s08_vo_walks.js';

// The example screen's own "Example" heading; the technique's page has
// "Good examples" and "Bad examples", so the name must match exactly.
const exampleHeading = (page) => page.getByRole('heading', { name: 'Example', exact: true, level: 2 });
const { open } = technique('S08', { ready: exampleHeading, settle: 600 });

const GROCERIES = ['Milk', 'Eggs', 'Bread'];
const STEPS = ['1. Fork the repository', '2. Make the change', '3. Open a pull request'];

/**
 * The roles and names of the example's own elements, from Chromium's
 * accessibility tree as Playwright's ARIA snapshot gives it: every line
 * after the "Example" heading up to the end of the page, or up to the
 * "Chosen" line under a list of tiles. Indentation is kept, so the lines
 * show what holds what.
 */
async function exampleTree(page) {
  const snapshot = await page.locator('flt-semantics-host').ariaSnapshot();
  const lines = snapshot.split('\n');
  const start = lines.findIndex((l) => l.includes('heading "Example" [level=2]'));
  expect(start, 'the Example heading').toBeGreaterThanOrEqual(0);
  const end = lines.findIndex((l, i) => i > start && /Chosen: /.test(l));
  const own = lines.slice(start + 1, end < 0 ? undefined : end);
  const indent = Math.min(...own.map((l) => l.search(/\S/)));
  return own.map((l) => l.slice(indent).trimEnd());
}

/** Every element of the page with `role`, and the name of each. */
async function named(page, role) {
  return page.getByRole(role).evaluateAll((els) => els.map((e) => e.getAttribute('aria-label') ?? e.textContent.trim()));
}

/**
 * The text of every semantics element of the page that holds text and no
 * other element, after the "Example" heading: one entry per element.
 */
async function textElements(page) {
  return page.evaluate(() => {
    const host = document.querySelector('flt-semantics-host');
    const all = [...host.querySelectorAll('*')];
    // Flutter writes a heading as an <h2> element.
    const heading = all.findIndex((e) => e.tagName === 'H2' && e.textContent.trim() === 'Example');
    if (heading < 0) throw new Error('no Example heading');
    return all
      .slice(heading + 1)
      .filter((e) => e.tagName === 'FLT-SEMANTICS' && !e.querySelector('flt-semantics') && e.textContent.trim() !== '')
      .map((e) => e.textContent.trim());
  });
}

/** What the "Chosen" line under the list of tiles of `slug` says. */
const chosen = (page, slug) => byId(page, `s08-${slug}-chosen`);

test.describe('good examples', () => {
  test('good-bulleted: one list of three list items, each named by its line', async ({ page }) => {
    await open(page, 'good-bulleted');
    expect(await exampleTree(page)).toEqual([
      '- list:',
      ...GROCERIES.map((g) => `  - listitem "${g}"`),
    ]);
    await expect(page.getByRole('list')).toHaveCount(1);
    await expect(page.getByRole('list').getByRole('listitem')).toHaveCount(3);
    await expect(page.getByRole('listitem')).toHaveCount(3);
  });

  test('good-numbered: one list of three list items, each with its number', async ({ page }) => {
    await open(page, 'good-numbered');
    expect(await exampleTree(page)).toEqual(['- list:', ...STEPS.map((s) => `  - listitem "${s}"`)]);
    await expect(page.getByRole('list').getByRole('listitem')).toHaveCount(3);
    await expect(page.getByRole('listitem')).toHaveCount(3);
  });

  test('good-material: one list of three list items, each holding one button', async ({ page }) => {
    await open(page, 'good-material');
    expect(await exampleTree(page)).toEqual([
      '- list:',
      ...GROCERIES.flatMap((g) => ['  - listitem:', `    - button "${g}"`]),
    ]);
    const items = page.getByRole('list').getByRole('listitem');
    await expect(items).toHaveCount(3);
    for (const [i, g] of GROCERIES.entries()) {
      await expect(items.nth(i).getByRole('button')).toHaveCount(1);
      await expect(items.nth(i).getByRole('button')).toHaveAccessibleName(g);
    }
    // The three tiles and Back are the page's only buttons.
    expect(await named(page, 'button')).toEqual(['Back', ...GROCERIES]);
  });

  test('good-cupertino: one list named by its header, of three list items', async ({ page }) => {
    await open(page, 'good-cupertino');
    expect(await exampleTree(page)).toEqual([
      '- list "Groceries":',
      ...GROCERIES.map((g) => `  - listitem "${g}"`),
    ]);
    await expect(page.getByRole('list')).toHaveAccessibleName('Groceries');
    await expect(page.getByRole('list').getByRole('listitem')).toHaveCount(3);
    // The tiles do nothing: no button but Back.
    expect(await named(page, 'button')).toEqual(['Back']);
  });

  // FL-315: a list item whose text is merged into it is an element with the
  // text as its aria-label and nothing inside it, which VoiceOver read as
  // "Milk empty group (1 of 3) 1 of 3" in Chromium and WebKit. Written to
  // fail when the item holds its text. A list item that holds a control
  // (good-material) holds its element.
  for (const [slug, names] of [['good-bulleted', GROCERIES], ['good-numbered', STEPS], ['good-cupertino', GROCERIES]]) {
    test(`${slug}: each list item's text is its aria-label, with nothing inside it (FL-315)`, async ({ page }) => {
      await open(page, slug);
      const items = await page.locator('flt-semantics-host [role="listitem"]').evaluateAll((els) => els.map((e) => ({
        label: e.getAttribute('aria-label'),
        children: e.children.length,
        text: e.textContent,
      })));
      expect(items).toEqual(names.map((n) => ({ label: n, children: 0, text: '' })));
    });
  }

  test('good-material: each list item holds its tile\'s element and has no label of its own', async ({ page }) => {
    await open(page, 'good-material');
    const items = await page.locator('flt-semantics-host [role="listitem"]').evaluateAll((els) => els.map((e) => ({
      label: e.getAttribute('aria-label'),
      child: e.children.length === 1 ? e.children[0].getAttribute('role') : `${e.children.length} children`,
    })));
    expect(items).toEqual(GROCERIES.map(() => ({ label: null, child: 'button' })));
  });

  test('good-material: Tab goes Back, then each tile in turn', async ({ page }) => {
    await open(page, 'good-material');
    const stops = [];
    for (let i = 0; i < 4; i++) {
      await page.keyboard.press('Tab');
      await page.waitForTimeout(150);
      stops.push(await page.evaluate(() => `${document.activeElement.getAttribute('role')} ${document.activeElement.textContent.trim()}`));
    }
    expect(stops).toEqual(['button Back', ...GROCERIES.map((g) => `button ${g}`)]);
  });

  for (const slug of ['good-material', 'bad-tile-in-item']) {
    for (const [i, g] of GROCERIES.entries()) {
      test(`${slug}: a click on ${g} opens ${g}`, async ({ page }) => {
        await open(page, slug);
        await expect(chosen(page, slug)).toHaveText('Chosen: none');
        await byId(page, `s08-${slug}-${g.toLowerCase()}`).click();
        await expect(chosen(page, slug)).toHaveText(`Chosen: ${g}`);
      });

      for (const key of ['Enter', 'Space']) {
        test(`${slug}: Tab to ${g}, then ${key}, opens ${g}`, async ({ page }) => {
          await open(page, slug);
          await expect(chosen(page, slug)).toHaveText('Chosen: none');
          // Back, then the tiles in order.
          for (let t = 0; t < i + 2; t++) {
            await page.keyboard.press('Tab');
            await page.waitForTimeout(150);
          }
          const tile = byId(page, `s08-${slug}-${g.toLowerCase()}`);
          await expect.poll(() => tile.evaluate((e) => e === document.activeElement)).toBe(true);
          // Sent once: the key is what is tested.
          await page.keyboard.press(key);
          await expect(chosen(page, slug)).toHaveText(`Chosen: ${g}`);
        });
      }
    }
  }
});

test.describe('bad examples have their defect', () => {
  test('bad-one-text: no list and no list item; the items are one text', async ({ page }) => {
    await open(page, 'bad-one-text');
    await expect(page.getByRole('list')).toHaveCount(0);
    await expect(page.getByRole('listitem')).toHaveCount(0);
    expect(await exampleTree(page)).toEqual([`- text: ${GROCERIES.join(' ')}`]);
    // One element holds all three lines.
    expect(await textElements(page)).toEqual([GROCERIES.join('\n')]);
  });

  test('bad-no-list: no list and no list item; each line is a text of its own', async ({ page }) => {
    await open(page, 'bad-no-list');
    await expect(page.getByRole('list')).toHaveCount(0);
    await expect(page.getByRole('listitem')).toHaveCount(0);
    // The ARIA snapshot joins texts that follow each other into one line;
    // the page's own elements show that each line is an element.
    expect(await textElements(page)).toEqual(GROCERIES);
  });

  test('bad-tile-in-item: each tile is a list item named by its title, and not a button', async ({ page }) => {
    await open(page, 'bad-tile-in-item');
    expect(await exampleTree(page)).toEqual(['- list:', ...GROCERIES.map((g) => `  - listitem "${g}"`)]);
    for (const g of GROCERIES) {
      const tile = byId(page, `s08-bad-tile-in-item-${g.toLowerCase()}`);
      await expect(tile).toHaveRole('listitem');
      await expect(tile).toHaveAccessibleName(g);
      await expect(tile.getByRole('button')).toHaveCount(0);
    }
    // Back is the page's only button.
    expect(await named(page, 'button')).toEqual(['Back']);
  });

  test('bad-tile-in-item: Tab goes Back, then each tile, which is a list item', async ({ page }) => {
    await open(page, 'bad-tile-in-item');
    const stops = [];
    for (let i = 0; i < 4; i++) {
      await page.keyboard.press('Tab');
      await page.waitForTimeout(150);
      stops.push(await page.evaluate(() => `${document.activeElement.getAttribute('role')} ${document.activeElement.getAttribute('aria-label') ?? document.activeElement.textContent.trim()}`));
    }
    expect(stops).toEqual(['button Back', ...GROCERIES.map((g) => `listitem ${g}`)]);
  });
});

test.describe('the long list in a ListView', () => {
  /** The numbers of the orders in the page now, in its order. */
  const orders = (page) => page.evaluate(() => [...document.querySelectorAll('flt-semantics-host flt-semantics')]
    .filter((e) => !e.querySelector('flt-semantics'))
    .map((e) => /^Order (\d+)$/.exec(e.textContent.trim()))
    .filter(Boolean)
    .map((m) => Number(m[1])));

  test('bad-lazy-list: no list and no list item; only the orders near the view are in the page (FL-011)', async ({ page }) => {
    await open(page, 'bad-lazy-list');
    await expect(page.getByRole('list')).toHaveCount(0);
    await expect(page.getByRole('listitem')).toHaveCount(0);
    const atStart = await orders(page);
    expect(atStart[0]).toBe(1);
    expect(atStart.length).toBeLessThan(30);
    // Scrolled to its end with the mouse wheel, the first orders are gone.
    const first = await page.getByText('Order 2', { exact: true }).boundingBox();
    await page.mouse.move(first.x + 10, first.y + 5);
    for (let i = 0; i < 20; i++) {
      await page.mouse.wheel(0, 200);
      await page.waitForTimeout(100);
    }
    await expect.poll(async () => (await orders(page)).at(-1)).toBe(30);
    expect(await orders(page)).not.toContain(1);
    await expect(page.getByRole('list')).toHaveCount(0);
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

test.describe('the VoiceOver example walks are judged on every walk', () => {
  const own = screenStops('good-bulleted');
  // good-bulleted's list in web_tests/vo/s08_list_semantics_vo.spec.js, as
  // the first recording measured it in Chromium and WebKit
  // (docs/evidence/probes/s08/voiceover-web-round1-fail.md.txt).
  const item = (text, i) => `${text} empty group (${i + 1} of 3) ${i + 1} of 3`;
  const [milk, eggs, bread] = GROCERIES.map(item);
  const expected = ['list 3 items', milk, eggs, bread, 'end of list'];
  const screen = (...content) => [...own, EXAMPLE_HEADING, ...content];
  const cases = [
    ['the whole screen, every stop in its place', screen(...expected), true, 'complete'],
    ['the round 1 prediction, items read by their text alone', screen('list 3 items', ...GROCERIES, 'end of list'), true, 'wrong'],
    ['a stop read in other words', screen('list 3 items', milk, eggs, bread, 'Cheese'), true, 'wrong'],
    ['the list stop missing', screen(milk, eggs, bread, 'end of list'), true, 'wrong'],
    ['the end of the list missing', screen('list 3 items', milk, eggs, bread), true, 'wrong'],
    ['an item missing at the end', screen('list 3 items', milk, eggs), true, 'wrong'],
    ['the browser\'s crash dialog in place of the screen', ['Google Chrome for Testing quit unexpectedly.', 'Reopen default button'], true, 'wrong'],
    ['a stop after the last expected one', screen(...expected, 'Extra'), true, 'wrong'],
    ['an empty stop put in, so that every later stop comes late', screen('', ...expected), true, 'wrong'],
    // An empty phrase is a failed capture: walked again, never passed.
    ['the second and third recordings: the title read as an empty phrase, every later stop right',
      ['', ...own.slice(1), EXAMPLE_HEADING, ...expected], true, 'incomplete'],
    ['an item read as an empty phrase, every other stop right', screen('list 3 items', milk, '', bread, 'end of list'), true, 'incomplete'],
    ['an empty first stop and a wrong reading later', ['', ...own.slice(1), EXAMPLE_HEADING, 'list 3 items', 'Milk', eggs, bread, 'end of list'], true, 'wrong'],
    ['an empty first stop and a walk that reached the end short', ['', ...own.slice(1), EXAMPLE_HEADING, 'list 3 items'], true, 'wrong'],
    ['an empty phrase after the last expected stop', screen(...expected, ''), true, 'incomplete'],
    ['every stop an empty phrase', Array(8).fill(''), true, 'incomplete'],
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
  const short = { stops: screen('list 3 items'), reachedEnd: false };

  for (const [what, walk] of [
    ['a wrong reading', { stops: screen('Milk Eggs Bread'), reachedEnd: true }],
    ['a walk that reached the end without an item', { stops: screen('list 3 items', milk, bread, 'end of list'), reachedEnd: true }],
  ]) {
    test(`${what} followed by a right walk fails, and no second walk is made`, async () => {
      const { walkOnce, made } = sequence(walk, right);
      expect((await runWalks(walkOnce, judge)).verdict).toBe('wrong');
      expect(made()).toBe(1);
    });
  }

  const emptyTitle = { stops: ['', ...own.slice(1), EXAMPLE_HEADING, ...expected], reachedEnd: true };

  test('an empty first stop is walked again, and a right walk then passes on the second', async () => {
    const { walkOnce, made } = sequence(emptyTitle, right);
    expect(await runWalks(walkOnce, judge)).toMatchObject({ verdict: 'complete', walks: 2 });
    expect(made()).toBe(2);
  });

  test('an empty first stop, then a wrong reading on the re-walk, fails, and no third walk is made', async () => {
    const { walkOnce, made } = sequence(emptyTitle, { stops: screen('Milk Eggs Bread'), reachedEnd: true }, right);
    expect((await runWalks(walkOnce, judge)).verdict).toBe('wrong');
    expect(made()).toBe(2);
  });

  test('three empty captures fail, and no fourth walk is made', async () => {
    const { walkOnce, made } = sequence(emptyTitle, emptyTitle, emptyTitle, right);
    expect(await runWalks(walkOnce, judge)).toMatchObject({ verdict: 'incomplete', walks: 3 });
    expect(made()).toBe(3);
  });

  test('a wrong walk after a short one still fails, and no third walk is made', async () => {
    const { walkOnce, made } = sequence(short, { stops: screen('Milk Eggs Bread'), reachedEnd: true }, right);
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
