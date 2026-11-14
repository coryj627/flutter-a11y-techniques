import '../../catalog/technique.dart';
import 'examples.dart';

/// S01 Accessible names. Spec: docs/specs/S01-accessible-names.md.
/// Doc: docs/techniques/S01.md.
final s01AccessibleNames = Technique(
  id: 'S01',
  title: 'Accessible names',
  group: TechniqueGroup.semantics,
  summary:
      'Every control has a name that assistive technology can read. The name '
      'is the visible text where there is some, says what the control is for, '
      'is different from the names of other controls, and does not repeat '
      'the role.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(),
    AppPlatform.ios: PlatformStatus.applies(),
    AppPlatform.web: PlatformStatus.applies(
      note:
          'A slider cannot be given a name on web (limitation FL-028). The '
          'other controls here can.',
    ),
  },
  wcag: const [
    WcagCriterion('1.3.1', 'Info and Relationships', 'info-and-relationships'),
    WcagCriterion('2.4.6', 'Headings and Labels', 'headings-and-labels'),
    WcagCriterion('2.5.3', 'Label in Name', 'label-in-name'),
    WcagCriterion('4.1.2', 'Name, Role, Value', 'name-role-value'),
  ],
  sources: const [
    SourceLink(
      'CVS Health iOS SwiftUI: Accessibility Label',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/AccessibilityLabel.md',
    ),
    SourceLink(
      'CVS Health iOS SwiftUI: Meaningful Accessible Names',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/MeaningfulAccessibleNames.md',
    ),
    SourceLink(
      'CVS Health Android Compose: Interactive Control Labels',
      'https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/interactions/InteractiveControlLabels.md',
    ),
    SourceLink(
      'ARIA Authoring Practices Guide: Providing Accessible Names and '
          'Descriptions',
      'https://www.w3.org/WAI/ARIA/apg/practices/names-and-descriptions/',
    ),
    SourceLink(
      'MDN: The label element',
      'https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/label',
    ),
    SourceLink(
      'Flutter API: MergeSemantics',
      'https://api.flutter.dev/flutter/widgets/MergeSemantics-class.html',
    ),
    SourceLink(
      'Flutter API: CheckboxListTile',
      'https://api.flutter.dev/flutter/material/CheckboxListTile-class.html',
    ),
    SourceLink(
      'Flutter API: SwitchListTile',
      'https://api.flutter.dev/flutter/material/SwitchListTile-class.html',
    ),
    SourceLink(
      'Flutter API: Text.semanticsLabel',
      'https://api.flutter.dev/flutter/widgets/Text/semanticsLabel.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-visible-label',
      title: 'List tile controls named by their text',
      variant: ExampleVariant.material,
      builder: (_) => const GoodVisibleLabel(),
    ),
    TechniqueExample.good(
      slug: 'good-merged-label',
      title: 'Control merged with the text beside it',
      variant: ExampleVariant.material,
      builder: (_) => const GoodMergedLabel(),
    ),
    TechniqueExample.good(
      slug: 'good-specific-names',
      title: 'Repeated controls with specific names',
      variant: ExampleVariant.material,
      builder: (_) => const GoodSpecificNames(),
    ),
    TechniqueExample.good(
      slug: 'good-cupertino',
      title: 'Cupertino switch merged with its text',
      variant: ExampleVariant.cupertino,
      builder: (_) => const GoodCupertinoLabel(),
    ),
    TechniqueExample.bad(
      slug: 'bad-unassociated-label',
      title: 'Text beside a control but not joined to it',
      variant: ExampleVariant.material,
      defect: 'The checkbox has no accessible name.',
      builder: (_) => const BadUnassociatedLabel(),
    ),
    TechniqueExample.bad(
      slug: 'bad-duplicate-names',
      title: 'Repeated controls with the same name',
      variant: ExampleVariant.material,
      defect: 'Two switches are both named "Order updates".',
      builder: (_) => const BadDuplicateNames(),
    ),
    TechniqueExample.bad(
      slug: 'bad-role-in-name',
      title: 'Role repeated in the name',
      variant: ExampleVariant.material,
      defect: 'The name is "Dark mode switch", so the role is announced twice.',
      builder: (_) => const BadRoleInName(),
    ),
    TechniqueExample.bad(
      slug: 'bad-slider-name-web',
      title: 'Slider whose name is lost on web',
      variant: ExampleVariant.material,
      defect:
          'Flutter limitation: on web the slider has no accessible name, '
          'although it is joined to its visible text. On Android and iOS it '
          'is named "Volume".',
      builder: (_) => const BadSliderNameWeb(),
    ),
  ],
);
