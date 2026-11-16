import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/s15_hints/s15_hints.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/examples.dart';

/// L1 for S15 Hints (docs/specs/S15-hints.md).
final _open = exampleOpener(s15Hints);

int _count(WidgetTester tester, String slug) =>
    countOf(tester, 's15-$slug-count');

const _good = [
  'good-result',
  'good-row',
  'good-cupertino',
  'good-custom',
  'good-field',
];

/// The buttons: slug, identifier, name, hint.
const _buttons = [
  (
    'good-result',
    's15-good-result-favorite',
    'Favorite',
    'Adds this item to your favorites.',
  ),
  (
    'good-row',
    's15-good-row-song',
    'Night Ferry\nThe Lanterns',
    'Plays the song.',
  ),
  (
    'good-cupertino',
    's15-good-cupertino-share',
    'Share',
    'Shares the current page.',
  ),
  (
    'good-custom',
    's15-good-custom-archive',
    'Archive',
    'Moves this message out of the inbox.',
  ),
  (
    'bad-gesture',
    's15-bad-gesture-favorite',
    'Favorite',
    'Double tap to add this item to your favorites.',
  ),
  ('bad-repeats-label', 's15-bad-repeats-label-delete', 'Delete', 'Delete'),
  (
    'bad-control-type',
    's15-bad-control-type-share',
    'Share',
    'This button shares the current page.',
  ),
  ('bad-no-hint', 's15-bad-no-hint-song', 'Night Ferry\nThe Lanterns', ''),
];

const _rule = '3 to 12 letters or numbers.';

void main() {
  test('the technique has the examples named in the spec', () {
    expect(s15Hints.examples.map((e) => e.slug), [
      ..._good,
      'bad-gesture',
      'bad-repeats-label',
      'bad-control-type',
      'bad-no-hint',
      'bad-hint-detached',
      'bad-hint-only',
    ]);
    expect(_good, [
      for (final e in s15Hints.examples)
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

    testWidgets('good hints follow the wording rules of the source', (
      tester,
    ) async {
      for (final (slug, _, name, hint) in _buttons) {
        if (!slug.startsWith('good-')) continue;
        expect(hint, matches(RegExp(r'^[A-Z].*\.$')), reason: slug);
        expect(
          hint.toLowerCase(),
          isNot(matches(RegExp(r'\b(tap|swipe|click|press|button|link)\b'))),
          reason: slug,
        );
        // More than the name said again.
        expect(hint.toLowerCase(), isNot('${name.toLowerCase()}.'));
        expect(hint.split(' ').length, greaterThan(2), reason: slug);
        // Third person: the first word ends in "s" ("Adds", "Plays").
        expect(hint.split(' ').first, endsWith('s'), reason: slug);
      }
    });

    testWidgets('good-field: the rule is the hint and is also on the screen', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-field');
      const id = 's15-good-field-username';
      expect(dataById(id).label, 'Username');
      expect(dataById(id).hint, _rule);
      expect(dataById(id).flagsCollection.isTextField, isTrue);
      // The visible rule is an element of its own, not part of the field.
      expect(find.text(_rule), findsOneWidget);
      expect(
        semanticsNodes(tester).where((n) => n.label == _rule),
        hasLength(1),
      );
      await tester.enterText(find.byType(TextField), 'a');
      await tester.pump();
      expect(_count(tester, 'good-field'), 1);
      expect(dataById(id).hint, _rule);
      handle.dispose();
    });
  });

  group('buttons', () {
    for (final (slug, id, name, hint) in _buttons) {
      testWidgets('$slug: one button with its name, '
          '${hint.isEmpty ? 'and no hint' : 'and the hint "$hint"'}', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        final data = dataById(id);
        expect(data.label, name);
        expect(data.hint, hint);
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.hasAction(SemanticsAction.tap), isTrue);
        // The hint is on the button and nowhere else.
        expect(
          semanticsNodes(tester).where((n) => n.hint.isNotEmpty),
          hasLength(hint.isEmpty ? 0 : 1),
        );
        handle.dispose();
      });

      testWidgets('$slug: tap, the semantics action, Enter, and Space', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await tester.tap(byId(id));
        await tester.pumpAndSettle();
        expect(_count(tester, slug), 1);
        tester.semantics.tap(nodeById(id));
        await tester.pumpAndSettle();
        expect(_count(tester, slug), 2);
        await tabTo(tester, id);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(_count(tester, slug), 3);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(_count(tester, slug), 4);
        // Using the control does not change what it says.
        expect(dataById(id).label, name);
        expect(dataById(id).hint, hint);
        handle.dispose();
      });
    }
  });

  group('bad examples have their defect', () {
    testWidgets('bad-gesture: the hint names a gesture', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-gesture');
      expect(
        dataById('s15-bad-gesture-favorite').hint.toLowerCase(),
        contains('double tap'),
      );
      handle.dispose();
    });

    testWidgets('bad-repeats-label: the hint is the name', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-repeats-label');
      final data = dataById('s15-bad-repeats-label-delete');
      expect(data.hint, data.label);
      handle.dispose();
    });

    testWidgets('bad-control-type: the hint says "button"', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-control-type');
      expect(dataById('s15-bad-control-type-share').hint, contains('button'));
      handle.dispose();
    });

    testWidgets('bad-hint-detached: the hint is on a node with no name and no '
        'action, and the button has none', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-hint-detached');
      final nodes = semanticsNodes(tester);
      final button = nodes.singleWhere((n) => n.label == 'Favorite');
      expect(button.flagsCollection.isButton, isTrue);
      // Flutter 3.47.5: FilledButton is a semantics container, so the hint
      // around it does not join it (docs/flutter-limitations.md, FL-040).
      // If this fails, the hint has started to reach the button.
      expect(button.hint, isEmpty);
      final hinted = nodes.where((n) => n.hint.isNotEmpty).toList();
      expect(hinted, hasLength(1));
      expect(hinted.single.hint, 'Adds this item to your favorites.');
      expect(hinted.single.label, isEmpty);
      expect(hinted.single.hasAction(SemanticsAction.tap), isFalse);
      // The button still works.
      await tester.tap(byId('s15-bad-hint-detached-favorite'));
      await tester.pumpAndSettle();
      expect(_count(tester, 'bad-hint-detached'), 1);
      handle.dispose();
    });

    testWidgets('bad-hint-only: the rule is in the hint and not on the '
        'screen', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-hint-only');
      const id = 's15-bad-hint-only-username';
      expect(dataById(id).label, 'Username');
      expect(dataById(id).hint, _rule);
      expect(find.text(_rule), findsNothing);
      expect(
        semanticsNodes(tester).where((n) => n.label.contains("3 to 12")),
        isEmpty,
      );
      handle.dispose();
    });
  });
}
