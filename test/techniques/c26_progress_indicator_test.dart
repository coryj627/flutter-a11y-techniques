import 'dart:math' as math;
import 'dart:ui' show Tristate;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/app/screens.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/c26_progress_indicator/c26_progress_indicator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/examples.dart';

/// L1 for C26 Progress indicator (docs/specs/C26-progress-indicator.md,
/// section 6). The tests run as Android, except where they say iOS or
/// macOS. Each example's task runs four steps of one second once its
/// button is pressed; time is pumped a step at a time, never settled while
/// a spinner turns, as a spinner never settles.
final _openExample = exampleOpener(c26ProgressIndicator);

/// Opens [slug] from nothing: whatever was shown before is taken down
/// first, so that a test can open a second example, or the same one again
/// at rest, in one launch.
Future<void> _open(
  WidgetTester tester,
  String slug, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) async {
  await tester.pumpWidget(const SizedBox());
  await _openExample(
    tester,
    slug,
    brightness: brightness,
    textScale: textScale,
  );
}

const _good = ['good-linear', 'good-circular', 'good-cupertino'];
const _bars = ['good-linear', 'bad-no-label', 'bad-silent-end'];

/// The indicator of each example: a bar, or a spinner shown while running.
const _indicator = {
  'good-linear': 'c26-good-linear-bar',
  'good-circular': 'c26-good-circular-spinner',
  'good-cupertino': 'c26-good-cupertino-spinner',
  'bad-no-label': 'c26-bad-no-label-bar',
  'bad-silent-end': 'c26-bad-silent-end-bar',
  'bad-adaptive': 'c26-bad-adaptive-spinner',
  'bad-cupertino-bar': 'c26-bad-cupertino-bar-bar',
};

String _start(String slug) => 'c26-$slug-start';
String _status(String slug) => 'c26-$slug-status';

/// What each status line says before, at the start and each step, and at
/// the end.
List<String> _statusLines(String slug) =>
    _bars.contains(slug) || slug == 'bad-cupertino-bar'
    ? [
        'Not started',
        'Upload started',
        'Upload started',
        'Half uploaded',
        'Half uploaded',
        'Upload complete',
      ]
    : [
        'Inbox not loaded',
        'Loading started',
        'Loading started',
        'Loading started',
        'Loading started',
        'Inbox loaded',
      ];

/// Presses the example's button with a tap, and pumps one frame.
Future<void> _press(WidgetTester tester, String slug) async {
  await tester.tap(byId(_start(slug)));
  await tester.pump();
}

/// Pumps one step of the task: a second, in frames of 100 ms, so that a
/// spinner's animation runs as it does in an app.
Future<void> _step(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

SemanticsData? _maybe(String id) {
  final found = nodeById(id).evaluate();
  return found.isEmpty ? null : found.single.getSemanticsData();
}

/// The semantics nodes, anywhere on the screen, whose label holds [text].
List<SemanticsData> _labelled(WidgetTester tester, String text) => [
  for (final n in semanticsNodes(tester))
    if (n.label.contains(text)) n,
];

double _luminance(Color c) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double _contrast(Color a, Color b) {
  final x = _luminance(a), y = _luminance(b);
  return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
}

/// The identifier of the node with keyboard focus, or its label.
String _focusedStop(WidgetTester tester) {
  for (final n in semanticsNodes(tester)) {
    if (n.flagsCollection.isFocused == Tristate.isTrue) {
      return n.identifier.isNotEmpty ? n.identifier : n.label;
    }
  }
  return '(none)';
}

void main() {
  test('the technique has the examples named in the spec', () {
    expect(c26ProgressIndicator.examples.map((e) => e.slug), [
      ..._good,
      'bad-no-label',
      'bad-silent-end',
      'bad-adaptive',
      'bad-cupertino-bar',
    ]);
    expect(_good, [
      for (final e in c26ProgressIndicator.examples)
        if (e.kind == ExampleKind.good) e.slug,
    ]);
    expect(
      c26ProgressIndicator.examples.where((e) => e.isCustomSolution),
      isEmpty,
    );
  });

  group('good examples', () {
    for (final slug in _good) {
      for (final brightness in Brightness.values) {
        testWidgets('$slug meets the guidelines at rest and while running '
            '(${brightness.name})', (tester) async {
          final handle = tester.ensureSemantics();
          await _open(tester, slug, brightness: brightness);
          Future<void> check() async {
            await expectLater(
              tester,
              meetsGuideline(androidTapTargetGuideline),
            );
            await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
            await expectLater(
              tester,
              meetsGuideline(labeledTapTargetGuideline),
            );
            await expectLater(tester, meetsGuideline(textContrastGuideline));
          }

          await check();
          await _press(tester, slug);
          await _step(tester);
          expect(_maybe(_indicator[slug]!), isNotNull, reason: 'running');
          await check();
          for (var i = 0; i < 4; i++) {
            await _step(tester);
          }
          await check();
          handle.dispose();
        });

        testWidgets('$slug: the button\'s focus outline is 3:1 or more on '
            'the page, and the text meets the contrast guideline with focus '
            'on it (${brightness.name})', (tester) async {
          final handle = tester.ensureSemantics();
          await _open(tester, slug, brightness: brightness);
          final button = tester.widget<OutlinedButton>(
            find.descendant(
              of: byId(_start(slug)),
              matching: find.byType(OutlinedButton),
            ),
          );
          final ring = button.style!.side!.resolve({WidgetState.focused})!;
          final page = Theme.of(tester.element(byId(_start(slug))))
              .colorScheme
              .surface;
          expect(ring.width, 2);
          expect(_contrast(ring.color, page), greaterThanOrEqualTo(3));
          await tabTo(tester, _start(slug));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          handle.dispose();
        });
      }

      testWidgets('$slug: the button starts the task by a tap, the tap action, '
          'Enter, and Space, each from rest', (tester) async {
        final handle = tester.ensureSemantics();
        Future<void> expectStarted(String how) async {
          await tester.pump();
          expect(
            dataById(_status(slug)).label,
            _statusLines(slug)[1],
            reason: '$how started the task',
          );
          for (var i = 0; i < 5; i++) {
            await _step(tester);
          }
          expect(dataById(_status(slug)).label, _statusLines(slug).last);
        }

        await _open(tester, slug);
        await tester.tap(byId(_start(slug)));
        await expectStarted('a tap');
        await _open(tester, slug);
        tester.semantics.tap(nodeById(_start(slug)));
        await expectStarted('the tap action');
        for (final key in [
          LogicalKeyboardKey.enter,
          LogicalKeyboardKey.space,
        ]) {
          await _open(tester, slug);
          await tabTo(tester, _start(slug));
          await tester.sendKeyEvent(key);
          await expectStarted(key.keyLabel);
        }
        handle.dispose();
      });

      testWidgets('$slug: Tab goes Back, then the button, then round; the '
          'indicator takes no focus, while running too', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await tabTo(tester, _start(slug));
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        await _step(tester);
        expect(_maybe(_indicator[slug]!), isNotNull);
        final stops = <String>[];
        for (var i = 0; i < 3; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          stops.add(_focusedStop(tester));
        }
        // The button had focus; the next Tabs go round the screen's two
        // stops, and never to the indicator.
        expect(stops, ['Back', _start(slug), 'Back']);
        // A node that can take focus has isFocused true or false.
        expect(
          _maybe(_indicator[slug]!)!.flagsCollection.isFocused,
          Tristate.none,
        );
        handle.dispose();
      });

      testWidgets('$slug: the status line is a live region, and says how the '
          'task is going and that it has ended, at each step', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        final lines = <String>[dataById(_status(slug)).label];
        expect(dataById(_status(slug)).flagsCollection.isLiveRegion, isTrue);
        await _press(tester, slug);
        lines.add(dataById(_status(slug)).label);
        for (var i = 0; i < 4; i++) {
          await _step(tester);
          lines.add(dataById(_status(slug)).label);
          expect(dataById(_status(slug)).flagsCollection.isLiveRegion, isTrue);
        }
        expect(lines, _statusLines(slug));
        handle.dispose();
      });

      testWidgets('$slug: with animations turned off, the indicator exposes '
          'the same as with them on', (tester) async {
        final handle = tester.ensureSemantics();
        Future<SemanticsData> running(bool disable) async {
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              FakeAccessibilityFeatures(disableAnimations: disable);
          await _open(tester, slug);
          await _press(tester, slug);
          await _step(tester);
          await _step(tester);
          return dataById(_indicator[slug]!);
        }

        final on = await running(false);
        final off = await running(true);
        expect(
          (off.role, off.label, off.value, off.minValue, off.maxValue),
          (on.role, on.label, on.value, on.minValue, on.maxValue),
        );
        handle.dispose();
      });
    }

    testWidgets('good-linear: the bar is a progress bar named by the words '
        'above it, once, with the percentage as its value at each step', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-linear');
      SemanticsData bar() => dataById('c26-good-linear-bar');
      expect(
        (bar().role, bar().label, bar().value, bar().minValue, bar().maxValue),
        (SemanticsRole.progressBar, 'Report upload', '0', '0', '100'),
      );
      expect(_labelled(tester, 'Report upload'), hasLength(1));
      await _press(tester, 'good-linear');
      final values = <String>[bar().value];
      for (var i = 0; i < 4; i++) {
        await _step(tester);
        values.add(bar().value);
      }
      expect(values, ['0', '25', '50', '75', '100']);
      expect(bar().role, SemanticsRole.progressBar);
      handle.dispose();
    });

    for (final slug in ['good-circular', 'good-cupertino']) {
      testWidgets(
        '$slug: the spinner is there only while loading, named, '
        'with no value; ${slug == 'good-circular' ? 'its role is a loading spinner' : 'it has no role (FL-255)'}',
        (tester) async {
          final handle = tester.ensureSemantics();
          await _open(tester, slug);
          final id = _indicator[slug]!;
          expect(_maybe(id), isNull, reason: 'no spinner before loading');
          await _press(tester, slug);
          await _step(tester);
          final spinner = dataById(id);
          expect(
            (
              spinner.role,
              spinner.label,
              spinner.value,
              spinner.minValue,
              spinner.maxValue,
            ),
            (
              slug == 'good-circular'
                  ? SemanticsRole.loadingSpinner
                  : SemanticsRole.none,
              'Loading inbox',
              '',
              null,
              null,
            ),
          );
          for (var i = 0; i < 4; i++) {
            await _step(tester);
          }
          expect(_maybe(id), isNull, reason: 'no spinner once loaded');
          expect(dataById(_status(slug)).label, 'Inbox loaded');
          handle.dispose();
        },
      );
    }

    // 1.4.11: the colours each indicator draws with, from the theme, read
    // as the SDK's defaults use them (source read: material/
    // progress_indicator.dart, cupertino/activity_indicator.dart). The
    // value is given in text as well, by the status line, so the bar's
    // track is not needed to understand it: the track on the page is
    // printed, not asserted.
    for (final brightness in Brightness.values) {
      testWidgets('the indicators\' colours (${brightness.name})', (
        tester,
      ) async {
        await _open(tester, 'good-linear', brightness: brightness);
        final s = Theme.of(tester.element(byId('c26-good-linear-bar')))
            .colorScheme;
        final bar = _contrast(s.primary, s.secondaryContainer);
        final barOnPage = _contrast(s.primary, s.surface);
        final track = _contrast(s.secondaryContainer, s.surface);
        final tick = brightness == Brightness.light
            ? const Color(0xFF3C3C44)
            : const Color(0xFFEBEBF5);
        final ticks = [
          for (final a in [47, 72, 97, 122, 147])
            _contrast(
              Color.alphaBlend(tick.withAlpha(a), s.surface),
              s.surface,
            ),
        ];
        debugPrint(
          'C26 colours ${brightness.name}: bar on track '
          '${bar.toStringAsFixed(2)}, bar on page ${barOnPage.toStringAsFixed(2)}, '
          'track on page ${track.toStringAsFixed(2)}, Cupertino ticks on page '
          '${ticks.map((t) => t.toStringAsFixed(2)).join(', ')}',
        );
        expect(bar, greaterThanOrEqualTo(3));
        expect(barOnPage, greaterThanOrEqualTo(3));
        // The darkest tick, the one that turns, meets 3:1; the others do
        // not (section 7 of the spec).
        expect(ticks.last, greaterThanOrEqualTo(3));
        expect(ticks.first, lessThan(3));
      });
    }
  });

  // Every example, good and bad: at 200% text on a 320 by 640 screen, at
  // rest and while running, no layout overflows, and no text in the example
  // is cut short, by a line limit or by a box too small for its lines.
  for (final example in c26ProgressIndicator.examples) {
    final slug = example.slug;
    testWidgets('$slug: at 200% text on a phone nothing overflows and no '
        'text is cut short, at rest and while running', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _open(tester, slug, textScale: 2);
      void check() {
        expect(tester.takeException(), isNull);
        final widget = example.builder(
          tester.element(find.byType(ExampleScreen)),
        );
        final paragraphs = tester.renderObjectList<RenderParagraph>(
          find.descendant(
            of: find.byType(widget.runtimeType),
            matching: find.byType(RichText),
          ),
        );
        expect(paragraphs, isNotEmpty);
        for (final p in paragraphs) {
          final text = p.text.toPlainText();
          expect(
            p.didExceedMaxLines,
            isFalse,
            reason: '"$text" hit its line limit',
          );
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
          painter.dispose();
          final right = p.localToGlobal(Offset(p.size.width, 0)).dx;
          expect(
            right,
            lessThanOrEqualTo(320.5),
            reason: '"$text" runs off the screen',
          );
        }
      }

      check();
      await _press(tester, slug);
      await _step(tester);
      check();
      for (var i = 0; i < 4; i++) {
        await _step(tester);
      }
      check();
    });
  }

  group('bad examples have their defect', () {
    testWidgets('bad-no-label: the bar has no name; its words are a text '
        'node of their own; good-linear\'s bar has the name', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-no-label');
      final bar = dataById('c26-bad-no-label-bar');
      expect(
        (bar.role, bar.label, bar.value, bar.minValue, bar.maxValue),
        (SemanticsRole.progressBar, '', '0', '0', '100'),
      );
      final words = _labelled(tester, 'Report upload');
      expect(words, hasLength(1));
      expect(words.single.role, SemanticsRole.none);
      expect(words.single.identifier, isEmpty);
      await _open(tester, 'good-linear');
      expect(dataById('c26-good-linear-bar').label, 'Report upload');
      handle.dispose();
    });

    testWidgets('bad-silent-end: the status line says the upload is '
        'complete but is no live region, and the bar is none either; '
        'good-linear\'s line is one', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-silent-end');
      await _press(tester, 'bad-silent-end');
      for (var i = 0; i < 4; i++) {
        await _step(tester);
      }
      final line = dataById('c26-bad-silent-end-status');
      expect(line.label, 'Upload complete');
      expect(line.flagsCollection.isLiveRegion, isFalse);
      expect(
        dataById('c26-bad-silent-end-bar').flagsCollection.isLiveRegion,
        isFalse,
      );
      expect(
        semanticsNodes(tester).where((n) => n.flagsCollection.isLiveRegion),
        isEmpty,
      );
      await _open(tester, 'good-linear');
      expect(
        dataById('c26-good-linear-status').flagsCollection.isLiveRegion,
        isTrue,
      );
      handle.dispose();
    });

    for (final platform in [TargetPlatform.iOS, TargetPlatform.macOS]) {
      testWidgets('bad-adaptive as ${platform.name}: the spinner exposes '
          'nothing, while a CircularProgressIndicator in the same launch is '
          'named (FL-257)', (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        final handle = tester.ensureSemantics();
        await _open(tester, 'bad-adaptive');
        await _press(tester, 'bad-adaptive');
        await _step(tester);
        expect(
          find.descendant(
            of: byId('c26-bad-adaptive-spinner'),
            matching: find.byType(CupertinoActivityIndicator),
          ),
          findsOneWidget,
        );
        final spinner = dataById('c26-bad-adaptive-spinner');
        expect(
          (spinner.role, spinner.label, spinner.value),
          (SemanticsRole.none, '', ''),
        );
        expect(_labelled(tester, 'Loading inbox'), isEmpty);
        expect(dataById('c26-bad-adaptive-status').label, 'Loading started');
        // Positive control, same platform: good-circular's spinner.
        await _open(tester, 'good-circular');
        await _press(tester, 'good-circular');
        await _step(tester);
        expect(dataById('c26-good-circular-spinner').label, 'Loading inbox');
        await tester.pumpWidget(const SizedBox());
        handle.dispose();
        debugDefaultTargetPlatformOverride = null;
      });
    }

    testWidgets('bad-adaptive as Android: Material\'s spinner, named', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-adaptive');
      await _press(tester, 'bad-adaptive');
      await _step(tester);
      final spinner = dataById('c26-bad-adaptive-spinner');
      expect(
        (spinner.role, spinner.label),
        (SemanticsRole.loadingSpinner, 'Loading inbox'),
      );
      handle.dispose();
    });

    testWidgets('bad-cupertino-bar: the bar exposes no role, name, or value, '
        'at rest and while running', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-cupertino-bar');
      void expectNothing() {
        final bar = dataById('c26-bad-cupertino-bar-bar');
        expect(
          (bar.role, bar.label, bar.value, bar.minValue, bar.maxValue),
          (SemanticsRole.none, '', '', null, null),
        );
      }

      expectNothing();
      await _press(tester, 'bad-cupertino-bar');
      await _step(tester);
      await _step(tester);
      expect(dataById('c26-bad-cupertino-bar-status').label, 'Half uploaded');
      expectNothing();
      handle.dispose();
    });
  });
}
