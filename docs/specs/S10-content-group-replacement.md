# Spec: S10 Content group replacement

Status: Draft 1 (2026-11-26), written with the build. Wave 3, structure
and order. Flutter pin: 3.47.5.

A visual composite, such as a rating drawn as a bar or as five stars
beside two numbers, whose pieces say little alone, is replaced for
assistive technology by one node whose label says what the composite
means, and its pieces are hidden. Out of scope, and cited: content
grouping, named groups and merged label and value pairs (S09); hiding
content in general (S12); a picture's text alternative and a chart's
(S02 Informative images, whose `good-chart` and `good-group-description`
give a drawing or an icon and a time one description), decorative images
(S03); a custom control's role, value, and adjust actions (S14
`good-rating` and F10 `good-custom`, flagged custom solutions, tested in isolation and not vetted by a real-world example); a single text's
reworded name (`Text(semanticsLabel:)`, S01); custom actions (I05).

## 1. Rule

A composite whose pieces do not say what it means is exposed as one node
whose label does, worked out from the same values the pieces show; every
piece is hidden, a piece with semantics of its own included; and no
control is hidden with them.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies | Applies | Applies |

The good examples are Flutter's own `Semantics` through its documented
parameters, and give the same one node on all three platforms (section
7). None is a custom solution. What the framework does not give, and is
not built here:

- **A framework control's semantics for a drawing** (the iOS reference's
  `accessibilityRepresentation`): no Flutter API does it
  ([FL-025](../flutter-limitations.md#fl-025), extended; source read). A
  drawn control is given a role, a value, and actions by hand (F10
  `good-custom`, S14 `good-rating`: flagged custom solutions, tested in isolation and not vetted by a real-world example), or the
  framework control itself is drawn another way. That wider subject is
  outside S10, whose requirement is a text alternative for a group, and
  stays in FL-025; the good examples meet S10's requirement on iOS, so iOS
  applies (the principal's decision, section 8).
- **A merged group takes a progress indicator's value, and its role where
  the platform has one** ([FL-330](../flutter-limitations.md#fl-330),
  new): `bad-merged`, `bad-not-excluded`. The good examples hide the bar.
- **Custom actions are not on the web**
  ([FL-022](../flutter-limitations.md#fl-022), extended with this probe):
  a replacement that takes in a control cannot hand its action on there.
  No example uses one.

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [1.3.1 Info and Relationships](https://www.w3.org/TR/WCAG22/#info-and-relationships) | What the composite's presentation conveys, a rating of 3.4 out of 5 stars from 856 reviews, is available in text or programmatically determined |
| [4.1.2 Name, Role, Value](https://www.w3.org/TR/WCAG22/#name-role-value) | A control inside a replaced composite keeps its name and role |

1.3.1, as written: "Information, structure, and relationships conveyed
through presentation can be programmatically determined or are available
in text." A star drawn full, half, or empty, and its place among five,
conveys how many stars of five; the "(856)" beside it conveys a count of
reviews only by its place and its brackets. With no replacement
(`bad-pieces`), what is determined is "3.4" and "(856)": the out of five,
the stars, and what 856 counts are conveyed by presentation alone, which
fails 1.3.1 as written, on all three platforms. The stars are non-text
content with no text alternative, so 1.1.1 Non-text Content fails as
written too; the alternative the replacement gives is its label. A label
fixed when the values change (`bad-stale`) makes "857 reviews", shown,
not determinable: the visible text is hidden and the only text exposed
says 856, which fails 1.3.1 as written, on all three.

A merged bar (`bad-merged`, `bad-not-excluded`) exposes the rating's
words, so its information is determinable; what it adds is a stray "68"
(the bar's value), and on Android and the web a progress bar node
([FL-330](../flutter-limitations.md#fl-330)). Whether a rating shown as a
bar is a user interface component that a progress bar role misidentifies,
4.1.2 does not say for content that takes no input; C26 read a progress
indicator as one, "under that reading". No criterion is claimed failed for
these two: the information is in the name, and the 68 is the bar's value
as drawn. Neither is a shown failure of a success criterion; each is
shown for what the user hears, a stray 68 (the principal's decision,
section 8).

4.1.2, as written: "For all user interface components …, the name and
role can be programmatically determined". A `TextButton` inside the
replaced composite (`bad-hides-control`) is a user interface component
with no node on any platform, so its name and role are not determinable:
4.1.2 fails as written, on all three. 2.1.1 is not failed: the keyboard
reaches and runs it (section 7).

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | A group whose pieces do not convey their meaning well is replaced, for a screen reader, by one text that says what the group means | [Android View: Content Group Replacement](https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/grouping/ContentGroupReplacement.md) (`android:contentDescription` on the enclosing `ViewGroup`: "Rating: 3.4 out of 5 stars"), [Android Compose: Content Group Replacement](https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/content/ContentGroupReplacement.md) (a group text alternative) |
| R2 | Every piece is hidden, so the replacement is not read as well as its pieces; a piece with semantics of its own (the progress indicator) has to be hidden too | Android Compose (`hideFromAccessibility()` on each child, "and when necessary on children of children", or `clearAndSetSemantics`, which replaces the semantics of all child composables), [Flutter: `Semantics.excludeSemantics`](https://api.flutter.dev/flutter/widgets/Semantics/excludeSemantics.html) ("Whether to replace all child semantics with this node") |
| R3 | The replacement follows the values: it is worked out from the same data the pieces show | Android View (the values "generally set to dynamic values in code") |
| R4 | A composite whose children control their own interactions is not replaced whole: a control is not hidden with the pieces | Android Compose (`clearAndSetSemantics` "is not the technique to use when child content should control its own interactions") |
| R5 | A drawn control is given the representation of a native control: its role, value, and actions | [iOS: Accessibility Representation](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/AccessibilityRepresentation.md) (`.accessibilityRepresentation` with a `Slider`; 4.1.2) |

R5 has no Flutter counterpart ([FL-025](../flutter-limitations.md#fl-025),
extended): it is outside S10, whose requirement is a text alternative
for a group (the principal's decision, section 8). S10 has no example for
it, and cites S14 `good-rating` and F10 `good-custom`, which give a drawn
control a role, a value, and actions by hand: flagged custom solutions, tested in isolation and not vetted by a real-world example. The iOS reference's subject is
a custom control; the Android references' is a composite that is not a
control, which is what S10 builds.

Flutter references for the mechanisms used:

- [`Semantics.excludeSemantics`](https://api.flutter.dev/flutter/widgets/Semantics/excludeSemantics.html),
  [`Semantics.label`](https://api.flutter.dev/flutter/widgets/Semantics/label.html)
- [`MergeSemantics`](https://api.flutter.dev/flutter/widgets/MergeSemantics-class.html),
  [`ExcludeSemantics`](https://api.flutter.dev/flutter/widgets/ExcludeSemantics-class.html)
- [`LinearProgressIndicator`](https://api.flutter.dev/flutter/material/LinearProgressIndicator-class.html),
  [`Icon`](https://api.flutter.dev/flutter/widgets/Icon-class.html) (no
  semantics without `semanticLabel`), [`TextButton`](https://api.flutter.dev/flutter/material/TextButton-class.html),
  [`ButtonStyle.side`](https://api.flutter.dev/flutter/material/ButtonStyle/side.html)

The inventory row names no APG pattern and no HTML element. The nearest
HTML is an element with `aria-label` over children with `aria-hidden`, or
`role="img"` with `aria-label` (whose children are presentational); it is
not built or measured here.

## 5. Examples

Every example shows the same rating: 3.4 out of 5 stars from 856 reviews,
"Rating: 3.4 out of 5 stars, based on 856 reviews" in words, as the
Android references word it (48 characters, under the 64 that VoiceOver's
test service gives back). The bar row is the references' own: the text
"Rating:", a `LinearProgressIndicator` at 3.4 of 5 (a node of its own,
value 68, a progress bar on Android and the web), "3.4 / 5", and "Reviews: 856". The star row is five star
`Icon`s with no `semanticLabel`, "3.4", and "(856)". Where there is a
button "Add a 5-star review", it adds a review, and the row then shows
857.

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-exclude-semantics` | Material | The bar row replaced, and a button that adds a review | `Semantics(label: rating.words, excludeSemantics: true)` round the row, the label worked out from the shown values; a `TextButton` with a 2 pixel focus outline through its own `style` (FL-430) | R1, R2, R3 |
| `good-hidden-pieces` | Material | The bar row replaced the Compose reference's other way | `MergeSemantics` round `Semantics(label:)`, each of the four pieces, the bar included, in `ExcludeSemantics` | R1, R2 |
| `good-stars` | Widgets layer | The star row replaced | `Semantics(label:, excludeSemantics: true)` round the stars and the two numbers | R1, R2 |

No good example is a custom solution: each gives a name and an exclusion
with documented `Semantics` properties, and builds no control
([custom-solutions.md](../custom-solutions.md#s10-content-group-replacement)).

There is no Cupertino example. The mechanism is `Semantics`, the same
under any design language; Cupertino has no rating and no widget with a
parameter for this, and its activity indicators give nothing to replace
([FL-255](../flutter-limitations.md#fl-255)).

### Bad

| Slug | Variant | Defect | Violates | Fails |
| --- | --- | --- | --- | --- |
| `bad-pieces` | Widgets layer | The star row as it is: the stars are not read, and nothing says what 3.4 and 856 are | R1 | 1.3.1 and 1.1.1, on all three |
| `bad-merged` | Material | The bar row in `MergeSemantics`, the references' "grouped" example: the rating is read with a stray 68 from the bar ([FL-330](../flutter-limitations.md#fl-330)) | R1, R2 | none: not a shown failure of a success criterion; shown for what the user hears (section 3) |
| `bad-not-excluded` | Material | `Semantics(label:)` round the bar row, its pieces not hidden: the rating is read twice, with a stray 68 (FL-330) | R2 | none: not a shown failure of a success criterion; shown for what the user hears (section 3) |
| `bad-hides-control` | Material | The star row and a `TextButton` "Reviews" in one `Semantics(label:, excludeSemantics: true)`: a screen reader cannot find the button; the keyboard still reaches it | R4 | 4.1.2, on all three |
| `bad-stale` | Material | `good-exclude-semantics` with a fixed label: after a review is added the row shows 857, and a screen reader still hears 856 | R3 | 1.3.1, on all three |

What each platform's screen reader hears for each, as measured (section
7): `bad-merged` TalkBack "68.0.", "68,", "Rating: 3.4 / 5 Reviews: 856";
VoiceOver on iOS "Rating: 3.4 / 5 Reviews: 856 68"; the web's tree a
`progressbar` named "Rating: 3.4 / 5 Reviews: 856 68", which VoiceOver on
the web, in Chromium and WebKit, read "Rating: 3.4 / 5 Reviews: 856 68 68%
progress indicator" (recorded 2026-11-27). `bad-not-excluded` the same with
the label first.

Not built:

- **The bar left out of the hiding** (probe p08, the regression the
  Compose reference warns of): the replacement gets the value 68, and a
  progress bar role on Android and the web, as `bad-not-excluded` but with
  the words once. In FL-330; one
  example of a stray 68 from a merge with a label is enough.
- **A label and a value** (p11): `Semantics(label: 'Rating', value: …)`.
  On Android the value is read before the label ("3.4 out of 5 stars, 856
  reviews, Rating", [FL-039](../flutter-limitations.md#fl-039)'s joining
  of value, label, and hint), and on the web it is appended to the name
  ([FL-037](../flutter-limitations.md#fl-037)). The references give a
  name only.
- **An image role** (p12): S02 `good-chart` gives a drawing that role.
- **`CustomPainter.semanticsBuilder`** (p16, p17): gives a painting nodes
  of its own, one or a node per bar; it replaces nothing, and a chart's
  alternative is S02's.
- **A weather summary and a badge** (p18 to p21): read as the rating is,
  piece by piece, and replaced the same way.
- **A custom action on the replacement** (p14): not on the web (FL-022),
  and I05's subject.
- **A `ListTile` whose subtitle is a replacement** (p15): one button named
  by the title and the replacement on every platform, and worked by every
  input tried. It is the way to keep a control in a replaced composite
  (R4) when the whole composite is the control; C18 `good-tappable` is
  that pattern.

`TestId` is a `MergeSemantics`, so it is put round the add buttons only.
Each replacement has `Semantics(identifier:)` on its own node (probe p25:
the identifier lands on the replacement on every platform); `bad-pieces`'
two texts are found by their text.

## 6. Assertions by layer

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Good, in light and dark: the four guidelines. Each good replacement: one node labelled with the words, no value, no role, no action, no focus; no node on the screen is a progress bar or has the value 68, and none is labelled with a piece ("Rating:", "3.4 / 5", "Reviews: 856", "3.4", "(856)"). The example's nodes after the "Example" heading, exactly: `good-exclude-semantics` the words and the button (button, tap); `good-hidden-pieces` and `good-stars` the words alone. `good-exclude-semantics`: after a tap, the tap action, Tab and Enter, and Tab and Space (each from a fresh open) the row shows "Reviews: 857" and the replacement says "… 857 reviews"; Tab goes Back, the button, Back, never to the rating; the button's style draws a 2 pixel outline in the text colour, 3:1 or more on the page, only while it has focus, and the text contrast guideline holds with focus on it. `good-stars`: the stars in the theme's primary colour, 3:1 or more on the page (6.12:1 light, 10.90:1 dark). Every example at 200% text on 320 by 640: no overflow, no text at its line limit or cut short, nothing off the screen. Bad: `bad-pieces` exactly "3.4" and "(856)", none naming stars, "out of", reviews, or a rating, and `good-stars` replaced in the same test; `bad-merged` exactly one node, the pieces, value 68, role progress bar; `bad-not-excluded` one node, the words then the pieces, value 68, role progress bar; `bad-hides-control` exactly the words and "Reviews opened: 0", no node "Reviews", no button but Back, the second Tab putting keyboard focus on the Reviews button with no node focused, Enter then running it, and a tap where it is drawn running it again; `bad-stale` after a tap "Reviews: 857" shown and the replacement still the words with 856, and `good-exclude-semantics` following the same tap in the same test. The tests run as Android |
| L3 web | Good: the replacement one element with the identifier, holding the words, with no `role`, `aria-label`, `aria-valuenow`, or `tabindex`; one element with the words on the page; no `progressbar`; no element whose own text or label is a piece. The example's elements after the "Example" heading, exactly: `good-exclude-semantics` a text and a button, `good-hidden-pieces` and `good-stars` the text alone (and no button but Back). Tab goes Back, then the button. After a click, a DOM click, Tab and Enter, and Tab and Space (each from a fresh load) the replacement says 857 reviews. Bad: `bad-pieces` exactly the texts "3.4" and "(856)", no image, none naming stars, "out of", reviews, or a rating; `bad-merged` exactly one `progressbar`, `aria-label` the pieces and " 68", `aria-valuenow` 68, named by Chromium "Rating: 3.4 / 5 Reviews: 856 68", with the identifier; `bad-not-excluded` the same with the words first; `bad-hides-control` exactly the words and the count, one button, Back, no element "Reviews"; after two Tabs DOM focus is on Back, and Enter runs Reviews and leaves the screen open; in another load one Tab and Enter leave the screen (Enter on Back, the positive control); `bad-stale` after a click the replacement still says 856 for 1.5 seconds and nothing says 857, and in another load `good-exclude-semantics` says 857 within 1.5 seconds of the same click. Each screen shows the title and lines the VoiceOver judge expects above its heading. The judge (`web_tests/vo/s10_vo_walks.js`, S08's) on made-up walks |
| L3 Android | Good: the replacement a `View` named by the words, no range, not clickable, no child; no node on the screen named by a piece, a `ProgressBar`, or with a range; the example's named nodes after the "Example" heading, exactly the words and, for `good-exclude-semantics`, the clickable `Button`. `good-exclude-semantics`: the click action (what TalkBack's double tap performs), a tap at the button's centre, and Tab then Enter (each from a fresh launch) make the replacement say 857 reviews, with no piece or bar after. Bad: `bad-pieces` exactly two `View`s, "3.4" and "(856)", none naming stars, "out of", reviews, or a rating; `bad-merged` one `ProgressBar` named "68, " and the pieces, range current 68, and nothing else; `bad-not-excluded` the same with the words after the 68; `bad-hides-control` exactly the words and the count, no node "Reviews", no clickable node but Back, and from a fresh launch each, one to three Tabs then Enter: one of them runs Reviews with no node named Reviews focused, and one leaves the screen (Back); `bad-stale` after the click action the name stays the words with 856 for two seconds and no node says 857, and `good-exclude-semantics` follows the same action in the same test. Run once at CI's 320 by 640 at 160 dpi as well |
| L3 iOS | Good: the replacement a static text labelled with the words, no value, the only element with that label, no element labelled with a piece; no button but Back, and the add button for `good-exclude-semantics`. `good-exclude-semantics`: after a tap, and after two Tabs and Return (no modifier; the probe found the first Tab on Back), the replacement says 857. Bad: `bad-pieces` elements "3.4" and "(856)", none naming stars, "out of", or reviews but the screen's own title and defect, no image; `bad-merged` labelled with the pieces, value "68"; `bad-not-excluded` labelled with the words and the pieces, value "68"; `bad-hides-control` labelled with the words, no element "Reviews", no button but Back, and two Tabs and Return running Reviews; `bad-stale` after a tap still 856 for two seconds, nothing labelled with 857, and `good-exclude-semantics` following the same tap in the same test. XCUITest cannot read traits or Flutter's focus |
| L4 TalkBack | Focus moved to each node by action, each row judged as whole utterances (`== A / B` in `said()`, `tool/talkback.py`: the row's utterances exactly these, in order, TalkBack's usage hint once at the end allowed), as the committed transcript holds them: each good replacement exactly the words; `good-exclude-semantics`' button exactly "Add a 5-star review", "Button"; after the click action on it, with the witness showing 857 first, the replacement exactly "… 857 reviews". Bad: `bad-pieces` exactly "3.4", and exactly "(856)"; `bad-hides-control` exactly the words, and exactly "Reviews opened: 0"; `bad-stale` exactly the words, the button, and, after the click action and the witness showing 857, exactly the words with 856. `bad-merged` and `bad-not-excluded` cannot be written whole, because their last utterance holds "3.4 / 5" and the form splits at every "/": their first utterance must be exactly "68.0." (`^= A`), the row must hold the pieces (and for `bad-not-excluded` the words before them) in one utterance, and "out of 5 stars" (`bad-merged`) and "Image" must not be said. The rows and their mutations (the speech said twice, an extra role, a wrong number, each neighbour's label added before, after, or inside) are tested in `tool/test_talkback.py` (`S10WholeUtterances`). Each walk is judged whole (`walk_strictly`; S10 is in its `STRICT` set): a walk with any wrong reading fails for good, and only a walk shown to be incomplete is walked again, up to three walks, every walk in the transcript. No row is declared silent |
| L4 VoiceOver iOS | Every utterance of the screen (C03's walk), tied to its screen: the stops before the "Example Heading" must be exactly this example's title with "Heading", its description, and a bad example's defect (a stop of 64 characters or more as the service cuts it), and only then is what follows taken as the content, compared as a whole list: `good-exclude-semantics` the words, "Add a 5-star review Button", and after a tap on the button (VoiceOver off, the witness showing 857 first) the words with 857; `good-hidden-pieces` and `good-stars` the words (the same content, told apart by their titles and descriptions); `bad-pieces` "3.4", "(856)"; `bad-merged` "Rating: 3.4 / 5 Reviews: 856 68"; `bad-not-excluded` the words and " Rating: 3.4 / 5", cut by the service at 64 characters (a `.cut` stop: its first 63 characters, and the utterance exactly 64 long); `bad-hides-control` the words and "Reviews opened: 0"; `bad-stale` the words and the button, and after a tap (the witness showing 857) still the words with 856. The identification judge is tested on made-up walks (`testTheIdentificationJudgeTiesACaptureToItsScreen`): another example's title or description with the same content, a missing, empty, half, or extra identification, a missing defect, no heading, and a walk that did not reach the end are each refused. Every expected utterance is under 64 characters; the test refuses one that is not |
| L4 VoiceOver web | Each screen walked from Back with the cursor's position kept at every stop (`walkWithPositions`, a copy of S08's) and judged against the whole screen in order (`judgeExampleWalk` in `web_tests/vo/s10_vo_walks.js`, a copy of S08's judge), in Chromium and WebKit, no runner retries. A wrong reading fails for good and is looked for first; any stop past the expected end fails for good, an empty one included (the bounds check comes before the empty check); a walk that reached the end short is wrong; a walk with an empty phrase and nothing wrong is a failed capture, walked again, at most three walks, every try logged, and an empty reading never passes. VoiceOver's help message ("You are currently on ...") is left out only when it is at the same position as the real stop before it and names that stop's spoken role (`spokenRole`, from the reading's role part, never from a name: extended for S10 to a text and a progress indicator); any other help message is a stop, and fails. The help rule is tested only on made-up walks: no S10 recording has been made. `good-exclude-semantics` and `bad-stale` are walked again after a mouse click on the add button. The lists (`EXPECTED_STOPS`, `EXPECTED_AFTER_ADDING`) were written as predictions before any S10 recording; the recording of 2026-11-27 read every one exactly, in both browsers, on the first walk (section 7). The judge's cases, and its mutations (a help message at a new position, naming another role, after an empty stop, with positions of the wrong length, two in a row, after a heading whose name has a role word), are in the web tree spec |

## 7. What the build found (Flutter 3.47.5)

The probe that came first is in
[evidence/probes/s10](../evidence/probes/s10/README.md): twenty-five
fixtures on every platform, with each screen reader.

- **`Semantics(label:, excludeSemantics: true)` replaces the group with
  one node, on every platform** (p03, p10, `good-exclude-semantics`,
  `good-stars`): the widget tests' one node with the label and nothing
  else; on the web a text element holding the words, with no role; on
  Android a `View` named by the words; on iOS a static text. TalkBack and
  VoiceOver on iOS read the words alone. `Semantics(label:)` round
  `ExcludeSemantics` (p04), and `MergeSemantics` round `Semantics(label:)`
  with every piece in `ExcludeSemantics` (p05, `good-hidden-pieces`),
  give the same node.
- **A merged progress indicator puts its value, and its role where the
  platform has one, on the group**
  ([FL-330](../flutter-limitations.md#fl-330), new; p02, p06 to p08;
  `bad-merged`, `bad-not-excluded`). Web: one `progressbar` named by the
  texts and " 68". Android: one `ProgressBar` named "68, " and the texts,
  read by TalkBack "68.0.", "68,", then the texts, with no role word
  within its six-second dwell. iOS: one static text, value "68" (no role,
  FL-256), read "Rating: 3.4 / 5 Reviews: 856 68". A `Semantics(label:)`
  round the pieces is not a label over them: it merges them into its node
  (p06).
- **A replacement that takes in a control hides it from every screen
  reader, and the keyboard still reaches it** (p13, `bad-hides-control`).
  On the web, after the Tab that reaches the hidden button, DOM focus
  stays on Back, and Enter runs Reviews and not Back. On Android the node
  reported as focused stays Back. On iOS two Tabs and Return, and a tap
  where the button is drawn, run it. Where a keyboard user is also a
  screen reader user, focus is on a control their screen reader cannot
  see; what VoiceOver or TalkBack says then was not measured.
- **A label worked out from the values follows them; a fixed one does
  not** (p22, p23), on every platform.
- **Stars with no label give nothing** (p09, `bad-pieces`): every platform
  exposes "3.4" and "(856)" and nothing else; the icons are excluded by
  `Icon` itself when it has no `semanticLabel`.
- **Custom actions** on a replacement (p14): Android has the action, and
  TalkBack says "Actions available"; the web has none in the DOM; iOS
  VoiceOver reads "Actions availab" (cut), and no key or tap ran it
  ([FL-022](../flutter-limitations.md#fl-022), extended).
- **A change of a node's identifier alone is not sent to the platform**
  ([FL-331](../flutter-limitations.md#fl-331), new; source read, the web
  measured): met while building `bad-stale`'s test witness (section 7,
  skips). A test finding: nothing a user meets.
- **No Flutter counterpart of `accessibilityRepresentation`**
  ([FL-025](../flutter-limitations.md#fl-025), extended; the `Semantics`
  API read, nothing measured).
- **VoiceOver on the web, recorded 2026-11-27**
  ([evidence/S10/voiceover-web.md](../evidence/S10/voiceover-web.md), by
  the principal): 20 tests passed, every walk complete on its first try in
  Chromium and WebKit, and the two browsers read the same. Every list
  written as a prediction before the recording was read exactly: each
  replacement as its words alone; `bad-pieces` "3.4", "(856)";
  `bad-merged` "Rating: 3.4 / 5 Reviews: 856 68 68% progress indicator",
  the bar's value twice, once in the name ([FL-037](../flutter-limitations.md#fl-037))
  and once as a percentage, as C26's bars were read; `bad-not-excluded` the
  same after the words; `bad-hides-control` the words and the count, no
  button; the button "Add a 5-star review button"; after a review was added
  with a mouse click, `good-exclude-semantics` "… 857 reviews" and
  `bad-stale` still "… 856 reviews". No help message was captured in any
  walk, so the judge's help rule did not come into play and stays tested
  on made-up walks only.
- **The first TalkBack recording failed on its own walk**
  (`docs/evidence/probes/s10/talkback-round1-fail.md.txt`): every row was
  read as expected but `bad-stale`'s second, which put TalkBack focus back
  on the replacement it was already on, after the click action on the
  button; TalkBack said nothing for it in all three walks, so each was
  incomplete. The walk now moves focus to the button between the two
  readings, as `good-exclude-semantics`' walk did, whose second reading
  ("… 857 reviews") was heard in every walk. Why TalkBack was silent was
  not measured.
- **Colours**: the stars, in the theme's primary colour, are 6.12:1 on
  the page in light mode and 10.90:1 in dark (widget test). The bar is
  Material's default, whose colours C26 measured (its track 1.22:1 and
  2.00:1 on the page); "3.4 / 5" says the same in text, so no 1.4.11
  failure is claimed.

Skips and what they give up, in the tests:

- The widget tests run as Android (`kIsWeb` false): what the web engine
  makes of a node is seen only in the web tests.
- The example's nodes are compared only where they have a label, a value,
  or an action (widget tests), a name or a range (Android), or a role, a
  label, or text of their own (web): a container with none of these is
  left out. Every node a screen reader stops on in the probe had one.
- On Android the screen is read from the top and then scrolled a step at
  a time to its end, each node kept once: two nodes with the same name,
  class, and identifier would count as one; no example has two.
- "No piece is exposed" is checked against the five piece texts by exact
  label (widget tests, Android, iOS) or by an element's own text or label
  (web); a piece reworded would not be caught by that check, and is caught
  by the exact lists of each example's nodes.
- `bad-stale`'s "still 856" is judged only once a witness shows that the
  row reached 857 (Codex, first review: the test had checked words that
  were already there, so a click that did nothing passed). The row's text
  is in the subtree that the replacement hides, and on the web the canvas
  cannot be read, so the example has a test-only witness: an empty node,
  one pixel square, after the add button, whose identifier says how many
  reviews the row shows (`s10-<slug>-shows-856`, then `-857`), in
  `good-exclude-semantics` and `bad-stale`. It has no label, value, or
  action and no text; the tree tests' lists of each example's nodes are
  unchanged (they leave out nodes with none of these), and the web tree
  spec checks it has no role, name, value, text, or tab stop. A new node is
  made for each count (its key), because a change of an identifier alone
  is not sent to the platform ([FL-331](../flutter-limitations.md#fl-331),
  new: an identifier changed in place stayed "…-856" on the web,
  `docs/evidence/probes/s10/witness_probe.txt`). Every layer waits for the
  witness's 857 before judging the replacement (widget tests, web tree
  spec, Android, iOS, TalkBack's and VoiceOver's `-after` rows), and each
  has a control in the same test or spec with the activation left out, in
  which the witness never says 857, so the gate cannot pass. Then
  "still 856" is checked for two seconds more (Android, iOS) or at once
  (web, widget tests), with `good-exclude-semantics` following the same
  press as the positive control. The witness node is reachable by no
  screen reader in the transcripts recorded since (section 7); the web
  VoiceOver recording is to be made again with it in place.
- The iOS tree tests cannot see Flutter's focus: the key tests rely on the
  probe's finding that the first Tab is on Back and the second on the next
  control; which value changed is what shows the key reached it.
- On Android, `bad-hides-control`'s key test tries one, two, and three Tabs
  from a fresh launch each, because the first Tab can be used up leaving
  touch mode; it requires one try to run Reviews and one to leave the
  screen, and does not require which.
- The TalkBack walk moves focus to each node by action and does not see a
  stop it was not told of; the Android tree test checks the nodes and
  their order. `bad-merged`'s role word is not judged: the probe heard
  none within the dwell. `bad-merged`'s and `bad-not-excluded`'s rows are
  not judged as whole utterances (their last utterance holds "3.4 / 5",
  which the `==` form cannot hold): an utterance added after the pieces,
  other than the forbidden "Image", is not caught there; the tree test and
  the iOS and web walks read those nodes whole.
- The web VoiceOver judge leaves out a help message only when the walk's
  positions tie it to the real stop before it and its role matches that
  stop's spoken role. A reading with no role part is taken as spoken text
  (`spokenRole` gives "text"), and VoiceOver's help wording for a text
  element and a progress indicator is assumed to follow the list's and the
  button's: no recording here has heard either. The rule is tested only on
  made-up walks.
- The iOS VoiceOver walk is C03's: it ends where moving on gives the last
  utterance again, twice, and so gives up two neighbouring elements that
  VoiceOver reads alike; no example has two. Its content is taken only
  once the stops before the "Example Heading" are exactly the example's
  title, description, and defect (Codex, first review: `C03Walk.content`
  alone kept everything after the last heading, so `good-hidden-pieces`'
  capture would have passed for `good-stars`'). The title, description,
  and defect are as other techniques' transcripts show the screen
  (`docs/evidence/S03/voiceover-ios.md`); the judge is in S10's own test
  file, and no shared helper changed. `bad-not-excluded`'s
  utterance is longer than the service's 64 characters: the test checks
  its first 63 and that it was cut, and the "68" after the cut is checked
  in the tree test only.

**Not done yet.** VoiceOver's help message on the web for a text element
or a progress indicator, which no recording here has heard: the judge's
wording for it stays assumed. What VoiceOver and
TalkBack say while keyboard focus is on `bad-hides-control`'s hidden
button. VoiceOver's own activation on iOS, which XCUITest cannot make.
The actions rotor for p14 on iOS. A native Android or SwiftUI composite
for comparison (no limitation here rests on one). Right-to-left text;
dark mode on a device.

## 8. Decisions

The principal's, on 2026-11-27, in review of the build. They are the
principal's and not the owner's, who may overrule them.

1. **iOS stays "applies".** S10's requirement is a text alternative for a
   group, and the good examples meet it on iOS. The iOS reference's wider
   subject, a drawn control given a native control's role, value, and
   actions (R5), is outside S10 and stays in
   [FL-025](../flutter-limitations.md#fl-025). Where S14 `good-rating`
   and F10 `good-custom` are cited for it, they are flagged custom solutions, tested in isolation and not vetted by a real-world example;
   neither is recommended.
2. **`bad-merged` and `bad-not-excluded` stay as bad examples, with no
   WCAG failure claimed** (section 3). Each is not a shown failure of a
   success criterion; it is shown for what the user hears, a stray 68
   from the bar, as C03's `bad-vague-text` is shown as poor practice.

## 9. What is handed on

- **S12 Hiding content**: `excludeSemantics: true` hides a control and
  leaves it in the keyboard's order (`bad-hides-control`); on the web DOM
  focus stays where it was.
- **S09 Content grouping**: a labelled `Semantics` merges what is under
  it, and a merged progress indicator brings its value and role
  (FL-330).
- **I05 Custom actions**: the p14 measurements in FL-022.
