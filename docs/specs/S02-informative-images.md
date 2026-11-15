# Spec: S02 Informative images

Status: Draft 1 (2026-11-14), written with the build. Second technique of
batch 1 ([plan](../plan.md)). Flutter pin: 3.47.5.

An informative image tells people something. Images that add nothing are
S03 Decorative images; images that are a control's whole content (an icon
button, an image link) are S04 Functional images and
[C01 Button](C01-button.md).

## 1. Rule

An image or icon that conveys information has a text alternative that
conveys the same information. The alternative is short, says what the image
shows or means, and does not include the word "image" or a file name.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies | Applies | Applies |

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [1.1.1 Non-text Content](https://www.w3.org/TR/WCAG22/#non-text-content) | Non-text content has a text alternative that serves the same purpose |

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | An informative image has a text alternative | [iOS Images](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/Images.md), [iOS Informative Images](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/InformativeImages.md), [Android Compose Text Alternatives](https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/content/TextAlternatives.md), [Android View Text Alternatives](https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/basics/TextAlternatives.md), [MDN `img`](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/img) |
| R2 | The alternative matches the relevant content of the image | iOS Informative Images |
| R3 | The alternative does not include the word "image"; the screen reader says it | iOS Informative Images |
| R4 | The alternative describes what the image shows, not its file name | [iOS Accessibility Label](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/AccessibilityLabel.md); MDN `img` |
| R5 | An icon that conveys information has a text alternative | Android Compose Text Alternatives |
| R6 | An image and text that belong together can be combined into one element | iOS Informative Images; Android Compose Text Alternatives ("Avoid redundancy in grouped content") |
| R7 | A group of image and text can be replaced by a single description, with the parts hidden so they are not read as well | Android Compose Text Alternatives ("Overriding grouped content with a single description") |
| R8 | A complex image such as a chart has a concise alternative for its purpose, and its detail in text nearby | Android Compose Text Alternatives ("Handling complex images") |

Flutter references for the mechanisms used:

- [`Image.semanticLabel`](https://api.flutter.dev/flutter/widgets/Image/semanticLabel.html)
- [`Icon.semanticLabel`](https://api.flutter.dev/flutter/widgets/Icon/semanticLabel.html)
- [`SemanticsProperties.image`](https://api.flutter.dev/flutter/semantics/SemanticsProperties/image.html)
- [`ExcludeSemantics`](https://api.flutter.dev/flutter/widgets/ExcludeSemantics-class.html)

HTML elements in the inventory row: `img` maps to `Image` with a
`semanticLabel`. `picture` and `svg` are ways to supply the picture and get
their alternative the same way. `figure` and `figcaption` have no Flutter
counterpart: `SemanticsRole` has no figure role (FL-026), so a caption is
text beside the image.

## 5. Examples

The photo is a small PNG held in code (`example_image.dart`) and shown with
`Image.memory`, so the examples need no asset path in the app or the
Widgetbook. `semanticLabel` is the same parameter on `Image.asset` and
`Image.network`.

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-image-label` | Widgets | A photo with a text alternative | `Image(semanticLabel:)` | R1, R2, R3 |
| `good-icon-label` | Material | Status icons that are the only sign of an order's status | `Icon(semanticLabel:)`, merged with the order's text by `MergeSemantics` | R5, R6 |
| `good-group-description` | Material | An icon and a time read as "Sunrise at 6:35 am" | `Semantics(label:)` around `ExcludeSemantics` | R7 |
| `good-chart` | Widgets | A drawn bar chart with a short alternative, and its numbers in text below | `Semantics(image: true, label:)` around `CustomPaint` | R8 |

### Bad

| Slug | Defect | Violates | Fails |
| --- | --- | --- | --- |
| `bad-no-label` | A photo with no text alternative | R1 | 1.1.1 |
| `bad-icon-no-label` | Status icons with no text alternative; the status is not exposed | R5 | 1.1.1 |
| `bad-role-in-label` | The alternative starts with "Image of" | R3 | — (the role is heard twice) |
| `bad-filename-label` | The alternative is "IMG_2041.png" | R4 | 1.1.1 (the alternative does not serve the purpose of the image) |

## 6. Assertions by layer

Elements are located by role and name. Images have no controls to identify.

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Image flag and label per example; merged rows; that excluded parts are not in the tree; the bad examples' missing or wrong labels; guidelines in light and dark and 200% text for the good examples |
| L3 web | `role="img"` and accessible name; text content of merged rows; an unnamed `img` for the unlabelled photo |
| L3 Android | `ImageView` class and description; merged rows as one node; an `ImageView` with no description for the unlabelled photo |
| L3 iOS | Image element type and label; merged rows as one element; an image element with no label for the unlabelled photo |
| L4 TalkBack | The alternative and "Image" spoken; the status spoken, or not, for the icon rows; "Unlabelled" for the photo with no alternative |
| L4 VoiceOver iOS | "… Image" spoken per image; the unlabelled photo is skipped |
| L4 VoiceOver web | The alternative and the image role spoken; what is said at the unlabelled photo |

## 7. What the build found (Flutter 3.47.5)

The probe that came first is in [evidence/probes/s02](../evidence/probes/s02/).

- **`Image(semanticLabel:)` and `Semantics(image: true, label:)` are a named
  image on all three platforms**: `role="img"` with `aria-label`,
  `ImageView` with a description, and an image element with a label.
- **An `Image` with no label is still in the tree**, as an image with no
  name, on all three platforms. VoiceOver on macOS stops on it and says
  "image"; TalkBack, moved to it, says "Unlabelled. Image"; VoiceOver on iOS
  skips it. So leaving the label off does not hide
  an image; hiding one is S03.
- **`Icon(semanticLabel:)` is exposed as text, not as an image**, on all
  three. An `Icon` with no label exposes nothing.
- **A merged row keeps a line break** between the icon's label and the text.
  TalkBack's log splits such speech over two lines, which the transcript
  tool did not handle; `parse_speech` in `tool/talkback.py` now joins them.
  This was a tool problem, not Flutter's.
- **VoiceOver on iOS puts unusual whitespace between a label and "Image"**
  in what the API returns. The iOS test collapses whitespace before
  comparing.
- **No figure role.** `figure` and `figcaption` cannot be expressed (added
  to FL-026).
- No new Flutter limitation.

**Not done yet.** Whether an alternative describes the image well cannot be
tested. Images of text, long descriptions on a separate screen, and
`Image.asset` and `Image.network` are not shown. TalkBack was moved to the
unlabelled photo by the test; whether a swipe would stop on it was not
tried. There is no Cupertino variant: `Image` and `Icon`
are the same widgets in every design system.
