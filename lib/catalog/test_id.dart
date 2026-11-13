import 'package:flutter/widgets.dart';

/// Gives [child] a stable locator for UI tests without changing what it
/// exposes to assistive technology.
///
/// `MergeSemantics` folds the identifier into the control's own node, so a
/// test finds one node that has the role, the name, and the identifier:
/// `flt-semantics-identifier` on web, `resource-id` on Android, and
/// `accessibilityIdentifier` on iOS. An identifier placed inside a control
/// splits its name onto a child node, and a plain wrapper lands in a different
/// place on each platform (docs/plan.md, finding K2).
class TestId extends StatelessWidget {
  const TestId(this.id, {super.key, required this.child});

  final String id;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      key: ValueKey<String>(id),
      child: Semantics(identifier: id, child: child),
    );
  }
}
