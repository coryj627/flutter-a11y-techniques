# C05 probe: what Flutter's accordions, and a hand-built one, expose

Run on 2026-11-21, Flutter 3.47.5, before the C05 examples were written.
The fixture is `probe.dart.txt`, a second entry point and not part of the
app: eighteen fixtures, `p01` to `p18`, one per route (`/p01` …). Each is
an accordion of two sections, "pNN Shipping" and "pNN Returns", both
closed at the start, between a "Before pNN" text and a "pNN end" text. A
panel holds the text "pNN Shipping panel" and a button "pNN Shipping
button".

| # | Fixture |
| --- | --- |
| p01 | `ExpansionTile`, as it comes |
| p02 | `ExpansionTile(maintainState: true)` |
| p03 | `ExpansionTile` with its title in `Semantics(headingLevel: 3)` |
| p04 | `ExpansionPanelList`, as it comes (`canTapOnHeader: false`) |
| p05 | `ExpansionPanelList` with `canTapOnHeader: true` |
| p06 | `CupertinoExpansionTile`, as it comes |
| p07 | Hand-built: `MergeSemantics` round `Semantics(button: true, expanded:)`, `FocusableActionDetector` (Enter and Space), and a `GestureDetector`; the panel built only while open |
| p08 | p07 with `headingLevel: 3` on the same node |
| p09 | p07 inside `Semantics(headingLevel: 3, container: true)`: a heading node holding the button's node |
| p10 | p07 with `onExpand` and `onCollapse` |
| p11 | p07 with `controlsNodes` naming the panel, whose `Semantics` has that identifier |
| p12 | p07 with `value: 'collapsed'` or `'expanded'` |
| p13 | p07 with `onTapHint: 'expand'` or `'collapse'` |
| p14 | The widgets layer's `Expansible`, with p07's header and its default `maintainState: true`; its header takes Enter through `ActivateIntent` only |
| p15 | `ExpansionTile(internalAddSemanticForOnTap: true)` with its title in `Semantics(expanded:)` |
| p16 | p07 with a `CupertinoListTile` in place of the `GestureDetector` |
| p17 | p11 with Shipping open from the start |
| p18 | p11 with `controlsNodes` set only while the section is open |

How each platform was looked at, and the raw output:

- Widget tests (the harness, which is Android unless the target platform
  is set): `probe_test.dart.txt`, run as `flutter test`. For each fixture,
  as Android and as iOS: the semantics tree closed and after a tap on
  Shipping, and the name of the node with keyboard focus after each of
  seven Tabs, closed and open. A stop on a control with no semantics node
  is named by the nearest node above it (`probe_test.txt`).
- Web: Chromium, Playwright, `c05_probe.spec.js.txt` with
  `c05probe.config.js.txt`, against `flutter build web -t lib/probe.dart`.
  For each fixture: the semantics DOM and Chromium's accessibility tree
  over the DevTools protocol, closed and after a click on Shipping; the
  element with DOM focus after each Tab; then, from fresh loads, Tab to
  Shipping and Enter, and Space. A key that did nothing was followed by a
  click, the positive control. Last, a plain HTML page with APG's markup,
  a `details` element, and ARIA roles, for Chromium's reading of the same
  structures (`web.txt`, the `html` lines).
- Android: Pixel emulator, Android 17 (`SDK_INT 37`), 1080 by 2424 at
  420 dpi. `ProbeC05Test.kt.txt`, run by `probe_android.py.txt` with
  `am instrument` (`probe_all.sh.txt`): `probe()` dumps every node of each
  fixture with its expanded state (`getExpandedState`, API 36) and its
  actions, performs `ACTION_CLICK` on Shipping's header, and dumps again,
  then `ACTION_COLLAPSE` and `ACTION_EXPAND` where the node has them
  (`android-tree.txt`); `talkBackWalk()` moves TalkBack focus to the
  header, performs `ACTION_CLICK` with focus left there, then clears focus
  and puts it on the header again, through the project's `tool/talkback.py`
  (`android-talkback.md`). `keys()` sends Tab, Enter, and Space with
  `input keyevent` (`android-keys.txt`). A native comparison,
  `ProbeNativeActivity.kt.txt` (declared for the run in the debug
  manifest), was read the same way (`android-tree-native.txt`,
  `android-talkback-native.md`).
