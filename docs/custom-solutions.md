# Custom solutions

The register of good examples that are custom solutions, and of the good
examples that were looked at and are not.

## The rule

A technique does not invent a mechanism or a solution. Flutter's own widget
for a pattern is the source material; where it falls short, that is recorded
as a Flutter limitation in [flutter-limitations.md](flutter-limitations.md).

Work already merged built some good examples by hand all the same. The
owner decided on 2026-11-21 to keep them, flagged: each carries this label,
in the app, in the Widgetbook, and in its technique doc and spec.

> Custom solution: not vetted by a real-world example. It is tested here in isolation, with screen-reader transcripts, but has not been built into a real app and tested in a user journey. Do not treat it as a vetted technique.

They are backed by this repository's tests and screen-reader transcripts,
which is a good start. Until one is built into a real app and tested in a
user journey, it cannot be called a vetted technique. A hand-built solution
kept from now on is flagged in the same way and entered here.

## How each example was judged

- **Custom**: the example assembles by hand a control or a mechanism that a
  Flutter widget for the pattern would otherwise provide, or that no Flutter
  widget provides: its own role, state, focus, activation, keys, overlay, or
  announcement, from `Semantics`, `FocusableActionDetector`,
  `GestureDetector`, `Actions`, `Shortcuts`, and the like, or a workaround of
  the project's own design for a limitation. A Material or Cupertino widget
  wrapped in such machinery counts, even where the machinery only adds one
  key: an `Actions` that makes Enter work on a `CupertinoButton` on the web
  ([FL-002](flutter-limitations.md#fl-002)) is a workaround of the project's own.
- **Not custom**: a Flutter widget used through its own documented
  parameters, or a documented accessibility property applied the way its
  API documentation describes, where nothing is built. A name, a hint, or an
  exclusion given with `Semantics(label:)`, `Semantics(hint:)`,
  `semanticsLabel`, or `ExcludeSemantics` is in this group, also where it
  fills a gap such as a Cupertino field's missing label ([FL-016](flutter-limitations.md#fl-016)): the
  widget keeps its own role and behaviour, and only text is added.
- **Borderline**: listed with the reasoning, and not flagged until it is
  decided.

`TestId` (`lib/catalog/test_id.dart`), which every example uses so that the
tests can find it, is not counted, except in S22, where it is the subject.

"Source in the spec" gives the requirements the example meets and the
sources they come from, from section 4 of the technique's spec. For a
custom solution these say what has to be achieved; how it is built is the
project's own, from the Flutter API documentation, which is why it is
flagged.

Every technique's spec has a "Custom solutions" section with its table from
here when one of its examples is flagged, and its doc says so near the top.
`test/docs/custom_solutions_test.dart` checks that this register, the
catalog (`customSolution` on `TechniqueExample.good`), the docs, and the
specs agree, and that every good example is in this register, so that no
example is added without a decision.

## Summary

| Technique | Good examples | Custom | Borderline | Not custom |
| --- | --- | --- | --- | --- |
| [C01 Button](#c01-button) | 6 | 2 | 0 | 4 |
| [C02 Toggle button](#c02-toggle-button) | 4 | 3 | 0 | 1 |
| [C03 Stand-alone link](#c03-stand-alone-link) | 4 | 4 | 0 | 0 |
| [C04 Links inline with text](#c04-links-inline-with-text) | 3 | 3 | 0 | 0 |
| [C05 Accordion](#c05-accordion) | 3 | 3 | 0 | 0 |
| [C12 Tooltip](#c12-tooltip) | 3 | 1 | 0 | 2 |
| [C18 Card](#c18-card) | 3 | 0 | 0 | 3 |
| [F01 Text fields and labels](#f01-text-fields-and-labels) | 3 | 0 | 0 | 3 |
| [F02 Input instructions](#f02-input-instructions) | 3 | 0 | 0 | 3 |
| [F03 Keyboard types](#f03-keyboard-types) | 4 | 0 | 0 | 4 |
| [F06 Error identification and announcement](#f06-error-identification-and-announcement) | 2 | 2 | 0 | 0 |
| [F07 Checkbox](#f07-checkbox) | 5 | 1 | 2 | 2 |
| [F08 Radio group](#f08-radio-group) | 4 | 0 | 2 | 2 |
| [F09 Switch](#f09-switch) | 4 | 1 | 1 | 2 |
| [F10 Slider](#f10-slider) | 4 | 4 | 0 | 0 |
| [I01 Focusable and clickable controls](#i01-focusable-and-clickable-controls) | 3 | 2 | 0 | 1 |
| [I02 Keyboard focus order](#i02-keyboard-focus-order) | 3 | 0 | 2 | 1 |
| [I03 Focus management](#i03-focus-management) | 3 | 3 | 0 | 0 |
| [I04 Keyboard actions and shortcuts](#i04-keyboard-actions-and-shortcuts) | 3 | 3 | 0 | 0 |
| [I08 Dismiss and escape](#i08-dismiss-and-escape) | 3 | 1 | 0 | 2 |
| [I12 Announcements and live regions](#i12-announcements-and-live-regions) | 3 | 0 | 0 | 3 |
| [S01 Accessible names](#s01-accessible-names) | 4 | 0 | 2 | 2 |
| [S02 Informative images](#s02-informative-images) | 4 | 0 | 0 | 4 |
| [S03 Decorative images](#s03-decorative-images) | 5 | 0 | 0 | 5 |
| [S04 Functional images](#s04-functional-images) | 6 | 3 | 0 | 3 |
| [S05 Headings](#s05-headings) | 2 | 0 | 0 | 2 |
| [S13 Roles and traits](#s13-roles-and-traits) | 5 | 4 | 0 | 1 |
| [S14 Values and state descriptions](#s14-values-and-state-descriptions) | 4 | 2 | 1 | 1 |
| [S15 Hints](#s15-hints) | 5 | 2 | 0 | 3 |
| [S22 Semantics identifiers for testing](#s22-semantics-identifiers-for-testing) | 4 | 2 | 2 | 0 |
| [V13 Minimum touch target size](#v13-minimum-touch-target-size) | 4 | 3 | 0 | 1 |
| [V14 Focus indicators](#v14-focus-indicators) | 4 | 2 | 0 | 2 |
| All | 120 | 51 | 12 | 57 |

## C01 Button

Flagged: `good-cupertino`, `good-custom`.

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-text` | Nothing: `FilledButton`, `OutlinedButton`, and `TextButton` with a text child | Those buttons | none | R1, R7, R8: iOS Buttons, APG Button, MDN <button> | not custom |
| `good-icon` | Nothing: `IconButton(tooltip:)` | `IconButton` | none | R5: Android Compose Interactive Control Labels | not custom |
| `good-disabled` | Nothing: `onPressed: null` | The Material buttons | none | R4: iOS Buttons, APG Button | not custom |
| `good-unique-names` | Nothing: `Text(semanticsLabel:)` on each button, and `Semantics(container: true)` to keep each row's text a node of its own | `TextButton` | none | R2: iOS Buttons | not custom |
| `good-cupertino` | An `Actions` for `ButtonActivateIntent` round the `CupertinoButton`, so that Enter works on the web; `Semantics(enabled: false)` round the disabled one | `CupertinoButton` | Enter on the web ([FL-002](flutter-limitations.md#fl-002)); the disabled state ([FL-001](flutter-limitations.md#fl-001)) | R1, R4, R7: iOS Buttons, APG Button | custom |
| `good-custom` | A button drawn by hand: role, state, and tap from `Semantics(button: true, enabled:, onTap:)`; focus, Enter, and Space from `FocusableActionDetector`; a focus ring of its own | None for a drawn control; the Material and Cupertino buttons are the framework's | none | R6, R7: Android View Focusable, Clickable Controls, APG Button | custom |

## C02 Toggle button

Flagged: `good-icon-button`, `good-cupertino`, `good-custom`.

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-icon-button` | The pressed state: `Semantics(toggled:)` round an `IconButton`, merged onto its node with `MergeSemantics`, in place of `isSelected`; the pressed look drawn with `style` | `IconButton(isSelected:)` | No pressed state ([FL-200](flutter-limitations.md#fl-200)); `isSelected` says nothing while off ([FL-201](flutter-limitations.md#fl-201)); the state stays off the button's node ([FL-040](flutter-limitations.md#fl-040)) | R1, R3, R4, R5: APG Button, MDN aria-pressed, iOS Buttons | custom |
| `good-toggle-buttons` | Nothing: `ToggleButtons(isSelected:)`, each icon with a `semanticLabel` | `ToggleButtons` | None filled (TalkBack says no state while off, [FL-045](flutter-limitations.md#fl-045), is left as it is) | R1, R3, R4, R5: APG Button, MDN aria-pressed, iOS Buttons | not custom |
| `good-cupertino` | `Semantics(toggled:, enabled: true)` round a `CupertinoButton`, an `Actions` for Enter on the web, and the colours of the on state | None: Cupertino has no toggle button; `CupertinoButton` is the closest | No pressed state ([FL-200](flutter-limitations.md#fl-200)); no enabled state ([FL-001](flutter-limitations.md#fl-001), [FL-033](flutter-limitations.md#fl-033)); Enter on the web ([FL-002](flutter-limitations.md#fl-002)); text colour in dark mode ([FL-202](flutter-limitations.md#fl-202)) | R1, R3, R4, R5: APG Button, MDN aria-pressed, iOS Buttons | custom |
| `good-custom` | A toggle button drawn by hand: `Semantics(button: true, toggled:, enabled: true, label:, onTap:)`; Space and Enter from `FocusableActionDetector`; a focus ring of its own | None for a drawn control | No pressed state ([FL-200](flutter-limitations.md#fl-200)); dimmed without `enabled` ([FL-033](flutter-limitations.md#fl-033)) | R1, R3, R4, R5: APG Button, MDN aria-pressed, iOS Buttons | custom |

## C03 Stand-alone link

Flagged: `good-material`, `good-cupertino`, `good-custom`, `good-image-link`.

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-material` | A link: `Semantics(link: true, linkUrl:, onTapHint:)` round an `InkWell`; `BrowserKeys` (a `Shortcuts` with `DoNothingAndStopPropagationIntent`), so that the browser follows it on the web; a focus ring of its own | None: Flutter has no link widget ([FL-221](flutter-limitations.md#fl-221)) | No link widget ([FL-221](flutter-limitations.md#fl-221)); a link needs `linkUrl` ([FL-032](flutter-limitations.md#fl-032)); no role on Android ([FL-220](flutter-limitations.md#fl-220)); the browser follows it as well as the app ([FL-013](flutter-limitations.md#fl-013)); a faint focus tint ([FL-430](flutter-limitations.md#fl-430)) | R1, R2, R4, R5, R7: iOS Links, Android Compose Stand-alone Links, MDN a, WCAG failure F84, APG Link | custom |
| `good-cupertino` | `KeyboardLink` round a `CupertinoListTile`: `FocusableActionDetector` for focus, Enter, and Space off the web; a focus ring; `Semantics(link: true, linkUrl:, onTapHint:)` | None: Flutter has no link widget ([FL-221](flutter-limitations.md#fl-221)) | No link widget ([FL-221](flutter-limitations.md#fl-221)); the tile takes no focus ([FL-400](flutter-limitations.md#fl-400)); no role on Android ([FL-220](flutter-limitations.md#fl-220)); [FL-013](flutter-limitations.md#fl-013) | R1, R2, R3, R4, R5, R7: iOS Links, Android Compose Stand-alone Links, MDN a, WCAG failure F84, APG Link | custom |
| `good-custom` | `KeyboardLink` round a `GestureDetector` | None: Flutter has no link widget ([FL-221](flutter-limitations.md#fl-221)) | No link widget ([FL-221](flutter-limitations.md#fl-221)); no role on Android ([FL-220](flutter-limitations.md#fl-220)); [FL-013](flutter-limitations.md#fl-013) | R1, R2, R4, R5, R7: iOS Links, Android Compose Stand-alone Links, MDN a, WCAG failure F84, APG Link | custom |
| `good-image-link` | The link of `good-material`, round a picture: `Semantics(label:)` on the link, `Image(excludeFromSemantics: true)` | None: Flutter has no link widget ([FL-221](flutter-limitations.md#fl-221)) | No link widget ([FL-221](flutter-limitations.md#fl-221)); a label on an image in a control does not name it ([FL-030](flutter-limitations.md#fl-030)) | R2, R6: APG Link, MDN a, WCAG failure F89 | custom |

## C04 Links inline with text

Flagged: `good-material`, `good-cupertino`, `good-custom`.

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-material` | `MaterialInlineLink`: `Semantics(link: true, linkUrl:, onTapHint:)` round an `InkWell` in a `WidgetSpan`; C03's `BrowserKeys`; a focus ring; a sort key and an identifier that keep it in its sentence | A `TextSpan` with a tap recognizer, which takes no keyboard focus ([FL-240](flutter-limitations.md#fl-240)); no link widget ([FL-221](flutter-limitations.md#fl-221)) | [FL-240](flutter-limitations.md#fl-240); [FL-413](flutter-limitations.md#fl-413) (read after its sentence); [FL-241](flutter-limitations.md#fl-241) (scaled twice); [FL-013](flutter-limitations.md#fl-013); [FL-221](flutter-limitations.md#fl-221) | R1, R2, R3, R4, R5, R6, R7: APG Link, MDN a, iOS Links, G53, Android Compose, F73, G183, C03 R7 | custom |
| `good-cupertino` | `KeyboardInlineLink`: `FocusableActionDetector` round `Semantics(link: true, linkUrl:, onTapHint:)` and a `GestureDetector` in a `WidgetSpan`; the high-contrast `systemBlue` | As `good-material`; Cupertino has no link widget either | [FL-240](flutter-limitations.md#fl-240); [FL-413](flutter-limitations.md#fl-413); [FL-241](flutter-limitations.md#fl-241); [FL-242](flutter-limitations.md#fl-242) (link colour under 4.5:1); [FL-221](flutter-limitations.md#fl-221) | R1, R2, R3, R4, R5, R6, R7: APG Link, MDN a, iOS Links, G53, Android Compose, F73, G183, C03 R7 | custom |
| `good-custom` | `KeyboardInlineLink` in the theme's primary colour | As `good-material` | [FL-240](flutter-limitations.md#fl-240); [FL-413](flutter-limitations.md#fl-413); [FL-241](flutter-limitations.md#fl-241); [FL-221](flutter-limitations.md#fl-221) | R1, R2, R3, R4, R5, R6, R7: APG Link, MDN a, iOS Links, G53, Android Compose, F73, G183, C03 R7 | custom |

## C05 Accordion

Flagged: `good-material`, `good-cupertino`, `good-custom`.

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-material` | The accordion's state, with each panel built only while open; `HeaderSemantics` (`Semantics(button: true, expanded:)`, a heading, an iOS value, a tap hint, the expand and collapse actions, and `controlsNodes` while open) round a `ListTile`; a focus ring of its own | `ExpansionTile` | No expanded state and, on Android and iOS, no button role ([FL-264](flutter-limitations.md#fl-264)); no state on iOS ([FL-260](flutter-limitations.md#fl-260)); a heading that is a button on the web ([FL-262](flutter-limitations.md#fl-262)); `aria-controls` ([FL-266](flutter-limitations.md#fl-266)); a faint focus tint ([FL-430](flutter-limitations.md#fl-430)) | R1 to R8: APG Accordion, iOS Accordions, Android View Accordion Controls, Android Compose Accordion Controls | custom |
| `good-cupertino` | As `good-material`, round a `CupertinoListTile` given focus, Enter, and Space by `FocusableActionDetector`; its title in a `DefaultTextStyle` of its own, so that it wraps | `CupertinoExpansionTile` | No keyboard focus, no button role, and no state ([FL-265](flutter-limitations.md#fl-265), [FL-400](flutter-limitations.md#fl-400)); as `good-material` for [FL-260](flutter-limitations.md#fl-260), [FL-262](flutter-limitations.md#fl-262), and [FL-266](flutter-limitations.md#fl-266) | R1 to R8: APG Accordion, iOS Accordions, Android View Accordion Controls, Android Compose Accordion Controls | custom |
| `good-custom` | As `good-material`, round a header from the widgets layer: a `GestureDetector`, and focus, Enter, and Space from `FocusableActionDetector` | None for a drawn control; the SDK's accordions are `ExpansionTile`, `CupertinoExpansionTile`, and `ExpansionPanelList` ([FL-267](flutter-limitations.md#fl-267)) | As `good-material` for [FL-260](flutter-limitations.md#fl-260), [FL-262](flutter-limitations.md#fl-262), and [FL-266](flutter-limitations.md#fl-266) | R1 to R8: APG Accordion, iOS Accordions, Android View Accordion Controls, Android Compose Accordion Controls | custom |

## C12 Tooltip

Flagged: `good-cupertino`.

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-material` | Nothing: `Tooltip(message:, ignorePointer: false, excludeFromSemantics: true)` round an `IconButton` named by `Icon(semanticLabel:)`, and a focus outline through the button's own `style` | `Tooltip` | The pointer cannot reach a default tooltip ([FL-247](flutter-limitations.md#fl-247)), filled with its own parameter; a faint focus tint ([FL-430](flutter-limitations.md#fl-430)), filled with the button's `style` | R2, R3, R4: 1.4.13, Understanding 1.4.13, F95, APG, MDN title, Flutter's Tooltip documentation, 4.1.2, C01 | not custom |
| `good-cupertino` | An `Actions` for `ButtonActivateIntent` round the `CupertinoButton`, so that Enter works on the web; the tooltip itself is Material's `Tooltip` through its parameters | None: Cupertino has no tooltip; Material's `Tooltip` is used, with `CupertinoButton` | Enter on the web ([FL-002](flutter-limitations.md#fl-002)); the box over the button ([FL-250](flutter-limitations.md#fl-250)) and the faint ring ([FL-431](flutter-limitations.md#fl-431)), filled with parameters | R2, R3, R4: 1.4.13, Understanding 1.4.13, F95, APG, MDN title, Flutter's Tooltip documentation, 4.1.2, C01 | custom |
| `good-description` | Nothing is built: `MergeSemantics` round `Tooltip(message:, ignorePointer: false)` round an `OutlinedButton`, so that the tooltip is on the button | `Tooltip` | A tooltip round a Material button stays on a node of its own ([FL-040](flutter-limitations.md#fl-040)), filled with the documented merge | R2, R3, R4: 1.4.13, Understanding 1.4.13, F95, APG, MDN title, Flutter's Tooltip documentation, 4.1.2, C01 | not custom |

## C18 Card

Nothing flagged.

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-material` | Nothing: `Card(semanticContainer: false)`, as its documentation says for a card with different kinds of content; `Semantics(headingLevel: 3)` on the title; `Image(semanticLabel:)`; `TextButton`s named with `Text(semanticsLabel:)` and given a focus outline through their own `style` | `Card`, `TextButton` | The card's texts join one heading by default ([FL-269](flutter-limitations.md#fl-269)), filled with its own parameter; a faint focus tint ([FL-430](flutter-limitations.md#fl-430)), filled with the button's `style` | R1, R2, R3, R4, R5: iOS Cards, MDN article, Card documentation, S01, S02 | not custom |
| `good-tappable` | Nothing: a `ListTile(onTap:)` with a title and a subtitle, in a `Card` | `Card`, `ListTile` | An `InkWell` card has no button role ([FL-401](flutter-limitations.md#fl-401)), filled by using `ListTile` | R6, R7: iOS Cards, Card documentation, ARIA button | not custom |
| `good-cupertino` | Nothing is built: a `DecoratedBox` in Cupertino's grouped background, with `Semantics(headingLevel: 3)` on the title and `Image(semanticLabel:)` | None: Cupertino has no card | none | R1, R2, R3: iOS Cards, MDN article, S02 | not custom |

## F01 Text fields and labels

Nothing flagged.

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-label` | Nothing: `InputDecoration(labelText:)` | `TextField` | none | R1, R2, R5: iOS Text Fields, Android View Input Field Labels, Android Compose TextField Controls, MDN textarea | not custom |
| `good-label-above` | Nothing is built: the field is named with `Semantics(label:)`, and the visible label above it is in `ExcludeSemantics` | `TextField` | none | R1, R4: iOS Text Fields, Android View Input Field Labels, Android Compose TextField Controls, MDN label | not custom |
| `good-cupertino` | Nothing is built: `Semantics(label:)` on the `CupertinoTextField`, and the form row's prefix in `ExcludeSemantics` | `CupertinoTextField` in a `CupertinoFormRow` | The field has no label ([FL-016](flutter-limitations.md#fl-016)), filled with a name only | R1, R4: iOS Text Fields, Android View Input Field Labels, Android Compose TextField Controls, MDN label | not custom |

## F02 Input instructions

Nothing flagged.

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-helper` | Nothing is built: `Semantics(hint:)` with the helper text's words round `TextField(helperText:, helperMaxLines:)` | `TextField` with `InputDecoration.helperText` | Helper text is not tied to its field ([FL-140](flutter-limitations.md#fl-140)), filled with a hint only; one line by default ([FL-141](flutter-limitations.md#fl-141)) | R1, R2, R3, R5, R6: iOS Input Instructions, WCAG G89, WCAG ARIA1, MDN: aria-describedby, MDN: placeholder, Understanding 3.3.2, WCAG 1.4.4 | not custom |
| `good-cupertino` | Nothing is built: `Semantics(label:, hint:)` on the field, the visible label in `ExcludeSemantics` | `CupertinoFormRow(helper:)` | The field has no label or hint ([FL-016](flutter-limitations.md#fl-016)), filled with text only | R1, R2, R3, R5, R6: iOS Input Instructions, WCAG G89, WCAG ARIA1, MDN: aria-describedby, MDN: placeholder, Understanding 3.3.2, WCAG 1.4.4 | not custom |
| `good-before` | Nothing is built: a `Text` above the field, and `Semantics(label:, hint:)` on it, with the visible label in `ExcludeSemantics` | `TextField` | none | R1, R2, R3, R4, R5, R6: iOS Input Instructions, WCAG G89, WCAG ARIA1, MDN: aria-describedby, Android Compose TextField Controls, MDN: placeholder, Understanding 3.3.2, WCAG 1.4.4 | not custom |

## F03 Keyboard types

Nothing flagged.

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-contact` | Nothing: `TextField(keyboardType:, autofillHints:, textInputAction:)` | `TextField` | none | R1, R2, R3, R5: Android View Keyboard Types, Android Compose Keyboard Types and Options, MDN: inputmode, Understanding 1.3.5, H98, MDN: autocomplete, MDN: enterkeyhint | not custom |
| `good-amount` | Nothing: `TextField(keyboardType: TextInputType.numberWithOptions(decimal: true))` | `TextField` | none | R1, R5: Android View Keyboard Types, Android Compose Keyboard Types and Options, MDN: inputmode, MDN: enterkeyhint | not custom |
| `good-cupertino` | Nothing is built: `Semantics(label:)` on the field, the visible label in `ExcludeSemantics` | `CupertinoTextField` | The field has no label ([FL-016](flutter-limitations.md#fl-016)), filled with a name only | R1, R2, R3, R5: Android View Keyboard Types, Android Compose Keyboard Types and Options, MDN: inputmode, Understanding 1.3.5, H98, MDN: autocomplete, MDN: enterkeyhint | not custom |
| `good-sign-in` | Nothing: `AutofillGroup` and two `TextField`s, one with `obscureText: true` | `AutofillGroup`, `TextField` | none | R2, R4, R5: Android View Keyboard Types, Understanding 1.3.5, H98, MDN: autocomplete, Android Compose Keyboard Types and Options, MDN: input type=password, MDN: enterkeyhint | not custom |

## F06 Error identification and announcement

Flagged: `good-form`, `good-cupertino`.

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-form` | The move to the first field in error: `FocusNode.requestFocus()`, then a `FocusSemanticEvent` a frame later so that VoiceOver on iOS follows | `Form` and `TextFormField`, which show, announce, and mark the error but move no focus | VoiceOver on iOS does not follow keyboard focus ([FL-184](flutter-limitations.md#fl-184)) | R1, R2, R3, R4, R5, R6: iOS Error Validation, Android View Input Error Announcements, Android View, MDN: aria-invalid | custom |
| `good-cupertino` | An error field assembled by hand: `FormField` round a `CupertinoFormRow`; `Semantics(label:, hint:, validationResult:)` on the field; the error a live region where announcements are not supported; the focus move of `good-form` | `CupertinoTextFormFieldRow`, not used: its error is not announced on Android ([FL-182](flutter-limitations.md#fl-182)) and its field has no label ([FL-016](flutter-limitations.md#fl-016)) | [FL-182](flutter-limitations.md#fl-182); [FL-016](flutter-limitations.md#fl-016); [FL-184](flutter-limitations.md#fl-184) | R1, R2, R3, R4, R5, R6: iOS Error Validation, Android View Input Error Announcements, Android View, MDN: aria-invalid | custom |

## F07 Checkbox

Flagged: `good-custom`.

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-tile` | Nothing: `CheckboxListTile` | `CheckboxListTile` | none | R1, R2, R3, R5, R7: Android Compose Checkbox Controls, iOS Checkboxes, MDN: input type=checkbox, APG Checkbox | not custom |
| `good-cupertino` | The box and its text merged into one control (`MergeSemantics`, through `TestId`), and a `GestureDetector` so that a tap on the text changes the box | `CupertinoCheckbox`; Cupertino has no list tile for a checkbox, Material has `CheckboxListTile` | none | R1, R2, R3, R5, R7: Android Compose Checkbox Controls, iOS Checkboxes, MDN: input type=checkbox, APG Checkbox | borderline: The merge is what the `MergeSemantics` documentation describes for a checkbox and its text, and the box keeps its own role, state, and keys; but the labelled row, with a `GestureDetector` on the text, is assembled by hand where Material has a widget for it. |
| `good-custom` | A checkbox drawn by hand: `Semantics(checked:, enabled: true, label:, onTap:)`; Space from `FocusableActionDetector`; a focus ring of its own | None for a drawn control | Dimmed without `enabled` ([FL-033](flutter-limitations.md#fl-033)) | R1, R2, R3, R5, R7: Android Compose Checkbox Controls, iOS Checkboxes, MDN: input type=checkbox, APG Checkbox | custom |
| `good-mixed` | Nothing: `CheckboxListTile(tristate: true, value: null)` | `CheckboxListTile` | None filled (the mixed state is lost on most platforms, [FL-044](flutter-limitations.md#fl-044), and left as it is) | R4: APG Checkbox, MDN: input type=checkbox | not custom |
| `good-group` | A named group: `Semantics(container: true, explicitChildNodes: true, label:)` round the boxes, the visible question in `ExcludeSemantics` | None for a named group of checkboxes | none | R6: iOS Checkboxes, APG Checkbox | borderline: Only a name is given, with documented `Semantics` properties, and nothing behaves differently; but it makes a group node, a structure no Flutter widget provides. |

## F08 Radio group

Nothing flagged.

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-group` | Nothing: `RadioGroup` round a `Text` and three `RadioListTile`s | `RadioGroup`, `RadioListTile` | None filled (`RadioGroup` has no label parameter, [FL-046](flutter-limitations.md#fl-046); the text inside names it) | R1, R2, R3, R4, R5, R7: Android Compose RadioButton Groups, MDN: input type=radio, APG Radio Group, iOS Radio Buttons, MDN: fieldset | not custom |
| `good-cupertino` | Each `CupertinoRadio` merged with its text (`MergeSemantics`, through `TestId`), with a `GestureDetector` so that a tap on the text chooses it | `RadioGroup`, `CupertinoRadio`; Cupertino has no list tile for a radio button | none | R1, R2, R3, R4, R5, R7: Android Compose RadioButton Groups, MDN: input type=radio, APG Radio Group, iOS Radio Buttons, MDN: fieldset | borderline: As F07 `good-cupertino`: the merge is documented and the radio button keeps its own role, state, and keys, but the labelled row is assembled by hand. |
| `good-custom` | The drawing of a `RawRadio`: a ring from its builder, a focus ring drawn from its focus node, and the row merged with its text, with a `GestureDetector` on the text | `RawRadio` and `RadioGroup`, which are used: they give the role, the state, focus, and the arrow keys | none | R1, R2, R3, R4, R5, R7: Android Compose RadioButton Groups, MDN: input type=radio, APG Radio Group, iOS Radio Buttons, MDN: fieldset | borderline: The control is the framework's own `RawRadio`, used through its documented parameters; what is by hand is its drawing, a focus ring, and the merged row with a tap on the text. |
| `good-context` | Nothing: `Text(semanticsLabel:)` as each tile's title | `RadioListTile` | none | R6: Android Compose RadioButton Groups | not custom |

## F09 Switch

Flagged: `good-custom`.

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-tile` | Nothing: `SwitchListTile` | `SwitchListTile` | none | R1, R2, R3, R4, R5, R7: Android Compose Switch Controls, iOS Toggles, APG Switch, MDN: ARIA switch role, MDN switch role | not custom |
| `good-cupertino` | Nothing is built: `MergeSemantics` round a `CupertinoListTile` with a trailing `CupertinoSwitch` and `onTap`, as the `CupertinoSwitch` documentation shows | `CupertinoSwitch` in a `CupertinoListTile` | none | R1, R2, R3, R4, R5, R7: Android Compose Switch Controls, iOS Toggles, APG Switch, MDN: ARIA switch role, MDN switch role | not custom |
| `good-custom` | A switch drawn by hand: `Semantics(toggled:, enabled: true, label:, onTap:)`; Space and Enter from `FocusableActionDetector`; a focus ring of its own | None for a drawn control | Dimmed without `enabled` ([FL-033](flutter-limitations.md#fl-033)) | R1, R2, R3, R4, R5, R7: Android Compose Switch Controls, iOS Toggles, APG Switch, MDN: ARIA switch role, MDN switch role | custom |
| `good-group` | A named group: `Semantics(container: true, explicitChildNodes: true, label:)` round the switches, the visible question in `ExcludeSemantics` | None for a named group of switches | none | R6: APG Switch | borderline: As F07 `good-group`: only a name, with documented properties, but a group node that no widget provides. |

## F10 Slider

Flagged: `good-material`, `good-cupertino`, `good-custom`, `good-value-text`.

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-material` | Home and End keys, from a `CallbackShortcuts` round the `Slider` | `Slider` | No Home or End keys ([FL-122](flutter-limitations.md#fl-122)) | R1, R2, R3, R4, R5: iOS Sliders, Android Compose Slider and RangeSlider Controls, APG Slider, MDN: input type=range, MDN, Android Compose Slider, G216 | custom |
| `good-cupertino` | The keyboard for a `CupertinoSlider`: `FocusableActionDetector` with the APG keys, a focus ring, and two buttons a step down and up | `CupertinoSlider` | No keyboard focus ([FL-120](flutter-limitations.md#fl-120)); moves only when its thumb is dragged ([FL-121](flutter-limitations.md#fl-121)) | R1, R2, R3, R4, R5: iOS Sliders, Android Compose Slider and RangeSlider Controls, APG Slider, MDN: input type=range, MDN, Android Compose Slider, G216 | custom |
| `good-custom` | A slider drawn by hand: `Semantics(slider: true, label:, value:, increasedValue:, decreasedValue:, onIncrease:, onDecrease:)` round a track that takes a tap and a drag, with the APG keys from `FocusableActionDetector` | `Slider`, `CupertinoSlider`; none for a drawn slider | none | R1, R2, R3, R4, R5: iOS Sliders, Android Compose Slider and RangeSlider Controls, APG Slider, MDN: input type=range, MDN, Android Compose Slider, G216 | custom |
| `good-value-text` | The Home and End keys of `good-material`; the value text itself is the slider's own `semanticFormatterCallback` | `Slider` | No Home or End keys ([FL-122](flutter-limitations.md#fl-122)) | R3: APG Slider, Android Compose Slider | custom |

## I01 Focusable and clickable controls

Flagged: `good-cupertino`, `good-custom`.

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-material` | Nothing: `ListTile(onTap:)` in a `Card` | `ListTile` | none | R1, R2, R3, R4, R5: Android View: Focusable, Clickable Controls, MDN: Keyboard-navigable JavaScript widgets, Android View, MDN, APG Button, WCAG Understanding 2.5.2 | not custom |
| `good-cupertino` | Focus, Enter, and Space from `FocusableActionDetector`, a focus ring from `onShowFocusHighlight`, and `Semantics(button: true)`, round a `CupertinoListTile` | `CupertinoListTile` | No keyboard focus and no button role ([FL-400](flutter-limitations.md#fl-400)) | R1, R2, R3, R4, R5: Android View: Focusable, Clickable Controls, MDN: Keyboard-navigable JavaScript widgets, Android View, MDN, APG Button, WCAG Understanding 2.5.2 | custom |
| `good-custom` | A card made a button: `GestureDetector(onTap:)` in `Semantics(button: true)` in the same `FocusableActionDetector` | None for a drawn control | none | R1, R2, R3, R4, R5: Android View: Focusable, Clickable Controls, MDN: Keyboard-navigable JavaScript widgets, Android View, MDN, APG Button, WCAG Understanding 2.5.2 | custom |

## I02 Keyboard focus order

Nothing flagged.

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-material` | Nothing: a `FocusTraversalGroup` round each column of `CheckboxListTile`s | `FocusTraversalGroup` | none | R1, R2, R4, R5: Android View: Keyboard and Accessibility Focus Order, Android Compose: Keyboard Focus Order, Understanding 2.4.3, Android View, Android Compose, MDN: tabindex, Android View: Arrow Key Focus Order | not custom |
| `good-cupertino` | Each `CupertinoCheckbox` merged with its text and a `GestureDetector`, as in F07 `good-cupertino`; the traversal groups are the framework's | `FocusTraversalGroup`; `CupertinoCheckbox` | none | R1, R2, R4, R5: Android View: Keyboard and Accessibility Focus Order, Android Compose: Keyboard Focus Order, Understanding 2.4.3, Android View, Android Compose, MDN: tabindex, Android View: Arrow Key Focus Order | borderline: The technique's mechanism, `FocusTraversalGroup`, is the framework's; the controls are the hand-assembled checkbox rows of F07 `good-cupertino`, which is borderline itself. |
| `good-ordered` | A number on every control and every element: `OrderedTraversalPolicy` with a `NumericFocusOrder` on each control, and an `OrdinalSortKey` with the same number on each element | `FocusTraversalOrder`, `OrderedTraversalPolicy`, `Semantics.sortKey`, which are used | The keyboard's order and the screen reader's are set by separate widgets ([FL-420](flutter-limitations.md#fl-420)) | R1, R2, R3, R4, R5: Android View: Keyboard and Accessibility Focus Order, Android Compose: Keyboard Focus Order, Understanding 2.4.3, Android View, Android Compose, MDN: tabindex, MDN, Android View: Arrow Key Focus Order | borderline: Every widget is the framework's, used through its documented parameters; but keeping two orders in step by numbering every element by hand is a scheme of the project's own, for [FL-420](flutter-limitations.md#fl-420). |

## I03 Focus management

Flagged: `good-material`, `good-cupertino`, `good-widgets`.

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-material` | After a removal, focus put on the next trail's button with `FocusNode.requestFocus`, and on iOS a `FocusSemanticEvent` sent one frame after the question's route has gone | `showDialog`, whose route gives focus back when it closes; nothing decides where it goes when the opener is gone | The framework sends the screen reader back after the app's own move ([FL-442](flutter-limitations.md#fl-442)) | R1, R2, R3, R4, R5: iOS: Focus Management, Understanding 2.4.3, F85, Understanding 3.2.1, G107 | custom |
| `good-cupertino` | The focus move of `good-material`, and an `Actions` for Enter on the web round each button of the action sheet | `showCupertinoModalPopup` with a `CupertinoActionSheet` | [FL-442](flutter-limitations.md#fl-442); Enter on the web ([FL-002](flutter-limitations.md#fl-002)) | R1, R2, R3, R4, R5: iOS: Focus Management, Understanding 2.4.3, F85, Understanding 3.2.1, G107 | custom |
| `good-widgets` | The focus move of `good-material`, in a question drawn by hand in `showGeneralDialog` with `autofocus` on Cancel | `showGeneralDialog` | [FL-442](flutter-limitations.md#fl-442) | R1, R2, R3, R4, R5: iOS: Focus Management, Understanding 2.4.3, F85, Understanding 3.2.1, G107 | custom |

## I04 Keyboard actions and shortcuts

Flagged: `good-on-focus`, `good-turn-off`, `good-remap`.

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-on-focus` | The keys of a thumbnail strip: a `Shortcuts` mapping Left, Right, Home, End, and F to intents, and `Actions` for them | None: no widget has a strip with keys of its own | none | R1, R2, R3, R4, R5, R6: Android Compose: Keyboard Actions, MDN: Keyboard-navigable JavaScript widgets, APG: Toolbar, WCAG 2.2: 2.1.4, Understanding 2.1.4, WCAG 2.2 glossary, EditableText's documentation on shortcuts and text input | custom |
| `good-turn-off` | A `CallbackShortcuts` for F that a switch turns off; the strip's keys in a `Focus(onKeyEvent:)`; a `Shortcuts` that keeps F for the text field | None | A shortcut above a text field takes its key ([FL-460](flutter-limitations.md#fl-460)); [FL-464](flutter-limitations.md#fl-464) | R1, R2, R3, R4, R5, R6: Android Compose: Keyboard Actions, MDN: Keyboard-navigable JavaScript widgets, APG: Toolbar, WCAG 2.2: 2.1.4, Understanding 2.1.4, WCAG 2.2 glossary, EditableText's documentation on shortcuts and text input | custom |
| `good-remap` | A `CallbackShortcuts` bound to F or to Control+F; the strip's keys in a `CallbackShortcuts` | None | [FL-460](flutter-limitations.md#fl-460); [FL-464](flutter-limitations.md#fl-464) | R1, R2, R3, R4, R5, R6: Android Compose: Keyboard Actions, MDN: Keyboard-navigable JavaScript widgets, APG: Toolbar, WCAG 2.2: 2.1.4, Understanding 2.1.4, WCAG 2.2 glossary, EditableText's documentation on shortcuts and text input | custom |

## I08 Dismiss and escape

Flagged: `good-widgets`.

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-material` | Nothing: `showModalBottomSheet` | `showModalBottomSheet` | none | R1, R2, R3, R4, R5: APG: Dialog, Understanding 2.1.2, iOS: Escape Action, HTML: close requests, WCAG 2.2: 2.1.2, G21 | not custom |
| `good-cupertino` | Nothing: `showCupertinoModalPopup(semanticsDismissible: true)` | `showCupertinoModalPopup` | none | R1, R2, R3, R4, R5: APG: Dialog, Understanding 2.1.2, iOS: Escape Action, HTML: close requests, WCAG 2.2: 2.1.2, G21 | not custom |
| `good-widgets` | Dismissal for layers in an `OverlayEntry`: a `ModalBarrier`, a `FocusScopeNode` that keeps Tab in, an `Actions` for `DismissIntent`, `Semantics(onDismiss:)`, and a `PopScope` for Back | A route (`showModalBottomSheet`, `showDialog`); none for an overlay that is not a route | Nothing closes an overlay that is not a route ([FL-481](flutter-limitations.md#fl-481)) | R1, R2, R3, R4, R5: APG: Dialog, Understanding 2.1.2, iOS: Escape Action, HTML: close requests, WCAG 2.2: 2.1.2, G21 | custom |

## I12 Announcements and live regions

Nothing flagged.

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-live-region` | Nothing: `Semantics(liveRegion: true)` on the message | `Semantics.liveRegion` | none | R1, R2, R3: Android View UX Change Announcements, Android Compose UX Change Announcements, iOS Accessibility Notifications, APG Alert, Android View and Compose, MDN live regions, MDN output | not custom |
| `good-announce` | Nothing is built: `SemanticsService.sendAnnouncement` where `MediaQuery.supportsAnnounceOf` is true, and a live region otherwise, as the `SemanticsService` documentation says | `SemanticsService.sendAnnouncement` | Not supported on Android ([FL-018](flutter-limitations.md#fl-018)), handled as the documentation says | R1, R2, R4: Android View UX Change Announcements, Android Compose UX Change Announcements, iOS Accessibility Notifications, APG Alert, iOS, Android Compose | not custom |
| `good-snackbar` | Nothing: `ScaffoldMessenger.showSnackBar` | `SnackBar` | none | R1, R2: Android View UX Change Announcements, Android Compose UX Change Announcements, iOS Accessibility Notifications, APG Alert | not custom |

## S01 Accessible names

Nothing flagged.

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-visible-label` | Nothing: `CheckboxListTile`, `SwitchListTile` | Those tiles | none | R1, R2, R7: iOS Accessibility Label, Android Compose Interactive Control Labels, MDN label, Android Compose | not custom |
| `good-merged-label` | A checkbox and a switch laid out beside their text, merged (`MergeSemantics`), with a `GestureDetector` so that a tap on the text operates the control | `CheckboxListTile`, `SwitchListTile` | none | R1, R2, R7: iOS Accessibility Label, Android Compose Interactive Control Labels, MDN label, Android Compose | borderline: As F07 `good-cupertino`: the merge is what `MergeSemantics` documents, but the labelled row is assembled by hand where `CheckboxListTile` and `SwitchListTile` exist. |
| `good-specific-names` | Nothing: `Text(semanticsLabel:)` | The list tiles | none | R3, R4: iOS Meaningful Accessible Names, iOS Accessibility Label | not custom |
| `good-cupertino` | A `CupertinoSwitch` merged with the text beside it, with a `GestureDetector` on the text | `CupertinoSwitch` in a `CupertinoListTile`, as F09 `good-cupertino` uses it | none | R1, R2, R7: iOS Accessibility Label, Android Compose Interactive Control Labels, MDN label, Android Compose | borderline: As `good-merged-label`: a documented merge, but a labelled row assembled by hand. |

## S02 Informative images

Nothing flagged.

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-image-label` | Nothing: `Image(semanticLabel:)` | `Image` | none | R1, R2, R3: iOS Images, iOS Informative Images, Android Compose Text Alternatives, Android View Text Alternatives, MDN img | not custom |
| `good-icon-label` | Nothing: `Icon(semanticLabel:)`, merged with the order's text | `Icon` | none | R5, R6: Android Compose Text Alternatives, iOS Informative Images | not custom |
| `good-group-description` | Nothing: `Semantics(label:)` round `ExcludeSemantics` | `Semantics.label` | none | R7: Android Compose Text Alternatives | not custom |
| `good-chart` | Nothing is built: `Semantics(image: true, label:)` round a `CustomPaint`, which is not interactive | `CustomPaint` with `Semantics` | none | R8: Android Compose Text Alternatives | not custom |

## S03 Decorative images

Nothing flagged.

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-image-excluded` | Nothing: `Image(excludeFromSemantics: true)` | `Image` | none | R1, R2: iOS Decorative Images, iOS Images, Android Compose Text Alternatives, Android View Text Alternatives, MDN img, WAI Images Tutorial: Decorative Images, Android Compose and View Text Alternatives | not custom |
| `good-icon-no-label` | Nothing: an `Icon` with no `semanticLabel` | `Icon` | none | R1, R2, R3: iOS Decorative Images, iOS Images, Android Compose Text Alternatives, Android View Text Alternatives, MDN img, WAI Images Tutorial: Decorative Images, Android Compose and View Text Alternatives | not custom |
| `good-background-image` | Nothing: a `DecorationImage` | `DecorationImage` | none | R1, R2: iOS Decorative Images, iOS Images, Android Compose Text Alternatives, Android View Text Alternatives, MDN img, WAI Images Tutorial: Decorative Images, Android Compose and View Text Alternatives | not custom |
| `good-exclude-semantics` | Nothing: `ExcludeSemantics` round a `CircleAvatar` | `ExcludeSemantics` | none | R1, R6: iOS Decorative Images, iOS Images, Android Compose Text Alternatives, Android View Text Alternatives, MDN img, WAI Images Tutorial: Decorative Images | not custom |
| `good-merged-row` | Nothing: an excluded `Image` in a `MergeSemantics` row | `Image`, `MergeSemantics` | none | R1: iOS Decorative Images, iOS Images, Android Compose Text Alternatives, Android View Text Alternatives, MDN img, WAI Images Tutorial: Decorative Images | not custom |

## S04 Functional images

Flagged: `good-cupertino`, `good-custom`, `good-image-regions`.

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-image-button` | Nothing: `IconButton(tooltip:)` with an excluded `Image` | `IconButton` | none | R1, R2, R4: iOS Functional Images, Android Compose Text Alternatives, Android View Text Alternatives, WAI Images Tutorial: Functional Images, MDN img, WCAG failure F65, WAI Functional Images, WCAG failure F30, iOS Functional Images sample code | not custom |
| `good-icon-label` | Nothing: `IconButton` with `Icon(semanticLabel:)` | `IconButton` | none | R1, R2: iOS Functional Images, Android Compose Text Alternatives, Android View Text Alternatives, WAI Images Tutorial: Functional Images, MDN img, WCAG failure F65, WAI Functional Images, WCAG failure F30 | not custom |
| `good-image-with-text` | Nothing: `TextButton` with an excluded `Image`; `FilledButton.icon` | `TextButton`, `FilledButton.icon` | none | R5: WAI Functional Images, Android Compose and View Text Alternatives | not custom |
| `good-cupertino` | An `Actions` for `ButtonActivateIntent` round the `CupertinoButton`, so that Enter works on the web | `CupertinoButton` | Enter on the web ([FL-002](flutter-limitations.md#fl-002)) | R1, R2: iOS Functional Images, Android Compose Text Alternatives, Android View Text Alternatives, WAI Images Tutorial: Functional Images, MDN img, WCAG failure F65, WAI Functional Images, WCAG failure F30 | custom |
| `good-custom` | A picture made a button: `Semantics(button: true, label:)`, `FocusableActionDetector`, a `GestureDetector`, an excluded `Image`, a focus ring of its own | `IconButton`; none for a drawn control | none | R1, R2, R4: iOS Functional Images, Android Compose Text Alternatives, Android View Text Alternatives, WAI Images Tutorial: Functional Images, MDN img, WCAG failure F65, WAI Functional Images, WCAG failure F30, iOS Functional Images sample code | custom |
| `good-image-regions` | An image map: two `Semantics(button: true, label:)` regions with an `InkWell` each on a transparent `Material`, over an excluded `Image`, each with a focus ring drawn above the picture | None: Flutter has no image map | none | R6: MDN area, MDN map | custom |

## S05 Headings

Nothing flagged.

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-levels` | Nothing: `Semantics(header: true, headingLevel:)` | `Semantics.headingLevel` | none | R1, R2, R4: iOS Headings, Android Compose Heading Semantics, Android View Heading Semantics, MDN heading elements | not custom |
| `good-cupertino` | Nothing: `Semantics(header: true, headingLevel: 3)` as a `CupertinoListSection` header | `CupertinoListSection` | The header is not a heading ([FL-014](flutter-limitations.md#fl-014)), filled with the documented property | R1: iOS Headings, Android Compose Heading Semantics, Android View Heading Semantics | not custom |

## S13 Roles and traits

Flagged: `good-cupertino`, `good-custom-button`, `good-custom-switch`, `good-selected`.

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-standard` | Nothing: `FilledButton`, `SwitchListTile`, `CheckboxListTile` | Those widgets | none | R2: iOS Accessibility Traits | not custom |
| `good-cupertino` | An `Actions` for Enter on the web round the `CupertinoButton`; the switch merged with its text, with a `GestureDetector` | `CupertinoButton`, `CupertinoSwitch` | Enter on the web ([FL-002](flutter-limitations.md#fl-002)) | R2: iOS Accessibility Traits | custom |
| `good-custom-button` | A button drawn by hand: `Semantics(button: true, enabled: true)` round a `GestureDetector`, with focus, keys, and a focus ring of its own | None for a drawn control | none | R1, R4: iOS Accessibility Traits, WCAG technique ARIA4, WCAG failure F59, MDN: WAI-ARIA roles, Apple: UIAccessibilityTraits, Android: Role, iOS Accessibility Responds To User Interaction | custom |
| `good-custom-switch` | A switch drawn by hand: `Semantics(toggled:, enabled: true)` round a `GestureDetector`, with focus, keys, and a focus ring of its own | None for a drawn control | Dimmed without `enabled` ([FL-033](flutter-limitations.md#fl-033)) | R1, R5: iOS Accessibility Traits, WCAG technique ARIA4, WCAG failure F59, MDN: WAI-ARIA roles, Apple: UIAccessibilityTraits, Android: Role, WCAG 4.1.2 | custom |
| `good-selected` | Three buttons drawn by hand: `Semantics(button: true, enabled: true, selected:)`, with focus, keys, and a focus ring of their own | `SegmentedButton` | none | R1, R5: iOS Accessibility Traits, WCAG technique ARIA4, WCAG failure F59, MDN: WAI-ARIA roles, Apple: UIAccessibilityTraits, Android: Role, WCAG 4.1.2 | custom |

## S14 Values and state descriptions

Flagged: `good-rating`, `good-button-value`.

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-rating` | A star rating drawn by hand: `Semantics(label:, value:, increasedValue:, decreasedValue:, onIncrease:, onDecrease:)` round stars with no semantics, with the arrow keys from `FocusableActionDetector` | None: Flutter has no rating widget | No name on the web ([FL-028](flutter-limitations.md#fl-028)), not filled | R1, R2, R3, R4: iOS Accessibility Value, Apple: accessibilityValue, MDN: aria-valuetext | custom |
| `good-step` | A step indicator drawn by hand and described with `Semantics(label:, value:)`, its circles in `ExcludeSemantics`; it is not interactive | `Stepper` and the progress indicators (`semanticsValue:`) exist; none for this drawing | none | R1, R2, R3: iOS Accessibility Value, Apple: accessibilityValue, MDN: aria-valuetext | borderline: Like a label on an image, it only describes a drawing with documented properties, and nothing behaves; but it gives a hand-drawn indicator a value, where `Stepper` and the progress indicators have their own. |
| `good-button-value` | A button with three modes drawn by hand: `Semantics(button: true, label:, value:)`, with focus, keys, and a focus ring of its own | None for a drawn control | none | R1, R3: iOS Accessibility Value, Apple: accessibilityValue | custom |
| `good-slider-format` | Nothing: `Slider(semanticFormatterCallback:)`, merged with its text for its name | `Slider` | No name on the web ([FL-028](flutter-limitations.md#fl-028)), not filled | R2, R5, R6: iOS Accessibility Value, MDN: aria-valuetext, Android Compose Custom State Descriptions, Android View Custom State Descriptions, Android: View.setStateDescription | not custom |

## S15 Hints

Flagged: `good-cupertino`, `good-custom`.

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-result` | Nothing is built: `Semantics(hint:)` round `FilledButton.icon`, in `MergeSemantics` so that the hint is on the button | `FilledButton.icon` | A hint round a Material button stays on a node of its own ([FL-040](flutter-limitations.md#fl-040)), filled with the documented merge | R1, R2, R3, R4, R5: iOS Accessibility Hint, Apple: accessibilityHint | not custom |
| `good-row` | Nothing: `Semantics(hint:)` round `ListTile(onTap:)` | `ListTile` | none | R1, R2, R3: iOS Accessibility Hint, Apple: accessibilityHint | not custom |
| `good-cupertino` | An `Actions` for Enter on the web round the `CupertinoButton`; the hint itself is `Semantics(hint:)` | `CupertinoButton` | Enter on the web ([FL-002](flutter-limitations.md#fl-002)) | R1, R2, R3: iOS Accessibility Hint, Apple: accessibilityHint | custom |
| `good-custom` | A button drawn by hand: `Semantics(button: true, label:, hint:, onTap:)`, with Enter and Space from `FocusableActionDetector` and a focus ring of its own | None for a drawn control | none | R1, R2, R3: iOS Accessibility Hint, Apple: accessibilityHint | custom |
| `good-field` | Nothing: `Semantics(hint:)` round a `TextField`, and the rule as text | `TextField` | none | R6: iOS Accessibility Hint, MDN: aria-description | not custom |

## S22 Semantics identifiers for testing

Flagged: `good-cupertino`, `good-custom`.

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-merged` | `MergeSemantics` round `Semantics(identifier:)` round a `FilledButton`: the project's `TestId`, written out | `Semantics.identifier` | An identifier inside a button strips its name ([FL-007](flutter-limitations.md#fl-007)) or stays on a node of its own ([FL-043](flutter-limitations.md#fl-043)) | R1, R2, R4: iOS Accessibility Identifier, Apple: accessibilityIdentifier, Project rule | borderline: Two documented widgets and nothing that behaves; but the placement is the project's own rule for [FL-007](flutter-limitations.md#fl-007) and [FL-043](flutter-limitations.md#fl-043), the `TestId` that every example uses for its tests. |
| `good-cupertino` | An `Actions` for Enter on the web round the `CupertinoButton` | `CupertinoButton` | Enter on the web ([FL-002](flutter-limitations.md#fl-002)) | R1, R2, R4: iOS Accessibility Identifier, Apple: accessibilityIdentifier, Project rule | custom |
| `good-custom` | A button drawn by hand: `Semantics(button: true, label:, onTap:)`, with focus, keys, and a focus ring of its own | None for a drawn control | none | R1, R2, R4: iOS Accessibility Identifier, Apple: accessibilityIdentifier, Project rule | custom |
| `good-field` | `TestId` round a `TextField` | `Semantics.identifier` | As `good-merged` | R1, R2, R3, R4: iOS Accessibility Identifier, Apple: accessibilityIdentifier, Project rule | borderline: As `good-merged`: the project's `TestId` round a framework widget. |

## V13 Minimum touch target size

Flagged: `good-cupertino`, `good-custom`, `good-inline-link`.

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-material` | Nothing: `IconButton.filledTonal` with the theme's `MaterialTapTargetSize.padded` | `IconButton` | None filled (no padding in a desktop browser, [FL-412](flutter-limitations.md#fl-412), is left as it is) | R1, R2, R4: iOS: Touch Target Size, Android View: Minimum Touch Target Size, Android Compose: Minimum Touch Target Size, Android View and Android Compose, iOS, Android Compose | not custom |
| `good-cupertino` | An `Actions` for Enter on the web round each `CupertinoButton`; the size is the button's own `minimumSize` | `CupertinoButton` | Enter on the web ([FL-002](flutter-limitations.md#fl-002)) | R1, R2, R3: iOS: Touch Target Size, Android View: Minimum Touch Target Size, Android Compose: Minimum Touch Target Size, Android View and Android Compose, iOS, Android View, Android Compose | custom |
| `good-custom` | A button drawn by hand: an opaque `GestureDetector` round a 48 by 48 box, in `Semantics(button: true)`, with I01's focus and keys | None for a drawn control | The node can be bigger than the area that takes taps ([FL-410](flutter-limitations.md#fl-410)) | R1, R2, R3: iOS: Touch Target Size, Android View: Minimum Touch Target Size, Android Compose: Minimum Touch Target Size, Android View and Android Compose, iOS, Android View, Android Compose | custom |
| `good-inline-link` | A link in a sentence: `Semantics(link: true)` and an opaque `GestureDetector` in a `WidgetSpan`, with `FocusableActionDetector`, a `semanticsIdentifier` on the text before it, and a sort key | None: a `TextSpan` link takes no focus ([FL-240](flutter-limitations.md#fl-240)), and Flutter has no link widget ([FL-221](flutter-limitations.md#fl-221)) | The link is read after its sentence ([FL-413](flutter-limitations.md#fl-413)) | R5: iOS | custom |

## V14 Focus indicators

Flagged: `good-material`, `good-widgets`.

| Example | What is hand-built | Flutter widget for the pattern | Gap it fills | Source in the spec | Verdict |
| --- | --- | --- | --- | --- | --- |
| `good-material` | The tile's focus ring: a `Focus` that takes no focus hears the `CheckboxListTile`'s focus change and draws a `DecoratedBox`; the button's ring is its own `ButtonStyle.side` | `CheckboxListTile`, which has no style for a focus ring | A faint focus tint ([FL-430](flutter-limitations.md#fl-430)) | R1, R2, R3, R4: Android View: Custom Focus Indicators, Understanding 2.4.7, Android View and Android Compose: Custom Focus Indicators, Understanding 1.4.11, Android View, Android Compose | custom |
| `good-cupertino` | Nothing: `focusColor` on the `CupertinoSwitch` and the `CupertinoButton` | `CupertinoSwitch`, `CupertinoButton` | A pale default ring ([FL-431](flutter-limitations.md#fl-431)), filled with their own parameter | R1, R2, R3, R4: Android View: Custom Focus Indicators, Understanding 2.4.7, Android View and Android Compose: Custom Focus Indicators, Understanding 1.4.11, Android View, Android Compose | not custom |
| `good-widgets` | A card drawn by hand: focus, Enter, and Space from `FocusableActionDetector`, and its border drawn from `onShowFocusHighlight` | None for a drawn control | none | R1, R2, R3, R4: Android View: Custom Focus Indicators, Understanding 2.4.7, Android View and Android Compose: Custom Focus Indicators, Understanding 1.4.11, Android View, Android Compose | custom |
| `good-notice-below` | Nothing: the notice laid out under the scrolling box, and `TextButton`s with a focused `side` | `SingleChildScrollView`, `TextButton` | none | R5: Understanding 2.4.11, F110, C43 | not custom |
