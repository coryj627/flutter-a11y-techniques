import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../catalog/test_id.dart';

// Every example is Flutter's own `Tooltip`, configured only through its own
// parameters. What it cannot do is in docs/flutter-limitations.md and is not
// built here: it does not show on keyboard focus (FL-248); while it is shown
// its text is a node of its own (FL-249); and on the web Escape does not
// hide it while the page has no focus (FL-482).

// #region shared
/// Lays out one example: the control, a line of text that the tooltip lies
/// over while it is shown, and a count of the control's activations, so
/// that people and tests can confirm the control still works.
class _Demo extends StatefulWidget {
  const _Demo({required this.slug, required this.line, required this.builder});

  final String slug;
  final String line;
  final Widget Function(BuildContext context, VoidCallback activate) builder;

  @override
  State<_Demo> createState() => _DemoState();
}

class _DemoState extends State<_Demo> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        widget.builder(context, () => setState(() => _count++)),
        Text(widget.line),
        Semantics(
          key: ValueKey<String>('c12-${widget.slug}-count'),
          identifier: 'c12-${widget.slug}-count',
          liveRegion: true,
          child: Text('Activations: $_count'),
        ),
      ],
    );
  }
}

/// A 2 pixel outline in the page's text colour while a Material button has
/// keyboard focus, through the button's own `style`. Material's own focus
/// tint on an `IconButton` is under 3:1 against the page
/// (docs/flutter-limitations.md, FL-430).
ButtonStyle focusRing(ColorScheme colors) => ButtonStyle(
  side: WidgetStateProperty.resolveWith(
    (states) => states.contains(WidgetState.focused)
        ? BorderSide(color: colors.onSurface, width: 2)
        : null,
  ),
);
// #endregion

// #region good-material
/// An icon button with Material's `Tooltip`. `ignorePointer: false` lets
/// the pointer move onto the tooltip; a `Tooltip` with a plain message
/// ignores the pointer by default, and `IconButton.tooltip` always does
/// (FL-247). A Material button is a semantics container, so a tooltip round
/// it does not reach it (FL-040); the button is named by its icon's label,
/// and `excludeFromSemantics: true` leaves Tooltip's own copy out, as its
/// documentation says to when the app gives the label.
class GoodMaterial extends StatelessWidget {
  const GoodMaterial({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-material',
      line: 'Drafts are kept for 30 days.',
      builder: (context, activate) => TestId(
        'c12-good-material-delete',
        child: Tooltip(
          message: 'Delete draft',
          ignorePointer: false,
          excludeFromSemantics: true,
          child: IconButton(
            onPressed: activate,
            style: focusRing(Theme.of(context).colorScheme),
            icon: const Icon(
              Icons.delete_outline,
              semanticLabel: 'Delete draft',
            ),
          ),
        ),
      ),
    );
  }
}
// #endregion

// #region good-cupertino
/// Cupertino has no tooltip widget, so this is Material's `Tooltip` on an
/// icon-only `CupertinoButton`. A `CupertinoButton` is not a semantics
/// container, so the tooltip reaches it and is its name, as
/// `IconButton.tooltip` names an `IconButton`.
class GoodCupertino extends StatelessWidget {
  const GoodCupertino({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-cupertino',
      line: 'Drafts are kept for 30 days.',
      builder: (context, activate) => TestId(
        'c12-good-cupertino-delete',
        child: Tooltip(
          message: 'Delete draft',
          ignorePointer: false,
          // A CupertinoButton is 52.4 high, so Material's default of 24
          // from the centre puts the box 2.2 over the button's edge, and
          // with the pointer there Escape does not hold (FL-250). 28 leaves
          // a gap of 1.8, below and, flipped, above.
          verticalOffset: 28,
          // Flutter 3.47.5: on the web Enter is ButtonActivateIntent, which
          // CupertinoButton does not handle (FL-002, as in C01's
          // good-cupertino); Space works.
          child: Actions(
            actions: {
              ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
                onInvoke: (_) {
                  activate();
                  return null;
                },
              ),
            },
            child: CupertinoButton(
              onPressed: activate,
              // Cupertino's default focus ring is under 3:1 on a light page
              // (FL-431).
              focusColor: CupertinoColors.label.resolveFrom(context),
              child: const Icon(CupertinoIcons.delete),
            ),
          ),
        ),
      ),
    );
  }
}
// #endregion

