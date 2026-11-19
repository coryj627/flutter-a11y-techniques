import 'dart:ui'
    show Tristate, ViewFocusDirection, ViewFocusEvent, ViewFocusState;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/i08_dismiss_and_escape/i08_dismiss_and_escape.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/examples.dart';

/// L1 for I08 Dismiss and escape (docs/specs/I08-dismiss-and-escape.md).
///
/// Every stop is named, never counted: after each key the test finds the
/// node whose semantics say it has keyboard focus and names it by its
/// identifier, or, when no control has focus, names the scope that has it.
/// Every check that a key or command did nothing presses that key alone,
/// checks that the layers are still there and focus has not moved after a
/// second, and then shows in the same test that keys arrive and act.
///
/// What Android's Back and VoiceOver's escape gesture do is stood in for
/// by `handlePopRoute`, the message both engines send when nothing in the
/// semantics tree takes the gesture (read in the source: the Android
/// embedding's back handling, and `accessibilityPerformEscape` in the iOS
/// engine's `FlutterViewController.mm`); a screen reader's dismiss action
/// on a node by `SemanticsAction.dismiss`.
final _open = exampleOpener(i08DismissAndEscape);

const _good = ['good-material', 'good-cupertino', 'good-widgets'];
const _bad = ['bad-not-dismissible', 'bad-no-escape', 'bad-back-leaves'];
const _all = [..._good, ..._bad];

/// The examples whose layers are a route of their own.
const _routes = ['good-material', 'good-cupertino', 'bad-not-dismissible'];

/// The examples whose layers are drawn in the overlay, with no route.
const _overlays = ['good-widgets', 'bad-no-escape', 'bad-back-leaves'];

/// The examples whose layers close on Escape.
const _escapeCloses = [..._good, 'bad-back-leaves'];

/// Escape is checked as Android and as iOS: on the iOS simulator Escape
/// from XCUITest never reached Flutter (docs/evidence/probes/i08/
/// README.md), so this is the only check of it for iOS. The app's default
/// shortcuts map Escape to `DismissIntent` on every platform (read in the
/// source: widgets/app.dart).
final _platforms = TargetPlatformVariant({
  TargetPlatform.android,
  TargetPlatform.iOS,
});

String _id(String slug, String part) => 'i08-$slug-$part';

/// The number in "Closed: n", the times the layers have been closed.
int _closed(WidgetTester tester, String slug) =>
    countOf(tester, _id(slug, 'count'));

/// Whether the layers are shown: both switches are on the screen.
bool _shown(String slug) =>
    byId(_id(slug, 'contours')).evaluate().isNotEmpty &&
    byId(_id(slug, 'campsites')).evaluate().isNotEmpty;

/// Where keyboard focus is: 'back', a part of the example ('open',
/// 'contours', 'campsites'), 'layers' when it is on the layers' own scope
/// and on no control there, 'screen' when it is on the example's screen
/// and on no control, or 'none'.
String _stop(WidgetTester tester, String slug) {
  final focused = semanticsNodes(tester)
      .where((d) => d.flagsCollection.isFocused == Tristate.isTrue)
      .toList();
  expect(focused.length, lessThanOrEqualTo(1), reason: 'two nodes have focus');
  if (focused.isNotEmpty) {
    final node = focused.single;
    if (node.tooltip == 'Back') return 'back';
    for (final part in ['open', 'contours', 'campsites']) {
      if (node.identifier == _id(slug, part)) return part;
    }
    return 'other: ${node.identifier} ${node.label}';
  }
  final primary = FocusManager.instance.primaryFocus;
  if (primary == null) return 'none';
  if (primary is FocusScopeNode && primary.debugLabel == 'Map layers') {
    return 'layers';
  }
  final context = primary.context;
  if (context == null) return 'none';
  final route = ModalRoute.of(context);
  if (route is PopupRoute) return 'layers';
  if (route is PageRoute) return 'screen';
  return 'none';
}

/// Presses [key] (with Shift when [shift]) and returns whether anything
/// in the app handled it.
Future<bool> _key(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool shift = false,
}) async {
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  final handled = await tester.sendKeyEvent(key);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.pumpAndSettle();
  return handled;
}

/// Presses Tab [n] times and names the stop after each.
Future<List<String>> _tabs(
  WidgetTester tester,
  String slug,
  int n, {
  bool shift = false,
}) async {
  final stops = <String>[];
  for (var i = 0; i < n; i++) {
    await _key(tester, LogicalKeyboardKey.tab, shift: shift);
    stops.add(_stop(tester, slug));
  }
  return stops;
}

