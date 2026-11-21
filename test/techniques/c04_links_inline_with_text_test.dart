import 'dart:math' as math;
import 'dart:ui' show Tristate;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/app/app.dart';
import 'package:flutter_a11y_techniques/app/screens.dart';
import 'package:flutter_a11y_techniques/catalog/registry.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/c03_stand_alone_link/c03_stand_alone_link.dart';
import 'package:flutter_a11y_techniques/techniques/c03_stand_alone_link/examples.dart'
    show linkTapHint;
import 'package:flutter_a11y_techniques/techniques/c04_links_inline_with_text/c04_links_inline_with_text.dart';
import 'package:flutter_a11y_techniques/techniques/c04_links_inline_with_text/examples.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/examples.dart';

/// L1 for C04 Links inline with text (docs/specs/C04-links-inline-with-text.md,
/// section 6). These tests run as Android: `kIsWeb` is false, so what the
/// examples do only on the web (the browser follows the link, `BrowserKeys`
/// hands it the keys) is tested in web_tests/c04_links_inline_with_text.spec.js.
///
/// The app is opened with C03 as well as C04, so that the second link's
/// page, C03's, exists.
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
      registry: TechniqueRegistry([c04LinksInlineWithText, c03StandAloneLink]),
      platform: AppPlatform.android,
      initialRoute: '/t/C04/$slug',
    ),
  );
  await tester.pumpAndSettle();
}

const _good = ['good-material', 'good-cupertino', 'good-custom'];
const _links = [inTextLink, standAloneLink];

String _linkId(String slug, int n) => 'c04-$slug-link-$n';

/// The words and links of the two-link sentence, in reading order.
const _sentence = [
  'Read about ',
  'links in text',
  ' and ',
  'stand-alone links',
  ' first.',
];

/// The technique whose page is on top, if a technique page is.
String? _techniqueOnTop(WidgetTester tester) {
  final screens = find.byType(TechniqueScreen);
  if (screens.evaluate().isEmpty) return null;
  return tester.widget<TechniqueScreen>(screens.last).technique.id;
}

/// The page [link] goes to is on screen, and the example is not.
void _expectOn(WidgetTester tester, InlineLink link, String reason) {
  final id = link.route.split('/').last;
  expect(_techniqueOnTop(tester), id, reason: reason);
  expect(find.byType(ExampleScreen), findsNothing, reason: reason);
}

/// One Back brings the example back: the link opened one page.
Future<void> _backToExample(WidgetTester tester, String reason) async {
  await tester.tap(find.byTooltip('Back'));
  await tester.pumpAndSettle();
  expect(find.byType(ExampleScreen), findsOneWidget, reason: reason);
  expect(find.byType(TechniqueScreen), findsNothing, reason: reason);
}

bool _focused(String id) =>
    dataById(id).flagsCollection.isFocused == Tristate.isTrue;

/// The paragraph's own nodes in reading order: the runs of words and the
/// links, as a screen reader goes through them.
List<String> _readingOrder(WidgetTester tester, String slug) {
  final sentence = tester.getSemantics(
    find
        .byType(RichText)
        .evaluate()
        .map((e) => find.byWidget(e.widget))
        .firstWhere(
          (f) => tester
              .widget<RichText>(f)
              .text
              .toPlainText()
              .startsWith('Read about'),
        ),
  );
  final out = <String>[];
  void walk(SemanticsNode n) {
    final d = n.getSemanticsData();
    if (d.label.isNotEmpty) out.add(d.label);
    if (n.mergeAllDescendantsIntoThisNode) return;
    for (final c in n.debugListChildrenInOrder(
      DebugSemanticsDumpOrder.traversalOrder,
    )) {
      walk(c);
    }
  }

  walk(sentence);
  return out;
}

/// Every node on the screen with the link flag that is not merged into
/// another.
List<SemanticsData> _linkNodes(WidgetTester tester) => [
  for (final n in semanticsNodes(tester))
    if (n.flagsCollection.isLink) n,
];

/// The sentence's paragraph.
RenderParagraph _sentenceParagraph(WidgetTester tester) => tester
    .renderObjectList<RenderParagraph>(find.byType(RichText))
    .firstWhere((p) => p.text.toPlainText().startsWith('Read about'));

/// The paragraph that draws link [n]'s text.
RenderParagraph _linkParagraph(WidgetTester tester, String slug, int n) =>
    tester.renderObject<RenderParagraph>(
      find.descendant(
        of: byId(_linkId(slug, n)),
        matching: find.byType(RichText),
      ),
    );

/// The style link [n]'s text is drawn in.
TextStyle _linkStyle(WidgetTester tester, String slug, int n) =>
    _linkParagraph(tester, slug, n).text.style!;

/// The colour of the sentence's words.
Color _wordsColour(WidgetTester tester) {
  final p = _sentenceParagraph(tester);
  return p.text.style!.color!;
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// The colour of the focus ring round link [n], as it is rendered.
Color _ringColour(WidgetTester tester, String slug, int n) {
  final ring = find.descendant(
    of: byId(_linkId(slug, n)),
    matching: find.byType(InlineFocusRing),
  );
  expect(ring, findsOneWidget);
  final box = tester.widget<DecoratedBox>(
    find.descendant(of: ring, matching: find.byType(DecoratedBox)).first,
  );
  expect(box.position, DecorationPosition.foreground);
  final border = (box.decoration as BoxDecoration).border! as Border;
  expect(border.top.width, 2);
  expect(border.top.strokeAlign, BorderSide.strokeAlignOutside);
  return border.top.color;
}

/// The height on screen of the first line box of [p]'s text.
double _lineHeightOnScreen(RenderParagraph p) {
  final box = p
      .getBoxesForSelection(const TextSelection(baseOffset: 0, extentOffset: 1))
      .first
      .toRect();
  final shown = MatrixUtils.transformRect(p.getTransformTo(null), box);
  return shown.height;
}

void main() {
  test('the technique has the examples named in the spec', () {
    expect(c04LinksInlineWithText.examples.map((e) => e.slug), [
      ..._good,
      'bad-text-span',
      'bad-out-of-order',
      'bad-colour-only',
      'bad-merged',
    ]);
    expect(_good, [
      for (final e in c04LinksInlineWithText.examples)
        if (e.kind == ExampleKind.good) e.slug,
    ]);
  });

  test('the links go to the two technique pages', () {
    expect(inTextLink.route, '/t/C04');
    expect(inTextLink.address.toString(), '#/t/C04');
    expect(standAloneLink.route, '/t/C03');
    expect(standAloneLink.address.toString(), '#/t/C03');
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

        // With keyboard focus on a link, InkWell's focus tint and the ring
        // are drawn: the text must keep its contrast in that state too.
        for (var n = 1; n <= 2; n++) {
          testWidgets('$slug: with focus on link $n the text still meets the '
              'contrast guideline (${brightness.name})', (tester) async {
            final handle = tester.ensureSemantics();
            await _open(tester, slug, brightness: brightness);
            await tabTo(tester, _linkId(slug, n));
            await tester.pumpAndSettle();
            expect(_focused(_linkId(slug, n)), isTrue);
            await expectLater(tester, meetsGuideline(textContrastGuideline));
            handle.dispose();
          });
        }

        testWidgets('$slug: the links are underlined, in a colour with 4.5:1 '
            'on the page (${brightness.name})', (tester) async {
          await _open(tester, slug, brightness: brightness);
          final page = Theme.of(tester.element(byId(_linkId(slug, 1))))
              .colorScheme
              .surface;
          for (var n = 1; n <= 2; n++) {
            final style = _linkStyle(tester, slug, n);
            expect(style.decoration, TextDecoration.underline, reason: '$n');
            expect(
              _contrast(style.color!, page),
              greaterThanOrEqualTo(4.5),
              reason: 'link $n against the page',
            );
          }
        });
      }

      testWidgets('$slug: each link is its own node, a link with its address '
          'and name, and nothing else', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        for (var n = 1; n <= 2; n++) {
          final data = dataById(_linkId(slug, n));
          final link = _links[n - 1];
          expect(data.flagsCollection.isLink, isTrue, reason: '$n');
          expect(data.linkUrl, link.address, reason: '$n');
          expect(data.label, link.text, reason: '$n');
          expect(data.flagsCollection.isButton, isFalse, reason: '$n');
          // The sort key that puts it between the runs round it: without it
          // the order rests on where the links land (the probe's "order"
          // lines, docs/evidence/probes/c04/flutter_test.txt).
          expect(
            (nodeById(_linkId(slug, n)).evaluate().single.sortKey!
                    as OrdinalSortKey)
                .order,
            n - 0.5,
            reason: '$n',
          );
          expect(data.hasAction(SemanticsAction.tap), isTrue, reason: '$n');
          expect(
            data.customSemanticsActionIds,
            contains(
              CustomSemanticsAction.getIdentifier(
                const CustomSemanticsAction.overridingAction(
                  hint: linkTapHint,
                  action: SemanticsAction.tap,
                ),
              ),
            ),
            reason: '$n',
          );
        }
        // Exactly two link nodes on the screen.
        expect(_linkNodes(tester).map((d) => d.label), [
          inTextLink.text,
          standAloneLink.text,
        ]);
        handle.dispose();
      });

      // On one line and wrapped: where the links land changes the order a
      // sentence without sort keys is read in (docs/evidence/probes/c04).
      for (final (width, scale) in [(800.0, 1.0), (320.0, 1.0), (320.0, 2.0)]) {
        testWidgets('$slug: the sentence is read in order, each link in its '
            'place ($width wide, ${scale * 100}% text)', (tester) async {
          tester.view.physicalSize = Size(width, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final handle = tester.ensureSemantics();
          await _open(tester, slug, textScale: scale);
          expect(_readingOrder(tester, slug), _sentence);
          handle.dispose();
        });
      }

      for (var n = 1; n <= 2; n++) {
        testWidgets('$slug: a tap and the tap action each follow link $n, '
            'once', (tester) async {
          final handle = tester.ensureSemantics();
          await _open(tester, slug);
          final id = _linkId(slug, n);
          await tester.tap(byId(id));
          await tester.pumpAndSettle();
          _expectOn(tester, _links[n - 1], 'tap');
          await _backToExample(tester, 'tap');
          tester.semantics.tap(nodeById(id));
          await tester.pumpAndSettle();
          _expectOn(tester, _links[n - 1], 'tap action');
          await _backToExample(tester, 'tap action');
          handle.dispose();
        });

        for (final (key, name) in [
          (LogicalKeyboardKey.enter, 'Enter'),
          (LogicalKeyboardKey.space, 'Space'),
        ]) {
          testWidgets('$slug: Tab reaches link $n and $name follows it', (
            tester,
          ) async {
            final handle = tester.ensureSemantics();
            await _open(tester, slug);
            await tabTo(tester, _linkId(slug, n));
            await tester.sendKeyEvent(key);
            await tester.pumpAndSettle();
            _expectOn(tester, _links[n - 1], name);
            await _backToExample(tester, name);
            handle.dispose();
          });
        }
      }

      testWidgets('$slug: Tab goes Back, the first link, the second link', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        final stops = <String>[];
        for (var i = 0; i < 3; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          final focused = semanticsNodes(tester)
              .where((n) => n.flagsCollection.isFocused == Tristate.isTrue);
          stops.add(
            focused
                .map((n) => n.tooltip.isNotEmpty ? n.tooltip : n.label)
                .join('+'),
          );
        }
        expect(stops, ['Back', inTextLink.text, standAloneLink.text]);
        handle.dispose();
      });

      for (final brightness in Brightness.values) {
        testWidgets('$slug: keyboard focus draws the ring round each link, '
            'and it goes when focus leaves (${brightness.name})', (
          tester,
        ) async {
          final handle = tester.ensureSemantics();
          await _open(tester, slug, brightness: brightness);
          final colors = Theme.of(tester.element(byId(_linkId(slug, 1))))
              .colorScheme;
          expect(_ringColour(tester, slug, 1), Colors.transparent);
          expect(_ringColour(tester, slug, 2), Colors.transparent);
          await tabTo(tester, _linkId(slug, 1));
          expect(_ringColour(tester, slug, 1), colors.onSurface);
          expect(_ringColour(tester, slug, 2), Colors.transparent);
          expect(
            _contrast(colors.onSurface, colors.surface),
            greaterThanOrEqualTo(3),
          );
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          expect(_focused(_linkId(slug, 2)), isTrue);
          expect(_ringColour(tester, slug, 1), Colors.transparent);
          expect(_ringColour(tester, slug, 2), colors.onSurface);
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          expect(_focused(_linkId(slug, 2)), isFalse);
          expect(_ringColour(tester, slug, 2), Colors.transparent);
          handle.dispose();
        });
      }

      for (final scale in [1.0, 2.0]) {
        testWidgets('$slug: at ${scale * 100}% text the links are the size '
            'of the words round them', (tester) async {
          await _open(tester, slug, textScale: scale);
          final words = _lineHeightOnScreen(_sentenceParagraph(tester));
          for (var n = 1; n <= 2; n++) {
            expect(
              _lineHeightOnScreen(_linkParagraph(tester, slug, n)),
              moreOrLessEquals(words, epsilon: 0.5),
              reason: 'link $n',
            );
            expect(
              _linkStyle(tester, slug, n).fontSize,
              _sentenceParagraph(tester).text.style!.fontSize,
            );
          }
        });
      }
    }
  });

  // Every example, good and bad: at 200% text on a 320 by 640 screen no
  // layout overflows, and no text in the example is cut short, by a line
  // limit or by a box too small for its lines.
  for (final example in c04LinksInlineWithText.examples) {
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
        expect(p.didExceedMaxLines, isFalse, reason: '"$text" hit its limit');
        final painter = TextPainter(
          text: p.text,
          textDirection: p.textDirection,
          textScaler: p.textScaler,
          textAlign: p.textAlign,
        );
        // A paragraph with WidgetSpans needs their sizes to lay out; its
        // own layout already placed them, so only text-only ones are
        // measured again.
        if (p.childCount == 0) {
          painter.layout(maxWidth: p.size.width);
          expect(
            p.size.height,
            greaterThanOrEqualTo(painter.height - 0.5),
            reason: '"$text" is cut short in its box',
          );
        }
        painter.dispose();
        // Inside the screen's width.
        final shown = MatrixUtils.transformRect(
          p.getTransformTo(null),
          Offset.zero & p.size,
        );
        expect(shown.right, lessThanOrEqualTo(320.5), reason: '"$text"');
      }
    });
  }

  group('bad examples have their defect', () {
    const spanLink = 'c04-bad-text-span-link-1';

    testWidgets('bad-text-span: a link with no address that Tab never '
        'reaches', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-text-span');
      final data = dataById(spanLink);
      expect(data.label, inTextLink.text);
      expect(data.flagsCollection.isLink, isTrue);
      expect(data.linkUrl, isNull);
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      // It is read in its place: the recognizer splits the paragraph.
      expect(_readingOrder(tester, 'bad-text-span'), [
        'Read about ',
        inTextLink.text,
        ' first.',
      ]);
      // Not focusable, and Tab never gives it focus.
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(
          dataById(spanLink).flagsCollection.isFocused,
          Tristate.none,
          reason: 'after Tab ${i + 1}',
        );
      }
      // The tap action, what a screen reader performs, opens its page.
      tester.semantics.tap(nodeById(spanLink));
      await tester.pumpAndSettle();
      expect(find.text(TextSpanPage.title), findsOneWidget);
      handle.dispose();
    });

    testWidgets('bad-text-span: a tap on the link opens its page', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-text-span');
      // A tap in the middle of the link's words, which is what hides the
      // defect: it works by touch.
      final p = _sentenceParagraph(tester);
      final start = p.text.toPlainText().indexOf(inTextLink.text);
      final box = p
          .getBoxesForSelection(
            TextSelection(
              baseOffset: start,
              extentOffset: start + inTextLink.text.length,
            ),
          )
          .first
          .toRect();
      await tester.tapAt(p.localToGlobal(box.center));
      await tester.pumpAndSettle();
      expect(find.text(TextSpanPage.title), findsOneWidget);
      handle.dispose();
    });

    for (final (key, name) in [
      (LogicalKeyboardKey.enter, 'Enter'),
      (LogicalKeyboardKey.space, 'Space'),
    ]) {
      testWidgets('bad-text-span: no key opens its page: Tab reaches only '
          'Back, and $name there goes to the technique page', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, 'bad-text-span');
        final stops = <String>{};
        for (var i = 0; i < 4; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          stops.addAll(
            semanticsNodes(tester)
                .where((n) => n.flagsCollection.isFocused == Tristate.isTrue)
                .map((n) => n.tooltip.isNotEmpty ? n.tooltip : n.label),
          );
        }
        expect(stops, {'Back'});
        await tester.sendKeyEvent(key);
        await tester.pumpAndSettle();
        expect(_techniqueOnTop(tester), 'C04', reason: name);
        expect(find.text(TextSpanPage.title), findsNothing, reason: name);
        handle.dispose();
      });
    }

    testWidgets('bad-out-of-order: the sentence is one label without its '
        'links, and the links come after it', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-out-of-order');
      expect(_readingOrder(tester, 'bad-out-of-order'), [
        'Read about \n and \n first.',
        inTextLink.text,
        standAloneLink.text,
      ]);
      // The links themselves are as in the good examples.
      for (var n = 1; n <= 2; n++) {
        final data = dataById(_linkId('bad-out-of-order', n));
        expect(data.flagsCollection.isLink, isTrue);
        expect(data.linkUrl, _links[n - 1].address);
      }
      handle.dispose();
    });

    for (final brightness in Brightness.values) {
      testWidgets('bad-colour-only: no underline, and under 3:1 against the '
          'words round it (${brightness.name})', (tester) async {
        await _open(tester, 'bad-colour-only', brightness: brightness);
        final words = _wordsColour(tester);
        final page = Theme.of(
          tester.element(byId(_linkId('bad-colour-only', 1))),
        ).colorScheme.surface;
        for (var n = 1; n <= 2; n++) {
          final style = _linkStyle(tester, 'bad-colour-only', n);
          expect(style.decoration, TextDecoration.none);
          expect(
            style.fontWeight,
            _sentenceParagraph(tester).text.style!.fontWeight,
          );
          expect(
            style.fontStyle,
            _sentenceParagraph(tester).text.style!.fontStyle,
          );
          expect(_contrast(style.color!, words), lessThan(3), reason: '$n');
          // The measured ratios the docs give: 2.66:1 in light, 1.32:1 in
          // dark (also in docs/evidence/probes/c04/flutter_test.txt).
          expect(
            _contrast(style.color!, words),
            closeTo(brightness == Brightness.light ? 2.66 : 1.32, 0.01),
          );
          // The one defect: its contrast with the page is still enough.
          expect(_contrast(style.color!, page), greaterThanOrEqualTo(4.5));
        }
      });
    }

    testWidgets('bad-merged: one link node, the whole sentence, whose tap '
        'action follows only the first link', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-merged');
      const id = 'c04-bad-merged-sentence';
      final data = dataById(id);
      expect(data.flagsCollection.isLink, isTrue);
      expect(data.label, _sentence.join('\n'));
      expect(data.linkUrl, inTextLink.address);
      expect(_linkNodes(tester), hasLength(1));
      tester.semantics.tap(nodeById(id));
      await tester.pumpAndSettle();
      _expectOn(tester, inTextLink, 'the tap action');
      handle.dispose();
    });

    testWidgets('bad-merged: the keyboard still reaches both links, which '
        'shows the links themselves work', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-merged');
      await tester.sendKeyEvent(LogicalKeyboardKey.tab); // Back
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      _expectOn(tester, standAloneLink, 'Enter on the second link');
      handle.dispose();
    });
  });

  group('limitations, on the SDK alone', () {
    testWidgets('FL-241: text in a WidgetSpan is scaled twice', (tester) async {
      Widget sentence(Widget link) => MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Words '),
                WidgetSpan(child: link),
              ],
            ),
          ),
        ),
      );
      await tester.pumpWidget(sentence(const Text('link')));
      final words = _lineHeightOnScreen(
        tester.renderObject<RenderParagraph>(find.byType(RichText).first),
      );
      final link = _lineHeightOnScreen(
        tester.renderObject<RenderParagraph>(find.byType(RichText).last),
      );
      // Twice the words' height: scaled by the text and by the WidgetSpan.
      expect(link, moreOrLessEquals(2 * words, epsilon: 1));
      await tester.pumpWidget(
        sentence(MediaQuery.withNoTextScaling(child: const Text('link'))),
      );
      final fixed = _lineHeightOnScreen(
        tester.renderObject<RenderParagraph>(find.byType(RichText).last),
      );
      expect(fixed, moreOrLessEquals(words, epsilon: 0.5));
    });

    test('FL-242: CupertinoColors.link and systemBlue are under 4.5:1 on '
        'white', () {
      for (final c in [CupertinoColors.link, CupertinoColors.systemBlue]) {
        expect(
          _contrast(c.color, CupertinoColors.white),
          allOf(greaterThan(4), lessThan(4.5)),
        );
      }
      // The high-contrast variant good-cupertino uses.
      expect(
        _contrast(
          CupertinoColors.systemBlue.highContrastColor,
          CupertinoColors.white,
        ),
        greaterThan(7),
      );
    });
  });
}
