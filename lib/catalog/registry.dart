import 'package:flutter/foundation.dart';

import 'technique.dart';

/// The platform the app is running on, or null on an unsupported one.
AppPlatform? currentAppPlatform() {
  if (kIsWeb) return AppPlatform.web;
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => AppPlatform.android,
    TargetPlatform.iOS => AppPlatform.ios,
    _ => null,
  };
}

/// The set of techniques in the catalog.
class TechniqueRegistry {
  TechniqueRegistry(List<Technique> techniques)
    : techniques = List.unmodifiable(techniques),
      assert(
        techniques.map((t) => t.id).toSet().length == techniques.length,
        'Technique ids must be unique.',
      );

  final List<Technique> techniques;

  Technique? byId(String id) {
    for (final t in techniques) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Techniques shown on [platform], grouped in catalog order. A null
  /// platform (unsupported host, such as a desktop debug run) shows all.
  Map<TechniqueGroup, List<Technique>> grouped(AppPlatform? platform) {
    final result = <TechniqueGroup, List<Technique>>{};
    for (final group in TechniqueGroup.values) {
      final inGroup = [
        for (final t in techniques)
          if (t.group == group && (platform == null || t.isShownOn(platform)))
            t,
      ]..sort((a, b) => a.id.compareTo(b.id));
      if (inGroup.isNotEmpty) result[group] = inGroup;
    }
    return result;
  }
}
