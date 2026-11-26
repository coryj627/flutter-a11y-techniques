# Spec: C05 Accordion

Status: Draft 1 (2026-11-21), written with the build. Wave 2, links and
simple components. Flutter pin: 3.47.5.

An accordion is a set of section headers, each a button that shows or hides
its own panel. A disclosure of a single region outside an accordion is C06
Disclosure, a separate entry in the inventory. Tabs are C07 Tabs, and tree
views C21 Tree view. What a button is, is
[C01 Button](C01-button.md); headings are [S05 Headings](S05-headings.md);
how focus is shown, V14.

## 1. Rule

Each header of an accordion is a button whose name is its section's title,
that says whether its section is open or closed, and that is the heading of
its section. Touch, the keyboard (Enter and Space), and a screen reader each
open and close it. A closed section's panel is neither read nor focused; an
open one comes straight after its header, in reading order and in focus
order.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies | Applies | Applies |

On two platforms `Semantics(expanded:)` does not get the state across by
itself:

- iOS: Flutter does not pass the expanded state to iOS at all
  ([FL-260](../flutter-limitations.md#fl-260)). The good examples give iOS
  the state as the header's value as well.
- Android: Flutter passes it from Android 16 (API 36) only
  ([FL-261](../flutter-limitations.md#fl-261)). Not measured below
  Android 16. Before that, by the engine source, the node has no state and keeps only its click label, which
  TalkBack reads "Double-tap to expand" or "to collapse" (heard on Android
  17). The local emulator is Android 17; CI's is API 35, where
  only the source and the tree tests' branch for it speak for what happens.
  Whether Android before 16 is a limitation with no workaround is a
  decision for the owner; the catalog has Android as applying, with a note.

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [4.1.2 Name, Role, Value](https://www.w3.org/TR/WCAG22/#name-role-value) | Each header has a name, a role (button), and a state (expanded or collapsed) that assistive technology can read, and is told of when it changes |
| [1.3.1 Info and Relationships](https://www.w3.org/TR/WCAG22/#info-and-relationships) | A header drawn as a section heading is a heading; a panel's place after its header ties it to that header |

`bad-hidden-panel` also fails criteria outside the entry's two (section 5).

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | The header is a button | [APG Accordion](https://www.w3.org/WAI/ARIA/apg/patterns/accordion/) (the title is in an element with role `button`, required), [Android View Accordion Controls](https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/componenttypes/AccordionControls.md) (a focusable, clickable control), [iOS Accordions](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/Accordions.md) (`DisclosureGroup`) |
| R2 | The header says whether its panel is shown: expanded or collapsed, changed when it is activated | APG (`aria-expanded`, required), iOS Accordions ("VoiceOver users must hear the Expanded and Collapsed state"), Android View (`ACTION_EXPAND` and `ACTION_COLLAPSE`), [Android Compose Accordion Controls](https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/components/AccordionControls.md) (`expand()` and `collapse()`; never the state in the content or state description) |
| R3 | The header is a heading: in APG always, in a heading that holds the button and nothing else; in the Android references when the headers are the screen's section headings | APG (role `heading` round the button, required, with an `aria-level` that fits the page), Android View and Android Compose ("frequently serve as top-level section headings on a screen. If so, be sure to mark them") |
| R4 | The header's name is the section's title | APG (the title is the button's content), iOS Accordions (no `accessibilityLabel` that replaces what is inside), Android Compose (the icon has no description; the state belongs to the row) |
| R5 | Enter and Space open and close it; it is in the Tab order | APG (Enter or Space; Tab moves through every focusable element), Android View (keyboard operation) |
| R6 | A panel is shown only while open, and hidden content is hidden for everyone | Android View (`View.GONE`), Android Compose (the content is composed only while expanded), APG (`aria-expanded` false: the panel is hidden) |
| R7 | The header controls its panel | APG (`aria-controls` to the panel, required) |
| R8 | The click label says what a double tap does: "Expand" or "Collapse" | Android Compose (`onClickLabel`, which "can improve" the experience) |

APG's region role for panels is optional, and is not used here. APG's keys
are Enter, Space, Tab, and Shift+Tab; it lists no arrow keys for an
accordion.

R7 is met on the web while a panel is open, and nowhere else: `aria-controls`
has no counterpart Flutter writes on Android or iOS, and on the web it points
to a panel's element, which exists only while the panel is open
([FL-266](../flutter-limitations.md#fl-266)). Neither criterion as written
needs it: the panel is the next thing after its header.

Flutter references for the mechanisms used:

- [`SemanticsProperties.expanded`](https://api.flutter.dev/flutter/semantics/SemanticsProperties/expanded.html), [`headingLevel`](https://api.flutter.dev/flutter/semantics/SemanticsProperties/headingLevel.html), [`onTapHint`](https://api.flutter.dev/flutter/semantics/SemanticsProperties/onTapHint.html), [`value`](https://api.flutter.dev/flutter/semantics/SemanticsProperties/value.html)
- [`ListTile`](https://api.flutter.dev/flutter/material/ListTile-class.html), [`CupertinoListTile`](https://api.flutter.dev/flutter/cupertino/CupertinoListTile-class.html), [`FocusableActionDetector`](https://api.flutter.dev/flutter/widgets/FocusableActionDetector-class.html)
- The SDK's own accordions, measured and not used for the good examples: [`ExpansionTile`](https://api.flutter.dev/flutter/material/ExpansionTile-class.html), [`ExpansionPanelList`](https://api.flutter.dev/flutter/material/ExpansionPanelList-class.html), [`CupertinoExpansionTile`](https://api.flutter.dev/flutter/cupertino/CupertinoExpansionTile-class.html), [`Expansible`](https://api.flutter.dev/flutter/widgets/Expansible-class.html)

Radix comparison bar: Radix Accordion, which its documentation says follows
APG's accordion pattern: a `Header` that wraps a `Trigger`, set to the
page's heading level. Its keyboard table also has the arrow keys, Home, and
End, to move between headers; APG does not list them, and they are not
covered here.

## 5. Examples

Every example is an accordion of two sections, "Shipping" and "Returns",
both closed when it opens. A panel holds a line of text and a button
("Track a parcel", "Start a return"); the count under the accordion,
"Presses: n", says how often a panel button was pressed, so that a test
can tell a key reached one. The headers are drawn in the theme's title
style, as section headings, except in the two SDK tiles, which keep their
own.

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-material` | Material | Material list tiles as headers | `ListTile(onTap:)` with an arrow, inside `HeaderSemantics`; a 3 pixel focus ring (V14's, as the tile's tint is under 3:1, FL-430) | R1 to R8 |
| `good-cupertino` | Cupertino | Cupertino list tiles as headers | `CupertinoListTile` with a chevron, given focus, Enter, and Space by `FocusableActionDetector` (`KeyboardHeader`; the tile takes none, FL-400), inside `HeaderSemantics`; the title in a `DefaultTextStyle` of its own so that it wraps | R1 to R8 |
| `good-custom` | Widgets layer | Headers from the widgets layer | `GestureDetector` and `KeyboardHeader`, inside `HeaderSemantics` | R1 to R8 |

`HeaderSemantics` is one node, merged by `TestId`: `button: true`;
`expanded: open`; `onTapHint: 'expand'` or `'collapse'`; `onExpand` while
closed and `onCollapse` while open (Android's expand and collapse actions,
R2; Android 16 and later only, FL-261); on iOS only (not
the web), `value: 'collapsed'` or `'expanded'` (FL-260); `controlsNodes`
naming the panel while it is open (FL-266); and the heading, level 3 (the
screen's "Example" is 2): on Android and iOS `headingLevel` on the same
node, and on the web a `Semantics(headingLevel: 3, container: true)` round
it (FL-262). A panel is built only while open, as a node of its own with
an identifier, and its text a node of its own inside it (left to merge, the
text would become the panel's name, and on the web a group's).

Material's `ExpansionTile` and Cupertino's `CupertinoExpansionTile` are not
good examples (`bad-expansion-tile`, `bad-cupertino-expansion-tile`).
`ExpansionPanelList` and `Expansible` have no example of their own: the
first was measured in the probe (FL-267), and the second's default is
`bad-hidden-panel`'s defect.

### Custom solutions

**Custom solution: not vetted by a real-world example.** `good-material`,
`good-cupertino` and `good-custom` are custom solutions. Each is tested here
in isolation, with screen-reader transcripts, but has not been built into a
real app and tested in a user journey. Do not treat them as vetted
techniques. The app shows the label, with each example's reason, on each
of their screens.

They are built by hand because no Flutter accordion widget meets the
requirements through its own parameters: `ExpansionTile`'s header has no
expanded state and, on Android and iOS, no button role
([FL-264](../flutter-limitations.md#fl-264)); `CupertinoExpansionTile`'s
header takes no keyboard focus and has no role or state
([FL-265](../flutter-limitations.md#fl-265)); `ExpansionPanelList`'s
buttons are all named "Expand" or "Collapse" and have no state
([FL-267](../flutter-limitations.md#fl-267), probe only). They are what
was built and measured here, nothing more.

The table is this technique's part of the register of custom solutions,
[custom-solutions.md](../custom-solutions.md).

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-material` | The accordion's state, with each panel built only while open; `HeaderSemantics` (`Semantics(button: true, expanded:)`, a heading, an iOS value, a tap hint, the expand and collapse actions, and `controlsNodes` while open) round a `ListTile`; a focus ring of its own | `ExpansionTile` | No expanded state and, on Android and iOS, no button role ([FL-264](../flutter-limitations.md#fl-264)); no state on iOS ([FL-260](../flutter-limitations.md#fl-260)); a heading that is a button on the web ([FL-262](../flutter-limitations.md#fl-262)); `aria-controls` ([FL-266](../flutter-limitations.md#fl-266)); a faint focus tint ([FL-430](../flutter-limitations.md#fl-430)) | R1 to R8: APG Accordion, iOS Accordions, Android View Accordion Controls, Android Compose Accordion Controls | custom |
| `good-cupertino` | As `good-material`, round a `CupertinoListTile` given focus, Enter, and Space by `FocusableActionDetector`; its title in a `DefaultTextStyle` of its own, so that it wraps | `CupertinoExpansionTile` | No keyboard focus, no button role, and no state ([FL-265](../flutter-limitations.md#fl-265), [FL-400](../flutter-limitations.md#fl-400)); as `good-material` for [FL-260](../flutter-limitations.md#fl-260), [FL-262](../flutter-limitations.md#fl-262), and [FL-266](../flutter-limitations.md#fl-266) | R1 to R8: APG Accordion, iOS Accordions, Android View Accordion Controls, Android Compose Accordion Controls | custom |
| `good-custom` | As `good-material`, round a header from the widgets layer: a `GestureDetector`, and focus, Enter, and Space from `FocusableActionDetector` | None for a drawn control; the SDK's accordions are `ExpansionTile`, `CupertinoExpansionTile`, and `ExpansionPanelList` ([FL-267](../flutter-limitations.md#fl-267)) | As `good-material` for [FL-260](../flutter-limitations.md#fl-260), [FL-262](../flutter-limitations.md#fl-262), and [FL-266](../flutter-limitations.md#fl-266) | R1 to R8: APG Accordion, iOS Accordions, Android View Accordion Controls, Android Compose Accordion Controls | custom |

### What is hand-built

Each piece (all in `examples.dart`), the gap it fills, and where it comes
from:

| Piece | What it does | Gap it fills (measured) | Source |
| --- | --- | --- | --- |
| `Accordion`: the sections' state, and a panel built only while open | A closed panel is in neither the semantics tree nor the focus order | The SDK widgets give no role or state; kept with `Offstage` (`ExpansionTile(maintainState: true)`, and by default `CupertinoExpansionTile` and `Expansible`) a closed panel keeps keyboard focus ([FL-263](../flutter-limitations.md#fl-263)) | APG (`aria-expanded` false: the panel is hidden); Android View reference (`View.GONE`); Android Compose reference (content composed only while expanded) |
| `HeaderSemantics`: `button: true` | The button role | `ExpansionTile` gives its header no button flag; a `CupertinoListTile` has none (FL-264, FL-265, [FL-400](../flutter-limitations.md#fl-400)) | APG (button role, required); Android View reference; Flutter `SemanticsProperties.button` |
| `HeaderSemantics`: `expanded: open` | The state: `aria-expanded` on the web, the expanded state on Android 16 and later | No Flutter accordion widget sets `expanded`; they put the word in a hint (FL-264) | APG (`aria-expanded`); iOS reference (VoiceOver must hear "Expanded" and "Collapsed"); Flutter `SemanticsProperties.expanded` |
| `iosStateValue`: `value: 'collapsed'` or `'expanded'`, on iOS only | VoiceOver reads the state | The iOS engine does not pass `expanded` ([FL-260](../flutter-limitations.md#fl-260)) | **No source.** Of this project's own design: not in APG, the reference repositories, or Flutter's documentation. UIKit and SwiftUI use `accessibilityExpandedStatus`, which Flutter cannot set |
| `onTapHint: 'expand'` or `'collapse'` | TalkBack says "Double-tap to expand" or "to collapse" | Before Android 16 no state reaches Android ([FL-261](../flutter-limitations.md#fl-261), source read) | Android Compose reference (`onClickLabel`) |
| `onExpand` while closed, `onCollapse` while open | Android's expand and collapse actions (Android 16 and later only, FL-261) | No Flutter accordion widget gives them | Android View reference (`ACTION_EXPAND`, `ACTION_COLLAPSE`); Android Compose reference (`expand()`, `collapse()`) |
| The heading: `headingLevel: 3` on the button's node off the web, and on the web a `Semantics(headingLevel: 3, container: true)` round the button (by `kIsWeb`) | The heading | On the web a node that is both a heading and a button is a heading only ([FL-262](../flutter-limitations.md#fl-262)); no Flutter accordion widget has a heading | APG (a heading round the button, required); Android View and Compose references (mark section headings) |
| `controls` and `panelId`: `controlsNodes` naming the panel, set only while it is open | `aria-controls` on the web | Set all along, the web engine never writes it ([FL-266](../flutter-limitations.md#fl-266)) | APG for `aria-controls`. **No source** for setting it only while open: of this project's own design |
| `KeyboardHeader`: `FocusableActionDetector` with `ActivateIntent` and `ButtonActivateIntent` | Keyboard focus, Enter and Space | `CupertinoListTile` and `CupertinoExpansionTile` take no keyboard focus (FL-400, FL-265) | APG (Enter and Space); I01's workaround for FL-400 |
| `FocusRing`: a 3 pixel ring in the text colour | A visible focus indicator | `ListTile`'s focus tint is under 3:1 ([FL-430](../flutter-limitations.md#fl-430)); `CupertinoListTile` shows none | V14, and C03's copy of it |
| `wrappingTitle`: a `DefaultTextStyle` of the title's own | A `CupertinoListTile` title wraps at 200% text | The tile cuts its title to one line | C03 `good-cupertino`'s fix |
| `plainHeader`: a `GestureDetector`, the title, and an arrow | The face of `good-custom`, and of the hand-built bad examples | None: it is the widgets-layer variant | None needed: the widgets layer itself |

The hand-built bad examples (`bad-no-state`, `bad-heading-on-button`,
`bad-no-heading`, `bad-hidden-panel`) are built from the same pieces, each
with one taken away or changed; `bad-hidden-panel` copies `Expansible`'s
default way of hiding a closed panel.

### Bad

| Slug | Defect | Violates |
| --- | --- | --- |
| `bad-no-state` | Nothing says whether a section is open: buttons and headings with no expanded state (and no iOS value, no tap hint), as the iOS reference's bad example | R2 |
| `bad-heading-on-button` | The heading on the button's own node on the web too: there each header is an `<h3>` only, with no button role and no `aria-expanded` (FL-262). On Android and iOS it is as the good examples | R1, R2 (web) |
| `bad-no-heading` | Drawn as section headings, in the title style, but not headings | R3 |
| `bad-hidden-panel` | A closed panel kept with `Offstage`, as `Expansible` keeps it by default: out of the semantics tree, but its button keeps keyboard focus, so Tab goes to buttons that are not drawn, and Enter presses one (FL-263) | R6 |
| `bad-expansion-tile` | Material's `ExpansionTile`, as it comes: on Android and iOS its headers are not buttons (FL-264) | R1 |
| `bad-cupertino-expansion-tile` | Cupertino's `CupertinoExpansionTile`, as it comes: its headers take no keyboard focus, so a keyboard opens nothing (FL-265) | R5 |

The two SDK tiles are shown as they come, each with one named defect.
Their other measured shortcomings, which are not their named defects and
are not judged in the table below:

- `bad-expansion-tile`: no expanded state on any platform; "Collapsed" or
  "Expanded" is only text, at the end of the name on Android ("Shipping,
  Collapsed"), a hint on iOS, and the accessible description on the web;
  on Android a live region announces the change (FL-264). On the web the
  description depends on the platform Flutter's engine finds from the
  browser's `navigator.platform`: "Collapsed double tap to expand" on
  macOS, "Collapsed" alone on Linux and Windows (the tile adds the touch
  instruction only where `defaultTargetPlatform` is iOS or macOS; source
  read, and measured in the web tests).
- `bad-cupertino-expansion-tile`: no button role on Android (`View`) and
  iOS (static text); no expanded state. The state is hint text on iOS,
  and on the web the accessible description only where Flutter's engine
  finds macOS ("Collapsed double tap to expand"); on Linux and Windows the
  header has no description, so its state is in no attribute and no text,
  and on Android nothing says it either (the tile adds the hint only where
  `defaultTargetPlatform` is iOS or macOS; source read, and measured in
  the web tests). Once open, the panel's text joins the header's name
  (FL-265).

On the web, VoiceOver on macOS reads both tiles' closed headers "Shipping
Collapsed double tap to expand button", in Chromium and WebKit
(`docs/evidence/probes/c05/voiceover-web-round1-fail.md.txt`, and the
passing transcript, `docs/evidence/C05/voiceover-web.md`): the tiles do
give the state in words there, through the hint text, phrased as a touch
instruction on a desktop browser. VoiceOver on macOS hears only a browser
on macOS; on Linux and Windows the tree tests show `bad-expansion-tile`'s
description as "Collapsed" alone and `bad-cupertino-expansion-tile` with
none. What that means for the web, as the criteria are written: the named
defects' verdicts below do not change, on any of those platforms
(`bad-expansion-tile` has none on the web, where it is a button on each;
`bad-cupertino-expansion-tile` fails 2.1.1, as its header takes no focus
on each). For the state, which is not a named defect: where it is text in
the accessible description and not `aria-expanded` (both tiles on macOS,
`bad-expansion-tile` on Linux and Windows too), 4.1.2 fails, by the
owner's ruling of 2026-11-23 that a state given only as text does not
meet 4.1.2; where nothing gives it
(`bad-cupertino-expansion-tile` on Linux and Windows, as on Android), 4.1.2
fails as written. Nothing more is claimed.

Their panels hold text only, so that a closed panel has
nothing to take focus (`CupertinoExpansionTile` keeps closed panels
`Offstage`, FL-263). Their headers have no `TestId`: its `MergeSemantics`
would merge the tile's panel into its header. They are found by text.

What each fails, by platform, as the criteria are written:

| Example | Android | iOS | Web |
| --- | --- | --- | --- |
| `bad-no-state` | 4.1.2: no state (on Android 16 and later; before 16 the good examples have none either, FL-261) | 4.1.2: no state | 4.1.2: no `aria-expanded` |
| `bad-heading-on-button` | none: a heading button with its state | none: as the good examples | 4.1.2: a heading, with no button role and no state (FL-262) |
| `bad-no-heading` | 1.3.1: drawn as a heading, not one | 1.3.1 | 1.3.1 |
| `bad-hidden-panel` | 4.1.2: Tab puts keyboard focus on a button that has no node, and Enter presses it | 4.1.2: four Tabs and Enter press a button that is not on screen | 4.1.2: as on Android; the page's focus stays on the last header |
| `bad-expansion-tile` | 4.1.2: not a button (`View`) | 4.1.2: static text | none: a button ([FL-006](../flutter-limitations.md#fl-006)) |
| `bad-cupertino-expansion-tile` | 2.1.1: the header takes no keyboard focus, so no key reaches it | 2.1.1 | 2.1.1 |

For `bad-hidden-panel`, 2.4.7 Focus Visible and 2.4.3 Focus Order are
not claimed: the tests show keyboard focus on a control with no node, not
that no focus indicator is visible (that nothing is drawn is from the
source, `RenderOffstage` paints nothing, and no screenshot was taken), and
the visible stops keep their order.

2.1.1 Keyboard, outside the entry's two criteria, is claimed for
`bad-cupertino-expansion-tile` because it fails as written and the tests
show that no keyboard path opens a section: the header has no focus state
at all in the semantics tree (widget tests) and no `tabindex` on the web,
so no key can reach it; Tab stops only on Back, where Enter and Space
leave the example (widget tests, the web, Android); and on iOS one, two,
or three Tabs and then Enter or Space never open a section. A section
opens only by a pointer or a screen reader's tap action. 2.1.1's exception
(input that depends on the path of the user's movement) does not apply.

## 6. Assertions by layer

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Every example, closed and with both sections open: at 200% text on a 320 by 640 screen, no layout overflow and no text cut short (line limit or box); and in light and dark, the text contrast guideline. Good, closed and open, in light and dark: the four guidelines. Good: each header is a button, a level 3 heading, named by its title, collapsed, with a tap action and the tap hint "expand", and no value (Android); in iOS mode its value is "collapsed", then "expanded"; the reading order is Shipping, Returns, and after a tap Shipping, its text, its button, Returns, with Shipping expanded, its hint "collapse", and `controlsNodes` naming its panel; Tab stops are Back, Shipping, Returns, Back, and once open Back, Shipping, "Track a parcel", Returns, Back; the tap action opens and closes it; the expand action is offered while closed and the collapse action while open, and each opens or closes it; Tab to a header, then Enter, and in another test Space, each opens it, keeps focus on it, and closes it again; Tab into an open panel and Enter presses its button (the count); the focus ring is clear, drawn in the text colour on focus, and clear again after, closed and open, light and dark. Bad: `bad-no-state` has no expanded state or value before or after a tap that opens it; `bad-heading-on-button` is one node with heading, button, and state (the web shows the defect); `bad-no-heading` has no heading level, the title style of the good headers, and no level 3 heading on the screen; `bad-hidden-panel`'s closed panels are not in the tree, Tab stops after Returns twice on nodes no semantics node has, the first of them Shipping's button, and Enter there presses it while both stay closed; `bad-expansion-tile` is no button, no state, hint "Collapsed", then "Expanded" after a tap that opens it; `bad-cupertino-expansion-tile` is no button, no state, no focus state, opened by a tap, and Tab stops only on Back, where Enter, and in another test Space, take the app back (the key acted) |
| L3 web | Good: each header is a `role="button"` named by its title with `aria-expanded="false"`, inside an `<h3>` (its parent element), and the heading holds that button; three buttons on the screen (two headers and Back) and two level 3 headings; no closed panel in the page; a click opens Shipping, sets `aria-expanded="true"` and `aria-controls` to the panel's element (none before, none on Returns), and the page reads Shipping, its text, its button, Returns; a second click closes it; a DOM click with no pointer events opens it; Tab reaches it and Enter, and in another test Space, opens it, keeps focus, and closes it; Tab stops are Back, Shipping, Returns, and once open Shipping, "Track a parcel", Returns; Shift+Tab back to the button and Enter press it. Bad: `bad-no-state` has no `aria-expanded` before or after a click that opens it; `bad-heading-on-button` is an `<h3>` with the heading role, no `aria-expanded`, no button inside it, and Back the only button, while a click opens it; `bad-no-heading` has buttons with `aria-expanded` and no level 3 heading, only the screen's two headings; `bad-hidden-panel` has no closed panel and no panel button in the page, Tab stops are Back, Shipping, Returns, Returns, Returns, and Enter then presses a hidden button while both stay closed, with Enter on a header opening it as the positive control; `bad-expansion-tile` is a button with no `aria-expanded` whose description is "Collapsed double tap to expand", then "Expanded double tap to collapse", where Flutter's engine finds macOS, and "Collapsed", then "Expanded", on Linux and Windows; `bad-cupertino-expansion-tile`: Tab reaches only Back (stops on the page itself left out, FL-421), and Enter, and in another test Space, on Back leave the example; its header has no `tabindex` and no `aria-expanded`, on macOS the description "Collapsed double tap to expand" and on Linux and Windows no description (an empty one, and no `aria-description`), and a click opens it, after which it is one button with the panel's text, still with no `aria-expanded`, with "Expanded double tap to collapse" on macOS and no description on Linux and Windows. The two tiles' tests read the platform from `navigator.platform` in the page, as the engine does, and each also runs with it set to "MacIntel", "Linux x86_64" and "Win32" (section 7). Also: the VoiceOver walk judge on made-up walks, and that each screen shows the texts the judge expects |
| L3 Android | Good: each header is a `Button` named by its title, a heading, clickable, focusable, click label "expand", and on Android 16 and later expanded state "collapsed", before 16 no expand or collapse action; two clickable nodes but Back; no closed panel; the reading order Shipping, Returns; `ACTION_CLICK` opens Shipping (state "full", label "collapse", Returns still collapsed, reading order with the panel after its header) and closes it again; on Android 16 and later `ACTION_EXPAND` opens it and `ACTION_COLLAPSE` closes it (skipped before 16); a tap opens it; Tab to it and Enter, then Space, each open it, keep focus, and close it; Tab after a closed Shipping reaches Returns, after an open one "Track a parcel" then Returns. Bad: `bad-no-state` has no expanded state ("undefined") and no click label before and after a click that opens it; `bad-heading-on-button` is a heading button with its state; `bad-no-heading`'s headers are buttons with their state and not headings; `bad-hidden-panel`'s closed panel is not in the tree; the Tab after Returns leaves the tree reporting Returns as focused, and Enter then presses a hidden button (the count) while both sections stay closed, which Enter on Returns would not do; Enter on Returns opening it is the positive control; `bad-expansion-tile` is a `View` named "Shipping, Collapsed", then "Shipping, Expanded", not a heading, click label "Expand for more details", no expanded state; `bad-cupertino-expansion-tile`: Tab never gives its header focus and reaches Back, where Enter, and then Space, leave the example; its header is a `View` with no expanded state, opened by the click action |
| L3 iOS | Good: each header is a button named by its title, value "collapsed"; two buttons but Back; no closed panel on screen; a tap opens Shipping (value "expanded", Returns "collapsed", the panel's text and button between Shipping and Returns on screen; XCUITest's list of elements is not the reading order, which the VoiceOver walk checks) and a second closes it; two Tabs and Enter, and in another launch Space, open Shipping and stay on the example. Bad: `bad-no-state` has no value before or after a tap that opens it; `bad-heading-on-button` and `bad-no-heading` are buttons with the value (the heading is heard, not seen, in the tree); `bad-hidden-panel` shows no closed panel, four Tabs and Enter press a hidden button (the count) while both stay closed, and three Tabs and Enter open Returns, the positive control; `bad-expansion-tile` and `bad-cupertino-expansion-tile` are not buttons and have no value, and a tap opens them; for `bad-cupertino-expansion-tile`, one, two, and three Tabs and then Enter or Space never open a section and take the example off the screen (Back acted) |
| L4 TalkBack | For each example but `bad-hidden-panel`: what is said with focus on Shipping's header, closed; on the click action with focus left there (not for `bad-no-state` and `bad-cupertino-expansion-tile`, see section 7); with focus on the panel's text (on Back for `bad-cupertino-expansion-tile`, whose open panel is part of its header); and on the header again, open. Each walk is judged whole (`walk_strictly` in `tool/talkback.py`): a walk with any wrong reading fails for good, and only a walk shown to be incomplete (an element never focused, nothing spoken for it, or its speech cut off in the log with no forbidden phrase in what was captured) is walked again, up to three walks; the walk that decides is judged on its own, with no element's speech taken from another walk, and every walk is in the transcript. The judge is tested on made-up logs in `tool/test_talkback.py` (`StrictWalks`) |
| L4 VoiceOver iOS | Every utterance after the "Example" heading to the end of the screen, compared as a whole list, closed, and again after XCUITest's double tap at the header, with VoiceOver on, has opened Shipping; what VoiceOver says with its cursor on Shipping, and in the three seconds after that gesture. The gesture is a tap at the header's place, not VoiceOver's activation, which XCUIVoiceOverService has no way to make (C04 probe round 3, `docs/evidence/probes/c04/ios_round3.txt`) |
| L4 VoiceOver web | Every stop of VoiceOver's cursor from Back to the end of the screen, judged as C04's walks are (`judgeExampleWalk` in `web_tests/vo/c05_vo_walks.js`): the whole screen in order, the title, the description, a good example's custom-solution note, a bad example's defect, the heading, and every stop after it; a walk that reached the end with a stop missing, or with any stop wrong, fails for good; only a walk cut short with every stop right so far is walked again, up to three times, and every try is logged; no runner retries. Closed, and after a click has opened Shipping, in Chromium and WebKit. The judge is tested on made-up walks in `web_tests/c05_accordion.spec.js`. The first recording (`docs/evidence/probes/c05/voiceover-web-round1-fail.md.txt`) heard every walk of the good examples and of the four hand-built bad ones, closed and open, in both browsers, as expected; the two SDK tiles' closed readings were not as expected (their hint, above), so their open walks were not reached. Their expectations are now the closed readings heard, and open readings not heard yet. The second recording (`docs/evidence/probes/c05/voiceover-web-round2-fail.md.txt`) heard every walk as expected, the tiles' open walks included, but for `bad-cupertino-expansion-tile`, whose test ran into its timeout after the closed walk; its open walk now starts as described in section 7. The third (`voiceover-web-round3-fail.md.txt`) heard every walk as expected, that open walk included in Chromium, but in WebKit that open walk read only the page's web area; it is now made on a fresh load (section 7). The fourth (`docs/evidence/C05/voiceover-web.md`) passed: every walk, closed and open, in both browsers, complete and as expected on its first walk. It was recorded again on 2026-11-22, once the good examples' screens showed the custom-solution note, one more stop above their heading, which the walk judges: it passed, with every reading after the heading as before. The TalkBack and iOS VoiceOver transcripts, recorded again the same day with the good screens scrolled to their end first, read as before as well |

## 7. What the build found (Flutter 3.47.5)

The probe that came first is in [evidence/probes/c05](../evidence/probes/c05/README.md):
eighteen fixtures on the web, Android 17, and iOS 27.0, with TalkBack and
VoiceOver, and native comparisons on Android and iOS.

- **No accordion widget in the SDK is a good example.** `ExpansionTile`
  has no expanded state and, on Android and iOS, no button role; its
  state is a hint, which Android puts at the end of the name ("Shipping,
  Collapsed") ([FL-264](../flutter-limitations.md#fl-264)).
  `CupertinoExpansionTile` takes no keyboard focus, has no role or state,
  and once open its panel's text joins its name
  ([FL-265](../flutter-limitations.md#fl-265)). `ExpansionPanelList`'s
  expand buttons are all named "Expand" (probe only,
  [FL-267](../flutter-limitations.md#fl-267)). The good examples are
  list tiles and a `GestureDetector` inside `Semantics(button: true,
  expanded:)`.
- **iOS gets no expanded state from Flutter**
  ([FL-260](../flutter-limitations.md#fl-260)). VoiceOver reads
  a header with `expanded` exactly as one without ("p07 Shipping Button",
  closed and open), while UIKit's `accessibilityExpandedStatus` and
  SwiftUI's `DisclosureGroup` are read "Collapsed" and "Expanded" (probe,
  `testNative`). The good examples give iOS the state as the value, which
  VoiceOver reads after the name: "Shipping collapsed Button Heading".
- **Android gets it from Android 16 only**
  ([FL-261](../flutter-limitations.md#fl-261), source read). On Android 17
  TalkBack says "collapsed." before the name and "fully expanded" on the
  change. Before 16 it was not measured: the local emulator is 17, and
  CI's API 35 emulator runs the tests' other branch, which asserts that no
  expand or collapse action is there. By the engine source, what is left
  there is the tap hint ("Double-tap to expand" on Android 17), which says
  what a double tap does and not the state. Whether that leaves Android
  before 16 a limitation with no workaround is for the owner to decide;
  the catalog marks Android as applying, with a note.
- **On the web a heading node is never a button**
  ([FL-262](../flutter-limitations.md#fl-262)), so the heading holds the
  button there, and is on the button's own node elsewhere
  (`HeaderSemantics`, by `kIsWeb`). On Android that nesting would leave
  an unnamed heading and a button that is not one (probe p09).
- **A panel kept with `Offstage` keeps keyboard focus**
  ([FL-263](../flutter-limitations.md#fl-263)), and `Expansible` keeps
  closed panels that way by default. The good examples build a closed
  panel not at all.
- **An opened `CupertinoExpansionTile` leaves an empty element over the
  page on the web** ([FL-029](../flutter-limitations.md#fl-029), extended):
  the size of the view, taking pointer events, after a section has first
  been opened. Playwright's checked click on anything under it is refused;
  a real mouse click still reaches Flutter (web tests). The second web
  VoiceOver recording's test of that example ran into its timeout after
  the closed walk, with no open walk logged
  (`docs/evidence/probes/c05/voiceover-web-round2-fail.md.txt`); the open
  walk began with a checked click on the "Example" heading, which the
  probe shows is refused there (`click_probe.txt`).
- **`aria-controls` needs `controlsNodes` set while the panel is there**
  ([FL-266](../flutter-limitations.md#fl-266)): the good examples set it
  only while open.
- **TalkBack says nothing when focus is put back on the node it was on.**
  In the probe, focus cleared and put on the same header again read
  nothing, for every fixture. Why was not looked into. C05's walk moves
  focus to the panel's text and back instead.

What is said when a header is activated: on Android 17 TalkBack says
"fully expanded" or "collapsed" by itself, from the expanded state's
change. On iOS VoiceOver said nothing in the three seconds after
XCUITest's double tap at the header, for the good examples and for UIKit's
own button with an expanded status alike, and the new state was read when
the cursor came back to the header. That gesture is a tap at the header's
place and not VoiceOver's own activation (C04 probe round 3), so what
VoiceOver says after its own double tap, made by a person, was not
measured. The examples add no announcement of their own. `ExpansionTile`
announces the change itself (source read: `sendAnnouncement` on iOS and the
web, a live region on Android): "Expanded" was heard from VoiceOver on iOS
and from TalkBack; on the web it was not listened for.

Skips and what they give up, in the tests:

- The widget tests run as Android (`kIsWeb` false), so the web's heading
  node round each header is tested only in the web tests; one widget test
  per good example sets the iOS target platform to check the value.
- Android's expanded state and its expand and collapse actions are
  checked on Android 16 and later only; on CI's API 35 emulator the tests
  check instead that the actions are not there, and the test of the
  actions is skipped (`assumeTrue`). So CI gives up checking the state on
  Android, and the local run gives up checking the API 35 branch.
- The TalkBack judge counts only a capture shown to be short as
  incomplete: an element never focused, one with nothing spoken, or one
  whose speech was cut off in the log. A cut-off element is still checked
  for the phrases it must not say, in every fragment captured whole and in
  the captured lines of the cut-off one (logcat splits a fragment at its
  line breaks, so those are whole lines of what was said): a forbidden
  phrase found there is a wrong reading, and fails for good. A required
  phrase it lacks may have been in the lost part, so that alone makes it
  incomplete; a forbidden phrase whose words are not all in the captured
  lines was not shown to be said. Any other failed check, a system
  notification spoken over an element among them, is a wrong reading and
  fails the run for good. It gives up a retry for a reading spoiled by the
  device, which the composite judge of other techniques
  (`walk_until_heard`) would walk again row by row; that composite could
  pass two walks each wrong at a different row.
- The TalkBack walk leaves out `bad-hidden-panel`, whose defect is where
  Tab goes, which the tree tests check. Its expectations are for Android
  17; the transcript is recorded only on the local emulator.
- What TalkBack says on the click is not checked for `bad-no-state` and
  `bad-cupertino-expansion-tile`: they have no state to announce, and a
  check of silence would also pass on a lost capture. The walk drops that
  speech (an END marker before the click). It gives up hearing that
  nothing is announced; that they have no state is heard in their closed
  and open readings, which have no state word. In the first run, with
  those markers in place, TalkBack said nothing there for either, in three
  walks (`docs/evidence/probes/c05/talkback-first-run.md.txt`).
- The iOS tests cannot see Flutter's keyboard focus, so where Tab goes is
  shown by what Enter or Space then does: Shipping opening after two Tabs
  (good examples), the count going up after four (`bad-hidden-panel`),
  and the example leaving the screen (Back acted) after one to three Tabs
  in `bad-cupertino-expansion-tile`. They rely on the first Tab being on
  Back, as C03's probe found.
- The iOS VoiceOver walk goes to the end of the screen, where moving on
  gives the last utterance again, twice (`C05Walk`, tested with no device
  by `testWalkToTheEndSeesAnExtraStop`). It gives up two neighbouring
  elements that VoiceOver reads alike, which it would count as one; no
  example has two.
- The web VoiceOver spec's open walk of `bad-cupertino-expansion-tile`
  starts with a mouse click at the "Example" heading's place, not
  Playwright's checked click on it (`walkToEndClickingAtPoint`, as
  `walkFromBack`'s `clickAtPoint` does for FL-029): the empty element over
  the page refuses the checked click. The click only brings keyboard focus
  into the page; the walk is then `walkToEnd`'s. It gives up the check that
  nothing covers the heading, which the tree spec makes instead ("the empty
  element over the page").
- The web VoiceOver spec makes `bad-cupertino-expansion-tile`'s open walk
  on a fresh load of the example, so that it is the first walk on that
  page; every other example's open walk is the second walk on the page its
  closed walk was made on. In the third recording that open walk, the
  second on its page, read only the page's web area in WebKit and was
  right in Chromium (`voiceover-web-round3-fail.md.txt`). A WebKit probe of
  this example (`docs/evidence/probes/c05/voiceover-web-round3-probe.md.txt`,
  from `c05_accordion_vo_round3_probe.spec.js.txt`) started walks four
  ways, closed or open, with no click or with the click at a point, two
  walks on each load: all four first walks walked the page, open ones
  included; three of the four second walks did not, closed ones included.
  In two of them the start left VoiceOver's cursor where the walk before
  had ended ("Presses: 0"); in the third, with the click at a point, the
  start looked as in the good walks (the same kind of phrase, the cursor
  at the same place) and the first move went to the web area. So the
  probe ties the failure to a second walk on one load, not to the open
  screen, and gives no check at the start that would catch all of it;
  none is made. The fresh load gives up nothing that is judged: the walk
  is judged as every walk is, and a wrong reading fails for good. Why a
  second walk's start fails was not found. The other examples' second
  walks, which start with the checked click, were right in all three
  recordings, and the probe tested this example only, so they are left as
  they are.
- Each good example's screen shows the custom-solution note above the
  example (docs/custom-solutions.md), which makes it taller: in a widget
  test at 320 by 640, with the test font, the first header starts about
  200 pixels below the screen. The tests scroll as a person would, and
  assert what they did before: the widget tests scroll a header into view
  before a tap and, before the guidelines are checked with both sections
  open, scroll until the count is at the bottom of the view and check that
  the whole example, first header to count, is then in it; the Android
  and iOS tests scroll a good example's screen to its end once it is open
  (Android again before each reading of the tree, iOS again once a tap has
  opened Shipping and before the open VoiceOver walk). The web tests need
  no change: Playwright scrolls a control into view before it acts.
- The web tests of the two SDK tiles expect what the platform gives,
  read from `navigator.platform` in the page, from which Flutter's web
  engine takes `defaultTargetPlatform` (`detectOperatingSystem` in ui_web's
  `browser_detection.dart`; source read). Each also runs with
  `navigator.platform` set to "MacIntel", "Linux x86_64" and "Win32" before
  the app starts, so that every branch runs on any machine. A set value
  gives Flutter's own choice for that platform; it is not a browser on
  that system. On a real browser: macOS on this Mac, Linux on CI's
  Chromium (whose first run of the earlier test, which expected a
  description, received an empty one, as the Linux branch now expects;
  `docs/evidence/probes/c05/web-platforms.txt`); Windows on none. A browser
  on Android is not covered (the tests fail there): `ExpansionTile` adds a
  live region there (source read), not measured on the web.
- The web test of `bad-cupertino-expansion-tile`'s Tab stops leaves out
  stops outside Flutter's tree (the page itself, FL-421). It gives up
  nothing a key could act on in the app.

**Not done yet.** The SDK tiles on the web in a real browser on Windows or Android (section 7); Android before 16, measured
on a device; what VoiceOver on iOS says and does on its own double tap,
made by a person (the tests' gesture is XCUITest's tap at the header's
place); a real app and user journey built with the custom solution; what TalkBack's actions menu offers, and its swipe order
through an open panel (the walk moves focus by action); arrow keys, Home,
and End between headers, which APG does not list and Radix has; an
accordion that keeps one section always open (APG's `aria-disabled` case);
and the region role for panels, which APG makes optional.

