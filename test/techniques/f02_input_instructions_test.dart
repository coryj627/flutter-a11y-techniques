import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/catalog/test_id.dart';
import 'package:flutter_a11y_techniques/techniques/f02_input_instructions/f02_input_instructions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/examples.dart';

/// L1 for F02 Input instructions (docs/specs/F02-input-instructions.md).
final _open = exampleOpener(f02InputInstructions);

int _count(WidgetTester tester, String slug) =>
    countOf(tester, 'f02-$slug-count');

const _good = ['good-helper', 'good-cupertino', 'good-before'];

const _username = 'Username';
const _rule = '4 to 10 characters, no spaces.';
const _displayRule = 'Shown on your posts. 2 to 30 letters or numbers.';

/// Good fields: slug, identifier. Each is named "Username" and has the
/// instruction [_rule] on the screen and as its hint.
const _fields = [
  ('good-helper', 'f02-good-helper-username'),
  ('good-cupertino', 'f02-good-cupertino-username'),
  ('good-before', 'f02-good-before-username'),
];

Future<void> _type(WidgetTester tester, String id, String text) async {
  await tester.enterText(
    find.descendant(of: byId(id), matching: find.byType(EditableText)),
    text,
  );
  await tester.pumpAndSettle();
}

/// The nodes, not merged into a parent, whose label is [label].
Iterable<SemanticsData> _labelled(WidgetTester tester, String label) =>
    semanticsNodes(tester).where((n) => n.label == label);

/// The paragraphs on the example screen that show [text].
Iterable<RenderParagraph> _paragraphs(WidgetTester tester, String text) =>
    tester
        .renderObjectList<RenderParagraph>(find.byType(RichText))
        .where((p) => p.text.toPlainText() == text);

/// The identifiers of the children of the node with [id], in order, with
/// their labels.
List<String> _children(String id) {
  final children = <String>[];
  nodeById(id).evaluate().single.visitChildren((child) {
    children.add(child.getSemanticsData().label);
    return true;
  });
  return children;
}

