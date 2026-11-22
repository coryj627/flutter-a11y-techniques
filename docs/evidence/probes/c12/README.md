# C12 probe: what Flutter's tooltips expose, and what shows and hides them

Run on 2026-11-21, Flutter 3.47.5, before the C12 examples were written.
The fixture is `probe.dart.txt`, a second entry point and not part of the
app: fourteen fixtures, `t01` to `t14`, one per route (`/t01` …). Each is
"Before tNN", the control with its tooltip, a line "tNN line under the
control" that a tooltip shown below the control lies over, and "tNN taps: N".

| # | Fixture |
| --- | --- |
| t01 | `IconButton(tooltip: 't01 Delete draft')` |
| t02 | `Tooltip(message:)` round an `IconButton` with no tooltip |
| t03 | t02 inside `MergeSemantics` |
| t04 | `Tooltip(message: 't04 Saves a PDF copy')` round a `FilledButton` "t04 Download" |
| t05 | t04 inside `MergeSemantics` |
| t06 | `MergeSemantics` round `Tooltip(message: 't06 Download')` round a `FilledButton` "t06 Download" |
| t07 | `Tooltip(message:)` on an `Icon`, which takes no focus |
| t08 | t02 with `ignorePointer: false` |
| t09 | t02 with a `richMessage` |
| t10 | t08 shown by a `Focus` listener calling `ensureTooltipVisible()` (app code; not used by C12) |
| t11 | `MergeSemantics` round `Tooltip(excludeFromSemantics: true)` round `Semantics(hint:)` round a `FilledButton` |
| t12 | t07 with `triggerMode: tap` |
| t13 | t02 with a `HardwareKeyboard` handler that calls `Tooltip.dismissAllToolTips()` on Escape (app code; not used by C12) |
| t14 | the widgets layer's `RawTooltip` on an icon-only `CupertinoButton` |

The owner ruled during the build (2026-11-21) that the examples are the
framework's tooltip configured through its own parameters, and that
nothing is built to fill a gap; t10 and t13 are kept as measurements of
what such code did, not as workarounds.

How each platform was looked at, and the raw output:

- Widget tests: `probe_test.dart.txt` and `probe2_test.dart.txt` under
  `flutter test`, as Android (`flutter_test.txt`): each fixture's nodes; a
  mouse hover, the pointer moved onto the tooltip in ten steps, ten seconds
  of hover, Escape with focus on the route and with the view unfocused,
  four Tabs, a touch held 600 ms and the tooltip 1.4 s and 1.7 s after it
  ended, a tap; the path from the control to the tooltip, step by step,
  with the mouse regions hit. A tooltip's timers start animations, so time
  is pumped in 16 ms frames: an early run pumped 500 ms at once and showed
  a hidden tooltip as shown. `probe3_test.dart.txt` dumped the tree while
  t01's and t06's tooltips were shown, which found the shown text's node
  (its output is asserted by the C12 widget tests rather than kept).
  `probe4_test.dart.txt` ran the text contrast guideline on three Material
  buttons with focus and a hover (`flutter_test_buttons.txt`).
- Web: Chromium, Playwright, `c12_probe.spec.js.txt` with
  `c12probe.config.js.txt`, against `flutter build web -t lib/probe.dart`:
  each fixture's elements, Chromium's accessibility tree, a hover, eight
  seconds of it, Escape, the pointer moved onto the tooltip, four Tabs, and
  Escape with focus in the page (`web.txt`). Whether a tooltip was drawn is
  the count of pixels in a band under the control that differ from the
  first screenshot. Round 2, `c12_probe2.spec.js.txt` (`web_round2.txt`):
  round 1's "no element focused" rows had the Back button focused, as the
  page focuses it on load, so round 2 used `blur()`; and Chromium's tree,
  every node with the fixture's text, before and while shown.
