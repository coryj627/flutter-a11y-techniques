import '../../catalog/technique.dart';
import 'examples.dart';

/// C01 Button. Spec: docs/specs/C01-button.md. Doc: docs/techniques/C01.md.
final c01Button = Technique(
  id: 'C01',
  title: 'Button',
  group: TechniqueGroup.components,
  summary:
      'A button exposes a name that describes its function, the button role, '
      'and its enabled or disabled state, and can be operated by touch, '
      'keyboard, and assistive technology.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(),
    AppPlatform.ios: PlatformStatus.applies(),
    AppPlatform.web: PlatformStatus.applies(),
  },
  wcag: const [
    WcagCriterion('2.1.1', 'Keyboard', 'keyboard'),
    WcagCriterion('2.4.6', 'Headings and Labels', 'headings-and-labels'),
    WcagCriterion('2.5.2', 'Pointer Cancellation', 'pointer-cancellation'),
    WcagCriterion('2.5.3', 'Label in Name', 'label-in-name'),
    WcagCriterion('4.1.2', 'Name, Role, Value', 'name-role-value'),
  ],
  sources: const [
    SourceLink(
      'CVS Health iOS SwiftUI: Buttons',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/Buttons.md',
    ),
    SourceLink(
      'CVS Health Android Compose: Interactive Control Labels',
      'https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/interactions/InteractiveControlLabels.md',
    ),
    SourceLink(
      'CVS Health Android View: Focusable, Clickable Controls',
      'https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/basics/FocusableClickableControls.md',
    ),
    SourceLink(
      'ARIA Authoring Practices Guide: Button pattern',
      'https://www.w3.org/WAI/ARIA/apg/patterns/button/',
    ),
    SourceLink(
      'MDN: The button element',
      'https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/button',
    ),
    SourceLink(
      'Flutter: Accessibility',
      'https://docs.flutter.dev/ui/accessibility',
    ),
    SourceLink(
      'Flutter API: Semantics',
      'https://api.flutter.dev/flutter/widgets/Semantics-class.html',
    ),
    SourceLink(
      'Flutter API: Text.semanticsLabel',
      'https://api.flutter.dev/flutter/widgets/Text/semanticsLabel.html',
    ),
    SourceLink(
      'Flutter API: IconButton.tooltip',
      'https://api.flutter.dev/flutter/material/IconButton/tooltip.html',
    ),
    SourceLink(
      'Flutter API: FocusableActionDetector',
      'https://api.flutter.dev/flutter/widgets/FocusableActionDetector-class.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-text',
      title: 'Text buttons',
      variant: ExampleVariant.material,
      builder: (_) => const GoodTextButtons(),
    ),
    TechniqueExample.good(
      slug: 'good-icon',
      title: 'Icon button with a name',
      variant: ExampleVariant.material,
      builder: (_) => const GoodIconButton(),
    ),
    TechniqueExample.good(
      slug: 'good-disabled',
      title: 'Disabled button',
      variant: ExampleVariant.material,
      builder: (_) => const GoodDisabledButton(),
    ),
    TechniqueExample.good(
      slug: 'good-unique-names',
      title: 'Repeated buttons with unique names',
      variant: ExampleVariant.material,
      builder: (_) => const GoodUniqueNames(),
    ),
    TechniqueExample.good(
      slug: 'good-cupertino',
      title: 'Cupertino buttons',
      variant: ExampleVariant.cupertino,
      builder: (_) => const GoodCupertinoButtons(),
    ),
    TechniqueExample.good(
      slug: 'good-custom',
      title: 'Custom button',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodCustomButton(),
    ),
    TechniqueExample.bad(
      slug: 'bad-unlabelled-icon',
      title: 'Icon button with no name',
      variant: ExampleVariant.material,
      defect: 'The icon button has no accessible name.',
      builder: (_) => const BadUnlabelledIcon(),
    ),
    TechniqueExample.bad(
      slug: 'bad-gesture-only',
      title: 'Tap target that is not a button',
      variant: ExampleVariant.widgets,
      defect:
          'The control has no button role and cannot be reached or activated '
          'with a keyboard.',
      builder: (_) => const BadGestureOnly(),
    ),
    TechniqueExample.bad(
      slug: 'bad-role-in-name',
      title: 'Role repeated in the name',
      variant: ExampleVariant.material,
      defect: 'The name is "Close button", so the role is announced twice.',
      builder: (_) => const BadRoleInName(),
    ),
    TechniqueExample.bad(
      slug: 'bad-duplicate-names',
      title: 'Repeated buttons with the same name',
      variant: ExampleVariant.material,
      defect: 'Three buttons are all named "Edit".',
      builder: (_) => const BadDuplicateNames(),
    ),
    TechniqueExample.bad(
      slug: 'bad-name-mismatch',
      title: 'Name does not match the visible text',
      variant: ExampleVariant.material,
      defect:
          'The visible text is "Edit" but the accessible name is '
          '"Change username".',
      builder: (_) => const BadNameMismatch(),
    ),
    TechniqueExample.bad(
      slug: 'bad-fake-disabled',
      title: 'Button that only looks disabled',
      variant: ExampleVariant.material,
      defect:
          'The button looks disabled but is still enabled and is reported as '
          'enabled.',
      builder: (_) => const BadFakeDisabled(),
    ),
    TechniqueExample.bad(
      slug: 'bad-cupertino-disabled',
      title: 'Disabled Cupertino button with no disabled state',
      variant: ExampleVariant.cupertino,
      defect:
          'Flutter limitation: a disabled CupertinoButton looks disabled but '
          'does not report a disabled state to assistive technology.',
      builder: (_) => const BadCupertinoDisabled(),
    ),
  ],
);
