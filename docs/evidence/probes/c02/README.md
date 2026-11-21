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

- Android (`android_nodes.txt`): `android.widget.ToggleButton` is
  checkable and checked or not (n01, n02, and n05 after the tap); a
  `Button` with `isSelected = true` (n03) is a `Button` that is selected,
  as Flutter's `selected` is.
- iOS (`ios_native.txt`): see "Native controls" below.

## Native controls

- **iOS** (`ios_native.txt`, the walk before any tap). A UIKit button with
  the toggle button trait is a switch to XCUITest (type 40, as n01 and
  n02 are), and VoiceOver reads n02, which is selected, "n02 Bold Switch
  button Double tap to toggle setting.", with no word for its state. The
  button with `changesSelectionAsPrimaryAction` (n03) is read "n03 Bold
  Button": UIKit gives it no toggle trait of its own. The plain selected
  button (n04) is read "selected n04 Bold Button", as Flutter's
  `selected` is. n01 was not read: VoiceOver's cursor started on it and
  the walk's first move went past it. The test then failed: it looked for
  n01 among the buttons to tap it, and n01 is a switch to XCUITest, so
  the walk after the taps did not run. What VoiceOver says for a toggle
  button that is off, and for n03 after a tap, was not recorded.
- **Android** (`talkback-first-run.md.txt`, the rows `c02-native-…`,
  from the first run of the C02 TalkBack walk, which also focused the
  native screen). TalkBack 17 reads an `android.widget.ToggleButton` as a
  switch with no word for its state: "n02 Bold. Switch" for the one that
  is on, and "n05 Bold. Switch" for one turned on by a click. A `Button`
  with `isSelected` is read "selected. n03 Bold. Button", and one without
  "n04 Bold. Button". n01, the toggle button that is off, was not heard:
  TalkBack focus was already on it (the same as in the F07 and F09
  native runs).
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
  test now walks the page up to three times and requires each button to
  be read, every time it is read, with the same words.
  The first run's attempt at it
  failed before reading anything: it replaced the content of the Flutter
  page, and Flutter's view stayed over it and took the click that starts
  the walk (`voiceover-web-first-run.md.txt` and
  `voiceover-web-first-run-native-html-error.txt`).

So the native toggle buttons that are nearest are read as switches by
both phone screen readers, and with no word for their state in the
readings recorded here; Flutter's `toggled` is read as a switch with its
state.

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
