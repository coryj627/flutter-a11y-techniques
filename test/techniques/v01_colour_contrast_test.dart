import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_a11y_techniques/app/screens.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/v01_colour_contrast/v01_colour_contrast.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/examples.dart';

/// L1 for V01 Colour contrast (docs/specs/V01-colour-contrast.md, section
/// 6). Every contrast here is read from the pixels Flutter draws, never
/// from the theme: the app's layer tree is captured at a device pixel ratio
/// of 3, and each text, edge, or mark is measured where it is drawn, with
/// the measures of section 6 ([_textContrast], [_edge], [_marks]). The
/// other layers measure the platforms' own screenshots the same way. The
/// font of the widget tests draws every letter as a solid box, so a text's
/// colour is its boxes' colour; on the devices it is the colour of the
/// letters' strokes.
final _open = exampleOpener(v01ColourContrast);

const _good = [
  'good-material',
  'good-cupertino',
  'good-caption',
  'good-selection',
];
const _bad = [
  'bad-cupertino-placeholder',
  'bad-caption',
  'bad-colour-only',
  'bad-faint-edge',
];

/// The device pixel ratio of the pixel tests.
const _dpr = 3.0;

/// Opens [slug] on a screen of 400 by 800 logical pixels at [_dpr].
Future<void> _openForPixels(
  WidgetTester tester,
  String slug,
  Brightness brightness,
) async {
  tester.view.physicalSize = const Size(400 * _dpr, 800 * _dpr);
  tester.view.devicePixelRatio = _dpr;
  addTearDown(tester.view.reset);
  await _open(tester, slug, brightness: brightness);
}

// --- Pixels ---------------------------------------------------------------

/// A capture of the screen, as 0xRRGGBB per pixel.
class _Shot {
  _Shot(this.width, this.height, this.pixels);

  final int width;
  final int height;
  final List<int> pixels;

  int at(int x, int y) => pixels[y * width + x];
}

Future<_Shot> _shot(WidgetTester tester) async {
  final view = tester.binding.renderViews.first;
  final layer = view.debugLayer! as OffsetLayer;
  // The root layer already scales by the device pixel ratio.
  final ui.Image image = await layer.toImage(
    Offset.zero & tester.view.physicalSize,
  );
  final bytes = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  );
  final pixels = List<int>.generate(image.width * image.height, (i) {
    final o = i * 4;
    return bytes!.getUint8(o) << 16 |
        bytes.getUint8(o + 1) << 8 |
        bytes.getUint8(o + 2);
  });
  final shot = _Shot(image.width, image.height, pixels);
  image.dispose();
  return shot;
}

double _luminance(int c) {
  double lin(int v) {
    final s = v / 255;
    return s <= 0.04045 ? s / 12.92 : math.pow((s + 0.055) / 1.055, 2.4) * 1.0;
  }

  return 0.2126 * lin((c >> 16) & 255) +
      0.7152 * lin((c >> 8) & 255) +
      0.0722 * lin(c & 255);
}

/// WCAG's contrast ratio between two colours.
double _ratio(int a, int b) {
  final la = _luminance(a), lb = _luminance(b);
  final hi = math.max(la, lb), lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// The largest difference between two colours in any channel.
int _diff(int a, int b) {
  var most = 0;
  for (final s in [16, 8, 0]) {
    most = math.max(most, (((a >> s) & 255) - ((b >> s) & 255)).abs());
  }
  return most;
}

String _hex(int c) => '#${c.toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// The physical rectangle of [finder]'s render box.
Rect _rect(WidgetTester tester, Finder finder) {
  final r = tester.getRect(finder);
  return Rect.fromLTRB(
    r.left * _dpr,
    r.top * _dpr,
    r.right * _dpr,
    r.bottom * _dpr,
  );
}

/// What the text measure found.
class _Text {
  _Text(this.colour, this.lowest, this.under, this.textPixels, this.core);

  /// The text's colour: the commonest colour of its pixels.
  final int colour;

  /// The lowest contrast of [colour] against what is above or below the
  /// text in any column the text is in, and that colour.
  final double lowest;
  final int under;

  /// Pixels that differ from what is round the text, and how many of them
  /// are exactly [colour].
  final int textPixels;
  final int core;

  @override
  String toString() =>
      'text ${_hex(colour)}, lowest ${lowest.toStringAsFixed(2)}:1 over '
      '${_hex(under)} ($core of $textPixels pixels the text colour)';
}

/// The text measure (the spec, section 6, item 1). [box] is the text's
/// paragraph in physical pixels. For each column the colours round the
/// text are the pixels 6 above the box and 6 below it; a pixel of the box
/// that differs from both by more than 12 in some channel is a text pixel;
/// the text's colour is the commonest text pixel; and the contrast is the
/// lowest, over every column with a pixel of that colour, of the text's
/// colour against either colour round it there.
_Text _textContrast(_Shot s, Rect box) {
  final l = box.left.floor(), r = box.right.ceil() - 1;
  final t = box.top.floor(), b = box.bottom.ceil() - 1;
  final above = t - 6, below = b + 6;
  expect(above >= 0 && below < s.height, isTrue, reason: 'box off the screen');
  final counts = <int, int>{};
  var textPixels = 0;
  for (var x = l; x <= r; x++) {
    final up = s.at(x, above), down = s.at(x, below);
    for (var y = t; y <= b; y++) {
      final c = s.at(x, y);
      if (_diff(c, up) > 12 && _diff(c, down) > 12) {
        textPixels++;
        counts[c] = (counts[c] ?? 0) + 1;
      }
    }
  }
  expect(textPixels, greaterThan(20), reason: 'no text found in $box');
  final colour = counts.entries
      .reduce((a, b) => a.value >= b.value ? a : b)
      .key;
  var lowest = double.infinity;
  var under = 0;
  for (var x = l; x <= r; x++) {
    var has = false;
    for (var y = t; y <= b && !has; y++) {
      has = s.at(x, y) == colour;
    }
    if (!has) continue;
    for (final c in [s.at(x, above), s.at(x, below)]) {
      final q = _ratio(colour, c);
      if (q < lowest) {
        lowest = q;
        under = c;
      }
    }
  }
  return _Text(colour, lowest, under, textPixels, counts[colour]!);
}

/// What the edge measure found.
class _Edge {
  _Edge(this.start, this.edge, this.end);

  final int start, edge, end;

  /// The edge against where the walk began (outside the control) and
  /// against where it ended (inside).
  double get outside => _ratio(edge, start);
  double get inside => _ratio(edge, end);

  @override
  String toString() =>
      'edge ${_hex(edge)}: ${outside.toStringAsFixed(2)}:1 against '
      '${_hex(start)}, ${inside.toStringAsFixed(2)}:1 against ${_hex(end)}';
}

/// The edge measure (section 6, item 2): from [from], a physical pixel
/// outside the control, [steps] physical pixels in the direction
/// ([dx], [dy]); the edge is the pixel on the way that contrasts most with
/// the first, and it is taken against the first and against the last.
_Edge _edge(_Shot s, Offset from, int dx, int dy, int steps) {
  final x0 = from.dx.round(), y0 = from.dy.round();
  final start = s.at(x0, y0);
  var edge = start;
  for (var i = 1; i <= steps; i++) {
    final c = s.at(x0 + dx * i, y0 + dy * i);
    if (_ratio(c, start) > _ratio(edge, start)) edge = c;
  }
  return _Edge(start, edge, s.at(x0 + dx * steps, y0 + dy * steps));
}

/// The pixels of [area] that are 3:1 or more against [against]: the marks a
/// control draws there (section 6, item 3).
int _marks(_Shot s, Rect area, int against) {
  var n = 0;
  for (var y = area.top.floor(); y < area.bottom.ceil(); y++) {
    for (var x = area.left.floor(); x < area.right.ceil(); x++) {
      if (_ratio(s.at(x, y), against) >= 3) n++;
    }
  }
  return n;
}

// --- Input ----------------------------------------------------------------

/// Puts keyboard focus on [id] with Tab.
Future<void> _focus(WidgetTester tester, String id) async {
  await tabTo(tester, id);
  await tester.pumpAndSettle();
}

/// A mouse, at the screen's top left corner, over nothing.
Future<TestGesture> _mouse(WidgetTester tester) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: Offset.zero);
  addTearDown(mouse.removePointer);
  return mouse;
}

/// Moves [mouse] over [finder] and leaves it there.
Future<void> _hover(
  WidgetTester tester,
  TestGesture mouse,
  Finder finder,
) async {
  await mouse.moveTo(tester.getCenter(finder));
  await tester.pumpAndSettle();
}

/// Holds a finger down on [finder] for 300 ms, past the 100 ms after which
/// a control shows it is pressed and short of the 500 ms of a long press;
/// the caller lifts it.
Future<TestGesture> _press(
  WidgetTester tester,
  Finder finder, {
  PointerDeviceKind kind = PointerDeviceKind.touch,
  int steps = 2,
}) async {
  final finger = await tester.startGesture(
    tester.getCenter(finder),
    kind: kind,
  );
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
  return finger;
}

Finder _text(String text) => find.text(text).last;

void main() {
  test('the technique has the examples named in the spec', () {
    expect(v01ColourContrast.examples.map((e) => e.slug), [..._good, ..._bad]);
    expect(_good, [
      for (final e in v01ColourContrast.examples)
        if (e.kind == ExampleKind.good) e.slug,
    ]);
    expect(
      v01ColourContrast.examples.where((e) => e.isCustomSolution),
      isEmpty,
      reason: 'no good example is a custom solution',
    );
  });

  test('the measure gives WCAG\'s ratios for known pairs', () {
    expect(_ratio(0x000000, 0xFFFFFF), closeTo(21, 0.01));
    expect(_ratio(0x767676, 0xFFFFFF), closeTo(4.54, 0.01));
    expect(_ratio(0x949494, 0xFFFFFF), closeTo(3.03, 0.01));
    expect(_ratio(0xFFFFFF, 0xFFFFFF), 1);
  });

  group('good examples meet the guidelines', () {
    for (final slug in _good) {
      for (final brightness in Brightness.values) {
        testWidgets('$slug (${brightness.name})', (tester) async {
          final handle = tester.ensureSemantics();
          await _open(tester, slug, brightness: brightness);
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
  // layout overflows, and no text in the example is cut short.
  for (final example in v01ColourContrast.examples) {
    final slug = example.slug;
    testWidgets('$slug: at 200% text on a phone nothing overflows and no '
        'text is cut short', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _open(tester, slug, textScale: 2);
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
    });
  }

  group('semantics', () {
    testWidgets('good-material: a text field, a checkbox, and a button, '
        'each named', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-material');
      final email = dataById('v01-good-material-email');
      expect(email.flagsCollection.isTextField, isTrue);
      expect(email.label, 'Email');
      final updates = dataById('v01-good-material-updates');
      expect(updates.label, 'Send me updates');
      expect(updates.flagsCollection.isChecked, CheckedState.isFalse);
      final send = dataById('v01-good-material-send');
      expect(send.flagsCollection.isButton, isTrue);
      expect(send.label, 'Send');
      handle.dispose();
    });

    for (final slug in ['good-cupertino', 'bad-cupertino-placeholder']) {
      testWidgets('$slug: the field is named "Email", and the label above '
          'it is not a node of its own', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        final email = dataById('v01-$slug-email');
        expect(email.flagsCollection.isTextField, isTrue);
        // The placeholder joins the name, after a line break.
        expect(email.label, 'Email\nRequired');
        expect(
          semanticsNodes(tester).where((d) => d.label.startsWith('Email')),
          hasLength(1),
        );
        handle.dispose();
      });
    }

    for (final slug in ['good-caption', 'bad-caption']) {
      testWidgets('$slug: the caption is one text node', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        expect(
          semanticsNodes(tester).where((d) => d.label == 'Harbour'),
          hasLength(1),
        );
        handle.dispose();
      });
    }

    testWidgets('good-selection: three radio buttons in a group, Week '
        'chosen; a tap on Day chooses Day', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-selection');
      for (final (name, on) in [
        ('Day', false),
        ('Week', true),
        ('Month', false),
      ]) {
        final d = dataById('v01-good-selection-${name.toLowerCase()}');
        expect(d.label, name);
        expect(d.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
        expect(
          d.flagsCollection.isChecked,
          on ? CheckedState.isTrue : CheckedState.isFalse,
        );
      }
      await tester.tap(byId('v01-good-selection-day'));
      await tester.pumpAndSettle();
      expect(
        dataById('v01-good-selection-day').flagsCollection.isChecked,
        CheckedState.isTrue,
      );
      handle.dispose();
    });

    testWidgets('bad-colour-only: three buttons, Week selected; a tap on Day '
        'selects Day (the state reaches the semantics tree; the defect is '
        'what is drawn)', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-colour-only');
      for (final (name, on) in [
        ('Day', false),
        ('Week', true),
        ('Month', false),
      ]) {
        final d = dataById('v01-bad-colour-only-${name.toLowerCase()}');
        expect(d.label, name);
        expect(d.flagsCollection.isButton, isTrue);
        expect(
          d.flagsCollection.isSelected,
          on ? Tristate.isTrue : Tristate.isFalse,
        );
      }
      await tester.tap(byId('v01-bad-colour-only-day'));
      await tester.pumpAndSettle();
      expect(
        dataById('v01-bad-colour-only-day').flagsCollection.isSelected,
        Tristate.isTrue,
      );
      handle.dispose();
    });

    testWidgets('bad-faint-edge: a text field named "Email"', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-faint-edge');
      final email = dataById('v01-bad-faint-edge-email');
      expect(email.flagsCollection.isTextField, isTrue);
      expect(email.label, 'Email');
      handle.dispose();
    });
  });

  group('pixels', () {
    for (final brightness in Brightness.values) {
      final mode = brightness.name;

      testWidgets('good-material: every text 4.5:1 or more, and the field\'s '
          'edge, the checkbox, and the button\'s outline 3:1 or more, at '
          'rest ($mode)', (tester) async {
        await _openForPixels(tester, 'good-material', brightness);
        final s = await _shot(tester);
        for (final t in [
          'We reply within two days.',
          'Email',
          'Required',
          'Send me updates',
          'Send',
        ]) {
          final m = _textContrast(s, _rect(tester, _text(t)));
          expect(m.lowest, greaterThanOrEqualTo(4.5), reason: '"$t": $m');
        }
        final field = _rect(tester, byId('v01-good-material-email'));
        final edge = _edge(
          s,
          Offset(field.left - 12, field.center.dy),
          1,
          0,
          30,
        );
        expect(edge.outside, greaterThanOrEqualTo(3), reason: 'field $edge');
        final box = _rect(tester, find.byType(Checkbox));
        final boxEdge = _edge(
          s,
          Offset(box.right - 3, box.center.dy),
          -1,
          0,
          66,
        );
        expect(
          boxEdge.outside,
          greaterThanOrEqualTo(3),
          reason: 'box $boxEdge',
        );
        final send = _rect(tester, byId('v01-good-material-send'));
        final outline = _edge(
          s,
          Offset(send.left - 6, send.center.dy),
          1,
          0,
          30,
        );
        expect(
          outline.outside,
          greaterThanOrEqualTo(3),
          reason: 'outline $outline',
        );
      });

      testWidgets('good-material: the checkbox checked, its fill 3:1 against '
          'the page and its mark 3:1 against the fill ($mode)', (tester) async {
        await _openForPixels(tester, 'good-material', brightness);
        await tester.tap(byId('v01-good-material-updates'));
        await tester.pumpAndSettle();
        final s = await _shot(tester);
        final box = _rect(tester, find.byType(Checkbox));
        final fill = _edge(s, Offset(box.right - 3, box.center.dy), -1, 0, 66);
        expect(fill.outside, greaterThanOrEqualTo(3), reason: 'fill $fill');
        final inner = Rect.fromCenter(
          center: box.center,
          width: 30,
          height: 30,
        );
        expect(
          _marks(s, inner, fill.edge),
          greaterThan(30),
          reason: 'no mark 3:1 on the fill',
        );
        expect(
          _textContrast(s, _rect(tester, _text('Send me updates'))).lowest,
          greaterThanOrEqualTo(4.5),
        );
      });

      for (final state in [
        'focused',
        'hovered',
        'focused and hovered',
        'pressed',
        'held 2 s by a mouse',
      ]) {
        testWidgets('good-material: each control\'s text 4.5:1 or more when '
            '$state ($mode)', (tester) async {
          await _openForPixels(tester, 'good-material', brightness);
          final mouse = await _mouse(tester);
          for (final (id, label) in [
            ('v01-good-material-email', 'Email'),
            ('v01-good-material-updates', 'Send me updates'),
            ('v01-good-material-send', 'Send'),
          ]) {
            TestGesture? held;
            if (state.contains('focused')) await _focus(tester, id);
            if (state.contains('hovered')) {
              await _hover(tester, mouse, byId(id));
            }
            if (state == 'pressed') held = await _press(tester, byId(id));
            if (state.startsWith('held')) {
              await mouse.moveTo(tester.getCenter(byId(id)));
              await tester.pump();
              held = await _press(
                tester,
                byId(id),
                kind: PointerDeviceKind.mouse,
                steps: 14,
              );
            }
            final s = await _shot(tester);
            final m = _textContrast(s, _rect(tester, _text(label)));
            // ignore: avoid_print
            print('V01 good-material $id $state $mode: $m');
            expect(m.lowest, greaterThanOrEqualTo(4.5), reason: '$id: $m');
            if (id.endsWith('email') && state.contains('focused')) {
              final hint = _textContrast(s, _rect(tester, _text('Required')));
              expect(
                hint.lowest,
                greaterThanOrEqualTo(4.5),
                reason: 'hint: $hint',
              );
            }
            await held?.up();
            await mouse.moveTo(Offset.zero);
            await tester.pumpAndSettle();
          }
        });
      }

      testWidgets('good-cupertino: the label, the placeholder, and the '
          'button\'s text 4.5:1 or more, the field\'s edge 3:1 or more '
          'against the page and the field ($mode)', (tester) async {
        await _openForPixels(tester, 'good-cupertino', brightness);
        final s = await _shot(tester);
        for (final t in ['Email', 'Required', 'Send']) {
          final m = _textContrast(s, _rect(tester, _text(t)));
          expect(m.lowest, greaterThanOrEqualTo(4.5), reason: '"$t": $m');
        }
        final field = _rect(tester, byId('v01-good-cupertino-email'));
        final edge = _edge(
          s,
          Offset(field.left - 6, field.center.dy),
          1,
          0,
          18,
        );
        expect(edge.outside, greaterThanOrEqualTo(3), reason: '$edge');
        expect(edge.inside, greaterThanOrEqualTo(3), reason: '$edge');
      });

      for (final state in ['focused', 'hovered', 'pressed']) {
        testWidgets('good-cupertino: the button\'s text when $state '
            '($mode)', (tester) async {
          await _openForPixels(tester, 'good-cupertino', brightness);
          const id = 'v01-good-cupertino-send';
          TestGesture? held;
          if (state == 'focused') await _focus(tester, id);
          if (state == 'hovered') {
            await _hover(tester, await _mouse(tester), byId(id));
          }
          if (state == 'pressed') held = await _press(tester, byId(id));
          final s = await _shot(tester);
          final m = _textContrast(s, _rect(tester, _text('Send')));
          // ignore: avoid_print
          print('V01 good-cupertino $state $mode: $m');
          expect(m.lowest, greaterThanOrEqualTo(4.5), reason: '$m');
          await held?.up();
          await tester.pumpAndSettle();
        });
      }

      testWidgets('good-caption: the caption 4.5:1 or more over the whole '
          'picture ($mode)', (tester) async {
        await _openForPixels(tester, 'good-caption', brightness);
        final s = await _shot(tester);
        final m = _textContrast(s, _rect(tester, _text('Harbour')));
        // ignore: avoid_print
        print('V01 good-caption $mode: $m');
        expect(m.lowest, greaterThanOrEqualTo(4.5), reason: '$m');
      });

      testWidgets('good-selection: each option 4.5:1 or more, each radio '
          'button\'s ring 3:1 or more, and only the chosen one has a dot; a '
          'tap on Day moves the dot ($mode)', (tester) async {
        await _openForPixels(tester, 'good-selection', brightness);
        Future<Map<String, int>> dots() async {
          final s = await _shot(tester);
          final page = s.at(
            2,
            (_rect(tester, byId('v01-good-selection-day')).top - 2).round(),
          );
          final out = <String, int>{};
          for (final v in ['day', 'week', 'month']) {
            final radio = _rect(
              tester,
              find.descendant(
                of: byId('v01-good-selection-$v'),
                matching: find.byWidgetPredicate((w) => w is Radio),
              ),
            );
            final ring = _edge(
              s,
              Offset(radio.left + 3, radio.center.dy),
              1,
              0,
              (radio.width / 2 - 3).round(),
            );
            expect(
              ring.outside,
              greaterThanOrEqualTo(3),
              reason: '$v ring $ring',
            );
            final title = _textContrast(
              s,
              _rect(tester, _text(v[0].toUpperCase() + v.substring(1))),
            );
            expect(
              title.lowest,
              greaterThanOrEqualTo(4.5),
              reason: '$v: $title',
            );
            // The dot: the middle of the ring, 4 logical pixels each way.
            out[v] = _marks(
              s,
              Rect.fromCenter(
                center: radio.center,
                width: 4 * _dpr * 2,
                height: 4 * _dpr * 2,
              ),
              page,
            );
          }
          return out;
        }

        final before = await dots();
        expect(before['week'], greaterThan(100), reason: '$before');
        expect(before['day'], 0, reason: '$before');
        expect(before['month'], 0, reason: '$before');
        await tester.tap(byId('v01-good-selection-day'));
        await tester.pumpAndSettle();
        final after = await dots();
        expect(after['day'], greaterThan(100), reason: '$after');
        expect(after['week'], 0, reason: '$after');
      });

      // --- Bad examples: each defect, measured, written to fail if Flutter
      // draws it otherwise.

      testWidgets('bad-cupertino-placeholder: the placeholder under 4.5:1; '
          'the label and the field\'s edge as in good-cupertino ($mode)', (
        tester,
      ) async {
        await _openForPixels(tester, 'bad-cupertino-placeholder', brightness);
        final s = await _shot(tester);
        final placeholder = _textContrast(s, _rect(tester, _text('Required')));
        // ignore: avoid_print
        print('V01 bad-cupertino-placeholder $mode: $placeholder');
        expect(placeholder.lowest, lessThan(4.5), reason: '$placeholder');
        expect(
          placeholder.lowest,
          greaterThan(1.2),
          reason: 'the placeholder is drawn',
        );
        final label = _textContrast(s, _rect(tester, _text('Email')));
        expect(label.lowest, greaterThanOrEqualTo(4.5), reason: '$label');
        final field = _rect(
          tester,
          byId('v01-bad-cupertino-placeholder-email'),
        );
        final edge = _edge(
          s,
          Offset(field.left - 6, field.center.dy),
          1,
          0,
          18,
        );
        expect(edge.outside, greaterThanOrEqualTo(3), reason: '$edge');
      });

      testWidgets('bad-caption: the caption under 4.5:1 over the pale part '
          'of the picture, and 4.5:1 or more over the dark part ($mode)', (
        tester,
      ) async {
        await _openForPixels(tester, 'bad-caption', brightness);
        final s = await _shot(tester);
        final box = _rect(tester, _text('Harbour'));
        final whole = _textContrast(s, box);
        // ignore: avoid_print
        print('V01 bad-caption $mode: $whole');
        expect(whole.lowest, lessThan(4.5), reason: '$whole');
        expect(whole.lowest, greaterThan(1), reason: 'the caption is drawn');
        // The caption's colour is one that would be 4.5:1 or more over the
        // dark end of the picture, at the right of the same bar: what fails
        // is where it is drawn.
        final dark = s.at(
          _rect(tester, find.byType(GridTileBar)).right.round() - 4,
          box.center.dy.round(),
        );
        expect(_ratio(whole.colour, dark), greaterThanOrEqualTo(4.5));
      });

      testWidgets('bad-colour-only: the chosen title differs from the others '
          'by colour alone, under 3:1 against theirs; each 4.5:1 or more '
          'against the page; a tap on Day moves the colour ($mode)', (
        tester,
      ) async {
        await _openForPixels(tester, 'bad-colour-only', brightness);
        Future<Map<String, _Text>> titles() async {
          final s = await _shot(tester);
          final out = <String, _Text>{};
          for (final v in ['Day', 'Week', 'Month']) {
            final m = _textContrast(s, _rect(tester, _text(v)));
            expect(m.lowest, greaterThanOrEqualTo(4.5), reason: '$v: $m');
            out[v] = m;
            // Nothing but the title is drawn on the tile: every pixel of
            // the tile outside the title's box is the page's colour.
            final tile = _rect(
              tester,
              byId('v01-bad-colour-only-${v.toLowerCase()}'),
            );
            final title = _rect(tester, _text(v)).inflate(2);
            final page = s.at(tile.left.round() + 1, tile.top.round() + 1);
            var other = 0;
            for (var y = tile.top.ceil(); y < tile.bottom.floor(); y++) {
              for (var x = tile.left.ceil(); x < tile.right.floor(); x++) {
                if (!title.contains(Offset(x.toDouble(), y.toDouble())) &&
                    _diff(s.at(x, y), page) > 2) {
                  other++;
                }
              }
            }
            expect(other, 0, reason: '$v: $other pixels besides the title');
          }
          return out;
        }

        final before = await titles();
        final chosen = before['Week']!.colour;
        for (final v in ['Day', 'Month']) {
          final q = _ratio(chosen, before[v]!.colour);
          // ignore: avoid_print
          print(
            'V01 bad-colour-only $mode: Week ${_hex(chosen)} against $v '
            '${_hex(before[v]!.colour)} ${q.toStringAsFixed(2)}:1',
          );
          expect(before[v]!.colour, isNot(chosen));
          expect(q, lessThan(3), reason: 'Week against $v');
        }
        await tester.tap(byId('v01-bad-colour-only-day'));
        await tester.pumpAndSettle();
        final after = await titles();
        expect(after['Day']!.colour, chosen, reason: 'the colour moved to Day');
        expect(after['Week']!.colour, before['Day']!.colour);
      });

      testWidgets('bad-faint-edge: the field\'s edge under 3:1 against the '
          'page at rest; with focus the same measure finds it 3:1 or more '
          '($mode)', (tester) async {
        await _openForPixels(tester, 'bad-faint-edge', brightness);
        var s = await _shot(tester);
        final field = _rect(tester, byId('v01-bad-faint-edge-email'));
        final rest = _edge(
          s,
          Offset(field.left - 12, field.center.dy),
          1,
          0,
          30,
        );
        // ignore: avoid_print
        print('V01 bad-faint-edge $mode: $rest');
        expect(rest.outside, lessThan(3), reason: '$rest');
        expect(rest.outside, greaterThan(1.2), reason: 'the edge is drawn');
        final label = _textContrast(s, _rect(tester, _text('Email')));
        expect(label.lowest, greaterThanOrEqualTo(4.5), reason: '$label');
        await _focus(tester, 'v01-bad-faint-edge-email');
        s = await _shot(tester);
        final focused = _edge(
          s,
          Offset(field.left - 12, field.center.dy),
          1,
          0,
          30,
        );
        expect(focused.outside, greaterThanOrEqualTo(3), reason: '$focused');
      });
    }
  });

  // The defaults good-cupertino changes, each on its own in the app's
  // theme, light and dark: written to fail when Flutter changes them.
  group('limitations', () {
    Future<void> pumpAlone(
      WidgetTester tester,
      Brightness brightness,
      Widget child,
    ) async {
      tester.view.physicalSize = const Size(400 * _dpr, 400 * _dpr);
      tester.view.devicePixelRatio = _dpr;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      // The catalog app's themes, as lib/app/app.dart gives them.
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorSchemeSeed: Colors.indigo),
          darkTheme: ThemeData(
            colorSchemeSeed: Colors.indigo,
            brightness: Brightness.dark,
          ),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(40),
              child: Align(alignment: Alignment.topLeft, child: child),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    for (final brightness in Brightness.values) {
      final mode = brightness.name;

      testWidgets('FL-511: a CupertinoTextField\'s default edge is under '
          '3:1 against the page and against the field ($mode)', (tester) async {
        await pumpAlone(
          tester,
          brightness,
          const SizedBox(width: 280, child: CupertinoTextField()),
        );
        final s = await _shot(tester);
        final field = _rect(tester, find.byType(CupertinoTextField));
        final edge = _edge(
          s,
          Offset(field.left - 6, field.center.dy),
          1,
          0,
          18,
        );
        // ignore: avoid_print
        print('V01 FL-511 $mode: $edge');
        expect(edge.outside, lessThan(3), reason: '$edge');
        expect(edge.inside, lessThan(3), reason: '$edge');
        expect(edge.outside, greaterThan(1), reason: 'the edge is drawn');
      });

      testWidgets('FL-514: a CupertinoButton.filled\'s text is under 4.5:1 '
          'on its fill while it is pressed, and 4.5:1 or more at rest '
          '($mode)', (tester) async {
        await pumpAlone(
          tester,
          brightness,
          CupertinoButton.filled(onPressed: () {}, child: const Text('Send')),
        );
        final rest = _textContrast(
          await _shot(tester),
          _rect(tester, find.text('Send')),
        );
        expect(rest.lowest, greaterThanOrEqualTo(4.5), reason: '$rest');
        final finger = await _press(tester, find.byType(CupertinoButton));
        final pressed = _textContrast(
          await _shot(tester),
          _rect(tester, find.text('Send')),
        );
        // ignore: avoid_print
        print('V01 FL-514 $mode: at rest $rest; pressed $pressed');
        expect(pressed.lowest, lessThan(4.5), reason: '$pressed');
        await finger.up();
        await tester.pumpAndSettle();
      });
    }
  });
}
