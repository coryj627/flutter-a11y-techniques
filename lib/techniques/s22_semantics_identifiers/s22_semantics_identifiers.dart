import '../../catalog/technique.dart';
import 'examples.dart';

/// S22 Semantics identifiers for testing.
/// Spec: docs/specs/S22-semantics-identifiers.md.
/// Doc: docs/techniques/S22.md.
final s22SemanticsIdentifiers = Technique(
  id: 'S22',
  title: 'Semantics identifiers for testing',
  group: TechniqueGroup.semantics,
  summary:
      'An identifier lets a UI test find a control without depending on its '
      'text. It is not read by a screen reader, so it never stands in for a '
      'name, and adding one must not change what the control exposes.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(),
    AppPlatform.ios: PlatformStatus.applies(),
    AppPlatform.web: PlatformStatus.applies(),
  },
  wcag: const [],
  sources: const [
    SourceLink(
      'iOS SwiftUI: Accessibility Identifier',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/AccessibilityIdentifier.md',
    ),
    SourceLink(
      'Apple: accessibilityIdentifier(_:)',
      'https://developer.apple.com/documentation/swiftui/view/accessibilityidentifier(_:)',
    ),
    SourceLink(
      'Flutter API: SemanticsProperties.identifier',
      'https://api.flutter.dev/flutter/semantics/SemanticsProperties/identifier.html',
    ),
    SourceLink(
      'Flutter API: MergeSemantics',
      'https://api.flutter.dev/flutter/widgets/MergeSemantics-class.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-merged',
      title: 'Identifier merged into a Material button',
      variant: ExampleVariant.material,
      builder: (_) => const GoodMerged(),
    ),
    TechniqueExample.good(
      slug: 'good-cupertino',
      title: 'Identifier on a Cupertino button',
      variant: ExampleVariant.cupertino,
      customSolution:
          'An Actions built by hand round the CupertinoButton so that Enter '
          'works on the web (FL-002).',
      builder: (_) => const GoodCupertino(),
    ),
    TechniqueExample.good(
      slug: 'good-custom',
      title: 'Identifier on a custom button',
      variant: ExampleVariant.widgets,
      customSolution:
          'A button drawn by hand: Semantics(button: true, label:, onTap:), '
          'with focus, keys, and a focus ring of its own.',
      builder: (_) => const GoodCustom(),
    ),
    TechniqueExample.good(
      slug: 'good-field',
      title: 'Identifier on a text field',
      variant: ExampleVariant.material,
      builder: (_) => const GoodField(),
    ),
    TechniqueExample.bad(
      slug: 'bad-inside',
      title: 'Identifier inside the button',
      variant: ExampleVariant.material,
      defect: 'On Android and iOS the button loses its name: a screen reader says "Button", then reads "Save draft" as separate text.',
      builder: (_) => const BadInside(),
    ),
    TechniqueExample.bad(
      slug: 'bad-wrapper',
      title: 'Identifier around the button, not merged',
      variant: ExampleVariant.material,
      defect: 'Nothing changes for a screen reader user. A test that finds the identifier gets an element that is not the button.',
      builder: (_) => const BadWrapper(),
    ),
    TechniqueExample.bad(
      slug: 'bad-id-as-name',
      title: 'Identifier and no name',
      variant: ExampleVariant.material,
      defect: 'The icon button has no name. The identifier is not read: a screen reader says "Button" and gives no name.',
      builder: (_) => const BadIdAsName(),
    ),
    TechniqueExample.bad(
      slug: 'bad-duplicate',
      title: 'Two controls with one identifier',
      variant: ExampleVariant.material,
      defect: 'Nothing changes for a screen reader user. A test that asks for the identifier cannot tell the two buttons apart.',
      builder: (_) => const BadDuplicate(),
    ),
  ],
);
