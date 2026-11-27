// L3 for S09 Content grouping on web: what the page exposes for each
// example's units and groups, and what a click and the keys do. Spec:
// docs/specs/S09-content-grouping.md. Runs against the release build in
// build/web.
import { test, expect } from '@playwright/test';
import { byId, tabTo, technique } from './support/techniques.js';
import { EXAMPLE_HEADING, EXAMPLE_SCREENS, judgeExampleWalk, runWalks, screenStops } from './vo/s09_vo_walks.js';

// The example screen's own "Example" heading; the technique's page has
// "Good examples" and "Bad examples", so the name must match exactly.
const exampleHeading = (page) => page.getByRole('heading', { name: 'Example', exact: true, level: 2 });
const { open } = technique('S09', { ready: exampleHeading, settle: 600 });

const FACTS = [['City', 'Boston'], ['Founded', '1630']];
const GROUP = 'Kitchen light';
const TARGET = 'App information';

/**
 * The example's own elements in the page's order: every semantics element
 * after the "Example" heading up to the example's status line (or the end
 * of the screen) that has a role, a name, or text of its own, written as
 * `role "name"` and indented by how deep it sits below the first of them.
 * Unlike Chromium's ARIA snapshot, which runs neighbouring texts into one
 * line, this keeps one entry per element, so a merged label and value
 * (one element) and a split one (two) differ. Line breaks in a name are
 * kept as "\n".
 */
async function exampleElements(page) {
  return page.evaluate(() => {
    const host = document.querySelector('flt-semantics-host');
    const all = [...host.querySelectorAll('flt-semantics, h1, h2, h3, h4, h5, h6')];
    const start = all.findIndex((e) => /^H2$/.test(e.tagName) && e.textContent.trim() === 'Example');
    const out = [];
    const depth = (e) => {
      let d = 0;
      for (let p = e.parentElement; p && p !== host; p = p.parentElement) d++;
      return d;
    };
    let base = null;
    for (const e of all.slice(start + 1)) {
      const id = e.getAttribute('flt-semantics-identifier') ?? '';
      if (/^s09-.*-(status|opens)$/.test(id)) break;
      const role = e.getAttribute('role') ?? (/^H\d$/.test(e.tagName) ? e.tagName.toLowerCase() : null);
      const label = e.getAttribute('aria-label');
      const own = [...e.childNodes].filter((n) => n.nodeType === 3 || n.tagName === 'SPAN')
        .map((n) => n.textContent).join('');
      const name = label ?? own;
      if (!role && !name) continue;
      if (base === null) base = depth(e);
      out.push(`${'  '.repeat(depth(e) - base)}${role ?? 'text'} "${name.replace(/\n/g, '\\n')}"`);
    }
    if (start < 0) out.unshift('(no Example heading)');
    return out;
  });
}

/** The text of the status line with the identifier `id`. */
const statusOf = (page, id) => byId(page, id).textContent();

const controls = {
  'good-named-group': [
    { id: 's09-good-named-group-on', name: 'On', status: 's09-good-named-group-status', after: 'Light: on' },
    { id: 's09-good-named-group-off', name: 'Off', status: 's09-good-named-group-status', after: 'Light: off' },
  ],
  'good-tap-target': [
    { id: 's09-good-tap-target-info', name: TARGET, status: 's09-good-tap-target-opens', after: 'Opens: 1' },
  ],
};

test.describe('good examples', () => {
  test('good-merged-facts: each label and its value are one element, in the order shown', async ({ page }) => {
    await open(page, 'good-merged-facts');
    expect(await exampleElements(page)).toEqual(FACTS.map(([l, v]) => `text "${l}\\n${v}"`));
    // Chromium names each one by both texts.
    for (const [l, v] of FACTS) {
      await expect(page.locator('flt-semantics-host').getByText(`${l}\n${v}`, { exact: true })).toHaveCount(1);
    }
    await expect(page.getByRole('button')).toHaveCount(1);
  });

  test('good-cupertino: each row is one element, its title and its value', async ({ page }) => {
    await open(page, 'good-cupertino');
    expect(await exampleElements(page)).toEqual(FACTS.map(([l, v]) => `text "${l}\\n${v}"`));
    await expect(page.getByRole('button')).toHaveCount(1);
  });

  test('good-named-group: a group named by the question holds the two buttons, and the question is not text again', async ({ page }) => {
    await open(page, 'good-named-group');
    expect(await exampleElements(page)).toEqual([
      `group "${GROUP}"`,
      '  button "On"',
      '  button "Off"',
    ]);
    const group = page.getByRole('group', { name: GROUP, exact: true });
    await expect(group).toHaveCount(1);
    await expect(group.getByRole('button')).toHaveCount(2);
    await expect(group.getByRole('button', { name: 'On', exact: true })).toHaveCount(1);
    await expect(group.getByRole('button', { name: 'Off', exact: true })).toHaveCount(1);
    await expect(page.locator('flt-semantics-host').getByText(GROUP, { exact: true })).toHaveCount(0);
    await expect(page.getByRole('button')).toHaveCount(3);
  });

  test('good-named-group: Tab goes Back, On, Off, and on round to Back again', async ({ page }) => {
    await open(page, 'good-named-group');
    const stops = [];
    for (let i = 0; i < 6; i++) {
      await page.keyboard.press('Tab');
      await page.waitForTimeout(150);
      stops.push(await page.evaluate(() => {
        const e = document.activeElement;
        return e?.closest('flt-semantics-host') ? e.textContent.trim() : `(${e?.tagName})`;
      }));
    }
    // After Off, focus leaves Flutter's elements for the page (FL-421) and
    // comes back to Back.
    const back = stops.indexOf('Back', 1);
    expect(stops.slice(0, 3)).toEqual(['Back', 'On', 'Off']);
    expect(back, `a whole cycle: ${stops.join(' -> ')}`).toBeGreaterThan(2);
    expect(stops.slice(3, back).every((s) => s.startsWith('('))).toBe(true);
  });

  test('good-tap-target: one button named by its text, and the icon is no element of its own', async ({ page }) => {
    await open(page, 'good-tap-target');
    expect(await exampleElements(page)).toEqual([`button "${TARGET}"`]);
    await expect(page.getByRole('button')).toHaveCount(2);
    await expect(page.getByRole('img')).toHaveCount(0);
  });

  for (const [slug, list] of Object.entries(controls)) {
    for (const c of list) {
      test(`${slug}: a click on ${c.id} does its own action`, async ({ page }) => {
        await open(page, slug);
        expect(await statusOf(page, c.status)).not.toBe(c.after);
        await byId(page, c.id).click();
        await expect.poll(() => statusOf(page, c.status), { timeout: 3000 }).toBe(c.after);
      });

      test(`${slug}: a click from assistive technology on ${c.id} does its own action`, async ({ page }) => {
        await open(page, slug);
        await byId(page, c.id).evaluate((e) => e.click());
        await expect.poll(() => statusOf(page, c.status), { timeout: 3000 }).toBe(c.after);
      });

      for (const key of ['Enter', 'Space']) {
        test(`${slug}: Tab reaches ${c.id} and ${key} does its own action`, async ({ page }) => {
          await open(page, slug);
          expect(await tabTo(page, byId(page, c.id))).toBe(true);
          await expect(byId(page, c.id)).toHaveRole('button');
          await expect(byId(page, c.id)).toHaveAccessibleName(c.name);
          await page.keyboard.press(key);
          await expect.poll(() => statusOf(page, c.status), { timeout: 3000 }).toBe(c.after);
        });
      }
    }
  }
});

test.describe('bad examples have their defect', () => {
  test('bad-split-facts: four elements, both labels before both values', async ({ page }) => {
    await open(page, 'bad-split-facts');
    expect(await exampleElements(page)).toEqual([
      `text "${FACTS[0][0]}"`,
      `text "${FACTS[1][0]}"`,
      `text "${FACTS[0][1]}"`,
      `text "${FACTS[1][1]}"`,
    ]);
  });

  test('bad-merged-group: one button named by the question and both buttons, and no button "Off"', async ({ page }) => {
    await open(page, 'bad-merged-group');
    expect(await exampleElements(page)).toEqual([`button "${GROUP}\\nOn\\nOff"`]);
    const merged = byId(page, 's09-bad-merged-group-light');
    await expect(merged).toHaveRole('button');
    await expect(merged).toHaveAccessibleName(`${GROUP} On Off`);
    await expect(page.getByRole('button')).toHaveCount(2);
    await expect(page.getByRole('button', { name: 'Off', exact: true })).toHaveCount(0);
    await expect(page.getByRole('group', { name: GROUP })).toHaveCount(0);
  });

  test('bad-merged-group: the keyboard reaches Off\'s own focus, but a click from assistive technology on the one button turns the light on', async ({ page }) => {
    await open(page, 'bad-merged-group');
    const status = 's09-bad-merged-group-status';
    // Back, then the merged element twice: On's focus, then Off's.
    for (let i = 0; i < 3; i++) {
      await page.keyboard.press('Tab');
      await page.waitForTimeout(150);
    }
    await expect(byId(page, 's09-bad-merged-group-light')).toBeFocused();
    await page.keyboard.press('Enter');
    await expect.poll(() => statusOf(page, status), { timeout: 3000 }).toBe('Light: off');
    // What a screen reader activates is the element: its click is On's.
    await byId(page, 's09-bad-merged-group-light').evaluate((e) => e.click());
    await expect.poll(() => statusOf(page, status), { timeout: 3000 }).toBe('Light: on');
  });

  test('bad-merged-group: Tab stops on the one element twice, once for each button', async ({ page }) => {
    await open(page, 'bad-merged-group');
    const stops = [];
    for (let i = 0; i < 3; i++) {
      await page.keyboard.press('Tab');
      await page.waitForTimeout(150);
      stops.push(await page.evaluate(() => document.activeElement?.getAttribute('flt-semantics-identifier') ?? document.activeElement?.textContent.trim()));
    }
    expect(stops).toEqual(['Back', 's09-bad-merged-group-light', 's09-bad-merged-group-light']);
  });
});

// What the VoiceOver spec expects above each example's "Example" heading
// (EXAMPLE_SCREENS in vo/s09_vo_walks.js): each screen must show those
// texts, so that a change to a title or a defect is caught here.
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
  const expected = [`${GROUP} group`, 'On button', 'Off button', `end of ${GROUP} group`, 'Light: not set'];
  const own = screenStops('good-named-group');
  // A help message as S08's fourth recording read one (WebKit), with the
  // role of a group: its words are never judged.
  const HELP = 'You are currently on a group, inside of web content. To exit this web area, press Control-Option-Shift-Up Arrow.';
  const screen = (...content) => [...own, EXAMPLE_HEADING, ...content];
  const cases = [
    ['a correct walk', screen(...expected), true, 'complete'],
    // A stop read in other words, or out of its place: wrong at once.
    ['the question as plain text, with no group', screen(GROUP, ...expected.slice(1, 3), expected[4]), true, 'wrong'],
    ['the buttons merged into one', screen(`${GROUP} On Off button`, expected[4]), true, 'wrong'],
    ['a button with no role', screen(expected[0], 'On', ...expected.slice(2)), true, 'wrong'],
    ['the buttons swapped', screen(expected[0], expected[2], expected[1], ...expected.slice(3)), true, 'wrong'],
    ['the question read twice', screen(expected[0], GROUP, ...expected.slice(1)), true, 'wrong'],
    ['an empty stop put in, so that every later stop comes late', screen('', ...expected), true, 'wrong'],
    ['a stop after the status', screen(...expected, 'end of main'), true, 'wrong'],
    ['a wrong reading in a walk cut short', screen(expected[0], 'On'), false, 'wrong'],
    // A walk that reached the end with an expected stop not read: wrong,
    // not a short capture to be walked again.
    ['a walk that reached the end without the end of the group', screen(...expected.slice(0, 3), expected[4]), true, 'wrong'],
    ['a walk that reached the end without the status', screen(...expected.slice(0, -1)), true, 'wrong'],
    ['a walk with no title', [own[1], EXAMPLE_HEADING, ...expected], true, 'wrong'],
    ['a walk with no description', [own[0], EXAMPLE_HEADING, ...expected], true, 'wrong'],
    ['a walk with no heading', [...own, ...expected], true, 'wrong'],
    ['a walk of the example alone', [...expected], true, 'wrong'],
    ['a walk that reached the end having read nothing', [], true, 'wrong'],
    ['a walk that reached the end after the screen\'s own stops', [...own], true, 'wrong'],
    ['the screen\'s own stops out of their order', [own[1], own[0], EXAMPLE_HEADING, ...expected], true, 'wrong'],
    ['a stop that is not the screen\'s before the heading', ['Back button', ...own, EXAMPLE_HEADING, ...expected], true, 'wrong'],
    // An empty phrase is a failed capture: walked again, never passed (the
    // principal's rule of 2026-11-26, S08's judge).
    ['an empty first stop for the title, every later stop right', ['', ...own.slice(1), EXAMPLE_HEADING, ...expected], true, 'incomplete'],
    ['a button read as an empty phrase, every other stop right', screen(expected[0], '', ...expected.slice(2)), true, 'incomplete'],
    ['an empty first stop and a wrong reading later', ['', ...own.slice(1), EXAMPLE_HEADING, expected[0], 'On', ...expected.slice(2)], true, 'wrong'],
    ['an empty first stop and a walk that reached the end short', ['', ...own.slice(1), EXAMPLE_HEADING, expected[0]], true, 'wrong'],
    ['an empty phrase after the last expected stop', screen(...expected, ''), true, 'incomplete'],
    ['every stop an empty phrase', Array(8).fill(''), true, 'incomplete'],
    // VoiceOver's help message is not a stop of the page.
    ['a help message after the last stop', screen(...expected, HELP), true, 'complete'],
    ['a help message in the middle', screen(expected[0], expected[1], HELP, ...expected.slice(2)), true, 'complete'],
    ['a help message in place of an expected stop', screen(expected[0], HELP, ...expected.slice(2)), true, 'wrong'],
    ['a help message in place of the last stop', screen(...expected.slice(0, -1), HELP), true, 'wrong'],
    ['only help messages', [HELP, HELP], true, 'wrong'],
    ['a help message and a wrong reading', screen(expected[0], HELP, 'On', ...expected.slice(2)), true, 'wrong'],
    // Cut short before the end, with every stop right so far: may be walked
    // again.
    ['an empty walk cut short', [], false, 'incomplete'],
    ['a walk cut short after the title', [own[0]], false, 'incomplete'],
    ['a walk cut short after the heading', [...own, EXAMPLE_HEADING], false, 'incomplete'],
    ['a walk cut short inside the group', screen(...expected.slice(0, 2)), false, 'incomplete'],
    ['every stop read, but the end not reached', screen(...expected), false, 'incomplete'],
  ];
  for (const [what, stops, reachedEnd, verdict] of cases) {
    test(`${what}: ${verdict}`, () => {
      expect(judgeExampleWalk(stops, reachedEnd, expected, own).verdict).toBe(verdict);
    });
  }

  test('a bad example\'s own stops include its defect', () => {
    expect(screenStops('bad-merged-group').at(-1)).toMatch(/^Defect: /);
  });

  test('bad-split-facts: the walk of the split table is complete, and the merged reading is wrong', () => {
    const split = ['City', 'Founded', 'Boston', '1630'];
    const ownStops = screenStops('bad-split-facts');
    const walk = (...content) => [...ownStops, EXAMPLE_HEADING, ...content];
    expect(judgeExampleWalk(walk(...split), true, split, ownStops).verdict).toBe('complete');
    expect(judgeExampleWalk(walk('City Boston', 'Founded 1630'), true, split, ownStops).verdict).toBe('wrong');
  });

  test('bad-merged-group: the first recording\'s WebKit walk, the title read as an empty phrase, is walked again', () => {
    // docs/evidence/probes/s09/voiceover-web-round1-fail.md.txt.
    const measured = [`${GROUP} On Off button`, 'Light: not set'];
    const ownStops = screenStops('bad-merged-group');
    const walk = ['', ...ownStops.slice(1), EXAMPLE_HEADING, ...measured];
    expect(judgeExampleWalk(walk, true, measured, ownStops).verdict).toBe('incomplete');
    expect(judgeExampleWalk([...ownStops, EXAMPLE_HEADING, ...measured], true, measured, ownStops).verdict).toBe('complete');
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

  for (const [what, walk] of [
    ['a wrong reading', { stops: screen(GROUP), reachedEnd: true }],
    ['a walk that reached the end without the status', { stops: screen(...expected.slice(0, -1)), reachedEnd: true }],
    ['a walk with no title', { stops: [own[1], EXAMPLE_HEADING, ...expected], reachedEnd: true }],
    ['a walk with no heading', { stops: [...own, ...expected], reachedEnd: true }],
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
    const { walkOnce, made } = sequence(emptyTitle, { stops: screen(GROUP), reachedEnd: true }, right);
    expect((await runWalks(walkOnce, judge)).verdict).toBe('wrong');
    expect(made()).toBe(2);
  });

  test('three empty captures fail, and no fourth walk is made', async () => {
    const { walkOnce, made } = sequence(emptyTitle, emptyTitle, emptyTitle, right);
    expect(await runWalks(walkOnce, judge)).toMatchObject({ verdict: 'incomplete', walks: 3 });
    expect(made()).toBe(3);
  });

  test('a wrong walk after a short one still fails, and no third walk is made', async () => {
    const { walkOnce, made } = sequence(short, { stops: screen(...expected.slice(0, -1)), reachedEnd: true }, right);
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
