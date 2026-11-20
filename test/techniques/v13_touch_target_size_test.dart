import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/v13_touch_target_size/v13_touch_target_size.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/examples.dart';

/// L1 for V13 Minimum touch target size
/// (docs/specs/V13-touch-target-size.md).
final _open = exampleOpener(v13TouchTargetSize);

const _good = ['good-material', 'good-cupertino', 'good-custom'];
const _link = 'good-inline-link';
const _bad = [
  'bad-shrinkwrap',
  'bad-zero-padding-web',
  'bad-cupertino-small',
  'bad-custom-small',
];
const _all = [..._good, _link, ..._bad];

const _names = {'previous': 'Previous', 'play': 'Play', 'next': 'Next'};

/// The test ids of the controls of [slug].
List<String> _ids(String slug) => slug == _link
    ? ['v13-$_link-rules']
    : [for (final c in _names.keys) 'v13-$slug-$c'];

/// What each control measures, in logical pixels, with Flutter's platform
/// Android, as the widget tests open the app. iOS is the same (the probe,
/// docs/evidence/probes/v13/).
const _size = {
  'good-material': Size(48, 48),
  'good-cupertino': Size(48, 48),
  'good-custom': Size(48, 48),
  'bad-shrinkwrap': Size(18, 18),
  'bad-zero-padding-web': Size(48, 48),
  'bad-cupertino-small': Size(18, 18),
  'bad-custom-small': Size(18, 18),
};

/// WCAG 2.5.8's minimum, in CSS pixels, which are Flutter's logical pixels
/// on the web (docs/evidence/probes/v13/README.md).
const _minimum = 24.0;

/// The rect of [node] in logical pixels from the top left of the view,
/// through every transform: what androidTapTargetGuideline reads, and what
/// each platform's accessibility tree reports (the probe).
Rect _nodeRect(WidgetTester tester, SemanticsNode node) {
  var rect = node.rect;
  SemanticsNode? current = node;
  while (current != null) {
    final t = current.transform;
    if (t != null) rect = MatrixUtils.transformRect(t, rect);
    current = current.parent;
  }
  final dpr = tester.view.devicePixelRatio;
  return Rect.fromLTRB(
    rect.left / dpr,
    rect.top / dpr,
    rect.right / dpr,
    rect.bottom / dpr,
  );
}

Rect _rectOf(WidgetTester tester, String id) =>
    _nodeRect(tester, nodeById(id).evaluate().single);

/// The targets that fail WCAG 2.5.8 among [targets], each with why: an
/// undersized target (one that cannot hold a 24 by 24 square) passes only if
/// a circle 24 across, centred on it, meets no other target and no other
/// undersized target's circle (the spacing exception). Touching is not
/// meeting. The other exceptions are judged by hand in the spec.
List<String> wcag258Failures(Map<String, Rect> targets) {
  bool undersized(Rect r) => r.width < _minimum || r.height < _minimum;
  final failures = <String>[];
  for (final MapEntry(key: id, value: rect) in targets.entries) {
    if (!undersized(rect)) continue;
    final centre = rect.center;
    for (final MapEntry(key: other, value: o) in targets.entries) {
      if (other == id) continue;
      final nearest = Offset(
        centre.dx.clamp(o.left, o.right),
        centre.dy.clamp(o.top, o.bottom),
      );
      if ((nearest - centre).distance < _minimum / 2) {
        failures.add('$id: its circle meets $other');
      } else if (undersized(o) && (o.center - centre).distance < _minimum) {
        failures.add('$id: its circle meets the circle of $other');
      }
    }
  }
  return failures;
}

int _count(WidgetTester tester, String slug) =>
    countOf(tester, 'v13-$slug-count');

/// Taps at [point], and returns how many presses it gave.
Future<int> _tapAt(WidgetTester tester, String slug, Offset point) async {
  final before = _count(tester, slug);
  await tester.tapAt(point);
  await tester.pumpAndSettle();
  return _count(tester, slug) - before;
}

/// A tap at [point] that must do nothing, followed by the positive control:
/// a tap at the centre of [id], which must press it once.
Future<void> _expectNothingAt(
  WidgetTester tester,
  String slug,
  String id,
  Offset point,
  String what,
) async {
  expect(await _tapAt(tester, slug, point), 0, reason: '$id: $what');
  expect(
    await _tapAt(tester, slug, _rectOf(tester, id).center),
    1,
    reason: '$id: the tap at its centre after $what',
  );
}

/// Runs [body] with Flutter's platform set to [platform], as a web build is
/// in a browser on that operating system.
Future<void> _asPlatform(
  TargetPlatform platform,
  Future<void> Function() body,
) async {
  debugDefaultTargetPlatformOverride = platform;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

void main() {
  test('the technique has the examples named in the spec', () {
    expect(v13TouchTargetSize.examples.map((e) => e.slug), _all);
    expect(
      [..._good, _link],
      [
        for (final e in v13TouchTargetSize.examples)
          if (e.kind == ExampleKind.good) e.slug,
      ],
    );
  });

  group('the 2.5.8 check used by these tests', () {
    test('a 20 pixel target alone passes by its spacing', () {
      expect(
        wcag258Failures({'a': const Rect.fromLTWH(100, 100, 20, 20)}),
        isEmpty,
      );
      // 13 pixels from the next target's edge: its circle, 12 from its
      // centre and so 2 beyond its edge, does not reach.
      expect(
        wcag258Failures({
          'a': const Rect.fromLTWH(100, 100, 20, 20),
          'b': const Rect.fromLTWH(133, 100, 48, 48),
        }),
        isEmpty,
      );
    });

    test('two 20 pixel targets 2 apart fail, and 24 by 24 needs no space', () {
      expect(
        wcag258Failures({
          'a': const Rect.fromLTWH(100, 100, 20, 20),
          'b': const Rect.fromLTWH(122, 100, 20, 20),
        }),
        hasLength(2),
      );
      expect(
        wcag258Failures({
          'a': const Rect.fromLTWH(100, 100, 24, 24),
          'b': const Rect.fromLTWH(124, 100, 24, 24),
        }),
        isEmpty,
      );
      // A target 30 wide and 20 high is undersized: no 24 by 24 square fits.
      expect(
        wcag258Failures({
          'a': const Rect.fromLTWH(100, 100, 30, 20),
          'b': const Rect.fromLTWH(100, 121, 30, 20),
        }),
        isNotEmpty,
      );
    });
  });

  group('good examples', () {
    for (final slug in [..._good, _link]) {
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

      testWidgets('$slug: Tab reaches each control, and Enter and Space '
          'press it', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        var presses = 0;
        for (final id in _ids(slug)) {
          await tabTo(tester, id);
          // The web sends Enter as ButtonActivateIntent (FL-002); a widget
          // test cannot run as the web, so the lookup is checked as well.
          final focused = FocusManager.instance.primaryFocus!.context!;
          expect(Actions.maybeFind<ButtonActivateIntent>(focused), isNotNull);
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
          expect(_count(tester, slug), ++presses, reason: '$id Enter');
          await tester.sendKeyEvent(LogicalKeyboardKey.space);
          await tester.pumpAndSettle();
          expect(_count(tester, slug), ++presses, reason: '$id Space');
        }
        handle.dispose();
      });
    }
  });

  group('every control', () {
    for (final slug in _all) {
      testWidgets('$slug: a named control with a tap action, at its size', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        for (final id in _ids(slug)) {
          final data = dataById(id);
          if (slug == _link) {
            expect(data.label, 'trail rules');
            expect(data.flagsCollection.isLink, isTrue);
          } else {
            expect(data.label, _names[id.split('-').last]);
            expect(data.flagsCollection.isButton, isTrue);
          }
          expect(data.hasAction(SemanticsAction.tap), isTrue);
          if (slug != _link) {
            final size = _rectOf(tester, id).size;
            expect(
              size.width,
              moreOrLessEquals(_size[slug]!.width),
              reason: id,
            );
            expect(
              size.height,
              moreOrLessEquals(_size[slug]!.height),
              reason: id,
            );
          }
        }
        handle.dispose();
      });
    }
  });

  group('WCAG 2.5.8 as Android and iOS', () {
    for (final slug in [..._good, 'bad-zero-padding-web']) {
      testWidgets('$slug: no target is under 24 by 24, so it passes', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        final targets = {for (final id in _ids(slug)) id: _rectOf(tester, id)};
        for (final r in targets.values) {
          expect(r.width, greaterThanOrEqualTo(_minimum));
          expect(r.height, greaterThanOrEqualTo(_minimum));
        }
        expect(wcag258Failures(targets), isEmpty);
        handle.dispose();
      });
    }

    for (final slug in [
      'bad-shrinkwrap',
      'bad-cupertino-small',
      'bad-custom-small',
    ]) {
      testWidgets('$slug: 18 by 18 targets 4 apart fail, spacing included, '
          'and the 24 pixel guideline sees it', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        final targets = {for (final id in _ids(slug)) id: _rectOf(tester, id)};
        final rects = targets.values.toList();
        expect(rects[1].left - rects[0].right, moreOrLessEquals(4));
        expect(rects[2].left - rects[1].right, moreOrLessEquals(4));
        // Every one of the three fails: each circle meets its neighbour.
        expect(
          wcag258Failures(targets).map((f) => f.split(':').first).toSet(),
          targets.keys.toSet(),
        );
        // Written to fail if the targets grow.
        const wcag = MinimumTapTargetGuideline(
          size: Size(_minimum, _minimum),
          link: 'https://www.w3.org/TR/WCAG22/#target-size-minimum',
        );
        expect((await wcag.evaluate(tester)).passed, isFalse);
        expect(
          (await androidTapTargetGuideline.evaluate(tester)).passed,
          isFalse,
        );
        handle.dispose();
      });
    }

    // FL-413's workaround: the sentence's runs of text and the link are
    // separate nodes, in the sentence's order.
    testWidgets('$_link: the sentence is read in order, with the link in '
        'its place', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, _link);
      final link = nodeById('v13-$_link-rules').evaluate().single;
      final paragraph = link.parent!;
      expect(
        paragraph
            .debugListChildrenInOrder(DebugSemanticsDumpOrder.traversalOrder)
            .map((n) => n.getSemanticsData().label),
        ['Read the ', 'trail rules', ' before you set off.'],
      );
      final data = link.getSemanticsData();
      expect(data.flagsCollection.isLink, isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      handle.dispose();
    });

    testWidgets('$_link: under 24 high, in a sentence, so the inline '
        'exception applies; the guidelines skip links', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, _link);
      final rect = _rectOf(tester, 'v13-$_link-rules');
      expect(rect.height, lessThan(_minimum));
      // The link is inside the sentence: text before it and after it.
      final paragraph = tester.getRect(find.byType(RichText).first);
      expect(paragraph.left, lessThan(rect.left));
      expect(paragraph.right, greaterThan(rect.right));
      // The guideline would fail an undersized node that is not a link.
      const wcag = MinimumTapTargetGuideline(
        size: Size(_minimum, _minimum),
        link: 'https://www.w3.org/TR/WCAG22/#target-size-minimum',
      );
      expect((await wcag.evaluate(tester)).passed, isTrue);
      handle.dispose();
    });
  });

  group('WCAG 2.5.8 as the web in a desktop browser (FL-412)', () {
    // A web build takes Flutter's platform from the browser's operating
    // system, and on macOS, Linux, and Windows the Material theme does not
    // pad buttons and is compact (the probe; ThemeData's source).
    for (final platform in [
      TargetPlatform.macOS,
      TargetPlatform.linux,
      TargetPlatform.windows,
    ]) {
      testWidgets('bad-zero-padding-web as ${platform.name}: 18 by 18, 4 '
          'apart, fails', (tester) async {
        final handle = tester.ensureSemantics();
        await _asPlatform(platform, () async {
          await _open(tester, 'bad-zero-padding-web');
          final targets = {
            for (final id in _ids('bad-zero-padding-web'))
              id: _rectOf(tester, id),
          };
          for (final r in targets.values) {
            expect(r.size, const Size(18, 18));
          }
          expect(wcag258Failures(targets), isNotEmpty);
        });
        handle.dispose();
      });

      for (final (slug, size) in [
        ('good-material', const Size(40, 40)),
        ('good-cupertino', const Size(48, 48)),
        ('good-custom', const Size(48, 48)),
      ]) {
        testWidgets('$slug as ${platform.name}: $size, and passes', (
          tester,
        ) async {
          final handle = tester.ensureSemantics();
          await _asPlatform(platform, () async {
            await _open(tester, slug);
            final targets = {
              for (final id in _ids(slug)) id: _rectOf(tester, id),
            };
            for (final r in targets.values) {
              expect(r.size, size);
            }
            expect(wcag258Failures(targets), isEmpty);
          });
          handle.dispose();
        });
      }
    }

    for (final platform in [
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.fuchsia,
    ]) {
      testWidgets('bad-zero-padding-web as ${platform.name}: the theme pads '
          'it to 48 by 48', (tester) async {
        final handle = tester.ensureSemantics();
        await _asPlatform(platform, () async {
          await _open(tester, 'bad-zero-padding-web');
          for (final id in _ids('bad-zero-padding-web')) {
            expect(_rectOf(tester, id).size, const Size(48, 48), reason: id);
          }
        });
        handle.dispose();
      });
    }
  });

  group('taps', () {
    for (final slug in [..._good, ..._bad]) {
      testWidgets('$slug: each control takes a tap at its centre and 2 '
          'pixels inside its bottom edge, and not 2 pixels outside it', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        for (final id in _ids(slug)) {
          final r = _rectOf(tester, id);
          expect(await _tapAt(tester, slug, r.center), 1, reason: '$id centre');
          expect(
            await _tapAt(tester, slug, Offset(r.center.dx, r.bottom - 2)),
            1,
            reason: '$id 2 inside its bottom edge',
          );
          await _expectNothingAt(
            tester,
            slug,
            id,
            Offset(r.center.dx, r.bottom + 2),
            '2 below its bottom edge',
          );
        }
        // Nothing is to the right of the last control.
        final last = _ids(slug).last;
        final r = _rectOf(tester, last);
        await _expectNothingAt(
          tester,
          slug,
          last,
          Offset(r.right + 2, r.center.dy),
          '2 right of its right edge',
        );
        handle.dispose();
      });
    }

    testWidgets('good-material: a tap in the padding, outside the drawn '
        'circle, presses the button', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-material');
      for (final id in _ids('good-material')) {
        final node = _rectOf(tester, id);
        final circle = tester.getRect(
          find.descendant(of: byId(id), matching: find.byType(Material)).first,
        );
        expect(circle.size, const Size(40, 40));
        final point = Offset(node.center.dx, node.bottom - 2);
        expect(circle.contains(point), isFalse);
        expect(await _tapAt(tester, 'good-material', point), 1, reason: id);
      }
      handle.dispose();
    });

    testWidgets('good-custom: a tap in the box, outside the icon, presses '
        'the button', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-custom');
      for (final id in _ids('good-custom')) {
        final icon = tester.getRect(
          find.descendant(of: byId(id), matching: find.byType(Icon)),
        );
        expect(icon.size, const Size(24, 24));
        final node = _rectOf(tester, id);
        final point = Offset(node.center.dx, icon.bottom + 10);
        expect(await _tapAt(tester, 'good-custom', point), 1, reason: id);
      }
      handle.dispose();
    });

    testWidgets('$_link: the link takes a tap at its centre, and not 2 '
        'pixels below it', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, _link);
      final id = 'v13-$_link-rules';
      final r = _rectOf(tester, id);
      expect(await _tapAt(tester, _link, r.center), 1);
      await _expectNothingAt(
        tester,
        _link,
        id,
        Offset(r.center.dx, r.bottom + 2),
        '2 below it',
      );
      handle.dispose();
    });
  });

  group('the SDK on its own', () {
    // FL-413. Written to fail when a WidgetSpan is read in its place
    // without help.
    testWidgets('FL-413: the text around a WidgetSpan is one node without '
        "it, and the widget's node comes after", (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Read the '),
                    WidgetSpan(
                      child: MergeSemantics(
                        child: Semantics(
                          link: true,
                          identifier: 'link',
                          child: GestureDetector(
                            onTap: () {},
                            child: const Text('trail rules'),
                          ),
                        ),
                      ),
                    ),
                    const TextSpan(text: ' before you set off.'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final link = find.semantics
          .byPredicate(
            (n) =>
                !n.isMergedIntoParent &&
                n.getSemanticsData().identifier == 'link',
          )
          .evaluate()
          .single;
      final paragraph = link.parent!;
      expect(
        paragraph.getSemanticsData().label.replaceAll('\n', '|'),
        'Read the | before you set off.',
      );
      expect(
        paragraph
            .debugListChildrenInOrder(DebugSemanticsDumpOrder.traversalOrder)
            .map((n) => n.getSemanticsData().label),
        ['trail rules'],
      );
      handle.dispose();
    });

    Future<int Function()> pump(
      WidgetTester tester,
      Widget Function(VoidCallback) build,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Center(child: build(() => taps++))),
        ),
      );
      await tester.pumpAndSettle();
      return () => taps;
    }

    // FL-410. Written to fail when the node and the hit area agree, or the
    // guideline starts to look at the hit area.
    for (final (what, build) in <(String, Widget Function(VoidCallback))>[
      (
        'padding outside the GestureDetector',
        (tap) => Semantics(
          button: true,
          label: 'Close',
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: GestureDetector(
              onTap: tap,
              child: const Icon(Icons.close, size: 18),
            ),
          ),
        ),
      ),
      (
        'a 48 pixel box in a deferToChild GestureDetector',
        (tap) => Semantics(
          button: true,
          label: 'Close',
          child: GestureDetector(
            onTap: tap,
            child: const SizedBox.square(
              dimension: 48,
              child: Center(child: Icon(Icons.close, size: 18)),
            ),
          ),
        ),
      ),
    ]) {
      testWidgets('FL-410: $what: the node is 48 by 48 and passes the '
          'guideline, and only the 18 pixel icon takes taps', (tester) async {
        final handle = tester.ensureSemantics();
        final taps = await pump(tester, build);
        final node = tester.getSemantics(find.bySemanticsLabel('Close'));
        final rect = _nodeRect(tester, node);
        expect(rect.size, const Size(48, 48));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await tester.tapAt(Offset(rect.center.dx, rect.bottom - 2));
        await tester.pumpAndSettle();
        expect(taps(), 0, reason: 'a tap 2 inside the node, outside the icon');
        await tester.tapAt(rect.center);
        await tester.pumpAndSettle();
        expect(taps(), 1, reason: 'the positive control: a tap at the icon');
        handle.dispose();
      });
    }

    testWidgets('FL-410: a text link\'s node is its text plus 4 pixels on '
        'each side, which does not take taps, and the guidelines skip it', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      final recognizer = TapGestureRecognizer()..onTap = () => taps++;
      addTearDown(recognizer.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text.rich(
                TextSpan(
                  text: 'Read the ',
                  children: [
                    TextSpan(text: 'rules', recognizer: recognizer),
                    const TextSpan(text: ' first.'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final node = find.semantics.byLabel('rules').evaluate().single;
      expect(node.getSemanticsData().flagsCollection.isLink, isTrue);
      final rect = _nodeRect(tester, node);
      final paragraph = tester.renderObject<RenderParagraph>(
        find.byType(RichText),
      );
      final origin = paragraph.localToGlobal(Offset.zero);
      final boxes = paragraph.getBoxesForSelection(
        const TextSelection(baseOffset: 9, extentOffset: 14),
      );
      final text = boxes.first.toRect().shift(origin);
      expect(rect.top, moreOrLessEquals(text.top.floorToDouble() - 4));
      expect(rect.bottom, moreOrLessEquals(text.bottom.ceilToDouble() + 4));
      // 2 inside the node's bottom edge is 2 below the text: no tap.
      await tester.tapAt(Offset(rect.center.dx, rect.bottom - 2));
      await tester.pumpAndSettle();
      expect(taps, 0);
      await tester.tapAt(text.center);
      await tester.pumpAndSettle();
      expect(taps, 1);
      // Skipped: a node under 48 high that is not a link fails it.
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    // FL-412's workaround: the app's theme asks for the padding.
    testWidgets('FL-412: padded in ThemeData gives 48 by 48 as macOS', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _asPlatform(TargetPlatform.macOS, () async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              materialTapTargetSize: MaterialTapTargetSize.padded,
            ),
            home: Scaffold(
              body: Center(
                child: IconButton(
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 18,
                  icon: const Icon(Icons.add, semanticLabel: 'Bare'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final node = tester.getSemantics(find.bySemanticsLabel('Bare'));
        expect(_nodeRect(tester, node).size, const Size(48, 48));
      });
      handle.dispose();
    });

    // FL-412.
    for (final (platform, padded) in [
      (TargetPlatform.android, true),
      (TargetPlatform.iOS, true),
      (TargetPlatform.fuchsia, true),
      (TargetPlatform.macOS, false),
      (TargetPlatform.linux, false),
      (TargetPlatform.windows, false),
    ]) {
      testWidgets('FL-412: as ${platform.name} an IconButton is '
          '${padded ? 'padded to 48' : 'not padded'}', (tester) async {
        final handle = tester.ensureSemantics();
        await _asPlatform(platform, () async {
          await pump(
            tester,
            (tap) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: tap,
                  icon: const Icon(Icons.add, semanticLabel: 'Plain'),
                ),
                IconButton(
                  onPressed: tap,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 18,
                  icon: const Icon(Icons.add, semanticLabel: 'Bare'),
                ),
              ],
            ),
          );
          Size size(String label) => _nodeRect(
            tester,
            tester.getSemantics(find.bySemanticsLabel(label)),
          ).size;
          expect(
            size('Plain'),
            padded ? const Size(48, 48) : const Size(40, 40),
          );
          expect(
            size('Bare'),
            padded ? const Size(48, 48) : const Size(18, 18),
          );
          final theme = Theme.of(tester.element(find.byType(Row)));
          expect(
            theme.materialTapTargetSize,
            padded
                ? MaterialTapTargetSize.padded
                : MaterialTapTargetSize.shrinkWrap,
          );
          expect(
            theme.visualDensity,
            padded ? VisualDensity.standard : VisualDensity.compact,
          );
        });
        handle.dispose();
      });
    }
  });
}
