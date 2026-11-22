import 'package:flutter/widgets.dart';

export 'custom_solution.dart';

/// Catalog groups, matching docs/coverage-inventory.md.
enum TechniqueGroup {
  semantics('S', 'Semantics and content'),
  visual('V', 'Visual presentation and preferences'),
  interaction('I', 'Interaction and input'),
  forms('F', 'Forms'),
  components('C', 'Components');

  const TechniqueGroup(this.prefix, this.title);

  final String prefix;
  final String title;
}

/// The platforms this project builds for.
enum AppPlatform {
  android('Android'),
  ios('iOS'),
  web('Web');

  const AppPlatform(this.title);

  final String title;
}

enum Applicability { applies, notApplicable, limitation }

/// Whether a technique applies on one platform, and why not if it does not.
@immutable
class PlatformStatus {
  /// [note] is for something a reader must know even though the technique
  /// applies, such as a check that could not be automated on this platform.
  const PlatformStatus.applies({this.note})
    : applicability = Applicability.applies,
      issue = null;

  const PlatformStatus.notApplicable(String this.note)
    : applicability = Applicability.notApplicable,
      issue = null;

  /// The pattern cannot be made fully accessible because of the Flutter
  /// framework. [issue] links to the tracking Flutter issue when one exists.
  const PlatformStatus.limitation(String this.note, {this.issue})
    : applicability = Applicability.limitation;

  final Applicability applicability;
  final String? note;
  final Uri? issue;
}

/// A cited source. Every mechanism a good example uses traces to one.
@immutable
class SourceLink {
  const SourceLink(this.title, this.url);

  final String title;
  final String url;

  Uri get uri => Uri.parse(url);
}

/// A WCAG 2.2 success criterion.
@immutable
class WcagCriterion {
  const WcagCriterion(this.number, this.name, this.anchor);

  /// For example `4.1.2`.
  final String number;

  /// For example `Name, Role, Value`.
  final String name;

  /// Fragment in https://www.w3.org/TR/WCAG22/, for example `name-role-value`.
  final String anchor;

  String get label => '$number $name';

  Uri get uri => Uri.parse('https://www.w3.org/TR/WCAG22/#$anchor');
}

enum ExampleKind {
  good('Good example'),
  bad('Bad example');

  const ExampleKind(this.title);

  final String title;
}

enum ExampleVariant {
  material('Material'),
  cupertino('Cupertino'),
  widgets('Widgets layer');

  const ExampleVariant(this.title);

  final String title;
}

/// One live example of a technique.
@immutable
class TechniqueExample {
  /// A good example built by hand gives [customSolution]: one sentence on
  /// what is hand-built and why. It is then shown with
  /// [CustomSolution.label], and listed as custom in
  /// docs/custom-solutions.md.
  const TechniqueExample.good({
    required this.slug,
    required this.title,
    required this.variant,
    required this.builder,
    this.customSolution,
  }) : kind = ExampleKind.good,
       defect = null;

  /// A bad example has exactly one named [defect], which tests assert.
  const TechniqueExample.bad({
    required this.slug,
    required this.title,
    required this.variant,
    required String this.defect,
    required this.builder,
  }) : kind = ExampleKind.bad,
       customSolution = null;

  /// Stable route segment and test locator, for example `good-text`.
  final String slug;
  final String title;
  final ExampleKind kind;
  final ExampleVariant variant;
  final String? defect;

  /// Why a good example is a custom solution, not vetted by a real-world
  /// example: what is hand-built, and why. Null for every other example.
  final String? customSolution;

  final WidgetBuilder builder;

  /// Whether the example is a custom solution (see [customSolution]).
  bool get isCustomSolution => customSolution != null;
}

/// One catalog entry.
@immutable
class Technique {
  const Technique({
    required this.id,
    required this.title,
    required this.group,
    required this.summary,
    required this.platforms,
    required this.wcag,
    required this.examples,
    required this.sources,
  });

  /// Inventory id, for example `C01`.
  final String id;
  final String title;
  final TechniqueGroup group;
  final String summary;
  final Map<AppPlatform, PlatformStatus> platforms;
  final List<WcagCriterion> wcag;
  final List<TechniqueExample> examples;
  final List<SourceLink> sources;

  PlatformStatus statusFor(AppPlatform platform) =>
      platforms[platform] ??
      const PlatformStatus.notApplicable('Not specified for this platform.');

  /// Whether the technique is shown on [platform]. Limitations are shown,
  /// with their limitation documented.
  bool isShownOn(AppPlatform platform) =>
      statusFor(platform).applicability != Applicability.notApplicable;

  TechniqueExample? example(String slug) {
    for (final e in examples) {
      if (e.slug == slug) return e;
    }
    return null;
  }
}
