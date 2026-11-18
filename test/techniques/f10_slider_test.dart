import 'dart:ui' show Tristate;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/f10_slider/f10_slider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/examples.dart';

/// L1 for F10 Slider (docs/specs/F10-slider.md).
final _open = exampleOpener(f10Slider);

int _count(WidgetTester tester, String slug) =>
    countOf(tester, 'f10-$slug-count');

const _good = [
  'good-material',
  'good-cupertino',
  'good-custom',
  'good-value-text',
];

/// The slider's identifier in each example.
String _slider(String slug) =>
    slug.endsWith('-value-text') || slug.endsWith('-percent-value')
    ? 'f10-$slug-rating'
    : 'f10-$slug-volume';

/// Every example's slider: its name, its value at the start, and the
/// values one step up and one step down.
const _start = {
  'good-material': ('Volume', '40%', '50%', '30%'),
  'good-cupertino': ('Volume', '40%', '50%', '30%'),
  'good-custom': ('Volume', '40%', '50%', '30%'),
  'good-value-text': ('Rating', '4 out of 10', '5 out of 10', '3 out of 10'),
  'bad-unlabelled': ('', '40%', '50%', '30%'),
  'bad-indicator-label': ('Volume\n4', '40%', '50%', '30%'),
  'bad-percent-value': ('Rating', '40%', '50%', '30%'),
  'bad-no-keyboard': ('Volume', '40%', '50%', '30%'),
  'bad-drag-only': ('Volume', '40%', '50%', '30%'),
};

/// The examples whose slider the keyboard can reach and move.
const _withKeyboard = [
  'good-material',
  'good-cupertino',
  'good-custom',
  'good-value-text',
  'bad-unlabelled',
  'bad-indicator-label',
  'bad-percent-value',
  'bad-drag-only',
];

/// The values of each example's slider at its first and its last step.
const _ends = {
  'good-value-text': ('0 out of 10', '10 out of 10'),
  'bad-indicator-label': ('0%', '100%'),
};

SemanticsData _data(String slug) => dataById(_slider(slug));

/// Taps the slider's track at [fraction] of its width, on its middle line.
Future<void> _tapTrack(
  WidgetTester tester,
  String slug,
  double fraction,
) async {
  final rect = tester.getRect(_track(slug));
  await tester.tapAt(Offset(rect.left + rect.width * fraction, rect.center.dy));
  await tester.pumpAndSettle();
}

/// The widget that draws the slider in each example.
Finder _track(String slug) {
  final within = byId(_slider(slug));
  for (final type in [Slider, CupertinoSlider]) {
    final found = find.descendant(of: within, matching: find.byType(type));
    if (found.evaluate().isNotEmpty) return found;
  }
  return find.descendant(of: within, matching: find.byType(GestureDetector));
}

void main() {
  test('the technique has the examples named in the spec', () {
    expect(f10Slider.examples.map((e) => e.slug), [
      ..._good,
      'bad-unlabelled',
      'bad-indicator-label',
      'bad-percent-value',
      'bad-no-keyboard',
      'bad-drag-only',
    ]);
    expect(_good, [
      for (final e in f10Slider.examples)
        if (e.kind == ExampleKind.good) e.slug,
    ]);
  });

  group('good examples', () {
    for (final slug in _good) {
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

      testWidgets('$slug: a tap on the track or a step button sets the '
          'value, with no drag', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        final before = _data(slug).value;
        if (slug == 'good-cupertino') {
          // A CupertinoSlider answers a drag of its thumb only (FL-121):
          // the buttons are the single-pointer way.
          await _tapTrack(tester, slug, 0.95);
          expect(_data(slug).value, before);
          await tester.tap(byId('f10-good-cupertino-up'));
          await tester.pumpAndSettle();
          expect(_data(slug).value, '50%');
          await tester.tap(byId('f10-good-cupertino-down'));
          await tester.tap(byId('f10-good-cupertino-down'));
          await tester.pumpAndSettle();
          expect(_data(slug).value, '30%');
          expect(_count(tester, slug), 3);
        } else {
          await _tapTrack(tester, slug, 0.995);
          expect(
            _data(slug).value,
            slug == 'good-value-text' ? '10 out of 10' : '100%',
          );
          expect(_count(tester, slug), 1);
        }
        handle.dispose();
      });
    }
  });

  group('every slider', () {
    for (final MapEntry(key: slug, value: (name, value, up, down))
        in _start.entries) {
      testWidgets('$slug: a slider named "$name" at $value, with the '
          'values either side', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        final data = _data(slug);
        expect(data.flagsCollection.isSlider, isTrue);
        expect(data.label, name);
        expect(data.value, value);
        expect(data.increasedValue, up);
        expect(data.decreasedValue, down);
        expect(data.hasAction(SemanticsAction.increase), isTrue);
        expect(data.hasAction(SemanticsAction.decrease), isTrue);
        // One node is the slider: nothing else on the screen is.
        expect(
          semanticsNodes(tester).where((n) => n.flagsCollection.isSlider),
          hasLength(1),
        );
        handle.dispose();
      });

      testWidgets('$slug: the increase and decrease actions move it a step '
          'and report the new value', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        tester.semantics.increase(nodeById(_slider(slug)));
        await tester.pumpAndSettle();
        expect(_data(slug).value, up);
        tester.semantics.decrease(nodeById(_slider(slug)));
        await tester.pumpAndSettle();
        tester.semantics.decrease(nodeById(_slider(slug)));
        await tester.pumpAndSettle();
        expect(_data(slug).value, down);
        expect(_count(tester, slug), 3);
        handle.dispose();
      });
    }

    for (final slug in _withKeyboard) {
      testWidgets('$slug: Tab reaches the slider; the arrow keys move it a '
          'step, Home and End to the ends', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await tabTo(tester, _slider(slug));
        final (_, start, up, down) = _start[slug]!;
        final (first, last) = _ends[slug] ?? ('0%', '100%');
        for (final (key, expected) in [
          (LogicalKeyboardKey.arrowRight, up),
          (LogicalKeyboardKey.arrowLeft, start),
          (LogicalKeyboardKey.arrowUp, up),
          (LogicalKeyboardKey.arrowDown, start),
          (LogicalKeyboardKey.arrowDown, down),
          (LogicalKeyboardKey.end, last),
          (LogicalKeyboardKey.home, first),
        ]) {
          await tester.sendKeyEvent(key);
          await tester.pumpAndSettle();
          expect(_data(slug).value, expected, reason: '$key');
        }
        expect(
          _data(slug).flagsCollection.isFocused,
          Tristate.isTrue,
          reason: 'focus stays on the slider',
        );
        expect(_count(tester, slug), 7);
        handle.dispose();
      });
    }

    for (final slug in ['good-material', 'good-value-text', 'good-custom']) {
      testWidgets('$slug: a drag along the track moves it', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await tester.drag(_track(slug), const Offset(-2000, 0));
        await tester.pumpAndSettle();
        expect(
          _data(slug).value,
          slug == 'good-value-text' ? '0 out of 10' : '0%',
        );
        handle.dispose();
      });
    }
  });

  group('the value', () {
    testWidgets('good-value-text: the value is the words on the screen, and '
        'the name stays "Rating" as it changes', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-value-text');
      expect(find.text('4 out of 10'), findsOneWidget);
      tester.semantics.increase(nodeById(_slider('good-value-text')));
      await tester.pumpAndSettle();
      expect(find.text('5 out of 10'), findsOneWidget);
      expect(_data('good-value-text').value, '5 out of 10');
      expect(_data('good-value-text').label, 'Rating');
      // The visible value is not a node of its own.
      expect(
        semanticsNodes(tester).where((n) => n.label.contains('out of 10')),
        isEmpty,
      );
      handle.dispose();
    });
  });

  group('bad examples have their defect', () {
    testWidgets('bad-unlabelled: the slider has no name, and the text is a '
        'node of its own', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-unlabelled');
      expect(_data('bad-unlabelled').label, isEmpty);
      expect(
        semanticsNodes(tester).where((n) => n.label == 'Volume'),
        hasLength(1),
      );
      handle.dispose();
    });

    testWidgets('bad-indicator-label: the indicator text is in the name, '
        'which changes at every step', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-indicator-label');
      expect(_data('bad-indicator-label').label, 'Volume\n4');
      tester.semantics.increase(nodeById(_slider('bad-indicator-label')));
      await tester.pumpAndSettle();
      expect(_data('bad-indicator-label').label, 'Volume\n5');
      expect(_data('bad-indicator-label').value, '50%');
      handle.dispose();
    });

    testWidgets('bad-percent-value: the screen says "4 out of 10" and the '
        'value is "40%"', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-percent-value');
      expect(find.text('4 out of 10'), findsOneWidget);
      expect(_data('bad-percent-value').value, '40%');
      tester.semantics.increase(nodeById(_slider('bad-percent-value')));
      await tester.pumpAndSettle();
      expect(find.text('5 out of 10'), findsOneWidget);
      expect(_data('bad-percent-value').value, '50%');
      handle.dispose();
    });

    testWidgets('bad-no-keyboard: the slider cannot take focus, and Tab '
        'goes from Back to nothing else', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-no-keyboard');
      expect(_data('bad-no-keyboard').flagsCollection.isFocused, Tristate.none);
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(
          _data('bad-no-keyboard').flagsCollection.isFocused,
          isNot(Tristate.isTrue),
        );
      }
      for (final key in [
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.end,
      ]) {
        await tester.sendKeyEvent(key);
        await tester.pumpAndSettle();
      }
      expect(_data('bad-no-keyboard').value, '40%');
      expect(_count(tester, 'bad-no-keyboard'), 0);
      // A screen reader can still adjust it.
      tester.semantics.increase(nodeById(_slider('bad-no-keyboard')));
      await tester.pumpAndSettle();
      expect(_data('bad-no-keyboard').value, '50%');
      handle.dispose();
    });

    testWidgets('bad-drag-only: a tap on the track does nothing, and a drag '
        'moves it', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-drag-only');
      await _tapTrack(tester, 'bad-drag-only', 0.995);
      await _tapTrack(tester, 'bad-drag-only', 0.05);
      expect(_data('bad-drag-only').value, '40%');
      expect(_count(tester, 'bad-drag-only'), 0);
      await tester.drag(_track('bad-drag-only'), const Offset(2000, 0));
      await tester.pumpAndSettle();
      expect(_data('bad-drag-only').value, '100%');
      handle.dispose();
    });
  });

  // What the SDK's sliders do on their own, under the examples: each test
  // is written to fail when Flutter changes it, so that the limitation
  // entry is looked at again. FL-029, the empty element a Material Slider
  // adds, is on the web only and is asserted in web_tests/f10_slider.spec.js:
  // off the web the framework grafts that node under its traversal parent,
  // the slider (semantics.dart, _updateChildrenInTraversalOrder), and it is
  // not in the tree these tests read.
  group('Flutter limitations', () {
    Future<double> pumpAlone(
      WidgetTester tester,
      Widget Function(double value, ValueChanged<double> set) slider,
    ) async {
      var value = 0.4;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  TextButton(onPressed: () {}, child: const Text('Before')),
                  slider(value, (v) => setState(() => value = v)),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return value;
    }

    testWidgets('FL-120: a CupertinoSlider takes no keyboard focus', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpAlone(
        tester,
        (value, set) => CupertinoSlider(value: value, onChanged: set),
      );
      final slider = semanticsNodes(tester)
          .singleWhere((n) => n.flagsCollection.isSlider);
      expect(slider.flagsCollection.isFocused, Tristate.none);
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      expect(
        semanticsNodes(tester)
            .singleWhere((n) => n.flagsCollection.isSlider)
            .flagsCollection
            .isFocused,
        isNot(Tristate.isTrue),
      );
      handle.dispose();
    });

    testWidgets('FL-121: a tap on a CupertinoSlider\'s track away from the '
        'thumb does nothing', (tester) async {
      var changes = 0;
      await pumpAlone(
        tester,
        (value, set) => CupertinoSlider(
          value: value,
          onChanged: (v) {
            changes++;
            set(v);
          },
        ),
      );
      final rect = tester.getRect(find.byType(CupertinoSlider));
      await tester.tapAt(Offset(rect.left + rect.width * 0.9, rect.center.dy));
      await tester.pumpAndSettle();
      expect(changes, 0);
      // A drag of the thumb does move it.
      await tester.dragFrom(
        Offset(rect.left + rect.width * 0.4, rect.center.dy),
        const Offset(100, 0),
      );
      await tester.pumpAndSettle();
      expect(changes, greaterThan(0));
    });

    testWidgets('FL-122: a Slider has no Home or End keys', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpAlone(
        tester,
        (value, set) => Slider(value: value, divisions: 10, onChanged: set),
      );
      for (var i = 0; i < 2; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      SemanticsData slider() =>
          semanticsNodes(tester).singleWhere((n) => n.flagsCollection.isSlider);
      expect(slider().flagsCollection.isFocused, Tristate.isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(slider().value, '50%');
      // Each key is checked by itself: End up a step and Home back down
      // would also end at 50%.
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(slider().value, '50%');
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      expect(slider().value, '50%');
      handle.dispose();
    });

    testWidgets('FL-124: a disabled slider has no increase or decrease '
        'action, and a disabled CupertinoSlider has no value', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Slider(value: 0.4, onChanged: null),
                CupertinoSlider(value: 0.4, onChanged: null),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final sliders = semanticsNodes(tester)
          .where((n) => n.flagsCollection.isSlider)
          .toList();
      expect(sliders, hasLength(2));
      for (final slider in sliders) {
        expect(slider.hasAction(SemanticsAction.increase), isFalse);
        expect(slider.hasAction(SemanticsAction.decrease), isFalse);
      }
      expect(sliders[0].value, '40%');
      expect(sliders[0].flagsCollection.isEnabled, Tristate.isFalse);
      expect(sliders[1].value, isEmpty);
      handle.dispose();
    });
  });
}
