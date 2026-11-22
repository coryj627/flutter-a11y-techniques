# Spec: S04 Functional images

Status: Draft 1 (2026-11-14), written with the build. Fourth technique of
batch 1 ([plan](../plan.md)). Flutter pin: 3.47.5.

A functional image is a picture or icon that is a control, or part of one.
Images that only tell people something are
[S02 Informative images](S02-informative-images.md); images that add nothing
are [S03 Decorative images](S03-decorative-images.md). What a button is, its
states, and its keyboard behaviour are [C01 Button](C01-button.md). Image
links are left to C03 Stand-alone link.

## 1. Rule

A control whose content is an image has an accessible name that says what
the control does, not what the image shows. The name is on the control, and
the image inside it is not exposed as an element or a role of its own. When
the control also has text, the text is the name and the image has no text
alternative.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies | Applies | Applies |

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [1.1.1 Non-text Content](https://www.w3.org/TR/WCAG22/#non-text-content) | Non-text content that is a control has a name that describes its purpose |
| [4.1.2 Name, Role, Value](https://www.w3.org/TR/WCAG22/#name-role-value) | A control made from an image has a name and a role that assistive technology can read |

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | An image used as a control has a text alternative | [iOS Functional Images](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/FunctionalImages.md), [Android Compose Text Alternatives](https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/content/TextAlternatives.md) (`IconButton` content without text), [Android View Text Alternatives](https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/basics/TextAlternatives.md) (`ImageButton` without text), [WAI Images Tutorial: Functional Images](https://www.w3.org/WAI/tutorials/images/functional/), [MDN `img`](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/img), [WCAG failure F65](https://www.w3.org/WAI/WCAG22/Techniques/failures/F65) |
| R2 | The alternative describes what the control does, not what the image looks like | iOS Functional Images ("should not describe what an image looks like, instead, it should describe its function"); WAI Functional Images ("should convey the action that will be initiated"); [WCAG failure F30](https://www.w3.org/WAI/WCAG22/Techniques/failures/F30) |
| R3 | The alternative does not contain the word "image" or "icon" | iOS Functional Images |
| R4 | The image is in a real control, with the control's role, not an image with a tap handler | iOS Functional Images sample code (the second bad example: an `Image` with a tap gesture "rather than as a `Button`") |
| R5 | An image beside text in the same control has no text alternative of its own | WAI Functional Images (example 2: the image "adds no new function or information", so its alternative is empty); Android Compose and View Text Alternatives (redundant content is not given a second description) |
| R6 | Each active region of an image has its own alternative | [MDN `area`](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/area) (`alt` is required when the area is a link), [MDN `map`](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/map) |

R3 is not given an example here: a name that ends in the role is
`bad-role-in-name` in C01, and "Image of" in an alternative is
`bad-role-in-label` in S02.

Flutter references for the mechanisms used:

- [`IconButton.tooltip`](https://api.flutter.dev/flutter/material/IconButton/tooltip.html)
- [`Icon.semanticLabel`](https://api.flutter.dev/flutter/widgets/Icon/semanticLabel.html)
- [`Image.excludeFromSemantics`](https://api.flutter.dev/flutter/widgets/Image/excludeFromSemantics.html)
- [`Semantics`](https://api.flutter.dev/flutter/widgets/Semantics-class.html) (`button`, `label`)
- [`FocusableActionDetector`](https://api.flutter.dev/flutter/widgets/FocusableActionDetector-class.html)
- [`InkWell`](https://api.flutter.dev/flutter/material/InkWell-class.html)

HTML elements in the inventory row: `img` in `button`, whose counterpart is
an `Image` or `Icon` in a button named as in section 5; `area` and `map`,
which have no widget, and whose counterpart is one button for each region
(`good-image-regions`). `img` in `a` is left to C03, because a link in
Flutter has its own problems on the web
([FL-013](../flutter-limitations.md#fl-013)); the name of an image link is
given the same way as a button's.

## 5. Examples

The picture is the PNG from S02 (`example_image.dart`), shown with
`Image.memory`. Every example ends with a count of activations, so a person
or a test can tell that the control worked.

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-image-button` | Material | A picture that is the whole button | `IconButton(tooltip:)` with `Image(excludeFromSemantics: true)` | R1, R2, R4 |
| `good-icon-label` | Material | An icon button named by its icon | `IconButton` with `Icon(semanticLabel:)` | R1, R2 |
| `good-image-with-text` | Material | A picture beside a button's text, and an icon beside another's | `TextButton` with an excluded `Image` and `Text`; `FilledButton.icon` with an unlabelled `Icon` | R5 |
| `good-cupertino` | Cupertino | An icon button | `CupertinoButton` with `Icon(semanticLabel:)` | R1, R2 |
| `good-custom` | Widgets | A picture made into a button without Material | `Semantics(button: true, label:)`, `FocusableActionDetector`, `GestureDetector`, excluded `Image` | R1, R2, R4 |
| `good-image-regions` | Material | One picture with two regions that are buttons | `Stack`: an excluded `Image` under two `Semantics(button: true, label:)`, each with an `InkWell` on a transparent `Material` and a focus ring drawn above the picture | R6 |

### Custom solutions

**Custom solution: not vetted by a real-world example.** `good-cupertino`,
`good-custom` and `good-image-regions` are custom solutions. Each is tested
here in isolation, with screen-reader transcripts, but has not been built
into a real app and tested in a user journey. Do not treat them as vetted
techniques.

The table is this technique's part of the register of custom solutions,
[custom-solutions.md](../custom-solutions.md).

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-image-button` | Nothing: `IconButton(tooltip:)` with an excluded `Image` | `IconButton` | none | R1, R2, R4: iOS Functional Images, Android Compose Text Alternatives, Android View Text Alternatives, WAI Images Tutorial: Functional Images, MDN img, WCAG failure F65, WAI Functional Images, WCAG failure F30, iOS Functional Images sample code | not custom |
| `good-icon-label` | Nothing: `IconButton` with `Icon(semanticLabel:)` | `IconButton` | none | R1, R2: iOS Functional Images, Android Compose Text Alternatives, Android View Text Alternatives, WAI Images Tutorial: Functional Images, MDN img, WCAG failure F65, WAI Functional Images, WCAG failure F30 | not custom |
| `good-image-with-text` | Nothing: `TextButton` with an excluded `Image`; `FilledButton.icon` | `TextButton`, `FilledButton.icon` | none | R5: WAI Functional Images, Android Compose and View Text Alternatives | not custom |
| `good-cupertino` | An `Actions` for `ButtonActivateIntent` round the `CupertinoButton`, so that Enter works on the web | `CupertinoButton` | Enter on the web ([FL-002](../flutter-limitations.md#fl-002)) | R1, R2: iOS Functional Images, Android Compose Text Alternatives, Android View Text Alternatives, WAI Images Tutorial: Functional Images, MDN img, WCAG failure F65, WAI Functional Images, WCAG failure F30 | custom |
| `good-custom` | A picture made a button: `Semantics(button: true, label:)`, `FocusableActionDetector`, a `GestureDetector`, an excluded `Image`, a focus ring of its own | `IconButton`; none for a drawn control | none | R1, R2, R4: iOS Functional Images, Android Compose Text Alternatives, Android View Text Alternatives, WAI Images Tutorial: Functional Images, MDN img, WCAG failure F65, WAI Functional Images, WCAG failure F30, iOS Functional Images sample code | custom |
| `good-image-regions` | An image map: two `Semantics(button: true, label:)` regions with an `InkWell` each on a transparent `Material`, over an excluded `Image`, each with a focus ring drawn above the picture | None: Flutter has no image map | none | R6: MDN area, MDN map | custom |

### Bad

| Slug | Defect | Violates | Fails |
| --- | --- | --- | --- |
| `bad-no-name` | The picture button has no `tooltip` and no label: a button with no name | R1 | 1.1.1 (F65), 4.1.2 |
| `bad-label-on-image` | The name is `Image(semanticLabel:)` inside the button. On Android and iOS the button has no name and the image is a second element ([FL-030](../flutter-limitations.md#fl-030)) | R1 | 4.1.2 on Android and iOS |
| `bad-tap-gesture` | A labelled `Image` in a `GestureDetector`: an image, not a button, and no keyboard access | R4 | 4.1.2, 2.1.1 |
| `bad-describes-picture` | The search button is named "Magnifying glass" | R2 | 1.1.1 (F30: the alternative does not serve the purpose of the image) |
| `bad-image-not-excluded` | The picture beside the button's text is not excluded; the button is an image as well on Android and iOS ([FL-031](../flutter-limitations.md#fl-031)) | R5 | — (the name and the button role are still there) |
| `bad-redundant-label` | The icon beside the text has a label: the button is named "Printer Print" | R5 | — (the visible text is still in the name) |

`bad-label-on-image` and `bad-tap-gesture` have no `TestId`: its
`MergeSemantics` would join the image to the control and hide the defect.
Their nodes are found by role, name, and structure, and the widget tests use
a plain `Key`.

## 6. Assertions by layer

Controls are located by `TestId`, except in the two examples above.

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Good: name, button flag, no image flag, no image node, tap, Tab reach, Enter and Space; the focus ring of the focused region in `good-image-regions`; guidelines in light and dark and 200% text. Bad: no name; the unnamed button with the named image as its child; image and no button, no focus; the wrong name; button and image flags together; the doubled name |
| L3 web | Good: `role="button"`, accessible name, click, Tab, Enter and Space, no `role="img"`. Bad: the unnamed button; an `img` nested in a button that has no `aria-label`; an `img` and no button, never focused; the wrong name; the doubled name. `bad-image-not-excluded` is asserted to be a plain button on web |
| L3 Android | Good: `Button` class, description, click, no `ImageView`. Bad: an unnamed clickable node; an unnamed `Button` with a named `ImageView` child; an `ImageView` and no `Button`; `ImageView` class on the button with a picture; the doubled description |
| L3 iOS | Good: button type, label, tap, no image element. Bad: an unnamed button; an unnamed button and a named image; an image and no button; the doubled label. The image trait on a button cannot be read from the tree |
| L4 TalkBack | What is read with focus on each control, and on each of the two nodes of `bad-label-on-image` and `bad-tap-gesture` |
| L4 VoiceOver iOS | Every utterance between the "Example" heading and the activation count, compared as a whole list. A move with no speech is an entry in the list as a silent stop only when one move back reads the element before it and the move forward again is silent too |
| L4 VoiceOver web | Every stop of VoiceOver's cursor between the "Example" heading and the activation count, compared as a whole list, in Chromium and WebKit |

## 7. What the build found (Flutter 3.47.5)

The probe that came first is in [evidence/probes/s04](../evidence/probes/s04/).

- **A button is named by `tooltip`, by its text, by `Semantics(label:)`, or
  by an `Icon`'s `semanticLabel`, and then reads as a button and nothing
  else** on all three platforms, provided any `Image` in it is excluded.
- **A label on an `Image` inside a button does not name the button on
  Android and iOS** ([FL-030](../flutter-limitations.md#fl-030)). `Image`
  with a label is always a semantics node of its own. TalkBack and VoiceOver
  on iOS read "Button", then "Open trail guide, Image". Chromium computes
  the button's name from the image, and VoiceOver on macOS reads "Open trail
  guide, button" in Chromium and WebKit, so the web hides the defect.
- **An `Image` that is not excluded makes the button an image as well on
  Android and iOS** ([FL-031](../flutter-limitations.md#fl-031)). VoiceOver
  on iOS says "Trail guide, Button, Image". On Android the node's class is
  `ImageView`, and TalkBack still says "Trail guide, Button". The web
  exposes a plain button.
- **A tap handler around a labelled `Image` is two elements on Android and
  iOS**: one that takes the tap and has no name or role, and the image.
  VoiceOver on iOS stops on the first and says nothing; TalkBack said
  "Button" for it in two recordings and nothing in a third. On the web it is one image that the keyboard cannot
  reach.
- **`bad-no-name` is heard as "button" on the web and by TalkBack, and as
  "Button, Image" by VoiceOver on iOS.**
- **`InkWell` and `Tooltip` with `InkWell` give no button role on Android
  and iOS** (probe fixtures 05 and 16). That is C01's subject
  ([FL-006](../flutter-limitations.md#fl-006) is its web side).
- **`Semantics(link: true)` without `linkUrl` is not a link on the web**
  (probe fixtures 08 and 09): the element is an `<a>` with no `href`. Left
  to C03.
- **An `InkWell` placed over a picture needs a `Material` above the
  picture.** Its highlights are painted on the nearest `Material` ancestor,
  which is otherwise under the picture, so keyboard focus could not be seen.
  The regions of `good-image-regions` have a transparent `Material` and draw
  a focus ring of their own.
- **"No speech" from `XCUIVoiceOverService` is a timeout, not a position.**
  The iOS walk steps back and forward again before it records a silent
  stop. In `bad-tap-gesture` the step back read the "Example" heading and
  the second step forward was silent again.
- The iOS walk needs no rule for the end of the screen here: the activation
  count is a unique last element in every example.

**Not done yet.** Which elements a TalkBack swipe stops on is not tested;
the walk moves focus by action (see S03). Image links are left to C03. A
toggle made from an image (a favourite star) is left to C02 Toggle button. Whether a name describes the action well cannot be tested:
`bad-describes-picture` asserts only that the name is the one written.
`Image.asset` and `Image.network` are not shown; they take the same
parameters. `Ink.image` under an `InkWell` was probed (fixture 18) and
behaves as `good-custom` does; it has no example.
