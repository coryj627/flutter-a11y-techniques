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
          key: ValueKey<String>('s15-${widget.slug}-count'),
          identifier: 's15-${widget.slug}-count',
          liveRegion: true,
          child: Text('Changes: $_count'),
        ),
      ],
    );
  }
}

/// The keyboard half of a custom button and its focus ring: Enter and Space
/// call [onActivate]. It gives the control no role, no name, and no hint.
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

/// A song in a list: its title and the artist. A tap plays it, and nothing
/// in the row's text says so.
class _SongRow extends StatelessWidget {
  const _SongRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Night Ferry'),
      subtitle: const Text('The Lanterns'),
      onTap: onTap,
    );
  }
}
// #endregion

// #region good-result
/// A Material button whose name does not say what it does to the item. The
/// hint says what happens: a sentence in the third person, with no gesture
/// and no control type in it.
///
/// A Material button is a semantics container, so a `Semantics(hint:)`
/// around it lands on a node of its own (see `bad-hint-detached`).
/// `MergeSemantics` puts the hint on the button.
class GoodResult extends StatelessWidget {
  const GoodResult({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-result',
      builder: (context, changed) => [
        TestId(
          's15-good-result-favorite',
          child: MergeSemantics(
            child: Semantics(
              hint: 'Adds this item to your favorites.',
              child: FilledButton.icon(
                onPressed: changed,
                icon: const Icon(Icons.favorite_border),
                label: const Text('Favorite'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region good-row
/// A row whose text is a song and an artist. Nothing in that name says what
/// a tap does, so the hint does.
class GoodRow extends StatelessWidget {
  const GoodRow({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-row',
      builder: (context, changed) => [
        TestId(
          's15-good-row-song',
          child: Semantics(
            hint: 'Plays the song.',
            child: _SongRow(onTap: changed),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region good-cupertino
/// The same hint on a Cupertino button. `CupertinoButton` is not a semantics
/// container, so the hint joins the button's node without `MergeSemantics`.
class GoodCupertino extends StatelessWidget {
  const GoodCupertino({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-cupertino',
      builder: (context, changed) => [
        TestId(
          's15-good-cupertino-share',
          child: Semantics(
            hint: 'Shares the current page.',
            // Flutter 3.47.5: on web Enter is ButtonActivateIntent, which
            // CupertinoButton does not handle (docs/flutter-limitations.md,
            // FL-002). This adds the missing action; Space already works.
            child: Actions(
              actions: {
                ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
                  onInvoke: (_) {
                    changed();
                    return null;
                  },
                ),
              },
              child: CupertinoButton.filled(
                onPressed: changed,
                child: const Text('Share'),
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
/// A button drawn by hand. Its role, name, hint, and tap action are all on
/// one `Semantics`.
class GoodCustom extends StatelessWidget {
  const GoodCustom({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _Demo(
      slug: 'good-custom',
      builder: (context, changed) => [
        TestId(
          's15-good-custom-archive',
          child: _KeyboardOperable(
            onActivate: changed,
            child: Semantics(
              button: true,
              label: 'Archive',
              hint: 'Moves this message out of the inbox.',
              onTap: changed,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: changed,
                child: ExcludeSemantics(
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 96,
                      minHeight: 48,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.onSurface, width: 2),
                    ),
                    child: Text(
                      'Archive',
                      style: TextStyle(color: colors.onSurface),
                    ),
                  ),
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

// #region good-field
/// A field whose rule is on the screen as text and also in the field's
/// hint, so a screen reader user hears it with focus on the field. The text
/// stays readable on its own: a hint can be turned off.
class GoodField extends StatelessWidget {
  const GoodField({super.key});

  static const _rule = '3 to 12 letters or numbers.';

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-field',
      builder: (context, changed) => [
        TestId(
          's15-good-field-username',
          child: Semantics(
            hint: _rule,
            child: TextField(
              onChanged: (_) => changed(),
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
        const Text(_rule, key: ValueKey<String>('s15-good-field-rule')),
      ],
    );
  }
}
// #endregion

// #region bad-gesture
/// The hint names a gesture. A screen reader already says how to activate a
/// control, in the words for the way the person is using it.
class BadGesture extends StatelessWidget {
  const BadGesture({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-gesture',
      builder: (context, changed) => [
        TestId(
          's15-bad-gesture-favorite',
          child: MergeSemantics(
            child: Semantics(
              hint: 'Double tap to add this item to your favorites.',
              child: FilledButton.icon(
                onPressed: changed,
                icon: const Icon(Icons.favorite_border),
                label: const Text('Favorite'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-repeats-label
/// The hint is the name again.
class BadRepeatsLabel extends StatelessWidget {
  const BadRepeatsLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-repeats-label',
      builder: (context, changed) => [
        TestId(
          's15-bad-repeats-label-delete',
          child: MergeSemantics(
            child: Semantics(
              hint: 'Delete',
              child: FilledButton(
                onPressed: changed,
                child: const Text('Delete'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-control-type
/// The hint says what kind of control this is, which the role already says.
class BadControlType extends StatelessWidget {
  const BadControlType({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-control-type',
      builder: (context, changed) => [
        TestId(
          's15-bad-control-type-share',
          child: MergeSemantics(
            child: Semantics(
              hint: 'This button shares the current page.',
              child: FilledButton(
                onPressed: changed,
                child: const Text('Share'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-no-hint
/// The song row with no hint. Its name is a title and an artist, and
/// nothing says what a tap does.
class BadNoHint extends StatelessWidget {
  const BadNoHint({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-no-hint',
      builder: (context, changed) => [
        TestId('s15-bad-no-hint-song', child: _SongRow(onTap: changed)),
      ],
    );
  }
}
// #endregion

// #region bad-hint-detached
/// `Semantics(hint:)` around a Material button with nothing to merge them.
/// The button is a semantics container, so the hint is left on a node of
/// its own, with no name and no action. The button has no hint.
///
/// No `TestId` here: its `MergeSemantics` would put the hint back.
class BadHintDetached extends StatelessWidget {
  const BadHintDetached({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-hint-detached',
      builder: (context, changed) => [
        Semantics(
          hint: 'Adds this item to your favorites.',
          child: FilledButton.icon(
            key: const ValueKey<String>('s15-bad-hint-detached-favorite'),
            onPressed: changed,
            icon: const Icon(Icons.favorite_border),
            label: const Text('Favorite'),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-hint-only
/// The rule for the field is in its hint and nowhere on the screen. People
/// who do not use a screen reader never get it, and people who have turned
/// hints off do not either.
class BadHintOnly extends StatelessWidget {
  const BadHintOnly({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-hint-only',
      builder: (context, changed) => [
        TestId(
          's15-bad-hint-only-username',
          child: Semantics(
            hint: '3 to 12 letters or numbers.',
            child: TextField(
              onChanged: (_) => changed(),
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion
