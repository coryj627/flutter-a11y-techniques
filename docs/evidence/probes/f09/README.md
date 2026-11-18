# F09 probe: switches

Run on 2026-11-17, Flutter 3.47.5, before the F09 examples were written. The
fixture is `probe.dart.txt` (a second entry point, not part of the app);
`F09ProbeUITests.swift.txt` is the throwaway XCUITest class that printed the
iOS tree and walked it with VoiceOver. Every fixture's label starts with its
number ("w01 Wi-Fi"). Each fixture holds its own state, so each can be
operated.

Web is the DOM of the semantics tree in Playwright's Chromium and WebKit on
macOS (the two were the same). Android is `uiautomator dump` on the
Pixel_10a emulator, Android 17. iOS is the XCUITest tree and
`XCUIVoiceOverService` on the iPhone 17 simulator, iOS 27.0. On iOS every
switch is a `Switch` with the value 1 or 0.

| # | Fixture | Web | Android | iOS (tree, VoiceOver) |
| --- | --- | --- | --- | --- |
| 01 | `SwitchListTile`, on | `role="switch"`, `aria-checked="true"`, named | `Switch`, checkable, checked, named | switch, 1; "w01 Wi-Fi Switch button on Double tap to toggle setting." |
| 02 | `SwitchListTile`, off | as 01, `aria-checked="false"` | as 01, not checked | switch, 0; "… off …" |
| 03 | `Switch` beside a `Text` in a `Row` | text, then a switch with no name | a `View` with the text, then a `Switch` with no description | static text, then a switch with no label; "w03 Wi-Fi", "Switch button off …" |
| 04 | `MergeSemantics` around a `GestureDetector`, a `Text` and a `Switch` | one switch named by the text | one `Switch` | one switch |
| 05 | `MergeSemantics` around `CupertinoListTile(title:, trailing: CupertinoSwitch, onTap:)`, the sample in the `CupertinoSwitch` documentation | as 04 | as 04 | as 04; 44 points high |
| 06 | the same without `MergeSemantics` | `role="group"` named by the title, around a switch with no name | a clickable `View` with the title, around a `Switch` with no description | an `Other` with the title, then a switch with no label; two stops |
| 07 | `SwitchListTile.adaptive` | as 01 | as 01 | as 01 |
| 08 | `Semantics(container: true, toggled:, enabled: true, label:, onTap:)` on a drawn switch | `role="switch"` named | `Switch` named | switch; "w08 Wi-Fi Switch button off …" |
| 09 | the same with `checked:` in place of `toggled:` | `role="checkbox"` | `CheckBox` | switch, the same as 08 (FL-035) |
| 10 | `SwitchListTile(onChanged: null)`, on | `aria-disabled="true"`, `aria-checked="true"` | `Switch`, checked, not enabled, not clickable | switch, 1, not enabled; "w10 Wi-Fi dimmed Switch button on" |
| 11 | `SwitchListTile` whose title is "w11 Notifications off" and becomes "… on" | the name is the title, and changes with it | as web | as web; "w11 Notifications off Switch button off …" |
| 12 | `Semantics(label:)` around a bare `Switch` | one switch named by the label | one `Switch` | one switch |
| 13 | a bare `Switch` | switch with no name | `Switch` with no description | switch with no label |
| 14 | `Semantics(container: true, explicitChildNodes: true, label:)` around two tiles | `role="group"` named by the label, the two switches inside | a `View` with the label whose children are the two `Switch`es | an `Other` with the label, read as a stop of its own, then the two switches |
| 15 | tile with a subtitle | named "w15 Wi-Fi" and the subtitle, with a line break | as web | as web |
| 16 | `ListTile(title:, trailing: Switch, onTap:)`, no `MergeSemantics` | `role="button"` named by the title, around a switch with no name | a `Button` with the title, around a `Switch` with no description | a button with the title and a switch with no label |
| 17 | `Semantics(toggled:, label:, onTap:)` with no `enabled` | as 08 | as 08 | switch, not enabled (FL-033) |
| 18 | `MergeSemantics` around a `CupertinoListTile` with a disabled `CupertinoSwitch` | `aria-disabled="true"` | not enabled | not enabled |

Fixtures 08, 09, and 17 put a `GestureDetector` under the `Semantics`
without `ExcludeSemantics`, so each also has a child button with no name
(a `role="button"` on the web, a clickable `View` on Android, a silent stop
for VoiceOver on iOS). The examples exclude it.

The VoiceOver walk on iOS stopped moving at fixture 15, at the bottom of the
first screen, so 16 to 18 were read from the tree only. TalkBack and
VoiceOver on the web were not part of the probe; what they say was recorded
with the examples.

A first pass at the keyboard on the web (Tab to each switch, then Space,
then Enter) was not reliable enough to record: the script lost the focused
element on several fixtures. It did show Space and Enter each toggling a
`SwitchListTile` in Chromium. The keyboard is checked in the examples' tests
instead.

## Native comparison on Android

The first F09 TalkBack run read every Flutter switch that was on as
"checked. on.", so a native screen was added for one run
(`ProbeNativeActivity.kt.txt`: three `android.widget.Switch` views,
declared for that run in the debug manifest) and walked by a temporary
`talkBackWalk` in `F09SwitchTest`: focus on the native switch that is off,
the one that is on, and a third after a click, then `good-tile` before and
after a click and again after focus had been away for eight seconds.
TalkBack 17.0 on the emulator, Android 17:

| Control | TalkBack |
| --- | --- |
| native, off | "OFF. n01 native off. Switch", "Double-tap to toggle" |
| native, on | "ON. n02 native on. Switch", "Double-tap to toggle" |
| native, on after a click | "ON. n03 native clicked. Switch", "Double-tap to toggle" |
| Flutter `SwitchListTile`, off | "off.", "Bluetooth", "Switch", "Double-tap to toggle" |
| Flutter, on after a click | "checked. on.", "Bluetooth", "Switch", "Double-tap to toggle" |
| Flutter, on, focus back after eight seconds | "checked. on.", "Bluetooth", "Switch", "Double-tap to toggle" |

The native "off" switch was not read when it was focused first (focus was
already on it, as in the F07 native run); the tool walked it again, and
its speech was logged under the next marker. So the extra "checked" is
specific to the Flutter node (FL-100).

## What it shows

- **The SDK's switches are right on every platform** with no extra work
  (01, 02, 07): the switch role, the on or off state, and the name from
  the tile's title. iOS reads a native "Switch button".
- **A switch beside a text is two elements, and the switch has no name**
  (03, 13). `MergeSemantics` joins them (04, 05), and so does a label
  around the switch (12).
- **A list tile with a switch at its end is two elements unless it is
  merged** (06, 16). `CupertinoListTile` does not merge its parts, which is
  why the `CupertinoSwitch` documentation wraps it in `MergeSemantics`.
  Without that, the row is a group (web) or a button (Material
  `ListTile` with `onTap`) named by the title, and the switch inside it has
  no name.
- **A label that says the state changes the name** (11). The switch's
  state is said as well, so the state is heard twice.
- **A labelled container is a group on the web**, a parent `View` on
  Android, and an element read before the switches on iOS (14), the same
  as for checkboxes in F07.
- **A disabled switch** keeps its state and is marked disabled on all
  three (10, 18).
- **FL-033 holds**: a switch with no `enabled` flag is not enabled on iOS
  (17). FL-035 holds: a checkbox is a switch on iOS (09).
