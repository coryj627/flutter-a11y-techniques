# F03 probe: keyboard types, input purpose, and password fields

Run on 2026-11-18, Flutter 3.47.5, before the F03 examples were written.
The fixture is `probe.dart.txt` (a second entry point, not part of the
app): seventeen fields on three pages, so that each page fits on a phone
with the keyboard down. Every field's label starts with its number ("p01
Name"), and each carries the identifier `pNN` on a plain `Semantics`
around it. Unless a row says otherwise a field is a Material `TextField`
with `labelText` and the default `autofillHints`, which is an empty list.

How each platform was looked at, and the raw output:

- Widget level: a throwaway widget test (`probe_widget_test.dart.txt`)
  that prints each field's semantics and the configuration it sends the
  platform when editing starts (`TextInput.setClient`). Output:
  `widget.txt`.
- Android: Pixel 10a emulator, Android 17, Gboard. A throwaway
  instrumented test (`ProbeF03Test.kt.txt`, run with
  `-Ptarget=lib/probe.dart` under the device lock) that, for each field,
  clicks it and logs the editor the input method serves (`dumpsys
  input_method`), the labels of the keys in the keyboard's window, and
  the autofill structure the FlutterView gives the autofill framework,
  read with a recording `ViewStructure`. It took a screenshot of each
  keyboard; the screenshots were looked at and are not kept (VAL-11).
  Output: `android.txt`. Its first run stopped at fixture 11 (below) and
  pressed Back with no keyboard up, which left the app; the second run,
  kept here, presses Back only while the keyboard's window is there.
- iOS: iPhone 17 simulator, iOS 27.0. A throwaway XCUITest
  (`ProbeF03UITests.swift.txt`) that prints the tree, taps each field and
  prints the keyboard's keys, its buttons, and what is above it (the
  QuickType bar), and walks each page with `XCUIVoiceOverService`, and
  page 3 again while fixture 13 is being edited with "abc" typed. Output:
  `ios.txt`.
- Web: a throwaway Playwright test (`probe_web.js.txt` with
  `probe_web.config.js.txt`) that prints each field's `<input>`
  attributes before it is clicked, while focused, after "abc" is typed,
  and after focus has left; and, in Chromium, the accessibility tree. Run
  in Chromium and WebKit on the desktop, and with Playwright's Pixel 7
  and iPhone 15 emulation. `web.txt` is that run; in it the emulated
  phones still report `navigator.platform` "MacIntel", which Flutter
  reads first and takes for macOS. `web2.txt` is the phone projects run
  again with the platform a phone reports ("Linux armv8l", "iPhone").
- TalkBack and VoiceOver on the web were not part of the probe; what they
  say was recorded with the examples.

## Keyboards and purposes

"Android" is the editor's input type and IME action, the keyboard seen,
and the autofill hints given. "iOS" is the keyboard's keys and return
key. "Web" is the desktop `<input>` while focused (`type`, `inputmode`,
`autocomplete`, `name`); the phone column of `web2.txt` adds
`enterkeyhint`.

