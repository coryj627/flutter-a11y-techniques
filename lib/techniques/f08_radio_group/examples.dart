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
          key: ValueKey<String>('f08-${widget.slug}-count'),
          identifier: 'f08-${widget.slug}-count',
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

/// A radio button drawn by hand: a ring, filled when [selected]. It has no
/// semantics of its own.
class _DrawnRadio extends StatelessWidget {
  const _DrawnRadio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 24,
      height: 24,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colors.onSurface, width: 2),
      ),
      child: selected
          ? DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary,
              ),
            )
          : null,
    );
  }
}

/// A drawn radio button and its text in a row at least 48 high.
class _DrawnRow extends StatelessWidget {
  const _DrawnRow({required this.selected, required this.text});

  final bool selected;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DrawnRadio(selected: selected),
          const SizedBox(width: 12),
          Flexible(child: Text(text)),
        ],
      ),
    );
  }
}

const _question = 'Delivery speed';
const _speeds = ['Standard', 'Express', 'Next day'];

/// The id segment for an option: "Next day" is "next-day".
String _slugOf(String option) => option.toLowerCase().replaceAll(' ', '-');

/// The question printed above a group of options.
class _Question extends StatelessWidget {
  const _Question(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleMedium);
}

/// Three hand-built options, one chosen at a time, each wrapped by
/// [semantics]. Used by the examples that build radio buttons from
/// `Semantics` alone.
class _HandBuilt extends StatefulWidget {
  const _HandBuilt({required this.slug, required this.semantics});

  final String slug;
  final Widget Function(
    String option,
    bool selected,
    VoidCallback select,
    Widget child,
  )
  semantics;

  @override
  State<_HandBuilt> createState() => _HandBuiltState();
}

