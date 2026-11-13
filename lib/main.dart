import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'app/app.dart';
import 'catalog/registry.dart';
import 'techniques/all_techniques.dart';

void main() {
  runApp(
    A11yTechniquesApp(
      registry: TechniqueRegistry(allTechniques),
      platform: currentAppPlatform(),
    ),
  );
  // Flutter web builds its accessibility tree only on request. Enable it at
  // startup so assistive technology always has it.
  // https://docs.flutter.dev/ui/accessibility/web-accessibility
  if (kIsWeb) {
    SemanticsBinding.instance.ensureSemantics();
  }
}
