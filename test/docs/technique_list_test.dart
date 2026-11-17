import 'dart:io';

import 'package:flutter_a11y_techniques/techniques/all_techniques.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/technique_list.dart';

/// The list of techniques in the app and in the README is generated from the
/// folders in lib/techniques/, so pull requests that add techniques do not
/// all edit the same lines by hand.
void main() {
  final root = Directory.current;

  test('all_techniques.dart and the README are up to date', () {
    for (final MapEntry(key: path, value: content) in expectedFiles(
      root,
    ).entries) {
      expect(
        File(path).readAsStringSync(),
        content,
        reason: '$path. Run: dart run tool/technique_list.dart',
      );
    }
  });

  test('allTechniques holds one technique per folder, in folder order', () {
    expect(
      [for (final t in allTechniques) t.id],
      [for (final t in techniqueFolders(root)) t.id],
    );
  });

  test('the README lists the techniques in catalog order', () {
    final ordered = inCatalogOrder(techniqueFolders(root), groupOrder(root));
    final readme = File(readmePath).readAsStringSync();
    final listed = RegExp(
      r'\]\(docs/techniques/([A-Z]\d\d)\.md#how-it-is-tested\)',
    ).allMatches(readme).map((m) => m.group(1)).toList();
    expect(listed, [for (final t in ordered) t.id]);
  });

  group('idList', () {
    test('writes three or more ids in a row in one group as a range', () {
      expect(
        idList(['S01', 'S02', 'S03', 'S05', 'S06', 'I12', 'F01']),
        'S01 to S03, S05, S06, I12, and F01',
      );
      expect(idList(['S09', 'S10', 'S11']), 'S09 to S11');
      // A run does not cross groups.
      expect(idList(['F09', 'G10', 'G11']), 'F09, G10, and G11');
    });

    test('joins one, two, and more ids', () {
      expect(idList(['C01']), 'C01');
      expect(idList(['C01', 'F01']), 'C01 and F01');
      expect(idList(['C01', 'F01', 'I12']), 'C01, F01, and I12');
    });
  });

  test('catalog order is by group, then id', () {
    final ordered = inCatalogOrder(
      [
        TechniqueFolder('c01_button', 'Button'),
        TechniqueFolder('s05_headings', 'Headings'),
        TechniqueFolder('f01_text_fields', 'Text fields'),
        TechniqueFolder('s01_names', 'Names'),
      ],
      ['S', 'V', 'I', 'F', 'C'],
    );
    expect([for (final t in ordered) t.id], ['S01', 'S05', 'F01', 'C01']);
    expect(
      () => inCatalogOrder([TechniqueFolder('z01_x', 'X')], ['S']),
      throwsFormatException,
    );
  });

  test('the variable name comes from the folder name', () {
    expect(
      TechniqueFolder('s14_values_and_state_descriptions', '').variable,
      's14ValuesAndStateDescriptions',
    );
    expect(TechniqueFolder('c01_button', '').variable, 'c01Button');
  });

  test('the README list ends with "and" and a full stop', () {
    final list = readmeList([
      TechniqueFolder('c01_button', 'Button'),
      TechniqueFolder('f01_text_fields', 'Text fields'),
    ]);
    expect(list.split('\n').skip(3).toList(), [
      '[C01 Button](docs/techniques/C01.md#how-it-is-tested), and',
      '[F01 Text fields](docs/techniques/F01.md#how-it-is-tested).',
    ]);
  });

  test('replaceBetween refuses missing, misplaced, or repeated markers', () {
    expect(
      replaceBetween('a\n<s>\nold\n<e>\nb', '<s>', '<e>', 'new'),
      'a\n<s>\nnew\n<e>\nb',
    );
    expect(
      () => replaceBetween('<s> only', '<s>', '<e>', ''),
      throwsFormatException,
    );
    expect(
      () => replaceBetween('<e> <s>', '<s>', '<e>', ''),
      throwsFormatException,
    );
    expect(
      () => replaceBetween('<s> <e> <s> <e>', '<s>', '<e>', ''),
      throwsFormatException,
    );
  });

  group('techniqueFolders', () {
    late Directory temp;

    setUp(() {
      temp = Directory.systemTemp.createTempSync('technique_list_test');
      Directory('${temp.path}/lib/techniques').createSync(recursive: true);
      Directory('${temp.path}/docs/techniques').createSync(recursive: true);
    });
    tearDown(() => temp.deleteSync(recursive: true));

    void add(String folder, {String? declaration, bool doc = true}) {
      final id = folder.substring(0, 3).toUpperCase();
      final variable = TechniqueFolder(folder, '').variable;
      File('${temp.path}/lib/techniques/$folder/$folder.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync(
          declaration ?? 'final $variable = Technique(\n  id: "$id",\n);\n',
        );
      if (doc) {
        File('${temp.path}/docs/techniques/$id.md')
            .writeAsStringSync('---\nid: $id\ntitle: Thing $id\n---\n');
      }
    }

    test('reads each folder, its variable, and its title', () {
      add('s05_headings');
      add('c01_button');
      final found = techniqueFolders(temp);
      expect([for (final t in found) t.folder], ['c01_button', 's05_headings']);
      expect(found.first.title, 'Thing C01');
    });

    test('refuses a badly named folder', () {
      add('c01_button');
      Directory('${temp.path}/lib/techniques/Button').createSync();
      expect(() => techniqueFolders(temp), throwsFormatException);
    });

    test('refuses two folders with one id', () {
      add('c01_button');
      add('c01_other');
      expect(() => techniqueFolders(temp), throwsFormatException);
    });

    test('refuses a folder whose file does not declare the technique', () {
      add('c01_button', declaration: 'final button = Technique(\n);\n');
      expect(() => techniqueFolders(temp), throwsFormatException);
    });

    test('refuses a technique with no doc', () {
      add('c01_button', doc: false);
      expect(() => techniqueFolders(temp), throwsFormatException);
    });
  });
}
