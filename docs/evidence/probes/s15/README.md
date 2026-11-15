# S15 probe: where `Semantics(hint:)` goes

Run on 2026-11-15, Flutter 3.47.5, before the S15 examples were written. The
fixture is `probe.dart.txt` (a second entry point, not part of the app).

| # | Fixture | Web (Chromium and WebKit DOM) | Android (`uiautomator dump`) | iOS (VoiceOver, `XCUIVoiceOverService`) |
| --- | --- | --- | --- | --- |
| 01 | `Semantics(button, label, hint, onTap)` | `role="button"`, `aria-description` is the hint | `Button`, description "h01 Favorite, Adds this item to your favorites." | "h01 Favorite Button Adds this item to your favorites." |
| 02 | `Semantics(hint:)` around a `FilledButton` | button with no description; the hint is nowhere in the DOM | a `View` whose description is the hint, then the `Button` with no hint | the hint as a stop of its own, then "h02 Favorite Button" |
| 03 | `Semantics(hint:)` around a `CupertinoButton` | as 01 | as 01 | as 01 |
| 04 | `Semantics(hint:)` around a `ListTile` with `onTap` | button "h04 Night Ferry The Lanterns", `aria-description` | `Button`, "h04 Night Ferry, The Lanterns, Plays the song." (a line break between title and artist) | "h04 Night Ferry, The Lanterns Button Plays the song." |
| 05 | text with `label` and `hint`, no action | element with no role, `aria-description` | `View`, "h05 Total, Includes tax." | "h05 Total Includes tax." |
| 06 | `TextField` with `helperText` | textbox, no description; the helper is separate text | `EditText` with hint "h06 Password"; the helper is a separate `View` | "h06 Password Text field Double tap to edit.", then the helper as its own stop |
| 07 | `TextField` with `hintText` | textbox, no description | `EditText`, hint "h07 Password" | "h07 Password Text field Double tap to edit." |
| 08 | `Semantics(hint:)` around a `TextField` | `<input>` with `aria-description` | `EditText`, hint "h08 Password, 8 characters minimum." | "h08 Password Text field 8 characters minimum. Double tap to edit" |
| 09 | button with `onTapHint` only | nothing | description "h09 Favorite" (the action label is not in the dump) | "h09 Favorite Button" |
| 10 | button with `hint` and `onTapHint` | as 01 | as 01 | as 01 |
| 11 | switch with a hint | `role="switch"`, `aria-description` | `Switch`, "h11 Wi-Fi, Turns wireless networking on or off." | "h11 Wi-Fi Switch button off Turns wireless networking on or off." |
| 12 | button with `tooltip:` | button named "Add to favorites h12 Favorite" | `Button`, "h12 Favorite" | "h12 Favorite, Add to favorites Button" |
| 13 | `IconButton(tooltip:)` | button "h13 Favorite" | `Button`, "h13 Favorite" | "h13 Favorite Button" |
| 14 | button with a hint and no label | button with no name and no description | `Button` whose description is the hint | "h14 Adds this item to your favorites. Button": the hint is read as the name |
| 15 | link with a hint | `<a>`, `aria-description` | `Button`, "h15 Terms, Opens in the browser." | "h15 Terms Link Opens in the browser." |
| 16 | adjustable node with a hint | `aria-description` on the element around the `<input type="range">`, not on the slider | `SeekBar`, "3, h16 Volume, Changes the media volume." | "h16 Volume 3 adjustable Changes the media volume. Swipe up or do…" |
| 17 | `Semantics(hint:)` around a `TextField` with no label (`probe2.dart.txt`, web only) | `<input>` with no name and `aria-description` the hint, in Chromium and WebKit | not run | not run |

## What it shows

- **iOS has a hint of its own.** VoiceOver reads it after the name, the role,
  and the state.
- **Android has no separate hint.** The engine appends it to the content
  description, "label, hint". A text field is the exception: label and hint
  go into the node's hint text.
- **On the web a hint is `aria-description`** in Chromium and in WebKit; the
  `aria-describedby` fallback in the engine was not used by either.
- **A hint around a Material button is left on its own node** (02), because
  the button is a semantics container. On the web that node has no name and
  is not rendered, so the hint is lost.
- **A hint with no label is dropped on the web** (14) and is read as the
  name on Android and iOS. A text field is the exception on the web: its
  hint is set on the `<input>` with or without a label (17).
- **`helperText` and `hintText` are not hints** in the semantics sense
  (06, 07).
- **`onTapHint` is a different thing** (09): it is the label of the tap
  action, and belongs to I06.

TalkBack and VoiceOver on the web were not part of the probe; what they say
was recorded with the examples.
