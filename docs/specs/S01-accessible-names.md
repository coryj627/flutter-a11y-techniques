# Spec: S01 Accessible names

Status: Draft 1 (2026-11-14), written with the build. First technique of
batch 1 ([plan](../plan.md)). Flutter pin: 3.47.5.

This spec covers how a control gets its name, shown on checkboxes and
switches. Names of buttons are in [C01](C01-button.md) and of text fields in
[F01](F01-text-fields.md). Each control has its own entry for its role,
state, and operation (F07 Checkbox, F08 Radio group, F09 Switch, F10 Slider);
text alternatives for images are S02 to S04.

## 1. Rule

Every control has a name that assistive technology can read. The name is the
visible text where there is some, says what the control is for, differs from
the names of other controls on the screen, and does not repeat the role.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies | Applies | Applies, except sliders |

On web a slider cannot be given a name (Flutter limitation FL-028).

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [1.3.1 Info and Relationships](https://www.w3.org/TR/WCAG22/#info-and-relationships) | The link between a control and its visible label must be available programmatically |
| [2.4.6 Headings and Labels](https://www.w3.org/TR/WCAG22/#headings-and-labels) | Labels describe the purpose of the control |
| [2.5.3 Label in Name](https://www.w3.org/TR/WCAG22/#label-in-name) | The name contains the visible label text |
| [4.1.2 Name, Role, Value](https://www.w3.org/TR/WCAG22/#name-role-value) | Every control has a name that can be programmatically determined |

The inventory listed 4.1.2 and 2.4.6. The sources add 2.5.3 (CVS iOS
Meaningful Accessible Names) and 1.3.1 (CVS Compose Interactive Control
Labels).

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | Every accessible element has a label that says what it is | [CVS iOS Accessibility Label](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/AccessibilityLabel.md) |
| R2 | A control and its visible label are associated, so the label is the control's name. Checkbox, switch, and radio button: a wrapping layout that merges the text and the control and takes the click | [CVS Compose Interactive Control Labels](https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/interactions/InteractiveControlLabels.md); [MDN `label`](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/label) |
| R3 | Names are unique and specific. Where the visible text does not say what the control does, give a more specific name | [CVS iOS Meaningful Accessible Names](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/MeaningfulAccessibleNames.md) |
| R4 | A name that differs from the visible text begins with the visible text, so speech input still works | CVS iOS Accessibility Label; CVS iOS Meaningful Accessible Names |
| R5 | The name does not include the control type; the screen reader adds it | CVS iOS Accessibility Label; [APG Names and Descriptions](https://www.w3.org/WAI/ARIA/apg/practices/names-and-descriptions/) |
| R6 | A slider has a visible label, and that text is in its name | CVS Compose Interactive Control Labels |
| R7 | Clicking the label operates the control | MDN `label`; CVS Compose (the wrapping row is the click target) |

Not taken from the sources: "ideally a single word" and "begin with a
capitalized word, no period" (CVS iOS Accessibility Label) are style advice
and are not asserted.

Flutter references for the mechanisms used:

- [`MergeSemantics`](https://api.flutter.dev/flutter/widgets/MergeSemantics-class.html),
  whose own documentation uses a checkbox and its label as the example
- [`CheckboxListTile`](https://api.flutter.dev/flutter/material/CheckboxListTile-class.html),
  [`SwitchListTile`](https://api.flutter.dev/flutter/material/SwitchListTile-class.html)
- [`Text.semanticsLabel`](https://api.flutter.dev/flutter/widgets/Text/semanticsLabel.html)

## 5. Examples

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-visible-label` | Material | A checkbox and a switch named by their visible text | `CheckboxListTile`, `SwitchListTile` | R1, R2, R7 |
| `good-merged-label` | Material | A checkbox and a switch laid out by hand beside their text | `MergeSemantics` around the row; `GestureDetector` so a tap on the text operates the control | R1, R2, R7 |
| `good-specific-names` | Material | Two switches with the same visible text and different names | `Text(semanticsLabel:)` that begins with the visible text | R3, R4 |
| `good-cupertino` | Cupertino | A `CupertinoSwitch` named by the text beside it | `MergeSemantics`, as above | R1, R2, R7 |

### Bad

| Slug | Defect | Violates | Fails |
| --- | --- | --- | --- |
| `bad-unassociated-label` | Text beside a checkbox, not joined to it: the checkbox has no name | R1, R2 | 1.3.1, 4.1.2 |
| `bad-duplicate-names` | Two switches both named "Order updates" | R3 | 2.4.6 |
| `bad-role-in-name` | The name is "Dark mode switch" | R5 | — (the role is heard twice) |
| `bad-slider-name-web` | A slider joined to its text as in `good-merged-label`; on web it has no name (Flutter limitation FL-028) | R1, R6 | 4.1.2 on web |

`bad-slider-name-web` is a limitation example: its code follows the rule, and
it is good on Android and iOS. It is listed as bad because a good example
must work on every platform.

## 6. Assertions by layer

Controls are located by `TestId`.

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Name, identifier, tap action, and off state per control; the visible text is not a second node; a tap and Space each turn the control on; guidelines in light and dark and 200% text for the good examples; each bad example's defect |
| L3 web | Role (`checkbox`, `switch`) and accessible name; one control per name and no separate text; click and Space turn it on; for the slider, `aria-label` on the wrapper and an empty name on `input role="slider"` |
| L3 Android | Class (`CheckBox`, `Switch`, `SeekBar`), description, checkable, clickable; one node per name; the click action turns it on; the slider is named |
| L3 iOS | Element type (switch), label, value "0" then "1" after a tap; one element per label; the slider is named |
| L4 TalkBack | Name and role spoken per control; no name for the unassociated checkbox |
| L4 VoiceOver iOS | The utterance for each control starts with its name; the unassociated checkbox is read with no name |
| L4 VoiceOver web | Name, state, and role spoken per control. Chromium: the unnamed checkbox has no name; the slider is read with its value and no name. WebKit build: what was observed is asserted (the guessed name; the cursor that does not reach the slider) |

Where a defect cannot be observed on a platform, the test asserts what is
observable: `bad-slider-name-web` is asserted as named on Android and iOS.

## 7. What the build found (Flutter 3.47.5)

Detail is in [flutter-limitations.md](../flutter-limitations.md). The probe
that came first is in [evidence/probes/s01](../evidence/probes/s01/).

- **Every mechanism names a checkbox, a switch, and a radio button on all
  three platforms**: the list tile widgets, `MergeSemantics`,
  `Semantics(label:)`, and `Checkbox.semanticLabel`. The examples use the
  first two, which keep the visible text as the name.
- **A slider has no name on web** (FL-028). The label is put on a wrapper
  element, not on the element with the slider role.
  VoiceOver in Chromium reads the wrapper as "Volume group" and then "40%
  dimmed slider".
- **A Material `Slider` adds an empty full-screen element on web** that
  blocks Playwright's clicks on the rest of the screen (FL-029). Its effect
  on people was not tested. On the same screen, VoiceOver's cursor in
  Playwright's WebKit build did not get past the title.
- **VoiceOver in Playwright's WebKit build guesses a name for the unnamed
  checkbox** from the text beside it. The other three screen reader runs
  read it with no name.
- **TalkBack spoke no state for an unchecked checkbox** ("Email me order
  updates", "Check box"), and "off" for a switch. Left to the checkbox
  technique (F07); it may be the log, not the speech.
- **`MergeSemantics` alone does not make the text clickable.** A tap on the
  text of a merged row did nothing until a `GestureDetector` was added. The
  merged node has one tap action, and the Android test shows that the
  accessibility click turns the control on once, not twice.
- **iOS has no checkbox type.** A checkbox is a switch to XCUITest, and
  VoiceOver says "Switch button".
- **VoiceOver on iOS does not hide a role repeated in a switch's name**: it
  says "Dark mode switch Switch button". (For a button it did; see C01.)

**Not done yet.** Radio buttons (probed, not built: F08). Names on images
(S02 to S04). Activation with VoiceOver's double tap on iOS is not driven
here; the iOS tree test taps with VoiceOver off. Voice Control and Voice
Access were not run; label-in-name is asserted from the names only.
