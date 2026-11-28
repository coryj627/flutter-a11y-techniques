// L3 for S08 List semantics on web: what Chromium's accessibility tree
// exposes for each list and its items, and what a click and the keys do on
// the lists of tiles. Spec: docs/specs/S08-list-semantics.md. Runs against
// the release build in build/web.
import { test, expect } from '@playwright/test';
import { byId, technique } from './support/techniques.js';
import { readFileSync } from 'node:fs';
import { VO_HELP, phraseForMove } from './vo/vo_logic.js';
import {
  BROWSERS, EXAMPLE_HEADING, EXAMPLE_SCREENS, EXPECTED_STOPS, TRANSCRIPT_ROWS, collectWalk, endRow, expectedStops,
  helpRole, judgeCollectedWalk, judgeExampleWalk, judgeTranscript, judgeWalk, ordersRead, positionsRow, runWalks,
  screenStops, spokenRole, startRow, stopsOf, stopsText, transcriptRow, unresolvedRow, witnessBackHolds,
} from './vo/s08_vo_walks.js';

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

// The earlier web VoiceOver transcripts, judged again with today's judge
// of a walk's stops (judgeExampleWalk), each row against its browser's list
// (expectedStops): each row's stops (a complete walk shows only what
// follows the "Example" heading, so the screen's own stops are put back),
// with no positions, as none is in them. They were made before the walk
// took S16's rules and fail judgeTranscript (below); this shows what their
// stops alone judge. The sixth and fifth recordings passed and still judge
// complete (Chromium's bad-lazy-list, read to "Order 13", is N = 13 of its
// range); the fourth failed on a help message after the last stop and
// still judges wrong.
const transcriptRows = (file) => {
  let browser = null;
  return readFileSync(new URL(`../${file}`, import.meta.url), 'utf8')
    .split('\n')
    .map((line) => {
      browser = /^## (\S+)$/.exec(line)?.[1] ?? browser;
      const m = /^\| `([a-z-]+)-walk-\d+` \| (.*) \((complete|wrong|incomplete): .*\) \|$/.exec(line);
      if (!m) return null;
      const [, slug, shown, was] = m;
      const read = shown.split(' / ');
      return { browser, slug, was, stops: was === 'complete' ? [...screenStops(slug), EXAMPLE_HEADING, ...read] : read };
    })
    .filter(Boolean);
};
const verdictOf = ({ browser, slug, stops }) => judgeExampleWalk(stops, true, expectedStops(slug, browser, stops), screenStops(slug)).verdict;

test.describe('the earlier web VoiceOver transcripts\' stops judge as recorded', () => {
  test('the sixth and fifth recordings: every walk complete; the fourth: good-numbered in WebKit wrong, the rest complete', () => {
    for (const file of ['docs/evidence/probes/s08/voiceover-web-before-judge-update.md.txt', 'docs/evidence/probes/s08/voiceover-web-round5-pass.md.txt',
      'docs/evidence/probes/s08/voiceover-web-round4-fail.md.txt']) {
      const rows = transcriptRows(file);
      expect(rows, file).toHaveLength(16);
      const wrong = rows.filter((r) => verdictOf(r) !== 'complete').map((r) => `${r.browser} ${r.slug} ${verdictOf(r)}`);
      const expectedWrong = file.includes('round4') ? ['webkit good-numbered wrong'] : [];
      expect(wrong, file).toEqual(expectedWrong);
      const lazy = rows.find((r) => r.browser === 'chromium' && r.slug === 'bad-lazy-list');
      expect(lazy.stops.at(-1), file).toBe('Order 13');
    }
    const numbered = transcriptRows('docs/evidence/probes/s08/voiceover-web-round4-fail.md.txt')
      .find((r) => r.browser === 'webkit' && r.slug === 'good-numbered');
    expect(/^You are currently on /.test(numbered.stops.at(-1))).toBe(true);
  });
});

