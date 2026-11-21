import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/c02_toggle_button/c02_toggle_button.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/examples.dart';

/// L1 for C02 Toggle button (docs/specs/C02-toggle-button.md).
final _open = exampleOpener(c02ToggleButton);

int _count(WidgetTester tester, String slug) =>
    countOf(tester, 'c02-$slug-count');

const _good = [
  'good-icon-button',
  'good-toggle-buttons',
  'good-cupertino',
  'good-custom',
];

/// How a good example exposes its state.
enum _Kind { toggled, checked }

/// Toggles that start off and keep their name: slug, identifier, name, and
/// the state they carry.
const _toggles = [
  ('good-icon-button', 'c02-good-icon-button-bold', 'Bold', _Kind.toggled),
  (
    'good-toggle-buttons',
    'c02-good-toggle-buttons-bold',
    'Bold',
    _Kind.checked,
  ),
  (
    'good-toggle-buttons',
    'c02-good-toggle-buttons-italic',
    'Italic',
    _Kind.checked,
  ),
  (
    'good-toggle-buttons',
    'c02-good-toggle-buttons-underline',
    'Underline',
    _Kind.checked,
  ),
  ('good-cupertino', 'c02-good-cupertino-mute', 'Mute', _Kind.toggled),
  ('good-custom', 'c02-good-custom-mute', 'Mute', _Kind.toggled),
];

/// The name of a node: an `IconButton`'s is in its tooltip.
String _name(SemanticsData data) =>
    data.label.isNotEmpty ? data.label : data.tooltip;

/// Whether the node with [id] is on, by the state its kind carries.
bool _isOn(String id, _Kind kind) {
  final flags = dataById(id).flagsCollection;
  return switch (kind) {
    _Kind.toggled => flags.isToggled == Tristate.isTrue,
    _Kind.checked => flags.isChecked == CheckedState.isTrue,
  };
}

/// Expects [data] to be a toggle of [kind] in [on], enabled, a button, with
/// a tap action, and with no state of the other kind.
void _expectToggle(SemanticsData data, _Kind kind, {required bool on}) {
  final flags = data.flagsCollection;
  switch (kind) {
    case _Kind.toggled:
      expect(flags.isToggled, on ? Tristate.isTrue : Tristate.isFalse);
      expect(flags.isChecked, CheckedState.none);
    case _Kind.checked:
      expect(flags.isChecked, on ? CheckedState.isTrue : CheckedState.isFalse);
      expect(flags.isToggled, Tristate.none);
  }
  expect(flags.isButton, isTrue);
  expect(flags.isInMutuallyExclusiveGroup, isFalse);
  expect(flags.isEnabled, Tristate.isTrue);
  expect(data.hasAction(SemanticsAction.tap), isTrue);
}

void main() {
  test('the technique has the examples named in the spec', () {
    expect(c02ToggleButton.examples.map((e) => e.slug), [
      ..._good,
      'bad-selected-only',
      'bad-no-state',
      'bad-label-changes',
    ]);
    expect(_good, [
      for (final e in c02ToggleButton.examples)
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

  group('toggles', () {
    for (final (slug, id, name, kind) in _toggles) {
      testWidgets('$id: one node named "$name", a button with a ${kind.name} '
          'state that is off, and a tap action', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        final data = dataById(id);
        expect(_name(data), name);
        expect(data.value, isEmpty);
        _expectToggle(data, kind, on: false);
        // The name is on the control and on no other node.
        expect(
          semanticsNodes(tester).where((n) => _name(n) == name),
          hasLength(1),
        );
        handle.dispose();
      });

      testWidgets('$id: a tap, the semantics action, Space, and Enter each '
          'change the state, and the name stays', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await tester.tap(byId(id));
        await tester.pumpAndSettle();
        expect(_isOn(id, kind), isTrue);
        _expectToggle(dataById(id), kind, on: true);
        expect(_name(dataById(id)), name);
        tester.semantics.tap(nodeById(id));
        await tester.pumpAndSettle();
        expect(_isOn(id, kind), isFalse);
        await tabTo(tester, id);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(_isOn(id, kind), isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(_isOn(id, kind), isFalse);
        expect(_count(tester, slug), 4);
        expect(_name(dataById(id)), name);
        handle.dispose();
      });
    }

    for (final slug in ['good-icon-button', 'bad-label-changes']) {
      testWidgets('$slug: no selected state beside the toggled one, on or '
          'off, and the pressed look is drawn', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        final id = slug == 'good-icon-button'
            ? 'c02-good-icon-button-bold'
            : 'c02-bad-label-changes-mute';
        Color? fill() => tester
            .widget<IconButton>(
              find.descendant(of: byId(id), matching: find.byType(IconButton)),
            )
            .style
            ?.backgroundColor
            ?.resolve({});
        for (final on in [false, true]) {
          expect(dataById(id).flagsCollection.isSelected, Tristate.none);
          expect(_isOn(id, _Kind.toggled), on);
          final colors = Theme.of(tester.element(byId(id))).colorScheme;
          expect(fill(), on ? colors.primary : isNull);
          if (!on) {
            await tester.tap(byId(id));
            await tester.pumpAndSettle();
          }
        }
        handle.dispose();
      });
    }

    testWidgets('good-toggle-buttons: each button changes only itself', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-toggle-buttons');
      const italic = 'c02-good-toggle-buttons-italic';
      await tester.tap(byId(italic));
      await tester.pumpAndSettle();
      expect(_isOn(italic, _Kind.checked), isTrue);
      expect(_isOn('c02-good-toggle-buttons-bold', _Kind.checked), isFalse);
      expect(
        _isOn('c02-good-toggle-buttons-underline', _Kind.checked),
        isFalse,
      );
      expect(_count(tester, 'good-toggle-buttons'), 1);
      handle.dispose();
    });
  });

  group('bad examples have their defect', () {
    testWidgets('bad-selected-only: a button whose only state is selected, '
        'false when off', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-selected-only');
      const id = 'c02-bad-selected-only-bold';
      for (final on in [false, true, false]) {
        final data = dataById(id);
        expect(_name(data), 'Bold');
        expect(data.flagsCollection.isButton, isTrue);
        expect(
          data.flagsCollection.isSelected,
          on ? Tristate.isTrue : Tristate.isFalse,
        );
        // Written to fail when isSelected gives a toggled or checked state.
        expect(data.flagsCollection.isToggled, Tristate.none);
        expect(data.flagsCollection.isChecked, CheckedState.none);
        expect(data.value, isEmpty);
        await tester.tap(byId(id));
        await tester.pumpAndSettle();
      }
      expect(_count(tester, 'bad-selected-only'), 3);
      handle.dispose();
    });

    testWidgets('bad-no-state: a button with no state, before and after it '
        'is used', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-no-state');
      const id = 'c02-bad-no-state-mute';
      for (var taps = 0; taps < 3; taps++) {
        final data = dataById(id);
        expect(data.label, 'Mute');
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.flagsCollection.isToggled, Tristate.none);
        expect(data.flagsCollection.isChecked, CheckedState.none);
        expect(data.flagsCollection.isSelected, Tristate.none);
        expect(data.value, isEmpty);
        expect(_count(tester, 'bad-no-state'), taps);
        await tester.tap(byId(id));
        await tester.pumpAndSettle();
      }
      // The drawing changed with each tap; the semantics did not.
      expect(find.byIcon(Icons.volume_off), findsOneWidget);
      handle.dispose();
    });

    testWidgets('bad-label-changes: the name changes with the state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-label-changes');
      const id = 'c02-bad-label-changes-mute';
      expect(_name(dataById(id)), 'Mute');
      _expectToggle(dataById(id), _Kind.toggled, on: false);
      await tester.tap(byId(id));
      await tester.pumpAndSettle();
      expect(_name(dataById(id)), 'Unmute');
      _expectToggle(dataById(id), _Kind.toggled, on: true);
      await tester.tap(byId(id));
      await tester.pumpAndSettle();
      expect(_name(dataById(id)), 'Mute');
      expect(_count(tester, 'bad-label-changes'), 2);
      handle.dispose();
    });
  });
}
