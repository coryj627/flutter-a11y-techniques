import '../../catalog/technique.dart';
import 'examples.dart';

/// S16 Language of page and parts. Spec:
/// docs/specs/S16-language-page-parts.md. Doc: docs/techniques/S16.md.
final s16LanguagePageParts = Technique(
  id: 'S16',
  title: 'Language of page and parts',
  group: TechniqueGroup.semantics,
  summary:
      'The app\'s language is given to assistive technology, and a passage '
      'or a phrase in another language is marked with its own, so that a '
      'screen reader can speak it with the right voice.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(
      note:
          'The app\'s language and a marked part reach TalkBack as a '
          'LocaleSpan. Whether TalkBack changes its voice for one was not '
          'measured: its log gives the words only.',
    ),
    AppPlatform.ios: PlatformStatus.applies(
      note:
          'XCUITest cannot read a language. VoiceOver reads a button with '
          'its role word in its element\'s language ("Français Bouton") and '
          'a marked phrase with a second space round it; a passage\'s language '
          'rests on the engine\'s source. Whether VoiceOver changes its voice '
          'was not measured.',
    ),
    AppPlatform.web: PlatformStatus.limitation(
      'The page\'s lang is the app\'s language, and a passage marked with '
      'localeForSubtree has a lang of its own. A phrase inside a sentence '
      'cannot be marked: the web engine drops TextSpan(locale:) and every '
      'language attribute of a label (limitation FL-020). A locale with a '
      'country is written fr_FR, which the browser does not read as French '
      '(FL-020).',
    ),
  },
  wcag: const [
    WcagCriterion('3.1.1', 'Language of Page', 'language-of-page'),
    WcagCriterion('3.1.2', 'Language of Parts', 'language-of-parts'),
  ],
  sources: const [
    SourceLink(
      'iOS SwiftUI: Language',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/Language.md',
    ),
    SourceLink(
      'iOS SwiftUI: Attributed Strings',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/AttributedStrings.md',
    ),
    SourceLink(
      'Android View: Text Language Identification',
      'https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/componenttypes/TextLanguageIdentification.md',
    ),
    SourceLink(
      'MDN: The lang global attribute',
      'https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Global_attributes/lang',
    ),
    SourceLink(
      'WCAG technique H57: Using the language attribute on the HTML element',
      'https://www.w3.org/WAI/WCAG22/Techniques/html/H57',
    ),
    SourceLink(
      'WCAG technique H58: Using language attributes to identify changes '
          'in the human language',
      'https://www.w3.org/WAI/WCAG22/Techniques/html/H58',
    ),
    SourceLink(
      'Flutter API: Semantics.localeForSubtree',
      'https://api.flutter.dev/flutter/widgets/Semantics/localeForSubtree.html',
    ),
    SourceLink(
      'Flutter API: TextSpan.locale',
      'https://api.flutter.dev/flutter/painting/TextSpan/locale.html',
    ),
    SourceLink(
      'Flutter API: WidgetsApp.supportedLocales',
      'https://api.flutter.dev/flutter/widgets/WidgetsApp/supportedLocales.html',
    ),
    SourceLink(
      'Flutter API: Localizations.override',
      'https://api.flutter.dev/flutter/widgets/Localizations/Localizations.override.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-passage',
      title: 'Passage in another language',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodPassage(),
    ),
    TechniqueExample.good(
      slug: 'good-phrase',
      title: 'Phrase in another language',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodPhrase(),
    ),
    TechniqueExample.good(
      slug: 'good-language-menu',
      title: 'Language menu',
      variant: ExampleVariant.material,
      builder: (_) => const GoodLanguageMenu(),
    ),
    TechniqueExample.bad(
      slug: 'bad-unmarked',
      title: 'Passage not marked',
      variant: ExampleVariant.widgets,
      defect: 'The French passage is read as English.',
      builder: (_) => const BadUnmarked(),
    ),
    TechniqueExample.bad(
      slug: 'bad-title-in-tile',
      title: 'Language set inside each tile',
      variant: ExampleVariant.material,
      defect: 'Each language is read as English.',
      builder: (_) => const BadTitleInTile(),
    ),
    TechniqueExample.bad(
      slug: 'bad-region-tag',
      title: 'Language with a country',
      variant: ExampleVariant.widgets,
      defect: 'On the web the passage is not taken as French.',
      builder: (_) => const BadRegionTag(),
    ),
    TechniqueExample.bad(
      slug: 'bad-override',
      title: 'Localizations.override',
      variant: ExampleVariant.widgets,
      defect: 'The whole app becomes French, and stays French.',
      builder: (_) => const BadOverride(),
    ),
  ],
);
