# Spec: C01 Button

Status: Draft 2 (2026-11-12), updated with what the build found (section 9). First vertical-slice technique
([plan](../plan.md), phase 2). Flutter pin: 3.47.5.

Toggle buttons are a separate entry (C02). Touch target size (V13) and focus
indicators (V14) have their own entries; this spec only checks that the good
examples do not violate them.

## 1. Rule

A button exposes a name that describes its function, the button role, and its
enabled or disabled state, and can be operated by touch, keyboard, and assistive
technology.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies | Applies | Applies |

Two Flutter limitations were found for `CupertinoButton`; see section 9.

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [2.1.1 Keyboard](https://www.w3.org/TR/WCAG22/#keyboard) | Button must be focusable and activate from the keyboard |
| [2.4.6 Headings and Labels](https://www.w3.org/TR/WCAG22/#headings-and-labels) | Name describes the button's purpose |
| [2.5.2 Pointer Cancellation](https://www.w3.org/TR/WCAG22/#pointer-cancellation) | Activation on release, not on touch down |
| [2.5.3 Label in Name](https://www.w3.org/TR/WCAG22/#label-in-name) | Accessible name contains the visible text |
| [4.1.2 Name, Role, Value](https://www.w3.org/TR/WCAG22/#name-role-value) | Name, button role, and disabled state are exposed |

## 4. Source requirements

What each source says a button must do. Every example below traces to one of
these.

| # | Requirement | Source |
| --- | --- | --- |
| R1 | Buttons need unique, specific label text describing their function | [CVS iOS Buttons](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/Buttons.md) |
| R2 | When several buttons share a visible label, give each a unique accessible name that begins with the visible text | CVS iOS Buttons |
| R3 | Do not put the word "button" in the label; the screen reader adds the role | CVS iOS Buttons |
| R4 | Disabled state must be conveyed | CVS iOS Buttons; [APG Button](https://www.w3.org/WAI/ARIA/apg/patterns/button/) (`aria-disabled`) |
| R5 | An icon-only button must have a non-empty text alternative | [CVS Compose Interactive Control Labels](https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/interactions/InteractiveControlLabels.md) |
| R6 | A touchable control must be focusable and respond to click, not only touch, so keyboard and switch users can operate it | [CVS View Focusable, Clickable Controls](https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/basics/FocusableClickableControls.md) |
| R7 | Role is button; Space and Enter both activate it | APG Button |
| R8 | Accessible name comes from the text content, or is supplied explicitly | APG Button; [MDN `<button>`](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/button) |

Flutter references for the mechanisms used:

- [Flutter accessibility](https://docs.flutter.dev/ui/accessibility)
- [`Semantics`](https://api.flutter.dev/flutter/widgets/Semantics-class.html)
- [`Text.semanticsLabel`](https://api.flutter.dev/flutter/widgets/Text/semanticsLabel.html)
- [`IconButton.tooltip`](https://api.flutter.dev/flutter/material/IconButton/tooltip.html)
- [`FilledButton`](https://api.flutter.dev/flutter/material/FilledButton-class.html), [`CupertinoButton`](https://api.flutter.dev/flutter/cupertino/CupertinoButton-class.html)
- [`FocusableActionDetector`](https://api.flutter.dev/flutter/widgets/FocusableActionDetector-class.html), [`ActivateIntent`](https://api.flutter.dev/flutter/widgets/ActivateIntent-class.html)

Radix comparison bar: Radix has no standalone button primitive; the bar here is
the native `<button>` as described by MDN.

## 5. Examples

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-text` | Material | Filled, outlined, and text buttons with a text child | `FilledButton`, `OutlinedButton`, `TextButton` | R1, R7, R8 |
| `good-icon` | Material | Icon-only button with a name | `IconButton(tooltip:)` | R5 |
| `good-disabled` | Material | Disabled button | `onPressed: null` | R4 |
| `good-unique-names` | Material | Repeated "Edit" buttons, each named "Edit username", "Edit email" | `Text('Edit', semanticsLabel: 'Edit username')` | R2 |
| `good-cupertino` | Cupertino | Text button, and a disabled one | `CupertinoButton`; the disabled one inside `Semantics(enabled: false)` (limitation 1) | R1, R4, R7 |
| `good-custom` | Widgets layer | A custom-drawn button with role, state, and keyboard activation | `Semantics(button: true, enabled:, onTap:)` with `FocusableActionDetector` handling `ActivateIntent` | R6, R7 |

### Bad

Each has one named defect, asserted by tests (VAL-3).

| Slug | Defect | Violates | Fails |
| --- | --- | --- | --- |
| `bad-unlabelled-icon` | `IconButton` with no `tooltip` and an `Icon` with no `semanticLabel` | R5 | 4.1.2 |
| `bad-gesture-only` | Styled `Container` in a `GestureDetector`: no button role, not keyboard focusable | R6, R7 | 4.1.2, 2.1.1 |
| `bad-role-in-name` | Name is "Close button" | R3 | 2.4.6 |
| `bad-duplicate-names` | Three buttons all named "Edit" | R1, R2 | 2.4.6 |
| `bad-name-mismatch` | Visible text "Edit", accessible name "Change username" | R2 | 2.5.3 |
| `bad-fake-disabled` | Greyed out to look disabled but still enabled in semantics | R4 | 4.1.2 |
| `bad-cupertino-disabled` | Disabled `CupertinoButton` with no disabled state (Flutter limitation 1) | R4 | 4.1.2 |

## 6. Assertions by layer

Expected values for L3 are the working hypothesis. Spikes K1–K3 establish the
real ones, and this table is corrected before tests are written.

### L1 Widget tests

| Example | Assertion |
| --- | --- |
| All good | Semantics has the button flag, a tap action, and the expected label; passes `labeledTapTargetGuideline`, `androidTapTargetGuideline`, `iOSTapTargetGuideline`, `textContrastGuideline` |
| `good-disabled` | Has enabled state = false; no tap action |
| `good-unique-names` | Labels are unique and each starts with "Edit" |
| `good-custom` | Focusable; Enter and Space invoke the callback |
| All good | No overflow at 200% text scale |
| `bad-unlabelled-icon` | Fails `labeledTapTargetGuideline` |
| `bad-gesture-only` | No button flag; cannot receive keyboard focus |
| `bad-role-in-name` | Label ends with "button" |
| `bad-duplicate-names` | Labels are not unique |
| `bad-name-mismatch` | Label does not contain the visible text |
| `bad-fake-disabled` | Enabled state = true and tap action present |

### L2 Integration tests (each platform)

- Each example opens at `/t/C01/<slug>`.
- Tab reaches every good button in visual order; Enter and Space activate; the
  disabled button does not activate.
- Tab skips `bad-gesture-only`.

### L3 Platform accessibility tree

| Property | Web (Playwright) | iOS (XCUITest) | Android (UI Automator) |
| --- | --- | --- | --- |
| Role | `role=button` | Element type button | Class name `android.widget.Button` |
| Name | Accessible name | `label` | Content description or text |
| Disabled | `aria-disabled="true"` or `disabled` | `isEnabled == false` | `isEnabled == false` |
| Activation | Click, Enter, Space | `tap()` | `click()` |

Bad examples: `bad-gesture-only` is not found by a button role query;
`bad-unlabelled-icon` has an empty name; `bad-fake-disabled` reports enabled.

### L4 Screen reader

Gate or evidence per platform is set by spikes K5–K7. Expected phrases, ignoring
order and verbosity settings:

| Example | Expected to include |
| --- | --- |
| `good-text` | name, "button" |
| `good-disabled` | name, "button", "dimmed" (VoiceOver) / "disabled" (TalkBack) |
| `good-unique-names` | "Edit username", "button" |
| `bad-unlabelled-icon` | "button" with no name |
| `bad-gesture-only` | name with no "button" |
| `bad-role-in-name` | "Close button", "button" |

## 7. Open points

1. Whether `Text.semanticsLabel` alone replaces the button's name on all three
   platforms, or whether the web name also includes the visible text. Checked at L3.
2. Whether a `GestureDetector` still reports a click action on Android and iOS,
   making `bad-gesture-only` activatable by a screen reader but roleless. Either
   outcome is a valid bad example; the doc must describe what actually happens.
3. Exact L3 values on each platform (spikes K1–K3).

## 8. Done when

The definition of done in the [plan](../plan.md#4-definition-of-done-for-a-technique)
is met for all thirteen examples.

## 9. What the build found (Flutter 3.47.5)

Resolves the open points in section 7 and corrects section 6 where it differs.

**Locators.** Every control is wrapped in `TestId` (`lib/catalog/test_id.dart`),
which is `MergeSemantics` around `Semantics(identifier:)`. Identifiers are
`c01-<slug>-<name>`. Each example also has `c01-<slug>-count`, a polite live
region reading "Activations: N", so every layer can confirm activation.

**Open point 1, `Text.semanticsLabel`.** It replaces the name on all three
platforms. The web name is the label only.

**Open point 2, `GestureDetector`.** It is activatable by assistive technology
on every platform. Android and iOS expose no button role. Flutter web gives any
tappable node `role="button"`, so on web the role is present and the defect is
keyboard access (no `tabindex`). Android reports the node as focusable.

**Open point 3, L3 values.** As in section 6, with these corrections:

- An `IconButton`'s name is in the semantics `tooltip`, not `label`. Platforms
  expose it as the name.
- L1: the text contrast guideline is skipped for examples with a disabled
  button. WCAG 1.4.3 exempts inactive components; Flutter's guideline does not.
- L4 phrases: VoiceOver says "Submit dimmed Button"; TalkBack says "Submit" then
  "Button. disabled". VoiceOver does not repeat the role for
  `bad-role-in-name`, so on iOS that defect is asserted in the tree only.

Limitations are detailed in [flutter-limitations.md](../flutter-limitations.md)
(FL-001, FL-002, FL-006, FL-008).

**Limitation 1.** A disabled `CupertinoButton` reports no enabled state
(`Semantics(button: true)` only) and still lists a tap action.

**Limitation 2.** On web, Enter does not activate a `CupertinoButton`
(`ButtonActivateIntent` is not handled). Space does.

**Not done yet.** L2 `integration_test` runs, and a first run of the CI jobs. The keyboard
checks planned for L2 are covered in L1 and in the web suite.
