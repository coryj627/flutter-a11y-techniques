import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_a11y_techniques/app/doc_view.dart';
import 'package:flutter_a11y_techniques/app/screens.dart';
import 'package:flutter_a11y_techniques/app/widgets.dart';
import 'package:flutter_a11y_techniques/catalog/registry.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/all_techniques.dart';
import 'package:widgetbook/widgetbook.dart';

void main() {
  runApp(const TechniquesWidgetbook());
  // Flutter web builds its accessibility tree only on request.
  if (kIsWeb) {
    SemanticsBinding.instance.ensureSemantics();
  }
}

/// The catalog as a Widgetbook: one component per technique, one use case
/// per example, each shown with the technique's documentation (DOC-2). The
/// tree is built from the same registry the app uses, so the two cannot list
/// different examples.
class TechniquesWidgetbook extends StatelessWidget {
  const TechniquesWidgetbook({super.key});

  @override
  Widget build(BuildContext context) {
    final groups = TechniqueRegistry(allTechniques).grouped(null);
    return Widgetbook.material(
      directories: [
        for (final MapEntry(key: group, value: techniques) in groups.entries)
          WidgetbookCategory(
            name: group.title,
            isInitiallyExpanded: true,
            children: [
              for (final technique in techniques)
                WidgetbookComponent(
                  name: '${technique.id} ${technique.title}',
                  isInitiallyExpanded: true,
                  useCases: [
                    for (final example in technique.examples)
                      WidgetbookUseCase(
                        // Good or bad is in the name, never colour alone.
                        name:
                            '${example.title} '
                            '(${example.kind == ExampleKind.good ? 'good' : 'bad'})',
                        builder: (_) =>
                            UseCaseView(technique: technique, example: example),
                      ),
                  ],
                ),
            ],
          ),
        WidgetbookCategory(
          name: 'About',
          isInitiallyExpanded: true,
          children: [
            WidgetbookComponent(
              name: 'About this project',
              isInitiallyExpanded: true,
              useCases: [
                WidgetbookUseCase(
                  name: 'Independence and references',
                  builder: (_) => const AboutScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
      addons: [
        MaterialThemeAddon(
          themes: [
            WidgetbookTheme(
              name: 'Light',
              data: ThemeData(colorSchemeSeed: Colors.indigo),
            ),
            WidgetbookTheme(
              name: 'Dark',
              data: ThemeData(
                colorSchemeSeed: Colors.indigo,
                brightness: Brightness.dark,
              ),
            ),
          ],
        ),
        // Up to 200%, the size WCAG 1.4.4 asks content to survive.
        TextScaleAddon(min: 1, max: 2, divisions: 4),
      ],
    );
  }
}

/// One example with what it is, its defect if it is a bad example, and the
/// technique's documentation underneath.
class UseCaseView extends StatelessWidget {
  const UseCaseView({
    super.key,
    required this.technique,
    required this.example,
  });

  final Technique technique;
  final TechniqueExample example;

  @override
  Widget build(BuildContext context) {
    final e = example;
    return Material(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BodyText(
                    '${e.kind.title} for ${technique.title}. '
                    '${e.variant.title}.',
                  ),
                  if (e.defect case final defect?) BodyText('Defect: $defect'),
                  const SectionHeading('Example'),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Builder(builder: e.builder),
                  ),
                  TechniqueDocView(
                    techniqueId: technique.id,
                    title: 'Documentation',
                    headingOffset: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
