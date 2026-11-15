# Spec: S03 Decorative images

Status: Draft 1 (2026-11-14), written with the build. Third technique of
batch 1 ([plan](../plan.md)). Flutter pin: 3.47.5.

A decorative image adds nothing to the text around it. Images that tell
people something are [S02 Informative images](S02-informative-images.md);
images that are a control's whole content are S04 Functional images and
[C01 Button](C01-button.md).

## 1. Rule

An image or icon that conveys no information is not exposed to assistive
technology: it has no text alternative and is not in the semantics tree.
Leaving the text alternative off is not enough for an `Image`; it has to be
excluded.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies | Applies | Applies |

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [1.1.1 Non-text Content](https://www.w3.org/TR/WCAG22/#non-text-content) | Non-text content that is pure decoration is implemented so that assistive technology can ignore it |

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | A decorative image is hidden from the screen reader | [iOS Decorative Images](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/DecorativeImages.md), [iOS Images](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/Images.md), [Android Compose Text Alternatives](https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/content/TextAlternatives.md), [Android View Text Alternatives](https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/basics/TextAlternatives.md), [MDN `img`](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/img), [WAI Images Tutorial: Decorative Images](https://www.w3.org/WAI/tutorials/images/decorative/) |
| R2 | A decorative image has no text alternative | iOS Decorative Images ("should have no `.accessibilityLabel`"); Android Compose and View Text Alternatives ("never put a non-null `contentDescription` on a purely decorative image") |
| R3 | An image that only repeats the text beside it is decorative | WAI Images Tutorial: Decorative Images |
| R4 | The platform's own way to mark decoration is used; an empty string is not a substitute where the platform does not treat it as one | Android Compose Text Alternatives ("Never use the empty string for a `contentDescription`") |
| R5 | A decorative image that assistive technology cannot ignore is a failure of 1.1.1 | [WCAG failure F38](https://www.w3.org/WAI/WCAG22/Techniques/failures/F38) |
| R6 | The simple mechanism is preferred; hiding by a general "hide from accessibility" wrapper is for cases that have no simpler one | Android Compose Text Alternatives |

Whether an image is decorative is a judgement. The Android Compose and View
documents note that a picture that sets a tone may deserve a description;
that choice belongs to the designer and is not tested here.

Flutter references for the mechanisms used:

- [`Image.excludeFromSemantics`](https://api.flutter.dev/flutter/widgets/Image/excludeFromSemantics.html)
- [`Icon.semanticLabel`](https://api.flutter.dev/flutter/widgets/Icon/semanticLabel.html)
- [`DecorationImage`](https://api.flutter.dev/flutter/painting/DecorationImage-class.html)
- [`ExcludeSemantics`](https://api.flutter.dev/flutter/widgets/ExcludeSemantics-class.html)
- [`MergeSemantics`](https://api.flutter.dev/flutter/widgets/MergeSemantics-class.html)

HTML element in the inventory row: `img` with an empty `alt`. Flutter's
counterpart is `Image(excludeFromSemantics: true)`. An empty
`semanticLabel` is not: see `bad-empty-label`.

## 5. Examples

The banner and the small picture are the PNG from S02
(`example_image.dart`), shown with `Image.memory`.

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-image-excluded` | Widgets | A decorative banner between two lines of text | `Image(excludeFromSemantics: true)` | R1, R2 |
| `good-icon-no-label` | Material | Icons beside the words they illustrate | `Icon` with no `semanticLabel` | R1, R2, R3 |
| `good-background-image` | Widgets | The banner painted as a background | `DecorationImage` in a `BoxDecoration` | R1, R2 |
| `good-exclude-semantics` | Material | An avatar with the initials of the name beside it | `ExcludeSemantics` around `CircleAvatar` | R1, R6 |
| `good-merged-row` | Widgets | A small picture in a row that is read as one element | `Image(excludeFromSemantics: true)` inside `MergeSemantics` | R1 |

### Bad

| Slug | Defect | Violates | Fails |
| --- | --- | --- | --- |
| `bad-not-excluded` | The banner has no label and is not excluded: an image with no name | R1 | 1.1.1 (F38), where a screen reader stops on it |
| `bad-empty-label` | The banner has `semanticLabel: ''`, which does not hide it | R1, R4 | 1.1.1 (F38), where a screen reader stops on it |
| `bad-redundant-label` | Each icon has a label that repeats the word beside it | R2 | — (every word is read twice) |
| `bad-merged-image` | The picture in the merged row is not excluded, so the row of text has the image role | R1 | 1.1.1 (F38): the decoration is announced, as the row's role |

## 6. Assertions by layer

Elements are located by role and name. Images have no controls to identify.

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | The labels of each example, in order, and that no node is an image in the good examples; an unnamed image node in the first two bad examples; doubled labels; the image flag on the merged row; guidelines in light and dark and 200% text for the good examples |
| L3 web | No `role="img"` in the good examples; an unnamed `img` with no `aria-hidden` for the banner; doubled text; the merged row as `img` |
| L3 Android | No `ImageView` in the good examples and the example's nodes in order; an `ImageView` with no description; doubled nodes; the merged row as `ImageView` |
| L3 iOS | No image element in the good examples; an image element with no label; doubled elements; the merged row as an image |
| L4 TalkBack | What is read on each text and row, and on the unnamed banner when focus is moved to it |
| L4 VoiceOver iOS | Every element of each example, in order, compared as a whole list. The end of the screen is shown by a walk forward that comes to rest and a walk back to the heading |
| L4 VoiceOver web | Every stop of VoiceOver's cursor in each example, in order, compared as a whole list. Stops and the end of the screen are told by the cursor's position, read after every move |

## 7. What the build found (Flutter 3.47.5)

The probe that came first is in [evidence/probes/s03](../evidence/probes/s03/).

- **A `CustomPaint` exposes nothing only when its painter has no
  `semanticsBuilder` and it has no child with semantics.** The probe's
  painter had neither.
- **`excludeFromSemantics: true`, an `Icon` with no label, a
  `DecorationImage`, a `CircleAvatar` background image, and anything inside
  `ExcludeSemantics` expose nothing** on all three platforms.
- **`semanticLabel: ''` does not hide an `Image`.** It is exposed exactly
  as an `Image` with no label: `role="img"` with no name, an `ImageView`
  with no description, an image element with no label.
- **The unnamed image is heard differently on each platform.** VoiceOver on
  macOS stops on it and says "image". VoiceOver on iOS skips it. On Android
  the node is not focusable, and TalkBack says "Unlabelled. Image" when the
  test moves focus to it.
- **An unlabelled `Image` inside `MergeSemantics` turns the merged node
  into an image** named by the row's text, on all three platforms.
- **`Icon(semanticLabel: '')` leaves an empty node on Android** (not
  focusable) and nothing on web and iOS. Seen in the probe only; no example
  uses it.
- **The web VoiceOver walk reads VoiceOver directly.** Guidepup reported
  no phrase at the second of two stops that read the same, and turns a
  failed read into an empty phrase. The S03 walk therefore reads the last
  phrase and the cursor's position over AppleScript after every move, and
  the transcript shows the repeated words of `bad-redundant-label`. A direct
  read can also catch a VoiceOver hint ("You are currently on a heading
  ...") in place of an element's text when VoiceOver has been on it for a
  moment. That was seen once while recording, on a heading before the
  example; the committed transcript has none.
- No new Flutter limitation.

**Not done yet.** Which elements a TalkBack swipe stops on is not tested:
`UiDevice.swipe`, `input swipe`, and `input keycombination` (Alt and Right
arrow) sent to the emulator did not move TalkBack focus, so the walk moves
focus by action. That leaves open whether TalkBack stops on the unnamed
banner. What a screen reader does when a finger is put on the banner was
not tried either. Whether an image is rightly judged decorative cannot be
tested. `Image.asset` and `Image.network` are not shown; they take the same
`excludeFromSemantics`. There is no Cupertino variant: `Image` and `Icon`
are the same widgets in every design system.
