import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../catalog/test_id.dart';

// #region shared
/// Lays out one example and reports how many times its controls were
/// operated, so people and tests can confirm that they worked.
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
          key: ValueKey<String>('s14-${widget.slug}-count'),
          identifier: 's14-${widget.slug}-count',
          liveRegion: true,
          child: Text('Changes: $_count'),
        ),
      ],
    );
  }
}

class _StepIntent extends Intent {
  const _StepIntent(this.by);

  final int by;
}

/// The keyboard half of a custom control and its focus ring. [onActivate]
/// answers Enter and Space; [onStep] answers the arrow keys. It gives the
/// control no role, no value, and no semantics action.
class _KeyboardOperable extends StatefulWidget {
  const _KeyboardOperable({this.onActivate, this.onStep, required this.child});

  final VoidCallback? onActivate;
  final ValueChanged<int>? onStep;
  final Widget child;

  @override
  State<_KeyboardOperable> createState() => _KeyboardOperableState();
}

class _KeyboardOperableState extends State<_KeyboardOperable> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final activate = widget.onActivate;
    final step = widget.onStep;
    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      shortcuts: {
        if (step != null) ...const {
          SingleActivator(LogicalKeyboardKey.arrowRight): _StepIntent(1),
          SingleActivator(LogicalKeyboardKey.arrowUp): _StepIntent(1),
          SingleActivator(LogicalKeyboardKey.arrowLeft): _StepIntent(-1),
          SingleActivator(LogicalKeyboardKey.arrowDown): _StepIntent(-1),
        },
      },
      actions: {
        if (activate != null) ...{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => activate(),
          ),
          ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
            onInvoke: (_) => activate(),
          ),
        },
        if (step != null)
          _StepIntent: CallbackAction<_StepIntent>(
            onInvoke: (intent) => step(intent.by),
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

/// Five stars, [rating] of them filled. A tap on a star sets the rating.
/// The picture has no semantics: each example says what it exposes.
class _Stars extends StatelessWidget {
  const _Stars({required this.rating, required this.onRate});

  final int rating;
  final ValueChanged<int> onRate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var star = 1; star <= 5; star++)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onRate(star),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  star <= rating ? Icons.star : Icons.star_border,
                  color: colors.onSurface,
                  size: 32,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Four numbered circles; the one for [step] is filled. No semantics.
class _StepDots extends StatelessWidget {
  const _StepDots({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        for (var n = 1; n <= 4; n++)
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: n == step ? colors.onSurface : colors.surface,
              border: Border.all(color: colors.onSurface, width: 2),
            ),
            child: Text(
              '$n',
              style: TextStyle(
                color: n == step ? colors.surface : colors.onSurface,
              ),
            ),
          ),
      ],
    );
  }
}

const _repeatModes = ['Off', 'All', 'One'];
const _repeatIcons = [Icons.arrow_forward, Icons.repeat, Icons.repeat_one];

/// What the repeat button looks like in each of its three modes.
class _RepeatFace extends StatelessWidget {
  const _RepeatFace({required this.mode});

  final int mode;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 56,
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(color: colors.onSurface, width: mode == 0 ? 1 : 3),
      ),
      child: Icon(_repeatIcons[mode], color: colors.onSurface),
    );
  }
}

/// The picture of a switch: its text, and a thumb at the left (off) or the
/// right (on) of a track. No semantics of its own.
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

// #region good-rating
/// A star rating drawn by hand. `label` is its name and `value` is the
/// rating in words. `onIncrease` and `onDecrease` let a screen reader change
/// it, and `increasedValue` and `decreasedValue` say what it would become.
class GoodRating extends StatefulWidget {
  const GoodRating({super.key});

  @override
  State<GoodRating> createState() => _GoodRatingState();
}

class _GoodRatingState extends State<GoodRating> {
  int _rating = 3;

