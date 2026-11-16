# F07 probe: checkboxes

Run on 2026-11-16, Flutter 3.47.5, before the F07 examples were written. The
fixture is `probe.dart.txt` (a second entry point, not part of the app).
Every fixture's label starts with its number ("k01 Email").

On iOS every checkbox is a `Switch` with the value 1 or 0, and VoiceOver
says "Switch button on" or "off" (FL-035). The iOS column gives the value.

| # | Fixture | Web (Chromium and WebKit DOM) | Android (`uiautomator dump`) | iOS (XCUITest tree, VoiceOver) |
| --- | --- | --- | --- | --- |
| 01 | `CheckboxListTile`, checked | `role="checkbox"`, `aria-checked="true"`, named | `CheckBox`, checked | 1, "on" |
| 02 | `CheckboxListTile`, not checked | `aria-checked="false"` | `CheckBox`, not checked | 0, "off" |
| 03 | `CheckboxListTile(tristate: true, value: null)` | `aria-checked="false"` | `CheckBox`, `checked="false"` in the dump | 0, "off" |
| 04 | `Checkbox(tristate: true, value: null, semanticLabel:)` | as 03 | as 03 | 0, "off" |
| 05 | `Checkbox` beside a `Text` in a `Row` | checkbox with no name, then the text | `CheckBox` with no description, then a `View` | switch with no label, then static text |
| 06 | `MergeSemantics` around that `Row` | one checkbox named by the text | one `CheckBox` | one switch |
| 07 | `CupertinoCheckbox(semanticLabel:)`, checked | as 01 | as 01 | 1, "on" |
| 08 | `CupertinoCheckbox(tristate: true, value: null)` | as 03 | as 03 | 0, "off" |
| 09 | `Semantics(checked: true, enabled: true, label:, onTap:)` | as 01 | as 01 | 1, "on" |
| 10 | `Semantics(checked: false, mixed: true, ...)` | as 03 | as 03 | 0, "off" |
| 11 | `Semantics(container: true, explicitChildNodes: true, label:)` around two tiles | `role="group"` with `aria-label`, the two checkboxes inside | a `View` with the label whose children are the two `CheckBox`es | an `Other` with the label, read as a stop of its own, then the two switches |
| 12 | the same with `role: SemanticsRole.region` | `role="region"` with `aria-label` | as 11 | as 11 |
| 13 | `CheckboxListTile(onChanged: null)`, checked | `aria-disabled="true"`, `aria-checked="true"` | `CheckBox`, not enabled, not clickable | 1, disabled; "dimmed Switch button on" |
| 14 | tile with a subtitle | named "k14 Email Once a week" | description with a line break between the two | label with the line break |
| 15 | a `Text` above a tile | text, then the checkbox | a `View`, then the `CheckBox` | static text, then the switch |
| 16 | `MergeSemantics` around a `CupertinoCheckbox` and a `Text` | one checkbox named by the text | one `CheckBox` | one switch |
| 17 | `Semantics(button: true, label:, onTap:)` | `role="button"` | `Button` | button |
| 18 | `Semantics(container: true, label:)` around one tile, no `explicitChildNodes` | as 11 | as 11 | as 11 |

## The mixed state

The uiautomator dump has one boolean for the checked state, so it cannot
show a third. The instrumented test reads `AccessibilityNodeInfo.getChecked()`
and finds `CHECKED_STATE_PARTIAL` for a mixed Flutter checkbox on Android 17.

The web and iOS results come from the engine, not from the widgets: the
widget tests find `CheckedState.mixed` on the semantics node for fixtures
03, 04, and 10. See FL-044 for the two places in the engine.

## Native comparison on Android

TalkBack said no state for an unchecked Flutter checkbox, so a native screen
was added for one run (`ProbeNativeActivity.kt.txt`: three
`android.widget.CheckBox` views, the third with its node set to
`CHECKED_STATE_PARTIAL` through an accessibility delegate) and walked the
same way. TalkBack 17.0 on the Pixel_10a emulator, Android 17:

| Control | TalkBack |
| --- | --- |
| native, checked | "checked. n02 native checked. Check box", "Double-tap to toggle" |
| native, not checked | "not checked. n01 native unchecked. Check box", "Double-tap to toggle" |
| native, node set to partial | "not checked. n03 native partial. Check box", "Double-tap to toggle" |
| Flutter, checked | "checked.", "Email me product updates", "Check box" |
| Flutter, not checked | "Email me product updates", "Check box" |
| Flutter, mixed | "Select all", "Check box" |

So the missing "not checked" is specific to the Flutter node (FL-045), and
TalkBack did not speak a partial state for either kind of node (FL-044).
In the first native run the unchecked box was not read at all: TalkBack's
focus was already on it, and focusing a node that has focus says nothing.
The order was changed and the run repeated.

## What it shows

- **`CheckboxListTile` is one control** with the name, role, and state
  (01, 02). A bare `Checkbox` beside a `Text` is two elements and the box
  has no name (05); `MergeSemantics` joins them (06, 16).
- **Mixed is lost** on the web and iOS whatever widget is used (03, 04,
  08, 10).
- **A labelled container around checkboxes is a group on the web**
  (`role="group"` with `aria-label`), a parent `View` on Android, and an
  element read before the boxes on iOS (11, 18). `SemanticsRole.region`
  changes the web role only (12).
- **A disabled checkbox** keeps its state and is marked disabled on all
  three (13).

The VoiceOver walk on iOS stopped moving at fixture 14, at the bottom of the
first screen. VoiceOver on the web was not part of the probe.
