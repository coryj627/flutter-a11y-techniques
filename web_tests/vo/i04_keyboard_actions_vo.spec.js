// L4 on web for I04 Keyboard actions and shortcuts: what VoiceOver on macOS
// speaks for each example, and which keys still reach the page while it
// runs. Needs Guidepup's setup and macOS automation permissions on the
// machine. Run through `python3 tool/voiceover_web.py I04`, which also
// writes the transcript.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { activateBrowser, walkToEnd } from './vo_helpers.js';

const EXAMPLE = 'heading level 2 Example';
// The count of notes saved is the last element of every example.
const COUNT = 'Notes saved: 0';

const HINT_ON_FOCUS = 'In the photos: Left and Right arrows for the previous and next photo, Home and End for the first and last, F to add or remove a favourite.';
const HINT_PAGE = 'In the photos: Left and Right arrows for the previous and next photo, Home and End for the first and last. Anywhere here: F to add or remove a favourite.';
const HINT_NONE = 'In the photos: F to add or remove a favourite.';

const strip = (hint, setting = []) => [
  'Showing: Trailhead, 1 of 4',
  'Trailhead current button', 'Bridge button', 'Ridge button', 'Summit button',
  hint, 'Add to favourites button', ...setting, 'Note edit text', 'Favourites: none',
];

// slug -> everything VoiceOver speaks after the "Example" heading and before
// the count, in order, one entry for each element its cursor stops on. The
// keys are not heard: the strip reads the same in every example.
const EXAMPLES = {
  'good-on-focus': strip(HINT_ON_FOCUS),
  'good-turn-off': strip(HINT_PAGE, ['Single-key shortcuts on switch']),
  'good-remap': strip(HINT_PAGE, ['Use Control+F for favourites off switch']),
  'bad-page-shortcut': strip(HINT_PAGE),
  'bad-no-arrow-keys': strip(HINT_NONE),
};

for (const [slug, expected] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/I04/${slug}`, { waitUntil: 'load' });
    await expect(page.locator(`[flt-semantics-identifier="i04-${slug}-count"]`)).toBeVisible();
    const { stops, reachedEnd } = await walkToEnd(page, voiceOver, browserName, 40);
    console.log(`I04VO ${browserName} ${slug} | ${stops.join(' / ')}`);
    expect(reachedEnd, `${slug}: the walk reached the end of the screen`).toBe(true);
    const start = stops.indexOf(EXAMPLE);
    expect(start, `${slug}: reached the example`).toBeGreaterThanOrEqual(0);
    expect(stops.slice(start + 1), slug).toEqual([...expected, COUNT]);
  });
}

// With VoiceOver running, keys pressed through the system (Guidepup sends
// them as key presses to the front app) on a thumbnail of
// bad-page-shortcut: Right moves along the strip, F adds a favourite, and
// "Leafy" typed in the note loses its f, as without VoiceOver. VoiceOver's
// own commands use Control and Option, so none of these is one of them;
// Quick Nav, which would take the arrow keys, is off.
test('with voiceover on, keys reach bad-page-shortcut', async ({ page, voiceOver, browserName }) => {
  const slug = 'bad-page-shortcut';
  const id = (part) => page.locator(`[flt-semantics-identifier="i04-${slug}-${part}"]`);
  await page.goto(`/#/t/I04/${slug}`, { waitUntil: 'load' });
  await expect(id('count')).toBeVisible();
  await activateBrowser(browserName);
  await page.bringToFront();
  const heading = page.getByRole('heading', { name: 'Example', level: 2 });
  const box = await heading.boundingBox();
  await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
  await id('trailhead').focus();
  await page.waitForTimeout(1500);
  await voiceOver.press('ArrowRight');
  await page.waitForTimeout(1000);
  const showing = (await id('showing').textContent()).trim();
  await voiceOver.press('f');
  await page.waitForTimeout(1000);
  const favourites = (await id('favourites').textContent()).trim();
  await id('note').locator('input').focus();
  await page.waitForTimeout(1500);
  await voiceOver.type('Leafy');
  await page.waitForTimeout(1500);
  const typed = await id('note').locator('input').inputValue();
  const favouritesAfter = (await id('favourites').textContent()).trim();
  console.log(`I04VO ${browserName} keys-bad-page-shortcut | Right: ${showing} / F: ${favourites} / typed "Leafy": "${typed}" / ${favouritesAfter}`);
  expect(showing).toBe('Showing: Bridge, 2 of 4');
  expect(favourites).toBe('Favourites: Bridge');
  expect(typed).toBe('Leay');
  expect(favouritesAfter).toBe('Favourites: none');
});
