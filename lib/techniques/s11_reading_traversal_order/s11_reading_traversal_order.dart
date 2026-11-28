import '../../catalog/technique.dart';
import 'examples.dart';

/// S11 Reading and traversal order. Spec:
/// docs/specs/S11-reading-traversal-order.md. Doc: docs/techniques/S11.md.
final s11ReadingTraversalOrder = Technique(
  id: 'S11',
  title: 'Reading and traversal order',
  group: TechniqueGroup.semantics,
  summary:
      'A screen reader moves through content in an order that keeps its '
      'meaning, and keyboard focus reaches the controls in the same order: '
      'side-by-side columns are kept together, or every part is given its '
      'place.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(),
    AppPlatform.ios: PlatformStatus.applies(),
    AppPlatform.web: PlatformStatus.applies(),
  },
  wcag: const [
    WcagCriterion('1.3.2', 'Meaningful Sequence', 'meaningful-sequence'),
    WcagCriterion('2.4.3', 'Focus Order', 'focus-order'),
  ],
  sources: const [
    SourceLink(
      'iOS SwiftUI: Reading Order',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/ReadingOrder.md',
    ),
    SourceLink(
      'iOS SwiftUI: Accessibility Sort Priority',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/AccessibilitySortPriority.md',
    ),
    SourceLink(
      'Android View: Accessibility Reading Order',
      'https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/grouping/AccessibilityReadingOrder.md',
    ),
    SourceLink(
      'Android Compose: Accessibility Traversal Order',
      'https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/content/AccessibilityTraversalOrder.md',
    ),
    SourceLink(
      'Understanding 1.3.2 Meaningful Sequence',
      'https://www.w3.org/WAI/WCAG22/Understanding/meaningful-sequence.html',
    ),
    SourceLink(
      'Understanding 2.4.3 Focus Order',
      'https://www.w3.org/WAI/WCAG22/Understanding/focus-order.html',
    ),
    SourceLink(
      'Flutter API: Semantics.container',
      'https://api.flutter.dev/flutter/widgets/Semantics/container.html',
    ),
    SourceLink(
      'Flutter API: Semantics.explicitChildNodes',
      'https://api.flutter.dev/flutter/widgets/Semantics/explicitChildNodes.html',
    ),
    SourceLink(
      'Flutter API: OrdinalSortKey',
      'https://api.flutter.dev/flutter/semantics/OrdinalSortKey-class.html',
    ),
    SourceLink(
      'Flutter API: FocusTraversalGroup',
      'https://api.flutter.dev/flutter/widgets/FocusTraversalGroup-class.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-columns',
      title: 'Two columns, each kept together',
      variant: ExampleVariant.material,
      builder: (_) => const GoodColumns(),
    ),
    TechniqueExample.good(
      slug: 'good-sort-keys',
      title: 'Columns laid out row by row, given an order',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodSortKeys(),
    ),
    TechniqueExample.bad(
      slug: 'bad-columns-mixed',
      title: 'Two columns read row by row',
      variant: ExampleVariant.material,
      defect: 'A screen reader reads across the two columns, mixing the route with what to bring.',
      builder: (_) => const BadColumnsMixed(),
    ),
    TechniqueExample.bad(
      slug: 'bad-key-missing',
      title: 'One part with no sort key',
      variant: ExampleVariant.widgets,
      defect: 'The "Bring" title has no sort key, so a screen reader reads it before the route.',
      builder: (_) => const BadKeyMissing(),
    ),
  ],
);
