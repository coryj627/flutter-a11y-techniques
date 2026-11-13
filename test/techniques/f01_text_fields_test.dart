import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_a11y_techniques/app/app.dart';
import 'package:flutter_a11y_techniques/catalog/registry.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/f01_text_fields/f01_text_fields.dart';
import 'package:flutter_test/flutter_test.dart';

/// L1 for F01 Text fields and labels (docs/specs/F01-text-fields.md).
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
      registry: TechniqueRegistry([f01TextFields]),
      platform: AppPlatform.android,
      initialRoute: '/t/F01/$slug',
    ),
  );
  await tester.pumpAndSettle();
}

Finder _id(String id) => find.byKey(ValueKey<String>(id));

SemanticsData _data(WidgetTester tester, String id) =>
    tester.getSemantics(_id(id)).getSemanticsData();

Future<void> _type(WidgetTester tester, String id, String text) async {
  await tester.enterText(
    find.descendant(of: _id(id), matching: find.byType(EditableText)),
    text,
  );
  await tester.pumpAndSettle();
}

/// Good fields: identifier -> (name, visible label text).
const _good = {
  'good-label': {
    'f01-good-label-email': 'Email',
    'f01-good-label-message': 'Message',
  },
  'good-label-above': {'f01-good-label-above-name': 'Full name'},
  'good-cupertino': {'f01-good-cupertino-email': 'Email'},
};

void main() {
  test('the technique has the examples named in the spec', () {
    expect(f01TextFields.examples.map((e) => e.slug), [
      'good-label',
      'good-label-above',
      'good-cupertino',
      'bad-placeholder-only',
      'bad-unassociated-label',
      'bad-no-label',
      'bad-name-mismatch',
      'bad-cupertino-placeholder',
      'bad-cupertino-prefix',
    ]);
  });

  group('good examples', () {
    for (final MapEntry(key: slug, value: fields) in _good.entries) {
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

      testWidgets('$slug: a text field with a name that survives typing, '
          'and a visible label that stays on screen', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        for (final MapEntry(key: id, value: name) in fields.entries) {
          expect(
            tester.getSemantics(_id(id)),
            isSemantics(isTextField: true, label: name, identifier: id),
            reason: id,
          );
          await _type(tester, id, 'abc');
          final data = _data(tester, id);
          expect(data.label, name, reason: '$id after typing');
          expect(data.value, 'abc', reason: id);
          // The label is still drawn, and it is the same text as the name
          // (WCAG 2.5.3).
          expect(find.text(name), findsOneWidget, reason: '$id visible label');
        }
        handle.dispose();
      });
    }

    testWidgets('good-label-above and good-cupertino: the visible label is '
        'not read a second time', (tester) async {
      final handle = tester.ensureSemantics();
      for (final (slug, name) in [
        ('good-label-above', 'Full name'),
        ('good-cupertino', 'Email'),
      ]) {
        await tester.pumpWidget(const SizedBox());
        await _open(tester, slug);
        var count = 0;
        void visit(SemanticsNode node) {
          // Nodes merged into a parent are not separate stops for a screen
          // reader.
          if (!node.isMergedIntoParent &&
              node.getSemanticsData().label == name) {
            count++;
          }
          node.visitChildren((child) {
            visit(child);
            return true;
          });
        }

        visit(tester.getSemantics(find.byType(Scaffold)));
        expect(count, 1, reason: slug);
      }
      handle.dispose();
    });
  });

  // VAL-3: each bad example is asserted to have its named defect.
  group('bad examples have their defect', () {
    for (final (slug, id) in [
      ('bad-placeholder-only', 'f01-bad-placeholder-only-email'),
      ('bad-cupertino-placeholder', 'f01-bad-cupertino-placeholder-email'),
    ]) {
      testWidgets('$slug: the name and the visible label vanish once text is '
          'typed', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        expect(_data(tester, id).label, 'Email');
        expect(find.text('Email'), findsOneWidget);
        await _type(tester, id, 'abc');
        // Nothing on screen or in the tree says what the field is for.
        expect(_data(tester, id).label, isEmpty);
        expect(_data(tester, id).hint, isEmpty);
        expect(find.text('Email').hitTestable(), findsNothing);
        handle.dispose();
      });
    }

    for (final (slug, id, nearby) in [
      ('bad-unassociated-label', 'f01-bad-unassociated-label-email', 'Email'),
      ('bad-cupertino-prefix', 'f01-bad-cupertino-prefix-email', 'Email'),
    ]) {
      testWidgets('$slug: the label is on screen but the field has no name', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        expect(find.text(nearby), findsOneWidget);
        final data = _data(tester, id);
        expect(data.flagsCollection.isTextField, isTrue);
        expect(data.label, isEmpty);
        expect(data.hint, isEmpty);
        handle.dispose();
      });
    }

    testWidgets('bad-no-label: a text field with no name and no visible '
        'label', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-no-label');
      final data = _data(tester, 'f01-bad-no-label-search');
      expect(data.flagsCollection.isTextField, isTrue);
      expect(data.label, isEmpty);
      expect(data.hint, isEmpty);
      expect(
        find.descendant(
          of: _id('f01-bad-no-label-search'),
          matching: find.byType(Text),
        ),
        findsNothing,
      );
      handle.dispose();
    });

    testWidgets('bad-name-mismatch: the name lacks the visible label text', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-name-mismatch');
      expect(find.text('Email'), findsOneWidget);
      final name = _data(tester, 'f01-bad-name-mismatch-email').label;
      expect(name, 'Contact address');
      expect(name.toLowerCase(), isNot(contains('email')));
      handle.dispose();
    });
  });
}
