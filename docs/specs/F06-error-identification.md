# Spec: F06 Error identification and announcement

Status: Draft 1 (2026-11-18), written with the build. Built in wave 1
(forms). Flutter pin: 3.47.5.

This spec covers what a text field in error needs: a message in words that
says what is wrong and how to put it right, the field marked invalid, the
message tied to the field, the error announced when the form is sent, and
focus moved to the first field in error. Labels are
[F01 Text fields and labels](F01-text-fields.md). Announcements in general
(live regions, `sendAnnouncement`, the status and alert roles) are
[I12 Announcements and live regions](I12-announcements.md); what is left
to I12 is listed in section 7. Autofill is F04 and redundant entry F05;
neither is built here. Errors on checkboxes, radio buttons, and pickers
are not built here either.

## 1. Rule

When a form is sent with a mistake in it, every field in error is marked
invalid and shows a message, in words, that says what is wrong and how to
put it right. Assistive technology reads that message with the field, the
first error is announced without the user having to look for it, and
focus moves to the first field in error.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies | Applies | Applies |

Each platform has a gap that the good examples work around or that the
user can get past. On Android Flutter gives a field no error state, so
TalkBack never says "error", and a field in error that has a value is
read without its message; the message is the next element and is
announced when it appears ([FL-180](../flutter-limitations.md#fl-180)).
Whether that makes Android a limitation for this entry is a decision for
review (see section 7). On iOS moving keyboard focus does not move
VoiceOver, and a `FocusSemanticEvent` does
([FL-184](../flutter-limitations.md#fl-184)). On iOS and the web an error
is announced only through `Form.validate()`
([FL-181](../flutter-limitations.md#fl-181)).

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [3.3.1 Error Identification](https://www.w3.org/TR/WCAG22/#error-identification) | When an input error is detected, the item in error is identified and the error is described to the user in text |
| [3.3.3 Error Suggestion](https://www.w3.org/TR/WCAG22/#error-suggestion) | When an input error is detected and a correction is known, the correction is suggested to the user |
| [4.1.3 Status Messages](https://www.w3.org/TR/WCAG22/#status-messages) | An error message that appears without taking focus is a status message: assistive technology must be able to present it without it receiving focus |

1.3.1 Info and Relationships is cited by the iOS reference as well: the
message belongs to its field, which is shown by position on screen and
must also be in the code. It is not one of this entry's criteria in the
coverage inventory; where an example fails it, the spec says so.

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | An error is shown as text that says what is wrong and how to fix it; colour is not the only sign | [iOS Error Validation](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/ErrorValidation.md) ("meaningful and specific", "Don't rely on color as the only method"), [Android View Input Error Announcements](https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/dynamicbehaviors/InputErrorAnnouncements.md) ("visible notifications with suggestions for correction") |
| R2 | The error is heard when a screen reader is on the field | iOS Error Validation (an `accessibilityHint` matching the visible error), Android View (`TextInputLayout.error`, which TalkBack reads with the field) |
| R3 | The field is marked invalid | [MDN: aria-invalid](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Reference/Attributes/aria-invalid) (the HTML equivalent named in the coverage inventory) |
| R4 | The error is announced when it appears | Android View ("must be announced to accessibility services"), iOS Error Validation ("VoiceOver users must hear an error message spoken when submitting a form with invalid data") |
| R5 | Focus moves to the first field in error when the form is sent | iOS Error Validation (`AccessibilityFocusState` to the first invalid input), Android View (`ACTION_ACCESSIBILITY_FOCUS` on the first field in error) |
| R6 | The error is cleared when the value is put right | Android View (set the error to the empty string when valid) |

Flutter references for the mechanisms used:

- [`Form`](https://api.flutter.dev/flutter/widgets/Form-class.html) and
  [`FormState.validate`](https://api.flutter.dev/flutter/widgets/FormState/validate.html)
- [`TextFormField`](https://api.flutter.dev/flutter/material/TextFormField-class.html)
  and [`InputDecoration.errorText`](https://api.flutter.dev/flutter/material/InputDecoration/errorText.html)
- [`FormField`](https://api.flutter.dev/flutter/widgets/FormField-class.html)
- [`SemanticsProperties.validationResult`](https://api.flutter.dev/flutter/semantics/SemanticsProperties/validationResult.html),
  [`SemanticsProperties.hint`](https://api.flutter.dev/flutter/semantics/SemanticsProperties/hint.html),
  [`SemanticsProperties.liveRegion`](https://api.flutter.dev/flutter/semantics/SemanticsProperties/liveRegion.html)
- [`MediaQuery.supportsAnnounceOf`](https://api.flutter.dev/flutter/widgets/MediaQuery/supportsAnnounceOf.html)
- [`FocusNode.requestFocus`](https://api.flutter.dev/flutter/widgets/FocusNode/requestFocus.html)

Comparison bar: an HTML `<input>` with `aria-invalid="true"` and its message
in `aria-describedby` (or `aria-errormessage`), and on Android a native
`EditText` with `setError`.

## 5. Examples

Every example has a Send button and ends with a count of the forms sent,
so a person or a test can tell that a form with no errors goes through.
The count is not a live region: the only thing announced is an error.
Name must not be empty; Email must have an `@` and a dot after it. Send
with nothing filled in shows both errors.

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-form` | Material | Name and Email; on Send, both errors under their fields, the first announced, focus on Name | `Form`, `TextFormField(validator:)` with `errorMaxLines`, `FormState.validate()`, then `FocusNode.requestFocus()` and a `FocusSemanticEvent` on the first field in error; each field identified with `Semantics(identifier:)`, not merged | R1 to R6 |
| `good-cupertino` | Cupertino | The same in a `CupertinoFormSection` | `FormField` around `CupertinoFormRow`: the prefix in `ExcludeSemantics`, the field in `Semantics(label:, hint: errorText, validationResult:)`, the error in `Semantics(liveRegion: !MediaQuery.supportsAnnounceOf(context))`, the same `validate()` and focus move | R1 to R6 |

No widgets-layer example: a text field needs `EditableText` and its
decoration, and what the Cupertino example adds by hand (`Semantics` with
`label`, `hint`, `validationResult`, and `liveRegion`) is all widgets
layer already. `CupertinoTextFormFieldRow`, the SDK's own Cupertino field
with a validator, is not used: its error is never announced on Android
([FL-182](../flutter-limitations.md#fl-182)) and its field has no label
([FL-016](../flutter-limitations.md#fl-016)), two defects in one, so it is
not a bad example either.

### Bad

| Slug | Defect | Violates | Fails |
| --- | --- | --- | --- |
| `bad-color-only` | The validator returns an empty message. The field turns red and is marked invalid, and nothing says what is wrong | R1 | 3.3.1, all platforms |
| `bad-vague-message` | The message is "Invalid.": it says that something is wrong, not what to enter, though the app knows | R1 | 3.3.3, all platforms |
| `bad-not-announced` | `errorText` set with `setState` outside a `Form`, focus left on Send. On iOS and the web nothing announces the error ([FL-181](../flutter-limitations.md#fl-181)); on Android its live region does | R4 | 4.1.3 on iOS and the web; none on Android |
| `bad-merged-error` | `MergeSemantics` around the field takes in its error text: the error is part of the name and is read twice, and on Android the whole field becomes a live region ([FL-183](../flutter-limitations.md#fl-183)) | R2 | none: the error is still identified, described, and announced, and the name still has the label |

`bad-merged-error` fails nothing as the criteria are written. It is here
because `TestId`, which every other technique wraps its controls in, is a
`MergeSemantics`, and it does this to a field.

Not built, and why:

- An error shown only as text below the field, not tied to it: the probe
  (q05) read it as a separate element after the field, announced, and the
  field itself had no error. As the criteria are written that fails 1.3.1,
  which is not one of this entry's criteria, and passes 3.3.1, so it was
  left out to keep each bad example to one of this entry's criteria.
- Focus not moved: R5 is in both references, but no WCAG criterion
  requires it once the error is announced; `bad-not-announced` covers the
  case where neither happens.

## 6. Assertions by layer

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Good, for both `supportsAnnounce` values (true for iOS and the web, false for Android): each field's label, hint, and validation result before and after Send; the error as a node of its own, a live region only where announcements are unsupported; one announcement from code, the first error, assertive, only where supported; focus on the first field in error, then on the next; the form sent once both are right; Send reached with Tab and pressed with Enter; guidelines in light and dark with the errors showing; no overflow and the whole message shown at 200% text on 320 by 640. Bad: no new text and no announcement; the hint "Invalid."; no announcement and no live region where supported, a live region on Android; the error in the label and the hint, no node of its own, the field a live region on Android. FL-182 pinned |
| L3 web | Good: `aria-invalid` false then true, the accessible name the label, the accessible description the error, the message once on the page; what reaches the assertive announcer (the first error only); DOM focus on the first field in error, then the next; sent once right; Tab order. Bad: invalid with no description and nothing announced; description "Invalid."; nothing announced and focus on Send; the error in the name and the description |
| L3 Android | Good: the hint text "label, error" and back to the label; no content description, no native error, not content-invalid (FL-180); the error a separate node and a polite live region; input focus on the first field in error, then the next; sent once right. Bad: no new text; "Email, Invalid."; a live region on Android with focus left on Send; the hint "label\nerror, error" and the field a live region |
| L3 iOS | Good: a text field named by its label before and after Send, the error a static text of its own, keyboard focus on the first field; sent once right. Bad: no new text; "Invalid." shown; the error shown, focus not on the field; the error in the label. XCUITest cannot read a hint or a live region |
| L4 TalkBack | What is said on Send, in the seven seconds after it is pressed, and with focus on each field and error; a field in error with a value; and where TalkBack's focus is after Send (asserted: the first field in error) |
| L4 VoiceOver iOS | Everything said in the eight seconds after Send is activated, and where the cursor is afterwards |
| L4 VoiceOver web | Everything VoiceOver is given in the eight seconds after Send is pressed with the keyboard, in Chromium, and where the cursor is afterwards; silence only with the capture proven live |

## 7. What the build found (Flutter 3.47.5)

The probe that came first, with a native comparison on Android, is in
[evidence/probes/f06](../evidence/probes/f06/). Detail is in
[flutter-limitations.md](../flutter-limitations.md).

- **`TextFormField` does most of it.** `InputDecorator` shows the error,
  makes it a node of its own, and puts it in the field's hint; `FormField`
  sets `validationResult`; `Form.validate()` announces the first error.
  On the web that is `aria-invalid="true"` and an `aria-description`, and
  VoiceOver reads "Name Enter your name. invalid data edit text". On iOS
  VoiceOver reads the hint after the role, with or without a value. On
  Android the label and the error are joined in the hint text.
- **Android has no error state for a Flutter field**
  ([FL-180](../flutter-limitations.md#fl-180)). Neither `setError` nor
  `setContentInvalid` is used, so TalkBack never says "error", and a field
  in error that has a value is read "abc, Edit box": the hint text that
  holds the label and the error is not read once there is a value
  ([FL-015](../flutter-limitations.md#fl-015)). A native `EditText` with
  `setError` is read "Error: … abc. Edit box". The message is the next
  element and is announced when it appears, so the error is not lost, but
  a user coming back to a field does not hear it there. No workaround in
  the SDK. **Decision for review:** F01 records the same mechanism for the
  label as `PlatformStatus.limitation` on Android; F06 records Android as
  applying, with a note, because the error is identified, described, and
  announced there and only the reading on the field is missing.
- **Who announces depends on the platform**
  ([FL-181](../flutter-limitations.md#fl-181)). On Android every error text
  is a live region, whatever set it; TalkBack read both errors when two
  appeared together, in no fixed order. On iOS and the web only
  `Form.validate()` announces, the first error only, assertively; an
  `errorText` set any other way is silent there (`bad-not-announced`).
- **Keyboard focus is not enough on iOS**
  ([FL-184](../flutter-limitations.md#fl-184)). `requestFocus()` moves
  TalkBack and the web's DOM focus, and VoiceOver on the web follows it;
  VoiceOver on iOS stayed on the button. A `FocusSemanticEvent` to the
  field moves it; the examples do both.
- **`TestId` cannot be used on a field in error**
  ([FL-183](../flutter-limitations.md#fl-183)). Its `MergeSemantics` takes
  in the error text: the error joins the name and is read twice, and on
  Android the whole field becomes a live region (`bad-merged-error`). The
  fields carry `Semantics(identifier:)` instead, which joins the text
  field's own node. This is a departure from the guide ("Wrap a control in
  `TestId`"), recorded here for review; `TestId` itself is unchanged.
- **The Cupertino field has to be built.** `CupertinoTextFormFieldRow`'s
  error is never announced on Android
  ([FL-182](../flutter-limitations.md#fl-182)) and its field has no label
  ([FL-016](../flutter-limitations.md#fl-016)). `good-cupertino` gives a
  `CupertinoTextField` what `InputDecorator` gives a Material one. A live
  region used on every platform was announced twice on the web, by itself
  and by `Form` (probe p13); `good-cupertino` uses one only where
  `supportsAnnounceOf` is false, as `InputDecorator` does.
- **A second hint repeats the error.** The iOS reference adds the error
  as an `accessibilityHint`; `TextFormField` already does, and adding
  `Semantics(hint:)` around it makes the hint say it twice (probe p08).
- **`errorMaxLines` is needed.** The default is one line with an
  ellipsis; at 200% text on a 320 wide screen the email message takes six
  lines, and `good-form` allows eight.
- **`validationResult` is web only** (source read): nothing in the Android
  or iOS engine reads it.

### What is left to I12

The announcement mechanisms themselves are I12's: live regions, sending
an announcement from code with a fallback, the status and alert roles, and
assertiveness ([FL-017](../flutter-limitations.md#fl-017),
[FL-018](../flutter-limitations.md#fl-018)). F06 uses what `Form` and
`InputDecorator` already do and adds no announcement of its own. Not done
in either: an error summary at the top of a long form (probed, p11: on the
web and iOS it is announced together with `Form`'s first error, and on
Android with one field's live region; not built), and announcing an error
that appears while typing (`AutovalidateMode.onUserInteraction`, silent on
iOS and the web, probe p12), which needs a rate limit like I12's
`bad-chatty-live-region` warns about. I12's spec says error messages on
form fields are F04; they are this entry, F06.

**Not done yet.** Errors on checkboxes, radio buttons, switches, and
pickers. An error summary. Errors shown while typing. Clearing an error as
soon as the field is right, before the form is sent again. A swipe-order
check on Android that the message comes straight after its field (the
emulator walk forces focus). Moving focus with `requestFocus()` alone is
not an example, so FL-184 is observed in the probe and not asserted.
