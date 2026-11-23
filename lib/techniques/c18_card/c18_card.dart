import '../../catalog/technique.dart';
import 'examples.dart';

/// C18 Card. Spec: docs/specs/C18-card.md. Doc: docs/techniques/C18.md.
final c18Card = Technique(
  id: 'C18',
  title: 'Card',
  group: TechniqueGroup.components,
  summary:
      'A card\'s heading, text, picture, and actions are each exposed as '
      'what they are; a card that is one control is a button named by its '
      'text; and an action or link in a card says what it acts on.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(),
    AppPlatform.ios: PlatformStatus.applies(),
    AppPlatform.web: PlatformStatus.applies(),
  },
  wcag: const [
    WcagCriterion('1.3.1', 'Info and Relationships', 'info-and-relationships'),
    WcagCriterion(
      '2.4.4',
      'Link Purpose (In Context)',
      'link-purpose-in-context',
    ),
  ],
  sources: const [
    SourceLink(
      'iOS SwiftUI: Cards',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/Cards.md',
    ),
    SourceLink(
      'MDN: The article element',
      'https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/article',
    ),
    SourceLink(
      'WCAG failure F63: link context in content not related to the link',
      'https://www.w3.org/WAI/WCAG22/Techniques/failures/F63',
    ),
    SourceLink(
      'Understanding 2.4.4 Link Purpose (In Context)',
      'https://www.w3.org/WAI/WCAG22/Understanding/link-purpose-in-context.html',
    ),
    SourceLink(
      'Flutter API: Card.semanticContainer',
      'https://api.flutter.dev/flutter/material/Card/semanticContainer.html',
    ),
    SourceLink(
      'Flutter API: ListTile',
      'https://api.flutter.dev/flutter/material/ListTile-class.html',
    ),
    SourceLink(
      'Flutter API: Text.semanticsLabel',
      'https://api.flutter.dev/flutter/widgets/Text/semanticsLabel.html',
    ),
    SourceLink(
      'Flutter API: Semantics.headingLevel',
      'https://api.flutter.dev/flutter/widgets/Semantics/headingLevel.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-material',
      title: 'Material card with separate parts',
      variant: ExampleVariant.material,
      builder: (_) => const GoodMaterial(),
    ),
    TechniqueExample.good(
      slug: 'good-tappable',
      title: 'Material card that is one control',
      variant: ExampleVariant.material,
      builder: (_) => const GoodTappable(),
    ),
    TechniqueExample.good(
      slug: 'good-cupertino',
      title: 'Card in Cupertino style',
      variant: ExampleVariant.cupertino,
      builder: (_) => const GoodCupertino(),
    ),
    TechniqueExample.bad(
      slug: 'bad-default-container',
      title: 'Card left as one container',
      variant: ExampleVariant.material,
      defect: 'The heading and the text are read as one heading.',
      builder: (_) => const BadDefaultContainer(),
    ),
    TechniqueExample.bad(
      slug: 'bad-heading-button',
      title: 'Tappable card with a heading',
      variant: ExampleVariant.material,
      defect: 'On the web the card is a heading and not a button.',
      builder: (_) => const BadHeadingButton(),
    ),
    TechniqueExample.bad(
      slug: 'bad-ink-well',
      title: 'Tappable card with an InkWell',
      variant: ExampleVariant.material,
      defect: 'On Android and iOS the card is not a button.',
      builder: (_) => const BadInkWell(),
    ),
    TechniqueExample.bad(
      slug: 'bad-read-more',
      title: 'Card with a "Read more" link',
      variant: ExampleVariant.material,
      defect: 'The link is named "Read more", and the heading that says what it reads more of is not related to it.',
      builder: (_) => const BadReadMore(),
    ),
  ],
);
