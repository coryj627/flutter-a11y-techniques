import '../../catalog/technique.dart';
import 'examples.dart';

/// F03 Keyboard types.
/// Spec: docs/specs/F03-keyboard-types.md.
/// Doc: docs/techniques/F03.md.
final f03KeyboardTypes = Technique(
  id: 'F03',
  title: 'Keyboard types',
  group: TechniqueGroup.forms,
  summary:
      'A text field asks for the on-screen keyboard that fits what it takes, '
      'says what its Enter key does, and, when it collects information about '
      'the user, names that information with an autofill hint, so that the '
      'platform can offer the right keys and fill the field in.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(),
    AppPlatform.ios: PlatformStatus.applies(
      note:
          'Autofill hints become the field\'s text content type while it is '
          'being edited, according to the engine source; no test can read '
          'that on iOS, so it is not verified. An obscured field is a secure '
          'text field only while it is being edited (limitation FL-042).',
    ),
    AppPlatform.web: PlatformStatus.limitation(
      'Autofill hints do not reach the page for a field that is not '
      'obscured: its autocomplete attribute is "off" whatever the hint '
      '(limitation FL-161). An email keyboard type gives '
      'autocomplete="email", and an obscured field gets its hint once it '
      'has been focused. There is no workaround in the SDK for other '
      'fields.',
    ),
  },
  wcag: const [
    WcagCriterion('1.3.5', 'Identify Input Purpose', 'identify-input-purpose'),
  ],
  sources: const [
    SourceLink(
      'Android View: Keyboard Types',
      'https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/dynamicbehaviors/KeyboardTypes.md',
    ),
    SourceLink(
      'Android Compose: Keyboard Types and Options',
      'https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/interactions/KeyboardTypes.md',
    ),
    SourceLink(
      'WCAG: Understanding 1.3.5 Identify Input Purpose',
      'https://www.w3.org/WAI/WCAG22/Understanding/identify-input-purpose.html',
    ),
    SourceLink(
      'WCAG: H98 Using HTML autocomplete attributes',
      'https://www.w3.org/WAI/WCAG22/Techniques/html/H98',
    ),
    SourceLink(
      'MDN: The inputmode attribute',
      'https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Global_attributes/inputmode',
    ),
    SourceLink(
      'MDN: The autocomplete attribute',
      'https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Attributes/autocomplete',
    ),
    SourceLink(
      'MDN: <input type="password">',
      'https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/input/password',
    ),
    SourceLink(
      'Flutter API: TextField.keyboardType',
      'https://api.flutter.dev/flutter/material/TextField/keyboardType.html',
    ),
    SourceLink(
      'Flutter API: TextField.autofillHints',
      'https://api.flutter.dev/flutter/material/TextField/autofillHints.html',
    ),
    SourceLink(
      'Flutter API: AutofillGroup',
      'https://api.flutter.dev/flutter/widgets/AutofillGroup-class.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-contact',
      title: 'Contact fields with their keyboards and purposes',
      variant: ExampleVariant.material,
      builder: (_) => const GoodContact(),
    ),
    TechniqueExample.good(
      slug: 'good-amount',
      title: 'Amount with the decimal keyboard',
      variant: ExampleVariant.material,
      builder: (_) => const GoodAmount(),
    ),
    TechniqueExample.good(
      slug: 'good-cupertino',
      title: 'Cupertino fields with their keyboards and purposes',
      variant: ExampleVariant.cupertino,
      builder: (_) => const GoodCupertino(),
    ),
    TechniqueExample.good(
      slug: 'good-sign-in',
      title: 'Sign-in fields in an autofill group',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodSignIn(),
    ),
    TechniqueExample.bad(
      slug: 'bad-number-for-name',
      title: 'Name field with the number keyboard',
      variant: ExampleVariant.material,
      defect:
          'The on-screen keyboard has digits only, so a name cannot be typed '
          'with it.',
      builder: (_) => const BadNumberForName(),
    ),
    TechniqueExample.bad(
      slug: 'bad-default-keyboard',
      title: 'Email field with the default keyboard',
      variant: ExampleVariant.material,
      defect:
          'The keyboard is the general one: the "@" is not on its first page.',
      builder: (_) => const BadDefaultKeyboard(),
    ),
    TechniqueExample.bad(
      slug: 'bad-no-purpose',
      title: 'Name field with no autofill hint',
      variant: ExampleVariant.material,
      defect:
          'Nothing says that the field holds the user\'s name, so the '
          'platform cannot offer to fill it in.',
      builder: (_) => const BadNoPurpose(),
    ),
    TechniqueExample.bad(
      slug: 'bad-email-no-suggestions',
      title: 'Email field with suggestions turned off',
      variant: ExampleVariant.material,
      defect:
          'On Android the email keyboard is replaced by a general one with no '
          '"@" key (limitation FL-160).',
      builder: (_) => const BadEmailNoSuggestions(),
    ),
  ],
);
