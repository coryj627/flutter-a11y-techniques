# I03 probe: focus management

Run on 2026-11-18, Flutter 3.47.5, before the I03 examples were written,
in three rounds. The fixture is a second entry point and not part of the
app: `probe_round1.dart.txt` is the first round as it ran on Android and
the web, and `probe.dart.txt` the last, which adds two buttons at the top
of the first screen (`r00 Round 3`, `r0 Round 2`) and two more screens.

A status bar at the bottom of the screen, outside the Navigator so that a
dialog's barrier does not hide it, shows where focus is, so that every
platform's tree can be read for it:

- `KF:` the node with Flutter's keyboard focus
  (`FocusManager.primaryFocus`), named by the first text under it, as
  `node:p1 Close`, or `scope:...` for a focus scope with no focused child
  (a route that has focus and no control in it). In a release web build
  a focus node's `debugLabel` is empty, so the name is looked up.
- `SR:` the semantics node the platform last said has accessibility
  focus: the engine's `didGainFocus` message, which Android and iOS send
  when TalkBack's or VoiceOver's focus lands on a node
  (`ServicesBinding.accessibilityFocus`, read in the source), named by
  its label. The web sends none.
- `Log:` what the fixtures did; `Keys:` the last keys that reached the
  framework.

On Android the probe also reads the node Android reports as
accessibility focused (`findFocus(FOCUS_ACCESSIBILITY)`, `A11Y` in the
output), and on the web the element with DOM focus (`DOM`) and, under
VoiceOver, the element under VoiceOver's cursor, found by comparing the
cursor's bounds on the screen with each element's (`VO on`).

## Fixtures

Round 1 (`/probe`). Every control's text starts with its fixture id.

| # | Fixture |
| --- | --- |
| p1 | `showDialog` with an `AlertDialog`: title, body, Other, Close |
| p2 | the same with `autofocus: true` on its second button, OK |
| p3 | `showModalBottomSheet`: title, Other, Close |
| p4 | `Navigator.push` of a `MaterialPageRoute` with a Done button |
| p5 | `showCupertinoDialog` with a `CupertinoAlertDialog`, two `CupertinoDialogAction`s |
| p6 | `showCupertinoModalPopup` with a `CupertinoActionSheet`, two actions |
| p7 | `Navigator.push` of a `CupertinoPageRoute` with a `CupertinoButton` Done |
| p8 | `showGeneralDialog` with a hand-made panel: title, Other, Close |
| p9 | an `OverlayEntry` inserted into the Navigator's overlay, no focus handling: title, Other, Close |
| p10 | a panel shown in the page right after its button, no focus handling |
| p11 | the same with `FocusNode.requestFocus` on the panel's Close when it opens and on the button when it closes |
| p12 | the same with a `FocusSemanticEvent` sent to the panel's title when it opens and to the button when it closes, and no keyboard focus moved |
| p13 | three buttons, Remove A, B, C, in a keyed list; pressing one removes it, nothing else |
| p14 | the same, and `requestFocus` on the next button (or the one before) |
| p17 | as p13 with no keys, so the element of a removed row is reused for the next |
| p15 | on a page of its own: a button whose `onFocusChange` opens a dialog, between two plain buttons |

Round 2 (`/round2`): rows `r1`, `r2`, `r3`, `r5`, each with Remove A, B,
and C, whose press opens a `showDialog` confirmation (Cancel, Confirm);
Confirm removes the row. r1: `requestFocus` on the next row at once. r2:
that and a `FocusSemanticEvent` to the next row after the frame. r3:
nothing. r5: as r2 with the event a second later. r4: a dialog shown
with `requestFocus: false`. In r2 and r5 the event was sent from a
render object whose semantics node was the identifier's own node, not
the button's (FL-043), so those two rows show nothing about the event.

Round 3 (`/round3`): the same confirmation, each row's button merged with
its identifier as `TestId` does, so that an event sent from the row goes
to the button's node. s1: confirm, then at once remove and `requestFocus`
the next row. s2: confirm, wait until the dialog route has animated out
and 400 ms more, then remove and `requestFocus`. s3: as s1, and a
`FocusSemanticEvent` to the next row a second later. s4: as s2, and the
event after the frame. t, u, v: no dialog; t removes and calls
`requestFocus`, u does that and sends the event, v only removes. `w`: a
button whose `onFocusChange` opens a dialog.

## How each platform was looked at

- Flutter test: `probe_test.dart.txt` (round 1 and 2, as Android and as
  iOS, keyboard driven, with the accessibility channel recorded and a
  `didGainFocus` message sent for the trigger to stand in for a screen
  reader). Output: `flutter_test.txt`, from the last probe source.
  `probe_test_round1.dart.txt` is the first round's version.
