import 'dart:ui' show CheckedState, SemanticsRole, Tristate;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/app/app.dart';
import 'package:flutter_a11y_techniques/catalog/registry.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/f08_radio_group/f08_radio_group.dart';
import 'package:flutter_test/flutter_test.dart';

/// L1 for F08 Radio group (docs/specs/F08-radio-group.md).
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
      registry: TechniqueRegistry([f08RadioGroup]),
      platform: AppPlatform.android,
      initialRoute: '/t/F08/$slug',
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
    find.descendant(of: _id('f08-$slug-count'), matching: find.byType(Text)),
  );
  return int.parse(text.data!.split(': ').last);
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

const _good = ['good-group', 'good-cupertino', 'good-custom', 'good-context'];

/// The examples whose options are "Standard", "Express", and "Next day",
/// with "Express" chosen, and that are radio buttons to the semantics tree.
const _radioExamples = [
  'good-group',
  'good-cupertino',
  'good-custom',
  'bad-group-unlabelled',
  'bad-checked-only',
];

/// The examples built on `RadioGroup`, which supplies the arrow keys.
const _grouped = ['good-group', 'good-cupertino', 'good-custom'];

const _options = {
  'standard': 'Standard',
  'express': 'Express',
  'next-day': 'Next day',
};

CheckedState _state(String id) => _data(id).flagsCollection.isChecked;

/// The option that is checked, as its id segment.
String _chosen(String slug) => _options.keys.singleWhere(
  (option) => _state('f08-$slug-$option') == CheckedState.isTrue,
);

