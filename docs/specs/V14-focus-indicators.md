# Spec: V14 Focus indicators

Status: Draft 1 (2026-11-19), written with the build. Built in wave 4,
focus and keyboard ([plan](../plan.md)), as the batch 5 entry that closes
the VAL-9 gap: until now nothing in this project asserted that focus can
be seen. Flutter pin: 3.47.5.

This spec covers whether someone using a keyboard can see where focus is:
what Flutter draws when a control takes keyboard focus, how it stands out
from what is next to it, when Flutter draws it at all, and whether the
focused control can end up hidden under content drawn over the screen.
Which controls take focus is [I01](I01-focusable-controls.md), the order
Tab follows is [I02](I02-focus-order.md), where focus goes when the screen
changes is [I03](I03-focus-management.md), other keys and shortcuts are
I04, Escape and keyboard traps are I08, and target size is V13. The
contrast of text, including a control's label, is 1.4.3 and belongs to
the other V techniques of wave 5, visual preferences (V01 Colour
contrast, V02 High contrast preference, and V03 Dark and light themes);
this spec measures the contrast of the focus
indicator only. Section 8 says what is handed on.

## 1. Rule

When a control takes keyboard focus, something visibly changes on or
round it, and stays changed while focus is there. That change has a
contrast of at least 3:1 against the colours next to it. The control
with focus is not hidden entirely by anything else the app draws, such as
a banner, a bar, or a header pinned over a scrolling view.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies | Applies | Applies |