class _HandBuiltState extends State<_HandBuilt> {
  String _speed = 'Express';

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: widget.slug,
      builder: (context, changed) => [
        const _Question(_question),
        for (final option in _speeds)
          TestId(
            'f08-${widget.slug}-${_slugOf(option)}',
            child: Builder(
              builder: (context) {
                void select() {
                  if (_speed == option) return;
                  setState(() => _speed = option);
                  changed();
                }

                return _KeyboardOperable(
                  onActivate: select,
                  child: widget.semantics(
                    option,
                    _speed == option,
                    select,
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: select,
                      child: ExcludeSemantics(
                        child: _DrawnRow(
                          selected: _speed == option,
                          text: option,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
// #endregion

// #region good-group
/// Three Material radio buttons under one question. `RadioGroup` holds the
/// choice and gives the group its role and its arrow keys. `RadioListTile`
/// makes each button and its text one control.
///
/// `RadioGroup` has no parameter for a name (docs/flutter-limitations.md,
/// FL-046), so the question is the label of a node around the group. The
/// visible question is left out of the semantics, or it would be read
/// twice.
class GoodGroup extends StatefulWidget {
  const GoodGroup({super.key});

  @override
  State<GoodGroup> createState() => _GoodGroupState();
}

class _GoodGroupState extends State<GoodGroup> {
  String? _speed = 'Express';

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-group',
      builder: (context, changed) => [
        Semantics(
          key: const ValueKey<String>('f08-good-group-group'),
          identifier: 'f08-good-group-group',
          container: true,
          explicitChildNodes: true,
          label: _question,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ExcludeSemantics(child: _Question(_question)),
              RadioGroup<String>(
                groupValue: _speed,
                onChanged: (value) {
                  setState(() => _speed = value);
                  changed();
                },
                child: Column(
                  children: [
                    for (final option in _speeds)
                      TestId(
                        'f08-good-group-${_slugOf(option)}',
                        child: RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          value: option,
                          title: Text(option),
                        ),
                      ),
                  ],
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

// #region good-cupertino
/// The same with Cupertino radio buttons. Cupertino has no list tile for a
/// radio button, so each row is built by hand: merged, so the text names
/// the button, with a tap handler so the text is part of the target.
class GoodCupertino extends StatefulWidget {
  const GoodCupertino({super.key});

  @override
  State<GoodCupertino> createState() => _GoodCupertinoState();
}

class _GoodCupertinoState extends State<GoodCupertino> {
  String? _speed = 'Express';

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-cupertino',
      builder: (context, changed) {
        void select(String? value) {
          if (value == _speed) return;
          setState(() => _speed = value);
          changed();
        }

        return [
          Semantics(
            key: const ValueKey<String>('f08-good-cupertino-group'),
            identifier: 'f08-good-cupertino-group',
            container: true,
            explicitChildNodes: true,
            label: _question,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ExcludeSemantics(child: _Question(_question)),
                RadioGroup<String>(
                  groupValue: _speed,
                  onChanged: select,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final option in _speeds)
                        TestId(
                          'f08-good-cupertino-${_slugOf(option)}',
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => select(option),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 48),
                              child: Row(
                                children: [
                                  CupertinoRadio<String>(value: option),
                                  const SizedBox(width: 12),
                                  Flexible(child: Text(option)),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
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

// #region good-custom
/// Radio buttons drawn by hand on `RawRadio`, the widget `Radio` and
/// `CupertinoRadio` are built on. `RawRadio` supplies the semantics for
/// every platform (on iOS that is a selected state and a "Not selected"
/// hint, not a checked state) and joins the `RadioGroup` above it, which
/// supplies the arrow keys.
class GoodCustom extends StatefulWidget {
  const GoodCustom({super.key});

  @override
  State<GoodCustom> createState() => _GoodCustomState();
}

class _GoodCustomState extends State<GoodCustom> {
  String? _speed = 'Express';

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-custom',
      builder: (context, changed) => [
        Semantics(
          key: const ValueKey<String>('f08-good-custom-group'),
          identifier: 'f08-good-custom-group',
          container: true,
          explicitChildNodes: true,
          label: _question,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ExcludeSemantics(child: _Question(_question)),
              RadioGroup<String>(
                groupValue: _speed,
                onChanged: (value) {
                  // A tap on the text of the chosen option arrives here too.
                  if (value == _speed) return;
                  setState(() => _speed = value);
                  changed();
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final option in _speeds)
                      TestId(
                        'f08-good-custom-${_slugOf(option)}',
                        child: _RawRadioRow(option: option),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One option: a `RawRadio` that draws a ring, and its text. A tap on the
/// text chooses the option through the group.
class _RawRadioRow extends StatefulWidget {
  const _RawRadioRow({required this.option});

  final String option;

  @override
  State<_RawRadioRow> createState() => _RawRadioRowState();
}

class _RawRadioRowState extends State<_RawRadioRow> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_repaint);
  }

  void _repaint() => setState(() {});

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final group = RadioGroup.maybeOf<String>(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => group?.onChanged(widget.option),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border.all(
            color: _focusNode.hasFocus ? colors.onSurface : colors.surface,
            width: 3,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RawRadio<String>(
                  value: widget.option,
                  groupRegistry: group,
                  mouseCursor: const WidgetStatePropertyAll<MouseCursor>(
                    SystemMouseCursors.click,
                  ),
                  toggleable: false,
                  focusNode: _focusNode,
                  autofocus: false,
                  enabled: true,
                  builder: (context, state) =>
                      _DrawnRadio(selected: state.value ?? false),
                ),
                const SizedBox(width: 12),
                Flexible(child: Text(widget.option)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// #endregion

// #region good-context
/// A question with the answers "Yes" and "No". Read on its own, "Yes, radio
/// button" says nothing about what is being agreed to, and on Android and
/// iOS the question is not read with the answers. Each answer keeps its
/// short visible text and has a name that begins with it and carries the
/// question.
class GoodContext extends StatefulWidget {
  const GoodContext({super.key});

  @override
  State<GoodContext> createState() => _GoodContextState();
}

class _GoodContextState extends State<GoodContext> {
  String? _answer = 'no';

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-context',
      builder: (context, changed) => [
        Semantics(
          key: const ValueKey<String>('f08-good-context-group'),
          identifier: 'f08-good-context-group',
          container: true,
          explicitChildNodes: true,
          label: 'Are you at home?',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ExcludeSemantics(child: _Question('Are you at home?')),
              RadioGroup<String>(
                groupValue: _answer,
                onChanged: (value) {
                  setState(() => _answer = value);
                  changed();
                },
                child: const Column(
                  children: [
                    TestId(
                      'f08-good-context-yes',
                      child: RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        value: 'yes',
                        title: Text('Yes', semanticsLabel: 'Yes, I am at home'),
                      ),
                    ),
                    TestId(
                      'f08-good-context-no',
                      child: RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        value: 'no',
                        title: Text(
                          'No',
                          semanticsLabel: 'No, I am not at home',
                        ),
                      ),
                    ),
                  ],
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
/// `Radio` buttons with text beside them and nothing joining them. Each
/// button has no name, and a tap on the text does nothing.
class BadUnlabelled extends StatefulWidget {
  const BadUnlabelled({super.key});

  @override
  State<BadUnlabelled> createState() => _BadUnlabelledState();
}

class _BadUnlabelledState extends State<BadUnlabelled> {
  String? _speed = 'Express';

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-unlabelled',
      builder: (context, changed) => [
        const _Question(_question),
        RadioGroup<String>(
          groupValue: _speed,
          onChanged: (value) {
            setState(() => _speed = value);
            changed();
          },
          child: Column(
            children: [
              for (final option in _speeds)
                Row(
                  children: [
                    Radio<String>(
                      key: ValueKey<String>(
                        'f08-bad-unlabelled-${_slugOf(option)}',
                      ),
                      value: option,
                    ),
                    Flexible(child: Text(option)),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-group-unlabelled
/// The question is printed above the radio buttons and is tied to nothing.
/// The group has a role and no name.
class BadGroupUnlabelled extends StatefulWidget {
  const BadGroupUnlabelled({super.key});

  @override
  State<BadGroupUnlabelled> createState() => _BadGroupUnlabelledState();
}

class _BadGroupUnlabelledState extends State<BadGroupUnlabelled> {
  String? _speed = 'Express';

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-group-unlabelled',
      builder: (context, changed) => [
        const _Question(_question),
        RadioGroup<String>(
          groupValue: _speed,
          onChanged: (value) {
            setState(() => _speed = value);
            changed();
          },
          child: Column(
            children: [
              for (final option in _speeds)
                TestId(
                  'f08-bad-group-unlabelled-${_slugOf(option)}',
                  child: RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: option,
                    title: Text(option),
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

// #region bad-no-state
/// Hand-drawn radio buttons exposed as buttons. Each has a name and works,
/// but nothing says which one is chosen.
class BadNoState extends StatelessWidget {
  const BadNoState({super.key});

  @override
  Widget build(BuildContext context) {
    return _HandBuilt(
      slug: 'bad-no-state',
      semantics: (option, selected, select, child) =>
          Semantics(button: true, label: option, onTap: select, child: child),
    );
  }
}
// #endregion

// #region bad-checkbox-role
/// Hand-drawn radio buttons exposed as checkboxes. They say "checked" and
/// "not checked", which is true, and "checkbox", which tells the user that
/// more than one can be chosen.
class BadCheckboxRole extends StatelessWidget {
  const BadCheckboxRole({super.key});

  @override
  Widget build(BuildContext context) {
    return _HandBuilt(
      slug: 'bad-checkbox-role',
      semantics: (option, selected, select, child) => Semantics(
        checked: selected,
        enabled: true,
        label: option,
        onTap: select,
        child: child,
      ),
    );
  }
}
// #endregion

// #region bad-checked-only
/// Hand-drawn radio buttons with the two flags the Android and web engines
/// read: `checked` and `inMutuallyExclusiveGroup`. On iOS neither is read
/// for a radio button, so VoiceOver says the name and "Button" and gives no
/// state (docs/flutter-limitations.md, FL-047). `RawRadio` adds what iOS
/// needs; see `good-custom`.
class BadCheckedOnly extends StatelessWidget {
  const BadCheckedOnly({super.key});

  @override
  Widget build(BuildContext context) {
    return _HandBuilt(
      slug: 'bad-checked-only',
      semantics: (option, selected, select, child) => Semantics(
        checked: selected,
        inMutuallyExclusiveGroup: true,
        enabled: true,
        label: option,
        onTap: select,
        child: child,
      ),
    );
  }
}
// #endregion