- Web: Chromium, Playwright. `probe_web.spec.js.txt` (round 1),
  `probe_web2.spec.js.txt` (round 2, served by `p03.config.js.txt` from a
  build of its own), `probe_web3.spec.js.txt` (round 3). Keyboard, and
  "focus and click": DOM focus put on the element and then a click, as
  VoiceOver gives them. Output: `web.txt`, `web_round2.txt`,
  `web_round3.txt`. VoiceOver: `probe_vo.spec.js.txt`, run by
  `tool/voiceover_web.py I03`; output `voiceover_web.txt`.
- Android: Pixel 10a emulator, Android 17, 1080 by 2424.
  `ProbeI03Test_round1.kt.txt` and `ProbeI03Test.kt.txt`, run by
  `android_probe.sh.txt`, `android_probe2.sh.txt`, and
  `android_probe3.sh.txt`, which turn TalkBack on through the
  accessibility settings, as `tool/talkback.py` does, and put both
  settings back (the output shows them before and after). TalkBack is
  driven as `tool/talkback.py` drives it: its focus is put on a control
  with `ACTION_ACCESSIBILITY_FOCUS` and the control is activated with
  `ACTION_CLICK`, as a double tap does; after that nothing moves its
  focus but TalkBack and the app. Output: `android.txt` (round 1;
  its TalkBack half did not build), `android_round2.txt` (round 1's
  TalkBack tests and round 2), `android_round3.txt`.
- iOS: iPhone 17 simulator, iOS 27.0. `I03ProbeUITests.swift.txt` run by
  `ios_probe.sh.txt`. VoiceOver through `XCUIVoiceOverService`: `tap()`
  moves its cursor and `doubleTap()` activates; `currentSpeech()` is what
  it said, and one move back and forward again shows where its cursor
  is. Output: `ios.txt`.

## What it showed: keyboard focus

The same in the widget test, on the web, on the Android emulator, and on
the iOS simulator unless a line says otherwise.

| Fixture | When it opens | Tab after it opens | When it closes |
| --- | --- | --- | --- |
| p1 Material dialog | the dialog route's scope; no control | p1 Other, p1 Close, and round inside the dialog | back on p1 Dialog; the next Tab is p2 |
| p2 with `autofocus` | p2 OK | inside the dialog | back on p2 |
| p3 bottom sheet | the sheet's scope | p3 Other, p3 Close | back on p3 |
| p4 Material page | the page's scope | Back, p4 Done | back on p4 |
| p5 Cupertino alert | the dialog's scope | nowhere: Tab never reaches an action (FL-440); on the web it goes back and forth between leaving the page and the dialog's scope | not reached by the keyboard; closed by a tap in the probe |
| p6 action sheet | the sheet's scope | p6 Other, p6 Close | back on p6. On the web Enter on an action does nothing and Space works (`web_round2.txt`, FL-002) |
| p7 Cupertino page | the page's scope | Back, p7 Done | back on p7 |
| p8 general dialog | the dialog's scope | p8 Other, p8 Close | back on p8 |
| p9 overlay entry | stays on p9 | on down the page, p10 to p16; the overlay's controls only after p16, the last of the screen | the Close button is removed with focus on it: focus goes to the screen's scope and the next Tab is Back |
| p10 inline panel | stays on p10 | p10 Close, right after it | Close removed: back on p10, the control focused before it |
| p11 inline, managed | p11 Close | | back on p11 |
| p12 inline, event only | stays on p12 | p12 Close | back on p12 |

- **A removed control hands focus to the control focused before it.**
  p13 (keyed rows): Tab to Remove A, Tab to Remove B, Enter: focus on
  Remove A. On the web, with focus put on Remove B directly and a click
  (as VoiceOver gives them), there was no control focused before it in
  that screen, and focus went to the screen's scope: the Flutter view had
  DOM focus and the next Tab was Back (`web.txt`). Read in the source:
  `FocusAttachment.detach` calls `unfocus(disposition:
  UnfocusDisposition.previouslyFocusedChild)`. p14 (`requestFocus` on the
  next row): Remove C. p17 (no keys): focus stays on the same element,
  which now shows Remove C.
- **`requestFocus: false` on a dialog route** (r4): focus stays on the
  button behind the dialog, the next Tab goes to the next control behind
  it (r9 Last), and only then into the dialog. On the web the engine put
  DOM focus on the dialog's title while Flutter's focus stayed behind
  (`web_round2.txt`).
- **The confirmation, then the removal** (round 2 and 3): Cancel puts
  focus back on the row's button; Confirm with `requestFocus` on the next
  row puts it there (r1, s1 to s4); with nothing done (r3), on the row
  focused before.
- **A control whose `onFocusChange` opens a dialog** (p15, w): one Tab
  onto it opens the dialog and moves focus into it. On the web, giving
  the element DOM focus from script does the same (`web_round3.txt`).
- **Tab past a dialog's last control** (`web_round2.txt`): in the
  Material dialog it goes round inside the dialog; in a general dialog, a
  bottom sheet, and an action sheet on the web it leaves the page and the
  next Tab comes back into the dialog.

## What it showed: TalkBack

Android 17 emulator. TalkBack activates a control with the click action
after its focus has been put on it; then only TalkBack and the app move
it.

