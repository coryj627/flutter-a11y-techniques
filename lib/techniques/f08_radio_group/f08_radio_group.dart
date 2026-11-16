import '../../catalog/technique.dart';
import 'examples.dart';

/// F08 Radio group.
/// Spec: docs/specs/F08-radio-group.md.
/// Doc: docs/techniques/F08.md.
final f08RadioGroup = Technique(
  id: 'F08',
  title: 'Radio group',
  group: TechniqueGroup.forms,
  summary:
      'Radio buttons offer one choice from several. Each button and its '
      'label are one control that says whether it is the one chosen, and '
      'the buttons are a group named by the question they answer.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(
      note:
          'TalkBack 17 says "checked" for the chosen radio button and no '
          'state for the others (limitation FL-045).',
    ),
    AppPlatform.ios: PlatformStatus.limitation(
      'iOS has no radio button: Flutter exposes one as a button that is '
      'selected or not, and VoiceOver never says "radio button" '
      '(limitation FL-047). There is no workaround.',
    ),
    AppPlatform.web: PlatformStatus.applies(),
  },
  wcag: const [
    WcagCriterion('1.3.1', 'Info and Relationships', 'info-and-relationships'),
    WcagCriterion('4.1.2', 'Name, Role, Value', 'name-role-value'),
  ],
  sources: const [
    SourceLink(
      'iOS SwiftUI: Radio Buttons',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/RadioButtons.md',
    ),
    SourceLink(
      'Android Compose: RadioButton Groups',
      'https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/components/RadioButtonGroups.md',
    ),
    SourceLink(
      'ARIA APG: Radio Group pattern',
      'https://www.w3.org/WAI/ARIA/apg/patterns/radio/',
    ),
    SourceLink(
      'MDN: <input type="radio">',
      'https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/input/radio',
    ),
    SourceLink(
      'MDN: <fieldset>',
      'https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/fieldset',
    ),
    SourceLink(
      'Flutter API: RadioGroup',
      'https://api.flutter.dev/flutter/widgets/RadioGroup-class.html',
    ),
    SourceLink(
      'Flutter API: RadioListTile',
      'https://api.flutter.dev/flutter/material/RadioListTile-class.html',
    ),
    SourceLink(
      'Flutter API: RawRadio',
      'https://api.flutter.dev/flutter/widgets/RawRadio-class.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-group',
      title: 'Radio group with a label',
      variant: ExampleVariant.material,
      builder: (_) => const GoodGroup(),
    ),
    TechniqueExample.good(
      slug: 'good-cupertino',
      title: 'Cupertino radio buttons merged with their text',
      variant: ExampleVariant.cupertino,
      builder: (_) => const GoodCupertino(),
    ),
    TechniqueExample.good(
      slug: 'good-custom',
      title: 'Custom radio buttons on RawRadio',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodCustom(),
    ),
    TechniqueExample.good(
      slug: 'good-context',
      title: 'Short answers whose names carry the question',
      variant: ExampleVariant.material,
      builder: (_) => const GoodContext(),
    ),
    TechniqueExample.bad(
      slug: 'bad-unlabelled',
      title: 'Radio buttons with text beside them, not joined',
      variant: ExampleVariant.material,
      defect: 'The radio buttons have no names: a screen reader reads three unnamed radio buttons. A tap on the text does nothing.',
      builder: (_) => const BadUnlabelled(),
    ),
    TechniqueExample.bad(
      slug: 'bad-group-unlabelled',
      title: 'Radio group with no label',
      variant: ExampleVariant.material,
      defect: 'The question "Delivery speed" is plain text above the buttons. The group has no name.',
      builder: (_) => const BadGroupUnlabelled(),
    ),
    TechniqueExample.bad(
      slug: 'bad-no-state',
      title: 'Custom radio buttons exposed as buttons',
      variant: ExampleVariant.widgets,
      defect: 'A screen reader says "button" for each option and never says which one is chosen.',
      builder: (_) => const BadNoState(),
    ),
    TechniqueExample.bad(
      slug: 'bad-checkbox-role',
      title: 'Custom radio buttons exposed as checkboxes',
      variant: ExampleVariant.widgets,
      defect: 'Each option is read as a checkbox, which says that more than one can be chosen. Choosing one silently clears another.',
      builder: (_) => const BadCheckboxRole(),
    ),
    TechniqueExample.bad(
      slug: 'bad-checked-only',
      title: 'Custom radio buttons with no selected state',
      variant: ExampleVariant.widgets,
      defect: 'On iOS VoiceOver reads each option as a button and never says which one is chosen. Android and the web read them correctly.',
      builder: (_) => const BadCheckedOnly(),
    ),
  ],
);
