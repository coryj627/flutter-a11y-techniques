import '../catalog/technique.dart';
import 'c01_button/c01_button.dart';
import 'f01_text_fields/f01_text_fields.dart';
import 'i12_announcements/i12_announcements.dart';
import 's01_accessible_names/s01_accessible_names.dart';
import 's02_informative_images/s02_informative_images.dart';
import 's03_decorative_images/s03_decorative_images.dart';
import 's04_functional_images/s04_functional_images.dart';
import 's05_headings/s05_headings.dart';

/// Every technique in the catalog. Add each new technique here.
final List<Technique> allTechniques = [
  c01Button,
  s01AccessibleNames,
  s02InformativeImages,
  s03DecorativeImages,
  s04FunctionalImages,
  s05Headings,
  f01TextFields,
  i12Announcements,
];
