import '../../catalog/technique.dart';
import 'examples.dart';

/// C12 Tooltip. Spec: docs/specs/C12-tooltip.md. Doc: docs/techniques/C12.md.
final c12Tooltip = Technique(
  id: 'C12',
  title: 'Tooltip',
  group: TechniqueGroup.components,
  summary:
      'A tooltip shows on hover and on a long press; the pointer can move '
      'onto it; Escape hides it; it stays until then; and its words reach a '
      'screen reader as the control\'s name or description. Flutter\'s '
      'tooltip does not show on keyboard focus.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(
      note:
          'A Flutter tooltip does not show on keyboard focus (FL-248), so '
          'good-description fails 2.1.1 for its description when used with '
          'a keyboard. While shown, its text is a node of its own (FL-249).',
    ),
    AppPlatform.ios: PlatformStatus.applies(
      note:
          'A Flutter tooltip does not show on keyboard focus (FL-248), so '
          'good-description fails 2.1.1 for its description when used with '
          'a keyboard. A tooltip on a node with nothing else is not reached '
          'by VoiceOver (FL-252).',
    ),
    AppPlatform.web: PlatformStatus.applies(
      note:
          'While no element of the page has focus, Escape does not hide a '
          'tooltip (FL-482), so the good examples fail 1.4.13 in that '
          'state. A tooltip does not show on keyboard focus (FL-248), so '
          'good-description fails 2.1.1 for its description. No workaround '
          'in the SDK.',
    ),
  },
  wcag: const [
    WcagCriterion(
      '1.4.13',
      'Content on Hover or Focus',
      'content-on-hover-or-focus',
    ),
    WcagCriterion('4.1.2', 'Name, Role, Value', 'name-role-value'),
  ],
  sources: const [
    SourceLink(
      'iOS SwiftUI: TipKit',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/TipKit.md',
    ),
    SourceLink(
      'ARIA Authoring Practices Guide: Tooltip pattern',
      'https://www.w3.org/WAI/ARIA/apg/patterns/tooltip/',
    ),
    SourceLink(
      'MDN: The title attribute',
      'https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Global_attributes/title',
    ),
    SourceLink(
      'Understanding 1.4.13 Content on Hover or Focus',
      'https://www.w3.org/WAI/WCAG22/Understanding/content-on-hover-or-focus.html',
    ),
    SourceLink(
      'WCAG failure F95: content shown on hover that is not hoverable',
      'https://www.w3.org/WAI/WCAG22/Techniques/failures/F95',
    ),
    SourceLink(
      'Flutter API: Tooltip',
      'https://api.flutter.dev/flutter/material/Tooltip-class.html',
    ),
    SourceLink(
      'Flutter API: Tooltip.ignorePointer',
      'https://api.flutter.dev/flutter/material/Tooltip/ignorePointer.html',
    ),
    SourceLink(
      'Flutter API: IconButton.tooltip',
      'https://api.flutter.dev/flutter/material/IconButton/tooltip.html',
    ),
    SourceLink(
      'Flutter API: Tooltip.excludeFromSemantics',
      'https://api.flutter.dev/flutter/material/Tooltip/excludeFromSemantics.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-material',
      title: 'Material tooltip',
      variant: ExampleVariant.material,
      builder: (_) => const GoodMaterial(),
    ),
    TechniqueExample.good(
      slug: 'good-cupertino',
      title: 'Tooltip on a Cupertino button',
      variant: ExampleVariant.cupertino,
      builder: (_) => const GoodCupertino(),
    ),
    TechniqueExample.good(
      slug: 'good-description',
      title: 'Tooltip that describes a button',
      variant: ExampleVariant.material,
      builder: (_) => const GoodDescription(),
    ),
    TechniqueExample.bad(
      slug: 'bad-not-hoverable',
      title: 'Tooltip the pointer cannot reach',
      variant: ExampleVariant.material,
      defect: 'The tooltip goes when the pointer moves onto it.',
      builder: (_) => const BadNotHoverable(),
    ),
    TechniqueExample.bad(
      slug: 'bad-hover-only',
      title: 'Information only on hover',
      variant: ExampleVariant.material,
      defect:
          'Only a pointer or a long press shows the rule: not a keyboard, '
          'and not VoiceOver on iOS.',
      builder: (_) => const BadHoverOnly(),
    ),
    TechniqueExample.bad(
      slug: 'bad-repeats-name',
      title: 'Tooltip that repeats the name',
      variant: ExampleVariant.material,
      defect: 'A screen reader reads the name twice.',
      builder: (_) => const BadRepeatsName(),
    ),
    TechniqueExample.bad(
      slug: 'bad-outside-button',
      title: 'Tooltip outside its button',
      variant: ExampleVariant.material,
      defect: 'The button has no name; its tooltip is not on it.',
      builder: (_) => const BadOutsideButton(),
    ),
  ],
);
