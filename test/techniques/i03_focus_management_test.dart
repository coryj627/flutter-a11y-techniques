import 'dart:ui' show Tristate;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/i03_focus_management/i03_focus_management.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/examples.dart';

/// L1 for I03 Focus management (docs/specs/I03-focus-management.md).
///
/// Every stop is named, never counted: after each key the test finds where
/// Flutter's keyboard focus is (FocusManager.primaryFocus) and names it by
/// the control it is, or, when no control has it, by the route it is in.
final _open = exampleOpener(i03FocusManagement);

const _good = ['good-material', 'good-cupertino', 'good-widgets'];
const _bad = ['bad-focus-left-behind', 'bad-opens-on-focus'];
const _all = [..._good, ..._bad];

/// The examples whose question is opened by pressing a Remove button.
const _pressToAsk = [..._good, 'bad-focus-left-behind'];

const _names = {
  'remove-ridge': 'Remove Ridge trail',
  'remove-lake': 'Remove Lake loop',
  'remove-summit': 'Remove Summit path',
  'cancel': 'Cancel',
  'confirm': 'Remove',
};

String _id(String slug, String part) => 'i03-$slug-$part';

/// How long after a removal the examples send the screen reader to the
/// next button (`_afterTheRoute` in examples.dart).
const _afterTheRoute = Duration(seconds: 1);

int _saved(WidgetTester tester, String slug) =>
    countOf(tester, _id(slug, 'count'));

/// The question that removing Lake loop asks, on screen or not.
Finder get _lakeQuestion => find.text('Remove Lake loop?');

/// Where keyboard focus is: 'back', one of [_names]'s keys, 'question'
/// when it is on the question's route and on no control there, 'screen'
/// when it is on the example's screen and on no control, or 'none'.
String _stop(WidgetTester tester, String slug) {
  final focused = semanticsNodes(tester)
      .where((d) => d.flagsCollection.isFocused == Tristate.isTrue)
      .toList();
  expect(focused.length, lessThanOrEqualTo(1), reason: 'two nodes have focus');
  if (focused.isNotEmpty) {
    final node = focused.single;
    if (node.tooltip == 'Back') return 'back';
    for (final part in _names.keys) {
      if (node.identifier == _id(slug, part)) return part;
    }
    return 'other: ${node.identifier} ${node.label}';
  }
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return 'none';
  final route = ModalRoute.of(context);
  if (route is PopupRoute) return 'question';
  if (route is PageRoute) return 'screen';
  return 'none';
}

Future<void> _key(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool shift = false,
}) async {
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(key);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.pumpAndSettle();
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

/// Tabs from the screen as it opens to Remove Lake loop: Back, Remove Ridge
/// trail, Remove Lake loop, naming each stop.
Future<void> _tabToLake(WidgetTester tester, String slug) async {
  expect(await _tabs(tester, slug, 3), ['back', 'remove-ridge', 'remove-lake']);
}

/// Tabs from where focus is to [part] of the question, at most four times.
Future<void> _tabInQuestionTo(
  WidgetTester tester,
  String slug,
  String part,
) async {
  for (var i = 0; i < 4 && _stop(tester, slug) != part; i++) {
    await _key(tester, LogicalKeyboardKey.tab);
  }
  expect(_stop(tester, slug), part);
}

/// The id of the semantics node of [part] of [slug].
int _nodeId(String slug, String part) =>
    nodeById(_id(slug, part)).evaluate().single.id;

/// Tells the framework that the screen reader's focus is on the node
/// [nodeId], as the Android and iOS engines do when it lands on one.
Future<void> _screenReaderOn(WidgetTester tester, int nodeId) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.accessibility.name,
    SystemChannels.accessibility.codec.encodeMessage(<String, Object?>{
      'type': 'didGainFocus',
      'nodeId': nodeId,
    }),
    (_) {},
  );
}

/// Records what the framework asks the platform to do with the screen
/// reader's focus: the node of every "focus" event sent.
List<int> _recordFocusRequests(WidgetTester tester) {
  final requests = <int>[];
  tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
    SystemChannels.accessibility,
    (message) async {
      final map = message! as Map<Object?, Object?>;
      if (map['type'] == 'focus') requests.add(map['nodeId']! as int);
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger
        .setMockDecodedMessageHandler<Object?>(
          SystemChannels.accessibility,
          null,
        ),
  );
  return requests;
}