| # | Fixture | Android | iOS | Web |
| --- | --- | --- | --- | --- |
| 01 | `TextInputType.name`, `AutofillHints.name`, `TextCapitalization.words`, `next` | `0xa061` (person name, words, autocorrect), Next; letters; `personName` | letters and a "phone pad" key; "next" | `type="text"`, `autocomplete="off"`, `name="name"` |
| 02 | `emailAddress`, `AutofillHints.email`, `next` | `0x8021` (email), Next; "@" on the first page; `emailAddress` | letters, "@", "."; "next" | `inputmode="email"`, `autocomplete="email"` before focus as well |
| 03 | `phone`, `telephoneNumber`, `next` | `0x3`, Next; the dial pad with letters under the digits; `phoneNumber` | the phone pad: digits, no return key | `type="tel"`, `autocomplete="off"`, `name="tel"` |
| 04 | `url`, `AutofillHints.url`, `next` | `0x8011`, Next; "/"; `url` | letters, ".", "/", ".com"; "next" | `type="url"`, `autocomplete="off"`, `name="url"` |
| 05 | `numberWithOptions(decimal: true)`, `done` | `0x2002`, Done; digits, "," and "."; no hint | the decimal pad, no return key | nothing; on a phone no `inputmode` either |
| 06 | `TextInputType.number` | `0x2`, Done; digits; no hint | the number pad, no return key, no "." | as 05 |
| 07 | all defaults | `0x8001`, Done; letters, no "@" | letters, no "@"; "done" | `autocomplete="off"`, no `name` |
| 08 | `autofillHints: null` | `0x8001`; no autofill entry at all | as 07 | as 07 |
| 09 | `emailAddress`, `email`, `enableSuggestions: false` | `0x880b1` (the filter variation, FL-160); "," in place of "@"; `emailAddress` | as 02 | as 02 |
| 10 | `CupertinoTextField`, `emailAddress`, `email`, `next`, in `Semantics(label:)` | as 02 | as 02 | as 02 |
| 11 | a bare `EditableText`, decimal, in `Semantics(label:)` | a click did not focus it; no keyboard | after the tap the keyboard was the decimal pad, though XCUITest reported no focus | a click did not focus it |
| 12 | `multiline`, three lines | `0x28001` (multi-line), IME action none; the node's `isMultiLine` is false | letters; "return" | a `<textarea>`, `autocomplete="on"` once focused |
| 13 | `obscureText`, `AutofillHints.password`, `done` | `0x80081` (password, no suggestions); `password`; the node's password flag | letters; "done"; "Passwords" above the keyboard | `type="password"`; `autocomplete="current-password"` once focused |
| 14 | `obscureText`, `number` | `0x2`: a plain number field, no number-password variation; the node's password flag | the number pad | `type="password"`, `autocomplete="on"` once focused |
| 15 | `CupertinoTextField(obscureText:)`, `password` | as 13 | as 13 | as 13 |
| 16 | `obscureText`, `newPassword` | as 13, hint `newPassword` | as 13 | `autocomplete="new-password"` once focused |
| 17 | `visiblePassword`, not obscured | `0x8091` | letters; no "Passwords" | as 07 |

Before a field is focused, every `<input>` on the web has
`autocomplete="off"`, except the email fields (02, 09, 10), which have
`autocomplete="email"`. That stays so while the field is edited and
after, for every single-line field that is not obscured; the obscured
ones (13 to 16) keep the hint written when editing starts
([FL-161](../../../flutter-limitations.md#fl-161)). With a phone's
platform, `enterkeyhint` follows each field's action (`next`, `done`,
`enter` for 12) and `inputmode` is never "numeric" or "decimal"
([FL-162](../../../flutter-limitations.md#fl-162)). In Chromium's
accessibility tree every field on page 1 is a `textbox`, whatever its
`type`.

Before editing, the semantics input type the framework gives the engine
is `email`, `phone`, or `url` for those keyboard types and `text` for all
others (`widget.txt`), and the obscured fields have the obscured flag and
a value of bullets once something is typed.

## Password fields

- **Android**: the node has the password flag (`password=true`) before,
  during, and after editing, and its text is "•••" once "abc" is typed.
- **iOS** ([FL-042](../../../flutter-limitations.md#fl-042)): every
  obscured field is a text field (type 49) until it is tapped, a secure
  text field (type 50) while it is being edited, and a text field again,
  with "•••" as its value, once editing moves to another field. VoiceOver
  read them "p13 Password Text field Double tap to edit." on page 3. In
  the walk made while 13 was being edited, VoiceOver's cursor started on
  13 and the first move read 14, so what is said for 13 while it is
  edited was not captured here; the F03 VoiceOver test does that.
- **Web**: `type="password"` from the start, from the semantics flag.

## What it shows

- **Keyboard types reach the keyboard on Android and iOS** as the
  references describe, and the keys can be read: from the input method's
  window on Android and from `app.keyboards` on iOS. The return key
  follows `textInputAction` on Android and iOS, except that iOS's number,
  decimal, and phone pads have none
  ([FL-163](../../../flutter-limitations.md#fl-163)).
- **Autofill hints reach Android's autofill framework** (translated:
  `name` to `personName`, `email` to `emailAddress`, `telephoneNumber` to
  `phoneNumber`), and the iOS keyboard offers "Passwords" for a password
  field. On the web they are lost (FL-161).
- **`enableSuggestions: false` costs an Android email field its "@"**
  ([FL-160](../../../flutter-limitations.md#fl-160)).
- **On the web only email, phone, and URL fields say what keyboard they
  want** (FL-162).
- **A bare `EditableText` cannot be focused** by a click on Android or the
  web, so it was not made an example.
- **A PIN** (14) is a plain number field to Android's input method; the
  node still has the password flag. Not followed up: no example has one.
