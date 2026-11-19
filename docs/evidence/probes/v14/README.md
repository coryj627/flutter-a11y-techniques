# V14 probe: focus indicators

Run on 2026-11-19, Flutter 3.47.5, before the V14 examples were written.
The fixture is `probe.dart.txt`, a second entry point and not part of the
app. Route `/c/<id>` shows one control alone in a box (identifier
`v14-box`) with 16 logical pixels of the page round it, so that anything
drawn outside the control is inside the box; `/c/<id>/dark` is the same in
the dark theme. Nothing else on the screen takes focus. A status line at
the top says whether focus is inside the box (`f=1`), Flutter's highlight
mode (`m=t` traditional, `m=h` touch), and, from round 3 of Android on,
the device id and flags of the last raw key event (`d=`), the theme
(`th=`), and whether Flutter counts a mouse as connected (`mouse=`). The
runs before Android round 3 used the source without those three fields;
nothing else changed.

| # | Fixture | # | Fixture |
| --- | --- | --- | --- |
| m1 | `ElevatedButton` | c1 | `CupertinoButton` |
| m2 | `FilledButton` | c2 | `CupertinoButton.filled` |
| m3 | `OutlinedButton` | c3 | `CupertinoSwitch` |
| m4 | `TextButton` | c4 | `CupertinoCheckbox` |
| m5 | `IconButton` | c5 | `CupertinoTextField` |
| m6 | `TextField`, `OutlineInputBorder` | w1 | a bare `Focus`, drawing nothing |
| m7 | `TextField`, default (underline) | w2 | `FocusableActionDetector`, ring from `onShowFocusHighlight` |
| m8 | `Checkbox`, not checked | w3 | `Focus`, ring from `onFocusChange` |
| m9 | `Checkbox`, checked | x1 | `ElevatedButton`, `overlayColor` transparent |
| m10 | `Switch` | x2 | `InkWell` in a `Card`, `focusColor` transparent |
| m11 | `Radio` in a `RadioGroup` | x3 | `TextButton`, `ButtonStyle.side` for the focused state |
| m12 | `ListTile` with `onTap` | x4 | `ElevatedButton`, an overlay of `onSurface` at 50% for the focused state |
| m13 | `InkWell` in a `Card` | x5 | `CupertinoButton`, `focusColor` of `CupertinoColors.label` |
| m14 | `FilterChip` | | |
| m15 | `Slider` | | |

Route `/o/<id>` shows twelve `OutlinedButton`s in a scrolling view 300
pixels tall, with something drawn over or beside it, and the status line
says, after each focus change, how much of the focused button is inside
the view and not under the overlay (`vis=`), from the render boxes'
rectangles:

| # | Fixture |
| --- | --- |
| o1 | a banner 72 pixels tall in a `Stack`, `Positioned` over the bottom of the view |
| o2 | the same banner below the view, in a `Column` |
| o3 | a `CustomScrollView` with a pinned `SliverAppBar` 72 pixels tall |
| o4 | a header 72 pixels tall in a `Stack` over the top of the view |
| o5 | a `Scaffold` with `extendBody: true` and a `BottomAppBar` |

## How it was looked at

For each control fixture: capture the screen with the control unfocused
(`u`); press Tab until the status line says focus is in the box; wait
1.2 s and capture (`f1`); wait 0.7 s and capture (`f2`); tap an empty part
of the screen and capture (`e`); then a fresh launch, a tap on the control,
and a capture (`t`). `analyse.py.txt` reads the PNGs (its own decoder, no
libraries) and prints, for the box: the pixels that changed from `u` in
both `f1` and `f2` and agree between them (a caret or an animation still
running is "unstable" and not counted); the commonest new colour (the
indicator), the colour it replaced, and their contrast ratio; the colours
next to the changed region and the indicator's ratio against each; and how
many pixels `e` and `t` differ from `u` by. Colours are the pixels' own;
ratios are WCAG's.

- Widget tests: `probe_test.dart.txt` (as Android and as iOS, light and
  dark, at a device pixel ratio of 1, captured from the layer tree) and
  `probe2_test.dart.txt` (the obscuring fixtures, Tab and Shift+Tab).
  Output: `flutter_test.txt`.
- Web: Chromium on macOS, Playwright, 400 by 500, `probe_web.spec.js.txt`
  with `p14.config.js.txt`; touches with `page.touchscreen`. Output:
  `web.txt`, which also gives the computed style of the element with DOM
  focus.
- iOS: iPhone 17 simulator, iOS 27.0, `V14ProbeUITests.swift.txt` run by
  `ios_probe.sh.txt`; Tab with `typeKey`, screenshots with `XCUIScreen`.
  Output: `ios.txt`.