// How the web VoiceOver spec judges one walk's stops (judgeWalk, S16's, on
// S08's judgeExampleWalk). The walks here are made up; VoiceOver is not
// used. Each test names every case it holds.
test.describe('the VoiceOver example walks are judged on every walk', () => {
  const own = screenStops('good-bulleted');
  // good-bulleted's list, as the first recording measured it in Chromium
  // and WebKit (docs/evidence/probes/s08/voiceover-web-round1-fail.md.txt).
  const item = (text, i) => `${text} empty group (${i + 1} of 3) ${i + 1} of 3`;
  const [milk, eggs, bread] = GROCERIES.map(item);
  const expected = ['list 3 items', milk, eggs, bread, 'end of list'];
  // As the fourth recording read it (WebKit, good-numbered).
  const HELP = 'You are currently on a list, inside of web content. To move between items in this list, press '
    + 'Control-Option-Right Arrow or Control-Option-Left Arrow. To exit this web area, press Control-Option-Shift-Up Arrow.';
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
    ['an empty phrase after the last expected stop', screen(...expected, ''), true, 'wrong'],
    ['every stop an empty phrase', Array(8).fill(''), true, 'incomplete'],
    // A help message with no positions recorded is a stop like any other.
    ['the fourth recording as it was logged, with no positions: the help message after the last stop', screen(...expected, HELP), true, 'wrong'],
    ['no title', [own[1], EXAMPLE_HEADING, ...expected], true, 'wrong'],
    ['no heading', [...own, ...expected], true, 'wrong'],
    // A walk that did not reach its end ran out of moves: wrong for good.
    ['an empty walk that ran out of moves', [], false, 'wrong'],
    ['a walk that ran out of moves after the heading', screen(), false, 'wrong'],
    ['every stop read, but the end not reached', screen(...expected), false, 'wrong'],
  ];
  test(`the judge: whole screens, wrong readings, short walks, and empty captures (${cases.length} cases)`, () => {
    for (const [what, stops, reachedEnd, verdict] of cases) {
      expect(judgeWalk(stops, reachedEnd, expected, own).verdict, what).toBe(verdict);
    }
  });

  // A help message is left out only when the walk's positions tie it to the
  // stop before it: same position, a reading before it, and its role in
  // that reading (helpAfterStop in s08_vo_walks.js). Tested only on these
  // made-up walks: no S08 recording has had a help message with positions.
  const TEXT_FIELD_HELP = 'You are currently on a text field, inside of web content.';
  const IN_HELP = 'You are currently in a empty group.';
  const BUTTON_HELP = 'You are currently on a button, inside of web content. To click this button, press Control-Option-Space.';
  // One position per stop, each new but where `same` lists the stops (by
  // index) that are at the position of the stop before them.
  const at = (stops, same = []) => {
    const out = [];
    stops.forEach((_, i) => out.push(same.includes(i) ? out[i - 1] : `p${i}`));
    return out;
  };
  const whole = screen(...expected);
  const n = whole.length;
  const helpCases = [
    ['help after a judged stop, at its position: left out', [...whole, HELP], at([...whole, HELP], [n]), 'complete'],
    ['help after a judged stop in the middle, at its position, naming its role: left out',
      screen('list 3 items', HELP, milk, eggs, bread, 'end of list'),
      at(screen('list 3 items', HELP, milk, eggs, bread, 'end of list'), [own.length + 2]), 'complete'],
    ['help only, at a new position after the whole screen (an extra element): fails', [...whole, HELP], at([...whole, HELP]), 'wrong'],
    ['Codex\'s case: the whole screen, then a text field\'s help at a new position: fails', [...whole, TEXT_FIELD_HELP], at([...whole, TEXT_FIELD_HELP]), 'wrong'],
    ['help naming a role the stop before it does not have, at its position: fails', [...whole, TEXT_FIELD_HELP], at([...whole, TEXT_FIELD_HELP], [n]), 'wrong'],
    ['help in place of an expected stop: fails', screen('list 3 items', milk, HELP, bread, 'end of list'),
      at(screen('list 3 items', milk, HELP, bread, 'end of list')), 'wrong'],
    ['help after an empty stop, at its position: fails', [...screen('list 3 items', milk, eggs, bread, ''), HELP],
      at([...screen('list 3 items', milk, eggs, bread, ''), HELP], [n]), 'wrong'],
    ['help with positions of the wrong length: fails', [...whole, HELP], at(whole), 'wrong'],
    ['help and a wrong reading: fails', [...screen('list 3 items', 'Milk', eggs, bread, 'end of list'), HELP],
      at([...screen('list 3 items', 'Milk', eggs, bread, 'end of list'), HELP], [n]), 'wrong'],
    ['the fifth recording, which passed: no help message', whole, at(whole), 'complete'],
    // The role is the spoken role, never a word of the name.
    ['list help after the "Bulleted list" heading, at its position: fails',
      [own[0], HELP, ...whole.slice(1)], at([own[0], HELP, ...whole.slice(1)], [1]), 'wrong'],
    // VoiceOver's other wording, as round 9 read it (VO_HELP; helpRole
    // takes "empty group" as a group).
    ['"in a empty group" help after an item, at its position: left out',
      screen('list 3 items', milk, IN_HELP, eggs, bread, 'end of list'),
      at(screen('list 3 items', milk, IN_HELP, eggs, bread, 'end of list'), [own.length + 3]), 'complete'],
    ['"in a empty group" help after "list 3 items", at its position: fails',
      screen('list 3 items', IN_HELP, milk, eggs, bread, 'end of list'),
      at(screen('list 3 items', IN_HELP, milk, eggs, bread, 'end of list'), [own.length + 2]), 'wrong'],
    ['"in a empty group" help at a new position: fails',
      screen('list 3 items', milk, IN_HELP, eggs, bread, 'end of list'),
      at(screen('list 3 items', milk, IN_HELP, eggs, bread, 'end of list')), 'wrong'],
    ['button help after a text with no role, at its position: fails',
      [...whole, BUTTON_HELP], at([...whole, BUTTON_HELP], [n]), 'wrong'],
  ];
  test(`a help message is left out only when tied to the stop before it, by position and spoken role (${helpCases.length} cases)`, () => {
    for (const [what, stops, positions, verdict] of helpCases) {
      expect(judgeWalk(stops, true, expected, own, positions).verdict, what).toBe(verdict);
    }
  });

  test('a reading\'s spoken role comes from its role part only, and a help message names its role', () => {
    const roles = [
      ['heading level 1 Bulleted list', 'heading'],
      ['list 3 items', 'list'],
      ['list Groceries 3 items', 'list'],
      ['end of list', 'list'],
      ['Milk button 1 of 3', 'button'],
      ['Milk empty group (1 of 3) 1 of 3', 'group'],
      ['Bad example for List semantics. Widgets layer.', null],
      ['Milk', null],
    ];
    for (const [reading, role] of roles) expect(spokenRole(reading), reading).toBe(role);
    expect(helpRole(HELP)).toBe('list');
    expect(helpRole(TEXT_FIELD_HELP)).toBe('text field');
    expect(helpRole(BUTTON_HELP)).toBe('button');
    // VoiceOver's other wording (S08's ninth web recording).
    expect(helpRole('You are currently in a empty group.')).toBe('group');
    expect(helpRole('You are currently in a list, inside of web content.')).toBe('list');
    expect(helpRole('end of list')).toBe(null);
  });
});

