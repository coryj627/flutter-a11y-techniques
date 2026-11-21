# C02 probe: toggle buttons

Run on 2026-11-20, Flutter 3.47.5, before the C02 examples were written.
The fixture is `probe.dart.txt`, a second entry point and not part of the
app: one screen of fixtures `t01` to `t21`, each name starting with its
number ("t01 Bold"), each holding its own on or off state. "Flip all" at
the top flips every fixture at once, so each platform's tree can be read
in both states, and the line "State: t01=0 t02=1 …" gives every fixture's
state, so what a key did can be read from any platform's tree.

| # | Fixture |
| --- | --- |
| t01 | `IconButton(isSelected: false, tooltip:, icon:, selectedIcon:)` |
| t02 | the same, starting on |
| t03 | `IconButton(isSelected:)` with no tooltip; both icons have a `semanticLabel` |
| t04 | `Semantics(toggled:, enabled: true)` around an `IconButton(isSelected:)` |
| t05 | `ToggleButtons` with three icons (`t05a` to `t05c`), the second on; the third is not wired to the state (a fault of the fixture) |
| t06 | `SegmentedButton(multiSelectionEnabled: true, emptySelectionAllowed: true)`, two segments, the second chosen |
| t07 | `SegmentedButton` with one choice at a time (a radio group: F08, F17) |
| t08 | custom: `Semantics(button: true, selected:, enabled: true, label:, onTap:)` |
| t09 | custom: the same with `toggled:` |
| t10 | custom: the same with `checked:` |
| t11 | custom: `Semantics(button: true)` and no state |
| t12 | custom: `selected:`, with a name that changes ("Mute", then "Unmute") |
| t13 | `Semantics(toggled:, enabled: true)` around a `CupertinoButton` |
| t14 | `Semantics(selected:, enabled: true)` around a `CupertinoButton` |
| t15 | `FilterChip(selected:)` |
| t16 | `IconButton(isSelected: true, onPressed: null)`, disabled |
| t17 | `IconButton(isSelected:)` whose tooltip changes ("Mute", then "Unmute") |
| t18 | `Semantics(toggled:, enabled: true)` around an `OutlinedButton` |
| t19 | custom: `selected:` with no `enabled` |
| t20 | t04 inside `MergeSemantics` |
| t21 | t18 inside `MergeSemantics` |

The custom fixtures (t08 to t12, t19) are a drawn box in a
`GestureDetector`, with `ExcludeSemantics` under the `Semantics`, inside
a `FocusableActionDetector` for Enter and Space.

## How it was looked at

- Flutter test: `probe_test.dart.txt`, as Android and as iOS: every
  fixture's semantics node before and after "Flip all", then Tab through
  the screen with Space and then Enter at each stop. Output:
  `flutter_test.txt`.
- Web: Playwright on macOS, Chromium and WebKit,
  `probe_web.spec.js.txt` with `c02probe.config.js.txt`, against
  `flutter build web -t lib/probe.dart`: every element's role and ARIA
  attributes and Playwright's ARIA snapshot, before and after "Flip all";
  then, in Chromium, Tab through the screen with Space and then Enter at
  each stop. Output: `web.txt` (lines cut at 400 characters; only the
  "body" and "flutter-view" stops, which are the page itself, and the
  first stop's list of changes were long enough to be cut).
- Android: Pixel 10a emulator, Android 17, 1080 by 2424 at 420 dpi.
  `android_probe.sh.txt` installed the probe, dumped the node tree with
  `uiautomator dump`, tapped "Flip all", and dumped it again
  (`android_before.xml`, `android_after.xml`); then it opened a native
  screen (`ProbeNativeActivity.kt.txt`, declared for this run only in the
  debug manifest) and dumped it before and after a tap on n05
  (`android_native_before.xml`, `android_native_after.xml`).
  `android_nodes.py.txt` prints the nodes that have a text or a
  description: `android_nodes.txt`. The script's own output is
  `android.txt`. No device setting was changed.
- iOS: iPhone 17 simulator, iOS 27.0, `C02ProbeUITests.swift.txt`
  (`testProbe`), run by `ios_probe.sh.txt`: the XCUITest tree, then a
  VoiceOver walk with `XCUIVoiceOverService` (on for the walk, off after
  it), then a tap on "Flip all", the tree, and a walk again. Output:
  `ios.txt`. XCUITest cannot read traits, so a button's traits other than
  `isSelected` are known only from what VoiceOver says.
- iOS, native: the same class's `testNative`, run by
  `ios_native_probe.sh.txt`, with a throwaway `SceneDelegate`
  (`SceneDelegate.swift.txt`) that shows UIKit buttons in place of
  Flutter when launched with `-c02native`: n01 and n02, buttons with the
  toggle button trait (iOS 17), off and on; n03, a button with
  `changesSelectionAsPrimaryAction`; n04, a plain button that is selected.
  The tree and a walk, then a tap on n01 and on n03, then the tree and a
  walk again. Output: `ios_native.txt`.

## What each platform exposes

| Fixtures | Widget tree (both platforms) | Web | Android | iOS (tree; VoiceOver) |
| --- | --- | --- | --- | --- |
| t01, t02, t03 (`IconButton(isSelected:)`) | button, `selected` true or false | `role="button"`, `aria-current="true"` or `"false"` | `Button`, `selected` true or false, not checkable | button, `isSelected`; "t01 Bold Button", "selected t02 Bold Button" |
| t06 (multi-select `SegmentedButton`) | each segment a button, `selected` | as t01 | as t01 | as t01: "t06a Bold Button", "selected t06b Italic Button" |
| t08 (`selected`), t14 (`selected` around a `CupertinoButton`), t19 | as t01 | as t01 | as t01 | as t01 |
| t05 (`ToggleButtons`) | each a button, `checked` | `role="checkbox"`, `aria-checked` | `CheckBox`, checkable, checked | switch, value 0 or 1; "t05a Bold Switch button off Double tap to toggle setting." |
| t10 (`checked`) | button, `checked` | as t05 | as t05 | as t05 |
| t09 (`toggled`), t13 (`toggled` around a `CupertinoButton`) | button, `toggled` | `role="switch"`, `aria-checked` | `Switch`, checkable, checked | switch; "t09 Mute Switch button off …" |
| t20, t21 (`toggled` and a Material button, in `MergeSemantics`) | button, `toggled`; t20 also `selected` | as t09; t20 has no `aria-current` | as t09; t20 is also `selected` when on | as t09; VoiceOver does not say "selected" for t20 |
| t04, t18 (`toggled` around a Material button, not merged) | the button's node has no `toggled` | `role="switch"` named by the button inside it, around the button (`aria-current` on t04's button) | a `Button` with no checked state; the toggled node has no name | a switch with no label and a button, at the same place; VoiceOver read only the button: "t04 Bold Button" |
| t11 (no state) | button | `role="button"`, no state attribute | `Button`, not checkable, not selected | button; "t11 Mute Button" both times |
| t12, t17 (name changes) | the name is "Mute", then "Unmute" | as t01, and the name changes | as t01, and the name changes | "t12 Mute Button", then "selected t12 Unmute Button" |
| t15 (`FilterChip`) | button, `selected` | `role="checkbox"`, `aria-checked` (the chip sets `checked` on the web only) | `Button`, `selected` | button, `isSelected`; "selected t15 Bold Button" |
| t16 (disabled, on) | button, `selected`, not enabled | `aria-current="true"`, `aria-disabled="true"` | `Button`, selected, not enabled | button, selected, not enabled; VoiceOver did not stop on it in either walk |

No fixture gave `aria-pressed` on the web, an `android.widget.ToggleButton`
on Android, or anything that VoiceOver read as a toggle button on iOS.

Native, for comparison:

- Android and iOS: see "Native controls" below. The tree dumps of the
  first native fixture (`android_native_before.xml`,
  `android_native_after.xml` and their lines in `android_nodes.txt`) show
  `android.widget.ToggleButton` checkable and checked or not, and a
  `Button` with `isSelected` selected; that fixture's toggle buttons had
  no state description of their own (below).

## Native controls

The native fixtures were run twice. The first version set up its toggle
buttons in a way that removed their state on both platforms, so its
readings of the toggle buttons are not used; they are kept below with
what was wrong. The second version is the comparison.

