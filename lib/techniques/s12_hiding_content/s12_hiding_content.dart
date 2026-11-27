import '../../catalog/technique.dart';
import 'examples.dart';

/// S12 Hiding content from AT. Spec: docs/specs/S12-hiding-content.md.
/// Doc: docs/techniques/S12.md.
final s12HidingContent = Technique(
  id: 'S12',
  title: 'Hiding content from AT',
  group: TechniqueGroup.semantics,
  summary:
      'Text that only decorates, or that repeats what is said beside it, is '
      'hidden from assistive technology with ExcludeSemantics, and content '
      'hidden from sight is hidden from everyone with Visibility. Nothing a '
      'user needs or can operate is hidden: ExcludeSemantics, and the '
      'other ways to hide from a screen reader alone, leave a control in '
      'the keyboard\'s order.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(
      note:
          'A control hidden from the screen reader with ExcludeSemantics or '
          'Opacity keeps keyboard focus, with no node (limitation FL-350): '
          'hide only what has no control in it.',
    ),
    AppPlatform.ios: PlatformStatus.applies(
      note:
          'A control hidden from the screen reader with ExcludeSemantics or '
          'Opacity keeps keyboard focus, with no element (limitation '
          'FL-350): hide only what has no control in it.',
    ),
    AppPlatform.web: PlatformStatus.applies(
      note:
          'A control hidden from the screen reader with ExcludeSemantics or '
          'Opacity keeps keyboard focus while the page\'s focus stays on the '
          'element before it (limitation FL-350): hide only what has no '
          'control in it.',
    ),
  },
  wcag: const [
    WcagCriterion('1.3.1', 'Info and Relationships', 'info-and-relationships'),
    WcagCriterion('4.1.2', 'Name, Role, Value', 'name-role-value'),
  ],
  sources: const [
    SourceLink(
      'iOS SwiftUI: Accessibility Hidden',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/AccessibilityHidden.md',
    ),
    SourceLink(
      'HTML Standard: the hidden attribute',
      'https://html.spec.whatwg.org/multipage/interaction.html#the-hidden-attribute',
    ),
    SourceLink(
      'HTML Standard: the inert attribute',
      'https://html.spec.whatwg.org/multipage/interaction.html#the-inert-attribute',
    ),
    SourceLink(
      'WAI-ARIA 1.2: aria-hidden',
      'https://www.w3.org/TR/wai-aria-1.2/#aria-hidden',
    ),
    SourceLink(
      'Using ARIA: the fourth rule of ARIA use',
      'https://www.w3.org/TR/using-aria/#fourth',
    ),
    SourceLink(
      'Flutter API: ExcludeSemantics',
      'https://api.flutter.dev/flutter/widgets/ExcludeSemantics-class.html',
    ),
    SourceLink(
      'Flutter API: Visibility',
      'https://api.flutter.dev/flutter/widgets/Visibility-class.html',
    ),
    SourceLink(
      'Flutter API: Visibility.maintainFocusability',
      'https://api.flutter.dev/flutter/widgets/Visibility/maintainFocusability.html',
    ),
    SourceLink(
      'Flutter API: Opacity',
      'https://api.flutter.dev/flutter/widgets/Opacity-class.html',
    ),
    SourceLink(
      'Flutter API: Badge',
      'https://api.flutter.dev/flutter/material/Badge-class.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-decoration',
      title: 'Ornaments hidden from AT',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodDecoration(),
    ),
    TechniqueExample.good(
      slug: 'good-badge',
      title: 'Repeated count hidden from AT',
      variant: ExampleVariant.material,
      builder: (_) => const GoodBadge(),
    ),
    TechniqueExample.good(
      slug: 'good-visibility',
      title: 'Panel hidden from everyone',
      variant: ExampleVariant.material,
      builder: (_) => const GoodVisibility(),
    ),
    TechniqueExample.bad(
      slug: 'bad-decoration-read',
      title: 'Ornaments read aloud',
      variant: ExampleVariant.widgets,
      defect: 'A screen reader stops on each ornament and reads it.',
      builder: (_) => const BadDecorationRead(),
    ),
    TechniqueExample.bad(
      slug: 'bad-hidden-control',
      title: 'Button hidden with an ornament',
      variant: ExampleVariant.material,
      defect:
          'A screen reader cannot find the Share button; the keyboard '
          'still reaches it.',
      builder: (_) => const BadHiddenControl(),
    ),
    TechniqueExample.bad(
      slug: 'bad-opacity',
      title: 'Panel hidden by opacity',
      variant: ExampleVariant.material,
      defect:
          'While the panel is hidden, the keyboard still reaches its '
          'button, which no screen reader can find.',
      builder: (_) => const BadOpacity(),
    ),
    TechniqueExample.bad(
      slug: 'bad-maintain',
      title: 'Panel hidden only from sight',
      variant: ExampleVariant.material,
      defect:
          'While the panel is hidden, a screen reader still reads it and '
          'the keyboard still reaches its button.',
      builder: (_) => const BadMaintain(),
    ),
  ],
);
