import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

// Every good example is Flutter's own widgets used through their documented
// parameters: `Semantics(role: SemanticsRole.list)` round the list and
// `Semantics(role: SemanticsRole.listItem)` round each item, round a `Column`
// as the `SemanticsRole.list` documentation describes, Material's `ListTile`,
// and Cupertino's `CupertinoListSection`. None is complete on Android or the
// web: on Android a list made this way says "In list" and "Out of list" but
// not its size or an item's place (FL-311); on the web it is a list only
// because it is laid out whole and does not scroll (FL-312), and VoiceOver
// reads a text-only item as an "empty group" (FL-315). On iOS Flutter gives
// a list nothing (FL-310): each item is an element of its own. What they
// cannot do is in docs/flutter-limitations.md and is not built here.

// #region shared
/// The shopping list every unordered example shows.
const groceries = ['Milk', 'Eggs', 'Bread'];

/// The steps the ordered example shows, in order.
const steps = ['Fork the repository', 'Make the change', 'Open a pull request'];

/// A list: `SemanticsRole.list` round the widget that lays out its items.
/// Its items must be the nodes right under it: the framework checks that
/// every list item's parent node is a list.
Widget list(Widget child) => Semantics(role: SemanticsRole.list, child: child);

/// One item of a [list]: its texts are merged into the item's node.
Widget listItem(Widget child) =>
    Semantics(role: SemanticsRole.listItem, child: child);

/// The bullet drawn in front of an item. It is drawn, not text, so it adds
/// nothing to what assistive technology reads: the list's role says that
/// these are items, as a bullet does on the screen.
class Bullet extends StatelessWidget {
  const Bullet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface,
          shape: BoxShape.circle,
        ),
        child: const SizedBox(width: 6, height: 6),
      ),
    );
  }
}

/// A bulleted line: the bullet, then [text].
class BulletLine extends StatelessWidget {
  const BulletLine(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Bullet(),
          Flexible(child: Text(text)),
        ],
      ),
    );
  }
}

/// The line under a list of tiles that says which one was opened last:
/// "Chosen: Eggs". [id] is its test identifier.
class Chosen extends StatelessWidget {
  const Chosen({super.key, required this.id, required this.chosen});

  final String id;
  final String chosen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Semantics(
        key: ValueKey<String>(id),
        identifier: id,
        liveRegion: true,
        child: Text('Chosen: $chosen'),
      ),
    );
  }
}
// #endregion

// #region good-bulleted
/// A bulleted list: `SemanticsRole.list` round a `Column`, and
/// `SemanticsRole.listItem` round each line. Android: "In list" and "Out
/// of list", no size or place. iOS: each line an element, no list. Web: a
/// list of three items, each read as "Milk empty group (1 of 3) 1 of 3".
class GoodBulleted extends StatelessWidget {
  const GoodBulleted({super.key});

  @override
  Widget build(BuildContext context) {
    return list(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [for (final g in groceries) listItem(BulletLine(g))],
      ),
    );
  }
}
// #endregion

// #region good-numbered
/// A numbered list. Flutter has no ordered list, so each item's number is
/// part of its text, where it is read with the item. What each platform
/// gives is `good-bulleted`'s.
class GoodNumbered extends StatelessWidget {
  const GoodNumbered({super.key});

  @override
  Widget build(BuildContext context) {
    return list(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, step) in steps.indexed)
            listItem(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('${i + 1}. $step'),
              ),
            ),
        ],
      ),
    );
  }
}
// #endregion

// #region good-material
/// A list of Material list tiles that each open something. Each tile is
/// kept a button of its own inside its list item with `explicitChildNodes`:
/// merged into the item, it would be a list item and no button on the web
/// (`bad-tile-in-item`). Android: each tile a button, the first with "In
/// list", no size or place. iOS: each tile a button, no list. Web: a list
/// of items each holding a button, read "Milk button 1 of 3" (WebKit).
class GoodMaterial extends StatefulWidget {
  const GoodMaterial({super.key});

  @override
  State<GoodMaterial> createState() => _GoodMaterialState();
}

class _GoodMaterialState extends State<GoodMaterial> {
  var _chosen = 'none';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        list(
          Column(
            children: [
              for (final g in groceries)
                Semantics(
                  role: SemanticsRole.listItem,
                  explicitChildNodes: true,
                  child: Semantics(
                    key: ValueKey<String>(
                      's08-good-material-${g.toLowerCase()}',
                    ),
                    identifier: 's08-good-material-${g.toLowerCase()}',
                    child: ListTile(
                      title: Text(g),
                      onTap: () => setState(() => _chosen = g),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Chosen(id: 's08-good-material-chosen', chosen: _chosen),
      ],
    );
  }
}
// #endregion

// #region good-cupertino
/// A Cupertino list section, named by its header: `SemanticsRole.list` round
/// the `CupertinoListSection`, which joins the header's text to the list,
/// and `SemanticsRole.listItem` round each `CupertinoListTile`. The tiles do
/// nothing when tapped: a `CupertinoListTile` with `onTap` takes no keyboard
/// focus and is not a button on Android and iOS (FL-400). Android: the list
/// named "Groceries", no size or place. iOS: the header, then each tile, no
/// list. Web: "list Groceries 3 items", each tile as `good-bulleted`'s.
class GoodCupertino extends StatelessWidget {
  const GoodCupertino({super.key});

  @override
  Widget build(BuildContext context) {
    return list(
      CupertinoListSection(
        header: const Text('Groceries'),
        children: [
          for (final g in groceries)
            listItem(CupertinoListTile(title: Text(g))),
        ],
      ),
    );
  }
}
// #endregion

// #region bad-one-text
class BadOneText extends StatelessWidget {
  const BadOneText({super.key});

  @override
  Widget build(BuildContext context) {
    // Defect: the items are lines of one text, so they are one element,
    // read as one paragraph, with no list and no items.
    return Text(groceries.join('\n'));
  }
}
// #endregion

// #region bad-no-list
class BadNoList extends StatelessWidget {
  const BadNoList({super.key});

  @override
  Widget build(BuildContext context) {
    // Defect: the lines look like a list and are each an element of their
    // own, but nothing says they are a list: no role and no number of
    // items.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final g in groceries) BulletLine(g)],
    );
  }
}
// #endregion

// #region bad-tile-in-item
class BadTileInItem extends StatefulWidget {
  const BadTileInItem({super.key});

  @override
  State<BadTileInItem> createState() => _BadTileInItemState();
}

class _BadTileInItemState extends State<BadTileInItem> {
  var _chosen = 'none';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        list(
          Column(
            children: [
              for (final g in groceries)
                // Defect: the tile is merged into its list item, and on the
                // web a list item is not a button.
                Semantics(
                  key: ValueKey<String>(
                    's08-bad-tile-in-item-${g.toLowerCase()}',
                  ),
                  role: SemanticsRole.listItem,
                  identifier: 's08-bad-tile-in-item-${g.toLowerCase()}',
                  child: ListTile(
                    title: Text(g),
                    onTap: () => setState(() => _chosen = g),
                  ),
                ),
            ],
          ),
        ),
        Chosen(id: 's08-bad-tile-in-item-chosen', chosen: _chosen),
      ],
    );
  }
}
// #endregion

// #region bad-lazy-list
/// How many orders the long list holds.
const orderCount = 30;

class BadLazyList extends StatelessWidget {
  const BadLazyList({super.key});

  @override
  Widget build(BuildContext context) {
    // Defect, Flutter's and not the author's: a long list in a `ListView`,
    // the widget for long lists, which builds its items as they are
    // scrolled to. On Android and the web nothing says that it is a list
    // (FL-313, FL-312), and the list's role cannot be put round it
    // (FL-314). There is no good example of a long list to put beside it.
    return SizedBox(
      height: 200,
      child: ListView.builder(
        itemCount: orderCount,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text('Order ${i + 1}'),
        ),
      ),
    );
  }
}
// #endregion
