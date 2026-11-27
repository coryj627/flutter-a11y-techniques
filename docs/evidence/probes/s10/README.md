# S10 probe: replacing a visual composite with one node

Run on 2026-11-26, Flutter 3.47.5, before the S10 examples and their tests
were written; the examples were settled from what it found. The fixture
is `probe.dart.txt`, a second entry point and not part of the app:
twenty-five fixtures, `p01` to `p25`, one per route (`/p01` …). Each sits
between a "Before pNN" text and a "pNN taps: a=N b=N" text (identifier
`pNN-taps`) that counts the taps that reached its handlers.

The composites:

- the rating row of the Android reference repositories: the text
  "Rating:", a Material `LinearProgressIndicator` 80 wide at 3.4 of 5 (its
  own semantics: a progress bar, value 68), "3.4 / 5", and "Reviews: 856";
- a row of five star `Icon`s with no `semanticLabel` (three full, a half,
  an empty), "3.4", and "(856)";
- a weather summary (a sun `Icon`, "21°", "H 24°  L 12°"), a `Badge` with
  "3" on a mail `Icon` beside "Inbox", and a bar chart drawn by a
  `CustomPainter`.

The replacement text is "Rating: 3.4 out of 5 stars, based on 856
reviews", as the Android references word theirs.

| # | Fixture |
| --- | --- |
| p01 | The rating row, its pieces as they are |
| p02 | p01 in `MergeSemantics` (the references' "grouped" bad example) |
| p03 | p01 in `Semantics(label:, excludeSemantics: true)` |
| p04 | p01 in `Semantics(label:)` round `ExcludeSemantics` |
| p05 | `MergeSemantics` round `Semantics(label:)`, each piece in `ExcludeSemantics` (the Compose reference's `hideFromAccessibility` way) |
| p06 | p01 in `Semantics(label:)`, the pieces not hidden |
| p07 | p06 in `MergeSemantics` |
| p08 | p05 with the bar left out of `ExcludeSemantics` |
| p09 | The stars, as they are |
| p10 | p09 in `Semantics(label:, excludeSemantics: true)` |
| p11 | p09 in `Semantics(label: 'Rating', value: '3.4 out of 5 stars, 856 reviews', excludeSemantics: true)` |
| p12 | p09 in `Semantics(image: true, label:, excludeSemantics: true)` |
| p13 | The stars and a `TextButton` "Reviews", all in `Semantics(label:, excludeSemantics: true)` |
| p14 | p10 with a custom semantics action "Read reviews" |
| p15 | `ListTile(onTap:)` with the title "Ridge trail" and p10 as its subtitle |
| p16 | `CustomPaint` whose painter's `semanticsBuilder` gives one node with a summary |
| p17 | The same with a node per bar |
| p18 | The weather summary, as it is |
| p19 | p18 in `Semantics(label: 'Sunny, 21 degrees, high 24, low 12', excludeSemantics: true)` |
| p20 | The badge, as it is |
| p21 | p20 in `Semantics(label: 'Inbox, 3 unread', excludeSemantics: true)` |
| p22 | p03 whose label is worked out from the shown values, and a `TextButton` "Add a 5-star review" that adds one |
| p23 | p22 with a fixed label |
| p24 | `Text('3.4 / 5', semanticsLabel:)`, and `Text.rich` with `semanticsLabel` |
| p25 | p03 with `identifier:` on the replacement node |

How each platform was looked at, and the raw output:

- Widget tests: `probe_test.dart.txt` under `flutter test` (as Android):
  each fixture's semantics tree in traversal order, the merged data of
  every node with a label, a value, or an action, four Tabs, Enter and
  Space after one to three Tabs (each from a fresh pump), and for p22 and
  p23 the replacement's label before and after a tap on the button.
  Output: `flutter_test.txt`. The probe app has no Back button in the
  widget tests (each fixture is the home route).
- Web: Chromium, Playwright, `s10_probe.spec.js.txt` with
  `s10probe.config.js.txt`, against `flutter build web -t lib/probe.dart`:
  the semantics elements between the fixture's two lines, Chromium's own
  accessibility tree over the same span (DevTools protocol), the ARIA
  snapshot, six Tabs; for p13, p14, p15, p22, and p23, Enter and Space
  after one to three Tabs and a mouse click on each element with a button
  role (for p13, a click at the replaced element's right end, which missed
  the button: no handler ran), each from a fresh load; for p22 and p23 the
  replacement's text after the click. Output: `web.txt` (line breaks
  inside a value are written `\n`).
- Android: Pixel emulator, Android 17, 1080 by 2424 at 420 dpi.
  `ProbeS10Test.kt.txt`, run by `probe_android.py.txt` with `am
  instrument`. `probe()` dumps every node of each fixture and the nodes
  between its two lines (`own`); its clicks found no node again after a
  fresh launch ("not found again"), so round 2, `clicks()` (added to the
  same file afterwards), waits up to ten seconds for each node before its
  click action, and performs p14's custom action. `keys()` tabs five times
  with `input keyevent` and logs the deepest node with input focus, then
  presses Enter, then Space, after one to three Tabs, each from a fresh
  launch, for p13, p14, p15, p22, and p23. Output: `android-tree.txt`,
  `android-tree-round2.txt`. With TalkBack on, through the project's
  `tool/talkback.py` (which restores the device), `talkBackWalk()` moves
  TalkBack focus to each node between the two lines that has a name and
  waits six seconds (`android-talkback.md`; the markers, with the node
  each was put on, in `android-talkback-markers.txt`).
- iOS: iPhone 17 simulator, iOS 27.0, `ProbeS10UITests.swift.txt` run by
  `ios_probe.sh.txt`: `testTree` dumps the XCUITest tree of each fixture,
  and for the fixtures with a control taps each button but Back, and for
  p13 and p14 taps the replaced element at seven points from 30% to 60% of
  its width; `testKeys` presses one to three Tabs and Return for p13, p14,
  p15, p22, and p23, from a fresh launch each; `testVoiceOver` turns
  VoiceOver on and moves forward from the top of each fixture to its taps
  line. Output: `ios.txt`. XCUITest element types: 1 other, 9 button, 43
  image, 48 static text.

## What each platform exposed

From `flutter_test.txt`, `web.txt`, `android-tree.txt`,
`android-tree-round2.txt`, `android-talkback.md`, and `ios.txt`. "Pieces"
is the rating row's texts joined with line breaks, "Rating:\n3.4 /
5\nReviews: 856"; "Words" is the replacement text. VoiceOver's
utterances are cut at 64 characters by the service.

| # | Widget tests | Web | Android | TalkBack | iOS | VoiceOver on iOS |
| --- | --- | --- | --- | --- | --- | --- |
| p01 | four nodes: "Rating:", a progress bar (value 68, no label), "3.4 / 5", "Reviews: 856" | three text elements and a `progressbar` named "68" | three `View`s and a `ProgressBar` named "68", range 0..100 at 68 | "Rating:"; "68.0. / 68 / Progress bar"; "3.4 / 5"; "Reviews: 856" | three static texts; the bar is not in the dump, which leaves out elements of type other with no label, but VoiceOver read it | "Rating:", "68", "3.4 / 5", "Reviews: 856" |
| p02 | one node: pieces, value 68, role progress bar | one `progressbar`, `aria-label` pieces and " 68", `aria-valuenow` 68 | one `ProgressBar` "68, " and pieces, at 68 | "68.0. / 68, / Rating: 3.4 / 5 Reviews: 856", no role word | one static text, label pieces, value 68 | "Rating: 3.4 / 5 Reviews: 856 68" |
| p03, p04, p05, p10, p25 | one node: Words, nothing else | one text element (a `<span>` of Words), no role | one `View` named Words | Words | one static text, Words, no value | Words |
| p06, p07 | one node: Words, then pieces, value 68, role progress bar | one `progressbar` named Words, pieces, " 68" | one `ProgressBar` "68, " Words and pieces | "68.0. / 68, / " Words and pieces | label Words and pieces, value 68 | Words, " Rating: 3.4 / 5" (cut) |
| p08 | one node: Words, value 68, role progress bar | one `progressbar` "Words 68" | one `ProgressBar` "68, Words" | "68.0. / 68, / Words" | Words, value 68 | Words " 68" |
| p09 | "3.4", "(856)"; the icons give nothing | two text elements, "3.4" and "(856)" | two `View`s | "3.4"; "(856)" | two static texts | "3.4", "(856)" |
| p11 | label "Rating", value "3.4 out of 5 stars, 856 reviews" | one text element "Rating 3.4 out of 5 stars, 856 reviews" (FL-037) | one `View` "3.4 out of 5 stars, 856 reviews, Rating" | the value, then "Rating" | label "Rating", the value apart | "Rating 3.4 out of 5 stars, 856 reviews" |
| p12 | Words, image | `role="img"` named Words | `ImageView` Words | Words "/ Image" | an image (43) | Words "Image" |
| p13 | one node: Words; the button in no node | one text element; no button but Back | one `View`; no clickable node but Back | Words | one static text; no button but Back | Words |
| p14 | Words, a custom action | one text element; no action in the DOM | a `View` with the action "Read reviews" | Words "/ Actions available, use Tap with 3 fingers to view" | one static text | Words " Actions availab" (cut) |
| p15 | one button: "Ridge trail\nWords" | one `role="button"` with that text | one `Button` | "Ridge trail Words / Button" | one button | "Ridge trail Words But" (cut) |
| p16 | one node with the summary | one text element in a container | one `View` in a container | the summary | one static text | the summary |
| p17 | seven nodes, one per bar | seven text elements | seven `View`s | each bar's text | seven static texts | each bar's text |
| p18 | "21°", "H 24°  L 12°" | two text elements | two `View`s | "21°"; "H 24°  L 12°" | two static texts | "21°", "H 24° L 12°" |
| p19, p21 | one node with the label | one text element | one `View` | the label | one static text | the label |
| p20 | "3", "Inbox" | two text elements | two `View`s | "3"; "Inbox" | two static texts | "3", "Inbox" |
| p22, p23 | Words, then the button | a text element, then `role="button"` | a `View`, then a `Button` | Words; "Add a 5-star review / Button / Double-tap to activate" | a static text, then a button | Words, "Add a 5-star review Button" |
| p24 | "3.4 out of 5"; "3.4 out of 5 stars" | two text elements | two `View`s | each label | two static texts | each label |

No replaced node took a Tab stop on any platform (on Android its node
reports `focusable` true, as every text node in the dump does), and none
has an action.

## Keys, clicks, and the replacement's values

- p22, a replacement worked out from the values: after the button (a tap
  in the widget tests, a click on the web, the click action on Android, a
  tap on iOS) the row showed "Reviews: 857" and the replacement said "…
  based on 857 reviews" on every platform. p23, with a fixed label, still
  said 856 on every platform.
- p13, a replacement that takes in a `TextButton` "Reviews": the button is
  in no node on any platform, and the keyboard still reaches it. Widget
  tests: Tab reached it and Enter and Space ran it. Web: the first Tab put
  DOM focus on Back; after the second, DOM focus was still on Back and
  Enter, or Space, ran Reviews, not Back. Android: the node reported as
  focused stayed "Back" after every Tab; two Tabs and Enter, or Space, ran
  Reviews, and one or three left the screen (Back). iOS: two Tabs and
  Return ran it, one or three did not; a tap at 60% of the replaced
  element's width, where the button is drawn, ran it (30% to 55% did not).
- p15, a `ListTile` whose subtitle is a replacement: one button named by
  the title and the replacement on every platform; Tab reached it, and
  Enter, Space (where sent), a click, a tap, and the click action ran it.
- p14's custom action: Android performed it ("returned true", the handler
  ran, round 2). Web and iOS: no key, click, or tap ran it.

