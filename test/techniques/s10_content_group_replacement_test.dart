import 'dart:math' as math;
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/app/screens.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/s10_content_group_replacement/examples.dart';
import 'package:flutter_a11y_techniques/techniques/s10_content_group_replacement/s10_content_group_replacement.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/examples.dart';

/// L1 for S10 Content group replacement
/// (docs/specs/S10-content-group-replacement.md, section 6). These tests
/// run as Android: `kIsWeb` is false, so what the web engine makes of a
/// node is tested in web_tests/s10_content_group_replacement.spec.js.
final _open = exampleOpener(s10ContentGroupReplacement);

const _good = ['good-exclude-semantics', 'good-hidden-pieces', 'good-stars'];
const _bad = [
  'bad-pieces',
  'bad-merged',
  'bad-not-excluded',
  'bad-hides-control',
  'bad-stale',
];

/// What the rating means, before and after one 5-star review.
final _words = startRating.words;
final _wordsAfter = startRating.plus(5).words;

/// The visible pieces of the bar row.
const _barPieces = 'Rating:\n3.4 / 5\nReviews: 856';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// The nodes of the example, in traversal order, after the "Example"
/// heading to the end of the screen: what a screen reader moves through. A
/// node merged into its parent, and a node with no label, value, or action
/// (a container), are left out.
List<SemanticsData> _exampleNodes(WidgetTester tester) {
  final all = <SemanticsData>[];
  void visit(SemanticsNode node) {
    if (!node.isMergedIntoParent) all.add(node.getSemanticsData());
    for (final child in node.debugListChildrenInOrder(
      DebugSemanticsDumpOrder.traversalOrder,
    )) {
      visit(child);
    }
  }

  visit(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  final start = all.indexWhere((n) => n.label == 'Example');
  expect(start, isNonNegative, reason: 'the Example heading');
  return [
    for (final n in all.sublist(start + 1))
      if (n.label.isNotEmpty || n.value.isNotEmpty || n.actions != 0) n,
  ];
}

/// One node as a line: its label, its value, its role, and its flags and
/// actions.
String _describe(SemanticsData n) => [
  n.label,
  if (n.value.isNotEmpty) 'value ${n.value}',
  if (n.role != SemanticsRole.none) 'role ${n.role.name}',
  if (n.flagsCollection.isButton) 'button',
  if (n.flagsCollection.isImage) 'image',
  if (n.flagsCollection.isHeader) 'header',
  if (n.hasAction(SemanticsAction.tap)) 'tap',
].join(' | ');

/// The texts of the example's own widget, as drawn.
List<RenderParagraph> _exampleParagraphs(
  WidgetTester tester,
  TechniqueExample example,
) {
  final widget = example.builder(tester.element(find.byType(ExampleScreen)));
  expect(find.byType(widget.runtimeType), findsOneWidget);
  return tester
      .renderObjectList<RenderParagraph>(
        find.descendant(
          of: find.byType(widget.runtimeType),
          matching: find.byType(RichText),
        ),
      )
      .toList();
}

/// The label of the replacement node of [slug] now.
String _replacement(String slug) => dataById('s10-$slug-rating').label;

/// Whether any node on the screen, merged or not, is a progress bar or
/// has the bar's value.
bool _anyProgressBar(WidgetTester tester) => semanticsNodes(
  tester,
  includeMerged: true,
).any((n) => n.role == SemanticsRole.progressBar || n.value == '68');

/// The focus outline the `TextButton` under [id] draws in [states].
BorderSide? _side(WidgetTester tester, String id, Set<WidgetState> states) {
  final style = tester
      .widget<TextButton>(
        find.descendant(of: byId(id), matching: find.byType(TextButton)),
      )
      .style!;
  return style.side!.resolve(states);
}

/// The text "Reviews: N" that the bar row shows.
String _shownReviews() =>
    (find.textContaining('Reviews: ').evaluate().single.widget as Text).data!;

void main() {
  test('the technique has the examples named in the spec', () {
    expect(s10ContentGroupReplacement.examples.map((e) => e.slug), [
      ..._good,
      ..._bad,
    ]);
    expect(_good, [
      for (final e in s10ContentGroupReplacement.examples)
        if (e.kind == ExampleKind.good) e.slug,
    ]);
    expect(
      s10ContentGroupReplacement.examples.where((e) => e.isCustomSolution),
      isEmpty,
      reason: 'no good example is a custom solution',
    );
  });

  test('the replacement text is under the 64 characters VoiceOver on iOS '
      'gives back, before and after a review', () {
    expect(_words, 'Rating: 3.4 out of 5 stars, based on 856 reviews');
    expect(_wordsAfter, 'Rating: 3.4 out of 5 stars, based on 857 reviews');
    expect(_words.length, lessThan(64));
    expect(_wordsAfter.length, lessThan(64));
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

      testWidgets('$slug: no piece is exposed, no node is a progress bar, '
          'and the rating cannot take focus', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        final rating = dataById('s10-$slug-rating');
        expect(rating.label, _words);
        expect(rating.value, isEmpty);
        expect(rating.role, SemanticsRole.none);
        expect(rating.actions, 0, reason: 'no action of any kind');
        expect(rating.flagsCollection.isFocused, Tristate.none);
        expect(_anyProgressBar(tester), isFalse);
        for (final n in semanticsNodes(tester, includeMerged: true)) {
          for (final piece in ['Rating:', '3.4 / 5', 'Reviews: 856', '3.4']) {
            expect(n.label, isNot(piece), reason: 'no node is "$piece"');
          }
          expect(n.label, isNot(contains('(856)')));
        }
        handle.dispose();
      });
    }

    testWidgets('good-exclude-semantics: the rating, then the button, and '
        'nothing else', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-exclude-semantics');
      expect(_exampleNodes(tester).map(_describe), [
        _words,
        'Add a 5-star review | button | tap',
      ]);
      handle.dispose();
    });

    testWidgets('good-hidden-pieces: the rating, and nothing else', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-hidden-pieces');
      expect(_exampleNodes(tester).map(_describe), [_words]);
      handle.dispose();
    });

    testWidgets('good-stars: the rating, and nothing else', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(const SizedBox());
      await _open(tester, 'good-stars');
      expect(_exampleNodes(tester).map(_describe), [_words]);
      handle.dispose();
    });

    // The replacement follows the values: one review added by each way of
    // pressing the button, each from a fresh open.
    for (final (how, press) in <(String, Future<void> Function(WidgetTester))>[
      ('a tap', (t) => t.tap(byId('s10-good-exclude-semantics-add'))),
      (
        'the tap action',
        (t) async =>
            t.semantics.tap(nodeById('s10-good-exclude-semantics-add')),
      ),
      (
        'Tab and Enter',
        (t) async {
          await tabTo(t, 's10-good-exclude-semantics-add');
          await t.sendKeyEvent(LogicalKeyboardKey.enter);
        },
      ),
      (
        'Tab and Space',
        (t) async {
          await tabTo(t, 's10-good-exclude-semantics-add');
          await t.sendKeyEvent(LogicalKeyboardKey.space);
        },
      ),
    ]) {
      testWidgets('good-exclude-semantics: after $how on the button the row '
          'shows 857 reviews and the replacement says so', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, 'good-exclude-semantics');
        expect(_shownReviews(), 'Reviews: 856');
        expect(_replacement('good-exclude-semantics'), _words);
        await press(tester);
        await tester.pumpAndSettle();
        expect(_shownReviews(), 'Reviews: 857');
        expect(_replacement('good-exclude-semantics'), _wordsAfter);
        expect(_anyProgressBar(tester), isFalse);
        handle.dispose();
      });
    }

    testWidgets('good-exclude-semantics: Tab goes Back, the button, and Back '
        'again, never to the rating', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-exclude-semantics');
      final stops = <String>[];
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final focused = semanticsNodes(tester)
            .where((n) => n.flagsCollection.isFocused == Tristate.isTrue);
        stops.add(
          focused.map((n) => n.tooltip.isNotEmpty ? n.tooltip : n.label).single,
        );
      }
      expect(stops, ['Back', 'Add a 5-star review', 'Back']);
      handle.dispose();
    });

    for (final brightness in Brightness.values) {
      testWidgets('good-exclude-semantics: the button draws a 2 pixel '
          'outline in the text colour, 3:1 or more on the page, only while '
          'it has focus, and its text keeps its contrast then '
          '(${brightness.name})', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, 'good-exclude-semantics', brightness: brightness);
        const id = 's10-good-exclude-semantics-add';
        final colors = Theme.of(tester.element(byId(id))).colorScheme;
        final side = _side(tester, id, {WidgetState.focused})!;
        expect(side.color, colors.onSurface);
        expect(side.width, 2);
        expect(_contrast(side.color, colors.surface), greaterThanOrEqualTo(3));
        expect(_side(tester, id, {}), isNull);
        expect(_side(tester, id, {WidgetState.hovered}), isNull);
        await tabTo(tester, id);
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });

      testWidgets(
        'good-stars: the stars are drawn in the theme\'s primary colour, '
        '3:1 or more on the page (${brightness.name})',
        (tester) async {
          await _open(tester, 'good-stars', brightness: brightness);
          final colors = Theme.of(tester.element(find.byType(StarRow)))
              .colorScheme;
          for (final icon in tester.widgetList<Icon>(
            find.descendant(
              of: find.byType(StarRow),
              matching: find.byType(Icon),
            ),
          )) {
            expect(icon.color, colors.primary);
          }
          final stars = _contrast(colors.primary, colors.surface);
          expect(stars, greaterThanOrEqualTo(3));
          debugPrint(
            'S10 stars on the page ${brightness.name}: '
            '${stars.toStringAsFixed(2)}:1',
          );
        },
      );
    }
  });

  // Every example, good and bad: at 200% text on a 320 by 640 screen no
  // layout overflows, and no text in the example is cut short, by a line
  // limit or by a box too small for its lines.
  for (final example in s10ContentGroupReplacement.examples) {
    final slug = example.slug;
    testWidgets('$slug: at 200% text on a phone nothing overflows and no '
        'text is cut short', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _open(tester, slug, textScale: 2);
      expect(tester.takeException(), isNull);
      final paragraphs = _exampleParagraphs(tester, example);
      expect(paragraphs, isNotEmpty);
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
        expect(
          p.localToGlobal(Offset(p.size.width, 0)).dx,
          lessThanOrEqualTo(320.5),
          reason: '"$text" runs past the screen',
        );
        painter.dispose();
      }
    });
  }

  group('bad examples have their defect', () {
    testWidgets('bad-pieces: only "3.4" and "(856)", and nothing that says '
        'what they are', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-pieces');
      expect(_exampleNodes(tester).map(_describe), ['3.4', '(856)']);
      for (final n in _exampleNodes(tester)) {
        for (final word in ['star', 'Star', 'out of', 'review', 'Rating']) {
          expect(n.label, isNot(contains(word)));
        }
      }
      // Positive control: the same stars replaced say what they mean.
      await tester.pumpWidget(const SizedBox());
      await _open(tester, 'good-stars');
      expect(_exampleNodes(tester).map(_describe), [_words]);
      handle.dispose();
    });

    testWidgets('bad-merged: one node, a progress bar at 68 named by the '
        'pieces', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-merged');
      expect(_exampleNodes(tester).map(_describe), [
        '$_barPieces | value 68 | role progressBar',
      ]);
      handle.dispose();
    });

    testWidgets('bad-not-excluded: one node, the label and then the pieces, '
        'a progress bar at 68', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-not-excluded');
      expect(_exampleNodes(tester).map(_describe), [
        '$_words\n$_barPieces | value 68 | role progressBar',
      ]);
      handle.dispose();
    });

    testWidgets('bad-hides-control: the Reviews button is in no node, yet '
        'Tab reaches it and Enter runs it', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-hides-control');
      expect(_exampleNodes(tester).map(_describe), [
        _words,
        'Reviews opened: 0',
      ]);
      for (final n in semanticsNodes(tester, includeMerged: true)) {
        expect(n.label, isNot('Reviews'));
      }
      final buttons = semanticsNodes(tester)
          .where((n) => n.flagsCollection.isButton)
          .map((n) => n.tooltip);
      expect(buttons, ['Back'], reason: 'no button but Back');
      // The keyboard reaches it: the second Tab puts focus on the hidden
      // button, which no semantics node shows as focused, and Enter runs
      // it.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focus = FocusManager.instance.primaryFocus!.context!;
      expect(
        find.ancestor(
          of: find.byWidget(focus.widget),
          matching: find.widgetWithText(TextButton, 'Reviews'),
        ),
        findsOneWidget,
        reason: 'keyboard focus is on the Reviews button',
      );
      expect(
        semanticsNodes(tester)
            .where((n) => n.flagsCollection.isFocused == Tristate.isTrue),
        isEmpty,
        reason: 'no node shows that focus',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Reviews opened: 1'), findsOneWidget);
      // Positive control: a tap where it is drawn runs it too.
      await tester.tap(find.text('Reviews'));
      await tester.pumpAndSettle();
      expect(find.text('Reviews opened: 2'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('bad-stale: after a review the row shows 857 and the '
        'replacement still says 856', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-stale');
      expect(_replacement('bad-stale'), _words);
      // The test-only witness, the container's identifier, says what the
      // row shows: 856 before the tap.
      expect(nodeById('s10-bad-stale-shows-856'), findsOne);
      expect(nodeById('s10-bad-stale-shows-857'), findsNothing);
      await tester.tap(byId('s10-bad-stale-add'));
      await tester.pumpAndSettle();
      expect(_shownReviews(), 'Reviews: 857');
      expect(nodeById('s10-bad-stale-shows-857'), findsOne);
      // The witness is a container: no label, value, or action, and the
      // example's nodes are as before.
      final witness = dataById('s10-bad-stale-shows-857');
      expect(witness.label, isEmpty);
      expect(witness.value, isEmpty);
      expect(witness.actions, 0);
      expect(_replacement('bad-stale'), _words);
      expect(_replacement('bad-stale'), isNot(_wordsAfter));
      // Positive control: good-exclude-semantics, the same row and button,
      // follows the same tap.
      await tester.pumpWidget(const SizedBox());
      await _open(tester, 'good-exclude-semantics');
      await tester.tap(byId('s10-good-exclude-semantics-add'));
      await tester.pumpAndSettle();
      expect(_replacement('good-exclude-semantics'), _wordsAfter);
      handle.dispose();
    });
  });
}
