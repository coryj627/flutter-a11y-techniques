// L3 for S16 Language of page and parts on web: the page's `lang`, the
// `lang` of each part, and the language the browser takes each text to be
// in, by its own `:lang()` matching. Spec:
// docs/specs/S16-language-page-parts.md. Runs against the release build in
// build/web.
//
// Chromium's accessibility tree, read over the DevTools protocol in the
// probe, holds no language for any node (docs/evidence/probes/s16/web.txt),
// so the language is read from the page: the `lang` attributes, and
// `Element.matches(':lang(x)')`, which is the browser's own reading of them
// (the HTML standard's "language of a node"). What VoiceOver does with it
// is the web VoiceOver spec's, which can show the words only.
import { test, expect } from '@playwright/test';
import { byId, technique } from './support/techniques.js';
import { BROWSERS, EXAMPLE_HEADING, EXAMPLE_SCREENS, EXPECTED_STOPS, helpRole, judgeExampleWalk, judgeTranscript, runWalks, screenStops, spokenRole } from './vo/s16_vo_walks.js';
import { existsSync, readFileSync } from 'node:fs';

// The example screen's own "Example" heading; the technique's page has
// "Good examples" and "Bad examples", so the name must match exactly.
const exampleHeading = (page) => page.getByRole('heading', { name: 'Example', exact: true, level: 2 });
const { open } = technique('S16', { ready: exampleHeading, settle: 600 });

const LEAD = 'The sign at the door reads:';
const PASSAGE = 'Bienvenue à tous nos visiteurs.';
const SENTENCE = 'The guide said bon voyage as we left.';
const LANGUAGES = [
  { code: 'fr', name: 'Français', english: 'French' },
  { code: 'es', name: 'Español', english: 'Spanish' },
  { code: 'de', name: 'Deutsch', english: 'German' },
];
// The languages each text is checked against. A text matches the
// language of its nearest `lang` and every shorter prefix of it: "en-US"
// matches "en" and "en-US".
const CHECKED = ['en', 'en-US', 'fr', 'fr-FR', 'es', 'de'];

/** The `lang` of the page's root element. */
const pageLang = (page) => page.evaluate(() => document.documentElement.getAttribute('lang'));

/**
 * Every semantics element of the page whose own text or label is `text`:
 * the `lang` of the nearest element above it or on it that has one, every
 * `lang` on the way from it to the page's root, and the languages of
 * CHECKED that it matches.
 */
function languageOf(page, text) {
  return page.evaluate(({ text, checked }) => {
    const own = (e) =>
      (e.getAttribute('aria-label') || '') +
      [...e.childNodes].filter((n) => n.nodeType === 3).map((n) => n.textContent).join('');
    const host = document.querySelector('flt-semantics-host');
    return [...host.querySelectorAll('*')]
      .filter((e) => own(e).trim() === text)
      .map((e) => {
        const langs = [];
        for (let a = e; a; a = a.parentElement) if (a.hasAttribute('lang')) langs.push(a.getAttribute('lang'));
        return {
          nearest: e.closest('[lang]')?.getAttribute('lang') ?? null,
          langs,
          matches: checked.filter((l) => e.matches(`:lang(${l})`)),
        };
      });
  }, { text, checked: CHECKED });
}

/** Expects exactly one element with `text`, in `lang` and no other language. */
async function expectIn(page, text, { nearest, langs, matches }) {
  expect(await languageOf(page, text)).toEqual([{ nearest, langs, matches }]);
}

const ENGLISH = { nearest: 'en-US', langs: ['en-US'], matches: ['en', 'en-US'] };

/** What the "Chosen" line under the language menu of `slug` says. */
const chosen = (page, slug) => byId(page, `s16-${slug}-chosen`);

test.describe('the language of the page', () => {
  // 3.1.1: the app's language, en-US (MaterialApp's default supportedLocales;
  // the app sets no locale), on the page's root, for every example but
  // bad-override, from a fresh load.
  for (const slug of ['good-passage', 'good-phrase', 'good-language-menu', 'bad-unmarked', 'bad-title-in-tile', 'bad-region-tag']) {
    test(`${slug}: the page's lang is en-US, and the screen's title is English`, async ({ page }) => {
      await open(page, slug);
      expect(await pageLang(page)).toBe('en-US');
      await expectIn(page, 'Example', ENGLISH);
    });
  }

  test('the host page says lang="en" before Flutter starts, and Flutter sets en-US', async ({ page }) => {
    // The HTML file's own lang (web/index.html), read from the server, and
    // the page's once the app has started.
    const response = await page.request.get('/');
    expect(await response.text()).toContain('<html lang="en">');
    await open(page, 'good-passage');
    expect(await pageLang(page)).toBe('en-US');
  });
});

