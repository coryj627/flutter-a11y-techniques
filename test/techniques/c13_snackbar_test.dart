import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/app/screens.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/c13_snackbar/c13_snackbar.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/examples.dart';

/// L1 for C13 Snackbar and transient messages (docs/specs/C13-snackbar.md,
/// section 6). The tests run as Android. Time is pumped in 100 ms frames,
/// as a running app draws them: one pump of the whole time would run the
/// ScaffoldMessenger's timer and not the animations it starts
/// (docs/evidence/probes/c13/README.md). Every check that a key or an
/// action did nothing sends it alone, and shows in the same test that the
/// same path acts.

const _good = ['good-action', 'good-message', 'good-banner'];
const _bad = [
  'bad-action-times-out',
  'bad-only-in-message',
  'bad-inline-banner',
];

/// What each example's message says.
const _message = {
  'good-action': 'Message archived',
  'good-message': 'Draft saved',
  'good-banner': 'You are offline.',
  'bad-action-times-out': 'Message archived',
  'bad-only-in-message': 'Booked. Code: K7Q2',
  'bad-inline-banner': 'You are offline.',
};

/// The line of the page each example's button changes, before and after.
const _line = {
  'good-action': ('Archived: 0', 'Archived: 1'),
  'good-message': ('Drafts saved: 0', 'Drafts saved: 1'),
  'good-banner': ('Status: online', 'Status: offline'),
  'bad-action-times-out': ('Archived: 0', 'Archived: 1'),
  'bad-only-in-message': ('Bookings: 0', 'Bookings: 1'),
  'bad-inline-banner': ('Status: online', 'Status: offline'),
};

String _show(String slug) => 'c13-$slug-show';

Future<void> _open(
  WidgetTester tester,
  String slug, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
  bool accessibleNavigation = false,
}) => openExample(
  tester,
  c13Snackbar,
  slug,
  brightness: brightness,
  textScale: textScale,
  accessibilityFeatures: FakeAccessibilityFeatures(
    accessibleNavigation: accessibleNavigation,
  ),
);

