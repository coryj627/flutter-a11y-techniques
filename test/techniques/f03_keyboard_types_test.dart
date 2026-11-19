import 'dart:ui' show SemanticsInputType, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_a11y_techniques/techniques/f03_keyboard_types/f03_keyboard_types.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/examples.dart';

/// L1 for F03 Keyboard types (docs/specs/F03-keyboard-types.md).
///
/// What a field asks of the platform's keyboard and autofill is not in the
/// semantics tree: it is the configuration the field sends to the platform
/// when it starts editing (`TextInput.setClient`). The test binding records
/// that, so these tests read it there.
final _open = exampleOpener(f03KeyboardTypes);

Finder _editable(String id) =>
    find.descendant(of: byId(id), matching: find.byType(EditableText));

/// Starts editing [id] and returns what the field sent to the platform.
Future<Map<String, dynamic>> _configOf(WidgetTester tester, String id) async {
  await tester.showKeyboard(_editable(id));
  await tester.pump();
  return Map<String, dynamic>.from(tester.testTextInput.setClientArgs!);
}

/// The field's own part of [config]; the rest concerns its autofill group.
Map<String, dynamic> _inputType(Map<String, dynamic> config) =>
    Map<String, dynamic>.from(config['inputType'] as Map);

List<String> _hints(Map<String, dynamic> config) =>
    ((config['autofill'] as Map?)?['hints'] as List? ?? const [])
        .cast<String>();

/// One field as the spec describes it: what it asks for and what it exposes.
class _Field {
  const _Field(
    this.id,
    this.label, {
    required this.keyboard,
    this.decimal,
    required this.hints,
    required this.action,
    this.semanticsType = SemanticsInputType.text,
    this.obscured = false,
    this.capitalization = 'TextCapitalization.none',
  });

  final String id;
  final String label;
  final String keyboard;
  final bool? decimal;
  final List<String> hints;
  final String action;
  final SemanticsInputType semanticsType;
  final bool obscured;
  final String capitalization;
}

const _good = {
  'good-contact': [
    _Field(
      'f03-good-contact-name',
      'Name',
      keyboard: 'TextInputType.name',
      hints: ['name'],
      action: 'TextInputAction.next',
      capitalization: 'TextCapitalization.words',
    ),
    _Field(
      'f03-good-contact-email',
      'Email',
      keyboard: 'TextInputType.emailAddress',
      hints: ['email'],
      action: 'TextInputAction.next',
      semanticsType: SemanticsInputType.email,
    ),
    _Field(
      'f03-good-contact-phone',
      'Phone',
      keyboard: 'TextInputType.phone',
      hints: ['telephoneNumber'],
      action: 'TextInputAction.done',
      semanticsType: SemanticsInputType.phone,
    ),
  ],
  'good-amount': [
    _Field(
      'f03-good-amount-amount',
      'Amount',
      keyboard: 'TextInputType.number',
      decimal: true,
      hints: [],
      action: 'TextInputAction.done',
    ),
  ],
  'good-cupertino': [
    _Field(
      'f03-good-cupertino-email',
      'Email',
      keyboard: 'TextInputType.emailAddress',
      hints: ['email'],
      action: 'TextInputAction.next',
      semanticsType: SemanticsInputType.email,
    ),
    _Field(
      'f03-good-cupertino-phone',
      'Phone',
      keyboard: 'TextInputType.phone',
      hints: ['telephoneNumber'],
      action: 'TextInputAction.done',
      semanticsType: SemanticsInputType.phone,
    ),
  ],
  'good-sign-in': [
    _Field(
      'f03-good-sign-in-username',
      'Username',
      keyboard: 'TextInputType.text',
      hints: ['username'],
      action: 'TextInputAction.next',
    ),
    _Field(
      'f03-good-sign-in-password',
      'Password',
      keyboard: 'TextInputType.text',
      hints: ['password'],
      action: 'TextInputAction.done',
      obscured: true,
    ),
  ],
};

void _expectField(SemanticsData data, _Field field) {
  expect(data.flagsCollection.isTextField, isTrue, reason: field.id);
  expect(data.label, field.label, reason: field.id);
  expect(data.identifier, field.id);
  expect(data.inputType, field.semanticsType, reason: field.id);
  expect(data.flagsCollection.isObscured, field.obscured, reason: field.id);
}

void main() {
  test('the technique has the examples named in the spec', () {
    expect(f03KeyboardTypes.examples.map((e) => e.slug), [
      'good-contact',
      'good-amount',
      'good-cupertino',
      'good-sign-in',
      'bad-number-for-name',
      'bad-default-keyboard',
      'bad-no-purpose',
      'bad-email-no-suggestions',
    ]);
  });

  group('good examples', () {
    for (final MapEntry(key: slug, value: fields) in _good.entries) {
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

      testWidgets('$slug: every field is a named text field that asks for its '
          'keyboard, its Enter key, and its purpose', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        for (final field in fields) {
          _expectField(dataById(field.id), field);
          final config = await _configOf(tester, field.id);
          expect(_inputType(config)['name'], field.keyboard, reason: field.id);
          if (field.decimal != null) {
            expect(_inputType(config)['decimal'], field.decimal);
          }
          expect(_hints(config), field.hints, reason: field.id);
          expect(config['inputAction'], field.action, reason: field.id);
          expect(config['obscureText'], field.obscured, reason: field.id);
          expect(config['textCapitalization'], field.capitalization);
          expect(config['enableSuggestions'], isTrue, reason: field.id);
          // The field is in the tree the same way while it is edited.
          _expectField(dataById(field.id), field);
        }
        handle.dispose();
      });

      testWidgets('$slug: typing reaches each field and is counted', (
        tester,
      ) async {
        await _open(tester, slug);
        for (final (i, field) in fields.indexed) {
          await tester.enterText(_editable(field.id), '12');
          await tester.pump();
          expect(countOf(tester, 'f03-$slug-count'), i + 1);
        }
      });

      testWidgets('$slug: Tab reaches every field in order', (tester) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        for (final field in fields) {
          await tabTo(tester, field.id);
        }
        handle.dispose();
      });
    }

    for (final (slug, first, second) in [
      ('good-contact', 'f03-good-contact-name', 'f03-good-contact-email'),
      ('good-contact', 'f03-good-contact-email', 'f03-good-contact-phone'),
      (
        'good-cupertino',
        'f03-good-cupertino-email',
        'f03-good-cupertino-phone',
      ),
      (
        'good-sign-in',
        'f03-good-sign-in-username',
        'f03-good-sign-in-password',
      ),
    ]) {
      testWidgets('$slug: the Next key on $first moves to $second', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _open(tester, slug);
        await tester.showKeyboard(_editable(first));
        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.pumpAndSettle();
        expect(dataById(second).flagsCollection.isFocused, Tristate.isTrue);
        expect(dataById(first).flagsCollection.isFocused, Tristate.isFalse);
        handle.dispose();
      });
    }

    testWidgets('good-contact: the Done key on the last field ends editing', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-contact');
      await tester.showKeyboard(_editable('f03-good-contact-phone'));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      for (final field in _good['good-contact']!) {
        expect(
          dataById(field.id).flagsCollection.isFocused,
          Tristate.isFalse,
          reason: field.id,
        );
      }
      handle.dispose();
    });

    testWidgets('good-sign-in: both fields are sent to the platform as one '
        'autofill group', (tester) async {
      await _open(tester, 'good-sign-in');
      final config = await _configOf(tester, 'f03-good-sign-in-password');
      final fields = (config['fields'] as List).cast<Map>();
      expect(
        fields.map((f) => (f['autofill'] as Map)['hints']).toList(),
        unorderedEquals([
          ['username'],
          ['password'],
        ]),
      );
    });

    testWidgets('good-sign-in: the password is obscured in the tree and on '
        'the screen (FL-042)', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'good-sign-in');
      await tester.enterText(_editable('f03-good-sign-in-password'), 'abc');
      await tester.pump();
      final data = dataById('f03-good-sign-in-password');
      expect(data.flagsCollection.isObscured, isTrue);
      expect(data.value, '•••');
      // Drawn as bullets: the field obscures its text, not only its node.
      expect(
        tester
            .widget<EditableText>(_editable('f03-good-sign-in-password'))
            .obscureText,
        isTrue,
      );
      handle.dispose();
    });
  });

  // VAL-3: each bad example is asserted to have its named defect.
  group('bad examples have their defect', () {
    testWidgets('bad-number-for-name: a name field that asks for the number '
        'keyboard', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-number-for-name');
      const id = 'f03-bad-number-for-name-name';
      expect(dataById(id).label, 'Name');
      final config = await _configOf(tester, id);
      expect(_inputType(config), {
        'name': 'TextInputType.number',
        'signed': false,
        'decimal': false,
      });
      // The purpose is given; only the keyboard is wrong.
      expect(_hints(config), ['name']);
      handle.dispose();
    });

    testWidgets('bad-default-keyboard: an email field that asks for the '
        'general keyboard', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-default-keyboard');
      const id = 'f03-bad-default-keyboard-email';
      expect(dataById(id).label, 'Email');
      // Not exposed as an email field either: on the web that is what
      // gives the page an email input (FL-161).
      expect(dataById(id).inputType, SemanticsInputType.text);
      final config = await _configOf(tester, id);
      expect(_inputType(config)['name'], 'TextInputType.text');
      expect(_hints(config), ['email']);
      handle.dispose();
    });

    testWidgets('bad-no-purpose: a name field with no autofill hint', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-no-purpose');
      const id = 'f03-bad-no-purpose-name';
      expect(dataById(id).label, 'Name');
      final config = await _configOf(tester, id);
      // The keyboard is right; nothing names the purpose. A TextField's
      // default is an empty list: autofill on, with no hint.
      expect(_inputType(config)['name'], 'TextInputType.name');
      expect(config['autofill'], isNotNull);
      expect(_hints(config), isEmpty);
      handle.dispose();
    });

    testWidgets('bad-email-no-suggestions: an email field that turns '
        'suggestions off (FL-160)', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, 'bad-email-no-suggestions');
      const id = 'f03-bad-email-no-suggestions-email';
      expect(dataById(id).inputType, SemanticsInputType.email);
      final config = await _configOf(tester, id);
      // What the field asks for is right. The Android engine turns this
      // pair into a keyboard with no "@" (the Android tests); this layer
      // can only show the request.
      expect(_inputType(config)['name'], 'TextInputType.emailAddress');
      expect(config['enableSuggestions'], isFalse);
      expect(_hints(config), ['email']);
      handle.dispose();
    });
  });
}
