// L3 for I03 Focus management on web: where keyboard focus goes, read from
// document.activeElement, when the question opens and closes, when the
// button that had focus is removed, and that focus alone opens nothing.
// Spec: docs/specs/I03-focus-management.md. Runs against the release build
// in build/web.
import { test, expect } from '@playwright/test';
import { byId, technique } from './support/techniques.js';

const { open, expectCount } = technique('I03', { countLabel: 'Saved' });

const good = ['good-material', 'good-cupertino', 'good-widgets'];
const all = [...good, 'bad-focus-left-behind', 'bad-opens-on-focus'];
// The examples whose question is opened by pressing a Remove button.
const pressToAsk = [...good, 'bad-focus-left-behind'];
const names = {
  'remove-ridge': 'Remove Ridge trail',
  'remove-lake': 'Remove Lake loop',
  'remove-summit': 'Remove Summit path',
};

const control = (page, slug, part) => byId(page, `i03-${slug}-${part}`);
const question = (page, name) => page.getByText(`Remove ${name}?`, { exact: true });

/**
 * Names the element that has DOM focus: 'back', a part of the example
 * ('remove-lake', 'cancel', ...), 'outside' when focus is on no element
 * of the page's content (the body, or the Flutter view itself), or a
 * description of anything else.
 */
const stop = (page, slug) => page.evaluate((prefix) => {
  const e = document.activeElement;
  if (!e || e === document.body || e.tagName === 'FLUTTER-VIEW') return 'outside';
  const owner = e.closest('[flt-semantics-identifier]');
  const id = owner?.getAttribute('flt-semantics-identifier');
  if (id && id.startsWith(prefix)) return id.slice(prefix.length);
  if (e.getAttribute('role') === 'button' && e.textContent.trim() === 'Back') return 'back';
  return `other: ${e.tagName} ${e.getAttribute('role') ?? ''} ${e.textContent.trim().slice(0, 30)}`;
}, `i03-${slug}-`);

async function press(page, key) {
  await page.keyboard.press(key);
  // Flutter moves DOM focus on the next frame; a route takes longer.
  await page.waitForTimeout(400);
}

/** Presses Tab `n` times and names the stop after each. */
async function tabs(page, slug, n, key = 'Tab') {
  const stops = [];
  for (let i = 0; i < n; i++) {
    await press(page, key);
    stops.push(await stop(page, slug));
  }
  return stops;
}

/** From the screen as it opens: Back, Remove Ridge trail, Remove Lake loop. */
async function tabToLake(page, slug) {
  expect(await tabs(page, slug, 3)).toEqual(['back', 'remove-ridge', 'remove-lake']);
}

/** Tabs to `part` of the question, at most four times. */
async function tabInQuestionTo(page, slug, part) {
  for (let i = 0; i < 4 && (await stop(page, slug)) !== part; i++) await press(page, 'Tab');
  expect(await stop(page, slug)).toBe(part);
}

test.describe('every example', () => {
  for (const slug of all) {
    test(`${slug}: three Remove buttons, named, and in the Tab order`, async ({ page }) => {
      await open(page, slug);
      for (const [part, name] of Object.entries(names)) {
        const element = control(page, slug, part);
        await expect(element, part).toHaveRole('button');
        await expect(element, part).toHaveAccessibleName(name);
        await expect(element, part).toHaveAttribute('tabindex', '0');
      }
      await expectCount(page, slug, 3);
    });
  }
});

test.describe('the question opens on a press, not on focus (3.2.1)', () => {
  for (const slug of pressToAsk) {
    test(`${slug}: Tab onto each Remove button asks nothing; Enter on one asks`, async ({ page }) => {
      await open(page, slug);
      expect(await tabs(page, slug, 4)).toEqual(['back', 'remove-ridge', 'remove-lake', 'remove-summit']);
      await expect(page.getByText(/\?$/)).toHaveCount(0);
      // The positive control: Enter on the button Tab reached asks.
      await press(page, 'Enter');
      await expect(question(page, 'Summit path')).toBeVisible();
    });
  }

  // The defect. Written to fail when focus no longer opens the question.
  test('bad-opens-on-focus: Tab onto Remove Ridge trail asks at once', async ({ page }) => {
    const slug = 'bad-opens-on-focus';
    await open(page, slug);
    // Tab reaches Back and asks nothing: the key arrives.
    expect(await tabs(page, slug, 1)).toEqual(['back']);
    await expect(page.getByText(/\?$/)).toHaveCount(0);
    // The next Tab alone, onto Remove Ridge trail, asks.
    await press(page, 'Tab');
    await expect(question(page, 'Ridge trail')).toBeVisible();
    // Cancel goes back to the button, which does not ask again, and Tab to
    // the next button asks about it.
    await tabInQuestionTo(page, slug, 'cancel');
    await press(page, 'Enter');
    await expect(question(page, 'Ridge trail')).toHaveCount(0);
    expect(await stop(page, slug)).toBe('remove-ridge');
    await press(page, 'Tab');
    await expect(question(page, 'Lake loop')).toBeVisible();
  });

  // On the web, focus given to the element by anything, as VoiceOver's
  // cursor gives it, opens the question as well.
  test('bad-opens-on-focus: DOM focus on Remove Lake loop asks', async ({ page }) => {
    const slug = 'bad-opens-on-focus';
    await open(page, slug);
    await control(page, slug, 'remove-lake').focus();
    await expect(question(page, 'Lake loop')).toBeVisible();
  });
});

