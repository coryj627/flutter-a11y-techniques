# Spec: C18 Card

Status: Draft 1 (2026-11-22), written with the build. Wave 2, links and
simple components. Flutter pin: 3.47.5.

A card is a surface that holds one subject: a heading, its text, often a
picture, and actions, or the whole card as one control. What a heading is,
is [S05 Headings](S05-headings.md); a button, [C01 Button](C01-button.md); a
link, [C03 Stand-alone link](C03-stand-alone-link.md); a picture's text
alternative, [S02 Informative images](S02-informative-images.md); a control
that takes keyboard focus, [I01](I01-focusable-controls.md); how focus is
shown, [V14](V14-focus-indicators.md).

## 1. Rule

A card's parts are exposed as what they are, in their order: its heading as
a heading on its own, its text as text, its picture with a text
alternative, and each action as a control whose name says what it acts on.
A card that is one control is a button named by its text, and keeps that
role. A link in a card says where it goes by itself or with context that
is related to it, not by a heading that nothing relates to it.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies | Applies | Applies |

Every good example is Flutter's own widgets through their documented
parameters; none is a custom solution. What Flutter does not give a card is
recorded and not built:

- No platform is told that a card is a card. Flutter has no `article` role
  ([FL-026](../flutter-limitations.md#fl-026), extended), and a `Card` with
  separate parts is no node at all. The card's heading is what marks where
  it starts, as MDN says each `article` should be identified.
- A heading merged into a control is a heading and no longer a button or a
  link on the web ([FL-268](../flutter-limitations.md#fl-268), new;
  `bad-heading-button`). So a card that is one control has no heading of
  its own on any platform here (`good-tappable`).
- A `Card` left at its default joins all its text into one node, and a
  heading in it makes all of that one heading
  ([FL-269](../flutter-limitations.md#fl-269), new; `bad-default-container`).
- The tappable card of the `Card` documentation, an `InkWell`, is no button
  on Android and iOS ([FL-401](../flutter-limitations.md#fl-401), extended;
  `bad-ink-well`).

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [1.3.1 Info and Relationships](https://www.w3.org/TR/WCAG22/#info-and-relationships) | The card's heading is shown as a heading and its text as text; the structure that is shown is the structure exposed |
| [2.4.4 Link Purpose (In Context)](https://www.w3.org/TR/WCAG22/#link-purpose-in-context) | A link in a card, or a card that is a link, says where it goes alone or with its programmatically determined context |

For 1.3.1, a heading is shown by its size and place, and the card's text
under it is shown as body text. A heading that holds the text as well
(`bad-default-container`) exposes body text as part of a heading, which is
structure that the presentation does not show: it fails 1.3.1 as written,
on every platform where it is measured (section 7). The card's boundary is
shown too, but no platform here has a role for it
([FL-026](../flutter-limitations.md#fl-026)); a heading at the start of each
card is what conveys where one ends and the next starts, which is what
[H42](https://www.w3.org/WAI/WCAG22/Techniques/html/H42) and MDN's
`article` ask of a heading. No 1.3.1 failure is claimed for the missing
card role.

For 2.4.4, "programmatically determined link context" is, in HTML, text in
the same sentence, paragraph, list item, or table cell as the link, or in
table header cells for it (the WCAG definition and
[F63](https://www.w3.org/WAI/WCAG22/Techniques/failures/F63)'s test). A
heading before the link is not in that list: identifying a link by the
heading before it ([H80](https://www.w3.org/WAI/WCAG22/Techniques/html/H80))
is an advisory technique for 2.4.4, not a sufficient one (Understanding
2.4.4, read 2026-11-22). F63's test fails a link whose needed context is
neither in those places nor given to the link in another way
(`aria-label`, `aria-labelledby`, `aria-describedby`). The criterion's
exception, a purpose "ambiguous to users in general", does not apply to a
"Read more" link under a card's heading: everyone who sees the card can
tell what it reads more of. So `bad-read-more` fails 2.4.4 on every
platform: its context, the heading, is shown and not related to it (section
7 has what each platform relates). A Flutter link is built by hand in every
case (C03, [FL-221](../flutter-limitations.md#fl-221)), so no good example
here is a link; the good examples' actions are buttons, which 2.4.4 does
not cover, and their names say what they act on (R4).

Other criteria the examples touch are named where they fail: 4.1.2 Name,
Role, Value (`bad-heading-button` on the web, `bad-ink-well` on Android and
iOS).

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | The card's heading is a heading, on its own, and the first part of the card | [iOS Cards](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/Cards.md) ("a heading as the first focused element"), [MDN `article`](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/article) (each article "identified, typically by including a heading"), [H42](https://www.w3.org/WAI/WCAG22/Techniques/html/H42) |
| R2 | The card's text, picture, and actions are parts of their own, each with its own role, in the order shown | MDN `article` (a heading and its content), [Flutter: `Card.semanticContainer`](https://api.flutter.dev/flutter/material/Card/semanticContainer.html) ("should be false if the card contains multiple different types of content") |
| R3 | A picture that tells something has a text alternative | [S02 Informative images](S02-informative-images.md), [MDN `img`](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/img) |
| R4 | Each action's name says what it acts on, starting with its visible word | iOS Cards (a call to action "unique and specific when spoken", may need `.accessibilityLabel`), [S01 Accessible names](S01-accessible-names.md) (`good-specific-names`), [2.5.3 Label in Name](https://www.w3.org/TR/WCAG22/#label-in-name) |
| R5 | Each action is reached and activated by touch, keyboard, and screen reader, and runs only its own action | [C01 Button](C01-button.md), [APG Button](https://www.w3.org/WAI/ARIA/apg/patterns/button/) (Enter and Space) |
| R6 | A card that is one control is one element with a control's role, named by its text | iOS Cards (a card "combined as one focusable element", with the button trait added back), [I01](I01-focusable-controls.md) (`good-material`, a `ListTile` in a `Card`) |
| R7 | That role is kept: a heading inside a control does not take its place | [WAI-ARIA 1.2: button](https://www.w3.org/TR/wai-aria-1.2/#button) (children presentational), the plain HTML comparison in section 7 |
| R8 | A link in a card says where it goes, alone or with context related to it | [Understanding 2.4.4](https://www.w3.org/WAI/WCAG22/Understanding/link-purpose-in-context.html), [F63](https://www.w3.org/WAI/WCAG22/Techniques/failures/F63), iOS Cards |

Flutter references for the mechanisms used:

- [`Card`](https://api.flutter.dev/flutter/material/Card-class.html), [`Card.semanticContainer`](https://api.flutter.dev/flutter/material/Card/semanticContainer.html)
- [`ListTile`](https://api.flutter.dev/flutter/material/ListTile-class.html), [`TextButton`](https://api.flutter.dev/flutter/material/TextButton-class.html), [`ButtonStyle.side`](https://api.flutter.dev/flutter/material/ButtonStyle/side.html)
- [`Text.semanticsLabel`](https://api.flutter.dev/flutter/widgets/Text/semanticsLabel.html), [`Semantics.headingLevel`](https://api.flutter.dev/flutter/widgets/Semantics/headingLevel.html), [`Image.semanticLabel`](https://api.flutter.dev/flutter/widgets/Image/semanticLabel.html)
- [`CupertinoColors.secondarySystemGroupedBackground`](https://api.flutter.dev/flutter/cupertino/CupertinoColors/secondarySystemGroupedBackground-constant.html)

Radix comparison bar: Radix has no card primitive; the bar is HTML's
`article` with a heading, a paragraph, and buttons, as MDN describes it.

The iOS reference combines a card with many actions into one element and
adds its actions back with `.accessibilityAction`, or wraps it in a
`NavigationLink`. That is not built here: Flutter's custom semantics
actions are not exposed on the web ([FL-022](../flutter-limitations.md#fl-022)),
and a card merged into one element loses its actions' own names
(`MergeSemantics`, probe fixture p18). The Android reference repositories
have no card entry.

### Cupertino

Cupertino has no card widget. `good-cupertino` draws one with Cupertino's
grouped background and a rounded box, which gives assistive technology
nothing, so it shows the same parts as `good-material` without `Card`. It
has no action: a Cupertino action would be a `CupertinoButton`, which Enter
does not activate on the web ([FL-002](../flutter-limitations.md#fl-002))
without an `Actions` built by hand, which would make it a custom solution.
`CupertinoListSection.insetGrouped`, the nearest grouped surface, does not
make its header a heading ([FL-014](../flutter-limitations.md#fl-014)), and
a `CupertinoListTile` takes no keyboard focus and has no button role
([FL-400](../flutter-limitations.md#fl-400); probe fixture p17).

There is no widgets-layer example: the widgets layer has no card either,
and a card drawn there is `good-cupertino` without its colours.

## 5. Examples

Every card is the same subject: the heading "Ridge trail", the text "A 6 km
climb with a view.", and, where there is one, the picture
"Sunrise over the valley". Under each card with controls, one count per
action ("Saves: 0") shows which action ran.

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-material` | Material | A card with separate parts: heading, text, picture, two actions | `Card(semanticContainer: false)`; `Semantics(headingLevel: 3)` on the title; `Image(semanticLabel:)`; two `TextButton`s named "Save Ridge trail" and "Share Ridge trail" by `Text(semanticsLabel:)`, with a 2 pixel focus outline from their own `style` (FL-430) | R1 to R5 |
| `good-tappable` | Material | A card that is one control | `ListTile(onTap:, title:, subtitle:)` in a `Card`: a button named by the title and the text; the title is not a heading (FL-268) | R5, R6, R7 |
| `good-cupertino` | Cupertino | A card in Cupertino's style, with no action | A `DecoratedBox` in `CupertinoColors.secondarySystemGroupedBackground`; `Semantics(headingLevel: 3)`; `Image(semanticLabel:)` | R1, R2, R3 |

No good example here is a custom solution. The register's rows are in
[custom-solutions.md](../custom-solutions.md#c18-card): each is Flutter's
widgets through their documented parameters, with a name, a heading level,
or a text alternative given by documented properties.

### Bad

| Slug | Defect | Violates |
| --- | --- | --- |
| `bad-default-container` | `Card` left at `semanticContainer: true`, its default: the heading and the text are one node, a level 3 heading, and on the web an `<h3>` that holds the card's button too ([FL-269](../flutter-limitations.md#fl-269)) | R1, R2 |
| `bad-heading-button` | The title of `good-tappable` marked as a heading: the card's one node is a heading and a button, and on the web only a heading ([FL-268](../flutter-limitations.md#fl-268)) | R7 |
| `bad-ink-well` | The tappable card of the `Card` documentation: an `InkWell` round the title and the text, with no button role on Android and iOS ([FL-401](../flutter-limitations.md#fl-401)) | R6 |
| `bad-read-more` | A link named "Read more" under the card's heading, built as C03's links are; the heading that says what it reads more of is not related to it | R8 |

What each fails, by platform, as the criteria are written (section 7 has
the measurements):

| Example | Android | iOS | Web |
| --- | --- | --- | --- |
| `bad-default-container` | 1.3.1: one heading node named by the heading and the text, the button its child | 1.3.1: one element named by the heading and the text, read as one heading | 1.3.1: one `<h3>` named by the heading and the text, holding the button |
| `bad-heading-button` | none: a `Button` that is also a heading, as the iOS reference builds a combined card | none: a button that VoiceOver reads as a button and a heading | 4.1.2: an `<h3>` with no button role; a DOM click on it runs nothing, though a mouse click and Enter do |
| `bad-ink-well` | 4.1.2: an `android.view.View`, clickable, with no button role ([FL-401](../flutter-limitations.md#fl-401)) | 4.1.2: static text, read by VoiceOver as its text alone ([FL-401](../flutter-limitations.md#fl-401)) | none: a button, as any tappable node is ([FL-006](../flutter-limitations.md#fl-006)) |
| `bad-read-more` | 2.4.4 (F63): a link named "Read more", a sibling of the heading's node with nothing relating them | 2.4.4 (F63): a link named "Read more", read as "Read more Link", the heading an element of its own | 2.4.4 (F63): `<a href>` named "Read more", outside the heading and the paragraph, with no `aria-label`, `aria-labelledby`, or `aria-describedby` |

`bad-heading-button` on Android and iOS is a heading and a button at once:
that is the combined card of the iOS reference ("retains its child heading
semantics", with the button trait added back), so it is not called a
failure there. Its one defect is the web's.

`TestId` is a `MergeSemantics`, so it is put round each control and never
round a card: round `good-material`'s card it would make the whole card one
button with the heading's level, on the web a heading (probe fixture p18).
The headings and texts are found by their text.

## 6. Assertions by layer

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Every example: at 200% text on a 320 by 640 screen, no layout overflow, no text that hits its line limit, none taller than its box, none past the screen's edge. Good, in light and dark: the four guidelines, and the text contrast guideline again with keyboard focus on each control. `good-material`: the card's nodes, in traversal order, are exactly the heading (level 3, nothing else), the text, the picture (image), "Save Ridge trail" and "Share Ridge trail" (buttons with a tap action); Tab goes Back, Save, Share; each button's style draws a 2 pixel outline in the text colour, 3:1 or more against the card, only for the focused state. `good-tappable`: exactly one node, a button named "Ridge trail\nA 6 km climb with a view.", no heading level and no header flag; its focus tint inside the card is under 3:1 and over 1:1 (FL-434: 1.32:1 in light, 1.44:1 in dark), written to fail if it reaches 3:1. `good-cupertino`: exactly the heading, the text, and the picture, and no control. For each control: a tap, and the tap action, each add one to its own count and to no other; Tab to it, then Enter, and then Space (each from a fresh open), do the same. Bad: `bad-default-container` one node named by the heading and the text with level 3, the button inside it, and the button still working; `bad-heading-button` one node with level 3, the button flag, and a tap action that works; `bad-ink-well` one node with a tap action and no button or link flag, reached by Tab and activated by Enter; `bad-read-more` the heading, the text, and a link "Read more" with its address, nothing in its label, hint, value, or tooltip naming the trail, and a tap that opens the technique's page. The tests run as Android, so the web engine's choice of role (FL-268) is not seen here |
| L3 web | Good: the example's elements in the page's order from Chromium's tree (the ARIA snapshot between the "Example" heading and the first count): `good-material` exactly a level 3 heading "Ridge trail", the text, the image, and the two buttons, with nothing inside the heading; three buttons (Back included) and no link; `good-tappable` exactly one button named by the title and the text, and no level 3 heading; `good-cupertino` the heading, the text, the image, and no button but Back. Tab goes Back, Save, Share. For each control: a click, a DOM click with no pointer events, and Tab then Enter, then Space (each from a fresh load) add one to its own count and to no other. Bad: `bad-default-container` one level 3 heading named by the heading and the text, holding the button, no heading "Ridge trail" alone, and the button working; `bad-heading-button` an `<h3>` with the card's identifier, named by the title and the text, no button but Back; a mouse click and Tab then Enter open it (positive controls), and a DOM click on it does nothing, with a mouse click on it and a DOM click on Back in the same load as positive controls; `bad-ink-well` a button (FL-006) that Tab and Enter open; `bad-read-more` the heading, the text, and a link "Read more" to `#/t/C18`, with no description and no `aria-label`, `aria-labelledby`, or `aria-describedby`, outside the heading; Tab and Enter follow it. The VoiceOver judge (`web_tests/vo/c18_vo_walks.js`) is tested on made-up walks, and each screen is checked to show the title and lines the judge expects above its heading |
| L3 Android | The example's named nodes between the "Example" heading and its first count, in the tree's order (scrolling a step at a time where the card's end is below the view, each node kept once): `good-material` exactly a heading `View` "Ridge trail", a `View` with the text, an `ImageView` with the picture's name, and two clickable `Button`s, "Save Ridge trail" and "Share Ridge trail"; `good-tappable` exactly one clickable `Button` named "Ridge trail\nA 6 km climb with a view.", not a heading; `good-cupertino` the heading, the text, and the picture, and no clickable node but Back. For each control, from a fresh launch each: `ACTION_CLICK` (what TalkBack's double tap performs), a tap at its centre, and Tab then Enter each add one to its own count and to no other. Bad: `bad-default-container` one heading `View` named by the title and the text, whose one child is the button, no node named by the title alone, and the button's click action working; `bad-heading-button` a `Button` that is a heading, named by the title and the text, whose click action works; `bad-ink-well` an `android.view.View`, clickable, named by the title and the text, whose click action, and Tab then Enter, work; `bad-read-more` the heading, the text, and a clickable `View` "Read more" with the address `#/t/C18` in a `URLSpan`, with nothing in its name, hint, or state naming the trail, neither it nor the heading holding the other, and a click action that opens the technique's page. Run once at CI's 320 by 640 at 160 dpi as well |
| L3 iOS | `good-material`: the heading and the text are elements of their own (no element holds the text but its own), the picture an image, and the only buttons but Back are "Save Ridge trail" and "Share Ridge trail"; `good-tappable` one button named "Ridge trail\nA 6 km climb with a view.", the only button but Back; `good-cupertino` the heading, the text, the picture, and no button but Back. For each control a tap adds one to its own count and to no other; two Tabs then Enter, and then Space, add one to the first control's count, and three Tabs to the second's, each key sent once from a fresh launch (XCUITest cannot see Flutter's focus; the probe found the first Tab on Back). Bad: `bad-default-container` no element named by the title alone or the text alone, one named by both, and the button working; `bad-heading-button` a button named by the title and the text, whose tap works; `bad-ink-well` not a button, named by the title and the text, no button but Back, a tap working; `bad-read-more` a link named "Read more", without the trail, the heading an element of its own, and a tap opening the technique's page. XCUITest cannot read traits: headings are checked in the VoiceOver walk |
| L4 TalkBack | What is read with focus moved to each part of each card: each heading with "Heading" and without the text; the text alone; the picture with "Image"; each button with its whole name and "Button"; `good-tappable` its title, its text, and "Button", and no "Heading"; `bad-default-container` the title and the text with "Heading"; `bad-heading-button` both "Heading" and "Button"; `bad-ink-well` its text and "Double-tap to activate" and no "Button"; `bad-read-more`'s link "Read more" and "Double-tap to open link", without the trail. The usage hint is not required on a button (probe p05) |
| L4 VoiceOver iOS | Every utterance after the "Example" heading to the end of the screen, compared as a whole list (C03's walk, `C03Walk`): `good-material` "Ridge trail Heading", the text, "Sunrise over the valley Image", "Save Ridge trail Button", "Share Ridge trail Button", and the two counts; `good-tappable` the title and the text with "Button", and the count; `good-cupertino` the heading, the text, the picture; `bad-default-container` the title and the text with "Heading", then the button and the count; `bad-heading-button` the title and the text with "Button Heading"; `bad-ink-well` the title and the text with no trait; `bad-read-more` the heading, the text, "Read more Link". Every utterance here is under the service's 64 characters |
| L4 VoiceOver web | Every walk must read the whole screen, each stop in its place (`judgeExampleWalk` in `web_tests/vo/c18_vo_walks.js`, a copy of C04's): the screen's title and description, the "Example" heading, then exactly the expected list, to the end of the screen, the counts included. A wrong stop, an empty one, a skipped one, or a walk that reached the end with any expected stop not read fails the test for good; only a walk cut short before the end with every stop right so far is walked again, up to three walks, and every walk is logged in the transcript. No runner retries. In Chromium and WebKit. The expected phrases were written from Chromium's tree and earlier transcripts' wording before any C18 recording, and are not yet measured |

## 7. What the build found (Flutter 3.47.5)

The probe that came first is in [evidence/probes/c18](../evidence/probes/c18/README.md):
twenty fixtures on every platform, with plain HTML pages for comparison on
the web.

- **A `Card` at its default is read as one heading**
  ([FL-269](../flutter-limitations.md#fl-269), new; `bad-default-container`).
  `semanticContainer` is true unless set, and every `Text` in the card is
  merged into the card's node with its flags, so a title with a heading
  level makes the whole text a heading: on the web an `<h3>` holding the
  picture and the buttons; on Android a heading `View` with them as its
  children, read by TalkBack as the title and the text and "Heading"
  (probe p01); on iOS one element named by both, which VoiceOver read with
  "Heading" after the text. With `semanticContainer: false`, as the `Card`
  documentation says for "multiple different types of content", each part
  is a node of its own (p02, `good-material`).
- **On the web, a heading merged into a control takes the control's role**
  ([FL-268](../flutter-limitations.md#fl-268), new; `bad-heading-button`).
  The web engine picks the heading role before a button or a link for any
  node with a heading level (source read). A `ListTile` whose title is a
  heading (p06), an `InkWell` card with a heading (p03, p04), the same with
  `Semantics(button: true)` (p19), a card merged with `MergeSemantics`
  (p18), and a card made one link (p09) all became an `<h3 tabindex="0">`
  with no button role and, for the link, no `href`. Tab reached each, and
  Enter, Space, and a mouse click ran its handler, but a DOM click with no
  pointer events ran nothing (`web_round2.txt`), and the link card did
  nothing on Enter, as C03's `BrowserKeys` leaves Enter to a browser that
  has no link there. Android keeps both roles: TalkBack read p06 and p19 as
  "Button. Heading". iOS keeps them too: XCUITest found a button (p06,
  p18, p19) or a link (p09), and VoiceOver read `bad-heading-button` as
  "Ridge trail A 6 km climb with a view. Button Heading" (the probe's
  longer names were cut off at 64 characters before the second trait).
  Plain HTML keeps both as well: Chromium exposes a `role="button"`
  element or an `<a href>` round an `<h3>` as a button or a link with the
  heading inside it.
- **The `Card` documentation's tappable card has no button role off the
  web** ([FL-401](../flutter-limitations.md#fl-401), extended;
  `bad-ink-well`): `Card` round `InkWell`, read by TalkBack as its text and
  "Double-tap to activate" (p20), and on iOS static text that VoiceOver
  read as its text alone. A `ListTile` with `onTap` is a
  button on every platform (p05, `good-tappable`), read by TalkBack as its
  title and text and "Button".
- **A control inside a tappable card is a control of its own** (p07, an
  `InkWell` card holding a `TextButton`; p08, a `ListTile` with a trailing
  `IconButton`). Android: a clickable node with a clickable child; TalkBack
  focus and Tab reached each, and each ran only its own handler. Web: a
  button inside a button (p08) or inside the `<h3>` (p07), both in
  Chromium's tree, both reached by Tab and run by Enter, Space, and a click.
  iOS: the `InkWell` card an element of type other and the `ListTile` a
  button, each with the inner button as an element of its own; VoiceOver
  moving forward stopped on the card and then on the inner button, a tap
  on each ran its own handler, and two Tabs then Enter ran the card's,
  three its inner button's. No example builds it: no defect was shown, and ARIA makes a
  button's children presentational
  ([WAI-ARIA 1.2: button](https://www.w3.org/TR/wai-aria-1.2/#button)), so
  it is not offered as good either. What VoiceOver on the web does with the
  inner button was not measured.
- **A list of cards** (p13 to p15). In a `Column` the cards' parts are
  siblings with nothing round each card. In a `ListView` each card is an
  item: on Android the list has collection information (three rows) and
  TalkBack read the first heading with "In list. 3 items"; on the web each
  item is an element with no role. `SemanticsRole.list` and `listItem`
  give `role="list"` and `role="listitem"` on the web and an
  `android.widget.ListView` on Android ("In list"); on iOS neither changed
  what XCUITest or VoiceOver showed. No platform
  has an `article` role ([FL-026](../flutter-limitations.md#fl-026),
  extended). No example builds a list: a list of two or more cards does not
  fit CI's 320 by 640 screen with the counts, and the one lesson it adds
  that the examples do not, names that tell the cards' actions apart, is in
  `good-material`'s button names already.
- **Cupertino has no card.** A `CupertinoListSection.insetGrouped` header
  is not a heading ([FL-014](../flutter-limitations.md#fl-014)) and its
  `CupertinoListTile` takes no keyboard focus and has no button role
  ([FL-400](../flutter-limitations.md#fl-400)); TalkBack read p17's tile as
  its text and "Double-tap to activate", and Tab passed it on Android and
  the web. A `CupertinoButton` in a drawn card (p16) is a button, which on
  the web Enter does not activate without an `Actions` of its own
  ([FL-002](../flutter-limitations.md#fl-002)); `good-cupertino` has no
  action for that reason.
- **"Read more"** (p10 to p12). A `TextButton` "Read more" is a button, which
  2.4.4 does not cover; `Text(semanticsLabel:)` names it "Read more about
  cards" (p12) on every platform. A link "Read more" (p11, C03's link) is
  a link named "Read more", next to the heading and not inside it or named
  by it: `bad-read-more`.
- **TalkBack's usage hint is not always heard within the walk's dwell.**
  The `ListTile` of p05 was read as its text and "Button" with no
  "Double-tap to activate", where every `TextButton` had it; the TalkBack
  expectations require the role and not the hint.
- **The focus of a `ListTile` in a card is its tint**, 1.32:1 against the
  card in light and 1.44:1 in dark (widget test), a change within the
  component that 1.4.11 as written does not cover
  ([FL-434](../flutter-limitations.md#fl-434)); the `TextButton`s get a 2
  pixel outline from their own `style` ([FL-430](../flutter-limitations.md#fl-430)).
- **The Android suite passed at CI's size** (320 by 640 at 160 dpi) on the
  local emulator before the evidence run
  (`docs/evidence/probes/c18/android_320x640.txt`).

Skips and what they give up, in the tests:

- The widget tests run as Android (`kIsWeb` false), so the web engine's
  choice of role for a node ([FL-268](../flutter-limitations.md#fl-268)) is
  seen only in the web tests.
- `good-tappable`'s focus tint is worked out from the theme's colours, the
  focus colour laid over the card's surface (its colour with the surface
  tint for its elevation), not read from pixels: it gives up anything the
  ink draws that is not that colour, such as its shape and its edge.
  `good-material`'s focus outline is read from the buttons' style for the
  focused state, not from pixels, and its contrast is taken against the
  card's surface worked out the same way.
- The card's nodes are compared only where they have a name or a tap
  action (widget tests), a name (Android), or a line of Chromium's ARIA
  snapshot (web): a node with neither, such as a container, is left out.
  Every control here has a name; the count of controls is checked on each
  layer as well (buttons on the web and iOS, clickable nodes on Android).
- On Android the card is read from the top of the screen and then scrolled
  a step at a time until a count is in the tree, keeping each node once:
  two nodes with the same name, class, and identifier would count as one;
  no example has two.
- TalkBack's walk moves focus to each named part by action and does not
  see a stop it was not told of; the Android tree test checks the parts
  and their order. The usage hint, "Double-tap to activate", is not
  required on a button (probe p05). `talkback.py` walks an element again,
  up to three walks, when its speech fails its checks (a shared tool,
  unchanged); the transcript lists every element that needed it.
- The iOS tree tests cannot read traits, so a heading is checked in the
  VoiceOver walk, and cannot see Flutter's focus, so the key tests rely on
  the probe's finding that the first Tab is on Back and each later one on
  the next control; which count changed is what shows the key reached that
  control.
- The iOS VoiceOver walk is C03's (`C03Walk`): it ends where moving on
  gives the last utterance again, twice, and so gives up two neighbouring
  elements that VoiceOver reads alike; no example has two ("Saves: 0" and
  "Shares: 0" differ). Utterances are cut at 64 characters; the longest
  here, `bad-heading-button`'s, is 52.
- The web test that a DOM click on `bad-heading-button` does nothing waits
  one second; a mouse click on the same element and a DOM click on Back,
  in the same load, are its positive controls.
- `bad-read-more`'s "not related" is checked as what each tree shows: on
  the web no `aria-label`, `aria-labelledby`, or `aria-describedby` and no
  description, and the link outside the heading; on Android nothing in the
  link's name, hint, or state naming the trail, and neither node holding
  the other; on iOS the link's label alone. What a screen reader might
  offer as context of its own (a heading rotor, say) is not measured.

**Not done yet.** The web VoiceOver transcript: the expected phrases in
`web_tests/vo/c18_card_vo.spec.js` were written from Chromium's tree and
the wording of earlier transcripts, before any C18 recording, and may
need changing once it is recorded. Also: which stops a TalkBack swipe makes
(the walk moves focus by action); VoiceOver's own activation on iOS, which
XCUITest cannot make (C04 probe round 3); what VoiceOver on the web does
with a button inside a button (probe p07, p08) and with
`bad-heading-button`'s `<h3>` when it activates it; a card that is a link,
or a good link in a card, which would be a custom solution
([FL-221](../flutter-limitations.md#fl-221)); a list of cards as an
example (probe only); cards in dark mode on a device (widget tests only);
text scaling on the web; and right-to-left text.
