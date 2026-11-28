# V12 probe: what the framework tells an app about the user's settings

Flutter 3.47.5. Run 2026-11-28 under the device lock: Android 17 (API 37)
emulator, iOS 27.0 simulator (iPhone 17), and Playwright's Chromium and
WebKit builds. Each setting was turned on through the platform's own means
and off again while the probe app ran.

## The probe app

`probe.dart.txt` (built as `lib/probe.dart`, never committed): one screen
that shows, as one text per value with an identifier `v12-<name>`, and logs
as `V12PROBE` lines whenever anything changes:

- every accessibility field of `MediaQueryData`, read through its own
  `...Of` method (`mq.*`), the text scale as `scale(100)` and `scale(14)`;
- every flag of `PlatformDispatcher.accessibilityFeatures` (`f.*`), read
  again when `WidgetsBindingObserver.didChangeAccessibilityFeatures` is
  called, which `featureChanges` counts;
- `SemanticsBinding.semanticsEnabled`, from its listener
  (`semanticsChanges`);
- which of four `MaterialApp` themes was drawn (`theme`: `light`, `dark`,
  `hc-light`, `hc-dark`; `unknown` while a theme animates from one to the
  other);
- `once`, the features read once in `initState`; and `started`, when
  `main` ran: a new value means the app was started again.

The first web runs used the probe's first version, which logged each
reading as one line; Android's log cut that line at about 1,000
characters (`android-round1-logcat.txt`), so the probe logs in parts of
eight since (`summarise.py.txt` joins them). What the screen shows is the
same in both.

## Web (`web.txt`, `web_noensure.txt`)

`probe_v12.spec.js.txt` with `probe_v12.config.js.txt`, in Chromium and
WebKit, each setting on and then off with Playwright's `emulateMedia`;
the root font size and a text spacing style sheet set by the page, as a
user's browser setting or style sheet would; values read from the
semantics elements. Both browsers gave the same in every step:

| Step | What changed |
| --- | --- |
| Start, no screen reader | `accessibleNavigation` true, `semanticsEnabled` true, `supportsAnnounce` true, every other flag false, 100% |
| `prefers-color-scheme: dark` | `platformBrightness` dark, the dark theme; back on light |
| `prefers-reduced-motion: reduce` | `disableAnimations` and `reduceMotion` true; back on no-preference |
| `forced-colors: active` | `highContrast` true, the high contrast theme; back on none |
| `prefers-contrast: more` | nothing (FL-501) |
| root font size 32 px | text scale 200% (both sizes); back |
| text spacing style sheet | the four spacing overrides 1.5, 1.92, 2.56, 32; back to null |

`boldText`, `invertColors`, `onOffSwitchLabels`, `alwaysUse24HourFormat`
and `supportsShowingSystemContextMenu` were false throughout, and
`autoPlayAnimatedImages` and `autoPlayVideos` true.

Without `ensureSemantics` at start (the second build, `--dart-define=
V12_ENSURE=false`), there were no semantics elements and the log said
`accessibleNavigation` false; a click on Flutter's "Enable accessibility"
placeholder turned semantics on and `accessibleNavigation` true, in both
browsers (`web_noensure.txt`; the settings test fails in that build, since
it waits for elements that are not there). So on the web
`accessibleNavigation` is whether semantics are on (FL-500).

## Android (`android-summary.txt`, `android-logcat.txt`, `android-run.txt`)

`probe_android.py.txt`, under the lock: the probe installed and started,
then each setting put on with `adb shell settings put` or `cmd uimode` and
off again four seconds later, a `V12STEP` marker logged before each. Every
setting was read before the run and put back after it; the run printed
"same as before: True", and night mode "no". The second run is the one
summarised; the first (`android-round1-*`) gave the same where its cut
lines show it. The markers of the two contrast steps were not logged (their
names had parentheses, which the device shell refused); they ran four
seconds apart after "high contrast text off", as `android-run.txt` lists,
at 01:36:06 and 01:36:10, where the summary shows the change.

