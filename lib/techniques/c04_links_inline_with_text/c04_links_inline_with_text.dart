import '../../catalog/technique.dart';
import 'examples.dart';

/// C04 Links inline with text. Spec: docs/specs/C04-links-inline-with-text.md.
/// Doc: docs/techniques/C04.md.
final c04LinksInlineWithText = Technique(
  id: 'C04',
  title: 'Links inline with text',
  group: TechniqueGroup.components,
  summary:
      'Each link in a sentence is a stop of its own with the link role and '
      'a name that says where it goes, is read in its place, is reached and '
      'followed by touch, keyboard, and screen reader, and is told from the '
      'words round it by more than colour.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(),
    AppPlatform.ios: PlatformStatus.applies(),
    AppPlatform.web: PlatformStatus.applies(),
  },
  wcag: const [
    WcagCriterion(
      '2.4.4',
      'Link Purpose (In Context)',
      'link-purpose-in-context',
    ),
    WcagCriterion('1.4.1', 'Use of Color', 'use-of-color'),
  ],
  sources: const [
    SourceLink(
      'iOS SwiftUI: Links',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/Links.md',
    ),
    SourceLink(
      'Android View: Links Inline with Text',
      'https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/componenttypes/LinksInlineWithText.md',
    ),
    SourceLink(
      'Android Compose: Links Inline with Text',
      'https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/components/LinksInlineWithText.md',
    ),
    SourceLink(
      'ARIA Authoring Practices Guide: Link pattern',
      'https://www.w3.org/WAI/ARIA/apg/patterns/link/',
    ),
    SourceLink(
      'MDN: The a element',
      'https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/a',
    ),
    SourceLink(
      'WCAG technique G53: link text with the text of its sentence',
      'https://www.w3.org/WAI/WCAG22/Techniques/general/G53',
    ),
    SourceLink(
      'WCAG technique G183: a 3:1 contrast with the text round a link',
      'https://www.w3.org/WAI/WCAG22/Techniques/general/G183',
    ),
    SourceLink(
      'WCAG failure F73: links not visually evident without colour vision',
      'https://www.w3.org/WAI/WCAG22/Techniques/failures/F73',
    ),
    SourceLink(
      'Flutter API: WidgetSpan',
      'https://api.flutter.dev/flutter/widgets/WidgetSpan-class.html',
    ),
    SourceLink(
      'Flutter API: TextSpan.semanticsIdentifier',
      'https://api.flutter.dev/flutter/painting/TextSpan/semanticsIdentifier.html',
    ),
    SourceLink(
      'Flutter API: OrdinalSortKey',
      'https://api.flutter.dev/flutter/semantics/OrdinalSortKey-class.html',
    ),
    SourceLink(
      'Flutter API: MediaQuery.withNoTextScaling',
      'https://api.flutter.dev/flutter/widgets/MediaQuery/MediaQuery.withNoTextScaling.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-material',
      title: 'Material links in a sentence',
      variant: ExampleVariant.material,
      customSolution:
          'An inline link built by hand: Semantics(link: true, linkUrl:) '
          'round an InkWell in a WidgetSpan, with key bindings, a focus ring, '
          'and sort keys; a TextSpan link takes no keyboard focus (FL-240).',
      builder: (_) => const GoodMaterial(),
    ),
    TechniqueExample.good(
      slug: 'good-cupertino',
      title: 'Cupertino links in a sentence',
      variant: ExampleVariant.cupertino,
      customSolution:
          'An inline link built by hand from FocusableActionDetector, '
          'Semantics, and a GestureDetector in a WidgetSpan, in Cupertino\'s '
          'blue; Flutter has no link widget (FL-221) and a TextSpan link '
          'takes no focus (FL-240).',
      builder: (_) => const GoodCupertino(),
    ),
    TechniqueExample.good(
      slug: 'good-custom',
      title: 'Widgets-layer links in a sentence',
      variant: ExampleVariant.widgets,
      customSolution:
          'An inline link built by hand from FocusableActionDetector, '
          'Semantics, and a GestureDetector in a WidgetSpan; a TextSpan link '
          'takes no keyboard focus (FL-240).',
      builder: (_) => const GoodCustom(),
    ),
    TechniqueExample.bad(
      slug: 'bad-text-span',
      title: 'Link in a text span',
      variant: ExampleVariant.widgets,
      defect: 'A keyboard cannot reach the link.',
      builder: (_) => const BadTextSpan(),
    ),
    TechniqueExample.bad(
      slug: 'bad-out-of-order',
      title: 'Links read after their sentence',
      variant: ExampleVariant.material,
      defect: 'A screen reader reads the sentence without its links, then the links.',
      builder: (_) => const BadOutOfOrder(),
    ),
    TechniqueExample.bad(
      slug: 'bad-colour-only',
      title: 'Links shown by colour alone',
      variant: ExampleVariant.material,
      defect: 'Only a colour close to the text tells the links apart.',
      builder: (_) => const BadColourOnly(),
    ),
    TechniqueExample.bad(
      slug: 'bad-merged',
      title: 'Sentence and links as one element',
      variant: ExampleVariant.material,
      defect: 'A screen reader finds the sentence as one link, and not the second link.',
      builder: (_) => const BadMerged(),
    ),
  ],
);
