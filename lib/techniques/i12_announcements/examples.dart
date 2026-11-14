import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../catalog/test_id.dart';

// #region shared
/// A button that changes a message on screen. How the message is exposed is
/// what each example varies.
class _Demo extends StatefulWidget {
  const _Demo({
    required this.slug,
    required this.action,
    required this.initial,
    required this.message,
    required this.statusBuilder,
    this.onPressed,
  });

  final String slug;

  /// The button's label.
  final String action;

  /// The message before the button is pressed. Empty for none.
  final String initial;

  /// The message after [count] presses.
  final String Function(int count) message;

  /// Wraps the visible message text in whatever exposes it.
  final Widget Function(BuildContext context, Widget text) statusBuilder;

  /// Called after the message has changed, with the new message.
  final void Function(BuildContext context, String message)? onPressed;

  @override
  State<_Demo> createState() => _DemoState();
}

class _DemoState extends State<_Demo> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    final message = _count == 0 ? widget.initial : widget.message(_count);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        TestId(
          'i12-${widget.slug}-action',
          child: FilledButton(
            onPressed: () {
              setState(() => _count++);
              widget.onPressed?.call(context, widget.message(_count));
            },
            child: Text(widget.action),
          ),
        ),
        // Space is kept for the message so the layout does not jump.
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 24),
          child: widget.statusBuilder(
            context,
            Text(message, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ),
      ],
    );
  }
}

String _cart(int count) =>
    count == 1 ? '1 item in cart' : '$count items in cart';
// #endregion

// #region good-live-region
/// A status message in a live region: when its text changes, assistive
/// technology reads the new text without moving focus.
class GoodLiveRegion extends StatelessWidget {
  const GoodLiveRegion({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-live-region',
      action: 'Add to cart',
      initial: 'Cart is empty',
      message: _cart,
      statusBuilder: (context, text) => Semantics(
        identifier: 'i12-good-live-region-status',
        liveRegion: true,
        child: text,
      ),
    );
  }
}
// #endregion

// #region good-announce
/// A change announced from code, for platforms that support it, with a live
/// region for the ones that do not (Android).
class GoodAnnouncement extends StatefulWidget {
  const GoodAnnouncement({super.key});

  @override
  State<GoodAnnouncement> createState() => _GoodAnnouncementState();
}

class _GoodAnnouncementState extends State<GoodAnnouncement> {
  static const _confirmation = 'Link copied';
  String _message = '';

  void _copy(bool canAnnounce) {
    if (canAnnounce) {
      setState(() => _message = _confirmation);
      SemanticsService.sendAnnouncement(
        View.of(context),
        _confirmation,
        Directionality.of(context),
      );
      return;
    }
    // A live region is announced when its text changes. Pressing the button
    // a second time would leave the same text in place and say nothing, so
    // the message is cleared and set again in the next frame: every press is
    // a change, and every press is announced.
    setState(() => _message = '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _message = _confirmation);
    });
  }

  @override
  Widget build(BuildContext context) {
    // False on Android, which has deprecated announcements sent from code.
    final canAnnounce = MediaQuery.supportsAnnounceOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        TestId(
          'i12-good-announce-action',
          child: FilledButton(
            onPressed: () => _copy(canAnnounce),
            child: const Text('Copy link'),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 24),
          // Where code cannot announce, the visible confirmation is a live
          // region instead. Never both, or the message would be read twice.
          child: Semantics(
            identifier: 'i12-good-announce-status',
            liveRegion: !canAnnounce,
            child: Text(_message, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region good-snackbar
/// A Material SnackBar announces itself.
class GoodSnackBar extends StatelessWidget {
  const GoodSnackBar({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-snackbar',
      action: 'Archive message',
      initial: '',
      message: (count) => 'Message archived',
      statusBuilder: (context, text) => const SizedBox.shrink(),
      onPressed: (context, message) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }
}
// #endregion

// #region bad-silent-update
class BadSilentUpdate extends StatelessWidget {
  const BadSilentUpdate({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-silent-update',
      action: 'Add to cart',
      initial: 'Cart is empty',
      message: _cart,
      // Defect: the message changes on screen, but nothing tells assistive
      // technology that it changed.
      statusBuilder: (context, text) =>
          Semantics(identifier: 'i12-bad-silent-update-status', child: text),
    );
  }
}
// #endregion

// #region bad-status-role-only
class BadStatusRoleOnly extends StatelessWidget {
  const BadStatusRoleOnly({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-status-role-only',
      action: 'Add to cart',
      initial: 'Cart is empty',
      message: _cart,
      // Defect (Flutter limitation): the status role is announced on web
      // only. On Android nothing is said.
      statusBuilder: (context, text) => Semantics(
        identifier: 'i12-bad-status-role-only-status',
        role: SemanticsRole.status,
        child: text,
      ),
    );
  }
}
// #endregion

// #region bad-alert-role-only
class BadAlertRoleOnly extends StatelessWidget {
  const BadAlertRoleOnly({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-alert-role-only',
      action: 'Save changes',
      initial: '',
      message: (count) => 'Could not save. Attempt $count failed.',
      // Defect (Flutter limitation): the alert role is announced on web
      // only. On Android an error shown this way is silent.
      statusBuilder: (context, text) => Semantics(
        identifier: 'i12-bad-alert-role-only-status',
        role: SemanticsRole.alert,
        child: text,
      ),
    );
  }
}
// #endregion

// #region bad-chatty-live-region
class BadChattyLiveRegion extends StatefulWidget {
  const BadChattyLiveRegion({super.key});

  @override
  State<BadChattyLiveRegion> createState() => _BadChattyLiveRegionState();
}

class _BadChattyLiveRegionState extends State<BadChattyLiveRegion> {
  Timer? _timer;
  int _seconds = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        TestId(
          'i12-bad-chatty-live-region-action',
          child: FilledButton(
            onPressed: () {
              _timer?.cancel();
              setState(() => _seconds = 0);
              _timer = Timer.periodic(
                const Duration(seconds: 1),
                (_) => setState(() => _seconds++),
              );
            },
            child: const Text('Start upload'),
          ),
        ),
        // Defect: a live region that changes every second. Each change is
        // announced, so the screen reader never stops talking.
        Semantics(
          identifier: 'i12-bad-chatty-live-region-status',
          liveRegion: true,
          child: Text(
            _timer == null ? 'Not started' : 'Uploading: $_seconds seconds',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}
// #endregion