/// Opens the example, tabs to "Map layers" (Back first), and presses Enter,
/// then Tab until the first switch has focus: the route examples put focus
/// on the route's own scope, the overlay ones on the first switch.
Future<void> _showByKeyboard(WidgetTester tester, String slug) async {
  await _open(tester, slug);
  expect(await _tabs(tester, slug, 2), ['back', 'open']);
  await _key(tester, LogicalKeyboardKey.enter);
  expect(_shown(slug), isTrue, reason: 'Enter on Map layers shows them');
  if (_routes.contains(slug)) {
    expect(_stop(tester, slug), 'layers');
    expect(await _tabs(tester, slug, 1), ['contours']);
  } else {
    expect(_stop(tester, slug), 'contours');
  }
}

/// Expects the layers to be closed and the screen to be the example's:
/// the count says [closed], and keyboard focus is back on "Map layers".
void _expectClosed(WidgetTester tester, String slug, int closed) {
  expect(_shown(slug), isFalse, reason: 'the layers are still shown');
  expect(byId(_id(slug, 'count')), findsOneWidget, reason: 'the screen left');
  expect(_closed(tester, slug), closed);
  expect(_stop(tester, slug), 'open');
}

/// Expects the layers to be still shown after a second, with keyboard focus
/// still on [stop] and nothing closed.
Future<void> _expectStillShown(
  WidgetTester tester,
  String slug,
  String stop,
) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  expect(_shown(slug), isTrue, reason: 'the layers closed');
  expect(_closed(tester, slug), 0);
  expect(_stop(tester, slug), stop);
}

