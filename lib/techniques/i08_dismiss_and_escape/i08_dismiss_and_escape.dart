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
          'Escape was measured on iOS 27.0 only. VoiceOver\'s escape '
          'gesture could not be performed from a test, so what it does is '
          'read in the source and not verified.',
    ),
    AppPlatform.web: PlatformStatus.limitation(
      'In Chromium, while a tooltip still counts as open after a mouse '
      'hover, Flutter takes Escape for the tooltip before the layers can '
      '(limitation FL-484). In probes, unthrottled, with the mouse resting '
      'on Back, the first Escape within about 400 ms of opening the layers '
      'did not close them in any of the three good examples (20 of 20, 20 '
      'of 20, and 11 of 11 at 383 ms or less); a second Escape did. With '
      'the CPU throttled, a tooltip left open under the screen took every '
      'Escape in good-widgets. No workaround is built.',
    ),
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
      customSolution:
          'Dismissal built by hand for layers in an OverlayEntry: a '
          'ModalBarrier, a focus scope, Actions for DismissIntent, '
          'Semantics(onDismiss:), and a PopScope; an overlay has none of '
          'these (FL-481).',
      builder: (_) => const GoodWidgets(),
    ),
    TechniqueExample.bad(
      slug: 'bad-not-dismissible',
      title: 'A bottom sheet that cannot be dismissed',
      variant: ExampleVariant.material,
      defect:
          'Escape does nothing, and Tab only goes round the two switches. '
          'On iOS 27.0 no key closed the layers (earlier iOS not tested); on '
          'Android only the system\'s keyboard Back (Meta+Escape) does, and '
          'on the web the browser\'s Back, and nothing says so.',
      builder: (_) => const BadNotDismissible(),
    ),
    TechniqueExample.bad(
      slug: 'bad-no-escape',
      title: 'Layers drawn in the overlay with no Escape',
      variant: ExampleVariant.widgets,
      defect:
          'Escape does nothing, and Tab and Shift+Tab only go round the two '
          'switches. On iOS 27.0 no key left the layers (earlier iOS not '
          'tested); on Android only the system\'s keyboard Back '
          '(Meta+Escape) does, and on the web the browser\'s Back, and '
          'nothing says so.',
      builder: (_) => const BadNoEscape(),
    ),
    TechniqueExample.bad(
      slug: 'bad-back-leaves',
      title: 'Layers drawn in the overlay that Back goes past',
      variant: ExampleVariant.widgets,
      defect:
          'Back (on Android the Back key, TalkBack\'s Back gesture, or '
          'Meta+Escape on a keyboard; on the web the browser\'s Back) leaves '
          'the screen with the layers still open, instead of closing them.',
      builder: (_) => const BadBackLeaves(),
    ),
  ],
);
