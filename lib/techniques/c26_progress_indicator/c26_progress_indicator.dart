import '../../catalog/technique.dart';
import 'examples.dart';

/// C26 Progress indicator. Spec: docs/specs/C26-progress-indicator.md.
/// Doc: docs/techniques/C26.md.
final c26ProgressIndicator = Technique(
  id: 'C26',
  title: 'Progress indicator',
  group: TechniqueGroup.components,
  summary:
      'A progress bar has a name and its value, and how the task is going, '
      'and that it has finished, are announced as status messages: '
      'Material\'s LinearProgressIndicator with a live region for the '
      'status. Flutter gives a spinner no role on any platform, and no '
      'indicator a role on iOS, so there is no good spinner example.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(
      note:
          'For a bar. A spinner has no role (limitation FL-256), so there is '
          'no good spinner example. A change of an indicator\'s value is not '
          'announced (FL-254): a live region tells the status.',
    ),
    AppPlatform.ios: PlatformStatus.limitation(
      'No progress indicator has a role on iOS: a bar and a spinner are '
      'plain text, read as a name and a value (limitation FL-256). There is '
      'no workaround. A change of the value is not announced (FL-254); a '
      'live region tells the status.',
    ),
    AppPlatform.web: PlatformStatus.applies(
      note:
          'For a bar. A spinner has no role (limitation FL-256), so there is '
          'no good spinner example. A change of an indicator\'s value is not '
          'announced (FL-254). In a browser on a Mac, '
          'CircularProgressIndicator.adaptive drops its label (FL-257).',
    ),
  },
  wcag: const [
    WcagCriterion('4.1.2', 'Name, Role, Value', 'name-role-value'),
    WcagCriterion('4.1.3', 'Status Messages', 'status-messages'),
  ],
  sources: const [
    SourceLink(
      'iOS SwiftUI: Progress Indicators',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/ProgressIndicators.md',
    ),
    SourceLink(
      'MDN: The progress element',
      'https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/progress',
    ),
    SourceLink(
      'WAI-ARIA 1.2: progressbar role',
      'https://www.w3.org/TR/wai-aria-1.2/#progressbar',
    ),
    SourceLink(
      'Understanding 4.1.3 Status Messages',
      'https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html',
    ),
    SourceLink(
      'WCAG technique ARIA25: a live region for the status of a progress bar',
      'https://www.w3.org/WAI/WCAG22/Techniques/aria/ARIA25',
    ),
    SourceLink(
      'Flutter API: LinearProgressIndicator',
      'https://api.flutter.dev/flutter/material/LinearProgressIndicator-class.html',
    ),
    SourceLink(
      'Flutter API: CircularProgressIndicator',
      'https://api.flutter.dev/flutter/material/CircularProgressIndicator-class.html',
    ),
    SourceLink(
      'Flutter API: ProgressIndicator.semanticsLabel',
      'https://api.flutter.dev/flutter/material/ProgressIndicator/semanticsLabel.html',
    ),
    SourceLink(
      'Flutter API: CupertinoActivityIndicator',
      'https://api.flutter.dev/flutter/cupertino/CupertinoActivityIndicator-class.html',
    ),
    SourceLink(
      'Flutter API: Semantics.liveRegion',
      'https://api.flutter.dev/flutter/widgets/Semantics/liveRegion.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-linear',
      title: 'Material progress bar',
      variant: ExampleVariant.material,
      builder: (_) => const GoodLinear(),
    ),
    TechniqueExample.bad(
      slug: 'bad-no-label',
      title: 'Progress bar with no name',
      variant: ExampleVariant.material,
      defect: 'A screen reader reads the bar as a number with no name.',
      builder: (_) => const BadNoLabel(),
    ),
    TechniqueExample.bad(
      slug: 'bad-silent-end',
      title: 'Upload that ends in silence',
      variant: ExampleVariant.material,
      defect: 'Nothing tells a screen reader that the upload has finished.',
      builder: (_) => const BadSilentEnd(),
    ),
    TechniqueExample.bad(
      slug: 'bad-no-role',
      title: 'Material spinner',
      variant: ExampleVariant.material,
      defect:
          'A screen reader hears a name and no role: Flutter gives no '
          'spinner one.',
      builder: (_) => const BadNoRole(),
    ),
    TechniqueExample.bad(
      slug: 'bad-cupertino-no-role',
      title: 'Cupertino spinner',
      variant: ExampleVariant.cupertino,
      defect:
          'A screen reader hears a name and no role: Flutter gives no '
          'spinner one.',
      builder: (_) => const BadCupertinoNoRole(),
    ),
    TechniqueExample.bad(
      slug: 'bad-adaptive',
      title: 'Adaptive spinner',
      variant: ExampleVariant.material,
      defect: 'On iOS and on a Mac, a screen reader finds no spinner.',
      builder: (_) => const BadAdaptive(),
    ),
    TechniqueExample.bad(
      slug: 'bad-cupertino-bar',
      title: 'Cupertino progress bar',
      variant: ExampleVariant.cupertino,
      defect: 'A screen reader finds no bar and no value.',
      builder: (_) => const BadCupertinoBar(),
    ),
  ],
);
