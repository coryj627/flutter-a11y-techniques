// L3 for C02 Toggle button on web: what the browser's accessibility tree
// exposes. Spec: docs/specs/C02-toggle-button.md. Runs against the release
// build in build/web.
import { test, expect } from '@playwright/test';
import { byId, tabTo, technique } from './support/techniques.js';
// Pure logic, with no VoiceOver: imported here so that CI tests it.
import fs from 'node:fs';
import { fileURLToPath } from 'node:url';
import {
  EXAMPLE_HEADING, EXAMPLE_SCREENS, judgeControlWalk, judgeExampleWalk, runControlWalks, runWalks, screenStops,
} from './vo/c02_vo_walks.js';

const { open, expectCount } = technique('C02', { countLabel: 'Changes' });

// slug, identifier, name, role. Each starts off. Flutter 3.47.5 writes no
// aria-pressed for any node (docs/flutter-limitations.md, FL-200): a
// toggled node is a switch and a checked one a checkbox, with
// aria-checked.
const toggles = [
  ['good-icon-button', 'c02-good-icon-button-bold', 'Bold', 'switch'],
  ['good-toggle-buttons', 'c02-good-toggle-buttons-bold', 'Bold', 'checkbox'],
  ['good-toggle-buttons', 'c02-good-toggle-buttons-italic', 'Italic', 'checkbox'],
  ['good-toggle-buttons', 'c02-good-toggle-buttons-underline', 'Underline', 'checkbox'],
  ['good-cupertino', 'c02-good-cupertino-mute', 'Mute', 'switch'],
  ['good-custom', 'c02-good-custom-mute', 'Mute', 'switch'],
];

/** Expects `control` to have no state attribute but `aria-checked`. */
async function expectOnlyChecked(control) {
  // Written to fail when Flutter starts to write aria-pressed (FL-200).
  await expect(control).not.toHaveAttribute('aria-pressed', /.*/);
  await expect(control).not.toHaveAttribute('aria-current', /.*/);
  await expect(control).not.toHaveAttribute('aria-selected', /.*/);
}

test.describe('toggles', () => {
  for (const [slug, id, name, role] of toggles) {
    test(`${id}: a ${role} named "${name}", off`, async ({ page }) => {
      await open(page, slug);
      const control = byId(page, id);
      await expect(control).toHaveRole(role);
      await expect(control).toHaveAccessibleName(name);
      await expect(control).toHaveAttribute('aria-checked', 'false');
      await expect(control).toBeEnabled();
      await expectOnlyChecked(control);
      // One element carries the name.
      await expect(page.getByRole(role, { name, exact: true })).toHaveCount(1);
      await expect(page.getByRole('button', { name, exact: true })).toHaveCount(0);
    });

    test(`${id}: a click, Space, and Enter each change the state, and the name stays`, async ({ page }) => {
      await open(page, slug);
      const control = byId(page, id);
      await control.click();
      await expect(control).toHaveAttribute('aria-checked', 'true');
      await expectCount(page, slug, 1);
      await expect(control).toHaveAccessibleName(name);
      await expectOnlyChecked(control);
      expect(await tabTo(page, control, 10), 'Tab reaches the control').toBe(true);
      await page.keyboard.press('Space');
      await expect(control).toHaveAttribute('aria-checked', 'false');
      await expectCount(page, slug, 2);
      await page.keyboard.press('Enter');
      await expect(control).toHaveAttribute('aria-checked', 'true');
      await expectCount(page, slug, 3);
      await expect(control).toHaveAccessibleName(name);
    });
  }

  test('good-toggle-buttons: each button changes only itself', async ({ page }) => {
    await open(page, 'good-toggle-buttons');
    await byId(page, 'c02-good-toggle-buttons-italic').click();
    await expect(byId(page, 'c02-good-toggle-buttons-italic')).toHaveAttribute('aria-checked', 'true');
    await expect(byId(page, 'c02-good-toggle-buttons-bold')).toHaveAttribute('aria-checked', 'false');
    await expect(byId(page, 'c02-good-toggle-buttons-underline')).toHaveAttribute('aria-checked', 'false');
    await expectCount(page, 'good-toggle-buttons', 1);
  });
});

