import '../../catalog/technique.dart';
import 'examples.dart';

/// C06 Disclosure. Spec: docs/specs/C06-disclosure.md.
/// Doc: docs/techniques/C06.md.
final c06Disclosure = Technique(
  id: 'C06',
  title: 'Disclosure',
  group: TechniqueGroup.components,
  summary:
      'A control that shows and hides one section is a button, named by what '
      'it shows, that says whether the section is open, and that Enter and '
      'Space operate. Flutter\'s ExpansionTile is a button on Android and '
      'iOS only with internalAddSemanticForOnTap, which its documentation calls '
      '"a temporary flag", and it says whether it is open only in words, '
      'never as a state (FL-264).',
  platforms: const {
    AppPlatform.android: PlatformStatus.limitation(
      'ExpansionTile with internalAddSemanticForOnTap ("a temporary flag", '
      'its documentation says) is a button, but Flutter gives it no expanded '
      'state: "Collapsed" or "Expanded" is only the end of its name, which '
      'TalkBack reads (FL-264; measured on Android 17). There is no '
      'workaround with the widget\'s own parameters.',
    ),
    AppPlatform.ios: PlatformStatus.limitation(
      'ExpansionTile with internalAddSemanticForOnTap ("a temporary flag", '
      'its documentation says) is a button, but iOS gets no expanded state '
      'from Flutter (FL-260): VoiceOver hears "Collapsed double tap to '
      'expand" from the tile\'s hint, not a state (FL-264). There is no '
      'workaround with the widget\'s own parameters.',
    ),
    AppPlatform.web: PlatformStatus.limitation(
      'ExpansionTile is a button with no aria-expanded: the state is only '
      'its accessible description, "Collapsed double tap to expand" in a '
      'browser on macOS and "Collapsed" where Flutter finds Linux or Windows '
      '(FL-264). There '
      'is no workaround with the widget\'s own parameters; a native details '
      'element in an HtmlElementView was not tried.',
    ),
  },
  wcag: const [WcagCriterion('4.1.2', 'Name, Role, Value', 'name-role-value')],
  sources: const [
    SourceLink(
      'ARIA Authoring Practices Guide: Disclosure (Show/Hide) pattern',
      'https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/',
    ),
    SourceLink(
      'MDN: <details>',
      'https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/details',
    ),
    SourceLink(
      'MDN: <summary>',
      'https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/summary',
    ),
    SourceLink(
      'Flutter API: ExpansionTile',
      'https://api.flutter.dev/flutter/material/ExpansionTile-class.html',
    ),
    SourceLink(
      'Flutter API: ExpansionTile.internalAddSemanticForOnTap',
      'https://api.flutter.dev/flutter/material/ExpansionTile/internalAddSemanticForOnTap.html',
    ),
    SourceLink(
      'Flutter API: ExpandIcon',
      'https://api.flutter.dev/flutter/material/ExpandIcon-class.html',
    ),
    SourceLink(
      'Flutter API: CupertinoExpansionTile',
      'https://api.flutter.dev/flutter/cupertino/CupertinoExpansionTile-class.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-material',
      title: 'ExpansionTile as a button',
      variant: ExampleVariant.material,
      builder: (_) => const GoodMaterial(),
    ),
    TechniqueExample.bad(
      slug: 'bad-expansion-tile',
      title: 'ExpansionTile as it comes',
      variant: ExampleVariant.material,
      defect: 'On Android and iOS the control is not a button.',
      builder: (_) => const BadExpansionTile(),
    ),
    TechniqueExample.bad(
      slug: 'bad-expand-icon',
      title: 'ExpandIcon beside a label',
      variant: ExampleVariant.material,
      defect: 'Nothing says whether the section is open, not even in words.',
      builder: (_) => const BadExpandIcon(),
    ),
    TechniqueExample.bad(
      slug: 'bad-cupertino-expansion-tile',
      title: 'CupertinoExpansionTile',
      variant: ExampleVariant.cupertino,
      defect: 'A keyboard cannot reach the control, so it opens nothing.',
      builder: (_) => const BadCupertinoExpansionTile(),
    ),
  ],
);
