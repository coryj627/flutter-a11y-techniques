import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../catalog/test_id.dart';

// #region shared
/// Lays out one example and reports how many times its fields changed, so
/// people and tests can confirm that typing reached them.
class _Demo extends StatefulWidget {
  const _Demo({required this.slug, required this.builder});

  final String slug;
  final List<Widget> Function(BuildContext context, VoidCallback changed)
  builder;

  @override
  State<_Demo> createState() => _DemoState();
}

class _DemoState extends State<_Demo> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        ...widget.builder(context, () => setState(() => _count++)),
        Semantics(
          key: ValueKey<String>('f03-${widget.slug}-count'),
          identifier: 'f03-${widget.slug}-count',
          liveRegion: true,
          child: Text('Changes: $_count'),
        ),
      ],
    );
  }
}
// #endregion

// #region good-contact
/// Each field asks for the keyboard that fits what it takes, says what the
/// Enter key does, and names the purpose of the information it collects
/// about the user, so the platform can offer to fill it in.
class GoodContact extends StatelessWidget {
  const GoodContact({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-contact',
      builder: (context, changed) => [
        TestId(
          'f03-good-contact-name',
          child: TextField(
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            textInputAction: TextInputAction.next,
            onChanged: (_) => changed(),
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        TestId(
          'f03-good-contact-email',
          child: TextField(
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            onChanged: (_) => changed(),
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        TestId(
          'f03-good-contact-phone',
          child: TextField(
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            textInputAction: TextInputAction.done,
            onChanged: (_) => changed(),
            decoration: const InputDecoration(
              labelText: 'Phone',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region good-amount
/// An amount with a decimal point gets the keyboard for decimal numbers.
/// It is not information about the user, so it needs no autofill hint.
class GoodAmount extends StatelessWidget {
  const GoodAmount({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-amount',
      builder: (context, changed) => [
        TestId(
          'f03-good-amount-amount',
          child: TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            onChanged: (_) => changed(),
            decoration: const InputDecoration(
              labelText: 'Amount',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region good-cupertino
/// A Cupertino field takes the same keyboard type and autofill hints. It
/// has no label of its own (FL-016), so it is given the row's text as its
/// name, and that text is left out of the semantics so it is not read
/// twice.
class GoodCupertino extends StatelessWidget {
  const GoodCupertino({super.key});

  @override
  Widget build(BuildContext context) {
    Widget row({
      required String label,
      required String id,
      required TextInputType keyboardType,
      required String hint,
      required TextInputAction action,
      required VoidCallback changed,
    }) {
      return CupertinoFormRow(
        // Less padding than the default, so that the label and the field
        // fit side by side at 200% text on a narrow phone.
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        prefix: ExcludeSemantics(child: Text(label)),
        child: TestId(
          id,
          child: Semantics(
            label: label,
            child: CupertinoTextField.borderless(
              keyboardType: keyboardType,
              autocorrect: false,
              autofillHints: [hint],
              textInputAction: action,
              onChanged: (_) => changed(),
            ),
          ),
        ),
      );
    }

    return _Demo(
      slug: 'good-cupertino',
      builder: (context, changed) => [
        CupertinoFormSection.insetGrouped(
          margin: EdgeInsets.zero,
          children: [
            row(
              label: 'Email',
              id: 'f03-good-cupertino-email',
              keyboardType: TextInputType.emailAddress,
              hint: AutofillHints.email,
              action: TextInputAction.next,
              changed: changed,
            ),
            row(
              label: 'Phone',
              id: 'f03-good-cupertino-phone',
              keyboardType: TextInputType.phone,
              hint: AutofillHints.telephoneNumber,
              action: TextInputAction.done,
              changed: changed,
            ),
          ],
        ),
      ],
    );
  }
}
// #endregion

// #region good-sign-in
/// A sign-in form. `AutofillGroup` tells the platform that the two fields
/// belong together, so a password manager can fill both. The password is
/// obscured, which also tells assistive technology that it is a password.
class GoodSignIn extends StatelessWidget {
  const GoodSignIn({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-sign-in',
      builder: (context, changed) => [
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              TestId(
                'f03-good-sign-in-username',
                child: TextField(
                  autocorrect: false,
                  autofillHints: const [AutofillHints.username],
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => changed(),
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              TestId(
                'f03-good-sign-in-password',
                child: TextField(
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => changed(),
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-number-for-name
class BadNumberForName extends StatelessWidget {
  const BadNumberForName({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-number-for-name',
      builder: (context, changed) => [
        TestId(
          'f03-bad-number-for-name-name',
          child: TextField(
            // Defect: a name field that asks for the number keyboard. The
            // on-screen keyboard has digits only, so a name cannot be
            // typed with it.
            keyboardType: TextInputType.number,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            onChanged: (_) => changed(),
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-default-keyboard
class BadDefaultKeyboard extends StatelessWidget {
  const BadDefaultKeyboard({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-default-keyboard',
      builder: (context, changed) => [
        TestId(
          'f03-bad-default-keyboard-email',
          child: TextField(
            // Defect: an email field left with the default keyboard. The
            // "@" is not on the keyboard's first page.
            autocorrect: false,
            autofillHints: const [AutofillHints.email],
            onChanged: (_) => changed(),
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-no-purpose
class BadNoPurpose extends StatelessWidget {
  const BadNoPurpose({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-no-purpose',
      builder: (context, changed) => [
        TestId(
          'f03-bad-no-purpose-name',
          child: TextField(
            // Defect: the field collects the user's name but says nothing
            // about what it holds: no autofill hint, so the platform cannot
            // tell its purpose and cannot offer to fill it in.
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => changed(),
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-email-no-suggestions
class BadEmailNoSuggestions extends StatelessWidget {
  const BadEmailNoSuggestions({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-email-no-suggestions',
      builder: (context, changed) => [
        TestId(
          'f03-bad-email-no-suggestions-email',
          child: TextField(
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            // Defect: turning suggestions off on Android replaces the email
            // keyboard with a general one with no "@" key
            // (docs/flutter-limitations.md, FL-160).
            enableSuggestions: false,
            autofillHints: const [AutofillHints.email],
            onChanged: (_) => changed(),
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion
