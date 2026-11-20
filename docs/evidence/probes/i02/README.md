# I02 probe: keyboard focus order

Run on 2026-11-18, Flutter 3.47.5, before the I02 examples were written.
The fixture is `probe.dart.txt`, a second entry point and not part of the
app: one long screen under an `AppBar` with a Back button, nine fixtures
`a` to `i`, each in a `FocusTraversalGroup` of its own so that the
fixtures do not mix. Every control's text starts with its fixture letter.
At the top of the screen, outside the scrolling part, the probe shows the
control with Flutter's focus ("Focus: b-water"), every focus it has had
since the screen opened ("Path: a-map a-alerts ..."), every checkbox
change ("Log: b-water on"), and every key that reached the framework
("Keys: Tab shift+Tab"), so that the order can be read from any
platform's tree. On the web, in a release build, a focus node's
`debugLabel` is empty, so there the probe names the node by looking it up
(the second web run).

Fixtures `a` to `d` are the same two columns side by side, "Pack" (Map,
Water, First aid kit) and "Send me" (Weather alerts, Trail closures), and
a Save button under them:

| # | Fixture |
| --- | --- |
| a | no groups |
| b | a `FocusTraversalGroup` per column |
| c | a `FocusTraversalGroup` and a `Semantics(container: true)` per column |
| d | a semantics container per column with sort keys putting "Send me" first, no focus groups |
| e | Cupertino: `CupertinoCheckbox`es merged with their text (as F07), a group per column, `CupertinoButton.filled` |
| f | a cross of four buttons, Up, Left, Right, Down, as in the Android View arrow key example |
| g | the five checkboxes laid out row by row, `OrderedTraversalPolicy`, every control numbered down the columns |
| h | g with an `OrdinalSortKey` of the same number on each control |
| i | g with First aid kit not numbered |

A second screen (round 2, routes `/scroll` and `/scroll-groups`) has forty
buttons, `s01` to `s40`, in a `SingleChildScrollView` under an `AppBar`,
in groups of four in the second.

How each platform was looked at, and the raw output:

- Flutter test: `probe_test.dart.txt` (as Android and as iOS at a phone's
  size, and at 1280 by 720) and `probe2_test.dart.txt` (ways round
  FL-422). Output: `flutter_test.txt`.
- Web: Chromium on macOS, Playwright, `probe_web.spec.js.txt`: the
  elements in document order, Chromium's accessibility tree, Tab and
  Shift+Tab read from `document.activeElement`, Tab past the end, the
  arrow keys, and round 2. Output: `web.txt`.
- Android: Pixel 10a emulator, Android 17, `hw.keyboard=yes` (read, not
  changed). A shell part (`android_probe.sh.txt`: `input keyevent`, `adb
  emu event send`, `uiautomator dump`) and an instrumented part
  (`ProbeI02Test.kt.txt`: the tree, sixty Tabs, every way found to send
  Shift+Tab, the D-pad). Output: `android.txt`. Round 2
  (`android_round2.sh.txt`: `sendevent` and `adb emu event send` again).
  Output: `android_round2.txt`.
- iOS: iPhone 17 simulator, iOS 27.0, `I02ProbeUITests.swift.txt` run by
  `ios_probe.sh.txt`: the tree, sixty Tabs, Shift+Tab, the arrows, Space,
  and VoiceOver's own moves. Output: `ios.txt`. Full Keyboard Access was
  not turned on.
- iOS on CI (iPhone 17 Pro simulator, iOS 26.5): the lines of the
  technique's Shift+Tab test from two CI jobs where it failed, in
  `ci_ios_26_5_shift_tab.txt`. Not a probe run: kept from the job logs.

## The order

**Tab, the same on every platform** (from Back, fixture by fixture):

| # | Tab order | Screen reader order |
| --- | --- | --- |
| a | Map, Weather alerts, Water, Trail closures, First aid kit, Save (web, Android, iOS); Map, Water, Weather alerts, First aid kit, Trail closures in the widget test at a phone's size, where the test font wraps "Weather alerts" and makes its row taller | row by row on the web, Android, and iOS (VoiceOver); column by column in the widget test |
| b | Map, Water, First aid kit, Weather alerts, Trail closures, Save | as a |
| c | as b | column by column everywhere |
| d | as a | "Send me" first, then "Pack", on the web and in the widget test |
| e | Map, Water, Weather alerts, Save | |
| g | Map, Water, First aid kit, Weather alerts, Trail closures, Save | row by row |
| h | as g | column by column |
| i | Map, Water, Weather alerts, Trail closures, Save, First aid kit | row by row |

So:

- **The default order is by position**, row by row when the rows of two
  columns are level. A `FocusTraversalGroup` per column makes Tab go down
  one column and then the other.
- **The two orders are set apart.** A focus group does not change the
  screen reader's order (b reads like a), and a semantics container or
  sort key does not change the keyboard's (d tabs like a). The
  framework's own semantics sort is by position as well, with rules of
  its own: rows that touch form one band read down by column, rows apart
  read across. The same layout read by column in the widget test and by
  row on the devices. FL-420.
- **`OrderedTraversalPolicy` puts a control with no order after every
  numbered one** (i), as its documentation says. HTML does the same:
  elements with a positive `tabindex` come first and the rest after.

**Past the end.** On Android and iOS, Tab past the last control went
round to the first control of the content (`a-map`), not to Back: the
screen had scrolled, and the content scrolled away above was higher on
the screen than the app bar (FL-422). Shift+Tab from `a-map` went to Back
and then round to the last control (`i-aid`). On the web, Tab past
`i-aid`, Flutter's last control, went to `i-save`, the next element in
the document, and from there round `i-aid`, `i-save` for ever; at the end
of an order whose last control is also last in the document, Tab left the
page (the body had focus). FL-421.

**Shift+Tab up a scrolled screen.** On the web, in round 2, Shift+Tab
from `s40` went up twenty buttons in order and then put focus on Back at
every second press: s20, Back, s19, Back, s18. With groups of four, Back
came between groups. In the first screen, Back came between fixtures. The
same screen in a widget test at 1280 by 720 did the same (Back from
`s26` up, and between groups), so it is the framework, not the web
engine. `probe2_test.dart.txt` tried two ways round it, each in a widget
test: a `FocusTraversalGroup` around the scrolling view, and an
`OrderedTraversalPolicy` over the screen ordering the app bar first; both
gave Back, s01 to s12, Back. FL-422.

**The arrow keys.** Android (D-pad keys through `input keyevent`), iOS
(`typeKey` with the arrow keys), and the widget test agree: Down from Map
goes to Water, Right from Map to Weather alerts, Left back. In the cross,
Down from Up goes to Down, as the Android View reference wants after its
fix, but Down from Left goes out of the cross to the next fixture's first
control, which is below Left and lined up with it, and on the devices
Down from Right went to the next fixture's second control: Flutter's
directional search looks first at what is in line with the control that
has focus (the "band" described in `DirectionalFocusTraversalPolicyMixin`'s
documentation, `widgets/focus_traversal.dart`). A `FocusTraversalGroup` does not hold the arrows (b-map Up went
to a-save). On the web the arrow keys did not move focus: they scrolled
the page by about 50 pixels (`WidgetsApp`'s web shortcuts map them to
scrolling; read in the source).

## Driving the keys

### Shift+Tab on Android

Each attempt started from `b-closures`; Shift+Tab should go to
`b-alerts`, and Tab to `b-save`. The key log is what reached the
framework.

