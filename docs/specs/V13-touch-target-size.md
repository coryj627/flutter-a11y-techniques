# Spec: V13 Minimum touch target size

Status: Draft 1 (2026-11-19), written with the build. Batch 5, built in
wave 4. Flutter pin: 3.47.5.

This spec covers how big the area is that takes a tap or click on a
control, and how to measure it. Left to others: whether a control
activates at all, from the keyboard, and on release
([I01 Focusable and clickable controls](I01-focusable-controls.md));
the spacing of text (V06 Reflow and adaptive layout, 1.4.12) and its size
(V05 Text scaling); gestures other than a tap (I05 Custom accessibility
actions for 2.5.1, I13 Drag and drop alternatives for 2.5.7); taking a press
back (I01, 2.5.2, and [FL-402](../flutter-limitations.md#fl-402)); what a
link is and how it is named (C03 Stand-alone link, C04 Links inline with
text); and how focus looks (V14).

## 1. Rule

Every control takes taps over an area at least 24 by 24 logical pixels,
or, if smaller, is far enough from every other control that a circle 24
across, centred on it, meets none of them. A control in a sentence is
exempt. Aim higher where the platform does: 48 by 48 dp on Android, 44 by
44 pt on iOS. What counts is the area that takes the tap, not what is drawn
and not what the accessibility tree reports.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies | Applies | Applies |

On the web, the Material theme follows the browser's operating system
([FL-412](../flutter-limitations.md#fl-412)); everything here was measured
in Chromium on a Mac, and a phone's browser only by setting Chromium's
`navigator.platform` and user agent to an Android phone's (section 7).

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [2.5.8 Target Size (Minimum)](https://www.w3.org/TR/WCAG22/#target-size-minimum) (AA) | "The size of the target for pointer inputs is at least 24 by 24 CSS pixels", except for spacing, equivalent, inline, user agent control, and essential |

The criterion's terms, from the WCAG 2.2 text and its
[Understanding document](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html):

- **Target**: the "region of the display that will accept a pointer
  action". So it is the area that takes the tap, which in Flutter is the
  hit test on Android and iOS and the node's element on the web (section
  7), and neither the painted shape nor, on Android and iOS, the node.
- **24 by 24**: a 24 by 24 square fits inside the target. A target 30 wide
  and 20 high is undersized.
- **CSS pixels** are Flutter's logical pixels on the web (measured:
  `window.devicePixelRatio` 1 and element boxes equal to Flutter's). On
  Android and iOS this spec applies the same number to dp and pt, which are
  Flutter's logical pixels there; WCAG defines the CSS pixel by a visual
  angle, and that both dp and pt are close to it is not measured here.
- **Spacing**: "Undersized targets … are positioned so that if a 24 CSS
  pixel diameter circle is centered on the bounding box of each, the
  circles do not intersect another target or the circle for another
  undersized target". Two 18 pixel targets 4 apart fail: their centres are
  22 apart, under 24. A 20 pixel target with no other target within 2
  pixels of its edges passes, as long as no other undersized target's
  centre is within 24 of its own.
- **Inline**: "The target is in a sentence or its size is otherwise
  constrained by the line-height of non-target text".
- **Equivalent**, **user agent control**, **essential**: not used by any
  example. Flutter draws its own controls, so none of the examples' sizes
  is set by the browser.
- 2.5.5 Target Size (Enhanced), 44 by 44, is AAA and not claimed. The 48
  and 44 that Flutter's guidelines check are the platforms' own guidance,
  stricter than 2.5.8.

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | A touch target is at least 24 by 24 | [iOS: Touch Target Size](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/TouchTargetSize.md), [Android View: Minimum Touch Target Size](https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/basics/MinimumTouchTargetSize.md), [Android Compose: Minimum Touch Target Size](https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/interactions/MinimumTouchTargetSize.md) |
| R2 | It should be 48 by 48 dp on Android; 44 by 44 is what Apple's audit checks | Android View and Android Compose (48 dp), iOS (Xcode's audit checks 44 by 44) |
| R3 | Size the control with a minimum size, not by guessing its content's size | Android View (`minWidth` and `minHeight`, the preferred way), Android Compose (`minimumInteractiveComponentSize()`), iOS (`.frame(minWidth: 24, minHeight: 24)`) |
| R4 | The invisible area around a small control counts, and controls whose areas would overlap must be spaced apart | Android Compose ("implicit touch target sizing") |
| R5 | A target in a line of text is exempt | iOS, and the WCAG text (inline) |

Flutter references for the mechanisms used:

- [`MaterialTapTargetSize`](https://api.flutter.dev/flutter/material/MaterialTapTargetSize.html), [`ThemeData.materialTapTargetSize`](https://api.flutter.dev/flutter/material/ThemeData/materialTapTargetSize.html), [`VisualDensity`](https://api.flutter.dev/flutter/material/VisualDensity-class.html)
- [`IconButton`](https://api.flutter.dev/flutter/material/IconButton-class.html) (`padding`, `constraints`, `style`)
- [`CupertinoButton.minimumSize`](https://api.flutter.dev/flutter/cupertino/CupertinoButton/minimumSize.html)
- [`GestureDetector.behavior`](https://api.flutter.dev/flutter/widgets/GestureDetector/behavior.html), [`HitTestBehavior`](https://api.flutter.dev/flutter/rendering/HitTestBehavior.html)
- [`WidgetSpan`](https://api.flutter.dev/flutter/widgets/WidgetSpan-class.html)
- [`androidTapTargetGuideline`](https://api.flutter.dev/flutter/flutter_test/androidTapTargetGuideline-constant.html), [`iOSTapTargetGuideline`](https://api.flutter.dev/flutter/flutter_test/iOSTapTargetGuideline-constant.html), [`MinimumTapTargetGuideline`](https://api.flutter.dev/flutter/flutter_test/MinimumTapTargetGuideline-class.html)

Comparison bar: none. Radix has no primitive for it, and HTML leaves a
control's size to the author.

## 5. Examples

Every player example is a row of three icon buttons, Previous, Play, and
Next, and ends with a count of presses. The bad ones each make the buttons
18 by 18, 4 pixels apart, in one way, so that the defect is the only
difference from a good one.

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-material` | Material | Tonal icon buttons, 40 across, in a 48 by 48 target on Android and iOS; 40 by 40 in a desktop browser | `IconButton.filledTonal` with the theme's `MaterialTapTargetSize.padded` | R1, R2, R4 |
| `good-cupertino` | Cupertino | Tinted buttons 48 by 48 everywhere | `CupertinoButton.tinted(padding: EdgeInsets.zero, minimumSize: Size.square(48))`; the default minimum, 44, would meet Apple's size and 2.5.8 but not Android's 48, which the widget tests check | R1, R2, R3 |
| `good-custom` | Widgets layer | A 24 pixel icon in a 48 by 48 box that takes taps all over | `GestureDetector(behavior: HitTestBehavior.opaque)` around `SizedBox.square(dimension: 48)`, inside `Semantics(button: true)` and the same `FocusableActionDetector` as I01 | R1, R2, R3 |
| `good-inline-link` | Widgets layer | A link in a sentence, as tall as its line of text (20 pixels at the default size) | A `WidgetSpan` holding `Semantics(link: true)` and an opaque `GestureDetector` around the link's text, with a `FocusableActionDetector`. A `WidgetSpan` because a `TextSpan` with a recognizer takes no keyboard focus. To keep it in its place for screen readers ([FL-413](../flutter-limitations.md#fl-413)): a `semanticsIdentifier` on the text before it, and `Semantics(container: true, sortKey: OrdinalSortKey(0.5))` around it | R5 |

### Custom solutions

**Custom solution: not vetted by a real-world example.** `good-cupertino`,
`good-custom` and `good-inline-link` are custom solutions. Each is tested
here in isolation, with screen-reader transcripts, but has not been built
into a real app and tested in a user journey. Do not treat them as vetted
techniques.

The table is this technique's part of the register of custom solutions,
[custom-solutions.md](../custom-solutions.md).

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-material` | Nothing: `IconButton.filledTonal` with the theme's `MaterialTapTargetSize.padded` | `IconButton` | None filled (no padding in a desktop browser, [FL-412](../flutter-limitations.md#fl-412), is left as it is) | R1, R2, R4: iOS: Touch Target Size, Android View: Minimum Touch Target Size, Android Compose: Minimum Touch Target Size, Android View and Android Compose, iOS, Android Compose | not custom |
| `good-cupertino` | An `Actions` for Enter on the web round each `CupertinoButton`; the size is the button's own `minimumSize` | `CupertinoButton` | Enter on the web ([FL-002](../flutter-limitations.md#fl-002)) | R1, R2, R3: iOS: Touch Target Size, Android View: Minimum Touch Target Size, Android Compose: Minimum Touch Target Size, Android View and Android Compose, iOS, Android View, Android Compose | custom |
| `good-custom` | A button drawn by hand: an opaque `GestureDetector` round a 48 by 48 box, in `Semantics(button: true)`, with I01's focus and keys | None for a drawn control | The node can be bigger than the area that takes taps ([FL-410](../flutter-limitations.md#fl-410)) | R1, R2, R3: iOS: Touch Target Size, Android View: Minimum Touch Target Size, Android Compose: Minimum Touch Target Size, Android View and Android Compose, iOS, Android View, Android Compose | custom |
| `good-inline-link` | A link in a sentence: `Semantics(link: true)` and an opaque `GestureDetector` in a `WidgetSpan`, with `FocusableActionDetector`, a `semanticsIdentifier` on the text before it, and a sort key | None: a `TextSpan` link takes no focus ([FL-240](../flutter-limitations.md#fl-240)), and Flutter has no link widget ([FL-221](../flutter-limitations.md#fl-221)) | The link is read after its sentence ([FL-413](../flutter-limitations.md#fl-413)) | R5: iOS | custom |

### Bad

| Slug | Defect | Violates | Fails |
| --- | --- | --- | --- |
| `bad-shrinkwrap` | `IconButton.filledTonal` with no padding, no minimum size, an 18 pixel icon, and `tapTargetSize: MaterialTapTargetSize.shrinkWrap`: each button takes taps on its 18 by 18 icon only, 4 pixels from the next | R1, R4 | 2.5.8 on every platform |
| `bad-zero-padding-web` | The same with the theme's tap target size: on Android and iOS the padding makes each target 48 by 48; in a desktop browser it is not there ([FL-412](../flutter-limitations.md#fl-412)) and each is 18 by 18, 4 apart | R1, R3 | 2.5.8 on the web in a desktop browser; none on Android and iOS |
| `bad-cupertino-small` | `CupertinoButton.tinted` with `minimumSize: Size.square(18)` and no padding: 18 by 18, 4 apart | R1, R3 | 2.5.8 on every platform |
| `bad-custom-small` | The good custom button with the `GestureDetector` around the 18 pixel icon only: 18 by 18, 4 apart | R1, R3 | 2.5.8 on every platform |

Why each bad one fails as the criterion is written: each target is 18 by
18, so it is undersized; the centres of neighbours are 22 apart, so the
circles of neighbours meet (the spacing exception does not hold); no other
control on the screen does the same thing (equivalent); they are a row of
buttons, not text in a sentence (inline); Flutter draws them (user agent
control); and nothing makes 18 pixels essential. The 18 pixel buttons that
take a click a little to the right of their box on the web
([FL-411](../flutter-limitations.md#fl-411)) are still 18 high there, so
still undersized.

Not built:

- A control whose node is bigger than the area that takes taps
  ([FL-410](../flutter-limitations.md#fl-410)), as a bad example. Laid out
  with nodes of 48 by 48 side by side, the 18 pixel areas inside are 30
  apart and pass by spacing, so 2.5.8 is not failed; the case is a
  limitation entry, tested in the widget tests on the SDK alone and in the
  probe on each platform.
- Compact density as a bad example. It takes 8 pixels off, and no Material
  control in the probe went under 32 with it (p03, p09).
- Examples for the equivalent, user agent control, and essential
  exceptions: none of them is something Flutter changes.

## 6. Assertions by layer

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | The 2.5.8 check itself on known rects (a lone 20 pixel target passes, two 2 apart fail, 30 by 20 is undersized). Good: the four guidelines in light and dark; 200% text at 320 by 640; Tab reaches each control and Enter and Space press it, and `ButtonActivateIntent` is handled. Every control: name, button (or link) flag, tap action, and the node's size in logical pixels, as Android. 2.5.8 as Android and iOS: good and `bad-zero-padding-web` have no target under 24; the three other bad ones are 18 by 18, 4 apart, every one fails, and a 24 pixel `MinimumTapTargetGuideline` and `androidTapTargetGuideline` fail them; the link is under 24 high inside its sentence, and the paragraph's nodes are "Read the ", the link, and " before you set off." in that order. 2.5.8 as macOS, Linux, and Windows (a desktop browser): `bad-zero-padding-web` is 18 by 18 and fails, the good examples are 40, 48, and 48 and pass; as Android, iOS, and Fuchsia it is 48 by 48. Taps: every control takes a tap at its centre and 2 pixels inside its bottom edge and not 2 outside it, and nothing 2 pixels right of the last one, each followed by a tap at the centre; `good-material` takes a tap in its padding, outside the drawn circle; `good-custom` outside its icon. SDK alone: FL-410 (two node-bigger-than-hit-area cases pass `androidTapTargetGuideline` and a tap inside the node misses; a text link's node is its text plus 4 and the guideline skips it), FL-412 (an `IconButton` as each platform, and the theme's values, and `materialTapTargetSize: padded` in the theme as macOS), FL-413 (a `WidgetSpan` link with no help: the paragraph's text is one node without it, and the link is its only child) |
| L3 web | Every control: role and name (the link is an `<a>` and a link in Chromium's tree), and the element's size in CSS pixels with a desktop platform. 2.5.8: good pass, bad are 18 by 18, 4 apart, all fail; the link is under 24 high with the sentence's text either side on its line, and the sentence's elements are the text before, the `<a>`, and the text after, in that order. Clicks: centre and 2 inside the bottom edge act, 2 below does not; nothing 2 right of the last good control; FL-411: 2 right of the last bad button presses it and the element there is its own, 2 below the link presses it, 2 above does not. Keyboard: Tab, Enter, and Space on every good control |
| L3 Android | Every control: name, class `Button`, clickable, and size in dp (bounds divided by the density); 2.5.8 as in L1 for Android, in dp; the link under 24 dp high. Taps with `UiDevice.click` at points worked out in dp: centre and 2 dp inside the bottom edge act, 2 dp below and 2 dp right of the last control do not, each followed by a tap at the centre. The link: Tab (`input keyevent`) gives it focus (`isFocused`), and Enter and Space each press it |
| L3 iOS | The same in points: label, type (`button`, `link`), frame size, 2.5.8, and taps with `XCUICoordinate`. The link: two Tabs (Back, then the link) and Enter, then Space, each press it |
| L4 TalkBack | Each control: its name, "Button", "Double-tap to activate"; the link is read as a button too ([FL-032](../flutter-limitations.md#fl-032)) |
| L4 VoiceOver iOS | Every utterance between the "Example" heading and the count: "Previous Button", "Play Button", "Next Button" for every player; for the link, the sentence in order: "Read the", "trail rules Link", "before you set off." ([FL-413](../flutter-limitations.md#fl-413)'s workaround) |
| L4 VoiceOver web | Every stop between the "Example" heading and the count, in Chromium and WebKit: "Previous button", "Play button", "Next button"; for the link, the sentence in order: "Read the", "link trail rules", "before you set off." (FL-413's workaround) |

Size is not heard: TalkBack and VoiceOver read the 18 pixel buttons as
they read the 48 pixel ones, and the screen reader layers record that.

## 7. What the build found (Flutter 3.47.5)

The probe that came first is in
[evidence/probes/v13](../evidence/probes/v13/README.md), with the raw
output of each platform: twenty controls measured and tapped 2 pixels
inside and outside each edge, on the Android emulator (density 2.625), the
iOS simulator, and Chromium.

- **Each platform's accessibility tree reports Flutter's semantics node**,
  in dp (Android bounds divided by the density, to the pixel's rounding),
  pt (iOS), or CSS pixels (the web), and one logical pixel is one of each.
- **On Android and iOS a tap is taken where Flutter's hit test says**, and
  that can be smaller than the node: padding outside a `GestureDetector`,
  a `GestureDetector` with the default `deferToChild` around a box with
  empty space, and a text link, whose node is its text plus 4 pixels on
  each side ([FL-410](../flutter-limitations.md#fl-410)). The tap target
  guidelines in `flutter_test` read the node, so they pass such a control.
- **On the web a click is taken by the node's element**, which is the
  node, and by any of the element's label text that runs out of it: 2
  pixels right of an 18 pixel button and 2 pixels below the link both act
  ([FL-411](../flutter-limitations.md#fl-411)).
- **The padding of a Material button takes taps** on Android and iOS (the
  48 by 48 box around a 40 pixel `IconButton`), and
  `MaterialTapTargetSize.shrinkWrap` removes it. **In a desktop browser the
  theme has no padding and is compact**
  ([FL-412](../flutter-limitations.md#fl-412)): an `IconButton` is 40 by
  40, a `TextButton` 32 high, a `Checkbox` 40 by 40, and one with no
  padding and no constraints the size of its icon. Chromium told it was an
  Android phone's browser (`navigator.platform` "Linux armv8l") got the
  padding back: 48 by 48.
- **`CupertinoButton` takes taps over its whole minimum size**, 44 by 44 by
  default (28 for `CupertinoButtonSize.small`), and the same on every
  platform; a smaller `minimumSize` gives a smaller target.
- **At 200% text** icons and icon buttons keep their size; text buttons and
  text links grow with the text. With the Android emulator's own font size
  at 2.0 a 20 pixel line of text became 37.
- **Size is not heard** by TalkBack or VoiceOver.
- **The link in `good-inline-link`** is an `<a>` with no `href` on the
  web, which Chromium's own accessibility tree calls a link and
  Playwright's role check does not ([FL-032](../flutter-limitations.md#fl-032)),
  and a link to XCUITest; TalkBack reads it as a button. What it is and
  how it is named is C04's.
- **In the first build the sentence around the link was read without
  it**, on iOS and the web, and the link after it; on Android the tree had
  the same order ([FL-413](../flutter-limitations.md#fl-413)). It came
  from the `WidgetSpan`, which is there so that the link takes keyboard
  focus. A `TextSpan` with a recognizer keeps its place but takes no
  keyboard focus. The second round of the probe found a way to have both
  (a `semanticsIdentifier` on a run of the sentence, and a sort key on the
  link), and `good-inline-link` now uses it: the sentence is read in order
  on iOS and the web, the web tree has the three parts in order, and Tab,
  Enter, and Space work on every platform. Links in text in general, and
  their role, are C04's subject.

**Not done yet.** A phone's browser itself (only imitated in Chromium);
Safari and Firefox; the desktop platforms as apps (read in the source
only); touches on the web (round 1 of the probe counted touches near a
fixture that were not explained, section "Taps" of the probe README);
Android's own device font size on the examples (only in the probe); and
whether dp and pt are close to WCAG's CSS pixel on a given device.
