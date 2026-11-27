import 'package:flutter/material.dart';

import '../../catalog/test_id.dart';

// Every good example is Flutter's own `Semantics` through its documented
// parameters: `excludeSemantics: true`, which "replace[s] all child
// semantics with this node", or `MergeSemantics` with each piece in
// `ExcludeSemantics`. What Flutter cannot do is in
// docs/flutter-limitations.md and is not built here.

// #region shared
/// A rating: its average number of stars, out of five, and its number of
/// reviews.
@immutable
class Rating {
  const Rating(this.stars, this.reviews);

  final double stars;
  final int reviews;

  /// The rating as it is shown: "3.4 / 5".
  String get shown => '${stars.toStringAsFixed(1)} / 5';

  /// What the rating means, in words, as the Android references word it:
  /// "Rating: 3.4 out of 5 stars, based on 856 reviews".
  String get words =>
      'Rating: ${stars.toStringAsFixed(1)} out of 5 stars, '
      'based on $reviews ${reviews == 1 ? 'review' : 'reviews'}';

  /// The rating once one more review of [stars] has been added.
  Rating plus(int stars) =>
      Rating((this.stars * reviews + stars) / (reviews + 1), reviews + 1);
}

/// The rating every example starts with.
const startRating = Rating(3.4, 856);

/// The rating as the reference repositories draw it: the word "Rating:", a
/// bar filled to the rating, "3.4 / 5", and "Reviews: 856". The bar is a
/// Material `LinearProgressIndicator`, which has semantics of its own: the
/// value 68, and a progress bar role on Android and the web (none on iOS,
/// FL-256). [piece] wraps each of the four pieces,
/// for `good-hidden-pieces`.
class RatingBar extends StatelessWidget {
  const RatingBar({super.key, required this.rating, this.piece});

  final Rating rating;
  final Widget Function(Widget child)? piece;

  @override
  Widget build(BuildContext context) {
    Widget wrap(Widget child) => piece == null ? child : piece!(child);
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        wrap(const Text('Rating:')),
        wrap(
          SizedBox(
            width: 80,
            child: LinearProgressIndicator(value: rating.stars / 5),
          ),
        ),
        wrap(Text(rating.shown)),
        wrap(Text('Reviews: ${rating.reviews}')),
      ],
    );
  }
}

/// The rating drawn as five stars, then "3.4" and "(856)". An `Icon` with
/// no `semanticLabel` gives assistive technology nothing.
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.rating});

  final Rating rating;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final full = rating.stars.floor();
    final half = rating.stars - full >= 0.25 && rating.stars - full < 0.75;
    return Wrap(
      spacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < 5; i++)
          Icon(
            i < full
                ? Icons.star
                : (i == full && half)
                ? Icons.star_half
                : Icons.star_border,
            color: color,
          ),
        Text(rating.stars.toStringAsFixed(1)),
        Text('(${rating.reviews})'),
      ],
    );
  }
}

/// A 2 pixel outline in the page's text colour while a `TextButton` has
/// keyboard focus, through the button's own `style`, as in C18: Material's
/// own focus tint on a `TextButton` is under 3:1 against the page
/// (docs/flutter-limitations.md, FL-430).
ButtonStyle focusRing(ColorScheme colors) => ButtonStyle(
  side: WidgetStateProperty.resolveWith(
    (states) => states.contains(WidgetState.focused)
        ? BorderSide(color: colors.onSurface, width: 2)
        : null,
  ),
);

/// Lays out a rating and, under it, a button that adds a 5-star review, so
/// that people and tests can see whether what the rating says follows what
/// it shows. [builder] gets the rating as it is now.
///
/// For the tests alone, an empty node after them whose identifier says how
/// many reviews the row shows, `s10-<slug>-shows-857`: the shown row is
/// hidden from assistive technology, so without it a test could not tell a
/// stale replacement from a button that did nothing. It has no label,
/// value, or action, and is one pixel square (a node of no size is left out
/// of the tree). A new node is made for each count (its key):
/// a change of an identifier alone is not sent to the platform
/// (docs/flutter-limitations.md, FL-331).
class RatingDemo extends StatefulWidget {
  const RatingDemo({super.key, required this.slug, required this.builder});

  final String slug;
  final Widget Function(BuildContext context, Rating rating) builder;

  @override
  State<RatingDemo> createState() => _RatingDemoState();
}

class _RatingDemoState extends State<RatingDemo> {
  var _rating = startRating;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final shows = 's10-${widget.slug}-shows-${_rating.reviews}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        widget.builder(context, _rating),
        TestId(
          's10-${widget.slug}-add',
          child: TextButton(
            style: focusRing(colors),
            onPressed: () => setState(() => _rating = _rating.plus(5)),
            child: const Text('Add a 5-star review'),
          ),
        ),
        Semantics(
          key: ValueKey<String>(shows),
          container: true,
          identifier: shows,
          child: const SizedBox.square(dimension: 1),
        ),
      ],
    );
  }
}
// #endregion

// #region good-exclude-semantics
/// The rating row replaced, for assistive technology, by one node that says
/// what it means: `Semantics(excludeSemantics: true)` "replace[s] all child
/// semantics with this node", so the word, the bar (a node of its own, with
/// a value), and the two numbers are hidden, and only the label is exposed. The
/// label is worked out from the same values as the pieces, so it follows
/// them when a review is added.
class GoodExcludeSemantics extends StatelessWidget {
  const GoodExcludeSemantics({super.key});

  @override
  Widget build(BuildContext context) {
    return RatingDemo(
      slug: 'good-exclude-semantics',
      builder: (context, rating) => Semantics(
        identifier: 's10-good-exclude-semantics-rating',
        label: rating.words,
        excludeSemantics: true,
        child: RatingBar(rating: rating),
      ),
    );
  }
}
// #endregion

// #region good-hidden-pieces
/// The same replacement made the other way the Android Compose reference
/// shows: the row is merged into one node (`MergeSemantics`), given the
/// label, and every piece is hidden with `ExcludeSemantics`. Every piece
/// has to be: the bar left out gives the whole node its value, 68, and on
/// Android and the web its progress bar role (docs/flutter-limitations.md,
/// FL-330).
class GoodHiddenPieces extends StatelessWidget {
  const GoodHiddenPieces({super.key});

  @override
  Widget build(BuildContext context) {
    const rating = startRating;
    return MergeSemantics(
      child: Semantics(
        identifier: 's10-good-hidden-pieces-rating',
        label: rating.words,
        child: RatingBar(
          rating: rating,
          piece: (child) => ExcludeSemantics(child: child),
        ),
      ),
    );
  }
}
// #endregion

// #region good-stars
/// Five stars and two numbers, which say nothing alone, replaced by one
/// node that says what they mean.
class GoodStars extends StatelessWidget {
  const GoodStars({super.key});

  @override
  Widget build(BuildContext context) {
    const rating = startRating;
    return Semantics(
      identifier: 's10-good-stars-rating',
      label: rating.words,
      excludeSemantics: true,
      child: const StarRow(rating: rating),
    );
  }
}
// #endregion

// #region bad-pieces
class BadPieces extends StatelessWidget {
  const BadPieces({super.key});

  @override
  Widget build(BuildContext context) {
    // Defect: nothing replaces the pieces. The stars give nothing, and
    // "3.4" and "(856)" are read alone, with nothing to say what they are.
    return const StarRow(rating: startRating);
  }
}
// #endregion

// #region bad-merged
class BadMerged extends StatelessWidget {
  const BadMerged({super.key});

  @override
  Widget build(BuildContext context) {
    // Defect: the row is merged and not replaced. Its texts join one node,
    // and the bar's value, 68, becomes the node's (and its role, where the
    // platform has one: FL-330): the rating is read with a stray 68. Not a
    // shown failure of a success criterion; shown for what the user hears.
    return MergeSemantics(
      child: Semantics(
        identifier: 's10-bad-merged-rating',
        child: const RatingBar(rating: startRating),
      ),
    );
  }
}
// #endregion

// #region bad-not-excluded
class BadNotExcluded extends StatelessWidget {
  const BadNotExcluded({super.key});

  @override
  Widget build(BuildContext context) {
    const rating = startRating;
    // Defect: the label is given and the pieces are not hidden. They join
    // the label's node, with the bar's value (FL-330): the rating is read
    // twice, with a stray 68. Not a shown failure of a success criterion;
    // shown for what the user hears.
    return Semantics(
      identifier: 's10-bad-not-excluded-rating',
      label: rating.words,
      child: const RatingBar(rating: rating),
    );
  }
}
// #endregion

// #region bad-hides-control
class BadHidesControl extends StatefulWidget {
  const BadHidesControl({super.key});

  @override
  State<BadHidesControl> createState() => _BadHidesControlState();
}

class _BadHidesControlState extends State<BadHidesControl> {
  var _opened = 0;

  @override
  Widget build(BuildContext context) {
    const rating = startRating;
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        // Defect: the replacement takes in a control. The Reviews button is
        // hidden with the stars, so a screen reader cannot find it, though
        // the keyboard still reaches it.
        Semantics(
          identifier: 's10-bad-hides-control-rating',
          label: rating.words,
          excludeSemantics: true,
          child: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const StarRow(rating: rating),
              TextButton(
                style: focusRing(colors),
                onPressed: () => setState(() => _opened++),
                child: const Text('Reviews'),
              ),
            ],
          ),
        ),
        // How many times the button ran, so that people and tests can
        // see that the keyboard reaches it.
        Semantics(
          identifier: 's10-bad-hides-control-opens',
          child: Text('Reviews opened: $_opened'),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-stale
class BadStale extends StatelessWidget {
  const BadStale({super.key});

  @override
  Widget build(BuildContext context) {
    return RatingDemo(
      slug: 'bad-stale',
      builder: (context, rating) => Semantics(
        identifier: 's10-bad-stale-rating',
        // Defect: the label is fixed text. When a review is added the row
        // shows 857 reviews, and a screen reader still hears 856.
        label: startRating.words,
        excludeSemantics: true,
        child: RatingBar(rating: rating),
      ),
    );
  }
}
// #endregion
