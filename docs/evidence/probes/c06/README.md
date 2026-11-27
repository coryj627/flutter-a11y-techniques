# C06 probe: what Flutter's widgets give a single disclosure

Run on 2026-11-22, Flutter 3.47.5, before any C06 example was written.
C05 Accordion's probe (`docs/evidence/probes/c05/`, on the branch
`c05-accordion`, not merged when this was run) had already measured
`ExpansionTile`, `CupertinoExpansionTile`, `ExpansionPanelList` and
`Expansible` as an accordion of two sections. This probe measures what a
single disclosure needs that C05 did not: one control on its own, the
`ExpansionTile` parameter that makes its header a button
(`internalAddSemanticForOnTap`) without anything else added, Material's
`ExpandIcon` used as its documentation says, and what is announced on the
web when the state changes. It repeats `ExpansionTile` and
`CupertinoExpansionTile` as they come, as the baseline in the same runs.

The fixture is `probe.dart.txt`, a second entry point and not part of the
app: four fixtures, one per route (`/d01` …). Each is one disclosure, "dNN
Details", closed at the start, between a "Before dNN" text and a "dNN end"
text. Its panel holds the text "dNN panel text" and a button "dNN panel
button".

| # | Fixture |
| --- | --- |
| d01 | `ExpansionTile`, as it comes |
| d02 | `ExpansionTile(internalAddSemanticForOnTap: true)`, nothing else added |
| d03 | `ExpandIcon` and a `Text` in a `MergeSemantics`, as `ExpandIcon`'s documentation says ("it should be combined with a label using MergeSemantics"); the panel built while it is expanded |
| d04 | `CupertinoExpansionTile`, as it comes |

Framework source read, at the pin:

- `material/expansion_tile.dart`: the header is a `ListTile` with
  `internalAddSemanticForOnTap` passed through (default false, documented
  as "a temporary flag to help changing the behavior of ListTile onTap
  semantics"); no `expanded` is set; the state is in a hint
  (`collapsedHint`/`expandedHint`, with "double tap to expand" or "to
  collapse" added where `defaultTargetPlatform` is iOS or macOS); on
  Android a live region labelled with the same word; on iOS
  `sendAnnouncement` after a second, elsewhere `sendAnnouncement` at once.
- `material/expand_icon.dart`: an `IconButton` inside
  `Semantics(onTapHint: 'Expand' or 'Collapse')`; no label, no `expanded`.
  Its documentation: "The expand icon does not include a semantic label for
  accessibility. In order to be accessible it should be combined with a
  label using MergeSemantics."
- `cupertino/expansion_tile.dart`: a `CupertinoListTile` inside
  `Semantics(hint:, onTapHint:)`; no `expanded`, no button.
- No widget in `material/`, `cupertino/` or `widgets/` sets `expanded` for
  a disclosure. The ones that do set it are menus and drop-downs
  (`dropdown.dart`, `dropdown_menu.dart`, `menu_anchor.dart`,
  `popup_menu.dart`).

How each platform was looked at, and the raw output:

- Widget tests (the harness, as Android and as iOS):
  `probe_test.dart.txt`, run as `flutter test` (`probe_test.txt`): the
  semantics tree closed and after a tap on the header's text, and where
  seven Tabs go. In the widget tests the tap on d03's text does not open
  it, as only the icon takes pointer input; `probe_d03_test.dart.txt` (`probe_d03_test.txt`) performs
  the merged node's tap action instead and reads its tap hint before and
  after.
- Web: Chromium, Playwright, `c06_probe.spec.js.txt` with
  `c06probe.config.js.txt`, against `flutter build web -t lib/probe.dart`
  (`web.txt`). For each fixture: the semantics DOM and Chromium's
  accessibility tree, closed and after a click; the element with DOM focus
  after each Tab; a second click; then, from fresh loads, Tab to the header
  and Enter, and Space, each pressed twice; and, all along, what is written
  to Flutter's announcement elements (a `MutationObserver`). A key that
  did nothing would have been followed by a click, the positive control.
  Last, plain HTML: a `details` element and APG's disclosure button.
- Android: Pixel emulator, Android 17 (`SDK_INT 37`), 1080 by 2424 at
  420 dpi. `ProbeC06Test.kt.txt`, run by `probe_android.py.txt` with
  `am instrument` (`probe_all.sh.txt`): `probe()` dumps every node with
  its expanded state (API 36) and actions, performs `ACTION_CLICK` on the
  header, dumps again, and clicks again (`android-tree.txt`); `keys()`
  sends Tab, Enter and Space with `input keyevent` (`android-keys.txt`);
  `talkBackWalk()`, through the project's `tool/talkback.py`
  (`run_with_talkback`, which restores the device), puts TalkBack's focus
  on the header, performs `ACTION_CLICK` with focus left there, moves focus
  to the panel's text and back to the header, and clicks again
  (`android-talkback.md`).
- iOS: iPhone 17 simulator, iOS 27.0, `ProbeC06UITests.swift.txt` run by
  the same script (`ios.txt`): the XCUITest tree, a tap and a second tap;
  one to three Tabs and then Enter or Space, each from a fresh launch; with
  VoiceOver on, a walk from the top, then the cursor put on the header,
  XCUITest's `doubleTap()` at it, what was said in the four seconds after,
  four more moves, and a second walk from the top. As C04 measured (probe
  round 3), that double tap is a tap at the element's place with VoiceOver
  on, not VoiceOver's own activation of its cursor, which
  `XCUIVoiceOverService` cannot make; what VoiceOver's own double tap,
  made by a person, does here was not measured.

## Widget tests (`probe_test.txt`, `probe_d03_test.txt`)

- d01: the header is a node "d01 Details", focusable, with a tap action,
  `selected: false`, hint "Collapsed" (Android) or "Collapsed\n double tap
  to expand" (iOS); no button flag; no expanded state. On Android it sits
  inside a live region node labelled "Collapsed", whose focus is blocked.
  Tab: Back, then the header; once open, Back, the header, the panel's
  button.
- d02: as d01, with the button flag.
- d03: one merged node "d03 Details", a button with the tap hint "Expand",
  then "Collapse" once its tap action has opened it, then "Expand" again;
  no hint, no expanded state. Its Tab stop is the
  `ExpandIcon` (40 by 40), named by the merged node.
- d04: the header "d04 Details" has a tap action and no button flag, no
  focus, no expanded state; hint "Collapsed\n double tap to expand" on iOS
  and none on Android. Tab never stops on it. Once open, the panel's text
  joins its label ("d04 Details\nd04 panel text").

## Web (Chromium, on this Mac: `navigator.platform` "MacIntel")

| # | Header | `aria-expanded` | Description | Tab stops (from load) | Enter, Space | Written to `flt-announcement-polite` |
| --- | --- | --- | --- | --- | --- | --- |
| d01 | `role="button"`, `tabindex="0"`, `aria-current="false"` | none, closed or open | "Collapsed double tap to expand", then "Expanded double tap to collapse" | Back, d01 Details | each opens it and, pressed again, closes it; focus stays on the header | "Expanded", then "Collapsed", on a click, Enter, and Space |
| d02 | as d01 | none | as d01 | as d01 | as d01 | as d01 |
| d03 | `role="button"`, `tabindex="0"`, named "d03 Details" | none | none | Back, d03 Details | as d01 | nothing |
| d04 | `role="button"`, no `tabindex` | none | as d01 | Back only | not reached by Tab | nothing |

Once d04 is open its header and the panel's text are one element, a group
"d04 Details d04 panel text" with the description "Expanded double tap to
collapse"; the panel's button is a button of its own. A second click at
that group's middle, which is over the panel's text, did not close it; why
was not looked into.

The plain HTML comparison (`html` lines): a `details` element's `summary`
is a `DisclosureTriangle` with `expanded: false`, then `expanded: true`;
Tab reaches it, Enter opens it, Space closes it. APG's disclosure button,
`<button aria-expanded="false" aria-controls>`, is a button with
`expanded: false`.

## Android (17)

| # | Header node, closed | Expanded state (API 36) | Open | Tab, then Enter or Space |
| --- | --- | --- | --- | --- |
| d01 | `View` "d01 Details, Collapsed", click label "Expand for more details", inside a live region node "Collapsed" | undefined, closed and open | `View` "d01 Details, Expanded", click label "Collapse"; live region "Expanded" | Back, then the header; two Tabs and Enter, and two Tabs and Space, open it with focus left on it; the next Tab goes to the panel's button |
| d02 | `Button` "d02 Details, Collapsed", otherwise as d01 | undefined | `Button` "d02 Details, Expanded", otherwise as d01 | as d01 |
| d03 | `Button` "d03 Details", click label "Expand"; no live region | undefined | `Button` "d03 Details", click label still "Expand" | as d01 |
| d04 | `View` "d04 Details", click label "Expand for more details" | undefined | `View` "d04 Details\nd04 panel text", click label "Collapse" | Tab never reaches the header: every stop is Back |

`ACTION_CLICK` opened and, a second time, closed each fixture
(`android-tree.txt`).

TalkBack (`android-talkback.md`), with focus on the header, then on the
click with focus left there, then on the panel's text (on Back for d04,
whose open panel text is part of its header), then on the header again,
then on a second click:

| # | Closed | On the click | Open | On the second click |
| --- | --- | --- | --- | --- |
| d01 | "d01 Details, / Collapsed / Double-tap to Expand for more details" | "Expanded" | "d01 Details, / Expanded / Double-tap to Collapse" | "Collapsed" |
| d02 | "d02 Details, / Collapsed / Button / Double-tap to Expand for more details" | "Expanded" | "d02 Details, / Expanded / Button / Double-tap to Collapse" | "Collapsed" |
| d03 | "d03 Details / Button / Double-tap to Expand" | nothing | "d03 Details / Button / Double-tap to Expand" | nothing |
| d04 | "d04 Details / Double-tap to Expand for more details" | nothing | "d04 Details d04 panel text / Double-tap to Collapse" | nothing |

d03's click label stays "Expand" once it is open, in the tree and in what
TalkBack says. In the widget test (`probe_d03_test.txt`) the same node's
tap hint does change, to "Collapse" and back. Why Android keeps "Expand"
was not found. "Nothing" on a click is the walk's capture for that marker;
it was not checked against a live capture here. C06's own TalkBack walk
later declared the clicks of d03's and d04's examples silent rows, with a
liveness row after each, and both were silent
(`docs/evidence/C06/talkback-android.md`).

## iOS (27.0)

Every "double tap" here is XCUITest's `doubleTap()` at the element with
VoiceOver on: a tap at its place, not VoiceOver's own activation (see
above).

| # | Header to XCUITest | VoiceOver, closed | In the four seconds after XCUITest's double tap | Open, read from the top | Two Tabs, then Enter or Space |
| --- | --- | --- | --- | --- | --- |
| d01 | static text, no value | "d01 Details Collapsed double tap to expand" | "Expanded" (the tile's announcement) | "d01 Details Expanded double tap to collapse", then "d01 panel text", "d01 panel Button" | each opens it |
| d02 | button, no value | "d02 Details Button Collapsed double tap to expand" | "Expanded" | "d02 Details Button Expanded double tap to collapse", then the panel | each opens it |
| d03 | button, no value | "d03 Details Button" | nothing more; it did not open | (it did not open) | each opens it |
| d04 | static text; once open "d04 Details\nd04 panel text", other (type 1) | "d04 Details Collapsed double tap to expand" | nothing more; it opened | "d04 Details d04 panel text Expanded double tap to collapse", then "d04 panel Button" | nothing, after one, two, or three Tabs |

XCUITest's tap at d03's place opened nothing, in `testTree` and with
VoiceOver on. The element's middle is over the text, and in the widget
tests a tap on the text opened nothing either, while the node's tap action
did: only the `ExpandIcon` at the row's end takes taps (source read). Android's click action and the web's click, which act on the node,
opened it. A second tap at d04's middle, once open, did not close it; that middle
is over the panel's text, and why was not looked into.

One Tab and then Enter or Space opened nothing in any fixture, and nor did
three. Whether Back took them was not read: the probe app's first screen
lists every fixture, and the probe's check that the fixture was still on
screen would have found it on that list too (the C05 probe had the same
gap).

UIKit's own reading of a button with an expanded status, for comparison,
is in the C05 probe (`testNative`): "n01 Shipping Button Collapsed
Double-tap to expand", and SwiftUI's `DisclosureGroup` "n03 Shipping
Button Collapsed Double-tap to expand". d02 is read in the same words, but
there the state is the tile's hint text: XCUITest shows no value and Flutter
passes no expanded state to iOS (C05's FL-260).

## What the probe found

- **None of the four fixtures exposes an expanded state, on any platform
  measured.** None sets `expanded`: no `aria-expanded` in Chromium,
  expanded state "undefined" on Android 17, no value on iOS 27.0. Where
  the state reaches a screen reader at all, it is text: in the name on
  Android ("d01 Details, Collapsed"), a hint on iOS ("Collapsed double tap
  to expand"), the accessible description in Chromium on this Mac
  ("Collapsed double tap to expand"; on Linux and Windows "Collapsed", by
  C05's tests with `navigator.platform` set).
- **`ExpansionTile` as it comes (d01) is not a button on Android 17 or iOS
  27.0** (a `View`; static text), and is one in Chromium. The same as
  C05's p01.
- **`ExpansionTile(internalAddSemanticForOnTap: true)` (d02) is a button
  on all three**, named by its title, with the state as text as above. Tab
  reaches it on all three; Enter and Space open it on all three, and
  close it again in Chromium (closing by a key was not tried on Android or
  iOS here). Its change is announced: "Expanded", then "Collapsed" on a
  second click, by TalkBack (the tile's live region); "Expanded" by
  VoiceOver on iOS after XCUITest's double tap (closing not listened for);
  "Expanded" and "Collapsed" written to `flt-announcement-polite` in
  Chromium. Its hint, live region, and announcements are the same as
  d01's in every reading above. The parameter is documented as "a
  temporary flag".
- **`ExpandIcon` with a `Text` (d03), as its documentation says, is a
  button named by the text with no state at all**: no state word on any
  platform, the tap hint "Expand" or "Collapse" (widget tests), and
  nothing written to Chromium's announcement elements; TalkBack's capture
  on its click held nothing (not checked against a live capture). On
  Android 17 the click label stays "Expand" once it is open, in the tree
  and in what TalkBack says, while the widget tests show the tap hint
  changing; why was not found. A tap on the text opens nothing in the
  widget tests and at the element's middle on iOS (only the icon takes
  pointer input); in Chromium a mouse click at the element's middle opened
  it, as a click there is taken by the node's element (FL-411).
- **`CupertinoExpansionTile` (d04) takes no keyboard focus** in Chromium,
  on Android 17, on iOS 27.0, and in the widget tests; it is no button on
  Android and iOS, has no state word on Android, and once open its panel's
  text joins its name. The same as C05's p06.
- **Keyboard**: d01 to d03 are reached by Tab after Back. In Chromium
  Enter and Space open and close each, with focus left on it; on Android
  17 two Tabs and Enter, or Space, open each with focus left on it, and
  the next Tab goes to the open panel's button; on iOS 27.0 two Tabs and
  Enter or Space open each. The widget tests read the Tab stops only.
- **Plain HTML**: `details` and `summary` are a disclosure triangle with
  an expanded state in Chromium, and APG's
  `<button aria-expanded="false">` a button with one.

## C06's first iOS VoiceOver run

`voiceover-ios-first-run.md.txt` is the tool's transcript of the first
iOS VoiceOver run of C06's examples, kept as it was. Every reading was as
expected but one: open, `bad-cupertino-expansion-tile`'s control and its
panel's text are one utterance longer than the 64 characters
`XCUIVoiceOverService` returns, and it was cut short ("Details Orders ship
in two days. Expanded double tap to collaps"), as C05 found for the same
widget. The expectation is now that cut reading. In the same run of the
tree tests, the check that one element, once that tile is open, has a
label that starts with "Details" and holds the panel's text found none,
read straight after the panel was found on screen; the check now waits
for it, and logs every element that holds the text.

## C06's Android tests at CI's screen size

`android_320x640.sh.txt` runs C06's Android tree tests once at the CI
emulator's size, 320 by 640 at 160 dpi, on the local emulator, and resets
both after; `android_320x640.txt` is its output (Gradle's lines and the
JUnit results). The emulator is still Android 17 at that size.

## The focus measure

`focus_widget_test.txt` is the output of C06's widget tests of the focus
indicator: for each example a keyboard reaches, closed and open, light and
dark, how many pixels keyboard focus changed on the control and the best
contrast of a changed pixel against what was there before.