test.describe('bad examples have their defect', () => {
  test('bad-selected-only: a button whose state is aria-current, said only when it is on', async ({ page }) => {
    await open(page, 'bad-selected-only');
    const control = byId(page, 'c02-bad-selected-only-bold');
    await expect(page.getByRole('switch')).toHaveCount(0);
    await expect(page.getByRole('checkbox')).toHaveCount(0);
    for (const [clicks, current] of [[0, 'false'], [1, 'true'], [2, 'false']]) {
      await expect(control).toHaveRole('button');
      await expect(control).toHaveAccessibleName('Bold');
      // aria-current is a different state from pressed: this is the web's
      // 4.1.2 failure (FL-201). Written to fail when Flutter writes a
      // pressed or checked state here.
      await expect(control).toHaveAttribute('aria-current', current);
      await expect(control).not.toHaveAttribute('aria-pressed', /.*/);
      await expect(control).not.toHaveAttribute('aria-checked', /.*/);
      await expectCount(page, 'bad-selected-only', clicks);
      if (clicks === 0) await control.click();
      if (clicks === 1) {
        expect(await tabTo(page, control, 10), 'Tab reaches the button').toBe(true);
        await page.keyboard.press('Space');
      }
    }
  });

  test('bad-no-state: a button with no state, before and after it is used', async ({ page }) => {
    await open(page, 'bad-no-state');
    const control = byId(page, 'c02-bad-no-state-mute');
    await expect(page.getByRole('switch')).toHaveCount(0);
    for (let clicks = 0; clicks < 3; clicks++) {
      await expectCount(page, 'bad-no-state', clicks);
      await expect(control).toHaveRole('button');
      await expect(control).toHaveAccessibleName('Mute');
      for (const state of ['aria-pressed', 'aria-checked', 'aria-current', 'aria-selected']) {
        await expect(control).not.toHaveAttribute(state, /.*/);
      }
      if (clicks < 2) await control.click();
    }
  });

  test('bad-label-changes: the name changes with the state', async ({ page }) => {
    await open(page, 'bad-label-changes');
    const control = byId(page, 'c02-bad-label-changes-mute');
    await expect(control).toHaveRole('switch');
    await expect(control).toHaveAccessibleName('Mute');
    await expect(control).toHaveAttribute('aria-checked', 'false');
    await control.click();
    await expect(control).toHaveAttribute('aria-checked', 'true');
    await expect(control).toHaveAccessibleName('Unmute');
    // The control can no longer be found by the name it had.
    await expect(page.getByRole('switch', { name: 'Mute', exact: true })).toHaveCount(0);
    await expectCount(page, 'bad-label-changes', 1);
  });
});

