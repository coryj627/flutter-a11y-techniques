import '../../catalog/technique.dart';
import 'examples.dart';

/// S15 Hints.
/// Spec: docs/specs/S15-hints.md.
/// Doc: docs/techniques/S15.md.
final s15Hints = Technique(
  id: 'S15',
  title: 'Hints',
  group: TechniqueGroup.semantics,
  summary:
      'A hint says what will happen when a control is used, for a control '
      'whose name does not already say it. It is extra: nothing a person '
      'needs is in the hint alone.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(
      note:
          'Android has no separate hint. Flutter adds the hint to the end of '
          'the control\'s description, so TalkBack reads it as part of the '
          'name and it cannot be turned off (limitation FL-039). A text '
          'field is read with its name and hint only while it is empty '
          '(limitation FL-015).',
    ),
    AppPlatform.ios: PlatformStatus.applies(),
    AppPlatform.web: PlatformStatus.applies(),
  },
  wcag: const [
    WcagCriterion('3.3.2', 'Labels or Instructions', 'labels-or-instructions'),
  ],
  sources: const [
    SourceLink(
      'iOS SwiftUI: Accessibility Hint',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/AccessibilityHint.md',
    ),
    SourceLink(
      'Apple: accessibilityHint',
      'https://developer.apple.com/documentation/uikit/uiaccessibilityelement/accessibilityhint',
    ),
    SourceLink(
      'MDN: aria-description',
      'https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Reference/Attributes/aria-description',
    ),
    SourceLink(
      'Flutter API: SemanticsProperties.hint',
      'https://api.flutter.dev/flutter/semantics/SemanticsProperties/hint.html',
    ),
    SourceLink(
      'Flutter API: MergeSemantics',
      'https://api.flutter.dev/flutter/widgets/MergeSemantics-class.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-result',
      title: 'Hint that says what the button does',
      variant: ExampleVariant.material,
      builder: (_) => const GoodResult(),
    ),
    TechniqueExample.good(
      slug: 'good-row',
      title: 'Hint on a row whose name does not say what a tap does',
      variant: ExampleVariant.material,
      builder: (_) => const GoodRow(),
    ),
    TechniqueExample.good(
      slug: 'good-cupertino',
      title: 'Hint on a Cupertino button',
      variant: ExampleVariant.cupertino,
      customSolution:
          'An Actions built by hand round the CupertinoButton so that Enter '
          'works on the web (FL-002); the hint itself is Semantics(hint:).',
      builder: (_) => const GoodCupertino(),
    ),
    TechniqueExample.good(
      slug: 'good-custom',
      title: 'Hint on a custom button',
      variant: ExampleVariant.widgets,
      customSolution:
          'A button drawn by hand: Semantics(button: true, label:, hint:, '
          'onTap:), with focus, keys, and a focus ring from '
          'FocusableActionDetector.',
      builder: (_) => const GoodCustom(),
    ),
    TechniqueExample.good(
      slug: 'good-field',
      title: 'Field rule shown on screen and repeated in the hint',
      variant: ExampleVariant.material,
      builder: (_) => const GoodField(),
    ),
    TechniqueExample.bad(
      slug: 'bad-gesture',
      title: 'Hint that names a gesture',
      variant: ExampleVariant.material,
      defect: 'The hint says "Double tap to", which the screen reader already says in its own words, and which is wrong for a keyboard or a switch.',
      builder: (_) => const BadGesture(),
    ),
    TechniqueExample.bad(
      slug: 'bad-repeats-label',
      title: 'Hint that repeats the name',
      variant: ExampleVariant.material,
      defect: 'The hint adds nothing. TalkBack and VoiceOver on the web read "Delete, Delete, button".',
      builder: (_) => const BadRepeatsLabel(),
    ),
    TechniqueExample.bad(
      slug: 'bad-control-type',
      title: 'Hint that says the control type',
      variant: ExampleVariant.material,
      defect: 'The hint says "This button", and the screen reader says "button" as well.',
      builder: (_) => const BadControlType(),
    ),
    TechniqueExample.bad(
      slug: 'bad-no-hint',
      title: 'Row with no hint',
      variant: ExampleVariant.material,
      defect: 'The row is read as a song and an artist, and nothing says that a tap plays it.',
      builder: (_) => const BadNoHint(),
    ),
    TechniqueExample.bad(
      slug: 'bad-hint-detached',
      title: 'Hint that does not reach a Material button',
      variant: ExampleVariant.material,
      defect: 'The hint is read on its own, before the button, on Android and iOS, and not at all on the web. The button has no hint.',
      builder: (_) => const BadHintDetached(),
    ),
    TechniqueExample.bad(
      slug: 'bad-hint-only',
      title: 'Field rule in the hint only',
      variant: ExampleVariant.material,
      defect: 'The username rule is not on the screen. Only a screen reader with hints on gives it.',
      builder: (_) => const BadHintOnly(),
    ),
  ],
);
