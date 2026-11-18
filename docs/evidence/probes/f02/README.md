# F02 probe: instructions for a text field

Run on 2026-11-18, Flutter 3.47.5, before the F02 examples were written.
The fixture is `probe.dart.txt` (a second entry point, not part of the
app). Every fixture's label starts with its number ("i01 Username"), and
each carries the identifier `iNN` on a plain `Semantics` around it (which
joins a `TextField`'s node; [FL-043](../../../flutter-limitations.md#fl-043)
does not affect a text field). The screen has two pages, so that each fits
on a phone and the iOS walk never scrolls; a button at the top switches
them.

The throwaway drivers are kept beside it:

- `probe_web.js.txt`: a Playwright test, run from `web_tests/` with a
  config of its own against `flutter build web -t lib/probe.dart`, that
  prints the DOM of the semantics tree and, in Chromium, the
  accessibility tree (CDP `Accessibility.getFullAXTree`).
- `probe_android.py.txt`: run under `tool/with_devices.py`; installs the
  probe APK, dumps `uiautomator` before and after typing.
- `F02ProbeUITests.swift.txt`: an XCUITest class that prints the iOS tree
  and walks it with `XCUIVoiceOverService`, before and after typing.

The instruction in every fixture but 10 and 11 is "4 to 10 characters, no
spaces." ("the rule" below). Fixtures 10 and 11 use a longer one.

Web is Playwright's Chromium and WebKit on macOS (the DOM was the same in
both). Android is `uiautomator dump` on the Pixel_10a emulator, Android 17.
iOS is the XCUITest tree and `XCUIVoiceOverService` on the iPhone 17
simulator, iOS 27.0; the service returns the first 64 characters of an
utterance.

