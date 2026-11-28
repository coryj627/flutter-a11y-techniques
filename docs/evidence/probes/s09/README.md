# S09 probe: grouping built from the SDK

Run on 2026-11-26, Flutter 3.47.5, before the S09 examples were settled.
The fixture is `probe.dart.txt`, a second entry point and not part of the
app: one fixture per route (`/s01` …), each between a "Before sNN" text
and a "sNN taps: on=N off=N info=N" text that counts the taps that reached
each handler. Its screen is a `SingleChildScrollView` round a `Column`, as
the app's `PageScaffold` is (a first widget run in a `ListView` made each
fixture an item of its own, which merged its loose texts with the "Before"
line; that run is not kept).

| # | Fixture |
| --- | --- |
| s01 | `MergeSemantics` round each label and its value ("City" over "Boston", "Population" over "675,647"), in a `Row` of two `Column`s |
| s02 | s01 without `MergeSemantics` |
| s03 | the same table built row by row: a `Row` of the labels, then a `Row` of the values, nothing merged |
| s04 | `Semantics(container: true)` round each label and its value |
| s05 | `ListTile(title:, subtitle:)` with no `onTap` for each pair |
| s06 | `MergeSemantics` round a pair whose value has a `semanticsLabel` |
| s07 | a named group: `Semantics(container: true, explicitChildNodes: true, label:)` round the question (in `ExcludeSemantics`) and two `OutlinedButton`s, "On" and "Off" |
| s08 | `Semantics(container: true)` round the question and the buttons |
| s09 | `Semantics(container: true, explicitChildNodes: true)` round the question and the buttons, no label |
| s10 | no group: the question as plain text above the buttons |
| s11 | `Semantics(label:)` round the buttons, no container (the iOS reference's warning) |
| s12 | `MergeSemantics` round the question and the buttons |
| s13 | `CupertinoFormSection(header:)` round two `CupertinoButton`s |
| s14 | s07 with the question not excluded |
| s15 | `TextButton.icon`: an icon and its text, one target |
| s16 | `ListTile(leading: Icon, title:, onTap:)` |
| s17 | two targets for one action: an `IconButton` with a tooltip and a `TextButton` |
| s18 | `MergeSemantics` round s17 |
| s19 | s07 without `explicitChildNodes` |
| s20 | `CupertinoListTile(title:, additionalInfo:)` rows, no `onTap` (widget tests only) |
| s21 | `CupertinoListTile(title:, subtitle:)` rows, no `onTap` (widget tests only) |

s20 and s21 were added after the device builds, so they were run in the
widget tests only. The examples settled on "Founded" over "1630" in place
of "Population" over "675,647", which did not fit CI's screen at 200% text.

How each platform was looked at, and the raw output:

- Widget tests: `probe_test.dart.txt` under `flutter test` (as Android):
  each fixture's semantics tree in traversal order, the merged data of
  every node with a label or a tap action, the tap action of each node that
  has one (each from a fresh pump), six Tabs, and Enter and Space after one
  to three Tabs. Output: `flutter_test.txt`. Its Tab lines name no focused
  node (the probe's helper did not find one) and are not relied on; the
  device runs give the Tab order.
- Web: Chromium, Playwright, `s09_probe.spec.js.txt` with
  `s09probe.config.js.txt`, against `flutter build web -t lib/probe.dart`:
  the fixture's elements, Chromium's accessibility tree over the DevTools
  protocol, the ARIA snapshot, six Tabs, Enter and Space after one to three
  Tabs, and a mouse click at the centre of each element with a button role
  (each from a fresh load); then plain HTML pages for comparison (lines
  starting "html"). Output: `web.txt` (line breaks inside a value are
  written `\n`). The ARIA snapshot runs neighbouring texts into one line
  ("group: Before s02 s02 City …"), so the element lines, not the snapshot,
  show whether a label and its value are one element.
- Android: Pixel emulator, Android 17, 1080 by 2424 at 420 dpi.
  `ProbeS09Test.kt.txt`, run by `probe_android.py.txt` with `am
  instrument`: `probe()` dumps every node of each fixture with its depth
  (class, name, heading, clickable, focusable, tooltip, pane title, and on
  Android 14 and later the container title) and performs `ACTION_CLICK` on
  each clickable node; `keys()` tabs five times with `input keyevent` and
  logs the deepest focused node, then presses Enter, then Space, after one
  to three Tabs, each from a fresh launch. Output: `android-tree.txt`.
  `probe()` looked for a node again straight after a fresh launch and often
  found the screen before it (the "not found again" lines); those clicks
  are not relied on, and `keys()` reached and activated every control.
  With TalkBack on, through the project's `tool/talkback.py` (which
  restores the device), `talkBackWalk()` moves TalkBack focus to the
  "Before" line and then to each node of the fixture that has a name,
  waiting six seconds at each, and for the group fixtures launches again
  and moves focus from the "Before" line straight to "On" (`-direct-on`).
  Round 1 (`android-talkback.md`, markers in
  `android-talkback-markers.txt`) stopped at s12, where no node is named
  "s12 On" (the probe's own error); round 2 walked s13 to s19
  (`android-talkback-round2.md`, `android-talkback-markers-round2.txt`).
  In round 1 a system dialog, "Allow Android Accessibility Suite to send
  you notifications?", was spoken at `s09-s12-direct-on`; nothing in the
  probe answered it.
- iOS: iPhone 17 simulator, iOS 27.0, `ProbeS09UITests.swift.txt` run by
  `ios_probe.sh.txt`: `testTree` dumps the XCUITest tree of each fixture
  and taps each element whose label has the fixture's id, each from a
  fresh launch; `testKeys` presses one to three Tabs and Enter, and two
  Tabs and Space, from a fresh launch each, for nine fixtures (s07, s08,
  s10, s12, s13, s15 to s18); `testVoiceOver` turns VoiceOver on and moves
  forward from the top of each fixture to its taps line, logging every
  utterance. Output: `ios.txt`. XCUITest element types: 1 other, 9
  button, 48 static text.

## Widget tests

From `flutter_test.txt`:

| # | Nodes |
| --- | --- |
| s01, s04, s05 | one node per pair, "City\nBoston" and "Population\n675,647" |
| s02, s03 | four nodes, in traversal order City, Population, Boston, 675,647: both labels, then both values, for the table built by columns (s02) as for the one built by rows (s03). Flutter sorts sibling nodes by their position ([FL-420](../../../flutter-limitations.md#fl-420)); the "node" lines are in the tree's order, the "tree" lines in traversal order |
| s06 | one node, "Distance\n6 kilometres": the value's `semanticsLabel` is kept in the merge |
| s07, s08, s19 | a node "Kitchen light" whose children are the buttons On and Off |
| s09, s10, s13 | the question as a node of its own, the buttons beside it (s09: all three inside an unlabelled node) |
| s11, s14 | the question twice: a node of its own and the label of a node round the buttons |
| s12 | one button "Kitchen light\nOn\nOff" with one tap action, which runs On |
| s15, s16 | one button "App information" |
| s17 | a button with no label (its name is its tooltip) and a button "App information"; both run the same handler |
| s18 | one button "App information" (the tooltip is not in the label) |
| s20, s21 | a `CupertinoListTile`'s title and its additional information, or its subtitle, are two nodes |

## Web

From `web.txt`:

| # | Elements | Tab | Keys and clicks |
| --- | --- | --- | --- |
| s01, s04, s05 | one `flt-semantics` per pair, its text "City\nBoston" | Back only | none to press |
| s02, s03 | four text elements, City, Population, Boston, 675,647 in the page's order, for both | Back only | none |
| s07, s08, s19 | `role="group"` with `aria-label="… Kitchen light"`, holding two `role="button"` | Back, On, Off | Enter, Space, and a click run each button's own handler |
| s09, s10, s13 | the question as text, the buttons beside it, no group | Back, On, Off | as s07 (s13: Space and a click; Enter runs nothing, FL-002) |
| s11, s14 | the question as text and a `group` named by it round the buttons (s14: the question inside the group as well) | Back, On, Off | as s07 |
| s12 | one `role="button"` "Kitchen light\nOn\nOff" | Back, then that element twice | Enter or Space after two Tabs runs On, after three runs Off; a click at its centre runs On |
| s15, s16 | one button "App information" | Back, the button | Enter, Space, and a click run it |
| s17 | two buttons named "App information" | Back, both | each runs the handler |
| s18 | one button "App information\nApp information" (the tooltip is in the name on the web, FL-251) | Back, then it twice | each runs the handler |

Plain HTML in Chromium ("html" lines): a `fieldset` is a `group` named by
its `legend`; a `div role="group"` with `aria-labelledby` or `aria-label`
is a `group` with that name; a `dl` is a description list of terms and
definitions; a `button` holding an `aria-hidden` icon and text is a button
named by the text.

## Android

From `android-tree.txt`, `android-talkback.md`, and
`android-talkback-round2.md`:

| # | Nodes | TalkBack, focus moved to each |
| --- | --- | --- |
| s01, s04, s05 | one `View` per pair | "City Boston", "Population 675,647" |
| s02, s03 | one `View` per text, in the tree's order City, Population, Boston, 675,647 for both | each text alone |
| s07, s08 | a `View` "Kitchen light", not clickable, with the two `Button`s as children; no container title, no pane title | "Kitchen light"; "On / Button / Double-tap to activate", also straight from the "Before" line; "Off / Button …" |
| s09, s10 | the question's `View` beside the buttons | the same readings |
| s11 | the question's `View`, then a `View` "Kitchen light" holding the buttons | "Kitchen light" twice, then the buttons |
| s12 | one `Button` "Kitchen light\nOn\nOff", clickable | "Kitchen light On Off / Button / Double-tap to activate" |
| s13 | the header's `View`, two `Button`s | as s07: the header alone, each button without it, also straight from the "Before" line |
| s14 | the question's `View` inside a `View` named by it, with the buttons | "Kitchen light" twice, then the buttons |
| s15, s16 | one `Button` "App information" | "App information / Button / Double-tap to activate" |
| s17 | a `Button` named by its tooltip, and a `Button` "App information" | "App information. Button …" and "App information / Button …" |
| s18 | one `Button` "App information", its tooltip "App information" | "App information / Button / Double-tap to activate" |
| s19 | as s07 | as s07 |

Keys (`input keyevent`): Tab went Back, then each control in order; Enter
and Space on each ran its own handler. s12's merged `Button` took two Tab
stops; Enter after two Tabs ran On, after three Off. s17 and s18 took two
stops, both running the one handler.

## iOS

From `ios.txt`:

| # | Elements | VoiceOver, moving forward | A tap |
| --- | --- | --- | --- |
| s01, s04, s05 | one static text per pair, "City\nBoston" | "City Boston", "Population 675,647" | nothing to run |
| s02, s03 | four static texts | "City", "Population", "Boston", "675,647", for both | nothing |
| s06 | one static text "Distance\n6 kilometres" | "Distance 6 kilometres" | nothing |
| s07, s08, s19 | an element of type other "Kitchen light", and two buttons | "Kitchen light", "On Button", "Off Button" | a tap on each button runs its own; a tap at the group's centre ran Off, which is drawn there |
| s09, s10, s13 | the question as static text, two buttons | the same readings as s07 | each button runs its own |
| s11, s14 | the question twice (static text, and type other) | "Kitchen light" twice, then the buttons | each its own |
| s12 | one button "Kitchen light\nOn\nOff" | "Kitchen light On Off Button" | a tap at its centre ran Off, which is drawn there |
| s15, s16 | one button "App information" | "App information Button" | runs it |
| s17 | two buttons named "App information" (the icon's name is its tooltip) | "App information Button" twice | each runs the handler |
| s18 | one button "App information\nApp information" (the tooltip is in the label, FL-251) | "App information App information Button" | runs it |

Keys (one to three Tabs and Enter, two Tabs and Space, each from a fresh
launch): one Tab and Enter ran nothing; two Tabs then Enter or Space ran
the first control, three Tabs then Enter the second where there is one
(s07, s08, s10, s12, s13; s15 and s16 ran nothing on the third). For s12,
the merged button, two Tabs ran On and three ran Off, as on the web and
Android. For s13 Enter ran the `CupertinoButton`s on iOS, unlike the web
(FL-002).

## Native comparison (round 3)

Asked for by the principal on 2026-11-26, before FL-320 could make Android
and iOS a limitation: what does a natively named group give each screen
reader? The fixtures have the texts of `good-named-group`: a "Before nNN"
line, the question "nNN Kitchen light", buttons "nNN On" and "nNN Off",
and an "nNN end" line.

iOS: `NativeGroups.swift.txt`, a UIKit app built with `swiftc` by
`build_native_ios.sh.txt` and installed only for the run by
`ios_native.sh.txt` (never part of the Runner), driven by
`ProbeS09NativeUITests.swift.txt`. n11 a `UIStackView` with
`accessibilityContainerType = .semanticGroup` and an `accessibilityLabel`,
its question label not an accessibility element; n12 the iOS reference's
SwiftUI layout, the question as a `Text` above an `HStack` of the buttons
with `.accessibilityElement(children: .contain)` and
`.accessibilityLabel`; n13 no group. For each, and for the app's own
`good-named-group`: a snapshot of the elements; with VoiceOver on, a tap on
the line before (which puts the cursor there) and moving forward to the
end; then a tap on "On", which puts the cursor straight on it, with every
raw poll of `currentSpeech()` for three seconds (a reading counts as new
only once it differs from the one before the tap), and moving forward
from it. Output: `ios-native.txt`.

| # | Moving forward from the line before | Cursor put on "On" by a tap |
| --- | --- | --- |
| n11 (UIKit, semantic group) | "Before n11" / "n11 Kitchen light n11 On Button" / "n11 Off Button" / "n11 end" | "n11 Kitchen light n11 On Button" |
| n12 (SwiftUI, `.contain` and a label) | "Before n12" / "n12 Kitchen light" (the visible `Text`) / "n12 Kitchen light n12 On Button" / "n12 Off Button" / "n12 end" | "n12 Kitchen light n12 On Button" |
| n13 (no group) | "Before n13" / "n13 Kitchen light" / "n13 On Button" / "n13 Off Button" / "n13 end" | "n13 On Button" |
| Flutter `good-named-group` | "Example Heading" / "Kitchen light" / "On Button" / "Off Button" / "Light: not set" | "On Button" |

So on iOS a named group's label is spoken with its first control on the
way in, whether VoiceOver moves into the group or the cursor is put on the
control, and nothing is said on the way out; Flutter's labelled node is
read as a stop of its own, and its buttons as a plain button is.

Android: `ProbeS09NativeActivity.kt.txt`, an `Activity` declared in the
debug manifest for the run only (`debug_AndroidManifest_for_the_run.xml.txt`),
driven by `ProbeS09NativeTest.kt.txt` and run by `native_android.py.txt`.
n01 a `LinearLayout` holding the question (not important for
accessibility) and the two `Button`s, whose `AccessibilityDelegate` sets
`AccessibilityNodeInfo.setContainerTitle` (Android 14 and later); n02 the
same named by its `contentDescription` only; n03 no group. The Android
Compose reference has no entry for a group of controls, and Compose needs
the Compose compiler's Gradle plugin and Compose's libraries, which the
project's Android build does not have and which were not added for a
throwaway probe, so no Compose fixture was built. `nativeTree()` dumps the screen
(`android-native-tree.txt`: n01's `LinearLayout` has the container title
"n01 Kitchen light", n02's the description, n03 no node round the
buttons). With TalkBack on (Android 17, TalkBack 17.0), `talkBackWalk()`
moves TalkBack focus by `ACTION_ACCESSIBILITY_FOCUS` to the line before,
the question where it is a node, "On", "Off", and the line after, and then
from the line before straight to "On" (`android-native-talkback.md`).
`talkBackKeys()` tried to move through with TalkBack's own navigation: in
round 1 Alt and Right with `input keycombination`
(`android-native-talkback-round1.md`; round 1's walk found no button, as
the buttons' text was in capitals, and is not used), in round 2 a swipe
right with `input swipe`. Neither moved TalkBack's focus (the "after"
lines in `android-native-talkback-markers.txt`), so TalkBack's own
navigation was not measured.

| # | Focus moved to "On" | "Off" | The line after |
| --- | --- | --- | --- |
| n01 (container title) | "n01 On. Button. In n01 Kitchen light / Double-tap to activate", from the line before and straight from it | "n01 Off. Button / Double-tap to activate" | "n01 end. Out of n01 Kitchen light" |
| n02 (`contentDescription` only) | "n02 On. Button / Double-tap to activate" | "n02 Off. Button …" | "n02 end" |
| n03 (no group) | "n03 On. Button / Double-tap to activate" | "n03 Off. Button …" | "n03 end" |
| Flutter `good-named-group` (the S09 transcript) | "On / Button / Double-tap to activate", from the question and straight from the "Example" heading | "Off / Button …" | not walked |

So on Android TalkBack says a container title on the way into a group and
on the way out ("In …", "Out of …"), and nothing for a container named
only by its description, which is what Flutter's labelled node gives; at
"Before n02" it also said "Out of n01 Kitchen light", left over from the
move before.

## Web VoiceOver, first recording

Recorded by the principal on 2026-11-26 with `tool/voiceover_web.py S09`:
`voiceover-web-round1-fail.md.txt` (the transcript) and
`voiceover-web-round1-fail.log.txt`. Eleven walks of twelve were complete
and right on their first try, in Chromium and WebKit, every predicted stop
heard. WebKit's `bad-merged-group` read "" where the screen's level 1
title was expected, and every later stop in its place; the judge of the
time counted that as wrong. The judge is now S08's: an empty phrase is a
failed capture, walked again, and VoiceOver's help message is left out
(spec, section 7). The second recording, with that judge, passed 12 of 12
(`docs/evidence/probes/s09/voiceover-web-before-judge-update.md.txt`, moved from
`docs/evidence/S09/voiceover-web.md` on 2026-11-28): every reading the same as in the
first, in both browsers; WebKit's `good-tap-target` was walked twice, its
first walk's title an empty phrase.

## What this changed

- A label and its value are merged with `MergeSemantics` (`good-merged-facts`),
  and a `CupertinoListTile` needs it too (`good-cupertino`).
- A table of label and value pairs that is not merged reads both labels
  and then both values on every platform, whether it is built by rows
  (s03) or by columns (s02): Flutter orders sibling nodes by position
  ([FL-420](../../../flutter-limitations.md#fl-420)). `bad-split-facts`
  is the row build, with its rows apart, which FL-420 reads across.
- A labelled node round controls is a `group` on the web only; on Android
  and iOS the name is a stop of its own and the buttons are read without
  it, from wherever focus comes, where native groups on both are named on
  the way in (round 3): [FL-320](../../../flutter-limitations.md#fl-320),
  and Android and iOS are a limitation for a named group.
- `MergeSemantics` round controls makes one button with the first one's
  action: `bad-merged-group`, and
  [FL-243](../../../flutter-limitations.md#fl-243) extended.
- `TextButton.icon` is one target named by its text on every platform:
  `good-tap-target`. Two targets for one action (s17) read the same name
  twice and fail no criterion, so no bad example is built from it.