- Android: Pixel 10a emulator, Android 17, 1080 by 2424 at 420 dpi,
  `hw.keyboard=yes`. Round 1, `android_probe.sh.txt` (Tab by `adb shell
  input keyevent`, `screencap`): `android_round1.txt`. Rounds 2 to 4,
  `ProbeV14Test.kt.txt` run with `am instrument` by
  `android_probe2.sh.txt` (screenshots by `UiAutomation.takeScreenshot`):
  `android_round2.txt` to `android_round4.txt`. Round 5,
  `android_probe5.sh.txt` (the emulator console): `android_round5.txt`.
  Round 6, `android_probe6.sh.txt` (a USB keyboard registered with the
  shell's `uinput` tool, Tab through it, `screencap`):
  `android_round6.txt`.

The V14 tests' own measurements, which the spec and the technique doc
cite alongside the probe's, are in `widget_tests.txt`, `web_tests.txt`,
`ios_tests.txt`, and `android_tests.txt` (the last at the emulator's own
size and at CI's 320 by 640 at 160 dpi).

## Two measures

The first analysis, `analyse.py.txt`, reported the commonest changed
colour and its contrast against the page and against the colour it
replaced; the V14 tests' first version also left out of the indicator
any changed pixel under 3:1 from the colour it replaced, unless that was
the page. That second rule compared the focused and unfocused states,
which 1.4.11 does not do, and it left out a checkbox's border that
darkens with focus. The review found it, and the measure was changed
(the V14 spec, section 6): every changed pixel is part of the indicator,
split into bands of flat colour, and each band is taken against what is
next to it in the focused capture: against the page if it is drawn where
the page was, against the colours on both sides of it if it is drawn on
the control. `analyse2.py.txt` applies that measure to the widget-test
captures again, rendered at a device pixel ratio of 3 so that 1 pixel
lines are flat bands (`probe_test.dart.txt` with `V14_DPR=3`); its output
is `flutter_test_measure2.txt`, which is what the verdicts rest on. The
colours below are the same in both; what changed is which parts count.

## What is drawn

The widget tests, the web, and iOS give the same colours to the last
digit for every fixture (Flutter paints the same pixels everywhere), and
so did Android for the four fixtures measured with a `uinput` keyboard in
round 6 (m1, m8, c1, w2); the figures below are those, light then dark,
against the page (`#FBF8FF` light, `#121318` dark), unless said otherwise.
With Android's own injected keys most of them are not drawn at all (next
section).

**Material, the default: a tint, a halo, or a border.**

- Buttons (m1 to m4), `IconButton` (m5), `ListTile` (m12), `InkWell`
  (m13), chip (m14), slider thumb (m15): an overlay, a tint of the
  control's own background or of the page under it. Against what it
  replaced: 1.15 (ElevatedButton, OutlinedButton, TextButton), 1.28
  (FilledButton, `#515B92` to `#636C9D`), 1.14 (IconButton), 1.32
  (ListTile), 1.31 (InkWell card), 1.32 (chip), 1.15 (slider); in dark,
  1.11 to 1.45. On an `IconButton`, which has no background of its own,
  the tint is a disc where the page was. An `OutlinedButton`'s outline
  also turns from `outline` to `primary` (round 2 on Android, where the
  tint was off: 1657 pixels of `#515B92`).
- `Checkbox` (m8, m9), `Radio` (m11), measured again
  (`flutter_test_measure2.txt`): unchecked or not selected, the halo and
  a border or ring that darkens to `#1B1B21`, 13.25:1 against the halo
  next to it (dark `#E4E1E9`, 11.38:1); checked (m9), the halo alone,
  `#EAE8F4`, 1.15:1 on the page (dark 1.22:1). The earlier description
  follows. A halo, a disc 40 pixels across
  round the 18 pixel box, outside it, of the text colour (or `primary`,
  when checked) at a tenth of its strength: `#E4E1E8`, 1.23:1 against the
  page (web 1.22:1, `#E4E2E8`), and 1.26:1 in dark. The box's border also
  turns from `onSurfaceVariant` to `onSurface` (`#46464F` to `#1B1B21`, a
  change of 1.82:1), and is 9:1 or more against the page either way. Read
  in the source: `material/checkbox.dart`, `_CheckboxDefaultsM3`,
  `overlayColor` (`onSurface.withOpacity(0.1)` for the focused state) and
  `side` (`onSurface` when focused).
- `Switch` (m10), measured again: the thumb darkens to `#46464F`, 5.95:1
  against the tinted track (dark: `#C7C5D0`, 5.50:1), beside the halo.
  The earlier description: the same halo round the thumb, partly over the
  track:
  `#D0CDD5` against the track `#E4E1E9`, 1.21:1; 1.49:1 at most against
  the page.
- `TextField` (m6, m7): the border or underline turns 2 pixels of
  `primary`, `#515B92`, 6.12:1 against the page (dark `#BAC3FF`, 10.9:1),
  and the label moves up and takes the same colour. This is drawn whenever
  the field has focus, after a tap too.

**Cupertino, the default: a pale ring.**

- `CupertinoButton` (c1, c2) and `CupertinoCheckbox` (c4): a ring 3.5
  pixels wide outside the control, `#8ABCF5`, 1.89:1 against the page;
  dark `#5C8EC6`, 5.42:1. It is the button's colour (here `activeBlue`) at
  80% made lighter and less saturated (read in the source:
  `cupertino/button.dart`, `kCupertinoFocusColorOpacity`, `Brightness`,
  `Saturation` in `cupertino/constants.dart`). In the app, where the
  Cupertino primary colour is the Material theme's `primary`, the same
  rule gives `#8A9AF5`, 2.49:1, and 3.79:1 in dark (the V14 widget and
  web tests of `bad-cupertino-ring`).
- `CupertinoSwitch` (c3): the same rule from its green, `#8AF3A5`, 1.29:1;
  dark 8.58:1.
- `CupertinoTextField` (c5): nothing is drawn but the caret; every changed
  pixel is unstable (the caret blinks).

**Widgets layer.**

- A bare `Focus` (w1): nothing at all.
- A ring drawn by the app (w2, w3): `#1B1B21`, 16.30:1 against the page,
  13.26:1 against the card's fill; dark `#E4E1E9`, 14.35:1.

**Customised.**

- Overlay made transparent (x1), `InkWell` `focusColor` transparent (x2):
  nothing at all, on every platform.
- `ButtonStyle.side` for the focused state (x3): a 3 pixel ring of
  `onSurface`, 16.30:1.
- A strong overlay (x4): `#88868D` over the button, a change of 3.25:1.
- `CupertinoButton` with `focusColor: CupertinoColors.label` (x5): a black
  ring, 19.97:1; white in dark, 18.55:1.

**On the web the browser's own outline is not what is seen.** The focused
element has the browser's default outline style (`outline: auto 1px
rgb(0, 95, 204)` in `web.txt`), but the semantics tree is transparent (the
engine sets `filter: opacity(0%)`, read in the engine source,
`lib/web_ui/lib/src/engine/semantics/semantics.dart`), and every change in
the screenshots is the same as in the widget tests and on iOS: Flutter's
own drawing on the canvas.

## When it is drawn: the highlight mode

Flutter decides whether to show focus highlights from the last input
(`FocusManager.highlightMode`; read in the source,
`widgets/focus_manager.dart`): a key makes the mode traditional and
highlights show; a touch makes it touch and they hide; before either, it is
touch on Android and iOS unless a mouse is connected, and traditional on
desktop platforms.

- Widget tests and iOS: Tab made the mode traditional (`m=t`); a tap on
  an empty part of the screen made it touch (`m=h`) with focus kept, and
  the highlight went (`e: 0`) for every fixture except those drawn from
  the focused state: the text fields' borders, the `Focus` ring (w3), and
  `ButtonStyle.side` (x3), whose ring stays while the overlay goes. On iOS
  a tap on a text field focused it in touch mode, with its border drawn.
- Web: the mode was traditional when the page opened (the platform is
  macOS) and after Tab; a touch made it touch. A tap on a button gave it
  focus (DOM focus follows the tap) with nothing drawn.
- **Android: injected keys leave highlights off; a registered keyboard's
  keys turn them on** (rounds 1 to 6). With injected keys, after every Tab
  the mode stayed touch and nothing that follows it
  was drawn (`changed=0` for m1, c1, w2 and the other overlays and rings),
  while the indicators drawn from the focused state were (m3's outline,
  m6, m7, w3, x3). Round 3 shows why: whatever device id the key was sent
  with (`input keyevent`; `Instrumentation.sendKeySync` with device 0,
  the emulator's keyboard; `UiAutomation.injectInputEvent` with device 0),
  Flutter received device id -1, Android's virtual keyboard (`d=-1/512`
  and `d=-1/520`). Flutter does not let a key from the virtual keyboard
  change the highlight mode (read in the source: `_HighlightModeManager.
  handleKeyMessage` and `_isKeyMessageFromAndroidIME`, which skip a key
  whose device id is -1 or that has the soft keyboard flag, added for
  [flutter/flutter#180746](https://github.com/flutter/flutter/issues/180746)).
  A mouse would also do (the default mode is traditional when a mouse is
  connected), but none of four ways of moving one reached Flutter as a
  mouse (round 4, `mouse=0`), and keys sent through the emulator's console
  did not reach the app at all (round 5). Round 6: a USB keyboard
  registered with the shell's `uinput` tool (it is on the emulator's
  image, `/system/bin/uinput`, and runs as the shell user on this `user`
  build) appeared in `dumpsys input` as an external keyboard; its Tab
  reached Flutter with device id 24 to 27 (one per session), and the mode
  became traditional (`m=t`). Every indicator was then drawn with the same
  colours as elsewhere: m1's tint `#E4E3EF` (1.15:1), m8's halo `#E4E1E8`
  (1.23:1), c1's ring `#8ABCF5` (1.89:1), w2's ring `#1B1B21` (16.30:1).
  In w2, the first session's first Tab switched the mode and did not move
  focus (the first-Tab-lost effect of I01); the second did. Closing the
  session removed the device (`dumpsys input` no longer listed it). Once
  the keyboard had been used, Android drew a 4 pixel lime frame
  (`#AAD42C`) round the edges of the screen, the status bar included, and
  a small icon in the status bar; no soft keyboard and no dialog appeared.
  `adb root` and `sendevent`, the other route considered, were not tried,
  since `uinput` worked (the local image is a `user` build,
  `android_round6.txt`). FL-433.

## Hidden under content drawn over the view

The same on every platform (widget test, web, Android, iOS):

- **o1, a banner over the bottom of the view**: Tab put focus on buttons
  wholly under the banner, `vis=0.00`, from the fifth button on (from the
  seventh on the web, where buttons are 32 pixels tall). Flutter scrolls a
  newly focused control into the view's own rectangle
  (`Scrollable.ensureVisible` from the traversal policy), and the view
  includes the part the banner covers; a control already inside it is not
  moved at all.
- **o2, the banner below the view**: every button wholly in sight (`vis`
  1.00, or 0.92 where 4 pixels of padding were outside the view).
- **o3, a pinned `SliverAppBar`**: every button in sight going down and,
  in the widget test, going up with Shift+Tab. A pinned sliver in the
  same viewport is allowed for (read in the source:
  `RenderViewport.getOffsetToReveal` subtracts
  `maxScrollObstructionExtentBefore`).
- **o4, a header over the top of the view**: the first button was wholly
  under it when Tab reached it (`vis=0.00`), and in the widget test
  Shift+Tab up the list put focus under it at every step from the seventh
  button.
- **o5, `Scaffold(extendBody: true)` with a `BottomAppBar`**: as o1, from
  the fifth button on. The body's `ListView` is padded by the bar's height
  at its end, but a control is scrolled to the view's edge, under the bar.

## What it shows

- Flutter draws its own focus indicators everywhere; on the web the
  browser's is hidden. What it draws is the same on every platform.
- Material shows focus on most controls with a tint at about 1.1:1 to
  1.45:1 against what it replaced: visible and faint. Inside a control's
  container 1.4.11 does not apply to it; where a control has no
  container, or nothing else of its own changes (a checked checkbox, a
  `TextButton`, an `IconButton`, a `ListTile`), the tint is all there is,
  under 3:1 on the page (FL-430). An unchecked checkbox, a radio button,
  and a switch add a halo and darken a border, ring, or thumb that is
  then 5.5:1 to 13:1 against what is next to it, which meets 1.4.11 as
  written (FL-434). A `Slider`'s thumb gains a black ring, 19.97:1 in
  light mode and 1.13:1 in dark (m15).
- Cupertino's default ring is under 3:1 in light mode: 1.89:1 for a
  button with the default blue, 1.29:1 for a switch, 1.89:1 for a
  checkbox; in dark mode the button (5.42:1) and the switch (8.58:1)
  pass and the checkbox does not (its largest bands 1.63:1 to 1.91:1)
  (FL-431). A `focusColor` fixes the button and the switch.
  `CupertinoTextField` shows only its caret (FL-435).
- A ring from `ButtonStyle.side`, from `Focus.onFocusChange`, or from
  `onShowFocusHighlight` reaches 13:1 to 20:1.
- Flutter shows most indicators only in its traditional highlight mode.
  On Android, keys injected with `input keyevent` or Instrumentation never
  reach it (they come from the virtual keyboard, device -1); keys from a
  keyboard registered with `uinput` do, and the V14 Android test uses one
  (FL-433).
- A focused control can be scrolled under content drawn over its view
  (FL-432); content laid out beside the view, or a pinned sliver in it,
  does not hide it.
