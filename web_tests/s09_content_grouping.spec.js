// L3 for S09 Content grouping on web: what the page exposes for each
// example's units and groups, and what a click and the keys do. Spec:
// docs/specs/S09-content-grouping.md. Runs against the release build in
// build/web.
import { readFileSync } from 'node:fs';
import { test, expect } from '@playwright/test';
import { byId, tabTo, technique } from './support/techniques.js';
import {
  BROWSERS, EXAMPLE_HEADING, EXAMPLE_SCREENS, EXPECTED_STOPS, TRANSCRIPT_ROWS, collectWalk, endRow, helpRole,
  judgeCollectedWalk, judgeExampleWalk, judgeTranscript, judgeWalk, positionsRow, runWalks, screenStops,
  spokenRole, startRow, stopsOf, stopsText, transcriptRow, unresolvedRow,
  witnessBackHolds,
} from './vo/s09_vo_walks.js';

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

// How the web VoiceOver spec judges one walk's stops (judgeWalk, S16's, on
// S08's judgeExampleWalk). The walks here are made up; VoiceOver is not
// used. Each test names every case it holds.
test.describe('the VoiceOver example walks are judged on every walk', () => {
  const expected = EXPECTED_STOPS['good-named-group'];
  const own = screenStops('good-named-group');
  // A help message in the form S08's fourth recording read one (WebKit),
  // with the role of a group.
  const HELP = 'You are currently on a group, inside of web content. To exit this web area, press Control-Option-Shift-Up Arrow.';
  const BUTTON_HELP = 'You are currently on a button, inside of web content. To click this button, press Control-Option-Space.';
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
    // A walk that reached the end with an expected stop not read: wrong.
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
    // An empty phrase is a failed capture: walked again, never passed.
    ['an empty first stop for the title, every later stop right', ['', ...own.slice(1), EXAMPLE_HEADING, ...expected], true, 'incomplete'],
    ['a button read as an empty phrase, every other stop right', screen(expected[0], '', ...expected.slice(2)), true, 'incomplete'],
    ['an empty first stop and a wrong reading later', ['', ...own.slice(1), EXAMPLE_HEADING, expected[0], 'On', ...expected.slice(2)], true, 'wrong'],
    ['an empty first stop and a walk that reached the end short', ['', ...own.slice(1), EXAMPLE_HEADING, expected[0]], true, 'wrong'],
    // A stop past the end is an element the screen does not have, empty or
    // not (S09's earlier judge walked an empty one again).
    ['an empty phrase after the last expected stop', screen(...expected, ''), true, 'wrong'],
    ['every stop an empty phrase', Array(8).fill(''), true, 'incomplete'],
    // With no positions recorded a help message is a stop like any other
    // (S09's earlier judge left out every help message wherever it came).
    ['a help message after the last stop, no positions', screen(...expected, HELP), true, 'wrong'],
    ['a help message in the middle, no positions', screen(expected[0], expected[1], HELP, ...expected.slice(2)), true, 'wrong'],
    ['a help message in place of an expected stop', screen(expected[0], HELP, ...expected.slice(2)), true, 'wrong'],
    ['a help message in place of the last stop', screen(...expected.slice(0, -1), HELP), true, 'wrong'],
    ['only help messages', [HELP, HELP], true, 'wrong'],
    // A walk that did not reach its end ran out of moves: wrong for good.
    ['an empty walk that ran out of moves', [], false, 'wrong'],
    ['a walk that ran out of moves after the title', [own[0]], false, 'wrong'],
    ['a walk that ran out of moves inside the group', screen(...expected.slice(0, 2)), false, 'wrong'],
    ['every stop read, but the end not reached', screen(...expected), false, 'wrong'],
  ];
  test(`the judge: whole screens, wrong readings, short walks, empty captures and help with no positions (${cases.length} cases)`, () => {
    for (const [what, stops, reachedEnd, verdict] of cases) {
      expect(judgeWalk(stops, reachedEnd, expected, own).verdict, what).toBe(verdict);
    }
  });

  // A help message is left out only when the walk's positions tie it to the
  // stop before it: same position, a reading before it, and its role in
  // that reading (helpAfterStop in s09_vo_walks.js, S08's rule). Tested
  // only on these made-up walks: no S09 recording has had a help message.
  const at = (stops, same = []) => {
    const out = [];
    stops.forEach((_, i) => out.push(same.includes(i) ? out[i - 1] : `p${i}`));
    return out;
  };
  const whole = screen(...expected);
  const n = whole.length;
  const g = own.length + 1; // the group's own stop
  const helpCases = [
    ['group help after the group\'s stop, at its position: left out',
      screen(expected[0], HELP, ...expected.slice(1)), at(screen(expected[0], HELP, ...expected.slice(1)), [g + 1]), 'complete'],
    ['group help after the end of the group, at its position: left out',
      screen(...expected.slice(0, 4), HELP, expected[4]), at(screen(...expected.slice(0, 4), HELP, expected[4]), [g + 4]), 'complete'],
    ['button help after On, at its position: left out',
      screen(...expected.slice(0, 2), BUTTON_HELP, ...expected.slice(2)), at(screen(...expected.slice(0, 2), BUTTON_HELP, ...expected.slice(2)), [g + 2]), 'complete'],
    ['group help at a new position after the whole screen (an extra element): fails', [...whole, HELP], at([...whole, HELP]), 'wrong'],
    ['group help after the status, a text with no role, at its position: fails', [...whole, HELP], at([...whole, HELP], [n]), 'wrong'],
    ['group help after On, a button, at its position: fails',
      screen(...expected.slice(0, 2), HELP, ...expected.slice(2)), at(screen(...expected.slice(0, 2), HELP, ...expected.slice(2)), [g + 2]), 'wrong'],
    ['help in place of an expected stop: fails', screen(expected[0], HELP, ...expected.slice(2)), at(screen(expected[0], HELP, ...expected.slice(2))), 'wrong'],
    ['help after an empty stop, at its position: fails', screen(expected[0], '', HELP, ...expected.slice(2)),
      at(screen(expected[0], '', HELP, ...expected.slice(2)), [g + 2]), 'wrong'],
    ['help with positions of the wrong length: fails', [...whole, HELP], at(whole), 'wrong'],
    // The role is the spoken role, never a word of the name.
    ['button help after the title heading, at its position: fails', [own[0], BUTTON_HELP, ...whole.slice(1)],
      at([own[0], BUTTON_HELP, ...whole.slice(1)], [1]), 'wrong'],
    ['no help message', whole, at(whole), 'complete'],
  ];
  test(`a help message is left out only when tied to the stop before it, by position and spoken role (${helpCases.length} cases)`, () => {
    for (const [what, stops, positions, verdict] of helpCases) {
      expect(judgeWalk(stops, true, expected, own, positions).verdict, what).toBe(verdict);
    }
  });

  test('a reading\'s spoken role comes from its role part only, and a help message names its role', () => {
    const roles = [
      ['heading level 1 Question and buttons merged', 'heading'],
      [`${GROUP} group`, 'group'],
      [`end of ${GROUP} group`, 'group'],
      ['On button', 'button'],
      [`${GROUP} On Off button`, 'button'],
      ['App information button', 'button'],
      ['City Boston', null],
      ['Light: not set', null],
      ["Defect: The question and both buttons are one button, whose action is On's.", null],
    ];
    for (const [reading, role] of roles) expect(spokenRole(reading), reading).toBe(role);
    expect(helpRole(HELP)).toBe('group');
    expect(helpRole(BUTTON_HELP)).toBe('button');
    // VoiceOver's other wording (S08's ninth web recording).
    expect(helpRole('You are currently in a empty group.')).toBe('group');
    expect(helpRole('You are currently in a list, inside of web content.')).toBe('list');
    expect(helpRole('Light: not set')).toBe(null);
  });

  test('bad-split-facts\' split walk is complete and the merged reading wrong; bad-merged-group\'s first-recording WebKit walk, its title empty, is walked again', () => {
    const split = EXPECTED_STOPS['bad-split-facts'];
    const ownStops = screenStops('bad-split-facts');
    const walk = (...content) => [...ownStops, EXAMPLE_HEADING, ...content];
    expect(judgeWalk(walk(...split), true, split, ownStops).verdict).toBe('complete');
    expect(judgeWalk(walk('City Boston', 'Founded 1630'), true, split, ownStops).verdict).toBe('wrong');
    // docs/evidence/probes/s09/voiceover-web-round1-fail.md.txt.
    const measured = EXPECTED_STOPS['bad-merged-group'];
    const mergedOwn = screenStops('bad-merged-group');
    expect(judgeWalk(['', ...mergedOwn.slice(1), EXAMPLE_HEADING, ...measured], true, measured, mergedOwn).verdict).toBe('incomplete');
    expect(judgeWalk([...mergedOwn, EXAMPLE_HEADING, ...measured], true, measured, mergedOwn).verdict).toBe('complete');
  });
});

