import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../catalog/test_id.dart';

// #region shared
/// One section of an accordion: the header's title, and what its panel
/// holds, a line of text and a button.
typedef Section = ({String key, String title, String text, String action});

/// The two sections of every example. Both start collapsed.
const sections = <Section>[
  (
    key: 'shipping',
    title: 'Shipping',
    text: 'Orders ship in two days.',
    action: 'Track a parcel',
  ),
  (
    key: 'returns',
    title: 'Returns',
    text: 'Return items within 30 days.',
    action: 'Start a return',
  ),
];

/// The heading level of a header: the example screen's "Example" heading is
/// level 2.
const headerLevel = 3;

/// What a header looks like, and what a tap and the keys call. [open] is
/// the section's state; [toggle] opens or closes it.
typedef HeaderBuilder = Widget Function(
  BuildContext context,
  Section section,
  bool open,
  VoidCallback toggle,
);

/// Lays out an accordion of [sections], with the header [header] builds
/// for each and, while a section is open, its panel straight after it. A
/// closed panel is not built, so it is in neither the semantics tree nor
/// the focus order. The count after the accordion says how often a panel
/// button was pressed, so people and tests can tell that a key reached one.
class Accordion extends StatefulWidget {
  const Accordion({
    super.key,
    required this.slug,
    required this.header,
    this.panels,
  });

  final String slug;
  final HeaderBuilder header;

  /// Builds the panels in place of the default: `bad-hidden-panel` keeps
  /// closed ones, and the two SDK tiles build none, as each tile has its
  /// own.
  final Widget Function(
    BuildContext context,
    Section section,
    bool open,
    Widget panel,
  )?
  panels;

  @override
  State<Accordion> createState() => _AccordionState();
}

class _AccordionState extends State<Accordion> {
  final _open = <String>{};
  int _presses = 0;

  void _toggle(String key) =>
      setState(() => _open.contains(key) ? _open.remove(key) : _open.add(key));

  /// A panel is a node of its own, with an identifier ([panelId]) that its
  /// header's `controlsNodes` names. Its text is a node of its own too: left
  /// to merge, it would become the panel's name, and on the web the panel a
  /// group named by it.
  Widget _panel(Section section) => Semantics(
    identifier: panelId(headerId(widget.slug, section)),
    container: true,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(container: true, child: Text(section.text)),
          TextButton(
            onPressed: () => setState(() => _presses++),
            child: Text(section.action),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final panels = widget.panels;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final s in sections) ...[
          widget.header(
            context,
            s,
            _open.contains(s.key),
            () => _toggle(s.key),
          ),
          if (panels != null)
            panels(context, s, _open.contains(s.key), _panel(s))
          else if (_open.contains(s.key))
            _panel(s),
        ],
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Semantics(
            key: ValueKey<String>('c05-${widget.slug}-count'),
            identifier: 'c05-${widget.slug}-count',
            child: Text('Presses: $_presses'),
          ),
        ),
      ],
    );
  }
}

/// The test identifier of a header: `c05-good-material-shipping`.
String headerId(String slug, Section section) => 'c05-$slug-${section.key}';

/// The identifier of the panel of the header [header]:
/// `c05-good-material-shipping-panel`.
String panelId(String header) => '$header-panel';

/// Setting it only while open has no source: it is of this project's own
/// design, measured but not taken from APG, the reference repositories, or
/// Flutter's documentation. `aria-controls` itself is APG's.
///
/// What a header controls: its panel, while it is open. On the web this is
/// `aria-controls`. The web engine writes it only if the panel's node is
/// there when the header's `controlsNodes` is set, so it is set when the
/// panel opens and taken away when it closes (FL-266). Android and iOS do
/// not read it.
Set<String>? controls(String header, bool open) =>
    open ? {panelId(header)} : null;

/// No source: this is of this project's own design, measured but not taken
/// from APG, the reference repositories, or Flutter's documentation.
///
/// What VoiceOver on iOS is given for the state. The iOS engine does not
/// pass `expanded` to iOS (docs/flutter-limitations.md, FL-260), so on iOS
/// the state goes in the header's value as well, which VoiceOver reads after
/// the name. Elsewhere `expanded` alone carries it: on Android and the web a
/// value would be read as part of the name, beside the state.
String? iosStateValue(bool open) =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
    ? (open ? 'expanded' : 'collapsed')
    : null;

/// Part of the custom solution of the good examples (not vetted by a
/// real-world example; docs/specs/C05-accordion.md, "Custom solutions").
///
/// What a header is to assistive technology: one node that is a button,
/// with the section's title as its name, an expanded state, and the heading
/// of its section.
///
/// - `expanded` gives the state: `aria-expanded` on the web, and on Android
///   16 and later the node's expanded state (FL-261 for earlier versions).
/// - `onTapHint` makes TalkBack say "Double-tap to expand" or "to
///   collapse", as the Android Compose reference does with `onClickLabel`.
/// - `onExpand` while closed and `onCollapse` while open: Android's expand
///   and collapse actions, which both Android references give a header.
///   The engine passes them on Android 16 and later only (FL-261).
/// - On iOS the state is also the value ([iosStateValue]).
/// - `controlsNodes` names the open panel ([controls]).
/// - The heading: on Android and iOS on the button's own node. On the web a
///   heading node is never a button (FL-262), so there the heading is a node
///   of its own that holds the button, as in APG's `<h3><button>`.
///
/// [TestId] merges [child], which takes the taps and the keys, into the
/// node.
class HeaderSemantics extends StatelessWidget {
  const HeaderSemantics({
    super.key,
    required this.id,
    required this.open,
    required this.toggle,
    required this.child,
  });

  final String id;
  final bool open;

  /// Opens or closes the section, for the expand and collapse actions.
  final VoidCallback toggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final header = TestId(
      id,
      child: Semantics(
        button: true,
        expanded: open,
        headingLevel: kIsWeb ? null : headerLevel,
        value: iosStateValue(open),
        onTapHint: open ? 'collapse' : 'expand',
        onExpand: open ? null : toggle,
        onCollapse: open ? toggle : null,
        controlsNodes: controls(id, open),
        child: child,
      ),
    );
    if (!kIsWeb) return header;
    return Semantics(container: true, headingLevel: headerLevel, child: header);
  }
}

/// The look of a header's title: the theme's title style, as section
/// headings have.
TextStyle? titleStyle(BuildContext context) =>
    Theme.of(context).textTheme.titleMedium;

/// A title for a Cupertino list tile, which cuts its title to one line with
/// an ellipsis (a `DefaultTextStyle` with `maxLines: 1`, as C03 found). A
/// `DefaultTextStyle` of the title's own, with no line limit, lets it wrap
/// at large text sizes.
/// With [headingStyle] false the tile's own text style is kept.
Widget wrappingTitle(String title, {bool headingStyle = true}) => Builder(
  builder: (context) {
    final tile = DefaultTextStyle.of(context);
    return DefaultTextStyle(
      style: tile.style,
      textAlign: tile.textAlign,
      child: Text(title, style: headingStyle ? titleStyle(context) : null),
    );
  },
);

/// A 3 pixel ring in the colour of the page's text round [child] while
/// focus is on it or inside it, as in V14 and C03: the Material and
/// Cupertino list tiles' own focus look is under 3:1 or none at all
/// (docs/flutter-limitations.md, FL-430 and FL-400). The `Focus` here takes
/// no focus itself; it only hears when the header inside it gains or loses
/// focus.
class FocusRing extends StatefulWidget {
  const FocusRing({super.key, required this.child});

  final Widget child;

  @override
  State<FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<FocusRing> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onFocusChange: (value) => setState(() => _focused = value),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: _focused ? colors.onSurface : Colors.transparent,
            width: 3,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

/// Gives [child], which takes the taps, keyboard focus: Enter and Space
/// call [onActivate], on every platform. It gives no role, name, or state;
/// [HeaderSemantics] does.
class KeyboardHeader extends StatelessWidget {
  const KeyboardHeader({
    super.key,
    required this.onActivate,
    required this.child,
  });

  final VoidCallback onActivate;
  final Widget child;

  Object? _activate(Intent intent) {
    onActivate();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // The ring goes outside the detector, whose own node takes the focus.
    return FocusRing(
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: _activate),
          ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
            onInvoke: _activate,
          ),
        },
        child: child,
      ),
    );
  }
}

/// A header built from the widgets layer: [KeyboardHeader] round a
/// `GestureDetector`, the title, and an arrow that points down while closed
/// and up while open. The arrow has no semantics of its own: the state is
/// the header's.
Widget plainHeader(
  BuildContext context,
  Section section,
  bool open,
  VoidCallback toggle,
) {
  return KeyboardHeader(
    onActivate: toggle,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: toggle,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(child: Text(section.title, style: titleStyle(context))),
            Icon(open ? Icons.expand_less : Icons.expand_more),
          ],
        ),
      ),
    ),
  );
}
// #endregion

