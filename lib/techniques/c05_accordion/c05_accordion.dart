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
      'and an open one comes straight after its header. No Flutter accordion '
      'widget does this through its own parameters (FL-264, FL-265, FL-267), '
      'so the good examples are built by hand.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(
      note:
          'The expanded state reaches Android 16 and later only (FL-261, '
          'source read). Not measured below Android 16: there, by the engine '
          'source, the headers have only their tap hint, "expand" or '
          '"collapse".',
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
      customSolution:
          'Headers built by hand: a ListTile inside Semantics(button: true, '
          'expanded:) with a heading, an iOS value, and a focus ring of their '
          'own, and panels built only while open; ExpansionTile has no '
          'expanded state and, on Android and iOS, no button role (FL-264).',
    ),
    TechniqueExample.good(
      slug: 'good-cupertino',
      title: 'Cupertino accordion',
      variant: ExampleVariant.cupertino,
      builder: (_) => const GoodCupertino(),
      customSolution:
          'Headers built by hand: a CupertinoListTile given keyboard focus by '
          'FocusableActionDetector, inside Semantics(button: true, expanded:) '
          'with a heading, an iOS value, and a focus ring of their own; '
          'CupertinoExpansionTile takes no keyboard focus and has no state '
          '(FL-265).',
    ),
    TechniqueExample.good(
      slug: 'good-custom',
      title: 'Accordion built from Semantics',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodCustom(),
      customSolution:
          'Headers built by hand from the widgets layer: a GestureDetector and '
          'FocusableActionDetector inside Semantics(button: true, expanded:) '
          'with a heading and an iOS value, and panels built only while open; '
          'no Flutter accordion widget gives the role and the state (FL-264, '
          'FL-265).',
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
      defect: 'On Android and iOS the headers are not buttons.',
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
