# S08 probe: lists built from the SDK

Run on 2026-11-26, Flutter 3.47.5, before the S08 examples were settled;
the examples and their tests were written from what it found. The fixture
is `probe.dart.txt`, a second entry point and not part of the app: 29
fixtures, `p01` to `p29`, one per route (`/p01` …). Each sits on a screen
laid out as the app's technique screens are (a `Scaffold` whose body is a
`SingleChildScrollView` round a `Column`), between a "Before pNN" text and
a "pNN end taps=N" text with the test identifier `pNN-end`. Every item's
text starts with the fixture's id. The three groceries are "Milk", "Eggs",
"Bread".

| # | Fixture |
| --- | --- |
| p01 | `Column` of three `Text`, each starting with "• " |
| p02 | one `Text`, the items on lines of their own |
| p03 | `Semantics(role: SemanticsRole.list)` round a `Column`, `Semantics(role: SemanticsRole.listItem)` round each `Text` |
| p04 | the list role round a `Column` of plain `Text`, no list items |
| p05 | the list item role round each `Text`, no list round them |
| p06 | `ListView(shrinkWrap: true, physics: NeverScrollableScrollPhysics())` of three `Text` |
| p07 | `ListView` of three `Text` in a `SizedBox(height: 160)`: fits, does not scroll |
| p08 | `ListView.builder` of 30 `Text` ("pNN Item 1" …) in a `SizedBox(height: 200)`: lazy |
| p09 | the list role round p06, the list item role round each `Text` |
| p10 | the list role round p08, the list item role round each item |
| p11 | `Column` of three `ListTile(title:, subtitle:)`, not tappable |
| p12 | p06 with the `ListTile`s of p11 |
| p13 | p06 with three `ListTile(onTap:)` |
| p14 | `CupertinoListSection(header:)` of three `CupertinoListTile`, not tappable |
| p15 | ordered: p03 with the number in each `Text` ("1. p15 Fork the repository") |
| p16 | description list: a `Column` of term and description `Text`, plain |
| p17 | description list: each term and description in a `MergeSemantics` row |
| p18 | nested: the list role, a list item holding "Fruit" and a list of two, then a list item "Bread" |
| p19 | `SliverList.list` in a `CustomScrollView(shrinkWrap: true)` |
| p20 | `ListView.separated(shrinkWrap: true)` with a `Divider` between items |
| p21 | a horizontal `ListView` of three `Text` in a `SizedBox(height: 48)` |
| p22 | p03 with two `Text` in each item, in a `Row` |
| p23 | the list role round a `Column` of p11's `ListTile`s, each in a list item |
| p24 | the list role round a `Column` of `ListTile(onTap:)`, each in a list item |
| p25 | the list role round p14, each `CupertinoListTile` in a list item |
| p26 | p22 with a `MergeSemantics` round each item's `Row` |
| p27 | the list role round p06, no list items |
| p28 | p24 with `explicitChildNodes: true` on each list item |
| p29 | p25 with `CupertinoListTile(onTap:)` and `explicitChildNodes: true` on each list item |

How each platform was looked at, and the raw output:

- Widget tests: `probe_test.dart.txt` under `flutter test` (as Android):
  any error the framework reported while the fixture opened, every
  semantics node with its role, label, flags, actions, scroll child count,
  scroll index, and index in its parent; for p08 and p10 the items that
  are nodes, then the list dragged up 3000 pixels and the tree again; five
  Tabs. Output: `flutter_test.txt`. p10's test failed: the list item check
  was thrown again while the list was scrolled, after the probe's own
  error handler was put back (the last lines of the file).
- Web: Chromium, Playwright, `s08_probe.spec.js.txt` with
  `s08probe.config.js.txt`, against `flutter build web -t lib/probe.dart`
  (a release build): the semantics elements between "Before" and "end",
  Chromium's whole accessibility tree over the DevTools protocol (role,
  name, and properties; the depth shown is its order in the protocol's
  list and not reliable), five Tabs; for p08 and p10 the items in the page
  before and after twenty turns of the mouse wheel over the list. Then
  plain HTML pages (`ul`, `ol`, `dl`, a nested `ul`, `menu`, `div`s with
  `role="list"` and `role="listitem"`, and a `ul` with no bullets), lines
  starting "html". Output: `web.txt` (line breaks inside a value are
  written `\n`). The protocol's properties did not include `setsize` or
  `posinset` for any list item, the plain HTML ones included.
