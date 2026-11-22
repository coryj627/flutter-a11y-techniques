import '../../catalog/technique.dart';
import 'examples.dart';

/// S14 Values and state descriptions.
/// Spec: docs/specs/S14-values-and-state-descriptions.md.
/// Doc: docs/techniques/S14.md.
final s14ValuesAndStateDescriptions = Technique(
  id: 'S14',
  title: 'Values and state descriptions',
  group: TechniqueGroup.semantics,
  summary:
      'A control that holds a value or a state says what it is now, in '
      'words, and says so again whenever it changes.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(),
    AppPlatform.ios: PlatformStatus.applies(),
    AppPlatform.web: PlatformStatus.applies(
      note:
          'Anything adjustable is a slider on web, and a slider cannot be '
          'given a name there (limitation FL-028). The rating and the slider '
          'here read their value on web without their name.',
    ),
  },
  wcag: const [WcagCriterion('4.1.2', 'Name, Role, Value', 'name-role-value')],
  sources: const [
    SourceLink(
      'iOS SwiftUI: Accessibility Value',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/AccessibilityValue.md',
    ),
    SourceLink(
      'Android Compose: Custom State Descriptions',
      'https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/interactions/CustomStateDescriptions.md',
    ),
    SourceLink(
      'Android View: Custom State Descriptions',
      'https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/dynamicbehaviors/CustomStateDescriptions.md',
    ),
    SourceLink(
      'MDN: aria-valuetext',
      'https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Reference/Attributes/aria-valuetext',
    ),
    SourceLink(
      'Apple: accessibilityValue',
      'https://developer.apple.com/documentation/uikit/uiaccessibilityelement/accessibilityvalue',
    ),
    SourceLink(
      'Android: View.setStateDescription',
      'https://developer.android.com/reference/android/view/View#setStateDescription(java.lang.CharSequence)',
    ),
    SourceLink(
      'Flutter API: SemanticsProperties.value',
      'https://api.flutter.dev/flutter/semantics/SemanticsProperties/value.html',
    ),
    SourceLink(
      'Flutter API: SemanticsProperties.onIncrease',
      'https://api.flutter.dev/flutter/semantics/SemanticsProperties/onIncrease.html',
    ),
    SourceLink(
      'Flutter API: Slider.semanticFormatterCallback',
      'https://api.flutter.dev/flutter/material/Slider/semanticFormatterCallback.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-rating',
      title: 'Star rating with a value that can be adjusted (no name on web)',
      variant: ExampleVariant.widgets,
      customSolution:
          'A rating control drawn by hand, adjustable through Semantics(value:, '
          'onIncrease:, onDecrease:) and the arrow keys from '
          'FocusableActionDetector.',
      builder: (_) => const GoodRating(),
    ),
    TechniqueExample.good(
      slug: 'good-step',
      title: 'Step indicator with a value',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodStep(),
    ),
    TechniqueExample.good(
      slug: 'good-button-value',
      title: 'Button with three modes that says which it is in',
      variant: ExampleVariant.widgets,
      customSolution:
          'A button with three modes drawn by hand: Semantics(button: true, '
          'label:, value:), with focus, keys, and a focus ring of its own.',
      builder: (_) => const GoodButtonValue(),
    ),
    TechniqueExample.good(
      slug: 'good-slider-format',
      title: 'Slider whose value is given in words (no name on web)',
      variant: ExampleVariant.material,
      builder: (_) => const GoodSliderFormat(),
    ),
    TechniqueExample.bad(
      slug: 'bad-rating-no-value',
      title: 'Star rating with no value',
      variant: ExampleVariant.widgets,
      defect: 'The rating has no value, so a screen reader says "Rating" and never how many stars.',
      builder: (_) => const BadRatingNoValue(),
    ),
    TechniqueExample.bad(
      slug: 'bad-stale-value',
      title: 'Value that is not updated',
      variant: ExampleVariant.widgets,
      defect: 'The value is never updated, so a screen reader says "3 out of 5" whatever the rating is.',
      builder: (_) => const BadStaleValue(),
    ),
    TechniqueExample.bad(
      slug: 'bad-step-no-value',
      title: 'Step indicator read as four numbers',
      variant: ExampleVariant.widgets,
      defect: 'The steps are read as "1", "2", "3", "4", and nothing says which one is current.',
      builder: (_) => const BadStepNoValue(),
    ),
    TechniqueExample.bad(
      slug: 'bad-button-no-value',
      title: 'Button that shows its mode with an icon only',
      variant: ExampleVariant.widgets,
      defect:
          'The button is read as "Repeat, button" in all three of its modes.',
      builder: (_) => const BadButtonNoValue(),
    ),
    TechniqueExample.bad(
      slug: 'bad-value-on-switch',
      title: 'Value used to reword a switch\'s state',
      variant: ExampleVariant.widgets,
      defect: 'Flutter limitation: the value does not replace "on" and "off". TalkBack reads both wordings, VoiceOver on iOS ignores the value, and on the web it becomes part of the name.',
      builder: (_) => const BadValueOnSwitch(),
    ),
  ],
);
