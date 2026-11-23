// L3 for C13 Snackbar and transient messages on web: what the browser's
// accessibility tree exposes for each example's message once shown, what
// Flutter gives the page's announcement elements, where keyboard focus is
// and goes, and how long each message stays. Spec: docs/specs/C13-snackbar.md.
// Runs against the release build in build/web.
//
// Flutter writes an announcement to flt-announcement-polite or -assertive
// and empties it 300 ms later (FL-012), so everything written there is
// recorded with a MutationObserver from before the press. Every check that
// a key or an action did nothing sends it alone, and shows in the same load
// that the same path acts.
import { test, expect } from '@playwright/test';
import { byId, openExample } from './support/techniques.js';
import {
  EXAMPLE_HEADING, EXAMPLE_SCREENS, judgeWalk, runWalks, screenStops, shownWalk,
} from './vo/c13_vo_walks.js';

const MESSAGE = {
  'good-action': 'Message archived',
  'good-message': 'Draft saved',
  'good-banner': 'You are offline.',
  'bad-action-times-out': 'Message archived',
  'bad-only-in-message': 'Booked. Code: K7Q2',
  'bad-inline-banner': 'You are offline.',
};
const LINE = {
  'good-action': ['Archived: 0', 'Archived: 1'],
  'good-message': ['Drafts saved: 0', 'Drafts saved: 1'],
  'good-banner': ['Status: online', 'Status: offline'],
  'bad-action-times-out': ['Archived: 0', 'Archived: 1'],
  'bad-only-in-message': ['Bookings: 0', 'Bookings: 1'],
  'bad-inline-banner': ['Status: online', 'Status: offline'],
};
const BUTTON = {
  'good-action': 'Archive message',
  'good-message': 'Save draft',
  'good-banner': 'Go offline',
  'bad-action-times-out': 'Archive message',
  'bad-only-in-message': 'Book a table',
  'bad-inline-banner': 'Go offline',
};

const show = (page, slug) => byId(page, `c13-${slug}-show`);
const line = (page, slug) => byId(page, `c13-${slug}-count`);

/** Opens an example, waits for its opening announcements to pass, and records every later one. */
async function open(page, slug) {
  await openExample(page, 'C13', slug, show(page, slug), { settle: 900 });
  await page.evaluate(() => {
    window.announced = [];
    for (const politeness of ['polite', 'assertive']) {
      const element = document.querySelector(`flt-announcement-${politeness}`);
      new MutationObserver(() => {
        const text = element.textContent.replace(/ /g, ' ').trim();
        if (text) window.announced.push(`${politeness}: ${text}`);
      }).observe(element, { childList: true, characterData: true, subtree: true });
    }
  });
}

const announced = (page) => page.evaluate(() => window.announced);

/** What has DOM focus: its role and its accessible name, as "button Undo". */
const focusName = (page) => page.evaluate(() => {
  const e = document.activeElement;
  if (!e || e === document.body) return '(body)';
  const role = e.getAttribute('role') ?? e.tagName.toLowerCase();
  return `${role} ${(e.getAttribute('aria-label') ?? e.textContent ?? '').trim()}`;
});

/** Tabs until the button named `name` has focus, at most eight times. */
async function tabToButton(page, name) {
  for (let i = 0; i < 8; i++) {
    if ((await focusName(page)) === `button ${name}`) return;
    await page.keyboard.press('Tab');
    await page.waitForTimeout(150);
  }
  expect(await focusName(page)).toBe(`button ${name}`);
}

/** Shows the message from the keyboard, as a keyboard user does. */
async function pressByKeyboard(page, slug) {
  await tabToButton(page, BUTTON[slug]);
  await page.keyboard.press('Enter');
  await expect(line(page, slug)).toHaveText(LINE[slug][1]);
}

/** Whether the message is in the page: as a group's name or as text. */
const shownIn = (page, slug) => page.evaluate((text) => [...document.querySelectorAll('flt-semantics')].some(
  (e) => e.getAttribute('aria-label') === text || (!e.querySelector('flt-semantics') && e.textContent.trim() === text),
), MESSAGE[slug]);

