import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../catalog/test_id.dart';

// #region shared
/// Lays out one example and says which control was used last, so people
/// and tests can tell which control a key acted on.
class _Demo extends StatefulWidget {
  const _Demo({required this.slug, required this.builder});

  final String slug;
  final List<Widget> Function(BuildContext context, ValueChanged<String> used)
  builder;

  @override
  State<_Demo> createState() => _DemoState();
}

class _DemoState extends State<_Demo> {
  String _last = 'none';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        ...widget.builder(context, (name) => setState(() => _last = name)),
        Semantics(
          key: ValueKey<String>('v14-${widget.slug}-count'),
          identifier: 'v14-${widget.slug}-count',
          child: Text('Last used: $_last'),
        ),
      ],
    );
  }
}

const _alerts = 'Weather alerts';
const _save = 'Save';

/// A focus ring for a Material button: a 3 pixel line of the theme's
/// `onSurface` colour drawn just outside the button's shape while it has
/// focus, and nothing otherwise. It comes from the focused state, so it is
/// drawn whatever moved focus there, not only after a key. Being outside
/// the button, the ring lies on the page, and `onSurface` is the colour the
/// theme puts text in on that page.
ButtonStyle _ringed(ColorScheme colors) => ButtonStyle(
  side: WidgetStateProperty.resolveWith(
    (states) => states.contains(WidgetState.focused)
        ? BorderSide(
            color: colors.onSurface,
            width: 3,
            strokeAlign: BorderSide.strokeAlignOutside,
          )
        : null,
  ),
);

/// Draws the same ring round [child] while focus is on it or inside it.
/// The `Focus` here takes no focus itself; it only hears when the control
/// inside it gains or loses focus.
class _FocusRing extends StatefulWidget {
  const _FocusRing({required this.child});

  final Widget child;

