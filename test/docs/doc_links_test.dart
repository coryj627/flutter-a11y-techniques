import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Project documents link to each other and to files in the repository. A
/// renamed or deleted file must not leave a dead link behind.
void main() {
  final documents = [
    File('README.md'),
    ...Directory('docs')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.md'))
        // Templates hold placeholder paths such as <ID>, by design.
        .where((f) => !f.path.contains('/templates/')),
  ]..sort((a, b) => a.path.compareTo(b.path));

  test('the documents to check were found', () {
    expect(documents.length, greaterThan(15));
  });

  for (final document in documents) {
    test('${document.path}: relative links point at files that exist', () {
      final source = document.readAsStringSync();
      // [text](target) where target is not a web address or an in-page anchor.
      final links = RegExp(r'\]\((?!https?://|mailto:|#)([^)#\s]+)')
          .allMatches(source)
          .map((m) => m.group(1)!);
      for (final link in links) {
        final target = document.absolute.uri.resolve(link);
        final exists =
            File.fromUri(target).existsSync() ||
            Directory.fromUri(target).existsSync();
        expect(exists, isTrue, reason: '${document.path} links to $link');
      }
    });
  }
}