| Setting (how) | What the app was told | When |
| --- | --- | --- |
| Dark theme (`cmd uimode night yes`) | `platformBrightness` dark, the dark theme | while running; back |
| Font size 1.5 and 2.0 (`system font_scale`) | `scale(14)` 22 and 26, `scale(100)` 100 | while running; back |
| `animator_duration_scale` 0 alone | nothing | |
| `transition_animation_scale` 0, and all three scales 0 ("Remove animations") | `disableAnimations` | while running; back |
| Colour inversion (`accessibility_display_inversion_enabled`) | `invertColors` | while running; back |
| High contrast text (`high_text_contrast_enabled`) | nothing (FL-504) | |
| Contrast level 1.0 (`secure contrast_level`) | `highContrast`, the high contrast theme | then the app was started again (`main` ran again, after the system's "Config changes" line); back to 0.0, the same (FL-504) |
| Bold text (`font_weight_adjustment` 300) | `boldText` | the app started again, its first frame told `boldText`; back, the same (FL-504) |
| 24-hour time (`system time_12_24`) | nothing while running | |
| Colour correction | nothing | |
| A UI Automator dump, no service on | `semanticsEnabled`, then `accessibleNavigation` true; both false about 150 ms later (FL-503) | |
| TalkBack on, then off | `semanticsEnabled` and `accessibleNavigation` true within 0.4 s; false | while running |
| App started with TalkBack already on | first frame `accessibleNavigation` false; true 650 ms later (FL-503) | |

`reduceMotion` and `onOffSwitchLabels` were never set, `supportsAnnounce`
was false throughout (FL-018), `autoPlayAnimatedImages` and
`autoPlayVideos` true, `deterministicCursor` false.
`cmd uimode contrast` is not a command on this Android
(`android-run.txt`). `MediaQueryData.invertColors`' documentation says "This
flag is currently only updated on iOS devices"; on Android it followed
colour inversion.

## iOS (`ios-round1.txt`, `ios-round2.txt`, `ios-round3.txt`)

Three rounds, each a script under the lock (`ios_probe-round1.sh.txt`,
`ios_round2.sh.txt`, `ios_round3.sh.txt`) running tests of
`ProbeV12UITests.swift.txt` (round 1's own version:
`ProbeV12UITests-round1.swift.txt`) against the probe app, on the iPhone 17
simulator, iOS 27.0.

- **Round 1.** `testAppearance` (`XCUIDevice.appearance` dark and back),
  `testVoiceOver` (`XCUIVoiceOverService` on and off), and
  `testDisplaySettings` and `testMotionSettings`, which open the
  simulator's Settings app, turn each switch on with the probe app in the
  background, bring the app back and read it, then turn the switch off and
  read again. The script's first part, `xcrun simctl ui` steps while the
  app's output was captured, captured nothing (`--console-pty` into a
  file); it is repeated in round 2. Switches not on this simulator's pages
  (Classic Invert, Button Shapes, Color Filters, Reduce White Point, Dim
  Flashing Lights, Prefer Cross-Fade Transitions) are logged with the page's
  elements.
- **Round 2.** `testRound2WatchFlutter` reads the app about once a second
  while the script runs `simctl ui` steps (`ios-round2-watch-steps.txt`);
  `testRound2Appearance`; and `testRound2Settings`, which for each switch
  reads the app before, after the change while it runs, after starting it
  afresh, and after turning the switch back. It was also to read a native
  UIKit app, `NativeSettings.swift.txt` (built by
  `build_native_ios.sh.txt`), whose first build iOS 27 stopped at launch
  for not adopting the scene life cycle (its readings are "missing"); the
  watch ended at the text size step, when the probe's lines went out of
  view (fixed in round 3: a missing line is logged, not a failure).
- **Round 3.** Round 2 again, with the native app fixed (a scene
  delegate), the native watch first.

| Setting (how) | The probe app, running | Started again | The native app, running | Started again |
| --- | --- | --- | --- | --- |
| VoiceOver on, off | `accessibleNavigation` on, off; `autoPlayVideos` false while on | | not measured | |
| Increase Contrast (Settings) | `highContrast`, the high contrast theme (rounds 1 to 3) | `highContrast` | `isDarkerSystemColorsEnabled`, one notification | the same |
| Increase Contrast (`simctl ui`) | `highContrast` (round 3) | | the same, notifications | |
| Larger Text (`simctl ui content_size`, the largest) | `scale(100)` 311.8 (round 3) | | the content size category, notifications | |
| Smart Invert (Settings) | `invertColors` | | not measured | |
| Reduce Motion (Settings) | `reduceMotion`, never `disableAnimations` | | not measured | |
| Auto-Play Animated Images off (Settings) | `autoPlayAnimatedImages` false | | not measured | |
| Bold Text (Settings) | nothing (rounds 1 to 3) | `boldText` | nothing: `isBoldTextEnabled` false, `legibilityWeight` regular, no notification | `isBoldTextEnabled` true, `legibilityWeight` bold |
| On/Off Labels (Settings) | nothing | `onOffSwitchLabels` | nothing | `isOnOffSwitchLabelsEnabled` true |
| Auto-Play Video Previews off (Settings) | nothing | `autoPlayVideos` false | nothing | `isVideoAutoplayEnabled` false |
| Prefer Non-Blinking Cursor (Settings) | nothing | `deterministicCursor` | nothing | `prefersNonBlinkingTextInsertionIndicator` true |
| Reduce Transparency, Differentiate Without Color (Settings) | nothing | | | |
| Dark (`XCUIDevice.appearance`, `simctl ui appearance`) | nothing | nothing | nothing: style light | |

Each setting turned back gave the same pattern in reverse: "nothing" while
running, and the old value until a new start. `semanticsEnabled` was true
throughout, `supportsAnnounce` true, `supportsShowingSystemContextMenu`
true.

**Device state.** In round 1 the tap meant to turn Smart Invert off, and
later Prefer Non-Blinking Cursor, did not take (`ios-round1.txt`:
"restored=1"), and both stayed on until a restore test
(`testRestore`, run on its own at 01:31 and again at the end of rounds 2
and 3) turned them off; every switch the probe touches read off after it,
the auto-play ones on. The accessibility defaults read before round 1
(`ios-a11y-defaults-before.txt`) and after each round differ only by keys
written at their default values when the Settings pages were opened
(`ios-a11y-defaults-after-round2.txt`; round 1's, before the restore,
shows the two left on). Since round 2 every switch is tapped until it
reads as wanted, at most four times.
