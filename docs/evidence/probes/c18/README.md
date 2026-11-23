# C18 probe: cards built from the SDK

Run on 2026-11-22, Flutter 3.47.5, while the C18 examples were first drafted;
the examples and their tests were settled from what it found.
The fixture is `probe.dart.txt`, a second entry point and not part of the
app: twenty fixtures, `p01` to `p20`, one per route (`/p01` …). Each is a
card (or three) between a "Before pNN" text and a "pNN taps: whole=N a=N
b=N c=N" text that counts the taps that reached each handler: the card as
a whole, then its first, second, and third action. Off the web the two
fixtures with an address, p09 and p11, also open `/dest`; on the web the
browser would follow the address itself.

| # | Fixture |
| --- | --- |
| p01 | `Card` with `semanticContainer` at its default, true: a heading (`headingLevel: 3`), text, a picture with `semanticLabel`, two `TextButton`s |
| p02 | p01 with `semanticContainer: false` |
| p03 | `Card` round an `InkWell` (the tappable card of the `Card` documentation): heading, text, an excluded picture |
| p04 | p03 with `semanticContainer: false` |
| p05 | `Card` round a `ListTile(onTap:, title:, subtitle:)` |
| p06 | p05 with the title a heading (`headingLevel: 3`) |
| p07 | p03 with a `TextButton` inside the `InkWell` (a control inside a control) |
| p08 | p05 with a trailing `IconButton` (a control inside a control) |
| p09 | the whole card one link: `Semantics(link: true, linkUrl:, onTapHint:)` round the `InkWell`, with C03's `BrowserKeys` |
| p10 | `semanticContainer: false`: heading, text, a `TextButton` "Read more" |
| p11 | p10 with a link "Read more" (C03's link: `Semantics(link: true, linkUrl:)` round an `InkWell`) |
| p12 | p10 with `Text(semanticsLabel:)` on the button: "Read more about cards" |
| p13 | three cards (`semanticContainer: false`) in a `Column`, each a heading, text, and a button |
| p14 | p13 in a `ListView` |
| p15 | p13 with `Semantics(role: SemanticsRole.list)` round it and `role: SemanticsRole.listItem` round each card |
| p16 | Cupertino: a `DecoratedBox` drawn as a card, heading, text, a `CupertinoButton` |
| p17 | Cupertino: `CupertinoListSection.insetGrouped` with a header and one `CupertinoListTile(onTap:)` |
| p18 | `MergeSemantics` round a `semanticContainer: false` card: heading, text, a `TextButton` |
| p19 | p03 with `Semantics(button: true)` round the `InkWell` (FL-401's workaround) |
| p20 | p03 with the title not marked as a heading |

How each platform was looked at, and the raw output:

- Widget tests: `probe_test.dart.txt` under `flutter test` (as Android):
  each fixture's semantics tree in traversal order, the merged data of
  every node with a label or a tap action, six Tabs, and Enter and Space
  after two to five Tabs, each from a fresh pump. Output:
  `flutter_test.txt`. The probe app has no Back button in the widget
  tests (each fixture is the home route), so Tab goes round the fixture's
  controls only.
- Web: Chromium, Playwright, `c18_probe.spec.js.txt` with
  `c18probe.config.js.txt`, against `flutter build web -t lib/probe.dart`:
  the fixture's elements, Chromium's own accessibility tree over the
  DevTools protocol, the ARIA snapshot, eight Tabs, Enter and Space after
  one to four Tabs, and a mouse click at the centre of each element with a
  button or link role (each from a fresh load); then plain HTML pages for
  comparison (lines starting "html"). Output: `web.txt` (line breaks inside
  a value are written `\n`). Round two, `c18_probe2.spec.js.txt`: for the
  fixtures whose tappable node came out as an `<h3>`, a mouse click and a
  DOM click with no pointer events on it, each from a fresh load:
  `web_round2.txt`.
- Android: Pixel emulator, Android 17, 1080 by 2424 at 420 dpi.
  `ProbeC18Test.kt.txt`, run by `probe_android.py.txt` with `am
  instrument`: `probe()` dumps every node of each fixture (class, name,
  `URLSpan`s, `isHeading`, clickable, focusable, children, collection
  information) and performs `ACTION_CLICK` on each clickable node of the
  fixture; `keys()` tabs six times with `input keyevent` and logs the
  deepest focused node, then presses Enter, then Space, after one to four
  Tabs, each from a fresh launch. Output: `android-tree.txt`. With TalkBack
  on, through the project's `tool/talkback.py` (which restores the
  device), `talkBackWalk()` moves TalkBack focus to each node of the
  fixture that has a name and waits six seconds (`android-talkback.md`;
  the markers, with the name of the node each was put on, in
  `android-talkback-markers.txt`). `probe()` looked for a node again
  straight after a fresh launch and sometimes found the screen before it
  (the "not found again" lines, for p13, p15, p16, p18, p19); those clicks
  are not relied on, and `keys()` reached and activated every one of
  those controls.
- iOS: iPhone 17 simulator, iOS 27.0, `ProbeC18UITests.swift.txt` run by
  `ios_probe.sh.txt`: `testTree` dumps the XCUITest tree of each fixture
  and taps each element whose label has the fixture's id, each from a
  fresh launch; `testKeys` presses one to three Tabs and Enter, and two
  Tabs and Space, from a fresh launch each, for eleven fixtures (p01 to
  p03, p05 to p09, p11, p17, p18); `testVoiceOver` turns VoiceOver on and
  moves forward from the top of each fixture to its taps line. Output:
  `ios.txt`. XCUITest element types: 1 other, 9 button, 42 link, 43 image,
  48 static text; a heading is an element of type other (1), which tells it
  from text but not from any other element of that type.

## Web

From `web.txt` and `web_round2.txt`:

| # | Elements | Tab | Keys and clicks |
| --- | --- | --- | --- |
| p01 | one `<h3 aria-label="p01 Card heading\np01 Body text…">` holding a `role="img"` and two `role="button"` | Back, the two buttons | Enter, Space, and a click run each button's own handler |
| p02 | `<h3>` "p02 Card heading", the text in a `<span>`, `role="img"`, two buttons, as siblings | Back, the two buttons | as p01 |
| p03, p04, p06, p09, p19 | one `<h3 tabindex="0">` named by the title and the text, no button or link role, no `href` (p09) | Back, the `<h3>` | Enter, Space, and a mouse click run the handler (p09: Enter and Space nothing); a DOM click runs nothing |
| p05, p20 | one `role="button"` named by the title and the text | Back, the button | Enter, Space, and a click run it |
| p07 | `<h3 tabindex="0">` holding a `role="button"` "p07 Save" | Back, the `<h3>`, Save | each runs its own handler; a DOM click on the `<h3>` runs nothing |
| p08 | `role="button"` named by the title and the text, holding a `role="button"` "p08 Save" | Back, the card, Save | each runs its own handler |
| p10, p12 | `<h3>`, the text, a button "p10 Read more" / "p12 Read more about cards" | Back, the button | Enter, Space, a click run it |
| p11 | `<h3>`, the text, `<a href="#/dest">` "p11 Read more" | Back, the link | Enter and a click: the browser follows it; Space: nothing |
| p13 | the three cards' headings, texts, and buttons as siblings | Back, the three buttons | each runs its own |
| p14 | each card's parts in a `flt-semantics` with no role, the three inside one more | as p13 | as p13 |
| p15 | `role="list"` holding three `role="listitem"`, each a card's parts | as p13 | as p13 |
| p16 | `<h3>`, the text, a button "p16 Save" | Back, Save | Space and a click run it (Enter: FL-002) |
| p17 | the header as text; the tile a `role="button"` with no `tabindex` | Back only | a click runs it |
| p18 | one `<h3 tabindex="0">` named by the title, the text, and "p18 Save" | Back, the `<h3>` | Enter and Space run Save; a click 16 pixels in from its left edge, on the title, and a DOM click, run nothing |

Plain HTML in Chromium (`web.txt`, "html" lines): an `article` is role
`article` holding its heading, paragraph, and buttons; a `div` with
`role="button"` round an `h3`, a `p`, and a `button` is a button named by
all its text, with the heading and the inner button inside it, and Tab
stops on both; an `a href` round an `h3` and a `p` is a link with the
heading inside it; an `article` whose "Read more" link sits in a `p` of its
own after the heading has the link in a paragraph that holds nothing else.

## Android

From `android-tree.txt` and `android-talkback.md`:

| # | Nodes | TalkBack, focus moved to each |
| --- | --- | --- |
| p01 | a `View`, `isHeading`, named by the title and the text, holding an `ImageView` and two `Button`s | "p01 Card heading p01 Body text … / Heading"; the picture "/ Image"; each button "/ Button / Double-tap to activate" |
| p02 | the heading `View` (`isHeading`), the text's `View`, the `ImageView`, the two `Button`s, as siblings | the heading "/ Heading"; the text alone; as p01 for the rest |
| p03, p04 | one `View`, clickable, `isHeading`, named by the title and the text | "… / Heading / Double-tap to activate" |
| p05 | one `Button` named by the title and the text | "… / Button" |
| p06, p19 | one `Button`, `isHeading` | "… / Button. Heading" |
| p07 | a clickable `View`, `isHeading`, holding a `Button` "p07 Save" | the card "… / Heading"; Save "/ Button / Double-tap to activate" |
| p08 | a `Button` holding a `Button` "p08 Save" (its tooltip) | the card "… / Button / Double-tap to activate"; Save "p08 Save. Button / Double-tap to activate" |
| p09 | one clickable `View`, `isHeading`, with the address in a `URLSpan` and a click action labelled "open link" | "… / Heading" |
| p10, p12 | heading, text, a `Button` "p10 Read more" / "p12 Read more about cards" | each read on its own; the button "/ Button / Double-tap to activate" |
| p11 | heading, text, a clickable `View` "p11 Read more" with its `URLSpan` | the link "p11 Read more / Double-tap to open link" |
| p13 | the three cards' parts as siblings | each heading "/ Heading", each button "/ Button …" |
| p14 | each card's parts in a node of their own, the three in a node with collection information 3 by 1 | the first heading "/ Heading. In list. 3 items" |
| p15 | as p14, the list an `android.widget.ListView` with no collection information printed | the first heading "/ Heading. In list" |
| p16 | heading, text, a `Button` "p16 Save" | as p02 |
| p17 | the header's `View`; the tile a clickable `View` with no role | the tile "… / Double-tap to activate" |
| p18 | one `Button`, `isHeading`, named by the title, the text, and "p18 Save" | the whole label, and no role within the dwell |
| p20 | one clickable `View`, not a heading | "… / Double-tap to activate" |

Keys (`input keyevent`, from `android-tree.txt`): Tab went Back, then
each control of the fixture in order, then round again; Enter and Space on
each control ran its own handler, and for p09 and p11 opened `/dest`. p17's
tile took no focus: Tab stopped on Back only.

## iOS

From `ios.txt` (types as XCUITest gives them; VoiceOver's utterances cut
at 64 characters by the service, so a trait after a long name is lost,
shown here as "…"):

| # | Elements | VoiceOver, moving forward | A tap |
| --- | --- | --- | --- |
| p01 | one element of type other named by the title and the text; an image; two buttons | "p01 Card heading p01 Body text … H…", "p01 picture Image", each button "… Button" | each button runs its own handler |
| p02, p10, p12, p16 | the heading (other), the text (static text), the image, the button(s), as siblings | "… Card heading Heading", the text, the image, each button "… Button" | each button runs its own |
| p03, p04 | one element of type other named by the title and the text | "… H…" | runs the card's handler |
| p05 | one button named by the title and the text | "… B…" | runs it |
| p06, p19 | one button | "… B…" | runs it |
| p07 | the card (other), and a button "p07 Save" | the card "… H…", then "p07 Save Button" | each runs its own |
| p08 | the card (button), and a button "p08 Save" | the card "… B…", then "p08 Save Button" | each runs its own |
| p09 | one link | "… H…" | opens `/dest` |
| p11 | heading, text, a link "p11 Read more" | "p11 Read more Link" | opens `/dest` |
| p13 to p15 | the cards' parts as siblings | each part on its own; nothing about a list | each button its own |
| p17 | the header and the tile as static text | "p17 Section header", "p17 Card heading p17 Body text" | runs the tile's handler |
| p18 | one button named by the title, the text, and "p18 Save" | "… p…" | at its centre, on the text, nothing |
| p20 | one static text named by the title and the text | the text alone, no trait | runs the card's handler |

Keys (one to three Tabs and Enter, two Tabs and Space, each from a fresh
launch): one Tab and Enter ran nothing; two Tabs ran the fixture's first
control (the card, or its first button), three its second, with Enter and
with Space; p09 and p11 opened `/dest`; p17's tile was never run by a key.

## What this changed

- `Card`'s default makes the card's text one heading on every platform:
  `bad-default-container`, and [FL-269](../../../flutter-limitations.md#fl-269).
- A heading inside a control is only a heading on the web:
  `bad-heading-button`, `good-tappable` has no heading, and
  [FL-268](../../../flutter-limitations.md#fl-268).
- The `Card` documentation's `InkWell` card has no role off the web:
  `bad-ink-well`, [FL-401](../../../flutter-limitations.md#fl-401) extended.
- No `article` role, and what a card and a list of cards give instead:
  [FL-026](../../../flutter-limitations.md#fl-026) extended.
- A control inside a tappable card (p07, p08) was reached and run on every
  platform; no example builds it.
- `good-cupertino` has no action, as a `CupertinoButton` needs an `Actions`
  built by hand for Enter on the web (p16, FL-002).
