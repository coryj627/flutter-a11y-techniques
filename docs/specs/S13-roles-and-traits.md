# Spec: S13 Roles and traits

Status: Draft 1 (2026-11-15), written with the build. Fifth technique of
batch 1 ([plan](../plan.md)). Flutter pin: 3.47.5.

A role says what kind of thing an element is: a button, a switch, a link.
iOS calls roles and some states "traits". This spec covers how a control
gets its role and the action that goes with it. A control's name is
[S01 Accessible names](S01-accessible-names.md); headings are
[S05 Headings](S05-headings.md); images are S02 to S04. What each kind of
control has to do in full (a button's states, a switch's keys) belongs to
that control's own entry ([C01 Button](C01-button.md), F09 Switch). Values
and state descriptions are S14. Links are left to C03 Stand-alone link.

## 1. Rule

Every control exposes the role that matches what it does, and an action
that assistive technology can call. The SDK's controls already do both and
get nothing added. A control built by hand gets its role from `Semantics`.
A role is not put on something that does not behave that way.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies | Applies | Applies |

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [4.1.2 Name, Role, Value](https://www.w3.org/TR/WCAG22/#name-role-value) | The role of every user interface component can be read by assistive technology, and so can its state |

The CVS document on `accessibilityRespondsToUserInteraction` lists 2.1.1
Keyboard and 2.4.3 Focus Order, because on iOS that property decides what
Full Keyboard Access and Switch Control can reach. In Flutter the keyboard
is handled by `Focus` and is separate from the semantics tree, so the
example made from that document (`bad-action-hidden`) still works from the
keyboard and is recorded against 4.1.2 only.

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | A custom control is given the role that matches what it does | [CVS iOS Accessibility Traits](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/AccessibilityTraits.md) ("add custom traits matching the roles and functionality of the control"; its good example adds the button trait to an image with a tap gesture), [WCAG technique ARIA4](https://www.w3.org/WAI/WCAG22/Techniques/aria/ARIA4), [WCAG failure F59](https://www.w3.org/WAI/WCAG22/Techniques/failures/F59), [MDN: WAI-ARIA roles](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Reference/Roles), [Apple: UIAccessibilityTraits](https://developer.apple.com/documentation/uikit/uiaccessibilitytraits), [Android: Role](https://developer.android.com/reference/kotlin/androidx/compose/ui/semantics/Role) |
| R2 | Standard controls already have their roles; nothing is added to them | CVS iOS Accessibility Traits ("Standard native controls already include accessibility traits by default") |
| R3 | A role is a promise: the element behaves as its role says. No role is better than a wrong one | [APG: Read Me First](https://www.w3.org/WAI/ARIA/apg/practices/read-me-first/) ("A role is a promise"; "No ARIA is better than bad ARIA") |
| R4 | A control that can be operated is not taken away from assistive technology, and text that cannot be operated is not presented as if it could | [CVS iOS Accessibility Responds To User Interaction](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/AccessibilityRespondsToUserInteraction.md) (its bad example turns the property off on tappable text and on for static text) |
| R5 | A state that is part of the role (selected, on or off) is exposed with it | CVS iOS Accessibility Traits (the list of traits has Selected and Toggle); WCAG 4.1.2 |

Flutter references for the mechanisms used:

- [`Semantics`](https://api.flutter.dev/flutter/widgets/Semantics-class.html)
  and [`SemanticsProperties`](https://api.flutter.dev/flutter/semantics/SemanticsProperties-class.html)
  (`button`, `toggled`, `selected`, `enabled`)
- [`GestureDetector.excludeFromSemantics`](https://api.flutter.dev/flutter/widgets/GestureDetector/excludeFromSemantics.html)
- [`FocusableActionDetector`](https://api.flutter.dev/flutter/widgets/FocusableActionDetector-class.html)

The inventory row names no APG pattern and no HTML element. The HTML
counterpart of R2 is using the native element (`button`, `input`) in place
of a `div` with a role.

### The CVS list of traits, and what Flutter has for each

| iOS trait | Flutter | Where |
| --- | --- | --- |
| Button | `Semantics(button: true)` | Here, C01 |
| Header | `Semantics(header: true, headingLevel:)` | S05 |
| Selected | `Semantics(selected:)` | Here (`good-selected`) |
| Link | `Semantics(link: true)`, a link on iOS only without `linkUrl` ([FL-032](../flutter-limitations.md#fl-032)) | C03 |
| Image | `Semantics(image: true)`, `Image`, `Icon` | S02 to S04 |
| Toggle | `Semantics(toggled:)` | Here (`good-custom-switch`) |
| Updates frequently | `Semantics(liveRegion: true)` | I12 |
| Static text | Given by the engine to a labelled node with no other trait | — |
| Keyboard key | `Semantics(keyboardKey: true)`, which has no effect ([FL-034](../flutter-limitations.md#fl-034)) | No example |
| Tab bar | `SemanticsRole.tabBar` and `tab` | The tabs entry |
| Search field, summary element, plays sound, starts media session, allows direct interaction, causes page turn | None ([FL-034](../flutter-limitations.md#fl-034)) | No example |
| Modal | `scopesRoute` and `namesRoute`, set by routes and dialogs | The dialog entries |

## 5. Examples

Every example ends with a count of activations, so a person or a test can
tell that a control worked. The custom controls share one keyboard wrapper
(`FocusableActionDetector`, Enter and Space, a focus ring), which adds no
role and no tap action; each example writes its own `Semantics` and
`GestureDetector`.

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-standard` | Material | A button, a switch, and a checkbox with nothing added | `FilledButton`, `SwitchListTile`, `CheckboxListTile` | R2 |
| `good-cupertino` | Cupertino | A button and a switch with nothing added to their roles | `CupertinoButton`, `CupertinoSwitch` in a `MergeSemantics` row for its name (S01) | R2 |
| `good-custom-button` | Widgets | A control drawn by hand that is a button | `Semantics(button: true, enabled: true)` around a `GestureDetector` | R1, R4 |
| `good-custom-switch` | Widgets | A control drawn by hand that is a switch | `Semantics(toggled:, enabled: true)` around a `GestureDetector` | R1, R5 |
| `good-selected` | Widgets | Three custom buttons that choose a view, one of them chosen | `Semantics(button: true, enabled: true, selected:)` | R1, R5 |

### Bad

| Slug | Defect | Violates | Fails |
| --- | --- | --- | --- |
| `bad-no-role` | The custom control has a tap action and keyboard access and no role. On Android and iOS it is read as text. The web makes it a button anyway ([FL-006](../flutter-limitations.md#fl-006)) | R1 | 4.1.2 on Android and iOS (F59) |
| `bad-wrong-role` | A switch with the button role: "Dark mode, button", and never whether it is on | R1, R5 | 4.1.2 |
| `bad-role-on-text` | Text that does nothing has the button role | R3, R4 | 4.1.2 |
| `bad-role-on-standard` | `Semantics(button: true)` around a `FilledButton`: a second button with no name around the real one on Android, and a button inside a button on the web | R2 | — on iOS; 4.1.2 where the unnamed button is exposed |
| `bad-action-hidden` | The button's tap is kept out of the semantics tree (`excludeFromSemantics: true`). It reads as a button and works by touch and keyboard, and has no action in the semantics tree: no click action on Android, and on the web a click sent to the element does nothing | R4 | 4.1.2 |
| `bad-switch-not-enabled` | `Semantics(toggled:)` with no `enabled`: VoiceOver on iOS reads a working switch as dimmed ([FL-033](../flutter-limitations.md#fl-033)) | R5 | 4.1.2 on iOS |

`bad-role-on-standard` has no `TestId`: its `MergeSemantics` would join the
two buttons and hide the defect. Its nodes are found by role and name, and
the widget tests use a plain `Key`.

No example for a link (C03) or for the keyboard key trait, which cannot be
shown to do anything ([FL-034](../flutter-limitations.md#fl-034)).

## 6. Assertions by layer

Controls are located by `TestId`, except in `bad-role-on-standard`.

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Good: name, the flags of the role and none of another role, `enabled`, the tap action, tap, the semantics tap action, Tab reach, Enter and Space, the state after each; guidelines in light and dark and 200% text. Bad: tap action and no role flag; button flag and no state before and after a press; button flag with no tap action and no focus; two button nodes, the outer one unnamed; button flag with no tap action that a touch and Enter still activate; `toggled` with no enabled state |
| L3 web | Good: role (`button`, `switch`, `checkbox`), accessible name, `aria-checked`, `aria-current` for `selected`, a pointer click, a click sent to the element (activation with no pointer position), Tab, Enter on buttons and Space on all. Bad: `bad-no-role` is asserted to be a button on web; a button with no state attribute; a button with no `tabindex` that nothing activates; a button inside a button; a button with no `flt-tappable` that ignores a click sent to it and answers to a pointer and Enter; `bad-switch-not-enabled` is asserted to be an ordinary switch on web |
| L3 Android | Good: class (`Button`, `Switch`, `CheckBox`), description, enabled, clickable, the click action, checked and selected. Bad: a clickable `View`; a `Button` that is not checkable and has no state description; a `Button` with no click action that a click does not activate; an unnamed `Button` around the named one; `bad-switch-not-enabled` is asserted to be an enabled `Switch` |
| L3 iOS | Good: element type (button, switch), label, enabled, value, selected. Bad: static text and no button; a button with no value; a button that a tap does not activate; a switch that is not enabled. `bad-action-hidden` cannot be told from the good button: XCUITest taps by touch and cannot read whether an element has an accessibility action |
| L4 TalkBack | What is read with focus on each control, including whether "Double-tap to activate" is offered |
| L4 VoiceOver iOS | Every utterance between the "Example" heading and the activation count, compared as a whole list |
| L4 VoiceOver web | Every stop of VoiceOver's cursor between the "Example" heading and the activation count, compared as a whole list, in Chromium and WebKit |

## 7. What the build found (Flutter 3.47.5)

The probe that came first is in [evidence/probes/s13](../evidence/probes/s13/).

- **The SDK's controls need nothing.** `FilledButton`, `SwitchListTile`,
  `CheckboxListTile`, `CupertinoButton`, and `CupertinoSwitch` have their
  role, their state, and a tap action on all three platforms.
- **`button`, `toggled`, and `selected` on `Semantics` reach all three
  platforms.** A custom control with `button: true` is `role="button"`, an
  Android `Button`, and an iOS button. With `toggled` it is `role="switch"`,
  a `Switch`, and an iOS switch, and it is not a button as well. `selected`
  on a button is `aria-current` on the web ("Week, current item, button"
  from VoiceOver), the selected state on Android
  ("selected, Week, Button" from TalkBack), and the selected trait on iOS
  ("selected, Week, Button").
- **A custom switch needs `enabled: true`**
  ([FL-033](../flutter-limitations.md#fl-033)). Without it VoiceOver on iOS
  reads "Dark mode, dimmed, Switch button, off" and XCUITest reports the
  switch as not enabled, though it works. Android and the web are not
  affected.
- **A checkbox is a switch for VoiceOver on iOS**
  ([FL-035](../flutter-limitations.md#fl-035)): "Remember me, Switch button,
  off. Double tap to toggle setting". TalkBack says "Check box" and the web
  has `role="checkbox"`.
- **A missing role cannot be shown on the web**
  ([FL-006](../flutter-limitations.md#fl-006)): `bad-no-role` is
  `role="button"` there. TalkBack reads "Scan barcode" and offers
  "Double-tap to activate" with no "Button"; VoiceOver on iOS reads "Scan
  barcode".
- **A role with no action is announced all the same.** `bad-role-on-text`
  and `bad-action-hidden` are read as buttons on every platform. What gives
  them away: TalkBack does not offer "Double-tap to activate"; the Android
  node is not clickable and has no click action; the web element has no
  `flt-tappable` and ignores a click sent to it. Flutter's Android bridge
  answers `true` to a click on any node, so the tests check that nothing
  was activated, not the result of the call.
- **What a screen reader's own activation does to `bad-action-hidden` was
  not tested on the web or on iOS.** On the web the test sends
  `element.click()`, which activates the good controls and not this one;
  which events VoiceOver sends in Chromium and WebKit was not recorded. On
  Android the node has no click action and `ACTION_CLICK` activates
  nothing. On iOS: XCUITest taps by touch, which
  works, and `XCUIVoiceOverService` has no command to activate the element
  under the cursor. VoiceOver reads it as "Scan barcode, Button", the same
  as the good example.
- **A role added to a real button makes a second button.**
  `Semantics(button: true)` around a `FilledButton` is a node of its own
  with no name. On the web it is a button around a button, both named
  "Save" by the text. On Android it is an unnamed `Button` that cannot be
  clicked; TalkBack, with focus moved to it, says "Button". VoiceOver on
  macOS stops once, on "Save button, group" in Chromium and "Save button"
  in WebKit. The iOS tree has
  an unnamed button too, and VoiceOver does not stop on it.
- **Enter does not toggle a `CupertinoSwitch` on the web; Space does.** The
  same cause as [FL-002](../flutter-limitations.md#fl-002). The APG Switch
  pattern makes Enter optional, so no action was added and the web test
  requires Space only for switches and checkboxes.
- **`link: true` alone is a link on iOS only**
  ([FL-032](../flutter-limitations.md#fl-032)), and **`keyboardKey` does
  nothing anywhere** ([FL-034](../flutter-limitations.md#fl-034)). Both were
  seen in the probe and have no example here.
- A method named `activate` on a `State` overrides `State.activate`. The
  shared state of the examples calls it `press`.

**Not done yet.** Whether VoiceOver can activate `bad-action-hidden`, on iOS or on the web,
is not known. What Switch Access and Voice Access do
with the examples was not tested; the tests go by the click action those
services use. Links are left to C03, and a checked radio button that
VoiceOver on iOS read as "Button" with no state (probe, fixture 09) to F08.
Which elements a TalkBack swipe stops on is not tested; the walk moves
focus by action (see S03).
