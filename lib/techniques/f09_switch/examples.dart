import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../catalog/test_id.dart';

// #region shared
/// Lays out one example and reports how many times its control was
/// operated, so people and tests can confirm that it worked.
class _Demo extends StatefulWidget {
  const _Demo({required this.slug, required this.builder});

  final String slug;
  final List<Widget> Function(BuildContext context, VoidCallback changed)
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
          key: ValueKey<String>('f09-${widget.slug}-count'),
          identifier: 'f09-${widget.slug}-count',
          liveRegion: true,
          child: Text('Changes: $_count'),
        ),
      ],
    );
  }
}

/// The keyboard half of a custom control and its focus ring: Enter and Space
/// call [onActivate]. It gives the control no role, no name, and no state.
class _KeyboardOperable extends StatefulWidget {
  const _KeyboardOperable({required this.onActivate, required this.child});

  final VoidCallback onActivate;
  final Widget child;

  @override
  State<_KeyboardOperable> createState() => _KeyboardOperableState();
}

class _KeyboardOperableState extends State<_KeyboardOperable> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) => widget.onActivate(),
        ),
        ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
          onInvoke: (_) => widget.onActivate(),
        ),
      },
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border.all(
            color: _focused ? colors.onSurface : colors.surface,
            width: 3,
          ),
        ),
        child: Padding(padding: const EdgeInsets.all(5), child: widget.child),
      ),
    );
  }
}

/// A switch drawn by hand, with its text: a track with the thumb at the
/// right and a tick when [on], at the left and a cross when off. It has no
/// semantics of its own.
class _DrawnSwitch extends StatelessWidget {
  const _DrawnSwitch({required this.text, required this.on});

  final String text;
  final bool on;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          Flexible(child: Text(text)),
          Container(
            width: 56,
            height: 30,
            alignment: on ? Alignment.centerRight : Alignment.centerLeft,
            decoration: BoxDecoration(
              color: on ? colors.primary : colors.surface,
              border: Border.all(color: colors.onSurface, width: 2),
            ),
            child: Container(
              width: 26,
              height: 26,
              color: on ? colors.onPrimary : colors.onSurface,
              child: Icon(
                on ? Icons.check : Icons.close,
                size: 18,
                color: on ? colors.primary : colors.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _bluetooth = 'Bluetooth';
// #endregion

// #region good-tile
/// A Material switch with its label. `SwitchListTile` makes the switch and
/// the text one control: one name, the switch role, the on or off state,
/// and a tap anywhere on the row changes it.
class GoodTile extends StatefulWidget {
  const GoodTile({super.key});

  @override
  State<GoodTile> createState() => _GoodTileState();
}

class _GoodTileState extends State<GoodTile> {
  bool _on = false;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-tile',
      builder: (context, changed) => [
        TestId(
          'f09-good-tile-bluetooth',
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _on,
            onChanged: (value) {
              setState(() => _on = value);
              changed();
            },
            title: const Text(_bluetooth),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region good-cupertino
/// A Cupertino switch at the end of a list tile, as the `CupertinoSwitch`
/// documentation shows it. `CupertinoListTile` does not merge its parts, so
/// `MergeSemantics` makes the title and the switch one control, and the
/// tile's `onTap` makes the title part of the target.
class GoodCupertino extends StatefulWidget {
  const GoodCupertino({super.key});

  @override
  State<GoodCupertino> createState() => _GoodCupertinoState();
}

class _GoodCupertinoState extends State<GoodCupertino> {
  bool _on = false;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-cupertino',
      builder: (context, changed) {
        void toggle() {
          setState(() => _on = !_on);
          changed();
        }

        return [
          TestId(
            'f09-good-cupertino-bluetooth',
            child: MergeSemantics(
              // A list tile is 44 high; the row is kept at 48, the size of
              // a touch target on Android.
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: CupertinoListTile(
                  padding: EdgeInsets.zero,
                  title: const Text(_bluetooth),
                  trailing: CupertinoSwitch(
                    value: _on,
                    onChanged: (_) => toggle(),
                  ),
                  onTap: toggle,
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

// #region good-custom
/// A switch drawn by hand. Its name, its on or off state, and its tap
/// action are on one `Semantics`: `toggled` gives the switch role and the
/// state together. `enabled: true` is there because without it VoiceOver
/// on iOS reads the switch as dimmed (docs/flutter-limitations.md, FL-033).
class GoodCustom extends StatefulWidget {
  const GoodCustom({super.key});

  @override
  State<GoodCustom> createState() => _GoodCustomState();
}

class _GoodCustomState extends State<GoodCustom> {
  bool _on = false;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-custom',
      builder: (context, changed) {
        void toggle() {
          setState(() => _on = !_on);
          changed();
        }

        return [
          TestId(
            'f09-good-custom-bluetooth',
            child: _KeyboardOperable(
              onActivate: toggle,
              child: Semantics(
                toggled: _on,
                enabled: true,
                label: _bluetooth,
                onTap: toggle,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: toggle,
                  child: ExcludeSemantics(
                    child: _DrawnSwitch(text: _bluetooth, on: _on),
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

// #region good-group
/// Two switches that answer one question. The question is the label of a
/// node around them, so it is tied to the switches and not only printed
/// above them. The visible text is left out of the semantics, or it would
/// be read twice.
class GoodGroup extends StatefulWidget {
  const GoodGroup({super.key});

  @override
  State<GoodGroup> createState() => _GoodGroupState();
}

class _GoodGroupState extends State<GoodGroup> {
  bool _messages = false;
  bool _reminders = false;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-group',
      builder: (context, changed) => [
        Semantics(
          key: const ValueKey<String>('f09-good-group-notify'),
          identifier: 'f09-good-group-notify',
          container: true,
          explicitChildNodes: true,
          label: 'Notify me about',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Text(
                  'Notify me about',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TestId(
                'f09-good-group-messages',
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _messages,
                  onChanged: (value) {
                    setState(() => _messages = value);
                    changed();
                  },
                  title: const Text('Messages'),
                ),
              ),
              TestId(
                'f09-good-group-reminders',
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _reminders,
                  onChanged: (value) {
                    setState(() => _reminders = value);
                    changed();
                  },
                  title: const Text('Reminders'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-unlabelled
/// A `Switch` with text beside it and nothing joining them. The switch has
/// no name, the text is a separate element, and a tap on the text does
/// nothing.
class BadUnlabelled extends StatefulWidget {
  const BadUnlabelled({super.key});

  @override
  State<BadUnlabelled> createState() => _BadUnlabelledState();
}

class _BadUnlabelledState extends State<BadUnlabelled> {
  bool _on = false;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-unlabelled',
      builder: (context, changed) => [
        Row(
          children: [
            const Expanded(child: Text(_bluetooth)),
            Switch(
              key: const ValueKey<String>('f09-bad-unlabelled-switch'),
              value: _on,
              onChanged: (value) {
                setState(() => _on = value);
                changed();
              },
            ),
          ],
        ),
      ],
    );
  }
}
// #endregion

// #region bad-tile-not-merged
/// A `ListTile` with a `Switch` at its end, and nothing to merge them. The
/// row is a button called "Bluetooth" that says nothing about on or off,
/// and the switch inside it is a second element with no name.
class BadTileNotMerged extends StatefulWidget {
  const BadTileNotMerged({super.key});

  @override
  State<BadTileNotMerged> createState() => _BadTileNotMergedState();
}

class _BadTileNotMergedState extends State<BadTileNotMerged> {
  bool _on = false;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-tile-not-merged',
      builder: (context, changed) {
        void toggle() {
          setState(() => _on = !_on);
          changed();
        }

        return [
          ListTile(
            key: const ValueKey<String>('f09-bad-tile-not-merged-tile'),
            contentPadding: EdgeInsets.zero,
            title: const Text(_bluetooth),
            trailing: Switch(
              key: const ValueKey<String>('f09-bad-tile-not-merged-switch'),
              value: _on,
              onChanged: (_) => toggle(),
            ),
            onTap: toggle,
          ),
        ];
      },
    );
  }
}
// #endregion

// #region bad-label-changes
/// A switch whose label says its state: "Bluetooth off", then "Bluetooth
/// on". The name changes every time the switch does, and the state is read
/// twice.
class BadLabelChanges extends StatefulWidget {
  const BadLabelChanges({super.key});

  @override
  State<BadLabelChanges> createState() => _BadLabelChangesState();
}

class _BadLabelChangesState extends State<BadLabelChanges> {
  bool _on = false;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-label-changes',
      builder: (context, changed) => [
        TestId(
          'f09-bad-label-changes-bluetooth',
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _on,
            onChanged: (value) {
              setState(() => _on = value);
              changed();
            },
            title: Text(_on ? 'Bluetooth on' : 'Bluetooth off'),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-no-state
/// A hand-drawn switch exposed as a button. It has a name and it works,
/// but nothing says that it is a switch or whether it is on.
class BadNoState extends StatefulWidget {
  const BadNoState({super.key});

  @override
  State<BadNoState> createState() => _BadNoStateState();
}

class _BadNoStateState extends State<BadNoState> {
  bool _on = false;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-no-state',
      builder: (context, changed) {
        void toggle() {
          setState(() => _on = !_on);
          changed();
        }

        return [
          TestId(
            'f09-bad-no-state-bluetooth',
            child: _KeyboardOperable(
              onActivate: toggle,
              child: Semantics(
                button: true,
                label: _bluetooth,
                onTap: toggle,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: toggle,
                  child: ExcludeSemantics(
                    child: _DrawnSwitch(text: _bluetooth, on: _on),
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
