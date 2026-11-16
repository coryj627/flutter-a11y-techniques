# S22 probe: where `Semantics(identifier:)` goes

Run on 2026-11-15, Flutter 3.47.5, before the S22 examples were written. The
fixture is `probe.dart.txt` (a second entry point, not part of the app).
Every fixture's label starts with its number ("i01 Save") and its
identifier is `p` and the number.

"On the control" means one element with the role, the name, and the
identifier. "Split" means the control has no identifier and, on Android and
iOS, no name; the text is a separate element with the identifier.

| # | Fixture | Web (Chromium and WebKit DOM) | Android (`uiautomator dump`) | iOS (XCUITest tree) | VoiceOver on iOS |
| --- | --- | --- | --- | --- | --- |
| 01 | `MergeSemantics` + identifier around a `FilledButton` | on the control | on the control | on the control | "i01 Save Button" |
| 02 | identifier around the text inside a `FilledButton` | on a child element of the button; the button's name is still "i02 Save" | split: `Button` with no description, child `View` "i02 Save" with the id | split: `Button` with no label, `StaticText` with the identifier | "Button", then "i02 Save" |
| 03 | plain identifier around a `FilledButton` | on an element around the button | on a `View` whose child is the `Button` | on an `Other` beside the button, same frame | "i03 Save Button" (one stop) |
| 04 | plain identifier around a `CupertinoButton` | on the control | on the control | on the control | "i04 Save Button" |
| 05 | `Semantics(button, label, identifier, onTap)` | on the control | on the control | on the control | "i05 Save Button" |
| 06 | plain identifier around a `TextField` | on the element around the `<input>` | on the `EditText` | on the `TextField` | "i06 Name Text field Double tap to edit." |
| 07 | merged identifier around a `TextField` | as 06 | as 06 | as 06 | as 06 |
| 08 | identifier around a `Text` | on the text's element | on the `View` | on the `StaticText` | "i08 Total: 3" |
| 09 | merged identifier around an `IconButton` with no tooltip | button with no name | `Button` with no description | `Button` with no label | "Button" |
| 10 | the same with a tooltip | button "i10 Close" | `Button` "i10 Close" | `Button` "i10 Close" | "i10 Close Button" |
| 11 | `Semantics(container: true, identifier:)` around a `FilledButton` | as 03 | as 03 | as 03 | "i11 Save Button" |
| 12 | identifier around the text inside a `CupertinoButton` | as 02 | split | split | "Button", then "i12 Save" |
| 13 | a node with an identifier and nothing else | an empty element | a `View` with the id | an `Other` | not a stop |
| 14 | two merged buttons with the same identifier | two elements with the attribute | two `Button`s with the id | two `Button`s with the identifier | each read normally |
| 15 | merged identifier around a `CheckboxListTile` | `role="checkbox"` with the attribute | `CheckBox` with the id | `Switch` with the identifier | "i15 Agree Switch button on" |
| 16 | merged identifier around a `ListTile` | on the control | on the control | on the control | not reached |
| 17 | identifier around an `Icon` with a label | on the element | on the `View` | on the `StaticText` | not reached |
| 18 | plain identifier around a `ListTile` | on the control | on the control | on the control | not reached |
| 19 | plain identifier around two `Text`s | one element, "i19 One i19 Two" | one `View`, the two lines as one description | one `StaticText` | not reached |
| 20 | identifier around a `ListTile`'s title | as 02 | split | split | not reached |
| 21 | `Semantics(explicitChildNodes: true, identifier:)` around a `FilledButton` | as 03 | as 03 | as 03 | not reached |
| 22 | identifier around the label of an `OutlinedButton.icon` | as 02 | split | split | not reached |

## What it shows

- **The identifier is `flt-semantics-identifier` on the web, the resource
  id on Android, and `accessibilityIdentifier` on iOS**, and is in nothing
  that is read.
- **Inside a control it splits the control** (02, 12, 20, 22). On Android
  and iOS the control loses its name. On the web the browser still
  computes the button's name from its content.
- **Around a Material button, unmerged, it is a node of its own** (03, 11,
  21): around the button on web and Android, beside it on iOS. Around a
  `CupertinoButton`, `ListTile`, `TextField`, or `Text` it joins the
  widget's node (04, 06, 08, 18).
- **`MergeSemantics` gives one node in every case tried** (01, 07, 09, 10,
  14, 15, 16).
- **An identifier is not a name** (09) and **two elements can share one**
  (14) with no error.
- **A plain wrapper around several texts merges them into one element**
  (19): an identifier on a group changes how the group is read.

The VoiceOver walk on iOS stopped moving at fixture 15, at the bottom of
the first screen, so fixtures 16 to 22 were not heard. The fixtures that
matter for the examples were above it. TalkBack and VoiceOver on the web
were not part of the probe; what they say was recorded with the examples.
The iOS tree also shows `CheckboxListTile` as a `Switch`; that is not about
identifiers and is left to the checkbox technique (F07).
