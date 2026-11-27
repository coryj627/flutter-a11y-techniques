# Spec: S08 List semantics

Status: Draft 1 (2026-11-26), written with the build. Wave 3, structure and
order. Flutter pin: 3.47.5.

A list is content shown as a run of items: a bulleted list, a numbered list
of steps, a list of rows that each open something, a long list that
scrolls. Tables are not lists (C19). Grouping content that is not a list
is S09 Content grouping. A control inside a list item is still the
control: what a button is, is [C01 Button](C01-button.md); a `ListTile`
that takes keyboard focus, [I01](I01-focusable-controls.md); a heading,
[S05 Headings](S05-headings.md).

## 1. Rule

Content shown as a list is exposed as a list, with each item an element of
its own, so that a screen reader says where the list starts and ends and,
where the platform has it, how many items it has and where each item is.
A list is never one block of text with its items on lines of it. A control
that is a list item keeps its control's role. A long list that is built as
it is scrolled is still a list, and every item can be reached.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Limitation | Applies | Limitation |

Every good example is Flutter's own widgets through their documented
parameters, `Semantics(role: SemanticsRole.list)` round the list and
`Semantics(role: SemanticsRole.listItem)` round each item; none is a custom
solution. What they do not give is recorded, not built (section 7):

- **Android, limitation.** A list made with the role says "In list" and
  "Out of list", but not its number of items or an item's place, which the
  Android reference repositories' list semantics give
  ([FL-311](../flutter-limitations.md#fl-311)). A list that scrolls says
  nothing about a list at all, and once scrolled its items give TalkBack
  the wrong place ([FL-313](../flutter-limitations.md#fl-313)). No
  documented parameter gives a list made with the role its size: a
  `ListView` gives it the size but is no list on the web, and the two
  cannot be put together ([FL-312](../flutter-limitations.md#fl-312),
  [FL-314](../flutter-limitations.md#fl-314)). So Android has no good
  example for the size and the place (R3) or for a long list (R7): the
  good examples give Android a list's start and end, and each item as an
  element of its own, and no more.
- **Web, limitation.** A short list made with the role is a list of list
  items in Chromium's tree. A list that scrolls, Flutter's `ListView` and
  `SliverList`, is not a list, and the role cannot be put round one
  ([FL-312](../flutter-limitations.md#fl-312)); it holds only the items
  near the view ([FL-011](../flutter-limitations.md#fl-011)). A
  description list has no roles in Flutter
  ([FL-026](../flutter-limitations.md#fl-026), extended). So the web has no
  good example for a long list (R7) or a description list (R5): the good
  examples are lists on the web only because they are laid out whole and
  do not scroll. VoiceOver reads them with their size and each item's
  place, and reads each item that holds only text as an "empty group"
  ([FL-315](../flutter-limitations.md#fl-315)).
- **iOS, applies, by measurement.** Flutter gives a list nothing on iOS
  ([FL-310](../flutter-limitations.md#fl-310)): VoiceOver reads each item
  by its text alone. A native list gives no more: a UIKit `UITableView` and
  a SwiftUI `List` of the same three rows, in a separate native app on
  the same simulator, were read by VoiceOver row by row with no "list",
  no count, no place, and nothing on entering or leaving (section 7). So
  R2 and R3 ask nothing on iOS that the platform's own lists give, and
  what is left is R1, each item an element of its own, as the iOS
  reference asks, which every good example gives. VoiceOver does speak
  lists in web content (Safari on the same simulator: "List start", "1 of
  3", "List end", and "Term" and "Description" for a `dl`); that is
  WebKit's, not a native view's. A long list is no good example here
  either: VoiceOver, moving forward, read the items in view and then left
  the list ([FL-011](../flutter-limitations.md#fl-011), extended).

These statuses follow the owner's rule of 2026-11-23: where Flutter is
measured not to meet a requirement on a platform and no documented
parameter fixes it, that platform is a limitation and has no good example
for that requirement. The principal decided Android and the web on
2026-11-26, and kept the good examples, after the owner's C06 ruling of
2026-11-23, which kept a framework example with its gap recorded as a
limitation (section 5, "Decisions").

What each good example gives, and does not, by platform (measured,
section 7; the web's VoiceOver in Chromium and WebKit, Playwright's
builds):

| Example | Android | iOS | Web |
| --- | --- | --- | --- |
| `good-bulleted`, `good-numbered` | "In list" with the first item and "Out of list" after the list; no number of items, no place (FL-311) | each item an element, read by its text; no word about a list (FL-310) | a list of list items, read "list 3 items", each item "… empty group (1 of 3) 1 of 3" (FL-315), "end of list"; only because it does not scroll (FL-312) |
| `good-material` | as above, each tile a button | each tile a button, read "Milk Button"; no word about a list | a list of list items each holding a button, read "list 3 items", "Milk button 1 of 3" … "end of list" (WebKit; no Chromium reading yet) |
| `good-cupertino` | the list named by its header, "Groceries / List", and its first item "In list Groceries"; no size or place | the header an element, then each item | "list Groceries 3 items", each item as `good-bulleted`'s |

None of them is complete on Android or the web.

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [1.3.1 Info and Relationships](https://www.w3.org/TR/WCAG22/#info-and-relationships) | A list shown as a list, its items shown as items, and an ordered list's order, are structure conveyed by presentation, which must be programmatically determinable or available in text |

For 1.3.1, a list is shown by its layout: items one under another, each
with a bullet or a number. Where the platform has list semantics (the
web's `ul`, `ol`, and `li`, and Android's collection information, which
both Android reference repositories call for), a list that is not exposed
as one is structure that is shown and not determinable, and fails 1.3.1 as
written. [H48](https://www.w3.org/WAI/WCAG22/Techniques/html/H48) is the
sufficient technique on the web. "Available in text" does not save it here:
the bullets in these examples are drawn, not text, and a run of lines says
nothing of where the list starts and ends. On iOS the iOS reference
repository says a native view has no list semantics, and a SwiftUI `List`
gives none; Flutter gives none either (FL-310). There the structure that
can be determined is each item as an element of its own, and a list whose
items are one element (`bad-one-text`) fails 1.3.1, while separate items
that are not marked as a list (`bad-no-list`) are what a native SwiftUI
`List` gives, and are not called a failure on iOS. VoiceOver does speak a
web page's lists in Safari (section 7), but a native `UITableView` and
SwiftUI `List` were read with no word about a list either, so a native
app gives no more than separate items.

A control that is a list item and loses its control's role
(`bad-tile-in-item` on the web) fails 4.1.2 Name, Role, Value: its role is
what says that it can be activated.

The number of items and an item's place (R3) are what the platform adds
for a list. Where Flutter does not give them (FL-311), no 1.3.1 failure is
claimed: that the content is a list, and where it starts and ends, is
determinable.

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | Each item of a list is an element of its own, and the list is not one block of text with the items on lines of it | [iOS Lists](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/Lists.md) ("list items that are individually focusable", not "one single paragraph", not items "visually separated using the `\n` new line character") |
| R2 | Content shown as a list is marked as a list, so that the screen reader says where it starts and ends | [Android View List Semantics](https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/grouping/ListSemantics.md) and [Android Compose List Semantics](https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/content/ListSemantics.md) (TalkBack's "In list" and "Out of list"), [MDN `ul`](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/ul), [H48](https://www.w3.org/WAI/WCAG22/Techniques/html/H48) |
| R3 | Where the platform has it, the number of items, and each item's place | Android Compose List Semantics (`collectionInfo` and `collectionItemInfo`, "1 of 3"), Android View List Semantics (`CollectionInfo`; `CollectionItemInfo` on numbered items) |
| R4 | An ordered list's order is conveyed | [MDN `ol`](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/ol), H48, iOS Lists (its numbered list carries each number in the item's text) |
| R5 | A description list's terms and descriptions are related | [MDN `dl`](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/dl), H48 ("Description lists (dl) are used to group name-value pairs") |
| R6 | A list item that is a control keeps its control's role, and is reached and activated by touch, keyboard, and screen reader | [Android Compose ListItem Layouts](https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/components/ListItemLayouts.md) (a clickable `ListItem`), [C01 Button](C01-button.md), [WAI-ARIA 1.2 `listitem`](https://www.w3.org/TR/wai-aria-1.2/#listitem) |
| R7 | A list built only as it is scrolled (a lazy list) is still a list, and every item can be reached | Android Compose List Semantics (`LazyColumn` has list semantics "automatically"), Android View List Semantics (`ListView` and `RecyclerView`), [FL-011](../flutter-limitations.md#fl-011) |

Flutter references for the mechanisms used:

- [`SemanticsRole`](https://api.flutter.dev/flutter/dart-ui/SemanticsRole.html), set with [`Semantics`](https://api.flutter.dev/flutter/widgets/Semantics/Semantics.html)`(role:)`. The SDK's documentation of `list` (`dart:ui`, `semantics.dart`, read at the pin): "A container to display multiple [listItem]s in vertical or horizontal layout. For example, a [LisView] or [Column]." (sic); of `listItem`: "An item in a [list]." `good-bulleted` and `good-numbered` are its second example, the role round a `Column` and the item role round each of its children; they do nothing it does not describe. Its first example, a `ListView`, is what the framework's own check rejects once the items have the item role ([FL-312](../flutter-limitations.md#fl-312), [FL-314](../flutter-limitations.md#fl-314)). The documentation says nothing of the check, of `explicitChildNodes` for an item that holds a control, or of a list's name from a `CupertinoListSection` header: those are measured here, not documented.
- [`Semantics.explicitChildNodes`](https://api.flutter.dev/flutter/widgets/Semantics/explicitChildNodes.html)
- [`ListTile`](https://api.flutter.dev/flutter/material/ListTile-class.html), [`CupertinoListSection`](https://api.flutter.dev/flutter/cupertino/CupertinoListSection-class.html), [`CupertinoListTile`](https://api.flutter.dev/flutter/cupertino/CupertinoListTile-class.html)
- [`ListView`](https://api.flutter.dev/flutter/widgets/ListView-class.html), [`ScrollView.semanticChildCount`](https://api.flutter.dev/flutter/widgets/ScrollView/semanticChildCount.html)

Radix comparison bar: Radix has no list primitive; the bar is HTML's `ul`,
`ol`, and `li`, which Chromium exposes as a `list` holding `listitem`s
(the plain HTML comparison in the probe's `web.txt`).

No SDK widget sets the list roles: `ListView`, `ListTile`, and
`CupertinoListSection` give none (the framework source, searched for
`SemanticsRole.list`). The Android references build list semantics by hand
on a layout (`AccessibilityDelegate`, `Modifier.semantics`); the
counterpart in Flutter is the documented role, which is what the good
examples use.

### Material, Cupertino, and the widgets layer

`good-bulleted` and `good-numbered` are the widgets layer, the roles round
a `Column`. `good-material` is a list of Material's `ListTile`s, each one
a button. `good-cupertino` is Cupertino's `CupertinoListSection` with its
`CupertinoListTile`s, with no action: a `CupertinoListTile` with `onTap`
takes no keyboard focus, and is no button on Android and iOS
([FL-400](../flutter-limitations.md#fl-400); probe p29).

## 5. Examples

The unordered examples show the same three groceries, "Milk", "Eggs", and
"Bread"; the ordered one three steps. Under each list of tiles, a line
("Chosen: none") says which tile ran.

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-bulleted` | Widgets layer | A bulleted list | `Semantics(role: SemanticsRole.list)` round a `Column`; `Semantics(role: SemanticsRole.listItem)` round each line; the bullet drawn, not text | R1, R2 |
| `good-numbered` | Widgets layer | A numbered list of steps | As `good-bulleted`, each number part of its item's text ("1. Fork the repository"): Flutter has no ordered list | R1, R2, R4 |
| `good-material` | Material | A list of rows that each open something | The roles round a `Column` of `ListTile(onTap:)`, each list item with `explicitChildNodes: true`, so that the tile stays a button of its own inside the item | R1, R2, R6 |
| `good-cupertino` | Cupertino | A Cupertino list section, named by its header | The list role round a `CupertinoListSection(header:)`, which joins the header to the list's node as its name; `listItem` round each `CupertinoListTile` | R1, R2 |

No good example here is a custom solution. The register's rows are in
[custom-solutions.md](../custom-solutions.md#s08-list-semantics): the roles
are given through `Semantics(role:)`, as `headingLevel` gives S05 its
headings, and the widgets keep their own roles and behaviour.

No good example covers R3 on Android, R5, or R7 on any platform: Flutter
gives nothing that meets them there (section 2).

### Bad

| Slug | Defect | Violates |
| --- | --- | --- |
| `bad-one-text` | The items are lines of one `Text`: one element, read as one paragraph, the iOS reference's bad example | R1, R2 |
| `bad-no-list` | Lines that look like a list, each its own element, with no list role: nothing says they are a list | R2 |
| `bad-tile-in-item` | `good-material` without `explicitChildNodes`: each tile is merged into its list item, and on the web the node is a list item and not a button ([FL-262](../flutter-limitations.md#fl-262), extended) | R6 |
| `bad-lazy-list` | A long list in a `ListView.builder`, the widget the Flutter documentation gives for long lists: on Android and the web nothing says that it is a list ([FL-312](../flutter-limitations.md#fl-312), [FL-313](../flutter-limitations.md#fl-313)), and it holds only the items near the view ([FL-011](../flutter-limitations.md#fl-011)) | R2, R3, R7 |

What each fails, by platform, as the criterion is written (section 7 has
the measurements):

| Example | Android | iOS | Web |
| --- | --- | --- | --- |
| `bad-one-text` | 1.3.1: one `View` named by the three lines, no list | 1.3.1: one element named by the three lines, read as one utterance | 1.3.1: one text, no list and no list item |
| `bad-no-list` | 1.3.1: three `View`s, no list class and no collection information; TalkBack says no "In list" | none: three elements, as a native SwiftUI `List` gives (Flutter gives iOS no list, FL-310; a native UIKit list was not measured) | 1.3.1: three texts, no list and no list item |
| `bad-tile-in-item` | none: a list of `Button`s, read "Milk / Button. In list" | none: each tile a button | 4.1.2: each tile a `listitem` with `tabindex`, no button role; Tab, Enter, Space, and a click still run it |
| `bad-lazy-list` | 1.3.1: a `ScrollView` with collection information, which TalkBack does not announce; and once scrolled its items' rows are wrong (FL-313) | none claimed: Flutter gives iOS no list (FL-310); items past the view were not reached by VoiceOver's moving forward (FL-011) | 1.3.1: no list and no list item; 13 of 30 orders in the page when it opens (FL-011) |

`bad-tile-in-item` on Android and iOS is a list of buttons, and is not
called a failure there: its one defect is the web's, as C18's
`bad-heading-button` is.

`bad-lazy-list` is a framework defect with no good counterpart: its
author did nothing wrong by Flutter's documentation, a `ListView` is the
widget for a long list, and what it lacks is Flutter's (FL-312, FL-313).
No good example of a long list exists here, on any platform. It is kept so
that every layer asserts what a long list gives, and fails if a Flutter
upgrade fixes it (the principal's decision; the owner may overrule).

### Decisions

The principal's, on 2026-11-26, on the engineer's questions:

1. Android is a limitation (FL-311, FL-313), by the owner's rule of
   2026-11-23.
2. The web is a limitation (FL-312, and FL-026 for description lists), by
   the same rule. On both, the good examples stay, after the owner's C06
   ruling of 2026-11-23, and the spec, the doc, and each example's text
   say by platform what the example gives and what it does not; none is
   called complete on a limitation platform.
3. `bad-lazy-list` stays, labelled as a framework defect with no good
   counterpart; the owner may overrule.
4. iOS was to be settled by a native comparison on the simulator: a
   `UITableView` and a SwiftUI `List`, three rows each. Measured: VoiceOver
   said nothing more for them than for Flutter's list, so iOS applies and
   FL-310 says so with the measurement (section 2, section 7).
5. `explicitChildNodes: true` in `good-material` is not a custom
   solution.
6. No description list example; FL-026 carries it.
7. FL-262 is extended for a list item that takes in a button, with its
   title and index row made to match.
8. The roles round a `Column` are checked against the SDK's documentation
   of `SemanticsRole.list` (section 4).

### Not built

- **A description list.** `SemanticsRole` has no term or definition role
  ([FL-026](../flutter-limitations.md#fl-026), extended). The probe measured
  terms and descriptions as plain texts (p16) and as one merged node each
  (p17); neither relates a term to its description, so neither is a good
  example, and a bad one would show nothing that FL-026 does not say.
- **A long list that is a list.** No SDK widget gives one on the web or on
  Android (FL-312, FL-313); the probe tried the role round a `ListView`
  (p09, p10, p27).
- **A list of Cupertino tiles that open something** (FL-400).
- **A nested list.** The role round a list inside a list item (p18) is a
  list inside a list item on the web, with the inner items at level 2,
  and "In list" and "Out of list" on Android at the inner list; it was
  measured in the probe only.

`TestId` is a `MergeSemantics`, which is a node of its own: round a list
item it would come between the item and its list, and round a tile it
would keep the tile out of the item. So the tiles carry
`Semantics(identifier:)` with a key, and the items and lines are found by
their text.

## 6. Assertions by layer

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Every example: at 200% text on a 320 by 640 screen, no layout overflow, no text that hits its line limit, none taller than its box, none past the screen's edge. Good, in light and dark: the four guidelines; no error from the framework (its list item check, FL-314); `good-material`'s text contrast again with keyboard focus on each tile. The example's nodes after the "Example" heading, in traversal order, with their depth: `good-bulleted` exactly a list holding three list items named by the lines; `good-numbered` the same with the numbered steps; `good-material` a list holding three list items, each holding one node that is a button with a tap action named by its tile; `good-cupertino` a list named "Groceries" holding three list items. The bullets are 3:1 or more against the page. `good-material`'s focus tint on a tile is under 3:1 and over 1:1 against the page (FL-434), written to fail if it reaches 3:1. Tab goes Back, then each tile. For each tile of `good-material` and `bad-tile-in-item`: a tap and the tap action each open it; Tab to it, then Enter, and then Space (each from a fresh open), do the same. Bad: `bad-one-text` one node holding the three lines and no list; `bad-no-list` three nodes and no list; `bad-tile-in-item` a list of three list items that are each a button with a tap action (the merge the web turns into a list item); `bad-lazy-list` no list and no list item, a scroll node of 30 children, fewer than 30 orders as nodes starting with order 1, and after scrolling to its end order 30 and not order 1. The tests run as Android, so the web engine's choice of role is not seen here |
| L3 web | The example's elements from Chromium's tree (the ARIA snapshot after the "Example" heading, up to the "Chosen" line): `good-bulleted` exactly a list holding three list items named "Milk", "Eggs", "Bread", one list and three list items in the page; `good-numbered` the same with the steps; `good-material` a list holding three list items, each holding one button named by its tile, and no button in the page but Back and the tiles; `good-cupertino` a list named "Groceries" of three list items, and no button but Back. Tab goes Back, then each tile, each a button. For each tile of `good-material` and `bad-tile-in-item`: a click, and Tab then Enter, and Tab then Space (each from a fresh load, the key sent once), open it. Bad: `bad-one-text` no list and no list item, and one element holding the three lines; `bad-no-list` no list and no list item, and three elements (the ARIA snapshot joins neighbouring texts into one line, so the elements are read from the page); `bad-tile-in-item` each tile's element is a `listitem` named by its title with no button inside it, the page's only button is Back, and Tab stops on each tile as a list item; `bad-lazy-list` no list and no list item, the orders in the page start at 1 and are fewer than 30, and after the mouse wheel scrolls the list to its end order 30 is there and order 1 is not, with still no list. The VoiceOver judge (`web_tests/vo/s08_vo_walks.js`) is tested on made-up walks, and each screen is checked to show the title and lines the judge expects above its heading |
| L3 Android | The example's nodes after the "Example" heading, with their class, name, and collection information, indented by depth (the screen scrolled to its end first): `good-bulleted` exactly a `ListView` holding three `View`s named by the lines; `good-numbered` the same with the steps; `good-material` a `ListView` whose three `Button`s are named by the tiles; `good-cupertino` a `ListView` named "Groceries" holding three `View`s, and no button but Back; and no node of any good example has collection information or collection item information (FL-311), written to fail when they have. For each tile of `good-material` and `bad-tile-in-item`, from a fresh launch each: `ACTION_CLICK` (what TalkBack's double tap performs), a tap at its centre, and Tab then Enter open it. Bad: `bad-one-text` one `View` named by the three lines, and no list class or collection anywhere; `bad-no-list` three `View`s, and no list class or collection anywhere; `bad-tile-in-item` a `ListView` of three `Button`s; `bad-lazy-list` no list class, a `ScrollView` with collection information 30 by 1, fewer than 30 orders starting with order 1, each with its own row, and after three `ACTION_SCROLL_FORWARD`s an order whose row is not its place (FL-313), written to fail when the rows are right. Run once at CI's 320 by 640 at 160 dpi as well |
| L3 iOS | The labels of the example's elements after the "Example" heading, in order: `good-bulleted` exactly the three lines, each the label of one element; `good-numbered` the steps; `good-material` the three tiles, each a button with its identifier and label; `good-cupertino` "Groceries" and the three items, and no button but Back. For each tile of `good-material` and `bad-tile-in-item`: a tap opens it; and Tabs then Enter, and then Space, each key sent once from a fresh launch, open it (XCUITest cannot see Flutter's focus; the first Tab goes to Back, as in the widget tests). Bad: `bad-one-text` one element with the three lines, and no element named by one of them; `bad-no-list` the three lines; `bad-tile-in-item` three buttons. The iOS tree test reads labels and types, not the hierarchy, and XCUITest gives no traits; an element with no label is left out (the probe found no element for an unnamed list on iOS, and a list named by a header, p25, as an element of type other); the VoiceOver walk is what shows that nothing says "list" |
| L4 TalkBack | Focus moved to each item of each list, in order: the first item of each list with its name and "In list", the others with their name and no "In list", and none with the list's size or an item's place ("3 items", "1 of 3"; FL-311); `good-material`'s and `bad-tile-in-item`'s tiles with "Button", and the line after them with "Out of list"; `good-cupertino`'s list itself named "Groceries" with "List"; `bad-one-text` the three lines as one reading, with no "In list"; `bad-no-list` each line with no "In list"; `bad-lazy-list` the first two orders with no "In list" and no size or place (FL-313). Each walk is judged whole (`walk_strictly` in `tool/talkback.py`, as C18's is): a walk with any wrong reading fails for good, and only a walk shown to be incomplete is walked again, up to three walks, each in the transcript |
| L4 VoiceOver iOS | Every utterance after the "Example" heading to the end of the screen, compared as a whole list (C03's walk, `C03Walk`): each item by its text alone, with no word about a list (FL-310); the tiles with "Button" and the "Chosen" line; `good-cupertino` "Groceries" then the items; `bad-one-text` the three lines as one utterance; `bad-lazy-list` the measured stops. Every expected utterance is under the service's 64 characters, and a test refuses a longer one |
| L4 VoiceOver web | Every walk must read the whole screen, each stop in its place (`judgeExampleWalk` in `web_tests/vo/s08_vo_walks.js`, a copy of C04's): the screen's title and description, the "Example" heading, then exactly the expected list, to the end of the screen. A wrong stop, an empty one, a skipped one, or a walk that reached the end with any expected stop not read fails the test for good; only a walk cut short with every stop right so far is walked again, up to three walks, every walk logged. No runner retries. VoiceOver's own help message ("You are currently on …", `VO_HELP` in `vo_logic.js`) is not a stop of the page: the walk puts the phrase Guidepup logged for a move in place of one (`walkToEnd`'s `loggedForHelp`, as the form techniques' walks do), and the judge leaves out any that comes anyway, wherever it is; a help message in place of an element's own speech leaves that element unread, which fails (regression cases in the web tree spec: after the last stop and in the middle, complete; in place of an expected stop, wrong). A stop read as an empty phrase is a failed capture, not a reading: the walk is incomplete and walked again (at most three walks, each logged), an empty phrase never passes, and a walk that also read the wrong words is wrong (the principal's rule of 2026-11-26; regression cases in the web tree spec: an empty first stop walked again, an empty first stop and then a wrong re-walk failing, three empty captures failing). In Chromium and WebKit. The expected lists are the stops the first recording measured: the list with "list 3 items" (`good-cupertino` "list Groceries 3 items"), each text-only item with "empty group" and its place twice, "end of list"; `good-material`'s buttons with their place (WebKit; Chromium quit in that walk, so its list is WebKit's); `bad-tile-in-item`'s items as "group"; the bad examples with no list as predicted. The judge's regression cases in the web tree spec include the first recording's prediction, now a wrong walk, and the crash dialog |

## 7. What the build found (Flutter 3.47.5)

The probe that came first is in [evidence/probes/s08](../evidence/probes/s08/README.md):
29 fixtures on every platform, a native Android comparison, and plain HTML
lists in Chromium and in Safari on iOS.

- **The list roles are a list on the web and Android, and nothing on iOS.**
  `Semantics(role: SemanticsRole.list)` round a `Column`, with
  `SemanticsRole.listItem` round each item (probe p03, `good-bulleted`),
  is a `list` of `listitem`s in Chromium's tree, the shape of a `div` with
  `role="list"` in plain HTML; on Android an `android.widget.ListView` that
  TalkBack enters with "In list" and leaves with "Out of list"; on iOS a
  static text per item, which VoiceOver reads by its text alone
  ([FL-310](../flutter-limitations.md#fl-310), new). On Android there is
  no collection information, so TalkBack gives no number of items and no
  place, where a native `ListView` says "1 of 3. In list. 3 items"
  ([FL-311](../flutter-limitations.md#fl-311), new).
- **Flutter's scrolling lists are lists on Android only, and only while
  they do not scroll.** A `ListView` is no list on the web (Chromium's
  tree), whether it is
  lazy or not (p06 to p08, p19 to p21;
  [FL-312](../flutter-limitations.md#fl-312), new). On Android a
  `ListView` laid out whole gives collection information, which TalkBack
  reads as "In list. 3 items" (p06), and with a height of its own and
  nothing to scroll the place as well, "1 of 3" (p07); a `ListView` that
  scrolls is an `android.widget.ScrollView` with 30 rows, of which TalkBack
  said nothing, and once scrolled its items' rows are their place among
  the nodes there, not in the list (p08, `bad-lazy-list`;
  [FL-313](../flutter-limitations.md#fl-313), new).
- **The list role cannot be put round a `ListView`.** The list items' parent
  node is then the scroll view's, and the framework's check that a list
  item's parent is a list fails (p09, p10): in the widget tests it is
  thrown, and in a debug build on Android and iOS the screen's semantics
  never arrived ([FL-314](../flutter-limitations.md#fl-314), new; the same
  check as [FL-258](../flutter-limitations.md#fl-258) for progress bars).
  A list item with no list at all fails it the same way (p05). In the web's
  release build, where the check does not run, p09 and p10 were lists.
- **A lazy list holds only the items near the view, on every platform**
  ([FL-011](../flutter-limitations.md#fl-011), extended with Android and
  iOS): 13 of 30 when p08 opens, as nodes in the widget tests, elements in
  the page, and elements on iOS; the 6 in view on Android. On iOS
  VoiceOver, moving forward, read the items in view and went on to the
  line after the list: items 7 to 30 were not reached, and the list was
  not scrolled.
- **A control merged into a list item is a list item, and no button, on the
  web** ([FL-262](../flutter-limitations.md#fl-262), extended;
  `bad-tile-in-item`). The web engine looks at a node's `SemanticsRole`
  before any flag (source read). `ListTile(onTap:)` in a list item (p24)
  is a focusable `listitem` named by the tile, which Tab, Enter, Space, and
  a click still run. On Android it is a `Button` ("p24 Milk / Button. In
  list"), and on iOS VoiceOver reads "p24 Milk Button". With
  `explicitChildNodes: true` on the list item (p28, `good-material`) the
  tile is a button inside the list item on the web and Android, and
  VoiceOver reads it as on p24.
- **A list named by its header**: the list role round a
  `CupertinoListSection(header:)` (p25, `good-cupertino`) joins the header
  to the list's node, which is `list "p25 Groceries"` on the web and on
  Android a focusable `ListView` that TalkBack read as "p25 Groceries /
  List", its first item "In list p25 Groceries". On iOS the header is an
  element of its own, read before the items.
- **The list role with no list items** (p04) merges every item's text into
  the list's own node: on the web a `list` named by all three lines with no
  items, on Android a `ListView` read as "p04 Milk p04 Eggs p04 Bread /
  List", on iOS one element. Not an example: it is `bad-one-text` with a
  role.
- **Description lists** have no roles (p16, p17;
  [FL-026](../flutter-limitations.md#fl-026), extended); plain HTML's `dl`
  is a `DescriptionList` of `term`s and `definition`s in Chromium.
- **Ordered lists**: Flutter's list items have no number of their own, so
  the number is in the text (p15, `good-numbered`), read with the item on
  every platform. HTML's `ol` gives each item a list marker instead.
- **Material's and Cupertino's list widgets give no list role.** `ListTile`
  (p11), `CupertinoListSection` and `CupertinoListTile` (p14) are texts,
  or buttons for a tile with `onTap` (p13); no SDK widget sets the list
  roles (framework source searched).
- **VoiceOver on the web reads the lists, with their size and place, and
  each text-only item as an "empty group"**
  ([FL-315](../flutter-limitations.md#fl-315), new). The first web
  recording (2026-11-26, macOS 27.2.1, Playwright 1.65.0's Chromium and
  WebKit builds;
  `docs/evidence/probes/s08/voiceover-web-round1-fail.md.txt` and its log)
  failed on 10 walks of 16, every one on the predictions; nothing in it
  was judged by a loosened rule. In both browsers: `good-bulleted` "list 3
  items", "Milk empty group (1 of 3) 1 of 3", "Eggs empty group (2 of 3) 2
  of 3", "Bread empty group (3 of 3) 3 of 3", "end of list";
  `good-numbered` the same with the steps; `good-cupertino` "list
  Groceries 3 items" and its items the same way; `bad-tile-in-item` "Milk
  group (1 of 3) 1 of 3" and no "button" (FL-262). `good-material` in
  WebKit: "list 3 items", "Milk button 1 of 3", "Eggs button 2 of 3",
  "Bread button 3 of 3", "end of list", "Chosen: none". In Chromium that
  walk read a dialog, "Google Chrome for Testing quit unexpectedly.":
  the browser had quit, and there is no Chromium reading of
  `good-material`; why it quit was not looked into. `bad-one-text`,
  `bad-no-list`, and `bad-lazy-list` were read as predicted, in both
  browsers (`bad-lazy-list`: "Order 1" to "Order 13", with no list). Each
  text-only item is `<flt-semantics role="listitem" aria-label="…">`, with
  no element and no text inside it (the web tree test); `bad-tile-in-item`'s
  items have `tabindex="0"` as well; `good-material`'s items hold a
  button element and have no label. What VoiceOver says for a plain HTML
  `li` in these browsers was not measured.
- **A native iOS list says nothing more than Flutter's**
  ([FL-310](../flutter-limitations.md#fl-310), with the measurement). The
  native comparison (`NativeLists.swift.txt`, a separate app built with
  `swiftc`, installed on the same simulator, not part of the Runner;
  `ios-native.txt`): a UIKit `UITableView` of three rows, a SwiftUI `List`
  of three `Text` rows, and a `UIStackView` of three labels. VoiceOver,
  moving forward from the label above and from the top of the screen,
  read each row by its text and then the label after it, in all three:
  no "list", no count, no place, nothing on entering or leaving. To
  XCUITest the table is a table of cells and the SwiftUI list a collection
  view of cells. Touching a row and the rotor were not tried.
- **The second and third web recordings each failed one walk of 16 on
  an empty first stop**, in WebKit only: `bad-tile-in-item` in round 2,
  `bad-one-text` in round 3
  (`docs/evidence/probes/s08/voiceover-web-round2-fail.md.txt`,
  `voiceover-web-round3-fail.md.txt`, with their logs, which hold the same
  text). The first stop, where "heading level 1 …" (the screen's title)
  was expected, was "", and every later stop of that walk was right, from
  the screen's second line on. Every other walk of both rounds was
  complete and right, `good-material` in Chromium among them ("Milk button
  1 of 3"), so the corrected expectations held. Where the empty phrase
  came from, from what was recorded: the walk starts by focusing Back,
  which is not a stop; the first `voiceOver.next()` moved the cursor (the
  move counted as a stop, and the next one read the second line, so the
  cursor had been on the title); and the AppleScript read of VoiceOver's
  last phrase after it gave "". Whether VoiceOver had not yet given that
  phrase when it was read, or gave the title no phrase, the logs cannot
  tell: they hold no timing and no cursor positions. C02 recorded WebKit
  reading a screen's level 1 heading as an empty phrase. C04's and S06's
  walks start the same way (`walkToEnd` in `vo_helpers.js`, from Back) and
  their judges count an empty phrase as a wrong stop; S06 passed 12 of 12
  with no empty reading. So the start is the same, and the difference was
  the judge: S08's counted the empty reading as wrong. It now counts it as
  a failed capture, walked again, as the principal set out. Nothing in
  the walk's start was changed.
- **The fourth web recording failed one walk of 16 on VoiceOver's help
  message**, WebKit, `good-numbered`
  (`docs/evidence/probes/s08/voiceover-web-round4-fail.md.txt`, its log
  the same text): every expected stop was read in its place, and then,
  after "end of list", one more stop, "You are currently on a list, inside
  of web content. To move between items in this list, press
  Control-Option-Right Arrow or Control-Option-Left Arrow. To exit this web
  area, press Control-Option-Shift-Up Arrow.", which the judge counted as
  read after the last expected stop. No stop was empty. The shared walk
  counts a move as a stop when the cursor moves or a new phrase is spoken
  (`stopsToEnd`, `vo_logic.js`), so a help message read after the last
  element is a new phrase and becomes a stop, whether or not the cursor
  moved; the log holds no cursor positions, so which it was is not
  known.
  `vo_helpers.js` already says that VoiceOver gives its help for an
  element about a second after the element, and the form techniques
  replace a help message with the phrase Guidepup logged for the move
  (`phraseForMove`). S08 now does both: the walk uses `loggedForHelp`, and
  the judge leaves out a help message wherever it comes. No shared file
  was changed.
- **What leaving out the help message gives up.** Its words are never
  checked: here it said "on a list", which is VoiceOver telling where its
  cursor is, and a help message that named the wrong role would pass
  unseen. A help message that came in place of an element's own speech is
  not passed over: the element is then missing, and the walk fails. Nor
  can a walk of help messages alone pass.
- **What a re-walk can hide.** A stop VoiceOver sometimes gives no phrase
  for (WebKit's title, here) passes when a later walk of the same example
  reads it; the empty try is in the transcript, as every try is, but does
  not fail the test. A wrong reading cannot be hidden this way: a walk
  with one fails, whatever try it is. Nor can an empty phrase pass: three
  walks each with one fail. What is given up is that an empty phrase that
  comes and goes is reported, not failed.
- **VoiceOver on iOS speaks a web page's lists.** In Safari on the same
  simulator, moving forward from a tap on the line above (probe round 2,
  `ios-round2.txt`): a `ul` of three, "List start 1 of 3" with the first
  item, "2 of 3", and "3 of 3 List end"; an `ol`, "List start 1" (cut at
  64 characters), "2 of 3", "3 of 3 List"; a `dl`, each term with "Term"
  and each description with "Description"; a nested `ul`, "List start"
  and "List end" at each level, with the inner items "1 of 2" and "2 of
  2". The service returned each item's text twice. A native UIKit list
  container was not built, so this shows what VoiceOver can say, not what
  a native app gives.
- **The native Android comparison** (`ProbeNativeActivity.kt.txt`): a
  native `ListView` of three items was read "n01 Milk. 1 of 3. In list. 3
  items / Double-tap to activate", then "2 of 3", "3 of 3", and "n01 end.
  Out of list". The Android View reference's own builds (n02, n03,
  round 2): its unnumbered list "In list. 3 items", its numbered list "1
  of 3. In list. 3 items". A native `ListView` of 30 that scrolls (n04)
  "1 of 30. In list. 30 items", and after three steps forward "10 of 30.
  In list. 30 items": a scrolling list is announced, with the right
  place, natively, and Flutter's is not (FL-313).
- **TalkBack's keyboard navigation could not be driven**: Alt and Right,
  sent with `input keycombination`, never moved TalkBack's focus. The
  TalkBack walks here move focus by action, so what a swipe through a list
  says, and whether it scrolls a lazy one, was not measured.

The first evidence run (2026-11-26) failed two layers, both in the tests,
and each was changed and run again:

- Android: the test of the tiles read the "Chosen" line straight after a
  launch with `revealed()`, which throws on a miss; right after a launch
  the screen being replaced, the same example, can still be up. The wait
  now catches the miss and reads again, for at most ten seconds.
- iOS: the two tests of the lists of tiles read the screen's labels with
  an element query, which gave no tile labels between the "Example"
  heading and the "Chosen" line. The labels are now read from one
  snapshot of the app, depth first, as the probe read them. Why the
  query's order differed was not looked into.

The Android tree tests then passed at CI's size, 320 by 640 at 160 dpi
(`docs/evidence/probes/s08/android_320x640.txt`), and again at the
emulator's own size with the iOS tree tests (the second evidence run).

What the tests skip or cannot see, and what each gives up:

- The Android tree test reads the example after scrolling the screen to
  its end, except for `bad-lazy-list`, whose own list would be the first
  scrollable node on a screen that does not scroll. A node scrolled away
  above would be missed; every example fits CI's screen below the heading
  (checked at 320 by 640, below).
- The web tree test reads the ARIA snapshot, which joins neighbouring
  texts into one line, so `bad-no-list`'s and `bad-one-text`'s elements are
  read from the page's `flt-semantics` elements instead: an element that
  holds no other and has text is one entry. A text inside an element that
  also holds another element would be missed; no example has one.
- `bad-lazy-list`'s tests check that the items in the tree are fewer than
  30 and start at 1, not that they are exactly 13, which depends on the
  view's height and the platform.
- The TalkBack walk focuses two of the thirty orders of `bad-lazy-list`,
  the first two, before any scrolling.
- XCUITest gives no traits, and the iOS tree test reads labels and types
  in one snapshot's order, not the hierarchy; the VoiceOver walk shows what is said.

**Not done yet.** A passing web VoiceOver recording with the judge that
walks an empty capture again and leaves out VoiceOver's help message. What VoiceOver says for a plain HTML `li`
in the same browsers (FL-315). Which stops a TalkBack
swipe makes, and whether it scrolls a lazy list. VoiceOver's own
activation on iOS, which XCUITest cannot make (C04 probe round 3): the
tiles' taps are taps at their place. What VoiceOver on iOS says for a
native list when a row is touched, or with the rotor (only moving forward
was measured). A description list, a long
list, and a nested list as examples. The lists in dark mode on a device
(widget tests only), text scaling on the web, and right-to-left text.
