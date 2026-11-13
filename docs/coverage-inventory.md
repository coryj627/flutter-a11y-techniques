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
  entries may become limitation entries under TEC-6.
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
| S07 | Landmarks and regions | ? | ? | ✓ | 1.3.1, 2.4.1 | Containers | — | — | Landmarks | `header`, `footer`, `main`, `nav`, `aside`, `section`, `article`, `search`, `form`, `address` |
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
| S18 | Pronunciation | ? | ? | ? | 3.1.6 (AAA, note only) | VoiceOverPronunciation | — | — | — | `ruby`, `rt`, `rp`, `abbr` |
| S19 | Inline text semantics | ? | ? | ? | 1.3.1 | AttributedStrings | — | — | — | `em`, `strong`, `mark`, `del`, `ins`, `s`, `sub`, `sup`, `code`, `kbd`, `samp`, `var`, `q`, `cite`, `dfn`, `time`, `data`, `small` |
| S20 | Block text structure | ? | ? | ? | 1.3.1 | — | — | — | — | `p`, `blockquote`, `pre`, `hr` |
| S21 | Custom content (extra detail on demand) | ✗ | ? | ✗ | 1.3.1 | AccessibilityCustomContent | — | — | — | — |
| S22 | Semantics identifiers for testing | ✓ | ✓ | ✓ | — (test enablement) | AccessibilityIdentifier | — | — | — | `id`, `data-testid` equivalents |

### 1.2 Visual presentation and preferences (V)

| ID | Technique | A | I | W | WCAG | iOS | View | Compose | APG | HTML |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| V01 | Colour contrast | ✓ | ✓ | ✓ | 1.4.3, 1.4.11, 1.4.1 | Contrast | — | — | — | — |
| V02 | High contrast preference | ✓ | ✓ | ✓ | 1.4.3 | IncreaseContrast | — | — | — | — |
| V03 | Dark and light themes | ✓ | ✓ | ✓ | 1.4.3, 1.4.11 | DarkMode | DarkTheme | DarkAndLightThemes | — | — |
| V04 | Inverted colours | ? | ? | ✗ | 1.4.1 | SmartInvert | — | — | — | — |
| V05 | Text scaling | ✓ | ✓ | ✓ | 1.4.4 | DynamicType | TextResizingAndReflow | — | — | — |
| V06 | Reflow and adaptive layout | ✓ | ✓ | ✓ | 1.4.10, 1.4.12 | ResponsiveLayouts | TextResizingAndReflow | AdaptiveLayouts | — | — |
| V07 | Device orientation | ✓ | ✓ | ✓ | 1.3.4 | DeviceOrientation | DeviceOrientation | — | — | — |
| V08 | Large content viewer | ✗ | ? | ✗ | 1.4.4 | LargeContentViewer | — | — | — | — |
| V09 | Reduced motion and animation control | ✓ | ✓ | ✓ | 2.2.2, 2.3.1 | ReduceMotion, DimFlashingLights | AnimationControl | — | — | — |
| V10 | Reduced transparency | ? | ? | ? | 1.4.3 | ReduceTransparency | — | — | — | — |
| V11 | Button shapes and borders | ? | ? | ✗ | 1.4.1, 1.4.11 | ShowBorders | — | — | — | — |
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
| I05 | Custom accessibility actions | ✓ | ✓ | ? | 2.1.1, 2.5.1, 2.5.7 | AccessibilityActions, SwipeActions | CustomAccessibilityActions | CustomAccessibilityActions | — | — |
| I06 | Action labels | ✓ | ? | ✗ | 4.1.2 | — | AccessibilityActionLabels | CustomClickLabels | — | — |
| I07 | Adjustable (increase / decrease) | ✓ | ✓ | ✓ | 4.1.2 | AdjustableAction | — | — | — | — |
| I08 | Dismiss and escape | ✓ | ✓ | ✓ | 2.1.2 | EscapeAction | — | — | — | — |
| I09 | Magic Tap | ✗ | ? | ✗ | — | MagicTap | — | — | — | — |
| I10 | Rotor | ✗ | ? | ✗ | 2.4.1 | Rotor | — | — | — | — |
| I11 | Voice input labels | ? | ? | ✓ | 2.5.3 | AccessibilityInputLabels | — | — | — | — |
| I12 | Announcements and live regions | ✓ | ✓ | ✓ | 4.1.3 | AccessibilityNotifications | UXChangeAnnouncements | UXChangeAnnouncements | Alert | `output` |
| I13 | Drag and drop alternatives | ✓ | ✓ | ✓ | 2.5.7, 2.1.1 | DragDrop | — | — | — | `draggable` equivalents |
| I14 | Scrolling regions | ✓ | ✓ | ✓ | 2.1.1, 1.4.10 | ScrollViews, HorizontalScrollViews | — | ScrollingColumns | — | — |
| I15 | Navigation structure | ✓ | ✓ | ✓ | 2.4.1, 3.2.3 | Navigation | — | NavigationBarLayouts | — | `nav` |
| I16 | Breadcrumb | ✓ | ✓ | ✓ | 2.4.8 (AAA), 1.3.1 | — | — | — | Breadcrumb | `nav`, `ol` |
| I17 | Assistive Access mode | ✗ | ? | ✗ | — | AssistiveAccess | — | — | — | — |

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
| C15 | Menubar | ? | ? | ✓ | 4.1.2, 2.1.1 | — | — | — | Menu and Menubar | — |
| C16 | Toolbar | ✓ | ✓ | ✓ | 4.1.2, 2.1.1 | Toolbars | — | — | Toolbar | — |
| C17 | Carousel | ✓ | ✓ | ✓ | 2.2.2, 4.1.2 | Carousels | — | — | Carousel | — |
| C18 | Card | ✓ | ✓ | ✓ | 1.3.1, 2.4.4 | Cards | — | — | — | `article` |
| C19 | Data table | ? | ? | ✓ | 1.3.1 | DataTables | — | — | Table | `table`, `caption`, `thead`, `tbody`, `tfoot`, `tr`, `th`, `td`, `col`, `colgroup` |
| C20 | Interactive grid | ? | ? | ? | 4.1.2, 2.1.1 | — | — | — | Grid | — |
| C21 | Tree view | ? | ? | ? | 4.1.2, 2.1.1 | — | — | — | Tree View | — |
| C22 | Treegrid | ? | ? | ? | 4.1.2, 2.1.1 | — | — | — | Treegrid | — |
| C23 | Feed | ? | ? | ? | 1.3.1, 2.1.1 | — | — | — | Feed | `article` |
| C24 | Window splitter | ? | ? | ? | 4.1.2, 2.5.7 | — | — | — | Window Splitter | — |
| C25 | Meter | ? | ? | ? | 4.1.2, 1.1.1 | — | — | — | Meter | `meter` |
| C26 | Progress indicator | ✓ | ✓ | ✓ | 4.1.2, 4.1.3 | ProgressIndicators | — | — | — | `progress` |
| C27 | Charts | ✓ | ✓ | ✓ | 1.1.1, 1.4.1 | Charts | — | — | — | `canvas`, `svg` |
| C28 | Maps | ? | ? | ? | 1.1.1, 2.5.1 | Maps | — | — | — | — |
| C29 | Video and audio | ? | ? | ? | 1.2.1–1.2.5, 1.4.2 | Videos | — | — | — | `video`, `audio`, `track`, `source` |
| C30 | Embedded web and platform views | ? | ? | ? | 4.1.2, 1.4.4 | WebViewDynamicType | — | — | — | `iframe`, `embed`, `object` |
| C31 | Math content | ? | ? | ? | 1.1.1, 1.3.1 | — | — | — | — | `math` |

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
