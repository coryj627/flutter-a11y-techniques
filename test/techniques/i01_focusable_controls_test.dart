import 'dart:ui' show Tristate;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/i01_focusable_controls/i01_focusable_controls.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/examples.dart';

/// L1 for I01 Focusable and clickable controls
/// (docs/specs/I01-focusable-controls.md).
final _open = exampleOpener(i01FocusableControls);

int _count(WidgetTester tester, String slug) =>
    countOf(tester, 'i01-$slug-count');

String _id(String slug) => 'i01-$slug-trail';

const _good = ['good-material', 'good-cupertino', 'good-custom'];
const _bad = [
  'bad-inkwell-no-role',
  'bad-no-focus',
  'bad-no-key-action',
  'bad-tap-down',
];
const _all = [..._good, ..._bad];

/// The examples that Tab reaches and Enter and Space activate.
const _keyboard = [..._good, 'bad-inkwell-no-role', 'bad-tap-down'];

/// The examples that act when the pointer is released over them.
const _actOnRelease = [
  ..._good,
  'bad-inkwell-no-role',
  'bad-no-focus',
  'bad-no-key-action',
];

const _trail = 'Ridge trail';

Tristate _focused(String slug) => dataById(_id(slug)).flagsCollection.isFocused;

/// Whether the widget with keyboard focus is inside the Back button.
bool _focusOnBack() {
  final focus = FocusManager.instance.primaryFocus?.context;
  if (focus == null) return false;
  return find
      .ancestor(
        of: find.byElementPredicate((e) => e == focus),
        matching: find.byType(BackButton),
      )
      .evaluate()
      .isNotEmpty;
}

/// The control for a key that did nothing on the card: Tab on, round to
/// Back, and require [key] to act there, which leaves the example screen.
Future<void> _expectKeyActsOnBack(
  WidgetTester tester,
  String slug,
  LogicalKeyboardKey key,
) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pumpAndSettle();
  expect(_focusOnBack(), isTrue, reason: 'Tab from the card reaches Back');
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
  expect(byId('i01-$slug-count'), findsNothing, reason: '$key on Back');
}

/// Where on the screen the control of [slug] is.
Offset _centre(WidgetTester tester, String slug) =>
    tester.getCenter(byId(_id(slug)));

/// Presses the control of [slug], moves the pointer well off it, and lets go
/// there. Returns the count while it was held and after it was let go.
Future<(int, int)> _pressAndSlideOff(WidgetTester tester, String slug) async {
  final gesture = await tester.startGesture(_centre(tester, slug));
  await tester.pump(const Duration(milliseconds: 300));
  final held = _count(tester, slug);
  await gesture.moveBy(const Offset(0, 300));
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
  return (held, _count(tester, slug));
}

void main() {
  test('the technique has the examples named in the spec', () {
    expect(i01FocusableControls.examples.map((e) => e.slug), _all);
    expect(_good, [
      for (final e in i01FocusableControls.examples)
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

      testWidgets('$slug is a button named "$_trail" with a tap action', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        final data = dataById(_id(slug));
        expect(data.label, _trail);
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.hasAction(SemanticsAction.tap), isTrue);
        // Focusable, and not focused until the keyboard gets there.
        expect(data.flagsCollection.isFocused, Tristate.isFalse);
        // The name is on the control and on no other node.
        expect(
          semanticsNodes(tester).where((n) => n.label.contains(_trail)),
          hasLength(1),
        );
        handle.dispose();
      });
    }
  });

  group('every example', () {
    for (final slug in _all) {
      testWidgets('$slug: a tap activates it once', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await tester.tap(byId(_id(slug)));
        await tester.pumpAndSettle();
        expect(_count(tester, slug), 1);
        handle.dispose();
      });

      testWidgets('$slug: the semantics tap action, which screen readers '
          'and switch access use, activates it once', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        expect(dataById(_id(slug)).label, _trail);
        tester.semantics.tap(nodeById(_id(slug)));
        await tester.pumpAndSettle();
        expect(_count(tester, slug), 1);
        handle.dispose();
      });
    }
  });

  group('keyboard', () {
    for (final slug in _keyboard) {
      testWidgets('$slug: Tab reaches it, and Enter and Space each activate '
          'it once with focus staying on it', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        expect(_focused(slug), Tristate.isFalse);
        await tabTo(tester, _id(slug));
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(_count(tester, slug), 1);
        expect(_focused(slug), Tristate.isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(_count(tester, slug), 2);
        expect(_focused(slug), Tristate.isTrue);
        handle.dispose();
      });

      // On the web, WidgetsApp sends Enter as ButtonActivateIntent and not
      // ActivateIntent (FL-002). A widget test cannot run as the web, so
      // this checks the lookup that the web relies on; the web tests press
      // Enter.
      testWidgets('$slug: the focused control handles the intent the web '
          'sends for Enter', (tester) async {
        await _open(tester, slug);
        await tabTo(tester, _id(slug));
        final focused = FocusManager.instance.primaryFocus!.context!;
        expect(Actions.maybeFind<ButtonActivateIntent>(focused), isNotNull);
        expect(Actions.maybeFind<ActivateIntent>(focused), isNotNull);
      });
    }

    testWidgets('bad-no-focus: not focusable, and Tab never reaches it', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-no-focus');
      // Tristate.none: the node is not focusable at all.
      expect(_focused('bad-no-focus'), Tristate.none);
      expect(
        find.descendant(
          of: byId(_id('bad-no-focus')),
          matching: find.byType(Focus),
        ),
        findsNothing,
      );
      // The first Tab reaches Back, and the second, where a control that
      // can take focus would get it, goes round to Back again.
      for (var i = 0; i < 2; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(_focusOnBack(), isTrue, reason: 'Tab ${i + 1} is on Back');
      }
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(_focused('bad-no-focus'), Tristate.none);
        // Focus is never inside the card. Enter is not pressed: focus may
        // be on Back.
        final focus = FocusManager.instance.primaryFocus?.context;
        expect(
          focus == null ||
              find
                  .descendant(
                    of: byId(_id('bad-no-focus')),
                    matching: find.byElementPredicate((e) => e == focus),
                  )
                  .evaluate()
                  .isEmpty,
          isTrue,
        );
      }
      expect(_count(tester, 'bad-no-focus'), 0);
      handle.dispose();
    });

    testWidgets('bad-no-key-action: Tab reaches it; Enter does nothing', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-no-key-action');
      await tabTo(tester, _id('bad-no-key-action'));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(_count(tester, 'bad-no-key-action'), 0);
      expect(_focused('bad-no-key-action'), Tristate.isTrue);
      await _expectKeyActsOnBack(
        tester,
        'bad-no-key-action',
        LogicalKeyboardKey.enter,
      );
      handle.dispose();
    });

    testWidgets('bad-no-key-action: Tab reaches it; Space does nothing', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-no-key-action');
      await tabTo(tester, _id('bad-no-key-action'));
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(_count(tester, 'bad-no-key-action'), 0);
      expect(_focused('bad-no-key-action'), Tristate.isTrue);
      await _expectKeyActsOnBack(
        tester,
        'bad-no-key-action',
        LogicalKeyboardKey.space,
      );
      handle.dispose();
    });

    testWidgets('bad-no-key-action: neither intent is handled where focus is', (
      tester,
    ) async {
      await _open(tester, 'bad-no-key-action');
      await tabTo(tester, _id('bad-no-key-action'));
      final focused = FocusManager.instance.primaryFocus!.context!;
      expect(Actions.maybeFind<ActivateIntent>(focused), isNull);
      expect(Actions.maybeFind<ButtonActivateIntent>(focused), isNull);
    });
  });

  group('pointer', () {
    for (final slug in _actOnRelease) {
      testWidgets('$slug: nothing happens while it is pressed, or when the '
          'pointer leaves it before it is let go', (tester) async {
        await _open(tester, slug);
        final (held, after) = await _pressAndSlideOff(tester, slug);
        expect(held, 0);
        expect(after, 0);
      });

      testWidgets('$slug: it acts once when the pointer is let go over it', (
        tester,
      ) async {
        await _open(tester, slug);
        final gesture = await tester.startGesture(_centre(tester, slug));
        await tester.pump(const Duration(milliseconds: 300));
        expect(_count(tester, slug), 0);
        await gesture.up();
        await tester.pumpAndSettle();
        expect(_count(tester, slug), 1);
      });
    }

    testWidgets('bad-tap-down: it acts while it is pressed, and moving off '
        'before letting go does not take it back', (tester) async {
      await _open(tester, 'bad-tap-down');
      final (held, after) = await _pressAndSlideOff(tester, 'bad-tap-down');
      expect(held, 1);
      expect(after, 1);
    });
  });

  group('roles', () {
    testWidgets('bad-inkwell-no-role: focusable, with a tap action, and no '
        'button role', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-inkwell-no-role');
      final data = dataById(_id('bad-inkwell-no-role'));
      expect(data.label, _trail);
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(data.flagsCollection.isFocused, Tristate.isFalse);
      // Written to fail if InkWell starts to give itself a role.
      expect(data.flagsCollection.isButton, isFalse);
      expect(data.role, SemanticsRole.none);
      handle.dispose();
    });

    for (final slug in ['bad-no-focus', 'bad-no-key-action', 'bad-tap-down']) {
      testWidgets('$slug: a button named "$_trail": its defect is not in '
          'its role or name', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        final data = dataById(_id(slug));
        expect(data.label, _trail);
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.hasAction(SemanticsAction.tap), isTrue);
        handle.dispose();
      });
    }
  });

  group('the SDK widgets on their own', () {
    Future<void> pumpAlone(WidgetTester tester, Widget control) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextButton(onPressed: () {}, child: const Text('Before')),
                control,
                TextButton(onPressed: () {}, child: const Text('After')),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    // The missing button flag makes the tile not a button on Android and
    // iOS; on the web the engine makes it one from the tap action (FL-006).
    testWidgets('FL-400: a CupertinoListTile with onTap takes no keyboard '
        'focus and has no button flag', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await pumpAlone(
        tester,
        CupertinoListTile(title: const Text(_trail), onTap: () => taps++),
      );
      final tile = tester.getSemantics(find.byType(CupertinoListTile));
      final data = tile.getSemanticsData();
      expect(data.label, _trail);
      // A tap reaches it, and so does assistive technology.
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      // Written to fail when the tile takes focus or becomes a button.
      expect(data.flagsCollection.isFocused, Tristate.none);
      expect(data.flagsCollection.isButton, isFalse);
      expect(
        find.descendant(
          of: find.byType(CupertinoListTile),
          matching: find.byType(Focus),
        ),
        findsNothing,
      );
      // Tab goes from Before straight to After.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focused = FocusManager.instance.primaryFocus!.context!;
      expect(
        find.ancestor(
          of: find.byElementPredicate((e) => e == focused),
          matching: find.widgetWithText(TextButton, 'After'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byType(CupertinoListTile));
      await tester.pumpAndSettle();
      expect(taps, 1);
      handle.dispose();
    });
  });
}
