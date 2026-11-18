import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../catalog/test_id.dart';

// #region shared
/// Lays out one example and reports how many times its value changed, so
/// people and tests can confirm that the control worked.
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
          key: ValueKey<String>('f10-${widget.slug}-count'),
          identifier: 'f10-${widget.slug}-count',
          liveRegion: true,
          child: Text('Changes: $_count'),
        ),
      ],
    );
  }
}

/// The volume as people read it: 0.4 is "40%".
String _percent(double volume) => '${(volume.clamp(0, 1) * 100).round()}%';

/// Home and End for an SDK slider, which has the arrow keys and not these
/// (docs/flutter-limitations.md, FL-122). [to] is called with the first or
/// the last value.
class _HomeAndEnd extends StatelessWidget {
  const _HomeAndEnd({
    required this.first,
    required this.last,
    required this.to,
    required this.child,
  });

  final double first;
  final double last;
  final ValueChanged<double> to;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.home): () => to(first),
        const SingleActivator(LogicalKeyboardKey.end): () => to(last),
      },
      child: child,
    );
  }
}

/// A move asked for with the keyboard: one step up or down, or to an end.
class _StepIntent extends Intent {
  const _StepIntent(this.by);

  /// 1 or -1 for a step; [_toLast] or [_toFirst] for an end.
  final int by;
}

const _toLast = 1000;
const _toFirst = -1000;

/// The keyboard half of a slider and its focus ring, as the APG slider
/// pattern lays it out: Right and Up a step up, Left and Down a step down,
/// Home the first value, End the last. [onStep] gets 1, -1, [_toLast], or
/// [_toFirst]. It gives the control no role, no name, and no value.
class _KeyboardOperable extends StatefulWidget {
  const _KeyboardOperable({required this.onStep, required this.child});

  final ValueChanged<int> onStep;
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
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.arrowRight): _StepIntent(1),
        SingleActivator(LogicalKeyboardKey.arrowUp): _StepIntent(1),
        SingleActivator(LogicalKeyboardKey.arrowLeft): _StepIntent(-1),
        SingleActivator(LogicalKeyboardKey.arrowDown): _StepIntent(-1),
        SingleActivator(LogicalKeyboardKey.home): _StepIntent(_toFirst),
        SingleActivator(LogicalKeyboardKey.end): _StepIntent(_toLast),
      },
      actions: {
        _StepIntent: CallbackAction<_StepIntent>(
          onInvoke: (intent) => widget.onStep(intent.by),
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

/// A volume from 0 to 10 tenths, with what a key asks for applied to it.
int _stepped(int tenths, int by) => switch (by) {
  _toLast => 10,
  _toFirst => 0,
  _ => (tenths + by).clamp(0, 10),
};

/// A slider drawn by hand: a track, the part of it up to [tenths] filled,
/// and a thumb. Dragging along it sets the value; with [tapToSet] a tap on
/// the track does too. It has no semantics of its own.
class _DrawnSlider extends StatelessWidget {
  const _DrawnSlider({
    required this.tenths,
    required this.onSet,
    this.tapToSet = true,
  });

  final int tenths;
  final ValueChanged<int> onSet;
  final bool tapToSet;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int at(Offset position) =>
            (position.dx / width * 10).round().clamp(0, 10);
        return ExcludeSemantics(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: tapToSet ? (d) => onSet(at(d.localPosition)) : null,
            onHorizontalDragUpdate: (d) => onSet(at(d.localPosition)),
            child: SizedBox(
              width: width,
              height: 48,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(height: 4, color: colors.onSurfaceVariant),
                  FractionallySizedBox(
                    widthFactor: tenths / 10,
                    child: Container(height: 4, color: colors.primary),
                  ),
                  Align(
                    alignment: Alignment(tenths / 5 - 1, 0),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A volume slider drawn by hand and given its semantics: the slider flag,
/// the visible text as its name, its value, the values one step either
/// side, and the actions that take those steps. [keyboard] wraps it in
/// [_KeyboardOperable]; [tapToSet] is passed to [_DrawnSlider].
class _CustomVolume extends StatefulWidget {
  const _CustomVolume({
    required this.slug,
    this.keyboard = true,
    this.tapToSet = true,
  });

  final String slug;
  final bool keyboard;
  final bool tapToSet;

  @override
  State<_CustomVolume> createState() => _CustomVolumeState();
}

class _CustomVolumeState extends State<_CustomVolume> {
  int _tenths = 4;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: widget.slug,
      builder: (context, changed) {
        void set(int tenths) {
          if (tenths == _tenths) return;
          setState(() => _tenths = tenths);
          changed();
        }

        Widget slider = Semantics(
          slider: true,
          label: 'Volume',
          value: _percent(_tenths / 10),
          increasedValue: _percent(_stepped(_tenths, 1) / 10),
          decreasedValue: _percent(_stepped(_tenths, -1) / 10),
          onIncrease: () => set(_stepped(_tenths, 1)),
          onDecrease: () => set(_stepped(_tenths, -1)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ExcludeSemantics(child: Text('Volume')),
              _DrawnSlider(
                tenths: _tenths,
                onSet: set,
                tapToSet: widget.tapToSet,
              ),
            ],
          ),
        );
        if (widget.keyboard) {
          slider = _KeyboardOperable(
            onStep: (by) => set(_stepped(_tenths, by)),
            child: slider,
          );
        }
        return [TestId('f10-${widget.slug}-volume', child: slider)];
      },
    );
  }
}
// #endregion

// #region good-material
/// A Material `Slider` and the text above it, joined into one control by
/// `TestId`'s `MergeSemantics`, so the visible text is the slider's name.
/// A tap anywhere on the track sets the value as well as a drag, and the
/// arrow keys move it a step. `_HomeAndEnd` adds the Home and End keys,
/// which `Slider` does not have.
///
/// On the web the name does not reach the slider element (FL-028), and
/// the slider adds an empty element over the whole screen (FL-029).
class GoodMaterial extends StatefulWidget {
  const GoodMaterial({super.key});

  @override
  State<GoodMaterial> createState() => _GoodMaterialState();
}

class _GoodMaterialState extends State<GoodMaterial> {
  double _volume = 0.4;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-material',
      builder: (context, changed) {
        void set(double volume) {
          if (volume == _volume) return;
          setState(() => _volume = volume);
          changed();
        }

        return [
          TestId(
            'f10-good-material-volume',
            child: _HomeAndEnd(
              first: 0,
              last: 1,
              to: set,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Volume'),
                  Slider(value: _volume, divisions: 10, onChanged: set),
                ],
              ),
            ),
          ),
        ];
      },
    );
  }
}
// #endregion

