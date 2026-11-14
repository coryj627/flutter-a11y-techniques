# S01 probe: ways to name a control

Run on 2026-11-14, Flutter 3.47.5, before the S01 examples were written. The
fixture is `probe.dart.txt` (a second entry point, not part of the app). Each
control is wrapped in `TestId`, which merges its subtree into one node, so
these results say what a merged control exposes.

- Web: Chromium, DOM under `flt-semantics-host` and Playwright's ARIA
  snapshot (`web-dom.txt`).
- Android: Pixel 10a emulator, API 37, `uiautomator dump` (`android-tree.txt`).
- iOS: iPhone 17 simulator, iOS 27.0, XCUITest tree and a VoiceOver walk
  (`ios-tree-and-voiceover.txt`).

Result: every mechanism names a checkbox, switch, and radio button on all
three platforms. A slider is named on Android and iOS; on web its label is on
the wrapping `flt-semantics` element and the `input role="slider"` inside has
no name (limitation FL-028).
