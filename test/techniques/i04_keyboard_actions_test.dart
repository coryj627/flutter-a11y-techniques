import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/i04_keyboard_actions/i04_keyboard_actions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/examples.dart';

/// L1 for I04 Keyboard actions and shortcuts
/// (docs/specs/I04-keyboard-actions.md).
///
/// A widget test sends keys to the framework only. A key that no shortcut
/// handles would go on to the platform's text input on a device; here
/// `sendKeyEvent` reports it as not handled, which is what the tests of the
/// note field read. On a device, Enter on a hardware keyboard reaches a
/// single-line field as the field's action (docs/evidence/probes/i04/), so
/// the tests send the action, as `TextField.onSubmitted`'s documentation
/// says to.
final _open = exampleOpener(i04KeyboardActions);

const _good = ['good-on-focus', 'good-turn-off', 'good-remap'];
const _bad = ['bad-page-shortcut', 'bad-no-arrow-keys'];
const _all = [..._good, ..._bad];

/// The examples whose strip answers the arrow keys, Home, and End.
const _stripKeys = [..._good, 'bad-page-shortcut'];

/// The examples with a setting between the favourite button and the note.
const _withSetting = ['good-turn-off', 'good-remap'];

const _photos = ['Trailhead', 'Bridge', 'Ridge', 'Summit'];
final _thumbs = [for (final p in _photos) p.toLowerCase()];

String _id(String slug, String part) => 'i04-$slug-$part';

String _text(WidgetTester tester, String slug, String part) => tester
    .widget<Text>(
      find.descendant(of: byId(_id(slug, part)), matching: find.byType(Text)),
    )
    .data!;

/// "Bridge" for "Showing: Bridge, 2 of 4".
String _showing(WidgetTester tester, String slug) => _text(
  tester,
  slug,
  'showing',
).replaceFirst('Showing: ', '').split(',').first;

String _favourites(WidgetTester tester, String slug) =>
    _text(tester, slug, 'favourites');

int _notes(WidgetTester tester, String slug) =>
    countOf(tester, _id(slug, 'count'));

bool _focused(String slug, String part) =>
    dataById(_id(slug, part)).flagsCollection.isFocused == Tristate.isTrue;

/// The one part of the example, or Back, whose node says it has focus;
/// "none" if none does. Fails if two do.
String _stop(String slug) {
  final parts = [..._thumbs, 'favourite', 'setting', 'note'];
  final focused = [
    for (final part in parts)
      if (nodeById(_id(slug, part)).evaluate().isNotEmpty &&
          _focused(slug, part))
        part,
    if (_backFocused()) 'back',
  ];
  expect(focused.length, lessThanOrEqualTo(1), reason: 'focused: $focused');
  return focused.isEmpty ? 'none' : focused.single;
}

bool _backFocused() {
  final focus = FocusManager.instance.primaryFocus?.context;
  if (focus == null) return false;
  return find
      .ancestor(
        of: find.byElementPredicate((e) => e == focus),
        matching: find.byType(BackButton),
      )
      .evaluate()
      .isNotEmpty;
}

Future<bool> _key(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  String? character,
}) async {
  final handled = await tester.sendKeyEvent(key, character: character);
  await tester.pumpAndSettle();
  return handled;
}

/// F as a keyboard sends it: the F key with the character "f".
Future<bool> _f(WidgetTester tester) =>
    _key(tester, LogicalKeyboardKey.keyF, character: 'f');

Future<bool> _controlF(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  final handled = await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
  return handled;
}

Future<void> _shiftTab(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
  await tester.pumpAndSettle();
}

/// Taps [finder] once it is scrolled into view: the longer defect text of
/// a bad example pushes the note below the test screen.
Future<void> _tapOn(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Tabs until [part] of [slug] has focus, and proves it.
Future<void> _tabTo(WidgetTester tester, String slug, String part) async {
  await tabTo(tester, _id(slug, part));
  expect(_stop(slug), part);
}

void main() {
  test('the technique has the examples named in the spec', () {
    expect(i04KeyboardActions.examples.map((e) => e.slug), _all);
    expect(_good, [
      for (final e in i04KeyboardActions.examples)
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
    }
  });

  group('every example', () {
    for (final slug in _all) {
      testWidgets('$slug: four thumbnails, the first selected, a favourite '
          'button, and a note field', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        expect(_text(tester, slug, 'showing'), 'Showing: Trailhead, 1 of 4');
        for (var i = 0; i < _photos.length; i++) {
          final thumb = dataById(_id(slug, _thumbs[i]));
          expect(thumb.label, _photos[i]);
          expect(thumb.flagsCollection.isButton, isTrue);
          expect(
            thumb.flagsCollection.isSelected,
            i == 0 ? Tristate.isTrue : Tristate.isFalse,
            reason: _photos[i],
          );
          expect(thumb.flagsCollection.isFocused, Tristate.isFalse);
        }
        final favourite = dataById(_id(slug, 'favourite'));
        expect(favourite.tooltip, 'Add to favourites');
        expect(favourite.flagsCollection.isButton, isTrue);
        final note = dataById(_id(slug, 'note'));
        expect(note.label, contains('Note'));
        expect(note.flagsCollection.isTextField, isTrue);
        expect(_favourites(tester, slug), 'Favourites: none');
        expect(_notes(tester, slug), 0);
        handle.dispose();
      });

      testWidgets('$slug: a tap, and the semantics tap a screen reader '
          'sends, show any photo', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await _tapOn(tester, byId(_id(slug, 'ridge')));
        expect(_showing(tester, slug), 'Ridge');
        expect(
          dataById(_id(slug, 'ridge')).flagsCollection.isSelected,
          Tristate.isTrue,
        );
        tester.semantics.tap(nodeById(_id(slug, 'summit')));
        await tester.pumpAndSettle();
        expect(_showing(tester, slug), 'Summit');
        handle.dispose();
      });

      testWidgets('$slug: the favourite button adds and removes the photo, '
          'and says which it will do', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await _tapOn(tester, byId(_id(slug, 'favourite')));
        expect(_favourites(tester, slug), 'Favourites: Trailhead');
        expect(
          dataById(_id(slug, 'favourite')).tooltip,
          'Remove from favourites',
        );
        await _tapOn(tester, byId(_id(slug, 'favourite')));
        expect(_favourites(tester, slug), 'Favourites: none');
        handle.dispose();
      });

      testWidgets('$slug: the note field\'s action key is Done, and the '
          'action saves the note and empties the field', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await _tapOn(tester, byId(_id(slug, 'note')));
        expect(
          tester.testTextInput.setClientArgs?['inputAction'],
          'TextInputAction.done',
        );
        tester.testTextInput.enterText('Muddy');
        await tester.pumpAndSettle();
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(_notes(tester, slug), 1);
        final field = tester.widget<EditableText>(
          find.descendant(
            of: byId(_id(slug, 'note')),
            matching: find.byType(EditableText),
          ),
        );
        expect(field.controller.text, isEmpty);
        // FL-460: the action takes focus from the field and gives it to no
        // control.
        expect(_stop(slug), 'none');
        // A blank note is not saved.
        await _tapOn(tester, byId(_id(slug, 'note')));
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(_notes(tester, slug), 1);
        handle.dispose();
      });

      testWidgets('$slug: Tab goes Back, the thumbnail of the photo shown, '
          'the favourite button, '
          '${_withSetting.contains(slug) ? 'the setting, ' : ''}the note, '
          'then round to Back, stop by stop', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        final order = [
          'back',
          'trailhead',
          'favourite',
          if (_withSetting.contains(slug)) 'setting',
          'note',
          'back',
        ];
        for (final stop in order) {
          await _key(tester, LogicalKeyboardKey.tab);
          expect(_stop(slug), stop);
        }
        // With another photo shown, its thumbnail is the strip's stop.
        tester.semantics.tap(nodeById(_id(slug, 'ridge')));
        await tester.pumpAndSettle();
        await tabTo(tester, _id(slug, 'favourite'));
        await _shiftTab(tester);
        expect(_stop(slug), 'ridge');
        await _shiftTab(tester);
        expect(_stop(slug), 'back');
        handle.dispose();
      });
    }
  });

  group('the strip\'s keys', () {
    for (final slug in _stripKeys) {
      testWidgets('$slug: Right, Left, End, and Home show a photo and move '
          'focus to its thumbnail', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await _tabTo(tester, slug, 'trailhead');
        for (final (key, photo) in [
          (LogicalKeyboardKey.arrowRight, 'Bridge'),
          (LogicalKeyboardKey.arrowRight, 'Ridge'),
          (LogicalKeyboardKey.arrowLeft, 'Bridge'),
          (LogicalKeyboardKey.end, 'Summit'),
          (LogicalKeyboardKey.arrowRight, 'Summit'),
          (LogicalKeyboardKey.home, 'Trailhead'),
          (LogicalKeyboardKey.arrowLeft, 'Trailhead'),
        ]) {
          expect(await _key(tester, key), isTrue, reason: '$key handled');
          expect(_showing(tester, slug), photo, reason: '$key');
          expect(_stop(slug), photo.toLowerCase(), reason: 'focus after $key');
        }
        // A held arrow repeats.
        await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        expect(_showing(tester, slug), 'Ridge');
        expect(_stop(slug), 'ridge');
        handle.dispose();
      });

      testWidgets('$slug: Down leaves the strip for the control below, as '
          'the default directional focus does', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await _tabTo(tester, slug, 'trailhead');
        await _key(tester, LogicalKeyboardKey.arrowDown);
        expect(_stop(slug), 'favourite');
        expect(_showing(tester, slug), 'Trailhead');
        handle.dispose();
      });
    }

    for (final (key, name) in [
      (LogicalKeyboardKey.arrowRight, 'Right'),
      (LogicalKeyboardKey.arrowLeft, 'Left'),
      (LogicalKeyboardKey.end, 'End'),
      (LogicalKeyboardKey.home, 'Home'),
    ]) {
      testWidgets('bad-no-arrow-keys: $name does not move along the strip; '
          'F and Down, in the same launch, act there', (tester) async {
        const slug = 'bad-no-arrow-keys';
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        // From the second photo, so that Left and Home would have
        // somewhere to go.
        tester.semantics.tap(nodeById(_id(slug, 'bridge')));
        await tester.pumpAndSettle();
        await _tabTo(tester, slug, 'bridge');
        await _key(tester, key);
        expect(_showing(tester, slug), 'Bridge', reason: name);
        final after = _stop(slug);
        expect(
          ['trailhead', 'ridge', 'summit'],
          isNot(contains(after)),
          reason: '$name moved to another thumbnail',
        );
        if (after != 'bridge') await _tabTo(tester, slug, 'bridge');
        // The controls: keys reach the strip, and an arrow arrives.
        expect(await _f(tester), isTrue);
        expect(_favourites(tester, slug), 'Favourites: Bridge');
        // Down moves focus to a control below the strip, by the default
        // directional focus: the arrows do arrive.
        await _key(tester, LogicalKeyboardKey.arrowDown);
        expect(_stop(slug), isIn(['favourite', 'note']));
        handle.dispose();
      });
    }

    testWidgets('bad-no-arrow-keys: Tab and Shift+Tab never reach the other '
        'thumbnails', (tester) async {
      const slug = 'bad-no-arrow-keys';
      final handle = tester.ensureSemantics();
      await _open(tester, slug);
      final seen = <String>[];
      for (var i = 0; i < 10; i++) {
        await _key(tester, LogicalKeyboardKey.tab);
        seen.add(_stop(slug));
      }
      for (var i = 0; i < 10; i++) {
        await _shiftTab(tester);
        seen.add(_stop(slug));
      }
      expect(seen, containsAll(['back', 'trailhead', 'favourite', 'note']));
      expect(seen, isNot(contains('bridge')));
      expect(seen, isNot(contains('ridge')));
      expect(seen, isNot(contains('summit')));
      handle.dispose();
    });
  });

  group('the F shortcut', () {
    testWidgets('good-on-focus: F acts in the strip only; on the favourite '
        'button and in the note it is not taken', (tester) async {
      const slug = 'good-on-focus';
      final handle = tester.ensureSemantics();
      await _open(tester, slug);
      await _tabTo(tester, slug, 'trailhead');
      expect(await _f(tester), isTrue);
      expect(_favourites(tester, slug), 'Favourites: Trailhead');
      await _tabTo(tester, slug, 'favourite');
      expect(await _f(tester), isFalse);
      expect(_favourites(tester, slug), 'Favourites: Trailhead');
      await _tabTo(tester, slug, 'note');
      // Not handled: on a device the key goes on to the field as a letter.
      expect(await _f(tester), isFalse);
      expect(_favourites(tester, slug), 'Favourites: Trailhead');
      handle.dispose();
    });

    for (final slug in ['good-turn-off', 'good-remap']) {
      testWidgets('$slug: F acts wherever focus is, except in the note, '
          'where it is left for typing', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await _tabTo(tester, slug, 'trailhead');
        expect(await _f(tester), isTrue);
        expect(_favourites(tester, slug), 'Favourites: Trailhead');
        await _key(tester, LogicalKeyboardKey.arrowRight);
        await _tabTo(tester, slug, 'favourite');
        expect(await _f(tester), isTrue);
        expect(_favourites(tester, slug), 'Favourites: Trailhead, Bridge');
        await _tabTo(tester, slug, 'setting');
        expect(await _f(tester), isTrue);
        expect(_favourites(tester, slug), 'Favourites: Trailhead');
        await _tabTo(tester, slug, 'note');
        expect(await _f(tester), isFalse);
        expect(_favourites(tester, slug), 'Favourites: Trailhead');
        handle.dispose();
      });
    }

    testWidgets('good-turn-off: with the switch off F does nothing; on '
        'again, F acts', (tester) async {
      const slug = 'good-turn-off';
      final handle = tester.ensureSemantics();
      await _open(tester, slug);
      final setting = dataById(_id(slug, 'setting'));
      expect(setting.label, 'Single-key shortcuts');
      expect(setting.flagsCollection.isToggled, Tristate.isTrue);
      await _tabTo(tester, slug, 'setting');
      await _key(tester, LogicalKeyboardKey.space);
      expect(
        dataById(_id(slug, 'setting')).flagsCollection.isToggled,
        Tristate.isFalse,
      );
      expect(await _f(tester), isFalse);
      await _shiftTab(tester);
      await _shiftTab(tester);
      expect(_stop(slug), 'trailhead');
      expect(await _f(tester), isFalse);
      expect(_favourites(tester, slug), 'Favourites: none');
      // The keys arrive: the strip's own keys still act.
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(_showing(tester, slug), 'Bridge');
      // On again: the same key acts.
      await _tabTo(tester, slug, 'setting');
      await _key(tester, LogicalKeyboardKey.space);
      expect(await _f(tester), isTrue);
      expect(_favourites(tester, slug), 'Favourites: Bridge');
      handle.dispose();
    });

    testWidgets('good-remap: with the switch on, F does nothing and '
        'Control+F acts, in the note as well', (tester) async {
      const slug = 'good-remap';
      final handle = tester.ensureSemantics();
      await _open(tester, slug);
      expect(
        dataById(_id(slug, 'setting')).label,
        'Use Control+F for favourites',
      );
      await _tabTo(tester, slug, 'setting');
      // Control+F does nothing while the shortcut is F.
      expect(await _controlF(tester), isFalse);
      expect(_favourites(tester, slug), 'Favourites: none');
      await _key(tester, LogicalKeyboardKey.space);
      expect(
        dataById(_id(slug, 'setting')).flagsCollection.isToggled,
        Tristate.isTrue,
      );
      expect(await _f(tester), isFalse);
      expect(_favourites(tester, slug), 'Favourites: none');
      expect(await _controlF(tester), isTrue);
      expect(_favourites(tester, slug), 'Favourites: Trailhead');
      await _tabTo(tester, slug, 'note');
      expect(await _f(tester), isFalse);
      expect(await _controlF(tester), isTrue);
      expect(_favourites(tester, slug), 'Favourites: none');
      handle.dispose();
    });

    testWidgets('bad-page-shortcut: F acts wherever focus is, in the note '
        'too, where it is taken before the field can type it', (tester) async {
      const slug = 'bad-page-shortcut';
      final handle = tester.ensureSemantics();
      await _open(tester, slug);
      await _tabTo(tester, slug, 'trailhead');
      expect(await _f(tester), isTrue);
      expect(_favourites(tester, slug), 'Favourites: Trailhead');
      await _tabTo(tester, slug, 'favourite');
      expect(await _f(tester), isTrue);
      expect(_favourites(tester, slug), 'Favourites: none');
      await _tabTo(tester, slug, 'note');
      expect(await _f(tester), isTrue);
      expect(_favourites(tester, slug), 'Favourites: Trailhead');
      // Nothing on the screen turns it off or changes it.
      expect(nodeById(_id(slug, 'setting')), findsNothing);
      handle.dispose();
    });

    testWidgets('bad-no-arrow-keys: F acts in the strip only', (tester) async {
      const slug = 'bad-no-arrow-keys';
      final handle = tester.ensureSemantics();
      await _open(tester, slug);
      await _tabTo(tester, slug, 'trailhead');
      expect(await _f(tester), isTrue);
      await _tabTo(tester, slug, 'favourite');
      expect(await _f(tester), isFalse);
      expect(_favourites(tester, slug), 'Favourites: Trailhead');
      handle.dispose();
    });
  });

  group('the line of keys', () {
    for (final slug in _all) {
      testWidgets('$slug: the line of keys is a node of its own, with no '
          'control under it', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        final hint = semanticsNodes(tester)
            .where((n) => n.label.startsWith('In the photos:'))
            .toList();
        expect(hint, hasLength(1));
        final node = find.semantics
            .byPredicate((n) => n.label.startsWith('In the photos:'))
            .evaluate()
            .single;
        expect(node.childrenCount, 0);
        handle.dispose();
      });
    }
  });

  // FL-464: a Shortcuts, a CallbackShortcuts, or a Focus that takes no
  // focus adds a semantics node, which takes the text inside it that has no
  // node of its own as its name and holds the controls inside it as its
  // children. Written to fail when the wrapper stops adding a node.
  group('the SDK on its own (FL-464)', () {
    final wrappers = <String, Widget Function(Widget)>{
      'CallbackShortcuts': (c) =>
          CallbackShortcuts(bindings: const {}, child: c),
      'Shortcuts': (c) => Shortcuts(shortcuts: const {}, child: c),
      'Focus': (c) => Focus(canRequestFocus: false, child: c),
    };
    for (final MapEntry(key: name, value: wrap) in wrappers.entries) {
      for (final container in [false, true]) {
        testWidgets('$name around text${container ? ' in its own node' : ''} '
            'and a button', (tester) async {
          final handle = tester.ensureSemantics();
          const text = Text('Press F');
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: wrap(
                  Column(
                    children: [
                      if (container)
                        Semantics(container: true, child: text)
                      else
                        text,
                      ElevatedButton(onPressed: () {}, child: const Text('Go')),
                    ],
                  ),
                ),
              ),
            ),
          );
          final node = find.semantics
              .byPredicate((n) => n.label == 'Press F')
              .evaluate()
              .single;
          final children = <String>[];
          node.visitChildren((c) {
            children.add(c.getSemanticsData().label);
            return true;
          });
          expect(children, container ? isEmpty : ['Go']);
          handle.dispose();
        });
      }
    }
    testWidgets('with nothing around them, the text and the button are '
        'side by side', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Text('Press F'),
                ElevatedButton(onPressed: () {}, child: const Text('Go')),
              ],
            ),
          ),
        ),
      );
      final node = find.semantics
          .byPredicate((n) => n.label == 'Press F')
          .evaluate()
          .single;
      expect(node.childrenCount, 0);
      handle.dispose();
    });
  });
}