// #region good-cupertino
/// A `CupertinoSlider` and its text, joined in the same way. A
/// `CupertinoSlider` takes no keyboard focus and moves only when its thumb
/// is dragged (FL-120, FL-121), so it is given the keyboard with
/// `_KeyboardOperable`, and two buttons that move it a step for anyone who
/// cannot drag.
class GoodCupertino extends StatefulWidget {
  const GoodCupertino({super.key});

  @override
  State<GoodCupertino> createState() => _GoodCupertinoState();
}

class _GoodCupertinoState extends State<GoodCupertino> {
  int _tenths = 4;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-cupertino',
      builder: (context, changed) {
        void set(int tenths) {
          if (tenths == _tenths) return;
          setState(() => _tenths = tenths);
          changed();
        }

        return [
          TestId(
            'f10-good-cupertino-volume',
            child: _KeyboardOperable(
              onStep: (by) => set(_stepped(_tenths, by)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Volume'),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoSlider(
                      value: _tenths / 10,
                      divisions: 10,
                      onChanged: (volume) => set((volume * 10).round()),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TestId(
                'f10-good-cupertino-down',
                child: CupertinoButton.tinted(
                  onPressed: () => set(_stepped(_tenths, -1)),
                  child: const Text('Volume down'),
                ),
              ),
              TestId(
                'f10-good-cupertino-up',
                child: CupertinoButton.tinted(
                  onPressed: () => set(_stepped(_tenths, 1)),
                  child: const Text('Volume up'),
                ),
              ),
            ],
          ),
        ];
      },
    );
  }
}
// #endregion

// #region good-custom
/// A slider drawn by hand on `Semantics`: `slider: true`, the visible text
/// as its `label`, its `value`, `increasedValue` and `decreasedValue`, and
/// `onIncrease` and `onDecrease`. `_KeyboardOperable` gives it focus and
/// the APG keys, and a tap on the track sets it as well as a drag.
class GoodCustom extends StatelessWidget {
  const GoodCustom({super.key});

  @override
  Widget build(BuildContext context) =>
      const _CustomVolume(slug: 'good-custom');
}
// #endregion

// #region good-value-text
/// A rating from 0 to 10. `Slider` reports a value as a percentage of its
/// range unless told otherwise; `semanticFormatterCallback` makes it the
/// words on the screen, "4 out of 10". The visible value is left out of
/// the semantics so that the name stays "Rating" as the value changes.
class GoodValueText extends StatefulWidget {
  const GoodValueText({super.key});

  @override
  State<GoodValueText> createState() => _GoodValueTextState();
}

class _GoodValueTextState extends State<GoodValueText> {
  double _rating = 4;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-value-text',
      builder: (context, changed) {
        void set(double rating) {
          if (rating == _rating) return;
          setState(() => _rating = rating);
          changed();
        }

        return [
          TestId(
            'f10-good-value-text-rating',
            child: _HomeAndEnd(
              first: 0,
              last: 10,
              to: set,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rating'),
                  Slider(
                    value: _rating,
                    max: 10,
                    divisions: 10,
                    semanticFormatterCallback: (rating) =>
                        '${rating.round()} out of 10',
                    onChanged: set,
                  ),
                  ExcludeSemantics(child: Text('${_rating.round()} out of 10')),
                ],
              ),
            ),
          ),
        ];
      },
    );
  }
}
// #endregion

// #region bad-unlabelled
/// The text "Volume" above a Material `Slider`, with nothing joining them.
/// The slider has no name: a screen reader says "40%, slider" and nothing
/// says what it sets.
class BadUnlabelled extends StatefulWidget {
  const BadUnlabelled({super.key});

  @override
  State<BadUnlabelled> createState() => _BadUnlabelledState();
}

class _BadUnlabelledState extends State<BadUnlabelled> {
  double _volume = 0.4;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-unlabelled',
      builder: (context, changed) {
        void set(double volume) {
          if (volume == _volume) return;
          setState(() => _volume = volume);
          changed();
        }

        return [
          const Text('Volume'),
          TestId(
            'f10-bad-unlabelled-volume',
            child: _HomeAndEnd(
              first: 0,
              last: 1,
              to: set,
              child: Slider(value: _volume, divisions: 10, onChanged: set),
            ),
          ),
        ];
      },
    );
  }
}
// #endregion

// #region bad-indicator-label
/// A Material `Slider` with `label`, the number shown above the thumb
/// while it moves. `Slider` puts that text in its semantics label too
/// (FL-123), so the name becomes "Volume" and the number, and changes
/// with every step.
class BadIndicatorLabel extends StatefulWidget {
  const BadIndicatorLabel({super.key});

  @override
  State<BadIndicatorLabel> createState() => _BadIndicatorLabelState();
}

class _BadIndicatorLabelState extends State<BadIndicatorLabel> {
  double _volume = 0.4;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-indicator-label',
      builder: (context, changed) {
        void set(double volume) {
          if (volume == _volume) return;
          setState(() => _volume = volume);
          changed();
        }

        return [
          TestId(
            'f10-bad-indicator-label-volume',
            child: _HomeAndEnd(
              first: 0,
              last: 1,
              to: set,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Volume'),
                  Slider(
                    value: _volume,
                    divisions: 10,
                    label: '${(_volume * 10).round()}',
                    onChanged: set,
                  ),
                ],
              ),
            ),
          ),
        ];
      },
    );
  }
}
// #endregion

// #region bad-percent-value
/// The rating from 0 to 10 with no `semanticFormatterCallback`. The screen
/// says "4 out of 10" and a screen reader says "40%".
class BadPercentValue extends StatefulWidget {
  const BadPercentValue({super.key});

  @override
  State<BadPercentValue> createState() => _BadPercentValueState();
}

class _BadPercentValueState extends State<BadPercentValue> {
  double _rating = 4;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-percent-value',
      builder: (context, changed) {
        void set(double rating) {
          if (rating == _rating) return;
          setState(() => _rating = rating);
          changed();
        }

        return [
          TestId(
            'f10-bad-percent-value-rating',
            child: _HomeAndEnd(
              first: 0,
              last: 10,
              to: set,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rating'),
                  Slider(
                    value: _rating,
                    max: 10,
                    divisions: 10,
                    onChanged: set,
                  ),
                  ExcludeSemantics(child: Text('${_rating.round()} out of 10')),
                ],
              ),
            ),
          ),
        ];
      },
    );
  }
}
// #endregion

// #region bad-no-keyboard
/// The custom slider with its semantics and without `_KeyboardOperable`.
/// A screen reader can read and adjust it, and the keyboard cannot reach
/// it: Tab goes past it.
class BadNoKeyboard extends StatelessWidget {
  const BadNoKeyboard({super.key});

  @override
  Widget build(BuildContext context) =>
      const _CustomVolume(slug: 'bad-no-keyboard', keyboard: false);
}
// #endregion

// #region bad-drag-only
/// The custom slider whose track does not answer a tap. The value moves
/// only while the thumb is dragged, which some people cannot do.
class BadDragOnly extends StatelessWidget {
  const BadDragOnly({super.key});

  @override
  Widget build(BuildContext context) =>
      const _CustomVolume(slug: 'bad-drag-only', tapToSet: false);
}
// #endregion
