import '../../catalog/technique.dart';
import 'examples.dart';

/// F07 Checkbox.
/// Spec: docs/specs/F07-checkbox.md.
/// Doc: docs/techniques/F07.md.
final f07Checkbox = Technique(
  id: 'F07',
  title: 'Checkbox',
  group: TechniqueGroup.forms,
  summary:
      'A checkbox and its label are one control with a name, the checkbox '
      'role, and a state that is checked, not checked, or mixed. Checkboxes '
      'that answer one question are grouped under that question.',
  platforms: const {
    AppPlatform.android: PlatformStatus.limitation(
      'Checked and not checked are exposed correctly. A mixed checkbox is '
      'exposed as partial on Android 16 and later and as not checked before '
      'that, and TalkBack says no state for it on either (limitation '
      'FL-044). TalkBack also says no state for a checkbox that is not '
      'checked (limitation FL-045). There is no workaround.',
    ),
    AppPlatform.ios: PlatformStatus.limitation(
      'iOS has no checkbox: Flutter exposes one as a switch, read "on" or '
      '"off" (limitation FL-035). A mixed checkbox is read as "off" '
      '(limitation FL-044). There is no workaround for either.',
    ),
    AppPlatform.web: PlatformStatus.limitation(
      'A mixed checkbox is exposed as not checked: aria-checked is "false" '
      'where it should be "mixed" (limitation FL-044). There is no '
      'workaround. Checked and not checked are correct.',
    ),
  },
  wcag: const [
    WcagCriterion('1.3.1', 'Info and Relationships', 'info-and-relationships'),
    WcagCriterion('4.1.2', 'Name, Role, Value', 'name-role-value'),
  ],
  sources: const [
    SourceLink(
      'iOS SwiftUI: Checkboxes',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/Checkboxes.md',
    ),
    SourceLink(
      'Android Compose: Checkbox Controls',
      'https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/components/CheckboxControls.md',
    ),
    SourceLink(
      'ARIA APG: Checkbox pattern',
      'https://www.w3.org/WAI/ARIA/apg/patterns/checkbox/',
    ),
    SourceLink(
      'MDN: <input type="checkbox">',
      'https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/input/checkbox',
    ),
    SourceLink(
      'Flutter API: CheckboxListTile',
      'https://api.flutter.dev/flutter/material/CheckboxListTile-class.html',
    ),
    SourceLink(
      'Flutter API: SemanticsProperties.checked',
      'https://api.flutter.dev/flutter/semantics/SemanticsProperties/checked.html',
    ),
    SourceLink(
      'Flutter API: SemanticsProperties.mixed',
      'https://api.flutter.dev/flutter/semantics/SemanticsProperties/mixed.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-tile',
      title: 'Checkbox and label as one control',
      variant: ExampleVariant.material,
      builder: (_) => const GoodTile(),
    ),
    TechniqueExample.good(
      slug: 'good-cupertino',
      title: 'Cupertino checkbox merged with its text',
      variant: ExampleVariant.cupertino,
      builder: (_) => const GoodCupertino(),
    ),
    TechniqueExample.good(
      slug: 'good-custom',
      title: 'Custom checkbox with a checked state',
      variant: ExampleVariant.widgets,
      customSolution:
          'A checkbox drawn by hand, with its role, state, focus, keys, and '
          'focus ring built from Semantics and FocusableActionDetector.',
      builder: (_) => const GoodCustom(),
    ),
    TechniqueExample.good(
      slug: 'good-mixed',
      title: 'Select all with a mixed state',
      variant: ExampleVariant.material,
      builder: (_) => const GoodMixed(),
    ),
    TechniqueExample.good(
      slug: 'good-group',
      title: 'Group of checkboxes with a label',
      variant: ExampleVariant.material,
      builder: (_) => const GoodGroup(),
    ),
    TechniqueExample.bad(
      slug: 'bad-unlabelled',
      title: 'Checkbox with text beside it, not joined',
      variant: ExampleVariant.material,
      defect: 'The checkbox has no name: a screen reader says "checkbox, not checked" and reads the text as a separate element. A tap on the text does nothing.',
      builder: (_) => const BadUnlabelled(),
    ),
    TechniqueExample.bad(
      slug: 'bad-no-state',
      title: 'Custom checkbox exposed as a button',
      variant: ExampleVariant.widgets,
      defect: 'A screen reader says "button" and never says whether the box is checked.',
      builder: (_) => const BadNoState(),
    ),
    TechniqueExample.bad(
      slug: 'bad-mixed-as-unchecked',
      title: 'Select all with two states',
      variant: ExampleVariant.material,
      defect: '"Select all" is read as not checked while one of the two boxes under it is checked.',
      builder: (_) => const BadMixedAsUnchecked(),
    ),
    TechniqueExample.bad(
      slug: 'bad-group-unlabelled',
      title: 'Group of checkboxes with no label',
      variant: ExampleVariant.material,
      defect: 'The question "Contact me by" is plain text above the boxes. Nothing ties it to them.',
      builder: (_) => const BadGroupUnlabelled(),
    ),
  ],
);
