import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/app/app.dart';
import 'package:flutter_a11y_techniques/catalog/registry.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/s13_roles_and_traits/s13_roles_and_traits.dart';
import 'package:flutter_test/flutter_test.dart';

/// L1 for S13 Roles and traits (docs/specs/S13-roles-and-traits.md).
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
      registry: TechniqueRegistry([s13RolesAndTraits]),
      platform: AppPlatform.android,
      initialRoute: '/t/S13/$slug',
    ),
  );
  await tester.pumpAndSettle();
}

Finder _id(String id) => find.byKey(ValueKey<String>(id));

SemanticsData _data(WidgetTester tester, Finder finder) =>
    tester.getSemantics(finder).getSemanticsData();

int _count(WidgetTester tester, String slug) {
  final text = tester.widget<Text>(
    find.descendant(of: _id('s13-$slug-count'), matching: find.byType(Text)),
  );
  return int.parse(text.data!.split(': ').last);
}

bool _focused(WidgetTester tester, Finder finder) =>
    _data(tester, finder).flagsCollection.isFocused == Tristate.isTrue;

/// Tabs until [id] has focus. The Back button comes first.
Future<void> _tabTo(WidgetTester tester, String id) async {
  var reached = false;
  for (var i = 0; i < 8 && !reached; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    reached = _focused(tester, _id(id));
  }
  expect(reached, isTrue, reason: 'Tab did not reach $id');
}

