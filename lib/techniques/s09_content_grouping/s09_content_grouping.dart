import '../../catalog/technique.dart';
import 'examples.dart';

/// S09 Content grouping. Spec: docs/specs/S09-content-grouping.md. Doc:
/// docs/techniques/S09.md.
final s09ContentGrouping = Technique(
  id: 'S09',
  title: 'Content grouping',
  group: TechniqueGroup.semantics,
  summary:
      'Content that belongs together is exposed as one unit or as a named '
      'group: a label and its value are read as one stop, a set of related '
      'controls is a group named by its visible question, and an icon and '
      'its text that do one thing are one target.',
  platforms: const {
    AppPlatform.android: PlatformStatus.limitation(
      'A label and its value are one stop, and an icon and its text one '
      'button. But Flutter has no group that TalkBack names: a group\'s '
      'name is a stop of its own before its controls, and focus put on a '
      'control inside is read without it, where a native container title '
      'is read on the way in (limitation FL-320). There is no workaround.',
    ),
    AppPlatform.ios: PlatformStatus.limitation(
      'A label and its value are one stop, and an icon and its text one '
      'button. But Flutter has no group that VoiceOver names: a group\'s '
      'name is a stop of its own before its controls, and the controls are '
      'read without it, where a native semantic group is read on the way in '
      '(limitation FL-320). There is no workaround.',
    ),
    AppPlatform.web: PlatformStatus.applies(),
  },
  wcag: const [
    WcagCriterion('1.3.1', 'Info and Relationships', 'info-and-relationships'),
  ],
  sources: const [
    SourceLink(
      'iOS SwiftUI: Combining Focus',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/CombiningFocus.md',
    ),
    SourceLink(
      'iOS SwiftUI: Grouping Controls',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/GroupingControls.md',
    ),
    SourceLink(
      'Android View: Content Grouping',
      'https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/grouping/ContentGrouping.md',
    ),
    SourceLink(
      'Android View: Tap Target Grouping',
      'https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/grouping/TapTargetGrouping.md',
    ),
    SourceLink(
      'Android Compose: Content Grouping',
      'https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/content/ContentGrouping.md',
    ),
    SourceLink(
      'MDN: The fieldset element',
      'https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/fieldset',
    ),
    SourceLink(
      'WCAG technique H71: fieldset and legend',
      'https://www.w3.org/WAI/WCAG22/Techniques/html/H71',
    ),
    SourceLink(
      'Flutter API: MergeSemantics',
      'https://api.flutter.dev/flutter/widgets/MergeSemantics-class.html',
    ),
    SourceLink(
      'Flutter API: Semantics.container',
      'https://api.flutter.dev/flutter/widgets/Semantics/container.html',
    ),
    SourceLink(
      'Flutter API: TextButton.icon',
      'https://api.flutter.dev/flutter/material/TextButton/TextButton.icon.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-merged-facts',
      title: 'Each label merged with its value',
      variant: ExampleVariant.widgets,
      builder: (_) => const GoodMergedFacts(),
    ),
    TechniqueExample.good(
      slug: 'good-cupertino',
      title: 'Cupertino rows, each one element',
      variant: ExampleVariant.cupertino,
      builder: (_) => const GoodCupertino(),
    ),
    TechniqueExample.good(
      slug: 'good-named-group',
      title: 'Buttons in a group named by its question',
      variant: ExampleVariant.material,
      builder: (_) => const GoodNamedGroup(),
    ),
    TechniqueExample.good(
      slug: 'good-tap-target',
      title: 'Icon and text as one button',
      variant: ExampleVariant.material,
      builder: (_) => const GoodTapTarget(),
    ),
    TechniqueExample.bad(
      slug: 'bad-split-facts',
      title: 'Labels and values in separate rows',
      variant: ExampleVariant.widgets,
      defect: 'Both labels are read first, then both values.',
      builder: (_) => const BadSplitFacts(),
    ),
    TechniqueExample.bad(
      slug: 'bad-merged-group',
      title: 'Question and buttons merged',
      variant: ExampleVariant.material,
      defect:
          "The question and both buttons are one button, whose action is On's.",
      builder: (_) => const BadMergedGroup(),
    ),
  ],
);
