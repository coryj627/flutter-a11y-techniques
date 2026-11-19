import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/i02_focus_order/i02_focus_order.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/examples.dart';

/// L1 for I02 Keyboard focus order (docs/specs/I02-focus-order.md).
///
/// Every order is read stop by stop: after each key the test finds the one
/// node whose semantics say it has focus, and names it. The examples are
/// opened on the test's default 800 by 600 screen, where every label fits
/// on one line, so the rows of the two columns are level, as on the
/// devices.
final _open = exampleOpener(i02FocusOrder);

const _good = ['good-material', 'good-cupertino', 'good-ordered'];
const _bad = ['bad-columns-mixed', 'bad-order-missing'];
const _all = [..._good, ..._bad];

/// The controls of every example, by the last part of their identifier.
const _controls = ['map', 'water', 'aid', 'weather', 'closures', 'save'];
const _names = {
  'map': 'Map',
  'water': 'Water',
  'aid': 'First aid',
  'weather': 'Weather',
  'closures': 'Closures',
  'save': 'Save plan',
};
const _boxes = ['map', 'water', 'aid', 'weather', 'closures'];

/// Down the first column, down the second, then Save plan.
const _columnOrder = ['map', 'water', 'aid', 'weather', 'closures', 'save'];

/// Tab, from the screen as it opens, in each example: Back comes first.
const _tabOrder = {
  'good-material': ['back', ..._columnOrder],
  'good-cupertino': ['back', ..._columnOrder],
  'good-ordered': ['back', ..._columnOrder],
  // Row by row, across the two columns.
  'bad-columns-mixed': [
    'back',
    'map',
    'weather',
    'water',
    'closures',
    'aid',
    'save',
  ],
  // First aid, with no number, after every numbered control.
  'bad-order-missing': [
    'back',
    'map',
    'water',
    'weather',
    'closures',
    'save',
    'aid',
  ],
};

/// What a screen reader moving forward meets, in every example: one column,
/// then the other.
const _readingOrder = [
  'Pack',
  'Map',
  'Water',
  'First aid',
  'Send me',
  'Weather',
  'Closures',
  'Save plan',
  'Saves: 0',
];

String _id(String slug, String control) => 'i02-$slug-$control';

int _saves(WidgetTester tester, String slug) =>
    countOf(tester, _id(slug, 'count'));

CheckedState _checked(String slug, String box) =>
    dataById(_id(slug, box)).flagsCollection.isChecked;

/// The control that has keyboard focus: 'back', one of [_controls], or
/// 'none'. Fails if more than one node says it has focus.
String _stop(WidgetTester tester, String slug) {
  final focused = semanticsNodes(tester)
      .where((d) => d.flagsCollection.isFocused == Tristate.isTrue)
      .toList();
  if (focused.isEmpty) return 'none';
  expect(focused, hasLength(1), reason: 'more than one node has focus');
  final node = focused.single;
  if (node.tooltip == 'Back') return 'back';
  for (final c in _controls) {
    if (node.identifier == _id(slug, c)) return c;
  }
  return 'other: ${node.identifier} ${node.label}';
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

/// Presses Tab, or Shift+Tab, [n] times and names the stop after each.
Future<List<String>> _walk(
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

/// Puts keyboard focus on [control] by pressing Tab until it is there.
Future<void> _tabTo(WidgetTester tester, String slug, String control) =>
    tabTo(tester, _id(slug, control));

/// Labels of the semantics nodes in the order a screen reader moving
/// forward meets them, from the "Example" heading to the count.
List<String> _reading(WidgetTester tester) {
  final out = _readingFrom(tester);
  return out.sublist(out.indexOf('Example') + 1);
}

/// Labels of every semantics node on the screen in traversal order, the
/// order the framework gives the platform for a screen reader to follow.
List<String> _readingFrom(WidgetTester tester) {
  final out = <String>[];
  void visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    if (!node.isMergedIntoParent && data.label.isNotEmpty) out.add(data.label);
    for (final child in node.debugListChildrenInOrder(
      DebugSemanticsDumpOrder.traversalOrder,
    )) {
      visit(child);
    }
  }

  visit(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return out;
}

void main() {
  test('the technique has the examples named in the spec', () {
    expect(i02FocusOrder.examples.map((e) => e.slug), _all);
    expect(_good, [
      for (final e in i02FocusOrder.examples)
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

  group('every example', () {
    for (final slug in _all) {
      testWidgets('$slug: five named checkboxes and a Save plan button, each '
          'focusable', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        for (final box in _boxes) {
          final data = dataById(_id(slug, box));
          expect(data.label, _names[box], reason: box);
          expect(
            data.flagsCollection.isChecked,
            CheckedState.isFalse,
            reason: box,
          );
          expect(data.flagsCollection.isFocused, Tristate.isFalse, reason: box);
        }
        final save = dataById(_id(slug, 'save'));
        expect(save.label, 'Save plan');
        expect(save.flagsCollection.isButton, isTrue);
        expect(save.flagsCollection.isFocused, Tristate.isFalse);
        handle.dispose();
      });

      testWidgets('$slug: a tap changes a box, and Save plan counts', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        for (final box in _boxes) {
          await tester.tap(byId(_id(slug, box)));
          await tester.pumpAndSettle();
          expect(_checked(slug, box), CheckedState.isTrue, reason: box);
        }
        await tester.tap(byId(_id(slug, 'save')));
        await tester.pumpAndSettle();
        expect(_saves(tester, slug), 1);
        handle.dispose();
      });

      testWidgets('$slug: a screen reader reads one column, then the other', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        expect(_reading(tester), _readingOrder);
        handle.dispose();
      });
    }
  });

  group('Tab order', () {
    for (final slug in _all) {
      final order = _tabOrder[slug]!;

      testWidgets('$slug: Tab goes ${order.join(', ')}, then round to Back', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        expect(_stop(tester, slug), 'none');
        expect(await _walk(tester, slug, order.length + 1), [...order, 'back']);
        handle.dispose();
      });

      testWidgets('$slug: Shift+Tab goes the same way backwards', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        // To the last stop, then back to Back and round to the last again.
        await _tabTo(tester, slug, order.last);
        final back = order.reversed.skip(1).toList();
        expect(await _walk(tester, slug, back.length + 1, shift: true), [
          ...back,
          order.last,
        ]);
        handle.dispose();
      });

      testWidgets('$slug: Space at each stop changes the box that has focus, '
          'and no other', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await _key(tester, LogicalKeyboardKey.tab); // Back
        for (final stop in order.skip(1)) {
          await _key(tester, LogicalKeyboardKey.tab);
          expect(_stop(tester, slug), stop);
          await _key(tester, LogicalKeyboardKey.space);
          if (stop == 'save') {
            expect(_saves(tester, slug), 1);
          } else {
            expect(_checked(slug, stop), CheckedState.isTrue, reason: stop);
          }
          final done = order.sublist(1, order.indexOf(stop) + 1);
          for (final box in _boxes) {
            expect(
              _checked(slug, box),
              done.contains(box) ? CheckedState.isTrue : CheckedState.isFalse,
              reason: 'after Space on $stop, $box',
            );
          }
        }
        handle.dispose();
      });
    }
  });

  // FL-422. On a screen so short that the example scrolls right past the
  // top of the screen, the default order, which is by position, can put
  // the app bar's Back among the controls scrolled away above it.
  // PageScaffold puts a FocusTraversalGroup around its scrolling view to
  // keep Back out (lib/app/widgets.dart).
  //
  // The good examples keep their order here with or without that group
  // (checked by taking it out): their FocusTraversalGroups are tall, and a
  // group is placed by its whole rectangle, which still reaches down into
  // Back's row, so Back stays first (read in the source:
  // ReadingOrderTraversalPolicy's bands). These tests guard their order on
  // a scrolled screen. The last test, on bad-columns-mixed, whose controls
  // are not in groups, is the one that fails without PageScaffold's group.
  group('on a screen short enough to scroll', () {
    Future<void> openShort(WidgetTester tester, String slug) async {
      tester.view.physicalSize = const Size(800, 120);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _open(tester, slug);
    }

    /// The top of the screen. A control whose bottom is above it is higher
    /// on the screen than Back.
    double viewTop(WidgetTester tester) => 0;

    for (final slug in _good) {
      final order = _tabOrder[slug]!;

      testWidgets('$slug: Tab goes ${order.join(', ')}, then round to Back, '
          'while the screen scrolls', (tester) async {
        final handle = tester.ensureSemantics();
        await openShort(tester, slug);
        final stops = <String>[];
        var scrolledAway = false;
        for (var i = 0; i < order.length; i++) {
          await _key(tester, LogicalKeyboardKey.tab);
          stops.add(_stop(tester, slug));
          if (tester.getRect(byId(_id(slug, 'map'))).bottom <=
              viewTop(tester)) {
            scrolledAway = true;
          }
        }
        expect(stops, order);
        // The screen really scrolled: on the way to Save plan, Map went
        // above the top of the screen, higher than Back.
        expect(scrolledAway, isTrue, reason: 'Map never left the screen');
        expect(await _walk(tester, slug, 1), ['back']);
        handle.dispose();
      });

      testWidgets('$slug: Shift+Tab goes backwards from Save plan to Back, '
          'while the screen scrolls', (tester) async {
        final handle = tester.ensureSemantics();
        await openShort(tester, slug);
        await _tabTo(tester, slug, order.last);
        expect(
          tester.getRect(byId(_id(slug, 'map'))).bottom,
          lessThanOrEqualTo(viewTop(tester)),
          reason: 'Map is above the screen when Save plan has focus',
        );
        final back = order.reversed.skip(1).toList();
        expect(await _walk(tester, slug, back.length, shift: true), back);
        handle.dispose();
      });
    }

    // Without PageScaffold's group, Tab past Save plan went round to Map,
    // the control highest on the screen, and skipped Back.
    testWidgets('bad-columns-mixed: Tab past Save plan goes round to Back, '
        'not to Map, while the screen scrolls', (tester) async {
      final handle = tester.ensureSemantics();
      await openShort(tester, 'bad-columns-mixed');
      final order = _tabOrder['bad-columns-mixed']!;
      expect(await _walk(tester, 'bad-columns-mixed', order.length), order);
      expect(
        tester.getRect(byId(_id('bad-columns-mixed', 'map'))).bottom,
        lessThanOrEqualTo(viewTop(tester)),
        reason: 'Map is above the screen when Save plan has focus',
      );
      expect(await _walk(tester, 'bad-columns-mixed', 2), ['back', 'map']);
      handle.dispose();
    });
  });

  group('arrow keys (Android and iOS; on the web they scroll)', () {
    // Each move: from, key, to. The arrows move by position, inside or
    // across a traversal group, the same in every example.
    const moves = [
      ('map', LogicalKeyboardKey.arrowDown, 'water'),
      ('water', LogicalKeyboardKey.arrowUp, 'map'),
      ('map', LogicalKeyboardKey.arrowRight, 'weather'),
      ('weather', LogicalKeyboardKey.arrowLeft, 'map'),
      ('weather', LogicalKeyboardKey.arrowDown, 'closures'),
      ('aid', LogicalKeyboardKey.arrowDown, 'save'),
    ];
    for (final slug in _all) {
      testWidgets('$slug: each arrow moves to the control on that side', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        for (final (from, key, to) in moves) {
          await _tabTo(tester, slug, from);
          await _key(tester, key);
          expect(_stop(tester, slug), to, reason: '$from ${key.keyLabel}');
        }
        handle.dispose();
      });
    }
  });

  group('the SDK on its own', () {
    // Two columns of three buttons of one size, with space between the
    // rows, so the rows are level and apart. [groups] puts each column in
    // a FocusTraversalGroup, [containers] in a semantics container.
    Widget columns({required bool groups, required bool containers}) {
      Widget column(String side) {
        Widget c = Column(
          spacing: 16,
          children: [
            for (var i = 1; i <= 3; i++)
              SizedBox(
                width: 120,
                height: 40,
                child: TextButton(
                  style: TextButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {},
                  child: Text('$side$i'),
                ),
              ),
          ],
        );
        if (containers) c = Semantics(container: true, child: c);
        if (groups) c = FocusTraversalGroup(child: c);
        return c;
      }

      return MaterialApp(
        home: Scaffold(
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [column('L'), column('R')],
          ),
        ),
      );
    }

    String focusedLabel(WidgetTester tester) =>
        semanticsNodes(tester)
            .where((d) => d.flagsCollection.isFocused == Tristate.isTrue)
            .map((d) => d.label)
            .single;

    Future<List<String>> tabs(WidgetTester tester) async {
      final out = <String>[];
      for (var i = 0; i < 6; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        out.add(focusedLabel(tester));
      }
      return out;
    }

    List<String> reading(WidgetTester tester) => [
      for (final label in _readingFrom(tester))
        if (RegExp(r'^[LR]\d$').hasMatch(label)) label,
    ];

    const rows = ['L1', 'R1', 'L2', 'R2', 'L3', 'R3'];
    const cols = ['L1', 'L2', 'L3', 'R1', 'R2', 'R3'];

    // FL-420: the default order is by position, and a traversal group and
    // a semantics container each fix one order and not the other. Written
    // to fail if either starts to do the other's job.
    for (final (groups, containers, tab, read) in [
      (false, false, rows, rows),
      (true, false, cols, rows),
      (false, true, rows, cols),
      (true, true, cols, cols),
    ]) {
      testWidgets('FL-420: groups $groups, containers $containers: Tab goes '
          '${tab == cols ? 'by column' : 'by row'}, a screen reader '
          '${read == cols ? 'by column' : 'by row'}', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          columns(groups: groups, containers: containers),
        );
        await tester.pumpAndSettle();
        expect(await tabs(tester), tab);
        expect(reading(tester), read);
        handle.dispose();
      });
    }

    // A screen with an app bar and twelve buttons in a scrolling list, on a
    // screen that shows about six. [grouped] puts the scrolling list
    // inside a FocusTraversalGroup.
    Widget scrolledList({required bool grouped}) {
      Widget body = SingleChildScrollView(
        child: Column(
          children: [
            for (var i = 1; i <= 12; i++)
              SizedBox(
                height: 48,
                child: TextButton(onPressed: () {}, child: Text('B$i')),
              ),
          ],
        ),
      );
      if (grouped) body = FocusTraversalGroup(child: body);
      return MaterialApp(
        initialRoute: '/list',
        routes: {
          '/': (_) => const Scaffold(),
          '/list': (_) => Scaffold(
            appBar: AppBar(title: const Text('List')),
            body: body,
          ),
        },
      );
    }

    Future<List<String>> press(
      WidgetTester tester,
      int n, {
      bool shift = false,
    }) async {
      final out = <String>[];
      for (var i = 0; i < n; i++) {
        if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pumpAndSettle();
        out.add(
          semanticsNodes(tester)
              .where((d) => d.flagsCollection.isFocused == Tristate.isTrue)
              .map((d) => d.tooltip == 'Back' ? 'Back' : d.label)
              .single,
        );
      }
      return out;
    }

    final list = [for (var i = 1; i <= 12; i++) 'B$i'];

    // FL-422: on a scrolled screen the default order, which is by position
    // on the screen, puts the app bar's Back button among the controls
    // scrolled out of view above. Written to fail when Back stops coming
    // between them.
    testWidgets('FL-422: on a scrolled screen Back comes between the '
        'buttons, and Tab past the end skips it', (tester) async {
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(scrolledList(grouped: false));
      await tester.pumpAndSettle();
      // Down the list in order, from Back, while nothing is scrolled away.
      expect(await press(tester, 13), ['Back', ...list]);
      // Past the end: round to B1, which is higher on the screen than Back
      // once the list has scrolled, so Back is skipped.
      expect(await press(tester, 1), ['B1']);
      // On down again, Back comes between B5 and B6.
      expect(await press(tester, 11), [
        ...list.sublist(1, 5),
        'Back',
        ...list.sublist(5, 11),
      ]);
      // And back up, Back comes between every two buttons from B6 on.
      expect(await press(tester, 14, shift: true), [
        ...['B10', 'B9', 'B8', 'B7', 'B6'],
        ...['Back', 'B5', 'Back', 'B4', 'Back', 'B3', 'Back', 'B2', 'Back'],
      ]);
      handle.dispose();
    });

    // The workaround: a FocusTraversalGroup around the scrolling list. The
    // group is sorted by its own rectangle, the part of the screen the list
    // shows, which is always below the app bar.
    testWidgets('FL-422 workaround: with the scrolling list in a '
        'FocusTraversalGroup, Back comes only before B1', (tester) async {
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(scrolledList(grouped: true));
      await tester.pumpAndSettle();
      expect(await press(tester, 14), ['Back', ...list, 'Back']);
      expect(await press(tester, 12), list);
      expect(await press(tester, 13, shift: true), [
        ...list.reversed.skip(1),
        'Back',
        'B12',
      ]);
      handle.dispose();
    });

    testWidgets('OrderedTraversalPolicy puts a control with no order after '
        'every control with one', (tester) async {
      final handle = tester.ensureSemantics();
      Widget numbered(double? n, String label) {
        final button = TextButton(onPressed: () {}, child: Text(label));
        return n == null
            ? button
            : FocusTraversalOrder(order: NumericFocusOrder(n), child: button);
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: Column(
                children: [
                  numbered(1, 'A'),
                  numbered(null, 'B'),
                  numbered(2, 'C'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final out = <String>[];
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        out.add(focusedLabel(tester));
      }
      expect(out, ['A', 'C', 'B']);
      handle.dispose();
    });
  });
}
