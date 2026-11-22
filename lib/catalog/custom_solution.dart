/// The label every custom solution carries, in the app, the Widgetbook, and
/// the docs (docs/custom-solutions.md). A custom solution is a good example
/// that assembles by hand a control or a mechanism that a Flutter widget for
/// the pattern would otherwise provide, or that no Flutter widget provides.
///
/// Plain Dart with no imports, so that the tools in `tool/` can use it too.
abstract final class CustomSolution {
  /// The label's first sentence. The docs check looks for it.
  static const firstSentence =
      'Custom solution: not vetted by a real-world example.';

  /// The whole label.
  static const label =
      '$firstSentence It is tested here in isolation, with screen-reader '
      'transcripts, but has not been built into a real app and tested in a '
      'user journey. Do not treat it as a vetted technique.';

  /// The label where space is short, as in a list of examples.
  static const short = 'Custom solution, not vetted';
}
