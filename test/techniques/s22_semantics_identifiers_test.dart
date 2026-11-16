import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/app/app.dart';
import 'package:flutter_a11y_techniques/catalog/registry.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/s22_semantics_identifiers/s22_semantics_identifiers.dart';
import 'package:flutter_test/flutter_test.dart';

/// L1 for S22 Semantics identifiers for testing
/// (docs/specs/S22-semantics-identifiers.md).
Future<void> _open(
  WidgetTester tester,
  String slug, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) async {
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  await tester.pumpWidget(
    A11yTechniquesApp(
      registry: TechniqueRegistry([s22SemanticsIdentifiers]),
      platform: AppPlatform.android,
      initialRoute: '/t/S22/$slug',
    ),
  );
  await tester.pumpAndSettle();
}

Finder _id(String id) => find.byKey(ValueKey<String>(id));

/// The semantics node that stands for the element with [id]: the one whose
/// merged data has the identifier, and that is not merged into a parent.
FinderBase<SemanticsNode> _node(String id) => find.semantics.byPredicate(
  (node) =>
      !node.isMergedIntoParent && node.getSemanticsData().identifier == id,
);

/// What the node with [id] exposes now. Read again after every change.
SemanticsData _data(String id) =>
    _node(id).evaluate().single.getSemanticsData();

int _count(WidgetTester tester, String slug) {
  final text = tester.widget<Text>(
    find.descendant(of: _id('s22-$slug-count'), matching: find.byType(Text)),
  );
  return int.parse(text.data!.split(': ').last);
}

/// Tabs until [id] has focus. The Back button comes first.
Future<void> _tabTo(WidgetTester tester, String id) async {
  var reached = false;
  for (var i = 0; i < 8 && !reached; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    reached = _data(id).flagsCollection.isFocused == Tristate.isTrue;
  }
  expect(reached, isTrue, reason: 'Tab did not reach $id');
}

