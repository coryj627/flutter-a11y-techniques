import '../../catalog/technique.dart';
import 'examples.dart';

/// S10 Content group replacement. Spec:
/// docs/specs/S10-content-group-replacement.md. Doc: docs/techniques/S10.md.
final s10ContentGroupReplacement = Technique(
  id: 'S10',
  title: 'Content group replacement',
  group: TechniqueGroup.semantics,
  summary:
      'A group of pieces that say little alone, such as a rating drawn as a '
      'bar or as stars beside two numbers, is replaced for assistive '
      'technology by one node whose label says what the group means; every '
      'piece is hidden, the label follows the values, and no control is '
      'hidden with them.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(),
    AppPlatform.ios: PlatformStatus.applies(),
    AppPlatform.web: PlatformStatus.applies(),
  },
  wcag: const [
    WcagCriterion('1.3.1', 'Info and Relationships', 'info-and-relationships'),
    WcagCriterion('4.1.2', 'Name, Role, Value', 'name-role-value'),
  ],
  sources: const [
    SourceLink(
      'Android View: Content Group Replacement',
      'https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/grouping/ContentGroupReplacement.md',
    ),
    SourceLink(
      'Android Compose: Content Group Replacement',
      'https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/content/ContentGroupReplacement.md',
    ),
    SourceLink(
      'iOS SwiftUI: Accessibility Representation',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/AccessibilityRepresentation.md',
    ),
    SourceLink(
      'Flutter API: Semantics.excludeSemantics',
      'https://api.flutter.dev/flutter/widgets/Semantics/excludeSemantics.html',
    ),
    SourceLink(
      'Flutter API: MergeSemantics',
      'https://api.flutter.dev/flutter/widgets/MergeSemantics-class.html',
    ),
    SourceLink(
      'Flutter API: ExcludeSemantics',
      'https://api.flutter.dev/flutter/widgets/ExcludeSemantics-class.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-exclude-semantics',
      title: 'Rating replaced with excludeSemantics',
      variant: ExampleVariant.material,
      builder: (_) => const GoodExcludeSemantics(),
    ),
    TechniqueExample.good(
      slug: 'good-hidden-pieces',
      title: 'Rating merged, with every piece hidden',
      variant: ExampleVariant.material,
      builder: (_) => const GoodHiddenPieces(),
    ),
    TechniqueExample.good(
      slug: 'good-stars',
      title: 'Star rating replaced',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodStars(),
    ),
    TechniqueExample.bad(
      slug: 'bad-pieces',
      title: 'Star rating left as pieces',
      variant: ExampleVariant.widgets,
      defect: 'The stars are not read, and nothing says what 3.4 and 856 are.',
      builder: (_) => const BadPieces(),
    ),
    TechniqueExample.bad(
      slug: 'bad-merged',
      title: 'Rating merged, not replaced',
      variant: ExampleVariant.material,
      defect: 'The rating is read with a stray 68 from the bar.',
      builder: (_) => const BadMerged(),
    ),
    TechniqueExample.bad(
      slug: 'bad-not-excluded',
      title: 'Label with the pieces left in',
      variant: ExampleVariant.material,
      defect: 'The rating is read twice, with a stray 68.',
      builder: (_) => const BadNotExcluded(),
    ),
    TechniqueExample.bad(
      slug: 'bad-hides-control',
      title: 'Replacement that hides a button',
      variant: ExampleVariant.material,
      defect: 'A screen reader cannot find the Reviews button.',
      builder: (_) => const BadHidesControl(),
    ),
    TechniqueExample.bad(
      slug: 'bad-stale',
      title: 'Replacement with a fixed label',
      variant: ExampleVariant.material,
      defect: 'After a review is added, a screen reader still hears 856.',
      builder: (_) => const BadStale(),
    ),
  ],
);