/** Waits until the message is gone, at most `max` ms; the time it took, or null. */
async function goneAfter(page, slug, max = 12000) {
  const start = Date.now();
  while (Date.now() - start < max) {
    if (!(await shownIn(page, slug))) return Date.now() - start;
    await page.waitForTimeout(100);
  }
  return null;
}

test.describe('good examples', () => {
  for (const slug of ['good-action', 'good-message', 'good-banner']) {
    test(`${slug}: the message is announced politely, once, and focus stays on the button`, async ({ page }) => {
      await open(page, slug);
      await pressByKeyboard(page, slug);
      await expect.poll(() => announced(page)).toEqual([`polite: ${MESSAGE[slug]}`]);
      await page.waitForTimeout(1500);
      expect(await announced(page)).toEqual([`polite: ${MESSAGE[slug]}`]);
      expect(await focusName(page)).toBe(`button ${BUTTON[slug]}`);
    });
  }

  test('good-action: the message is a group named by it, holding Undo and Close', async ({ page }) => {
    await open(page, 'good-action');
    await pressByKeyboard(page, 'good-action');
    const group = page.getByRole('group', { name: 'Message archived', exact: true });
    await expect(group).toHaveCount(1);
    await expect(group.getByRole('button')).toHaveCount(2);
    await expect(group.getByRole('button', { name: 'Undo', exact: true })).toHaveCount(1);
    await expect(group.getByRole('button', { name: 'Close', exact: true })).toHaveCount(1);
  });

  test('good-message: the message is text on its own, with no control', async ({ page }) => {
    await open(page, 'good-message');
    await pressByKeyboard(page, 'good-message');
    await expect(page.locator('flt-semantics-host').getByText('Draft saved', { exact: true })).toHaveCount(1);
    await expect(page.getByRole('button')).toHaveCount(2); // Back and Save draft
  });

  test('good-banner: the banner is a group named by it, holding Go online, above the page', async ({ page }) => {
    await open(page, 'good-banner');
    await pressByKeyboard(page, 'good-banner');
    const group = page.getByRole('group', { name: 'You are offline.', exact: true });
    await expect(group).toHaveCount(1);
    await expect(group.getByRole('button')).toHaveCount(1);
    await expect(group.getByRole('button', { name: 'Go online', exact: true })).toHaveCount(1);
  });

  // FL-249: Close is an IconButton whose tooltip is "Close". With keyboard
  // focus alone it is named "Close"; with the pointer on it the tooltip is
  // shown, its text is an element the button owns, and the button is named
  // "Close Close". Each is read in the same load.
  test('good-action: Close is named "Close" with keyboard focus, and "Close Close" while the pointer shows its tooltip', async ({ page }) => {
    await open(page, 'good-action');
    await pressByKeyboard(page, 'good-action');
    await tabToButton(page, 'Close');
    await page.waitForTimeout(1500);
    const close = page.locator('flt-semantics[role="button"]', { hasText: /^Close$/ });
    await expect(close).toHaveCount(1);
    await expect(close).toHaveAccessibleName('Close');
    await expect(close).not.toHaveAttribute('aria-owns');
    const box = await close.boundingBox();
    await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
    await expect(close).toHaveAttribute('aria-owns', /.+/);
    await expect(close).toHaveAccessibleName('Close Close');
    await expect(close).toHaveRole('button');
  });

  test('good-action: after the show, Tab goes on to Undo, then Close', async ({ page }) => {
    await open(page, 'good-action');
    await pressByKeyboard(page, 'good-action');
    const stops = [];
    for (let i = 0; i < 2; i++) {
      await page.keyboard.press('Tab');
      await page.waitForTimeout(150);
      stops.push(await focusName(page));
    }
    expect(stops).toEqual(['button Undo', 'button Close']);
  });

  test('good-banner: the banner\'s Go online is the Tab stop after Back, before the page\'s button', async ({ page }) => {
    await open(page, 'good-banner');
    await pressByKeyboard(page, 'good-banner');
    await page.getByRole('button', { name: 'Back' }).focus();
    await page.keyboard.press('Tab');
    await page.waitForTimeout(150);
    expect(await focusName(page)).toBe('button Go online');
    await page.keyboard.press('Tab');
    await page.waitForTimeout(150);
    expect(await focusName(page)).toBe('button Go offline');
  });

  for (const key of ['Enter', 'Space']) {
    test(`good-action: ${key} on Undo undoes and takes the message away`, async ({ page }) => {
      await open(page, 'good-action');
      await pressByKeyboard(page, 'good-action');
      await tabToButton(page, 'Undo');
      await page.keyboard.press(key === 'Space' ? ' ' : 'Enter');
      await expect(line(page, 'good-action')).toHaveText('Archived: 0');
      expect(await goneAfter(page, 'good-action', 3000)).not.toBeNull();
    });
  }

  test('good-action: Enter on Close takes the message away and undoes nothing', async ({ page }) => {
    await open(page, 'good-action');
    await pressByKeyboard(page, 'good-action');
    await tabToButton(page, 'Close');
    await page.keyboard.press('Enter');
    expect(await goneAfter(page, 'good-action', 3000)).not.toBeNull();
    await expect(line(page, 'good-action')).toHaveText('Archived: 1');
  });

  for (const [slug, action] of [['good-action', 'Undo'], ['good-banner', 'Go online']]) {
    test(`${slug}: the message stays 10 s, with focus on ${action} and with focus elsewhere`, async ({ page }) => {
      await open(page, slug);
      await pressByKeyboard(page, slug);
      expect(await goneAfter(page, slug, 10000)).toBeNull();
      await tabToButton(page, action);
      expect(await goneAfter(page, slug, 5000)).toBeNull();
    });

    // FL-291: Escape closes no message.
    test(`${slug}: Escape with focus on ${action} leaves the message; Enter there, in the same load, acts`, async ({ page }) => {
      await open(page, slug);
      await pressByKeyboard(page, slug);
      await tabToButton(page, action);
      await page.keyboard.press('Escape');
      await page.waitForTimeout(1000);
      expect(await shownIn(page, slug)).toBe(true);
      expect(await focusName(page)).toBe(`button ${action}`);
      await expect(line(page, slug)).toHaveText(LINE[slug][1]);
      await page.keyboard.press('Enter');
      await expect(line(page, slug)).toHaveText(LINE[slug][0]);
      expect(await goneAfter(page, slug, 3000)).not.toBeNull();
    });
  }

  test('good-message: the message goes after about 4 s, and what it said stays on the page', async ({ page }) => {
    await open(page, 'good-message');
    await pressByKeyboard(page, 'good-message');
    const gone = await goneAfter(page, 'good-message');
    expect(gone).not.toBeNull();
    expect(gone).toBeGreaterThan(2000);
    expect(gone).toBeLessThan(6000);
    await expect(line(page, 'good-message')).toHaveText('Drafts saved: 1');
  });
});

