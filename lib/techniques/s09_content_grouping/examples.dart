import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../catalog/test_id.dart';

// Every good example is Flutter's own widgets used through their documented
// parameters: `MergeSemantics`, `Semantics(container:, explicitChildNodes:,
// label:)` with `ExcludeSemantics`, Cupertino's list section and tile, and
// Material's `TextButton.icon`. What they cannot do is in
// docs/flutter-limitations.md and is not built here.

// #region shared
/// The facts the text examples show: a label and its value, twice.
const facts = [('City', 'Boston'), ('Founded', '1630')];

/// The question the group of buttons answers, and its buttons.
const groupName = 'Kitchen light';

/// The one action of the tap target examples.
const targetName = 'App information';

/// A label over its value, as the text examples draw each fact.
class FactLabel extends StatelessWidget {
  const FactLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.labelLarge);
}

/// A fact's value, drawn larger than its label.
class FactValue extends StatelessWidget {
  const FactValue(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleLarge);
}

/// A 2 pixel outline in the page's text colour while a Material button has
/// keyboard focus, through the button's own `style`, as in C18: Material's
/// own focus tint on an `OutlinedButton` or a `TextButton` is under 3:1
/// against the page (docs/flutter-limitations.md, FL-430).
ButtonStyle focusRing(ColorScheme colors) => ButtonStyle(
  side: WidgetStateProperty.resolveWith(
    (states) => states.contains(WidgetState.focused)
        ? BorderSide(color: colors.onSurface, width: 2)
        : null,
  ),
);

/// A line under an example that says what its controls did, so that
/// people and tests can confirm it: "Light: on". [id] is its test
/// identifier.
class Status extends StatelessWidget {
  const Status({super.key, required this.id, required this.text});

  final String id;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: ValueKey<String>(id),
      identifier: id,
      liveRegion: true,
      child: Text(text),
    );
  }
}

/// The two buttons of the group examples, "On" and "Off", and the status
/// line under them. [builder] places the question and the buttons. Each
/// button has its test identifier, unless [buttonIds] is false: `TestId`
/// is a `MergeSemantics`, and inside a merged node its identifier would be
/// merged too.
class LightDemo extends StatefulWidget {
  const LightDemo({
    super.key,
    required this.slug,
    required this.builder,
    this.buttonIds = true,
  });

  final String slug;
  final bool buttonIds;
  final Widget Function(BuildContext context, Widget question, Widget buttons)
  builder;

  @override
  State<LightDemo> createState() => _LightDemoState();
}

class _LightDemoState extends State<LightDemo> {
  bool? _on;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final slug = widget.slug;
    Widget button(String name, bool on) {
      final button = OutlinedButton(
        style: focusRing(colors),
        onPressed: () => setState(() => _on = on),
        child: Text(name),
      );
      return widget.buttonIds
          ? TestId('s09-$slug-${name.toLowerCase()}', child: button)
          : button;
    }

    final question = Text(
      groupName,
      style: Theme.of(context).textTheme.titleMedium,
    );
    final buttons = Row(
      spacing: 8,
      children: [button('On', true), button('Off', false)],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        widget.builder(context, question, buttons),
        Status(
          id: 's09-$slug-status',
          text: switch (_on) {
            null => 'Light: not set',
            true => 'Light: on',
            false => 'Light: off',
          },
        ),
      ],
    );
  }
}
// #endregion

// #region good-merged-facts
/// Two facts, each a label over its value. `MergeSemantics` round each
/// pair makes it one element, read as one stop: "City, Boston". The pairs
/// sit side by side, as the columns of a small table, and wrap onto a line
/// of their own where the screen is too narrow.
class GoodMergedFacts extends StatelessWidget {
  const GoodMergedFacts({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 32,
      runSpacing: 12,
      children: [
        for (final (label, value) in facts)
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [FactLabel(label), FactValue(value)],
            ),
          ),
      ],
    );
  }
}
// #endregion

