import '../../catalog/technique.dart';
import 'examples.dart';

/// I02 Keyboard focus order.
/// Spec: docs/specs/I02-focus-order.md.
/// Doc: docs/techniques/I02.md.
final i02FocusOrder = Technique(
  id: 'I02',
  title: 'Keyboard focus order',
  group: TechniqueGroup.interaction,
  summary:
      'Tab and Shift+Tab move through the controls in an order that keeps '
      'their meaning: down one column before the next, each list before '
      'the action that ends it.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(),
    AppPlatform.ios: PlatformStatus.applies(),
    AppPlatform.web: PlatformStatus.applies(),
  },
  wcag: const [
    WcagCriterion('2.4.3', 'Focus Order', 'focus-order'),
    WcagCriterion('2.1.1', 'Keyboard', 'keyboard'),
  ],
  sources: const [
    SourceLink(
      'Android View: Keyboard and Accessibility Focus Order',
      'https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/grouping/KeyboardAndAccessibilityFocusOrder.md',
    ),
    SourceLink(
      'Android View: Arrow Key Focus Order',
      'https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/grouping/ArrowKeyFocusOrder.md',
    ),
    SourceLink(
      'Android Compose: Keyboard Focus Order',
      'https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/interactions/KeyboardFocusOrder.md',
    ),
    SourceLink(
      'WCAG 2.2: Understanding Focus Order',
      'https://www.w3.org/WAI/WCAG22/Understanding/focus-order.html',
    ),
    SourceLink(
      'MDN: tabindex',
      'https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Global_attributes/tabindex',
    ),
    SourceLink(
      'Flutter: Understanding Flutter\'s keyboard focus system',
      'https://docs.flutter.dev/ui/interactivity/focus',
    ),
    SourceLink(
      'Flutter API: FocusTraversalGroup',
      'https://api.flutter.dev/flutter/widgets/FocusTraversalGroup-class.html',
    ),
    SourceLink(
      'Flutter API: OrderedTraversalPolicy',
      'https://api.flutter.dev/flutter/widgets/OrderedTraversalPolicy-class.html',
    ),
    SourceLink(
      'Flutter API: FocusTraversalOrder',
      'https://api.flutter.dev/flutter/widgets/FocusTraversalOrder-class.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-material',
      title: 'A traversal group per column',
      variant: ExampleVariant.material,
      builder: (_) => const GoodMaterial(),
    ),
    TechniqueExample.good(
      slug: 'good-cupertino',
      title: 'Cupertino checkboxes, a traversal group per column',
      variant: ExampleVariant.cupertino,
      builder: (_) => const GoodCupertino(),
    ),
    TechniqueExample.good(
      slug: 'good-ordered',
      title: 'Order given by number where no widget holds a column',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodOrdered(),
    ),
    TechniqueExample.bad(
      slug: 'bad-columns-mixed',
      title: 'Two columns with no traversal groups',
      variant: ExampleVariant.material,
      defect:
          'Tab goes back and forth between the two lists, row by row: Map, '
          'then Weather, then Water, so the choices of one list are reached '
          'in among the other\'s.',
      builder: (_) => const BadColumnsMixed(),
    ),
    TechniqueExample.bad(
      slug: 'bad-order-missing',
      title: 'Order given by number, with one number missing',
      variant: ExampleVariant.widgets,
      defect:
          'First aid has no number, so Tab reaches it only after Save plan, '
          'cut off from the rest of its list.',
      builder: (_) => const BadOrderMissing(),
    ),
  ],
);
