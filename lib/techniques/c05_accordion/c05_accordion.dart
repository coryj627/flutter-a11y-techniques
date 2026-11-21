import '../../catalog/technique.dart';
import 'examples.dart';

/// C05 Accordion. Spec: docs/specs/C05-accordion.md.
/// Doc: docs/techniques/C05.md.
final c05Accordion = Technique(
  id: 'C05',
  title: 'Accordion',
  group: TechniqueGroup.components,
  summary:
      'Each header of an accordion is a heading and a button that says '
      'whether its section is open; a closed section is not read or focused, '
      'and an open one comes straight after its header.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(
      note:
          'The expanded state reaches Android 16 and later only (FL-261, '
          'source read; not measured before 16): before that, the headers '
          'have only their tap hint, "expand" or "collapse".',
    ),
    AppPlatform.ios: PlatformStatus.applies(
      note:
          'Flutter does not pass the expanded state to iOS (FL-260): the '
          'examples put it in the value on iOS.',
    ),
    AppPlatform.web: PlatformStatus.applies(),
  },
  wcag: const [
    WcagCriterion('4.1.2', 'Name, Role, Value', 'name-role-value'),
    WcagCriterion('1.3.1', 'Info and Relationships', 'info-and-relationships'),
  ],
  sources: const [
    SourceLink(
      'iOS SwiftUI: Accordions',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/Accordions.md',
    ),
    SourceLink(
      'Android View: Accordion Controls',
      'https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/componenttypes/AccordionControls.md',
    ),
    SourceLink(
      'Android Compose: Accordion Controls',
      'https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/components/AccordionControls.md',
    ),
    SourceLink(
      'ARIA Authoring Practices Guide: Accordion pattern',
      'https://www.w3.org/WAI/ARIA/apg/patterns/accordion/',
    ),
    SourceLink(
      'Flutter API: SemanticsProperties.expanded',
      'https://api.flutter.dev/flutter/semantics/SemanticsProperties/expanded.html',
    ),
    SourceLink(
      'Flutter API: SemanticsProperties.headingLevel',
      'https://api.flutter.dev/flutter/semantics/SemanticsProperties/headingLevel.html',
    ),
    SourceLink(
      'Flutter API: FocusableActionDetector',
      'https://api.flutter.dev/flutter/widgets/FocusableActionDetector-class.html',
    ),
    SourceLink(
      'Flutter API: ExpansionTile',
      'https://api.flutter.dev/flutter/material/ExpansionTile-class.html',
    ),
    SourceLink(
      'Flutter API: CupertinoExpansionTile',
      'https://api.flutter.dev/flutter/cupertino/CupertinoExpansionTile-class.html',
    ),
    SourceLink(
      'Flutter API: Expansible',
      'https://api.flutter.dev/flutter/widgets/Expansible-class.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-material',
      title: 'Material accordion',
      variant: ExampleVariant.material,
      builder: (_) => const GoodMaterial(),
    ),
    TechniqueExample.good(
      slug: 'good-cupertino',
      title: 'Cupertino accordion',
      variant: ExampleVariant.cupertino,
      builder: (_) => const GoodCupertino(),
    ),
    TechniqueExample.good(
      slug: 'good-custom',
      title: 'Accordion built from Semantics',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodCustom(),
    ),
    TechniqueExample.bad(
      slug: 'bad-no-state',
      title: 'Headers with no state',
      variant: ExampleVariant.widgets,
      defect: 'Nothing says whether a section is open or closed.',
      builder: (_) => const BadNoState(),
    ),
    TechniqueExample.bad(
      slug: 'bad-heading-on-button',
      title: 'Heading on the button',
      variant: ExampleVariant.widgets,
      defect:
          'On the web each header is a heading only: not a button, and with '
          'no state.',
      builder: (_) => const BadHeadingOnButton(),
    ),
    TechniqueExample.bad(
      slug: 'bad-no-heading',
      title: 'Headers that are not headings',
      variant: ExampleVariant.widgets,
      defect: 'The headers look like headings but are not headings.',
      builder: (_) => const BadNoHeading(),
    ),
    TechniqueExample.bad(
      slug: 'bad-hidden-panel',
      title: 'Closed sections kept hidden',
      variant: ExampleVariant.widgets,
      defect: 'Tab goes into closed sections, to buttons that are not shown.',
      builder: (_) => const BadHiddenPanel(),
    ),
    TechniqueExample.bad(
      slug: 'bad-expansion-tile',
      title: 'Material ExpansionTile',
      variant: ExampleVariant.material,
      defect:
          'The headers have no open or closed state, and on Android and iOS '
          'are not buttons.',
      builder: (_) => const BadExpansionTile(),
    ),
    TechniqueExample.bad(
      slug: 'bad-cupertino-expansion-tile',
      title: 'CupertinoExpansionTile',
      variant: ExampleVariant.cupertino,
      defect: 'A keyboard cannot reach the headers, so it opens nothing.',
      builder: (_) => const BadCupertinoExpansionTile(),
    ),
  ],
);