- Android: Pixel 10a emulator, Android 17, 1080 by 2424 at 420 dpi.
  `ProbeC12Test.kt.txt`, run by `probe_android.py.txt` with `am
  instrument`. `probe()`: each fixture's nodes; the long-click action
  (offered by no node); a touch held 800 ms through UiAutomation and the
  screen read over four seconds; a mouse hover injected through
  UiAutomation, five seconds of it, and the mouse moved onto the tooltip.
  `keys()`: four Tabs with `input keyevent`, Escape with focus on the
  control, a touch and Escape after it. Round 1 failed after t01 (a lookup
  just after a launch found an empty tree; `android-tree-round1.txt`);
  round 2 waited for the tree (`android-tree.txt`). `talkBack()`, with
  TalkBack on through the project's `tool/talkback.py` (which restores the
  device), moved focus to each fixture node (`android-talkback.md`,
  markers in `android-talkback-markers.txt`). No device setting was left
  changed.
- iOS: iPhone 17 simulator, iOS 27.0. `ProbeC12UITests.swift.txt`, run by
  `ios_probe.sh.txt` (`ios.txt`): `testTree` failed at t01 (an element
  went while the tree was read), after reading t01 before and 0.3 s after
  a touch held 0.8 s; `testKeys`: the tree after one and two Tabs; and a
  VoiceOver walk of each fixture from the top. No setting was changed.

## What it shows

| | Widget tests | Web | Android | iOS |
| --- | --- | --- | --- | --- |
| Shown by a hover | all | all (t14 not measured: its control's element is the row's width) | t02 to t13; t01 not, the first hover of the run | not measured |
| Pointer moved onto it | gone for a plain message (t01 to t07, t11 to t13); stays for t08, t09, t10, t14 | the same | the same | not measured |
| Under hover, 8 to 10 s | stays | stays | stays (5.6 s) | — |
| Shown by keyboard focus | none but t10 | none but t10 | none | none but t10 |
| After a touch | — | — | shown, gone 1.5 to 2 s after the touch ended | t01 shown 0.3 s after |
| Escape, focus in the app | hides (t14: hides for a frame, then the hover shows it again) | hides | hides, 300 ms after a touch (one reading each) | not measured |
| Escape, no focus in the page or view | stays; t13 hides | stays (`blur()`); t13 hides | — | — |
| Shown text in the tree | a node, inside the control in traversal order | an element; owned by the control (`aria-owns`) and added to its name where nothing came between them (t01, t03, t06) | a focusable `View` named by the text | a static text |

Names, from the trees and the screen readers (t05, a tooltip merged into a
button with text): iOS label "t05 Download\nt05 Saves a PDF copy", read
"t05 Download t05 Saves a PDF copy Button"; web name "t05 Saves a PDF copy
t05 Download"; Android name "t05 Download", tooltip text "t05 Saves a PDF
copy", read "t05 Download / Button. t05 Saves a PDF copy". t06, the same
words twice: iOS "t06 Download t06 Download Button", web "t06 Download t06
Download", TalkBack "t06 Download / Button" once.

A tooltip outside a Material button (t02, t04, t08 to t10, t13): on every
platform its text is on a node of its own and the button has none.
TalkBack read the outer node, "t02 Delete draft", then "Button"; VoiceOver
on iOS passed over the outer node and read "Button". A tooltip on an
`Icon` alone (t07, t12): TalkBack read it; VoiceOver on iOS passed over it,
though XCUITest lists it with the tooltip as its label.

## Findings

- A plain-message tooltip, and `IconButton.tooltip`, cannot be hovered:
  FL-247.
- No tooltip shows on keyboard focus: FL-248.
- While shown, a tooltip's text is a node of its own: FL-249.
- A `RawTooltip` sits over its control by default: FL-250 (t14).
- A tooltip is part of the name on iOS and the web: FL-251 (t05, t06).
- VoiceOver on iOS passes over a node with only a tooltip: FL-252.
- A `Tooltip` round a Material button misses it: FL-040, extended.
- Escape on the web with no focus in the page: FL-482, extended.
- A `FilledButton` with focus and a hover is 4.28:1: FL-253
  (`flutter_test_buttons.txt`).
- The default tooltip box is 4.94:1 text on box in light mode and 17.05:1
  in dark (`flutter_test.txt`, "colours").

## C12's Android suite at CI's size

After the examples were built, C12's Android tree tests ran once at the CI
emulator's size, 320 by 640 at 160 dpi (`android_320x640.sh.txt`, which
resets both after): the Gradle run ended "BUILD SUCCESSFUL", with
`talkBackWalk` skipped as TalkBack was off (`android_320x640.txt`).
