import '../../catalog/technique.dart';
import 'examples.dart';

/// S08 List semantics. Spec: docs/specs/S08-list-semantics.md. Doc:
/// docs/techniques/S08.md.
final s08ListSemantics = Technique(
  id: 'S08',
  title: 'List semantics',
  group: TechniqueGroup.semantics,
  summary:
      'Content shown as a list is exposed as a list, with each item an '
      'element of its own, so that a screen reader can say that it is a '
      'list and where it starts and ends.',
  platforms: const {
    AppPlatform.android: PlatformStatus.limitation(
      'A list made with the list role says "In list" and "Out of list", '
      'but not its number of items or an item\'s place (limitation '
      'FL-311). A list that scrolls says nothing about a list, and once '
      'scrolled its items report the wrong place (FL-313). There is no '
      'workaround in the SDK that keeps the list on the web.',
    ),
    AppPlatform.ios: PlatformStatus.applies(
      note:
          'Flutter gives a list nothing on iOS (FL-310): VoiceOver reads '
          'each item by its text alone, which is what the iOS reference '
          'says a SwiftUI List gives. VoiceOver does say "List start" and '
          '"1 of 3" for a web page\'s list in Safari; a native UIKit list '
          'was not measured. VoiceOver, moving forward, leaves a long '
          'ListView after the items in view (FL-011).',
    ),
    AppPlatform.web: PlatformStatus.limitation(
      'A short list made with the list role is a list of list items. A '
      'list that scrolls, Flutter\'s ListView, is not a list, and the role '
      'cannot be put round one (limitation FL-312); a description list '
      'has no roles (FL-026). There is no workaround in the SDK.',
    ),
  },
  wcag: const [
    WcagCriterion('1.3.1', 'Info and Relationships', 'info-and-relationships'),
  ],
  sources: const [
    SourceLink(
      'iOS SwiftUI: Lists',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/Lists.md',
    ),
    SourceLink(
      'Android View: List Semantics',
      'https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/grouping/ListSemantics.md',
    ),
    SourceLink(
      'Android Compose: List Semantics',
      'https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/content/ListSemantics.md',
    ),
    SourceLink(
      'Android Compose: ListItem Layouts',
      'https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/components/ListItemLayouts.md',
    ),
    SourceLink(
      'MDN: The unordered list element',
      'https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/ul',
    ),
    SourceLink(
      'MDN: The ordered list element',
      'https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/ol',
    ),
    SourceLink(
      'MDN: The description list element',
      'https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/dl',
    ),
    SourceLink(
      'WCAG technique H48: Using ol, ul and dl for lists',
      'https://www.w3.org/WAI/WCAG22/Techniques/html/H48',
    ),
    SourceLink(
      'Flutter API: SemanticsRole',
      'https://api.flutter.dev/flutter/dart-ui/SemanticsRole.html',
    ),
    SourceLink(
      'Flutter API: Semantics.explicitChildNodes',
      'https://api.flutter.dev/flutter/widgets/Semantics/explicitChildNodes.html',
    ),
    SourceLink(
      'Flutter API: ListTile',
      'https://api.flutter.dev/flutter/material/ListTile-class.html',
    ),
    SourceLink(
      'Flutter API: CupertinoListSection',
      'https://api.flutter.dev/flutter/cupertino/CupertinoListSection-class.html',
    ),
    SourceLink(
      'Flutter API: ListView',
      'https://api.flutter.dev/flutter/widgets/ListView-class.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-bulleted',
      title: 'Bulleted list',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodBulleted(),
    ),
    TechniqueExample.good(
      slug: 'good-numbered',
      title: 'Numbered list',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodNumbered(),
    ),
    TechniqueExample.good(
      slug: 'good-material',
      title: 'List of Material list tiles',
      variant: ExampleVariant.material,
      builder: (_) => const GoodMaterial(),
    ),
    TechniqueExample.good(
      slug: 'good-cupertino',
      title: 'Cupertino list section',
      variant: ExampleVariant.cupertino,
      builder: (_) => const GoodCupertino(),
    ),
    TechniqueExample.bad(
      slug: 'bad-one-text',
      title: 'List in one text',
      variant: ExampleVariant.widgets,
      defect: 'The items are read as one paragraph, not as a list.',
      builder: (_) => const BadOneText(),
    ),
    TechniqueExample.bad(
      slug: 'bad-no-list',
      title: 'Lines with no list role',
      variant: ExampleVariant.widgets,
      defect: 'Nothing says that the lines are a list.',
      builder: (_) => const BadNoList(),
    ),
    TechniqueExample.bad(
      slug: 'bad-tile-in-item',
      title: 'List tiles merged into their items',
      variant: ExampleVariant.material,
      defect: 'On the web each tile is a list item and not a button.',
      builder: (_) => const BadTileInItem(),
    ),
    TechniqueExample.bad(
      slug: 'bad-lazy-list',
      title: 'Long list in a ListView',
      variant: ExampleVariant.widgets,
      defect: 'On Android and the web nothing says that it is a list.',
      builder: (_) => const BadLazyList(),
    ),
  ],
);
