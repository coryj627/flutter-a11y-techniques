# C04 probe: links inside a sentence, built from the SDK

Run on 2026-11-21, Flutter 3.47.5, before the C04 examples were written.
The fixture is `probe.dart.txt`, a second entry point and not part of the
app: ten fixtures, `r01` to `r10`, one per route (`/r01` …). Each is the
sentence "rNN Read about [rNN first link] and [rNN second link] first."
between a "Before rNN" text and a "rNN taps: first=N second=M" text that
counts the taps that reached each link's handler. Off the web a tap on a
fixture with an address also opens `/dest`; on the web the browser follows
the address `#/dest` itself.

| # | Fixture |
| --- | --- |
| r01 | `TextSpan` links with a `TapGestureRecognizer` |
| r02 | `WidgetSpan` links: `Semantics(link: true, linkUrl:, onTapHint:)` round an `InkWell`, with C03's `BrowserKeys`; no FL-413 workaround |
| r03 | r02 with FL-413's workaround: an identifier on the first words, sort keys 0.5 and 1.5 |
| r04 | r03 with widgets-layer links: `FocusableActionDetector` round `Semantics(link:, linkUrl:)` and a `GestureDetector` |
| r05 | r03 inside `MergeSemantics` |
| r06 | r03 with a second link long enough to wrap |
| r07 | `SelectableText.rich` with `TextSpan` links |
| r08 | `TextSpan` links in a `Text.rich` with a `semanticsLabel` |
| r09 | r01 with a second link long enough to wrap |
| r10 | r03 with each link's text in `MediaQuery.withNoTextScaling` |

How each platform was looked at, and the raw output:

- Widget tests: `probe_test.dart.txt` under `flutter test`: each
  fixture's semantics nodes, their traversal order, eight Tabs, Enter and
  Space after one to four Tabs, and the layout at 200% text on a 320 pixel
  screen; then what the tap action on r05's merged node does, the scale of
  the link text at 200% (r03, r10), colour contrasts, how the runs are
  counted with two spans before a link ("two spans"), and which part of
  FL-413's workaround the order rests on ("order"). Output:
  `flutter_test.txt`.
- Web: Chromium, Playwright, `c04_probe.spec.js.txt` with
  `c04probe.config.js.txt`, against `flutter build web -t lib/probe.dart`:
  the sentence's elements, Chromium's own accessibility tree over the
  DevTools protocol, the ARIA snapshot, eight Tabs, each link's box, then
  for each link from a fresh load a mouse click, a DOM click, Tab and
  Enter, and Tab and Space. Output: `web.txt` (line breaks inside a value
  are written `\n`). After the examples were built,
  `web_merged.spec.js.txt` clicked `bad-merged`'s one element where each
  link's words and the first words are drawn, and sent it a DOM click,
  each from a fresh load: `web_merged.txt`.
- Android: Pixel emulator, Android 17, 1080 by 2424 at 420 dpi.
  `ProbeC04Test.kt.txt`, run by `probe_android.py.txt` with `am instrument`:
  `probe()` dumps every node of each fixture and performs `ACTION_CLICK` on
  each link; `keys()` tabs with `input keyevent`; `nativeTree()` reads the
  native comparison, `ProbeNativeActivity.kt.txt` (a `TextView` with two
  `URLSpan`s and `LinkMovementMethod`, the Android View reference's way;
  declared for the run in the debug manifest). Output: `android-tree.txt`.
  `rects()` dumps the nodes with the system font scale at 2.0, put back to
  1.0 afterwards (`android-rects-200.txt`). With TalkBack on, through the
  project's `tool/talkback.py` (which restores the device),
  `talkBackWalk()` moves TalkBack focus to each part of each sentence and
  `nativeTalkBack()` to the native text (`android-talkback.md`, the
  markers in `android-talkback-markers.txt`); `talkBackSwipe()` swiped
  right with UI Automator from "Before rNN" and logged where TalkBack's
  focus was.
- iOS: iPhone 17 simulator, iOS 27.0, `ProbeC04UITests.swift.txt` run by
  `ios_probe.sh.txt`: the XCUITest tree and a tap on each link; one to
  three Tabs and Enter from a fresh launch; with VoiceOver on, a walk from
  the top and a double tap on each link; and the tree again at the text
  size accessibility-large, put back afterwards. Output: `ios.txt`,
  `ios-rects.txt`. XCUITest element types: 1 other, 9 button, 42 link,
  48 static text.

