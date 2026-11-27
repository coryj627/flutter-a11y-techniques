import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../catalog/test_id.dart';

// Every good example is Flutter's own widgets used through their documented
// parameters: `Semantics(container:, explicitChildNodes:)` and
// `FocusTraversalGroup` round a column, or `Semantics(sortKey:)` with an
// `OrdinalSortKey` on every part. Flutter orders what a screen reader reads
// by where each part is on the screen, not by the order of the widgets
// (docs/flutter-limitations.md, FL-420), so two columns side by side are read
// row by row unless something says otherwise.

// #region shared
/// The left column: its title and the route's steps, in order.
const routeTitle = 'Route';
const routeSteps = ['Park at the gate.', 'Climb the ridge.', 'Walk back.'];

/// The right column: its title and what to bring.
const bringTitle = 'Bring';
const bringItems = ['Water', 'A map'];

/// A column's title: a level 3 heading, under the screen's level 1 title and
/// its level 2 "Example". `headingLevel` makes it a heading on every
/// platform (FL-003, FL-005) and the right level on the web (FL-004).
class ColumnTitle extends StatelessWidget {
  const ColumnTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    headingLevel: 3,
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

/// A 2 pixel outline in the page's text colour while a `TextButton` has
/// keyboard focus, through the button's own `style`, as in C12 and C18:
/// Material's own focus tint on a `TextButton` is under 3:1 against the page
/// (docs/flutter-limitations.md, FL-430).
ButtonStyle focusRing(ColorScheme colors) => ButtonStyle(
  side: WidgetStateProperty.resolveWith(
    (states) => states.contains(WidgetState.focused)
        ? BorderSide(color: colors.onSurface, width: 2)
        : null,
  ),
);

/// Holds how many times each list was saved, and ends every example with
/// the two counts, so that people and tests can see which button ran.
class Plan extends StatefulWidget {
  const Plan({super.key, required this.slug, required this.builder});

  final String slug;
  final Widget Function(BuildContext context, PlanState plan) builder;

  @override
  State<Plan> createState() => PlanState();
}

class PlanState extends State<Plan> {
  int routeSaves = 0;
  int listSaves = 0;

  /// The test identifier of the part [name] of this example.
  String id(String name) => 's11-${widget.slug}-$name';

  /// The "Save route" button.
  Widget saveRoute(BuildContext context) => TestId(
    id('save-route'),
    child: TextButton(
      style: focusRing(Theme.of(context).colorScheme),
      onPressed: () => setState(() => routeSaves++),
      child: const Text('Save route'),
    ),
  );

  /// The "Save list" button.
  Widget saveList(BuildContext context) => TestId(
    id('save-list'),
    child: TextButton(
      style: focusRing(Theme.of(context).colorScheme),
      onPressed: () => setState(() => listSaves++),
      child: const Text('Save list'),
    ),
  );

  Widget _count(String name, String text) => Semantics(
    key: ValueKey<String>(id(name)),
    identifier: id(name),
    liveRegion: true,
    child: Text(text),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        widget.builder(context, this),
        _count('route-saves', 'Route saves: $routeSaves'),
        _count('list-saves', 'List saves: $listSaves'),
      ],
    );
  }
}

/// Two parts side by side, each half the width.
Widget sideBySide(Widget left, Widget right) => Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: 16,
  children: [
    Expanded(child: left),
    Expanded(child: right),
  ],
);

/// One column of parts, top to bottom.
Widget stack(List<Widget> children) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: 8,
  children: children,
);

/// The route column's parts: its title, its steps, and its button.
List<Widget> routeColumn(BuildContext context, PlanState plan) => [
  const ColumnTitle(routeTitle),
  for (final step in routeSteps) Text(step),
  plan.saveRoute(context),
];

/// The bring column's parts: its title, its items, and its button.
List<Widget> bringColumn(BuildContext context, PlanState plan) => [
  const ColumnTitle(bringTitle),
  for (final item in bringItems) Text(item),
  plan.saveList(context),
];

/// Gives [child] its place, [order], in the screen reader's order.
Widget readAt(double order, Widget child) =>
    Semantics(container: true, sortKey: OrdinalSortKey(order), child: child);

