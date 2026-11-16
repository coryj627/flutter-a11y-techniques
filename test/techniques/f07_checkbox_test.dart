import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/app/app.dart';
import 'package:flutter_a11y_techniques/catalog/registry.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/f07_checkbox/f07_checkbox.dart';
import 'package:flutter_test/flutter_test.dart';

/// L1 for F07 Checkbox (docs/specs/F07-checkbox.md).
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
      registry: TechniqueRegistry([f07Checkbox]),
      platform: AppPlatform.android,
      initialRoute: '/t/F07/$slug',
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
    find.descendant(of: _id('f07-$slug-count'), matching: find.byType(Text)),
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

const _good = [
  'good-tile',
  'good-cupertino',
  'good-custom',
  'good-mixed',
  'good-group',
];

const _updates = 'Email me product updates';

/// Checkboxes that start unchecked: slug, identifier, name.
const _boxes = [
  ('good-tile', 'f07-good-tile-updates', _updates),
  ('good-cupertino', 'f07-good-cupertino-updates', _updates),
  ('good-custom', 'f07-good-custom-updates', _updates),
  ('good-group', 'f07-good-group-phone', 'Phone'),
  ('good-group', 'f07-good-group-post', 'Post'),
  ('bad-group-unlabelled', 'f07-bad-group-unlabelled-phone', 'Phone'),
];

CheckedState _state(String id) => _data(id).flagsCollection.isChecked;

