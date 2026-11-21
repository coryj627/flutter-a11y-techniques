// L3 for C03 Stand-alone link on web: what the browser's accessibility tree
// exposes, and what a click, the keys, and a click from assistive technology
// do. Spec: docs/specs/C03-stand-alone-link.md. Runs against the release
// build in build/web.
//
// Every link goes to the technique's own page, /t/C03. On the web the good
// examples' links are <a href="#/t/C03"> and the browser follows them; the
// app does not (FL-013). "Followed once" is checked by the app's Back
// button: one press must bring the example back.
import { test, expect } from '@playwright/test';
import { byId, tabTo, technique } from './support/techniques.js';

// The example screen's own "Example" heading; the technique's page has
// "Good examples" and "Bad examples", so the name must match exactly.
const exampleHeading = (page) => page.getByRole('heading', { name: 'Example', exact: true, level: 2 });
const { open } = technique('C03', { ready: exampleHeading, settle: 600 });

const NAME = 'Read about stand-alone links';
const DESTINATION = /#\/t\/C03$/;

const good = {
  'good-material': 'c03-good-material-link',
  'good-cupertino': 'c03-good-cupertino-link',
  'good-custom': 'c03-good-custom-link',
  'good-image-link': 'c03-good-image-link-link',
};

/** The technique's page, the links' destination, is on screen. */
async function expectDestination(page) {
  await expect(page).toHaveURL(DESTINATION);
  await expect(page.getByRole('heading', { name: 'Stand-alone link', level: 1 })).toBeVisible();
  await expect(exampleHeading(page)).toHaveCount(0);
}

/** One press of the app's Back button brings the example back. */
async function backToExample(page, slug) {
  await page.getByRole('button', { name: 'Back' }).click();
  await expect(exampleHeading(page)).toBeVisible();
  await expect(page).toHaveURL(new RegExp(`#/t/C03/${slug}$`));
}

/** Waits, then checks that the example is still on screen, unfollowed. */
async function expectStillOnExample(page, slug) {
  await page.waitForTimeout(1000);
  await expect(page).toHaveURL(new RegExp(`#/t/C03/${slug}$`));
  await expect(exampleHeading(page)).toBeVisible();
}

test.describe('good examples', () => {
  for (const [slug, id] of Object.entries(good)) {
    test(`${slug}: a link with an href and a name, and no other role`, async ({ page }) => {
      await open(page, slug);
      const link = byId(page, id);
      await expect(link).toHaveRole('link');
      await expect(link).toHaveAccessibleName(NAME);
      await expect(link).toHaveAttribute('href', '#/t/C03');
      expect(await link.evaluate((e) => e.tagName)).toBe('A');
      await expect(page.getByRole('link', { name: NAME, exact: true })).toHaveCount(1);
      // Nothing inside it is a button or an image of its own.
      await expect(link.getByRole('button')).toHaveCount(0);
      await expect(page.getByRole('img')).toHaveCount(0);
    });

    test(`${slug}: a click follows it once, in this tab`, async ({ page, context }) => {
      await open(page, slug);
      await byId(page, id).click();
      await expectDestination(page);
      expect(context.pages()).toHaveLength(1);
      await backToExample(page, slug);
    });

    test(`${slug}: a click from assistive technology follows it once`, async ({ page }) => {
      // A screen reader activates an element with a DOM click, with no
      // pointer events before it.
      await open(page, slug);
      await byId(page, id).dispatchEvent('click');
      await expectDestination(page);
      await backToExample(page, slug);
    });

    test(`${slug}: Tab reaches it and Enter follows it once`, async ({ page }) => {
      await open(page, slug);
      expect(await tabTo(page, byId(page, id)), 'Tab reaches the link').toBe(true);
      await page.keyboard.press('Enter');
      await expectDestination(page);
      await backToExample(page, slug);
    });

    test(`${slug}: Space does not follow it, as for any link; Enter then does`, async ({ page }) => {
      await open(page, slug);
      const link = byId(page, id);
      expect(await tabTo(page, link), 'Tab reaches the link').toBe(true);
      await page.keyboard.press('Space');
      await expectStillOnExample(page, slug);
      // The positive control, through the same focus in the same load.
      await expect(link).toBeFocused();
      await page.keyboard.press('Enter');
      await expectDestination(page);
    });

    test(`${slug}: Command- or Ctrl-click opens it in a new tab and leaves this one`, async ({ page, context }) => {
      await open(page, slug);
      const opened = context.waitForEvent('page');
      await byId(page, id).click({ modifiers: ['ControlOrMeta'] });
      const tab = await opened;
      await expect(tab).toHaveURL(DESTINATION);
      await expect(tab.getByRole('heading', { name: 'Stand-alone link', level: 1 })).toBeVisible();
      await expectStillOnExample(page, slug);
    });
  }
});