/// Pumps [d] in 100 ms frames.
Future<void> _frames(WidgetTester tester, Duration d) async {
  final end = tester.binding.clock.now().add(d);
  while (tester.binding.clock.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Presses the example's button with a tap, and lets the message come in.
Future<void> _press(WidgetTester tester, String slug) async {
  await tester.tap(byId(_show(slug)));
  await _frames(tester, const Duration(seconds: 1));
}

/// Whether the example's message is on the screen.
bool _shown(String slug) => find.text(_message[slug]!).evaluate().isNotEmpty;

/// The line of the page under the button.
String _lineText(WidgetTester tester, String slug) => tester
    .widget<Text>(
      find.descendant(of: byId('c13-$slug-count'), matching: find.byType(Text)),
    )
    .data!;

/// Pumps until the message has gone, at most [max]; the time it took, from
/// now, or null if it is still there.
Future<Duration?> _goneAfter(
  WidgetTester tester,
  String slug, {
  Duration max = const Duration(seconds: 30),
}) async {
  final start = tester.binding.clock.now();
  while (tester.binding.clock.now().difference(start) <= max) {
    if (!_shown(slug)) return tester.binding.clock.now().difference(start);
    await tester.pump(const Duration(milliseconds: 100));
  }
  return null;
}

/// Every live region on the screen.
List<SemanticsData> _liveRegions(WidgetTester tester) => [
  for (final n in semanticsNodes(tester))
    if (n.flagsCollection.isLiveRegion) n,
];

/// The node that has keyboard focus, named by its identifier, its label,
/// or its tooltip; "(none)" when no node has it.
String _focused(WidgetTester tester) {
  for (final n in semanticsNodes(tester)) {
    if (n.flagsCollection.isFocused == Tristate.isTrue) {
      if (n.identifier.isNotEmpty) return n.identifier;
      return n.label.isNotEmpty ? n.label : n.tooltip;
    }
  }
  return '(none)';
}

/// Presses Tab [n] times and names the stop after each.
Future<List<String>> _tabs(WidgetTester tester, int n) async {
  final stops = <String>[];
  for (var i = 0; i < n; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump(const Duration(milliseconds: 100));
    stops.add(_focused(tester));
  }
  return stops;
}

/// Tabs until the stop named [name] has focus, at most eight times.
Future<void> _tabTo(WidgetTester tester, String name) async {
  for (var i = 0; i < 8; i++) {
    if (_focused(tester) == name) return;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(_focused(tester), name, reason: 'Tab did not reach $name');
}

/// The node with the dismiss action: the message's own.
SemanticsNode _dismissable(WidgetTester tester) {
  final found = <SemanticsNode>[];
  void visit(SemanticsNode n) {
    if (!n.isMergedIntoParent &&
        n.getSemanticsData().hasAction(SemanticsAction.dismiss)) {
      found.add(n);
    }
    n.visitChildren((c) {
      visit(c);
      return true;
    });
  }

  visit(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  expect(found, hasLength(1));
  return found.single;
}

double _luminance(int c) {
  double ch(int v) {
    final s = v / 255;
    return s <= 0.04045
        ? s / 12.92
        : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * ch((c >> 16) & 255) +
      0.7152 * ch((c >> 8) & 255) +
      0.0722 * ch(c & 255);
}

double _contrast(int a, int b) {
  final la = _luminance(a), lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// The screen as pixels, at one pixel per logical pixel.
Future<List<int>> _screenshot(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byType(RepaintBoundary).first,
  );
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    final bytes = data!.buffer.asUint8List();
    return [
      for (var i = 0; i < bytes.length; i += 4)
        (bytes[i] << 16) | (bytes[i + 1] << 8) | bytes[i + 2],
    ];
  }))!;
}

/// What keyboard focus changes on and within 8 of [rect], between [before]
/// and [after]: how many pixels change, and how many of them change by 3:1
/// or more (the colour focus draws against the colour that was there).
(int, int) _focusChange(
  WidgetTester tester,
  List<int> before,
  List<int> after,
  Rect rect,
) {
  final width = tester.view.physicalSize.width ~/ tester.view.devicePixelRatio;
  final r = rect.inflate(8);
  var changed = 0, strong = 0;
  for (var i = 0; i < before.length; i++) {
    if (before[i] == after[i]) continue;
    if (!r.contains(Offset(i % width + 0.5, i ~/ width + 0.5))) continue;
    changed++;
    if (_contrast(before[i], after[i]) >= 3) strong++;
  }
  return (changed, strong);
}

void main() {
  test('the technique has the examples named in the spec', () {
    expect(c13Snackbar.examples.map((e) => e.slug), [..._good, ..._bad]);
    expect(_good, [
      for (final e in c13Snackbar.examples)
        if (e.kind == ExampleKind.good) e.slug,
    ]);
    // Cupertino has no widget for a transient message (the spec, section
    // 5), and no example is built by hand.
    expect(c13Snackbar.examples.map((e) => e.variant).toSet(), {
      ExampleVariant.material,
    });
    expect(c13Snackbar.examples.where((e) => e.isCustomSolution), isEmpty);
  });

  group('good examples', () {
    for (final slug in _good) {
      for (final brightness in Brightness.values) {
        testWidgets('$slug meets the guidelines before and while its message '
            'is shown (${brightness.name})', (tester) async {
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
          await _press(tester, slug);
          expect(_shown(slug), isTrue);
          await check();
          handle.dispose();
        });

        testWidgets('$slug: with keyboard focus on each control in turn the '
            'text meets the contrast guideline (${brightness.name})', (
          tester,
        ) async {
          final handle = tester.ensureSemantics();
          await _open(tester, slug, brightness: brightness);
          await _press(tester, slug);
          final stops = {..._order[slug]!}..remove('Back');
          for (final stop in stops) {
            await _tabTo(tester, stop);
            await tester.pumpAndSettle();
            await expectLater(tester, meetsGuideline(textContrastGuideline));
          }
          handle.dispose();
        });

        testWidgets('$slug: keyboard focus draws a change of 3:1 or more on '
            'each control but the SnackBar\'s Close (${brightness.name})', (
          tester,
        ) async {
          final handle = tester.ensureSemantics();
          await _open(tester, slug, brightness: brightness);
          await _press(tester, slug);
          await tester.pumpAndSettle();
          final order = _order[slug]!;
          var shot = <int>[];
          for (var i = 0; i < order.length; i++) {
            await _tabTo(tester, order[i]);
            await tester.pumpAndSettle();
            final now = await _screenshot(tester);
            if (i > 0) {
              final (changed, strong) = _focusChange(
                tester,
                shot,
                now,
                tester.getRect(_finder(slug, order[i])),
              );
              // ignore: avoid_print
              print(
                'C13FOCUS $slug ${brightness.name} ${order[i]}: '
                '$changed pixels changed, $strong of them by 3:1 or more',
              );
              expect(changed, greaterThan(0), reason: order[i]);
              if (order[i] == 'Close') {
                // FL-294: the close icon shows focus only with a faint
                // tint, and closeIconColor does not change it. Written to
                // fail when it draws a change of 3:1.
                expect(strong, 0, reason: 'Close (FL-294)');
              } else {
                expect(strong, greaterThan(100), reason: order[i]);
              }
            }
            shot = now;
          }
          handle.dispose();
        });
      }

      testWidgets('$slug: the message is one live region, with its words '
          'and the dismiss action, and showing it moves no focus', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        expect(_liveRegions(tester), isEmpty);
        await _tabTo(tester, _show(slug));
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await _frames(tester, const Duration(seconds: 1));
        expect(_shown(slug), isTrue);
        final live = _liveRegions(tester);
        expect(live, hasLength(1));
        expect(live.single.label, _message[slug]);
        expect(live.single.hasAction(SemanticsAction.dismiss), isTrue);
        expect(_focused(tester), _show(slug), reason: 'focus stays');
        expect(_lineText(tester, slug), _line[slug]!.$2);
        handle.dispose();
      });

      testWidgets('$slug: Tab after the show reaches the message\'s controls', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await _press(tester, slug);
        final order = _order[slug]!;
        expect(await _tabs(tester, order.length + 1), [...order, order.first]);
        handle.dispose();
      });

      testWidgets('$slug: the dismiss action takes the message away', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await _press(tester, slug);
        tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
          _dismissable(tester).id,
          SemanticsAction.dismiss,
        );
        await _frames(tester, const Duration(seconds: 1));
        expect(_shown(slug), isFalse);
        handle.dispose();
      });
    }

    for (final slug in ['good-action', 'good-banner']) {
      for (final nav in [false, true]) {
        testWidgets('$slug: the message stays 30 s, with '
            'accessibleNavigation $nav', (tester) async {
          await _open(tester, slug, accessibleNavigation: nav);
          await _press(tester, slug);
          expect(await _goneAfter(tester, slug), isNull);
        });
      }
    }

    testWidgets('good-action: Enter and Space on Undo each undo, and Enter '
        'on Close closes and undoes nothing', (tester) async {
      final handle = tester.ensureSemantics();
      for (final key in [LogicalKeyboardKey.enter, LogicalKeyboardKey.space]) {
        await tester.pumpWidget(const SizedBox());
        await _open(tester, 'good-action');
        await _press(tester, 'good-action');
        expect(_lineText(tester, 'good-action'), 'Archived: 1');
        await _tabTo(tester, 'Undo');
        await tester.sendKeyEvent(key);
        await _frames(tester, const Duration(seconds: 1));
        expect(_lineText(tester, 'good-action'), 'Archived: 0', reason: '$key');
        expect(_shown('good-action'), isFalse, reason: '$key');
      }
      await tester.pumpWidget(const SizedBox());
      await _open(tester, 'good-action');
      await _press(tester, 'good-action');
      await _tabTo(tester, 'Close');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _frames(tester, const Duration(seconds: 1));
      expect(_shown('good-action'), isFalse);
      expect(_lineText(tester, 'good-action'), 'Archived: 1');
      handle.dispose();
    });

    testWidgets('good-banner: Enter on Go online closes the banner', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-banner');
      await _press(tester, 'good-banner');
      await _tabTo(tester, 'Go online');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _frames(tester, const Duration(seconds: 1));
      expect(_shown('good-banner'), isFalse);
      expect(_lineText(tester, 'good-banner'), 'Status: online');
      handle.dispose();
    });

    for (final nav in [false, true]) {
      testWidgets('good-message: the message goes after about 4 s, with '
          'accessibleNavigation $nav, and what it said stays on the page', (
        tester,
      ) async {
        await _open(tester, 'good-message', accessibleNavigation: nav);
        await _press(tester, 'good-message');
        final gone = await _goneAfter(tester, 'good-message');
        expect(gone, isNotNull);
        // _press waited a second of it.
        expect(gone!.inMilliseconds, inInclusiveRange(2900, 4500));
        expect(_lineText(tester, 'good-message'), 'Drafts saved: 1');
      });
    }
  });

  group('FL-291: Escape and Back', () {
    for (final (slug, stop) in [
      ('good-action', 'Undo'),
      ('good-banner', 'Go online'),
    ]) {
      testWidgets('$slug: Escape with focus on $stop leaves the message; '
          'Enter there, in the same launch, acts', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await _press(tester, slug);
        await _tabTo(tester, stop);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await _frames(tester, const Duration(seconds: 1));
        expect(_shown(slug), isTrue, reason: 'Escape');
        expect(_focused(tester), stop, reason: 'Escape');
        expect(_lineText(tester, slug), _line[slug]!.$2, reason: 'Escape');
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await _frames(tester, const Duration(seconds: 1));
        expect(_shown(slug), isFalse, reason: 'Enter');
        expect(_lineText(tester, slug), _line[slug]!.$1, reason: 'Enter');
        handle.dispose();
      });

      testWidgets('$slug: Back pops the example, and the message stays on '
          'the screen under it', (tester) async {
        await _open(tester, slug);
        await _press(tester, slug);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(ExampleScreen), findsNothing);
        expect(find.byType(TechniqueScreen), findsOneWidget);
        expect(_shown(slug), isTrue);
        expect(await _goneAfter(tester, slug), isNull);
        // Its action still works there, on a screen that is gone.
        await tester.tap(
          find.text(slug == 'good-action' ? 'Undo' : 'Go online'),
        );
        await _frames(tester, const Duration(seconds: 1));
        expect(_shown(slug), isFalse);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('bad examples have their defect', () {
    for (final nav in [false, true]) {
      testWidgets('bad-action-times-out: Undo goes with the message after '
          'about 4 s, with accessibleNavigation $nav (FL-290)', (tester) async {
        await _open(tester, 'bad-action-times-out', accessibleNavigation: nav);
        await _press(tester, 'bad-action-times-out');
        expect(find.text('Undo'), findsOneWidget);
        final gone = await _goneAfter(tester, 'bad-action-times-out');
        expect(gone, isNotNull);
        expect(gone!.inMilliseconds, inInclusiveRange(2900, 4500));
        expect(find.text('Undo'), findsNothing);
        expect(_lineText(tester, 'bad-action-times-out'), 'Archived: 1');
      });
    }

    testWidgets('bad-action-times-out: with keyboard focus on Undo it still '
        'goes, and focus is then on no control (FL-292)', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-action-times-out');
      await _press(tester, 'bad-action-times-out');
      await _tabTo(tester, 'Undo');
      expect(_focused(tester), 'Undo');
      expect(await _goneAfter(tester, 'bad-action-times-out'), isNotNull);
      expect(_focused(tester), '(none)');
      // The next Tab starts again from the top of the screen.
      expect(await _tabs(tester, 1), ['Back']);
      handle.dispose();
    });

    for (final nav in [false, true]) {
      testWidgets('bad-only-in-message: the code is shown, then goes after '
          'about 4 s, with accessibleNavigation $nav, and is nowhere else', (
        tester,
      ) async {
        await _open(tester, 'bad-only-in-message', accessibleNavigation: nav);
        expect(find.textContaining('K7Q2'), findsNothing);
        await _press(tester, 'bad-only-in-message');
        expect(find.textContaining('K7Q2'), findsOneWidget);
        final gone = await _goneAfter(tester, 'bad-only-in-message');
        expect(gone, isNotNull);
        expect(gone!.inMilliseconds, inInclusiveRange(2900, 4500));
        expect(find.textContaining('K7Q2'), findsNothing);
        expect(_lineText(tester, 'bad-only-in-message'), 'Bookings: 1');
      });
    }

    testWidgets('bad-only-in-message: the message is a live region with its '
        'words', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-only-in-message');
      await _press(tester, 'bad-only-in-message');
      expect(_liveRegions(tester).map((n) => n.label), ['Booked. Code: K7Q2']);
      handle.dispose();
    });

    testWidgets('bad-inline-banner: the banner is shown with no live region '
        '(FL-295); good-banner\'s, in the same test, is one', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-inline-banner');
      await _press(tester, 'bad-inline-banner');
      expect(_shown('bad-inline-banner'), isTrue);
      expect(_liveRegions(tester), isEmpty);
      // A new app, so that its initial route is read again.
      await tester.pumpWidget(const SizedBox());
      await _open(tester, 'good-banner');
      await _press(tester, 'good-banner');
      expect(_liveRegions(tester).map((n) => n.label), ['You are offline.']);
      handle.dispose();
    });

    testWidgets('bad-inline-banner: the banner is not a node with the '
        'dismiss action, and Go online closes it', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-inline-banner');
      await _press(tester, 'bad-inline-banner');
      expect(
        semanticsNodes(tester)
            .where((n) => n.hasAction(SemanticsAction.dismiss)),
        isEmpty,
      );
      await _tabTo(tester, 'Go online');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(_shown('bad-inline-banner'), isFalse);
      handle.dispose();
    });
  });

  group('FL-290: what does not change a SnackBar\'s time limit', () {
    testWidgets('accessibleNavigation turned on while the message is shown', (
      tester,
    ) async {
      await _open(tester, 'bad-action-times-out');
      await _press(tester, 'bad-action-times-out');
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(accessibleNavigation: true);
      await tester.pump();
      final gone = await _goneAfter(tester, 'bad-action-times-out');
      expect(gone, isNotNull);
      expect(gone!.inMilliseconds, lessThanOrEqualTo(4500));
    });

    testWidgets('a mouse resting on the message', (tester) async {
      await _open(tester, 'bad-action-times-out');
      await _press(tester, 'bad-action-times-out');
      final mouse = await tester.createGesture(
        kind: ui.PointerDeviceKind.mouse,
      );
      await mouse.addPointer(
        location: tester.getCenter(find.text('Message archived')),
      );
      addTearDown(mouse.removePointer);
      final gone = await _goneAfter(tester, 'bad-action-times-out');
      expect(gone, isNotNull);
      expect(gone!.inMilliseconds, lessThanOrEqualTo(4500));
    });
  });

  testWidgets('FL-293: a message shown while one that stays is shown waits, '
      'unseen, until that one is closed', (tester) async {
    final handle = tester.ensureSemantics();
    await _open(tester, 'good-action');
    await _press(tester, 'good-action');
    ScaffoldMessenger.of(tester.element(byId(_show('good-action'))))
        .showSnackBar(const SnackBar(content: Text('Second message')));
    await _frames(tester, const Duration(seconds: 10));
    expect(find.text('Second message'), findsNothing);
    expect(_shown('good-action'), isTrue);
    await tester.tap(find.byTooltip('Close'));
    await _frames(tester, const Duration(seconds: 1));
    expect(find.text('Second message'), findsOneWidget);
    expect(_liveRegions(tester).map((n) => n.label), ['Second message']);
    handle.dispose();
  });

  // Every example, with its message shown: at 200% text on a 320 by 640
  // screen no layout overflows, and no text is cut short, by a line limit
  // or by a box too small for its lines, or runs off the screen.
  for (final example in c13Snackbar.examples) {
    final slug = example.slug;
    testWidgets('$slug: at 200% text on a phone, with the message shown, '
        'nothing overflows and no text is cut short', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _open(tester, slug, textScale: 2);
      await Scrollable.ensureVisible(tester.element(byId(_show(slug))));
      await tester.pumpAndSettle();
      await _press(tester, slug);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(_shown(slug), isTrue);
      // The example's own text and its message's, not the app's title bar.
      final widget = example.builder(
        tester.element(find.byType(ExampleScreen)),
      );
      final paragraphs = [
        for (final of in [
          find.byType(widget.runtimeType),
          find.byType(SnackBar),
          find.byType(MaterialBanner),
        ])
          ...tester.renderObjectList<RenderParagraph>(
            find.descendant(of: of, matching: find.byType(RichText)),
          ),
      ];
      final texts = paragraphs.map((p) => p.text.toPlainText()).toList();
      expect(texts, contains(_message[slug]));
      for (final p in paragraphs) {
        final text = p.text.toPlainText();
        expect(p.didExceedMaxLines, isFalse, reason: '"$text" hit its limit');
        final painter = TextPainter(
          text: p.text,
          textDirection: p.textDirection,
          textScaler: p.textScaler,
          textAlign: p.textAlign,
        )..layout(maxWidth: p.size.width);
        expect(
          p.size.height,
          greaterThanOrEqualTo(painter.height - 0.5),
          reason: '"$text" is cut short in its box',
        );
        painter.dispose();
        final right = p.localToGlobal(Offset(p.size.width, 0)).dx;
        expect(right, lessThanOrEqualTo(320.5), reason: '"$text" runs off');
      }
    });
  }
}

/// The Tab stops of each good example once its message is shown, from the
/// top: Back first.
const _order = {
  'good-action': ['Back', 'c13-good-action-show', 'Undo', 'Close'],
  'good-message': ['Back', 'c13-good-message-show'],
  // The banner is above the page, in the Scaffold.
  'good-banner': ['Back', 'Go online', 'c13-good-banner-show'],
};

/// The widget of the stop named [stop].
Finder _finder(String slug, String stop) => switch (stop) {
  'Close' => find.byTooltip('Close'),
  'Undo' || 'Go online' => find.widgetWithText(TextButton, stop),
  _ => byId(stop),
};
