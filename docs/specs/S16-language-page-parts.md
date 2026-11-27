# Spec: S16 Language of page and parts

Status: Draft 1 (2026-11-27), written with the build. Wave 3, structure and
order. Flutter pin: 3.47.5.

The language of the app and of the parts of it in another language.
Right-to-left text and its direction is S17; how a word is pronounced,
spelled out or given a reading, is S18 (3.1.6, AAA).

## 1. Rule

The app's language is given to assistive technology. A passage, a phrase,
or a control's name in another language is marked with that language, so
that a screen reader can speak it with a voice for it. Marking one part
changes the language of nothing else.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies | Applies, not verified in speech | Limitation |

Every good example is Flutter's own documented parameters,
`Semantics(localeForSubtree:)` and `TextSpan(locale:)`; none is a custom
solution (section 5).

- **Android, applies.** The app's language, a passage's, and a phrase's
  reach the node as `LocaleSpan`s, and TalkBack logged the locale of each
  fragment it spoke accordingly (section 7). What voice the speech engine
  used was not measured: the emulator's engine had no French voice.
- **iOS, applies; the voice not verified.** XCUITest cannot read an
  element's language or a label's language attribute. What was measured is
  what VoiceOver's words show: a button whose element is French is read
  with the French role word ("Français Bouton"), and a label with a
  phrase marked is read with a second space round the phrase. That a
  passage's element is French rests on the engine's source
  (`SemanticsObject.accessibilityLanguage`), not on a measurement.
