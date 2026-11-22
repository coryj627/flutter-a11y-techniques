# Spec: S22 Semantics identifiers for testing

Status: Draft 1 (2026-11-15), written with the build. Eighth and last
technique of batch 1 ([plan](../plan.md)). Flutter pin: 3.47.5.

An identifier is a string a UI test finds an element by. It is not read to
anyone. This spec covers where to put one so that a test finds the control
itself, and so that adding it changes nothing a screen reader user gets. A
control's name is [S01 Accessible names](S01-accessible-names.md). Finding
widgets in widget tests (`find.byKey`) is a different thing and is not
covered: a `Key` never leaves the widget tree.

## 1. Rule

A control found by an identifier is one element that has the identifier,
the role, the name, and the action. The identifier is never the control's
name, and adding it does not change what assistive technology is given.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies | Applies | Applies |

`Semantics(identifier:)` is the node's resource id on Android (`By.res`),
`accessibilityIdentifier` on iOS, and the `flt-semantics-identifier`
attribute on the web.

## 3. WCAG 2.2 success criteria

None. This is a testing technique, and the source says so. Two of the bad
examples do fail a criterion, as a side effect of where the identifier was
put or of what it was used for:

| Criterion | Where |
| --- | --- |
| [4.1.2 Name, Role, Value](https://www.w3.org/TR/WCAG22/#name-role-value) | `bad-inside` on Android and iOS, and `bad-id-as-name` everywhere: a button with no name |

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | An identifier is a unique string that identifies an element for UI testing | [iOS Accessibility Identifier](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/AccessibilityIdentifier.md) ("specify a unique string identifier for UI Testing purposes"), [Apple: accessibilityIdentifier(_:)](https://developer.apple.com/documentation/swiftui/view/accessibilityidentifier(_:)) |
| R2 | It is not spoken to screen reader users | iOS Accessibility Identifier ("Accessibility Identifiers are not spoken to VoiceOver users") |
| R3 | It is not a substitute for a label: an element that needs a name gets a label | iOS Accessibility Identifier ("Don't use `.accessibilityIdentifier()` to try to label elements for assistive technology users") |
| R4 | Adding an identifier does not change the element's name, role, or actions | Project rule, from spike K2 ([plan](../plan.md)) and [FL-007](../flutter-limitations.md#fl-007). The sources assume it: on iOS a modifier does not restructure the element |

The inventory row's Android columns are empty, and its HTML column says
"`id`, `data-testid` equivalents". Neither attribute is what Flutter writes
on the web; the attribute is `flt-semantics-identifier`.

Flutter references for the mechanisms used:

- [`SemanticsProperties.identifier`](https://api.flutter.dev/flutter/semantics/SemanticsProperties/identifier.html)
- [`MergeSemantics`](https://api.flutter.dev/flutter/widgets/MergeSemantics-class.html)

## 5. Examples

Every example ends with a count of changes, which has an identifier of its
own (`s22-<slug>-count`), so a test can tell that a control worked.

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-merged` | Material | A "Save draft" button that a test finds by identifier | `MergeSemantics` around `Semantics(identifier:)` around `FilledButton`, written out | R1, R2, R4 |
| `good-cupertino` | Cupertino | The same on a Cupertino button | `TestId` (the same two widgets) around `CupertinoButton.filled` | R1, R2, R4 |
| `good-custom` | Widgets | The same on a button drawn by hand | `TestId` around the focus handling and `Semantics(button:, label:, onTap:)` | R1, R2, R4 |
| `good-field` | Material | A text field found by identifier that keeps its name | `TestId` around `TextField` | R1, R2, R3, R4 |

### Custom solutions

**Custom solution: not vetted by a real-world example.** `good-cupertino`
and `good-custom` are custom solutions. Each is tested here in isolation,
with screen-reader transcripts, but has not been built into a real app and
tested in a user journey. Do not treat them as vetted techniques.

The table is this technique's part of the register of custom solutions,
[custom-solutions.md](../custom-solutions.md).

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-merged` | `MergeSemantics` round `Semantics(identifier:)` round a `FilledButton`: the project's `TestId`, written out | `Semantics.identifier` | An identifier inside a button strips its name ([FL-007](../flutter-limitations.md#fl-007)) or stays on a node of its own ([FL-043](../flutter-limitations.md#fl-043)) | R1, R2, R4: iOS Accessibility Identifier, Apple: accessibilityIdentifier, Project rule | borderline: Two documented widgets and nothing that behaves; but the placement is the project's own rule for [FL-007](../flutter-limitations.md#fl-007) and [FL-043](../flutter-limitations.md#fl-043), the `TestId` that every example uses for its tests. |
| `good-cupertino` | An `Actions` for Enter on the web round the `CupertinoButton` | `CupertinoButton` | Enter on the web ([FL-002](../flutter-limitations.md#fl-002)) | R1, R2, R4: iOS Accessibility Identifier, Apple: accessibilityIdentifier, Project rule | custom |
| `good-custom` | A button drawn by hand: `Semantics(button: true, label:, onTap:)`, with focus, keys, and a focus ring of its own | None for a drawn control | none | R1, R2, R4: iOS Accessibility Identifier, Apple: accessibilityIdentifier, Project rule | custom |
| `good-field` | `TestId` round a `TextField` | `Semantics.identifier` | As `good-merged` | R1, R2, R3, R4: iOS Accessibility Identifier, Apple: accessibilityIdentifier, Project rule | borderline: As `good-merged`: the project's `TestId` round a framework widget. |

### Bad

| Slug | Defect | Violates | Fails |
| --- | --- | --- | --- |
| `bad-inside` | The identifier is around the text inside a `FilledButton`. On Android and iOS the button has no name and its text is a separate element; on the web the button keeps its name and the identifier is on an element inside it | R4 | 4.1.2 on Android and iOS |
| `bad-wrapper` | The identifier is around a `FilledButton` with no `MergeSemantics`. It is on an element of its own with no role, name, or action: around the button on web and Android, beside it on iOS. Nothing changes for a screen reader user; the test has not found the button | R1 (it identifies the wrong element) | — |
| `bad-id-as-name` | An icon button with an identifier and no name | R3 | 4.1.2 |
| `bad-duplicate` | Two buttons with the same identifier. Nothing changes for a screen reader user; a test cannot tell them apart | R1 | — |

Two of the four bad examples have no effect on a user. They are here
because the technique is about tests, and the defect is stated as what the
test gets.

## 6. Assertions by layer

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Good: guidelines in light and dark, 200% text, every identifier on the screen unique and in no label, value, hint, or tooltip. Buttons: the node with the identifier has the button flag, the name, and the tap action, and tap, the semantics action, Enter, and Space work. Bad: the identifier on a text node and a button with no label; the identifier on a node with no role, name, or action; a button that fails `labeledTapTargetGuideline`; two nodes with one identifier |
| L3 web | Buttons: exactly one element with the attribute, its role and accessible name, click, Enter, and Space. No identifier in the page's accessibility snapshot or in a naming attribute. Field: the attribute on the element around the `<input>`, which keeps its name. Bad: the attribute inside the button, around the button, on a button with no name, and on two elements (Playwright's strict mode refuses to click) |
| L3 Android | Buttons: one node with the resource id, the `Button` class, the description, found and clicked through `By.res`. No identifier in any description, text, hint text, tooltip, state description, or pane title. Bad: an unnamed `Button` whose child `View` has the id and the text; a `View` with the id whose child is the button; two buttons with one id |
| L3 iOS | Buttons: one element with the identifier, type `.button`, its label, found by `app.buttons[id]` and tapped. No identifier in any label or value. Bad: a static text with the identifier and one unnamed button; an `Other` element with the identifier, the same frame as the button and no button inside it; two buttons with one identifier |
| L4 TalkBack | What is read with focus on each control; words from the identifier must not be heard |
| L4 VoiceOver iOS | Every utterance between the "Example" heading and the change count, compared as a whole list, and no identifier in any utterance |
| L4 VoiceOver web | Every stop between the "Example" heading and the change count, in Chromium and WebKit, and no identifier at any stop |

## 7. What the build found (Flutter 3.47.5)

The probe that came first is in [evidence/probes/s22](../evidence/probes/s22/).

- **The identifier reaches all three platforms and none of them reads it.**
  Resource id on Android, `accessibilityIdentifier` on iOS,
  `flt-semantics-identifier` on the web.
- **Where it lands depends on what it is wrapped around.** Around a widget
  that is not a semantics container (`CupertinoButton`, `ListTile`,
  `TextField`, `Text`) a plain `Semantics(identifier:)` joins
  that widget's node. Around a Material button, which is a container, it
  stays on a node of its own
  ([FL-043](../flutter-limitations.md#fl-043)). `MergeSemantics` makes both
  cases one node, which is why `TestId` always uses it.
- **The stray node is in a different place on iOS**: an `Other` element
  beside the button with the same frame, not around it. "Find the
  identifier, then the button inside" works on web and Android and finds
  nothing on iOS.
- **An identifier inside a control splits it**
  ([FL-007](../flutter-limitations.md#fl-007), now asserted by tests). This
  is true of `FilledButton`, `OutlinedButton.icon`, `CupertinoButton`, and
  `ListTile` alike (probe, fixtures 02, 12, 20, 22). On Android and iOS the
  control is left with no name. On the web the control keeps its name,
  because a button's name is computed from its content.
- **Nothing stops two elements having the same identifier.** No error and
  no warning on any platform. Each tool does something different:
  Playwright refuses to act on the locator, and UI Automator's
  `findObject` takes the first. XCUITest's subscript was not tried; the
  test counts the matches.
- **A node with an identifier and nothing else is not a screen reader
  stop** on iOS (probe, fixtures 03, 11, 13).
- **On the web a text field's identifier is on the element around the
  `<input>`**, and the name is on the `<input>`. A test goes from one to
  the other.
- **What is heard**: every good example is read by its name and role and
  nothing else, on TalkBack, VoiceOver on iOS, and VoiceOver on the web.
  `bad-inside` is "Button", then "Save draft", on TalkBack and on iOS, and
  "Save draft button" on the web. `bad-wrapper` and `bad-duplicate` sound
  like the good example.
- **TalkBack guesses at the unnamed icon button**: "Button", then
  "Detected: Text, X". That is TalkBack's own description of the picture.
  It is not the identifier and it is not a name the app gave.

**Not done yet.** Appium and Maestro, which also read these identifiers,
were not tried. `find.bySemanticsIdentifier` in widget tests is not used by
this project's tests, which read the semantics tree directly. Whether
`aria-controls`, which the web engine resolves through identifiers, picks
the wrong element when two share one was read in the engine source
(`identifiersToIds` keeps the last one) and not tested; it goes to the
technique that first uses `controlsNodes`.
