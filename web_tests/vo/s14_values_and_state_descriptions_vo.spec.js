// L4 on web for S14 Values and state descriptions: what VoiceOver on macOS
// speaks for each example. Needs Guidepup's setup and macOS automation
// permissions on the machine. Run through `python3 tool/voiceover_web.py
// S14`, which also writes the transcript.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { walkFromBack, walkToEnd } from './vo_helpers.js';

const EXAMPLE = 'heading level 2 Example';
// The change count is the last element of every example.
const COUNT = 'Changes: 0';

// slug -> everything VoiceOver speaks after the "Example" heading and before
// the change count, in order, one entry for each element its cursor stops
// on. On web a value is read as part of the name (FL-037).
const EXAMPLES = {
  'good-step': ['Progress Step 2 of 4', 'Next step button'],
  'good-button-value': ['Repeat Off button'],
  // Bad examples: the defect must be audible.
  'bad-step-no-value': ['1', '2', '3', '4', 'Next step button'],
  'bad-button-no-value': ['Repeat button'],
  // The state is said twice, once inside the name (FL-036).
  'bad-value-on-switch': ['Home alarm Deactivated off switch'],
};

for (const [slug, expected] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/S14/${slug}`, { waitUntil: 'load' });
    await expect(page.locator(`[flt-semantics-identifier="s14-${slug}-count"]`)).toBeVisible();
    const { stops, reachedEnd } = await walkToEnd(page, voiceOver, browserName);
    console.log(`S14VO ${browserName} ${slug} | ${stops.join(' / ')}`);
    expect(reachedEnd, `${slug}: the walk reached the end of the screen`).toBe(true);
    const start = stops.indexOf(EXAMPLE);
    expect(start, `${slug}: reached the example`).toBeGreaterThanOrEqual(0);
    expect(stops.slice(start + 1), slug).toEqual([...expected, COUNT]);
  });
}

// The slider's own phrase, not the title or the defect text.
const isSlider = (p) => /slider/.test(p) && !/^(heading|Defect|Good|Bad)/.test(p);

// The adjustable examples are sliders on web. As in S01
// (bad-slider-name-web): in Chromium VoiceOver reads the element around the
// slider as a group with the name, then the slider with its value text and
// no name (FL-028). The walk stops at the slider. Playwright's WebKit build
// is recorded and not judged: there the cursor often leaves the page before
// it reaches a slider, and this test cannot tell that from a fault of the
// page. `material` is for a Material Slider, which needs the click at a
// point (FL-029).
const SLIDERS = {
  'good-rating': { name: 'Rating', has: '3 out of 5' },
  'good-slider-format': { name: 'Timer', has: '15 minutes', material: true },
  'bad-rating-no-value': { name: 'Rating', lacks: 'out of 5' },
  // Heard as the good one is: the defect appears only after a change, which
  // the tree tests make.
  'bad-stale-value': { name: 'Rating', has: '3 out of 5' },
};

for (const [slug, { name, has, lacks, material }] of Object.entries(SLIDERS)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/S14/${slug}`, { waitUntil: 'load' });
    await expect(page.locator(`[flt-semantics-identifier="s14-${slug}-count"]`)).toBeVisible();
    const spoken = await walkFromBack(page, voiceOver, browserName, isSlider, 12, material === true);
    console.log(`S14VO ${browserName} ${slug} | ${spoken.join(' / ')}`);
    // Capture is working and the cursor started in the page.
    expect(spoken[0], slug).toMatch(/^heading level 1 /);
    if (browserName !== 'chromium') return;
    const slider = spoken.filter(isSlider);
    expect(spoken, slug).toContain(`${name} group`);
    expect(slider, slug).toHaveLength(1);
    if (has) expect(slider[0], slug).toContain(has);
    if (lacks) expect(slider[0], slug).not.toContain(lacks);
    expect(slider[0], slug).not.toContain(name);
  });
}
