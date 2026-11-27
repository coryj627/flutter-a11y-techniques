# Spec: S06 Screen and page titles

Status: Draft 1 (2026-11-26), written with the build. Wave 3, structure
and order. Flutter pin: 3.47.5 (`.fvmrc`).

A screen's title: the words that say what a screen is for, shown at its
top and given to assistive technology, on the web as the document's title
(the browser tab, and the name of the page a screen reader reads), on
Android as the pane title of the app's view, and on iOS as the screen's
first heading. The source material is Flutter's own: Material's `AppBar`
and its `title`, Cupertino's `CupertinoNavigationBar` and its `middle`,
the widgets layer's `Title` (which `MaterialApp.title` and
`onGenerateTitle` also build), `Semantics(namesRoute:)`, and the routes
(`MaterialPageRoute`, `CupertinoPageRoute`), whose pages scope a route
(`scopesRoute`). By the owner's rule of 2026-11-21 every example is the
framework's widget through its documented parameters; where it cannot
meet a requirement, that is a limitation entry and nothing is built to
fill it.

Not this technique: headings and their levels (S05; the screen title as
level 1 heading is taken from there), where focus goes when a screen
opens (I03), and what the web's announcer says when a screen opens, which
[FL-010](../flutter-limitations.md#fl-010) covers. A dialog's title is
the dialog techniques'. The issue's note that named-route landmarks on the
web need Flutter 3.50 is not tested: the pin is 3.47.5, and on it a route
on the web is a generic element with no role (section 7).

## 1. Rule

Every screen has a title that says what the screen is for, shown at its
top; assistive technology is given that title for the screen that is
shown, on each platform the way the platform takes it; and two screens
do not share one title where they differ.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies | Applies | Limitation (FL-300) |

By the owner's rule of 2026-11-23: where Flutter is measured not to meet
a requirement on a platform and no documented parameter fixes it, that
platform is a limitation, and there is no good example for it there.

- **Web: a limitation, with no workaround**
  ([FL-300](../flutter-limitations.md#fl-300)). `Title` sets the
  document's title when it is first built and when its own `title`
  changes, and at no other time (source read: `widgets/title.dart`). When
  a screen closes, by the app's Back or the browser's, nothing gives the
  screen shown again its title back: the document keeps the closed
  screen's (measured on every probe fixture with a `Title` and on every
  example, `docs/evidence/probes/s06/web.txt` and the web tree tests). So
  R4 below is not met on the web, by any example. No documented parameter
  of `Title`, `MaterialApp`, or the routes sets it on a pop; a
  `NavigatorObserver` that called `SystemChrome` would be a mechanism of
  the project's own. The good examples are the closest the framework
  comes on the web: right while a screen is open, wrong after Back.
  What the app shows of this is the shared app's, as for every
  technique with a limitation: the technique screen's "Platforms" line,
  "Web: Flutter limitation. Title sets the document title when a screen
  opens, … (limitation FL-300). There is no workaround."
  (`lib/app/screens.dart`, lines 65 to 67 and `_describe`, line 96); the
  example screens and the technique screen's list still say "Good
  example" and "Good examples", with no platform note, as they do for
  I08's good examples, whose web is a limitation too
  (`docs/evidence/probes/s06/web_status.txt`).
- **iOS: applies** (the principal's decision, section 8). The title is
  the screen's level 1 heading, and VoiceOver reads it with "Heading"
  when its cursor reaches it (R1, R2, R3). When a screen opens, the title
  is not heard: VoiceOver's cursor goes to the screen's first control,
  Back ([FL-302](../flutter-limitations.md#fl-302)). Material's `AppBar`
  does not name the route on iOS (source read: `material/app_bar.dart`),
  and the probe heard no title where a node did name it (p07, p08). R5,
  the title said when a screen opens, is not a requirement on iOS: 2.4.2
  does not ask for it, and its only source is the Android Compose
  repository. `good-cupertino` has a framework defect on iOS besides:
  its Back button's tap target has no name
  ([FL-303](../flutter-limitations.md#fl-303)).
- **Android: applies.** `AppBar`'s title is the pane title of the app's
  view, and TalkBack says it when the screen opens and closes (section 7).
  `CupertinoNavigationBar`'s middle names no route
  ([FL-301](../flutter-limitations.md#fl-301)): the documented
  `Semantics(namesRoute: true)` round it does (`good-cupertino`).

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [2.4.2 Page Titled](https://www.w3.org/TR/WCAG22/#page-titled) | A screen's title, and the document's title on the web |

2.4.2, as written: "Web pages have titles that describe topic or
purpose." Its glossary's web page is "a non-embedded resource obtained
from a single URI using HTTP plus any other resources that are used in the
rendering or intended to be rendered together with it by a user agent",
and its second example is a web mail program that "lives entirely at" one
address, with an inbox, contacts, and a calendar that "do not change the
URI of the page as a whole".
[Understanding 2.4.2](https://www.w3.org/WAI/WCAG22/Understanding/page-titled.html)
says that "the name of the document or web application would be
sufficient to describe the purpose of the page", and that in a single
page application, "where various distinct pages/views are all nominally
served from the same URI", "the title of the page should also be changed
dynamically to reflect the content or topic of the current view". Its
sufficient technique is G88 with H25 (the `title` element), and its
failure F25, "the title of a web page not identifying the contents".

So, as written, a Flutter web app can be one web page (one address; this
app's routes are in the address's fragment, and the examples' screens do
not change the address at all), and 2.4.2 needs a title that describes
it, for which the app's name can do. This technique reads each screen of
an app as a page, as both reference repositories do for native apps (the
iOS one: "Page titles must describe the purpose of the page and be unique
for each page in the app"; the Android Compose one: "All applications
screens require titles") and as Understanding's "should" asks for each
view. Its 2.4.2 verdicts on a screen, below, hold only under that
reading; under the criterion as written, only `bad-vague-title` on the
web, whose document title "Details" does not describe the app, would be
in question, and this spec makes no claim on it.

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | Every screen has a title, visible at its top | [Android Compose: Screen and Pane Titles](https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/content/ScreenAndPaneTitles.md) ("The screen title should be both visible and announced by screen readers"), [iOS: Page Titles](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/PageTitles.md) ("Use `.navigationTitle` to create a title for each page") |
| R2 | The title describes the screen's topic or purpose, and two screens do not share one where that is reasonable | Android Compose ("must be descriptive", "To the extent reasonable, screen titles should also be unique"), iOS ("describe the purpose of the page and be unique for each page"), [Understanding 2.4.2](https://www.w3.org/WAI/WCAG22/Understanding/page-titled.html), [F25](https://www.w3.org/WAI/WCAG22/Techniques/failures/F25) |
| R3 | The title is the screen's heading | iOS ("VoiceOver will speak the page title as a Heading"), Android Compose (titles as headings, "suggested"); S05 (level 1) |
| R4 | On the web, the document's title is the title of the screen shown, and changes when the screen does | [MDN: title](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/title), Understanding 2.4.2 ("should also be changed dynamically to reflect the content or topic of the current view"), [G88](https://www.w3.org/WAI/WCAG22/Techniques/general/G88) |
| R5 | On Android, when a screen opens, the screen reader is told its title | Android Compose (the title "announced by screen readers"; "One good way to provide screen reader announcement of screen titles is using the `Modifier.semantics` `paneTitle` property") |

The reference repositories: iOS has Page Titles, read above, with a good
page (`.navigationTitle("About the Company")`) and a bad page with no
title; most of its text is on long titles that the bar cuts short, and it
recommends an in-page heading for a long one. Android Compose has Screen
and Pane Titles, read above: a `TopAppBar` title marked as a heading, and
`Modifier.semantics { paneTitle = … }` on the screen's `Scaffold`, and the
same for "significant panes" (a navigation drawer, the panes of a list
and detail layout). Android View has no entry, and APG has no pattern.

HTML's comparison is the `title` element: one per document, in its head,
which browsers show in the tab and screen readers read as the page's name
(MDN). In a single-page application the page changes it with
`document.title`, which is what Flutter's web engine does for `Title`
(source read: `platform_dispatcher.dart`,
`SystemChrome.setApplicationSwitcherDescription`).

Flutter references for the mechanisms used:

- [`AppBar.title`](https://api.flutter.dev/flutter/material/AppBar/title.html);
  `AppBar` marks its title as a header and, on Android, Fuchsia, Linux,
  and Windows, as the route's name (`excludeHeaderSemantics`: "the title
  will be used as `namesRoute` for Android, Fuchsia, Linux, and Windows")
- [`CupertinoNavigationBar.middle`](https://api.flutter.dev/flutter/cupertino/CupertinoNavigationBar/middle.html)
- [`Title`](https://api.flutter.dev/flutter/widgets/Title-class.html),
  and `MaterialApp.title`, `onGenerateTitle`, which build one
- [`SemanticsProperties.namesRoute`](https://api.flutter.dev/flutter/semantics/SemanticsProperties/namesRoute.html),
  [`Semantics.headingLevel`](https://api.flutter.dev/flutter/widgets/Semantics/headingLevel.html)

## 5. Examples

Every example is a button, "Open orders", that opens a screen of its own,
a route pushed on the app's Navigator, as an app moves from one screen to
the next. The screen it opens has the text "Three orders in the last 30
days." Its title, where it has one, is "Orders". The example's own screen,
under it, is the app's: an `AppBar` titled with the example's title, and a
`Title` "<example title> - Flutter A11Y Techniques".

"Orders" is short on purpose: in the widget tests, at 200% text on a 320
wide screen, an `AppBar` cut "Your orders" and "Order history" short with
an ellipsis (`docs/evidence/probes/s06/flutter_test_cut.txt`; the test font
has square glyphs, wider than a real one, so this is not a device
measurement). The iOS source has the same problem with long titles.

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-material` | Material | A Material screen titled "Orders" | `MaterialPageRoute`; `Scaffold(appBar: AppBar(title: Semantics(headingLevel: 1, child: Text('Orders'))))`; `Title(title: 'Orders')` round it | R1 to R5 |
| `good-cupertino` | Cupertino | A Cupertino screen titled "Orders", with Cupertino's own Back button, which has a framework defect (FL-303, below) | `CupertinoPageRoute`; `CupertinoPageScaffold(navigationBar: CupertinoNavigationBar(middle: Semantics(namesRoute: true, headingLevel: 1, child: Text('Orders'))))`; `Title(title: 'Orders')` round it | R1 to R5 |

Neither is a custom solution: Flutter's widgets through their documented
parameters, with `namesRoute` and `headingLevel` applied as their
documentation describes ([custom-solutions.md](../custom-solutions.md#s06-screen-and-page-titles),
as S05 `good-cupertino` fills FL-014 with `headingLevel`).

What each meets and does not, by platform, under the reading of section 3:

| Example | Android | iOS | Web |
| --- | --- | --- | --- |
| `good-material` | R1 to R5: pane title "Orders"; a heading; TalkBack said "Orders" as it opened | R1 to R3: "Orders Heading" when reached; the title not heard as the screen opens (FL-302), which R5 does not ask of iOS | R1 to R3; R4 while it is open, not after Back (FL-300), so not good on the web |
| `good-cupertino` | As `good-material`, with `namesRoute` (FL-301). Its Back button (FL-303): TalkBack read the node named "Back", a `Button` with no click action and no "Double-tap to activate"; an unnamed clickable node is there too; not shown to fail 4.1.2 | As `good-material`, and a framework defect: as the screen opens VoiceOver lands on Back's unnamed tap target and says only "Button", which fails 4.1.2's name as written (FL-303) | As `good-material`, so not good on the web; its route is described by its title with `navigator.platform` as a Mac and as Linux (Playwright's Chromium on macOS); Back is two button elements, both named "Back" in Chromium's tree, read by VoiceOver as "Back button" in Chromium and WebKit as the screen opened (Chromium adding "group"): not a 4.1.2 failure (FL-303) |

`good-cupertino` is the framework's bar through its documented
parameters, and it is not free of defects: its Back button, which the
bar builds, fails 4.1.2 on iOS (FL-303). Nothing in the SDK names that
tap target, and the example does not replace the bar's button with one
of its own (the owner's rule).

No widgets-layer example: the widgets layer has no bar to hold a title.
A title there would be a heading and a `Semantics(namesRoute: true)`
assembled by hand, which `good-cupertino` already shows on a framework
bar.

### Bad

| Slug | Variant | Defect | Violates | Fails |
| --- | --- | --- | --- | --- |
| `bad-no-title` | Material | The screen has no title: an `AppBar` with none, no `Title`, and "Orders" drawn as large text in the page, plain text. No platform is given a title: Android's pane title is a space, the document keeps the example screen's title, and no screen reader finds a heading | R1, R3, R4, R5 | 2.4.2 on all three, under the reading of section 3 |
| `bad-vague-title` | Material | The title is "Details", which does not say what the screen is about; everything else as `good-material` | R2 | 2.4.2 on all three, under the reading |
| `bad-no-document-title` | Material | No `Title`: the `AppBar`'s title is right, and the browser's document keeps the title of the screen before | R4 | 2.4.2 on the web, under the reading; none on Android and iOS, where `Title` gives assistive technology nothing (section 7) |
| `bad-cupertino-unnamed` | Cupertino | `CupertinoNavigationBar(middle:)` as it comes: the bar names no route, so on Android the pane title is a space and TalkBack is not told the screen's name (FL-301); the title is still a heading, and the document title is right | R5 | none as 2.4.2 is written: the screen has a title, shown, and a heading. R5 is the Android source's, not WCAG's |

- `bad-cupertino-unnamed` names no criterion failure. Its defect is the
  framework's, as C26's spinners' are, and it is a bad example by the
  technique guide's rule that a mechanism that does not work where it is
  checked "is a bad example with a limitation entry". Its assertions are
  written to fail if Flutter starts to name the route.
- `bad-no-document-title` on Android and iOS: `Title` sets the label of
  the app's task in Android's Recents (source read:
  `PlatformPlugin.java`, `setTaskDescription`) and nothing on iOS (source
  read: `FlutterPlatformPlugin.mm`, "No counterpart on iOS"). Neither is
  what TalkBack or VoiceOver reads for a screen, so the example has no
  defect a screen reader user meets there.

Not built:

- **A screen whose title changes inside one route** (a `NavigationBar`,
  the probe's p10). On the web `Title` follows it; on Android the pane
  title stays the first destination's
  ([FL-305](../flutter-limitations.md#fl-305)); on iOS VoiceOver said
  nothing of it (probe round 2). A bottom navigation bar is a navigation
  technique's.
- **A drawer, a pane** (p13). `Drawer` scopes and names a route of its
  own, "Navigation menu" or its `semanticLabel`, in the widget tests as
  Android and as iOS (source read: `material/drawer.dart`), which is the
  Compose source's pane title for a drawer. On the Android emulator the
  pane title became "p13 Folders" and TalkBack said it; on iOS VoiceOver
  went to the drawer's first item, and "p13 Folders" was not heard; on
  the web the drawer is no dialog and no region (`web.txt`). The
  navigation techniques' subject.
- **`MaterialApp.title` alone** (p12): it builds a `Title` for the whole
  app, which gives the document the app's name until a screen's `Title`
  replaces it (`web.txt`, p12 launcher "Probe app"); every example's
  screen sits in this app, whose own `MaterialApp.title` is "Flutter A11Y
  Techniques". `onGenerateTitle` is the same widget (source read:
  `widgets/app.dart`).
- **A route name** (p11, `Navigator.pushNamed('/p11/orders')`): it changes
  the address on the web and nothing a screen reader is given: no
  document title, no pane title, no label (`web.txt`, `android-tree.txt`).
- **`excludeHeaderSemantics: true`** (p04): the title is then neither a
  header nor the route's name; on Android the pane title is a space. The
  same defect as `bad-no-title` for a screen reader, with the title
  visible; not a separate example.

## 6. Assertions by layer

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Every example, good and bad, in light and dark: the four guidelines on the example screen and on the screen opened, and text contrast with keyboard focus on the button (the labelled tap target guideline skipped on the two Cupertino screens, whose own Back fails it, FL-303, asserted below); at 200% text on 320 by 640, nothing overflows and no text is cut short, the example's own text and the whole opened screen. For each example, once its screen is open: the name the platform engines would read for the last route (the first non-empty label of a node with `namesRoute`, depth first, the way `AccessibilityBridge.java` and `SemanticsObject.mm` read it): "Orders" for the good ones and `bad-no-document-title`, "Details" for `bad-vague-title`, none for `bad-no-title` and `bad-cupertino-unnamed`; every document title the app sent, through `SystemChrome.setApplicationSwitcherDescription`: "Orders", "Details", or nothing for `bad-no-title` and `bad-no-document-title` (with `good-material`'s sent as the positive control in the same test); and the headings: "Orders" level 1, "Details" level 1, none for `bad-no-title`. For every example, Back sends no document title at all, and the route shown is the example screen's, named by its title (FL-300). Cupertino's Back: one tappable node with no name and one node named Back that takes no tap; Material's, one node, named, that takes the tap, as the control. As iOS: `good-material`'s route has no name (FL-302) and `good-cupertino`'s is "Orders". Tab reaches the button, and Enter and Space each open the screen. Tests run as Android, except where they say iOS |
| L3 web | For each example: the document title is the example screen's when it opens by its address, the opened screen's once it is open ("Orders", "Details", or the example screen's for `bad-no-title` and `bad-no-document-title`), and still the opened screen's after the app's Back (FL-300), and after the browser's Back for `good-material`; the name of Chromium's root web area is the document title each time. The opened screen's headings: one, level 1, "Orders" or "Details", and none for `bad-no-title`, where "Orders" is plain text; the example screen is out of the tree while covered. The route's element, with `navigator.platform` set before load to "MacIntel" and to "Linux x86_64" (CI's browser is on Linux): `good-material` described by "Orders" as Linux and by nothing as a Mac, `good-cupertino` by "Orders" as both, `bad-cupertino-unnamed` by nothing as both; a described route is a generic element with no name and no role, and no route is a dialog or a region. Tab reaches the button, and Enter and Space each open the screen, with DOM focus then on its Back; Tab and Enter on Back close it, focus goes back to the button, and the title stays. The VoiceOver spec's stops above each heading are on each screen; the walk judge on made-up walks |
| L3 Android | For each example: the button a `Button` named "Open orders"; the FlutterView's pane title the example's title, then once the screen is open "Orders", "Details", or a single space for `bad-no-title` and `bad-cupertino-unnamed`, then the example's title again after the system Back; the app window's title "Flutter A11Y Techniques" throughout. The opened screen's headings: "Orders" or "Details", none for `bad-no-title`. Cupertino's Back: the node named Back takes no click, and a clickable node with no name is there; Material's Back, named and clickable, the control. Tab reaches the button and Enter opens the screen, for both good examples |
| L3 iOS | For each example: the button labelled "Open orders"; a tap opens the screen, whose title is a text element and which has no navigation bar; the example screen's button is out of the tree while it is covered; Back closes it. Cupertino's Back: two buttons, one labelled Back and one with no label; Material's, one, labelled Back |
| L4 TalkBack | Every row judged by whole utterances, not by words found in the row (`==` and `^=` in `tool/talkback.py`, `said`): each button exactly "Open orders", "Button". After the click action, eight seconds, exactly the pane title, "Back", "Button" (the usage hint at the end allowed): the title "Orders" for the good examples and `bad-no-document-title`, "Details" for `bad-vague-title`, and an utterance of nothing but white space, the pane title of one space, for `bad-no-title` and `bad-cupertino-unnamed`; any other title, or any utterance more, is a wrong reading. After the system Back, eight seconds: the first utterance exactly the example screen's title; what follows, where TalkBack's focus went, is recorded and not judged, because it varied between recordings (to "Open orders" in the first and third recordings; for `good-cupertino` to the app's Back in the second, `docs/evidence/probes/s06/talkback-round2-fail.md.txt`). Judged whole (`walk_strictly`; S06 is in `STRICT`). The judge's cases, among them the false passes the word match allowed (late "Open orders" in place of "Orders"; a title on `bad-no-title`; a second title), are in `tool/test_talkback.py`, `S06WholeUtterances` |
| L4 VoiceOver iOS | For each example, the cursor walked to the button and the button pressed with a tap at its place: every `currentSpeech()` read for six seconds judged raw (`S06Landing.judge`): the button's utterance, then only the landing, "Back Button" (Material) or "Button" (Cupertino, FL-303), and never back; then the screen to its end as a whole list ("Orders Heading" or "Details Heading", "Orders" for `bad-no-title`, and the text; the Cupertino screens "Back Button" first); then Back pressed the same way, and the reads judged: the text's utterance, then "Open orders Button" |
| L4 VoiceOver web | Each example screen walked from Back and judged against the whole screen in order; Enter on the button and six seconds of phrases, recorded and not judged, except that something must be heard; the opened screen walked from its Back and judged: "heading level 1 Orders" (or "Details", or "Orders" as plain text for `bad-no-title`) and the text. No runner retries. Recorded twice, by the principal: the first failed on a start of VoiceOver, the second passed (section 7) |

## 7. What the build found (Flutter 3.47.5)

The probe (`docs/evidence/probes/s06/`, its README) ran thirteen fixtures
on the web, Android, and iOS before the examples were written. What each
platform gives, from the probe's raw files, and where the examples'
tests and transcripts confirm it:

| | Web (Chromium on macOS) | Android 17 | iOS 27.0 |
| --- | --- | --- | --- |
| What holds a screen's title | `document.title`, from `Title`; the name of Chromium's root web area follows it | the FlutterView's pane title, the route's name; the window's title is the app's label throughout | nothing but the title's own text element; no navigation bar |
| `AppBar(title:)` | a heading (level 2 without `headingLevel`, FL-004); no route name with `navigator.platform` "MacIntel", a route described by it with "Linux x86_64" set before load, both in Playwright's Chromium on macOS (FL-304) | the pane title; a heading only with `headingLevel` (FL-005) | no route name (FL-302); static text, read as a heading only with `headingLevel` (FL-003) |
| `CupertinoNavigationBar(middle:)` | a heading; no route name with either `navigator.platform` tried (FL-301) | pane title a single space (FL-301) | as `AppBar` |
| `Semantics(namesRoute: true)` round the title | a route described by it, with `navigator.platform` "MacIntel" too | the pane title | no change heard (FL-302) |
| `Title` | sets `document.title` when its screen opens; nothing when it closes (FL-300) | the task label in Recents (source read; not measured) | nothing (source read) |
| When a screen opens | DOM focus on its first control, Back; the web's announcer: FL-010 | TalkBack says the pane title, then the first control: "Orders", "Back", "Button"; an empty utterance where there is no name | VoiceOver's cursor on the first control: "Back Button", or "Button" on a Cupertino screen (FL-303); the title not heard (FL-302) |
| When a screen closes | the closed screen's title stays (FL-300); DOM focus back on the button that opened it | TalkBack says the pane title of the screen under it, then, in the probe and the first recording, the button that opened it (in the second, for `good-cupertino`, the app's Back) | the cursor back on the button that opened it |
| A screen that changes inside one route (p10) | the title follows | the pane title stays the first one's (FL-305); TalkBack said "selected" | nothing new heard; the title read one move on |

What the examples' tests showed:

- **The web.** Every example's screen gives the document its title while
  it is open, or none (`bad-no-title`, `bad-no-document-title`, which keep
  the example screen's); after the app's Back, and the browser's for
  `good-material`, the document keeps the closed screen's title
  (`web_tests/s06_screen_titles.spec.js`). The app's own screens do the
  same: the catalog, after Back from a technique, keeps the technique's
  title (`web_back.txt`). After a screen opened by Enter, DOM focus was on
  its Back button and a first Enter did nothing; after a Tab, which left
  focus there, Enter closed it (`web_back.txt`; I03's subject).
- **Android.** The pane title is "Orders" (or "Details", or a single
  space) once each screen is open, and the example's title again after
  Back (`S06ScreenTitlesTest`). TalkBack, as each screen opened, said its
  pane title and then "Back", "Button": "Orders" for the good examples
  and `bad-no-document-title`, "Details" for `bad-vague-title`, and an
  empty utterance for `bad-no-title` and `bad-cupertino-unnamed`; as each
  closed, the example screen's title first
  (`docs/evidence/S06/talkback-android.md`, one walk, right). After the
  title, in the first and third recordings, TalkBack went to "Open
  orders", "Button" for every example (the third is the committed
  transcript, and said what the first said in every row); in the second,
  for `good-cupertino`, to the app's "Back", "Button" instead
  (`docs/evidence/probes/s06/talkback-round2-fail.md.txt`, which failed
  on that row under the judge of the time, the only row that differed
  in what was said). Where focus goes when a screen closes is I03's, and
  is recorded, not judged, here. On the two
  Cupertino screens TalkBack said "Back", "Button" with no "Double-tap to
  activate", which it said for Material's Back: the node named Back has
  no click action there (FL-303).
- **iOS.** As each screen opened, VoiceOver's reads went from "Open
  orders Button" to "Back Button" on the Material screens and to
  "Button" on the Cupertino ones (FL-303), and to nothing else; the
  screen then read "Orders Heading" (or "Details Heading", or "Orders"
  as plain text for `bad-no-title`) and the text, the Cupertino screens
  "Back Button" first; as each closed, the reads went to "Open orders
  Button" (`docs/evidence/S06/voiceover-ios.md`). The tree: two buttons
  on each Cupertino screen, one labelled "Back" and one with no label;
  one on each Material screen (`S06ScreenTitlesUITests`).
- **VoiceOver on the web** (the principal's recordings, Playwright's
  Chromium and WebKit on macOS, `navigator.platform` as it is). The
  second passed, twelve tests of twelve
  (`docs/evidence/S06/voiceover-web.md`); the first failed one test,
  `good-material` in Chromium, where VoiceOver could not be started
  ("Error: VoiceOver cannot be started"), and every walk that ran in it
  was complete (`docs/evidence/probes/s06/voiceover-web-round1-fail.md.txt`,
  `voiceover-web-round1-error.txt`). No expected list was changed between
  them. In the passing one every walk was complete on its first try, in
  both browsers: each example screen to its button, "Open orders
  button", and each opened screen, "heading level 1 Orders" (or
  "Details", or "Orders" as plain text for `bad-no-title`) and the text.
  The opening rows, recorded and not judged, differ between the
  browsers and between the recordings. WebKit read "Back button" for
  every example, in both. Chromium, in the passing recording: for
  `good-material`, "Back and 1 more item and 1 more item group", then
  "Back button"; for `bad-vague-title`, the same group, then "Back";
  "Back button" for `bad-no-title` and `bad-no-document-title`; "Back button, group" and
  VoiceOver's help for a group for the two Cupertino ones, with "Back and
  2 more items group" first for `bad-cupertino-unnamed`. In the first
  recording the "Back and 2 more items group" came first for
  `good-cupertino` and not `bad-cupertino-unnamed`, and `bad-vague-title`
  ended on "Back button". No opening row of either recording had the
  title. These rows prove only what was heard in each recording, and the
  spec claims nothing more of them.
- **Widget tests.** No title is sent on Back, for any example; the route
  names and headings are as the table above, as Android and as iOS.

Skips and what they give up, in the tests:

- The widget tests read the route's name the way the engines' source
  does (the first non-empty label of a node with `namesRoute` in the last
  route); they do not run an engine. The Android tree test reads the
  pane title the engine sets; the iOS tests cannot read what the engine
  posts with its screen change notification, only what VoiceOver then
  says.
- The widget tests skip `labeledTapTargetGuideline` on the opened screens
  of `good-cupertino` and `bad-cupertino-unnamed`, because of the
  framework's own Back button (FL-303),
  and assert that defect instead. They check that no text is cut short
  on the example's own widget and on the whole opened screen, and not on
  the example screen's app bar, which is the app's.
- The web tests' route checks set `navigator.platform` before load, to
  "MacIntel" and to "Linux x86_64", in Playwright's Chromium on macOS (and
  on CI, Playwright's Chromium on Linux). Overriding the value is not the
  same as a browser that runs on Linux; no browser on Windows, and no
  real browser on Linux, was tried here. Chromium only for the tree.
- The Android tree test reads the pane titles of the application windows
  only; the status bar has a pane title of its own.
- TalkBack's opening rows are judged as their exact list of utterances,
  except that TalkBack's usage hint, "Double-tap to activate", may end a
  row or not (it ended the Material rows and not the Cupertino ones,
  whose Back node has no click action): a row that differed only by that
  hint would pass either way. A closing row is judged by its first
  utterance, exactly, the title; everything after it is recorded and not
  judged, since it varied between recordings. A row whose capture was cut
  off in the log is still judged on what was captured of it, each
  utterance in its own place: one captured whole must be the utterance
  allowed there, and one cut off must have, as its captured text, the
  start of it (an empty capture proves nothing); an utterance beyond the
  last place, cut off or not, and a second usage hint, are wrong. A row
  shown wrong fails for good, so a wrong title cannot be walked again
  away; one that is short of its utterances, or whose cut-off parts could
  still be the right ones, stays incomplete and is walked again
  (`whole_wrong` in `tool/talkback.py`; `S06CutOffRows` in
  `tool/test_talkback.py`, from the log to the report).
- The iOS VoiceOver landing reads `currentSpeech()` every 0.15 s; an
  utterance shorter than that between two reads would not be seen.
- The web VoiceOver opening rows are recorded and not judged, so they
  prove nothing but that speech was captured.
- The good examples' button is a `FilledButton`, whose focus shows as a
  tint of its container, which FL-434 records as not a 1.4.11 failure as
  written; its text contrast with focus on it is checked.

- **The Android suite passed at CI's size** (320 by 640 at 160 dpi) on the
  local emulator (`docs/evidence/probes/s06/android_320x640.txt`). Its
  first run, at the local size, failed one test, a fault of the test
  (`android-test-round1-fail.txt`, the probe README).

**Not done yet.** What
TalkBack and VoiceOver do with a title that changes inside one route
(FL-305) and with a drawer, beyond the probe.

## 8. Decisions

Decided by the principal on 2026-11-26, in answer to the build; the
owner has been told of the first, and may overrule the second and the
fourth:

- **The web is `PlatformStatus.limitation`, citing FL-300, with no good
  example on the web.** This follows the owner's rule of 2026-11-23. No
  `NavigatorObserver` or `RouteAware` that sets the title again on a pop
  is built: it would be a mechanism of the project's own. The app's own
  screens have the same fault (`lib/app/widgets.dart`, `PageScaffold`:
  the catalog after Back keeps the technique screen's title,
  `docs/evidence/probes/s06/web_back.txt`); `lib/app` is not changed
  here, and section 9 hands it on.
- **R5, the title said when a screen opens, is not a requirement on
  iOS.** 2.4.2 does not ask for it, and its only source is the Android
  Compose repository. iOS applies: on iOS the title is not heard as a
  screen opens (FL-302), and VoiceOver reads it as a heading when it
  reaches it.
- **`good-cupertino` is not a custom solution**: `Semantics(namesRoute:
  true)` fills FL-301 with a documented property, as S05
  `good-cupertino` fills FL-014 with `headingLevel`. Its Back button's
  unnamed tap target (FL-303) is a framework defect inside a good
  example, and the spec, the doc, and the example's code say so by
  platform: on iOS it fails 4.1.2's name as written; on the web and
  Android it was not shown to fail. The example is not called free of
  defects.
- **`bad-cupertino-unnamed` is kept**, labelled as a framework defect
  that fails no WCAG criterion (it misses R5 on Android).

## 9. What is handed on

- **I03 Focus management**: on the web, after a screen opens, DOM focus
  is on its Back button and Enter does nothing until a Tab, which leaves
  focus on Back (`docs/evidence/probes/s06/web_back.txt`). TalkBack and
  VoiceOver go to the new screen's first control, and back to the button
  that opened it when it closes, except once: in the second TalkBack
  recording, TalkBack went to the app's Back after `good-cupertino`'s
  screen closed (`talkback-round2-fail.md.txt`).
- **The app's shell** (`lib/app`): FL-300 holds for the app's own screens; the catalog after Back keeps the technique screen's title (`web_back.txt`). Not changed here (the principal's decision, section 8).
- **Navigation techniques** (tabs, bottom navigation, drawers): FL-305;
  TalkBack said only "selected" for a new destination; a `Drawer` names a
  route of its own, which TalkBack announced (p13).
- **Resize text**: in the widget tests, `AppBar` limits its title's text
  scale (drawn at 29.5 for 22 at 200%) and `CupertinoNavigationBar` does
  not scale its title at all (17 at 200%); measured in the test font only
  (`flutter_test_cut.txt`).
- **Dialogs**: a dialog's route is named by its title on Android, by the
  framework's source (`material/dialog.dart`); not measured here.
