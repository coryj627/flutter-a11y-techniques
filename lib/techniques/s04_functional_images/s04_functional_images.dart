import '../../catalog/technique.dart';
import 'examples.dart';

/// S04 Functional images. Spec: docs/specs/S04-functional-images.md.
/// Doc: docs/techniques/S04.md.
final s04FunctionalImages = Technique(
  id: 'S04',
  title: 'Functional images',
  group: TechniqueGroup.semantics,
  summary:
      'An image or icon that is a control has a name that says what the '
      'control does, and the name is on the control, not on the image.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(),
    AppPlatform.ios: PlatformStatus.applies(),
    AppPlatform.web: PlatformStatus.applies(),
  },
  wcag: const [
    WcagCriterion('1.1.1', 'Non-text Content', 'non-text-content'),
    WcagCriterion('4.1.2', 'Name, Role, Value', 'name-role-value'),
  ],
  sources: const [
    SourceLink(
      'iOS SwiftUI: Functional Images',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/FunctionalImages.md',
    ),
    SourceLink(
      'Android Compose: Text Alternatives',
      'https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/content/TextAlternatives.md',
    ),
    SourceLink(
      'Android View: Text Alternatives',
      'https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/basics/TextAlternatives.md',
    ),
    SourceLink(
      'W3C WAI Images Tutorial: Functional Images',
      'https://www.w3.org/WAI/tutorials/images/functional/',
    ),
    SourceLink(
      'MDN: The img element',
      'https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/img',
    ),
    SourceLink(
      'MDN: The area element',
      'https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/area',
    ),
    SourceLink(
      'MDN: The map element',
      'https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/map',
    ),
    SourceLink(
      'WCAG failure F65: no text alternative on an image or image button',
      'https://www.w3.org/WAI/WCAG22/Techniques/failures/F65',
    ),
    SourceLink(
      'WCAG failure F30: text alternatives that are not alternatives',
      'https://www.w3.org/WAI/WCAG22/Techniques/failures/F30',
    ),
    SourceLink(
      'Flutter API: IconButton.tooltip',
      'https://api.flutter.dev/flutter/material/IconButton/tooltip.html',
    ),
    SourceLink(
      'Flutter API: Icon.semanticLabel',
      'https://api.flutter.dev/flutter/widgets/Icon/semanticLabel.html',
    ),
    SourceLink(
      'Flutter API: Image.excludeFromSemantics',
      'https://api.flutter.dev/flutter/widgets/Image/excludeFromSemantics.html',
    ),
    SourceLink(
      'Flutter API: Semantics',
      'https://api.flutter.dev/flutter/widgets/Semantics-class.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-image-button',
      title: 'Picture button named by its tooltip',
      variant: ExampleVariant.material,
      builder: (_) => const GoodImageButton(),
    ),
    TechniqueExample.good(
      slug: 'good-icon-label',
      title: 'Icon button named by the icon\'s label',
      variant: ExampleVariant.material,
      builder: (_) => const GoodIconLabel(),
    ),
    TechniqueExample.good(
      slug: 'good-image-with-text',
      title: 'Picture and icon beside a button\'s text',
      variant: ExampleVariant.material,
      builder: (_) => const GoodImageWithText(),
    ),
    TechniqueExample.good(
      slug: 'good-cupertino',
      title: 'Cupertino icon button',
      variant: ExampleVariant.cupertino,
      builder: (_) => const GoodCupertino(),
    ),
    TechniqueExample.good(
      slug: 'good-custom',
      title: 'Picture button built from Semantics',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodCustomImageButton(),
    ),
    TechniqueExample.good(
      slug: 'good-image-regions',
      title: 'Picture with two regions that are buttons',
      variant: ExampleVariant.material,
      builder: (_) => const GoodImageRegions(),
    ),
    TechniqueExample.bad(
      slug: 'bad-no-name',
      title: 'Picture button with no name',
      variant: ExampleVariant.material,
      defect: 'The picture button has no name, so a screen reader says only "button".',
      builder: (_) => const BadNoName(),
    ),
    TechniqueExample.bad(
      slug: 'bad-label-on-image',
      title: 'Name put on the image inside the button',
      variant: ExampleVariant.material,
      defect: 'The name is on the picture, not the button: on Android and iOS the button has no name and the picture is read as a separate image.',
      builder: (_) => const BadLabelOnImage(),
    ),
    TechniqueExample.bad(
      slug: 'bad-tap-gesture',
      title: 'Picture with a tap handler',
      variant: ExampleVariant.widgets,
      defect: 'The picture is announced as an image, not a button, and a keyboard cannot reach it.',
      builder: (_) => const BadTapGesture(),
    ),
    TechniqueExample.bad(
      slug: 'bad-describes-picture',
      title: 'Name that describes the icon',
      variant: ExampleVariant.material,
      defect: 'The search button is named "Magnifying glass", which does not say what it does.',
      builder: (_) => const BadDescribesPicture(),
    ),
    TechniqueExample.bad(
      slug: 'bad-image-not-excluded',
      title: 'Picture left in the tree beside a button\'s text',
      variant: ExampleVariant.material,
      defect: 'The picture inside the button is not excluded, so VoiceOver on iOS announces the button as an image as well.',
      builder: (_) => const BadImageNotExcluded(),
    ),
    TechniqueExample.bad(
      slug: 'bad-redundant-label',
      title: 'Icon label that repeats the button\'s text',
      variant: ExampleVariant.material,
      defect: 'The icon has a label as well as the text, so the button is named "Printer Print".',
      builder: (_) => const BadRedundantLabel(),
    ),
  ],
);