test.describe('bad examples have their defect', () => {
  test('bad-action-times-out: Undo is announced with the message and goes with it after about 4 s', async ({ page }) => {
    await open(page, 'bad-action-times-out');
    await pressByKeyboard(page, 'bad-action-times-out');
    await expect.poll(() => announced(page)).toEqual(['polite: Message archived']);
    await expect(page.getByRole('button', { name: 'Undo', exact: true })).toHaveCount(1);
    const gone = await goneAfter(page, 'bad-action-times-out');
    expect(gone).not.toBeNull();
    expect(gone).toBeLessThan(6000);
    await expect(page.getByRole('button', { name: 'Undo', exact: true })).toHaveCount(0);
    await expect(line(page, 'bad-action-times-out')).toHaveText('Archived: 1');
  });

  // FL-292 on the web: DOM focus goes back to the button that showed the
  // message, and the next Tab leaves Flutter's controls.
  test('bad-action-times-out: with focus on Undo it still goes; focus is then on the page\'s button', async ({ page }) => {
    await open(page, 'bad-action-times-out');
    await pressByKeyboard(page, 'bad-action-times-out');
    await tabToButton(page, 'Undo');
    const gone = await goneAfter(page, 'bad-action-times-out');
    expect(gone).not.toBeNull();
    expect(gone).toBeLessThan(6000);
    await page.waitForTimeout(500);
    expect(await focusName(page)).toBe('button Archive message');
  });

  test('bad-only-in-message: the code is announced, goes after about 4 s, and is nowhere else', async ({ page }) => {
    await open(page, 'bad-only-in-message');
    await expect(page.locator('flt-semantics-host')).not.toContainText('K7Q2');
    await pressByKeyboard(page, 'bad-only-in-message');
    await expect.poll(() => announced(page)).toEqual(['polite: Booked. Code: K7Q2']);
    const gone = await goneAfter(page, 'bad-only-in-message');
    expect(gone).not.toBeNull();
    expect(gone).toBeLessThan(6000);
    await expect(page.locator('flt-semantics-host')).not.toContainText('K7Q2');
    expect(await page.evaluate(() => [...document.querySelectorAll('[aria-label]')].some((e) => e.getAttribute('aria-label').includes('K7Q2')))).toBe(false);
  });

  test('bad-inline-banner: nothing is announced (FL-295); then Go online\'s SnackBar, in the same document, is, by the same recorder', async ({ page }) => {
    await open(page, 'bad-inline-banner');
    await pressByKeyboard(page, 'bad-inline-banner');
    await expect(page.locator('flt-semantics-host').getByText('You are offline.', { exact: false })).toHaveCount(1);
    // The buffer the silence is read from is marked, so that the control
    // below can show it is the same one, in the same document.
    await page.evaluate(() => { window.announced.mark = 'silence'; });
    await page.waitForTimeout(1500);
    expect(await announced(page)).toEqual([]);
    await expect(page.locator('flt-semantics-host [aria-live]')).toHaveCount(0);
    // The positive control: no reload, the same MutationObserver and the
    // same buffer. Go online shows a SnackBar, which the recorder must hear.
    await tabToButton(page, 'Go online');
    await page.keyboard.press('Enter');
    await expect(line(page, 'bad-inline-banner')).toHaveText('Status: online');
    await expect.poll(() => announced(page)).toEqual(['polite: You are online.']);
    // The same buffer the silence was read from.
    expect(await page.evaluate(() => window.announced.mark)).toBe('silence');
  });
});

