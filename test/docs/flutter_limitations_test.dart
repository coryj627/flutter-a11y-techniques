import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// docs/flutter-limitations.md: ids are unique and in id order, each sits in
/// the place of its range (see the top of the file), the index matches the
/// entries, and every link to an entry from anywhere in the repository finds
/// it.
void main() {
  final source = File('docs/flutter-limitations.md').readAsStringSync();
  final lines = source.split('\n');

  /// The ranges in file order: (first, last). Ids before the first range's
  /// row or comment line are from before the ranges.
  const ranges = [
    (48, 69),
    (70, 99),
    (100, 199),
    (200, 299),
    (300, 399),
    (400, 499),
    (500, 599),
    (600, 699),
    (700, 799),
    (800, 899),
    (900, 999),
  ];
  const before = (1, 47);

  String fl(int n) => 'FL-${n.toString().padLeft(3, '0')}';

  final indexRow = RegExp(
    r'^\| \[FL-(\d{3})\]\(#fl-(\d{3})\) \| (.+?) \| (.+?) \| (.+?) \|$',
  );
  final rangeRow = RegExp(
    r'^\| \*\*FL-(\d{3}) to FL-(\d{3})\*\* \| .+ \| \| \|$',
  );
  final rangeComment = RegExp(
    r'^<!-- FL-(\d{3}) to FL-(\d{3}): .+\. Entries in this range go below, in id order\. -->$',
  );
  final heading = RegExp(r'^## FL-(\d{3})$');

  /// The ids in a section, with the range each sits under.
  List<(int, (int, int))> idsWithRanges(
    Iterable<String> section,
    RegExp rangeLine,
    RegExp idLine,
  ) {
    final found = <(int, (int, int))>[];
    var range = before;
    var nextRange = 0;
    for (final line in section) {
      final r = rangeLine.firstMatch(line);
      if (r != null) {
        expect(nextRange, lessThan(ranges.length), reason: line);
        expect(
          (int.parse(r.group(1)!), int.parse(r.group(2)!)),
          ranges[nextRange],
          reason: 'the ranges are listed once each, in order: $line',
        );
        range = ranges[nextRange++];
        continue;
      }
      final m = idLine.firstMatch(line);
      if (m != null) found.add((int.parse(m.group(1)!), range));
    }
    expect(nextRange, ranges.length, reason: 'every range has its place');
    return found;
  }

  final tableStart = lines.indexOf('| Id | Summary | Platforms | Status |');
  final indexLines = lines.skip(tableStart + 2).takeWhile((l) => l.isNotEmpty);
  final entriesStart = lines.indexOf('---', tableStart);
  final entryLines = lines.skip(entriesStart + 1);

  test('the index has only entry rows and range rows', () {
    expect(tableStart, greaterThan(0));
    for (final line in indexLines) {
      expect(
        indexRow.hasMatch(line) || rangeRow.hasMatch(line),
        isTrue,
        reason: line,
      );
      final m = indexRow.firstMatch(line);
      if (m != null) {
        expect(m.group(1), m.group(2), reason: 'the row links to itself');
      }
    }
  });

  // Computed inside each test, so a failure is reported by that test.
  List<(int, (int, int))> indexIds() =>
      idsWithRanges(indexLines, rangeRow, indexRow);
  List<(int, (int, int))> entryIds() =>
      idsWithRanges(entryLines, rangeComment, heading);

  test('ids are unique, in id order, and in the range they sit under', () {
    for (final (name, ids) in [
      ('index', indexIds()),
      ('entries', entryIds()),
    ]) {
      final numbers = [for (final (n, _) in ids) n];
      expect(numbers.toSet(), hasLength(numbers.length), reason: name);
      expect(numbers, [...numbers]..sort(), reason: '$name in id order');
      for (final (n, (first, last)) in ids) {
        expect(
          n >= first && n <= last,
          isTrue,
          reason: '$name: ${fl(n)} sits under ${fl(first)} to ${fl(last)}',
        );
      }
    }
  });

  test('the index and the entries list the same ids', () {
    expect(entryIds(), isNotEmpty);
    expect(
      [for (final (n, _) in indexIds()) n],
      [for (final (n, _) in entryIds()) n],
    );
  });

  test('each entry opens with its summary from the index', () {
    final summaries = {
      for (final line in indexLines)
        if (indexRow.firstMatch(line) case final m?) m.group(1)!: m.group(3)!,
    };
    final entries = RegExp(
      r'^## FL-(\d{3})\n\n\*\*(.+)\*\*$',
      multiLine: true,
    ).allMatches(source);
    expect(entries, hasLength(entryIds().length));
    for (final m in entries) {
      final bold = m.group(2)!;
      expect(bold.endsWith('.'), isTrue, reason: 'FL-${m.group(1)}: $bold');
      expect(
        bold.substring(0, bold.length - 1),
        summaries[m.group(1)],
        reason: 'FL-${m.group(1)}',
      );
    }
  });

  test('every link to an entry, anywhere in the repository, finds it', () {
    final ids = {for (final (n, _) in entryIds()) fl(n).toLowerCase()};
    final link = RegExp(r'flutter-limitations\.md#(fl-\d{3})\b');
    final inPage = RegExp(r'\]\(#(fl-\d{3})\)');
    final files = [
      File('README.md'),
      for (final dir in [
        'docs',
        'lib',
        'test',
        'tool',
        'web_tests',
        'widgetbook/lib',
      ])
        ...Directory(dir)
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => !f.path.contains('node_modules'))
            .where(
              (f) =>
                  RegExp(r'\.(md|dart|js|py|kt|swift|txt)$').hasMatch(f.path),
            ),
    ];
    var checked = 0;
    for (final file in files) {
      final text = file.readAsStringSync();
      final targets = [
        ...link.allMatches(text).map((m) => m.group(1)!),
        if (file.path.endsWith('flutter-limitations.md'))
          ...inPage.allMatches(text).map((m) => m.group(1)!),
      ];
      for (final target in targets) {
        checked++;
        expect(ids, contains(target), reason: '${file.path} links to #$target');
      }
    }
    expect(checked, greaterThan(50));
  });
}