  String _words(int rating) => '${rating.clamp(0, 5)} out of 5';

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-rating',
      builder: (context, changed) {
        void rate(int rating) {
          final next = rating.clamp(0, 5);
          if (next == _rating) return;
          setState(() => _rating = next);
          changed();
        }

        return [
          TestId(
            's14-good-rating-rating',
            child: _KeyboardOperable(
              onStep: (by) => rate(_rating + by),
              child: Semantics(
                label: 'Rating',
                value: _words(_rating),
                increasedValue: _words(_rating + 1),
                decreasedValue: _words(_rating - 1),
                onIncrease: () => rate(_rating + 1),
                onDecrease: () => rate(_rating - 1),
                child: _Stars(rating: _rating, onRate: rate),
              ),
            ),
          ),
        ];
      },
    );
  }
}
// #endregion

// #region good-step
/// A step indicator. The four circles are one element named "Progress"
/// whose value says which step this is and how many there are.
class GoodStep extends StatefulWidget {
  const GoodStep({super.key});

  @override
  State<GoodStep> createState() => _GoodStepState();
}

class _GoodStepState extends State<GoodStep> {
  int _step = 2;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-step',
      builder: (context, changed) => [
        Semantics(
          identifier: 's14-good-step-progress',
          container: true,
          label: 'Progress',
          value: 'Step $_step of 4',
          child: ExcludeSemantics(child: _StepDots(step: _step)),
        ),
        TestId(
          's14-good-step-next',
          child: FilledButton(
            onPressed: () {
              setState(() => _step = _step % 4 + 1);
              changed();
            },
            child: const Text('Next step'),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region good-button-value
/// A button with three modes. It is not a switch, so `toggled` does not
/// fit; `value` says which mode it is in, and changes when it is pressed.
class GoodButtonValue extends StatefulWidget {
  const GoodButtonValue({super.key});

  @override
  State<GoodButtonValue> createState() => _GoodButtonValueState();
}

class _GoodButtonValueState extends State<GoodButtonValue> {
  int _mode = 0;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-button-value',
      builder: (context, changed) {
        void next() {
          setState(() => _mode = (_mode + 1) % 3);
          changed();
        }

        return [
          TestId(
            's14-good-button-value-repeat',
            child: _KeyboardOperable(
              onActivate: next,
              child: Semantics(
                button: true,
                enabled: true,
                label: 'Repeat',
                value: _repeatModes[_mode],
                child: GestureDetector(
                  onTap: next,
                  child: _RepeatFace(mode: _mode),
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

// #region good-slider-format
/// A Material `Slider` reports its value as a percentage of its range.
/// `semanticFormatterCallback` replaces that with words that fit what the
/// slider sets. The `MergeSemantics` row gives the slider its name (S01).
class GoodSliderFormat extends StatefulWidget {
  const GoodSliderFormat({super.key});

  @override
  State<GoodSliderFormat> createState() => _GoodSliderFormatState();
}

class _GoodSliderFormatState extends State<GoodSliderFormat> {
  double _minutes = 15;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-slider-format',
      builder: (context, changed) => [
        TestId(
          's14-good-slider-format-timer',
          child: MergeSemantics(
            child: Row(
              children: [
                const Text('Timer'),
                Expanded(
                  child: Slider(
                    value: _minutes,
                    max: 60,
                    divisions: 12,
                    semanticFormatterCallback: (value) =>
                        '${value.round()} minutes',
                    onChanged: (value) {
                      setState(() => _minutes = value);
                      changed();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-rating-no-value
/// Defect: the rating can be read and changed, but it has no value. A
/// screen reader says "Rating, adjustable" and never how many stars.
class BadRatingNoValue extends StatefulWidget {
  const BadRatingNoValue({super.key});

  @override
  State<BadRatingNoValue> createState() => _BadRatingNoValueState();
}

class _BadRatingNoValueState extends State<BadRatingNoValue> {
  int _rating = 3;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-rating-no-value',
      builder: (context, changed) {
        void rate(int rating) {
          final next = rating.clamp(0, 5);
          if (next == _rating) return;
          setState(() => _rating = next);
          changed();
        }

        return [
          TestId(
            's14-bad-rating-no-value-rating',
            child: _KeyboardOperable(
              onStep: (by) => rate(_rating + by),
              child: Semantics(
                label: 'Rating',
                // No value, increasedValue, or decreasedValue.
                onIncrease: () => rate(_rating + 1),
                onDecrease: () => rate(_rating - 1),
                child: _Stars(rating: _rating, onRate: rate),
              ),
            ),
          ),
        ];
      },
    );
  }
}
// #endregion

// #region bad-stale-value
/// Defect: the value is written once and never updated. The stars change
/// and a screen reader goes on saying "3 out of 5".
class BadStaleValue extends StatefulWidget {
  const BadStaleValue({super.key});

  @override
  State<BadStaleValue> createState() => _BadStaleValueState();
}

class _BadStaleValueState extends State<BadStaleValue> {
  int _rating = 3;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-stale-value',
      builder: (context, changed) {
        void rate(int rating) {
          final next = rating.clamp(0, 5);
          if (next == _rating) return;
          setState(() => _rating = next);
          changed();
        }

        return [
          TestId(
            's14-bad-stale-value-rating',
            child: _KeyboardOperable(
              onStep: (by) => rate(_rating + by),
              child: Semantics(
                label: 'Rating',
                // Fixed text, not built from _rating.
                value: '3 out of 5',
                increasedValue: '4 out of 5',
                decreasedValue: '2 out of 5',
                onIncrease: () => rate(_rating + 1),
                onDecrease: () => rate(_rating - 1),
                child: _Stars(rating: _rating, onRate: rate),
              ),
            ),
          ),
        ];
      },
    );
  }
}
// #endregion

// #region bad-step-no-value
/// Defect: the circles are exposed as the numbers 1 to 4, one element each.
/// Nothing says which step is the current one.
class BadStepNoValue extends StatefulWidget {
  const BadStepNoValue({super.key});

  @override
  State<BadStepNoValue> createState() => _BadStepNoValueState();
}

class _BadStepNoValueState extends State<BadStepNoValue> {
  int _step = 2;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-step-no-value',
      builder: (context, changed) => [
        // No Semantics around the circles and no value.
        _StepDots(step: _step),
        TestId(
          's14-bad-step-no-value-next',
          child: FilledButton(
            onPressed: () {
              setState(() => _step = _step % 4 + 1);
              changed();
            },
            child: const Text('Next step'),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-button-no-value
/// Defect: the repeat button shows its mode with an icon only. A screen
/// reader says "Repeat, button" in all three modes.
class BadButtonNoValue extends StatefulWidget {
  const BadButtonNoValue({super.key});

  @override
  State<BadButtonNoValue> createState() => _BadButtonNoValueState();
}

class _BadButtonNoValueState extends State<BadButtonNoValue> {
  int _mode = 0;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-button-no-value',
      builder: (context, changed) {
        void next() {
          setState(() => _mode = (_mode + 1) % 3);
          changed();
        }

        return [
          TestId(
            's14-bad-button-no-value-repeat',
            child: _KeyboardOperable(
              onActivate: next,
              child: Semantics(
                button: true,
                enabled: true,
                label: 'Repeat',
                // No value.
                child: GestureDetector(
                  onTap: next,
                  child: _RepeatFace(mode: _mode),
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

// #region bad-value-on-switch
/// Defect: `value` is used to reword a switch's "on" and "off" as
/// "Activated" and "Deactivated". Flutter has no way to do that (FL-036).
/// TalkBack reads both wordings, VoiceOver on iOS ignores the value, and on
/// the web the value becomes part of the switch's name.
class BadValueOnSwitch extends StatefulWidget {
  const BadValueOnSwitch({super.key});

  @override
  State<BadValueOnSwitch> createState() => _BadValueOnSwitchState();
}

class _BadValueOnSwitchState extends State<BadValueOnSwitch> {
  bool _on = false;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-value-on-switch',
      builder: (context, changed) {
        void toggle() {
          setState(() => _on = !_on);
          changed();
        }

        return [
          TestId(
            's14-bad-value-on-switch-alarm',
            child: _KeyboardOperable(
              onActivate: toggle,
              child: Semantics(
                toggled: _on,
                enabled: true,
                value: _on ? 'Activated' : 'Deactivated',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: toggle,
                  child: _SwitchFace(text: 'Home alarm', on: _on),
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
