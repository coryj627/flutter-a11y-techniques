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
          key: ValueKey<String>('f07-${widget.slug}-count'),
          identifier: 'f07-${widget.slug}-count',
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

/// A box drawn by hand, with a tick when [checked]. It has no semantics of
/// its own.
class _DrawnBox extends StatelessWidget {
  const _DrawnBox({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: checked ? colors.primary : colors.surface,
        border: Border.all(color: colors.onSurface, width: 2),
      ),
      child: checked
          ? Icon(Icons.check, size: 18, color: colors.onPrimary)
          : null,
    );
  }
}

const _updates = 'Email me product updates';
// #endregion

// #region good-tile
/// A Material checkbox with its label. `CheckboxListTile` makes the box and
/// the text one control: one name, one role, one state, and a tap anywhere
/// on the row changes it.
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
          'f07-good-tile-updates',
          child: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _on,
            onChanged: (value) {
              setState(() => _on = value!);
              changed();
            },
            title: const Text(_updates),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region good-cupertino
/// A Cupertino checkbox with visible text. `CupertinoCheckbox` has no label
/// of its own on screen, so the box and the text are merged into one
/// control, and a tap on the text changes the box too.
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
            'f07-good-cupertino-updates',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: toggle,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  children: [
                    CupertinoCheckbox(value: _on, onChanged: (_) => toggle()),
                    const SizedBox(width: 8),
                    const Flexible(child: Text(_updates)),
                  ],
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
/// A checkbox drawn by hand. Its name, its checked state, and its tap
/// action are on one `Semantics`. `enabled: true` is there because without
/// it VoiceOver on iOS reads the control as dimmed
/// (docs/flutter-limitations.md, FL-033).
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
            'f07-good-custom-updates',
            child: _KeyboardOperable(
              onActivate: toggle,
              child: Semantics(
                checked: _on,
                enabled: true,
                label: _updates,
                onTap: toggle,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: toggle,
                  child: ExcludeSemantics(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _DrawnBox(checked: _on),
                          const SizedBox(width: 12),
                          const Flexible(child: Text(_updates)),
                        ],
                      ),
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

// #region good-mixed
/// A "Select all" checkbox over two others. With one of the two checked it
/// is neither checked nor unchecked: `tristate: true` and a null value say
/// so.
///
/// Flutter 3.47.5 passes the mixed state on to Android 16 (API 36) and
/// later only, where TalkBack does not speak it. On the web, on iOS, and on
/// older Android versions it is exposed as not checked
/// (docs/flutter-limitations.md, FL-044).
class GoodMixed extends StatefulWidget {
  const GoodMixed({super.key});

  @override
  State<GoodMixed> createState() => _GoodMixedState();
}

class _GoodMixedState extends State<GoodMixed> {
  bool _email = true;
  bool _text = false;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-mixed',
      builder: (context, changed) => [
        TestId(
          'f07-good-mixed-all',
          child: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            tristate: true,
            // true when both are checked, false when neither, null when one.
            value: _email == _text ? _email : null,
            onChanged: (_) {
              // From mixed or unchecked, check both; from checked, clear.
              final all = !(_email && _text);
              setState(() => _email = _text = all);
              changed();
            },
            title: const Text('Select all'),
          ),
        ),
        TestId(
          'f07-good-mixed-email',
          child: CheckboxListTile(
            contentPadding: const EdgeInsets.only(left: 32),
            controlAffinity: ListTileControlAffinity.leading,
            value: _email,
            onChanged: (value) {
              setState(() => _email = value!);
              changed();
            },
            title: const Text('Email'),
          ),
        ),
        TestId(
          'f07-good-mixed-text',
          child: CheckboxListTile(
            contentPadding: const EdgeInsets.only(left: 32),
            controlAffinity: ListTileControlAffinity.leading,
            value: _text,
            onChanged: (value) {
              setState(() => _text = value!);
              changed();
            },
            title: const Text('Text message'),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region good-group
/// Two checkboxes that answer one question. The question is the label of a
/// node around them, so it is tied to the boxes and not only printed above
/// them. The visible text is left out of the semantics, or it would be read
/// twice.
class GoodGroup extends StatefulWidget {
  const GoodGroup({super.key});

  @override
  State<GoodGroup> createState() => _GoodGroupState();
}

class _GoodGroupState extends State<GoodGroup> {
  bool _phone = false;
  bool _post = false;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-group',
      builder: (context, changed) => [
        Semantics(
          key: const ValueKey<String>('f07-good-group-contact'),
          identifier: 'f07-good-group-contact',
          container: true,
          explicitChildNodes: true,
          label: 'Contact me by',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Text(
                  'Contact me by',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TestId(
                'f07-good-group-phone',
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _phone,
                  onChanged: (value) {
                    setState(() => _phone = value!);
                    changed();
                  },
                  title: const Text('Phone'),
                ),
              ),
              TestId(
                'f07-good-group-post',
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _post,
                  onChanged: (value) {
                    setState(() => _post = value!);
                    changed();
                  },
                  title: const Text('Post'),
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
/// A `Checkbox` with text beside it and nothing joining them. The box has
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
            Checkbox(
              key: const ValueKey<String>('f07-bad-unlabelled-box'),
              value: _on,
              onChanged: (value) {
                setState(() => _on = value!);
                changed();
              },
            ),
            const Flexible(child: Text(_updates)),
          ],
        ),
      ],
    );
  }
}
// #endregion

// #region bad-no-state
/// A hand-drawn checkbox exposed as a button. It has a name and it works,
/// but nothing says that it is a checkbox or whether it is checked.
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
            'f07-bad-no-state-updates',
            child: _KeyboardOperable(
              onActivate: toggle,
              child: Semantics(
                button: true,
                label: _updates,
                onTap: toggle,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: toggle,
                  child: ExcludeSemantics(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _DrawnBox(checked: _on),
                          const SizedBox(width: 12),
                          const Flexible(child: Text(_updates)),
                        ],
                      ),
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

// #region bad-mixed-as-unchecked
/// "Select all" with two states only. When one of the two boxes under it is
/// checked it says "not checked", which is not true.
class BadMixedAsUnchecked extends StatefulWidget {
  const BadMixedAsUnchecked({super.key});

  @override
  State<BadMixedAsUnchecked> createState() => _BadMixedAsUncheckedState();
}

class _BadMixedAsUncheckedState extends State<BadMixedAsUnchecked> {
  bool _email = true;
  bool _text = false;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-mixed-as-unchecked',
      builder: (context, changed) => [
        TestId(
          'f07-bad-mixed-as-unchecked-all',
          child: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _email && _text,
            onChanged: (value) {
              setState(() => _email = _text = value!);
              changed();
            },
            title: const Text('Select all'),
          ),
        ),
        TestId(
          'f07-bad-mixed-as-unchecked-email',
          child: CheckboxListTile(
            contentPadding: const EdgeInsets.only(left: 32),
            controlAffinity: ListTileControlAffinity.leading,
            value: _email,
            onChanged: (value) {
              setState(() => _email = value!);
              changed();
            },
            title: const Text('Email'),
          ),
        ),
        TestId(
          'f07-bad-mixed-as-unchecked-text',
          child: CheckboxListTile(
            contentPadding: const EdgeInsets.only(left: 32),
            controlAffinity: ListTileControlAffinity.leading,
            value: _text,
            onChanged: (value) {
              setState(() => _text = value!);
              changed();
            },
            title: const Text('Text message'),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-group-unlabelled
/// The question is printed above the boxes and is tied to nothing. Someone
/// who lands on "Phone" hears a checkbox called "Phone" and not what it is
/// for.
class BadGroupUnlabelled extends StatefulWidget {
  const BadGroupUnlabelled({super.key});

  @override
  State<BadGroupUnlabelled> createState() => _BadGroupUnlabelledState();
}

class _BadGroupUnlabelledState extends State<BadGroupUnlabelled> {
  bool _phone = false;
  bool _post = false;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-group-unlabelled',
      builder: (context, changed) => [
        Text('Contact me by', style: Theme.of(context).textTheme.titleMedium),
        TestId(
          'f07-bad-group-unlabelled-phone',
          child: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _phone,
            onChanged: (value) {
              setState(() => _phone = value!);
              changed();
            },
            title: const Text('Phone'),
          ),
        ),
        TestId(
          'f07-bad-group-unlabelled-post',
          child: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _post,
            onChanged: (value) {
              setState(() => _post = value!);
              changed();
            },
            title: const Text('Post'),
          ),
        ),
      ],
    );
  }
}
// #endregion
