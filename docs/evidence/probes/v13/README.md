# V13 probe: how big the tappable area of a control is

Run on 2026-11-19, Flutter 3.47.5, before the V13 examples were written.
The fixture is `probe.dart.txt`, a second entry point and not part of the
app: twenty controls, `p01` to `p20`, each alone in the middle of a cell at
least 104 by 104 logical pixels with nothing tappable around it, each
labelled with its id. Every activation prints `V13PROBE TAP pNN` and is
added to the log at the top of the screen. After each frame the probe
works out, in logical pixels from the top left of the Flutter view:

- `lay`: the box the fixture takes in the layout;
- `vis`: what the eye sees as the control, the icon or the text;
- `shp`: the button's own shape, where it has one (the inner `Material` of a
  Material button, the `CustomPaint` of a `Checkbox`, the `DecoratedBox` of a
  `CupertinoButton`);
- `sem`: the rect of the fixture's semantics node through every transform,
  as `androidTapTargetGuideline` reads it.

| # | Fixture |
| --- | --- |
| p01 | `IconButton`, as the theme makes it |
| p02 | `IconButton` with `tapTargetSize: MaterialTapTargetSize.shrinkWrap` |
| p03 | `IconButton` with `visualDensity: VisualDensity.compact` |
| p04 | `IconButton` with `padding: EdgeInsets.zero`, `constraints: BoxConstraints()`, `iconSize: 18` |
| p05 | p04 with `shrinkWrap` |
| p06 | `TextButton`, as the theme makes it |
| p07 | `TextButton` with `shrinkWrap`, `minimumSize: Size.zero`, no padding, compact |
| p08 | `Checkbox`, as the theme makes it |
| p09 | `Checkbox` with `shrinkWrap` and compact |
| p10 | `CupertinoButton` around an icon, as it comes |
| p11 | `CupertinoButton` with `padding: EdgeInsets.zero`, `minimumSize: Size(18, 18)`, an 18 pixel icon |
| p12 | `CupertinoButton` with `sizeStyle: CupertinoButtonSize.small` |
| p13 | `Semantics(button: true)` around `GestureDetector` around an 18 pixel icon |
| p14 | `Semantics(button: true)` around `Padding(all: 15)` around p13's `GestureDetector`: padding outside the detector |
| p15 | `GestureDetector(behavior: HitTestBehavior.opaque)` around a 48 by 48 `SizedBox` with the icon in its centre |
| p16 | p15 with the default behaviour, `HitTestBehavior.deferToChild` |
| p17 | `InkWell` around an 18 pixel icon |
| p18 | A `TextSpan` with a `TapGestureRecognizer` in a sentence: "Go p18link now" |
| p19 | `GestureDetector(behavior: opaque)` around `Padding(all: 15)` around the icon: padding inside the detector |
| p20 | `ElevatedButton`, for comparison |

Each platform then tapped at points 2 logical pixels (2 dp, 2 pt, 2 CSS
pixels) inside and outside the right and bottom edges of `vis`, `shp`, and
`sem`, on a line through the middle of what is painted. Each tap was
followed, in the same launch, by a tap at the fixture's centre, the
positive control: a result is `HIT` if both acted, `miss` if only the
centre did, and is marked `(control FAILED)` if the centre did not. No
control failed in the results below.

How each platform was looked at, and the raw output:

- Flutter test: `probe_test.dart.txt`, as Android, iOS, and macOS (what a
  web build is in a browser on a Mac), at the probe's own text scale 1 and
  2. Output: `flutter_test.txt`. The test font is not a real font, so text
  widths there differ from the devices'; sizes of icons and paddings do not.
- Android: Pixel emulator, Android 17 (API 37), 1080 by 2424 pixels at
  420 dpi (density 2.625). `android_probe.py.txt`: bounds from
  `uiautomator dump`, taps with `adb shell input tap`, activations read
  from logcat. Then the device's font size was set to 2.0 with
  `settings put system font_scale 2.0`, measured, and put back to 1.0 (the
  last line of the output). Output: `android.txt`. After the examples were
  built, `android_link_dump.sh.txt` dumped the tree of
  `/t/V13/good-inline-link` once, for the order of its nodes (FL-413).
  Output: `android_link_dump.txt`.
- iOS: iPhone 17 simulator, iOS 27.0, `V13ProbeUITests.swift.txt` (run by
  `ios_probe.sh.txt`): frames from XCUITest, taps with
  `XCUICoordinate.tap()`, activations read from the probe's log text.
  Output: `ios.txt`.
- Web: Chromium on macOS, Playwright, `v13_probe.spec.js.txt` with
  `v13probe.config.js.txt`: element boxes, Chromium's accessibility tree,
  mouse clicks, and the probe's text scale 2. Output: `web.txt`. Round 2,
  `v13_probe2.spec.js.txt`: what `document.elementFromPoint` finds near
  small fixtures. Output: `web_round2.txt`. Round 3,
  `v13_probe3.spec.js.txt`: Chromium as a phone. Output: `web_round3.txt`.

