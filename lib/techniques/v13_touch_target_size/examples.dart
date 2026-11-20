import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show OrdinalSortKey;

import '../../catalog/test_id.dart';

// #region shared
/// Lays out one example: its controls, then how many times any of them was
/// pressed, so people and tests can see whether a tap landed.
class _Demo extends StatefulWidget {
  const _Demo({required this.slug, required this.builder});

  final String slug;
  final Widget Function(BuildContext context, VoidCallback press) builder;

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
        widget.builder(context, () => setState(() => _count++)),
        Semantics(
          key: ValueKey<String>('v13-${widget.slug}-count'),
          identifier: 'v13-${widget.slug}-count',
          liveRegion: true,
          child: Text('Presses: $_count'),
        ),
      ],
    );
  }
}

/// The three controls of a player bar: their test id, name, and icons.
const _controls = [
  (
    'previous',
    'Previous',
    Icons.skip_previous,
    CupertinoIcons.backward_end_fill,
  ),
  ('play', 'Play', Icons.play_arrow, CupertinoIcons.play_fill),
  ('next', 'Next', Icons.skip_next, CupertinoIcons.forward_end_fill),
];

/// Makes Enter activate a `CupertinoButton` on the web, where Enter is
/// `ButtonActivateIntent` and the button handles only `ActivateIntent`
/// (docs/flutter-limitations.md, FL-002).
class _EnterToo extends StatelessWidget {
  const _EnterToo({required this.onActivate, required this.child});

  final VoidCallback onActivate;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: {
        ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
          onInvoke: (_) {
            onActivate();
            return null;
          },
        ),
      },
      child: child,
    );
  }
}

/// What makes a hand-made control reachable and usable from the keyboard: a
/// focus node in the Tab order, and Enter and Space mapped to [onActivate]
/// (both activate intents, as in I01). The builder is told whether to show
/// the focus ring. It adds no role, name, or size.
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

/// A ring around [child] while [focused].
Widget _ring(BuildContext context, bool focused, Widget child) => DecoratedBox(
  position: DecorationPosition.foreground,
  decoration: BoxDecoration(
    border: Border.all(
      color: focused
          ? Theme.of(context).colorScheme.onSurface
          : Colors.transparent,
      width: 2,
    ),
    borderRadius: BorderRadius.circular(8),
  ),
  child: child,
);
// #endregion

// #region good-material
/// Material buttons are padded to a 48 by 48 target on Android and iOS
/// (`MaterialTapTargetSize.padded`): the tonal circle is 40 across, and a tap
/// in the 4 pixels around it still presses the button. In a desktop browser
/// the theme does not pad them (docs/flutter-limitations.md, FL-412), and
/// the target is the 40 by 40 circle, still over 24 by 24.
class GoodMaterial extends StatelessWidget {
  const GoodMaterial({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-material',
      builder: (context, press) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (id, name, icon, _) in _controls)
            TestId(
              'v13-good-material-$id',
              child: IconButton.filledTonal(
                onPressed: press,
                icon: Icon(icon, semanticLabel: name),
              ),
            ),
        ],
      ),
    );
  }
}
// #endregion

