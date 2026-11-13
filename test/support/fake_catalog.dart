import 'package:flutter/material.dart';
import 'package:flutter_a11y_techniques/catalog/registry.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';

/// A stand-in catalog so the shell can be tested before real techniques exist.
TechniqueRegistry fakeRegistry() => TechniqueRegistry([
  Technique(
    id: 'C01',
    title: 'Fake button',
    group: TechniqueGroup.components,
    summary: 'A fake technique for testing the shell.',
    platforms: {
      AppPlatform.android: const PlatformStatus.applies(),
      AppPlatform.ios: const PlatformStatus.applies(),
      AppPlatform.web: PlatformStatus.limitation(
        'Not fully supported.',
        issue: Uri.parse('https://github.com/flutter/flutter/issues/1'),
      ),
    },
    wcag: const [
      WcagCriterion('4.1.2', 'Name, Role, Value', 'name-role-value'),
    ],
    sources: const [
      SourceLink(
        'APG Button',
        'https://www.w3.org/WAI/ARIA/apg/patterns/button/',
      ),
    ],
    examples: [
      TechniqueExample.good(
        slug: 'good-text',
        title: 'Text button',
        variant: ExampleVariant.material,
        builder: (_) =>
            FilledButton(onPressed: () {}, child: const Text('Save')),
      ),
      TechniqueExample.bad(
        slug: 'bad-thing',
        title: 'Broken button',
        variant: ExampleVariant.material,
        defect: 'It is broken.',
        builder: (_) => const Text('Not a button'),
      ),
    ],
  ),
  const Technique(
    id: 'I09',
    title: 'Fake iOS only',
    group: TechniqueGroup.interaction,
    summary: 'Only on iOS.',
    platforms: {
      AppPlatform.android: PlatformStatus.notApplicable('iOS only.'),
      AppPlatform.ios: PlatformStatus.applies(),
      AppPlatform.web: PlatformStatus.notApplicable('iOS only.'),
    },
    wcag: [],
    sources: [],
    examples: [],
  ),
]);
