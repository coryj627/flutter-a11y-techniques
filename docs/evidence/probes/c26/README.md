# C26 probe: what Flutter's progress indicators expose, still and changing

Run on 2026-11-22, Flutter 3.47.5, before the C26 examples were written.
The fixture is `probe.dart.txt`, a second entry point and not part of the
app: 22 fixtures, `p01` to `p22`, one per route (`/p01` …). Each is
"Before pNN", the indicator, and "pNN end". `p17` to `p22` change: a
"pNN Start" button runs them 0, 20, 40, 60, 80, 100 one step every 1.2 s,
and then their indicator is replaced as the table says. A route with "a"
after the id (`/p17a`) starts the fixture by itself 10 s after it opens, so
that a screen reader's cursor can be left on the indicator.

| # | Fixture |
| --- | --- |
| p01 | `LinearProgressIndicator(value: 0.4, semanticsLabel:)` |
| p02 | `LinearProgressIndicator(value: 0.4)`, no label |
| p03 | p01 with `semanticsValue: '40%'` |
| p04 | p01 with `semanticsValue: '2 of 5 files'` |
| p05 | `LinearProgressIndicator(semanticsLabel:)`, indeterminate |
| p06 | `LinearProgressIndicator()`, indeterminate, no label |
| p07 | `CircularProgressIndicator(value: 0.4, semanticsLabel:)` |
| p08 | `CircularProgressIndicator(semanticsLabel:)`, indeterminate |
| p09 | `CircularProgressIndicator.adaptive(semanticsLabel:)`, indeterminate |
| p10 | `CircularProgressIndicator.adaptive(value: 0.4, semanticsLabel:)` |
| p11 | `CupertinoActivityIndicator()` |
| p12 | `CupertinoActivityIndicator.partiallyRevealed(progress: 0.4)` |
| p13 | `CupertinoLinearActivityIndicator(progress: 0.4)` |
| p14 | `Semantics(label:)` round a `CupertinoActivityIndicator` |
| p15 | a `Text` "p15 Uploading report" above p01 with the same label, inside one `Semantics(identifier:)` |
| p16 | p01 at `value: 1.0` |
| p17 | a determinate bar (indeterminate before Start), then a plain `Text` "p17 Upload complete" |
| p18 | p17 with a status line in `Semantics(liveRegion: true)`: "p18 Not started", "p18 20% uploaded" … "p18 Upload complete" |
| p19 | p17 with `SemanticsService.sendAnnouncement` of "p19 Upload complete" at the end, and no live region |
| p20 | a `CircularProgressIndicator(semanticsLabel:)` while running ("p20 Not loading" before), then "p20 Loaded" |
| p21 | p20 inside `Semantics(liveRegion: true)` |
| p22 | p20 with a status line in a live region: "p22 Idle", "p22 Loading messages", "p22 Messages loaded" |

How each platform was looked at, and the raw output:

- Widget tests: `probe_test.dart.txt` under `flutter test`, as Android,
  iOS, and macOS (`flutter_test.txt`): each fixture's semantics nodes, and
  each step of the changing ones. p04's run threw the framework's progress
  bar check in every frame (`flutter_test_p04.txt`). `contrast_test.dart.txt`
  reads the colours the indicators draw with from the app's themes and
  the SDK's defaults (`flutter_test_colours.txt`).
- Web: Chromium on macOS (`navigator.platform` "MacIntel"), the release
  build, with a throwaway Playwright spec (`probe_c26.spec.js.txt`,
  `probe_c26.config.js.txt`): the semantics elements, Chromium's
  accessibility tree over the DevTools protocol, four Tabs; for the
  changing fixtures, the elements every 600 ms and every value written to
  Flutter's announcement elements. Output: `web.txt`.
- Android: (filled in below)
- iOS: (filled in below)
