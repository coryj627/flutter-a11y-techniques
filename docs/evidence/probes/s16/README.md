# S16 probe: what reaches assistive technology of an app's language, a passage's, and a phrase's

Run on 2026-11-27, Flutter 3.47.5, before the S16 examples were written.
The fixture is `probe.dart.txt`, a second entry point and not part of the
app: 25 fixtures, `p01` to `p25`, one per route (`/p01` …). Each is
"Before pNN", the fixture, and "pNN end". A route `/p01-p03` is p01 with a
button "Open p03" that pushes p03. The probe app's `MaterialApp` sets no
locale, and its `supportedLocales` is the default, en-US, as the catalog
app's is. Built a second time with `--dart-define=APP_LOCALE=fr` (the web
only): `MaterialApp(locale: Locale('fr'), supportedLocales: [fr])`, with a
probe-only delegate that gives Material's English strings for French (the
SDK's default Material delegate supports English only).

| # | Fixture |
| --- | --- |
| p01 | `Text('Bonjour tout le monde')`, nothing marked |
| p02 | `Text(…, locale: Locale('fr'))` |
| p03 | `Localizations.override(locale: Locale('fr'))` round the text |
| p04 | `Semantics(localeForSubtree: Locale('fr'))` round the text |
| p05 | p04 with `container: true` |
| p06 | p05 with `Locale('fr', 'FR')` |
| p07 | p03 with `Locale('fr', 'FR')` |
| p08 | `Text.rich`: "She said ", `TextSpan(text: 'bonjour', locale: fr)`, " to me." |
| p09 | p08's sentence, nothing marked |
| p10 | `Semantics(attributedLabel:)` with a `LocaleStringAttribute` over "bonjour" |
| p11 | p08's sentence as three `Text`s in a `Wrap`, "bonjour" in `localeForSubtree` |
| p12 | `ListTile(title: Text.rich(TextSpan(text: 'Français', locale: fr)), onTap:)` |
| p13 | `Semantics(localeForSubtree: fr)` round `ListTile(title: Text('Français'), onTap:)` |
| p14 | `Localizations.override(locale: fr)` round p13's tile |
| p15 | `CupertinoListTile` titled as p12 |
| p16 | p13's tile, nothing marked |
| p17 | `Text.rich(TextSpan(text: …, locale: fr))`, the whole passage |
| p18 | `Text('日本語')`, nothing marked |
| p19 | `Semantics(localeForSubtree: Locale('ja'), container: true)` round p18 |
| p20 | `Semantics(localeForSubtree: Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'))` round "繁體中文" |
| p21 | p05 holding the passage and `localeForSubtree: Locale('en')` round "Hello everyone" |
| p22 | p08 with `Locale('fr', 'FR')` |
| p23 | p04 inside `Semantics(identifier:)` |
| p24 | p04 inside `MergeSemantics` and `Semantics(identifier:)`, as `TestId` does |
| p25 | p03 inside `Semantics(identifier:)` |

How each platform was looked at, and the raw output:

- Widget tests: `probe_test.dart.txt` under `flutter test`, as Android:
  each fixture's nodes from "Before" to "end", with each node's `locale`
  and its label's attributes (`flutter_test.txt`). A node's `locale` is
  printed with `Locale.toString()`, so `fr_FR` there is the framework's
  `Locale('fr', 'FR')`.
- Web: the release build in Playwright's Chromium and WebKit on macOS,
  with a throwaway spec (`probe_s16.spec.js.txt`, `probe_s16.config.js.txt`):
  the page's `lang`, each element's own `lang` and the nearest one above
  it, which of `en`, `en-US`, `fr`, `fr-FR`, `ja`, `zh`, `zh-Hant` the
  element matches with `Element.matches(':lang(x)')`, and in Chromium the
  accessibility tree over the DevTools protocol (`web.txt`). The same for a
  plain HTML page, `s16_html.html.txt`, served with the build (`web.txt`,
  `html` rows). Then p01, p03, p07, or p05 pushed by the address's hash,
  then the browser's Back, with no reload (`web_nav.txt`). The build with
  the app's locale French, Chromium (`web_app_fr.txt`).
- Android: Pixel emulator, Android 17, a throwaway instrumented test
  (`ProbeS16Test.kt.txt`, run by `probe_android.py.txt` under the device
  lock): every node of each fixture with its content description and the
  spans on it, `LocaleSpan` with its language tags; and p01, "Open" pressed
  with the click action, the screen opened, then Back
  (`android-tree.txt`). With TalkBack on, through `tool/talkback.py`'s own
  helper, which restores the device: TalkBack focus on each node of each
  fixture, five seconds each (`android-talkback.md`, as parsed by
  `talkback.parse_speech`, which keeps the words; `android-talkback-log.txt`,
  TalkBack's own lines for each fragment it spoke, with the `locale=` it
  logged, and the speech engine's voice data lines;
  `android-talkback-markers.txt`, the probe's own lines).
- iOS: iPhone 17 simulator, iOS 27.0, the simulator's languages
  `("en-US")`, a throwaway XCUITest (`ProbeS16UITests.swift.txt`, run by
  `ios_probe.sh.txt`): each fixture's elements from one `snapshot()`, and
  the whole attribute dictionary of one element of p01, p02, p03, and p08;
  a VoiceOver walk of each fixture with each utterance exactly as the
  service gave it (`debugDescription`, so a doubled space shows), and the
  properties and instance variables of the service's output object; and
  p01, "Open p03" (or p05) tapped, Back tapped, and a walk of p01 again
  (`ios.txt`).

## What it showed

- **The app's language reaches every platform.** With no locale set, the
  page's `lang` is `en-US` (the host page's own `<html lang="en">` is
  replaced), every Android node's description has a `LocaleSpan` en-US
  over its whole text, and TalkBack logged `locale=en_US` with every
  fragment of an unmarked text. With the app's locale French the page's
  `lang` is `fr` (`web_app_fr.txt`). On iOS the default language of every
  element is the app's locale (engine source read:
  `SemanticsObject.accessibilityLanguage` gives the node's locale or the
  bridge's application locale); XCUITest cannot read it.
