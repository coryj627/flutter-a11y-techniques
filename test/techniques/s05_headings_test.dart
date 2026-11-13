import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_a11y_techniques/app/app.dart';
import 'package:flutter_a11y_techniques/catalog/registry.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/s05_headings/s05_headings.dart';
import 'package:flutter_test/flutter_test.dart';

/// L1 for S05 Headings (docs/specs/S05-headings.md).
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
      registry: TechniqueRegistry([s05Headings]),
      platform: AppPlatform.android,
      initialRoute: '/t/S05/$slug',
    ),
  );
  await tester.pumpAndSettle();
}

SemanticsData _data(WidgetTester tester, String text) =>
    tester.getSemantics(find.text(text)).getSemanticsData();

/// Heading level of the node showing [text]; 0 when it is not a heading.
int _level(WidgetTester tester, String text) {
  final data = _data(tester, text);
  return data.flagsCollection.isHeader ? data.headingLevel : 0;
}

bool _isHeading(WidgetTester tester, String text) =>
    _data(tester, text).flagsCollection.isHeader ||
    _data(tester, text).headingLevel > 0;

/// Every heading on the screen, in reading order, as (level, label).
List<(int, String)> _outline(WidgetTester tester) {
  final found = <(int, String)>[];
  void visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    if (data.flagsCollection.isHeader || data.headingLevel > 0) {
      found.add((data.headingLevel, data.label));
    }
    // Traversal order is the order a screen reader moves through the screen.
    node
        .debugListChildrenInOrder(DebugSemanticsDumpOrder.traversalOrder)
        .forEach(visit);
  }

  visit(tester.getSemantics(find.byType(Scaffold)));
  return found;
}

void main() {
  final goodSlugs = [
    for (final e in s05Headings.examples)
      if (e.kind == ExampleKind.good) e.slug,
  ];

  test('the technique has the examples named in the spec', () {
    expect(s05Headings.examples.map((e) => e.slug), [
      'good-levels',
      'good-cupertino',
      'bad-visual-only',
      'bad-fake-label',
      'bad-skipped-level',
      'bad-header-only',
      'bad-emphasis-heading',
      'bad-cupertino-section-header',
    ]);
  });

  group('good examples', () {
    for (final slug in goodSlugs) {
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

    testWidgets('good-levels: the outline starts at the screen title and '
        'never skips a level going down', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-levels');
      final outline = _outline(tester);
      expect(outline, [
        (1, 'Headings with levels'),
        (2, 'Example'),
        (3, 'Profile'),
        (4, 'Contact details'),
        (4, 'Email preferences'),
        (3, 'Security'),
      ]);
      for (var i = 1; i < outline.length; i++) {
        expect(
          outline[i].$1 - outline[i - 1].$1,
          lessThanOrEqualTo(1),
          reason: '${outline[i - 1]} then ${outline[i]}',
        );
      }
      // Body text is not a heading.
      expect(_isHeading(tester, 'Choose which messages you receive.'), isFalse);
      handle.dispose();
    });

    testWidgets('good-cupertino: the section header is a level 3 heading', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-cupertino');
      expect(_level(tester, 'Notifications'), 3);
      expect(_isHeading(tester, 'Order updates'), isFalse);
      handle.dispose();
    });
  });

  // VAL-3: each bad example is asserted to have its named defect.
  group('bad examples have their defect', () {
    testWidgets('bad-visual-only: looks like a heading, is not one', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-visual-only');
      expect(_isHeading(tester, 'Profile'), isFalse);
      // It is styled exactly like the real level 3 heading.
      final style = tester.widget<Text>(find.text('Profile')).style;
      expect(
        style,
        Theme.of(tester.element(find.text('Profile'))).textTheme.titleLarge,
      );
      handle.dispose();
    });

    testWidgets('bad-fake-label: "heading" is in the name, not the role', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-fake-label');
      final data = _data(tester, 'Profile');
      expect(data.label, 'Profile, heading');
      expect(data.flagsCollection.isHeader, isFalse);
      expect(data.headingLevel, 0);
      handle.dispose();
    });

    testWidgets('bad-skipped-level: level 5 directly after level 3', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-skipped-level');
      expect(_level(tester, 'Profile'), 3);
      expect(_level(tester, 'Contact details'), 5);
      handle.dispose();
    });

    testWidgets('bad-header-only: a header with no level (Flutter '
        'limitation)', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-header-only');
      final data = _data(tester, 'Profile');
      expect(data.flagsCollection.isHeader, isTrue);
      // No level is carried, so each platform decides what this is.
      expect(data.headingLevel, 0);
      handle.dispose();
    });

    testWidgets('bad-emphasis-heading: a sentence is marked as a heading', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-emphasis-heading');
      expect(_level(tester, 'Please check your address before you pay.'), 4);
      // It is body-sized text, and it ends like a sentence.
      final text = tester.widget<Text>(
        find.text('Please check your address before you pay.'),
      );
      expect(text.style?.fontSize, lessThanOrEqualTo(16));
      expect(text.data, endsWith('.'));
      handle.dispose();
    });

    testWidgets('bad-cupertino-section-header: not a heading (Flutter '
        'limitation)', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-cupertino-section-header');
      // If this starts failing after an upgrade, CupertinoListSection has
      // begun exposing its header and the wrapper in good-cupertino can go.
      expect(_isHeading(tester, 'Notifications'), isFalse);
      handle.dispose();
    });
  });

  testWidgets('the screen title is the level 1 heading on every screen', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    for (final route in ['/', '/about', '/t/S05', '/t/S05/good-levels']) {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        A11yTechniquesApp(
          registry: TechniqueRegistry([s05Headings]),
          platform: AppPlatform.android,
          initialRoute: route,
        ),
      );
      await tester.pumpAndSettle();
      final levelOnes = _outline(tester).where((h) => h.$1 == 1);
      expect(levelOnes, hasLength(1), reason: route);
    }
    handle.dispose();
  });
}
