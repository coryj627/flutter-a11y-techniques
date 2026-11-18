# Spec: F02 Input instructions

Status: Draft 1 (2026-11-18), written with the build. Fifth technique of
batch 2 ([plan](../plan.md)), built in wave 1. Flutter pin: 3.47.5.

An instruction is text that says what a field needs: a format, a length,
which characters are allowed. This spec covers showing it, tying it to the
field so that a screen reader reads it there, and keeping it readable. A
field's label is [F01 Text fields and labels](F01-text-fields.md); a hint
in general, on any control, is [S15 Hints](S15-hints.md), whose
`bad-hint-only` already shows an instruction that is in the hint and not on
the screen. Keyboard types are F03, error messages F04, required fields
F05. Password fields are left to F03 (see
[FL-042](../flutter-limitations.md#fl-042) and section 7).

## 1. Rule

An instruction a field needs is shown as text on the screen, whole, and
stays there while the field is filled in. The field carries the same words
as its hint, so a screen reader reads them with the field.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies | Applies | Applies |

On Android Flutter puts the label and the hint of a text field into the
node's hint text, which TalkBack reads only while the field is empty
([FL-015](../flutter-limitations.md#fl-015)). Once the field has a value,
TalkBack reads it with neither its name nor the instruction. The visible
instruction is kept as an element of its own, so it can still be reached
next to the field; that is the workaround, and the catalog carries a note
on the Android platform. iOS and the web keep the hint when the field has
a value.

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [3.3.2 Labels or Instructions](https://www.w3.org/TR/WCAG22/#labels-or-instructions) | Labels or instructions are provided when content requires user input. The instruction is shown to everyone, as text |
| [1.3.1 Info and Relationships](https://www.w3.org/TR/WCAG22/#info-and-relationships) | The instruction is drawn next to its field, which says it belongs to the field. That relationship must be programmatically determinable too |
| [1.4.4 Resize Text](https://www.w3.org/TR/WCAG22/#resize-text) | Text can be resized to 200 percent without loss of content. Material cuts helper text to one line unless told otherwise ([FL-141](../flutter-limitations.md#fl-141)) |

The [Understanding document for 3.3.2](https://www.w3.org/WAI/WCAG22/Understanding/labels-or-instructions.html)
says that 3.3.2 does not require labels or instructions to be marked up or
associated with their fields; that is 1.3.1. It also allows an instruction
to be shown only while its field has focus. Both decide what the bad
examples below are said to fail.

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | An instruction gives the required information or the format of a field's value | [iOS Input Instructions](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/InputInstructions.md) ("convey required information or value format requirements for an input"), [WCAG G89](https://www.w3.org/WAI/WCAG22/Techniques/general/G89) |
| R2 | A screen reader user hears the instruction with focus on the field | iOS Input Instructions ("VoiceOver users need to hear the input instruction text when focused on the input"), [WCAG ARIA1](https://www.w3.org/WAI/WCAG22/Techniques/aria/ARIA1), [MDN: aria-describedby](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Reference/Attributes/aria-describedby) |
| R3 | The field's hint is the visible instruction text, word for word | iOS Input Instructions ("Use an `.accessibilityHint` matching the visible instruction text for each input") |
| R4 | The instruction is visible text near the field, read before the field in order where it can be | the [iOS reference's example code](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/iOSswiftUIa11yTechniques/InputInstructionsView.swift) (the good example draws the instruction between the label and the field; the bad one after the field, with no hint), [Android Compose TextField Controls](https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/components/TextFieldControls.md) (brief instructions in `supportingText`, under the field) |
| R5 | The instruction stays available while the field is filled in; placeholder text is not the place for it | [MDN: placeholder](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Attributes/placeholder) ("Placeholder text disappears from form fields when users start entering text"), [Understanding 3.3.2](https://www.w3.org/WAI/WCAG22/Understanding/labels-or-instructions.html) |
| R6 | The instruction can be read whole at any text size | [WCAG 1.4.4](https://www.w3.org/TR/WCAG22/#resize-text) |

Flutter references for the mechanisms used:

- [`SemanticsProperties.hint`](https://api.flutter.dev/flutter/semantics/SemanticsProperties/hint.html)
- [`InputDecoration.helperText`](https://api.flutter.dev/flutter/material/InputDecoration/helperText.html)
  and [`helperMaxLines`](https://api.flutter.dev/flutter/material/InputDecoration/helperMaxLines.html)
- [`CupertinoFormRow`](https://api.flutter.dev/flutter/cupertino/CupertinoFormRow-class.html),
  whose `helper` is "meant to inform the user about interaction with the
  child widget"

On the web Flutter writes a hint as `aria-description` on the `<input>`.
Comparison bar: an `<input>` with a `<label>` and `aria-describedby`
pointing at visible help text, as in WCAG technique ARIA1. Radix has no
primitive for a described field.

## 5. Examples

Every example ends with a count of changes to its field, so a person or a
test can tell that typing reached it. Every good field is "Username" with
the iOS reference's instruction, "4 to 10 characters, no spaces."

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-helper` | Material | The instruction as helper text under the field, and as the field's hint | `Semantics(hint:)` around `TextField(decoration: InputDecoration(labelText:, helperText:, helperMaxLines:))`; the identifier on the same `Semantics`, not in `TestId` ([FL-140](../flutter-limitations.md#fl-140)) | R1 to R3, R5, R6 |
| `good-cupertino` | Cupertino | The instruction as the help text of a form row, and as the field's hint | `CupertinoFormRow(prefix:, helper:)` with `Semantics(label:, hint:)` on the `CupertinoTextField` and the visible label in `ExcludeSemantics` ([FL-016](../flutter-limitations.md#fl-016)) | R1 to R3, R5, R6 |
| `good-before` | Widgets layer | The instruction between the label and the field, as the iOS reference lays it out | A `Text` above the field, and `Semantics(label:, hint:)` on the field with the visible label in `ExcludeSemantics` | R1 to R6 |

### Bad

| Slug | Defect | Violates | Fails |
| --- | --- | --- | --- |
| `bad-helper-only` | Helper text and nothing else. The instruction is on the screen, but the field is read without it, and the instruction is reached only as text after the field | R2, R3 | 1.3.1 |
| `bad-placeholder-format` | The format, "DD/MM/YYYY", is only the placeholder (`hintText`) of a labelled field. Material shows it only while the field is being edited and is empty, so it is gone at the first character. On Android and iOS a screen reader that reaches the field does not say it (on the web VoiceOver focuses the field on arrival and does) | R2, R5 | — (3.3.2 allows an instruction shown on focus) |
| `bad-helper-cut-off` | Helper text with the default `helperMaxLines`: with large text the instruction is cut to one line and ends in an ellipsis. The field has the instruction as its hint, so a screen reader reads it whole | R6 | 1.4.4 |

`bad-helper-only` follows the iOS reference's bad example, which has no
hint. The reference also puts the instruction after the field; Material's
helper text is always after the field, so that is not a defect of its own
here.

An instruction that is only in the hint, and not on the screen, is S15's
`bad-hint-only`; it is not repeated. A Cupertino row whose help text is
not tied to the field has the same defect as `bad-helper-only` and the
same tree (the help text is an element after the field, probe fixture 08),
so it is not a separate example.

`good-helper`, `bad-helper-only` and `bad-helper-cut-off` have no
`TestId`. Its `MergeSemantics` would pull the helper text into the field's
name ([FL-140](../flutter-limitations.md#fl-140)), which is a different
result from what an app gets. They carry the identifier on a plain
`Semantics` around the `TextField`, which joins the field's node
([FL-043](../flutter-limitations.md#fl-043): a `TextField` is not
affected).

## 6. Assertions by layer

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Good fields: a text field named "Username" with the instruction as its hint, before and after typing; the instruction on the screen and one node of its own, not a text field and with no action; the visible label not a second node; Tab reaches the field; `good-before` has the instruction just before the field in reading order; the helper of `good-helper` is a child of the field's node. Guidelines in light and dark, and 200% text at 320 by 640 with the instruction not cut. Bad: no hint on `bad-helper-only` before and after typing, the instruction only as text inside the field's node; the placeholder not shown or exposed until the field is focused, then part of the name, and gone after one character; the helper of `bad-helper-cut-off` whole at 100% and cut at 200%, while the tree keeps all of it. FL-140: a field with helper text inside `TestId` has the helper in its name |
| L3 web | Every field: role `textbox`, accessible name, accessible description, `aria-description`, no `aria-describedby`, before and after typing; the instruction as visible text once; Tab reaches the field; in `good-before` the instruction precedes the `<input>`. Bad: no description; the placeholder only while focused and empty, in `aria-label` and `placeholder`; the whole of the cut-off instruction in the page (the cut itself is not visible to this layer) |
| L3 Android | Every field: `EditText`, editable, the hint text "label, instruction" (or the label alone for `bad-helper-only`), no content description, before and after typing; the instruction as one node of its own that is not clickable; in `good-before` it is above the field. `bad-placeholder-format`: the hint text is the label until the field is clicked, then "label\nDD/MM/YYYY", then the label again after one character |
| L3 iOS | Every field: type text field, label "Username", the value after typing, the instruction as static text once; in `good-before` it is above the field. XCUITest cannot read a hint. `bad-placeholder-format`: the label gains the placeholder while it is being edited and empty, and loses it after one character. The cut is not visible to this layer |
| L4 TalkBack | What is read with focus on each field and each instruction, and for `good-helper` again with "abc" typed, as the last stop of the walk |
| L4 VoiceOver iOS | Every utterance between the "Example" heading and the change count, compared as a whole list, and the same for `good-helper` and `bad-helper-only` with "abc" typed. This is the only iOS layer that sees a hint |
| L4 VoiceOver web | Every stop between the "Example" heading and the change count, in Chromium and WebKit, and the same for `good-helper`, `bad-helper-only` and `bad-placeholder-format` with "abc" typed |

## 7. What the build found (Flutter 3.47.5)

The probe that came first is in [evidence/probes/f02](../evidence/probes/f02/).

- **`Semantics(hint:)` ties an instruction to a field on all three
  platforms.** The web has `aria-description` on the `<input>`, and
  VoiceOver reads "Username 4 to 10 characters, no spaces. edit text".
  Android puts label and hint in the field's hint text, "Username, 4 to 10
  characters, no spaces." ([FL-039](../flutter-limitations.md#fl-039)),
  and TalkBack reads "Username,", the rule, "Edit box". iOS has a hint
  read after the role: "Username Text field 4 to 10 characters, no
  spaces. Double tap to…".
- **Material helper text is not tied to its field**
  ([FL-140](../flutter-limitations.md#fl-140)). It is a node of its own,
  a child of the field's node, read as separate text after the field:
  "Username edit text", then the rule. Error text, in the same place, is
  given to the field as its hint (read in the source; F04). Inside
  `MergeSemantics`, the helper is merged into the field's name instead
  (probe, fixture 02, and a widget test), which is why the Material
  examples carry their identifier on a plain `Semantics`.
- **TalkBack drops the instruction once the field has a value**, with the
  label ([FL-015](../flutter-limitations.md#fl-015)): "Editing.", "abc",
  "Edit box". VoiceOver on iOS and on the web still read it. The helper
  text kept as an element is the way to reach it there, which is why no
  example hides the visible text from the semantics (probe, fixture 04).
  The good examples are read twice on iOS and the web, once on the field
  and once as text; the iOS reference does the same.
- **Helper text is one line unless `helperMaxLines` is set**
  ([FL-141](../flutter-limitations.md#fl-141)). At 200% text the
  instruction of `bad-helper-cut-off` ends in an ellipsis; the tree keeps
  all of it, so only the widget tests can see the cut.
- **A placeholder beside a label is drawn and exposed only while the field
  is focused and empty, and is then added to the name**
  ([FL-142](../flutter-limitations.md#fl-142)): "Date of birth\nDD/MM/YYYY"
  on every platform, and a `placeholder` attribute on the web. TalkBack
  and VoiceOver on iOS, moving to the field, read "Date of birth" alone.
  VoiceOver on the web moves keyboard focus into a field it reaches, so
  there the format is heard on arrival ("Date of birth DD/MM/YYYY edit
  text" in WebKit; Chromium leaves out "edit text"). The first walks
  expected the format not to be heard on the web; both browsers read it
  in all three attempts, and the expectation and the defect's wording were
  corrected. After one character it is gone everywhere.
- **With text in a field, VoiceOver on the web says where the caret is**:
  "abc Insertion at end of text. Username …" in Chromium and "abc contents
  selected Username …" in WebKit. The first web expectations left that
  out.
- **A Cupertino form row's `helper` is plain text after the field**, and
  the field needs `Semantics(label:, hint:)`
  ([FL-016](../flutter-limitations.md#fl-016)). The row's default padding
  made the label and the field overflow at 200% text on a 320-wide screen;
  `good-cupertino` uses less.
- **An obscured field is a text field on iOS until it is edited**, and a
  secure text field while it is (probe, fixture 10;
  [FL-042](../flutter-limitations.md#fl-042)). F02 has no password
  example; that question is left to F03.
- The TalkBack walk went wrong twice, each time on the example after the
  second field that had been typed into (`bad-helper-only`, filled): once
  "example bad-placeholder-format did not open" (the count was not in the
  active window), and once TalkBack said nothing on that example and every
  element after it, on all three walks of the run; the run between them
  passed. The cause was not found. The walk now looks for each example's
  count in every window, as `I12AnnouncementsTest` does, and types into one
  field only, `good-helper`, as its last example. `bad-helper-only` filled
  is still walked by VoiceOver on iOS and on the web.

**Not done yet.** Instructions for a group of fields, given once at the
start of a form (WCAG G184), are not built. Turning hints off in
VoiceOver's settings, which would leave only the visible text, was not
tested. Error text is F04. NVDA is not verified.
