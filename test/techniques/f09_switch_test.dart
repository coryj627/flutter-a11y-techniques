import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/f09_switch/f09_switch.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/examples.dart';

/// L1 for F09 Switch (docs/specs/F09-switch.md).
final _open = exampleOpener(f09Switch);

int _count(WidgetTester tester, String slug) =>
    countOf(tester, 'f09-$slug-count');

const _good = ['good-tile', 'good-cupertino', 'good-custom', 'good-group'];

const _bluetooth = 'Bluetooth';

/// Switches that start off and keep their name: slug, identifier, name.
const _switches = [
  ('good-tile', 'f09-good-tile-bluetooth', _bluetooth),
  ('good-cupertino', 'f09-good-cupertino-bluetooth', _bluetooth),
  ('good-custom', 'f09-good-custom-bluetooth', _bluetooth),
  ('good-group', 'f09-good-group-messages', 'Messages'),
  ('good-group', 'f09-good-group-reminders', 'Reminders'),
];

Tristate _state(String id) => dataById(id).flagsCollection.isToggled;

/// Expects [data] to be a switch: toggled, not a checkbox, a radio button,
/// or a button, enabled, with a tap action.
void _expectSwitch(SemanticsData data, Tristate state) {
  expect(data.flagsCollection.isToggled, state);
  expect(data.flagsCollection.isChecked, CheckedState.none);
  expect(data.flagsCollection.isInMutuallyExclusiveGroup, isFalse);
  expect(data.flagsCollection.isButton, isFalse);
  expect(data.flagsCollection.isEnabled, Tristate.isTrue);
  expect(data.hasAction(SemanticsAction.tap), isTrue);
}

void main() {
  test('the technique has the examples named in the spec', () {
    expect(f09Switch.examples.map((e) => e.slug), [
      ..._good,
      'bad-unlabelled',
      'bad-tile-not-merged',
      'bad-label-changes',
      'bad-no-state',
    ]);
    expect(_good, [
      for (final e in f09Switch.examples)
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
  });

  group('switches', () {
    for (final (slug, id, name) in _switches) {
      testWidgets('$id: one node with the name "$name", the switch role, '
          'off, and a tap action', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        final data = dataById(id);
        expect(data.label, name);
        expect(data.value, isEmpty);
        _expectSwitch(data, Tristate.isFalse);
        // The name is on the switch and on no other node.
        expect(
          semanticsNodes(tester).where((n) => n.label == name),
          hasLength(1),
        );
        handle.dispose();
      });

      testWidgets('$id: tap, the semantics action, and Space each change '
          'the state, and the name stays', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await tester.tap(byId(id));
        await tester.pumpAndSettle();
        expect(_state(id), Tristate.isTrue);
        expect(dataById(id).label, name);
        tester.semantics.tap(nodeById(id));
        await tester.pumpAndSettle();
        expect(_state(id), Tristate.isFalse);
        await tabTo(tester, id);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(_state(id), Tristate.isTrue);
        expect(_count(tester, slug), 3);
        expect(dataById(id).label, name);
        handle.dispose();
      });
    }

    for (final slug in ['good-tile', 'good-cupertino', 'good-custom']) {
      testWidgets('$slug: a tap on the label text changes the switch', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await tester.tap(
          find.descendant(
            of: byId('f09-$slug-bluetooth'),
            matching: find.text(_bluetooth),
          ),
        );
        await tester.pumpAndSettle();
        expect(_count(tester, slug), 1);
        expect(_state('f09-$slug-bluetooth'), Tristate.isTrue);
        handle.dispose();
      });
    }

    testWidgets('good-custom: Enter changes the switch as well', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-custom');
      const id = 'f09-good-custom-bluetooth';
      await tabTo(tester, id);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(_state(id), Tristate.isTrue);
      expect(_count(tester, 'good-custom'), 1);
      handle.dispose();
    });
  });

  group('good-group', () {
    testWidgets('the question is the label of a node around both switches, '
        'and is read once', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-group');
      final group = nodeById('f09-good-group-notify').evaluate().single;
      expect(group.getSemanticsData().label, 'Notify me about');
      expect(group.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      final children = <String>[];
      group.visitChildren((child) {
        children.add(child.getSemanticsData().identifier);
        return true;
      });
      expect(children, ['f09-good-group-messages', 'f09-good-group-reminders']);
      // The visible text is on the screen and is not a second node.
      expect(find.text('Notify me about'), findsOneWidget);
      expect(
        semanticsNodes(tester)
            .where((n) => n.label.contains('Notify me about')),
        hasLength(1),
      );
      handle.dispose();
    });
  });

  group('bad examples have their defect', () {
    testWidgets('bad-unlabelled: a switch with no name beside separate text, '
        'and a tap on the text does nothing', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-unlabelled');
      final nodes = semanticsNodes(tester);
      final control = nodes.singleWhere(
        (n) => n.flagsCollection.isToggled != Tristate.none,
      );
      expect(control.label, isEmpty);
      _expectSwitch(control, Tristate.isFalse);
      final text = nodes.singleWhere((n) => n.label == _bluetooth);
      expect(text.flagsCollection.isToggled, Tristate.none);
      expect(text.hasAction(SemanticsAction.tap), isFalse);
      await expectLater(
        tester,
        doesNotMeetGuideline(labeledTapTargetGuideline),
      );
      await tester.tap(find.text(_bluetooth));
      await tester.pumpAndSettle();
      expect(_count(tester, 'bad-unlabelled'), 0);
      await tester.tap(find.byKey(const ValueKey('f09-bad-unlabelled-switch')));
      await tester.pumpAndSettle();
      expect(_count(tester, 'bad-unlabelled'), 1);
      handle.dispose();
    });

    testWidgets('bad-tile-not-merged: a button named "Bluetooth" with no '
        'state, around a switch with no name', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-tile-not-merged');
      SemanticsNode tile() => find.semantics
          .byPredicate(
            (n) =>
                !n.isMergedIntoParent &&
                n.getSemanticsData().label == _bluetooth,
          )
          .evaluate()
          .single;
      SemanticsData control() =>
          semanticsNodes(tester)
              .singleWhere((n) => n.flagsCollection.isToggled != Tristate.none);
      for (final state in [Tristate.isFalse, Tristate.isTrue]) {
        final row = tile().getSemanticsData();
        expect(row.flagsCollection.isButton, isTrue);
        expect(row.flagsCollection.isToggled, Tristate.none);
        expect(row.flagsCollection.isChecked, CheckedState.none);
        expect(row.hasAction(SemanticsAction.tap), isTrue);
        expect(control().label, isEmpty);
        _expectSwitch(control(), state);
        // The switch is a node of its own inside the row's node.
        final inside = <SemanticsData>[];
        tile().visitChildren((child) {
          inside.add(child.getSemanticsData());
          return true;
        });
        expect(inside, hasLength(1));
        expect(inside.single.flagsCollection.isToggled, state);
        await tester.tap(find.text(_bluetooth));
        await tester.pumpAndSettle();
      }
      expect(_count(tester, 'bad-tile-not-merged'), 2);
      // Two nodes with a tap action where there should be one.
      expect(
        semanticsNodes(tester).where(
          (n) =>
              n.hasAction(SemanticsAction.tap) &&
              (n.label == _bluetooth ||
                  n.flagsCollection.isToggled != Tristate.none),
        ),
        hasLength(2),
      );
      handle.dispose();
    });

    testWidgets('bad-label-changes: the name says the state and changes with '
        'it', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-label-changes');
      const id = 'f09-bad-label-changes-bluetooth';
      expect(dataById(id).label, 'Bluetooth off');
      _expectSwitch(dataById(id), Tristate.isFalse);
      await tester.tap(byId(id));
      await tester.pumpAndSettle();
      expect(dataById(id).label, 'Bluetooth on');
      _expectSwitch(dataById(id), Tristate.isTrue);
      await tester.tap(byId(id));
      await tester.pumpAndSettle();
      expect(dataById(id).label, 'Bluetooth off');
      expect(_count(tester, 'bad-label-changes'), 2);
      handle.dispose();
    });

    testWidgets('bad-no-state: a button with no on or off state, before and '
        'after it is used', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-no-state');
      const id = 'f09-bad-no-state-bluetooth';
      for (var taps = 0; taps < 2; taps++) {
        final data = dataById(id);
        expect(data.label, _bluetooth);
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.flagsCollection.isToggled, Tristate.none);
        expect(data.flagsCollection.isChecked, CheckedState.none);
        expect(data.flagsCollection.isSelected, Tristate.none);
        expect(data.value, isEmpty);
        await tester.tap(byId(id));
        await tester.pumpAndSettle();
      }
      expect(_count(tester, 'bad-no-state'), 2);
      // The drawing changed; the semantics did not.
      expect(find.byIcon(Icons.check), findsNothing);
      await tester.tap(byId(id));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(dataById(id).flagsCollection.isToggled, Tristate.none);
      handle.dispose();
    });
  });
}
