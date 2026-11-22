/// Reads `docs/custom-solutions.md`, the register of custom solutions: one
/// section per technique, `## X00 Title`, with a table that has a row for
/// each of the technique's good examples, the slug in its first cell and the
/// verdict at the start of its last (`custom`, `not custom`, or
/// `borderline`, which may be followed by `:` and the reasoning).
///
/// `tool/doc_code.dart` labels the code of the custom ones, and
/// `test/docs/custom_solutions_test.dart` checks the register against the
/// catalog, the technique docs, and the specs.
library;

import 'dart:io';

const registerPath = 'docs/custom-solutions.md';

enum Verdict { custom, notCustom, borderline }

/// One row of the register.
class RegisterRow {
  RegisterRow(this.slug, this.verdict, this.line);

  /// For example `good-custom`.
  final String slug;
  final Verdict verdict;

  /// The row as it is written.
  final String line;
}

final _section = RegExp(r'^## ([A-Z]\d\d) ');
final _row = RegExp(r'^\| `((?:good|bad)-[a-z0-9-]+)` \|');

/// The rows of [source], by technique id, in the order they are written.
///
/// Throws a [FormatException] for a row outside a technique's section, a
/// slug listed twice for one technique, a technique listed twice, or a row
/// whose verdict is not one of the three.
Map<String, List<RegisterRow>> parseRegister(String source) {
  final found = <String, List<RegisterRow>>{};
  String? id;
  var number = 0;
  for (final line in source.split('\n')) {
    number++;
    final section = _section.firstMatch(line);
    if (section != null) {
      id = section.group(1)!;
      if (found.containsKey(id)) {
        throw FormatException('line $number: $id has two sections');
      }
      found[id] = [];
      continue;
    }
    if (line.startsWith('## ')) {
      id = null;
      continue;
    }
    final row = _row.firstMatch(line);
    if (row == null) continue;
    final slug = row.group(1)!;
    if (id == null) {
      throw FormatException('line $number: `$slug` is not in a technique');
    }
    final rows = found[id]!;
    if (rows.any((r) => r.slug == slug)) {
      throw FormatException('line $number: $id lists `$slug` twice');
    }
    rows.add(RegisterRow(slug, _verdict(line, number), line));
  }
  return found;
}

Verdict _verdict(String line, int number) {
  final cells = cellsOf(line);
  final last = cells.last;
  if (last == 'custom') return Verdict.custom;
  if (last == 'not custom') return Verdict.notCustom;
  if (last == 'borderline' || last.startsWith('borderline: ')) {
    return Verdict.borderline;
  }
  throw FormatException('line $number: no verdict in "$last"');
}

/// The cells of a Markdown table row, trimmed; `\|` stays inside a cell.
List<String> cellsOf(String line) {
  final inner = line.trim().replaceFirst(RegExp(r'^\|'), '');
  final cells = inner.split(RegExp(r'(?<!\\)\|')).map((c) => c.trim());
  return cells.toList()..removeLast();
}

/// [line] with every Markdown link reduced to its text, so that rows that
/// link to the same entries from different folders compare equal.
String withoutLinkTargets(String line) =>
    line.replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]*\)'), (m) => m[1]!);

/// The slugs flagged as custom for technique [id] in the register under
/// [root], or none if the register does not list it.
Set<String> customSlugs(Directory root, String id) {
  final file = File('${root.path}/$registerPath');
  if (!file.existsSync()) return const {};
  final rows = parseRegister(file.readAsStringSync())[id] ?? const [];
  return {
    for (final r in rows)
      if (r.verdict == Verdict.custom) r.slug,
  };
}
