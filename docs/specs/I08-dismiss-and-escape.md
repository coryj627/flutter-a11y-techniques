# Spec: I08 Dismiss and escape

Status: Draft 1 (2026-11-19), written with the build. Fifth technique of
batch 5, focus and keyboard ([plan](../plan.md)), built in wave 4. Flutter
pin: 3.47.5.

This spec covers getting out: what closes something shown over the screen
for a while (a dialog, a sheet, a menu, a popup, a tooltip, or layers drawn
by hand), from the keyboard, with Android's Back, and with a screen
reader's own dismiss command; what a barrier that cannot be dismissed
leaves keyboard and screen reader users with; and a part of the screen
that keeps Tab inside it, with and without a way out. Left to others:

| Left out | Owner |
| --- | --- |
| Where focus goes when something opens or closes | [I03 Focus management](I03-focus-management.md) |
| The order Tab and Shift+Tab move in | [I02 Keyboard focus order](I02-focus-order.md) |
| Keys and shortcuts in general, and the default intents | I04 Keyboard actions and shortcuts |
| What makes a dialog modal: its role and name, and the content behind it out of reach | C08 Modal dialog |
| Confirmation and alert dialogs, and which button has focus first | C09 Alert and confirmation dialog |
| The bottom sheet as a component (drag handle, height, scrim) | C10 Bottom sheet |
| Popovers, tooltips, and menus as components (1.4.13 for tooltips) | C11 Popover, C12 Tooltip, C14 Menu and menu button |
| Snack bars and how long they stay | C13 Snackbar and transient messages |
| How focus looks | V14 Focus indicators |

## 1. Rule

Anything shown over the screen for a while can be closed from the keyboard
with Escape, and with each platform's own way back: Android's Back, the
screen reader's dismiss command. A part of the screen that keeps Tab inside
it always has a way out from the keyboard; if that way is not Escape, Tab,
or the arrow keys, the user is told what it is.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies | Applies; Escape measured on iOS 27.0 only, the escape gesture not verified | Applies |

