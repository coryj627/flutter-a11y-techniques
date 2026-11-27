# S11 probe: reading and traversal order

Run on 2026-11-26, Flutter 3.47.5, before the S11 examples were written;
the examples and their tests were settled from what it found. The fixture
is `probe.dart.txt`, a second entry point and not part of the app: twenty
fixtures, `r01` to `r20`, one per route (`/r01` …). Each sits between a
"Before rNN" text and an "After rNN" text. A fixture's parts are named
"rNN A0" … for the left column (A0 is its title) and "rNN B0" … for the
right one, so that an order read out can be told at a glance; the left
column has four parts (A0 to A3) and the right three (B0 to B2). The
fixtures with buttons count the presses in the "After" line.

| # | Fixture |
| --- | --- |
| r01 | Two columns: a `Row` of two `Column`s of texts, rows level, 8 apart; no container |
| r02 | r01 with `Semantics(container: true)` round each column |
| r03 | r01 with the left parts 40 high and the right ones 24 (rows not level) |
| r04 | r01 with no space between the parts |
| r05 | Built row by row: a `Row` per line (left part, right part); no keys |
| r06 | r05 with `Semantics(container: true, sortKey: OrdinalSortKey(n))` on every part, A 1 to 4, B 5 to 7 |
| r07 | r06 with `Semantics(sortKey:)` and no container |
| r08 | r06 with B0 given no key |
| r09 | r06 with each keyed part inside a `MergeSemantics`, as `TestId` puts one |
| r10 | Two containers in a `Row`, the left one `OrdinalSortKey(1)`, the right one `OrdinalSortKey(0)` (the Android Compose reference's example 3) |
| r11 | r10 with a `TextButton` at the end of each column |
| r12 | r11 inside `FocusTraversalGroup(policy: OrderedTraversalPolicy())`, each column a `FocusTraversalGroup` in a `FocusTraversalOrder` (B 1, A 2) |
| r13 | r01 with the left column `Semantics(container: true, traversalParentIdentifier:)` and a text below the `Row` with `traversalChildIdentifier:` the same value |
| r14 | r02 inside `Directionality(textDirection: TextDirection.rtl)` |
| r15 | r02 with a `TextButton` at the end of each column, no focus group |
| r16 | r02 with `explicitChildNodes: true` on each container |
| r17 | r14 with `Semantics(container: true, explicitChildNodes: true, textDirection: TextDirection.rtl)` round the `Row` |
| r18 | r10 with `explicitChildNodes: true` |
| r19 | r12 with `explicitChildNodes: true` |
| r20 | r16 with a `TextButton` at the end of each column, each column a `FocusTraversalGroup` |

How each platform was looked at, and the raw output:

- Widget tests: `probe_test.dart.txt` under `flutter test` (as Android,
  with the test font): each fixture's labelled nodes in traversal order, at
  412 by 915 and at 320 by 640, and for the fixtures with buttons the
  stops of five Tabs. Output: `flutter_test.txt` (the probe app has no Back
  button in the widget tests: each fixture is the home route). Round two,
  `probe2_test.dart.txt`: which ancestors of a part carry a text direction,
  and r01, r02, r14, and r16 in an app that is right-to-left as a whole
  (`Directionality` in `MaterialApp.builder`). Output:
  `flutter_test_round2.txt`.
- Web: Chromium, Playwright, `s11_probe.spec.js.txt` with
  `s11probe.config.js.txt`, against `flutter build web -t lib/probe.dart`:
  at 412 by 915 and at 320 by 640, the fixture's elements with text in the
  document's order, with their depth and position; any `aria-owns` or
  `aria-flowto`; Chromium's accessibility tree in its own order; and for
  the fixtures with buttons, eight Tabs and eight Shift+Tabs. Then plain
  HTML pages for comparison (lines starting "html"). Output: `web.txt`
  (line breaks inside a value are written `\n`).
- Android: Pixel emulator, Android 17, 1080 by 2424 at 420 dpi, TalkBack
  17.0. `ProbeS11Test.kt.txt`, run by `probe_android.py.txt` with `am
  instrument`. `probe()` dumps each fixture's nodes in the tree's order,
  with the node each is to be read after (`getTraversalAfter`), and for the
  fixtures with buttons six Tabs and six Shift+Tabs from a keyboard
  registered with the shell's `uinput` tool (as V14's test does):
  `android-tree.txt`. `talkBackOrder()`, with TalkBack on: TalkBack's focus
  put on "Before rNN" by action, then TalkBack's own "next" key pressed on
  that keyboard, with the node TalkBack's focus was on after each press
  (`findFocus(FOCUS_ACCESSIBILITY)`): `android-talkback-order.txt`, and
  what TalkBack said after each press, by marker:
  `android-talkback.md`.
- iOS: iPhone 17 simulator, iOS 27.0. `ProbeS11UITests.swift.txt`, run by
  `ios_probe.sh.txt`: the XCUITest elements in the order XCUITest gives
  them, with their frames; for the fixtures with buttons one to three Tabs
  then Space, each from a fresh launch; and with VoiceOver on, a walk with
  `moveForward()` from the top of the screen to the "After" line. Output:
  `ios.txt`.

## What was found

To be completed with the device results.
