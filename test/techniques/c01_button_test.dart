import 'dart:ui' show Tristate;

import 'package:flutter/cupertino.dart' show CupertinoButton;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/app/app.dart';
import 'package:flutter_a11y_techniques/catalog/registry.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/c01_button/c01_button.dart';
import 'package:flutter_test/flutter_test.dart';

/// L1 for C01 Button (docs/specs/C01-button.md, section 6).
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
      registry: TechniqueRegistry([c01Button]),
      platform: AppPlatform.android,
      initialRoute: '/t/C01/$slug',
    ),
  );
  await tester.pumpAndSettle();
}

Finder _id(String id) => find.byKey(ValueKey<String>(id));

SemanticsNode _node(WidgetTester tester, String id) =>
    tester.getSemantics(_id(id));

/// The accessible name: the label, or the tooltip when there is no label
/// (an `IconButton` is named by its tooltip).
String _label(WidgetTester tester, String id) {
  final data = _node(tester, id).getSemanticsData();
  return data.label.isNotEmpty ? data.label : data.tooltip;
}

int _count(WidgetTester tester, String slug) {
  final text = tester.widget<Text>(
    find.descendant(of: _id('c01-$slug-count'), matching: find.byType(Text)),
  );
  return int.parse(text.data!.split(': ').last);
}

/// Identifiers of the enabled good buttons, with their expected names.
const _enabledGood = {
  'good-text': {
    'c01-good-text-filled': 'Save',
    'c01-good-text-outlined': 'Cancel',
    'c01-good-text-text': 'Learn more',
  },
  'good-icon': {'c01-good-icon-close': 'Close'},
  'good-unique-names': {
    'c01-good-unique-names-username': 'Edit username',
    'c01-good-unique-names-email': 'Edit email',
    'c01-good-unique-names-password': 'Edit password',
  },
  'good-cupertino': {'c01-good-cupertino-save': 'Save'},
  'good-custom': {'c01-good-custom-save': 'Save'},
};

const _disabledGood = {
  'good-disabled': {'c01-good-disabled-submit': 'Submit'},
  'good-cupertino': {'c01-good-cupertino-delete': 'Delete'},
};

