import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../catalog/test_id.dart';

// #region shared
/// Lays out one example and reports how many times its field changed, so
/// people and tests can confirm that typing reached it.
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
          key: ValueKey<String>('f02-${widget.slug}-count'),
          identifier: 'f02-${widget.slug}-count',
          liveRegion: true,
          child: Text('Changes: $_count'),
        ),
      ],
    );
  }
}

const _username = 'Username';
const _rule = '4 to 10 characters, no spaces.';
// #endregion

// #region good-helper
/// Material's place for an instruction is the helper text under the field.
/// On its own it is only text near the field, so the field is given the
/// same words as its hint: a screen reader reads them with the field. The
/// helper text stays on the screen and stays an element of its own.
///
/// The identifier is set with a plain `Semantics`, not `TestId`: the
/// `MergeSemantics` inside `TestId` would pull the helper text into the
/// field's name (docs/flutter-limitations.md, FL-140).
/// `helperMaxLines` lets the instruction wrap; by default it is cut to one
/// line (FL-141).
class GoodHelper extends StatelessWidget {
  const GoodHelper({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-helper',
      builder: (context, changed) => [
        Semantics(
          key: const ValueKey<String>('f02-good-helper-username'),
          identifier: 'f02-good-helper-username',
          hint: _rule,
          child: TextField(
            onChanged: (_) => changed(),
            decoration: const InputDecoration(
              labelText: _username,
              helperText: _rule,
              helperMaxLines: 4,
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
/// A Cupertino form row has a place for help text under the field. The
/// field has no label or hint of its own (FL-016), so it is given both, and
/// the visible label is left out of the semantics so it is not read twice.
class GoodCupertino extends StatelessWidget {
  const GoodCupertino({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-cupertino',
      builder: (context, changed) => [
        CupertinoFormSection.insetGrouped(
          margin: EdgeInsets.zero,
          children: [
            CupertinoFormRow(
              // Less padding than the default, so that the label and the
              // field fit side by side at 200% text on a narrow phone.
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              prefix: const ExcludeSemantics(child: Text(_username)),
              helper: const Text(_rule),
              child: TestId(
                'f02-good-cupertino-username',
                child: Semantics(
                  label: _username,
                  hint: _rule,
                  child: CupertinoTextField.borderless(
                    onChanged: (_) => changed(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
// #endregion

// #region good-before
/// The instruction drawn between the label and the field, so it is read
/// before the field in order, as the iOS reference lays it out. The field
/// is given the label as its name and the instruction as its hint.
class GoodBefore extends StatelessWidget {
  const GoodBefore({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return _Demo(
      slug: 'good-before',
      builder: (context, changed) => [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 4,
          children: [
            ExcludeSemantics(child: Text(_username, style: text.labelLarge)),
            Text(
              _rule,
              key: const ValueKey<String>('f02-good-before-rule'),
              style: text.bodySmall,
            ),
            TestId(
              'f02-good-before-username',
              child: Semantics(
                label: _username,
                hint: _rule,
                child: TextField(
                  onChanged: (_) => changed(),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
// #endregion

// #region bad-helper-only
/// Helper text and nothing else. The instruction is on the screen under the
/// field, but nothing ties it to the field: a screen reader reads the field
/// without it, and reads the instruction as separate text.
class BadHelperOnly extends StatelessWidget {
  const BadHelperOnly({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-helper-only',
      builder: (context, changed) => [
        Semantics(
          key: const ValueKey<String>('f02-bad-helper-only-username'),
          identifier: 'f02-bad-helper-only-username',
          child: TextField(
            onChanged: (_) => changed(),
            // Defect: the instruction is only helper text, which Flutter
            // does not make the field's description.
            decoration: const InputDecoration(
              labelText: _username,
              helperText: _rule,
              helperMaxLines: 4,
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-placeholder-format
/// The format is given as placeholder text. With a label, Material shows
/// it only while the field is being edited and is empty: it is gone at the
/// first character typed, and on Android and iOS a screen reader arriving
/// at the field does not hear it.
class BadPlaceholderFormat extends StatelessWidget {
  const BadPlaceholderFormat({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-placeholder-format',
      builder: (context, changed) => [
        TestId(
          'f02-bad-placeholder-format-birthday',
          child: TextField(
            onChanged: (_) => changed(),
            keyboardType: TextInputType.datetime,
            decoration: const InputDecoration(
              labelText: 'Date of birth',
              // Defect: the only instruction is a placeholder.
              hintText: 'DD/MM/YYYY',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-helper-cut-off
/// Helper text with the default `helperMaxLines`. The field is given the
/// instruction as its hint, so a screen reader hears all of it, but on the
/// screen the helper text is one line: with large text the end of the
/// instruction is cut off.
class BadHelperCutOff extends StatelessWidget {
  const BadHelperCutOff({super.key});

  static const _displayRule =
      'Shown on your posts. 2 to 30 letters or numbers.';

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-helper-cut-off',
      builder: (context, changed) => [
        Semantics(
          key: const ValueKey<String>('f02-bad-helper-cut-off-name'),
          identifier: 'f02-bad-helper-cut-off-name',
          hint: _displayRule,
          child: TextField(
            onChanged: (_) => changed(),
            // Defect: no helperMaxLines, so the helper text never wraps.
            decoration: const InputDecoration(
              labelText: 'Display name',
              helperText: _displayRule,
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion
