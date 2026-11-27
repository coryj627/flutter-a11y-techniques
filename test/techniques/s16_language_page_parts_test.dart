import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/app/screens.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/s16_language_page_parts/examples.dart';
import 'package:flutter_a11y_techniques/techniques/s16_language_page_parts/s16_language_page_parts.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/examples.dart';

/// L1 for S16 Language of page and parts
/// (docs/specs/S16-language-page-parts.md, section 6). The language of a
/// node is its `locale`, given by `localeForSubtree` above it; the language
/// of a part of its label is a `LocaleStringAttribute` over the part's
/// range. A node with neither is in the app's language, which the app
/// gives the platform and not the semantics tree: widget tests cannot see
/// it, nor what `Localizations.override` does to it (FL-360), since the
/// framework sends both to the engine (`setApplicationLocale`), which the
/// tests do not run. Those are tested on the device layers and the web.
final _open = exampleOpener(s16LanguagePageParts);

const _good = ['good-passage', 'good-phrase', 'good-language-menu'];
const _menus = ['good-language-menu', 'bad-title-in-tile'];

/// One line per named node of the example, after the "Example" heading and
/// up to its "Chosen" line, in traversal order: its label, its locale when
/// it has one, each language attribute of its label with its range, and
/// "button" for a button. A node merged into its parent is left out.
List<String> _tree(WidgetTester tester) {
  final out = <SemanticsData>[];
  void visit(SemanticsNode node) {
    if (node.isMergedIntoParent) return;
    out.add(node.getSemanticsData());
    for (final child in node.debugListChildrenInOrder(
      DebugSemanticsDumpOrder.traversalOrder,
    )) {
      visit(child);
    }
  }

  visit(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  final start = out.indexWhere((n) => n.label == 'Example');
  expect(start, isNonNegative, reason: 'the Example heading');
  final lines = <String>[];
  for (final n in out.skip(start + 1)) {
    if (n.label.startsWith('Chosen: ') || n.label == 'Back') break;
    if (n.label.isEmpty) continue;
    final attributes = [
      for (final a in n.attributedLabel.attributes)
        if (a is LocaleStringAttribute)
          '${a.locale.toLanguageTag()}[${a.range.start}-${a.range.end}]'
        else
          '$a',
    ];
    lines.add(
      [
        '"${n.label}"',
        if (n.locale != null) 'locale ${n.locale!.toLanguageTag()}',
        ...attributes,
        if (n.flagsCollection.isButton) 'button',
      ].join(' '),
    );
  }
  return lines;
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// What the "Chosen" line of [slug] says.
String _chosen(WidgetTester tester, String slug) => tester
    .widget<Text>(
      find.descendant(
        of: find.byKey(ValueKey<String>('s16-$slug-chosen')),
        matching: find.byType(Text),
      ),
    )
    .data!;

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

void main() {
  test('the technique has the examples named in the spec', () {
    expect(s16LanguagePageParts.examples.map((e) => e.slug), [
      ..._good,
      'bad-unmarked',
      'bad-title-in-tile',
      'bad-region-tag',
      'bad-override',
    ]);
    expect(_good, [
      for (final e in s16LanguagePageParts.examples)
        if (e.kind == ExampleKind.good) e.slug,
    ]);
    expect(
      s16LanguagePageParts.examples.where((e) => e.isCustomSolution),
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
      }
    }

    testWidgets('good-passage: the passage is a French node, and the line '
        'before it has no language of its own', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-passage');
      expect(_tree(tester), ['"$lead"', '"$passage" locale fr']);
      handle.dispose();
    });

    testWidgets('good-phrase: one node, French over the phrase alone', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-phrase');
      const sentence = 'The guide said bon voyage as we left.';
      final start = sentence.indexOf('bon voyage');
      expect(_tree(tester), [
        '"$sentence" fr[$start-${start + 'bon voyage'.length}]',
      ]);
      handle.dispose();
    });

    testWidgets('good-language-menu: each tile a button in its own '
        'language', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-language-menu');
      expect(_tree(tester), [
        for (final l in languages) '"${l.name}" locale ${l.code} button',
      ]);
      expect(
        dataById('s16-good-language-menu-chosen').locale,
        isNull,
        reason: 'the Chosen line is in the app\'s language',
      );
      handle.dispose();
    });

    for (final brightness in Brightness.values) {
      testWidgets('good-language-menu: keyboard focus tints the tile '
          '(FL-434), under 3:1 against the page (${brightness.name})', (
        tester,
      ) async {
        await _open(tester, 'good-language-menu', brightness: brightness);
        final theme = Theme.of(
          tester.element(byId('s16-good-language-menu-fr')),
        );
        final page = theme.scaffoldBackgroundColor;
        final tint = Color.alphaBlend(theme.focusColor, page);
        final ratio = _contrast(tint, page);
        // FL-434: a change of background within the component, which
        // Understanding 1.4.11 puts out of its scope, as S08's tiles. Written
        // to fail if the tint reaches 3:1, so the entry is looked at again.
        expect(ratio, lessThan(3));
        expect(ratio, greaterThan(1));
      });

      for (final l in languages) {
        testWidgets('good-language-menu: with keyboard focus on ${l.name} the '
            'text still meets the contrast guideline (${brightness.name})', (
          tester,
        ) async {
          final handle = tester.ensureSemantics();
          await _open(tester, 'good-language-menu', brightness: brightness);
          await tabTo(tester, 's16-good-language-menu-${l.code}');
          await tester.pumpAndSettle();
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          handle.dispose();
        });
      }
    }
  });

  // Both language menus: each tile, by a tap, by the tap action, and by Tab
  // then Enter or Space, chooses its own language and no other. In
  // bad-title-in-tile this is the positive control: the tiles work, and
  // only their language is lost.
  for (final slug in _menus) {
    for (final l in languages) {
      final id = 's16-$slug-${l.code}';
      testWidgets('$slug: a tap and the tap action on ${l.name} each choose '
          '${l.english}', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        expect(_chosen(tester, slug), 'Chosen: none');
        await tester.tap(byId(id));
        await tester.pumpAndSettle();
        expect(_chosen(tester, slug), 'Chosen: ${l.english}', reason: 'tap');
        final other = languages.firstWhere((o) => o != l);
        await tester.tap(byId('s16-$slug-${other.code}'));
        await tester.pumpAndSettle();
        expect(_chosen(tester, slug), 'Chosen: ${other.english}');
        tester.semantics.tap(nodeById(id));
        await tester.pumpAndSettle();
        expect(
          _chosen(tester, slug),
          'Chosen: ${l.english}',
          reason: 'tap action',
        );
        handle.dispose();
      });

      for (final (key, name) in [
        (LogicalKeyboardKey.enter, 'Enter'),
        (LogicalKeyboardKey.space, 'Space'),
      ]) {
        testWidgets('$slug: Tab reaches ${l.name} and $name chooses '
            '${l.english}', (tester) async {
          final handle = tester.ensureSemantics();
          await _open(tester, slug);
          await tabTo(tester, id);
          await tester.sendKeyEvent(key);
          await tester.pumpAndSettle();
          expect(_chosen(tester, slug), 'Chosen: ${l.english}');
          handle.dispose();
        });
      }
    }
  }

  // Every example, good and bad: at 200% text on a 320 by 640 screen no
  // layout overflows, and no text in the example is cut short, by a line
  // limit or by a box too small for its lines.
  for (final example in s16LanguagePageParts.examples) {
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
    testWidgets('bad-unmarked: no node and no part has a language of its '
        'own', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-unmarked');
      expect(_tree(tester), ['"$lead"', '"$passage"']);
      handle.dispose();
    });

    testWidgets('bad-title-in-tile: each tile is a button with no language '
        'of its own (FL-361)', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-title-in-tile');
      expect(_tree(tester), [for (final l in languages) '"${l.name}" button']);
      handle.dispose();
    });

    testWidgets('bad-region-tag: the passage is a node in fr-FR; the '
        'web writes it fr_FR (FL-020), which widget tests do not see', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-region-tag');
      expect(_tree(tester), ['"$lead"', '"$passage" locale fr-FR']);
      // What the web engine writes is the locale's toString(), where the
      // other engines write its language tag (source read, FL-020).
      expect(const Locale('fr', 'FR').toString(), 'fr_FR');
      expect(const Locale('fr', 'FR').toLanguageTag(), 'fr-FR');
      handle.dispose();
    });

    testWidgets('bad-override: the passage is a French node; what it does to '
        'the app\'s language is not seen here (FL-360)', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-override');
      expect(_tree(tester), ['"$lead"', '"$passage" locale fr']);
      handle.dispose();
    });
  });
}
