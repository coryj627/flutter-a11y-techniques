// L4 on web for S15 Hints: what VoiceOver on macOS speaks for
// each example. Needs Guidepup's setup and macOS automation permissions on
// the machine. Run through `python3 tool/voiceover_web.py S15`, which also
// writes the transcript.
import { voiceOverTest as test } from '@guidepup/playwright';
import { expect } from '@playwright/test';
import { walkToEnd } from './vo_helpers.js';

const EXAMPLE = 'heading level 2 Example';
// The change count is the last element of every example.
const COUNT = 'Changes: 0';

// slug -> everything VoiceOver speaks after the "Example" heading and before
// the change count, in order, one entry for each element its cursor
// stops on. Because every stop is listed, the list also shows what is not
// spoken.
const RULE = '3 to 12 letters or numbers.';
const EXAMPLES = {
  // On web a hint is aria-description. VoiceOver reads it after the name
  // and before the role.
  'good-result': ['Favorite Adds this item to your favorites. button'],
  'good-row': ['Night Ferry The Lanterns Plays the song. button'],
  'good-cupertino': ['Share Shares the current page. button'],
  'good-custom': ['Archive Moves this message out of the inbox. button'],
  'good-field': [`Username ${RULE} edit text`, RULE],
  // Bad examples: the defect must be audible.
  'bad-gesture': ['Favorite Double tap to add this item to your favorites. button'],
  'bad-repeats-label': ['Delete Delete button'],
  'bad-control-type': ['Share This button shares the current page. button'],
  'bad-no-hint': ['Night Ferry The Lanterns button'],
  // The hint is not in the page at all (FL-040, FL-041).
  'bad-hint-detached': ['Favorite button'],
  // Read as the good field is: the tree test finds no rule on the page.
  'bad-hint-only': [`Username ${RULE} edit text`],
};

// On a text field with a description VoiceOver follows the field's own
// speech at once with its help message ("You are currently on a text
// field…"), and that message is then its last phrase. Guidepup's log has
// what was spoken for the move itself. It is used for such a stop only,
// and only when it agrees with the walk at every other stop, so the two
// records are known to line up.
const HELP = /^You are currently on /;
function withoutHelp(stops, log) {
  const aligned = stops.every((stop, i) => HELP.test(stop) || stop === log[i]);
  return aligned ? stops.map((stop, i) => (HELP.test(stop) ? log[i] : stop)) : stops;
}

for (const [slug, expected] of Object.entries(EXAMPLES)) {
  test(`voiceover reads ${slug}`, async ({ page, voiceOver, browserName }) => {
    await page.goto(`/#/t/S15/${slug}`, { waitUntil: 'load' });
    await expect(page.locator(`[flt-semantics-identifier="s15-${slug}-count"]`)).toBeVisible();
    const walk = await walkToEnd(page, voiceOver, browserName);
    const reachedEnd = walk.reachedEnd;
    const stops = withoutHelp(walk.stops, await voiceOver.spokenPhraseLog());
    console.log(`S15VO ${browserName} ${slug} | ${stops.join(' / ')}`);
    expect(reachedEnd, `${slug}: the walk reached the end of the screen`).toBe(true);
    const start = stops.indexOf(EXAMPLE);
    expect(start, `${slug}: reached the example`).toBeGreaterThanOrEqual(0);
    const content = Array.isArray(expected) ? expected : expected[browserName];
    // No fallback to another browser's speech: it differs, which is the point.
    expect(content, `${slug}: no expected speech for ${browserName}`).toBeDefined();
    expect(stops.slice(start + 1), slug).toEqual([...content, COUNT]);
  });
}
