# Spec: C04 Links inline with text

Status: Draft 1 (2026-11-21), written with the build. Wave 2, links and
simple components. Flutter pin: 3.47.5.

Links inside a sentence. A link on its own is
[C03 Stand-alone link](C03-stand-alone-link.md), which this entry builds
on: the same addresses in the app, the same `linkUrl`, and the same note on
`url_launcher` (D30). How big a link must be is V13 (a link in a sentence is
exempt from 2.5.8); how its focus is shown, V14.

## 1. Rule

Each link in a sentence is a stop of its own, with the link role where the
platform has one and a name that, with its sentence, says where it goes. It
is read in its place in the sentence, is reached and followed by touch, by
the keyboard, and by a screen reader, and is told from the words round it
by more than colour.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies | Applies | Applies |

Android has no link role that a node can declare, and TalkBack says no role
for a Flutter link ([FL-220](../flutter-limitations.md#fl-220)); the links
say what they are in their double-tap hint, as in C03.

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [2.4.4 Link Purpose (In Context)](https://www.w3.org/TR/WCAG22/#link-purpose-in-context) | The link's name, alone or with its sentence, says where it goes |
| [1.4.1 Use of Color](https://www.w3.org/TR/WCAG22/#use-of-color) | A link in running text is told from the text round it by more than colour |

For 2.4.4, text in the same sentence is programmatically determined link
context ([G53](https://www.w3.org/WAI/WCAG22/Techniques/general/G53); the
Understanding document: "text in the same sentence, paragraph, list item,
or table cell"). In Flutter the sentence's words and its links are sibling
nodes of one paragraph node on every platform (section 7), so the sentence
is that context. A link whose purpose is "ambiguous to users in general" is
exempt, which is why there is no vague-text example here (section 5).

For 1.4.1, the Understanding document lists
[G183](https://www.w3.org/WAI/WCAG22/Techniques/general/G183) (a 3:1
contrast between the link's colour and the text round it) as sufficient,
and [F73](https://www.w3.org/WAI/WCAG22/Techniques/failures/F73) as the
failure: a link in body text "visually evident" by colour alone. Read
against both on 2026-11-21: F73 passes a hue difference with 3:1 or more
in lightness, and says a cue that comes only on hover or focus does not
count; G183's procedure is the contrast check alone and asks for no hover
or focus cue (it suggests an underline as advice). An underline passes
F73 whatever the colour. The good links are underlined; `bad-colour-only`
has no underline and a colour under 3:1 against the words.

Other criteria the examples touch are named where they fail: 2.1.1
Keyboard (`bad-text-span`), 1.3.2 Meaningful Sequence (`bad-out-of-order`),
and 4.1.2 Name, Role, Value (`bad-merged`).

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | Each link has the link role and is exposed on its own, with its name | [Android View: Links Inline with Text](https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/componenttypes/LinksInlineWithText.md) and [Android Compose: Links Inline with Text](https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/components/LinksInlineWithText.md) (4.1.2: name, role, and value exposed), [APG Link](https://www.w3.org/WAI/ARIA/apg/patterns/link/), [MDN `a`](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/a) (`href` needed for the link role) |
| R2 | The link's name, with its sentence, says where it goes | [iOS Links](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/Links.md) ("unique and specific label"), [G53](https://www.w3.org/WAI/WCAG22/Techniques/general/G53) |
| R3 | A keyboard reaches each link, and Enter follows it | Android Compose (inline links "focusable and selectable with a keyboard"; `ClickableText` avoided for its keyboard handling), iOS Links (Markdown and `AttributedString` links are not reached by Full Keyboard Access; avoid inline links until that is fixed), APG Link (Enter) |
| R4 | The link is read in its place in the sentence | Android Compose (without merging, links take focus before the app bar, against 1.3.2 and 2.4.3) |
| R5 | A link in text is told from the text round it by more than colour | iOS Links (underline inline links), Android Compose (primary colour with an underline), F73, G183 |
| R6 | The link's colour meets text contrast in light and dark | iOS Links (the default link colour is under 4.5:1; use one with enough), Android Compose (TalkBack's links menu shows the app's link style, so both themes must have enough contrast) |
| R7 | Following a link has one result | C03 R7; MDN `a` |

How the reference repositories expose inline links differs from what is
built here, and the difference is recorded, not copied:

- Android View puts the links in one `TextView` with `URLSpan`s and
  `LinkMovementMethod`; TalkBack reads the text as one stop and offers its
  links in its links menu. Android Compose merges the text into one node
  for the same reason. A Flutter sentence has no such menu: its links are
  nodes of their own (section 7), and merging them (`bad-merged`) loses the
  second link.
- iOS says SwiftUI's inline links cannot be reached by the keyboard. The
  Flutter good examples can.

Flutter references for the mechanisms used:

- [`WidgetSpan`](https://api.flutter.dev/flutter/widgets/WidgetSpan-class.html), [`TextSpan.semanticsIdentifier`](https://api.flutter.dev/flutter/painting/TextSpan/semanticsIdentifier.html), [`TextSpan.recognizer`](https://api.flutter.dev/flutter/painting/TextSpan/recognizer.html)
- [`OrdinalSortKey`](https://api.flutter.dev/flutter/semantics/OrdinalSortKey-class.html), [`SemanticsProperties.link`](https://api.flutter.dev/flutter/semantics/SemanticsProperties/link.html), [`linkUrl`](https://api.flutter.dev/flutter/semantics/SemanticsProperties/linkUrl.html)
- [`MediaQuery.withNoTextScaling`](https://api.flutter.dev/flutter/widgets/MediaQuery/MediaQuery.withNoTextScaling.html)
- [`InkWell`](https://api.flutter.dev/flutter/material/InkWell-class.html), [`FocusableActionDetector`](https://api.flutter.dev/flutter/widgets/FocusableActionDetector-class.html), [`DoNothingAndStopPropagationIntent`](https://api.flutter.dev/flutter/widgets/DoNothingAndStopPropagationIntent-class.html) (C03's `BrowserKeys`)
- [`CupertinoColors.systemBlue`](https://api.flutter.dev/flutter/cupertino/CupertinoColors/systemBlue-constant.html)

Radix comparison bar: Radix has no link primitive; the bar is the native
`<a href>` inside a `<p>`, as MDN and APG describe it.

### Where the links go

As in C03: the SDK cannot open an address in the browser app off the web
(that takes a plugin, D30), so every link goes to a page of the app. The
first link, "links in text", goes to this technique's page, `/t/C04`; the
second, "stand-alone links", to C03's, `/t/C03`. Off the web the app opens
the page with `Navigator`; on the web the link's `href` is `#/t/C04` or
`#/t/C03`, and the browser follows it while the app does nothing
(`followLink`, C03's `BrowserKeys`).

## 5. Examples

Every good example is the sentence "Read about [links in text] and
[stand-alone links] first." built by `LinkSentence`: each link a
`WidgetSpan`, with FL-413's workaround (an identifier on the first words,
and a sort key between the runs round each link), the link's text in
`MediaQuery.withNoTextScaling` (FL-241), underlined.

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-material` | Material | Links in the theme's primary colour | `Semantics(link: true, linkUrl:, onTapHint: 'open link')` round an `InkWell` (`MaterialInlineLink`); C03's `BrowserKeys`; a 2 pixel ring outside the link when it has keyboard focus | R1 to R7 |
| `good-cupertino` | Cupertino | Links in Cupertino's blue | `KeyboardInlineLink`: `FocusableActionDetector` (Enter and Space off the web only) round `Semantics(link: true, linkUrl:, onTapHint:)` and a `GestureDetector`; the high-contrast variant of `CupertinoColors.systemBlue`, as the plain one is 4.02:1 on white (FL-242) | R1 to R7 |
| `good-custom` | Widgets layer | Links with no Material widget | `KeyboardInlineLink` in the theme's primary colour | R1 to R7 |

Cupertino has no link widget, inline or not, and `CupertinoButton` stays a
button inside `Semantics(link: true)` (FL-221). So `good-cupertino` is the
widgets-layer link in Cupertino's colour; what makes it Cupertino is the
colour, and the spec says so rather than claim more.

### Bad

| Slug | Defect | Violates |
| --- | --- | --- |
| `bad-text-span` | A `TextSpan` with a `TapGestureRecognizer`, the SDK's own link in text: a keyboard cannot reach it. It opens a page of its own, `TextSpanPage`, which nothing else opens | R3 (and R1 on Android and the web: no address, FL-032) |
| `bad-out-of-order` | The links as `WidgetSpan`s with no workaround: the sentence is read without its links, then the links ([FL-413](../flutter-limitations.md#fl-413)) | R4 |
| `bad-colour-only` | No underline; the links' colour, the theme's primary, is under 3:1 against the words round them | R5 |
| `bad-merged` | `MergeSemantics` round the sentence, which `TestId` also is: the sentence and both links are one link, with the first link's address and action | R1 |

What each fails, by platform, as the criteria are written (section 7 has
the measurements):

| Example | Android | iOS | Web |
| --- | --- | --- | --- |
| `bad-text-span` | 2.1.1: Tab never reaches the link, and no key opens its page, which nothing else opens | 2.1.1: no key opened its page (one Tab, then Enter or Space; in the probe one to three Tabs, then Enter) | 2.1.1: Tab never reaches it, and no key opens its page |
| `bad-out-of-order` | 1.3.2: the sentence node is "Read about and first.", its links after it | 1.3.2: VoiceOver reads "Read about and first." and then the links | 1.3.2: a group named "Read about and first." holding the links |
| `bad-colour-only` | 1.4.1 (F73) | 1.4.1 (F73) | 1.4.1 (F73) |
| `bad-merged` | 4.1.2: the second link is not exposed as a link of its own; TalkBack's double tap follows the first | 4.1.2: the second link is not exposed as a link of its own; VoiceOver reads one link (what its double tap opens is recorded, not asserted: no page, in the probe) | 4.1.2: one `<a href="#/t/C04">`; a click anywhere on the sentence, and Enter after either Tab, follow the first link |

`bad-colour-only`'s links are in the theme's primary colour of each mode:
2.66:1 against the words in light, 1.32:1 in dark, and 6.12:1 and
10.90:1 against the page, so its one defect is the missing cue.

No example has vague link text. C03's `bad-vague-text` covers a link that
says "Read more". In a sentence, the sentence is the link's context, and a
link whose sentence does not say where it goes either is "ambiguous to
users in general", which 2.4.4 exempts; a failure as written would need the
context to be visible and not programmatic, which a Flutter sentence does
not give (its words and links share a parent on every platform). An
example that could not be shown to fail was not built.

`bad-merged` has no `TestId`: it is the defect. Its sentence carries a
plain `Semantics(identifier:)` under the `MergeSemantics`. The good
examples' links carry their identifiers on the container that has the sort
key, because `TestId`'s `MergeSemantics` drops the sort key (FL-413).

## 6. Assertions by layer

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Every example, good and bad: at 200% text on a 320 by 640 screen, no layout overflow, no text that hits its line limit, no text-only paragraph shorter than its lines, and nothing wider than the screen. Good, in light and dark: the four guidelines; each link underlined, with 4.5:1 against the page. Good: each link a node of its own with the link flag, its address, its name, no button flag, a tap action, the tap hint, and the sort key `n - 0.5`; exactly two link nodes; the sentence read "Read about ", the first link, " and ", the second link, " first." at 800 by 640 and 320 by 640 at 100% and 200% text; a tap and the tap action each open the link's page, and one Back brings the example back; Tab goes Back, first link, second link; Tab to each link, then Enter or Space, opens its page; the focus ring shows on the focused link only, in the page's text colour (3:1 or more on the page), in light and dark, and goes when focus leaves; at 100% and 200% text the links' line height on screen is the words' (FL-241's fix), with the same font size. Bad: `bad-text-span`'s link has the link flag, no address, no focus, and is read in its place; four Tabs never focus it; its tap action and a tap on its words open `TextSpanPage`; Tab stops only on Back, and Enter, then Space, there open the technique's page and not `TextSpanPage`. `bad-out-of-order`: the sentence's label without the links, then the two links. `bad-colour-only`, light and dark: no underline, the same weight and style as the words, under 3:1 against them and 4.5:1 or more against the page. `bad-merged`: one link node, the whole sentence, the first link's address; its tap action opens the first link's page; the keyboard still reaches the second link (positive control). On the SDK alone: FL-241 (a `Text` in a `WidgetSpan` at 200% is twice the height of the words, and `withNoTextScaling` makes it the same) and FL-242 (`CupertinoColors.link` and `systemBlue` between 4:1 and 4.5:1 on white). The tests run as Android, so the web-only code (`followLink` doing nothing, `BrowserKeys`, `KeyboardInlineLink`'s empty actions) is not run here |
| L3 web | Good: two `<a href>` with names, `#/t/C04` and `#/t/C03`, nothing inside them a button; two links and one button (Back) on the screen; the sentence's elements in the page's order: words, link, words, link, words; Tab goes Back, first link, second link; for each link: a click, a DOM click with no pointer events, and Tab then Enter each open its page once in this tab; Space does not follow it, with Enter in the same load as the positive control; Command- or Ctrl-click opens it in a new tab and leaves this one. Bad: `bad-text-span` an `<a>` with no `href` and no `tabindex`, no link found by role, skipped by Tab with Back reached as the positive control, a click opening `TextSpanPage`; Tab stops only on Back, and Enter, then Space, there open the technique's page and not `TextSpanPage`. `bad-out-of-order`: a group named "Read about and first." holding the two links. `bad-merged`: one link, named by the whole sentence, `href="#/t/C04"`; a click where the second link's words are drawn opens C04's page; Tab stops on the one element twice, and Enter then opens C04's page. `bad-colour-only` cannot be seen here (drawn on the canvas) |
| L3 Android | Good: each link an `android.view.View` with its name, its address in a `URLSpan`, a click action labelled "open link", clickable and focusable; the sentence's node holds "Read about ", the first link, " and ", the second link, " first.", in that order; two clickable nodes but Back; for each link, `ACTION_CLICK`, a tap, and Tab then Enter (the second link one Tab after the first) each open its page, and one Back brings the example back. Bad: `bad-text-span` a `Button` with no address, in its place, never focused by six Tabs with Back focused as the positive control, its click action opening `TextSpanPage`; Tab to Back and Enter, then Space, open the technique's page and not `TextSpanPage`. `bad-out-of-order`: the sentence's node named "Read about \n and \n first.", holding the two links. `bad-merged`: one `View` named by the whole sentence, with one `URLSpan`, the first link's, no children, the only clickable node but Back; its click action opens C04's page. `bad-colour-only` cannot be seen here |
| L3 iOS | Good: each link of element type link with its name; two links and no button but Back; the words as text; a tap on each link, and two or three Tabs then Enter, open its page once. Bad: `bad-text-span` a link that a tap follows to `TextSpanPage`; one Tab then Enter, and one Tab then Space, each take the example off the screen (Back acted) and do not open `TextSpanPage`. `bad-merged`: one link, named by the whole sentence, and no link named "stand-alone links". `bad-colour-only` cannot be seen here; `bad-out-of-order`'s order is in the VoiceOver walk, as XCUITest gives no order |
| L4 TalkBack | What is read with focus moved to each part of each sentence: each word run, and each link with "Double-tap to open link" and no "Button"; `bad-text-span`'s link with "Button"; `bad-out-of-order`'s sentence node without the links' names; `bad-merged`'s one node with the whole sentence |
| L4 VoiceOver iOS | Every utterance after the "Example" heading to the end of the screen, compared as a whole list; for each good link, with the cursor moved forward to it, what is said there and that a double tap opens its page; for `good-material`, that a tap at each link's centre puts the cursor on "first.", with one move back reaching the second link as the positive control (FL-246); for `bad-merged`, what a double tap on the sentence opens, recorded and not asserted |
| L4 VoiceOver web | Every stop of VoiceOver's cursor after the "Example" heading to the end of the screen, compared as a whole list, in Chromium and WebKit, with no retry |

## 7. What the build found (Flutter 3.47.5)

The probe that came first is in [evidence/probes/c04](../evidence/probes/c04/),
with a native comparison on Android.

- **The SDK's own link in text cannot be reached by the keyboard**
  ([FL-240](../flutter-limitations.md#fl-240), new; `bad-text-span`). A
  `TextSpan` with a `TapGestureRecognizer` is read in its place, with the
  link role on iOS, and a tap and a screen reader's activation follow it.
  The source gives it the link flag and the tap action and nothing else: no
  focus node, and no address, so it is a `Button` on Android ("… / Button /
  Double-tap to activate") and an `<a>` with no `href` on the web
  ([FL-032](../flutter-limitations.md#fl-032)). `SelectableText.rich` is
  the same on Android and iOS.
- **A `WidgetSpan` link can be reached, and needs three things.** FL-413's
  workaround, now tested with two links (sort keys 0.5 and 1.5) on every
  layer; without the keys, the probe's widget test shows the order resting
  on where the links land, though C04's own sentence came out right without
  them, so the widget tests check each link's key as well as the order. The
  run counting has a trap: the span with the identifier is a run of its
  own ([FL-413](../flutter-limitations.md#fl-413), extended). And the
  link's text in `MediaQuery.withNoTextScaling`, as a `WidgetSpan` scales
  its widget and the `Text` inside scales again: at font scale 2.0 on the
  emulator the links were 180 pixels tall in 102 pixel lines, and at the
  simulator's accessibility-large 75.7 points in 41
  ([FL-241](../flutter-limitations.md#fl-241), new).
- **A `WidgetSpan` link is one box in the line**
  ([FL-244](../flutter-limitations.md#fl-244), new): a link that does not
  fit moves to the next line, and a long one wraps inside its own box. The
  same words as a `TextSpan` flow on with the text, but its node then
  covers both lines whole, and XCUITest's tap at its centre missed it on
  iOS (probe r09). The examples keep their links short; at 200% on a 320
  pixel screen nothing is cut short or overflows.
- **Merging a sentence loses its second link**
  ([FL-243](../flutter-limitations.md#fl-243), new; `bad-merged`). One
  node, the whole sentence, the first link's address and action, on all
  three platforms. On the web every click on the sentence and Enter after
  either Tab follow the first link; off the web a tap on the second link's
  words still opens it (Flutter's hit test is not merged), so the defect
  there is the screen reader's.
- **On iOS a VoiceOver touch on a link can find the words instead**
  ([FL-246](../flutter-limitations.md#fl-246), new). On the iPhone 17
  screen the good sentences take two lines, and the last run, " first.",
  has one node over both whole lines, over the links. With VoiceOver on, a
  tap at either link's centre put the cursor on "first."; the first
  transcript run, which placed the cursor that way, failed on it, and the
  second probe round (`ios_round2.txt`) found why. The double-tap test now
  moves the cursor forward to each link, which works, and a test of its own
  asserts what a touch finds. No WCAG failure is claimed: swiping, the
  keyboard, and the double tap reach every link. No workaround was found.
- **Native Android text is one TalkBack stop with a links menu** (the
  probe's `TextView` with two `URLSpan`s: "… Double-tap to open link.
  Actions available"), which is what both Android reference repositories
  build. A Flutter sentence is a stop per run of words and per link, and
  offers no menu. Neither is a failure as written; the difference is
  recorded, and the good examples follow the web's model, where each link
  is its own element.
- **Cupertino's link colours are under 4.5:1 on white**
  ([FL-242](../flutter-limitations.md#fl-242), new): `CupertinoColors.link`
  and `systemBlue` are 4.02:1. `good-cupertino` uses `systemBlue`'s
  high-contrast variant, 7.56:1 in light.
- **The theme's primary colour is too close to the text to carry a link
  alone**: 2.66:1 against the body text in light and 1.32:1 in dark, though
  6.12:1 and 10.90:1 against the page. That is `bad-colour-only`.
- **`SelectableText` on the web is an empty, disabled text field**
  ([FL-245](../flutter-limitations.md#fl-245), probe only): its words and
  links are not in the page. No example uses it.
- **`semanticsLabel` on a paragraph with links replaces the links** (probe
  r08): one text node and no link on any platform. Not an example: the
  label is the developer's own choice, and the result is what its
  documentation says it does.
- **UI Automator's swipe is not a TalkBack gesture**: the probe's swipes
  did not move TalkBack's focus. The TalkBack walk moves focus to each part
  by action, and the Android tree test checks the parts' order.
- **The inline-link question of the doc renderer** has an answer: inline
  links can be made reachable on every platform with the SDK, as above, but
  not with the `TextSpan`s the renderer uses. The technique doc says what
  the renderer would need; the renderer, a shared file, is not changed.

Skips and what they give up, in the tests:

- The widget tests run as Android (`kIsWeb` false), so the web-only branch
  of `followLink`, `BrowserKeys`, and `KeyboardInlineLink` runs only in the
  web tests.
- The 200% check measures again only paragraphs with no `WidgetSpan` (a
  paragraph with one needs its placeholders' sizes to be laid out again);
  for the sentences it gives up the "taller than its box" check and keeps
  the line limit, the overflow check, and the right edge.
- The iOS VoiceOver walk is C03's (`C03Walk`): it ends where moving on
  gives the last utterance again, twice, and so gives up two neighbouring
  elements that VoiceOver reads alike, which it would count as one; no
  example has two. Utterances are cut at 64 characters; the longest here,
  `bad-merged`'s, is 58.
- The iOS key tests cannot see Flutter's focus. Which link Enter followed
  is told by the page that opens (the two links go to different pages).
  For `bad-text-span` the test relies on Back being the only control that
  takes focus, which the widget tests, Android, and the web show and the
  probe agrees with (one to three Tabs and Enter never ran a text span
  link's handler): one Tab, then Enter or Space, sent once; the example
  leaving the screen is the positive control. That the link takes no focus
  is not seen directly on iOS.
- The web test of `bad-text-span`'s Tab stops leaves out stops outside
  Flutter's semantics tree (FL-421), which no key can act on in the app.
- TalkBack's walk moves focus to each part by action and does not see a
  stop it was not told of; the Android tree test counts the clickable
  nodes and checks the sentence's parts and their order instead.
- `bad-merged`'s TalkBack check does not require the double-tap hint: in
  the probe TalkBack read the long sentence and no hint within the dwell.
- `talkback.py` walks an element again, up to three walks, when its speech
  fails its checks (a shared tool, unchanged); the transcript lists every
  element that needed it.
- The web's "Space does not follow it" waits one second; Enter in the same
  load is the positive control.
- `bad-colour-only`'s defect is checked in the widget tests only: no tree
  carries a link's colour or underline.

**Not done yet.** Where a TalkBack swipe goes (not automatable here);
TalkBack's links menu, which a Flutter sentence does not offer; a link's
hover cue and visited state; links out of the app (the SDK cannot open
them off the web); a link at the start of a sentence, or two links with
nothing between them; right-to-left text; text scaling on the web; and
what VoiceOver on the web sends when it activates a link (the web tests
send a DOM click in its place).
