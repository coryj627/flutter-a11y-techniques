import 'dart:ui' show Tristate;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/app/screens.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/c05_accordion/c05_accordion.dart';
import 'package:flutter_a11y_techniques/techniques/c05_accordion/examples.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/examples.dart';

/// L1 for C05 Accordion (docs/specs/C05-accordion.md, section 6). These
/// tests run as Android unless a test sets another platform: `kIsWeb` is
/// false, so the web's heading node round each header is tested in
/// web_tests/c05_accordion.spec.js.
final _open = exampleOpener(c05Accordion);

const _good = ['good-material', 'good-cupertino', 'good-custom'];
final _shipping = sections[0];
final _returns = sections[1];

bool _focused(String id) =>
    dataById(id).flagsCollection.isFocused == Tristate.isTrue;

/// The name of the node with keyboard focus: its tooltip (Back) or label.
String? _focusName(WidgetTester tester) {
  final focused = semanticsNodes(tester)
      .where((n) => n.flagsCollection.isFocused == Tristate.isTrue)
      .toList();
  if (focused.isEmpty) return null;
  final n = focused.single;
  return n.tooltip.isNotEmpty ? n.tooltip : n.label;
}

/// Every stop of keyboard focus, Tab by Tab, [tabs] times, from where focus
/// is now. A stop on a control with no semantics node (one that is not on
/// screen) is "(hidden)": focus moved, and no node has it.
Future<List<String>> _tabStops(WidgetTester tester, int tabs) async {
  final stops = <String>[];
  for (var i = 0; i < tabs; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    stops.add(_focusName(tester) ?? '(hidden)');
  }
  return stops;
}

/// Whether the text [text] is on screen as a semantics node.
bool _readable(WidgetTester tester, String text) => semanticsNodes(
  tester,
  includeMerged: true,
).any((n) => n.label.contains(text));

/// The labels of the example's nodes in the order a screen reader reads
/// them, from the first header to the count.
List<String> _reading(WidgetTester tester) {
  final labels = [
    for (final n in semanticsNodes(tester))
      if (n.label.isNotEmpty) n.label,
  ];
  final start = labels.indexOf(_shipping.title);
  final end = labels.indexWhere((l) => l.startsWith('Presses: '));
  expect(start, greaterThanOrEqualTo(0), reason: 'the first header is read');
  expect(end, greaterThan(start), reason: 'the count comes last');
  return labels.sublist(start, end);
}

/// Taps the header of [section], scrolled into view first if it is not
/// wholly on the screen, just far enough for it to be, at the bottom of the
/// view, as a person scrolls to it: a custom solution's note above the
/// example (docs/custom-solutions.md) can push Returns below an 800 by 600
/// screen once Shipping is open. A header in view is not moved.
Future<void> _tapHeader(WidgetTester tester, Section section) async {
  await Scrollable.ensureVisible(
    tester.element(find.text(section.title)),
    alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(section.title));
  await tester.pumpAndSettle();
}

/// Scrolls, if need be, until the example's count is at the bottom of the
/// view, and checks that the whole example, from its first header to its
/// count, is then in the view: a guideline checked after this covers all
/// of the example, as when the example fitted under its title. A custom
/// solution's note above the example (docs/custom-solutions.md) can push
/// an open example's end below an 800 by 600 screen; the note itself is
/// checked in test/app/shell_a11y_test.dart.
Future<void> _showWholeExample(WidgetTester tester, String slug) async {
  final count = byId('c05-$slug-count');
  await Scrollable.ensureVisible(
    tester.element(count),
    alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
  );
  await tester.pumpAndSettle();
  final viewport = tester.getRect(
    find.ancestor(of: count, matching: find.byType(Scrollable)).first,
  );
  final top = tester.getRect(find.text(_shipping.title)).top;
  final bottom = tester.getRect(count).bottom;
  expect(top, greaterThanOrEqualTo(viewport.top), reason: '$slug: header');
  expect(bottom, lessThanOrEqualTo(viewport.bottom), reason: '$slug: count');
}

/// The colour of the focus ring round the header [id].
Color _ringColour(WidgetTester tester, String id) {
  final ring = find.descendant(of: byId(id), matching: find.byType(FocusRing));
  expect(ring, findsOneWidget, reason: '$id has one focus ring');
  final box = tester.widget<DecoratedBox>(
    find.descendant(of: ring, matching: find.byType(DecoratedBox)).first,
  );
  expect(box.position, DecorationPosition.foreground);
  return ((box.decoration as BoxDecoration).border! as Border).top.color;
}

/// The custom action that carries a tap hint: what TalkBack says a double
/// tap does.
int _tapHint(String hint) => CustomSemanticsAction.getIdentifier(
  CustomSemanticsAction.overridingAction(
    hint: hint,
    action: SemanticsAction.tap,
  ),
);

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
    expect(c05Accordion.examples.map((e) => e.slug), [
      ..._good,
      'bad-no-state',
      'bad-heading-on-button',
      'bad-no-heading',
      'bad-hidden-panel',
      'bad-expansion-tile',
      'bad-cupertino-expansion-tile',
    ]);
    expect(_good, [
      for (final e in c05Accordion.examples)
        if (e.kind == ExampleKind.good) e.slug,
    ]);
  });

  group('good examples', () {
    for (final slug in _good) {
      final shipping = headerId(slug, _shipping);
      final returns = headerId(slug, _returns);

      for (final brightness in Brightness.values) {
        for (final opened in [false, true]) {
          testWidgets('$slug meets the guidelines (${brightness.name}, '
              '${opened ? 'both sections open' : 'closed'})', (tester) async {
            final handle = tester.ensureSemantics();
            await _open(tester, slug, brightness: brightness);
            if (opened) {
              await _tapHeader(tester, _shipping);
              await _tapHeader(tester, _returns);
              expect(_readable(tester, _returns.text), isTrue);
            }
            await _showWholeExample(tester, slug);
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
            handle.dispose();
          });
        }
      }

      testWidgets('$slug: each header is a heading and a button with its '
          'title as its name, collapsed', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        for (final (id, section) in [
          (shipping, _shipping),
          (returns, _returns),
        ]) {
          final data = dataById(id);
          expect(data.label, section.title, reason: id);
          expect(data.flagsCollection.isButton, isTrue, reason: id);
          expect(data.headingLevel, headerLevel, reason: id);
          expect(data.flagsCollection.isExpanded, Tristate.isFalse, reason: id);
          expect(data.hasAction(SemanticsAction.tap), isTrue, reason: id);
          expect(
            data.customSemanticsActionIds,
            contains(_tapHint('expand')),
            reason: id,
          );
          // The state is not in the value off iOS (Android here).
          expect(data.value, isEmpty, reason: id);
          expect(data.hasAction(SemanticsAction.expand), isTrue, reason: id);
          expect(data.hasAction(SemanticsAction.collapse), isFalse, reason: id);
        }
        handle.dispose();
      });

      testWidgets('$slug: a closed section is neither read nor focused; an '
          'open one comes straight after its header', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        expect(_reading(tester), [_shipping.title, _returns.title]);
        expect(await _tabStops(tester, 4), [
          'Back',
          _shipping.title,
          _returns.title,
          'Back',
        ]);
        expect(dataById(shipping).controlsNodes, isNull);
        await _tapHeader(tester, _shipping);
        expect(dataById(shipping).flagsCollection.isExpanded, Tristate.isTrue);
        expect(dataById(returns).flagsCollection.isExpanded, Tristate.isFalse);
        // The open header names its panel, which is a node of its own.
        expect(dataById(shipping).controlsNodes, {panelId(shipping)});
        expect(dataById(panelId(shipping)).label, isEmpty);
        expect(dataById(returns).controlsNodes, isNull);
        expect(
          dataById(shipping).customSemanticsActionIds,
          contains(_tapHint('collapse')),
        );
        expect(_reading(tester), [
          _shipping.title,
          _shipping.text,
          _shipping.action,
          _returns.title,
        ]);
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        expect(await _tabStops(tester, 5), [
          'Back',
          _shipping.title,
          _shipping.action,
          _returns.title,
          'Back',
        ]);
        handle.dispose();
      });

      testWidgets('$slug: the tap action, which a screen reader sends, opens '
          'and closes a section', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        tester.semantics.tap(nodeById(shipping));
        await tester.pumpAndSettle();
        expect(dataById(shipping).flagsCollection.isExpanded, Tristate.isTrue);
        expect(_readable(tester, _shipping.text), isTrue);
        tester.semantics.tap(nodeById(shipping));
        await tester.pumpAndSettle();
        expect(dataById(shipping).flagsCollection.isExpanded, Tristate.isFalse);
        expect(_readable(tester, _shipping.text), isFalse);
        handle.dispose();
      });

      testWidgets('$slug: the expand and collapse actions open and close a '
          'section, each offered only where it applies', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        tester.semantics.performAction(
          nodeById(shipping),
          SemanticsAction.expand,
        );
        await tester.pumpAndSettle();
        expect(dataById(shipping).flagsCollection.isExpanded, Tristate.isTrue);
        expect(_readable(tester, _shipping.text), isTrue);
        expect(dataById(shipping).hasAction(SemanticsAction.expand), isFalse);
        expect(dataById(shipping).hasAction(SemanticsAction.collapse), isTrue);
        tester.semantics.performAction(
          nodeById(shipping),
          SemanticsAction.collapse,
        );
        await tester.pumpAndSettle();
        expect(dataById(shipping).flagsCollection.isExpanded, Tristate.isFalse);
        expect(_readable(tester, _shipping.text), isFalse);
        handle.dispose();
      });

      for (final (key, name) in [
        (LogicalKeyboardKey.enter, 'Enter'),
        (LogicalKeyboardKey.space, 'Space'),
      ]) {
        testWidgets('$slug: Tab reaches a header and $name opens and closes '
            'it', (tester) async {
          final handle = tester.ensureSemantics();
          await _open(tester, slug);
          await tabTo(tester, shipping);
          await tester.sendKeyEvent(key);
          await tester.pumpAndSettle();
          expect(
            dataById(shipping).flagsCollection.isExpanded,
            Tristate.isTrue,
          );
          expect(_readable(tester, _shipping.text), isTrue);
          expect(_focused(shipping), isTrue, reason: 'focus stays');
          await tester.sendKeyEvent(key);
          await tester.pumpAndSettle();
          expect(
            dataById(shipping).flagsCollection.isExpanded,
            Tristate.isFalse,
          );
          expect(_readable(tester, _shipping.text), isFalse);
          handle.dispose();
        });
      }

      testWidgets('$slug: Tab into an open panel reaches its button, and '
          'Enter presses it', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await _tapHeader(tester, _shipping);
        await tabTo(tester, shipping);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        expect(_focusName(tester), _shipping.action);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(countOf(tester, 'c05-$slug-count'), 1);
        handle.dispose();
      });

      for (final brightness in Brightness.values) {
        for (final opened in [false, true]) {
          testWidgets('$slug: keyboard focus draws the ring, and it goes '
              'when focus leaves (${brightness.name}, '
              '${opened ? 'open' : 'closed'})', (tester) async {
            final handle = tester.ensureSemantics();
            await _open(tester, slug, brightness: brightness);
            if (opened) await _tapHeader(tester, _shipping);
            final colors = Theme.of(tester.element(byId(shipping))).colorScheme;
            expect(_ringColour(tester, shipping), Colors.transparent);
            await tabTo(tester, shipping);
            expect(_ringColour(tester, shipping), colors.onSurface);
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.pump();
            expect(_focused(shipping), isFalse);
            expect(_ringColour(tester, shipping), Colors.transparent);
            handle.dispose();
          });
        }
      }

      testWidgets('$slug: on iOS the state is the value as well', (
        tester,
      ) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        expect(dataById(shipping).value, 'collapsed');
        await _tapHeader(tester, _shipping);
        expect(dataById(shipping).value, 'expanded');
        expect(dataById(returns).value, 'collapsed');
        handle.dispose();
        debugDefaultTargetPlatformOverride = null;
      });
    }
  });

  // Every example, bad ones too, closed and with both sections open, in
  // light and dark: the text contrast guideline, so that no bad example
  // has a contrast defect besides the one it is named for.
  for (final example in c05Accordion.examples) {
    for (final brightness in Brightness.values) {
      for (final opened in [false, true]) {
        testWidgets('${example.slug}: text contrast (${brightness.name}, '
            '${opened ? 'open' : 'closed'})', (tester) async {
          final handle = tester.ensureSemantics();
          await _open(tester, example.slug, brightness: brightness);
          if (opened) {
            await _tapHeader(tester, _shipping);
            await _tapHeader(tester, _returns);
            expect(find.text(_returns.text), findsOneWidget);
          }
          await _showWholeExample(tester, example.slug);
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          handle.dispose();
        });
      }
    }
  }

  // Every example, closed and with both sections open: at 200% text on a
  // 320 by 640 screen no layout overflows, and no text is cut short.
  for (final example in c05Accordion.examples) {
    final slug = example.slug;
    for (final opened in [false, true]) {
      testWidgets('$slug: at 200% text on a phone nothing overflows and no '
          'text is cut short (${opened ? 'open' : 'closed'})', (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await _open(tester, slug, textScale: 2);
        if (opened) {
          for (final s in sections) {
            await tester.ensureVisible(find.text(s.title));
            await tester.pumpAndSettle();
            await _tapHeader(tester, s);
          }
          expect(find.text(_returns.text), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        for (final p in _exampleParagraphs(tester, example)) {
          final text = p.text.toPlainText();
          expect(p.didExceedMaxLines, isFalse, reason: '"$text" line limit');
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
        }
      });
    }
  }

  group('bad examples have their defect', () {
    testWidgets('bad-no-state: buttons and headings with no expanded state, '
        'before and after a tap that opens the section', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-no-state');
      final id = headerId('bad-no-state', _shipping);
      expect(dataById(id).flagsCollection.isButton, isTrue);
      expect(dataById(id).headingLevel, headerLevel);
      expect(dataById(id).flagsCollection.isExpanded, Tristate.none);
      expect(dataById(id).value, isEmpty);
      await _tapHeader(tester, _shipping);
      // The positive control: the tap opened the section.
      expect(_readable(tester, _shipping.text), isTrue);
      expect(dataById(id).flagsCollection.isExpanded, Tristate.none);
      expect(dataById(id).value, isEmpty);
      handle.dispose();
    });

    testWidgets('bad-heading-on-button: one node that is a heading, a '
        'button, and expandable (off the web, where that works)', (
      tester,
    ) async {
      // The defect is on the web only: there the heading takes the node and
      // it is no button (web_tests/c05_accordion.spec.js).
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-heading-on-button');
      final data = dataById(headerId('bad-heading-on-button', _shipping));
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.headingLevel, headerLevel);
      expect(data.flagsCollection.isExpanded, Tristate.isFalse);
      handle.dispose();
    });

    testWidgets('bad-no-heading: drawn as the good headers are, and not a '
        'heading', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-no-heading');
      final data = dataById(headerId('bad-no-heading', _shipping));
      expect(data.headingLevel, 0);
      expect(data.flagsCollection.isHeader, isFalse);
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isExpanded, Tristate.isFalse);
      // The same text style as the good examples' headers.
      final style = tester.widget<Text>(find.text(_shipping.title)).style;
      final theme = Theme.of(tester.element(find.text(_shipping.title)));
      expect(style, theme.textTheme.titleMedium);
      expect(
        semanticsNodes(tester).where((n) => n.headingLevel == headerLevel),
        isEmpty,
      );
      handle.dispose();
    });

    testWidgets('bad-hidden-panel: closed panels are not read, but Tab stops '
        'on their buttons, and Enter presses one', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-hidden-panel');
      expect(_readable(tester, _shipping.text), isFalse);
      expect(_readable(tester, _shipping.action), isFalse);
      expect(_reading(tester), [_shipping.title, _returns.title]);
      // Tab reaches the hidden buttons after both headers, not after their
      // own (why was not looked into).
      expect(await _tabStops(tester, 5), [
        'Back',
        _shipping.title,
        _returns.title,
        '(hidden)',
        '(hidden)',
      ]);
      // Back to the first hidden stop, Shipping's button, and press it.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await _tabStops(tester, 4);
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<TextButton>()
            ?.child,
        isA<Text>().having((t) => t.data, 'text', _shipping.action),
      );
      expect(countOf(tester, 'c05-bad-hidden-panel-count'), 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(countOf(tester, 'c05-bad-hidden-panel-count'), 1);
      expect(
        _readable(tester, _shipping.text),
        isFalse,
        reason: 'still closed',
      );
      handle.dispose();
    });

    testWidgets('bad-expansion-tile: the header is no button and has no '
        'expanded state; the state is a hint', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-expansion-tile');
      SemanticsData header() =>
          semanticsNodes(tester).singleWhere((n) => n.label == _shipping.title);
      expect(header().flagsCollection.isButton, isFalse);
      expect(header().flagsCollection.isExpanded, Tristate.none);
      expect(header().headingLevel, 0);
      expect(header().hint, 'Collapsed');
      await _tapHeader(tester, _shipping);
      // The positive control: the tap opened it.
      expect(_readable(tester, _shipping.text), isTrue);
      expect(header().flagsCollection.isExpanded, Tristate.none);
      expect(header().hint, 'Expanded');
      handle.dispose();
    });

    for (final (key, name) in [
      (LogicalKeyboardKey.enter, 'Enter'),
      (LogicalKeyboardKey.space, 'Space'),
    ]) {
      testWidgets('bad-cupertino-expansion-tile: Tab reaches only Back, and '
          '$name there leaves the example closed', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, 'bad-cupertino-expansion-tile');
        expect(await _tabStops(tester, 4), ['Back', 'Back', 'Back', 'Back']);
        await tester.sendKeyEvent(key);
        await tester.pumpAndSettle();
        // The key acted: Back took it and the example left the screen.
        expect(find.byType(ExampleScreen), findsNothing, reason: name);
        expect(find.byType(TechniqueScreen), findsOneWidget, reason: name);
        handle.dispose();
      });
    }

    testWidgets('bad-cupertino-expansion-tile: the header is no button and '
        'has no expanded state, and a tap opens it', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-cupertino-expansion-tile');
      final header = semanticsNodes(tester)
          .singleWhere((n) => n.label == _shipping.title);
      expect(header.flagsCollection.isButton, isFalse);
      expect(header.flagsCollection.isExpanded, Tristate.none);
      expect(header.flagsCollection.isFocused, Tristate.none);
      await _tapHeader(tester, _shipping);
      expect(_readable(tester, _shipping.text), isTrue);
      handle.dispose();
    });
  });

  // The tests above rely on running off the web (see the top of the file).
  test('kIsWeb is false here', () => expect(kIsWeb, isFalse));
}
