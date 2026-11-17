import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/s14_values_and_state_descriptions/s14_values_and_state_descriptions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/examples.dart';

/// L1 for S14 Values and state descriptions
/// (docs/specs/S14-values-and-state-descriptions.md).
final _open = exampleOpener(s14ValuesAndStateDescriptions);

int _count(WidgetTester tester, String slug) =>
    countOf(tester, 's14-$slug-count');

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
      expect(dataById(id).label, 'Rating');
      expect(dataById(id).value, '3 out of 5');
      expect(dataById(id).increasedValue, '4 out of 5');
      expect(dataById(id).decreasedValue, '2 out of 5');
      expect(dataById(id).hasAction(SemanticsAction.increase), isTrue);
      expect(dataById(id).hasAction(SemanticsAction.decrease), isTrue);
      // The stars are not elements of their own.
      expect(_labels(tester).where((l) => l.contains('star')), isEmpty);
      handle.dispose();
    });

    testWidgets('good-rating: the value follows the semantics actions, the '
        'arrow keys, and a tap on a star', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-rating');
      const id = 's14-good-rating-rating';
      tester.semantics.increase(nodeById(id));
      await tester.pump();
      expect(dataById(id).value, '4 out of 5');
      expect(_count(tester, 'good-rating'), 1);
      tester.semantics.decrease(nodeById(id));
      tester.semantics.decrease(nodeById(id));
      await tester.pump();
      expect(dataById(id).value, '2 out of 5');
      expect(dataById(id).increasedValue, '3 out of 5');
      expect(dataById(id).decreasedValue, '1 out of 5');

      await tabTo(tester, id);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(dataById(id).value, '3 out of 5');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(dataById(id).value, '4 out of 5');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(dataById(id).value, '2 out of 5');

      // The fifth star.
      final stars = tester.getRect(find.byIcon(Icons.star_border).last);
      await tester.tapAt(stars.center);
      await tester.pump();
      expect(dataById(id).value, '5 out of 5');
      // At the top the value stays, and the next value is the same one.
      expect(dataById(id).increasedValue, '5 out of 5');
      final before = _count(tester, 'good-rating');
      tester.semantics.increase(nodeById(id));
      await tester.pump();
      expect(dataById(id).value, '5 out of 5');
      expect(_count(tester, 'good-rating'), before);
      handle.dispose();
    });

    testWidgets('good-step: one element with the step as its value', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-step');
      const id = 's14-good-step-progress';
      expect(dataById(id).label, 'Progress');
      expect(dataById(id).value, 'Step 2 of 4');
      // The numbers in the circles are not read one by one.
      expect(
        _labels(tester).where((l) => RegExp(r'^[1-4]$').hasMatch(l)),
        isEmpty,
      );
      for (final step in [3, 4, 1]) {
        await tester.tap(byId('s14-good-step-next'));
        await tester.pump();
        expect(dataById(id).value, 'Step $step of 4');
      }
      handle.dispose();
    });

    testWidgets('good-button-value: a button whose value follows its mode', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-button-value');
      const id = 's14-good-button-value-repeat';
      expect(dataById(id).label, 'Repeat');
      expect(dataById(id).flagsCollection.isButton, isTrue);
      expect(dataById(id).flagsCollection.isToggled, Tristate.none);
      expect(dataById(id).hasAction(SemanticsAction.tap), isTrue);
      expect(dataById(id).value, 'Off');
      await tester.tap(byId(id));
      await tester.pump();
      expect(dataById(id).value, 'All');
      tester.semantics.tap(nodeById(id));
      await tester.pump();
      expect(dataById(id).value, 'One');
      await tabTo(tester, id);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(dataById(id).value, 'Off');
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(dataById(id).value, 'All');
      // The name never changes.
      expect(dataById(id).label, 'Repeat');
      handle.dispose();
    });

    testWidgets('good-slider-format: the value is in minutes, not percent', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-slider-format');
      const id = 's14-good-slider-format-timer';
      expect(dataById(id).label, 'Timer');
      expect(dataById(id).flagsCollection.isSlider, isTrue);
      expect(dataById(id).value, '15 minutes');
      expect(dataById(id).increasedValue, '20 minutes');
      expect(dataById(id).decreasedValue, '10 minutes');
      tester.semantics.increase(nodeById(id));
      await tester.pump();
      expect(dataById(id).value, '20 minutes');
      await tabTo(tester, id);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(dataById(id).value, '15 minutes');
      expect(dataById(id).value, isNot(contains('%')));
      handle.dispose();
    });
  });

  group('bad examples have their defect', () {
    testWidgets('bad-rating-no-value: adjustable, and no value before or '
        'after a change', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-rating-no-value');
      const id = 's14-bad-rating-no-value-rating';
      expect(dataById(id).label, 'Rating');
      expect(dataById(id).hasAction(SemanticsAction.increase), isTrue);
      expect(dataById(id).value, isEmpty);
      expect(dataById(id).increasedValue, isEmpty);
      tester.semantics.increase(nodeById(id));
      await tester.pump();
      // It did change; nothing in the semantics says to what.
      expect(_count(tester, 'bad-rating-no-value'), 1);
      expect(find.byIcon(Icons.star), findsNWidgets(4));
      expect(dataById(id).value, isEmpty);
      expect(dataById(id).label, 'Rating');
      handle.dispose();
    });

    testWidgets('bad-stale-value: the value stays "3 out of 5" while the '
        'rating changes', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-stale-value');
      const id = 's14-bad-stale-value-rating';
      expect(dataById(id).value, '3 out of 5');
      tester.semantics.increase(nodeById(id));
      await tester.pump();
      tester.semantics.increase(nodeById(id));
      await tester.pump();
      expect(_count(tester, 'bad-stale-value'), 2);
      expect(find.byIcon(Icons.star), findsNWidgets(5));
      expect(dataById(id).value, '3 out of 5');
      expect(dataById(id).increasedValue, '4 out of 5');
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
        await tester.tap(byId('s14-bad-step-no-value-next'));
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
        expect(dataById(id).label, 'Repeat');
        expect(dataById(id).flagsCollection.isButton, isTrue);
        expect(dataById(id).value, isEmpty);
        expect(dataById(id).flagsCollection.isToggled, Tristate.none);
        expect(dataById(id).flagsCollection.isSelected, Tristate.none);
        await tester.tap(byId(id));
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
      expect(dataById(id).label, 'Home alarm');
      expect(dataById(id).flagsCollection.isToggled, Tristate.isFalse);
      expect(dataById(id).value, 'Deactivated');
      await tester.tap(byId(id));
      await tester.pump();
      expect(dataById(id).flagsCollection.isToggled, Tristate.isTrue);
      expect(dataById(id).value, 'Activated');
      handle.dispose();
    });
  });
}
