import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../catalog/test_id.dart';
import '../c03_stand_alone_link/examples.dart' show MaterialLink, linkStyle;
import '../s02_informative_images/example_image.dart';

// Every good example is Flutter's own widgets used through their documented
// parameters: Material's `Card`, `TextButton`, and `ListTile`, and Cupertino's
// colours (Cupertino has no card). What they cannot do is in
// docs/flutter-limitations.md and is not built here.

// #region shared
/// The card's subject, the same in every example.
const trailName = 'Ridge trail';

/// The card's text.
const trailText = 'A 6 km climb with a view.';

/// The picture's text alternative.
const pictureLabel = 'Sunrise over the valley';

/// The card's heading: level 3, under the screen's level 1 title and its
/// level 2 "Example". `headingLevel` makes it a heading on every platform
/// (FL-003, FL-005) and the right level on the web (FL-004).
class CardHeading extends StatelessWidget {
  const CardHeading({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      headingLevel: 3,
      child: Text(trailName, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

/// The card's picture, with a text alternative (S02).
Widget picture() => Image.memory(
  sunrisePng,
  width: 96,
  height: 64,
  fit: BoxFit.cover,
  filterQuality: FilterQuality.none,
  semanticLabel: pictureLabel,
);

/// A 2 pixel outline in the page's text colour while a `TextButton` has
/// keyboard focus, through the button's own `style`, as in C12: Material's
/// own focus tint on a `TextButton` is under 3:1 against the page
/// (docs/flutter-limitations.md, FL-430).
ButtonStyle focusRing(ColorScheme colors) => ButtonStyle(
  side: WidgetStateProperty.resolveWith(
    (states) => states.contains(WidgetState.focused)
        ? BorderSide(color: colors.onSurface, width: 2)
        : null,
  ),
);

/// A count under a card, so that people and tests can confirm which action
/// ran: "Saves: 1". [id] is its test identifier.
class Count extends StatelessWidget {
  const Count({super.key, required this.id, required this.text});

  final String id;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: ValueKey<String>(id),
      identifier: id,
      liveRegion: true,
      child: Text(text),
    );
  }
}

/// Lays out one example: the card and its counts below it. [builder] gets
/// a function that adds one to a count by its name.
class CardDemo extends StatefulWidget {
  const CardDemo({
    super.key,
    required this.slug,
    required this.counts,
    required this.builder,
  });

  final String slug;

  /// The names of the counts, in order: "Saves", "Shares", "Opens".
  final List<String> counts;
  final Widget Function(BuildContext context, void Function(String) add)
  builder;

  @override
  State<CardDemo> createState() => _CardDemoState();
}

class _CardDemoState extends State<CardDemo> {
  final _counts = <String, int>{};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        widget.builder(
          context,
          (name) => setState(() => _counts[name] = (_counts[name] ?? 0) + 1),
        ),
        for (final name in widget.counts)
          Count(
            id: 'c18-${widget.slug}-${name.toLowerCase()}',
            text: '$name: ${_counts[name] ?? 0}',
          ),
      ],
    );
  }
}
// #endregion

// #region good-material
/// A card with separate parts: a heading, its text, a picture, and two
/// actions. `semanticContainer: false` keeps each part a node of its own,
/// as the `Card` documentation says for a card that "contains multiple
/// different types of content". Each button's name says which trail it
/// acts on, with `Text(semanticsLabel:)`, and starts with its visible word.
class GoodMaterial extends StatelessWidget {
  const GoodMaterial({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CardDemo(
      slug: 'good-material',
      counts: const ['Saves', 'Shares'],
      builder: (context, add) => Card(
        semanticContainer: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              const CardHeading(),
              const Text(trailText),
              picture(),
              Wrap(
                spacing: 8,
                children: [
                  TestId(
                    'c18-good-material-save',
                    child: TextButton(
                      style: focusRing(colors),
                      onPressed: () => add('Saves'),
                      child: const Text(
                        'Save',
                        semanticsLabel: 'Save $trailName',
                      ),
                    ),
                  ),
                  TestId(
                    'c18-good-material-share',
                    child: TextButton(
                      style: focusRing(colors),
                      onPressed: () => add('Shares'),
                      child: const Text(
                        'Share',
                        semanticsLabel: 'Share $trailName',
                      ),
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
// #endregion

// #region good-tappable
/// A card that is one control: a `ListTile` with `onTap`, which is a button
/// on every platform, named by its title and its text. Its title is not a
/// heading: a heading merged into a control is a heading and no longer a
/// button on the web (`bad-heading-button`).
class GoodTappable extends StatelessWidget {
  const GoodTappable({super.key});

  @override
  Widget build(BuildContext context) {
    return CardDemo(
      slug: 'good-tappable',
      counts: const ['Opens'],
      builder: (context, add) => Card(
        clipBehavior: Clip.antiAlias,
        child: TestId(
          'c18-good-tappable-card',
          child: ListTile(
            title: const Text(trailName),
            subtitle: const Text(trailText),
            onTap: () => add('Opens'),
          ),
        ),
      ),
    );
  }
}
// #endregion

// #region good-cupertino
/// Cupertino has no card. Its grouped background and a rounded box draw
/// one; a box gives assistive technology nothing, so the parts are nodes
/// of their own, as in `good-material`: a heading, its text, a picture.
class GoodCupertino extends StatelessWidget {
  const GoodCupertino({super.key});

  @override
  Widget build(BuildContext context) {
    final text = CupertinoTheme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Semantics(
              headingLevel: 3,
              child: Text(trailName, style: text.navTitleTextStyle),
            ),
            Text(trailText, style: text.textStyle),
            picture(),
          ],
        ),
      ),
    );
  }
}
// #endregion

// #region bad-default-container
class BadDefaultContainer extends StatelessWidget {
  const BadDefaultContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CardDemo(
      slug: 'bad-default-container',
      counts: const ['Saves'],
      // Defect: `semanticContainer` is left at its default, true. The card's
      // texts join one node, and the heading's level is on it: the heading
      // and the text are read as one heading.
      builder: (context, add) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              const CardHeading(),
              const Text(trailText),
              TestId(
                'c18-bad-default-container-save',
                child: TextButton(
                  style: focusRing(colors),
                  onPressed: () => add('Saves'),
                  child: const Text('Save', semanticsLabel: 'Save $trailName'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// #endregion

// #region bad-heading-button
class BadHeadingButton extends StatelessWidget {
  const BadHeadingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return CardDemo(
      slug: 'bad-heading-button',
      counts: const ['Opens'],
      builder: (context, add) => Card(
        clipBehavior: Clip.antiAlias,
        child: TestId(
          'c18-bad-heading-button-card',
          child: ListTile(
            // Defect: the title is a heading, and a heading merged into the
            // tile is, on the web, a heading and not a button.
            title: Semantics(headingLevel: 3, child: const Text(trailName)),
            subtitle: const Text(trailText),
            onTap: () => add('Opens'),
          ),
        ),
      ),
    );
  }
}
// #endregion

// #region bad-ink-well
class BadInkWell extends StatelessWidget {
  const BadInkWell({super.key});

  @override
  Widget build(BuildContext context) {
    return CardDemo(
      slug: 'bad-ink-well',
      counts: const ['Opens'],
      // Defect: the tappable card of the `Card` documentation, an `InkWell`,
      // has no button role on Android and iOS (FL-401).
      builder: (context, add) => Card(
        clipBehavior: Clip.antiAlias,
        child: TestId(
          'c18-bad-ink-well-card',
          child: InkWell(
            onTap: () => add('Opens'),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [Text(trailName), Text(trailText)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// #endregion

// #region bad-read-more
/// Where the "Read more" link goes: this technique's page in the app.
const readMoreRoute = '/t/C18';

class BadReadMore extends StatelessWidget {
  const BadReadMore({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      semanticContainer: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            const CardHeading(),
            const Text(trailText),
            TestId(
              'c18-bad-read-more-link',
              // C03's link. On the web the browser follows its address.
              child: MaterialLink(
                url: Uri.parse('#$readMoreRoute'),
                onTap: () {
                  if (!kIsWeb) Navigator.of(context).pushNamed(readMoreRoute);
                },
                // Defect: the link says "Read more". What it reads more of is
                // the heading above it, which is not related to the link.
                child: Text('Read more', style: linkStyle(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// #endregion
