// L3 for I04 Keyboard actions and shortcuts on web: what the browser's
// accessibility tree exposes, and what the keys do, read from the page
// after each one. Spec: docs/specs/I04-keyboard-actions.md. Runs against
// the release build in build/web.
//
// Playwright sends its keys to the page through the browser's DevTools
// protocol, past the browser's own shortcuts, so whether the browser would
// take a key first (its Find, for example) is not tested here.
import { test, expect } from '@playwright/test';
import { byId, tabTo, technique } from './support/techniques.js';

const { open, expectCount } = technique('I04', { countLabel: 'Notes saved' });

const good = ['good-on-focus', 'good-turn-off', 'good-remap'];
const all = [...good, 'bad-page-shortcut', 'bad-no-arrow-keys'];
// The strip answers the arrow keys, Home, and End in these.
const stripKeys = [...good, 'bad-page-shortcut'];
const withSetting = ['good-turn-off', 'good-remap'];
const photos = ['Trailhead', 'Bridge', 'Ridge', 'Summit'];
const thumbs = photos.map((p) => p.toLowerCase());

const part = (page, slug, name) => byId(page, `i04-${slug}-${name}`);
const note = (page, slug) => part(page, slug, 'note').locator('input');
const back = (page) => page.getByRole('button', { name: 'Back' });
const isActive = (locator) => locator.evaluate((e) => e === document.activeElement);

const expectShowing = (page, slug, name) =>
  expect(part(page, slug, 'showing')).toHaveText(`Showing: ${name}, ${photos.indexOf(name) + 1} of 4`);
const expectFavourites = (page, slug, text) =>
  expect(part(page, slug, 'favourites')).toHaveText(`Favourites: ${text}`);

/** The part of the example, or Back, that has focus; "none" if none does. */
async function stop(page, slug) {
  for (const name of [...thumbs, 'favourite', 'setting', 'note']) {
    const element = part(page, slug, name);
    if ((await element.count()) === 0) continue;
    if (await element.evaluate((e) => e === document.activeElement || e.contains(document.activeElement))) {
      return name;
    }
  }
  if (await isActive(back(page))) return 'back';
  return 'none';
}

async function key(page, name, wait = 250) {
  await page.keyboard.press(name);
  await page.waitForTimeout(wait);
}

/** Tabs until `name` has focus, and proves it. */
async function tabToPart(page, slug, name) {
  for (let i = 0; i < 10; i++) {
    if ((await stop(page, slug)) === name) return;
    await key(page, 'Tab', 120);
  }
  expect(await stop(page, slug), `Tab reaches ${name}`).toBe(name);
}

test.describe('every example', () => {
  for (const slug of all) {
    test(`${slug}: four thumbnail buttons, the first selected, a favourite button, and a note field`, async ({ page }) => {
      await open(page, slug);
      await expectShowing(page, slug, 'Trailhead');
      for (const [i, photo] of photos.entries()) {
        const thumb = part(page, slug, thumbs[i]);
        await expect(thumb).toHaveRole('button');
        await expect(thumb).toHaveAccessibleName(photo);
        // The engine writes a button's selected state as aria-current.
        await expect(thumb).toHaveAttribute('aria-current', i === 0 ? 'true' : 'false');
        // Every thumbnail has a tabindex: the strip's one Tab stop is
        // Flutter's own order, which handles Tab (I02).
        await expect(thumb).toHaveAttribute('tabindex', '0');
      }
      await expect(part(page, slug, 'favourite')).toHaveRole('button');
      await expect(part(page, slug, 'favourite')).toHaveAccessibleName('Add to favourites');
      await expect(note(page, slug)).toHaveAccessibleName('Note');
      await expectFavourites(page, slug, 'none');
      await expectCount(page, slug, 0);
    });

    test(`${slug}: a click, and a click event as a screen reader sends, show any photo`, async ({ page }) => {
      await open(page, slug);
      await part(page, slug, 'ridge').click();
      await expectShowing(page, slug, 'Ridge');
      await part(page, slug, 'summit').dispatchEvent('click');
      await expectShowing(page, slug, 'Summit');
    });

    test(`${slug}: Tab goes Back, the thumbnail of the photo shown, the favourite button, then the note`, async ({ page }) => {
      await open(page, slug);
      const order = ['trailhead', 'favourite', ...(withSetting.includes(slug) ? ['setting'] : []), 'note'];
      expect(await tabTo(page, back(page), 2), 'the first Tab reaches Back').toBe(true);
      for (const expected of order) {
        await key(page, 'Tab', 150);
        expect(await stop(page, slug)).toBe(expected);
      }
      // With another photo shown, its thumbnail is the strip's stop.
      await part(page, slug, 'ridge').dispatchEvent('click');
      await expectShowing(page, slug, 'Ridge');
      await tabToPart(page, slug, 'favourite');
      await key(page, 'Shift+Tab', 150);
      expect(await stop(page, slug)).toBe('ridge');
      await key(page, 'Shift+Tab', 150);
      expect(await stop(page, slug)).toBe('back');
    });

    test(`${slug}: Enter in the note saves it, empties the field, and takes focus from it`, async ({ page }) => {
      await open(page, slug);
      await page.waitForTimeout(600);
      await tabToPart(page, slug, 'note');
      await page.keyboard.type('Muddy', { delay: 50 });
      await expect(note(page, slug)).toHaveValue('Muddy');
      await key(page, 'Enter', 400);
      await expectCount(page, slug, 1);
      await expect(note(page, slug)).toHaveValue('');
      // FL-461: the field gives focus up to no control, and the next Tab
      // starts again from the top.
      expect(await stop(page, slug)).toBe('none');
      await key(page, 'Tab', 200);
      expect(await stop(page, slug)).toBe('back');
    });
  }
});

