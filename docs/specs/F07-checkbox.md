# Spec: F07 Checkbox

Status: Draft 1 (2026-11-16), written with the build. First technique of
batch 2 ([plan](../plan.md)). Flutter pin: 3.47.5.

A checkbox is a control with two states, checked and not checked, and
sometimes a third, mixed. This spec covers its name, role, and state, the
mixed state of a "select all" box, and a label for a group of checkboxes.
A switch is F09. Radio buttons are F08. A checkbox in a menu
(`menuItemCheckbox`) belongs to the menu technique. Rewording "checked" is
[S14 Values and state descriptions](S14-values-and-state-descriptions.md)
([FL-036](../flutter-limitations.md#fl-036)). Target size is V13.

## 1. Rule

A checkbox and its visible label are one control. Assistive technology is
given its name, the checkbox role, and whether it is checked, not checked,
or mixed, and the state is kept true as it changes. Checkboxes that answer
one question are grouped, and the question is the group's name.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Limitation | Limitation | Limitation |

Checked is right on all three. The limitations are in the other two
states:

- iOS has no checkbox control. Flutter exposes a checkbox there as a
  switch, read "on" or "off" ([FL-035](../flutter-limitations.md#fl-035)).
- A mixed checkbox is exposed as not checked on the web and on iOS. On
  Android the node says partial and TalkBack says no state
  ([FL-044](../flutter-limitations.md#fl-044)).
- On Android TalkBack says no state for a checkbox that is not checked,
  where it says "not checked" for a native one
  ([FL-045](../flutter-limitations.md#fl-045)).

There is no workaround for any of them within the SDK.

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [4.1.2 Name, Role, Value](https://www.w3.org/TR/WCAG22/#name-role-value) | A checkbox is a user interface component: its name and role can be programmatically determined, and its state can be set and is notified to assistive technology when it changes |
| [1.3.1 Info and Relationships](https://www.w3.org/TR/WCAG22/#info-and-relationships) | The label beside a box belongs to that box, and a question above several boxes belongs to all of them. Both relationships are shown visually and must be programmatically determinable |

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | The checkbox and its label are one element: the label names the checkbox, and the whole row is the control | [Android Compose Checkbox Controls](https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/components/CheckboxControls.md) ("a wrapping layout to programmatically associate a label and subsume the `Checkbox`'s role and toggle handling"), [iOS Checkboxes](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/Checkboxes.md) ("Use `Toggle(\"Label Text\")` to create label text"), [MDN: input type=checkbox](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/input/checkbox) (a `<label>` makes the text part of the hit area) |
| R2 | It has the checkbox role | [APG Checkbox](https://www.w3.org/WAI/ARIA/apg/patterns/checkbox/) ("The checkbox has role `checkbox`"), Android Compose Checkbox Controls (`role = Role.Checkbox`) |
| R3 | Its state is exposed as checked or not checked | APG Checkbox (`aria-checked` `true` or `false`), iOS Checkboxes (a value of "Checked" or "Unchecked") |
| R4 | A checkbox that stands for several others is mixed when only some of them are checked | APG Checkbox ("When partially checked, it has state `aria-checked` set to `mixed`"), MDN: input type=checkbox (`indeterminate`) |
| R5 | Space changes the state when the checkbox has focus | APG Checkbox ("Space: When the checkbox has focus, pressing the Space key changes the state of the checkbox") |
| R6 | A group of checkboxes has a label that matches the visible text for the group | iOS Checkboxes ("Checkbox groups need an accessibility label for the group which matches the visible group label text"), APG Checkbox ("If a set of checkboxes is presented as a logical group with a visible label, the checkboxes are included in an element with role `group` that has the property `aria-labelledby`") |
| R7 | The control keeps a touch target of at least 48 by 48 | Android Compose Checkbox Controls (`Modifier.minimumInteractiveComponentSize()`) |

The iOS document notes that SwiftUI has no checkbox control or trait and
that UI tests find one through `.switches`. The same is true of Flutter on
iOS.

Flutter references for the mechanisms used:

- [`CheckboxListTile`](https://api.flutter.dev/flutter/material/CheckboxListTile-class.html)
- [`SemanticsProperties.checked`](https://api.flutter.dev/flutter/semantics/SemanticsProperties/checked.html)
- [`SemanticsProperties.mixed`](https://api.flutter.dev/flutter/semantics/SemanticsProperties/mixed.html)

Comparison bar: the HTML `<input type="checkbox">` with a `<label>`, and
`aria-checked="mixed"` for the third state.

## 5. Examples

Every example ends with a count of changes, so a person or a test can tell
that a control worked.

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-tile` | Material | "Email me product updates" as one control | `CheckboxListTile` | R1, R2, R3, R5, R7 |
| `good-cupertino` | Cupertino | The same with a Cupertino box and visible text | `MergeSemantics` (through `TestId`) around a `GestureDetector`, a `CupertinoCheckbox`, and a `Text` | R1, R2, R3, R5, R7 |
| `good-custom` | Widgets | The same drawn by hand | `Semantics(checked:, enabled: true, label:, onTap:)`; Space through `FocusableActionDetector` | R1, R2, R3, R5, R7 |
| `good-mixed` | Material | "Select all" over two boxes, mixed while one is checked | `CheckboxListTile(tristate: true, value: null)` | R4 |
| `good-group` | Material | Two boxes under the question "Contact me by" | `Semantics(container: true, explicitChildNodes: true, label:)` around the boxes, with the visible question in `ExcludeSemantics` | R6 |

### Bad

| Slug | Defect | Violates | Fails |
| --- | --- | --- | --- |
| `bad-unlabelled` | A `Checkbox` with a `Text` beside it. The box has no name, the text is a separate element, and a tap on the text does nothing | R1 | 4.1.2, 1.3.1 |
| `bad-no-state` | A hand-drawn checkbox exposed as a button. Nothing says it is a checkbox or whether it is checked | R2, R3 | 4.1.2 |
| `bad-mixed-as-unchecked` | "Select all" with two states: it is "not checked" while one box under it is checked | R4 | 4.1.2 |
| `bad-group-unlabelled` | The question is plain text above the boxes | R6 | 1.3.1 |

`bad-mixed-as-unchecked` can be told from `good-mixed` only in the Android
tree, not in TalkBack's speech. On iOS and the web the good example is
exposed the same way
([FL-044](../flutter-limitations.md#fl-044)); the tests there assert that
sameness, so they fail when Flutter fixes it.

## 6. Assertions by layer

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Every checkbox: its label on one node, a checked state that is not a toggle and not in an exclusive group, enabled, a tap action; tap, the semantics action, and Space each change the state. A tap on the label text changes the box. `good-mixed`: the mixed state, and each step of the cycle. `good-group`: the question on a node whose children are the two boxes, once. Bad: a checkbox with no label and text with no action; a button with no checked state before and after use; not checked while one child is; the question as a leaf beside the boxes. Guidelines in light and dark and 200% text for good examples |
| L3 web | Every checkbox: role, accessible name, `aria-checked`, a click and Space. `good-mixed`: the cycle, and `aria-checked="false"` while mixed (FL-044). `good-group`: role `group` named by the question, containing both. Bad: a checkbox with no name; a button with no `aria-checked`; no named group |
| L3 Android | Every checkbox: the `CheckBox` class, description, checkable, the checked state before and after a click. `good-mixed`: `CHECKED_STATE_PARTIAL`, and the cycle. `good-group`: a `View` with the question whose children are the boxes. Bad: a `CheckBox` with no description; a `Button` that is not checkable; not checked while one child is; the question as a sibling |
| L3 iOS | Every checkbox: type `.switch` (FL-035), label, value "0" then "1" after a tap. `good-mixed`: value "0" while mixed (FL-044). `good-group`: one `Other` element with the question. Bad: a switch with no label; a button with no value; "0" while one child is "1"; the question as static text |
| L4 TalkBack | What is read with focus on each checkbox, before and after it is changed; the mixed box; the group's question |
| L4 VoiceOver iOS | Every utterance between the "Example" heading and the change count, compared as a whole list |
| L4 VoiceOver web | Every stop between the "Example" heading and the change count, in Chromium and WebKit |

## 7. What the build found (Flutter 3.47.5)

The probe that came first is in [evidence/probes/f07](../evidence/probes/f07/).

- **Checked and not checked are right in every tree.** `role="checkbox"`
  with `aria-checked` on the web, a checkable `CheckBox` on Android, and a
  switch with the value 1 or 0 on iOS
  ([FL-035](../flutter-limitations.md#fl-035)).
- **The mixed state is lost on the web and iOS**
  ([FL-044](../flutter-limitations.md#fl-044)). The semantics node is
  mixed, and the web engine writes `aria-checked="false"` and the iOS
  engine a switch that is off. VoiceOver reads "Select all unchecked
  checkbox" and "Select all, Switch button, off". On Android the node says
  partial (`CHECKED_STATE_PARTIAL`, Android 16 and later) and TalkBack
  says no state for it. No platform tells a user that the box is mixed.
- **TalkBack says no state for an unchecked Flutter checkbox**
  ([FL-045](../flutter-limitations.md#fl-045)): "Email me product updates,
  Check box". A native `CheckBox` on the same device is read "not
  checked". This had been seen in S01 and S13 and left for here; the
  native comparison is in the probe folder.
- **A bare `Checkbox` beside a `Text` is two elements** on every platform,
  and the box has no name. `MergeSemantics` joins the name; it does not
  make the text part of the target, which needs a tap handler.
- **`CupertinoCheckbox` has no list tile.** `good-cupertino` builds the row
  by hand.
- **A labelled container is a group on the web only.** There it is
  `role="group"` with the question as its name, and VoiceOver says
  "Contact me by group" on the way in and "end of Contact me by group" on
  the way out. On Android it is a parent `View` and on iOS an element
  before the boxes; both read the question once, in order, which is also
  what the bad example sounds like. The difference on those two is in the
  tree only.
- **On the web VoiceOver follows a checkbox that has no name with its help
  message at once** ("You are currently on a checkbox…"). The walk takes
  the phrase Guidepup logged for that move: "unchecked checkbox" in
  Chromium. Playwright's WebKit build guesses a name for the box from the
  text beside it and reads "Email me product updates unchecked checkbox",
  then the text again; S01 saw the same guess.
- **`bad-mixed-as-unchecked` and `good-mixed` sound the same everywhere.**
  Only the Android tree tells them apart.
- `XCUIVoiceOverService` returns the first 64 characters of an utterance:
  the long label's line ends "Double tap to toggle".

**Not done yet.** A disabled checkbox is in the probe (fixture 13) and not
in an example. What a screen reader says at the moment a box changes (the
change announcement, as opposed to what it reads on arriving) is not
recorded. `aria-describedby` for a checkbox, which the APG pattern allows,
is S15's subject. Whether the group's question is heard when focus goes
straight to a box inside the group, without passing the question, was not
tested on any platform.