/// Every node on the screen that has the button flag. A node merged into
/// its parent is not counted: the parent stands for both.
List<SemanticsNode> _buttonNodes(WidgetTester tester) {
  final found = <SemanticsNode>[];
  void visit(SemanticsNode node) {
    if (!node.isMergedIntoParent &&
        node.getSemanticsData().flagsCollection.isButton) {
      found.add(node);
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

/// The semantics node that has [id] as its identifier.
FinderBase<SemanticsNode> _node(String id) =>
    find.semantics.byPredicate((node) => node.identifier == id);

enum _Role { button, toggle, checkbox }

/// The controls of the good examples: identifier, name, and role.
const _good = <String, Map<String, (String, _Role)>>{
  'good-standard': {
    's13-good-standard-save': ('Save', _Role.button),
    's13-good-standard-wifi': ('Wi-Fi', _Role.toggle),
    's13-good-standard-remember': ('Remember me', _Role.checkbox),
  },
  'good-cupertino': {
    's13-good-cupertino-save': ('Save', _Role.button),
    's13-good-cupertino-wifi': ('Wi-Fi', _Role.toggle),
  },
  'good-custom-button': {
    's13-good-custom-button-scan': ('Scan barcode', _Role.button),
  },
  'good-custom-switch': {
    's13-good-custom-switch-dark': ('Dark mode', _Role.toggle),
  },
  'good-selected': {
    's13-good-selected-day': ('Day', _Role.button),
    's13-good-selected-week': ('Week', _Role.button),
    's13-good-selected-month': ('Month', _Role.button),
  },
};

/// Checks that [data] has [role] and none of the other two roles' flags.
void _expectRole(SemanticsData data, _Role role, String id) {
  final flags = data.flagsCollection;
  switch (role) {
    case _Role.button:
      expect(flags.isButton, isTrue, reason: '$id button');
      expect(flags.isToggled, Tristate.none, reason: '$id toggled');
      expect(flags.isChecked, CheckedState.none, reason: '$id checked');
    case _Role.toggle:
      expect(flags.isToggled, isNot(Tristate.none), reason: '$id toggled');
      expect(flags.isChecked, CheckedState.none, reason: '$id checked');
    case _Role.checkbox:
      expect(flags.isChecked, isNot(CheckedState.none), reason: '$id checked');
      expect(flags.isToggled, Tristate.none, reason: '$id toggled');
  }
  if (role == _Role.button) {
    // A CupertinoButton has no enabled state at all (FL-001).
    expect(flags.isEnabled, isNot(Tristate.isFalse), reason: '$id enabled');
  } else {
    // Without it VoiceOver on iOS reads the control as dimmed (FL-033).
    expect(flags.isEnabled, Tristate.isTrue, reason: '$id enabled');
  }
  expect(data.hasAction(SemanticsAction.tap), isTrue, reason: '$id tap');
}

void main() {
  test('the technique has the examples named in the spec', () {
    expect(s13RolesAndTraits.examples.map((e) => e.slug), [
      ..._good.keys,
      'bad-no-role',
      'bad-wrong-role',
      'bad-role-on-text',
      'bad-role-on-standard',
      'bad-action-hidden',
      'bad-switch-not-enabled',
    ]);
    expect(_good.keys, [
      for (final e in s13RolesAndTraits.examples)
        if (e.kind == ExampleKind.good) e.slug,
    ]);
  });

  group('good examples', () {
    for (final MapEntry(key: slug, value: controls) in _good.entries) {
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

      testWidgets('$slug: each control has its name, role, and tap action', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        var expected = 0;
        for (final MapEntry(key: id, value: (name, role)) in controls.entries) {
          final data = _data(tester, _id(id));
          expect(data.label, name, reason: id);
          expect(data.identifier, id);
          _expectRole(data, role, id);
          await tester.tap(_id(id));
          await tester.pump();
          expect(_count(tester, slug), ++expected, reason: 'tap $id');
        }
        // One node for each control: no role is on a second node.
        expect(
          _buttonNodes(tester)
              .where((n) => n.getSemanticsData().label != 'Back'),
          hasLength(controls.values.where((c) => c.$2 == _Role.button).length),
        );
        handle.dispose();
      });

      testWidgets('$slug: Tab reaches each control; Enter and Space operate '
          'it', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        var expected = 0;
        for (final id in controls.keys) {
          await _tabTo(tester, id);
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

    testWidgets('good-standard and good-cupertino: the state follows the '
        'control', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-standard');
      const wifi = 's13-good-standard-wifi';
      const remember = 's13-good-standard-remember';
      expect(
        _data(tester, _id(wifi)).flagsCollection.isToggled,
        Tristate.isFalse,
      );
      expect(
        _data(tester, _id(remember)).flagsCollection.isChecked,
        CheckedState.isFalse,
      );
      await tester.tap(_id(wifi));
      await tester.tap(_id(remember));
      await tester.pump();
      expect(
        _data(tester, _id(wifi)).flagsCollection.isToggled,
        Tristate.isTrue,
      );
      expect(
        _data(tester, _id(remember)).flagsCollection.isChecked,
        CheckedState.isTrue,
      );
      handle.dispose();
    });

    testWidgets('good-custom-switch: toggled follows the switch', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-custom-switch');
      const id = 's13-good-custom-switch-dark';
      expect(
        _data(tester, _id(id)).flagsCollection.isToggled,
        Tristate.isFalse,
      );
      // Not a button as well: a switch is one role.
      expect(_data(tester, _id(id)).flagsCollection.isButton, isFalse);
      await tester.tap(_id(id));
      await tester.pump();
      expect(_data(tester, _id(id)).flagsCollection.isToggled, Tristate.isTrue);
      // The semantics tap action does the same as a touch.
      tester.semantics.tap(_node(id));
      await tester.pump();
      expect(
        _data(tester, _id(id)).flagsCollection.isToggled,
        Tristate.isFalse,
      );
      handle.dispose();
    });

    for (final (slug, id) in [
      ('good-custom-switch', 's13-good-custom-switch-dark'),
      ('bad-wrong-role', 's13-bad-wrong-role-dark'),
      ('bad-switch-not-enabled', 's13-bad-switch-not-enabled-dark'),
    ]) {
      testWidgets('$slug: a tap anywhere on the switch operates it once', (
        tester,
      ) async {
        await _open(tester, slug);
        final detector = find.descendant(
          of: _id(id),
          matching: find.byType(GestureDetector),
        );
        final rect = tester.getRect(detector);
        expect(rect.height, greaterThanOrEqualTo(48));
        // The padding at each corner, and the gap between text and track.
        final track = tester.getRect(
          find.descendant(of: detector, matching: find.byIcon(Icons.close)),
        );
        final points = [
          rect.topLeft + const Offset(2, 2),
          rect.bottomRight - const Offset(2, 2),
          Offset(track.left - 20, rect.center.dy),
        ];
        var expected = 0;
        for (final point in points) {
          await tester.tapAt(point);
          await tester.pump();
          expect(_count(tester, slug), ++expected, reason: 'tap at $point');
        }
      });
    }

    testWidgets('good-custom-button: the semantics tap action activates it', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-custom-button');
      tester.semantics.tap(_node('s13-good-custom-button-scan'));
      await tester.pump();
      expect(_count(tester, 'good-custom-button'), 1);
      handle.dispose();
    });

    testWidgets('good-selected: one button is selected, and it follows the '
        'choice', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-selected');
      Map<String, Tristate> selected() => {
        for (final view in ['day', 'week', 'month'])
          view: _data(
            tester,
            _id('s13-good-selected-$view'),
          ).flagsCollection.isSelected,
      };
      expect(selected(), {
        'day': Tristate.isFalse,
        'week': Tristate.isTrue,
        'month': Tristate.isFalse,
      });
      await tester.tap(_id('s13-good-selected-month'));
      await tester.pump();
      expect(selected(), {
        'day': Tristate.isFalse,
        'week': Tristate.isFalse,
        'month': Tristate.isTrue,
      });
      handle.dispose();
    });
  });

  group('bad examples have their defect', () {
    testWidgets('bad-no-role: works by tap, key, and semantics action, and '
        'has no role', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-no-role');
      const id = 's13-bad-no-role-scan';
      final data = _data(tester, _id(id));
      expect(data.label, 'Scan barcode');
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(data.flagsCollection.isButton, isFalse);
      expect(data.flagsCollection.isLink, isFalse);
      expect(data.flagsCollection.isToggled, Tristate.none);
      expect(data.flagsCollection.isChecked, CheckedState.none);
      // Everything else works, so the missing role is the only defect.
      await tester.tap(_id(id));
      await tester.pump();
      expect(_count(tester, 'bad-no-role'), 1);
      tester.semantics.tap(_node(id));
      await tester.pump();
      expect(_count(tester, 'bad-no-role'), 2);
      await _tabTo(tester, id);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(_count(tester, 'bad-no-role'), 3);
      handle.dispose();
    });

    testWidgets('bad-wrong-role: a button with no state, before and after '
        'it is switched on', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-wrong-role');
      const id = 's13-bad-wrong-role-dark';
      for (var presses = 0; presses < 2; presses++) {
        final data = _data(tester, _id(id));
        expect(data.label, 'Dark mode');
        expect(data.value, isEmpty);
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.flagsCollection.isToggled, Tristate.none);
        expect(data.flagsCollection.isChecked, CheckedState.none);
        expect(data.flagsCollection.isSelected, Tristate.none);
        await tester.tap(_id(id));
        await tester.pump();
      }
      // It did switch: only the semantics do not say so.
      expect(_count(tester, 'bad-wrong-role'), 2);
      handle.dispose();
    });

    testWidgets('bad-role-on-text: a button with no action and no focus', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-role-on-text');
      const id = 's13-bad-role-on-text-delivery';
      SemanticsData data() => _data(tester, _id(id));
      expect(data().label, 'Free delivery');
      expect(data().flagsCollection.isButton, isTrue);
      expect(data().hasAction(SemanticsAction.tap), isFalse);
      await tester.tap(_id(id));
      await tester.pump();
      expect(_count(tester, 'bad-role-on-text'), 0);
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(
          data().flagsCollection.isFocused,
          isNot(Tristate.isTrue),
          reason: 'after Tab ${i + 1}',
        );
      }
      handle.dispose();
    });

    testWidgets('bad-role-on-standard: an unnamed button around the real '
        'one', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-role-on-standard');
      final buttons = _buttonNodes(tester)
          .where((n) => n.getSemanticsData().label != 'Back')
          .toList();
      expect(buttons, hasLength(2));
      final outer = buttons.first;
      final inner = buttons.last;
      expect(inner.parent!.id, outer.id);
      expect(outer.getSemanticsData().label, isEmpty);
      expect(outer.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      expect(inner.getSemanticsData().label, 'Save');
      expect(inner.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      await tester.tap(_id('s13-bad-role-on-standard-save'));
      await tester.pump();
      expect(_count(tester, 'bad-role-on-standard'), 1);
      handle.dispose();
    });

    testWidgets('bad-action-hidden: a button with no tap action that still '
        'works by touch and key', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-action-hidden');
      const id = 's13-bad-action-hidden-scan';
      final data = _data(tester, _id(id));
      expect(data.label, 'Scan barcode');
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isEnabled, Tristate.isTrue);
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      await tester.tap(_id(id));
      await tester.pump();
      expect(_count(tester, 'bad-action-hidden'), 1);
      await _tabTo(tester, id);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(_count(tester, 'bad-action-hidden'), 2);
      handle.dispose();
    });

    testWidgets('bad-switch-not-enabled: a working switch that does not say '
        'it is enabled', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-switch-not-enabled');
      const id = 's13-bad-switch-not-enabled-dark';
      expect(_data(tester, _id(id)).label, 'Dark mode');
      expect(
        _data(tester, _id(id)).flagsCollection.isToggled,
        Tristate.isFalse,
      );
      // Neither enabled nor disabled: the flag is absent.
      expect(_data(tester, _id(id)).flagsCollection.isEnabled, Tristate.none);
      expect(_data(tester, _id(id)).hasAction(SemanticsAction.tap), isTrue);
      await tester.tap(_id(id));
      await tester.pump();
      expect(_data(tester, _id(id)).flagsCollection.isToggled, Tristate.isTrue);
      handle.dispose();
    });
  });
}