- **`localeForSubtree` with a language alone marks a node on every
  platform** (p04, p05, p19, p21, p23): the web `lang="fr"` on the node's
  element, which matches `:lang(fr)` only; Android a `LocaleSpan` fr in
  place of the app's; TalkBack logged `locale=fr` for it. `container`
  makes no difference to what is exposed. A node inside it with
  `localeForSubtree` of its own (p21) has its own.
- **A part of a text marked with `TextSpan(locale:)`, `Text(locale:)`, or
  a `LocaleStringAttribute`** (p02, p08, p10, p12, p17, p22) is an
  attribute over its range of the label: on Android a `LocaleSpan` over
  the range beside the app's over the whole, which TalkBack spoke as one
  fragment per part, each with its own `locale=` ("She said " en_US,
  "bonjour" fr, " to me." en_US). On iOS VoiceOver read the label with a
  second space before and after the part ("She said  bonjour  to me."),
  where the unmarked p09 had one. **On the web nothing:** no `lang` on any
  element, in Chromium and WebKit (FL-020). `Text(locale:)` is documented
  as choosing a locale's glyphs; it passes the locale to the text's span
  (source read: `widgets/text.dart`), so it marks the whole text as
  `TextSpan(locale:)` does.
- **A locale with a country or a script is written with an underscore on
  the web** (p06, p07's passage, p20): `lang="fr_FR"`, `lang="zh_Hant"`,
  which match no `:lang()` in Chromium and WebKit; the plain HTML page's
  `lang="fr_FR"` and `lang="zh_Hant"` match none either, and its
  `lang="fr-FR"` and `lang="zh-Hant"` match their language (`web.txt`).
  Android and iOS are given the language tag, fr-FR (source read:
  `LocaleStringAttribute` and the node's locale go through
  `Locale.toLanguageTag()`; the web engine writes `Locale.toString()`).
- **`Localizations.override` sets the whole app's language, and nothing
  sets it back** (p03, p07, p14, p25). On the web the page's `lang` became
  `fr` (`fr-FR` for p07), so every text on the screen matched French, and
  after the browser's Back to p01 it stayed `fr` (`web_nav.txt`), in
  Chromium and WebKit. On Android every node of the screen had a
  `LocaleSpan` fr, and after Back p01's did too; TalkBack logged
  `locale=fr` for "Before p03" and for the Back button. p05 (with
  `localeForSubtree`) changed neither. Source read: `_LocalizationsState`
  calls `setApplicationLocale` whenever its locale is set, whether or not
  the `Localizations` is the app's. On iOS the walk after Back read the
  same words (`ios.txt`, nav rows); the probe's walks met no role word
  that would show the language.
- **A language set inside a node that merges its children is lost** (p24):
  the merged node has the app's language on every platform (Android en-US,
  no `lang` on the web, no locale in the widget tests). Source read:
  `SemanticsConfiguration.absorb` takes nothing of a child's locale.
  `localeForSubtree` round the merging node (p13) marks it.
- **VoiceOver on iOS speaks a button's role in its element's language.**
  p13 and p14, a tile inside `localeForSubtree` fr or
  `Localizations.override`, were read "Français Bouton"; p12, whose label
  alone carries the attribute, and p16, unmarked, "Français Button". A
  `CupertinoListTile` (p15) was read "Français" with no role.
- **What the captures cannot show.** TalkBack's log gives the locale it
  asked for with each fragment, not the voice the engine used. The
  emulator's speech engine had no French voice: it tried to download the
  fr-fr and fr-ca voices while the probe ran, and the download failed
  ("failed to download voice fr-ca", `android-talkback-log.txt`), so what
  was heard for a French fragment is not known. XCUITest's snapshot has no
  language attribute: the dictionary printed (`ios.txt`) is of the element
  of type other after "Before pNN", not of the text, and its keys are the
  ones `XCUIElementAttributes` declares, which name no language (the SDK
  header, read: `XCUIElementAttributes.h`). The VoiceOver
  service gives an utterance's words only (its output object has one
  property, `utterance`). Chromium's accessibility tree over the DevTools
  protocol holds no language for any node (`web.txt`, AX rows). No
  recording here shows a voice change.
- **The sentence split into three texts** (p11) is not read in its order:
  "She said" and "to me." are one node, and "bonjour" a node after it, on
  every platform. Not an example.