// #region good-material
/// Each header is a Material `ListTile`, which is a button with keyboard
/// focus and takes Enter and Space, inside [HeaderSemantics]. Material's
/// own `ExpansionTile` is not used: its header has no expanded state, and
/// on Android and iOS no button role (`bad-expansion-tile`).
///
/// Custom solution: not vetted by a real-world example. It is tested here in
/// isolation, with screen-reader transcripts, but has not been built into a
/// real app and tested in a user journey. Do not treat it as a vetted
/// technique. No Flutter accordion widget meets the requirements through its
/// own parameters (docs/flutter-limitations.md, FL-264, FL-265, FL-267).
class GoodMaterial extends StatelessWidget {
  const GoodMaterial({super.key});

  @override
  Widget build(BuildContext context) {
    return Accordion(
      slug: 'good-material',
      header: (context, section, open, toggle) => HeaderSemantics(
        id: headerId('good-material', section),
        open: open,
        toggle: toggle,
        child: FocusRing(
          child: ListTile(
            title: Text(section.title, style: titleStyle(context)),
            trailing: Icon(open ? Icons.expand_less : Icons.expand_more),
            onTap: toggle,
          ),
        ),
      ),
    );
  }
}
// #endregion

// #region good-cupertino
/// Each header is a `CupertinoListTile` with a chevron that turns down
/// while open, given keyboard focus by [KeyboardHeader] (the tile takes
/// none, FL-400), inside [HeaderSemantics]. Cupertino's own
/// `CupertinoExpansionTile` is not used: a keyboard cannot reach its
/// headers (`bad-cupertino-expansion-tile`).
///
/// Custom solution: not vetted by a real-world example. It is tested here in
/// isolation, with screen-reader transcripts, but has not been built into a
/// real app and tested in a user journey. Do not treat it as a vetted
/// technique. No Flutter accordion widget meets the requirements through its
/// own parameters (docs/flutter-limitations.md, FL-264, FL-265, FL-267).
class GoodCupertino extends StatelessWidget {
  const GoodCupertino({super.key});

  @override
  Widget build(BuildContext context) {
    return Accordion(
      slug: 'good-cupertino',
      header: (context, section, open, toggle) => HeaderSemantics(
        id: headerId('good-cupertino', section),
        open: open,
        toggle: toggle,
        child: KeyboardHeader(
          onActivate: toggle,
          child: CupertinoListTile(
            title: wrappingTitle(section.title),
            trailing: Icon(
              open ? CupertinoIcons.chevron_down : CupertinoIcons.chevron_right,
            ),
            onTap: toggle,
          ),
        ),
      ),
    );
  }
}
// #endregion

// #region good-custom
/// Each header is built from the widgets layer ([plainHeader]) inside
/// [HeaderSemantics].
///
/// Custom solution: not vetted by a real-world example. It is tested here in
/// isolation, with screen-reader transcripts, but has not been built into a
/// real app and tested in a user journey. Do not treat it as a vetted
/// technique. No Flutter accordion widget meets the requirements through its
/// own parameters (docs/flutter-limitations.md, FL-264, FL-265, FL-267).
class GoodCustom extends StatelessWidget {
  const GoodCustom({super.key});

  @override
  Widget build(BuildContext context) {
    return Accordion(
      slug: 'good-custom',
      header: (context, section, open, toggle) => HeaderSemantics(
        id: headerId('good-custom', section),
        open: open,
        toggle: toggle,
        child: plainHeader(context, section, open, toggle),
      ),
    );
  }
}
// #endregion

// #region bad-no-state
class BadNoState extends StatelessWidget {
  const BadNoState({super.key});

  @override
  Widget build(BuildContext context) {
    return Accordion(
      slug: 'bad-no-state',
      header: (context, section, open, toggle) => Semantics(
        container: kIsWeb,
        headingLevel: kIsWeb ? headerLevel : null,
        child: TestId(
          headerId('bad-no-state', section),
          // Defect: a button and a heading with no expanded state. Only the
          // arrow, which assistive technology does not see, shows whether
          // the section is open.
          child: Semantics(
            button: true,
            headingLevel: kIsWeb ? null : headerLevel,
            controlsNodes: controls(headerId('bad-no-state', section), open),
            child: plainHeader(context, section, open, toggle),
          ),
        ),
      ),
    );
  }
}
// #endregion

// #region bad-heading-on-button
class BadHeadingOnButton extends StatelessWidget {
  const BadHeadingOnButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Accordion(
      slug: 'bad-heading-on-button',
      header: (context, section, open, toggle) => TestId(
        headerId('bad-heading-on-button', section),
        // Defect: the heading is on the button's own node on the web too.
        // There a heading node is never a button: the header is a heading
        // only, with no button role and no expanded state (FL-262).
        child: Semantics(
          button: true,
          expanded: open,
          headingLevel: headerLevel,
          value: iosStateValue(open),
          onTapHint: open ? 'collapse' : 'expand',
          onExpand: open ? null : toggle,
          onCollapse: open ? toggle : null,
          controlsNodes: controls(
            headerId('bad-heading-on-button', section),
            open,
          ),
          child: plainHeader(context, section, open, toggle),
        ),
      ),
    );
  }
}
// #endregion

// #region bad-no-heading
class BadNoHeading extends StatelessWidget {
  const BadNoHeading({super.key});

  @override
  Widget build(BuildContext context) {
    return Accordion(
      slug: 'bad-no-heading',
      header: (context, section, open, toggle) => TestId(
        headerId('bad-no-heading', section),
        // Defect: the header is drawn as a section heading, in the title
        // style, but it is not a heading.
        child: Semantics(
          button: true,
          expanded: open,
          value: iosStateValue(open),
          onTapHint: open ? 'collapse' : 'expand',
          onExpand: open ? null : toggle,
          onCollapse: open ? toggle : null,
          controlsNodes: controls(headerId('bad-no-heading', section), open),
          child: plainHeader(context, section, open, toggle),
        ),
      ),
    );
  }
}
// #endregion

// #region bad-hidden-panel
class BadHiddenPanel extends StatelessWidget {
  const BadHiddenPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Accordion(
      slug: 'bad-hidden-panel',
      header: (context, section, open, toggle) => HeaderSemantics(
        id: headerId('bad-hidden-panel', section),
        open: open,
        toggle: toggle,
        child: plainHeader(context, section, open, toggle),
      ),
      // Defect: a closed panel is kept, hidden with Offstage, as the
      // widgets layer's Expansible does by default (maintainState: true).
      // Offstage leaves it out of the semantics tree and paints nothing,
      // but its button keeps keyboard focus, so Tab goes into the closed
      // sections (FL-263).
      panels: (context, section, open, panel) =>
          Offstage(offstage: !open, child: panel),
    );
  }
}
// #endregion

// #region bad-expansion-tile
class BadExpansionTile extends StatelessWidget {
  const BadExpansionTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Accordion(
      slug: 'bad-expansion-tile',
      // Defect: Material's ExpansionTile, as it comes. On Android and iOS
      // its header is not a button (FL-264). It has other shortcomings,
      // which the spec lists: no expanded state, only "Expanded" or
      // "Collapsed" as a hint. The tile has its own panel, so the
      // accordion's is not used.
      // No TestId: its MergeSemantics would take the tile's panel into the
      // header. The headers are found by their text.
      // The title keeps the tile's own text style: drawn as a section
      // heading, it would fail for not being one as well.
      header: (context, section, open, toggle) => ExpansionTile(
        title: Text(section.title),
        children: [_TilePanel(section: section)],
      ),
      panels: (context, section, open, panel) => const SizedBox.shrink(),
    );
  }
}

/// The panel of `bad-expansion-tile` and `bad-cupertino-expansion-tile`:
/// the same text as the others, and no button, so that a closed panel has
/// nothing that could take keyboard focus.
class _TilePanel extends StatelessWidget {
  const _TilePanel({required this.section});

  final Section section;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(section.text),
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
    return Accordion(
      slug: 'bad-cupertino-expansion-tile',
      // Defect: Cupertino's CupertinoExpansionTile, as it comes. Its header
      // is a CupertinoListTile, which takes no keyboard focus, so a
      // keyboard cannot open a section (FL-265). Its other shortcomings,
      // which the spec lists: no button role on Android and iOS, no
      // expanded state, and once open its panel's text joins its name.
      // No TestId, as in bad-expansion-tile.
      // The tile's own text style, as in bad-expansion-tile.
      header: (context, section, open, toggle) => CupertinoExpansionTile(
        title: wrappingTitle(section.title, headingStyle: false),
        child: _TilePanel(section: section),
      ),
      panels: (context, section, open, panel) => const SizedBox.shrink(),
    );
  }
}
// #endregion
