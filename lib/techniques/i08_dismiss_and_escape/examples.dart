import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../catalog/test_id.dart';

// #region shared
/// The layers every example's map can show: the last part of each switch's
/// identifier, and its name.
const _layers = [('contours', 'Contour lines'), ('campsites', 'Campsites')];

/// Shows the map's layers to choose from, and completes once they have
/// gone, however they were closed. Each example shows them its own way.
typedef _ShowLayers = Future<void> Function(
  BuildContext context,
  _MapState map,
);

/// A trail map with a button that shows its layers, a line saying which
/// layers are on, and a count of the times the layers have been closed, so
/// that people and tests can see that a key or a gesture closed them.
class _Map extends StatefulWidget {
  const _Map({required this.slug, required this.show});

  final String slug;
  final _ShowLayers show;

  @override
  State<_Map> createState() => _MapState();
}

class _MapState extends State<_Map> {
  /// The layers that are on; the switches read and change it.
  final ValueNotifier<Set<String>> on = ValueNotifier({'contours'});

  /// The focus node of Map layers, the button that shows the layers.
  final FocusNode opener = FocusNode();
  int _closed = 0;

  /// The test identifier of the part [part] of this example.
  String id(String part) => 'i08-${widget.slug}-$part';

  @override
  void dispose() {
    on.dispose();
    opener.dispose();
    super.dispose();
  }

  Future<void> _show() async {
    await widget.show(context, this);
    if (mounted) setState(() => _closed++);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text('Trail map', style: Theme.of(context).textTheme.titleMedium),
        ListenableBuilder(
          listenable: on,
          builder: (context, _) {
            final names = [
              for (final (key, name) in _layers)
                if (on.value.contains(key)) name,
            ];
            return Text(
              'Showing: ${names.isEmpty ? 'no layers' : names.join(', ')}',
            );
          },
        ),
        TestId(
          id('open'),
          child: OutlinedButton(
            focusNode: opener,
            onPressed: _show,
            child: const Text('Map layers'),
          ),
        ),
        Semantics(
          key: ValueKey<String>(id('count')),
          identifier: id('count'),
          child: Text('Closed: $_closed'),
        ),
      ],
    );
  }
}

/// The two switches, Material ones, for the layers of [map].
Widget _materialSwitches(_MapState map) => ListenableBuilder(
  listenable: map.on,
  builder: (context, _) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final (key, name) in _layers)
        TestId(
          map.id(key),
          child: SwitchListTile(
            title: Text(name),
            value: map.on.value.contains(key),
            onChanged: (value) => map.on.value = value
                ? {...map.on.value, key}
                : ({...map.on.value}..remove(key)),
          ),
        ),
    ],
  ),
);

/// The layers' title and their two Material switches.
/// They scroll when large text makes them taller than the sheet.
Widget _layersPanel(BuildContext context, _MapState map) => SafeArea(
  child: SingleChildScrollView(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Map layers',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        _materialSwitches(map),
      ],
    ),
  ),
);
// #endregion

// #region good-material
/// A modal bottom sheet, the Material place for a choice like this. Its
/// route closes it on Escape, because the sheet can be dismissed
/// (`isDismissible`, true by default); on Android's Back and on VoiceOver's
/// escape gesture, which pop the route on top; and through its barrier,
/// which a screen reader can dismiss. While it is open, Tab goes round its
/// two switches: a modal with a standard way out is not a trap.
class GoodMaterial extends StatelessWidget {
  const GoodMaterial({super.key});

  @override
  Widget build(BuildContext context) {
    return _Map(
      slug: 'good-material',
      show: (context, map) => showModalBottomSheet<void>(
        context: context,
        builder: (context) => _layersPanel(context, map),
      ),
    );
  }
}
// #endregion

// #region good-cupertino
/// A Cupertino modal popup. `barrierDismissible` is true by default, so
/// Escape closes it; `semanticsDismissible` makes its barrier one more
/// element a screen reader can use to close it.
class GoodCupertino extends StatelessWidget {
  const GoodCupertino({super.key});