test.describe('bad examples have their defect', () => {
  test('bad-vague-text: a link named "Read more"', async ({ page }) => {
    await open(page, 'bad-vague-text');
    const link = byId(page, 'c03-bad-vague-text-link');
    await expect(link).toHaveRole('link');
    await expect(link).toHaveAccessibleName('Read more');
    await expect(link).toHaveAttribute('href', '#/t/C03');
  });

  test('bad-tap-handler: a button, not a link, and Tab never reaches it', async ({ page }) => {
    await open(page, 'bad-tap-handler');
    const element = byId(page, 'c03-bad-tap-handler-link');
    // Any node with a tap action is role="button" on the web (FL-006).
    await expect(element).toHaveRole('button');
    await expect(element).toHaveAccessibleName(NAME);
    await expect(page.getByRole('link')).toHaveCount(0);
    await expect(element).not.toHaveAttribute('tabindex');
    // The positive control: Tab does reach Back, the one other control.
    expect(await tabTo(page, page.getByRole('button', { name: 'Back' })), 'Tab reaches Back').toBe(true);
    await page.locator('body').click({ position: { x: 1, y: 1 } });
    expect(await tabTo(page, element), 'Tab skips the text').toBe(false);
    // A click still follows it, which is what hides the defect.
    await element.click();
    await expectDestination(page);
  });

  test('bad-no-address: an <a> with no href, which is not a link', async ({ page }) => {
    await open(page, 'bad-no-address');
    const element = byId(page, 'c03-bad-no-address-link');
    expect(await element.evaluate((e) => e.tagName)).toBe('A');
    await expect(element).not.toHaveAttribute('href');
    await expect(page.getByRole('link')).toHaveCount(0);
    await expect(element).not.toHaveRole('link');
    // The app follows it itself, by a click and by Enter.
    await element.click();
    await expectDestination(page);
    await backToExample(page, 'bad-no-address');
    expect(await tabTo(page, element), 'Tab reaches it').toBe(true);
    await page.keyboard.press('Enter');
    await expectDestination(page);
  });

  test('bad-image-no-name: a link with no name', async ({ page }) => {
    await open(page, 'bad-image-no-name');
    const link = byId(page, 'c03-bad-image-no-name-link');
    await expect(link).toHaveRole('link');
    await expect(link).toHaveAccessibleName('');
    await expect(link).toHaveAttribute('href', '#/t/C03');
  });

  test('bad-label-on-image: the link takes its name from the image inside it', async ({ page }) => {
    await open(page, 'bad-label-on-image');
    // Chromium computes the link's name from the image, so on the web the
    // defect is in the structure only: an image element inside a link that
    // has no label of its own. Android and iOS expose a link with no name
    // (see the device tests).
    const link = page.getByRole('link', { name: NAME, exact: true });
    await expect(link).toHaveCount(1);
    await expect(link).not.toHaveAttribute('aria-label');
    const image = link.getByRole('img', { name: NAME, exact: true });
    await expect(image).toHaveCount(1);
    await expect(image).toHaveAttribute('aria-label', NAME);
  });

  test('bad-cupertino-button: on the web a link only, with no button inside', async ({ page }) => {
    // The defect cannot be seen on the web: the engine makes a node that is
    // a link and a button one <a href>, and its role is link. Android and
    // iOS expose a button (see the device tests).
    await open(page, 'bad-cupertino-button');
    const link = byId(page, 'c03-bad-cupertino-button-link');
    await expect(link).toHaveRole('link');
    await expect(link).toHaveAccessibleName(NAME);
    await expect(link).toHaveAttribute('href', '#/t/C03');
    await expect(page.getByRole('button', { name: NAME })).toHaveCount(0);
  });

  // The app and the browser both follow the link. What that does depends on
  // how it is followed (docs/evidence/probes/c03/web_twice.txt,
  // web_twice_enter.txt, and web_twice_dispatch.txt, five runs each).
  for (const how of ['click', 'Enter']) {
    test(`bad-app-also-follows: a mouse ${how === 'click' ? 'click' : 'user\'s Enter'} leaves the screen as it was`, async ({ page }) => {
      await open(page, 'bad-app-also-follows');
      const link = byId(page, 'c03-bad-app-also-follows-link');
      const destinations = [];
      page.on('framenavigated', (f) => {
        if (f === page.mainFrame() && DESTINATION.test(f.url())) destinations.push(f.url());
      });
      if (how === 'click') {
        await link.click();
      } else {
        expect(await tabTo(page, link), 'Tab reaches the link').toBe(true);
        await page.keyboard.press('Enter');
      }
      await page.waitForTimeout(1500);
      // The positive control: the key or click did reach the link, and the
      // address went to the technique's page on the way.
      expect(destinations.length, `the ${how} navigated to #/t/C03 on the way`).toBeGreaterThan(0);
      // Where it ended: the example, as if nothing had happened.
      await expect(page).toHaveURL(/#\/t\/C03\/bad-app-also-follows$/);
      await expect(exampleHeading(page)).toBeVisible();
      await expect(page.getByRole('heading', { name: 'Stand-alone link', level: 1 })).toHaveCount(0);
    });
  }

  test("bad-app-also-follows: a DOM click opens the page twice, under the example's address", async ({ page }) => {
    // A click event with no pointer events before it, as assistive
    // technology can send. What VoiceOver itself does here was not measured.
    await open(page, 'bad-app-also-follows');
    await byId(page, 'c03-bad-app-also-follows-link').dispatchEvent('click');
    const destination = page.getByRole('heading', { name: 'Stand-alone link', level: 1 });
    await expect(destination).toBeVisible();
    await page.waitForTimeout(1000);
    // The address bar still shows the example.
    await expect(page).toHaveURL(/#\/t\/C03\/bad-app-also-follows$/);
    // One Back leaves the technique's page on screen: it was opened twice.
    await page.getByRole('button', { name: 'Back' }).click();
    await page.waitForTimeout(1000);
    await expect(destination).toBeVisible();
    await expect(exampleHeading(page)).toHaveCount(0);
    // A second Back brings the example back.
    await page.getByRole('button', { name: 'Back' }).click();
    await expect(exampleHeading(page)).toBeVisible();
  });
});
