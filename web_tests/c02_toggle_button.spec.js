// L3 for C02 Toggle button on web: what the browser's accessibility tree
// exposes. Spec: docs/specs/C02-toggle-button.md. Runs against the release
// build in build/web.
import { test, expect } from '@playwright/test';
import { byId, tabTo, technique } from './support/techniques.js';
// Pure logic, with no VoiceOver: imported here so that CI tests it.
import fs from 'node:fs';
import { fileURLToPath } from 'node:url';
import { judgeControlWalk, runControlWalks } from './vo/c02_control_html.js';

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
    ['a walk that missed the stop before the buttons', ['', ...good, 'Changes: 0', 'end of main'], true, 'incomplete'],
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
  test('the VoiceOver comparison test is not retried by the runner', () => {
    const source = fs.readFileSync(
      fileURLToPath(new URL('./vo/c02_toggle_button_vo.spec.js', import.meta.url)), 'utf8');
    const block = source.slice(source.indexOf("test.describe('control-html'"));
    expect(block.indexOf("test.describe('control-html'"), 'the comparison test has a describe of its own').toBe(0);
    expect(block.split('\n')[1].trim()).toBe('test.describe.configure({ retries: 0 });');
    expect(block).toContain("test('voiceover reads control-html'");
  });
});
