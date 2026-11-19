// L4 on web for I08 Dismiss and escape: what VoiceOver on macOS says when
// the layers open, with VoiceOver's own activation, and what happens when a
// VoiceOver user presses Escape. Needs Guidepup's setup and macOS
// automation permissions on the machine. Run through
// `python3 tool/voiceover_web.py I08`, which also writes the transcript.
//
// VoiceOver on macOS has no dismiss gesture of its own; its user presses
// Escape on the keyboard, which VoiceOver passes to the page (Escape is not
// one of VoiceOver's commands, which start with Control and Option). The
// key is pressed through the system here, as a person's is.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { activateBrowser, lastPhrase, waitUntilQuiet } from './vo_helpers.js';

const all = ['good-material', 'good-cupertino', 'good-widgets', 'bad-not-dismissible', 'bad-no-escape', 'bad-back-leaves'];
const escapeCloses = ['good-material', 'good-cupertino', 'good-widgets', 'bad-back-leaves'];

// The good example each bad one is made from, by its title on the
// technique's screen.
const goodOf = {
  'bad-not-dismissible': ['good-material', 'A Material bottom sheet that can be dismissed'],
  'bad-no-escape': ['good-widgets', 'Layers drawn in the overlay, closed by every dismiss command'],
};

const control = (page, slug, part) => page.locator(`[flt-semantics-identifier="i08-${slug}-${part}"]`);

const tidy = (phrase) => phrase.replace(/\s+/g, ' ').trim();

/**
 * Runs `action`, then collects every new phrase VoiceOver is given for
 * `ms` milliseconds. The phrase from before the action is left out, so a
 * stale phrase cannot pass for one the action caused; every read throws if
 * VoiceOver cannot be read.
 */
async function heardAfter(page, action, ms = 4000) {
  const before = tidy(await lastPhrase());
  await action();
  const out = [];
  const end = Date.now() + ms;
  while (Date.now() < end) {
    const now = tidy(await lastPhrase());
    if (now && now !== before && now !== out[out.length - 1]) out.push(now);
    await page.waitForTimeout(200);
  }
  return out;
}

/** Whether both switches are on the page. */
const shown = async (page, slug) =>
  (await control(page, slug, 'contours').count()) === 1 && (await control(page, slug, 'campsites').count()) === 1;

for (const slug of all) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    test.skip(browserName === 'webkit', 'measured in Chromium only');
    await page.goto(`/#/t/I08/${slug}`, { waitUntil: 'load' });
    await expect(control(page, slug, 'count')).toBeVisible();
    await activateBrowser(browserName);
    await page.bringToFront();
    // A real click, on inert text, puts keyboard focus in the page.
    await page.getByRole('heading', { name: 'Example', level: 2 }).click();
    await control(page, slug, 'open').focus();
    await waitUntilQuiet(page, 2000, 10000);
    const opened = await heardAfter(page, () => voiceOver.act());
    const isShown = await shown(page, slug);
    // VoiceOver's cursor follows DOM focus, which the layers put on their
    // first switch, or leave on the page for a route (I03); either way the
    // next Escape is the user's.
    const escaped = await heardAfter(page, () => voiceOver.press('Escape'), 3000);
    const stillShown = await shown(page, slug);
    console.log(`I08VO ${browserName} ${slug} | opened: ${opened.join(' / ')} [shown: ${isShown}] | Escape: ${escaped.join(' / ') || '(nothing new)'} [shown: ${stillShown}]`);
    expect(isShown, `${slug}: VoiceOver's activation shows the layers`).toBe(true);
    expect(opened.length, `${slug}: VoiceOver said something when the layers opened`).toBeGreaterThan(0);
    if (escapeCloses.includes(slug)) {
      expect(stillShown, `${slug}: Escape closed the layers`).toBe(false);
      await expect(control(page, slug, 'count')).toHaveText('Closed: 1');
    } else {
      // The defect, with VoiceOver on: Escape leaves the layers shown. The
      // positive control, on the same page: VoiceOver's cursor on Contour
      // lines, and its own activation turns the switch, so the layers are
      // live and VoiceOver's commands reach them.
      expect(stillShown, `${slug}: the layers are still shown`).toBe(true);
      const contours = control(page, slug, 'contours');
      await contours.focus();
      await waitUntilQuiet(page, 2000, 10000);
      const before = await contours.getAttribute('aria-checked');
      await voiceOver.act();
      await page.waitForTimeout(1500);
      const after = await contours.getAttribute('aria-checked');
      console.log(`I08VO ${browserName} ${slug}-control | VO-Space on Contour lines: ${before} to ${after}`);
      expect(after, `${slug}: VoiceOver's activation turned the switch`).not.toBe(before);
      // And for Escape itself, on the same page: the layers closed with the
      // mouse, Back to the technique's screen, the good example the bad one
      // is made from opened from there, and the same Escape, pressed
      // through the system, closes its layers.
      const size = page.viewportSize();
      if (slug === 'bad-not-dismissible') {
        const box = await contours.boundingBox();
        await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
        await page.mouse.down();
        await page.mouse.move(box.x + box.width / 2, size.height - 2, { steps: 20 });
        await page.mouse.up();
      } else {
        await page.mouse.click(size.width / 2, 40);
      }
      await expect(contours).toHaveCount(0);
      await page.getByRole('button', { name: 'Back' }).click();
      const [good, title] = goodOf[slug];
      await page.getByRole('button', { name: new RegExp(`^${title}`) }).click();
      await expect(control(page, good, 'count')).toBeVisible();
      await control(page, good, 'open').click();
      await expect(control(page, good, 'contours')).toHaveCount(1);
      await voiceOver.press('Escape');
      await page.waitForTimeout(1500);
      const goodClosed = !(await shown(page, good));
      console.log(`I08VO ${browserName} ${slug}-escape-control | Escape in ${good}, on the same page: ${goodClosed ? 'closed' : 'still shown'}`);
      expect(goodClosed, `${good}: Escape, the positive control on the page of ${slug}`).toBe(true);
    }
  });
}
