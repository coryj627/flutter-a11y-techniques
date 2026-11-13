import '../../catalog/technique.dart';
import 'examples.dart';

/// F01 Text fields and labels. Spec: docs/specs/F01-text-fields.md.
/// Doc: docs/techniques/F01.md.
final f01TextFields = Technique(
  id: 'F01',
  title: 'Text fields and labels',
  group: TechniqueGroup.forms,
  summary:
      'Every text field has a visible label that stays visible while the '
      'field is filled in, and that label is the name assistive technology '
      'announces for the field.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(),
    AppPlatform.ios: PlatformStatus.applies(),
    AppPlatform.web: PlatformStatus.applies(),
  },
  wcag: const [
    WcagCriterion('1.3.1', 'Info and Relationships', 'info-and-relationships'),
    WcagCriterion('2.5.3', 'Label in Name', 'label-in-name'),
    WcagCriterion('3.3.2', 'Labels or Instructions', 'labels-or-instructions'),
    WcagCriterion('4.1.2', 'Name, Role, Value', 'name-role-value'),
  ],
  sources: const [
    SourceLink(
      'CVS Health iOS SwiftUI: Text Fields',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/TextFields.md',
    ),
    SourceLink(
      'CVS Health Android View: Input Field Labels',
      'https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/basics/InputFieldLabels.md',
    ),
    SourceLink(
      'CVS Health Android Compose: TextField Controls',
      'https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/components/TextFieldControls.md',
    ),
    SourceLink(
      'MDN: The label element',
      'https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/label',
    ),
    SourceLink(
      'MDN: The input element',
      'https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/input',
    ),
    SourceLink(
      'MDN: The textarea element',
      'https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/textarea',
    ),
    SourceLink(
      'Flutter API: InputDecoration.labelText',
      'https://api.flutter.dev/flutter/material/InputDecoration/labelText.html',
    ),
    SourceLink(
      'Flutter API: Semantics',
      'https://api.flutter.dev/flutter/widgets/Semantics-class.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-label',
      title: 'Fields with a label',
      variant: ExampleVariant.material,
      builder: (_) => const GoodLabelledFields(),
    ),
    TechniqueExample.good(
      slug: 'good-label-above',
      title: 'Label above the field',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodLabelAbove(),
    ),
    TechniqueExample.good(
      slug: 'good-cupertino',
      title: 'Cupertino field with a label',
      variant: ExampleVariant.cupertino,
      builder: (_) => const GoodCupertinoField(),
    ),
    TechniqueExample.bad(
      slug: 'bad-placeholder-only',
      title: 'Placeholder used as the label',
      variant: ExampleVariant.material,
      defect:
          'The only label is placeholder text, which disappears when '
          'something is typed.',
      builder: (_) => const BadPlaceholderOnly(),
    ),
    TechniqueExample.bad(
      slug: 'bad-unassociated-label',
      title: 'Label that is only nearby text',
      variant: ExampleVariant.material,
      defect:
          'The visible label is separate text that is not tied to the field, '
          'so the field has no name.',
      builder: (_) => const BadUnassociatedLabel(),
    ),
    TechniqueExample.bad(
      slug: 'bad-no-label',
      title: 'Field with only an icon',
      variant: ExampleVariant.material,
      defect: 'The field has no label at all; an icon is the only clue.',
      builder: (_) => const BadNoLabel(),
    ),
    TechniqueExample.bad(
      slug: 'bad-name-mismatch',
      title: 'Name does not match the visible label',
      variant: ExampleVariant.widgets,
      defect:
          'The visible label is "Email" but the accessible name is '
          '"Contact address".',
      builder: (_) => const BadFieldNameMismatch(),
    ),
    TechniqueExample.bad(
      slug: 'bad-cupertino-placeholder',
      title: 'Cupertino field with only a placeholder',
      variant: ExampleVariant.cupertino,
      defect:
          'The placeholder is the only label, and it disappears when '
          'something is typed.',
      builder: (_) => const BadCupertinoPlaceholder(),
    ),
    TechniqueExample.bad(
      slug: 'bad-cupertino-prefix',
      title: 'Cupertino form row prefix as the label',
      variant: ExampleVariant.cupertino,
      defect:
          'The row prefix looks like the label but is separate text; the '
          'field itself has no name.',
      builder: (_) => const BadCupertinoPrefix(),
    ),
  ],
);
