import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/app/app.dart';
import 'package:flutter_a11y_techniques/catalog/registry.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/s04_functional_images/s04_functional_images.dart';
import 'package:flutter_test/flutter_test.dart';

/// L1 for S04 Functional images (docs/specs/S04-functional-images.md).
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
      registry: TechniqueRegistry([s04FunctionalImages]),
      platform: AppPlatform.android,
      initialRoute: '/t/S04/$slug',
    ),
  );
  await tester.pumpAndSettle();
}

Finder _id(String id) => find.byKey(ValueKey<String>(id));

SemanticsData _data(WidgetTester tester, Finder finder) =>
    tester.getSemantics(finder).getSemanticsData();

/// The accessible name: the label, or the tooltip when there is no label
/// (an `IconButton` is named by its tooltip).
String _name(SemanticsData data) =>
    data.label.isNotEmpty ? data.label : data.tooltip;

int _count(WidgetTester tester, String slug) {
  final text = tester.widget<Text>(
    find.descendant(of: _id('s04-$slug-count'), matching: find.byType(Text)),
  );
  return int.parse(text.data!.split(': ').last);
}

bool _focused(WidgetTester tester, Finder finder) =>
    _data(tester, finder).flagsCollection.isFocused == Tristate.isTrue;

/// Every node below the "Example" heading that is an image.
List<SemanticsData> _imageNodes(WidgetTester tester) {
  final found = <SemanticsData>[];
  void visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    if (data.flagsCollection.isImage) found.add(data);
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

/// Identifiers of the good examples' buttons, with their expected names.
const _good = {
  'good-image-button': {'s04-good-image-button-guide': 'Open trail guide'},
  'good-icon-label': {'s04-good-icon-label-search': 'Search'},
  'good-image-with-text': {
    's04-good-image-with-text-guide': 'Trail guide',
    's04-good-image-with-text-print': 'Print',
  },
  'good-cupertino': {'s04-good-cupertino-search': 'Search'},
  'good-custom': {'s04-good-custom-guide': 'Open trail guide'},
  'good-image-regions': {
    's04-good-image-regions-west': 'West trail',
    's04-good-image-regions-east': 'East trail',
  },
};

void main() {
  test('the technique has the examples named in the spec', () {
    expect(s04FunctionalImages.examples.map((e) => e.slug), [
      ..._good.keys,
      'bad-no-name',
      'bad-label-on-image',
      'bad-tap-gesture',
      'bad-describes-picture',
      'bad-image-not-excluded',
      'bad-redundant-label',
    ]);
    expect(_good.keys, [
      for (final e in s04FunctionalImages.examples)
        if (e.kind == ExampleKind.good) e.slug,
    ]);
  });

  group('good examples', () {
    for (final MapEntry(key: slug, value: buttons) in _good.entries) {
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

      testWidgets('$slug: a named button that is not an image, and it works', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        var expected = 0;
        for (final MapEntry(key: id, value: name) in buttons.entries) {
          final data = _data(tester, _id(id));
          expect(_name(data), name, reason: id);
          expect(data.identifier, id);
          expect(data.flagsCollection.isButton, isTrue, reason: id);
          expect(data.flagsCollection.isImage, isFalse, reason: id);
          expect(data.hasAction(SemanticsAction.tap), isTrue, reason: id);
          await tester.tap(_id(id));
          await tester.pump();
          expect(_count(tester, slug), ++expected, reason: 'tap $id');
        }
        // The picture or icon is not an element of its own either.
        expect(_imageNodes(tester), isEmpty);
        handle.dispose();
      });

      testWidgets('$slug: Tab reaches each button; Enter and Space activate', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        var expected = 0;
        for (final id in buttons.keys) {
          // Tab until this button has focus. The Back button comes first.
          var reached = false;
          for (var i = 0; i < 6 && !reached; i++) {
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.pump();
            reached = _focused(tester, _id(id));
          }
          expect(reached, isTrue, reason: 'Tab did not reach $id');
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pump();
          expect(_count(tester, slug), ++expected, reason: 'Enter on $id');
          await tester.sendKeyEvent(LogicalKeyboardKey.space);
          await tester.pump();
          expect(_count(tester, slug), ++expected, reason: 'Space on $id');
        }
        handle.dispose();
      });
    }
  });

  testWidgets('good-image-regions: the focused region shows a focus ring', (
    tester,
  ) async {
    await _open(tester, 'good-image-regions');
    const west = 's04-good-image-regions-west';
    const east = 's04-good-image-regions-east';
    Finder ring(String id) => find.byKey(ValueKey<String>('$id-focus'));
    expect(ring(west), findsNothing);
    expect(ring(east), findsNothing);
    final handle = tester.ensureSemantics();
    for (final (focused, other) in [(west, east), (east, west)]) {
      var reached = false;
      for (var i = 0; i < 6 && !reached; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        reached = _focused(tester, _id(focused));
      }
      expect(reached, isTrue, reason: 'Tab did not reach $focused');
      expect(ring(focused), findsOneWidget);
      expect(ring(other), findsNothing);
      // The ring is drawn above the picture: it comes later in the Stack.
      final stack = find.ancestor(
        of: ring(focused),
        matching: find.byType(Stack),
      );
      final picture = find.descendant(
        of: stack.first,
        matching: find.byType(Image),
      );
      expect(picture, findsOneWidget);
      expect(tester.getRect(ring(focused)).size, const Size(120, 80));
    }
    handle.dispose();
  });

  group('bad examples have their defect', () {
    testWidgets('bad-no-name: a button with no name', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-no-name');
      final data = _data(tester, _id('s04-bad-no-name-guide'));
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(data.label, isEmpty);
      expect(data.tooltip, isEmpty);
      // The picture's image flag is all the button has for content.
      expect(data.flagsCollection.isImage, isTrue);
      await expectLater(
        tester,
        doesNotMeetGuideline(labeledTapTargetGuideline),
      );
      handle.dispose();
    });

    testWidgets('bad-label-on-image: the button has no name; the name is on '
        'a separate image', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-label-on-image');
      final button = tester.getSemantics(_id('s04-bad-label-on-image-guide'));
      final buttonData = button.getSemanticsData();
      expect(buttonData.flagsCollection.isButton, isTrue);
      expect(buttonData.hasAction(SemanticsAction.tap), isTrue);
      expect(buttonData.label, isEmpty);
      expect(buttonData.tooltip, isEmpty);
      expect(buttonData.flagsCollection.isImage, isFalse);

      final images = _imageNodes(tester);
      expect(images, hasLength(1));
      expect(images.single.label, 'Open trail guide');
      expect(images.single.flagsCollection.isButton, isFalse);
      expect(images.single.hasAction(SemanticsAction.tap), isFalse);
      final image = tester.getSemantics(find.byType(Image));
      expect(image.id, isNot(button.id));
      expect(image.parent!.id, button.id);
      handle.dispose();
    });

    testWidgets('bad-tap-gesture: an image, not a button, and no keyboard '
        'access', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-tap-gesture');
      final images = _imageNodes(tester);
      expect(images, hasLength(1));
      expect(images.single.label, 'Open trail guide');
      expect(images.single.flagsCollection.isButton, isFalse);
      // The tap action is on a node of its own with no role and no name.
      SemanticsNode image() => tester.getSemantics(find.byType(Image));
      SemanticsData tappable() => image().parent!.getSemanticsData();
      expect(tappable().hasAction(SemanticsAction.tap), isTrue);
      expect(tappable().flagsCollection.isButton, isFalse);
      expect(tappable().label, isEmpty);
      // Tab through everything on the screen. Focus never lands on the
      // picture or on the node that takes the tap, so no key can operate
      // it. Both are read again after every Tab.
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(
          image().getSemanticsData().flagsCollection.isFocused,
          Tristate.none,
          reason: 'image after Tab ${i + 1}',
        );
        expect(
          tappable().flagsCollection.isFocused,
          Tristate.none,
          reason: 'tappable node after Tab ${i + 1}',
        );
      }
      // The example builds no Focus widget of its own either.
      expect(
        find.descendant(
          of: _id('s04-bad-tap-gesture-guide'),
          matching: find.byType(Focus),
        ),
        findsNothing,
      );
      // It still works by touch, which is what hides the defect.
      await tester.tap(_id('s04-bad-tap-gesture-guide'));
      await tester.pump();
      expect(_count(tester, 'bad-tap-gesture'), 1);
      handle.dispose();
    });

    testWidgets('bad-describes-picture: the name describes the icon', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-describes-picture');
      final data = _data(tester, _id('s04-bad-describes-picture-search'));
      expect(data.flagsCollection.isButton, isTrue);
      expect(_name(data), 'Magnifying glass');
      handle.dispose();
    });

    testWidgets('bad-image-not-excluded: the button is also an image', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-image-not-excluded');
      final data = _data(tester, _id('s04-bad-image-not-excluded-guide'));
      expect(data.label, 'Trail guide');
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isImage, isTrue);
      handle.dispose();
    });

    testWidgets('bad-redundant-label: the name has the icon\'s label and the '
        'text', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-redundant-label');
      final data = _data(tester, _id('s04-bad-redundant-label-print'));
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.label, 'Printer\nPrint');
      expect(find.text('Print'), findsOneWidget);
      handle.dispose();
    });
  });
}