void main() {
  test('the technique has the examples named in the spec', () {
    expect(f08RadioGroup.examples.map((e) => e.slug), [
      ..._good,
      'bad-unlabelled',
      'bad-group-unlabelled',
      'bad-no-state',
      'bad-checkbox-role',
      'bad-checked-only',
    ]);
    expect(_good, [
      for (final e in f08RadioGroup.examples)
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

      testWidgets('$slug: the question is the label of a node around a radio '
          'group, and is read once', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        final question = slug == 'good-context'
            ? 'Are you at home?'
            : 'Delivery speed';
        final outer = _node('f08-$slug-group').evaluate().single;
        expect(outer.getSemanticsData().label, question);
        expect(
          outer.getSemanticsData().hasAction(SemanticsAction.tap),
          isFalse,
        );
        // Inside it, the node RadioGroup makes: the role, and no label.
        final inner = <SemanticsNode>[];
        outer.visitChildren((child) {
          inner.add(child);
          return true;
        });
        expect(inner, hasLength(1));
        expect(inner.single.getSemanticsData().role, SemanticsRole.radioGroup);
        // Flutter 3.47.5: RadioGroup has no way to take a name (FL-046). If
        // this fails, it has one, and the wrapper is no longer needed.
        expect(inner.single.getSemanticsData().label, isEmpty);
        var radios = 0;
        inner.single.visitChildren((child) {
          final flags = child.getSemanticsData().flagsCollection;
          if (flags.isInMutuallyExclusiveGroup) radios++;
          return true;
        });
        expect(radios, slug == 'good-context' ? 2 : 3);
        expect(find.text(question), findsOneWidget);
        expect(
          _nodes(tester).where((n) => n.label.contains(question)),
          hasLength(1),
        );
        handle.dispose();
      });
    }
  });

  group('radio buttons', () {
    for (final slug in _radioExamples) {
      testWidgets('$slug: three radio buttons with their names, and '
          '"Express" checked', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        for (final MapEntry(key: option, value: name) in _options.entries) {
          final data = _data('f08-$slug-$option');
          expect(data.label, name, reason: option);
          expect(data.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
          expect(
            data.flagsCollection.isChecked,
            option == 'express' ? CheckedState.isTrue : CheckedState.isFalse,
            reason: option,
          );
          expect(data.flagsCollection.isToggled, Tristate.none);
          expect(data.flagsCollection.isButton, isFalse);
          expect(data.flagsCollection.isEnabled, Tristate.isTrue);
          expect(data.hasAction(SemanticsAction.tap), isTrue);
          // The name is on the radio button and on no other node.
          expect(_nodes(tester).where((n) => n.label == name), hasLength(1));
        }
        handle.dispose();
      });

      testWidgets('$slug: a tap and the semantics action each choose one '
          'option and clear the other', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await tester.tap(_id('f08-$slug-standard'));
        await tester.pumpAndSettle();
        expect(_chosen(slug), 'standard');
        tester.semantics.tap(_node('f08-$slug-next-day'));
        await tester.pumpAndSettle();
        expect(_chosen(slug), 'next-day');
        expect(_count(tester, slug), 2);
        // Choosing the chosen one again changes nothing.
        await tester.tap(_id('f08-$slug-next-day'));
        await tester.pumpAndSettle();
        expect(_chosen(slug), 'next-day');
        expect(_count(tester, slug), 2);
        handle.dispose();
      });
    }

    for (final slug in _grouped) {
      testWidgets('$slug: Tab goes to the chosen option, and the arrow keys '
          'move the choice and wrap', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        // The Back button, then the group: focus lands on "Express".
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(
          _data('f08-$slug-express').flagsCollection.isFocused,
          Tristate.isTrue,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        expect(_chosen(slug), 'next-day');
        expect(
          _data('f08-$slug-next-day').flagsCollection.isFocused,
          Tristate.isTrue,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        expect(_chosen(slug), 'standard');
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();
        expect(_chosen(slug), 'next-day');
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pumpAndSettle();
        expect(_chosen(slug), 'express');
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        expect(_chosen(slug), 'next-day');
        expect(_count(tester, slug), 5);
        handle.dispose();
      });

      testWidgets('$slug: a tap on the text of an option chooses it', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await tester.tap(
          find.descendant(
            of: _id('f08-$slug-standard'),
            matching: find.text('Standard'),
          ),
        );
        await tester.pumpAndSettle();
        expect(_chosen(slug), 'standard');
        expect(_count(tester, slug), 1);
        handle.dispose();
      });
    }
  });

  group('on iOS', () {
    // RawRadio adds a selected state, and a hint on the options that are
    // not chosen, on iOS and macOS only: iOS reads neither `checked` nor a
    // radio role (FL-047).
    for (final slug in _grouped) {
      testWidgets('$slug: the chosen option is selected, and the others '
          'have the hint "Not selected"', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        expect(
          _data('f08-$slug-express').flagsCollection.isSelected,
          Tristate.isTrue,
        );
        expect(_data('f08-$slug-express').hint, isEmpty);
        for (final option in ['standard', 'next-day']) {
          final data = _data('f08-$slug-$option');
          expect(data.flagsCollection.isSelected, Tristate.isFalse);
          expect(data.hint, 'Not selected');
        }
        handle.dispose();
        debugDefaultTargetPlatformOverride = null;
      });
    }

    testWidgets('bad-checked-only: no option has a selected state or a hint', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-checked-only');
      for (final option in _options.keys) {
        final data = _data('f08-bad-checked-only-$option');
        expect(data.flagsCollection.isSelected, Tristate.none, reason: option);
        expect(data.hint, isEmpty, reason: option);
      }
      // The checked state is there; iOS does not read it for a radio button.
      expect(_chosen('bad-checked-only'), 'express');
      handle.dispose();
      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('good-context', () {
    testWidgets('each answer has a name that starts with its visible text '
        'and carries the question', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-context');
      expect(_data('f08-good-context-yes').label, 'Yes, I am at home');
      expect(_data('f08-good-context-no').label, 'No, I am not at home');
      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);
      expect(_state('f08-good-context-no'), CheckedState.isTrue);
      await tester.tap(_id('f08-good-context-yes'));
      await tester.pumpAndSettle();
      expect(_state('f08-good-context-yes'), CheckedState.isTrue);
      expect(_state('f08-good-context-no'), CheckedState.isFalse);
      handle.dispose();
    });
  });

  group('bad examples have their defect', () {
    testWidgets('bad-unlabelled: three radio buttons with no names, and a '
        'tap on the text does nothing', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-unlabelled');
      final radios = _nodes(tester)
          .where((n) => n.flagsCollection.isInMutuallyExclusiveGroup)
          .toList();
      expect(radios, hasLength(3));
      expect(radios.every((n) => n.label.isEmpty), isTrue);
      await expectLater(
        tester,
        doesNotMeetGuideline(labeledTapTargetGuideline),
      );
      await tester.tap(find.text('Standard'));
      await tester.pumpAndSettle();
      expect(_count(tester, 'bad-unlabelled'), 0);
      await tester.tap(_id('f08-bad-unlabelled-standard'));
      await tester.pumpAndSettle();
      expect(_count(tester, 'bad-unlabelled'), 1);
      handle.dispose();
    });

    testWidgets('bad-group-unlabelled: the radio group has no label and no '
        'labelled node around it', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-group-unlabelled');
      final radio = _node('f08-bad-group-unlabelled-standard')
          .evaluate()
          .single;
      final group = radio.parent!;
      expect(group.getSemanticsData().role, SemanticsRole.radioGroup);
      expect(group.getSemanticsData().label, isEmpty);
      expect(group.parent!.getSemanticsData().label, isEmpty);
      // The question is a node beside the group.
      final question = find.semantics
          .byPredicate(
            (n) =>
                !n.isMergedIntoParent &&
                n.getSemanticsData().label == 'Delivery speed',
          )
          .evaluate()
          .single;
      expect(question.childrenCount, 0);
      expect(question.parent, group.parent);
      handle.dispose();
    });

    testWidgets('bad-no-state: three buttons with no state, before and '
        'after one is chosen', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-no-state');
      for (var pass = 0; pass < 2; pass++) {
        for (final MapEntry(key: option, value: name) in _options.entries) {
          final data = _data('f08-bad-no-state-$option');
          expect(data.label, name);
          expect(data.flagsCollection.isButton, isTrue);
          expect(data.flagsCollection.isChecked, CheckedState.none);
          expect(data.flagsCollection.isSelected, Tristate.none);
          expect(data.flagsCollection.isInMutuallyExclusiveGroup, isFalse);
          expect(data.value, isEmpty);
        }
        await tester.tap(_id('f08-bad-no-state-standard'));
        await tester.pumpAndSettle();
      }
      expect(_count(tester, 'bad-no-state'), 1);
      handle.dispose();
    });

    testWidgets('bad-checkbox-role: checkboxes, of which choosing one '
        'clears another', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-checkbox-role');
      for (final option in _options.keys) {
        final flags = _data('f08-bad-checkbox-role-$option').flagsCollection;
        expect(flags.isChecked, isNot(CheckedState.none), reason: option);
        expect(flags.isInMutuallyExclusiveGroup, isFalse, reason: option);
      }
      expect(_state('f08-bad-checkbox-role-express'), CheckedState.isTrue);
      await tester.tap(_id('f08-bad-checkbox-role-standard'));
      await tester.pumpAndSettle();
      expect(_state('f08-bad-checkbox-role-standard'), CheckedState.isTrue);
      expect(_state('f08-bad-checkbox-role-express'), CheckedState.isFalse);
      handle.dispose();
    });

    testWidgets('bad-checked-only: no radio group around the options', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-checked-only');
      expect(
        _nodes(tester).where((n) => n.role == SemanticsRole.radioGroup),
        isEmpty,
      );
      handle.dispose();
    });
  });
}
