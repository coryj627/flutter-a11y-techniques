# Spec: F09 Switch

Status: Draft 1 (2026-11-17), written with the build. Third technique of
batch 2 ([plan](../plan.md)), built in wave 1. Flutter pin: 3.47.5.

A switch is a control that is on or off. This spec covers its name, role,
and state, a name that stays the same as the state changes, a switch at
the end of a list tile, and a label for a group of switches. A checkbox is
[F07 Checkbox](F07-checkbox.md), and radio buttons are
[F08 Radio group](F08-radio-group.md). Rewording "on" and "off" is
[S14 Values and state descriptions](S14-values-and-state-descriptions.md)
([FL-036](../flutter-limitations.md#fl-036)), and a custom switch with no
`enabled` flag is [S13 Roles and traits](S13-roles-and-traits.md)
([FL-033](../flutter-limitations.md#fl-033)). Target size is V13.

## 1. Rule

A switch and its visible label are one control. Assistive technology is
given its name, the switch role, and whether it is on or off, and the state
is kept true as it changes. The name does not change when the state does.
Switches that answer one question are grouped, and the question is the
group's name.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies | Applies | Applies |

All three have a switch role and an on or off state, and the SDK's
switches use them. A switch drawn by hand needs `enabled: true` beside
`toggled` on iOS ([FL-033](../flutter-limitations.md#fl-033)). On the web
Enter does not toggle a `CupertinoSwitch`
([FL-002](../flutter-limitations.md#fl-002)); Space does, which is what the
APG pattern requires.

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [4.1.2 Name, Role, Value](https://www.w3.org/TR/WCAG22/#name-role-value) | A switch is a user interface component: its name and role can be programmatically determined, and its state can be set and is notified to assistive technology when it changes |
| [1.3.1 Info and Relationships](https://www.w3.org/TR/WCAG22/#info-and-relationships) | The label beside a switch belongs to that switch, and a question above several switches belongs to all of them. Both relationships are shown visually and must be programmatically determinable |

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | The switch and its label are one element: the label names the switch, and the whole row is the control | [Android Compose Switch Controls](https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/components/SwitchControls.md) (a wrapping layout with `Modifier.toggleable()` that takes over the switch's role and toggle handling, so the label and switch are read "as a unit"), [iOS Toggles](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/Toggles.md) (`Toggle("Label Text")` for a visible and accessibility label) |
| R2 | It has the switch role | [APG Switch](https://www.w3.org/WAI/ARIA/apg/patterns/switch/) (role `switch`), Android Compose Switch Controls (`Role.Switch`), [MDN: ARIA switch role](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Reference/Roles/switch_role) |
| R3 | Its state is exposed as on or off, and changes as it changes | APG Switch (`aria-checked` `true` or `false`), iOS Toggles (VoiceOver users hear the "On" and "Off" state), MDN switch role (the state must be changed "dynamically when the switch is toggled") |
| R4 | The label does not change when the state changes | APG Switch ("it is critical the label on a switch does not change when its state changes") |
| R5 | Space changes the state when the switch has focus; Enter may | APG Switch, keyboard interaction (Space; Enter optional), MDN switch role (Space) |
| R6 | A group of switches has a label that matches the visible text for the group | APG Switch (a group with a visible label is `role="group"` with `aria-labelledby`, or a `fieldset` with a `legend`) |
| R7 | The control keeps a touch target of at least 48 by 48 | Android Compose Switch Controls (`Modifier.minimumInteractiveComponentSize()`) |

The iOS document says UI tests find a SwiftUI toggle with `.switches`; the
same is true of a Flutter switch on iOS, which the engine backs with a
native `UISwitch`.

Flutter references for the mechanisms used:

- [`SwitchListTile`](https://api.flutter.dev/flutter/material/SwitchListTile-class.html)
- [`CupertinoSwitch`](https://api.flutter.dev/flutter/cupertino/CupertinoSwitch-class.html),
  whose documentation shows a `CupertinoListTile` with a trailing switch
  inside `MergeSemantics`
- [`SemanticsProperties.toggled`](https://api.flutter.dev/flutter/semantics/SemanticsProperties/toggled.html)

Comparison bar: the HTML `<input type="checkbox" switch>` or an element with
`role="switch"` and a `<label>`.

## 5. Examples

Every example ends with a count of changes, so a person or a test can tell
that a control worked. Every switch starts off.

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-tile` | Material | "Bluetooth" as one control | `SwitchListTile` | R1 to R5, R7 |
| `good-cupertino` | Cupertino | The same with a Cupertino switch at the end of a list tile | `MergeSemantics` around a `CupertinoListTile` with a trailing `CupertinoSwitch` and `onTap`, as the `CupertinoSwitch` documentation shows | R1 to R5, R7 |
| `good-custom` | Widgets | The same drawn by hand | `Semantics(toggled:, enabled: true, label:, onTap:)`; Space and Enter through `FocusableActionDetector` | R1 to R5, R7 |
| `good-group` | Material | Two switches under the question "Notify me about" | `Semantics(container: true, explicitChildNodes: true, label:)` around the switches, with the visible question in `ExcludeSemantics` | R6 |

### Bad

| Slug | Defect | Violates | Fails |
| --- | --- | --- | --- |
| `bad-unlabelled` | A `Switch` with a `Text` beside it. The switch has no name, the text is a separate element, and a tap on the text does nothing | R1 | 4.1.2, 1.3.1 |
| `bad-tile-not-merged` | A `ListTile` with `onTap` and a trailing `Switch`, not merged. The row is a button named "Bluetooth" that never says on or off, and the switch inside it has no name: a second stop on Android and iOS, and never reached by VoiceOver on the web | R1 | 4.1.2, 1.3.1 |
| `bad-label-changes` | The label says the state: "Bluetooth off", then "Bluetooth on". The name changes with every change, and the state is heard twice | R4 | 4.1.2 |
| `bad-no-state` | A hand-drawn switch exposed as a button. Nothing says it is a switch or whether it is on | R2, R3 | 4.1.2 |

A group with its question as plain text above it is not repeated here:
it is F07's `bad-group-unlabelled`, and the probe showed switches behave
the same way as checkboxes there. A custom switch with no `enabled` flag is
S13's `bad-switch-not-enabled`, and a `value` used to reword the state is
S14's `bad-value-on-switch`.

## 6. Assertions by layer

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Every switch: its label on one node, a toggled state that is not a checked state, not a button or in an exclusive group, enabled, a tap action; a tap, the semantics action, and Space each change the state, and the name stays. A tap on the label text changes the switch. Enter changes the custom switch. `good-group`: the question on a node whose children are the two switches, once. Bad: a switch with no label and text with no action; a button with no toggled state around a switch with no label, before and after a tap; a label that changes with the state; a button with no toggled state before and after use. Guidelines in light and dark and 200% text for good examples |
| L3 web | Every switch: role, accessible name, `aria-checked`, a click and Space, the name kept; Enter, which toggles every switch but the Cupertino one (FL-002). A click on the text of `good-tile`. `good-group`: role `group` named by the question, containing both. Bad: a switch with no name and text that does nothing; a button with no `aria-checked` around a switch with no name; a name that changes; a button with no `aria-checked` |
| L3 Android | Every switch: the `Switch` class, description, checkable, the checked state before and after a click, the name kept. `good-group`: a `View` with the question whose children are the switches. Bad: a `Switch` with no description beside a `View`; a `Button` that is not checkable around a `Switch` with no description; a description that changes; a `Button` that is not checkable |
| L3 iOS | Every switch: type `.switch`, label, enabled, value "0" then "1" after a tap and "0" again. `good-group`: one `Other` element with the question. Bad: a switch with no label beside static text; a button with no value and a switch with no label; a label that changes; a button with no value |
| L4 TalkBack | What is read with focus on each switch, before and after it is changed, including the extra "checked" for one that is on (FL-100); the group's question; each element of the bad examples |
| L4 VoiceOver iOS | Every utterance between the "Example" heading and the change count, compared as a whole list |
| L4 VoiceOver web | Every stop between the "Example" heading and the change count, in Chromium and WebKit |

## 7. What the build found (Flutter 3.47.5)

The probe that came first is in [evidence/probes/f09](../evidence/probes/f09/).

- **The SDK's switches are right in every tree.** `role="switch"` with
  `aria-checked` on the web, a checkable `Switch` on Android, and a
  native switch with the value 0 or 1 on iOS, named by the tile's title.
  VoiceOver on the web says "Bluetooth off switch", VoiceOver on iOS
  "Bluetooth Switch button off", and TalkBack "off. Bluetooth, Switch".
  `SwitchListTile`, `CupertinoSwitch` in a merged `CupertinoListTile`, and
  `Semantics(toggled:, enabled: true)` sound the same everywhere.
- **TalkBack says "checked" as well as "on" for a switch that is on**
  ([FL-100](../flutter-limitations.md#fl-100)): "checked. on. Bluetooth,
  Switch". A native `android.widget.Switch` on the same emulator is read
  "ON. … Switch" (the comparison is in the probe folder). The off state
  has no such extra word. The state is right; it is said twice.
- **`CupertinoListTile` does not merge its parts.** Without the
  `MergeSemantics` that the `CupertinoSwitch` documentation puts around it,
  the row is a group (web), a clickable `View` (Android), or an element
  (iOS) named by the title, around a switch with no name (probe, fixture
  06). `good-cupertino` follows the documentation. The tile is 44 high,
  so the example keeps it at 48.
- **A Material `ListTile` with a trailing `Switch` is a button around a
  switch with no name** (`bad-tile-not-merged`). On Android and iOS that
  is two stops: "Bluetooth, Button" and "off. Switch". On the web the
  switch is inside a `role="button"`, whose content is presentational:
  VoiceOver never moves into it, and the user hears "Bluetooth button"
  and nothing about on or off (Chromium adds "group"). The tree spec
  finds the switch inside the button; the screen reader does not.
- **A label that says the state is heard twice and changes the name**
  (`bad-label-changes`): "Bluetooth off off switch" on the web, "Bluetooth
  off Switch button off" on iOS, "off. Bluetooth off, Switch" on
  Android, and the name is "Bluetooth on" once the switch is on.
- **Enter toggles the Material and the custom switch on the web, and not
  the Cupertino one** ([FL-002](../flutter-limitations.md#fl-002)). Space
  toggles all of them, which is what the APG pattern requires, so
  `good-cupertino` adds nothing for Enter, as S13 decided.
- **`enabled: true` is needed on a custom switch** for iOS
  ([FL-033](../flutter-limitations.md#fl-033), probe fixture 17);
  `good-custom` sets it, and the iOS test checks the switch is enabled.
- **A labelled container is a group on the web only**, as for checkboxes
  (F07): VoiceOver says "Notify me about group" on the way in and "end of
  Notify me about group" on the way out. On Android it is a parent `View`
  and on iOS an element read before the switches.
- **A switch beside a text, not joined, has no name** on every platform
  (`bad-unlabelled`), and a tap on the text does nothing.
- The first web VoiceOver recording expected the switch inside the button
  of `bad-tile-not-merged` to be a stop; both browsers skipped it, and the
  expectation was corrected to what they read.

**Not done yet.** A disabled switch is in the probe (fixtures 10 and 18:
marked disabled on all three, state kept) and not in an example. What a
screen reader says at the moment a switch changes, as opposed to what it
reads on arriving, is not recorded. Whether the group's question is heard
when focus goes straight to a switch inside the group was not tested. A
switch with visible text other than "on" and "off" beside it (the iOS
reference's `.accessibilityValue` case) is not built: a `value` on a
switch is dropped on iOS and added to the name elsewhere
([FL-036](../flutter-limitations.md#fl-036)).
