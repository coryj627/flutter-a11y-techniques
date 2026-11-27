# Spec: S12 Hiding content from AT

Status: Draft 1 (2026-11-27), written with the build. Wave 3, structure and
order. Flutter pin: 3.47.5.

Hiding content from assistive technology: characters that only decorate,
and text that repeats what is said beside it, are kept from the screen
reader; content that is closed or inactive, meant to be unavailable to
everyone, is hidden from everyone; and nothing a user needs or can operate
is hidden. Content meant only for assistive technology, hidden from sight
and read by the screen reader (WCAG technique
[C7](https://www.w3.org/WAI/WCAG22/Techniques/css/C7), text hidden with
CSS to complete a link's purpose), is a different case and is not covered
here. A picture that only decorates is
[S03 Decorative images](S03-decorative-images.md), merged and cited, and not
repeated here; replacing a group with one label of its own is
[S10 Content group replacement](S10-content-group-replacement.md);
joining texts into one stop is [S09 Content grouping](S09-content-grouping.md).
A panel that opens and closes is a disclosure ([C06](C06-disclosure.md)) or
an accordion ([C05](C05-accordion.md)); this spec uses a switch to show and
hide one, so that the control is not the subject. What is behind a dialog
or a drawer is wave 7's.

## 1. Rule

Characters that only decorate, and text that only repeats text beside it,
are hidden from assistive technology. Content that is closed or inactive,
meant to be unavailable to everyone, is hidden from everyone: the screen
reader, the keyboard, and the pointer. Nothing that a user needs, and no
control, is hidden from a screen reader while it is shown and can be
operated. Content hidden from sight on purpose for assistive technology
alone (C7) is not this rule's subject.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies | Applies | Applies |

Every good example is Flutter's own widgets through their documented
parameters: `ExcludeSemantics` round what only decorates or repeats, and
`Visibility` round what is hidden from everyone. None is a custom solution
(section 5). Each was measured to do what the rule asks on all three
platforms (section 7), so every platform applies.

What Flutter does not give is recorded, and changes no platform's status,
because the good examples do not need it:

- **A control hidden from the semantics tree keeps keyboard focus, on every
  platform** ([FL-350](../flutter-limitations.md#fl-350), new; and
  [FL-263](../flutter-limitations.md#fl-263), extended, for `Offstage`).
  `ExcludeSemantics`, `Semantics(excludeSemantics: true)`, `Opacity` at 0,
  `BlockSemantics`, and the deprecated `IgnorePointer(ignoringSemantics:
  true)` take a control out of the tree and leave it in the keyboard's
  order, where Enter and Space run it with no node focused. On the web the
  page's focus stays on the element before it, so a screen reader is told
  focus is on that element. Plain HTML exposes a focused `aria-hidden`
  button while it has focus (WAI-ARIA 1.2, 7.2); Flutter has nothing to
  expose. The good examples hide no control, which is the rule's own
  requirement; `Visibility` takes what it hides out of the keyboard's order
  as well. `bad-hidden-control` and `bad-opacity` are this defect.
- **`Semantics(hidden: true)` is not a way to hide**
  ([FL-351](../flutter-limitations.md#fl-351), new; probe only). It took
  the node and everything under it out of the tree on Android, only the
  node itself out of VoiceOver's moving forward on iOS, and nothing on the
  web. It is documented as a flag that "Platforms are free to completely
  ignore", "mainly used to implement accessibility scrolling on iOS". No
  example uses it.

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [1.3.1 Info and Relationships](https://www.w3.org/TR/WCAG22/#info-and-relationships) | Information shown on the screen must be determinable, or available in text: hiding it from the screen reader loses it |
| [4.1.2 Name, Role, Value](https://www.w3.org/TR/WCAG22/#name-role-value) | A control hidden from the screen reader has no name or role it can determine |

4.1.2, as written: "For all user interface components ..., the name and
role can be programmatically determined". A button that a pointer and the
keyboard can operate is a user interface component. Hidden from the
semantics tree it has no node, so its name and role cannot be determined:
`bad-hidden-control` fails 4.1.2 as written on all three platforms, and so
does `bad-opacity` while its panel is hidden, whose Copy button the
keyboard and a tap at its place still operate (section 7). 2.1.1 is not
failed by either: the keyboard reaches and runs the control.

1.3.1, as written: "Information, structure, and relationships conveyed
through presentation can be programmatically determined or are available
in text." The good examples hide only what the text beside them already
says (`good-badge`'s "3", in "Inbox: 3 unread") or what conveys nothing
(`good-decoration`'s ornaments), so nothing conveyed is lost. No bad example
here hides needed text alone: the one that hides text hides a control with
it (`bad-hidden-control`, judged under 4.1.2).

What a bad example fails, by platform, as the criterion is written:

| Example | Android | iOS | Web | Measured in widget tests only |
| --- | --- | --- | --- | --- |
| `bad-decoration-read` | none in S12's list; 1.1.1 (outside it), by the tree and the focused reading: each ornament a node | none in S12's list; 1.1.1 (outside it): VoiceOver stops on each | none in S12's list; 1.1.1 (outside it): VoiceOver stops on each, both browsers | — |
| `bad-hidden-control` | 4.1.2: Share has no node; the keyboard reaches and runs it | 4.1.2, as Android | 4.1.2, as Android; the page's focus stays on Back | — |
| `bad-opacity` | 4.1.2: hidden, Copy has no node; the keyboard and a tap at its place run it | 4.1.2, as Android | 4.1.2, as Android; the page's focus stays on the switch | 2.4.7: no focus indicator shows |
| `bad-maintain` | none of 1.3.1 and 4.1.2: hidden, everything is exposed as if shown | as Android | as Android | 2.4.7: no focus indicator shows |

`bad-decoration-read` is not a shown failure of a success criterion in
this technique's list; shown for what the user hears. It does fail a
criterion outside the list, 1.1.1 Non-text Content, as written. WCAG's
definition of non-text content is "any content that is not a sequence of
characters that can be programmatically determined or where the sequence
is not expressing something in human language", and its note includes
"ASCII art (which is a pattern of characters)". "✦ ✦ ✦" is a sequence of
characters that expresses nothing in human language, and "❝", a quotation
mark ornament standing alone before the quote, says nothing the layout and
the attribution do not; both are non-text content, and both are pure
decoration. 1.1.1 asks of pure decoration that it be "implemented in a way
that it can be ignored by assistive technology". By platform, from the
transcripts:

- iOS: VoiceOver, moving forward, stops on "❝" and on "✦ ✦ ✦", each an
  utterance of its own (`docs/evidence/S12/voiceover-ios.md`): fails.
- Web: VoiceOver's `next` stops on each, in Chromium and in WebKit
  (`docs/evidence/S12/voiceover-web.md`): fails.
- Android: each is a node of its own that TalkBack reads when focused
  (`docs/evidence/S12/talkback-android.md`) and that the tree test counts.
  TalkBack's own navigation by swipe was not measured (the walks move focus
  by action), so on Android the failure rests on the ornaments being
  focusable nodes in the tree and read when focused, not on a measured
  swipe.

`good-decoration` meets the same clause on all three: the ornaments are
in no node, element, or XCUITest element, and none of the three
transcripts has a stop for them. 1.1.1 is outside S12's listed criteria
(1.3.1 and 4.1.2); S03 Decorative images owns it for pictures.

`bad-maintain` is likewise
not a shown failure of a success criterion in this technique's list; shown for what the user hears: it fails neither 1.3.1 nor 4.1.2, because what it exposes is
determinable; its defect is that a screen reader reads, and the keyboard
reaches, what is not on the screen. Its 2.4.7 failure below was measured in
widget tests only, and 2.4.7 is outside S12's list. 2.4.7 Focus Visible, as written: "Any
keyboard operable user interface has a mode of operation where the keyboard
focus indicator is visible." While the panel is hidden, focus on Copy draws
nothing at all (the widget test compares the screen's pixels with focus on
Copy and with no focus, and they are the same; section 7), so for
`bad-opacity` and `bad-maintain` 2.4.7 fails as written. That was measured
in the widget tests only, not on a device's screen.

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | Content that only decorates, or only repeats nearby text, may be hidden from assistive technology | [iOS Accessibility Hidden](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/AccessibilityHidden.md) (text that "is decorative or very short, such as a badge number or a glyph, and the element around it already says what it means"), [WAI-ARIA 1.2 `aria-hidden`](https://www.w3.org/TR/wai-aria-1.2/#aria-hidden) ("redundant or extraneous content") |
| R2 | What is hidden from assistive technology loses nothing: "identical or equivalent meaning and functionality" is exposed | WAI-ARIA 1.2 `aria-hidden`; iOS Accessibility Hidden ("Don't use `.accessibilityHidden(true)` on any informative content or UI controls") |
| R3 | A container that holds informative or functional content is not hidden | iOS Accessibility Hidden (not on "parent view containers that hold informative or functional content because all child elements will be hidden"); [Using ARIA, the fourth rule](https://www.w3.org/TR/using-aria/#fourth) (`aria-hidden` on an ancestor of a visible control) |
| R4 | A control is never hidden from assistive technology while it can take keyboard focus | Using ARIA, the fourth rule ("Do not use ... `aria-hidden="true"` on a focusable element"); iOS Accessibility Hidden (it hides content "from VoiceOver, Voice Control, Full Keyboard Access, and Switch Control users") |
| R5 | Content that is closed or inactive, meant to be unavailable to everyone, is hidden from every user and every presentation, the screen reader and the keyboard included. Content hidden from sight but meant for assistive technology, as in WCAG technique [C7](https://www.w3.org/WAI/WCAG22/Techniques/css/C7), is a different case and is not covered here | [HTML Standard, the `hidden` attribute](https://html.spec.whatwg.org/multipage/interaction.html#the-hidden-attribute) ("hidden from all presentations, including, for instance, screen readers"); [HTML Standard, `inert`](https://html.spec.whatwg.org/multipage/interaction.html#the-inert-attribute) (inert nodes "generally cannot be focused", and are not exposed "to accessibility APIs") |

Visible label text is not hidden to avoid hearing it twice: the iOS
reference's bad example hides a field's visible label, and its guidance is
to "accept the repetition". No example here hides a label: S01 and F01 own
names and labels.

How HTML behaves, from the HTML Standard and WAI-ARIA 1.2, read
2026-11-27, and measured in Chromium (`docs/evidence/probes/s12/web.txt`
and `web-round2.txt`, page `html.html.txt`):

- `hidden`: "will not be rendered"; "hidden from all presentations,
  including, for instance, screen readers". Measured: its text and button
  are not in Chromium's tree and Tab does not reach the button.
- `inert`: inert nodes "generally cannot be focused", hit-testing acts as if
  `pointer-events` were none, and they are not exposed "to accessibility
  APIs or assistive technologies". Measured: not in the tree, not reached
  by Tab, `focus()` refused.
- `aria-hidden="true"`: "The element is hidden from the accessibility API",
  and focus is not affected; but WAI-ARIA 1.2, 7.2, has user agents expose
  "Elements that are currently focused, even if the element or one of its
  ancestor elements has its aria-hidden attribute set to true." Measured:
  out of the tree until Tab reaches it; while it has DOM focus, Chromium's
  tree has it, focused, as a button with its name.
- `opacity: 0` and `visibility: hidden` (CSS, for comparison): at opacity 0
  the text and button are in the tree and Tab reaches the button;
  `visibility: hidden` takes both out of the tree and out of Tab's reach.

HTML's `hidden` marks an element that "is not yet, or is no longer, directly
relevant to the page's current state", which is the case R5 covers; the HTML Standard
says it "must not be used to hide content that could legitimately be shown
in another presentation".

Flutter's counterparts, from the probe (section 7): `Visibility(visible:
false)` is `hidden`'s: out of the tree, out of the keyboard's reach, not
drawn, no tap. `ExcludeSemantics` is `aria-hidden`'s, but with nothing
exposed when a control under it has keyboard focus (FL-350).
`ExcludeSemantics` round `ExcludeFocus` is closest to `inert` for the
screen reader and the keyboard, and a pointer still reaches what is under
it (p20). `Visibility.maintain(visible: false)` is close to `opacity: 0`.

Flutter references for the mechanisms used:

- [`ExcludeSemantics`](https://api.flutter.dev/flutter/widgets/ExcludeSemantics-class.html): "A widget that drops all the semantics of its descendants ... This can be used to hide descendant widgets that would otherwise be reported but that would only be confusing." Its documentation says nothing of keyboard focus.
- [`Visibility`](https://api.flutter.dev/flutter/widgets/Visibility-class.html), [`Visibility.maintainState`](https://api.flutter.dev/flutter/widgets/Visibility/maintainState.html), [`Visibility.maintainFocusability`](https://api.flutter.dev/flutter/widgets/Visibility/maintainFocusability.html): "By default, with [maintainFocusability] set to false, focus events cannot reach the [child] when this widget is not [visible] because an [ExcludeFocus] widget is used to exclude the child subtree from the focus tree." With `maintainState` and no `maintainSize`, the hidden child is in an `Offstage` (source read, `widgets/indexed_stack.dart`).
- [`Visibility.maintain`](https://api.flutter.dev/flutter/widgets/Visibility/Visibility.maintain.html): every `maintain` flag set, semantics and focus included.
- [`Opacity`](https://api.flutter.dev/flutter/widgets/Opacity-class.html), [`Opacity.alwaysIncludeSemantics`](https://api.flutter.dev/flutter/widgets/Opacity/alwaysIncludeSemantics.html)
- [`Badge`](https://api.flutter.dev/flutter/material/Badge-class.html), [`Icon.semanticLabel`](https://api.flutter.dev/flutter/widgets/Icon/semanticLabel.html) (an `Icon` with none gives no semantics: S03)
- [`SwitchListTile`](https://api.flutter.dev/flutter/material/SwitchListTile-class.html) (F09's `good-tile`)

The full set looked at, from the framework's source (every widget and
parameter in `widgets/`, `material/`, and `cupertino/` that drops, blocks,
or keeps semantics, or takes a subtree out of focus or hit testing): the
widgets `ExcludeSemantics`, `BlockSemantics`, `Offstage`, `SliverOffstage`,
`Visibility`, `SliverVisibility`, `IndexedStack`, `Opacity`,
`SliverOpacity`, `AnimatedOpacity`, `FadeTransition`, `IgnorePointer`,
`SliverIgnorePointer`, `AbsorbPointer`, `ExcludeFocus`; and the parameters
`Semantics(excludeSemantics:)`, `Semantics(hidden:)`,
`Image(excludeFromSemantics:)`, `FadeInImage(excludeFromSemantics:)`,
`GestureDetector(excludeFromSemantics:)`,
`RawGestureDetector(excludeFromSemantics:)`,
`InkWell(excludeFromSemantics:)`, `Scrollable(excludeFromSemantics:)`,
`Tooltip(excludeFromSemantics:)`, `alwaysIncludeSemantics` on the opacity
widgets and `FlexibleSpaceBar`, `IgnorePointer(ignoringSemantics:)` and
`AbsorbPointer(ignoringSemantics:)` (both deprecated since 3.8, "Use
ExcludeSemantics or create a custom ignore pointer widget instead"), and
the `maintain*` flags of `Visibility`. Cupertino has no parameter of its
own for this (`cupertino/` searched). The sliver forms were not probed;
they are the same render objects' sliver versions (source read).

### Material, Cupertino, and the widgets layer

Hiding is done by widgets-layer widgets, round anything. `good-decoration`
and `bad-decoration-read` are the widgets layer; `good-badge` hides a
Material `Badge`; the panel examples use Material's `SwitchListTile` and
`TextButton`. There is no Cupertino example: Cupertino has no hiding
parameter of its own, and its widgets are hidden by the same widgets as any
other. A Cupertino control in the panel would bring its own gaps
(`CupertinoButton` and Enter on the web, FL-002) that are not this
technique's.

## 5. Examples

The decoration examples show a quote, "Walk the ridge before the sun is
up.", from "Trail guide", with a quotation mark "❝" before it and the
ornament "✦ ✦ ✦" under it. The badge example is a mail icon with a badge
"3" beside the text "Inbox: 3 unread". The panel examples have a switch,
"Show tracking", off when the screen opens, a panel with "Tracking number:
1Z 999" and a "Copy number" button, and a count, "Copies: 0", under it.

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-decoration` | Widgets layer | Ornaments round a quote | `ExcludeSemantics` round each ornament | R1, R2 |
| `good-badge` | Material | A badge whose count the text beside it says | `ExcludeSemantics` round the `Badge`; the `Icon` has no `semanticLabel` | R1, R2, R3 |
| `good-visibility` | Material | A panel hidden from everyone until the switch shows it | `Visibility(visible:, maintainState: true)` | R4, R5 |

No good example here is a custom solution. The register's rows are in
[custom-solutions.md](../custom-solutions.md#s12-hiding-content-from-at):
`ExcludeSemantics` and `Visibility` are used through their documented
parameters, round widgets that keep their own roles and behaviour.

### Bad

| Slug | Defect | Violates |
| --- | --- | --- |
| `bad-decoration-read` | The ornaments are left as they are: a screen reader stops on each and reads it, as text (how a voice pronounces the symbols was not measured) | R1 |
| `bad-hidden-control` | The ornament and a Share button in one `ExcludeSemantics`: no screen reader can find Share, and the keyboard still reaches and runs it (FL-350) | R2, R3, R4 |
| `bad-opacity` | The panel hidden with `Opacity` at 0: not drawn and not in the tree, but its Copy button keeps keyboard focus, Enter and Space copy, and a tap at its place copies (FL-350) | R4, R5 |
| `bad-maintain` | The panel hidden with `Visibility.maintain`: not drawn, but a screen reader reads the number and the button, and the keyboard reaches Copy | R5 |

What each fails, as the criterion is written, is in section 3.

### Not built

- **`Offstage`**: C05's `bad-hidden-panel` is that defect, and FL-263 has
  it; S12's probe measured it again (p05, p12), and FL-263 is extended.
- **`Semantics(excludeSemantics: true)` round a control**: S10's
  `bad-hides-control` ([its spec](S10-content-group-replacement.md), section 9, hands that
  finding to S12); S12's probe measured it again (p04), in
  FL-350.
- **`BlockSemantics`** (p23, p24): it drops the semantics of what was
  painted before it in the same container, as documented, and the
  controls it hides keep keyboard focus (FL-350). A banner that blocks the
  page is a dialog's concern (wave 7); not built.
- **`Semantics(hidden: true)`** (p21, p22): FL-351; documented as a flag
  for platform workarounds, not for hiding.
- **`IgnorePointer` and `AbsorbPointer`** (p16, p17): the control stays a
  button with no tap action on every platform, a tap does nothing, and the
  keyboard still runs it. They hide an action, not content: handed to I01
  (section 9).
- **`InkWell(excludeFromSemantics: true)` and
  `GestureDetector(excludeFromSemantics: true)`** (p31, p32): the tap is
  hidden from the screen reader; the `InkWell` still takes keyboard focus
  and Enter runs it, the `GestureDetector` takes none. Handed to I01.
- **`IndexedStack`** (p29): the panes not shown are out of the tree and
  out of the keyboard's reach, as with `Visibility(maintainState: true)`:
  it puts each child not shown in an `ExcludeFocus`, and its render object
  gives such a child no painting, hit testing, or semantics (source read,
  `widgets/indexed_stack.dart`). `good-visibility` covers the same result.
- **`Tooltip(excludeFromSemantics: true)`** (p30): C12's subject.
- **A struck-out price** (p33), which the iOS reference counts as text
  that is correct to hide (reading the old price aloud "would claim to be
  the current price"): Flutter exposes a struck-out text as plain text,
  "$30", with nothing about the line through it, on every platform, as the
  reference says. Not built: whether to hide the old price or say it in
  words ("was $30") is a wording choice, S01's subject.

## 6. Assertions by layer

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Good, in light and dark: the four guidelines (for `good-visibility` with the panel hidden and again shown); the ornaments, which the text contrast guideline does not see once they are out of the semantics tree, 4.5:1 or more on the page; the badge's text on its colour 4.5:1 or more (Material 3's defaults, `onError` on `error`) and the icon 3:1 or more on the page; the switch's track 3:1 or more on the page off (`outline`) and on (`primary`); Copy's 2 pixel outline in the text colour, 3:1 or more, only while focused; the text contrast guideline with focus on the switch and on Copy. The example's nodes after the "Example" heading, exactly: `good-decoration` the quote and its source, and no label anywhere on the screen with "❝" or "✦"; `good-badge` "Inbox: 3 unread", and no other label with a "3". `good-visibility`: hidden, the switch alone, off, and no node for the number or Copy anywhere, and a whole Tab cycle (Tab until focus comes back to its first stop) is Back and the switch; shown, in the same launch, the switch on, the number, and Copy, and the cycle Back, the switch, Copy. Hidden, Enter and Space each on the switch (its only stop but Back) copy nothing and show the panel; in the same launch Tab to Copy and the same key copies. Shown, a tap and the tap action on Copy each copy. Every example at 200% text on 320 by 640, the panels shown: no overflow, no text at its line limit or cut short, nothing past the screen. Bad: `bad-decoration-read` exactly "❝", the quote, the source, "✦ ✦ ✦"; `bad-hidden-control` exactly the quote, no label "Share", no button but Back, a whole Tab cycle Back and Share, Enter and then Space with focus on Share and no node focused each share, and a tap on it shares; `bad-opacity` and `bad-maintain`, hidden (the opacity read as 0, `Visibility.visible` false): the whole Tab cycle Back, the switch, Copy, Enter and then Space on Copy each copy and the switch stays off; with focus on Copy the screen's pixels are the same as with no focus at all, and, shown, in the same launch, focus on Copy changes them (the positive control); `bad-opacity` hidden has only the switch as a node, no node for the number or Copy, no node focused with focus on Copy, and a tap on Copy's place copies; `bad-maintain` hidden has the switch, the number, and Copy as nodes, and Copy's tap action copies. The tests run as Android |
| L3 web | The example's elements after the "Example" heading, up to its count, read from the page's `flt-semantics` elements, exactly: `good-decoration` the quote and the source as texts, no name or text in the page with "❝" or "✦", one button (Back); `good-badge` "Inbox: 3 unread" alone, no other text with a "3", no image; `good-visibility` hidden: the switch, `aria-checked="false"`, no number, no Copy; a whole Tab cycle is Back, the switch, then out of Flutter's elements and back to Back (FL-421); shown, in the same load, the switch, the number, and the Copy button, and Tab reaches Copy. Enter and Space each: hidden, with Tab past the switch, copy nothing; then on the switch show the panel and copy nothing; then Tab to Copy and the key copies. Shown, a click and a DOM click (what a screen reader's activation sends) each copy. Bad: `bad-decoration-read` exactly "❝", the quote, the source, "✦ ✦ ✦"; `bad-hidden-control` exactly the quote, no text "Share", one button, Back; after two Tabs DOM focus is on Back, and Enter, and in another load Space, share and leave the screen open; in another load one Tab and the same key leave the screen (the key on Back, the positive control); a click where Share is drawn, between the quote and the count, shares; `bad-opacity` hidden: the switch alone, no number, no Copy; after the Tab past the switch DOM focus stays on the switch, and Enter copies, and in another load Space, with the switch still off; a click where Copy is laid out copies; `bad-maintain` hidden: the switch, the number, and the Copy button; Tab reaches Copy, and Enter and Space copy with the switch off. Each screen shows the title and lines the VoiceOver judge expects above its heading. The judge (`web_tests/vo/s12_vo_walks.js`, S08's) on made-up walks, its mutation cases in two tests that name every case in their messages, and the committed transcript judged again from its rows alone (`judgeTranscript`, row L4 VoiceOver web) |
| L3 Android | The example's nodes after the "Example" heading, with their class, name, and checked state, the screen scrolled to the count: `good-decoration` exactly the quote and the source as `View`s, and no name on the screen with "❝" or "✦"; `good-badge` exactly "Inbox: 3 unread", and no other name with a "3"; `good-visibility` hidden: the switch alone, a `Switch`, not checked, and no node named by the number or Copy; Tabs from a fresh launch stop only on Back and the switch; in the same launch, shown by the click action: the switch checked, the number, and Copy, and Tab to Copy and Enter copy. Hidden, one to three Tabs and Enter, each from a fresh launch: the try that lands on the switch copies nothing, and in that launch Tab to Copy and Enter copy. Shown, the click action and a tap at Copy's centre each copy. Bad: `bad-decoration-read` exactly "❝", the quote, the source, "✦ ✦ ✦" as `View`s; `bad-hidden-control` exactly the quote, no node "Share", no clickable node but Back; from a fresh launch each, one to three Tabs then Enter, and then Space: one try shares, with no node named Share focused, and one leaves the screen (the key on Back); a tap where Share is drawn shares; `bad-opacity` hidden: the switch alone, no node for the number or Copy; Tab to the switch, one more Tab, then Enter, and in another launch Space, copy with the switch still off; a tap where Copy is laid out copies; `bad-maintain` hidden: the switch, the number, and Copy as nodes; Tab to Copy and Enter copy with the switch off, and the click action on Copy copies. Run once at CI's 320 by 640 at 160 dpi as well |
| L3 iOS | `good-decoration` one element each for the quote and the source, and no label with "❝" or "✦"; `good-badge` "Inbox: 3 unread" the only label with a "3", no image; `good-visibility` hidden: the switch (type switch, value "0"), no element for the number or Copy, no button but Back; shown, in the same launch, by a tap: the number, and Copy a button, which a tap makes copy. Hidden, three Tabs (the probe found the first on Back) and Return, and in another launch Space, leave the screen: the third Tab is on Back again, with no stop for Copy between the switch and Back; from a fresh launch, shown first, the same keys copy and leave the screen open. Bad: `bad-decoration-read` one element each for "❝", the quote, the source, and "✦ ✦ ✦"; `bad-hidden-control` no element "Share", no button but Back; two Tabs and Return, and then Space, each from a fresh launch, share and leave the screen open; one Tab and Return leave it (on Back, the positive control); a tap where Share is drawn shares; `bad-opacity` hidden: no element for the number or Copy, no button but Back; three Tabs and Return, and then Space, copy with the switch still off; a tap where Copy is laid out copies; `bad-maintain` hidden: the number and Copy, a button, are there; three Tabs and Return copy with the switch off. XCUITest cannot see Flutter's focus or traits; no key has a modifier |
| L4 TalkBack | Focus moved to each part by action. Every row is a whole-utterance row (`"== A / B / C"` in `tool/talkback.py`'s `said()`, S06's form): the row's utterances must be exactly these, in this order, each compared whole, with TalkBack's usage hint "Double-tap to activate" allowed once at the end and nothing else: `good-decoration` "Walk the ridge before the sun is up." and "Trail guide", each alone; `good-badge` "Inbox: 3 unread"; the switch of `good-visibility`, `bad-opacity`, and `bad-maintain` "off.", "Show tracking", "Switch", "Double-tap to toggle" (its own hint, which the form does not treat as optional, so it is required as heard); each count "Copies: 0" or "Shares: 0"; `bad-decoration-read` "❝", the quote, the source, "✦ ✦ ✦"; `bad-maintain`'s hidden parts "Tracking number: 1Z 999" and "Copy number", "Button". The tool tests (`S12WholeUtterances` in `tool/test_talkback.py`) take every row and check that its right reading passes, with and without the hint, and that each mutation is wrong: the speech duplicated, an unexpected role word added, a wrong token, the hint twice, and each sibling row's label in place of its own or before it; and that the committed transcript is still right. No second mechanism is added. Each walk is judged whole (`walk_strictly`; S12 is in `STRICT` in `tool/talkback.py`): a walk with a wrong reading fails for good, only a walk shown to be incomplete is walked again, up to three walks, every walk in the transcript. No row is declared silent: what is hidden is not a node, and a walk by action cannot focus it, so its absence is the tree test's. The probe's finding that TalkBack says nothing for the Tab that lands on a hidden button stays probe-only and is not a judged row (the principal's decision, section 8): which Tab lands there depends on touch mode (the probe's p01 spent its first Tab leaving it), and with focus reported on Back either way the walk cannot tell which Tab it was, so a silent row could not be tied to that Tab |
| L4 VoiceOver iOS | The whole walk from the top of the screen to its end (`S12Walk.collect`, as S11's and S16's): every utterance is kept as a stop; a stop read twice in a row and then followed by another utterance fails the walk ("a duplicate stop"); two repeats in a row end it only with a witness, one move back that reads the stop before the last and one move forward that reads the last again, both shown in the transcript; anything else read there fails it ("the end is not shown"). `testTheCollectorFailsADuplicateStopStaleSpeechAndAWrongWitness` (no VoiceOver) checks a duplicate title, a duplicate stop after the heading, stale speech at the end, a move back that reads another element or nothing, a move forward that reads something else, and a walk that runs out of moves. The walk is judged against this example's own screen (`S12Walk.judge` in `S12HidingContentUITests.swift`): Back may come first, then the screen's title read "<title> Heading", its description, a bad example's defect (longer than the service's 64 characters, so matched by its first 63 and an utterance 64 long), the "Example" heading once, then exactly the expected content and nothing more. So a walk of another screen cannot pass for this one, where two examples expect the same content (`good-visibility` and `bad-opacity`). The whole walk, its identity included, is the transcript row. `testTheVoiceOverJudgeTiesAWalkToItsScreen`, which needs no VoiceOver and runs in the iOS tree layer, judges made-up walks: each example's own walk passes; `good-visibility`'s walk judged as `bad-opacity`, and the other way round, fail; so do a walk with no title, no description, an empty title, no stops, no defect on a bad screen, the heading twice, a stop before the title that is not Back, changed content, a stop after the content, a walk that did not reach the end, and a defect line cut too short. The content lists are those in `S12HidingContentUITests.speech`, written from the probe's readings of text and buttons and from F09's transcript for a `SwitchListTile` ("Bluetooth Switch button off Double tap to toggle setting."), then checked by the first S12 recording (section 7). Every expected utterance is under 64 characters; the test refuses one that is not |
| L4 VoiceOver web | The walk is `collectWalk` (`web_tests/vo/s12_vo_walks.js`), whose capture and moves are passed in: a move is a stop when the cursor moved or a new phrase was spoken, and two moves that do neither end the walk only with a witness, one move back whose fresh capture is the stop before the last by its phrase at another position, and one move forward whose capture is the last stop again at its position. A frozen or empty capture at the witness fails the walk for good (`judgeCollectedWalk`), and both witness readings are logged as a row of their own (`<slug>-walk-<n>-end`). A single move that does neither, followed by one that moves on, is an unresolved read: the move may have reached an element whose capture was lost. A walk with one is incomplete whatever its stops say, is walked again (at most three walks), and never passes; every walk logs its unresolved reads, or "none", as a row of its own (`<slug>-walk-<n>-unresolved`). The web tree spec drives `collectWalk` with made-up screens: the capture frozen after `good-badge`'s expected stops while the cursor goes on through "3" and a button (the reviewer's case, which judged complete before the witness), empty phrases at a frozen position, a move back that reads another stop, the right words at the last position, or nothing, a move forward that reads another stop or the last words elsewhere, a walk that runs out of moves, and a screen of one stop; and lost captures: an exposed "❝" after `good-decoration`'s heading whose move reads the heading's phrase and bounds again, or no phrase at them (the stops are then exactly the expected screen, and the walk is incomplete by its unresolved read), `bad-decoration-read`'s own "❝" lost in the same way (incomplete, not wrong), the stop before the last lost (the witness then fails, wrong), and a lost read followed by the true end (the end, through the witness, but incomplete). Every walk must read the whole screen, each stop in its place (`judgeExampleWalk` in `web_tests/vo/s12_vo_walks.js`, a copy of S08's): the title, the description, a bad example's defect, the "Example" heading, then exactly the expected list, to the end of the screen. A wrong stop fails for good and is looked for first; a walk that reached the end with an expected stop not read fails for good; a stop past the expected end fails for good, an empty one included (the bounds check runs before the empty-stop check); a stop read as an empty phrase in an expected place is a failed capture, walked again, and never passes; only a walk cut short, or one with an empty capture and nothing wrong, is walked again, at most three walks, every walk logged. No runner retries (`retries: 0`). `walkWithPositions` keeps each stop's cursor position; VoiceOver's help message ("You are currently on …") is left out only at the same position as the judged stop before it, a reading whose spoken role (`spokenRole`: heading, switch, button) is the help's role; any other help message is a wrong stop, and one in place of an element's own speech fails. The help rule is tested only synthetically, by the regression cases in the web tree spec: no recorded walk had a help message. The expected lists were written as predictions and were confirmed by the recording of 2026-11-27 (section 7). Every try is logged whole, the screen's own stops included (an empty phrase as "(empty)"), so the transcript keeps each walk's browser, example, try, title, description, and heading. The web tree spec judges the committed transcript again from its rows alone (`judgeTranscript`): every browser and example exactly once, walks numbered from 1 with no gap or repeat, no malformed row, no row for an unknown browser or example, and each walk judged on the stops it recorded with nothing put back, the last complete and every earlier one incomplete. Its regression cases, in one test that names each: a right transcript passes; fourteen copies of the first Chromium row, a missing example, a missing browser, an unknown browser, a repeated row, a malformed row, an unknown example, `good-visibility`'s walk under `bad-opacity`'s name, a row as the first recording logged it (after the heading only), a walk with no title, a walk whose title is an empty phrase, a last walk recorded wrong, a walk 2 with no walk 1, a wrong walk before a complete one, and a stop past the end all fail; an empty first walk walked again and then complete passes. Each walk must have one unresolved-reads row, "none" for the last walk; a last walk with an unresolved read, a walk with no such row, an earlier walk with an unresolved read recorded complete, the row twice, a row for a walk that is not there, an empty transcript, and a transcript with every end row or every unresolved-reads row removed all fail; an earlier walk with an unresolved read, recorded incomplete though its stops judge complete, then a complete walk, passes. The test of the committed transcript always runs; it is not skipped for a transcript recorded under older rules |

## 7. What the build found (Flutter 3.47.5)

The probe that came first is in
[evidence/probes/s12](../evidence/probes/s12/README.md): 34 fixtures, each
of Flutter's ways to hide round a note or a `TextButton`, in widget tests,
Chromium, Android 17, and iOS 27.0, and a plain HTML page in Chromium. Its
README has the table, fixture by fixture, from the raw files.

- **`ExcludeSemantics` round what has no control hides it from every
  screen reader and changes nothing else** (p02, p26, p28;
  `good-decoration`, `good-badge`). No node, element, or XCUITest element
  is left, and VoiceOver on iOS, moving forward, went from the line before
  to the line after.
- **Ornaments left as they are are text, a node each** (p25,
  `bad-decoration-read`), on every platform: "❝" before the quote, if it is
  in the same `Text`, joins the quote's node ("❝ p25 Quote"); in a `Text`
  of its own it is a node of its own. VoiceOver's utterances on iOS hold
  the same characters; how VoiceOver pronounces them is not something the
  service returns, and was not measured.
- **A badge's count is a node of its own, "3"** (p27), read by VoiceOver
  on iOS as "3" before the text; in `ExcludeSemantics` (p28) only the text
  is left.
- **A control hidden from the semantics tree keeps keyboard focus**
  ([FL-350](../flutter-limitations.md#fl-350), new): `ExcludeSemantics`
  (p03), `Semantics(label:, excludeSemantics: true)` (p04, S10's
  replacement), `Opacity` at 0 (p13) and `AnimatedOpacity` at 0 (p15),
  `IgnorePointer(ignoringSemantics: true)` (p18), and `BlockSemantics`
  (p23, p24). On all four, no node for the button, Tab gives it focus, and
  Enter runs it, Space as well where sent (p03, p13). On the web DOM focus
  stays on Back, and Chromium's tree has Back focused (`web-round2.txt`);
  on Android the node reported as focused stays Back. A tap where it is
  laid out runs it (p03, p04, p13, p15, p23). `Offstage` (p05) and
  `Visibility` with `maintainFocusability` (p12) do the same, which is
  [FL-263](../flutter-limitations.md#fl-263), extended.
- **`Visibility(visible: false)` hides from everyone** (p06 to p10; the
  keyboard tried on the devices for p07, p09, and p10, and in the widget
  tests and the web for all five): no node and no keyboard stop, with or without `maintainState`,
  `maintainAnimation`, and `maintainSize`, because it adds an
  `ExcludeFocus` (its documentation; source read); `maintainSemantics`
  (p09) leaves the button in the tree, a button with no tap action, read
  by VoiceOver as "p09 Share Button"; `maintainInteractivity` (p10) lets a
  tap through. `Visibility.maintain` (p11) keeps everything: the hidden
  button is in the tree with its tap action, VoiceOver reads it, the
  keyboard reaches it, and a tap runs it: `bad-maintain`. `IndexedStack`'s
  pane not shown (p29) is hidden from everyone, as `Visibility` with
  `maintainState`.
- **`Opacity(alwaysIncludeSemantics: true)`** at 0 (p14) is
  `Visibility.maintain`'s: all there, as if shown.
- **`ExcludeFocus`** (p19) takes the button out of the keyboard's order
  only: it is still a button with its tap action, read by VoiceOver, and a
  tap runs it. Round it, `ExcludeSemantics` (p20) leaves only the tap.
- **`Semantics(hidden: true)`** ([FL-351](../flutter-limitations.md#fl-351),
  new, probe only): Android left the flagged node and everything under it
  out of the tree; iOS kept both in the XCUITest tree, and VoiceOver's
  moving forward passed over the flagged note (p21) and read the button
  inside the flagged node (p22); the web wrote nothing, and both were in
  Chromium's tree. On every platform the keyboard reached p22's button and
  Enter and Space ran it.
- **`BlockSemantics` blocks up to its container** (p23, p24): inside
  `Semantics(container: true)` it dropped the note and the button before
  it; with no container round it, the screen's "Before" line too, and not
  the app bar.
- **`IgnorePointer` and `AbsorbPointer`** (p16, p17) leave the button a
  button with no tap action: not clickable on Android, no `flt-tappable` on
  the web, read by VoiceOver on iOS as "p16 Share Button"; a tap does
  nothing; and Tab and Enter, and Space (p16), still run it. Not hiding
  content: handed to I01.
- **`InkWell(excludeFromSemantics: true)`** (p31) leaves a node with no
  role and no tap action that still takes keyboard focus (on the web an
  element with `tabindex="0"` and no role), which Enter and Space run;
  **`GestureDetector(excludeFromSemantics: true)`** (p32) leaves plain
  text that the keyboard does not reach. A tap runs both. Handed to I01.
- **A struck-out price** (p33) is plain text, "$30", on every platform,
  with nothing about the line through it; the iOS reference counts hiding
  one as correct.
- **Plain HTML** (Chromium): `hidden` and `inert` take a button out of
  the tree and out of Tab's reach; `aria-hidden` takes it out of the tree
  until it has focus, and then Chromium's tree has it, focused, named, a
  button, as WAI-ARIA 1.2, 7.2, has user agents do. That is what Flutter
  has no counterpart for (FL-350).

- **TalkBack** (probe, `android-talkback.md`): each node was read by its
  text, the ornaments as the characters sent to speech ("❝ p25 Quote",
  "· · ·", "✦ ✦ ✦"), and a button with no tap action (p09, p16) as "p09
  Share / Button" with no "Double-tap to activate". Swipes sent with
  `input swipe` moved nothing, as in S09, so TalkBack's own navigation is
  not measured. With TalkBack on, the Tab that gives a hidden button
  keyboard focus (p03, p13, and p05) was not spoken at all, between a Tab
  that read Back and one that read the next button; input focus stayed
  reported on Back (round 2, `android-talkback-keys.md`). That is in the
  probe only: which Tab lands on the hidden button depends on touch mode,
  so no transcript row asserts it.

The first evidence run (2026-11-27) passed every layer it ran but one,
the iOS tree test of `good-visibility`'s keys
(`docs/evidence/probes/s12/ios-evidence-round1-fail.txt`). It expected the
count to stay at 0 after three Tabs and Return with the panel hidden; the
third Tab was on Back, as the probe's p07 had shown, and Return left the
screen, so there was no count to read. The test now asserts what happens:
hidden, the third Tab and the key leave the screen, with no stop for Copy
between the switch and Back; shown, the same keys copy. Nothing in the
example changed. The iOS layer was then run again on its own and passed.
The Android tree tests at CI's size, 320 by 640 at 160 dpi, failed once
(`docs/evidence/probes/s12/android_320x640-round1-fail.txt`): `bad-opacity`'s
single tap where Copy is laid out copied nothing. Why was not measured:
the tap was placed from the switch's and the count's bounds read with
`node()`, which scrolls to a node that is out of the tree, and at that
size the example is below the fold. The tap is now placed from one state,
the screen scrolled to its end, at four points down the gap between the
switch and the count, and one of them must copy. The suite then passed at CI's size
(`docs/evidence/probes/s12/android_320x640.txt`) and again at the
emulator's own size. The TalkBack transcript
(`docs/evidence/S12/talkback-android.md`) passed on its first walk, and
the iOS VoiceOver transcript (`docs/evidence/S12/voiceover-ios.md`) read
every example as listed, the switch as F09's had been read ("Show
tracking Switch button off Double tap to toggle setting.").

The web VoiceOver recording, made by the principal on 2026-11-27
(`docs/evidence/S12/voiceover-web.md`; macOS 27.2.1, Playwright 1.65.0's
Chromium and WebKit builds), passed: 14 walks of 14, every one complete on
its first walk, the same in both browsers. Every expected list, written as
a prediction from the tree and from F09's reading of a `SwitchListTile`,
was read as written: `good-decoration` the quote and "Trail guide";
`good-badge` "Inbox: 3 unread"; `good-visibility` and `bad-opacity` "Show
tracking off switch" and "Copies: 0"; `bad-decoration-read` "❝", the quote,
"Trail guide", "✦ ✦ ✦"; `bad-hidden-control` the quote and "Shares: 0";
`bad-maintain` "Show tracking off switch", "Tracking number: 1Z 999", "Copy
number button", and "Copies: 0". No walk had an empty stop or a help
message, so the judge's rule for a help message was not exercised by a
real walk. What VoiceOver on the web says when keyboard focus lands on a
hidden button was not measured: the walks move with VoiceOver's own
`next`, not Tab. The ornaments' stops hold the characters as VoiceOver's
last phrase gives them; how the voice pronounced them is not in it.

**The web VoiceOver transcript was recorded again.** The first
recording logged a complete walk only from the "Example" heading on, and
the re-judging test put the screen's own stops back from today's
expectations, so it could not show which screen a row came from: fourteen
copies of one row would have passed (Codex, review of 7328954). The
VoiceOver spec now logs every try whole, and the re-judging test judges
only what a row recorded. The first recording is kept as it was committed
in `docs/evidence/probes/s12/voiceover-web-round1-pass.md.txt`.
The evidence run after the review (2026-11-27) passed the Android tree
tests, TalkBack (every row a whole-utterance row, right on its first walk),
the iOS tree tests (the judge's made-up walks among them), and VoiceOver on
iOS (each walk judged whole against its own screen; the transcript now
shows the whole walk); its web layer failed on the re-judging test alone,
against the first recording's old form. The principal then recorded the
web transcript again, 2026-11-27 (`docs/evidence/S12/voiceover-web.md`):
14 walks of 14, every one complete on its first walk in Chromium and
WebKit, each row the whole walk, from "heading level 1 <title>" through
the description, a bad example's defect, "heading level 2 Example", to
the expected list, which was read as in the first recording. No walk had
an empty stop or a help message. The re-judging test passes on it.

**The end of a walk needs a witness** (Codex, review of 90edde5). Two
unchanged readings of the cursor and the phrase were taken as the end of
the screen, with nothing to show that the capture was still live: with
injected captures, a capture that froze after `good-badge`'s expected stops,
while the cursor went on through an exposed "3" and an unexpected button,
judged complete, and so did empty phrases at a frozen position. On iOS the
end was likewise two repeated utterances. Both walks now accept the end
only with a witness: one move back that reads the stop before the last
(on the web, also at a position other than the last stop's), and one move
forward that reads the last stop again (on the web, at its position). A
failed witness fails the walk for good. On the web an empty phrase at the
witness is not the failed capture the empty-capture rule walks again: that
rule is for the walk's own stops, whose moved cursor shows they are new; at
the witness an empty phrase cannot be told from a frozen capture.

**A lost capture mid-walk is unresolved** (Codex, third review, of
739520f). A single unchanged reading mid-walk was dropped at once, and the
next move that moved on reset the count without a trace. With an exposed
"❝" injected after `good-decoration`'s heading, its move reading the
heading's phrase and bounds again (or no phrase at them), and every later
capture and the witness live, the stops were exactly the expected screen
and the walk judged complete: the element vanished from the evidence. Now
such a read is kept as unresolved, with the stop it came after, its phrase,
and its position, and logged on its walk's `-unresolved` row. The walk is
incomplete and walked again, not wrong for good: a real transient capture
failure looks like that, a reading taken before VoiceOver updated its last
phrase and cursor, followed by fresh readings, the same failure the
empty-capture rule walks again. Its stops may lack an element, so they can
be trusted neither to pass nor to fail it. An incomplete walk never passes,
so three walks with a lost read fail. A lost read of the stop just before
the last is caught by the witness instead (the move back reads the lost
element), and that walk is wrong for good, as any failed witness is. Two
unchanged readings in a row are still the end, with its witness. The
transcript format changed (one `-unresolved` row per walk), so the
committed web transcript, recorded before this, fails the re-judging test
until the principal records it again; the test is no longer skipped for a
transcript recorded under older rules.

What the witness cannot show. It shows that the capture was live at the
end and that the cursor stood on the last stop read. It cannot show that
this stop is the screen's last element: if the capture froze exactly at the
real last element, or if VoiceOver itself stops moving while elements
follow, the move back and forward read true stops and the walk ends there;
the elements after it are then missing from the walk, and the judge fails
the walk only if one of them was expected. On iOS a move forward from the
last element onto an element the service reads with no speech is recorded
as a stop, as the earlier walk did (`VoiceOverWalk.afterNoSpeech`), and an
element VoiceOver never moves to is not seen on either platform.

The web VoiceOver transcript committed at 90edde5 was recorded before the
witness, so it had no witness rows, and the web tree spec's test of it was
skipped with that reason. The principal recorded it again on 2026-11-27
(`docs/evidence/S12/voiceover-web.md`): 14 walks of 14, each complete on
its first walk in Chromium and WebKit, each with its end row, no empty stop
and no help message; every move back read the stop before the last at
another position, and every move forward the last stop again at its
position, as the cursor's bounds show ("318, 355, 386, 375"). The readings
are those of the two recordings before. The test runs on it and passes. A
cursor position has commas and spaces, which S17 found its copy of this
judge read as malformed; the end-row pattern here reads it whole, and the
made-up rows and walks now use positions in that form, so a pattern that
read it as one word would fail them.
The evidence run after this change (2026-11-27, `--only
ios,voiceover-ios,web`) passed all three: every iOS walk ended with its
witness, the move back reading the stop before the last and the move
forward the last again, each shown after its row in
`docs/evidence/S12/voiceover-ios.md`.

What the tests skip or cannot see, and what each gives up:

- The widget tests run as Android (`kIsWeb` false): what the web engine
  makes of a node is seen only in the web tests.
- The example's nodes are compared only where they have a label or a tap
  action (widget tests), a name or a click action (Android), or a role, a
  label, or text of their own (web): a container with none is left out.
- "No ornament anywhere" is checked by the characters "❝" and "✦" in any
  label, name, or text of the screen; a hidden ornament reworded into other
  characters would not be caught by that check, and is caught by the exact
  lists of the example's nodes.
- On Android the screen is read from the top and then scrolled a step at
  a time to the count, each node kept once by its name, class, and
  identifier: two nodes alike would count as one; no example has two.
- XCUITest cannot see Flutter's focus or traits. The iOS key tests rely on
  the probe's finding that the first Tab is on Back and each later one on
  the next control; which count changed is what shows where the key went.
  No key with a modifier is sent, so CI's iOS 26.5, where modifiers were
  unreliable, is not a concern here.
- On Android, `bad-hidden-control`'s key test tries one, two, and three
  Tabs from a fresh launch each, because the first Tab can be used up
  leaving touch mode; it requires one try to share and one to leave the
  screen, and does not require which.
- The taps "where a hidden button is drawn" are placed between the
  neighbouring lines, at a few points across or down the gap, and the test
  passes when one of them copies (or shares) and fails when none does; it
  gives up which point it was. A point that hit the switch instead would
  turn it on, and the panel tests require the switch to stay off.
- The 2.4.7 measurement compares the route's pixels in the widget tests,
  with the test framework's text drawn as boxes; it is not a screenshot
  of a device.
- The TalkBack walk moves focus to each node by action and cannot focus
  what has no node; the tree tests show that the hidden parts have none.
- The iOS VoiceOver walk is C03's: it ends where moving on gives the last
  utterance again, twice, and so gives up two neighbouring elements that
  VoiceOver reads alike; no example has two.

**Not done yet.** How each screen reader pronounces the
ornaments' symbols. TalkBack's and VoiceOver's own navigation by swipe or
by keyboard, which the tests could not drive or did not try. VoiceOver's
own activation on iOS, which XCUITest cannot make (C04 probe round 3): the
taps are taps at a place. A native iOS or Android comparison: no
limitation here rests on what a native platform does; FL-350's
comparison is with HTML, measured. The sliver forms of the hiding widgets.
Dark mode on a device; text scaling on the web; right-to-left text.

## 8. Decisions

The principal's, on 2026-11-27, on the engineer's questions (the owner
may overrule):

1. **FL-350 stays its own entry beside FL-263.** The mechanism is the
   same, semantics dropped and focus left alone; FL-263 is about
   `Offstage` and the expansion widgets that use it, and FL-350 about the
   other widgets. FL-263 is extended with S12's measurements of
   `Offstage`.
2. **All three platforms stay "applies".** The good examples meet the
   requirement without the gaps in FL-350 and FL-351: the rule asks that
   no control be hidden, and `Visibility` hides from everyone together.
3. **`bad-decoration-read` and `bad-maintain` stay.** Each is not a shown failure of a success criterion in this technique's list; shown for what the user hears
   (section 3); for `bad-maintain`, 2.4.7 was measured in widget tests
   only and is outside S12's list. The spec, the technique doc, and the
   example text say so.
4. **The TalkBack silence on a hidden-focus Tab stays probe-only.** It is
   not a judged row, because which Tab lands on the hidden button depends
   on touch mode and the walk cannot tell (section 6).

Not asked: there is no Cupertino example (section 4).

## 9. What is handed on

- **I01 Focusable and clickable controls**: `IgnorePointer` and
  `AbsorbPointer` leave a button with no tap action that the keyboard still
  runs (p16, p17); `InkWell(excludeFromSemantics: true)` leaves a focusable
  node with no role or tap action (p31).
- **Wave 7, dialogs and overlays**: `BlockSemantics` and what it leaves in
  the keyboard's order (p23, p24, FL-350), next to FL-483.
- **S10 Content group replacement** (merged): its hand-off, that
  `excludeSemantics: true` hides a control and leaves it in the keyboard's
  order ([S10's spec](S10-content-group-replacement.md), section 9), is
  FL-350, measured again here (p04); its `bad-hides-control` is that
  defect.
- **C05 Accordion**: `Visibility(visible:, maintainState: true)` keeps a
  closed panel's state and takes it out of the keyboard's order (p07),
  the workaround FL-263 had not tried.