// What an action did, back on the page's line, is told by a SnackBar of its
// own: the line's change alone writes nothing to the announcement elements.
test.describe('what an action did is announced', () => {
  for (const [slug, action, said, back] of [
    ['good-action', 'Undo', 'Archive undone', 'Archived: 0'],
    ['good-banner', 'Go online', 'You are online.', 'Status: online'],
    ['bad-action-times-out', 'Undo', 'Archive undone', 'Archived: 0'],
  ]) {
    test(`${slug}: ${action} is announced "${said}", after the message, and the line changes`, async ({ page }) => {
      await open(page, slug);
      await pressByKeyboard(page, slug);
      await expect.poll(() => announced(page)).toEqual([`polite: ${MESSAGE[slug]}`]);
      await tabToButton(page, action);
      await page.keyboard.press('Enter');
      await expect(line(page, slug)).toHaveText(back);
      await expect.poll(() => announced(page)).toEqual([`polite: ${MESSAGE[slug]}`, `polite: ${said}`]);
      await page.waitForTimeout(1500);
      expect(await announced(page)).toEqual([`polite: ${MESSAGE[slug]}`, `polite: ${said}`]);
      await expect(line(page, slug)).not.toHaveAttribute('aria-live');
    });
  }
});

// The VoiceOver spec takes these texts as the stops above each example's
// "Example" heading (EXAMPLE_SCREENS). Each screen must show them, so that
// a change to a title or a defect is caught here.
test.describe('the stops the VoiceOver spec expects above each example', () => {
  for (const [slug, [title, ...lines]] of Object.entries(EXAMPLE_SCREENS)) {
    test(`${slug} shows its title and its lines`, async ({ page }) => {
      await open(page, slug);
      await expect(page.getByRole('heading', { level: 1, name: title, exact: true })).toHaveCount(1);
      for (const text of lines) {
        await expect(page.locator('flt-semantics-host').getByText(text, { exact: true })).toHaveCount(1);
      }
    });
  }
});

