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
          key: ValueKey<String>('s22-${widget.slug}-count'),
          identifier: 's22-${widget.slug}-count',
          liveRegion: true,
          child: Text('Changes: $_count'),
        ),
      ],
    );
  }
}

/// The keyboard half of a custom button and its focus ring: Enter and Space
/// call [onActivate]. It gives the control no role, no name, and no identifier.
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
// #endregion

// #region good-merged
/// A Material button with an identifier a UI test can find it by. The
/// identifier is outside the button, and `MergeSemantics` folds it into the
/// button's own node, so one node has the role, the name, and the
/// identifier on every platform. Screen readers do not read it.
///
/// This is what the project's `TestId` widget does
/// (lib/catalog/test_id.dart); the other examples use it.
class GoodMerged extends StatelessWidget {
  const GoodMerged({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-merged',
      builder: (context, changed) => [
        MergeSemantics(
          key: const ValueKey<String>('s22-good-merged-save'),
          child: Semantics(
            identifier: 's22-good-merged-save',
            child: FilledButton(
              onPressed: changed,
              child: const Text('Save draft'),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region good-cupertino
/// The same on a Cupertino button.
class GoodCupertino extends StatelessWidget {
  const GoodCupertino({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-cupertino',
      builder: (context, changed) => [
        TestId(
          's22-good-cupertino-save',
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
              child: const Text('Save draft'),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region good-custom
/// A button drawn by hand. Its role, name, and tap action are on one
/// `Semantics`, and its keyboard focus is on a widget around that. The
/// identifier goes outside both, merged, as for any other control.
class GoodCustom extends StatelessWidget {
  const GoodCustom({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _Demo(
      slug: 'good-custom',
      builder: (context, changed) => [
        TestId(
          's22-good-custom-save',
          child: _KeyboardOperable(
            onActivate: changed,
            child: Semantics(
              button: true,
              label: 'Save draft',
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
                      'Save draft',
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
/// A text field with an identifier. The field keeps its name, "Project
/// name"; the identifier is only for tests.
class GoodField extends StatelessWidget {
  const GoodField({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-field',
      builder: (context, changed) => [
        TestId(
          's22-good-field-project',
          child: TextField(
            onChanged: (_) => changed(),
            decoration: const InputDecoration(
              labelText: 'Project name',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-inside
/// The identifier is inside the button, around its text. On Android and
/// iOS the text becomes a node of its own and takes the name with it: the
/// button is read as "Button", with no name. On the web the button keeps
/// its name, and the identifier is on an element inside it that is not the
/// button.
class BadInside extends StatelessWidget {
  const BadInside({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-inside',
      builder: (context, changed) => [
        FilledButton(
          key: const ValueKey<String>('s22-bad-inside-button'),
          onPressed: changed,
          child: Semantics(
            identifier: 's22-bad-inside-save',
            child: const Text('Save draft'),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-wrapper
/// The identifier is outside the button with nothing to merge them. A
/// Material button is a semantics container, so the identifier is left on
/// a node of its own, with no role, no name, and no action. A test that
/// finds the identifier has not found the button.
class BadWrapper extends StatelessWidget {
  const BadWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-wrapper',
      builder: (context, changed) => [
        Semantics(
          identifier: 's22-bad-wrapper-save',
          child: FilledButton(
            key: const ValueKey<String>('s22-bad-wrapper-button'),
            onPressed: changed,
            child: const Text('Save draft'),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-id-as-name
/// An icon button with an identifier and no name. The identifier is not
/// read: a screen reader says "Button" and nothing else.
class BadIdAsName extends StatelessWidget {
  const BadIdAsName({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-id-as-name',
      builder: (context, changed) => [
        TestId(
          's22-bad-id-as-name-close',
          child: IconButton(onPressed: changed, icon: const Icon(Icons.close)),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-duplicate
/// Two buttons with the same identifier. A test that asks for the
/// identifier gets two elements, or the first one, depending on the tool.
class BadDuplicate extends StatelessWidget {
  const BadDuplicate({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-duplicate',
      builder: (context, changed) => [
        MergeSemantics(
          child: Semantics(
            identifier: 's22-bad-duplicate-action',
            child: FilledButton(
              key: const ValueKey<String>('s22-bad-duplicate-save'),
              onPressed: changed,
              child: const Text('Save draft'),
            ),
          ),
        ),
        MergeSemantics(
          child: Semantics(
            identifier: 's22-bad-duplicate-action',
            child: OutlinedButton(
              key: const ValueKey<String>('s22-bad-duplicate-discard'),
              onPressed: changed,
              child: const Text('Discard draft'),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion
