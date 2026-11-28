import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_a11y_techniques/app/screens.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/v12_accessibility_settings/v12_accessibility_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/examples.dart';

/// L1 for V12 Detecting accessibility settings
/// (docs/specs/V12-accessibility-settings.md, section 6). A setting changed
/// while an example is open is a test value set on the test's platform
/// dispatcher: its setter calls the dispatcher's change callback, as the
/// engine does when the platform reports a change, so MediaQuery and
/// WidgetsBindingObserver hear of it the way they do on a device. Which
/// system setting sets which flag on a device is not seen here: the engine
/// is not run. That is measured on the device layers and the web.
const _good = ['good-media-query', 'good-motion'];
const _lists = ['good-media-query', 'bad-read-once'];

/// Every flag off, so that no test depends on what the machine running the
/// tests reports.
const _none = FakeAccessibilityFeatures();

const _defaults = [
  'Accessible navigation: off',
  'Bold text: off',
  'High contrast: off',
  'Invert colours: off',
  'Disable animations: off',
  'Switch labels: off',
  'Dark mode: off',
  'Text scale: 100%',
];

/// Opens [slug] with every flag off, light, at 100% text.
Future<void> _openPlain(WidgetTester tester, String slug) => openExample(
  tester,
  v12AccessibilitySettings,
  slug,
  accessibilityFeatures: _none,
);

/// The labels of the named nodes after the "Example" heading, in traversal
/// order, each with its identifier: `v12-good-media-query-bold "Bold text:
/// off"`.
List<String> _lines(WidgetTester tester) {
  final out = <SemanticsData>[];
  void visit(SemanticsNode node) {
    if (node.isMergedIntoParent) return;
    out.add(node.getSemanticsData());
    for (final child in node.debugListChildrenInOrder(
      DebugSemanticsDumpOrder.traversalOrder,
    )) {
      visit(child);
    }
  }

  visit(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  final start = out.indexWhere((n) => n.label == 'Example');
  expect(start, isNonNegative, reason: 'the Example heading');
  return [
    for (final n in out.skip(start + 1))
      if (n.label.isNotEmpty) '${n.identifier} "${n.label}"',
  ];
}

/// What the line [key] of [slug] says now.
String _line(String slug, String key) => dataById('v12-$slug-$key').label;

/// The lines of a settings list, with their identifiers.
List<String> _expected(String slug, List<String> texts) {
  const keys = [
    'navigation',
    'bold',
    'contrast',
    'invert',
    'animations',
    'labels',
    'dark',
    'scale',
  ];
  return [
    for (var i = 0; i < keys.length; i++) 'v12-$slug-${keys[i]} "${texts[i]}"',
  ];
}

/// Each flag of a settings list on its own: the features with it on, the
/// line it changes, and what that line says then.
final _flags = <(String, FakeAccessibilityFeatures, String, String)>[
  (
    'accessibleNavigation',
    const FakeAccessibilityFeatures(accessibleNavigation: true),
    'navigation',
    'Accessible navigation: on',
  ),
  (
    'boldText',
    const FakeAccessibilityFeatures(boldText: true),
    'bold',
    'Bold text: on',
  ),
  (
    'highContrast',
    const FakeAccessibilityFeatures(highContrast: true),
    'contrast',
    'High contrast: on',
  ),
  (
    'invertColors',
    const FakeAccessibilityFeatures(invertColors: true),
    'invert',
    'Invert colours: on',
  ),
  (
    'disableAnimations',
    const FakeAccessibilityFeatures(disableAnimations: true),
    'animations',
    'Disable animations: on',
  ),
  (
    'onOffSwitchLabels',
    const FakeAccessibilityFeatures(onOffSwitchLabels: true),
    'labels',
    'Switch labels: on',
  ),
];

/// The scale the text of the line [key] of [slug] is drawn with.
double _drawnScale(WidgetTester tester, String slug, String key) =>
    tester
        .renderObject<RenderParagraph>(
          find.descendant(
            of: byId('v12-$slug-$key'),
            matching: find.byType(RichText),
          ),
        )
        .textScaler
        .scale(14) /
    14;

void main() {
  test('the technique has the examples named in the spec', () {
    expect(v12AccessibilitySettings.examples.map((e) => e.slug), [
      ..._good,
      'bad-read-once',
      'bad-animations-only',
    ]);
    expect(_good, [
      for (final e in v12AccessibilitySettings.examples)
        if (e.kind == ExampleKind.good) e.slug,
    ]);
    expect(
      v12AccessibilitySettings.examples.where((e) => e.isCustomSolution),
      isEmpty,
      reason: 'no good example is a custom solution',
    );
    expect(v12AccessibilitySettings.wcag, isEmpty, reason: 'an enabler');
  });

  group('good examples', () {
    for (final slug in _good) {
      for (final brightness in Brightness.values) {
        testWidgets('$slug meets the guidelines (${brightness.name})', (
          tester,
        ) async {
          final handle = tester.ensureSemantics();
          await openExample(
            tester,
            v12AccessibilitySettings,
            slug,
            brightness: brightness,
            accessibilityFeatures: _none,
          );
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          handle.dispose();
        });
      }
    }
  });

  // Every example, good and bad: at 200% text on a 320 by 640 screen no
  // layout overflows, and no text in the example is cut short, by a line
  // limit or by a box too small for its lines.
  for (final example in v12AccessibilitySettings.examples) {
    final slug = example.slug;
    testWidgets('$slug: at 200% text on a phone nothing overflows and no '
        'text is cut short', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await openExample(
        tester,
        v12AccessibilitySettings,
        slug,
        textScale: 2,
        accessibilityFeatures: _none,
      );
      expect(tester.takeException(), isNull);
      final widget = example.builder(
        tester.element(find.byType(ExampleScreen)),
      );
      final paragraphs = tester
          .renderObjectList<RenderParagraph>(
            find.descendant(
              of: find.byType(widget.runtimeType),
              matching: find.byType(RichText),
            ),
          )
          .toList();
      expect(paragraphs, isNotEmpty);
      for (final p in paragraphs) {
        final text = p.text.toPlainText();
        expect(p.didExceedMaxLines, isFalse, reason: '"$text" hit its limit');
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
        expect(
          p.localToGlobal(Offset(p.size.width, 0)).dx,
          lessThanOrEqualTo(320.5),
          reason: '"$text" runs past the screen',
        );
        painter.dispose();
      }
      // The text scale line says what the text is drawn at.
      if (_lists.contains(slug)) {
        expect(_drawnScale(tester, slug, 'scale'), 2);
      }
    });
  }

  group('what each example says when it opens', () {
    for (final slug in _lists) {
      testWidgets('$slug: one node per setting, in order, every one off', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _openPlain(tester, slug);
        expect(_lines(tester), _expected(slug, _defaults));
        handle.dispose();
      });

      // Each flag on when the screen opens: both lists read it, the bad
      // one included. Its defect is only that it never reads again.
      for (final (name, features, key, text) in _flags) {
        testWidgets('$slug: opened with $name on, says "$text"', (
          tester,
        ) async {
          final handle = tester.ensureSemantics();
          await openExample(
            tester,
            v12AccessibilitySettings,
            slug,
            accessibilityFeatures: features,
          );
          expect(_line(slug, key), text);
          handle.dispose();
        });
      }
      testWidgets('$slug: opened dark at 150% text, says so', (tester) async {
        final handle = tester.ensureSemantics();
        await openExample(
          tester,
          v12AccessibilitySettings,
          slug,
          brightness: Brightness.dark,
          textScale: 1.5,
          accessibilityFeatures: _none,
        );
        expect(_line(slug, 'dark'), 'Dark mode: on');
        expect(_line(slug, 'scale'), 'Text scale: 150%');
        handle.dispose();
      });
    }

    for (final slug in ['good-motion', 'bad-animations-only']) {
      testWidgets('$slug: one node, "Reduce motion: off"', (tester) async {
        final handle = tester.ensureSemantics();
        await _openPlain(tester, slug);
        expect(_lines(tester), ['v12-$slug-motion "Reduce motion: off"']);
        handle.dispose();
      });
    }
  });

  group('a setting changed while the example is open', () {
    for (final (name, features, key, text) in _flags) {
      testWidgets('good-media-query: $name turned on and off again, the '
          'line follows it and no other line changes', (tester) async {
        final handle = tester.ensureSemantics();
        await _openPlain(tester, 'good-media-query');
        tester.platformDispatcher.accessibilityFeaturesTestValue = features;
        await tester.pumpAndSettle();
        final on = [..._defaults];
        on[on.indexWhere((l) => l.startsWith(text.split(':').first))] = text;
        expect(_lines(tester), _expected('good-media-query', on));
        tester.platformDispatcher.accessibilityFeaturesTestValue = _none;
        await tester.pumpAndSettle();
        expect(_lines(tester), _expected('good-media-query', _defaults));
        handle.dispose();
      });

      testWidgets('bad-read-once: $name turned on, the line still says off, '
          'though the framework has the change', (tester) async {
        final handle = tester.ensureSemantics();
        await _openPlain(tester, 'bad-read-once');
        tester.platformDispatcher.accessibilityFeaturesTestValue = features;
        await tester.pumpAndSettle();
        // The witness: the screen's MediaQuery has the new value.
        final mq = MediaQuery.of(
          tester.element(byId('v12-bad-read-once-$key')),
        );
        final now = switch (key) {
          'navigation' => mq.accessibleNavigation,
          'bold' => mq.boldText,
          'contrast' => mq.highContrast,
          'invert' => mq.invertColors,
          'animations' => mq.disableAnimations,
          'labels' => mq.onOffSwitchLabels,
          _ => throw StateError(key),
        };
        expect(now, isTrue, reason: 'the change reached the framework');
        expect(_lines(tester), _expected('bad-read-once', _defaults));
        handle.dispose();
      });
    }

    testWidgets('good-media-query: dark mode and 150% text turned on, the '
        'lines follow them', (tester) async {
      final handle = tester.ensureSemantics();
      await _openPlain(tester, 'good-media-query');
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      await tester.pumpAndSettle();
      expect(_line('good-media-query', 'dark'), 'Dark mode: on');
      expect(_line('good-media-query', 'scale'), 'Text scale: 150%');
      handle.dispose();
    });

    testWidgets('bad-read-once: dark mode and 150% text turned on, the lines '
        'still say off and 100%, though the screen is dark and its text '
        'scaled', (tester) async {
      final handle = tester.ensureSemantics();
      await _openPlain(tester, 'bad-read-once');
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      await tester.pumpAndSettle();
      // The witnesses: the app's theme went dark, and the lines' own text
      // is drawn at 150%.
      expect(
        Theme.of(tester.element(byId('v12-bad-read-once-dark'))).brightness,
        Brightness.dark,
      );
      expect(_drawnScale(tester, 'bad-read-once', 'scale'), 1.5);
      expect(_line('bad-read-once', 'dark'), 'Dark mode: off');
      expect(_line('bad-read-once', 'scale'), 'Text scale: 100%');
      handle.dispose();
    });

    // good-motion reads both flags; bad-animations-only reads
    // disableAnimations alone, so reduceMotion, the flag iOS's Reduce
    // Motion sets, leaves it off. The disableAnimations row is the
    // positive control for the bad example: it does read its one flag.
    final motion = <(String, FakeAccessibilityFeatures, String, String)>[
      (
        'reduceMotion',
        const FakeAccessibilityFeatures(reduceMotion: true),
        'on',
        'off',
      ),
      (
        'disableAnimations',
        const FakeAccessibilityFeatures(disableAnimations: true),
        'on',
        'on',
      ),
      (
        'both',
        const FakeAccessibilityFeatures(
          reduceMotion: true,
          disableAnimations: true,
        ),
        'on',
        'on',
      ),
    ];
    for (final (name, features, good, bad) in motion) {
      for (final (slug, want) in [
        ('good-motion', good),
        ('bad-animations-only', bad),
      ]) {
        testWidgets('$slug: $name turned on says "Reduce motion: $want", '
            'and off again "off"', (tester) async {
          final handle = tester.ensureSemantics();
          await _openPlain(tester, slug);
          tester.platformDispatcher.accessibilityFeaturesTestValue = features;
          await tester.pumpAndSettle();
          expect(_line(slug, 'motion'), 'Reduce motion: $want');
          tester.platformDispatcher.accessibilityFeaturesTestValue = _none;
          await tester.pumpAndSettle();
          expect(_line(slug, 'motion'), 'Reduce motion: off');
          handle.dispose();
        });
      }
    }
  });
}