/// Every semantics node that has the dismiss action, by label ('' for none).
List<SemanticsNode> _dismissable(WidgetTester tester) {
  final out = <SemanticsNode>[];
  void visit(SemanticsNode n) {
    if (n.getSemanticsData().hasAction(SemanticsAction.dismiss)) out.add(n);
    n.visitChildren((c) {
      visit(c);
      return true;
    });
  }

  visit(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return out;
}

/// Whether [node] or one of its ancestors has the dismiss action: where
/// VoiceOver's escape gesture on it is taken (read in the source:
/// `accessibilityPerformEscape` in the iOS engine's `SemanticsObject.mm`,
/// which UIKit asks of the element and then of each container above it).
bool _escapeTakenAt(SemanticsNode node) {
  for (SemanticsNode? n = node; n != null; n = n.parent) {
    if (n.getSemanticsData().hasAction(SemanticsAction.dismiss)) return true;
  }
  return false;
}

/// Performs the dismiss action on [node], as TalkBack's Dismiss action and
/// VoiceOver's escape gesture do.
void _dismiss(WidgetTester tester, SemanticsNode node) => tester
    .binding
    .renderViews
    .first
    .owner!
    .semanticsOwner!
    .performAction(node.id, SemanticsAction.dismiss);

void main() {
  test('the technique has the examples named in the spec', () {
    expect(i08DismissAndEscape.examples.map((e) => e.slug), _all);
    expect(_good, [
      for (final e in i08DismissAndEscape.examples)
        if (e.kind == ExampleKind.good) e.slug,
    ]);
  });

  group('good examples', () {
    for (final slug in _good) {
      for (final brightness in Brightness.values) {
        testWidgets('$slug meets the guidelines (${brightness.name}), with '
            'and without the layers shown', (tester) async {
          final handle = tester.ensureSemantics();
          await _open(tester, slug, brightness: brightness);
          Future<void> check() async {
            await expectLater(
              tester,
              meetsGuideline(androidTapTargetGuideline),
            );
            await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
            await expectLater(
              tester,
              meetsGuideline(labeledTapTargetGuideline),
            );
            await expectLater(tester, meetsGuideline(textContrastGuideline));
          }

          await check();
          await tester.tap(byId(_id(slug, 'open')));
          await tester.pumpAndSettle();
          expect(_shown(slug), isTrue);
          await check();
          handle.dispose();
        });
      }

      testWidgets('$slug does not overflow at 200% text on a phone, with '
          'the layers shown', (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await _open(tester, slug, textScale: 2);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(byId(_id(slug, 'open')));
        await tester.pumpAndSettle();
        await tester.tap(byId(_id(slug, 'open')));
        await tester.pumpAndSettle();
        expect(_shown(slug), isTrue);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('every example', () {
    for (final slug in _all) {
      testWidgets('$slug: a Map layers button, the count, and two named '
          'switches', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        final open = dataById(_id(slug, 'open'));
        expect(open.label, 'Map layers');
        expect(open.flagsCollection.isButton, isTrue);
        expect(_closed(tester, slug), 0);
        expect(find.text('Showing: Contour lines'), findsOneWidget);
        expect(_shown(slug), isFalse);
        await tester.tap(byId(_id(slug, 'open')));
        await tester.pumpAndSettle();
        for (final (part, name, on) in [
          ('contours', 'Contour lines', Tristate.isTrue),
          ('campsites', 'Campsites', Tristate.isFalse),
        ]) {
          final data = dataById(_id(slug, part));
          expect(data.label, name, reason: part);
          expect(data.flagsCollection.isToggled, on, reason: part);
        }
        handle.dispose();
      });

      testWidgets('$slug: Enter shows the layers and puts keyboard focus '
          'in them; Space turns a layer on', (tester) async {
        final handle = tester.ensureSemantics();
        await _showByKeyboard(tester, slug);
        await _key(tester, LogicalKeyboardKey.space);
        expect(
          dataById(_id(slug, 'contours')).flagsCollection.isToggled,
          Tristate.isFalse,
        );
        handle.dispose();
      });

      // Every example keeps Tab in its layers while they are shown: the
      // examples differ only in whether a key gets out (below).
      testWidgets('$slug: Tab and Shift+Tab go round the two switches', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _showByKeyboard(tester, slug);
        expect(await _tabs(tester, slug, 4), [
          'campsites',
          'contours',
          'campsites',
          'contours',
        ]);
        expect(await _tabs(tester, slug, 4, shift: true), [
          'campsites',
          'contours',
          'campsites',
          'contours',
        ]);
        handle.dispose();
      });
    }
  });

  group('Escape (2.1.2)', () {
    for (final slug in _escapeCloses) {
      testWidgets('$slug: Escape closes the layers and focus goes back to '
          'Map layers', (tester) async {
        final handle = tester.ensureSemantics();
        await _showByKeyboard(tester, slug);
        expect(await _key(tester, LogicalKeyboardKey.escape), isTrue);
        _expectClosed(tester, slug, 1);
        handle.dispose();
      }, variant: _platforms);
    }

    // The defects. Escape alone, from each switch; then, in the same test,
    // the positive control: Space on the stop turns its layer, so keys
    // arrive and focus is where the test says. Written to fail when Escape
    // starts to close the layers.
    for (final slug in ['bad-not-dismissible', 'bad-no-escape']) {
      testWidgets('$slug: Escape does nothing, from either switch, and no '
          'key leaves the layers', (tester) async {
        final handle = tester.ensureSemantics();
        await _showByKeyboard(tester, slug);
        expect(await _key(tester, LogicalKeyboardKey.escape), isFalse);
        await _expectStillShown(tester, slug, 'contours');
        expect(await _tabs(tester, slug, 1), ['campsites']);
        expect(await _key(tester, LogicalKeyboardKey.escape), isFalse);
        await _expectStillShown(tester, slug, 'campsites');
        await _key(tester, LogicalKeyboardKey.space);
        expect(
          dataById(_id(slug, 'campsites')).flagsCollection.isToggled,
          Tristate.isTrue,
        );
        // Ten Tabs and ten Shift+Tabs never leave the two switches.
        final stops = [
          ...await _tabs(tester, slug, 10),
          ...await _tabs(tester, slug, 10, shift: true),
        ];
        expect(stops.toSet(), {'contours', 'campsites'});
        // The positive control for Escape itself, in the same test: the
        // good example this one is made from closes on the same key.
        await tester.pumpWidget(const SizedBox());
        final good = slug == 'bad-no-escape' ? 'good-widgets' : 'good-material';
        await _showByKeyboard(tester, good);
        expect(await _key(tester, LogicalKeyboardKey.escape), isTrue);
        _expectClosed(tester, good, 1);
        handle.dispose();
      }, variant: _platforms);
    }
  });

  group('Back and the escape gesture at the root (popRoute)', () {
    for (final slug in [..._good, 'bad-not-dismissible', 'bad-no-escape']) {
      testWidgets('$slug: popRoute closes the layers and the screen stays', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _showByKeyboard(tester, slug);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        _expectClosed(tester, slug, 1);
        handle.dispose();
      });
    }

    // The defect. First the positive control, in the same test: Escape
    // closes the layers, and the screen is the example's. Then popRoute
    // with the layers shown takes the user off the screen, to the
    // technique's own screen. Written to fail when popRoute closes them.
    testWidgets('bad-back-leaves: popRoute leaves the screen with the '
        'layers shown', (tester) async {
      const slug = 'bad-back-leaves';
      final handle = tester.ensureSemantics();
      await _showByKeyboard(tester, slug);
      expect(await _key(tester, LogicalKeyboardKey.escape), isTrue);
      _expectClosed(tester, slug, 1);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(_shown(slug), isTrue);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(byId(_id(slug, 'count')), findsNothing);
      expect(_shown(slug), isFalse);
      // The technique's screen, with its list of examples.
      expect(find.text('Good examples'), findsOneWidget);
      expect(
        find.text('Layers drawn in the overlay that Back goes past'),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('a screen reader\'s dismiss action', () {
    // Which nodes have the dismiss action while the layers are shown: the
    // barrier, which TalkBack reads as a control of its own, and, in the
    // overlay examples, the layers themselves.
    const dismissable = {
      'good-material': ['Scrim'],
      'good-cupertino': ['Dismiss'],
      'good-widgets': ['Close map layers', ''],
      'bad-no-escape': ['Close map layers', ''],
      'bad-back-leaves': ['Close map layers', ''],
    };
    for (final MapEntry(key: slug, value: labels) in dismissable.entries) {
      for (var i = 0; i < labels.length; i++) {
        testWidgets('$slug: the dismiss action on "${labels[i]}" closes the '
            'layers', (tester) async {
          final handle = tester.ensureSemantics();
          await _showByKeyboard(tester, slug);
          final nodes = _dismissable(tester);
          expect(nodes.map((n) => n.getSemanticsData().label), labels);
          _dismiss(tester, nodes[i]);
          await tester.pumpAndSettle();
          _expectClosed(tester, slug, 1);
          handle.dispose();
        });
      }
    }

    // Where VoiceOver's escape gesture on a switch is taken: in the overlay
    // examples by the layers' own node; in the route examples by nothing in
    // the tree, so it goes on to the engine's view controller, which sends
    // popRoute (above).
    for (final slug in _all) {
      final inTree = _overlays.contains(slug);
      testWidgets('$slug: the escape gesture on a switch is taken '
          '${inTree ? 'by the layers' : 'by no node'}', (tester) async {
        final handle = tester.ensureSemantics();
        await _showByKeyboard(tester, slug);
        for (final part in ['contours', 'campsites']) {
          expect(
            _escapeTakenAt(nodeById(_id(slug, part)).evaluate().single),
            inTree,
            reason: part,
          );
        }
        handle.dispose();
      });
    }

    // The defect. Written to fail when the sheet's barrier gets the action.
    testWidgets('bad-not-dismissible: no node has the dismiss action', (
      tester,
    ) async {
      const slug = 'bad-not-dismissible';
      final handle = tester.ensureSemantics();
      await _showByKeyboard(tester, slug);
      expect(_dismissable(tester), isEmpty);
      // The positive control: the same search finds good-material's.
      await tester.pumpWidget(const SizedBox());
      await _showByKeyboard(tester, 'good-material');
      expect(_dismissable(tester), hasLength(1));
      handle.dispose();
    });
  });

  group('the SDK on its own', () {
    Future<void> pumpApp(WidgetTester tester, Widget home) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: home)));
      await tester.pumpAndSettle();
    }

    // FL-480. A route closes on Escape only when its barrier can be
    // dismissed; popRoute, which Android's Back and VoiceOver's escape
    // gesture send, closes it either way.
    for (final dismissible in [true, false]) {
      testWidgets('showDialog(barrierDismissible: $dismissible): Escape '
          '${dismissible ? 'closes' : 'does not close'} it, popRoute does', (
        tester,
      ) async {
        await pumpApp(
          tester,
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                barrierDismissible: dismissible,
                builder: (_) => const AlertDialog(title: Text('Question')),
              ),
              child: const Text('Ask'),
            ),
          ),
        );
        await tester.tap(find.text('Ask'));
        await tester.pumpAndSettle();
        expect(await _key(tester, LogicalKeyboardKey.escape), dismissible);
        expect(find.text('Question'), dismissible ? findsNothing : findsOne);
        if (dismissible) return;
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Question'), findsNothing);
      });
    }

    // FL-481. An overlay with no route closes on nothing: Escape is not
    // handled, and popRoute pops the screen under it.
    testWidgets('an OverlayPortal: Escape is not handled, and popRoute pops '
        'the screen under it', (tester) async {
      final controller = OverlayPortalController();
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          home: const Scaffold(body: Text('First screen')),
        ),
      );
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            body: OverlayPortal(
              controller: controller,
              overlayChildBuilder: (_) => const Center(child: Text('Panel')),
              child: const Text('Second screen'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      controller.show();
      await tester.pumpAndSettle();
      expect(find.text('Panel'), findsOne);
      expect(await _key(tester, LogicalKeyboardKey.escape), isFalse);
      expect(find.text('Panel'), findsOne);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Second screen'), findsNothing);
      expect(find.text('First screen'), findsOne);
    });

    // FL-481. An OverlayEntry inserted from a screen is not part of it:
    // popRoute pops the screen and the entry stays, over the screen before.
    testWidgets('an OverlayEntry stays on after popRoute pops its screen', (
      tester,
    ) async {
      final navigator = GlobalKey<NavigatorState>();
      final entry = OverlayEntry(
        builder: (_) => const Center(child: Text('Panel')),
      );
      addTearDown(entry.dispose);
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          home: const Scaffold(body: Text('First screen')),
        ),
      );
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Overlay.of(context).insert(entry),
              child: const Text('Second screen'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Second screen'));
      await tester.pumpAndSettle();
      expect(await _key(tester, LogicalKeyboardKey.escape), isFalse);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('First screen'), findsOne);
      expect(find.text('Panel'), findsOne);
      entry.remove();
    });

    // FL-483. An OverlayPortal's overlay child is in the semantics tree
    // where the portal is, not over the screen, so a ModalBarrier in it,
    // which hides from screen readers what was painted before it, takes
    // the whole screen out of the tree, the layers with it. The same
    // barrier in an OverlayEntry hides only the screen.
    for (final portal in [true, false]) {
      testWidgets(
        'a ModalBarrier in ${portal ? 'an OverlayPortal' : 'an '
                  'OverlayEntry'} ${portal ? 'empties' : 'keeps the panel in'} the '
        'semantics tree',
        (tester) async {
          final handle = tester.ensureSemantics();
          final controller = OverlayPortalController();
          Widget overlay(BuildContext _) => Stack(
            children: [
              const ModalBarrier(semanticsLabel: 'Close'),
              Center(
                child: TextButton(onPressed: () {}, child: const Text('Panel')),
              ),
            ],
          );
          final entry = OverlayEntry(builder: overlay);
          addTearDown(entry.dispose);
          await pumpApp(
            tester,
            Builder(
              builder: (context) => OverlayPortal(
                controller: controller,
                overlayChildBuilder: overlay,
                child: TextButton(
                  onPressed: () => portal
                      ? controller.show()
                      : Overlay.of(context).insert(entry),
                  child: const Text('Screen'),
                ),
              ),
            ),
          );
          expect(find.semantics.byLabel('Screen'), findsOne);
          await tester.tap(find.text('Screen'));
          await tester.pumpAndSettle();
          expect(find.text('Panel'), findsOne);
          expect(find.semantics.byLabel('Screen'), findsNothing);
          expect(
            find.semantics.byLabel('Panel'),
            portal ? findsNothing : findsOne,
          );
          expect(
            find.semantics.byLabel('Close'),
            portal ? findsNothing : findsOne,
          );
          if (!portal) entry.remove();
          handle.dispose();
        },
      );
    }

    // The three ways to keep Tab in a part of the screen: each keeps Tab
    // and Shift+Tab there, and none lets Escape out by itself.
    final ways = <String, Widget Function(List<Widget> buttons)>{
      'Focus.onKeyEvent': (buttons) => _KeyTrap(children: buttons),
      'a FocusTraversalPolicy': (buttons) => FocusTraversalGroup(
        policy: _CyclePolicy(),
        child: Row(children: buttons),
      ),
      'TraversalEdgeBehavior.closedLoop': (buttons) => FocusScope(
        node: FocusScopeNode(
          traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
        ),
        child: Row(children: buttons),
      ),
    };
    for (final MapEntry(key: way, value: trap) in ways.entries) {
      testWidgets('a trap made with $way keeps Tab and Shift+Tab in, and '
          'Escape does not get out', (tester) async {
        final a = FocusNode(debugLabel: 'A');
        final b = FocusNode(debugLabel: 'B');
        final after = FocusNode(debugLabel: 'After');
        addTearDown(() {
          a.dispose();
          b.dispose();
          after.dispose();
        });
        await pumpApp(
          tester,
          Column(
            children: [
              trap([
                TextButton(
                  focusNode: a,
                  onPressed: () {},
                  child: const Text('A'),
                ),
                TextButton(
                  focusNode: b,
                  onPressed: () {},
                  child: const Text('B'),
                ),
              ]),
              TextButton(
                focusNode: after,
                onPressed: () {},
                child: const Text('After'),
              ),
            ],
          ),
        );
        a.requestFocus();
        await tester.pumpAndSettle();
        final seen = <String?>[];
        for (var i = 0; i < 4; i++) {
          await _key(tester, LogicalKeyboardKey.tab);
          seen.add(FocusManager.instance.primaryFocus?.debugLabel);
        }
        for (var i = 0; i < 4; i++) {
          await _key(tester, LogicalKeyboardKey.tab, shift: true);
          seen.add(FocusManager.instance.primaryFocus?.debugLabel);
        }
        expect(seen, ['B', 'A', 'B', 'A', 'B', 'A', 'B', 'A']);
        await _key(tester, LogicalKeyboardKey.escape);
        expect(FocusManager.instance.primaryFocus, a);
        // The positive control: the button after the trap takes focus.
        after.requestFocus();
        await tester.pumpAndSettle();
        expect(FocusManager.instance.primaryFocus, after);
      });
    }

    // FL-482. Escape hides a tooltip only while keyboard focus is inside
    // the app: WidgetsApp handles it in a Focus of its own, which a key
    // reaches only on its way up from the focused node.
    testWidgets('a tooltip: Escape hides it while focus is in the app, and '
        'not while focus is above it', (tester) async {
      Future<void> showTip() async {
        await tester.longPress(find.text('Map'));
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Shows the map'), findsOne);
      }

      await pumpApp(
        tester,
        const Center(
          child: Tooltip(message: 'Shows the map', child: Text('Map')),
        ),
      );
      await showTip();
      expect(
        FocusManager.instance.primaryFocus,
        isNot(FocusManager.instance.rootScope),
      );
      expect(await _key(tester, LogicalKeyboardKey.escape), isTrue);
      expect(find.text('Shows the map'), findsNothing);
      // The view loses focus, as on the web when the page itself has no
      // focus: the framework parks focus on the root scope, above
      // WidgetsApp (read in the source: widgets/view.dart).
      tester.binding.handleViewFocusChanged(
        ViewFocusEvent(
          viewId: tester.view.viewId,
          state: ViewFocusState.unfocused,
          direction: ViewFocusDirection.undefined,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        FocusManager.instance.primaryFocus,
        FocusManager.instance.rootScope,
      );
      await showTip();
      expect(await _key(tester, LogicalKeyboardKey.escape), isFalse);
      expect(find.text('Shows the map'), findsOne);
      await tester.pump(const Duration(seconds: 2));
    });
  });
}

