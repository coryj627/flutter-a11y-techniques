import '../../catalog/technique.dart';
import 'examples.dart';

/// I12 Announcements and live regions. Spec: docs/specs/I12-announcements.md.
/// Doc: docs/techniques/I12.md.
final i12Announcements = Technique(
  id: 'I12',
  title: 'Announcements and live regions',
  group: TechniqueGroup.interaction,
  summary:
      'When a status message appears or changes without taking focus, '
      'assistive technology announces it, so people who cannot see the '
      'change still learn about it.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(),
    AppPlatform.ios: PlatformStatus.applies(),
    AppPlatform.web: PlatformStatus.applies(),
  },
  wcag: const [WcagCriterion('4.1.3', 'Status Messages', 'status-messages')],
  sources: const [
    SourceLink(
      'CVS Health iOS SwiftUI: Accessibility Notifications',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/AccessibilityNotifications.md',
    ),
    SourceLink(
      'CVS Health Android View: UX Change Announcements',
      'https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/dynamicbehaviors/UXChangeAnnouncements.md',
    ),
    SourceLink(
      'CVS Health Android Compose: UX Change Announcements',
      'https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/interactions/UXChangeAnnouncements.md',
    ),
    SourceLink(
      'ARIA Authoring Practices Guide: Alert pattern',
      'https://www.w3.org/WAI/ARIA/apg/patterns/alert/',
    ),
    SourceLink(
      'MDN: ARIA live regions',
      'https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Guides/Live_regions',
    ),
    SourceLink(
      'MDN: The output element',
      'https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/output',
    ),
    SourceLink(
      'Flutter API: SemanticsProperties.liveRegion',
      'https://api.flutter.dev/flutter/semantics/SemanticsProperties/liveRegion.html',
    ),
    SourceLink(
      'Flutter API: SemanticsService.sendAnnouncement',
      'https://api.flutter.dev/flutter/semantics/SemanticsService/sendAnnouncement.html',
    ),
    SourceLink(
      'Flutter API: SemanticsRole',
      'https://api.flutter.dev/flutter/dart-ui/SemanticsRole.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-live-region',
      title: 'Status message in a live region',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodLiveRegion(),
    ),
    TechniqueExample.good(
      slug: 'good-announce',
      title: 'Announcement sent from code, with a fallback',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodAnnouncement(),
    ),
    TechniqueExample.good(
      slug: 'good-snackbar',
      title: 'SnackBar',
      variant: ExampleVariant.material,
      builder: (_) => const GoodSnackBar(),
    ),
    TechniqueExample.bad(
      slug: 'bad-silent-update',
      title: 'Status message that is not announced',
      variant: ExampleVariant.widgets,
      defect:
          'The message changes on screen but is not announced, so a screen '
          'reader user does not know anything happened.',
      builder: (_) => const BadSilentUpdate(),
    ),
    TechniqueExample.bad(
      slug: 'bad-chatty-live-region',
      title: 'Live region that changes every second',
      variant: ExampleVariant.widgets,
      defect:
          'A live region updates every second, so the screen reader '
          'announces without pause.',
      builder: (_) => const BadChattyLiveRegion(),
    ),
    TechniqueExample.bad(
      slug: 'bad-status-role-only',
      title: 'Status role with no live region',
      variant: ExampleVariant.widgets,
      defect:
          'Flutter limitation: a message with only the status role is '
          'announced on web but not on Android.',
      builder: (_) => const BadStatusRoleOnly(),
    ),
    TechniqueExample.bad(
      slug: 'bad-alert-role-only',
      title: 'Alert role with no live region',
      variant: ExampleVariant.widgets,
      defect:
          'Flutter limitation: an error with only the alert role is '
          'announced on web but not on Android.',
      builder: (_) => const BadAlertRoleOnly(),
    ),
  ],
);
