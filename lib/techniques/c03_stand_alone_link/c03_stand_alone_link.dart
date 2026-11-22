import '../../catalog/technique.dart';
import 'examples.dart';

/// C03 Stand-alone link. Spec: docs/specs/C03-stand-alone-link.md.
/// Doc: docs/techniques/C03.md.
final c03StandAloneLink = Technique(
  id: 'C03',
  title: 'Stand-alone link',
  group: TechniqueGroup.components,
  summary:
      'A link on its own has the link role, a name that says where it goes, '
      'and is followed by touch, keyboard, and screen reader, once.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(),
    AppPlatform.ios: PlatformStatus.applies(),
    AppPlatform.web: PlatformStatus.applies(),
  },
  wcag: const [
    WcagCriterion(
      '2.4.4',
      'Link Purpose (In Context)',
      'link-purpose-in-context',
    ),
    WcagCriterion('4.1.2', 'Name, Role, Value', 'name-role-value'),
  ],
  sources: const [
    SourceLink(
      'iOS SwiftUI: Links',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/Links.md',
    ),
    SourceLink(
      'Android Compose: Stand-alone Links',
      'https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/components/StandAloneLinks.md',
    ),
    SourceLink(
      'ARIA Authoring Practices Guide: Link pattern',
      'https://www.w3.org/WAI/ARIA/apg/patterns/link/',
    ),
    SourceLink(
      'MDN: The a element',
      'https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/a',
    ),
    SourceLink(
      'WCAG failure F89: no accessible name for an image that is the only content of a link',
      'https://www.w3.org/WAI/WCAG22/Techniques/failures/F89',
    ),
    SourceLink(
      'WCAG failure F84 (of 2.4.9): a non-specific link such as "read more"',
      'https://www.w3.org/WAI/WCAG22/Techniques/failures/F84',
    ),
    SourceLink(
      'Flutter API: SemanticsProperties.link',
      'https://api.flutter.dev/flutter/semantics/SemanticsProperties/link.html',
    ),
    SourceLink(
      'Flutter API: SemanticsProperties.linkUrl',
      'https://api.flutter.dev/flutter/semantics/SemanticsProperties/linkUrl.html',
    ),
    SourceLink(
      'Flutter API: DoNothingAndStopPropagationIntent',
      'https://api.flutter.dev/flutter/widgets/DoNothingAndStopPropagationIntent-class.html',
    ),
    SourceLink(
      'Flutter API: FocusableActionDetector',
      'https://api.flutter.dev/flutter/widgets/FocusableActionDetector-class.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-material',
      title: 'Material link',
      variant: ExampleVariant.material,
      customSolution:
          'A link built by hand: Semantics(link: true, linkUrl:) round an '
          'InkWell, with key bindings for the web and a focus ring of its '
          'own; Flutter has no link widget (FL-221).',
      builder: (_) => const GoodMaterial(),
    ),
    TechniqueExample.good(
      slug: 'good-cupertino',
      title: 'Cupertino link',
      variant: ExampleVariant.cupertino,
      customSolution:
          'A link built by hand round a CupertinoListTile, with focus, keys, '
          'and the link role from FocusableActionDetector and Semantics; '
          'Flutter has no link widget (FL-221) and the tile takes no focus '
          '(FL-400).',
      builder: (_) => const GoodCupertino(),
    ),
    TechniqueExample.good(
      slug: 'good-custom',
      title: 'Link built from Semantics',
      variant: ExampleVariant.widgets,
      customSolution:
          'A link built from the widgets layer: Semantics(link: true, '
          'linkUrl:), FocusableActionDetector, and a GestureDetector; Flutter '
          'has no link widget (FL-221).',
      builder: (_) => const GoodCustom(),
    ),
    TechniqueExample.good(
      slug: 'good-image-link',
      title: 'Picture link named on the link',
      variant: ExampleVariant.material,
      customSolution:
          'The hand-built link of good-material round a picture, named on the '
          'link; Flutter has no link widget (FL-221).',
      builder: (_) => const GoodImageLink(),
    ),
    TechniqueExample.bad(
      slug: 'bad-vague-text',
      title: 'Link that says "Read more"',
      variant: ExampleVariant.material,
      defect: 'The link says "Read more", which does not say where it goes.',
      builder: (_) => const BadVagueText(),
    ),
    TechniqueExample.bad(
      slug: 'bad-tap-handler',
      title: 'Underlined text with a tap handler',
      variant: ExampleVariant.widgets,
      defect: 'It looks like a link but is not one: no link role, and a keyboard cannot reach it.',
      builder: (_) => const BadTapHandler(),
    ),
    TechniqueExample.bad(
      slug: 'bad-no-address',
      title: 'Link with no address',
      variant: ExampleVariant.material,
      defect: 'The link has no address: on Android it is read as a button, and on the web its element is an <a> with no href.',
      builder: (_) => const BadNoAddress(),
    ),
    TechniqueExample.bad(
      slug: 'bad-image-no-name',
      title: 'Picture link with no name',
      variant: ExampleVariant.material,
      defect: 'The picture link has no name, so nothing says where it goes.',
      builder: (_) => const BadImageNoName(),
    ),
    TechniqueExample.bad(
      slug: 'bad-label-on-image',
      title: 'Name put on the picture inside the link',
      variant: ExampleVariant.material,
      defect: 'The name is on the picture, not the link: on Android and iOS the link has no name.',
      builder: (_) => const BadLabelOnImage(),
    ),
    TechniqueExample.bad(
      slug: 'bad-cupertino-button',
      title: 'Link round a Cupertino button',
      variant: ExampleVariant.cupertino,
      defect: 'The link is a button as well: VoiceOver on iOS says "Button, Link", and TalkBack says "Button".',
      builder: (_) => const BadCupertinoButton(),
    ),
    TechniqueExample.bad(
      slug: 'bad-app-also-follows',
      title: 'Link the app follows on the web too',
      variant: ExampleVariant.material,
      defect: 'On the web a click or Enter on it does nothing, and a click with no pointer events, which assistive technology can send, opens the page twice.',
      builder: (_) => const BadAppAlsoFollows(),
    ),
  ],
);