- **Into a route, and back.** For every route that opens over the screen
  (p1, p2, p3, p5, p6, p8, and the round 2 and 3 confirmations) TalkBack's
  focus went into it, to its title or first element; for p2, to the
  title, not to the autofocused OK. For a pushed page (p4, p7), to Back.
  When the route closed, TalkBack's focus went back to the button that
  opened it, except once for p4, where it went to the probe's status bar
  (`android_round2.txt`; not looked into). This is the Navigator's doing:
  it records the node TalkBack is on and, when a route closes, asks for
  TalkBack's focus to go back there (read in the source:
  `widgets/navigator.dart`, `_RouteEntry.handleDidPopNext`, on Android
  300 ms after the route has gone).
- **`requestFocus: false`** (r4): TalkBack still went into the dialog.
- **No route** (p9 overlay, p10 inline): TalkBack stayed on the button
  when the panel opened, and went to Back, the top of the screen, when
  the panel's Close button, which it was on, was removed.
- **`requestFocus` moves TalkBack too** (p11): TalkBack followed keyboard
  focus to the panel's Close and back. With the keyboard driving and
  TalkBack on, TalkBack followed keyboard focus in every fixture.
- **`FocusSemanticEvent`** (p12): moved TalkBack to the panel's title.
  Sent to the button when the panel closed, it did not: TalkBack was on
  the Close button that had just been removed and went to Back.
- **A removed control** (p13, TalkBack activating it, nothing done):
  TalkBack went to Back.
- **The confirmation, then the removal, with TalkBack activating**
  (`android_round3.txt`): removing the row and calling `requestFocus` on
  the next row at once (s1) left TalkBack on Back, though keyboard focus
  was on Remove C; in round 2 the same code (r1) left it on Remove A.
  Waiting until the dialog route had animated out and 400 ms more before
  removing the row (s2), or sending a `FocusSemanticEvent` to the next
  row a second after the removal (s3), or both (s4), put TalkBack on
  Remove C. With no dialog (t), `requestFocus` alone did. With the
  keyboard driving and TalkBack on, every row ended on Remove C at once.
  The rows u, v, and w were not reached in the TalkBack run (they were
  off the screen and the test did not scroll); only their keyboard runs
  count.

## What it showed: VoiceOver on iOS

iPhone 17 simulator, iOS 27.0 (`ios.txt`). VoiceOver's cursor is put on
a control with `tap()` and the control activated with `doubleTap()`.

- **Into a route, and back.** For every route that opens over the screen
  VoiceOver went to its title (p2 too, not to the autofocused OK), and
  for a pushed page to its first element (p4 Back; p7 an element read
  only as "Button", then Back). When the route closed it went back to the
  button. With the keyboard opening and closing p1, VoiceOver went back
  to the element it had been on before, not to the button the keyboard
  had used: the framework restores the screen reader's own position.
- **No route** (p9, p10): VoiceOver stayed on the button, and went to
  Back when the panel's Close, which it was on, was removed.
- **`requestFocus` does not move VoiceOver.** p11: VoiceOver stayed on
  the button when keyboard focus went to the panel's Close. With the
  keyboard driving and VoiceOver on, VoiceOver did not follow Tab. p14
  and t: after a removal with `requestFocus` on the next button,
  VoiceOver went to Back.
- **`FocusSemanticEvent` moves VoiceOver**: to the next row after a
  removal (u, after the frame), and after a confirmed removal (s3, a
  second later; s4, after waiting for the route). In p12 it moved
  nothing, either way; not looked into.
- **The confirmation, then the removal**: s1 (`requestFocus` at once)
  and s2 (`requestFocus` after waiting) left VoiceOver on Back; s3 and s4,
  with the event, on Remove C.
- **`onFocusChange` that opens a dialog** (p15, w): VoiceOver's cursor on
  the button did not open it.

## What it showed: VoiceOver on the web

Chromium (`voiceover_web.txt`); WebKit not run. VoiceOver's cursor is put
on a control by giving its element DOM focus, and the control is
activated with VO-Space or with Enter.

- **VoiceOver follows DOM focus, and DOM focus follows Flutter's keyboard
  focus.** Into each dialog route: the Material dialog and the general
  dialog to their title (the engine puts DOM focus on a route's first
  element when no node asks for focus, read in the source:
  `SemanticRouteBase._setDefaultFocus`), p2 to OK. The action sheet: to
  the sheet as a whole. The bottom sheet: to "Scrim", the barrier's
  label. Back to the button when each closed.
- **No route**: the overlay (p9) and the inline panel (p10): VoiceOver
  stayed on the button.
- **A removed control** (p13 by VO-Space): VoiceOver went to the top of
  the screen; p14, with `requestFocus`, to Remove C.
- **The confirmation, then the removal**: s1, `requestFocus` at once, put
  VoiceOver on Remove C; s2, which waits, read Remove B first and then
  Remove C.
- **`onFocusChange` that opens a dialog** (p15, w): one VoiceOver move
  onto the button opened the dialog, and VoiceOver read it.
