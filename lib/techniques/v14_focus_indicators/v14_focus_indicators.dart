import '../../catalog/technique.dart';
import 'examples.dart';

/// V14 Focus indicators.
/// Spec: docs/specs/V14-focus-indicators.md.
/// Doc: docs/techniques/V14.md.
final v14FocusIndicators = Technique(
  id: 'V14',
  title: 'Focus indicators',
  group: TechniqueGroup.visual,
  summary:
      'Someone using a keyboard can see which control has focus: the '
      'control changes visibly when focus reaches it, the change stands out '
      'from what is next to it, and nothing drawn over the screen hides it.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(
      note:
          'Material checkboxes, radio buttons, and switches show focus with a '
          'halo that is too faint, Cupertino controls with a ring that is too '
          'pale in light mode, and Flutter scrolls a focused control into '
          'view without regard to anything drawn over the view (limitations '
          'FL-430, FL-431, and FL-432). Keys a test sends arrive as the '
          'virtual keyboard\'s, which do not turn Flutter\'s focus highlights '
          'on (FL-433): only the indicators drawn from the focused state, '
          'those of the Material example, are verified here; the Cupertino '
          'and custom ones and the bad examples\' defaults are not verified '
          'on Android.',
    ),
    AppPlatform.ios: PlatformStatus.applies(
      note:
          'Material checkboxes, radio buttons, and switches show focus with a '
          'halo that is too faint, and Cupertino controls with a ring that is '
          'too pale in light mode (limitations FL-430 and FL-431). Flutter '
          'scrolls a focused control into view without regard to anything '
          'drawn over the scrolling view (FL-432). Checked with a hardware '
          'keyboard and Full Keyboard Access off.',
    ),
    AppPlatform.web: PlatformStatus.applies(
      note:
          'Flutter draws every focus indicator itself; the browser\'s own '
          'outline is hidden. Material checkboxes, radio buttons, and '
          'switches show focus with a halo that is too faint, and Cupertino '
          'controls with a ring that is too pale in light mode (limitations '
          'FL-430 and FL-431), and a focused control can scroll under '
          'content drawn over the scrolling view (FL-432).',
    ),
  },
  wcag: const [
    WcagCriterion('2.4.7', 'Focus Visible', 'focus-visible'),
    WcagCriterion(
      '2.4.11',
      'Focus Not Obscured (Minimum)',
      'focus-not-obscured-minimum',
    ),
    WcagCriterion('1.4.11', 'Non-text Contrast', 'non-text-contrast'),
  ],
  sources: const [
    SourceLink(
      'Android View: Custom Focus Indicators',
      'https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/dynamicbehaviors/CustomFocusIndicators.md',
    ),
    SourceLink(
      'Android Compose: Custom Focus Indicators',
      'https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/interactions/CustomFocusIndicators.md',
    ),
    SourceLink(
      'WCAG: Understanding 2.4.7 Focus Visible',
      'https://www.w3.org/WAI/WCAG22/Understanding/focus-visible.html',
    ),
    SourceLink(
      'WCAG: Understanding 2.4.11 Focus Not Obscured (Minimum)',
      'https://www.w3.org/WAI/WCAG22/Understanding/focus-not-obscured-minimum.html',
    ),
    SourceLink(
      'WCAG: Understanding 1.4.11 Non-text Contrast',
      'https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html',
    ),
    SourceLink(
      'Flutter API: ButtonStyle.side',
      'https://api.flutter.dev/flutter/material/ButtonStyle/side.html',
    ),
    SourceLink(
      'Flutter API: Focus.onFocusChange',
      'https://api.flutter.dev/flutter/widgets/Focus/onFocusChange.html',
    ),
    SourceLink(
      'Flutter API: CupertinoButton.focusColor',
      'https://api.flutter.dev/flutter/cupertino/CupertinoButton/focusColor.html',
    ),
    SourceLink(
      'Flutter API: FocusableActionDetector.onShowFocusHighlight',
      'https://api.flutter.dev/flutter/widgets/FocusableActionDetector/onShowFocusHighlight.html',
    ),
    SourceLink(
      'Flutter API: FocusManager.highlightMode',
      'https://api.flutter.dev/flutter/widgets/FocusManager/highlightMode.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-material',
      title: 'Checkbox tile and button with a focus ring',
      variant: ExampleVariant.material,
      builder: (_) => const GoodMaterial(),
    ),
    TechniqueExample.good(
      slug: 'good-cupertino',
      title: 'Cupertino switch and button with a dark focus ring',
      variant: ExampleVariant.cupertino,
      builder: (_) => const GoodCupertino(),
    ),
    TechniqueExample.good(
      slug: 'good-widgets',
      title: 'Custom card that thickens its border on focus',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodWidgets(),
    ),
    TechniqueExample.good(
      slug: 'good-notice-below',
      title: 'Scrolling list with its notice below it',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodNoticeBelow(),
    ),
    TechniqueExample.bad(
      slug: 'bad-indicator-removed',
      title: 'Button whose focus overlay is removed',
      variant: ExampleVariant.material,
      defect:
          'Nothing on the screen changes when Tab reaches the button, so '
          'someone using a keyboard cannot see where they are.',
      builder: (_) => const BadIndicatorRemoved(),
    ),
    TechniqueExample.bad(
      slug: 'bad-checkbox-halo',
      title: 'Checkbox with its default focus halo',
      variant: ExampleVariant.material,
      defect:
          'The faint halo that shows focus is hard to see: it is about 1.2 '
          'to 1 against the page, where a focus indicator needs 3 to 1.',
      builder: (_) => const BadCheckboxHalo(),
    ),
    TechniqueExample.bad(
      slug: 'bad-cupertino-ring',
      title: 'Cupertino button with its default focus ring',
      variant: ExampleVariant.cupertino,
      defect:
          'In light mode the pale blue ring that shows focus is hard to see: '
          'it is about 2.5 to 1 against the page, where a focus indicator '
          'needs 3 to 1.',
      builder: (_) => const BadCupertinoRing(),
    ),
    TechniqueExample.bad(
      slug: 'bad-notice-over-list',
      title: 'Scrolling list with a notice drawn over it',
      variant: ExampleVariant.widgets,
      defect:
          'Tab moves focus to trails that are hidden under the notice, so '
          'someone using a keyboard cannot see the control they are on.',
      builder: (_) => const BadNoticeOverList(),
    ),
  ],
);
