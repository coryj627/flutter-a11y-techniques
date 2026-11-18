import '../../catalog/technique.dart';
import 'examples.dart';

/// F02 Input instructions.
/// Spec: docs/specs/F02-input-instructions.md.
/// Doc: docs/techniques/F02.md.
final f02InputInstructions = Technique(
  id: 'F02',
  title: 'Input instructions',
  group: TechniqueGroup.forms,
  summary:
      'A field that needs a format or has rules shows them as text on the '
      'screen, and the field carries the same words as its hint, so a '
      'screen reader reads them with the field.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(
      note:
          'TalkBack reads a field\'s label and instructions only while the '
          'field is empty (limitation FL-015). Once it has a value the '
          'instruction is left in the visible text beside the field, which is '
          'kept as an element of its own; TalkBack reads it when focus is put '
          'on it.',
    ),
    AppPlatform.ios: PlatformStatus.applies(),
    AppPlatform.web: PlatformStatus.applies(),
  },
  wcag: const [
    WcagCriterion('3.3.2', 'Labels or Instructions', 'labels-or-instructions'),
    WcagCriterion('1.3.1', 'Info and Relationships', 'info-and-relationships'),
    WcagCriterion('1.4.4', 'Resize Text', 'resize-text'),
  ],
  sources: const [
    SourceLink(
      'iOS SwiftUI: Input Instructions',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/InputInstructions.md',
    ),
    SourceLink(
      'Android Compose: TextField Controls',
      'https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/components/TextFieldControls.md',
    ),
    SourceLink(
      'MDN: aria-describedby',
      'https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Reference/Attributes/aria-describedby',
    ),
    SourceLink(
      'WCAG: Understanding 3.3.2 Labels or Instructions',
      'https://www.w3.org/WAI/WCAG22/Understanding/labels-or-instructions.html',
    ),
    SourceLink(
      'WCAG technique ARIA1: aria-describedby for a control',
      'https://www.w3.org/WAI/WCAG22/Techniques/aria/ARIA1',
    ),
    SourceLink(
      'WCAG technique G89: expected data format and example',
      'https://www.w3.org/WAI/WCAG22/Techniques/general/G89',
    ),
    SourceLink(
      'Flutter API: SemanticsProperties.hint',
      'https://api.flutter.dev/flutter/semantics/SemanticsProperties/hint.html',
    ),
    SourceLink(
      'Flutter API: InputDecoration.helperText',
      'https://api.flutter.dev/flutter/material/InputDecoration/helperText.html',
    ),
    SourceLink(
      'Flutter API: InputDecoration.helperMaxLines',
      'https://api.flutter.dev/flutter/material/InputDecoration/helperMaxLines.html',
    ),
    SourceLink(
      'Flutter API: CupertinoFormRow',
      'https://api.flutter.dev/flutter/cupertino/CupertinoFormRow-class.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-helper',
      title: 'Helper text that is also the field\'s hint',
      variant: ExampleVariant.material,
      builder: (_) => const GoodHelper(),
    ),
    TechniqueExample.good(
      slug: 'good-cupertino',
      title: 'Form row help text that is also the field\'s hint',
      variant: ExampleVariant.cupertino,
      builder: (_) => const GoodCupertino(),
    ),
    TechniqueExample.good(
      slug: 'good-before',
      title: 'Instruction above the field, and the field\'s hint',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodBefore(),
    ),
    TechniqueExample.bad(
      slug: 'bad-helper-only',
      title: 'Helper text not tied to the field',
      variant: ExampleVariant.material,
      defect:
          'The instruction is on the screen, but a screen reader reads the '
          'field without it. It is reached only as separate text after the '
          'field.',
      builder: (_) => const BadHelperOnly(),
    ),
    TechniqueExample.bad(
      slug: 'bad-placeholder-format',
      title: 'Format given only as placeholder text',
      variant: ExampleVariant.material,
      defect:
          'The format appears only while the field is being edited and is '
          'empty, and is gone at the first character typed. On Android and '
          'iOS a screen reader does not say it when it reaches the field.',
      builder: (_) => const BadPlaceholderFormat(),
    ),
    TechniqueExample.bad(
      slug: 'bad-helper-cut-off',
      title: 'Helper text cut off with large text',
      variant: ExampleVariant.material,
      defect:
          'With large text the instruction under the field is cut to one '
          'line and ends in an ellipsis; the rest cannot be read on the '
          'screen.',
      builder: (_) => const BadHelperCutOff(),
    ),
  ],
);
