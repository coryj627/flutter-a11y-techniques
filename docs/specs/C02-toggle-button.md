# Spec: C02 Toggle button

Status: Draft 1 (2026-11-20), written with the build. Built in wave 2.
Flutter pin: 3.47.5.

A toggle button is a button that stays pressed or not pressed: Bold in a
text editor, Mute in a call. This spec covers its name, its role, its
state in both states, a name that does not change with the state, and
what each screen reader says before and after a change. Where the line is
with the entries beside it:

- A plain button, whose press does something and leaves nothing on or
  off, is [C01 Button](C01-button.md). So is a button whose name says what
  the next press does ("Play", then "Pause") and that has no state: APG
  allows that design in place of a toggle button, and it is a plain
  button.
- A control drawn as a switch, with a track and a thumb, is
  [F09 Switch](F09-switch.md); a tick box is [F07 Checkbox](F07-checkbox.md).
  Flutter gives a toggle button the switch or the checkbox role (section
  7), so the platforms' roles overlap; what decides the entry is what the
  control is drawn and used as.
- A set of buttons of which exactly one is chosen (a `SegmentedButton`
  with one choice at a time, a `CupertinoSlidingSegmentedControl`) is a
  radio group: [F08 Radio group](F08-radio-group.md) and F17 Segmented
  control. A multi-select `SegmentedButton` is a row of toggle buttons; it
  exposes the same `selected` state as `IconButton(isSelected:)` (probe,
  fixture t06) and is not repeated as an example here. F17 has it.
- A row of toggle buttons as one keyboard stop with arrow keys between
  them is C16 Toolbar. Here each toggle button is a Tab stop of its own.
- Chips (`FilterChip`) were looked at in the probe (fixture t15) and are
  not covered.