// How the web VoiceOver spec judges one walk of its plain HTML comparison
// page (web_tests/vo/c02_toggle_button_vo.spec.js, `control-html`). The
// walks here are made up; VoiceOver is not used.
test.describe('the VoiceOver comparison page is judged on every walk', () => {
  const good = ['Bold toggle button', 'Italic selected toggle button', 'Underline current item button'];
  const walk = (buttons) => ['heading level 2 Example', 'Text styles', ...buttons, 'Changes: 0', 'end of main'];
  const cases = [
    ['a correct walk', walk(good), true, 'complete'],
    ['a bare name', walk(['Bold', ...good.slice(1)]), true, 'wrong'],
    ['a state word before the name', walk(['selected Bold toggle button', ...good.slice(1)]), true, 'wrong'],
    ['a button read as another button', walk([good[0], 'Italic toggle button', good[2]]), true, 'wrong'],
    ['a reading with no name, between the neighbours', walk([good[0], 'toggle button', good[2]]), true, 'wrong'],
    ['an empty reading, between the neighbours', walk([good[0], '', good[2]]), true, 'wrong'],
    ['a wrong reading before the page is reached', ['Bold', ...walk(good)], true, 'wrong'],
    ['an empty walk', [], false, 'incomplete'],
    ['a partial walk: a button gone past without being read', walk(good.slice(1)), true, 'incomplete'],
    ['a partial walk: the end not reached', ['heading level 2 Example', 'Text styles', good[0]], false, 'incomplete'],
    ['a correct reading that did not reach the end', walk(good), false, 'incomplete'],
    // Without "Text styles" an empty first stop cannot be told from an
    // empty button reading, so it is wrong.
    ['a walk that missed the stop before the buttons, with an empty first stop', ['', ...good, 'Changes: 0', 'end of main'], true, 'wrong'],
    ['a walk that missed the stop before the buttons', ['heading level 2 Example', ...good, 'Changes: 0', 'end of main'], true, 'incomplete'],
    // Walks that did not read "Text styles": judged from the first stop,
    // or after the heading.
    ['no "Text styles", a nameless reading', ['heading level 2 Example', 'toggle button', good[1], 'Changes: 0'], true, 'wrong'],
    ['no "Text styles", an empty reading', ['heading level 2 Example', good[0], '', 'Changes: 0'], true, 'wrong'],
    ['no "Text styles", a stop that is not the page\'s', ['Back button'], false, 'wrong'],
    ['no "Text styles", readings out of order', ['heading level 2 Example', good[1], good[0]], false, 'wrong'],
    ['no "Text styles", the heading only', ['heading level 2 Example'], false, 'incomplete'],
    ['"Text styles" read, readings out of order', walk([good[1], good[0], good[2]]), true, 'wrong'],
    ['"Text styles" read, a reading twice', walk([good[0], good[0], good[1], good[2]]), true, 'wrong'],
    // Found by trying to break the judge: the page's stops either side of
    // the buttons are checked too.
    ['a stop before "Text styles" that is not the heading', ['Changes: 0', 'Text styles', ...good, 'Changes: 0'], true, 'wrong'],
    ['an unknown stop before "Text styles"', ['Back button', 'Text styles', ...good, 'Changes: 0'], true, 'wrong'],
    ['a reading after the count', ['Text styles', ...good, 'Changes: 0', 'toggle button'], true, 'wrong'],
    ['WebKit\'s empty heading before "Text styles"', ['', 'Text styles', ...good, 'Changes: 0', 'end of main'], true, 'complete'],
    // Truncated walks: the stop after the buttons was never reached.
    ['a truncated walk with a nameless reading', ['Text styles', 'toggle button', good[1]], false, 'wrong'],
    ['a truncated walk with an empty reading', ['Text styles', good[0], ''], false, 'wrong'],
    ['a truncated walk with a bare name', ['Text styles', 'Bold'], false, 'wrong'],
    ['a truncated walk that read its buttons right', ['Text styles', good[0], good[1]], false, 'incomplete'],
    ['a walk that skipped the count and ended the page', ['Text styles', ...good, 'end of main'], true, 'incomplete'],
  ];
  for (const [what, stops, reachedEnd, verdict] of cases) {
    test(`${what}: ${verdict}`, () => {
      expect(judgeControlWalk(stops, reachedEnd).verdict).toBe(verdict);
    });
  }

  // The tries of one test: made-up walks, handed out in order.
  const walks = (...list) => {
    let i = 0;
    const walkOnce = async () => list[i++];
    return { walkOnce, made: () => i };
  };
  const complete = { stops: walk(good), reachedEnd: true };
  const wrong = { stops: walk(['Bold', ...good.slice(1)]), reachedEnd: true };
  const partial = { stops: walk(good.slice(1)), reachedEnd: true };

  test('a wrong walk followed by a correct one fails, and no second walk is made', async () => {
    const { walkOnce, made } = walks(wrong, complete);
    expect((await runControlWalks(walkOnce)).verdict).toBe('wrong');
    expect(made()).toBe(1);
  });

  test('a wrong walk with no "Text styles" followed by a correct one fails, and no second walk is made', async () => {
    const noBefore = { stops: ['heading level 2 Example', 'toggle button', good[1], good[2], 'Changes: 0'], reachedEnd: true };
    const { walkOnce, made } = walks(noBefore, complete);
    expect((await runControlWalks(walkOnce)).verdict).toBe('wrong');
    expect(made()).toBe(1);
  });

  test('an empty walk followed by a correct one passes on the second', async () => {
    const { walkOnce } = walks({ stops: [], reachedEnd: false }, complete);
    expect(await runControlWalks(walkOnce)).toMatchObject({ verdict: 'complete', walks: 2 });
  });

  test('an incomplete walk followed by a correct one passes on the second', async () => {
    const { walkOnce, made } = walks(partial, complete);
    const result = await runControlWalks(walkOnce);
    expect(result.verdict).toBe('complete');
    expect(result.walks).toBe(2);
    expect(made()).toBe(2);
  });

  test('an incomplete walk followed by a wrong one fails', async () => {
    const { walkOnce } = walks(partial, wrong, complete);
    expect((await runControlWalks(walkOnce)).verdict).toBe('wrong');
  });

  test('three incomplete walks fail', async () => {
    const { walkOnce, made } = walks(partial, partial, partial, complete);
    expect((await runControlWalks(walkOnce)).verdict).toBe('incomplete');
    expect(made()).toBe(3);
  });

  test('every try is logged', async () => {
    const { walkOnce } = walks(partial, complete);
    const logged = [];
    await runControlWalks(walkOnce, { log: (n, stops, judged) => logged.push([n, judged.verdict]) });
    expect(logged).toEqual([[1, 'incomplete'], [2, 'complete']]);
  });

  // The runner's own retries would let a later passing attempt hide a wrong
  // one, so the comparison test turns them off. The VoiceOver spec cannot be
  // loaded here (its guard stops it), so its source is read.
  test('no test in the C02 VoiceOver spec is retried by the runner', () => {
    const source = fs.readFileSync(
      fileURLToPath(new URL('./vo/c02_toggle_button_vo.spec.js', import.meta.url)), 'utf8');
    // Code only: comments may mention retries.
    const code = source.split('\n').filter((line) => !line.trim().startsWith('//')).join('\n');
    const configure = code.indexOf('test.describe.configure({ retries: 0 });');
    expect(configure, 'the file turns runner retries off').toBeGreaterThan(-1);
    // At the top level, before any test or describe, so it covers them all.
    const firstTest = Math.min(...['test(', 'test.describe('].map((t) => {
      const i = code.indexOf(t);
      return i < 0 ? Infinity : i;
    }));
    expect(configure, 'the configure call comes before every test').toBeLessThan(firstTest);
    expect(code.slice(0, configure).split('\n').every((line) => !line.startsWith(' ')),
      'the configure call is at the top level').toBe(true);
    // Nothing turns them on again.
    expect(code.match(/retries\s*:/g), 'one retries setting in the file').toHaveLength(1);
    expect(code).not.toMatch(/test\.(describe\.)?configure\(\{[^}]*retries:\s*[1-9]/);
    expect(code).not.toMatch(/\.retry\(|test\.info\(\)\.retry/);
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
  const before = ['Bold off switch', 'Changes: 0'];
  const after = ['Bold on switch', 'Changes: 1'];
  const own = screenStops('good-icon-button');
  const screen = (...content) => [...own, EXAMPLE_HEADING, ...content];
  const cases = [
    ['a correct walk', screen(...before), true, before, 'complete'],
    ['a correct walk after the change', screen(...after), true, after, 'complete'],
    ['a wrong state', screen('Bold on switch', 'Changes: 0'), true, before, 'wrong'],
    ['a wrong role', screen('Bold button', 'Changes: 0'), true, before, 'wrong'],
    ['an empty reading', screen('', 'Changes: 0'), true, before, 'wrong'],
    ['a stale count after the change', screen('Bold on switch', 'Changes: 0'), true, after, 'wrong'],
    ['the expected stops out of order', screen('Changes: 0', 'Bold off switch'), true, before, 'wrong'],
    ['a stop read twice', screen('Bold off switch', 'Bold off switch', 'Changes: 0'), true, before, 'wrong'],
    ['a wrong reading in a truncated walk', screen('Bold button'), false, before, 'wrong'],
    ['an empty walk', [], false, before, 'incomplete'],
    ['a truncated walk', screen('Bold off switch'), false, before, 'incomplete'],
    ['a walk that went past a stop without reading it', screen('Changes: 0'), true, before, 'incomplete'],
    // Walks that did not read the heading: judged after the screen's own stops.
    ['a headingless walk with a wrong state', ['Bold on switch', 'Changes: 0'], true, before, 'wrong'],
    ['a headingless walk with a nameless reading', [...own, 'switch', 'Changes: 0'], true, before, 'wrong'],
    ['a headingless walk with an empty reading', [...own, '', 'Changes: 0'], true, before, 'wrong'],
    ['a headingless walk with a stop that is not the screen\'s', ['Back button'], false, before, 'wrong'],
    ['a headingless walk with a screen stop out of its place', [...own.slice(0, 1), 'Bold off switch', own[1]], false, before, 'wrong'],
    ['a headingless walk of the screen\'s own stops only', [...own], false, before, 'incomplete'],
    ['a headingless walk of the screen\'s stops and a right reading', [...own, 'Bold off switch', 'Changes: 0'], true, before, 'incomplete'],
    ['a headingless walk with a right reading only', ['Bold off switch'], false, before, 'incomplete'],
    ['a stale count in a headingless walk after the change', ['Bold on switch', 'Changes: 0'], true, after, 'wrong'],
    // Found by trying to break the judge: what comes before the heading is
    // checked too.
    ['a wrong reading before the heading', ['Bold on switch', EXAMPLE_HEADING, ...before], true, before, 'wrong'],
    ['the screen\'s own stops out of their order', [own[1], own[0], EXAMPLE_HEADING, ...before], true, before, 'wrong'],
    // WebKit read the screen's level 1 heading as an empty phrase (review
    // round 4): allowed as the first stop only, in a walk that read the
    // "Example" heading.
    ['an empty first stop for the title, then the heading and right readings', ['', ...own.slice(1), EXAMPLE_HEADING, ...before], true, before, 'complete'],
    ['an empty first stop and no heading', ['', ...own.slice(1), ...before], true, before, 'wrong'],
    ['an empty first stop alone', [''], false, before, 'wrong'],
    ['an empty stop after the title', [own[0], '', EXAMPLE_HEADING, ...before], true, before, 'wrong'],
    ['an empty stop just before the heading', [...own, '', EXAMPLE_HEADING, ...before], true, before, 'wrong'],
    ['two empty stops before the heading', ['', '', ...own.slice(1), EXAMPLE_HEADING, ...before], true, before, 'wrong'],
    ['an empty first stop and the title read as well', ['', ...own, EXAMPLE_HEADING, ...before], true, before, 'wrong'],
    ['an empty stop after the heading', screen('', ...before), true, before, 'wrong'],
    ['a stop after the count', screen(...before, 'end of main'), true, before, 'wrong'],
  ];
  for (const [what, stops, reachedEnd, expected, verdict] of cases) {
    test(`${what}: ${verdict}`, () => {
      expect(judgeExampleWalk(stops, reachedEnd, expected, own).verdict).toBe(verdict);
    });
  }

  test('a bad example\'s own stops include its defect', () => {
    const stops = screenStops('bad-no-state');
    expect(judgeExampleWalk(stops, false, ['Mute button', 'Changes: 0'], stops).verdict).toBe('incomplete');
    expect(stops.at(-1)).toMatch(/^Defect: /);
  });

  const judge = (stops, reachedEnd) => judgeExampleWalk(stops, reachedEnd, before, own);
  const sequence = (...list) => {
    let i = 0;
    return { walkOnce: async () => list[i++], made: () => i };
  };
  const right = { stops: screen(...before), reachedEnd: true };
  const wrong = { stops: screen('Bold on switch', 'Changes: 0'), reachedEnd: true };
  const short = { stops: screen('Bold off switch'), reachedEnd: false };
  const headinglessWrong = { stops: ['Bold on switch', 'Changes: 0'], reachedEnd: true };
  const empty = { stops: [], reachedEnd: false };

  test('a wrong walk followed by a right one fails, and no second walk is made', async () => {
    const { walkOnce, made } = sequence(wrong, right);
    expect((await runWalks(walkOnce, judge)).verdict).toBe('wrong');
    expect(made()).toBe(1);
  });

  test('a wrong headingless walk followed by a right one fails, and no second walk is made', async () => {
    const { walkOnce, made } = sequence(headinglessWrong, right);
    expect((await runWalks(walkOnce, judge)).verdict).toBe('wrong');
    expect(made()).toBe(1);
  });

  test('an incomplete walk followed by a right one passes on the second', async () => {
    const { walkOnce, made } = sequence(short, right);
    const result = await runWalks(walkOnce, judge);
    expect(result).toMatchObject({ verdict: 'complete', walks: 2 });
    expect(made()).toBe(2);
  });

  test('an empty walk followed by a right one passes on the second', async () => {
    const { walkOnce } = sequence(empty, right);
    expect(await runWalks(walkOnce, judge)).toMatchObject({ verdict: 'complete', walks: 2 });
  });

  test('every try of an example walk is logged', async () => {
    const { walkOnce } = sequence(short, short, right);
    const logged = [];
    await runWalks(walkOnce, judge, { log: (n, stops, judged) => logged.push([n, judged.verdict]) });
    expect(logged).toEqual([[1, 'incomplete'], [2, 'incomplete'], [3, 'complete']]);
  });
});
