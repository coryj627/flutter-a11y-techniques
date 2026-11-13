# Spec: F01 Text fields and labels

Status: Draft 1 (2026-11-13), written with the build. Third vertical-slice
technique ([plan](../plan.md), phase 3). Flutter pin: 3.47.5.

Out of scope here, each with its own entry: input instructions (F02), keyboard
types (F03), error messages (F04), required fields (F05), and autofill.

## 1. Rule

Every text field has a visible label that stays visible while the field is
filled in, and that label is the name assistive technology announces for the
field.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies, with a limitation | Applies | Applies |

On Android the label is exposed, but TalkBack stops speaking it once the field
has a value (FL-015). Two more limitations concern Cupertino fields; see
section 7.

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [1.3.1 Info and Relationships](https://www.w3.org/TR/WCAG22/#info-and-relationships) | The label–field relationship shown visually is available programmatically |
| [2.5.3 Label in Name](https://www.w3.org/TR/WCAG22/#label-in-name) | The accessible name contains the visible label text |
| [3.3.2 Labels or Instructions](https://www.w3.org/TR/WCAG22/#labels-or-instructions) | A label is provided when input is required, and stays available |
| [4.1.2 Name, Role, Value](https://www.w3.org/TR/WCAG22/#name-role-value) | The field exposes its name, its role, and its value |

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | A text field needs visible label text next to it, exposed as the field's accessible name | [CVS iOS Text Fields](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/TextFields.md), [CVS View Input Field Labels](https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/basics/InputFieldLabels.md), [CVS Compose TextField Controls](https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/components/TextFieldControls.md) |
| R2 | Screen reader users must hear the label when focus is on the field | CVS iOS Text Fields |
| R3 | Do not use placeholder text in place of a label: it disappears once a value is entered | CVS iOS Text Fields; [MDN input](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/input) |
| R4 | A label must be associated with its field, not only placed near it | CVS View Input Field Labels; [MDN label](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/label) |
| R5 | Multi-line input is labelled the same way | [MDN textarea](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/textarea) |

Flutter references for the mechanisms used:

- [`InputDecoration.labelText`](https://api.flutter.dev/flutter/material/InputDecoration/labelText.html)
- [`Semantics`](https://api.flutter.dev/flutter/widgets/Semantics-class.html)

Radix comparison bar: the Radix Label primitive renders a native `label`
associated with its control; the bar is `label` with `input` or `textarea` as
described by MDN.

## 5. Examples

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-label` | Material | A single-line and a multi-line field | `TextField(decoration: InputDecoration(labelText: …))` | R1, R2, R5 |
| `good-label-above` | Widgets layer | A label drawn above the field | `Semantics(label: …, child: TextField())`, with the visible label in `ExcludeSemantics` | R1, R4 |
| `good-cupertino` | Cupertino | A field in a form row | `CupertinoFormRow(prefix:)` as the visible label, hidden from assistive technology, and `Semantics(label:)` on the `CupertinoTextField` | R1, R4 |

### Bad

| Slug | Defect | Violates | Fails |
| --- | --- | --- | --- |
| `bad-placeholder-only` | `hintText` is the only label; name and label vanish once text is typed | R3 | 3.3.2, 4.1.2 |
| `bad-unassociated-label` | A `Text` above the field that is not tied to it | R4 | 1.3.1, 4.1.2 |
| `bad-no-label` | Only a prefix icon | R1 | 3.3.2, 4.1.2 |
| `bad-name-mismatch` | Visible label "Email", name "Contact address" | R1 | 2.5.3 |
| `bad-cupertino-placeholder` | `CupertinoTextField(placeholder:)` only | R3 | 3.3.2, 4.1.2 |
| `bad-cupertino-prefix` | `CupertinoFormRow(prefix:)` left as the only label (Flutter limitation FL-016) | R4 | 1.3.1, 4.1.2 |

## 6. Assertions by layer

Fields carry a `TestId`, `f01-<slug>-<name>`. Several checks are made twice:
with the field empty, and after "abc" has been typed, because the placeholder
defect only appears once the field has a value.

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Text field flag, label, and value; the label survives typing for good fields and vanishes for placeholder fields; the visible label is exposed once, not twice; guidelines and 200% text for the good examples |
| L3 web | Real `input` and `textarea` with role `textbox`; accessible name; explicit `aria-label` before and after typing; Tab moves between fields |
| L3 Android | Class `android.widget.EditText`, editable, name (hint text) before and after typing with real key events |
| L3 iOS | Element type text field, label, and value before and after typing |
| L4 TalkBack | Name and "Edit box" per field, empty and filled |
| L4 VoiceOver iOS | "Email Text field …" per field, empty and filled |
| L4 VoiceOver web | "Email edit text" per field, empty and filled, in Chromium and WebKit |

## 7. What the build found (Flutter 3.47.5)

Detail is in [flutter-limitations.md](../flutter-limitations.md).

- **`labelText` and `Semantics(label:)` name the field on all three
  platforms**, and the name survives typing in the tree everywhere.
- **TalkBack stops speaking the label once the field has a value** (FL-015).
  Flutter exposes the label as Android hint text. A filled, labelled field is
  read as "abc, Edit box". VoiceOver keeps the label: "Email abc Text field"
  on iOS and "abc … Email edit text" on web.
- **A placeholder is a name only while the field is empty.** After typing, the
  field has no name on Android or iOS and VoiceOver says "abc Text field". On
  web Flutter removes `aria-label` and leaves a `placeholder` attribute, which
  VoiceOver does not speak for a filled field.
- **Cupertino fields have no label of their own** (FL-016).
  `CupertinoTextField` only has `placeholder`, and a `CupertinoFormRow` prefix
  is separate text.
- **WebKit hides the unassociated-label defect from the ear.** With plain text
  next to an unnamed field, VoiceOver in WebKit says "Email edit text", a
  guess from the nearby text. Chromium says "edit text blank". The tree is
  unnamed in both.
- **Chromium VoiceOver is silent on an unnamed empty field** and has silent
  stops between some elements, so the web walk stops at a recognised phrase
  and does not count steps.
- **Setting a field's text through the Android accessibility action left its
  hint in place**, where real key presses removed it. The tests type with key
  events. Cause not investigated.

**Not done yet.** Instructions, keyboard types, errors, required state, and
autofill are separate entries. Password fields are not covered.
