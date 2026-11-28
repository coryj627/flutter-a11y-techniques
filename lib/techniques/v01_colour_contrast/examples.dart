import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../catalog/test_id.dart';

// Contrast is set by colours, and in Flutter the colours of the framework's
// own widgets come from the theme: Material's widgets draw with the roles of
// the app's `ColorScheme` (here `ColorScheme.fromSeed` from indigo, light
// and dark), and Cupertino's with `CupertinoColors`, resolved for the
// brightness. The good examples use the framework's widgets through their
// documented parameters, and each colour they show was measured from the
// rendered pixels on every layer (docs/specs/V01-colour-contrast.md). Where
// a widget's default colour was measured under the threshold, the example
// that corrects it says so and links the limitation in
// docs/flutter-limitations.md.

// #region shared
/// A picture that is pale on the left and dark on the right, as a photo of
/// a harbour under a pale sky might be. It is drawn as a gradient so that
/// every layer measures the same pixels.
class Picture extends StatelessWidget {
  const Picture({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFC5CAE9), Color(0xFF1A237E)],
        ),
      ),
    );
  }
}

/// A picture with a caption, the caption a [GridTileBar] in the tile's
/// footer. [captionBackground] is the bar's `backgroundColor`.
class CaptionedPicture extends StatelessWidget {
  const CaptionedPicture({super.key, this.captionBackground});

  final Color? captionBackground;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: GridTile(
        footer: GridTileBar(
          backgroundColor: captionBackground,
          title: const Text('Harbour'),
        ),
        child: const Picture(),
      ),
    );
  }
}

/// The calendar views a person can choose between.
enum CalendarView { day, week, month }

extension CalendarViewName on CalendarView {
  String get title => switch (this) {
    CalendarView.day => 'Day',
    CalendarView.week => 'Week',
    CalendarView.month => 'Month',
  };
}

/// A Cupertino field's placeholder and edge colour: `systemGrey`'s
/// high-contrast colours, 5.2:1 on the field's white in light mode and
/// 9.5:1 on its black in dark mode (as measured, the spec, section 7).
const fieldGrey = CupertinoDynamicColor.withBrightness(
  color: Color(0xFF6C6C70),
  darkColor: Color(0xFFAEAEB2),
);

/// The edge `good-cupertino` and `bad-cupertino-placeholder` give their
/// field in place of the default hairline (FL-511).
const fieldDecoration = BoxDecoration(
  color: CupertinoColors.systemBackground,
  border: Border.fromBorderSide(BorderSide(color: fieldGrey)),
  borderRadius: BorderRadius.all(Radius.circular(5)),
);

/// A Cupertino email field with a visible label above it, which also names
/// it (a Cupertino field has no label of its own, FL-016).
class CupertinoEmailField extends StatelessWidget {
  const CupertinoEmailField({
    super.key,
    required this.id,
    this.placeholderStyle,
  });

  final String id;

