import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/s06_screen_titles/examples.dart';
import 'package:flutter_a11y_techniques/techniques/s06_screen_titles/s06_screen_titles.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/examples.dart';

/// L1 for S06 Screen and page titles (docs/specs/S06-screen-titles.md,
/// section 6). Each example is a button that opens a screen; these tests
/// open it and read what the framework gives a screen reader as the
/// screen's name (the node with `namesRoute` inside the last route, which
/// is what Android's and iOS's engines read, in their source) and every
/// document title the app sends (`SystemChrome.setApplicationSwitcherDescription`,
/// which the web engine writes to `document.title`). What the browser,
/// TalkBack, and VoiceOver then do with them is measured in the device and
/// web tests.
final _open = exampleOpener(s06ScreenTitles);

const _good = ['good-material', 'good-cupertino'];
const _cupertino = {'good-cupertino', 'bad-cupertino-unnamed'};
const _all = [
  ..._good,
  'bad-no-title',
  'bad-vague-title',
  'bad-no-document-title',
  'bad-cupertino-unnamed',
];

/// The example screen's own title, which the app's PageScaffold sends.
String _exampleTitle(String slug) =>
    '${s06ScreenTitles.example(slug)!.title} - Flutter A11Y Techniques';

/// Records every document title the app sends from now on.
List<String> _recordTitles(WidgetTester tester) {
  final titles = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'SystemChrome.setApplicationSwitcherDescription') {
        titles.add((call.arguments as Map)['label'] as String);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return titles;
}

/// The routes on the screen, in the tree's order, each with the name the
/// platform engines would give it: the first non-empty label of a node
/// with `namesRoute`, depth first, or null.
List<(int, String?)> _routes(WidgetTester tester) {
  final out = <(int, String?)>[];
  String? nameIn(SemanticsNode n) {
    final d = n.getSemanticsData();
    if (d.flagsCollection.namesRoute && d.label.isNotEmpty) return d.label;
    String? found;
    n.visitChildren((c) {
      found ??= nameIn(c);
      return found == null;
    });
    return found;
  }

  void visit(SemanticsNode n) {
    if (n.getSemanticsData().flagsCollection.scopesRoute) {
      out.add((n.id, nameIn(n)));
    }
    n.visitChildren((c) {
      visit(c);
      return true;
    });
  }

  visit(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return out;
}

/// The name of the last route, the one shown.
String? _shownRouteName(WidgetTester tester) => _routes(tester).last.$2;

Future<void> _openScreen(WidgetTester tester, String slug) async {
  await tester.ensureVisible(byId('s06-$slug-open'));
  await tester.pumpAndSettle();
  await tester.tap(byId('s06-$slug-open'));
  await tester.pumpAndSettle();
  expect(find.text(screenText), findsOneWidget, reason: '$slug opened');
}

Future<void> _back(WidgetTester tester) async {
  final material = find.byType(BackButton);
  await tester.tap(
    material.evaluate().isNotEmpty
        ? material.last
        : find.byType(CupertinoNavigationBarBackButton),
  );
  await tester.pumpAndSettle();
  expect(find.text(screenText), findsNothing, reason: 'closed');
}

/// The nodes that are headings, with their level, on the shown screen.
List<String> _headings(WidgetTester tester) => [
  for (final n in semanticsNodes(tester))
    if (n.flagsCollection.isHeader || n.headingLevel > 0)
      '${n.label} (level ${n.headingLevel})',
];

void main() {
  test('the technique has the examples named in the spec', () {
    expect(s06ScreenTitles.examples.map((e) => e.slug), _all);
    expect(_good, [
      for (final e in s06ScreenTitles.examples)
        if (e.kind == ExampleKind.good) e.slug,
    ]);
    expect(
      s06ScreenTitles.examples.where((e) => e.isCustomSolution),
      isEmpty,
      reason: 'no good example is a custom solution',
    );
  });

  // The guidelines and 200% text for every example, good and bad: the
  // bad examples' one defect is their title, and nothing else may fail.
  group('every example', () {
    for (final slug in _all) {
      for (final brightness in Brightness.values) {
        testWidgets('$slug: the example and the screen it opens meet the '
            'guidelines (${brightness.name})', (tester) async {
          final handle = tester.ensureSemantics();
          await _open(tester, slug, brightness: brightness);
          Future<void> check({bool labeled = true}) async {
            await expectLater(
              tester,
              meetsGuideline(androidTapTargetGuideline),
            );
            await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
            if (labeled) {
              await expectLater(
                tester,
                meetsGuideline(labeledTapTargetGuideline),
              );
            }
            await expectLater(tester, meetsGuideline(textContrastGuideline));
          }

          await check();
          await tabTo(tester, 's06-$slug-open');
          await tester.pumpAndSettle();
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          await _openScreen(tester, slug);
          // Skipped on the Cupertino screen: Cupertino's own Back button
          // takes the tap on a node with no name (FL-303), which the test
          // below asserts.
          await check(labeled: !_cupertino.contains(slug));
          handle.dispose();
        });
      }

      // 200% text on CI's phone screen, 320 by 640: nothing overflows and
      // no text is cut short, on the example and on the screen it opens.
      // The title is one line in its bar (AppBar and CupertinoNavigationBar
      // both draw it so), so a title cut short shows here.
      testWidgets('$slug: at 200% text on a 320 by 640 screen nothing '
          'overflows and no text is cut short', (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await _open(tester, slug, textScale: 2);
        expect(tester.takeException(), isNull);
        // On the example screen, the example's own text: the app bar there
        // is the app's, and is not this example's.
        void noneCut(String where, Finder within) {
          for (final p in tester.renderObjectList<RenderParagraph>(
            find.descendant(of: within, matching: find.byType(RichText)),
          )) {
            final text = p.text.toPlainText();
            expect(
              p.didExceedMaxLines,
              isFalse,
              reason: '$where: "$text" was cut short',
            );
          }
        }

        noneCut('the example', find.byType(OpenScreen));
        await _openScreen(tester, slug);
        expect(tester.takeException(), isNull);
        // The whole opened screen, its title in its bar included.
        noneCut('the opened screen', find.byType(Title).last);
      });
    }
  });

  group('the screen opened: its name and its document title', () {
    testWidgets('good-material: the route is named "Order history", the '
        'document title is "Order history", and the title is the level 1 '
        'heading', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-material');
      final titles = _recordTitles(tester);
      await _openScreen(tester, 'good-material');
      expect(_shownRouteName(tester), screenTitle);
      expect(titles, [screenTitle]);
      expect(_headings(tester), ['$screenTitle (level 1)']);
      handle.dispose();
    });

    testWidgets('good-cupertino: the same, from Semantics(namesRoute: true) '
        'round the bar\'s middle', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-cupertino');
      final titles = _recordTitles(tester);
      await _openScreen(tester, 'good-cupertino');
      expect(_shownRouteName(tester), screenTitle);
      expect(titles, [screenTitle]);
      expect(_headings(tester), ['$screenTitle (level 1)']);
      handle.dispose();
    });

    testWidgets('bad-cupertino-unnamed: the route has no name, and the '
        'document title and the heading are right (FL-301)', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-cupertino-unnamed');
      final titles = _recordTitles(tester);
      await _openScreen(tester, 'bad-cupertino-unnamed');
      expect(_shownRouteName(tester), isNull);
      expect(titles, [screenTitle]);
      expect(_headings(tester), ['$screenTitle (level 1)']);
      handle.dispose();
    });

    testWidgets('bad-no-title: no route name, no document title sent, and '
        'no heading: the large text is plain text', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-no-title');
      final titles = _recordTitles(tester);
      await _openScreen(tester, 'bad-no-title');
      expect(_shownRouteName(tester), isNull);
      expect(titles, isEmpty);
      expect(_headings(tester), isEmpty);
      expect(find.text(screenTitle), findsOneWidget);
      handle.dispose();
    });

    testWidgets('bad-vague-title: the route, the document, and the heading '
        'are all "Details"', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-vague-title');
      final titles = _recordTitles(tester);
      await _openScreen(tester, 'bad-vague-title');
      expect(_shownRouteName(tester), 'Details');
      expect(titles, ['Details']);
      expect(_headings(tester), ['Details (level 1)']);
      handle.dispose();
    });

    testWidgets('bad-no-document-title: the route is named, and no document '
        'title is sent, so the example screen\'s stays', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-no-document-title');
      final titles = _recordTitles(tester);
      await _openScreen(tester, 'bad-no-document-title');
      expect(_shownRouteName(tester), screenTitle);
      expect(titles, isEmpty);
      // The positive control, in the same launch: good-material's screen
      // sends its title through the same channel.
      await tester.pumpWidget(const SizedBox());
      await _open(tester, 'good-material');
      await _openScreen(tester, 'good-material');
      expect(titles, contains(screenTitle));
      handle.dispose();
    });
  });

  group('closing the screen (FL-300)', () {
    for (final slug in _all) {
      testWidgets('$slug: Back sends no document title, and the route shown '
          'is the example screen again', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        final titles = _recordTitles(tester);
        await _openScreen(tester, slug);
        final opened = List.of(titles);
        await _back(tester);
        // Written to fail if Flutter starts to send the title of the
        // screen shown again: nothing at all is sent on Back.
        expect(titles, opened, reason: 'nothing sent on Back');
        expect(_shownRouteName(tester), s06ScreenTitles.example(slug)!.title);
        handle.dispose();
      });
    }

    testWidgets('the example screen sent its own title when it opened, which '
        'is what Back would have to send again', (tester) async {
      final titles = _recordTitles(tester);
      await _open(tester, 'good-material');
      expect(titles.last, _exampleTitle('good-material'));
    });
  });

  group('Cupertino\'s Back button (FL-303)', () {
    for (final slug in ['good-cupertino', 'bad-cupertino-unnamed']) {
      testWidgets('$slug: the node that takes the tap has no name, and the '
          'node named Back takes no tap', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await _openScreen(tester, slug);
        expect(find.byType(CupertinoNavigationBarBackButton), findsOneWidget);
        final tappable = [
          for (final n in semanticsNodes(tester))
            if (n.hasAction(SemanticsAction.tap) && n.label.isEmpty) n,
        ];
        final named = [
          for (final n in semanticsNodes(tester))
            if (n.label == 'Back') n,
        ];
        expect(tappable, hasLength(1), reason: 'one tappable node, unnamed');
        expect(named, hasLength(1));
        expect(named.single.flagsCollection.isButton, isTrue);
        expect(named.single.hasAction(SemanticsAction.tap), isFalse);
        handle.dispose();
      });
    }

    testWidgets('positive control: Material\'s Back button is one node, '
        'named, that takes the tap', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-material');
      await _openScreen(tester, 'good-material');
      final named = [
        for (final n in semanticsNodes(tester))
          if (n.tooltip == 'Back' || n.label == 'Back') n,
      ];
      expect(named, hasLength(1));
      expect(named.single.hasAction(SemanticsAction.tap), isTrue);
      expect([
        for (final n in semanticsNodes(tester))
          if (n.hasAction(SemanticsAction.tap) &&
              n.label.isEmpty &&
              n.tooltip.isEmpty)
            n,
      ], isEmpty);
      handle.dispose();
    });
  });

  group('as iOS (FL-302)', () {
    for (final slug in ['good-material', 'good-cupertino']) {
      testWidgets('$slug: the route name on iOS', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await _openScreen(tester, slug);
        // AppBar sets namesRoute on Android, Fuchsia, Linux, and Windows
        // only (material/app_bar.dart); good-cupertino sets it itself.
        expect(
          _shownRouteName(tester),
          slug == 'good-material' ? isNull : screenTitle,
        );
        expect(_headings(tester), ['$screenTitle (level 1)']);
        handle.dispose();
        debugDefaultTargetPlatformOverride = null;
      });
    }
  });

  group('keyboard', () {
    for (final slug in _all) {
      testWidgets('$slug: Tab reaches the button, and Enter and Space each '
          'open the screen', (tester) async {
        final handle = tester.ensureSemantics();
        for (final key in [
          LogicalKeyboardKey.enter,
          LogicalKeyboardKey.space,
        ]) {
          // A fresh app for each key: pumping the app again would keep its
          // Navigator, and the screen the first key opened.
          await tester.pumpWidget(const SizedBox());
          await _open(tester, slug);
          await tabTo(tester, 's06-$slug-open');
          expect(find.text(screenText), findsNothing);
          await tester.sendKeyEvent(key);
          await tester.pumpAndSettle();
          expect(
            find.text(screenText),
            findsOneWidget,
            reason: '${key.keyLabel} opened it',
          );
        }
        handle.dispose();
      });
    }
  });
}
