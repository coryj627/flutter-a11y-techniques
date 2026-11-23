import 'dart:math' as math;
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/app/screens.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/c18_card/c18_card.dart';
import 'package:flutter_a11y_techniques/techniques/c18_card/examples.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/examples.dart';

/// L1 for C18 Card (docs/specs/C18-card.md, section 6). These tests run as
/// Android: `kIsWeb` is false, so what the web engine makes of a node (a
/// heading that is also a button is only a heading there, FL-268) is
/// tested in web_tests/c18_card.spec.js.
final _open = exampleOpener(c18Card, decodeImages: true);

const _good = ['good-material', 'good-tappable', 'good-cupertino'];

/// The keyboard-operable controls of each good example, by test identifier,
/// with the count each one adds to.
const _controls = {
  'good-material': {
    'c18-good-material-save': 'c18-good-material-saves',
    'c18-good-material-share': 'c18-good-material-shares',
  },
  'good-tappable': {'c18-good-tappable-card': 'c18-good-tappable-opens'},
  'good-cupertino': <String, String>{},
};

const _cardText = '$trailName\n$trailText';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

bool _focused(String id) =>
    dataById(id).flagsCollection.isFocused == Tristate.isTrue;

/// The number a count with the identifier [id] shows: 2 for "Saves: 2".
int _count(WidgetTester tester, String id) {
  final text = tester.widget<Text>(
    find.descendant(
      of: find.byKey(ValueKey<String>(id)),
      matching: find.byType(Text),
    ),
  );
  return int.parse(text.data!.split(': ').last);
}

/// Every count of [slug], by identifier.
Map<String, int> _counts(WidgetTester tester, String slug) => {
  for (final e in find.byType(Count).evaluate())
    if ((e.widget as Count).id.startsWith('c18-$slug-'))
      (e.widget as Count).id: _count(tester, (e.widget as Count).id),
};

/// The nodes of the example, in traversal order, from the first node after
/// the "Example" heading up to its first count: what a screen reader moves
/// through in the card. A node merged into its parent is left out.
List<SemanticsData> _cardNodes(WidgetTester tester) {
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
  final end = all.indexWhere(
    (n) =>
        n.identifier.startsWith('c18-') &&
        RegExp(r'-(saves|shares|opens)$').hasMatch(n.identifier),
  );
  expect(start, isNonNegative, reason: 'the Example heading');
  final stop = end < 0 ? all.length : end;
  return [
    for (final n in all.sublist(start + 1, stop))
      if (n.label.isNotEmpty || n.tooltip.isNotEmpty) n,
  ];
}

String _describe(SemanticsData n) => [
  n.label,
  if (n.headingLevel > 0) 'heading ${n.headingLevel}',
  if (n.flagsCollection.isButton) 'button',
  if (n.flagsCollection.isLink) 'link',
  if (n.flagsCollection.isImage) 'image',
  if (n.hasAction(SemanticsAction.tap)) 'tap',
].join(' | ');

/// Every paragraph of text that the example's own widget draws.
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

/// The focus outline the `TextButton` [id] draws while it has keyboard
/// focus, from its own style, and none while it has not.
BorderSide? _side(WidgetTester tester, String id, Set<WidgetState> states) {
  final style = tester
      .widget<TextButton>(
        find.descendant(of: byId(id), matching: find.byType(TextButton)),
      )
      .style!;
  return style.side!.resolve(states);
}

