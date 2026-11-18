import '../../catalog/technique.dart';
import 'examples.dart';

/// I01 Focusable and clickable controls.
/// Spec: docs/specs/I01-focusable-controls.md.
/// Doc: docs/techniques/I01.md.
final i01FocusableControls = Technique(
  id: 'I01',
  title: 'Focusable and clickable controls',
  group: TechniqueGroup.interaction,
  summary:
      'Anything that can be tapped can also be reached with the keyboard, '
      'activated with Enter and Space, and activated by assistive '
      'technology, and it acts when the pointer is released over it, not '
      'when it goes down.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(),
    AppPlatform.ios: PlatformStatus.applies(),
    AppPlatform.web: PlatformStatus.applies(),
  },
  wcag: const [
    WcagCriterion('2.1.1', 'Keyboard', 'keyboard'),
    WcagCriterion('2.5.2', 'Pointer Cancellation', 'pointer-cancellation'),
    WcagCriterion('4.1.2', 'Name, Role, Value', 'name-role-value'),
  ],
  sources: const [
    SourceLink(
      'Android View: Focusable, Clickable Controls',
      'https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/basics/FocusableClickableControls.md',
    ),
    SourceLink(
      'ARIA APG: Button pattern',
      'https://www.w3.org/WAI/ARIA/apg/patterns/button/',
    ),
    SourceLink(
      'MDN: Keyboard-navigable JavaScript widgets',
      'https://developer.mozilla.org/en-US/docs/Web/Accessibility/Guides/Keyboard-navigable_JavaScript_widgets',
    ),
    SourceLink(
      'Flutter: Understanding Flutter\'s keyboard focus system',
      'https://docs.flutter.dev/ui/interactivity/focus',
    ),
    SourceLink(
      'Flutter API: FocusableActionDetector',
      'https://api.flutter.dev/flutter/widgets/FocusableActionDetector-class.html',
    ),
    SourceLink(
      'Flutter API: ListTile.onTap',
      'https://api.flutter.dev/flutter/material/ListTile/onTap.html',
    ),
    SourceLink(
      'Flutter API: GestureDetector.onTap',
      'https://api.flutter.dev/flutter/widgets/GestureDetector/onTap.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-material',
      title: 'List tile in a card',
      variant: ExampleVariant.material,
      builder: (_) => const GoodMaterial(),
    ),
    TechniqueExample.good(
      slug: 'good-cupertino',
      title: 'Cupertino list tile with focus and keys added',
      variant: ExampleVariant.cupertino,
      builder: (_) => const GoodCupertino(),
    ),
    TechniqueExample.good(
      slug: 'good-custom',
      title: 'Custom card with focus, keys, and a button role',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodCustom(),
    ),
    TechniqueExample.bad(
      slug: 'bad-inkwell-no-role',
      title: 'Card made tappable with an InkWell',
      variant: ExampleVariant.material,
      defect:
          'On Android and iOS the card is not a button: a screen reader reads '
          'its text and nothing says that it can be activated.',
      builder: (_) => const BadInkWellNoRole(),
    ),
    TechniqueExample.bad(
      slug: 'bad-no-focus',
      title: 'Card that takes no keyboard focus',
      variant: ExampleVariant.widgets,
      defect:
          'Tab goes past the card, so someone using a keyboard cannot reach '
          'it or activate it.',
      builder: (_) => const BadNoFocus(),
    ),
    TechniqueExample.bad(
      slug: 'bad-no-key-action',
      title: 'Card that takes focus and ignores the keys',
      variant: ExampleVariant.widgets,
      defect:
          'Tab reaches the card and shows a ring around it, but Enter and '
          'Space do nothing.',
      builder: (_) => const BadNoKeyAction(),
    ),
    TechniqueExample.bad(
      slug: 'bad-tap-down',
      title: 'Card that acts when the pointer goes down',
      variant: ExampleVariant.widgets,
      defect:
          'The card acts as soon as it is pressed, so a press cannot be taken '
          'back by moving off it before letting go.',
      builder: (_) => const BadTapDown(),
    ),
  ],
);
