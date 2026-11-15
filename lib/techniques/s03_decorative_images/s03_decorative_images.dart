import '../../catalog/technique.dart';
import 'examples.dart';

/// S03 Decorative images. Spec: docs/specs/S03-decorative-images.md.
/// Doc: docs/techniques/S03.md.
final s03DecorativeImages = Technique(
  id: 'S03',
  title: 'Decorative images',
  group: TechniqueGroup.semantics,
  summary:
      'An image or icon that adds nothing to the text around it is kept out '
      'of the semantics tree, so a screen reader does not stop on it.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(),
    AppPlatform.ios: PlatformStatus.applies(),
    AppPlatform.web: PlatformStatus.applies(),
  },
  wcag: const [WcagCriterion('1.1.1', 'Non-text Content', 'non-text-content')],
  sources: const [
    SourceLink(
      'CVS Health iOS SwiftUI: Decorative Images',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/DecorativeImages.md',
    ),
    SourceLink(
      'CVS Health iOS SwiftUI: Images',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/Images.md',
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
      'W3C WAI Images Tutorial: Decorative Images',
      'https://www.w3.org/WAI/tutorials/images/decorative/',
    ),
    SourceLink(
      'WCAG failure F38: decorative images that cannot be ignored',
      'https://www.w3.org/WAI/WCAG22/Techniques/failures/F38',
    ),
    SourceLink(
      'Flutter API: Image.excludeFromSemantics',
      'https://api.flutter.dev/flutter/widgets/Image/excludeFromSemantics.html',
    ),
    SourceLink(
      'Flutter API: Icon.semanticLabel',
      'https://api.flutter.dev/flutter/widgets/Icon/semanticLabel.html',
    ),
    SourceLink(
      'Flutter API: DecorationImage',
      'https://api.flutter.dev/flutter/painting/DecorationImage-class.html',
    ),
    SourceLink(
      'Flutter API: ExcludeSemantics',
      'https://api.flutter.dev/flutter/widgets/ExcludeSemantics-class.html',
    ),
    SourceLink(
      'Flutter API: MergeSemantics',
      'https://api.flutter.dev/flutter/widgets/MergeSemantics-class.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-image-excluded',
      title: 'Decorative image excluded',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodImageExcluded(),
    ),
    TechniqueExample.good(
      slug: 'good-icon-no-label',
      title: 'Icons that repeat the text beside them',
      variant: ExampleVariant.material,
      builder: (_) => const GoodIconNoLabel(),
    ),
    TechniqueExample.good(
      slug: 'good-background-image',
      title: 'Decoration painted as a background',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodBackgroundImage(),
    ),
    TechniqueExample.good(
      slug: 'good-exclude-semantics',
      title: 'Avatar hidden with ExcludeSemantics',
      variant: ExampleVariant.material,
      builder: (_) => const GoodExcludeSemantics(),
    ),
    TechniqueExample.good(
      slug: 'good-merged-row',
      title: 'Decorative picture excluded from a merged row',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodMergedRow(),
    ),
    TechniqueExample.bad(
      slug: 'bad-not-excluded',
      title: 'Decorative image left in the tree',
      variant: ExampleVariant.widgets,
      defect: 'The decorative banner is not excluded, so it is exposed as an image with no name.',
      builder: (_) => const BadNotExcluded(),
    ),
    TechniqueExample.bad(
      slug: 'bad-empty-label',
      title: 'Empty label used to hide an image',
      variant: ExampleVariant.widgets,
      defect: 'The banner has an empty label, which does not hide it: it is exposed as an image with no name.',
      builder: (_) => const BadEmptyLabel(),
    ),
    TechniqueExample.bad(
      slug: 'bad-redundant-label',
      title: 'Decorative icons that repeat the text',
      variant: ExampleVariant.material,
      defect: 'Each icon has a label that repeats the word beside it, so every word is read twice.',
      builder: (_) => const BadRedundantLabel(),
    ),
    TechniqueExample.bad(
      slug: 'bad-merged-image',
      title: 'Decorative picture merged into a row',
      variant: ExampleVariant.widgets,
      defect: 'The picture in the merged row is not excluded, so the text of the row is announced as an image.',
      builder: (_) => const BadMergedImage(),
    ),
  ],
);