void main() {
  test('the technique has the examples named in the spec', () {
    expect(c18Card.examples.map((e) => e.slug), [
      ..._good,
      'bad-default-container',
      'bad-heading-button',
      'bad-ink-well',
      'bad-read-more',
    ]);
    expect(_good, [
      for (final e in c18Card.examples)
        if (e.kind == ExampleKind.good) e.slug,
    ]);
    expect(
      c18Card.examples.where((e) => e.isCustomSolution),
      isEmpty,
      reason: 'no good example is a custom solution',
    );
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

        for (final id in _controls[slug]!.keys) {
          testWidgets('$slug: with keyboard focus on $id the text still '
              'meets the contrast guideline (${brightness.name})', (
            tester,
          ) async {
            final handle = tester.ensureSemantics();
            await _open(tester, slug, brightness: brightness);
            await tabTo(tester, id);
            await tester.pumpAndSettle();
            expect(_focused(id), isTrue);
            await expectLater(tester, meetsGuideline(textContrastGuideline));
            handle.dispose();
          });
        }
      }

      for (final MapEntry(key: id, value: countId)
          in _controls[slug]!.entries) {
        testWidgets('$slug: a tap and the tap action on $id each add one to '
            'its own count, and to no other', (tester) async {
          final handle = tester.ensureSemantics();
          await _open(tester, slug);
          final before = _counts(tester, slug);
          expect(before.values, everyElement(0));
          await tester.tap(byId(id));
          await tester.pumpAndSettle();
          expect(_counts(tester, slug), {...before, countId: 1}, reason: 'tap');
          tester.semantics.tap(nodeById(id));
          await tester.pumpAndSettle();
          expect(_counts(tester, slug), {
            ...before,
            countId: 2,
          }, reason: 'tap action');
          handle.dispose();
        });

        for (final (key, name) in [
          (LogicalKeyboardKey.enter, 'Enter'),
          (LogicalKeyboardKey.space, 'Space'),
        ]) {
          testWidgets('$slug: Tab reaches $id and $name adds one to its '
              'own count, and to no other', (tester) async {
            final handle = tester.ensureSemantics();
            await _open(tester, slug);
            final before = _counts(tester, slug);
            await tabTo(tester, id);
            await tester.sendKeyEvent(key);
            await tester.pumpAndSettle();
            expect(_counts(tester, slug), {...before, countId: 1});
            handle.dispose();
          });
        }
      }
    }

    testWidgets('good-material: heading, text, picture, and the two buttons, '
        'each a node of its own, in that order', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-material');
      expect(_cardNodes(tester).map(_describe), [
        '$trailName | heading 3',
        trailText,
        '$pictureLabel | image',
        'Save $trailName | button | tap',
        'Share $trailName | button | tap',
      ]);
      handle.dispose();
    });

    testWidgets('good-material: Tab goes Back, Save, Share', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-material');
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
      expect(stops, ['Back', 'Save $trailName', 'Share $trailName']);
      handle.dispose();
    });

    for (final brightness in Brightness.values) {
      testWidgets('good-material: each button draws a 2 pixel outline in '
          'the text colour, 3:1 or more on the card, only while it has focus '
          '(${brightness.name})', (tester) async {
        await _open(tester, 'good-material', brightness: brightness);
        final ctx = tester.element(byId('c18-good-material-save'));
        final colors = Theme.of(ctx).colorScheme;
        final card = tester.widget<Material>(
          find
              .ancestor(
                of: byId('c18-good-material-save'),
                matching: find.byType(Material),
              )
              .first,
        );
        final surface = Color.alphaBlend(
          ElevationOverlay.applySurfaceTint(
            card.color!,
            card.surfaceTintColor,
            card.elevation,
          ),
          colors.surface,
        );
        for (final id in _controls['good-material']!.keys) {
          final side = _side(tester, id, {WidgetState.focused})!;
          expect(side.color, colors.onSurface, reason: id);
          expect(side.width, 2, reason: id);
          expect(
            _contrast(side.color, surface),
            greaterThanOrEqualTo(3),
            reason: '$id against the card',
          );
          expect(_side(tester, id, {}), isNull, reason: '$id unfocused');
          expect(_side(tester, id, {WidgetState.hovered}), isNull, reason: id);
        }
      });
    }

    testWidgets('good-tappable: one node, a button named by the title and '
        'the text, not a heading', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-tappable');
      expect(_cardNodes(tester).map(_describe), ['$_cardText | button | tap']);
      final data = dataById('c18-good-tappable-card');
      expect(data.headingLevel, 0);
      expect(data.flagsCollection.isHeader, isFalse);
      handle.dispose();
    });

    for (final brightness in Brightness.values) {
      testWidgets('good-tappable: keyboard focus tints the tile inside the '
          'card (FL-434), under 3:1 against the card (${brightness.name})', (
        tester,
      ) async {
        await _open(tester, 'good-tappable', brightness: brightness);
        final theme = Theme.of(tester.element(byId('c18-good-tappable-card')));
        final card = tester.widget<Material>(
          find
              .ancestor(
                of: byId('c18-good-tappable-card'),
                matching: find.byType(Material),
              )
              .first,
        );
        final surface = Color.alphaBlend(
          ElevationOverlay.applySurfaceTint(
            card.color!,
            card.surfaceTintColor,
            card.elevation,
          ),
          theme.colorScheme.surface,
        );
        final tint = Color.alphaBlend(theme.focusColor, surface);
        final ratio = _contrast(tint, surface);
        // FL-434: a change of background within the component, which
        // Understanding 1.4.11 puts out of its scope. Written to fail if
        // the tint reaches 3:1, so the entry is looked at again.
        expect(ratio, lessThan(3));
        expect(ratio, greaterThan(1));
        debugPrint(
          'C18 good-tappable focus tint ${brightness.name}: '
          '${ratio.toStringAsFixed(2)}:1',
        );
      });
    }

    testWidgets('good-cupertino: heading, text, picture, each a node of its '
        'own, and no control', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-cupertino');
      expect(_cardNodes(tester).map(_describe), [
        '$trailName | heading 3',
        trailText,
        '$pictureLabel | image',
      ]);
      handle.dispose();
    });
  });

  // Every example, good and bad: at 200% text on a 320 by 640 screen no
  // layout overflows, and no text in the example is cut short, by a line
  // limit or by a box too small for its lines.
  for (final example in c18Card.examples) {
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
    testWidgets('bad-default-container: the heading and the text are one '
        'node, a heading; the picture-less card\'s button is its child', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-default-container');
      expect(_cardNodes(tester).map(_describe), [
        '$_cardText | heading 3',
        'Save $trailName | button | tap',
      ]);
      final button = tester.getSemantics(
        find
            .descendant(
              of: byId('c18-bad-default-container-save'),
              matching: find.byType(Semantics),
            )
            .first,
      );
      var parent = button.parent;
      while (parent != null && parent.getSemanticsData().headingLevel == 0) {
        parent = parent.parent;
      }
      expect(
        parent?.getSemanticsData().label,
        _cardText,
        reason: 'the button sits inside the heading node',
      );
      // Positive control: the button still works.
      await tester.tap(byId('c18-bad-default-container-save'));
      await tester.pumpAndSettle();
      expect(_count(tester, 'c18-bad-default-container-saves'), 1);
      handle.dispose();
    });

    testWidgets('bad-heading-button: one node that is a button and a level 3 '
        'heading', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-heading-button');
      expect(_cardNodes(tester).map(_describe), [
        '$_cardText | heading 3 | button | tap',
      ]);
      // Off the web it works as good-tappable does.
      tester.semantics.tap(nodeById('c18-bad-heading-button-card'));
      await tester.pumpAndSettle();
      expect(_count(tester, 'c18-bad-heading-button-opens'), 1);
      handle.dispose();
    });

    testWidgets('bad-ink-well: one node with a tap action and no button flag '
        '(FL-401); Tab and Enter still reach and activate it', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-ink-well');
      expect(_cardNodes(tester).map(_describe), ['$_cardText | tap']);
      final data = dataById('c18-bad-ink-well-card');
      expect(data.flagsCollection.isButton, isFalse);
      expect(data.flagsCollection.isLink, isFalse);
      // Everything but the role is there: focus and the keys.
      await tabTo(tester, 'c18-bad-ink-well-card');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(_count(tester, 'c18-bad-ink-well-opens'), 1);
      handle.dispose();
    });

    testWidgets('bad-read-more: a link named "Read more" that nothing '
        'relates to the heading', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-read-more');
      expect(_cardNodes(tester).map(_describe), [
        '$trailName | heading 3',
        trailText,
        'Read more | link | tap',
      ]);
      final link = dataById('c18-bad-read-more-link');
      expect(link.linkUrl, Uri.parse('#$readMoreRoute'));
      for (final text in [link.label, link.hint, link.value, link.tooltip]) {
        expect(text, isNot(contains(trailName)));
      }
      // Positive control: it is a working link.
      await tester.tap(byId('c18-bad-read-more-link'));
      await tester.pumpAndSettle();
      expect(find.byType(TechniqueScreen), findsOneWidget);
      expect(find.byType(ExampleScreen), findsNothing);
      handle.dispose();
    });
  });
}