/// A part of the screen whose `onKeyEvent` takes Tab and Shift+Tab and
/// moves between its own buttons.
class _KeyTrap extends StatelessWidget {
  const _KeyTrap({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent ||
            event.logicalKey != LogicalKeyboardKey.tab) {
          return KeyEventResult.ignored;
        }
        final nodes = node.traversalDescendants.toList();
        final i = nodes.indexWhere((n) => n.hasPrimaryFocus);
        final by = HardwareKeyboard.instance.isShiftPressed ? -1 : 1;
        nodes[(i + by) % nodes.length].requestFocus();
        return KeyEventResult.handled;
      },
      child: Row(children: children),
    );
  }
}

/// A policy whose next and previous go round its own group.
class _CyclePolicy extends WidgetOrderTraversalPolicy {
  @override
  bool next(FocusNode currentNode) => _move(currentNode, 1);

  @override
  bool previous(FocusNode currentNode) => _move(currentNode, -1);

  bool _move(FocusNode current, int by) {
    final group = FocusTraversalGroup.maybeOfNode(current);
    final nodes = sortDescendants(
      current.nearestScope!.traversalDescendants,
      current,
    ).where((n) => FocusTraversalGroup.maybeOfNode(n) == group).toList();
    final i = nodes.indexOf(current);
    nodes[(i + by) % nodes.length].requestFocus();
    return true;
  }
}
