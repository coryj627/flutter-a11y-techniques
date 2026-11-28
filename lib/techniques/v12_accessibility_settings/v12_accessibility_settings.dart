import '../../catalog/technique.dart';
import 'examples.dart';

/// V12 Detecting accessibility settings. Spec:
/// docs/specs/V12-accessibility-settings.md. Doc: docs/techniques/V12.md.
final v12AccessibilitySettings = Technique(
  id: 'V12',
  title: 'Detecting accessibility settings',
  group: TechniqueGroup.visual,
  summary:
      'An app reads the user\'s settings through MediaQuery, which rebuilds '
      'it when one changes, and does not count on a flag that a platform '
      'never sets. No success criterion of its own: it serves the '
      'techniques that adapt to a setting.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(
      note:
          'Accessible navigation turns on when any accessibility service '
          'reads the app, not only TalkBack, and is off in the first frame '
          '(limitation FL-503). High contrast follows the contrast level, '
          'not High contrast text, and changing it or Bold text starts the '
          'app again (FL-504).',
    ),
    AppPlatform.ios: PlatformStatus.applies(
      note:
          'Reduce Motion sets only AccessibilityFeatures.reduceMotion, '
          'which MediaQuery does not carry (limitation FL-502). The '
          'appearance could not be changed on the simulator, so dark mode '
          'was not measured.',
    ),
    AppPlatform.web: PlatformStatus.limitation(
      'Whether a screen reader is running cannot be told: accessible '
      'navigation is whether the app\'s semantics are on, which this app '
      'turns on at start (limitation FL-500). High contrast comes from '
      'forced colours only, and bold text, inverted colours, and switch '
      'labels are never set (FL-501).',
    ),
  },
  wcag: const [],
  sources: const [
    SourceLink(
      'iOS SwiftUI: Accessibility Detection',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/AccessibilityDetection.md',
    ),
    SourceLink(
      'Flutter API: MediaQueryData',
      'https://api.flutter.dev/flutter/widgets/MediaQueryData-class.html',
    ),
    SourceLink(
      'Flutter API: MediaQuery',
      'https://api.flutter.dev/flutter/widgets/MediaQuery-class.html',
    ),
    SourceLink(
      'Flutter API: AccessibilityFeatures',
      'https://api.flutter.dev/flutter/dart-ui/AccessibilityFeatures-class.html',
    ),
    SourceLink(
      'Flutter API: WidgetsBindingObserver.didChangeAccessibilityFeatures',
      'https://api.flutter.dev/flutter/widgets/WidgetsBindingObserver/didChangeAccessibilityFeatures.html',
    ),
    SourceLink(
      'Flutter API: SemanticsBinding.semanticsEnabled',
      'https://api.flutter.dev/flutter/semantics/SemanticsBinding/semanticsEnabled.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-media-query',
      title: 'Settings from MediaQuery',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodMediaQuery(),
    ),
    TechniqueExample.good(
      slug: 'good-motion',
      title: 'Reduce motion from both flags',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodMotion(),
    ),
    TechniqueExample.bad(
      slug: 'bad-read-once',
      title: 'Settings read once',
      variant: ExampleVariant.widgets,
      defect: 'A setting changed while this is open is not shown.',
      builder: (_) => const BadReadOnce(),
    ),
    TechniqueExample.bad(
      slug: 'bad-animations-only',
      title: 'Reduce motion from one flag',
      variant: ExampleVariant.widgets,
      defect: 'On iOS, Reduce Motion is shown as off.',
      builder: (_) => const BadAnimationsOnly(),
    ),
  ],
);