// S16's regression cases (web_tests/s16_language_page_parts.spec.js),
// carried over to S08's screens. VO_SLUG is the example the made-up walks
// are drawn on; WRONG_TITLE is another S08 example's title, read where
// VO_SLUG's is expected; TIED is a help message that the positions tie to
// the stop before it (helpAfterStop), at `after` in the whole screen of
// `slug`.
const VO_SLUG = 'good-bulleted';
const WRONG_TITLE = `heading level 1 ${EXAMPLE_SCREENS['good-numbered'][0]}`;
const TIED = {
  slug: 'good-bulleted',
  after: screenStops('good-bulleted').length + 1,
  help: 'You are currently on a list, inside of web content. To move between items in this list, press '
    + 'Control-Option-Right Arrow or Control-Option-Left Arrow. To exit this web area, press Control-Option-Shift-Up Arrow.',
};
const VO_HELP_PREFIX = /^You are currently (?:on|in) /;
// The end witness's move back may read VoiceOver's help about the stop
// before the last (witnessBackHolds; the principal's decision of
// 2026-11-28): `pair` is a reading with a spoken role and a stop after it,
// `help` names that role, `wrongHelp` another; `row` is a transcript row
// whose stop before the last has that role, or null.
const WITNESS = {
  row: 'good-bulleted',
  help: 'You are currently in a empty group.',
  wrongHelp: 'You are currently on a button, inside of web content. To click this button, press Control-Option-Space.',
  pair: ['Bread empty group (3 of 3) 3 of 3', 'end of list'],
};

