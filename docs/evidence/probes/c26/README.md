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
- Android: Pixel emulator, Android 17, a throwaway instrumented test
  (`ProbeC26Test.kt.txt`, run by `probe_android.py.txt` under the device
  lock): every node of each fixture with its class, description, range,
  live region, and actions; for the changing fixtures, Start pressed with
  the click action and the indicator and status every 600 ms
  (`android-tree.txt`). With TalkBack on, through `tool/talkback.py`'s own
  helper, which restores the device: TalkBack focus on each still
  indicator; for each changing fixture, focus left on the indicator, then
  on Start, while Start is pressed, nine seconds each
  (`android-talkback.md`, as parsed by `talkback.parse_speech`;
  `android-talkback-markers.txt`, the probe's own lines).
- iOS: iPhone 17 simulator, iOS 27.0, a throwaway XCUITest
  (`ProbeC26UITests.swift.txt`, run by `ios_probe.sh.txt`): each
  fixture's elements from one `snapshot()`; for the changing fixtures,
  Start tapped and a snapshot every 600 ms; a VoiceOver walk of each
  fixture; the cursor on Start, a double tap at it, and `currentSpeech()`
  for nine seconds; and the cursor left on the indicator of the fixture's
  "a" route, which starts by itself, and `currentSpeech()` until 24 s after
  the open (`ios.txt`).

## Rounds

- **Round 1** (`android-tree-round1.txt`, `android-talkback-round1.md`,
  `android-talkback-markers-round1.txt`, `ios-round1.txt`, `web-round1.txt`).
  On Android the run stopped at p04, which never opened: a debug build
  asserts against its value (FL-258). On iOS no fixture's elements were
  found: a start by URL builds the probe's `/` route first, which then
  listed every fixture, p04 among them; and each element query waited a
  minute or more while an indicator turned. Round 1 was stopped there.
- **Round 2**: `/` lists nothing; p04 is tried alone (`p04Alone`,
  `testP04`); a changing bar is at 0 before Start, where in round 1 it was
  indeterminate (no role on the web, a spinner's role elsewhere); iOS reads
  the tree from snapshots. Every other file here is round 2. The web was
  run again for round 2 (`web.txt`).

## Kept from the build, after the probe

- `android_320x640.txt`, with `android_320x640.sh.txt`: C26's Android tree
  tests at CI's emulator size, 320 by 640 at 160 dpi; passed.
- `ios-tab-round1-fail.txt`: the first iOS tree run's one failure, Tab
  and Return (the spec, section 7).
- `voiceover-ios-round1-fail.md.txt` to `voiceover-ios-round3-fail.md.txt`:
  the iOS VoiceOver transcripts that failed while the reading of a
  spinner during loading was settled (the spec, section 7).

## What was found

| # | Web (Chromium) | Android | iOS |
| --- | --- | --- | --- |
| p01 bar, named | `progressbar`, `aria-label` "p01 Upload 40", `aria-valuenow` 40, min 0, max 100 | `ProgressBar` "40, p01 Upload", float range 0 to 100, 40; TalkBack "40.0.", "40,", "p01 Upload", "Progress bar" | static text, label "p01 Upload", value "40"; VoiceOver "p01 Upload 40" |
| p02 bar, no name | `progressbar` named "40" | `ProgressBar` "40"; TalkBack "40.0.", "40", "Progress bar" | an element of type other, no label, value "40"; VoiceOver "40" |
| p03 `semanticsValue: '40%'` | `aria-valuenow` 40, `aria-valuetext` "40%", named "p03 Upload 40%" | `ProgressBar` "40%, p03 Upload", range of the indeterminate type, 0 to 0 (FL-027); TalkBack "40%,", "p03 Upload", "Progress bar" | value "40%"; VoiceOver "p03 Upload 40%" |
| p04 `semanticsValue: '2 of 5 files'` | (release) `aria-valuetext` "2 of 5 files", no `aria-valuenow` | (debug) never opened | (debug) never opened |
| p05, p08 spinner, named | no role, `aria-label`; Chromium "generic" | `View` "p05 Loading", no range; TalkBack "p05 Loading", no role word | static text "p05 Loading"; VoiceOver "p05 Loading" |
| p06 spinner, no name | an element with nothing | a `View` with nothing, not focusable; TalkBack nothing of it | type other, nothing; VoiceOver passed over |
| p07 circle, named | as p01 | as p01 | as p01 |
| p09, p10 `.adaptive` | nothing (a Mac's browser) | Material's: as p08 and p07 | nothing; VoiceOver passed over |
| p11 to p13 Cupertino | nothing | nothing | nothing; VoiceOver passed over |
| p14 `Semantics(label:)` round Cupertino's spinner | the text "p14 Loading", no role | `View` "p14 Loading" | static text "p14 Loading" |
| p15 text above, one `Semantics` | the text and the label both in the name | the same | the same |
| p17 changing bar, then text | `aria-valuenow` each step; nothing announced | range each step; TalkBack said nothing for the steps, on the bar or on Start | value each step; VoiceOver said nothing for them, on the bar or on Start |
| p18 status line, live region | each line announced | each line spoken, seconds behind | each line spoken |
| p19 `sendAnnouncement` at the end | announced | `supportsAnnounce` false; TalkBack spoke it (focus on Start) | spoken |
| p20 spinner, then text | nothing announced | nothing; with TalkBack focus on the spinner, the focus was still on that node when it held "p20 Loaded", and nothing was said | nothing |
| p21 live region round the spinner | "p21 Loading" and "p21 Loaded" announced | both spoken | both spoken |
| p22 spinner and a status line | the line announced | spoken | spoken |

Widget tests (`flutter_test.txt`): the same roles, labels, and values as
Android, iOS, and macOS; `.adaptive` with nothing as iOS and macOS. The
default `semanticsValue` is the percentage with no "%", "40".
