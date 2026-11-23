# C13 probe: what Flutter's SnackBar and MaterialBanner give assistive technology, how long they stay, and what reaches and closes them

Run on 2026-11-22, Flutter 3.47.5, before the C13 examples were written.
The fixture is `probe.dart.txt`, a second entry point and not part of the
app. Each fixture is a `Scaffold` with "Before sNN", a button "sNN Show"
that shows the message, "sNN taps: N" (the message's action), "sNN
closed: …" (why the message went and how long after the show, from the
`ScaffoldMessenger`'s own `closed` future, timed by the app's clock), "sNN
nav: …" (`MediaQuery.accessibleNavigation` at the show), "sNN focus: …"
(what has Flutter's keyboard focus, updated on every change), then "After
sNN". The timings and the focus are on screen so that every platform's
tree can read them.

| # | Fixture |
| --- | --- |
| s01 | `SnackBar(content:)` |
| s02 | with an action, `SnackBarAction('sNN Undo')` (`persist` left to its default) |
| s03 | s02 with `persist: false` |
| s04 | `showCloseIcon: true`, no action |
| s05 | an action and `showCloseIcon: true` |
| s06 | `showMaterialBanner(MaterialBanner(content:, actions: [TextButton('s06 Dismiss')]))` |
| s07 | s01 with `duration: 10 s` |
| s08 | s03 with `behavior: SnackBarBehavior.floating` |
| s09 | s05 with a `closeIconColor` that is a `WidgetStateColor`, yellow when focused; added after the device rounds, widget tests only |

How each platform was looked at, and the raw output:

- Widget tests, as Android: `probe_test.dart.txt` (`flutter_test.txt`):
  each fixture's nodes once shown, with `accessibleNavigation` off and on,
  and the time until the message went, pumped in 100 ms frames; ten Tabs
  after the show and Escape; Tab to the action and wait, then three Tabs,
  or Escape and Enter there; the dismiss action, `popRoute`, a swipe down,
  a mouse resting on it; `accessibleNavigation` turned on while shown; a
  second SnackBar while s02 is shown. The app's clock does not run in a
  widget test, so the "closed" times there are not times; the "gone at"
  times are. `probe2_test.dart.txt` (`flutter_test_examples.txt`): the
  nodes of each C13 example once shown. `probe3_test.dart.txt`
  (`flutter_test_identifier.txt`): a SnackBar whose content is
  `Semantics(identifier:)` round its text (FL-007).
  `probe4_test.dart.txt` (`flutter_test_focus.txt`): what keyboard focus
  changes on each control, from screenshots (below). The probe app has a
  light theme only, so its "dark" rows are light.
- Source: `source_search.sh.txt` (`source_search.txt`): the Android
  embedding of the pinned engine and the framework searched for a reader
  of Android's accessibility timeout.
- Web: Chromium, Playwright, `c13_probe.spec.js.txt` with
  `c13probe.config.js.txt`, against `flutter build web -t lib/probe.dart`:
  the message's elements, everything Flutter wrote to its announcement
  elements, DOM focus after the show, five Tabs, the time until the
  message went; then Tab to the action and wait, then one Tab, or Escape
  and Enter there. Round 1 (`web_round1.txt`) matched s06's Flutter view,
  whose text holds "Dismiss", as its action; round 2 (`web_round2.txt`)
  requires a button.
- Android: Pixel 10a emulator, Android 17, 1080 by 2424 at 420 dpi.
  `ProbeC13Test.kt.txt`, run by `probe_android.py.txt` with `am
  instrument` (`android-tree.txt`). `probe()` read each fixture's nodes
  and its lifetime, and the dismiss action; it failed at s02's second
  launch (its Show button was not found), so it has s01 and s02 only.
  `keys()`: Tab stops after the show; its search for the action matched
  the Back button's icon ("icon 57490") first, so its Escape, Enter, and
  wait rows are on Back and measure nothing about the message (Enter on
  Back left the screen: "no node"). `timeout()` set Android's two
  accessibility timeout settings, `accessibility_non_interactive_ui_timeout_ms`
  and `accessibility_interactive_ui_timeout_ms` ("Time to take action"),
  to 60 s and put them back as they were, unset, in a `finally`: the log
  shows both before, during, and after. `talkBack()`, with TalkBack on
  through the project's `tool/talkback.py` (which restores the device):
  focus parked on "Before sNN", the Show button pressed with the click
  action, and the speech logged; then TalkBack focus on the message and
  its action (`android-talkback.md`, markers in
  `android-talkback-markers.txt`).
- iOS: iPhone 17 simulator, iOS 27.0. `ProbeC13UITests.swift.txt`, run by
  `ios_probe.sh.txt` (`ios.txt`): `testTree`, the elements once shown and
  the lifetime; `testKeys`, Tab stops after the show (its search for the
  action matched Back's icon, "icon 62832", as on Android, so its wait and
  Return rows are on Back); `testVoiceOver`, the cursor put on Show with
  `tap()`, `doubleTap()` at it (which acts on what is under the tap, C04
  probe round 3; VoiceOver's own activation was not measured), the speech
  for six seconds, then eight moves forward. No setting was changed;
  VoiceOver was turned on and off through `XCUIVoiceOverService`.

## What it shows

Times are from the show to the message's going.

| | Widget tests (as Android) | Web | Android | iOS |
| --- | --- | --- | --- | --- |
| The message's node | a live region named by the message, with the dismiss action; its action and Close are buttons of their own | a group named by the message (`aria-label`) holding its buttons; a message with no control is text | a polite live region named by the message, dismissable; its action a `Button` | an element labelled by the message; its action a button |
| Announced | (live region) | `flt-announcement-polite`, the message's words once, not its action | TalkBack: the message's words, not its action | VoiceOver: the message's words; the cursor stayed on Show |
| Focus after the show | not moved | stayed on Show | not read | (the cursor) stayed on Show |
| Tab after the show | Back, Show, the action, Close, Back; the banner's action is before Show | Show, the action, Close, then out of Flutter | Back, Show, the action, Close; banner as widget tests | as Android |
| No action (s01, s04) | 4.7 s; 4.4 s with `accessibleNavigation` | 4.26 s | 4.29 s; 4.27 s with TalkBack | 4.56 s; 4.28 s with VoiceOver |
| An action, the default (s02, s05) | still there at 15 s, either way | still there at 14 s | still there at 16 s; at 14 s with TalkBack | still there at 16 s; at 14 s with VoiceOver |
| An action, `persist: false` (s03, s08) | 4.7 s; 4.4 s | 4.27 s | 4.28 s; 4.28 s with TalkBack | 4.56 s; 4.27 s with VoiceOver |
| `duration: 10 s` (s07) | 10.7 s | 10.26 s | 10.35 s | 10.55 s |
| Android's accessibility timeout at 60 s | — | — | unchanged: 4.28 s, 4.29 s, 4.28 s, 10.34 s, 4.29 s (s01, s03, s04, s07, s08) | — |
| `accessibleNavigation` | as set | — | true in every run, TalkBack off or on (why was not found) | false, and true with VoiceOver |
| A mouse resting on it | went at 4.7 s | — | — | — |
| Keyboard focus on its action | went at 4.6 s; then no node focused, and Tab went to Back | went at 4.26 s; DOM focus to Show (fixed), to Show or the Flutter view (floating) | not measured here (the C13 tests measure it) | not measured |
| Escape | nothing, focus anywhere | nothing; Enter then acted | not measured here (the C13 tests measure it) | not sent |
| Dismiss action | took it away (reason `dismiss`) | — | took it away (s01) | — |
| `popRoute` (Back) | popped the screen; the message stayed on the screen under it | — | — | — |
| Swipe down | took a SnackBar away; not the banner | — | — | — |
| A second SnackBar while s02 is shown | not shown 10 s later | — | — | — |

Focus indicators (`flutter_test_focus.txt`, the pixels keyboard focus
changes on and within 8 of the control, and how far each changes): the
default `SnackBarAction`, Close, and a `TextButton` in the banner change
by at most 1.15:1 to 1.38:1. s09's `closeIconColor` by state changed
nothing on focus. In the C13 examples, with the action's `textColor` and
`backgroundColor` turned round on focus and a 2 pixel outline on the
`TextButton`s and the page's button, over 3,600 pixels of Undo change by
3:1 or more, and 650 to 1,100 of the outlined buttons; Close still at most
1.34:1.

## Findings

- A SnackBar's time is the app's alone: FL-290.
- Escape closes no message, and Back takes it to the screen under: FL-291.
- Keyboard focus on an action is lost when the SnackBar times out: FL-292.
- A message waits behind one that stays: FL-293.
- The Close button's focus tint cannot be changed: FL-294 (and FL-430).
- A `MaterialBanner` outside the messenger is no live region: FL-295 (read
  in the source; the C13 tests measure it).
- An identifier inside the message splits the live region: FL-007.
- TalkBack reads the message node with "Actions available, use Tap with 3
  fingers to view", its dismiss action.
- With VoiceOver on, the cursor moved forward from Show reached a
  SnackBar that stays after the page's own lines, about 12 s after the
  show (s02, s05); for every timed one the moves never reached it, but
  they began after six seconds of listening, when it had gone.

## C13's Android suite at CI's size

After the examples were built, C13's Android tree tests ran once at the
CI emulator's size, 320 by 640 at 160 dpi (`android_320x640.sh.txt`, which
resets both after): the Gradle run ended "BUILD SUCCESSFUL", with
`talkBackWalk` skipped as TalkBack was off (`android_320x640.txt`).

## The first web VoiceOver recording, and the Close button

Recorded by the principal on 2026-11-22 with `tool/voiceover_web.py C13`,
against the examples as committed in 3c59dba; kept as
`voiceover-web-round1-fail.md.txt`, the tool's transcript. 4 of 10 tests
failed, the four walks (`good-action` and `good-banner`, in Chromium and
WebKit), each on its first walk, on expectations written as predictions:
the message is the group's name and not a stop of its own inside it, and
VoiceOver says "end of" the group on leaving it. The six announcements
passed in Chromium. The two browsers read the same but at the SnackBar's
Close: "Close button" in WebKit, "Close Close" with no role in Chromium.

`c13_close_probe.spec.js.txt` (`close_probe.txt`), plain Playwright with
no VoiceOver, in Chromium and WebKit, against the app's build, with
`good-action`'s message shown: Close, Undo, and Back are each a button
whose name is its text, with no `aria-label`, description, or `title`, and
Chromium's own tree names them "Close", "Undo", "Back". With the pointer
on Close its tooltip is shown: the button owns the tooltip's element
(`aria-owns`), in both browsers, and Chromium names it "Close Close",
still a button. Tab to Close shows no tooltip. Whether the tooltip was
shown during the recorded walk is not in the log.

## The second web VoiceOver recording

Recorded by the principal on 2026-11-22 against 45b9d7d; kept as
`voiceover-web-round2-fail.md.txt`. One test of ten failed:
`good-action`'s walk in Chromium, at Close, read "Close Close" again where
"Close button" was expected. Everything else passed: `good-banner` in both
browsers, `good-action` in WebKit (Close "Close button"), and the six
announcements. The diagnostic row `good-action-close-tooltip-after-walk`
said "shown" in both browsers: after the walk Close's tooltip was shown.
The walks now expect each browser's reading exactly.

The third recording, against 50889b8, passed: every test, every walk
complete on its first try. It is the transcript,
`docs/evidence/C13/voiceover-web.md`.

## Review round (Codex, 2026-11-22)

- `flutter_test_burst.txt`: the C13 widget tests "a burst of presses" run
  against `examples.dart` as of 3b3b982 (`hideCurrentSnackBar` and
  `hideCurrentMaterialBanner` before each show), where all six failed: a
  replacement stayed queued and came after the message was closed or
  gone, three SnackBars were seen for two presses; and against the fixed
  code (`clearSnackBars`, `clearMaterialBanners`), where all six passed
  (FL-293).
- `c13_undo_probe.spec.js.txt` (`web_undo.txt`), Chromium, no VoiceOver:
  after Undo on `good-action`, what of the two messages is in the tree and
  what is announced. Round 1, with "Archive undone" shown from Undo's
  `onPressed` after a clear: it never appeared, and nothing was
  announced. Round 2, shown from the first SnackBar's `closed` future: it
  appeared and was written to `flt-announcement-polite` (FL-296).

## The fourth web VoiceOver recording

Recorded by the principal after the review fixes (9eb7c64, eefe4ee); kept
as `voiceover-web-round3-fail.md.txt`. 3 failed, 7 passed: the three
announcement tests that then press the message's action and listen for
what it did (`-done-announced`). Every walk and every first announcement
passed. After Enter on Undo (`good-action`) VoiceOver in Chromium said
"Back and 1 more item and 2 more items group", "Back", and the usage hint;
after Enter on Go online, "Back" and the hint (`good-banner`), "Back and 1
more item and 2 more items group" and "Back" (`bad-inline-banner`). None
said "Archive undone" or "You are online.".

`c13_done_focus_probe.spec.js.txt` (`web_done_focus.txt`), Chromium with
no VoiceOver, pressing the same way: Flutter wrote "Archive undone" and
"You are online." to `flt-announcement-polite` about 50 ms after Enter and
emptied it about 300 ms later; DOM focus went to the page's button
("Archive message" after Undo, "Go offline" after Go online).

The principal decided (2026-11-22) to keep the design and record the
reading as FL-297.

## The fifth web VoiceOver recording

Recorded by the principal at 90f0877; kept as
`voiceover-web-round4-fail.md.txt`. 2 failed, 8 passed: the after-action
checks of `good-action` and `bad-inline-banner`, which heard "Archive
undone" and "You are online." this time, where the fourth recording heard
neither; `good-banner`'s heard "Go offline button", "Back", the hint, and
no message. The reading varied, so FL-297 now lists each recording, and
the after-action rows record every phrase and assert nothing about the
message (the principal's decision, 2026-11-22).

## The sixth web VoiceOver recording

Recorded by the principal at 3ea1098: every test passed. It is the
transcript, `docs/evidence/C13/voiceover-web.md`. The after-action rows
recorded: Undo, "Back" and the hint; `good-banner`'s Go online, "Back and
1 more item and 2 more items group", "Back", the hint;
`bad-inline-banner`'s, "Back and 1 more item and 2 more items group", "You
are online.".

## Review round (Codex, 2026-11-23)

`flutter_test_outgoing_undo.txt`: the C13 widget tests "the outgoing
message's action, during the next one's coming", against `examples.dart`
as of d7eebd9, where three of four failed (the newer message and its Undo
were gone after the outgoing Undo), and against the fixed code, where all
four passed (FL-293).

`flutter_test_outlive.txt`: the C13 widget tests "messages that outlive
their example", against `examples.dart` as of 6688803 (a count per example,
a confirmation whether or not its example was still there), where 5 of 9
failed, and against the fixed code (a count per messenger, a confirmation
only for an action that changed its example while it was there), where
all 9 passed.