test.describe('good examples', () => {
  test('good-passage: the passage is French, and the line before it English', async ({ page }) => {
    await open(page, 'good-passage');
    await expectIn(page, PASSAGE, { nearest: 'fr', langs: ['fr', 'en-US'], matches: ['fr'] });
    await expectIn(page, LEAD, ENGLISH);
    // One element in the page has a lang of its own, the passage's.
    expect(await page.locator('flt-semantics-host [lang]').evaluateAll((els) => els.map((e) => e.getAttribute('lang')))).toEqual(['fr']);
  });

  // FL-020: on the web a phrase marked with TextSpan(locale:) is not
  // marked. The sentence is one element in the page's language, with no
  // lang inside it; written to fail when the phrase gets a lang.
  test('good-phrase: the sentence is one English element, and the phrase has no lang of its own (FL-020)', async ({ page }) => {
    await open(page, 'good-phrase');
    await expectIn(page, SENTENCE, ENGLISH);
    await expect(page.locator('flt-semantics-host [lang]')).toHaveCount(0);
    expect(await languageOf(page, 'bon voyage')).toEqual([]);
  });

  test('good-language-menu: each tile is a button in its own language, and the Chosen line English', async ({ page }) => {
    await open(page, 'good-language-menu');
    for (const l of LANGUAGES) {
      const tile = byId(page, `s16-good-language-menu-${l.code}`);
      await expect(tile).toHaveRole('button');
      await expect(tile).toHaveAccessibleName(l.name);
      await expectIn(page, l.name, { nearest: l.code, langs: [l.code, 'en-US'], matches: [l.code] });
    }
    await expectIn(page, 'Chosen: none', ENGLISH);
  });
});

// Both language menus: a click on each tile, and Tab then Enter or Space,
// each from a fresh load, choose that language. In bad-title-in-tile this
// is the positive control: the tiles work, and only their language is lost.
for (const slug of ['good-language-menu', 'bad-title-in-tile']) {
  test.describe(`${slug}: each tile chooses its language`, () => {
    for (const [i, l] of LANGUAGES.entries()) {
      test(`a click on ${l.name} chooses ${l.english}`, async ({ page }) => {
        await open(page, slug);
        await expect(chosen(page, slug)).toHaveText('Chosen: none');
        await byId(page, `s16-${slug}-${l.code}`).click();
        await expect(chosen(page, slug)).toHaveText(`Chosen: ${l.english}`);
      });

      for (const key of ['Enter', 'Space']) {
        test(`Tab to ${l.name}, then ${key}, chooses ${l.english}`, async ({ page }) => {
          await open(page, slug);
          await expect(chosen(page, slug)).toHaveText('Chosen: none');
          // Back, then the tiles in order.
          for (let t = 0; t < i + 2; t++) {
            await page.keyboard.press('Tab');
            await page.waitForTimeout(150);
          }
          const tile = byId(page, `s16-${slug}-${l.code}`);
          await expect.poll(() => tile.evaluate((e) => e === document.activeElement)).toBe(true);
          // Sent once: the key is what is tested.
          await page.keyboard.press(key);
          await expect(chosen(page, slug)).toHaveText(`Chosen: ${l.english}`);
        });
      }
    }
  });
}

