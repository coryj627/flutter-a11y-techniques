import '../../catalog/technique.dart';
import 'examples.dart';

/// S02 Informative images. Spec: docs/specs/S02-informative-images.md.
/// Doc: docs/techniques/S02.md.
final s02InformativeImages = Technique(
  id: 'S02',
  title: 'Informative images',
  group: TechniqueGroup.semantics,
  summary:
      'An image or icon that tells people something has a text alternative '
      'that says the same thing, in a few words, without the word "image".',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(),
    AppPlatform.ios: PlatformStatus.applies(),
    AppPlatform.web: PlatformStatus.applies(),
  },
  wcag: const [WcagCriterion('1.1.1', 'Non-text Content', 'non-text-content')],
  sources: const [
    SourceLink(
      'CVS Health iOS SwiftUI: Images',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/Images.md',
    ),
    SourceLink(
      'CVS Health iOS SwiftUI: Informative Images',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/InformativeImages.md',
    ),
    SourceLink(
      'CVS Health iOS SwiftUI: Accessibility Label',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/AccessibilityLabel.md',
    ),
    SourceLink(
      'CVS Health Android Compose: Text Alternatives',
      'https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/content/TextAlternatives.md',
    ),
    SourceLink(
      'CVS Health Android View: Text Alternatives',
      'https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/basics/TextAlternatives.md',
    ),
    SourceLink(
      'MDN: The img element',
      'https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/img',
    ),
    SourceLink(
      'Flutter API: Image.semanticLabel',
      'https://api.flutter.dev/flutter/widgets/Image/semanticLabel.html',
    ),
    SourceLink(
      'Flutter API: Icon.semanticLabel',
      'https://api.flutter.dev/flutter/widgets/Icon/semanticLabel.html',
    ),
    SourceLink(
      'Flutter API: SemanticsProperties.image',
      'https://api.flutter.dev/flutter/semantics/SemanticsProperties/image.html',
    ),
    SourceLink(
      'Flutter API: ExcludeSemantics',
      'https://api.flutter.dev/flutter/widgets/ExcludeSemantics-class.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-image-label',
      title: 'Photo with a text alternative',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodImageLabel(),
    ),
    TechniqueExample.good(
      slug: 'good-icon-label',
      title: 'Status icons with text alternatives',
      variant: ExampleVariant.material,
      builder: (_) => const GoodIconLabel(),
    ),
    TechniqueExample.good(
      slug: 'good-group-description',
      title: 'Icon and text with one description',
      variant: ExampleVariant.material,
      builder: (_) => const GoodGroupDescription(),
    ),
    TechniqueExample.good(
      slug: 'good-chart',
      title: 'Chart with a short alternative and its data in text',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodChart(),
    ),
    TechniqueExample.bad(
      slug: 'bad-no-label',
      title: 'Photo with no text alternative',
      variant: ExampleVariant.widgets,
      defect: 'The photo has no text alternative.',
      builder: (_) => const BadNoLabel(),
    ),
    TechniqueExample.bad(
      slug: 'bad-icon-no-label',
      title: 'Status icons with no text alternatives',
      variant: ExampleVariant.material,
      defect:
          'The icons are the only sign of each order\'s status, and they '
          'have no text alternative.',
      builder: (_) => const BadIconNoLabel(),
    ),
    TechniqueExample.bad(
      slug: 'bad-role-in-label',
      title: 'Role repeated in the text alternative',
      variant: ExampleVariant.widgets,
      defect:
          'The text alternative starts with "Image of", so the role is '
          'announced twice.',
      builder: (_) => const BadRoleInLabel(),
    ),
    TechniqueExample.bad(
      slug: 'bad-filename-label',
      title: 'File name as the text alternative',
      variant: ExampleVariant.widgets,
      defect:
          'The text alternative is "IMG_2041.png", which says nothing about '
          'the picture.',
      builder: (_) => const BadFilenameLabel(),
    ),
  ],
);
