# S12 probe: what each of Flutter's ways to hide leaves

Run on 2026-11-27, Flutter 3.47.5, before the S12 examples and their tests
were written; the examples were settled from what it found. The fixture is
`probe.dart.txt`, a second entry point and not part of the app:
thirty-four fixtures, `p01` to `p34`, one per route (`/p01` …). Each sits
between a "Before pNN" text and a "pNN taps: a=N b=N" text (identifier
`pNN-taps`). `a` counts the taps on the fixture's own button, a
`TextButton` "pNN Share", where it has one; `b` counts the taps on a
"pNN After" button that follows every fixture and is never hidden, the
positive control for the keyboard and the screen reader.

| # | Fixture |
| --- | --- |
| p01 | Nothing hidden: a note and a `TextButton` |
| p02 | `ExcludeSemantics` round a glyph "✦ ✦ ✦" and a note |
| p03 | `ExcludeSemantics` round a `TextButton` |
| p04 | `Semantics(label:, excludeSemantics: true)` round a `TextButton` |
| p05 | `Offstage(offstage: true)` round a `TextButton` |
| p06 | `Visibility(visible: false)` round a `TextButton` |
| p07 | `Visibility(visible: false, maintainState: true)` |
| p08 | p07 with `maintainAnimation` and `maintainSize` |
| p09 | p08 with `maintainSemantics` |
| p10 | p08 with `maintainInteractivity` |
| p11 | `Visibility.maintain(visible: false)` |
| p12 | `Visibility(visible: false, maintainState: true, maintainFocusability: true)` |
| p13 | `Opacity(opacity: 0)` round a `TextButton` |
| p14 | `Opacity(opacity: 0, alwaysIncludeSemantics: true)` |
| p15 | `AnimatedOpacity(opacity: 0)`, settled |
| p16 | `IgnorePointer` round a `TextButton` |
| p17 | `AbsorbPointer` round a `TextButton` |
| p18 | `IgnorePointer(ignoringSemantics: true)` (deprecated) |
| p19 | `ExcludeFocus` round a `TextButton` |
| p20 | `ExcludeSemantics` round `ExcludeFocus` round a `TextButton` |
| p21 | `Semantics(hidden: true)` round a note |
| p22 | `Semantics(hidden: true)` round a `TextButton` |
| p23 | A note, a `TextButton`, and a `BlockSemantics` banner after them, in `Semantics(container: true)` |
| p24 | p23 with no container round it |
| p25 | A quotation mark "❝" before a quote, and the ornaments "· · ·" and "✦ ✦ ✦", not hidden |
| p26 | p25 with each ornament in `ExcludeSemantics` |
| p27 | A `Badge` "3" on a mail `Icon` beside "Inbox, 3 unread" |
| p28 | p27 with the `Badge` in `ExcludeSemantics` |
| p29 | `IndexedStack(index: 0)`: a note, and a pane with a `TextButton` |
| p30 | `Tooltip(excludeFromSemantics: true)` on a `Text` with the same words |
| p31 | `InkWell(excludeFromSemantics: true, onTap:)` round a `Text` |
| p32 | `GestureDetector(excludeFromSemantics: true, onTap:)` round a `Text` |
| p33 | A struck-out old price "$30" and "Now $24" |
| p34 | `Opacity(opacity: 0)` round a note |

How each platform was looked at, and the raw output:

- Widget tests: `probe_test.dart.txt` under `flutter test` (as Android):
  the semantics tree with each node's label, flags, and actions; five
  Tabs and the widget focused after each; for one to four Tabs, each from
  a fresh pump, Enter and then Space and the taps line; a tap at the
  centre of the "Share" text, from a fresh pump. Output:
  `flutter_test.txt` (the probe app has no Back button in the widget
  tests: each fixture is the home route). Space shows as `then  :`.
