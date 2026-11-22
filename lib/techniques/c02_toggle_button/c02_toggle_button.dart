import '../../catalog/technique.dart';
import 'examples.dart';

/// C02 Toggle button.
/// Spec: docs/specs/C02-toggle-button.md.
/// Doc: docs/techniques/C02.md.
final c02ToggleButton = Technique(
  id: 'C02',
  title: 'Toggle button',
  group: TechniqueGroup.components,
  summary:
      'A button that stays pressed or not pressed exposes its name, a role, '
      'and whether it is on, in both states, and its name does not change '
      'when its state does.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(
      note:
          'Flutter has no pressed state: a toggle button is given the switch '
          'role with an on or off state (limitation FL-200). An icon '
          'button\'s isSelected alone says nothing while it is off.',
    ),
    AppPlatform.ios: PlatformStatus.applies(
      note:
          'Flutter has no pressed state: a toggle button is given the switch '
          'role with an on or off state (limitation FL-200). One built with '
          'Semantics(toggled:) needs enabled: true as well (limitation '
          'FL-033).',
    ),
    AppPlatform.web: PlatformStatus.applies(
      note:
          'Flutter writes no aria-pressed: a toggle button is given the '
          'switch role with an on or off state (limitation FL-200). An icon '
          'button\'s isSelected is written as aria-current.',
    ),
  },
  wcag: const [WcagCriterion('4.1.2', 'Name, Role, Value', 'name-role-value')],
  sources: const [
    SourceLink(
      'iOS SwiftUI: Buttons',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/Buttons.md',
    ),
    SourceLink(
      'ARIA Authoring Practices Guide: Button pattern',
      'https://www.w3.org/WAI/ARIA/apg/patterns/button/',
    ),
    SourceLink(
      'MDN: aria-pressed',
      'https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Reference/Attributes/aria-pressed',
    ),
    SourceLink(
      'Flutter API: IconButton.isSelected',
      'https://api.flutter.dev/flutter/material/IconButton/isSelected.html',
    ),
    SourceLink(
      'Flutter API: ToggleButtons',
      'https://api.flutter.dev/flutter/material/ToggleButtons-class.html',
    ),
    SourceLink(
      'Flutter API: SemanticsProperties.toggled',
      'https://api.flutter.dev/flutter/semantics/SemanticsProperties/toggled.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-icon-button',
      title: 'Icon button that stays pressed',
      variant: ExampleVariant.material,
      builder: (_) => const GoodIconButton(),
    ),
    TechniqueExample.good(
      slug: 'good-toggle-buttons',
      title: 'Row of toggle buttons',
      variant: ExampleVariant.material,
      builder: (_) => const GoodToggleButtons(),
    ),
    TechniqueExample.good(
      slug: 'good-cupertino',
      title: 'Cupertino button that stays pressed',
      variant: ExampleVariant.cupertino,
      builder: (_) => const GoodCupertino(),
    ),
    TechniqueExample.good(
      slug: 'good-custom',
      title: 'Custom toggle button with an on or off state',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodCustom(),
    ),
    TechniqueExample.bad(
      slug: 'bad-selected-only',
      title: 'Icon button with isSelected alone',
      variant: ExampleVariant.material,
      defect:
          'While off it is read only "Bold, button": nothing says it is a '
          'toggle. On, it is "selected", and on the web "current item", a '
          'state that is not pressed.',
      builder: (_) => const BadSelectedOnly(),
    ),
    TechniqueExample.bad(
      slug: 'bad-no-state',
      title: 'Custom toggle button exposed as a plain button',
      variant: ExampleVariant.widgets,
      defect:
          'A screen reader says "Mute, button" whether it is on or off: only '
          'the drawing changes.',
      builder: (_) => const BadNoState(),
    ),
    TechniqueExample.bad(
      slug: 'bad-label-changes',
      title: 'Toggle button whose name changes with its state',
      variant: ExampleVariant.material,
      defect:
          'The name is "Mute", then "Unmute": it changes every time the state '
          'does, and "Unmute" with "on" can be taken either way.',
      builder: (_) => const BadLabelChanges(),
    ),
  ],
);