test.describe('bad examples have their defect', () => {
  test('bad-unmarked: the passage is in the page\'s language, English', async ({ page }) => {
    await open(page, 'bad-unmarked');
    await expectIn(page, PASSAGE, ENGLISH);
    await expect(page.locator('flt-semantics-host [lang]')).toHaveCount(0);
  });

  test('bad-title-in-tile: each tile is a button in the page\'s language, English (FL-361)', async ({ page }) => {
    await open(page, 'bad-title-in-tile');
    for (const l of LANGUAGES) {
      const tile = byId(page, `s16-bad-title-in-tile-${l.code}`);
      await expect(tile).toHaveRole('button');
      await expect(tile).toHaveAccessibleName(l.name);
      await expectIn(page, l.name, ENGLISH);
    }
    await expect(page.locator('flt-semantics-host [lang]')).toHaveCount(0);
  });

  // FL-020: a locale with a country is written with an underscore, which is
  // not a language tag, and the browser takes the passage to be in no
  // language of CHECKED. The control: the same browser, on a plain element
  // with lang="fr-FR", matches French.
  test('bad-region-tag: the passage\'s lang is fr_FR, which the browser does not match as French (FL-020)', async ({ page }) => {
    await open(page, 'bad-region-tag');
    await expectIn(page, PASSAGE, { nearest: 'fr_FR', langs: ['fr_FR', 'en-US'], matches: [] });
    await expectIn(page, LEAD, ENGLISH);
    const control = await page.evaluate((checked) => {
      const p = document.createElement('p');
      p.setAttribute('lang', 'fr-FR');
      document.body.append(p);
      const m = checked.filter((l) => p.matches(`:lang(${l})`));
      p.remove();
      return m;
    }, CHECKED);
    expect(control).toEqual(['fr', 'fr-FR']);
  });

  // FL-360: Localizations.override sets the app's language, the page's lang,
  // to its own, and nothing sets it back when the screen closes.
  test('bad-override: the page\'s lang becomes fr, and every text on the screen is French (FL-360)', async ({ page }) => {
    await open(page, 'bad-override');
    expect(await pageLang(page)).toBe('fr');
    const french = { nearest: 'fr', langs: ['fr'], matches: ['fr'] };
    await expectIn(page, 'Example', french);
    await expectIn(page, LEAD, french);
    // The passage's own element has lang="fr" as well.
    await expectIn(page, PASSAGE, { nearest: 'fr', langs: ['fr', 'fr'], matches: ['fr'] });
  });

  // The witness that Back took effect is the technique's page on the screen
  // and the example's heading gone; the control is good-passage, whose
  // Back leaves the page English, which shows that the test can see the
  // page's lang go back.
  for (const [slug, after] of [['bad-override', 'fr'], ['good-passage', 'en-US']]) {
    test(`${slug}: after Back to the technique's page, the page's lang is ${after}${slug === 'bad-override' ? ' (FL-360)' : ' (the control)'}`, async ({ page }) => {
      await open(page, slug);
      await page.getByRole('button', { name: 'Back' }).click();
      await expect(page.getByRole('heading', { name: 'Good examples', level: 2 })).toBeVisible();
      await expect(exampleHeading(page)).toHaveCount(0);
      expect(await pageLang(page)).toBe(after);
      const title = after === 'fr'
        ? { nearest: 'fr', langs: ['fr'], matches: ['fr'] }
        : ENGLISH;
      // The page's "Good examples" heading, and the technique doc's, which
      // the page shows below it: every one in the page's language.
      const found = await languageOf(page, 'Good examples');
      expect(found.length).toBeGreaterThanOrEqual(1);
      for (const f of found) expect(f).toEqual(title);
    });
  }
});

test.describe('the stops the VoiceOver spec expects above each example', () => {
  for (const [slug, [title, ...lines]] of Object.entries(EXAMPLE_SCREENS)) {
    test(`${slug} shows its title and its lines`, async ({ page }) => {
      await open(page, slug);
      await expect(page.getByRole('heading', { name: title, exact: true, level: 1 })).toHaveCount(1);
      for (const line of lines) await expect(page.getByText(line, { exact: true })).toHaveCount(1);
    });
  }
});

const VO_HELP_PREFIX = /^You are currently on /;

