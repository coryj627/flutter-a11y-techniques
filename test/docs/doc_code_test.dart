import 'dart:io';

import 'package:flutter_a11y_techniques/techniques/all_techniques.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/doc_code.dart';

/// D24: the code shown in a technique doc is the code in its examples file.
void main() {
  group('regions', () {
    test('returns each region by slug, in file order, trimmed', () {
      const source = '''
import 'x';

// #region good-a
class A {}
// #endregion

// #region bad-b

class B {}

// #endregion
''';
      final found = regions(source);
      expect(found.keys.toList(), ['good-a', 'bad-b']);
      expect(found['good-a'], 'class A {}');
      expect(found['bad-b'], 'class B {}');
    });

    for (final (name, source) in [
      ('nested', '// #region a\n// #region b\nx\n// #endregion\n'),
      ('unclosed', '// #region a\nx\n'),
      ('end without start', 'x\n// #endregion\n'),
      ('empty', '// #region a\n\n// #endregion\n'),
      (
        'repeated',
        '// #region a\nx\n// #endregion\n// #region a\ny\n// #endregion\n',
      ),
      ('code fence', '// #region a\n/// ```dart\n// #endregion\n'),
    ]) {
      test('rejects a region that is $name', () {
        expect(() => regions(source), throwsFormatException);
      });
    }
  });

  group('sync', () {
    const examples = '// #region good-a\nclass A {}\n// #endregion\n';
    const path = 'lib/techniques/x/examples.dart';

    test('replaces only what is between the markers', () {
      const doc = 'Before.\n\n$startMarker\nold\n$endMarker\n\n## After\n';
      final result = sync(doc, examples, path);
      expect(result, startsWith('Before.\n\n$startMarker\n## Example code\n'));
      expect(result, contains('### `good-a`\n\n```dart\nclass A {}\n```\n'));
      expect(result, endsWith('$endMarker\n\n## After\n'));
      expect(result, isNot(contains('old')));
      expect(sync(result, examples, path), result, reason: 'stable');
    });

    test('rejects a doc with no markers, or with two blocks', () {
      expect(() => sync('No markers.', examples, path), throwsFormatException);
      const twice = '$startMarker\n$endMarker\n$startMarker\n$endMarker\n';
      expect(() => sync(twice, examples, path), throwsFormatException);
    });

    test('finds the examples file from the doc\'s Code link', () {
      expect(
        examplesPathOf(
          'Code: [`x`](../../lib/techniques/c01_button/examples.dart).',
        ),
        'lib/techniques/c01_button/examples.dart',
      );
      expect(() => examplesPathOf('No link.'), throwsFormatException);
    });
  });

  group('technique docs', () {
    final root = Directory.current;

    test('every registered technique has a doc the tool manages', () {
      expect(techniqueDocs(root).map((f) => f.uri.pathSegments.last).toSet(), {
        for (final t in allTechniques) '${t.id}.md',
      });
    });

    for (final technique in allTechniques) {
      final doc = File('docs/techniques/${technique.id}.md');

      test('${technique.id}: the example code is up to date', () {
        expect(
          doc.readAsStringSync(),
          expected(doc, root),
          reason: 'Run: dart run tool/doc_code.dart',
        );
      });

      test('${technique.id}: every example has a region, and no other', () {
        final source = doc.readAsStringSync();
        final examples = File(examplesPathOf(source)).readAsStringSync();
        expect(regions(examples).keys.toSet(), {
          for (final e in technique.examples) e.slug,
        });
      });
    }
  });
}
