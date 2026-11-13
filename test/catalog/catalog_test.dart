import 'package:flutter_a11y_techniques/app/routes.dart';
import 'package:flutter_a11y_techniques/catalog/technique.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_catalog.dart';

void main() {
  group('TechniqueRegistry', () {
    final registry = fakeRegistry();

    test('hides techniques that do not apply on a platform', () {
      final android = registry.grouped(AppPlatform.android);
      expect(android.keys, [TechniqueGroup.components]);

      final ios = registry.grouped(AppPlatform.ios);
      expect(ios.keys, [TechniqueGroup.interaction, TechniqueGroup.components]);
    });

    test('keeps limitation entries visible', () {
      final web = registry.grouped(AppPlatform.web);
      expect(web[TechniqueGroup.components]!.single.id, 'C01');
    });

    test('shows everything when the platform is unknown', () {
      expect(registry.grouped(null).values.expand((t) => t), hasLength(2));
    });

    test('finds techniques and examples', () {
      expect(registry.byId('C01')!.example('good-text'), isNotNull);
      expect(registry.byId('C01')!.example('nope'), isNull);
      expect(registry.byId('X99'), isNull);
    });
  });

  group('AppRoute.parse', () {
    test('parses each route shape', () {
      expect(AppRoute.parse('/'), isA<CatalogRoute>());
      expect(AppRoute.parse(null), isA<CatalogRoute>());
      expect(AppRoute.parse('/about'), isA<AboutRoute>());
      expect(
        AppRoute.parse('/t/C01'),
        isA<TechniqueRoute>().having((r) => r.id, 'id', 'C01'),
      );
      expect(
        AppRoute.parse(AppRoutes.example('C01', 'good-text')),
        isA<ExampleRoute>()
            .having((r) => r.id, 'id', 'C01')
            .having((r) => r.slug, 'slug', 'good-text'),
      );
      expect(AppRoute.parse('/nope'), isA<NotFoundRoute>());
      expect(AppRoute.parse('/t/C01/a/b'), isA<NotFoundRoute>());
    });
  });
}
