import 'package:flutter/material.dart';

import 'example_image.dart';

// #region shared
/// The example photo at a fixed size. `sunrisePng` is a small PNG held in
/// `example_image.dart`; `semanticLabel` works the same on `Image.asset` and
/// `Image.network`.
Widget _photo({String? semanticLabel}) {
  return Image.memory(
    sunrisePng,
    width: 192,
    height: 128,
    fit: BoxFit.cover,
    filterQuality: FilterQuality.none,
    semanticLabel: semanticLabel,
  );
}

/// One order in a list: a status icon and the order's name, read as one
/// element.
class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order, required this.icon, this.status});

  final String order;
  final IconData icon;

  /// The text alternative for the icon. Null leaves the icon with none.
  final String? status;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          spacing: 12,
          children: [
            Icon(icon, semanticLabel: status),
            Expanded(child: Text(order)),
          ],
        ),
      ),
    );
  }
}
// #endregion

// #region good-image-label
/// `semanticLabel` is the image's text alternative. It says what the picture
/// shows, in a few words, without the word "image".
class GoodImageLabel extends StatelessWidget {
  const GoodImageLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        _photo(semanticLabel: 'Sunrise over green hills'),
        const Text('Taken from the east ridge trail.'),
      ],
    );
  }
}
// #endregion

// #region good-icon-label
/// Each icon is the only thing that says whether the order arrived, so each
/// has a `semanticLabel`. `MergeSemantics` reads the status and the order as
/// one element.
class GoodIconLabel extends StatelessWidget {
  const GoodIconLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _OrderRow(
          order: 'Order 1042',
          icon: Icons.check_circle,
          status: 'Delivered',
        ),
        _OrderRow(order: 'Order 1043', icon: Icons.error, status: 'Delayed'),
      ],
    );
  }
}
// #endregion

// #region good-group-description
/// An icon and a short text that only make sense together. One description
/// replaces both: `Semantics(label:)` gives it, and `ExcludeSemantics` keeps
/// the parts from being read as well.
class GoodGroupDescription extends StatelessWidget {
  const GoodGroupDescription({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Sunrise at 6:35 am',
      child: const ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [Icon(Icons.wb_twilight), Text('6:35 am')],
        ),
      ),
    );
  }
}
// #endregion

// #region good-chart
/// A drawn chart is an image: `Semantics(image: true, label:)` gives it a
/// short alternative that states its point. The numbers are in the text
/// below it, for everyone.
class GoodChart extends StatelessWidget {
  const GoodChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Semantics(
          image: true,
          label: 'Bar chart: orders rose every quarter of 2025',
          child: CustomPaint(
            size: const Size(200, 100),
            painter: _BarChart(
              values: const [20, 35, 50, 80],
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const Text('Orders in 2025: Q1 20, Q2 35, Q3 50, Q4 80.'),
      ],
    );
  }
}

class _BarChart extends CustomPainter {
  const _BarChart({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final slot = size.width / values.length;
    for (var i = 0; i < values.length; i++) {
      final height = size.height * values[i] / 100;
      canvas.drawRect(
        Rect.fromLTWH(i * slot + 6, size.height - height, slot - 12, height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarChart old) =>
      old.color != color || old.values != values;
}
// #endregion

// #region bad-no-label
/// Defect: the photo has no `semanticLabel`, so it has no text alternative.
class BadNoLabel extends StatelessWidget {
  const BadNoLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [_photo(), const Text('Taken from the east ridge trail.')],
    );
  }
}
// #endregion

// #region bad-icon-no-label
/// Defect: the icons have no `semanticLabel`. Both rows read as an order
/// number only, and whether the order arrived is not exposed.
class BadIconNoLabel extends StatelessWidget {
  const BadIconNoLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _OrderRow(order: 'Order 1042', icon: Icons.check_circle),
        _OrderRow(order: 'Order 1043', icon: Icons.error),
      ],
    );
  }
}
// #endregion

// #region bad-role-in-label
/// Defect: the label starts with "Image of". The screen reader adds the role
/// itself, so "image" is heard twice.
class BadRoleInLabel extends StatelessWidget {
  const BadRoleInLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return _photo(semanticLabel: 'Image of a sunrise over green hills');
  }
}
// #endregion

// #region bad-filename-label
/// Defect: the label is the file's name. It is a text alternative that says
/// nothing about what the picture shows.
class BadFilenameLabel extends StatelessWidget {
  const BadFilenameLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return _photo(semanticLabel: 'IMG_2041.png');
  }
}
// #endregion
