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
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => _screenFor(AppRoute.parse(settings.name)),
      ),
    );
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
