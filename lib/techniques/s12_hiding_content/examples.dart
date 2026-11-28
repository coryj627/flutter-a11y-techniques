import 'package:flutter/material.dart';

import '../../catalog/test_id.dart';

// Every good example is Flutter's own widgets used through their documented
// parameters: `ExcludeSemantics` round what only decorates or repeats, and
// `Visibility` for what is closed and meant to be unavailable to everyone. What they cannot do is in
// docs/flutter-limitations.md and is not built here.

// #region shared
/// The quote the decoration examples show, and who said it.
const quoteText = 'Walk the ridge before the sun is up.';
const quoteSource = 'Trail guide';

/// The ornaments drawn round the quote: text that only decorates.
const quoteMark = '❝';
const ornament = '✦ ✦ ✦';

/// What the badge example's text says beside the badge.
const inboxText = 'Inbox: 3 unread';

/// The tracking number the panel examples hide and show.
const trackingText = 'Tracking number: 1Z 999';

/// A 2 pixel outline in the page's text colour while a Material button has
/// keyboard focus, through the button's own `style`, as in C18: Material's
/// own focus tint on a `TextButton` is under 3:1 against the page
/// (docs/flutter-limitations.md, FL-430).
ButtonStyle focusRing(ColorScheme colors) => ButtonStyle(
  side: WidgetStateProperty.resolveWith(
    (states) => states.contains(WidgetState.focused)
        ? BorderSide(color: colors.onSurface, width: 2)
        : null,
  ),
);

/// A count under an example, so that people and tests can confirm which
/// action ran: "Shares: 1". [id] is its test identifier.
class Count extends StatelessWidget {
  const Count({super.key, required this.id, required this.text});

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

/// The quote between its ornaments. [hide] wraps each ornament: the good
/// example hides them, the bad one leaves them as they are.
class Quote extends StatelessWidget {
  const Quote({super.key, required this.hide});

  final Widget Function(Widget ornament) hide;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            hide(Text(quoteMark, style: text.headlineMedium)),
            Expanded(child: Text(quoteText, style: text.titleMedium)),
          ],
        ),
        Text(quoteSource, style: text.bodyMedium),
        hide(Text(ornament, style: text.bodyLarge)),
      ],
    );
  }
}

/// A switch that shows the tracking number, the panel with the number and a
/// button that copies it, and a count of the copies. [hide] places the
/// panel and hides it while the switch is off: each panel example hides it
/// a different way.
class TrackingDemo extends StatefulWidget {
  const TrackingDemo({super.key, required this.slug, required this.hide});

  final String slug;
  final Widget Function(bool shown, Widget panel) hide;

  @override
  State<TrackingDemo> createState() => _TrackingDemoState();
}

class _TrackingDemoState extends State<TrackingDemo> {
  var _shown = false;
  var _copies = 0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final slug = widget.slug;
    final panel = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(trackingText),
        TestId(
          's12-$slug-copy',
          child: TextButton(
            style: focusRing(colors),
            onPressed: () => setState(() => _copies++),
            child: const Text('Copy number'),
          ),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        TestId(
          's12-$slug-show',
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Show tracking'),
            value: _shown,
            onChanged: (v) => setState(() => _shown = v),
          ),
        ),
        widget.hide(_shown, panel),
        Count(id: 's12-$slug-count', text: 'Copies: $_copies'),
      ],
    );
  }
}
// #endregion

// #region good-decoration
/// The quote's ornaments are characters that express nothing in human
/// language, which WCAG counts as non-text content, and they only decorate:
/// each is in `ExcludeSemantics`, so a screen reader reads the quote and who
/// said it, and nothing else, as 1.1.1 asks of pure decoration.
class GoodDecoration extends StatelessWidget {
  const GoodDecoration({super.key});

  @override
  Widget build(BuildContext context) {
    return Quote(hide: (ornament) => ExcludeSemantics(child: ornament));
  }
}
// #endregion

// #region good-badge
/// The badge's "3" repeats the "3 unread" beside it: the badge is in
/// `ExcludeSemantics`, so the count is read once, in the words beside it.
/// The mail icon has no `semanticLabel`, so `Icon` gives it no semantics.
class GoodBadge extends StatelessWidget {
  const GoodBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      spacing: 16,
      children: [
        ExcludeSemantics(
          child: Badge(label: Text('3'), child: Icon(Icons.mail_outline)),
        ),
        Expanded(child: Text(inboxText)),
      ],
    );
  }
}
// #endregion

// #region good-visibility
/// While the switch is off the panel is hidden from everyone with
/// `Visibility`: it is not drawn, has no semantics, and, because
/// `Visibility` puts it in an `ExcludeFocus` while it is hidden, the
/// keyboard does not reach its button. `maintainState` keeps the panel's
/// state while it is hidden.
class GoodVisibility extends StatelessWidget {
  const GoodVisibility({super.key});

  @override
  Widget build(BuildContext context) {
    return TrackingDemo(
      slug: 'good-visibility',
      hide: (shown, panel) =>
          Visibility(visible: shown, maintainState: true, child: panel),
    );
  }
}
// #endregion

// #region bad-decoration-read
/// The ornaments are left as they are: a screen reader stops on each one,
/// around the quote, and reads it as text. This is not a shown failure of a success criterion in this technique's list; shown for what the user hears.
/// It fails 1.1.1, outside that list: the ornaments are non-text content
/// and pure decoration that assistive technology cannot ignore.
class BadDecorationRead extends StatelessWidget {
  const BadDecorationRead({super.key});

  @override
  Widget build(BuildContext context) {
    return Quote(hide: (ornament) => ornament);
  }
}
// #endregion

// #region bad-hidden-control
/// The ornament and the Share button are in one `ExcludeSemantics`: the
/// ornament is hidden, and so is the button. A screen reader cannot find it,
/// and the keyboard still reaches it.
class BadHiddenControl extends StatefulWidget {
  const BadHiddenControl({super.key});

  @override
  State<BadHiddenControl> createState() => _BadHiddenControlState();
}

class _BadHiddenControlState extends State<BadHiddenControl> {
  var _shares = 0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(quoteText, style: Theme.of(context).textTheme.titleMedium),
        ExcludeSemantics(
          child: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(ornament, style: Theme.of(context).textTheme.bodyLarge),
              TextButton(
                key: const ValueKey<String>('s12-bad-hidden-control-share'),
                style: focusRing(colors),
                onPressed: () => setState(() => _shares++),
                child: const Text('Share'),
              ),
            ],
          ),
        ),
        Count(id: 's12-bad-hidden-control-count', text: 'Shares: $_shares'),
      ],
    );
  }
}
// #endregion

// #region bad-opacity
/// While the switch is off the panel is hidden with `Opacity` at 0: it is
/// not drawn and has no semantics, but its button keeps keyboard focus, and
/// Enter copies the number.
class BadOpacity extends StatelessWidget {
  const BadOpacity({super.key});

  @override
  Widget build(BuildContext context) {
    return TrackingDemo(
      slug: 'bad-opacity',
      hide: (shown, panel) => Opacity(opacity: shown ? 1 : 0, child: panel),
    );
  }
}
// #endregion

// #region bad-maintain
/// While the switch is off the panel is hidden with `Visibility.maintain`:
/// it is not drawn, but its semantics are kept, so a screen reader reads
/// the number and the button, and the keyboard reaches the button. This is
/// not a shown failure of a success criterion in this technique's list; shown for what the user hears; the 2.4.7 failure of its invisible focus was measured in
/// widget tests only and is outside S12's list.
class BadMaintain extends StatelessWidget {
  const BadMaintain({super.key});

  @override
  Widget build(BuildContext context) {
    return TrackingDemo(
      slug: 'bad-maintain',
      hide: (shown, panel) => Visibility.maintain(visible: shown, child: panel),
    );
  }
}
// #endregion