void main() {
  test('the technique has the examples named in the spec', () {
    expect(f07Checkbox.examples.map((e) => e.slug), [
      ..._good,
      'bad-unlabelled',
      'bad-no-state',
      'bad-mixed-as-unchecked',
      'bad-group-unlabelled',
    ]);
    expect(_good, [
      for (final e in f07Checkbox.examples)
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

  group('checkboxes', () {
    for (final (slug, id, name) in _boxes) {
      testWidgets('$id: one node with the name "$name", a checked state, '
          'and a tap action', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        final data = _data(id);
        expect(data.label, name);
        expect(data.value, isEmpty);
        expect(_state(id), CheckedState.isFalse);
        // A checkbox: not a switch, not a radio button, not a button.
        expect(data.flagsCollection.isToggled, Tristate.none);
        expect(data.flagsCollection.isInMutuallyExclusiveGroup, isFalse);
        expect(data.flagsCollection.isButton, isFalse);
        expect(data.flagsCollection.isEnabled, Tristate.isTrue);
        expect(data.hasAction(SemanticsAction.tap), isTrue);
        // The name is on the checkbox and on no other node.
        expect(_nodes(tester).where((n) => n.label == name), hasLength(1));
        handle.dispose();
      });

      testWidgets('$id: tap, the semantics action, and Space each change '
          'the state', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await tester.tap(_id(id));
        await tester.pumpAndSettle();
        expect(_state(id), CheckedState.isTrue);
        tester.semantics.tap(_node(id));
        await tester.pumpAndSettle();
        expect(_state(id), CheckedState.isFalse);
        await _tabTo(tester, id);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(_state(id), CheckedState.isTrue);
        expect(_count(tester, slug), 3);
        expect(_data(id).label, name);
        handle.dispose();
      });
    }

    for (final slug in ['good-tile', 'good-cupertino', 'good-custom']) {
      testWidgets('$slug: a tap on the label text changes the checkbox', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await tester.tap(
          find.descendant(
            of: _id('f07-$slug-updates'),
            matching: find.text(_updates),
          ),
        );
        await tester.pumpAndSettle();
        expect(_count(tester, slug), 1);
        expect(_state('f07-$slug-updates'), CheckedState.isTrue);
        handle.dispose();
      });
    }
  });

  group('good-mixed', () {
    const all = 'f07-good-mixed-all';
    const email = 'f07-good-mixed-email';
    const text = 'f07-good-mixed-text';

    testWidgets('"Select all" is mixed while one of the two is checked', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-mixed');
      expect(_data(all).label, 'Select all');
      expect(_state(email), CheckedState.isTrue);
      expect(_state(text), CheckedState.isFalse);
      expect(_state(all), CheckedState.mixed);
      handle.dispose();
    });

    testWidgets('it follows the two boxes, and sets both', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-mixed');
      // Check the second box: all checked.
      await tester.tap(_id(text));
      await tester.pumpAndSettle();
      expect(_state(all), CheckedState.isTrue);
      // "Select all" from checked clears both.
      await tester.tap(_id(all));
      await tester.pumpAndSettle();
      expect(_state(all), CheckedState.isFalse);
      expect(_state(email), CheckedState.isFalse);
      expect(_state(text), CheckedState.isFalse);
      // One box: mixed again. "Select all" from mixed checks both.
      await tester.tap(_id(email));
      await tester.pumpAndSettle();
      expect(_state(all), CheckedState.mixed);
      await _tabTo(tester, all);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(_state(all), CheckedState.isTrue);
      expect(_state(email), CheckedState.isTrue);
      expect(_state(text), CheckedState.isTrue);
      expect(_count(tester, 'good-mixed'), 4);
      handle.dispose();
    });
  });

  group('good-group', () {
    testWidgets('the question is the label of a node around both boxes, and '
        'is read once', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-group');
      final group = _node('f07-good-group-contact').evaluate().single;
      expect(group.getSemanticsData().label, 'Contact me by');
      expect(group.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      final children = <String>[];
      group.visitChildren((child) {
        children.add(child.getSemanticsData().identifier);
        return true;
      });
      expect(children, ['f07-good-group-phone', 'f07-good-group-post']);
      // The visible text is on the screen and is not a second node.
      expect(find.text('Contact me by'), findsOneWidget);
      expect(
        _nodes(tester).where((n) => n.label.contains('Contact me by')),
        hasLength(1),
      );
      handle.dispose();
    });
  });

  group('bad examples have their defect', () {
    testWidgets('bad-unlabelled: a checkbox with no name beside separate '
        'text, and a tap on the text does nothing', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-unlabelled');
      final nodes = _nodes(tester);
      final box = nodes.singleWhere(
        (n) => n.flagsCollection.isChecked != CheckedState.none,
      );
      expect(box.label, isEmpty);
      expect(box.hasAction(SemanticsAction.tap), isTrue);
      final text = nodes.singleWhere((n) => n.label == _updates);
      expect(text.flagsCollection.isChecked, CheckedState.none);
      expect(text.hasAction(SemanticsAction.tap), isFalse);
      await expectLater(
        tester,
        doesNotMeetGuideline(labeledTapTargetGuideline),
      );
      await tester.tap(find.text(_updates));
      await tester.pumpAndSettle();
      expect(_count(tester, 'bad-unlabelled'), 0);
      await tester.tap(_id('f07-bad-unlabelled-box'));
      await tester.pumpAndSettle();
      expect(_count(tester, 'bad-unlabelled'), 1);
      handle.dispose();
    });

    testWidgets('bad-no-state: a button with no checked state, before and '
        'after it is used', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-no-state');
      const id = 'f07-bad-no-state-updates';
      for (var taps = 0; taps < 2; taps++) {
        final data = _data(id);
        expect(data.label, _updates);
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.flagsCollection.isChecked, CheckedState.none);
        expect(data.flagsCollection.isToggled, Tristate.none);
        expect(data.flagsCollection.isSelected, Tristate.none);
        expect(data.value, isEmpty);
        await tester.tap(_id(id));
        await tester.pumpAndSettle();
      }
      expect(_count(tester, 'bad-no-state'), 2);
      // The drawing changed; the semantics did not.
      expect(find.byIcon(Icons.check), findsNothing);
      await tester.tap(_id(id));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check), findsOneWidget);
      handle.dispose();
    });

    testWidgets('bad-mixed-as-unchecked: "Select all" is not checked while '
        'one box under it is', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-mixed-as-unchecked');
      expect(_state('f07-bad-mixed-as-unchecked-email'), CheckedState.isTrue);
      expect(_state('f07-bad-mixed-as-unchecked-text'), CheckedState.isFalse);
      expect(_state('f07-bad-mixed-as-unchecked-all'), CheckedState.isFalse);
      handle.dispose();
    });

    testWidgets('bad-group-unlabelled: the question is a text node beside '
        'the boxes, and no node contains them', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-group-unlabelled');
      final question = find.semantics
          .byPredicate(
            (n) =>
                !n.isMergedIntoParent &&
                n.getSemanticsData().label == 'Contact me by',
          )
          .evaluate()
          .single;
      expect(question.childrenCount, 0);
      final phone = _node('f07-bad-group-unlabelled-phone').evaluate().single;
      expect(phone.parent, question.parent);
      handle.dispose();
    });
  });
}
