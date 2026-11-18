import 'dart:ui' show Tristate;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_a11y_techniques/techniques/f06_error_identification/f06_error_identification.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/examples.dart';

/// L1 for F06 Error identification and announcement
/// (docs/specs/F06-error-identification.md).
///
/// [supportsAnnounce] stands for the platform: false is Android, where
/// Flutter reports that announcements are not supported; true is iOS and
/// the web.
Future<void> _open(
  WidgetTester tester,
  String slug, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
  bool supportsAnnounce = true,
}) => openExample(
  tester,
  f06ErrorIdentification,
  slug,
  brightness: brightness,
  textScale: textScale,
  accessibilityFeatures: FakeAccessibilityFeatures(
    supportsAnnounce: supportsAnnounce,
  ),
);

const _good = ['good-form', 'good-cupertino'];
const _bad = [
  'bad-color-only',
  'bad-vague-message',
  'bad-not-announced',
  'bad-merged-error',
];

const _nameError = 'Enter your name.';
const _emailError = 'Enter an email address with an @, like name@example.com.';

/// The fields of each example: slug -> (identifier, label, error when empty).
const _fields = {
  'good-form': [
    ('f06-good-form-name', 'Name', _nameError),
    ('f06-good-form-email', 'Email', _emailError),
  ],
  'good-cupertino': [
    ('f06-good-cupertino-name', 'Name', _nameError),
    ('f06-good-cupertino-email', 'Email', _emailError),
  ],
};

int _count(WidgetTester tester, String slug) =>
    countOf(tester, 'f06-$slug-count');

Finder _send(String slug) => byId('f06-$slug-send');

