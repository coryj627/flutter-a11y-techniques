import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/app/app.dart';
import 'package:flutter_a11y_techniques/catalog/registry.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/s14_values_and_state_descriptions/s14_values_and_state_descriptions.dart';
import 'package:flutter_test/flutter_test.dart';

/// L1 for S14 Values and state descriptions
/// (docs/specs/S14-values-and-state-descriptions.md).
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
      registry: TechniqueRegistry([s14ValuesAndStateDescriptions]),
      platform: AppPlatform.android,
      initialRoute: '/t/S14/$slug',
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
    find.descendant(of: _id('s14-$slug-count'), matching: find.byType(Text)),
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

/// The labels of every node on the screen, in traversal order.
List<String> _labels(WidgetTester tester) {
  final found = <String>[];
  void visit(SemanticsNode node) {
    if (!node.isMergedIntoParent && node.label.isNotEmpty) {
      found.add(node.label);
    }
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

const _good = [
  'good-rating',
  'good-step',
  'good-button-value',
  'good-slider-format',
];

void main() {
  test('the technique has the examples named in the spec', () {
    expect(s14ValuesAndStateDescriptions.examples.map((e) => e.slug), [
      ..._good,
      'bad-rating-no-value',
      'bad-stale-value',
      'bad-step-no-value',
      'bad-button-no-value',
      'bad-value-on-switch',
    ]);
    expect(_good, [
      for (final e in s14ValuesAndStateDescriptions.examples)
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
    }

    testWidgets('good-rating: name, value, and the values on each side', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-rating');
      const id = 's14-good-rating-rating';
      expect(_data(id).label, 'Rating');
      expect(_data(id).value, '3 out of 5');
      expect(_data(id).increasedValue, '4 out of 5');
      expect(_data(id).decreasedValue, '2 out of 5');
      expect(_data(id).hasAction(SemanticsAction.increase), isTrue);
      expect(_data(id).hasAction(SemanticsAction.decrease), isTrue);
      // The stars are not elements of their own.
      expect(_labels(tester).where((l) => l.contains('star')), isEmpty);
      handle.dispose();
    });

    testWidgets('good-rating: the value follows the semantics actions, the '
        'arrow keys, and a tap on a star', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-rating');
      const id = 's14-good-rating-rating';
      tester.semantics.increase(_node(id));
      await tester.pump();
      expect(_data(id).value, '4 out of 5');
      expect(_count(tester, 'good-rating'), 1);
      tester.semantics.decrease(_node(id));
      tester.semantics.decrease(_node(id));
      await tester.pump();
      expect(_data(id).value, '2 out of 5');
      expect(_data(id).increasedValue, '3 out of 5');
      expect(_data(id).decreasedValue, '1 out of 5');

      await _tabTo(tester, id);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(_data(id).value, '3 out of 5');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(_data(id).value, '4 out of 5');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_data(id).value, '2 out of 5');

      // The fifth star.
      final stars = tester.getRect(find.byIcon(Icons.star_border).last);
      await tester.tapAt(stars.center);
      await tester.pump();
      expect(_data(id).value, '5 out of 5');
      // At the top the value stays, and the next value is the same one.
      expect(_data(id).increasedValue, '5 out of 5');
      final before = _count(tester, 'good-rating');
      tester.semantics.increase(_node(id));
      await tester.pump();
      expect(_data(id).value, '5 out of 5');
      expect(_count(tester, 'good-rating'), before);
      handle.dispose();
    });

    testWidgets('good-step: one element with the step as its value', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-step');
      const id = 's14-good-step-progress';
      expect(_data(id).label, 'Progress');
      expect(_data(id).value, 'Step 2 of 4');
      // The numbers in the circles are not read one by one.
      expect(
        _labels(tester).where((l) => RegExp(r'^[1-4]$').hasMatch(l)),
        isEmpty,
      );
      for (final step in [3, 4, 1]) {
        await tester.tap(_id('s14-good-step-next'));
        await tester.pump();
        expect(_data(id).value, 'Step $step of 4');
      }
      handle.dispose();
    });

    testWidgets('good-button-value: a button whose value follows its mode', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-button-value');
      const id = 's14-good-button-value-repeat';
      expect(_data(id).label, 'Repeat');
      expect(_data(id).flagsCollection.isButton, isTrue);
      expect(_data(id).flagsCollection.isToggled, Tristate.none);
      expect(_data(id).hasAction(SemanticsAction.tap), isTrue);
      expect(_data(id).value, 'Off');
      await tester.tap(_id(id));
      await tester.pump();
      expect(_data(id).value, 'All');
      tester.semantics.tap(_node(id));
      await tester.pump();
      expect(_data(id).value, 'One');
      await _tabTo(tester, id);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(_data(id).value, 'Off');
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(_data(id).value, 'All');
      // The name never changes.
      expect(_data(id).label, 'Repeat');
      handle.dispose();
    });

    testWidgets('good-slider-format: the value is in minutes, not percent', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-slider-format');
      const id = 's14-good-slider-format-timer';
      expect(_data(id).label, 'Timer');
      expect(_data(id).flagsCollection.isSlider, isTrue);
      expect(_data(id).value, '15 minutes');
      expect(_data(id).increasedValue, '20 minutes');
      expect(_data(id).decreasedValue, '10 minutes');
      tester.semantics.increase(_node(id));
      await tester.pump();
      expect(_data(id).value, '20 minutes');
      await _tabTo(tester, id);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(_data(id).value, '15 minutes');
      expect(_data(id).value, isNot(contains('%')));
      handle.dispose();
    });
  });

  group('bad examples have their defect', () {
    testWidgets('bad-rating-no-value: adjustable, and no value before or '
        'after a change', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-rating-no-value');
      const id = 's14-bad-rating-no-value-rating';
      expect(_data(id).label, 'Rating');
      expect(_data(id).hasAction(SemanticsAction.increase), isTrue);
      expect(_data(id).value, isEmpty);
      expect(_data(id).increasedValue, isEmpty);
      tester.semantics.increase(_node(id));
      await tester.pump();
      // It did change; nothing in the semantics says to what.
      expect(_count(tester, 'bad-rating-no-value'), 1);
      expect(find.byIcon(Icons.star), findsNWidgets(4));
      expect(_data(id).value, isEmpty);
      expect(_data(id).label, 'Rating');
      handle.dispose();
    });

    testWidgets('bad-stale-value: the value stays "3 out of 5" while the '
        'rating changes', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-stale-value');
      const id = 's14-bad-stale-value-rating';
      expect(_data(id).value, '3 out of 5');
      tester.semantics.increase(_node(id));
      await tester.pump();
      tester.semantics.increase(_node(id));
      await tester.pump();
      expect(_count(tester, 'bad-stale-value'), 2);
      expect(find.byIcon(Icons.star), findsNWidgets(5));
      expect(_data(id).value, '3 out of 5');
      expect(_data(id).increasedValue, '4 out of 5');
      handle.dispose();
    });

    testWidgets('bad-step-no-value: four numbers, and nothing that says '
        'which is current', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-step-no-value');
      Iterable<SemanticsNode> numbers() => find.semantics
          .byPredicate((n) => RegExp(r'^[1-4]$').hasMatch(n.label))
          .evaluate();
      for (var press = 0; press < 2; press++) {
        expect(numbers().map((n) => n.label), ['1', '2', '3', '4']);
        for (final node in numbers()) {
          final data = node.getSemanticsData();
          expect(data.value, isEmpty);
          expect(data.flagsCollection.isSelected, Tristate.none);
        }
        expect(_labels(tester), isNot(contains('Progress')));
        await tester.tap(_id('s14-bad-step-no-value-next'));
        await tester.pump();
      }
      expect(_count(tester, 'bad-step-no-value'), 2);
      handle.dispose();
    });

    testWidgets('bad-button-no-value: the same semantics in every mode', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-button-no-value');
      const id = 's14-bad-button-no-value-repeat';
      for (var press = 0; press < 3; press++) {
        expect(_data(id).label, 'Repeat');
        expect(_data(id).flagsCollection.isButton, isTrue);
        expect(_data(id).value, isEmpty);
        expect(_data(id).flagsCollection.isToggled, Tristate.none);
        expect(_data(id).flagsCollection.isSelected, Tristate.none);
        await tester.tap(_id(id));
        await tester.pump();
      }
      expect(_count(tester, 'bad-button-no-value'), 3);
      handle.dispose();
    });

    testWidgets('bad-value-on-switch: a switch state and a value that say '
        'the same thing twice', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-value-on-switch');
      const id = 's14-bad-value-on-switch-alarm';
      expect(_data(id).label, 'Home alarm');
      expect(_data(id).flagsCollection.isToggled, Tristate.isFalse);
      expect(_data(id).value, 'Deactivated');
      await tester.tap(_id(id));
      await tester.pump();
      expect(_data(id).flagsCollection.isToggled, Tristate.isTrue);
      expect(_data(id).value, 'Activated');
      handle.dispose();
    });
  });
}
