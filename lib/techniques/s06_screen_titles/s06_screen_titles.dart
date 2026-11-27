import '../../catalog/technique.dart';
import 'examples.dart';

/// S06 Screen and page titles. Spec: docs/specs/S06-screen-titles.md.
/// Doc: docs/techniques/S06.md.
final s06ScreenTitles = Technique(
  id: 'S06',
  title: 'Screen and page titles',
  group: TechniqueGroup.semantics,
  summary:
      'Every screen has a title that says what it is for: the app bar\'s '
      'title, which names the screen for a screen reader, and Title, which '
      'gives the browser its document title. Flutter keeps the document '
      'title of a closed screen after Back, so the web is a limitation.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(
      note:
          'An AppBar\'s title names the screen; a CupertinoNavigationBar\'s '
          'does not until it is given namesRoute (limitation FL-301).',
    ),
    AppPlatform.ios: PlatformStatus.applies(
      note:
          'The title is the screen\'s level 1 heading. When a screen '
          'opens VoiceOver goes to its Back button, and the title is not '
          'heard (limitation FL-302).',
    ),
    AppPlatform.web: PlatformStatus.limitation(
      'Title sets the document title when a screen opens, and nothing sets '
      'it back when the screen closes: after Back the browser tab still '
      'names the closed screen (limitation FL-300). There is no workaround.',
    ),
  },
  wcag: const [WcagCriterion('2.4.2', 'Page Titled', 'page-titled')],
  sources: const [
    SourceLink(
      'iOS SwiftUI: Page Titles',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/PageTitles.md',
    ),
    SourceLink(
      'Android Compose: Screen and Pane Titles',
      'https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/content/ScreenAndPaneTitles.md',
    ),
    SourceLink(
      'MDN: The title element',
      'https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/title',
    ),
    SourceLink(
      'Understanding 2.4.2 Page Titled',
      'https://www.w3.org/WAI/WCAG22/Understanding/page-titled.html',
    ),
    SourceLink(
      'WCAG technique G88: descriptive titles',
      'https://www.w3.org/WAI/WCAG22/Techniques/general/G88',
    ),
    SourceLink(
      'WCAG failure F25: a title that does not identify the contents',
      'https://www.w3.org/WAI/WCAG22/Techniques/failures/F25',
    ),
    SourceLink(
      'Flutter API: AppBar.title',
      'https://api.flutter.dev/flutter/material/AppBar/title.html',
    ),
    SourceLink(
      'Flutter API: CupertinoNavigationBar.middle',
      'https://api.flutter.dev/flutter/cupertino/CupertinoNavigationBar/middle.html',
    ),
    SourceLink(
      'Flutter API: Title',
      'https://api.flutter.dev/flutter/widgets/Title-class.html',
    ),
    SourceLink(
      'Flutter API: SemanticsProperties.namesRoute',
      'https://api.flutter.dev/flutter/semantics/SemanticsProperties/namesRoute.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-material',
      title: 'Material screen title',
      variant: ExampleVariant.material,
      builder: (_) => const GoodMaterial(),
    ),
    TechniqueExample.good(
      slug: 'good-cupertino',
      title: 'Cupertino screen title',
      variant: ExampleVariant.cupertino,
      builder: (_) => const GoodCupertino(),
    ),
    TechniqueExample.bad(
      slug: 'bad-no-title',
      title: 'Screen with no title',
      variant: ExampleVariant.material,
      defect: 'The screen has no title, only large text.',
      builder: (_) => const BadNoTitle(),
    ),
    TechniqueExample.bad(
      slug: 'bad-vague-title',
      title: 'Screen titled Details',
      variant: ExampleVariant.material,
      defect: 'The title does not say what the screen is about.',
      builder: (_) => const BadVagueTitle(),
    ),
    TechniqueExample.bad(
      slug: 'bad-no-document-title',
      title: 'Screen with no document title',
      variant: ExampleVariant.material,
      defect: 'The browser tab keeps the title of the screen before.',
      builder: (_) => const BadNoDocumentTitle(),
    ),
    TechniqueExample.bad(
      slug: 'bad-cupertino-unnamed',
      title: 'Cupertino bar that names no screen',
      variant: ExampleVariant.cupertino,
      defect: 'On Android, TalkBack is not told the screen\'s name.',
      builder: (_) => const BadCupertinoUnnamed(),
    ),
  ],
);
