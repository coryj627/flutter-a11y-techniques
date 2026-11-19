# I04 probe: keyboard actions and shortcuts

Run on 2026-11-18, Flutter 3.47.5, before the I04 examples were written.
The fixture is `probe.dart.txt`, a second entry point and not part of the
app: one long screen of fixtures `q01` to `q19`, each text starting with
its id. At the top of the screen, outside the scrolling part, the probe
shows the widget with Flutter's focus ("Focus: q05"), every key-down that
reached the framework with its modifiers and character ("Keys: ...
F'f'"), a log of what every shortcut, action, page change, and submit did
("Log: q01 char-f"), the text in every field ("Texts: q01=a b"), and the
offset of the scrolling part ("Scroll: 467"). So what a key did can be
read from any platform's tree.

| # | Fixture |
| --- | --- |
| q01 | `CallbackShortcuts` for `CharacterActivator('f')` and `SingleActivator(keyG)` around a text field and a button |
| q02 | q01 with the field inside a `Shortcuts` that maps both keys to `DoNothingAndStopPropagationIntent` |
| q04 | a `ShortcutRegistry` entry for `CharacterActivator('h')`, for the whole app |
| q05 | a custom control in `FocusableActionDetector` with shortcuts for Left, Right, Home, End, and F |
| q06 | the same in `Focus(onKeyEvent:)`, handling key down and repeat for the arrows, and F by its character |
| q07 | a `PageView` of four pages, nothing added |
| q08 | a `CarouselView` of four items |
| q09 | `TextField(textInputAction: search, onSubmitted:)` |
| q10 | `TextField(textInputAction: next)`, then a second field `q10b` |
| q11 | a multi-line `TextField` (three lines, `keyboardType: multiline`) |
| q12 | `CupertinoTextField(textInputAction: search, onSubmitted:)` |
| q13 | a `TextField` inside a `FocusableActionDetector` with actions for both activate intents |
| q14 | `CallbackShortcuts` for Control+F, Alt+F, Meta+F, Control+Shift+F, and `CharacterActivator('f', alt: true)` around a button |
| q15 | a button and a plain `Focus` node, for the scrolling keys |
| q16, q17 | an adjustable custom control (`Semantics(onIncrease:, onDecrease:)`) with no keys, and with keys (round 2) |
| q18, q19 | a three-line field with the send action, and the same with Enter mapped to send by `CallbackShortcuts` (round 2) |

How each platform was looked at, and the raw output (long lines in the
web and iOS output were cut when they were saved; the field values are
kept):

- Flutter test: `probe_test.dart.txt`, as Android and as iOS: Tab and
  Space over a `CupertinoSlidingSegmentedControl`, a `SegmentedButton`,
  and a `CupertinoSwitch`; whether a page-wide shortcut handles F in a
  field. Output: `flutter_test.txt`.
- Web: Chromium on macOS, Playwright, `probe_web.spec.js.txt`. Output:
  `web.txt` (four runs, one after the other as fixtures were added).
  `html_control.spec.js.txt` is a plain HTML page with no Flutter, for
  comparison. Output: `html_control.txt`.
- Android: Pixel 10a emulator, Android 17, `hw.keyboard=yes` (read, not
  changed), Gboard as the input method (`settings get secure
  default_input_method`). `ProbeI04Test.kt.txt`, run with `am instrument`
  by `android_probe.sh.txt`, which also turned TalkBack on for one method
  and put the accessibility settings back afterwards (both runs end with
  "restored: null / 0", the values from before). Round 1:
  `android.txt`; round 2 (the script as it was then): `android_round2.txt`.
  In round 2 the screen was longer and many `tabUntil` calls did not
  reach their fixture ("reached false"); only the lines that say
  "reached true" are used below.
- iOS: iPhone 17 simulator, iOS 27.0, `I04ProbeUITests.swift.txt`, run by
  `ios_probe.sh.txt`: `typeKey` for every key, `typeText` once, and one
  method with VoiceOver turned on through `XCUIVoiceOverService` and off
  again. Output: `ios.txt`. Full Keyboard Access was not turned on.

## Single-key shortcuts and text fields

| | Web | Android | iOS |
| --- | --- | --- | --- |
| q01: "afg b" typed in the field | "a b"; both shortcuts ran | "afg b"; no shortcut ran, and no letter reached the framework as a key (`input text`) | "a b" with `typeKey`, both shortcuts ran; "fg" with `typeText` was typed whole and no key event reached the framework |
| q02 (the field maps F and G to `DoNothingAndStopPropagationIntent`) | "afg b"; no shortcut | "afg b" | "afg b" |
| q01 and q02, F and G on the button | both shortcuts ran | both ran in q01; in q02 only G was seen in round 1 | both ran |
| q04, H with nothing focused, on a button, and typed in a field | ran each time; the field lost the h ("i") | ran with nothing focused; "hi" typed whole in the field | ran each time; the field lost the h |

On Android the letters typed into a field never appeared in the key log:
read as the input method (Gboard) having the keys first while a field is
being edited. In round 2, `input keyevent` letters sent to a focused field
appeared neither in the key log nor in the field; not explained, and not
relied on: the I04 tests type with `Instrumentation.sendStringSync`.

**With a screen reader running.** iOS, VoiceOver on through
`XCUIVoiceOverService`: `typeKey`'s letters, Tab, the arrows, and Space
all reached Flutter, F still took the f from the field ("a b"), and the
viewer's arrows and F worked. Whether a real keyboard's keys behave the
same with VoiceOver on, and with Quick Nav, was not tried. Android, with
TalkBack on (`touchExploration=true` in round 2): Tab, the D-pad keys,
and F still reached Flutter and acted (q06's photo and favourite changed).
Whether Enter submitted with TalkBack on was not established: round 2's
line for it shows no submit and its field value was not kept, and round
1's TalkBack run was not checked to have TalkBack on. The web with VoiceOver: the
I04 VoiceOver spec's `keys-bad-page-shortcut` row
(`docs/evidence/I04/voiceover-web.md`).

## The keys a custom control handles

q05 (`FocusableActionDetector`) and q06 (`Focus.onKeyEvent`):

| | Web | Android | iOS |
| --- | --- | --- | --- |
| Left, Right | acted; the page did not scroll | acted | acted |
| Home, End | acted in q05; in q06, which does not handle them, the page scrolled to its end and back to the top | acted in q05; nothing in q06 | never reached Flutter: no key in the log |
| F | acted | acted | acted |
| Down | scrolled the page 50 pixels | moved focus to the next control below | moved focus below |
| Page Down, Page Up | scrolled the page | scrolled the page | never reached Flutter |
| A held Right | one step (Playwright does not repeat) | repeated (`--longpress`), and q06's repeat handling went on | not tried |

- **A key the control does not handle goes on to the defaults**:
  `WidgetsApp.defaultShortcuts` (read in `widgets/app.dart`). Off the web
  the arrow keys move focus by position; on the web they, Page Up, and
  Page Down scroll, and Space on a control with no activate action
  scrolls a page (q15's plain `Focus` node). On Android Control+Down
  scrolled; on iOS Command+Down is the scroll key in the source.
- **q16, a control with `onIncrease` and `onDecrease` and no keys, on the
  web**: it is an `<input type="range">`; Left and Right did nothing, and
  End moved it one step through the browser's own handling, as FL-122
  describes for a slider. Such a control also has no accessible name on
  the web ([FL-028](../../../flutter-limitations.md#fl-028)), which is why
  the I04 examples use a strip of buttons and not an adjustable control.
- **q07, a `PageView`**: Tab never stopped on it, on any platform
  (FL-463).
- **q08, a `CarouselView`**: each item a Tab stop, and Enter and Space
  tapped it, on all three; Right moved focus to the next item on Android
  and iOS and did nothing on the web.

## The text field's action

| | Web | Android | iOS |
| --- | --- | --- | --- |
| q09, Enter (search action) | `onSubmitted`, then no control had focus (`flutter-view` active); the next Tab went to the first stop of the screen | `onSubmitted`, focus on the screen's scope; the next Tab to the first stop | the same as Android |
| q10, Enter (next action) | `onSubmitted`, then focus on q10b | the same | the same |
| q11, Enter in a multi-line field | a new line, no submit | the same | the same |
| q12, `CupertinoTextField` | as q09 | as q09 | as q09 |
| q13, a field inside activate actions | `onSubmitted`; the activate actions did not run | the same | the same |
| q18, Enter in a multi-line field with the send action | `onSubmitted`, no new line | not reached in round 2 | not tried |
| q19, q18 with Enter mapped by `CallbackShortcuts` | the shortcut ran and no new line; Shift+Enter submitted | Enter ran the shortcut, Shift+Enter added a line | not tried |

Enter reached the framework as a key event on all three (the key log),
and on iOS only as `typeKey("\n")`: `XCUIKeyboardKey.return` reached
nothing, and `XCUIKeyboardKey.enter` arrived as Control+C. On iOS,
"ab" typed with `typeKey` was autocorrected to "an" on Enter.

Losing focus after the action is FL-461. The on-screen keyboard's action
key could not be pressed from the tests: the emulator and the simulator
both have a hardware keyboard, which hides it. Android's text field nodes
offered no `ACTION_IME_ENTER` (round 1: only actions 64 and 16).

## Modifiers

q14 on a button: Control+F, Alt+F, Meta+F, and Control+Shift+F each reached
the framework and ran on the web (Playwright) and on iOS; on iOS Option+F
gave the character "ƒ", so `CharacterActivator('f', alt: true)` did not
run where `SingleActivator(keyF, alt: true)` did. On Android Control+F and
Alt+F ran; Meta+F never reached Flutter, and the probe app was gone from
the screen at the next read. Playwright's keys go to the page past the
browser's own shortcuts, so whether a browser keeps Control+F for itself
was not measured.

## What it shows

- **A shortcut above a text field takes its letter on the web and on
  iOS, not on Android** (FL-460). `DoNothingAndStopPropagationIntent`
  around the field gives it back everywhere.
- **Keys a control does not handle fall through to the defaults**, which
  differ between the web and the rest: arrows scroll on the web and move
  focus elsewhere.
- **Enter in a single-line field is its action on every platform**, and
  a done, go, search, or send action leaves focus on no control (FL-461).
- **XCUITest cannot send Home, End, Page Up, or Page Down** to the
  simulator; those keys are not verified on iOS.
- An adjustable control has no name on the web (FL-028), a `PageView`
  takes no focus (FL-463), and a `CupertinoSlidingSegmentedControl` did
  not answer Space in a widget test (FL-462).

## Kept from the build

- `voiceover-ios-first-run.md.txt` and `voiceover-web-first-run.md.txt`:
  the first VoiceOver transcripts of the I04 examples, written by
  `tool/voiceover_ios.py` and `tool/voiceover_web.py` and copied here
  before later runs replaced them. They show FL-464: with the line of
  keys as plain text inside a `CallbackShortcuts`, the web read the
  example as a group named by that line, and VoiceOver on iOS read the
  line before the strip it was written under. Their expected phrases
  were first guesses and fail for that reason too; the speech is what
  matters here.
