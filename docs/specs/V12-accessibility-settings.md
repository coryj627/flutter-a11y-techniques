# Spec: V12 Detecting accessibility settings

Status: Draft 1 (2026-11-28), written with the build. Wave 5, visual
preferences. Flutter pin: 3.47.5.

What the framework tells an app about the user's settings, on each
platform, and how an app reads it so that it stays right while the app
runs. What an app then does with a setting is the technique that adapts to
it: high contrast is V02, inverted colours V04, text size V05, reduced
motion V09. Announcements (`supportsAnnounce`) are I12's, and a timed
message under `accessibleNavigation` is C13's.

## 1. Rule

An app reads the user's settings through the framework's documented API
in a way that hears of a change while the app runs, and does not count on
a flag that the platform never sets.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies | Applies | Limitation |

The principal decided these statuses on 2026-11-28 (section 5,
"Decisions"); the owner may overrule.

- **Android, applies.** Every flag Android sets reaches `MediaQuery` while
  the app runs, but two: a change of Bold text or of the contrast level
  starts the app again, and the app's new first frame is told the new
  value ([FL-504](../flutter-limitations.md#fl-504)). `accessibleNavigation` is
  on for TalkBack, and also for any other service that reads the app's
  nodes, and off in a screen's first frame
  ([FL-503](../flutter-limitations.md#fl-503)); "High contrast text" sets
  nothing (FL-504).
- **iOS, applies.** Every setting changed while the app ran reached it
  (VoiceOver, Increase Contrast, Smart Invert, Reduce Motion, Auto-Play
  Animated Images, Larger Text), but four: Bold Text, On/Off Labels,
  Auto-Play Video Previews, and Prefer Non-Blinking Cursor, which reached
  no running app on this simulator, a native UIKit app's included, only a
  new start (`docs/evidence/probes/v12/ios-round3.txt`, the native app's readings).
  Reduce Motion sets only `reduceMotion`, the second flag, which
  `MediaQueryData` does not carry
  ([FL-502](../flutter-limitations.md#fl-502)); `good-motion` reads it.
  Dark mode was not measured: neither tool changed the simulator's
  appearance for any app.
- **Web, limitation.** R1 cannot be met: `accessibleNavigation` says
  whether the app's semantics are on, and the app turns them on at start,
  so it is on with no screen reader
  ([FL-500](../flutter-limitations.md#fl-500)); no documented parameter
  tells a screen reader apart, and a browser does not tell a page whether
  one is running. So `good-media-query`'s first line is not good on the
  web, and the web has no good example for R1. R2 is met in part:
  `prefers-contrast: more` sets nothing, and `boldText`, `invertColors`,
  and `onOffSwitchLabels` are never set
  ([FL-501](../flutter-limitations.md#fl-501)). R3 and R4 are met.

Neither good example is a custom solution (section 5).

## 3. WCAG 2.2 success criteria

None. V12 is an enabler, with no success criterion of its own (the
coverage inventory: "— (enabler)"; the iOS reference: "Applicable WCAG
Success Criteria: N/A"). It serves the criteria of the techniques that
adapt to a setting: 1.4.3 and 1.4.6 (V02, high contrast), 1.4.4 (V05,
text size), 2.2.2 and 2.3.3 (V09, motion), and 2.2.1 where a time limit is
lengthened for a screen reader user (C13). No example here is said to
pass or fail a criterion: a line that reports a setting wrongly fails the
user who reads it, and the criterion it would fail is the adapting
technique's, which these examples do not build.

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | The app can tell whether an assistive technology such as a screen reader is running | [iOS Accessibility Detection](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/AccessibilityDetection.md) ("`UIAccessibility.isVoiceOverRunning`"), [`MediaQueryData.accessibleNavigation`](https://api.flutter.dev/flutter/widgets/MediaQueryData/accessibleNavigation.html) |
| R2 | The app can read each display and motion setting the platform has | iOS Accessibility Detection ("All of the iOS accessibility features can be detected", its settings list), [`MediaQueryData`](https://api.flutter.dev/flutter/widgets/MediaQueryData-class.html), [`AccessibilityFeatures`](https://api.flutter.dev/flutter/dart-ui/AccessibilityFeatures-class.html) |
| R3 | A setting changed while the app runs reaches what the app shows while it runs | [`MediaQuery`](https://api.flutter.dev/flutter/widgets/MediaQuery-class.html) (each "…Of" method rebuilds its caller when its field changes; `MediaQueryData.size`: "It is considered bad practice to cache" a value read from it), [`WidgetsBindingObserver.didChangeAccessibilityFeatures`](https://api.flutter.dev/flutter/widgets/WidgetsBindingObserver/didChangeAccessibilityFeatures.html) |
| R4 | The app does not count on a flag the platform never sets: where the platforms set different flags for one request, it reads each | `MediaQueryData.disableAnimations` ("On iOS, reduced motion is exposed separately via `AccessibilityFeatures.reduceMotion` and does not set this flag"), `AccessibilityFeatures` ("Only supported on iOS", and the like, on several flags) |

The iOS reference's own advice, that detecting a setting "may lead to
creating unequal experiences" and is for when a different experience is
needed, is not a requirement that an example can show; the examples only
say what the app was told.

Flutter references for the mechanisms used:

- [`MediaQuery.boldTextOf`](https://api.flutter.dev/flutter/widgets/MediaQuery/boldTextOf.html)
  and the other aspect methods (`accessibleNavigationOf`, `highContrastOf`,
  `invertColorsOf`, `disableAnimationsOf`, `onOffSwitchLabelsOf`,
  `platformBrightnessOf`, `textScalerOf`): "Use of this method will cause
  the given [context] to rebuild any time that the
  [MediaQueryData.boldText] property of the ancestor [MediaQuery] changes",
  and the same for each (`widgets/media_query.dart`, read at the pin).
- [`PlatformDispatcher.accessibilityFeatures`](https://api.flutter.dev/flutter/dart-ui/PlatformDispatcher/accessibilityFeatures.html),
  read through `View.of(context).platformDispatcher`, and
  `WidgetsBindingObserver.didChangeAccessibilityFeatures`.
- `TextScaler.scale`: on Android 14 and later the platform's scaler is not
  linear (`SystemTextScaler`), so a scale is given for a font size.

The full set the pinned framework has, and where each comes from (source
read): `MediaQueryData` has `accessibleNavigation`, `boldText`,
`highContrast`, `invertColors`, `disableAnimations`, `onOffSwitchLabels`,
`supportsAnnounce`, `textScaler`, `platformBrightness`,
`alwaysUse24HourFormat`, `navigationMode`, `gestureSettings`,
`supportsShowingSystemContextMenu`, the four text spacing overrides
(`lineHeightScaleFactorOverride`, `letterSpacingOverride`,
`wordSpacingOverride`, `paragraphSpacingOverride`), and
`displayCornerRadii`. `AccessibilityFeatures` has the first six flags,
`supportsAnnounce`, and four that `MediaQueryData` does not carry:
`reduceMotion`, `autoPlayAnimatedImages`, `autoPlayVideos`, and
`deterministicCursor`. `SemanticsBinding.semanticsEnabled` says whether
the semantics tree is being built, with
`addSemanticsEnabledListener`; `ensureSemantics` turns it on. Nothing else
in the SDK reports a user setting.

Radix comparison bar: none; the bar is the platform's own API, measured by
a native UIKit app on iOS where a setting did not reach Flutter
(section 7).

### Material, Cupertino, and the widgets layer

Reading a setting is the widgets layer's (`MediaQuery`,
`WidgetsBindingObserver`); Material and Cupertino add no parameter for it.
What they do with a setting is measured where it matters (`MaterialApp`
choosing `highContrastTheme` and `darkTheme`, section 7) and is the
adapting techniques'. Both good examples are the widgets layer.

## 5. Examples

The settings lists say, one line each: "Accessible navigation", "Bold
text", "High contrast", "Invert colours", "Disable animations", "Switch
labels" (`onOffSwitchLabels`), and "Dark mode", each "on" or "off", and
"Text scale: 100%", the scale for text of 14 points, the body text's size.
The motion examples say "Reduce motion: on" or "off".

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-media-query` | Widgets layer | Which settings the app was told are on, kept up to date | `MediaQuery`'s `...Of` method for each | R1, R2, R3 |
| `good-motion` | Widgets layer | Whether to reduce motion, on every platform | `MediaQuery.disableAnimationsOf(context)` or `AccessibilityFeatures.reduceMotion`, read again in `WidgetsBindingObserver.didChangeAccessibilityFeatures` | R2, R3, R4 |

No good example here is a custom solution. The register's rows are in
[custom-solutions.md](../custom-solutions.md#v12-detecting-accessibility-settings):
both examples read documented settings as their documentation says, and
build no control, role, state, focus, or announcement.

### Bad

| Slug | Defect | Violates |
| --- | --- | --- |
| `bad-read-once` | The same lines, read once from the platform dispatcher as the screen is first built and kept: a setting changed while it is open is not shown | R3 |
| `bad-animations-only` | "Reduce motion" from `disableAnimations` alone: on iOS Reduce Motion never sets it ([FL-502](../flutter-limitations.md#fl-502)), so the line stays off | R4 |

What each shows, by platform (section 7 has the measurements):

| Example | Android | iOS | Web |
| --- | --- | --- | --- |
| `bad-read-once` | Dark mode and a font scale of 1.5 turned on while it is open: its lines stay as they were; TalkBack, on as it opened, is read "Accessible navigation: off" (FL-503) | VoiceOver and Increase Contrast turned on while it is open: its lines stay as they were | Dark mode, reduced motion, forced colours, and a larger root font size while it is open: its lines stay as they were |
| `bad-animations-only` | none: Remove animations sets `disableAnimations`, which it reads | Reduce Motion on: the line stays off | none: `prefers-reduced-motion` sets both flags |

`bad-animations-only` on Android and the web is not called a defect there:
its one defect is iOS's, as S16's `bad-region-tag` is the web's.

### Decisions

The principal's, on 2026-11-28, on the engineer's questions; the owner
may overrule:

1. The web is `PlatformStatus.limitation`, citing FL-500 and FL-501: a
   contrast preference other than forced colours is not detected, and
   `accessibleNavigation` does not mean a screen reader is running.
   Android and iOS apply. On Android a change of Bold text or of the
   contrast level starts the app again (FL-504); on iOS Reduce Motion
   needs the second flag, `AccessibilityFeatures.reduceMotion` (FL-502).
2. The iOS VoiceOver walk judges the 65-character description line by its
   first 64 characters, the most the service returns; every other
   expectation of 64 characters or more is refused.
3. `good-motion` is not a custom solution.
4. The `onOffSwitchLabels` line says "Switch labels": a "/" would be read
   as the TalkBack row form's separator. No V12 stop holds " / ", so the
   web VoiceOver rows need no escaping for it.

### Not built

- **An example that adapts** (a theme for high contrast, an animation that
  stops): each is the technique for that setting (V02, V04, V05, V09).
- **A line for each of the iOS reference's other settings** (Reduce
  Transparency, Button Shapes, Differentiate Without Color, Grayscale, Dim
  Flashing Lights, Speak Screen, Closed Captions, Guided Access, Assistive
  Touch, Prefer Cross-Fade Transitions, the large content viewer): Flutter
  reports none of them ([FL-025](../flutter-limitations.md#fl-025),
  extended).
- **The four flags only `AccessibilityFeatures` has, other than
  `reduceMotion`** (`autoPlayAnimatedImages`, `autoPlayVideos`,
  `deterministicCursor`): measured in the probe (section 7), not shown in
  an example: each is the setting of a technique not built yet (C29 video,
  F-series text fields).

## 6. Assertions by layer

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Good, in light and dark, with every flag off: the four guidelines. Every example: at 200% text on a 320 by 640 screen, no layout overflow, no text that hits its line limit, none taller than its box, none past the screen's edge, and the settings lists' scale line's text drawn at 200%. Each list's lines after the "Example" heading, in traversal order, each one node with its identifier and its text, every one off and 100%. Opened with each flag on in turn, and dark at 150%, both lists say so (the positive control for `bad-read-once`: it does read the settings, once). A setting changed while the example is open is a test value set on the test's platform dispatcher, whose setter calls the change callback, as the engine does: for `good-media-query`, each flag on its own turned on and off again, only its own line follows; dark and 150% follow; for `bad-read-once`, each flag on and the lines unchanged, with the witness that the framework has the change (the screen's `MediaQuery` has it), and dark and 150% unchanged, with the witnesses that the theme went dark and the line's own text is drawn at 150%. Motion: `reduceMotion` alone, `disableAnimations` alone, and both, on and off again: `good-motion` says on for each; `bad-animations-only` says off for `reduceMotion` alone (its defect, as on iOS) and on for the other two (its positive control). Which system setting sets which flag is not seen here: the engine is not run |
| L3 web | Each list one element per line, eight, in order: `good-media-query` with accessible navigation on and no screen reader (FL-500), `bad-read-once` off, read in the app's first frame, with the witness that it is on by then (`good-media-query` opened by address in the same page says on); each motion example one element, "off". Opened with dark mode, reduced motion, and forced colours: both lists say so. While open, each change made once and each reading waited for in a bounded loop: `prefers-color-scheme: dark`, `prefers-reduced-motion: reduce`, `forced-colors: active`, each on and off again, `good-media-query`'s own line follows and no other changes; a 32-pixel root font size gives "Text scale: 200%" and back; `prefers-contrast: more` leaves "High contrast: off", with the witness that the page's own media query matches it and the control, forced colours in the same page, that does set it (FL-501, written to fail when the engine reads it). `bad-read-once`: dark mode on and its lines unchanged, the witness the screen's mean luminance falling below 0.2 (MaterialApp's dark theme drawn); reduced motion and forced colours on and unchanged, with `good-media-query` in the same page then following the same change; a 32-pixel root font and its scale line still 100%, the witness its element 1.6 times as wide. Both motion examples follow `prefers-reduced-motion` on and off (the web sets both flags). Each screen shows the title and lines the VoiceOver judge expects; the judge's regression cases (below) |
| L3 Android | Each list after opening, with no accessibility service on but the test's own UiAutomation: `good-media-query` accessible navigation on (FL-503), `bad-read-once` off, every other line off and 100%; each motion example "off". While open, each through the device's own settings from the test's shell, each read first and put back after, whatever the test found, and each reading waited for: dark mode (`cmd uimode night yes`), Remove animations (the three animation scales 0), colour inversion, each followed by `good-media-query`'s line and back; a font scale of 1.5 grows the scale line by at least 30% (the platform's curve gave 157% in the probe; one number is not asserted, since the curve may differ by Android version) and back to 100%; "High contrast text" leaves "High contrast: off" for four seconds, with the font scale, changed on the same screen after it, as the control that the line is read (FL-504). `bad-read-once`: dark mode on, the witness the screen's mean luminance below 0.2, and its lines unchanged; a font scale of 1.5, the witness its scale line's node 1.3 times as wide, and still "Text scale: 100%". Both motion examples follow Remove animations. Bold text and the contrast level are not changed: each starts the app again (FL-504). Run once at CI's 320 by 640 at 160 dpi as well |
| L3 iOS | Each list's eight lines, every one off and 100%, and each motion example "off", with VoiceOver off. VoiceOver turned on and off with `XCUIVoiceOverService` while `good-media-query` is open: its line follows, on then off. `bad-read-once`, opened with VoiceOver off, then VoiceOver on: its line still says off for four seconds and every line is unchanged; the witness, `good-media-query` opened by its address in the same running app, says on. Increase Contrast, turned on in the simulator's Settings app and off again: `good-media-query`'s line follows and no other changes; `bad-read-once` stays off, with `good-media-query` opened in the same running app as the witness. Reduce Motion turned on in Settings: `bad-animations-only` stays off for four seconds (its defect, FL-502), and `good-motion`, opened in the same running app, says on, then off again once Reduce Motion is off. Every switch turned on is turned off again, checked, whatever the test found. Each reading after a change is waited for in a bounded loop |
| L4 TalkBack | TalkBack on before each example opens; focus moved to each line in turn; every row a whole-utterance form (`== A`, `tool/talkback.py`): `good-media-query`'s eight lines with accessible navigation on, `bad-read-once`'s with it off (its first frame, before TalkBack had read a node, FL-503), each motion line "off". Mutation tests in `tool/test_talkback.py`: a line said twice, an added role, the other value, a wrong number, every sibling line in its place. Each walk is judged whole (`walk_strictly`) |
| L4 VoiceOver iOS | Each example opened with VoiceOver off, then VoiceOver on and a walk from the top of the screen to its end (V12Walk, S16's walk copied): the screen's own stops (the title as a heading, the description, a bad example's defect, the "Example" heading), then exactly the example's lines: `good-media-query` with accessible navigation on, which VoiceOver itself turned on; `bad-read-once` with it off, read before VoiceOver was on. A stop read twice mid-walk fails; the end only with its witness; made-up walks test a duplicate title, a duplicate stop, stale speech at the end, a wrong witness, a walk out of moves, and the judge's refusal of another screen, a missing or empty title, a wrong value, a missing or swapped line, an extra stop, the description whole or cut shorter; every expected utterance is under 64 characters, and the judge refuses one that is not, but the screen's description line, which the app writes from the technique's title and which is 65 characters on a good example's screen ("Good example for Detecting accessibility settings. Widgets layer."): `XCUIVoiceOverService` returns the first 64 characters, so it is judged as exactly those |
| L4 VoiceOver web | S16's walk and judge, copied whole (`web_tests/vo/v12_vo_walks.js`), and S16's VoiceOver spec with V12's screens. The expected stops were predictions from the web tree spec: `good-media-query` with accessible navigation on, `bad-read-once` off, everything else off and 100%; the recording (recorded 2026-11-28) read every one as predicted. The browsers' media features are Playwright's defaults, not the Mac's (section 7). The judge's regression cases are S16's, on `good-media-query`'s screen with a made-up content of four stops, one a button (V12's own lines are plain text, and the help-message rule needs a role to tie to); the committed transcript (recorded 2026-11-28) is judged again from its rows by a test that is never skipped |

What the tests skip or cannot see, and what each gives up:

- No layer reads a setting's effect on the app beyond the lines and, as a
  witness, the theme or a line's size: what an app should do with a
  setting is the adapting technique's.
- The Android tree test changes no setting that restarts the app (bold
  text, the contrast level): those are measured in the probe only.
- On iOS, Bold Text, On/Off Labels, Auto-Play Video Previews, Prefer
  Non-Blinking Cursor and the appearance are not changed by the tests:
  on this simulator the first four reach no running app, Flutter or
  native, so a test of a change while the example is open could not show
  anything; the appearance could not be changed at all (section 7).
- The iOS layers reach the Settings app through XCUITest; a tap on a
  switch did not always take in the probe, so each switch is tapped until
  it reads as wanted, at most four times, and checked.
- On the web the browser's own text size setting is not changed: no
  Playwright call sets it, and the page's root font size stands in for it.
  `inverted-colors` cannot be emulated, so `invertColors` on the web rests
  on the engine's source.
- The iOS VoiceOver walk judges a good example's description line by its
  first 64 characters, the most the service returns: its last character,
  a full stop, is not judged. Every other stop is judged whole.
- The TalkBack walk and both VoiceOver walks change no setting while they
  run: the screen reader itself, on as the walk reads, is the setting
  shown.

## 7. What the build found (Flutter 3.47.5)

The probe that came first is in
[evidence/probes/v12](../evidence/probes/v12/README.md): the probe app
shows and logs every value of section 4, and each setting was turned on
through the platform's own means and off again while it ran, under the
device lock, on the Android 17 emulator (adb `settings` and `cmd uimode`),
the iOS 27.0 simulator (XCUIVoiceOverService, `XCUIDevice.appearance`,
`xcrun simctl ui`, and the simulator's own Settings app driven by
XCUITest), and in Playwright's Chromium and WebKit (`emulateMedia`, the
page's root font size, a text spacing style sheet). Every setting changed
was put back, and the device state read afterwards matched the state read
before (section 7, "Device state").

### Which setting sets which flag

| Flag | Android | iOS | Web |
| --- | --- | --- | --- |
| `accessibleNavigation` | TalkBack, while running; any service that reads the app's nodes (a UI Automator dump: on, then off 150 ms later; the tree test's own connection: on); off in the first frame with TalkBack already on, on about 0.4 s after it (FL-503) | VoiceOver, while running (and `autoPlayVideos` went false with it) | whether semantics are on: true with no screen reader once the app has called `ensureSemantics`, false before (FL-500) |
| `boldText` | Bold text (`font_weight_adjustment` 300); the app started again, its first frame told (FL-504) | Bold Text, only at a new start: changed in Settings while the app ran, it was not told, and a native UIKit app was not either (its `UIAccessibility` value, its trait collection, and its notifications: (`docs/evidence/probes/v12/ios-round3.txt`, the native app's readings)) | never (FL-501) |
| `highContrast` | the contrast level (1.0), the app started again (FL-504); "High contrast text": nothing | Increase Contrast, while running | `forced-colors: active`, while running; `prefers-contrast: more`: nothing (FL-501) |
| `invertColors` | Colour inversion, while running | Smart Invert, while running | never (FL-501) |
| `disableAnimations` | the transition animation scale 0 (and "Remove animations", all three 0), while running; the animator duration scale alone: nothing | never (FL-502) | `prefers-reduced-motion: reduce`, while running |
| `reduceMotion` | never | Reduce Motion, while running | with `disableAnimations` |
| `onOffSwitchLabels` | never | On/Off Labels, only at a new start, as the native app (`docs/evidence/probes/v12/ios-round3.txt`, the native app's readings) | never |
| `platformBrightness` | Dark theme, while running | not measured: `XCUIDevice.appearance` and `xcrun simctl ui appearance` set to dark changed nothing, in the probe app or in a native UIKit app (its trait collection stayed light), live or after a new start; a test-tool problem, not Flutter's | `prefers-color-scheme`, while running |
| `textScaler` | Font size, while running: at 1.5, `scale(14)` 22 and `scale(100)` 100; at 2.0, `scale(14)` 26 | Larger Text (`xcrun simctl ui content_size`), while running: the largest accessibility size gave `scale(100)` 311.8, and back; a native app's content size category followed the same steps | the root font size: 32 px gave 200% |
| `supportsAnnounce` | false throughout | true | true |
| `autoPlayAnimatedImages` | true throughout | Auto-Play Animated Images, while running | true throughout |
| `autoPlayVideos` | true throughout | Auto-Play Video Previews, only at a new start, as the native app (`docs/evidence/probes/v12/ios-round3.txt`, the native app's readings); also false while VoiceOver ran (native not measured) | true throughout |
| `deterministicCursor` | false throughout | Prefer Non-Blinking Cursor, only at a new start, as the native app (`docs/evidence/probes/v12/ios-round3.txt`, the native app's readings) | false throughout |
| text spacing overrides | null | null | a user style sheet's line height, letter and word spacing, and paragraph margin, while running |
| `semanticsEnabled` | on with TalkBack or a UI Automator connection, off when it closes | on throughout the XCUITest runs | on after `ensureSemantics` |

`MaterialApp` drew its `darkTheme` and `highContrastTheme` wherever their
flags changed: both on Android and the web, `highContrastTheme` on iOS. `alwaysUse24HourFormat`
did not follow Android's 24-hour setting while the app ran, and is false
on the web, as its documentation says; it is not an accessibility setting
and is not used here. `MediaQueryData.invertColors`' documentation says the
flag "is currently only updated on iOS devices"; on Android it followed
colour inversion.

### What the examples showed

- **`good-media-query` follows every change that reaches the app while it
  runs**, on every layer that changed one: dark mode, Remove animations,
  colour inversion and the font scale on Android (tree test); VoiceOver
  and Increase Contrast on iOS (tree test); dark mode, reduced motion,
  forced colours and the root font size on the web (tree test).
- **`bad-read-once` keeps what it read**: on the same changes, with a
  witness on the screen (the dark theme drawn; the line's text laid out
  larger) or the good example in the same running app following the same
  change. It also shows FL-500 and FL-503 at work: the first frame of an
  app opened at the example is told accessible navigation is off, on the
  web (before the first semantics update, which is when the web engine
  turns it on: source read) and on Android (before TalkBack or the test
  tool has read a node: the probe's timestamps); so TalkBack read
  "Accessible navigation: off" for it while TalkBack was running
  (`docs/evidence/V12/talkback-android.md`), VoiceOver on iOS, turned on
  after it opened, read it the same way (`docs/evidence/V12/voiceover-ios.md`),
  and so did VoiceOver in both browsers (`docs/evidence/V12/voiceover-web.md`).
- **`bad-animations-only`**: on iOS, Reduce Motion on, the line stayed off,
  and `good-motion`, opened in the same running app, said on (tree test).
  On Android and the web both followed (tree tests).

### iOS: what reached a running app, Flutter's and a native one

The iOS probe ran in three rounds (`docs/evidence/probes/v12/ios-round1.txt`
to `ios-round3.txt`). Round 1 changed each switch in the simulator's
Settings app while the probe app was in the background, then brought the
app back and read it. Rounds 2 and 3 also started the app afresh after each
change, and compared a native UIKit app, NativeSettings
(`NativeSettings.swift.txt`, built with `swiftc` and installed beside the
Runner, never part of it), which reads `UIAccessibility`'s value for each
setting, its trait collection, and counts every notification the Flutter
engine listens for; it reads again whenever it becomes active. Its first
build was stopped at launch by iOS 27 for not adopting the scene life
cycle, so round 2 has no native readings; round 3 has them.

| Setting (how) | The Flutter app, running | The Flutter app, started again | The native app, running | The native app, started again |
| --- | --- | --- | --- | --- |
| VoiceOver (`XCUIVoiceOverService`) | `accessibleNavigation` on, off | | not measured | |
| Increase Contrast (Settings) | `highContrast`, the high contrast theme | `highContrast` | `isDarkerSystemColorsEnabled`, its notification | the same |
| Increase Contrast (`simctl ui`) | `highContrast` | | `isDarkerSystemColorsEnabled`, its notification | |
| Larger Text (`simctl ui content_size`) | the text scale, 312% at the largest | | the content size category, its notification | |
| Smart Invert (Settings, round 1) | `invertColors` | | not measured | |
| Reduce Motion (Settings, round 1) | `reduceMotion` only | | not measured | |
| Auto-Play Animated Images off (Settings, round 1) | `autoPlayAnimatedImages` false | | not measured | |
| Bold Text (Settings) | nothing | `boldText` | nothing: `isBoldTextEnabled` false, `legibilityWeight` regular, no notification | `isBoldTextEnabled` true, `legibilityWeight` bold |
| On/Off Labels (Settings) | nothing | `onOffSwitchLabels` | nothing | `isOnOffSwitchLabelsEnabled` true |
| Auto-Play Video Previews off (Settings) | nothing | `autoPlayVideos` false | nothing | `isVideoAutoplayEnabled` false |
| Prefer Non-Blinking Cursor (Settings) | nothing | `deterministicCursor` | nothing | `prefersNonBlinkingTextInsertionIndicator` true |
| Reduce Transparency, Differentiate Without Color (Settings, round 1) | nothing (no flag, FL-025) | | | |
| Dark appearance (`XCUIDevice.appearance`, `simctl ui appearance`) | nothing | nothing | nothing: its style stayed light | nothing |

Turned back off, each setting gave the same pattern in reverse. So Bold
Text, On/Off Labels, Auto-Play Video Previews, and Prefer Non-Blinking
Cursor, changed while an app runs on this simulator, reach no running app,
native or Flutter; they are read when the app starts, by both. That is
not recorded as a Flutter limitation: the native app was told no more.
Whether a real device behaves otherwise was not measured. The appearance
could not be changed by either tool on this simulator: that is a test-tool
problem, and dark mode on iOS is not measured.

### Platform statuses

Following the owner's rule of 2026-11-23 (where Flutter is measured not
to meet a requirement on a platform and no documented parameter fixes it,
the platform is a limitation and has no good example for it), the
engineer proposed, and the principal decided (section 5, "Decisions"):

1. **Web: limitation**, citing FL-500 (R1) and FL-501 (R2 in part).
2. **Android: applies.** R1 is met for TalkBack, Switch Access, and Voice
   Access, the services the engine's own comment names; that a test tool
   such as UI Automator turns it on as well is FL-503, and so is the first
   frame, which `good-media-query` hears the change from. A change of Bold
   text or of the contrast level starts the app again (FL-504): the app's
   `main` runs again and its new first frame is told the new value; what
   an app loses by it was not measured (the probe has one screen).
3. **iOS: applies.** Reduce Motion needs the second flag (FL-502); dark
   mode was not measured.

### Device state

Every probe step and every test that changed a setting read it first and
put it back. Android: every setting read back equal at the end ("same as
before: True", night mode "no"). The iOS simulator: on the first probe run
a tap meant to turn Smart Invert and Prefer Non-Blinking Cursor off did not
take, and both stayed on from about 00:40 to 01:33 on 2026-11-28, during
other techniques' evidence runs (S08 to S11), which the principal was told
at the time. A restore test then turned both off, and every switch the
probe touches read off (the auto-play ones on); the accessibility defaults
matched the ones read before the probe apart from keys written at their
default values when the Settings pages were opened
(`ios-a11y-defaults-*.txt`). Since then each switch is tapped until it
reads as wanted, at most four times, and checked.

### The evidence runs

The evidence runs (2026-11-28, `python3 tool/evidence.py V12 --only
android,talkback,ios,voiceover-ios,web`): the Android tree tests passed on
their first run, and so did the TalkBack walk, on its first walk; its
transcript is that run's. TalkBack read every line as predicted, and read
`bad-read-once`'s first line "Accessible navigation: off" while TalkBack
was running. The iOS VoiceOver walk passed on its first run, every example
read as predicted after its "Example" heading. The first iOS tree run
failed on the judge's own made-up walks and on the check of utterance
lengths only: the good examples' description line is 65 characters, over
what the service returns. The tests now judge that line by its first 64
characters (section 6), and the second run passed whole; the VoiceOver
walk had already run with that change, since its tool builds the tests
anew. Every test that changed a setting through the device (Increase
Contrast and Reduce Motion in the Settings app, VoiceOver) passed on its
first run, each switch taking on its first tap. The web tree spec passed
but for the test that judges the web VoiceOver recording again, which
failed then because there was no recording; it passes on the recording
below. The Android tree tests passed at CI's
320 by 640 at 160 dpi as well, on their first run there (10 tests, the
TalkBack walk skipped; `docs/evidence/probes/v12/android_320x640.txt`), and
the size and density were reset afterwards. On review each Android setting
change was made to check that it took (`settings get`, `cmd uimode night`)
before the example is read; the Android tree tests passed again with it
(`python3 tool/evidence.py V12 --only android`).

**The web VoiceOver recording** (recorded 2026-11-28 by the principal,
`docs/evidence/V12/voiceover-web.md`, 141 s) passed on its first run: 8
walks of 8, each complete on its first walk, in Playwright's Chromium and
WebKit builds. Every walk read its screen's title, description, a bad
example's defect, and the "Example" heading, then every line as
predicted: `good-media-query` "Accessible navigation: on",
`bad-read-once` "off", every other line off and 100%, each motion example
"Reduce motion: off". Every walk's start row read an empty phrase on Back,
every unresolved-reads row is "none", and every end was witnessed (a move
back to the stop before the last at another position, a move forward to
the last again); no help message was read. The web tree spec judges the
transcript again from its rows, and it passes. The Mac's appearance was
Dark during the recording (`defaults read -g AppleInterfaceStyle`: Dark,
read afterwards), and both browsers' walks read "Dark mode: off": the
browsers' colour scheme is Playwright's documented default, light, which
the VoiceOver config (`web_tests/vo/playwright.config.js`, with
Guidepup's `screenReaderConfig`, neither of which sets `colorScheme`) does
not change; likewise reduced motion, forced colours, and contrast keep
Playwright's defaults. That the browsers ignored the Mac's appearance is
shown by the one line; that Playwright's default is what set it rests on
its documentation (the pinned 1.65.0's `colorScheme`: "Defaults to
'light'").

**Not done yet.** Dark mode on
iOS: neither `XCUIDevice.appearance` nor `simctl ui appearance` changed
the appearance of any app on this simulator. A real iPhone, where Bold
Text and the three other settings that reached no running app here may
behave otherwise. Switch Control, Voice Access, and Switch Access, which
the engines' source says also set `accessibleNavigation` (not installed
or not measured). The browser's own text size setting (the page's root
font size stood in for it). Whether `fontWeightAdjustment` in the
Android manifest's `configChanges` would keep the app running and what
`boldText` would then say (the manifest is shared; source read only).