// #region good-description
/// A tooltip that describes a button with a name of its own: "Download"
/// saves a PDF copy. `MergeSemantics` puts the tooltip on the Material
/// button (FL-040). TalkBack reads it after the button's role; on iOS and
/// the web it joins the button's name, after it on iOS and before it on the
/// web (FL-251). Good with a qualification: the description is on screen
/// only in the tooltip, which no key shows (FL-248), so a sighted keyboard
/// user cannot get it, and it fails 2.1.1 for the description wherever a
/// keyboard is used.
class GoodDescription extends StatelessWidget {
  const GoodDescription({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-description',
      line: 'The file is 2 MB.',
      builder: (context, activate) => TestId(
        'c12-good-description-download',
        child: MergeSemantics(
          child: Tooltip(
            message: 'Saves a PDF copy',
            ignorePointer: false,
            child: OutlinedButton(
              onPressed: activate,
              style: focusRing(Theme.of(context).colorScheme),
              child: const Text('Download'),
            ),
          ),
        ),
      ),
    );
  }
}
// #endregion

// #region bad-not-hoverable
/// `IconButton(tooltip:)`, as it comes. Its tooltip takes no pointer
/// events, so a pointer that moves onto it has left the button, and the
/// tooltip goes.
class BadNotHoverable extends StatelessWidget {
  const BadNotHoverable({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-not-hoverable',
      line: 'Drafts are kept for 30 days.',
      builder: (context, activate) => TestId(
        'c12-bad-not-hoverable-delete',
        child: IconButton(
          onPressed: activate,
          // Defect: IconButton's tooltip ignores the pointer, and nothing
          // in IconButton changes that.
          tooltip: 'Delete draft',
          style: focusRing(Theme.of(context).colorScheme),
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }
}
// #endregion

// #region bad-hover-only
/// The rule for a password is only in the tooltip of an information icon,
/// Tooltip's own way of explaining an icon. A pointer or a long press shows
/// it. The icon takes no keyboard focus, so a keyboard cannot; and the
/// icon's node has the tooltip and nothing else, which VoiceOver on iOS
/// does not stop on (FL-252). TalkBack and the web's tree have it.
class BadHoverOnly extends StatelessWidget {
  const BadHoverOnly({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-hover-only',
      line: 'You can change it later.',
      builder: (context, activate) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          const Row(
            spacing: 8,
            children: [
              Flexible(child: Text('Password rules')),
              // Defect: the rule is only here, and nothing here takes
              // keyboard focus.
              TestId(
                'c12-bad-hover-only-info',
                child: Tooltip(
                  message: 'At least 8 characters',
                  ignorePointer: false,
                  child: Icon(Icons.info_outline),
                ),
              ),
            ],
          ),
          TestId(
            'c12-bad-hover-only-sign-up',
            child: FilledButton(
              onPressed: activate,
              child: const Text('Sign up'),
            ),
          ),
        ],
      ),
    );
  }
}
// #endregion

// #region bad-repeats-name
/// A tooltip with the button's own text. Tooltip gives its message to the
/// semantics tree as a tooltip, and on the web and on iOS that joins the
/// button's name: it is read "Download Download". `MergeSemantics` is what
/// puts the tooltip on the button at all (FL-040).
class BadRepeatsName extends StatelessWidget {
  const BadRepeatsName({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-repeats-name',
      line: 'The file is 2 MB.',
      builder: (context, activate) => TestId(
        'c12-bad-repeats-name-download',
        child: MergeSemantics(
          child: Tooltip(
            // Defect: the tooltip says only what the button says.
            message: 'Download',
            ignorePointer: false,
            child: OutlinedButton(
              onPressed: activate,
              style: focusRing(Theme.of(context).colorScheme),
              child: const Text('Download'),
            ),
          ),
        ),
      ),
    );
  }
}
// #endregion

// #region bad-outside-button
/// A `Tooltip` put round an `IconButton`, as one is put round any widget.
/// A Material button is a semantics container, so the tooltip's text stays
/// on a node of its own outside it, and the button has no name.
class BadOutsideButton extends StatelessWidget {
  const BadOutsideButton({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-outside-button',
      line: 'Drafts are kept for 30 days.',
      // No TestId: its MergeSemantics would put the tooltip on the button.
      // The container stands for a row or a card round the control; the
      // tooltip's node is that container's.
      builder: (context, activate) => Semantics(
        container: true,
        identifier: 'c12-bad-outside-button-tooltip',
        child: Tooltip(
          // Defect: the tooltip is outside the button's semantics.
          message: 'Delete draft',
          ignorePointer: false,
          child: IconButton(
            onPressed: activate,
            style: focusRing(Theme.of(context).colorScheme),
            icon: const Icon(Icons.delete_outline),
          ),
        ),
      ),
    );
  }
}
// #endregion
