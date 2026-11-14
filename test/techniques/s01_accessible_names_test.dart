import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/app/app.dart';
import 'package:flutter_a11y_techniques/catalog/registry.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/s01_accessible_names/s01_accessible_names.dart';
import 'package:flutter_test/flutter_test.dart';

/// L1 for S01 Accessible names (docs/specs/S01-accessible-names.md).
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
      registry: TechniqueRegistry([s01AccessibleNames]),
      platform: AppPlatform.android,
      initialRoute: '/t/S01/$slug',
    ),
  );
  await tester.pumpAndSettle();
}

Finder _id(String id) => find.byKey(ValueKey<String>(id));

SemanticsData _data(WidgetTester tester, String id) =>
    tester.getSemantics(_id(id)).getSemanticsData();

/// Whether the control is on: checked for a checkbox, toggled for a switch.
bool _isOn(WidgetTester tester, String id) {
  final flags = _data(tester, id).flagsCollection;
  return flags.isChecked == CheckedState.isTrue ||
      flags.isToggled == Tristate.isTrue;
}

enum _Kind { checkbox, toggle }

/// The controls of every example that are named, with their expected names.
const _named = {
  'good-visible-label': {
    's01-good-visible-label-updates': (
      'Email me order updates',
      _Kind.checkbox,
    ),
    's01-good-visible-label-dark': ('Dark mode', _Kind.toggle),
  },
  'good-merged-label': {
    's01-good-merged-label-remember': ('Remember this device', _Kind.checkbox),
    's01-good-merged-label-wifi': ('Wi-Fi', _Kind.toggle),
  },
  'good-specific-names': {
    's01-good-specific-names-email': ('Order updates, email', _Kind.toggle),
    's01-good-specific-names-sms': (
      'Order updates, text message',
      _Kind.toggle,
    ),
  },
  'good-cupertino': {
    's01-good-cupertino-airplane': ('Airplane mode', _Kind.toggle),
  },
};

void main() {
  final goodSlugs = [
    for (final e in s01AccessibleNames.examples)
      if (e.kind == ExampleKind.good) e.slug,
  ];

  test('the technique has the examples named in the spec', () {
    expect(s01AccessibleNames.examples.map((e) => e.slug), [
      'good-visible-label',
      'good-merged-label',
      'good-specific-names',
      'good-cupertino',
      'bad-unassociated-label',
      'bad-duplicate-names',
      'bad-role-in-name',
      'bad-slider-name-web',
    ]);
    expect(goodSlugs, _named.keys);
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

    for (final MapEntry(key: slug, value: controls) in _named.entries) {
      testWidgets('$slug: one named control per id, and it works', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        for (final MapEntry(key: id, value: (name, kind)) in controls.entries) {
          final data = _data(tester, id);
          expect(data.label, name, reason: id);
          expect(data.identifier, id);
          expect(data.hasAction(SemanticsAction.tap), isTrue, reason: id);
          final flags = data.flagsCollection;
          switch (kind) {
            case _Kind.checkbox:
              expect(flags.isChecked, CheckedState.isFalse, reason: id);
            case _Kind.toggle:
              expect(flags.isToggled, Tristate.isFalse, reason: id);
          }
          // The visible text is part of the control, not a second element.
          expect(find.bySemanticsLabel(name), findsOneWidget, reason: id);
          await tester.tap(_id(id));
          await tester.pump();
          expect(_isOn(tester, id), isTrue, reason: 'tap $id');
        }
        handle.dispose();
      });

      testWidgets('$slug: Tab reaches each control and Space operates it', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        for (final id in controls.keys) {
          // Tab until this control has focus. The Back button comes first.
          var reached = false;
          for (var i = 0; i < 6 && !reached; i++) {
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.pump();
            reached =
                _data(tester, id).flagsCollection.isFocused == Tristate.isTrue;
          }
          expect(reached, isTrue, reason: 'Tab did not reach $id');
          await tester.sendKeyEvent(LogicalKeyboardKey.space);
          await tester.pump();
          expect(_isOn(tester, id), isTrue, reason: 'Space on $id');
        }
        handle.dispose();
      });
    }

    testWidgets('good-specific-names: each name starts with the visible '
        'text and the names differ', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-specific-names');
      final names = [
        for (final id in _named['good-specific-names']!.keys)
          _data(tester, id).label,
      ];
      expect(find.text('Order updates'), findsNWidgets(2));
      for (final name in names) {
        expect(name, startsWith('Order updates'));
      }
      expect(names.toSet(), hasLength(2));
      handle.dispose();
    });
  });

  group('bad examples', () {
    testWidgets('bad-unassociated-label: a checkbox with no name', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-unassociated-label');
      const id = 's01-bad-unassociated-label-terms';
      final data = _data(tester, id);
      expect(data.flagsCollection.isChecked, CheckedState.isFalse);
      expect(data.label, isEmpty);
      expect(data.tooltip, isEmpty);
      // The text is there, as an element of its own.
      final text = tester.getSemantics(find.text('I accept the terms'));
      expect(text.id, isNot(tester.getSemantics(_id(id)).id));
      await expectLater(
        tester,
        doesNotMeetGuideline(labeledTapTargetGuideline),
      );
      // The control still works; only the name is missing.
      await tester.tap(_id(id));
      await tester.pump();
      expect(_isOn(tester, id), isTrue);
      handle.dispose();
    });

    testWidgets('bad-duplicate-names: the names are not unique', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-duplicate-names');
      final names = [
        _data(tester, 's01-bad-duplicate-names-email').label,
        _data(tester, 's01-bad-duplicate-names-sms').label,
      ];
      expect(names, ['Order updates', 'Order updates']);
      handle.dispose();
    });

    testWidgets('bad-role-in-name: the name ends with the role', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-role-in-name');
      final data = _data(tester, 's01-bad-role-in-name-dark');
      expect(data.label, 'Dark mode switch');
      expect(data.flagsCollection.isToggled, Tristate.isFalse);
      handle.dispose();
    });

    testWidgets('bad-slider-name-web: the framework gives the slider its '
        'name; the defect is in the web engine (FL-028)', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-slider-name-web');
      final data = _data(tester, 's01-bad-slider-name-web-volume');
      expect(data.label, 'Volume');
      expect(data.value, '40%');
      expect(data.hasAction(SemanticsAction.increase), isTrue);
      expect(data.hasAction(SemanticsAction.decrease), isTrue);
      handle.dispose();
    });
  });

  test('the technique screen lists web as applying with a note', () {
    final web = s01AccessibleNames.statusFor(AppPlatform.web);
    expect(web.applicability, Applicability.applies);
    expect(web.note, contains('FL-028'));
  });
}
