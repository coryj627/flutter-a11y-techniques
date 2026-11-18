# Spec: F10 Slider

Status: Draft 1 (2026-11-17), written with the build. Fourth technique of
batch 2 ([plan](../plan.md)), built in wave 1. Flutter pin: 3.47.5.

A slider sets one value in a range. This spec covers its name, its role,
its value and how the value is worded, the keyboard, and setting it with
one pointer. A range slider (two thumbs) was probed and is not built here
([FL-126](../flutter-limitations.md#fl-126)). A progress bar is a value
that cannot be set and has its own entry; a stepper or spin button is
another way to set a number. How values in general are worded is
[S14 Values and state descriptions](S14-values-and-state-descriptions.md).

## 1. Rule

A slider's visible text is its name, and it is one control with that text.
Assistive technology is told that it is a slider, what its value is in the
words the screen uses, and that the value can be moved up and down, and
the value it reports stays right as it changes. The keyboard reaches it
and moves it with the arrow keys, Home, and End, and a single tap or click
can set it as well as a drag.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies | Applies | Limitation |

On the web the slider element has no name in Flutter 3.47.5: the label is
put on an element around the `<input type="range">` and not on it
([FL-028](../flutter-limitations.md#fl-028)). Flutter 3.50.0's source
copies the label onto the input; that version was not run. A Material
`Slider` also adds an empty element over the whole page that every hit
test finds first ([FL-029](../flutter-limitations.md#fl-029)). Neither has
a workaround in the SDK. The value, the role, and the keyboard are right.

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [4.1.2 Name, Role, Value](https://www.w3.org/TR/WCAG22/#name-role-value) | A slider is a user interface component: its name and role can be programmatically determined, its value can be set, and changes to it are available to assistive technology |
| [2.5.7 Dragging Movements](https://www.w3.org/TR/WCAG22/#dragging-movements) | A slider is operated by dragging; a single pointer must be able to set it without dragging |
| [2.1.1 Keyboard](https://www.w3.org/TR/WCAG22/#keyboard) | Everything a slider does can be done from a keyboard |
| [2.5.3 Label in Name](https://www.w3.org/TR/WCAG22/#label-in-name) | The slider's name contains its visible text, so speech input can address it by what is on the screen |

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | The slider has a visible label, and its accessible name contains the visible text | [iOS Sliders](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/Sliders.md) ("a unique and specific accessibility label" and "visible label `Text`"), [Android Compose Slider and RangeSlider Controls](https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/components/SliderAndRangeSliderControls.md) ("the `contentDescription` must contain the visible label text"), [APG Slider](https://www.w3.org/WAI/ARIA/apg/patterns/slider/) (`aria-labelledby` the visible label), [MDN: input type=range](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/input/range) (a `<label>`) |
| R2 | It has the slider role, and screen readers can adjust it | iOS Sliders (the "adjustable" trait, "adjust the value by swiping up or down"), APG Slider (role `slider`), MDN (implicit role `slider`) |
| R3 | Its value is reported, in words that fit it where a number or percentage does not | APG Slider (`aria-valuenow`, `aria-valuemin`, `aria-valuemax`, and `aria-valuetext` "if aria-valuenow isn't user-friendly"), Android Compose Slider (`stateDescription` "if the default announcement of 'xx percent' does not apply") |
| R4 | Right and Up add a step, Left and Down take one away, Home goes to the first value and End to the last | APG Slider, keyboard interaction (Page Up and Page Down are optional and not built); Android Compose Slider (`onKeyEvent` for the arrow keys) |
| R5 | A single pointer can set it without dragging | iOS Sliders ("Provide single tap alternatives to adjusting the slider with a gesture"; G216); [G216](https://www.w3.org/WAI/WCAG22/Techniques/general/G216) |

The iOS document also suggests a text field and a stepper beside a slider
for fine control. `good-cupertino` has step buttons because its slider
needs them for R5; a text field is not built.

Flutter references for the mechanisms used:

- [`Slider`](https://api.flutter.dev/flutter/material/Slider-class.html) and [`Slider.semanticFormatterCallback`](https://api.flutter.dev/flutter/material/Slider/semanticFormatterCallback.html)
- [`CupertinoSlider`](https://api.flutter.dev/flutter/cupertino/CupertinoSlider-class.html)
- [`SemanticsProperties.slider`](https://api.flutter.dev/flutter/semantics/SemanticsProperties/slider.html), [`increasedValue`](https://api.flutter.dev/flutter/semantics/SemanticsProperties/increasedValue.html), [`onIncrease`](https://api.flutter.dev/flutter/semantics/SemanticsProperties/onIncrease.html)
- [`FocusableActionDetector`](https://api.flutter.dev/flutter/widgets/FocusableActionDetector-class.html) and [`CallbackShortcuts`](https://api.flutter.dev/flutter/widgets/CallbackShortcuts-class.html)

Comparison bar: HTML `<input type="range">` with a `<label>`.

## 5. Examples

Every example ends with a count of changes. The volume sliders start at
40% and move in tenths; the rating sliders run from 0 to 10 and start at 4.

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-material` | Material | A volume slider under its text | `Slider` and a `Text` in a `Column` in `TestId` (a `MergeSemantics`), and `CallbackShortcuts` for Home and End | R1 to R5 |
| `good-cupertino` | Cupertino | The same with a Cupertino slider, and buttons a step down and up | `CupertinoSlider` and a `Text`, merged, inside `FocusableActionDetector` with the APG keys; two `CupertinoButton`s | R1 to R5 |
| `good-custom` | Widgets | A slider drawn by hand | `Semantics(slider: true, label:, value:, increasedValue:, decreasedValue:, onIncrease:, onDecrease:)` around a drawn track that answers a tap and a drag, inside `FocusableActionDetector` with the APG keys | R1 to R5 |
| `good-value-text` | Material | A rating from 0 to 10 read as "4 out of 10" | `Slider(semanticFormatterCallback:)`; the visible value in `ExcludeSemantics` | R3 |

### Bad

| Slug | Defect | Violates | Fails |
| --- | --- | --- | --- |
| `bad-unlabelled` | The text above the slider is not joined to it. The slider has no name: "40%, slider" | R1 | 4.1.2, 2.5.3 |
| `bad-indicator-label` | `Slider(label:)`, the number shown above the thumb, is added to the name ([FL-123](../flutter-limitations.md#fl-123)): "Volume 4" and "40%", and the name changes at every step | R1 | 2.5.3 |
| `bad-percent-value` | A rating from 0 to 10 with no formatter: the screen says "4 out of 10" and a screen reader "40%" | R3 | 4.1.2 |
| `bad-no-keyboard` | The custom slider with no focus or keys: Flutter's focus order goes past it, and on Android and iOS the keyboard cannot move it | R4 | 2.1.1 |
| `bad-drag-only` | The custom slider whose track does not answer a tap: only a drag moves it | R5 | 2.5.7 |

There is no example of a disabled slider: on every platform Flutter
exposes one as something that is not a slider
([FL-124](../flutter-limitations.md#fl-124)), so it could be neither a good
example nor a bad one with one defect. It is in the probe.

## 6. Assertions by layer

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Every slider: one node with the slider flag, its label, value, increased and decreased values, and the increase and decrease actions, which move it a step. Keyboard: Tab reaches it, the four arrows, Home, and End, and focus stays. Good: a tap on the track sets it (`good-cupertino`: the track does not, the buttons do), a drag moves it, guidelines in light and dark, 200% text. Bad: no label; the indicator number in the label, changing; a percentage beside "4 out of 10"; no focus and keys that do nothing; a tap that does nothing and a drag that works. The SDK's own sliders: a `CupertinoSlider` takes no focus (FL-120) and ignores a tap on its track (FL-121), a `Slider` has no Home or End (FL-122), and a disabled slider has no adjust actions (FL-124) |
| L3 web | Every slider: one `role="slider"`, the label on the element around it and none on the slider (FL-028), `aria-valuetext`, the stand-in range 0 to 2 (FL-125), and a change through the input. Keyboard: Tab, the arrows, Home, and End. Pointer: a click on the track, the step buttons. The empty element over the page on the Material screens and not the others, what a hit test finds there, and that Back still works by mouse and by a click event (FL-029). Bad: as L1, and on the web `bad-no-keyboard` is reached by the browser's own Tab order and Home and End move one step |
| L3 Android | Every slider: one `SeekBar`, its description (value, then name), no `RangeInfo`, and the scroll actions, which move it a step and show the new value at once (FL-038). Pointer: a tap on the track, the step buttons, `good-cupertino`'s track ignoring a tap, `bad-drag-only` moving only by a swipe. The keyboard is not checked here |
| L3 iOS | Every slider: type Other, label, value, enabled. Pointer: as Android. Bad: an empty label and the text as static text; the label changing with the value; a percentage |
| L4 TalkBack | Each slider on arrival, and again after an increase; the step button; the text beside `bad-unlabelled` |
| L4 VoiceOver iOS | Every utterance between the "Example" heading and the change count |
| L4 VoiceOver web | Every stop between the "Example" heading and the change count in Chromium, and in WebKit for the screens with no Material slider; in WebKit, that the cursor leaves the page on the five that have one. Pressing Back with VoiceOver on a Material slider's screen (Chromium). A control in plain HTML: Flutter's markup enabled is not "dimmed", disabled it is, and a labelled input is read with its label |

The keyboard and pointer defects (`bad-no-keyboard`, `bad-drag-only`) are
not heard: a screen reader reads and adjusts those sliders correctly. The
screen reader layers record that they sound like the good ones.

## 7. What the build found (Flutter 3.47.5)

The probes that came first are in [evidence/probes/f10](../evidence/probes/f10/).

- **On Android and iOS the SDK's sliders are right with no extra work**
  once joined to their text. Android: a `SeekBar` whose description is
  the value and the name, "40%, Volume", with no `RangeInfo`; TalkBack
  says "40%", "Volume", "Slider", and "Swipe up or Swipe down to adjust".
  iOS: an adjustable element, type Other to XCUITest, label "Volume",
  value "40%"; VoiceOver says "Volume 40% adjustable" and its hint. A
  slider built on `Semantics` is the same on both.
- **On the web no slider has a name** ([FL-028](../flutter-limitations.md#fl-028)):
  not the Material, the Cupertino, or the custom one, however the label is
  given. The label is on the element around the `<input>`. The web tests
  are written to fail when it reaches the input, which Flutter 3.50.0's
  source does.
- **A Material `Slider` puts an empty element over the whole page on the
  web** ([FL-029](../flutter-limitations.md#fl-029)): one per slider, from
  the `OverlayPortal` it keeps for its value indicator. Hit tests find it
  first, so Playwright cannot click anything on those screens; a real
  mouse click, a click event on an element, and VoiceOver's press all
  still reach the control. The cause was found in the framework source.
- **The web's range is a stand-in** ([FL-125](../flutter-limitations.md#fl-125)):
  minimum 0, value 1, maximum 2, moved by one at each change; only
  `aria-valuetext` is real.
- **A `CupertinoSlider` has no keyboard and ignores a tap on its track**
  ([FL-120](../flutter-limitations.md#fl-120), [FL-121](../flutter-limitations.md#fl-121)).
  `good-cupertino` adds both with SDK widgets; the tap on the track is
  asserted to do nothing on every layer, so a fix shows.
- **A `Slider` has the arrow keys and not Home or End**
  ([FL-122](../flutter-limitations.md#fl-122)). On the web Home and End
  reach the browser's `<input>`, which moves one step. `CallbackShortcuts`
  around the slider fixes both.
- **`Slider.label` becomes part of the name**
  ([FL-123](../flutter-limitations.md#fl-123)): TalkBack says "Volume 4"
  and then "Volume 5"; VoiceOver on iOS "Volume 4 40%".
- **A slider whose range is not 0 to 1 still reads a percentage**: a
  rating of 4 out of 10 is "40%" everywhere until
  `semanticFormatterCallback` is given.
- **On Android the value shown straight after an adjustment is right**
  for these sliders ([FL-038](../flutter-limitations.md#fl-038)), because
  each computes its `increasedValue` from its value. A test that waits
  for the description to change cannot tell that the app has acted; the
  Android tests wait for the change count.
- **On the web, a slider without Flutter focus can still get the
  browser's**: `bad-no-keyboard`'s `<input>` is the next element the
  browser can focus after Back, so Tab lands on it there, and the
  browser's keys move it one step at a time. With a Flutter control after
  it, Tab skips it (the probe's fixtures 06 to 08).
- **A disabled slider is not a slider** on any platform
  ([FL-124](../flutter-limitations.md#fl-124)), and a merged `RangeSlider`
  reports one value ([FL-126](../flutter-limitations.md#fl-126)). Neither
  is built.
- **Key events from UI Automator did not move Flutter's focus** on the
  Android emulator in a first try, so the keyboard is asserted in the
  widget tests and on the web only.

- **VoiceOver on the web reads the label as a group around the slider**:
  "Volume group", "40% dimmed slider", "end of Volume group" in
  Chromium. A copy of the same markup in plain HTML is read the same way,
  and a plain `<label>` on the input is read "40% Volume slider", which is
  what Flutter 3.50's change should give.
- **"Dimmed" is the engine disabling the input**
  ([FL-127](../flutter-limitations.md#fl-127)): it does so for half a
  second after any pointer event, and the page received twenty or more
  during each VoiceOver walk. The plain HTML copy is "dimmed" only with
  `disabled` set.
- **In Playwright's WebKit build VoiceOver's cursor left the page** after
  the screen title on all five screens with a Material `Slider`, every
  time, and walked the four others like Chromium
  ([FL-029](../flutter-limitations.md#fl-029); cause not proven). The
  spec asserts both.
- **VoiceOver's own press works beside a Material slider**: in Chromium,
  VoiceOver on Back and its activate command went back, through the
  empty element.

**Not done yet.** A disabled slider and a range slider as examples; a
vertical slider; Page Up and Page Down; a text field for an exact value;
what each screen reader says at the moment the value changes; the
keyboard on Android and iOS; Flutter 3.50.
