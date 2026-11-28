# V01 probe: the colours Flutter's widgets draw, light and dark

Run on 2026-11-28, Flutter 3.47.5, before the V01 examples were written.
The fixture is `probe.dart.txt`, a second entry point and not part of the
app. Route `/f/<id>` shows one fixture, `/f/<id>/dark` the same in the
dark theme, in a box framed by a magenta (#FF00FF) line 3 logical pixels
wide, with 16 logical pixels of the page inside the frame; the analyser
finds the box by its frame in any screenshot. The theme is the catalog
app's, `ThemeData(colorSchemeSeed: Colors.indigo)`.

Two rounds of the fixture:

- **Round 1** (every platform): a dark route put a dark `Theme` inside the
  light `MaterialApp`. A `Theme` passes on the Cupertino theme above it
  rather than deriving one from its own data (read in the source,
  `material/theme.dart`, `_inheritedCupertinoThemeData`), so the
  Cupertino fixtures were drawn light in the dark routes. Every Material
  fixture, and every light route, is as the app draws it; the dark
  Cupertino routes of round 1 are not (`flutter_test_round1.txt`,
  `web_round1.txt`, `devices_round1.txt` say so only here).
- **Round 2** (the widget tests and Chromium): the dark route also puts a
  `CupertinoTheme` derived from the dark Material theme above the `Theme`,
  and sets the platform's brightness dark, as the app is in dark mode.
  The Cupertino fixtures were run again (`flutter_test_round2_cupertino.txt`,
  `web_round2_cupertino.txt`). Android and iOS were not run in round 2;
  their dark Cupertino figures come from the V01 examples' own tests.

| # | Fixture | # | Fixture |
| --- | --- | --- | --- |
| t1 to t8 | `Text` in `onSurface`, `onSurfaceVariant`, `outline`, `primary`, `error`, `onSurface` at 0.38, `Colors.grey`, `outlineVariant` | c1, c2 | `CupertinoButton`, `.filled`, in the app's theme |
| k1 to k4 | `Text` in `CupertinoColors.label`, `secondaryLabel`, `tertiaryLabel`, `placeholderText` | c3s, c4s | the same under a default `CupertinoThemeData` (`systemBlue`) |
| k5 | `Text` in `secondaryLabel`'s high-contrast colour | c5, c6 | `CupertinoTextField`, empty with a placeholder, and with text |
| m1 to m5, m32 | `FilledButton`, `OutlinedButton`, `TextButton`, `ElevatedButton`, `FilledButton.tonal`, `IconButton` | c7, c8 | `CupertinoSwitch` off, on |
| m1d, m2d, m11 | disabled `FilledButton`, `OutlinedButton`, `TextField` | c9 | `CupertinoCheckbox` off and on |
| m6 to m12, m35 | `TextField`: outlined with a label, with a hint, underlined, filled, with an error, with text, focused | c10, c11 | `CupertinoSlidingSegmentedControl`, `CupertinoSegmentedControl` |
| m13 to m16 | `Checkbox` off, on, with `isError`; `Radio` off and on | c12, c13 | `CupertinoListTile` with a subtitle; `CupertinoListSection.insetGrouped` |
| m18 to m20 | `Switch` off, on; `Slider` | c14 | `CupertinoActionSheet` with a title and a message, drawn in the page |
| m21 | `ListTile`, one selected, one not | c15, c17 | `CupertinoSlider`; `CupertinoSearchTextField` |
| m22 to m27 | `FilterChip`, `ChoiceChip`, `SegmentedButton`, `ToggleButtons`, `TabBar`, `NavigationBar`, each with one chosen | g1 | white text on a gradient from #1A237E to #C5CAE9 |
| m28 to m31 | `Divider`, `Card.outlined`, `LinearProgressIndicator`, `Chip` | g2 to g4 | `GridTileBar` over the gradient, with no background, `Colors.black54`, `Colors.black87` |

- **Round 3** (Chromium and WebKit, after the principal's review):
  FL-515. `probe3.dart.txt` shows one control per route in the catalog
  app's `MaterialApp` (theme and dark theme, the browser's colour scheme
  choosing): an `OutlinedButton`, a `CheckboxListTile`, a `RadioListTile`,
  and an outlined `TextField`, each at its default and with one layer of
  its ink turned off by a documented parameter (b0 to b3, c0 to c5, r0 to
  r4, e0; the fixtures' own descriptions in the file). `probe3_web.spec.js.txt`
  with `probe3_web.config.js.txt`, at a scale factor of 3, measures each
  text with V01's text measure (its helpers copied from the web tree spec)
  at rest, hovered, and with the mouse button held 0.3 s, 2 s, and 4 s,
  light and dark, in Playwright's Chromium and WebKit
  (`probe3_web.txt`). The V01 web tests with the examples under the theme
  with no splash: `web_pressed_without_splash.txt`.

## How it was looked at

- **Widget tests**: `probe_test.dart.txt`, at a device pixel ratio of 3,
  light and dark, at rest, and for the fixtures that take input: a mouse
  over the control, a press held, Tab focus, and focus with the mouse
  over it. The press of this probe did not register (its captures equal
  the hover's); the V01 widget tests press properly. Each capture is a
  PNG; the colour scheme's roles are printed (`flutter_test_roles.txt`).
- **Web**: Chromium on macOS, Playwright, 400 by 600 at a scale factor of
  1, `probe_web.spec.js.txt` with `probe_web.config.js.txt`: every
  fixture at rest; a mouse hover, a mouse button held 0.6 s, Tab focus,
  and focus with the hover for the input fixtures; and Chromium's
  accessibility tree over the DevTools protocol for 22 fixtures
  (`web_trees.txt`).
- **Android**: the Pixel emulator, Android 17, 1080 by 2424 at 420 dpi,
  `android_probe.sh.txt` under the device lock: each fixture opened by its
  route, `screencap`; for 13 fixtures a finger held with `input
  motionevent` and a screenshot while it was down; and the UI Automator
  tree of 22 fixtures (`android_round1.txt`).
- **iOS**: the iPhone 17 simulator, iOS 27.0, `V01ProbeUITests.swift.txt`
  run by `ios_probe.sh.txt`: each fixture opened by the `fluttera11y`
  scheme, `XCUIScreen` screenshots at rest and after Tab, and each
  element's type, label, value, and selected state for 22 fixtures
  (`ios_round1.txt`).

`analyse.py.txt` reads the PNGs (its own decoder, no libraries) and
prints for each capture: the page colour (the commonest along the inside
of the frame); the solid colours in the box, commonest first, each with
its share, its contrast against the page, and the scheme roles it matches
within 3 in each channel; the colours new against the same fixture's rest
capture; and, for the gradient fixtures, the text's lowest and highest
contrast against the colours 6 pixels above and below it. `compare.py.txt`
compares two analyses fixture by fixture. Ratios are WCAG's. Where a
ratio in the spec or a limitation entry is between two colours that were
measured apart (a text colour and a fill), it says that it was computed
from them.

The outputs:

- `flutter_test_round1.txt`, `flutter_test_round2_cupertino.txt`,
  `flutter_test_roles.txt`
- `web_round1.txt`, `web_round2_cupertino.txt`, `web_trees.txt`
- `devices_round1.txt`: Android and iOS at rest, for the fixtures the
  limitation entries cite (light: c3s, c4s, c5, c7, c8, c12, c14, c17, k2
  to k4, m1, m21, m25, m29, t3, g2; dark: m1, m21, m25, t3, g2)
- `android_round1.txt`, `ios_round1.txt`: the device runs' own lines and
  trees

## What the probe showed

Flutter draws the same colours on every platform: every solid colour that
both the widget tests and Chromium found in a fixture was the same, to the
last digit, but for the translucent action sheet (c14), one off in a
channel; the fixtures analysed on Android and iOS gave the same colours
again. What differs is the
anti-aliasing of real letters on the devices and the web, against the test
font's solid boxes. The figures are in the spec, section 7, and in the
limitation entries FL-510 to FL-517 and the extended FL-242, FL-253, and
FL-441.

## The V01 tests' own measurements

- `widget_tests.txt`: the V01 widget tests' logged measures.
- `web_tests_round1.txt`: the first full run of the web tree spec, which
  found FL-515; `web_pressed.txt`: its pressed-state tests again, with
  FL-515's readings asserted; `web_tests_evidence_run1.txt`: the web layer
  of the first evidence run, where the dark "Send me updates" read 4.65:1
  at 0.3 s (4.25:1 before), after which only the 2 s readings are
  asserted.
- `android_tests.txt` and `android_tests_320x640.txt`: the first version
  of the Android tests, before review, at the emulator's own size and at
  CI's 320 by 640 at 160 dpi.
- `android_tests_native.txt` and `android_tests_320x640_animations_off.txt`:
  the reviewed Android tests, run by the engineer with
  `android_runs.sh.txt` under the device lock (not by the evidence run,
  whose log does not keep the test's measures): at the emulator's own
  size, then at 320 by 640 at 160 dpi with the three animation scales at
  0, as CI's runner sets them; the size, the density, and the scales read
  first, put back, and compared (all the same as before). Each file is the
  test's own "V01" log lines, per test, from the logcat files Gradle
  keeps.
- `ios_tests.txt`: the iOS tests, from the evidence run.
- `voiceover-web-round1-fail.md.txt` and `.log.txt`: the principal's
  first web VoiceOver recording, which failed on the text fields' words;
  `fields_web.txt` (from `fields_web.spec.js.txt` with
  `fields_web.config.js.txt`): what each field's input carries at rest and
  with DOM focus, in Chromium and WebKit, and Chromium's accessibility
  tree.
- `talkback-android-round1.md.txt`: the first TalkBack walk, with no rows
  yet, from which the rows were written; `voiceover-ios-round1.txt`: the
  first iOS VoiceOver walk, the same way.
