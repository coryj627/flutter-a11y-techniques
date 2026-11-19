# Spec: I02 Keyboard focus order

Status: Draft 1 (2026-11-18), written with the build. Second technique of
batch 5, focus and keyboard ([plan](../plan.md)), built in wave 4. Flutter
pin: 3.47.5.

This spec covers the order that Tab and Shift+Tab move keyboard focus in,
and what the arrow keys do with it. Making a control reachable at all is
[I01 Focusable and clickable controls](I01-focusable-controls.md); moving
focus from code (after a dialog opens or closes, after an error) is I03;
other keys and shortcuts are I04; Escape and keyboard traps are I08; how
focus looks is V14. The order a screen reader moves in is S11 Reading and
traversal order (wave 3); section 8 says where the two meet.

## 1. Rule

Moving forward with Tab, and back with Shift+Tab, reaches the controls of
a screen in an order that keeps their meaning: what belongs together is
reached together (one column, then the next), and nothing is reached
after the action that finishes what it belongs to. Shift+Tab goes the same
way backwards. Where the arrow keys move focus, they move it to the
control on that side.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies | Applies | Applies |

Android and iOS: a hardware keyboard (Tab, Shift+Tab, the arrow keys, a
D-pad). Web: the browser's keyboard. On the web the arrow keys scroll and
do not move focus, as in any web page (section 7).

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [2.4.3 Focus Order](https://www.w3.org/TR/WCAG22/#focus-order) | The examples can be navigated sequentially, and the order of their controls carries meaning: which list a choice belongs to, and that the choices come before the action that saves them |
| [2.1.1 Keyboard](https://www.w3.org/TR/WCAG22/#keyboard) | Every control can be reached and operated with the keyboard, forwards and backwards |

The two bad examples fail 2.4.3 as it is written, and each in the way the
Understanding document's own failing example does: there, a form has a
section of address fields and a section of newsletter checkboxes, and the
tab order moves between the two sections, from the name field to a
checkbox and back to the address
([Understanding 2.4.3](https://www.w3.org/WAI/WCAG22/Understanding/focus-order.html),
examples). `bad-columns-mixed` moves between the two lists of one form,
row by row. `bad-order-missing` reaches a choice of the first list after
the button that saves the form, so someone who goes forward through the
form saves it before they have met that choice; that affects operation.
The same document says that two columns that are independent of each
other may be reached in either order: these two are not independent, as
both are parts of one plan saved by one button.

Neither bad example fails 2.1.1: every control can still be reached. On
the web `bad-order-missing` also never lets Tab leave the page (section
7, [FL-421](../flutter-limitations.md#fl-421)); Shift+Tab does, so that is
not a keyboard trap under 2.1.2 either.

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | Focus moves in an order that keeps the meaning of the layout: a two-column layout is reached one column at a time | [Android View: Keyboard and Accessibility Focus Order](https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/grouping/KeyboardAndAccessibilityFocusOrder.md) (two inner vertical layouts, one per column), [Android Compose: Keyboard Focus Order](https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/interactions/KeyboardFocusOrder.md) (a `Row` of two `Column`s), [Understanding 2.4.3](https://www.w3.org/WAI/WCAG22/Understanding/focus-order.html) |
| R2 | The order comes from the structure of the layout where it can, and is given explicitly only where the layout cannot give it | Android View (correct layout grouping first, `nextFocusForward` where needed), Android Compose (`focusProperties` and `FocusRequester` when layout cannot, as with `ConstraintLayout`; "This approach is preferred when possible" of the layout), [MDN: tabindex](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Global_attributes/tabindex) (write the document in a logical sequence; avoid positive values) |
| R3 | An explicit order covers every control, so none falls out of sequence | Android Compose (point `next` and `previous` at every control in turn; never create a loop), MDN (positive values make keyboard navigation difficult) |
| R4 | The keyboard's order and the screen reader's order are set separately, and both are kept | Android View (`nextFocusForward` is "keyboard (but not accessibility)"; `accessibilityTraversalBefore` the reverse), Android Compose ("accessibility traversal order is set separately from keyboard focus order") |
| R5 | The arrow keys move focus to the control in their direction | [Android View: Arrow Key Focus Order](https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/grouping/ArrowKeyFocusOrder.md) |

Flutter references for the mechanisms used:

- [Understanding Flutter's keyboard focus system](https://docs.flutter.dev/ui/interactivity/focus), the section on focus traversal
- [`FocusTraversalGroup`](https://api.flutter.dev/flutter/widgets/FocusTraversalGroup-class.html), [`ReadingOrderTraversalPolicy`](https://api.flutter.dev/flutter/widgets/ReadingOrderTraversalPolicy-class.html) (the default)
- [`OrderedTraversalPolicy`](https://api.flutter.dev/flutter/widgets/OrderedTraversalPolicy-class.html), [`FocusTraversalOrder`](https://api.flutter.dev/flutter/widgets/FocusTraversalOrder-class.html), [`NumericFocusOrder`](https://api.flutter.dev/flutter/widgets/NumericFocusOrder-class.html)
- [`DirectionalFocusIntent`](https://api.flutter.dev/flutter/widgets/DirectionalFocusIntent-class.html) and [`WidgetsApp.defaultShortcuts`](https://api.flutter.dev/flutter/widgets/WidgetsApp/defaultShortcuts.html)
- For the screen reader's order, kept in step: [`Semantics.container`](https://api.flutter.dev/flutter/widgets/Semantics/container.html), [`OrdinalSortKey`](https://api.flutter.dev/flutter/semantics/OrdinalSortKey-class.html) (S11's subject)

Comparison bar: an HTML form whose two `<fieldset>`s sit side by side,
each written as one block in the document, with no `tabindex` above 0, as
MDN advises. The browser's Tab follows the document, so it goes down one
column and then the other. Radix has no primitive for focus order.

## 5. Examples

Every example is one plan for a hike: two lists of checkboxes side by
side, "Pack" (Map, Water, First aid) and "Send me" (Weather, Closures),
and a "Save plan" button under them, then the count of saves. The order
meant is down the first list, down the second, then Save plan. Each
column is a semantics container in every example, so that a screen reader
reads one list and then the other everywhere; the bad examples differ
from a good one only in the keyboard's order.

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-material` | Material | The two lists, each a `FocusTraversalGroup` | `FocusTraversalGroup` around each column of `CheckboxListTile`s, a `FilledButton` | R1, R2, R4, R5 |
| `good-cupertino` | Cupertino | The same with Cupertino controls | `FocusTraversalGroup` around each column of `CupertinoCheckbox`es (each merged with its text, as in F07), a `CupertinoButton.filled` | R1, R2, R4, R5 |
| `good-ordered` | Widgets layer | The same choices laid out row by row, where no widget holds a column, so the order is given by number | `FocusTraversalGroup(policy: OrderedTraversalPolicy())`, a `FocusTraversalOrder` with a `NumericFocusOrder` on every control, and an `OrdinalSortKey` with the same number on every element so the screen reader's order agrees | R1 to R5 |

The widgets-layer example is about the traversal widgets, which are
widgets-layer; its controls are Material checkboxes. A hand-made control
is I01's subject.

### Bad

| Slug | Defect | Violates | Fails |
| --- | --- | --- | --- |
| `bad-columns-mixed` | `good-material` without the two `FocusTraversalGroup`s. Flutter's default order is by position, row by row, so Tab goes Map, Weather, Water, Closures, First aid: back and forth between the two lists. A screen reader still reads one list and then the other ([FL-420](../flutter-limitations.md#fl-420)) | R1, R4 | 2.4.3 |
| `bad-order-missing` | `good-ordered` with First aid given its sort key and no `FocusTraversalOrder`. `OrderedTraversalPolicy` puts a control with no order after all the ordered ones, so Tab reaches First aid after Save plan, cut off from its list. On the web Tab then goes round Weather, Closures, Save plan, and First aid and never leaves the page ([FL-421](../flutter-limitations.md#fl-421)) | R3 | 2.4.3 |

Not built:

- A keyboard trap made by the order (the Android Compose reference's bad
  example 4). It fails 2.1.2, which is I08's.
- An order given by number where every number is present and wrong. It
  would show the same defect as `bad-columns-mixed` by another route.
- An arrow-key example. The arrow keys move by position on Android and
  iOS and do the right thing in every example here; on the web they
  scroll. Flutter has no per-control `nextFocusDown` to get wrong; what
  the arrows do is asserted for every example instead (section 6), and
  where position alone gives a poor answer is recorded in section 7.

## 6. Assertions by layer

Every order is read stop by stop and each stop is named: by the node that
reports focus (widget tests, Android), by `document.activeElement` (web),
or by what Space does there (iOS, where XCUITest cannot see focus).

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Good: guidelines in light and dark, and no overflow with 200% text at 320 by 640. At that size each column's text is 80 logical pixels wide and the labels wrap inside words in the test font; nothing is cut off. The columns are kept side by side because that layout is what the technique is about; what real fonts do there was not measured. Every example: five named checkboxes, not checked and not focused, and a "Save plan" button; a tap changes each box and Save plan counts; the semantics order is the column order. Tab from the start, stop by stop, then round to Back; Shift+Tab the same backwards from the last stop and round; Space at each stop changes the box that has focus and no other. The arrow keys, as on Android and iOS: Down, Up, Left, and Right each move to the control on that side. The SDK alone (FL-420): two columns of buttons with neither, either, or both of `FocusTraversalGroup` and a semantics container: the group sets the Tab order and not the semantics order, the container the reverse. `OrderedTraversalPolicy` puts a control with no order last. FL-422: a long scrolled list under an app bar takes Back in among its buttons, and does not with a `FocusTraversalGroup` around the scrolling view. On an 800 by 120 screen, where the example scrolls until Map is above the top of the screen: each good example's Tab order stop by stop, round to Back, and Shift+Tab from Save plan back to Back; `bad-columns-mixed` goes round from Save plan to Back, which needs `PageScaffold`'s group |
| L3 web | Every example: five checkboxes with names, `aria-checked="false"`, and `tabindex="0"`, and a button "Save plan"; the controls are in the document in the column order. Tab from the start, stop by stop; Shift+Tab backwards; Space at each stop changes only the box with focus (`aria-checked`). Past Save plan, Tab leaves the page's content, except in `bad-order-missing`, where Tab past First aid goes round Weather, Closures, Save plan, and First aid twice and never leaves, and Shift+Tab gets out (FL-421). The arrow keys leave focus where it is. On an 800 by 120 page, where the example scrolls until Map is above the top of the page, each good example's Tab and Shift+Tab orders stop by stop |
| L3 Android | Every example: the five checkboxes (`CheckBox`, checkable, not checked, not focused) and the button; the controls are in the tree in the column order, read at each scroll position on a screen where the example scrolls. Tab (`input keyevent`) stop by stop from Back, then round to Back; Shift+Tab (four events through `Instrumentation.sendKeySync`) backwards and round; Space at each stop changes only the box with focus; the D-pad arrows each move to the control on that side |
| L3 iOS | Every example: the five checkboxes (switches to XCUITest, FL-035, value "0") and the button. The first Tab on a freshly opened screen goes to Back (Space there leaves the screen), and that check fails when focus is one stop further on, on Map (`XCTExpectFailure`). Tab (`typeKey`) stop by stop, each named by the one box Space changes or by the count, then round to Back (Space leaves the screen); Shift+Tab the same backwards; the arrow keys each move to the control on that side |
| L4 TalkBack | Each control: its name and "Check box" (no state, FL-045) or "Button". The walk puts TalkBack's focus on each control, so it records speech, not order |
| L4 VoiceOver iOS | Everything between the "Example" heading and the count, moving with VoiceOver's own swipes: "Pack", the three boxes, "Send me", the two boxes, "Save plan Button", in every example |
| L4 VoiceOver web | The same with VoiceOver's own cursor: each column a group named by its title, or, in the numbered examples, each title as text; the same order in every example |

The keyboard's order is not heard: a screen reader moves in its own
order, which is right in all five examples. The screen reader layers
record that the bad examples read like the good ones.

## 7. What the build found (Flutter 3.47.5)

The probe that came first is in
[evidence/probes/i02](../evidence/probes/i02/README.md), with the raw
output of each platform.

- **Flutter's default order is by position, not by the layout's
  structure.** `ReadingOrderTraversalPolicy` takes the highest control,
  then any others whose rectangle overlaps its row, in reading direction,
  and so on, so two columns with level rows are reached row by row, on
  every platform. Android Views, Compose, and HTML follow the layout or
  the document instead. A `FocusTraversalGroup` per column fixes it
  ([FL-420](../flutter-limitations.md#fl-420)).
- **The keyboard's order and the screen reader's are set by different
  widgets.** `FocusTraversalGroup` has no semantics node
  (`includeSemantics: false`, read in the source), so it does not change
  the screen reader's order; a semantics container or a sort key does not
  change the keyboard's. Without a container, the screen reader's order
  of two columns was row by row on the web, Android, and iOS and column by
  column in a widget test of the same layout: the framework sorts the
  semantics by position too, by its own rules (read in the source:
  `_childrenInDefaultOrder`). So every example here has a container per
  column, and the widget tests assert the two orders apart (FL-420).
- **`OrderedTraversalPolicy` puts a control with no order last**, after
  all the numbered ones, as its documentation says. HTML does the same:
  elements with a positive `tabindex` come first and the rest after.
- **On the web, Tab past Flutter's last control continues in the
  document's order** ([FL-421](../flutter-limitations.md#fl-421)). Flutter
  handles Tab itself, and at the end of its order lets the browser have
  it so that focus can leave the page. The browser goes to the next
  element in the document; if that is one of Flutter's, Flutter carries on
  from there. In `bad-order-missing` Tab goes round Weather, Closures,
  Save plan, and First aid and never leaves. When the last control of the
  focus order is also last in the document, as in the other four
  examples, Tab leaves the page.
- **On a scrolled screen the default order puts Back among the content**
  ([FL-422](../flutter-limitations.md#fl-422)): the order is worked out
  from positions on the screen at each key press, and controls scrolled
  away above are higher than the app bar. Shift+Tab up a long list stops
  on Back every press or two, and Tab past the end goes round to the
  first control of the list and skips Back. Found on the web, reproduced
  in a widget test, and seen on Android and iOS as the skipped Back. A
  `FocusTraversalGroup` around the scrolling view fixes it in the widget
  test, and the app's `PageScaffold` now has one
  (`test/app/page_scaffold_focus_test.dart`). On an 800 by 120 screen,
  where each example scrolls until Map is above the top of the screen,
  the good examples keep their order forwards, round to Back, and
  backwards (widget tests; and on the web, Chromium at the same size,
  forwards and backwards). They kept it with the scaffold's group taken
  out as well: each of their `FocusTraversalGroup`s is tall enough to
  reach down into Back's row, so Back stays first (read in the source:
  the bands of `ReadingOrderTraversalPolicy`). `bad-columns-mixed`, whose
  controls are in no group, is the one that needs the scaffold's group:
  without it, Tab past Save plan went round to Map and skipped Back.
- **The arrow keys move by position on Android and iOS**, within and
  across groups, and in every example go to the control on that side.
  Where nothing is in line, they can leave a group: in the probe's cross
  of four buttons, Down from Left went past Down to the next control
  below Left. **On the web they scroll** and do not move focus, as in a
  web page (`WidgetsApp`'s web shortcuts, read in the source).
- **Shift+Tab can be sent on the Android emulator**, as four events
  through `Instrumentation.sendKeySync`: Shift down, Tab down and up with
  the Shift meta state, Shift up. A Tab with only the Shift meta state
  (`pressKeyCode` with a meta state, `input keycombination`) arrives as a
  plain Tab: for the virtual keyboard's events the engine trusts the meta
  state without adding a Shift press (read in the source:
  `KeyEmbedderResponder.java`). `sendevent` was refused and the emulator
  console's `event send` reached nothing.
- **On CI's Android emulator (320 by 640 at 160 dpi) the example
  screens scroll, and a node out of view is not in the tree UI Automator
  reads.** On that screen, set on the local emulator with `wm size` and
  `wm density`, `bad-columns-mixed`'s count, below its longer defect
  text, was missing from the tree when the screen opened, and the other
  four examples' counts were there; at the local emulator's own size all
  five were. The Android tests wait for Map, near the top, and scroll to
  any node out of view. Every Android order assertion (Tab, Shift+Tab,
  the D-pad arrows, round to Back) passed at both sizes, for all five
  examples.
- **iOS**: `typeKey` with `.shift` sends Shift+Tab; Space checks the box
  that has focus, which is how the iOS tests name each stop, since
  XCUITest cannot see focus.

**Not done yet.** Full Keyboard Access on iOS, and Switch Access and
Switch Control, which move in an order of their own; what a screen reader
says when keyboard focus lands on a control; a right-to-left layout
(`ReadingOrderTraversalPolicy` follows `Directionality`, read in the
source, not tested); TalkBack's own moves (its walk puts its focus on each
control); and lists that build lazily, where controls out of view do not
exist yet.

## 8. Where I02 meets the screen reader's order (S11)

I02 is the order of keyboard focus, WCAG 2.4.3 for sequential keyboard
navigation. S11 Reading and traversal order (wave 3) is the order a
screen reader moves its own cursor in, 1.3.2 Meaningful Sequence and 2.4.3
for screen reader navigation. They meet in four places:

- **Each example sets both.** I02's good examples put a semantics
  container on each column, or a sort key on each element, so that the
  screen reader reads them in the same order as Tab. That is S11's
  mechanism; I02 uses it and tests the result (the widget tests' semantics
  order, the Android tree's order, the web document's order, and the two
  VoiceOver walks), and leaves its rules (sort keys, containers,
  `explicitChildNodes`, `traversalParent`) to S11.
- **The two are independent** (FL-420), which the I02 widget tests show
  both ways. S11 should show, from its side, that a sort key does not
  move Tab, and that its own good examples do not leave Tab in an order
  that differs from the reading order.
- **The framework's default reading order of side-by-side columns
  depends on the geometry**: by column where rows touch, by row where
  they are apart, and differently in a widget test and on a device. S11
  owns that finding and the cases where it misleads.
- **On the web the document's order is also the browser's Tab order at
  the edges** (FL-421): a reading order that ends on a different control
  from the focus order makes Tab go round. S11's sort keys can cause
  that; I02's fix is to keep the two orders the same.

Handed on:

- **I03 Focus management**: where focus goes after a route opens or
  closes; FL-422 (Back taken into the order on a scrolled screen), which
  the app's `PageScaffold` now avoids with a `FocusTraversalGroup` around
  its scrolling view, but which a screen with a scrolling view of its own,
  or a dialog, will meet again; and `TraversalEdgeBehavior` (`leaveFlutterView` on the web,
  `parentScope` elsewhere) for dialogs.
- **I04 Keyboard actions and shortcuts**: on the web the arrow keys
  scroll. Flutter has no per-control counterpart of Android's
  `nextFocusDown`; giving an arrow a target of its own would mean an
  action for `DirectionalFocusIntent` (not tried here).
- **I08 Dismiss and escape**: a keyboard trap made by the order (the
  Compose reference's bad example 4), and a `FocusScope` with
  `TraversalEdgeBehavior.closedLoop`, which keeps Tab inside it.
- **V14 Focus indicators**: every I02 example relies on the controls' own
  focus highlight; none was checked here.
- **I14 Scrolling regions**: FL-422, and whether a lazy list's controls
  out of view are reachable by Tab.
