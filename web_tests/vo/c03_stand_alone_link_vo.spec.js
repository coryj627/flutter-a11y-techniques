// L4 on web for C03 Stand-alone link: what VoiceOver on macOS speaks for
// each example. Needs Guidepup's setup and macOS automation permissions on
// the machine. Run through `python3 tool/voiceover_web.py C03`, which also
// writes the transcript.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { walkToEnd } from './vo_helpers.js';

const EXAMPLE = 'heading level 2 Example';
const LINK = 'link Read about stand-alone links';

// slug -> everything VoiceOver speaks after the "Example" heading, to the
// end of the screen, in order, one entry for each element its cursor stops
// on. The link is the last element of every example. Because every stop is
// listed, the list also shows what is not spoken.
const EXAMPLES = {
  'good-material': [LINK],
  'good-cupertino': [LINK],
  'good-custom': [LINK],
  'good-image-link': [LINK],
  // Bad examples: the defect must be audible where the web shows it.
  'bad-vague-text': ['link Read more'],
  'bad-tap-handler': ['Read about stand-alone links button'],
  // Not audible here: the browsers' own trees call an <a> with no href a
  // link, though HTML gives it none (see the tree spec).
  'bad-no-address': [LINK],
  // With no name, VoiceOver reads the link's address in its place: the
  // page's own origin, then #/t/C03 (ADDRESS, filled in for the page).
  'bad-image-no-name': ['ADDRESS'],
  // Chromium names the link from the image inside it (see the tree spec).
  'bad-label-on-image': ['link image Read about stand-alone links'],
  // The web shows a link only (see the tree spec).
  'bad-cupertino-button': [LINK],
  // The defect is in what a click does, not in what is heard.
  'bad-app-also-follows': [LINK],
};

for (const [slug, expected] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/C03/${slug}`, { waitUntil: 'load' });
    await expect(page.getByRole('heading', { name: 'Example', exact: true, level: 2 })).toBeVisible();
    await page.waitForTimeout(600);
    const { stops, reachedEnd } = await walkToEnd(page, voiceOver, browserName);
    console.log(`C03VO ${browserName} ${slug} | ${stops.join(' / ')}`);
    expect(reachedEnd, `${slug}: the walk reached the end of the screen`).toBe(true);
    const start = stops.indexOf(EXAMPLE);
    expect(start, `${slug}: reached the example`).toBeGreaterThanOrEqual(0);
    const address = `link ${new URL(page.url()).origin}/#/t/C03`;
    expect(stops.slice(start + 1), slug).toEqual(expected.map((e) => (e === 'ADDRESS' ? address : e)));
  });
}
