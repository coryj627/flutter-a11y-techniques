import 'dart:convert';
import 'dart:io';
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
/// that changed in both captures and is the same in both. Its contrast is
/// taken against the colours next to it in the focused capture (see
/// [_compare]), never from the theme. The other layers do the same with the
/// platform's own screenshots.
final _open = exampleOpener(v14FocusIndicators);

const _good = [
  'good-material',
  'good-cupertino',
  'good-widgets',
  'good-notice-below',
];
const _bad = [
  'bad-indicator-removed',
  'bad-checked-checkbox',
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
  'bad-checked-checkbox': [('alerts', 'Weather alerts')],
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

/// A capture of the screen, or a picture made up for a test of the measure.
class _Shot {
  _Shot(this.width, this.height, this.at);

  /// A capture as RGBA bytes.
  factory _Shot.rgba(ByteData bytes, int width, int height) =>
      _Shot(width, height, (x, y) {
        final o = (y * width + x) * 4;
        return bytes.getUint8(o) << 16 |
            bytes.getUint8(o + 1) << 8 |
            bytes.getUint8(o + 2);
      });

  final int width;
  final int height;

  /// The colour at (x, y), as 0xRRGGBB.
  final int Function(int x, int y) at;
}

Future<_Shot> _shot(WidgetTester tester) async {
  final view = tester.binding.renderViews.first;
  final layer = view.debugLayer! as OffsetLayer;
  final ui.Image image = await layer.toImage(Offset.zero & view.size);
  final bytes = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  );
  final shot = _Shot.rgba(bytes!, image.width, image.height);
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

/// One band of what focus drew: a connected area of one flat colour (or of
/// shades each within [_flat] of the next), drawn mostly where the page was
/// before focus or mostly on the control.
class _Band {
  _Band(
    this.colour,
    this.onPage,
    this.pixels,
    this.contrast,
    this.lowest,
    this.next,
  );

  /// Its commonest colour.
  final int colour;
  final bool onPage;
  final int pixels;

  /// Its contrast: the lowest against any neighbour it must contrast with
  /// (see [_compare]).
  final double contrast;

  /// The neighbour that gave [contrast].
  final int lowest;

  /// Its commonest neighbours, by how many of its edge's pixels touch
  /// them, with their counts.
  final List<(int, int)> next;

  @override
  String toString() {
    final total = next.fold(0, (s, n) => s + n.$2);
    return '$pixels px ${_hex(colour)} '
        '${onPage ? 'on the page' : 'on the control'} '
        '${contrast.toStringAsFixed(2)} against ${_hex(lowest)}; next to it '
        '${next.take(2).map((n) => '${_hex(n.$1)} ${_ratio(colour, n.$1).toStringAsFixed(2)} ${100 * n.$2 ~/ math.max(total, 1)}%').join(', ')}';
  }
}

/// What focus drew in a region.
class _Indicator {
  _Indicator({
    required this.changed,
    required this.unstable,
    required this.swapped,
    required this.strong,
    required this.page,
    required this.bands,
  });

  /// Pixels that differ from before focus in both captures, and agree.
  final int changed;

  /// Pixels that differ in one capture only, or between the two.
  final int unstable;

  /// How many of the changed pixels' new colours are their old colours
  /// elsewhere: what moving the same drawing would give.
  final int swapped;

  /// Every changed pixel, whatever it replaced: what focus drew.
  int get indicator => changed;

  /// Indicator pixels in bands of 3:1 or more against every neighbour they
  /// must contrast with.
  final int strong;

  /// The page's colour: the commonest along the edge of the region, before
  /// focus.
  final int page;

  /// The bands of what was drawn, largest first.
  final List<_Band> bands;

  /// Indicator pixels in bands: all but anti-aliased edges.
  int get flat => bands.fold(0, (s, b) => s + b.pixels);

  /// Whether the drawing moved rather than focus adding to it: half or more
  /// of the colours the changed pixels took were there before, among the
  /// changed pixels, and went (a shifted label, icon, or edge).
  bool get moved => changed > 0 && swapped * 2 >= changed;

  /// The largest band's contrast, or 1 if nothing was drawn.
  double get ratio => bands.isEmpty ? 1 : bands.first.contrast;

  @override
  String toString() =>
      'changed $changed, unstable $unstable, swapped $swapped, '
      'indicator $changed, in bands $flat, 3:1 or more: $strong, '
      'page ${_hex(page)}; ${bands.take(3).join('; ')}';
}

/// A change of a channel by this much or less is no change.
const _threshold = 12;

/// Two colours are one flat colour if no channel differs by more than this.
const _flat = 4;

/// An anti-aliased edge is read across at most this many pixels.
const _blur = 4;

/// How many strong pixels, at a device pixel ratio of 1, a good control's
/// indicator must have in these tests: about a line one pixel wide round a
/// 40 by 40 control. This is the tests' own threshold, kept apart from the
/// contrast measure: 1.4.11 sets no size (2.4.13, AAA, does).
const _ourMinimum = 150;

/// What focus drew in [region], given the capture before focus [u] and two
/// after it, [f1] and [f2]. The measure of the V14 spec, section 6, which
/// lists what it is known not to do.
///
/// A pixel has changed if it differs from [u] in both and [f1] and [f2]
/// agree. Every changed pixel is part of the indicator, whatever it
/// replaced: Understanding 1.4.11 does not compare the focused and
/// unfocused states. (What replaced what is used once, to tell a drawing
/// that moved from one that focus added to: see [_Indicator.moved].)
///
/// A pixel of [f1] is solid if it has a 4-neighbour of its colour (within
/// [_flat]) and is not anti-aliasing: a pixel whose colour lies between the
/// colours either side of it, across or down or on a diagonal, where those
/// two differ. A one pixel line is solid. Solid changed pixels are joined
/// into bands: 4-connected, each within [_flat] of the next. A band is on
/// the page if most of it was drawn where the page was before focus, and
/// on the control if not.
///
/// Each band is taken against its neighbours, spatially: from every pixel
/// on its edge, outward, across pixels of the edge pixel's own colour and
/// at most [_blur] pixels of an anti-aliased edge being crossed (each
/// between the pixels before and after it on the way), to the first solid
/// pixel (or the last of those [_blur], so that no neighbour is passed over
/// for being blurred, unless focus drew it). A walk that meets a blurred
/// pixel that is not between them, but is a blend some other way, is going
/// along an edge, not across it, and finds nothing; a blurred pixel that
/// is a blend no way is texture (a dither), and is the neighbour. A band on the control, inside it
/// or on its border, must contrast with every neighbour found, whatever it
/// is (Understanding: both adjacent colours). A band on the page, outside
/// the control, must contrast with the background: the walk goes on across
/// the rest of what focus drew, and a neighbour that was not the page
/// before focus (the control itself) is not one it must contrast with. A
/// band's
/// contrast is its lowest against any of them (with none, against the
/// page): the least contrasting part decides. Its pixels are strong if that
/// is 3:1 or more. The page's colour is the commonest along the region's
/// top and bottom edges in [u].
_Indicator _compare(_Shot u, _Shot f1, _Shot f2, Rect region) {
  final l = math.max(0, region.left.floor());
  final t = math.max(0, region.top.floor());
  final r = math.min(u.width, region.right.ceil());
  final b = math.min(u.height, region.bottom.ceil());
  final w = r - l, h = b - t;
  bool inside(int x, int y) => x >= l && x < r && y >= t && y < b;
  int at(int x, int y) => (y - t) * w + (x - l);
  final edge = <int, int>{};
  for (var x = l; x < r; x++) {
    for (final y in [t, t + 1, b - 2, b - 1]) {
      edge.update(u.at(x, y), (n) => n + 1, ifAbsent: () => 1);
    }
  }
  var page = 0, most = -1;
  for (final MapEntry(key: c, value: n) in edge.entries) {
    if (n > most || (n == most && c < page)) (page, most) = (c, n);
  }
  final isChanged = List<bool>.filled(w * h, false);
  var changed = 0, unstable = 0;
  final newColours = <int, int>{}, oldColours = <int, int>{};
  for (var y = t; y < b; y++) {
    for (var x = l; x < r; x++) {
      final a = u.at(x, y), p = f1.at(x, y), q = f2.at(x, y);
      final d1 = _channelDiff(a, p) > _threshold;
      final d2 = _channelDiff(a, q) > _threshold;
      if (d1 && d2 && _channelDiff(p, q) <= _threshold) {
        changed++;
        isChanged[at(x, y)] = true;
        newColours.update(p, (n) => n + 1, ifAbsent: () => 1);
        oldColours.update(a, (n) => n + 1, ifAbsent: () => 1);
      } else if (d1 || d2) {
        unstable++;
      }
    }
  }
  bool same(int x, int y, int c) =>
      inside(x, y) && _channelDiff(f1.at(x, y), c) <= _flat;
  bool between(int c, int a, int b) {
    for (final s in [16, 8, 0]) {
      final v = (c >> s) & 255, p = (a >> s) & 255, q = (b >> s) & 255;
      if (v < math.min(p, q) - _flat || v > math.max(p, q) + _flat) {
        return false;
      }
    }
    return true;
  }

  /// Whether (x, y) lies between the pixels either side of it along
  /// (dx, dy): a pixel of an anti-aliased edge crossed that way.
  bool blendAlong(int x, int y, int dx, int dy) {
    if (!inside(x - dx, y - dy) || !inside(x + dx, y + dy)) return false;
    final c = f1.at(x, y);
    final a = f1.at(x - dx, y - dy), z = f1.at(x + dx, y + dy);
    return _channelDiff(a, z) > _threshold &&
        _channelDiff(c, a) > _flat &&
        _channelDiff(c, z) > _flat &&
        between(c, a, z);
  }

  bool blend(int x, int y) =>
      blendAlong(x, y, 1, 0) ||
      blendAlong(x, y, 0, 1) ||
      blendAlong(x, y, 1, 1) ||
      blendAlong(x, y, 1, -1);

  final solidAt = List<bool>.filled(w * h, false);
  for (var y = t; y < b; y++) {
    for (var x = l; x < r; x++) {
      final c = f1.at(x, y);
      solidAt[at(x, y)] =
          (same(x - 1, y, c) ||
              same(x + 1, y, c) ||
              same(x, y - 1, c) ||
              same(x, y + 1, c)) &&
          !blend(x, y);
    }
  }
  bool onPageAt(int x, int y) => _channelDiff(u.at(x, y), page) <= _threshold;

  const steps = [(1, 0), (-1, 0), (0, 1), (0, -1)];
  final bandOf = List<int>.filled(w * h, -1);

  /// The neighbour of the edge pixel (x, y) of band [id] in the direction
  /// (dx, dy), or null if the walk finds none it must contrast with.
  int? neighbour(int x, int y, int dx, int dy, bool onPage, int id) {
    final c0 = f1.at(x, y);
    // How thick the band is here, along the way.
    var thick = 0;
    for (
      var bx = x, by = y;
      inside(bx, by) && bandOf[at(bx, by)] == id;
      bx -= dx, by -= dy
    ) {
      thick++;
    }
    var same = 0, blurred = 0;
    while (true) {
      x += dx;
      y += dy;
      if (!inside(x, y)) return null;
      final i = at(x, y);
      final c = f1.at(x, y);
      // The band itself, or a pixel of its colour that focus also drew.
      if (bandOf[i] == id) continue;
      if (isChanged[i] && _channelDiff(c, c0) <= _flat) continue;
      // On the page, the rest of what focus drew is crossed: the band is
      // taken against the background.
      if (onPage && isChanged[i]) continue;
      final ours = !(onPage && !onPageAt(x, y));
      if (!isChanged[i] && c == c0) {
        // A run of exactly the band's colour that was there before, no
        // wider than the band: the same shape made thicker. A wider one is
        // a neighbour, at 1:1.
        if (++same <= thick) continue;
        return ours ? c : null;
      }
      if (solidAt[i]) return ours ? c : null;
      if (!blendAlong(x, y, dx, dy)) {
        // A blend some other way is the side of an anti-aliased edge that
        // runs along the way, not one being crossed: the neighbour beyond
        // it is found by the walks that cross it.
        if (blend(x, y)) return null;
        // A blend no way is texture (a dither, a pattern), not
        // anti-aliasing: it is the neighbour.
        return ours ? c : null;
      }
      // Blurred all the way: what is there is the neighbour, unless focus
      // drew it (the indicator's own anti-aliased edge is not a neighbour
      // of it).
      if (++blurred == _blur) return ours && !isChanged[i] ? c : null;
    }
  }

  final bands = <(_Band, int)>[];
  var strong = 0;
  for (var y0 = t; y0 < b; y0++) {
    for (var x0 = l; x0 < r; x0++) {
      final i0 = at(x0, y0);
      if (!isChanged[i0] || !solidAt[i0] || bandOf[i0] >= 0) continue;
      final id = bands.length;
      final pixels = <(int, int)>[(x0, y0)];
      bandOf[i0] = id;
      for (var k = 0; k < pixels.length; k++) {
        final (x, y) = pixels[k];
        for (final (dx, dy) in steps) {
          final nx = x + dx, ny = y + dy;
          if (!inside(nx, ny)) continue;
          final j = at(nx, ny);
          if (!isChanged[j] || !solidAt[j] || bandOf[j] >= 0) continue;
          if (_channelDiff(f1.at(nx, ny), f1.at(x, y)) > _flat) continue;
          bandOf[j] = id;
          pixels.add((nx, ny));
        }
      }
      final onPage =
          pixels.where((p) => onPageAt(p.$1, p.$2)).length * 2 > pixels.length;
      var contrast = double.infinity, lowest = page;
      final next = <int, int>{};
      for (final (x, y) in pixels) {
        for (final (dx, dy) in steps) {
          if (inside(x + dx, y + dy) && bandOf[at(x + dx, y + dy)] == id) {
            continue;
          }
          final n = neighbour(x, y, dx, dy, onPage, id);
          if (n == null) continue;
          next.update(n, (k) => k + 1, ifAbsent: () => 1);
          final c = _ratio(f1.at(x, y), n);
          if (c < contrast) (contrast, lowest) = (c, n);
        }
      }
      final counts = <int, int>{};
      for (final (x, y) in pixels) {
        counts.update(f1.at(x, y), (n) => n + 1, ifAbsent: () => 1);
      }
      var colour = 0, top = -1;
      for (final MapEntry(key: c, value: n) in counts.entries) {
        if (n > top || (n == top && c < colour)) (colour, top) = (c, n);
      }
      if (next.isEmpty) {
        // Nothing found to measure against: on the page, the page; on the
        // control, the measure is inconclusive and the band is not strong.
        (contrast, lowest) = onPage
            ? (_ratio(colour, page), page)
            : (1, colour);
      }
      if (contrast >= 3) strong += pixels.length;
      final sorted = next.entries.toList()
        ..sort(
          (p, q) => q.value != p.value ? q.value - p.value : p.key - q.key,
        );
      bands.add((
        _Band(colour, onPage, pixels.length, contrast, lowest, [
          for (final e in sorted.take(3)) (e.key, e.value),
        ]),
        id,
      ));
    }
  }
  bands.sort(
    (p, q) =>
        q.$1.pixels != p.$1.pixels ? q.$1.pixels - p.$1.pixels : p.$2 - q.$2,
  );
  var swapped = 0;
  for (final MapEntry(key: c, value: n) in newColours.entries) {
    swapped += math.min(n, oldColours[c] ?? 0);
  }
  return _Indicator(
    changed: changed,
    unstable: unstable,
    swapped: swapped,
    strong: strong,
    page: page,
    bands: [for (final (band, _) in bands) band],
  );
}

/// The area looked at round a control: its rectangle and 8 pixels more on
/// every side, which is where a ring drawn outside it lies.
Rect _region(Rect control) => control.inflate(8);

/// The measure's cases, shared with the other layers.
const _casesFile = 'test/techniques/v14_focus_indicators_measure_cases.json';
const _androidFile =
    'android/app/src/androidTest/kotlin/dev/fluttera11y/'
    'flutter_a11y_techniques/V14FocusIndicatorsTest.kt';

int _colour(dynamic hex) => int.parse((hex as String).substring(1), radix: 16);

/// A case's picture, its [layers] painted in order on white at pixel ratio
/// [s] (the case file says how).
_Shot _paint(List<dynamic> layers, int width, int height, int s) {
  final px = List<int>.filled(width * height, 0xFFFFFF);
  for (final layer in layers.cast<Map<String, dynamic>>()) {
    final rect = [
      for (final v in (layer['rect'] as List<dynamic>? ?? [0, 0, 0, 0]))
        (v as int) * s,
    ];
    final (l, t) = layer.containsKey('rect') ? (rect[0], rect[1]) : (0, 0);
    final (r, b) = layer.containsKey('rect')
        ? (rect[2], rect[3])
        : (width, height);
    final ring = ((layer['ring'] as int?) ?? 0) * s;
    for (var y = t; y < b; y++) {
      for (var x = l; x < r; x++) {
        if (ring > 0 &&
            x >= l + ring &&
            x < r - ring &&
            y >= t + ring &&
            y < b - ring) {
          continue;
        }
        final along = layer['axis'] == 'y' ? y - t : x - l;
        final length = layer['axis'] == 'y' ? b - t : r - l;
        int c;
        if (layer['checker'] case final List<dynamic> pair) {
          final period = (layer['period'] as int) * s;
          c = _colour(pair[((x - l) ~/ period + (y - t) ~/ period) % 2]);
        } else if (layer['stripes'] case final List<dynamic> stripes) {
          final period = (layer['period'] as int) * s;
          c = _colour(stripes[(along ~/ period) % stripes.length]);
        } else if (layer['gradient'] case final List<dynamic> ends) {
          final a = _colour(ends[0]), z = _colour(ends[1]);
          final n = length - 1;
          c = 0;
          for (final sh in [16, 8, 0]) {
            final v =
                (((a >> sh) & 255) * (n - along) +
                    ((z >> sh) & 255) * along +
                    n ~/ 2) ~/
                n;
            c |= v << sh;
          }
        } else {
          c = _colour(layer['colour'] ?? layer['fill']);
        }
        px[y * width + x] = c;
      }
    }
  }
  return _Shot(width, height, (x, y) => px[y * width + x]);
}

/// What a case's measure at pixel ratio [s] gets wrong: none, if it passes.
List<String> _checkCase(Map<String, dynamic> c, int s) {
  final size = (c['size'] as List<dynamic>).cast<int>();
  final w = size[0] * s, h = size[1] * s;
  final u = _paint(c['before'] as List<dynamic>, w, h, s);
  final f1 = _paint(c['after'] as List<dynamic>, w, h, s);
  final f2 = c.containsKey('after2')
      ? _paint(c['after2'] as List<dynamic>, w, h, s)
      : f1;
  final ind = _compare(u, f1, f2, Rect.fromLTWH(0, 0, w * 1.0, h * 1.0));
  final e = c['expect'] as Map<String, dynamic>;
  final problems = <String>[];
  void want(bool ok, String what) {
    if (!ok) problems.add('$what: $ind');
  }

  bool some(String v, int n) => v == 'none' ? n == 0 : n > 0;
  if (e['changed'] case final String v) {
    want(some(v, ind.changed), 'changed $v');
  }
  if (e['unstable'] case final String v) {
    want(some(v, ind.unstable), 'unstable $v');
  }
  if (e['moved'] case final bool v) want(ind.moved == v, 'moved $v');
  switch (e['strong']) {
    case 'all':
      want(ind.flat > 0 && ind.strong == ind.flat, 'strong all');
    case 'none':
      want(ind.strong == 0, 'strong none');
    case 'some':
      want(ind.strong > 0 && ind.strong < ind.flat, 'strong some');
  }
  if (e['strongPixels'] case final int n) {
    want(ind.strong == n * s * s, 'strong pixels ${n * s * s}');
  }
  if (e['ratio'] case [final num v, final num tolerance]) {
    want((ind.ratio - v).abs() <= tolerance, 'ratio $v');
  }
  if (e['ratioBelow'] case final num v) want(ind.ratio < v, 'ratio below $v');
  if (e['onPage'] case final bool v) {
    want(ind.bands.isNotEmpty && ind.bands.first.onPage == v, 'on the page $v');
  }
  return problems;
}

/// Brings [control] wholly into view, captures the screen, presses Tab,
/// checks that the stop is [stop] and that the control has not moved, and
/// captures it twice more, 700 ms apart; returns what changed round it. A
/// control that moved (scrolled into view by Tab, say) would show its own
/// drawing moved as a change, so the test fails instead.
Future<_Indicator> _tabAndMeasure(
  WidgetTester tester,
  String slug,
  String stop,
  Finder control,
) async {
  await tester.ensureVisible(control);
  await tester.pumpAndSettle();
  final where = tester.getRect(control);
  final before = await _shot(tester);
  await _tab(tester);
  expect(_stop(tester, slug), stop, reason: 'Tab stops on $stop');
  expect(tester.getRect(control), where, reason: '$stop did not move');
  final f1 = await _shot(tester);
  await tester.pump(const Duration(milliseconds: 700));
  final f2 = await _shot(tester);
  final ind = _compare(before, f1, f2, _region(where));
  expect(ind.moved, isFalse, reason: 'the drawing moved: $ind');
  return ind;
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

  // The measure itself, on the cases of
  // v14_focus_indicators_measure_cases.json, which the web spec, the iOS
  // UI tests, and the probe analyser read too, and the Android test holds
  // a copy of: among them the pass and fail figures of Understanding
  // 1.4.11's section on focus indicators, the first review's reproductions,
  // and the measure's known limits.
  group('the measure', () {
    final cases =
        (jsonDecode(File(_casesFile).readAsStringSync())
                as Map<String, dynamic>)['cases']
            as List<dynamic>;
    for (final c in cases.cast<Map<String, dynamic>>()) {
      for (final s in (c['scales'] as List<dynamic>).cast<int>()) {
        test('${c['name']} (pixel ratio $s)', () {
          expect(_checkCase(c, s), isEmpty);
        });
      }
    }

    test('the Android test holds the same cases', () {
      final kotlin = File(_androidFile).readAsStringSync();
      final from = kotlin.indexOf('CASES = """') + 'CASES = """'.length;
      final to = kotlin.indexOf('"""', from);
      expect(
        kotlin.substring(from, to).trim(),
        File(_casesFile).readAsStringSync().trim(),
      );
    });
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
          // An IconButton's name is its tooltip.
          expect(data.label.isEmpty ? data.tooltip : data.label, name);
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
      ('bad-checked-checkbox', 'alerts', 'checked checkbox'),
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
          case 'checked checkbox':
            expect(flags.isChecked, CheckedState.isTrue);
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
    // Every good control: Tab draws a band of 3:1 or more against what it
    // must contrast with, of the tests' minimum size, in light and dark;
    // and it goes when Tab moves on.
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
            lastBefore = await _shot(tester);
            final ind = await _tabAndMeasure(
              tester,
              slug,
              c,
              byId(_id(slug, c)),
            );
            debugPrint('V14 $slug ${brightness.name} $c: $ind');
            // What is drawn includes a ring (and, on the checkbox tile, the
            // tile's own faint tint as well): enough pixels of 3:1 or more
            // against what is next to them for a line all round the
            // control.
            expect(ind.strong, greaterThan(_ourMinimum), reason: '$c: $ind');
            if (slug == 'good-material' && c == 'alerts') {
              // With highlights on, the tile's own focus tint is drawn as
              // well, and is most of what changes. With highlights off, as
              // after a key from Android's virtual keyboard (FL-433), only
              // the ring would be.
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
            _region(tester.getRect(byId(_id(slug, controls.last.$1)))),
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
        back,
      );
      debugPrint('V14 bad-indicator-removed back: $onBack');
      expect(onBack.indicator, greaterThan(100), reason: 'Back: $onBack');
      final onSave = await _tabAndMeasure(
        tester,
        'bad-indicator-removed',
        'save',
        byId(_id('bad-indicator-removed', 'save')),
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
      testWidgets('bad-checked-checkbox (${brightness.name}): the halo is '
          'drawn on the page, under 3:1 against it, and nothing else changes', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _openForPixels(
          tester,
          'bad-checked-checkbox',
          brightness: brightness,
        );
        await _tabToBefore(tester, 'bad-checked-checkbox', 'alerts');
        final ind = await _tabAndMeasure(
          tester,
          'bad-checked-checkbox',
          'alerts',
          find.byType(Checkbox),
        );
        debugPrint('V14 bad-checked-checkbox ${brightness.name}: $ind');
        expect(ind.indicator, greaterThan(500), reason: '$ind');
        // The halo is drawn where the page was, round the box.
        expect(ind.bands.first.onPage, isTrue, reason: '$ind');
        // Written to fail if Flutter makes the halo stand out, or adds
        // anything else at 3:1 (as it does, a darker border, when the box
        // is not checked: the test below).
        expect(ind.ratio, lessThan(1.5), reason: '$ind');
        expect(ind.strong, lessThan(ind.indicator * 0.02), reason: '$ind');
        handle.dispose();
      });

      testWidgets('a Checkbox that is not checked (${brightness.name}): its '
          'border, darker with focus, is 3:1 or more against the halo next '
          'to it', (tester) async {
        var value = false;
        tester.view.physicalSize = const Size(400, 400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(colorSchemeSeed: Colors.indigo),
            darkTheme: ThemeData(
              colorSchemeSeed: Colors.indigo,
              brightness: Brightness.dark,
            ),
            themeMode: brightness == Brightness.light
                ? ThemeMode.light
                : ThemeMode.dark,
            home: Scaffold(
              body: Center(
                child: StatefulBuilder(
                  builder: (context, set) => Checkbox(
                    value: value,
                    onChanged: (v) => set(() => value = v!),
                  ),
                ),
              ),
            ),
          ),
        );
        final box = find.byType(Checkbox);
        final where = tester.getRect(box);
        final before = await _shot(tester);
        await _tab(tester);
        final f1 = await _shot(tester);
        await tester.pump(const Duration(milliseconds: 700));
        final f2 = await _shot(tester);
        expect(tester.getRect(box), where);
        final ind = _compare(before, f1, f2, _region(where));
        debugPrint('V14 unchecked Checkbox ${brightness.name}: $ind');
        expect(ind.moved, isFalse, reason: '$ind');
        // The halo is still the largest band, under 3:1 on the page ...
        expect(ind.bands.first.onPage, isTrue, reason: '$ind');
        expect(ind.ratio, lessThan(1.5), reason: '$ind');
        // ... and the border, on the control, is 3:1 or more against what
        // is next to it: 1.4.11 is met as written (FL-434).
        final border = ind.bands.where((b) => !b.onPage && b.contrast >= 3);
        expect(border, isNotEmpty, reason: '$ind');
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
          byId(_id('bad-cupertino-ring', 'save')),
        );
        debugPrint('V14 bad-cupertino-ring ${brightness.name}: $ind');
        expect(ind.indicator, greaterThan(500), reason: '$ind');
        expect(ind.bands.first.onPage, isTrue, reason: '$ind');
        if (brightness == Brightness.light) {
          // The defect. Written to fail if Flutter darkens the ring, or
          // adds anything else at 3:1.
          expect(ind.ratio, lessThan(3), reason: '$ind');
          expect(ind.strong, lessThan(ind.indicator * 0.02), reason: '$ind');
        } else {
          // In dark mode the same ring passes; recorded, not the defect.
          expect(ind.ratio, greaterThanOrEqualTo(3), reason: '$ind');
          expect(ind.strong, greaterThan(_ourMinimum), reason: '$ind');
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
        control,
      );
      expect(ind.strong, greaterThan(_ourMinimum));
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
        _region(tester.getRect(control)),
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
      final again = _compare(
        focused,
        back,
        back,
        _region(tester.getRect(control)),
      );
      expect(again.changed, 0, reason: 'the ring is back as it was: $again');
      handle.dispose();
    });
  });
}