void main() {
  test('the technique has the examples named in the spec', () {
    expect(f02InputInstructions.examples.map((e) => e.slug), [
      ..._good,
      'bad-helper-only',
      'bad-placeholder-format',
      'bad-helper-cut-off',
    ]);
    expect(_good, [
      for (final e in f02InputInstructions.examples)
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

      testWidgets('$slug does not overflow at 200% text on a phone, and the '
          'instruction is shown whole', (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await _open(tester, slug, textScale: 2);
        expect(tester.takeException(), isNull);
        final rule = _paragraphs(tester, _rule);
        expect(rule, hasLength(1));
        expect(rule.single.didExceedMaxLines, isFalse);
      });
    }

    for (final (slug, id) in _fields) {
      testWidgets('$id: a text field named "$_username" with the instruction '
          'as its hint, before and after typing', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        for (final value in ['', 'abc']) {
          if (value.isNotEmpty) await _type(tester, id, value);
          final data = dataById(id);
          expect(data.flagsCollection.isTextField, isTrue, reason: id);
          expect(data.label, _username, reason: '$id, value "$value"');
          expect(data.hint, _rule, reason: '$id, value "$value"');
          expect(data.value, value, reason: id);
        }
        expect(_count(tester, slug), 1);
        handle.dispose();
      });

      testWidgets('$id: the instruction stays on the screen and is an '
          'element of its own, read once as text', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await _type(tester, id, 'abc');
        // On screen, and not cut off.
        expect(find.text(_rule).hitTestable(), findsOneWidget);
        // One node whose label is the instruction: the text itself. The
        // field has it as its hint, not in its name.
        final rule = _labelled(tester, _rule);
        expect(rule, hasLength(1));
        expect(rule.single.flagsCollection.isTextField, isFalse);
        expect(rule.single.hasAction(SemanticsAction.tap), isFalse);
        // The visible label is not a second node.
        expect(_labelled(tester, _username), hasLength(1));
        handle.dispose();
      });

      testWidgets('$id: Tab reaches the field', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await tabTo(tester, id);
        handle.dispose();
      });
    }

    testWidgets('good-before: the instruction comes before the field in '
        'reading order', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-before');
      final nodes = semanticsNodes(tester);
      final rule = nodes.indexWhere((n) => n.label == _rule);
      final field = nodes.indexWhere(
        (n) => n.identifier == 'f02-good-before-username',
      );
      expect(rule, greaterThanOrEqualTo(0));
      expect(field, rule + 1);
      handle.dispose();
    });

    testWidgets('good-helper: the helper text is a node inside the field\'s '
        'node, as Flutter builds it (FL-140)', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-helper');
      expect(_children('f02-good-helper-username'), [_rule]);
      handle.dispose();
    });
  });

  // VAL-3: each bad example is asserted to have its named defect.
  group('bad examples have their defect', () {
    testWidgets('bad-helper-only: the field has no hint, and the instruction '
        'is only text inside it (FL-140)', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-helper-only');
      const id = 'f02-bad-helper-only-username';
      for (final value in ['', 'abc']) {
        if (value.isNotEmpty) await _type(tester, id, value);
        final data = dataById(id);
        expect(data.flagsCollection.isTextField, isTrue);
        expect(data.label, _username);
        // Written to fail if Flutter starts to give a field its helper text
        // as a hint or description.
        expect(data.hint, isEmpty, reason: 'value "$value"');
        expect(find.text(_rule).hitTestable(), findsOneWidget);
        expect(_children(id), [_rule]);
        expect(_labelled(tester, _rule).single.hint, isEmpty);
      }
      expect(_count(tester, 'bad-helper-only'), 1);
      handle.dispose();
    });

    testWidgets('bad-placeholder-format: the format is shown and exposed '
        'only while the field is focused and empty', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-placeholder-format');
      const id = 'f02-bad-placeholder-format-birthday';
      const format = 'DD/MM/YYYY';
      // Whether the placeholder is drawn: Material keeps it in the widget
      // tree at opacity 0 once text is typed.
      bool shown() {
        final text = find.text(format);
        if (text.evaluate().isEmpty) return false;
        final fade = find.ancestor(
          of: text,
          matching: find.byType(AnimatedOpacity),
        );
        return fade.evaluate().isEmpty ||
            tester.widget<AnimatedOpacity>(fade.first).opacity > 0;
      }

      // Not focused: nothing on the screen or in the tree gives the format.
      expect(shown(), isFalse);
      expect(dataById(id).label, 'Date of birth');
      expect(dataById(id).hint, isEmpty);
      // Focused and empty: the placeholder appears, and Flutter adds it to
      // the field's name.
      await tester.tap(byId(id));
      await tester.pumpAndSettle();
      expect(shown(), isTrue);
      expect(dataById(id).label, 'Date of birth\n$format');
      // One character in: gone from the screen and from the tree.
      await _type(tester, id, 'a');
      expect(shown(), isFalse);
      expect(dataById(id).label, 'Date of birth');
      expect(dataById(id).hint, isEmpty);
      expect(
        semanticsNodes(tester).where((n) => n.label.contains(format)),
        isEmpty,
      );
      expect(_count(tester, 'bad-placeholder-format'), 1);
      handle.dispose();
    });

    testWidgets('bad-helper-cut-off: the whole instruction fits at 100% '
        'text and is cut to one line at 200% (FL-141)', (tester) async {
      final handle = tester.ensureSemantics();
      const id = 'f02-bad-helper-cut-off-name';
      // The default test screen is 800 wide: the line fits at 100%.
      await _open(tester, 'bad-helper-cut-off');
      expect(
        _paragraphs(tester, _displayRule).single.didExceedMaxLines,
        isFalse,
      );
      await tester.pumpWidget(const SizedBox());
      await _open(tester, 'bad-helper-cut-off', textScale: 2);
      final helper = _paragraphs(tester, _displayRule).single;
      // Written to fail if Flutter starts to wrap helper text by default.
      expect(helper.maxLines, isNull);
      expect(helper.didExceedMaxLines, isTrue);
      expect(tester.takeException(), isNull);
      // The tree still has all of it, as the field's hint and as the text:
      // only the screen loses the end.
      expect(dataById(id).hint, _displayRule);
      expect(_labelled(tester, _displayRule), hasLength(1));
      handle.dispose();
    });
  });

  group('Flutter limitations shown outside the examples', () {
    testWidgets('FL-140: inside MergeSemantics, as TestId puts it, helper '
        'text joins the field\'s name', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TestId(
              'field',
              child: TextField(
                decoration: InputDecoration(
                  labelText: _username,
                  helperText: _rule,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final data = dataById('field');
      expect(data.label, '$_username\n$_rule');
      expect(data.hint, isEmpty);
      expect(_labelled(tester, _rule), isEmpty);
      handle.dispose();
    });
  });
}
