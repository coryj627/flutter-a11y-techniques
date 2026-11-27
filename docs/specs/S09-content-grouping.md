# Spec: S09 Content grouping

Status: Draft 1 (2026-11-26), written with the build. Wave 3, structure and
order. Flutter pin: 3.47.5.

Related content is exposed as one unit, or as a named group, as the
content needs. Out of scope, and covered elsewhere: a card as one unit or
as separate parts, [C18 Card](C18-card.md) (FL-262, FL-269); groups of
checkboxes, radio buttons, and switches, [F07](F07-checkbox.md),
[F08](F08-radio-group.md), and [F09](F09-switch.md), whose named groups
are built as `good-named-group` is here; lists, S08; reading order, S11; a
control's own label, [S01](S01-accessible-names.md) and
[F01](F01-text-fields.md); a merged sentence with links,
[C04](C04-links-inline-with-text.md) (FL-243).

## 1. Rule

Pieces of text that are read as one thing, such as a label and its value,
are one stop. A set of related controls is a group named by its visible
question, and a screen reader says that name on the way into the group.
An icon and its text that do one thing are one control named by the text.
Controls that do different things are never merged into one.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Limitation (FL-320) | Limitation (FL-320) | Applies |

A merged label and value, and an icon and text as one button, work on all
three. A named group works on the web only: there a labelled node round
the buttons is a `group` named by the question. On Android and iOS Flutter
has no group a screen reader names: the name is a stop of its own before
the buttons, and a button is read without it
([FL-320](../flutter-limitations.md#fl-320), new). Natively both
platforms have one, and their screen readers speak it on the way in:
TalkBack read a container title as "On. Button. In Kitchen light", and
VoiceOver a semantic group as "Kitchen light On Button" (the native
comparison, section 7). Flutter has no documented parameter for either,
so by the owner's rule of 2026-11-23 both platforms are a limitation (the
principal's decision 1, section 5), and `good-named-group` does not meet
R4 on them.

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [1.3.1 Info and Relationships](https://www.w3.org/TR/WCAG22/#info-and-relationships) | A label shown with its value, and a question shown over its buttons, are relationships shown by layout; they must be programmatically determined or in the text |

For 1.3.1: the relationships here are a label and the value set under it,
in a table of two columns, and a question and the buttons that answer it.
[H71](https://www.w3.org/WAI/WCAG22/Techniques/html/H71) (`fieldset` and
`legend`) and [ARIA17](https://www.w3.org/WAI/WCAG22/Techniques/aria/ARIA17)
(grouping roles) are the sufficient techniques for a group of controls in
HTML. `bad-split-facts` reads both labels and then both values, with
nothing in any element or in the order tying a value to its label: the
relationship that the columns show is lost, which fails 1.3.1 as written,
on all three platforms (section 7).

`good-named-group` on Android and iOS: the question is exposed as text
read just before the buttons, and on Android as the node that holds them,
so no 1.3.1 failure is claimed; what is missing there is R4, the name said
on the way into the group, which the iOS reference requires and which
native groups on both platforms were measured to give (section 7).

Other criteria the examples touch are named where they fail: 4.1.2 Name,
Role, Value (`bad-merged-group`, all three).

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | Content that belongs together, such as a label and its value, is one element, read as one stop | [Android View Content Grouping](https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/grouping/ContentGrouping.md) and [Android Compose Content Grouping](https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/content/ContentGrouping.md) ("Group content labels with their values"), [iOS Combining Focus](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/CombiningFocus.md) (`.accessibilityElement(children: .combine)`) |
| R2 | A unit is read in the order shown, and a table's labels are not all read before its values | Android View and Android Compose Content Grouping ("misgrouping or a lack of grouping could read all the table headings, then the table values") |
| R3 | A set of related controls is a group whose name is its visible question | [iOS Grouping Controls](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/GroupingControls.md) (`.accessibilityElement(children: .contain)` and `.accessibilityLabel`), [MDN `fieldset`](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/fieldset) (implicit role `group`, captioned by its `legend`), [H71](https://www.w3.org/WAI/WCAG22/Techniques/html/H71) |
| R4 | The screen reader says the group's name when focus first comes to a control in the group | iOS Grouping Controls ("VoiceOver users need to hear the group label text spoken when they first focus on a control in a group of related controls"); measured to hold for native groups on iOS (a semantic group) and Android (a container title, "In …"), section 7 |
| R5 | An icon and its text that do the same thing are one target, named by the text, and the icon adds no name of its own | [Android View Tap Target Grouping](https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/grouping/TapTargetGrouping.md) ("Group adjacent tap targets that perform the same action"; "Disable any redundant content description") |
| R6 | Controls that do different things are not merged into one unit: each keeps its own name, role, and action | iOS Combining Focus (a button combined into its parent loses its label unless its trait is removed, and "important traits" must be added back), [FL-243](../flutter-limitations.md#fl-243) |

Flutter references for the mechanisms used:

- [`MergeSemantics`](https://api.flutter.dev/flutter/widgets/MergeSemantics-class.html)
- [`Semantics.container`](https://api.flutter.dev/flutter/widgets/Semantics/container.html), [`Semantics.explicitChildNodes`](https://api.flutter.dev/flutter/widgets/Semantics/explicitChildNodes.html), [`Semantics.label`](https://api.flutter.dev/flutter/widgets/Semantics/label.html), [`ExcludeSemantics`](https://api.flutter.dev/flutter/widgets/ExcludeSemantics-class.html)
- [`CupertinoListSection`](https://api.flutter.dev/flutter/cupertino/CupertinoListSection-class.html), [`CupertinoListTile`](https://api.flutter.dev/flutter/cupertino/CupertinoListTile-class.html)
- [`TextButton.icon`](https://api.flutter.dev/flutter/material/TextButton/TextButton.icon.html), [`ButtonStyle.side`](https://api.flutter.dev/flutter/material/ButtonStyle/side.html)

Radix comparison bar: Radix has no grouping primitive; the bar is HTML's
`fieldset` with a `legend` for a group of controls, and text in one element
for a label and its value. In Chromium a `fieldset` is a `group` named by
its legend, as is a `role="group"` with `aria-labelledby` or `aria-label`
(probe, plain HTML lines of `web.txt`).

What the platforms offer that Flutter does not use (read in the platform
documentation, not measured): Android 14 added
[`AccessibilityNodeInfo.setContainerTitle`](https://developer.android.com/reference/android/view/accessibility/AccessibilityNodeInfo#setContainerTitle(java.lang.CharSequence)),
"used to group together related controls, similar to HTML fieldset";
whether TalkBack speaks it was not measured. Flutter's Android bridge does
not set it: no node in the probe had one (`android-tree.txt`), and the
name does not occur in the compiled `AccessibilityBridge` class of the
pinned engine (its strings were read, not its source). SwiftUI's
`.accessibilityElement(children: .contain)` is the iOS reference's
mechanism; Flutter has no parameter for it.

### Flutter's candidates

Read in the pinned SDK before choosing:

- `SemanticsRole` (in `dart:ui`) has no `group` role. Its grouping roles are
  `radioGroup` (F08's `RadioGroup` uses it), `list` and `listItem` (S08),
  `table`, `row`, and `cell`, `menu` and `menuBar`, `tabBar`, and the
  landmarks `form`, `region`, `main`, `navigation`, `complementary`, and
  `contentInfo` (S07, FL-019). None is a group of controls.
- The web engine gives `role="group"` to any node that has a label and
  children and no role of its own (`GenericRole` in the web engine's
  `semantics.dart`, source read): that is what `good-named-group` gets.
- `MergeSemantics` makes one node of everything under it, controls
  included. `Semantics(container: true)` makes a node of its own that takes
  in text with no node of its own (probe s04), and keeps controls as its
  children (s08). A Material `ListTile` merges its title and subtitle
  (s05); a `CupertinoListTile` does not (s20, s21).
- `CupertinoFormSection(header:)` gives its header no tie to its rows: the
  header is text before them, as plain text is (s13).

## 5. Examples

The text examples show two facts, "City" over "Boston" and "Founded" over
"1630", side by side as a table of two columns. The group examples ask
"Kitchen light" with two buttons, "On" and "Off", and a status line under
them ("Light: not set"). The tap target is "App information", with an
info icon, and a count of its opens.

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-merged-facts` | Widgets layer | Each label and its value one stop | `MergeSemantics` round each label and value, in a `Wrap` | R1, R2 |
| `good-cupertino` | Cupertino | The same facts as rows of a Cupertino list, each row one stop | `MergeSemantics` round each `CupertinoListTile(title:, subtitle:)` | R1, R2 |
| `good-named-group` | Material | Two buttons in a group named by the question | `Semantics(container: true, explicitChildNodes: true, label:)` round the buttons, the visible question in `ExcludeSemantics` (F07's `good-group`); `OutlinedButton`s with a 2 pixel focus outline from their own `style` (FL-430) | R3, R4 (web only), R6 |
| `good-tap-target` | Material | An icon and its text as one button | `TextButton.icon(icon:, label:)`, with a 2 pixel focus outline from its own `style` | R5 |

`good-named-group` meets R3 and R4 on the web only. On Android and iOS it
gives the question as a stop of its own just before the buttons, and on
Android as the node that holds them; it does not give R4 there
([FL-320](../flutter-limitations.md#fl-320)), and is not a complete named
group on either. It stays a good example by the principal's decision 3
(below).

No good example is flagged as a custom solution. The register's rows are in
[custom-solutions.md](../custom-solutions.md#s09-content-grouping):
`good-named-group` is borderline, as F07's and F09's `good-group` are, and
the others are Flutter's widgets through their documented parameters.

### Bad

| Slug | Defect | Violates |
| --- | --- | --- |
| `bad-split-facts` | The same table built row by row, the labels in one row and the values in the next, nothing grouped: both labels are read first, then both values | R1, R2 |
| `bad-merged-group` | `MergeSemantics` round the question and its buttons: one button named "Kitchen light On Off", whose action is On's; Off is no element of its own | R6 |

What each fails, by platform, as the criteria are written (section 7 has
the measurements; the web is Chromium, through Playwright, here and
throughout this spec, apart from the F07 VoiceOver recording cited for
WebKit; WebKit's tree was not read):

| Example | Android | iOS | Web |
| --- | --- | --- | --- |
| `bad-split-facts` | 1.3.1: four `View`s, "City", "Founded", "Boston", "1630", in that order, nothing holding a label and its value | 1.3.1: four static texts, read in that order | 1.3.1: four text elements, in that order |
| `bad-merged-group` | 4.1.2: one `Button` named "Kitchen light\nOn\nOff"; no node is Off; its click action turns the light on | 4.1.2: one button with that label; no element is On or Off | 4.1.2: one `role="button"` named "Kitchen light On Off"; no element is Off; a click on it from assistive technology turns the light on |

On every platform the keyboard still reaches Off in `bad-merged-group`:
Tab stops on the merged node twice, and Enter on the second stop turns the
light off (probe s12; the web and Android tree tests). So no 2.1.1 failure
is claimed. What a screen reader activates is the merged node, whose one
action is On's: TalkBack's double tap performs the click action, measured
here on Android; on the web the element's click, measured; on iOS
VoiceOver's own activation is not measured (C04 probe round 3).

### Decisions

Made by the principal on 2026-11-26, on the engineer's questions:

1. The platform status follows the owner's rule of 2026-11-23 wherever the
   native comparison confirms the gap: Android and iOS are a limitation
   for a named group (FL-320). The principal tells the owner.
2. F07 Checkbox and F09 Switch, whose named groups are built the same
   way, are not edited here. Whether they become limitations on Android
   and iOS for their groups is handed on as an open question for the
   owner, with FL-320 (section 7, "Handed on").
3. `good-named-group` is borderline in the custom-solution register, and
   stays a good example, as the owner's C06 ruling of 2026-11-23 kept a
   framework example whose gap is a limitation. The spec, the doc, and
   the example's text say by platform what it gives and does not, and
   never call it complete on a limitation platform.

There is no bad example of a group with its question as plain text: it is
F07's `bad-group-unlabelled`, and on Android and iOS it reads the same as
`good-named-group` (FL-320). There is no bad tap target: two targets for
one action (probe s17, an `IconButton` with a tooltip beside a
`TextButton`) read the same name twice and are two Tab stops, which no
criterion fails, so its defect is not one WCAG names.

## 6. Assertions by layer

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Every example: at 200% text on a 320 by 640 screen, no layout overflow, no text that hits its line limit, none taller than its box, none past the screen's edge. Good, in light and dark: the four guidelines, and for each control the text contrast guideline again with keyboard focus on it, and its focus outline (2 pixels, the text colour, 3:1 or more on the page) while focused and not otherwise. The example's nodes in traversal order, each with its depth: `good-merged-facts` and `good-cupertino` exactly "City\nBoston" and "Founded\n1630"; `good-named-group` exactly "Kitchen light" holding "On" and "Off", buttons with a tap action; `good-tap-target` exactly one button "App information", and a tap on the icon opens it. For each control: a tap, and the tap action, each from a fresh open, set its own status ("Light: on", "Light: off", "Opens: 1"); Tab then Enter, and Tab then Space, the same. `good-named-group`: Tab goes Back, On, Off. Bad: `bad-split-facts` exactly "City", "Founded", "Boston", "1630"; `bad-merged-group` exactly one button "Kitchen light\nOn\nOff" with a tap action, which turns the light on, again after a tap on Off's words has turned it off (the positive control), and three Tabs then Enter turn it off. The tests run as Android, so the web's `group` is not seen here |
| L3 web | The example's elements in the page's order (every semantics element after the "Example" heading up to the status line with a role, a name, or text of its own, with its depth), not the ARIA snapshot, which runs neighbouring texts into one line: `good-merged-facts` and `good-cupertino` exactly two text elements, "City\nBoston" and "Founded\n1630"; `good-named-group` exactly a `group` "Kitchen light" holding `button` "On" and `button` "Off", the group's name in no text element, three buttons in all (Back included); `good-tap-target` exactly one `button` "App information", no image, two buttons in all. `good-named-group`: Tab goes Back, On, Off, then out of Flutter's elements (FL-421) and round to Back. For each control: a click, a DOM click with no pointer events, and Tab then Enter, and then Space (each from a fresh load, the control's role and name checked on the way), set its own status. Bad: `bad-split-facts` exactly four text elements, both labels first; `bad-merged-group` exactly one `button` named "Kitchen light On Off", no button "Off", no group named "Kitchen light", two buttons in all; Tab stops on it twice; three Tabs then Enter turn the light off, and then a DOM click on it turns it on, in the same load. The VoiceOver judge (`web_tests/vo/s09_vo_walks.js`) is tested on made-up walks, and each screen is checked to show the title and lines the judge expects above its heading |
| L3 Android | The example's named and clickable nodes between the "Example" heading and its status line, in the tree's order, with their depth (scrolling a step at a time where the end is below the view, each node kept once): `good-merged-facts` and `good-cupertino` exactly two `View`s, "City\nBoston" and "Founded\n1630", and no clickable node but Back; `good-named-group` exactly a `View` "Kitchen light" whose two children are the `Button`s "On" and "Off", with no container title (Android 14 and later) and no pane title, and neither button's name, hint, or state holding the question; `good-tap-target` exactly one clickable `Button` "App information". For each control, from a fresh launch each: `ACTION_CLICK` (what TalkBack's double tap performs), a tap at its centre, and Tab then Enter set its own status. Bad: `bad-split-facts` exactly four `View`s, both labels first; `bad-merged-group` exactly one clickable `Button` "Kitchen light\nOn\nOff", no node "Off"; Tab until it has focus (On's focus) and once more (Off's), the node still focused, then Enter turns the light off, and then its click action turns it on. Run once at CI's 320 by 640 at 160 dpi as well |
| L3 iOS | `good-merged-facts` and `good-cupertino`: one element for each label and its value ("City\nBoston"), none for either alone, and no button but Back; `good-named-group`: one element "Kitchen light", the buttons "On" and "Off", the only buttons but Back, neither carrying the question; `good-tap-target`: one button "App information", the only button but Back, and no image. For each control a tap sets its own status; two Tabs then Enter, and then Space, reach the first control and three Tabs the second, each key sent once from a fresh launch (XCUITest cannot see Flutter's focus; the probe found the first Tab on Back). Bad: `bad-split-facts` one element for each of the four texts, none joined; `bad-merged-group` one button labelled "Kitchen light\nOn\nOff", the only button but Back, and no element "On" or "Off". XCUITest gives no hierarchy, so whether the buttons sit inside the group is not seen on iOS |
| L4 TalkBack | What is read with focus moved to each part of each example: each fact its label and value together and nothing of the other; the group's name alone, with no role; each button its name and "Button" and not the group's name, both when focus comes from the question and when it comes straight from the "Example" heading (FL-320, written to fail if the name starts to be heard); the tap target its name and "Button" and no "Image"; `bad-split-facts` each text alone; `bad-merged-group` "Kitchen light On Off" and "Button". The walk is judged whole (`walk_strictly`, S09 in `STRICT` of `tool/talkback.py`): a walk with any wrong reading fails for good, and only a walk shown to be incomplete is walked again, up to three walks, each in the transcript. No row claims silence |
| L4 VoiceOver iOS | Every utterance after the "Example" heading to the end of the screen, compared as a whole list (C03's walk, `C03Walk`), each one checked to be under the service's 64 characters before the walk: `good-merged-facts` and `good-cupertino` "City Boston", "Founded 1630"; `good-named-group` "Kitchen light", "On Button", "Off Button", "Light: not set"; `good-tap-target` "App information Button", "Opens: 0"; `bad-split-facts` "City", "Founded", "Boston", "1630"; `bad-merged-group` "Kitchen light On Off Button", "Light: not set" |
| L4 VoiceOver web | Every walk must read the whole screen, each stop in its place (`judgeExampleWalk` in `web_tests/vo/s09_vo_walks.js`, a copy of C04's by way of C18's): the screen's title and description, the "Example" heading, then exactly the expected list, to the end of the screen. A wrong stop, an empty one, a skipped one, or a walk that reached the end with any expected stop not read fails the test for good; only a walk cut short before the end with every stop right so far is walked again, up to three walks, each logged. No runner retries. In Chromium and WebKit. The expected phrases were written before any S09 recording, from how C18 and F07 were read: `good-named-group` "Kitchen light group", "On button", "Off button", "end of Kitchen light group", "Light: not set"; the facts "City Boston" and "Founded 1630"; `bad-merged-group` "Kitchen light On Off button" |

## 7. What the build found (Flutter 3.47.5)

The probe that came first is in
[evidence/probes/s09](../evidence/probes/s09/README.md): nineteen fixtures
on every platform, two more in widget tests only, with plain HTML for
comparison on the web.

- **A label and its value are one stop when merged**
  (`good-merged-facts`, probe s01). `MergeSemantics`, a
  `Semantics(container: true)` (s04), and a Material `ListTile` with no
  `onTap` (s05) each make one node of a label and its value, on every
  platform: one text element on the web, one `View` on Android that
  TalkBack read as "City Boston", and one static text on iOS that
  VoiceOver read as "City Boston". A value's own
  `semanticsLabel` is kept in the merge (s06). `MergeSemantics` is the one
  used: its documentation describes it as merging the semantics of a
  subtree into one node.
- **A `CupertinoListTile` does not merge its parts** (`good-cupertino`):
  its title and its subtitle, or its additional information, are two
  nodes (widget tests, s20 and s21, and the SDK-alone widget test), so each
  tile is put in `MergeSemantics`. A `CupertinoListTile` with no `onTap`
  is not a control, so the merge takes in no control.
- **A table of pairs that is not merged is read row by row**
  (`bad-split-facts`, probe s02 and s03): "City", "Population", "Boston",
  "675,647", in the semantics tree's order (widget tests, the Android
  tree, the web's element order) and as VoiceOver on iOS read it, whether
  the table is built by rows (s03) or by columns with nothing merged
  (s02). Flutter orders sibling nodes by their position
  ([FL-420](../flutter-limitations.md#fl-420), which also says that rows
  that touch can be read down by column instead, so an order that rests
  on position can change with the screen). `bad-split-facts` is the row
  build, with 4 pixels between its rows; its order is checked at every
  layer, and on Android at CI's size too. TalkBack's walk moves focus by
  action, so it shows what each text says, not the order.
- **A named group is a group on the web only**
  ([FL-320](../flutter-limitations.md#fl-320), new; `good-named-group`).
  On the web the labelled node is `role="group"` named by the question,
  holding the buttons, as a `fieldset` with a `legend` is in Chromium
  (s07, s08, s19, and the plain HTML lines). On Android it is a `View`
  named by the question, holding the buttons, with no container title and
  no pane title; TalkBack read the question as a stop of its own and each
  button without it, "On / Button / Double-tap to activate", also when
  focus went straight from the line before to "On" (`-direct-on`). On iOS an element of type other
  named by the question, then the two buttons; VoiceOver, moving forward,
  read "Kitchen light", "On Button", "Off Button", and with the cursor put
  straight on "On" by a tap, "On Button" (round 3, `ios-native.txt`). Plain text above the buttons (s10) is read the same as the
  group on Android and iOS, and is no group on the web.
- **Natively, both platforms name a group on the way in** (round 3 of the
  probe, `ios-native.txt`, `android-native-talkback.md`). On iOS a UIKit
  container with `accessibilityContainerType = .semanticGroup` and a
  label, and the iOS reference's SwiftUI `HStack` with
  `.accessibilityElement(children: .contain)` and a label, were read by
  VoiceOver as "Kitchen light On Button", moving forward into the group
  and with the cursor put straight on "On" by a tap; "Off Button" and the
  line after with nothing on the way out. Native buttons with plain text
  above them read "On Button", as Flutter's `good-named-group` did the
  same two ways. On Android (TalkBack 17.0) a container with
  `setContainerTitle` gave "On. Button. In Kitchen light" with focus
  moved onto "On", from the line before and straight from it, and "end.
  Out of Kitchen light" for the line after; a container named only by its
  `contentDescription`, which is what Flutter's labelled node gives, and
  no group, gave "On. Button". TalkBack's own navigation could not be
  driven: neither Alt and Right from `input keycombination` nor a swipe
  from `input swipe` moved its focus, so only focus moved by
  `ACTION_ACCESSIBILITY_FOCUS` was measured. No Compose fixture was
  built (it needs the Compose compiler's Gradle plugin and libraries).
  This is what makes R4 a requirement Flutter fails on both platforms,
  and not one that the platforms' own screen readers do not meet.
- **A label put round the buttons without a container** (s11, the iOS
  reference's warning) did not override the buttons' names in Flutter: it
  made a node of its own round them, so with the question also drawn the
  question was read twice (TalkBack: "Kitchen light", "Kitchen light").
  The same happens with the question left in the group (s14).
- **`MergeSemantics` round controls makes one control**
  ([FL-243](../flutter-limitations.md#fl-243), extended;
  `bad-merged-group`, s12): one button named by the question and both
  buttons, with one action, On's. On the web and Android the second
  button's focus node is still there: Tab stops on the merged node twice,
  and Enter on the second stop runs Off. A click on it from assistive
  technology (web) and its click action (Android) run On. On iOS one
  button with the whole label; a tap at its centre in the probe ran Off,
  as that is where Off is drawn and a tap goes through Flutter's own hit
  test. The same merge round an `IconButton` and a `TextButton` that do
  one thing (s18) is harmless, as both run one handler, but on the web
  and iOS its name holds the tooltip as well ("App information\nApp
  information", FL-251).
- **An icon and its text are one target with `TextButton.icon`**
  (`good-tap-target`, s15), and with `ListTile(leading:, title:, onTap:)`
  (s16): one button named by the text on every platform. Two targets for
  one action (s17) are two buttons with one name and two Tab stops, which
  no criterion fails; no bad example is built from it.
- **`CupertinoFormSection`'s header is not the name of its rows** (s13):
  it is text before them, as plain text is, and no group on the web.
- **The transcripts** ([TalkBack](../evidence/S09/talkback-android.md),
  [VoiceOver on iOS](../evidence/S09/voiceover-ios.md)) passed on their
  first walk, each reading as the probe measured it: TalkBack read "On /
  Button / Double-tap to activate" with no group name both after the
  question and with focus moved straight from the "Example" heading, and
  VoiceOver on iOS read "Kitchen light", "On Button", "Off Button". The
  web VoiceOver recording has not been made (the principal runs it); its
  expected lists are predictions from C18's and F07's recordings, and a
  reading that differs will be a measurement to record, not a defect to
  assume.
- **The Android suite passed at CI's size** (320 by 640 at 160 dpi)
  on the local emulator after the evidence run, eight tests with
  `talkBackWalk` skipped as it runs only with TalkBack on
  (`docs/evidence/probes/s09/android_320x640.txt`).

Skips and what they give up, in the tests:

- The widget tests run as Android (`kIsWeb` false), so the web engine's
  `group` role is seen only in the web tests.
- The example's nodes are compared only where they have a name or a tap
  action (widget tests, Android) or a role, a name, or text of their own
  (web): a node with none of these, such as an unlabelled container, is
  left out, so an extra unnamed wrapper would not be seen. The depth of
  each node is compared, so a named node's place inside another is.
- On the web the example's elements are read from the DOM, not from
  Chromium's ARIA snapshot, which runs neighbouring texts into one line;
  so what is compared is what Flutter writes, and Chromium's own names are
  checked separately for the group, the buttons, and the merged texts.
- On Android the screen is read from the top and then scrolled a step at
  a time until the status line is in the tree, keeping each node once: two
  nodes with the same name, class, and identifier would count as one; no
  example has two.
- The focus outlines are read from the buttons' style for the focused
  state, not from pixels, and their contrast is taken against the theme's
  surface colour.
- TalkBack's walk moves focus to each part by action and does not see a
  stop it was not told of; the Android tree test checks the parts and
  their order. The usage hint, "Double-tap to activate", is not required.
- The TalkBack judge counts only a capture shown to be short as
  incomplete; any other failed check is a wrong reading and fails the run
  for good (as for C18).
- The iOS tree tests cannot read traits or the hierarchy, and cannot see
  Flutter's focus, so the key tests rely on the probe's finding that the
  first Tab is on Back and each later one on the next control.
- The iOS VoiceOver walk is C03's (`C03Walk`): it ends where moving on
  gives the last utterance again, twice, and so gives up two neighbouring
  elements that VoiceOver reads alike; no example has two. Utterances are
  cut at 64 characters; the test refuses an expected one that long.

Handed on:

- To the owner, by the principal: whether F07 Checkbox's and F09 Switch's
  named groups, built as `good-named-group` is and recorded there as
  applying on Android and iOS, become limitations on those platforms for
  their groups ([FL-320](../flutter-limitations.md#fl-320)).
- To S11 Reading and traversal order: a table of unmerged pairs is read
  row by row on every platform here, by Flutter's ordering by position
  ([FL-420](../flutter-limitations.md#fl-420)).

**Not done yet.** The web VoiceOver recording (the principal runs it);
TalkBack's own navigation into a native or a Flutter group, which could
not be driven (focus was moved by action); VoiceOver's own activation on
iOS (C04 probe round 3); whether VoiceOver on the web says the group's
name when Tab, not its own navigation, moves into the group; a group of
text fields; dark mode on a device (widget tests only); text scaling on the
web; and right-to-left text.
