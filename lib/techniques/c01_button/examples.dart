import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../catalog/test_id.dart';

/// Lays out one example and reports how many times its buttons were
/// activated, so people and tests can confirm that activation worked.
class _Demo extends StatefulWidget {
  const _Demo({required this.slug, required this.builder});

  final String slug;
  final List<Widget> Function(BuildContext context, VoidCallback activate)
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
          key: ValueKey<String>('c01-${widget.slug}-count'),
          identifier: 'c01-${widget.slug}-count',
          liveRegion: true,
          child: Text('Activations: $_count'),
        ),
      ],
    );
  }
}

// #region good-text
/// Material buttons take their name from their text child and expose the
/// button role and enabled state themselves.
class GoodTextButtons extends StatelessWidget {
  const GoodTextButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-text',
      builder: (context, activate) => [
        TestId(
          'c01-good-text-filled',
          child: FilledButton(onPressed: activate, child: const Text('Save')),
        ),
        TestId(
          'c01-good-text-outlined',
          child: OutlinedButton(
            onPressed: activate,
            child: const Text('Cancel'),
          ),
        ),
        TestId(
          'c01-good-text-text',
          child: TextButton(
            onPressed: activate,
            child: const Text('Learn more'),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region good-icon
/// An icon-only button gets its name from `tooltip`.
class GoodIconButton extends StatelessWidget {
  const GoodIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-icon',
      builder: (context, activate) => [
        TestId(
          'c01-good-icon-close',
          child: IconButton(
            onPressed: activate,
            tooltip: 'Close',
            icon: const Icon(Icons.close),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region good-disabled
/// `onPressed: null` disables the button and exposes the disabled state.
class GoodDisabledButton extends StatelessWidget {
  const GoodDisabledButton({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-disabled',
      builder: (context, activate) => [
        const TestId(
          'c01-good-disabled-submit',
          child: FilledButton(onPressed: null, child: Text('Submit')),
        ),
      ],
    );
  }
}
// #endregion

// #region good-unique-names
/// Buttons that share the visible text "Edit" each get a unique accessible
/// name that starts with the visible text.
class GoodUniqueNames extends StatelessWidget {
  const GoodUniqueNames({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-unique-names',
      builder: (context, activate) => [
        for (final field in const ['username', 'email', 'password'])
          Row(
            children: [
              Expanded(
                // Its own node, so each label is read just before its button.
                child: Semantics(
                  container: true,
                  child: Text(field[0].toUpperCase() + field.substring(1)),
                ),
              ),
              TestId(
                'c01-good-unique-names-$field',
                child: TextButton(
                  onPressed: activate,
                  child: Text('Edit', semanticsLabel: 'Edit $field'),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
// #endregion

// #region good-cupertino
/// Cupertino buttons expose their name and role. The disabled state has to
/// be added.
class GoodCupertinoButtons extends StatelessWidget {
  const GoodCupertinoButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-cupertino',
      builder: (context, activate) => [
        TestId(
          'c01-good-cupertino-save',
          child: CupertinoButton.filled(
            onPressed: activate,
            child: const Text('Save'),
          ),
        ),
        // Flutter 3.47.5: CupertinoButton does not report its own disabled
        // state, so it is stated with Semantics(enabled: false). See
        // bad-cupertino-disabled for the button without it.
        TestId(
          'c01-good-cupertino-delete',
          child: Semantics(
            enabled: false,
            child: const CupertinoButton.filled(
              onPressed: null,
              child: Text('Delete'),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region good-custom
/// A custom-drawn button built from the widgets layer: it states its role
/// and state, takes keyboard focus, and activates from Enter and Space.
class GoodCustomButton extends StatelessWidget {
  const GoodCustomButton({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-custom',
      builder: (context, activate) => [
        TestId(
          'c01-good-custom-save',
          child: CustomButton(label: 'Save', onPressed: activate),
        ),
      ],
    );
  }
}

class CustomButton extends StatefulWidget {
  const CustomButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _focused = false;

  Object? _activate(Intent intent) {
    widget.onPressed();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      // Enter and Space reach the button as these intents through the
      // default shortcuts of WidgetsApp.
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: _activate),
        ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
          onInvoke: _activate,
        ),
      },
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      child: Semantics(
        button: true,
        enabled: true,
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _focused ? colors.onSurface : colors.primary,
                width: 3,
              ),
            ),
            child: Text(
              widget.label,
              style: TextStyle(color: colors.onPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
// #endregion

// #region bad-unlabelled-icon
class BadUnlabelledIcon extends StatelessWidget {
  const BadUnlabelledIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-unlabelled-icon',
      builder: (context, activate) => [
        TestId(
          'c01-bad-unlabelled-icon-close',
          // Defect: no tooltip, and the icon has no semanticLabel.
          child: IconButton(onPressed: activate, icon: const Icon(Icons.close)),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-gesture-only
class BadGestureOnly extends StatelessWidget {
  const BadGestureOnly({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _Demo(
      slug: 'bad-gesture-only',
      builder: (context, activate) => [
        TestId(
          'c01-bad-gesture-only-save',
          // Defect: looks like a button, but has no button role and cannot
          // take keyboard focus.
          child: GestureDetector(
            onTap: activate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Save', style: TextStyle(color: colors.onPrimary)),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-role-in-name
class BadRoleInName extends StatelessWidget {
  const BadRoleInName({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-role-in-name',
      builder: (context, activate) => [
        TestId(
          'c01-bad-role-in-name-close',
          child: IconButton(
            onPressed: activate,
            // Defect: the role is part of the name, so it is announced twice.
            tooltip: 'Close button',
            icon: const Icon(Icons.close),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-duplicate-names
class BadDuplicateNames extends StatelessWidget {
  const BadDuplicateNames({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-duplicate-names',
      builder: (context, activate) => [
        for (final field in const ['username', 'email', 'password'])
          Row(
            children: [
              Expanded(
                // Its own node, so each label is read just before its button.
                child: Semantics(
                  container: true,
                  child: Text(field[0].toUpperCase() + field.substring(1)),
                ),
              ),
              TestId(
                'c01-bad-duplicate-names-$field',
                // Defect: all three buttons are named "Edit".
                child: TextButton(
                  onPressed: activate,
                  child: const Text('Edit'),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
// #endregion

// #region bad-name-mismatch
class BadNameMismatch extends StatelessWidget {
  const BadNameMismatch({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-name-mismatch',
      builder: (context, activate) => [
        TestId(
          'c01-bad-name-mismatch-edit',
          child: TextButton(
            onPressed: activate,
            // Defect: the accessible name does not contain the visible text.
            child: const Text('Edit', semanticsLabel: 'Change username'),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-fake-disabled
class BadFakeDisabled extends StatelessWidget {
  const BadFakeDisabled({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _Demo(
      slug: 'bad-fake-disabled',
      builder: (context, activate) => [
        TestId(
          'c01-bad-fake-disabled-submit',
          child: FilledButton(
            // Defect: styled to look disabled, but still enabled and still
            // reported as enabled.
            onPressed: activate,
            style: FilledButton.styleFrom(
              backgroundColor: colors.onSurface.withValues(alpha: 0.12),
              foregroundColor: colors.onSurface.withValues(alpha: 0.38),
            ),
            child: const Text('Submit'),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-cupertino-disabled
class BadCupertinoDisabled extends StatelessWidget {
  const BadCupertinoDisabled({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-cupertino-disabled',
      builder: (context, activate) => [
        const TestId(
          'c01-bad-cupertino-disabled-delete',
          // Defect (Flutter limitation): a disabled CupertinoButton looks
          // disabled and ignores taps, but does not report a disabled state.
          child: CupertinoButton.filled(onPressed: null, child: Text('Delete')),
        ),
      ],
    );
  }
}
// #endregion
