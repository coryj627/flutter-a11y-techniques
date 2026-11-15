import '../../catalog/technique.dart';
import 'examples.dart';

/// S13 Roles and traits. Spec: docs/specs/S13-roles-and-traits.md.
/// Doc: docs/techniques/S13.md.
final s13RolesAndTraits = Technique(
  id: 'S13',
  title: 'Roles and traits',
  group: TechniqueGroup.semantics,
  summary:
      'A control says what kind of control it is. The SDK\'s widgets already '
      'do; a control built by hand gets the role that matches what it does, '
      'and the action that goes with it.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(),
    AppPlatform.ios: PlatformStatus.applies(),
    AppPlatform.web: PlatformStatus.applies(),
  },
  wcag: const [WcagCriterion('4.1.2', 'Name, Role, Value', 'name-role-value')],
  sources: const [
    SourceLink(
      'iOS SwiftUI: Accessibility Traits',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/AccessibilityTraits.md',
    ),
    SourceLink(
      'iOS SwiftUI: Accessibility Responds To User Interaction',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/AccessibilityRespondsToUserInteraction.md',
    ),
    SourceLink(
      'WCAG technique ARIA4: using a role to expose the role of a component',
      'https://www.w3.org/WAI/WCAG22/Techniques/aria/ARIA4',
    ),
    SourceLink(
      'WCAG failure F59: a control made by script with no role',
      'https://www.w3.org/WAI/WCAG22/Techniques/failures/F59',
    ),
    SourceLink(
      'ARIA Authoring Practices Guide: Read Me First',
      'https://www.w3.org/WAI/ARIA/apg/practices/read-me-first/',
    ),
    SourceLink(
      'MDN: WAI-ARIA roles',
      'https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Reference/Roles',
    ),
    SourceLink(
      'Apple: UIAccessibilityTraits',
      'https://developer.apple.com/documentation/uikit/uiaccessibilitytraits',
    ),
    SourceLink(
      'Android: Role in Compose semantics',
      'https://developer.android.com/reference/kotlin/androidx/compose/ui/semantics/Role',
    ),
    SourceLink(
      'Flutter API: Semantics',
      'https://api.flutter.dev/flutter/widgets/Semantics-class.html',
    ),
    SourceLink(
      'Flutter API: SemanticsProperties',
      'https://api.flutter.dev/flutter/semantics/SemanticsProperties-class.html',
    ),
    SourceLink(
      'Flutter API: GestureDetector.excludeFromSemantics',
      'https://api.flutter.dev/flutter/widgets/GestureDetector/excludeFromSemantics.html',
    ),
    SourceLink(
      'Flutter API: FocusableActionDetector',
      'https://api.flutter.dev/flutter/widgets/FocusableActionDetector-class.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-standard',
      title: 'Material controls with the roles they come with',
      variant: ExampleVariant.material,
      builder: (_) => const GoodStandard(),
    ),
    TechniqueExample.good(
      slug: 'good-cupertino',
      title: 'Cupertino controls with the roles they come with',
      variant: ExampleVariant.cupertino,
      builder: (_) => const GoodCupertino(),
    ),
    TechniqueExample.good(
      slug: 'good-custom-button',
      title: 'Custom control given the button role',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodCustomButton(),
    ),
    TechniqueExample.good(
      slug: 'good-custom-switch',
      title: 'Custom on/off control given the switch role',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodCustomSwitch(),
    ),
    TechniqueExample.good(
      slug: 'good-selected',
      title: 'Custom buttons that mark the chosen one as selected',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodSelected(),
    ),
    TechniqueExample.bad(
      slug: 'bad-no-role',
      title: 'Custom control with no role',
      variant: ExampleVariant.widgets,
      defect: 'The control has no role, so on Android and iOS a screen reader reads its name and does not say it is a button.',
      builder: (_) => const BadNoRole(),
    ),
    TechniqueExample.bad(
      slug: 'bad-wrong-role',
      title: 'Switch that says it is a button',
      variant: ExampleVariant.widgets,
      defect: 'The on/off control has the button role, so a screen reader never says whether it is on.',
      builder: (_) => const BadWrongRole(),
    ),
    TechniqueExample.bad(
      slug: 'bad-role-on-text',
      title: 'Button role on text that does nothing',
      variant: ExampleVariant.widgets,
      defect: 'Plain text is announced as a button, and activating it does nothing.',
      builder: (_) => const BadRoleOnText(),
    ),
    TechniqueExample.bad(
      slug: 'bad-role-on-standard',
      title: 'Button role added to a real button',
      variant: ExampleVariant.material,
      defect: 'The added role makes a second button with no name around the real one on Android and on the web.',
      builder: (_) => const BadRoleOnStandard(),
    ),
    TechniqueExample.bad(
      slug: 'bad-action-hidden',
      title: 'Button whose tap is hidden from assistive technology',
      variant: ExampleVariant.widgets,
      defect: 'The button has no action in the semantics tree: on Android assistive technology has nothing to call, and on the web a click sent to the element does nothing.',
      builder: (_) => const BadActionHidden(),
    ),
    TechniqueExample.bad(
      slug: 'bad-switch-not-enabled',
      title: 'Custom switch that iOS reads as dimmed',
      variant: ExampleVariant.widgets,
      defect: 'The switch does not say it is enabled, so VoiceOver on iOS reads a working switch as dimmed.',
      builder: (_) => const BadSwitchNotEnabled(),
    ),
  ],
);
