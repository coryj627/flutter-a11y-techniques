import '../../catalog/technique.dart';
import 'examples.dart';

/// C13 Snackbar and transient messages. Spec: docs/specs/C13-snackbar.md.
/// Doc: docs/techniques/C13.md.
final c13Snackbar = Technique(
  id: 'C13',
  title: 'Snackbar and transient messages',
  group: TechniqueGroup.components,
  summary:
      'A short message about what the app has done is announced without '
      'taking focus, its action can be reached before it goes, and what it '
      'says or offers does not vanish on a timer the user cannot change. '
      'Flutter\'s SnackBar and MaterialBanner, shown through the '
      'ScaffoldMessenger.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(
      note:
          'A SnackBar\'s time limit is the app\'s alone: TalkBack and '
          'Android\'s "Time to take action" setting do not change it '
          '(FL-290). Escape does not close a message (FL-291).',
    ),
    AppPlatform.ios: PlatformStatus.applies(
      note:
          'A SnackBar\'s time limit is the app\'s alone: VoiceOver does not '
          'change it (FL-290). Cupertino has no widget for a transient '
          'message; the examples are Material\'s.',
    ),
    AppPlatform.web: PlatformStatus.applies(
      note:
          'A SnackBar\'s time limit is the app\'s alone (FL-290). Escape does '
          'not close a message (FL-291). VoiceOver in Chromium did not say '
          'what Undo or Go online did after Enter on it (FL-297).',
    ),
  },
  wcag: const [
    WcagCriterion('4.1.3', 'Status Messages', 'status-messages'),
    WcagCriterion('2.2.1', 'Timing Adjustable', 'timing-adjustable'),
  ],
  sources: const [
    SourceLink(
      'Android Compose: Popup messages',
      'https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/components/PopupMessages.md',
    ),
    SourceLink(
      'ARIA Authoring Practices Guide: Alert pattern',
      'https://www.w3.org/WAI/ARIA/apg/patterns/alert/',
    ),
    SourceLink(
      'Understanding 4.1.3 Status Messages',
      'https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html',
    ),
    SourceLink(
      'Understanding 2.2.1 Timing Adjustable',
      'https://www.w3.org/WAI/WCAG22/Understanding/timing-adjustable.html',
    ),
    SourceLink(
      'Flutter API: SnackBar',
      'https://api.flutter.dev/flutter/material/SnackBar-class.html',
    ),
    SourceLink(
      'Flutter API: SnackBar.persist',
      'https://api.flutter.dev/flutter/material/SnackBar/persist.html',
    ),
    SourceLink(
      'Flutter API: SnackBar.showCloseIcon',
      'https://api.flutter.dev/flutter/material/SnackBar/showCloseIcon.html',
    ),
    SourceLink(
      'Flutter API: ScaffoldMessengerState.showSnackBar',
      'https://api.flutter.dev/flutter/material/ScaffoldMessengerState/showSnackBar.html',
    ),
    SourceLink(
      'Flutter API: MaterialBanner',
      'https://api.flutter.dev/flutter/material/MaterialBanner-class.html',
    ),
    SourceLink(
      'Flutter API: ScaffoldMessengerState.showMaterialBanner',
      'https://api.flutter.dev/flutter/material/ScaffoldMessengerState/showMaterialBanner.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-action',
      title: 'SnackBar with an action',
      variant: ExampleVariant.material,
      builder: (_) => const GoodAction(),
    ),
    TechniqueExample.good(
      slug: 'good-message',
      title: 'SnackBar whose news is also on the page',
      variant: ExampleVariant.material,
      builder: (_) => const GoodMessage(),
    ),
    TechniqueExample.good(
      slug: 'good-banner',
      title: 'MaterialBanner',
      variant: ExampleVariant.material,
      builder: (_) => const GoodBanner(),
    ),
    TechniqueExample.bad(
      slug: 'bad-action-times-out',
      title: 'Action that times out',
      variant: ExampleVariant.material,
      defect: 'Undo goes after four seconds, and nothing gives more time.',
      builder: (_) => const BadActionTimesOut(),
    ),
    TechniqueExample.bad(
      slug: 'bad-only-in-message',
      title: 'Information only in a SnackBar',
      variant: ExampleVariant.material,
      defect: 'The code is shown for four seconds and nowhere else.',
      builder: (_) => const BadOnlyInMessage(),
    ),
    TechniqueExample.bad(
      slug: 'bad-inline-banner',
      title: 'Banner put in the page',
      variant: ExampleVariant.material,
      defect: 'The banner is not announced.',
      builder: (_) => const BadInlineBanner(),
    ),
  ],
);
