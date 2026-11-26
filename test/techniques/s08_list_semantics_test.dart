import 'dart:math' as math;
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/app/screens.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/s08_list_semantics/examples.dart';
import 'package:flutter_a11y_techniques/techniques/s08_list_semantics/s08_list_semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/examples.dart';

/// L1 for S08 List semantics (docs/specs/S08-list-semantics.md, section 6).
/// These tests run as Android: `kIsWeb` is false, so what the web engine
/// makes of a node (a list item that is also a button is only a list item
/// there, FL-262) is tested in web_tests/s08_list_semantics.spec.js.
final _open = exampleOpener(s08ListSemantics);

const _good = [
  'good-bulleted',
  'good-numbered',
  'good-material',
  'good-cupertino',
];

/// The lists of tiles, each with its tiles' identifiers by title.
final _tiles = {
  for (final slug in ['good-material', 'bad-tile-in-item'])
    slug: {for (final g in groceries) g: 's08-$slug-${g.toLowerCase()}'},
};

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// What the "Chosen" line of [slug] says.
String _chosen(WidgetTester tester, String slug) => tester
    .widget<Text>(
      find.descendant(
        of: find.byKey(ValueKey<String>('s08-$slug-chosen')),
        matching: find.byType(Text),
      ),
    )
    .data!;

/// One line per node of the example, after the "Example" heading and up to
/// its "Chosen" line, in traversal order, indented by depth under the
/// example: its role (when it has one), its label, and its button flag and
/// tap action. A node merged into its parent is left out, and so is a node
/// with no role and no label that only holds others: what is left is what
/// assistive technology is given.
List<String> _tree(WidgetTester tester) {
  final out = <(int, SemanticsData)>[];
  void visit(SemanticsNode node, int depth) {
    if (node.isMergedIntoParent) return;
    out.add((depth, node.getSemanticsData()));
    for (final child in node.debugListChildrenInOrder(
      DebugSemanticsDumpOrder.traversalOrder,
    )) {
      visit(child, depth + 1);
    }
  }

  visit(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
    0,
  );
  final start = out.indexWhere((n) => n.$2.label == 'Example');
  expect(start, isNonNegative, reason: 'the Example heading');
  final base = out[start].$1;
  final lines = <String>[];
  for (final (depth, n) in out.skip(start + 1)) {
    if (depth < base) break;
    if (n.label.startsWith('Chosen: ')) break;
    final role = n.role == SemanticsRole.none ? '' : n.role.name;
    if (role.isEmpty && n.label.isEmpty) continue;
    lines.add(
      '${'  ' * (depth - base)}${[if (role.isNotEmpty) role, if (n.label.isNotEmpty) '"${n.label}"', if (n.flagsCollection.isButton) 'button', if (n.hasAction(SemanticsAction.tap)) 'tap'].join(' ')}',
    );
  }
  return lines;
}

/// Every paragraph of text that the example's own widget draws.
List<RenderParagraph> _exampleParagraphs(
  WidgetTester tester,
  TechniqueExample example,
) {
  final widget = example.builder(tester.element(find.byType(ExampleScreen)));
  expect(find.byType(widget.runtimeType), findsOneWidget);
  return tester
      .renderObjectList<RenderParagraph>(
        find.descendant(
          of: find.byType(widget.runtimeType),
          matching: find.byType(RichText),
        ),
      )
      .toList();
}

void main() {
  test('the technique has the examples named in the spec', () {
    expect(s08ListSemantics.examples.map((e) => e.slug), [
      ..._good,
      'bad-one-text',
      'bad-no-list',
      'bad-tile-in-item',
      'bad-lazy-list',
    ]);
    expect(_good, [
      for (final e in s08ListSemantics.examples)
        if (e.kind == ExampleKind.good) e.slug,
    ]);
    expect(
      s08ListSemantics.examples.where((e) => e.isCustomSolution),
      isEmpty,
      reason: 'no good example is a custom solution',
    );
  });

  group('good examples', () {
    for (final slug in _good) {
      for (final brightness in Brightness.values) {
        testWidgets('$slug meets the guidelines (${brightness.name})', (
          tester,
        ) async {
          final handle = tester.ensureSemantics();
          await _open(tester, slug, brightness: brightness);
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          handle.dispose();
        });
      }

      testWidgets('$slug: the framework reports no error', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        // The framework checks, in a debug build, that a list item's parent
        // node is a list; a failed check is thrown here.
        expect(tester.takeException(), isNull);
        handle.dispose();
      });
    }

    testWidgets('good-bulleted: a list of three items, each its line', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-bulleted');
      expect(_tree(tester), [
        'list',
        for (final g in groceries) '  listItem "$g"',
      ]);
      handle.dispose();
    });

    testWidgets('good-numbered: a list of three items, each with its '
        'number', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-numbered');
      expect(_tree(tester), [
        'list',
        for (final (i, s) in steps.indexed) '  listItem "${i + 1}. $s"',
      ]);
      handle.dispose();
    });

    testWidgets('good-material: a list of three items, each holding one '
        'button', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-material');
      expect(_tree(tester), [
        'list',
        for (final g in groceries) ...['  listItem', '    "$g" button tap'],
      ]);
      handle.dispose();
    });

    testWidgets('good-cupertino: a list named by its header, of three items, '
        'and no control', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-cupertino');
      expect(_tree(tester), [
        'list "Groceries"',
        for (final g in groceries) '  listItem "$g"',
      ]);
      handle.dispose();
    });

    for (final brightness in Brightness.values) {
      testWidgets('good-bulleted: the bullets are 3:1 or more against the '
          'page (${brightness.name})', (tester) async {
        await _open(tester, 'good-bulleted', brightness: brightness);
        final ctx = tester.element(find.byType(Bullet).first);
        final page = Theme.of(ctx).scaffoldBackgroundColor;
        for (final box in tester.widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(Bullet),
            matching: find.byType(DecoratedBox),
          ),
        )) {
          final colour = (box.decoration as BoxDecoration).color!;
          expect(_contrast(colour, page), greaterThanOrEqualTo(3));
        }
      });

      testWidgets('good-material: keyboard focus tints the tile (FL-434), '
          'under 3:1 against the page (${brightness.name})', (tester) async {
        await _open(tester, 'good-material', brightness: brightness);
        final theme = Theme.of(tester.element(byId('s08-good-material-milk')));
        final page = theme.scaffoldBackgroundColor;
        final tint = Color.alphaBlend(theme.focusColor, page);
        final ratio = _contrast(tint, page);
        // FL-434: a change of background within the component, which
        // Understanding 1.4.11 puts out of its scope. Written to fail if
        // the tint reaches 3:1, so the entry is looked at again.
        expect(ratio, lessThan(3));
        expect(ratio, greaterThan(1));
      });

      for (final g in groceries) {
        testWidgets('good-material: with keyboard focus on $g the text still '
            'meets the contrast guideline (${brightness.name})', (
          tester,
        ) async {
          final handle = tester.ensureSemantics();
          await _open(tester, 'good-material', brightness: brightness);
          await tabTo(tester, _tiles['good-material']![g]!);
          await tester.pumpAndSettle();
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          handle.dispose();
        });
      }
    }

    testWidgets('good-material: Tab goes Back, then each tile in turn', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-material');
      final stops = <String>[];
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final focused = semanticsNodes(tester)
            .where((n) => n.flagsCollection.isFocused == Tristate.isTrue);
        stops.add(
          focused.map((n) => n.tooltip.isNotEmpty ? n.tooltip : n.label).single,
        );
      }
      expect(stops, ['Back', ...groceries]);
      handle.dispose();
    });
  });

  // Both lists of tiles: each tile, by a tap, by the tap action, and by Tab
  // then Enter or Space, opens its own item and no other. In bad-tile-in-item
  // this is the positive control: everything but the web's role works.
  for (final MapEntry(key: slug, value: tiles) in _tiles.entries) {
    for (final MapEntry(key: g, value: id) in tiles.entries) {
      testWidgets('$slug: a tap and the tap action on $g each open $g', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        expect(_chosen(tester, slug), 'Chosen: none');
        await tester.tap(byId(id));
        await tester.pumpAndSettle();
        expect(_chosen(tester, slug), 'Chosen: $g', reason: 'tap');
        // Back to none: open another, then the tap action on this one.
        final other = tiles.values.firstWhere((o) => o != id);
        await tester.tap(byId(other));
        await tester.pumpAndSettle();
        expect(_chosen(tester, slug), isNot('Chosen: $g'));
        tester.semantics.tap(nodeById(id));
        await tester.pumpAndSettle();
        expect(_chosen(tester, slug), 'Chosen: $g', reason: 'tap action');
        handle.dispose();
      });

      for (final (key, name) in [
        (LogicalKeyboardKey.enter, 'Enter'),
        (LogicalKeyboardKey.space, 'Space'),
      ]) {
        testWidgets('$slug: Tab reaches $g and $name opens it', (tester) async {
          final handle = tester.ensureSemantics();
          await _open(tester, slug);
          await tabTo(tester, id);
          await tester.sendKeyEvent(key);
          await tester.pumpAndSettle();
          expect(_chosen(tester, slug), 'Chosen: $g');
          handle.dispose();
        });
      }
    }
  }

  // Every example, good and bad: at 200% text on a 320 by 640 screen no
  // layout overflows, and no text in the example is cut short, by a line
  // limit or by a box too small for its lines.
  for (final example in s08ListSemantics.examples) {
    final slug = example.slug;
    testWidgets('$slug: at 200% text on a phone nothing overflows and no '
        'text is cut short', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _open(tester, slug, textScale: 2);
      expect(tester.takeException(), isNull);
      final paragraphs = _exampleParagraphs(tester, example);
      expect(paragraphs, isNotEmpty);
      for (final p in paragraphs) {
        final text = p.text.toPlainText();
        expect(p.didExceedMaxLines, isFalse, reason: '"$text" hit its limit');
        final painter = TextPainter(
          text: p.text,
          textDirection: p.textDirection,
          textScaler: p.textScaler,
          textAlign: p.textAlign,
        )..layout(maxWidth: p.size.width);
        expect(
          p.size.height,
          greaterThanOrEqualTo(painter.height - 0.5),
          reason: '"$text" is cut short in its box',
        );
        expect(
          p.localToGlobal(Offset(p.size.width, 0)).dx,
          lessThanOrEqualTo(320.5),
          reason: '"$text" runs past the screen',
        );
        painter.dispose();
      }
    });
  }

  group('bad examples have their defect', () {
    testWidgets('bad-one-text: one node holds every item; no list and no '
        'item', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-one-text');
      expect(_tree(tester), ['"${groceries.join('\n')}"']);
      handle.dispose();
    });

    testWidgets('bad-no-list: each line a node of its own; no list and no '
        'item', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-no-list');
      expect(_tree(tester), [for (final g in groceries) '"$g"']);
      handle.dispose();
    });

    testWidgets('bad-tile-in-item: each tile is merged into its list item, '
        'one node that is a list item and a button', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-tile-in-item');
      expect(_tree(tester), [
        'list',
        for (final g in groceries) '  listItem "$g" button tap',
      ]);
      handle.dispose();
    });

    testWidgets('bad-lazy-list: no list role; the scroll view says it holds '
        '30 items, and only those near the view are nodes', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-lazy-list');
      final nodes = semanticsNodes(tester);
      expect(nodes.where((n) => n.role == SemanticsRole.list), isEmpty);
      expect(nodes.where((n) => n.role == SemanticsRole.listItem), isEmpty);
      final scroller = nodes.singleWhere((n) => n.scrollChildCount != null);
      expect(scroller.scrollChildCount, orderCount);
      List<int> orders() => [
        for (final n in semanticsNodes(tester))
          if (RegExp(r'^Order (\d+)$').firstMatch(n.label) case final m?)
            int.parse(m.group(1)!),
      ];
      final atStart = orders();
      expect(atStart.first, 1);
      expect(atStart.length, lessThan(orderCount), reason: 'FL-011');
      // Scrolled to its end, the first orders are gone from the tree.
      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pumpAndSettle();
      final atEnd = orders();
      expect(atEnd.last, orderCount);
      expect(atEnd, isNot(contains(1)), reason: 'FL-011');
      handle.dispose();
    });
  });
}