  /// The placeholder's style; null keeps the default.
  final TextStyle? placeholderStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ExcludeSemantics(child: Text('Email')),
        const SizedBox(height: 4),
        TestId(
          id,
          child: Semantics(
            label: 'Email',
            child: placeholderStyle == null
                ? const CupertinoTextField(
                    placeholder: 'Required',
                    decoration: fieldDecoration,
                  )
                : CupertinoTextField(
                    placeholder: 'Required',
                    placeholderStyle: placeholderStyle!,
                    decoration: fieldDecoration,
                  ),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region good-material
/// A short form at the theme's defaults: body text in `onSurface`, a field
/// with its label floating so that its hint shows at rest, a checkbox, and
/// a button. Every text is 4.5:1 or more and every edge that marks a
/// control 3:1 or more, light and dark. The button is an `OutlinedButton`:
/// a `FilledButton`'s text drops under 4.5:1 with focus and a hover in
/// light mode (FL-253).
class GoodMaterial extends StatefulWidget {
  const GoodMaterial({super.key});

  @override
  State<GoodMaterial> createState() => _GoodMaterialState();
}

class _GoodMaterialState extends State<GoodMaterial> {
  var _updates = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('We reply within two days.'),
        const SizedBox(height: 16),
        const TestId(
          'v01-good-material-email',
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'Required',
              hintMaxLines: 2,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: OutlineInputBorder(),
            ),
          ),
        ),
        TestId(
          'v01-good-material-updates',
          child: CheckboxListTile(
            title: const Text('Send me updates'),
            value: _updates,
            onChanged: (v) => setState(() => _updates = v ?? false),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TestId(
            'v01-good-material-send',
            child: OutlinedButton(onPressed: () {}, child: const Text('Send')),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region good-cupertino
/// Cupertino's field with its placeholder and its edge in `systemGrey`'s
/// high-contrast colours, through `placeholderStyle` and `decoration`. The
/// defaults are under the thresholds (FL-510, FL-511). The button is
/// `CupertinoButton.filled`, whose colour here is the app theme's primary,
/// with a `pressedOpacity` that keeps its text 4.5:1 while it is held.
class GoodCupertino extends StatelessWidget {
  const GoodCupertino({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CupertinoEmailField(
          id: 'v01-good-cupertino-email',
          placeholderStyle: TextStyle(color: fieldGrey),
        ),
        const SizedBox(height: 16),
        TestId(
          'v01-good-cupertino-send',
          child: CupertinoButton.filled(
            // While pressed the default fades the button to 0.4 opacity,
            // and its text to under 4.5:1 on its fill (FL-514).
            pressedOpacity: 0.9,
            onPressed: () {},
            child: const Text('Send'),
          ),
        ),
      ],
    );
  }
}
// #endregion

// #region good-caption
/// A caption on a picture, on a bar of its own: `GridTileBar` with
/// `backgroundColor: Colors.black54`, so that the caption keeps its
/// contrast wherever the picture under it is pale.
class GoodCaption extends StatelessWidget {
  const GoodCaption({super.key});

  @override
  Widget build(BuildContext context) {
    return const CaptionedPicture(captionBackground: Colors.black54);
  }
}
// #endregion

// #region good-selection
/// The same choice as `bad-colour-only`, as `RadioListTile`s in a
/// `RadioGroup`: the chosen one's radio button is a filled ring and the
/// others' are empty, so the choice is shown by a shape as well as by
/// colour.
class GoodSelection extends StatefulWidget {
  const GoodSelection({super.key});

  @override
  State<GoodSelection> createState() => _GoodSelectionState();
}

class _GoodSelectionState extends State<GoodSelection> {
  var _view = CalendarView.week;

  @override
  Widget build(BuildContext context) {
    return RadioGroup<CalendarView>(
      groupValue: _view,
      onChanged: (v) => setState(() => _view = v ?? _view),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Calendar view'),
          for (final v in CalendarView.values)
            TestId(
              'v01-good-selection-${v.name}',
              child: RadioListTile<CalendarView>(
                value: v,
                title: Text(v.title),
              ),
            ),
        ],
      ),
    );
  }
}
// #endregion

// #region bad-cupertino-placeholder
/// The same field as `good-cupertino`, with the default placeholder colour.
class BadCupertinoPlaceholder extends StatelessWidget {
  const BadCupertinoPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    // Defect: CupertinoColors.placeholderText, the default, is under 4.5:1
    // on the field, light and dark (FL-510).
    return const CupertinoEmailField(id: 'v01-bad-cupertino-placeholder-email');
  }
}
// #endregion

// #region bad-caption
/// `good-caption`'s picture with the caption bar at its default: no
/// background.
class BadCaption extends StatelessWidget {
  const BadCaption({super.key});

  @override
  Widget build(BuildContext context) {
    // Defect: the caption is drawn straight on the picture, where it is
    // pale, and is under 4.5:1 there (FL-512).
    return const CaptionedPicture();
  }
}
// #endregion

// #region bad-colour-only
/// The same choice as `good-selection` as a list of `ListTile`s with
/// `selected`, at its defaults.
class BadColourOnly extends StatefulWidget {
  const BadColourOnly({super.key});

  @override
  State<BadColourOnly> createState() => _BadColourOnlyState();
}

class _BadColourOnlyState extends State<BadColourOnly> {
  var _view = CalendarView.week;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Calendar view'),
        for (final v in CalendarView.values)
          TestId(
            'v01-bad-colour-only-${v.name}',
            // Defect: the chosen tile differs from the others only by the
            // colour of its text, under 3:1 against theirs (FL-513).
            child: ListTile(
              title: Text(v.title),
              selected: v == _view,
              onTap: () => setState(() => _view = v),
            ),
          ),
      ],
    );
  }
}
// #endregion

// #region bad-faint-edge
/// A field whose edge is drawn in `outlineVariant`, the scheme's role for
/// decorative lines, in place of `outline`.
class BadFaintEdge extends StatelessWidget {
  const BadFaintEdge({super.key});

  @override
  Widget build(BuildContext context) {
    final faint = OutlineInputBorder(
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
    return TestId(
      'v01-bad-faint-edge-email',
      child: TextField(
        decoration: InputDecoration(
          labelText: 'Email',
          floatingLabelBehavior: FloatingLabelBehavior.always,
          // Defect: the edge that shows where the field is is under 3:1
          // against the page, light and dark.
          border: faint,
          enabledBorder: faint,
        ),
      ),
    );
  }
}
// #endregion
