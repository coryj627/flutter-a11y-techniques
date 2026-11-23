import 'package:flutter/material.dart';

import '../../catalog/test_id.dart';

// Every example is Flutter's own SnackBar or MaterialBanner, configured only
// through their own parameters; every one but bad-inline-banner is shown
// through the ScaffoldMessenger.
// What they cannot do is in docs/flutter-limitations.md and is not built
// here: no setting of the platform's or of assistive technology changes a
// SnackBar's time limit (FL-290); Escape closes neither, and Back takes the
// message to the screen under (FL-291). Cupertino has no widget for a
// transient message.

// #region shared
/// Lays out one example: a button that does something and shows a message
/// about it, and a line of the page that says what the button has done, so
/// that people and tests can confirm it worked.
class _Demo extends StatelessWidget {
  const _Demo({
    required this.slug,
    required this.action,
    required this.line,
    required this.onPressed,
    this.below,
  });

  final String slug;
  final String action;
  final String line;
  final void Function(BuildContext context) onPressed;

  /// What the example shows under its line, if anything.
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        TestId(
          'c13-$slug-show',
          child: OutlinedButton(
            onPressed: () => onPressed(context),
            style: focusRing(Theme.of(context).colorScheme.onSurface),
            child: Text(action),
          ),
        ),
        Semantics(
          key: ValueKey<String>('c13-$slug-count'),
          identifier: 'c13-$slug-count',
          child: Text(line),
        ),
        ?below,
      ],
    );
  }
}

/// A 2 pixel outline while a Material button has keyboard focus, through
/// the button's own `style`. Material's own focus tint on a `TextButton` is
/// under 3:1 against what is round it (docs/flutter-limitations.md, FL-430),
/// and the banner's action and the page's button use this.
ButtonStyle focusRing(Color color) => ButtonStyle(
  side: WidgetStateProperty.resolveWith(
    (states) => states.contains(WidgetState.focused)
        ? BorderSide(color: color, width: 2)
        : null,
  ),
);

/// A SnackBar's action, whose colours turn round while it has keyboard
/// focus, through `SnackBarAction`'s own `textColor` and `backgroundColor`,
/// which take a `WidgetStateColor`. Its default focus tint is under 3:1
/// (FL-430).
SnackBarAction undo(BuildContext context, VoidCallback onPressed) {
  final colors = Theme.of(context).colorScheme;
  bool focused(Set<WidgetState> states) => states.contains(WidgetState.focused);
  return SnackBarAction(
    label: 'Undo',
    onPressed: onPressed,
    textColor: WidgetStateColor.resolveWith(
      (states) =>
          focused(states) ? colors.inverseSurface : colors.inversePrimary,
    ),
    backgroundColor: WidgetStateColor.resolveWith(
      (states) => focused(states) ? colors.inversePrimary : Colors.transparent,
    ),
  );
}

/// Shows [bar] through [messenger], first clearing the queue and taking
/// away the message that is shown (`clearSnackBars`), so that a new message
/// is never queued behind one that stays (FL-293), and presses that come
/// while a message is still going out leave only the newest.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> _show(
  ScaffoldMessengerState messenger,
  SnackBar bar,
) {
  messenger.clearSnackBars();
  return messenger.showSnackBar(bar);
}

/// Tells, once a SnackBar shown by [_show] has been closed by its action,
/// what that action did. The new SnackBar is shown from the old one's
/// `closed` future and not from the action's `onPressed`: the action hides
/// the current SnackBar after `onPressed` returns, and with
/// `accessibleNavigation` on, that is a SnackBar shown there (FL-296).
void _tellAfterAction(
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> shown,
  ScaffoldMessengerState messenger,
  String text,
) {
  shown.closed.then((reason) {
    if (reason == SnackBarClosedReason.action) _show(messenger, _done(text));
  });
}

/// What an action that changes the page's line back says it did: a message
/// only, which goes after its default four seconds, as its news is on the
/// page too.
SnackBar _done(String text) => SnackBar(content: Text(text));
// #endregion

// #region good-action
/// A SnackBar with an action. A SnackBar with an action stays until it is
/// used or closed (`persist` defaults to true when there is an action), so
/// the action has no time limit. `showCloseIcon` gives it a Close button,
/// because Escape does not close it (FL-291). It is a live region: shown, it
/// is announced, and focus stays where it was.
/// Good with a qualification: Close shows keyboard focus only by a faint
/// tint, and no parameter changes it (FL-294), which fails 1.4.11 as FL-430
/// reads it, wherever a keyboard is used.
class GoodAction extends StatefulWidget {
  const GoodAction({super.key});

  @override
  State<GoodAction> createState() => _GoodActionState();
}

class _GoodActionState extends State<GoodAction> {
  int _archived = 0;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-action',
      action: 'Archive message',
      line: 'Archived: $_archived',
      onPressed: (context) {
        setState(() => _archived++);
        final messenger = ScaffoldMessenger.of(context);
        final shown = _show(
          messenger,
          SnackBar(
            content: Text('Message archived'),
            // The SnackBar follows the user to the screen under when they go
            // back (FL-291), where this screen is gone.
            action: undo(context, () {
              if (mounted) setState(() => _archived--);
            }),
            showCloseIcon: true,
            // The close icon's default focus tint is under 3:1 (FL-430);
            // its colour changes while it has keyboard focus.
            closeIconColor: WidgetStateColor.resolveWith(
              (states) => states.contains(WidgetState.focused)
                  ? Theme.of(context).colorScheme.inversePrimary
                  : Theme.of(context).colorScheme.onInverseSurface,
            ),
          ),
        );
        // What Undo did is told by a SnackBar too, as the line's change
        // alone is not announced.
        _tellAfterAction(shown, messenger, 'Archive undone');
      },
    );
  }
}
// #endregion

// #region good-message
/// A SnackBar with a message only, which goes after its default four
/// seconds. What it says is also on the page ("Drafts saved"), so its going
/// sets no time limit on finding it out (Understanding 2.2.1).
class GoodMessage extends StatefulWidget {
  const GoodMessage({super.key});

  @override
  State<GoodMessage> createState() => _GoodMessageState();
}

class _GoodMessageState extends State<GoodMessage> {
  int _saved = 0;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-message',
      action: 'Save draft',
      line: 'Drafts saved: $_saved',
      onPressed: (context) {
        setState(() => _saved++);
        _show(
          ScaffoldMessenger.of(context),
          SnackBar(content: Text('Draft saved')),
        );
      },
    );
  }
}
// #endregion

// #region good-banner
/// A MaterialBanner, shown through the ScaffoldMessenger, which makes it a
/// live region. It stays until its action is used; it has no time limit.
class GoodBanner extends StatefulWidget {
  const GoodBanner({super.key});

  @override
  State<GoodBanner> createState() => _GoodBannerState();
}

class _GoodBannerState extends State<GoodBanner> {
  bool _offline = false;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-banner',
      action: 'Go offline',
      line: _offline ? 'Status: offline' : 'Status: online',
      onPressed: (context) {
        setState(() => _offline = true);
        final messenger = ScaffoldMessenger.of(context);
        // clearMaterialBanners, as _show does for a SnackBar: presses that
        // come while a banner is going out leave only the newest.
        messenger
          ..clearMaterialBanners()
          ..showMaterialBanner(
            MaterialBanner(
              content: Text('You are offline.'),
              actions: [
                TextButton(
                  // Going online is told by a SnackBar, as the line's
                  // change alone is not announced.
                  onPressed: () {
                    if (mounted) setState(() => _offline = false);
                    messenger.clearMaterialBanners();
                    _show(messenger, _done('You are online.'));
                  },
                  style: focusRing(Theme.of(context).colorScheme.onSurface),
                  child: const Text('Go online'),
                ),
              ],
            ),
          );
      },
    );
  }
}
// #endregion

// #region bad-action-times-out
/// A SnackBar whose action goes with it after four seconds:
/// `persist: false` makes it time out though it has an action. Undo is the
/// only way to undo, and nothing lets the user turn the limit off, adjust
/// it, or extend it; a screen reader does not change it (FL-290).
class BadActionTimesOut extends StatefulWidget {
  const BadActionTimesOut({super.key});

  @override
  State<BadActionTimesOut> createState() => _BadActionTimesOutState();
}

class _BadActionTimesOutState extends State<BadActionTimesOut> {
  int _archived = 0;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-action-times-out',
      action: 'Archive message',
      line: 'Archived: $_archived',
      onPressed: (context) {
        setState(() => _archived++);
        final messenger = ScaffoldMessenger.of(context);
        final shown = _show(
          messenger,
          SnackBar(
            content: Text('Message archived'),
            action: undo(context, () {
              if (mounted) setState(() => _archived--);
            }),
            // Defect: the action times out with the message.
            persist: false,
          ),
        );
        _tellAfterAction(shown, messenger, 'Archive undone');
      },
    );
  }
}
// #endregion

// #region bad-only-in-message
/// A SnackBar that is the only place the booking code is shown, and goes
/// after four seconds. Nothing lets the user turn the limit off, adjust it,
/// or extend it.
class BadOnlyInMessage extends StatefulWidget {
  const BadOnlyInMessage({super.key});

  @override
  State<BadOnlyInMessage> createState() => _BadOnlyInMessageState();
}

class _BadOnlyInMessageState extends State<BadOnlyInMessage> {
  int _booked = 0;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-only-in-message',
      action: 'Book a table',
      line: 'Bookings: $_booked',
      onPressed: (context) {
        setState(() => _booked++);
        _show(
          ScaffoldMessenger.of(context),
          SnackBar(
            // Defect: the code is nowhere else, and the message times out.
            content: Text('Booked. Code: K7Q2'),
          ),
        );
      },
    );
  }
}
// #endregion

// #region bad-inline-banner
/// A MaterialBanner put in the page by the app, as any widget is put there,
/// and not shown through the ScaffoldMessenger. Only a banner that the
/// messenger shows is a live region, so this one is not announced.
class BadInlineBanner extends StatefulWidget {
  const BadInlineBanner({super.key});

  @override
  State<BadInlineBanner> createState() => _BadInlineBannerState();
}

class _BadInlineBannerState extends State<BadInlineBanner> {
  bool _offline = false;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-inline-banner',
      action: 'Go offline',
      line: _offline ? 'Status: offline' : 'Status: online',
      onPressed: (context) => setState(() => _offline = true),
      // Defect: a banner in the page, with no live region.
      below: _offline
          ? MaterialBanner(
              content: Text('You are offline.'),
              actions: [
                TextButton(
                  // Going online is told by a SnackBar, as in good-banner:
                  // the defect is the banner's alone.
                  onPressed: () {
                    setState(() => _offline = false);
                    _show(
                      ScaffoldMessenger.of(context),
                      _done('You are online.'),
                    );
                  },
                  style: focusRing(Theme.of(context).colorScheme.onSurface),
                  child: const Text('Go online'),
                ),
              ],
            )
          : null,
    );
  }
}
// #endregion
