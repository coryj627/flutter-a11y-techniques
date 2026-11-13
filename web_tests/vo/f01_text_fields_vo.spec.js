// L4 on web for F01 Text fields and labels: what VoiceOver on macOS speaks.
// Needs Guidepup's setup and macOS automation permissions on the machine.
// Run through `python3 tool/voiceover_web.py F01`, which also writes the transcript.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { walkFromBack } from './vo_helpers.js';

const field = (page, id) =>
  page.locator(`[flt-semantics-identifier="${id}"]`).locator('input,textarea');

// name -> { slug, fill: id of a field to type "abc" into first, must /
// mustNot: patterns for single spoken phrases, and per-browser extras where
// the browsers differ }.
const NAMED = /^Email edit text$/;
const UNNAMED = /^edit text blank$/;
const WALKS = {
  'good-label': { slug: 'good-label', must: [NAMED, /^Message text entry area$/], mustNot: [] },
  // The label is still spoken once the field has a value.
  'good-label+filled': { slug: 'good-label', fill: 'f01-good-label-email', must: [/^abc .*Email edit text$/], mustNot: [] },
  // The visible label is not read a second time as separate text.
  'good-label-above': { slug: 'good-label-above', must: [/^Full name edit text$/], mustNot: [/^Full name$/] },
  'good-cupertino': { slug: 'good-cupertino', must: [NAMED], mustNot: [/^Email$/] },
  // Bad examples: the defect must be audible.
  'bad-placeholder-only': { slug: 'bad-placeholder-only', must: [NAMED], mustNot: [] },
  // Flutter drops the label once text is typed; VoiceOver does not use the
  // placeholder attribute that is left, so the field has no name.
  'bad-placeholder-only+filled': { slug: 'bad-placeholder-only',
    fill: 'f01-bad-placeholder-only-email', must: [/^abc .*edit text$/], mustNot: [/Email/] },
  // "Email" is read as separate text. Chromium then reads a field with no
  // name. WebKit guesses a name from the text next to the field, so there the
  // defect cannot be heard, though the tree shows the field is unnamed.
  'bad-unassociated-label': { slug: 'bad-unassociated-label', must: [/^Email$/], mustNot: [], chromium: [UNNAMED], webkit: [NAMED] },
  // WebKit reads "edit text blank". In Chromium an empty field with no name
  // is passed over in silence. Either way nothing names the field.
  'bad-no-label': { slug: 'bad-no-label', must: [], mustNot: [/\S+ edit text$/],
    webkit: [UNNAMED] },
  'bad-name-mismatch': { slug: 'bad-name-mismatch', must: [/^Contact address edit text$/], mustNot: [NAMED] },
  'bad-cupertino-placeholder': { slug: 'bad-cupertino-placeholder', must: [NAMED], mustNot: [] },
  'bad-cupertino-placeholder+filled': { slug: 'bad-cupertino-placeholder',
    fill: 'f01-bad-cupertino-placeholder-email', must: [/^abc .*edit text$/], mustNot: [/Email/] },
  'bad-cupertino-prefix': { slug: 'bad-cupertino-prefix', must: [/^Email$/], mustNot: [], chromium: [UNNAMED], webkit: [NAMED] },
};

for (const [name, walk] of Object.entries(WALKS)) {
  const { slug, fill, must, mustNot } = walk;
  test(`voiceover reads ${name}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/F01/${slug}`, { waitUntil: 'load' });
    await expect(page.getByRole('heading', { name: 'Example', level: 2 })).toBeVisible();
    if (fill) {
      // Flutter attaches its text editing a moment after the tree appears.
      await page.waitForTimeout(600);
      await field(page, fill).click();
      await page.waitForTimeout(250);
      await page.keyboard.type('abc', { delay: 40 });
      await expect(field(page, fill)).toHaveValue('abc');
    }
    // Walk until the last field is read. Chromium has silent stops between
    // some elements, so steps are not counted; a field that is never
    // announced ends the walk at the step limit.
    const last = slug === 'good-label' ? /text entry area$/ : /edit text( blank)?$/;
    const spoken = await walkFromBack(page, voiceOver, browserName, (p) => last.test(p), 9);
    console.log(`F01VO ${browserName} ${name} | ${spoken.join(' / ')}`);
    expect(spoken[0], name).toMatch(/^heading level 1 /);
    // Only what follows the "Example" heading is the example itself.
    const example = spoken.slice(spoken.indexOf('heading level 2 Example') + 1);
    const heard = (pattern) => example.some((phrase) => pattern.test(phrase));
    for (const pattern of [...must, ...(walk[browserName] ?? [])]) {
      expect(heard(pattern), `${name}: expected ${pattern} in ${JSON.stringify(example)}`).toBe(true);
    }
    for (const pattern of mustNot) {
      expect(heard(pattern), `${name}: did not expect ${pattern} in ${JSON.stringify(example)}`).toBe(false);
    }
  });
}
