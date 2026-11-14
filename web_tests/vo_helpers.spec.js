// The VoiceOver helpers must fail loudly. These checks need macOS (for
// osascript) but not VoiceOver itself.
import { test, expect } from '@playwright/test';
import { runAppleScript } from './vo/vo_helpers.js';

test.skip(process.platform !== 'darwin', 'osascript is macOS only');

test('a failing AppleScript rejects instead of returning empty speech', async () => {
  await expect(runAppleScript('error "capture is broken"')).rejects.toThrow(/AppleScript failed.*capture is broken/);
  await expect(runAppleScript('this is not applescript ((')).rejects.toThrow(/AppleScript failed/);
});

test('a working AppleScript returns its output, trimmed', async () => {
  await expect(runAppleScript('return "  one   two  "')).resolves.toBe('one two');
});