| # | Fixture | Web | Android | iOS (tree; VoiceOver) |
| --- | --- | --- | --- | --- |
| 01 | `TextField(decoration: InputDecoration(labelText:, helperText:))` | `<input aria-label="i01 Username">`, no description; the rule as text inside the field's element, beside the `<input>` | `EditText`, hint text "i01 Username"; then a `View` whose description is the rule, inside the field's bounds | text field "i01 Username", then static text, the rule; "i01 Username Text field Double tap to edit.", then "4 to 10 characters, no spaces." |
| 02 | 01 inside `MergeSemantics`, as `TestId` wraps a field | `aria-label="i02 Username\n4 to 10 characters, no spaces."`, no separate text | `EditText`, hint text "i02 Username\n4 to 10 characters, no spaces.", no separate `View` | text field labelled "i02 Username\n4 to 10 characters, no spaces."; "i02 Username 4 to 10 characters, no spaces. Text field Double ta…", no second stop |
| 03 | `Semantics(hint: rule)` around 01 | `aria-description` the rule; the helper text as in 01 | `EditText`, hint text "i03 Username, 4 to 10 characters, no spaces."; then the rule as a `View` | as 01; "i03 Username Text field 4 to 10 characters, no spaces. Double ta…", then the rule |
| 04 | 03 with `helper: ExcludeSemantics(child: Text(rule))` | `aria-description` the rule, no text | hint text "i04 Username, 4 to 10 characters, no spaces.", no `View` | "i04 Username Text field 4 to 10 characters, no spaces. Double ta…", no second stop |
| 05 | `labelText` and `hintText: 'name@example.com'` | not focused: `aria-label="i05 Email"`; focused: `aria-label="i05 Email\nname@example.com"` and `placeholder="name@example.com"`; after focus left, the `aria-label` is the label again and the `placeholder` attribute stays | hint text "i05 Email"; focused: "i05 Email\nname@example.com"; after focus left, "i05 Email" | "i05 Email Text field Double tap to edit." |
| 06 | 03 inside `MergeSemantics` | name with the rule, and `aria-description` the rule | hint text "i06 Username\n4 to 10 characters, no spaces., 4 to 10 characters, no spaces." | "i06 Username 4 to 10 characters, no spaces. Text field 4 to 10 c…": the rule twice |
| 07 | `CupertinoFormRow(prefix: ExcludeSemantics(Text), helper: Text(rule), child: Semantics(label:, hint:, child: CupertinoTextField.borderless()))` | `aria-label`, `aria-description`; the rule as text after the field | hint text "i07 Username, 4 to 10 characters, no spaces."; then the rule as a `View` | "i07 Username Text field 4 to 10 characters, no spaces. Double ta…", then the rule |
| 08 | 07 without `hint:` | no description; the rule as text after the field | hint text "i08 Username"; then the rule as a `View` | "i08 Username Text field Double tap to edit.", then the rule |
| 09 | label in `ExcludeSemantics`, `Text(rule)`, then a `TextField` with `Semantics(label:, hint:)` | the rule as text, then the `<input>` with `aria-description` | the rule as a `View`, then the `EditText` with hint text "i09 Username, 4 to 10 characters, no spaces." | the rule, then "i09 Username Text field 4 to 10 characters, no spaces. Double ta…" |
| 10 | `TextField(obscureText: true)` with `labelText`, `helperText` and `Semantics(hint:)` | `<input type="password">` with `aria-description` | `EditText` with `password="true"`, the label and rule in its hint text; typed text shown as "•••" | not being edited: a text field (not a secure text field); "i10 Password Text field 8 characters minimum, with at least one…". Being edited: a secure text field, value "•••" ([FL-042](../../../flutter-limitations.md#fl-042)) |
| 11 | a long `helperText` with the default `helperMaxLines` | the whole text in the DOM | hint text "i11 Password"; the whole text as a `View` | the whole text as static text |

After "abc" was typed into 01 and 03: on the web the names and
descriptions were unchanged; on iOS VoiceOver read
"i03 Username abc Text field 4 to 10 characters, no spaces. Doubl…", so the
hint stays on a filled field, and 01 still had no hint.

A widget test of the same screen (not kept) showed the shapes behind
these: in 01 the helper is a node of its own and a child of the field's
node; in 02 it is merged into the field and its label is appended to the
field's; in 05 the placeholder's text is added to the field's label while
it is shown, and only then.

On Android, after "abc" was typed into 01 and 03 and the keyboard put
away, the hint text of both was unchanged (the label, and for 03 the
rule): Flutter keeps label and hint in the hint text, which TalkBack reads
for an empty field only ([FL-015](../../../flutter-limitations.md#fl-015)).
`uiautomator dump` does not show nesting; the helper's `View` sits inside
the field's bounds, which take in the helper's line.

## What it shows

- **Helper text is not a description** (01). It is drawn under the
  field, and in the tree it is separate text. A screen reader reads the
  field without it ([FL-140](../../../flutter-limitations.md#fl-140)).
- **`Semantics(hint:)` with the same words ties it to the field** (03, 07,
  09) on every platform: `aria-description` on the web, a hint read after
  the role on iOS. The visible text stays an element of its own.
- **`MergeSemantics` around a field with helper text moves the helper into
  the name** (02, 06). With a hint as well, the instruction is read twice
  in one utterance (06). The examples keep `TestId` off those fields.
- **Excluding the helper from the semantics** (04) leaves the instruction
  in the hint only, which TalkBack does not read once the field has a
  value ([FL-015](../../../flutter-limitations.md#fl-015)); the examples
  keep the helper.
- **A placeholder beside a label** (05) is there only while the field is
  focused and empty, and is then part of the name
  ([FL-142](../../../flutter-limitations.md#fl-142)).
- **A Cupertino form row's helper** (07, 08) is plain text after the field;
  the field needs `Semantics(label:, hint:)`, as it needs a label in F01
  ([FL-016](../../../flutter-limitations.md#fl-016)).
- **An obscured field is a plain text field on iOS until it is edited**
  (10), as FL-042 recorded; while it is being edited XCUITest reports a
  secure text field. What VoiceOver says during editing was not captured:
  the walk began on the next element.

TalkBack and VoiceOver on the web were not part of the probe; what they
say was recorded with the examples.