void main() {
  test('the technique has the examples named in the spec', () {
    expect(i03FocusManagement.examples.map((e) => e.slug), _all);
    expect(_good, [
      for (final e in i03FocusManagement.examples)
        if (e.kind == ExampleKind.good) e.slug,
    ]);
  });

  group('good examples', () {
    for (final slug in _good) {
      for (final brightness in Brightness.values) {
        testWidgets('$slug meets the guidelines (${brightness.name}), with '
            'and without the question open', (tester) async {
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
          await tester.tap(byId(_id(slug, 'remove-lake')));
          await tester.pumpAndSettle();
          expect(_lakeQuestion, findsOneWidget);
          await check();
          handle.dispose();
        });
      }

      testWidgets('$slug does not overflow at 200% text on a phone, with '
          'the question open', (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await _open(tester, slug, textScale: 2);
        expect(tester.takeException(), isNull);
        await tester.tap(byId(_id(slug, 'remove-lake')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('every example', () {
    for (final slug in _all) {
      testWidgets('$slug: three named Remove buttons, none focused, and '
          'the count', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        for (final part in ['remove-ridge', 'remove-lake', 'remove-summit']) {
          final data = dataById(_id(slug, part));
          expect(data.label, _names[part], reason: part);
          expect(data.flagsCollection.isButton, isTrue, reason: part);
          expect(data.flagsCollection.isFocused, Tristate.isFalse);
        }
        expect(_saved(tester, slug), 3);
        handle.dispose();
      });

      testWidgets('$slug: a tap asks, and Remove removes', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await tester.tap(byId(_id(slug, 'remove-lake')));
        await tester.pumpAndSettle();
        expect(_lakeQuestion, findsOneWidget);
        await tester.tap(byId(_id(slug, 'confirm')));
        await tester.pumpAndSettle();
        expect(_lakeQuestion, findsNothing);
        expect(byId(_id(slug, 'remove-lake')), findsNothing);
        expect(_saved(tester, slug), 2);
        await tester.pump(_afterTheRoute);
        handle.dispose();
      });
    }
  });

  group('the question opens on a press, not on focus (3.2.1)', () {
    for (final slug in _pressToAsk) {
      testWidgets('$slug: Tab onto each Remove button asks nothing; Enter '
          'on one asks', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        expect(await _tabs(tester, slug, 4), [
          'back',
          'remove-ridge',
          'remove-lake',
          'remove-summit',
        ]);
        expect(find.textContaining('?'), findsNothing);
        // The positive control: the same key reached each button, and
        // Enter on one asks.
        await _key(tester, LogicalKeyboardKey.enter);
        expect(find.text('Remove Summit path?'), findsOneWidget);
        handle.dispose();
      });
    }

    // The defect. Written to fail when focus no longer opens the question.
    testWidgets('bad-opens-on-focus: Tab onto Remove Ridge trail asks at '
        'once and moves focus into the question', (tester) async {
      const slug = 'bad-opens-on-focus';
      final handle = tester.ensureSemantics();
      await _open(tester, slug);
      // Tab reaches Back and asks nothing: the key arrives.
      expect(await _tabs(tester, slug, 1), ['back']);
      expect(find.textContaining('?'), findsNothing);
      // The next Tab alone, onto Remove Ridge trail, asks.
      await _key(tester, LogicalKeyboardKey.tab);
      expect(find.text('Remove Ridge trail?'), findsOneWidget);
      expect(_stop(tester, slug), 'question');
      // Cancel goes back to the button, which does not ask again ...
      await _tabInQuestionTo(tester, slug, 'cancel');
      await _key(tester, LogicalKeyboardKey.enter);
      expect(find.textContaining('?'), findsNothing);
      expect(_stop(tester, slug), 'remove-ridge');
      // ... and Tab to the next button asks about it.
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_lakeQuestion, findsOneWidget);
      expect(_stop(tester, slug), 'question');
      handle.dispose();
    });
  });

  group('focus goes into the question when it opens (2.4.3)', () {
    // Enter on Remove Lake loop. The two dialog routes put focus on their
    // own scope, so the next Tab is the question's first control; the
    // general dialog puts it on Cancel at once.
    const opens = {
      'good-material': ('question', 'cancel'),
      'good-cupertino': ('question', 'confirm'),
      'good-widgets': ('cancel', 'confirm'),
    };
    for (final MapEntry(key: slug, value: (first, next)) in opens.entries) {
      testWidgets('$slug: Enter on Remove Lake loop puts focus in the '
          'question, and Tab stays in it', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await _tabToLake(tester, slug);
        await _key(tester, LogicalKeyboardKey.enter);
        expect(_lakeQuestion, findsOneWidget);
        expect(_stop(tester, slug), first);
        expect(await _tabs(tester, slug, 1), [next]);
        handle.dispose();
      });
    }

    // The defect. Written to fail when the question starts to take focus.
    testWidgets('bad-focus-left-behind: focus stays on Remove Lake loop '
        'behind the question, and Tab goes to the button behind it before '
        'the question', (tester) async {
      const slug = 'bad-focus-left-behind';
      final handle = tester.ensureSemantics();
      await _open(tester, slug);
      await _tabToLake(tester, slug);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(_lakeQuestion, findsOneWidget);
      // The button behind the question is out of the semantics tree, so
      // the focus node itself is read.
      expect(
        FocusManager.instance.primaryFocus,
        _focusNodeOf(tester, slug, 'remove-lake'),
      );
      expect(
        ModalRoute.of(FocusManager.instance.primaryFocus!.context!),
        isA<PageRoute<Object?>>(),
      );
      await _key(tester, LogicalKeyboardKey.tab);
      expect(
        FocusManager.instance.primaryFocus,
        _focusNodeOf(tester, slug, 'remove-summit'),
        reason: 'the next Tab goes to the button behind the question',
      );
      // Only after the last control of the screen does Tab reach the
      // question.
      expect(await _tabs(tester, slug, 1), ['cancel']);
      handle.dispose();
    });
  });

  group('focus comes back when the question closes (2.4.3)', () {
    // The same defect seen on the way out. Tab reached the question only by
    // passing the last control of the screen, which clears the screen's
    // record of where its focus was (read in the source:
    // FocusTraversalPolicy._moveFocus, TraversalEdgeBehavior.parentScope,
    // and FocusNode.unfocus). So Cancel leaves focus on the screen itself,
    // and the next Tab starts again at Back. Written to fail when focus
    // comes back to the Remove button.
    testWidgets('bad-focus-left-behind: after Cancel focus is on no '
        'control, and Tab starts again at Back', (tester) async {
      const slug = 'bad-focus-left-behind';
      final handle = tester.ensureSemantics();
      await _open(tester, slug);
      await _tabToLake(tester, slug);
      await _key(tester, LogicalKeyboardKey.enter);
      await _tabInQuestionTo(tester, slug, 'cancel');
      await _key(tester, LogicalKeyboardKey.enter);
      expect(_lakeQuestion, findsNothing);
      expect(_stop(tester, slug), 'screen');
      expect(await _tabs(tester, slug, 1), ['back']);
      handle.dispose();
    });

    for (final slug in _good) {
      testWidgets('$slug: Cancel puts focus back on Remove Lake loop, and '
          'Tab goes on from there', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await _tabToLake(tester, slug);
        await _key(tester, LogicalKeyboardKey.enter);
        await _tabInQuestionTo(tester, slug, 'cancel');
        await _key(tester, LogicalKeyboardKey.enter);
        expect(_lakeQuestion, findsNothing);
        expect(_stop(tester, slug), 'remove-lake');
        expect(await _tabs(tester, slug, 1), ['remove-summit']);
        handle.dispose();
      });
    }

    for (final slug in _good) {
      testWidgets('$slug: Remove puts focus on the next trail\'s button, '
          'Remove Summit path', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await _tabToLake(tester, slug);
        await _key(tester, LogicalKeyboardKey.enter);
        await _tabInQuestionTo(tester, slug, 'confirm');
        await _key(tester, LogicalKeyboardKey.enter);
        expect(byId(_id(slug, 'remove-lake')), findsNothing);
        expect(_saved(tester, slug), 2);
        expect(_stop(tester, slug), 'remove-summit');
        expect(await _tabs(tester, slug, 1, shift: true), ['remove-ridge']);
        await tester.pump(_afterTheRoute);
        handle.dispose();
      });

      testWidgets('$slug: removing the last trail puts focus on the one '
          'before', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        expect(await _tabs(tester, slug, 4), [
          'back',
          'remove-ridge',
          'remove-lake',
          'remove-summit',
        ]);
        await _key(tester, LogicalKeyboardKey.enter);
        await _tabInQuestionTo(tester, slug, 'confirm');
        await _key(tester, LogicalKeyboardKey.enter);
        expect(byId(_id(slug, 'remove-summit')), findsNothing);
        expect(_stop(tester, slug), 'remove-lake');
        await tester.pump(_afterTheRoute);
        handle.dispose();
      });
    }
  });

  group('the screen reader (what the framework sends the platform)', () {
    // On Android and iOS the Navigator remembers which node the screen
    // reader was on when a route opened, and when the route closes asks
    // the platform to put the screen reader's focus back there (read in
    // the source: widgets/navigator.dart, _RouteEntry.handleDidPopNext).
    // On the web it sends nothing; there the screen reader follows the
    // element with DOM focus. What the platforms then do with the request
    // is the TalkBack and VoiceOver walks' to show.
    for (final slug in _pressToAsk) {
      testWidgets(
        '$slug: after Cancel the framework asks for the screen reader to go '
        'back to Remove Lake loop',
        variant: const TargetPlatformVariant({
          TargetPlatform.android,
          TargetPlatform.iOS,
        }),
        (tester) async {
          final handle = tester.ensureSemantics();
          // The binding keeps the last node reported across tests, and does
          // not report the same node twice.
          ServicesBinding.instance.accessibilityFocus.value = null;
          final requests = _recordFocusRequests(tester);
          await _open(tester, slug);
          final lake = _nodeId(slug, 'remove-lake');
          await _screenReaderOn(tester, lake);
          await tester.tap(byId(_id(slug, 'remove-lake')));
          await tester.pumpAndSettle();
          await tester.tap(byId(_id(slug, 'cancel')));
          await tester.pumpAndSettle();
          await tester.pump(const Duration(seconds: 1));
          expect(requests, [lake]);
          handle.dispose();
        },
      );
    }

    // After Remove, the framework's own request is for Remove Lake loop,
    // which is gone by then (FL-442); the good examples follow it with a
    // request for Remove Summit path. The order matters: the last request
    // is the one the platform is left with.
    for (final slug in _good) {
      testWidgets(
        '$slug: after Remove the last request is for Remove Summit path, '
        'after the framework\'s for the removed button',
        variant: const TargetPlatformVariant({
          TargetPlatform.android,
          TargetPlatform.iOS,
        }),
        (tester) async {
          final handle = tester.ensureSemantics();
          ServicesBinding.instance.accessibilityFocus.value = null;
          final requests = _recordFocusRequests(tester);
          await _open(tester, slug);
          final lake = _nodeId(slug, 'remove-lake');
          final summit = _nodeId(slug, 'remove-summit');
          await _screenReaderOn(tester, lake);
          await tester.tap(byId(_id(slug, 'remove-lake')));
          await tester.pumpAndSettle();
          await tester.tap(byId(_id(slug, 'confirm')));
          await tester.pumpAndSettle();
          // The framework's request comes once the route has gone (on
          // Android 300 ms later), the examples' after it.
          await tester.pump(_afterTheRoute);
          expect(requests, [lake, summit]);
          expect(nodeById(_id(slug, 'remove-lake')), findsNothing);
          handle.dispose();
        },
      );
    }
  });

  group('the SDK on its own', () {
    // FL-440: a CupertinoDialogAction takes no keyboard focus, so Tab
    // never reaches the actions of a CupertinoAlertDialog. Written to fail
    // when it starts to.
    testWidgets('FL-440: Tab never reaches a CupertinoAlertDialog\'s '
        'actions', (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (context) => CupertinoPageScaffold(
              child: Center(
                child: CupertinoButton(
                  onPressed: () => showCupertinoDialog<void>(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: const Text('Remove Lake loop?'),
                      actions: [
                        CupertinoDialogAction(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        CupertinoDialogAction(
                          isDestructiveAction: true,
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Remove'),
                        ),
                      ],
                    ),
                  ),
                  child: const Text('Remove Lake loop'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Remove Lake loop?'), findsOneWidget);
      final scope = FocusManager.instance.primaryFocus;
      expect(scope, isA<FocusScopeNode>());
      for (var i = 0; i < 6; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        expect(
          FocusManager.instance.primaryFocus,
          scope,
          reason: 'Tab $i moved focus',
        );
      }
      // Neither action has a focus node of its own (read in the source:
      // cupertino/dialog.dart, CupertinoDialogAction has no Focus).
      expect(find.byType(CupertinoDialogAction), findsNWidgets(2));
      expect(
        find.descendant(
          of: find.byType(CupertinoDialogAction),
          matching: find.byType(Focus),
        ),
        findsNothing,
      );
    });

    // FL-002, for the action sheet. On the web Enter arrives as
    // ButtonActivateIntent; a widget test cannot run as web, so this checks
    // the action lookup the web relies on, from inside each action, where
    // its focus node is. Written to fail when the plain action starts to
    // handle it, and the wrapper in good-cupertino can go.
    testWidgets('FL-002: a CupertinoActionSheetAction has no action for the '
        'intent the web sends for Enter; good-cupertino adds one', (
      tester,
    ) async {
      bool handlesEnterOnWeb(Finder action) {
        late BuildContext inside;
        tester.element(action).visitChildElements((child) => inside = child);
        return Actions.maybeFind<ButtonActivateIntent>(inside) != null;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: CupertinoActionSheet(
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {},
                child: const Text('Remove'),
              ),
            ],
          ),
        ),
      );
      expect(
        handlesEnterOnWeb(find.byType(CupertinoActionSheetAction)),
        isFalse,
      );

      await tester.pumpWidget(const SizedBox());
      await _open(tester, 'good-cupertino');
      await tester.tap(byId(_id('good-cupertino', 'remove-lake')));
      await tester.pumpAndSettle();
      for (final part in ['confirm', 'cancel']) {
        final action = find.descendant(
          of: byId(_id('good-cupertino', part)),
          matching: find.byType(CupertinoActionSheetAction),
        );
        expect(handlesEnterOnWeb(action), isTrue, reason: part);
      }
    });

    // FL-441: with its own colours, an action sheet's title and message
    // fail Flutter's text contrast check in light mode, which is why
    // good-cupertino sets them. Written to fail when they pass.
    testWidgets('FL-441: a CupertinoActionSheet\'s own text colours fail '
        'the text contrast check in light mode', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showCupertinoModalPopup<void>(
                    context: context,
                    builder: (context) => CupertinoActionSheet(
                      title: const Text('Remove Lake loop?'),
                      message: const Text('It goes from your saved trails.'),
                      actions: [
                        CupertinoActionSheetAction(
                          isDestructiveAction: true,
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Remove'),
                        ),
                      ],
                      cancelButton: CupertinoActionSheetAction(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ),
                  child: const Text('Remove Lake loop'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Remove Lake loop'));
      await tester.pumpAndSettle();
      final result = await textContrastGuideline.evaluate(tester);
      expect(result.passed, isFalse);
      expect(result.reason, contains('Remove Lake loop?'));
      expect(result.reason, contains('It goes from your saved trails.'));
      handle.dispose();
    });

    // The way Flutter moves focus off a control that is removed: to the
    // control of the same scope that had focus before it, which depends on
    // how the user got there (read in the source:
    // FocusAttachment.detach, UnfocusDisposition.previouslyFocusedChild).
    testWidgets('a removed focused control hands focus to the one focused '
        'before it, wherever that is', (tester) async {
      final rows = ValueNotifier(['A', 'B', 'C']);
      final nodes = {for (final r in rows.value) r: FocusNode(debugLabel: r)};
      addTearDown(() {
        for (final n in nodes.values) {
          n.dispose();
        }
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder(
              valueListenable: rows,
              builder: (context, value, _) => Column(
                children: [
                  for (final r in value)
                    TextButton(
                      key: ValueKey(r),
                      focusNode: nodes[r],
                      onPressed: () => rows.value = [...value]..remove(r),
                      child: Text(r),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      // Tab to A, then focus put on C directly, as it is on the web when
      // VoiceOver's cursor gives an element DOM focus.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, nodes['A']);
      nodes['C']!.requestFocus();
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, nodes['C']);
      // Removing C hands focus back to A, past B, its neighbour.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('C'), findsNothing);
      expect(FocusManager.instance.primaryFocus, nodes['A']);
    });
  });
}

/// The focus node of the control [part] of [slug]: the `Focus` nearest
/// under its test identifier.
FocusNode _focusNodeOf(WidgetTester tester, String slug, String part) =>
    Focus.of(
      tester.element(
        find
            .descendant(of: byId(_id(slug, part)), matching: find.byType(Text))
            .first,
      ),
    );
