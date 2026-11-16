# Spec: F08 Radio group

Status: Draft 1 (2026-11-16), written with the build. Second technique of
batch 2 ([plan](../plan.md)). Flutter pin: 3.47.5.

Radio buttons offer one choice from several. This spec covers the name,
role, and state of each button, the group and its name, and the keyboard.
A checkbox is [F07 Checkbox](F07-checkbox.md), and a switch is F09. A
segmented control, tabs, and a dropdown are other ways to offer one choice
and have their own entries. A radio item in a menu (`menuItemRadio`)
belongs to the menu technique. Target size is V13.

## 1. Rule

Each radio button and its visible label are one control. Assistive
technology is given its name, that it is one of a set of exclusive choices,
and whether it is the one chosen, and that stays true as the choice
changes. The buttons are in a group, and the question they answer is the
group's name.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies | Limitation | Applies |

iOS has no radio button control. Flutter exposes a radio button there as a
button with a selected state, and VoiceOver never says "radio button"
([FL-047](../flutter-limitations.md#fl-047)). There is no workaround
within the SDK. The chosen option is announced correctly.

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [4.1.2 Name, Role, Value](https://www.w3.org/TR/WCAG22/#name-role-value) | A radio button is a user interface component: its name and role can be programmatically determined, and its state can be set and is notified to assistive technology when it changes |
| [1.3.1 Info and Relationships](https://www.w3.org/TR/WCAG22/#info-and-relationships) | The label beside a button belongs to it, the buttons belong together, and the question above them belongs to all of them. Those relationships are shown visually and must be programmatically determinable |

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | Each radio button and its label are one element: the label names the button, and the whole row is the control | [Android Compose RadioButton Groups](https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/components/RadioButtonGroups.md) ("each `RadioButton` control have a programmatically associated label"), [MDN: input type=radio](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/input/radio) |
| R2 | Each has the radio role, and says whether it is checked | [APG Radio Group](https://www.w3.org/WAI/ARIA/apg/patterns/radio/) ("Each radio button element has role `radio`"; `aria-checked`), Android Compose RadioButton Groups (`role = Role.RadioButton`, `selected`), [iOS Radio Buttons](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/RadioButtons.md) (a selected trait, and a value that says "Radio button, checked") |
| R3 | The buttons are contained in a group with the radio group role | APG Radio Group ("The radio buttons are contained in or owned by an element with role `radiogroup`"), Android Compose RadioButton Groups (`Modifier.selectableGroup()`) |
| R4 | The group has a name that is the visible label of the group | APG Radio Group ("The `radiogroup` element has a visible label referenced by `aria-labelledby` or has a label specified with `aria-label`"), iOS Radio Buttons ("give the radio group a label for VoiceOver"), [MDN: fieldset](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/fieldset) (`<legend>`) |
| R5 | Tab moves focus into the group, to the checked button if there is one; arrow keys move focus and the choice to the next or previous button and wrap; Space checks the focused button | APG Radio Group, keyboard interaction |
| R6 | Where a button's label does not make sense without the question, the button's name carries the question | Android Compose RadioButton Groups ("make each radio button option contextually understandable when announced individually by a screen reader") |
| R7 | The control keeps a touch target of at least 48 by 48 | Android Compose RadioButton Groups (`Modifier.minimumInteractiveComponentSize()`) |

The iOS document says SwiftUI has no radio button and builds one from a
button with the button trait removed and a selected trait added. Flutter's
`RawRadio` does much the same on iOS, and keeps the button trait.

Flutter references for the mechanisms used:

- [`RadioGroup`](https://api.flutter.dev/flutter/widgets/RadioGroup-class.html)
- [`RadioListTile`](https://api.flutter.dev/flutter/material/RadioListTile-class.html)
- [`RawRadio`](https://api.flutter.dev/flutter/widgets/RawRadio-class.html)

Comparison bar: HTML `<input type="radio">` buttons with `<label>`s in a
`<fieldset>` with a `<legend>`.

## 5. Examples

Every example ends with a count of changes. Except in `good-context`, the
question is "Delivery speed", the options are "Standard", "Express", and
"Next day", and "Express" is chosen at the start.

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-group` | Material | Three radio buttons under a question | `RadioGroup` around `RadioListTile`s, inside `Semantics(container: true, explicitChildNodes: true, label:)`, with the visible question in `ExcludeSemantics` | R1 to R5, R7 |
| `good-cupertino` | Cupertino | The same with Cupertino buttons and visible text | `RadioGroup` around rows of `MergeSemantics` (through `TestId`), a `GestureDetector`, a `CupertinoRadio`, and a `Text` | R1 to R5, R7 |
| `good-custom` | Widgets | The same drawn by hand | `RadioGroup` around `RawRadio`s with a hand-drawn ring | R1 to R5, R7 |
| `good-context` | Material | "Are you at home?" with "Yes" and "No", named "Yes, I am at home" and "No, I am not at home" | `Text('Yes', semanticsLabel: 'Yes, I am at home')` as the tile's title | R6 |

### Bad

| Slug | Defect | Violates | Fails |
| --- | --- | --- | --- |
| `bad-unlabelled` | `Radio` buttons with `Text` beside them. The buttons have no names, and a tap on the text does nothing | R1 | 4.1.2, 1.3.1 |
| `bad-group-unlabelled` | The question is plain text above the group. The group has no name | R4 | 1.3.1 |
| `bad-no-state` | Hand-drawn radio buttons exposed as buttons. Nothing says which is chosen | R2 | 4.1.2 |
| `bad-checkbox-role` | Hand-drawn radio buttons exposed as checkboxes: the state is right and the role says several can be chosen | R2 | 4.1.2 |
| `bad-checked-only` | Hand-drawn radio buttons with `checked` and `inMutuallyExclusiveGroup` and nothing else. Right on Android and the web; on iOS no state is exposed ([FL-047](../flutter-limitations.md#fl-047)) | R2 | 4.1.2 on iOS |

## 6. Assertions by layer

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Every radio button: its label on one node, in an exclusive group, checked or not, not a toggle or a button, enabled, a tap action; a tap and the semantics action each choose one and clear the other; choosing the chosen one changes nothing. Grouped examples: Tab lands on the chosen option, the four arrow keys move the choice and wrap, and a tap on the text chooses. The question on a node whose one child has the radio group role and no label. With the platform set to iOS: the chosen option selected, the others with the hint "Not selected", and neither on `bad-checked-only`. Bad: no names; a group with no label; buttons with no state; checkboxes; no group. Guidelines in light and dark and 200% text for good examples |
| L3 web | Every radio button: role, accessible name, `aria-checked`, a click. Grouped: Tab to the chosen one, the arrow keys, and Tab out. The question as the name of a `group` around a `radiogroup` that has no name. Bad: radios with no name; a `radiogroup` with no name and no named group; buttons with no `aria-checked`; checkboxes; radios with no `radiogroup` |
| L3 Android | Every radio button: the `RadioButton` class, description, checkable, checked or not, and a click. The question on a `View` whose child is a `RadioGroup` with no description. Bad: `RadioButton`s with no description; the question as a sibling; `Button`s that are not checkable; `CheckBox`es; no `RadioGroup` |
| L3 iOS | Every radio button: type `.button` (FL-047), label, one selected, and a tap. The question as one `Other` element. Bad: buttons with no label; the question as static text; buttons none of which is selected (`bad-no-state` and `bad-checked-only`); switches |
| L4 TalkBack | What is read with focus on the question, an option that is not chosen, the one that is, and the first again after it is chosen |
| L4 VoiceOver iOS | Every utterance between the "Example" heading and the change count, compared as a whole list |
| L4 VoiceOver web | Every stop between the "Example" heading and the change count, in Chromium and WebKit |

## 7. What the build found (Flutter 3.47.5)

The probe that came first is in [evidence/probes/f08](../evidence/probes/f08/).

- **`RadioGroup` with `RadioListTile`, `CupertinoRadio`, or `RawRadio`
  gives the role, the state, and the keyboard on every platform.**
  `role="radio"` with `aria-checked` inside `role="radiogroup"` on the
  web, a checkable `RadioButton` inside a `RadioGroup` on Android. Tab
  lands on the chosen option, the arrow keys move the choice and wrap, and
  Tab leaves the group.
- **`RadioGroup` cannot be named**
  ([FL-046](../flutter-limitations.md#fl-046)). The question goes on a
  node around it. On the web that is a `group` named "Delivery speed"
  around an unnamed `radiogroup`; VoiceOver says "Delivery speed group"
  going in, "end of Delivery speed group" coming out, and counts the
  buttons ("1 of 3"). On Android and iOS the question is an element read
  before the buttons, which is also what `bad-group-unlabelled` sounds
  like there. The difference on those two is in the tree only.
- **On iOS a radio button is a button**
  ([FL-047](../flutter-limitations.md#fl-047)). Flutter's radio widgets
  add a selected state and a "Not selected" hint: "selected, Express,
  Button" and "Standard, Button, Not selected". VoiceOver never says
  "radio button".
- **A radio button built from `checked` and `inMutuallyExclusiveGroup`
  alone has no state on iOS** (FL-047): "Express, Button". It is right on
  Android and the web. `good-custom` uses `RawRadio` for this reason, and
  `bad-checked-only` shows the trap.
- **In a browser on an Apple device the same hint is an
  `aria-description`**, and VoiceOver reads it: "Standard Not selected
  radio button, 1 of 3". On other systems the attribute is not there. The
  web tree tests do not assert it for that reason.
- **TalkBack says no state for a radio button that is not chosen**
  ([FL-045](../flutter-limitations.md#fl-045)): "Standard, Radio button",
  and "checked, Express, Radio button" for the chosen one. It did not say
  a position in the set ("2 of 3"), which the Android source describes
  for Compose's `selectableGroup`.
- **Unnamed radio buttons hand their texts to the group.** In
  `bad-unlabelled` the three stray texts become the name of the radio
  group: VoiceOver on the web reads "Standard Express Next day radio
  group" and then three buttons with no names; VoiceOver on iOS reads the
  three texts as one stop.
- **`CupertinoRadio` has no list tile.** `good-cupertino` builds the row
  by hand. `MergeSemantics` joins the name; the tap on the text needs its
  own handler.
- **Short answers need the question in their names on Android and iOS**
  (`good-context`), because the question is not read with them there.
  `Text('Yes', semanticsLabel: 'Yes, I am at home')` keeps the visible
  text and starts the name with it.
- During one web VoiceOver capture a macOS notification ("Login Items…")
  was read in place of one stop. The recorder retries a failed walk, and
  the transcript says which walks needed one.

**Not done yet.** A disabled radio button is in the probe (fixture 09) and
not in an example. A group with nothing chosen at the start was not built.
What each screen reader says at the moment the choice changes is not
recorded. A native Android `RadioButton` was not compared with the Flutter
one for the missing "not checked". Whether the description "Not selected"
appears in a browser on iOS was not run; it is expected from the framework
source.
