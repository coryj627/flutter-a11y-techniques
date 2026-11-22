import '../../catalog/technique.dart';
import 'examples.dart';

/// F06 Error identification and announcement.
/// Spec: docs/specs/F06-error-identification.md.
/// Doc: docs/techniques/F06.md.
final f06ErrorIdentification = Technique(
  id: 'F06',
  title: 'Error identification and announcement',
  group: TechniqueGroup.forms,
  summary:
      'When a form is sent with a mistake, each field in error is marked '
      'invalid and shows a message that says what is wrong and how to put it '
      'right. The message is part of the field for assistive technology, the '
      'first error is announced, and focus moves to the first field in error.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(
      note:
          'Flutter gives a field no error state on Android: TalkBack does '
          'not say "error", and reads a field in error that has a value '
          'without its message, which is a node of its own after the field '
          '(limitation FL-180).',
    ),
    AppPlatform.ios: PlatformStatus.applies(
      note:
          'Moving keyboard focus to a field does not move VoiceOver; the '
          'examples send a FocusSemanticEvent as well (limitation FL-184).',
    ),
    AppPlatform.web: PlatformStatus.applies(
      note:
          'On the web and iOS an error is announced only by Form.validate(), '
          'validateGranularly(), or the Form\'s always, onUserInteraction, or '
          'onUserInteractionIfError mode; onUnfocus, a field validated on its '
          'own, and an errorText set by hand are not announced '
          '(limitation FL-181).',
    ),
  },
  wcag: const [
    WcagCriterion('3.3.1', 'Error Identification', 'error-identification'),
    WcagCriterion('3.3.3', 'Error Suggestion', 'error-suggestion'),
    WcagCriterion('4.1.3', 'Status Messages', 'status-messages'),
  ],
  sources: const [
    SourceLink(
      'iOS SwiftUI: Error Validation',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/ErrorValidation.md',
    ),
    SourceLink(
      'Android View: Input Error Announcements',
      'https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/dynamicbehaviors/InputErrorAnnouncements.md',
    ),
    SourceLink(
      'MDN: aria-invalid',
      'https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Reference/Attributes/aria-invalid',
    ),
    SourceLink(
      'Flutter API: Form',
      'https://api.flutter.dev/flutter/widgets/Form-class.html',
    ),
    SourceLink(
      'Flutter API: TextFormField',
      'https://api.flutter.dev/flutter/material/TextFormField-class.html',
    ),
    SourceLink(
      'Flutter API: InputDecoration.errorText',
      'https://api.flutter.dev/flutter/material/InputDecoration/errorText.html',
    ),
    SourceLink(
      'Flutter API: SemanticsProperties.validationResult',
      'https://api.flutter.dev/flutter/semantics/SemanticsProperties/validationResult.html',
    ),
    SourceLink(
      'Flutter API: FocusNode.requestFocus',
      'https://api.flutter.dev/flutter/widgets/FocusNode/requestFocus.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-form',
      title: 'Form with errors under each field',
      variant: ExampleVariant.material,
      customSolution:
          'A focus move built by hand: focus goes to the first field in '
          'error, with a FocusSemanticEvent so that VoiceOver on iOS follows '
          '(FL-184); Form moves no focus.',
      builder: (_) => const GoodForm(),
    ),
    TechniqueExample.good(
      slug: 'good-cupertino',
      title: 'Cupertino form with errors',
      variant: ExampleVariant.cupertino,
      customSolution:
          'A Cupertino error field built by hand: FormField, '
          'Semantics(label:, hint:, validationResult:), a live region for the '
          'error, and the focus move of good-form; CupertinoTextFormFieldRow '
          'falls short (FL-182, FL-016).',
      builder: (_) => const GoodCupertino(),
    ),
    TechniqueExample.bad(
      slug: 'bad-color-only',
      title: 'Error shown by colour alone',
      variant: ExampleVariant.material,
      defect:
          'The field turns red and nothing says what is wrong: there is no '
          'message to see or to hear.',
      builder: (_) => const BadColorOnly(),
    ),
    TechniqueExample.bad(
      slug: 'bad-vague-message',
      title: 'Error that does not say how to fix it',
      variant: ExampleVariant.material,
      defect:
          'The message is "Invalid.": it says that something is wrong, not '
          'what to enter.',
      builder: (_) => const BadVagueMessage(),
    ),
    TechniqueExample.bad(
      slug: 'bad-not-announced',
      title: 'Error that appears without being announced',
      variant: ExampleVariant.material,
      defect:
          'The error appears under the field while focus stays on Send, and '
          'on iOS and the web nothing is announced.',
      builder: (_) => const BadNotAnnounced(),
    ),
    TechniqueExample.bad(
      slug: 'bad-merged-error',
      title: 'Field merged with its error',
      variant: ExampleVariant.material,
      defect:
          'The error becomes part of the field\'s name as well as its hint, '
          'so it is heard twice, and on Android the whole field becomes a '
          'live region.',
      builder: (_) => const BadMergedError(),
    ),
  ],
);
