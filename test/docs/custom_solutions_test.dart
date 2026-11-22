import 'dart:io';

import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/all_techniques.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/custom_solutions.dart';
import '../../tool/doc_code.dart';

/// The register of custom solutions (docs/custom-solutions.md), the catalog's
/// `customSolution` fields, the technique docs, and the specs must agree, and
/// every good example must have a decision in the register, so that a
/// hand-built example cannot be added without one.
void main() {
  group('parseRegister', () {
    const register = '''
# Custom solutions

| Technique | Good examples |
| --- | --- |
| [C01 Button](#c01-button) | 3 |

## C01 Button

| Example | What | Verdict |
| --- | --- | --- |
| `good-text` | Nothing | not custom |
| `good-custom` | A \\| B | custom |
| `good-row` | Rows | borderline: the reason, with a colon: here |

## Notes

## I09 Other

| `good-x` | x | custom |
''';

    test('reads the rows of each technique, in order, with their verdicts', () {
      final rows = parseRegister(register);
      expect(rows.keys, ['C01', 'I09']);
      expect(
        [for (final r in rows['C01']!) (r.slug, r.verdict)],
        [
          ('good-text', Verdict.notCustom),
          ('good-custom', Verdict.custom),
          ('good-row', Verdict.borderline),
        ],
      );
      expect(rows['I09']!.single.verdict, Verdict.custom);
    });

    test('rejects a row outside a technique, a repeated slug, and an '
        'unknown verdict', () {
      for (final bad in [
        '## Intro\n\n| `good-a` | a | custom |\n',
        '## C01 Button\n\n| `good-a` | a | custom |\n| `good-a` | a | custom |\n',
        '## C01 Button\n\n| `good-a` | a | maybe |\n',
        '## C01 Button\n\n## C01 Button\n',
      ]) {
        expect(() => parseRegister(bad), throwsFormatException, reason: bad);
      }
    });

    test('compares rows without their link targets', () {
      expect(
        withoutLinkTargets('| [FL-002](../flutter-limitations.md#fl-002) |'),
        withoutLinkTargets('| [FL-002](flutter-limitations.md#fl-002) |'),
      );
    });
  });

  final register = File(registerPath).readAsStringSync();
  final rows = parseRegister(register);

  test('the register states the rule and carries the whole label', () {
    expect(register, contains(CustomSolution.label));
    expect(register, contains('## The rule'));
  });

  test('the register lists only techniques in the catalog', () {
    expect(rows.keys.toSet(), {for (final t in allTechniques) t.id});
  });

  for (final technique in allTechniques) {
    final id = technique.id;
    final good = [
      for (final e in technique.examples)
        if (e.kind == ExampleKind.good) e,
    ];
    final flagged = [
      for (final e in good)
        if (e.isCustomSolution) e.slug,
    ];

    group(id, () {
      final listed = rows[id] ?? const <RegisterRow>[];

      test('every good example has a decision in the register, and only '
          'good examples are listed', () {
        // This is what keeps a new hand-built example, a widgets-layer one
        // above all, from being added without a decision.
        expect(
          {for (final r in listed) r.slug},
          {for (final e in good) e.slug},
        );
        final widgets = [
          for (final e in good)
            if (e.variant == ExampleVariant.widgets) e.slug,
        ];
        for (final slug in widgets) {
          expect(listed.map((r) => r.slug), contains(slug), reason: slug);
        }
      });

      test('the catalog flags exactly the examples the register calls '
          'custom', () {
        expect(flagged.toSet(), {
          for (final r in listed)
            if (r.verdict == Verdict.custom) r.slug,
        });
        for (final e in good.where((e) => e.isCustomSolution)) {
          final reason = e.customSolution!;
          expect(reason.trim(), isNotEmpty, reason: e.slug);
          expect(reason, endsWith('.'), reason: '${e.slug}: one sentence');
        }
      });

      final doc = File('docs/techniques/$id.md').readAsStringSync();
      final written = handwritten(doc);

      test('the technique doc notes its custom solutions near the top', () {
        final section = _section(written, '## Custom solutions');
        if (flagged.isEmpty) {
          expect(section, isNull, reason: 'nothing is flagged');
          return;
        }
        expect(section, isNotNull, reason: 'a "## Custom solutions" section');
        expect(section, contains(CustomSolution.firstSentence));
        expect(_slugs(section!), flagged.toSet());
        expect(
          written.indexOf('\n## Custom solutions\n'),
          lessThan(written.indexOf('\n## Good examples\n')),
          reason: 'before the examples',
        );
        final table = _section(written, '## Good examples')!;
        for (final slug in flagged) {
          final row = table
              .split('\n')
              .singleWhere((l) => l.startsWith('| `$slug`'));
          expect(row, contains(CustomSolution.short), reason: slug);
        }
      });

      test('the spec has a "Custom solutions" section with the register\'s '
          'table', () {
        final spec = Directory('docs/specs')
            .listSync()
            .whereType<File>()
            .singleWhere((f) => f.uri.pathSegments.last.startsWith('$id-'))
            .readAsStringSync();
        final section = _section(spec, '### Custom solutions');
        if (flagged.isEmpty) {
          expect(section, isNull, reason: 'nothing is flagged');
          return;
        }
        expect(section, isNotNull, reason: 'a "### Custom solutions" section');
        expect(section, contains(CustomSolution.firstSentence));
        for (final slug in flagged) {
          expect(section, contains('`$slug`'), reason: slug);
        }
        final inSpec = [
          for (final line in section!.split('\n'))
            if (line.startsWith('| `')) withoutLinkTargets(line),
        ];
        expect(inSpec, [for (final r in listed) withoutLinkTargets(r.line)]);
      });
    });
  }
}

/// The text of the section of [source] that starts with the line [heading],
/// to the next heading of the same level or higher; null if there is none.
String? _section(String source, String heading) {
  final start = source.indexOf('\n$heading\n');
  if (start < 0) return null;
  final level = heading.indexOf(' ');
  final next = RegExp(
    '^#{1,$level} ',
    multiLine: true,
  ).allMatches(source).map((m) => m.start).where((i) => i > start + 1);
  return source.substring(start + 1, next.isEmpty ? null : next.first);
}

/// The example slugs named in [text].
Set<String> _slugs(String text) =>
    RegExp(r'`(good-[a-z0-9-]+)`')
        .allMatches(text)
        .map((m) => m.group(1)!)
        .toSet();
