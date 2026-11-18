import '../../catalog/technique.dart';
import 'examples.dart';

/// F10 Slider.
/// Spec: docs/specs/F10-slider.md.
/// Doc: docs/techniques/F10.md.
final f10Slider = Technique(
  id: 'F10',
  title: 'Slider',
  group: TechniqueGroup.forms,
  summary:
      'A slider sets a value in a range. It has the visible text beside it '
      'as its name, a value in the words the screen uses, the arrow, Home, '
      'and End keys, and a way to set it with a tap as well as a drag.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(),
    AppPlatform.ios: PlatformStatus.applies(),
    AppPlatform.web: PlatformStatus.limitation(
      'On the web the slider element has no name: Flutter 3.47 puts the '
      'label on an element around it (limitation FL-028, fixed in Flutter '
      '3.50 according to its source). A Material Slider also adds an empty '
      'element over the whole screen (FL-029). There is no workaround in '
      'the SDK.',
    ),
  },
  wcag: const [
    WcagCriterion('2.1.1', 'Keyboard', 'keyboard'),
    WcagCriterion('2.5.7', 'Dragging Movements', 'dragging-movements'),
    WcagCriterion('4.1.2', 'Name, Role, Value', 'name-role-value'),
  ],
  sources: const [
    SourceLink(
      'iOS SwiftUI: Sliders',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/Sliders.md',
    ),
    SourceLink(
      'Android Compose: Slider and RangeSlider Controls',
      'https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/components/SliderAndRangeSliderControls.md',
    ),
    SourceLink(
      'ARIA APG: Slider pattern',
      'https://www.w3.org/WAI/ARIA/apg/patterns/slider/',
    ),
    SourceLink(
      'MDN: <input type="range">',
      'https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/input/range',
    ),
    SourceLink(
      'WCAG: G216 Providing single point activation for a control slider',
      'https://www.w3.org/WAI/WCAG22/Techniques/general/G216',
    ),
    SourceLink(
      'Flutter API: Slider',
      'https://api.flutter.dev/flutter/material/Slider-class.html',
    ),
    SourceLink(
      'Flutter API: CupertinoSlider',
      'https://api.flutter.dev/flutter/cupertino/CupertinoSlider-class.html',
    ),
    SourceLink(
      'Flutter API: SemanticsProperties.increasedValue',
      'https://api.flutter.dev/flutter/semantics/SemanticsProperties/increasedValue.html',
    ),
    SourceLink(
      'Flutter API: FocusableActionDetector',
      'https://api.flutter.dev/flutter/widgets/FocusableActionDetector-class.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-material',
      title: 'Material slider joined to its text',
      variant: ExampleVariant.material,
      builder: (_) => const GoodMaterial(),
    ),
    TechniqueExample.good(
      slug: 'good-cupertino',
      title: 'Cupertino slider with keys and step buttons',
      variant: ExampleVariant.cupertino,
      builder: (_) => const GoodCupertino(),
    ),
    TechniqueExample.good(
      slug: 'good-custom',
      title: 'Custom slider on Semantics',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodCustom(),
    ),
    TechniqueExample.good(
      slug: 'good-value-text',
      title: 'Slider whose value is read in words',
      variant: ExampleVariant.material,
      builder: (_) => const GoodValueText(),
    ),
    TechniqueExample.bad(
      slug: 'bad-unlabelled',
      title: 'Slider with text above it, not joined',
      variant: ExampleVariant.material,
      defect: 'The slider has no name: a screen reader says "40%" and "slider", and nothing says what it sets.',
      builder: (_) => const BadUnlabelled(),
    ),
    TechniqueExample.bad(
      slug: 'bad-indicator-label',
      title: 'Slider with a value indicator label',
      variant: ExampleVariant.material,
      defect: 'The number shown above the thumb is added to the name: TalkBack says "40%", "Volume 4", "Slider", and the name changes at every step.',
      builder: (_) => const BadIndicatorLabel(),
    ),
    TechniqueExample.bad(
      slug: 'bad-percent-value',
      title: 'Rating slider read as a percentage',
      variant: ExampleVariant.material,
      defect: 'The screen says "4 out of 10" and a screen reader says "40%".',
      builder: (_) => const BadPercentValue(),
    ),
    TechniqueExample.bad(
      slug: 'bad-no-keyboard',
      title: 'Custom slider with no keyboard',
      variant: ExampleVariant.widgets,
      defect: 'The slider takes no keyboard focus: Tab goes past it and the arrow keys never move it. On the web the browser\'s own Tab order can still land on it, and then Home and End move one step.',
      builder: (_) => const BadNoKeyboard(),
    ),
    TechniqueExample.bad(
      slug: 'bad-drag-only',
      title: 'Custom slider that only drags',
      variant: ExampleVariant.widgets,
      defect: 'A tap on the track does nothing: the value moves only while the thumb is dragged.',
      builder: (_) => const BadDragOnly(),
    ),
  ],
);
