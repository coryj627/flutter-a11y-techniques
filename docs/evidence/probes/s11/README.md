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

Orders are written with the fixture's part names; "A0..A3" is a whole
column joined into one node.

| # | The order on every layer (widget tests, the web document and Chromium's tree, Android tree, TalkBack, VoiceOver on iOS), but where the row says otherwise |
| --- | --- |
| r01 | A0, B0, A1, B1, A2, B2, A3: row by row |
| r02 | A0..A3, B0..B2: each column one node |
| r03 | A0, A1, B0, B1, B2, A2, A3: part of each column down it, where the rows overlap |
| r04 | row by row, as r01 |
| r05 | row by row, as r01: built by rows or by columns makes no difference |
| r06 | A0, A1, A2, A3, B0, B1, B2: the column order |
| r07 | the column order, as r06 (a key with no container works) |
| r08 | A0, B0, A1, A2, A3, B1, B2: the unkeyed B0 stays second (FL-340) |
| r09 | row by row, as r01: the keys inside `MergeSemantics` count for nothing (FL-341) |
| r10 | B0..B2, A0..A3: the right column first |
| r11 | B0..B2, B btn, A0..A3, A btn; Tab: A btn, then B btn (FL-420) |
| r12 | as r11; Tab: B btn, then A btn |
| r13 | A0..A3, A9 grafted, B0..B2: the grafted text read in the left column; on the web this is Chromium's accessibility tree, through `aria-owns`, and the document's order is A0..A3, B0..B2, A9 grafted |
| r14 | B0..B2, A0..A3: in a right-to-left `Directionality`, with the columns' places swapped on the screen, still read left first |
| r15 | A0..A3, A btn, B0..B2, B btn; Tab: A btn, then B btn |
| r16 | A0, A1, A2, A3, B0, B1, B2: each column kept, each part its own node |
| r17 | A0..A3 (on the right), then B0..B2: with the `Row`'s semantics given `textDirection: rtl`, read right first |
| r18 | B0, B1, B2, A0, A1, A2, A3 |
| r19 | B0, B1, B2, B btn, A0 .. A3, A btn; Tab: B btn, then A btn |
| r20 | A0, A1, A2, A3, A btn, B0, B1, B2, B btn; Tab: A btn, then B btn |

- **The order is the framework's.** For nineteen of the twenty
  fixtures, the widget tests' traversal order (`flutter_test.txt`, at both
  sizes), the document's order on the web and the order of Chromium's
  accessibility tree (`web.txt`, "dom order" and "ax order", at both
  sizes), the Android tree (`android-tree.txt`), the stops TalkBack's own
  "next" moved to (`android-talkback-order.txt`, and what it said,
  `android-talkback.md`), and the stops VoiceOver's `moveForward()` moved
  to on iOS (`ios.txt`, "VO" lines) were the same. The exception is r13
  on the web: the document's order there is A0..A3, B0..B2, A9 grafted,
  the grafted text last, while Chromium's accessibility tree has A0..A3,
  A9 grafted, B0..B2, as every other layer does. The left column's element
  has `aria-owns` naming the grafted text's element (`web.txt`, r13
  "aria-owns/flowto", the only fixture with one), and Chromium's tree
  follows it. Which of the two VoiceOver on the web follows for r13 was
  not measured: no web VoiceOver walk was made in the probe.
  On Android each node's traversal-after link is the node before it
  (`android-tree.txt`).
- **TalkBack's own navigation can be driven.** Search (Meta) and Right on
  a keyboard registered with the shell's `uinput` tool moved TalkBack's
  focus to the next node; Alt and Right did not, at the first press of each of the twenty fixtures (
  "Alt+Right did not move", in `android-talkback-order.txt`). Earlier
  techniques found that a swipe, `input swipe`, and `input keycombination`
  did not move it (S03, C04).
- **XCUITest's own list of elements is not VoiceOver's order** once an
  element has children: it lists an element's children after the
  elements beside it (`ios.txt`, "element order", r11 to r13 and r15 to r20, where the
  "After" line comes before the columns). For the flat fixtures it was the
  same as VoiceOver's.
- **Tab** went by position in every fixture without a focus order, the
  left button before the right one (r11, r15, r20), and with
  `OrderedTraversalPolicy` and a `FocusTraversalOrder` round each column's
  group the right one first (r12, r19): in the widget tests, Chromium
  (Back first), the Android emulator (`uinput` keyboard, Tab and
  Shift+Tab; the first Tab after opening reached no node, then Back came
  next in r11 and after the last button in the others), and the iOS
  simulator (one to three Tabs then Space, which pressed nothing after one
  Tab; Shift+Tab not sent). In
  Chromium, r11's Tab never left the page: Flutter's last control, the
  right button, is not the document's last (FL-421); Shift+Tab got out.
- **Right-to-left** (r14, r17, and `flutter_test_round2.txt`): a
  `Directionality` round the columns swaps their places on the screen but
  not the reading order, which still starts at the left; a `Semantics`
  with `textDirection: TextDirection.rtl` round them starts it at the
  right. The text direction the order is sorted by is taken from the
  nearest node above that has one, and in these fixtures that was a node
  of the app's own above the screen, left to right (round 2's
  "ancestors" line). In an app made right-to-left only with
  `Directionality` in `MaterialApp.builder`, with an English locale, the
  columns were still read left first (round 2). An app in a right-to-left
  locale was not tried; S11 does not cover right-to-left.
- **Plain HTML** (`web.txt`, "html" lines): two columns written one after
  the other and laid out side by side with flex are read one, then the
  other; the same parts written row by row in a grid are read row by row;
  CSS `order` moves a column on the screen and not in the reading order.
  The document's order decides, as Understanding 1.3.2's C27 says.
