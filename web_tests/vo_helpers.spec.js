// The VoiceOver helpers must fail loudly. These checks need macOS (for
// osascript) but not VoiceOver itself.
import { test, expect } from '@playwright/test';
import { runAppleScript, stopsToEnd } from './vo/vo_helpers.js';

test.skip(process.platform !== 'darwin', 'osascript is macOS only');

test('a failing AppleScript rejects instead of returning empty speech', async () => {
  await expect(runAppleScript('error "capture is broken"')).rejects.toThrow(/AppleScript failed.*capture is broken/);
  await expect(runAppleScript('this is not applescript ((')).rejects.toThrow(/AppleScript failed/);
});

test('a working AppleScript returns its output, trimmed', async () => {
  await expect(runAppleScript('return "  one   two  "')).resolves.toBe('one two');
});

// stopsToEnd: the walk to the end of the screen, driven here by a list of
// made-up moves instead of VoiceOver.
const moves = (list) => {
  let i = 0;
  return async () => {
    const [phrase, position] = list[Math.min(i++, list.length - 1)];
    return { phrase, position };
  };
};

test('the walk ends when the cursor stays put twice, and keeps every stop', async () => {
  const result = await stopsToEnd(moves([['One', 'a'], ['Two', 'b'], ['Two', 'b'], ['Two', 'b']]), 'start');
  expect(result).toEqual({ stops: ['One', 'Two'], reachedEnd: true });
});

test('two elements that read the same are two stops', async () => {
  const result = await stopsToEnd(
    moves([['Name', 'a'], ['', 'b'], ['', 'b'], ['', 'b']]), 'start');
  expect(result).toEqual({ stops: ['Name', ''], reachedEnd: true });
});

test('silence or a repeat is not taken for the end when the cursor moved', async () => {
  // After "Row" VoiceOver reports nothing, then reads an image: both are
  // stops, because the cursor moved each time.
  const result = await stopsToEnd(
    moves([['Row', 'a'], ['', 'b'], ['image', 'c'], ['image', 'c'], ['image', 'c']]), 'start');
  expect(result).toEqual({ stops: ['Row', '', 'image'], reachedEnd: true });
});

test('one move that stays put is not the end', async () => {
  const result = await stopsToEnd(
    moves([['One', 'a'], ['One', 'a'], ['Two', 'b'], ['Two', 'b'], ['Two', 'b']]), 'start');
  expect(result).toEqual({ stops: ['One', 'Two'], reachedEnd: true });
});

test('a walk that runs out of moves did not reach the end', async () => {
  let n = 0;
  const result = await stopsToEnd(async () => ({ phrase: `p${n}`, position: `at${n++}` }), 'start', 5);
  expect(result.reachedEnd).toBe(false);
  expect(result.stops).toHaveLength(5);
});
