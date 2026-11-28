# Spec: V01 Colour contrast

Status: Draft 1 (2026-11-28), written with the build. Wave 5, visual
preferences. Flutter pin: 3.47.5.

The contrast of text, and of the parts of a control that identify it and
its state, in every state, light and dark; and whether a state is shown by
colour alone. A user's request for more contrast is V02; the app's light
and dark themes as such are V03; focus indicators are
[V14](V14-focus-indicators.md), which measured them and is cited, not
repeated (section 8 says what is handed on).

## 1. Rule

Text and images of text have a contrast of at least 4.5:1 with what is
behind them (3:1 for large text). The parts of a control that are needed to
see it and its state have 3:1 against the colours next to them. A state, or
a difference between items, is never shown by colour alone. All three hold
in light and dark mode and in every state a control can be in.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies | Applies | Applies |

Every good example is Flutter's own widgets through their documented
parameters; none is a custom solution (section 5). Every colour cited here
was measured from rendered pixels: the widget tests' layer tree, Chromium's
screenshots, the Android emulator's, and the iOS simulator's, in light and
dark mode (section 6).

- **Android, applies.** Every example measured at rest, with keyboard focus
  from a registered keyboard, and with a finger held down until two
  screenshots agree, the first at 750 ms or later, in light and dark mode
  set with `cmd uimode night`. Hover was not measured: the emulator has no
  mouse the tests can drive.
- **iOS, applies.** Every example measured at rest and with keyboard focus
  by Tab, in light and dark mode set with `XCUIDevice.appearance`. A held
  press and a hover could not be measured: XCUITest's press returns only
  after the finger is lifted, and has no pointer.
- **Web, applies.** Every example measured at rest, focused, hovered,
  focused and hovered, and with a mouse button held 2 s and 4 s, in light
  and dark mode by `prefers-color-scheme`, in Chromium. With the theme's
  default ink splash, a mouse button held on a Material button or list
  tile takes its text under 4.5:1, in Chromium and in WebKit
  ([FL-515](../flutter-limitations.md#fl-515)); `good-material` and
  `good-selection` are under the theme with no splash, a documented
  parameter, which keeps every text at 4.5:1 or more (section 5).

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [1.4.3 Contrast (Minimum)](https://www.w3.org/TR/WCAG22/#contrast-minimum) | Every example has text: labels, placeholders, hints, a caption, titles |
| [1.4.11 Non-text Contrast](https://www.w3.org/TR/WCAG22/#non-text-contrast) | A field's edge, a checkbox's box and mark, a radio button's ring and dot, a button's outline |
| [1.4.1 Use of Color](https://www.w3.org/TR/WCAG22/#use-of-color) | Two examples show which of three views is chosen |

How each applies, as written, with its exceptions:

- **1.4.3.** 4.5:1, or 3:1 for large scale text, at least 18 point or 14
  point bold, which [Understanding 1.4.3](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html)
  gives as about 24 and 18.5 CSS pixels. No text in the examples is large:
  the largest is the caption, 16 logical pixels. The criterion applies to
  placeholder text (the Understanding document says so) and to text shown
  on hover or focus. Its exceptions: text in an inactive component (no
  example has one; a disabled control's text, measured in the probe at
  2.34:1 to 3.84:1, is excepted), incidental text, and logotypes (none
  here). The caption is not incidental: it names the picture. A pressed
  state is not excepted; it is measured as any other (section 5,
  Decisions). [F83](https://www.w3.org/WAI/WCAG22/Techniques/failures/F83)
  is the failure of text over a background image without enough contrast,
  which `bad-caption` is.
- **1.4.11.** 3:1 for the "visual information required to identify user
  interface components and states" against adjacent colours
  ([Understanding 1.4.11](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html)).
  A text field's edge is required when it is what shows where the field
  is: the Understanding document's failing example is a light grey input
  border. A button with text needs no boundary; its outline is measured
  but no verdict rests on it. The criterion does not compare a control's
  states with each other, and does not apply to inactive components. Its
  exception for appearance "determined by the user agent and not modified
  by the author" does not cover Flutter's widgets, on the reasoning of
  [V14's spec](V14-focus-indicators.md), section 3: Flutter draws them as
  part of the app, on every platform. Where the least contrasting part of
  a gradient decides, the lowest figure is used.
- **1.4.1.** Colour must not be "the only visual means" of showing a state
  or telling items apart. [Understanding 1.4.1](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html)
  counts a difference of lightness of 3:1 or more between the colours as a
  means besides hue. So `bad-colour-only` fails it: its chosen title
  differs from the others by hue and by 2.66:1 (light) or 1.32:1 (dark),
  and by nothing else that is drawn. `good-selection` passes: a radio
  button's dot is a shape. That the state reaches the screen reader in
  both (section 7) does not change the verdict: the criterion is about
  what is seen.

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | Text 4.5:1 against its background, 3:1 if large (18 point, or 14 point bold) | [iOS SwiftUI: Contrast](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/Contrast.md), Understanding 1.4.3 |
| R2 | Borders, icons, and controls 3:1 against adjacent colours; a text field's border meets it | iOS SwiftUI: Contrast (`.textFieldStyle(.roundedBorder)`), Understanding 1.4.11 |
| R3 | Semantic colours that adapt to light and dark mode rather than fixed ones, and checked in both | iOS SwiftUI: Contrast (`.primary`, `.secondary`; "Color.black or Color.white" do not adapt) |
| R4 | Placeholder text meets R1 | Understanding 1.4.3 |
| R5 | Text over a picture keeps R1 wherever the picture is under it | [F83](https://www.w3.org/WAI/WCAG22/Techniques/failures/F83), Understanding 1.4.11 ("choose the least contrasting area") |
| R6 | A state is shown by more than colour, or by a lightness difference of 3:1 | Understanding 1.4.1 |
| R7 | Every state of a control keeps R1 and R2: focused, hovered, pressed, selected | Understanding 1.4.3 (text on hover or focus), Understanding 1.4.11 ("must not lose contrast with the adjacent colors") |

The iOS reference document says that `.secondary` meets 4.5:1 "in most
configurations". Its Flutter counterpart, `CupertinoColors.secondaryLabel`,
was measured at 3.38:1 on this app's light page
([FL-517](../flutter-limitations.md#fl-517)). The reference does not cover
placeholders, disabled controls, states, or colour alone; R4 to R7 come
from the Understanding documents. The reference repositories have no
Android document for this entry.

Flutter references for the mechanisms used:

- [`ColorScheme.fromSeed`](https://api.flutter.dev/flutter/material/ColorScheme/ColorScheme.fromSeed.html), through `ThemeData(colorSchemeSeed:)`, and its roles; [`ColorScheme.outlineVariant`](https://api.flutter.dev/flutter/material/ColorScheme/outlineVariant.html), "for decorative elements"
- [`InputDecoration.floatingLabelBehavior`](https://api.flutter.dev/flutter/material/InputDecoration/floatingLabelBehavior.html), `hintMaxLines`
- [`CupertinoTextField.placeholderStyle`](https://api.flutter.dev/flutter/cupertino/CupertinoTextField/placeholderStyle.html) and [`decoration`](https://api.flutter.dev/flutter/cupertino/CupertinoTextField/decoration.html), with [`CupertinoDynamicColor`](https://api.flutter.dev/flutter/cupertino/CupertinoDynamicColor/highContrastColor.html) colours
- `CupertinoButton.pressedOpacity`
- [`ThemeData.splashFactory`](https://api.flutter.dev/flutter/material/ThemeData/splashFactory.html) and [`NoSplash.splashFactory`](https://api.flutter.dev/flutter/material/NoSplash/splashFactory-constant.html)
- [`GridTileBar.backgroundColor`](https://api.flutter.dev/flutter/material/GridTileBar/backgroundColor.html)
- [`RadioListTile`](https://api.flutter.dev/flutter/material/RadioListTile-class.html) in a `RadioGroup`; [`ListTile.selected`](https://api.flutter.dev/flutter/material/ListTile/selected.html)

## 5. Examples

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-material` | Material | A line of body text, an outlined field "Email" with its hint "Required" shown at rest, a checkbox "Send me updates", and a button "Send", at the theme's colours | `TextField(decoration: InputDecoration(border: OutlineInputBorder(), floatingLabelBehavior: always, hintMaxLines: 2))`, `CheckboxListTile`, `OutlinedButton`; colours from the app's `colorSchemeSeed`; under `Theme(data: ….copyWith(splashFactory: NoSplash.splashFactory))` (FL-515) | R1 to R4, R7 |
| `good-cupertino` | Cupertino | A field "Email", with a label above it, its placeholder "Required" and its edge in a stronger grey, and a filled button "Send" | `CupertinoTextField(placeholderStyle:, decoration:)` with `systemGrey`'s high-contrast colours, #6C6C70 and #AEAEB2, as one `CupertinoDynamicColor`; `CupertinoButton.filled(pressedOpacity: 0.9)` | R1 to R4, R7 |
| `good-caption` | Material | A picture, pale at the left and dark at the right, with the caption "Harbour" on a bar | `GridTile` with `GridTileBar(backgroundColor: Colors.black54)` | R1, R5 |
| `good-selection` | Material | A choice of view, Day, Week, or Month, Week chosen | `RadioListTile`s in a `RadioGroup`: the chosen radio button has a dot; under the theme with no splash, as `good-material` | R6, R7 |

The `OutlinedButton` in `good-material` is not a `FilledButton` because a
`FilledButton`'s text is under 4.5:1 with focus and a hover in light mode
([FL-253](../flutter-limitations.md#fl-253)). The hint is shown at rest so
that every layer can measure it without focusing the field (on Android,
focusing a field can bring up the soft keyboard over the example), and
`hintMaxLines: 2` lets it wrap at 200% text rather than be cut.

No good example is a custom solution: each is a framework widget at its
defaults or with its own documented parameters, and nothing is built. The
register's rows, with what each fills, are in
[custom-solutions.md](../custom-solutions.md#v01-colour-contrast).

### Bad

| Slug | Defect | Violates | Fails |
| --- | --- | --- | --- |
| `bad-cupertino-placeholder` | `good-cupertino`'s field with the default placeholder colour, `CupertinoColors.placeholderText`: #C5C5C7 on white, 1.72:1; #464649 on black, 2.23:1 ([FL-510](../flutter-limitations.md#fl-510)) | R4 | 1.4.3, all platforms, light and dark |
| `bad-caption` | `good-caption` with the bar at its default, no background: the caption #E6E0E9 lies on the pale part of the picture, 1.33:1 to 1.35:1 ([FL-512](../flutter-limitations.md#fl-512)) | R5 | 1.4.3, all platforms, light and dark |
| `bad-colour-only` | The same choice as three `ListTile`s with `selected`: the chosen title is `primary` and the others `onSurface`, 2.66:1 apart in light mode and 1.32:1 in dark, and nothing else is drawn ([FL-513](../flutter-limitations.md#fl-513)) | R6 | 1.4.1, all platforms, light and dark |
| `bad-faint-edge` | An outlined field whose edge is `outlineVariant`, the scheme's role for decorative lines: 1.62:1 against the page in light mode, 1.99:1 in dark. With focus its edge turns `primary`, 6.12:1 and 10.90:1 | R2 | 1.4.11, all platforms, light and dark |

### Decisions

The principal's, made in review on 2026-11-28 (the owner may overrule):

1. **A held press is held to 1.4.3**, as every state is: the label is
   still text the user reads while pressing.
2. **FL-515: the documented parameter, not a limitation.** With the
   theme's default ink splash, a mouse button held on `good-material`'s
   button and tile and on `good-selection`'s tiles took their texts to
   4.19:1 ("Send", light) and 4.25:1 (the tile titles, dark) in Chromium
   and WebKit, at 2 s and 4 s. Measured in probe round 3, each layer
   turned off in turn: the splash, drawn over the pressed highlight and
   the hover tint, is what takes them under (FL-515 gives every figure).
   `ThemeData.splashFactory: NoSplash.splashFactory` round the two
   examples (`WithoutSplash`) keeps them at 4.79:1 and more ("Send",
   light) and 7.07:1 and more (the titles, dark) in both browsers; the
   press is still shown by its highlight. The web is therefore applies,
   and FL-515 stays as the default's gap with that workaround.
3. **`pressedOpacity: 0.9` in `good-cupertino` stays.** It is
   `CupertinoButton`'s documented parameter, and the value is the
   example's own choice: there is no source for it, and any value whose
   measured pressed ratio is 4.5:1 or more would serve. At 0.9 the text is
   5.14:1 (light) and 6.66:1 (dark) while pressed in the widget tests, and
   5.13:1 and 6.65:1 on the web with a mouse button held 2 s and 4 s
   (`web_pressed_without_splash.txt`); Android asserts it 4.5:1 or more
   with a finger held until steady, and its figures are in the test's log,
   which the evidence run does not keep; 0.85 sits on the threshold, 4.54:1 in light mode
   (computed from the colours, not measured). The default, 0.4, is 1.88:1
   and 2.42:1 ([FL-514](../flutter-limitations.md#fl-514)), measured in
   the widget tests only: the default's press is not measured on a
   device.
4. **`good-cupertino`'s greys stay**, the example's choice among
   `CupertinoColors`' documented colours: `systemGrey`'s high-contrast
   colours, #6C6C70 and #AEAEB2. Measured on every layer: the placeholder
   5.23:1 on the field's white and 9.50:1 on its black; the edge 4.97:1
   against the page and 5.23:1 against the field in light mode, 8.39:1 and
   9.50:1 in dark. `secondaryLabel` and its high-contrast colour do not
   reach 4.5:1 in light mode (3.38:1 and 4.10:1 to 4.16:1 on the page;
   [FL-517](../flutter-limitations.md#fl-517)).
5. **C02's `good-toggle-buttons`** is not V01's to change: it is handed on
   as a question for the owner (section 8).

### Not built

- A bad example of body text in a weak colour (`Colors.grey`, 2.55:1 on
  the light page; `outline` as text, 4.27:1): the defect is the author's
  colour, and `bad-cupertino-placeholder` and `bad-caption` show 1.4.3
  failing already. The probe's figures for every role as text are in
  section 7.
- `CupertinoSwitch` and `CupertinoListTile` with their defaults
  ([FL-516](../flutter-limitations.md#fl-516),
  [FL-517](../flutter-limitations.md#fl-517)): measured in the probe,
  not built, to keep to one defect a bad example and to what the examples
  can show on every layer.
- A widgets-layer example: the widgets layer has no controls of its own
  with colours to measure; its `Text` takes its colour from the
  `DefaultTextStyle` the Material or Cupertino theme gives it.
- Focus indicators: [V14](V14-focus-indicators.md).

## 6. Assertions by layer

### The measures

Every layer implements the same three measures, in its own test file
(Dart, JavaScript, Kotlin, Swift), on its own screenshots: the widget
tests' layer tree at a device pixel ratio of 3, Chromium at a device scale
factor of 3, the Android emulator at its own density (2.625, and 1.0 at
CI's size), and the iOS simulator at 3, drawn into sRGB. Contrast is WCAG's
relative-luminance ratio, checked on known pairs (21, 4.54, 3.03, 1).

1. **Text.** The text's paragraph box, in screenshot pixels. For each
   column, the pixels 6 above and 6 below the box are the colours round the
   text there. A pixel in the box that differs from both by more than 12 in
   some channel is a text pixel. The text's colour is the commonest text
   pixel, exactly. The contrast is the lowest, over every column that has
   a pixel of exactly that colour, of the text colour against either colour
   round it there. More than 20 text pixels are required.
2. **Edge.** From a pixel outside a control, a straight walk into it: the
   edge is the pixel on the way that contrasts most with the first; it is
   taken against the first (outside) and the last (inside). On the devices
   and the web, the first pixel must be the page's colour, or the test
   fails.
3. **Marks.** The pixels of an area that are 3:1 or more against a colour:
   a checkbox's mark on its fill, a radio button's dot on the page.

What these measures leave out, and what each gives up:

- The text measure ignores text pixels within 12 of a colour round the
  text: the faintest anti-aliasing. It cannot see a text whose colour is
  within 12 of its background (no example's is).
- It takes the commonest text pixel as the text's colour. On a device the
  letters' strokes have cores of that exact colour; a text drawn so thin or
  so blended that no colour is commonest among its pixels would be
  measured by its anti-aliasing, which lowers the ratio, so leans to
  failing. The logs give, for each text, how many of its pixels were
  exactly the text colour.
- It skips columns with no pixel of exactly the text colour: the
  anti-aliased edges of letters. A background that changes under those
  columns only is not seen.
- It takes the background 6 pixels above and below the box. A shape that
  lies there is taken as the background; each layer's logs give the colour
  each text was taken against, and none is another shape's.
- On the web, Android, and iOS, a text that has no element of its own (a
  field's label and hint, a tile's title, a button's text, which are
  merged into the control's node) has its box found from the pixels at
  rest: the pixels of a search area that differ from its commonest colour
  by more than 12. On Android and iOS the box is grown by 2 pixels; on the
  web it is not (its rows 6 above and below are outside the letters either
  way). The search areas are each layer's, from the control's rectangle
  and the probe's geometry (the layers' file headers name them). The box
  is kept for the other states, after checking the control did not move.
- A state is measured once it has stopped moving: the widget tests settle
  the frame (`pumpAndSettle`, or 300 ms held for a press); the web takes
  two screenshots 250 ms apart that agree in every pixel of what is
  measured; Android holds a press until two screenshots agree, the first
  at 750 ms or later (earlier ones are logged, not judged), and settles
  other states to within a caret's area; iOS settles to within 0.5% of the
  region, and measures a focused field's texts in two screenshots 600 ms
  apart that must agree, as its caret blinks. Each state is set and shown
  set by a witness other than the pixels measured (a focus flag, the tree,
  Flutter's mouse cursor on the web, the page's colour for the mode,
  pixels changed elsewhere than the text), and undone and shown undone.
- Colours: the widget tests, the web, and iOS compare colours exactly;
  Android within 2 in each channel.
- The edge measure walks one line, at the control's vertical middle. A
  faint stretch of edge elsewhere is not seen; a mark on the line (a
  letter) would be taken as the edge, which leans to passing, so each
  walk is placed where no text lies.
- The marks measure counts pixels; it does not find a shape. The dot is
  told from the ring by area: the middle of the radio button only.

### By layer

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Good, light and dark: the four guidelines; at 200% text on 320 by 640, no overflow and no text cut short, for every example. Names and roles: the fields (the Cupertino field's name is "Email" and its placeholder, `Email\nRequired`), the checkbox, the button, the caption as one node, `good-selection`'s three radio buttons in a group with Week checked and a tap on Day checking Day, `bad-colour-only`'s three buttons with Week selected and a tap selecting Day. Pixels, light and dark: every text of `good-material` 4.5:1 or more at rest, focused, hovered, focused and hovered, pressed 300 ms by a finger, and held 2 s by a mouse; its field's edge, checkbox, and outline 3:1 or more; checked, the fill 3:1 against the page and the mark 3:1 on the fill. `good-cupertino`: label, placeholder, and "Send" 4.5:1 or more, the edge 3:1 against the page and the field; "Send" focused, hovered, and pressed 4.5:1 or more. `good-caption` 4.5:1 or more over the whole picture. `good-selection`: titles 4.5:1, rings 3:1, a dot in Week's radio only, moving to Day with a tap. Each bad example's defect, under its threshold and over 1:1, with its positive control (`bad-faint-edge` with focus 3:1 or more; `bad-caption`'s colour 4.5:1 or more against the picture's dark end; `bad-colour-only`'s colour moving with a tap; nothing else drawn on its tiles). FL-511 and FL-514, each widget on its own, light and dark |
| L3 web | Role, name, and state of every control by Chromium's accessibility tree; the Cupertino field named "Email Required"; `good-selection` a radio group with Week checked, a click checking Day; `bad-colour-only` three buttons with no selected, pressed, or checked state (Flutter writes `aria-current` on the chosen one). The same pixel assertions on Chromium screenshots at a scale factor of 3, light and dark by `prefers-color-scheme` (the page colour and the media query checked first, light put back after), states by Tab, mouse hover (witnessed by Flutter's mouse cursor on the page), both, and a mouse button held 2 s and 4 s, the two readings required to agree, every text 4.5:1 or more; each state undone (focus back to Back, the mouse moved off before it is let go, so no click) and shown undone. The VoiceOver judge regressions and the transcript re-judge (section 7) |
| L3 Android | Class, name, and checked or selected state of every control; a tap moving each choice. The same pixel assertions on `UiAutomation.takeScreenshot`, light and dark by `cmd uimode night` (asserted, put back, asserted), focus from a `uinput` keyboard (FL-433), a finger held by injected events until two screenshots agree, the first at 750 ms or later, each press witnessed by pixels changed outside the measured text or by the control's state after the lift, and the button's press shown undone. TalkBack walked in light mode, set and checked. Run at the emulator's own size and at 320 by 640 at 160 dpi |
| L3 iOS | Type and label of every element; a tap moving each choice (`isSelected`). The same pixel assertions on `XCUIScreen` screenshots in sRGB, light and dark by `XCUIDevice.appearance` (the page colour checked, put back, checked), focus by Tab with no modifier, witnessed by `hasKeyboardFocus` for a field and by pixels changed in the control outside its texts for the others, and shown gone after the next Tab; a checkbox and a choice put back by a tap and checked. No held press (XCUITest cannot hold one and take a screenshot), no hover |
| L4 TalkBack | Each text and control of each example in turn, every row a whole utterance (`== A / B`), each walk judged whole (`walk_strictly`) |
| L4 VoiceOver iOS | Every utterance from the top of the screen to its end (V01Walk, S16's walk): the screen's own title, description, and defect, then exactly the example's stops |
| L4 VoiceOver web | S16's walk and judge (`web_tests/vo/v01_vo_walks.js`), every stop judged; the transcript re-judged by the tree spec from its rows |

A colour is drawn, not spoken: the screen-reader layers record that the
bad examples read as their good counterparts, and that
`bad-colour-only`'s chosen tile reaches the screen reader as selected
while only a colour shows it on the screen.

## 7. What the build found (Flutter 3.47.5)

The probe that came first is in
[evidence/probes/v01](../evidence/probes/v01/README.md), with its fixtures,
its raw output, and the analyser. Every figure here is read from pixels;
"read in the source" marks what was not.

- **Flutter draws the same colours on every platform.** Every solid colour
  that both the widget tests and Chromium found in a probe fixture was the
  same in both, to the last digit, but for the translucent action sheet
  (c14), whose blurred fill differed by one in a channel; the fixtures
  analysed on Android and iOS gave the same colours again
  (`devices_round1.txt`), and so did the examples on every layer (the
  layers' logs). Chromium and the devices find fewer solid colours in
  text, whose real letters are anti-aliased where the test font's are
  solid boxes. The ratios below hold on every layer to within
  0.1, except where a layer is named.
- **The Material scheme from the app's seed, as text on its page**
  (`surface`, #FBF8FF light, #121318 dark): `onSurface` 16.30:1 and
  14.35:1, `onSurfaceVariant` 8.88:1 and 10.89:1, `primary` 6.12:1 and
  10.90:1, `error` 6.14:1 and 10.93:1, `outline` 4.27:1 and 5.87:1,
  `outlineVariant` 1.62:1 and 1.99:1 (probe t1 to t8). So `outline` is
  enough for an edge and not for text in light mode, and `outlineVariant`
  is enough for neither: the API documents it as "for decorative
  elements".
- **Material's widgets at their defaults** (probe m1 to m35): every text of
  every enabled control 4.5:1 or more, light and dark: a field's label and
  hint `onSurfaceVariant`, its edge `outline` (4.27:1, 5.87:1), focused
  `primary`; the error text `error`; a checkbox's border
  `onSurfaceVariant`; a filled button's text on `primary`. Disabled text is
  2.34:1 to 3.84:1, excepted. With states: focus and hover tints lower a
  text's contrast. A `FilledButton` with focus and a hover is 4.28:1 in
  light mode (FL-253), and a selected `ListTile` with focus and a hover
  4.25:1 (probe m21, widget tests; FL-253); every other state measured
  stays over 4.5:1 in the widget tests. On the web, in Chromium and
  WebKit, a mouse button held on an `OutlinedButton` or a list tile with
  the default ink splash takes its text to 4.19:1 (the button, light) and
  4.25:1 (the tiles, dark) once the splash has spread; with the theme's
  `splashFactory: NoSplash.splashFactory` 4.79:1 and 7.07:1 or more
  (FL-515, probe round 3). The good examples are under that theme.
- **Material shows some states by colour alone.** A selected `ListTile`
  colours its title `primary`, 2.66:1 against the others' `onSurface` in
  light mode and 1.32:1 in dark, and draws nothing else (FL-513,
  `bad-colour-only`). `ToggleButtons`' chosen button is a fill of 1.19:1
  against the page and a text colour 1.81:1 from the others' (probe m25).
  A `FilterChip`, a `ChoiceChip`, and a `SegmentedButton` draw a check
  mark; a `TabBar` an underline; a `Radio` a dot; a `Checkbox` a mark
  (probe m16, m22 to m26).
- **Cupertino's defaults, in the app's theme** (probe c1 to c17, k1 to
  k5; Cupertino's primary colour here is the Material theme's): the
  placeholder `placeholderText` 1.72:1 on white and 2.23:1 on black
  (FL-510); the field's hairline edge 1.25:1 against the page and 1.32:1
  against the field in light mode, 1.31:1 and 1.49:1 in dark (FL-511); a
  `CupertinoButton.filled` 6.44:1 and 7.71:1 at rest and 1.88:1 and
  2.42:1 while pressed (FL-514); a `CupertinoSwitch` off, track 1.20:1 and
  thumb 1.05:1 against the page in light mode, on, track `systemGreen`
  2.11:1 (FL-516); `secondaryLabel` text 3.38:1 in light mode, which a
  `CupertinoListTile`'s subtitle uses, and `tertiaryLabel` 1.71:1
  (FL-517); a `CupertinoActionSheet`'s title and message 3.40:1 in light
  mode (FL-441). Under a default `CupertinoThemeData`, whose primary is
  `systemBlue`, a `CupertinoButton`'s text is 3.82:1 on the page and a
  filled one's white text 4.02:1 on its fill (FL-242).
- **A nested `Theme` passes the app's Cupertino theme on unchanged.** The
  probe's first round put a dark `Theme` inside a light `MaterialApp`, and
  the Cupertino fixtures were drawn light (`flutter_test_round1.txt`).
  Read in the source: `Theme` passes on the `CupertinoTheme` above it
  before deriving one from its own data (`material/theme.dart`,
  `_inheritedCupertinoThemeData`). The app's own dark mode is not
  affected: `MaterialApp` builds the top `Theme` from `darkTheme`. Handed
  to V03 (section 8).
- **Text over a picture** (probe g1 to g4, `good-caption`,
  `bad-caption`): `GridTileBar` draws its title #E6E0E9 with no background
  by default, 1.33:1 to 1.35:1 over the picture's pale end (FL-512); with
  `backgroundColor: Colors.black54`, 5.28:1 to 5.43:1 over the whole
  picture.
- **What the examples measured**, by layer (logs in the probe folder:
  `widget_tests.txt`, `web_tests.txt`, `android_tests.txt` and
  `android_tests_320x640.txt`, `ios_tests.txt`):

  | Example | Widget | Web | Android | iOS |
  | --- | --- | --- | --- | --- |
  | `good-material`, texts at rest (light / dark) | 6.12 to 16.30 / 10.89 to 14.35 | same | same | same |
  | `good-material`, edges | 4.27, 8.88, 4.27 / 5.87, 10.89, 5.87 | same | same | same |
  | `good-cupertino`, placeholder | 5.23 / 9.50 | 5.23 / 9.50 | 5.23 / 9.50 | 5.23 / 9.50 |
  | `good-caption` | 5.33 | 5.33 | 5.33 (5.43 at 320 by 640) | 5.28 |
  | `bad-cupertino-placeholder` | 1.72 / 2.23 | 1.72 / 2.23 | 1.72 / 2.23 | 1.72 / 2.23 |
  | `bad-caption` | 1.34 | 1.35 | 1.35 (1.39) | 1.33 |
  | `bad-colour-only`, chosen against others | 2.66 / 1.32 | 2.66 / 1.32 | 2.66 / 1.32 | 2.66 / 1.32 |
  | `bad-faint-edge`, at rest; focused | 1.62, 6.12 / 1.99, 10.90 | same | same | same |

- **What reaches the screen reader.** `bad-colour-only`'s chosen tile is
  "selected" to TalkBack ("selected. / Week / Button") and VoiceOver on iOS
  ("selected Week Button"). In Chromium's accessibility tree the three
  tiles are buttons with no selected, pressed, or checked state; Flutter
  writes `aria-current="true"` on the chosen one, which the tree read over
  the DevTools protocol does not show. The Material field's hint is not
  spoken by TalkBack or VoiceOver on iOS, and is not in Chromium's
  accessible name; the Cupertino field's placeholder is part of its name,
  "Email Required", on every platform.
- **The shared iOS simulator during the build** (notes, not findings).
  From about 05:07 on 2026-11-28 the simulator drew no dark mode: the
  appearance set by `XCUIDevice.appearance`, by `simctl ui appearance
  dark`, and by a tap on Dark in Settings each read back dark, and
  Settings and the app stayed light; at 04:39 the same test had drawn
  dark. At 06:38 it was shut down and booted again, under the device
  lock, and dark mode was drawn again, also after a VoiceOver walk. The
  cause was not found. While looking, `simctl openurl` left two "Open in
  'Flutter A11Y Techniques'?" dialogs on the home screen; a later run
  under the lock tapped Cancel on both, and a screenshot showed the home
  screen clear. The appearance was put back to light, and checked, after
  every run. The iOS tests fail, measuring nothing, if the page does not
  show the mode.

**Not done yet.** Hover on Android and iOS; a held press on iOS; the
default ink splash held on Android (the examples are without it; the
probe's Android presses were short); the colour schemes of other seeds; forced
colours and Windows High Contrast (V02); the examples in WebKit and Firefox (probe round 3 measured FL-515 in WebKit); text over a
real photograph (the picture is a gradient so that every layer measures
the same pixels); every other Material and Cupertino widget in every
state on the devices (the probe measured them in the widget tests and
Chromium, and at rest on Android and iOS).

## 8. What is handed on

- **V02 High contrast preference**: `CupertinoDynamicColor`'s
  high-contrast variants, which `good-cupertino` uses by hand, are what
  Flutter resolves to when the device asks for more contrast; whether
  they do on each platform was not measured. `secondaryLabel`'s
  high-contrast colour is still 4.10:1 on the light page (FL-517).
- **V03 Dark and light themes**: a nested `Theme` passes the app's
  Cupertino theme on unchanged, so Cupertino widgets under a nested dark
  `Theme` keep the app's brightness (section 7, read in the source and
  seen in the probe's first round).
- **C02 Toggle button**: `ToggleButtons` shows its chosen button by
  colour alone (FL-513).
- **S14 Values and state descriptions**: on the web a selected `ListTile`
  is a button with `aria-current`, and no selected state in Chromium's
  tree.
- **Wave 8, navigation**: `NavigationBar`'s chosen destination is a pill
  of 1.22:1 against the bar, with label colours 1.8:1 apart (probe m27);
  not judged here.
