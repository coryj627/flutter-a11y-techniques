import 'package:flutter/material.dart';

import '../catalog/registry.dart';
import '../catalog/technique.dart';
import 'routes.dart';
import 'screens.dart';
import 'widgets.dart';

class A11yTechniquesApp extends StatelessWidget {
  const A11yTechniquesApp({
    super.key,
    required this.registry,
    this.platform,
    this.initialRoute,
  });

  final TechniqueRegistry registry;

  /// The platform whose techniques are shown. Null shows every technique.
  final AppPlatform? platform;

  final String? initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      initialRoute: initialRoute,
      onGenerateRoute: _routeFor,
      onGenerateInitialRoutes: (name) => [
        for (final ancestor in _historyFor(name))
          _routeFor(RouteSettings(name: ancestor)),
      ],
    );
  }

  Route<void> _routeFor(RouteSettings settings) => MaterialPageRoute<void>(
    settings: settings,
    builder: (_) => _screenFor(AppRoute.parse(settings.name)),
  );

  /// The screens that sit under a deep link, oldest first, so Back from a
  /// directly opened example goes to its technique and then the catalog.
  ///
  /// Flutter's default splits the path at every `/`, which would put `/t`
  /// (not a screen) into the history as a "Page not found" page. Only screens
  /// that exist are included here.
  List<String> _historyFor(String name) {
    final technique = switch (AppRoute.parse(name)) {
      ExampleRoute(:final id) => registry.byId(id),
      _ => null,
    };
    return [
      if (AppRoute.parse(name) is! CatalogRoute) AppRoutes.catalog,
      if (technique != null) AppRoutes.technique(technique.id),
      name,
    ];
  }

  Widget _screenFor(AppRoute route) {
    switch (route) {
      case CatalogRoute():
        return CatalogScreen(registry: registry, platform: platform);
      case AboutRoute():
        return const AboutScreen();
      case TechniqueRoute(:final id):
        final technique = registry.byId(id);
        if (technique == null) return const NotFoundScreen();
        return TechniqueScreen(technique: technique, platform: platform);
      case ExampleRoute(:final id, :final slug):
        final technique = registry.byId(id);
        final example = technique?.example(slug);
        if (technique == null || example == null) {
          return const NotFoundScreen();
        }
        return ExampleScreen(technique: technique, example: example);
      case NotFoundRoute():
        return const NotFoundScreen();
    }
  }
}