// The VoiceOver judge (web_tests/vo/s16_vo_walks.js, S08's), on made-up
// walks. Each test names every case it holds, and fails on the first case
// whose verdict is not the one given, with the case's name.
test.describe('the VoiceOver example walks are judged on every walk', () => {
  const own = screenStops('good-language-menu');
  const expected = EXPECTED_STOPS['good-language-menu'];
  const [fr, es, de, chosenLine] = expected;
  const HELP = 'You are currently on a button, inside of web content. To click this button, press Control-Option-Space.';
  const TEXT_FIELD_HELP = 'You are currently on a text field, inside of web content.';
  const HEADING_HELP = 'You are currently on a heading level 1, inside of web content.';
  const screen = (...content) => [...own, EXAMPLE_HEADING, ...content];
  const whole = screen(...expected);
  const n = whole.length;
  // One position per stop, each new but where `same` lists the stops (by
  // index) that are at the position of the stop before them.
  const at = (stops, same = []) => {
    const out = [];
    stops.forEach((_, i) => out.push(same.includes(i) ? out[i - 1] : `p${i}`));
    return out;
  };
  const check = (cases, judge) => {
    for (const [what, verdict, ...args] of cases) {
      expect(judge(...args).verdict, what).toBe(verdict);
    }
  };

  test('the judge: whole screens, wrong readings, short walks, and empty captures', () => {
    check([
      ['the whole screen, every stop in its place', 'complete', whole, true],
      ['a tile read without its role', 'wrong', screen('Français', es, de, chosenLine), true],
      ['a stop read in other words', 'wrong', screen(fr, es, de, 'Chosen: French'), true],
      ['a tile missing', 'wrong', screen(fr, de, chosenLine), true],
      ['the last stop missing', 'wrong', screen(fr, es, de), true],
      ['the tiles in another order', 'wrong', screen(es, fr, de, chosenLine), true],
      ['a stop after the last expected one', 'wrong', [...whole, 'Extra'], true],
      ['another example\'s screen', 'wrong', [...screenStops('bad-title-in-tile'), EXAMPLE_HEADING, ...expected], true],
      ['an empty stop put in, so that every later stop comes late', 'wrong', screen('', ...expected), true],
      ['the title read as an empty phrase, every later stop right', 'incomplete', ['', ...own.slice(1), EXAMPLE_HEADING, ...expected], true],
      ['a tile read as an empty phrase, every other stop right', 'incomplete', screen(fr, '', de, chosenLine), true],
      ['an empty first stop and a wrong reading later', 'wrong', ['', ...own.slice(1), EXAMPLE_HEADING, 'Français', es, de, chosenLine], true],
      ['an empty first stop and a walk that reached the end short', 'wrong', ['', ...own.slice(1), EXAMPLE_HEADING, fr], true],
      ['an empty phrase after the last expected stop', 'wrong', [...whole, ''], true],
      ['every stop an empty phrase', 'incomplete', Array(n).fill(''), true],
      ['a help message with no positions recorded', 'wrong', [...whole, HELP], true],
      ['no title', 'wrong', [own[1], EXAMPLE_HEADING, ...expected], true],
      ['no heading', 'wrong', [...own, ...expected], true],
      ['an empty walk cut short', 'incomplete', [], false],
      ['a walk cut short after the heading', 'incomplete', screen(), false],
      ['every stop read, but the end not reached', 'incomplete', whole, false],
    ], (stops, reachedEnd) => judgeExampleWalk(stops, reachedEnd, expected, own));
  });

  test('a help message is left out only when tied to the stop before it, by position and spoken role', () => {
    check([
      ['help after the last tile\'s stop, at its position', 'complete',
        screen(fr, es, de, HELP, chosenLine), at(screen(fr, es, de, HELP, chosenLine), [own.length + 4])],
      ['help at a new position after the whole screen (an extra element)', 'wrong', [...whole, HELP], at([...whole, HELP])],
      ['a text field\'s help at a new position after the whole screen', 'wrong', [...whole, TEXT_FIELD_HELP], at([...whole, TEXT_FIELD_HELP])],
      ['button help after a text with no role, at its position', 'wrong', [...whole, HELP], at([...whole, HELP], [n])],
      ['help naming another role than the stop before it, at its position', 'wrong',
        screen(fr, TEXT_FIELD_HELP, es, de, chosenLine), at(screen(fr, TEXT_FIELD_HELP, es, de, chosenLine), [own.length + 2])],
      ['help in place of an expected stop', 'wrong', screen(fr, HELP, de, chosenLine), at(screen(fr, HELP, de, chosenLine))],
      ['help after an empty stop, at its position', 'wrong', screen(fr, '', HELP, de, chosenLine),
        at(screen(fr, '', HELP, de, chosenLine), [own.length + 3])],
      ['help with positions of the wrong length', 'wrong', screen(fr, HELP, es, de, chosenLine), at(whole)],
      ['help and a wrong reading', 'wrong', screen('Français', HELP, es, de, chosenLine),
        at(screen('Français', HELP, es, de, chosenLine), [own.length + 2])],
      // helpRole gives "heading level 1", which is not spokenRole's
      // "heading": a made-up heading help is not left out (S08's rule errs
      // toward failing).
      ['a heading help with its level after the title, at its position', 'wrong', [own[0], HEADING_HELP, ...whole.slice(1)],
        at([own[0], HEADING_HELP, ...whole.slice(1)], [1])],
      ['button help after the title heading, at its position', 'wrong', [own[0], HELP, ...whole.slice(1)],
        at([own[0], HELP, ...whole.slice(1)], [1])],
      ['no help message', 'complete', whole, at(whole)],
    ], (stops, positions) => judgeExampleWalk(stops, true, expected, own, positions));
  });

  test('a reading\'s spoken role comes from its role part only, and a help message names its role', () => {
    const roles = [
      ['heading level 1 Language menu', 'heading'],
      ['heading level 2 Example', 'heading'],
      ['Français button', 'button'],
      ['Chosen: none', null],
      ['The sign at the door reads:', null],
      ['Good example for Language of page and parts. Material.', null],
      ['Defect: Each language is read as English.', null],
    ];
    for (const [reading, role] of roles) expect(spokenRole(reading), reading).toBe(role);
    expect(helpRole(HELP)).toBe('button');
    expect(helpRole(TEXT_FIELD_HELP)).toBe('text field');
    expect(helpRole('Chosen: none')).toBe(null);
  });

  test('every screen: a bad example\'s own stops end with its defect, no screen has a custom solution note, and no expected stop is empty or help', () => {
    for (const slug of Object.keys(EXAMPLE_SCREENS)) {
      if (slug.startsWith('bad-')) expect(screenStops(slug).at(-1), slug).toMatch(/^Defect: /);
      expect(screenStops(slug).some((s) => s.startsWith('Custom solution')), slug).toBe(false);
    }
    for (const [slug, stops] of Object.entries(EXPECTED_STOPS)) {
      for (const s of stops) expect(s !== '' && !VO_HELP_PREFIX.test(s), `${slug}: "${s}"`).toBe(true);
    }
  });

  test('walks are made again only while incomplete, at most three, and every try is logged', async () => {
    const judge = (stops, reachedEnd) => judgeExampleWalk(stops, reachedEnd, expected, own);
    const right = { stops: whole, reachedEnd: true };
    const short = { stops: screen(fr), reachedEnd: false };
    const wrong = { stops: screen('Français', es, de, chosenLine), reachedEnd: true };
    const emptyTitle = { stops: ['', ...own.slice(1), EXAMPLE_HEADING, ...expected], reachedEnd: true };
    const pastEnd = { stops: [...whole, ''], reachedEnd: true };
    const cases = [
      ['a wrong reading, then a right walk', [wrong, right], 'wrong', 1],
      ['a complete walk plus an empty stop past the end, then a right walk', [pastEnd, right], 'wrong', 1],
      ['an empty first stop, then a right walk', [emptyTitle, right], 'complete', 2],
      ['an empty first stop, then a wrong reading, then a right walk', [emptyTitle, wrong, right], 'wrong', 2],
      ['three empty captures, then a right walk', [emptyTitle, emptyTitle, emptyTitle, right], 'incomplete', 3],
      ['a short walk, then a wrong one, then a right one', [short, wrong, right], 'wrong', 2],
      ['a short walk, then a right one', [short, right], 'complete', 2],
      ['three short walks, then a right one', [short, short, short, right], 'incomplete', 3],
    ];
    for (const [what, walks, verdict, made] of cases) {
      let i = 0;
      const logged = [];
      const result = await runWalks(async () => walks[i++], judge, { log: (w, stops, judged) => logged.push([w, judged.verdict]) });
      expect(result.verdict, what).toBe(verdict);
      expect(i, `${what}: walks made`).toBe(made);
      expect(logged.map(([w]) => w), `${what}: every try logged`).toEqual(Array.from({ length: made }, (_, k) => k + 1));
    }
  });
});

