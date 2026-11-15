# Spec: S14 Values and state descriptions

Status: Draft 1 (2026-11-15), written with the build. Sixth technique of
batch 1 ([plan](../plan.md)). Flutter pin: 3.47.5.

A value is what a control holds now: a rating, a step, a mode. This spec
covers how a custom control says its value, and what Flutter can and cannot
do about the wording of a standard control's state. Which role a control
has, and the on/off state that comes with the switch role, is
[S13 Roles and traits](S13-roles-and-traits.md). The label on a tap action
("double-tap to activate alarm") is I06 Action labels. Sliders, progress
indicators, and steppers have entries of their own (F10, and the progress
entry); they appear here only as far as their value text goes.

## 1. Rule

A control that holds a value or a state exposes it in words, apart from its
name, and the words change when the value does. Where the value can be
adjusted, the control also says what it would become.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies | Applies | Applies |

On the web anything adjustable is a slider, and a slider has no accessible
name there ([FL-028](../flutter-limitations.md#fl-028)). `good-rating` and
`good-slider-format` expose the right value on the web and no name; the
catalog carries a note on the web platform and in both titles.

Custom wording for the state of a switch or checkbox, the subject of the
two Android source documents, cannot be done on any platform
([FL-036](../flutter-limitations.md#fl-036)). The technique as a whole still
applies.

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [4.1.2 Name, Role, Value](https://www.w3.org/TR/WCAG22/#name-role-value) | The value and state of a control can be read by assistive technology, and changes to them are available to it |

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | A custom control with a value or state that changes exposes it as its value, not in its name | [CVS iOS Accessibility Value](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/AccessibilityValue.md) ("The value describes the current state ... not the label or action"), [Apple: accessibilityValue](https://developer.apple.com/documentation/uikit/uiaccessibilityelement/accessibilityvalue) |
| R2 | The value is in words a person would use: "3 out of 5", "Step 2 of 4" | CVS iOS Accessibility Value (its examples), [MDN: aria-valuetext](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Reference/Attributes/aria-valuetext) (for when the number alone is not meaningful) |
| R3 | The value is updated when the state changes | CVS iOS Accessibility Value ("Update the value dynamically as the state changes") |
| R4 | A value that can be adjusted has the adjust actions, so a screen reader user can change it | CVS iOS Accessibility Value ("combine `.accessibilityValue` with `.accessibilityAdjustableAction`") |
| R5 | Standard controls give their own values; nothing is added | CVS iOS Accessibility Value ("Native controls like `Slider`, `Toggle`, and `Stepper` provide their own values automatically") |
| R6 | The wording of a standard control's state can be replaced with words that fit it better ("Activated" for "Checked") | [CVS Compose Custom State Descriptions](https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/interactions/CustomStateDescriptions.md), [CVS View Custom State Descriptions](https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/dynamicbehaviors/CustomStateDescriptions.md), [Android: View.setStateDescription](https://developer.android.com/reference/android/view/View#setStateDescription(java.lang.CharSequence)) |

R6 cannot be met in Flutter 3.47.5 for a switch or a checkbox
([FL-036](../flutter-limitations.md#fl-036)). It can for a slider, whose
value text is `semanticFormatterCallback` (`good-slider-format`). The second
half of the CVS View document, the label of the click action, is I06.

Flutter references for the mechanisms used:

- [`SemanticsProperties.value`](https://api.flutter.dev/flutter/semantics/SemanticsProperties/value.html),
  `increasedValue`, `decreasedValue`
- [`SemanticsProperties.onIncrease`](https://api.flutter.dev/flutter/semantics/SemanticsProperties/onIncrease.html),
  `onDecrease`
- [`Slider.semanticFormatterCallback`](https://api.flutter.dev/flutter/material/Slider/semanticFormatterCallback.html)

The inventory row names no APG pattern and no HTML element.

## 5. Examples

Every example ends with a count of changes, so a person or a test can tell
that a control worked. The star rating and the step indicator are examples of the CVS iOS
document. Its third example, an on/off toggle with the value "enabled", is
`good-custom-switch` in S13, because in Flutter the switch role carries that
state. The three-mode button here shows a value on a button whose state no
role carries.

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-rating` | Widgets | A star rating read as "Rating, 3 out of 5" that a screen reader can adjust | `Semantics(label:, value:, increasedValue:, decreasedValue:, onIncrease:, onDecrease:)` around stars with no semantics; arrow keys through `FocusableActionDetector` | R1, R2, R3, R4 |
| `good-step` | Widgets | Four step circles read as "Progress, Step 2 of 4" | `Semantics(label:, value:)` around `ExcludeSemantics` | R1, R2, R3 |
| `good-button-value` | Widgets | A button with three modes that says which it is in | `Semantics(button: true, label:, value:)` | R1, R3 |
| `good-slider-format` | Material | A slider read in minutes, not percent | `Slider(semanticFormatterCallback:)` in a `MergeSemantics` row for its name | R2, R5, R6 |

### Bad

| Slug | Defect | Violates | Fails |
| --- | --- | --- | --- |
| `bad-rating-no-value` | The rating has adjust actions and no value: "Rating", and never how many stars | R1 | 4.1.2 |
| `bad-stale-value` | The value is fixed text. The stars change and the value stays "3 out of 5" | R3 | 4.1.2 |
| `bad-step-no-value` | The circles are read as "1", "2", "3", "4"; nothing says which is current | R1 | 4.1.2, 1.3.1 |
| `bad-button-no-value` | The mode is shown by an icon only: "Repeat, button" in all three modes | R1 | 4.1.2 |
| `bad-value-on-switch` | `value` used to reword a switch's state. TalkBack reads both wordings, VoiceOver on iOS ignores the value, and on the web it becomes part of the name ([FL-036](../flutter-limitations.md#fl-036)) | R6 (cannot be met) | — (the state is still exposed) |

There is no Cupertino example. The mechanism is `Semantics`, which is the
same under either design language, and `CupertinoSlider` has no
`semanticFormatterCallback`, so the one widget-specific example has no
Cupertino counterpart.

`good-step` and `bad-step-no-value` locate the indicator by a
`Semantics(identifier:)` on the node itself and by the text of the numbers;
the other controls use `TestId`.

## 6. Assertions by layer

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Good: label, value, `increasedValue`, `decreasedValue`, the increase and decrease actions; the value after each semantics action, arrow key, tap, Enter, and Space; that the name does not change; the top of the range; guidelines in light and dark and 200% text. Bad: no value before or after a change; the first value after two changes; four numbered nodes with no value and no selected state; the same semantics in three modes; a toggled state and a value together |
| L3 web | Good: a slider with `aria-valuetext`, and its change on arrow keys; the step text; the button's name with its mode, after click, Enter, and Space; the slider in minutes. The slider's own name is asserted to be empty ([FL-028](../flutter-limitations.md#fl-028)). Bad: empty `aria-valuetext` and a range of one point; `aria-valuetext` unchanged after two changes; four texts and no current marker; the same name in three modes; a switch whose name changes with its state |
| L3 Android | Good: `SeekBar` or `Button` class and the description "value, label"; the description after scroll forward and backward, and after a click. Bad: a description with no value and no state description; the wrong value after two increases ([FL-038](../flutter-limitations.md#fl-038)); four numbered nodes with no state; the same description in three modes; a `Switch` with both a checked state and the value in its description |
| L3 iOS | Good: label and value apart, and the value after a tap on a star, the Next button, or the control. Bad: an empty value before and after; the first value after a change; four texts with no value; an empty value in three modes; a switch whose value is 0 or 1 and not the given word |
| L4 TalkBack | What is read with focus on each control, and again after it is changed |
| L4 VoiceOver iOS | Every utterance between the "Example" heading and the change count, compared as a whole list |
| L4 VoiceOver web | Non-sliders: every stop between the "Example" heading and the change count, in Chromium and WebKit. The four examples that are sliders on web: walked to the slider and judged in Chromium only, as in S01 |

## 7. What the build found (Flutter 3.47.5)

The probe that came first is in [evidence/probes/s14](../evidence/probes/s14/).

- **`Semantics(value:)` reaches all three platforms, in three shapes.** iOS
  has a value apart from the label, and VoiceOver reads "Rating, 3 out of
  5". Android has none: the engine writes "3 out of 5, Rating" into the
  content description, and TalkBack reads the value first. The web appends
  the value to the name, "Repeat Off"
  ([FL-037](../flutter-limitations.md#fl-037)), except on an adjustable
  node, where it is `aria-valuetext`.
- **A node with `onIncrease` or `onDecrease` is a slider everywhere**: a
  `SeekBar` on Android ("Slider. Swipe up or swipe down to adjust"),
  adjustable on iOS, and `<input type="range">` on the web. `slider: true`
  made no difference in the probe and is not used.
- **The custom rating has no name on the web**, like every Flutter slider
  ([FL-028](../flutter-limitations.md#fl-028)): the name is on the element
  around the `<input>`. The web test asserts the empty name so that a fix
  is noticed.
- **On Android `increasedValue` is read as the value straight after an
  increase** ([FL-038](../flutter-limitations.md#fl-038)). In
  `bad-stale-value` the node read "3 out of 5", then "4 out of 5" after one
  increase and after two. So `increasedValue` and `decreasedValue` have to
  be right, and the TalkBack walk increases twice before it listens.
- **With no `increasedValue` the web slider has a range of one point**: its
  minimum and maximum are the same (`bad-rating-no-value`). The arrow keys
  still change the rating, through Flutter's own key handling, and the web
  test asserts that. Whether a screen reader's adjust command can move such
  a slider was not tested.
- **A switch's state cannot be reworded**
  ([FL-036](../flutter-limitations.md#fl-036)). With `value` on a switch,
  TalkBack reads "off, Deactivated, Home alarm, Switch"; VoiceOver on iOS
  reads "Home alarm, Switch button, off"; the web names the switch "Home
  alarm Deactivated".
- **A slider's value text can be replaced**: `semanticFormatterCallback`
  gives "15 minutes" on all three platforms.
- **`XCUIVoiceOverService` returns the first 64 characters of an
  utterance.** The hint of an adjustable element is cut short in the iOS
  transcript ("Swipe up or down with one finger to").
- TalkBack's log for an element that is then changed ends with the change
  count's announcements ("Changes: 0", "Changes: 1"): the walk parks focus
  on the count before it changes the control, and the count is a live
  region.
- `bad-stale-value` sounds the same as `good-rating` until the rating is
  changed. The iOS and web VoiceOver walks do not change it; the tree tests
  on every platform do, and the TalkBack walk does.

**Not done yet.** The web VoiceOver transcript has to be recorded from the
owner's Terminal, so `web_tests/vo/s14_values_and_state_descriptions_vo.spec.js`
holds expected speech that has not been heard yet. VoiceOver's own adjust
gesture was not sent on iOS (the test API has no command for it); the iOS
tests change the rating by touch. Which elements a TalkBack swipe stops on
is not tested. The label of a tap action is left to I06, and a slider's
name on the web to F10.
