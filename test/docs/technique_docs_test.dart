import 'dart:io';

import 'package:flutter_a11y_techniques/techniques/all_techniques.dart';
import 'package:flutter_test/flutter_test.dart';

/// DOC-3: the Markdown doc and the registered technique must not drift apart.
void main() {
  for (final technique in allTechniques) {
    final file = File('docs/techniques/${technique.id}.md');

    group('docs/techniques/${technique.id}.md', () {
      late String source;
      late Map<String, String> frontMatter;

      setUpAll(() {
        expect(file.existsSync(), isTrue, reason: 'every technique has a doc');
        source = file.readAsStringSync();
        final end = source.indexOf('\n---', 3);
        expect(
          source.startsWith('---') && end > 0,
          isTrue,
          reason: 'front matter',
        );
        frontMatter = {
          for (final line in source.substring(4, end).split('\n'))
            if (RegExp(r'^\w').hasMatch(line) && line.contains(':'))
              line.substring(0, line.indexOf(':')).trim(): line
                  .substring(line.indexOf(':') + 1)
                  .trim(),
        };
      });

      test('front matter matches the registered technique', () {
        expect(frontMatter['id'], technique.id);
        expect(frontMatter['title'], technique.title);
        expect(frontMatter['group'], technique.group.title.split(' ').first);
        final wcag = RegExp(r'"([\d.]+)"')
            .allMatches(frontMatter['wcag'] ?? '')
            .map((m) => m.group(1))
            .toList();
        expect(wcag, [for (final c in technique.wcag) c.number]);
      });

      test('has the Flutter version it was measured on', () {
        final pin = RegExp(r'"flutter":\s*"([^"]+)"')
            .firstMatch(File('.fvmrc').readAsStringSync())!
            .group(1);
        expect(frontMatter['flutter'], pin);
      });

      test('names every example, and no example that does not exist', () {
        final inDoc = RegExp(r'`((?:good|bad)-[a-z-]+)`')
            .allMatches(source)
            .map((m) => m.group(1)!)
            .toSet();
        expect(inDoc, {for (final e in technique.examples) e.slug});
      });

      test('links to every WCAG criterion and every non-Flutter source', () {
        for (final c in technique.wcag) {
          expect(source, contains(c.uri.toString()), reason: c.label);
        }
        for (final s in technique.sources) {
          if (s.url.contains('flutter.dev')) continue;
          expect(source, contains(s.url), reason: s.title);
        }
      });

      test('relative links point at files that exist', () {
        final links = RegExp(r'\]\((\.\.?/[^)#\s]+)')
            .allMatches(source)
            .map((m) => m.group(1)!);
        expect(links, isNotEmpty);
        for (final link in links) {
          final target = File.fromUri(file.absolute.uri.resolve(link));
          expect(target.existsSync(), isTrue, reason: link);
        }
      });
    });
  }
}