- Android: Pixel emulator, Android 17, 1080 by 2424 at 420 dpi.
  `ProbeS08Test.kt.txt`, run by `probe_android.py.txt` with `am
  instrument`: `probe()` dumps every node of each fixture (class, name,
  heading, clickable, focusable, scrollable, visible, actions, children,
  and collection and collection item information); for p08 and p10 it
  performs `ACTION_SCROLL_FORWARD` on the inner list six times and dumps
  the items after each step. `nativeTree()` dumps the native comparison,
  `ProbeNativeActivity.kt.txt` (declared for the run in the debug
  manifest): n01 a native `ListView` of three items; n02 a `LinearLayout`
  of three `TextView`s given `CollectionInfo` by an
  `AccessibilityDelegate`, the Android View reference's unnumbered list;
  n03 n02 with `CollectionItemInfo` on each item, its numbered list; n04
  (round 2) a native `ListView` of 30 items in a box that scrolls. Output:
  `android-tree.txt`, and `android-tree-round2.txt` for the native screen
  with n04. With TalkBack on, through the project's `tool/talkback.py`
  (which restores the device), `talkBackWalk()` moves TalkBack focus to
  "Before", to each node of the fixture whose name starts with its id, and
  to "end", five seconds each; `talkBackKeys()` puts TalkBack focus on
  "Before" and sends Alt and Right with `input keycombination` twelve
  times, logging where TalkBack's focus is. Output: `android-talkback.md`
  (as parsed by `talkback.parse_speech`) and `android-talkback-markers.txt`
  (the name of the node each marker was put on). Round 2,
  `talkBackRound2()`: the items round 1 missed because their text starts
  with a bullet or a number (p01, p15, and the native n02 and n03), the
  native n04, and p08 and n04 again after three `ACTION_SCROLL_FORWARD`s
  on the list (`android-talkback-round2.md`,
  `android-talkback-markers-round2.txt`). The round 1 walk of p01, p15,
  n02, and n03 has "Before" and "end" only, for that reason. p05, p09, and
  p10 did not open: their screens never reached the accessibility tree.
- iOS: iPhone 17 simulator, iOS 27.0, `ProbeS08UITests.swift.txt` run by
  `ios_probe.sh.txt`: `testTree` dumps the elements of one snapshot whose
  label or identifier has the fixture's id, and for p08 drags the list up
  150 points four times; `testVoiceOver` turns VoiceOver on and moves
  forward from the top of each fixture to its end line (45 moves at most
  for p08 and p10); `testSafari` opens the plain HTML pages of `html-pages.txt`,
  served from the Mac for the run, in Safari, and walks forward with
  VoiceOver from a tap on "Before". Output: `ios.txt`. In round 1
  `testTree` failed at p08's second drag, which started from an element
  that had scrolled away, so the fixtures after p08 have no tree dump
  there, and `testSafari` failed reading the page's elements; round 2
  (`ios-round2.txt`) is the tree from p08 on, the drag started from a
  point of the screen, and the Safari walk. XCUITest element types: 9
  button, 48 static text.

## Web

From `web.txt`:

| # | Elements | In Chromium's tree |
| --- | --- | --- |
| p01, p16, p19, p20 | a text element each | a text each; no list |
| p02 | one text element, the lines in it | one text "p02 Milk p02 Eggs p02 Bread" |
| p03, p15, p22 | `role="list"` holding three `role="listitem"`, each named by its text (`aria-label`) | `list` holding `listitem`s, level 1 |
| p04 | `role="list"` named by all three texts, with no children | a `list` named "p04 Milk p04 Eggs p04 Bread", no items |
| p05 | three `role="listitem"` with no list | three `listitem`s with no list |
| p06 | text elements inside two `flt-semantics` with no role | texts; no list |
| p07, p21 | text elements inside `role="group"` | a `group`; no list |
| p08 | text elements, items 1 to 13 of 30, inside `role="group"` with a scroll area; after the wheel, items 18 to 30 | a `group`; no list |
| p09, p10 | `role="list"` holding the scroll view's elements, which hold the `listitem`s (a release build: the check that fails in a debug build does not run) | a `list`, then a `group` (p10), then the `listitem`s |
| p11, p12 | an element per tile with `aria-current="false"`, its title and subtitle in it | a text each; no list |
| p13 | `role="button"` per tile | buttons; no list |
| p14 | a text each, the header first | texts; no list |
| p17 | an element per pair, both texts in it | a text each |
| p18 | a list item "p18 Fruit" holding a list of two items, then a list item | the inner items at level 2 |
| p23 | list items named by each tile's title and subtitle, `aria-current="false"` | `list` of `listitem`s |
| p24 | list items with `tabindex="0"`, named by the tile, no `role="button"` | `list` of focusable `listitem`s; no button |
| p25 | `role="list" aria-label="p25 Groceries"`, three list items | a `list` named by the header |
| p26 | list items each holding one text element with both texts | `list` of `listitem`s |
| p27 | `role="list"` holding the scroll view's elements and three texts, no list items | a `list` with no items |
| p28 | list items each holding a `role="button"` | `list` of `listitem`s, each holding a button |
| p29 | p25 with a `role="button"` with no `tabindex` in each list item | as p28; the tiles take no focus |

