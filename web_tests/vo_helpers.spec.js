// The VoiceOver helpers must fail loudly. These checks need macOS (for
// osascript) but not VoiceOver itself.
import { test, expect } from '@playwright/test';
import { VO_HELP, phraseForMove, runAppleScript, stopsToEnd, untilQuiet } from './vo/vo_logic.js';

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

test('a different phrase in the same place is a stop', async () => {
  // An image that sits exactly where the row before it does.
  const result = await stopsToEnd(
    moves([['Row', 'a'], ['unexpected image', 'a'], ['unexpected image', 'a'], ['unexpected image', 'a']]),
    'start');
  expect(result).toEqual({ stops: ['Row', 'unexpected image'], reachedEnd: true });
});

test('a different phrase after one unmoved step is still a stop', async () => {
  const result = await stopsToEnd(
    moves([['Row', 'a'], ['', 'a'], ['late image', 'a'], ['', 'a'], ['', 'a']]), 'start');
  expect(result).toEqual({ stops: ['Row', 'late image'], reachedEnd: true });
});

test('a read that fails ends the walk with its error, not with an end of screen', async () => {
  const list = [['Row', 'a']];
  let i = 0;
  const step = async () => {
    if (i >= list.length) throw new Error('AppleScript failed: no speech');
    const [phrase, position] = list[i++];
    return { phrase, position };
  };
  await expect(stopsToEnd(step, 'start')).rejects.toThrow(/AppleScript failed/);
});

// phraseForMove: the phrase logged for a move replaces VoiceOver's help
// message, and nothing else.
const HELP = 'You are currently on a text field, inside of web content.';

test('VoiceOver\'s help message is recognised in both its wordings, and only at the start of a phrase', () => {
  const cases = [
    [HELP, true],
    ['You are currently on a button, inside of web content. To click this button, press Control-Option-Space.', true],
    // S08's ninth web recording (2026-11-28).
    ['You are currently in a empty group.', true],
    ['You are currently in a list, inside of web content.', true],
    // Ordinary speech with the same words, not at the start.
    ['Note: You are currently on a trial plan', false],
    ['Order 1 You are currently in a group', false],
    ['Status: you are currently on hold', false],
    // The words without the space after "on" or "in" that the message has.
    ['You are currently online', false],
    ['You are currently inside', false],
    ['you are currently on a button', false],
    ['', false],
  ];
  for (const [phrase, help] of cases) expect(VO_HELP.test(phrase), phrase).toBe(help);
});

test('a help message is replaced by the phrase logged for the same move', () => {
  expect(phraseForMove(HELP, 'Username edit text')).toBe('Username edit text');
  expect(phraseForMove('You are currently in a empty group.', 'Bread empty group (3 of 3) 3 of 3'))
    .toBe('Bread empty group (3 of 3) 3 of 3');
  expect(phraseForMove('Note: You are currently on a trial plan', 'something else')).toBe('Note: You are currently on a trial plan');
  expect(phraseForMove('Save button', 'something else')).toBe('Save button');
  // A failed read of the log is an empty phrase, not the help message.
  expect(phraseForMove(HELP, '')).toBe('');
});

test('the logged phrase stays with its move when an earlier move is dropped', async () => {
  // The first move neither moves the cursor nor speaks anew, so it is not a
  // stop. The field comes two moves later and still gets its own phrase.
  const made = [
    { direct: '', logged: 'Back button', position: 'start' },
    { direct: 'heading level 2 Example', logged: 'heading level 2 Example', position: 'a' },
    { direct: HELP, logged: 'Username edit text', position: 'b' },
    { direct: 'Changes: 0', logged: 'Changes: 0', position: 'c' },
  ];
  let i = 0;
  const step = async () => {
    const move = made[Math.min(i++, made.length - 1)];
    return { phrase: phraseForMove(move.direct, move.logged), position: move.position };
  };
  const result = await stopsToEnd(step, 'start');
  expect(result).toEqual({
    stops: ['heading level 2 Example', 'Username edit text', 'Changes: 0'],
    reachedEnd: true,
  });
});

// untilQuiet: driven by a made-up clock and a list of phrases, one for each
// read. Every sleep moves the clock on by the time asked for.
const fakeVoiceOver = (phrases) => {
  let time = 0;
  let reads = 0;
  return {
    read: async () => phrases[Math.min(reads++, phrases.length - 1)],
    sleep: async (ms) => { time += ms; },
    now: () => time,
    elapsed: () => time,
  };
};

test('quiet is reached once the phrase has stayed the same for the whole interval', async () => {
  const vo = fakeVoiceOver(['Back button']);
  const result = await untilQuiet({ ...vo, quietMs: 2000, limitMs: 10000 });
  expect(result).toEqual({ phrase: 'Back button', quiet: true });
  expect(vo.elapsed()).toBe(2000);
});

test('each new phrase starts the quiet interval again', async () => {
  // The button, its help message a second later, then an empty phrase.
  const vo = fakeVoiceOver(['Back', 'Back', 'Back', 'Back', 'You are currently on a button', 'You are currently on a button', '']);
  const result = await untilQuiet({ ...vo, quietMs: 2000, limitMs: 10000 });
  expect(result).toEqual({ phrase: '', quiet: true });
  // Six reads to reach the empty phrase (1500 ms), then two quiet seconds.
  expect(vo.elapsed()).toBe(3500);
});

test('speech that never stops is reported as not quiet, at the limit', async () => {
  let n = 0;
  const vo = fakeVoiceOver([]);
  const result = await untilQuiet({ ...vo, read: async () => `phrase ${n++}`, quietMs: 2000, limitMs: 10000 });
  expect(result.quiet).toBe(false);
  expect(vo.elapsed()).toBe(10000);
});

