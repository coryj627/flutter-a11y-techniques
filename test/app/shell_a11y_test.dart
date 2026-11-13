import 'package:flutter/material.dart';
import 'package:flutter_a11y_techniques/app/app.dart';
import 'package:flutter_a11y_techniques/app/routes.dart';
import 'package:flutter_a11y_techniques/catalog/registry.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_catalog.dart';

/// Shell screens that must meet the accessibility guidelines (APP-3).
/// The bad-example screen is excluded: its content is defective on purpose.
const _routes = {
  'catalog': AppRoutes.catalog,
  'about': AppRoutes.about,
  'technique': '/t/C01',
  'good example': '/t/C01/good-text',
  'not found': '/nowhere',
};

Future<void> _pump(
  WidgetTester tester,
  String route, {
  TechniqueRegistry? registry,
  AppPlatform? platform = AppPlatform.android,
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) async {
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  await tester.pumpWidget(
    A11yTechniquesApp(
      registry: registry ?? fakeRegistry(),
      platform: platform,
      initialRoute: route,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _expectGuidelines(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}

void main() {
  for (final MapEntry(key: name, value: route) in _routes.entries) {
    for (final brightness in Brightness.values) {
      testWidgets('$name screen meets guidelines (${brightness.name})', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _pump(tester, route, brightness: brightness);
        await _expectGuidelines(tester);
        handle.dispose();
      });
    }

    testWidgets('$name screen does not overflow at 200% text on a phone', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _pump(tester, route, textScale: 2);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('empty catalog meets guidelines and says so', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, '/', registry: TechniqueRegistry(const []));
    expect(find.text('No techniques have been added yet.'), findsOneWidget);
    await _expectGuidelines(tester);
    handle.dispose();
  });

  testWidgets('section headings are exposed as headings', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, '/t/C01');
    for (final heading in ['Platforms', 'Good examples', 'Bad examples']) {
      expect(
        tester.getSemantics(find.text(heading)),
        isSemantics(isHeader: true),
        reason: heading,
      );
    }
    handle.dispose();
  });

  testWidgets('source links are exposed as links', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, '/t/C01');
    await tester.scrollUntilVisible(find.text('APG Button'), 200);
    expect(
      tester.getSemantics(find.text('APG Button')),
      isSemantics(isLink: true, hasTapAction: true, label: 'APG Button'),
    );
    handle.dispose();
  });

  testWidgets('catalog hides techniques not applicable on the platform', (
    tester,
  ) async {
    await _pump(tester, '/', platform: AppPlatform.android);
    expect(find.text('Fake button'), findsOneWidget);
    expect(find.text('Fake iOS only'), findsNothing);
  });

  testWidgets('navigates catalog to technique to example', (tester) async {
    await _pump(tester, '/');
    await tester.tap(find.text('Fake button'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Text button'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
  });

  // Titles of the screens in the history, top first, found by going back.
  Future<List<String>> history(WidgetTester tester) async {
    final titles = <String>[];
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    while (true) {
      titles.add(
        tester
            .widget<Text>(
              find.descendant(
                of: find.byType(AppBar).hitTestable(),
                matching: find.byType(Text),
              ),
            )
            .data!,
      );
      if (!navigator.canPop()) break;
      navigator.pop();
      await tester.pumpAndSettle();
    }
    // Remove the app so the next pump starts from its own initial route.
    await tester.pumpWidget(const SizedBox());
    return titles;
  }

  testWidgets('Back from a deep-linked example goes to its technique, then '
      'the catalog', (tester) async {
    await _pump(tester, '/t/C01/good-text');
    expect(await history(tester), [
      'Text button',
      'Fake button',
      'Flutter A11Y Techniques',
    ]);
  });

  testWidgets('Back from a deep-linked technique or the about screen goes to '
      'the catalog', (tester) async {
    await _pump(tester, '/t/C01');
    expect(await history(tester), ['Fake button', 'Flutter A11Y Techniques']);
    await _pump(tester, AppRoutes.about);
    expect(await history(tester), ['About', 'Flutter A11Y Techniques']);
  });

  testWidgets('an unknown address shows one not-found page over the catalog', (
    tester,
  ) async {
    for (final route in [
      '/nowhere',
      '/t/ZZZ/good-text',
      '/a/b/c/d',
      // Malformed encodings must not break startup.
      '/t/C01/%FF',
      '/t/%E0%A4%A/good-text',
      '/%',
      'http://[::1',
    ]) {
      await _pump(tester, route);
      expect(await history(tester), [
        'Page not found',
        'Flutter A11Y Techniques',
      ], reason: route);
    }
  });

  testWidgets('an unknown example of a real technique keeps the technique in '
      'the history', (tester) async {
    await _pump(tester, '/t/C01/no-such-example');
    expect(await history(tester), [
      'Page not found',
      'Fake button',
      'Flutter A11Y Techniques',
    ]);
  });

  testWidgets('bad example states its defect in text', (tester) async {
    await _pump(tester, '/t/C01/bad-thing');
    expect(find.text('Defect: It is broken.'), findsOneWidget);
    expect(find.textContaining('Bad example for Fake button'), findsOneWidget);
  });

  testWidgets('about screen carries the independence statement', (
    tester,
  ) async {
    await _pump(tester, AppRoutes.about);
    expect(
      find.textContaining('no material connection to CVS Health'),
      findsOneWidget,
    );
  });
}