Tab: Back, then each `ListTile` with `onTap` (p13, p24, p28: as a button,
a list item, and a button); p08 and p10 have one more stop, the scroll
area (`role="group"`). No other fixture has a stop.

Plain HTML in Chromium (`web.txt`, "html" lines): `ul`, `ol`, `menu`, and
`div`s with `role="list"` and `role="listitem"` are a `list` of
`listitem`s; `ul` and `ol` have a `ListMarker` ("• ", "1. ") in each item,
which the `div`s and Flutter's items do not; `dl` is a `DescriptionList`
of `term`s and `definition`s; a nested `ul`'s items are at level 2.

## Android

From `android-tree.txt` and `android-talkback.md`:

| # | Nodes | TalkBack, focus moved to each item in turn |
| --- | --- | --- |
| p01 | a `View` per line, no collection | (round 2) each line its text alone; no list |
| p02 | one `View` named by the three lines | "p02 Milk p02 Eggs p02 Bread" |
| p03, p22, p23, p26 | an `android.widget.ListView` with no collection information, holding a `View` per item | the first "… / In list", the others their text alone; the line after the list "… / Out of list" |
| p04 | a `ListView` named by all three texts, no children | "p04 Milk p04 Eggs p04 Bread / List" |
| p05, p09, p10 | not opened: nothing but the window in the tree | |
| p06, p12, p20, p27 | a `View` with collection 3 by 1, its items with no collection item information | the first "… / In list. 3 items", the others their text alone; "Out of list" after |
| p07, p21 | a `View` with collection 3 by 1, its items with item information, rows 0 to 2 (p21, the horizontal list, too: it does not scroll, and the engine takes a list as horizontal only from its scroll actions) | "… / 1 of 3. In list. 3 items", "2 of 3", "3 of 3"; "Out of list" after |
| p08 | (round 2 as well: after three `ACTION_SCROLL_FORWARD`s, items 14 to 19 each read by its text alone) an `android.widget.ScrollView`, scrollable, collection 30 by 1, holding the items in view, 1 to 6, rows 0 to 5; after each `ACTION_SCROLL_FORWARD` the items in view, whose rows are their place among the nodes there: item 9 row 7 after step 2, item 26 row 7 after step 6 | each item its text alone: no "In list", no size, no place |
| p11 | a `View` per tile, named by its title and subtitle | each tile's text; no list |
| p13 | a `View` with collection 3 by 1 holding three `Button`s | "p13 Milk / Button. In list. 3 items / Double-tap to activate", then "… / Button / …" |
| p14 | a `View` per text, the header first | each text; no list |
| p15 | a `ListView` holding a `View` per step | (round 2) the first step "… / In list", the others their text alone; "Out of list" after |
| p16, p17, p19 | a `View` per text (p17 per pair, both texts in it) | each text; no list |
| p18 | a `ListView` holding a `View` "p18 Fruit" holding a `ListView` of two, and a `View` "p18 Bread" | "p18 Fruit" alone; "p18 Apple / In list"; "p18 Pear"; "p18 Bread / Out of list"; the line after, nothing about a list |
| p24, p28 | a `ListView` holding three `Button`s (p28: each in a `View` with no name) | "p24 Milk / Button. In list / Double-tap to activate", then "… / Button / …"; "Out of list" after |
| p25 | a `ListView` named "p25 Groceries", focusable, holding a `View` per tile | the list "p25 Groceries / List"; the first tile "p25 Milk / In list p25 Groceries"; "Out of list p25 Groceries" after |
| p29 | as p25, each tile a clickable `View` with no role | the first tile "… / In list p29 Groceries / Double-tap to activate" |
| n01 | a native `ListView`, collection 3 by 1, holding three clickable `TextView`s | "n01 Milk. 1 of 3. In list. 3 items / Double-tap to activate", "n01 Eggs. 2 of 3 …", "n01 Bread. 3 of 3 …"; "n01 end. Out of list" |
| n02, n03 | `LinearLayout`s with collection 3 by 1 (n03's items with item information) | (round 2) n02: "• n02 Milk. In list. 3 items", then each item alone, "n02 end. Out of list"; n03: "1. n03 Milk. 1 of 3. In list. 3 items", "2 of 3", "3 of 3", "Out of list" |
| n04 | (`android-tree-round2.txt`) a native `ListView`, scrollable, collection 30 by 1, holding the items in view | (round 2) "n04 Item 1. 1 of 30. In list. 30 items", "2 of 30" …; after three `ACTION_SCROLL_FORWARD`s, "n04 Item 10. 10 of 30. In list. 30 items", "11 of 30" … |

`talkBackKeys()`: Alt and Right sent with `input keycombination` never
moved TalkBack's focus off "Before" (`android-talkback-markers.txt`), on
the native screen or on any fixture, and nothing was spoken for any of
them. TalkBack's own moving to the next item was not driven, so which
stops a TalkBack swipe makes through a list, and whether it scrolls a
lazy one, was not measured.

## iOS

From `ios.txt` (types as XCUITest gives them):

| # | Elements | VoiceOver, moving forward from the top |
| --- | --- | --- |
| p01 | a static text per line, "• p01 Milk" … | "• p01 Milk", "• p01 Eggs", "• p01 Bread" (the bullet is in the utterance's text; whether it was spoken as a word was not measured) |
| p02, p04 | one static text with the three lines | "p02 Milk p02 Eggs p02 Bread" |
| p03, p06, p07, p19, p20, p21, p27 | a static text per item, no element for the list | each item's text alone |
| p05, p09, p10 | did not open: no element of the fixture | |
| p08 | items 1 to 13 of 30 as static texts when it opens; dragged up 150 points, items 3 to 22 | one stop with no speech (error 3), items 1 to 6, then "p08 end taps=0": items 7 to 30 were not reached, and the list was not scrolled |
| p11, p12, p23 | a static text per tile, its title and subtitle | each tile's title and subtitle |
| p13, p24, p28 | a button (type 9) per tile, named by its title (`ios-round2.txt`) | each tile's title and "Button" |
| p14, p25 | p14: a static text per text, the header first; p25: the header an element of type other (the list's node, named by it), then a static text per tile | "… Groceries", then each tile |
| p15 | a static text per step | each step with its number |
| p16, p17 | a static text per text (p17 per pair) | each text (p17 each pair) |
| p18 | "p18 Fruit" an element of type other (the list item holding the inner list), the others static texts | "p18 Fruit", "p18 Apple", "p18 Pear", "p18 Bread" |
| p22, p26 | a static text per item, its two texts in it | each item's two texts as one utterance |

No utterance in any Flutter walk said "list", a number of items, or a
place.

Safari, plain HTML (`ios-round2.txt`, round 2; the service gave each
item's text twice, and cut an utterance at 64 characters):

| Page | VoiceOver, moving forward from a tap on "Before" |
| --- | --- |
| `ul` | "• ul Milk … List start 1 of 3", "• ul Eggs … 2 of 3", "• ul Bread … 3 of 3 List end", "ul end" |
| `ol` | "1. ol Fork the repository … List start 1" (cut), "… 2 of 3", "… 3 of 3 List" (cut), "ol end" |
| `dl` | "dl Weight … Term", "dl 2 kg … Description", "dl Colour … Term", "dl Blue … Description" |
| nested `ul` | "• List start", "nested Fruit … 1 of 2", "◦ nested Apple … List start 1 of 2", "◦ nested Pear … 2 of 2 List end", "• nested Bread … 2 of 2 List end" |

So VoiceOver on iOS speaks lists, their size, an item's place, and a
description list's parts, for web content.

Native iOS (round 3, `ios-native.txt`; `NativeLists.swift.txt`, a
separate app built with `swiftc` by `build_native_ios.sh.txt`, installed
and driven by `ios_native.sh.txt` and `ProbeS08NativeUITests.swift.txt`,
never part of the Runner):

| # | Elements (XCUITest types) | VoiceOver, moving forward from a tap on "Before" and from the top |
| --- | --- | --- |
| n05, a UIKit `UITableView` of three rows | a table (26) holding three cells (75), each holding a static text | "n05 Milk", "n05 Eggs", "n05 Bread", "n05 end" |
| n06, a SwiftUI `List` of three `Text` rows | a collection view (32) holding three cells, each holding a static text | "n06 Milk", "n06 Eggs", "n06 Bread", "n06 end" |
| n07, a `UIStackView` of three labels | three static texts | "n07 Milk", "n07 Eggs", "n07 Bread", "n07 end" |

No native walk said "list", a count, or a place. Only moving forward was
measured.

The whole hierarchy (round 4, `ios-tree.txt`, from one snapshot of each
app read depth first, every element with its depth, type, label,
identifier, and frame, unlabelled ones included; `ProbeS08TreeUITests.swift.txt`
run by `ios_tree.sh.txt`). The tables above list only labelled elements,
so they show no containers; this one shows what holds what. Everything
after the "Example" heading for S08's own examples, and the list's part
for the native app:

| Screen | What holds the items |
| --- | --- |
| native n05, `UITableView` | a table (26) holding three cells (75), each holding its row's static text (48) and two unlabelled elements of type other |
| native n06, SwiftUI `List` | a collection view (32) holding three cells (75), each holding its row's text in elements of type other |
| native n07, `UIStackView` | the stack's element of type other (1), holding "Before n07", the three texts, and "n07 end" |
| `good-bulleted`, `good-numbered` | an element of type other (1), no label, holding four: an element of type other at the list's frame, no label, then the three items as static texts (48) |
| `good-cupertino` | the same, its first child labelled "Groceries" |
| `good-material` | the same container, holding the list's element and, for each list item, a container of type other holding the item's element and the tile's button (9) |
| `bad-no-list` | no container: the three static texts are siblings of the "Example" heading |
| `bad-one-text` | one static text with the three lines |

A list made with the roles is grouped on iOS, in the kind of container the
iOS engine gives every semantics node with children; nothing in it is of
a list's, a table's, or a cell's type (FL-310).

## Web VoiceOver, the first recording of the examples

Made by the coordinator on 2026-11-26 with `tool/voiceover_web.py S08`,
against expected lists that were predictions; it failed on 10 walks of 16
and is kept whole: `voiceover-web-round1-fail.md.txt` (the transcript) and
`voiceover-web-round1-fail.log.txt` (the log). What was said is in the
spec's section 7 and FL-315; the expected lists were then set to it.

The second and third recordings, against those lists, each failed one
walk of 16, in WebKit, on a first stop read as an empty phrase with every
later stop right (`voiceover-web-round2-fail.md.txt`, `bad-tile-in-item`;
`voiceover-web-round3-fail.md.txt`, `bad-one-text`; each `.log.txt` holds
the same text). The judge now walks such a capture again; the spec's
section 7 has the diagnosis. The fourth failed one walk, WebKit,
`good-numbered`, on VoiceOver's help message for the list after the last
stop (`voiceover-web-round4-fail.md.txt`, its log the same text). The
fifth passed, 16 of 16 (`voiceover-web-round5-pass.md.txt`). The judge
was tightened after it: a help message is left out only when the walk's
recorded positions tie it to the stop before it. The sixth, with that
walk and judge, passed 16 of 16 on first walks, with no empty stop and no
help message (`docs/evidence/probes/s08/voiceover-web-before-judge-update.md.txt`, moved from
`docs/evidence/S08/voiceover-web.md` on 2026-11-28); since no help
message came, the position rule was not exercised by it.

## What the examples take from this

- The list role round a `Column`, with the list item role round each
  item, is the one build that is a list on the web (p03), says "In list"
  and "Out of list" on Android, and keeps each item an element of its own
  on iOS: `good-bulleted`, `good-numbered`.
- A control in a list item needs `explicitChildNodes` (p28, not p24):
  `good-material`, and `bad-tile-in-item`.
- The list role round a `CupertinoListSection` takes the header as the
  list's name on the web and Android (p25): `good-cupertino`.
- Nothing gives a list that scrolls list semantics on the web or on
  Android (p08 to p10, p27): `bad-lazy-list`, FL-312, FL-313.
- A list item in the wrong place stops the screen's semantics in a debug
  build (p05, p09, p10): FL-314. S08's widget tests check that no good
  example throws.
