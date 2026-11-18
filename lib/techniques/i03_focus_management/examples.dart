import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../catalog/test_id.dart';

// #region shared
/// The trails every example starts with: the last part of each Remove
/// button's identifier, and the trail's name.
const _trails = [
  ('ridge', 'Ridge trail'),
  ('lake', 'Lake loop'),
  ('summit', 'Summit path'),
];

/// Asks whether to remove the trail [name]. Completes with true to remove
/// it, and false or null to keep it. Each example asks in its own way.
typedef _Ask = Future<bool?> Function(
  BuildContext context,
  _TrailsState trails,
  String name,
);

/// How long after a question has closed its route has gone, and the
/// framework has sent the screen reader back to where it was: the longest
/// route transition here (the action sheet's 335 ms), and Android's 300 ms
/// on top, with room to spare.
const _afterTheRoute = Duration(seconds: 1);

/// One Remove button, drawn the way the example draws its buttons.
typedef _RemoveButton = Widget Function(
  String label,
  VoidCallback onPressed,
  FocusNode focusNode,
);

/// A list of saved trails, each with a button that removes it after asking
/// first, and the number left at the end, so that people and tests can see
/// what a key did.
///
/// When a trail is removed its button goes with it, and the button that
/// had focus is gone. Focus is then put on the next trail's button, or on
/// the one before when the last trail went: keyboard focus at once, and
/// the screen reader's once the question has closed (see [_TrailsState]).
class _Trails extends StatefulWidget {
  const _Trails({required this.slug, required this.ask, required this.button});

  final String slug;
  final _Ask ask;
  final _RemoveButton button;

  @override
  State<_Trails> createState() => _TrailsState();
}

class _TrailsState extends State<_Trails> {
  final List<(String, String)> _left = [..._trails];
  final Map<String, FocusNode> _nodes = {
    for (final (key, _) in _trails) key: FocusNode(),
  };

  /// One key per button, on the button's own semantics node, for the
  /// screen reader's focus request.
  final Map<String, GlobalKey> _keys = {
    for (final (key, _) in _trails) key: GlobalKey(),
  };

  /// The test identifier of the part [part] of this example.
  String id(String part) => 'i03-${widget.slug}-$part';