test.describe("the strip's keys", () => {
  for (const slug of stripKeys) {
    test(`${slug}: Right, Left, End, and Home show a photo and move focus to its thumbnail`, async ({ page }) => {
      await open(page, slug);
      await tabToPart(page, slug, 'trailhead');
      for (const [name, photo] of [
        ['ArrowRight', 'Bridge'], ['ArrowRight', 'Ridge'], ['ArrowLeft', 'Bridge'],
        ['End', 'Summit'], ['ArrowRight', 'Summit'], ['Home', 'Trailhead'], ['ArrowLeft', 'Trailhead'],
      ]) {
        await key(page, name);
        await expectShowing(page, slug, photo);
        expect(await stop(page, slug), `focus after ${name}`).toBe(photo.toLowerCase());
      }
    });
  }

  for (const name of ['ArrowRight', 'ArrowLeft', 'End', 'Home']) {
    test(`bad-no-arrow-keys: ${name} does not move along the strip; in the note the arrows move the caret`, async ({ page }) => {
      const slug = 'bad-no-arrow-keys';
      await open(page, slug);
      await page.waitForTimeout(600);
      // From the second photo, so that Left and Home would have somewhere to go.
      await part(page, slug, 'bridge').dispatchEvent('click');
      await expectShowing(page, slug, 'Bridge');
      await tabToPart(page, slug, 'bridge');
      await key(page, name, 400);
      await expectShowing(page, slug, 'Bridge');
      expect(await stop(page, slug), `focus after ${name}`).toBe('bridge');
      // The keys reach the strip: F acts there.
      await key(page, 'f');
      await expectFavourites(page, slug, 'Bridge');
      // The arrows arrive and act in the note, in the same page.
      await tabToPart(page, slug, 'note');
      await page.keyboard.type('Mud', { delay: 50 });
      await key(page, 'ArrowLeft');
      await page.keyboard.type('x');
      await expect(note(page, slug)).toHaveValue('Muxd');
    });
  }

  test('bad-no-arrow-keys: Tab and Shift+Tab never reach the other thumbnails', async ({ page }) => {
    const slug = 'bad-no-arrow-keys';
    await open(page, slug);
    const seen = [];
    for (let i = 0; i < 6; i++) {
      await key(page, 'Tab', 150);
      seen.push(await stop(page, slug));
    }
    for (let i = 0; i < 6; i++) {
      await key(page, 'Shift+Tab', 150);
      seen.push(await stop(page, slug));
    }
    expect(seen).toEqual(expect.arrayContaining(['back', 'trailhead', 'favourite', 'note']));
    for (const other of ['bridge', 'ridge', 'summit']) expect(seen).not.toContain(other);
  });
});

test.describe('the F shortcut', () => {
  test('good-on-focus: F acts in the strip only, and types in the note', async ({ page }) => {
    const slug = 'good-on-focus';
    await open(page, slug);
    await page.waitForTimeout(600);
    await tabToPart(page, slug, 'trailhead');
    await key(page, 'f');
    await expectFavourites(page, slug, 'Trailhead');
    await tabToPart(page, slug, 'favourite');
    await key(page, 'f', 500);
    await expectFavourites(page, slug, 'Trailhead');
    await tabToPart(page, slug, 'note');
    await page.keyboard.type('Leafy', { delay: 50 });
    await expect(note(page, slug)).toHaveValue('Leafy');
    await expectFavourites(page, slug, 'Trailhead');
  });

  for (const slug of ['good-turn-off', 'good-remap']) {
    test(`${slug}: F acts wherever focus is, and types in the note`, async ({ page }) => {
      await open(page, slug);
      await page.waitForTimeout(600);
      await tabToPart(page, slug, 'trailhead');
      await key(page, 'f');
      await expectFavourites(page, slug, 'Trailhead');
      await key(page, 'ArrowRight');
      await tabToPart(page, slug, 'favourite');
      await key(page, 'f');
      await expectFavourites(page, slug, 'Trailhead, Bridge');
      await tabToPart(page, slug, 'setting');
      await key(page, 'f');
      await expectFavourites(page, slug, 'Trailhead');
      await tabToPart(page, slug, 'note');
      await page.keyboard.type('Leafy', { delay: 50 });
      await expect(note(page, slug)).toHaveValue('Leafy');
      await expectFavourites(page, slug, 'Trailhead');
    });
  }

  test('good-turn-off: with the switch off F does nothing; on again, it acts', async ({ page }) => {
    const slug = 'good-turn-off';
    await open(page, slug);
    await tabToPart(page, slug, 'setting');
    await key(page, 'Space');
    await expect(part(page, slug, 'setting')).toHaveAttribute('aria-checked', 'false');
    await key(page, 'f', 500);
    await expectFavourites(page, slug, 'none');
    await key(page, 'Shift+Tab');
    await key(page, 'Shift+Tab');
    expect(await stop(page, slug)).toBe('trailhead');
    await key(page, 'f', 500);
    await expectFavourites(page, slug, 'none');
    // The keys arrive: the strip's own keys still act.
    await key(page, 'ArrowRight');
    await expectShowing(page, slug, 'Bridge');
    // The control: on again, the same key acts.
    await tabToPart(page, slug, 'setting');
    await key(page, 'Space');
    await expect(part(page, slug, 'setting')).toHaveAttribute('aria-checked', 'true');
    await key(page, 'f');
    await expectFavourites(page, slug, 'Bridge');
  });

  test('good-remap: with the switch on, F does nothing and types, and Control+F acts', async ({ page }) => {
    const slug = 'good-remap';
    await open(page, slug);
    await page.waitForTimeout(600);
    await tabToPart(page, slug, 'setting');
    await key(page, 'Control+f', 500);
    await expectFavourites(page, slug, 'none');
    await key(page, 'Space');
    await expect(part(page, slug, 'setting')).toHaveAttribute('aria-checked', 'true');
    await key(page, 'f', 500);
    await expectFavourites(page, slug, 'none');
    await key(page, 'Control+f');
    await expectFavourites(page, slug, 'Trailhead');
    await tabToPart(page, slug, 'note');
    await page.keyboard.type('Leafy', { delay: 50 });
    await expect(note(page, slug)).toHaveValue('Leafy');
    await key(page, 'Control+f');
    await expectFavourites(page, slug, 'none');
  });

  test('bad-page-shortcut: F acts wherever focus is, and in the note it is taken and never typed', async ({ page }) => {
    const slug = 'bad-page-shortcut';
    await open(page, slug);
    await page.waitForTimeout(600);
    await tabToPart(page, slug, 'trailhead');
    await key(page, 'f');
    await expectFavourites(page, slug, 'Trailhead');
    await tabToPart(page, slug, 'favourite');
    await key(page, 'f');
    await expectFavourites(page, slug, 'none');
    await tabToPart(page, slug, 'note');
    await page.keyboard.type('Leafy', { delay: 50 });
    await expect(note(page, slug)).toHaveValue('Leay');
    await expectFavourites(page, slug, 'Trailhead');
    await expect(part(page, slug, 'setting')).toHaveCount(0);
  });

  // What the lost letter leaves: other keyboard ways to put an f in the
  // note. Shift+F types a capital, which CharacterActivator('f') does not
  // match; and an f pasted from the clipboard with the keyboard goes in
  // through the browser's own paste. Each is checked on its own, after a
  // plain f has been shown to be lost in the same page.
  test('bad-page-shortcut: Shift+F types a capital F in the note', async ({ page }) => {
    const slug = 'bad-page-shortcut';
    await open(page, slug);
    await page.waitForTimeout(600);
    await tabToPart(page, slug, 'note');
    await page.keyboard.type('Lea', { delay: 50 });
    await key(page, 'f');
    await expect(note(page, slug)).toHaveValue('Lea');
    await expectFavourites(page, slug, 'Trailhead');
    await key(page, 'Shift+F');
    await expect(note(page, slug)).toHaveValue('LeaF');
    await expectFavourites(page, slug, 'Trailhead');
  });

  test('bad-page-shortcut: an f pasted with the keyboard goes into the note', async ({ page, context }) => {
    const slug = 'bad-page-shortcut';
    await context.grantPermissions(['clipboard-read', 'clipboard-write']);
    await open(page, slug);
    await page.waitForTimeout(600);
    await page.evaluate(() => navigator.clipboard.writeText('f'));
    await tabToPart(page, slug, 'note');
    await page.keyboard.type('Lea', { delay: 50 });
    await key(page, 'f');
    await expect(note(page, slug)).toHaveValue('Lea');
    await key(page, 'ControlOrMeta+V', 500);
    await expect(note(page, slug)).toHaveValue('Leaf');
    await expectFavourites(page, slug, 'Trailhead');
  });
});