Keyboard: a hardware keyboard on Android and iOS, the browser's on the
web. Android's Back: the Back key, the global Back action that TalkBack's
Back gesture calls, and a hardware keyboard's Back, Meta+Escape or
Meta+Left (section 3). Screen readers: TalkBack (its Back gesture
and its Dismiss action), VoiceOver on iOS (its two-finger scrub, the
escape gesture), VoiceOver on macOS in Chromium (Escape on the keyboard;
it has no gesture of its own for this). VoiceOver's escape gesture on iOS
cannot be made from XCUITest (section 7), so what it does is read in the
engine's source and checked in the widget tests through the messages it
sends, and not verified on a device. On the iOS simulator the Escape key
typed from XCUITest never reached Flutter; Command+period, which arrives
as Escape on iOS 27.0, is what the iOS tests send, on iOS 27 and later
only (section 7).

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [2.1.2 No Keyboard Trap](https://www.w3.org/TR/WCAG22/#no-keyboard-trap) | Every example's layers take keyboard focus and keep Tab inside them while they are shown; focus must be able to leave them from the keyboard |

2.1.2, as written: if keyboard focus can be moved to a component with a
keyboard interface, focus can be moved away from it with only a keyboard
interface, and if that takes more than unmodified arrow or Tab keys or
other standard exit methods, the user is told how.
[Understanding 2.1.2](https://www.w3.org/WAI/WCAG22/Understanding/no-keyboard-trap.html)
says that keeping focus in a modal dialog is not a trap as long as the
user can leave it, that Escape is the usual standard exit method with a
keyboard, and gives as its example a modal dialog that keeps Tab inside it
and is closed by its buttons or by Escape. A modal with a standard way out
is not a trap; the three good examples are that. On the web Escape can be
taken first by a tooltip that counts as open
([FL-484](../flutter-limitations.md#fl-484)): seen in probes only, in
all three, for the first Escape pressed within about 400 ms of the
layers being opened while the mouse rests on Back, and, with Chromium's CPU
throttled, for every Escape after a tooltip was left open under the
pushed screen. No criterion is claimed failed for it (the entry says
why).

Android has a keyboard way out of its own. Its system shortcuts turn
Meta+Escape and Meta+Left on a hardware keyboard into Back (AOSP's
`InputGestureManager`, in the `android16-release` and `main` sources;
`main` also lists Meta+Backspace), before the app sees the keys. On the
API 37 emulator both chords acted as Back, and Meta+Backspace did not
(probe `android_round4.txt`). Back closes a route whether its barrier can
be dismissed or not, and closes layers in the overlay when the screen has
a `PopScope` that closes them (section 7). The Understanding document
leaves "standard exit methods" to the platform; Back from the keyboard is
Android's, so it counts on Android. On iOS no such shortcut was
found: on iOS 27.0, Command+[ reached Flutter as itself and did nothing
(probe `ios_round3.txt`); Full Keyboard Access was not tried.

The web has one too: the browser's Back, whose keyboard shortcuts are
Alt+Left and, on a Mac, Command+[. The history event it makes reaches
Flutter as `popRoute`, the same as Android's Back (read in the source:
`SingleEntryBrowserHistory.onPopState` in the web engine). Measured as
that event, through Playwright's `page.goBack()`: it closed the layers of
every example but `bad-back-leaves`, with the count up by one, DOM focus
back on Map layers, and the example's screen still there (probe
`web_back.txt`; asserted in `web_tests/i08_dismiss_and_escape.spec.js`).
The shortcuts themselves could not be sent: Playwright's keys go to the
page, not to the browser's own shortcuts, and neither chord went back. So
on the web the key is not measured, only the event it makes; the verdicts
below take the browser's Back as the web's standard way back, by the same
reasoning as Android's, and say so.

How the bad examples fail, as the criterion is written. The iOS verdicts
rest on what was measured on the iOS 27.0 simulator, with Escape sent as
Command+period (`ios_round3.txt`, `ios_suite_x3.txt`). On earlier iOS,
Escape is not verified: on CI's iOS 26.5 Command+period did not arrive as
Escape every time (section 7), so nothing was measured there, which is
not the same as the layers staying open; the Escape checks are skipped
before iOS 27. Tab and Shift+Tab going round the two switches was
measured on both iOS 27.0 and CI's iOS 26.5. That no other key gets out
rests on the probe on iOS 27.0 (Command+[ reached Flutter as itself and
did nothing); other shortcuts and Full Keyboard Access were not tried.

- `bad-no-escape` fails 2.1.2 on iOS (measured on iOS 27.0; earlier iOS
  not verified). Enter on Map layers moves
  keyboard focus into the layers; there Tab and Shift+Tab go round the two
  switches, Escape does nothing, and no other key closes the layers or
  moves focus out of them. Nothing on the screen says how to leave. On
  Android it does not fail as written: the keyboard's Back (Meta+Escape)
  closes the layers through the screen's `PopScope`. On the web it does
  not either, with the caveat above: the browser's Back closes them
  through the same `PopScope` (measured as the history event, not as the
  key). What goes wrong on those two is that Escape, the key the good
  examples answer, does nothing, and nothing says the way out is the
  platform's Back; no criterion is claimed for that.
- `bad-not-dismissible` fails 2.1.2 on iOS (measured on iOS 27.0; earlier
  iOS not verified): the same, in a bottom
  sheet that cannot be dismissed. On Android the keyboard's Back closes
  it, as Back closes any route; what goes wrong there is the same as in
  `bad-no-escape`. On the web it does not fail as written: the browser's
  Back closes it (the history event, as above), and Tab past the last
  switch also leaves the page for the browser's own controls, which moves
  focus away from the sheet (the next Tab comes back to it).
- `bad-back-leaves` fails nothing: Escape closes its layers. Its defect is
  for Android's Back, in every form: the Back key, TalkBack's Back
  gesture, and the keyboard's Meta+Escape and Meta+Left all take the user
  off the screen with the layers open; and on the web the browser's Back
  does the same (the history event). Leaving the screen moves focus
  away, so it is not a trap. The iOS reference's own bad example, a
  dialog with no escape action, has no WCAG criterion either ("N/A" in its
  document).

The navigation bar's Back and the screen readers' gestures are not a
keyboard interface, so a surface that ignores them fails no criterion as
written; the reference repository and the HTML standard (section 4) treat
them as the same request as Escape.

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | Escape closes a dialog or other surface shown over the screen | [APG: Dialog (Modal)](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/) (keyboard interaction: "Escape: Closes the dialog"), [Understanding 2.1.2](https://www.w3.org/WAI/WCAG22/Understanding/no-keyboard-trap.html) (Escape as the standard exit method; the modal dialog example) |
| R2 | A screen reader's escape gesture closes a custom dialog or view, as it does a native one | [iOS: Escape Action](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/EscapeAction.md) (`.accessibilityAction(.escape)` on a custom dialog; the two-finger Z) |
| R3 | Android's Back, a screen reader's dismiss gesture, and Escape are the same request to close what is shown | [HTML: close requests](https://html.spec.whatwg.org/multipage/interaction.html#close-requests) (Esc on desktop, the back button or gesture on Android, VoiceOver's two-finger scrub "z") |
| R4 | A part of the page that keeps Tab inside it can be left from the keyboard, by a standard exit or a method the user is told | [WCAG 2.2: 2.1.2](https://www.w3.org/TR/WCAG22/#no-keyboard-trap), [G21](https://www.w3.org/WAI/WCAG22/Techniques/general/G21) |
| R5 | While a modal is open, Tab and Shift+Tab stay in it | APG: Dialog (Modal) (Tab and Shift+Tab wrap inside the dialog) |

The reference repositories have one document for this entry, the iOS one;
the Android View and Android Compose references have none. Its good
example closes a custom dialog on the escape gesture and returns focus to
the button that opened it; returning focus is I03's.

Flutter references for the mechanisms used:

- [`DismissIntent`](https://api.flutter.dev/flutter/widgets/DismissIntent-class.html), mapped to Escape by [`WidgetsApp.defaultShortcuts`](https://api.flutter.dev/flutter/widgets/WidgetsApp/defaultShortcuts.html); [`Actions`](https://api.flutter.dev/flutter/widgets/Actions-class.html)
- [`ModalRoute.barrierDismissible`](https://api.flutter.dev/flutter/widgets/ModalRoute/barrierDismissible.html), [`showModalBottomSheet`](https://api.flutter.dev/flutter/material/showModalBottomSheet.html) (`isDismissible`), [`showCupertinoModalPopup`](https://api.flutter.dev/flutter/cupertino/showCupertinoModalPopup.html) (`semanticsDismissible`)
- [`PopScope`](https://api.flutter.dev/flutter/widgets/PopScope-class.html), [`SemanticsProperties.onDismiss`](https://api.flutter.dev/flutter/semantics/SemanticsProperties/onDismiss.html), [`ModalBarrier`](https://api.flutter.dev/flutter/widgets/ModalBarrier-class.html), [`OverlayEntry`](https://api.flutter.dev/flutter/widgets/OverlayEntry-class.html)
- [`TraversalEdgeBehavior`](https://api.flutter.dev/flutter/widgets/TraversalEdgeBehavior.html), [`FocusScopeNode`](https://api.flutter.dev/flutter/widgets/FocusScopeNode-class.html)

Comparison bar: the HTML `<dialog>` element opened with `showModal()`,
and the `popover` attribute. The HTML standard sends both a close request
on Escape, Android's back button, and VoiceOver's escape gesture, and a
page can cancel it (the `cancel` event) but not stop the user from leaving
the dialog by default
([HTML: close requests](https://html.spec.whatwg.org/multipage/interaction.html#close-requests)).
Radix's Dialog closes on Esc and moves focus to its trigger, and has an
`onEscapeKeyDown` handler for the key
([Radix: Dialog](https://www.radix-ui.com/primitives/docs/components/dialog)).
In Flutter Escape, Back, and the escape gesture reach the app by three
different paths (section 7), and each has to be handled.

## 5. Examples

Every example is the same screen: a trail map with a button, Map layers,
that shows the map's layers over the screen, two switches (Contour lines,
on, and Campsites, off), a line saying which layers are shown, and a count
of the times the layers have been closed ("Closed: 0"), so that a test can
see that a key or a gesture closed them. The layers have no Close button:
like a menu or a popover they close on Escape, on a tap outside them, or on
the platform's way back. While they are shown, keyboard focus is in them
and Tab goes round the two switches in every example; the examples differ
only in what lets the user out.

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-material` | Material | A modal bottom sheet that can be dismissed | `showModalBottomSheet`: its route closes on Escape because `isDismissible` is true (the default); on Back and on the escape gesture, which pop the route on top; and through its barrier's dismiss action | R1 to R5 |
| `good-cupertino` | Cupertino | A Cupertino modal popup whose barrier a screen reader can use | `showCupertinoModalPopup` with `barrierDismissible` (true by default) and `semanticsDismissible: true` | R1 to R5 |
| `good-widgets` | Widgets layer | The layers drawn by hand in the app's overlay, with no route | An `OverlayEntry` with a `ModalBarrier`; a `FocusScopeNode` with `TraversalEdgeBehavior.closedLoop`; an `Actions` for `DismissIntent` around the layers; `Semantics(onDismiss:)` on them; a `PopScope` on the screen that closes them on Back | R1 to R5 |

### Custom solutions

**Custom solution: not vetted by a real-world example.** `good-widgets` is a
custom solution. It is tested here in isolation, with screen-reader
transcripts, but has not been built into a real app and tested in a user
journey. Do not treat it as a vetted technique.

The table is this technique's part of the register of custom solutions,
[custom-solutions.md](../custom-solutions.md).

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-material` | Nothing: `showModalBottomSheet` | `showModalBottomSheet` | none | R1, R2, R3, R4, R5: APG: Dialog, Understanding 2.1.2, iOS: Escape Action, HTML: close requests, WCAG 2.2: 2.1.2, G21 | not custom |
| `good-cupertino` | Nothing: `showCupertinoModalPopup(semanticsDismissible: true)` | `showCupertinoModalPopup` | none | R1, R2, R3, R4, R5: APG: Dialog, Understanding 2.1.2, iOS: Escape Action, HTML: close requests, WCAG 2.2: 2.1.2, G21 | not custom |
| `good-widgets` | Dismissal for layers in an `OverlayEntry`: a `ModalBarrier`, a `FocusScopeNode` that keeps Tab in, an `Actions` for `DismissIntent`, `Semantics(onDismiss:)`, and a `PopScope` for Back | A route (`showModalBottomSheet`, `showDialog`); none for an overlay that is not a route | Nothing closes an overlay that is not a route ([FL-481](../flutter-limitations.md#fl-481)) | R1, R2, R3, R4, R5: APG: Dialog, Understanding 2.1.2, iOS: Escape Action, HTML: close requests, WCAG 2.2: 2.1.2, G21 | custom |

### Bad

| Slug | Defect | Violates | Fails |
| --- | --- | --- | --- |
| `bad-not-dismissible` | `good-material` with `isDismissible: false`. Escape does nothing, and Tab only goes round the two switches (on the web, out of the page and back): on iOS 27.0 no key closed the layers (earlier iOS not verified); on Android only the system's keyboard Back, Meta+Escape, and on the web the browser's Back, which nothing on the screen mentions | R1, R4 | 2.1.2 on iOS (measured on iOS 27.0, section 3) |
| `bad-no-escape` | `good-widgets` without its action for `DismissIntent`. Escape does nothing, and Tab and Shift+Tab only go round the two switches: on iOS 27.0 no key left the layers (earlier iOS not verified); on Android only the system's keyboard Back, Meta+Escape, and on the web only the browser's Back, which nothing on the screen mentions | R1, R4 | 2.1.2 on iOS (measured on iOS 27.0, section 3) |
| `bad-back-leaves` | `good-widgets` without its `PopScope`. On Android, Back (the Back key, TalkBack's Back gesture, or Meta+Escape on a keyboard), and the browser's Back on the web, take the user off the screen, with the layers still open, instead of closing them | R3 | — |

Not built:

- **A trap with a way out that is not standard, and is told.** The
  Understanding document's rich text editor, whose Tab indents and whose
  Alt+F10 leaves. Flutter's text fields do not take Tab, and nothing in
  the SDK needs Tab for itself; the probe's traps (section 7) show that
  Escape handled by the component is the way out, and `good-widgets`
  uses it. Telling the user is a sentence on the screen, not a mechanism.
- **A trap made by `Focus.onKeyEvent` or by a `FocusTraversalPolicy`.**
  Measured in the probe on every platform: they trap Tab and Shift+Tab
  exactly as `TraversalEdgeBehavior.closedLoop` does, and Escape gets out
  only where it is handled. The widget tests show all three; the examples
  use `closedLoop`, the SDK's own setting for it.
- **A `CupertinoAlertDialog` shown with `showCupertinoDialog`.** With the
  SDK's defaults it traps the keyboard on iOS: its actions take no focus
  ([FL-440](../flutter-limitations.md#fl-440), measured on the iOS
  simulator in I03) and its barrier cannot be dismissed, so Escape does
  nothing (the widget test, as iOS, and the source; Escape on it was not
  measured on an iOS device or simulator). On Android the keyboard's
  Back, Meta+Escape, closed it in the probe, and on the web Tab leaves the
  page. A good Cupertino dialog
  would need both fixed; `good-cupertino` uses a modal popup.
- **A tooltip.** Escape hides it on the pinned SDK, except on the web when
  the page has no keyboard focus
  ([FL-482](../flutter-limitations.md#fl-482)); a tooltip is C12's.

## 6. Assertions by layer

Where focus is, is read stop by stop: by the node whose semantics say it
has focus (widget tests, Android), by `document.activeElement` (web), or by
what Space does there (iOS, where XCUITest cannot see focus: it turns one
switch). Each test that says a key or a command does nothing sends it
alone, reads the layers and the stop again a second later, and shows in
the same launch that keys arrive (Space turns the switch the stop names);
for Escape, the same launch then goes to the good example the bad one is
made from (through the app's own screens; on iOS by its link, opened in
the app that is running), and the same key closes its
layers. The layers are identified by both switches, the example's screen
by its count, and the technique's own screen by its title (by its list of
examples in the widget tests).

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Good: guidelines in light and dark, with and without the layers shown; 200% text at 320 by 640 with them shown. Every example: Map layers is a button, the count is 0, "Showing: Contour lines"; the switches are named and Contour lines alone is on; Enter on Map layers puts keyboard focus in the layers (the route's scope, then the first switch on Tab, or the first switch at once) and Space turns it; Tab and Shift+Tab go round the two switches. Escape, as Android and as iOS: it closes the layers in the good examples and `bad-back-leaves`, the count goes to 1 and focus is back on Map layers; in `bad-not-dismissible` and `bad-no-escape` it is not handled, from either switch, the layers stay with focus where it was after a second, Space turns the switch, twenty Tabs and Shift+Tabs never leave the two, and the good example the bad one is made from then closes on the same key. `popRoute` (Back, and the escape gesture at the root): closes the layers on the example's screen in every example but `bad-back-leaves`, where, after Escape has closed them once in the same test, it takes the user to the technique's own screen. The dismiss action: which nodes have it ("Scrim", "Dismiss", "Close map layers", and the overlay's own node), and each one closes the layers; in `bad-not-dismissible` no node has it, and the same search finds `good-material`'s. Where VoiceOver's escape gesture on a switch is taken: by the layers' own node in the overlay examples, by no node in the route examples. The SDK on its own: `showDialog` with and without `barrierDismissible` (FL-480); an `OverlayPortal` that Escape does not close and `popRoute` pops the screen under, and an `OverlayEntry` that stays after it (FL-481); a trap made each of the three ways keeps Tab and Shift+Tab and lets no Escape out; a tooltip that Escape hides while focus is in the app and not after the view loses focus (FL-482); a `ModalBarrier` in an `OverlayPortal` that empties the semantics tree, and in an `OverlayEntry` that does not (FL-483) |
| L3 web | Every example: Map layers is a button with its name, the count, and each switch is `role="switch"` with its name and `aria-checked`; Enter shows the layers and Space turns a switch. Tab and Shift+Tab: round the two switches in the overlay examples; in the route examples round the two and out of the page for the browser's own stops, and back to the first switch. Escape: closes the layers, the count is 1 and DOM focus is on Map layers, in the good examples and `bad-back-leaves`; does nothing in the other two, from either switch, with the positive controls as above, where the mouse is first moved off the app bar and the good example is opened only once Back's tooltip has not been shown for half a second (FL-484); a failure of `expectShown` reports where DOM focus was and whether Back's tooltip was shown; in `bad-no-escape` twenty Tabs and Shift+Tabs never leave the switches. The browser's Back, as its history event (`page.goBack()`; its keyboard shortcuts cannot be sent from Playwright): from each switch, it closes the layers in every example but `bad-back-leaves` (both switches gone, the count at 1, DOM focus on Map layers, the URL still the example's), and in `bad-back-leaves` it brings back the technique's screen |
| L3 Android | The same parts by class (`Button`, `Switch`), name, and `isChecked`; Tab and Shift+Tab round the two switches by `isFocused`; Escape as on the web, with the positive controls; the Back key, the global Back action, and the keyboard's Back (Meta+Escape and Meta+Left, sent as key events) close the layers on the example's screen, keyboard focus back on Map layers, in every example but `bad-back-leaves`, where all four take the app to the technique's screen with the app still in front, after Escape has closed the layers in the same launch; `ACTION_DISMISS` on the barrier, and on the overlay's own node, closes the layers; in `bad-not-dismissible` the read that holds the layers has no node with it |
| L3 iOS | Map layers (a button) and the switches (`.switch`, named, values "1" and "0"); Tab and Shift+Tab round the two switches, each stop named by what Space turns; Escape, on iOS 27 and later (section 7), sent as Command+period once Space twice has shown keyboard focus on Contour lines, closes the layers in the good examples and `bad-back-leaves` (both switches gone, the count at 1), and Space then shows them again from Map layers; it does nothing in the other two, with the positive controls as above (the good example opened over the bad one by its link, in the same launch). Not asserted: the Escape key itself, which XCUITest cannot send to Flutter; Back, which iOS has no key for; the escape gesture |
| L4 TalkBack | Map layers, then, with the layers open, each switch (name, "Switch", and its state) and the barrier, by what TalkBack reads; then TalkBack's Back gesture (the global Back action) from a switch: the layers close and TalkBack's focus is on Map layers for the last two seconds of the window; in `bad-back-leaves` the app goes to the technique's screen and TalkBack is no longer on the example |
| L4 VoiceOver iOS | VoiceOver's cursor on Map layers and a double tap; what VoiceOver says, then each element forward until the barrier: both switches with "Switch button", and the barrier in every example but `bad-not-dismissible`, where neither "Scrim" nor "Dismiss" is read |
| L4 VoiceOver web | VoiceOver's own activation on Map layers shows the layers and VoiceOver speaks; Escape pressed through the system closes them in the good examples and `bad-back-leaves`, and leaves them in the other two, where VoiceOver's activation on the focused switch then turns it |

What the tests leave out, and what that gives up:

- In the web positive controls (`bad-not-dismissible` and
  `bad-no-escape`: "Escape does nothing, from either switch"), after the
  click on Back the mouse is moved off the app bar, and the good example
  is opened only once Back's tooltip has not been shown for half a
  second, waited for for at most ten seconds; Escape is still sent once.
  Without that, a tooltip still being hidden when the good example was
  pushed made Escape fail now and then on CI
  ([FL-484](../flutter-limitations.md#fl-484)). What it gives up: these
  tests no longer show Escape closing a good example while a tooltip
  counts as open; that state is recorded in the entry and the probe
  (`docs/evidence/probes/i08/README.md`, round 6), not tested. A tooltip
  left open under another screen is not in the page's tree, so the wait
  cannot see one; it removes the hover that leaves one.

## 7. What the build found (Flutter 3.47.5)

The probe that came first is in
[evidence/probes/i08](../evidence/probes/i08/README.md), with the raw
output of each platform.

- **Escape, Back, and a screen reader's dismiss command reach the app
  three ways**, and a route answers all three by itself. Escape becomes a
  `DismissIntent` through the app's default shortcuts and is handled
  where keyboard focus is; every `ModalRoute` has an action for it (read
  in the source: `widgets/routes.dart`). Android's Back key and the global
  Back action, which TalkBack's Back gesture calls, send `popRoute`, which
  the Navigator answers by popping the route on top; so does VoiceOver's
  escape gesture on iOS when no element on its way up has the dismiss
  action (read in the engine source). A screen reader's dismiss action
  (TalkBack's Dismiss action, `ACTION_DISMISS`; VoiceOver's escape gesture
  on an element that has it) goes to a semantics node; a route's barrier
  has it when it has a label. Measured in the probe on every platform that
  could send each one (the probe's table).
- **A route closes on Escape only when its barrier can be dismissed**
  ([FL-480](../flutter-limitations.md#fl-480)). `barrierDismissible:
  false` (`isDismissible: false` for a sheet) turns off Escape, and the
  barrier's dismiss action, but not Back: the Back key and the global Back
  action closed every route the probe opened on the Android emulator, and
  the keyboard's Meta+Escape and Meta+Left every one it was tried on; only
  `PopScope(canPop: false)` stopped them. So a sheet that cannot be
  dismissed leaves a keyboard user its buttons, if it has any, and on
  Android the keyboard's Back; and leaves a screen reader user Back and
  the escape gesture, but not TalkBack's Dismiss action. `showCupertinoDialog`,
  `showGeneralDialog`, and `showCupertinoSheet` are not dismissible by
  default; with a `CupertinoAlertDialog`, whose actions take no focus,
  that makes `showCupertinoDialog`'s defaults a keyboard trap on iOS
  ([FL-440](../flutter-limitations.md#fl-440)): concluded from FL-440,
  measured on the iOS simulator in I03, and from Escape on a barrier
  that cannot be dismissed (the widget test, as iOS); not measured as a
  whole on iOS.
- **On Android, Escape alone is not Back; Meta+Escape is.** An Escape
  that nothing in the app handled left the screen where it was (the
  probe's key log, `android.txt`). Meta+Escape and Meta+Left, sent as
  key events, acted as Back before the app saw them, on the probe screen
  with nothing open (it went back to Home) and on every fixture they were
  tried on (`android_round4.txt`); Meta+Backspace did nothing on this API
  37 emulator. So on Android a keyboard user always has Back; a surface
  that ignores Escape leaves them a way out they have to know, which
  nothing on the screen tells them.
- **Nothing closes an overlay with no route**
  ([FL-481](../flutter-limitations.md#fl-481)). An `OverlayEntry` or
  `OverlayPortal` ignores Escape, has no dismiss action, and Back pops the
  screen it was shown from; an `OverlayEntry` then stays over the screen
  before. `good-widgets` adds the three things: an `Actions` for
  `DismissIntent` around the layers, a `PopScope` on the screen whose
  `canPop` is false while they are shown, and `Semantics(onDismiss:)` on
  them, which TalkBack lists as its Dismiss action and VoiceOver's escape
  gesture made on any part of them performs (read in the source; the
  widget tests show the node is an ancestor of each switch).
- **A trap made any of the three ways is the same trap**
  (`Focus.onKeyEvent` that takes Tab, a `FocusTraversalPolicy` whose next
  and previous go round, or `TraversalEdgeBehavior.closedLoop`): Tab and
  Shift+Tab stayed in it on every platform, and Escape got out only where
  the trap handled it (probe fixtures t1 to t5; the widget tests). Which
  way a component keeps Tab in is not what makes it a trap; whether a key
  gets out is.
- **On the web, a route other than `showDialog` lets Tab leave the
  page**: past the last switch DOM focus goes to nothing of the page for
  two Tabs here (the browser's own stops), and then comes back to the
  first switch; the page behind the sheet is never reached. `showDialog`
  keeps Tab inside it (`TraversalEdgeBehavior.closedLoop`, read in the
  source). This is why `bad-not-dismissible` does not fail 2.1.2 on the
  web as the criterion is written (section 3), and why the overlay
  examples, whose scope is `closedLoop`, keep Tab in on the web too.
- **On the iOS simulator, the Escape key from XCUITest never reached
  Flutter**, with VoiceOver on or off, while Tab in the same launch did;
  Command+period, iOS's key for cancel, arrived as Escape and closed what
  Escape closes (probe `ios_round3.txt`). The iOS tests send Escape that
  way. Whether a hardware keyboard's Escape key reaches the app was not
  tried; neither was Full Keyboard Access.
- **On CI's simulator, iOS 26.5, Command+period did not arrive as Escape
  every time, so the iOS Escape checks run on iOS 27 only**
  (run 44502222902: GitHub's macOS runner, Xcode 26.6, an iPhone 17 Pro
  simulator with iOS 26.5; here, Xcode 27.1 and iOS 27.0). It closed them
  in `good-material` and `good-cupertino`, where it was sent after a Tab;
  it did not in `good-widgets`, where it was sent straight after Enter had
  shown the layers, nor in the positive control that opens
  `good-material` over a bad example and sent it straight after a tap.
  Whether that was timing (keyboard focus not yet in the layers) or
  Command+period not arriving as Escape on iOS 26.5 is not established:
  there is no iOS 26 simulator here, and CI's log has no key log. The
  tests now name the stop with Space twice, on Contour lines, before
  Escape is sent, and wait up to ten seconds for the closed state; three
  runs of the suite in a row passed here
  (`docs/evidence/probes/i08/ios_suite_x3.txt`). On CI's next run with
  that change (run 44580353546, the same runner, Xcode and iOS 26.5;
  `docs/evidence/probes/i08/ci_ios_26_5.txt`) Command+period closed the
  layers in `good-material`, `good-cupertino`, `good-widgets` and
  `bad-back-leaves`, and in `bad-not-dismissible` it left them shown from
  both switches. That run failed one check, the positive control's wait
  for `good-material` opened by its link: it waited ten seconds, and on
  that runner a screen opened by its link took up to 30 seconds to appear
  (in the next test, a fresh launch on `good-material`). The wait is now
  30 seconds, as for every other screen. On the next run, with only that
  wait changed (run 44595763702, attempt 2, the same runner and iOS 26.5;
  `docs/evidence/probes/i08/ci_ios_26_5_rerun.txt`), Command+period closed
  the layers in `good-material` and then not in `good-cupertino`, nor in
  the positive control's `good-material`, each time after Space twice had
  shown keyboard focus on Contour lines. So on iOS 26.5 Command+period
  does not arrive as Escape every time, and a check that fails there says
  nothing about the app: the two iOS tests that send Escape
  (`testEscapeClosesTheLayers`, `testEscapeDoesNothingInTheBadExamples`)
  run on iOS 27 and later and are skipped before it, as CI's are until
  its image has iOS 27. On iOS 27.0 here they passed in every run
  (`ios_suite_x3.txt`). Why Command+period is lost on iOS 26.5 was not
  found; there is no iOS 26 simulator here.
- **VoiceOver's escape gesture could not be made from a test**: neither
  `XCUIVoiceOverService` nor XCUITest has a two-finger scrub, and Escape
  typed with VoiceOver on did nothing (probe). What it does is read in the
  engine source (`accessibilityPerformEscape` in `SemanticsObject.mm` and
  `FlutterViewController.mm`) and asserted, as messages, in the widget
  tests; on a device it is not verified.
- **TalkBack** ([transcript](../evidence/I08/talkback-android.md)): it
  reads each switch with its state, its name, and "Switch"; the barrier as
  "Scrim", "Dismiss", or "Close map layers", with "Actions available"; and
  after its Back gesture the layers closed and TalkBack read Map layers,
  "Button" (after the screen's title, for the routes, as I03 found), and
  its focus stayed there. In `bad-back-leaves` the gesture left the
  screen: TalkBack read the technique's title, "Dismiss and escape", and
  Back. In the overlay examples TalkBack's focus followed keyboard focus
  into the layers, to Contour lines; VoiceOver on iOS went to the
  barrier, "Close map layers", the first element of the overlay
  ([transcript](../evidence/I08/voiceover-ios.md)), and in the routes to
  the title. When the overlay closes, keyboard focus is put back on Map
  layers, and TalkBack follows it; where VoiceOver on iOS goes then was
  not measured (it does not follow keyboard focus, I03), and is I03's
  subject.
- **A `ModalBarrier` in an `OverlayPortal` silences the screen in a
  widget test** ([FL-483](../flutter-limitations.md#fl-483)): the examples
  were first built that way; they use an `OverlayEntry`.
- **Tooltips**: Escape hides one on the pinned 3.47.5, on the web too,
  while keyboard focus is in the page; not while the page has no focus
  ([FL-482](../flutter-limitations.md#fl-482)). The plan's note that
  Escape on tooltips on the web needs 3.50 is right for that case only; on
  Android, one shown by the long-click action stayed after Escape.
- **On the web, an open tooltip can take Escape from the layers**
  ([FL-484](../flutter-limitations.md#fl-484)). `WidgetsApp` hides
  tooltips on Escape from a `Focus` of its own that a key reaches before
  the app's `Shortcuts` (read in the source; the order also seen in the
  probe's trace). In the probe (round 6) Escape failed to close the
  layers in two states. The first Escape, with the mouse resting on Back
  and its tooltip shown, sent with no added wait once focus was on
  Contour lines, unthrottled, as Linux: in 20 of 20 runs of
  `good-widgets` and of `good-material` (116 to 218 ms from Enter on Map
  layers), and in `good-cupertino` in the 11 runs with Escape at 383 ms
  or less and none of the 9 at 398 ms or more; with 400 ms or more
  between focus reaching Contour lines and Escape, `good-widgets` closed
  in 12 of 12. And every Escape on `good-widgets` after the technique
  screen's Back tooltip was
  left in the list of open tooltips under the pushed example, which
  happened only with Chromium's CPU throttled and Flutter seeing Linux
  (about 15% of runs at four times). That second state is the one the
  probe found behind the positive control's failures; the failures on CI
  had the same symptom, and their page state was not recorded. The
  positive controls now move the mouse off the app bar first (section 6).

**Not done yet.** Escape on iOS before 27 (on CI's iOS 26.5
Command+period did not arrive every time, so nothing was measured); the
hardware Escape key on iOS (the tests use Command+period); Full Keyboard Access; VoiceOver's escape gesture on a
device; a real Android keyboard (the tests use `input keyevent` and key events sent through `Instrumentation`), and Meta+Escape on other Android versions; Switch
Access and Switch Control; VoiceOver in WebKit; the browser's Back
shortcuts themselves (Alt+Left, Command+[), as opposed to the history
event they make, which is measured; a trap whose way out is not standard and
is told (section 5); and every component of the probe's table as an
example of its own, which are C08 to C14.

## 8. What is handed on

- **C08 Modal dialog**: FL-480 for dialogs, and that `showDialog` keeps
  Tab in while the other dialog routes let it leave the page on the web;
  what a dialog that cannot be dismissed leaves its users (section 7).
- **C09 Alert and confirmation dialog**: FL-440 with FL-480, a
  `showCupertinoDialog` that the keyboard can neither answer nor leave.
- **C10 Bottom sheet**: `isDismissible`, and the persistent sheet, which
  Back closes and Escape does not (probe `e7`).
- **C11 Popover and C14 Menu and menu button**: FL-481 for anything drawn
  in the overlay; a `MenuAnchor` closes on Escape only while focus is on
  its button or in it (probe `e8`).
- **C12 Tooltip**: FL-482, and the tooltip that stayed on Android after
  Escape.
- **C13 Snackbar**: Escape does not close one, Back pops the screen under
  it, and it has its own dismiss action (probe `e12`).
- **I03 Focus management**: where focus goes when hand-made layers open
  and close; `good-widgets` moves keyboard focus in and back itself, and
  does not move VoiceOver on iOS.
- **I15 Navigation structure**: Back on a screen, and the escape gesture
  that pops a page on iOS.
- **V14 Focus indicators**: not checked here.