void main() {
  final goodSlugs = [
    for (final e in c01Button.examples)
      if (e.kind == ExampleKind.good) e.slug,
  ];

  test('the technique has the examples named in the spec', () {
    expect(c01Button.examples.map((e) => e.slug), [
      'good-text',
      'good-icon',
      'good-disabled',
      'good-unique-names',
      'good-cupertino',
      'good-custom',
      'bad-unlabelled-icon',
      'bad-gesture-only',
      'bad-role-in-name',
      'bad-duplicate-names',
      'bad-name-mismatch',
      'bad-fake-disabled',
      'bad-cupertino-disabled',
    ]);
  });

  group('good examples', () {
    for (final slug in goodSlugs) {
      for (final brightness in Brightness.values) {
        testWidgets('$slug meets the guidelines (${brightness.name})', (
          tester,
        ) async {
          final handle = tester.ensureSemantics();
          await _open(tester, slug, brightness: brightness);
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          // WCAG 1.4.3 exempts inactive components, but Flutter's guideline
          // checks them, so examples with a disabled button skip it.
          if (!_disabledGood.containsKey(slug)) {
            await expectLater(tester, meetsGuideline(textContrastGuideline));
          }
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

    for (final MapEntry(key: slug, value: buttons) in _enabledGood.entries) {
      testWidgets('$slug: name, role, enabled state, and activation', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        var expected = 0;
        for (final MapEntry(key: id, value: name) in buttons.entries) {
          expect(_label(tester, id), name, reason: id);
          expect(
            _node(tester, id),
            isSemantics(identifier: id, isButton: true, hasTapAction: true),
            reason: id,
          );
          final flags = _node(tester, id).getSemanticsData().flagsCollection;
          expect(flags.isEnabled, isNot(Tristate.isFalse), reason: id);
          await tester.tap(_id(id));
          await tester.pump();
          expect(_count(tester, slug), ++expected, reason: 'tap $id');
        }
        handle.dispose();
      });

      testWidgets('$slug: Tab reaches each button; Enter and Space activate', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        var expected = 0;
        for (final id in buttons.keys) {
          // Tab until this button has focus. The Back button comes first.
          var reached = false;
          for (var i = 0; i < 6 && !reached; i++) {
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.pump();
            reached =
                _node(
                  tester,
                  id,
                ).getSemanticsData().flagsCollection.isFocused ==
                Tristate.isTrue;
          }
          expect(reached, isTrue, reason: 'Tab did not reach $id');
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pump();
          expect(_count(tester, slug), ++expected, reason: 'Enter on $id');
          await tester.sendKeyEvent(LogicalKeyboardKey.space);
          await tester.pump();
          expect(_count(tester, slug), ++expected, reason: 'Space on $id');
        }
        handle.dispose();
      });
    }

    for (final MapEntry(key: slug, value: buttons) in _disabledGood.entries) {
      testWidgets('$slug: disabled button reports disabled and cannot act', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        for (final MapEntry(key: id, value: name) in buttons.entries) {
          expect(_label(tester, id), name, reason: id);
          expect(
            _node(tester, id),
            isSemantics(
              isButton: true,
              hasEnabledState: true,
              isEnabled: false,
            ),
            reason: id,
          );
          // Flutter 3.47.5: a disabled CupertinoButton still lists a tap
          // action in semantics, though it does nothing. Material does not.
          if (!id.contains('cupertino')) {
            expect(
              _node(tester, id),
              isSemantics(hasTapAction: false),
              reason: id,
            );
          }
          final before = _count(tester, slug);
          await tester.tap(_id(id), warnIfMissed: false);
          await tester.pump();
          expect(_count(tester, slug), before, reason: 'tap $id');
        }
        handle.dispose();
      });
    }

    testWidgets('good-unique-names: names are unique and start with the '
        'visible text', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-unique-names');
      final names = [
        for (final id in _enabledGood['good-unique-names']!.keys)
          _label(tester, id),
      ];
      expect(names.toSet(), hasLength(names.length));
      expect(names, everyElement(startsWith('Edit')));
      expect(find.text('Edit'), findsNWidgets(3));
      handle.dispose();
    });
  });

  // VAL-3: each bad example is asserted to have its named defect.
  group('bad examples have their defect', () {
    testWidgets('bad-unlabelled-icon: a button with no name', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-unlabelled-icon');
      expect(
        _node(tester, 'c01-bad-unlabelled-icon-close'),
        isSemantics(isButton: true, hasTapAction: true),
      );
      expect(_label(tester, 'c01-bad-unlabelled-icon-close'), isEmpty);
      await expectLater(
        tester,
        doesNotMeetGuideline(labeledTapTargetGuideline),
      );
      handle.dispose();
    });

    testWidgets('bad-gesture-only: no button role, no keyboard access', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-gesture-only');
      const id = 'c01-bad-gesture-only-save';
      final data = _node(tester, id).getSemanticsData();
      expect(data.label, 'Save');
      expect(data.flagsCollection.isButton, isFalse);
      expect(data.flagsCollection.isFocused, Tristate.none);
      // Tab through everything on the screen; focus never lands on it.
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(
          _node(tester, id).getSemanticsData().flagsCollection.isFocused,
          Tristate.none,
        );
      }
      expect(_count(tester, 'bad-gesture-only'), 0);
      // It still works by touch, which is what hides the defect.
      await tester.tap(_id(id));
      await tester.pump();
      expect(_count(tester, 'bad-gesture-only'), 1);
      handle.dispose();
    });

    testWidgets('bad-role-in-name: the name ends with the role', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-role-in-name');
      final node = _node(tester, 'c01-bad-role-in-name-close');
      expect(node, isSemantics(isButton: true));
      expect(
        _label(tester, 'c01-bad-role-in-name-close').toLowerCase(),
        endsWith('button'),
      );
      handle.dispose();
    });

    testWidgets('bad-duplicate-names: the names are not unique', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-duplicate-names');
      final names = [
        for (final field in ['username', 'email', 'password'])
          _label(tester, 'c01-bad-duplicate-names-$field'),
      ];
      expect(names, ['Edit', 'Edit', 'Edit']);
      handle.dispose();
    });

    testWidgets('bad-name-mismatch: the name lacks the visible text', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-name-mismatch');
      expect(find.text('Edit'), findsOneWidget);
      final name = _label(tester, 'c01-bad-name-mismatch-edit');
      expect(name, 'Change username');
      expect(name.toLowerCase(), isNot(contains('edit')));
      handle.dispose();
    });

    testWidgets('bad-fake-disabled: looks disabled, reports enabled, acts', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-fake-disabled');
      const id = 'c01-bad-fake-disabled-submit';
      expect(
        _node(tester, id),
        isSemantics(isButton: true, isEnabled: true, hasTapAction: true),
      );
      await tester.tap(_id(id));
      await tester.pump();
      expect(_count(tester, 'bad-fake-disabled'), 1);
      handle.dispose();
    });

    testWidgets('bad-cupertino-disabled: ignores taps but has no disabled '
        'state (Flutter limitation)', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-cupertino-disabled');
      const id = 'c01-bad-cupertino-disabled-delete';
      final flags = _node(tester, id).getSemanticsData().flagsCollection;
      expect(flags.isButton, isTrue);
      // Tristate.none: no enabled state is reported at all. If a Flutter
      // upgrade changes this, the limitation is fixed and this example and
      // the workaround in good-cupertino should be revisited.
      expect(flags.isEnabled, Tristate.none);
      await tester.tap(_id(id), warnIfMissed: false);
      await tester.pump();
      expect(_count(tester, 'bad-cupertino-disabled'), 0);
      handle.dispose();
    });

    // FL-002. On web Enter arrives as ButtonActivateIntent. A widget test
    // cannot run as web, so this checks the action lookup that web relies on.
    testWidgets('FL-002: CupertinoButton has no action for the intent web '
        'sends for Enter; the good example adds one', (tester) async {
      Future<bool> handlesEnterOnWeb(String slug, String id) async {
        await tester.pumpWidget(const SizedBox());
        await _open(tester, slug);
        final button = tester.element(
          find.descendant(of: _id(id), matching: find.byType(CupertinoButton)),
        );
        // Look up from inside the button, where its focus node is.
        late BuildContext inside;
        button.visitChildElements((child) => inside = child);
        return Actions.maybeFind<ButtonActivateIntent>(inside) != null;
      }

      // If the plain button starts handling it, the limitation is fixed and
      // the wrapper in good-cupertino can go.
      expect(
        await handlesEnterOnWeb(
          'bad-cupertino-disabled',
          'c01-bad-cupertino-disabled-delete',
        ),
        isFalse,
      );
      expect(
        await handlesEnterOnWeb('good-cupertino', 'c01-good-cupertino-save'),
        isTrue,
      );
    });
  });
}
