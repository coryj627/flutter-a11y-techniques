import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/app/doc_view.dart';
import 'package:flutter_test/flutter_test.dart';

const _doc = '''
---
id: T01
wcag: ["4.1.2"]
---

# T01 Sample

Intro with **bold**, `code`, and a [web link](https://www.w3.org/TR/WCAG22/).

## Skipped

This section is left out.

## Kept section

### Sub section

- First item with a [repo link](../specs/T01.md)
- Second item

1. Step one
2. Step two

| Example | Defect |
| --- | --- |
| `bad-one` | No name. See [APG](https://www.w3.org/WAI/ARIA/apg/). |

```dart
final a = 1;
```

See [same page](#kept-section) and [insecure](http://example.com/).
''';

class _Bundle extends CachingAssetBundle {
  _Bundle(this.files);

  final Map<String, String> files;

  @override
  Future<ByteData> load(String key) async {
    final value = files[key];
    if (value == null) throw FlutterError('missing $key');
    return ByteData.sublistView(utf8.encode(value));
  }
}

Future<void> _pump(
  WidgetTester tester, {
  String id = 'T01',
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) async {
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  await tester.pumpWidget(
    DefaultAssetBundle(
      bundle: _Bundle({'docs/techniques/T01.md': _doc}),
      child: MaterialApp(
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          brightness: brightness,
        ),
        home: Scaffold(
          body: ListView(
            children: [
              TechniqueDocView(
                techniqueId: id,
                skipSections: const {'Skipped'},
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('stripFrontMatter removes the YAML block only', () {
    expect(stripFrontMatter('---\nid: X\n---\n\n# Title\n'), '\n# Title\n');
    expect(stripFrontMatter('# Title\n'), '# Title\n');
  });

  testWidgets('headings keep their level; title and skipped section are out', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);
    expect(find.text('T01 Sample'), findsNothing);
    expect(find.text('Skipped'), findsNothing);
    expect(find.text('This section is left out.'), findsNothing);
    expect(
      tester.getSemantics(find.text('Kept section')),
      isSemantics(isHeader: true),
    );
    expect(
      tester.getSemantics(find.text('Sub section')),
      isSemantics(isHeader: true),
    );
    int level(String text) =>
        tester.getSemantics(find.text(text)).getSemanticsData().headingLevel;
    expect(level('Kept section'), 2);
    expect(level('Sub section'), 3);
    handle.dispose();
  });

  testWidgets('links are real links; in-page and non-https links are dropped', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);
    for (final (title, url) in [
      ('web link', 'https://www.w3.org/TR/WCAG22/'),
      (
        'repo link',
        'https://github.com/coryj627/flutter-a11y-techniques/blob/main/docs/specs/T01.md',
      ),
      ('APG', 'https://www.w3.org/WAI/ARIA/apg/'),
    ]) {
      final node = tester.getSemantics(find.text(title));
      expect(
        node,
        isSemantics(isLink: true, hasTapAction: true),
        reason: title,
      );
      expect(node.getSemanticsData().linkUrl, Uri.parse(url), reason: title);
    }
    expect(find.text('same page'), findsNothing);
    expect(find.text('insecure'), findsNothing);
    handle.dispose();
  });

  testWidgets('lists have list and list item roles', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);
    final roles = <SemanticsRole>[];
    void visit(SemanticsNode node) {
      roles.add(node.getSemanticsData().role);
      node.visitChildren((child) {
        visit(child);
        return true;
      });
    }

    visit(tester.getSemantics(find.byType(ListView)));
    expect(roles.where((r) => r == SemanticsRole.list), hasLength(2));
    expect(roles.where((r) => r == SemanticsRole.listItem), hasLength(4));
    handle.dispose();
  });

  testWidgets('a table row reads as header and value pairs', (tester) async {
    await _pump(tester);
    expect(
      find.textContaining('Example: bad-one', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Defect: No name. See APG.', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('final a = 1;'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets('meets the guidelines (${brightness.name})', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, brightness: brightness);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  }

  testWidgets('does not overflow at 200% text on a phone', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _pump(tester, textScale: 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a technique with no doc shows nothing and does not throw', (
    tester,
  ) async {
    await _pump(tester, id: 'NOPE');
    expect(tester.takeException(), isNull);
    expect(find.byType(Text), findsNothing);
  });
}