- iOS: iPhone 17 simulator, iOS 27.0, `ProbeC05UITests.swift.txt` run by
  the same script: the XCUITest tree and a tap; one to three Tabs and
  then Enter or Space, each from a fresh launch; with VoiceOver on, a walk
  from the top, then the cursor put on Shipping and XCUITest's double tap
  at it (see the note under "iOS (27.0)"), what was
  said after it, and four more moves. A native comparison, UIKit buttons
  with `accessibilityExpandedStatus` and SwiftUI's `DisclosureGroup`
  (`SceneDelegate.swift.txt`, launch argument `-c05native`), read by
  `testNative`. Output: `ios.txt`. XCUITest element types: 1 other,
  9 button, 48 static text.

Two first runs went wrong and were run again (`probe_android2.sh.txt`):

- `keys()` read the Flutter view itself as the focused node, so every stop
  was "FrameLayout" (`android-keys-first-run.txt`, kept, not used). The
  second run reads the focused node inside the view that has a name, and
  sends keys with `input keyevent`, as the technique tests do, for ten of
  the fixtures (`android-keys.txt`).
- The native screen was not found: its buttons' text is shown in capitals
  by the theme, and a node's text is then in capitals too, so the probe's
  "n01" did not match. The buttons' capitals are off in the second run;
  that changes nothing about their role or state.

## Web (Chromium)

