import '../../catalog/technique.dart';
import 'examples.dart';

/// I08 Dismiss and escape.
/// Spec: docs/specs/I08-dismiss-and-escape.md.
/// Doc: docs/techniques/I08.md.
final i08DismissAndEscape = Technique(
  id: 'I08',
  title: 'Dismiss and escape',
  group: TechniqueGroup.interaction,
  summary:
      'Something shown over the screen for a while, such as a sheet, a '
      'popup, or layers drawn by hand, closes on Escape, on Android\'s Back, '
      'and on a screen reader\'s own dismiss command; and a part of the '
      'screen that keeps Tab inside it can always be left from the keyboard.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(),
    AppPlatform.ios: PlatformStatus.applies(
      note:
          'VoiceOver\'s escape gesture could not be performed from a test, '
          'so what it does is read in the source and not verified.',
    ),
    AppPlatform.web: PlatformStatus.applies(),
  },
  wcag: const [WcagCriterion('2.1.2', 'No Keyboard Trap', 'no-keyboard-trap')],
  sources: const [
    SourceLink(
      'iOS: Escape Action',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/EscapeAction.md',
    ),
    SourceLink(
      'WCAG 2.2: Understanding No Keyboard Trap',
      'https://www.w3.org/WAI/WCAG22/Understanding/no-keyboard-trap.html',
    ),
    SourceLink(
      'WCAG technique G21: ensuring that users are not trapped in content',
      'https://www.w3.org/WAI/WCAG22/Techniques/general/G21',
    ),
    SourceLink(
      'APG: Dialog (Modal) pattern, keyboard interaction',
      'https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/',
    ),
    SourceLink(
      'HTML: close requests',
      'https://html.spec.whatwg.org/multipage/interaction.html#close-requests',
    ),
    SourceLink(
      'Flutter API: DismissIntent',
      'https://api.flutter.dev/flutter/widgets/DismissIntent-class.html',
    ),
    SourceLink(
      'Flutter API: ModalRoute.barrierDismissible',
      'https://api.flutter.dev/flutter/widgets/ModalRoute/barrierDismissible.html',
    ),
    SourceLink(
      'Flutter API: PopScope',
      'https://api.flutter.dev/flutter/widgets/PopScope-class.html',
    ),
    SourceLink(
      'Flutter API: SemanticsProperties.onDismiss',
      'https://api.flutter.dev/flutter/semantics/SemanticsProperties/onDismiss.html',
    ),
    SourceLink(
      'Flutter API: TraversalEdgeBehavior',
      'https://api.flutter.dev/flutter/widgets/TraversalEdgeBehavior.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-material',
      title: 'A Material bottom sheet that can be dismissed',
      variant: ExampleVariant.material,
      builder: (_) => const GoodMaterial(),
    ),
    TechniqueExample.good(
      slug: 'good-cupertino',
      title: 'A Cupertino modal popup with a dismissible barrier',
      variant: ExampleVariant.cupertino,
      builder: (_) => const GoodCupertino(),
    ),
    TechniqueExample.good(
      slug: 'good-widgets',
      title: 'Layers drawn in the overlay, closed by every dismiss command',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodWidgets(),
    ),
    TechniqueExample.bad(
      slug: 'bad-not-dismissible',
      title: 'A bottom sheet that cannot be dismissed',
      variant: ExampleVariant.material,
      defect:
          'Escape does nothing, and Tab only goes round the two switches. '
          'On iOS no key closes the layers; on Android only the system\'s '
          'keyboard Back, Meta+Escape, does, and nothing says so.',
      builder: (_) => const BadNotDismissible(),
    ),
    TechniqueExample.bad(
      slug: 'bad-no-escape',
      title: 'Layers drawn in the overlay with no Escape',
      variant: ExampleVariant.widgets,
      defect:
          'Escape does nothing, and Tab and Shift+Tab only go round the two '
          'switches. On iOS and the web no key leaves the layers; on Android '
          'only the system\'s keyboard Back, Meta+Escape, does, and nothing '
          'says so.',
      builder: (_) => const BadNoEscape(),
    ),
    TechniqueExample.bad(
      slug: 'bad-back-leaves',
      title: 'Layers drawn in the overlay that Back goes past',
      variant: ExampleVariant.widgets,
      defect:
          'On Android, Back (the Back key, TalkBack\'s Back gesture, or '
          'Meta+Escape on a keyboard) leaves the screen with the layers '
          'still open, instead of closing them.',
      builder: (_) => const BadBackLeaves(),
    ),
  ],
);