// #region good-cupertino
/// A `CupertinoButton` is never smaller than its `minimumSize` and takes
/// taps over all of it. The default, 44 by 44, is Apple's size; 48 by 48
/// meets Android's as well. With no padding the tinted square is exactly
/// that box.
class GoodCupertino extends StatelessWidget {
  const GoodCupertino({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-cupertino',
      builder: (context, press) => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          for (final (id, name, _, icon) in _controls)
            TestId(
              'v13-good-cupertino-$id',
              child: _EnterToo(
                onActivate: press,
                child: CupertinoButton.tinted(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size.square(48),
                  onPressed: press,
                  child: Icon(icon, semanticLabel: name),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
// #endregion

// #region good-custom
/// A hand-made button: a 24 pixel icon in a 48 by 48 box. The box takes
/// taps everywhere because the `GestureDetector` is
/// `HitTestBehavior.opaque`; with the default, `deferToChild`, only the icon
/// would, while the node would still say 48 by 48
/// (docs/flutter-limitations.md, FL-410).
class GoodCustom extends StatelessWidget {
  const GoodCustom({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-custom',
      builder: (context, press) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (id, name, icon, _) in _controls)
            TestId(
              'v13-good-custom-$id',
              child: _Keyboard(
                onActivate: press,
                builder: (focused) => Semantics(
                  button: true,
                  label: name,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: press,
                    child: _ring(
                      context,
                      focused,
                      SizedBox.square(
                        dimension: 48,
                        child: Center(child: Icon(icon)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
// #endregion

// #region good-inline-link
/// A link in a sentence is exempt from the minimum size: it is as tall as
/// the line of text it sits in. Flutter's tap target guidelines skip links.
///
/// It is a `WidgetSpan`, so that it can take keyboard focus, which a
/// `TextSpan` with a recognizer cannot. Two things keep it in its place in
/// the sentence for screen readers (docs/flutter-limitations.md, FL-413):
/// a `semanticsIdentifier` on the text before it, which makes the paragraph
/// give each run of text a node of its own, in order, rather than one label
/// without the link; and a sort key between the ones the paragraph gives
/// those runs (0 and 1), so that the link's node is read between them.
class GoodInlineLink extends StatelessWidget {
  const GoodInlineLink({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _Demo(
      slug: 'good-inline-link',
      builder: (context, press) => Text.rich(
        TextSpan(
          children: [
            const TextSpan(
              text: 'Read the ',
              semanticsIdentifier: 'v13-good-inline-link-sentence',
            ),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              // Not TestId: its MergeSemantics would drop the sort key. The
              // identifier goes on the same node instead.
              child: Semantics(
                key: const ValueKey<String>('v13-good-inline-link-rules'),
                container: true,
                identifier: 'v13-good-inline-link-rules',
                sortKey: const OrdinalSortKey(0.5),
                child: _Keyboard(
                  onActivate: press,
                  builder: (focused) => Semantics(
                    link: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: press,
                      child: _ring(
                        context,
                        focused,
                        Text(
                          'trail rules',
                          style: TextStyle(
                            color: colors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const TextSpan(text: ' before you set off.'),
          ],
        ),
      ),
    );
  }
}
// #endregion

// #region bad-shrinkwrap
class BadShrinkWrap extends StatelessWidget {
  const BadShrinkWrap({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-shrinkwrap',
      builder: (context, press) => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          for (final (id, name, icon, _) in _controls)
            TestId(
              'v13-bad-shrinkwrap-$id',
              child: IconButton.filledTonal(
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                // Defect: shrinkWrap takes away the padding that makes the
                // target 48 by 48, so each button is its 18 pixel icon, 4
                // pixels from the next, on every platform.
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: press,
                icon: Icon(icon, semanticLabel: name),
              ),
            ),
        ],
      ),
    );
  }
}
// #endregion

// #region bad-zero-padding-web
class BadZeroPaddingWeb extends StatelessWidget {
  const BadZeroPaddingWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-zero-padding-web',
      builder: (context, press) => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          for (final (id, name, icon, _) in _controls)
            TestId(
              'v13-bad-zero-padding-web-$id',
              // Defect: no padding and no minimum size. On Android and iOS
              // the theme still pads the button to 48 by 48; in a desktop
              // browser it does not (FL-412), and each button is its 18
              // pixel icon, 4 pixels from the next.
              child: IconButton.filledTonal(
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: press,
                icon: Icon(icon, semanticLabel: name),
              ),
            ),
        ],
      ),
    );
  }
}
// #endregion

// #region bad-cupertino-small
class BadCupertinoSmall extends StatelessWidget {
  const BadCupertinoSmall({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-cupertino-small',
      builder: (context, press) => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          for (final (id, name, _, icon) in _controls)
            TestId(
              'v13-bad-cupertino-small-$id',
              child: _EnterToo(
                onActivate: press,
                // Defect: a minimum size of 18 by 18 in place of 44 by 44,
                // so each button is 18 pixels square, 4 pixels from the
                // next.
                child: CupertinoButton.tinted(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size.square(18),
                  onPressed: press,
                  child: Icon(icon, size: 14, semanticLabel: name),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
// #endregion

// #region bad-custom-small
class BadCustomSmall extends StatelessWidget {
  const BadCustomSmall({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-custom-small',
      builder: (context, press) => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          for (final (id, name, icon, _) in _controls)
            TestId(
              'v13-bad-custom-small-$id',
              child: _Keyboard(
                onActivate: press,
                builder: (focused) => Semantics(
                  button: true,
                  label: name,
                  // Defect: the detector is around the 18 pixel icon and
                  // nothing more, so the target is the icon, 4 pixels from
                  // the next.
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: press,
                    child: _ring(context, focused, Icon(icon, size: 18)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
// #endregion
