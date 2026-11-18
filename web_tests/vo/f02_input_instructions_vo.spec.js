// L4 on web for F02 Input instructions: what VoiceOver on macOS speaks for
// each example. Needs Guidepup's setup and macOS automation permissions on
// the machine. Run through `python3 tool/voiceover_web.py F02`, which also
// writes the transcript.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { walkToEnd } from './vo_helpers.js';

const EXAMPLE = 'heading level 2 Example';
// The change count is the last element of every example. A walk made after
// typing "abc" ends on "Changes: 3".
const COUNT = (n) => `Changes: ${n}`;
const RULE = '4 to 10 characters, no spaces.';
const DISPLAY_RULE = 'Shown on your posts. 2 to 30 letters or numbers.';

const field = (page, id) => page.locator(`[flt-semantics-identifier="${id}"] input`);

// name -> { slug, fill: identifier of a field to type "abc" into first,
// content: everything VoiceOver speaks after the "Example" heading and before
// the change count, in order, one entry for each element its cursor stops
// on }. Because every stop is listed, the list also shows what is not
// spoken, and a stop with no speech, or with the speech of the stop before
// it, fails the comparison.
// A field VoiceOver reaches with text in it is read with the text first and
// then what the browser says about the caret: Chromium "Insertion at end of
// text.", WebKit "contents selected". VoiceOver's cursor moving onto a field
// also moves keyboard focus into it, in both browsers.
const FILLED = { chromium: 'abc Insertion at end of text.', webkit: 'abc contents selected' };

const WALKS = {
  // On web a hint is aria-description. VoiceOver reads it after the name
  // and before the role; the helper text is a stop of its own.
  'good-helper': { slug: 'good-helper', content: [`Username ${RULE} edit text`, RULE] },
  // The instruction is still read once the field has a value.
  'good-helper+filled': { slug: 'good-helper', fill: 'f02-good-helper-username',
    content: (b) => [`${FILLED[b]} Username ${RULE} edit text`, RULE] },
  'good-cupertino': { slug: 'good-cupertino', content: [`Username ${RULE} edit text`, RULE] },
  // The instruction is read before the field, and again with it.
  'good-before': { slug: 'good-before', content: [RULE, `Username ${RULE} edit text`] },
  // Bad examples: the defect must be audible.
  'bad-helper-only': { slug: 'bad-helper-only', content: ['Username edit text', RULE] },
  'bad-helper-only+filled': { slug: 'bad-helper-only', fill: 'f02-bad-helper-only-username',
    content: (b) => [`${FILLED[b]} Username edit text`, RULE] },
  // Moving VoiceOver onto the empty field focuses it, so Material shows the
  // placeholder and adds it to the name (FL-142): on the web the format is
  // heard on arrival. Chromium reads the new name without the role; the
  // role is not part of what is checked here, the format is.
  'bad-placeholder-format': { slug: 'bad-placeholder-format',
    content: { chromium: ['Date of birth DD/MM/YYYY'], webkit: ['Date of birth DD/MM/YYYY edit text'] } },
  // Once anything is typed the format is gone from the name.
  'bad-placeholder-format+filled': { slug: 'bad-placeholder-format', fill: 'f02-bad-placeholder-format-birthday',
    content: (b) => [`${FILLED[b]} Date of birth edit text`] },
  // The cut is on the screen only: VoiceOver reads the whole instruction.
  'bad-helper-cut-off': { slug: 'bad-helper-cut-off',
    content: [`Display name ${DISPLAY_RULE} edit text`, DISPLAY_RULE] },
};

for (const [name, walk] of Object.entries(WALKS)) {
  test(`voiceover reads ${name}`, async ({ page, voiceOver, browserName }) => {
    const { slug, fill } = walk;
    const content = typeof walk.content === 'function' ? walk.content(browserName)
      : Array.isArray(walk.content) ? walk.content : walk.content[browserName];
    // No fallback to another browser's speech: it differs, which is the point.
    expect(content, `${name}: no expected speech for ${browserName}`).toBeDefined();
    await page.goto(`/#/t/F02/${slug}`, { waitUntil: 'load' });
    await expect(page.locator(`[flt-semantics-identifier="f02-${slug}-count"]`)).toBeVisible();
    if (fill) {
      // Flutter attaches its text editing a moment after the tree appears.
      await page.waitForTimeout(600);
      await field(page, fill).click();
      await page.waitForTimeout(250);
      await page.keyboard.type('abc', { delay: 40 });
      await expect(field(page, fill)).toHaveValue('abc');
    }
    // VoiceOver follows a described text field with its help message at
    // once; at such a move the walk records Guidepup's phrase for that move
    // (vo_helpers.js, phraseForMove).
    const { stops, reachedEnd } = await walkToEnd(page, voiceOver, browserName, 40, { loggedForHelp: true });
    console.log(`F02VO ${browserName} ${name} | ${stops.join(' / ')}`);
    expect(reachedEnd, `${name}: the walk reached the end of the screen`).toBe(true);
    const start = stops.indexOf(EXAMPLE);
    expect(start, `${name}: reached the example`).toBeGreaterThanOrEqual(0);
    expect(stops.slice(start + 1), name).toEqual([...content, COUNT(fill ? 3 : 0)]);
  });
}