// The committed web VoiceOver transcript, judged again from the stops it
// recorded (judgeTranscript in web_tests/vo/s16_vo_walks.js): every
// browser and example once, walks in order, the last complete, the screen's
// own stops included. Made-up transcripts test the judge first.
test.describe('the web VoiceOver transcript is judged again from what it recorded', () => {
  const row = (slug, n, stops, verdict = 'complete', reason = 'the whole screen, every stop in its place') =>
    `| \`${slug}-walk-${n}\` | ${stops.join(' / ') || '(nothing)'} (${verdict}: ${reason}) |`;
  const whole = (slug) => [...screenStops(slug), EXAMPLE_HEADING, ...EXPECTED_STOPS[slug]];
  const section = (browser, rows) => ['', `## ${browser}`, '', '| Example | Spoken, in order |', '| --- | --- |', ...rows];
  const transcript = (rowsFor) => ['# S16 Language of page and parts: VoiceOver transcript (web, macOS)', '',
    'Result: PASS', ...BROWSERS.flatMap((b) => section(b, rowsFor(b)))].join('\n');
  const right = (b) => Object.keys(EXAMPLE_SCREENS).map((slug) => row(slug, 1, whole(slug)));

  test('made-up transcripts: a right one passes, and each wrong one names its problem', () => {
    const passage = row('good-passage', 1, whole('good-passage'));
    const short = (slug) => row(slug, 1, whole(slug).slice(0, 3), 'incomplete', 'the walk was cut short');
    const cases = [
      ['a whole walk of every example in both browsers', transcript(right), true],
      ['a short first walk, then a complete second', transcript((b) => right(b).flatMap((r, i) => (i === 0 ? [short('good-passage'), r.replace('-walk-1`', '-walk-2`')] : [r]))), true],
      ['fourteen copies of one row', transcript(() => Array(7).fill(passage)), false],
      ['one row twice', transcript((b) => [...right(b), passage]), false],
      ['an example missing in one browser', transcript((b) => (b === 'webkit' ? right(b).slice(1) : right(b))), false],
      ['a browser section missing', ['Result: PASS', ...section('chromium', right('chromium'))].join('\n'), false],
      ['a browser section twice', [transcript(right), ...section('webkit', right('webkit'))].join('\n'), false],
      ['an unknown browser section', [transcript(right), ...section('firefox', [])].join('\n'), false],
      ['an unknown example', transcript((b) => [...right(b), row('good-other', 1, whole('good-passage'))]), false],
      ['a malformed row', transcript((b) => [...right(b), '| `good-passage-walk-x` | something |']), false],
      ['a row outside any section', [passage, transcript(right)].join('\n'), false],
      ['walk 2 with no walk 1', transcript((b) => right(b).map((r, i) => (i === 0 ? r.replace('-walk-1`', '-walk-2`') : r))), false],
      ['the last walk recorded wrong', transcript((b) => right(b).map((r, i) => (i === 0 ? r.replace('(complete:', '(wrong:') : r))), false],
      ['a short walk as the last', transcript((b) => right(b).map((r, i) => (i === 0 ? short('good-passage') : r))), false],
      ['a complete walk after a wrong one', transcript((b) => right(b).flatMap((r, i) => (i === 0 ? [row('good-passage', 1, ['x'], 'wrong', 'x'), r.replace('-walk-1`', '-walk-2`')] : [r]))), false],
      ['recorded complete, but only what follows the heading (the first recording\'s form)',
        transcript((b) => Object.keys(EXAMPLE_SCREENS).map((slug) => row(slug, 1, EXPECTED_STOPS[slug]))), false],
      ['recorded complete, with another example\'s screen stops',
        transcript((b) => right(b).map((r, i) => (i === 0 ? row('good-passage', 1, [...screenStops('bad-unmarked'), EXAMPLE_HEADING, ...EXPECTED_STOPS['good-passage']]) : r))), false],
      ['recorded complete, with a wrong stop after the heading',
        transcript((b) => right(b).map((r, i) => (i === 0 ? row('good-passage', 1, [...screenStops('good-passage'), EXAMPLE_HEADING, 'Bienvenue']) : r))), false],
    ];
    for (const [what, text, ok] of cases) {
      const problems = judgeTranscript(text);
      expect(problems.length === 0, `${what}: ${problems.join('; ')}`).toBe(ok);
    }
  });

  test('the first recording (voiceover-web-round1-pass.md.txt), which logged only what follows the heading of a complete walk, cannot be judged again: every pair fails for its missing screen stops', () => {
    const text = readFileSync(new URL('../docs/evidence/probes/s16/voiceover-web-round1-pass.md.txt', import.meta.url), 'utf8');
    const problems = judgeTranscript(text);
    // Fourteen walks, each judged wrong again (its first stop is not the
    // title), and nothing else wrong with the file.
    expect(problems.filter((p) => / judges "wrong" again: stop 1 was /.test(p))).toHaveLength(14);
    expect(problems).toHaveLength(14);
  });

  // The recording with every walk logged whole is made by the principal
  // (the web VoiceOver recording takes over the Mac). Until it is
  // committed there is nothing to judge, and this test says so.
  const committed = new URL('../docs/evidence/S16/voiceover-web.md', import.meta.url);
  test('the committed recording (docs/evidence/S16/voiceover-web.md) is right, every browser and example once', () => {
    test.skip(!existsSync(committed), 'not recorded yet with every walk logged whole');
    expect(judgeTranscript(readFileSync(committed, 'utf8'))).toEqual([]);
  });
});
