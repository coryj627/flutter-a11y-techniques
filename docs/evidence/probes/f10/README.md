# F10 probe: sliders

Run on 2026-11-17, Flutter 3.47.5, before the F10 examples were written.
Two fixtures, each a second entry point and not part of the app:
`probe.dart.txt` (fixtures `p01` to `p14`) and `probe2.dart.txt`
(fixtures `q01` to `q09`, run after the first to try ways round what it
found). Every fixture's text starts with its id. The Material sliders have
ten divisions and start at 40%.

How each was looked at, and the raw output:

- Web: Chromium on macOS, the DOM under `flt-semantics-host`, Chromium's
  accessibility tree over the DevTools protocol, hit tests, mouse clicks,
  and keys, with a throwaway Playwright spec (`probe_web.spec.js.txt`,
  `probe2_web.spec.js.txt`). Output: `web.txt`, `web2.txt`.
- Android: Pixel 10a emulator, Android 17, a throwaway instrumented test
  that dumps every node with its class, description, range, and actions,
  and sends the increase action (`ProbeF10Test.kt.txt`). Output:
  `android.txt`. First probe only.
- iOS: iPhone 17 simulator, iOS 27.0, a throwaway XCUITest that dumps the
  tree, taps each slider's track at 85%, and walks VoiceOver
  (`ProbeF10UITests.swift.txt`). Output: `ios.txt`. First probe only; the
  taps ran before the walk, so the walk hears the changed values. The
  first run of it stopped at `p07` (two elements matched the identifier
  query: XCUITest matches a label as well), and a swipe did not move any
  slider.
- Screen readers on the web and TalkBack were not part of the probe; what
  they say was recorded with the examples.
- `voiceover-web-notes.txt` is not from the probe: it is the notes that
  `web_tests/vo/f10_slider_vo.spec.js` wrote during one run of
  `python3 tool/voiceover_web.py F10`. One line per walk: the pointer and
  mouse events the page received during it, every change of the slider's
  input's `disabled` property in order, and whether it was disabled
  straight after the walk (FL-127).

## First probe

| # | Fixture | Web | Android | iOS |
| --- | --- | --- | --- | --- |
| 01 | `Slider` and its text in `MergeSemantics` | `aria-label` on the wrapper, an `<input type="range" role="slider">` with no name inside it; `aria-valuetext="40%"`, `aria-valuenow="1"` between 0 and 2 | `SeekBar` "40%, p01 Volume", no `RangeInfo` | Other, label "p01 Volume", value "40%" |
| 02 | `Semantics(label:)` around a `Slider` | as 01 | as 01 | as 01 |
| 03 | a `Slider` with its text beside it, not joined | no label anywhere | "40%" | label "" |
| 04 | `Slider(label: '4')` merged with its text | wrapper `aria-label="p04 Volume\n4"` | "40%, p04 Volume\n4" | label "p04 Volume\n4" |
| 04b | `Slider(label: '4')` alone | `aria-label="4"` | "40%, 4" | label "4" |
| 05 | `semanticFormatterCallback`, merged | `aria-valuetext="4 of 10"` | "4 of 10, p05 Volume" | value "4 of 10" |
| 06 | `CupertinoSlider`, merged | as 01; Tab never reaches it | as 01 | as 01; a tap on the track does nothing |
| 07 | `Semantics(slider: true, label:, value:, increasedValue:, decreasedValue:, onIncrease:, onDecrease:)` on a drawn bar | as 01, no name on the input; Tab never reaches it | `SeekBar`, with a click action | as 01 |
| 08 | the same without `slider: true` | as 07 | `SeekBar` with no click action | as 01 |
| 09 | a disabled `Slider` (`onChanged: null`), merged | plain text "p09 Volume 40%", focusable; no slider | `android.view.View`, not enabled, "40%, p09 Volume" | not enabled; VoiceOver "p09 Volume 40% dimmed", no "adjustable" |
| 10 | `RangeSlider`, merged | one slider, "20%" | one `SeekBar`, "20%, p10 Price" | one element, value "20%" |
| 11 | `Slider(max: 10)` at 4, no formatter | "40%" | "40%, p11 Rating" | "40%" |
| 12 | `showValueIndicator: never` | as 01, and still adds the empty element | as 01 | as 01 |
| 13 | `Slider.adaptive` | a `CupertinoSlider` in a browser on a Mac: Tab never reaches it | as 01 | as 01 |
| 14 | a `FilledButton` with a count | see below | clicks and taps work | taps work |

Also seen on the web in the first probe:

- Ten empty `flt-semantics` elements the size of the view, with
  `pointer-events: auto`, one for each `Slider` widget: 01 to 05 with
  04b, 09, 11, 12, and 13 (the adaptive one, drawn as a `CupertinoSlider`
  in a browser on a Mac, still adds it). The `CupertinoSlider` of 06, the
  custom sliders, and the `RangeSlider` add none; the second probe, with
  four `Slider`s and a `RangeSlider`, has four. `document.elementFromPoint` at the button and
  at the first slider found the topmost of them. Playwright's own click on
  the button timed out; a mouse click at its position, and a `click`
  event sent to the button element, both pressed it.
- With focus on fixture 01, the arrow keys moved it one step; Home moved
  it one step down and End one step up; Page Up and Page Down did nothing.
- Chromium's accessibility tree gives every slider an empty name, and the
  value text "1".
- A mouse click on the track left the input enabled when read 0.6 and 1.4
  seconds later.

## Second probe

| # | Fixture | Web |
| --- | --- | --- |
| q01 | one `Slider`, merged | one empty full-screen element (four in all on the screen: q01, q03, q05, q07) |
| q02 | `RangeSlider`, not merged | two inputs, one per thumb, neither named, inside elements with no label |
| q03 | a `Slider` inside `Overlay.wrap(alwaysSizeToContent: true)` | the empty element is still the size of the view |
| q04 | `CupertinoSlider` inside `FocusableActionDetector` with the arrow keys, Home, and End | Tab reaches it; the arrows move a step; Home 0%, End 100% |
| q05 | `Slider` inside `CallbackShortcuts` for Home and End | Home 0%, End 100%; the arrows as before |
| q06 | custom `Semantics(slider: true)` inside `FocusableActionDetector` with the same keys | as q04 |
| q07 | a disabled `Slider`, not merged | text "40%", focusable |
| q08 | a disabled `CupertinoSlider`, merged | text "q08 Volume": no value at all |
| q09 | a button | as 14 |

## What it shows

- **Every slider is unnamed on the web** (FL-028), however the name is
  given, and Android and iOS are right.
- **A Material `Slider` adds one empty element over the whole page** on
  the web (FL-029), which hit tests find before anything else. Neither
  `showValueIndicator: never` nor `Overlay.wrap` removes it.
- **A `CupertinoSlider` has no keyboard and moves only by a drag of its
  thumb** (FL-120, FL-121). `FocusableActionDetector` gives it the keys.
- **A `Slider` has no Home or End**, and on the web those keys move it one
  step (FL-122). `CallbackShortcuts` around it adds them.
- **`Slider.label` is added to the name** (FL-123).
- **A disabled slider is not a slider** on any platform (FL-124).
- **The web's value range is a stand-in** of 0 to 2 (FL-125).
- **A merged `RangeSlider` reports one value** (FL-126).
- **A slider with no formatter reads a percentage** whatever its range.