| # | Shipping's header | `aria-expanded` | Tab stops, closed (after Back) | Enter, Space |
| --- | --- | --- | --- | --- |
| p01 | `role="button"`, `tabindex="0"`, `aria-description` "Collapsed …" | none | Shipping, Returns | each opens it |
| p02 | as p01 | none | Shipping, Returns, then two more Tabs with DOM focus left on Returns: the closed panels' buttons | each opens it |
| p03 | `<h3 tabindex="0">`, the description as p01; no button | none | Shipping, Returns | each opens it |
| p04 | text; beside it a `role="button"` with no name (the `ExpandIcon`) | none | two unnamed buttons | not looked at (see below) |
| p05 | `role="button"`, `aria-current="false"` | none | Shipping twice, Returns twice: the header and the `ExpandIcon` inside it | each opens it |
| p06 | `role="button"`, no `tabindex`, `aria-description` "Collapsed …" | none | Back only | not reached |
| p07 | `role="button"`, `tabindex="0"` | `false`, then `true` | Shipping, Returns | each opens it, and Enter again closes it |
| p08 | `<h3 tabindex="0">`; no button | none | Shipping, Returns | each opens it |
| p09 | `<h3>` holding `role="button"` | `false`, then `true` | Shipping, Returns | each opens it |
| p10 | as p07 | as p07 | as p07 | as p07 |
| p11 | as p07; no `aria-controls`, closed or open | as p07 | as p07 | as p07 |
| p12 | as p07, named "p12 Shipping collapsed" ([FL-037](../../../flutter-limitations.md#fl-037)) | as p07 | as p07 | as p07 |
| p13 | as p07; the tap hint is not in the page | as p07 | as p07 | as p07 |
| p14 | as p07 | as p07 | Shipping, Returns, then two more with DOM focus left on Returns | Space opens it; Enter does nothing, as its header has no action for `ButtonActivateIntent` ([FL-002](../../../flutter-limitations.md#fl-002)'s mechanism), and a click then opens it |
| p15 | as p01, and `aria-expanded` | `false`, then `true` | Shipping, Returns | each opens it |
| p16 | as p07 | as p07 | as p07 | as p07 |
| p17 | as p07, with `aria-controls` naming the open panel's element, kept after it closes | `true`, then `false` | | |
| p18 | as p07; `aria-controls` names the panel while it is open | as p07 | as p07 | as p07 |

Chromium's tree, for the same: p01, p02, p05, p15 are buttons named by the
title; p03 and p08 are headings of level 3 and no button; p06's headers are
buttons that are not focusable; p09 is a heading "p09 Shipping" of level 3
holding a button "p09 Shipping" with `expanded: false`, which is how
Chromium reads APG's plain HTML (`<h3><button aria-expanded="false">`, the
`html` lines: heading "h01 Shipping" level 3, button "h01 Shipping"
`expanded: false`). An ARIA `role="heading"` holding a `role="button"`
reads the same (h04); a `role="button"` with `aria-level` is a button only
(h05). A `details` element's `summary` is a `DisclosureTriangle` with
`expanded: false` (h03).

Once p06 is open, its header and the panel's text are one group, "p06
Shipping p06 Shipping panel", and the panel's button is a button of its
own after it.

The probe's "header reached after 5 Tab(s)" for p04 and p06 is a false
match: DOM focus was on the page itself (`flutter-view`), whose text holds
the header's, and Enter and Space there did nothing. Neither header is a
Tab stop.

On the web the hidden panels' buttons are Tab stops with no element:
Flutter's focus moves to them and the page's focus stays on the last
header that had it (p02, p14). The widget tests show which button has
Flutter's focus.

## Android (17)

| # | Shipping's header node | Expanded state (API 36) | TalkBack with focus on it, closed | TalkBack on the click |
| --- | --- | --- | --- | --- |
| p01 | `View`, "p01 Shipping, Collapsed", click label "Expand for more details", inside a live region node "Collapsed" | undefined | "p01 Shipping, / Collapsed / Double-tap to Expand for more details" | "Expanded" |
| p02 | as p01 | undefined | as p01 | as p01 |
| p03 | as p01, and a heading | undefined | as p01, with "Heading" | as p01 |
| p04 | `View` "p04 Shipping", not clickable; beside it a `View` "Expand" holding a `Button` with no name | undefined | "p04 Shipping" | nothing (the click on the text did not open it) |
| p05 | `Button` "p05 Shipping", click label "Expand" | undefined | "p05 Shipping / Button / Double-tap to Expand" | nothing |
| p06 | `View` "p06 Shipping", click label "Expand for more details"; open, "p06 Shipping\np06 Shipping panel" | undefined | "p06 Shipping / Double-tap to Expand for more details" | nothing |
| p07 | `Button` "p07 Shipping" | collapsed, then full | "collapsed. / p07 Shipping / Button / Double-tap to activate" | "fully expanded" |
| p08 | as p07, and a heading | as p07 | as p07, with "Button. Heading" | "fully expanded" |
| p09 | `Button`, not a heading, inside a heading node with no name | as p07 | as p07 | "fully expanded" |
| p10 | as p07, with `ACTION_EXPAND` (closed) or `ACTION_COLLAPSE` (open); each opened or closed it | as p07 | as p07, and "Actions available, use Tap with 3 fingers to view" | "fully expanded" |
| p11 | as p07; the panel is a node "p11 Shipping panel" holding its button | as p07 | as p07 | "fully expanded" |
| p12 | `Button` "collapsed, p12 Shipping": the value before the name | as p07 | not read (the walk found no node named "p12 Shipping") | |
| p13 | as p07, click label "expand", then "collapse" | as p07 | "collapsed. / p13 Shipping / Button / Double-tap to expand" | "fully expanded" |
| p14 | as p07 | as p07 | as p07 | "fully expanded" |
| p15 | `Button` "p15 Shipping, Collapsed", inside p01's live region | as p07 | "collapsed. / p15 Shipping, / Collapsed / Button / Double-tap to Expand for more details" | "Expanded / fully expanded" |
| p16 | as p07 | as p07 | as p07 | "fully expanded" |
| p17 | as p07, open from the start | full, then collapsed | "fully expanded. / p17 Shipping / …" | "collapsed" |
| p18 | as p07 | as p07 | as p07 | "fully expanded" |

After each click the walk cleared TalkBack's focus and put it on the header
again; TalkBack said nothing then, for every fixture (`-expanded` rows).
Why was not looked into. C05's own walk moves focus to the panel's text and
back instead.

The tree before a click has no panel node in any fixture: with
`maintainState: true` (p02) and in `Expansible` (p14) the closed panel is
`Offstage` and has no node either.

Keys (`android-keys.txt`, the second run, ten fixtures): from a fresh
launch, Tab stops on Back, then each header; p01 and p02 on "Shipping,
Collapsed" and "Returns, Collapsed"; p05 twice on each header (the
`ExpandIcon` inside it is a second stop); p04 and p06 on no header at all,
only Back (for p04 the `ExpandIcon` buttons take focus but have no name, so
the probe's reading shows "(none)"). Two Tabs and Enter, and two Tabs and
Space, opened Shipping in p01, p02, p05, p07 to p09, p14, and p16, with
focus left on the header, and the next Tab went to the open panel's
button, then to Returns. In p02 and p14, after Returns, Tab went on with
the tree still reporting Returns as focused: Flutter's focus was on the
closed panels' buttons, which have no node.

Native (`ProbeNativeActivity.kt.txt`, the second run): n01, a `Button`
whose delegate adds `ACTION_EXPAND` or `ACTION_COLLAPSE` as the Android
View reference does, has those actions and no expanded state; n02 also
sets the heading and `setExpandedState`, and has the state "collapsed",
then "full", after a click. TalkBack read n01 "Double-tap to activate.
Actions available, use Tap with 3 fingers to view", with no state word and
without its name in the capture; then the walk could not put focus back on
n01 after its click and stopped, so n02 was not read.

## iOS (27.0)

Every "double tap" in this section, and in the probe's iOS source, is
XCUITest's `doubleTap()` at the element with VoiceOver on. As C04 measured
(probe round 3, `docs/evidence/probes/c04/ios_round3.txt`), that gesture
acts on what is under it and is not VoiceOver's activation of what its
cursor is on; `XCUIVoiceOverService` has no activation. So what VoiceOver's
own double tap, made by a person, does or says here was not measured.

| # | Shipping's header to XCUITest | VoiceOver, closed | After XCUITest's double tap | Two Tabs, then Enter or Space |
| --- | --- | --- | --- | --- |
| p01 | static text, no value | "p01 Shipping Collapsed double tap to expand" | "Expanded" (the tile's announcement) | opens it |
| p02 | as p01 | as p01 | as p01 | opens it |
| p03 | other (type 1), no value | "p03 Shipping Heading Collapsed double tap to expand" | "Expanded" | opens it |
| p04 | static text; then "Expand" and "Button", two stops | "p04 Shipping / Expand / Button" | nothing (the double tap on the text opened nothing) | opens it (the second Tab is on the `ExpandIcon`) |
| p05 | button | "p05 Shipping Button" | nothing more | opens it; three Tabs also open it (the `ExpandIcon` inside) |
| p06 | static text; once open, "p06 Shipping\np06 Shipping panel", other (type 1) | "p06 Shipping Collapsed double tap to expand" | nothing more | nothing, after one, two, or three Tabs |
| p07 | button, no value | "p07 Shipping Button" | nothing more | opens it |
| p08 | button | "p08 Shipping Button Heading" | nothing more | opens it |
| p09 | button | "p09 Shipping Button": no heading | nothing more | opens it |
| p10, p11, p13, p16, p18 | button, no value | as p07 | nothing more | opens it |
| p12 | button, value "collapsed" | "p12 Shipping collapsed Button" | nothing more | opens it |
| p14 | button | as p07 | nothing more; the panel did not open | opens it |
| p15 | button | "p15 Shipping Button Collapsed double tap to expand" | "Expanded" | opens it |
| p17 | button, open from the start | "p17 Shipping Button / p17 Shipping panel / …" | | closes it |

Moving on from an open header read its panel's text, then its button,
then the next header, in every fixture that opened. A double tap on p14
and a tap on it in `testTree` did not open it on iOS, while a tap opened
it on Android and the web and Tab and Enter opened it on iOS; why was not
looked into (p14 has no example; `bad-hidden-panel` is built
differently).

One Tab and then Enter or Space opened nothing in any fixture. Whether
Back took them was not read: the probe app's first screen lists every
fixture, and the probe's check that the fixture was still there would
have found it on that list too.

Native, UIKit and SwiftUI (`testNative`):

| | VoiceOver, closed | Open |
| --- | --- | --- |
| n01, `UIButton` with `accessibilityExpandedStatus` | "n01 Shipping Button Collapsed Double-tap to expand" | "n01 Shipping Button Expanded Double-tap to collapse", then "n01 panel text" |
| n02, the same with the header trait | "n02 Shipping Button Heading Collapsed Double-tap to expand" | "n02 Shipping Button Heading Expanded Double-tap to collapse" |
| n03, SwiftUI `DisclosureGroup` | "n03 Shipping Button Collapsed Double-tap to expand" | "n03 Shipping Button Expanded Double-tap to collapse" |

After XCUITest's double tap that opened each, VoiceOver said nothing more in the
three seconds read, as for Flutter's headers; the new state was read when
the cursor came back to the header.

## What the probe decided

- **No SDK accordion is a good example.** `ExpansionTile` (p01) has no
  expanded state anywhere and no button role on Android and iOS
  ([FL-264](../../../flutter-limitations.md#fl-264));
  `ExpansionPanelList` (p04, p05) names every expand button "Expand" and
  has no state ([FL-267](../../../flutter-limitations.md#fl-267));
  `CupertinoExpansionTile` (p06) takes no keyboard focus and has no role
  or state ([FL-265](../../../flutter-limitations.md#fl-265)). The good
  examples are hand-built headers on p07's pattern, with a Material
  `ListTile`, a `CupertinoListTile` (p16's), and a `GestureDetector` as
  what takes the taps.
- **The state needs more than `expanded` on iOS and on Android before 16.**
  On iOS nothing of `expanded` reaches VoiceOver
  ([FL-260](../../../flutter-limitations.md#fl-260)); p12's value is read
  instead, so the good examples give iOS the value. On Android 17 the state
  is read (p07); before Android 16 the engine does not pass it (source
  read, [FL-261](../../../flutter-limitations.md#fl-261)), so the good
  examples also set p13's tap hint, which the engine passes on every version
  (source read; heard here on Android 17 only).
  The value is iOS only: Android puts it before the name (p12) and the web
  in the name.
- **The heading goes on the button's node on Android and iOS, and round it
  on the web.** On the web a heading node is never a button (p08,
  [FL-262](../../../flutter-limitations.md#fl-262)); p09's nesting is
  APG's markup there, and on Android leaves an unnamed heading and a
  button that is not one. `bad-heading-on-button` is p08 on every platform.
- **A closed panel is not built.** Kept with `Offstage` (p02, p14) it is
  out of the semantics tree but its buttons keep keyboard focus
  ([FL-263](../../../flutter-limitations.md#fl-263)): `bad-hidden-panel`.
- **`controlsNodes` is set only while the panel is open** (p18), as set
  all along it never reaches the page (p11,
  [FL-266](../../../flutter-limitations.md#fl-266)).
- **`onExpand` and `onCollapse` are given.** On Android 16 and later they
  add the expand and collapse actions, which both Android references give
  a header, and each opened and closed the section (p10). TalkBack then
  adds "Actions available" to what it says. Before Android 16 the engine
  does not pass them ([FL-261](../../../flutter-limitations.md#fl-261)).

## C05's first transcript runs

Kept as they were, before the fixes they led to:

- `talkback-first-run.md.txt`: the first TalkBack walk of the examples.
  For `bad-no-state` and `bad-cupertino-expansion-tile` TalkBack said
  nothing on the click, in three walks; and in
  `bad-cupertino-expansion-tile` the panel's text has no node of its own
  once open, so the walk's move to it, and back to the header, read
  nothing. The walk now drops the speech on the click for those two and
  moves to Back in place of the panel there.
- `voiceover-ios-first-run.md.txt`: the first iOS VoiceOver run. Every
  reading was as expected but one: open, `bad-cupertino-expansion-tile`'s
  header and panel are one utterance longer than the 64 characters
  `XCUIVoiceOverService` returns, and it was cut short. The second run
  (`voiceover-ios-second-run.txt`, its lines from the evidence run's
  output) read it the same way ("… Expanded double tap to collap"); the cut
  falls before VoiceOver's line breaks are made spaces, so it is not the
  first 64 characters of the reading as the test writes it. The
  expectation is now that cut reading.
  In the same run of the tree tests, XCUITest listed an open panel's
  elements after the next header, which is not the reading order; that
  test now checks the panel's place on screen.


## C05's Android tests at CI's screen size

C05's Android tree tests were run once at the CI emulator's size, 320 by
640 at 160 dpi, on the local emulator (`android_320x640.sh.txt`, which
resets both after): fifteen tests, none failed, `talkBackWalk` skipped with
TalkBack off (`android_320x640.txt`, the JUnit summary at its end). The
emulator is still Android 17 at that size, so this runs the Android 16 and
later branch; the API 35 branch runs only on CI.
