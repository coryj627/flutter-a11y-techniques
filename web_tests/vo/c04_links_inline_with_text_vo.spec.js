// L4 on web for C04 Links inline with text: what VoiceOver on macOS speaks
// for each example. Needs Guidepup's setup and macOS automation permissions
// on the machine. Run through `python3 tool/voiceover_web.py C04`, which also
// writes the transcript.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { walkToEnd } from './vo_helpers.js';

// A wrong reading must fail for good: no runner retries. walkToEnd retries
// nothing either; every stop it makes is compared below.
test.describe.configure({ retries: 0 });

const EXAMPLE = 'heading level 2 Example';
const FIRST = 'link links in text';
const SECOND = 'link stand-alone links';

// slug -> everything VoiceOver speaks after the "Example" heading, to the
// end of the screen, in order, one entry for each element its cursor stops
// on. Because every stop is listed, the list also shows what is not spoken.
const EXAMPLES = {
  // The sentence is read in its order, each link in its place.
  'good-material': ['Read about', FIRST, 'and', SECOND, 'first.'],
  'good-cupertino': ['Read about', FIRST, 'and', SECOND, 'first.'],
  'good-custom': ['Read about', FIRST, 'and', SECOND, 'first.'],
  // Bad examples: the defect must be audible where the web shows it. An <a>
  // with no href is read as a link (FL-032, as in C03's bad-no-address); the
  // defect is the keyboard (see the tree spec).
  'bad-text-span': ['Read about', FIRST, 'first.'],
  // The sentence without its links, as a group, then the links inside it
  // (FL-413, as in V13's first build).
  'bad-out-of-order': [
    'Read about and first. group',
    FIRST,
    SECOND,
    'end of Read about and first. group',
  ],
  // The defect is in what is drawn, not in what is heard.
  'bad-colour-only': ['Read about', FIRST, 'and', SECOND, 'first.'],
  // One link, the whole sentence.
  'bad-merged': ['link Read about links in text and stand-alone links first.'],
};

for (const [slug, expected] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/C04/${slug}`, { waitUntil: 'load' });
    await expect(page.getByRole('heading', { name: 'Example', exact: true, level: 2 })).toBeVisible();
    await page.waitForTimeout(600);
    const { stops, reachedEnd } = await walkToEnd(page, voiceOver, browserName);
    console.log(`C04VO ${browserName} ${slug} | ${stops.join(' / ')}`);
    expect(reachedEnd, `${slug}: the walk reached the end of the screen`).toBe(true);
    const start = stops.indexOf(EXAMPLE);
    expect(start, `${slug}: reached the example`).toBeGreaterThanOrEqual(0);
    expect(stops.slice(start + 1), slug).toEqual(expected);
  });
}
