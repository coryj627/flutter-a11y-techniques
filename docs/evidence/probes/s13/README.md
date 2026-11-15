# S13 probe: what each role flag exposes

Run on 2026-11-15, Flutter 3.47.5, before the S13 examples were written. Two
fixtures, each a second entry point and not part of the app:
`probe-1.dart.txt` (one `Semantics` property per fixture, on plain text) and
`probe-2.dart.txt` (custom controls, and roles added to the SDK's widgets).
Unless a fixture says otherwise it is `Semantics(container: true, ...)`
around a `Text`, with `onTap` given to `Semantics` directly.

## Round 1: one property per fixture

| # | `Semantics` properties | Web (Chromium) | Android (`uiautomator dump`) | iOS (XCUITest type; VoiceOver) |
| --- | --- | --- | --- | --- |
| 01 | `button`, `onTap` | `role="button"` | `Button`, clickable | Button; (first element, not heard) |
| 02 | `link`, `onTap` | `<a>` with no `href`: text, not a link | `Button`, clickable | Link; "n02 link, Link" |
| 03 | `link`, `linkUrl`, `onTap` | `<a href>`: link | `View`, clickable | Link; "n03 link url, Link" |
| 04 | `image` | `role="img"` | `ImageView` | Image; "Image" |
| 05 | `selected: true`, `onTap` | `role="button"`, `aria-current="true"` | `View`, clickable, selected | Other; "selected, n05 selected" |
| 06 | `button`, `selected: true`, `onTap` | `role="button"`, `aria-current="true"` | `Button`, clickable, selected | Button; "selected, n06 button selected, Button" |
| 07 | `toggled: true`, `onTap` | `role="switch"`, `aria-checked="true"` | `Switch`, checked | Switch, value 1, **not enabled**; "dimmed, Switch button, on" |
| 08 | `checked: true`, `onTap` | `role="checkbox"`, `aria-checked="true"` | `CheckBox`, checked | Switch, value 1, **not enabled**; "dimmed, Switch button, on" |
| 09 | `checked: true`, `inMutuallyExclusiveGroup`, `onTap` | `role="radio"`, `aria-checked="true"` | `RadioButton`, checked | Button; "n09 radio, Button", with no state |
| 10 | `keyboardKey`, `onTap` | `role="button"` (from the tap action) | `View`, clickable | Static text; "n10 key" |
| 11 | `keyboardKey`, `button`, `onTap` | `role="button"` | `Button`, clickable | Button; "n11 key, Button" |
| 12 | `slider`, `value`, `onIncrease`, `onDecrease` | `<input type="range">` with no name ([FL-028](../../../flutter-limitations.md#fl-028)) | `SeekBar`, description "5, n12 slider" | Other, value 5; "n12 slider, 5, adjustable" |
| 13 | `button`, no action | `role="button"`, no `flt-tappable` | `Button`, not clickable | Button; "Button" |
| 14 | `onTap`, no role | `role="button"` ([FL-006](../../../flutter-limitations.md#fl-006)) | `View`, clickable | Static text; name only |
| 15 | `button` around `GestureDetector(excludeFromSemantics: true)` | `role="button"`, no `flt-tappable` | `Button`, not clickable | Button; "Button" |
| 16 | none (plain `Text`) | text | `View` | Static text |
| 17 | `button`, `enabled: false` | `role="button"`, `aria-disabled="true"` | `Button`, not enabled | Button, not enabled; "dimmed, Button" |
| 18 | `button`, `toggled: true`, `onTap` | `role="switch"` | `Switch`, checked | Switch; "dimmed, Switch button, on" |
| 19 | `header` | `<h2>` | `View` | Static text; no "Heading" ([FL-003](../../../flutter-limitations.md#fl-003), [FL-005](../../../flutter-limitations.md#fl-005)) |
| 20 | `button`, `link`, `onTap` | `<a>` with no `href`: text | `Button`, clickable | Button; "Button, Link" |
| 21 | `Focus` around `Text` | an element with `tabindex="0"` and no role | `View` | Static text |
| 22 | `GestureDetector(onTap:)` around `Text` | `role="button"` | `View`, clickable | Static text |
| 23 | `button`, `image`, `onTap` | `role="button"` | `ImageView`, clickable ([FL-031](../../../flutter-limitations.md#fl-031)) | Button; "Button, Image" |

## Round 2: custom controls and added roles

"Custom" is `FocusableActionDetector` around the `Semantics` shown, around a
`GestureDetector(onTap:)`.

| # | Fixture | Web | Android | iOS VoiceOver |
| --- | --- | --- | --- | --- |
| 01 | `toggled: true`, `enabled: true`, `onTap` | `switch`, checked | `Switch`, enabled | (first element, not heard) |
| 02 | `checked: true`, `enabled: true`, `onTap` | `checkbox`, checked | `CheckBox` | "Switch button, on. Double tap to toggle setting" |
| 03 | radio as round 1 fixture 09, with `enabled: true` | `radio`, checked | `RadioButton`, checked | "r03 radio enabled, Button" |
| 04 | `Semantics(button: true)` around `FilledButton` | a `button` inside a `button`, both named by the text | a `Button` with no name, not clickable, and inside it the `Button` "r04 wrapped" | one stop: "r04 wrapped, Button" |
| 05 | the same with `container: true` | as 04 | as 04 | as 04 |
| 06 | `Semantics(link: true)` around `TextButton` | `button` | a `Button` with no name around the `Button` | "r06 link wrap, Button" |
| 08 | custom, `button`, `enabled: true` | `button`, `tabindex="0"` | `Button`, clickable | "Button" |
| 09 | custom, no `Semantics` | `button`, `tabindex="0"` | `View`, clickable | name only |
| 10 | custom, `button`, `enabled: true`, gesture excluded from semantics | `button`, `tabindex="0"`, no `flt-tappable` | `Button`, not clickable | "Button" |
| 11 | `button`, `enabled: true` on text, no action | `button`, no `tabindex` | `Button`, not clickable | "Button" |
| 12 | `SwitchListTile` | `switch` | `Switch` | "Switch button, on. Double tap to toggle setting" |
| 13 | `CheckboxListTile` | `checkbox` | `CheckBox` | "Switch button, on. Double tap to toggle setting" |
| 14 | `MergeSemantics` row with `CupertinoSwitch` | `switch` | `Switch` | "Switch button, on. Double tap to toggle setting" |
| 15 | custom, `toggled`, `enabled: true` | `switch`, `tabindex="0"` | `Switch` | "Switch button, on. Double tap to toggle setting" |
| 16 | custom, `button`, `selected: true`, `enabled: true` | `button`, `aria-current="true"` | `Button`, selected | "selected, r16 custom, Button" |
| 17 | custom, `button`, `selected: false`, `enabled: true` | `button`, `aria-current="false"` | `Button` | "r17 custom, Button" |

On web a click sent to the element itself (`element.click()`, which is what
a screen reader's activation command produces) activated fixtures 08, 09,
and 15, and did nothing for 10 and 11.

## What it shows

- `button`, `image`, `toggled`, `checked`, and `selected` reach all three
  platforms. `header` is S05's subject.
- **`link` alone is a link on iOS only.** On Android it is a `Button`; on
  the web it is an `<a>` with no `href`, which has no role. With `linkUrl`
  it is a link on the web and is no longer a `Button` on Android
  ([FL-032](../../../flutter-limitations.md#fl-032)). Links are left to C03.
- **`toggled` or `checked` without `enabled: true` is a dimmed switch for
  VoiceOver on iOS** (round 1, 07, 08, 18; with `enabled: true` in round 2
  it is not) ([FL-033](../../../flutter-limitations.md#fl-033)).
- **`keyboardKey` changes nothing on any platform** (10, 11)
  ([FL-034](../../../flutter-limitations.md#fl-034)).
- **A checkbox is a switch for VoiceOver on iOS**, whether it is
  `Semantics(checked:)` or a `CheckboxListTile`
  ([FL-035](../../../flutter-limitations.md#fl-035)).
- A checked radio button was read by VoiceOver on iOS as "Button" with no
  state (round 1, 09; round 2, 03). Not followed up here; it belongs to F08
  Radio group.
- A role with no action (13, 15, round 2 10 and 11) is still announced as a
  button everywhere. Android marks it as not clickable, and the web element
  has no `flt-tappable` and ignores a click sent to it.
- A role added around a widget that has one already (round 2, 04 to 06)
  makes a second, unnamed button around the real one on Android and a
  button inside a button on the web. VoiceOver on iOS stops once.
- A tap action with no role (14, 22, round 2 09) is a button on the web
  only ([FL-006](../../../flutter-limitations.md#fl-006)).

TalkBack was not part of the probe; what it says was recorded with the
examples (`docs/evidence/S13/talkback-android.md`).
