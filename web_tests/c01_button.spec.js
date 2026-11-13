// L3 for C01 Button on web: what the browser's accessibility tree exposes.
// Spec: docs/specs/C01-button.md. Runs against the release build in build/web.
import { test, expect } from '@playwright/test';

const byId = (page, id) => page.locator(`[flt-semantics-identifier="${id}"]`);

async function open(page, slug) {
  await page.goto('about:blank');
  await page.goto(`/#/t/C01/${slug}`);
  await byId(page, `c01-${slug}-count`).waitFor();
}

const expectCount = (page, slug, n) =>
  expect(byId(page, `c01-${slug}-count`)).toHaveText(`Activations: ${n}`);

/** Press Tab until `locator` has focus. Returns false if it never does. */
async function tabTo(page, locator, max = 8) {
  for (let i = 0; i < max; i++) {
    await page.keyboard.press('Tab');
    // Flutter moves DOM focus on the next frame.
    await page.waitForTimeout(100);
    if (await locator.evaluate((e) => e === document.activeElement)) return true;
  }
  return false;
}

const enabledGood = {
  'good-text': {
    'c01-good-text-filled': 'Save',
    'c01-good-text-outlined': 'Cancel',
    'c01-good-text-text': 'Learn more',
  },
  'good-icon': { 'c01-good-icon-close': 'Close' },
  'good-unique-names': {
    'c01-good-unique-names-username': 'Edit username',
    'c01-good-unique-names-email': 'Edit email',
    'c01-good-unique-names-password': 'Edit password',
  },
  'good-cupertino': { 'c01-good-cupertino-save': 'Save' },
  'good-custom': { 'c01-good-custom-save': 'Save' },
};

const disabledGood = {
  'good-disabled': { 'c01-good-disabled-submit': 'Submit' },
  'good-cupertino': { 'c01-good-cupertino-delete': 'Delete' },
};

test.describe('good examples', () => {
  for (const [slug, buttons] of Object.entries(enabledGood)) {
    test(`${slug}: role, name, and click`, async ({ page }) => {
      await open(page, slug);
      let n = 0;
      for (const [id, name] of Object.entries(buttons)) {
        const button = byId(page, id);
        await expect(button).toHaveRole('button');
        await expect(button).toHaveAccessibleName(name);
        await expect(button).toBeEnabled();
        await expect(page.getByRole('button', { name, exact: true })).toHaveCount(1);
        await button.click();
        await expectCount(page, slug, ++n);
      }
    });

    test(`${slug}: Tab reaches each button in order; Enter and Space activate`, async ({ page }) => {
      await open(page, slug);
      let n = 0;
      for (const id of Object.keys(buttons)) {
        expect(await tabTo(page, byId(page, id)), `Tab reaches ${id}`).toBe(true);
        await page.keyboard.press('Enter');
        await expectCount(page, slug, ++n);
        await page.keyboard.press('Space');
        await expectCount(page, slug, ++n);
      }
    });
  }

  for (const [slug, buttons] of Object.entries(disabledGood)) {
    test(`${slug}: disabled button is exposed as disabled and cannot act`, async ({ page }) => {
      await open(page, slug);
      for (const [id, name] of Object.entries(buttons)) {
        const button = byId(page, id);
        await expect(button).toHaveRole('button');
        await expect(button).toHaveAccessibleName(name);
        await expect(button).toHaveAttribute('aria-disabled', 'true');
        await expect(button).toBeDisabled();
        await button.click({ force: true });
        expect(await tabTo(page, button), `Tab skips ${id}`).toBe(false);
      }
      await expectCount(page, slug, 0);
    });
  }

  test('activation is announced through a polite live region', async ({ page }) => {
    await open(page, 'good-text');
    // Flutter writes an announcement into <flt-announcement-polite> and clears
    // it again after a short time, and a pending clear from an earlier
    // announcement can remove a newer one. Reading the element once is a race,
    // so record everything it is given.
    await page.locator('flt-announcement-polite').evaluate((element) => {
      window.announcements = [];
      new MutationObserver(() => {
        if (element.textContent) window.announcements.push(element.textContent);
      }).observe(element, { childList: true, characterData: true, subtree: true });
    });
    await byId(page, 'c01-good-text-filled').click();
    await expect
      .poll(() => page.evaluate(() => window.announcements.join(' | ')))
      .toMatch(/Activations: 1/);
  });
});

// VAL-3: each bad example is asserted to have its named defect.
test.describe('bad examples have their defect', () => {
  test('bad-unlabelled-icon: a button with an empty name', async ({ page }) => {
    await open(page, 'bad-unlabelled-icon');
    const button = byId(page, 'c01-bad-unlabelled-icon-close');
    await expect(button).toHaveRole('button');
    await expect(button).toHaveAccessibleName('');
  });

  test('bad-gesture-only: cannot be reached or activated from the keyboard', async ({ page }) => {
    await open(page, 'bad-gesture-only');
    const target = byId(page, 'c01-bad-gesture-only-save');
    // Flutter web gives every tappable node role="button", so on web the role
    // is present and the defect is keyboard access only.
    await expect(target).toHaveRole('button');
    await expect(target).not.toHaveAttribute('tabindex');
    expect(await tabTo(page, target)).toBe(false);
    await expectCount(page, 'bad-gesture-only', 0);
    await target.click();
    await expectCount(page, 'bad-gesture-only', 1);
  });

  test('bad-role-in-name: the name ends with the role', async ({ page }) => {
    await open(page, 'bad-role-in-name');
    await expect(byId(page, 'c01-bad-role-in-name-close')).toHaveAccessibleName(/button$/i);
  });

  test('bad-duplicate-names: three buttons share one name', async ({ page }) => {
    await open(page, 'bad-duplicate-names');
    await expect(page.getByRole('button', { name: 'Edit', exact: true })).toHaveCount(3);
  });

  test('bad-name-mismatch: the name does not contain "Edit"', async ({ page }) => {
    await open(page, 'bad-name-mismatch');
    const button = byId(page, 'c01-bad-name-mismatch-edit');
    await expect(button).toHaveAccessibleName('Change username');
    await expect(button).not.toHaveAccessibleName(/edit/i);
  });

  test('bad-fake-disabled: reported as enabled and still acts', async ({ page }) => {
    await open(page, 'bad-fake-disabled');
    const button = byId(page, 'c01-bad-fake-disabled-submit');
    await expect(button).not.toHaveAttribute('aria-disabled');
    await button.click();
    await expectCount(page, 'bad-fake-disabled', 1);
  });

  test('bad-cupertino-disabled: no disabled state (Flutter limitation)', async ({ page }) => {
    await open(page, 'bad-cupertino-disabled');
    const button = byId(page, 'c01-bad-cupertino-disabled-delete');
    await expect(button).toHaveRole('button');
    await expect(button).not.toHaveAttribute('aria-disabled');
    await button.click({ force: true });
    await expectCount(page, 'bad-cupertino-disabled', 0);
  });
});

// DOC-2: the technique screen renders docs/techniques/C01.md.
test.describe('technique doc in the app', () => {
  test('headings, links, and lists are exposed', async ({ page }) => {
    await page.goto('about:blank');
    await page.goto('/#/t/C01');
    await expect(page.getByRole('heading', { name: 'Documentation', level: 2 })).toBeAttached();
    await expect(page.getByRole('heading', { name: 'Why it matters', level: 3 })).toBeAttached();
    // The whole page is in the tree without scrolling, to the last section.
    await expect(page.getByRole('heading', { name: 'Flutter limitations', level: 3 })).toBeAttached();
    await expect(page.getByRole('heading', { name: 'Sources', level: 2 })).toBeAttached();
    // The doc's own title and its WCAG section are not repeated.
    await expect(page.getByRole('heading', { name: 'C01 Button' })).toHaveCount(0);
    await expect(page.getByRole('heading', { name: 'WCAG 2.2', exact: true })).toHaveCount(0);
    // A web link and a repository link, both real links with a destination.
    await expect(page.getByRole('link', { name: 'APG Button' }).first()).toHaveAttribute(
      'href', 'https://www.w3.org/WAI/ARIA/apg/patterns/button/');
    await expect(page.getByRole('link', { name: 'FL-001' })).toHaveAttribute(
      'href', /github\.com\/coryj627\/flutter-a11y-techniques\/blob\/main\/docs\/flutter-limitations\.md#fl-001$/);
    expect(await page.getByRole('list').count()).toBeGreaterThan(0);
    expect(await page.getByRole('listitem').count()).toBeGreaterThan(3);
  });
});

test.describe('addresses', () => {
  for (const hash of ['/t/C01/%FF', '/t/%E0%A4%A/good-text', '/nowhere']) {
    test(`a bad address (${hash}) shows the not-found page, not a blank app`, async ({ page }) => {
      await page.goto('about:blank');
      await page.goto(`/#${hash}`);
      await expect(page.getByRole('heading', { name: 'Page not found' })).toBeVisible();
      await page.getByRole('button', { name: 'Go to the catalog' }).click();
      await expect(page.getByRole('heading', { name: 'Flutter A11Y Techniques' })).toBeVisible();
    });
  }

  test('Back from a directly opened example reaches its technique, then the catalog', async ({ page }) => {
    await open(page, 'good-text');
    await page.getByRole('button', { name: 'Back' }).click();
    await expect(page.getByRole('heading', { name: 'Button', exact: true })).toBeVisible();
    await page.getByRole('button', { name: 'Back' }).click();
    await expect(page.getByRole('heading', { name: 'Flutter A11Y Techniques' })).toBeVisible();
    await expect(page.getByRole('heading', { name: 'Page not found' })).toHaveCount(0);
  });
});

// A link must go to its destination once: in this tab, with no second tab.
test.describe('external links', () => {
  for (const how of ['click', 'Enter']) {
    test(`activating a link by ${how} navigates this tab once and opens no other`, async ({ page, context }) => {
      // Serve a stub so the test does not depend on the network.
      await context.route(/^https:\/\/www\.w3\.org\//, (route) =>
        route.fulfill({ status: 200, contentType: 'text/html', body: '<title>stub</title>' }));
      const opened = [];
      context.on('page', (p) => opened.push(p));
      await page.goto('about:blank');
      await page.goto('/#/about');
      const link = page.getByRole('link', { name: 'WCAG 2.2' });
      await expect(link).toHaveAttribute('href', 'https://www.w3.org/TR/WCAG22/');
      if (how === 'click') {
        await link.click();
      } else {
        await link.focus();
        await page.keyboard.press('Enter');
      }
      await expect(page).toHaveURL('https://www.w3.org/TR/WCAG22/');
      await page.waitForTimeout(1500);
      expect(opened, 'no second tab').toHaveLength(0);
      // Back returns to the app where the user was.
      await page.goBack();
      await expect(page.getByRole('heading', { name: 'About' })).toBeVisible();
    });
  }
});