  @override
  void dispose() {
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> remove((String, String) trail) async {
    final yes = await widget.ask(context, this, trail.$2);
    if (yes != true || !mounted) return;
    final index = _left.indexOf(trail);
    setState(() => _left.remove(trail));
    if (_left.isEmpty) return;
    final next = _left[index < _left.length ? index : _left.length - 1].$1;
    // Keyboard focus, and on the web the screen reader with it.
    _nodes[next]!.requestFocus();
    // On Android and iOS, when the question's route has gone, the
    // framework sends the screen reader back to the button that opened it
    // (on Android 300 ms later). That button has just been removed, so the
    // screen reader is left at the top of the screen, and a move made
    // before then is undone (docs/flutter-limitations.md, FL-442). So the
    // screen reader is sent to the next button once that has happened.
    Future<void>.delayed(_afterTheRoute, () {
      if (!mounted) return;
      _keys[next]!.currentContext?.findRenderObject()?.sendSemanticsEvent(
        const FocusSemanticEvent(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text('Saved trails', style: Theme.of(context).textTheme.titleMedium),
        for (final trail in _left)
          KeyedSubtree(
            key: _keys[trail.$1],
            child: TestId(
              id('remove-${trail.$1}'),
              child: widget.button(
                'Remove ${trail.$2}',
                () => remove(trail),
                _nodes[trail.$1]!,
              ),
            ),
          ),
        Semantics(
          key: ValueKey<String>(id('count')),
          identifier: id('count'),
          child: Text('Saved: ${_left.length}'),
        ),
      ],
    );
  }
}

Widget _materialButton(String label, VoidCallback onPressed, FocusNode node) =>
    TextButton(focusNode: node, onPressed: onPressed, child: Text(label));

/// The question every Material example asks, in an `AlertDialog`.
Widget _materialQuestion(
  BuildContext context,
  _TrailsState trails,
  String name,
) => AlertDialog(
  title: Text('Remove $name?'),
  content: const Text('It goes from your saved trails.'),
  actions: [
    TestId(
      trails.id('cancel'),
      child: TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Cancel'),
      ),
    ),
    TestId(
      trails.id('confirm'),
      child: TextButton(
        onPressed: () => Navigator.pop(context, true),
        child: const Text('Remove'),
      ),
    ),
  ],
);
// #endregion

// #region good-material
/// `showDialog` opens the question as a route of its own. The route takes
/// keyboard focus when it opens, so the next Tab is inside it, and when it
/// closes the screen under it puts focus back on the button that opened
/// it. When a trail is removed its button goes too, so focus is put on the
/// next trail's button.
class GoodMaterial extends StatelessWidget {
  const GoodMaterial({super.key});

  @override
  Widget build(BuildContext context) {
    return _Trails(
      slug: 'good-material',
      button: _materialButton,
      ask: (context, trails, name) => showDialog<bool>(
        context: context,
        builder: (context) => _materialQuestion(context, trails, name),
      ),
    );
  }
}
// #endregion

// #region good-cupertino
/// The Cupertino way to confirm a removal is an action sheet. Its actions
/// take keyboard focus; a `CupertinoAlertDialog`'s do not
/// (docs/flutter-limitations.md, FL-440). On the web Enter is
/// `ButtonActivateIntent`, which neither `CupertinoButton` nor
/// `CupertinoActionSheetAction` handles, so it is added around each
/// (FL-002).
class GoodCupertino extends StatelessWidget {
  const GoodCupertino({super.key});

  @override
  Widget build(BuildContext context) {
    return _Trails(
      slug: 'good-cupertino',
      button: (label, onPressed, node) => _enterToo(
        onPressed,
        CupertinoButton(
          focusNode: node,
          onPressed: onPressed,
          child: Text(label),
        ),
      ),
      ask: (context, trails, name) => showCupertinoModalPopup<bool>(
        context: context,
        builder: (context) => CupertinoActionSheet(
          // The sheet's own grey for these is too faint to read
          // (FL-441), so they are given the label colour.
          title: Text('Remove $name?', style: _label(context)),
          message: Text(
            'It goes from your saved trails.',
            style: _label(context),
          ),
          actions: [
            TestId(
              trails.id('confirm'),
              child: _enterToo(
                () => Navigator.pop(context, true),
                CupertinoActionSheetAction(
                  isDestructiveAction: true,
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Remove'),
                ),
              ),
            ),
          ],
          cancelButton: TestId(
            trails.id('cancel'),
            child: _enterToo(
              () => Navigator.pop(context, false),
              CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

TextStyle _label(BuildContext context) =>
    TextStyle(color: CupertinoColors.label.resolveFrom(context));

/// Makes Enter on the web activate [child], as Space already does.
Widget _enterToo(VoidCallback onPressed, Widget child) => Actions(
  actions: {
    ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
      onInvoke: (_) {
        onPressed();
        return null;
      },
    ),
  },
  child: child,
);
// #endregion

// #region good-widgets
/// `showGeneralDialog`, the widgets layer's dialog route, for a question
/// drawn by hand. It moves focus in and back as `showDialog` does; here
/// `autofocus` also puts focus straight on Cancel, the choice that loses
/// nothing.
class GoodWidgets extends StatelessWidget {
  const GoodWidgets({super.key});

  @override
  Widget build(BuildContext context) {
    return _Trails(
      slug: 'good-widgets',
      button: _materialButton,
      ask: (context, trails, name) => showGeneralDialog<bool>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Keep $name',
        // What the dialog is to assistive technology, its role and name,
        // is C08's; this example is about where focus goes.
        pageBuilder: (context, _, _) => Center(
          child: _Card(
            children: [
              Text(
                'Remove $name?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Text('It goes from your saved trails.'),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TestId(
                    trails.id('cancel'),
                    child: TextButton(
                      autofocus: true,
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  TestId(
                    trails.id('confirm'),
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Remove'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A plain card for the question.
class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: children,
        ),
      ),
    );
  }
}
// #endregion

// #region bad-focus-left-behind
class BadFocusLeftBehind extends StatelessWidget {
  const BadFocusLeftBehind({super.key});

  @override
  Widget build(BuildContext context) {
    return _Trails(
      slug: 'bad-focus-left-behind',
      button: _materialButton,
      ask: (context, trails, name) => showDialog<bool>(
        context: context,
        // Defect: the dialog route does not take focus when it opens.
        // Focus stays on the Remove button behind the dialog, Tab goes on
        // to the controls behind it, and the dialog's buttons come only
        // after every control on the screen.
        requestFocus: false,
        builder: (context) => _materialQuestion(context, trails, name),
      ),
    );
  }
}
// #endregion

// #region bad-opens-on-focus
class BadOpensOnFocus extends StatefulWidget {
  const BadOpensOnFocus({super.key});

  @override
  State<BadOpensOnFocus> createState() => _BadOpensOnFocusState();
}

class _BadOpensOnFocusState extends State<BadOpensOnFocus> {
  /// The trail whose question was asked when its button last took focus,
  /// so that focus coming back to it from the question does not ask again.
  String? _askedFor;

  @override
  Widget build(BuildContext context) {
    return _Trails(
      slug: 'bad-opens-on-focus',
      ask: (context, trails, name) => showDialog<bool>(
        context: context,
        builder: (context) => _materialQuestion(context, trails, name),
      ),
      button: (label, onPressed, node) => TextButton(
        focusNode: node,
        onPressed: onPressed,
        // Defect: the question opens as soon as the button takes focus,
        // so Tab onto a Remove button moves focus into a dialog: a change
        // of context on focus.
        onFocusChange: (focused) {
          if (!focused || _askedFor == label) return;
          _askedFor = label;
          onPressed();
        },
        child: Text(label),
      ),
    );
  }
}
// #endregion