| How | Result |
| --- | --- |
| `UiDevice.pressKeyCode(TAB, META_SHIFT_ON \| META_SHIFT_LEFT_ON)` | forward, to `b-save`; the key log has a plain Tab |
| `Instrumentation.sendKeySync`: Shift down (meta `SHIFT_ON \| SHIFT_LEFT_ON`), Tab down and up (same meta), Shift up (meta 0), device -1 | **backward, to `b-alerts`**; the log has `shift+Shift Left shift+Tab` |
| `UiAutomation.injectInputEvent`: the same four events, device -1 | **backward** |
| `Instrumentation.sendKeySync`: the same four events, device 0 (`qwerty2`, the emulator's keyboard) | **backward** |
| `UiAutomation.injectInputEvent`: the same four events, device 0 | **backward** |
| `Instrumentation.sendKeySync`: Tab down and up with the Shift meta state and no Shift events, device 0 | forward |
| `adb shell input keycombination KEYCODE_SHIFT_LEFT KEYCODE_TAB` | forward; the log has Shift and then a Tab without Shift |
| `adb shell input keyevent --longpress KEYCODE_SHIFT_LEFT KEYCODE_TAB` | forward, past `b-save` to `c-map` |
| `adb emu event send EV_KEY:KEY_LEFTSHIFT:1 EV_KEY:KEY_TAB:1 EV_KEY:KEY_TAB:0 EV_KEY:KEY_LEFTSHIFT:0`, and again with `EV_SYN` after each | the console answered OK; nothing reached the app, not even a Tab sent the same way |
| `adb shell sendevent` on `/dev/input/event12` (`qwerty2`) | "Permission denied": the shell user is in the `input` group, but writing is refused (SELinux, presumably; not checked); the image is a `user` build and not debuggable, so `adb root` was not tried |

What decides it is a Shift key event of its own. Read in the engine
source (`KeyEmbedderResponder.java`): Flutter keeps its own record of
which keys are down and makes it agree with each event's meta state; for
an event from the virtual keyboard, device -1, which is what
`pressKeyCode` and `input` send, it trusts the meta state without adding a
Shift press it never saw, so a Tab carrying only the Shift meta state is a
plain Tab to Flutter. With a real Shift down event first, Flutter's record
has Shift down when the Tab arrives. The I02 Android tests send Shift+Tab
the second way.

### Other keys

- **The first Tab after the app opens** was lost on the first Android
  run (eleven Tabs, ten in the key log) and not on the second (eleven
  and eleven), when the probe was started with `monkey` in both. The
  tests allow for it either way by tabbing until a control has focus.
- **iOS**: `typeKey(XCUIKeyboardKey.tab.rawValue, modifierFlags: .shift)`
  reached Flutter as Shift+Tab and moved focus backward, all the way up
  the screen. Space checked the box that had focus.
- **Web**: Playwright's `Shift+Tab` arrived as Shift and Tab with Shift
  held, as on the other platforms.

## Screen readers

- VoiceOver on iOS, moving with its own swipes: fixtures `a` and `b` row
  by row ("a Pack", "a Send me", "a Map", "a Weather alerts", ...),
  fixture `c` column by column. It stopped moving at "c Trail closures"
  (the next element was below the screen); the walk was not taken
  further.
- TalkBack was not run; the order of the nodes in the tree (which the
  engine builds from the framework's traversal order, read in the source)
  was row by row for `a` and `b` and column by column for `c`.
- On the web the document's order, which VoiceOver's cursor follows, was
  row by row for `a` and `b`, column by column for `c` and `h`, and "Send
  me" first for `d`.

## What it shows

- Flutter's default focus order goes across side-by-side columns, row by
  row; `FocusTraversalGroup` per column fixes it on every platform. The
  screen reader's order needs a separate fix, a semantics container per
  column or sort keys, and without it may read across too (FL-420). The
  good examples have both, and the bad example `bad-columns-mixed` keeps
  the semantics container, so that its one defect is the keyboard's.
- Where no widget holds a column, `OrderedTraversalPolicy` and a number
  on every control give the order; a control left without a number comes
  last, after the Save button (`bad-order-missing`). On the web that also
  makes Tab go round for ever, because the browser carries on in the
  document's order (FL-421); sort keys matching the numbers avoid it.
- On a scrolled screen the default order puts Back among the content
  (FL-422); a `FocusTraversalGroup` around the scrolling view fixes it in
  a widget test.
- The arrow keys move by position on Android and iOS, and scroll on the
  web.
- Shift+Tab can be sent on Android, with a Shift key event of its own.
