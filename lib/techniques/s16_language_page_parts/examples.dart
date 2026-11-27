import 'package:flutter/material.dart';

import '../../catalog/test_id.dart';

// The app's own language, the language of the page (3.1.1), is set for the
// whole app by `MaterialApp`, which resolves its locale from the device and
// its `supportedLocales` and tells the platform: the page's `lang` on the
// web, the default language of every node on Android and iOS. This app
// sets neither, so its language is en-US, the default. The examples mark
// the parts that are in another language (3.1.2) with Flutter's own
// documented parameters: `Semantics(localeForSubtree:)` round a passage or
// a control, and `TextSpan(locale:)` round a phrase. On the web a phrase
// marked with `TextSpan(locale:)` is not marked at all: the web engine
// drops the language of a part of a text (FL-020). What the framework
// cannot do is in docs/flutter-limitations.md and is not built here.

// #region shared
/// French, by language alone. A locale with a country, `Locale('fr', 'FR')`,
/// is written `fr_FR` on the web, which no browser reads as French
/// (`bad-region-tag`, FL-020).
const french = Locale('fr');

/// The English line before a passage, in the app's own language.
const lead = 'The sign at the door reads:';

/// The passage in French.
const passage = 'Bienvenue à tous nos visiteurs.';

/// The languages of the language menus, each named in its own language,
/// with its name in English for the "Chosen" line.
const languages = [
  (code: 'fr', name: 'Français', english: 'French'),
  (code: 'es', name: 'Español', english: 'Spanish'),
  (code: 'de', name: 'Deutsch', english: 'German'),
];

/// The line under a language menu that says which language was chosen
/// last: "Chosen: French". [id] is its test identifier.
class Chosen extends StatelessWidget {
  const Chosen({super.key, required this.id, required this.chosen});

  final String id;
  final String chosen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Semantics(
        key: ValueKey<String>(id),
        identifier: id,
        liveRegion: true,
        child: Text('Chosen: $chosen'),
      ),
    );
  }
}

/// One language of a language menu.
typedef Language = ({String code, String name, String english});

/// A language menu: one `ListTile` per language, titled by [title], each
/// tile with its test identifier inside [around], and the "Chosen" line
/// under them.
class LanguageMenu extends StatefulWidget {
  const LanguageMenu({
    super.key,
    required this.slug,
    required this.title,
    this.around = _itself,
  });

  final String slug;
  final Widget Function(Language language) title;
  final Widget Function(Language language, Widget tile) around;

  static Widget _itself(Language language, Widget tile) => tile;

  @override
  State<LanguageMenu> createState() => _LanguageMenuState();
}

class _LanguageMenuState extends State<LanguageMenu> {
  var _chosen = 'none';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final l in languages)
          widget.around(
            l,
            TestId(
              's16-${widget.slug}-${l.code}',
              child: ListTile(
                title: widget.title(l),
                onTap: () => setState(() => _chosen = l.english),
              ),
            ),
          ),
        Chosen(id: 's16-${widget.slug}-chosen', chosen: _chosen),
      ],
    );
  }
}
// #endregion

// #region good-passage
/// A passage in French after a line in English: the passage inside
/// `Semantics(localeForSubtree: Locale('fr'))`. Its node is French, and
/// the English line keeps the app's language. Web: `lang="fr"` on the
/// passage's element. Android: a `LocaleSpan` fr over its text. iOS: the
/// element's language is fr (source read; XCUITest cannot read it).
class GoodPassage extends StatelessWidget {
  const GoodPassage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(lead),
        const SizedBox(height: 8),
        Semantics(localeForSubtree: french, child: const Text(passage)),
      ],
    );
  }
}
// #endregion

// #region good-phrase
/// A phrase in French inside a sentence in English: `TextSpan(locale:)`
/// round the phrase, whose documentation says it sets how assistive
/// technology pronounces the text. Android: a `LocaleSpan` fr over the
/// phrase alone. iOS: the phrase's range of the label carries the language
/// (source read). Web: nothing; the web engine drops a part's language,
/// so the phrase is not marked there (FL-020), and the web has no good
/// example of a phrase.
class GoodPhrase extends StatelessWidget {
  const GoodPhrase({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        text: 'The guide said ',
        children: [
          TextSpan(text: 'bon voyage', locale: french),
          TextSpan(text: ' as we left.'),
        ],
      ),
    );
  }
}
// #endregion

// #region good-language-menu
/// A language menu, each language named in its own language: each
/// `ListTile`, with its test identifier, inside
/// `Semantics(localeForSubtree:)` with its language, so that the tile's own
/// node, a button, is in that language on every platform. The language is set round the whole tile: set inside it, on
/// its title, it is lost (`bad-title-in-tile`).
class GoodLanguageMenu extends StatelessWidget {
  const GoodLanguageMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return LanguageMenu(
      slug: 'good-language-menu',
      title: (l) => Text(l.name),
      around: (l, tile) =>
          Semantics(localeForSubtree: Locale(l.code), child: tile),
    );
  }
}
// #endregion

// #region bad-unmarked
class BadUnmarked extends StatelessWidget {
  const BadUnmarked({super.key});

  @override
  Widget build(BuildContext context) {
    // Defect: nothing says that the passage is in French, so it is in the
    // app's language, English, and read with English speech.
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text(lead), SizedBox(height: 8), Text(passage)],
    );
  }
}
// #endregion

// #region bad-title-in-tile
class BadTitleInTile extends StatelessWidget {
  const BadTitleInTile({super.key});

  @override
  Widget build(BuildContext context) {
    return LanguageMenu(
      slug: 'bad-title-in-tile',
      // Defect: the language is set on the title inside the tile, whose
      // text the tile merges into its own node. The merged node keeps the
      // app's language, and the title's is lost (FL-361).
      title: (l) =>
          Semantics(localeForSubtree: Locale(l.code), child: Text(l.name)),
    );
  }
}
// #endregion

// #region bad-region-tag
class BadRegionTag extends StatelessWidget {
  const BadRegionTag({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(lead),
        const SizedBox(height: 8),
        // Defect: a locale with a country is written `lang="fr_FR"` on the
        // web, which is not a language tag, and no browser reads it as
        // French (FL-020). Android and iOS are given fr-FR.
        Semantics(
          localeForSubtree: const Locale('fr', 'FR'),
          child: const Text(passage),
        ),
      ],
    );
  }
}
// #endregion

// #region bad-override
class BadOverride extends StatelessWidget {
  const BadOverride({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(lead),
        const SizedBox(height: 8),
        // Defect: `Localizations.override` marks the passage French, and
        // also sets the whole app's language to French, which stays
        // French after this screen is closed (FL-360).
        Localizations.override(
          context: context,
          locale: french,
          child: const Text(passage),
        ),
      ],
    );
  }
}
// #endregion
