import 'dart:math' as math;
import 'dart:ui' show Tristate;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/app/screens.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/s09_content_grouping/examples.dart';
import 'package:flutter_a11y_techniques/techniques/s09_content_grouping/s09_content_grouping.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/examples.dart';

/// L1 for S09 Content grouping (docs/specs/S09-content-grouping.md, section
/// 6). These tests run as Android: `kIsWeb` is false, so what the web
/// engine makes of a node (a labelled node with children is a `group`
/// there) is tested in web_tests/s09_content_grouping.spec.js, and what
/// TalkBack and VoiceOver say of a group is in the transcripts.
final _open = exampleOpener(s09ContentGrouping);

const _good = [
  'good-merged-facts',
  'good-cupertino',
  'good-named-group',
  'good-tap-target',
];

/// The keyboard-operable controls of each good example, by test
/// identifier, with the status line it changes and what that line then
/// says.
const _controls = {
  'good-merged-facts': <String, (String, String)>{},
  'good-cupertino': <String, (String, String)>{},
  'good-named-group': {
    's09-good-named-group-on': ('s09-good-named-group-status', 'Light: on'),
    's09-good-named-group-off': ('s09-good-named-group-status', 'Light: off'),
  },
  'good-tap-target': {
    's09-good-tap-target-info': ('s09-good-tap-target-opens', 'Opens: 1'),
  },
};

/// What a merged label and value is named: the two texts on two lines.
String _fact(int i) => '${facts[i].$1}\n${facts[i].$2}';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// The text of the status line with the identifier [id].
String _status(WidgetTester tester, String id) => tester
    .widget<Text>(
      find.descendant(
        of: find.byKey(ValueKey<String>(id)),
        matching: find.byType(Text),
      ),
    )
    .data!;

