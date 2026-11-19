import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/v14_focus_indicators/v14_focus_indicators.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/examples.dart';

/// L1 for V14 Focus indicators (docs/specs/V14-focus-indicators.md).
///
/// What a focus indicator is, here, is read from the pixels Flutter draws:
/// the screen is captured before a control has focus and twice after Tab
/// has put focus on it, and the indicator is every pixel round the control
/// that changed in both captures and is the same in both. Its colour is the
/// commonest of those pixels, and the page's colour the commonest along the
/// edge of the area looked at, before focus; the contrast ratio is worked
/// out from those two colours, never from the theme. The other layers do
/// the same with the platform's own screenshots.
final _open = exampleOpener(v14FocusIndicators);

const _good = [
  'good-material',
  'good-cupertino',
  'good-widgets',
  'good-notice-below',
];
const _bad = [
  'bad-indicator-removed',
  'bad-checkbox-halo',
  'bad-cupertino-ring',
  'bad-notice-over-list',
];
const _all = [..._good, ..._bad];

/// The controls of each example that are not in a scrolling list, in Tab
/// order, with their names.
const _controls = <String, List<(String, String)>>{
  'good-material': [('alerts', 'Weather alerts'), ('save', 'Save')],
  'good-cupertino': [('alerts', 'Weather alerts'), ('save', 'Save')],
  'good-widgets': [('trail', 'Ridge trail')],
  'bad-indicator-removed': [('save', 'Save')],
  'bad-checkbox-halo': [('alerts', 'Weather alerts')],
  'bad-cupertino-ring': [('save', 'Save')],
};

const _trails = [
  'Ridge trail',
  'Lake loop',
  'Summit path',
  'Forest walk',
  'River run',
  'Canyon climb',
];

String _id(String slug, String control) => 'v14-$slug-$control';

String _lastUsed(WidgetTester tester, String slug) => tester
    .widget<Text>(
      find.descendant(of: byId('v14-$slug-count'), matching: find.byType(Text)),
    )
    .data!;

/// The control with keyboard focus, by its identifier's last part, "back",
/// or "none".
String _stop(WidgetTester tester, String slug) {
  final focused = semanticsNodes(tester)
      .where((d) => d.flagsCollection.isFocused == Tristate.isTrue)
      .toList();
  if (focused.isEmpty) return 'none';
  expect(focused, hasLength(1), reason: 'more than one node has focus');
  final node = focused.single;
  if (node.tooltip == 'Back') return 'back';
  final prefix = 'v14-$slug-';
  if (node.identifier.startsWith(prefix)) {
    return node.identifier.substring(prefix.length);
  }
  return 'other: ${node.identifier} ${node.label}';
}

Future<void> _tab(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pumpAndSettle();
}

/// Opens [slug] on a screen read pixel for pixel: 800 by 1000 logical
/// pixels at a device pixel ratio of 1.
Future<void> _openForPixels(
  WidgetTester tester,
  String slug, {
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = const Size(800, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await _open(tester, slug, brightness: brightness);
}

/// A capture of the whole screen, as RGBA bytes.
class _Shot {
  _Shot(this.bytes, this.width, this.height);

  final ByteData bytes;
  final int width;
  final int height;

  /// The colour at (x, y), as 0xRRGGBB.
  int at(int x, int y) {
    final o = (y * width + x) * 4;
    return bytes.getUint8(o) << 16 |
        bytes.getUint8(o + 1) << 8 |
        bytes.getUint8(o + 2);
  }
}

Future<_Shot> _shot(WidgetTester tester) async {
  final view = tester.binding.renderViews.first;
  final layer = view.debugLayer! as OffsetLayer;
  final ui.Image image = await layer.toImage(Offset.zero & view.size);
  final bytes = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  );
  final shot = _Shot(bytes!, image.width, image.height);
  image.dispose();
  return shot;
}

int _channelDiff(int a, int b) {
  var most = 0;
  for (final shift in [16, 8, 0]) {
    final d = ((a >> shift) & 255) - ((b >> shift) & 255);
    if (d.abs() > most) most = d.abs();
  }
  return most;
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
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

String _hex(int c) => '#${c.toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// What focus drew in [region].
class _Indicator {
  _Indicator({
    required this.changed,
    required this.unstable,
    required this.drawn,
    required this.page,
    required this.colour,
    required this.share,
    required this.bounds,
    required this.strong,
    required this.strongColour,
    required this.marks,
  });

  /// Drawn pixels that are marks focus made: drawn where the page was, or
  /// 3:1 or more from the colour they replaced.
  final int marks;

  /// [marks] whose colour is 3:1 or more against [page]: the part of the
  /// indicator that meets 1.4.11.
  final int strong;

  /// The commonest colour of the [strong] pixels, or null if none.
  final int? strongColour;

  /// Pixels that differ from before focus in both captures, and agree.
  final int changed;

  /// Pixels that differ in one capture only, or between the two.
  final int unstable;

  /// Changed pixels that are not now the page's colour: what was drawn,
  /// as against what was uncovered.
  final int drawn;

  /// The page's colour: the commonest along the edge of the region,
  /// before focus.
  final int page;

  /// The commonest colour of the drawn pixels, or null if none.
  final int? colour;

  /// The share of the drawn pixels that are [colour].
  final double share;

  /// The rectangle round the drawn pixels.
  final Rect? bounds;

  double get ratio => colour == null ? 1 : _ratio(colour!, page);

  @override
  String toString() =>
      'changed $changed, unstable $unstable, drawn $drawn, page ${_hex(page)}, '
      'indicator ${colour == null ? 'none' : _hex(colour!)} '
      '(${(share * 100).round()}% of drawn), '
      'ratio ${ratio.toStringAsFixed(2)}, bounds $bounds; marks $marks, '
      '3:1 or more: '
      '$strong${strongColour == null ? '' : ' (${_hex(strongColour!)}, '
                '${_ratio(strongColour!, page).toStringAsFixed(2)})'}';
}

/// The pixels a change of a channel by more than this does not count as.
const _threshold = 12;

_Indicator _compare(_Shot u, _Shot f1, _Shot f2, Rect region) {
  final l = math.max(0, region.left.floor());
  final t = math.max(0, region.top.floor());
  final r = math.min(u.width, region.right.ceil());
  final b = math.min(u.height, region.bottom.ceil());
  final edge = <int, int>{};
  for (var x = l; x < r; x++) {
    for (final y in [t, t + 1, b - 2, b - 1]) {
      edge.update(u.at(x, y), (n) => n + 1, ifAbsent: () => 1);
    }
  }
  final page =
      (edge.entries.toList()..sort((a, b) => b.value - a.value)).first.key;
  var changed = 0, unstable = 0, marks = 0;
  final drawn = <int, int>{};
  final strong = <int, int>{};
  var minX = r, minY = b, maxX = l, maxY = t;
  for (var y = t; y < b; y++) {
    for (var x = l; x < r; x++) {
      final a = u.at(x, y), p = f1.at(x, y), q = f2.at(x, y);
      final d1 = _channelDiff(a, p) > _threshold;
      final d2 = _channelDiff(a, q) > _threshold;
      if (d1 && d2 && _channelDiff(p, q) <= _threshold) {
        changed++;
        if (_channelDiff(p, page) > _threshold) {
          drawn.update(p, (n) => n + 1, ifAbsent: () => 1);
          // A mark focus made: drawn where the page was, or standing out
          // 3:1 from what was there. A colour shift inside the control,
          // such as a tinted fill or a border a shade darker, is not one.
          final onPage = _channelDiff(a, page) <= _threshold;
          if (onPage || _ratio(p, a) >= 3) {
            marks++;
            if (_ratio(p, page) >= 3) {
              strong.update(p, (n) => n + 1, ifAbsent: () => 1);
            }
          }
          if (x < minX) minX = x;
          if (y < minY) minY = y;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
        }
      } else if (d1 || d2) {
        unstable++;
      }
    }
  }
  final total = drawn.values.fold(0, (a, b) => a + b);
  final top = total == 0
      ? null
      : (drawn.entries.toList()..sort((a, b) => b.value - a.value)).first;
  final strongTotal = strong.values.fold(0, (a, b) => a + b);
  final strongTop = strongTotal == 0
      ? null
      : (strong.entries.toList()..sort((a, b) => b.value - a.value)).first;
  return _Indicator(
    strong: strongTotal,
    marks: marks,
    strongColour: strongTop?.key,
    changed: changed,
    unstable: unstable,
    drawn: total,
    page: page,
    colour: top?.key,
    share: top == null ? 0 : top.value / total,
    bounds: total == 0
        ? null
        : Rect.fromLTRB(
            minX - region.left,
            minY - region.top,
            maxX - region.left + 1,
            maxY - region.top + 1,
          ),
  );
}

/// The area looked at round a control: its rectangle and 8 pixels more on
/// every side, which is where a ring drawn outside it lies.
Rect _region(WidgetTester tester, Finder control) =>
    tester.getRect(control).inflate(8);

/// Captures [region], presses Tab, checks that the stop is [stop], and
/// captures it twice more, 700 ms apart; returns what changed.
Future<_Indicator> _tabAndMeasure(
  WidgetTester tester,
  String slug,
  String stop,
  Rect Function() region,
) async {
  final before = await _shot(tester);
  await _tab(tester);
  expect(_stop(tester, slug), stop, reason: 'Tab stops on $stop');
  final f1 = await _shot(tester);
  await tester.pump(const Duration(milliseconds: 700));
  final f2 = await _shot(tester);
  return _compare(before, f1, f2, region());
}

/// Tabs until the stop before [control], so that the next Tab reaches it.
Future<void> _tabToBefore(
  WidgetTester tester,
  String slug,
  String control,
) async {
  final order = ['back', for (final (c, _) in _controls[slug]!) c];
  final before = order[order.indexOf(control) - 1];
  for (var i = 0; i < 8 && _stop(tester, slug) != before; i++) {
    await _tab(tester);
  }
  expect(_stop(tester, slug), before);
}

void main() {
  test('the technique has the examples named in the spec', () {
    expect(v14FocusIndicators.examples.map((e) => e.slug), _all);
    expect(_good, [
      for (final e in v14FocusIndicators.examples)
        if (e.kind == ExampleKind.good) e.slug,
    ]);
  });

  test('the contrast ratio is WCAG\'s', () {
    expect(_ratio(0xFFFFFF, 0x000000), closeTo(21, 0.001));
    expect(_ratio(0x767676, 0xFFFFFF), closeTo(4.54, 0.01));
    expect(_ratio(0x949494, 0xFFFFFF), closeTo(3.03, 0.01));
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
    }
  });

  group('names, roles, and keys', () {
    for (final MapEntry(key: slug, value: controls) in _controls.entries) {
      testWidgets('$slug: each control has its name and takes focus, in '
          'order after Back, and Space uses it', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        for (final (c, name) in controls) {
          final data = dataById(_id(slug, c));
          expect(data.label, name);
          expect(data.flagsCollection.isFocused, Tristate.isFalse);
        }
        await _tab(tester);
        expect(_stop(tester, slug), 'back');
        for (final (c, name) in controls) {
          await _tab(tester);
          expect(_stop(tester, slug), c);
          await tester.sendKeyEvent(LogicalKeyboardKey.space);
          await tester.pumpAndSettle();
          expect(_lastUsed(tester, slug), 'Last used: $name');
        }
        handle.dispose();
      });
    }

    for (final slug in ['good-notice-below', 'bad-notice-over-list']) {
      testWidgets('$slug: six trail buttons, reached in order after Back', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await _tab(tester);
        expect(_stop(tester, slug), 'back');
        for (var i = 1; i <= 6; i++) {
          expect(dataById(_id(slug, 'trail$i')).label, _trails[i - 1]);
          expect(dataById(_id(slug, 'trail$i')).flagsCollection.isButton, true);
          await _tab(tester);
          expect(_stop(tester, slug), 'trail$i');
        }
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(_lastUsed(tester, slug), 'Last used: Canyon climb');
        handle.dispose();
      });
    }

    for (final (slug, c, role) in [
      ('good-material', 'alerts', 'checkbox'),
      ('good-cupertino', 'alerts', 'switch'),
      ('bad-checkbox-halo', 'alerts', 'checkbox'),
      ('good-material', 'save', 'button'),
      ('good-cupertino', 'save', 'button'),
      ('good-widgets', 'trail', 'button'),
      ('bad-indicator-removed', 'save', 'button'),
      ('bad-cupertino-ring', 'save', 'button'),
    ]) {
      testWidgets('$slug: $c is a $role', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        final flags = dataById(_id(slug, c)).flagsCollection;
        switch (role) {
          case 'checkbox':
            expect(flags.isChecked, CheckedState.isFalse);
          case 'switch':
            expect(flags.isToggled, Tristate.isFalse);
          default:
            expect(flags.isButton, isTrue);
        }
        handle.dispose();
      });
    }
  });

  group('focus indicators, measured from the pixels', () {
    // Every good control: Tab draws something round it whose commonest
    // colour is at least 3:1 against the page, in light and dark; and it
    // goes when Tab moves on.
    for (final slug in ['good-material', 'good-cupertino', 'good-widgets']) {
      for (final brightness in Brightness.values) {
        testWidgets('$slug (${brightness.name}): each control draws an '
            'indicator of 3:1 or more against the page, which goes when '
            'focus moves on', (tester) async {
          final handle = tester.ensureSemantics();
          await _openForPixels(tester, slug, brightness: brightness);
          final controls = _controls[slug]!;
          await _tabToBefore(tester, slug, controls.first.$1);
          _Shot? lastBefore;
          for (final (c, _) in controls) {
            Rect region() => _region(tester, byId(_id(slug, c)));
            lastBefore = await _shot(tester);
            final ind = await _tabAndMeasure(tester, slug, c, region);
            debugPrint('V14 $slug ${brightness.name} $c: $ind');
            // What is drawn includes a ring (and, on the checkbox tile, the
            // tile's own faint tint as well): enough pixels of 3:1 or more
            // against the page for a line all round the control.
            expect(ind.strong, greaterThan(150), reason: '$c: $ind');
            if (slug == 'good-material' && c == 'alerts') {
              // With highlights on, the tile's own focus tint is drawn as
              // well, and is most of what changes; on Android, where the
              // tests' keys leave highlights off (FL-433), only the ring is.
              expect(ind.ratio, lessThan(1.5), reason: '$c: $ind');
            }
          }
          // And off again: Tab on from the last control, and its region is
          // as it was before it had focus.
          await _tab(tester);
          expect(_stop(tester, slug), isNot(controls.last.$1));
          final off = await _shot(tester);
          final gone = _compare(
            lastBefore!,
            off,
            off,
            _region(tester, byId(_id(slug, controls.last.$1))),
          );
          expect(gone.changed, 0, reason: 'after focus left: $gone');
          handle.dispose();
        });
      }
    }

    testWidgets('bad-indicator-removed: Tab to Save changes no pixel; Tab to '
        'Back, the positive control, does', (tester) async {
      final handle = tester.ensureSemantics();
      await _openForPixels(tester, 'bad-indicator-removed');
      final back = find.byType(BackButton);
      final onBack = await _tabAndMeasure(
        tester,
        'bad-indicator-removed',
        'back',
        () => _region(tester, back),
      );
      debugPrint('V14 bad-indicator-removed back: $onBack');
      expect(onBack.drawn, greaterThan(100), reason: 'Back: $onBack');
      final onSave = await _tabAndMeasure(
        tester,
        'bad-indicator-removed',
        'save',
        () => _region(tester, byId(_id('bad-indicator-removed', 'save'))),
      );
      debugPrint('V14 bad-indicator-removed save: $onSave');
      // Written to fail if a FilledButton starts to show focus some other
      // way than its overlay.
      expect(onSave.changed, 0, reason: 'Save: $onSave');
      expect(onSave.unstable, 0, reason: 'Save: $onSave');
      // Focus is on Save all the same.
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(_lastUsed(tester, 'bad-indicator-removed'), 'Last used: Save');
      handle.dispose();
    });

    for (final brightness in Brightness.values) {
      testWidgets('bad-checkbox-halo (${brightness.name}): the halo is drawn '
          'outside the box and is under 3:1 against the page', (tester) async {
        final handle = tester.ensureSemantics();
        await _openForPixels(
          tester,
          'bad-checkbox-halo',
          brightness: brightness,
        );
        await _tabToBefore(tester, 'bad-checkbox-halo', 'alerts');
        final ind = await _tabAndMeasure(
          tester,
          'bad-checkbox-halo',
          'alerts',
          () => _region(tester, find.byType(Checkbox)),
        );
        debugPrint('V14 bad-checkbox-halo ${brightness.name}: $ind');
        expect(ind.drawn, greaterThan(500), reason: '$ind');
        // The halo is wider than the box (18 pixels): it lies on the page.
        expect(ind.bounds!.width, greaterThan(30), reason: '$ind');
        // Written to fail if Flutter makes the halo stand out: nothing it
        // draws is 3:1 against the page.
        expect(ind.ratio, lessThan(1.5), reason: '$ind');
        expect(ind.strong, lessThan(ind.marks * 0.02), reason: '$ind');
        handle.dispose();
      });

      testWidgets('bad-cupertino-ring (${brightness.name}): the ring is '
          '${brightness == Brightness.light ? 'under' : 'over'} 3:1 against '
          'the page', (tester) async {
        final handle = tester.ensureSemantics();
        await _openForPixels(
          tester,
          'bad-cupertino-ring',
          brightness: brightness,
        );
        await _tabToBefore(tester, 'bad-cupertino-ring', 'save');
        final ind = await _tabAndMeasure(
          tester,
          'bad-cupertino-ring',
          'save',
          () => _region(tester, byId(_id('bad-cupertino-ring', 'save'))),
        );
        debugPrint('V14 bad-cupertino-ring ${brightness.name}: $ind');
        expect(ind.drawn, greaterThan(500), reason: '$ind');
        if (brightness == Brightness.light) {
          // The defect. Written to fail if Flutter darkens the ring.
          expect(ind.ratio, lessThan(3), reason: '$ind');
          expect(ind.strong, lessThan(ind.marks * 0.02), reason: '$ind');
        } else {
          // In dark mode the same ring passes; recorded, not the defect.
          expect(ind.ratio, greaterThanOrEqualTo(3), reason: '$ind');
          expect(ind.strong, greaterThan(150), reason: '$ind');
        }
        handle.dispose();
      });
    }
  });

  group('the focused trail and the notice (2.4.11)', () {
    /// How much of the focused trail is in sight: inside the scrolling box
    /// and not under the notice, as a fraction of its height.
    double visible(WidgetTester tester, String slug, int i) {
      final trail = tester.getRect(byId(_id(slug, 'trail$i')));
      final box = tester.getRect(find.byType(SingleChildScrollView).last);
      final notice = tester.getRect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics && w.properties.identifier == 'v14-$slug-notice',
        ),
      );
      final inBox = trail.intersect(box);
      if (inBox.height <= 0) return 0;
      final under = inBox.intersect(notice);
      final hidden = under.height > 0 && under.width > 0 ? under.height : 0.0;
      return (inBox.height - hidden) / trail.height;
    }

    testWidgets('good-notice-below: every trail Tab reaches is wholly in '
        'sight', (tester) async {
      final handle = tester.ensureSemantics();
      await _openForPixels(tester, 'good-notice-below');
      await _tab(tester);
      for (var i = 1; i <= 6; i++) {
        await _tab(tester);
        expect(_stop(tester, 'good-notice-below'), 'trail$i');
        expect(
          visible(tester, 'good-notice-below', i),
          closeTo(1, 0.01),
          reason: 'trail$i',
        );
      }
      handle.dispose();
    });

    testWidgets('bad-notice-over-list: Tab reaches trails 4 to 6 entirely '
        'under the notice; trails 1 and 2 are in sight', (tester) async {
      final handle = tester.ensureSemantics();
      await _openForPixels(tester, 'bad-notice-over-list');
      await _tab(tester);
      final seen = <double>[];
      for (var i = 1; i <= 6; i++) {
        await _tab(tester);
        expect(_stop(tester, 'bad-notice-over-list'), 'trail$i');
        seen.add(visible(tester, 'bad-notice-over-list', i));
      }
      debugPrint('V14 bad-notice-over-list visible: $seen');
      // The positive control, through the same measure: the first two are
      // in sight.
      expect(seen[0], closeTo(1, 0.01));
      expect(seen[1], closeTo(1, 0.01));
      // The defect. Written to fail if Flutter starts to scroll a focused
      // control out from under what is drawn over its view.
      for (final i in [4, 5, 6]) {
        expect(seen[i - 1], 0, reason: 'trail$i is entirely hidden');
      }
      handle.dispose();
    });

    testWidgets('bad-notice-over-list: what is on the screen where the '
        'focused trail is, is the notice', (tester) async {
      await _openForPixels(tester, 'bad-notice-over-list');
      for (var i = 0; i < 7; i++) {
        await _tab(tester);
      }
      // Focus is on trail 6 (the test above names every stop).
      final shot = await _shot(tester);
      final trail = tester.getRect(byId(_id('bad-notice-over-list', 'trail6')));
      final notice = tester.getRect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.identifier == 'v14-bad-notice-over-list-notice',
        ),
      );
      expect(
        notice.contains(trail.topLeft) &&
            notice.contains(trail.bottomRight - const Offset(1, 1)),
        isTrue,
      );
      final colours = <int>{};
      for (var y = trail.top.ceil(); y < trail.bottom.floor(); y++) {
        for (var x = trail.left.ceil(); x < trail.right.floor(); x++) {
          colours.add(shot.at(x, y));
        }
      }
      // The notice's background and its text, and nothing of the trail's
      // ring or label: compare with the notice drawn where no trail is.
      final noticeColours = <int>{};
      for (var y = notice.top.ceil(); y < notice.bottom.floor(); y++) {
        for (var x = notice.left.ceil(); x < notice.right.floor(); x++) {
          noticeColours.add(shot.at(x, y));
        }
      }
      expect(colours.difference(noticeColours), isEmpty);
      final ring = Theme.of(
        tester.element(byId(_id('bad-notice-over-list', 'trail6'))),
      ).colorScheme.onSurface;
      expect(colours.contains(ring.toARGB32() & 0xFFFFFF), isFalse);
    });

    testWidgets('a pinned header in the same scrolling view is allowed for: '
        'Shift+Tab up a list under a pinned SliverAppBar keeps each button '
        'in sight', (tester) async {
      final keys = [for (var i = 0; i < 12; i++) GlobalKey()];
      final view = GlobalKey();
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              key: view,
              slivers: [
                const SliverAppBar(pinned: true, title: Text('Header')),
                SliverList.list(
                  children: [
                    for (var i = 0; i < 12; i++)
                      SizedBox(
                        height: 48,
                        child: TextButton(
                          key: keys[i],
                          onPressed: () {},
                          child: Text('B$i'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      for (var i = 0; i < 12; i++) {
        await _tab(tester);
      }
      final header = tester.getRect(find.byType(AppBar));
      for (var i = 10; i >= 0; i--) {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pumpAndSettle();
        final b = tester.getRect(find.byKey(keys[i]));
        expect(b.top, greaterThanOrEqualTo(header.bottom - 0.5), reason: 'B$i');
      }
    });
  });

  group('the highlight mode', () {
    // Flutter shows most indicators only while the last input was a key
    // (FocusManager.highlightMode): a touch hides them with focus where it
    // was, and the next key brings them back.
    testWidgets('good-widgets: a touch hides the ring with focus kept, and '
        'a key brings it back', (tester) async {
      final handle = tester.ensureSemantics();
      await _openForPixels(tester, 'good-widgets');
      final control = byId(_id('good-widgets', 'trail'));
      await _tabToBefore(tester, 'good-widgets', 'trail');
      final ind = await _tabAndMeasure(
        tester,
        'good-widgets',
        'trail',
        () => _region(tester, control),
      );
      expect(ind.drawn, greaterThan(150));
      final focused = await _shot(tester);
      // A touch on an empty part of the screen.
      await tester.tapAt(const Offset(790, 990));
      await tester.pumpAndSettle();
      expect(FocusManager.instance.highlightMode, FocusHighlightMode.touch);
      expect(_stop(tester, 'good-widgets'), 'trail');
      final touched = await _shot(tester);
      final hidden = _compare(
        focused,
        touched,
        touched,
        _region(tester, control),
      );
      expect(
        hidden.changed,
        greaterThan(150),
        reason: 'the ring went: $hidden',
      );
      // Any key, here Shift alone, switches back to the keyboard's mode.
      await tester.sendKeyEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(
        FocusManager.instance.highlightMode,
        FocusHighlightMode.traditional,
      );
      final back = await _shot(tester);
      final again = _compare(focused, back, back, _region(tester, control));
      expect(again.changed, 0, reason: 'the ring is back as it was: $again');
      handle.dispose();
    });
  });
}
