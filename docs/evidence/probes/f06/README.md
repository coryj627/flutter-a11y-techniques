# F06 probe: text fields with errors

Run on 2026-11-18, Flutter 3.47.5, before the F06 examples were written.
The fixtures are `probe.dart.txt`, a second entry point and not part of
the app, one screen per fixture, opened by route (`/p01` …). Every
fixture's text starts with its id. Errors used: "Enter your name.",
"Enter an email address, like name@example.com.", and "Enter a phone
number using digits only." (the examples later changed the email
message).

How each was looked at, and the raw output:

- Web: Chromium on macOS through Playwright (`probe_web.spec.js.txt`): the
  DOM under `flt-semantics-host`, Chromium's accessibility tree over the
  DevTools protocol, everything written to `flt-announcement-polite` and
  `flt-announcement-assertive` (a `MutationObserver`), and DOM focus,
  before and after the button was pressed with the keyboard. Output:
  `web.txt`. First round only.
- VoiceOver on the web: `probe_vo.spec.js.txt`, run once through
  `python3 tool/voiceover_web.py F06` with a temporary registration
  pointing at it and `build/web` built from the probe. Output:
  `voiceover-web.md`, which that tool wrote. First round only.
- Android: the Pixel 10a emulator, Android 17, TalkBack 17.0, with a
  throwaway instrumented test (`ProbeF06Test.kt.txt`) run by
  `probe_android.py.txt` under the device lock with Gradle's
  `-Ptarget=lib/probe.dart`. `probe()` dumps every node of each fixture
  before and after its button is clicked (`android-tree.txt`,
  `android-tree2.txt` for the second round). `talkBackWalk()` does it with
  TalkBack on, using `tool/talkback.py`'s own `run_with_talkback`, and
  logs markers: TalkBack focus on the button, the button clicked (what is
  then said with focus left alone), and then focus forced onto each
  element in turn, which shows speech and not swipe order. The speech per
  marker is `android-talkback.md` and `android-talkback2.md`, parsed with
  `tool/talkback.py`'s `parse_speech` (`parse_tb.py.txt`; the first
  capture was in logcat's brief format, whose prefixes it normalises); the
  node dumps taken with TalkBack on are `android-talkback-tree*.txt`.
- Native comparison on Android: `ProbeNativeActivity.kt.txt`, two
  `android.widget.EditText`s and a button that calls `setError` on both,
  declared for that run in the debug manifest. Output:
  `android-tree-native.txt` and `android-talkback-native.md`.
- iOS: the iPhone 17 simulator, iOS 27.0, with a throwaway XCUITest
  (`ProbeF06UITests.swift.txt`): the element tree before and after the
  button is tapped, then with VoiceOver on: the cursor put on the button,
  a double tap, every new utterance of `currentSpeech()` for nine seconds,
  one move forward and one back to find the cursor, and a walk of the
  screen. Output: `ios.txt`. XCUITest gives the first 64 characters of an
  utterance. First round only.

## First round

`p01` and `p02` show their errors from the start; every other fixture has
a button that makes the errors appear. Fields are wrapped in the project's
`TestId` (a `MergeSemantics`) unless the row says otherwise.

