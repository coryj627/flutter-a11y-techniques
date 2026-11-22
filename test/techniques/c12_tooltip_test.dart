import 'dart:math' as math;
import 'dart:ui'
    show
        PointerDeviceKind,
        Tristate,
        ViewFocusDirection,
        ViewFocusEvent,
        ViewFocusState;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/app/screens.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/c12_tooltip/c12_tooltip.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/examples.dart';

/// L1 for C12 Tooltip (docs/specs/C12-tooltip.md, section 6). The tests
/// run as Android. A tooltip's timing is in frames: [_frames] pumps them
/// 16 ms apart, as a running app draws them, because one pump of the whole
/// time runs the timers and not the animations they start
/// (docs/evidence/probes/c12/README.md).
final _open = exampleOpener(c12Tooltip);

const _good = ['good-material', 'good-cupertino', 'good-description'];

/// The control whose tooltip each example is about.
const _control = {
  'good-material': 'c12-good-material-delete',
  'good-cupertino': 'c12-good-cupertino-delete',
  'good-description': 'c12-good-description-download',
  'bad-not-hoverable': 'c12-bad-not-hoverable-delete',
  'bad-hover-only': 'c12-bad-hover-only-info',
  'bad-repeats-name': 'c12-bad-repeats-name-download',
  'bad-outside-button': 'c12-bad-outside-button-tooltip',
};

/// The words each tooltip draws.
const _tip = {
  'good-material': 'Delete draft',
  'good-cupertino': 'Delete draft',
  'good-description': 'Saves a PDF copy',
  'bad-not-hoverable': 'Delete draft',
  'bad-hover-only': 'At least 8 characters',
  'bad-repeats-name': 'Download',
  'bad-outside-button': 'Delete draft',
};

/// The line of text under each good example's control.
const _line = {
  'good-material': 'Drafts are kept for 30 days.',
  'good-cupertino': 'Drafts are kept for 30 days.',
  'good-description': 'The file is 2 MB.',
};

Future<void> _frames(WidgetTester tester, Duration d) async {
  final end = tester.binding.clock.now().add(d);
  while (tester.binding.clock.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// The paragraphs that draw [slug]'s tooltip: text with the tooltip's words
/// inside Material's tooltip box (`_TooltipBox`), not the control's own
/// (bad-repeats-name's button says the same words).
Iterable<Element> _tipParagraphs(WidgetTester tester, String slug) =>
    find.byType(RichText).evaluate().where((e) {
      final text = (e.widget as RichText).text.toPlainText();
      if (text != _tip[slug]) return false;
      return find
          .ancestor(
            of: find.byWidget(e.widget),
            matching: find.byWidgetPredicate(
              (w) => w.runtimeType.toString() == '_TooltipBox',
            ),
          )
          .evaluate()
          .isNotEmpty;
    });

/// Whether [slug]'s tooltip is drawn: its text is laid out, and not faded
/// out.
bool _shown(WidgetTester tester, String slug) {
  for (final e in _tipParagraphs(tester, slug)) {
    final fade = find.ancestor(
      of: find.byWidget(e.widget),
      matching: find.byType(FadeTransition),
    );
    final visible = fade.evaluate().every(
      (f) => (f.widget as FadeTransition).opacity.value > 0,
    );
    if (visible) return true;
  }
  return false;
}

/// The tooltip's box on screen.
Rect _tipRect(WidgetTester tester, String slug) {
  final e = _tipParagraphs(tester, slug).first;
  final box = e.renderObject! as RenderBox;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// The centre of the control. bad-outside-button's identifier is on a
/// container the width of the example: its button is found by type.
Offset _controlCentre(WidgetTester tester, String slug) => switch (slug) {
  'bad-outside-button' => tester.getCenter(find.byType(IconButton)),
  _ => tester.getCenter(byId(_control[slug]!)),
};

Rect _controlRect(WidgetTester tester, String slug) => switch (slug) {
  'bad-outside-button' => tester.getRect(find.byType(IconButton)),
  _ => tester.getRect(byId(_control[slug]!)),
};

/// A mouse, added away from the example, removed at the end of the test.
Future<TestGesture> _mouse(WidgetTester tester) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: const Offset(1, 1));
  addTearDown(mouse.removePointer);
  return mouse;
}

/// Moves [mouse] from where it is to [to] in ten steps, a frame apart.
Future<void> _glide(
  WidgetTester tester,
  TestGesture mouse,
  Offset from,
  Offset to,
) async {
  for (var i = 1; i <= 10; i++) {
    await mouse.moveTo(Offset.lerp(from, to, i / 10)!);
    await tester.pump(const Duration(milliseconds: 16));
  }
}

bool _focused(String id) =>
    dataById(id).flagsCollection.isFocused == Tristate.isTrue;

/// Every node on the screen whose name, tooltip, or hint has [text], merged
/// nodes included.
List<SemanticsData> _nodesWith(WidgetTester tester, String text) => [
  for (final n in semanticsNodes(tester, includeMerged: true))
    if (n.label.contains(text) ||
        n.tooltip.contains(text) ||
        n.hint.contains(text))
      n,
];

/// The view loses focus, as on the web when the page itself has none: the
/// framework parks focus on the root scope, above `WidgetsApp` (FL-482).
Future<void> _viewLosesFocus(WidgetTester tester) async {
  tester.binding.handleViewFocusChanged(
    ViewFocusEvent(
      viewId: tester.view.viewId,
      state: ViewFocusState.unfocused,
      direction: ViewFocusDirection.undefined,
    ),
  );
  await tester.pumpAndSettle();
  expect(FocusManager.instance.primaryFocus, FocusManager.instance.rootScope);
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// The colour of the focus outline of [slug]'s control when focused, as
/// each example sets it.
Color _ringColour(WidgetTester tester, String slug) {
  final control = byId(_control[slug]!);
  switch (slug) {
    case 'good-cupertino':
      return tester
          .widget<CupertinoButton>(
            find.descendant(
              of: control,
              matching: find.byType(CupertinoButton),
            ),
          )
          .focusColor!;
    default:
      final style = tester
          .widget<ButtonStyleButton>(
            find.descendant(
              of: control,
              matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
            ),
          )
          .style!;
      return style.side!.resolve({WidgetState.focused})!.color;
  }
}

void main() {
  test('the technique has the examples named in the spec', () {
    expect(c12Tooltip.examples.map((e) => e.slug), [
      ..._good,
      'bad-not-hoverable',
      'bad-hover-only',
      'bad-repeats-name',
      'bad-outside-button',
    ]);
    expect(_good, [
      for (final e in c12Tooltip.examples)
        if (e.kind == ExampleKind.good) e.slug,
    ]);
  });

  group('good examples', () {
    for (final slug in _good) {
      final id = _control[slug]!;
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

        // Shown by a hover, with keyboard focus on the control: the
        // tooltip's text, the control with its focus outline, and the line
        // under it must all keep their contrast.
        testWidgets('$slug: with focus on the control and its tooltip shown '
            'the text meets the contrast guideline (${brightness.name})', (
          tester,
        ) async {
          final handle = tester.ensureSemantics();
          await _open(tester, slug, brightness: brightness);
          await tabTo(tester, id);
          final mouse = await _mouse(tester);
          await mouse.moveTo(_controlCentre(tester, slug));
          await tester.pumpAndSettle();
          expect(_shown(tester, slug), isTrue);
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          handle.dispose();
        });

        testWidgets('$slug: the focus outline is 3:1 or more on the page '
            '(${brightness.name})', (tester) async {
          await _open(tester, slug, brightness: brightness);
          final page = Theme.of(tester.element(byId(id))).colorScheme.surface;
          expect(
            _contrast(_ringColour(tester, slug), page),
            greaterThanOrEqualTo(3),
          );
        });
      }

      testWidgets('$slug: the tooltip\'s words are on the control, once', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        final data = dataById(id);
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.hasAction(SemanticsAction.tap), isTrue);
        expect(
          (data.label, data.tooltip, data.hint),
          switch (slug) {
            'good-material' => ('Delete draft', '', ''),
            'good-cupertino' => ('', 'Delete draft', ''),
            _ => ('Download', 'Saves a PDF copy', ''),
          },
        );
        expect(
          [
            for (final n in semanticsNodes(tester))
              if ('${n.label}|${n.tooltip}|${n.hint}'.contains(_tip[slug]!))
                n.identifier,
          ],
          [id],
        );
        handle.dispose();
      });

      // FL-249: while the tooltip is shown, its text is a node of its own,
      // in traversal order inside the control. Written to fail when that
      // changes.
      testWidgets('$slug: while shown, the tooltip\'s text is a node of its '
          'own inside the control (FL-249)', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        final mouse = await _mouse(tester);
        await mouse.moveTo(_controlCentre(tester, slug));
        await tester.pumpAndSettle();
        expect(_shown(tester, slug), isTrue);
        final control = nodeById(id).evaluate().single;
        expect(_textInTraversal(control, _tip[slug]!), isTrue);
        handle.dispose();
      });

      testWidgets('$slug: a hover shows the tooltip, and it stays while '
          'hovered, ten seconds', (tester) async {
        await _open(tester, slug);
        expect(_shown(tester, slug), isFalse);
        final mouse = await _mouse(tester);
        await mouse.moveTo(_controlCentre(tester, slug));
        await _frames(tester, const Duration(milliseconds: 300));
        expect(_shown(tester, slug), isTrue);
        await _frames(tester, const Duration(seconds: 10));
        expect(_shown(tester, slug), isTrue);
        await mouse.moveTo(const Offset(1, 1));
        await _frames(tester, const Duration(milliseconds: 400));
        expect(_shown(tester, slug), isFalse, reason: 'the pointer left');
      });

      // 1.4.13's dismissible condition has an exception for content that
      // "does not obscure or replace other content". This tooltip covers
      // other text in every layout measured: under the control when there
      // is room below it (the line under it), above it when there is not
      // (Material's positionDependentBox flips it; at 200% on a phone the
      // control is low on the screen). Each reading is printed (C12GEOM)
      // with every text the box lies over, for the spec.
      for (final (width, scale) in [(800.0, 1.0), (320.0, 1.0), (320.0, 2.0)]) {
        testWidgets('$slug: the shown tooltip lies over other text on the '
            'screen ($width wide, ${scale * 100}% text)', (tester) async {
          tester.view.physicalSize = Size(width, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await _open(tester, slug, textScale: scale);
          final mouse = await _mouse(tester);
          await mouse.moveTo(_controlCentre(tester, slug));
          await tester.pumpAndSettle();
          expect(_shown(tester, slug), isTrue);
          final boxFinder = find
              .byWidgetPredicate(
                (w) => w.runtimeType.toString() == '_TooltipBox',
              )
              .first;
          final box = tester.getRect(boxFinder);
          // Every text on the screen outside the tooltip and the control,
          // and how much of it the box covers.
          final covered = <String>[];
          for (final e in find.byType(RichText).evaluate()) {
            final inBox = find
                .ancestor(of: find.byWidget(e.widget), matching: boxFinder)
                .evaluate()
                .isNotEmpty;
            if (inBox) continue;
            final text = (e.widget as RichText).text.toPlainText();
            final r = tester.getRect(find.byWidget(e.widget));
            final o = box.intersect(r);
            if (o.width > 0 && o.height > 0) {
              covered.add(
                '"$text" (${o.width.toStringAsFixed(0)} by '
                '${o.height.toStringAsFixed(0)} of '
                '${r.width.toStringAsFixed(0)} by ${r.height.toStringAsFixed(0)})',
              );
            }
          }
          final control = _controlRect(tester, slug);
          final below = box.top >= control.center.dy;
          // Positive: a gap between the control and the box; negative: the
          // box over the control's edge (FL-250).
          final gap = below
              ? box.top - control.bottom
              : control.top - box.bottom;
          debugPrint(
            'C12GEOM $slug ${width}x640 ${scale * 100}%: control $control, '
            'tooltip box $box (${below ? 'below' : 'above'} the control, '
            '${gap < 0 ? 'over its edge by ${(-gap).toStringAsFixed(1)}' : 'a gap of ${gap.toStringAsFixed(1)}'}), '
            'covers ${covered.join(', ')}',
          );
          expect(gap, greaterThanOrEqualTo(0), reason: 'not over the control');
          expect(covered, isNotEmpty, reason: 'the box lies over other text');
          if (box.top >= control.center.dy) {
            expect(
              covered.any((c) => c.startsWith('"${_line[slug]}"')),
              isTrue,
              reason: 'below the control, it covers the line under it',
            );
          }
        });
      }

      // FL-250: where the box lay over the control's edge, Escape with the
      // pointer there hid it for a few frames and the hover showed it again
      // (docs/evidence/probes/c12/flutter_test_overlap.txt, good-cupertino
      // before verticalOffset). With the pointer 0.5 inside the tooltip's
      // edge nearest the control, and 0.5 inside the control's edge nearest
      // the tooltip, below it and flipped above it, Escape hides it and it
      // stays hidden for 30 frames.
      for (final (width, scale) in [(800.0, 1.0), (320.0, 2.0)]) {
        for (final edge in ['tooltip', 'control']) {
          testWidgets('$slug: with the pointer at the $edge\'s edge nearest '
              'the other, Escape hides the tooltip and it stays hidden '
              '($width wide, ${scale * 100}% text)', (tester) async {
            tester.view.physicalSize = Size(width, 640);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await _open(tester, slug, textScale: scale);
            final mouse = await _mouse(tester);
            final control = _controlRect(tester, slug);
            await mouse.moveTo(control.center);
            await tester.pumpAndSettle();
            final box = tester.getRect(
              find
                  .byWidgetPredicate(
                    (w) => w.runtimeType.toString() == '_TooltipBox',
                  )
                  .first,
            );
            final below = box.top >= control.center.dy;
            final y = switch ((edge, below)) {
              ('tooltip', true) => box.top + 0.5,
              ('tooltip', false) => box.bottom - 0.5,
              (_, true) => control.bottom - 0.5,
              (_, false) => control.top + 0.5,
            };
            await mouse.moveTo(Offset(control.center.dx, y));
            await tester.pumpAndSettle();
            expect(_shown(tester, slug), isTrue);
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            final seen = <bool>[];
            for (var i = 0; i < 30; i++) {
              await tester.pump(const Duration(milliseconds: 16));
              seen.add(_shown(tester, slug));
            }
            expect(seen.skip(10), everyElement(isFalse), reason: '$seen');
          });
        }
      }

      testWidgets('$slug: the pointer can move onto the tooltip, and it '
          'stays there', (tester) async {
        await _open(tester, slug);
        final mouse = await _mouse(tester);
        final from = _controlCentre(tester, slug);
        await mouse.moveTo(from);
        await _frames(tester, const Duration(milliseconds: 300));
        expect(_shown(tester, slug), isTrue);
        final to = _tipRect(tester, slug).center;
        expect(_controlRect(tester, slug).contains(to), isFalse);
        await _glide(tester, mouse, from, to);
        await _frames(tester, const Duration(milliseconds: 500));
        expect(_shown(tester, slug), isTrue);
        await _frames(tester, const Duration(seconds: 5));
        expect(_shown(tester, slug), isTrue);
      });

      // FL-248: no Flutter tooltip shows on keyboard focus. Written to fail
      // when that changes.
      testWidgets('$slug: keyboard focus does not show the tooltip; a hover '
          'in the same launch does (FL-248)', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await tabTo(tester, id);
        await _frames(tester, const Duration(seconds: 3));
        expect(_focused(id), isTrue);
        expect(_shown(tester, slug), isFalse);
        final mouse = await _mouse(tester);
        await mouse.moveTo(_controlCentre(tester, slug));
        await _frames(tester, const Duration(milliseconds: 300));
        expect(_shown(tester, slug), isTrue, reason: 'positive control');
        handle.dispose();
      });

      testWidgets('$slug: with focus in the app, Escape hides the tooltip, '
          'with the pointer on the control and on the tooltip', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await tabTo(tester, id);
        final mouse = await _mouse(tester);
        final from = _controlCentre(tester, slug);
        await mouse.moveTo(from);
        await _frames(tester, const Duration(milliseconds: 300));
        expect(_shown(tester, slug), isTrue);
        expect(await tester.sendKeyEvent(LogicalKeyboardKey.escape), isTrue);
        await _frames(tester, const Duration(milliseconds: 300));
        expect(_shown(tester, slug), isFalse, reason: 'on the control');
        expect(_focused(id), isTrue, reason: 'focus stays');
        await _frames(tester, const Duration(seconds: 2));
        expect(_shown(tester, slug), isFalse, reason: 'it does not come back');
        // Leave and come back: the hover shows it again; then onto it.
        await mouse.moveTo(const Offset(1, 1));
        await _frames(tester, const Duration(milliseconds: 300));
        await mouse.moveTo(from);
        await _frames(tester, const Duration(milliseconds: 300));
        expect(_shown(tester, slug), isTrue, reason: 'shown again');
        await _glide(tester, mouse, from, _tipRect(tester, slug).center);
        await _frames(tester, const Duration(milliseconds: 300));
        expect(_shown(tester, slug), isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await _frames(tester, const Duration(milliseconds: 300));
        expect(_shown(tester, slug), isFalse, reason: 'on the tooltip');
        handle.dispose();
      });

      // FL-482: with focus parked above WidgetsApp, as on the web when the
      // page has no focus, Escape hides nothing. Written to fail when that
      // changes.
      testWidgets('$slug: while the view has no focus, Escape does not hide '
          'the tooltip (FL-482)', (tester) async {
        await _open(tester, slug);
        await _viewLosesFocus(tester);
        final mouse = await _mouse(tester);
        await mouse.moveTo(_controlCentre(tester, slug));
        await _frames(tester, const Duration(milliseconds: 300));
        expect(_shown(tester, slug), isTrue);
        expect(await tester.sendKeyEvent(LogicalKeyboardKey.escape), isFalse);
        await _frames(tester, const Duration(milliseconds: 300));
        expect(_shown(tester, slug), isTrue);
      });

      testWidgets('$slug: a long press shows the tooltip, which goes 1.5 s '
          'after the touch ends', (tester) async {
        await _open(tester, slug);
        final touch = await tester.startGesture(_controlCentre(tester, slug));
        await _frames(tester, const Duration(milliseconds: 700));
        expect(_shown(tester, slug), isTrue);
        await touch.up();
        await _frames(tester, const Duration(milliseconds: 1300));
        expect(_shown(tester, slug), isTrue, reason: '1.3 s after');
        await _frames(tester, const Duration(milliseconds: 500));
        expect(_shown(tester, slug), isFalse, reason: '1.8 s after');
        expect(
          countOf(tester, 'c12-$slug-count'),
          0,
          reason: 'a long press does not activate',
        );
      });

      testWidgets('$slug: a tap, the tap action, Enter, and Space each '
          'activate the control once', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        final count = 'c12-$slug-count';
        await tester.tap(byId(id));
        await tester.pumpAndSettle();
        expect(countOf(tester, count), 1);
        tester.semantics.tap(nodeById(id));
        await tester.pumpAndSettle();
        expect(countOf(tester, count), 2);
        await tabTo(tester, id);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(countOf(tester, count), 3);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(countOf(tester, count), 4);
        handle.dispose();
      });

      testWidgets('$slug: Tab goes Back, then the control', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        final stops = <String>[];
        for (var i = 0; i < 2; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          stops.add(_focusedStop(tester));
        }
        expect(stops, ['Back', id]);
        handle.dispose();
      });

      testWidgets('$slug: at 200% text on a phone the tooltip is drawn whole, '
          'inside the screen, scaled once', (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await _open(tester, slug, textScale: 2);
        final mouse = await _mouse(tester);
        await mouse.moveTo(_controlCentre(tester, slug));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(_shown(tester, slug), isTrue);
        for (final e in _tipParagraphs(tester, slug)) {
          final p = e.renderObject! as RenderParagraph;
          expect(p.didExceedMaxLines, isFalse);
          final r = _tipRect(tester, slug);
          expect(r.left, greaterThanOrEqualTo(0));
          expect(r.right, lessThanOrEqualTo(320));
          // The tooltip's font is 14 on Android.
          final line = p
              .getBoxesForSelection(
                const TextSelection(baseOffset: 0, extentOffset: 1),
              )
              .first
              .toRect();
          final onScreen = MatrixUtils.transformRect(
            p.getTransformTo(null),
            line,
          ).height;
          expect(onScreen, greaterThanOrEqualTo(14 * 2), reason: 'scaled');
          expect(onScreen, lessThan(14 * 4), reason: 'scaled once');
        }
      });
    }
  });

  // Every example, good and bad: at 200% text on a 320 by 640 screen no
  // layout overflows, and no text in the example is cut short, by a line
  // limit or by a box too small for its lines.
  for (final example in c12Tooltip.examples) {
    final slug = example.slug;
    testWidgets('$slug: at 200% text on a phone nothing overflows and no '
        'text is cut short', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _open(tester, slug, textScale: 2);
      expect(tester.takeException(), isNull);
      final widget = example.builder(
        tester.element(find.byType(ExampleScreen)),
      );
      final paragraphs = tester.renderObjectList<RenderParagraph>(
        find.descendant(
          of: find.byType(widget.runtimeType),
          matching: find.byType(RichText),
        ),
      );
      expect(paragraphs, isNotEmpty);
      for (final p in paragraphs) {
        final text = p.text.toPlainText();
        expect(
          p.didExceedMaxLines,
          isFalse,
          reason: '"$text" hit its line limit',
        );
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
        expect(
          right,
          lessThanOrEqualTo(320.5),
          reason: '"$text" runs off the screen',
        );
      }
    });
  }

  group('bad examples have their defect', () {
    testWidgets('bad-not-hoverable: the tooltip goes when the pointer moves '
        'onto it', (tester) async {
      const slug = 'bad-not-hoverable';
      await _open(tester, slug);
      final mouse = await _mouse(tester);
      final from = _controlCentre(tester, slug);
      await mouse.moveTo(from);
      await _frames(tester, const Duration(milliseconds: 300));
      // The positive control: the same hover shows it.
      expect(_shown(tester, slug), isTrue);
      final to = _tipRect(tester, slug).center;
      expect(_controlRect(tester, slug).contains(to), isFalse);
      await _glide(tester, mouse, from, to);
      await _frames(tester, const Duration(milliseconds: 500));
      expect(_shown(tester, slug), isFalse);
      // Back on the button, it shows again.
      await _glide(tester, mouse, to, from);
      await _frames(tester, const Duration(milliseconds: 300));
      expect(_shown(tester, slug), isTrue);
    });

    testWidgets('bad-not-hoverable: the tooltip is the button\'s name, as in '
        'good-cupertino', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-not-hoverable');
      final data = dataById(_control['bad-not-hoverable']!);
      expect(data.flagsCollection.isButton, isTrue);
      expect((data.label, data.tooltip), ('', 'Delete draft'));
      handle.dispose();
    });

    testWidgets('bad-hover-only: no key shows the rule; a hover and a long '
        'press do', (tester) async {
      const slug = 'bad-hover-only';
      final handle = tester.ensureSemantics();
      await _open(tester, slug);
      final info = dataById(_control[slug]!);
      expect((info.label, info.tooltip), ('', 'At least 8 characters'));
      expect(info.flagsCollection.isFocused, Tristate.none);
      expect(info.flagsCollection.isButton, isFalse);
      expect(info.hasAction(SemanticsAction.tap), isFalse);
      // Every Tab stop, and Enter and Space: never the icon, and the
      // tooltip never shows. Sign up is the positive control for the keys.
      final stops = <String>[];
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await _frames(tester, const Duration(milliseconds: 300));
        stops.add(_focusedStop(tester));
        expect(_shown(tester, slug), isFalse, reason: 'after Tab $i');
      }
      expect(stops, [
        'Back',
        'c12-bad-hover-only-sign-up',
        'Back',
        'c12-bad-hover-only-sign-up',
      ]);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _frames(tester, const Duration(milliseconds: 300));
      expect(countOf(tester, 'c12-bad-hover-only-count'), 1);
      expect(_shown(tester, slug), isFalse, reason: 'after Enter');
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await _frames(tester, const Duration(milliseconds: 300));
      expect(countOf(tester, 'c12-bad-hover-only-count'), 2);
      expect(_shown(tester, slug), isFalse, reason: 'after Space');
      // The positive controls for the tooltip: a hover and a long press.
      final mouse = await _mouse(tester);
      await mouse.moveTo(_controlCentre(tester, slug));
      await _frames(tester, const Duration(milliseconds: 300));
      expect(_shown(tester, slug), isTrue, reason: 'hover');
      await mouse.moveTo(const Offset(1, 1));
      await _frames(tester, const Duration(milliseconds: 400));
      expect(_shown(tester, slug), isFalse);
      final touch = await tester.startGesture(_controlCentre(tester, slug));
      await _frames(tester, const Duration(milliseconds: 700));
      expect(_shown(tester, slug), isTrue, reason: 'long press');
      await touch.up();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      handle.dispose();
    });

    testWidgets('bad-repeats-name: the button\'s name and its tooltip are '
        'the same words', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-repeats-name');
      final data = dataById(_control['bad-repeats-name']!);
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.label, 'Download');
      expect(data.tooltip, 'Download');
      handle.dispose();
    });

    testWidgets('bad-outside-button: the tooltip is on a node of its own, '
        'and the button has no name', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-outside-button');
      final outer = dataById(_control['bad-outside-button']!);
      expect(outer.tooltip, 'Delete draft');
      expect(outer.flagsCollection.isButton, isFalse);
      expect(outer.hasAction(SemanticsAction.tap), isFalse);
      final buttons = [
        for (final n in semanticsNodes(tester))
          if (n.flagsCollection.isButton && n.tooltip != 'Back') n,
      ];
      expect(buttons, hasLength(1));
      expect(
        (buttons.single.label, buttons.single.tooltip, buttons.single.hint),
        ('', '', ''),
      );
      expect(buttons.single.hasAction(SemanticsAction.tap), isTrue);
      handle.dispose();
    });
  });

  // What the SDK does by itself, behind the limitation entries.
  group('the SDK alone', () {
    Future<void> pumpTip(WidgetTester tester, Widget child) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Center(child: child)),
        ),
      );
      await tester.pumpAndSettle();
    }

    bool shownText(WidgetTester tester, String text) => find
        .byWidgetPredicate((w) => w is RichText && w.text.toPlainText() == text)
        .evaluate()
        .isNotEmpty;

    // FL-247.
    for (final (name, widget) in [
      (
        'IconButton(tooltip:)',
        IconButton(
          tooltip: 'Close',
          onPressed: () {},
          icon: const Icon(Icons.close),
        ),
      ),
      (
        'Tooltip(message:)',
        Tooltip(
          message: 'Close',
          child: IconButton(onPressed: () {}, icon: const Icon(Icons.close)),
        ),
      ),
    ]) {
      testWidgets('$name: the tooltip goes when the pointer moves onto it', (
        tester,
      ) async {
        await pumpTip(tester, widget);
        final mouse = await _mouse(tester);
        final from = tester.getCenter(find.byType(IconButton));
        await mouse.moveTo(from);
        await _frames(tester, const Duration(milliseconds: 300));
        expect(shownText(tester, 'Close'), isTrue);
        final tip = tester.getRect(
          find.byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText() == 'Close',
          ),
        );
        await _glide(tester, mouse, from, tip.center);
        await _frames(tester, const Duration(milliseconds: 500));
        expect(shownText(tester, 'Close'), isFalse);
      });

      // FL-248.
      testWidgets('$name: keyboard focus does not show the tooltip', (
        tester,
      ) async {
        await pumpTip(tester, widget);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await _frames(tester, const Duration(milliseconds: 500));
        expect(
          FocusManager.instance.primaryFocus?.context
              ?.findAncestorWidgetOfExactType<IconButton>(),
          isNotNull,
        );
        expect(shownText(tester, 'Close'), isFalse);
        // The positive control: a hover shows it.
        final mouse = await _mouse(tester);
        await mouse.moveTo(tester.getCenter(find.byType(IconButton)));
        await _frames(tester, const Duration(milliseconds: 300));
        expect(shownText(tester, 'Close'), isTrue);
      });
    }

    testWidgets('Tooltip(richMessage:) or ignorePointer: false: the pointer '
        'can move onto the tooltip', (tester) async {
      for (final widget in [
        Tooltip(
          richMessage: const TextSpan(text: 'Close'),
          child: IconButton(onPressed: () {}, icon: const Icon(Icons.close)),
        ),
        Tooltip(
          message: 'Close',
          ignorePointer: false,
          child: IconButton(onPressed: () {}, icon: const Icon(Icons.close)),
        ),
      ]) {
        await pumpTip(tester, widget);
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: const Offset(1, 1));
        final from = tester.getCenter(find.byType(IconButton));
        await mouse.moveTo(from);
        await _frames(tester, const Duration(milliseconds: 300));
        final tip = tester.getRect(
          find.byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText() == 'Close',
          ),
        );
        await _glide(tester, mouse, from, tip.center);
        await _frames(tester, const Duration(milliseconds: 500));
        expect(shownText(tester, 'Close'), isTrue);
        await mouse.removePointer();
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      }
    });

    // FL-249: while shown, the tooltip's text is a node inside the control
    // in traversal order, though not its child in the tree.
    testWidgets('IconButton(tooltip:): while shown, its text is a node inside '
        'the button', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpTip(
        tester,
        IconButton(
          tooltip: 'Close',
          onPressed: () {},
          icon: const Icon(Icons.close),
        ),
      );
      List<SemanticsData> withClose() => _nodesWith(tester, 'Close');
      expect(withClose().map((d) => (d.label, d.tooltip)), [('', 'Close')]);
      final mouse = await _mouse(tester);
      await mouse.moveTo(tester.getCenter(find.byType(IconButton)));
      await tester.pumpAndSettle();
      expect(shownText(tester, 'Close'), isTrue);
      expect(withClose().map((d) => (d.label, d.tooltip)), [
        ('', 'Close'),
        ('Close', ''),
      ]);
      SemanticsNode? buttonOf(SemanticsNode n) {
        if (n.getSemanticsData().flagsCollection.isButton) return n;
        SemanticsNode? found;
        n.visitChildren((c) {
          found ??= buttonOf(c);
          return true;
        });
        return found;
      }

      final button = buttonOf(
        tester
            .binding
            .renderViews
            .first
            .owner!
            .semanticsOwner!
            .rootSemanticsNode!,
      )!;
      expect(button.tooltip, 'Close');
      expect(button.childrenCount, 0, reason: 'not its child in the tree');
      expect(_textInTraversal(button, 'Close'), isTrue);
      handle.dispose();
    });

    // FL-482.
    testWidgets('Escape with the view unfocused hides no tooltip', (
      tester,
    ) async {
      await pumpTip(
        tester,
        Tooltip(
          message: 'Close',
          child: IconButton(onPressed: () {}, icon: const Icon(Icons.close)),
        ),
      );
      await _viewLosesFocus(tester);
      final mouse = await _mouse(tester);
      await mouse.moveTo(tester.getCenter(find.byType(IconButton)));
      await _frames(tester, const Duration(milliseconds: 300));
      expect(shownText(tester, 'Close'), isTrue);
      expect(await tester.sendKeyEvent(LogicalKeyboardKey.escape), isFalse);
      await _frames(tester, const Duration(milliseconds: 300));
      expect(shownText(tester, 'Close'), isTrue);
    });

    // FL-250: a RawTooltip is placed over its control by default.
    testWidgets('RawTooltip by default: placed over the control\'s lower half, '
        'and Escape with the pointer there does not hold', (tester) async {
      await pumpTip(
        tester,
        RawTooltip(
          semanticsTooltip: 'Close',
          tooltipBuilder: (context, animation) => Container(
            color: Colors.black,
            padding: const EdgeInsets.all(6),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
          child: CupertinoButton(
            onPressed: () {},
            child: const Icon(CupertinoIcons.delete),
          ),
        ),
      );
      final button = tester.getRect(find.byType(CupertinoButton));
      final mouse = await _mouse(tester);
      await mouse.moveTo(button.center);
      await _frames(tester, const Duration(milliseconds: 300));
      expect(shownText(tester, 'Close'), isTrue);
      final box = tester.getRect(find.byType(Container));
      expect(box.top, lessThan(button.bottom));
      expect(
        box.top,
        lessThanOrEqualTo(button.center.dy + 0.5),
        reason: 'the pointer is on the box',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      final seen = <bool>[];
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        seen.add(shownText(tester, 'Close'));
      }
      expect(seen, contains(false), reason: 'Escape hid it');
      expect(seen.last, isTrue, reason: 'and the hover showed it again');
    });
  });
}

/// Whether a node with the label [text] is below [n] in traversal order. An
/// OverlayPortal's overlay is placed where the portal is
/// (`traversalParentIdentifier`), though in the tree it is the overlay's.
bool _textInTraversal(SemanticsNode n, String text) => n
    .debugListChildrenInOrder(DebugSemanticsDumpOrder.traversalOrder)
    .any((c) => c.label == text || _textInTraversal(c, text));

/// What has keyboard focus, by identifier, else by tooltip.
String _focusedStop(WidgetTester tester) =>
    semanticsNodes(tester)
        .where((n) => n.flagsCollection.isFocused == Tristate.isTrue)
        .map((n) => n.identifier.isNotEmpty ? n.identifier : n.tooltip)
        .join('+');
