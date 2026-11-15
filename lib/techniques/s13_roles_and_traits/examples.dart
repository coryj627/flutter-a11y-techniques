import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../catalog/test_id.dart';

// #region shared
/// The state of one example: a count of activations, the switches that are
/// on, and the chosen view.
class _DemoState extends State<_Demo> {
  int _count = 0;
  final Set<String> _on = {};
  String _view = 'Week';

  void press() => setState(() => _count++);

  bool isOn(String name) => _on.contains(name);

  void toggle(String name) => setState(() {
    _count++;
    if (!_on.remove(name)) _on.add(name);
  });

  String get view => _view;

  void choose(String view) => setState(() {
    _count++;
    _view = view;
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        ...widget.builder(context, this),
        Semantics(
          key: ValueKey<String>('s13-${widget.slug}-count'),
          identifier: 's13-${widget.slug}-count',
          liveRegion: true,
          child: Text('Activations: $_count'),
        ),
      ],
    );
  }
}

/// Lays out one example and reports how many times its controls were
/// activated, so people and tests can confirm that activation worked.
class _Demo extends StatefulWidget {
  const _Demo({required this.slug, required this.builder});

  final String slug;
  final List<Widget> Function(BuildContext context, _DemoState demo) builder;

  @override
  State<_Demo> createState() => _DemoState();
}

/// The keyboard half of a custom control: focus, Enter and Space, and a
/// focus ring. It gives the control no role and no tap action; each example
/// adds its own `Semantics` and `GestureDetector` inside it.
class _KeyboardOperable extends StatefulWidget {
  const _KeyboardOperable({required this.onActivate, required this.child});

  final VoidCallback onActivate;
  final Widget child;

  @override
  State<_KeyboardOperable> createState() => _KeyboardOperableState();
}

class _KeyboardOperableState extends State<_KeyboardOperable> {
  bool _focused = false;

  Object? _activate(Intent intent) {
    widget.onActivate();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      // Enter and Space reach the control as these intents through the
      // default shortcuts of WidgetsApp.
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: _activate),
        ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
          onInvoke: _activate,
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

/// What a custom control looks like: an icon and text in an outlined box.
/// The icon has no label, so the text is the control's name.
class _Face extends StatelessWidget {
  const _Face({required this.icon, required this.text, this.strong = false});

  final IconData icon;
  final String text;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: colors.onSurface, width: strong ? 3 : 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Icon(icon, color: colors.onSurface),
          Flexible(
            child: Text(text, style: TextStyle(color: colors.onSurface)),
          ),
        ],
      ),
    );
  }
}

/// The picture of a switch: its text, and a thumb at the left (off) or the
/// right (on) of a track. The state is shown by position and by an icon, not
/// by colour alone, and has no semantics of its own.
class _SwitchFace extends StatelessWidget {
  const _SwitchFace({required this.text, required this.on});

