# I01 probe: focusable and clickable controls

Run on 2026-11-18, Flutter 3.47.5, before the I01 examples were written.
The fixture is `probe.dart.txt`, a second entry point and not part of the
app: fourteen tappable things, `k01` to `k14`, each text starting with its
id. Every activation is added to a log at the top of the screen ("k01
tap", "k09 down", "k05 key"); under it the widget with Flutter's primary
focus is named ("Focus: k03"), and, in the second round, every key that
reached the framework ("Keys: Tab Tab Enter"). So what the keyboard did can
be read from any platform's tree, even where the tree does not say where
focus is.

| # | Fixture |
| --- | --- |
| k01 | `ListTile(onTap:)` in a `Card` |
| k02 | `InkWell(onTap:)` around text |
| k03 | `Semantics(button: true)` around an `InkWell` |
| k04 | `CupertinoListTile(onTap:)` |
| k05 | k04 inside `FocusableActionDetector` (both activate intents) and `Semantics(button: true)` |
| k06 | `FocusableActionDetector`, `Semantics(button: true)`, `GestureDetector(onTap:)` |
| k07 | `Semantics(button: true)` and `GestureDetector(onTap:)`, no focus |
| k08 | k07 inside `Focus`, with no actions for the keys |
| k09 | k06 with `onTapDown` in place of `onTap` |
| k10 | `Semantics(button: true)` around `Listener(onPointerUp:)`, the counterpart of an Android `onTouchListener` |
| k11 | `CupertinoButton`, for comparison |
| k12 | `TextButton`, for comparison |
| k13 | `FocusableActionDetector` with `ActivateIntent` only, and `Semantics(button: true, onTap:)` with no gesture |
| k14 | `FocusableActionDetector` and `GestureDetector`, no `Semantics(button: true)` |

How each platform was looked at, and the raw output:

- Flutter test: `probe_test.dart.txt` under `flutter_test`, as Android and
  as iOS. Output: `flutter_test.txt`.
- Web: Chromium on macOS, Playwright, `probe_web.spec.js.txt`: each
  element's attributes, Chromium's accessibility tree over the DevTools
  protocol, Tab with Enter and Space at each stop, presses that slide off,
  and click events sent to elements. Output: `web.txt` (run after the
  second round, so the screen also has the key log).
- Android: Pixel 10a emulator, Android 17 (API 37), with `hw.keyboard=yes`
  in its AVD settings (read, not changed). First round
  (`android_probe.py.txt`): `adb shell input keyevent` for the keys,
  `uiautomator dump` for the tree after each, `input swipe` and `input tap`
  for the pointer. Output: `android.txt`. Second round
  (`ProbeI01Test.kt.txt`, an instrumented test, run by `round2.sh.txt`):
  each way a test can press a key, one after the other, with the key log
  read after each. Output: `android_round2.txt`.
- iOS: iPhone 17 simulator, iOS 27.0, Xcode 27.1, `I01ProbeUITests.swift.txt`
  (run by `ios_probe.sh.txt` and `round2.sh.txt`): the tree with
  `hasFocus`, `typeKey` for the keys, `press(forDuration:thenDragTo:)`,
  VoiceOver's walk and double tap, and Full Keyboard Access turned on in
  the Settings app and off again. Output: `ios.txt`.

## What each fixture is

| # | Web | Android | iOS | VoiceOver on iOS |
| --- | --- | --- | --- | --- |
| k01 | `role="button"`, `tabindex="0"` | `Button`, clickable | button | "k01 ListTile Button" |
| k02 | `role="button"`, `tabindex="0"` | `View`, clickable | static text | "k02 InkWell" |
| k03 | as k01 | `Button` | button | "… Button" |
| k04 | `role="button"`, no `tabindex` | `View`, clickable | static text | "k04 CupertinoListTile" |
| k05 to k09 | as k01 | `Button` | button | "… Button" |
| k10 | `role="button"`, no `tabindex`, no `flt-tappable` | `Button`, not clickable | button | "k10 Listener Button" |
| k11 to k13 | as k01 | `Button` | button | "… Button" |
| k14 | as k01 | `View`, clickable | static text | "k14 FAD, no button role" |

In the semantics tree (`flutter_test.txt`) k04, k07, and k10 are the only
fixtures with no focus state at all (`isFocused` is `Tristate.none`); k10
is the only one with no tap action.

Android's `focusable` is true for every fixture, k04, k07, and k10
included. The engine sets it from the node's flags, label, and actions
(read in the source: `isFocusable()` in `AccessibilityBridge.java` falls
back to "has a label or an action"), so it says nothing about the
keyboard. `focused` is set from Flutter's keyboard focus
(`BaseRoleConfigurator.java` sets it for the node with the focused flag)
and follows Tab, as below.

## The keyboard

**Tab order, the same on every platform:** k01, k02, k03, k05, k06, k08,
k09, k11, k12, k13, k14, then round to k01. Tab never stops on k04
(`CupertinoListTile`), k07 (no focus), or k10 (`Listener`).

**Enter and Space at each stop:**

| # | Flutter test | Web | Android | iOS |
| --- | --- | --- | --- | --- |
| k01 to k03, k05, k06, k09, k12, k14 | both activate | both | both | Space; Enter see below |
| k08 (`Focus`, no actions) | neither | neither | neither | neither |
| k11 (`CupertinoButton`) | both | Space only (FL-002) | both | Space |
| k13 (`ActivateIntent` only) | both | Space only | both | Space |

### Driving it on Android

- `adb shell input keyevent KEYCODE_TAB` (and `KEYCODE_ENTER`,
  `KEYCODE_SPACE`) moves Flutter's focus and activates, and
  `uiautomator dump` then shows `focused="true"` on the node with focus.
  So does `input keyboard keyevent`.
- In an instrumented test, `UiDevice.pressKeyCode`,
  `Instrumentation.sendKeyDownUpSync`, `UiDevice.pressEnter`, and
  `UiDevice.executeShellCommand("input keyevent …")` all reached Flutter
  (`android_round2.txt`, the key log after each).
- **The first Tab after the app opens does nothing.** In both rounds the
  first Tab left Flutter's focus where it was, and in the second the key
  log shows it never reached the framework; the second Tab moved focus.
  This fits Android's touch mode: a key that moves focus, pressed while the
  device is in touch mode, takes it out of touch mode and is used up there.
  That is not confirmed from the Android source here. A test that presses
  Tab once and gives up, as the F10 probe did, sees nothing happen. The I01
  tests press Tab until the control has focus, at most six times.
- **Shift+Tab could not be sent.** `pressKeyCode(TAB, META_SHIFT_ON)`
  arrived as a plain Tab, and `input keycombination KEYCODE_SHIFT_LEFT
  KEYCODE_TAB` as Shift and then a Tab without Shift; both moved focus
  forward. Not tried: `UiAutomation.injectInputEvent` with a Shift key
  down event held around the Tab. Left to I02.
- `KEYCODE_DPAD_DOWN` moved focus to the next control below (k06 to k08).

### Driving it on iOS

- `XCUIElement.typeKey` sends keys that the simulator delivers as a
  hardware keyboard's. Tab, Shift+Tab, Space, and the arrow keys reached
  Flutter (the key log); Tab moved focus as on the other platforms and
  Space activated.
- **Enter has to be typed as `"\n"`.** `XCUIKeyboardKey.return` reached
  nothing (no key in the log); `XCUIKeyboardKey.enter`, the keypad key,
  arrived as Control and C; `typeKey("\n", …)` arrived as Enter and
  activated k01.
- `XCUIKeyboardKey.escape` reached nothing. Left to I08.
- **XCUITest does not see Flutter's keyboard focus**: `hasFocus` was false
  on every element after every key. The I01 tests show focus by what a key
  does next.
- **With Full Keyboard Access on**, turned on in the Settings app by the
  probe, no key from `typeKey` reached Flutter (the key log stayed empty),
  no element reported `hasFocus`, and Space activated nothing. In the
  first round, after `defaults write com.apple.Accessibility
  FullKeyboardAccessEnabled -bool true` (the key was not there before, and
  was deleted after), Tab no longer moved Flutter's focus and Space
  activated nothing either; that round had no key log. What Full Keyboard Access does with Flutter controls is
  therefore not established. The engine's source
  (`SemanticsObject+UIFocusSystem.mm`) says that with it on, the system's
  focus moves over every node that has a tap action, whether or not
  Flutter can focus it, and activates with the tap action; if that holds,
  k07 (`bad-no-focus` in the examples) would be reachable there, and k08's
  keys would work. Read in the source, not observed. Full Keyboard Access
  was turned off again after the run (checked in a fresh launch of
  Settings).

## The pointer

A press on the fixture, held, then moved well off it before being let go:

| # | Flutter test | Web | Android | iOS |
| --- | --- | --- | --- | --- |
| k01, k06, k04, k07 | nothing | nothing | nothing | nothing |
| k09 (`onTapDown`) | acts on the press | acts on the press if held 300 ms or more | acts on the press | acts on the press |
| k10 (`Listener`) | acts when let go, off the control | the same | the same | the same |

On the web a press on an element that can be tapped is held back by the
engine for up to 200 ms (read in the source: `ClickDebouncer` in
`pointer_binding.dart`). Measured: k09 had not acted 100 ms into a press
and had by 300 ms; a press that moved off sooner did not act at all.

## Assistive technology

- A semantics tap (`flutter_test`), a click event on the element (web),
  and VoiceOver's double tap (iOS) activated k04 and k07: a control with
  no keyboard focus still works for a screen reader.
- k10, with no tap action: nothing on the web (click event) and nothing
  from a semantics tap; VoiceOver's double tap on iOS did activate it,
  through a touch VoiceOver makes at the element. On Android it is not
  clickable. TalkBack was not tried.

## What it shows

- **A `CupertinoListTile` with `onTap` cannot be reached by the keyboard**
  on any platform, **and is not a button on Android and iOS** (FL-400). On
  the web it has `role="button"`, from its tap action (FL-006), and no
  `tabindex`. `FocusableActionDetector` and `Semantics(button: true)`
  around it fix both (k05).
- **An `InkWell` is focusable and keyboard operable and is not a button**
  on Android and iOS (FL-401). `Semantics(button: true)` (k03) or a
  `ListTile` (k01) fixes it.
- **`Focus` alone puts a control in the Tab order and does not make the
  keys work** (k08). `FocusableActionDetector` with actions for
  `ActivateIntent` and `ButtonActivateIntent` does (k06).
- **Registering `ActivateIntent` only leaves Enter dead on the web**
  (k13), as FL-002 found for `CupertinoButton`.
- **`onTapDown` acts on the press** on every platform, and a `Listener`
  acts on any release, even off the control.
- **The keyboard can be driven and observed on the Android emulator** once
  the first Tab is allowed for, and **driven on the iOS simulator**, where
  focus cannot be read.
- The `Listener` fixture (k10) has three defects at once (no keyboard, no
  tap action, no way to cancel), so it was not made an example.
