# S06 probe: what Flutter gives assistive technology as a screen's title

Run on 2026-11-26, Flutter 3.47.5, before the S06 examples were written.
The fixture is `probe.dart.txt`, a second entry point and not part of the
app: thirteen fixtures, `p01` to `p13`, one per route (`/p01` …). Each
route is a launcher: a Material screen titled "pNN launcher", with a
`Title` of the same text (except p12), its text "pNN start", and a button
"pNN Open" that pushes the fixture's screen. Every fixture screen has the
text "pNN body" and, last, "pNN end". The app's own `MaterialApp.title` is
"Probe app".

| # | Fixture screen |
| --- | --- |
| p01 | `MaterialPageRoute`; `AppBar(title: Text('p01 Orders'))`; `Title('p01 Orders')` |
| p02 | p01 with no `Title` |
| p03 | `Title('p03 Orders')`; an `AppBar` with no title; "p03 Orders" as large text in the body |
| p04 | p01 with `AppBar(excludeHeaderSemantics: true)` |
| p05 | `CupertinoPageRoute`; `CupertinoNavigationBar(middle: Text('p05 Orders'))`; `Title` |
| p06 | `CupertinoPageRoute`; `CupertinoSliverNavigationBar(largeTitle: Text('p06 Orders'))`; `Title` |
| p07 | p01 with `Semantics(namesRoute: true)` round the title's text |
| p08 | p05 with `Semantics(namesRoute: true)` round the middle's text |
| p09 | p01 with `Semantics(headingLevel: 1)` round the title's text, as the app's `PageScaffold` |
| p10 | One route whose screen changes: a `NavigationBar` with "p10 Inbox" and "p10 Settings"; the `AppBar` title and the `Title` follow the destination |
| p11 | Pushed by name, `Navigator.pushNamed('/p11/orders')`; `AppBar` title "p11 Orders", no `Title` |
| p12 | As p01; its launcher has no `Title`, only `MaterialApp.title` |
| p13 | `Title` and `AppBar` "p13 Mail", with a `Drawer(semanticLabel: 'p13 Folders')` opened by a button |

How each platform was looked at, and the raw output:

- **Widget tests**: `probe_test.dart.txt` under `flutter test`, as Android
  and as iOS (`flutter_test.txt`): every document title the app sent
  (`SystemChrome.setApplicationSwitcherDescription`) on the launcher,
  after Open, and after Back; and the nodes that scope or name a route,
  with the name the platform engines would take for the last route (the
  first non-empty label of a node with `namesRoute`, depth first, as
  `AccessibilityBridge.java` and `SemanticsObject.mm` read it).
  `probe_cut_test.dart.txt` (`flutter_test_cut.txt`): titles of four
  lengths in a Material and a Cupertino bar, at 100% and 200% text, on a
  320 by 640 screen, cut short or not; the test font has square glyphs,
  so this is not what a device shows.
- **Web**: Chromium on macOS (`navigator.platform` "MacIntel"), the
  release build of the probe, with a throwaway Playwright spec
  (`probe_s06.spec.js.txt`, `probe_s06.config.js.txt`): at each step,
  `document.title`, the address, every title the document had since the
  step before, the name of Chromium's root web area, the elements that
  carry a route (`aria-describedby` and what it points to, a dialog
  role), the headings, and the element with DOM focus; the app's Back,
  the browser's back and forward; a second run of four fixtures with
  `navigator.platform` set to "Linux x86_64" before load, as CI's browser
  is; two fixtures opened with Tab and Enter. Output: `web.txt` (round 4).
  On the app's release build, `probe_s06_back.spec.js.txt`
  (`web_back.txt`): what Enter, Tab, and Shift+Tab do on S06
  `good-material`'s opened screen.