/// Every node on the screen that is not merged into a parent, in traversal
/// order.
List<SemanticsData> _nodes(WidgetTester tester) {
  final found = <SemanticsData>[];
  void visit(SemanticsNode node) {
    if (!node.isMergedIntoParent) found.add(node.getSemanticsData());
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return found;
}

const _good = ['good-merged', 'good-cupertino', 'good-custom', 'good-field'];

/// The buttons found by their identifier: slug, identifier, name.
const _buttons = [
  ('good-merged', 's22-good-merged-save', 'Save draft'),
  ('good-cupertino', 's22-good-cupertino-save', 'Save draft'),
  ('good-custom', 's22-good-custom-save', 'Save draft'),
  ('bad-id-as-name', 's22-bad-id-as-name-close', ''),
];

/// Nodes on the screen whose identifier is [id].
Iterable<SemanticsData> _withId(WidgetTester tester, String id) =>
    _nodes(tester).where((n) => n.identifier == id);

void main() {
  test('the technique has the examples named in the spec', () {
    expect(s22SemanticsIdentifiers.examples.map((e) => e.slug), [
      ..._good,
      'bad-inside',
      'bad-wrapper',
      'bad-id-as-name',
      'bad-duplicate',
    ]);
    expect(_good, [
      for (final e in s22SemanticsIdentifiers.examples)
        if (e.kind == ExampleKind.good) e.slug,
    ]);
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

      testWidgets('$slug does not overflow at 200% text on a phone', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await _open(tester, slug, textScale: 2);
        expect(tester.takeException(), isNull);
      });

      testWidgets('$slug: every identifier on the screen is on one node, and '
          'is in no label, value, hint, or tooltip', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        final nodes = _nodes(tester);
        final ids = [
          for (final n in nodes)
            if (n.identifier.isNotEmpty) n.identifier,
        ];
        expect(ids.toSet(), hasLength(ids.length), reason: 'unique');
        expect(ids, contains('s22-$slug-count'));
        for (final n in nodes) {
          final spoken = '${n.label} ${n.value} ${n.hint} ${n.tooltip}';
          expect(spoken, isNot(contains('s22-')), reason: slug);
        }
        handle.dispose();
      });
    }

    testWidgets('good-field: the field has its name and the identifier', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-field');
      const id = 's22-good-field-project';
      expect(_data(id).label, 'Project name');
      expect(_data(id).flagsCollection.isTextField, isTrue);
      await tester.enterText(find.byType(TextField), 'a');
      await tester.pump();
      expect(_count(tester, 'good-field'), 1);
      expect(_data(id).value, 'a');
      expect(_data(id).label, 'Project name');
      handle.dispose();
    });
  });

  group('buttons found by identifier', () {
    for (final (slug, id, name) in _buttons) {
      testWidgets('$slug: the node with the identifier is the button, '
          '${name.isEmpty ? 'with no name' : 'named "$name"'}', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        final data = _data(id);
        expect(data.label, name);
        expect(data.tooltip, isEmpty);
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.hasAction(SemanticsAction.tap), isTrue);
        // One button on the screen besides Back, and it is this node.
        expect(
          _nodes(tester).where((n) => n.flagsCollection.isButton),
          hasLength(2),
        );
        handle.dispose();
      });

      testWidgets('$slug: tap, the semantics action, Enter, and Space', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await tester.tap(_id(id));
        await tester.pumpAndSettle();
        expect(_count(tester, slug), 1);
        tester.semantics.tap(_node(id));
        await tester.pumpAndSettle();
        expect(_count(tester, slug), 2);
        await _tabTo(tester, id);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(_count(tester, slug), 3);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(_count(tester, slug), 4);
        expect(_data(id).label, name);
        handle.dispose();
      });
    }
  });

  group('bad examples have their defect', () {
    testWidgets('bad-inside: the identifier is on a text node inside the '
        'button, and the button node has no name of its own', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-inside');
      final withId = _withId(tester, 's22-bad-inside-save').toList();
      expect(withId, hasLength(1));
      // Flutter 3.47.5: the identifier makes the text a node of its own,
      // which takes the label out of the button (FL-007). If this fails,
      // the identifier has stopped splitting the button.
      expect(withId.single.label, 'Save draft');
      expect(withId.single.flagsCollection.isButton, isFalse);
      expect(withId.single.hasAction(SemanticsAction.tap), isFalse);
      final button = _nodes(
        tester,
      ).singleWhere((n) => n.flagsCollection.isButton && n.tooltip != 'Back');
      expect(button.label, isEmpty);
      expect(button.identifier, isEmpty);
      expect(button.hasAction(SemanticsAction.tap), isTrue);
      await tester.tap(_id('s22-bad-inside-button'));
      await tester.pumpAndSettle();
      expect(_count(tester, 'bad-inside'), 1);
      handle.dispose();
    });

    testWidgets('bad-wrapper: the identifier is on a node with no role, no '
        'name, and no action, and the button has no identifier', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-wrapper');
      final withId = _withId(tester, 's22-bad-wrapper-save').toList();
      expect(withId, hasLength(1));
      // Flutter 3.47.5: FilledButton is a semantics container, so the
      // identifier around it does not join it. If this fails, the plain
      // wrapper has started to work.
      expect(withId.single.label, isEmpty);
      expect(withId.single.flagsCollection.isButton, isFalse);
      expect(withId.single.hasAction(SemanticsAction.tap), isFalse);
      final button = _nodes(tester).singleWhere((n) => n.label == 'Save draft');
      expect(button.flagsCollection.isButton, isTrue);
      expect(button.identifier, isEmpty);
      await tester.tap(_id('s22-bad-wrapper-button'));
      await tester.pumpAndSettle();
      expect(_count(tester, 'bad-wrapper'), 1);
      handle.dispose();
    });

    testWidgets('bad-id-as-name: the button has an identifier and fails the '
        'labelled tap target guideline', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-id-as-name');
      final data = _data('s22-bad-id-as-name-close');
      expect(data.label, isEmpty);
      expect(data.tooltip, isEmpty);
      expect(data.value, isEmpty);
      await expectLater(
        tester,
        doesNotMeetGuideline(labeledTapTargetGuideline),
      );
      handle.dispose();
    });

    testWidgets('bad-duplicate: two buttons carry the same identifier', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-duplicate');
      final withId = _withId(tester, 's22-bad-duplicate-action').toList();
      expect(withId.map((n) => n.label), ['Save draft', 'Discard draft']);
      expect(withId.every((n) => n.flagsCollection.isButton), isTrue);
      await tester.tap(_id('s22-bad-duplicate-save'));
      await tester.pumpAndSettle();
      await tester.tap(_id('s22-bad-duplicate-discard'));
      await tester.pumpAndSettle();
      expect(_count(tester, 'bad-duplicate'), 2);
      handle.dispose();
    });
  });
}
