import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_a11y_techniques/app/app.dart';
import 'package:flutter_a11y_techniques/catalog/registry.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/s03_decorative_images/examples.dart';
import 'package:flutter_a11y_techniques/techniques/s03_decorative_images/s03_decorative_images.dart';
import 'package:flutter_test/flutter_test.dart';

/// L1 for S03 Decorative images (docs/specs/S03-decorative-images.md).
/// Images have no controls to identify, so nodes are found by their label.
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
      registry: TechniqueRegistry([s03DecorativeImages]),
      platform: AppPlatform.android,
      initialRoute: '/t/S03/$slug',
    ),
  );
  // Image.memory decodes on a real async gap.
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

/// The data of every semantics node on the screen, in traversal order.
List<SemanticsData> _all(WidgetTester tester) {
  final found = <SemanticsData>[];
  void visit(SemanticsNode node) {
    found.add(node.getSemanticsData());
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return found;
}

bool _isImage(SemanticsData data) => data.flagsCollection.isImage;

/// The node whose label is exactly [label].
SemanticsData _labelled(WidgetTester tester, String label) =>
    _all(tester).singleWhere((d) => d.label == label);

void main() {
  final goodSlugs = [
    for (final e in s03DecorativeImages.examples)
      if (e.kind == ExampleKind.good) e.slug,
  ];

  List<String> labels(WidgetTester tester) =>
      _all(tester).map((d) => d.label).where((l) => l.isNotEmpty).toList();

  /// The labels of the example itself: what lies between the "Example"
  /// heading and the app bar, which comes last in the tree.
  List<String> example(WidgetTester tester) {
    final all = labels(tester);
    return all.sublist(all.indexOf('Example') + 1, all.indexOf('Back'));
  }

  test('the technique has the examples named in the spec', () {
    expect(s03DecorativeImages.examples.map((e) => e.slug), [
      'good-image-excluded',
      'good-icon-no-label',
      'good-background-image',
      'good-exclude-semantics',
      'good-merged-row',
      'bad-not-excluded',
      'bad-empty-label',
      'bad-redundant-label',
      'bad-merged-image',
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

    testWidgets('good-image-excluded: the banner is drawn and not exposed', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-image-excluded');
      expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
      expect(_all(tester).where(_isImage), isEmpty);
      expect(example(tester), [
        'Welcome back, Ana.',
        'You have 2 new messages.',
      ]);
      handle.dispose();
    });

    testWidgets('good-icon-no-label: only the words are exposed', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-icon-no-label');
      expect(find.byIcon(Icons.local_shipping), findsOneWidget);
      expect(find.byIcon(Icons.replay), findsOneWidget);
      expect(example(tester), [
        'Shipping',
        'Returns',
        'Delivery takes 2 to 4 days.',
      ]);
      expect(_all(tester).where(_isImage), isEmpty);
      handle.dispose();
    });

    testWidgets('good-background-image: the decoration is not exposed', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-background-image');
      final box = tester.widget<DecoratedBox>(
        find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).image != null,
        ),
      );
      expect((box.decoration as BoxDecoration).image, isNotNull);
      expect(_all(tester).where(_isImage), isEmpty);
      expect(example(tester), [
        'Welcome back, Ana.',
        'You have 2 new messages.',
      ]);
      handle.dispose();
    });

    testWidgets('good-exclude-semantics: the initials are shown, not exposed', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-exclude-semantics');
      expect(find.text('AK'), findsOneWidget);
      expect(example(tester), ['Ana Kovac']);
      handle.dispose();
    });

    testWidgets('good-merged-row: the row is its text and not an image', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-merged-row');
      expect(find.byType(RawImage), findsOneWidget);
      final row = _labelled(tester, 'Trail guide\n12 routes');
      expect(_isImage(row), isFalse);
      expect(_all(tester).where(_isImage), isEmpty);
      handle.dispose();
    });
  });

  group('bad examples', () {
    for (final slug in ['bad-not-excluded', 'bad-empty-label']) {
      testWidgets('$slug: the banner is an image with no name', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        final images = _all(tester).where(_isImage).toList();
        expect(images, hasLength(1));
        expect(images.single.label, isEmpty);
        expect(images.single.tooltip, isEmpty);
        expect(images.single.value, isEmpty);
        expect(example(tester), [
          'Welcome back, Ana.',
          'You have 2 new messages.',
        ]);
        handle.dispose();
      });
    }

    testWidgets('bad-empty-label: the label given is the empty string', (
      tester,
    ) async {
      await _open(tester, 'bad-empty-label');
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.semanticLabel, '');
      expect(image.excludeFromSemantics, isFalse);
    });

    testWidgets('bad-redundant-label: every word is exposed twice', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-redundant-label');
      expect(example(tester), [
        'Shipping',
        'Shipping',
        'Returns',
        'Returns',
        'Delivery takes 2 to 4 days.',
      ]);
      handle.dispose();
    });

    testWidgets('bad-merged-image: the row of text is an image', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-merged-image');
      final row = _labelled(tester, 'Trail guide\n12 routes');
      expect(_isImage(row), isTrue);
      handle.dispose();
    });
  });

  test('the examples are exported for the registry', () {
    expect(const GoodImageExcluded(), isA<Widget>());
  });
}
