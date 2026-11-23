import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../catalog/test_id.dart';

// Every indicator is Flutter's own: Material's LinearProgressIndicator and
// CircularProgressIndicator through their documented `semanticsLabel`, and
// Cupertino's CupertinoActivityIndicator, which has no semantics of its
// own, named with `Semantics(label:)`. The only good example is the bar:
// Flutter gives a spinner no role (FL-256), so the spinners are bad
// examples of that. How the task is going, and that it has ended, is told
// by a line of text in a live region, `Semantics(liveRegion: true)`: a change of an indicator's value is not
// announced on any platform (docs/flutter-limitations.md, FL-254). What the
// framework cannot do is in that file and is not built here.

// #region shared
/// A task that runs for four steps of one second once started: [progress]
/// goes 0, 0.25, 0.5, 0.75, 1, and [done] is true at the end. It stands in
/// for an upload or a load, so that people and tests can watch it run.
class _Task extends ChangeNotifier {
  static const step = Duration(seconds: 1);

  double progress = 0;
  bool running = false;
  bool done = false;
  Timer? _timer;

  void start() {
    _timer?.cancel();
    progress = 0;
    running = true;
    done = false;
    notifyListeners();
    _timer = Timer.periodic(step, (timer) {
      progress = (progress + 0.25).clamp(0, 1);
      if (progress >= 1) {
        timer.cancel();
        running = false;
        done = true;
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Lays out one example: a button that starts the task, what [indicator]
/// draws for it, and a line of text, [status], that says how it is going.
/// With [live] the line is a live region, which a screen reader announces
/// when its text changes.
class _Demo extends StatefulWidget {
  const _Demo({
    required this.slug,
    required this.action,
    required this.indicator,
    required this.status,
    this.live = true,
  });

  final String slug;
  final String action;
  final Widget Function(BuildContext context, _Task task) indicator;
  final String Function(_Task task) status;
  final bool live;

  @override
  State<_Demo> createState() => _DemoState();
}

class _DemoState extends State<_Demo> {
  final _task = _Task();

  @override
  void dispose() {
    _task.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slug = widget.slug;
    final colors = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: _task,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          TestId(
            'c26-$slug-start',
            child: OutlinedButton(
              onPressed: _task.start,
              // A 2 pixel outline in the page's text colour while the
              // button has keyboard focus, through its own style.
              style: ButtonStyle(
                side: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.focused)
                      ? BorderSide(color: colors.onSurface, width: 2)
                      : null,
                ),
              ),
              child: Text(widget.action),
            ),
          ),
          widget.indicator(context, _task),
          Semantics(
            key: ValueKey<String>('c26-$slug-status'),
            identifier: 'c26-$slug-status',
            liveRegion: widget.live,
            child: Text(widget.status(_task)),
          ),
        ],
      ),
    );
  }
}

/// What an upload's status line says: before, when it starts, halfway,
/// and at the end. It changes at those points only, so that a screen
/// reader is told how it is going now and then, and not at every step.
String _uploadStatus(_Task task) => task.done
    ? 'Upload complete'
    : task.running && task.progress >= 0.5
    ? 'Half uploaded'
    : task.running
    ? 'Upload started'
    : 'Not started';

/// What a load's status line says: before, during, and at the end.
String _loadStatus(_Task task) => task.done
    ? 'Inbox loaded'
    : task.running
    ? 'Loading started'
    : 'Inbox not loaded';

/// The visible name of an upload's bar, above it.
const _uploadName = 'Report upload';

/// The name of a load's spinner.
const _loadName = 'Loading inbox';

/// Room for a spinner, so that the line under it stays in place.
const _spinnerBox = Size.square(40);
// #endregion

// #region good-linear
/// A bar that shows how far an upload has gone. `semanticsLabel` names it
/// with the words shown above it, which are left out of the semantics so
/// that they are read once; its value is the indicator's own, the percentage
/// as a number. The status line under it, a live region, says that it has
/// started, when it is half done, and that it has finished: the bar's own value
/// changes are not announced (FL-254).
class GoodLinear extends StatelessWidget {
  const GoodLinear({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-linear',
      action: 'Upload report',
      status: _uploadStatus,
      indicator: (context, task) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          const ExcludeSemantics(child: Text(_uploadName)),
          TestId(
            'c26-good-linear-bar',
            child: LinearProgressIndicator(
              value: task.progress,
              semanticsLabel: _uploadName,
            ),
          ),
        ],
      ),
    );
  }
}
// #endregion

// #region bad-no-label
/// The bar of `good-linear` with no `semanticsLabel`. The words above it
/// are shown, and read as text of their own, but nothing ties them to it:
/// the bar is read as a number with no name.
class BadNoLabel extends StatelessWidget {
  const BadNoLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-no-label',
      action: 'Upload report',
      status: _uploadStatus,
      indicator: (context, task) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          const Text(_uploadName),
          TestId(
            'c26-bad-no-label-bar',
            // Defect: no semanticsLabel.
            child: LinearProgressIndicator(value: task.progress),
          ),
        ],
      ),
    );
  }
}
// #endregion

