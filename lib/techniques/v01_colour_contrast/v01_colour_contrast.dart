import '../../catalog/technique.dart';
import 'examples.dart';

/// V01 Colour contrast. Spec: docs/specs/V01-colour-contrast.md. Doc:
/// docs/techniques/V01.md.
final v01ColourContrast = Technique(
  id: 'V01',
  title: 'Colour contrast',
  group: TechniqueGroup.visual,
  summary:
      'Text has a contrast of 4.5:1 with what is behind it, the edges and '
      'marks that show a control and its state 3:1 with what is next to '
      'them, and a state is never shown by colour alone.',
  platforms: const {
    AppPlatform.android: PlatformStatus.applies(
      note:
          'Measured from the emulator\'s screenshots, light and dark. Hover '
          'was not measured: the emulator has no mouse.',
    ),
    AppPlatform.ios: PlatformStatus.applies(
      note:
          'Measured from the simulator\'s screenshots, light and dark. Hover '
          'and a held press were not measured.',
    ),
    AppPlatform.web: PlatformStatus.applies(
      note: 'Measured from Chromium\'s screenshots, light and dark.',
    ),
  },
  wcag: const [
    WcagCriterion('1.4.3', 'Contrast (Minimum)', 'contrast-minimum'),
    WcagCriterion('1.4.11', 'Non-text Contrast', 'non-text-contrast'),
    WcagCriterion('1.4.1', 'Use of Color', 'use-of-color'),
  ],
  sources: const [
    SourceLink(
      'iOS SwiftUI: Contrast',
      'https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/Contrast.md',
    ),
    SourceLink(
      'Understanding 1.4.3 Contrast (Minimum)',
      'https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html',
    ),
    SourceLink(
      'Understanding 1.4.11 Non-text Contrast',
      'https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html',
    ),
    SourceLink(
      'Understanding 1.4.1 Use of Color',
      'https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html',
    ),
    SourceLink(
      'WCAG failure F83: background images that do not provide sufficient '
          'contrast with foreground text',
      'https://www.w3.org/WAI/WCAG22/Techniques/failures/F83',
    ),
    SourceLink(
      'Flutter API: ColorScheme.fromSeed',
      'https://api.flutter.dev/flutter/material/ColorScheme/ColorScheme.fromSeed.html',
    ),
    SourceLink(
      'Flutter API: ColorScheme.outlineVariant',
      'https://api.flutter.dev/flutter/material/ColorScheme/outlineVariant.html',
    ),
    SourceLink(
      'Flutter API: InputDecoration.floatingLabelBehavior',
      'https://api.flutter.dev/flutter/material/InputDecoration/floatingLabelBehavior.html',
    ),
    SourceLink(
      'Flutter API: CupertinoTextField.placeholderStyle',
      'https://api.flutter.dev/flutter/cupertino/CupertinoTextField/placeholderStyle.html',
    ),
    SourceLink(
      'Flutter API: CupertinoTextField.decoration',
      'https://api.flutter.dev/flutter/cupertino/CupertinoTextField/decoration.html',
    ),
    SourceLink(
      'Flutter API: CupertinoDynamicColor.highContrastColor',
      'https://api.flutter.dev/flutter/cupertino/CupertinoDynamicColor/highContrastColor.html',
    ),
    SourceLink(
      'Flutter API: GridTileBar.backgroundColor',
      'https://api.flutter.dev/flutter/material/GridTileBar/backgroundColor.html',
    ),
    SourceLink(
      'Flutter API: RadioListTile',
      'https://api.flutter.dev/flutter/material/RadioListTile-class.html',
    ),
    SourceLink(
      'Flutter API: ListTile.selected',
      'https://api.flutter.dev/flutter/material/ListTile/selected.html',
    ),
  ],
  examples: [
    TechniqueExample.good(
      slug: 'good-material',
      title: 'Material form at the theme\'s defaults',
      variant: ExampleVariant.material,
      builder: (_) => const GoodMaterial(),
    ),
    TechniqueExample.good(
      slug: 'good-cupertino',
      title: 'Cupertino field with stronger greys',
      variant: ExampleVariant.cupertino,
      builder: (_) => const GoodCupertino(),
    ),
    TechniqueExample.good(
      slug: 'good-caption',
      title: 'Caption on a bar of its own',
      variant: ExampleVariant.material,
      builder: (_) => const GoodCaption(),
    ),
    TechniqueExample.good(
      slug: 'good-selection',
      title: 'Choice shown by a shape',
      variant: ExampleVariant.material,
      builder: (_) => const GoodSelection(),
    ),
    TechniqueExample.bad(
      slug: 'bad-cupertino-placeholder',
      title: 'Default Cupertino placeholder',
      variant: ExampleVariant.cupertino,
      defect: 'The placeholder is too faint to read.',
      builder: (_) => const BadCupertinoPlaceholder(),
    ),
    TechniqueExample.bad(
      slug: 'bad-caption',
      title: 'Caption straight on the picture',
      variant: ExampleVariant.material,
      defect: 'The caption fades into the pale part of the picture.',
      builder: (_) => const BadCaption(),
    ),
    TechniqueExample.bad(
      slug: 'bad-colour-only',
      title: 'Choice shown by colour alone',
      variant: ExampleVariant.material,
      defect: 'The chosen view differs from the others only by colour.',
      builder: (_) => const BadColourOnly(),
    ),
    TechniqueExample.bad(
      slug: 'bad-faint-edge',
      title: 'Field with a faint edge',
      variant: ExampleVariant.material,
      defect: 'The field\'s edge is too faint to see where it is.',
      builder: (_) => const BadFaintEdge(),
    ),
  ],
);