## What this changed

- `Semantics(label:, excludeSemantics: true)` replaces a group with one
  node that has the label and nothing else, on every platform: S10
  `good-exclude-semantics` and `good-stars`. `MergeSemantics` round
  `Semantics(label:)` with every piece in `ExcludeSemantics` gives the
  same node: `good-hidden-pieces`.
- A merged group takes a progress indicator's value, and its role where
  the platform has one: `bad-merged`, `bad-not-excluded`, and
  [FL-330](../../../flutter-limitations.md#fl-330) (new). The bar left out
  of the hiding (p08) does the same; it is in FL-330 and not an example.
- A replacement that takes in a control hides it from every screen reader
  while the keyboard still reaches it: `bad-hides-control`.
- A fixed label goes stale: `bad-stale`. One worked out from the values
  follows them: `good-exclude-semantics`.
- Stars with no label give nothing, and the numbers beside them say
  nothing alone: `bad-pieces`.
- Not built as examples: a label and a value (p11): on Android the value
  comes before the label, "3.4 out of 5 stars, 856 reviews, Rating"
  ([FL-039](../../../flutter-limitations.md#fl-039)'s joining), and on
  the web it is appended to the name
  ([FL-037](../../../flutter-limitations.md#fl-037)); a replacement with an
  image role (p12), a chart's alternative, is S02's `good-chart`;
  `CustomPainter.semanticsBuilder` (p16, p17) gives a painting nodes of
  its own, one or many, and replaces nothing; the weather summary and the
  badge (p18 to p21) read as the rating does; `Text(semanticsLabel:)`
  (p24) rewords one text, S01's subject; custom actions (p14) are not on
  the web ([FL-022](../../../flutter-limitations.md#fl-022), extended)
  and are I05's subject.
