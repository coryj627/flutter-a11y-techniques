import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../catalog/test_id.dart';

// #region shared
/// Holds the on or off state of the controls in one example, so people and
/// tests can confirm that a control still works after it has been named.
class _Toggles extends StatefulWidget {
  const _Toggles({required this.builder});

  final List<Widget> Function(
    bool Function(String key) isOn,
    void Function(String key) toggle,
  )
  builder;

  @override
  State<_Toggles> createState() => _TogglesState();
}

class _TogglesState extends State<_Toggles> {
  final Set<String> _on = {};

  void _toggle(String key) {
    setState(() => _on.contains(key) ? _on.remove(key) : _on.add(key));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.builder(_on.contains, _toggle),
    );
  }
}

/// A level 3 heading for a group of controls. The screen title is level 1
/// and the "Example" section is level 2.
class _GroupHeading extends StatelessWidget {
  const _GroupHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Semantics(
        header: true,
        headingLevel: 3,
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}
// #endregion

// #region good-visible-label
/// The list tile widgets take the control's name from the visible `title`.
/// The text and the control are one element: the name is the text people
/// see, and the whole row operates the control.
class GoodVisibleLabel extends StatelessWidget {
  const GoodVisibleLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return _Toggles(
      builder: (isOn, toggle) => [
        TestId(
          's01-good-visible-label-updates',
          child: CheckboxListTile(
            title: const Text('Email me order updates'),
            value: isOn('updates'),
            onChanged: (_) => toggle('updates'),
          ),
        ),
        TestId(
          's01-good-visible-label-dark',
          child: SwitchListTile(
            title: const Text('Dark mode'),
            value: isOn('dark'),
            onChanged: (_) => toggle('dark'),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region good-merged-label
/// When a control and its visible text are laid out by hand, `MergeSemantics`
/// joins them into one element, so the text becomes the control's name. The
/// `GestureDetector` makes a tap on the text operate the control, as a tap
/// on an HTML `label` does.
class GoodMergedLabel extends StatelessWidget {
  const GoodMergedLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return _Toggles(
      builder: (isOn, toggle) => [
        TestId(
          's01-good-merged-label-remember',
          child: MergeSemantics(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => toggle('remember'),
              child: Row(
                children: [
                  Checkbox(
                    value: isOn('remember'),
                    onChanged: (_) => toggle('remember'),
                  ),
                  const Expanded(child: Text('Remember this device')),
                ],
              ),
            ),
          ),
        ),
        TestId(
          's01-good-merged-label-wifi',
          child: MergeSemantics(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => toggle('wifi'),
              child: Row(
                children: [
                  const Expanded(child: Text('Wi-Fi')),
                  Switch(value: isOn('wifi'), onChanged: (_) => toggle('wifi')),
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

// #region good-specific-names
/// Two controls show the same text. `Text.semanticsLabel` gives each a name
/// that says which one it is and still begins with the visible text, so
/// speech input users can say what they see.
class GoodSpecificNames extends StatelessWidget {
  const GoodSpecificNames({super.key});

  @override
  Widget build(BuildContext context) {
    return _Toggles(
      builder: (isOn, toggle) => [
        const _GroupHeading('Email'),
        TestId(
          's01-good-specific-names-email',
          child: SwitchListTile(
            title: const Text(
              'Order updates',
              semanticsLabel: 'Order updates, email',
            ),
            value: isOn('email'),
            onChanged: (_) => toggle('email'),
          ),
        ),
        const _GroupHeading('Text message'),
        TestId(
          's01-good-specific-names-sms',
          child: SwitchListTile(
            title: const Text(
              'Order updates',
              semanticsLabel: 'Order updates, text message',
            ),
            value: isOn('sms'),
            onChanged: (_) => toggle('sms'),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region good-cupertino
/// A `CupertinoSwitch` has no label of its own. `MergeSemantics` joins it to
/// the visible text beside it, as for the Material controls.
class GoodCupertinoLabel extends StatelessWidget {
  const GoodCupertinoLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return _Toggles(
      builder: (isOn, toggle) => [
        TestId(
          's01-good-cupertino-airplane',
          child: MergeSemantics(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => toggle('airplane'),
              child: Row(
                children: [
                  const Expanded(child: Text('Airplane mode')),
                  CupertinoSwitch(
                    value: isOn('airplane'),
                    onChanged: (_) => toggle('airplane'),
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

// #region bad-unassociated-label
/// Defect: the text sits beside the checkbox but is a separate element, so
/// the checkbox has no name. A screen reader says only "checkbox".
class BadUnassociatedLabel extends StatelessWidget {
  const BadUnassociatedLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return _Toggles(
      builder: (isOn, toggle) => [
        Row(
          children: [
            TestId(
              's01-bad-unassociated-label-terms',
              child: Checkbox(
                value: isOn('terms'),
                onChanged: (_) => toggle('terms'),
              ),
            ),
            const Expanded(child: Text('I accept the terms')),
          ],
        ),
      ],
    );
  }
}
// #endregion

// #region bad-duplicate-names
/// Defect: both switches are named "Order updates". Out of context, as in a
/// screen reader's list of controls, nothing says which is which.
class BadDuplicateNames extends StatelessWidget {
  const BadDuplicateNames({super.key});

  @override
  Widget build(BuildContext context) {
    return _Toggles(
      builder: (isOn, toggle) => [
        const _GroupHeading('Email'),
        TestId(
          's01-bad-duplicate-names-email',
          child: SwitchListTile(
            title: const Text('Order updates'),
            value: isOn('email'),
            onChanged: (_) => toggle('email'),
          ),
        ),
        const _GroupHeading('Text message'),
        TestId(
          's01-bad-duplicate-names-sms',
          child: SwitchListTile(
            title: const Text('Order updates'),
            value: isOn('sms'),
            onChanged: (_) => toggle('sms'),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-role-in-name
/// Defect: the name is "Dark mode switch". The screen reader adds the role
/// itself, so people hear "switch" twice.
class BadRoleInName extends StatelessWidget {
  const BadRoleInName({super.key});

  @override
  Widget build(BuildContext context) {
    return _Toggles(
      builder: (isOn, toggle) => [
        TestId(
          's01-bad-role-in-name-dark',
          child: SwitchListTile(
            title: const Text('Dark mode', semanticsLabel: 'Dark mode switch'),
            value: isOn('dark'),
            onChanged: (_) => toggle('dark'),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-slider-name-web
/// Flutter limitation FL-028: the slider is joined to its visible text in the
/// same way as the good examples, and is named "Volume" on Android and iOS.
/// On web the name is put on a wrapper element, not on the slider, so the
/// slider has no name there.
class BadSliderNameWeb extends StatefulWidget {
  const BadSliderNameWeb({super.key});

  @override
  State<BadSliderNameWeb> createState() => _BadSliderNameWebState();
}

class _BadSliderNameWebState extends State<BadSliderNameWeb> {
  double _volume = 0.4;

  @override
  Widget build(BuildContext context) {
    return TestId(
      's01-bad-slider-name-web-volume',
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Volume'),
            Slider(
              value: _volume,
              // Ten steps, so one step up is 50% on every platform.
              divisions: 10,
              onChanged: (value) => setState(() => _volume = value),
            ),
          ],
        ),
      ),
    );
  }
}
// #endregion