/// Records the announcements sent from code while [body] runs: each one's
/// message and assertiveness.
Future<List<(String, int)>> _announcements(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  final sent = <(String, int)>[];
  tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
    SystemChannels.accessibility,
    (message) async {
      final map = (message! as Map).cast<String, Object?>();
      if (map['type'] == 'announce') {
        final data = (map['data']! as Map).cast<String, Object?>();
        sent.add((
          data['message']! as String,
          data['assertiveness'] as int? ?? 0,
        ));
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger
        .setMockDecodedMessageHandler<Object?>(
          SystemChannels.accessibility,
          null,
        ),
  );
  await body();
  return sent;
}

/// Presses Send with a tap, lets Form's announcement go out, and settles.
Future<void> _pressSend(WidgetTester tester, String slug) async {
  await tester.ensureVisible(_send(slug));
  await tester.pumpAndSettle();
  await tester.tap(_send(slug));
  await tester.pumpAndSettle();
}

/// Every node, merged or not, whose label is exactly [text].
Iterable<SemanticsData> _nodesLabelled(WidgetTester tester, String text) =>
    semanticsNodes(tester).where((n) => n.label == text);

/// The node of the visible error text [text]: not the field, labelled with
/// the message alone.
SemanticsData _errorNode(WidgetTester tester, String text) =>
    _nodesLabelled(tester, text).single;

bool _focused(String id) =>
    dataById(id).flagsCollection.isFocused == Tristate.isTrue;

Future<void> _enter(WidgetTester tester, String id, String text) async {
  await tester.enterText(
    find.descendant(
      of: find.bySemanticsIdentifier(id),
      matching: find.byType(EditableText),
    ),
    text,
  );
  await tester.pumpAndSettle();
}

void main() {
  test('the technique has the examples named in the spec', () {
    expect(f06ErrorIdentification.examples.map((e) => e.slug), [
      ..._good,
      ..._bad,
    ]);
    expect(_good, [
      for (final e in f06ErrorIdentification.examples)
        if (e.kind == ExampleKind.good) e.slug,
    ]);
  });

  group('good examples', () {
    for (final slug in _good) {
      for (final brightness in Brightness.values) {
        testWidgets('$slug meets the guidelines with its errors showing '
            '(${brightness.name})', (tester) async {
          final handle = tester.ensureSemantics();
          await _open(tester, slug, brightness: brightness);
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          await _pressSend(tester, slug);
          expect(find.text(_nameError), findsOneWidget);
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          handle.dispose();
        });
      }

      testWidgets('$slug does not overflow at 200% text on a phone, and its '
          'errors are shown whole', (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await _open(tester, slug, textScale: 2);
        await _pressSend(tester, slug);
        expect(tester.takeException(), isNull);
        for (final message in [_nameError, _emailError]) {
          final paragraph = tester.renderObject<RenderParagraph>(
            find.text(message),
          );
          expect(paragraph.didExceedMaxLines, isFalse, reason: message);
        }
      });

      for (final supportsAnnounce in [true, false]) {
        final where = supportsAnnounce ? 'iOS and web' : 'Android';
        testWidgets('$slug ($where): each field in error is invalid, has its '
            'error as its hint, and shows it once as its own text', (
          tester,
        ) async {
          final handle = tester.ensureSemantics();
          await _open(tester, slug, supportsAnnounce: supportsAnnounce);
          for (final (id, label, _) in _fields[slug]!) {
            final data = dataById(id);
            expect(data.flagsCollection.isTextField, isTrue, reason: id);
            expect(data.label, label, reason: id);
            expect(data.hint, isEmpty, reason: id);
            expect(data.validationResult, SemanticsValidationResult.valid);
          }
          await _pressSend(tester, slug);
          for (final (id, label, error) in _fields[slug]!) {
            final data = dataById(id);
            // The name stays the label; the error is the hint.
            expect(data.label, label, reason: id);
            expect(data.hint, error, reason: id);
            expect(data.validationResult, SemanticsValidationResult.invalid);
            // The visible error is a node of its own, a live region only
            // where nothing announces it from code (Android).
            final message = _errorNode(tester, error);
            expect(message.flagsCollection.isLiveRegion, !supportsAnnounce);
            expect(message.flagsCollection.isTextField, isFalse);
          }
          // The visible label is the field's name and not a second node.
          expect(_nodesLabelled(tester, 'Name'), hasLength(1));
          expect(_count(tester, slug), 0);
          handle.dispose();
        });
      }

      testWidgets('$slug: Send announces the first error only, assertively, '
          'where announcements are supported', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        final sent = await _announcements(
          tester,
          () => _pressSend(tester, slug),
        );
        expect(sent, [(_nameError, Assertiveness.assertive.index)]);
        handle.dispose();
      });

      testWidgets('$slug: nothing is announced from code on Android', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug, supportsAnnounce: false);
        final sent = await _announcements(
          tester,
          () => _pressSend(tester, slug),
        );
        expect(sent, isEmpty);
        handle.dispose();
      });

      testWidgets('$slug: focus goes to the first field in error, and the '
          'form is sent once both are put right', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        final [(name, _, _), (email, _, _)] = _fields[slug]!;
        await _pressSend(tester, slug);
        expect(_focused(name), isTrue);
        expect(_focused(email), isFalse);
        await _enter(tester, name, 'Ana');
        await _enter(tester, email, 'abc');
        final sent = await _announcements(
          tester,
          () => _pressSend(tester, slug),
        );
        // Name is right now; Email is the first and only error.
        expect(
          dataById(name).validationResult,
          SemanticsValidationResult.valid,
        );
        expect(dataById(name).hint, isEmpty);
        expect(_focused(email), isTrue);
        expect(sent, [(_emailError, Assertiveness.assertive.index)]);
        await _enter(tester, email, 'ana@example.com');
        final none = await _announcements(
          tester,
          () => _pressSend(tester, slug),
        );
        expect(none, isEmpty);
        expect(find.text(_emailError), findsNothing);
        expect(_count(tester, slug), 1);
        handle.dispose();
      });

      testWidgets('$slug: the keyboard reaches Send and sends with Enter', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await tabTo(tester, 'f06-$slug-send');
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.text(_nameError), findsOneWidget);
        expect(_focused(_fields[slug]!.first.$1), isTrue);
        handle.dispose();
      });
    }
  });

  // VAL-3: each bad example is asserted to have its named defect.
  group('bad examples have their defect', () {
    testWidgets('bad-color-only: the field is invalid and turns red, and no '
        'words say what is wrong', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-color-only');
      const id = 'f06-bad-color-only-email';
      final before = semanticsNodes(tester).map((n) => n.label).toSet();
      final sent = await _announcements(
        tester,
        () => _pressSend(tester, 'bad-color-only'),
      );
      expect(dataById(id).validationResult, SemanticsValidationResult.invalid);
      expect(dataById(id).label, 'Email');
      expect(dataById(id).hint, isEmpty);
      // No new text anywhere, and nothing announced: the error has no words.
      final after = semanticsNodes(tester).map((n) => n.label).toSet();
      expect(after.difference(before), isEmpty);
      expect(sent, isEmpty);
      // The only sign is the colour of the outline.
      final decorator = tester.widget<InputDecorator>(
        find.descendant(
          of: find.bySemanticsIdentifier(id),
          matching: find.byType(InputDecorator),
        ),
      );
      expect(decorator.decoration.errorText, '');
      expect(_focused(id), isTrue);
      handle.dispose();
    });

    testWidgets('bad-vague-message: the error says "Invalid." and nothing '
        'about what to enter', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-vague-message');
      const id = 'f06-bad-vague-message-email';
      final sent = await _announcements(
        tester,
        () => _pressSend(tester, 'bad-vague-message'),
      );
      expect(dataById(id).validationResult, SemanticsValidationResult.invalid);
      expect(dataById(id).hint, 'Invalid.');
      expect(sent, [('Invalid.', Assertiveness.assertive.index)]);
      expect(find.text('Invalid.'), findsOneWidget);
      // The same input gets a message with a suggestion in good-form.
      expect(dataById(id).hint, isNot(contains('@')));
      handle.dispose();
    });

    for (final supportsAnnounce in [true, false]) {
      final where = supportsAnnounce ? 'iOS and web' : 'Android';
      testWidgets('bad-not-announced ($where): the error appears with focus '
          'left on Send, and is ${supportsAnnounce ? 'not announced' : 'a live '
                    'region'}', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(
          tester,
          'bad-not-announced',
          supportsAnnounce: supportsAnnounce,
        );
        const id = 'f06-bad-not-announced-email';
        final sent = await _announcements(
          tester,
          () => _pressSend(tester, 'bad-not-announced'),
        );
        // Everything else is as good-form has it.
        expect(dataById(id).hint, _emailError);
        expect(
          dataById(id).validationResult,
          SemanticsValidationResult.invalid,
        );
        expect(_focused(id), isFalse);
        expect(sent, isEmpty);
        // Where announcements are supported the error text is not a live
        // region either, so nothing tells a screen reader it appeared.
        expect(
          _errorNode(tester, _emailError).flagsCollection.isLiveRegion,
          !supportsAnnounce,
        );
        handle.dispose();
      });
    }

    for (final supportsAnnounce in [true, false]) {
      final where = supportsAnnounce ? 'iOS and web' : 'Android';
      testWidgets('bad-merged-error ($where): the error is in the field\'s '
          'name as well as its hint', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(
          tester,
          'bad-merged-error',
          supportsAnnounce: supportsAnnounce,
        );
        const id = 'f06-bad-merged-error-email';
        expect(dataById(id).label, 'Email');
        await _pressSend(tester, 'bad-merged-error');
        final data = dataById(id);
        expect(data.label, 'Email\n$_emailError');
        expect(data.hint, _emailError);
        // The error text is no longer a node of its own.
        expect(_nodesLabelled(tester, _emailError), isEmpty);
        // On Android its live region is merged into the field: the whole
        // field is now a live region.
        expect(data.flagsCollection.isLiveRegion, !supportsAnnounce);
        handle.dispose();
      });
    }
  });

  // A Flutter limitation pinned here, written to fail when it is fixed.
  for (final supportsAnnounce in [true, false]) {
    testWidgets('FL-182: CupertinoTextFormFieldRow\'s error is not a live '
        'region (supportsAnnounce: $supportsAnnounce)', (tester) async {
      final handle = tester.ensureSemantics();
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(supportsAnnounce: supportsAnnounce);
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      final form = GlobalKey<FormState>();
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Form(
              key: form,
              child: CupertinoFormSection(
                children: [
                  CupertinoTextFormFieldRow(
                    prefix: const Text('Email'),
                    validator: (_) => _emailError,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      form.currentState!.validate();
      await tester.pumpAndSettle();
      expect(find.text(_emailError), findsOneWidget);
      // Nothing is a live region, on Android either, where nothing else
      // announces the error.
      expect(
        semanticsNodes(
          tester,
          includeMerged: true,
        ).where((n) => n.flagsCollection.isLiveRegion),
        isEmpty,
      );
      handle.dispose();
    });
  }
}
