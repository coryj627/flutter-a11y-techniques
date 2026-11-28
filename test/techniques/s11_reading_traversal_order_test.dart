import 'dart:math' as math;
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/app/screens.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/s11_reading_traversal_order/examples.dart';
import 'package:flutter_a11y_techniques/techniques/s11_reading_traversal_order/s11_reading_traversal_order.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/examples.dart';

/// L1 for S11 Reading and traversal order
/// (docs/specs/S11-reading-traversal-order.md, section 6). These tests run as
/// Android, with the test font, whose letters are wider than a real font's,
/// so a line wraps sooner here than on a device; where the reading order
/// rests on the parts' positions (`bad-columns-mixed`) the order measured
/// here is this layer's own, and each device layer asserts what it measured.
final _open = exampleOpener(s11ReadingTraversalOrder);

const _good = ['good-columns', 'good-sort-keys'];
const _bad = ['bad-columns-mixed', 'bad-key-missing'];

/// The order meant: the route column, then the bring column, then the counts.
const _meant = [
  '$routeTitle | heading 3',
  'Park at the gate.',
  'Climb the ridge.',
  'Walk back.',
  'Save route | button',
  '$bringTitle | heading 3',
  'Water',
  'A map',
  'Save list | button',
  'Route saves: 0',
  'List saves: 0',
];

String _id(String slug, String name) => 's11-$slug-$name';

/// The screen sizes the order is read at: a phone held upright, CI's
/// emulator (320 by 640), and the test window's default (800 by 600).
const _sizes = [Size(412, 915), Size(320, 640), Size(800, 600)];

