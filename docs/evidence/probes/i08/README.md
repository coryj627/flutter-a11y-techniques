# I08 probe: dismiss and escape

Run on 2026-11-19, Flutter 3.47.5, before the I08 examples were written.
The fixture is a second entry point and not part of the app
(`probe.dart.txt`, the source as it ran last). A status bar at the bottom
of the screen, outside the Navigator so that no barrier hides it, shows:

- `Open:` the fixtures open now, as each fixture's own code saw it open
  and close (a route's future completing, a sheet's `closed` future, an
  overlay's own close). The dropdown (`e21`) is not closed through its
  `onChanged`, so its `Open:` stays; read its `didPop` instead.
- `KF:` the node with Flutter's keyboard focus, named by the first text
  under it (`scope:...` for a scope with no focused child).
- `Log:` what happened: `e1 closed`, `popRoute` (a Back message reached
  the framework; logged by a `WidgetsBindingObserver` registered first,
  which handles nothing), `didPop ...` (a route the Navigator popped),
  and, from the second Android round on, `unhandled <key>` for every key
  that nothing in the app handled, logged by a `Focus` above the whole
  app.
- `Keys:` the last keys that reached the framework at all.

F1 to F5 put keyboard focus on the first button of trap t1 to t5, and F6
on "t0 before" (the probe's own keys, taken before any focus handler).

## Fixtures

Screen one (`/probe`), each a button that opens it:

| # | Fixture |
| --- | --- |
| e1 | `showDialog`, an `AlertDialog` with a Close button |
| e2 | the same, `barrierDismissible: false` |
| e3 | `showCupertinoDialog`, a `CupertinoAlertDialog` (barrier not dismissible by default) |
| e4 | the same, `barrierDismissible: true` |
| e5 | `showModalBottomSheet` with a Close button |
| e6 | the same, `isDismissible: false` |
| e7 | `Scaffold.showBottomSheet`, a persistent sheet |
| e8 | a `MenuAnchor` with two items |
| e9 | a `PopupMenuButton` |
| e10 | a `Tooltip` on a button |
| e11 | the `Scaffold`'s `Drawer` |
| e12 | a `SnackBar` with an action, 30 seconds |
| e13 | `showDatePicker` |
| e14 | an `OverlayEntry` inserted into the Navigator's overlay, focus put on its Close button |
| e15 | an `OverlayPortal`, the same |
| e16 | `showGeneralDialog`, `barrierDismissible: true` with a `barrierLabel` |
| e17 | `showGeneralDialog` with its defaults (not dismissible) |
| e18 | `showCupertinoModalPopup`, a `CupertinoActionSheet` |
| e19 | `showDialog` with a `PopScope(canPop: false)` in it |
| e20 | an `OverlayPortal` with an action for `DismissIntent`, `Semantics(onDismiss:)`, and a `PopScope` on the screen: the mechanism of I08 `good-widgets` |
| e21 | a `DropdownButton` |
| e22 | `showCupertinoSheet` |

Screen two (`/traps`): t0 before; t1, a `Focus.onKeyEvent` that takes Tab
and Shift+Tab and moves between its two buttons; t2, the same that also
takes Escape and moves focus to t9; t3, a `FocusTraversalGroup` with a
policy whose next and previous go round its own group; t4, a
`FocusScopeNode` with `TraversalEdgeBehavior.closedLoop`; t5, the same
with an action for `DismissIntent` around it that moves focus to t9; t9
after.

## How each platform was looked at

- Flutter test: `probe_test.dart.txt`, as Android and as iOS. For each
  fixture, in a fresh app each time: Escape; `handlePopRoute`, the message
  Android's Back sends (and VoiceOver's escape gesture, when it reaches
  the view controller: read in the engine source,
  `FlutterViewController.mm`); and the dismiss action on the last node
  that has it. Then the traps. Output: `flutter_test.txt`.
- Web: Chromium, Playwright (`probe_web.spec.js.txt`, served by
  `p08.config.js.txt` from a build of its own). Each fixture opened with a
  click and, separately, with DOM focus on its button and Enter; then
  Escape. The tooltip shown by hovering, with no element focused and with
  its button focused. Then the traps. Output: `web_round1.txt` (its
  "keys" rows put DOM focus on the identifier's own element and not on
  the button, FL-043, so they opened nothing) and `web_round2.txt` (the
  "keys" rows again, with the button found by its role and name; the
  tooltip; the dropdown counted by its items).
- Android: Pixel 10a emulator, Android 17, 1080 by 2424, no accessibility
  service on (`ProbeI08Test.kt.txt`, run by `android_probe.sh.txt`, which
  changes no setting). Each fixture opened with the click action, then,
  each in a launch of its own: Escape (`input keyevent KEYCODE_ESCAPE`),
  the Back key (`input keyevent KEYCODE_BACK`), the global Back action
  (`performGlobalAction(GLOBAL_ACTION_BACK)`, the call TalkBack's Back
  gesture makes), and the dismiss action on the last node that has one.
  `backControl` is the positive control for Back: with nothing open, Back
  popped the probe screen to Home, and Back again left the app. Output:
  `android_round1.txt` (most fixtures did not open: the click went to the
  identifier's own node, FL-043; the popup menu and the dropdown, found by
  name, opened, and Escape left them open; the status bar did not log
  keys yet, so whether Escape arrived there is not known) and
  `android.txt` (round 2: the button found by name, the key log, and ten
  fixtures), `android_round3.txt` and `android_round4.txt` (the other
  fixtures, and `keyboardBack`, the keyboard's Back chords; round 4 also
  reads the key log after each Escape and sends F10 after each chord, to
  see whether keys reach the app). The probe test as it ran last is
  `ProbeI08Test.kt.txt`; round 3 and 4 ran `android_probe3.sh.txt`, which
  also prints the API level.
- iOS: iPhone 17 simulator, iOS 27.0 (`I08ProbeUITests.swift.txt`, run by
  `ios_probe.sh.txt`). Each fixture opened with a tap, then Escape
  (`typeKey(XCUIKeyboardKey.escape)`). With VoiceOver on, through
  `XCUIVoiceOverService`: its cursor on the button, a double tap, and
  Escape typed. VoiceOver was turned off at the end of each fixture.
  Output: `ios.txt`; `ios_round2.txt` and `ios_round3.txt`, Escape typed
  in other ways, each after a Tab that the key log shows arriving (in
  round 2 `typeText` stopped the test: XCUITest types text only into an
  element with keyboard focus).

## What it showed

The same in the widget test, on the web (Escape only), and on the Android
emulator unless a line says otherwise. On Android:

- Escape was measured in round 2 only (`android.txt`: `e1`, `e2`, `e5`,
  `e6`, `e9`, `e10`, `e14`, `e18`, `e19`, `e20`, and `e21`). In rounds 3
  and 4 (`android_round3.txt`, `android_round4.txt`, the other fixtures)
  no key sent to the app reached Flutter at all: the probe's key log
  stayed empty, the F12 and F11 sent at each launch and the F10 sent after
  each keyboard Back included, so those rounds' Escape rows show only that
  the keys were lost, and the Escape column for `e3`, `e4`, `e7`, `e8`,
  `e11`, `e12`, `e13`, `e15`, `e16`, `e17`, and `e22` is the widget test's
  and the web's. Why the keys were lost was not found; the emulator is
  shared, and the I08 Android tests, run between rounds 2 and 3, had
  their keys arrive.
- Back (the Back key and the global Back action, which did the same in
  every fixture) and the dismiss action were measured for every fixture:
  round 2 for its list, rounds 3 and 4 for the rest. They do not go
  through the app's keys.
- The keyboard's Back, Meta+Escape and Meta+Left, in rounds 3 and 4 (see
  below).

"Back" is `popRoute` in the widget test. The dismiss action is the widget
test's and Android's; the web has none.

| Fixture | Escape | Back (`popRoute`) | Dismiss action |
| --- | --- | --- | --- |
| e1 dialog | closes | closes | on its barrier, "Dismiss": closes |
| e2 dialog, not dismissible | nothing | closes | no node has it |
| e3 Cupertino alert (not dismissible by default) | nothing | closes | no node has it |
| e4 Cupertino alert, dismissible | closes | closes | "Dismiss": closes |
| e5 modal bottom sheet | closes | closes | "Scrim": closes |
| e6 sheet, not dismissible | nothing | closes | no node has it |
| e7 persistent sheet | nothing | closes it (the sheet is a local history entry of the screen) | on the sheet itself: closes |
| e8 menu | closes when focus is on its button (web keyboard and click); with focus elsewhere, nothing (widget test, where a tap gives no focus) | the widget test: pops the screen and leaves the menu open | none |
| e9 popup menu | closes | closes | "Dismiss menu": closes |
| e10 tooltip | see below | pops the screen | none |
| e11 drawer | closes | closes | none |
| e12 snack bar | nothing | pops the screen; the snack bar stays | on the snack bar: closes it |
| e13 date picker | closes | closes | "Dismiss": closes |
| e14 `OverlayEntry` | nothing | pops the screen; the entry stays over Home (widget test and Android) | none |
| e15 `OverlayPortal` | nothing | pops the screen | none |
| e16 general dialog, dismissible | closes | closes | its barrier label: closes |
| e17 general dialog, defaults | nothing | closes | no node has it |
| e18 Cupertino modal popup | closes | closes | none (its barrier has no label by default) |
| e19 dialog with `PopScope(canPop: false)` | nothing | nothing | "Dismiss": nothing |
| e20 overlay, handled | closes | closes | on the overlay: closes |
| e21 dropdown | closes | closes | "Dismiss": closes |
| e22 Cupertino sheet | nothing | closes | no node has it |