/// Every node of the screen in traversal order, each with its depth below
/// the "Example" heading's parent, from the first node after that heading
/// up to the example's status line (or the end): what a screen reader moves
/// through in the example. A node merged into its parent is left out, and so
/// is a node with no name and no tap action, such as a plain container.
List<(int, SemanticsData)> _exampleNodes(WidgetTester tester) {
  final all = <(int, SemanticsData)>[];
  void visit(SemanticsNode node, int depth) {
    if (!node.isMergedIntoParent) all.add((depth, node.getSemanticsData()));
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
  final start = all.indexWhere((n) => n.$2.label == 'Example');
  expect(start, isNonNegative, reason: 'the Example heading');
  final end = all.indexWhere(
    (n) => RegExp(r'^s09-.*-(status|opens)$').hasMatch(n.$2.identifier),
  );
  final base = all[start].$1;
  return [
    for (final n in all.sublist(start + 1, end < 0 ? all.length : end))
      if (n.$2.label.isNotEmpty || n.$2.hasAction(SemanticsAction.tap))
        (n.$1 - base, n.$2),
  ];
}

String _describe((int, SemanticsData) entry) {
  final (depth, n) = entry;
  return [
    '${'  ' * depth}${n.label}',
    if (n.flagsCollection.isButton) 'button',
    if (n.flagsCollection.isHeader) 'header',
    if (n.hasAction(SemanticsAction.tap)) 'tap',
  ].join(' | ');
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

/// The labels of the nodes with keyboard focus.
List<String> _focused(WidgetTester tester) => [
  for (final n in semanticsNodes(tester))
    if (n.flagsCollection.isFocused == Tristate.isTrue)
      n.tooltip.isNotEmpty ? n.tooltip : n.label,
];

void main() {
  test('the technique has the examples named in the spec', () {
    expect(s09ContentGrouping.examples.map((e) => e.slug), [
      ..._good,
      'bad-split-facts',
      'bad-merged-group',
    ]);
    expect(_good, [
      for (final e in s09ContentGrouping.examples)
        if (e.kind == ExampleKind.good) e.slug,
    ]);
    expect(
      s09ContentGrouping.examples.where((e) => e.isCustomSolution),
      isEmpty,
      reason: 'no good example is flagged as a custom solution',
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

        for (final id in _controls[slug]!.keys) {
          testWidgets('$slug: with keyboard focus on $id the text still '
              'meets the contrast guideline, and the button draws a 2 pixel '
              'outline 3:1 or more on the page (${brightness.name})', (
            tester,
          ) async {
            final handle = tester.ensureSemantics();
            await _open(tester, slug, brightness: brightness);
            await tabTo(tester, id);
            await tester.pumpAndSettle();
            expect(dataById(id).flagsCollection.isFocused, Tristate.isTrue);
            await expectLater(tester, meetsGuideline(textContrastGuideline));
            final button = tester.widget<ButtonStyleButton>(
              find.descendant(
                of: byId(id),
                matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
              ),
            );
            final colors = Theme.of(tester.element(byId(id))).colorScheme;
            final side = button.style!.side!.resolve({WidgetState.focused})!;
            expect(side.width, 2);
            expect(side.color, colors.onSurface);
            expect(
              _contrast(side.color, colors.surface),
              greaterThanOrEqualTo(3),
            );
            expect(
              button.style!.side!.resolve({}),
              isNull,
              reason: 'unfocused',
            );
            handle.dispose();
          });
        }
      }

      for (final MapEntry(key: id, value: (statusId, after))
          in _controls[slug]!.entries) {
        for (final (how, act) in [
          ('a tap', (WidgetTester t) => t.tap(byId(id))),
          (
            'the tap action',
            (WidgetTester t) async => t.semantics.tap(nodeById(id)),
          ),
        ]) {
          testWidgets('$slug: $how on $id does its own action', (tester) async {
            final handle = tester.ensureSemantics();
            await _open(tester, slug);
            expect(_status(tester, statusId), isNot(after));
            await act(tester);
            await tester.pumpAndSettle();
            expect(_status(tester, statusId), after);
            handle.dispose();
          });
        }

        for (final (key, name) in [
          (LogicalKeyboardKey.enter, 'Enter'),
          (LogicalKeyboardKey.space, 'Space'),
        ]) {
          testWidgets('$slug: Tab reaches $id and $name does its own '
              'action', (tester) async {
            final handle = tester.ensureSemantics();
            await _open(tester, slug);
            await tabTo(tester, id);
            await tester.sendKeyEvent(key);
            await tester.pumpAndSettle();
            expect(_status(tester, statusId), after);
            handle.dispose();
          });
        }
      }
    }

    testWidgets('good-merged-facts: each label and its value are one node, '
        'in the order shown', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-merged-facts');
      expect(_exampleNodes(tester).map(_describe), [_fact(0), _fact(1)]);
      handle.dispose();
    });

    testWidgets('good-cupertino: each row is one node, its title and its '
        'value', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-cupertino');
      expect(_exampleNodes(tester).map((e) => e.$2.label), [
        _fact(0),
        _fact(1),
      ]);
      handle.dispose();
    });

    testWidgets('good-named-group: a node named by the question holds the '
        'two buttons, and the question is read once', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-named-group');
      expect(_exampleNodes(tester).map(_describe), [
        groupName,
        '  On | button | tap',
        '  Off | button | tap',
      ]);
      handle.dispose();
    });

    testWidgets('good-named-group: Tab goes Back, On, Off', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-named-group');
      final stops = <String>[];
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        stops.addAll(_focused(tester));
      }
      expect(stops, ['Back', 'On', 'Off']);
      handle.dispose();
    });

    testWidgets('good-tap-target: one button named by its text; the icon has '
        'no node of its own, and a tap on the icon acts', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-tap-target');
      expect(_exampleNodes(tester).map(_describe), [
        '$targetName | button | tap',
      ]);
      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();
      expect(_status(tester, 's09-good-tap-target-opens'), 'Opens: 1');
      handle.dispose();
    });
  });

  // Every example, good and bad: at 200% text on a 320 by 640 screen no
  // layout overflows, and no text in the example is cut short, by a line
  // limit or by a box too small for its lines.
  for (final example in s09ContentGrouping.examples) {
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

  testWidgets('the SDK on its own: a CupertinoListTile keeps its title and '
      'its subtitle as two nodes, which is why good-cupertino merges each '
      'one', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: SafeArea(
            child: CupertinoListSection.insetGrouped(
              children: [
                CupertinoListTile(
                  title: Text(facts[0].$1),
                  subtitle: Text(facts[0].$2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final labels = [
      for (final n in semanticsNodes(tester))
        if (n.label.isNotEmpty) n.label,
    ];
    // Written to fail if the tile starts merging them, so that the
    // example's comment and the spec are looked at again.
    expect(labels, [facts[0].$1, facts[0].$2]);
    handle.dispose();
  });

  group('bad examples have their defect', () {
    testWidgets('bad-split-facts: four nodes, both labels before both '
        'values', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-split-facts');
      expect(_exampleNodes(tester).map((e) => e.$2.label), [
        facts[0].$1,
        facts[1].$1,
        facts[0].$2,
        facts[1].$2,
      ]);
      handle.dispose();
    });

    testWidgets('bad-merged-group: one button named by the question and both '
        'buttons, whose tap action is On\'s', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-merged-group');
      expect(_exampleNodes(tester).map(_describe), [
        '$groupName\nOn\nOff | button | tap',
      ]);
      // The merged node's one tap action runs On, never Off.
      tester.semantics.tap(nodeById('s09-bad-merged-group-light'));
      await tester.pumpAndSettle();
      expect(_status(tester, 's09-bad-merged-group-status'), 'Light: on');
      // Positive control, through the same status line in the same launch:
      // a tap on Off's own words turns it off.
      await tester.tap(find.text('Off'));
      await tester.pumpAndSettle();
      expect(_status(tester, 's09-bad-merged-group-status'), 'Light: off');
      // And the merged node's action again: On, so it is not Off's.
      tester.semantics.tap(nodeById('s09-bad-merged-group-light'));
      await tester.pumpAndSettle();
      expect(_status(tester, 's09-bad-merged-group-status'), 'Light: on');
      handle.dispose();
    });

    testWidgets('bad-merged-group: the keyboard still reaches both buttons '
        '(the two focus nodes are under the one merged node)', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-merged-group');
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(_status(tester, 's09-bad-merged-group-status'), 'Light: off');
      handle.dispose();
    });
  });
}