Future<void> _openAt(
  WidgetTester tester,
  String slug,
  Size size, {
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await _open(tester, slug, textScale: textScale);
}

String _describe(SemanticsData n) => [
  n.label,
  if (n.headingLevel > 0) 'heading ${n.headingLevel}',
  if (n.flagsCollection.isButton) 'button',
].join(' | ');

/// Every node in traversal order, the order the framework gives the
/// platforms, a node merged into its parent left out.
List<SemanticsData> _traversal(WidgetTester tester) {
  final all = <SemanticsData>[];
  void visit(SemanticsNode node) {
    if (!node.isMergedIntoParent) all.add(node.getSemanticsData());
    for (final child in node.debugListChildrenInOrder(
      DebugSemanticsDumpOrder.traversalOrder,
    )) {
      visit(child);
    }
  }

  visit(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return all;
}

/// The example's nodes with a label, in traversal order, from the first node
/// after the "Example" heading to the end of the screen: what a screen
/// reader moves through. Nodes with no label (the columns' containers) are
/// left out.
List<String> _reading(WidgetTester tester) {
  final all = _traversal(tester);
  final start = all.indexWhere((n) => n.label == 'Example');
  expect(start, isNonNegative, reason: 'the Example heading');
  return [
    for (final n in all.sublist(start + 1))
      if (n.label.isNotEmpty) _describe(n),
  ];
}

bool _focused(String id) =>
    dataById(id).flagsCollection.isFocused == Tristate.isTrue;

/// The name of the one node with keyboard focus.
String _stop(WidgetTester tester) {
  final focused = semanticsNodes(tester)
      .where((n) => n.flagsCollection.isFocused == Tristate.isTrue)
      .toList();
  expect(focused, hasLength(1), reason: 'one node has keyboard focus');
  final n = focused.single;
  return n.tooltip.isNotEmpty ? n.tooltip : n.label;
}

Future<List<String>> _keyStops(
  WidgetTester tester,
  int count, {
  bool shift = false,
}) async {
  final stops = <String>[];
  for (var i = 0; i < count; i++) {
    if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    stops.add(_stop(tester));
  }
  return stops;
}

int _count(WidgetTester tester, String slug, String name) {
  final text = tester.widget<Text>(
    find.descendant(
      of: find.byKey(ValueKey<String>(_id(slug, name))),
      matching: find.byType(Text),
    ),
  );
  return int.parse(text.data!.split(': ').last);
}

Map<String, int> _counts(WidgetTester tester, String slug) => {
  'route': _count(tester, slug, 'route-saves'),
  'list': _count(tester, slug, 'list-saves'),
};

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
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

/// The order of [labels] among the siblings built by [children], each a
/// semantics node, in a bare app.
Future<List<String>> _siblingOrder(
  WidgetTester tester,
  Widget child, {
  required List<String> labels,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return [
    for (final n in _traversal(tester))
      if (labels.contains(n.label)) n.label,
  ];
}

void main() {
  test('the technique has the examples named in the spec', () {
    expect(s11ReadingTraversalOrder.examples.map((e) => e.slug), [
      ..._good,
      ..._bad,
    ]);
    expect(_good, [
      for (final e in s11ReadingTraversalOrder.examples)
        if (e.kind == ExampleKind.good) e.slug,
    ]);
    expect(
      s11ReadingTraversalOrder.examples.where((e) => e.isCustomSolution),
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

        for (final button in ['save-route', 'save-list']) {
          testWidgets('$slug: with keyboard focus on $button the text still '
              'meets the contrast guideline (${brightness.name})', (
            tester,
          ) async {
            final handle = tester.ensureSemantics();
            await _open(tester, slug, brightness: brightness);
            await tabTo(tester, _id(slug, button));
            await tester.pumpAndSettle();
            expect(_focused(_id(slug, button)), isTrue);
            await expectLater(tester, meetsGuideline(textContrastGuideline));
            handle.dispose();
          });
        }

        testWidgets('$slug: each button draws a 2 pixel outline in the text '
            'colour, 3:1 or more on the page, only while it has focus '
            '(${brightness.name})', (tester) async {
          await _open(tester, slug, brightness: brightness);
          final colors = Theme.of(tester.element(byId(_id(slug, 'save-route'))))
              .colorScheme;
          for (final button in ['save-route', 'save-list']) {
            final style = tester
                .widget<TextButton>(
                  find.descendant(
                    of: byId(_id(slug, button)),
                    matching: find.byType(TextButton),
                  ),
                )
                .style!;
            final side = style.side!.resolve({WidgetState.focused})!;
            expect(side.color, colors.onSurface, reason: button);
            expect(side.width, 2, reason: button);
            expect(
              _contrast(side.color, colors.surface),
              greaterThanOrEqualTo(3),
              reason: '$button against the page',
            );
            expect(
              style.side!.resolve({}),
              isNull,
              reason: '$button unfocused',
            );
            expect(
              style.side!.resolve({WidgetState.hovered}),
              isNull,
              reason: '$button hovered',
            );
          }
        });
      }

      for (final size in _sizes) {
        for (final scale in [1.0, 2.0]) {
          testWidgets('$slug: read in the order meant, the route column and '
              'then the bring column, at ${size.width.toInt()} by '
              '${size.height.toInt()} and ${(scale * 100).toInt()}% text', (
            tester,
          ) async {
            final handle = tester.ensureSemantics();
            await _openAt(tester, slug, size, textScale: scale);
            expect(_reading(tester), _meant);
            handle.dispose();
          });
        }
      }

      testWidgets('$slug: Tab reaches the buttons in their reading order, '
          'then goes round to Back; Shift+Tab goes back the same way', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        final read = [
          for (final part in _reading(tester))
            if (part.endsWith(' | button')) part.split(' | ').first,
        ];
        expect(read, ['Save route', 'Save list']);
        expect(await _keyStops(tester, 4), ['Back', ...read, 'Back']);
        expect(await _keyStops(tester, 3, shift: true), [
          ...read.reversed,
          'Back',
        ]);
        handle.dispose();
      });

      for (final (button, count) in [
        ('save-route', 'route'),
        ('save-list', 'list'),
      ]) {
        testWidgets('$slug: a tap and the tap action on $button each add one '
            'to its own count, and to no other', (tester) async {
          final handle = tester.ensureSemantics();
          await _open(tester, slug);
          expect(_counts(tester, slug), {'route': 0, 'list': 0});
          await tester.tap(byId(_id(slug, button)));
          await tester.pumpAndSettle();
          expect(_counts(tester, slug), {
            'route': count == 'route' ? 1 : 0,
            'list': count == 'list' ? 1 : 0,
          }, reason: 'tap');
          tester.semantics.tap(nodeById(_id(slug, button)));
          await tester.pumpAndSettle();
          expect(_counts(tester, slug), {
            'route': count == 'route' ? 2 : 0,
            'list': count == 'list' ? 2 : 0,
          }, reason: 'tap action');
          handle.dispose();
        });

        for (final (key, name) in [
          (LogicalKeyboardKey.enter, 'Enter'),
          (LogicalKeyboardKey.space, 'Space'),
        ]) {
          testWidgets('$slug: Tab reaches $button and $name adds one to its '
              'own count, and to no other', (tester) async {
            final handle = tester.ensureSemantics();
            await _open(tester, slug);
            await tabTo(tester, _id(slug, button));
            await tester.sendKeyEvent(key);
            await tester.pumpAndSettle();
            expect(_counts(tester, slug), {
              'route': count == 'route' ? 1 : 0,
              'list': count == 'list' ? 1 : 0,
            });
            handle.dispose();
          });
        }
      }
    }

    testWidgets('good-sort-keys: every part of the two columns has its own '
        'OrdinalSortKey, the route 1 to 5 and the list 6 to 9', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-sort-keys');
      final keyed = <String, double>{};
      for (final s in tester.widgetList<Semantics>(
        find.descendant(
          of: find.byType(GoodSortKeys),
          matching: find.byType(Semantics),
        ),
      )) {
        final key = s.properties.sortKey;
        if (key is! OrdinalSortKey) continue;
        final texts = tester
            .widgetList<Text>(
              find.descendant(
                of: find.byWidget(s),
                matching: find.byType(Text),
              ),
            )
            .map((t) => t.data!)
            .toList();
        keyed[texts.single] = key.order;
      }
      expect(keyed, {
        routeTitle: 1,
        routeSteps[0]: 2,
        routeSteps[1]: 3,
        routeSteps[2]: 4,
        'Save route': 5,
        bringTitle: 6,
        bringItems[0]: 7,
        bringItems[1]: 8,
        'Save list': 9,
      });
      handle.dispose();
    });
  });

  // Every example, good and bad: at 200% text on a 320 by 640 screen no
  // layout overflows, and no text in the example is cut short, by a line
  // limit or by a box too small for its lines.
  for (final example in s11ReadingTraversalOrder.examples) {
    final slug = example.slug;
    testWidgets('$slug: at 200% text on a phone nothing overflows and no '
        'text is cut short', (tester) async {
      await _openAt(tester, slug, const Size(320, 640), textScale: 2);
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
    // bad-columns-mixed: the order rests on the parts' positions, so it is
    // measured per size and per platform (with the test font here). At every
    // size the two titles are read first, one after the other, and the order
    // is not the one meant. Written to fail if Flutter starts to read a
    // column as one block by itself.
    // Measured here, with the test font (each step wraps at 136 pixels
    // wide, so some rows overlap and part of a column is read down it).
    // Only at 800 by 600 and 100%, where nothing wraps, is it row by row
    // throughout.
    const mixed = <String, List<String>>{
      '412 100': [
        '$routeTitle | heading 3',
        '$bringTitle | heading 3',
        'Park at the gate.',
        'Water',
        'A map',
        'Climb the ridge.',
        'Walk back.',
        'Save list | button',
        'Save route | button',
      ],
      '412 200': [
        '$routeTitle | heading 3',
        '$bringTitle | heading 3',
        'Park at the gate.',
        'Climb the ridge.',
        'Water',
        'A map',
        'Save list | button',
        'Walk back.',
        'Save route | button',
      ],
      '320 100': [
        '$routeTitle | heading 3',
        '$bringTitle | heading 3',
        'Park at the gate.',
        'Water',
        'A map',
        'Climb the ridge.',
        'Walk back.',
        'Save list | button',
        'Save route | button',
      ],
      '320 200': [
        '$routeTitle | heading 3',
        '$bringTitle | heading 3',
        'Park at the gate.',
        'Climb the ridge.',
        'Water',
        'A map',
        'Save list | button',
        'Walk back.',
        'Save route | button',
      ],
      '800 100': [
        '$routeTitle | heading 3',
        '$bringTitle | heading 3',
        'Park at the gate.',
        'Water',
        'Climb the ridge.',
        'A map',
        'Walk back.',
        'Save route | button',
        'Save list | button',
      ],
      '800 200': [
        '$routeTitle | heading 3',
        '$bringTitle | heading 3',
        'Park at the gate.',
        'Water',
        'A map',
        'Climb the ridge.',
        'Save list | button',
        'Walk back.',
        'Save route | button',
      ],
    };
    for (final size in _sizes) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('bad-columns-mixed: read across the columns, both '
            'titles first, at ${size.width.toInt()} by ${size.height.toInt()} '
            'and ${(scale * 100).toInt()}% text', (tester) async {
          final handle = tester.ensureSemantics();
          await _openAt(tester, 'bad-columns-mixed', size, textScale: scale);
          final read = _reading(tester);
          expect(read.take(2), [
            '$routeTitle | heading 3',
            '$bringTitle | heading 3',
          ]);
          expect(read, isNot(_meant));
          expect(read.toSet(), _meant.toSet(), reason: 'every part is read');
          final measured =
              mixed['${size.width.toInt()} ${(scale * 100).toInt()}'];
          expect(read, [...measured!, 'Route saves: 0', 'List saves: 0']);
          handle.dispose();
        });
      }
    }

    testWidgets('bad-columns-mixed: Tab still goes down one column and then '
        'the other: Back, Save route, Save list, and round', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-columns-mixed');
      expect(await _keyStops(tester, 4), [
        'Back',
        'Save route',
        'Save list',
        'Back',
      ]);
      handle.dispose();
    });

    for (final size in _sizes) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('bad-key-missing: the Bring title is read second, and '
            'the list after the route with no title, at '
            '${size.width.toInt()} by ${size.height.toInt()} and '
            '${(scale * 100).toInt()}% text', (tester) async {
          final handle = tester.ensureSemantics();
          await _openAt(tester, 'bad-key-missing', size, textScale: scale);
          expect(_reading(tester), [
            '$routeTitle | heading 3',
            '$bringTitle | heading 3',
            'Park at the gate.',
            'Climb the ridge.',
            'Walk back.',
            'Save route | button',
            'Water',
            'A map',
            'Save list | button',
            'Route saves: 0',
            'List saves: 0',
          ]);
          handle.dispose();
        });
      }
    }

    testWidgets('bad-key-missing: every part but the Bring title has its '
        'key', (tester) async {
      await _open(tester, 'bad-key-missing');
      final keyed = <String>[];
      for (final s in tester.widgetList<Semantics>(
        find.descendant(
          of: find.byType(BadKeyMissing),
          matching: find.byType(Semantics),
        ),
      )) {
        if (s.properties.sortKey == null) continue;
        keyed.addAll(
          tester
              .widgetList<Text>(
                find.descendant(
                  of: find.byWidget(s),
                  matching: find.byType(Text),
                ),
              )
              .map((t) => t.data!),
        );
      }
      expect(keyed, isNot(contains(bringTitle)));
      expect(keyed, hasLength(8));
    });

    testWidgets('bad-key-missing: Tab is not affected: Back, Save route, '
        'Save list, and round', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-key-missing');
      expect(await _keyStops(tester, 4), [
        'Back',
        'Save route',
        'Save list',
        'Back',
      ]);
      handle.dispose();
    });
  });

  group('good-columns without its focus groups', () {
    // What the FocusTraversalGroups of good-columns are measured to do, in
    // the widget tests only (the test font): the same two columns, each a
    // semantics container, without the groups. The Bring column is
    // shorter, so its button is higher, and Tab, by position, reached Save
    // list first at five of the six sizes; at 800 by 600 and 100% the two
    // buttons' rows overlap and Save route came first. Not measured on a
    // device: the probe's r15, with one part less in its right column,
    // went to the left button first everywhere.
    const first = {
      '412 100': 'Save list',
      '412 200': 'Save list',
      '320 100': 'Save list',
      '320 200': 'Save list',
      '800 100': 'Save route',
      '800 200': 'Save list',
    };
    for (final size in _sizes) {
      for (final scale in [1.0, 2.0]) {
        final key = '${size.width.toInt()} ${(scale * 100).toInt()}';
        testWidgets('at $key% Tab reaches ${first[key]} first', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearAllTestValues);
          final handle = tester.ensureSemantics();
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Plan(
                    slug: 'no-groups',
                    builder: (context, plan) => sideBySide(
                      Semantics(
                        container: true,
                        explicitChildNodes: true,
                        child: stack(routeColumn(context, plan)),
                      ),
                      Semantics(
                        container: true,
                        explicitChildNodes: true,
                        child: stack(bringColumn(context, plan)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final stops = await _keyStops(tester, 2);
          expect(stops.first, first[key]);
          expect(stops.toSet(), {'Save route', 'Save list'});
          handle.dispose();
        });
      }
    }
  });

  group('the SDK alone', () {
    // Two columns of texts in a Row, no container: the order is by position.
    Widget columns({double leftHeight = 20, double rightHeight = 20}) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            spacing: 8,
            children: [
              for (final t in ['A0', 'A1', 'A2'])
                SizedBox(height: leftHeight, child: Text(t)),
            ],
          ),
        ),
        Expanded(
          child: Column(
            spacing: 8,
            children: [
              for (final t in ['B0', 'B1'])
                SizedBox(height: rightHeight, child: Text(t)),
            ],
          ),
        ),
      ],
    );
    const ab = ['A0', 'A1', 'A2', 'B0', 'B1'];

    testWidgets('FL-420: two columns with level rows are read row by row, '
        'and the same columns with taller parts on the left down each column '
        'in part', (tester) async {
      final handle = tester.ensureSemantics();
      expect(await _siblingOrder(tester, columns(), labels: ab), [
        'A0',
        'B0',
        'A1',
        'B1',
        'A2',
      ]);
      // 40 high on the left, 24 on the right: B1 (32 to 56) overlaps A0
      // (0 to 40) and A1 (48 to 88), so the rows form one band, read down
      // each column.
      expect(
        await _siblingOrder(
          tester,
          columns(leftHeight: 40, rightHeight: 24),
          labels: ab,
        ),
        ['A0', 'A1', 'B0', 'B1', 'A2'],
      );
      handle.dispose();
    });

    testWidgets('a semantics container round each column keeps it together; '
        'without explicitChildNodes it joins the column\'s texts into one '
        'node', (tester) async {
      final handle = tester.ensureSemantics();
      Widget kept({required bool explicit}) => Row(
        children: [
          for (final col in ['A', 'B'])
            Expanded(
              child: Semantics(
                container: true,
                explicitChildNodes: explicit,
                child: Column(
                  spacing: 8,
                  children: [Text('${col}0'), Text('${col}1')],
                ),
              ),
            ),
        ],
      );
      expect(
        await _siblingOrder(
          tester,
          kept(explicit: true),
          labels: ['A0', 'A1', 'B0', 'B1'],
        ),
        ['A0', 'A1', 'B0', 'B1'],
      );
      expect(
        await _siblingOrder(
          tester,
          kept(explicit: false),
          labels: ['A0\nA1', 'B0\nB1'],
        ),
        ['A0\nA1', 'B0\nB1'],
      );
      handle.dispose();
    });

    // Three siblings in a row, left to right: Y keyed 2, P, and Z keyed 1.
    Widget row({required bool keyP}) => Row(
      spacing: 16,
      children: [
        Semantics(
          container: true,
          sortKey: const OrdinalSortKey(2),
          child: const Text('Y'),
        ),
        if (keyP)
          Semantics(
            container: true,
            sortKey: const OrdinalSortKey(3),
            child: const Text('P'),
          )
        else
          const Text('P'),
        Semantics(
          container: true,
          sortKey: const OrdinalSortKey(1),
          child: const Text('Z'),
        ),
      ],
    );

    testWidgets('FL-340: a node with no sort key keeps its place by position '
        'and splits the keyed nodes round it into runs sorted apart', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      const labels = ['Y', 'P', 'Z'];
      // Every node keyed: sorted by key.
      expect(await _siblingOrder(tester, row(keyP: true), labels: labels), [
        'Z',
        'Y',
        'P',
      ]);
      // P unkeyed between Y and Z: each keyed node is a run of its own, and
      // nothing is sorted. Written to fail when an unkeyed node no longer
      // splits the runs.
      expect(await _siblingOrder(tester, row(keyP: false), labels: labels), [
        'Y',
        'P',
        'Z',
      ]);
      handle.dispose();
    });

    testWidgets('FL-341: a sort key inside MergeSemantics (as in TestId) does '
        'not order the merged node; outside it, it does', (tester) async {
      final handle = tester.ensureSemantics();
      Widget pair({required bool inside}) {
        Widget part(String text, double order) {
          final keyed = Semantics(
            container: true,
            sortKey: OrdinalSortKey(order),
            child: Text(text),
          );
          return inside
              ? MergeSemantics(child: keyed)
              : Semantics(
                  container: true,
                  sortKey: OrdinalSortKey(order),
                  child: MergeSemantics(child: Text(text)),
                );
        }

        return Row(
          spacing: 16,
          children: [part('Second', 2), part('First', 1)],
        );
      }

      expect(
        await _siblingOrder(
          tester,
          pair(inside: false),
          labels: ['First', 'Second'],
        ),
        ['First', 'Second'],
      );
      expect(
        await _siblingOrder(
          tester,
          pair(inside: true),
          labels: ['First', 'Second'],
        ),
        ['Second', 'First'],
        reason: 'written to fail when the key inside the merge counts',
      );
      handle.dispose();
    });

    testWidgets('FL-420: a sort key changes the reading order and not Tab; '
        'FocusTraversalOrder changes Tab and not the reading order', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      Widget buttons({required bool readFirst, required bool tabFirst}) {
        Widget button(String text, {double? read, double? tab}) {
          Widget b = TextButton(onPressed: () {}, child: Text(text));
          if (tab != null) {
            b = FocusTraversalOrder(order: NumericFocusOrder(tab), child: b);
          }
          if (read != null) {
            b = Semantics(
              container: true,
              sortKey: OrdinalSortKey(read),
              child: b,
            );
          }
          return b;
        }

        return FocusTraversalGroup(
          policy: tabFirst
              ? OrderedTraversalPolicy()
              : ReadingOrderTraversalPolicy(),
          child: Row(
            spacing: 16,
            children: [
              button(
                'Left',
                read: readFirst ? 2 : null,
                tab: tabFirst ? 2 : null,
              ),
              button(
                'Right',
                read: readFirst ? 1 : null,
                tab: tabFirst ? 1 : null,
              ),
            ],
          ),
        );
      }

      Future<List<String>> tabs() async {
        final stops = <String>[];
        for (var i = 0; i < 2; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          stops.add(_stop(tester));
        }
        return stops;
      }

      const lr = ['Left', 'Right'];
      expect(
        await _siblingOrder(
          tester,
          buttons(readFirst: true, tabFirst: false),
          labels: lr,
        ),
        ['Right', 'Left'],
      );
      expect(await tabs(), ['Left', 'Right']);
      expect(
        await _siblingOrder(
          tester,
          buttons(readFirst: false, tabFirst: true),
          labels: lr,
        ),
        ['Left', 'Right'],
      );
      expect(await tabs(), ['Right', 'Left']);
      handle.dispose();
    });
  });
}
