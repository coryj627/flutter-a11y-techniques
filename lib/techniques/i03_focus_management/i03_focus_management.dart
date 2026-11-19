import '../../catalog/technique.dart';
import 'examples.dart';

/// I03 Focus management.
/// Spec: docs/specs/I03-focus-management.md.
/// Doc: docs/techniques/I03.md.
final i03FocusManagement = Technique(
  id: 'I03',
  title: 'Focus management',
  group: TechniqueGroup.interaction,
  summary:
      'When a dialog opens, focus goes into it; when it closes, focus goes '
      'back to the control that opened it, or to the next one when that '
      'control is gone; and nothing opens just because a control took '
      'focus.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(),
    AppPlatform.ios: PlatformStatus.applies(),
    AppPlatform.web: PlatformStatus.applies(),
  },
  wcag: const [
    WcagCriterion('2.4.3', 'Focus Order', 'focus-order'),
    WcagCriterion('3.2.1', 'On Focus', 'on-focus'),
  ],
  sources: const [
    SourceLink(
      'iOS: Focus Management',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/FocusManagement.md',
    ),
    SourceLink(
      'WCAG 2.2: Understanding Focus Order',
      'https://www.w3.org/WAI/WCAG22/Understanding/focus-order.html',
    ),
    SourceLink(
      'WCAG 2.2: Understanding On Focus',
      'https://www.w3.org/WAI/WCAG22/Understanding/on-focus.html',
    ),
    SourceLink(
      'WCAG technique F85: dialogs not adjacent to their trigger',
      'https://www.w3.org/WAI/WCAG22/Techniques/failures/F85',
    ),
    SourceLink(
      'Flutter: Understanding Flutter\'s keyboard focus system',
      'https://docs.flutter.dev/ui/interactivity/focus',
    ),
    SourceLink(
      'Flutter API: Route.requestFocus',
      'https://api.flutter.dev/flutter/widgets/Route/requestFocus.html',
    ),
    SourceLink(
      'Flutter API: FocusNode.requestFocus',
      'https://api.flutter.dev/flutter/widgets/FocusNode/requestFocus.html',
    ),
    SourceLink(
      'Flutter API: showGeneralDialog',
      'https://api.flutter.dev/flutter/widgets/showGeneralDialog.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-material',
      title: 'A Material dialog, and focus placed after a removal',
      variant: ExampleVariant.material,
      builder: (_) => const GoodMaterial(),
    ),
    TechniqueExample.good(
      slug: 'good-cupertino',
      title: 'A Cupertino action sheet, and focus placed after a removal',
      variant: ExampleVariant.cupertino,
      builder: (_) => const GoodCupertino(),
    ),
    TechniqueExample.good(
      slug: 'good-widgets',
      title: 'A general dialog that puts focus on Cancel',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodWidgets(),
    ),
    TechniqueExample.bad(
      slug: 'bad-focus-left-behind',
      title: 'A dialog that does not take focus',
      variant: ExampleVariant.material,
      defect:
          'When the dialog opens, focus stays on the Remove button behind '
          'it: Tab goes on to the controls behind the dialog, and reaches '
          'the dialog\'s buttons only after all of them.',
      builder: (_) => const BadFocusLeftBehind(),
    ),
    TechniqueExample.bad(
      slug: 'bad-opens-on-focus',
      title: 'A dialog that opens when its button takes focus',
      variant: ExampleVariant.material,
      defect:
          'Tab onto a Remove button opens the dialog at once, and moves '
          'focus into it, before anything has been pressed.',
      builder: (_) => const BadOpensOnFocus(),
    ),
  ],
);
