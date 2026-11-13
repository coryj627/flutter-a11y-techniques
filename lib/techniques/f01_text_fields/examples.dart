import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../catalog/test_id.dart';

class _Fields extends StatelessWidget {
  const _Fields({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: children,
    );
  }
}

// #region good-label
/// `labelText` is the visible label and the field's accessible name. It
/// moves above the text when the field has a value, so it never disappears.
class GoodLabelledFields extends StatelessWidget {
  const GoodLabelledFields({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Fields(
      children: [
        TestId(
          'f01-good-label-email',
          child: TextField(
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        TestId(
          'f01-good-label-message',
          child: TextField(
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Message',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region good-label-above
/// A label drawn above the field, as many designs do. The field is given
/// the same text as its accessible name, and the visible label is hidden
/// from assistive technology so it is not read twice.
class GoodLabelAbove extends StatelessWidget {
  const GoodLabelAbove({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Full name',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ),
        TestId(
          'f01-good-label-above-name',
          child: Semantics(
            label: 'Full name',
            child: const TextField(
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region good-cupertino
/// A Cupertino field has no label of its own. In a form row the prefix is
/// the visible label, and the field is given the same text as its name.
class GoodCupertinoField extends StatelessWidget {
  const GoodCupertinoField({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoFormSection.insetGrouped(
      children: [
        CupertinoFormRow(
          prefix: const ExcludeSemantics(child: Text('Email')),
          child: TestId(
            'f01-good-cupertino-email',
            child: Semantics(
              label: 'Email',
              child: const CupertinoTextField.borderless(
                keyboardType: TextInputType.emailAddress,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-placeholder-only
class BadPlaceholderOnly extends StatelessWidget {
  const BadPlaceholderOnly({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Fields(
      children: [
        TestId(
          'f01-bad-placeholder-only-email',
          child: TextField(
            // Defect: the only label is placeholder text, which disappears
            // as soon as something is typed.
            decoration: InputDecoration(
              hintText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-unassociated-label
class BadUnassociatedLabel extends StatelessWidget {
  const BadUnassociatedLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          // Defect: a visible label that is only nearby text. Nothing ties
          // it to the field, so the field has no name.
          child: Text('Email', style: Theme.of(context).textTheme.labelLarge),
        ),
        const TestId(
          'f01-bad-unassociated-label-email',
          child: TextField(
            decoration: InputDecoration(border: OutlineInputBorder()),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-no-label
class BadNoLabel extends StatelessWidget {
  const BadNoLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Fields(
      children: [
        TestId(
          'f01-bad-no-label-search',
          child: TextField(
            // Defect: an icon is the only hint of what the field is for.
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-name-mismatch
class BadFieldNameMismatch extends StatelessWidget {
  const BadFieldNameMismatch({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('Email', style: Theme.of(context).textTheme.labelLarge),
          ),
        ),
        TestId(
          'f01-bad-name-mismatch-email',
          child: Semantics(
            // Defect: the visible label says "Email" but the accessible
            // name is something else.
            label: 'Contact address',
            child: const TextField(
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-cupertino-placeholder
class BadCupertinoPlaceholder extends StatelessWidget {
  const BadCupertinoPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Fields(
      children: [
        TestId(
          'f01-bad-cupertino-placeholder-email',
          // Defect: placeholder is the only label a CupertinoTextField has.
          child: CupertinoTextField(placeholder: 'Email'),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-cupertino-prefix
class BadCupertinoPrefix extends StatelessWidget {
  const BadCupertinoPrefix({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoFormSection.insetGrouped(
      children: const [
        CupertinoFormRow(
          // Defect (to be confirmed per platform): the row's prefix looks
          // like the field's label but is separate text.
          prefix: Text('Email'),
          child: TestId(
            'f01-bad-cupertino-prefix-email',
            child: CupertinoTextField.borderless(),
          ),
        ),
      ],
    );
  }
}
// #endregion
