import 'package:flutter/material.dart';

// What the framework tells an app about the user's settings is in
// `MediaQuery` (from `MediaQueryData`, which the framework fills from the
// platform and keeps up to date) and, for four flags that `MediaQueryData`
// does not carry, in `PlatformDispatcher.accessibilityFeatures`. A widget
// that reads a setting with `MediaQuery`'s `...Of` methods is rebuilt when
// that setting changes; a widget that reads `accessibilityFeatures` is not,
// unless it listens with `WidgetsBindingObserver.didChangeAccessibilityFeatures`.
// Which system setting sets which flag differs by platform, and some flags
// are never set on some platforms: docs/specs/V12-accessibility-settings.md
// has the table, measured on each. The examples say which settings are on,
// in text, so that what the app was told can be seen and read by a screen
// reader.

// #region shared
/// "on" or "off".
String onOff(bool on) => on ? 'on' : 'off';

/// The settings the settings examples show, as the app was told them.
typedef Settings = ({
  bool accessibleNavigation,
  bool boldText,
  bool highContrast,
  bool invertColors,
  bool disableAnimations,
  bool onOffSwitchLabels,
  bool dark,
  int textScale,
});

/// One line of an example, one node, with the test identifier [id].
class SettingLine extends StatelessWidget {
  const SettingLine({super.key, required this.id, required this.text});

  final String id;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: ValueKey<String>(id),
      container: true,
      identifier: id,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(text),
      ),
    );
  }
}

/// The settings [settings] as one line each, identified
/// `v12-<slug>-<key>`, in this order.
class SettingLines extends StatelessWidget {
  const SettingLines({super.key, required this.slug, required this.settings});

  final String slug;
  final Settings settings;

  /// Each line's key and text.
  static List<(String, String)> lines(Settings s) => [
    ('navigation', 'Accessible navigation: ${onOff(s.accessibleNavigation)}'),
    ('bold', 'Bold text: ${onOff(s.boldText)}'),
    ('contrast', 'High contrast: ${onOff(s.highContrast)}'),
    ('invert', 'Invert colours: ${onOff(s.invertColors)}'),
    ('animations', 'Disable animations: ${onOff(s.disableAnimations)}'),
    ('labels', 'Switch labels: ${onOff(s.onOffSwitchLabels)}'),
    ('dark', 'Dark mode: ${onOff(s.dark)}'),
    ('scale', 'Text scale: ${s.textScale}%'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (key, text) in lines(settings))
          SettingLine(id: 'v12-$slug-$key', text: text),
      ],
    );
  }
}
// #endregion

// #region good-media-query
/// Each setting read with `MediaQuery`'s method for it. The widget depends
/// on each of those settings and is rebuilt when one of them changes, so
/// the lines say what is on now. The text scale is the scale for text of
/// 14 pixels, the body text's size: on Android 14 and later a text scaler
/// can scale large text less than small text.
class GoodMediaQuery extends StatelessWidget {
  const GoodMediaQuery({super.key});

  @override
  Widget build(BuildContext context) {
    final Settings settings = (
      accessibleNavigation: MediaQuery.accessibleNavigationOf(context),
      boldText: MediaQuery.boldTextOf(context),
      highContrast: MediaQuery.highContrastOf(context),
      invertColors: MediaQuery.invertColorsOf(context),
      disableAnimations: MediaQuery.disableAnimationsOf(context),
      onOffSwitchLabels: MediaQuery.onOffSwitchLabelsOf(context),
      dark: MediaQuery.platformBrightnessOf(context) == Brightness.dark,
      textScale: (MediaQuery.textScalerOf(context).scale(14) / 14 * 100)
          .round(),
    );
    return SettingLines(slug: 'good-media-query', settings: settings);
  }
}
// #endregion

// #region good-motion
/// Whether to reduce motion. Android's "Remove animations" and the web's
/// `prefers-reduced-motion` set `disableAnimations`; iOS's Reduce Motion
/// sets only `AccessibilityFeatures.reduceMotion`, which `MediaQueryData`
/// does not carry. So both are read, as the framework's own
/// `CupertinoMenuAnchor` reads both, and a `WidgetsBindingObserver` rebuilds
/// the line when the platform's features change.
class GoodMotion extends StatefulWidget {
  const GoodMotion({super.key});

  @override
  State<GoodMotion> createState() => _GoodMotionState();
}

class _GoodMotionState extends State<GoodMotion> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAccessibilityFeatures() => setState(() {});

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final features = View.of(context).platformDispatcher.accessibilityFeatures;
    final reduce =
        MediaQuery.disableAnimationsOf(context) || features.reduceMotion;
    return SettingLine(
      id: 'v12-good-motion-motion',
      text: 'Reduce motion: ${onOff(reduce)}',
    );
  }
}
// #endregion

// #region bad-read-once
/// The same settings, read once when the screen opens, from the platform
/// dispatcher, and kept. Nothing rebuilds the lines, so a setting changed
/// while the screen is open is never shown.
class BadReadOnce extends StatefulWidget {
  const BadReadOnce({super.key});

  @override
  State<BadReadOnce> createState() => _BadReadOnceState();
}

class _BadReadOnceState extends State<BadReadOnce> {
  late final Settings _settings;

  @override
  void initState() {
    super.initState();
    final platform = WidgetsBinding.instance.platformDispatcher;
    final f = platform.accessibilityFeatures;
    _settings = (
      accessibleNavigation: f.accessibleNavigation,
      boldText: f.boldText,
      highContrast: f.highContrast,
      invertColors: f.invertColors,
      disableAnimations: f.disableAnimations,
      onOffSwitchLabels: f.onOffSwitchLabels,
      dark: platform.platformBrightness == Brightness.dark,
      textScale: (platform.textScaleFactor * 100).round(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingLines(slug: 'bad-read-once', settings: _settings);
  }
}
// #endregion

// #region bad-animations-only
/// Whether to reduce motion, from `disableAnimations` alone. iOS's Reduce
/// Motion never sets it, so on iOS the line stays "off".
class BadAnimationsOnly extends StatelessWidget {
  const BadAnimationsOnly({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingLine(
      id: 'v12-bad-animations-only-motion',
      text: 'Reduce motion: ${onOff(MediaQuery.disableAnimationsOf(context))}',
    );
  }
}
// #endregion
