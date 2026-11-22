import '../../catalog/technique.dart';
import 'examples.dart';

/// V13 Minimum touch target size.
/// Spec: docs/specs/V13-touch-target-size.md.
/// Doc: docs/techniques/V13.md.
final v13TouchTargetSize = Technique(
  id: 'V13',
  title: 'Minimum touch target size',
  group: TechniqueGroup.visual,
  summary:
      'Every control takes taps over at least 24 by 24 pixels, or is far '
      'enough from the next one; aim for the platforms\' 48 by 48 or 44 by '
      '44. The area that takes taps is what counts, not what is drawn or '
      'what the accessibility tree reports.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(
      note:
          'A control\'s accessibility node can be bigger than the area that '
          'takes taps, and the tap target guidelines in flutter_test read '
          'the node (limitation FL-410).',
    ),
    AppPlatform.ios: PlatformStatus.applies(
      note:
          'A control\'s accessibility node can be bigger than the area that '
          'takes taps, and the tap target guidelines in flutter_test read '
          'the node (limitation FL-410).',
    ),
    AppPlatform.web: PlatformStatus.applies(
      note:
          'In a desktop browser the Material theme adds no padding to '
          'buttons (limitation FL-412), and a click is taken by the '
          'element of the node under it, which can be bigger than the '
          'control (limitation FL-411). A phone\'s browser was only '
          'imitated in Chromium.',
    ),
  },
  wcag: const [
    WcagCriterion('2.5.8', 'Target Size (Minimum)', 'target-size-minimum'),
  ],
  sources: const [
    SourceLink(
      'iOS: Touch Target Size',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/TouchTargetSize.md',
    ),
    SourceLink(
      'Android View: Minimum Touch Target Size',
      'https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/basics/MinimumTouchTargetSize.md',
    ),
    SourceLink(
      'Android Compose: Minimum Touch Target Size',
      'https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/interactions/MinimumTouchTargetSize.md',
    ),
    SourceLink(
      'WCAG: Understanding Target Size (Minimum)',
      'https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html',
    ),
    SourceLink(
      'Flutter API: MaterialTapTargetSize',
      'https://api.flutter.dev/flutter/material/MaterialTapTargetSize.html',
    ),
    SourceLink(
      'Flutter API: CupertinoButton.minimumSize',
      'https://api.flutter.dev/flutter/cupertino/CupertinoButton/minimumSize.html',
    ),
    SourceLink(
      'Flutter API: HitTestBehavior',
      'https://api.flutter.dev/flutter/rendering/HitTestBehavior.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-material',
      title: 'Material icon buttons with their padding',
      variant: ExampleVariant.material,
      builder: (_) => const GoodMaterial(),
    ),
    TechniqueExample.good(
      slug: 'good-cupertino',
      title: 'Cupertino buttons at their minimum size',
      variant: ExampleVariant.cupertino,
      customSolution:
          'An Actions built by hand round each CupertinoButton so that Enter '
          'works on the web (FL-002); the size itself is the button\'s own '
          'minimumSize.',
      builder: (_) => const GoodCupertino(),
    ),
    TechniqueExample.good(
      slug: 'good-custom',
      title: 'Custom buttons that take taps over their whole box',
      variant: ExampleVariant.widgets,
      customSolution:
          'A button drawn by hand: an opaque 48 by 48 GestureDetector in '
          'Semantics(button: true), with focus and keys from '
          'FocusableActionDetector.',
      builder: (_) => const GoodCustom(),
    ),
    TechniqueExample.good(
      slug: 'good-inline-link',
      title: 'Link in a sentence',
      variant: ExampleVariant.widgets,
      customSolution:
          'An inline link built by hand: Semantics(link: true) and a '
          'GestureDetector in a WidgetSpan, with FocusableActionDetector and '
          'a sort key to keep it in its sentence (FL-413).',
      builder: (_) => const GoodInlineLink(),
    ),
    TechniqueExample.bad(
      slug: 'bad-shrinkwrap',
      title: 'Material icon buttons shrink-wrapped',
      variant: ExampleVariant.material,
      defect:
          'Each button takes taps only on its 18 pixel icon, and the buttons '
          'are 4 pixels apart, so a finger meant for one easily lands on the '
          'next or on nothing.',
      builder: (_) => const BadShrinkWrap(),
    ),
    TechniqueExample.bad(
      slug: 'bad-zero-padding-web',
      title: 'Material icon buttons with no padding',
      variant: ExampleVariant.material,
      defect:
          'In a desktop browser each button takes clicks only on its 18 pixel '
          'icon, 4 pixels from the next. On Android and iOS the theme pads '
          'them to 48 by 48.',
      builder: (_) => const BadZeroPaddingWeb(),
    ),
    TechniqueExample.bad(
      slug: 'bad-cupertino-small',
      title: 'Cupertino buttons with a small minimum size',
      variant: ExampleVariant.cupertino,
      defect:
          'Each button is 18 pixels square and 4 pixels from the next, so a '
          'finger meant for one easily lands on the next or on nothing.',
      builder: (_) => const BadCupertinoSmall(),
    ),
    TechniqueExample.bad(
      slug: 'bad-custom-small',
      title: 'Custom buttons the size of their icons',
      variant: ExampleVariant.widgets,
      defect:
          'Each button takes taps only on its 18 pixel icon, and the buttons '
          'are 4 pixels apart, so a finger meant for one easily lands on the '
          'next or on nothing.',
      builder: (_) => const BadCustomSmall(),
    ),
  ],
);
