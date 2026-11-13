import 'package:flutter/material.dart';

import '../catalog/registry.dart';
import '../catalog/technique.dart';
import 'routes.dart';
import 'widgets.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key, required this.registry, this.platform});

  final TechniqueRegistry registry;
  final AppPlatform? platform;

  @override
  Widget build(BuildContext context) {
    final groups = registry.grouped(platform);
    return PageScaffold(
      title: appName,
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          tooltip: 'About',
          onPressed: () => Navigator.pushNamed(context, AppRoutes.about),
        ),
      ],
      children: [
        if (groups.isEmpty)
          const BodyText('No techniques have been added yet.')
        else
          for (final MapEntry(key: group, value: techniques)
              in groups.entries) ...[
            SectionHeading(group.title),
            for (final t in techniques)
              ListTile(
                title: Text(t.title),
                subtitle: Text(t.id),
                trailing: const ExcludeSemantics(
                  child: Icon(Icons.chevron_right),
                ),
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.technique(t.id)),
              ),
          ],
      ],
    );
  }
}

class TechniqueScreen extends StatelessWidget {
  const TechniqueScreen({super.key, required this.technique, this.platform});

  final Technique technique;
  final AppPlatform? platform;

  @override
  Widget build(BuildContext context) {
    final t = technique;
    final good = t.examples.where((e) => e.kind == ExampleKind.good);
    final bad = t.examples.where((e) => e.kind == ExampleKind.bad);
    return PageScaffold(
      title: t.title,
      children: [
        BodyText(t.summary),
        const SectionHeading('Platforms'),
        for (final p in AppPlatform.values)
          BodyText('${p.title}: ${_describe(t.statusFor(p))}'),
        for (final p in AppPlatform.values)
          if (t.statusFor(p).issue case final issue?)
            ExternalLink(title: 'Flutter issue (${p.title})', uri: issue),
        if (good.isNotEmpty) const SectionHeading('Good examples'),
        for (final e in good) _ExampleTile(technique: t, example: e),
        if (bad.isNotEmpty) const SectionHeading('Bad examples'),
        for (final e in bad) _ExampleTile(technique: t, example: e),
        const SectionHeading('WCAG 2.2 success criteria'),
        for (final c in t.wcag) ExternalLink(title: c.label, uri: c.uri),
        const SectionHeading('Sources'),
        for (final s in t.sources) ExternalLink(title: s.title, uri: s.uri),
      ],
    );
  }

  static String _describe(PlatformStatus status) {
    final note = status.note == null ? '' : ' ${status.note}';
    return switch (status.applicability) {
      Applicability.applies => 'Applies.',
      Applicability.notApplicable => 'Not applicable.$note',
      Applicability.limitation => 'Flutter limitation.$note',
    };
  }
}

class _ExampleTile extends StatelessWidget {
  const _ExampleTile({required this.technique, required this.example});

  final Technique technique;
  final TechniqueExample example;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(example.title),
      subtitle: Text(example.variant.title),
      trailing: const ExcludeSemantics(child: Icon(Icons.chevron_right)),
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.example(technique.id, example.slug),
      ),
    );
  }
}

class ExampleScreen extends StatelessWidget {
  const ExampleScreen({
    super.key,
    required this.technique,
    required this.example,
  });

  final Technique technique;
  final TechniqueExample example;

  @override
  Widget build(BuildContext context) {
    final e = example;
    return PageScaffold(
      title: e.title,
      children: [
        // Good or bad is stated in text, never by colour alone.
        BodyText('${e.kind.title} for ${technique.title}. ${e.variant.title}.'),
        if (e.defect case final defect?) BodyText('Defect: $defect'),
        const SectionHeading('Example'),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Builder(builder: e.builder),
        ),
      ],
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'About',
      children: [
        const BodyText(
          'Live good and bad examples of Flutter accessibility techniques, '
          'measured against WCAG 2.2 Level A and AA, with source-referenced '
          'documentation.',
        ),
        const SectionHeading('Independence'),
        const BodyText(
          'This project draws on public accessibility technique repositories '
          'published by CVS Health as references. The project, its code, and '
          'the work have no material connection to CVS Health. It is the work '
          'of an independent developer, not a representative of the company.',
        ),
        const SectionHeading('References'),
        ExternalLink(
          title: 'WCAG 2.2',
          uri: Uri.parse('https://www.w3.org/TR/WCAG22/'),
        ),
        ExternalLink(
          title: 'ARIA Authoring Practices Guide patterns',
          uri: Uri.parse('https://www.w3.org/WAI/ARIA/apg/patterns/'),
        ),
        ExternalLink(
          title: 'iOS SwiftUI Accessibility Techniques (Apache-2.0)',
          uri: Uri.parse(
            'https://github.com/cvs-health/ios-swiftui-accessibility-techniques',
          ),
        ),
        ExternalLink(
          title: 'Android View Accessibility Techniques (Apache-2.0)',
          uri: Uri.parse(
            'https://github.com/cvs-health/android-view-accessibility-techniques',
          ),
        ),
        ExternalLink(
          title: 'Android Compose Accessibility Techniques (Apache-2.0)',
          uri: Uri.parse(
            'https://github.com/cvs-health/android-compose-accessibility-techniques',
          ),
        ),
      ],
    );
  }
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Page not found',
      children: [
        const BodyText('There is nothing at this address.'),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.catalog,
                (_) => false,
              ),
              child: const Text('Go to the catalog'),
            ),
          ),
        ),
      ],
    );
  }
}
