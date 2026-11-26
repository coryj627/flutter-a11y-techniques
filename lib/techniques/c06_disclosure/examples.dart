import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Every example is a Flutter widget for the pattern, used through its own
// parameters; nothing is built round it. What none of them gives is in
// docs/flutter-limitations.md and is not built here: none of Flutter's
// widgets for a disclosure measured here exposes an expanded or collapsed
// state, on Android 17, iOS 27.0, or the web (FL-264, FL-265, FL-267);
// `ExpansionTile` gives the state only as text.
//
// No example uses `TestId`: its `MergeSemantics` would take the open panel
// into the control's node. The controls are found by their text.

// #region shared
/// What the control is named, and what its panel holds.
const disclosureTitle = 'Details';
const panelText = 'Orders ship in two days.';
const panelAction = 'Change address';

/// Lays out one example: the disclosure, and under it a count of the
/// presses of the panel's button, so that people and tests can tell that a
/// key reached the button once the panel is open.
class _Demo extends StatefulWidget {
  const _Demo({required this.slug, required this.builder});

  final String slug;
  final Widget Function(BuildContext context, VoidCallback press) builder;

  @override
  State<_Demo> createState() => _DemoState();
}

class _DemoState extends State<_Demo> {
  int _presses = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.builder(context, () => setState(() => _presses++)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Semantics(
            key: ValueKey<String>('c06-${widget.slug}-count'),
            identifier: 'c06-${widget.slug}-count',
            child: Text('Presses: $_presses'),
          ),
        ),
      ],
    );
  }
}

/// The panel: a line of text and a button, at the start of the line.
/// [onPressed] null leaves the button out (`bad-cupertino-expansion-tile`).
class _Panel extends StatelessWidget {
  const _Panel({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final press = onPressed;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(panelText),
            if (press != null)
              TextButton(onPressed: press, child: const Text(panelAction)),
          ],
        ),
      ),
    );
  }
}
// #endregion

// #region good-material
/// Material's `ExpansionTile` with `internalAddSemanticForOnTap: true`, a
/// documented parameter that makes its header a button on Android and iOS
/// (without it the header is a button on the web only, FL-264). The
/// documentation calls that parameter "a temporary flag to help changing
/// the behavior of ListTile onTap semantics", so it may change or go.
/// The tile's own panel is built only while it is open (`maintainState`
/// false, its default).
///
/// Good with a limitation, on every platform: the tile exposes no expanded
/// state. It says "Collapsed" or "Expanded" only as text: at the end of
/// the name on Android, as a hint on iOS, and as the accessible description
/// on the web (FL-264); that text is not counted as meeting 4.1.2. Its
/// focus tint is ListTile's, under 3:1 (FL-430).
class GoodMaterial extends StatelessWidget {
  const GoodMaterial({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-material',
      builder: (context, press) => ExpansionTile(
        internalAddSemanticForOnTap: true,
        title: const Text(disclosureTitle),
        children: [_Panel(onPressed: press)],
      ),
    );
  }
}
// #endregion

// #region bad-expansion-tile
class BadExpansionTile extends StatelessWidget {
  const BadExpansionTile({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-expansion-tile',
      // Defect: `ExpansionTile` as it comes. `internalAddSemanticForOnTap`
      // is false by default, so on Android and iOS the header is not a
      // button (FL-264). On the web it is one, as any tappable node is
      // (FL-006).
      builder: (context, press) => ExpansionTile(
        title: const Text(disclosureTitle),
        children: [_Panel(onPressed: press)],
      ),
    );
  }
}
// #endregion

// #region bad-expand-icon
class BadExpandIcon extends StatefulWidget {
  const BadExpandIcon({super.key});

  @override
  State<BadExpandIcon> createState() => _BadExpandIconState();
}

class _BadExpandIconState extends State<BadExpandIcon> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-expand-icon',
      // Defect: Material's `ExpandIcon`, combined with its label in a
      // `MergeSemantics` as its documentation says. The button is named by
      // the label, and nothing says whether the panel is open, not even in
      // words: `ExpandIcon` sets no state and no hint, only a tap hint,
      // "Expand" or "Collapse" (FL-267). Only the icon takes pointer input:
      // a tap on the label opens nothing, except on the web, where a click
      // there is taken by the button's element (FL-411).
      builder: (context, press) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MergeSemantics(
            child: Row(
              children: [
                const SizedBox(width: 16),
                const Expanded(child: Text(disclosureTitle)),
                ExpandIcon(
                  isExpanded: _open,
                  onPressed: (wasOpen) => setState(() => _open = !wasOpen),
                ),
              ],
            ),
          ),
          if (_open) _Panel(onPressed: press),
        ],
      ),
    );
  }
}
// #endregion

// #region bad-cupertino-expansion-tile
class BadCupertinoExpansionTile extends StatelessWidget {
  const BadCupertinoExpansionTile({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-cupertino-expansion-tile',
      // Defect: `CupertinoExpansionTile` as it comes. Its header is a
      // `CupertinoListTile`, which takes no keyboard focus, so a keyboard
      // cannot open it (FL-265). Its panel has no button: the tile keeps a
      // closed panel `Offstage`, where a button would still take keyboard
      // focus (FL-263), a second defect.
      builder: (context, press) => const CupertinoExpansionTile(
        title: Text(disclosureTitle),
        child: _Panel(),
      ),
    );
  }
}
// #endregion