  @override
  State<_FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<_FocusRing> {
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
          borderRadius: BorderRadius.circular(8),
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

/// The trails of the scrolling examples.
const _trails = [
  'Ridge trail',
  'Lake loop',
  'Summit path',
  'Forest walk',
  'River run',
  'Canyon climb',
];

/// Six trail buttons in a scrolling box 232 pixels tall, and a notice 72
/// pixels tall. With [over], the notice is drawn over the bottom of the
/// box, as a banner pinned to the bottom of a view often is; otherwise it
/// sits under the box, and the box is that much shorter.
class _TrailList extends StatelessWidget {
  const _TrailList({
    required this.slug,
    required this.over,
    required this.used,
  });

  final String slug;
  final bool over;
  final ValueChanged<String> used;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final list = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, trail) in _trails.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: SizedBox(
                height: 48,
                child: TestId(
                  'v14-$slug-trail${i + 1}',
                  child: TextButton(
                    style: _ringed(colors),
                    onPressed: () => used(trail),
                    child: Text(trail),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    final notice = Semantics(
      container: true,
      identifier: 'v14-$slug-notice',
      child: Container(
        height: 72,
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        color: colors.inverseSurface,
        child: Text(
          'Trail conditions are updated every morning.',
          style: TextStyle(color: colors.onInverseSurface),
        ),
      ),
    );
    return Semantics(
      container: true,
      identifier: 'v14-$slug-list',
      child: Container(
        height: 232,
        decoration: BoxDecoration(border: Border.all(color: colors.outline)),
        child: over
            ? Stack(
                children: [
                  list,
                  Positioned(left: 0, right: 0, bottom: 0, child: notice),
                ],
              )
            : Column(
                children: [
                  Expanded(child: list),
                  notice,
                ],
              ),
      ),
    );
  }
}
// #endregion

// #region good-material
/// A `CheckboxListTile` and a `FilledButton` whose focus is shown by a ring
/// of the theme's text colour. The button draws it from its style, for the
/// focused state; the tile, which has no such style, gets it from a
/// `Focus` that hears its focus change.
class GoodMaterial extends StatefulWidget {
  const GoodMaterial({super.key});

  @override
  State<GoodMaterial> createState() => _GoodMaterialState();
}

class _GoodMaterialState extends State<GoodMaterial> {
  bool _on = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _Demo(
      slug: 'good-material',
      builder: (context, used) => [
        TestId(
          'v14-good-material-alerts',
          child: _FocusRing(
            child: CheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              value: _on,
              onChanged: (value) {
                setState(() => _on = value!);
                used(_alerts);
              },
              title: const Text(_alerts),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(4),
          child: TestId(
            'v14-good-material-save',
            child: FilledButton(
              style: _ringed(colors),
              onPressed: () => used(_save),
              child: const Text(_save),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region good-cupertino
/// A `CupertinoSwitch` and a `CupertinoButton` with a `focusColor` of the
/// label colour, which draws their focus ring in a colour that stands out
/// from the page in light and dark mode. Their own ring is too pale on a
/// light page (docs/flutter-limitations.md, FL-431).
class GoodCupertino extends StatefulWidget {
  const GoodCupertino({super.key});

  @override
  State<GoodCupertino> createState() => _GoodCupertinoState();
}

class _GoodCupertinoState extends State<GoodCupertino> {
  bool _on = false;

  @override
  Widget build(BuildContext context) {
    final ring = CupertinoColors.label.resolveFrom(context);
    return _Demo(
      slug: 'good-cupertino',
      builder: (context, used) => [
        TestId(
          'v14-good-cupertino-alerts',
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: CupertinoListTile(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              title: const Text(_alerts),
              trailing: CupertinoSwitch(
                focusColor: ring,
                value: _on,
                onChanged: (value) {
                  setState(() => _on = value);
                  used(_alerts);
                },
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: TestId(
            'v14-good-cupertino-save',
            child: CupertinoButton.filled(
              focusColor: ring,
              onPressed: () => used(_save),
              child: const Text(_save),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region good-widgets
/// A card drawn by hand. `FocusableActionDetector` gives it focus, Enter
/// and Space, and tells it when to show its focus: only when the keyboard
/// is in use, as Flutter's own controls do. The card then draws its border
/// 3 pixels wide in the theme's text colour.
class GoodWidgets extends StatefulWidget {
  const GoodWidgets({super.key});

  @override
  State<GoodWidgets> createState() => _GoodWidgetsState();
}

class _GoodWidgetsState extends State<GoodWidgets> {
  bool _showFocus = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _Demo(
      slug: 'good-widgets',
      builder: (context, used) {
        Object? activate(Intent _) {
          used(_trails.first);
          return null;
        }

        return [
          TestId(
            'v14-good-widgets-trail',
            child: FocusableActionDetector(
              mouseCursor: SystemMouseCursors.click,
              actions: {
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: activate,
                ),
                ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
                  onInvoke: activate,
                ),
              },
              onShowFocusHighlight: (value) =>
                  setState(() => _showFocus = value),
              child: Semantics(
                button: true,
                child: GestureDetector(
                  onTap: () => used(_trails.first),
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 56,
                      minWidth: 220,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _showFocus ? colors.onSurface : colors.outline,
                        width: _showFocus ? 3 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 12,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          color: colors.onSurfaceVariant,
                        ),
                        Flexible(
                          child: Text(
                            _trails.first,
                            style: TextStyle(color: colors.onSurface),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ];
      },
    );
  }
}
// #endregion

// #region good-notice-below
/// The notice is laid out under the scrolling box, not over it, so the box
/// ends where the notice starts. When Tab moves to a trail out of view,
/// Flutter scrolls the box until the trail is inside it, which is now all
/// in sight.
class GoodNoticeBelow extends StatelessWidget {
  const GoodNoticeBelow({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-notice-below',
      builder: (context, used) => [
        _TrailList(slug: 'good-notice-below', over: false, used: used),
      ],
    );
  }
}
// #endregion

// #region bad-indicator-removed
class BadIndicatorRemoved extends StatelessWidget {
  const BadIndicatorRemoved({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-indicator-removed',
      builder: (context, used) => [
        TestId(
          'v14-bad-indicator-removed-save',
          child: FilledButton(
            // Defect: the overlay is the only thing a FilledButton changes
            // when it takes focus, and it is made transparent here (to be
            // rid of the tint a press leaves, say). With it goes the focus
            // indicator: nothing on the screen changes when Tab reaches
            // the button.
            style: const ButtonStyle(
              overlayColor: WidgetStatePropertyAll(Colors.transparent),
            ),
            onPressed: () => used(_save),
            child: const Text(_save),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-checkbox-halo
class BadCheckboxHalo extends StatefulWidget {
  const BadCheckboxHalo({super.key});

  @override
  State<BadCheckboxHalo> createState() => _BadCheckboxHaloState();
}

class _BadCheckboxHaloState extends State<BadCheckboxHalo> {
  bool _on = false;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-checkbox-halo',
      builder: (context, used) {
        void toggle() {
          setState(() => _on = !_on);
          used(_alerts);
        }

        return [
          TestId(
            'v14-bad-checkbox-halo-alerts',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Defect: a Checkbox shows focus with its default halo, a
                // disc of the theme's text colour at a tenth of its
                // strength round the box. On the page it is about 1.2:1,
                // far from the 3:1 a focus indicator needs
                // (docs/flutter-limitations.md, FL-430).
                Checkbox(value: _on, onChanged: (_) => toggle()),
                GestureDetector(
                  excludeFromSemantics: true,
                  onTap: toggle,
                  child: const Text(_alerts),
                ),
              ],
            ),
          ),
        ];
      },
    );
  }
}
// #endregion

// #region bad-cupertino-ring
class BadCupertinoRing extends StatelessWidget {
  const BadCupertinoRing({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-cupertino-ring',
      builder: (context, used) => [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TestId(
            'v14-bad-cupertino-ring-save',
            // Defect: a CupertinoButton shows focus with its default ring,
            // a pale tint of the button's own colour. In light mode it is
            // about 2.5:1 against the page here, under the 3:1 a focus
            // indicator needs (docs/flutter-limitations.md, FL-431). In
            // dark mode it passes.
            child: CupertinoButton.filled(
              onPressed: () => used(_save),
              child: const Text(_save),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-notice-over-list
class BadNoticeOverList extends StatelessWidget {
  const BadNoticeOverList({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-notice-over-list',
      builder: (context, used) => [
        // Defect: the notice is drawn over the bottom of the scrolling box.
        // Flutter scrolls a focused trail into the box, not out from under
        // what is drawn over it, so Tab puts focus on trails that are
        // entirely under the notice (docs/flutter-limitations.md, FL-432).
        _TrailList(slug: 'bad-notice-over-list', over: true, used: used),
      ],
    );
  }
}
// #endregion