## Sizes

Logical pixels. On Android the bounds in `android.txt` divided by the
density, 2.625, agree with Flutter's own numbers to the pixel's rounding
(17.9 dp for 18). On iOS XCUITest's frames, in points, are Flutter's
numbers. On the web each element's box, in CSS pixels, is Flutter's
numbers (`window.devicePixelRatio` 1). So on all three the accessibility
tree reports the semantics node's rect, and one logical pixel is one dp,
one pt, or one CSS pixel.

| # | Android, iOS: `sem` (`shp`) | Web, desktop Chromium on macOS: `sem` | What it is |
| --- | --- | --- | --- |
| p01 | 48 by 48 (40 by 40) | 40 by 40 | `IconButton`: padded on Android and iOS, not on the web here |
| p02 | 40 by 40 | 40 by 40 | `shrinkWrap`: the 40 pixel button alone |
| p03 | 40 by 40 (40 by 32) | 40 by 32 | compact: the shape loses 8 in height; the padding keeps 40 on Android and iOS |
| p04 | 48 by 48 (18 by 18) | 18 by 18 | no padding or constraints: padded to 48 on Android and iOS, the icon's size on the web |
| p05 | 18 by 18 | 18 by 18 | no padding, no constraints, `shrinkWrap` |
| p06 | 64 by 48 (64 by 40) | 56 by 32 | `TextButton` |
| p08 | 48 by 48 | 40 by 40 | `Checkbox` |
| p09 | 32 by 32 | 32 by 32 | `Checkbox`, `shrinkWrap` and compact |
| p10 | 60.4 by 52.4 | 60.4 by 52.4 | `CupertinoButton`, the same everywhere |
| p11 | 18 by 18 | 18 by 18 | `CupertinoButton` with a smaller `minimumSize` |
| p12 | 42 by 30 | 42 by 30 | `CupertinoButtonSize.small`, whose minimum is 28 |
| p13, p17 | 18 by 18 | 18 by 18 | `GestureDetector` or `InkWell` around an icon: the icon's size |
| p14, p16, p19, p15 | 48 by 48 | 48 by 48 | see the taps below |
| p18 | 56 by 26 (Android), 57 by 26 (iOS); the text is 20 high | 56 by 26 | the span's text box plus 4 on each side |

Why the web differs (read in the source): `ThemeData` makes
`materialTapTargetSize` `padded` and `visualDensity` standard on Android,
iOS, and Fuchsia, and `shrinkWrap` and compact on macOS, Linux, and
Windows (`material/theme_data.dart`, `VisualDensity.defaultDensityForPlatform`).
A web build takes the platform from the browser: the engine reads
`navigator.platform` first, so Chromium on a Mac is macOS
(`ui_web/src/ui_web/browser_detection.dart`). Round 3 set
`navigator.platform` to "Linux armv8l" with the Pixel 7 user agent, what an
Android phone's browser reports, and Flutter's platform was Android, with
`padded` and standard density: p01 48 by 48, p04 48 by 48, p06 64 by 48,
p08 48 by 48, the same as on the Android emulator. With the Pixel 7
descriptor alone, `navigator.platform` stayed "MacIntel" and the platform
stayed macOS (round 1, second half).

At 200% text (the probe's linear text scale on all three, and the Android
device's own font size 2.0): icon buttons, checkboxes, Cupertino icon
buttons, and the hand-made controls keep their size; text buttons and the
text span grow with their text. On the Android emulator at font size 2.0
the 20 pixel line of text became 37 (Android scales text by less than the
setting at large sizes), and p07, a text button with no padding, grew from
24 by 20 dp to 44.6 by 37.0 dp.

## Taps

The same on Android, iOS, and in `flutter_test` for every fixture:

- **The padding a Material button adds takes taps.** p01, p03, p04, p06,
  p20: a tap 2 pixels outside the shape, inside the 48 pixel box, acts;
  2 pixels outside the box does not. Read in the source:
  `_RenderInputPadding.hitTest` in `material/button_style_button.dart`
  sends a hit anywhere in the padded box to the centre of the button.
- **`shrinkWrap` removes it** (p02, p05, p07, p09): 2 pixels outside the
  shape does nothing.
- **A `CupertinoButton` takes taps over its whole `minimumSize` box**
  (p10, p12), including where nothing is painted around the icon.
- **A `GestureDetector` takes taps only where its child does, unless its
  `behavior` says otherwise.** p13, p17: the 18 pixel icon only. p16: a 48
  pixel `SizedBox` with the icon in its centre still takes taps only on the
  icon, because `deferToChild` asks the children and an empty `SizedBox`
  and `Center` answer no. p15 (`opaque`) and p19 (padding inside an opaque
  detector) take taps over all 48.
- **The semantics node can be bigger than what takes taps.** p14 (padding
  outside the detector) and p16 report a 48 by 48 node on all three
  platforms, and `androidTapTargetGuideline` reads 48 by 48, while a tap 2
  pixels inside the node's edge does nothing on Android and iOS: only the
  18 pixel icon acts. p18's node is the text plus 4 pixels on each side
  (read in the source: `RenderParagraph.assembleSemanticsNode` floors and
  ceils the span's text boxes and adds 4.0 on each side), and a tap 2
  pixels inside the node's edge, outside the text, does nothing on Android
  and iOS.

On the web, desktop Chromium, with the mouse, differently:

- **A click on a tappable element is the element's, whatever Flutter's hit
  test would say.** p14 and p16 acted on a click anywhere in their 48 by
  48 element, and p18 on a click 2 pixels inside the bottom of its `<a>`,
  below the text. Read in the engine source: with semantics on, a
  `pointerdown` on an element with `flt-tappable` starts the
  `ClickDebouncer` (`pointer_binding.dart`); when the browser's `click`
  follows, the engine sends `SemanticsAction.tap` to that node and drops
  the pointer events. The app turns semantics on at start on the web
  (`lib/main.dart`), so this is every click there, not only a screen
  reader's.
- **A small element's label text spills out of it and takes clicks.** p04,
  p05, p11, p13, and p17, all 18 by 18, acted on a click 2 pixels to the
  right of their box. Round 2: the element there is still the fixture's
  `flt-semantics`, whose label is its text content and overflows to the
  right (`overflow: visible`); 6 pixels to the right it is the
  `flutter-view`. Below the box (2 pixels outside the bottom edge) nothing
  acts.
- Otherwise the same as Android and iOS: 2 pixels outside every node's
  edge did nothing, except for the spilled label above.

Round 1's second half, touches with Chromium as a Pixel 7 (platform
still macOS), counted every tap near a fixture as acting, outside its
edges too; that is not explained and is not used. Round 3 found that one
touch tap at a fixture's centre acts once, with the platform macOS or
Android, so the double count is not a tap giving two activations.

## Round 2: an inline link read in its sentence that takes keyboard focus

After review of the first build, whose `good-inline-link` was read out of
its sentence (FL-413; that build's VoiceOver transcripts are kept here as
`voiceover_ios_round1_widgetspan.md.txt` and
`voiceover_web_round1_widgetspan.md.txt`). `probe2_test.dart.txt` under
`flutter_test`, as Android, prints each fixture's semantics nodes in
traversal order and what two Tabs, Enter, and Space do (output:
`flutter_test_round2.txt`). Its last line per fixture also counts a tap at
the paragraph's centre, which is not on the link, so for `q2` it says 0;
ignore that count.

| # | Fixture | Order in the tree | Keyboard |
| --- | --- | --- | --- |
| q1 | `WidgetSpan` with the link (no `MergeSemantics`) | one node, "Read the", the link text, "before you set off.", that is the link | Tab reaches it; Enter and Space act |
| q2 | `TextSpan` with a `TapGestureRecognizer` | "Read the ", link, " before you set off.": in order | Tab never reaches it; Enter does nothing |
| q3 | q1 with a `semanticsIdentifier` on the text before the link | link first, then "Read the ", then " before you set off." | reaches and acts |
| q4 | the same with the identifier on the text after | link first, as q3 | reaches and acts |
| q5 | q3 with the link in `Semantics(container: true, sortKey: OrdinalSortKey(0.5))` | "Read the ", link, " before you set off.": in order | reaches and acts |
| q6 | q5 with `MergeSemantics` around it, as `TestId` builds it | link first: the sort key is lost | reaches and acts |
| q7 | q5 with the test identifier on the same container | in order, the identifier on the link | reaches and acts |

The first build's `good-inline-link` was a `WidgetSpan` inside `TestId`,
which is like q1 with `MergeSemantics`: there the paragraph's own node
kept the text and the link was a separate node after it.

q7 became `good-inline-link`. On the web (`web_round4.spec.js.txt`, output
`web_round4.txt`) its sentence is three elements in order, the text before,
the `<a>` link, and the text after; Chromium's tree has the link and the
two runs of text; and the second Tab focuses the link. The example's own
tests and transcripts on every platform are the rest of the evidence.

## What it shows

- **The rect each platform's accessibility tree reports is Flutter's
  semantics node**, converted to dp, pt, or CSS pixels; none of them
  reports where a tap is taken.
- **On Android and iOS a node can be bigger than its hit area**, and then
  the guideline in `flutter_test` and any tool that reads the tree say the
  target is bigger than it is (FL-410). On the web the node is the target,
  because the engine turns a click on the element into a tap action
  (FL-411).
- **A Material control's padded target follows the platform**, and on the
  web the platform is the browser's operating system: a desktop browser
  gets no padding and compact density (FL-412). Default Material controls
  stay at 32 pixels or more there; one with its padding and constraints
  taken away is the size of its icon.
- **`MaterialTapTargetSize.shrinkWrap` and small `CupertinoButton`
  minimum sizes give targets under 24 on every platform.** Compact density
  alone takes 8 pixels off and stays over 24 on its own (p03, 40 by 32 at
  the least).
