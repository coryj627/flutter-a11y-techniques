import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/app/screens.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/c03_stand_alone_link/c03_stand_alone_link.dart';
import 'package:flutter_a11y_techniques/techniques/c03_stand_alone_link/examples.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/examples.dart';

/// L1 for C03 Stand-alone link (docs/specs/C03-stand-alone-link.md,
/// section 6). These tests run as Android: `kIsWeb` is false, so what the
/// examples do only on the web (the browser follows the link, `BrowserKeys`
/// hands it the keys) is tested in web_tests/c03_stand_alone_link.spec.js.
final _open = exampleOpener(c03StandAloneLink, decodeImages: true);

/// The link of each good example.
const _good = {
  'good-material': 'c03-good-material-link',
  'good-cupertino': 'c03-good-cupertino-link',
  'good-custom': 'c03-good-custom-link',
  'good-image-link': 'c03-good-image-link-link',
};

/// Whether the screen on top is the technique's own page, the links'
/// destination, and the example is no longer on screen.
void _expectOnDestination(WidgetTester tester, String slug) {
  expect(find.byType(TechniqueScreen), findsOneWidget, reason: slug);
  expect(find.byType(ExampleScreen), findsNothing, reason: slug);
}

void _expectOnExample(WidgetTester tester, String slug) {
  expect(find.byType(ExampleScreen), findsOneWidget, reason: slug);
  expect(find.byType(TechniqueScreen), findsNothing, reason: slug);
}

/// Goes back once, with the app's Back button, and checks that the example
/// is on screen again: the link opened one page, not two.
Future<void> _backToExample(WidgetTester tester, String slug) async {
  await tester.tap(find.byTooltip('Back'));
  await tester.pumpAndSettle();
  _expectOnExample(tester, slug);
}

bool _focused(String id) =>
    dataById(id).flagsCollection.isFocused == Tristate.isTrue;

/// Every node on the screen that is an image.
List<SemanticsData> _images(WidgetTester tester) => [
  for (final n in semanticsNodes(tester, includeMerged: true))
    if (n.flagsCollection.isImage) n,
];

void main() {
  test('the technique has the examples named in the spec', () {
    expect(c03StandAloneLink.examples.map((e) => e.slug), [
      ..._good.keys,
      'bad-vague-text',
      'bad-tap-handler',
      'bad-no-address',
      'bad-image-no-name',
      'bad-label-on-image',
      'bad-cupertino-button',
      'bad-app-also-follows',
    ]);
    expect(_good.keys, [
      for (final e in c03StandAloneLink.examples)
        if (e.kind == ExampleKind.good) e.slug,
    ]);
  });

  test('the links go to the technique page', () {
    expect(linkRoute, '/t/C03');
    expect(linkAddress.toString(), '#/t/C03');
  });

  group('good examples', () {
    for (final MapEntry(key: slug, value: id) in _good.entries) {
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

      testWidgets('$slug: a link with its address and name, and nothing else', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        final data = dataById(id);
        expect(data.flagsCollection.isLink, isTrue);
        expect(data.linkUrl, linkAddress);
        expect(data.label, linkText);
        expect(data.flagsCollection.isButton, isFalse);
        expect(data.flagsCollection.isImage, isFalse);
        expect(data.hasAction(SemanticsAction.tap), isTrue);
        // The tap hint travels as a custom action that overrides tap.
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
        );
        expect(_images(tester), isEmpty);
        handle.dispose();
      });

      testWidgets('$slug: a tap and the tap action each follow it, once', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await tester.tap(byId(id));
        await tester.pumpAndSettle();
        _expectOnDestination(tester, slug);
        await _backToExample(tester, slug);
        // The action a screen reader performs.
        tester.semantics.tap(nodeById(id));
        await tester.pumpAndSettle();
        _expectOnDestination(tester, slug);
        await _backToExample(tester, slug);
        handle.dispose();
      });

      for (final (key, name) in [
        (LogicalKeyboardKey.enter, 'Enter'),
        (LogicalKeyboardKey.space, 'Space'),
      ]) {
        testWidgets('$slug: Tab reaches it and $name follows it', (
          tester,
        ) async {
          final handle = tester.ensureSemantics();
          await _open(tester, slug);
          await tabTo(tester, id);
          await tester.sendKeyEvent(key);
          await tester.pumpAndSettle();
          _expectOnDestination(tester, slug);
          await _backToExample(tester, slug);
          handle.dispose();
        });
      }
    }
  });

  group('bad examples have their defect', () {
    testWidgets('bad-vague-text: a link named "Read more"', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-vague-text');
      final data = dataById('c03-bad-vague-text-link');
      expect(data.flagsCollection.isLink, isTrue);
      expect(data.linkUrl, linkAddress);
      expect(data.label, 'Read more');
      handle.dispose();
    });

    testWidgets('bad-tap-handler: no link role, and Tab never reaches it', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-tap-handler');
      const id = 'c03-bad-tap-handler-link';
      final data = dataById(id);
      expect(data.label, linkText);
      expect(data.flagsCollection.isLink, isFalse);
      expect(data.flagsCollection.isButton, isFalse);
      expect(data.linkUrl, isNull);
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      // Tab through everything on the screen: focus never lands on it, and
      // the example builds no Focus widget of its own.
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(_focused(id), isFalse, reason: 'after Tab ${i + 1}');
        expect(
          dataById(id).flagsCollection.isFocused,
          Tristate.none,
          reason: 'not focusable, after Tab ${i + 1}',
        );
      }
      expect(
        find.descendant(of: byId(id), matching: find.byType(Focus)),
        findsNothing,
      );
      // A tap still follows it, which is what hides the defect.
      await tester.tap(byId(id));
      await tester.pumpAndSettle();
      _expectOnDestination(tester, 'bad-tap-handler');
      handle.dispose();
    });

    testWidgets('bad-no-address: a link with no address', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-no-address');
      final data = dataById('c03-bad-no-address-link');
      expect(data.flagsCollection.isLink, isTrue);
      expect(data.linkUrl, isNull);
      expect(data.label, linkText);
      // What this means on Android (a button) and on the web (an <a> with no
      // href) is in the engine; the device and web tests assert it. It
      // still works here.
      await tester.tap(byId('c03-bad-no-address-link'));
      await tester.pumpAndSettle();
      _expectOnDestination(tester, 'bad-no-address');
      handle.dispose();
    });

    testWidgets('bad-image-no-name: a picture link with no name', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-image-no-name');
      final data = dataById('c03-bad-image-no-name-link');
      expect(data.flagsCollection.isLink, isTrue);
      expect(data.linkUrl, linkAddress);
      expect(data.label, isEmpty);
      expect(data.tooltip, isEmpty);
      // The picture's image flag is merged into the link: all it has.
      expect(data.flagsCollection.isImage, isTrue);
      await expectLater(
        tester,
        doesNotMeetGuideline(labeledTapTargetGuideline),
      );
      handle.dispose();
    });

    testWidgets('bad-label-on-image: the link has no name; the name is on '
        'a separate image', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-label-on-image');
      final images = _images(tester);
      expect(images, hasLength(1));
      expect(images.single.label, linkText);
      expect(images.single.flagsCollection.isLink, isFalse);
      final image = tester.getSemantics(find.byType(Image));
      final link = image.parent!;
      final data = link.getSemanticsData();
      expect(data.flagsCollection.isLink, isTrue);
      expect(data.linkUrl, linkAddress);
      expect(data.label, isEmpty);
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(image.id, isNot(link.id));
      handle.dispose();
    });

    testWidgets('bad-cupertino-button: a link and a button at once', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-cupertino-button');
      final data = dataById('c03-bad-cupertino-button-link');
      expect(data.flagsCollection.isLink, isTrue);
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.linkUrl, linkAddress);
      expect(data.label, linkText);
      handle.dispose();
    });

    testWidgets('bad-app-also-follows: off the web a tap follows it once', (
      tester,
    ) async {
      // The defect is on the web only, where the browser follows the href
      // as well (web_tests/c03_stand_alone_link.spec.js). Here only the app
      // follows it, so one Back returns to the example.
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-app-also-follows');
      final data = dataById('c03-bad-app-also-follows-link');
      expect(data.flagsCollection.isLink, isTrue);
      expect(data.linkUrl, linkAddress);
      expect(data.label, linkText);
      await tester.tap(byId('c03-bad-app-also-follows-link'));
      await tester.pumpAndSettle();
      _expectOnDestination(tester, 'bad-app-also-follows');
      await _backToExample(tester, 'bad-app-also-follows');
      handle.dispose();
    });
  });
}
