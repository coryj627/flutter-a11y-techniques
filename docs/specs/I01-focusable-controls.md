# Spec: I01 Focusable and clickable controls

Status: Draft 1 (2026-11-18), written with the build. First technique of
batch 5, focus and keyboard ([plan](../plan.md)), built in wave 4. Flutter
pin: 3.47.5.

This spec covers one thing: something a person can tap can also be
reached and activated from the keyboard and by assistive technology, and
it acts when the pointer is let go, not when it goes down. A button's
name, role, and disabled state are [C01 Button](C01-button.md); roles in
general are [S13 Roles and traits](S13-roles-and-traits.md). The order
focus moves in is I02, moving focus from code is I03, other keys and
shortcuts are I04, Escape is I08, and how focus looks is V14; each is
left to its own entry (section 8).

## 1. Rule

A control that answers a tap or click also takes keyboard focus in the
Tab order, does the same thing when Enter or Space is pressed on it, and
can be activated by a screen reader or switch access through the
platform's activate action. Assistive technology is told that it is a
control. It acts when the pointer is released, so that a press can be
taken back by moving the pointer away before letting go.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies | Applies | Applies |

See section 7 for what could be driven from tests on each platform.

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [2.1.1 Keyboard](https://www.w3.org/TR/WCAG22/#keyboard) | Everything a control does with a tap can be done from a keyboard |
| [2.5.2 Pointer Cancellation](https://www.w3.org/TR/WCAG22/#pointer-cancellation) | The press of a single pointer does not carry out the function; it happens on release, so it can be abandoned |
| [4.1.2 Name, Role, Value](https://www.w3.org/TR/WCAG22/#name-role-value) | The control's role can be programmatically determined, and its focused state is exposed |

The coverage inventory lists 2.1.1 and 4.1.2. The Android View
reference lists 2.1.1 and 2.5.2; 2.5.2 is added here because one bad
example fails it.

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | A touchable, active control is focusable, so keyboard and switch users can reach it | [Android View: Focusable, Clickable Controls](https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/basics/FocusableClickableControls.md) (`android:focusable="true"` on an `ImageView` that acts), [MDN: Keyboard-navigable JavaScript widgets](https://developer.mozilla.org/en-US/docs/Web/Accessibility/Guides/Keyboard-navigable_JavaScript_widgets) (`tabindex="0"` on an element that is not focusable by itself) |
| R2 | It responds to a click, not only to a touch: the action is the same whatever started it | Android View (an `onClickListener`, not an `onTouchListener` alone), MDN (what a mouse handler does, a key handler does too) |
| R3 | Enter and Space both activate it | [APG Button](https://www.w3.org/WAI/ARIA/apg/patterns/button/), keyboard interaction |
| R4 | Assistive technology is told it is a control | APG Button (role `button`), MDN (a role on an element that is not a control by itself) |
| R5 | It acts on release, not on press | Android View (2.5.2 and a click in place of a touch), [WCAG Understanding 2.5.2](https://www.w3.org/WAI/WCAG22/Understanding/pointer-cancellation.html) |

Flutter references for the mechanisms used:

- [Understanding Flutter's keyboard focus system](https://docs.flutter.dev/ui/interactivity/focus) and [Using Actions and Shortcuts](https://docs.flutter.dev/ui/interactivity/actions-and-shortcuts)
- [`FocusableActionDetector`](https://api.flutter.dev/flutter/widgets/FocusableActionDetector-class.html), [`ActivateIntent`](https://api.flutter.dev/flutter/widgets/ActivateIntent-class.html), [`ButtonActivateIntent`](https://api.flutter.dev/flutter/widgets/ButtonActivateIntent-class.html)
- [`ListTile.onTap`](https://api.flutter.dev/flutter/material/ListTile/onTap.html), [`InkWell`](https://api.flutter.dev/flutter/material/InkWell-class.html), [`CupertinoListTile`](https://api.flutter.dev/flutter/cupertino/CupertinoListTile-class.html)
- [`GestureDetector.onTap`](https://api.flutter.dev/flutter/widgets/GestureDetector/onTap.html) and [`onTapDown`](https://api.flutter.dev/flutter/widgets/GestureDetector/onTapDown.html), [`SemanticsProperties.button`](https://api.flutter.dev/flutter/semantics/SemanticsProperties/button.html)

Comparison bar: an HTML `<div>` with `role="button"`, `tabindex="0"`, a
`click` handler, and a `keydown` handler for Enter and Space, as MDN and
the APG describe; Radix has no primitive for it.

## 5. Examples

Every example is one card, "Ridge trail", that counts its activations,
and ends with the count. The four bad examples each break one of the
rules in section 1 and keep the others, so that the defect is the only
difference from a good one.

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-material` | Material | A list tile in a card | `Card` around `ListTile(onTap:)`, which is a button, takes focus through its `InkWell`, and handles both activate intents | R1 to R5 |
| `good-cupertino` | Cupertino | A Cupertino list tile, with the focus and keys it lacks everywhere, and the button role it lacks on Android and iOS, added ([FL-400](../flutter-limitations.md#fl-400)) | `CupertinoListTile(onTap:)` inside `Semantics(button: true)` and `FocusableActionDetector` with `ActivateIntent` and `ButtonActivateIntent`, and a ring drawn from `onShowFocusHighlight` | R1 to R5 |
| `good-custom` | Widgets layer | A card drawn by hand | `GestureDetector(onTap:)` inside `Semantics(button: true)` inside the same `FocusableActionDetector` | R1 to R5 |

### Bad

| Slug | Defect | Violates | Fails |
| --- | --- | --- | --- |
| `bad-inkwell-no-role` | `Card` around `InkWell(onTap:)`, as in the `Card` documentation's tappable card. Focus, the keys, and the tap all work; on Android and iOS nothing says it is a control ([FL-401](../flutter-limitations.md#fl-401)) | R4 | 4.1.2, on Android and iOS. On the web it is a button ([FL-006](../flutter-limitations.md#fl-006)) |
| `bad-no-focus` | `Semantics(button: true)` around `GestureDetector(onTap:)` and no focus node: Tab goes past it | R1 | 2.1.1 |
| `bad-no-key-action` | The same inside `Focus`: Tab reaches it and a ring shows, and Enter and Space do nothing | R2, R3 | 2.1.1 |
| `bad-tap-down` | The good custom card with `onTapDown` in place of `onTap`: it acts on the press, and moving off before letting go does not take it back | R5 | 2.5.2 |

Not built: a control made from a raw `Listener(onPointerUp:)`, the closest
Flutter has to the Android reference's `onTouchListener`. In the probe
(fixture `k10`) it has three defects at once: no keyboard focus, no tap
action for assistive technology, and a release anywhere activates it, even
off the control. It is in the probe only.

C01 already has the plain `GestureDetector` with no role and no focus
(`bad-gesture-only`) and a custom button built the way `good-custom` is.
I01's examples are cards, not buttons, and each bad one has one defect.

## 6. Assertions by layer

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Every example: one node named "Ridge trail" with a tap action; a tap, and the semantics tap action, each activate it once. Good: the button flag, focusable and not focused, guidelines in light and dark, 200% text. Keyboard: Tab reaches the control, Enter and Space each activate it once and focus stays, and the focused control handles `ButtonActivateIntent` (the web's Enter) as well as `ActivateIntent`. Pointer: nothing while it is held, nothing when the pointer leaves before release, one activation on release. Bad: `bad-inkwell-no-role` has no button flag and no role; `bad-no-focus` has no focus state, the first and second Tabs both land on Back, and later Tabs never reach it; `bad-no-key-action` is reached and Enter, and separately Space, does nothing, then Tab goes on to Back and the same key there leaves the screen, and neither intent is handled; `bad-tap-down` acts while held and moving off does not undo it. The SDK widget on its own: a `CupertinoListTile` with `onTap` has no focus state, no button flag, and Tab goes past it (FL-400) |
| L3 web | Every example: `role="button"` named "Ridge trail", once; a click and a click event on the element each activate it. Keyboard: `tabindex="0"`, Tab reaches it, Enter and Space each activate it with focus staying; `bad-no-focus` has no `tabindex`, the first Tab lands on Back, the second leaves Back and is not on the card, and later Tabs never reach it; `bad-no-key-action`'s Enter, and separately its Space, does nothing, then Shift+Tab reaches Back and the same key there leaves the screen. Pointer: a press held 600 ms and then moved off does nothing; on `bad-tap-down` it acts while held and stays |
| L3 Android | Every example: the name, the class (`Button`, or `View` for `bad-inkwell-no-role`), clickable with a click action, enabled, not focused; the click action and a tap each activate it once. Keyboard, with `input keyevent`: Tab reaches it (`isFocused`), Enter and Space each activate it with focus staying; for `bad-no-focus` six Tabs never focus it while Back takes focus, so the keys did arrive; `bad-no-key-action`'s Enter, and separately its Space, does nothing, then Tab reaches Back and the same key there leaves the screen. Pointer: a swipe that starts on the control and leaves it does nothing, except on `bad-tap-down` |
| L3 iOS | Every example: the label, the type (button, or static text for `bad-inkwell-no-role`), enabled; a tap activates it once. Keyboard, with `typeKey`: two Tabs and Enter activate it and Space again; for `bad-no-focus` two Tabs, the number at which a focusable control has focus, and Space leave the screen, because focus is on Back (a focusable card would be activated and the screen would stay, and so would it if no key arrived); for `bad-no-key-action`, Enter, and separately Space, neither activates it nor leaves the screen, and then a Tab on to Back and the same key leave it. Pointer: a press that slides off does nothing, except on `bad-tap-down` |
| L4 TalkBack | Each control: "Ridge trail", "Button", and "Double-tap to activate"; for `bad-inkwell-no-role` no "Button" |
| L4 VoiceOver iOS | Every utterance between the "Example" heading and the count: "Ridge trail Button", and "Ridge trail" alone for `bad-inkwell-no-role` |
| L4 VoiceOver web | Every stop between the "Example" heading and the count: "Ridge trail button" for every example |

The keyboard and pointer defects are not heard: a screen reader reads
`bad-no-focus`, `bad-no-key-action`, and `bad-tap-down` as it reads the
good examples, and activates them through the tap action. The screen
reader layers record that.

## 7. What the build found (Flutter 3.47.5)

The probe that came first is in
[evidence/probes/i01](../evidence/probes/i01/README.md), with the raw output
of each platform.

- **The keyboard can be driven on all three platforms.** On the Android
  emulator (it has a hardware keyboard in its AVD settings) `input
  keyevent`, `UiDevice.pressKeyCode`, and
  `Instrumentation.sendKeyDownUpSync` all reach Flutter, and the node with
  Flutter's focus reports `isFocused`. On the iOS simulator
  `XCUIElement.typeKey` reaches Flutter for Tab, Shift+Tab, Space, and the
  arrows; Enter only when typed as `"\n"`. XCUITest cannot see where focus
  is, so the iOS tests show it by what the next key does.
- **On Android the first Tab after the app opens is lost**: it never
  reaches the framework, and the second Tab moves focus. That fits
  Android's touch mode, which a first navigation key only leaves; not
  confirmed in the Android source. F10's one try with UI Automator's keys
  would have met exactly this. The tests press Tab until the control has
  focus.
- **Android's `isFocusable` says nothing about the keyboard**: it is true
  for every node with a name or an action (read in the engine source), so
  `bad-no-focus` is "focusable" there. `isFocused` is what the tests read.
- **Not established: iOS with Full Keyboard Access.** With it turned on in
  the simulator's Settings, no key from XCUITest reached the app, nothing
  reported focus, and Space did nothing. The engine source says that
  Full Keyboard Access moves over every node with a tap action and
  activates through it, apart from Flutter's focus; if so, `bad-no-focus`
  is reachable there. Not observed.
- **Shift+Tab could not be sent on Android** by any of the ways tried; it
  is not used in these tests.
- **A `CupertinoListTile` with `onTap` takes no keyboard focus on any
  platform, and is not a button on Android and iOS**
  ([FL-400](../flutter-limitations.md#fl-400)). On the web the engine
  makes it a button anyway, because it has a tap action
  ([FL-006](../flutter-limitations.md#fl-006)); only the `tabindex` is
  missing there. `good-cupertino` adds focus, the keys, and the button
  flag.
- **An `InkWell` has everything but the role**
  ([FL-401](../flutter-limitations.md#fl-401)): on Android a `View`, on
  iOS static text, read with no "Button". On the web it is a button
  ([FL-006](../flutter-limitations.md#fl-006)), so that example's defect
  is not on the web.
- **`Focus` without actions**, `bad-no-key-action`, was reached by Tab and
  ignored Enter and Space on every platform.
- **`onTapDown` acts on the press everywhere.** On the web the engine holds
  a press on a tappable element back for up to 200 ms before passing it on
  (read in the source: `ClickDebouncer`), so a press that moves off sooner
  never acts; one held longer does, as the test holds it.
- **A tap is given up by distance, not by the control's edge**
  ([FL-402](../flutter-limitations.md#fl-402)): `onTap` does not run once
  the pointer has moved more than 18 logical pixels from the press, and
  does not look at where it is released. In the widget tests a press 4
  pixels inside the edge released 6 outside still acts, and a press at
  the centre moved 40 pixels and released over the control does not. Not
  measured on a device.
- **A screen reader does not need keyboard focus**: a semantics tap, a
  click event on the web element, and VoiceOver's double tap all activate
  `bad-no-focus`. TalkBack, VoiceOver on iOS, and VoiceOver on the web read
  the three widgets-layer bad examples exactly as the good ones.
- **A control that handles only `ActivateIntent` ignores Enter on the
  web** (probe fixture `k13`), as [FL-002](../flutter-limitations.md#fl-002)
  found for `CupertinoButton`. The good examples handle
  `ButtonActivateIntent` too, and the widget tests check both are found
  from the focused control.

**Not done yet.** Full Keyboard Access on iOS; Shift+Tab on Android; a
disabled control; what a screen reader says when keyboard focus lands on
a control; focus order (I02), moving focus (I03), other keys (I04),
Escape (I08), and focus indicators (V14).