// #region bad-silent-end
/// `good-linear` with its status line left out of the live regions. The
/// line still says on screen that the upload is complete, but nothing
/// announces it, and the bar's own value changes are not announced either
/// (FL-254): a screen reader user is not told that it has finished.
class BadSilentEnd extends StatelessWidget {
  const BadSilentEnd({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-silent-end',
      action: 'Upload report',
      status: _uploadStatus,
      // Defect: the status line is not a live region.
      live: false,
      indicator: (context, task) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          const ExcludeSemantics(child: Text(_uploadName)),
          TestId(
            'c26-bad-silent-end-bar',
            child: LinearProgressIndicator(
              value: task.progress,
              semanticsLabel: _uploadName,
            ),
          ),
        ],
      ),
    );
  }
}
// #endregion

// #region bad-no-role
/// Material's spinner, shown while the inbox loads, named by
/// `semanticsLabel`, with no value, as an indeterminate indicator has none.
/// The status line, a live region, says that loading has started and that
/// it has ended. Its one defect is the framework's: Flutter gives a spinner
/// no role on any platform, and no parameter adds one (FL-256), so a
/// screen reader hears a name and nothing that says what it is. There is
/// no good spinner example: by the owner's decision of 2026-11-23 a
/// platform where Flutter gives no role is a limitation.
class BadNoRole extends StatelessWidget {
  const BadNoRole({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-no-role',
      action: 'Load inbox',
      status: _loadStatus,
      indicator: (context, task) => SizedBox.fromSize(
        size: _spinnerBox,
        child: task.running
            ? const TestId(
                'c26-bad-no-role-spinner',
                // Defect: no role, on any platform (FL-256).
                child: CircularProgressIndicator(semanticsLabel: _loadName),
              )
            : null,
      ),
    );
  }
}
// #endregion

// #region bad-cupertino-no-role
/// Cupertino's spinner. `CupertinoActivityIndicator` gives no semantics of
/// its own and has no parameter for a name (FL-255), so it is named with
/// `Semantics(label:)`. The status line, a live region, says that loading
/// has started and that it has ended. Its one defect is the framework's,
/// as `bad-no-role`'s: no role, on any platform, and nothing in the SDK
/// adds one (FL-256). The button is Material's, as in the other examples:
/// a `CupertinoButton` takes no Enter on the web (FL-002).
class BadCupertinoNoRole extends StatelessWidget {
  const BadCupertinoNoRole({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-cupertino-no-role',
      action: 'Load inbox',
      status: _loadStatus,
      indicator: (context, task) => SizedBox.fromSize(
        size: _spinnerBox,
        child: task.running
            ? TestId(
                'c26-bad-cupertino-no-role-spinner',
                // Defect: a name, and no role, on any platform (FL-256).
                child: Semantics(
                  label: _loadName,
                  child: const CupertinoActivityIndicator(radius: 14),
                ),
              )
            : null,
      ),
    );
  }
}
// #endregion

// #region bad-adaptive
/// `CircularProgressIndicator.adaptive` with a `semanticsLabel`. Where the
/// theme's platform is iOS or macOS, which it is on an iPhone and in a
/// browser on a Mac, it draws a `CupertinoActivityIndicator` and drops the
/// label, as its documentation says: the spinner is not there for a screen
/// reader at all (FL-257). On Android, and in a browser elsewhere, it is
/// Material's spinner, named.
class BadAdaptive extends StatelessWidget {
  const BadAdaptive({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-adaptive',
      action: 'Load inbox',
      status: _loadStatus,
      indicator: (context, task) => SizedBox.fromSize(
        size: _spinnerBox,
        child: task.running
            ? const TestId(
                'c26-bad-adaptive-spinner',
                // Defect: the label is ignored on iOS and macOS.
                child: CircularProgressIndicator.adaptive(
                  semanticsLabel: _loadName,
                ),
              )
            : null,
      ),
    );
  }
}
// #endregion

// #region bad-cupertino-bar
/// Cupertino's bar, `CupertinoLinearActivityIndicator`, as it comes. It
/// gives no semantics and has no parameter for a name or a value (FL-255):
/// a screen reader finds the words above it, and no bar.
class BadCupertinoBar extends StatelessWidget {
  const BadCupertinoBar({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-cupertino-bar',
      action: 'Upload report',
      status: _uploadStatus,
      indicator: (context, task) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          const Text(_uploadName),
          TestId(
            'c26-bad-cupertino-bar-bar',
            // Defect: the bar exposes nothing.
            child: CupertinoLinearActivityIndicator(progress: task.progress),
          ),
        ],
      ),
    );
  }
}
// #endregion
