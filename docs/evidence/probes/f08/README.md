# F08 probe: radio groups

Run on 2026-11-16, Flutter 3.47.5, before the F08 examples were written. The
fixture is `probe.dart.txt` (a second entry point, not part of the app).
Every fixture's label starts with its number ("r01 Small"), and the second
option of each pair is the chosen one.

On iOS every radio button is a `Button`. "Selected" is the element's
selected state in the XCUITest tree.

| # | Fixture | Web (Chromium and WebKit DOM, on macOS) | Android (`uiautomator dump`) | iOS (XCUITest tree, VoiceOver) |
| --- | --- | --- | --- | --- |
| 01 | `RadioGroup` with two `RadioListTile`s | `role="radiogroup"` with no name; `role="radio"` with `aria-checked`; the unchosen one has `aria-description="Not selected"` | `RadioGroup` with no description; two checkable `RadioButton`s, one checked | two buttons, one selected; "r01 Small Button Not selected", "selected r01 Large Button" |
| 02 | `Semantics(label:)` around a `RadioGroup` | `role="group"` named by the label, around the `radiogroup` | a `View` with the label, around the `RadioGroup` | an `Other` with the label, read first, then as 01 |
| 03 | `Semantics(container: true, explicitChildNodes: true, label:)` around a `RadioGroup` | as 02 | as 02 | as 02 |
| 04 | the same with `role: SemanticsRole.radioGroup` | a named `radiogroup` around an unnamed `radiogroup` | a `RadioGroup` with the label around a `RadioGroup` | as 02 |
| 05 | `Radio` beside `Text` in a `Row`, twice, in a `RadioGroup` | `radiogroup` named "r05 Small r05 Large"; two radios with no name | `RadioGroup` whose description is the two texts; two `RadioButton`s with no description | the texts as one stop, then "Not selected Button" and "selected Button" |
| 06 | `MergeSemantics` around `CupertinoRadio` and `Text` | as 01 | as 01 | as 01 |
| 07 | `Semantics(checked:, inMutuallyExclusiveGroup: true, enabled: true, label:, onTap:)` | `role="radio"` with `aria-checked`, no description, no `radiogroup` | `RadioButton`s, one checked, no `RadioGroup` | two buttons, neither selected; "r07 Small Button", "r07 Large Button" |
| 08 | the same with `selected:` | as 07 | as 07, and the chosen one is also selected | the chosen one selected; "r08 Small Button", "selected r08 Large Button" |
| 09 | `RadioListTile(enabled: false)` | `aria-disabled="true"`, state kept | not enabled, state kept | disabled; "r09 Small dimmed Button Not selected" |
| 10 | `Semantics(button: true, label:, onTap:)` | `role="button"` | `Button` | button |
| 11 | a `Text` above a `RadioGroup` | text, then the unnamed `radiogroup` | a `View`, then the `RadioGroup` | static text, then as 01 |

## Second probe: naming the group from inside

`probe2.dart.txt`, run the same day after a review pointed out that the
first probe had only tried labels outside the group.

| # | Fixture | Web | Android | iOS |
| --- | --- | --- | --- | --- |
| 12 | a `Text` with the question inside the `RadioGroup`, before the tiles | `role="radiogroup"` named by the text; the two radios are its only children | `RadioGroup` with the text as its description | an `Other` with the text, then the two buttons |
| 13 | `Semantics(label:)` inside the `RadioGroup`, around the tiles | as 12 | as 12 | as 12; "r13 Size", then the buttons |
| 14 | the same with the visible question in `ExcludeSemantics` | as 12 | as 12 | as 12 |
| 15 | `Semantics(header: true)` around the question, inside the group | `radiogroup` with no name; inside it a `<header>` with the label, with the radios inside the header | `RadioGroup` with the text as its description | as 12 |

So the group can be named, and the simplest way is 12: the visible
question as plain text inside the group.

## What it shows

- **The SDK's radio widgets are right on the web and Android** with no
  extra work (01, 06).
- **`RadioGroup` has no label parameter and no name by default** (01). A
  label around it lands on a node of its own (02, 03), and giving that
  node the radio group role nests two radio groups (04). Text inside the
  group names it (12 to 14).
- **iOS has no radio button.** `RawRadio` adds a selected state and a
  "Not selected" hint there (01); a node built from `checked` and
  `inMutuallyExclusiveGroup` alone has no state at all (07), and adding
  `selected:` gives the chosen one its state (08).
- **The "Not selected" hint reaches the web too** as `aria-description`
  when the browser is on macOS (01).
- **Unjoined texts become the group's name** (05).
- **A disabled radio button** keeps its state and is marked disabled on
  all three (09).

The VoiceOver walk on iOS stopped moving at fixture 09, at the bottom of
the first screen. TalkBack and VoiceOver on the web were not part of the
probe; what they say was recorded with the examples.
