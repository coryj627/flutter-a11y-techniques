import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/app/app.dart';
import 'package:flutter_a11y_techniques/catalog/registry.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/i12_announcements/i12_announcements.dart';
import 'package:flutter_test/flutter_test.dart';

/// L1 for I12 Announcements and live regions
/// (docs/specs/I12-announcements.md).
Future<void> _open(
  WidgetTester tester,
  String slug, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
  bool supportsAnnounce = true,
}) async {
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(supportsAnnounce: supportsAnnounce);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  await tester.pumpWidget(
    A11yTechniquesApp(
      registry: TechniqueRegistry([i12Announcements]),
      platform: AppPlatform.android,
      initialRoute: '/t/I12/$slug',
    ),
  );
  await tester.pumpAndSettle();
}

Finder _action(String slug) => find.byKey(ValueKey<String>('i12-$slug-action'));

/// Semantics of the node carrying the example's status identifier.
SemanticsData _status(WidgetTester tester, String slug) {
  SemanticsData? found;
  void visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    if (data.identifier == 'i12-$slug-status') found = data;
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(tester.getSemantics(find.byType(Scaffold)));
  return found ?? (throw StateError('no status node for $slug'));
}

/// Records announcements sent from code while [body] runs.
Future<List<String>> _announcements(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  final sent = <String>[];
  tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
    SystemChannels.accessibility,
    (message) async {
      final map = (message! as Map).cast<String, Object?>();
      if (map['type'] == 'announce') {
        sent.add(((map['data']! as Map)['message']! as String));
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger
        .setMockDecodedMessageHandler<Object?>(
          SystemChannels.accessibility,
          null,
        ),
  );
  await body();
  return sent;
}

void main() {
  final goodSlugs = [
    for (final e in i12Announcements.examples)
      if (e.kind == ExampleKind.good) e.slug,
  ];

  test('the technique has the examples named in the spec', () {
    expect(i12Announcements.examples.map((e) => e.slug), [
      'good-live-region',
      'good-announce',
      'good-snackbar',
      'bad-silent-update',
      'bad-chatty-live-region',
      'bad-status-role-only',
      'bad-alert-role-only',
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
          await tester.tap(_action(slug));
          await tester.pumpAndSettle();
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
        await tester.tap(_action(slug));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('good-live-region: the message is a live region and changes '
        'without moving focus', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-live-region');
      expect(_status(tester, 'good-live-region').label, 'Cart is empty');
      expect(
        _status(tester, 'good-live-region').flagsCollection.isLiveRegion,
        isTrue,
      );
      final sent = await _announcements(tester, () async {
        await tester.tap(_action('good-live-region'));
        await tester.pumpAndSettle();
      });
      expect(_status(tester, 'good-live-region').label, '1 item in cart');
      // The live region does the announcing; nothing is sent from code too.
      expect(sent, isEmpty);
      await tester.tap(_action('good-live-region'));
      await tester.pumpAndSettle();
      expect(_status(tester, 'good-live-region').label, '2 items in cart');
      handle.dispose();
    });

    testWidgets('good-announce: announces from code where that is '
        'supported, and is not also a live region', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-announce');
      final sent = await _announcements(tester, () async {
        await tester.tap(_action('good-announce'));
        await tester.pumpAndSettle();
      });
      expect(sent, ['Link copied']);
      expect(find.text('Link copied'), findsOneWidget);
      // Every press is announced, not only the first.
      final again = await _announcements(tester, () async {
        await tester.tap(_action('good-announce'));
        await tester.pumpAndSettle();
      });
      expect(again, ['Link copied']);
      expect(
        _status(tester, 'good-announce').flagsCollection.isLiveRegion,
        isFalse,
      );
      handle.dispose();
    });

    testWidgets('good-announce: falls back to a live region where '
        'announcing from code is not supported', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-announce', supportsAnnounce: false);
      final sent = await _announcements(tester, () async {
        await tester.tap(_action('good-announce'));
        await tester.pumpAndSettle();
      });
      expect(sent, isEmpty);
      final status = _status(tester, 'good-announce');
      expect(status.label, 'Link copied');
      expect(status.flagsCollection.isLiveRegion, isTrue);

      // A second press must change the live region's text again, or nothing
      // would be announced: it is cleared for one frame, then set.
      await tester.tap(_action('good-announce'));
      await tester.pump();
      // For this frame the message is gone, from the screen and the tree.
      expect(find.text('Link copied'), findsNothing);
      await tester.pump();
      final again = _status(tester, 'good-announce');
      expect(again.label, 'Link copied');
      expect(again.flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });

    testWidgets('good-snackbar: the SnackBar is a live region with the '
        'message', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-snackbar');
      await tester.tap(_action('good-snackbar'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(SnackBar, 'Message archived'), findsOneWidget);
      var live = false;
      void visit(SemanticsNode node) {
        final data = node.getSemanticsData();
        if (data.flagsCollection.isLiveRegion &&
            data.label.contains('Message archived')) {
          live = true;
        }
        node.visitChildren((child) {
          visit(child);
          return true;
        });
      }

      visit(tester.getSemantics(find.byType(Scaffold)));
      expect(live, isTrue);
      handle.dispose();
    });
  });

  // VAL-3: each bad example is asserted to have its named defect.
  group('bad examples have their defect', () {
    testWidgets('bad-silent-update: the text changes but is not a live '
        'region and nothing is announced', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-silent-update');
      final sent = await _announcements(tester, () async {
        await tester.tap(_action('bad-silent-update'));
        await tester.pumpAndSettle();
      });
      final status = _status(tester, 'bad-silent-update');
      expect(status.label, '1 item in cart');
      expect(status.flagsCollection.isLiveRegion, isFalse);
      expect(status.role, SemanticsRole.none);
      expect(sent, isEmpty);
      handle.dispose();
    });

    testWidgets('bad-chatty-live-region: a live region with a new message '
        'every second', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-chatty-live-region');
      await tester.tap(_action('bad-chatty-live-region'));
      await tester.pump();
      final seen = <String>{};
      for (var second = 0; second < 5; second++) {
        final status = _status(tester, 'bad-chatty-live-region');
        expect(status.flagsCollection.isLiveRegion, isTrue);
        seen.add(status.label);
        await tester.pump(const Duration(seconds: 1));
      }
      // Five different messages in five seconds, each one announced.
      expect(seen, hasLength(5));
      // Stop the timer before the test ends.
      await tester.pumpWidget(const SizedBox());
      handle.dispose();
    });

    for (final (slug, role, message) in [
      ('bad-status-role-only', SemanticsRole.status, '1 item in cart'),
      (
        'bad-alert-role-only',
        SemanticsRole.alert,
        'Could not save. Attempt 1 failed.',
      ),
    ]) {
      testWidgets('$slug: has the role but is not a live region (Flutter '
          'limitation)', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        final sent = await _announcements(tester, () async {
          await tester.tap(_action(slug));
          await tester.pumpAndSettle();
        });
        final status = _status(tester, slug);
        expect(status.label, message);
        expect(status.role, role);
        // The role is all there is: no live region flag, which is what
        // Android and iOS act on, and nothing sent from code.
        expect(status.flagsCollection.isLiveRegion, isFalse);
        expect(sent, isEmpty);
        handle.dispose();
      });
    }
  });

  testWidgets('the technique screen lists every platform as applying', (
    tester,
  ) async {
    await tester.pumpWidget(
      A11yTechniquesApp(
        registry: TechniqueRegistry([i12Announcements]),
        platform: AppPlatform.ios,
        initialRoute: '/t/I12',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('iOS: Applies.'), findsOneWidget);
    expect(find.text('Android: Applies.'), findsOneWidget);
  });
}