Keyboard focus from a hardware keyboard on Android and iOS, and from the
browser's keyboard on the web. Flutter shows most of its indicators only
when it judges that the keyboard is in use (its highlight mode, section
7). The tests put it in that mode the way a user's keyboard does: on
iOS with XCUITest's hardware keys, on the web with the browser's keys, and
on Android with a keyboard the test registers through the shell's `uinput`
tool, because the keys Android's own injection sends (`input keyevent`,
Instrumentation) count as the on-screen keyboard's and leave the mode as
it is ([FL-433](../flutter-limitations.md#fl-433)). The simulator and the
emulator are in light mode; dark mode is measured in the widget tests
and the probe.

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [2.4.7 Focus Visible](https://www.w3.org/TR/WCAG22/#focus-visible) | Every control in the examples is reached with the keyboard; there must be a mode in which the keyboard focus indicator is visible |
| [2.4.11 Focus Not Obscured (Minimum)](https://www.w3.org/TR/WCAG22/#focus-not-obscured-minimum) | Two examples have a notice next to a scrolling list; a control that takes focus must not be entirely hidden by content the app draws |
| [1.4.11 Non-text Contrast](https://www.w3.org/TR/WCAG22/#non-text-contrast) | A focus indicator is visual information that identifies a state of a component, so it needs 3:1 against adjacent colours |

How each applies, as the criteria and their Understanding documents are
written:

- **2.4.7** asks for "a mode of operation where the keyboard focus
  indicator is visible"; a user agent may show it only when a keyboard is
  used ([Understanding 2.4.7](https://www.w3.org/WAI/WCAG22/Understanding/focus-visible.html)).
  Flutter's own rule, which hides most indicators after a touch and shows
  them again at the next key, is such a mode and is not a failure.
  `bad-indicator-removed` fails 2.4.7: in no mode does anything change on
  the screen when the button takes focus, which is the outcome of failure
  [F78](https://www.w3.org/WAI/WCAG22/Techniques/failures/F78) (styling
  that "removes or renders non-visible the visual focus indicator").
  2.4.7 sets no contrast; Understanding 2.4.7 leaves that to 1.4.11.
- **1.4.11**: per
  [Understanding 1.4.11](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html),
  an indicator drawn outside a component must contrast with the
  background the component is on; one inside it, with the colours inside;
  one on the component's border, with both. The criterion does not
  compare the focused and unfocused states, and a change of background
  colour within the component "is not in scope". `bad-checkbox-halo` and
  `bad-cupertino-ring` (in light mode) fail it: both indicators are
  drawn outside the control, on the page, at 1.22:1 to 1.26:1 and, in
  light mode, 2.49:1 against it (section 7). The checkbox shows focus in
  one more way, which does not change the verdict: its box's 2 pixel
  border turns from `onSurfaceVariant`, `#46464F`, to `onSurface`,
  `#1B1B21`, a change of 1.82:1 between the two states; both colours are
  9:1 or more against the page, so the border identifies the box in
  either state and not which state it is in. What identifies the focused
  state is the halo, at 1.23:1 (read in the source,
  `_CheckboxDefaultsM3.side`; the colours measured in the probe). Material's default overlay on a button or a list tile, a
  tint of the control's own background at 1.14:1 to 1.45:1 against what
  it replaced, is a change of background within the component and so is
  not a 1.4.11 failure; it is weak, and is recorded as such
  ([FL-434](../flutter-limitations.md#fl-434)).
- **The 1.4.11 exception** for a component whose appearance "is
  determined by the user agent and not modified by the author" does not
  cover Flutter's default indicators, on any platform:
  - Web: the user agent is the browser. Its own focus outline is never
    seen: the web engine makes every semantics element transparent
    (`filter: opacity(0%)`, read in the engine source,
    `lib/web_ui/lib/src/engine/semantics/semantics.dart`, and asserted by
    the web test), and the indicator the user sees is painted on the
    canvas by Flutter's widget code, which the author ships with the
    page. That is the author's presentation, not the browser's.
  - Android and iOS: [WCAG2ICT](https://www.w3.org/TR/wcag2ict-22/#non-text-contrast)
    reads the exception as appearance "determined by the user agent or
    other platform software", and gives as an example of the author's
    modification "content that sets the visual style of a control ... to
    differ from the default style for the user agent or platform". A
    Flutter app does not use the platform's controls or their focus
    appearance; Flutter's widgets are a library compiled into the app,
    and what they draw differs from Android's and iOS's own focus styles.
    This spec treats that as the author's presentation. If Flutter itself
    were read as "other platform software", its unmodified default rings
    and halos would be excepted on Android and iOS (never on the web);
    the measurements in section 7 stand either way.
- **2.4.11** asks that the focused component is "not entirely hidden due
  to author-created content"; partly hidden passes
  ([Understanding 2.4.11](https://www.w3.org/WAI/WCAG22/Understanding/focus-not-obscured-minimum.html)).
  `bad-notice-over-list` fails it the way failure
  [F110](https://www.w3.org/WAI/WCAG22/Techniques/failures/F110)
  describes (a sticky footer completely hiding focused elements): three
  of its six trails are entirely under the notice when Tab reaches them.
  The notice is drawn by the app, is in its first position, and is not
  something the user opened. Trail 3, 87% to 88% in sight, passes.
- 2.4.13 Focus Appearance is AAA and not in scope. For reference: it asks
  for a change of contrast of 3:1 between the focused and unfocused
  states over an area at least as large as a 2 pixel perimeter. Material's
  default overlay (a change of 1.14:1 to 1.45:1) and the halo would not
  meet it; the good examples' rings, a change of 13:1 to 20:1, would.

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | Every control that takes keyboard focus shows that it has it | [Android View: Custom Focus Indicators](https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/dynamicbehaviors/CustomFocusIndicators.md) ("all standard Android control types have focus indicators which display when keyboard focus is on a control"), [Understanding 2.4.7](https://www.w3.org/WAI/WCAG22/Understanding/focus-visible.html) |
| R2 | The indicator is strong enough to find: the platforms' defaults "are generally low-contrast", so a custom indicator of 3:1 or more is drawn | Android View and [Android Compose: Custom Focus Indicators](https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/interactions/CustomFocusIndicators.md) (both cite 2.4.7 and 2.4.13), [Understanding 1.4.11](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html) |
| R3 | The indicator is drawn from the control's focused state: a border or outline of a state-dependent colour, or a button's own border | Android View (a colour state list on `app:strokeColor`, a drawable state list on `android:background` or `android:foreground`, `state_focused`), Android Compose (`Modifier.border()` with a colour set from `onFocusChanged`; `Button`'s `border`; a custom `Indication`) |
| R4 | It works in light and dark themes, and is more than a change of hue | Android View (a colour for each theme), Android Compose ("distinguishable in both Light and Dark themes"; "distinguished by more than hue", 1.4.1) |
| R5 | The control with focus is not entirely hidden by content the author pinned over the view | [Understanding 2.4.11](https://www.w3.org/WAI/WCAG22/Understanding/focus-not-obscured-minimum.html), [F110](https://www.w3.org/WAI/WCAG22/Techniques/failures/F110), [C43](https://www.w3.org/WAI/WCAG22/Techniques/css/C43) (scroll padding, the web's way to keep focused content clear of a sticky bar) |

The reference repositories have no iOS document for this entry; the
inventory lists the Android View and Android Compose ones. Neither covers
2.4.11; R5 comes from the Understanding document.

Flutter references for the mechanisms used:

- [`ButtonStyle.side`](https://api.flutter.dev/flutter/material/ButtonStyle/side.html) resolved with [`WidgetState.focused`](https://api.flutter.dev/flutter/widgets/WidgetState.html), and [`BorderSide.strokeAlignOutside`](https://api.flutter.dev/flutter/painting/BorderSide/strokeAlignOutside-constant.html)
- [`Focus.onFocusChange`](https://api.flutter.dev/flutter/widgets/Focus/onFocusChange.html) and [`DecoratedBox`](https://api.flutter.dev/flutter/widgets/DecoratedBox-class.html)
- [`CupertinoButton.focusColor`](https://api.flutter.dev/flutter/cupertino/CupertinoButton/focusColor.html), [`CupertinoSwitch.focusColor`](https://api.flutter.dev/flutter/cupertino/CupertinoSwitch/focusColor.html), [`CupertinoColors.label`](https://api.flutter.dev/flutter/cupertino/CupertinoColors/label-constant.html)
- [`FocusableActionDetector.onShowFocusHighlight`](https://api.flutter.dev/flutter/widgets/FocusableActionDetector/onShowFocusHighlight.html)
- [`FocusManager.highlightMode`](https://api.flutter.dev/flutter/widgets/FocusManager/highlightMode.html) and [`FocusHighlightMode`](https://api.flutter.dev/flutter/widgets/FocusHighlightMode.html)
- [`Scrollable.ensureVisible`](https://api.flutter.dev/flutter/widgets/Scrollable/ensureVisible.html), which traversal calls on the newly focused control

Comparison bar: an HTML `<button>` styled with `:focus-visible { outline:
3px solid currentColor; outline-offset: 2px }`. `:focus-visible` is
defined in Selectors Level 4, which leaves when to show focus to the user
agent's heuristics and suggests, without requiring them: show it after
the user interacts by keyboard; not after a pointer, unless the element
takes keyboard input such as text; and always if the user has asked for
that in a setting
([Selectors 4: `:focus-visible`](https://www.w3.org/TR/selectors-4/#the-focus-visible-pseudo)).
Flutter's highlight mode follows the first two (a text field's border is
drawn from its focused state, so it shows after a tap too). For the
third, an app can set `FocusManager.instance.highlightStrategy` to
`FocusHighlightStrategy.alwaysTraditional`; Flutter reads no user setting
for it (read in the source).
Flutter on the web cannot use it: the elements the browser focuses are
transparent, and Flutter paints its own indicator. For 2.4.11 the web has
`scroll-padding` ([C43](https://www.w3.org/WAI/WCAG22/Techniques/css/C43));
Flutter has no counterpart for what is drawn over a view (FL-432).

## 5. Examples

Each example ends with a line, "Last used: none", that names the control
Space or Enter last used, so that a test can tell which control a key
acted on.

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-material` | Material | A `CheckboxListTile` "Weather alerts" and a `FilledButton` "Save", each with a 3 pixel ring of the theme's text colour (`onSurface`) while it has focus | The button: `ButtonStyle.side` resolved for `WidgetState.focused`, drawn outside the shape (`strokeAlignOutside`). The tile, which has no such style: a `Focus` that takes no focus itself, hears the tile's focus change through `onFocusChange`, and draws the ring with a `DecoratedBox` | R1 to R4 |
| `good-cupertino` | Cupertino | A `CupertinoSwitch` "Weather alerts" in a `CupertinoListTile` and a `CupertinoButton.filled` "Save", with their own focus rings in the label colour | `focusColor: CupertinoColors.label.resolveFrom(context)` on both (black in light mode, white in dark) | R1 to R4 |
| `good-widgets` | Widgets layer | A card drawn by hand whose border turns from a 1 pixel outline to a 3 pixel line of the text colour while it shows focus | `FocusableActionDetector` with `onShowFocusHighlight`, so the ring follows Flutter's highlight mode as its own controls do | R1 to R4 |
| `good-notice-below` | Widgets layer | Six trail buttons in a scrolling box 232 pixels tall, and a notice, "Trail conditions are updated every morning.", laid out under the list in a `Column` | The scrolling view ends where the notice begins, so `ensureVisible` brings a focused trail wholly into sight | R5 |

The trail buttons of both notice examples are `TextButton`s with the same
focused `side` as `good-material`'s button, so that what they show when
they have focus is not in question.

There is no text field. The probe measured a Material `TextField`'s
focused border (2 pixels of `primary`, 6.12:1 against the page in light
mode and 10.9:1 in dark) and found it sufficient, but on CI's emulator,
which has no hardware keyboard, a focused field brings up the on-screen
keyboard over the example. `CupertinoTextField` shows focus only by its
caret (section 7, [FL-435](../flutter-limitations.md#fl-435)).

### Bad

| Slug | Defect | Violates | Fails |
| --- | --- | --- | --- |
| `bad-indicator-removed` | A `FilledButton` with `overlayColor: WidgetStatePropertyAll(Colors.transparent)`, as is done to be rid of the tint a press leaves. The overlay is all a `FilledButton` changes for focus: Tab reaches the button and nothing on the screen changes | R1 | 2.4.7, all platforms |
| `bad-checkbox-halo` | A Material `Checkbox` and its label, with the checkbox's default focus indicator: a disc of the text colour at a tenth of its strength round the box. 1.22:1 to 1.23:1 against the page in light mode, 1.26:1 in dark. Radio buttons and switches have the same halo ([FL-430](../flutter-limitations.md#fl-430)) | R2 | 1.4.11, all platforms. The box's border also darkens on focus, 1.82:1 between the states (section 3) |
| `bad-cupertino-ring` | A `CupertinoButton.filled` with its default focus ring, a pale tint made from the button's colour: 2.49:1 against the page in light mode. In dark mode it is 3.79:1 and passes ([FL-431](../flutter-limitations.md#fl-431)) | R2, R4 | 1.4.11 in light mode, all platforms; passes in dark mode (3.79:1, asserted in the widget tests) |
| `bad-notice-over-list` | `good-notice-below` with the notice drawn over the bottom of the scrolling box (a `Stack` and `Positioned`). Tab reaches trails 4, 5, and 6 while they are entirely under the notice ([FL-432](../flutter-limitations.md#fl-432)) | R5 | 2.4.11, all platforms |

Not built:

- A bare `Focus` round a control that draws nothing (probe fixture `w1`):
  the same defect as `bad-indicator-removed`, from the widgets layer.
- An `InkWell` with `focusColor: Colors.transparent` (probe `x2`), the
  same defect again.
- A pinned header that hides focus. A pinned `SliverAppBar` in the same
  `CustomScrollView` is allowed for by Flutter's scrolling (probe `o3`,
  and a widget test), and a header drawn over the view in a `Stack` (probe
  `o4`) fails the same way as the notice, so a header example would add
  nothing to `bad-notice-over-list`. A `Scaffold` with `extendBody: true`
  and a bottom bar hides focused controls the same way (probe `o5`); it is
  in FL-432.

## 6. Assertions by layer

How focus visibility is asserted, on every layer, with the same rules
(implemented once per layer, in that layer's test file):

1. Capture the screen with the control unfocused (`u`), press Tab, check
   that the stop is that control, wait until two captures 300 ms apart
   differ in no more than 1% of the area (at most 3 s), and capture it
   twice, 700 ms apart (`f1`, `f2`). The area is the control's rectangle
   and 8 logical pixels round it, where a ring drawn outside it lies.
2. A pixel has changed if it differs from `u` by more than 12 in some
   channel in both `f1` and `f2`, and `f1` and `f2` agree. A pixel that
   differs in one capture only is unstable (a caret, an animation still
   running) and is not counted.
3. The page's colour is the commonest along the edge of the area in `u`.
   A changed pixel is a mark if it is drawn where the page was, or is 3:1
   or more from the colour it replaced: a ring is a mark, a tinted fill
   or a border a shade darker is not. A mark is strong if it is 3:1 or
   more against the page. Colours are read from the pixels and the ratio
   is WCAG's relative luminance formula, checked against known pairs.
4. A good control passes if it has more than 150 strong marks per square
   logical pixel of the screen's scale (a line all round a control is
   several hundred). A bad halo or ring must have more than 500 marks, a
   commonest mark under the limit, and almost no strong marks (under 2%).
   "Nothing drawn" is zero changed and zero unstable pixels.

What would make them fail: an unchanged image (no marks), a change
elsewhere than round the control (outside the area), a change that comes
and goes (unstable, not counted), a tint inside the control (not a
mark), or a ring under 3:1 (not strong). A change from something other
than focus is kept out by pressing only Tab: no tap, no pointer over the
page, nothing moving on the screen. A test that says nothing is drawn
first finds the Back button's indicator through the same measure in the
same launch (the positive control). After the last good control, Tab
moves on and its area must be as it was in `u`, pixel for pixel, which
shows the change was focus's.

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Good: guidelines in light and dark, 200% text at 320 by 640. Every control: its name and role (checkbox, switch, button), not focused at first, reached by Tab in order after Back (each stop named by the node that is focused), and used by Space. Pixels, from the app's own layer tree at a device pixel ratio of 1, in light and dark: each good control has strong marks, and the last one's area returns to `u` when focus moves on; `bad-indicator-removed` changes nothing, after Back, the positive control, has marks; `bad-checkbox-halo`'s marks are wider than the box and under 1.5:1, with no strong ones, in both themes; `bad-cupertino-ring`'s are under 3:1 in light mode and pass in dark. 2.4.11: at each of the six stops, how much of the focused trail is inside the scrolling box and not under the notice: all of it in `good-notice-below`; in `bad-notice-over-list` trails 1 and 2 all (the positive control), trails 4 to 6 none, and the pixels where trail 6 is are only the notice's colours. A pinned `SliverAppBar` keeps every button below it as Shift+Tab goes up. The highlight mode: a touch hides `good-widgets`' ring with focus where it was, and Shift alone brings it back |
| L3 web | The same: role, name, Tab order by `document.activeElement`, Space; the focused element is inside one with `filter: opacity(0%)`, so the browser's outline is not seen; the same pixel measure on Chromium's screenshots; the same 2.4.11 measure from the elements' rectangles |
| L3 Android | Name and class (`CheckBox`, `Switch`, `Button`) through UI Automator; stops by `isFocused`, with Tab reaching every control of every example. Keys from a keyboard registered through `uinput` (section 7). The same pixel measure on `UiAutomation.takeScreenshot`, for every example as in the widget tests, with Back as the positive control for `bad-indicator-removed`. FL-433: in one launch, Tab from `input keyevent` puts focus on `good-widgets`' card with nothing drawn, and Shift alone from the registered keyboard then draws its ring. The same 2.4.11 measure from `getBoundsInScreen`, with a trail scrolled out of its list found by scrolling the list itself. Run at the emulator's own size and at 320 by 640 at 160 dpi |
| L3 iOS | Label and type (a checkbox is a switch to XCUITest, FL-035); every stop shown by Space and the "Last used" line; the same pixel measure on `XCUIScreen` screenshots drawn into sRGB; the same 2.4.11 measure from the elements' frames |
| L4 TalkBack | Each control's name and role; a trail under the notice is read like any other |
| L4 VoiceOver iOS | Every utterance between the "Example" heading and the "Last used" line |
| L4 VoiceOver web | Every stop between the "Example" heading and the "Last used" line |

A focus indicator is drawn, not spoken: no defect of V14 is heard, and
the screen reader layers record that the bad examples sound like the
good ones.

## 7. What the build found (Flutter 3.47.5)

The probe that came first is in
[evidence/probes/v14](../evidence/probes/v14/README.md), with the raw
output and the sampled colours of each platform. Every figure here is
read from pixels; "read in the source" marks what was not measured.

- **Flutter draws the same indicator on every platform.** The widget
  tests, Chromium, and the iOS simulator gave the same colours for every
  probe fixture, to the last digit, and the V14 tests the same again. On
  the web the element the browser focuses is transparent (the engine's
  `filter: opacity(0%)`, read in the source and asserted by the web
  test), so the browser's outline is never what is seen.
- **Material's defaults** (probe fixtures m1 to m15): most controls tint
  their own background with a tenth of the foreground colour, a change of
  1.14:1 to 1.32:1 in light mode and 1.11:1 to 1.45:1 in dark
  ([FL-434](../flutter-limitations.md#fl-434)); checkboxes, radio
  buttons, and switches draw a halo outside the control at 1.21:1 to
  1.49:1 ([FL-430](../flutter-limitations.md#fl-430)); a `TextField`'s
  border turns 2 pixels of `primary`, 6.12:1 (10.9:1 in dark), whenever it
  has focus; an `OutlinedButton`'s outline turns `primary` as well as
  tinting.
- **Cupertino's defaults** (c1 to c5): a ring outside the control, a pale
  tint of the control's colour: 1.89:1 with the default blue and 1.29:1
  for a switch in light mode, 5.42:1 and 8.58:1 in dark; 2.49:1 in this
  app, whose Cupertino primary colour is the Material theme's
  ([FL-431](../flutter-limitations.md#fl-431)). A `CupertinoTextField`
  draws nothing but its caret ([FL-435](../flutter-limitations.md#fl-435)).
- **What the examples measured**, light mode on every layer and dark mode
  in the widget tests (marks of 3:1 or more, with their colour and ratio
  to the page):
  - `good-material`: the tile's ring `#1B1B21`, 16.30:1 (dark `#E4E1E9`,
    14.35:1); its own tint is the commonest change, at 1.32:1, where
    highlights are on. The button's ring the same colours.
  - `good-cupertino`: black rings, 19.97:1; white in dark, 18.55:1.
  - `good-widgets`: the border `#1B1B21`, 16.30:1; dark 14.35:1.
  - `bad-indicator-removed`: no pixel changed, on every layer, while the
    Back button's tint, the positive control, was found (1.22:1 to
    1.23:1, over a thousand pixels at a device pixel ratio of 1).
  - `bad-checkbox-halo`: `#E4E1E8`, 1.23:1 (web `#E4E2E8`, 1.22:1); dark
    `#27282D`, 1.26:1; no mark at 3:1.
  - `bad-cupertino-ring`: in light mode `#8A9AF5`, 2.49:1, no mark at
    3:1; in dark mode `#5C69C6`, 3.79:1 (widget tests, asserted to be 3:1
    or more).
  - `bad-notice-over-list`: the share of each focused trail in sight was
    1, 1, 0.88, 0, 0, 0 on every layer (0.87 for trail 3 on Android);
    in `good-notice-below`, 1 for each.
- **When Flutter draws an indicator** (read in the source:
  `widgets/focus_manager.dart`): most indicators show only in the
  traditional highlight mode, which a key turns on and a touch turns off,
  focus staying where it was. Seen in the widget tests (asserted for
  `good-widgets`), on the web, and on iOS: Tab put the mode on traditional
  and the indicator appeared; a tap elsewhere put it on touch and the
  indicator went, apart from those drawn from the focused state itself
  (text field borders, `ButtonStyle.side`, a `Focus` ring), which stayed.
  On the web a tap on a button gave it focus and drew nothing. Before any
  input the mode is touch on Android and iOS and traditional on the web
  in Chromium on macOS. This meets 2.4.7.
- **On Android, keys from Android's own injection do not turn highlights
  on; keys from a registered keyboard do**
  ([FL-433](../flutter-limitations.md#fl-433)). Every key sent with `input
  keyevent`, `Instrumentation.sendKeySync`, or
  `UiAutomation.injectInputEvent` reached Flutter with device id -1, the
  virtual keyboard's, whatever id it was sent with, and Flutter does not
  let a key from that device change the mode: focus moved and only the
  indicators drawn from the focused state appeared (probe rounds 1 to 3).
  The emulator console's keys did not reach the app, and no way of moving
  a mouse reached Flutter as a mouse (rounds 4 and 5). A USB keyboard
  registered with the shell's `uinput` tool did work (round 6): its keys
  arrived with a device id of its own (24 to 27), the first one turned the
  mode traditional, and every indicator was drawn with the same colours as
  in the widget tests, on the web, and on iOS. The V14 Android test
  registers such a keyboard for its keys (`Keyboard` in the test file, a
  `uinput` session opened with `UiAutomation.executeShellCommandRw` and
  closed after each test, which removes the device), and passed with it
  at the emulator's own size and at 320 by 640 at 160 dpi; it does not
  depend on the emulator's hardware keyboard setting, as the keyboard is
  a device of its own. Its FL-433 test shows both in one launch: Tab from
  `input keyevent` reaches `good-widgets`' card and nothing is drawn;
  Shift alone from the registered keyboard then draws the ring. While a
  registered keyboard had been used, Android drew a 4 pixel lime frame
  round the edges of the screen and a small icon in the status bar
  (round 6); the measured regions do not reach the edges. The other
  wave 4 techniques' Android tests send `input keyevent` and
  Instrumentation keys, so they see what an on-screen keyboard's user
  sees, not a hardware keyboard's; a `uinput` keyboard would let them see
  the second (not changed here).
- **A focused control can be scrolled under content drawn over its view**
  ([FL-432](../flutter-limitations.md#fl-432)), on every platform: a
  banner over the bottom (probe o1 and `bad-notice-over-list`), a header
  over the top (o4), and a `Scaffold` with `extendBody: true` and a bottom
  bar (o5). A pinned `SliverAppBar` in the same `CustomScrollView` is
  allowed for (o3, and the widget test of Shift+Tab under one), and
  content laid out beside the view is not in the way (o2,
  `good-notice-below`).
- **Screen readers say nothing of focus indicators**, as expected: the
  bad examples are read as the good ones, and a trail under the notice is
  read as any other (the transcripts).
- **Observed, not V14's subject: VoiceOver on iOS did not swipe into the
  trails scrolled out of the box.** In both notice examples its swipes
  went from the last trail in the box's view to the notice, after one
  silent stop before the first trail (the transcript); Tab reaches every
  trail. Not looked into; handed to I14 (section 8).

**Not done yet.** A physical keyboard on a physical Android device (the
`uinput` keyboard is a kernel input device on the emulator); a real
on-screen keyboard's Tab key (FL-433, by the source); Full Keyboard
Access on iOS, which draws a ring of the system's own; forced colours and
Windows High Contrast on the web; dark mode on the devices (the widget
tests and the probe cover it); text fields as examples; WebKit and
Firefox; focus moved from code (whether a ring shows then: by the source,
those drawn from the focused state do, the others only once a key has been
pressed); focus indicators in dialogs, menus, tabs, and other components
of later waves.

## 8. What is handed on

- **V13 Minimum touch target size**: a ring drawn outside a control
  (`strokeAlignOutside`, 3 pixels) needs room between controls; the
  examples give 4 to 8 pixels.
- **V01 Colour contrast, V02, and V03 (wave 5)**: the contrast of
  text, including labels that change colour on focus (a Material text
  field's label turns `primary`), and FL-441's action sheet text.
- **I01 to I03 and the later keyboard techniques**: their Android tests
  press keys with `input keyevent` and Instrumentation, which Flutter
  takes for the on-screen keyboard's (FL-433). Where what is drawn, or
  anything that follows the highlight mode, matters, a keyboard
  registered through `uinput`, as V14's Android test does, gives what a
  hardware keyboard's user sees. Not changed in those techniques.
- **I03 Focus management**: whether a control focused from code shows its
  ring. The rings drawn from the focused state show at once; those that
  follow the highlight mode show only if the last input was a key.
- **I04 Keyboard shortcuts and I08 Dismiss and escape**: no change; a
  shortcut that moves focus should be checked with this technique's
  measure.
- **C08 to C10, dialogs and sheets (wave 7)**: a modal barrier or a sheet
  over a scrolling page is content drawn over a view; where focus can stay
  behind it, FL-432 applies.
- **C-numbered navigation components (wave 8)**: a `NavigationBar` or
  `BottomAppBar` with `Scaffold(extendBody: true)` hides focused content
  under it (FL-432, probe o5).
- **I14 Scrolling regions**: in a scrolling box inside a scrolling page,
  VoiceOver on iOS, moving by swipes, stopped once silently before the
  box's first trail and did not go on to the trails scrolled out of the
  box (the V14 VoiceOver transcript for iOS). Whether that is the inner
  scrolling view, and whether a three-finger scroll reaches them, was not
  checked.
- **The shared test helpers**: the pixel measure exists four times, once
  in each layer's V14 test file. If later techniques measure focus, it
  could move to a shared helper per layer (the report to the wave's
  principal says so); nothing shared was changed here.
