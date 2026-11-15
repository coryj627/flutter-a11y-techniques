import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../catalog/test_id.dart';
import '../s02_informative_images/example_image.dart';

// #region shared
/// The example photo at the size of a small picture button. `sunrisePng` is
/// the small PNG from S02 (`example_image.dart`).
Widget _picture({bool excludeFromSemantics = false, String? semanticLabel}) {
  return Image.memory(
    sunrisePng,
    width: 72,
    height: 48,
    fit: BoxFit.cover,
    filterQuality: FilterQuality.none,
    excludeFromSemantics: excludeFromSemantics,
    semanticLabel: semanticLabel,
  );
}

/// Lays out one example and reports how many times its controls were
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
          key: ValueKey<String>('s04-${widget.slug}-count'),
          identifier: 's04-${widget.slug}-count',
          liveRegion: true,
          child: Text('Activations: $_count'),
        ),
      ],
    );
  }
}
// #endregion

// #region good-image-button
/// The picture is the whole button. The button's name is its `tooltip` and
/// says what the button does, not what the picture shows. The picture itself
/// is excluded, so nothing but the button is exposed.
class GoodImageButton extends StatelessWidget {
  const GoodImageButton({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-image-button',
      builder: (context, activate) => [
        TestId(
          's04-good-image-button-guide',
          child: IconButton(
            onPressed: activate,
            tooltip: 'Open trail guide',
            icon: _picture(excludeFromSemantics: true),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region good-icon-label
/// An `Icon`'s `semanticLabel` becomes the name of the button around it.
/// This works for `Icon`; it does not for `Image` (see `bad-label-on-image`).
class GoodIconLabel extends StatelessWidget {
  const GoodIconLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-icon-label',
      builder: (context, activate) => [
        TestId(
          's04-good-icon-label-search',
          child: IconButton(
            onPressed: activate,
            icon: const Icon(Icons.search, semanticLabel: 'Search'),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region good-image-with-text
/// When a control has text, the text is its name. The picture or icon beside
/// the text gets no text alternative, and an `Image` is excluded.
class GoodImageWithText extends StatelessWidget {
  const GoodImageWithText({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-image-with-text',
      builder: (context, activate) => [
        TestId(
          's04-good-image-with-text-guide',
          child: TextButton(
            onPressed: activate,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                _picture(excludeFromSemantics: true),
                const Flexible(child: Text('Trail guide')),
              ],
            ),
          ),
        ),
        TestId(
          's04-good-image-with-text-print',
          child: FilledButton.icon(
            onPressed: activate,
            icon: const Icon(Icons.print),
            label: const Text('Print'),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region good-cupertino
/// A `CupertinoButton` has no `tooltip`; the icon's `semanticLabel` names it.
class GoodCupertino extends StatelessWidget {
  const GoodCupertino({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-cupertino',
      builder: (context, activate) => [
        TestId(
          's04-good-cupertino-search',
          // Flutter 3.47.5: on web Enter is ButtonActivateIntent, which
          // CupertinoButton does not handle (docs/flutter-limitations.md,
          // FL-002). This adds the missing action; Space already works.
          child: Actions(
            actions: {
              ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
                onInvoke: (_) {
                  activate();
                  return null;
                },
              ),
            },
            child: CupertinoButton(
              onPressed: activate,
              child: const Icon(CupertinoIcons.search, semanticLabel: 'Search'),
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region good-custom
/// A picture made into a button from the widgets layer. `Semantics` gives it
/// the button role and its name; the picture is excluded.
class GoodCustomImageButton extends StatelessWidget {
  const GoodCustomImageButton({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-custom',
      builder: (context, activate) => [
        TestId(
          's04-good-custom-guide',
          child: PictureButton(label: 'Open trail guide', onPressed: activate),
        ),
      ],
    );
  }
}

class PictureButton extends StatefulWidget {
  const PictureButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  State<PictureButton> createState() => _PictureButtonState();
}

class _PictureButtonState extends State<PictureButton> {
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
        label: widget.label,
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(
                color: _focused ? colors.onSurface : colors.surface,
                width: 3,
              ),
            ),
            child: _picture(excludeFromSemantics: true),
          ),
        ),
      ),
    );
  }
}
// #endregion

// #region good-image-regions
/// One picture with two regions that each do something, like an HTML image
/// map. Each region is a button of its own with its own name; the picture
/// behind them is excluded.
class GoodImageRegions extends StatelessWidget {
  const GoodImageRegions({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'good-image-regions',
      builder: (context, activate) => [
        SizedBox(
          width: 240,
          height: 80,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.memory(
                  sunrisePng,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.none,
                  excludeFromSemantics: true,
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                width: 120,
                height: 80,
                child: _Region(
                  id: 's04-good-image-regions-west',
                  label: 'West trail',
                  onPressed: activate,
                ),
              ),
              Positioned(
                left: 120,
                top: 0,
                width: 120,
                height: 80,
                child: _Region(
                  id: 's04-good-image-regions-east',
                  label: 'East trail',
                  onPressed: activate,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One region of the picture: a named button with nothing drawn in it until
/// it has keyboard focus.
class _Region extends StatefulWidget {
  const _Region({
    required this.id,
    required this.label,
    required this.onPressed,
  });

  final String id;
  final String label;
  final VoidCallback onPressed;

  @override
  State<_Region> createState() => _RegionState();
}

class _RegionState extends State<_Region> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return TestId(
      widget.id,
      child: Semantics(
        button: true,
        label: widget.label,
        // An InkWell paints on the nearest Material. Without one above the
        // picture, its focus highlight would be painted under the picture.
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onPressed,
            onFocusChange: (value) => setState(() => _focused = value),
            child: _focused
                // A black ring around a white one, so that the focused
                // region can be seen on any part of the picture.
                ? DecoratedBox(
                    key: ValueKey<String>('${widget.id}-focus'),
                    decoration: BoxDecoration(border: Border.all(width: 3)),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFFFFFFF),
                            width: 3,
                          ),
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  )
                : const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}
// #endregion

// #region bad-no-name
class BadNoName extends StatelessWidget {
  const BadNoName({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-no-name',
      builder: (context, activate) => [
        TestId(
          's04-bad-no-name-guide',
          // Defect: no tooltip, and the picture has no semanticLabel.
          child: IconButton(onPressed: activate, icon: _picture()),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-label-on-image
class BadLabelOnImage extends StatelessWidget {
  const BadLabelOnImage({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-label-on-image',
      builder: (context, activate) => [
        // No TestId here: its MergeSemantics would join the picture to the
        // button and hide the defect. The key is only for the widget tests.
        //
        // Defect: the name is on the Image, not on the button. A labelled
        // Image is always an element of its own, so the button has no name.
        IconButton(
          key: const ValueKey<String>('s04-bad-label-on-image-guide'),
          onPressed: activate,
          icon: _picture(semanticLabel: 'Open trail guide'),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-tap-gesture
class BadTapGesture extends StatelessWidget {
  const BadTapGesture({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-tap-gesture',
      builder: (context, activate) => [
        // No TestId here, for the reason given in bad-label-on-image.
        //
        // Defect: a tap handler on a picture is not a button. It has no
        // button role and cannot be reached or operated from a keyboard.
        GestureDetector(
          key: const ValueKey<String>('s04-bad-tap-gesture-guide'),
          onTap: activate,
          child: _picture(semanticLabel: 'Open trail guide'),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-describes-picture
class BadDescribesPicture extends StatelessWidget {
  const BadDescribesPicture({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-describes-picture',
      builder: (context, activate) => [
        TestId(
          's04-bad-describes-picture-search',
          child: IconButton(
            onPressed: activate,
            // Defect: the name says what the icon looks like, not what the
            // button does.
            tooltip: 'Magnifying glass',
            icon: const Icon(Icons.search),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-image-not-excluded
class BadImageNotExcluded extends StatelessWidget {
  const BadImageNotExcluded({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-image-not-excluded',
      builder: (context, activate) => [
        TestId(
          's04-bad-image-not-excluded-guide',
          child: TextButton(
            onPressed: activate,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                // Defect: the picture is not excluded, so the button is also
                // an image.
                _picture(),
                const Flexible(child: Text('Trail guide')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-redundant-label
class BadRedundantLabel extends StatelessWidget {
  const BadRedundantLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return _Demo(
      slug: 'bad-redundant-label',
      builder: (context, activate) => [
        TestId(
          's04-bad-redundant-label-print',
          child: FilledButton.icon(
            onPressed: activate,
            // Defect: the icon has a label as well as the text beside it, so
            // the button's name is "Printer Print".
            icon: const Icon(Icons.print, semanticLabel: 'Printer'),
            label: const Text('Print'),
          ),
        ),
      ],
    );
  }
}
// #endregion