- **Android, second version** (`ProbeNativeActivity2.kt.txt`; the walk's
  native stops in `C02ToggleButtonTest-native2.kt.txt`; run by
  `native2_probe.sh.txt`; TalkBack's speech in `talkback-native2.md.txt`,
  the tool's output in `talkback-native2-run.txt`; the nodes the walk
  logged in `android_native2_nodes.txt`). Each `ToggleButton` keeps
  Android's own `textOn` and `textOff`; the fixture sets only
  `contentDescription` (the name) and `isChecked`. n00, a plain `Button`,
  comes first, and TalkBack focus goes to it before each reading, so no
  control is read while it already has focus. The nodes: n01 is a
  checkable `ToggleButton` with the text and the state description "OFF",
  and both "ON" after the click; n02 is "ON" from the start. TalkBack 17
  reads:
  - n01, off: "OFF. n01 Bold. Switch", "Double-tap to toggle"
  - n01, after a click: "ON. n01 Bold. Switch", "Double-tap to toggle"
  - n02, on from the start: "ON. n02 Bold. Switch", "Double-tap to
    activate" (the hint differs from n01's; why was not looked into)
  - n03, a `Button` that is selected: "selected. n03 Bold. Button"
  - n04, a `Button` that is not: "n04 Bold. Button"
  - n05, made as in the first version (below): "n05 Bold. Switch"
  Flutter's `toggled` is read "off. Bold. Switch" and "checked. on. Bold.
  Switch": the same role and the same state words, with the extra
  "checked" of FL-100.
- **Android, first version** (`ProbeNativeActivity.kt.txt`, the rows
  `c02-native-…` of `talkback-first-run.md.txt`). The fixture set
  `textOn` and `textOff` both to the name ("n02 Bold"). The source of
  `android.widget.ToggleButton` in the installed SDK
  (`sources/android-37.0/android/widget/ToggleButton.java`,
  `getButtonStateDescription`) makes the state description `textOn` when
  checked and `textOff` when not, and "ON" or "OFF" only when they are
  unset, so that fixture made the state description the name in both
  states, and TalkBack read "n02 Bold. Switch" with no state. The second
  version's n05 is made the same way and reads the same. The first
  version also left n01, the one that was off, unread: TalkBack focus was
  already on it.
- **iOS, second version** (`SceneDelegate2.swift.txt`,
  `C02ProbeUITests2.swift.txt`, output `ios_native2.txt`, run by
  `native2_probe.sh.txt`). n01 and n02 are a `UIButton` subclass that adds
  the toggle button trait to the traits UIKit gives it, changing nothing
  else, so UIKit still adds the selected trait from `isSelected`; n03 is a
  button with `changesSelectionAsPrimaryAction` and nothing else set; n04
  is a plain button that is selected; n00, a plain button, comes first.
  To XCUITest the toggle buttons are switches (type 40) whose `isSelected`
  follows the state. VoiceOver reads:
  - n01, not selected: "n01 Bold Switch button Double tap to toggle
    setting."; after a tap: "selected n01 Bold Switch button …"
  - n02, selected: "selected n02 Bold Switch button …"
  - n03: "n03 Bold Button"; after a tap: "selected n03 Bold Button"
    (UIKit gives it no toggle trait)
  - n04: "selected n04 Bold Button"
  - n05, made as in the first version (below): "n05 Bold Switch button
    …", although it is selected
  Flutter's `toggled` is read "Bold Switch button off" and "… on": the
  same role, with the state in other words.
- **iOS, first version** (`SceneDelegate.swift.txt`, `ios_native.txt`).
  The fixture added the toggle button trait by assigning
  `accessibilityTraits` (`insert` on the property) before setting
  `isSelected`. An assigned value replaces the traits a `UIButton`
  derives from its state, so the selected trait was lost, and VoiceOver
  read the selected n02 "n02 Bold Switch button" with no state. The
  second version's n05 is made the same way and reads the same, while
  the subclass that adds to UIKit's traits is read "selected". The first
  version's test also failed before its second walk: it looked for n01
  among the buttons, and n01 is a switch to XCUITest.
- **Anything else the fixtures set that could change a reading**: see
  the C02 spec, section 7, "What the native fixtures set".