- **Android**: Pixel emulator, Android 17, a throwaway instrumented test
  (`ProbeS06Test.kt.txt`, run by `probe_android.py.txt` under the device
  lock). Without TalkBack: at each step, the title of every window, every
  node with a pane title, the app's task line from `dumpsys activity
  recents`, the node with accessibility focus, and every node with a name,
  text, or identifier (`android-tree.txt`). With TalkBack on, through
  `tool/talkback.py`'s own helper, which restores the device: TalkBack
  focus on the Open button, then the button pressed with the click
  action, then the system Back, a marker before each and eight seconds of
  speech after (`android-talkback.md`, as parsed by
  `talkback.parse_speech`; `android-talkback-markers.txt`, the probe's
  own lines).
- **iOS**: iPhone 17 simulator, iOS 27.0, a throwaway XCUITest
  (`ProbeS06UITests.swift.txt`, run by `ios_probe.sh.txt`): the elements
  of one snapshot on the launcher, after a tap on Open, and after a tap on
  Back; with VoiceOver, the cursor walked to Open, a double tap at it
  (which acts on what is under the tap), every distinct `currentSpeech()`
  reading for eight seconds, read every 0.15 s, then one move forward and
  one back; the same after a double tap at Back (`ios.txt`).

## Rounds

- **Web rounds 1 to 3** (`web-round1.txt`, `web-round3.txt`). Round 1 ran
  p01 to p10 and stopped at p10, where the test timed out; round 2 stopped
  at p10 again (the destination is `role="tab"` with its name in
  `aria-label`, so a filter by text never matched; its output was not
  kept); round 3 ran p01 to p13 and the other three tests, and its first
  test stopped at p05's Back (a Cupertino back button has a second element
  named Back inside it, so the strict locator found two). Round 4
  (`web.txt`) ran everything. Round 1 also logged each title more than
  once, a fault of the probe (one observer added per fixture), fixed in
  round 2.
- **iOS round 1** (`ios-round1.txt`): the tree test stopped at p10, whose
  destination's label is "p10 Settings\nTab 2 of 2", not "p10 Settings";
  the VoiceOver test stopped at the same place, so p11 to p13 were not
  read in round 1. **Round 2** (`ios.txt`) ran p10 to p13 alone, with
  the label matched by its start and VoiceOver switched off however the
  test ends.

## What was seen

**The route's name, read in the widget tests** (`flutter_test.txt`). As
Android, the last route is named by `AppBar`'s title (p01, p02, p09, p11,
p12), by `namesRoute` set by hand (p07, p08), and by nothing with no app
bar title (p03), with `excludeHeaderSemantics` (p04), and with
Cupertino's bars as they come (p05, p06). As iOS, by nothing for every
Material and Cupertino bar, and only where `namesRoute` is set by hand
(p07, p08). A `Drawer` names a route of its own, "p13 Folders", on both
(it scopes a route). p10's route takes the new destination's name.

**The document's title.** Widget tests: a `Title` sends its title when its
screen opens and when its own title changes (p10), and nothing at all on
Back, on any fixture. The launcher of p12, with only `MaterialApp.title`,
sent "Probe app". Web (`web.txt`): `document.title` and the name of
Chromium's root web area were the opened screen's title for every fixture
with a `Title`, and stayed so after the app's Back and after the browser's
back and forward. With no `Title` (p02, p11) the document kept the
launcher's title while the screen was open. p10's second destination
changed it to "p10 Settings". On the app's own build (`web_back.txt`,
round 2 of that spec): the catalog "Flutter A11Y Techniques", the S06
technique screen opened from it "Screen and page titles - Flutter A11Y
Techniques", and the catalog after Back the same, the closed screen's.

**The route on the web** (`web.txt`). As a Mac, no element had
`aria-describedby` and no element was a dialog or region, except where
`namesRoute` was set by hand (p07, p08: one generic element described by
the title, a generic node in Chromium's tree with no name and that
description). As Linux, `AppBar`'s routes were described too (p01, p09,
p13), and p05's Cupertino route was not. With the drawer open (as Linux)
the route's description pointed at nothing. Keyboard focus, after Open by
a click or by Enter, was on the new screen's first control (Back, or
"Open navigation menu" in p13), and after Back on the launcher's Open
button. On the app's build, after Enter opened S06 `good-material`'s
screen with DOM focus on Back, Enter did nothing; Tab (which left focus on
Back) or Shift+Tab and then Enter closed it; a second Tab took focus out
of Flutter to the page's body (`web_back.txt`; FL-421).

**Android** (`android-tree.txt`, `android-talkback.md`). The FlutterView
is the node with a pane title, an `android.widget.FrameLayout`: the
route's name where a node names it, a single space where none does (p03
to p06), and after Back the launcher's name again. The status bar's
window has a pane title of its own, "Status bar". The app window's title
was "Flutter A11Y Techniques", the app's label, on every screen. p10's
pane title stayed "p10 Inbox" after "p10 Settings" was pressed, while its
`AppBar` and `Title` changed. With the drawer open the pane title was
"p13 Folders", and "p13 Mail" again once it closed. The probe's filter of
`dumpsys activity recents` found no task description line on any step;
the format was not looked at, so what `Title` sets in Recents was not
read here. TalkBack, as each screen opened: its pane title, then its
first control ("p01 Orders", "Back", "Button. Out of list"); where no
node names the route, an empty utterance and then "Back" (p03 to p06).
As each closed: the launcher's pane title and its Open button. After p10's
second destination was pressed, only "selected". As the drawer opened,
"p13 Folders" and its first item; as it closed, "p13 Mail". The
AppBar title is a heading only with `headingLevel` (p09 `heading=true`,
p01 `heading=false`; FL-005).

**iOS** (`ios-round1.txt`, `ios.txt`). No navigation bar element: the
title is a static text element, an element of type Other with
`headingLevel` (p09). With VoiceOver, after the double tap at Open, the
reads gave Open's own utterance and then "Back Button" for every Material
screen (p01 to p04, p07, p09, p10) and "Button" for every Cupertino one
(p05, p06, p08); the title was in no read, also with `namesRoute` (p07,
p08). One move forward read the title: "p01 Orders", or "p09 Orders
Heading" with `headingLevel`; on a Cupertino screen it read "Back Button"
(the second of Cupertino's two back buttons). After the double tap at
Back, the reads gave the last utterance and then the launcher's Open
button. Round 2 (`ios.txt`): the tree test's tap on p10's Open opened
nothing ("p10 screen did not open"): VoiceOver had been left on by round
1's failed test, and with VoiceOver on a tap only moves its cursor; so
round 2's tree readings for p10 to p13 are not measurements, and the
tree of p11 to p13 was not read. Its VoiceOver test, which switches
VoiceOver on itself, ran p10 to p13: p10, p11, p12 as the other Material
screens ("Back Button", then the title one move forward). After a double
tap at p10's "p10 Settings" destination nothing new was read in eight
seconds (still "Back Button", the read from before), and one move forward
read "p10 Settings", the new title. p13: after Open, "Open navigation
menu Button" (the drawer's menu button is its first control), then "p13
Mail"; after a double tap at "p13 Show folders", "p13 Inbox folder", the
drawer's first item, and not its label "p13 Folders". VoiceOver was
switched off at the end of round 2 (its `defer`).

**Titles cut short** (`flutter_test_cut.txt`, widget tests, test font).
Material's `AppBar` cut "Your orders" and the longer titles at 100% and
200%, with a Back button before them on a 320 wide screen, and drew its
title at 29.5 for a size of 22 at 200% (its text scale is limited);
Cupertino's bar cut none of the four and drew its title at 17 at 200% as
at 100% (no scaling). The semantics label was the whole title in every
case.