- **Escape is a route's only when its barrier can be dismissed**
  ([FL-480](../../../flutter-limitations.md#fl-480)): every fixture whose
  barrier cannot be dismissed ignored it, and Back closed them all. Only
  `PopScope` stopped Back.
- **An Escape that nothing handles is not Back on Android.** With nothing
  open, or with a fixture that ignores Escape open, the key log shows
  `unhandled Escape` and the screen stayed (`android.txt`).
- **A hardware keyboard's Back on Android** (`android_round3.txt`,
  `android_round4.txt`; API 37 emulator). Meta+Escape and Meta+Left, each
  sent as four key events (Meta down, the key down and up, Meta up)
  through `Instrumentation.sendKeySync`, acted as Back: with nothing open
  the probe screen went back to Home (the positive control, and `popRoute`
  in the log), and they closed `e1`, `e2`, `e3`, `e6`, and `e17`, the
  overlay that handles Back (`e20`), popped the screen under `e14`, and
  were stopped by `e19`'s `PopScope`, exactly as the Back key. The app's
  key log never showed them: the system takes the chord before the app.
  Meta+Backspace did nothing, with nothing open either. This matches the
  AOSP sources: `InputGestureManager` in `android16-release` maps
  Meta+Escape and Meta+Left to Back (and `main` adds Meta+Backspace);
  `PhoneWindowManager` in `android15-release` turns Meta+Escape,
  Meta+Left, and Meta+Backspace into Back.
- **Nothing closes an overlay with no route, and Back pops the screen
  under it** ([FL-481](../../../flutter-limitations.md#fl-481)): `e14`
  and `e15`. `e20` shows the three things that make one close: an action
  for `DismissIntent`, a `PopScope`, and `Semantics(onDismiss:)`.
- **Tooltips** ([FL-482](../../../flutter-limitations.md#fl-482)): in the
  widget test, Escape hid a tooltip shown by a long press. On the web it
  hid one shown by hovering when the tooltip's button had DOM focus, and
  not when no element of the page had focus (`web_round2.txt`). On the
  Android emulator one shown by the long-click action stayed after
  Escape. The plan says Escape on tooltips on the web needs Flutter 3.50;
  on the pinned 3.47.5 it works on the web while focus is in the page.
- **Traps** (`flutter_test.txt`, `web_round1.txt`, `android.txt`,
  `ios.txt`): t1, t3, and t4 kept Tab and Shift+Tab between their two
  buttons on every platform, and Escape left focus where it was; t2 and t5
  sent focus to t9 on Escape, in the widget test, on the web, and on
  Android. Tab from t0 went into t1 and stayed. On iOS each F key arrived
  as the one before it (F2 as F1, and so on), so the rows of `ios.txt`
  are each one trap off: the t1 row is t5, the t2 row t1, and so on; every
  trap kept Tab and Shift+Tab, and Escape did not reach Flutter.
- **On the web, a route's Tab goes out of the page** (`web_round1.txt`):
  the dialog keeps Tab inside it (`showDialog` uses
  `TraversalEdgeBehavior.closedLoop`, read in the source); the bottom
  sheet and the general dialog leave the page past their last control and
  come back, as I03 found.
- **On iOS, Escape from XCUITest never reached Flutter** (`ios.txt`):
  every fixture stayed open, the one that handles Escape itself (`e20`)
  included, and the key log has no Escape. With VoiceOver on, Escape did
  nothing either: VoiceOver did not turn it into its escape action. In
  `ios_round2.txt` and `ios_round3.txt`, after a Tab that arrived, neither
  `XCUIKeyboardKey.escape` nor the character `\u{1b}` arrived; Command
  and period arrived as Escape and closed `e20` and `e1`; Command and `[`
  arrived as itself and did nothing.
- **VoiceOver's escape gesture on iOS** cannot be made from a test:
  `XCUIVoiceOverService` has `moveForward`, `moveBackward`, `moveIn`,
  `moveOut`, and `currentSpeech`, and nothing for gestures (read in its
  header in Xcode 27), and XCUITest has no two-finger scrub. What it does
  is read in the engine source: `accessibilityPerformEscape` on an
  element performs the dismiss action if the element has it, and UIKit
  asks each container above it in turn (`SemanticsObject.mm`); the view
  controller at the top sends `popRoute` (`FlutterViewController.mm`).
- With VoiceOver on (iOS), a double tap on a route's button put VoiceOver
  on the route's title (`ios.txt`, the `vo` rows); on the overlays
  (`e14`, `e20`) it stayed on the button.

## Afterwards

The examples' layers were first an `OverlayPortal` with a `ModalBarrier`
behind them; in a widget test the semantics tree then held only its root
([FL-483](../../../flutter-limitations.md#fl-483)), so they are an
`OverlayEntry`, as `e14` is, with the handling of `e20`.

The iOS tests send Escape as Command+period, from `ios_round3.txt`.

`android_320x640.txt` is the I08 Android test class (not the probe), as it is after review round one, run
at CI's screen size, 320 by 640 at 160 dpi, through `tool/with_devices.py`
on 2026-11-19; the script set the size and density and put both back at
the end (its first and last lines; the script is `android_320x640.sh.txt`). Its output lists only failed and
skipped tests: none failed, and the TalkBack walk was skipped, as TalkBack
was off.

`ios_suite_x3.txt` is the I08 iOS test class (not the probe, and without
its VoiceOver walk) run three times in a row on 2026-11-19, after the iOS
tests were changed to show keyboard focus in the layers before sending
Escape (I08's spec, section 7): 15 tests passed, none failed.

`android_keyboard_back_test.txt` is the I08 Android test of the
keyboard's Back (`keyboardBackClosesTheLayers`) run twice, with the
system's log of each Back (`CoreBackPreview`, `ShellBackPreview`), by
`android_keyboard_back_test.sh.txt`. Before it, that test had failed in
two of three runs: the next example opened, and its Map layers was then
not on the screen. Each chord gave one Back, and with the test now
waiting three seconds after each and checking that the example's screen
is still there, both runs passed; what took the screen away before was
not found.