test.describe('focus goes into the question when it opens (2.4.3)', () => {
  // Enter on Remove Lake loop. Where DOM focus is then, and the next Tab.
  // The Material dialog and the action sheet leave Flutter's keyboard
  // focus on their own scope. For the dialog the web engine then puts DOM
  // focus on its first element, the title (read in the source:
  // SemanticRouteBase._setDefaultFocus); for the action sheet it puts it
  // nowhere, and the Flutter view keeps it. In both the next Tab is the
  // first control of the question. The general dialog puts focus on
  // Cancel.
  const opens = {
    'good-material': ['title', 'cancel'],
    'good-cupertino': ['outside', 'confirm'],
    'good-widgets': ['cancel', 'confirm'],
  };
  for (const [slug, [first, next]] of Object.entries(opens)) {
    test(`${slug}: Enter on Remove Lake loop puts focus in the question`, async ({ page }) => {
      await open(page, slug);
      await tabToLake(page, slug);
      await press(page, 'Enter');
      await expect(question(page, 'Lake loop')).toBeVisible();
      const where = await stop(page, slug);
      if (first === 'title') {
        expect(where).toMatch(/^other: .*Remove Lake loop\?/);
      } else {
        expect(where).toBe(first);
      }
      expect(await tabs(page, slug, 1)).toEqual([next]);
    });
  }

  // The defect. Flutter's keyboard focus stays on Remove Lake loop behind
  // the question; the button is out of the document while the question is
  // up, so the stop is named by what Enter does there. Written to fail when
  // the question starts to take focus.
  test('bad-focus-left-behind: the first Tab goes to Remove Summit path behind the question', async ({ page }) => {
    const slug = 'bad-focus-left-behind';
    await open(page, slug);
    await tabToLake(page, slug);
    await press(page, 'Enter');
    await expect(question(page, 'Lake loop')).toBeVisible();
    await expect(control(page, slug, 'remove-summit')).toHaveCount(0);
    await press(page, 'Tab');
    // No control of the question has focus ...
    expect(['cancel', 'confirm']).not.toContain(await stop(page, slug));
    // ... and Enter asks about Summit path: focus was on its button.
    await press(page, 'Enter');
    await expect(question(page, 'Summit path')).toBeVisible();
  });

  test('bad-focus-left-behind: the question\'s buttons come only after the screen\'s last control', async ({ page }) => {
    const slug = 'bad-focus-left-behind';
    await open(page, slug);
    await tabToLake(page, slug);
    await press(page, 'Enter');
    // Remove Summit path, behind the question and out of the document,
    // then Cancel.
    const stops = await tabs(page, slug, 2);
    expect(stops[0]).not.toBe('cancel');
    expect(stops[1]).toBe('cancel');
  });
});

test.describe('focus comes back when the question closes (2.4.3)', () => {
  for (const slug of good) {
    test(`${slug}: Cancel puts focus back on Remove Lake loop, and Tab goes on from there`, async ({ page }) => {
      await open(page, slug);
      await tabToLake(page, slug);
      await press(page, 'Enter');
      await tabInQuestionTo(page, slug, 'cancel');
      await press(page, 'Enter');
      await expect(question(page, 'Lake loop')).toHaveCount(0);
      expect(await stop(page, slug)).toBe('remove-lake');
      expect(await tabs(page, slug, 1)).toEqual(['remove-summit']);
    });

    test(`${slug}: Remove puts focus on Remove Summit path`, async ({ page }) => {
      await open(page, slug);
      await tabToLake(page, slug);
      await press(page, 'Enter');
      await tabInQuestionTo(page, slug, 'confirm');
      await press(page, 'Enter');
      await expect(control(page, slug, 'remove-lake')).toHaveCount(0);
      await expectCount(page, slug, 2);
      expect(await stop(page, slug)).toBe('remove-summit');
      expect(await tabs(page, slug, 1, 'Shift+Tab')).toEqual(['remove-ridge']);
    });

    // As VoiceOver does it: DOM focus on the element, then a click.
    test(`${slug}: focus and a click, as VoiceOver gives them, bring focus back and on`, async ({ page }) => {
      await open(page, slug);
      const act = async (part) => {
        await control(page, slug, part).focus();
        await page.waitForTimeout(300);
        await control(page, slug, part).click();
        await page.waitForTimeout(1200);
      };
      await act('remove-lake');
      await act('cancel');
      expect(await stop(page, slug)).toBe('remove-lake');
      await act('remove-lake');
      await act('confirm');
      await expectCount(page, slug, 2);
      expect(await stop(page, slug)).toBe('remove-summit');
    });
  }

  // The same defect on the way out: reaching Cancel took Tab past the end
  // of the screen, which clears the screen's record of its focus, so focus
  // does not come back to Remove Lake loop. Flutter's focus is on the
  // screen and on no control; the web engine, finding no element that
  // asks for focus when the screen's elements come back, puts DOM focus on
  // the first, Back (SemanticRouteBase._setDefaultFocus, read in the
  // source). The next Tab is Flutter's first stop, Back, and the one after
  // it Remove Ridge trail: the order starts again from the top. Written to
  // fail when focus comes back to Remove Lake loop.
  test('bad-focus-left-behind: after Cancel focus is at the top of the screen, and Tab starts again at Back', async ({ page }) => {
    const slug = 'bad-focus-left-behind';
    await open(page, slug);
    await tabToLake(page, slug);
    await press(page, 'Enter');
    await tabInQuestionTo(page, slug, 'cancel');
    await press(page, 'Enter');
    await expect(question(page, 'Lake loop')).toHaveCount(0);
    expect(await stop(page, slug)).toBe('back');
    expect(await tabs(page, slug, 2)).toEqual(['back', 'remove-ridge']);
  });
});