Two readings of the first Android round were not usable and are not
relied on: `keys()` logged the Flutter view itself as the focused node,
which has no name, so every Tab stop reads empty, and `probe()` looked for
the first link straight after a fresh launch and found the screen before
it, so most "first: no node" lines are that and not a missing node. Round
two (`android-tree-round2.txt`) waits for the link and reads the deepest
focused node. The swipes did not move TalkBack's focus at all (every line
stays on "Before rNN"): UI Automator's swipe is not a TalkBack gesture, so
the order of a swipe was not measured.

## Web

From `web.txt`:

| # | Sentence | Each link | Tab | Click / DOM click | Enter / Space |
| --- | --- | --- | --- | --- | --- |
| r01 | words and links as siblings in order | `<a flt-tappable>`, no `href`, no `tabindex`; Chromium: link | Back only | the handler runs | not reached |
| r02 | a `group` with `aria-label="r02 Read about \n and \n first."` holding the two links | `<a href="#/dest" tabindex="0">` | Back, first, second | followed by the browser | followed / nothing |
| r03, r04, r06, r10 | words and links as siblings in order | `<a href="#/dest" tabindex="0">` | Back, first, second | followed | followed / nothing |
| r05 | one `<a href="#/dest">` named by the whole sentence | (none of their own) | Back, then the one element twice | (see `web_merged.txt`) | |
| r07 | a `<textarea disabled>` with an empty value; no words, no links | | Back only | | |
| r08 | one text, "r08 Read about the two links first." | none | Back only | | |
| r09 | as r01; the long link's element is 440 wide on one line at this width | as r01 | Back only | the handler runs | not reached |