- **Web, limitation.** A phrase inside a sentence cannot be marked: the
  web engine drops `TextSpan(locale:)` and every language attribute of a
  label, and no documented parameter gives a part of a text a `lang`
  ([FL-020](../flutter-limitations.md#fl-020)). So the web has no good
  example for R3, and `good-phrase` is good on Android and iOS only. The
  page's language (R1), a passage's (R2), and a control's (R5) work on the
  web, with a locale of a language alone; with a country the web writes
  `lang="fr_FR"`, which the browser takes as no language (FL-020).

This follows the owner's rule of 2026-11-23: where Flutter is measured not
to meet a requirement on a platform and no documented parameter fixes it,
that platform is a limitation and has no good example for that requirement.
The principal has not yet decided this technique's statuses.

What each good example gives, by platform (section 7):

| Example | Android | iOS | Web |
| --- | --- | --- | --- |
| `good-passage` | the passage's node fr (`LocaleSpan` fr), the line before it en-US | the passage's element fr by the engine's source; VoiceOver's words are the same as unmarked | `lang="fr"` on the passage's element |
| `good-phrase` | a `LocaleSpan` fr over the phrase; TalkBack speaks the sentence in three parts | a second space round the phrase in VoiceOver's utterance | **nothing**: one English element (FL-020) |
| `good-language-menu` | each tile a button with its language's `LocaleSpan` | each tile read with its role word in its language | each tile a button with its `lang` |

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [3.1.1 Language of Page](https://www.w3.org/TR/WCAG22/#language-of-page) | The default human language of the app can be programmatically determined |
| [3.1.2 Language of Parts](https://www.w3.org/TR/WCAG22/#language-of-parts) | The language of each passage or phrase can be programmatically determined, except proper names, technical terms, words of indeterminate language, and words that have become part of the vernacular of the immediately surrounding text |

For 3.1.1, an app is one "page" here: WCAG2ICT reads the criterion for
software as the default language of the software. `MaterialApp` gives the
platform its resolved locale (the framework's `Localizations`, source
read; measured on the web and Android). The catalog app sets no locale and
keeps the default `supportedLocales`, en-US, the language of all its text,
so every example screen meets 3.1.1 but `bad-override`, which changes it.
No example builds an app of its own: the app's `MaterialApp` is shared
(`lib/app/app.dart`), and a second `MaterialApp` inside an example would
set the language of the whole app (the mechanism of FL-360). The probe
built the probe app in French on the web only (`web_app_fr.txt`).

For 3.1.2, a French sentence and a language's name in that language are
neither a proper name nor a term taken into English. "Bon voyage" is
arguably in English dictionaries; it is marked here as the phrase of the
example, and no failure is claimed for a phrase left unmarked.

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | The app's language is set, so that everything not marked otherwise is in it | [iOS Language](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/Language.md) ("Language of Page"), [Android View Text Language Identification](https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/componenttypes/TextLanguageIdentification.md) (per-app language, 3.1.1), [H57](https://www.w3.org/WAI/WCAG22/Techniques/html/H57) |
| R2 | A passage or a section in another language is marked with it as a whole | iOS Language (the locale on the container view), [H58](https://www.w3.org/WAI/WCAG22/Techniques/html/H58), [MDN `lang`](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Global_attributes/lang) |
| R3 | A phrase inside a text in another language is marked over its own range, inside the text | Android View Text Language Identification (a `LocaleSpan` over the quotation, "especially in a mixed-language `TextView`"), iOS Language ("Language of Parts", an attributed string's language), H58 (`lang` on a `span`) |
| R4 | The language is a valid language tag | MDN `lang` (a BCP 47 tag), H57, H58 |
| R5 | A control named in another language, such as a language menu's entries, has that language | H58, iOS Language |
| R6 | Marking a part changes the language of nothing outside it | H58 (the `lang` of an element applies to it and its content) |

[Attributed Strings](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/AttributedStrings.md),
mapped to S16 by the inventory, is about styled text and its accessibility
label (1.1.1) and speech pitch, not language; it adds no requirement here.

Flutter references for the mechanisms used:

- [`Semantics.localeForSubtree`](https://api.flutter.dev/flutter/widgets/Semantics/localeForSubtree.html): "The [Locale] for widgets in the subtree." (`widgets/basic.dart`, read at the pin)
- [`TextSpan.locale`](https://api.flutter.dev/flutter/painting/TextSpan/locale.html): "The language of the text in this span and its span children. Setting the locale of this text span affects the way that assistive technologies, such as VoiceOver or TalkBack, pronounce the text." (`painting/text_span.dart`)
- [`WidgetsApp.supportedLocales`](https://api.flutter.dev/flutter/widgets/WidgetsApp/supportedLocales.html) and `locale`, through `MaterialApp`.
- [`Localizations.override`](https://api.flutter.dev/flutter/widgets/Localizations/Localizations.override.html), documented for "the (usually rare) situation where part of an app should be localized for a different locale": `bad-override` (FL-360).

Also in the SDK, and not used: `Text(locale:)`, documented as choosing a
locale's glyphs, which also passes the locale to the text's span (source
read), so it marks the text as `TextSpan(locale:)` does (probe p02);
`Semantics(attributedLabel:)` with a `LocaleStringAttribute` (p10), the
same attribute by hand, which replaces the text's own label. Neither adds
anything the two used do not.

Radix comparison bar: Radix has no primitive for language; the bar is
HTML's `lang` on the root element and on the part, which the probe's
plain HTML page measured (section 7).

### Material, Cupertino, and the widgets layer

A language is a property of text, set with the widgets layer's `Semantics`
and the painting layer's `TextSpan`; neither Material nor Cupertino has a
parameter of its own for it. `good-passage` and `good-phrase` are the
widgets layer; `good-language-menu` is Material's `ListTile`, a control
named in another language. There is no Cupertino example: a
`CupertinoListTile` with `onTap` takes no keyboard focus and is no button
on Android and iOS ([FL-400](../flutter-limitations.md#fl-400)), so a
Cupertino menu would show FL-400 and nothing more about language; marked
the same way it is read in its language (probe p15, with
`TextSpan(locale:)`; VoiceOver "Français", no role).

## 5. Examples

The passages are one English line, "The sign at the door reads:", and the
French passage "Bienvenue à tous nos visiteurs."; the phrase is "The guide
said bon voyage as we left." The menus are "Français", "Español", and
"Deutsch", and a line under them, "Chosen: none", which says in English
which language was chosen.

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-passage` | Widgets layer | A passage in French | `Semantics(localeForSubtree: Locale('fr'))` round the passage's `Text` | R1, R2, R4, R6 |
| `good-phrase` | Widgets layer | A phrase in French in an English sentence | `TextSpan(text: 'bon voyage', locale: Locale('fr'))` in a `Text.rich`; on Android and iOS only (FL-020) | R1, R3, R6 |
| `good-language-menu` | Material | A language menu, each language named in its own | `Semantics(localeForSubtree: Locale(code))` round each `ListTile` | R1, R4, R5, R6 |

No good example here is a custom solution. The register's rows are in
[custom-solutions.md](../custom-solutions.md#s16-language-of-page-and-parts).

### Bad

| Slug | Defect | Violates |
| --- | --- | --- |
| `bad-unmarked` | The passage with nothing marked: it is in the app's language, English | R2 |
| `bad-title-in-tile` | `good-language-menu` with `localeForSubtree` on each tile's title, inside the tile, which merges it: the language is lost ([FL-361](../flutter-limitations.md#fl-361)) | R5 |
| `bad-region-tag` | `good-passage` with `Locale('fr', 'FR')`: on the web `lang="fr_FR"`, which is no language tag and which the browser takes as no language ([FL-020](../flutter-limitations.md#fl-020)) | R4 |
| `bad-override` | The passage inside `Localizations.override(locale: Locale('fr'))`: the passage is French, and so is the whole app, which stays French after the screen closes ([FL-360](../flutter-limitations.md#fl-360)) | R1, R6 |

What each fails, by platform, as the criterion is written (section 7 has
the measurements):

| Example | Android | iOS | Web |
| --- | --- | --- | --- |
| `bad-unmarked` | 3.1.2: the passage's node en-US | 3.1.2: nothing marks the passage (the tree and the source; VoiceOver's words are the same as `good-passage`'s) | 3.1.2: the passage's element in the page's `en-US` |
| `bad-title-in-tile` | 3.1.2: each tile's node en-US | 3.1.2: each tile read "Button", in English | 3.1.2: no `lang` on any tile |
| `bad-region-tag` | none: the node fr-FR | none: fr-FR, by the source | 3.1.2: `lang="fr_FR"` matches no `:lang()` |
| `bad-override` | 3.1.1: every node of the screen fr, and after Back the technique's page fr | 3.1.1 by the engine's source; not measured | 3.1.1: the page's `lang="fr"`, on the screen and after Back |

`bad-region-tag` on Android and iOS is not called a failure: its one
defect is the web's, as S08's `bad-tile-in-item` is.

`bad-override` is a framework defect: its author used the widget the
documentation gives for a part of an app in another locale. It changes the
app it runs in, the catalog app: once it has been opened, the catalog is
French until the app is started again. Every test opens each example in a
fresh start (a page load, a new Android activity, a new iOS launch), and
the web VoiceOver spec gives each example a page of its own. A user of the
catalog who opens it is left with a French catalog; that is the defect,
shown where it happens, and it is the principal's call whether the
example stays (section 7, "Decisions needed").

### Not built

- **A phrase marked on the web.** No documented parameter gives a part of
  a text a `lang` (FL-020). Splitting the sentence into texts of their
  own, the phrase in `localeForSubtree` (probe p11), puts the phrase after
  the rest of the sentence, on every platform: "She said to me." then
  "bonjour". It is not a workaround, and is not built.
- **An app in another language.** The catalog's `MaterialApp` is shared;
  the probe measured a French app on the web (`web_app_fr.txt`).
- **A Cupertino example** (section 4).
- **A localized subtree**, translated widgets in another language with
  their language: `Localizations.override` is the widget for it, and it
  changes the app's language (FL-360).

`TestId` is a `MergeSemantics`: inside it `localeForSubtree` is lost
(FL-361, probe p24). So `good-language-menu` puts `localeForSubtree`
round each tile's `TestId`, and the texts are found by their names.

## 6. Assertions by layer

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Good, in light and dark: the four guidelines; `good-language-menu`'s text contrast with keyboard focus on each tile, and its focus tint under 3:1 and over 1:1 against the page ([FL-434](../flutter-limitations.md#fl-434), as S08's tiles; written to fail if it reaches 3:1). Every example: at 200% text on a 320 by 640 screen, no layout overflow, no text that hits its line limit, none taller than its box, none past the screen's edge. The example's named nodes after the "Example" heading, in traversal order, each with its locale and its label's language attributes: `good-passage` the lead with no locale and the passage `fr`; `good-phrase` one node with a `fr` attribute over "bon voyage" alone; `good-language-menu` three buttons, each with its language, and the Chosen line with none; `bad-unmarked` no locale and no attribute; `bad-title-in-tile` three buttons with no locale; `bad-region-tag` the passage `fr-FR`; `bad-override` the passage `fr`. For each tile of both menus: a tap and the tap action each choose it; Tab to it and Enter, and Space, each choose it (the positive control for `bad-title-in-tile`). The app's language is sent to the engine, which widget tests do not run, so it and FL-360 are not seen here |
| L3 web | The page's `lang` is `en-US` on every example but `bad-override`, the screen's "Example" heading in it, and the host page's own `lang="en"`. Each text's `lang`, every `lang` from it to the root, and which of `en`, `en-US`, `fr`, `fr-FR`, `es`, `de` it matches by `:lang()`: `good-passage` the passage `fr` only and the lead `en-US`, one element with a `lang` of its own; `good-phrase` one English element, no `lang` in the page, no element for the phrase (FL-020, written to fail when the phrase gets one); `good-language-menu` each tile a button named by its language with its `lang`, the Chosen line `en-US`; `bad-unmarked` and `bad-title-in-tile` everything `en-US`, no `lang` in the page; `bad-region-tag` `lang="fr_FR"` matching nothing, with the control of a plain element with `lang="fr-FR"` matching `fr` and `fr-FR`; `bad-override` the page's `lang="fr"` and every text French, and after the app's Back the technique's page `fr`, with the control that `good-passage`'s Back leaves it `en-US` (the witness that Back took effect: the technique's "Good examples" heading shown and no "Example" heading). For each tile of both menus, a click, and Tab then Enter, and then Space, each key sent once from a fresh load, choose it. Each screen shows the title and lines the VoiceOver judge expects; the judge's regression cases (section 7) |
| L3 Android | The `LocaleSpan`s of each node's description, sorted: the screen's title and "Example" heading `en-US` over their whole text on every example but `bad-override`; `good-passage` the lead `en-US` and the passage `fr`; `good-phrase` one node `en-US` over the whole and `fr` over the phrase; `good-language-menu` three `Button`s, each its language over its name, and the Chosen line `en-US`; `bad-unmarked` both `en-US`; `bad-title-in-tile` three `Button`s `en-US`; `bad-region-tag` the passage `fr-FR`; `bad-override` the title, the heading, the lead and the passage `fr`, and after Back the technique's "Good examples" heading `fr`, with the control that it is `en-US` after Back from `good-passage`. For each tile of both menus, from a fresh launch each: `ACTION_CLICK`, a tap at its centre, and Tab then Enter choose it. Run once at CI's 320 by 640 at 160 dpi as well |
| L3 iOS | The labels of the example's elements after the "Example" heading, in order, and each tile a button with its label; a tap on each tile, and Tabs then Enter, and then Space, each key sent once from a fresh launch, choose it. XCUITest cannot read a language, so no defect is seen in the tree; the VoiceOver walk is where it is judged |
| L4 TalkBack | Focus moved to each text of each example and to each tile, in order; every row a whole-utterance form, exactly its fragments in order (`== A / B`, `tool/talkback.py`): each text its words, `good-phrase` the sentence in three fragments, "The guide said / bon voyage / as we left.", split where the language changes, each tile its name and "Button" (a usage hint allowed once at the end). The locale TalkBack logs with each fragment is not read by the tool, so the rows judge words: the split of `good-phrase` is the only one that shows a language; the passages' languages are judged by the Android tree test. Each walk is judged whole (`walk_strictly`): a wrong reading fails for good |
| L4 VoiceOver iOS | Every utterance from the top of the screen to its end (S16Walk, C03's walk keeping each raw utterance), judged whole: the screen's own stops (Back, the title, the description, the defect, the "Example" heading), which tie the walk to this example, then exactly the example's stops, each with white space made one space; and for some stops the raw utterance exactly: `good-phrase`'s with a second space before and after the phrase, and the passages' leads and passages with single spaces. `good-language-menu`'s tiles with their role word in their language; `bad-title-in-tile`'s with "Button"; `bad-override`'s screen stops with French role words. Every expected utterance is under the service's 64 characters, and a test refuses a longer one; made-up walks test the judge |
| L4 VoiceOver web | Not recorded yet. The walk and the judge are S08's (`web_tests/vo/s16_vo_walks.js`): the whole screen in order, every stop judged, an empty stop a failed capture walked again (at most three walks, each logged), a wrong reading failing for good, no runner retries; the help-message rule is tested only on made-up walks. The expected stops are predictions from the page's elements; the words are the same whatever language a stop is in |

## 7. What the build found (Flutter 3.47.5)

The probe that came first is in
[evidence/probes/s16](../evidence/probes/s16/README.md): 25 fixtures on
every platform, with a plain HTML control page on the web.

- **The app's language reaches every platform**, from `MaterialApp`'s
  resolved locale, with no parameter set (probe p01): the page's
  `lang="en-US"`, replacing the host page's `lang="en"`; on Android a
  `LocaleSpan` en-US over every node's text, and TalkBack logged
  `locale=en_US` with the text of every unmarked node (its own words, such
  as "1 of 5", with `locale=null`). A French app (the probe's second
  build, measured on the web only) gave the page `lang="fr"`. On iOS by
  the engine's source only.
- **`localeForSubtree` with a language alone marks a node** on the web
  (`lang="fr"`, matching `:lang(fr)` only) and on Android (a `LocaleSpan`
  fr in place of the app's, and TalkBack logged `locale=fr`) (p04, p05,
  p19, p21, p23; `good-passage`). On iOS by the engine's source; what was
  measured is VoiceOver reading a button inside it with the French role
  word (p13).
- **A part's language** (p02, p08, p10, p12, p17, p22; `good-phrase`)
  reaches Android as a `LocaleSpan` over the part, and TalkBack spoke the
  text in one fragment per part, each logged with its locale. On iOS,
  VoiceOver's utterance had a second space before and after the part. On
  the web nothing reaches the page (FL-020, extended and now Confirmed).
- **A locale with a country or a script** (p06, p07, p20;
  `bad-region-tag`) is written `fr_FR`, `zh_Hant` on the web, which match
  no `:lang()` in Chromium and WebKit, as a plain HTML element with
  `lang="fr_FR"` does not; `lang="fr-FR"` on one matches `fr` and `fr-FR`.
  Android and iOS are given the tag with a hyphen (source read).
- **`Localizations.override` sets the app's language** (p03, p07, p14,
  p25; `bad-override`; [FL-360](../flutter-limitations.md#fl-360), new).
- **A language set inside a merging node is lost** (p24;
  `bad-title-in-tile`; [FL-361](../flutter-limitations.md#fl-361), new).
- **VoiceOver on iOS speaks a role word in its element's language**: a
  tile inside `localeForSubtree` fr "Français Bouton", the same tile
  unmarked "Français Button" (p13, p16). This is the one measurement on
  iOS that shows an element's language.
- **What no capture shows: the voice.** TalkBack logged the locale it
  asked for; the emulator's speech engine had no French voice, tried to
  download one during the probe, and failed (`android-talkback-log.txt`).
  VoiceOver's service gives words. Chromium's accessibility tree over the
  DevTools protocol holds no language. So "reaches the screen reader"
  here means the span, the attribute, the `lang`, the logged locale, or
  the role word, and never that a voice changed.

What the tests skip or cannot see, and what each gives up:

- The TalkBack rows judge words. `tool/talkback.py` reads each fragment's
  text and drops the `locale=` TalkBack logs with it, so a passage read
  with an English locale and one read with a French one give the same
  row: the TalkBack layer cannot fail `bad-unmarked` or pass
  `good-passage` on their language. The Android tree test judges the
  spans. Reading the logged locale needs a change to the shared tool,
  proposed and not made.
- The iOS layers cannot read a language. The VoiceOver walk judges the
  role words and the doubled spaces that show one, and nothing shows a
  passage's language: `good-passage`, `bad-unmarked`, `bad-region-tag`,
  and `bad-override`'s content are read alike there.
- The web tree test reads `lang` attributes and `:lang()` matching, the
  browser's own reading of them, and not what a screen reader does with
  them; Chromium's accessibility tree has no language to read.
- The Android tree test reads the example after scrolling the screen to
  its end; a node scrolled away above would be missed. Every example fits
  CI's screen below the heading (checked at 320 by 640).

**Decisions needed.** Listed in the engineer's report to the principal.

**Not done yet.** The web VoiceOver recording. The voice on any platform.
What VoiceOver does with `lang="fr_FR"` or with a page whose `lang` is
wrong. An app in another language as an example. Right-to-left languages
(S17).
