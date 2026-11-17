// What every technique's L1 widget tests share: opening an example through
// the real app, finding its widgets and semantics nodes, reading its count,
// and tabbing.
import 'dart:ui' show AccessibilityFeatures, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/app/app.dart';
import 'package:flutter_a11y_techniques/catalog/registry.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opens the example [slug] of [technique] in the real app, as on Android,
/// with [brightness] and [textScale]. [accessibilityFeatures], when given,
/// replaces the platform's accessibility features. With [decodeImages], a
/// real async gap comes before the app settles, for `Image.memory` to
/// decode.
Future<void> openExample(
  WidgetTester tester,
  Technique technique,
  String slug, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
  AccessibilityFeatures? accessibilityFeatures,
  bool decodeImages = false,
}) async {
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  if (accessibilityFeatures != null) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        accessibilityFeatures;
  }
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  await tester.pumpWidget(
    A11yTechniquesApp(
      registry: TechniqueRegistry([technique]),
      platform: AppPlatform.android,
      initialRoute: '/t/${technique.id}/$slug',
    ),
  );
  if (decodeImages) {
    // Image.memory decodes on a real async gap.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
  await tester.pumpAndSettle();
}

/// [openExample] for one technique.
typedef ExampleOpener = Future<void> Function(
  WidgetTester tester,
  String slug, {
  Brightness brightness,
  double textScale,
});

/// [openExample] bound to [technique]: `final _open = exampleOpener(c01Button);`.
ExampleOpener exampleOpener(Technique technique, {bool decodeImages = false}) =>
    (
      WidgetTester tester,
      String slug, {
      Brightness brightness = Brightness.light,
      double textScale = 1,
    }) => openExample(
      tester,
      technique,
      slug,
      brightness: brightness,
      textScale: textScale,
      decodeImages: decodeImages,
    );

/// The widget with the test identifier [id]: `TestId` keys its child with it.
Finder byId(String id) => find.byKey(ValueKey<String>(id));

/// The semantics node that stands for the element with [id]: the one whose
/// merged data has the identifier, and that is not merged into a parent.
FinderBase<SemanticsNode> nodeById(String id) => find.semantics.byPredicate(
  (node) =>
      !node.isMergedIntoParent && node.getSemanticsData().identifier == id,
);

/// What the node with [id] exposes now. Read again after every change.
SemanticsData dataById(String id) =>
    nodeById(id).evaluate().single.getSemanticsData();

/// What the semantics node of the widget [finder] finds exposes.
SemanticsData dataOf(WidgetTester tester, Finder finder) =>
    tester.getSemantics(finder).getSemanticsData();

/// The number at the end of the count with the identifier [id]: 2 for
/// "Activations: 2".
int countOf(WidgetTester tester, String id) {
  final text = tester.widget<Text>(
    find.descendant(of: byId(id), matching: find.byType(Text)),
  );
  return int.parse(text.data!.split(': ').last);
}

/// Tabs until [id] has focus, at most eight times. The Back button comes
/// first.
Future<void> tabTo(WidgetTester tester, String id) async {
  var reached = false;
  for (var i = 0; i < 8 && !reached; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    reached = dataById(id).flagsCollection.isFocused == Tristate.isTrue;
  }
  expect(reached, isTrue, reason: 'Tab did not reach $id');
}

/// Every semantics node on the screen, depth first, as the tree orders
/// children. A node merged into its parent is left out, unless
/// [includeMerged].
List<SemanticsData> semanticsNodes(
  WidgetTester tester, {
  bool includeMerged = false,
}) {
  final found = <SemanticsData>[];
  void visit(SemanticsNode node) {
    if (includeMerged || !node.isMergedIntoParent) {
      found.add(node.getSemanticsData());
    }
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