| # | Fixture | Web | Android | iOS |
| --- | --- | --- | --- | --- |
| p01 | `TextField` with `errorText`, in `TestId`; Email empty, Phone "abc" | name "p01 Email Enter an email…", description the error again; `aria-invalid` absent | `EditText`, hint "p01 Email\nEnter…, Enter…", the field itself a live region; TalkBack "abc, Edit box" for Phone | label "p01 Email\nEnter…"; VoiceOver "p01 Email Enter an email address… Text fi…" |
| p02 | the same with `Semantics(identifier:)`, not merged | name "p02 Email", description the error; the error a text of its own | hint "p02 Email, Enter…"; the error a child `View`, polite live region; TalkBack "p02 Email, Enter…" empty, "abc, Edit box" filled, the error read as its own stop | label "p02 Email", the error a static text; VoiceOver "p02 Email Text field Enter an email…", and filled "p02 Phone abc Text field Enter a phone number…" |
| p03 | `errorText` set by a button with `setState`, no `Form` | nothing announced; focus stays on the button | the field (merged) is a live region; TalkBack announced it | nothing said after the double tap |
| p04 | `Form`, one `TextFormField`, `validate()` | assertive announcement of the error; `aria-invalid="true"` | live region announced | VoiceOver said the error |
| p05 | `Form`, two fields, `validate()` | the first error only, assertive | (merged) only the second field's live region was spoken | the first error only |
| p06 | p05 with `requestFocus()` on the first field in error | DOM focus on its `<input>`, first error announced | input focus and TalkBack focus on the field; keyboard up | the error announced; the cursor stayed on the button, keyboard up (one move forward reached a key) |
| p07 | p05 with a `FocusSemanticEvent` to the first field in error | no change: the web ignores the event | TalkBack focus on the field | the cursor moved to the field: "p07 Name Enter your name. Text field Enter your name. Double tap", then "Enter your name." |
| p08 | `Form`, and the error also as `Semantics(hint:)` | the description has the error twice | the hint has it three times | the hint read with the value |
| p09 | `CupertinoTextFormFieldRow`, in `TestId`, `validate()` (Space on the web) | assertive announcement; name "p09 Email name@example.com Enter…" | nothing said after the button; the error is not a live region | VoiceOver said the error |
| p10 | a hand-drawn error `Text` in a live region, `validationResult` on the field | polite announcement; `aria-invalid="true"` on the field | announced | announced |
| p11 | `Form`, two fields, and a summary of the errors in a live region | the first error (assertive) and the summary (polite) | the summary and one field announced | the summary, then the first error |
| p12 | a `TextFormField` with its own `AutovalidateMode.onUserInteraction`, no `Form`; a button puts "x" in the field | nothing announced | TalkBack "x, Edit box", no error | nothing said |
| p13 | a hand-built Cupertino row: `FormField`, the field named, the error in a live region always | announced twice: assertive and polite; `aria-invalid` on an element around the field, not on the field | announced | announced once |

## Second round

Android only. Fields identified with `Semantics(identifier:)`, not merged.

| # | Fixture | Android |
| --- | --- | --- |
| q01 | `Form`, Name and Email both empty, `validate()` | both errors are child `View`s and live regions; TalkBack said both, Email's first |
| q02 | q01 with `requestFocus()` on Name | both errors, then "q02 Name, Enter your name. Editing. Edit box"; TalkBack focus on Name |
| q03 | Name "Ana", Email "abc", focus to Email | "Enter an email…", then "Editing.", "abc", "Edit box"; read again, Email is the same: no label, no error |
| q04 | a Cupertino row built like `InputDecorator`: label, hint, validation result, live region only where announcements are unsupported | hint "q04 Email\nname@example.com, Enter…" (the placeholder joins the label); the error a live region, announced |
| q05 | an error `Text` below an unmerged field, in a live region | announced; the field has no error of its own |
| q06 | `errorText: ''` | nothing said; the field is not marked in any way TalkBack reads |
| native | `EditText.setError` on an empty field and on one holding "abc" | node error set and content-invalid; TalkBack announced "Error: Enter an email address." and "Error: Enter a phone number using digits only.", and read the filled field "Error: Enter a phone number using digits only.. abc. Edit box" |

## What it shows

- **`TextFormField` puts its error in two places**: a text node of its own
  under the field, and the field's semantics hint. The web makes the hint
  the field's description; iOS reads it after the role, with or without a
  value; Android joins it to the label in the hint text, which TalkBack
  stops reading once the field has a value (FL-015, FL-180).
- **Android has no error state for a Flutter field** (FL-180). A native
  `EditText` with `setError` is read "Error: …" even with a value.
- **`aria-invalid` comes only from a `FormField`** (its
  `validationResult`), and only on the web; a bare `TextField` with
  `errorText` has none (p01 to p03).
- **Who announces differs by platform** (FL-181). On Android the error text
  is a live region whatever set it. On iOS and the web `Form.validate()`
  announced the first error only, assertively (p04 to p07). An `errorText`
  set with `setState` (p03) and a field's own autovalidate mode with no
  `Form` (p12) were silent there. The probe did not try the `Form`'s own
  `autovalidateMode` or `validateGranularly()`; the source and the F06
  widget tests show that both announce, like `validate()`.
- **`CupertinoTextFormFieldRow`'s error is silent on Android** (FL-182,
  p09).
- **`MergeSemantics` (and so `TestId`) around a field takes in its error**
  (FL-183, p01 against p02): the error is in the name and read twice, and
  on Android the field becomes a live region.
- **Keyboard focus does not move VoiceOver on iOS** (FL-184, p06); a
  `FocusSemanticEvent` does (p07). On Android and the web keyboard focus
  is enough.
- **A second hint with the error repeats it** (p08), and an always-on live
  region beside `Form.validate()` announces it twice on the web (p13):
  copy `InputDecorator`, which uses a live region only where announcements
  are not supported.