- Rewording "on" and "off" is S14 ([FL-036](../flutter-limitations.md#fl-036)).

## 1. Rule

A toggle button exposes its name, a role, and whether it is pressed, in
both states, and keeps the state true as it changes. Its name does not
change when its state does.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies, with [FL-200](../flutter-limitations.md#fl-200): a switch, not a toggle button | Applies, with [FL-200](../flutter-limitations.md#fl-200): a switch, not a toggle button | Applies, with [FL-200](../flutter-limitations.md#fl-200): a switch, not a toggle button (no `aria-pressed`) |

Flutter has no pressed state ([FL-200](../flutter-limitations.md#fl-200)):
no `aria-pressed` on the web, no toggle button class on Android, no toggle
button trait on iOS. The good examples use the nearest states instead:
`toggled` (the switch role, with the state said on and off on every
platform) or, in `ToggleButtons`, `checked` (the checkbox role, a switch
on iOS; TalkBack says no state while it is off,
[FL-045](../flutter-limitations.md#fl-045)).

On the web a Flutter toggle button cannot be read as a toggle button.
HTML has one, a `button` with `aria-pressed`, which VoiceOver reads
"Bold toggle button" when it is not pressed and "Italic selected toggle
button" when it is (`control-html` in the transcript); Flutter writes no
`aria-pressed`, so its toggle button is a switch ("Bold off switch",
"Bold on switch") or a checkbox. This was accepted, and the web recorded
as applying, because the role and the state can both be programmatically
determined, which is what 4.1.2 asks for (section 3). On Android and iOS
the native toggle buttons nearest to it are read as switches too, by
TalkBack and by VoiceOver (section 7), so there the role heard is the
platform's own.

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [4.1.2 Name, Role, Value](https://www.w3.org/TR/WCAG22/#name-role-value) | A toggle button is a user interface component: its name and role can be programmatically determined, and its state, which the user sets, can be programmatically set and determined, with changes notified to assistive technology |

How the verdicts are reached: 4.1.2 asks for a role that can be
programmatically determined and for the state the user sets to be
exposed. It does not name the toggle button role. A switch or a checkbox
with an on or off state exposes a role and the pressed state, in both
states, so it meets the criterion. A button that exposes no state at all
does not. `selected` alone (`bad-selected-only`) is judged in section 5.

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | A toggle button tells assistive technology that it is a toggle and whether it is on or off, in both states | [APG Button](https://www.w3.org/WAI/ARIA/apg/patterns/button/) ("To tell assistive technologies that a button is a toggle button, specify a value for the attribute aria-pressed"; `true` when on, `false` when off), [MDN `aria-pressed`](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Reference/Attributes/aria-pressed) |
| R2 | The role is button | APG Button ("The button has role of button") |
| R3 | The name does not change when the state changes | APG Button ("it is critical the label on a toggle does not change when its state changes") |
| R4 | Space and Enter both change it | APG Button, keyboard interaction |
| R5 | Its state is conveyed to VoiceOver, and its name is unique and specific | [iOS Buttons](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/Buttons.md) ("Button states must be conveyed to VoiceOver users"; the document names the disabled state and says nothing about toggle buttons) |

The inventory names no Android reference for this entry, and the iOS
reference's Buttons document has no toggle button. Its traits sample
(`AccessibilityTraitsView.swift` in the reference repository) lists the
selected trait and, from iOS 17, the toggle trait, without saying when to
use either.

R2 cannot be met together with R1 in Flutter: a node with a toggled or
checked state is exposed with that role, not as a button (FL-200). The
good examples meet R1, R3, R4, and R5, with the switch or checkbox role.

Flutter references for the mechanisms used:

- [`IconButton.isSelected`](https://api.flutter.dev/flutter/material/IconButton/isSelected.html)
- [`ToggleButtons`](https://api.flutter.dev/flutter/material/ToggleButtons-class.html)
- [`SemanticsProperties.toggled`](https://api.flutter.dev/flutter/semantics/SemanticsProperties/toggled.html)
- [`MergeSemantics`](https://api.flutter.dev/flutter/widgets/MergeSemantics-class.html)

Comparison bar: the HTML `<button aria-pressed="false">`, as APG
describes it.

## 5. Examples

Every example ends with a count of changes, so a person or a test can tell
that a control worked. Every toggle button starts off.

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-icon-button` | Material | A "Bold" icon button that stays pressed | `Semantics(toggled:)` around an `IconButton(tooltip: 'Bold')`, inside `MergeSemantics`, which puts it on the button's node; the pressed look (the filled icon on the primary colour) drawn with `style`, and `isSelected` left out | R1, R3, R4, R5 |
| `good-toggle-buttons` | Material | Bold, Italic, and Underline, each on or off | `ToggleButtons(isSelected:)`, each icon with a `semanticLabel` | R1, R3, R4, R5 |
| `good-cupertino` | Cupertino | A "Mute" button that stays pressed | `Semantics(toggled:, enabled: true)` around a `CupertinoButton`, with an action for `ButtonActivateIntent` ([FL-002](../flutter-limitations.md#fl-002)); when on, filled with `CupertinoColors.label` and its text and icon in `CupertinoColors.systemBackground`, both resolved for the context | R1, R3, R4, R5 |
| `good-custom` | Widgets | The same drawn by hand | `Semantics(button: true, toggled:, enabled: true, label:, onTap:)`; Space and Enter through `FocusableActionDetector` | R1, R3, R4, R5 |

Cupertino has no toggle button, so `good-cupertino` is a `CupertinoButton`
given a state. `good-toggle-buttons` keeps the framework's own `checked`
state; it is the only good example whose role is the checkbox (a switch on
iOS), and TalkBack says nothing for one that is off
([FL-045](../flutter-limitations.md#fl-045)). That is the same reading as
F07's checkboxes, which were judged not to fail 4.1.2: the role says the
control has an on and an off state, and only "not checked" is not said.

### Custom solutions

**Custom solution: not vetted by a real-world example.** `good-icon-button`,
`good-cupertino` and `good-custom` are custom solutions. Each is tested here
in isolation, with screen-reader transcripts, but has not been built into a
real app and tested in a user journey. Do not treat them as vetted
techniques.

The table is this technique's part of the register of custom solutions,
[custom-solutions.md](../custom-solutions.md).

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-icon-button` | The pressed state: `Semantics(toggled:)` round an `IconButton`, merged onto its node with `MergeSemantics`, in place of `isSelected`; the pressed look drawn with `style` | `IconButton(isSelected:)` | No pressed state ([FL-200](../flutter-limitations.md#fl-200)); `isSelected` says nothing while off ([FL-201](../flutter-limitations.md#fl-201)); the state stays off the button's node ([FL-040](../flutter-limitations.md#fl-040)) | R1, R3, R4, R5: APG Button, MDN aria-pressed, iOS Buttons | custom |
| `good-toggle-buttons` | Nothing: `ToggleButtons(isSelected:)`, each icon with a `semanticLabel` | `ToggleButtons` | None filled (TalkBack says no state while off, [FL-045](../flutter-limitations.md#fl-045), is left as it is) | R1, R3, R4, R5: APG Button, MDN aria-pressed, iOS Buttons | not custom |
| `good-cupertino` | `Semantics(toggled:, enabled: true)` round a `CupertinoButton`, an `Actions` for Enter on the web, and the colours of the on state | None: Cupertino has no toggle button; `CupertinoButton` is the closest | No pressed state ([FL-200](../flutter-limitations.md#fl-200)); no enabled state ([FL-001](../flutter-limitations.md#fl-001), [FL-033](../flutter-limitations.md#fl-033)); Enter on the web ([FL-002](../flutter-limitations.md#fl-002)); text colour in dark mode ([FL-202](../flutter-limitations.md#fl-202)) | R1, R3, R4, R5: APG Button, MDN aria-pressed, iOS Buttons | custom |
| `good-custom` | A toggle button drawn by hand: `Semantics(button: true, toggled:, enabled: true, label:, onTap:)`; Space and Enter from `FocusableActionDetector`; a focus ring of its own | None for a drawn control | No pressed state ([FL-200](../flutter-limitations.md#fl-200)); dimmed without `enabled` ([FL-033](../flutter-limitations.md#fl-033)) | R1, R3, R4, R5: APG Button, MDN aria-pressed, iOS Buttons | custom |

### Bad

| Slug | Defect | Violates | Fails |
| --- | --- | --- | --- |
| `bad-selected-only` | `IconButton(isSelected:)` as it comes. While off it is read "Bold, button", as a button with no state is; while on, "selected" (on the web, "current item") | R1 | 4.1.2 on the web; none as written on Android and iOS ([FL-201](../flutter-limitations.md#fl-201)) |
| `bad-no-state` | A hand-drawn toggle button exposed as a plain button: "Mute, button" whether on or off | R1 | 4.1.2 |
| `bad-label-changes` | `good-icon-button`'s mechanism with the name "Mute", then "Unmute": the name changes with the state, and "Unmute" with "on" can be taken either way | R3 | none |

Verdicts:

- `bad-no-state` fails 4.1.2 on every platform: the state the user sets is
  not exposed at all.
- `bad-selected-only`, by platform:
  - Web: fails 4.1.2. The state is written as `aria-current`, which
    VoiceOver reads "current item": a different state from pressed (and
    from selected), the one that marks the current item of a set. The
    state the user sets is not exposed as itself.
  - Android: none as written. The selected state can be programmatically
    determined in both states: the node is a `Button` with
    `selected="false"` while off and `selected="true"` while on
    (`docs/evidence/probes/c02/android_before.xml` and
    `android_after.xml`, fixtures t01 and t02; the C02 Android test), the
    same as a native `Button` that is selected or not (n03 and n04 in
    `android_native2_nodes.txt`, read "selected. n03 Bold. Button" and
    "n04 Bold. Button" in `talkback-native2.md.txt`).
  - iOS: none as written. XCUITest reports `isSelected` false while off
    and true while on (`ios.txt`, t01 and t02; the C02 iOS test). The
    engine sets the selected trait only while it is true and leaves it
    off otherwise (source read, `SemanticsObject.mm`), which is how UIKit
    represents a button that is not selected: a native button reads the
    same, "n03 Bold Button" not selected and "selected n04 Bold Button"
    selected (`ios_native2.txt`).
  - The weakness on all three, stated plainly: while the button is off,
    nothing says that it is a toggle. It is read "Bold, button", the same
    as a button that does nothing more than act, so a user cannot tell
    that it stays pressed or that it is out without pressing it. The
    nearest native toggle buttons do say it, by their role: TalkBack
    reads an `android.widget.ToggleButton` "OFF. n01 Bold. Switch", and
    VoiceOver a UIKit button with the toggle button trait "n01 Bold
    Switch button" (section 7).
- `bad-label-changes`: no criterion fails as written. The name can be
  programmatically determined at every moment and the state is exposed,
  so 4.1.2 is met; the defect is APG's rule that a toggle button's label
  does not change. It is kept as a bad example because what the user
  hears is ambiguous ("Unmute, on"). F09's `bad-label-changes`, marked
  4.1.2 there, differs in what the name says: there it is the state
  itself ("Bluetooth off", then "Bluetooth on"), so the state is heard
  twice; here it is the action ("Mute", then "Unmute"), and the state is
  heard once.

A multi-select `SegmentedButton` has the same defect as
`bad-selected-only` (probe, fixture t06) and is left to F17.

## 6. Assertions by layer

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Every good toggle: its name on one node, a button with a `toggled` (for `ToggleButtons`, `checked`) state that is off, no state of the other kind, not in an exclusive group, enabled, with a tap action; a tap, the semantics tap action, Space, and Enter each change it, and the name stays. `good-icon-button` and `bad-label-changes` have no selected state, on or off, and draw the pressed look. Each `ToggleButtons` button changes only itself. Bad: a button whose only state is `selected`, false, then true, then false, with no toggled or checked state; a button with no state before and after use; a name that changes with the state. Guidelines in light and dark and 200% text for the good examples; and text contrast and the tap target guidelines again once each good example's first control is on, in light and dark |
| L3 web | Every good toggle: role `switch` (`checkbox` for `ToggleButtons`), name, `aria-checked` false then true, no `aria-pressed`, `aria-current`, or `aria-selected` (written to fail when Flutter writes `aria-pressed`, FL-200); a click, Space, and Enter each change it, and the name stays. Bad: a `button` with `aria-current` false, true after a click, false after Space, and no `aria-pressed` or `aria-checked`; a `button` with no state attribute before and after use; a switch whose name changes |
| L3 Android | Every good toggle: the `Switch` class (`CheckBox` for `ToggleButtons`), the name, checkable, not checked, checked after a click and not after a second, the name and class kept, enabled, clickable. `good-icon-button` is not selected, on or off. Bad: a `Button` that is not checkable and is selected after one click and not after two; a `Button` with no state before and after use; a `Switch` whose name changes |
| L3 iOS | Every good toggle: type `.switch`, label, enabled, value "0", "1" after a tap, "0" after a second. Bad: a `.button` with no value, `isSelected` after one tap and not after two; a button with no value and not selected before and after use; a switch whose label changes |
| L4 TalkBack | Each control on arriving, and again after it has been changed once, with focus away and back: the state words, the name, and the role, and the words that must not be there |
| L4 VoiceOver iOS | Every utterance between the "Example" heading and the change count, as each example opens and again after its first control was tapped once, compared as a whole list; the second walk must end at "Changes: 1" |
| L4 VoiceOver web | In Chromium and WebKit. No test in the spec is retried by the runner (`test.describe.configure({ retries: 0 })` at the top of the file): the shared config retries a failed test twice, and `tool/voiceover_web.py` reports a run whose retry passed as PASS and keeps only the last attempt's rows, so a runner retry could hide a wrong reading. Each walk is instead repeated by the test itself (`runWalks` in `web_tests/vo/c02_vo_walks.js`), up to three times, only while it falls short, and every try is logged as its own transcript row (`<slug>-walk-<n>`) with its verdict. Each example is walked as it opens and again after its first control was clicked once, and each walk is judged by `judgeExampleWalk`: before the "Example" heading only the screen's own stops (`EXAMPLE_SCREENS`), in order, the first of them, the level 1 heading, allowed to be read as an empty phrase, as WebKit did (round 4); after it the whole expected list, ending with the change count; in a walk that did not read the heading, every stop after the screen's own is judged against the list. A stop not in the list (an empty one, or "Changes: 0" in the second walk, included) or the list's stops out of order or read twice fails the test at once, with no further walk; exactly the list after the heading, with the end reached, passes; an empty walk, one of the screen's own stops only, or one that read only some of the list in order, without the heading or without reaching the end, is a failed try. For comparison, a plain HTML page (`control-html`) with a `button` with `aria-pressed="false"`, one with `aria-pressed="true"`, and one with `aria-current="true"`, judged by `judgeControlWalk`: a stop is a button's when it names the button, however it is worded, or when it comes after "Text styles", the page's stop before the buttons, and before "Changes: 0", the stop after them; in a walk cut off before "Changes: 0", every stop after "Text styles" but a last "end of main"; in a walk that did not read "Text styles", from the first stop, or after the heading if the walk began with it. Before "Text styles" only the heading may stand (or WebKit's empty reading of it), and after "Changes: 0" only "end of main". Any such stop that is not that button's expected reading ("Bold toggle button", "Italic selected toggle button", "Underline current item button") fails the test at once; exactly the three readings, in order, between the two neighbours, with the end reached, passes; anything else is a failed try. Both judges and the tries are tested on made-up walks, with no VoiceOver, in `web_tests/c02_toggle_button.spec.js`, which CI runs. For the examples: headingless walks with a wrong state, a nameless, an empty, or an unknown reading, a screen stop out of its place, and a stale count (all fail), headingless walks of the screen's own stops or of right readings (incomplete), a wrong reading before the heading, the screen's stops out of order, a stop after the count, an empty first stop for the title before the heading (passes), and an empty first stop without the heading, alone, after the title, just before the heading, twice, beside the title, or after the heading (all fail), a wrong headingless walk followed by a right one (fails, with no second walk), an empty walk followed by a right one (passes); and a correct walk before and after the change, a wrong state, a wrong role, an empty reading, a stale count, stops out of order, a stop read twice, a wrong reading in a truncated walk, an empty walk, a walk that never reached the heading, a truncated walk, and a walk that missed a stop; a wrong walk followed by a right one (fails, with no second walk), an incomplete one followed by a right one (passes), and every try logged. For the comparison page: walks without "Text styles" with a nameless, an empty, or an unknown reading, or readings out of order (all fail), the heading alone (incomplete), an empty first stop without "Text styles" (fails), a stop before "Text styles" other than the heading, a reading after the count, readings out of order or twice with "Text styles" read (all fail), WebKit's empty heading (passes), a wrong walk without "Text styles" followed by a correct one (fails, with no second walk), an empty walk followed by a correct one (passes); and a correct walk, a bare name, a state word before the name, a button read as another, a reading with no name or an empty one between the neighbours, a wrong reading before the page, an empty walk, partial walks, truncated walks with a nameless, an empty, or a bare-name reading, and the same three about tries. A tree test checks that each example screen shows the texts in `EXAMPLE_SCREENS`. And a check of the VoiceOver spec's source, which its guard keeps from loading here: one top-level `retries: 0` before every test, and no other retries setting |

What the tests leave out, and what that gives up:

- The screen reader walks read each control in its new state as the
  reader arrives on it, not what is said at the moment of the change.
  Whether the change itself is announced is not checked.
- Only the first `ToggleButtons` button is changed in the walks; Italic
  and Underline are read off only.
- TalkBack's walk logs what is said while a control is being changed
  under the stop before it, so the phrases that a first stop must not
  have leave out what the change announces
  (`tool/techniques/c02_toggle_button.py`). That the change happened is
  checked by the count reading 1 before the second reading.
- The web VoiceOver spec's comparison page (`control-html`, plain HTML,
  no Flutter) is walked up to three times, because on that page the walk
  was not steady: in the third run of the examples it never reached the
  heading in some tries and went past the Bold button without reading it
  in others, in both browsers
  ([transcript](../evidence/probes/c02/voiceover-web-third-run.md.txt),
  [failures](../evidence/probes/c02/voiceover-web-third-run-control-errors.txt)).
  The second run's check failed for another reason, written before the
  reading was known
  ([transcript](../evidence/probes/c02/voiceover-web-second-run.md.txt)).
  A try counts only if it is complete (the three buttons in order between
  "Text styles" and "Changes: 0", and the end reached), and a wrong
  reading in any try fails the test. Every stop of a walk is judged: only
  the heading (or the empty phrase WebKit reads for it) may stand before
  "Text styles", only "end of main" after "Changes: 0", and only the
  expected readings, in order, between them; a walk that never read
  "Text styles" is judged from its first stop (after the heading, if it
  began with it), so an empty first stop there is taken as a button read
  as nothing and fails the run, even if it was WebKit's reading of the
  heading.
- The example walks are judged the same way: before the "Example"
  heading only the screen's own stops may stand (its title, the line
  that says good or bad, and a bad example's defect, listed in
  `EXAMPLE_SCREENS` and checked against each screen by the tree spec),
  each at most once and in order; after it only the expected readings,
  in order. A walk that never read the heading is judged from the first
  stop that is not one of the screen's own, and any such stop must be an
  expected reading, in order, or the test fails; such a walk is at best
  incomplete. What this gives up: a walk is judged by its text alone, so
  if VoiceOver reads one of the screen's own texts in other words than
  the screen shows (the defects have quotation marks), a walk with it
  fails the test rather than being taken as the screen's. One exception
  is allowed: an empty phrase as the first stop, in the place of the
  screen's level 1 heading, in a walk that went on to read the "Example"
  heading. WebKit read that heading so on three screens
  (`good-toggle-buttons`, `good-cupertino`, `good-custom`) in one run
  ([round 4 transcript](../evidence/probes/c02/voiceover-web-round4-fail.md.txt)),
  where the judge then refused it; why WebKit reads it empty is not
  known. An empty stop anywhere else, a second one, or an empty first
  stop in a walk that did not read the "Example" heading is still
  "wrong". It gives up this much: a walk whose first stop was empty for
  some other reason is taken as having read the title.
- The web VoiceOver walks repeat only a walk that fell short; what an
  incomplete try read is in the transcript, but the test does not judge
  it beyond "nothing wrong in it". A wrong reading is never retried.
  Other techniques' VoiceOver specs still take the shared config's runner
  retries; that is outside C02.

## 7. What the build found (Flutter 3.47.5)

The probe that came first is in [evidence/probes/c02](../evidence/probes/c02/).

- **Flutter has no pressed state**
  ([FL-200](../flutter-limitations.md#fl-200)). No `aria-pressed` on the
  web, no `android.widget.ToggleButton`, no toggle button trait on iOS,
  in the engine source or in any of the 21 probe fixtures. What a toggle
  button can have is `selected`, `checked`, or `toggled`.
- **`toggled` is said in both states on every platform**, as a switch:
  "Bold off switch" and "Bold on switch" on the web, "Bold Switch button
  off" and "… on" on iOS, "off. Bold. Switch" and "checked. on. Bold.
  Switch" on Android ([FL-100](../flutter-limitations.md#fl-100) for the
  extra "checked"). The native toggle buttons nearest to it are read as
  switches too (the second native probe; probe README, "Native
  controls"). On Android the role and the state words match: TalkBack
  reads an `android.widget.ToggleButton` "OFF. n01 Bold. Switch" and,
  after a click, "ON. n01 Bold. Switch". On iOS the role matches and the
  state words do not: VoiceOver reads a UIKit button with the toggle
  button trait "n01 Bold Switch button" while it is not selected and
  "selected n01 Bold Switch button" once it is, where Flutter's
  `toggled` says "off" and "on". Only the web
  has a toggle button role of its own: VoiceOver reads a plain HTML
  button with `aria-pressed` "Bold toggle button", and "Italic selected
  toggle button" when it is pressed (`control-html` in the transcript),
  which no Flutter node can give.
- **The Material toggles use `selected` and `checked`.**
  `IconButton(isSelected:)` and a multi-select `SegmentedButton` are a
  button that is selected or not, which is silent while off
  ([FL-201](../flutter-limitations.md#fl-201)); on the web it is
  `aria-current`. `ToggleButtons` is a checkbox on Android and the web
  and a switch on iOS ([FL-035](../flutter-limitations.md#fl-035)).
- **`isSelected` beside `toggled` says the state three ways on Android**:
  the first build of `good-icon-button` kept `isSelected` for its look,
  and TalkBack read "selected. checked. on. Bold. Switch"
  ([first-run transcript](../evidence/probes/c02/talkback-first-run.md.txt)).
  VoiceOver on iOS did not say "selected" there
  ([first run](../evidence/probes/c02/voiceover-ios-first-run.md.txt)),
  and the web writes no `aria-current` beside `aria-checked` (probe,
  fixture t20). The example now draws its pressed look and leaves
  `isSelected` out.
- **`toggled` around a Material button needs `MergeSemantics`**: alone it
  makes a second node with no name (probe, fixtures t04 and t18; the same
  mechanism as [FL-040](../flutter-limitations.md#fl-040)); the examples
  put `MergeSemantics` round it. Around a `CupertinoButton` it joins
  without help, and needs `enabled: true`
  ([FL-033](../flutter-limitations.md#fl-033),
  [FL-001](../flutter-limitations.md#fl-001)).
- **Enter does not change a `CupertinoButton` on the web**
  ([FL-002](../flutter-limitations.md#fl-002)); APG requires it for a
  toggle button, so `good-cupertino` adds the action, and Space and Enter
  both work on every example.
- **A name that changes with the state** changes on every platform and is
  heard with the new state: "Unmute on switch" on the web, "Unmute Switch
  button on" on iOS, "checked. on. Unmute. Switch" on Android.
- **A pressed look can lose its contrast.** The first `good-cupertino`
  filled the button with `CupertinoColors.label` when on and left its
  text and icon in the theme's primary colour: "Mute" was 3.26:1 on black
  in light mode and 1.70:1 on white in dark mode, and the text contrast
  guideline failed in both, where the L1 tests had checked only the off
  state ([measurements](../evidence/probes/c02/contrast_on.txt), from
  `contrast_on_test.dart.txt`). It now sets `foregroundColor` to
  `CupertinoColors.systemBackground` as well, text and icon 21:1 in both
  ([measured](../evidence/probes/c02/icon_foreground.txt)). A
  `CupertinoButton` resolves its `color` for the context and not its
  `foregroundColor` ([FL-202](../flutter-limitations.md#fl-202)). Measured
  in widget tests: with `foregroundColor` unresolved the text stayed white
  on white in dark mode, 1.00:1, under a `MaterialApp` and under a
  `CupertinoApp`; the icon did too under a `MaterialApp`, and was resolved
  under a `CupertinoApp`, whose Cupertino icon theme resolves it (read in
  the source). So the example resolves both itself. The other good
  examples passed text contrast once on, before and after the change.
  The L1 tests now check text contrast with each good example's first
  control on. Icon contrast (1.4.11) is measured above for
  `good-cupertino` only and not judged against the criterion; it is not
  checked by a test.

**What the native fixtures set** (second version, the one the readings
above come from; `ProbeNativeActivity2.kt.txt` and
`SceneDelegate2.swift.txt` in the probe folder):

- Android: every `ToggleButton` keeps Android's own `textOn` and `textOff`
  ("ON" and "OFF", which are also its text and its state description).
  The fixture sets `contentDescription` (the name, "n01 Bold"), which
  replaces the text "ON" or "OFF" as what TalkBack reads for the name, and
  `isChecked`. The plain `Button`s set `text` and `isSelected`. A plain
  `Button`, n00, comes first and takes focus before each reading.
- iOS: the toggle buttons are a `UIButton` subclass whose
  `accessibilityTraits` adds the toggle button trait to UIKit's own and
  changes nothing else; each sets a title and `isSelected`, and a tap
  toggles `isSelected`. The `changesSelectionAsPrimaryAction` button sets
  only that and a title. A plain button, n00, comes first. Adding the
  toggle button trait is itself a choice: UIKit gives it to no `UIButton`
  by itself (the `changesSelectionAsPrimaryAction` button has none).
- Both keep, for comparison, one control made as in the first version
  (n05): on Android `textOn` and `textOff` both set to the name, read
  "n05 Bold. Switch" with no state; on iOS the toggle button trait set by
  assigning `accessibilityTraits`, which replaces the selected trait UIKit
  derives, read "n05 Bold Switch button" while selected. The first
  version's readings are not used.

**Not verified.**

- What any screen reader says at the moment a toggle changes. The walks
  read each control again after the change, as the reader arrives on it.
- On Android, a native toggle button that is on when the screen opens
  (n02) was read "ON. n02 Bold. Switch" with the hint "Double-tap to
  activate", where n01 after a click had "Double-tap to toggle"; why the
  hint differs was not looked into.

**Not done yet.** A disabled toggle button is in the probe (fixture t16:
marked disabled on all three, the state kept; VoiceOver on iOS did not
stop on it) and not in an example.