// #region good-cupertino
/// The same facts as rows of a Cupertino list, each its label over its
/// value. A `CupertinoListTile` keeps its title and its subtitle as two
/// elements (measured in the widget tests), so each row is put in
/// `MergeSemantics`, which makes it one: "City, Boston".
class GoodCupertino extends StatelessWidget {
  const GoodCupertino({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoListSection.insetGrouped(
      margin: EdgeInsets.zero,
      children: [
        for (final (label, value) in facts)
          MergeSemantics(
            child: CupertinoListTile(title: Text(label), subtitle: Text(value)),
          ),
      ],
    );
  }
}
// #endregion

// #region good-named-group
/// Two buttons that answer one question. The question is the label of a
/// node round the buttons. On the web that node is a group named by the
/// question, as `fieldset` and `legend` make one in HTML. On Android and
/// iOS Flutter has no such group: the question is read as a stop of its
/// own before the buttons, and not with them, where a native group's name
/// is said on the way in (docs/flutter-limitations.md, FL-320). So this is
/// a complete named group on the web only. The visible question is left
/// out of the semantics, or it would be read twice.
class GoodNamedGroup extends StatelessWidget {
  const GoodNamedGroup({super.key});

  @override
  Widget build(BuildContext context) {
    return LightDemo(
      slug: 'good-named-group',
      builder: (context, question, buttons) => Semantics(
        container: true,
        explicitChildNodes: true,
        label: groupName,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            ExcludeSemantics(child: question),
            buttons,
          ],
        ),
      ),
    );
  }
}
// #endregion

// #region good-tap-target
/// An icon and its text that do one thing are one target:
/// `TextButton.icon` makes one button named by the text, and a tap on the
/// icon or on the words does the same. The icon has no name of its own.
class GoodTapTarget extends StatefulWidget {
  const GoodTapTarget({super.key});

  @override
  State<GoodTapTarget> createState() => _GoodTapTargetState();
}

class _GoodTapTargetState extends State<GoodTapTarget> {
  int _opens = 0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        TestId(
          's09-good-tap-target-info',
          child: TextButton.icon(
            style: focusRing(colors),
            onPressed: () => setState(() => _opens++),
            icon: const Icon(Icons.info_outline),
            label: const Text(targetName),
          ),
        ),
        Status(id: 's09-good-tap-target-opens', text: 'Opens: $_opens'),
      ],
    );
  }
}
// #endregion

// #region bad-split-facts
/// The same table built row by row: the labels in one row and the values
/// in the next, nothing grouped. It looks the same, but it is read as
/// "City", "Founded", "Boston", "1630": the values come apart from what
/// they are.
class BadSplitFacts extends StatelessWidget {
  const BadSplitFacts({super.key});

  @override
  Widget build(BuildContext context) {
    Widget row(List<Widget> cells) =>
        Row(children: [for (final cell in cells) Expanded(child: cell)]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        row([for (final (label, _) in facts) FactLabel(label)]),
        row([for (final (_, value) in facts) FactValue(value)]),
      ],
    );
  }
}
// #endregion

// #region bad-merged-group
/// The question and its buttons merged into one element with
/// `MergeSemantics`: one button named "Kitchen light On Off", whose action
/// is the first button's. "Off" is no element of its own: TalkBack's
/// double tap on Android, and a click from assistive technology on the
/// web, turn the light on (VoiceOver's own activation on iOS was not
/// measured). The keyboard still reaches Off.
class BadMergedGroup extends StatelessWidget {
  const BadMergedGroup({super.key});

  @override
  Widget build(BuildContext context) {
    return LightDemo(
      slug: 'bad-merged-group',
      buttonIds: false,
      builder: (context, question, buttons) => MergeSemantics(
        child: Semantics(
          identifier: 's09-bad-merged-group-light',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [question, buttons],
          ),
        ),
      ),
    );
  }
}
// #endregion
