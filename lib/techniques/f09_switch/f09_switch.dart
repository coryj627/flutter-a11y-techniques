import '../../catalog/technique.dart';
import 'examples.dart';

/// F09 Switch.
/// Spec: docs/specs/F09-switch.md.
/// Doc: docs/techniques/F09.md.
final f09Switch = Technique(
  id: 'F09',
  title: 'Switch',
  group: TechniqueGroup.forms,
  summary:
      'A switch and its label are one control with a name that does not '
      'change, the switch role, and a state that is on or off. Switches that '
      'answer one question are grouped under that question.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(
      note:
          'TalkBack 17 says "checked" as well as "on" for a switch that is '
          'on; for a native switch it says "on" only (limitation FL-100).',
    ),
    AppPlatform.ios: PlatformStatus.applies(
      note:
          'A switch built with Semantics(toggled:) needs enabled: true as '
          'well, or VoiceOver reads it as dimmed (limitation FL-033).',
    ),
    AppPlatform.web: PlatformStatus.applies(
      note:
          'Enter does not toggle a CupertinoSwitch; Space does, which is what '
          'the APG pattern requires (limitation FL-002).',
    ),
  },
  wcag: const [
    WcagCriterion('1.3.1', 'Info and Relationships', 'info-and-relationships'),
    WcagCriterion('4.1.2', 'Name, Role, Value', 'name-role-value'),
  ],
  sources: const [
    SourceLink(
      'iOS SwiftUI: Toggles',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/Toggles.md',
    ),
    SourceLink(
      'Android Compose: Switch Controls',
      'https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/components/SwitchControls.md',
    ),
    SourceLink(
      'ARIA APG: Switch pattern',
      'https://www.w3.org/WAI/ARIA/apg/patterns/switch/',
    ),
    SourceLink(
      'MDN: ARIA switch role',
      'https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Reference/Roles/switch_role',
    ),
    SourceLink(
      'Flutter API: SwitchListTile',
      'https://api.flutter.dev/flutter/material/SwitchListTile-class.html',
    ),
    SourceLink(
      'Flutter API: CupertinoSwitch',
      'https://api.flutter.dev/flutter/cupertino/CupertinoSwitch-class.html',
    ),
    SourceLink(
      'Flutter API: SemanticsProperties.toggled',
      'https://api.flutter.dev/flutter/semantics/SemanticsProperties/toggled.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-tile',
      title: 'Switch and label as one control',
      variant: ExampleVariant.material,
      builder: (_) => const GoodTile(),
    ),
    TechniqueExample.good(
      slug: 'good-cupertino',
      title: 'Cupertino switch in a merged list tile',
      variant: ExampleVariant.cupertino,
      builder: (_) => const GoodCupertino(),
    ),
    TechniqueExample.good(
      slug: 'good-custom',
      title: 'Custom switch with an on or off state',
      variant: ExampleVariant.widgets,
      customSolution:
          'A switch drawn by hand, with its role, state, focus, keys, and '
          'focus ring built from Semantics and FocusableActionDetector.',
      builder: (_) => const GoodCustom(),
    ),
    TechniqueExample.good(
      slug: 'good-group',
      title: 'Group of switches with a label',
      variant: ExampleVariant.material,
      builder: (_) => const GoodGroup(),
    ),
    TechniqueExample.bad(
      slug: 'bad-unlabelled',
      title: 'Switch with text beside it, not joined',
      variant: ExampleVariant.material,
      defect: 'The switch has no name: a screen reader says "switch, off" and reads the text as a separate element. A tap on the text does nothing.',
      builder: (_) => const BadUnlabelled(),
    ),
    TechniqueExample.bad(
      slug: 'bad-tile-not-merged',
      title: 'List tile with a switch, not merged',
      variant: ExampleVariant.material,
      defect: 'The row is a button called "Bluetooth" that never says on or off. The switch inside it has no name: a second stop on Android and iOS, and not reached at all by VoiceOver on the web.',
      builder: (_) => const BadTileNotMerged(),
    ),
    TechniqueExample.bad(
      slug: 'bad-label-changes',
      title: 'Switch whose label says its state',
      variant: ExampleVariant.material,
      defect: 'The name is "Bluetooth off", then "Bluetooth on": it changes every time the switch does, and the state is read twice.',
      builder: (_) => const BadLabelChanges(),
    ),
    TechniqueExample.bad(
      slug: 'bad-no-state',
      title: 'Custom switch exposed as a button',
      variant: ExampleVariant.widgets,
      defect: 'A screen reader says "button" and never says whether the switch is on.',
      builder: (_) => const BadNoState(),
    ),
  ],
);