  final String text;
  final bool on;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          Flexible(
            child: Text(text, style: TextStyle(color: colors.onSurface)),
          ),
          Container(
            width: 56,
            height: 30,
            alignment: on ? Alignment.centerRight : Alignment.centerLeft,
            decoration: BoxDecoration(
              border: Border.all(color: colors.onSurface, width: 2),
            ),
            child: Container(
              width: 26,
              height: 26,
              color: colors.onSurface,
              child: Icon(
                on ? Icons.check : Icons.close,
                size: 18,
                color: colors.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// #endregion

// #region good-standard
/// The SDK's own controls already have their roles: a button, a switch, and
/// a checkbox. Nothing is added to them.
class GoodStandard extends StatelessWidget {
  const GoodStandard({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-standard',
      builder: (context, demo) => [
        TestId(
          's13-good-standard-save',
          child: FilledButton(onPressed: demo.press, child: const Text('Save')),
        ),
        TestId(
          's13-good-standard-wifi',
          child: SwitchListTile(
            title: const Text('Wi-Fi'),
            value: demo.isOn('wifi'),
            onChanged: (_) => demo.toggle('wifi'),
          ),
        ),
        TestId(
          's13-good-standard-remember',
          child: CheckboxListTile(
            title: const Text('Remember me'),
            value: demo.isOn('remember'),
            onChanged: (_) => demo.toggle('remember'),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region good-cupertino
/// The Cupertino controls have their roles as well. The switch has no label
/// of its own, so `MergeSemantics` joins it to the text beside it (S01).
class GoodCupertino extends StatelessWidget {
  const GoodCupertino({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-cupertino',
      builder: (context, demo) => [
        TestId(
          's13-good-cupertino-save',
          // Flutter 3.47.5: on web Enter is ButtonActivateIntent, which
          // CupertinoButton does not handle (docs/flutter-limitations.md,
          // FL-002). This adds the missing action; Space already works.
          child: Actions(
            actions: {
              ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
                onInvoke: (_) {
                  demo.press();
                  return null;
                },
              ),
            },
            child: CupertinoButton.filled(
              onPressed: demo.press,
              child: const Text('Save'),
            ),
          ),
        ),
        TestId(
          's13-good-cupertino-wifi',
          child: MergeSemantics(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => demo.toggle('wifi'),
              child: Row(
                children: [
                  const Expanded(child: Text('Wi-Fi')),
                  CupertinoSwitch(
                    value: demo.isOn('wifi'),
                    onChanged: (_) => demo.toggle('wifi'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region good-custom-button
/// A control drawn by hand gets its role from `Semantics`. `button: true` is
/// the role, `enabled: true` says it can be used, and the `GestureDetector`
/// inside gives it the tap action that assistive technology calls.
class GoodCustomButton extends StatelessWidget {
  const GoodCustomButton({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-custom-button',
      builder: (context, demo) => [
        TestId(
          's13-good-custom-button-scan',
          child: _KeyboardOperable(
            onActivate: demo.press,
            child: Semantics(
              button: true,
              enabled: true,
              child: GestureDetector(
                onTap: demo.press,
                child: const _Face(
                  icon: Icons.qr_code_scanner,
                  text: 'Scan barcode',
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

// #region good-custom-switch
/// A control that is on or off is a switch, not a button. `toggled` gives
/// the role and the state together. `enabled: true` is needed as well:
/// without it VoiceOver on iOS reads the switch as dimmed (FL-033).
class GoodCustomSwitch extends StatelessWidget {
  const GoodCustomSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-custom-switch',
      builder: (context, demo) => [
        TestId(
          's13-good-custom-switch-dark',
          child: _KeyboardOperable(
            onActivate: () => demo.toggle('dark'),
            child: Semantics(
              toggled: demo.isOn('dark'),
              enabled: true,
              child: GestureDetector(
                // The whole face takes the tap, its padding included.
                behavior: HitTestBehavior.opaque,
                onTap: () => demo.toggle('dark'),
                child: _SwitchFace(text: 'Dark mode', on: demo.isOn('dark')),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region good-selected
/// Three buttons that choose a view. `selected` marks the one that is
/// chosen; the other two say `selected: false`, so they are known to be
/// part of the same choice.
class GoodSelected extends StatelessWidget {
  const GoodSelected({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-selected',
      builder: (context, demo) => [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final view in const ['Day', 'Week', 'Month'])
              TestId(
                's13-good-selected-${view.toLowerCase()}',
                child: _KeyboardOperable(
                  onActivate: () => demo.choose(view),
                  child: Semantics(
                    button: true,
                    enabled: true,
                    selected: demo.view == view,
                    child: GestureDetector(
                      onTap: () => demo.choose(view),
                      child: _Face(
                        icon: demo.view == view
                            ? Icons.check
                            : Icons.calendar_today,
                        text: view,
                        strong: demo.view == view,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
// #endregion

// #region bad-no-role
/// Defect: the control works by touch, keyboard, and screen reader, but it
/// has no role. On Android and iOS a screen reader reads "Scan barcode" and
/// does not say it is a button.
class BadNoRole extends StatelessWidget {
  const BadNoRole({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-no-role',
      builder: (context, demo) => [
        TestId(
          's13-bad-no-role-scan',
          child: _KeyboardOperable(
            onActivate: demo.press,
            // No Semantics(button: true).
            child: GestureDetector(
              onTap: demo.press,
              child: const _Face(
                icon: Icons.qr_code_scanner,
                text: 'Scan barcode',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-wrong-role
/// Defect: a switch that says it is a button. A screen reader reads "Dark
/// mode, button" and never says whether dark mode is on.
class BadWrongRole extends StatelessWidget {
  const BadWrongRole({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-wrong-role',
      builder: (context, demo) => [
        TestId(
          's13-bad-wrong-role-dark',
          child: _KeyboardOperable(
            onActivate: () => demo.toggle('dark'),
            child: Semantics(
              button: true,
              enabled: true,
              child: GestureDetector(
                // The whole face takes the tap, its padding included.
                behavior: HitTestBehavior.opaque,
                onTap: () => demo.toggle('dark'),
                child: _SwitchFace(text: 'Dark mode', on: demo.isOn('dark')),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-role-on-text
/// Defect: text that does nothing says it is a button. A screen reader
/// reads "Free delivery, button", and activating it has no effect.
class BadRoleOnText extends StatelessWidget {
  const BadRoleOnText({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-role-on-text',
      builder: (context, demo) => [
        TestId(
          's13-bad-role-on-text-delivery',
          child: Semantics(button: true, child: const Text('Free delivery')),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-role-on-standard
/// Defect: a role is added to a widget that already has it. The `Semantics`
/// around the `FilledButton` becomes a second button, with no name, around
/// the real one. There is no `TestId` here: its `MergeSemantics` would join
/// the two and hide the defect.
class BadRoleOnStandard extends StatelessWidget {
  const BadRoleOnStandard({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-role-on-standard',
      builder: (context, demo) => [
        Semantics(
          button: true,
          child: FilledButton(
            key: const ValueKey<String>('s13-bad-role-on-standard-save'),
            onPressed: demo.press,
            child: const Text('Save'),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-action-hidden
/// Defect: the control looks and reads as a button and works by touch and
/// keyboard, but its tap is kept out of the semantics tree. On Android the
/// node has no click action, which is what TalkBack, Switch Access, and
/// Voice Access call. On the web a click sent to the element does nothing.
class BadActionHidden extends StatelessWidget {
  const BadActionHidden({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-action-hidden',
      builder: (context, demo) => [
        TestId(
          's13-bad-action-hidden-scan',
          child: _KeyboardOperable(
            onActivate: demo.press,
            child: Semantics(
              button: true,
              enabled: true,
              child: GestureDetector(
                // The tap is not exposed as a semantics action.
                excludeFromSemantics: true,
                onTap: demo.press,
                child: const _Face(
                  icon: Icons.qr_code_scanner,
                  text: 'Scan barcode',
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

// #region bad-switch-not-enabled
/// Defect: the switch has `toggled` and no `enabled`. It works, but
/// VoiceOver on iOS reads it as dimmed, which tells people it cannot be
/// used (FL-033).
class BadSwitchNotEnabled extends StatelessWidget {
  const BadSwitchNotEnabled({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-switch-not-enabled',
      builder: (context, demo) => [
        TestId(
          's13-bad-switch-not-enabled-dark',
          child: _KeyboardOperable(
            onActivate: () => demo.toggle('dark'),
            child: Semantics(
              toggled: demo.isOn('dark'),
              // No enabled: true.
              child: GestureDetector(
                // The whole face takes the tap, its padding included.
                behavior: HitTestBehavior.opaque,
                onTap: () => demo.toggle('dark'),
                child: _SwitchFace(text: 'Dark mode', on: demo.isOn('dark')),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion
