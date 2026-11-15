# S14 probe: where `Semantics(value:)` goes

Run on 2026-11-15, Flutter 3.47.5, before the S14 examples were written. The
fixture is `probe.dart.txt` (a second entry point, not part of the app).
Every fixture is `Semantics(container: true, label:, value:, ...)` around
excluded text, unless it says otherwise.

| # | Fixture | Web (Chromium) | Android (`uiautomator dump`) | iOS (XCUITest; VoiceOver) |
| --- | --- | --- | --- | --- |
| 01 | `label: 'Rating'`, `value: '3 out of 5'` | text "Rating 3 out of 5" | `View`, description "3 out of 5, Rating" | static text, value "3 out of 5"; "Rating, 3 out of 5" |
| 02 | 01 with `onIncrease`, `onDecrease`, `increasedValue`, `decreasedValue` | `<input type="range" role="slider">` with `aria-valuetext="3 out of 5"`, `aria-valuenow="1"`, minimum 0, maximum 2; the name is on the parent element, not the slider ([FL-028](../../../flutter-limitations.md#fl-028)) | `SeekBar`, description "3 out of 5, Rating" | value "3 out of 5"; "Rating, 3 out of 5, adjustable. Swipe up or down with one finger to adjust the value" |
| 03 | 02 with `slider: true` | as 02 | `SeekBar`, clickable | as 02 |
| 04 | `label: 'Progress'`, `value: 'Step 2 of 4'` | text "Progress Step 2 of 4" | `View`, "Step 2 of 4, Progress" | "Progress, Step 2 of 4" |
| 05 | `button`, `label: 'Notifications'`, `value: 'enabled'`, `onTap` | `role="button"` named "Notifications enabled" | `Button`, "enabled, Notifications" | button, value "enabled"; "Notifications, enabled, Button" |
| 06 | `toggled: true`, `label: 'Alarm'`, `value: 'Activated'` | `role="switch"`, `aria-label="Alarm Activated"`, checked | `Switch`, checked, "Activated, Alarm" | switch, value 1; "Alarm, Switch button, on": the value is not read |
| 07 | `checked: true`, `label: 'Alarm'`, `value: 'Activated'` | `role="checkbox"`, `aria-label="Alarm Activated"` | `CheckBox`, checked, "Activated, Alarm" | as 06 |
| 08 | `MergeSemantics` of `Semantics(value: 'Activated')` and a `CheckboxListTile` | `role="checkbox"`, `aria-label="Alarm tile Activated"` | `CheckBox`, "Activated, Alarm tile" | as 06 |
| 09 | `button`, `label: 'Cart, 3 items'` | `button "Cart, 3 items"` | `Button`, "Cart, 3 items" | "Cart, 3 items, Button" |
| 10 | `label: 'Storage'`, `value: '40%'` | text "Storage 40%" | `View`, "40%, Storage" | "Storage, 40%" |
| 11 | 10 as `SemanticsRole.progressBar` with `value: '40'`, `minValue`, `maxValue` | `role="progressbar"`, `aria-valuenow="40"`, `aria-label="Storage 40"` | `ProgressBar`, "40, Storage" | "Storage, 40" |
| 12 | `button`, `selected: true`, `label: 'Step 2'`, `value: 'current'` | `button "Step 2 current"`, `aria-current="true"` | `Button`, selected, "current, Step 2" | "selected, Step 2, current, Button" |

## What it shows

- **iOS has a value of its own.** XCUITest reports `value` apart from the
  label, and VoiceOver reads it after the label.
- **Android has no separate value.** The engine writes "value, label" into
  the node's content description.
- **On the web a value is appended to the name**, in the element's text or
  its `aria-label`, except on an adjustable node, where it is
  `aria-valuetext` ([FL-037](../../../flutter-limitations.md#fl-037)).
- **A node with `onIncrease` or `onDecrease` is a slider on all three
  platforms**, with or without `slider: true`. On the web it has no name
  ([FL-028](../../../flutter-limitations.md#fl-028)), and its numeric range
  is a made-up 0 to 2.
- **A value on a switch or checkbox does not replace "on" and "off"**
  ([FL-036](../../../flutter-limitations.md#fl-036)). iOS drops it, Android
  adds it to the description beside the checked state, and the web adds it
  to the name.

TalkBack was not part of the probe; what it says was recorded with the
examples.
