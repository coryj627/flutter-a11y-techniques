import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../catalog/test_id.dart';

// #region shared
/// The choices of every example: what to pack, on the left, and what to be
/// sent, on the right. The order they are meant to be reached in is down
/// the left column, then down the right one, then the Save button.
const _pack = [('map', 'Map'), ('water', 'Water'), ('aid', 'First aid')];
const _sendMe = [('weather', 'Weather'), ('closures', 'Closures')];

/// Holds which boxes are checked and how many times the plan was saved, and
/// ends every example with the count, so that people and tests can see
/// what a key did.
class _Plan extends StatefulWidget {
  const _Plan({required this.slug, required this.builder});

  final String slug;
  final List<Widget> Function(BuildContext context, _PlanState plan) builder;

  @override
  State<_Plan> createState() => _PlanState();
}

class _PlanState extends State<_Plan> {
  final Set<String> _checked = {};
  int _saves = 0;

  bool isChecked(String key) => _checked.contains(key);

  void toggle(String key) => setState(
    () => _checked.contains(key) ? _checked.remove(key) : _checked.add(key),
  );

  void save() => setState(() => _saves++);

  /// The test identifier of the control [key] of this example.
  String id(String key) => 'i02-${widget.slug}-$key';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        ...widget.builder(context, this),
        Semantics(
          key: ValueKey<String>(id('count')),
          identifier: id('count'),
          liveRegion: true,
          child: Text('Saves: $_saves'),
        ),
      ],
    );
  }
}

/// The title over a column of choices.
class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

/// A column of choices under its title. The semantics container keeps the
/// column together for screen readers, which otherwise read side-by-side
/// columns row by row, as Tab does; reading order is S11's subject. It
/// does nothing for the keyboard.
class _Choices extends StatelessWidget {
  const _Choices(this.title, this.children);

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [_Title(title), ...children],
    ),
  );
}

/// Two columns side by side, their rows level with each other.
class _TwoColumns extends StatelessWidget {
  const _TwoColumns({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 16,
    children: [
      Expanded(child: left),
      Expanded(child: right),
    ],
  );
}

/// A Material checkbox and its text as one control.
Widget _materialBox(_PlanState plan, (String, String) choice) => TestId(
  plan.id(choice.$1),
  child: CheckboxListTile(
    contentPadding: EdgeInsets.zero,
    controlAffinity: ListTileControlAffinity.leading,
    value: plan.isChecked(choice.$1),
    onChanged: (_) => plan.toggle(choice.$1),
    title: Text(choice.$2),
  ),
);

Widget _materialSave(_PlanState plan) => Align(
  alignment: AlignmentDirectional.centerStart,
  child: TestId(
    plan.id('save'),
    child: FilledButton(onPressed: plan.save, child: const Text('Save plan')),
  ),
);

/// Gives [child] its place, [order], in the keyboard's order and in the
/// screen reader's, so that the two agree.
Widget _numbered(double order, Widget child) => FocusTraversalOrder(
  order: NumericFocusOrder(order),
  child: _readAt(order, child),
);

/// Gives [child] its place, [order], in the screen reader's order only.
Widget _readAt(double order, Widget child) =>
    Semantics(container: true, sortKey: OrdinalSortKey(order), child: child);
// #endregion

// #region good-material
/// Each column is a `FocusTraversalGroup`, so Tab goes down the first
/// column before it moves to the second.
class GoodMaterial extends StatelessWidget {
  const GoodMaterial({super.key});

  @override
  Widget build(BuildContext context) {
    return _Plan(
      slug: 'good-material',
      builder: (context, plan) => [
        _TwoColumns(
          left: FocusTraversalGroup(
            child: _Choices('Pack', [
              for (final c in _pack) _materialBox(plan, c),
            ]),
          ),
          right: FocusTraversalGroup(
            child: _Choices('Send me', [
              for (final c in _sendMe) _materialBox(plan, c),
            ]),
          ),
        ),
        _materialSave(plan),
      ],
    );
  }
}
// #endregion

// #region good-cupertino
/// The same with Cupertino controls. `CupertinoCheckbox` takes keyboard
/// focus; it has no text of its own, so each one is merged with its text,
/// as in F07.
class GoodCupertino extends StatelessWidget {
  const GoodCupertino({super.key});

  Widget _box(_PlanState plan, (String, String) choice) => TestId(
    plan.id(choice.$1),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => plan.toggle(choice.$1),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          spacing: 8,
          children: [
            CupertinoCheckbox(
              value: plan.isChecked(choice.$1),
              onChanged: (_) => plan.toggle(choice.$1),
            ),
            Flexible(child: Text(choice.$2)),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return _Plan(
      slug: 'good-cupertino',
      builder: (context, plan) => [
        _TwoColumns(
          left: FocusTraversalGroup(
            child: _Choices('Pack', [for (final c in _pack) _box(plan, c)]),
          ),
          right: FocusTraversalGroup(
            child: _Choices('Send me', [
              for (final c in _sendMe) _box(plan, c),
            ]),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TestId(
            plan.id('save'),
            child: CupertinoButton.filled(
              onPressed: plan.save,
              child: const Text('Save plan'),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region good-ordered
/// When no widget holds a column, as here where the choices are laid out
/// row by row, the order is given by number: `OrderedTraversalPolicy` and
/// `FocusTraversalOrder` for the keyboard, and sort keys for screen readers.
/// Every control has a number, and the numbers follow the columns.
class GoodOrdered extends StatelessWidget {
  const GoodOrdered({super.key});

  @override
  Widget build(BuildContext context) {
    return _Plan(
      slug: 'good-ordered',
      builder: (context, plan) => [
        Semantics(
          container: true,
          child: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TwoColumns(
                  left: _readAt(1, const _Title('Pack')),
                  right: _readAt(5, const _Title('Send me')),
                ),
                _TwoColumns(
                  left: _numbered(2, _materialBox(plan, _pack[0])),
                  right: _numbered(6, _materialBox(plan, _sendMe[0])),
                ),
                _TwoColumns(
                  left: _numbered(3, _materialBox(plan, _pack[1])),
                  right: _numbered(7, _materialBox(plan, _sendMe[1])),
                ),
                _TwoColumns(
                  left: _numbered(4, _materialBox(plan, _pack[2])),
                  right: const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),
                _numbered(8, _materialSave(plan)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-columns-mixed
class BadColumnsMixed extends StatelessWidget {
  const BadColumnsMixed({super.key});

  @override
  Widget build(BuildContext context) {
    return _Plan(
      slug: 'bad-columns-mixed',
      builder: (context, plan) => [
        // Defect: no FocusTraversalGroup around either column. Flutter's
        // default order is by position, row by row, so Tab goes back and
        // forth between the two lists: Map, Weather, Water, Closures,
        // First aid. Screen readers still read one column, then the other.
        _TwoColumns(
          left: _Choices('Pack', [
            for (final c in _pack) _materialBox(plan, c),
          ]),
          right: _Choices('Send me', [
            for (final c in _sendMe) _materialBox(plan, c),
          ]),
        ),
        _materialSave(plan),
      ],
    );
  }
}
// #endregion

// #region bad-order-missing
class BadOrderMissing extends StatelessWidget {
  const BadOrderMissing({super.key});

  @override
  Widget build(BuildContext context) {
    return _Plan(
      slug: 'bad-order-missing',
      builder: (context, plan) => [
        Semantics(
          container: true,
          child: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TwoColumns(
                  left: _readAt(1, const _Title('Pack')),
                  right: _readAt(5, const _Title('Send me')),
                ),
                _TwoColumns(
                  left: _numbered(2, _materialBox(plan, _pack[0])),
                  right: _numbered(6, _materialBox(plan, _sendMe[0])),
                ),
                _TwoColumns(
                  left: _numbered(3, _materialBox(plan, _pack[1])),
                  right: _numbered(7, _materialBox(plan, _sendMe[1])),
                ),
                _TwoColumns(
                  // Defect: First aid has its place in the reading order
                  // but no number for the keyboard. OrderedTraversalPolicy
                  // puts a control with no number after every numbered
                  // one, so Tab reaches First aid only after Save plan.
                  left: _readAt(4, _materialBox(plan, _pack[2])),
                  right: const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),
                _numbered(8, _materialSave(plan)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion
