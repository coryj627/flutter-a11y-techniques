// L3 for C04 Links inline with text on web: what the browser's
// accessibility tree exposes for links inside a sentence, and what a click,
// the keys, and a click from assistive technology do. Spec:
// docs/specs/C04-links-inline-with-text.md. Runs against the release build
// in build/web.
//
// Each sentence has two links, to C04's own page and to C03's. On the web
// the good links are <a href> and the browser follows them; the app does not
// (FL-013). "Followed once" is checked by the app's Back button: one press
// must bring the example back.
//
// The colour and underline of a link are drawn on Flutter's canvas, not in
// the page, so this layer cannot see bad-colour-only's defect; the widget
// tests assert it.
import { test, expect } from '@playwright/test';
import { byId, tabTo, technique } from './support/techniques.js';

const exampleHeading = (page) => page.getByRole('heading', { name: 'Example', exact: true, level: 2 });
const { open } = technique('C04', { ready: exampleHeading, settle: 600 });

const LINKS = [
  { name: 'links in text', href: '#/t/C04', page: 'Links inline with text', url: /#\/t\/C04$/ },
  { name: 'stand-alone links', href: '#/t/C03', page: 'Stand-alone link', url: /#\/t\/C03$/ },
];
const SENTENCE = ['Read about', 'links in text', 'and', 'stand-alone links', 'first.'];
// The page only bad-text-span opens (TextSpanPage).
const TEXT_SPAN_PAGE = 'About links in text';
const GOOD = ['good-material', 'good-cupertino', 'good-custom'];

const linkId = (slug, n) => `c04-${slug}-link-${n}`;

/** The page `link` goes to is on screen, and the example is not. */
async function expectOn(page, link) {
  await expect(page).toHaveURL(link.url);
  await expect(page.getByRole('heading', { name: link.page, exact: true, level: 1 })).toBeVisible();
  await expect(exampleHeading(page)).toHaveCount(0);
}

/** One press of the app's Back button brings the example back. */
async function backToExample(page, slug) {
  await page.getByRole('button', { name: 'Back' }).click();
  await expect(exampleHeading(page)).toBeVisible();
  await expect(page).toHaveURL(new RegExp(`#/t/C04/${slug}$`));
}

/** Waits, then checks that the example is still on screen, unfollowed. */
async function expectStillOnExample(page, slug) {
  await page.waitForTimeout(1000);
  await expect(page).toHaveURL(new RegExp(`#/t/C04/${slug}$`));
  await expect(exampleHeading(page)).toBeVisible();
}

/** The text of each child element of the sentence, in the page's order. */
async function sentenceParts(page, slug) {
  return byId(page, linkId(slug, 1)).evaluate((link) =>
    [...link.parentElement.children].map((e) => (e.getAttribute('aria-label') || e.textContent).trim()));
}

/** What has keyboard focus, as a short description. */
async function focusedName(page) {
  return page.evaluate(() => {
    const e = document.activeElement;
    if (!e || !e.closest('flt-semantics-host')) return '(page)';
    return (e.getAttribute('aria-label') || e.textContent).replace(/\s+/g, ' ').trim();
  });
}

test.describe('good examples', () => {
  for (const slug of GOOD) {
    test(`${slug}: two links with their href and name, and no other control but Back`, async ({ page }) => {
      await open(page, slug);
      for (const [i, link] of LINKS.entries()) {
        const el = byId(page, linkId(slug, i + 1));
        await expect(el).toHaveRole('link');
        await expect(el).toHaveAccessibleName(link.name);
        await expect(el).toHaveAttribute('href', link.href);
        expect(await el.evaluate((e) => e.tagName)).toBe('A');
        await expect(el.getByRole('button')).toHaveCount(0);
      }
      await expect(page.getByRole('link')).toHaveCount(2);
      await expect(page.getByRole('button')).toHaveCount(1);
    });

    test(`${slug}: the sentence is its words and links in order`, async ({ page }) => {
      await open(page, slug);
      expect(await sentenceParts(page, slug)).toEqual(SENTENCE);
      // Each link sits between the words round it: element 1 and 3.
      const roles = await byId(page, linkId(slug, 1)).evaluate((link) =>
        [...link.parentElement.children].map((e) => e.tagName));
      expect(roles).toEqual(['FLT-SEMANTICS', 'A', 'FLT-SEMANTICS', 'A', 'FLT-SEMANTICS']);
    });

    test(`${slug}: Tab goes Back, the first link, the second link`, async ({ page }) => {
      await open(page, slug);
      const stops = [];
      for (let i = 0; i < 3; i++) {
        await page.keyboard.press('Tab');
        await page.waitForTimeout(150);
        stops.push(await focusedName(page));
      }
      expect(stops).toEqual(['Back', LINKS[0].name, LINKS[1].name]);
    });

    for (const [i, link] of LINKS.entries()) {
      const id = linkId(slug, i + 1);
      test(`${slug}: a click follows link ${i + 1} once, in this tab`, async ({ page, context }) => {
        await open(page, slug);
        await byId(page, id).click();
        await expectOn(page, link);
        expect(context.pages()).toHaveLength(1);
        await backToExample(page, slug);
      });

      test(`${slug}: a click from assistive technology follows link ${i + 1} once`, async ({ page }) => {
        // A DOM click with no pointer events before it, in place of what a
        // screen reader sends; what VoiceOver itself sends was not measured.
        await open(page, slug);
        await byId(page, id).dispatchEvent('click');
        await expectOn(page, link);
        await backToExample(page, slug);
      });

      test(`${slug}: Tab reaches link ${i + 1} and Enter follows it once`, async ({ page }) => {
        await open(page, slug);
        expect(await tabTo(page, byId(page, id)), 'Tab reaches the link').toBe(true);
        await page.keyboard.press('Enter');
        await expectOn(page, link);
        await backToExample(page, slug);
      });

      test(`${slug}: Space does not follow link ${i + 1}, as for any link; Enter then does`, async ({ page }) => {
        await open(page, slug);
        const el = byId(page, id);
        expect(await tabTo(page, el), 'Tab reaches the link').toBe(true);
        await page.keyboard.press('Space');
        await expectStillOnExample(page, slug);
        // The positive control, through the same focus in the same load.
        await expect(el).toBeFocused();
        await page.keyboard.press('Enter');
        await expectOn(page, link);
      });

      test(`${slug}: Command- or Ctrl-click opens link ${i + 1} in a new tab and leaves this one`, async ({ page, context }) => {
        await open(page, slug);
        const opened = context.waitForEvent('page');
        await byId(page, id).click({ modifiers: ['ControlOrMeta'] });
        const tab = await opened;
        await expect(tab).toHaveURL(link.url);
        await expectStillOnExample(page, slug);
      });
    }
  }
});

test.describe('bad examples have their defect', () => {
  const spanLink = 'c04-bad-text-span-link-1';

  test('bad-text-span: an <a> with no href that Tab never reaches', async ({ page }) => {
    await open(page, 'bad-text-span');
    const el = byId(page, spanLink);
    expect(await el.evaluate((e) => e.tagName)).toBe('A');
    await expect(el).not.toHaveAttribute('href');
    await expect(el).not.toHaveAttribute('tabindex');
    await expect(el).toHaveText(LINKS[0].name);
    // HTML gives an <a> with no href no link role (Chromium's own tree
    // still calls it a link: docs/evidence/probes/c04/web.txt).
    await expect(page.getByRole('link')).toHaveCount(0);
    // The positive control: Tab does reach Back, the one other control.
    expect(await tabTo(page, page.getByRole('button', { name: 'Back' })), 'Tab reaches Back').toBe(true);
    await page.locator('body').click({ position: { x: 1, y: 1 } });
    expect(await tabTo(page, el), 'Tab skips the link').toBe(false);
    // A click still opens its page, which is what hides the defect.
    await el.click();
    await expect(page.getByRole('heading', { name: TEXT_SPAN_PAGE, level: 1 })).toBeVisible();
  });

  for (const key of ['Enter', 'Space']) {
    test(`bad-text-span: no key opens its page; Tab stops only on Back, and ${key} there goes elsewhere`, async ({ page }) => {
      await open(page, 'bad-text-span');
      // Every control eight presses of Tab stop on: only Back. Stops
      // outside the semantics tree (the page itself, when focus goes round,
      // FL-421) are not controls and are left out.
      const stops = new Set();
      for (let i = 0; i < 8; i++) {
        await page.keyboard.press('Tab');
        await page.waitForTimeout(100);
        stops.add(await focusedName(page));
      }
      expect([...stops].filter((s) => s !== '(page)')).toEqual(['Back']);
      expect(await tabTo(page, page.getByRole('button', { name: 'Back' })), 'Tab reaches Back').toBe(true);
      await page.keyboard.press(key);
      await expect(page.getByRole('heading', { name: 'Links inline with text', level: 1 })).toBeVisible();
      await expect(page.getByRole('heading', { name: TEXT_SPAN_PAGE, level: 1 })).toHaveCount(0);
    });
  }

  test('bad-out-of-order: the sentence is a group named without its links, and the links are inside it after its words', async ({ page }) => {
    await open(page, 'bad-out-of-order');
    const first = byId(page, linkId('bad-out-of-order', 1));
    const group = first.locator('xpath=..');
    await expect(group).toHaveRole('group');
    await expect(group).toHaveAccessibleName('Read about and first.');
    // Inside it, the two links and nothing else.
    expect(await group.evaluate((g) => [...g.children].map((e) => e.textContent.trim()))).toEqual([
      LINKS[0].name,
      LINKS[1].name,
    ]);
    await expect(page.getByRole('link')).toHaveCount(2);
  });

  test('bad-merged: one link, the whole sentence, to the first link\'s page', async ({ page }) => {
    await open(page, 'bad-merged');
    const el = byId(page, 'c04-bad-merged-sentence');
    await expect(el).toHaveRole('link');
    await expect(el).toHaveAccessibleName('Read about links in text and stand-alone links first.');
    await expect(el).toHaveAttribute('href', LINKS[0].href);
    await expect(page.getByRole('link')).toHaveCount(1);
  });

  test('bad-merged: a click on the second link\'s words opens the first link\'s page', async ({ page }) => {
    // Where the words "stand-alone links" are drawn, measured from the
    // sentence's top left in good-material, whose sentence is laid out the
    // same (docs/evidence/probes/c04/web_merged.txt).
    await open(page, 'good-material');
    const second = await byId(page, linkId('good-material', 2)).boundingBox();
    const sentence = await byId(page, linkId('good-material', 1)).evaluate((e) => {
      const r = e.parentElement.getBoundingClientRect();
      return { x: r.x, y: r.y };
    });
    await open(page, 'bad-merged');
    const merged = await byId(page, 'c04-bad-merged-sentence').boundingBox();
    const x = merged.x + (second.x - sentence.x) + second.width / 2;
    const y = merged.y + (second.y - sentence.y) + second.height / 2;
    // The point is on the one element, so the click is its.
    expect(await page.evaluate(([x, y]) => document.elementFromPoint(x, y)?.getAttribute('flt-semantics-identifier'), [x, y]))
      .toBe('c04-bad-merged-sentence');
    await page.mouse.click(x, y);
    await expectOn(page, LINKS[0]);
  });

  test('bad-merged: two Tabs stay on the one element, and Enter there follows the first link', async ({ page }) => {
    await open(page, 'bad-merged');
    const stops = [];
    for (let i = 0; i < 3; i++) {
      await page.keyboard.press('Tab');
      await page.waitForTimeout(150);
      stops.push(await focusedName(page));
    }
    const whole = 'Read about links in text and stand-alone links first.';
    expect(stops).toEqual(['Back', whole, whole]);
    // Flutter's focus is on the second link now; the key goes to the
    // browser, which follows the element's one href.
    await page.keyboard.press('Enter');
    await expectOn(page, LINKS[0]);
  });
});