// How the web VoiceOver spec judges one walk (judgeWalk) and repeats one
// that fell short (runWalks). The walks here are made up; VoiceOver is not
// used.
test.describe('the VoiceOver walks are judged on every walk', () => {
  const whole = shownWalk('good-action', 'webkit');
  const own = screenStops('good-action');
  const cases = [
    ['a correct walk', whole, true, 'complete'],
    ['the message not read', whole.filter((s) => !s.startsWith('Message archived')), true, 'wrong'],
    ['Undo not read', whole.filter((s) => s !== 'Undo button'), true, 'wrong'],
    ['Close not read', whole.filter((s) => s !== 'Close button'), true, 'wrong'],
    ['Undo and Close swapped', whole.map((s) => (s === 'Undo button' ? 'Close button' : s === 'Close button' ? 'Undo button' : s)), true, 'wrong'],
    ['a stop read in other words', whole.map((s) => (s === 'Undo button' ? 'Undo' : s)), true, 'wrong'],
    ['an empty reading', ['', ...whole], true, 'wrong'],
    ['a stop read twice', [...whole.slice(0, 4), whole[3], ...whole.slice(4)], true, 'wrong'],
    ['a stop after the end', [...whole, 'end of main'], true, 'wrong'],
    ['a walk that reached the end before the message', whole.slice(0, 5), true, 'wrong'],
    ['a walk with no title', whole.slice(1), true, 'wrong'],
    ['a walk with no heading', whole.filter((s) => s !== EXAMPLE_HEADING), true, 'wrong'],
    ['a walk that reached the end having read nothing', [], true, 'wrong'],
    ['a wrong reading in a walk cut short', [own[0], 'Good example'], false, 'wrong'],
    ['an empty first stop', ['', ...whole.slice(1)], true, 'wrong'],
    ['an empty walk cut short', [], false, 'incomplete'],
    ['a walk cut short after the heading', [...own, EXAMPLE_HEADING], false, 'incomplete'],
    ['every stop read, but the end not reached', whole, false, 'incomplete'],
  ];
  for (const [what, stops, reachedEnd, verdict] of cases) {
    test(`${what}: ${verdict}`, () => {
      expect(judgeWalk(stops, reachedEnd, whole).verdict).toBe(verdict);
    });
  }

  test('the two browsers\' lists differ at Close alone, each exact', () => {
    const chromium = shownWalk('good-action', 'chromium');
    const webkit = shownWalk('good-action', 'webkit');
    expect(chromium.length).toBe(webkit.length);
    const differ = chromium.map((s, i) => (s === webkit[i] ? null : [s, webkit[i]])).filter(Boolean);
    expect(differ).toEqual([['Close Close', 'Close button']]);
    expect(shownWalk('good-banner', 'chromium')).toEqual(shownWalk('good-banner', 'webkit'));
    // Each is judged exactly: the other browser's reading of Close is wrong.
    expect(judgeWalk(webkit, true, chromium).verdict).toBe('wrong');
    expect(judgeWalk(chromium, true, webkit).verdict).toBe('wrong');
    expect(() => shownWalk('good-action', 'firefox')).toThrow();
  });

  test('the banner\'s walk has the banner before the screen\'s description', () => {
    const banner = shownWalk('good-banner', 'chromium');
    expect(banner.indexOf('Go online button')).toBeLessThan(banner.indexOf(screenStops('good-banner')[1]));
  });

  const judge = (stops, reachedEnd) => judgeWalk(stops, reachedEnd, whole);
  const sequence = (...list) => {
    let i = 0;
    return { walkOnce: async () => list[i++], made: () => i };
  };
  const right = { stops: whole, reachedEnd: true };
  const short = { stops: whole.slice(0, 3), reachedEnd: false };

  test('a wrong walk followed by a right one fails, and no second walk is made', async () => {
    const { walkOnce, made } = sequence({ stops: whole.slice(0, 5), reachedEnd: true }, right);
    expect((await runWalks(walkOnce, judge)).verdict).toBe('wrong');
    expect(made()).toBe(1);
  });

  test('a wrong walk after a short one still fails, and no third walk is made', async () => {
    const { walkOnce, made } = sequence(short, { stops: whole.slice(1), reachedEnd: true }, right);
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

  test('every try is logged', async () => {
    const { walkOnce } = sequence(short, short, right);
    const logged = [];
    await runWalks(walkOnce, judge, { log: (n, stops, judged) => logged.push([n, judged.verdict]) });
    expect(logged).toEqual([[1, 'incomplete'], [2, 'incomplete'], [3, 'complete']]);
  });
});