`web_merged.txt` (the examples' build, `bad-merged`): a click at the first
link's words, at the second link's, and at the first words each lands on
the one `<a>` and ends on `#/t/C04`, the first link's page; so does a DOM
click.

## Android

From `android-tree.txt`, `android-tree-round2.txt`, `android-rects-200.txt`,
and `android-talkback.md`:

| # | Nodes | TalkBack on a link |
| --- | --- | --- |
| r01, r07 | the sentence's node holds the words and each link in order; each link an `android.widget.Button`, no `URLSpan` | "… / Button / Double-tap to activate" |
| r02 | a `View` named "r02 Read about \n and \n first." holding the two links | "… / Double-tap to open link"; the sentence node "r02 Read about and first." |
| r03, r04, r06, r10 | words and links in order; each link a `View` with its `URLSpan` and a click action labelled "open link" | "… / Double-tap to open link" |
| r05 | one `View` named by the whole sentence, one `URLSpan` (the address) over all of it, a click action labelled "open link", no children | the sentence, and nothing more within five seconds |
| r08 | one node, "r08 Read about the two links first." | (no link) |
| r09 | as r01; the long link's node covers two whole lines | "… / Button" |

`ACTION_CLICK` ran each link's handler wherever the probe found the link
(round two: every link of every fixture but r05 and r08, where no node is
named by a link).

Keys, round two (`input keyevent`): r02, r03, r04, r06, r10 stop on Back,
the first link, the second link, and round again; Enter after two Tabs and
after three opened `/dest`. r01, r07, r09 (text spans) and r08 stop on
Back only (r01's first Tab is used up leaving touch mode). r05 stops on
Back and then twice on the one merged node.

At font scale 2.0 (`android-rects-200.txt`): r03's links are 180 pixels
tall and the words' lines 102; each link is on a line of its own. r10's
links are 98 pixels tall in 102 pixel lines, the first beside the first
words. r06's long link is a block from the left edge, 902 pixels tall; r09's
flows from the end of the first line.

Native comparison (`nativeTree`, `nativeTalkBack`): the `TextView` is one
node with the two `URLSpan`s in its text; Tab stops on it and nowhere
inside it (five Tabs); TalkBack reads the whole text as one stop and adds
"Double-tap to open link. Actions available, use Tap with 3 fingers to
view", where its links are offered. So native Android text makes the
sentence one stop with its links in a menu; Flutter makes each run and
each link a stop, with no menu.

## iOS

From `ios.txt` and `ios-rects.txt`:

From `ios.txt` and `ios-rects.txt` (VoiceOver's utterances are cut at 64
characters by `XCUIVoiceOverService`):

| # | XCUITest | VoiceOver, walking from the top | Tap / double tap on each link | 1 to 3 Tabs, then Enter |
| --- | --- | --- | --- | --- |
| r01, r07 | words as static text, each link a link | "r01 Read about", "r01 first link Link", "and", "r01 second link Link", "first." | the handler runs | the handler never runs |
| r02 | an element (type 1) labelled "r02 Read about \n and \n first.", then the two links | "r02 Read about and first.", "r02 first link Link", "r02 second link Link" | followed | 2 or 3 Tabs: followed |
| r03, r04, r10 | words as static text, each link a link | in order, as r01 | followed | 2 or 3 Tabs: followed |
| r05 | one link labelled by the whole sentence | one stop, "r05 Read about r05 first link and r05 second link first. Lin" (cut at 64) | (no element named by a link) | 2 or 3 Tabs: followed |
| r06 | the long link a link with a 370 by 40 frame from the paragraph's left edge | in order; the long link cut at 64 | the cursor, put by a tap at the long link's centre, landed on "first."; the double tap then followed a link | 2 or 3 Tabs: followed |
| r08 | one static text | "r08 Read about the two links first." | (no link) | nothing |
| r09 | the long link a link whose frame starts at the paragraph's left edge on the first line and covers both lines (12, 163, 354 by 46) | in order | XCUITest's tap at the long link's centre missed it ("second tap": second=0); with VoiceOver, a tap at the first link put the cursor on the long link, and one at the long link put it on "first." | the handler never runs |

The keys cannot tell which link Enter followed: every link of a fixture
goes to `/dest`. In the examples' tests the two links go to different
pages, which tells them apart.

At the text size accessibility-large (`ios-rects.txt`): r03's first link
is 75.7 points tall where the first words' line is 41; r10's is 38.8. The
links of r03 are scaled twice, and r10's once, as on Android.

`(error 3)` in r07's walk is one move after "Before r07" that gave no
utterance; the walk went on to the words.

### Round 2, after the first transcript run

The first iOS VoiceOver transcript run of the examples failed: the test
put the cursor on each good link with a tap, as C03's does, and VoiceOver
said "first." each time. `ProbeC04VOUITests.swift.txt`, run by
`ios_probe2.sh.txt` against the app's own build, looked at why
(`ios_round2.txt`):

- `good-material`'s sentence takes two lines on the iPhone 17 screen. The
  last run, " first.", has the frame (12, 256, 378 by 52): both lines,
  whole, over the two links (24 points tall, on the first line).
- With VoiceOver on, a tap at either link's centre puts the cursor on
  "first.". A double tap there then opened the link's own page; why was
  not found.
- Moving the cursor forward reaches each link ("links in text Link",
  "stand-alone links Link"), and a double tap on the link then opens its
  page.
- `bad-merged`: with the cursor on the one element, by a tap or by moving
  forward, the probe logged "(no page)" three seconds after a double tap on
  it. That is one observation with no positive control on the element, and
  nothing is claimed from it; the C04 test records the same step without
  asserting it.

## C04's Android suite at CI's size

After the examples were built, C04's Android tree tests ran once at the CI
emulator's size, 320 by 640 at 160 dpi (`android_320x640.sh.txt`, which
resets both after): nine tests, no failure, `talkBackWalk` skipped with
TalkBack off; the JUnit summary is at the end of `android_320x640.txt`.

## What it shows

- **A `TextSpan` link is read well and the keyboard cannot reach it, on
  every platform** (r01, r07, r09). On Android it is a `Button` and on the
  web an `<a>` with no `href`, as it has no address (FL-032). FL-240.
- **A `WidgetSpan` link reaches the keyboard and is followed by every
  input**, and FL-413's workaround keeps two links in place on all three
  platforms (r03, r04). Without it, the sentence is read without its links
  (r02).
- **A `WidgetSpan`'s text is scaled twice** (r03 against r10, on Android,
  iOS, and in the widget tests), and `withNoTextScaling` puts it right.
  FL-241.
- **A `WidgetSpan` link is a box** (r06): a long one takes lines of its own,
  where the same words in a `TextSpan` flow on (r09). FL-244. A long
  `TextSpan` link's node covers its lines whole, so a tap at its centre can
  miss it (r09 on iOS).
- **Merging the sentence makes one link** with the first link's address
  (r05) on all three platforms. FL-243.
- **A run of words that wraps has one node over all its lines**, and on
  iOS a VoiceOver touch on a link under it finds the words (round 2).
  FL-246.
- **`semanticsLabel` on the paragraph hides its links** (r08): the label
  replaces the spans' nodes. Not an example; the label is the developer's
  choice.
- **`SelectableText` on the web is an empty field** (r07). FL-245.
- **Native Android text is one stop with a links menu**; Flutter's is a
  stop per part, with no menu.
- **Cupertino's link colours are under 4.5:1 on white** (`flutter_test.txt`,
  "contrast"). FL-242.
