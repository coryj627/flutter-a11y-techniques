# Spec: F03 Keyboard types

Status: Draft 1 (2026-11-18), written with the build. Sixth technique of
batch 2 ([plan](../plan.md)), built in wave 1. Flutter pin: 3.47.5.

A text field tells the platform what it takes. This spec covers the three
things it says: which on-screen keyboard fits (`keyboardType`), what the
keyboard's Enter key does (`textInputAction`), and, for information about
the user, what that information is (`autofillHints`), which is what WCAG
1.3.5 asks for. It also covers a password field (`obscureText`), which
F02 Input instructions (in review, so not linked) handed on with
[FL-042](../flutter-limitations.md#fl-042). A field's label is
[F01](F01-text-fields.md) and its instructions F02. Autofill in depth
(addresses, card numbers, a wrong hint, autofill services and password
managers) is F04 Autofill and input purpose, which the
[coverage inventory](../coverage-inventory.md) also maps to 1.3.5; this
spec sets hints the way the keyboard type references do, and
`bad-no-purpose` and `good-sign-in` could move to F04 if the wave decides
so. Error messages are F06. Focus order is I02 and keyboard actions in
general I04; this spec checks only that Next moves to the next field.

## 1. Rule

A text field asks for the keyboard that fits what it takes and says what
its Enter key does. When it collects information about the user that is
one of WCAG's input purposes, it names that purpose with an autofill hint,
so that the platform can offer to fill it in. A password field obscures
its text, and assistive technology is told that it is a password field.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies | Applies, with a note | Limitation |

On the web the autofill hints do not reach the page
([FL-161](../flutter-limitations.md#fl-161)): every single-line field
that is not obscured has `autocomplete="off"`, whatever its hints, except
one with the email keyboard type, which has `autocomplete="email"`. An
obscured field gets its hint (`current-password`) once it has been
focused. No SDK API sets `autocomplete`, so the purpose of a name, a
phone number, or a username cannot be made programmatically determinable
on the web. This is recorded as a limitation with no workaround; the
wave's principal has been asked to confirm it.

On iOS the hints become the field's text content type while it is being
edited, according to the engine source. No test here can read a content
type; the "Passwords" button iOS adds above the keyboard is the only trace
seen (section 7). An obscured field is a secure text field only while it
is being edited ([FL-042](../flutter-limitations.md#fl-042)).

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [1.3.5 Identify Input Purpose](https://www.w3.org/TR/WCAG22/#identify-input-purpose) (AA) | "The purpose of each input field collecting information about the user can be programmatically determined" when the field serves one of the [input purposes](https://www.w3.org/TR/WCAG22/#input-purposes) and the technology supports it |

How 1.3.5 is applied here, from the
[Understanding document](https://www.w3.org/WAI/WCAG22/Understanding/identify-input-purpose.html):

- It is about the purpose, not the keyboard. The Understanding document
  does not mention keyboard types or `inputmode`, and calls `type` a broad
  category that does not necessarily convey a purpose. The reference
  repositories say a keyboard type supports "part of" 1.3.5; here the
  keyboard type is not counted towards it. No WCAG 2.2 criterion requires
  a particular on-screen keyboard, so the keyboard defects below are
  stated as defects with no criterion failed.
- It covers information about the user only. An amount is not, so
  `good-amount` needs no hint (the Understanding document's own example is
  `transaction-amount`).
- The sufficient technique on the web is
  [H98](https://www.w3.org/WAI/WCAG22/Techniques/html/H98) (an
  `autocomplete` token that matches the field's purpose); the failure is
  [F107](https://www.w3.org/WAI/WCAG22/Techniques/failures/F107)
  (a wrong token). `autocomplete="off"` or `"on"` names no purpose, and a
  browser's guess from the `name` attribute is not a programmatic
  determination.
- For Android and iOS,
  [WCAG2ICT](https://www.w3.org/TR/wcag2ict-22/#identify-input-purpose)
  applies 1.3.5 as written to software whose technology has attributes
  for the meaning of a field. Android's autofill hints
  (`View.setAutofillHints`) and iOS's text content types are those
  attributes; Flutter's `autofillHints` maps to both.

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | A field sets the keyboard type that matches the data it takes; a wrong one can make entry harder or impossible | [Android View Keyboard Types](https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/dynamicbehaviors/KeyboardTypes.md) (`android:inputType`, "Numeric keyboard type prevents text data entry" in its app), [Android Compose Keyboard Types and Options](https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/interactions/KeyboardTypes.md) (`keyboardOptions`), [MDN: inputmode](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Global_attributes/inputmode) ("This allows a browser to display an appropriate virtual keyboard") |
| R2 | A field that collects information about the user names its purpose for autofill | Android View Keyboard Types (`android:autofillHints`, "the other part of supporting" 1.3.5), [Understanding 1.3.5](https://www.w3.org/WAI/WCAG22/Understanding/identify-input-purpose.html), [H98](https://www.w3.org/WAI/WCAG22/Techniques/html/H98), [MDN: autocomplete](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Attributes/autocomplete) |
| R3 | Keyboard options that fit the data: capital letters for a name, no autocorrection for an address | Android Compose Keyboard Types and Options (`capitalization`, `autoCorrectEnabled`) |
| R4 | A password keyboard type is not masking: a password field must also be masked | Android Compose Keyboard Types and Options ("does not supply input field masking"), [MDN: input type=password](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/input/password) |
| R5 | The Enter key says what it does | [MDN: enterkeyhint](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Global_attributes/enterkeyhint); the Android Compose reference treats it under keyboard actions |

The iOS reference has no keyboard types document.

Flutter references for the mechanisms used:

- [`TextField.keyboardType`](https://api.flutter.dev/flutter/material/TextField/keyboardType.html) and [`TextInputType`](https://api.flutter.dev/flutter/services/TextInputType-class.html)
- [`TextField.autofillHints`](https://api.flutter.dev/flutter/material/TextField/autofillHints.html) and [`AutofillHints`](https://api.flutter.dev/flutter/services/AutofillHints-class.html)
- [`AutofillGroup`](https://api.flutter.dev/flutter/widgets/AutofillGroup-class.html)
- [`TextField.textInputAction`](https://api.flutter.dev/flutter/material/TextField/textInputAction.html), [`textCapitalization`](https://api.flutter.dev/flutter/material/TextField/textCapitalization.html), [`autocorrect`](https://api.flutter.dev/flutter/material/TextField/autocorrect.html), [`obscureText`](https://api.flutter.dev/flutter/material/TextField/obscureText.html)
- [`CupertinoTextField`](https://api.flutter.dev/flutter/cupertino/CupertinoTextField-class.html), which takes the same parameters

Comparison bar: an `<input>` with the `type`, `inputmode`,
`autocomplete`, and `enterkeyhint` MDN describes for its data.

## 5. Examples

Every example ends with a count of changes to its fields, so a person or a
test can tell that typing reached them.

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-contact` | Material | Name, Email, and Phone, each with its keyboard, its purpose, and Next or Done | `TextField(keyboardType:, autofillHints:, textInputAction:)`; `textCapitalization: words` on the name and `autocorrect: false` on the email | R1 to R3, R5 |
| `good-amount` | Material | An amount with the decimal keyboard and no hint: it is not about the user | `TextField(keyboardType: TextInputType.numberWithOptions(decimal: true))` | R1, R5 |
| `good-cupertino` | Cupertino | Email and Phone in a form section | `CupertinoTextField.borderless(keyboardType:, autofillHints:, textInputAction:)` with `Semantics(label:)` and the visible label in `ExcludeSemantics` ([FL-016](../flutter-limitations.md#fl-016)) | R1 to R3, R5 |
| `good-sign-in` | Widgets layer | Username and Password in one autofill group; the password obscured | `AutofillGroup` around two `TextField`s with `AutofillHints.username` and `AutofillHints.password`, and `obscureText: true` | R2, R4, R5 |

### Bad

| Slug | Defect | Violates | Fails |
| --- | --- | --- | --- |
| `bad-number-for-name` | A name field with `TextInputType.number`. The on-screen keyboard has digits only: on Android and iOS a name cannot be typed with it | R1 | None as written: no criterion requires an on-screen keyboard. The purpose is given, so 1.3.5 is met where hints work |
| `bad-default-keyboard` | An email field left with the default keyboard: no "@" on its first page | R1 | None as written on Android and iOS. On the web it also loses the only `autocomplete` an email field gets there (FL-161), which is the limitation's doing, not the example's |
| `bad-no-purpose` | A name field with the name keyboard and no autofill hint: nothing names its purpose | R2 | 1.3.5 on Android and iOS. On the web the good example fails it too (FL-161) |
| `bad-email-no-suggestions` | An email field with `enableSuggestions: false`. On Android the engine turns the email keyboard into the general one, with no "@" ([FL-160](../flutter-limitations.md#fl-160)); iOS and the web keep it | R1 | None as written |

`bad-email-no-suggestions` is a reasonable choice that a Flutter defect
spoils on one platform, as F10's `bad-indicator-label` is. It is kept as
an example so that every layer that can see FL-160 asserts it.

Not built, with the reason:

- **A custom field on `EditableText` alone.** `EditableText` takes the same
  `keyboardType`, `autofillHints`, and `textInputAction`, but it has no tap
  to focus and no semantics action that starts editing: in the probe a
  click and a tap did not focus it on Android or the web (fixture 11). A
  field built on it is a custom text field, which is not this technique.
  The widgets-layer example is `AutofillGroup`, which is in the widgets
  library.
- **A wrong hint** (F107, such as `AutofillHints.email` on a phone field).
  Each layer would show only a different string where `bad-no-purpose`
  shows none.
- **A password shown in plain text.** No WCAG criterion requires masking.

## 6. Assertions by layer

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Every field: one text field node with its label, identifier, semantics input type (email, phone, or text), and obscured flag, before and while editing; what it sends the platform when editing starts (`TextInput.setClient`): keyboard type, decimal, hints, action, obscured, capitalization, suggestions. Next moves focus to the next field; Done on the last ends editing; Tab reaches every field; typing is counted. `good-sign-in`: both fields sent as one autofill group; the password's value is bullets. Guidelines in light and dark, and 200% text at 320 by 640. Bad: the number keyboard with the name hint; the text keyboard with the email hint and a text semantics type; an empty hint list; suggestions off |
| L3 web | Every field: role `textbox`, its name, and `type`, `inputmode`, `autocomplete`, `enterkeyhint`, and `name` before editing, while editing, after typing, and after leaving; Tab order; Enter on a Next field moves on. The password is `type="password"` and what is typed is not in the page. With an Android phone's user agent: `inputmode` and `enterkeyhint` while editing. FL-161 is asserted on every field |
| L3 Android | Every field: `EditText`, editable, its label as hint text, the password flag. While editing: the editor's input type and IME action from `dumpsys input_method`, the keys the keyboard shows, and the autofill hints given to the autofill framework. `good-sign-in`: two autofill entries, the password current. The password's text is bullets while editing and after |
| L3 iOS | Every field: type text field and its label. While editing: the keyboard's keys and its return key, the "Passwords" button, and the field's type (a secure text field for the password, FL-042). The password's value is bullets, and it is a plain text field again once editing moves on |
| L4 TalkBack | Every field on arrival, and the password again with "abc" typed, as the last stop |
| L4 VoiceOver iOS | Every utterance between the "Example" heading and the change count; the password while it is being edited |
| L4 VoiceOver web | Every stop between the "Example" heading and the change count, in Chromium and WebKit, and `good-sign-in` with "abc" in the password |

The keyboard and purpose defects are not heard: a screen reader reads the
bad examples as it reads the good ones, and the screen reader layers
record that.

## 7. What the build found (Flutter 3.47.5)

The probe that came first is in [evidence/probes/f03](../evidence/probes/f03/).

- **On Android and iOS the keyboard types work as the references say,
  and the keyboard can be checked.** Android's input method is asked for
  the input type the reference's `android:inputType` would give (`0x21`
  for an email field, `0x3` for a phone, `0x2002` for a decimal), and the
  keys Gboard shows are in its window: "@" for email, the dial pad for a
  phone, digits only for a number. On iOS `app.keyboards` shows the email
  keyboard's "@", the name pad's "phone pad" key, and the number, decimal,
  and phone pads. The return key follows `textInputAction` ("next",
  "done") on both, except that iOS's pads have no return key at all
  ([FL-163](../flutter-limitations.md#fl-163)).
- **Autofill hints reach Android and iOS.** The FlutterView gives the
  autofill framework each hint, translated to Android's own
  (`personName`, `emailAddress`, `phoneNumber`, `username`, `password`),
  and an autofill group as one structure with the field being edited
  marked. On iOS the only trace is the "Passwords" button above the
  keyboard, offered for the username and the password and for no other
  field.
- **On the web the hints are lost**
  ([FL-161](../flutter-limitations.md#fl-161)). `autocomplete` is "off"
  for every single-line field that is not obscured, before, while, and
  after editing, except an email field, which has "email" from its
  keyboard type. The password gets `current-password` once focused. The
  hint is written as the `<input>`'s `name` while editing, which a
  browser may use as a guess.
- **On the web only email, phone, and URL fields ask for a keyboard**
  ([FL-162](../flutter-limitations.md#fl-162)): `inputmode="email"`,
  `type="tel"`, `type="url"`. A number or decimal field has nothing, even
  as on an Android phone, where `enterkeyhint` does follow the action.
  Flutter decides that it is on a phone from `navigator.platform`, which
  Playwright's device emulation leaves as "MacIntel"; the tests set it.
- **`enableSuggestions: false` costs an Android email field its "@"**
  ([FL-160](../flutter-limitations.md#fl-160)): the engine joins two
  keyboard variations with a bitwise or and asks for the filter
  variation, `0x800b1`. `good-contact` turns off `autocorrect` only.
- **A password field** ([FL-042](../flutter-limitations.md#fl-042),
  settled here). Android: the password flag always; TalkBack says
  "Password", "password. Edit box", and with "abc" typed "Editing.
  password. 3 characters. Edit box". iOS: a plain text field until it is
  edited ("Password Text field Double tap to edit."), a secure text field
  while it is ("Password Secure text field Is editing •••"), and a plain
  one again after. Web: `type="password"` always; VoiceOver reads
  "Password secure text field", and with "abc" typed "3 characters
  contents selected Password secure text field" in Chromium and "•••" in
  WebKit. The typed text is not exposed anywhere: the value is bullets in
  every tree, and no screen reader read it.
- **Next moves to the next field** in the widget tests and on the web,
  where Enter does it; Done ends editing.
- **Almost none of it is heard.** TalkBack and VoiceOver on iOS read a
  field's name and role the same whatever keyboard or hint it has, so
  every bad example sounds like its good one, and that is what the
  transcripts show. The one exception is a phone field on the web:
  VoiceOver names its `type="tel"`, "Phone telephone" in Chromium and
  "Phone telephone number field" in WebKit. A password is heard as one
  everywhere: "password" (TalkBack), "Secure text field" while edited
  (VoiceOver on iOS), "secure text field" (VoiceOver on the web).
- **A bare `EditableText` cannot be focused** by a click on Android or
  the web (probe, fixture 11), which is why the widgets-layer example is
  an `AutofillGroup` and not a field built on `EditableText`.
- **Testing with the keyboard up.** Every Android check closes the
  keyboard before it reads other nodes, and presses Back only while the
  keyboard's window is there (Back with no keyboard leaves the app, as
  the probe's first run did). On iOS each field is looked at in a freshly
  opened example, because a pad cannot be put away (FL-163). The TalkBack
  walk types into one field only, the password, as its last stop, as F02
  advised; it went through with no retries and no silence.

**Not done yet.** A field built on `EditableText`; a wrong hint (F107);
a PIN (in the probe, fixture 14: Android's input method is told it is a
plain number field); the `onTapOutside` workaround for FL-163, which is
described and not tested; `TextInputType.datetime`, `streetAddress`, and
`twitter`; whether a real phone's browser shows the keyboards the
attributes ask for; iOS's text content types beyond the "Passwords"
button, which no test here can read; NVDA.
