import 'package:flutter/material.dart';

import '../s02_informative_images/example_image.dart';

// #region shared
/// A strip of the example photo used as decoration. `sunrisePng` is the
/// small PNG from S02 (`example_image.dart`).
Widget _banner({bool excludeFromSemantics = false, String? semanticLabel}) {
  return Image.memory(
    sunrisePng,
    width: 240,
    height: 48,
    fit: BoxFit.cover,
    filterQuality: FilterQuality.none,
    excludeFromSemantics: excludeFromSemantics,
    semanticLabel: semanticLabel,
  );
}

/// Two lines of text with a decorative banner between them. The banner adds
/// nothing the text does not say.
class _Welcome extends StatelessWidget {
  const _Welcome({required this.banner});

  final Widget banner;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        const Text('Welcome back, Ana.'),
        banner,
        const Text('You have 2 new messages.'),
      ],
    );
  }
}

/// An icon beside the word it illustrates.
class _TopicRow extends StatelessWidget {
  const _TopicRow({required this.icon, required this.text, this.iconLabel});

  final IconData icon;
  final String text;

  /// A text alternative for the icon. Null leaves the icon with none, which
  /// is right when the text beside it says the same thing.
  final String? iconLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        spacing: 12,
        children: [
          Icon(icon, semanticLabel: iconLabel),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

/// Icon rows followed by a line of plain text.
class _Topics extends StatelessWidget {
  const _Topics({required this.labelIcons});

  /// Whether each icon gets a text alternative that repeats its word.
  final bool labelIcons;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TopicRow(
          icon: Icons.local_shipping,
          text: 'Shipping',
          iconLabel: labelIcons ? 'Shipping' : null,
        ),
        _TopicRow(
          icon: Icons.replay,
          text: 'Returns',
          iconLabel: labelIcons ? 'Returns' : null,
        ),
        const Text('Delivery takes 2 to 4 days.'),
      ],
    );
  }
}

/// A small picture beside two lines of text, read as one element.
class _GuideRow extends StatelessWidget {
  const _GuideRow({required this.excludeImage});

  final bool excludeImage;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Row(
        spacing: 12,
        children: [
          Image.memory(
            sunrisePng,
            width: 72,
            height: 48,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.none,
            excludeFromSemantics: excludeImage,
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text('Trail guide'), Text('12 routes')],
            ),
          ),
        ],
      ),
    );
  }
}
// #endregion

// #region good-image-excluded
/// `excludeFromSemantics: true` keeps a decorative `Image` out of the
/// semantics tree. Leaving `semanticLabel` off is not enough: the image
/// would still be there, with no name.
class GoodImageExcluded extends StatelessWidget {
  const GoodImageExcluded({super.key});

  @override
  Widget build(BuildContext context) {
    return _Welcome(banner: _banner(excludeFromSemantics: true));
  }
}
// #endregion

// #region good-icon-no-label
/// Each icon repeats the word beside it. An `Icon` with no `semanticLabel`
/// exposes nothing, so nothing more is needed.
class GoodIconNoLabel extends StatelessWidget {
  const GoodIconNoLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Topics(labelIcons: false);
  }
}
// #endregion

// #region good-background-image
/// A picture painted as a `DecorationImage` is never in the semantics tree.
/// Use it only for decoration: it cannot be given a text alternative.
class GoodBackgroundImage extends StatelessWidget {
  const GoodBackgroundImage({super.key});

  @override
  Widget build(BuildContext context) {
    return _Welcome(
      banner: DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: MemoryImage(sunrisePng),
            fit: BoxFit.cover,
            filterQuality: FilterQuality.none,
          ),
        ),
        child: const SizedBox(width: 240, height: 48),
      ),
    );
  }
}
// #endregion

// #region good-exclude-semantics
/// The avatar shows the initials of the name beside it. `CircleAvatar` has
/// no parameter to hide it, so `ExcludeSemantics` does: it works on any
/// widget.
class GoodExcludeSemantics extends StatelessWidget {
  const GoodExcludeSemantics({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      spacing: 12,
      children: [
        ExcludeSemantics(child: CircleAvatar(child: Text('AK'))),
        Expanded(child: Text('Ana Kovac')),
      ],
    );
  }
}
// #endregion

// #region good-merged-row
/// A decorative picture inside a merged row is excluded too. The row then
/// reads as its text, and is not announced as an image.
class GoodMergedRow extends StatelessWidget {
  const GoodMergedRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const _GuideRow(excludeImage: true);
  }
}
// #endregion

// #region bad-not-excluded
/// Defect: the decorative banner is not excluded. It is in the semantics
/// tree as an image with no name.
class BadNotExcluded extends StatelessWidget {
  const BadNotExcluded({super.key});

  @override
  Widget build(BuildContext context) {
    return _Welcome(banner: _banner());
  }
}
// #endregion

// #region bad-empty-label
/// Defect: the banner has `semanticLabel: ''`, as `alt=""` would be written
/// in HTML. In Flutter an empty label does not hide the image: it is still
/// in the tree, with no name.
class BadEmptyLabel extends StatelessWidget {
  const BadEmptyLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return _Welcome(banner: _banner(semanticLabel: ''));
  }
}
// #endregion

// #region bad-redundant-label
/// Defect: each decorative icon has a `semanticLabel` that repeats the word
/// beside it, so every word is read twice.
class BadRedundantLabel extends StatelessWidget {
  const BadRedundantLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Topics(labelIcons: true);
  }
}
// #endregion

// #region bad-merged-image
/// Defect: the decorative picture in the merged row is not excluded. Its
/// image role is merged into the row, so the row's text is announced as an
/// image.
class BadMergedImage extends StatelessWidget {
  const BadMergedImage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _GuideRow(excludeImage: false);
  }
}
// #endregion
