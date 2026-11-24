import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui' show Tristate;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/app/screens.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/c06_disclosure/c06_disclosure.dart';
import 'package:flutter_a11y_techniques/techniques/c06_disclosure/examples.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/examples.dart';

/// L1 for C06 Disclosure (docs/specs/C06-disclosure.md, section 6). These
/// tests run as Android unless a test sets another platform: `kIsWeb` is
/// false. No example has a `TestId` (its `MergeSemantics` would take the
/// open panel into the control), so the control is found by its text.
final _open = exampleOpener(c06Disclosure);

const _all = [
  'good-material',
  'bad-expansion-tile',
  'bad-expand-icon',
  'bad-cupertino-expansion-tile',
];

/// The examples whose panel has a button (not the Cupertino tile's).
const _withButton = ['good-material', 'bad-expansion-tile', 'bad-expand-icon'];

/// The node of the control: the one node, not merged into another, whose
/// label is the title.
SemanticsData _control(WidgetTester tester) =>
    semanticsNodes(tester).singleWhere((n) => n.label == disclosureTitle);

bool _isFocused(SemanticsData d) =>
    d.flagsCollection.isFocused == Tristate.isTrue;

/// The name of the node with keyboard focus: its tooltip (Back) or label,
/// or "(none)".
String _focusName(WidgetTester tester) {
  final focused = semanticsNodes(tester).where(_isFocused).toList();
  if (focused.isEmpty) return '(none)';
  final n = focused.single;
  return n.tooltip.isNotEmpty ? n.tooltip : n.label;
}

/// Every stop of keyboard focus, Tab by Tab, [tabs] times.
Future<List<String>> _tabStops(WidgetTester tester, int tabs) async {
  final stops = <String>[];
  for (var i = 0; i < tabs; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    stops.add(_focusName(tester));
  }
  return stops;
}

/// One whole cycle of keyboard focus: Tab (Shift+Tab when [backwards])
/// until Back has had focus twice, at most eight presses, and the name of
/// the focused node after each. It does not stop at the first Back, so a
/// control after Back in the cycle is always visited.
Future<List<String>> _focusCycle(
  WidgetTester tester, {
  required bool backwards,
}) async {
  final stops = <String>[];
  var backs = 0;
  for (var i = 0; i < 8; i++) {
    if (backwards) {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    } else {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    }
    await tester.pumpAndSettle();
    final name = _focusName(tester);
    stops.add(name);
    if (name == 'Back' && ++backs == 2) return stops;
  }
  fail('no whole focus cycle in eight presses: $stops');
}

/// Tabs until the control has focus, at most four times.
Future<void> _tabToControl(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    if (_focusName(tester) == disclosureTitle) return;
  }
  fail('Tab did not reach the control');
}

/// Whether the panel's text is on screen as a semantics node, merged or not.
bool _panelShown(WidgetTester tester) => semanticsNodes(
  tester,
  includeMerged: true,
).any((n) => n.label.contains(panelText));

/// The labels of the example's nodes in reading order, from the control to
/// the count, the count left out.
List<String> _reading(WidgetTester tester) {
  final labels = [
    for (final n in semanticsNodes(tester))
      if (n.label.isNotEmpty) n.label,
  ];
  final start = labels.indexWhere((l) => l.startsWith(disclosureTitle));
  final end = labels.indexWhere((l) => l.startsWith('Presses: '));
  expect(start, greaterThanOrEqualTo(0), reason: 'the control is read');
  expect(end, greaterThan(start), reason: 'the count comes last');
  return labels.sublist(start, end);
}

/// Opens the section with a tap on the control's title (on its icon for
/// `bad-expand-icon`, the only part of it that takes taps).
Future<void> _tapOpen(WidgetTester tester, String slug) async {
  final target = slug == 'bad-expand-icon'
      ? find.byType(ExpandIcon)
      : find.text(disclosureTitle);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(_panelShown(tester), isTrue, reason: '$slug: the tap opened it');
}

/// Performs the tap action on the control's node, as a screen reader does.
Future<void> _tapAction(WidgetTester tester) async {
  final node = semanticsNodeOf(tester, disclosureTitle);
  tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
    node.id,
    SemanticsAction.tap,
  );
  await tester.pumpAndSettle();
}

/// The semantics node of the control.
SemanticsNode semanticsNodeOf(WidgetTester tester, String label) {
  final found = <SemanticsNode>[];
  void visit(SemanticsNode n) {
    if (!n.isMergedIntoParent && n.getSemanticsData().label == label) {
      found.add(n);
    }
    n.visitChildren((c) {
      visit(c);
      return true;
    });
  }

  visit(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return found.single;
}

/// The hints of the control's tap action: what TalkBack says a double tap
/// does.
List<String> _tapHints(SemanticsData d) => [
  for (final id in d.customSemanticsActionIds ?? <int>[])
    if (CustomSemanticsAction.getAction(id) case final a?
        when a.action == SemanticsAction.tap)
      a.hint!,
];

/// Every paragraph of text that the example's own widget draws.
List<RenderParagraph> _exampleParagraphs(
  WidgetTester tester,
  TechniqueExample example,
) {
  final widget = example.builder(tester.element(find.byType(ExampleScreen)));
  expect(find.byType(widget.runtimeType), findsOneWidget);
  return tester
      .renderObjectList<RenderParagraph>(
        find.descendant(
          of: find.byType(widget.runtimeType),
          matching: find.byType(RichText),
        ),
      )
      .toList();
}

// Focus indicator: what keyboard focus changes on the screen, read from two
// captures, one before focus and one with it.

/// A capture of the screen as 0xRRGGBB per pixel.
class _Shot {
  _Shot(this.width, this.bytes);

  final int width;
  final ByteData bytes;

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
  final shot = _Shot(image.width, bytes!);
  image.dispose();
  return shot;
}

double _luminance(int c) {
  double lin(int v) {
    final s = v / 255;
    return s <= 0.04045
        ? s / 12.92
        : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * lin((c >> 16) & 255) +
      0.7152 * lin((c >> 8) & 255) +
      0.0722 * lin(c & 255);
}

double _ratio(int a, int b) {
  final la = _luminance(a), lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

int _channelDiff(int a, int b) {
  var most = 0;
  for (final shift in [16, 8, 0]) {
    most = math.max(most, (((a >> shift) & 255) - ((b >> shift) & 255)).abs());
  }
  return most;
}

/// What focus changed inside [region]: how many pixels changed by more
/// than 2 in a channel, and the highest contrast between a changed pixel's
/// colour with focus and its colour before, at the same place. Pixels
/// outside [region] are not read.
({int changed, double best}) _focusChange(
  _Shot before,
  _Shot after,
  Rect region,
) {
  var changed = 0;
  var best = 1.0;
  for (var y = region.top.floor(); y < region.bottom.ceil(); y++) {
    for (var x = region.left.floor(); x < region.right.ceil(); x++) {
      final a = before.at(x, y), b = after.at(x, y);
      if (_channelDiff(a, b) <= 2) continue;
      changed++;
      best = math.max(best, _ratio(a, b));
    }
  }
  return (changed: changed, best: best);
}

void main() {
  test('the technique has the examples named in the spec', () {
    expect(c06Disclosure.examples.map((e) => e.slug), _all);
    expect(
      [
        for (final e in c06Disclosure.examples)
          if (e.kind == ExampleKind.good) e.slug,
      ],
      ['good-material'],
    );
    expect(c06Disclosure.examples.first.customSolution, isNull);
    for (final platform in AppPlatform.values) {
      expect(
        c06Disclosure.platforms[platform]!.applicability,
        Applicability.limitation,
        reason: platform.name,
      );
    }
  });

  group('good-material', () {
    const slug = 'good-material';

    for (final brightness in Brightness.values) {
      for (final opened in [false, true]) {
        testWidgets('meets the guidelines (${brightness.name}, '
            '${opened ? 'open' : 'closed'})', (tester) async {
          final handle = tester.ensureSemantics();
          await _open(tester, slug, brightness: brightness);
          if (opened) await _tapOpen(tester, slug);
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          handle.dispose();
        });
      }
    }

    testWidgets('the control is a button named by its title, with the state '
        'only in its hint and no expanded state; the closed panel is not '
        'there', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, slug);
      final d = _control(tester);
      expect(d.flagsCollection.isButton, isTrue);
      expect(d.hasAction(SemanticsAction.tap), isTrue);
      expect(d.flagsCollection.isFocused, Tristate.isFalse);
      expect(d.hint, 'Collapsed');
      expect(d.value, isEmpty);
      // FL-264: no expanded state. Written to fail when Flutter adds one.
      expect(d.flagsCollection.isExpanded, Tristate.none);
      expect(_tapHints(d), ['Expand for more details']);
      // The control is the only button but Back, and a closed panel is not
      // in the tree.
      expect(
        semanticsNodes(tester)
            .where((n) => n.flagsCollection.isButton && n.tooltip != 'Back'),
        hasLength(1),
      );
      expect(_panelShown(tester), isFalse);
      expect(find.text(panelAction), findsNothing);
      expect(_reading(tester), [disclosureTitle]);
      handle.dispose();
    });

    testWidgets('open, the hint says "Expanded", there is still no expanded '
        'state, and the panel comes straight after the control', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, slug);
      await _tapOpen(tester, slug);
      final d = _control(tester);
      expect(d.flagsCollection.isButton, isTrue);
      expect(d.hint, 'Expanded');
      expect(d.flagsCollection.isExpanded, Tristate.none);
      expect(_tapHints(d), ['Collapse']);
      expect(_reading(tester), [disclosureTitle, panelText, panelAction]);
      handle.dispose();
    });

    testWidgets('on Android the state is also a live region that announces '
        'the change', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, slug);
      SemanticsData live() =>
          semanticsNodes(tester)
              .singleWhere((n) => n.flagsCollection.isLiveRegion);
      expect(live().label, 'Collapsed');
      await _tapAction(tester);
      expect(_panelShown(tester), isTrue);
      expect(live().label, 'Expanded');
      handle.dispose();
    });

    testWidgets('on iOS the hint adds the touch instruction, and the change '
        'is announced after a second', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final announced = <String>[];
      tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(SystemChannels.accessibility, (
            message,
          ) async {
            final m = message! as Map<Object?, Object?>;
            if (m['type'] == 'announce') {
              announced.add(
                (m['data']! as Map<Object?, Object?>)['message']! as String,
              );
            }
            return null;
          });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockDecodedMessageHandler<Object?>(
              SystemChannels.accessibility,
              null,
            ),
      );
      final handle = tester.ensureSemantics();
      await _open(tester, slug);
      final d = _control(tester);
      expect(d.flagsCollection.isButton, isTrue);
      expect(d.hint, 'Collapsed\n double tap to expand');
      expect(d.flagsCollection.isExpanded, Tristate.none);
      await _tapAction(tester);
      expect(_panelShown(tester), isTrue);
      expect(announced, isEmpty, reason: 'not before the second has passed');
      await tester.pump(const Duration(seconds: 1));
      expect(announced, ['Expanded']);
      expect(_control(tester).hint, 'Expanded\n double tap to collapse');
      handle.dispose();
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('the tap action, which a screen reader sends, opens and '
        'closes it', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, slug);
      await _tapAction(tester);
      expect(_panelShown(tester), isTrue);
      await _tapAction(tester);
      expect(_panelShown(tester), isFalse);
      expect(_control(tester).hint, 'Collapsed');
      handle.dispose();
    });

    for (final (key, name) in [
      (LogicalKeyboardKey.enter, 'Enter'),
      (LogicalKeyboardKey.space, 'Space'),
    ]) {
      testWidgets('Tab reaches it, after Back, and $name opens and closes '
          'it with focus kept on it', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        expect(await _tabStops(tester, 2), ['Back', disclosureTitle]);
        await tester.sendKeyEvent(key);
        await tester.pumpAndSettle();
        expect(_panelShown(tester), isTrue, reason: '$name opens it');
        expect(_focusName(tester), disclosureTitle);
        await tester.sendKeyEvent(key);
        await tester.pumpAndSettle();
        expect(_panelShown(tester), isFalse, reason: '$name again closes it');
        expect(_focusName(tester), disclosureTitle);
        handle.dispose();
      });
    }

    testWidgets('open, the next Tab goes to the panel\'s button, and Enter '
        'presses it', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, slug);
      await _tabToControl(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(await _tabStops(tester, 1), [panelAction]);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(countOf(tester, 'c06-$slug-count'), 1);
      expect(_panelShown(tester), isTrue);
      handle.dispose();
    });
  });

  // Keyboard focus, for every example a keyboard reaches: what focus
  // changes on the control is ListTile's or IconButton's tint, under 3:1
  // against what was there (FL-430), closed and open, light and dark.
  // Written to fail when focus draws something of 3:1 or more. The
  // Cupertino tile takes no focus (asserted below).
  for (final slug in _withButton) {
    for (final brightness in Brightness.values) {
      for (final opened in [false, true]) {
        testWidgets('$slug: keyboard focus shows only a tint under 3:1 '
            '(${brightness.name}, ${opened ? 'open' : 'closed'})', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(800, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final handle = tester.ensureSemantics();
          await _open(tester, slug, brightness: brightness);
          if (opened) await _tapOpen(tester, slug);
          // Focus off the control, as after a tap; then the capture before.
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          final control = slug == 'bad-expand-icon'
              ? find.descendant(
                  of: find.byType(ExpandIcon),
                  matching: find.byType(IconButton),
                )
              : find.descendant(
                  of: find.byType(ExpansionTile),
                  matching: find.byType(ListTile),
                );
          final region = tester.getRect(control).inflate(4);
          final before = await _shot(tester);
          await _tabToControl(tester);
          final after = await _shot(tester);
          final change = _focusChange(before, after, region);
          expect(
            change.changed,
            greaterThan(0),
            reason: 'focus drew something',
          );
          expect(change.best, lessThan(3), reason: 'FL-430: the tint');
          debugPrint(
            'C06FOCUS $slug ${brightness.name} ${opened ? 'open' : 'closed'}: '
            '${change.changed} pixels changed, best ${change.best.toStringAsFixed(2)}:1',
          );
          handle.dispose();
        });
      }
    }
  }

  // Every example, closed and open, in light and dark: the text contrast
  // guideline, so that no bad example has a contrast defect besides its
  // named one.
  for (final slug in _all) {
    for (final brightness in Brightness.values) {
      for (final opened in [false, true]) {
        testWidgets('$slug: text contrast (${brightness.name}, '
            '${opened ? 'open' : 'closed'})', (tester) async {
          final handle = tester.ensureSemantics();
          await _open(tester, slug, brightness: brightness);
          if (opened) await _tapOpen(tester, slug);
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          handle.dispose();
        });
      }
    }
  }

  // Every example, closed and open: at 200% text on a 320 by 640 screen no
  // layout overflows, and no text is cut short (line limit or box).
  for (final example in c06Disclosure.examples) {
    final slug = example.slug;
    for (final opened in [false, true]) {
      testWidgets('$slug: at 200% text on a phone nothing overflows and no '
          'text is cut short (${opened ? 'open' : 'closed'})', (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await _open(tester, slug, textScale: 2);
        if (opened) await _tapOpen(tester, slug);
        expect(tester.takeException(), isNull);
        final paragraphs = _exampleParagraphs(tester, example);
        expect(paragraphs, isNotEmpty);
        for (final p in paragraphs) {
          final text = p.text.toPlainText();
          expect(p.didExceedMaxLines, isFalse, reason: '"$text" line limit');
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
        }
      });
    }
  }

  group('bad examples have their defect', () {
    testWidgets('bad-expansion-tile: on Android and iOS the control is no '
        'button, and a tap opens it', (tester) async {
      for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
        debugDefaultTargetPlatformOverride = platform;
        final handle = tester.ensureSemantics();
        await _open(tester, 'bad-expansion-tile');
        final d = _control(tester);
        expect(d.flagsCollection.isButton, isFalse, reason: platform.name);
        expect(d.hasAction(SemanticsAction.tap), isTrue, reason: platform.name);
        expect(d.flagsCollection.isExpanded, Tristate.none);
        // The positive control: the same node, the same tap, opens it.
        await _tapOpen(tester, 'bad-expansion-tile');
        expect(_control(tester).flagsCollection.isButton, isFalse);
        handle.dispose();
        debugDefaultTargetPlatformOverride = null;
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('bad-expand-icon: a button named by its label with no state '
        'and no hint, before and after its tap action opens it', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-expand-icon');
      final d = _control(tester);
      expect(d.flagsCollection.isButton, isTrue);
      expect(d.flagsCollection.isExpanded, Tristate.none);
      expect(d.hint, isEmpty);
      expect(d.value, isEmpty);
      expect(_tapHints(d), ['Expand']);
      expect(
        semanticsNodes(tester).where((n) => n.flagsCollection.isLiveRegion),
        isEmpty,
      );
      await _tapAction(tester);
      // The positive control: the action opened it.
      expect(_panelShown(tester), isTrue);
      final open = _control(tester);
      expect(open.flagsCollection.isExpanded, Tristate.none);
      expect(open.hint, isEmpty);
      expect(open.value, isEmpty);
      expect(open.label, disclosureTitle);
      // In the widget tests the tap hint follows the state; on Android it
      // was seen not to (FL-280, the Android tests).
      expect(_tapHints(open), ['Collapse']);
      expect(_reading(tester), [disclosureTitle, panelText, panelAction]);
      handle.dispose();
    });

    testWidgets('bad-expand-icon: a tap on the label opens nothing; a tap on '
        'the icon opens it', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-expand-icon');
      await tester.tap(find.text(disclosureTitle), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(_panelShown(tester), isFalse);
      await _tapOpen(tester, 'bad-expand-icon');
      handle.dispose();
    });

    // A whole focus cycle, forwards and backwards, whose every stop is
    // Back; then the key, on Back, leaves the example (the key acted). The
    // same cycle visits good-material's control (the next test).
    for (final (key, name, backwards) in [
      (LogicalKeyboardKey.enter, 'Enter', false),
      (LogicalKeyboardKey.space, 'Space', false),
      (LogicalKeyboardKey.enter, 'Enter', true),
    ]) {
      final by = backwards ? 'Shift+Tab' : 'Tab';
      testWidgets('bad-cupertino-expansion-tile: a whole $by cycle stops only '
          'on Back, and $name there leaves the example closed', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, 'bad-cupertino-expansion-tile');
        final stops = await _focusCycle(tester, backwards: backwards);
        expect(stops, everyElement('Back'));
        expect(_panelShown(tester), isFalse);
        await tester.sendKeyEvent(key);
        await tester.pumpAndSettle();
        // The key acted: Back took it and the example left the screen.
        expect(find.byType(ExampleScreen), findsNothing, reason: name);
        expect(find.byType(TechniqueScreen), findsOneWidget, reason: name);
        handle.dispose();
      });
    }

    testWidgets('good-material: the same whole cycle, forwards and backwards, '
        'visits the control (the positive control)', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-material');
      expect(await _focusCycle(tester, backwards: false), [
        'Back',
        disclosureTitle,
        'Back',
      ]);
      expect(await _focusCycle(tester, backwards: true), [
        disclosureTitle,
        'Back',
        disclosureTitle,
        'Back',
      ]);
      handle.dispose();
    });

    testWidgets('bad-cupertino-expansion-tile: the control takes no focus, '
        'is no button, has no state, and a tap opens it', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-cupertino-expansion-tile');
      final d = _control(tester);
      expect(d.flagsCollection.isButton, isFalse);
      expect(d.flagsCollection.isFocused, Tristate.none);
      expect(d.flagsCollection.isExpanded, Tristate.none);
      expect(d.hasAction(SemanticsAction.tap), isTrue);
      await _tapOpen(tester, 'bad-cupertino-expansion-tile');
      // Open, the panel's text joins the control's label (FL-265).
      expect(
        semanticsNodes(tester)
            .where((n) => n.label == '$disclosureTitle\n$panelText'),
        hasLength(1),
      );
      handle.dispose();
    });
  });

  // The tests above rely on running off the web (see the top of the file).
  test('kIsWeb is false here', () => expect(kIsWeb, isFalse));
}
