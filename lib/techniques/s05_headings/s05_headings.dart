import '../../catalog/technique.dart';
import 'examples.dart';

/// S05 Headings. Spec: docs/specs/S05-headings.md. Doc: docs/techniques/S05.md.
final s05Headings = Technique(
  id: 'S05',
  title: 'Headings',
  group: TechniqueGroup.semantics,
  summary:
      'Text that works as a heading is exposed to assistive technology as a '
      'heading, with a level that matches its place in the page outline, so '
      'people can understand the structure and move between sections.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(),
    AppPlatform.ios: PlatformStatus.applies(),
    AppPlatform.web: PlatformStatus.applies(),
  },
  wcag: const [
    WcagCriterion('1.3.1', 'Info and Relationships', 'info-and-relationships'),
    WcagCriterion('2.4.6', 'Headings and Labels', 'headings-and-labels'),
  ],
  sources: const [
    SourceLink(
      'CVS Health iOS SwiftUI: Headings',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/Headings.md',
    ),
    SourceLink(
      'CVS Health Android Compose: Heading Semantics',
      'https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/content/HeadingSemantics.md',
    ),
    SourceLink(
      'CVS Health Android View: Heading Semantics',
      'https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/grouping/HeadingSemantics.md',
    ),
    SourceLink(
      'MDN: The HTML section heading elements',
      'https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/Heading_Elements',
    ),
    SourceLink(
      'Flutter API: SemanticsProperties.headingLevel',
      'https://api.flutter.dev/flutter/semantics/SemanticsProperties/headingLevel.html',
    ),
    SourceLink(
      'Flutter API: SemanticsProperties.header',
      'https://api.flutter.dev/flutter/semantics/SemanticsProperties/header.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-levels',
      title: 'Headings with levels',
      variant: ExampleVariant.material,
      builder: (_) => const GoodHeadingLevels(),
    ),
    TechniqueExample.good(
      slug: 'good-cupertino',
      title: 'Cupertino section heading',
      variant: ExampleVariant.cupertino,
      builder: (_) => const GoodCupertinoSectionHeading(),
    ),
    TechniqueExample.bad(
      slug: 'bad-visual-only',
      title: 'Heading by appearance only',
      variant: ExampleVariant.material,
      defect:
          'The text looks like a heading but is not exposed as one, so it '
          'cannot be found by heading navigation.',
      builder: (_) => const BadVisualOnlyHeading(),
    ),
    TechniqueExample.bad(
      slug: 'bad-fake-label',
      title: 'The word "heading" in the name',
      variant: ExampleVariant.material,
      defect:
          'The name is "Profile, heading", but the text is not a heading and '
          'heading navigation cannot find it.',
      builder: (_) => const BadFakeHeadingLabel(),
    ),
    TechniqueExample.bad(
      slug: 'bad-skipped-level',
      title: 'Skipped heading level',
      variant: ExampleVariant.material,
      defect:
          'A level 5 heading follows a level 3 heading; level 4 is skipped.',
      builder: (_) => const BadSkippedLevel(),
    ),
    TechniqueExample.bad(
      slug: 'bad-header-only',
      title: 'Heading with no level',
      variant: ExampleVariant.material,
      defect:
          'Flutter limitation: a heading marked only with header: true is '
          'not a heading on every platform, and has the wrong level on web.',
      builder: (_) => const BadHeaderOnly(),
    ),
    TechniqueExample.bad(
      slug: 'bad-emphasis-heading',
      title: 'Heading used for emphasis',
      variant: ExampleVariant.material,
      defect:
          'A sentence that introduces no section is marked as a heading to '
          'make it stand out.',
      builder: (_) => const BadEmphasisHeading(),
    ),
    TechniqueExample.bad(
      slug: 'bad-cupertino-section-header',
      title: 'Cupertino section header that is not a heading',
      variant: ExampleVariant.cupertino,
      defect:
          'Flutter limitation: the header of a CupertinoListSection looks '
          'like a heading but is not exposed as one.',
      builder: (_) => const BadCupertinoSectionHeader(),
    ),
  ],
);
