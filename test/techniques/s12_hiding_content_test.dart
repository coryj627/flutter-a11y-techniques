import 'dart:math' as math;
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/app/screens.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/s12_hiding_content/examples.dart';
import 'package:flutter_a11y_techniques/techniques/s12_hiding_content/s12_hiding_content.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/examples.dart';

/// L1 for S12 Hiding content from AT (docs/specs/S12-hiding-content.md,
/// section 6). These tests run as Android: `kIsWeb` is false, so what the
/// web engine makes of a node is tested in web_tests/s12_hiding_content.spec.js,
/// and what TalkBack and VoiceOver say is in the transcripts.
final _open = exampleOpener(s12HidingContent);

const _good = ['good-decoration', 'good-badge', 'good-visibility'];
const _panels = ['good-visibility', 'bad-opacity', 'bad-maintain'];

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// The text of the count with the identifier [id].
String _count(WidgetTester tester, String id) => tester
    .widget<Text>(
      find.descendant(
        of: find.byKey(ValueKey<String>(id)),
        matching: find.byType(Text),
      ),
    )
    .data!;

/// Every node of the screen in traversal order, from the first node after
/// the "Example" heading up to the example's count (or the end): what a
/// screen reader moves through in the example. A node merged into its
/// parent is left out, and so is a node with no name and no tap action,
/// such as a plain container.
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
  final end = all.indexWhere(
    (n) => RegExp(r'^s12-.*-count$').hasMatch(n.identifier),
  );
  return [
    for (final n in all.sublist(start + 1, end < 0 ? all.length : end))
      if (n.label.isNotEmpty || n.hasAction(SemanticsAction.tap)) n,
  ];
}

String _describe(SemanticsData n) => [
  n.label,
  if (n.flagsCollection.isButton) 'button',
  if (n.flagsCollection.isToggled != Tristate.none)
    'toggled=${n.flagsCollection.isToggled.name}',
  if (n.hasAction(SemanticsAction.tap)) 'tap',
].join(' | ');

/// Every label on the screen, merged nodes included.
List<String> _allLabels(WidgetTester tester) => [
  for (final n in semanticsNodes(tester, includeMerged: true))
    if (n.label.isNotEmpty) n.label,
];

/// The labels of the nodes with keyboard focus.
List<String> _focusedNodes(WidgetTester tester) => [
  for (final n in semanticsNodes(tester))
    if (n.flagsCollection.isFocused == Tristate.isTrue)
      n.tooltip.isNotEmpty ? n.tooltip : n.label,
];

/// The text of the widget with keyboard focus, whether or not it has a
/// semantics node: the first `Text` under the focused element, or the
/// tooltip of the `IconButton` it is in (the Back button's), or its type.
String _focusedWidget() {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return '(none)';
  String? text;
  void visit(Element e) {
    if (text != null) return;
    if (e.widget case Text(:final data?)) {
      text = data;
      return;
    }
    if (e.widget case Tooltip(:final message?)) {
      text = message;
      return;
    }
    e.visitChildren(visit);
  }

  (context as Element).visitChildren(visit);
  // The Back button draws an icon: its name is its tooltip, above it.
  text ??= context.findAncestorWidgetOfExactType<IconButton>()?.tooltip;
  return text ?? '(${context.widget.runtimeType})';
}

Future<void> _tab(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pump();
}

/// Tab until focus comes back to where the first Tab put it: one whole
/// focus cycle, as the widget with focus after each Tab, turned to start at
/// Back. At most twelve Tabs.
Future<List<String>> _focusCycle(WidgetTester tester) async {
  await _tab(tester);
  final first = FocusManager.instance.primaryFocus;
  final stops = [_focusedWidget()];
  for (var i = 0; i < 12; i++) {
    await _tab(tester);
    if (FocusManager.instance.primaryFocus == first) {
      final back = stops.indexOf('Back');
      expect(back, isNonNegative, reason: 'Back is in the cycle: $stops');
      return [...stops.sublist(back), ...stops.sublist(0, back)];
    }
    stops.add(_focusedWidget());
  }
  fail('focus did not come back to its first stop: $stops');
}

/// The example screen's pixels, as the route's repaint boundary draws them.
/// With [unfocus], keyboard focus is taken off first.
Future<List<int>> _screen(WidgetTester tester, {bool unfocus = false}) async {
  if (unfocus) {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }
  final element = tester.element(find.byType(ExampleScreen));
  final bytes = await tester.runAsync(() async {
    final image = await captureImage(element);
    final data = await image.toByteData();
    image.dispose();
    return data!.buffer.asUint8List().toList();
  });
  return bytes!;
}

/// Turns the panel's switch on with a tap.
Future<void> _show(WidgetTester tester, String slug) async {
  await tester.tap(byId('s12-$slug-show'));
  await tester.pumpAndSettle();
}

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
          skipOffstage: false,
        ),
      )
      .toList();
}

void main() {
  test('the technique has the examples named in the spec', () {
    expect(s12HidingContent.examples.map((e) => e.slug), [
      ..._good,
      'bad-decoration-read',
      'bad-hidden-control',
      'bad-opacity',
      'bad-maintain',
    ]);
    expect(_good, [
      for (final e in s12HidingContent.examples)
        if (e.kind == ExampleKind.good) e.slug,
    ]);
    expect(
      s12HidingContent.examples.where((e) => e.isCustomSolution),
      isEmpty,
      reason: 'no good example is flagged as a custom solution',
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
          if (slug == 'good-visibility') {
            await _show(tester, slug);
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
          handle.dispose();
        });
      }
    }

    for (final brightness in Brightness.values) {
      testWidgets('good-decoration: the ornaments, hidden from the guideline '
          'with their semantics, are 4.5:1 or more on the page '
          '(${brightness.name})', (tester) async {
        await _open(tester, 'good-decoration', brightness: brightness);
        final colors = Theme.of(tester.element(find.byType(GoodDecoration)))
            .colorScheme;
        for (final text in [quoteMark, ornament]) {
          final p = tester.renderObject<RenderParagraph>(
            find.descendant(
              of: find.byType(GoodDecoration),
              matching: find.text(text).hitTestable(),
            ),
          );
          final color = p.text.style!.color!;
          expect(
            _contrast(color, colors.surface),
            greaterThanOrEqualTo(4.5),
            reason: text,
          );
        }
      });

      testWidgets('good-badge: the badge, hidden from the guideline with its '
          'semantics, is 4.5:1 or more, its text on its colour, and its '
          'icon 3:1 or more on the page (${brightness.name})', (tester) async {
        await _open(tester, 'good-badge', brightness: brightness);
        final context = tester.element(find.byType(Badge));
        final colors = Theme.of(context).colorScheme;
        final badge = tester.widget<Badge>(find.byType(Badge));
        expect(badge.backgroundColor, isNull, reason: 'the theme\'s default');
        expect(badge.textColor, isNull, reason: 'the theme\'s default');
        // Material 3's defaults for a badge: error and onError.
        expect(
          _contrast(colors.onError, colors.error),
          greaterThanOrEqualTo(4.5),
        );
        final icon = tester.widget<RichText>(
          find.descendant(
            of: find.byIcon(Icons.mail_outline),
            matching: find.byType(RichText),
          ),
        );
        expect(
          _contrast(icon.text.style!.color!, colors.surface),
          greaterThanOrEqualTo(3),
        );
      });

      testWidgets('good-visibility: the switch\'s track is 3:1 or more on the '
          'page, off and on; the Copy button draws a 2 pixel outline 3:1 or '
          'more only with focus, and the text meets the contrast guideline '
          'with focus on the switch and on Copy (${brightness.name})', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, 'good-visibility', brightness: brightness);
        final colors = Theme.of(
          tester.element(byId('s12-good-visibility-show')),
        ).colorScheme;
        // Material 3's switch: off, the track's outline is `outline`; on,
        // the track is `primary` (SwitchThemeData defaults, source read).
        expect(
          _contrast(colors.outline, colors.surface),
          greaterThanOrEqualTo(3),
        );
        expect(
          _contrast(colors.primary, colors.surface),
          greaterThanOrEqualTo(3),
        );
        await _tab(tester); // Back
        await _tab(tester); // the switch
        expect(_focusedWidget(), 'Show tracking');
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await _show(tester, 'good-visibility');
        final copy = tester.widget<TextButton>(
          find.descendant(
            of: byId('s12-good-visibility-copy'),
            matching: find.byType(TextButton),
          ),
        );
        final side = copy.style!.side!.resolve({WidgetState.focused})!;
        expect(side.width, 2);
        expect(side.color, colors.onSurface);
        expect(_contrast(side.color, colors.surface), greaterThanOrEqualTo(3));
        expect(copy.style!.side!.resolve({}), isNull, reason: 'unfocused');
        await _tab(tester);
        expect(_focusedWidget(), 'Copy number');
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }

    testWidgets('good-decoration: the quote and who said it, and no ornament, '
        'anywhere on the screen', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-decoration');
      expect(_exampleNodes(tester).map(_describe), [quoteText, quoteSource]);
      for (final label in _allLabels(tester)) {
        expect(label, isNot(contains(quoteMark)));
        expect(label, isNot(contains('✦')));
      }
      handle.dispose();
    });

    testWidgets('good-badge: the words alone, and no node "3"', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-badge');
      expect(_exampleNodes(tester).map(_describe), [inboxText]);
      expect(_allLabels(tester), isNot(contains('3')));
      expect(_allLabels(tester).where((l) => l.contains('3')), [inboxText]);
      handle.dispose();
    });

    testWidgets('good-visibility: hidden, the panel has no node and the '
        'keyboard\'s whole cycle is Back and the switch; shown, the number '
        'and Copy are there and Tab reaches Copy', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-visibility');
      expect(_exampleNodes(tester).map(_describe), [
        'Show tracking | toggled=isFalse | tap',
      ]);
      expect(_allLabels(tester), isNot(contains(trackingText)));
      expect(_allLabels(tester), isNot(contains('Copy number')));
      expect(await _focusCycle(tester), ['Back', 'Show tracking']);
      // Positive control, in the same launch: shown, the panel is there,
      // and the keyboard reaches its button and copies.
      await _show(tester, 'good-visibility');
      expect(_exampleNodes(tester).map(_describe), [
        'Show tracking | toggled=isTrue | tap',
        trackingText,
        'Copy number | button | tap',
      ]);
      expect(await _focusCycle(tester), [
        'Back',
        'Show tracking',
        'Copy number',
      ]);
      handle.dispose();
    });

    for (final (key, name) in [
      (LogicalKeyboardKey.enter, 'Enter'),
      (LogicalKeyboardKey.space, 'Space'),
    ]) {
      testWidgets('good-visibility: hidden, the switch is the only stop but '
          'Back, and $name there shows the panel and copies nothing; then '
          'Tab to Copy and $name copies', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, 'good-visibility');
        await _tab(tester); // Back; Enter or Space there would leave.
        await _tab(tester);
        expect(_focusedWidget(), 'Show tracking');
        await tester.sendKeyEvent(key);
        await tester.pumpAndSettle();
        // The key acted on the switch, and showed the panel: it copied
        // nothing.
        expect(_count(tester, 's12-good-visibility-count'), 'Copies: 0');
        expect(find.text(trackingText).hitTestable(), findsOneWidget);
        // In the same launch, the panel shown: Tab to Copy, the key copies.
        await _tab(tester);
        expect(_focusedWidget(), 'Copy number');
        await tester.sendKeyEvent(key);
        await tester.pumpAndSettle();
        expect(_count(tester, 's12-good-visibility-count'), 'Copies: 1');
        handle.dispose();
      });
    }

    testWidgets('good-visibility: a tap and the tap action on Copy each copy '
        'once it is shown', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-visibility');
      await _show(tester, 'good-visibility');
      await tester.tap(byId('s12-good-visibility-copy'));
      await tester.pumpAndSettle();
      expect(_count(tester, 's12-good-visibility-count'), 'Copies: 1');
      tester.semantics.tap(nodeById('s12-good-visibility-copy'));
      await tester.pumpAndSettle();
      expect(_count(tester, 's12-good-visibility-count'), 'Copies: 2');
      handle.dispose();
    });
  });

  // Every example, good and bad: at 200% text on a 320 by 640 screen no
  // layout overflows, and no text in the example is cut short, by a line
  // limit or by a box too small for its lines. The panels are shown first,
  // so that their text is laid out.
  for (final example in s12HidingContent.examples) {
    final slug = example.slug;
    testWidgets('$slug: at 200% text on a phone nothing overflows and no '
        'text is cut short', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _open(tester, slug, textScale: 2);
      if (_panels.contains(slug)) {
        await tester.ensureVisible(byId('s12-$slug-show'));
        await tester.pumpAndSettle();
        await _show(tester, slug);
      }
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
    testWidgets('bad-decoration-read: each ornament is a node of its own, '
        'around the quote', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-decoration-read');
      expect(_exampleNodes(tester).map(_describe), [
        quoteMark,
        quoteText,
        quoteSource,
        ornament,
      ]);
      handle.dispose();
    });

    testWidgets('bad-hidden-control: no node for Share, which the keyboard '
        'still reaches with no node focused; Enter and Space run it, and a '
        'tap where it is drawn', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-hidden-control');
      expect(_exampleNodes(tester).map(_describe), [quoteText]);
      expect(_allLabels(tester), isNot(contains('Share')));
      expect(
        semanticsNodes(tester)
            .where((n) => n.flagsCollection.isButton && n.label != 'Back'),
        isEmpty,
      );
      expect(await _focusCycle(tester), ['Back', 'Share']);
      const count = 's12-bad-hidden-control-count';
      for (final (key, after) in [
        (LogicalKeyboardKey.enter, 'Shares: 1'),
        (LogicalKeyboardKey.space, 'Shares: 2'),
      ]) {
        // From the end of a cycle, focus is on Back; one more Tab is Share.
        while (_focusedWidget() != 'Share') {
          await _tab(tester);
        }
        expect(_focusedNodes(tester), isEmpty, reason: 'no node has focus');
        await tester.sendKeyEvent(key);
        await tester.pumpAndSettle();
        expect(_count(tester, count), after);
      }
      await tester.tap(
        find.byKey(const ValueKey<String>('s12-bad-hidden-control-share')),
      );
      await tester.pumpAndSettle();
      expect(_count(tester, count), 'Shares: 3');
      handle.dispose();
    });

    for (final slug in ['bad-opacity', 'bad-maintain']) {
      testWidgets('$slug: hidden, the panel is not drawn, and the keyboard '
          'reaches Copy and Enter and Space copy', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        expect(find.text(trackingText), findsOneWidget);
        // Not drawn: at opacity 0, or by Visibility, which paints nothing
        // while hidden (source read; the opacity is read here).
        if (slug == 'bad-opacity') {
          expect(
            tester
                .widget<Opacity>(
                  find.ancestor(
                    of: find.text(trackingText),
                    matching: find.byType(Opacity),
                  ),
                )
                .opacity,
            0,
          );
        } else {
          expect(
            tester
                .widget<Visibility>(
                  find.ancestor(
                    of: find.text(trackingText),
                    matching: find.byType(Visibility),
                  ),
                )
                .visible,
            isFalse,
          );
        }
        expect(await _focusCycle(tester), [
          'Back',
          'Show tracking',
          'Copy number',
        ]);
        final count = 's12-$slug-count';
        for (final (key, after) in [
          (LogicalKeyboardKey.enter, 'Copies: 1'),
          (LogicalKeyboardKey.space, 'Copies: 2'),
        ]) {
          while (_focusedWidget() != 'Copy number') {
            await _tab(tester);
          }
          await tester.sendKeyEvent(key);
          await tester.pumpAndSettle();
          expect(_count(tester, count), after);
        }
        // Still hidden: the keys acted on Copy, not on the switch.
        expect(
          tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
          isFalse,
        );
        handle.dispose();
      });
    }

    testWidgets('bad-opacity: hidden, no node for the number or Copy, which '
        'has keyboard focus with no node focused; a tap where Copy is laid '
        'out copies', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-opacity');
      expect(_exampleNodes(tester).map(_describe), [
        'Show tracking | toggled=isFalse | tap',
      ]);
      expect(_allLabels(tester), isNot(contains(trackingText)));
      expect(_allLabels(tester), isNot(contains('Copy number')));
      while (_focusedWidget() != 'Copy number') {
        await _tab(tester);
      }
      expect(_focusedNodes(tester), isEmpty, reason: 'no node has focus');
      await tester.tap(byId('s12-bad-opacity-copy'));
      await tester.pumpAndSettle();
      expect(_count(tester, 's12-bad-opacity-count'), 'Copies: 1');
      handle.dispose();
    });

    for (final slug in ['bad-opacity', 'bad-maintain']) {
      testWidgets('$slug: hidden, with keyboard focus on Copy the screen is '
          'drawn exactly as with no focus at all: no focus indicator shows; '
          'shown, focus on Copy changes the screen', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        final unfocused = await _screen(tester);
        while (_focusedWidget() != 'Copy number') {
          await _tab(tester);
        }
        await tester.pumpAndSettle();
        expect(
          await _screen(tester),
          unfocused,
          reason: 'focus on the hidden Copy draws nothing',
        );
        // Positive control, in the same launch and the same way: the panel
        // shown, focus on Copy draws its outline.
        await _show(tester, slug);
        final shownUnfocused = await _screen(tester, unfocus: true);
        while (_focusedWidget() != 'Copy number') {
          await _tab(tester);
        }
        await tester.pumpAndSettle();
        expect(await _screen(tester), isNot(shownUnfocused));
        handle.dispose();
      });
    }

    testWidgets('bad-maintain: hidden, the number and Copy are nodes as if '
        'shown, and Copy has the tap action', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-maintain');
      expect(_exampleNodes(tester).map(_describe), [
        'Show tracking | toggled=isFalse | tap',
        trackingText,
        'Copy number | button | tap',
      ]);
      tester.semantics.tap(nodeById('s12-bad-maintain-copy'));
      await tester.pumpAndSettle();
      expect(_count(tester, 's12-bad-maintain-count'), 'Copies: 1');
      handle.dispose();
    });
  });
}
