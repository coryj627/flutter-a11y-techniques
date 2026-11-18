# Spec: I03 Focus management

Status: Draft 1 (2026-11-18), written with the build. Third technique of
batch 5, focus and keyboard ([plan](../plan.md)), built in wave 4. Flutter
pin: 3.47.5.

This spec covers where focus goes when the screen changes under it: when
a dialog opens and closes, when the control that had focus is removed,
and when code moves focus on purpose; and that taking focus changes
nothing by itself. The order Tab moves in is
[I02 Keyboard focus order](I02-focus-order.md); other keys and shortcuts
are I04; Escape and keyboard traps are I08; how focus looks is V14;
announcements are [I12](I12-announcements.md). What a dialog is (its role,
its name, that the content behind it is inert) is C08 Modal dialog, C09
Alert and confirmation dialog, and C10 Bottom sheet (wave 7); section 8
says what is handed to each.

## 1. Rule

When a dialog opens, focus goes into it, so that the next thing the user
meets is the dialog. When it closes, focus goes back to the control that
opened it; if that control is gone, to the control next to where it was.
Both keyboard focus and a screen reader's focus follow these moves. A
control that takes focus does not, by that alone, open, submit, or move
anything.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies | Applies | Applies |

Keyboard focus: a hardware keyboard on Android and iOS, the browser's on
the web. Screen reader focus: TalkBack, VoiceOver on iOS, and VoiceOver on
macOS in Chromium. Section 7 says, for each finding, which of the two was
measured.

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [2.4.3 Focus Order](https://www.w3.org/TR/WCAG22/#focus-order) | The examples can be navigated sequentially, and a dialog changes the order: its controls must come next when it opens, and the order must carry on from where it was when it closes |
| [3.2.1 On Focus](https://www.w3.org/TR/WCAG22/#on-focus) | Each Remove button takes focus; taking it must not open the question, which would move focus away |

How the bad examples fail, as the criteria are written:

- `bad-focus-left-behind` fails 2.4.3 by technique
  [F85](https://www.w3.org/WAI/WCAG22/Techniques/failures/F85), dialogs
  that are not next to their trigger in the sequential navigation order,
  on both of its tests. Activated from the
  keyboard, the dialog does not take focus, and the next Tab does not
  reach it: it goes to the control behind the dialog, and the dialog's
  buttons come only after the last control of the screen (F85's example
  1). When the dialog is closed with Cancel, focus does not come back to
  the button that opened it nor next to it: the next Tab starts again at
  the top of the screen (F85's example 2). Measured with the keyboard on
  all three platforms. A screen reader is not affected the same way
  (section 7).
- `bad-opens-on-focus` fails 3.2.1 in the way of the failure example in
  [Understanding 3.2.1](https://www.w3.org/WAI/WCAG22/Understanding/on-focus.html):
  a help dialog that opens when a field receives focus, and takes focus
  away from it each time the user tabs onto it. Moving focus to another
  component is one of the changes of context the Understanding document
  lists. Measured with the keyboard on all three platforms; on
  the web a screen reader's cursor sets it off too (section 7).

Neither bad example fails 2.1.1 or 2.1.2: every control can still be
reached and operated, and focus can leave the dialog.

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | When a dialog opens, focus moves into it | [iOS: Focus Management](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/FocusManagement.md) (`accessibilityFocused` on the dialog's heading when it opens), [Understanding 2.4.3](https://www.w3.org/WAI/WCAG22/Understanding/focus-order.html) (modal dialogs: "focus is set within the dialog"), [F85](https://www.w3.org/WAI/WCAG22/Techniques/failures/F85) |
| R2 | When it closes, focus returns to the control that opened it | iOS: Focus Management ("back to the trigger button when it's closed"), Understanding 2.4.3 ("focus returns to the button or the element following the button"), F85 |
| R3 | When the control that had focus is removed, focus goes to the control before or after it, or wherever is logical, never to the top of the screen | F85 (its note on a list of tags, each with a delete button) |
| R4 | Both keyboard focus and screen reader focus follow these moves | iOS: Focus Management (VoiceOver focus; Full Keyboard Access is a separate case it names) |
| R5 | Taking focus does not change the context; a control acts when it is activated | [Understanding 3.2.1](https://www.w3.org/WAI/WCAG22/Understanding/on-focus.html), G107 ("activate" rather than "focus" as a trigger) |

The reference repositories have one document for this entry, the iOS one;
the Android View and Android Compose references have none. It also names
the modal trait (VoiceOver kept in the dialog), the escape gesture, and
the content behind a dialog; those are left to C08, C09, and I08 (section
8).

Flutter references for the mechanisms used:

- [Understanding Flutter's keyboard focus system](https://docs.flutter.dev/ui/interactivity/focus)
- [`Route.requestFocus`](https://api.flutter.dev/flutter/widgets/Route/requestFocus.html), [`showDialog`](https://api.flutter.dev/flutter/material/showDialog.html), [`showCupertinoModalPopup`](https://api.flutter.dev/flutter/cupertino/showCupertinoModalPopup.html), [`showGeneralDialog`](https://api.flutter.dev/flutter/widgets/showGeneralDialog.html)
- [`FocusNode.requestFocus`](https://api.flutter.dev/flutter/widgets/FocusNode/requestFocus.html), [`autofocus`](https://api.flutter.dev/flutter/widgets/Focus/autofocus.html)
- [`FocusSemanticEvent`](https://api.flutter.dev/flutter/semantics/FocusSemanticEvent-class.html), the SDK's one way to ask for a screen reader's focus, documented for Android and iOS only

Comparison bar: the HTML `<dialog>` element opened with `showModal()`.
The HTML standard records the element that had focus as the dialog's
"previously focused element", runs the dialog focusing steps to move
focus into it, and when a modal dialog closes runs the focusing steps for
that element again
([HTML: the dialog element](https://html.spec.whatwg.org/multipage/interactive-elements.html#the-dialog-element)).
Where focus goes when the element that opened the dialog has gone is
left to the page, as F85's note says. Radix's Dialog primitive has
`onOpenAutoFocus` and `onCloseAutoFocus` events for the focus it moves
when it opens and closes
([Radix: Dialog](https://www.radix-ui.com/primitives/docs/components/dialog)).

## 5. Examples

Every example is the same list: "Saved trails", three buttons, Remove
Ridge trail, Remove Lake loop, and Remove Summit path, and the number
left ("Saved: 3"). Each Remove button asks first, "Remove Lake loop?",
with Cancel and Remove. Cancel keeps the trail; Remove removes it, and
its button with it. This is the case in F85's note: the control that
opened the dialog can be gone when it closes.

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-material` | Material | The question in an `AlertDialog`; after a removal, focus on the next trail's button | `showDialog`: the route takes focus when it opens and the screen gives it back to the button when it closes; `FocusNode.requestFocus` on the next button after a removal, and a `FocusSemanticEvent` to it a second later, once the framework has made its own request ([FL-442](../flutter-limitations.md#fl-442)) | R1 to R5 |
| `good-cupertino` | Cupertino | The same in a `CupertinoActionSheet`, the Cupertino way to confirm a removal | `showCupertinoModalPopup`, the same `requestFocus` and event; Enter added on the web where the Cupertino controls handle Space only ([FL-002](../flutter-limitations.md#fl-002)) | R1 to R5 |
| `good-widgets` | Widgets layer | The question drawn by hand in a general dialog, with focus put on Cancel when it opens | `showGeneralDialog`, `autofocus` on Cancel, the same `requestFocus` and event | R1 to R5 |

A `CupertinoAlertDialog` is not used: its actions take no keyboard focus
([FL-440](../flutter-limitations.md#fl-440)), so a keyboard user cannot
answer it at all.

### Bad

| Slug | Defect | Violates | Fails |
| --- | --- | --- | --- |
| `bad-focus-left-behind` | `good-material` with `requestFocus: false` on the dialog route. Focus stays on Remove Lake loop behind the dialog; Tab goes to Remove Summit path behind it, then to the dialog; and Cancel leaves focus on no control, so the next Tab starts again at Back | R1, R2 | 2.4.3 (F85) |
| `bad-opens-on-focus` | `good-material` with the question opened from each Remove button's `onFocusChange`. Tab onto a Remove button opens the question at once and moves focus into it | R5 | 3.2.1 |

Not built:

- A dialog made from an `OverlayEntry` or a `Stack` with no route, the
  "custom dialog" of the iOS reference. In the probe (fixture `p9`) it
  took no focus, came after every control of the screen in the Tab order,
  and dropped focus to the top of the screen when its button was removed;
  TalkBack did not move into it at all. It fails like
  `bad-focus-left-behind`, and it also lacks everything a route gives a
  dialog (the barrier, the content behind it hidden from screen readers),
  which is C08's subject. A route is the way to build a dialog in Flutter;
  `good-widgets` shows the one for a dialog drawn by hand.
- A bad example in which nothing is done after a removal. With the
  keyboard Flutter gives focus back to the control that had it before, so
  after Tab to a button and Remove, focus is on the button above it: not a
  failure, by F85's own note. What it does to a screen reader depends on
  the platform and on how the button was reached (section 7), so its
  defect cannot be stated once. The good examples place focus themselves,
  and the widget tests show the SDK's own behaviour.

## 6. Assertions by layer

Every check that nothing was asked reads the screen once and needs the
example's list in that same read, so an empty read cannot pass, and its
positive control finds the question through the same read and test.
Every keyboard stop is named, never counted: by the node whose semantics
say it has focus (widget tests, Android), by `document.activeElement`
(web), or by what Space does there (iOS, where XCUITest cannot see focus).
A stop that is behind the question, and so out of the accessibility tree,
is named by what Enter or Space does there: it opens a second question,
about that trail.

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Good: guidelines in light and dark, with and without the question open; 200% text at 320 by 640 with the question open. Every example: three named Remove buttons, not focused, and "Saved: 3"; a tap asks and Remove removes. 3.2.1: Tab onto each Remove button asks nothing, and Enter asks (the positive control); in `bad-opens-on-focus` the Tab onto Remove Ridge trail alone asks, after a Tab onto Back that did not, and focus coming back from Cancel does not ask again. 2.4.3: Enter on Remove Lake loop puts focus in the question (the route's scope, then the first control; Cancel itself in `good-widgets`); Cancel puts it back on Remove Lake loop and Tab goes on to Remove Summit path; Remove puts it on Remove Summit path, and on the button before when the last trail goes. `bad-focus-left-behind`: focus stays on Remove Lake loop's node, the next Tab goes to Remove Summit path's, then Cancel; after Cancel focus is on the screen and on no control, and Tab goes to Back. The screen reader, as far as a widget test can see it: on Android and iOS, after Cancel the framework sends the platform a request to put the screen reader's focus on Remove Lake loop; after Remove, that request, for a button that is gone, and then the example's own for Remove Summit path; and, in the same launch as a removal whose request is sent, a request still to come that is not sent when keyboard focus has moved on before it is due. The SDK alone: a `CupertinoAlertDialog`'s actions take no focus (FL-440); a removed control hands focus to the control focused before it, past its neighbour; a `CupertinoActionSheetAction` has no action for the web's Enter (FL-002) and `good-cupertino`'s do; an action sheet's own text colours fail the contrast check (FL-441) |
| L3 web | The same keyboard stops from `document.activeElement`; where the DOM focus is when each question opens (the dialog's title, nothing for the action sheet, Cancel for the general dialog); a stop behind the question named by Enter; focus put on an element and a click, as VoiceOver gives them, bring focus back to Remove Lake loop and on to Remove Summit path; in `bad-opens-on-focus` DOM focus alone asks |
| L3 Android | Names, class, and count; the same keyboard stops by `isFocused`, with Shift+Tab after a removal; a stop behind the question named by Enter |
| L3 iOS | Labels, type, and count; every stop named by what Space does |
| L4 TalkBack | TalkBack activates Remove Lake loop, then Cancel, then Remove Lake loop and Remove; after each the test reads where TalkBack's own focus went (`isAccessibilityFocused`): into the question, back to Remove Lake loop, on to Remove Summit path, and it must stay there for the last two seconds of a ten-second window, so that a later move cannot be missed; and what TalkBack said is recorded. In `good-material`, Ridge trail is then removed and Shift+Tab moves keyboard focus to Back before the example's request is due: TalkBack must not end on Remove Summit path. In `bad-opens-on-focus` TalkBack's focus on a Remove button asks nothing, and the click action then asks, both seen through one read of the app's window that must hold the list |
| L4 VoiceOver iOS | The same with VoiceOver's own double tap; where the cursor is is read three seconds after the speech, by one move back and one forward again |
| L4 VoiceOver web | The same with VoiceOver's own activation |

## 7. What the build found (Flutter 3.47.5)

The probe that came first is in
[evidence/probes/i03](../evidence/probes/i03/README.md), with the raw
output of each platform. Each finding says whether keyboard focus or a
screen reader's focus was measured.

- **A dialog route moves keyboard focus in and back by itself**
  (keyboard; widget test, web, Android, iOS). `showDialog`,
  `showCupertinoModalPopup`, `showModalBottomSheet`, and
  `showGeneralDialog` put focus on the new route's own scope, so the next
  Tab is the route's first control; `autofocus` puts it on a control at
  once. When the route closes, the screen under it takes focus back, and
  its scope remembers the control that had it (read in the source:
  `ModalRoute`, `FocusScopeNode.setFirstFocus`). The next Tab goes on from
  there.
- **A dialog route moves the screen reader in and back on Android and
  iOS** (TalkBack; VoiceOver on iOS). Both went to the dialog's title
  when it opened, and back to the button when it closed. The way back is
  the framework's: the Navigator records the node the screen reader is on
  (the engine's `didGainFocus` message) and, when a route closes, sends a
  `FocusSemanticEvent` for that node, on Android 300 ms after the route
  has gone (read in the source: `widgets/navigator.dart`,
  `_RouteEntry.handleDidPopNext`; the request is asserted in the widget
  tests). It is the screen reader's own last position that comes back:
  on iOS, with the keyboard opening and closing a dialog, VoiceOver went
  back to where it had been, not to the button the keyboard used. What
  they said (the transcripts): when the question opened TalkBack read the
  route's name ("Alert"; nothing for the general dialog, which has none)
  and the title, and when it closed the screen's title and then the
  button; VoiceOver on iOS read the title, then the button.
- **On the web the screen reader follows DOM focus, and DOM focus follows
  Flutter's keyboard focus** (VoiceOver in Chromium). There is no
  separate request: the Navigator sends none on the web. When a dialog with
  no `autofocus` opened, the web engine put DOM focus on its title, since no node asked
  for it (`SemanticRouteBase._setDefaultFocus`, read in the source), and
  VoiceOver read the dialog; for the action sheet it put it nowhere and
  VoiceOver moved onto the sheet as a whole; for a bottom sheet, onto its
  barrier, "Scrim" (C10). When the dialog closed, DOM focus came back to
  the button with Flutter's focus, and VoiceOver with it. After a removal
  it went to the next button with keyboard focus; in `good-widgets` it
  read the top of the page first (transcript).
- **When the control with focus is removed, Flutter gives keyboard focus
  to the control focused before it in the same screen**, not to a
  neighbour (keyboard; widget test, web, Android; read in the source:
  `FocusAttachment.detach`). After Tab to a button, that is the button
  above it. When nothing was focused before it, as on the web when
  VoiceOver's cursor put focus on the button directly, focus goes to the
  screen itself and the next Tab starts at Back. The widget test "a
  removed focused control hands focus to the one focused before it"
  shows it skip a neighbour. A screen reader whose focus was on the
  removed control went to the top of the screen: TalkBack to Back
  (Android), VoiceOver to Back (iOS), VoiceOver to the top of the page
  (web).
- **`FocusNode.requestFocus` moves the screen reader too on Android and
  the web, and not on iOS** (TalkBack; VoiceOver in Chromium; VoiceOver
  on iOS). TalkBack followed it (TYPE_VIEW_FOCUSED, read in the engine
  source), and on the web DOM focus did; with the keyboard driving and
  TalkBack on, TalkBack followed keyboard focus to every control.
  VoiceOver on iOS did not follow it, nor Tab. On iOS the screen reader
  is moved with a `FocusSemanticEvent`, which did move VoiceOver to the
  next row after a removal (probe rows u, s3, s4); in one fixture, `p12`,
  it did not, which was not looked into. The iOS reference, too, moves
  VoiceOver with a mechanism of its own, `accessibilityFocused`, apart
  from keyboard focus.
- **After a removal confirmed in a dialog, the framework's own request
  can win on Android** ([FL-442](../flutter-limitations.md#fl-442);
  TalkBack). In the probe, when TalkBack activated Remove in the dialog,
  and the row was removed and the next row given focus at once, TalkBack
  ended on Back (round 3) or on the row above (round 2), not on the next
  row: the Navigator's request for the removed button came after the
  app's move. Without a dialog the same `requestFocus` took TalkBack to
  the next row (probe row t). In the I03 examples it did not happen: with
  the examples' own request removed, or sent after 250 ms, TalkBack still
  ended and stayed on the next button (mutation runs m1 to m3,
  [evidence/probes/i03/mutations](../evidence/probes/i03/mutations/README.md));
  what makes the difference was not found. Waiting until the route had gone before moving focus,
  or sending a `FocusSemanticEvent` to the next row a second later, put
  TalkBack on the next row. On iOS VoiceOver went to Back after
  `requestFocus` with or without a dialog, and to the next row with the
  event a second later; whether an event sent sooner would be undone by
  the framework's request was not measured there. The good examples
  move keyboard focus at once and send the event a second later; on the
  web the event does nothing and VoiceOver follows the keyboard focus at
  once. The delay is a timing workaround (FL-442 says what it waits for):
  the event is dropped when a new question opens, the trail has gone, or
  keyboard focus has left the button, so a user who has gone on is not
  pulled back; a screen reader's own swipe in that second cannot be told
  apart from the framework's move, and is not guarded against.
- **`requestFocus: false` leaves keyboard focus behind the dialog, and
  loses it on the way back** (keyboard; the I03 tests on every layer,
  and the probe in a widget test, on the web, and on Android).
  The first Tab goes to the next control behind the dialog, and reaching
  the dialog takes Tab past the screen's last control, which clears the
  screen's record of its focus (read in the source:
  `TraversalEdgeBehavior.parentScope` in `FocusTraversalPolicy`, which
  calls `unfocus()`), so after Cancel focus is on no control. A screen
  reader is not affected: TalkBack went into the dialog, and on the web
  the engine put DOM focus on the dialog's title, with Flutter's focus
  still behind it.
- **`onFocusChange` that opens a dialog fires for keyboard focus only**
  (keyboard; TalkBack; VoiceOver on iOS; VoiceOver in Chromium). Tab onto
  the button opened it on every platform. TalkBack's focus and
  VoiceOver's cursor on iOS do not move keyboard focus, and it did not
  open. On the web VoiceOver's cursor gives the element DOM focus, which
  gives the button Flutter's focus, and it opened.
- **A `CupertinoAlertDialog` cannot be answered from the keyboard**
  ([FL-440](../flutter-limitations.md#fl-440)), and a
  `CupertinoActionSheet` can: `good-cupertino` uses the sheet. Its title
  and message fail the text contrast check with their own colours
  ([FL-441](../flutter-limitations.md#fl-441)), so the example sets them.
  On the web Enter does not activate its actions, as for
  `CupertinoButton` ([FL-002](../flutter-limitations.md#fl-002)).
- **A dialog made without a route** (`OverlayEntry`, probe `p9`) took no
  focus and came last in the Tab order; TalkBack and VoiceOver on the web
  stayed on the button; closing it dropped keyboard focus to the screen
  and TalkBack to Back. This is the iOS reference's custom dialog; in
  Flutter a route does the work, so it is not an example (section 5).
- **The probe on iOS** matched the other platforms for keyboard focus
  in every fixture, with Tab, Enter typed as "\n", and Shift+Tab from
  XCUITest, read from the probe's own status line (XCUITest cannot see
  focus). VoiceOver went into each route and back, stayed put for a panel
  without a route, and went to Back when the control under it was
  removed. A pushed `CupertinoPageRoute` put VoiceOver on an element read
  only as "Button" before Back (probe `p7`); left to I15.

**Not done yet.** Full Keyboard Access on iOS; VoiceOver in WebKit;
Switch Access and Switch Control; a screen reader moving with its own
gestures into a dialog that does not take its focus (the walks put it on
each control); what each screen reader says when a route opens, beyond
that it moved (I12); removing the last trail with a screen reader; and
the route announcements on Android (`setAccessibilityPaneTitle`).

## 8. What is handed on

- **C08 Modal dialog** (wave 7): what makes a dialog modal, which the
  iOS reference also asks for: the role and name (`AlertDialog` is
  `role="alertdialog"` with `aria-modal="true"` on the web, probe
  `web.txt`), the content behind it out of reach (a route's barrier
  takes it out of the semantics tree, so the page's elements leave the
  document; probe `web.txt`), and a dialog made from an `OverlayEntry`,
  which gets none of this (fixture `p9`). Also where Tab goes past a
  dialog's last control: `showDialog` keeps it in the dialog on every
  platform (`TraversalEdgeBehavior.closedLoop`, read in the source); a
  general dialog, an action sheet, and a bottom sheet use the
  Navigator's default, which on the web lets Tab leave the page and come
  back to the dialog (probe `web_round2.txt`). And `requestFocus: false`
  on a route, which `bad-focus-left-behind` shows.
- **C09 Alert and confirmation dialog**: which control a confirmation
  puts focus on first (`good-widgets` puts it on Cancel, the choice that
  loses nothing); [FL-440](../flutter-limitations.md#fl-440), a
  `CupertinoAlertDialog` that the keyboard cannot answer.
- **C10 Bottom sheet**: on the web a bottom sheet and an action sheet
  leave DOM focus on the Flutter view when they open (probe `web.txt`,
  fixtures `p3` and `p6`), where a dialog puts it on its title.
- **I08 Dismiss and escape**: Escape did not close a
  `CupertinoAlertDialog` in the widget test or on the web (FL-440), and
  the iOS reference's escape gesture.
- **I12 Announcements**: what a screen reader says when a route opens or
  closes, as opposed to where its focus goes.
- **F06 Error identification**: moving focus to the field in error is
  the same `FocusNode.requestFocus` as here, and needs the same check of
  where the screen reader goes.
- **I15 Navigation structure** and page routes: a pushed page put focus
  on its own scope and Tab then on Back; going back put it on the button
  that pushed it (fixtures `p4` and `p7`).
- **V14 Focus indicators**: whether focus moved from code shows a ring;
  not checked here.
