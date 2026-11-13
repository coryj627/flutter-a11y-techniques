/// Stable routes. Every example is addressable so each test layer can open
/// it directly: `/t/<id>/<slug>`.
abstract final class AppRoutes {
  static const catalog = '/';
  static const about = '/about';

  /// Stands in for an address that is not valid URI syntax.
  static const notFound = '/not-found';

  static String technique(String id) => '/t/$id';

  static String example(String id, String slug) => '/t/$id/$slug';
}

sealed class AppRoute {
  const AppRoute();

  /// Parses a route name. Unknown shapes become [NotFoundRoute].
  factory AppRoute.parse(String? name) {
    final List<String> segments;
    try {
      segments = Uri.parse(name ?? '/').pathSegments;
    } on FormatException {
      // A malformed address, such as a bad percent-encoding (`/t/C01/%FF`),
      // is an unknown page, not a crash at startup.
      return const NotFoundRoute();
    }
    return switch (segments) {
      [] => const CatalogRoute(),
      ['about'] => const AboutRoute(),
      ['t', final id] => TechniqueRoute(id),
      ['t', final id, final slug] => ExampleRoute(id, slug),
      _ => const NotFoundRoute(),
    };
  }
}

class CatalogRoute extends AppRoute {
  const CatalogRoute();
}

class AboutRoute extends AppRoute {
  const AboutRoute();
}

class TechniqueRoute extends AppRoute {
  const TechniqueRoute(this.id);

  final String id;
}

class ExampleRoute extends AppRoute {
  const ExampleRoute(this.id, this.slug);

  final String id;
  final String slug;
}

class NotFoundRoute extends AppRoute {
  const NotFoundRoute();
}
