// L3 for C06 Disclosure on web: what the browser's accessibility tree
// exposes for each control and its panel, and what a click, a click from
// assistive technology, Tab, Enter, and Space do. Spec:
// docs/specs/C06-disclosure.md. Runs against the release build in build/web.
//
// None of the Flutter widgets for a disclosure used here writes
// aria-expanded (FL-264, FL-265, FL-267): every test below that says so is
// written to fail when one does.
// No example has a TestId, so the control is found by its role and name.
import { test, expect } from '@playwright/test';
import { technique } from './support/techniques.js';
import { EXAMPLE_HEADING, EXAMPLE_SCREENS, judgeExampleWalk, runWalks, screenStops } from './vo/c06_vo_walks.js';

const exampleHeading = (page) => page.getByRole('heading', { name: 'Example', exact: true, level: 2 });
const { open, count } = technique('C06', { ready: exampleHeading, settle: 600 });

const TITLE = 'Details';
const PANEL_TEXT = 'Orders ship in two days.';
const PANEL_ACTION = 'Change address';
const ALL = ['good-material', 'bad-expansion-tile', 'bad-expand-icon', 'bad-cupertino-expansion-tile'];
// The values of navigator.platform the tile tests also run with (see
// browserPlatform).
const EMULATED = ['MacIntel', 'Linux x86_64', 'Win32'];

const control = (page) => page.getByRole('button', { name: TITLE, exact: true });

/** What has DOM focus: its accessible name, or "(page)". */
async function focused(page) {
  return page.evaluate(() => {
    const e = document.activeElement;
    if (!e || e === document.body || e.tagName === 'FLUTTER-VIEW') return '(page)';
    return (e.getAttribute('aria-label') || e.textContent || '').trim();
  });
}

/** The name of each stop of `tabs` presses of Tab, from where focus is. */
async function tabStops(page, tabs) {
  const stops = [];
  for (let i = 0; i < tabs; i++) {
    await page.keyboard.press('Tab');
    await page.waitForTimeout(150);
    stops.push(await focused(page));
  }
  return stops;
}

/**
 * One whole cycle of focus: `key` (Tab or Shift+Tab) until Back has had
 * focus twice, at most ten presses, and what has focus after each. It does
 * not stop at the first Back, so a control after Back in the cycle is
 * always visited. Going round, focus can pass through the page itself
 * ("(page)", FL-421). Fails when no whole cycle is made.
 */
async function focusCycle(page, key) {
  const stops = [];
  let backs = 0;
  for (let i = 0; i < 10; i++) {
    await page.keyboard.press(key);
    await page.waitForTimeout(150);
    const name = await focused(page);
    stops.push(name);
    if (name === 'Back' && ++backs === 2) return stops;
  }
  throw new Error(`no whole focus cycle in ten presses of ${key}: ${stops.join(' / ')}`);
}

/** Tab until the element named `name` has focus, at most six times. */
async function tabToName(page, name) {
  for (let i = 0; i < 6; i++) {
    await page.keyboard.press('Tab');
    await page.waitForTimeout(150);
    if ((await focused(page)) === name) return true;
  }
  return false;
}

/** Whether `text` is in the page, as an element's text or in its name. */
async function shown(page, text) {
  return page.locator('flt-semantics-host').evaluate(
    (host, text) => [...host.querySelectorAll('*')].some((e) => (e.getAttribute('aria-label') || '').includes(text) || [...e.childNodes].some((n) => n.nodeType === 3 && n.textContent.includes(text))),
    text,
  );
}

/** The text of every element of the example in DOM order, from the control to the count, the count left out. */
async function reading(page) {
  const texts = await page.locator('flt-semantics-host').evaluate((host) => {
    const out = [];
    for (const e of host.querySelectorAll('*')) {
      const own = [...e.childNodes].filter((n) => n.nodeType === 3).map((n) => n.textContent.trim()).join('');
      const name = e.getAttribute('aria-label') || own;
      if (name) out.push(name);
    }
    return out;
  });
  const start = texts.findIndex((t) => t.startsWith(TITLE));
  const end = texts.findIndex((t) => t.startsWith('Presses: '));
  expect(start, 'the control is in the page').toBeGreaterThanOrEqual(0);
  expect(end, 'the count comes last').toBeGreaterThan(start);
  return texts.slice(start, end);
}

/**
 * Starts recording what Flutter writes to its announcement elements
 * (flt-announcement-polite and -assertive), which it clears after a moment;
 * `heard(page)` returns everything written since.
 */
async function recordAnnouncements(page) {
  await page.evaluate(() => {
    window.__c06heard = [];
    const watch = () => {
      for (const el of document.querySelectorAll('flt-announcement-polite, flt-announcement-assertive')) {
        if (el.__c06watched) continue;
        el.__c06watched = true;
        new MutationObserver(() => {
          const t = el.textContent.trim();
          if (t) window.__c06heard.push(`${el.tagName.toLowerCase()}: ${t}`);
        }).observe(el, { childList: true, characterData: true, subtree: true });
      }
    };
    watch();
    new MutationObserver(watch).observe(document.body, { childList: true, subtree: true });
  });
}
const heard = (page) => page.evaluate(() => window.__c06heard.slice());

/**
 * The tiles' descriptions depend on the platform Flutter's web engine
 * finds, which it takes from the browser's `navigator.platform`
 * (`detectOperatingSystem` in ui_web's browser_detection.dart; source read,
 * as C05's tests found): "Mac…" is macOS, "Linux…" Linux and "Win…"
 * Windows. `ExpansionTile` adds "double tap to expand" or "to collapse"
 * only on iOS and macOS; there `CupertinoExpansionTile` has its only
 * description, and elsewhere none (FL-264, FL-265). Each test reads the
 * platform in the page, as the engine does, and expects what that platform
 * gives; a platform with no branch here (an Android browser) fails. The
 * tile tests also run with `navigator.platform` set before the app starts
 * (EMULATED), so every branch runs on any machine: the real Linux branch is
 * CI's, the real macOS branch a Mac's.
 */
async function emulatePlatform(page, platform) {
  await page.addInitScript((value) => Object.defineProperty(Navigator.prototype, 'platform', { get: () => value }), platform);
}

/** 'apple', 'linux' or 'windows', as Flutter's engine would find it in this page. */
async function browserPlatform(page) {
  const os = await page.evaluate(() => {
    const p = navigator.platform;
    if (p.startsWith('Mac') || /iphone|ipad|ipod/i.test(p)) return 'apple';
    if (navigator.userAgent.includes('Android')) return 'android';
    if (p.startsWith('Linux')) return 'linux';
    if (p.startsWith('Win')) return 'windows';
    return `unknown (${p})`;
  });
  expect(['apple', 'linux', 'windows'], 'a platform these tests have a branch for').toContain(os);
  return os;
}

/**
 * `ExpansionTile`, for `good-material` and `bad-expansion-tile`, which on
 * the web are alike: a button named by its title, with no aria-expanded;
 * its state only in its description, by platform; a click opens it, with
 * the panel straight after it, and a second closes it.
 */
async function expansionTile(page, slug) {
  await open(page, slug);
  const apple = (await browserPlatform(page)) === 'apple';
  const c = control(page);
  await expect(c).toHaveCount(1);
  await expect(c).not.toHaveAttribute('aria-expanded');
  await expect(c).toHaveAccessibleDescription(apple ? 'Collapsed double tap to expand' : 'Collapsed');
  // The control and Back are the page's only buttons; a closed panel is not there.
  await expect(page.getByRole('button')).toHaveCount(2);
  expect(await shown(page, PANEL_TEXT)).toBe(false);
  expect(await reading(page)).toEqual([TITLE]);
  await c.click();
  await expect.poll(() => shown(page, PANEL_TEXT)).toBe(true);
  await expect(c).not.toHaveAttribute('aria-expanded');
  await expect(c).toHaveAccessibleDescription(apple ? 'Expanded double tap to collapse' : 'Expanded');
  expect(await reading(page)).toEqual([TITLE, PANEL_TEXT, PANEL_ACTION]);
  await c.click();
  await expect.poll(() => shown(page, PANEL_TEXT)).toBe(false);
  await expect(c).toHaveAccessibleDescription(apple ? 'Collapsed double tap to expand' : 'Collapsed');
}

test.describe('good-material', () => {
  const slug = 'good-material';

  test('a button with no aria-expanded, the state in its description; a click opens it straight after the control, and a second closes it', async ({ page }) => {
    await expansionTile(page, slug);
  });

  for (const platform of EMULATED) {
    test(`navigator.platform "${platform}": no aria-expanded; the description for that platform`, async ({ page }) => {
      await emulatePlatform(page, platform);
      await expansionTile(page, slug);
    });
  }

  test('a click sent to the element with no pointer events, as assistive technology sends it, opens it', async ({ page }) => {
    await open(page, slug);
    await control(page).evaluate((e) => e.click());
    await expect.poll(() => shown(page, PANEL_TEXT)).toBe(true);
  });

  test('the change is written to the polite announcement element: "Expanded", then "Collapsed"', async ({ page }) => {
    await open(page, slug);
    await recordAnnouncements(page);
    await control(page).click();
    await expect.poll(() => shown(page, PANEL_TEXT)).toBe(true);
    await expect.poll(() => heard(page)).toEqual(['flt-announcement-polite: Expanded']);
    await control(page).click();
    await expect.poll(() => shown(page, PANEL_TEXT)).toBe(false);
    await expect.poll(() => heard(page)).toEqual(['flt-announcement-polite: Expanded', 'flt-announcement-polite: Collapsed']);
  });

  for (const key of ['Enter', 'Space']) {
    test(`Tab reaches it after Back, and ${key} opens and closes it with focus kept on it`, async ({ page }) => {
      await open(page, slug);
      expect(await tabStops(page, 2)).toEqual(['Back', TITLE]);
      await page.keyboard.press(key);
      await expect.poll(() => shown(page, PANEL_TEXT)).toBe(true);
      expect(await focused(page)).toBe(TITLE);
      await page.keyboard.press(key);
      await expect.poll(() => shown(page, PANEL_TEXT)).toBe(false);
      expect(await focused(page)).toBe(TITLE);
    });
  }

  test("open, the next Tab goes to the panel's button, and Enter presses it", async ({ page }) => {
    await open(page, slug);
    expect(await tabToName(page, TITLE)).toBe(true);
    await page.keyboard.press('Enter');
    await expect.poll(() => shown(page, PANEL_TEXT)).toBe(true);
    expect(await tabStops(page, 1)).toEqual([PANEL_ACTION]);
    await page.keyboard.press('Enter');
    await expect(count(page, slug)).toHaveText('Presses: 1');
  });
});

test.describe('bad examples have their defect', () => {
  // The defect, no button role, is on Android and iOS. On the web the
  // control is a button, as any tappable node is (FL-006), and it is read
  // as good-material is.
  test('bad-expansion-tile: on the web the control is a button, as good-material', async ({ page }) => {
    await expansionTile(page, 'bad-expansion-tile');
  });

  for (const platform of EMULATED) {
    test(`bad-expansion-tile, navigator.platform "${platform}": as good-material`, async ({ page }) => {
      await emulatePlatform(page, platform);
      await expansionTile(page, 'bad-expansion-tile');
    });
  }

  for (const platform of [null, ...EMULATED]) {
    test(`bad-expand-icon${platform ? `, navigator.platform "${platform}"` : ''}: a button named by its label, with no aria-expanded and no description, before and after a click opens it`, async ({ page }) => {
      if (platform) await emulatePlatform(page, platform);
      await open(page, 'bad-expand-icon');
      const c = control(page);
      await expect(c).toHaveCount(1);
      await expect(c).not.toHaveAttribute('aria-expanded');
      await expect(c).not.toHaveAttribute('aria-description');
      await expect(c).toHaveAccessibleDescription('');
      await expect(page.getByRole('button')).toHaveCount(2);
      await c.click();
      // The positive control: the click opened it.
      await expect.poll(() => shown(page, PANEL_TEXT)).toBe(true);
      await expect(c).toHaveAccessibleName(TITLE);
      await expect(c).not.toHaveAttribute('aria-expanded');
      await expect(c).not.toHaveAttribute('aria-description');
      await expect(c).toHaveAccessibleDescription('');
      expect(await reading(page)).toEqual([TITLE, PANEL_TEXT, PANEL_ACTION]);
    });
  }

  for (const key of ['Enter', 'Space']) {
    test(`bad-expand-icon: Tab reaches it and ${key} opens it, as on good-material`, async ({ page }) => {
      await open(page, 'bad-expand-icon');
      expect(await tabStops(page, 2)).toEqual(['Back', TITLE]);
      await page.keyboard.press(key);
      await expect.poll(() => shown(page, PANEL_TEXT)).toBe(true);
    });
  }

  // A whole focus cycle, forwards and backwards: every stop in Flutter's
  // tree is Back, and the panel stays closed; then the key, on Back where
  // the cycle ended, leaves the example (the key acted). The same cycle
  // visits good-material's control (the test after these).
  for (const [key, by] of [['Enter', 'Tab'], ['Space', 'Tab'], ['Enter', 'Shift+Tab']]) {
    test(`bad-cupertino-expansion-tile: a whole ${by} cycle stops only on Back, and ${key} there leaves the example`, async ({ page }) => {
      await open(page, 'bad-cupertino-expansion-tile');
      const stops = await focusCycle(page, by);
      const inApp = stops.filter((s) => s !== '(page)');
      expect(inApp, stops.join(' / ')).toEqual(inApp.map(() => 'Back'));
      expect(await shown(page, PANEL_TEXT)).toBe(false);
      expect(await focused(page)).toBe('Back');
      await page.keyboard.press(key);
      await expect(exampleHeading(page)).toHaveCount(0);
      await expect(page).toHaveURL(/#\/t\/C06$/);
    });
  }

  test('good-material: the same whole cycle, Tab and Shift+Tab, visits the control (the positive control)', async ({ page }) => {
    await open(page, 'good-material');
    const forwards = await focusCycle(page, 'Tab');
    expect(forwards, forwards.join(' / ')).toContain(TITLE);
    const backwards = await focusCycle(page, 'Shift+Tab');
    expect(backwards, backwards.join(' / ')).toContain(TITLE);
  });

  for (const platform of [null, ...EMULATED]) {
    test(`bad-cupertino-expansion-tile${platform ? `, navigator.platform "${platform}"` : ''}: no tabindex and no aria-expanded; the description for that platform; a click opens it`, async ({ page }) => {
      if (platform) await emulatePlatform(page, platform);
      await open(page, 'bad-cupertino-expansion-tile');
      const apple = (await browserPlatform(page)) === 'apple';
      const c = control(page);
      await expect(c).toHaveCount(1);
      await expect(c).not.toHaveAttribute('tabindex');
      await expect(c).not.toHaveAttribute('aria-expanded');
      if (apple) {
        await expect(c).toHaveAccessibleDescription('Collapsed double tap to expand');
      } else {
        await expect(c).toHaveAccessibleDescription('');
        await expect(c).not.toHaveAttribute('aria-description');
      }
      await c.click();
      await expect.poll(() => shown(page, PANEL_TEXT)).toBe(true);
      // Open, the control and its panel's text are one button (FL-265),
      // still with no aria-expanded.
      const merged = page.getByRole('button', { name: `${TITLE} ${PANEL_TEXT}`, exact: true });
      await expect(merged).toHaveCount(1);
      await expect(merged).not.toHaveAttribute('aria-expanded');
      await expect(merged).not.toHaveAttribute('tabindex');
      if (apple) {
        await expect(merged).toHaveAccessibleDescription('Expanded double tap to collapse');
      } else {
        await expect(merged).toHaveAccessibleDescription('');
      }
    });
  }
});

// Once a CupertinoExpansionTile has been opened, an empty element the size
// of the view lies over the page and takes pointer events (FL-029, as C05
// found). Written to fail when it goes. The other examples have none.
test.describe('the empty element over the page', () => {
  const fullScreenEmpty = (page) =>
    page.evaluate(() =>
      [...document.querySelectorAll('flt-semantics')].filter((e) => {
        const r = e.getBoundingClientRect();
        return (
          e.childElementCount === 0 &&
          e.textContent === '' &&
          e.attributes.length === 2 && // id and style only
          r.width >= window.innerWidth - 1 &&
          r.height >= window.innerHeight - 1
        );
      }).map((e) => e.style.pointerEvents));
  const exampleHeadingIsHit = (page) =>
    page.evaluate(() => {
      const h = [...document.querySelectorAll('h2')].find((e) => e.textContent === 'Example');
      const r = h.getBoundingClientRect();
      return document.elementFromPoint(r.x + r.width / 2, r.y + r.height / 2) === h;
    });

  for (const slug of ALL) {
    const appears = slug === 'bad-cupertino-expansion-tile';
    test(`${slug}: ${appears ? 'none while closed, one once opened' : 'none, closed or open'}`, async ({ page }) => {
      await open(page, slug);
      expect(await fullScreenEmpty(page)).toEqual([]);
      expect(await exampleHeadingIsHit(page)).toBe(true);
      await control(page).click();
      await expect.poll(() => shown(page, PANEL_TEXT)).toBe(true);
      await page.waitForTimeout(1000);
      expect(await fullScreenEmpty(page)).toEqual(appears ? ['auto'] : []);
      expect(await exampleHeadingIsHit(page)).toBe(!appears);
    });
  }
});

test.describe('the VoiceOver example walks are judged on every walk', () => {
  const expected = ['Details Collapsed double tap to expand button', 'Presses: 0'];
  const own = screenStops('good-material');
  const screen = (...content) => [...own, EXAMPLE_HEADING, ...content];
  const cases = [
    ['a correct walk', screen(...expected), true, 'complete'],
    // A stop read in other words, or out of its place: wrong at once.
    ['a control with no state', screen('Details button', expected[1]), true, 'wrong'],
    ['the stops swapped', screen(expected[1], expected[0]), true, 'wrong'],
    ['an empty reading', screen('', ...expected), true, 'wrong'],
    ['a stop read twice', screen(expected[0], ...expected), true, 'wrong'],
    ['a stop after the count', screen(...expected, 'end of main'), true, 'wrong'],
    ['a wrong reading in a walk cut short', screen('Details'), false, 'wrong'],
    // A walk that reached the end with an expected stop not read: wrong,
    // not a short capture to be walked again.
    ['a walk that reached the end without the control', screen(expected[1]), true, 'wrong'],
    ['a walk that reached the end without the count', screen(expected[0]), true, 'wrong'],
    ['a walk with no title', [own[1], EXAMPLE_HEADING, ...expected], true, 'wrong'],
    ['a walk with no description', [own[0], EXAMPLE_HEADING, ...expected], true, 'wrong'],
    ['a walk with no heading', [...own, ...expected], true, 'wrong'],
    ['a walk of the example alone', [...expected], true, 'wrong'],
    ['a walk that reached the end having read nothing', [], true, 'wrong'],
    ["a walk that reached the end after the screen's own stops", [...own], true, 'wrong'],
    ["the screen's own stops out of their order", [own[1], own[0], EXAMPLE_HEADING, ...expected], true, 'wrong'],
    ["a stop that is not the screen's before the heading", ['Back button', ...own, EXAMPLE_HEADING, ...expected], true, 'wrong'],
    ['an empty first stop for the title', ['', ...own.slice(1), EXAMPLE_HEADING, ...expected], true, 'wrong'],
    ['an empty first stop alone', [''], false, 'wrong'],
    ['an empty stop just before the heading', [...own, '', EXAMPLE_HEADING, ...expected], true, 'wrong'],
    // Cut short before the end, with every stop right so far: may be walked
    // again.
    ['an empty walk cut short', [], false, 'incomplete'],
    ['a walk cut short after the title', [own[0]], false, 'incomplete'],
    ['a walk cut short after the heading', [...own, EXAMPLE_HEADING], false, 'incomplete'],
    ['a walk cut short after the control', screen(expected[0]), false, 'incomplete'],
    ['every stop read, but the end not reached', screen(...expected), false, 'incomplete'],
  ];
  for (const [what, stops, reachedEnd, verdict] of cases) {
    test(`${what}: ${verdict}`, () => {
      expect(judgeExampleWalk(stops, reachedEnd, expected, own).verdict).toBe(verdict);
    });
  }

  test("a bad example's own stops include its defect", () => {
    for (const slug of ALL.filter((s) => s.startsWith('bad-'))) {
      expect(screenStops(slug).at(-1)).toMatch(/^Defect: /);
    }
    expect(screenStops('good-material')).toHaveLength(2);
  });

  const judge = (stops, reachedEnd) => judgeExampleWalk(stops, reachedEnd, expected, own);
  const sequence = (...list) => {
    let i = 0;
    return { walkOnce: async () => list[i++], made: () => i };
  };
  const right = { stops: screen(...expected), reachedEnd: true };
  const short = { stops: screen(expected[0]), reachedEnd: false };

  for (const [what, walk] of [
    ['a wrong reading', { stops: screen('Details button', expected[1]), reachedEnd: true }],
    ['a walk that reached the end without the count', { stops: screen(expected[0]), reachedEnd: true }],
    ['a walk with no title', { stops: [own[1], EXAMPLE_HEADING, ...expected], reachedEnd: true }],
    ['a walk with no heading', { stops: [...own, ...expected], reachedEnd: true }],
  ]) {
    test(`${what} followed by a right walk fails, and no second walk is made`, async () => {
      const { walkOnce, made } = sequence(walk, right);
      expect((await runWalks(walkOnce, judge)).verdict).toBe('wrong');
      expect(made()).toBe(1);
    });
  }

  test('a wrong walk after a short one still fails, and no third walk is made', async () => {
    const { walkOnce, made } = sequence(short, { stops: screen(expected[0]), reachedEnd: true }, right);
    expect((await runWalks(walkOnce, judge)).verdict).toBe('wrong');
    expect(made()).toBe(2);
  });

  test('an empty walk cut short, followed by a right one, passes on the second', async () => {
    const { walkOnce } = sequence({ stops: [], reachedEnd: false }, right);
    expect(await runWalks(walkOnce, judge)).toMatchObject({ verdict: 'complete', walks: 2 });
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

  for (const [slug, [title, ...rest]] of Object.entries(EXAMPLE_SCREENS)) {
    test(`${slug}: the screen shows the texts the VoiceOver judge expects`, async ({ page }) => {
      await open(page, slug);
      await expect(page.getByRole('heading', { name: title, exact: true, level: 1 })).toHaveCount(1);
      for (const text of rest) await expect(page.getByText(text, { exact: true })).toHaveCount(1);
    });
  }
});