- Web: Chromium, Playwright, `s12_probe.spec.js.txt` with
  `s12probe.config.js.txt`, against `flutter build web -t lib/probe.dart`:
  the semantics elements between the fixture's two lines, Chromium's own
  tree over the same span (DevTools protocol), the DOM's active element
  after each of six Tabs; for the fixtures with a Share button, Enter
  after one to three Tabs (Space as well for p03, p05, p13, p16, p22,
  p31), each from a fresh load, and a mouse click between the "Before"
  line and the After button, where Share is laid out. Then the plain HTML
  page `html.html.txt`, served beside the build: Chromium's tree, ten Tabs,
  and `focus()` on each hidden button. Output: `web.txt`. Round 2,
  `s12_probe2.spec.js.txt`: Chromium's tree after each Tab, on the HTML
  page and on p03 and p13 (`web-round2.txt`).
- Android: Pixel emulator, Android 17, 1080 by 2424 at 420 dpi.
  `ProbeS12Test.kt.txt`, run by `probe_android.py.txt` with `am
  instrument`. `tree()` dumps every node of each fixture and the nodes
  between its two lines (`own`), with whether each is visible to the
  user; performs the click action on each clickable node among them, from
  a fresh launch; and taps between the "Before" line and the After button.
  `keys()` logs the deepest node with input focus after each of five Tabs
  (`input keyevent`), and presses Enter (and Space for p03, p05, p13, p16,
  p22, p31) after one to three Tabs, each from a fresh launch. Output:
  `android-tree.txt`. With TalkBack on, through the project's
  `tool/talkback.py` (which restores the device): `talkBackWalk()` and
  `talkBackKeys()`, below.
- iOS: iPhone 17 simulator, iOS 27.0, `ProbeS12UITests.swift.txt` run by
  `ios_probe.sh.txt`: `testTree` dumps the XCUITest tree of each fixture,
  taps each button but Back and After, and taps between the "Before" line
  and the After button; `testKeys` presses one to three Tabs and Return
  (and Space for the same six fixtures), from a fresh launch each;
  `testVoiceOver` turns VoiceOver on and moves forward from the top of
  each fixture to its taps line. Output: `ios.txt`.

## What each platform exposed

From `flutter_test.txt`, `web.txt`, `android-tree.txt`, and `ios.txt`.
"Share" is the fixture's own button. "No node" means no semantics node,
DOM element, Android node, or XCUITest element for it, and that
VoiceOver's moving forward on iOS did not stop on it. "Keyboard: reaches"
means Tab gave it keyboard focus and Enter ran it, on all four (two Tabs
on the devices, the first on Back; one in the widget tests, which have no
Back); "not reached", that a whole Tab cycle never gave it focus. "Tap" is
whether a tap where it is laid out (between the "Before" line and the
After button on the devices; at the centre of its text in the widget
tests) ran Share: "nothing" where Share did not run, whatever else the tap
hit (in the widget tests, where Share takes no space, the tap landed on
the After button).

| # | Widget tests, web, Android, iOS | Keyboard | Tap |
| --- | --- | --- | --- |
| p01 | the note and Share, a button with a tap action | reaches, Space too where sent | runs |
| p02 | no node for the glyph or the note | — | — |
| p03 | no node for Share | reaches; Space too; web: DOM focus stays on Back; Android: the focused node stays Back | runs |
| p04 | one node "p04 Replacement", text only; no Share | reaches; focus reported as in p03 | runs |
| p05 | no node for Share | reaches; Space too; focus reported as in p03 | nothing: not laid out, the After button moves up |
| p06 | no node for Share | not reached: Tab goes Back, After (widget tests and web; on Android and iOS no key was sent) | — |
| p07 | no node for Share | not reached | nothing |
| p08 | no node for Share | not reached (widget tests and web; on Android and iOS no key was sent) | nothing (widget test only) |
| p09 | Share is a button with no tap action (web: no `flt-tappable`; Android: not clickable); VoiceOver "p09 Share Button" | not reached | nothing |
| p10 | no node for Share | not reached | runs |
| p11 | Share is a button with its tap action, as p01; VoiceOver reads it | reaches | runs |
| p12 | no node for Share | reaches; focus reported as in p03 | nothing: not laid out |
| p13 | no node for Share | reaches; Space too; focus reported as in p03 | runs |
| p14 | Share is a button with its tap action; VoiceOver reads it | reaches | runs |
| p15 | no node for Share | reaches; focus reported as in p03 | runs |
| p16 | Share is a button with no tap action (as p09); VoiceOver "p16 Share Button" | reaches; Space too | nothing |
| p17 | as p16 | reaches | nothing |
| p18 | no node for Share | reaches; focus reported as in p03 | nothing (widget tests, web, iOS; on Android the probe found no "Before" line after the launch, and made no tap) |
| p19 | Share is a button with its tap action; VoiceOver reads it | not reached | runs |
| p20 | no node for Share | not reached | runs |
| p21 | widget tests: the note, flagged hidden; web: the note's element, in Chromium's tree; Android: no node; iOS: a static text, which VoiceOver's moving forward passed over | — | — |
| p22 | widget tests: a node flagged hidden holding Share, a button with its tap action; web: Share, a button; Android: no node; iOS: Share, a button, which VoiceOver read, "p22 Share Button" | reaches; Space too; Android reports the root view as focused | runs |
| p23 | no node for the note or Share; the banner's node | reaches; focus reported as in p03 | runs |
| p24 | no node for the note, Share, or the "Before p24" line; the banner's node; the app bar's title and Back are left | reaches; focus reported as in p03 | not tried (the tap was placed by the "Before" line, which had no node) |
| p25 | three nodes, "❝ p25 Quote", "· · ·", "✦ ✦ ✦"; VoiceOver's utterances on iOS hold the same characters | — | — |
| p26 | one node, "p26 Quote" | — | — |
| p27 | two nodes, "3" and "p27 Inbox, 3 unread"; VoiceOver "3", then the text | — | — |
| p28 | one node, "p28 Inbox, 3 unread" | — | — |
| p29 | one node, "p29 Pane one"; no node for pane two or its Share | not reached | nothing |
| p30 | one node, "p30 Full text" | — | — |
| p31 | one node "p31 Share", with no role and no tap action (widget tests: a focus action only; web: `tabindex="0"`, no role; Android: a `View`, not clickable; iOS: static text); VoiceOver "p31 Share" | reaches; Space too | runs |
| p32 | one node "p32 Share", text only; VoiceOver "p32 Share" | not reached | runs |
| p33 | two nodes, "p33 $30" and "p33 Now $24": nothing about the line through the old price | — | — |
| p34 | no node for the note | — | — |

Where the four differ is said in the row. Every other row is the same on
all four, by the raw files: one exception was looked for in each and is
named where it was found (p21, p22, p24). The VoiceOver walk on iOS read,
for every fixture, "Probe pNN", "Before pNN" (but p24), the nodes above in
order, the After button, and the taps line (`ios.txt`, the VO lines).

The plain HTML comparison (`html.html.txt`, `web.txt` "html" lines,
`web-round2.txt`):

- `hidden` and `inert`: neither the text nor the button is in Chromium's
  tree; Tab does not reach either button; `focus()` is refused.
- `aria-hidden="true"`: neither is in the tree until Tab reaches the
  button, which it does; while it has DOM focus, Chromium's tree has it,
  focused, as a button named "h02 Button in aria-hidden".
- `opacity: 0`: the text and the button are in the tree, and Tab reaches
  the button. `visibility: hidden`: neither, and Tab does not.
- An ornament in `aria-hidden` before a text: the text alone is in the
  tree; not hidden, the ornament is part of the paragraph's text.

In Flutter, Tab to a control with no node (p03, p13) leaves DOM focus on
Back, and Chromium's tree has Back focused and no element for the control
(`web-round2.txt`).

## TalkBack

Android 17, TalkBack on through `tool/talkback.py`'s helper, which
restores the device (`android-talkback.md`, the markers in
`android-talkback-markers.txt`).

- `talkBackWalk()`: TalkBack focus put on the "Before" line by action, then
  seven swipes to the right with `input swipe`, a marker before each, then
  focus moved by action to each node between the fixture's two lines.
  The swipes moved nothing: no swipe row has any speech, in any fixture,
  as S09 found (its spec, section 7). TalkBack's own navigation is
  therefore not measured. Focus by action read each node the tree has,
  and nothing else can be focused that way: the hidden parts have no
  node. What its log holds is the text sent to speech: "❝ p25 Quote",
  "· · ·", "✦ ✦ ✦" (p25), "3" (p27); how the voice pronounced the
  symbols is not in it. A button with no tap action (p09, p16) was read
  "p09 Share / Button", with no "Double-tap to activate".

- `talkBackKeys()`, round 2, for p01, p03, p13, and p05: TalkBack focus
  put on the "Before" line by action, then four Tabs, a marker logged
  before each and six seconds after it, the node with input focus logged
  after each, then Enter (`android-talkback-keys.md`, the markers and the
  focus lines in `android-talkback-keys-markers.txt`). With the button
  hidden (p03 `ExcludeSemantics`, p13 `Opacity` at 0, p05 `Offstage`), the
  first Tab read "Back / Button / Double-tap to activate"; the second,
  which gives the hidden button keyboard focus, read nothing at all, and
  input focus was still reported on Back; the third read "pNN After /
  Button / Double-tap to activate", and the fourth Back again. With nothing
  hidden (p01) the first Tab read nothing and input focus was on the root
  view (the Tab that leaves touch mode), then Back, "p01 Share / Button /
  Double-tap to activate", and After. So a TalkBack user who presses Tab
  onto the hidden button hears nothing, and TalkBack goes on as if focus
  were still on Back; a Tab later, speech comes back. This is the probe
  only: no S12 test or transcript row asserts it (which Tab lands on the
  hidden button depends on touch mode, as p01's first Tab shows). The
  Enter after the fourth Tab was on Back each time and left the screen; it
  shows nothing about the hidden button.

## What this changed

- `ExcludeSemantics` round what only decorates or repeats takes it out of
  every screen reader's way and changes nothing else (p02, p26, p28):
  `good-decoration`, `good-badge`. Left as they are, the ornaments are
  nodes of their own on every platform (p25): `bad-decoration-read`. The
  badge's "3" is a node of its own (p27); hidden, the text says it.
- A control under `ExcludeSemantics`, `excludeSemantics`, `Opacity` at 0,
  `BlockSemantics`, or the deprecated `ignoringSemantics` has no node and
  keeps keyboard focus (p03, p04, p13, p15, p18, p23, p24):
  [FL-350](../../../flutter-limitations.md#fl-350) (new),
  `bad-hidden-control`, `bad-opacity`. `Offstage` does the same (p05, p12):
  [FL-263](../../../flutter-limitations.md#fl-263), extended.
- `Visibility(visible: false)`, with `maintainState`, takes its child out
  of the tree and out of the keyboard's order (p06 to p10, p29; the
  keyboard on the devices for p07, p09, p10, and p29):
  `good-visibility`. With every `maintain` flag (`Visibility.maintain`,
  p11) the hidden child is in the tree and the keyboard's order as if
  shown: `bad-maintain`.
- `Semantics(hidden: true)` hides differently on each platform (p21,
  p22): [FL-351](../../../flutter-limitations.md#fl-351) (new); no example.
- Not built as examples: `IgnorePointer` and `AbsorbPointer` (p16, p17),
  which leave a button with no tap action that the keyboard still runs;
  `InkWell` and `GestureDetector` with `excludeFromSemantics` (p31, p32);
  `Tooltip(excludeFromSemantics:)` (p30, C12's); a struck-out price (p33);
  `BlockSemantics` (p23, p24), a dialog's concern.

## Records of the evidence runs

Not the probe, but kept here as the spec cites them (section 7):
`ios-evidence-round1-fail.txt`, the first evidence run's iOS tree layer,
whose `good-visibility` key test expected what the probe's p07 had shown
not to happen; `android_320x640-round1-fail.txt`, the first run of the
Android tree tests at CI's 320 by 640 at 160 dpi, where one tap missed;
`android_320x640.sh.txt` and `android_320x640.txt`, the script and the
passing run at that size.
