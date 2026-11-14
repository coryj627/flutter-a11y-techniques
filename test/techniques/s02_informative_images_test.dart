import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_a11y_techniques/app/app.dart';
import 'package:flutter_a11y_techniques/catalog/registry.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/s02_informative_images/examples.dart';
import 'package:flutter_a11y_techniques/techniques/s02_informative_images/s02_informative_images.dart';
import 'package:flutter_test/flutter_test.dart';

/// L1 for S02 Informative images (docs/specs/S02-informative-images.md).
/// Images have no controls to identify, so they are found by their label.
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
      registry: TechniqueRegistry([s02InformativeImages]),
      platform: AppPlatform.android,
      initialRoute: '/t/S02/$slug',
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
    for (final e in s02InformativeImages.examples)
      if (e.kind == ExampleKind.good) e.slug,
  ];

  test('the technique has the examples named in the spec', () {
    expect(s02InformativeImages.examples.map((e) => e.slug), [
      'good-image-label',
      'good-icon-label',
      'good-group-description',
      'good-chart',
      'bad-no-label',
      'bad-icon-no-label',
      'bad-role-in-label',
      'bad-filename-label',
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

    testWidgets('good-image-label: an image with a name', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-image-label');
      final photo = _labelled(tester, 'Sunrise over green hills');
      expect(_isImage(photo), isTrue);
      expect(_all(tester).where(_isImage), hasLength(1));
      // The picture itself was decoded and is on screen.
      final image = tester.widget<RawImage>(find.byType(RawImage));
      expect(image.image, isNotNull);
      handle.dispose();
    });

    testWidgets('good-icon-label: each row reads its status and its order', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-icon-label');
      final labels = _all(tester).map((d) => d.label).toList();
      expect(labels, contains('Delivered\nOrder 1042'));
      expect(labels, contains('Delayed\nOrder 1043'));
      // The status is not also a separate element.
      expect(labels, isNot(contains('Delivered')));
      expect(labels, isNot(contains('Order 1042')));
      handle.dispose();
    });

    testWidgets('good-group-description: one description, parts not read', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-group-description');
      final labels = _all(tester).map((d) => d.label).toList();
      expect(labels.where((l) => l == 'Sunrise at 6:35 am'), hasLength(1));
      expect(labels.where((l) => l.contains('6:35 am')), hasLength(1));
      // The time is still shown.
      expect(find.text('6:35 am'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('good-chart: an image with a short name, and its data in '
        'text', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-chart');
      final chart = _labelled(
        tester,
        'Bar chart: orders rose every quarter of 2025',
      );
      expect(_isImage(chart), isTrue);
      final text = _labelled(
        tester,
        'Orders in 2025: Q1 20, Q2 35, Q3 50, Q4 80.',
      );
      expect(_isImage(text), isFalse);
      handle.dispose();
    });
  });

  group('bad examples', () {
    testWidgets('bad-no-label: an image with no name', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-no-label');
      expect(find.byType(RawImage), findsOneWidget);
      final images = _all(tester).where(_isImage).toList();
      expect(images, hasLength(1));
      expect(images.single.label, isEmpty);
      expect(images.single.tooltip, isEmpty);
      expect(images.single.value, isEmpty);
      // Nothing on the screen says what the picture shows.
      expect(
        _all(tester).where((d) => d.label.toLowerCase().contains('sunrise')),
        isEmpty,
      );
      handle.dispose();
    });

    testWidgets('bad-icon-no-label: the rows read as order numbers only', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-icon-no-label');
      final labels = _all(tester).map((d) => d.label).toList();
      expect(labels, contains('Order 1042'));
      expect(labels, contains('Order 1043'));
      for (final status in ['Delivered', 'Delayed']) {
        expect(labels.where((l) => l.contains(status)), isEmpty);
      }
      // The icons are drawn; only their meaning is missing.
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
      handle.dispose();
    });

    testWidgets('bad-role-in-label: the name starts with the role', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-role-in-label');
      final image = _all(tester).singleWhere(_isImage);
      expect(image.label.toLowerCase(), startsWith('image'));
      handle.dispose();
    });

    testWidgets('bad-filename-label: the name is a file name', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-filename-label');
      final image = _all(tester).singleWhere(_isImage);
      expect(image.label, 'IMG_2041.png');
      expect(image.label, matches(RegExp(r'\.(png|jpe?g|gif|webp)$')));
      handle.dispose();
    });
  });

  test('the examples are exported for the registry', () {
    expect(const GoodImageLabel(), isA<Widget>());
  });
}
