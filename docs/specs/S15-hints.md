# Spec: S15 Hints

Status: Draft 1 (2026-11-15), written with the build. Seventh technique of
batch 1 ([plan](../plan.md)). Flutter pin: 3.47.5.

A hint is a short sentence, apart from a control's name, that says what
using the control will do. This spec covers when to give one, how to word
it, and where Flutter puts it on each platform. A control's name is
[S01 Accessible names](S01-accessible-names.md). The label of a tap action
(`onTapHint`, "double-tap to add to favorites") is I06 Action labels.
Instructions for a form field, which are more than a hint, are F02 Input
instructions; one field appears here because the source has one. Tooltips
are C12.

## 1. Rule

A control whose name does not say what it does has a hint that does. The
hint describes the result, in a sentence, without naming a gesture or the
kind of control, and without repeating the name. Nothing a person needs is
in the hint alone.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies | Applies | Applies |

On Android a hint is not kept apart: it is the end of the control's
description, read with the name and before the role
([FL-039](../flutter-limitations.md#fl-039)). A text field's name and hint
are read by TalkBack only while the field is empty
([FL-015](../flutter-limitations.md#fl-015)), so on Android `good-field`
gives the rule on focus for an empty field only; after that the rule is
reached as the text under the field. The catalog carries a note on the
Android platform for both.

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [3.3.2 Labels or Instructions](https://www.w3.org/TR/WCAG22/#labels-or-instructions) | Labels or instructions are provided when content requires user input. A hint is one way to give an instruction to a screen reader user, and it cannot be the only way an instruction is given |

A badly worded hint does not fail a success criterion. `bad-gesture`,
`bad-repeats-label`, and `bad-control-type` break the source's wording
rules, not WCAG.

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | A hint is given only when the result of an action is not clear from the name | [iOS Accessibility Hint](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/AccessibilityHint.md) ("Only provide a hint when the result is not obvious from the element's label"), [Apple: accessibilityHint](https://developer.apple.com/documentation/uikit/uiaccessibilityelement/accessibilityhint) |
| R2 | The hint describes the result of the action, not how to perform it | iOS Accessibility Hint ("Describe the result of the action, not how to perform it") |
| R3 | It begins with a verb in the third person ("Adds", not "Add"), starts with a capital, and ends with a period | iOS Accessibility Hint, Apple: accessibilityHint |
| R4 | It does not name a gesture ("tap", "double tap", "swipe") | iOS Accessibility Hint |
| R5 | It does not repeat the name or say the control type ("button", "link") | iOS Accessibility Hint |
| R6 | Hints are optional: a user can turn them off, so nothing essential is in a hint alone. A field's format rule given in a hint is also visible on the screen | iOS Accessibility Hint ("Hints are optional — VoiceOver users can turn them off in Settings"; its input example conveys "the input requirements that are visible on screen"), [MDN: aria-description](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Reference/Attributes/aria-description) |

Flutter references for the mechanisms used:

- [`SemanticsProperties.hint`](https://api.flutter.dev/flutter/semantics/SemanticsProperties/hint.html)
- [`MergeSemantics`](https://api.flutter.dev/flutter/widgets/MergeSemantics-class.html)

The inventory row names no APG pattern and no HTML element. On the web the
hint is `aria-description`.

## 5. Examples

Every example ends with a count of changes, so a person or a test can tell
that a control worked. The examples follow the iOS document's: a button
whose hint gives the result, a list row whose name does not say what a tap
does, and a field whose rule is on the screen and in the hint. The song and
artist are made up.

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-result` | Material | A "Favorite" button with the hint "Adds this item to your favorites." | `MergeSemantics` around `Semantics(hint:)` around `FilledButton.icon` | R1, R2, R3, R4, R5 |
| `good-row` | Material | A row named by a song and an artist, with the hint "Plays the song." | `Semantics(hint:)` around `ListTile(onTap:)` | R1, R2, R3 |
| `good-cupertino` | Cupertino | A "Share" button with the hint "Shares the current page." | `Semantics(hint:)` around `CupertinoButton.filled` | R1, R2, R3 |
| `good-custom` | Widgets | A button drawn by hand, with the hint "Moves this message out of the inbox." | `Semantics(button:, label:, hint:, onTap:)`; Enter and Space through `FocusableActionDetector` | R1, R2, R3 |
| `good-field` | Material | A username field whose rule is text under the field and also the field's hint | `Semantics(hint:)` around `TextField`, and a `Text` | R6 |

### Bad

| Slug | Defect | Violates | Fails |
| --- | --- | --- | --- |
| `bad-gesture` | The hint is "Double tap to add this item to your favorites." | R2, R4 | — |
| `bad-repeats-label` | The hint is "Delete" on a button named "Delete" | R5 | — |
| `bad-control-type` | The hint is "This button shares the current page." | R5 | — |
| `bad-no-hint` | The song row with no hint: nothing says a tap plays it | R1 | — (the source requires the hint; WCAG does not) |
| `bad-hint-detached` | `Semantics(hint:)` around a `FilledButton` with no `MergeSemantics`. The hint is an element of its own on Android and iOS and is not in the page on the web ([FL-040](../flutter-limitations.md#fl-040)) | R1 (the button has no hint) | — |
| `bad-hint-only` | The username rule is in the field's hint and not on the screen | R6 | 3.3.2 |

`bad-control-type` differs from the source's example, "Tap this button to
share the current page.", which has two defects, a gesture and a control
type. Here each has its own example.

`bad-hint-detached` has no `TestId`: its `MergeSemantics` would put the
hint back on the button. The tests find the button by its name and the
stray node by its hint.

## 6. Assertions by layer

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Every button: its label, its hint, the button flag and tap action, that no other node has a hint, and that tap, the semantics action, Enter, and Space all work and leave label and hint unchanged. Good hints: the wording rules R3 to R5. Good field: label, hint, a text field, and the rule as one separate node. Bad: the gesture, the repeated name, and the control type in the hint; the detached hint on a node with no label and no action, and none on the button; the rule in the hint and no text on the screen. Guidelines in light and dark and 200% text for good examples |
| L3 web | Every button: role, accessible name, accessible description, `aria-description`, that nothing else is described, and click, Enter, and Space. Fields: name, description, and the rule as text or not. `bad-hint-detached`: no description on the button and the hint nowhere in the page |
| L3 Android | Every button: the `Button` class and the description "name, hint"; empty hint text, tooltip, and state description; the click action. Fields: `EditText` with the hint text "Username, rule", before and after text is typed, and the rule as a separate node or not. `bad-hint-detached`: a `View` with the hint and no click action, and a button without it |
| L3 iOS | Every button: type, and a label without the hint. XCUITest cannot read a hint. Fields: label, and the rule as static text or not. `bad-hint-detached`: the hint is in no label |
| L4 TalkBack | What is read with focus on each control, and for the two fields again with text in them |
| L4 VoiceOver iOS | Every utterance between the "Example" heading and the change count, compared as a whole list. This is the only iOS layer that sees a hint |
| L4 VoiceOver web | Every stop between the "Example" heading and the change count, in Chromium and WebKit. At a text field the phrase is taken from Guidepup's log (section 7) |

## 7. What the build found (Flutter 3.47.5)

The probe that came first is in [evidence/probes/s15](../evidence/probes/s15/).

- **`Semantics(hint:)` reaches all three platforms, in three shapes.** iOS
  has a hint of its own, read after the name and role: "Favorite, Button,
  Adds this item to your favorites." Android has none: the engine writes
  "Favorite, Adds this item to your favorites." into the content
  description, and TalkBack reads the hint before "Button"
  ([FL-039](../flutter-limitations.md#fl-039)). The web sets
  `aria-description`, which VoiceOver on macOS reads between the name and
  the role in Chromium and WebKit: "Favorite Adds this item to your
  favorites. button".
- **A hint around a Material button does not reach it**
  ([FL-040](../flutter-limitations.md#fl-040)). The button is a semantics
  container, so the hint stays on a node of its own. `MergeSemantics` joins
  them, and `good-result` uses it. `CupertinoButton` and `ListTile` are not
  containers and take the hint directly.
- **On the web a node with a hint and no name gets nothing, unless it is
  a text field** ([FL-041](../flutter-limitations.md#fl-041)), which is why
  the detached hint disappears there.
- **VoiceOver on iOS does not read a hint that is the same as the label.**
  `bad-repeats-label` is "Delete, Button" there. TalkBack reads "Delete,
  Delete, Button", and VoiceOver on the web "Delete Delete button".
- **A text field's hint is hint text on Android**: "Username, 3 to 12
  letters or numbers." TalkBack reads it with the field while the field is
  empty. With "abc" typed it reads "Editing, abc, Edit box" and neither the name nor
  the rule ([FL-015](../flutter-limitations.md#fl-015)); the walk reads both
  fields a second time, filled, to record that.
- **On the web VoiceOver follows a described text field with its help
  message** ("You are currently on a text field, inside of web content…")
  straight away, so that message, not the field, is VoiceOver's last
  phrase. The S15 walk takes the phrase Guidepup logged for the move at
  such a stop, after checking that the log agrees with the walk at every
  other stop. The field is read "Username 3 to 12 letters or numbers. edit
  text".
- **The field examples were password fields at first, and were changed**
  to keep this technique to hints. In that build VoiceOver on iOS read the
  obscured field, not being edited, as a plain text field
  ([FL-042](../flutter-limitations.md#fl-042)); that was seen once and not
  explored.
- **`helperText` and `hintText` on `InputDecoration` are not semantic
  hints** (probe, fixtures 06 and 07). Helper text is a separate element;
  hint text was not exposed for an empty, unfocused field with a label.
- **`XCUIVoiceOverService` returns the first 64 characters of an
  utterance.** The field's line ends "Double tap to ed".
- TalkBack's own "Double-tap to activate" comes after a pause and was heard
  for some buttons and not others within the listening window. It is not
  required by the transcript check.
- `bad-hint-only` sounds the same as `good-field` to a screen reader. Its
  defect is what is missing from the screen, which the tree tests assert.

**Not done yet.** Turning hints off (VoiceOver's setting on iOS, and
verbosity settings elsewhere) was not tested on any platform. Which
elements a TalkBack swipe stops on is not tested. `onTapHint` is left to
I06, `helperText` and field instructions to F02, tooltips to C12, and the
secure-field role on iOS to F01's follow-up.