// S16's regression cases (web_tests/s16_language_page_parts.spec.js),
// carried over to S09's screens. VO_SLUG is the example the made-up walks
// are drawn on; WRONG_TITLE is another S09 example's title, read where
// VO_SLUG's is expected; TIED is a help message that the positions tie to
// the stop before it (helpAfterStop), at `after` in the whole screen of
// `slug`.
const VO_SLUG = 'good-named-group';
const WRONG_TITLE = `heading level 1 ${EXAMPLE_SCREENS['bad-merged-group'][0]}`;
const TIED = {
  slug: 'good-named-group',
  after: screenStops('good-named-group').length + 1,
  help: 'You are currently on a group, inside of web content. To exit this web area, press Control-Option-Shift-Up Arrow.',
};
const VO_HELP_PREFIX = /^You are currently (?:on|in) /;
// The end witness's move back may read VoiceOver's help about the stop
// before the last (witnessBackHolds; the principal's decision of
// 2026-11-28): `pair` is a reading with a spoken role and a stop after it,
// `help` names that role, `wrongHelp` another; `row` is a transcript row
// whose stop before the last has that role, or null.
const WITNESS = {
  row: 'good-named-group',
  help: 'You are currently on a group, inside of web content.',
  wrongHelp: 'You are currently on a button, inside of web content. To click this button, press Control-Option-Space.',
  pair: [`end of ${GROUP} group`, 'Light: not set'],
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

// The walk (collectWalk in web_tests/vo/s09_vo_walks.js), driven by made-up
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
// (judgeTranscript in web_tests/vo/s09_vo_walks.js), never skipped: every
// browser and row once, walks in order, the last complete, each walk with
// its start, positions and unresolved-reads rows and the last with its end
// witness row. Made-up transcripts test the judge first.
test.describe('the web VoiceOver transcript is judged again from what it recorded', () => {
  const rows = Object.keys(TRANSCRIPT_ROWS);
  const R = rows[0];
  const whole = (row) => [...TRANSCRIPT_ROWS[row].screen, EXAMPLE_HEADING, ...TRANSCRIPT_ROWS[row].expected];
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
  const transcript = (rowsFor) => ['# S09 Content grouping: VoiceOver transcript (web, macOS)', '',
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
    const exhausted = Array.from({ length: 20 }, (_, i) => w[i % w.length]);
    const cases = [
      ['a whole walk of every row in both browsers', transcript(right), true],
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
    const text = readFileSync(new URL('../docs/evidence/probes/s09/voiceover-web-before-judge-update.md.txt', import.meta.url), 'utf8');
    const problems = judgeTranscript(text);
    const walkRows = text.split('\n').filter((l) => /^\| `[a-z-]+-walk-\d+` \|/.test(l));
    expect(walkRows).toHaveLength(13);
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

  test('the committed recording (docs/evidence/S09/voiceover-web.md) is right, every browser and row once', () => {
    // Never skipped: a missing file fails here.
    const text = readFileSync(new URL('../docs/evidence/S09/voiceover-web.md', import.meta.url), 'utf8');
    expect(judgeTranscript(text)).toEqual([]);
  });
});