  @override
  Widget build(BuildContext context) {
    return _Map(
      slug: 'good-cupertino',
      show: (context, map) => showCupertinoModalPopup<void>(
        context: context,
        semanticsDismissible: true,
        builder: (context) => CupertinoPopupSurface(
          child: SafeArea(
            top: false,
            child: ListenableBuilder(
              listenable: map.on,
              builder: (context, _) => CupertinoListSection(
                header: Text(
                  'Map layers',
                  style: TextStyle(
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
                children: [
                  for (final (key, name) in _layers)
                    TestId(
                      map.id(key),
                      // CupertinoListTile does not merge its parts, so the
                      // title and the switch are made one control, as F09
                      // does.
                      child: MergeSemantics(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: CupertinoListTile(
                            title: Text(name),
                            trailing: CupertinoSwitch(
                              value: map.on.value.contains(key),
                              onChanged: (value) => map.on.value = value
                                  ? {...map.on.value, key}
                                  : ({...map.on.value}..remove(key)),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// #endregion

// #region good-widgets
/// The layers drawn by hand in the app's overlay, with no route. Nothing
/// closes such an overlay by itself: Escape, Back, and the screen readers'
/// dismiss commands each need something of their own. [_Overlay] gives it
/// the dismiss action for screen readers and keeps Tab in it; this example
/// adds Escape and Back.
class GoodWidgets extends StatelessWidget {
  const GoodWidgets({super.key});

  @override
  Widget build(BuildContext context) =>
      const _Overlay(slug: 'good-widgets', escape: true, back: true);
}

/// A map whose layers are shown in an [OverlayEntry] over the screen,
/// behind a barrier that hides the screen from screen readers, as a route
/// does.
///
/// With [escape], Escape closes the layers: the app's default shortcuts
/// turn Escape into a `DismissIntent`, and an action for it is put around
/// the layers, where keyboard focus is. With [back], Android's Back and
/// VoiceOver's escape gesture close them: both ask the Navigator to pop
/// the route on top, which is the screen itself, and a `PopScope` stops
/// that while the layers are open and closes them instead.
class _Overlay extends StatefulWidget {
  const _Overlay({
    required this.slug,
    required this.escape,
    required this.back,
  });

  final String slug;
  final bool escape;
  final bool back;

  @override
  State<_Overlay> createState() => _OverlayState();
}

class _OverlayState extends State<_Overlay> {
  /// The layers' own focus scope. Tab and Shift+Tab go round inside it
  /// while the layers are open.
  final _scope = FocusScopeNode(
    debugLabel: 'Map layers',
    traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
  );
  OverlayEntry? _entry;
  Completer<void>? _shown;
  _MapState? _map;

  @override
  void dispose() {
    _entry?.remove();
    _entry?.dispose();
    _scope.dispose();
    super.dispose();
  }

  Future<void> _show(BuildContext context, _MapState map) {
    _map = map;
    _entry = OverlayEntry(builder: (context) => _layers(context, map));
    Overlay.of(context).insert(_entry!);
    setState(() {});
    _shown = Completer<void>();
    // Keyboard focus goes into the layers, to their first switch.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_entry != null) _scope.nextFocus();
    });
    return _shown!.future;
  }

  void _close() {
    final entry = _entry;
    if (entry == null) return;
    _entry = null;
    entry.remove();
    entry.dispose();
    if (mounted) setState(() {});
    // Keyboard focus goes back to the button that showed the layers, and
    // TalkBack with it (I03).
    _map?.opener.requestFocus();
    _shown?.complete();
  }

  Widget _layers(BuildContext context, _MapState map) {
    Widget layers = Semantics(
      // For screen readers: TalkBack lists it as the Dismiss action, and
      // VoiceOver's escape gesture on any part of the layers performs it.
      onDismiss: _close,
      explicitChildNodes: true,
      child: FocusScope(
        node: _scope,
        child: Material(
          elevation: 8,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: _layersPanel(context, map),
        ),
      ),
    );
    if (widget.escape) {
      layers = Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              _close();
              return null;
            },
          ),
        },
        child: layers,
      );
    }
    return Stack(
      children: [
        // Hides the screen from screen readers while the layers are open,
        // and closes them on a tap outside them.
        ModalBarrier(
          color: Colors.black54,
          onDismiss: _close,
          semanticsLabel: 'Close map layers',
        ),
        Align(alignment: Alignment.bottomCenter, child: layers),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final map = _Map(slug: widget.slug, show: _show);
    if (!widget.back) return map;
    return PopScope(
      canPop: _entry == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: map,
    );
  }
}
// #endregion

// #region bad-not-dismissible
class BadNotDismissible extends StatelessWidget {
  const BadNotDismissible({super.key});

  @override
  Widget build(BuildContext context) {
    return _Map(
      slug: 'bad-not-dismissible',
      show: (context, map) => showModalBottomSheet<void>(
        context: context,
        // Defect: the sheet cannot be dismissed, so Escape does nothing,
        // and there is no other key that closes it: from a keyboard, Tab
        // only goes round the two switches.
        isDismissible: false,
        builder: (context) => _layersPanel(context, map),
      ),
    );
  }
}
// #endregion

// #region bad-no-escape
class BadNoEscape extends StatelessWidget {
  const BadNoEscape({super.key});

  // Defect: no action for Escape. Tab and Shift+Tab go round the two
  // switches, and no key leaves them.
  @override
  Widget build(BuildContext context) =>
      const _Overlay(slug: 'bad-no-escape', escape: false, back: true);
}
// #endregion

// #region bad-back-leaves
class BadBackLeaves extends StatelessWidget {
  const BadBackLeaves({super.key});

  // Defect: no PopScope. Android's Back, and TalkBack's Back gesture, pop
  // the screen under the layers, and take the user off it.
  @override
  Widget build(BuildContext context) =>
      const _Overlay(slug: 'bad-back-leaves', escape: true, back: false);
}
// #endregion
