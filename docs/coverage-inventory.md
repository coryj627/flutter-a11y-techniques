# Coverage Inventory

Status: Draft 1 (2026-11-12). Satisfies requirement CAT-5 in
[requirements.md](requirements.md).

This maps every source item to a proposed catalog entry, or to a recorded reason
it is not a technique.

## How to read this

- **Sources were inventoried by document title only.** The CVS documents
  themselves have not been read yet, so mappings may shift when each technique is
  specified.
- **WCAG mappings are provisional** and get confirmed against
  [WCAG 2.2](https://www.w3.org/TR/WCAG22/) in each technique spec.
- **Platform columns (A / I / W)** are the expected applicability for Android,
  iOS, and Web. `?` means Flutter feasibility is unknown and must be tested; such
  entries may become limitation entries under TEC-6. The 27 entries that had
  a `?` were probed in batch 0 (section 5).
- Nothing here asserts that Flutter can do a given thing. That is established per
  technique.

### Sources

| Key | Source | License | Items |
| --- | --- | --- | --- |
| iOS | [cvs-health/ios-swiftui-accessibility-techniques](https://github.com/cvs-health/ios-swiftui-accessibility-techniques) `iOSswiftUIa11yTechniques/Documentation/` | Apache-2.0 | 90 docs |
| View | [cvs-health/android-view-accessibility-techniques](https://github.com/cvs-health/android-view-accessibility-techniques) `doc/` | Apache-2.0 | 31 docs |
| Compose | [cvs-health/android-compose-accessibility-techniques](https://github.com/cvs-health/android-compose-accessibility-techniques) `doc/` | Apache-2.0 | 37 docs |
| APG | [ARIA APG patterns](https://www.w3.org/WAI/ARIA/apg/patterns/) | W3C | 30 patterns |
| HTML | [MDN HTML elements reference](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements) | CC-BY-SA | all elements |

The CVS repositories are Apache-2.0 and this repository is MIT. Adapting their
text or code requires attribution and license notices (DOC-7). This project has
no material connection to CVS Health.

## 1. Proposed catalog

102 entries in five groups.

### 1.1 Semantics and content (S)

| ID | Technique | A | I | W | WCAG | iOS | View | Compose | APG | HTML |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| S01 | Accessible names | ✓ | ✓ | ✓ | 4.1.2, 2.4.6 | AccessibilityLabel, MeaningfulAccessibleNames | — | InteractiveControlLabels | — | `label` |
| S02 | Informative images | ✓ | ✓ | ✓ | 1.1.1 | Images, InformativeImages | TextAlternatives | TextAlternatives | — | `img`, `picture`, `figure`, `figcaption`, `svg` |
| S03 | Decorative images | ✓ | ✓ | ✓ | 1.1.1 | DecorativeImages | TextAlternatives | TextAlternatives | — | `img` (empty alt) |
| S04 | Functional images | ✓ | ✓ | ✓ | 1.1.1, 4.1.2 | FunctionalImages | TextAlternatives | TextAlternatives | — | `img` in `a`/`button`, `area`, `map` |
| S05 | Headings | ✓ | ✓ | ✓ | 1.3.1, 2.4.6 | Headings | HeadingSemantics | HeadingSemantics | — | `h1`–`h6`, `hgroup` |
| S06 | Screen and page titles | ✓ | ✓ | ✓ | 2.4.2 | PageTitles | — | ScreenAndPaneTitles | — | `title` |
| S07 | Landmarks and regions | ✗ | ✗ | ✓ | 1.3.1, 2.4.1 | Containers | — | — | Landmarks | `header`, `footer`, `main`, `nav`, `aside`, `section`, `article`, `search`, `form`, `address` |
| S08 | List semantics | ✓ | ✓ | ✓ | 1.3.1 | Lists | ListSemantics | ListSemantics, ListItemLayouts | — | `ul`, `ol`, `li`, `dl`, `dt`, `dd`, `menu` |
| S09 | Content grouping | ✓ | ✓ | ✓ | 1.3.1 | CombiningFocus, GroupingControls, Cards | ContentGrouping, TapTargetGrouping | ContentGrouping | — | `fieldset`, `legend` |
| S10 | Content group replacement | ✓ | ✓ | ✓ | 1.3.1, 4.1.2 | AccessibilityRepresentation | ContentGroupReplacement | ContentGroupReplacement | — | — |
| S11 | Reading and traversal order | ✓ | ✓ | ✓ | 1.3.2, 2.4.3 | ReadingOrder, AccessibilitySortPriority | AccessibilityReadingOrder | AccessibilityTraversalOrder | — | — |
| S12 | Hiding content from AT | ✓ | ✓ | ✓ | 1.3.1, 4.1.2 | AccessibilityHidden | — | — | — | `hidden`, `aria-hidden` equivalents |
| S13 | Roles and traits | ✓ | ✓ | ✓ | 4.1.2 | AccessibilityTraits, AccessibilityRespondsToUserInteraction | — | — | — | — |
| S14 | Values and state descriptions | ✓ | ✓ | ✓ | 4.1.2 | AccessibilityValue | CustomStateDescriptions | CustomStateDescriptions | — | — |
| S15 | Hints | ✓ | ✓ | ✓ | 3.3.2 | AccessibilityHint | — | — | — | — |
| S16 | Language of page and parts | ✓ | ✓ | ✓ | 3.1.1, 3.1.2 | Language, AttributedStrings | TextLanguageIdentification | — | — | `lang` on `html` and parts |
| S17 | Text direction and RTL layout | ✓ | ✓ | ✓ | 1.3.2 | — | — | — | — | `bdi`, `bdo`, `dir` |
| S18 | Pronunciation | ✓ | ? | ✗ | 3.1.6 (AAA, note only) | VoiceOverPronunciation | — | — | — | `ruby`, `rt`, `rp`, `abbr` |
| S19 | Inline text semantics | ✗ | ✗ | ? | 1.3.1 | AttributedStrings | — | — | — | `em`, `strong`, `mark`, `del`, `ins`, `s`, `sub`, `sup`, `code`, `kbd`, `samp`, `var`, `q`, `cite`, `dfn`, `time`, `data`, `small` |
| S20 | Block text structure | ✗ | ✗ | ? | 1.3.1 | — | — | — | — | `p`, `blockquote`, `pre`, `hr` |
| S21 | Custom content (extra detail on demand) | ✗ | ✗ | ✗ | 1.3.1 | AccessibilityCustomContent | — | — | — | — |
| S22 | Semantics identifiers for testing | ✓ | ✓ | ✓ | — (test enablement) | AccessibilityIdentifier | — | — | — | `id`, `data-testid` equivalents |

### 1.2 Visual presentation and preferences (V)

| ID | Technique | A | I | W | WCAG | iOS | View | Compose | APG | HTML |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| V01 | Colour contrast | ✓ | ✓ | ✓ | 1.4.3, 1.4.11, 1.4.1 | Contrast | — | — | — | — |
| V02 | High contrast preference | ✓ | ✓ | ✓ | 1.4.3 | IncreaseContrast | — | — | — | — |
| V03 | Dark and light themes | ✓ | ✓ | ✓ | 1.4.3, 1.4.11 | DarkMode | DarkTheme | DarkAndLightThemes | — | — |
| V04 | Inverted colours | ✗ | ? | ✗ | 1.4.1 | SmartInvert | — | — | — | — |
| V05 | Text scaling | ✓ | ✓ | ✓ | 1.4.4 | DynamicType | TextResizingAndReflow | — | — | — |
| V06 | Reflow and adaptive layout | ✓ | ✓ | ✓ | 1.4.10, 1.4.12 | ResponsiveLayouts | TextResizingAndReflow | AdaptiveLayouts | — | — |
| V07 | Device orientation | ✓ | ✓ | ✓ | 1.3.4 | DeviceOrientation | DeviceOrientation | — | — | — |
| V08 | Large content viewer | ✗ | ✗ | ✗ | 1.4.4 | LargeContentViewer | — | — | — | — |
| V09 | Reduced motion and animation control | ✓ | ✓ | ✓ | 2.2.2, 2.3.1 | ReduceMotion, DimFlashingLights | AnimationControl | — | — | — |
| V10 | Reduced transparency | ✗ | ✗ | ✗ | 1.4.3 | ReduceTransparency | — | — | — | — |
| V11 | Button shapes and borders | ✗ | ✗ | ✗ | 1.4.1, 1.4.11 | ShowBorders | — | — | — | — |
| V12 | Detecting accessibility settings | ✓ | ✓ | ✓ | — (enabler) | AccessibilityDetection | — | — | — | — |
| V13 | Minimum touch target size | ✓ | ✓ | ✓ | 2.5.8 | TouchTargetSize | MinimumTouchTargetSize | MinimumTouchTargetSize | — | — |
| V14 | Focus indicators | ✓ | ✓ | ✓ | 2.4.7, 2.4.11, 1.4.11 | — | CustomFocusIndicators | CustomFocusIndicators | — | — |

### 1.3 Interaction and input (I)

| ID | Technique | A | I | W | WCAG | iOS | View | Compose | APG | HTML |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| I01 | Focusable and clickable controls | ✓ | ✓ | ✓ | 2.1.1, 4.1.2 | — | FocusableClickableControls | — | — | — |
| I02 | Keyboard focus order | ✓ | ✓ | ✓ | 2.4.3, 2.1.1 | — | KeyboardAndAccessibilityFocusOrder, ArrowKeyFocusOrder | KeyboardFocusOrder | — | `tabindex` equivalents |
| I03 | Focus management | ✓ | ✓ | ✓ | 2.4.3, 3.2.1 | FocusManagement | — | — | — | — |
| I04 | Keyboard actions and shortcuts | ✓ | ✓ | ✓ | 2.1.1, 2.1.4 | — | — | KeyboardActions | — | `accesskey` equivalents |
| I05 | Custom accessibility actions | ✓ | ✓ | ✗ | 2.1.1, 2.5.1, 2.5.7 | AccessibilityActions, SwipeActions | CustomAccessibilityActions | CustomAccessibilityActions | — | — |
| I06 | Action labels | ✓ | ✗ | ✗ | 4.1.2 | — | AccessibilityActionLabels | CustomClickLabels | — | — |
| I07 | Adjustable (increase / decrease) | ✓ | ✓ | ✓ | 4.1.2 | AdjustableAction | — | — | — | — |
| I08 | Dismiss and escape | ✓ | ✓ | ✓ | 2.1.2 | EscapeAction | — | — | — | — |
| I09 | Magic Tap | ✗ | ✗ | ✗ | — | MagicTap | — | — | — | — |
| I10 | Rotor | ✗ | ✗ | ✗ | 2.4.1 | Rotor | — | — | — | — |
| I11 | Voice input labels | ✗ | ✗ | ✓ | 2.5.3 | AccessibilityInputLabels | — | — | — | — |
| I12 | Announcements and live regions | ✓ | ✓ | ✓ | 4.1.3 | AccessibilityNotifications | UXChangeAnnouncements | UXChangeAnnouncements | Alert | `output` |
| I13 | Drag and drop alternatives | ✓ | ✓ | ✓ | 2.5.7, 2.1.1 | DragDrop | — | — | — | `draggable` equivalents |
| I14 | Scrolling regions | ✓ | ✓ | ✓ | 2.1.1, 1.4.10 | ScrollViews, HorizontalScrollViews | — | ScrollingColumns | — | — |
| I15 | Navigation structure | ✓ | ✓ | ✓ | 2.4.1, 3.2.3 | Navigation | — | NavigationBarLayouts | — | `nav` |
| I16 | Breadcrumb | ✓ | ✓ | ✓ | 2.4.8 (AAA), 1.3.1 | — | — | — | Breadcrumb | `nav`, `ol` |
| I17 | Assistive Access mode | ✗ | ✗ | ✗ | — | AssistiveAccess | — | — | — | — |

### 1.4 Forms (F)

| ID | Technique | A | I | W | WCAG | iOS | View | Compose | APG | HTML |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| F01 | Text fields and labels | ✓ | ✓ | ✓ | 1.3.1, 3.3.2, 4.1.2 | TextFields | InputFieldLabels | TextFieldControls | — | `input`, `textarea`, `label` |
| F02 | Input instructions | ✓ | ✓ | ✓ | 3.3.2 | InputInstructions | — | — | — | `aria-describedby` equivalents |
| F03 | Keyboard types | ✓ | ✓ | ✓ | 1.3.5 | — | KeyboardTypes | KeyboardTypes | — | `input type`, `inputmode` |
| F04 | Autofill and input purpose | ✓ | ✓ | ✓ | 1.3.5 | — | AutofillInputFields | AutofillControls | — | `autocomplete` |
| F05 | Redundant entry | ✓ | ✓ | ✓ | 3.3.7 | RedundantEntry | — | — | — | — |
| F06 | Error identification and announcement | ✓ | ✓ | ✓ | 3.3.1, 3.3.3, 4.1.3 | ErrorValidation | InputErrorAnnouncements | — | — | `aria-invalid` equivalents |
| F07 | Checkbox | ✓ | ✓ | ✓ | 4.1.2 | Checkboxes | — | CheckboxControls | Checkbox | `input type=checkbox` |
| F08 | Radio group | ✓ | ✓ | ✓ | 4.1.2, 1.3.1 | RadioButtons | — | RadioButtonGroups | Radio Group | `input type=radio`, `fieldset` |
| F09 | Switch | ✓ | ✓ | ✓ | 4.1.2 | Toggles | — | SwitchControls | Switch | — |
| F10 | Slider | ✓ | ✓ | ✓ | 4.1.2, 2.5.7 | Sliders | — | SliderAndRangeSliderControls | Slider | `input type=range` |
| F11 | Multi-thumb (range) slider | ✓ | ✓ | ✓ | 4.1.2, 2.5.7 | — | — | SliderAndRangeSliderControls | Slider (Multi-Thumb) | — |
| F12 | Stepper / spinbutton | ✓ | ✓ | ✓ | 4.1.2 | Steppers | — | — | Spinbutton | `input type=number` |
| F13 | Select, picker, and listbox | ✓ | ✓ | ✓ | 4.1.2 | Pickers | DropdownSelectionMenus | — | Listbox | `select`, `option`, `optgroup` |
| F14 | Multi-selection list | ✓ | ✓ | ✓ | 4.1.2 | MultiSelectionLists | — | — | Listbox | `select multiple` |
| F15 | Combobox and autocomplete | ✓ | ✓ | ✓ | 4.1.2, 4.1.3 | SearchSuggestions | AutocompleteInputControls | ExposedDropdownMenus | Combobox | `datalist`, `input list` |
| F16 | Date and time pickers | ✓ | ✓ | ✓ | 4.1.2, 2.1.1 | DateTimePickers | — | — | (Dialog date picker example) | `input type=date/time` |
| F17 | Segmented control | ✓ | ✓ | ✓ | 4.1.2 | SegmentedControls | — | — | — | — |
| F18 | Rating control | ✓ | ✓ | ✓ | 4.1.2 | — | RatingBarControls | — | — | — |

### 1.5 Components (C)

| ID | Technique | A | I | W | WCAG | iOS | View | Compose | APG | HTML |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| C01 | Button | ✓ | ✓ | ✓ | 4.1.2, 2.1.1 | Buttons | — | — | Button | `button`, `input type=button/submit` |
| C02 | Toggle button | ✓ | ✓ | ✓ | 4.1.2 | Buttons | — | — | Button | — |
| C03 | Stand-alone link | ✓ | ✓ | ✓ | 2.4.4, 4.1.2 | Links | — | StandAloneLinks | Link | `a` |
| C04 | Links inline with text | ✓ | ✓ | ✓ | 2.4.4, 1.4.1 | Links | LinksInlineWithText | LinksInlineWithText | Link | `a` |
| C05 | Accordion | ✓ | ✓ | ✓ | 4.1.2, 1.3.1 | Accordions | AccordionControls | AccordionControls | Accordion | — |
| C06 | Disclosure | ✓ | ✓ | ✓ | 4.1.2 | — | — | — | Disclosure | `details`, `summary` |
| C07 | Tabs | ✓ | ✓ | ✓ | 4.1.2, 1.3.1 | Tabs | — | TabRows | Tabs | — |
| C08 | Modal dialog | ✓ | ✓ | ✓ | 4.1.2, 2.4.3, 2.1.2 | — | — | — | Dialog (Modal) | `dialog` |
| C09 | Alert and confirmation dialog | ✓ | ✓ | ✓ | 4.1.2, 2.4.3 | Alerts, ConfirmationDialogs | — | — | Alert and Message Dialogs | `dialog` |
| C10 | Bottom sheet | ✓ | ✓ | ✓ | 4.1.2, 2.4.3 | Sheets | — | ModalBottomSheetLayouts | Dialog (Modal) | — |
| C11 | Popover | ✓ | ✓ | ✓ | 4.1.2, 1.4.13 | Popovers | — | — | — | `popover` equivalents |
| C12 | Tooltip | ✓ | ✓ | ✓ | 1.4.13, 4.1.2 | TipKit | — | — | Tooltip | `title` attribute equivalents |
| C13 | Snackbar and transient messages | ✓ | ✓ | ✓ | 4.1.3, 2.2.1 | — | — | PopupMessages | Alert | — |
| C14 | Menu and menu button | ✓ | ✓ | ✓ | 4.1.2, 2.1.1 | Menus | — | DropdownMenus | Menu Button | — |
| C15 | Menubar | ? | ? | ? | 4.1.2, 2.1.1 | — | — | — | Menu and Menubar | — |
| C16 | Toolbar | ✓ | ✓ | ✓ | 4.1.2, 2.1.1 | Toolbars | — | — | Toolbar | — |
| C17 | Carousel | ✓ | ✓ | ✓ | 2.2.2, 4.1.2 | Carousels | — | — | Carousel | — |
| C18 | Card | ✓ | ✓ | ✓ | 1.3.1, 2.4.4 | Cards | — | — | — | `article` |
| C19 | Data table | ✗ | ✗ | ✓ | 1.3.1 | DataTables | — | — | Table | `table`, `caption`, `thead`, `tbody`, `tfoot`, `tr`, `th`, `td`, `col`, `colgroup` |
| C20 | Interactive grid | ✗ | ✗ | ? | 4.1.2, 2.1.1 | — | — | — | Grid | — |
| C21 | Tree view | ✗ | ✗ | ? | 4.1.2, 2.1.1 | — | — | — | Tree View | — |
| C22 | Treegrid | ✗ | ✗ | ? | 4.1.2, 2.1.1 | — | — | — | Treegrid | — |
| C23 | Feed | ✗ | ✗ | ? | 1.3.1, 2.1.1 | — | — | — | Feed | `article` |
| C24 | Window splitter | ✗ | ✗ | ? | 4.1.2, 2.5.7 | — | — | — | Window Splitter | — |
| C25 | Meter | ✗ | ✗ | ? | 4.1.2, 1.1.1 | — | — | — | Meter | `meter` |
| C26 | Progress indicator | ✓ | ✓ | ✓ | 4.1.2, 4.1.3 | ProgressIndicators | — | — | — | `progress` |
| C27 | Charts | ✓ | ✓ | ✓ | 1.1.1, 1.4.1 | Charts | — | — | — | `canvas`, `svg` |
| C28 | Maps | ? | ? | ? | 1.1.1, 2.5.1 | Maps | — | — | — | — |
| C29 | Video and audio | ? | ? | ? | 1.2.1–1.2.5, 1.4.2 | Videos | — | — | — | `video`, `audio`, `track`, `source` |
| C30 | Embedded web and platform views | ? | ? | ? | 4.1.2, 1.4.4 | WebViewDynamicType | — | — | — | `iframe`, `embed`, `object` |
| C31 | Math content | ✗ | ✗ | ? | 1.1.1, 1.3.1 | — | — | — | — | `math` |

## 2. Source items that are not techniques

### 2.1 CVS tooling and testing documents

These inform the validation harness (VAL-1 to VAL-5), not the catalog.

| Source | Document | Feeds |
| --- | --- | --- |
| iOS | A11yCheck | Static and audit checks |
| iOS | SwiftLint | Lint rules |
| iOS | XCTestAccessibility | XCUITest layer (VAL-2) |
| iOS | VoiceOverAutomationTesting | Screen reader automation (VAL-4) |
| View | EspressoAutomatedAccessibilityTesting | Espresso layer (VAL-2) |
| Compose | AutomatedComposeAccessibilityTesting | Flutter-stack test approach (VAL-1) |

Repository housekeeping files (README, CONTRIBUTING, ARCHITECTURE, CHANGELOG,
AppStore, CLAUDE, SKILL files, a11y-check READMEs, `.todos.md`, pull request
template) are not techniques.

### 2.2 HTML elements with no technique

| Elements | Reason |
| --- | --- |
| `html`, `head`, `body`, `base`, `link`, `meta`, `style` | Document plumbing. `lang` and `title` are covered by S16 and S06. |
| `script`, `noscript`, `template`, `slot` | Scripting and web components; no user-facing semantics. |
| `div`, `span`, `br`, `wbr` | No semantics. |
| `b`, `i`, `u` | Presentational; no accessibility semantics exposed. |
| `selectedcontent`, `geolocation` | New or experimental; revisit when stable. |
| `acronym`, `big`, `center`, `content`, `dir`, `fencedframe`, `font`, `frame`, `frameset`, `image`, `marquee`, `menuitem`, `nobr`, `noembed`, `noframes`, `param`, `plaintext`, `rb`, `rtc`, `shadow`, `strike`, `tt`, `xmp` | Obsolete or deprecated. |

## 3. Coverage check

- **CVS iOS:** 86 technique docs mapped to catalog entries; 4 tooling docs in 2.1.
- **CVS Android View:** 30 technique docs mapped; 1 tooling doc in 2.1.
- **CVS Android Compose:** 36 technique docs mapped; 1 tooling doc in 2.1.
- **APG:** all 30 patterns mapped.
- **HTML:** every element on the MDN reference is either mapped or listed in 2.2.

## 4. Observations for planning

1. **Unknown feasibility is concentrated.** 27 entries carry a `?` on at least one
   platform. The heaviest are the APG desktop-style widgets (grid, tree view,
   treegrid, feed, window splitter, menubar, meter), iOS-specific features
   (Rotor, Magic Tap, custom content, large content viewer, Assistive Access),
   text-level semantics (S18–S20), and media and embeds (C28–C31).
2. **Landmarks, tables, and inline text semantics on mobile** are the likeliest
   limitation entries and worth probing early, since many other techniques
   reference them.
3. **Vertical slice candidates** (DEL-1) that touch all three CVS repos, APG, and
   HTML: C01 Button, S05 Headings, F01 Text fields and labels. Adding I12
   Announcements would exercise the screen reader speech gate.
4. **Cupertino variants** are expected mainly in the F and C groups (switch,
   slider, picker, date picker, segmented control, dialogs, sheets).

## 5. Batch 0: probes of the 27 unknown entries

Done on 2026-11-13 with Flutter 3.47.5: Chromium (Playwright), Android 17
emulator, and iPhone 17 simulator on iOS 27.0 with VoiceOver. One fixture per
SDK mechanism on a throwaway screen; where the SDK has no mechanism, the SDK
and the iOS engine source were searched instead. The fixture source and the
raw output are in [evidence/probes/batch-0](evidence/probes/batch-0/). The
A / I / W columns above now carry the result; a `?` that remains is explained
here.

For S19, S20, C20 to C25, and C31 the web column stays `?`. Flutter's
`Semantics` API has no mechanism for them, but on web the SDK can embed native
HTML with `HtmlElementView`, and that route was not probed. Whether it counts
as a Flutter technique is an open question for the owner.

These are probe results, not verified techniques. Each entry that is built
gets its full spec and tests, and may change again.

| ID | Technique | Outcome | What was found |
| --- | --- | --- | --- |
| S07 | Landmarks and regions | Build, web; limitation on mobile | `SemanticsRole.main`, `navigation`, `complementary`, `contentInfo`, `region`, and `form` become ARIA landmarks on web. Android and iOS expose a plain node; a labelled landmark becomes an extra stop that reads only its label. FL-019 |
| S18 | Pronunciation | Build | `SpellOutStringAttribute` reaches Android as a `TtsSpan`, and `LocaleStringAttribute` and `localeForSubtree` as a `LocaleSpan`. On iOS the engine sets an attributed label; whether speech changes was not confirmed. On web only `localeForSubtree` has an effect, and it writes `lang="fr_FR"`. FL-020 |
| S19 | Inline text semantics | Limitation entry (`Semantics` API) | A `Text.rich` with bold and struck-through spans is one plain string on every platform. No SDK mechanism for emphasis, deletion, sub or superscript, code. FL-021 |
| S20 | Block text structure | Limitation entry (`Semantics` API) | No SDK mechanism for paragraph, quotation, preformatted text, or a separator. `Divider` exposes an empty node. FL-021 |
| S21 | Custom content (extra detail on demand) | Limitation entry | No Flutter API, and the iOS engine does not implement `accessibilityCustomContent`. FL-025 |
| V04 | Inverted colours | Build, iOS, small | `MediaQuery.invertColors` exists and is documented as iOS only. There is no way to exclude an image from inversion (`accessibilityIgnoresInvertColors` is not in the engine). Not toggled on the simulator in this probe. FL-025 |
| V08 | Large content viewer | Limitation entry | No Flutter API for the iOS large content viewer. FL-025 |
| V10 | Reduced transparency | Limitation entry | `AccessibilityFeatures` has no reduce-transparency flag. FL-025 |
| V11 | Button shapes and borders | Limitation entry | `AccessibilityFeatures` has no button-shapes flag. FL-025 |
| I05 | Custom accessibility actions | Build; limitation on web | `customSemanticsActions` gives labelled actions on Android and "Actions available" in VoiceOver on iOS. Nothing reaches the DOM on web. FL-022 |
| I06 | Action labels | Build, Android | `onTapHint` and `onLongPressHint` label the click and long-click actions on Android. VoiceOver on iOS read no hint, and nothing reaches the DOM on web |
| I09 | Magic Tap | Limitation entry | The iOS engine does not implement `accessibilityPerformMagicTap`. FL-025 |
| I10 | Rotor | Limitation entry | No custom rotors in the iOS engine. The built-in headings rotor is covered by S05. FL-025 |
| I11 | Voice input labels | Fold into label-in-name checks | No API for iOS `accessibilityUserInputLabels`. What can be done is WCAG 2.5.3, already asserted per component. FL-025 |
| I17 | Assistive Access mode | Not applicable | Assistive Access is a native app mode set up in the native scene and Info.plist, not something a Flutter widget does |
| C15 | Menubar | Build, expect limitations | `MenuBar`, `SubmenuButton`, and `MenuItemButton` do not use the menu roles: on web a group of buttons, items as button, checkbox, and radio; on Android and iOS the items have no button role. `SemanticsRole.menuBar`, `menu`, and `menuItem` exist but were not probed. FL-023 |
| C19 | Data table | Build, web; limitation on mobile | `DataTable` is `table`, `row`, `columnheader`, `cell` on web. A plain `Table` of `Text` cells has no headers; marking one with `SemanticsRole.columnHeader` was read in the source and not probed. Android has no collection information and iOS only the cell text. FL-024 |
| C20 | Interactive grid | Limitation entry (`Semantics` API) | No grid role in `SemanticsRole`. FL-026 |
| C21 | Tree view | Limitation entry (`Semantics` API) | `TreeSliver` rows are buttons with no tree role, level, or expanded state on any platform. FL-026 |
| C22 | Treegrid | Limitation entry (`Semantics` API) | No treegrid role. FL-026 |
| C23 | Feed | Limitation entry (`Semantics` API) | No feed or article role. FL-026 |
| C24 | Window splitter | Limitation entry (`Semantics` API) | No separator role. Slider semantics give an adjustable control on all three platforms (`SeekBar`, `role="slider"`), which is a slider, not a splitter. FL-026 |
| C25 | Meter | Limitation entry; see the progress entry | No meter role. `SemanticsRole.progressBar` with `minValue` and `maxValue` is a progress bar on web and Android, which is a different thing from a meter. FL-026, FL-027 |
| C28 | Maps | Owner decision: needs a plugin | Nothing in the SDK. `google_maps_flutter` is a platform view |
| C29 | Video and audio | Owner decision: needs a plugin | Nothing in the SDK plays media; `video_player` does. The SDK does report `autoPlayVideos` and `autoPlayAnimatedImages` |
| C30 | Embedded web and platform views | Owner decision: needs a plugin off the web | `HtmlElementView` is in the SDK for web; its content was not reachable from the page DOM in this probe. Mobile needs `webview_flutter` |
| C31 | Math content | Limitation entry (`Semantics` API) | No math semantics. Only a text alternative is possible, which S02 covers. FL-026 |

Totals: 7 to build (S07, S18, V04, I05, I06, C15, C19); 15 limitation
entries, which under TEC-6 stay in the catalog with the gap documented and the
closest achievable example where there is one; 1 not applicable (I17); 1
folded into existing checks (I11); and 3 that need a plugin from outside the
SDK (C28, C29, C30). Whether first-party plugins such as `video_player` and
`webview_flutter` are in scope is a decision for the owner.
