# Spec: S11 Reading and traversal order

Status: Draft 1 (2026-11-26), written with the build. Wave 3, structure and
order. Flutter pin: 3.47.5.

This spec covers the order in which a screen reader moves through content
(TalkBack's and VoiceOver's "next"), and how that order relates to the
order of keyboard focus. The keyboard's order on its own (Tab, Shift+Tab,
the arrow keys, an explicit focus order, what happens past the last
control) is [I02 Keyboard focus order](I02-focus-order.md); grouping parts
into one element is [S09 Content grouping](S09-content-grouping.md); a list's structure,
S08; headings, [S05](S05-headings.md); a link inside a sentence, which is
read out of its place without help ([FL-413](../flutter-limitations.md#fl-413)),
[C04](C04-links-inline-with-text.md).

## 1. Rule

A screen reader moves through a screen in an order that keeps its meaning:
what is shown as one column, one list, or one group is read as one, and is
not interleaved with what is beside it; a heading comes before what it
heads. Keyboard focus reaches the controls in the same order as the screen
reader reads them.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies | Applies | Applies |

Every good example is Flutter's own widgets through their documented
parameters; none is a custom solution
([custom-solutions.md](../custom-solutions.md#s11-reading-and-traversal-order)).
The order is worked out by the framework, once, for every platform: Android
gets it as the order of the nodes in the tree with traversal links, iOS as
the order of the accessibility elements, and the web as the order of the
elements in the document, with `aria-owns` where a node is a traversal
child of a node elsewhere (read in the engine's source, `_updateTraversalParent` for `aria-owns`, and seen in the
probe's r13; section 7 has what each screen reader was measured to do
with it).

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [1.3.2 Meaningful Sequence](https://www.w3.org/TR/WCAG22/#meaningful-sequence) | Each column is a sequence whose order carries its meaning (the steps of a route, in order; a list under its heading), and the columns must not be interleaved |
| [2.4.3 Focus Order](https://www.w3.org/TR/WCAG22/#focus-order) | The examples can be navigated sequentially with the keyboard; the technique keeps the order their controls are reached in the same as the order they are read in (R5), so that the screen reader's sequence and the keyboard's tell one story |

1.3.2 applies "when the sequence in which content is presented affects its
meaning". The Understanding document says that two independent sections
may be read in either order "as long as they are not interleaved", and its
first example is a multi-column document read from the top of a column to
its bottom, then the next column
([Understanding 1.3.2](https://www.w3.org/WAI/WCAG22/Understanding/meaningful-sequence.html),
read 2026-11-26). So the route and the list may come in either order; what
fails is reading them mixed.

- `bad-columns-mixed` interleaves the two columns, on every platform where
  it was measured (section 7): the two headings first, then a step, an
  item, a step, and so on. It fails 1.3.2 as written, on Android, iOS, and
  the web.
- `bad-key-missing` reads the "Bring" heading second, right after "Route",
  then the route's three steps and its button, then the list's items with
  no heading before them. The list's heading is interleaved into the route,
  and the steps are read under the heading of the list: it fails 1.3.2 as
  written, on Android, iOS, and the web.

Neither bad example fails 2.4.3: Tab reaches Back, Save route, and Save
list, in that order, in all four examples, on every platform tested
(section 6). That is the point of `bad-columns-mixed`: the keyboard's
order and the screen reader's are set by separate widgets
([FL-420](../flutter-limitations.md#fl-420)), and a screen that is right
for one can be wrong for the other. No 2.1.1 failure: every control is
reached and operated.

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | The screen reader's order matches the order the layout means: a two-column layout is read one column at a time | [iOS: Reading Order](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/ReadingOrder.md) (three columns, read row by row without `.accessibilityElement(children: .contain)`), [Android View: Accessibility Reading Order](https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/grouping/AccessibilityReadingOrder.md) (a sidebar layout, one inner layout per column), [Android Compose: Accessibility Traversal Order](https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/content/AccessibilityTraversalOrder.md) (a `Row` of two `Column`s, read mixed without `isTraversalGroup`), [Understanding 1.3.2](https://www.w3.org/WAI/WCAG22/Understanding/meaningful-sequence.html) |
| R2 | The order comes from the structure, a group per column, before any explicit index | iOS: Reading Order ("Prefer restructuring the view hierarchy or using `.accessibilityElement(children: .combine/.contain)` before resorting to `.accessibilitySortPriority()`"), Android View (layout sequence first; `accessibilityTraversalBefore` and `After` "only if necessary"), Android Compose (`isTraversalGroup`; `traversalIndex` "only if necessary") |
| R3 | Where an explicit order is given, every part that needs a place has one, and the order is kept up to date | [iOS: Accessibility Sort Priority](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/AccessibilitySortPriority.md) (sort priority is "fragile — every new element needs a priority value"), Android Compose (`traversalIndex` "tends to be fragile") |
| R4 | The parts of a group stay stops of their own unless they are meant to be one | iOS: Reading Order (`.contain`, which keeps the elements, and `.combine`, which makes one), Android Compose (`isTraversalGroup` keeps the column's texts) |
| R5 | Keyboard focus reaches the controls in the same order as the screen reader | [Understanding 2.4.3](https://www.w3.org/WAI/WCAG22/Understanding/focus-order.html), [I02](I02-focus-order.md) R4 (the two orders are set apart, and both are kept) |

Flutter references for the mechanisms used:

- [`Semantics.container`](https://api.flutter.dev/flutter/widgets/Semantics/container.html), [`Semantics.explicitChildNodes`](https://api.flutter.dev/flutter/widgets/Semantics/explicitChildNodes.html)
- [`Semantics.sortKey`](https://api.flutter.dev/flutter/widgets/Semantics/sortKey.html) ("the position of this node among its siblings"), [`OrdinalSortKey`](https://api.flutter.dev/flutter/semantics/OrdinalSortKey-class.html), [`SemanticsSortKey`](https://api.flutter.dev/flutter/semantics/SemanticsSortKey-class.html)
- [`FocusTraversalGroup`](https://api.flutter.dev/flutter/widgets/FocusTraversalGroup-class.html), [`ReadingOrderTraversalPolicy`](https://api.flutter.dev/flutter/widgets/ReadingOrderTraversalPolicy-class.html) (I02's subject)

The full set of ordering parameters found in the framework (read in the
source, `semantics/semantics.dart` and `widgets/focus_traversal.dart`):

| Parameter | Orders | Used here |
| --- | --- | --- |
| The default, by position (`_childrenInDefaultOrder`) | the screen reader | every example; the defect of `bad-columns-mixed` |
| `Semantics(container: true)`, with `explicitChildNodes` | the screen reader: a container's children are sorted among themselves | `good-columns` |
| `Semantics(sortKey: OrdinalSortKey(n))`, with a `name` to sort groups of keys apart | the screen reader, among siblings | `good-sort-keys`; the defect of `bad-key-missing` |
| A `SemanticsSortKey` subclass of one's own | the screen reader | no: it would be a mechanism of the project's own |
| `Semantics(traversalParentIdentifier:)` and `traversalChildIdentifier:` | the screen reader: a node read inside another, wherever it is (on the web through `aria-owns`, the document's order unchanged) | probe only (r13): documented as "primarily used with `OverlayPortal`" |
| `Semantics(textDirection:)`, and `Directionality` for text | the direction rows are read in | probe only (r14, r17); right-to-left is not covered (section 7) |
| `FocusTraversalGroup`, `ReadingOrderTraversalPolicy` (the default), `OrderedTraversalPolicy` with `FocusTraversalOrder` and `NumericFocusOrder` or `LexicalFocusOrder`, `WidgetOrderTraversalPolicy` | the keyboard only | `FocusTraversalGroup` in `good-columns` and `bad-columns-mixed`; the rest is I02's |

Comparison bar: HTML, where the reading order is the document's order, so
two columns written one after the other are read one after the other
whatever CSS does with them (probe, plain HTML pages: a flex row of two
columns, and CSS `order`, both read in the document's order). Radix has no
primitive for reading order.

## 5. Examples

Every example is one plan for a walk, in two columns side by side: "Route"
(Park at the gate., Climb the ridge., Walk back., and a "Save route"
button) and "Bring" (Water, A map, and a "Save list" button), each column
under a level 3 heading; then two counts, "Route saves: 0" and "List saves:
0", which say which button ran. The order meant is down the route column,
down the bring column, then the counts. Each button has a 2 pixel outline
in the text colour while it has keyboard focus, from its own `style`
([FL-430](../flutter-limitations.md#fl-430)), as in C18.

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-columns` | Material | Each column kept together for the screen reader and for the keyboard | `Semantics(container: true, explicitChildNodes: true)` and a `FocusTraversalGroup` round each `Column`; `TextButton`s | R1, R2, R4, R5 |
| `good-sort-keys` | Widgets layer | The same parts laid out row by row, so that each step lines up with the item beside it, where no widget holds a column, so the order is given part by part | `Semantics(container: true, sortKey: OrdinalSortKey(n))` on every part, the route 1 to 5 and the list 6 to 9, outside each button's `TestId`; the buttons share the last row, so Tab, by position, reaches them in the same order | R1, R3, R4, R5 |

No good example is a custom solution. The register's rows are in
[custom-solutions.md](../custom-solutions.md#s11-reading-and-traversal-order).

`good-columns` is the reference repositories' own fix in Flutter: a
container per column, as `.accessibilityElement(children: .contain)` and
`isTraversalGroup` are. `explicitChildNodes: true` is needed for the
"contain" half: without it the container joins its column's texts into one
node (probe r02; the SDK-alone widget test), which is the "combine" of the
iOS reference, one stop per column. The `FocusTraversalGroup` keeps the
keyboard in step: with it, Tab reaches Save route and then Save list on
every layer tested. The Bring column is shorter, so its button is higher on
the screen than Save route, and without the groups Tab, which goes by
position, reached Save list first in the widget tests (test font) at 412 by
915 and 320 by 640, at 100% and 200% text, and at 800 by 600 at 200%, and
Save route first at 800 by 600 at 100%, where the two buttons' rows overlap
(the widget tests "good-columns without its focus groups"). That was not
measured on a device. The probe's r15, columns with buttons and no focus
group, one part shorter on the right, went to the left button first on
every layer (`flutter_test.txt`, `web.txt`, `android-tree.txt`, `ios.txt`).
So whether Tab goes wrong without the groups depends on the layout, and
the groups make the order not depend on it, as in I02.

`good-sort-keys` is the "only if necessary" index of the references: the
parts are laid out row by row, which is a common way to keep rows level,
and no widget holds a column. Every part needs a key (`bad-key-missing`,
[FL-340](../flutter-limitations.md#fl-340)). The keys go outside each
button's `TestId`, whose `MergeSemantics` would drop them
([FL-341](../flutter-limitations.md#fl-341)).

Cupertino: there is no Cupertino example. Reading order is set by the
widgets layer, the same for Material and Cupertino content, and
Cupertino's button would need an `Actions` of the project's own for Enter
on the web ([FL-002](../flutter-limitations.md#fl-002)), which would make
the example a custom solution for a reason that is not this technique's.

### Bad

| Slug | Defect | Violates | Fails |
| --- | --- | --- | --- |
| `bad-columns-mixed` | `good-columns` without the semantics containers (the `FocusTraversalGroup`s kept). Flutter orders the screen reader's stops by position, so it reads across the two columns: both headings, then a step, an item, and so on. Tab still goes down one column, then the other ([FL-420](../flutter-limitations.md#fl-420)) | R1, R5 | 1.3.2 |
| `bad-key-missing` | `good-sort-keys` with the "Bring" heading given no key. A node with no key keeps its place by position and splits the keyed nodes round it into runs that are sorted apart, so the heading is read second, before the route ([FL-340](../flutter-limitations.md#fl-340)) | R3 | 1.3.2 |

What each fails, by platform, as the criteria are written (section 7 has
the measurements):

| Example | Android | iOS | Web |
| --- | --- | --- | --- |
| `bad-columns-mixed` | 1.3.2 | 1.3.2 | 1.3.2 |
| `bad-key-missing` | 1.3.2 | 1.3.2 | 1.3.2 |

Not built:

- A bad example with the keyboard's order wrong and the reading order
  right: I02's `bad-columns-mixed`.
- A sort key that moves a column first for the screen reader and leaves
  Tab by position (the Android Compose reference's example 3 without a
  focus order). In the probe (r11) Tab then went the other way round from
  the reading order, and on the web never left the page
  ([FL-421](../flutter-limitations.md#fl-421), extended); with two buttons
  whose names say what they save, the order of the two is not one that
  affects their meaning, so no criterion would fail as written, and the
  finding is recorded in the entry and the SDK-alone widget test instead.
- A key inside `MergeSemantics` (FL-341): asserted in the SDK-alone widget
  test and the probe on every platform; an example would show the same
  user-facing defect as `bad-columns-mixed`.
- Keys given in a wrong order, as in the iOS reference's bad example: the
  same defect as `bad-key-missing` by another route.

## 6. Assertions by layer

Every order is read stop by stop and compared as a whole list, from the
first stop after the "Example" heading to the end of the screen, the two
counts included, so a stop missing, added, or out of its place fails.

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Good, in light and dark: the four guidelines, and the text contrast guideline again with keyboard focus on each button; each button's style draws a 2 pixel outline in the text colour, 3:1 or more on the page, only while it has focus. Every example: at 200% text on a 320 by 640 screen, no layout overflow, no text that hits its line limit, none taller than its box, none past the screen's edge. The labelled nodes in traversal order, the order the framework gives every platform: the good examples exactly the order meant (heading, three steps, button, heading, two items, button, two counts) at 412 by 915, 320 by 640, and 800 by 600, each at 100% and 200% text; `bad-columns-mixed` the order measured at each of those six, both headings first and not the order meant, every part there; `bad-key-missing` "Route", "Bring", the steps, Save route, the items, Save list, the counts, at all six. `good-sort-keys` has a key on every part, 1 to 9 in the order meant; `bad-key-missing` on every part but the Bring heading. Tab from the screen as it opens: Back, Save route, Save list, Back, in every example, which for the good examples is the buttons' reading order; Shift+Tab the same backwards. For each button: a tap and the tap action, and Tab then Enter, and Tab then Space, each add one to its own count and to no other. `good-columns`' layout without its focus groups: which button Tab reaches first at the six sizes (Save list at five, Save route at 800 by 600 and 100%). The SDK alone: two columns with level rows read row by row, and with taller parts on the left partly down each column (FL-420); a container per column with and without `explicitChildNodes`; three siblings keyed 2, 3, 1 sorted, and keyed 2, none, 1 not (FL-340); a key inside `MergeSemantics` not counted and one outside it counted (FL-341); a sort key that changes the reading order and not Tab, and a `FocusTraversalOrder` that changes Tab and not the reading order (FL-420). The tests run as Android with the test font, so `bad-columns-mixed`'s orders are this layer's own |
| L3 web | Every example: the example's elements in the document's order (each element after the "Example" heading with a role, a name, or text of its own), at 1280 by 720 and at 320 by 640, compared whole with the order measured; Chromium's own accessibility tree in the same order; no `aria-owns` or `aria-flowto`. The good examples are the order meant at both sizes; the bad ones are not, with both headings first and every part there. Two level 3 headings, "Route" and "Bring", and three buttons (Back, Save route, Save list) with their names. Tab goes Back, Save route, Save list, then out of Flutter's elements (FL-421), and Shift+Tab back; for each button a click, a DOM click with no pointer events, and Tab then Enter, and then Space, each from a fresh load, add one to its own count and to no other. The VoiceOver judge (`web_tests/vo/s11_vo_walks.js`, S08's) is tested on made-up walks, and each screen is checked to show the title and lines the judge expects above its heading |
| L3 Android | Every example: the named nodes after the "Example" heading in the tree's order, to the last count (scrolling a step at a time where the end is below the view, each node kept once), with "heading" and "button" where they are: the good examples exactly the order meant; `bad-columns-mixed` the order measured, both headings first, not the order meant; `bad-key-missing` its order. Tab, from a keyboard registered with the shell's `uinput` tool, stop by stop: Back, Save route, Save list, Back, and Shift+Tab back the same way, each key sent once with a bounded wait for focus to settle. For each button, from a fresh launch each: `ACTION_CLICK` (what TalkBack's double tap performs), a tap at its centre, and Tab then Enter, and then Space, each add one to its own count and to no other. Run once at CI's 320 by 640 at 160 dpi as well |
| L3 iOS | Every example: every part an element of its own, its label once on the screen; the two buttons buttons with their names, and no other button but Back. XCUITest's own list of elements is not checked for order: it gives an element's children after the elements beside it (probe, `ios.txt`), so the order is checked in the VoiceOver walk. For each button a tap adds one to its own count and to no other; two Tabs then Space add one to Save route's count, three to Save list's, each key sent once from a fresh launch (XCUITest cannot see Flutter's focus; the probe found the first Tab on Back). Shift+Tab is not sent on iOS (section 7) |
| L4 TalkBack | TalkBack's own order: its focus put on the "Example" heading by action, then TalkBack's "next" pressed once per row, Search and Right on the `uinput` keyboard, with a marker logged before each press, eleven presses per example; each row is what TalkBack said after that press and is judged by whole utterances, with S06's form (`"== A / B / C"` in `talkback.said`): what TalkBack said must be exactly the part meant there, utterance by utterance ("Route" then "Heading"; "Save route", "Button", then "Press select to activate", the usage hint TalkBack gives with a keyboard attached, heard in every button row of both recordings), and nothing more but one "Double-tap to activate" at the end, because the labels overlap ("Route" is in "Save route" and in "Route saves: 0") and a phrase found anywhere could not tell a row's own label from another said beside it. A capture cut off in the log is judged at its place by S06's `whole_wrong`. A button row without its keyboard hint is a wrong reading, which a recording where TalkBack left the hint out within the dwell would fail for good. So a walk in a different order, or a row that also says another part, alone or joined to its own, is a wrong reading. The good examples' rows are the order meant; the bad ones' the order measured. Each walk is judged whole (`walk_strictly`): a wrong reading fails for good, and only a walk shown to be incomplete (a row with nothing said, or cut off in the log) is walked again, up to three walks, each in the transcript. The judge is tested on made-up logs (`S11OrderedWalk` in `tool/test_talkback.py`) |
| L4 VoiceOver iOS | VoiceOver's own order, moving with `moveForward()` from the top of the screen to its end (S11's own walk, `S11Walk`), judged whole: right before "Example Heading" the example's own title ("Two columns, each kept together Heading"), its good or bad line, and a bad example's defect (64 characters or more, matched as the service cuts it), then exactly the expected content: the good examples "Route Heading", the three steps, "Save route Button", "Bring Heading", the two items, "Save list Button", the two counts; the bad ones in their own orders. The two good examples have the same content, so the title is what tells their walks apart. No stop may be read twice in a row anywhere in the walk; the end is where moving on gives the last utterance again twice, and it needs independent evidence as well: one move back from it must read the stop before the last. The whole walk, from the top, is in the transcript. Every content utterance is under the service's 64 characters, and the test refuses a longer one. The judge and the collector are tested on made-up walks: each example's own walk passes; the other good example's walk, a missing, empty, wrong, or traitless title, a missing line or defect, another example's defect, a stop read twice in a row (the title included), a walk that did not reach the end, and a move back that read nothing or the last stop again all fail |
| L4 VoiceOver web | The walk, its judge, and the transcript judge are S16's (`web_tests/vo/s11_vo_walks.js`, a copy, read and not imported), with S17's positions row (S17's `s17_vo_walks.js`, on S17's branch, read and not imported). In Chromium and WebKit; no runner retries. The walk (`collectWalk`) begins with a capture on Back (the walk's start row) and compares every move, the first included, with the stop before it, or with the start: a move that changes the position or speaks a non-empty phrase other than that one is a stop, even at unchanged bounds, and its position is kept (the positions row). A move that does neither, an empty phrase or a repeat, is kept: one followed by a move on is unresolved, a gap after the stop before it (the unresolved row); two in a row are the end only with a witness, a move back that freshly reads the stop before the last, not empty, at another position, then a move forward that reads the last again at its position (both on the end row); a frozen, empty, or wrong witness fails for good. Every walk is judged whole (`judgeWalk`): the screen's title, its description, a bad example's defect, the "Example" heading, then exactly the expected list. A stop past the last expected one, empty or not, is wrong, checked before anything else; a wrong reading always wins; before the first gap the stops must be the expected list exactly; across a gap the next stop must be the next expected one or the one after it; a walk that ran out of moves is wrong. Only a walk with no wrong stop and a gap or a stop read as an empty phrase is incomplete: walked again, at most three walks, each logged, and never passed; a wrong walk ends the example (`runWalks`), so a clean walk after it is never made. VoiceOver's help message ("You are currently on …") is left out only at the position of an already-judged stop whose spoken role (`spokenRole`, from the reading's role part, never its name) is the one it names (`helpAfterStop`); it stays in the walk row. A stop with " / " or a backslash in it is written with a backslash before each in the walk row (`stopsText`). The web tree spec drives the walk with made-up screens, S16's regression cases on S11's screens: a frozen capture with elements after it, empty phrases with frozen bounds, wrong witnesses, a stale and an empty lost read at an unexpected element mid-walk, a wrong title then a stale read then a clean retry (which fails), a wrong first title at the start position, a walk exhausted at the move limit, and a help message read after the last element at its position (wrong: the witness's move back then reads the element before it). It judges the committed transcript again from its rows alone (`judgeTranscript`, never skipped): every browser and row exactly once, walks numbered from 1, at most three, each with its start, positions, and unresolved rows and the last with its end row, every position four whole numbers; the help rule applied from the positions row; the end witness checked against the last recorded position and each unresolved read against the position before it, and one whose words are neither empty nor the phrase before it fails; every walk judged again with `judgeWalk`, the last complete and every earlier one incomplete. Duplicate, malformed, unknown, or missing rows fail, and so do an empty transcript, fourteen copies of one row, and a transcript with any kind of row removed (made-up transcripts test each). The help rule is still tested only on made-up walks. Spoken roles: S11's `spokenRole` reads a heading with its level ("heading level 3", first) and a button ("button", last), and a text or a count has none; `helpAfterStop` takes a help naming "heading" as a heading's of any level. The expected lists (`EXPECTED_STOPS`, moved from the VoiceOver spec to `s11_vo_walks.js`, unchanged) were written from the document's order before any recording, and both recordings, 2026-11-26 and 2026-11-27, read exactly them in both browsers (section 7) |

## 7. What the build found (Flutter 3.47.5)

The probe that came first is in
[evidence/probes/s11](../evidence/probes/s11/README.md): twenty fixtures of
side-by-side columns on every platform, with each screen reader's own
navigation, and plain HTML pages for comparison on the web.

- **The reading order is the framework's, and the same on every
  platform**, with one exception on the web. For nineteen of the twenty
  probe fixtures the widget tests' traversal order, the web document's
  order, the order of Chromium's accessibility tree, the Android tree,
  the stops TalkBack's own "next" moved to, and the stops VoiceOver's
  `moveForward()` moved to on iOS were the same. In r13 (a traversal
  parent and child, below) the web document's order differs: the grafted
  text is last in the document, and Chromium's accessibility tree puts it
  in the left column, as every other layer does, through an `aria-owns`
  on the left column's element. The engine hands each
  platform the framework's order (read in the engine's source: Android's
  `AccessibilityBridge` adds the children in that order and links each to
  the sibling before it with `setTraversalAfter`, a first child to none; iOS's bridge builds its
  elements in that order; the web engine writes the elements in that
  order). The examples' tests on every layer agree with it, the
  transcripts included.
- **The default order is by position, not by how the widgets are
  written** ([FL-420](../flutter-limitations.md#fl-420), extended). The
  framework puts the parts whose boxes overlap vertically in one band,
  bands top to bottom, and within a band the parts that do not overlap
  horizontally left to right (read in the source:
  `_childrenInDefaultOrder`). Two columns with level rows are read row by
  row whether they are written as a `Row` of two `Column`s or row by row
  (probe r01, r05). Where the left parts are taller, so that rows overlap,
  part of each column is read down it (r03). So one layout can be read in
  different orders on different screens: `bad-columns-mixed` was read in
  six different mixed orders in the widget tests (three screen sizes, 100%
  and 200% text, with the test font, whose wide letters wrap each step),
  and row by row throughout in Chromium at 1280 and 320 pixels wide, on
  the Android emulator at its own size and at CI's, by TalkBack, by
  VoiceOver on the iOS simulator, and by VoiceOver on the web in Chromium
  and WebKit, where each step fits on one line.
  This is how the reference repositories describe SwiftUI's and Compose's
  defaults too (each reference's bad example, read row by row: not
  measured here); HTML instead reads the document's order whatever the
  layout (probe, plain HTML).
- **A container per column needs `explicitChildNodes: true`** to keep its
  parts apart: without it the container joins the column's texts into one
  node (r02), as `Semantics.explicitChildNodes`' documentation says, which
  TalkBack and VoiceOver on iOS read as one stop (the web was measured in
  the document and Chromium's tree, not with VoiceOver). That is a reading
  order kept, with
  each column one long stop. `good-columns` keeps the parts.
- **A node with no sort key splits the keyed nodes round it**
  ([FL-340](../flutter-limitations.md#fl-340), new; `bad-key-missing`):
  the sort compares only neighbours in the default order whose keys are of
  one kind, so a node with no key keeps its place and the keyed nodes
  either side are sorted as two runs (read in the source; r08 on every
  platform).
- **A sort key inside `MergeSemantics` counts for nothing**
  ([FL-341](../flutter-limitations.md#fl-341), new): r09 was read by
  position on every platform. `TestId` is a `MergeSemantics`, so
  `good-sort-keys` keys each button outside its `TestId`.
- **A sort key changes the reading order and not Tab, and a focus order
  the reverse** ([FL-420](../flutter-limitations.md#fl-420), extended):
  with the right column keyed first (r11), TalkBack and VoiceOver on iOS
  read it first, as the web document and Chromium's tree have it, and
  Tab still went to the left column's button first, on every platform; a `FocusTraversalOrder` round each column's
  `FocusTraversalGroup`, under an `OrderedTraversalPolicy` (r12), brought
  Tab into the same order. On the web, r11's Tab never left the page,
  because Flutter's last control was not the document's last
  ([FL-421](../flutter-limitations.md#fl-421), extended); Shift+Tab got
  out. All four examples keep the last control of the two orders the
  same, and Tab leaves the page in each (web tree test).
- **`traversalParentIdentifier` and `traversalChildIdentifier`** put a text
  from below the columns into the left column's place in the order (r13)
  in the widget tests, the Android tree, TalkBack's moves, and VoiceOver's
  on iOS. On the web the document keeps the text where it is, last, and
  the left column's element names it in `aria-owns`; Chromium's
  accessibility tree then has it in the left column. What VoiceOver on the
  web reads there was not measured. They are documented as "primarily
  used with `OverlayPortal`"; no example uses them.
- **TalkBack's own navigation can be driven by a test**: Search (Meta) and
  Right on a keyboard registered with the shell's `uinput` tool moved
  TalkBack's focus to the next node, every time in the probe and in every
  row of the transcript; Alt and Right did not. S03, C04, and F02 had
  tried gestures and keys sent other ways (a swipe, `input swipe`,
  `input keycombination`), found that none moved it, and walked by
  action. S11's walk is TalkBack's own order. TalkBack's
  usage hint for a button with a keyboard attached is "Press select to
  activate" (the transcript); it is not required.
- **XCUITest's own list of elements is not VoiceOver's order** once an
  element has children: it lists an element's children after the elements
  beside it (probe, r11 to r13 and r15 to r20). The iOS tree test does not check order
  for that reason, and the VoiceOver walk does.
- **Tab on iOS**: one Tab then Space pressed no button; two Tabs then
  Space pressed the first button of the keyboard's order and three the
  second, in every probe fixture with buttons: the left column's first in
  r11, r15, and r20, the right column's first in r12 and r19, as on the
  other platforms. In r11 that is the other way round from the reading
  order.
- **Right-to-left** (probe r14, r17, widget-test round 2): a
  `Directionality(rtl)` round the columns swapped their places on the
  screen and not the reading order, which still started at the left, on
  every platform; a `Semantics(textDirection: TextDirection.rtl)` round
  them started it at the right. In a widget test of an app made
  right-to-left only with `Directionality` in `MaterialApp.builder`, with
  an English locale, the columns were also read left first. An app in a
  right-to-left locale was not tried, and S11 makes no claim about
  right-to-left: handed on below.
- **VoiceOver on the web read every example in the document's order**
  (`docs/evidence/probes/s11/voiceover-web-before-judge-update.md.txt`, recorded by the principal on
  2026-11-27 with the present judge, in Chromium and Playwright's WebKit):
  the good examples one
  column, then the other, `bad-columns-mixed` row by row with both
  headings first, and `bad-key-missing` "Route", "Bring", the steps, Save
  route, the items, Save list. Headings were read "heading level 3 Route",
  buttons "Save route button". The lists had been written from the
  document's order before the first recording, and every one was read
  exactly. Every walk was complete on its first try. The first recording
  (2026-11-26, with the judge before review,
  `docs/evidence/probes/s11/voiceover-web-round1.md.txt`) read the same lists, and had one walk
  made twice: WebKit's `bad-columns-mixed`, whose first walk read the
  screen's title as an empty phrase, every later stop right. No help
  message ("You are currently on ...") came in any walk of either
  recording, so the rule that ties one to the stop before it by the
  cursor's position and its role (S08's, mirrored and tightened in review)
  is tested only by the made-up walks in the web tree spec.
- **The Android suite passed at CI's size** (320 by 640 at 160 dpi) on
  the local emulator, with `bad-columns-mixed` read row by row there too
  (`docs/evidence/probes/s11/android_320x640.txt`).

Skips and what they give up, in the tests:

- The widget tests and the Android tree test compare only nodes with a
  name (a label): the columns' containers have none and are left out. A
  node with a name and no other part's text would be compared too; every
  node the examples have is listed.
- The web order is every element after the "Example" heading with a role,
  a name, or text of its own; the containers have none. Chromium's tree is
  compared for headings, buttons, and text that is not inside a heading or
  a button.
- On Android the screen is read from the top and scrolled a step at a time
  until the last count is in the tree, each node kept once: two nodes with
  the same name, class, and identifier would count as one; no example has
  two.
- The TalkBack walk makes eleven presses per example, one per part, and
  the counts are the screen's last elements (the tree test reads to the
  end): a stop added or missing before the end shifts every later row and
  fails, but one more stop after the last count would not be seen.
- The iOS tree test does not check order (above); which count changed is
  what shows a Tab reached a button. Shift+Tab is not sent on iOS: keys
  with a modifier were unreliable on CI's iOS 26.5 (wave 4), and the
  backwards order is tested in the widget tests, on the web, and on
  Android.
- The iOS VoiceOver walk (`S11Walk`) ends where moving on gives the last
  utterance again, twice, and then needs one move back to read the stop
  before the last; it keeps every other repeat as a stop, so two
  neighbouring elements that VoiceOver reads alike would fail the walk
  rather than pass as one. No example has two. A stop before the title
  would be shown and not judged; in the recording each walk began at the
  title.
- `bad-columns-mixed`'s orders are measured per layer and per size, so the
  tests show its order on the sizes measured, not on every screen; on each,
  both headings come first and the order is not the one meant.

- **The web VoiceOver walk and its judges were brought to S16's rules,
  with S17's positions row** (2026-11-28, not yet recorded with them).
  Before, the walk compared its first move with nothing, kept no unchanged
  read (two were the end, with no witness), and logged only what follows
  the "Example" heading of a complete walk; a walk cut short was walked
  again; and no test judged the committed transcript. The transcript
  recorded before
  (`docs/evidence/probes/s11/voiceover-web-before-judge-update.md.txt`,
  moved from `docs/evidence/S11/voiceover-web.md`) has none of the new
  rows, and the web tree spec shows that it fails `judgeTranscript` for
  that, and for its rows' old form, which logged only what follows the
  "Example" heading of a complete walk.
  `docs/evidence/S11/voiceover-web.md` is absent until the next recording,
  and the never-skipped test of it fails until then. Two things differ
  from S16's rules: the positions row, S17's, so that `judgeTranscript`
  leaves out a help message by the rule the walk used (S16's counts every
  help message in a transcript as a stop), and the escaping of " / " in a
  stop (S10's `bad-merged` reads "3.4 / 5", which S16's walk row splits
  into two stops). A made-up walk in the web tree spec shows a property of
  S16's walk: a help message read after the last element, at its position,
  is the walk's last stop, and the witness's move back then reads the
  element before it, not the stop before the last, so the walk fails for
  good; the help rule cannot leave out such a message. S08's fourth
  recording read a help message there, after "end of list". The help rule
  is still tested only on made-up walks. In S16's recording
  (`docs/evidence/S16/voiceover-web.md`) the start capture on Back read an
  empty phrase in all 14 walks, and it did in S17's recordings too (on
  S17's branch); why was not looked into.

**Not done yet.** A real walk in which VoiceOver gives its help message:
none came in the recording, so the rule for help is tested only on made-up
walks; a right-to-left layout and locale; reading order inside scrolling and lazy
lists, where parts out of view do not exist yet (FL-011); Switch Access,
Switch Control, and Full Keyboard Access, which move in orders of their
own; the order on a tablet or a desktop window wide enough to change the
layout; VoiceOver's own activation on iOS (C04 probe round 3); dark mode on
a device (widget tests only); and text scaling on the web.

Handed on:

- To I14 Scrolling regions and S08: the order of a lazy list's parts out
  of view.
- To whoever takes right-to-left: what the probe saw of the direction a
  layout is read in (r14, r17, widget-test round 2).
- To the test tools: TalkBack's own "next" can be pressed from a test with
  a `uinput` keyboard (Search and Right), which later techniques can use in
  place of moving TalkBack's focus by action.