/// The two columns built row by row. [bringTitleOrder] is the bring
/// column's title's place in the reading order, or null for none.
Widget rowBuilt(
  BuildContext context,
  PlanState plan, {
  double? bringTitleOrder = 6,
}) {
  Widget title = const ColumnTitle(bringTitle);
  if (bringTitleOrder != null) title = readAt(bringTitleOrder, title);
  return stack([
    sideBySide(readAt(1, const ColumnTitle(routeTitle)), title),
    sideBySide(readAt(2, Text(routeSteps[0])), readAt(7, Text(bringItems[0]))),
    sideBySide(readAt(3, Text(routeSteps[1])), readAt(8, Text(bringItems[1]))),
    sideBySide(readAt(4, Text(routeSteps[2])), const SizedBox.shrink()),
    sideBySide(
      readAt(5, plan.saveRoute(context)),
      readAt(9, plan.saveList(context)),
    ),
  ]);
}
// #endregion

// #region good-columns
/// Each column is a semantics container, so a screen reader reads one
/// column and then the other, and keeps each part a stop of its own with
/// `explicitChildNodes` (without it the container joins the column's texts
/// into one node). Each column is also a `FocusTraversalGroup`, so Tab
/// reaches the buttons in the same order whatever their heights: the right
/// column's button is higher on the screen, and without the groups Tab,
/// which goes by position, reached it first in the widget tests at most
/// sizes measured.
class GoodColumns extends StatelessWidget {
  const GoodColumns({super.key});

  @override
  Widget build(BuildContext context) {
    return Plan(
      slug: 'good-columns',
      builder: (context, plan) => sideBySide(
        FocusTraversalGroup(
          child: Semantics(
            container: true,
            explicitChildNodes: true,
            child: stack(routeColumn(context, plan)),
          ),
        ),
        FocusTraversalGroup(
          child: Semantics(
            container: true,
            explicitChildNodes: true,
            child: stack(bringColumn(context, plan)),
          ),
        ),
      ),
    );
  }
}
// #endregion

// #region good-sort-keys
/// The same two columns laid out row by row, so that each step lines up
/// with the item beside it: no widget holds a column, so no container can
/// keep one together. Every part is given its place in the reading order
/// with an `OrdinalSortKey`, the route's parts 1 to 5 and the list's 6 to
/// 9. Every part needs one: a part with no key keeps its place by position
/// (`bad-key-missing`). The key goes outside the button's `TestId`, whose
/// `MergeSemantics` would drop it (FL-341). The two buttons share the last
/// row, so Tab, which goes by position, reaches them in the reading order.
class GoodSortKeys extends StatelessWidget {
  const GoodSortKeys({super.key});

  @override
  Widget build(BuildContext context) {
    return Plan(
      slug: 'good-sort-keys',
      builder: (context, plan) => rowBuilt(context, plan),
    );
  }
}

// #endregion

// #region bad-columns-mixed
class BadColumnsMixed extends StatelessWidget {
  const BadColumnsMixed({super.key});

  @override
  Widget build(BuildContext context) {
    return Plan(
      slug: 'bad-columns-mixed',
      // Defect: no semantics container round either column. Flutter orders
      // what a screen reader reads by position, row by row, so it goes back
      // and forth between the two columns: Route, Bring, Park at the gate.,
      // Water, and so on. Tab still goes down one column, then the other.
      builder: (context, plan) => sideBySide(
        FocusTraversalGroup(child: stack(routeColumn(context, plan))),
        FocusTraversalGroup(child: stack(bringColumn(context, plan))),
      ),
    );
  }
}
// #endregion

// #region bad-key-missing
class BadKeyMissing extends StatelessWidget {
  const BadKeyMissing({super.key});

  @override
  Widget build(BuildContext context) {
    return Plan(
      slug: 'bad-key-missing',
      // Defect: the "Bring" title has no sort key. A part with no key keeps
      // its place by position and splits the keyed parts round it into
      // runs that are sorted apart (FL-340), so it is read second, before
      // the route's steps, and nothing heads the list that follows them.
      builder: (context, plan) =>
          rowBuilt(context, plan, bringTitleOrder: null),
    );
  }
}
// #endregion
