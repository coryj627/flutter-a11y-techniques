import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../catalog/test_id.dart';

// #region shared
/// Lays out one example and reports how many times its control was
/// activated, so people and tests can confirm that activation worked.
class _Demo extends StatefulWidget {
  const _Demo({required this.slug, required this.builder});

  final String slug;
  final List<Widget> Function(BuildContext context, VoidCallback activate)
  builder;

  @override
  State<_Demo> createState() => _DemoState();
}

class _DemoState extends State<_Demo> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        ...widget.builder(context, () => setState(() => _count++)),
        Semantics(
          key: ValueKey<String>('i01-${widget.slug}-count'),
          identifier: 'i01-${widget.slug}-count',
          liveRegion: true,
          child: Text('Activations: $_count'),
        ),
      ],
    );
  }
}

/// The text every example's control shows.
const _trail = 'Ridge trail';

/// A card drawn by hand: a map icon and the trail's name, with a ring
/// around it when [focused]. It has no semantics of its own beyond its
/// text, and does nothing by itself.
class _TrailCard extends StatelessWidget {
  const _TrailCard({this.focused = false});

  final bool focused;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 56, minWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: focused ? colors.onSurface : colors.outline,
          width: focused ? 3 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          Icon(Icons.map_outlined, color: colors.onSurfaceVariant),
          Flexible(
            child: Text(_trail, style: TextStyle(color: colors.onSurface)),
          ),
        ],
      ),
    );
  }
}

/// What makes a custom control reachable and usable from the keyboard: a
/// focus node in the traversal order, and Enter and Space mapped to
/// [onActivate]. `WidgetsApp` sends Space as `ActivateIntent` everywhere,
/// and Enter as `ActivateIntent` on Android and iOS and as
/// `ButtonActivateIntent` on the web, so both intents are handled. The
/// builder is told whether to show the focus ring. It adds no role, name,
/// or semantics action.
class _Keyboard extends StatefulWidget {
  const _Keyboard({required this.onActivate, required this.builder});

  final VoidCallback onActivate;
  final Widget Function(bool focused) builder;

  @override
  State<_Keyboard> createState() => _KeyboardState();
}

class _KeyboardState extends State<_Keyboard> {
  bool _focused = false;

  Object? _activate(Intent intent) {
    widget.onActivate();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: _activate),
        ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
          onInvoke: _activate,
        ),
      },
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      child: widget.builder(_focused),
    );
  }
}
// #endregion

// #region good-material
/// A `ListTile` with `onTap` is focusable, answers Enter and Space, acts
/// when the pointer is released over it, and is a button to assistive
/// technology.
class GoodMaterial extends StatelessWidget {
  const GoodMaterial({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-material',
      builder: (context, activate) => [
        TestId(
          'i01-good-material-trail',
          child: Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.map_outlined),
              title: const Text(_trail),
              onTap: activate,
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region good-cupertino
/// A `CupertinoListTile` with `onTap` answers a tap only: it takes no
/// keyboard focus on any platform, and it sets no button flag, so it is not
/// a button on Android and iOS (docs/flutter-limitations.md, FL-400). The
/// keyboard half and the flag are added around it.
class GoodCupertino extends StatelessWidget {
  const GoodCupertino({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _Demo(
      slug: 'good-cupertino',
      builder: (context, activate) => [
        TestId(
          'i01-good-cupertino-trail',
          child: _Keyboard(
            onActivate: activate,
            builder: (focused) => Semantics(
              button: true,
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: focused ? colors.onSurface : colors.surface,
                    width: 3,
                  ),
                ),
                child: CupertinoListTile(
                  leading: const Icon(CupertinoIcons.map),
                  title: const Text(_trail),
                  trailing: const CupertinoListTileChevron(),
                  onTap: activate,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region good-custom
/// A card drawn by hand: `GestureDetector(onTap:)` for the pointer and for
/// assistive technology, `Semantics(button: true)` for the role, and
/// `FocusableActionDetector` for focus, Enter, and Space.
class GoodCustom extends StatelessWidget {
  const GoodCustom({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-custom',
      builder: (context, activate) => [
        TestId(
          'i01-good-custom-trail',
          child: _Keyboard(
            onActivate: activate,
            builder: (focused) => Semantics(
              button: true,
              child: GestureDetector(
                onTap: activate,
                child: _TrailCard(focused: focused),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-inkwell-no-role
class BadInkWellNoRole extends StatelessWidget {
  const BadInkWellNoRole({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-inkwell-no-role',
      builder: (context, activate) => [
        TestId(
          'i01-bad-inkwell-no-role-trail',
          // Defect: an InkWell is focusable, answers Enter and Space, and
          // has a tap action, but sets no button flag. On Android and iOS
          // nothing says that the card can be activated. (On the web the
          // engine makes anything with a tap action a button, FL-006.)
          child: Card(
            margin: EdgeInsets.zero,
            child: InkWell(
              onTap: activate,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 12,
                  children: [Icon(Icons.map_outlined), Text(_trail)],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-no-focus
class BadNoFocus extends StatelessWidget {
  const BadNoFocus({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-no-focus',
      builder: (context, activate) => [
        TestId(
          'i01-bad-no-focus-trail',
          // Defect: a button to assistive technology, with a tap, but no
          // focus node. Tab goes past it, so the keyboard cannot reach it.
          child: Semantics(
            button: true,
            child: GestureDetector(onTap: activate, child: const _TrailCard()),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-no-key-action
class BadNoKeyAction extends StatefulWidget {
  const BadNoKeyAction({super.key});

  @override
  State<BadNoKeyAction> createState() => _BadNoKeyActionState();
}

class _BadNoKeyActionState extends State<BadNoKeyAction> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-no-key-action',
      builder: (context, activate) => [
        TestId(
          'i01-bad-no-key-action-trail',
          // Defect: Focus puts the card in the Tab order and shows a ring,
          // but nothing maps Enter or Space to the tap, so the keyboard
          // reaches it and cannot activate it.
          child: Focus(
            onFocusChange: (value) => setState(() => _focused = value),
            child: Semantics(
              button: true,
              child: GestureDetector(
                onTap: activate,
                child: _TrailCard(focused: _focused),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-tap-down
class BadTapDown extends StatelessWidget {
  const BadTapDown({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-tap-down',
      builder: (context, activate) => [
        TestId(
          'i01-bad-tap-down-trail',
          child: _Keyboard(
            onActivate: activate,
            builder: (focused) => Semantics(
              button: true,
              child: GestureDetector(
                // Defect: acts as soon as a finger or the mouse goes down,
                // so a press cannot be taken back by moving off the card
                // before letting go.
                onTapDown: (_) => activate(),
                child: _TrailCard(focused: focused),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion
