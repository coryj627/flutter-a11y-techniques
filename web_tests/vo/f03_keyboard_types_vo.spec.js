// L4 on web for F03 Keyboard types: what VoiceOver on macOS speaks for each
// example. Needs Guidepup's setup and macOS automation permissions on the
// machine. Run through `python3 tool/voiceover_web.py F03`, which also
// writes the transcript.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { walkToEnd } from './vo_helpers.js';

const EXAMPLE = 'heading level 2 Example';
// The change count is the last element of every example. A walk made after
// typing "abc" ends on "Changes: 3".
const COUNT = (n) => `Changes: ${n}`;

const field = (page, id) => page.locator(`[flt-semantics-identifier="${id}"] input`);

// name -> { slug, fill: identifier of a field to type "abc" into first,
// content: everything VoiceOver speaks after the "Example" heading and before
// the change count, in order, one entry for each element its cursor stops
// on, per browser where they differ }. Because every stop is listed, a stop
// with no speech, or with the speech of the stop before it, fails the
// comparison: an empty or stale capture cannot pass.
const WALKS = {
  'good-contact': { slug: 'good-contact', content: ['Name edit text', 'Email edit text', 'Phone edit text'] },
  'good-amount': { slug: 'good-amount', content: ['Amount edit text'] },
  'good-cupertino': { slug: 'good-cupertino', content: ['Email edit text', 'Phone edit text'] },
  'good-sign-in': { slug: 'good-sign-in', content: ['Username edit text', 'Password secure edit text'] },
  // The password with "abc" typed: what was typed is not read out.
  'good-sign-in+filled': { slug: 'good-sign-in', fill: 'f03-good-sign-in-password',
    content: ['Username edit text', 'Password secure edit text'] },
  // Bad examples: the keyboard and the purpose are not heard, so these read
  // like the good ones.
  'bad-number-for-name': { slug: 'bad-number-for-name', content: ['Name edit text'] },
  'bad-default-keyboard': { slug: 'bad-default-keyboard', content: ['Email edit text'] },
  'bad-no-purpose': { slug: 'bad-no-purpose', content: ['Name edit text'] },
  'bad-email-no-suggestions': { slug: 'bad-email-no-suggestions', content: ['Email edit text'] },
};

for (const [name, walk] of Object.entries(WALKS)) {
  test(`voiceover reads ${name}`, async ({ page, voiceOver, browserName }) => {
    const { slug, fill } = walk;
    const content = typeof walk.content === 'function' ? walk.content(browserName)
      : Array.isArray(walk.content) ? walk.content : walk.content[browserName];
    // No fallback to another browser's speech: it differs, which is the point.
    expect(content, `${name}: no expected speech for ${browserName}`).toBeDefined();
    await page.goto(`/#/t/F03/${slug}`, { waitUntil: 'load' });
    await expect(page.locator(`[flt-semantics-identifier="f03-${slug}-count"]`)).toBeVisible();
    if (fill) {
      // Flutter attaches its text editing a moment after the tree appears.
      await page.waitForTimeout(600);
      await field(page, fill).click();
      await page.waitForTimeout(250);
      await page.keyboard.type('abc', { delay: 40 });
      await expect(page.locator(`[flt-semantics-identifier="f03-${slug}-count"]`)).toHaveText(COUNT(3));
    }
    const { stops, reachedEnd } = await walkToEnd(page, voiceOver, browserName, 40, { loggedForHelp: true });
    console.log(`F03VO ${browserName} ${name} | ${stops.join(' / ')}`);
    expect(reachedEnd, `${name}: the walk reached the end of the screen`).toBe(true);
    const start = stops.indexOf(EXAMPLE);
    expect(start, `${name}: reached the example`).toBeGreaterThanOrEqual(0);
    expect(stops.slice(start + 1), name).toEqual([...content, COUNT(fill ? 3 : 0)]);
  });
}