// How the walks are made again (runWalks), judged by judgeWalk as the
// VoiceOver spec's walks are, and the screens and lists every judge reads.
// Each test names every case it holds, and fails on the first case whose
// verdict is not the one given, with the case's name.
test.describe('the VoiceOver walks are made again only while incomplete', () => {
  const own = screenStops(VO_SLUG);
  const expected = EXPECTED_STOPS[VO_SLUG];
  const whole = [...own, EXAMPLE_HEADING, ...expected];

  test('every screen: a bad example\'s own stops end with its defect, no screen has a custom solution note, and no expected stop is empty or help', () => {
    for (const slug of Object.keys(EXAMPLE_SCREENS)) {
      if (slug.startsWith('bad-')) expect(screenStops(slug).at(-1), slug).toMatch(/^Defect: /);
      expect(screenStops(slug).some((s) => s.startsWith('Custom solution')), slug).toBe(false);
    }
    for (const [row, { expected: stops, screen }] of Object.entries(TRANSCRIPT_ROWS)) {
      for (const s of [...screen, ...stops]) expect(s !== '' && !VO_HELP_PREFIX.test(s), `${row}: "${s}"`).toBe(true);
    }
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

// The walk (collectWalk in web_tests/vo/s08_vo_walks.js), driven by made-up
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
      // walk fails for good: the help rule cannot leave it out. (S08's
      // fourth recording read a list's help after "end of list".)
      ['a help message at the last element\'s position, after its reading', await drive(screen, (c, el, n) => (
        n > words.length && c === words.length - 1 ? { phrase: TIED.help, position: at(words.length - 1) } : el)), 'wrong'],
    ];
    for (const [what, walk, verdict] of cases) {
      expect(judge(walk).verdict, `${what}: ${JSON.stringify(walk)}`).toBe(verdict);
    }
  });

  test('the reviewer\'s frozen capture, with elements after the last expected stop, would pass without the witness, and fails with it', async () => {
    const elements = [...screen, { phrase: 'Extra 0', position: at(80) }, extra];
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
    // gap makes the walk incomplete, walked again.
    // Three from the end, so that neither of the last two, which the
    // witness reads, is the one lost.
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
// (judgeTranscript in web_tests/vo/s08_vo_walks.js), never skipped: every
// browser and row once, walks in order, the last complete, each walk with
// its start, positions and unresolved-reads rows and the last with its end
// witness row. Made-up transcripts test the judge first.
test.describe('the web VoiceOver transcript is judged again from what it recorded', () => {
  const rows = Object.keys(TRANSCRIPT_ROWS);
  const R = rows[0];
  // The browser whose section a made-up transcript is building: a row's
  // list is its browser's (expectedStops; bad-lazy-list's differs).
  let current = BROWSERS[0];
  const whole = (row, b = current) => [...TRANSCRIPT_ROWS[row].screen, EXAMPLE_HEADING, ...expectedStops(row, b)];
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
  const transcript = (rowsFor) => ['# S08 List semantics: VoiceOver transcript (web, macOS)', '',
    'Result: PASS', ...BROWSERS.flatMap((b) => { current = b; return section(b, rowsFor(b)); })].join('\n');
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
  // bad-lazy-list's orders 1 to n, and a transcript whose `browser` walk of
  // it read `orders` after its screen's own stops and heading.
  const lazyOrders = (n) => Array.from({ length: n }, (_, i) => `Order ${i + 1}`);
  const lazyIn = (browser, orders) => transcript((b) => rows.flatMap((row) => (row === 'bad-lazy-list' && b === browser
    ? walkRows(row, 1, [...TRANSCRIPT_ROWS[row].screen, EXAMPLE_HEADING, ...orders], 'complete') : rowsOf(row))));

  test('made-up transcripts: a right one passes, and each wrong one names its problem', () => {
    const one = transcriptRow(R, 1, w, 'complete', 'x');
    // A stop with " / " or a backslash in it is written escaped and read
    // back whole (S10's bad-merged reads "3.4 / 5").
    const odd = ['Rating: 3.4 / 5 Reviews', '', 'a\\b', '(x)'];
    expect(stopsOf(stopsText(odd))).toEqual(odd);
    expect(stopsText(odd).split(' / ')).toHaveLength(odd.length);
    const exhausted = Array.from({ length: 20 }, (_, i) => w[i % w.length]);
    const cases = [
      ['a whole walk of every row in both browsers', transcript(right), true],
      // bad-lazy-list: each browser's walk reads orders 1 to N, consecutive,
      // for some N from 13 to 30 (STOP_RANGES).
      ...BROWSERS.flatMap((browser) => [
        ['to Order 13', lazyOrders(13), true],
        ['to Order 21', lazyOrders(21), true],
        ['to Order 22', lazyOrders(22), true],
        ['to Order 30', lazyOrders(30), true],
        ['to Order 12', lazyOrders(12), false],
        ['to Order 31', lazyOrders(31), false],
        ['to Order 22 with Order 15 skipped', lazyOrders(22).filter((o) => o !== 'Order 15'), false],
        ['to Order 22 with Order 15 read twice', [...lazyOrders(15), 'Order 15', ...lazyOrders(22).slice(15)], false],
        ['to Order 22, then another stop', [...lazyOrders(22), 'Extra'], false],
        ['to Order 22, then Order 13 again', [...lazyOrders(22), 'Order 13'], false],
      ].map(([what, orders, ok]) => [`${browser}'s bad-lazy-list read ${what}`, lazyIn(browser, orders), ok])),
      ['an empty transcript', '', false],
      ['fourteen copies of one walk row', transcript(() => Array(7).fill(one)), false],
      ['fourteen copies of one walk\'s rows', transcript(() => Array(7).fill(rowsOf(R)).flat()), false],
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
        walkRows(row, 1, TRANSCRIPT_ROWS[row].expected, 'complete'))), false],
      ['another row\'s screen stops', replaced('', transcriptRow(R, 1, [...TRANSCRIPT_ROWS[rows.at(-1)].screen, ...w.slice(h)], 'complete', 'x')), false],
      ['a walk whose title is an empty phrase', replaced('', transcriptRow(R, 1, ['', ...w.slice(1)], 'complete', 'x')), false],
      ['a stop past the end, empty', transcript(() => rows.flatMap((row) => (row === R ? walkRows(R, 1, [...w, ''], 'complete') : rowsOf(row)))), false],
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
      // An unresolved read is an unchanged read (S17's checks).
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

  test('the recording made before the walk took S16\'s rules (voiceover-web-before-judge-update.md.txt) lacks every new row, and fails for that', () => {
    const text = readFileSync(new URL('../docs/evidence/probes/s08/voiceover-web-before-judge-update.md.txt', import.meta.url), 'utf8');
    const problems = judgeTranscript(text);
    const walkRows = text.split('\n').filter((l) => /^\| `[a-z-]+-walk-\d+` \|/.test(l));
    expect(walkRows).toHaveLength(16);
    // Every walk lacks its start, positions, and unresolved-reads rows, and
    // every last walk its end witness row.
    for (const kind of ['start', 'positions', 'unresolved-reads']) {
      expect(problems.filter((p) => p.endsWith(` has no ${kind} row`)), kind).toHaveLength(walkRows.length);
    }
    expect(problems.filter((p) => / has no end witness$/.test(p))).toHaveLength(BROWSERS.length * rows.length);
    // The rest: each walk, having no end row, did not reach its end, and
    // judges wrong. Its row is in the old form too: a complete walk logged
    // only what follows the "Example" heading, exactly the expected list.
    const rest = problems.filter((p) => !/ has no (start|positions|unresolved-reads) row$| has no end witness$/.test(p));
    expect(rest.every((p) => / was recorded (complete|incomplete) and judges wrong$/.test(p)), rest.join('; ')).toBe(true);
    expect(rest).toHaveLength(walkRows.length);
    let section = null;
    for (const line of text.split('\n')) {
      section = /^## (\S+)$/.exec(line)?.[1] ?? section;
      const m = /^\| `([a-z-]+)-walk-\d+` \| (.*) \(complete: .*\) \|$/.exec(line);
      if (m) expect(m[2], `${section} ${m[1]}`).toBe(TRANSCRIPT_ROWS[m[1]].expected.join(' / '));
    }
  });

  test('rounds 7 to 10 (2026-11-28) judge by today\'s rules as listed: only the verdicts they recorded', () => {
    // Each end witnessed. bad-lazy-list read, Chromium/WebKit: 30/13,
    // 22/13, 30/21 and 20/30; rounds 7 and 8 were recorded wrong on
    // Chromium's, round 9 on WebKit's, each against the list it was judged
    // by then. In rounds 9 and 10 the end witness's move back read
    // VoiceOver's "You are currently in a empty group." at the position
    // recorded for the last item, in place of the item; those walks were
    // recorded wrong, and the witness now holds (witnessBackHolds).
    const recorded = (b, slug) => `${b} ${slug}: the last walk, 1, was recorded wrong and judges complete`;
    const rounds = [
      [7, { chromium: 30, webkit: 13 }, [recorded('chromium', 'bad-lazy-list')]],
      [8, { chromium: 22, webkit: 13 }, [recorded('chromium', 'bad-lazy-list')]],
      [9, { chromium: 30, webkit: 21 }, [recorded('chromium', 'good-bulleted'), recorded('chromium', 'good-numbered'),
        recorded('webkit', 'good-bulleted'), recorded('webkit', 'bad-lazy-list')]],
      [10, { chromium: 20, webkit: 30 }, [recorded('chromium', 'good-cupertino'), recorded('webkit', 'good-numbered')]],
    ];
    for (const [round, reached, problems] of rounds) {
      const file = `docs/evidence/probes/s08/voiceover-web-round${round}-fail.md.txt`;
      const text = readFileSync(new URL(`../${file}`, import.meta.url), 'utf8');
      expect(judgeTranscript(text), file).toEqual(problems);
      for (const b of BROWSERS) {
        // These rows hold the whole walk (the screen's own stops first).
        const section = text.slice(text.indexOf(`## ${b}`));
        const row = /^\| `bad-lazy-list-walk-1` \| (.*) \((?:complete|wrong|incomplete): .*\) \|$/m.exec(section)[1];
        const stops = stopsOf(row);
        expect(stops.slice(4), `${file} ${b}`).toEqual(lazyOrders(reached[b]));
        expect(ordersRead('bad-lazy-list', b, stops), `${file} ${b}`).toBe(reached[b]);
      }
    }
  });

  test('rounds 9 and 10: every end witness that read a help message read it at exactly the position recorded for the last item', () => {
    // Round 10 was recorded with VO_HELP matching "You are currently in",
    // so its capture put the phrase Guidepup logged for the move in place of
    // the help text (phraseForMove); the help text was still what it gave,
    // so the phrase logged for that move was the help text itself.
    const seen = [];
    for (const round of [9, 10]) {
      const text = readFileSync(new URL(`../docs/evidence/probes/s08/voiceover-web-round${round}-fail.md.txt`, import.meta.url), 'utf8');
      let browser = null;
      const rowsOf = {};
      for (const line of text.split('\n')) {
        browser = /^## (\S+)$/.exec(line)?.[1] ?? browser;
        const walk = /^\| `([a-z-]+)-walk-1` \| (.*) \((?:complete|wrong|incomplete): .*\) \|$/.exec(line);
        if (walk) (rowsOf[`${browser} ${walk[1]}`] ??= {}).stops = stopsOf(walk[2]);
        const at = /^\| `([a-z-]+)-walk-1-positions` \| (.*) \|$/.exec(line);
        if (at) (rowsOf[`${browser} ${at[1]}`] ??= {}).positions = at[2].split(' / ');
        const end = /^\| `([a-z-]+)-walk-1-end` \| back "(.*)" at (.*) \/ forward "(.*)" at (.*) \|$/.exec(line);
        if (end) (rowsOf[`${browser} ${end[1]}`] ??= {}).back = { phrase: end[2], position: end[3] };
      }
      for (const [key, { stops, positions, back }] of Object.entries(rowsOf)) {
        if (!VO_HELP.test(back.phrase)) continue;
        seen.push(`${round} ${key}: ${back.phrase}`);
        expect(back.position, key).toBe(positions.at(-2));
        expect(back.position, key).not.toBe(positions.at(-1));
        expect(helpRole(back.phrase), key).toBe(spokenRole(stops.at(-2)));
        expect(witnessBackHolds(back, stops, positions), key).toBe(true);
      }
    }
    expect(seen).toEqual([
      '9 chromium good-bulleted: You are currently in a empty group.',
      '9 chromium good-numbered: You are currently in a empty group.',
      '9 webkit good-bulleted: You are currently in a empty group.',
      '10 chromium good-cupertino: You are currently in a empty group.',
      '10 webkit good-numbered: You are currently in a empty group.',
    ]);
    expect(phraseForMove('You are currently in a empty group.', 'You are currently in a empty group.')).toBe('You are currently in a empty group.');
  });

  test('the end witness\'s move back: the stop before the last, or VoiceOver\'s help about it at exactly its recorded position', async () => {
    const [a, b] = WITNESS.pair;
    const at = (i) => `318, ${251 + 40 * i}, 1011, ${271 + 40 * i}`;
    const stops = ['heading level 2 Example', a, b];
    const positions = [at(0), at(1), at(2)];
    const cases = [
      ['the stop before the last, read again', { phrase: a, position: at(1) }, positions, true],
      ['help naming its role, at its recorded position', { phrase: WITNESS.help, position: at(1) }, positions, true],
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
    if (!WITNESS.row) return;
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

  test('the committed recording (docs/evidence/S08/voiceover-web.md) is right, every browser and row once', () => {
    // Never skipped: a missing file fails here.
    const text = readFileSync(new URL('../docs/evidence/S08/voiceover-web.md', import.meta.url), 'utf8');
    expect(judgeTranscript(text)).toEqual([]);
  });
});