- **Web**: the C02 VoiceOver spec reads a plain HTML page with a
  `button` with `aria-pressed="false"`, one with `aria-pressed="true"`,
  and one with `aria-current="true"` (`control-html` in
  `docs/evidence/C02/voiceover-web.md`): "Bold toggle button", "Italic
  selected toggle button", and "Underline current item button", in
  Chromium and WebKit. It was first read in the second run of the
  examples (`voiceover-web-second-run.md.txt`), where the test failed
  only because its check had been written before the reading was known
  (it expected the walk to end at "Changes: 0"; VoiceOver went on to "end
  of main"). In the third run (`voiceover-web-third-run.md.txt`,
  failures in `voiceover-web-third-run-control-errors.txt`) the check was
  the exact list from the second run, and the walk was not steady on this
  page: in some attempts it never reached the heading, and in others it
  went past the Bold button without reading it, in both browsers. The
  test now walks the page up to three times, logs every try, and passes
  only on a complete walk: the three buttons read one after the other,
  each in the expected words, then "Changes: 0", and the end reached. A
  button read in other words in any try fails it.
  The first run's attempt at it
  failed before reading anything: it replaced the content of the Flutter
  page, and Flutter's view stayed over it and took the click that starts
  the walk (`voiceover-web-first-run.md.txt` and
  `voiceover-web-first-run-native-html-error.txt`).

So the native toggle buttons that are nearest are read as switches by
both phone screen readers. On Android they say "OFF" and "ON", as
Flutter's `toggled` does; on iOS they say nothing while off and
"selected" while on, where Flutter's `toggled` says "off" and "on". Only
the web has a toggle button role, which Flutter cannot give.

## The Android suite at CI's size

`android_320x640.sh.txt` ran `C02ToggleButtonTest` once with the
emulator at 320 by 640 and 160 dpi, CI's size, and put the size and
density back afterwards: `android_320x640.txt`. The build passed; Gradle
prints only the skipped test (`talkBackWalk`, which skips itself with
TalkBack off), so a pass is "BUILD SUCCESSFUL" with no failure.

## First run of the examples

The first build of the C02 examples was run through `tool/evidence.py C02`
before the examples were settled, and its transcripts are kept here:
`talkback-first-run.md.txt`, `voiceover-ios-first-run.md.txt`, and
`voiceover-web-first-run.md.txt`, with the sources they ran
(`examples-first-run.dart.txt`, `C02ToggleButtonTest-first-run.kt.txt`,
`C02ToggleButtonUITests-first-run.swift.txt`,
`c02_toggle_button_vo-first-run.spec.js.txt`). That run's expectations
checked the names only; it was a probe of the speech. What it changed:
`good-icon-button` then kept `isSelected` beside `toggled`, and TalkBack
read it "selected. checked. on. Bold. Switch", so the example now draws
its pressed look and leaves `isSelected` out; `bad-label-changes` had
`isSelected` too and was changed the same way.

## Keyboard

From `flutter_test.txt` (as Android and as iOS) and `web.txt` (Chromium):
Space and Enter each toggled every fixture once it had focus, with three
exceptions. On the web, Enter did not change t13 or t14, the
`CupertinoButton`s (FL-002); Space did. On every platform, Enter and Space
did nothing on t07's segment that was already chosen, which is what a
radio group does, and Enter did nothing on its other segment once Space
had chosen it. t05c is not wired to the state (the fixture's fault), so
nothing shows there.

Every fixture but the disabled t16 is one Tab stop, the three
`ToggleButtons` and the two segments of each `SegmentedButton` one stop
each. On the web the custom
fixtures' focus is on an element around the one with the role (the
`FocusableActionDetector`'s, with `role` null in `web.txt`), because the
probe does not merge them; the examples do, through `TestId`.

## What it shows

- **Flutter has no pressed state.** A toggle button can be given
  `selected`, `checked`, or `toggled`, and becomes a button that is
  selected, a checkbox, or a switch. None is a toggle button on any
  platform.
- **The framework's own toggles use `selected` and `checked`.**
  `IconButton(isSelected:)` and a multi-select `SegmentedButton` give
  `selected`, which says nothing while it is false: VoiceOver on iOS reads
  "t01 Bold Button" for one that is off, as for a plain button.
  `ToggleButtons` gives `checked`: a checkbox on Android and the web, a
  switch on iOS.
- **`toggled` gives a state in both states on every platform**, as a
  switch. On a Material button it has to be merged with the button's own
  node (t04 and t18 against t20 and t21); on a `CupertinoButton` it joins
  without help (t13).
- **On the web `selected` on a button is `aria-current`.**
- A name that changes with the state changes on every platform (t12,
  t17).
