# Flutter framework limitations log

Every accessibility issue or surprising behaviour found in the Flutter
framework while building this project, in one place. Technique docs link here
instead of repeating the detail. This log is the source for the limitation
pages in the final documentation.

Rules for this file:

- One entry per behaviour, with a stable id (`FL-nnn`). Ids are never reused.
- Record what was observed and how, not a guess at the cause, unless the SDK
  source was read; say which.
- Record the Flutter version. Re-check every open entry when the pin changes
  (currently 3.47.5, see `.fvmrc`).
- Test-tool problems (Guidepup, XCUITest, Espresso, TalkBack logging) are not
  framework issues. They are in [plan.md](plan.md).

Ids are taken from ranges, so that work going on at the same time never
picks the same id:

| Ids | For |
| --- | --- |
| FL-001 to FL-047 | Entries from before the ranges |
| FL-048 to FL-069 | Work outside the waves |
| FL-070 to FL-099 | Wave 10, the limitation entries |
| FL-N00 to FL-N99 | Wave N, for N from 1 to 9: FL-100 to FL-199 for wave 1, FL-200 to FL-299 for wave 2, and so on |

The waves are: 1 forms, 2 links and simple components, 3 structure and
order, 4 focus and keyboard, 5 visual preferences, 6 remaining forms, 7
dialogs and overlays, 8 navigation and complex components, 9 the batch 10
techniques, 10 the limitation entries. Ids stay three digits and are never
reused. Use the next free id in your range.

The index and the entries are both in id order, and each range has a place
of its own in each: in the index, the rows after the range's bold row; in
the entries, the entries after the range's comment line. Add a new entry
at the end of its range in both, so that two changes in different ranges
never touch the same lines. `test/docs/flutter_limitations_test.dart`
checks the ids, the ranges, and that the index matches the entries.

Status values: **Confirmed** (reproduced by an automated test in this repo, or
read in the SDK source), **Observed** (seen in a spike, no test in the repo
yet), **Fixed in x.y** (verified on that version).

| Id | Summary | Platforms | Status |
| --- | --- | --- | --- |
| [FL-001](#fl-001) | Disabled `CupertinoButton` reports no disabled state | All | Confirmed |
| [FL-002](#fl-002) | Enter does not activate a `CupertinoButton` on web | Web | Confirmed |
| [FL-003](#fl-003) | `Semantics(header: true)` alone is not a heading for VoiceOver on iOS | iOS | Confirmed |
| [FL-004](#fl-004) | `header: true` on web is always `<h2>` | Web | Confirmed |
| [FL-005](#fl-005) | `header: true` alone is not a heading on Android, except directly in a list | Android | Confirmed |
| [FL-006](#fl-006) | Any tappable node is `role="button"` on web | Web | Confirmed |
| [FL-007](#fl-007) | `Semantics(identifier:)` inside a button strips the button's name | Android, iOS | Confirmed |
| [FL-008](#fl-008) | `IconButton` tooltip is read as a second item by VoiceOver in Chromium | Web (Chromium) | Observed |
| [FL-009](#fl-009) | `textContrastGuideline` checks disabled text | Test framework | Confirmed |
| [FL-010](#fl-010) | Live region text is announced when the screen opens | Android, iOS, Web | Observed |
| [FL-011](#fl-011) | Lazy lists expose only content near the viewport | Web (others not checked) | Confirmed |
| [FL-012](#fl-012) | A web live region announcement can be erased by an earlier one's clear timer | Web | Confirmed (source read) |
| [FL-013](#fl-013) | A web link with `linkUrl` is followed by the browser as well as by `onTap` | Web | Confirmed |
| [FL-014](#fl-014) | `CupertinoListSection` does not expose its header as a heading | All | Confirmed |
| [FL-015](#fl-015) | On Android, TalkBack stops speaking a text field's label once it has a value | Android | Confirmed |
| [FL-016](#fl-016) | Cupertino text fields have no label | All | Confirmed |
| [FL-017](#fl-017) | The status and alert roles are announced on web only | Android, iOS | Confirmed |
| [FL-018](#fl-018) | Announcements sent from code are reported as unsupported on Android, and assertiveness is web only | Android, iOS | Confirmed |
| [FL-019](#fl-019) | Landmark roles have an effect on web only | Android, iOS | Observed |
| [FL-020](#fl-020) | Spell-out and language attributes do not reach the web, and `localeForSubtree` writes an invalid `lang` | Web | Observed |
| [FL-021](#fl-021) | No semantics for inline or block text structure | All | Observed |
| [FL-022](#fl-022) | Custom semantics actions are not exposed on web | Web | Observed |
| [FL-023](#fl-023) | Material menu widgets do not use the menu roles, and their items have no button role on Android and iOS | All | Observed |
| [FL-024](#fl-024) | Tables have structure on web only, and a plain `Table` marks no headers by itself | Android, iOS, Web | Observed |
| [FL-025](#fl-025) | iOS accessibility APIs and settings with no Flutter counterpart | iOS | Confirmed |
| [FL-026](#fl-026) | No semantics roles for grid, tree, treegrid, feed, separator, meter, or math | All | Confirmed |
| [FL-027](#fl-027) | A progress indicator whose value has a percent sign reports an empty range on Android | Android | Confirmed (source read) |
| [FL-028](#fl-028) | A slider has no accessible name on web | Web | Confirmed; fixed in 3.50 by its source, not verified |
| [FL-029](#fl-029) | A Material `Slider` adds an empty full-screen element that takes pointer events on web | Web | Confirmed |
| [FL-030](#fl-030) | A label on an `Image` inside a button does not name the button | Android, iOS | Confirmed (source read) |
| [FL-031](#fl-031) | An `Image` left in a button's semantics makes the button an image as well | Android, iOS | Confirmed |
| [FL-032](#fl-032) | `Semantics(link: true)` without `linkUrl` is a link on iOS only | Android, Web | Confirmed |
| [FL-033](#fl-033) | A switch or checkbox with no `enabled` flag is read as dimmed by VoiceOver on iOS | iOS | Confirmed (source read) |
| [FL-034](#fl-034) | `Semantics(keyboardKey: true)` has no effect on any platform | All | Observed (source read) |
| [FL-035](#fl-035) | A checkbox is a switch for VoiceOver on iOS | iOS | Confirmed (source read) |
| [FL-036](#fl-036) | No way to reword the state of a switch or checkbox; `value` on one is handled three different ways | All | Confirmed |
| [FL-037](#fl-037) | On web a `value` is appended to the accessible name | Web | Confirmed |
| [FL-038](#fl-038) | On Android an adjustable node shows `increasedValue` as its value straight after the action | Android | Confirmed (source read) |
| [FL-039](#fl-039) | On Android a hint is the end of the content description, not a hint | Android | Confirmed (source read) |
| [FL-040](#fl-040) | `Semantics(hint:)` around a Material button stays on a node of its own | All | Confirmed |
| [FL-041](#fl-041) | On web a hint on a node with no label is not rendered, unless the node is a text field | Web | Confirmed (source read) |
| [FL-042](#fl-042) | On iOS an obscured text field is a secure text field only while it is being edited | iOS | Confirmed |
| [FL-043](#fl-043) | `Semantics(identifier:)` around a Material button stays on a node of its own, in a different place on iOS | All | Confirmed |
| [FL-044](#fl-044) | A mixed checkbox is exposed as not checked on the web, on iOS, and on Android before 16, and TalkBack says no state for it | All | Confirmed |
| [FL-045](#fl-045) | TalkBack says no state for a checkbox or radio button that is not checked | Android | Confirmed; cause not found |
| [FL-046](#fl-046) | `RadioGroup` has no label parameter: it is named by text inside it, and a label around it misses | All | Confirmed |
| [FL-047](#fl-047) | A radio button is a button for VoiceOver on iOS, and a hand-built one has no state there | iOS | Confirmed (source read) |
| **FL-048 to FL-069** | Work outside the waves | | |
| **FL-070 to FL-099** | Wave 10, the limitation entries | | |
| **FL-100 to FL-199** | Wave 1, forms | | |
| [FL-100](#fl-100) | TalkBack says "checked" as well as "on" for a switch that is on | Android | Confirmed; cause not found |
| [FL-120](#fl-120) | A `CupertinoSlider` takes no keyboard focus | All | Confirmed |
| [FL-121](#fl-121) | A `CupertinoSlider` moves only when its thumb is dragged | All | Confirmed |
| [FL-122](#fl-122) | A Material `Slider` has no Home or End keys, and on the web those keys move it one step | All | Confirmed |
| [FL-123](#fl-123) | `Slider.label`, the text shown above the thumb, is added to the slider's name | All | Confirmed |
| [FL-124](#fl-124) | A disabled slider is not a slider | All | Confirmed (source read) |
| [FL-125](#fl-125) | On the web a slider's minimum, maximum, and current value are stand-ins | Web | Confirmed |
| [FL-126](#fl-126) | A `RangeSlider` has two unnamed sliders on the web and one value on Android when merged | Android, iOS, Web | Observed |
| [FL-127](#fl-127) | On the web a slider is disabled for half a second after any pointer event, and VoiceOver calls it "dimmed" | Web | Confirmed |
| [FL-140](#fl-140) | Material helper text is not tied to its field; inside `MergeSemantics` it joins the field's name | All | Confirmed |
| [FL-141](#fl-141) | Material helper text is cut to one line by default | All | Confirmed |
| [FL-142](#fl-142) | A Material placeholder beside a label is exposed only while the field is focused and empty, and then as part of its name | All | Confirmed |
| [FL-160](#fl-160) | On Android, turning suggestions off on an email field replaces the email keyboard with one that has no "@" | Android | Confirmed |
| [FL-161](#fl-161) | On the web autofill hints do not reach `autocomplete`, except on an obscured field once it is focused | Web | Confirmed |
| [FL-162](#fl-162) | On the web the number and decimal keyboard types leave nothing in the page, so a phone's browser shows its general keyboard | Web | Confirmed |
| [FL-163](#fl-163) | On iOS the number, decimal, and phone pads have no return key, and a tap outside the field does not end editing | iOS | Confirmed |
| [FL-180](#fl-180) | A text field in error has no error state on Android: TalkBack does not say "error", and reads a filled field without its error | Android | Confirmed |
| [FL-181](#fl-181) | On iOS and the web an error is announced only when a `Form` validates on send or as the user types; `onUnfocus`, a field validated on its own, and a hand-set `errorText` are silent there | iOS, Web | Confirmed |
| [FL-182](#fl-182) | `CupertinoTextFormFieldRow`'s error is not a live region, so on Android nothing announces it | Android | Confirmed |
| [FL-183](#fl-183) | `MergeSemantics` around a field takes in its error: the error joins the field's name as well as its hint, and on Android the field becomes a live region | All | Confirmed |
| [FL-184](#fl-184) | Keyboard focus moved to a field does not move VoiceOver's cursor on iOS | iOS | Observed |
| **FL-200 to FL-299** | Wave 2, links and simple components | | |
| [FL-200](#fl-200) | Flutter has no pressed state: a toggle button can only be a switch, a checkbox, or a button that is selected | All | Confirmed |
| [FL-201](#fl-201) | `IconButton(isSelected:)` and a multi-select `SegmentedButton` say nothing while they are off, and on the web their state is `aria-current` | All (a 4.1.2 failure on the web only) | Confirmed |
| [FL-202](#fl-202) | A `CupertinoButton` resolves its `color` for light and dark mode, and not its `foregroundColor`, so dynamic text colour stays light in dark mode | All (widget tests only) | Confirmed |
| [FL-220](#fl-220) | On Android TalkBack says no role for a Flutter link | Android | Confirmed |
| [FL-221](#fl-221) | Material and Cupertino have no link widget, and a link put round one of their buttons is a button as well | Android, iOS (`CupertinoButton`); All (`TextButton`, probe only) | Confirmed for `CupertinoButton` |
| [FL-240](#fl-240) | A link in a `TextSpan` takes no keyboard focus, and cannot be given an address | All | Confirmed |
| [FL-241](#fl-241) | Text inside a `WidgetSpan` is scaled twice by the text size setting | Android, iOS, test framework (web not measured) | Confirmed |
| [FL-242](#fl-242) | `CupertinoColors.link` and `CupertinoColors.systemBlue` are 4.02:1 on white, under the 4.5:1 that text needs | All (widget test only) | Confirmed |
| [FL-243](#fl-243) | `MergeSemantics` round a sentence with links makes one link, with the first link's address and action | All | Confirmed |
| [FL-244](#fl-244) | A link in a `WidgetSpan` cannot break across lines with the text round it | Android, iOS, test framework (web not measured) | Confirmed |
| [FL-245](#fl-245) | On the web `SelectableText` is an empty, disabled text field: its text and its links are not in the page | Web (Chromium) | Observed |
| [FL-246](#fl-246) | A run of a paragraph's text that wraps has one node over the whole of its lines, which can lie over a link on the first line: on iOS a VoiceOver touch on the link finds the words | iOS (Android and web not measured) | Confirmed |
| [FL-247](#fl-247) | A tooltip with a plain message, and every `IconButton.tooltip`, takes no pointer events, so the pointer cannot move onto it | Web, Android (with a mouse), widget tests; iOS not measured | Confirmed |
| [FL-248](#fl-248) | No Flutter tooltip shows on keyboard focus, so showing one fails 2.1.1 wherever a keyboard is used | All | Confirmed |
| [FL-249](#fl-249) | While a tooltip is shown, its text is a node of its own inside its control | All | Confirmed |
| [FL-250](#fl-250) | A tooltip whose box lies over its control's edge does not stay hidden after Escape while the pointer is on that strip: a `RawTooltip` by default, and a Material `Tooltip` on a control taller than 48 | Widget tests only | Confirmed (widget test only) |
| [FL-251](#fl-251) | A tooltip is part of its control's name on iOS and the web, before the control's own text on the web; only Android treats it as separate text | iOS, Web | Confirmed |
| [FL-252](#fl-252) | On iOS VoiceOver does not stop on a node whose only text is a tooltip | iOS | Confirmed |
| [FL-253](#fl-253) | A `FilledButton`'s text is under 4.5:1 in light mode while it has keyboard focus and a hover | All (widget test only) | Confirmed (widget test only) |
| [FL-254](#fl-254) | A change of a progress indicator's value is not announced, even with the screen reader on the indicator | All | Confirmed |
| [FL-255](#fl-255) | Cupertino's activity indicators give no semantics, and have no parameter for a name or a value | All | Confirmed |
| [FL-256](#fl-256) | A spinner has no role on any platform, and on iOS no progress indicator has one | All (spinner); iOS (every indicator) | Confirmed |
| [FL-257](#fl-257) | `CircularProgressIndicator.adaptive` drops its label, and all its semantics, where the theme's platform is iOS or macOS, which includes a browser on a Mac | iOS, Web (on a Mac) | Confirmed |
| [FL-258](#fl-258) | A progress indicator's `semanticsValue` that is not a number or a percentage fails the framework's own check, and in a debug build no semantics are sent for the screen | Android, iOS, test framework (debug); Web (release: no `aria-valuenow`) | Confirmed |
| [FL-259](#fl-259) | On the web a node whose role changes loses its test identifier | Web | Observed (source read) |
| [FL-260](#fl-260) | On iOS `expanded` has no effect: VoiceOver says no expanded or collapsed state | iOS | Confirmed |
| [FL-261](#fl-261) | On Android the expanded state reaches only Android 16 and later | Android (before 16) | Confirmed (source read); measured on Android 17 only |
| [FL-262](#fl-262) | On the web a heading is never a button: a node with a heading level and a button flag is a heading only, with no `aria-expanded` and no button role | Web | Confirmed |
| [FL-263](#fl-263) | A panel hidden with `Offstage` is out of the semantics tree, but its controls keep keyboard focus; `Expansible` and `CupertinoExpansionTile` hide closed panels that way by default, and `ExpansionTile` does with `maintainState: true` | All | Confirmed |
| [FL-264](#fl-264) | `ExpansionTile`'s header has no expanded state, and on Android and iOS no button role unless `internalAddSemanticForOnTap`, "a temporary flag", is set; the state is a hint | All | Confirmed |
| [FL-265](#fl-265) | `CupertinoExpansionTile`'s header takes no keyboard focus, is no button, and has no expanded state; once open, the panel's text joins its name | All (no focus); Android, iOS (no role) | Confirmed |
| [FL-266](#fl-266) | On the web `controlsNodes` becomes `aria-controls` only if the controlled node is there when `controlsNodes` is set | Web | Confirmed |
| [FL-267](#fl-267) | `ExpansionPanelList`'s expand buttons are named "Expand" or "Collapse" whatever their panel, and have no expanded state; an `ExpandIcon` on its own has no state in any words | All | Observed (`ExpansionPanelList`); Confirmed (`ExpandIcon` on its own, C06) |
| [FL-269](#fl-269) | A `Card` left at its default joins all its text into one node, and a heading in it makes all of that one heading | All | Confirmed |
| [FL-280](#fl-280) | On Android an `ExpandIcon` merged with its label keeps the click label "Expand" once it is open | Android | Confirmed; cause not found |
| [FL-290](#fl-290) | A SnackBar's time limit is the app's alone: a screen reader, Android's accessibility timeout, a pointer resting on it, and keyboard focus on its action do not change it | All | Confirmed |
| [FL-291](#fl-291) | Escape closes no SnackBar or MaterialBanner; Back pops the screen under it, and the message stays on the screen before | All (Escape: Android and the web, and widget tests; not sent on iOS) | Confirmed |
| [FL-292](#fl-292) | When a SnackBar times out with keyboard focus on its action, focus goes back to the button that showed it on Android and the web, but to no control in widget tests, and once to the page for a floating one on the web | Android, Web, widget tests (iOS not measured) | Confirmed |
| [FL-293](#fl-293) | A message shown while one that stays is up waits, unseen and unannounced, until that one is closed | Widget tests only | Confirmed (widget tests only) |
| [FL-294](#fl-294) | A SnackBar's Close button shows keyboard focus only by a faint tint, and `closeIconColor` cannot change that | Widget tests only | Confirmed (widget tests only) |
| [FL-295](#fl-295) | A `MaterialBanner` is a live region only when the `ScaffoldMessenger` shows it | All | Confirmed |
| [FL-296](#fl-296) | A SnackBar shown from a `SnackBarAction`'s `onPressed`, after `clearSnackBars` or `hideCurrentSnackBar` there, never appears when `accessibleNavigation` is on: the action hides it | Web; widget tests (Android and iOS not run) | Confirmed |
| [FL-297](#fl-297) | On the web, whether VoiceOver in Chromium said what a SnackBar or banner action did, when Enter on that action removed the control, varied between recordings, and the live-region line that now says it was not heard in its one recording | Web (Chromium, VoiceOver, Enter) | Observed |
| **FL-300 to FL-399** | Wave 3, structure and order | | |
| [FL-300](#fl-300) | `Title` sets the document title only when it is built or its title changes: after Back the browser keeps the title of the screen that closed | Web (Chromium) | Confirmed |
| [FL-301](#fl-301) | `CupertinoNavigationBar`'s title names no route: on Android the pane title is a space, and TalkBack is not told the screen's name | Android, Web (Chromium on macOS, `navigator.platform` as a Mac and as Linux) | Confirmed |
| [FL-302](#fl-302) | On iOS VoiceOver is not told a screen's title when it opens: its cursor goes to the screen's first control | iOS | Confirmed |
| [FL-303](#fl-303) | `CupertinoNavigationBarBackButton` is two buttons: the one that takes the tap has no name | All | Confirmed |
| [FL-304](#fl-304) | On the web a route is a generic element with no role, described by its title only where a node names the route, which `AppBar` does not when `navigator.platform` reports a Mac | Web (Chromium) | Confirmed |
| [FL-305](#fl-305) | On Android a screen that changes inside one route, such as a `NavigationBar`'s destinations, keeps the pane title of the first | Android | Observed |
| **FL-400 to FL-499** | Wave 4, focus and keyboard | | |
| [FL-400](#fl-400) | A `CupertinoListTile` with `onTap` takes no keyboard focus, and is not a button on Android and iOS | All (no focus); Android, iOS (no role) | Confirmed |
| [FL-401](#fl-401) | An `InkWell` with `onTap` is not a button on Android and iOS | Android, iOS | Confirmed |
| [FL-402](#fl-402) | A tap is given up by how far the pointer has moved, not by whether it has left the control | All (widget test only) | Confirmed |
| [FL-410](#fl-410) | A control's semantics node can be bigger than the area that takes taps, and the tap target guidelines read the node | Android, iOS, test framework | Confirmed |
| [FL-411](#fl-411) | On the web a click is taken by the element of the node under it, and by its label text where that runs out of the element | Web | Confirmed |
| [FL-412](#fl-412) | In a desktop browser the Material theme does not pad controls to 48 by 48, and is compact | Web (desktop browser) | Confirmed |
| [FL-413](#fl-413) | The text around a `WidgetSpan` is one node that leaves the widget out, and the widget's node comes after it | All | Confirmed; workaround verified |
| [FL-420](#fl-420) | Tab crosses side-by-side columns row by row by default, and the keyboard's order and the screen reader's are set by separate widgets | All | Confirmed |
| [FL-421](#fl-421) | On the web, Tab past Flutter's last control continues in the document's order, and can go round for ever | Web | Confirmed |
| [FL-422](#fl-422) | On a scrolled screen the default focus order puts the app bar's Back button among the content | All | Confirmed |
| [FL-430](#fl-430) | A Material control with nothing of its own to change shows keyboard focus only with a tint on the page under 3:1: a checked `Checkbox`, a `TextButton`, an `IconButton`, a `ListTile` | All | Confirmed for the checked `Checkbox`; the others in the probe |
| [FL-431](#fl-431) | Cupertino's default focus ring is under 3:1 on a light page, and a `CupertinoCheckbox`'s in dark mode as well | All (the dark-mode checkbox: widget tests only) | Confirmed for `CupertinoButton`; the others in the probe |
| [FL-432](#fl-432) | A control that takes keyboard focus is scrolled into its view without regard to anything drawn over the view, and can end up entirely hidden | All | Confirmed |
| [FL-433](#fl-433) | On Android, a key from the virtual keyboard device does not turn focus highlights on, and `input keyevent` and Instrumentation's keys all come from it | Android | Confirmed |
| [FL-434](#fl-434) | Material's default focus indicator on a control with a container, a border, or a thumb of its own is a faint tint or halo beside a change that does meet 3:1, or a tint of the container; not a 1.4.11 failure as written | All | Confirmed |
| [FL-435](#fl-435) | A `CupertinoTextField` shows keyboard focus only by its caret | iOS, Web (Android: no caret either; not looked into) | Observed |
| [FL-440](#fl-440) | A `CupertinoAlertDialog`'s actions take no keyboard focus | All | Confirmed |
| [FL-441](#fl-441) | A `CupertinoActionSheet`'s title and message fail text contrast in light mode | All (widget test only) | Confirmed (widget test only) |
| [FL-442](#fl-442) | When a route closes, the framework sends the screen reader back to where it was, after the app's own move, even when that control has been removed | Android | Confirmed in the source; its effect Observed |
| [FL-460](#fl-460) | A shortcut above a text field takes its key before the field can type it, on the web and on iOS; on Android not on the local emulator, and not shown on CI's, where the letter was lost | Web, iOS; Android not shown | Confirmed |
| [FL-461](#fl-461) | A text field's done, go, search, or send action takes keyboard focus away and gives it to no control | All | Confirmed |
| [FL-463](#fl-463) | A `PageView` takes no keyboard focus and has no keys | Android, iOS, Web | Observed |
| [FL-464](#fl-464) | A `Shortcuts`, `CallbackShortcuts`, or `Focus` around plain text makes that text the name of a node holding every control inside it | Web, iOS (Android not looked at) | Confirmed |
| [FL-480](#fl-480) | A route closes on Escape only when its barrier can be dismissed, and on Back and VoiceOver's escape gesture whether it can or not | All | Confirmed |
| [FL-481](#fl-481) | Nothing closes an overlay that is not a route, and Back pops the screen under it | All | Confirmed |
| [FL-482](#fl-482) | On the web, Escape does not hide a tooltip while the page has no keyboard focus | Web | Confirmed |
| [FL-483](#fl-483) | A `ModalBarrier` in an `OverlayPortal`'s overlay takes the whole screen out of the semantics tree, the overlay with it | All (widget test only) | Confirmed (widget test only) |
| [FL-484](#fl-484) | While a tooltip counts as open, `WidgetsApp` takes Escape for it before the app's default Escape shortcut reaches the focused layers; a tooltip still hiding when a screen is pushed over it took every Escape | Web (Chromium) | Observed |
| **FL-500 to FL-599** | Wave 5, visual preferences | | |
| **FL-600 to FL-699** | Wave 6, remaining forms | | |
| **FL-700 to FL-799** | Wave 7, dialogs and overlays | | |
| **FL-800 to FL-899** | Wave 8, navigation and complex components | | |
| **FL-900 to FL-999** | Wave 9, the batch 10 techniques | | |

---

## FL-001

**Disabled `CupertinoButton` reports no disabled state.**

- Status: Confirmed. Flutter 3.47.5. Android, iOS, Web.
- Widgets: `CupertinoButton`, `CupertinoButton.filled`, `CupertinoButton.tinted`.
- WCAG: 4.1.2 Name, Role, Value.
- What happens: with `onPressed: null` the button looks disabled and ignores
  taps, but its semantics have the button flag only. There is no enabled
  state, and a tap action is still listed. Material buttons report
  `hasEnabledState` with `isEnabled: false` and no tap action.
- What users get: screen readers announce an ordinary button. VoiceOver on iOS
  says "Delete Button" where a Material button says "Submit dimmed Button";
  TalkBack says "Delete / Button" with "Double-tap to activate"; on web there
  is no `aria-disabled`.
- Cause (SDK source read): `packages/flutter/lib/src/cupertino/button.dart`
  wraps its child in `Semantics(button: true, …)` and never sets `enabled`.
- Reproduce: example `/t/C01/bad-cupertino-disabled`. Asserted in
  `test/techniques/c01_button_test.dart` (enabled state is `Tristate.none`),
  `web_tests/c01_button.spec.js`, `C01ButtonTest.kt`, and
  `C01ButtonUITests.swift`. Each test is written to fail when this is fixed.
- Workaround: `Semantics(enabled: false, child: CupertinoButton(onPressed: null, …))`.
  Verified on all three platforms in `/t/C01/good-cupertino` ("Delete dimmed
  Button", "Button. disabled", `aria-disabled="true"`). The stray tap action
  remains but does nothing.
- Upstream issue: none found in three searches of flutter/flutter on
  2026-11-12. To be filed.

## FL-002

**Enter does not activate a `CupertinoButton` on web.**

- Status: Confirmed. Flutter 3.47.5. Web only.
- WCAG: 2.1.1 Keyboard. APG Button says Enter and Space both activate.
- What happens: Tab reaches the button and Space activates it; Enter does
  nothing.
- Cause (SDK source read): on web `WidgetsApp` maps Enter to
  `ButtonActivateIntent` (`_defaultWebShortcuts` in
  `packages/flutter/lib/src/widgets/app.dart`). `CupertinoButton` registers an
  action for `ActivateIntent` only. Material's `InkWell` handles both.
- Reproduce: a plain `CupertinoButton` on web: Tab to it and press Enter.
  `test/techniques/c01_button_test.dart` asserts that the plain button has no
  action registered for `ButtonActivateIntent` (written to fail when this is
  fixed). On Android and iOS Enter is `ActivateIntent` and works.
- Workaround, applied in `/t/C01/good-cupertino`: wrap the button in
  `Actions(actions: {ButtonActivateIntent: CallbackAction(onInvoke: …)})` that
  calls the same callback. `web_tests/c01_button.spec.js` requires Enter and
  Space to each activate it once.
- Also seen in S13 (2026-11-15): Enter does not toggle a `CupertinoSwitch`
  on web; Space does. The APG Switch pattern makes Enter optional, so
  `/t/S13/good-cupertino` adds no action for it, and
  `web_tests/s13_roles_and_traits.spec.js` requires Space only. F09
  (2026-11-17) asserts it: `web_tests/f09_switch.spec.js` requires Enter to
  leave `/t/F09/good-cupertino` unchanged, written to fail when it is
  fixed, and Enter toggles the Material and custom switches there.
- Also seen in I03 (2026-11-18), the same mechanism: a
  `CupertinoActionSheetAction` registers an action for `ActivateIntent`
  only (`cupertino/dialog.dart`, read in the source). In the I03 probe on
  the web (`docs/evidence/probes/i03/web_round2.txt`, fixture `p6`) Enter
  on one left the sheet open and Space then closed it. The I03 widget test
  "FL-002" asserts that the plain action has no action for
  `ButtonActivateIntent`, written to fail when it has; `/t/I03/good-cupertino`
  wraps each action and its Remove buttons the same way as C01, and
  `web_tests/i03_focus_management.spec.js` presses Enter on them.
- Upstream issue: not found. To be filed.

## FL-003

**`Semantics(header: true)` alone is not a heading for VoiceOver on iOS.**

- Status: Confirmed, Flutter 3.47.5, iOS 27.0 simulator.
- WCAG: 1.3.1 Info and Relationships, 2.4.6 Headings and Labels.
- What happens: `Semantics(header: true, child: Text('Profile'))` is spoken as
  "Profile", with no "Heading". The same text with `headingLevel: 3` is spoken
  as "Profile Heading". A native heading in Apple's Settings app, read through
  the same test API, is spoken as "General Heading", so the API does report
  the trait. An `AppBar` title is affected the same way, because `AppBar`
  marks its title with `header: true` and no level.
- Cause: not investigated.
- Reproduce: `/t/S05/bad-header-only`. Asserted in
  `ios/RunnerUITests/S05HeadingsUITests.swift` (`testVoiceOverSpeech`), written
  to fail when this is fixed; transcript in
  `docs/evidence/S05/voiceover-ios.md`.
- Workaround: set `headingLevel`, with or without `header: true`
  (`/t/S05/good-levels`). For an `AppBar`, wrap the title:
  `AppBar(title: Semantics(headingLevel: 1, child: Text(title)))`. The shell
  does both (`lib/app/widgets.dart`).
- Upstream issue: not searched yet.

## FL-004

**`header: true` on web is always `<h2>`.**

- Status: Confirmed, Flutter 3.47.5, web.
- WCAG: 1.3.1 Info and Relationships.
- What happens: every `Semantics(header: true)` node becomes `<h2>`, whatever
  its place in the page outline, including an `AppBar` title. A page built
  this way has no `<h1>`, and every heading is announced as "heading level
  2". `Semantics(headingLevel: n)` produces the matching `<h1>`–`<h6>`.
- Reproduce: `/t/S05/bad-header-only`. Asserted in
  `web_tests/s05_headings.spec.js`, written to fail if the level changes;
  VoiceOver says "heading level 2 Profile"
  (`docs/evidence/S05/voiceover-web.md`).
- Workaround: always set `headingLevel`, and give the `AppBar` title level 1
  as in FL-003. `web_tests/s05_headings.spec.js` asserts that every screen of
  this app has exactly one `<h1>` and no skipped level.
- Upstream issue: not searched yet.

## FL-005

**`header: true` alone is not a heading on Android, except directly in a list.**

- Status: Confirmed, Flutter 3.47.5, Android 17 emulator. SDK source read.
- WCAG: 1.3.1 Info and Relationships.
- What happens: `Semantics(header: true, child: Text('Profile'))` reports
  `AccessibilityNodeInfo.isHeading == false`, TalkBack does not say
  "Heading", and heading navigation skips it. With `headingLevel` set it is a
  heading.
- Cause (SDK source read): the Android embedding sets the heading property
  from the level only, `result.setHeading(node.headingLevel > 0)` in
  `engine/src/flutter/shell/platform/android/io/flutter/view/BaseRoleConfigurator.java`.
  The header flag is used in one other place: when the node is a direct child
  of a scrollable list it is passed as the "is heading" value of the node's
  collection item info, and Android reports such an item as a heading. So the
  same widget is a heading as a direct `ListView` child and not a heading
  anywhere else, for example inside a `Column`.
- Correction: an earlier version of this entry, from the Phase 1 spike, blamed
  a test identifier on the same node. That was wrong. The spike's heading that
  worked was a direct `ListView` child and the ones that failed were not; the
  identifier was a coincidence.
- Reproduce: `/t/S05/bad-header-only`. Asserted in `S05HeadingsTest.kt`
  (`badHeaderOnlyIsNotAHeadingOnAndroid`), written to fail when this is fixed,
  and in the TalkBack transcript.
- Workaround: set `headingLevel` (`/t/S05/good-levels`). Android has one
  heading level, so any level from 1 to 6 gives the same result there.
- Upstream issue: not searched yet.

## FL-006

**Any tappable node is `role="button"` on web.**

- Status: Confirmed, Flutter 3.47.5, web.
- What happens: a `GestureDetector(onTap:)` around a `Container` with no
  `Semantics(button: true)` is exposed as `<flt-semantics role="button">` with
  no `tabindex`. VoiceOver says "Save button". On Android it is an
  `android.view.View` and on iOS static text, with no button role.
- Why it matters: on web a control can sound like a button to a screen reader
  user and still be unreachable from the keyboard (2.1.1). It also means a
  missing button role cannot be demonstrated on web.
- Reproduce: `/t/C01/bad-gesture-only`. Asserted in
  `web_tests/c01_button.spec.js` and `web_tests/vo/c01_button_vo.spec.js`.
- Workaround: not applicable; use a real button widget or
  `FocusableActionDetector` (`/t/C01/good-custom`).
- Upstream issue: not searched yet. This may be intended behaviour.

## FL-007

**`Semantics(identifier:)` inside a button strips the button's name.**

- Status: Confirmed, Flutter 3.47.5, Android 17 and iOS 27. First seen in
  spike K2. Asserted by the widget test "bad-inside",
  `S22SemanticsIdentifiersTest.badInsideLeavesTheButtonWithNoName`,
  `S22SemanticsIdentifiersUITests.testBadInsideLeavesTheButtonWithNoName`,
  and the TalkBack and iOS VoiceOver walks of S22.
- What happens: `FilledButton(child: Semantics(identifier: 'x', child: Text('Save draft')))`
  produces two nodes on Android and iOS: a `Button` with no name and a
  separate text node carrying the label and the identifier. TalkBack and
  VoiceOver announce just "Button". An identifier added for testing has made
  the control inaccessible (4.1.2). The S22 probe saw the same split inside
  `OutlinedButton.icon`, `CupertinoButton`, and `ListTile`
  (`docs/evidence/probes/s22`, fixtures 02, 12, 20, 22).
- On the web the tree splits the same way, and the identifier is on an
  element inside the button, but the button keeps its name: a button's
  accessible name is computed from its content
  (`web_tests/s22_semantics_identifiers.spec.js`, "bad-inside").
- The same inside a SnackBar's message (C13, 2026-11-22; widget test
  only, `docs/evidence/probes/c13/flutter_test_identifier.txt`, as
  Android): with `SnackBar(content: Semantics(identifier: 'message', child:
  Text('Message archived')))`, the SnackBar's own node keeps the live
  region and the dismiss action and has no label, and the words and the
  identifier are on a node of their own inside it, which is not a live
  region; with the text alone, the SnackBar's node is the live region with
  the words. What a screen reader announces for the split one was not
  measured. C13's examples put no identifier on a message, and the tests
  find it by its words.
- Cause: a `Semantics` with an identifier is a node boundary for the text
  under it, so the text can no longer merge up into the button. Not read in
  the SDK source; this is from the trees.
- Workaround: put the identifier outside the control and merge it:
  `MergeSemantics(child: Semantics(identifier: 'x', child: FilledButton(…)))`.
  This is the project's `TestId` widget (`lib/catalog/test_id.dart`) and gives
  one node with role, name, and identifier on all three platforms. A plain
  outer `Semantics(identifier:)` without `MergeSemantics` is
  [FL-043](#fl-043).
- Upstream issue: not searched yet (D25).

## FL-008

**`IconButton` tooltip is read as a second item by VoiceOver in Chromium.**

- Status: Observed, Flutter 3.47.5, macOS 27.0.1, VoiceOver with Playwright's
  Chromium build. Consistent across four runs.
- What happens: for `IconButton(tooltip: 'Close')`, swiping forward reads
  "Close button", then a second item "Close", then an empty item, before the
  next element. Playwright's WebKit build, TalkBack, and VoiceOver on iOS read
  the button once. The DOM for the button is a single
  `<flt-semantics role="button">Close</flt-semantics>`.
- Cause: not investigated. Possibly the tooltip exposed as separate content.
  C12 (2026-11-21) recorded VoiceOver in Chromium and WebKit on seven
  Material tooltips, an `IconButton(tooltip:)` among them: each button was
  read once, no tooltip was shown, and nothing was read twice
  (`docs/evidence/probes/c12/voiceover-web-round1-fail.md.txt`). Why C01's
  reading differed was not found.
- Evidence: `docs/evidence/C01/voiceover-web.md`, `good-icon` and
  `bad-role-in-name` rows under chromium.
- Workaround: none known.
- Upstream issue: not searched yet.

## FL-009

**`textContrastGuideline` checks disabled text.**

- Status: Confirmed, Flutter 3.47.5 (`flutter_test`).
- What happens: `meetsGuideline(textContrastGuideline)` fails on the label of a
  disabled Material or Cupertino button (ratios 2.87 light and 2.26 dark for
  `FilledButton` on the default indigo theme). WCAG 1.4.3 exempts text that is
  part of an inactive user interface component.
- Effect here: the Button widget tests skip the contrast guideline for
  examples that contain a disabled button
  (`test/techniques/c01_button_test.dart`).
- Upstream issue: not searched yet.

## FL-010

**Live region text is announced when the screen opens.**

- Status: Observed, Flutter 3.47.5. TalkBack on Android 17; also seen in
  Flutter web's announcer element.
- What happens: a `Semantics(liveRegion: true)` node that is present when a
  route opens is announced immediately ("Activations: 0", "Cart is empty"),
  before the user has done anything. On Android the announcement can also
  interrupt or delay speech for the element that receives focus. On web the
  text is written to the polite announcer as the screen appears.
- Why it matters: 4.1.3 Status Messages is about changes; reading initial
  content is noise.
- Effect on the tests: the web suites wait for these opening announcements to
  clear before recording (`web_tests/i12_announcements.spec.js`), and the
  TalkBack walks wait for the screen's own speech to finish.
- Workaround: none applied. Not adding the live region until there is
  something to announce avoids it, at the cost of the first message.
- Upstream issue: not searched yet.

## FL-011

**Lazy lists expose only content near the viewport.**

- Status: Confirmed on web, Flutter 3.47.5. Android and iOS not checked.
- WCAG: 1.3.1 Info and Relationships, 2.4.1 Bypass Blocks (heading navigation).
- What happens: `ListView` builds only the children near the viewport, and
  only those are in the accessibility tree. With the technique screen in a
  `ListView`, the browser's tree held four of the page's twelve headings on
  load; after scrolling to the end it held two, and the earlier ones were
  gone. A screen reader's heading list, link list, and find therefore show
  only part of the page, and which part depends on scroll position.
- Reproduce: was `PageScaffold` in `lib/app/widgets.dart` before it was
  changed. Counted with Playwright (`h1,h2,h3` in the DOM before and after
  scrolling).
- Workaround: for pages of modest length, `SingleChildScrollView` with a
  `Column`, which lays out everything. The shell does this now, and
  `web_tests/c01_button.spec.js` asserts that the last section's heading is in
  the tree without scrolling. Long or unbounded lists still need a lazy list;
  what to do there is a question for the list techniques (S12, C-group).
- Upstream issue: not searched yet. Lazy building is by design; the effect on
  assistive technology navigation is the limitation.

## FL-012

**A web live region announcement can be erased by an earlier one's clear timer.**

- Status: Confirmed by reading the engine source, Flutter 3.47.5, web. Seen
  as a test failure on CI. Whether a screen reader actually loses speech
  because of it has not been tested.
- WCAG: 4.1.3 Status Messages.
- What happens: Flutter web does not put `aria-live` on the live region's own
  node. It copies the text into a shared `<flt-announcement-polite>` element
  and empties that element 300 ms later (`liveMessageDuration`). Each
  announcement starts its own clear timer and nothing cancels the earlier
  ones, so when two announcements are less than 300 ms apart the first one's
  timer empties the element while it holds the second one's text. With a live
  region that is present when a screen opens (see FL-010), a change made
  within 300 ms of opening is affected.
- Cause (SDK source read):
  `engine/src/flutter/lib/web_ui/lib/src/engine/semantics/accessibility.dart`,
  `AccessibilityAnnouncements.announce`.
- How it showed up: `web_tests/c01_button.spec.js` read the element once after
  clicking Save and found it empty on a slower CI machine. The test now
  records every value the element is given.
- Workaround: none applied. To be examined in I12 Announcements with a real
  screen reader.
- Upstream issue: not searched yet.

## FL-013

**A web link with `linkUrl` is followed by the browser as well as by `onTap`.**

- Status: Confirmed, Flutter 3.47.5, web (Playwright Chromium).
- What happens: `Semantics(link: true, linkUrl: uri)` around a tappable widget
  becomes a real `<a href>`. A click runs the widget's `onTap` and the browser
  also follows the `href` in the current tab. If `onTap` opens the URL in a
  new tab (the usual `launchUrl`), one click opens the destination twice: the
  current tab is replaced and a new tab opens. A key press is different:
  Flutter handles Enter itself and the anchor is not followed, so `onTap` is
  the only thing that navigates.
- Why it matters: a link must have one predictable result (3.2.5 Change on
  Request is AAA, but an unexpected second tab and a lost page is a failure
  of the link either way).
- Reproduce: was `ExternalLink` in `lib/app/widgets.dart` before it was
  changed; clicking "WCAG 2.2" on the about screen navigated the tab and
  opened a second one.
- Workaround, applied: on web the tap does nothing and the browser follows
  the anchor, which also keeps Ctrl- and Command-click working as they do for
  any link. Enter is mapped with `Shortcuts` and `Actions` to open the URL in
  the same tab, since the key press never reaches the anchor.
  `web_tests/c01_button.spec.js` asserts: click and Enter each end on the
  destination in this tab with no second tab; Ctrl/Command-click opens
  exactly one new tab and leaves this one alone; Space does nothing.
- Measured again in C03 Stand-alone link (2026-11-20), with an address in
  the app (`linkUrl: Uri.parse('#/t/C03')`) and a widget whose `onTap`
  pushes the same route with `Navigator`, as an app does off the web
  (`/t/C03/bad-app-also-follows`), with `InkWell`'s Enter and Space given to
  the browser as in the workaround below. In Chromium, five runs out of five
  for each:
  - A mouse click, and Tab then Enter, navigate and end where they began:
    the address goes to `#/t/C03` and back, the example stays on screen,
    and the app's Back then goes to the technique's page and a second Back
    to the catalog, as from an example opened by its address
    (`docs/evidence/probes/c03/web_twice.txt`, `web_twice_enter.txt`).
  - A DOM click with no pointer events, the kind assistive technology can
    send, opens the technique's page twice, and the address bar keeps the
    example's address: one Back leaves the technique's page on screen
    (`web_twice_dispatch.txt`). What VoiceOver's own activation sends was
    not measured.
  - Why the two navigations end this way was not found. Asserted in
    `web_tests/c03_stand_alone_link.spec.js`.
  - So with the app following the link as well, Enter does not follow it.
    That breaks the usual keyboard activation, but WCAG 2.1.1 Keyboard is
    not shown to fail: the page the link goes to is the technique's own
    page, which the screen's Back button also opens from the keyboard.
    Space was not tried on that example.
- Which keys reach the anchor, measured in the C03 probe
  (`docs/evidence/probes/c03/web.txt`): Enter follows an `<a href>` only when
  no Flutter widget takes the key. An `InkWell` or a `TextButton` takes it
  (only `onTap` runs); a `Focus` with no actions, a `GestureDetector`, and a
  `CupertinoButton` ([FL-002](#fl-002)) do not, and the browser follows the
  link. Space never follows it, as for any link. An `<a href>` with no
  `Focus` widget at all is still reached by Tab: the browser makes the
  anchor focusable by itself, while Flutter's focus knows nothing of it.
- The workaround with no plugin, verified in C03's good examples on every
  layer: on the web the widget's `onTap` does nothing, and Enter and Space
  are bound to `DoNothingAndStopPropagationIntent` above the `InkWell`,
  which stops them in Flutter without handling them, so the browser gets
  them. The browser then follows the link once on a click, on a DOM click,
  and on Enter, and opens it in a new tab on Command- or Ctrl-click.
- `url_launcher`'s `Link` widget, which this entry asked about, is a plugin,
  which D30 rules out. Source read (`url_launcher` 6.3.3,
  `url_launcher_web` 2.4.3): on the web it puts
  `Semantics(link: true, linkUrl:)` round its builder's widget and a
  platform view with an `<a>` of its own over it, and decides between the
  browser and `launchUrl` per click; off the web it adds no semantics at
  all, so its builder's `TextButton` is a button on Android and iOS (C03
  probe fixture p12).
- Upstream issue: not searched yet.

## FL-014

**`CupertinoListSection` does not expose its header as a heading.**

- Status: Confirmed, Flutter 3.47.5. Android, iOS, Web. SDK source read.
- WCAG: 1.3.1 Info and Relationships.
- What happens: the `header` of `CupertinoListSection` (and
  `CupertinoListSection.insetGrouped`) is drawn in the section-header style
  but is plain text to assistive technology. VoiceOver says "Notifications"
  with no "Heading", TalkBack the same, and on web it is not a heading
  element.
- Cause (SDK source read): `packages/flutter/lib/src/cupertino/list_section.dart`
  adds no `Semantics` to the header.
- Reproduce: `/t/S05/bad-cupertino-section-header`. Asserted at every layer:
  `test/techniques/s05_headings_test.dart`, `web_tests/s05_headings.spec.js`,
  `S05HeadingsTest.kt`, and the three transcripts in `docs/evidence/S05/`.
  The widget test is written to fail when this is fixed.
- Workaround: pass a header that is a heading,
  `header: Semantics(header: true, headingLevel: 3, child: Text('…'))`
  (`/t/S05/good-cupertino`).
- Upstream issue: not searched yet.

## FL-015

**On Android, TalkBack stops speaking a text field's label once it has a value.**

- Status: Confirmed, Flutter 3.47.5, Android 17 emulator, TalkBack 17.0. SDK
  source read for how the label is exposed; TalkBack's side is observed, not
  read.
- WCAG: 4.1.2 Name, Role, Value; 3.3.2 Labels or Instructions.
- What happens: a field with `InputDecoration(labelText: 'Email')` is read as
  "Email, Edit box" while empty. With "abc" typed it is read as "abc, Edit
  box", whether or not it is being edited. The label is still in the tree. A
  field named with `Semantics(label:)` behaves the same. On iOS VoiceOver
  says "Email abc Text field", and on web "abc … Email edit text".
- Cause: Flutter's Android embedding puts a text field's label and hint
  together into the node's hint text (`getTextFieldHint()` in
  `AccessibilityBridge.java`, applied with `setHintText` in
  `BaseRoleConfigurator.java`) and sets nothing else that names the field.
  TalkBack spoke that hint only for an empty field.
- Reproduce: `/t/F01/good-label`, type into Email, move TalkBack focus away
  and back. Captured by `python3 tool/talkback.py F01`
  (`f01-good-label-email-filled` in `docs/evidence/F01/talkback-android.md`).
  The expectation is written to fail when "Email" starts being spoken.
- Workaround: none found within the SDK. A separate visible label that is
  left in the tree is read as its own stop before the field, which helps a
  user exploring in order but does not name the field.
- Instructions go the same way (F02). A field's hint is in the same hint
  text, "Username, 4 to 10 characters, no spaces.", and is read only while
  the field is empty: with "abc" typed TalkBack read "Editing.", "abc",
  "Edit box" (`f02-good-helper-username-filled` in
  `docs/evidence/F02/talkback-android.md`, written to fail when the label
  or the instruction starts being spoken). VoiceOver on iOS and on the web
  still read the hint of a filled field. What F02 does about it: the
  visible instruction is kept as an element of its own (helper text, a
  form row's help text, or a `Text`). It is still an element of its own
  in the tree after the field has a value, and TalkBack reads the whole
  instruction when focus is put on it (`f02-good-helper-rule` and
  `f02-good-helper-rule-filled`). Whether a swipe from the filled field
  lands on it was not tested: swipes and Alt or Meta arrow-key commands
  did not move TalkBack focus on the emulator, in F02 as in S03. It does
  not put the instruction back on the field.
- The same goes for an error. `InputDecoration.errorText` is put in the
  field's semantics hint, which joins the label in the hint text ("Email,
  Enter an email address…"), so a field in error that has a value was
  read "Editing.", "abc", "Edit box", with neither its label nor its
  error. Found in F06 and asserted by `f06-good-form-email-filled` in
  `docs/evidence/F06/talkback-android.md`; see [FL-180](#fl-180) for why
  nothing else on the field carries the error.
- Upstream issue: not searched yet.

## FL-016

**Cupertino text fields have no label.**

- Status: Confirmed, Flutter 3.47.5. Android, iOS, Web.
- WCAG: 1.3.1 Info and Relationships; 3.3.2 Labels or Instructions; 4.1.2
  Name, Role, Value.
- What happens: `CupertinoTextField` has a `placeholder` and no label
  parameter. The placeholder names the field only while it is empty; once
  text is typed the field has no name (VoiceOver: "abc Text field"). A
  `CupertinoFormRow(prefix: Text('Email'), child: CupertinoTextField())` draws
  a label beside the field, but the prefix is separate text and the field is
  unnamed (VoiceOver: "Email", then "Text field").
- Reproduce: `/t/F01/bad-cupertino-placeholder` and
  `/t/F01/bad-cupertino-prefix`. Asserted at every layer:
  `test/techniques/f01_text_fields_test.dart`,
  `web_tests/f01_text_fields.spec.js`, `F01TextFieldsTest.kt`,
  `F01TextFieldsUITests.swift`, and the transcripts in `docs/evidence/F01/`.
- Workaround: name the field with `Semantics(label: 'Email', child: …)` and
  wrap the visible prefix in `ExcludeSemantics` so it is not read twice
  (`/t/F01/good-cupertino`).
- Instructions (F02): a Cupertino field has no hint either, and the
  `helper` of a `CupertinoFormRow` is plain text after the field, not tied
  to it ([F02 probe](evidence/probes/f02/README.md), fixture 08). The same
  workaround carries an instruction: `Semantics(label: 'Username', hint:
  rule, …)` on the field, with the form row's `helper` showing the rule.
  Verified on all three platforms in `/t/F02/good-cupertino`.
- Upstream issue: not searched yet.

## FL-017

**The status and alert roles are announced on web only.**

- Status: Confirmed, Flutter 3.47.5. Android 17 with TalkBack 17.0; web with
  VoiceOver in Chromium; iOS 27.0 with VoiceOver, where both roles are also
  silent (`docs/evidence/I12/voiceover-ios.md`).
- WCAG: 4.1.3 Status Messages.
- What happens: `Semantics(role: SemanticsRole.status, child: Text(…))` and
  `SemanticsRole.alert` become `role="status"` and `role="alert"` on web, and
  VoiceOver announces a change to them. On Android the same nodes are not
  live regions (`AccessibilityNodeInfo.liveRegion` is none) and TalkBack says
  nothing when their text changes. An error shown only this way is silent to
  a TalkBack user.
- The roles cannot be combined with `liveRegion: true` on one node: the
  framework asserts against it (`_noLiveRegion` in
  `packages/flutter/lib/src/semantics/semantics.dart`).
- Also seen on web: the message is carried as the node's `aria-label`, and
  VoiceOver in Chromium reads it twice ("1 item in cart 1 item in cart").
- Reproduce: `/t/I12/bad-status-role-only` and `/t/I12/bad-alert-role-only`.
  Asserted in `I12AnnouncementsTest.kt` (no live region) and in the TalkBack
  transcript (nothing spoken), both written to fail when this is fixed, and
  on web in `web_tests/i12_announcements.spec.js` and the VoiceOver transcript.
- Workaround: use `Semantics(liveRegion: true)` for a status message
  (`/t/I12/good-live-region`). It is announced on Android and web.
- Upstream issue: not searched yet.

## FL-018

**Announcements sent from code are reported as unsupported on Android, and assertiveness is web only.**

- Status: Confirmed, Flutter 3.47.5. SDK documentation and source read;
  behaviour checked on Android 17 with TalkBack 17.0.
- WCAG: 4.1.3 Status Messages.
- What happens:
  - `MediaQuery.supportsAnnounceOf(context)` is false on Android. The SDK
    documentation says Android has deprecated announcement events and to use
    `Semantics` instead. Code that follows the documentation and checks
    support therefore sends nothing on Android.
  - When `SemanticsService.sendAnnouncement` is called anyway on this Android
    version, TalkBack does speak it. The platform says not to rely on that.
  - The `assertiveness` argument "is only supported by the web engine and has
    no effect on other platforms" (SDK documentation). On Android Flutter
    exposes live regions as polite only, so there is no assertive option
    there.
- Effect: there is no single way to announce from code on every platform,
  and no way to make an urgent message assertive off the web.
- Reproduce and workaround: `/t/I12/good-announce` checks
  `supportsAnnounceOf` and, where it is false, makes its visible confirmation
  a live region instead. Asserted in
  `test/techniques/i12_announcements_test.dart` (both branches),
  `I12AnnouncementsTest.kt`, and the TalkBack transcript ("Link copied").
- Upstream issue: not searched yet.

## FL-019

**Landmark roles have an effect on web only.**

- Status: Observed, Flutter 3.47.5, batch 0 probe (`docs/evidence/probes/batch-0/`). Chromium;
  Android 17; iOS 27.0 with VoiceOver.
- WCAG: 1.3.1 Info and Relationships, 2.4.1 Bypass Blocks.
- What happens: `Semantics(role: SemanticsRole.main)` and the `navigation`,
  `complementary`, `contentInfo`, `region`, and `form` roles become
  `role="main"` and so on (a `<form>` element for `form`) on web. On Android
  the node is a plain `android.view.View` with no pane title or role. On iOS
  it is an element of type Other. Where the landmark has a label, the label
  becomes an extra stop on mobile that reads only the label ("Primary").
- Effect: landmark navigation exists only on web. On mobile a labelled
  landmark adds a stop that says nothing about what it is.
- Workaround: none found yet. To be worked out in S07.
- Upstream issue: not searched yet.

## FL-020

**Spell-out and language attributes do not reach the web, and `localeForSubtree` writes an invalid `lang`.**

- Status: Observed, Flutter 3.47.5, batch 0 probe (`docs/evidence/probes/batch-0/`).
- WCAG: 3.1.2 Language of Parts; 3.1.6 Pronunciation (AAA).
- What happens:
  - On Android, `SpellOutStringAttribute` arrives as a `TtsSpan` and
    `LocaleStringAttribute` as a `LocaleSpan` over the same range.
    `Semantics(localeForSubtree:)` arrives as a `LocaleSpan` on the text.
  - On web, the two string attributes leave no trace in the DOM.
    `localeForSubtree: Locale('fr', 'FR')` writes `lang="fr_FR"`. A language
    tag uses a hyphen (`fr-FR`); whether browsers and screen readers accept
    the underscore form was not tested.
  - On iOS, the engine sets an attributed label. XCUITest cannot read speech
    attributes, and the utterance text was unchanged apart from spacing, so
    whether VoiceOver changes pronunciation was not confirmed.
- Effect: a phrase in another language inside a sentence cannot be marked on
  web, and a whole passage may be marked with a tag browsers do not
  recognise.
- Workaround: none found yet. To be worked out in S17 and S18.
- Upstream issue: not searched yet.

## FL-021

**No semantics for inline or block text structure.**

- Status: Observed, Flutter 3.47.5, batch 0 probe (`docs/evidence/probes/batch-0/`); the
  `SemanticsRole` and `SemanticsProperties` API was read.
- WCAG: 1.3.1 Info and Relationships.
- What happens: a `Text.rich` with a struck-through "20" and a bold "15" is
  the single string "Was 20 now 15 dollars" on web, Android, and iOS. Nothing
  says that one price is deleted. There is no SDK mechanism for emphasis,
  insertion and deletion, subscript and superscript, code, quotation,
  preformatted text, or a thematic break in the `Semantics` API; `Divider`
  exposes an empty node. As in FL-026, native HTML embedded with
  `HtmlElementView` on web was not probed. It is not a good example (D31) and
  may be shown as a labelled web workaround once verified (D32).
- Effect: meaning carried only by text styling is lost to screen reader
  users.
- Workaround: put the meaning in words, for example
  `Text.rich(…, semanticsLabel: 'Was 20 dollars, now 15 dollars')`.
- Upstream issue: not searched yet.

## FL-022

**Custom semantics actions are not exposed on web.**

- Status: Observed, Flutter 3.47.5, batch 0 probe (`docs/evidence/probes/batch-0/`).
- WCAG: 2.1.1 Keyboard, 2.5.1 Pointer Gestures, 2.5.7 Dragging Movements.
- What happens: `Semantics(customSemanticsActions: …)` with "Archive" and
  "Delete" gives two labelled actions on the Android node, and VoiceOver on
  iOS reads "Message from Ana, Actions available". On web the node is a plain
  element holding the label; the actions are not in the DOM.
- Effect: an alternative to a swipe or drag that is offered only as a custom
  action does not exist on web.
- Workaround: also offer the actions as visible controls or a menu. To be
  worked out in I05.
- Upstream issue: not searched yet.

## FL-023

**Material menu widgets do not use the menu roles, and their items have no button role on Android and iOS.**

- Status: Observed, Flutter 3.47.5, batch 0 probe (`docs/evidence/probes/batch-0/`);
  `material/menu_anchor.dart` contains no `SemanticsRole`.
- WCAG: 4.1.2 Name, Role, Value.
- What happens: a `MenuBar` with a `SubmenuButton` and a `MenuItemButton` is
  `role="group"` holding two `role="button"` elements on web, with
  `aria-expanded` on the submenu button. Opened, the items are a button, a
  `checkbox`, and a `radio`; nothing has `menubar`, `menu`, or `menuitem`. On
  Android "File" and "Help" are clickable `android.view.View` nodes, and on
  iOS VoiceOver reads "File" and "Help" with no "Button".
  `SemanticsRole.menuBar`, `menu`, `menuItem`, `menuItemCheckbox`, and
  `menuItemRadio` exist in the SDK; what they do when applied by hand was not
  probed.
- Effect: a menu bar is not announced as one, and on mobile its items are
  not announced as buttons.
- Workaround: none found yet. To be worked out in C15.
- Upstream issue: not searched yet.

## FL-024

**Tables have structure on web only, and a plain `Table` marks no headers by itself.**

- Status: Observed, Flutter 3.47.5, batch 0 probe (`docs/evidence/probes/batch-0/`).
- WCAG: 1.3.1 Info and Relationships.
- What happens: on web `DataTable` is `role="table"` with `row`,
  `columnheader`, and `cell`. The widgets-layer `Table` is `table`, `row`,
  and `cell` with no header cells when its children are plain `Text`: it does
  not infer a header row. `RenderTable` keeps a child that has
  `SemanticsRole.columnHeader`, which is how `DataTable` marks its headings,
  so wrapping a cell in `Semantics(role: SemanticsRole.columnHeader)` is the
  SDK mechanism; that was read in the source and not probed. On Android neither
  has `CollectionInfo` or `CollectionItemInfo`; the cells are plain views. On
  iOS the cells are static text in reading order.
- Effect: on mobile a screen reader user hears cell text with no row,
  column, or header.
- Workaround: none found yet. To be worked out in C19.
- Upstream issue: not searched yet.

## FL-025

**iOS accessibility APIs and settings with no Flutter counterpart.**

- Status: Confirmed, Flutter 3.47.5, by reading the SDK and searching the iOS
  engine source (`engine/src/flutter/shell/platform/darwin/ios`).
- What is missing:
  - Custom content (`accessibilityCustomContent`).
  - Custom rotors (`accessibilityCustomRotors`).
  - Magic Tap (`accessibilityPerformMagicTap`). Escape is implemented.
  - Voice Control input labels (`accessibilityUserInputLabels`).
  - The large content viewer.
  - `accessibilityIgnoresInvertColors`, so an image cannot be kept out of
    Smart Invert. `MediaQuery.invertColors` does report the setting.
  - The Reduce Transparency and Button Shapes settings.
    `AccessibilityFeatures` reports `accessibleNavigation`, `invertColors`,
    `disableAnimations`, `boldText`, `reduceMotion`, `highContrast`,
    `onOffSwitchLabels`, `supportsAnnounce`, `autoPlayAnimatedImages`,
    `autoPlayVideos`, and `deterministicCursor`, and nothing else.
- Effect: the iOS techniques for these features cannot be reproduced in
  Flutter without writing platform code, which is outside this project's
  rule that good examples use SDK mechanisms.
- Workaround: none within the SDK.
- Upstream issue: not searched yet.

## FL-026

**No semantics roles for grid, tree, treegrid, feed, separator, meter, or math.**

- Status: Confirmed, Flutter 3.47.5, by reading `SemanticsRole`; `TreeSliver`
  observed in the batch 0 probe (`docs/evidence/probes/batch-0/`).
- WCAG: 4.1.2 Name, Role, Value; 1.3.1 Info and Relationships.
- What happens: `SemanticsRole` has `tab`, `tabBar`, `tabPanel`, `dialog`,
  `alertDialog`, `table`, `cell`, `row`, `columnHeader`, `dragHandle`,
  `spinButton`, `comboBox`, `menuBar`, `menu`, `menuItem`,
  `menuItemCheckbox`, `menuItemRadio`, `list`, `listItem`, `form`, `tooltip`,
  `loadingSpinner`, `progressBar`, `hotKey`, `radioGroup`, `status`, `alert`,
  `complementary`, `contentInfo`, `main`, `navigation`, and `region`. The
  ARIA roles `grid`, `tree`, `treeitem`, `treegrid`, `feed`, `article`,
  `separator`, `meter`, `math`, and `figure` (noted while building S02
  Informative images) have no counterpart. The SDK's own
  `TreeSliver` exposes each row as a button, with no level and no expanded
  or collapsed state, on all three platforms.
- Effect: the APG Grid, Tree View, Treegrid, Feed, Window Splitter, and Meter
  patterns cannot be expressed through Flutter's semantics tree. The nearest
  roles (a slider for a splitter, a progress bar for a meter) tell the user
  something different.
- Scope of this entry: the `Semantics` API only. On web the SDK can also
  embed native HTML with `HtmlElementView`, which could carry any ARIA role.
  That route was not probed (the probe recorded only the wrapper around the
  embedded element). Decision D31 in [requirements.md](requirements.md) keeps
  good examples to widgets and the `Semantics` API, the mechanisms Flutter's
  web accessibility documentation names. Under D32 an entry may show
  embedded HTML as a labelled workaround on web, a lesser option, once it
  has been verified. None has been yet.
- Workaround: none through `Semantics` that keeps the pattern. Each entry
  documents the closest achievable example.
- What a card gets in place of `article`, measured in C18 (2026-11-22,
  `docs/evidence/probes/c18/`): a Material `Card` with
  `semanticContainer: false` makes no node of its own, so its parts are
  siblings of everything round it on the web and Android (XCUITest gives no
  hierarchy, so iOS's was not read); with the default,
  true, it is one node that takes in its text ([FL-269](#fl-269)). Cards in
  a `ListView` (fixture p14) are each an item node: on Android the list's
  node has collection information, three rows by one column, and TalkBack
  read the first card's heading with "In list. 3 items"; on the web each
  item is a `flt-semantics` element with no role. `SemanticsRole.list` and
  `listItem` round the cards (fixture p15) are `role="list"` and
  `role="listitem"` on the web, and on Android an `android.widget.ListView`
  that TalkBack reads as "In list". On iOS neither changed what XCUITest
  or VoiceOver showed: each part was read on its own, with no word about a
  list (`ios.txt`, p14, p15). None of these says
  "article". C18 relies on each card's heading to mark where it starts, as
  MDN's `article` page says an article should be identified.
- How to read this entry: these are roles Flutter has not added yet. Treat
  it as unfinished work in the framework, and re-check it whenever the
  pinned version changes.
- Upstream issue: not searched yet.

## FL-027

**A progress indicator whose value has a percent sign reports an empty range on Android.**

- Status: Confirmed (source read), Flutter 3.47.5, batch 0 probe
  (`docs/evidence/probes/batch-0/`); `material/progress_indicator.dart`
  read; measured again, with TalkBack, in the C26 probe
  (`docs/evidence/probes/c26/`, p01 to p03), and the engine source read
  for C26.
- WCAG: 4.1.2 Name, Role, Value.
- What happens: `LinearProgressIndicator(value: 0.4, semanticsValue: '40%')`
  sets `minValue: '0'` and `maxValue: '100'`, and is an
  `android.widget.ProgressBar` whose `RangeInfo` is 0 to 0 with current 0.
  `Semantics(role: SemanticsRole.progressBar, value: '40', minValue: '0',
  maxValue: '100')` gives 0 to 100 with current 40. On web both give
  `aria-valuenow="40"`.
- Cause (engine source read for C26):
  `shell/platform/android/io/flutter/view/ProgressBarRoleConfigurator.java`
  parses the value with `Float.parseFloat`; "40%" fails, and from Android
  16 (API 36) the range is given the indeterminate type, 0 to 0 (the C26
  probe on Android 17 read `RANGE_TYPE_INDETERMINATE`, 3); before 16, a
  float range 0 to 0.
- The widget's default value (no `semanticsValue`), measured in C26: the
  percentage as a bare number, "40", which Android parses: a float range 0
  to 100 with current 40. TalkBack then reads the value twice, first from
  the range as a decimal and then from the description: "40.0.", "40,",
  the name, "Progress bar" (C26 probe, `android-talkback.md`, p01). With
  "40%" it reads "40%,", the name, "Progress bar", once, and the range is
  lost. So on Android the default gives a range and a doubled reading,
  and a percent sign gives one reading and no range. VoiceOver on iOS
  reads the default as "p01 Upload 40", the number with no unit, and
  "40%" as "40%" (C26 probe, `ios.txt`). VoiceOver on the web, in
  Chromium and in WebKit, reads the default twice as well: C26
  `good-linear`'s bar at 0 was "Report upload 0 0% progress indicator",
  the name, which holds the value on the web ([FL-037](#fl-037)), then the
  value as a percentage, and `bad-no-label`'s "0 0% progress indicator"
  (`docs/evidence/C26/voiceover-web.md`; the first recording read the same). The
  element has `aria-valuenow="0"`, min 0, max 100, and no
  `aria-valuetext`; where VoiceOver's "0%" comes from was not measured. A
  percent sign on the web was not recorded with VoiceOver. The documentation says the
  default is "10%" for 0.1 ([FL-258](#fl-258)).
- Effect: anything that reads the range gets nothing when the value has a
  percent sign; the node's description still holds it ("40%, Storage
  used").
- Workaround: none that serves both. C26's good bar keeps the default, by
  the principal's decision in review (C26's spec, section 8), for the
  range, with the doubled reading on Android and the web and the bare
  number on iOS as a qualification.
- Upstream issue: not searched yet.

## FL-028

**A slider has no accessible name on web.**

- Status: Confirmed, Flutter 3.47.5. Found in the S01 probe
  (`docs/evidence/probes/s01/`); asserted by
  `web_tests/s01_accessible_names.spec.js` (`bad-slider-name-web`) and, for
  every F10 example, by `web_tests/f10_slider.spec.js` ("every slider"),
  and heard in `docs/evidence/S01/voiceover-web.md` and
  `docs/evidence/F10/voiceover-web.md`. Engine source read:
  `lib/web_ui/lib/src/engine/semantics/incrementable.dart`.
- WCAG: 4.1.2 Name, Role, Value; 1.3.1 Info and Relationships.
- What happens: the framework gives the slider's node its label. On web the
  engine draws that node as a `flt-semantics` element with no role, puts
  `aria-label` on it, and appends an `<input type="range" role="slider">`
  inside it. The input is the element that takes focus and has the role and
  the value, and it gets no `aria-label` and no `aria-labelledby`. Chromium
  computes an empty accessible name for the slider. The same happens for
  `Semantics(label:)` around a `Slider`, for `MergeSemantics` around a
  `Slider` and its text, for `CupertinoSlider`, and (F10 probe) for a
  slider built from `Semantics(slider: true, label:, onIncrease:, ...)`
  with or without the slider flag: every node with an increase or
  decrease action.
- Not affected: Android (`SeekBar` with description "40%, Volume") and iOS
  (label "Volume", value "40%"). Checkbox, switch, and radio elements on web
  carry `aria-label` on the element that has the role.
- Effect: the slider has no name of its own, so a list of form controls or
  a move by Tab gives a slider and a value with no word on what it adjusts,
  and speech input cannot address it by name. Heard with VoiceOver on macOS
  in Chromium, moving with the VoiceOver cursor: "Volume group" as one stop,
  then "40% dimmed slider". What is spoken when Tab lands on the slider was
  not recorded.
- "Dimmed": see [FL-127](#fl-127). The input was found disabled after
  each walk that read a slider; whether it is disabled at the moment
  VoiceOver speaks was not established.
- With a label on the input, as in plain HTML, VoiceOver in Chromium
  reads "40% Volume slider" (F10 web VoiceOver control,
  `plain-labelled-input`).
- Fixed in Flutter 3.50.0, by its source, not verified: 3.50.0's
  `incrementable.dart` copies the wrapper's `aria-label` onto the input.
  The pin is 3.47.5 (D21); re-run the F10 and S01 web tests on the
  upgrade, which are written to fail when the name arrives.
- How to reproduce: `/t/S01/bad-slider-name-web` or any `/t/F10/` example,
  on web.
- Workaround: none found in the SDK. Tried in F10: none of the ways of
  giving the label changes where it lands. Not a workaround: putting the
  name in the value text with `semanticFormatterCallback`, which makes it
  part of `aria-valuetext` and not a name, and would change what Android
  and iOS say.
- Upstream issue: not searched yet (D25).

## FL-029

**A Material `Slider` adds an empty full-screen element that takes pointer events on web.**

- Status: Confirmed, Flutter 3.47.5, web. First seen while recording
  VoiceOver for `/t/S01/bad-slider-name-web`; asserted by
  `web_tests/f10_slider.spec.js` ("the empty element over the page").
  Framework source read: `material/slider.dart`, `widgets/overlay.dart`,
  and `semantics/semantics.dart`; engine source read:
  `lib/web_ui/lib/src/engine/semantics/semantics.dart`.
- Cause: every `Slider` keeps an `OverlayPortal` shown for its value
  indicator ("Always keep the ValueIndicator visible on the Overlay"). The
  portal's child is laid out in the `Overlay` at the size of the whole
  overlay by a `_DeferredLayout` render object, which marks its semantics
  with `traversalChildIdentifier` and so makes a node of its own, with
  nothing in it. Off the web the framework grafts such a node under its
  traversal parent; on the web it keeps the paint order, so the node stays
  in the overlay, last, the size of the view. The engine gives a leaf node
  with no role `pointer-events: auto`.
- What happens: one empty `flt-semantics` element per Material `Slider`
  on the screen (ten sliders, ten elements, in the F10 probe), with no
  role, label, or children, the size of the whole view, with
  `pointer-events: auto`, after the other nodes in document order. It is
  there with and without `divisions`, with
  `showValueIndicator: ShowValueIndicator.never`, inside `Overlay.wrap`,
  for a disabled `Slider`, and for `Slider.adaptive` where it draws a
  `CupertinoSlider`. A `CupertinoSlider` itself, a `RangeSlider`, and a
  slider built on `Semantics` add none. Android and iOS have no such node
  (F10 probe).
- Effect, tested in F10: `document.elementFromPoint` anywhere on the page
  finds the empty element, not the control under the pointer, so
  anything that finds an element by position gets nothing: Playwright
  refuses to click any other semantics element ("intercepts pointer
  events"). Whether touch exploration by a screen reader in a phone's
  browser, which also finds elements by position, is affected was not
  tested. A real mouse click still works,
  because Flutter takes pointer events for the whole view and hit-tests
  them itself: the Back button beside a slider goes back. A click event
  sent to the button element, as a screen reader's activation is, works
  too, and so does VoiceOver's own press (F10 web VoiceOver test).
  Keyboard operation is not affected.
- Seen on the same screens, cause not proven: with Playwright's WebKit
  build, VoiceOver's cursor leaves the page content on a screen with a
  Material `Slider`, and walks screens without one normally. Moving on
  from the Back button, which it has just read, it reads at most the
  screen title and then only the page's web area, "<document title> web
  content", again and again with empty phrases between, and never the
  example. In F10 that held for all five Material
  screens on every walk recorded, and for none of the four others
  (`docs/evidence/F10/voiceover-web.md`); S01 and S14 saw the same. The
  F10 web VoiceOver spec requires VoiceOver to read Back before the walk,
  the web area at least twice and nothing else during it, and Back again
  when it is focused after it, so a walk that heard nothing fails instead
  of passing. It is
  written to fail when the cursor starts reaching the slider. The empty
  element is the only difference found between the two kinds of screen;
  the test cannot rule out the harness. The WebKit build is not Safari;
  Safari was not tried.
- Also seen in C05 (2026-11-21), for `CupertinoExpansionTile`: once any
  of its sections has been opened, one empty `flt-semantics` element the
  size of the view, with `pointer-events: auto`, lies over the page; before
  that there is none (`docs/evidence/probes/c05/click_probe.txt`, from
  `c05_probe_click.spec.js.txt`). Framework source read:
  `cupertino/expansion_tile.dart` shows an `OverlayPortal` for its fade on
  the first tap of a header (`_fadeController.show()`) and never hides it.
  That its node is made the way the `Slider`'s is (`_DeferredLayout`) was
  not traced. Asserted by `web_tests/c05_accordion.spec.js` ("the empty
  element over the page"), written to fail when it goes: none on the other
  C05 examples, closed or open; on `bad-cupertino-expansion-tile` none
  while closed and one once opened, a hit test at the "Example" heading
  finds it, Playwright's checked click on the heading is refused, and a
  real mouse click on the Returns header still opens it. In C05's second
  web VoiceOver recording the test of that example ran into its timeout
  after its closed walk, with no open walk logged
  (`docs/evidence/probes/c05/voiceover-web-round2-fail.md.txt`); the open
  walk begins with a checked click on the heading, which the probe shows
  is refused there.
- How it is handled here: `walkFromBack` in `web_tests/vo/vo_helpers.js`
  takes a `clickAtPoint` flag for these screens, which clicks with the
  mouse at a position and skips Playwright's check. C05's web VoiceOver
  spec has its own `walkToEndClickingAtPoint`, `walkToEnd` with that click,
  for the open Cupertino tile.
- Workaround: none in the SDK for a Material `Slider`. Tried in F10:
  `showValueIndicator: never` and `Overlay.wrap` around the slider. A
  `CupertinoSlider` or a custom slider has no such element.
- Upstream issue: not searched yet (D25).

## FL-030

**A label on an `Image` inside a button does not name the button.**

- Status: Confirmed, Flutter 3.47.5. Found in the S04 probe
  (`docs/evidence/probes/s04/`); asserted by the S04 widget, web, Android,
  and iOS tests (`bad-label-on-image`) and heard in
  `docs/evidence/S04/talkback-android.md` and
  `docs/evidence/S04/voiceover-ios.md`. Framework source read:
  `packages/flutter/lib/src/widgets/image.dart`.
- WCAG: 4.1.2 Name, Role, Value; 1.1.1 Non-text Content.
- What happens: `Image` wraps itself in
  `Semantics(container: semanticLabel != null, image: true, label: ...)`.
  With a label, `container` is true, so the image is always a semantics node
  of its own and its label is not merged into a control around it. For
  `IconButton(icon: Image(semanticLabel: 'Open trail guide'))` the tree is a
  button node with no label and, as its child, an image node with the label.
  - Android: a `Button` with no description that can be clicked, and inside
    it an `ImageView` "Open trail guide" that cannot. TalkBack, with focus
    moved to each: "Button", then "Open trail guide, Image".
  - iOS: a button with no label and an image "Open trail guide". VoiceOver
    stops twice: "Button", then "Open trail guide, Image".
  - Web: `role="button"` with no `aria-label` and a `role="img"` child with
    `aria-label`. Chromium computes the button's name from the child, and
    VoiceOver on macOS reads "Open trail guide, button" as one stop in
    Chromium and in Playwright's WebKit build. The web is not affected.
- The same split with other tappable parents: `InkWell` or `GestureDetector`
  around a labelled `Image` gives a tappable node with no name and no role,
  with the image inside it. VoiceOver on iOS stops on that node and says
  nothing, then reads the image. (`XCUIVoiceOverService` reports "No speech
  available"; the test takes it as a stop because one move back reads the
  element before it and the move forward again is silent too.) TalkBack,
  with focus moved to that node, said "Button" in two recordings and
  nothing in a third, and never the name (`bad-tap-gesture`).
- The same for a link (C03, 2026-11-20, `/t/C03/bad-label-on-image`,
  asserted in its widget, web, Android, and iOS tests): an `InkWell` in
  `Semantics(link: true, linkUrl:)` with `Image(semanticLabel:)` inside is
  a link node with no name and, as its child, an image with the name.
  Android: a clickable `View` with no name and, because the address rides
  on the name ([FL-220](#fl-220)), no `URLSpan` either, round an
  `ImageView`; TalkBack reads the picture "Read about stand-alone links /
  Image". iOS: a link with no label and an image; VoiceOver stops twice,
  "Link", then "Read about stand-alone links Image". Web: an `<a href>`
  holding a `role="img"`, which Chromium names the link from. The
  workaround is the same: `Semantics(label:)` on the link and
  `excludeFromSemantics: true` on the picture (C03 `good-image-link`).
- Not affected: `Icon(semanticLabel:)`. An `Icon`'s label is not a container
  and becomes the name of the button around it on all three platforms
  (`good-icon-label`).
- Why it matters: `Image.semanticLabel` is the documented text alternative
  for an image, and on the web and in native toolkits the alternative of an
  image inside a button is the button's name. Code written that way in
  Flutter gives Android and iOS users a button with no name.
- How to reproduce: `/t/S04/bad-label-on-image` in the app.
- Workaround, in the SDK: name the control, not the image, and exclude the
  image. `IconButton(tooltip: ..., icon: Image(excludeFromSemantics: true))`
  (`good-image-button`), or `Semantics(button: true, label: ...)` around a
  custom control (`good-custom`). Not tried: `MergeSemantics` around the
  button.
- Upstream issue: not searched yet (D25).

## FL-031

**An `Image` left in a button's semantics makes the button an image as well.**

- Status: Confirmed, Flutter 3.47.5. Found in the S04 probe
  (`docs/evidence/probes/s04/`); asserted by the S04 widget, Android, and
  iOS tests (`bad-image-not-excluded`, `bad-no-name`) and heard in
  `docs/evidence/S04/voiceover-ios.md`. Engine source not read.
- What happens: an `Image` with no `semanticLabel` and without
  `excludeFromSemantics: true` contributes `image: true` and no node of its
  own (`container` is false, see FL-030). Inside a button the flag is merged
  into the button's node, which is then a button and an image. Seen with
  `TextButton(child: Row(children: [Image(...), Text('Trail guide')]))` and
  with `IconButton(icon: Image(...))`.
  - iOS: VoiceOver reads "Trail guide, Button, Image". XCUITest still
    reports a button.
  - Android: the node's class is `android.widget.ImageView`, not
    `android.widget.Button`, though it can be clicked. TalkBack, with focus
    moved to it, still says "Trail guide, Button" and does not say "Image".
    A tool that goes by the class sees an image.
  - Web: `role="button"` only. Not affected.
- The same merging outside a button is in S03 (`bad-merged-image`): an
  unlabelled `Image` in a `MergeSemantics` row makes the row an image on all
  three platforms.
- Why it matters: the picture is decoration inside the button, and it is
  announced as part of the button's role on iOS. It is not a WCAG failure on
  its own, because the button role and name are still there.
- How to reproduce: `/t/S04/bad-image-not-excluded` in the app, with
  VoiceOver on iOS.
- Workaround, in the SDK: `excludeFromSemantics: true` on every `Image`
  inside a control (`good-image-with-text`).
- Upstream issue: not searched yet (D25).

## FL-032

**`Semantics(link: true)` without `linkUrl` is a link on iOS only.**

- Status: Confirmed, Flutter 3.47.5: first seen in the S13 probe
  (`docs/evidence/probes/s13/`, round 1, fixtures 02, 03, and 20; and
  fixtures 08 and 09 of `docs/evidence/probes/s04/`), asserted by C03
  `bad-no-address` (below). Engine source read:
  `shell/platform/android/io/flutter/view/AccessibilityBridge.java`
  (`shouldBeTreatedAsButton`).
- WCAG: 4.1.2 Name, Role, Value.
- What happens: `Semantics(link: true, onTap: ...)` with no `linkUrl`:
  - iOS: the link trait. VoiceOver reads "Link".
  - Android: the node's class is `android.widget.Button`. The engine's
    comment says "a link is treated as a button if and only if it does not
    have a URL". What TalkBack says was not recorded.
  - Web: an `<a>` element with no `href`. An anchor with no `href` has no
    link role; Playwright's ARIA snapshot shows it as text. A node with
    `button: true` and `link: true` becomes the same `<a>` and so loses the
    button role as well.
- With `linkUrl`: the web element is `<a href>`, a real link, and the
  Android node is a `View` (the engine attaches the URL as a `URLSpan`; what
  TalkBack says was not recorded). On the web the browser then follows the
  `href` as well as running `onTap` ([FL-013](#fl-013)).
- Why it matters: `link: true` reads as the way to give a custom control the
  link role, as `button: true` gives the button role. On two of three
  platforms it does not.
- Also seen in V13 (2026-11-19), `/t/V13/good-inline-link`:
  `Semantics(link: true)` around a `GestureDetector`, in a `WidgetSpan`,
  with no `linkUrl`. iOS: XCUITest's type is link, and VoiceOver reads
  "trail rules Link" (`docs/evidence/V13/voiceover-ios.md`). Android:
  TalkBack reads "trail rules / Button / Double-tap to activate"
  (`docs/evidence/V13/talkback-android.md`). Web: the `<a>` with no
  `href`; Chromium's own accessibility tree, read over the DevTools
  protocol, gives it the role link (asserted in
  `web_tests/v13_touch_target_size.spec.js`), where HTML-AAM maps an `a`
  with no `href` to generic and Playwright's role check finds no link.
  What VoiceOver says for it on the web is in
  `docs/evidence/V13/voiceover-web.md`.
- Confirmed in C03 (2026-11-20), `/t/C03/bad-no-address`, asserted in its
  widget, web, Android, and iOS tests: an `InkWell` in
  `Semantics(link: true)` with no `linkUrl` is a `Button` on Android, which
  TalkBack reads "Read about stand-alone links / Button / Double-tap to
  open link" (the last words are the example's `onTapHint`), a link for
  VoiceOver on iOS, and on the web an `<a>` with no `href` that
  Playwright's role check does not find as a link, while VoiceOver says
  "link Read about stand-alone links" in Chromium and WebKit
  (`docs/evidence/C03/voiceover-web.md`): the browsers' own trees call
  it a link, as V13 found for Chromium. With `linkUrl` (C03's probe p02 to
  p06 and its good examples), TalkBack says no role at all
  ([FL-220](#fl-220)).
- Also in C04 (2026-11-21), `/t/C04/bad-text-span`: a `TextSpan` with a
  `TapGestureRecognizer` gets the link flag and no address from the
  framework, so it is an `android.widget.Button` that TalkBack reads "… /
  Button / Double-tap to activate", and on the web an `<a>` with no `href`;
  there is no way to give it one ([FL-240](#fl-240)).
- Workaround, verified in C03's good examples on every layer: give
  `linkUrl` as well, and on the web leave the following to the browser
  ([FL-013](#fl-013)).
- Upstream issue: not searched yet (D25).

## FL-033

**A switch or checkbox with no `enabled` flag is read as dimmed by VoiceOver on iOS.**

- Status: Confirmed, Flutter 3.47.5. Found in the S13 probe
  (`docs/evidence/probes/s13/`); asserted by the S13 iOS tests
  (`bad-switch-not-enabled`: the tree, and VoiceOver's speech in
  `docs/evidence/S13/voiceover-ios.md`). Engine source read:
  `shell/platform/darwin/ios/framework/Source/SemanticsObject.mm`
  (`FlutterSwitchSemanticsObject`).
- WCAG: 4.1.2 Name, Role, Value (the state that is exposed is wrong).
- What happens: `Semantics(toggled: value)` or `Semantics(checked: value)`
  with no `enabled` argument has no enabled state at all: it is neither
  enabled nor disabled. On iOS the engine backs such a node with a native
  `UISwitch` and sets `nativeSwitch.enabled = (isEnabled == true)`, so an
  absent flag counts as disabled.
  - iOS: XCUITest reports the switch as not enabled, and VoiceOver reads
    "Dark mode, dimmed, Switch button, off". The switch still works.
  - Android: an ordinary enabled `Switch`. Not affected.
  - Web: `role="switch"` with no `aria-disabled`. Not affected.
- Not affected: a node with `button: true` and no `enabled` (for example a
  `CupertinoButton`, [FL-001](#fl-001)) is not read as dimmed. The SDK's
  `Switch`, `Checkbox`, their list tiles, and `CupertinoSwitch` all set
  `enabled`.
- Why it matters: "dimmed" tells a VoiceOver user the control cannot be
  used. The `Semantics` documentation does not say that `toggled` or
  `checked` needs `enabled`.
- How to reproduce: `/t/S13/bad-switch-not-enabled` in the app, with
  VoiceOver on iOS.
- Workaround, in the SDK: pass `enabled: true` with `toggled` or `checked`
  (`/t/S13/good-custom-switch`).
- Upstream issue: not searched yet (D25).

## FL-034

**`Semantics(keyboardKey: true)` has no effect on any platform.**

- Status: Observed, Flutter 3.47.5, in the S13 probe
  (`docs/evidence/probes/s13/`, round 1, fixtures 10 and 11). No example and
  no test in the repo. Engine source read for iOS, Android, and web.
- What happens: the flag is sent to the engine and nothing uses it.
  - iOS: `SemanticsObject.mm` sets no trait for it;
    `UIAccessibilityTraitKeyboardKey` does not appear in the iOS engine
    source. VoiceOver reads a node with only this flag as plain text.
  - Android: `AccessibilityBridge.java` defines `IS_KEYBOARD_KEY` and never
    reads it. The node is a `View`.
  - Web: no role handles it. The node is a button only if it has a tap
    action ([FL-006](#fl-006)).
- Why it matters: the iOS reference technique lists the keyboard key trait,
  which on iOS lets VoiceOver users type on a custom keypad in the way they
  have chosen for the system keyboard. A Flutter keypad cannot have it. Use
  `button: true` on each key, which is what the SDK's own widgets do.
- Also without a Flutter counterpart, from the same list of traits:
  plays sound, starts media session, allows direct interaction, causes page
  turn, summary element, search field, and tab bar as a trait (the tab roles
  are `SemanticsRole.tab` and `tabBar`, left to the tabs technique). Static
  text is given by the engine to a node with a label and no other trait,
  and "updates frequently" is set from `liveRegion: true` (I12).
- Workaround: none for the trait.
- How to read this entry: Flutter has not added these yet. Re-check when the
  pinned version changes.
- Upstream issue: not searched yet (D25).

## FL-035

**A checkbox is a switch for VoiceOver on iOS.**

- Status: Confirmed, Flutter 3.47.5. Asserted by the S13 iOS tests
  (`good-standard`: the tree, and VoiceOver's speech in
  `docs/evidence/S13/voiceover-ios.md`); first heard in the S01 probe.
  Engine source read:
  `shell/platform/darwin/ios/framework/Source/accessibility_bridge.mm`.
- What happens: the iOS engine backs every node that has a `toggled` or a
  `checked` state, and is not in a mutually exclusive group, with the same
  object, which borrows the traits and value of a native `UISwitch`. A
  `Checkbox`, a `CheckboxListTile`, and `Semantics(checked:)` are therefore
  switches to XCUITest, and VoiceOver reads "Remember me, Switch button,
  off. Double tap to toggle setting". Android (`CheckBox`) and the web
  (`role="checkbox"`) keep the two apart.
- Why it matters: UIKit has no checkbox control, so there is no native
  wording to match, and on/off is a fair reading of checked/unchecked. But a
  screen that shows a tick box and a switch reads both as switches, and
  support staff or documentation that says "tick the box" does not match
  what is heard. For a checkbox with two states this is not a WCAG failure:
  the role is a near equivalent and on/off follows checked/unchecked.
- A checkbox with three states is worse off (engine source read, not
  probed): `accessibilityValue` sets the native switch on only when the
  state is checked, so the mixed state of `Checkbox(tristate: true, value:
  null)` is read as "off". F07 probed and confirmed it; see
  [FL-044](#fl-044).
- Workaround: none within the SDK.
- Upstream issue: not searched yet (D25).

## FL-036

**No way to reword the state of a switch or checkbox; `value` on one is handled three different ways.**

- Status: Confirmed, Flutter 3.47.5. Found in the S14 probe
  (`docs/evidence/probes/s14/`, fixtures 06 to 08); asserted by the S14
  widget, web, Android, and iOS tests (`bad-value-on-switch`) and heard in
  the S14 transcripts. Engine source read for iOS
  (`FlutterSwitchSemanticsObject.accessibilityValue` in `SemanticsObject.mm`)
  and searched for Android (`AccessibilityBridge.java` never calls
  `setStateDescription`).
- What is missing: Android lets an app replace "checked" and "not checked",
  or "on" and "off", with words that fit the control
  (`View.setStateDescription`, `stateDescription` in Compose), which is the
  subject of the Android reference technique "Custom State Descriptions".
  `Semantics` has no such property, and the Android engine sets no state
  description.
- What happens if `value` is used for it, as in
  `Semantics(toggled: on, value: on ? 'Activated' : 'Deactivated')`:
  - Android: the value is written into the content description, "Deactivated,
    Home alarm", beside the checked state. TalkBack reads both wordings.
  - iOS: the value is dropped. The switch's value is its own 0 or 1, and
    VoiceOver reads "Home alarm, Switch button, off".
  - Web: the value is appended to the name: `role="switch"` named "Home
    alarm Deactivated", with `aria-checked`. The name changes every time the
    switch does ([FL-037](#fl-037)).
- Why it matters: the standard wording is not a failure, so nothing is lost
  by leaving it alone. The harm comes from trying: the state is said twice
  on Android, and on the web the control's name is no longer stable.
- Workaround: none within the SDK. Keep the standard wording, and put any
  extra meaning in the label ("Home alarm" on or off is clear enough).
- How to read this entry: Flutter has not added this yet. Re-check when the
  pinned version changes.
- Upstream issue: not searched yet (D25).

## FL-037

**On web a `value` is appended to the accessible name.**

- Status: Confirmed, Flutter 3.47.5, web. Found in the S14 probe; asserted
  by `web_tests/s14_values_and_state_descriptions.spec.js` (`good-step`,
  `good-button-value`, `bad-value-on-switch`). Engine source not read.
- What happens: for a node that is not adjustable, `Semantics(label: 'Repeat',
  value: 'All')` becomes one string, "Repeat All": the text of the element,
  or its `aria-label` when it has a role that takes one. A button is
  `role="button"` with the accessible name "Repeat All"; plain text reads
  "Progress Step 2 of 4". Only an adjustable node keeps the two apart, with
  the value in `aria-valuetext`.
- Why it matters: a screen reader user hears the same words in the same
  order as on iOS, so reading is not harmed. But the name is no longer the
  name: it changes with the state, a test or script that finds the control
  by its name has to know the state, and a speech-input user who says the
  visible label still matches only because the label comes first. HTML has
  no general "value" for a button, so there is no obvious better mapping;
  `aria-description` would be one candidate.
- Workaround: none needed for reading. In tests, find the control by its
  identifier and assert the whole name.
- Sliders (F10): an enabled slider is adjustable and keeps its value in
  `aria-valuetext`. A disabled one is not adjustable, so its value is
  appended to its name like any other node's: "Volume 40%" as plain text
  (F10 probe; [FL-124](#fl-124)).
- Progress bars (C26): a determinate indicator is a `progressbar` whose
  value is in its name as well as in `aria-valuenow`: "Report upload 0".
  VoiceOver, in Chromium and WebKit, then read the value twice: "Report
  upload 0 0% progress indicator", and with no label "0 0% progress
  indicator" (`docs/evidence/C26/voiceover-web.md`;
  [FL-027](#fl-027)). So for a progress bar, unlike the "Why it matters"
  above, the user hears the number twice; whether the name's copy of the
  value is the cause was not measured.
- Upstream issue: not searched yet (D25).

## FL-038

**On Android an adjustable node shows `increasedValue` as its value straight after the action.**

- Status: Confirmed, Flutter 3.47.5, Android. Asserted by
  `S14ValuesAndStateDescriptionsTest.badStaleValueKeepsItsFirstValue`.
  Engine source read: `AccessibilityBridge.java`, in the handling of
  `ACTION_SCROLL_FORWARD` and `ACTION_SCROLL_BACKWARD`
  (`semanticsNode.value = semanticsNode.increasedValue`).
- What happens: when TalkBack (or any service) sends the increase action,
  the Android bridge sends it to the app and at once replaces the node's
  value with its `increasedValue`, without waiting for the app's next
  semantics update. If the app then sends an update, that wins. If it does
  not, the guess stays.
- Why it matters: `increasedValue` and `decreasedValue` are not just hints.
  On Android they are what the user hears after adjusting, until the app
  says otherwise. A control with a wrong or missing `increasedValue`
  announces a wrong value, or none. In `bad-stale-value`, whose semantics
  never change, the node read "3 out of 5", then "4 out of 5" after one
  increase and still "4 out of 5" after a second, with five stars showing.
- Related, on the web (S14 probe and `bad-rating-no-value`): with no
  `increasedValue` and no `decreasedValue` the slider element has the same
  minimum and maximum. The arrow keys still reach the app. Whether a
  screen reader's adjust command can move such a slider was not tested.
- Workaround: always give `increasedValue` and `decreasedValue` with
  `onIncrease` and `onDecrease`, computed from the current value, as
  `good-rating` does.
- Sliders (F10): the SDK's `Slider` and `CupertinoSlider` compute both
  from the value, so the guess is right: straight after the action the
  node already reads the new value, "50%, Volume", before the app has
  acted. Only the value is guessed: for F10 `bad-indicator-label`, whose
  name holds the number too, one run read "50%, Volume\n4" at that
  moment, which is what shows the value arriving ahead of the app's own
  update; no test holds the app back to prove that order.
  `F10SliderTest.everySliderIsASeekBarWithItsValueAndName` asserts that
  the new value is in the description (it waits up to two seconds for the
  tree to show it, since one CI run still read the old one on the next
  line), and shows the other side: a test that waits for the description
  to change cannot tell that the app has acted, and has to wait for the
  app's own change count. At the last value `Slider` repeats the value as
  `increasedValue`, so an increase there shows the same value. The F10
  custom sliders do the same.
- Upstream issue: not searched yet (D25). This is probably intended.

## FL-039

**On Android a hint is the end of the content description, not a hint.**

- Status: Confirmed, Flutter 3.47.5, Android. Asserted by
  `S15HintsTest.buttonsHaveTheirNameAndHintInTheDescription`. Engine source
  read: `AccessibilityBridge.java`, `getValueLabelHint()`, which joins
  value, label, and hint with ", " and is used for `setContentDescription`.
- What happens: `Semantics(label: 'Favorite', hint: 'Adds this item to your
  favorites.')` on a button gives an Android node whose content description
  is "Favorite, Adds this item to your favorites.". Its hint text, tooltip
  text, and state description are empty. A text field is the exception:
  label and hint go into the node's hint text (`getTextFieldHint()`, see
  [FL-015](#fl-015)), joined the same way: "Username, 4 to 10 characters,
  no spaces." (asserted by
  `F02InputInstructionsTest.fieldsHaveTheirLabelAndInstructionInTheHintTextBeforeAndAfterTyping`).
- Why it matters: to TalkBack the hint is part of the name. It is read
  before the role ("Favorite, Adds this item to your favorites, Button"),
  not after it as on iOS, and it is read every time, at once. It is not
  in any field that a screen reader could treat as optional, which is what
  a hint is on iOS; whether a TalkBack setting shortens it was not tested.
  Anything that matches a control by
  its description (Voice Access, a UI test) has to match the hint as well.
  Android has no general hint for a view, so there is no exact place to put
  it; the cost is that a hint is a heavier thing on Android than on iOS, and
  should be short and used sparingly.
- Workaround: none. Keep hints short, and use one only where the name does
  not say what the control does.
- Upstream issue: not searched yet (D25). This is probably intended.

## FL-040

**`Semantics(hint:)` around a Material button stays on a node of its own.**

- Status: Confirmed, Flutter 3.47.5, all platforms. Asserted by the widget
  test "bad-hint-detached", `web_tests/s15_hints.spec.js`,
  `S15HintsTest.badHintDetachedHasTheHintOnANodeOfItsOwn`, and the iOS
  VoiceOver walk.
- What happens: Material buttons (`ButtonStyleButton`: `FilledButton`,
  `ElevatedButton`, `OutlinedButton`, `TextButton`) wrap themselves in
  `Semantics(container: true, button: true)`. A container starts a new
  semantics node, so a `Semantics(hint: ...)` above it has nothing to join
  and becomes a node with a hint and nothing else: no name, no role, no
  action. The button's node has no hint. The same wrapper around a
  `CupertinoButton`, a `ListTile`, or an `InkWell` does reach the control,
  because those are not containers.
- What the user gets: on Android and iOS the hint is an element of its own
  in front of the button, read with no name and no role, and the button is
  read without it. On the web the node has no name, so nothing is rendered
  for it ([FL-041](#fl-041)) and the hint is gone.
- Why it matters: the code looks right and analyses clean, and the same
  line works for other widgets. Nothing warns that the hint missed.
- Workaround: wrap both in `MergeSemantics`, as `good-result` does:
  `MergeSemantics(child: Semantics(hint: ..., child: FilledButton(...)))`.
  The project's `TestId` wrapper is a `MergeSemantics`, so a button inside
  one already gets the hint; `bad-hint-detached` has no `TestId` for that
  reason.
- Also seen in C02 (2026-11-20), the same mechanism for a state. Observed:
  seen in the probe only; no test asserts it.
  `Semantics(toggled:, enabled: true)` around an `IconButton` or an
  `OutlinedButton` does not reach the button (`docs/evidence/probes/c02`,
  fixtures t04 and t18). The
  button's node has no toggled state, and a second node with the state and
  no name is made. On the web it is a `role="switch"` around the button,
  named by the button's text inside it; on Android a `Switch` with no
  name with the same bounds as the `Button`, which has no state; on iOS
  a switch with no label at the button's place, which VoiceOver did not
  stop on (it read only "t04 Bold Button"). Inside `MergeSemantics` both
  join the button's node (fixtures t20 and t21); C02's
  `good-icon-button` and `bad-label-changes` put `MergeSemantics` round
  it. The same wrapper around a `CupertinoButton` reaches it without help
  (fixture t13).
- Also seen in C12 (2026-11-21), the same mechanism for a tooltip:
  `Tooltip(message:)` round an `IconButton` or a `FilledButton` puts the
  tooltip on a node of its own outside the button, and the button has no
  name of its own from it (`docs/evidence/probes/c12`, fixtures t02, t04,
  t08 to t10, t13, on every platform; C12 `bad-outside-button`). TalkBack
  read the outer node's tooltip and then "Button"; VoiceOver on iOS passed
  over the outer node ([FL-252](#fl-252)). Inside `MergeSemantics` the
  tooltip joins the button (t03, t05, t06; C12 `good-description`).
- Upstream issue: not searched yet (D25). The container is deliberate; a
  `hint` (or `semanticHint`) parameter on the buttons has not been added.

## FL-041

**On web a hint on a node with no label is not rendered, unless the node is a text field.**

- Status: Confirmed, Flutter 3.47.5, Web (Chromium and WebKit DOM). Seen in
  the [S15 probe](evidence/probes/s15/README.md) (fixtures 02, 14, and 17)
  and asserted through `bad-hint-detached` in `web_tests/s15_hints.spec.js`.
  Engine source read: `LabelAndValue.update()` in
  `lib/web_ui/lib/src/engine/semantics/label_and_value.dart`, which returns
  before `_updateHintDescription` when the computed label is null; and
  `text_field.dart`, which sets `aria-description` on the `<input>` on a
  path of its own.
- What happens: for a node that is not a text field, a hint becomes
  `aria-description` on the element, and that line is reached only when
  the node has a label, a value, or a tooltip. A button or plain node with
  a hint alone gets no description, and since it has no text either, the
  hint is nowhere in the page. A text field is different: its hint is set
  on the `<input>` whether or not the field has a label (fixture 17), and
  it stays there once the field has a value
  (`web_tests/f02_input_instructions.spec.js`). On
  Android and iOS the hint of an unnamed button is read as if it were its
  name.
- Why it matters: the three platforms disagree about a mistake. A button
  with a hint and no label is "Adds this item to your favorites, Button"
  on Android and iOS and an unnamed button on the web. Neither is right,
  but the web result hides that a hint was ever written.
- Related: on an adjustable node the description is on the element around
  the `<input type="range">`, not on the slider, like its name
  ([FL-028](#fl-028)).
- Workaround: none needed for a control that has a name. A hint is not a
  name: give the control a label ([S01](techniques/S01.md)).
- Upstream issue: not searched yet (D25).

## FL-042

**On iOS an obscured text field is a secure text field only while it is being edited.**

- Status: Confirmed, Flutter 3.47.5, iOS 27.0 simulator. First seen once
  in S15's first build; settled by the F03 probe
  (`docs/evidence/probes/f03`, fixtures 13 to 16) and asserted on
  `/t/F03/good-sign-in` by `F03KeyboardTypesUITests` (the tree, before,
  during, and after editing) and by its VoiceOver walk, each written to
  fail when the field is secure before it is edited. Engine source read:
  `TextInputSemanticsObject.mm`, which presents a text field's
  accessibility through the plugin's input view while the field is
  focused and through a plain stand-in (`FlutterInactiveTextInput`, which
  has no secure entry) otherwise; `FlutterTextInputPlugin.mm` sets
  `secureTextEntry` on the input view from `obscureText`.
- What happens: `TextField(obscureText: true)` that is not being edited is
  `XCUIElementType.textField`, and VoiceOver reads it "Password Text field
  Double tap to edit.", as it reads any field. Once it is tapped it is a
  `.secureTextField`, and VoiceOver reads "Password Secure text field Is
  editing •••" with "abc" typed. When editing moves to another field it
  is a `.textField` again, with "•••" as its value. Its text is never
  exposed: the value is bullets before, during, and after editing.
- On the other platforms (F03): Android gives the node its password flag
  at all times, and TalkBack reads "Password", "password. Edit box", and
  with "abc" typed "password. 3 characters"
  (`docs/evidence/F03/talkback-android.md`). The web has
  `<input type="password">` at all times, and VoiceOver on macOS reads
  "Password secure text field" before anything is typed; with "abc"
  typed, "3 characters contents selected Password secure text field" in
  Chromium and "•••" in WebKit (`docs/evidence/F03/voiceover-web.md`).
- Effect: a VoiceOver user moving through a form on iOS is not told that a
  field is a password field until they start to edit it. The label still
  says "Password", and what is typed is not read out. Not counted as a
  WCAG failure here: the field's role, a text field, is right, and the
  secure state is there whenever text is entered.
- Workaround: none needed for the text; none in the SDK for the state.
  `Semantics(obscured:)` sets the same flag `obscureText` does, and the
  iOS engine does not read that flag anywhere (read in the source, not
  tried).
- How to read this entry: Flutter has not yet exposed an obscured field
  as secure on iOS before it is edited. Re-check when the pinned version
  changes.
- Also seen in the F02 probe (2026-11-18,
  [F02 probe](evidence/probes/f02/README.md), fixture 10): an obscured
  field with a label and a hint was `XCUIElementType.textField` and read
  with no "secure" while not being edited, and `.secureTextField` with
  the value "•••" while being edited.
- Upstream issue: not searched yet (D25).

## FL-043

**`Semantics(identifier:)` around a Material button stays on a node of its own, in a different place on iOS.**

- Status: Confirmed, Flutter 3.47.5, all platforms. First seen in spike
  K2. Asserted by the widget test "bad-wrapper",
  `web_tests/s22_semantics_identifiers.spec.js`,
  `S22SemanticsIdentifiersTest.badWrapperHasTheIdentifierOnANodeAroundTheButton`,
  and
  `S22SemanticsIdentifiersUITests.testBadWrapperHasTheIdentifierOnAnElementThatIsNotTheButton`.
- What happens: Material buttons wrap themselves in
  `Semantics(container: true, button: true)` (the same cause as
  [FL-040](#fl-040)). A `Semantics(identifier: 'x')` above one has nothing
  to join and becomes a node with the identifier and nothing else: no
  role, no name, no action. The button's node has no identifier.
- Where the node is: on the web an `flt-semantics` element around the
  button, and on Android a `View` whose child is the `Button`. On iOS it
  is an `Other` element beside the button, with the same frame, and the
  button is not inside it. A test that finds the identifier and then looks
  for a button inside it works on web and Android and finds nothing on
  iOS. `Semantics(container: true, identifier:)` and
  `Semantics(explicitChildNodes: true, identifier:)` give the same trees
  (`docs/evidence/probes/s22`, fixtures 03, 11, 21).
- What the user gets: nothing different. The node has nothing to read and
  VoiceOver on iOS does not stop on it. The cost is to tests: the element
  they found is not the control, cannot be asked for its role or name, and
  is somewhere else on iOS.
- Not affected: the same wrapper around a `CupertinoButton`, a `ListTile`,
  a `TextField`, or a `Text` joins that widget's node (probe, fixtures 04,
  06, 08, 18).
- Workaround: `MergeSemantics(child: Semantics(identifier: 'x', child: FilledButton(…)))`,
  which is `TestId`. One node with role, name, and identifier everywhere.
- Upstream issue: not searched yet (D25). The buttons have not been given
  an `identifier` parameter.

## FL-044

**A mixed checkbox is exposed as not checked on the web, on iOS, and on Android before 16, and TalkBack says no state for it.**

- Status: Confirmed, Flutter 3.47.5, all platforms. Found in the F07 probe
  (`docs/evidence/probes/f07`, fixtures 03, 04, 08, 10). Asserted by
  `web_tests/f07_checkbox.spec.js` ("the mixed state is exposed as not
  checked"), `F07CheckboxUITests.testGoodMixedIsExposedAsOff`, and heard
  in the F07 VoiceOver transcripts. Engine source read for both.
- What happens: `Checkbox(tristate: true, value: null)`,
  `CheckboxListTile` and `CupertinoCheckbox` with the same arguments, and
  `Semantics(mixed: true)` all produce a semantics node whose checked
  state is mixed (`CheckedState.mixed`; the F07 widget tests assert it).
  - Web: the element is `role="checkbox"` with `aria-checked="false"`.
    The role class that renders checkboxes, `SemanticCheckable` in
    `lib/web_ui/lib/src/engine/semantics/checkable.dart`, writes `"true"`
    when the state is checked and `"false"` for everything else. The same
    file has a `Checkable` behaviour that does write `"mixed"`, but
    `SemanticCheckable` does not use it.
  - iOS: the element is a switch ([FL-035](#fl-035)) with the value "0".
    `FlutterSwitchSemanticsObject.accessibilityValue` in
    `SemanticsObject.mm` turns the native switch on only when the state is
    checked. A `UISwitch` has no third state to use.
  - Android: the node is right and the speech is not. On Android 16 (API
    36) and later `BaseRoleConfigurator.setChecked` passes
    `AccessibilityNodeInfo.CHECKED_STATE_PARTIAL`, asserted by
    `F07CheckboxTest.goodMixedIsPartiallyCheckedWhereAndroidHasThatState`. TalkBack 17 reads the
    box as "Select all, Check box" with no state
    (`docs/evidence/F07/talkback-android.md`). It did not speak the
    partial state of a native `CheckBox` either: one whose node was set to
    `CHECKED_STATE_PARTIAL` through an accessibility delegate was read "not
    checked" (`docs/evidence/probes/f07`). Jetpack Compose gives a
    tri-state checkbox a state description for this, and Flutter sets no
    state description ([FL-036](#fl-036)); that part is from memory of the
    Compose source and was not checked here. Before API 36 the engine
    calls the two-state `setChecked(false)`: the same test expects not
    checked there, and CI runs it on API 35.
- What the user gets: a "Select all" box with some of its items chosen is
  read as not checked on the web and "off" on iOS, which is false, and
  with no state on Android (where before Android 16 the node is not
  checked as well). Sighted users see a dash in the box. On the
  web, iOS, and Android before 16 this fails 4.1.2: the state is not what assistive technology
  is told.
- Workaround: none within the SDK. Putting the state in the label or in a
  `value` changes the control's name as it changes
  ([FL-036](#fl-036), [FL-037](#fl-037)), and a hint can be switched off
  by the user. The items under the box still report their own states
  correctly, so the information is reachable one box at a time.
- How to read this entry: Flutter has not added this yet. Re-check when
  the pinned version changes.
- Upstream issue: not searched yet (D25).

## FL-045

**TalkBack says no state for a checkbox or radio button that is not checked.**

- Status: Confirmed, Flutter 3.47.5, Android 17, TalkBack 17.0. First seen
  in S01 and S13 and left to F07. Asserted by the F07 TalkBack transcript
  (`tool/talkback.py`: every unchecked box must be read without the word
  "checked"). Cause not found.
- What happens: with focus on a Flutter checkbox that is not checked,
  TalkBack says "Email me product updates, Check box, Double-tap to
  toggle". Once the box is checked it says "checked, Email me product
  updates, Check box". A Flutter switch that is off is read "off, Wi-Fi,
  Switch", so the gap is the checkbox only.
- Compared with a native control: a plain `android.widget.CheckBox` on
  the same device is read "not checked, n01 native unchecked, Check box"
  (`docs/evidence/probes/f07`, the native screen and its transcript in
  the README).
- What the node has: class `android.widget.CheckBox`, checkable, checked
  false (`CHECKED_STATE_FALSE` on API 36 and later), the name in the
  content description, no state description. UI Automator and the
  instrumented test see a correct unchecked checkbox. What differs from
  the native node that makes TalkBack skip the state was not found; the
  native box has its name in `text`, where Flutter uses the content
  description, and that is the only difference seen.
- What the user gets: silence where "not checked" should be. Someone who
  knows TalkBack can take the missing word to mean not checked, so the
  state can be worked out, but it is not said. This is not counted as a
  WCAG failure here: the state is exposed to assistive technology
  correctly.
- Radio buttons are the same (F08): an option that is not chosen is read
  "Standard, Radio button", and the chosen one "checked, Express, Radio
  button" (`docs/evidence/F08/talkback-android.md`). A native
  `RadioButton` was not compared; the native comparison above is for a
  checkbox only.
- Workaround: none within the SDK. There is no state description to set
  ([FL-036](#fl-036)).
- Upstream issue: not searched yet (D25).

## FL-046

**`RadioGroup` has no label parameter: it is named by text inside it, and a label around it misses.**

- Status: Confirmed, Flutter 3.47.5, all platforms. Found in the F08
  probes (`docs/evidence/probes/f08`, fixtures 01 to 05 and 12 to 15).
  Asserted by the F08 widget tests ("the question is the name of the
  radio group", "bad-group-unlabelled", "bad-unlabelled"),
  `web_tests/f08_radio_group.spec.js`, and
  `F08RadioGroupTest.goodExamplesHaveTheQuestionAsTheNameOfTheRadioGroup`.
  Framework source read: `widgets/radio_group.dart`.
- What happens: `RadioGroup` builds
  `Semantics(container: true, role: SemanticsRole.radioGroup, child: ...)`
  and has no parameter for a label. The APG pattern requires the radio
  group to have one. Nothing in the API or its documentation says how to
  give it one.
- How it does get a name: the group's node is a container that does not
  have `explicitChildNodes`, so any semantics inside it that belong to no
  node of their own are merged into it. A `Text` placed inside the
  `RadioGroup`, beside the radio buttons, becomes the group's label:
  `role="radiogroup"` with `aria-label` on the web, an
  `android.widget.RadioGroup` with that description on Android, and on
  iOS an element with that label read before the buttons. A
  `Semantics(label: ...)` inside the group does the same (probe, fixtures
  12 to 14).
- What misses: a label around the `RadioGroup`. The group's node is a
  container, so a `Semantics(label:)` above it lands on a node of its own
  around the group, as a hint or an identifier around a Material button
  does ([FL-040](#fl-040), [FL-043](#fl-043)). The result is a `group`
  named by the label around an unnamed `radiogroup` on the web, and a
  `View` around an unnamed `RadioGroup` on Android. Giving the wrapper
  `role: SemanticsRole.radioGroup` nests two radio groups (probe,
  fixtures 02 to 04).
- What also follows: the naming is by accident of position, so it goes
  wrong the same way. The question printed just above the `RadioGroup`,
  outside it, names nothing (F08 `bad-group-unlabelled`). Texts beside
  radio buttons that are not joined to them become the group's name:
  "Standard Express Next day" (F08 `bad-unlabelled`). A question marked as
  a heading inside the group (`Semantics(header: true)`) named the group
  on Android, and on the web became a `<header>` element inside an unnamed
  `radiogroup`, with the radio buttons inside the header (probe, fixture
  15).
- Workaround: put the visible question inside the `RadioGroup`, as plain
  text, as the F08 good examples do.
- An earlier draft of this entry said the group could not be named at
  all. A review pointed out that the probes had only tried labels outside
  the group; the second probe corrected it.
- Upstream issue: not searched yet (D25).

## FL-047

**A radio button is a button for VoiceOver on iOS, and a hand-built one has no state there.**

- Status: Confirmed, Flutter 3.47.5, iOS 27. First seen in the S13 probe
  (fixture 09) and left to F08. Asserted by
  `F08RadioGroupUITests.testRadioButtonsAreButtonsWithOneSelected`,
  `testBadCheckedOnlyHasButtonsNoneSelected`, and the F08 VoiceOver
  transcript. Engine source read: `SemanticsObject.mm`; framework source
  read: `widgets/raw_radio.dart`.
- What happens, part one: UIKit has no radio button. A node with
  `inMutuallyExclusiveGroup` is an ordinary element with the button trait,
  and `accessibilityValue` returns nothing for it (the engine's comment:
  "iOS does not announce values of native radio buttons"), so its checked
  state is not exposed. VoiceOver never says "radio button".
- What Flutter's widgets do about it: `RawRadio`, which `Radio`,
  `RadioListTile`, and `CupertinoRadio` are built on, adds
  `selected: true` to the chosen button on iOS and macOS, and the hint
  "Not selected" (`WidgetsLocalizations.radioButtonUnselectedLabel`) to
  the others. VoiceOver reads "selected, Express, Button" and "Standard,
  Button, Not selected". The state is announced; the role is "Button".
- What happens, part two: a radio button built from
  `Semantics(checked: ..., inMutuallyExclusiveGroup: true)` has neither
  addition. It is right on Android (`RadioButton`, checked) and on the web
  (`role="radio"`, `aria-checked`), and on iOS it is "Express, Button"
  with no state at all: nothing says which option is chosen (4.1.2). The
  code looks complete and works on the two platforms most people test
  first.
- On the web, on Apple devices only: the same hint is written as
  `aria-description="Not selected"` on the buttons that are not chosen,
  because the framework chooses by `defaultTargetPlatform`, which is
  macOS or iOS in a browser there. A browser on another system gets no
  description.
- Why it matters: for the built-in widgets this is a naming difference,
  like a checkbox being a switch ([FL-035](#fl-035)). For a hand-built
  control it is a missing state.
- Workaround: build custom radio buttons on `RawRadio` inside a
  `RadioGroup`, as F08 `good-custom` does. To stay with `Semantics`, add
  `selected:` on iOS as `RawRadio` does. There is no way to make
  VoiceOver say "radio button".
- Upstream issue: not searched yet (D25).

<!-- FL-048 to FL-069: Work outside the waves. Entries in this range go below, in id order. -->

<!-- FL-070 to FL-099: Wave 10, the limitation entries. Entries in this range go below, in id order. -->

<!-- FL-100 to FL-199: Wave 1, forms. Entries in this range go below, in id order. -->

## FL-100

**TalkBack says "checked" as well as "on" for a switch that is on.**

- Status: Confirmed, Flutter 3.47.5, Android 17, TalkBack 17.0. Found in
  F09 and asserted by the F09 TalkBack transcript
  (`docs/evidence/F09/talkback-android.md`; `tool/techniques/f09_switch.py`
  requires "checked" as a sentence of its own for every switch that is on,
  written to fail when it is no longer said). Cause not found.
- What happens: with focus on a Flutter switch that is on, TalkBack says
  "checked. on. Bluetooth, Switch". A switch that is off is read "off.
  Bluetooth, Switch", with no "not checked". It is the same for
  `SwitchListTile`, a `CupertinoSwitch` merged with its list tile, and a
  switch built with `Semantics(toggled:)`. In the comparison run it was
  still said for the `SwitchListTile` when focus came back to it eight
  seconds after the change, so it is what TalkBack reads on arriving and
  not a change notice.
- Compared with a native control: a plain `android.widget.Switch` on the
  same device is read "ON. n02 native on. Switch" and "OFF. n01 native
  off. Switch", the same after a click (`docs/evidence/probes/f09`, the
  native screen and the walk in the README). The upper case is the
  switch's own state description, "ON" or "OFF".
- What the node has: class `android.widget.Switch`, checkable, checked,
  the name in the content description, no state description. The Android
  engine never sets a state description ([FL-036](#fl-036)); the native
  switch has one. That is the difference seen, and it fits: with no state
  description TalkBack speaks the checked state ("checked", and nothing
  for not checked, as for a checkbox in [FL-045](#fl-045)) and then its
  own word for a switch's state. Not proven.
- What the user gets: the state twice, in two vocabularies, when the
  switch is on. The state itself is right and is not missed, so this is
  not counted as a WCAG failure here. It does make an on switch sound like
  a checkbox that is also on, and "checked" is not a word the switch uses
  anywhere else.
- Workaround: none within the SDK. There is no state description to set
  ([FL-036](#fl-036)), and a `value` is added to the content description
  instead of replacing anything.
- How to read this entry: Flutter has not added this yet. Re-check when
  the pinned version changes.
## FL-120

**A `CupertinoSlider` takes no keyboard focus.**

- Status: Confirmed, Flutter 3.47.5, all platforms. Found in the F10 probe
  (`docs/evidence/probes/f10`, fixtures 06 and 13 of the first probe):
  Tab went past it on the web. Asserted by the F10 widget test "FL-120".
  Framework source read: `cupertino/slider.dart`, which has no `Focus`,
  `FocusableActionDetector`, or shortcuts, where `material/slider.dart`
  has all three.
- What happens: the slider has the slider flag, a value, and the increase
  and decrease actions, so a screen reader can read and adjust it, but it
  is never in the focus order. Tab goes past it, and the arrow keys do
  nothing. `Slider.adaptive` is a `CupertinoSlider` on iOS and macOS, so
  it has the same gap there; in a browser on a Mac it is the Cupertino one
  (probe, fixture 13).
- On the web: the slider's `<input type="range">` can take focus. Flutter's
  focus order skips it, but when nothing Flutter can focus comes after it,
  the browser's own Tab order lands on it, and the browser's arrow keys
  then move it one step at a time (seen with F10 `bad-no-keyboard`, which
  has the same gap on a custom slider).
- Effect: a keyboard user, or a switch user who moves by focus, cannot
  reach the slider (2.1.1).
- Workaround: wrap it in `FocusableActionDetector` with the APG keys
  mapped to steps, inside the same `MergeSemantics` as its text, as F10
  `good-cupertino` does. Verified in the widget tests and on the web: Tab
  reaches the slider, the arrow keys, Home, and End work, and focus is on
  the slider's `<input>`.
- How to read this entry: Flutter has not added keyboard support to the
  Cupertino slider yet. Re-check when the pinned version changes.
- Upstream issue: not searched yet (D25).

## FL-121

**A `CupertinoSlider` moves only when its thumb is dragged.**

- Status: Confirmed, Flutter 3.47.5, all platforms. Asserted by the F10
  widget test "FL-121" and by the F10 web, Android, and iOS tests of
  `good-cupertino`, each written to fail when a tap on the track starts
  to work. Framework source read: `cupertino/slider.dart`, whose render
  object has only a `HorizontalDragGestureRecognizer` and hit-tests only
  within a thumb's radius of the thumb.
- What happens: a tap or click on the track away from the thumb does
  nothing. A Material `Slider` moves to the point tapped.
- Effect: a person who cannot drag, or who uses a pointer that cannot
  drag, cannot set the slider by pointer (2.5.7 Dragging Movements; the
  iOS reference asks for "single tap alternatives").
- Workaround: put buttons beside it that move it a step, as F10
  `good-cupertino` does ("Volume down", "Volume up").
- Upstream issue: not searched yet (D25).

## FL-122

**A Material `Slider` has no Home or End keys, and on the web those keys move it one step.**

- Status: Confirmed, Flutter 3.47.5. Asserted by the F10 widget test
  "FL-122" (no effect off the web) and by the F10 web tests of
  `bad-no-keyboard` (one step on the web). Seen in the F10 probe (fixture
  01: Home went from 80% to 70%, End from 70% to 80%). Framework source
  read: `material/slider.dart`, whose shortcuts are the four arrow keys
  only; engine source read: `incrementable.dart`.
- What happens: the APG slider pattern sets Home to the first value and
  End to the last. `Slider` maps only the arrow keys. Off the web, Home
  and End do nothing. On the web the focused element is an
  `<input type="range">` whose range is a stand-in one step either side
  of the value ([FL-125](#fl-125)), so the browser's own Home and End
  move the input to that stand-in's end, which the engine turns into one
  increase or decrease.
- Workaround: `CallbackShortcuts` around the `Slider` for Home and End, as
  the F10 Material examples do (`_HomeAndEnd`). The `Slider` leaves those
  keys unhandled, so they reach the shortcuts above it; on the web the
  framework then takes the key and the browser does not move the input as
  well. Verified in the widget tests and on the web. The same for a
  custom slider through `FocusableActionDetector` (F10 `good-custom`).
  Page Up and Page Down, which the APG makes optional, are not built.
- Upstream issue: not searched yet (D25).

## FL-123

**`Slider.label`, the text shown above the thumb, is added to the slider's name.**

- Status: Confirmed, Flutter 3.47.5, all platforms. Asserted by the F10
  widget, web, Android, and iOS tests of `bad-indicator-label`. Framework
  source read: `material/slider.dart`, `describeSemanticsConfiguration`,
  which sets `config.label` to the widget's `label`.
- What happens: `label` is documented as the text of the value indicator
  that appears while the slider is used. It is also put in the slider's
  semantics label. With the visible text "Volume" merged in, the name is
  "Volume" and the number, on two lines ("Volume\n4"); with nothing else,
  the name is the number alone. Usually that number is the value, so it
  is read twice in two forms ("40%, Volume 4" on Android), and the name
  changes at every step.
- Effect: the name carries a number that is not the label and changes
  at every step. TalkBack reads "40%", "Volume 4", "Slider", and after a
  step "50%", "Volume 5" (F10 transcript): the value twice, once inside
  the name. The name still contains the visible label, so this is a
  naming fault and not a failure of 2.5.3 Label in Name. Anything that finds
  the control by name has to know its value.
- Workaround: none that keeps the indicator text out of the name. Leave
  `label` unset, or accept the longer name; give the value its words with
  `semanticFormatterCallback`.
- Upstream issue: not searched yet (D25).

## FL-124

**A disabled slider is not a slider.**

- Status: Confirmed (source read), Flutter 3.47.5, all platforms. Seen in
  the F10 probe (first probe fixture 09, second probe fixtures 07 and
  08) on all three platforms; asserted by the F10 widget test "FL-124".
  Engine source read: the web's `isIncrementable` in `semantics.dart`
  (an element is a slider only if it has the increase or decrease
  action) and the iOS `accessibilityTraits` in `SemanticsObject.mm` (the
  adjustable trait only with those actions).
- What happens: a `Slider` or `CupertinoSlider` with `onChanged: null`
  keeps the slider flag and drops the increase and decrease actions, and
  each engine decides the role from the actions. On the web it is plain
  text, "Volume 40%", focusable (the value is appended to the name as in
  [FL-037](#fl-037)); on Android an `android.view.View`, not enabled,
  "40%, Volume"; on iOS an element read "Volume 40% dimmed" with no
  "adjustable". A disabled `CupertinoSlider` also has no value at all.
- Effect: a disabled slider is announced as text, and the user is not
  told that there is a control here that is off. A native disabled
  `<input type="range">` is still a slider, marked disabled.
- Workaround: none in the SDK.
- Upstream issue: not searched yet (D25).

## FL-125

**On the web a slider's minimum, maximum, and current value are stand-ins.**

- Status: Confirmed, Flutter 3.47.5, web. Asserted by
  `web_tests/f10_slider.spec.js` ("every slider"). Engine source read:
  `incrementable.dart`, `_updateInputValues`.
- What happens: whatever the slider's own range, the engine gives the
  `<input type="range">` `aria-valuemin="0"`, `aria-valuenow="1"`, and
  `aria-valuemax="2"`, moving the three up or down by one after each
  change, and the real value only in `aria-valuetext`. A slider at its
  last value still has a maximum one above it, because `Slider` repeats
  the last value as its `increasedValue`. Chromium's own tree (read over
  the DevTools protocol) gives the value text as "1", the stand-in; what
  VoiceOver reads is the `aria-valuetext` (F10 transcripts).
- Effect: assistive technology that reads the numbers, or shows the
  slider's position as a proportion, gets a slider always in the middle of
  a range of three. Screen readers that speak `aria-valuetext` are not
  affected.
- Workaround: none. Give every slider value words that make sense alone
  (`semanticFormatterCallback`), since those are all that is real.
- Upstream issue: not searched yet (D25).

## FL-126

**A `RangeSlider` has two unnamed sliders on the web and one value on Android when merged.**

- Status: Observed, Flutter 3.47.5, in the F10 probe only (first probe
  fixture 10, second probe fixture 02). No example and no test; the
  range slider is not built in F10.
- What happens: on the web an unmerged `RangeSlider` is two
  `<input type="range">` elements, one per thumb, with no name and no
  label on any element around them. Inside `MergeSemantics` with its text,
  Android and iOS read one slider with the first thumb's value only
  ("20%, Price"), and the web shows one slider.
- Effect: the two values cannot both be read when the range slider is
  joined to its text, and cannot be told apart when it is not.
- Workaround: not looked for. To do in a technique that builds a range
  slider.
- Upstream issue: not searched yet (D25).

## FL-127

**On the web a slider is disabled for half a second after any pointer event, and VoiceOver calls it "dimmed".**

- Status: Confirmed, Flutter 3.47.5, web. Each statement below says
  whether it was measured or read in the source.
- Read in the engine source: `incrementable.dart` sets `disabled` on the
  slider's `<input type="range">` whenever the gesture mode is pointer
  events, and its `change` listener returns without acting while the input
  is disabled; `_temporarilyDisableBrowserGestureMode` in `semantics.dart`
  switches to that mode for 500 ms on any pointer, mouse, touch, or wheel
  event. The purpose given there is to keep the browser from handling a
  drag that Flutter handles.
- Measured, and asserted by `web_tests/f10_slider.spec.js` (Chromium, no
  screen reader): straight after the mouse moves, the input is disabled; a
  change through the input then, as a screen reader's adjust command makes
  it, does nothing; with no more pointer events the input is enabled again
  within three seconds and the same change moves the slider. The 500 ms
  itself was not measured.
- Measured, and asserted by `web_tests/vo/f10_slider_vo.spec.js` in both
  Playwright builds: during every VoiceOver walk of an F10 example the page
  received pointer events, and after every walk that read the slider its
  input was disabled when read straight after the walk. VoiceOver read
  every F10 slider it reached "dimmed slider". On the WebKit walks that leave the
  page ([FL-029](#fl-029)) the notes show the input disabled and enabled
  again many times, and at the end of the walk it was found either way, so
  nothing is asserted about it there. A plain HTML copy of Flutter's markup was read "40% slider"
  with the input enabled and "40% dimmed slider" with it disabled. The
  numbers from the run whose transcript is committed are in
  `docs/evidence/probes/f10/voiceover-web-notes.txt`, written by that
  spec: 20 to 24 pointer and mouse events per walk in Chromium, where the
  test itself clicks once, and 26 to 46 in WebKit, where it clicks twice;
  and every change of `disabled` in order. The counts are recorded, not
  asserted.
- Not established: whether the input is disabled at the very moment
  VoiceOver speaks the slider (it is read just after the walk, not at each
  move), and
  which part of the system sends the pointer events during a walk.
- Effect: a VoiceOver user is told that an enabled slider is unavailable.
  An adjustment that reaches the input in the half second after a pointer
  event is lost (measured as above). First noticed in S01
  ([FL-028](#fl-028)).
- Workaround: none in the SDK.
- Upstream issue: not searched yet (D25).

## FL-140

**Material helper text is not tied to its field; inside `MergeSemantics` it joins the field's name.**

- Status: Confirmed, Flutter 3.47.5, Android 17 emulator, iOS 27.0
  simulator, Chromium and WebKit. SDK source read:
  `_HelperErrorState._buildHelper()` in
  `packages/flutter/lib/src/material/input_decorator.dart` wraps the helper
  in `Semantics(container: true)`, and `InputDecorator.build` gives the
  field a semantics hint from `decoration.errorText` only (its comment:
  "Pass error text to semantics so screen readers announce it along with
  the input field"). Asserted by `bad-helper-only` and the FL-140 test in
  `test/techniques/f02_input_instructions_test.dart`,
  `web_tests/f02_input_instructions.spec.js`, `F02InputInstructionsTest.kt`,
  and the three transcripts in `docs/evidence/F02/`. Seen first in the
  [F02 probe](evidence/probes/f02/README.md), fixtures 01 and 02.
- What happens: `InputDecoration(helperText:)` (and `helper:`) is the
  documented place for an instruction under a Material field, and it is
  drawn there. In the semantics tree it is a node of its own, a child of
  the field's node, with the text as its label. The field gets no hint
  from it: on the web the `<input>` has no `aria-description` and no
  `aria-describedby`, and the helper is text beside the `<input>` inside
  the field's element; on Android the field's hint text is the label
  alone; on iOS the field has no hint and the helper is static text after
  it. An error text, in the same place on the screen, does become the
  field's hint (read in the source, not observed here; that is F04).
- Inside `MergeSemantics` (the project's `TestId` is one) the helper is
  merged into the field and becomes the end of its name: "Username\n4 to 10
  characters, no spaces." as the `aria-label` on the web and the label on
  iOS (probe, fixture 02), and in Android's hint text. It is then read as
  part of the name, before the role, and on Android only while the field
  is empty ([FL-015](#fl-015)).
- What the user gets: "Username, edit box" with focus on the field, and the
  instruction only if they move on past the field and recognise that the
  next text belongs to it. VoiceOver on iOS: "Username Text field Double
  tap to edit.", then "4 to 10 characters, no spaces."; on the web
  "Username edit text", then the instruction.
- Workaround: give the field the same words as its hint, and do not wrap
  the field in `MergeSemantics`:
  `Semantics(hint: rule, child: TextField(decoration: InputDecoration(helperText: rule, ...)))`
  (`/t/F02/good-helper`). The field is read with its instruction on all
  three platforms, and the helper stays an element of its own. On Android
  that is where the instruction is left once the field has a value
  (TalkBack reads it when focus is put on it; see [FL-015](#fl-015)). To give such a field a test identifier, put `identifier:` on that
  same `Semantics`; it joins the field's node
  ([FL-043](#fl-043) does not affect a `TextField`).
- How to read this entry: Flutter has not added this yet. The comment in
  `InputDecorator.build` names a follow-up with `aria-describedby` for
  error text; helper text is not mentioned.
- Upstream issue: not searched yet (D25).

## FL-141

**Material helper text is cut to one line by default.**

- Status: Confirmed, Flutter 3.47.5, all platforms (the widget layer; the
  device tests run at the default text size and cannot see it). Documented
  in the SDK: `InputDecoration.helperMaxLines` "Defaults to null, which
  means that soft line breaks in [helperText] are truncated with an
  ellipse". Asserted by `bad-helper-cut-off` in
  `test/techniques/f02_input_instructions_test.dart`, written to fail when
  helper text wraps by default.
- What happens: `helperText` is drawn with `overflow: TextOverflow.ellipsis`
  and `maxLines: helperMaxLines`. With `helperMaxLines` left null, a helper
  that is longer than the field is wide is shown as one line ending in
  "…". "Shown on your posts. 2 to 30 letters or numbers." fits on one line
  on an 800-wide screen at 100% text, and is cut at 200% (the widget test).
  The semantics keep the whole text, so a screen reader reads all of it.
- What the user gets: someone who uses large text, and does not use a
  screen reader, sees the start of the instruction and an ellipsis. That
  is a loss of content at 200% text (WCAG 1.4.4).
- Workaround: set `helperMaxLines` to enough lines for the largest text
  size, as `good-helper` does, or pass a `Text` as `helper:`, which wraps.
- How to read this entry: this is a default, not a missing feature, and it
  is in the documentation. It is here because the default loses an
  instruction at large text sizes without warning.
- Upstream issue: not searched yet (D25).

## FL-142

**A Material placeholder beside a label is exposed only while the field is focused and empty, and then as part of its name.**

- Status: Confirmed, Flutter 3.47.5, Android 17, iOS 27.0, Chromium and
  WebKit. SDK source read: in `InputDecorator.build`,
  `showHint = isEmpty && !_hasInlineLabel`, so with a `labelText` the hint
  text is drawn only while the field is focused (the label has floated)
  and empty; the hint `Text` is merged into the field's node, as the
  comment there says ("The hintText is already in the semantics tree via
  the hint Text widget that merges up"). Asserted by
  `bad-placeholder-format` in the widget tests,
  `web_tests/f02_input_instructions.spec.js`, `F02InputInstructionsTest.kt`,
  and `F02InputInstructionsUITests.swift`. Probe fixture 05.
- What happens: `InputDecoration(labelText: 'Date of birth', hintText:
  'DD/MM/YYYY')`. Not focused: the field's name is "Date of birth" and the
  format is nowhere in the tree. Focused and empty: the placeholder is
  drawn, and the name becomes "Date of birth\nDD/MM/YYYY" (the
  `aria-label` on the web, which also gains a `placeholder` attribute; the
  label on iOS; Android's hint text). After one character the name is
  "Date of birth" again.
- What the user gets: with TalkBack and VoiceOver on iOS, moving to the
  field reads "Date of birth", "Edit box" and "Date of birth Text field" with
  no format; the format is in the name only after editing has started and
  before anything is typed. VoiceOver on the web moves keyboard focus into
  a field it reaches, so there the placeholder appears and is read on
  arrival: "Date of birth DD/MM/YYYY edit text" in WebKit, "Date of birth
  DD/MM/YYYY" in Chromium. On every platform it is gone, from the screen
  and the name, at the first character typed (the F02 transcripts).
- WCAG: 3.3.2 Labels or Instructions, when the placeholder is the only
  instruction. The Understanding document allows an instruction shown only
  while the field has focus, and requires one that is provided to be
  "persistently available". This one is gone from the first character
  typed, with the field still focused, until the value is deleted
  (asserted in the widget test).
- Why it matters for instructions: this follows Material's design for a
  placeholder, which is an example of the value and not a place for an
  instruction. Combined with the label it changes the field's name while
  it is being edited.
- Workaround: put the format in helper text and in the field's hint, as
  [F02](techniques/F02.md) `good-helper` does ([FL-140](#fl-140)).
- Upstream issue: not searched yet (D25).

## FL-160

**On Android, turning suggestions off on an email field replaces the email keyboard with one that has no "@".**

- Status: Confirmed, Flutter 3.47.5, Android 17 emulator, Gboard. Found
  in the F03 probe (`docs/evidence/probes/f03`, fixture 09) and asserted
  by `F03KeyboardTypesTest.fieldsAskForTheirKeyboardAndPurpose` on
  `/t/F03/bad-email-no-suggestions`, written to fail when the email
  variation is kept. Engine source read:
  `inputTypeFromTextInputType` in `TextInputPlugin.java`.
- What happens: `TextField(keyboardType: TextInputType.emailAddress,
  enableSuggestions: false)` asks the input method for input type
  `0x800b1`. The engine starts from the email variation (`0x20`) and, for
  `enableSuggestions: false`, adds `TYPE_TEXT_FLAG_NO_SUGGESTIONS` and
  `TYPE_TEXT_VARIATION_VISIBLE_PASSWORD` (`0x90`) with a bitwise or. A
  variation is a number, not a set of flags: `0x20 | 0x90` is `0xb0`,
  `TYPE_TEXT_VARIATION_FILTER`. Gboard then shows its general keyboard,
  with "," where the email keyboard has "@" (the keys are read from the
  keyboard's window in the same test; the probe's screenshots, not kept,
  show the same). The same field with suggestions on asks for `0x21` and
  gets the "@" key.
- Read in the source, not measured: the same or applies to the other text
  variations. A URL field with suggestions off becomes a visible password
  field (`0x10 | 0x90` is `0x90`), and a name field gets `0xf0`, which is
  no defined variation. An obscured field is not affected, because the
  suggestions branch is not taken for it.
- iOS and the web keep the email keyboard: iOS shows "@" (the F03 iOS
  test), and the web's `inputmode="email"` is unchanged.
- Effect: a person typing an address has to switch to the symbols page
  for "@". That is extra work, and real work for someone who types slowly
  or with a switch; it fails no WCAG criterion as written. What else the
  filter variation changes in Gboard was not looked at.
- Workaround: leave `enableSuggestions` on for an email field and turn
  off only `autocorrect`, which on its own does not touch the variation
  (`good-contact`'s email field, input type `0x21`).
- How to read this entry: Flutter has not made `enableSuggestions` keep a
  field's keyboard variation yet. Re-check when the pinned version
  changes.
- Upstream issue: not searched yet (D25).

## FL-161

**On the web autofill hints do not reach `autocomplete`, except on an obscured field once it is focused.**

- Status: Confirmed, Flutter 3.47.5, web (Chromium and WebKit builds of
  Playwright, desktop, and with a phone's user agent and platform).
  Found in the F03 probe (`docs/evidence/probes/f03`, `web.txt` and
  `web2.txt`) and asserted on every F03 field by
  `web_tests/f03_keyboard_types.spec.js`, written to fail when a hint
  arrives. Engine source read: `semantics/text_field.dart` and
  `text_editing/text_editing.dart`.
- What happens: a field's `<input>` is created with `autocomplete="off"`.
  When editing starts, the text editing code writes the field's first
  autofill hint as `autocomplete`, `name`, and `id` (`AutofillInfo.
  applyToDomElement`). The semantics code then sets `autocomplete="off"`
  again on every update of the field's node (`_updateInputType`), which
  happens straight away and at every key. Measured: a field with
  `AutofillHints.name`, `telephoneNumber`, `username`, or `url` has
  `autocomplete="off"` before, while, and after it is edited, and
  `name="name"` (or `tel`, `username`, `url`) from the first edit on.
  Two exceptions, both from the same function:
  - a field with `keyboardType: TextInputType.emailAddress` has
    `autocomplete="email"` and `inputmode="email"` at all times, whatever
    its hints, set by the semantics code from the field's input type;
  - an obscured field is given `type="password"` and its `autocomplete`
    is left alone, so it has "off" until it is first focused and then its
    hint, such as `current-password` or `new-password`.
  A multi-line field gets "on" once focused.
- Effect: on the web the purpose of a name, a phone number, a username,
  or any other field that is not an email address or a password cannot be
  programmatically determined, so it fails 1.3.5 Identify Input Purpose
  however the app is written. A browser can still guess from the `name`
  attribute; a guess is not what 1.3.5 or H98 ask for. Before a password
  field has been focused, nothing says it is one either.
- Workaround: none in the SDK. For an email field, the email keyboard
  type is what gives it `autocomplete="email"`; an email field without it
  loses its purpose (`/t/F03/bad-default-keyboard`). A native `<input>`
  through `HtmlElementView` would be a D32 workaround; the catalog has no
  workaround kind yet, and none is built.
- How to read this entry: Flutter has not yet kept a field's autofill
  hint on the web. Re-check when the pinned version changes.
- Upstream issue: not searched yet (D25).

## FL-162

**On the web the number and decimal keyboard types leave nothing in the page, so a phone's browser shows its general keyboard.**

- Status: Confirmed, Flutter 3.47.5, web, Playwright's Chromium with an
  Android phone's user agent and platform. Found in the F03 probe
  (`docs/evidence/probes/f03/web2.txt`) and asserted by
  `web_tests/f03_keyboard_types.spec.js` ("as on an Android phone"),
  written to fail when `inputmode="numeric"` or `"decimal"` arrives.
  Engine source read: `semantics/text_field.dart` and
  `text_editing/input_type.dart`.
- What happens: on a phone the text editing code can write `inputmode`
  for a number (`numeric`), decimal (`decimal`), or phone (`tel`) field,
  and `enterkeyhint` for its action; on a desktop browser it writes
  neither. But the semantics code removes `inputmode` on every update of
  the field's node and puts back only what it knows: `inputmode="email"`
  for an email field, `type="tel"` for a phone field, `type="url"` for a
  URL field, `type="search"` for a search field. Measured with a phone's
  user agent and platform: a number and a decimal field have no
  `inputmode` and `type="text"`; email, phone, and URL fields have their
  attributes; and every field has the `enterkeyhint` of its action
  (`next`, `done`, `enter` for a multi-line field), which the semantics
  code does not touch.
- Effect: in a phone's browser an amount or a count field gets the
  general keyboard, and the digits are on its second page. A name field
  that asks for the number keyboard (`bad-number-for-name`) is not
  harmed on the web, for the same reason.
- Not measured: a real phone. Playwright's emulation is what was run;
  Flutter decides that it is on a phone from `navigator.platform` and the
  user agent, and both were set as a phone's.
- Workaround: none in the SDK. A phone field keeps `type="tel"`, which
  MDN describes as bringing up a telephone keypad on its own; that was
  not seen on a phone here.
- How to read this entry: Flutter has not yet kept `inputmode` for the
  number keyboard types on the web. Re-check when the pinned version
  changes.
- Upstream issue: not searched yet (D25).

## FL-163

**On iOS the number, decimal, and phone pads have no return key, and a tap outside the field does not end editing.**

- Status: Confirmed, Flutter 3.47.5, iOS 27.0 simulator. Asserted by
  `F03KeyboardTypesUITests.testEveryFieldGetsItsKeyboard` (no return key
  on the pads of `good-contact`'s phone field, `good-amount`, and
  `bad-number-for-name`) and `testAPhonePadCannotBePutAwayFromTheScreen`
  (the keyboard is still up after a tap on the "Example" heading), both
  written to fail when that changes. Framework source read:
  `_EditableTextTapOutsideAction` in `widgets/editable_text.dart`, which
  ends editing on a touch outside the field only on the web, and
  `FlutterTextInputPlugin.mm`, which sets no input accessory view.
- What happens: iOS's number pad, decimal pad, and phone pad have no
  return key, so a field's `textInputAction` (`done`, `next`) has no key
  there. Native apps put a bar with "Done" above such a pad; Flutter's
  text input plugin adds none and has no API for one. A tap elsewhere on
  the screen leaves the field focused and the keyboard up.
- Effect: once a number or phone field has focus, the keyboard covers
  the lower half of the screen until something in the app takes focus
  away. A person cannot put it away to see or reach what it covers, and
  "next" never moves on from such a field. The Android pads have a Done
  or Next key (the F03 Android test).
- Workaround, not built here: end editing on a tap outside the field,
  `TextField(onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus())`,
  or put a button that does so beside the field. Neither has been tested
  with VoiceOver.
- How to read this entry: Flutter has not added a way to give an iOS pad
  a Done key yet. Re-check when the pinned version changes.
- Upstream issue: not searched yet (D25).

## FL-180

**A text field in error has no error state on Android: TalkBack does not say "error", and reads a filled field without its error.**

- Status: Confirmed, Flutter 3.47.5, Android 17 emulator, TalkBack 17.0.
  Asserted by `F06ErrorIdentificationTest` (`node.error` empty and
  `isContentInvalid` false on every field in error) and by
  `f06-good-form-email-filled` in `docs/evidence/F06/talkback-android.md`
  ("Editing. / abc / Edit box", with no label and no error), written to
  fail when the error starts to be spoken. Engine source read:
  `AccessibilityBridge.java` calls neither `setError` nor
  `setContentInvalid` for a Flutter node; only `AccessibilityViewEmbedder`
  copies them, for platform views. No F06 transcript or probe has TalkBack
  saying "error" for a Flutter field.
- What happens: a `TextFormField` in error has its message in the field's
  semantics hint (`InputDecorator` puts `errorText` there), and Android
  joins it to the label in the hint text: "Email, Enter an email address
  …". While the field is empty TalkBack reads that
  (`f06-good-form-email`: "Email, / / Enter an email address … / Edit
  box"). Once the field has a value it reads the value alone, as it does
  for the label ([FL-015](#fl-015)). The error is also a node of its own
  after the field in the tree, and a live region (Android tree tests);
  TalkBack announced it when it appeared in every recorded case where it
  stayed a node of its own ([FL-181](#fl-181) lists them). Whether a swipe goes from
  the field straight to it was not tested: the emulator walk forces focus.
- Compared with a native control: an `android.widget.EditText` with
  `setError(…)` on the same emulator has its node's error set and is
  content-invalid. TalkBack announced "Error: Enter an email address." and
  "Error: Enter a phone number using digits only." when they were set, and
  read the filled field "Error: Enter a phone number using digits only..
  abc. Edit box" (probe, `android-talkback-native.md` and
  `android-tree-native.txt`).
- `SemanticsProperties.validationResult`, which `FormField` sets, is read
  only by the web engine, where it becomes `aria-invalid` (source read:
  `lib/web_ui`, `updateAriaInvalid`; nothing in the Android or iOS engine
  reads it). On iOS VoiceOver read the hint with the value in the probe
  ("p02 Phone abc Text field Enter a phone number using digits only.",
  `ios.txt`), so the reading on the field is not lost there; whether a
  native iOS field has an invalid state to compare with was not checked.
- Effect: a TalkBack user who comes back to a field they filled in wrongly
  hears their value and nothing else: not that the field is in error, nor
  what the error is, unless they move on to the message.
- Workaround: none in the SDK. Keep the error text as its own node right
  after the field, which `TextFormField` does unless it is merged
  ([FL-183](#fl-183)).
- How to read this entry: Flutter has not added an error state for
  Android yet. Re-check when the pinned version changes.
- Upstream issue: not searched yet (D25).

## FL-181

**On iOS and the web an error is announced only when a `Form` validates on send or as the user types; `onUnfocus`, a field validated on its own, and a hand-set `errorText` are silent there.**

- In short: `validate()`, `validateGranularly()`, and the `Form`'s
  `always`, `onUserInteraction`, and `onUserInteractionIfError` modes
  announce the first error; the `Form`'s `onUnfocus` mode,
  `FormFieldState.validate()`, a field's own `autovalidateMode`, and an
  `errorText` set by hand do not.

- Status: Confirmed, Flutter 3.47.5. Each statement below says whether it
  is asserted by a widget test, measured on a device, or read in the
  source only.
- Read in the framework source, `widgets/form.dart`:
  - `FormState._validate` validates every registered field and, where
    `MediaQuery.supportsAnnounceOf` is true, sends the first error with
    `SemanticsService.sendAnnouncement`, assertive, a second later on
    iOS. It is the only code in `form.dart` that announces.
  - It is called by `validate()` and `validateGranularly()`, and by
    `FormState.build` for the `Form`'s `always`, `onUserInteraction`
    (once a field has been changed), and `onUserInteractionIfError` (once
    a field has been changed and one has an error) modes. A field's change
    rebuilds the `Form` (`_fieldDidChange`, `_forceRebuild`).
  - `FormState.build` does nothing for `onUnfocus` or `disabled`. With the
    `Form`'s mode `onUnfocus` (or the field's own), each field wraps
    itself in a `Focus` whose loss calls the field's own `_validate()`,
    which sets the error and announces nothing. `FormFieldState.validate()`
    and a field's own `autovalidateMode` likewise validate that field only.
  - `material/input_decorator.dart`, `_buildError`, makes the error text
    `Semantics(liveRegion: !MediaQuery.supportsAnnounceOf(context))`.
- Asserted by the F06 widget tests (group "FL-181: who announces",
  announcements supported, each recording followed by the recorder's own
  liveness check). What each showed:
  - `onUserInteraction` on the `Form`: one announcement when typing made
    the field invalid, one more at the next change that left it invalid,
    none once it was right; on the Android path and on the iOS path,
    which waits a second.
  - `always` on the `Form`: the error was shown from the first frame and
    not announced then (the `Form` validates in its build, before its
    fields have registered); each change after that announced it.
  - `onUserInteractionIfError` on the `Form`: typing an invalid value
    showed and announced nothing, because no field had an error yet;
    `validate()` then announced it twice; the next change that kept it
    announced it once.
  - `validate()` on a `Form` whose mode is `always` or
    `onUserInteraction` announced the error twice: once from `validate()`
    and once from the rebuild it causes. With the mode `disabled` (F06
    `good-form`) it announced once.
  - `onUnfocus` on the `Form`: the error appeared when the field lost
    focus, and nothing was announced.
  - `validateGranularly()`: the first of two errors, once.
  - A `TextFormField` with its own `onUserInteraction` and no `Form`, the
    same field inside a `Form` whose mode is disabled, and
    `FormFieldState.validate()` on one field: the error shown, nothing
    announced.
  - `errorText` set with `setState` (`bad-not-announced`): nothing
    announced where announcements are supported; the error text a live
    region where they are not.
- Measured on devices, F06 probe (`docs/evidence/probes/f06`) and F06
  transcripts:
  - p03, `errorText` set with `setState`, no `Form`, the field wrapped in
    `TestId` (so merged, [FL-183](#fl-183)), field empty: silent with
    VoiceOver on iOS (`ios.txt`: nothing after the double tap) and on the
    web (`voiceover-web.md`: "(nothing)"). TalkBack announced the merged
    field with its error: "p03 Email Enter an email address …, / / Enter
    an email address …" (`android-talkback.md`, `f06-p03-after-submit`).
  - p12, a `TextFormField` with its own `onUserInteraction`, no `Form`,
    wrapped in `TestId`, made invalid by a button that adds "x": silent
    on iOS and on the web. TalkBack said "x / Edit box" when the error
    appeared and "x / Edit box …" when focus was put on the field
    (`f06-p12-after-submit`, `f06-p12-stop-0`): the error was not spoken
    on Android either. See below.
  - `bad-not-announced` (the same as p03 without the merge): silent on
    iOS and the web (`voiceover-ios.md`, `voiceover-web.md`); TalkBack
    announced "Enter an email address with an @, like name@example.com."
    (`talkback-android.md`, `f06-bad-not-announced-sent`).
  - `Form.validate()`, mode disabled: announced on all three (probe p04
    to p07 on all three, q01 to q03 on Android; the F06 transcripts for
    `good-form` and `good-cupertino`).
  - Not run on a device: the `Form`'s `always`, `onUserInteraction`,
    `onUserInteractionIfError`, and `onUnfocus` modes,
    `validateGranularly()`, and field-level autovalidation of a field that
    is not merged.
- On iOS a corrected error can still be announced after the form goes
  through. Read in the source: `_validate` takes the first error's text,
  then, on iOS only, waits `_kIOSAnnouncementDelayDuration` (one second)
  in an unawaited `Future` and sends that text without validating again or
  checking that the error is still there; nothing can cancel it. Asserted
  by the F06 widget tests on the iOS path: `validate()` failed, the field
  was put right and `validate()` passed 300 ms later, and the recorder
  had nothing when the form went through and then the old error, a second
  after the first send. With the second send 1.5 s after the first, the
  error came once, before it, and nothing after. On the other platforms'
  path the error is sent at once, so nothing comes after a quick success.
  What a user would hear in F06, where a form that goes through is
  announced by a live count: "Forms sent: 1", then "Enter an email address
  …" for a field that is no longer in error. It needs a send that fails
  and a send that goes through less than a second apart. Not measured on a
  device: the F06 walks put the fields right several seconds after the
  failed send. No workaround in the app: the queued announcement has no
  handle. It is recorded here and not as an entry of its own because it
  is the same code as the rest of this entry.
- What happens on Android: Flutter reports that announcements are not
  supported there ([FL-018](#fl-018)), so `Form` sends nothing. A
  Material field's error text is a live region (source; Android tree
  tests). TalkBack announced it in every configuration recorded where the
  error text was its own node: `Form.validate()` (q01 to q03,
  `good-form`, `good-cupertino`, with both errors read, in no fixed
  order) and `setState` (`bad-not-announced`). Where the field was
  merged, its error was part of the field: TalkBack announced it with an
  empty field (p03, p04, `bad-merged-error`), but in p12, where the field
  held "x", it said only the value. That fits [FL-183](#fl-183) (the
  merged field is the live region) and [FL-180](#fl-180) (a field with a
  value is read as its value); the cause was not established. With two
  merged fields in error at once (p05) TalkBack spoke only the second.
- Effect: the same code announces an error on one platform and not on the
  others. An error shown by `onUnfocus`, a field's own validation, or a
  hand-set `errorText`, while the user is elsewhere on the screen, is a
  status message that iOS and the web do not present (4.1.3). The
  `Form`'s `always`, `onUserInteraction`, and `onUserInteractionIfError`
  modes announce the first error again at every change that leaves it in
  error, which while typing is an announcement per keystroke, and
  `validate()` on such a `Form` announces it twice (widget tests). How
  screen readers handle either was not measured.
- Workaround: validate with the `Form` on send, with its mode left
  `disabled`: `validate()` or `validateGranularly()` (F06 `good-form`).
  Such a form already announces; do not add a second announcement to it.
  With `onUnfocus`, with a field's own validation, or for an error set by
  hand, nothing announces on iOS and the web: announce it with
  `SemanticsService.sendAnnouncement` where `supportsAnnounceOf` is true,
  as `Form` does (I12's `good-announce` shows the pattern). None of these
  workarounds was run on a device except `validate()`.
- Upstream issue: not searched yet (D25).

## FL-182

**`CupertinoTextFormFieldRow`'s error is not a live region, so on Android nothing announces it.**

- Status: Confirmed, Flutter 3.47.5. Asserted by the F06 widget test
  "FL-182" (no node is a live region after `validate()`). Framework source
  read: `cupertino/form_row.dart` shows `error` as plain text, and `Form`
  sends nothing on Android ([FL-181](#fl-181)). Seen once on a device, in
  the F06 probe on Android 17 with TalkBack 17.0: fixture p09, the row
  wrapped in `TestId`, nothing was said after `validate()`
  (`android-talkback.md`, `f06-p09-after-submit`). An unmerged row was
  not run on a device.
- What happens: on iOS and the web `Form.validate()` announced the first
  error (p09, `ios.txt` and `voiceover-web.md`); on Android nothing
  announces it. The row's field also has no label of its own
  ([FL-016](#fl-016)); merged with its row, it takes the prefix, the
  placeholder, and the error as its name (p09: hint text "p09 Email\n
  name@example.com\nEnter an email address …" on Android, name "p09 Email
  name@example.com Enter an email address …" on the web).
- Workaround: build the row from `FormField` and `CupertinoFormRow` and
  give each part what `InputDecorator` gives a Material field: the label
  and the error as the field's label and hint, its validation result, and
  the error text in a live region where `supportsAnnounceOf` is false. F06
  `good-cupertino` does this, and TalkBack announced its errors
  (`f06-good-cupertino-sent`).
- Upstream issue: not searched yet (D25).

## FL-183

**`MergeSemantics` around a field takes in its error: the error joins the field's name as well as its hint, and on Android the field becomes a live region.**

- Status: Confirmed, Flutter 3.47.5, all platforms. Asserted by the F06
  widget, web, Android, and iOS tests of `bad-merged-error`.
- What happens: the error text under a Material field is a node of its
  own (`Semantics(container: true)`), but `MergeSemantics` merges
  containers too. The field's label becomes "Email" and the error on two
  lines (widget test, XCUITest, the web's accessible name), and the error
  is its hint as well. What was heard:
  - Web, VoiceOver in Chromium: the error twice, "Email Enter an email
    address … Enter an email address … invalid data edit text"
    (`voiceover-web.md`).
  - Android: the hint text holds it twice ("Email\nEnter …, Enter …",
    tree test), and after Send TalkBack read "Email Enter an email address
    …, / / Enter an email address …" (`f06-bad-merged-error-sent`). The
    field itself is a live region (tree test).
  - iOS: VoiceOver began "Email Enter an email address with an @, like
    name@example.com. T" (`voiceover-ios.md`); the test API's 64
    characters end there, so whether it read the error a second time, as
    the hint, was not seen.
- On Android a merged field with a value: in probe p12 (a field in
  `TestId` with its own `onUserInteraction`, holding "x") TalkBack said
  only "x / Edit box" when the error appeared, and the error was not
  spoken ([FL-181](#fl-181)). Merged, the error has no node of its own to
  announce, and the field's live region and hint text are read as for any
  field with a value ([FL-180](#fl-180)); that is a reading of the
  results, not an established cause.
- Why it matters here: the project's `TestId`
  (`lib/catalog/test_id.dart`) is a `MergeSemantics`. The F06 fields carry
  their identifier with `Semantics(identifier:)` instead, which joins the
  text field's node without merging anything ([FL-043](#fl-043): a
  `TextField` is not a container).
- Workaround: do not merge a field with its decoration. Put an identifier
  on it with `Semantics(identifier:)`.
- Upstream issue: not searched yet (D25). Merging is by design.

## FL-184

**Keyboard focus moved to a field does not move VoiceOver's cursor on iOS.**

- Status: Observed, Flutter 3.47.5, iOS 27.0 simulator, in the F06 probe
  (fixtures p06 and p07, `docs/evidence/probes/f06/ios.txt`). No test in
  the repository reproduces it: no example moves focus that way alone. The
  F06 VoiceOver test on iOS asserts that the workaround below works.
- What happens: after `FocusNode.requestFocus()` on the first field in
  error (p06), the keyboard was up, and VoiceOver's cursor was still on
  the button that sent the form: one move forward read a key ("I
  Button") and one back read "p06 Submit Button". On Android TalkBack's
  focus moved to the field (probe p06 node dump; asserted by the F06
  TalkBack walk). On the web the field's `<input>` got DOM focus, and
  VoiceOver read it ("Name Enter your name. invalid data edit text",
  `voiceover-web.md`).
- Workaround: send a `FocusSemanticEvent` to the field as well. On iOS it
  moved VoiceOver to the field (probe p07, a field in `TestId`: "p07 Name
  Enter your name. Text field Enter your name. Double tap"; the F06
  VoiceOver test: the cursor on "Name Text field …" after Send). It is
  documented for Android and iOS only, and on the web the engine ignores
  it (source read: `AccessibilityAnnouncements.handleMessage` acts only on
  a message with text; probe p07 on the web: DOM focus stayed on the
  button). F06 `good-form` and `good-cupertino` do both.
- Upstream issue: not searched yet (D25).

<!-- FL-200 to FL-299: Wave 2, links and simple components. Entries in this range go below, in id order. -->

## FL-200

**Flutter has no pressed state: a toggle button can only be a switch, a checkbox, or a button that is selected.**

- Status: Confirmed, Flutter 3.47.5, all platforms. Found in the C02
  probe (`docs/evidence/probes/c02`) and asserted by the C02 tests: the
  web spec requires that no good example has `aria-pressed`, and every
  layer asserts the switch or checkbox role of the good examples, each
  written to fail when that changes. Engine source read at the pinned
  revision: the web engine's `semantics/` folder, the Android
  `BaseRoleConfigurator.java`, and the iOS `SemanticsObject.mm` and
  `accessibility_bridge.mm`.
- What is missing: the toggle button's own state. HTML and APG have
  `aria-pressed` on a button; Android has `android.widget.ToggleButton`;
  iOS has had the toggle button trait since iOS 17
  (`UIAccessibilityTraitToggleButton`, "used when the element should be
  treated as a toggle", in UIKit's `UIAccessibilityConstants.h`).
  `SemanticsProperties` has no pressed state and `SemanticsRole` has no
  toggle button, and none of the engines writes one: `aria-pressed` does
  not appear in the web engine's semantics source, the Android engine's
  only checkable classes are `CheckBox`, `RadioButton`, and `Switch`, and
  the iOS engine sets no toggle button trait.
- What a toggle button can be given instead, and what each platform makes
  of it (probe, fixtures t01 to t21):
  - `selected` (`IconButton(isSelected:)`, a multi-select
    `SegmentedButton`, `Semantics(button: true, selected:)`): a button
    that is selected or not. On the web `role="button"` with
    `aria-current`; on Android a `Button` with `isSelected`; on iOS a
    button with the selected trait. Nothing is said for it while it is
    off ([FL-201](#fl-201)).
  - `checked` (`ToggleButtons`, `Semantics(checked:)`): a checkbox on
    the web (`aria-checked`) and Android (`CheckBox`), and a switch on iOS
    ([FL-035](#fl-035)). TalkBack says no state while it is off
    ([FL-045](#fl-045)).
  - `toggled` (`Semantics(toggled:)`): a switch on every platform,
    `role="switch"` with `aria-checked`, `android.widget.Switch`, and a
    switch on iOS. The state is said in both states: "off. Bold. Switch"
    and "checked. on. Bold. Switch" ([FL-100](#fl-100)) by TalkBack,
    "Bold Switch button off" by VoiceOver on iOS.
  A node with `button: true` and a toggled or checked state is the switch
  or the checkbox on Android and the web; the button flag is not shown
  (on iOS it adds the button trait, which a switch has anyway).
- Compared with native controls (the second native probe, files
  `…native2…` in `docs/evidence/probes/c02`; the first version of the
  fixtures removed the state on both platforms and its readings are not
  used, see the probe README):
  - Android: an `android.widget.ToggleButton` with Android's own
    `textOn` and `textOff` (the fixture sets only `contentDescription`,
    for the name, and `isChecked`) is a checkable `ToggleButton` whose
    state description is "OFF" or "ON" (`android_native2_nodes.txt`).
    TalkBack 17 reads it "OFF. n01 Bold. Switch", and "ON. n01 Bold.
    Switch" after a click (`talkback-native2.md.txt`). Flutter's `toggled`
    is read "off. Bold. Switch" and "checked. on. Bold. Switch": the same
    role and the same state words, with the extra "checked" of
    [FL-100](#fl-100). A `Button` with `isSelected` is read "selected.
    n03 Bold. Button", the same as Flutter's `selected`.
  - iOS: a UIKit button with the toggle button trait added to UIKit's own
    traits is a switch to XCUITest, and VoiceOver reads it "n01 Bold
    Switch button" while it is not selected and "selected n01 Bold Switch
    button" once a tap has selected it (`ios_native2.txt`). Flutter's
    `toggled` is read "Bold Switch button off" and "… on": the same role,
    with the state in other words ("off" and "on", where UIKit says
    nothing and "selected"). A plain button that is selected is read
    "selected n04 Bold Button", the same as Flutter's `selected`; UIKit's
    `changesSelectionAsPrimaryAction` button is read "n03 Bold Button",
    then "selected n03 Bold Button", with no toggle trait.
  - Web: VoiceOver on macOS reads a plain HTML `button` with
    `aria-pressed="false"` "Bold toggle button" and one with
    `aria-pressed="true"` "Italic selected toggle button", in Chromium and
    WebKit (`control-html` in `docs/evidence/C02/voiceover-web.md`). No
    Flutter node can be read that way.
  So the nearest native toggle buttons are read as switches by TalkBack
  and by VoiceOver on iOS, as Flutter's `toggled` is; on Android with the
  same state words, on iOS with different ones. Only the web has a
  toggle button role that Flutter cannot reach.
- What the user gets: the role heard is "switch" or "checkbox", not
  "toggle button". With `toggled` the state is said in both states on
  every platform, which is what 4.1.2 asks for. This is not counted as a
  WCAG failure here: 4.1.2 asks for a role that can be determined and for
  the state, and does not name the toggle button role.
- Workaround, in the SDK: give a toggle button `toggled` (with
  `enabled: true` on a node that has no enabled state of its own,
  [FL-033](#fl-033)), and on a Material button merge it with the
  button's node ([FL-040](#fl-040)). C02 `good-icon-button`,
  `good-cupertino`, and `good-custom`.
- How to read this entry: Flutter has not added a pressed state yet.
  Re-check when the pinned version changes.
- Upstream issue: not searched yet (D25).

## FL-201

**`IconButton(isSelected:)` and a multi-select `SegmentedButton` say nothing while they are off, and on the web their state is `aria-current`.**

- Status: Confirmed, Flutter 3.47.5, all platforms (a 4.1.2 failure on the
  web only). Found in the C02
  probe (fixtures t01 to t03, t06); asserted by the C02 widget, web,
  Android, and iOS tests (`bad-selected-only`) and heard in the C02
  transcripts. Source read: `IconButton` wraps its icon in
  `Semantics(selected: isSelected)` (`material/icon_button.dart`), and a
  `SegmentedButton` segment is `Semantics(selected:)`, in a mutually
  exclusive group only when one choice at a time is allowed
  (`material/segmented_button.dart`); the web engine writes `selected` on
  any role but row and tab as `aria-current` (`Selectable` in
  `semantics/checkable.dart`).
- What happens: these are the Material widgets for a button that stays
  pressed, and they expose the pressed state as `selected`. Selected is
  said only when it is true:
  - Android: a `Button`, `isSelected` true or false. TalkBack says
    "Bold. Button" while it is off and "selected. Bold. Button" while it
    is on.
  - iOS: a button with the selected trait or not. VoiceOver says "Bold
    Button" and "selected Bold Button".
  - Web: `role="button"` with `aria-current="false"` or `"true"`.
    VoiceOver says "Bold button" and "Bold current item button", in
    Chromium and WebKit, the same as for a plain HTML button with
    `aria-current="true"` ("Underline current item button", `control-html`
    in the same transcript), and not what it says for `aria-pressed`
    ("selected toggle button").
- What the user gets: while the button is off, the same as for a button
  that does nothing more than act, so nothing says that it is a toggle,
  that it can be pressed in, or that it is out. On the web "current item"
  is the wording for the current page or step in a set, not for a pressed
  button.
- WCAG 4.1.2, by platform:
  - Web: fails. The state is written as `aria-current`, a different state
    from pressed (and from selected), so the state the user sets is not
    exposed as itself.
  - Android and iOS: no failure as written. The selected state can be
    programmatically determined in both states: on Android the node is a
    `Button` with `selected="false"` or `"true"`
    (`docs/evidence/probes/c02/android_before.xml`, `android_after.xml`);
    on iOS XCUITest reports `isSelected` false or true (`ios.txt`), the
    engine setting the selected trait only while it is true, which is how
    UIKit represents a button that is not selected. A native button that
    is selected or not reads the same on both: "selected. n03 Bold.
    Button" and "n04 Bold. Button" by TalkBack, "selected n04 Bold
    Button" and "n03 Bold Button" by VoiceOver (`android_native2_nodes.txt`,
    `talkback-native2.md.txt`, `ios_native2.txt` in the C02 probe folder;
    these are plain buttons, which the first native fixtures did not set
    up differently, and read the same there). The weakness is the one
    above: while off, nothing says the control is a toggle. The nearest
    native toggle buttons do say it, by their role (FL-200).
- `ToggleButtons` is not affected: it sets `checked` (FL-200). A
  `FilterChip` sets `selected` on Android and iOS and `checked` on the
  web (`material/chip.dart`, whose comment gives the reason; probe,
  fixture t15); chips are not covered by C02.
- Workaround: give the button `toggled`, merged with its node, and leave
  `isSelected` out, drawing the pressed look with `style` (C02
  `good-icon-button`). With `isSelected` kept beside `toggled`, TalkBack
  said the state three ways when it was on, "selected. checked. on. Bold.
  Switch" (`talkback-first-run.md.txt` in the C02 probe folder).
- Upstream issue: not searched yet (D25).

## FL-202

**A `CupertinoButton` resolves its `color` for light and dark mode, and not its `foregroundColor`, so dynamic text colour stays light in dark mode.**

- Status: Confirmed, Flutter 3.47.5; measured in widget tests only (the
  test harness, which reports the Android platform by default), not on a
  device. Found in C02.
- Read in the source (`cupertino/button.dart`, `build`): the background
  is `CupertinoDynamicColor.maybeResolve(widget.color, context)`; the
  foreground is `widget.foregroundColor` as given, used for the text
  style and copied into the icon theme
  (`IconTheme.of(context).copyWith(color: …)`). Whether the icon's colour
  is then resolved depends on the icon theme above the button:
  `IconTheme.of` calls the theme's `resolve`, which a
  `CupertinoIconThemeData` uses to resolve a dynamic colour and a plain
  `IconThemeData` does not (`cupertino/icon_theme_data.dart`,
  `widgets/icon_theme.dart`, `widgets/icon_theme_data.dart`).
- Measured (`docs/evidence/probes/c02/icon_foreground.txt`, from
  `icon_foreground_test.dart.txt`): a `CupertinoButton` with
  `color: CupertinoColors.label` and
  `foregroundColor: CupertinoColors.systemBackground`, both unresolved,
  with an icon and the text "Mute":
  - In dark mode, under a `MaterialApp`: fill white, text white (1.00:1),
    icon white (1.00:1); the icon theme at the icon is a plain
    `IconThemeData`.
  - In dark mode, under a `CupertinoApp`: fill white, text white (1.00:1),
    icon black (21:1); the icon theme is a `CupertinoIconThemeData`.
  - In light mode, under either: text and icon white on black, 21:1.
  So the text keeps the light colour in dark mode under both apps; the
  icon does under a `MaterialApp`, which C02's app is, and not under a
  `CupertinoApp`.
- Measured in C02 (`docs/evidence/probes/c02/contrast_on.txt`): the first
  fix of `good-cupertino`, with that unresolved `foregroundColor`, had
  "Mute" white on white in dark mode and failed the text contrast
  guideline.
- WCAG: 1.4.3 Contrast (Minimum) for the text, where a dynamic
  `foregroundColor` is passed unresolved: measured above. No verdict is
  given for the icon: whether 1.4.11 applies to it depends on whether it
  is needed to understand the control, which was not judged.
- Workaround: resolve the colour first,
  `foregroundColor: CupertinoDynamicColor.resolve(CupertinoColors.systemBackground, context)`
  (C02 `good-cupertino`: text and icon 21:1 on the fill, light and dark,
  in `icon_foreground.txt`; its L1 tests check text contrast with the
  button on, in light and dark).
- Upstream issue: not searched yet (D25).

## FL-220

**On Android TalkBack says no role for a Flutter link.**

- Status: Confirmed, Flutter 3.47.5: asserted by C03's TalkBack walk
  (`docs/evidence/C03/talkback-android.md`) and its Android tree test
  (class `android.view.View`, the address in a `URLSpan` on the content
  description). One native view was compared in the C03 probe only
  (`docs/evidence/probes/c03/`, fixtures p02 to p06 and p09, and the
  native screen `ProbeNativeActivity.kt.txt`). Engine source read:
  `shell/platform/android/io/flutter/view/AccessibilityBridge.java`
  (`shouldBeTreatedAsButton`; `getLabel` adds the URL as a `URLSpan` to the
  label, which becomes the content description).
- WCAG: 4.1.2 Name, Role, Value. Not settled by the criterion as written:
  Android's accessibility API has no link role for a node to declare,
  which the Android Compose reference repository also says, so there is no
  role here that a link could be missing.
- What happens: `Semantics(link: true, linkUrl:)` gives an
  `android.view.View` whose content description is the name with a
  `URLSpan` over it. TalkBack, with focus moved to it, says the name and
  "Double-tap to activate", and no role. Without `linkUrl` the node is an
  `android.widget.Button` and TalkBack says "Button" ([FL-032](#fl-032)).
  The address rides on the label: a link node with no label of its own has
  no `URLSpan` at all, whether a child has the name or nothing has (probe
  p07, p10, p11; C03 `bad-label-on-image` and `bad-image-no-name`, which
  TalkBack then reads as "Button").
- Native comparison (probe, Android 17 emulator, TalkBack's verbose log):
  a clickable native `View` whose content description has the `URLSpan`,
  Flutter's shape, is read the same, "n02 native link description /
  Double-tap to activate". The probe's two other native views are not
  compared: n01, a `TextView` with the link in its text and no click
  listener, was not read in the 6 seconds after focus moved to it, why
  was not found; n03 was laid out with no height below n02, which filled
  the screen (`android-tree-native.txt`), so what was read for it is not
  relied on. Whether TalkBack treats a link in a native view's text
  differently was not measured.
- Why it matters: a TalkBack user cannot tell a Flutter link from any other
  control with a name by its role.
- Workaround, in the SDK: say what the link does in the tap hint, as the
  Android Compose reference does with `onClickLabel`:
  `Semantics(onTapHint: 'open link')` makes TalkBack say "Double-tap to
  open link" in place of "Double-tap to activate" (C03's good examples).
  `onTapHint` is ignored on iOS (framework source: `SemanticsHintOverrides`)
  and not read by the web engine.
- Upstream issue: not searched yet (D25).

## FL-221

**Material and Cupertino have no link widget, and a link put round one of their buttons is a button as well.**

- Status: Confirmed, Flutter 3.47.5, for `CupertinoButton`: asserted by C03
  `bad-cupertino-button` in the widget, web, Android, and iOS tests and
  heard in its transcripts. Material's `TextButton` measured in the C03
  probe only (`docs/evidence/probes/c03/`, fixture p07; `CupertinoButton`
  is p08). Framework source read: `cupertino/button.dart` wraps its child
  in `Semantics(button: true)`, and no parameter turns that off.
- WCAG: 4.1.2 Name, Role, Value, by platform:
  - `CupertinoButton`: on iOS not settled, as VoiceOver says both "Button"
    and "Link" and the criterion does not say whether two roles identify
    the control; on Android not settled, as Android has no link role and
    a button is the stand-in the Android Compose reference uses; on the
    web none, a link only.
  - `TextButton` (probe only): on iOS a failure, as VoiceOver stops on the
    button alone, a role that does not identify a link, and the link round
    it has no name; on Android not settled, for the same reason as above;
    on the web not settled, as the link holds a button and what a screen
    reader says for it was not measured.
- What happens: Flutter has not added a link widget to Material or to
  Cupertino. The obvious way to make one, `Semantics(link: true, linkUrl:)`
  round a `TextButton` or a `CupertinoButton`, keeps the button:
  - `CupertinoButton` (p08, `bad-cupertino-button`): one node with the link
    and the button flags. iOS: XCUITest's type is button, and VoiceOver
    says "p08 cupertino Button Link". Android: class `Button`, with the
    address in a `URLSpan`; TalkBack says "Button". Web: one `<a href>`,
    whose role is link, so the web is not affected.
  - `TextButton` (p07): two nodes, a link with no name round a button.
    iOS: VoiceOver stops once, on the button, "p07 text Button". Android:
    a `View` with no name and no address round a `Button`; TalkBack says
    "Button". Web: an `<a href>` with a `role="button"` inside it; Tab
    reaches the button, and Enter runs the button and does not follow the
    `href`, while a click does both.
- Why it matters: the iOS reference repository's Links page says to remove
  the button trait from a link because VoiceOver otherwise says "Button,
  Link". In Flutter the trait cannot be removed from these widgets.
- Workaround, in the SDK: build the link from a widget that is not a
  button: `InkWell` (C03 `good-material`), `CupertinoListTile` with
  keyboard focus added (`good-cupertino`), or a `GestureDetector` with
  `FocusableActionDetector` (`good-custom`), each inside
  `Semantics(link: true, linkUrl:)`.
- Upstream issue: not searched yet (D25).

## FL-240

**A link in a `TextSpan` takes no keyboard focus, and cannot be given an address.**

- Status: Confirmed, Flutter 3.47.5: asserted by C04 `bad-text-span` in
  the widget, web, Android, and iOS tests. Found in the C04 probe
  (`docs/evidence/probes/c04/`, fixtures r01, r07, r09). Framework source
  read: `rendering/paragraph.dart` (`assembleSemanticsNode`).
- What happens: a `TextSpan` with a `TapGestureRecognizer`, the SDK's own
  way of putting a link in text (and the example in `TextSpan.recognizer`'s
  documentation), gets a semantics node of its own with the link flag and
  the tap action, in its place in the sentence. That is all it gets: the
  source sets `isLink` and `onTap` and nothing else, so it has no focus
  node and no `linkUrl`, and no API on `TextSpan` adds either.
  - Keyboard: Tab never reaches it, in the widget tests, in Chromium, on
    the Android emulator (`input keyevent`), and on the iOS simulator (one
    to three Tabs, then Enter: the link's handler never ran, probe
    `ios.txt`). A tap, and the tap action (the widget tests'; Android's
    click action, what TalkBack's double tap performs), follow it.
  - With no address it is a link on iOS only ([FL-032](#fl-032)): an
    `android.widget.Button`, which TalkBack reads "… / Button / Double-tap
    to activate" (probe `android-talkback.md`), and on the web an `<a>` with
    no `href` and no `tabindex`, which Chromium's own tree calls a link and
    Playwright's role check does not. VoiceOver on the web reads it "link
    links in text" in Chromium and WebKit, in its place between "Read
    about" and "first." (`docs/evidence/C04/voiceover-web.md`), so on the
    web the missing address is not heard; the keyboard is the defect.
  - `SelectableText.rich` gives its spans the same nodes on Android and
    iOS (r07), with the same keyboard result; on the web see
    [FL-245](#fl-245).
  - A recognizer span that wraps onto a second line has one node whose box
    covers both lines whole, the words before and after it included
    (r09: on iOS its frame starts at the paragraph's left edge on the first
    line; on Android, `Rect(32, 554 - 1021, 851)` at 200%). XCUITest's tap
    at the centre of that box missed the link on iOS (r09 "second tap",
    `ios.txt`), and VoiceOver's cursor, put by a tap at either link, landed
    on the other link or on the words after it; the same kind of node for
    a run of words is [FL-246](#fl-246).
- WCAG: 2.1.1 Keyboard, where no other keyboard path reaches the link's
  destination (`bad-text-span` opens a page nothing else opens). By
  platform: all three.
- Why it matters: the recognizer span is the link that flows with the
  text and is read in its place; it is the one a developer reaches for,
  and the keyboard cannot use it. The iOS reference repository records the
  same gap for SwiftUI's own inline links.
- Workaround, in the SDK, verified in C04's good examples on every layer:
  make each link a `WidgetSpan` holding a focusable link (an `InkWell` or a
  `FocusableActionDetector` inside `Semantics(link: true, linkUrl:)`), with
  [FL-413](#fl-413)'s workaround to keep it in its place, the text inside
  it unscaled ([FL-241](#fl-241)), and the cost that it cannot break
  across lines ([FL-244](#fl-244)).
- How to read this entry: Flutter has not added keyboard focus or an
  address to a link in a `TextSpan` yet.
- Upstream issue: not searched yet (D25).

## FL-241

**Text inside a `WidgetSpan` is scaled twice by the text size setting.**

- Platforms: Android, iOS, and the test framework; the web was not
  measured.
- Status: Confirmed, Flutter 3.47.5: asserted on the SDK alone by the C04
  widget test "FL-241", written to fail when it is fixed, and measured on
  the Android emulator at a system font scale of 2.0 (probe
  `android-rects-200.txt`) and on the iOS simulator at the text size
  accessibility-large (probe `ios-rects.txt`). Framework source read:
  `widgets/widget_span.dart` (`WidgetSpan.extractFromInlineSpan`,
  `_AutoScaleInlineWidget`), which carries the comment "this shouldn't
  happen automatically, at least there should be a way to opt out" and
  points at flutter/flutter issue 126962 (read in the source, not opened).
- What happens: a `WidgetSpan` lays its widget out at the paragraph's
  width divided by the text scale and draws it scaled up by the text
  scale. A `Text` inside the widget reads the same text scale from
  `MediaQuery` and scales its own letters as well. At 200% the link's
  letters are drawn at 400%: in the widget test a `Text` in a `WidgetSpan`
  is twice the height of the words round it (`flutter_test.txt`, r03: the
  link's paragraph laid out at 384 by 80 with a 2.0 text scaler, shown at
  768 by 160). On the Android emulator at font scale 2.0, r03's links are
  180 pixels tall where the words' line is 102 (`android-rects-200.txt`).
- WCAG: none failed as written: no text is lost, and 1.4.4 asks for 200%
  without loss of content or function.
- Why it matters: a link in a sentence grows twice as fast as the words
  round it, so at large text sizes each link takes a line of its own and
  the sentence breaks up.
- Workaround, in the SDK, verified in C04's good examples (widget test
  "at 200% text the links are the size of the words round them") and on
  the emulator (probe r10: links 98 pixels tall in a 102 pixel line): put
  the text inside the `WidgetSpan` in `MediaQuery.withNoTextScaling`, so
  that only the `WidgetSpan` scales it.
- How to read this entry: Flutter has not added a way to opt a
  `WidgetSpan` out of its scaling yet.
- Upstream issue: not searched yet (D25); the framework source names
  issue 126962, which was not opened.

## FL-242

**`CupertinoColors.link` and `CupertinoColors.systemBlue` are 4.02:1 on white, under the 4.5:1 that text needs.**

- Status: Confirmed, Flutter 3.47.5: asserted by the C04 widget test
  "FL-242". Framework source read: `cupertino/colors.dart`.
- Platforms: all; it is a colour. Measured in the widget tests only.
- What happens: both colours are `#007AFF` in light mode, 4.02:1 on white
  and 3.82:1 on the Material page colour of this app's light theme
  (`flutter_test.txt`, "contrast"). `CupertinoColors.link` has no
  high-contrast variant (the same `#007AFF`); `systemBlue`'s is `#0040DD`,
  7.56:1 on white. In dark mode both are 5.76:1 on black.
- WCAG: 1.4.3 Contrast (Minimum) for link text at body size in light
  mode, wherever the colour is used as given.
- Why it matters: `CupertinoColors.link` is the colour named for links. The
  iOS reference repository says the same of the system's default link
  colour and asks for one with 4.5:1.
- Workaround, in the SDK, in C04 `good-cupertino`: use
  `CupertinoColors.systemBlue.highContrastColor` in light mode and its
  `darkHighContrastColor` in dark.
- How to read this entry: this is the platform's colour, copied; the SDK
  does not resolve to the high-contrast variant unless the device asks for
  more contrast.
- Upstream issue: not searched yet (D25).

## FL-243

**`MergeSemantics` round a sentence with links makes one link, with the first link's address and action.**

- Status: Confirmed, Flutter 3.47.5: asserted by C04 `bad-merged` in the
  widget, web, Android, and iOS tests. Found in the C04 probe (fixture
  r05).
- What happens: the sentence, its words and both links, becomes one node
  whose label is the whole sentence, with the link flag, and one
  `linkUrl` and one tap action, the first link's:
  - Android: one `View` named by the sentence, with one `URLSpan`, the
    first link's, over all of it; `ACTION_CLICK`, what TalkBack's double
    tap performs, follows the first link. TalkBack read the sentence and
    no role (probe `android-talkback.md`, r05).
  - iOS: one link named by the sentence (probe `ios.txt`); VoiceOver reads
    it as one stop. VoiceOver's own activation of it is not measured
    (C04 probe round 3).
  - Web: one `<a href>` with the first link's address. A click on the
    first link's words, on the second link's, and on the first words, and
    Enter after two Tabs and after three, follow the first link
    (`web_merged.txt`, and C04's web tree tests); Tab stops on the one element twice, as
    the two links' focus nodes are still there. VoiceOver reads one stop,
    "link Read about links in text and stand-alone links first.", in
    Chromium and WebKit (`docs/evidence/C04/voiceover-web.md`).
  - Touch, off the web, still reaches each link: Flutter's own hit test is
    not merged.
- WCAG: 4.1.2 Name, Role, Value: the second link is a control with no name
  and role of its own. By platform: all three. On the web 2.1.1 as well
  only if nothing else reaches its page; in `bad-merged` C03's page is
  reached through the app's own catalog, so 2.1.1 is not claimed.
- Why it matters: `TestId`, which this project puts round controls, is a
  `MergeSemantics`, and so is the usual way of making a row one stop. The
  Android Compose reference merges its text for TalkBack, which then
  offers the links in its links menu; a merged Flutter sentence has no
  such menu, so the links after the first are lost.
- Workaround: do not merge a sentence that has links. Put identifiers on
  each link's own container (C04's good examples).
- Upstream issue: not searched yet (D25).

## FL-244

**A link in a `WidgetSpan` cannot break across lines with the text round it.**

- Status: Confirmed, Flutter 3.47.5, in the C04 probe (fixtures r03, r06,
  r09, r10) on Android and iOS and in the widget tests; the C04 widget
  tests check that nothing is cut short or overflows at 200% on a 320
  pixel screen. Framework source read: `rendering/paragraph.dart` (a
  placeholder is one box in the line).
- What happens: the link is one box. If it does not fit what is left of
  the line, the whole link goes to the next line; if it is wider than the
  line, it wraps inside its own box, and the words after it start below
  it. r06's long link is a block of its own on Android (`Rect(42, 739 -
  1038, 1641)` at font scale 2.0) and on iOS (a 370 by 40 frame from the
  paragraph's left edge, `ios.txt`), where the same words as a `TextSpan`
  (r09) flow on from the end of the line.
- WCAG: none failed as written.
- Why it matters: the keyboard-reachable link ([FL-240](#fl-240)) does not
  look like a link in running text once it is long or the text is large:
  it leaves a gap at the end of the line before it.
- Workaround: none in the SDK. Keep link text short.
- How to read this entry: Flutter has not added a focusable span that
  flows with the text yet.
- Upstream issue: not searched yet (D25).

## FL-245

**On the web `SelectableText` is an empty, disabled text field: its text and its links are not in the page.**

- Status: Observed, Flutter 3.47.5, Chromium, in the C04 probe only
  (fixture r07, `docs/evidence/probes/c04/web.txt`). On Android and iOS the
  same fixture's words and links are nodes as a `Text.rich`'s are
  ([FL-240](#fl-240)).
- What happens: `SelectableText.rich` with two link spans is a
  `<textarea disabled>` with an empty value in the semantics tree, which
  Playwright's ARIA snapshot reads as "textbox [disabled]". No element has
  its words or its links.
- WCAG: 1.3.1 and 4.1.2 for its links, as candidates; nothing is claimed,
  as no example was built and no screen reader was run on it.
- Why it matters: selectable text with links in it is not exposed at all
  on the web.
- Workaround: none tried. C04's links are in a `Text.rich`, which is not
  selectable.
- Upstream issue: not searched yet (D25).

## FL-246

**A run of a paragraph's text that wraps has one node over the whole of its lines, which can lie over a link on the first line: on iOS a VoiceOver touch on the link finds the words.**

- Status: Confirmed, Flutter 3.47.5, iOS 27.0 simulator: asserted by the
  C04 iOS VoiceOver test (`touchOnALinkFindsTheLastWords`), written to fail
  when the cursor lands on the link; found in the C04 probe's second iOS
  round (`docs/evidence/probes/c04/ios_round2.txt`). Framework source read:
  `rendering/paragraph.dart` (`assembleSemanticsNode` makes a run's rect
  the union of all its text boxes, each grown by 4 pixels).
- Platforms: iOS. Android and the web were not measured.
- What happens: in C04 `good-material` on the iPhone 17 simulator the
  sentence takes two lines, and its last run, " first.", starts at the end
  of the first line and ends on the second. Its node's frame is
  (12, 256, 378 by 52), the whole width of both lines, so it lies over both
  links, whose frames are 24 points tall on the first line. With VoiceOver
  on, a tap at either link's centre puts the cursor on "first." and not on
  the link. Moving the cursor by swiping reaches each link and reads it as
  a link (the same test). VoiceOver's own activation of the focused link is
  not measured: XCUITest's taps act on what is under them, and its
  VoiceOver service has no activation (C04 probe round 3,
  `docs/evidence/probes/c04/ios_round3.txt`). A `TextSpan` link that wraps has the same kind
  of node over its lines ([FL-240](#fl-240), probe r09).
- WCAG: none claimed: swiping reaches every link and the keyboard reaches
  and follows it. A VoiceOver user who explores the screen by touch does
  not find the link under their finger.
- Workaround: none found in the SDK. Short sentences whose runs do not
  wrap avoid it.
- How to read this entry: Flutter has not given each line of a run a node
  of its own yet.
- Upstream issue: not searched yet (D25).

## FL-247

**A tooltip with a plain message, and every `IconButton.tooltip`, takes no pointer events, so the pointer cannot move onto it.**

- Status: Confirmed, Flutter 3.47.5. Widget tests, web (Chromium,
  Playwright), Android (Pixel emulator, Android 17, a mouse hover injected
  through UiAutomation). iOS not measured (XCUITest cannot hover). Found
  in the C12 probe (`docs/evidence/probes/c12/`: `flutter_test.txt`,
  "pointer moved onto the tooltip"; `web.txt`, "pointer on the tooltip";
  `android-tree.txt`, "mouse moved onto the tooltip"): fixtures t01 to t07
  and t11 to t13, all plain messages, went within 500 ms of the pointer
  reaching the tooltip; t08 (`ignorePointer: false`) and t09
  (`richMessage`) stayed. Asserted by the C12 widget tests "the SDK alone:
  ... the tooltip goes when the pointer moves onto it" and by
  `bad-not-hoverable` on the web (`web_tests/c12_tooltip.spec.js`) and on
  Android (`C12TooltipTest.badNotHoverableGoesWhenThePointerMovesOntoIt`).
  Source read: `material/tooltip.dart`, `ignorePointer: widget.ignorePointer
  ?? widget.message != null`; `widgets/raw_tooltip.dart` wraps the shown
  tooltip in `IgnorePointer`, so its own `MouseRegion` never sees the
  pointer, and the pointer leaving the control hides it 100 ms later.
- WCAG: 1.4.13 Content on Hover or Focus, the hoverable condition, which
  has no exception for a tooltip drawn by the app (F95).
- What happens: a `Tooltip(message:)` and the tooltip of `IconButton`,
  and of every widget that builds `Tooltip(message: tooltip)` itself
  (`ButtonStyleButton`, read in `material/button_style_button.dart`), goes
  when the pointer moves from its control onto it. A large pointer, or a
  screen magnifier that follows the pointer, cannot read it.
- Workaround, in the SDK, for a `Tooltip` of your own: `ignorePointer:
  false`, or a `richMessage`, whose default is false (C12's good
  examples). `IconButton` and the other widgets with a `tooltip` parameter
  have no way to pass it: Flutter has not added one yet. Leave their
  `tooltip` unset and put a `Tooltip` round them, with the name given
  another way (C12 `good-material`).
- Upstream issue: not searched yet (D25).

## FL-248

**No Flutter tooltip shows on keyboard focus, so showing one fails 2.1.1 wherever a keyboard is used.**

- Status: Confirmed, Flutter 3.47.5, all platforms. In the C12 probe Tab
  to each fixture's control showed none of the framework's tooltips: the
  widget test (`flutter_test.txt`, "Tab stops"), the web (`web.txt`, "Tab
  stops": the band under the control unchanged), Android (`android-tree.txt`,
  "Tab stops"), iOS (`ios.txt`, "after 1 Tab(s)", "after 2 Tab(s)": no
  tooltip text element). Asserted by the C12 widget tests "keyboard focus
  does not show the tooltip" (the SDK alone and each good example), by
  `web_tests/c12_tooltip.spec.js` ("Tab to the control does not show the
  tooltip"), `C12TooltipTest.keyboardFocusDoesNotShowTheTooltip`, and
  `C12TooltipUITests.testKeyboardFocusDoesNotShowTheTooltip`, each with a
  hover or a long press in the same launch as the positive control, and
  written to fail when focus does show it. Source read:
  `widgets/raw_tooltip.dart` shows a tooltip on a mouse entering, on a
  long press or a tap, and from `ensureTooltipVisible()`; nothing listens
  to focus.
- WCAG: 2.1.1 Keyboard fails wherever a keyboard is used, for every
  tooltip: showing it is functionality, a hover or a long press performs
  it, and no key does. That the control works from the keyboard, or has a
  name for assistive technology, does not give a sighted keyboard user a
  way to reveal the tooltip's words; 1.1.1 and 2.5.3 give no exemption.
  The Understanding document for 1.4.13 says content a hover can show
  "should also be able to be triggered by keyboard focus" and points to
  2.1.1; APG's tooltip pattern shows the tooltip on focus. In C12 this is
  every example, the three good ones included (their keyboard-focus tests
  on every layer, above). No failure of 1.4.13 is claimed from it: 1.4.13
  covers content that does appear on focus and does not require any to.
- What users get: a keyboard user never sees a tooltip. Where the tooltip
  is an icon button's name, its words reach a screen reader as the name,
  and a sighted keyboard user cannot reveal them.
- Workaround: none in the framework. Flutter has not added a way for a
  tooltip to show on focus. (`TooltipState.ensureTooltipVisible()` exists;
  calling it from a focus listener is code of the app's own, which C12
  does not build.)
- Upstream issue: not searched yet (D25).

## FL-249

**While a tooltip is shown, its text is a node of its own inside its control.**

- Status: Confirmed, Flutter 3.47.5. Widget tests: a shown tooltip's text
  is a semantics node whose traversal parent is its `OverlayPortal`, so in
  traversal order it is inside the control, though not its child in the
  tree (C12 widget tests "while shown, the tooltip's text is a node of its
  own inside the control", for the SDK alone and each good example). Web
  (Chromium): an element with the text, outside the control
  (`web_tests/c12_tooltip.spec.js`, every good example and
  `bad-repeats-name`); in the probe, where nothing came between a tooltip
  and its button, the button owned it (`aria-owns`) and Chromium added it
  to the button's name: "t01 Delete draft t01 Delete draft"
  (`web_round2.txt`). Android: a focusable `View` named by the text
  (`android-tree.txt`, "tooltip text nodes"). iOS: a static text element
  in the probe, where nothing merged it (`ios.txt`, t01 after a touch, t10
  after a Tab); in the C12 examples, each inside `TestId`'s
  `MergeSemantics`, a long press drew the tooltip and left XCUITest's tree
  as it was, no second element and no change to the control's label
  (`C12TooltipUITests`, the `C12IOS` lines of its log). Whether VoiceOver
  finds it there was not measured. Read in the source:
  `widgets/raw_tooltip.dart` builds the tooltip in an
  `OverlayPortal.overlayChildLayoutBuilder` and leaves its text in the
  semantics tree.
- What users get: while a tooltip is shown, the tree has the control and
  then its tooltip's words again, as a node a screen reader could stop on
  (on Android a focusable one). When the tooltip is hidden the node goes.
  Not measured with a screen reader while a
  tooltip was shown: in C12's web VoiceOver walks no tooltip was shown,
  and nothing was read twice in either browser
  (`docs/evidence/probes/c12/voiceover-web-round1-fail.md.txt`).
- C13 (2026-11-22) found the same on the close button that
  `SnackBar.showCloseIcon` adds, an `IconButton` whose tooltip is
  "Close", which the app cannot leave out: with the pointer on it, in
  Chromium and WebKit, the button owns the tooltip's element (`aria-owns`)
  and Chromium names it "Close Close", still a button; with keyboard focus
  alone no tooltip is shown and it is named "Close"
  (`docs/evidence/probes/c13/close_probe.txt`; asserted by
  `web_tests/c13_snackbar.spec.js`). In C13's first web VoiceOver
  recording Chromium read that button "Close Close", with no role, and
  WebKit "Close button"
  (`docs/evidence/probes/c13/voiceover-web-round1-fail.md.txt`). The
  second recording read the same, Chromium "Close Close" and WebKit "Close
  button", and after each walk Close's tooltip was shown, in both browsers
  (`voiceover-web-round2-fail.md.txt`, row
  `good-action-close-tooltip-after-walk`). Every C13 recording since read
  the same, seven in all: Chromium "Close Close", WebKit "Close button",
  the tooltip shown after each walk (`voiceover-web-round3-fail.md.txt`,
  `voiceover-web-round4-fail.md.txt`, `voiceover-web-round5.md.txt`, and
  the transcript, `docs/evidence/C13/voiceover-web.md`). So a walk that reaches Close
  leaves its tooltip shown, and Chromium's VoiceOver then reads the doubled
  name with no role word; WebKit's reads the name once with its role. The
  tree keeps the role, a button, while the tooltip is shown
  (`close_probe.txt`), so the role is programmatically determinable: not a
  4.1.2 failure as written. But a Chromium VoiceOver user does not hear
  "button" on Close. What shows the tooltip during the walk (the pointer
  following VoiceOver's cursor is the likeliest, and keyboard focus alone
  does not), and why Chromium's speech drops the role, were not measured
  beyond that correlation. `SnackBar` has no parameter for the close
  icon's tooltip (read in the source: `material/snack_bar.dart` builds the
  `IconButton` with `tooltip: MaterialLocalizations.of(context)
  .closeButtonTooltip`), so an app cannot leave it out for one SnackBar;
  only its words could be changed, app-wide, through `MaterialLocalizations`.
  This is recorded here and not as an entry of its own because the doubled
  name is this entry's mechanism, a shown tooltip's text owned by its
  control; the dropped role word is VoiceOver's reading of that name in
  Chromium.
- Workaround: `Tooltip.excludeFromSemantics` leaves out the tooltip's
  semantics on its control, not the shown text. None in the framework for
  the shown text; Flutter has not added one yet.
- Upstream issue: not searched yet (D25).

## FL-250

**A tooltip whose box lies over its control's edge does not stay hidden after Escape while the pointer is on that strip: a `RawTooltip` by default, and a Material `Tooltip` on a control taller than 48.**

- Status: Confirmed in the widget tests only, Flutter 3.47.5, in two
  cases. Not measured on a device.
  - `RawTooltip` with its defaults: found in the C12 probe (t14,
    `flutter_test.txt`, "Escape while hovered: shown=true", and
    `probe2_test.dart.txt`, "Escape frame by frame": hidden for one frame,
    then shown again). Asserted by the C12 widget test "RawTooltip by
    default: placed over the control's lower half, and Escape with the
    pointer there does not hold". Source read: `widgets/raw_tooltip.dart`,
    `_TooltipPositionDelegate`, which calls `positionDependentBox` with no
    vertical offset, so the box's top is the control's centre.
  - Material's `Tooltip` with its default `verticalOffset`, 24, round a
    `CupertinoButton`, 52.4 high (C12 `good-cupertino` as first built):
    the box lay 2.2 over the button's bottom edge, and flipped above at
    200% text on a 320 wide screen, 2.2 over its top edge. With the
    pointer in that strip, after Escape the tooltip faded out over five
    frames, was gone for three, and from the ninth was shown again and
    stayed
    (`docs/evidence/probes/c12/flutter_test_overlap.txt`, from
    `probe5_test.dart.txt`). Source read: Material's `Tooltip` places its
    box `verticalOffset` from the control's centre, so any control taller
    than twice that, 48 by default, is overlapped. On 48 high controls
    (`good-material`, `good-description`) the gap is 0.0 in both
    directions, and Escape held with the pointer on either side of the
    edge.
- WCAG: 1.4.13, dismissible, where the box covers content.
- What happens: with the pointer on the strip where the box lies over the
  control, the pointer is on the box. Escape hides it, the pointer is then
  on the control, and the hover shows it again.
- Workaround, in the SDK: place the box off the control. For Material's
  `Tooltip`, a `verticalOffset` of at least half the control's height
  (C12 `good-cupertino`: 28 on a 52.4 high button, a gap of 1.8 below and
  above, asserted by the C12 widget tests "the shown tooltip lies over
  other text on the screen", which require no overlap, and "with the
  pointer at the tooltip's edge nearest the other, Escape hides the
  tooltip and it stays hidden" and its counterpart at the control's edge,
  which failed with the default offset); for a `RawTooltip`, a
  `positionDelegate`.
- Upstream issue: not searched yet (D25).

## FL-251

**A tooltip is part of its control's name on iOS and the web, before the control's own text on the web; only Android treats it as separate text.**

- Status: Confirmed, Flutter 3.47.5. The C12 probe, fixture t05 (a
  `Tooltip` merged into a `FilledButton` with text): iOS label "t05
  Download\nt05 Saves a PDF copy", read "t05 Download t05 Saves a PDF copy
  Button" (`ios.txt`); web `aria-label` "t05 Saves a PDF copy\nt05
  Download", Chromium name "t05 Saves a PDF copy t05 Download" (`web.txt`);
  Android content description "t05 Download" and tooltip text "t05 Saves a
  PDF copy", read "t05 Download / Button. t05 Saves a PDF copy"
  (`android-talkback.md`). Asserted for `good-description` and
  `bad-repeats-name` by every tree layer. Engine source read:
  `SemanticsObject.mm` (iOS) appends the tooltip to the label after a line
  break; `computeDomSemanticsLabel` in the web engine's
  `label_and_value.dart` puts it first; `BaseRoleConfigurator.java`
  (Android, API 28 and later) sets it as the node's tooltip text.
- WCAG: none failed as written: the name holds the control's visible text
  (2.5.3) and is determinable (4.1.2). APG's tooltip is the control's
  description (`aria-describedby`), not its name.
- What users get: on iOS and the web a tooltip that describes a control
  is read as part of its name, and on the web before it. A tooltip that
  repeats the control's text is read twice there (C12
  `bad-repeats-name`); TalkBack reads it once.
- Workaround: none in the framework for a description. Flutter has not
  added a tooltip that is a description on iOS and the web.
- Upstream issue: not searched yet (D25).

## FL-252

**On iOS VoiceOver does not stop on a node whose only text is a tooltip.**

- Status: Confirmed, Flutter 3.47.5, iOS 27.0 simulator. The C12 probe's
  VoiceOver walks (`ios.txt`): t07 and t12, a `Tooltip` on an `Icon`, were
  passed over ("Before t07 / t07 line under the control"), and so were the
  nodes of t02, t04, t08 to t10, and t13, where the tooltip sat outside a
  Material button: only "Button" or the button's own text was read.
  XCUITest lists each of them with the tooltip as its label. Asserted by
  the iOS VoiceOver walks of C12 `bad-hover-only` and `bad-outside-button`
  (`C12TooltipUITests.testVoiceOverSpeech`). Engine source read:
  `SemanticsObject.mm`, `isFocusable`, which makes a node an accessibility
  element when it has a label, a value, a hint, or an action, and does not
  look at its tooltip.
- What users get: an information icon explained by a `Tooltip`, the
  framework's way to explain an icon, is silent to VoiceOver on iOS. TalkBack
  reads it, and so does the web's tree.
- Workaround: give the node a label as well, for example
  `Icon(semanticLabel:)` with `excludeFromSemantics: true` on the tooltip
  (C12 `good-material` names its button this way).
- Upstream issue: not searched yet (D25).

## FL-253

**A `FilledButton`'s text is under 4.5:1 in light mode while it has keyboard focus and a hover.**

- Status: Confirmed in the widget tests only, Flutter 3.47.5, the app's
  indigo seed. Found building C12 `good-description`, first a
  `FilledButton`: the text contrast guideline gave 4.28:1. The probe
  (`flutter_test_buttons.txt`, from `probe4_test.dart.txt`) ran the
  guideline on a `FilledButton`, an `OutlinedButton`, and a `TextButton`
  with focus, a hover, and both, in light and dark: only the
  `FilledButton` with both, in light mode, failed. Not measured on a
  device. Why was not looked into.
- WCAG: 1.4.3 Contrast (Minimum), in that state.
- Workaround: another button (C12 uses an `OutlinedButton`), or a
  `style` whose overlay keeps the contrast. Not tried.
- Upstream issue: not searched yet (D25).

## FL-254

**A change of a progress indicator's value is not announced, even with the screen reader on the indicator.**

- Status: Confirmed, Flutter 3.47.5. Measured in the C26 probe
  (`docs/evidence/probes/c26/`): a `LinearProgressIndicator` going 0 to
  100 in five steps, with the screen reader's focus on it and on the
  button that started it. Android 17 with TalkBack
  (`android-talkback.md`, `p17-on-indicator-pressed` and
  `p17-on-start-pressed`): nothing was said for the steps, while the
  node's range changed every step (`android-tree.txt`, `p17 at …`). iOS
  27.0 with VoiceOver (`ios.txt`, `VO p17 on the indicator` and `on
  Start`): nothing was said from 10 s to 24 s after the screen opened,
  while the element's value went 0 to 100. Web, Chromium: nothing was
  written to Flutter's announcement elements (`web.txt`, `p17
  announcements []`), while `aria-valuenow` changed every step. What
  VoiceOver on the web says for it has not been recorded. Engine source
  read: Android's `AccessibilityBridge` sends a content change only for a
  live region whose label changed; iOS's `SemanticsObject.mm` gives a
  node the "updates frequently" trait only when it is a live region.
- WCAG: 4.1.3 Status Messages, for progress shown only by the indicator.
- What it means: the indicator's value can be read by moving to it, and
  is never told as it changes. That is also how ARIA's `progressbar`
  works on the web: it is not a live region, and ARIA25 gives progress to
  a screen reader through a separate live region. Whether a native
  Android `ProgressBar` or a UIKit progress view announces its changes
  was not measured.
- Workaround, used by C26's good example and its spinners: a line of text that says how
  the task is going and that it has ended, in `Semantics(liveRegion:
  true)`; it was announced on all three platforms (the probe's p18, p21,
  p22). A live region round the indicator itself (p21) is announced when
  its label changes, not its value. `SemanticsService.sendAnnouncement` at
  the end (p19) was spoken on iOS and the web, and by TalkBack too, though
  Android reports it as unsupported ([FL-018](#fl-018)).
- Asserted by C26 `bad-silent-end` on every layer: its tree tests (no live
  region); the web's recorder (nothing at all written to Flutter's
  announcement elements); the TalkBack transcript, two rows that must be
  silent, nothing at all said in the nine seconds after the press, with
  TalkBack focus on the button and then on the bar while its value goes
  0 to 100, each followed by a reading that shows the capture live; and
  the iOS VoiceOver transcript (nothing heard after the tap but the
  button's own utterance, then the status line read). The web VoiceOver
  test listens for the upload's status phrases only.
- Upstream issue: not searched yet (D25).

## FL-255

**Cupertino's activity indicators give no semantics, and have no parameter for a name or a value.**

- Status: Confirmed, Flutter 3.47.5. Source read:
  `cupertino/activity_indicator.dart`: `CupertinoActivityIndicator`,
  `CupertinoActivityIndicator.partiallyRevealed`, and
  `CupertinoLinearActivityIndicator` paint and add no `Semantics`, and
  take no label or value. Measured in the C26 probe (p11, p12, p13): the
  widget tests have no node of their own for them; Android 17 a `View`
  with no description that is not focusable, which TalkBack says nothing
  for; iOS 27.0 nothing but an identifier, which VoiceOver passed over;
  the web an element with no role, name, or text.
- WCAG: 4.1.2 Name, Role, Value, where the indicator is taken to be a
  user interface component (C26's spec, section 3).
- What users get: a spinner or a progress bar that a screen reader does
  not find, with its value lost for the bar.
- Workaround: for a spinner, `Semantics(label:)` round it (the probe's
  p14; C26 `bad-cupertino-no-role`) gives a name, read as plain text on every
  platform, which is all Material's spinner gives too
  ([FL-256](#fl-256)). For the bar, none that this project counts as not
  hand-built: a value with `Semantics(value:)` on a drawing was judged
  borderline in S14, and a progress bar role needs `SemanticsRole`, a role
  set by hand. C26 shows the bar as it comes (`bad-cupertino-bar`) and
  builds nothing.
- Upstream issue: not searched yet (D25).

## FL-256

**A spinner has no role on any platform, and on iOS no progress indicator has one.**

- Status: Confirmed, Flutter 3.47.5. Material's indeterminate indicators
  set `SemanticsRole.loadingSpinner` (source read:
  `material/progress_indicator.dart`). In the C26 probe (p05, p08):
  - Web, Chromium: an element with an `aria-label` and no role, which
    Chromium gives the role "generic" (`web.txt`). Engine source read:
    `semantics/progress_bar.dart`, `SemanticsLoadingSpinner` sets no ARIA
    role. HTML's `progress` with no value is an indeterminate
    `progressbar` (MDN), and ARIA's `progressbar` without
    `aria-valuenow` is one (WAI-ARIA 1.2); Flutter has neither for a
    spinner. Chromium's own node for Material's spinner is "generic", not
    ignored, with no children (`probes/c26/web-spinner-ax.txt`).
  - VoiceOver on the web, moving on with `next` from the button while the
    spinner loads (C26 `bad-no-role` and `bad-cupertino-no-role`; three
    recordings, all measured: at 7b9dc5c and 9f40ddc, `probes/c26/
    voiceover-web-round3-fail.md.txt` and `-round4-fail.md.txt`, and at
    4323aae, the transcript, `docs/evidence/C26/voiceover-web.md`, which
    passed):
    - WebKit (Playwright's build, not Safari itself): Material's spinner
      "Loading inbox empty group", in all three. The name, then
      "group", as VoiceOver says for [FL-028](#fl-028)'s slider wrapper, the other
      named element with no role in this project's transcripts ("Volume
      group", both browsers, `docs/evidence/F10/voiceover-web.md`): a
      measured comparison, not VoiceOver's documented reason. The spinner
      has no children; the slider wrapper has one and was read with no
      "empty". Neither word says it is a progress or busy indicator.
      Cupertino's spinner, plain text, "Loading inbox".
    - Chromium: Cupertino's spinner "Loading inbox", in all three.
      Material's spinner was not read in any of them. In the two that read
      the cursor's place (9f40ddc and 4323aae), `next` went from the button
      (top 343) to the status line below the spinner (top 439, "Loading
      started"), where Cupertino's spinner in the same browser was read at
      top 387, between them; the one at 7b9dc5c heard the same words and
      read no place. Not tried: VoiceOver's other ways of moving (the
      rotor, item by item within a group, the mouse), and real Safari or
      Chrome. No cause is claimed: the tree probe above, a node that is not
      ignored, is evidence of what Chromium exposes, not of why VoiceOver
      passes over it. A search of this log and of the web VoiceOver
      transcripts found no other named element with no role that
      VoiceOver in Chromium passed over: [FL-028](#fl-028)'s slider
      wrapper, which has a child, is a stop in Chromium. Two passings-over
      found are other shapes: [FL-262](#fl-262)'s button inside C18's
      `<h3>`, a button with a role inside a heading that has a label of its
      own; and F09 `bad-tile-not-merged`'s switch, which has a role and no
      name.
  - Android 17: an `android.view.View` with the name as its description
    (`android-tree.txt`); TalkBack read the name alone, with no role word
    (`android-talkback.md`). A determinate indicator is an
    `android.widget.ProgressBar`, which TalkBack calls "Progress bar".
  - iOS 27.0: a determinate indicator and a spinner are both a static
    text element (`ios.txt`: type 48), and VoiceOver read the name and
    the value with no role word ("p01 Upload 40", "p05 Loading"). Engine
    source read: `SemanticsObject.mm` gives no trait for either role.
    What VoiceOver says for a UIKit progress view or activity indicator
    was not measured.
- WCAG: 4.1.2 Name, Role, Value, where the indicator is taken to be a
  user interface component (C26's spec, section 3): the role is not
  programmatically determinable for a spinner on any platform, nor for a
  bar on iOS.
- A further consequence, on the web: with no role, Material's named
  spinner is a `generic` element with no children, and VoiceOver's next
  in Chromium passed over it (above), so a VoiceOver user moving through
  the screen in Chromium does not hear that something is loading at all,
  only the status line. It is the same failure, 4.1.2's role; no other
  criterion is claimed from it, and its cause is not known.
- Workaround: none in the SDK. `Semantics(role:
  SemanticsRole.progressBar)` without a numeric value fails the
  framework's own check ([FL-258](#fl-258)), so it cannot stand for a
  spinner. On the web, an HTML `progress` element embedded with
  `HtmlElementView` might carry the role (D31, D32); not tried.
- How to read this entry: a role Flutter has not added yet on these
  platforms. By the owner's decision of 2026-11-23, a platform where
  Flutter gives no role and no documented parameter adds one is a
  limitation, with no good example for it: C26 records iOS as
  `PlatformStatus.limitation` for its bar, and has no good spinner
  example on any platform. Its spinners, Material's and Cupertino's, are
  bad examples of this entry (`bad-no-role`, `bad-cupertino-no-role`),
  asserted on every layer and written to fail when Flutter adds the role:
  the tree tests (no role on the web, a plain `View` on Android, static
  text on iOS), the TalkBack transcript (the spinner read by its name with
  no role word), the iOS VoiceOver transcript ("Loading inbox" alone), and
  the web VoiceOver spec, which moves on from the button while each
  spinner loads and requires what was measured for that browser
  (`SPINNER_READINGS` in `web_tests/vo/c26_vo_walks.js`): the reading,
  exactly, with its name and no word that says it is an indicator, in
  WebKit for both spinners and in Chromium for Cupertino's; and in Chromium
  for Material's, a move that passes over the spinner to the status line,
  which fails if the spinner is ever read (C26's spec, section 7).
  The spinners' measurements in the C26 probe (p05, p08, p14, p20 to p22)
  are this entry's evidence as well.
- Upstream issue: not searched yet (D25).

## FL-257

**`CircularProgressIndicator.adaptive` drops its label, and all its semantics, where the theme's platform is iOS or macOS, which includes a browser on a Mac.**

- Status: Confirmed, Flutter 3.47.5. The documentation says its
  `semanticsLabel` and `semanticsValue` "will be ignored on iOS & macOS"
  (source read: `material/progress_indicator.dart`: it builds a
  `CupertinoActivityIndicator` there, which has no semantics,
  [FL-255](#fl-255)). Measured in the C26 probe (p09, p10): the widget
  tests as iOS and macOS, no label, role, or value; iOS 27.0, an element
  with nothing in it, passed over by VoiceOver; the web in Chromium on a
  Mac, an element with no name or role, because Flutter takes the
  platform from `navigator.platform` ("MacIntel" gives macOS). On Android
  it is Material's spinner, named, with no role, as every spinner
  ([FL-256](#fl-256)).
- WCAG: 4.1.2 Name, Role, Value, as C26's spec reads it, on iOS and in a
  browser on a Mac.
- What it means: a label that looks set in the code reaches no screen
  reader on an iPhone, and on the web only in browsers that are not on a
  Mac.
- Workaround: use `CircularProgressIndicator` (not adaptive), or name a
  `CupertinoActivityIndicator` with `Semantics(label:)` as C26
  `bad-cupertino-no-role` does, which gives a name but no role
  ([FL-256](#fl-256)). Asserted by C26 `bad-adaptive` on every layer,
  with a named spinner as the positive control in the same launch.
- Upstream issue: not searched yet (D25).

## FL-258

**A progress indicator's `semanticsValue` that is not a number or a percentage fails the framework's own check, and in a debug build no semantics are sent for the screen.**

- Status: Confirmed, Flutter 3.47.5. Source read:
  `semantics/semantics.dart`, `_semanticsProgressBar`: a node with the
  progress bar role must have a value, a minimum, and a maximum, and the
  value must parse as a number or a number with "%". Measured in the C26
  probe with `semanticsValue: '2 of 5 files'` (p04): the widget tests
  threw "Progress bar value, minValue, and maxValue must be valid
  numbers" in every frame (`flutter_test_p04.txt`); on Android 17 and on
  iOS 27.0 (debug builds) the screen's elements never reached the
  accessibility tree (`android-tree.txt`, `ios.txt`: p04 did not open).
  In the probe's first iOS round no fixture's elements were found at all
  (`ios-round1.txt`): a start by URL builds the probe's `/` route first,
  which then listed every fixture, p04 among them. With `/` listing none,
  the second round found them. That p04's check caused the first round's
  failure is inferred from that change alone. In the web's release
  build the bar had `aria-valuetext="2 of 5 files"` and no
  `aria-valuenow`. A release build on Android or iOS was not measured.
- What it means: the documentation says `semanticsValue` "may be used for
  determinate progress indicators to indicate how much progress has been
  made", and nothing says it must be a number; a value in words, such as
  "2 of 5 files", is not allowed. The documentation also says the
  default value is the percentage, "`0.1` will become '10%'"; the code
  gives "10", with no percent sign (C26's probe, every platform).
- Workaround: a number or a percentage as the value, and words, where
  needed, in a status line or the label.
- Upstream issue: not searched yet (D25).

## FL-259

**On the web a node whose role changes loses its test identifier.**

- Status: Observed, Flutter 3.47.5, web (Chromium); engine source read.
  In the C26 probe's first web round (`web-round1.txt`), a
  `Semantics(identifier:)` round an indicator that went from
  indeterminate (no role on the web) to determinate (`progressbar`), and
  then to text, had no `flt-semantics-identifier` from the first change
  on, while Chromium's tree had the element; the status lines, whose role
  never changed, kept theirs. In the second round, with the bar
  determinate from the start, the identifier stayed through every value
  (`web.txt`, p17 to p19) and went when the bar was replaced by text.
  Engine source read: `semantics/semantics.dart`, `SemanticRole.update`
  writes the identifier only when it has changed, and a role change makes
  a new element.
- What it means: a test, or anything else, that finds an element by its
  identifier loses it when its role changes, with the same identifier
  still on the node. Not an accessibility fault; a surprise for tests.
  Android and iOS were not checked for it.
- Workaround: keep a node's role fixed while it has an identifier; C26's
  bars are determinate from the start.
- Upstream issue: not searched yet (D25).

## FL-260

**On iOS `expanded` has no effect: VoiceOver says no expanded or collapsed state.**

- Status: Confirmed, Flutter 3.47.5, iOS 27.0 simulator. Found in the C05
  probe (`docs/evidence/probes/c05/`, fixtures p07 to p11 and p13 to p18
  have `Semantics(expanded:)`) and asserted by C05's VoiceOver walk on iOS
  (`bad-no-state` against the good examples; see below). Engine source read
  at the pinned revision: nothing under
  `engine/src/flutter/shell/platform/darwin/ios/framework/` reads the
  expanded flag, and the engine never sets UIKit's
  `accessibilityExpandedStatus` (iOS 18 and later, in
  `UIAccessibility.h` of the iOS 27.1 SDK).
- WCAG: 4.1.2 Name, Role, Value, on iOS: with `expanded` alone the state
  cannot be programmatically determined there.
- What happens: `Semantics(button: true, expanded: false)` and the same
  node expanded read alike: "p07 Shipping Button", closed and open (probe
  `ios.txt`, p07, p09 to p11, p13, p14, p16 to p18). XCUITest shows no value
  and no selected state for it. After XCUITest's double tap at the header
  opened it (a tap at its place with VoiceOver on, not VoiceOver's own
  activation, which XCUIVoiceOverService cannot make: C04 probe round 3),
  VoiceOver said nothing more in the three seconds read (nor for UIKit's own
  buttons, below), and moving on read the panel.
  So a VoiceOver user cannot tell whether a section is open.
- Native comparison (probe, `testNative`): a UIKit button with
  `accessibilityExpandedStatus` is read "n01 Shipping Button Collapsed
  Double-tap to expand", and once a tap has opened it "n01 Shipping Button
  Expanded Double-tap to collapse"; with the header trait added, "n02
  Shipping Button Heading Collapsed Double-tap to expand"; SwiftUI's
  `DisclosureGroup`, which the iOS reference uses, "n03 Shipping Button
  Collapsed Double-tap to expand" (`ios.txt`, `testNative`). So iOS has a
  state for this, which VoiceOver reads, and Flutter does not set it.
- Workaround, in the SDK, with no source (of this project's own design;
  not in APG, the reference repositories, or Flutter's documentation).
  Custom solution: not vetted by a real-world example (C05's spec, "Custom solutions"). On iOS only, put the state in the header's value
  as well: `value: open ? 'expanded' : 'collapsed'` when
  `defaultTargetPlatform == TargetPlatform.iOS` and not on the web
  (C05 `iosStateValue`). VoiceOver then says "p12 Shipping collapsed Button" (probe
  p12), the state between the name and the role, where UIKit's own status
  comes after the role and adds a hint; C05's good examples are read
  "Shipping collapsed Button Heading" (`docs/evidence/C05/voiceover-ios.md`). The value is not given elsewhere:
  on Android it is put before the name in the content description
  ("collapsed, p12 Shipping", probe p12), and on the web it is added to
  the name ("p12 Shipping collapsed", [FL-037](#fl-037)), each beside the
  expanded state the platform already reads.
- How to read this entry: Flutter has not passed the expanded state to
  iOS yet. Re-check when the pinned version changes.
- Upstream issue: not searched yet (D25).

## FL-261

**On Android the expanded state reaches only Android 16 and later.**

- Status: Confirmed (source read), Flutter 3.47.5. Measured on Android 17
  only: there it works (below). Below Android 16 it was not measured; the
  local emulator is Android 17, and the only Android 15 device is CI's
  emulator, where C05's Android tests take the other branch and assert
  that the node has no expand or collapse action. Engine source read:
  `BaseRoleConfigurator.java` (`configureExpanded`) sets the expanded state
  and adds `ACTION_EXPAND` and `ACTION_COLLAPSE` only when
  `Build.VERSION.SDK_INT >= API_LEVELS.API_36`, and
  `AccessibilityBridge.java` sends the expanded content change event under
  the same test.
- WCAG: 4.1.2 Name, Role, Value, on Android before 16 (source read, not
  measured): the state cannot be programmatically determined there.
- What happens on Android 17 (C05 probe and tests): a node with
  `Semantics(button: true, expanded:)` is a `Button` whose expanded state
  is "collapsed" or "full". TalkBack 17 says "collapsed." before the name
  ("collapsed. p07 Shipping / Button / Double-tap to activate"), and, when
  a click opens it with focus left on it, "fully expanded" (probe
  `android-talkback.md`, p07 to p18). `ACTION_EXPAND` and
  `ACTION_COLLAPSE` are on the node only when `onExpand` or `onCollapse`
  is set (p10: TalkBack then adds "Actions available"), and each opened
  and closed the section in the probe.
- Native comparison: the Android View reference marks a header with
  `ACTION_EXPAND` and `ACTION_COLLAPSE`, which exist on every version.
  In the C05 probe (`android-tree-native.txt`, `android-talkback-native.md`)
  a native `Button` with only those actions (n01) had no expanded state,
  and TalkBack 17 read it "Double-tap to activate. Actions available, use
  Tap with 3 fingers to view", with no state word (the name was not in the
  capture); one that also sets `setExpandedState` (n02, Android 16 and
  later) has the state "collapsed", then "full", as Flutter's node does.
  What TalkBack says for n02 was not captured: the walk could not move
  focus back to n01 after its click and stopped.
- What is left before Android 16: no state at all. The good examples set
  `onTapHint: open ? 'collapse' : 'expand'`, which makes TalkBack say
  "Double-tap to expand" or "to collapse" (heard on Android 17, probe p13),
  as the Android Compose reference does with `onClickLabel`. The engine
  gives the click action that label on every version
  (`BaseRoleConfigurator.java`, `configureTappable`, source read); what
  TalkBack says for it before Android 16 was not measured. That says what a
  double tap does, which implies the state; it is not the state, and no
  SDK way to give the state on those versions was found: `value` would be
  read on every version, so on Android 16 and later beside the state.
- How to read this entry: Flutter has not passed the expanded state to
  Android before 16 yet.
- Upstream issue: not searched yet (D25).

## FL-262

**On the web a heading is never a button: a node with a heading level and a button flag is a heading only, with no `aria-expanded` and no button role.**

- Status: Confirmed, Flutter 3.47.5, Chromium. Found in the C05 probe
  (`docs/evidence/probes/c05/web.txt`, fixtures p03 and p08) and asserted
  by C05 `bad-heading-on-button` in `web_tests/c05_accordion.spec.js`,
  written to fail when the header is a button. Web engine source read:
  `semantics.dart` (`_getEngineSemanticsRole` returns the heading role
  before the button role is looked at) and `heading.dart` (the heading
  role is built with `SemanticRole.blank`, so it adds none of the
  behaviours a button has, and not the one that writes `aria-expanded`).
- What happens: `Semantics(headingLevel: 3, button: true, expanded: false)`
  on one node is `<h3 tabindex="0">Shipping</h3>`: Chromium's tree has a
  heading of level 3, focusable, and no button and no expanded state. Tab
  still reaches it, and Enter, Space, and a click still open the section
  (p08). An `ExpansionTile`
  with its title in `Semantics(headingLevel: 3)` is the same (p03), with
  its hint as `aria-description`.
- On Android and iOS the same node is a heading and a button at once:
  `Button` with `isHeading` true, and TalkBack says "Button. Heading"
  (p08). On iOS VoiceOver says "p08 Shipping Button Heading".
- WCAG: 4.1.2 Name, Role, Value, on the web: the header's role and state
  cannot be programmatically determined.
- Workaround, in the SDK: on the web, a heading node of its own that holds
  the button's node, as APG's markup is:
  `Semantics(headingLevel: 3, container: true, child: <the button>)` gives
  `<h3><flt-semantics role="button" aria-expanded="false">Shipping</flt-semantics></h3>`,
  which Chromium reads as the APG markup in plain HTML (probe p09, and the
  plain HTML comparison in `web.txt`). Off the web keep the heading on the
  button's node: on Android the outer node of p09 is a heading with no name
  and the button is not a heading (`android-tree.txt`), and on iOS
  VoiceOver says "p09 Shipping Button", with no "Heading" (`ios.txt`).
  C05's good examples do both, by `kIsWeb` (`HeaderSemantics`). Custom solution: not vetted by a real-world example (C05's spec, "Custom solutions").
- Also seen in C18 (2026-11-22), the same mechanism from a heading merged
  into a control, and for a link as well as a button. Asserted by C18
  `bad-heading-button` in `web_tests/c18_card.spec.js`; found in the C18
  probe (`docs/evidence/probes/c18/web.txt` and `web_round2.txt`, fixtures
  p03, p04, p06, p07, p09, p18, p19). The engine's order (source read) puts
  the heading role before a text field, a checkable node, and a link as
  well; a checkbox or a text field merged with a heading was not built, so
  for those it is read in the source only. `Semantics(headingLevel: 3)`
  round the title of a control that merges its children puts the level on
  the control's node, which becomes an `<h3 tabindex="0">` named by
  everything merged into it:
  - A `ListTile` with `onTap` (p06, `bad-heading-button`): Tab reaches it,
    and Enter, Space, and a mouse click (16 pixels in from its left edge in
    the probe) run its `onTap`; a DOM click with no pointer events, which
    is what assistive technology sends, runs nothing (`web_round2.txt`; the C18 web test, with a mouse click on the
    same element and a DOM click on Back in the same load as positive
    controls). VoiceOver read it as "heading level 3 Ridge trail A 6 km
    climb with a view.", with no "button", in Chromium and WebKit
    (`docs/evidence/C18/voiceover-web.md`). What VoiceOver's own
    activation sends was not measured.
  - A card that is one link, `Semantics(link: true, linkUrl:)` round an
    `InkWell` whose text has a heading (p09): an `<h3>` with no `href`, so
    the browser has no link to follow, and neither Enter nor Space after
    Tab ran anything there (C03's `BrowserKeys` gives both to the browser).
    A mouse click 16 pixels in from its left edge ran the card's handler,
    which on the web leaves following the link to the browser, so nothing
    opened. A DOM click ran nothing.
  - `Semantics(button: true)` round an `InkWell` card, [FL-401](#fl-401)'s
    own workaround (p19): an `<h3>`; Enter, Space, and the mouse click ran
    its handler, a DOM click nothing.
  - `MergeSemantics` round a card with one button (p18; the project's
    `TestId` is one): an `<h3>` named by the title, the text, and the
    button; Enter and Space ran the button's handler, the merged node's one
    action; the mouse click 16 pixels in from its left edge, at mid height,
    and a DOM click ran nothing (a click where the button is drawn was not
    tried).
  - Off the web the `ListTile` (p06), the `Semantics(button: true)` card
    (p19), the merged card (p18), and the link card (p09) keep both: on
    Android a `Button` (for p09 a `View` with the link's `URLSpan`) whose
    `isHeading` is true (`android-tree.txt`); on iOS a button (for p09 a
    link) to XCUITest (`ios.txt`). The `InkWell` cards with a heading (p03,
    p04) have no button role off the web ([FL-401](#fl-401)): on Android a
    clickable `View` that is a heading, on iOS an element of type other. For C18
    `bad-heading-button` VoiceOver reads "Ridge trail A 6 km climb with a
    view. Button Heading" (`docs/evidence/C18/voiceover-ios.md`) and
    TalkBack "… / Button. Heading" (`docs/evidence/C18/talkback-android.md`).
  - Plain HTML (`web.txt`, "html"): a `div` with `role="button"` round an
    `h3` and a `p`, and an `a href` round them, are a button and a link in
    Chromium's tree with the heading inside them.
  - C18's way round it: no heading inside a control. A card that is one
    control has no heading of its own (C18 `good-tappable`). The workaround
    above, a heading node holding the button's node, was not tried for a
    card. A related reading: VoiceOver's next did not stop on a button
    inside C18 `bad-default-container`'s `<h3>`, which has the card's text
    as its label ([FL-269](#fl-269)), where C05's good examples, whose
    `<h3>` has no label of its own, are read as one stop with the button
    ("heading level 3 Shipping collapsed button",
    `docs/evidence/C05/voiceover-web.md`). Why they differ was not measured.
- How to read this entry: Flutter has not given a heading node the
  behaviours of a button on the web yet.
- Upstream issue: not searched yet (D25).

## FL-263

**A panel hidden with `Offstage` is out of the semantics tree, but its controls keep keyboard focus; `Expansible` and `CupertinoExpansionTile` hide closed panels that way by default, and `ExpansionTile` does with `maintainState: true`.**

- Status: Confirmed, Flutter 3.47.5, in widget tests, on the web, on
  Android 17, and on iOS 27.0. Found in the C05 probe (fixtures p02,
  `ExpansionTile(maintainState: true)`, and p14, `Expansible`;
  `probe_test.txt`, `web.txt`, `android-keys.txt`) and asserted by C05
  `bad-hidden-panel` in the widget, web, Android, and iOS tests (on iOS,
  `testBadHiddenPanelTabGoesToAHiddenButton`: four Tabs and Enter press a
  hidden button). Framework source read:
  `widgets/basic.dart` documents that "Offstage children are still active:
  they can receive focus and have keyboard input"; `RenderOffstage` paints
  nothing and gives no semantics while offstage
  (`rendering/proxy_box.dart`); `Expansible` builds a closed body as
  `Offstage(offstage: true, child: TickerMode(...))` unless
  `maintainState` is false (`widgets/expansible.dart`), and its
  `maintainState` defaults to true; `ExpansionTile` passes its own
  `maintainState`, false by default; `CupertinoExpansionTile` builds an
  `Expansible` and does not set it (`cupertino/expansion_tile.dart`).
- What happens: Tab moves keyboard focus to the closed panel's buttons,
  which are not drawn and have no semantics node. Tab reaches them after
  both headers, not after their own (why was not looked into). In the
  widget tests no node has focus while it is there; on Android the tree
  goes on reporting the last header as focused (probe `android-keys.txt`,
  p02 and p14), and on the web the page's focus stays on that header. Enter there
  presses the hidden button (C05's count goes up while every section stays
  closed).
- WCAG, as written: 4.1.2 Name, Role, Value: a control that takes
  keyboard focus and is operated by Enter has no name or role a screen
  reader can read. 2.4.7 Focus Visible is not claimed: the tests show focus
  on a control with no node, not that no focus indicator is visible (that
  nothing is drawn is from the source, `RenderOffstage` paints nothing; no
  screenshot was taken). 2.4.3 Focus Order is not claimed: the order of the
  visible stops is kept.
- Workaround, in the SDK: pass `maintainState: false` to `Expansible`
  (its documented parameter; not measured), or build a closed panel not at
  all, as C05's good examples do (`if (open) panel`; a custom solution, not vetted by a real-world
  example: C05's spec, "Custom solutions"). Keeping a hidden panel's state while taking its controls
  out of the focus order, for example with `ExcludeFocus`, was not tried.
- Upstream issue: not searched yet (D25).

## FL-264

**`ExpansionTile`'s header has no expanded state, and on Android and iOS no button role unless `internalAddSemanticForOnTap`, "a temporary flag", is set; the state is a hint.**

- Status: Confirmed, Flutter 3.47.5, all platforms. Found in the C05
  probe (fixture p01) and asserted by C05 `bad-expansion-tile` in the
  widget, web, Android, and iOS tests and heard in its transcripts.
  Framework source read: `material/expansion_tile.dart` builds its header
  as a `ListTile` with `internalAddSemanticForOnTap: false` (the
  parameter's default on `ExpansionTile`, documented as "a temporary
  flag"), so the header has no button flag; it sets no `expanded`; it
  puts "Collapsed" or "Expanded" (`MaterialLocalizations.expandedHint` and
  `collapsedHint`) in the header's hint, with "double tap to expand" or
  "to collapse" after it when `defaultTargetPlatform` is iOS or macOS
  (which it is in a browser on a Mac); on Android it wraps the header in a
  live region whose label is the same word, to announce the change; on
  iOS and the web it announces the change with `sendAnnouncement`.
- What each platform gets (probe and C05 tests):
  - Android: `android.view.View`, not a button, named "Shipping,
    Collapsed" (the hint at the end of the name, [FL-039](#fl-039)), click
    label "Expand for more details" or "Collapse". TalkBack: "Shipping, /
    Collapsed / Double-tap to Expand for more details", and "Expanded"
    when a click opens it.
  - iOS: static text to XCUITest. VoiceOver: "p01 Shipping Collapsed double tap to expand",
    the state as a hint with no role, and "Expanded" after XCUITest's
    double tap at the header opened it (the announcement; the gesture is a
    tap at its place, not VoiceOver's activation).
  - Web: `role="button"` ([FL-006](#fl-006)) with no `aria-expanded`;
    the state is its `aria-description`, which depends on the platform
    Flutter's engine finds from the browser's `navigator.platform`
    (`detectOperatingSystem`, ui_web's `browser_detection.dart`; source
    read). On macOS it is "Collapsed" and "double tap to expand"
    (accessible description "Collapsed double tap to expand", Chromium);
    on Linux and Windows "Collapsed" alone (C05's web tests, with
    `navigator.platform` set in the page; on a real Linux browser, CI's
    Chromium, the earlier test that the description starts "Collapsed"
    passed). VoiceOver on macOS reads it "Shipping Collapsed double tap to
    expand button", in Chromium and WebKit
    (`docs/evidence/probes/c05/voiceover-web-round1-fail.md.txt`): the
    state in words, phrased as a touch instruction on a desktop browser.
    In a browser on Android the source adds a live region; not
    measured.
- With `internalAddSemanticForOnTap: true`, and nothing else added (C06
  probe fixture d02, `docs/evidence/probes/c06/`, and C06 `good-material`
  in the widget, web, Android, and iOS tests and its transcripts): the
  header is a button on Android (`android.widget.Button`, "Details,
  Collapsed"; TalkBack adds "Button") and iOS (a button to XCUITest;
  VoiceOver "Details Button Collapsed double tap to expand", after
  "Button" where UIKit's own expanded status also comes, but as the tile's
  hint: XCUITest shows no value), and on the web as before. Nothing else
  that was measured changes: still no expanded state on Android 17, iOS
  27.0, or Chromium; the same hint; the same live region on Android; and
  the change still announced: "Expanded" from TalkBack on the click, and
  "Collapsed" on a second (Android 17, the live region); "Expanded" from
  VoiceOver on iOS after XCUITest's double tap opened it (iOS 27.0;
  closing was not listened for; the widget tests show the one-second
  timer); and "Expanded" and "Collapsed" written to Flutter's
  `flt-announcement-polite` element on a click, Enter, and Space (C06's
  web tests, Chromium). The parameter is documented as "a temporary flag
  to help changing the behavior of ListTile onTap semantics", with a note
  in the source to remove it once its default is flipped to true.
- WCAG: 4.1.2 Name, Role, Value. As it comes, on Android and iOS: no role
  that says it is a control. For the state, on every platform: no
  expanded state is exposed (no `aria-expanded` on the web, no expanded
  state on Android, none on iOS); the state is only text a screen reader
  reads, in the name on Android, the hint on iOS, and the accessible
  description on the web. The owner decided on 2026-11-23, for C06, that
  this text is not counted as meeting 4.1.2, so the state fails 4.1.2 on
  every platform, with or without `internalAddSemanticForOnTap`.
- Closest achievable example: none with `ExpansionTile`'s own parameters
  alone. C05 `good-material` builds the header from a `ListTile` inside
  `Semantics(button: true, expanded:)` and builds the panel only while it
  is open. Custom solution: not vetted by a real-world example (C05's spec, "Custom solutions"). `ExpansionTile(internalAddSemanticForOnTap:
  true)` with its title in `Semantics(expanded:)` gives a button with the
  state (probe p15), but keeps the hint and the live region, so the state
  is said twice ("Expanded / fully expanded" from TalkBack), and relies on
  a parameter the source calls temporary; it is not used. C06
  `good-material` is `ExpansionTile(internalAddSemanticForOnTap: true)`
  through its own parameters, with this entry's missing state recorded as
  a limitation on all three platforms; it is not a custom solution.
- How to read this entry: Flutter has not given `ExpansionTile` an
  expanded state, or a button role by default, yet.
- Upstream issue: not searched yet (D25).

## FL-265

**`CupertinoExpansionTile`'s header takes no keyboard focus, is no button, and has no expanded state; once open, the panel's text joins its name.**

- Status: Confirmed, Flutter 3.47.5. Found in the C05 probe (fixture p06)
  and asserted by C05 `bad-cupertino-expansion-tile` in the widget, web,
  Android, and iOS tests. Framework source read:
  `cupertino/expansion_tile.dart` builds the header as a
  `CupertinoListTile` with `onTap` inside `Semantics(hint:, onTapHint:)`,
  the hint only when `defaultTargetPlatform` is iOS or macOS (on the web,
  as Flutter's engine finds it from the browser's `navigator.platform`);
  a `CupertinoListTile` takes no focus and
  is no button ([FL-400](#fl-400), the same mechanism).
- What happens:
  - No keyboard focus, on every platform: Tab passes the headers (the
    widget tests, the web, Android, iOS), so a keyboard cannot open a
    section. WCAG 2.1.1 Keyboard: no other keyboard path opens it.
  - No button role on Android (`android.view.View`) and iOS (static text);
    a button on the web ([FL-006](#fl-006)), with no `tabindex`.
  - No expanded state. On Android nothing says the state. On iOS the hint
    is "Collapsed double tap to expand" (VoiceOver, probe p06). On the web,
    where Flutter's engine finds macOS, the same hint is the header's
    accessible description (C05's web tests), which VoiceOver on macOS
    reads "Shipping Collapsed double tap to expand button", in Chromium
    and WebKit (`docs/evidence/probes/c05/voiceover-web-round1-fail.md.txt`):
    the state in words, phrased as a touch instruction on a desktop
    browser. On Linux and Windows the header has no description and no
    `aria-description`, so nothing gives its state (C05's web tests, with
    `navigator.platform` set in the page; on a real Linux browser, CI's
    Chromium, the earlier test that expected a description received an
    empty one, `docs/evidence/probes/c05/web-platforms.txt`). Nothing
    announces the change.
  - Once a section is open, its panel's text is merged into the header's
    node: "Shipping\nOrders ship in two days." on Android; on the web a
    group named "Shipping p06 Shipping panel" in the probe (p06, whose
    panel has a button), and in C05's example, whose panel is text only, a
    button named "Shipping Orders ship in two days." (C05's web tests).
  - Once a section has been opened, an empty element the size of the view
    lies over the page on the web and takes pointer events
    ([FL-029](#fl-029), extended).
  - Its closed panel is `Offstage` and keeps keyboard focus
    ([FL-263](#fl-263)); C05's example has no button in it, so that this
    is not a second defect there.
- WCAG, for what is not C05's named defect (2.1.1, above): 4.1.2 Name,
  Role, Value. On Android and iOS no role that says it is a control. For
  the state: where nothing gives it (Android; the web on Linux and
  Windows), it fails as written; where it is only a hint (iOS; the web on
  macOS), it fails too, by the owner's ruling of 2026-11-23 (C06) that a
  state given only as text does not meet 4.1.2.
- Closest achievable example: none with `CupertinoExpansionTile`'s own
  parameters. C05 `good-cupertino` builds the header from a
  `CupertinoListTile` given focus by `FocusableActionDetector`, inside
  `Semantics(button: true, expanded:)`, with the panel built only while
  open. Custom solution: not vetted by a real-world example (C05's spec, "Custom solutions").
- How to read this entry: Flutter has not given `CupertinoExpansionTile`
  keyboard focus, a button role, or an expanded state yet.
- Upstream issue: not searched yet (D25).

## FL-266

**On the web `controlsNodes` becomes `aria-controls` only if the controlled node is there when `controlsNodes` is set.**

- Status: Confirmed, Flutter 3.47.5, Chromium, in the C05 probe
  (`web.txt`, fixtures p11, p17, p18); the workaround is asserted by
  C05's web tests. Web engine source read: `semantics.dart`
  (`_updateControls`), which looks the identifiers up once, after the
  update in which `controlsNodes` changed.
- What happens: a header with `controlsNodes: {'p11-Shipping-panel'}` set
  all along, whose panel is built only once it is opened, has no
  `aria-controls` before or after it opens (p11). With the panel open from
  the start, `aria-controls` names the panel's element, and is kept after
  the panel is gone (p17). Android and iOS do not read `controlsNodes`
  (engine source: neither embedding refers to it).
- WCAG: none failed as written. APG's accordion pattern requires
  `aria-controls`; 1.3.1 and 4.1.2 are met by the panel coming straight
  after its header.
- Workaround, in the SDK, with no source (of this project's own design).
  Custom solution: not vetted by a real-world example (C05's spec, "Custom solutions"). Set `controlsNodes` only while the panel is
  open, so it changes in the update that builds the panel:
  `controlsNodes: open ? {panelId} : null` (p18; C05 `controls`). Then
  `aria-controls` names the open panel and is gone while it is closed.
- Upstream issue: not searched yet (D25).

## FL-267

**`ExpansionPanelList`'s expand buttons are named "Expand" or "Collapse" whatever their panel, and have no expanded state; an `ExpandIcon` on its own has no state in any words.**

- Status, for `ExpansionPanelList`: Observed, Flutter 3.47.5, in the C05
  probe only (fixtures p04 and p05); no C05 example uses it. For
  `ExpandIcon` on its own: Confirmed, below. Framework source read:
  `material/expansion_panel.dart` and `material/expand_icon.dart`.
- What happens, with `canTapOnHeader` false (the default, p04): the header
  is text, and a separate `ExpandIcon`, an `IconButton`, opens it. That
  button is wrapped in `Semantics(label: 'Expand', container: true)`:
  on Android a node "Expand" holding a `Button` with no name; on the web
  a button with no name; on iOS "Expand" and then "Button", two stops after the
  header's text (VoiceOver, p04). Each panel's button reads
  the same, so nothing says which section it opens. No node has an
  expanded state. With `canTapOnHeader` true (p05) the header is one
  button, named by the header ("p05 Shipping", click label "Expand"), but
  the `ExpandIcon` inside it still takes keyboard focus: Tab stops twice on
  each header (widget tests, web).
- `ExpandIcon` on its own, beside a `Text` and merged with it in a
  `MergeSemantics`, as its documentation says ("it should be combined
  with a label using MergeSemantics"): Confirmed, Flutter 3.47.5, in the
  C06 probe (fixture d03) and asserted by C06 `bad-expand-icon` in the
  widget, web, Android, and iOS tests and heard in its transcripts. One
  button named by the label ("Details"), with no expanded state, no hint,
  and no value, closed or open, and no live region (widget tests, Android
  17); in the probe nothing was written to Chromium's announcement
  elements when it opened or closed. On the web
  a `role="button"` with no `aria-expanded` and no description (Chromium,
  with `navigator.platform` set to macOS, Linux, and Windows); on Android
  an `android.widget.Button` "Details" whose click label is "Expand"
  ([FL-280](#fl-280): it stays "Expand" once open); on iOS a button with
  no value, which VoiceOver reads "Details Button", closed and open. In
  the widget tests its tap hint is "Expand", then "Collapse". Only the
  icon takes pointer input: a tap on the label opens nothing (widget
  tests, and on iOS XCUITest's tap at the element's middle); in Chromium a
  mouse click at the element's middle opens it, as the node's element
  takes the click ([FL-411](#fl-411)). So nothing says whether its panel
  is open, in any words.
- WCAG: for `ExpansionPanelList`, not judged: no C05 example uses it, and
  the probe alone does not test a whole screen built with it. For
  `ExpandIcon` on its own: 4.1.2 Name, Role, Value, on every platform: no
  state.
- Workaround: as for [FL-264](#fl-264).
- Upstream issue: not searched yet (D25).

## FL-269

**A `Card` left at its default joins all its text into one node, and a heading in it makes all of that one heading.**

- Status: Confirmed, Flutter 3.47.5: asserted by C18
  `bad-default-container` in the widget, web, Android, and iOS tests and
  its transcripts. Found in the C18 probe (`docs/evidence/probes/c18/`,
  fixtures p01 and p02). Framework source read: `material/card.dart`
  wraps the card in `Semantics(container: semanticContainer)` and its
  child in `Semantics(explicitChildNodes: !semanticContainer)`;
  `semanticContainer` is true by default.
- WCAG: 1.3.1 Info and Relationships, on every platform: the card's body
  text is exposed as part of its heading, which is not what is shown.
- What happens: with `semanticContainer: true` every text in the card that
  has no node of its own (a `Text` has none) is merged into the card's
  node, and so are their flags: a `Semantics(headingLevel: 3)` title
  makes the whole node a level 3 heading named "title\ntext". Controls and
  labelled pictures keep nodes of their own, as children of it.
  - Web: an `<h3>` whose `aria-label` is the title and the text, holding
    the picture (`role="img"`) and the buttons (`web.txt`, p01).
    VoiceOver on macOS, moving with `voiceOver.next()` in Chromium and in
    WebKit, read C18 `bad-default-container`'s `<h3>` as "heading level 3
    Ridge trail A 6 km climb with a view." and then went to the next
    element after the card, "Saves: 0": the "Save Ridge trail" button
    inside the heading was not a stop
    (`docs/evidence/probes/c18/voiceover-web-round1-fail.md.txt`, the
    first recording, and the same in the second,
    `docs/evidence/C18/voiceover-web.md`). Only `next` was tried; Tab with VoiceOver on, the
    rotor, and activating the button with VoiceOver were not. Why it was
    passed over was not found. Without a screen reader, Tab reaches the
    button and Enter and Space activate it (C18's web tree test).
  - Android: an `android.view.View` with `isHeading` true, named by the
    title and the text, with the picture and the buttons as its children
    (`android-tree.txt`, p01).
  - iOS: one element of type other (XCUITest's type for a heading here)
    named by the title and the text, with the picture and the buttons as
    elements of their own (`ios.txt`, p01). VoiceOver read the title and
    the text and then "H", cut at 64 characters, in the probe; for C18
    `bad-default-container` it reads "Ridge trail A 6 km climb with a
    view. Heading" (`docs/evidence/C18/voiceover-ios.md`), and TalkBack
    "… / Heading" (`docs/evidence/C18/talkback-android.md`).
  - With `semanticContainer: false` each part is a node of its own, and
    the title alone is the heading (p02, C18 `good-material`).
- Why it matters: the default is what a `Card` gets unless its author has
  read this parameter's documentation, which says it "should be false if
  the card contains multiple different types of content". A screen reader
  user hears the card's whole text as a heading, and a list of headings
  holds every card's text.
- Workaround, in the SDK: `Card(semanticContainer: false)`, as its
  documentation says (C18 `good-material`).
- Upstream issue: not searched yet (D25).

## FL-280

**On Android an `ExpandIcon` merged with its label keeps the click label "Expand" once it is open.**

- Status: Confirmed, Flutter 3.47.5, Android 17 (emulator); cause not
  found. Found in the C06 probe (fixture d03, `android-tree.txt` and
  `android-talkback.md`) and asserted by C06 `bad-expand-icon` in the
  Android tests (`badExpandIconHasNoStateInAnyWords`, which reads the
  label for two seconds after the click has opened it) and heard in its
  TalkBack transcript. Not measured below Android 17. Framework source
  read: `material/expand_icon.dart` sets `onTapHint` to "Expand" or
  "Collapse" (`collapsedIconTapHint`, `expandedIconTapHint`) from
  `isExpanded` on every build.
- What happens: `ExpandIcon` beside a `Text` in a `MergeSemantics`, as its
  documentation says: closed, the merged `Button` "Details" has the click
  label "Expand"; once its click has opened the panel, the click label is
  still "Expand", and TalkBack says "Details / Button / Double-tap to
  Expand" with the panel open. In the widget tests the same node's tap
  hint changes to "Collapse" and back (`probe_d03_test.txt`, and C06's
  widget test), so the framework's semantics change and Android's node
  does not show it; where it is lost was not found. `ExpansionTile`'s
  click label, also set with `onTapHint` but on a node that is not merged
  into a parent (source read), does change on the same device ("Expand for
  more details", then "Collapse").
- WCAG: not counted by itself: the example has no state at all
  ([FL-267](#fl-267)), which fails 4.1.2 whatever its click label says. A
  label that says what a double tap does, and says the wrong thing once
  open, adds to that.
- Workaround: none found with `ExpandIcon`'s own parameters. Not tried:
  leaving out the `MergeSemantics` (the button then has no name, as the
  documentation warns).
- How to read this entry: Flutter has not passed a changed tap hint on a
  merged node to Android yet, in this case.
- Upstream issue: not searched yet (D25).

## FL-290

**A SnackBar's time limit is the app's alone: a screen reader, Android's accessibility timeout, a pointer resting on it, and keyboard focus on its action do not change it.**

- Status: Confirmed, Flutter 3.47.5. Framework source read:
  `material/scaffold.dart`, `ScaffoldMessengerState.build`, starts a
  `Timer(snackBar.duration)` once the SnackBar has come in, and when it
  fires does nothing if `snackBar.persist` is true and hides the SnackBar
  otherwise; nothing else is read. `SnackBar`'s constructor sets `persist`
  to `action != null` when the app gives none. `accessibleNavigation` is
  read in `snack_bar.dart` and `scaffold.dart` only to leave out the
  animations and to hide at once (`docs/evidence/probes/c13/source_search.txt`).
  The Android embedding of the pinned engine has no call to
  `AccessibilityManager.getRecommendedTimeoutMillis`, which it does have
  for touch exploration, and `AccessibilityFeatures` has no timeout
  (the same file).
- What was measured, as the time from the show to the message's going
  (the probe's fixtures s01 to s08, `docs/evidence/probes/c13/`):
  - Widget tests, as Android, with `accessibleNavigation` off and on
    (`flutter_test.txt`): a SnackBar with no action went at 4.7 s and 4.4
    s (the entrance animation is left out when it is on); with an action
    and `persist: false`, the same; with an action and the default, still
    there at 15 s, off and on; `duration: 10 s` went at 10.7 s and 10.4 s;
    `accessibleNavigation` turned on while one was shown, and a mouse
    resting on it, changed nothing. Keyboard focus on the action did not
    keep it (4.6 s).
  - Web, Chromium (`web_round1.txt`, `web_round2.txt`): 4.26 s, 4.27 s
    with keyboard focus on its action, 10.26 s for 10 s.
  - iOS 27.0 simulator (`ios.txt`): 4.56 s with VoiceOver off, and with
    VoiceOver on 4.27 s, `accessibleNavigation` true; with an action and
    the default, still there 14 s later with VoiceOver on.
  - Android 17 emulator (`android-tree.txt`, `android-talkback-markers.txt`):
    4.29 s with no action and with an action and `persist: false`, 4.27 s
    and 4.28 s with TalkBack on; with an action and the default, still
    there 16 s later, and 14 s later with TalkBack on. With Android's two
    accessibility timeout settings ("Time to take action") at 60 s, set
    by the probe and put back after: 4.28 s, 4.29 s, 4.28 s, and 10.34 s for
    a `duration` of 10 s, unchanged. `accessibleNavigation` was true in
    every Android run, TalkBack off as well as on; why was not found.
- WCAG: 2.2.1 Timing Adjustable, where the message is the only means to
  some information or function (Understanding 2.2.1). Nothing in a
  SnackBar lets the user turn its time off, adjust it, or extend it, and
  nothing in the platform does either. A SnackBar with an action and the
  default `persist` sets no time limit on its action.
- The documentation says: "A SnackBar with an action will not time out
  when TalkBack or VoiceOver are enabled. This is controlled by
  AccessibilityFeatures.accessibleNavigation." As measured, a SnackBar
  with an action does not time out whether a screen reader is on or not,
  by `persist`'s default, and with `persist: false` it times out with
  VoiceOver on and with TalkBack on (above).
- What users get: a SnackBar whose action or news exists nowhere else
  goes after four seconds for everyone, screen reader users included,
  before a swipe at a time can reach it: on iOS, VoiceOver's cursor moved
  from the button that showed it reached the message of a SnackBar that
  stays after six moves, past the page's own lines (`ios.txt`, s02 and
  s05). The reference repositories' Android Compose entry says a native
  Snackbar follows Android's "Time to take action" setting; a Flutter one
  does not.
- Workaround, in the SDK: give a SnackBar with an action no
  `persist: false`, so that it stays (C13 `good-action`); put news that
  is needed on the page as well (C13 `good-message`); or use a
  `MaterialBanner`, which has no timer. A longer `duration` is a longer
  fixed time, not one the user sets.
- How to read this entry: a SnackBar is documented as brief; this is
  logged because its time is fixed by the app for every user, and the
  documentation's sentence about screen readers describes `persist`'s
  default, not a change made for them.
- Upstream issue: not searched yet (D25).

## FL-291

**Escape closes no SnackBar or MaterialBanner; Back pops the screen under it, and the message stays on the screen before.**

- Status: Confirmed, Flutter 3.47.5. First seen in the I08 probe (fixture
  `e12`): Escape did nothing to a SnackBar, and Back popped the screen.
  Measured in the C13 probe (`flutter_test.txt`, `web_round1.txt`,
  `web_round2.txt`) and asserted by the C13 widget, web, and Android
  tests "Escape with focus on Undo (or Go online) leaves the message;
  Enter there, in the same launch, acts". Framework source read: neither
  `SnackBar` nor `MaterialBanner` has an action for `DismissIntent`, and
  the `ScaffoldMessenger` sits above the `Navigator`, so a SnackBar is
  shown on whichever `Scaffold` is current (`scaffold.dart`, `_register`
  and `_updateScaffolds`).
- What happens:
  - Escape, with keyboard focus on the message's action, its Close
    button, or elsewhere, leaves the message, as Android (widget tests and
    the emulator) and on the web; Enter on the same action in the same
    launch acted. On iOS Escape was not sent (I08: it reaches Flutter
    only as Command+period, and not every time before iOS 27).
  - Back (`popRoute`, the widget tests) pops the screen, and the message
    moves to the screen under it. A SnackBar that stays, and a banner,
    stay there: still shown 15 s and 30 s later (the probe's s02, s05,
    s06; C13 `good-action` and `good-banner`, which also stay over the
    catalog after a second Back), and their action can still be used
    there, on a screen that is gone (in the probe it ran the app's
    callback; C13's examples make it change nothing and tell nothing
    then, as the example has gone). A timed one goes on its timer.
  - What does close one: its action, `showCloseIcon`'s Close button, a
    swipe down (a SnackBar only; `flutter_test.txt`), and the dismiss
    action that both put on their node (`Semantics(onDismiss:)`), which
    TalkBack's Dismiss action reaches. VoiceOver's escape gesture made
    inside the message reaches the same action (read in the source, FL-481);
    not measured.
- WCAG: none failed as written. A keyboard can leave the message (Tab)
  and reach a control that closes it, where the app gives one. A SnackBar
  that stays and has no Close button can be removed with a keyboard only
  by using its action; `good-action` has a Close button for this.
- Workaround, in the SDK: `showCloseIcon: true` on a SnackBar that stays;
  a `MaterialBanner`'s own action that hides it.
- Upstream issue: not searched yet (D25).

## FL-292

**When a SnackBar times out with keyboard focus on its action, focus goes back to the button that showed it on Android and the web, but to no control in widget tests, and once to the page for a floating one on the web.**

- Status: Confirmed, Flutter 3.47.5. Asserted, as measured on each, by
  the C13 tests of `bad-action-times-out` "with keyboard focus on Undo it
  still goes": the widget test (no node has focus, and the next Tab goes
  to Back), the web tree test (DOM focus on "Archive message"), and
  `C13SnackbarTest.badActionTimesOutGoesWithKeyboardFocusOnUndo` (the
  node with input focus is "Archive message"'s, on the local emulator at
  its own size and at CI's 320 by 640, `android_320x640.txt`). Measured
  in the probe on fixtures s03, s04, and s08.
- What happens, with keyboard focus on a SnackBar's action or its Close
  button when the SnackBar times out:
  - Android 17 emulator, C13's test: focus on the button that showed it.
  - Web, Chromium: DOM focus on that button, for a fixed SnackBar, in
    both probe rounds (`web_round1.txt`, `web_round2.txt`, s03 and s04)
    and in six runs of six of C13's tree test; the next Tab left
    Flutter's controls for the page's body. For a floating one (s08), on
    that button in round 1, and on the Flutter view in round 2, where the
    next Tab went to Back.
  - Widget tests, as Android (`flutter_test.txt`): no node has focus
    afterwards; the next Tab goes to Back, the first control of the
    screen. Why the widget tests differ from the emulator was not found.
  - iOS: not measured (the probe's key test matched the Back button's
    icon and never reached the action; XCUITest cannot read Flutter's
    focus).
  When the action is used, focus goes back to the button that showed the
  message (widget tests, web).
- WCAG: none failed as written. It is the time limit of
  [FL-290](#fl-290) seen from the keyboard: the control under focus goes.
- How to read this entry: logged because a test of a widget's keyboard
  behaviour in `flutter test` does not show what a device does here, and
  the web varied for a floating SnackBar.
- Workaround: none needed for the examples; a SnackBar that stays does
  not go from under focus (C13 `good-action`).
- Upstream issue: not searched yet (D25).

## FL-293

**A message shown while one that stays is up waits, unseen and unannounced, until that one is closed.**

- Status: Confirmed in the widget tests, Flutter 3.47.5: the C13 test
  "FL-293", and the probe (`flutter_test.txt`, "a second message while
  s02 (persists) is shown"). Framework source read:
  `ScaffoldMessengerState.showSnackBar` queues a SnackBar while one is
  shown, as its documentation says, and shows the next only when the
  first has gone.
- What happens: a SnackBar shown while one with an action is up (which
  stays, [FL-290](#fl-290)) is not on the screen and not in the tree 10 s
  later; when the first is closed it comes, and is announced then, as a
  live region.
- WCAG: none established. The waiting message is presented late, to
  everyone, and when it comes it is a live region, announced without
  focus: the measurement shows a delay in presentation, not a status
  message that cannot be programmatically determined, so it does not
  establish a 4.1.3 failure. It is logged as a queueing limitation: a
  message about a later action can wait behind one the user has not
  dealt with.
- The same queue with presses that come while a message is going out
  (C13 review, 2026-11-22; `docs/evidence/probes/c13/flutter_test_burst.txt`):
  with `hideCurrentSnackBar()` (or `hideCurrentMaterialBanner()`) before
  each show and the animations on, two or three presses inside the exit
  animation each hid the same message and queued a replacement; the
  first replacement stayed, and the next came when it was closed, or, for
  a banner, when Go online hid it, with the page saying online.
- The same queue with an outgoing message's action (C13 review,
  2026-11-23; `docs/evidence/probes/c13/flutter_test_outgoing_undo.txt`):
  with the animations on, a message going out still takes taps. Archive
  A, press again so that A goes out and B is queued, and press A's Undo
  during A's exit: A closes with the reason `action`, and B comes in. A
  confirmation shown then from A's `closed` future with `clearSnackBars()`
  took B, and its Undo, away, while the line still counted B's archive.
  C13 first counted the messages each example had shown; that missed
  the messages that outlive their example: across Back and a reopen, or
  across two examples, an old message's confirmation cleared a newer
  message (`flutter_test_outlive.txt`). C13 now counts the messages shown
  through each messenger (plain state beside it, an `Expando`), queues a
  confirmation behind any newer one instead of clearing, and tells it only
  for an action that changed its example while it was there. Those were
  the third and fourth fixes to one project-built mechanism (a fourth bug
  was an old banner's Go online, after Back and a reopen, clearing the new
  instance's banner); by the principal's decision in review (2026-11-23)
  it was taken out: no second SnackBar is shown, and what an action did
  is told by a live-region line of the page. What remains of this
  entry's orderings in C13: a new message replaces the one before
  (`clear…` before each show), and an action whose example has gone
  changes nothing and takes away its own message only.
- Workaround, in the SDK: `clearSnackBars()` before `showSnackBar()`, and
  `clearMaterialBanners()` before `showMaterialBanner()`: they clear the
  queue and take away the current one. Every C13 example does; the C13
  widget tests "a burst of presses" fail with `hideCurrent…` and pass
  with `clear…`.
- Upstream issue: not searched yet (D25).

## FL-294

**A SnackBar's Close button shows keyboard focus only by a faint tint, and `closeIconColor` cannot change that.**

- Status: Confirmed in the widget tests only, Flutter 3.47.5. Measured in
  the probe (`flutter_test_focus.txt`, from `probe4_test.dart.txt`) and
  asserted by the C13 widget test "keyboard focus draws a change of 3:1
  or more on each control but the SnackBar's Close", written to fail when
  Close draws one.
- What happens: `showCloseIcon` adds an `IconButton` that the app cannot
  style. Keyboard focus on it changes 1,130 pixels on and round it, the
  largest change 1.34:1 in light mode and 1.19:1 in dark (the tint of
  [FL-430](#fl-430)). `closeIconColor` is documented to be resolved
  against the button's states when it is a `WidgetStateColor`; one that
  is yellow when focused and white otherwise changed nothing on focus
  (fixture s09: largest change 1.38:1). Read in the source:
  `IconButton` passes its `color` to `styleFrom` as `foregroundColor`,
  and `ButtonStyleButton.defaultColor` maps it to every state as it is.
- WCAG: 1.4.11 Non-text Contrast, as [FL-430](#fl-430) reads it for an
  `IconButton`.
- Workaround: none through the SnackBar's parameters. A `SnackBarAction`
  can be given focus colours (its `textColor` and `backgroundColor` take
  a `WidgetStateColor`, and C13 `good-action` uses them). An
  `IconButtonTheme` above the `ScaffoldMessenger`, for the whole app, was
  not tried.
- Upstream issue: not searched yet (D25).

## FL-295

**A `MaterialBanner` is a live region only when the `ScaffoldMessenger` shows it.**

- Status: Confirmed, Flutter 3.47.5. Framework source read:
  `material/banner.dart`, `_MaterialBannerState.build`, returns the
  banner as it is when it has no `animation` ("a static banner for
  backwards compatibility"), and wraps it in `Semantics(container: true,
  liveRegion: true, onDismiss:)` only when it has one, which
  `showMaterialBanner` gives it. Asserted by every C13 layer's tests of
  `bad-inline-banner`, with `good-banner` as the positive control.
- What happens: a `MaterialBanner` put in the page, as any widget is put
  there, has no live region and no dismiss action: on the web nothing is
  written to Flutter's announcement elements (the tree spec), and
  VoiceOver on iOS and TalkBack say nothing when it appears (see the C13
  transcripts). The same banner shown by `showMaterialBanner` is
  announced on all three.
- WCAG: 4.1.3 Status Messages, where the banner is a status message.
- Workaround, in the SDK: show it with
  `ScaffoldMessenger.showMaterialBanner` (C13 `good-banner`).
- Upstream issue: not searched yet (D25).

## FL-296

**A SnackBar shown from a `SnackBarAction`'s `onPressed`, after `clearSnackBars` or `hideCurrentSnackBar` there, never appears when `accessibleNavigation` is on: the action hides it.**

- Status: Confirmed, Flutter 3.47.5. Framework source read:
  `material/snack_bar.dart`, `_SnackBarActionState._handlePressed`, calls
  the app's `onPressed` and then
  `ScaffoldMessenger.of(context).hideCurrentSnackBar(reason: action)`;
  `scaffold.dart`, `hideCurrentSnackBar`, with `accessibleNavigation` on,
  sets the animation to 0 at once, which takes the SnackBar out of the
  queue before the next line runs. Asserted by the C13 widget tests
  "FL-296" (the SDK alone, four cases): with a clear in `onPressed`, the
  second SnackBar was never on the screen with `accessibleNavigation` on,
  and came with it off; without the clear, it came either way. Seen on the
  web (Chromium) in C13's first build of `good-action`, whose Undo cleared
  and showed "Archive undone" in `onPressed`: it never entered the
  semantics tree, and nothing was announced, by Enter or by a click
  (`docs/evidence/probes/c13/web_undo.txt`, round 1). Whether the web
  engine reports `accessibleNavigation` on was not read; the old SnackBar
  went at once there, as it does with it on.
- What happens: with it on, clearing takes the current SnackBar away at
  once, the new one becomes the current one, and the action then hides
  that one. With it off the cleared one is still going out when the
  action hides, so the action hides it again and the new one comes.
- What users get: `accessibleNavigation` is on when TalkBack or VoiceOver
  is (and was in every Android run of C13, [FL-290](#fl-290)), so a
  confirmation of what an action did, shown this way, is lost for the
  users who most need it to be announced, and works in a widget test that
  leaves it off.
- Workaround: none built. C13 first showed the second SnackBar from the
  first one's `closed` future (`SnackBarClosedReason.action`), and
  "Archive undone" was then written on the web (`web_undo.txt`, round 2);
  its ordering needed a project-built policy ([FL-293](#fl-293)), and it
  was taken out (the principal's decision in review, 2026-11-23). What an
  action did is announced by a live-region line of the page instead
  (`Semantics(liveRegion: true)`; C13 `good-action`, `good-banner`):
  TalkBack and VoiceOver on iOS said it; VoiceOver in Chromium did not,
  in its one web recording ([FL-297](#fl-297)).
- Upstream issue: not searched yet (D25).

## FL-297

**On the web, whether VoiceOver in Chromium said what a SnackBar or banner action did, when Enter on that action removed the control, varied between recordings, and the live-region line that now says it was not heard in its one recording.**

- Status: Observed, Flutter 3.47.5, macOS 27.2.1, VoiceOver, Playwright's
  Chromium build. Seen in C13's web VoiceOver recordings, listed below.
  The C13 web VoiceOver spec now records every phrase heard after the
  press and asserts nothing about the message (the rows
  `<slug>-after-undo-recorded`, `<slug>-after-go-online-recorded`).
- Rounds 3 to 5 measured the first review build's second SnackBar,
  since removed; C13 now tells what the action did with a live-region
  line of the page, the result line (`Semantics(liveRegion: true)`,
  [FL-296](#fl-296)), and round 6 on measured that line. The rows stay
  record-only unless three recordings agree.
- What was pressed: Enter, with keyboard focus on the action, in three
  examples: `good-action`'s Undo (a `SnackBarAction`), `good-banner`'s Go
  online (a `TextButton` in a `MaterialBanner` the messenger shows), and
  `bad-inline-banner`'s Go online (a `TextButton` in a banner in the
  page). Each removes the control pressed and, in rounds 3 to 5, showed a
  SnackBar, "Archive undone" or "You are online."; from round 6, writes
  the result line instead, "Archive undone. Archived: 0" or "You are
  online.". What VoiceOver said in the six seconds after, by recording:
  - Round 3 (`docs/evidence/probes/c13/voiceover-web-round3-fail.md.txt`):
    none of the three messages. Undo: "Back and 1 more item and 2 more
    items group", "Back", the usage hint. `good-banner`'s Go online:
    "Back", the hint. `bad-inline-banner`'s: "Back and 1 more item and 2
    more items group", "Back".
  - Round 4 (`voiceover-web-round4-fail.md.txt`): two of the three. Undo:
    "Back and 1 more item and 2 more items group", "Archive undone", the
    hint. `good-banner`'s Go online: "Go offline button", "Back", the
    hint, and not the message. `bad-inline-banner`'s: "Back and 1 more item
    and 2 more items group", "You are online.".
  - Round 5 (`voiceover-web-round5.md.txt`, every test passing, the rows
    recording only; the committed transcript until round 6): one of the
    three. Undo:
    "Back", the hint, and not the message. `good-banner`'s Go online:
    "Back and 1 more item and 2 more items group", "Back", the hint, and
    not the message. `bad-inline-banner`'s: "Back and 1 more item and 2
    more items group", "You are online.".
  - Across rounds 3 to 5, the second SnackBar: "Archive undone" (`good-action`) was said in one, `good-banner`'s "You are online." in none, and `bad-inline-banner`'s "You are online." in two.
  - Round 6, the result line, the committed transcript
    (`docs/evidence/C13/voiceover-web.md`, recorded by the principal at
    943c51e, 10 passed, the rows recording only): none of the three.
    Undo: "Back and 1 more item and 1 more item group", "Back", the hint,
    and not "Archive undone. Archived: 0". `good-banner`'s Go online:
    "Back", the hint, and not "You are online.". `bad-inline-banner`'s:
    "Back", and not "You are online.".
  - Across all four: `good-action`'s was said in one, `good-banner`'s in
    none, `bad-inline-banner`'s in two, and the result line, in its one
    recording, in none. One recording of the result line is no reading
    of it to hold; its rows stay record-only.
- What Flutter did, the same presses without VoiceOver
  (`docs/evidence/probes/c13/web_done_focus.txt`, Chromium): it wrote
  "Archive undone" or "You are online." to `flt-announcement-polite` about
  50 ms after Enter and emptied it about 300 ms later ([FL-012](#fl-012)'s
  timer); the control pressed went, and DOM focus went to the page's
  button ("Archive message" after Undo, "Go offline" after Go online).
  The result line goes the same way
  (`docs/evidence/probes/c13/web_result.txt`, Chromium, no VoiceOver):
  "Archive undone. Archived: 0" or "You are online." written to
  `flt-announcement-polite` 25 to 50 ms after Enter and emptied about
  300 ms later, once per press, the line itself staying on the page.
- Not measured: why the result varies; what decides between the message
  and the move to Back; why VoiceOver's cursor went to Back; whether a
  message not heard was dropped or never received; a press by any other
  means than Enter (a click, VoiceOver's own activation); WebKit, where
  Playwright's build passes no live region changes to VoiceOver at all
  (I12), and real Safari; any other screen reader. No cause is given.
- WCAG: 4.1.3 as written is met in the tree (the second SnackBar, and
  now the result line, is a polite live region, and Flutter writes it to
  the page's live region). VoiceOver in Chromium said the SnackBar in
  some recordings and not in others, `good-banner`'s in none of three,
  and the result line in none of the three examples in its one
  recording, so on the web what the action did may not be presented: a
  qualification of the web for the examples with an action, not a
  failure of 4.1.3 as written.
- What users get, as measured: a VoiceOver user in Chromium who presses
  Undo or Go online may hear what it did, or may hear "Back" instead; with
  the result line, in its one recording, they heard "Back" each time. The
  page's line shows it, and the result line stays on the page, where
  moving to it reads it (not measured with VoiceOver); TalkBack and
  VoiceOver on iOS said it (the C13 transcripts).
- Workaround: none tried. The C13 examples are the framework's SnackBar
  and banner through their own parameters, and what an action did is a
  `Semantics(liveRegion: true)` line of the page; nothing is built round
  them (the principal's decisions in review, 2026-11-22 and 2026-11-23).
- Upstream issue: not searched yet (D25).

<!-- FL-300 to FL-399: Wave 3, structure and order. Entries in this range go below, in id order. -->

## FL-300

**`Title` sets the document title only when it is built or its title changes: after Back the browser keeps the title of the screen that closed.**

- Status: Confirmed, Flutter 3.47.5: asserted by every S06 example in the
  widget tests (Back sends no title) and the web tree tests (the document
  title after the app's Back, and after the browser's Back for
  `good-material`). Found in the S06 probe
  (`docs/evidence/probes/s06/`): on the web, in Chromium on macOS, for
  every fixture with a `Title` (p01, p03 to p10, p12, p13), after the
  app's Back (not taken for p13) and after the browser's back and
  forward (`web.txt`), in Playwright's Chromium on macOS; in
  the widget tests, as Android and as iOS, Back sent no title at all
  (`flutter_test.txt`). Framework source read: `widgets/title.dart` calls
  `SystemChrome.setApplicationSwitcherDescription` in `initState` and in
  `didUpdateWidget` when its title or colour changed, and at no other
  time; the screen under a pushed route keeps its state and its widget,
  so nothing calls it again when the route above it pops. The web engine
  writes the label to `document.title` (source read:
  `platform_dispatcher.dart`).
- WCAG: 2.4.2 Page Titled, on the web, under S06's reading of each
  screen as a page (its spec, section 3). As written, an app at one
  address can be one page; Understanding 2.4.2 says its title "should
  also be changed dynamically" with the view.
- What happens: a screen opened with a `Title` gives the document its
  title, and Chromium's root web area takes that name. When the screen
  closes, the document keeps it: the example screen under S06's
  `good-material`, titled "Material screen title - Flutter A11Y
  Techniques" when it opened, is shown under the title "Orders" after
  Back. The same holds for this app's own screens, which each have a
  `Title` (`lib/app/widgets.dart`, `PageScaffold`): the catalog, "Flutter
  A11Y Techniques", opened S06's technique screen, "Screen and page
  titles - Flutter A11Y Techniques", and after the app's Back the catalog
  kept that title (`docs/evidence/probes/s06/web_back.txt`, the release
  app build in Playwright's Chromium on macOS); the example screens under
  S06's screens as above. No other screen of the app was tried. On Android `Title` sets the app's task label in
  Recents (source read: `PlatformPlugin.java`); what that label is after
  Back was not measured. On iOS `Title` does
  nothing (source read: `FlutterPlatformPlugin.mm`).
- Why it matters: after Back, the document's title, which a browser
  shows in its tab, and the page's name in Chromium's accessibility tree
  name a screen that is not shown. What a screen reader said of the
  page's name after Back, and the titles in the browser's history, were
  not measured.
- Workaround: none in the SDK. No documented parameter of `Title`,
  `MaterialApp` (`title`, `onGenerateTitle`), or the routes sets the
  title again when a route pops. A `NavigatorObserver` or a `RouteAware`
  that calls `SystemChrome` on a pop would be a mechanism of the
  project's own, which the owner's rule does not allow; it is not built.
  So the web is a limitation in S06 (`PlatformStatus.limitation`).
- Upstream issue: not searched yet (D25).

## FL-301

**`CupertinoNavigationBar`'s title names no route: on Android the pane title is a space, and TalkBack is not told the screen's name.**

- Status: Confirmed, Flutter 3.47.5: asserted by S06
  `bad-cupertino-unnamed` in the widget tests (no node names the route),
  the Android tree test (the pane title a single space), the TalkBack
  transcript, and the web tree test (Playwright's Chromium on macOS, with
  `navigator.platform` left as "MacIntel" and set to "Linux x86_64"
  before load); `good-cupertino`, the same
  bar with `Semantics(namesRoute: true)` round its middle, is the
  positive control on each. Found in the S06 probe (p05, p06; p08 with
  `namesRoute`). Framework source read: `cupertino/nav_bar.dart` wraps
  the middle and the large title in `Semantics(header: true)` with no
  `namesRoute`, where `material/app_bar.dart` sets `namesRoute` on its
  title for Android, Fuchsia, Linux, and Windows.
- WCAG: none as written: the title is there, shown, and a header. It
  misses S06's R5, an announcement of the title, which the Android
  Compose reference repository gives through the screen's pane title.
- What happens: Android's engine sets the FlutterView's pane title to the
  route's name, the label of the first node with `namesRoute` in the last
  route, or to a single space where there is none (source read:
  `AccessibilityBridge.java`, `onWindowNameChange`). With the bar's
  middle (p05) or large title (p06) it is " ", and TalkBack, when the
  screen opened, spoke an empty utterance and then "Back", "Button"
  (`android-tree.txt`, `android-talkback.md`). With `namesRoute` (p08)
  the pane title is "p08 Orders". On the web, in Playwright's Chromium on
  macOS, no element describes the route, with `navigator.platform` left
  as "MacIntel" or set to "Linux x86_64"; with `namesRoute` it is
  described by the title ([FL-304](#fl-304)). A browser that really runs
  on Linux or Windows was not tried here; CI's web tests run on Linux. On iOS VoiceOver did not say the title when the
  screen opened with or without it ([FL-302](#fl-302)).
- Workaround, in the SDK: `Semantics(namesRoute: true)` round the
  middle's text, the documented property, as S06 `good-cupertino` does.
- Upstream issue: not searched yet (D25).

## FL-302

**On iOS VoiceOver is not told a screen's title when it opens: its cursor goes to the screen's first control.**

- Status: Confirmed, Flutter 3.47.5, iOS 27.0: asserted by S06's iOS
  VoiceOver test for every example. Found in the S06 probe (`ios.txt`,
  `ios-round1.txt`, p01 to p13). Framework source read:
  `material/app_bar.dart` leaves `namesRoute` unset on iOS and macOS;
  the iOS engine posts `UIAccessibilityScreenChangedNotification` with
  the route's name, nil where no node names it, then
  `UIAccessibilityLayoutChangedNotification` with the first focusable
  node (`accessibility_bridge.mm`).
- WCAG: none as written; 2.4.2 asks for a title, not for an
  announcement. S06's R5, the title said as a screen opens, comes from
  the Android Compose reference alone and is not a requirement on iOS
  (the principal's decision, S06's spec, section 8); iOS applies there.
- What happens: after a double tap at the button that opens the screen,
  `currentSpeech()`, read every 0.15 s for eight seconds in the probe and
  six in the test, gave the button's own utterance and then only "Back
  Button" for a Material screen, or "Button" for a Cupertino one
  ([FL-303](#fl-303)): the cursor on the first control. The title was
  never among the reads, also where `Semantics(namesRoute: true)` names
  the route (p07, p08). One move forward reads it, "Orders Heading" when
  it has `headingLevel` (p09), "Orders" when it has not (p01): the
  header alone is not a heading for VoiceOver ([FL-003](#fl-003)). An
  utterance shorter than one read's interval could be missed by these
  reads; nothing shorter was seen.
- Why it matters: a VoiceOver user learns the screen's name only by
  moving to it.
- Workaround: none in the SDK. `namesRoute` did not change what was heard.
- Upstream issue: not searched yet (D25).

## FL-303

**`CupertinoNavigationBarBackButton` is two buttons: the one that takes the tap has no name.**

- Status: Confirmed, Flutter 3.47.5: asserted by S06 `good-cupertino`
  and `bad-cupertino-unnamed` in the widget tests, the iOS tree and
  VoiceOver tests, and the web tree test (where the Back button is
  located as the first of two), with Material's Back as the positive
  control. Found in the S06 probe (p05, p06, p08). Framework source read:
  `cupertino/nav_bar.dart` builds a `CupertinoButton`, which has the tap,
  round a `Semantics(container: true, excludeSemantics: true, label:
  'Back', button: true)`, which has the name and no action.
- WCAG: 4.1.2 Name, Role, Value, as written ("the name and role can be
  programmatically determined"), by platform, as measured:
  - iOS: fails. The element that takes the tap is a button with no
    label, and VoiceOver stops on it and says only "Button"; that a
    second element is labelled "Back" does not name it.
  - Web (Chromium and WebKit, Playwright's builds): not failed. Both
    elements have the button role and are named "Back" in Chromium's
    tree (the outer one by its content), and VoiceOver read "Back
    button" in both browsers as the two Cupertino screens opened; in
    Chromium it added "group" and its help for a group, in both
    recordings (`docs/evidence/S06/voiceover-web.md` and
    `docs/evidence/probes/s06/voiceover-web-round1-fail.md.txt`, the
    Cupertino `-opening` rows, recorded and not judged).
  - Android: not shown to fail. The node TalkBack read, "Back", has its
    name and the `Button` class; it has no click action, which 4.1.2
    does not ask about. Whether TalkBack ever stops on the unnamed
    clickable node was not measured: in the walk it went to "Back".
  - Widget tests: a test-framework finding, not a platform's.
- What happens:
  - Widget tests: a node with the tap action and no label, which fails
    `labeledTapTargetGuideline`, and a button node named "Back" with no
    action.
  - iOS: two buttons, one labelled "Back" and one with no label. When the
    screen opened, VoiceOver's cursor went to the unnamed one and said
    "Button"; one move forward said "Back Button" (`ios.txt`, p05, p06,
    p08). A double tap at the labelled one's place went back.
  - Web: two elements with the button role, the outer one focusable and
    tappable, the inner one with the text "Back"; in Chromium both are
    named "Back", the outer by its content (`web.txt`, round 3's strict
    locator found two).
  - Android: one node named "Back", a `Button` with no click action,
    which TalkBack read as "Back", "Button" with no "Double-tap to
    activate", where it said that for Material's Back
    (`docs/evidence/S06/talkback-android.md`, the Cupertino `-opened`
    rows; the probe's p05, p06, p08); and a clickable node with no
    name, as S06's Android tree test asserts.
- Workaround: none tried. S06 `good-cupertino` keeps the bar's own
  button, so that good example has this framework defect on iOS, and its
  spec, doc, and code say so; its widget test skips the labelled tap
  target guideline on the opened screen and asserts this instead.
- Upstream issue: not searched yet (D25).

## FL-304

**On the web a route is a generic element with no role, described by its title only where a node names the route, which `AppBar` does not when `navigator.platform` reports a Mac.**

- Status: Confirmed, Flutter 3.47.5, Playwright's Chromium on macOS:
  asserted by S06's web tree test, with `navigator.platform` set before
  load to "MacIntel" and to "Linux x86_64". Found in the S06 probe
  (`web.txt`: p01 to p13 with the platform as it is, "MacIntel"; p01,
  p05, p09, p13 with it set to "Linux x86_64"). A browser that really
  runs on Linux, as CI's does, or on Windows, was not tried here. Framework source read: the web engine gives a
  node with `scopesRoute` the `SemanticRoute` role, which sets no ARIA
  role, and points `aria-describedby` at a descendant with `namesRoute`
  (`semantics/route.dart`); Flutter takes the web's platform from
  `navigator.platform`, and `AppBar` sets `namesRoute` only on Android,
  Fuchsia, Linux, and Windows.
- WCAG: none on its own: the document's title is the web's screen title
  (R4), and this is about the route's element.
- What happens: with "MacIntel", no route element has
  `aria-describedby` with a Material `AppBar` (p01, p09), and one does
  with `namesRoute` set by hand (p07, p08). With "Linux x86_64",
  `AppBar`'s route is described by its title (p01, p09, p13). Where it is, Chromium's tree has a generic node with
  no name whose description is the title; no route is a `dialog`, a
  `region`, or any landmark. A screen is not a region a screen reader
  can move to. Named-route landmarks on the web are said to come with
  Flutter 3.50 (S06's issue); the pin is 3.47.5, and nothing of 3.50 was
  measured. VoiceOver on the web, opening `good-cupertino`'s screen,
  whose route is described with either `navigator.platform`, did not
  read the description in either recording, in Chromium or WebKit
  (`docs/evidence/S06/voiceover-web.md`, and the first, failed round,
  `docs/evidence/probes/s06/voiceover-web-round1-fail.md.txt`; the
  opening rows, recorded and not judged); nothing else was measured of
  it. Those recordings ran with `navigator.platform` as it is on the
  Mac, so `good-material`'s route was not described in them.
- Upstream issue: not searched yet (D25).

## FL-305

**On Android a screen that changes inside one route, such as a `NavigationBar`'s destinations, keeps the pane title of the first.**

- Status: Observed, Flutter 3.47.5, Android 17: the S06 probe (p10,
  `android-tree.txt`); no test in the repo. Framework source read:
  Android's engine sets the pane title only when the routes on the
  screen change (`AccessibilityBridge.java`, the route check before
  `onWindowNameChange`), not when the name of the shown route changes.
- WCAG: none as written; it misses S06's R5 for each destination.
- What happens: p10's `AppBar` title and `Title` follow the selected
  destination. After "p10 Settings" was pressed, the pane title was still
  "p10 Inbox"; on the web the document's title became "p10 Settings"
  (`web.txt`). TalkBack, after the press, said only "selected"
  (`android-talkback.md`). On iOS, after a double tap at the destination,
  VoiceOver's reads gave nothing new in eight seconds, and one move
  forward read "p10 Settings", the new title (`ios.txt`).
- Workaround: none tried.
- Upstream issue: not searched yet (D25).

<!-- FL-400 to FL-499: Wave 4, focus and keyboard. Entries in this range go below, in id order. -->

## FL-400

**A `CupertinoListTile` with `onTap` takes no keyboard focus, and is not a button on Android and iOS.**

- Status: Confirmed, Flutter 3.47.5. Two separate gaps, each stated below
  with where it was seen. Found in the I01 probe
  (`docs/evidence/probes/i01/`, fixture `k04`). Asserted by the I01 widget
  test "FL-400" (no focus state, no button flag, Tab goes past it),
  written to fail when the tile takes focus or gets the flag. Framework
  source read: `cupertino/list_tile.dart`, which wraps the tile in a
  `GestureDetector` when `onTap` is set and in nothing else: no `Focus`,
  no actions for the keys, no `Semantics(button: true)`. `ListTile` has
  all three, through `InkWell` and its own `Semantics`.
- No keyboard focus, on all three platforms. WCAG 2.1.1 Keyboard. Tab
  went past the tile on the web (Chromium, no `tabindex` on its element),
  on the Android emulator (`adb shell input keyevent`), and on the iOS
  simulator (XCUITest's hardware keys), and in the semantics tree the node
  has no focus state at all (`isFocused` is `Tristate.none`). The tile
  answers a tap, and the `GestureDetector` gives it a tap action, so a
  screen reader can still activate it.
- Not a button, on Android and iOS only. WCAG 4.1.2 Name, Role, Value, on
  those two. The framework sets no button flag on any platform; what each
  platform makes of that:
  - Android: `android.view.View`, clickable, "k04 CupertinoListTile".
  - iOS: static text to XCUITest; VoiceOver reads "k04 CupertinoListTile"
    with no "Button".
  - Web: a button. The engine gives any node with a tap action
    `role="button"` ([FL-006](#fl-006)), and Chromium's accessibility tree
    has a button named "k04 CupertinoListTile". The role is not missing
    there; only the focus is.
- Why it matters: `CupertinoListTile` is the Cupertino row for a list of
  choices or settings, and its `onTap` is documented for making the row act.
  A keyboard or switch user cannot reach a row built that way on any
  platform, and a screen reader user on Android or iOS is not told it is a
  control.
- Workaround, in the SDK: wrap the tile in `FocusableActionDetector` with
  actions for `ActivateIntent` and `ButtonActivateIntent`, and put
  `Semantics(button: true)` around it, as I01 `good-cupertino` does; draw
  a focus ring from `onShowFocusHighlight`, since the tile shows none.
  Verified in the I01 widget, web, Android, and iOS tests: Tab reaches it,
  Enter and Space activate it, and it is a button on all three platforms.
- How to read this entry: Flutter has not added keyboard support or a role
  to `CupertinoListTile` yet. Re-check when the pinned version changes.
- Upstream issue: not searched yet (D25).

## FL-401

**An `InkWell` with `onTap` is not a button on Android and iOS.**

- Status: Confirmed, Flutter 3.47.5. Found in the I01 probe
  (`docs/evidence/probes/i01/`, fixture `k02`); asserted by the I01 widget,
  Android, and iOS tests of `bad-inkwell-no-role` and heard in its TalkBack
  and VoiceOver on iOS transcripts. Framework source read:
  `material/ink_well.dart`, whose `Semantics` sets `onTap` and nothing that
  gives a role.
- WCAG: 4.1.2 Name, Role, Value, on Android and iOS only.
- What happens: an `InkWell` takes keyboard focus, handles Enter and Space
  (both `ActivateIntent` and `ButtonActivateIntent`), and has a tap action,
  so everything but the role is right: Tab reached it and Enter and Space
  activated it on all three platforms (probe fixture `k02`, and the I01
  tests of `bad-inkwell-no-role`). The framework sets no button flag on
  any platform; what each platform makes of that:
  - Android: `android.view.View`, clickable. TalkBack reads the text and
    "Double-tap to activate", and never "Button".
  - iOS: static text to XCUITest. VoiceOver reads the text alone.
  - Web: a button. The engine gives any node with a tap action
    `role="button"` ([FL-006](#fl-006)); VoiceOver reads "Ridge trail
    button". Not affected.
- Why it matters: the tappable card in the `Card` API documentation is a
  `Card` around an `InkWell`, and the same is a common way to make a
  Material surface tappable. A screen reader user on iOS hears a card with
  nothing to say it does anything; on Android only TalkBack's usage hint,
  "Double-tap to activate", gives it away. Whether TalkBack says anything
  of the kind with its usage hints turned off was not tested.
- Workaround, in the SDK: `Semantics(button: true)` around the `InkWell`
  (probe fixture `k03`: a button on all three platforms), or a `ListTile`
  with `onTap`, which is a button by itself (I01 `good-material`).
- The same in C18 (2026-11-22), as the card of the `Card` documentation:
  `Card(child: InkWell(onTap:, child: …))` with a title and a text is one
  node with a tap action and no button flag. Asserted by C18
  `bad-ink-well` in the widget, Android, iOS, and web tests and its
  transcripts: on Android an `android.view.View`, clickable, that TalkBack
  reads as its text and "Double-tap to activate" (probe fixture p20,
  `docs/evidence/probes/c18/android-talkback.md`); on iOS static text to
  XCUITest, which VoiceOver read as its text alone (`ios.txt`, p20); on the
  web a button. Two things change the workaround for a card: if the
  card's title is a heading, `Semantics(button: true)` round the
  `InkWell` gives a node that is a heading and a button, which on the web
  is a heading only ([FL-262](#fl-262), probe fixture p19); and on the
  web a `ListTile` with `onTap` (C18 `good-tappable`) is a button only
  while its title is not a heading (C18 `bad-heading-button`). On Android
  and iOS it keeps the button role with a heading title: an
  `android.widget.Button` that is a heading (`android-tree.txt`, p06), a
  button to XCUITest (`ios.txt`, p06), read by VoiceOver as "… Button
  Heading" (`docs/evidence/C18/voiceover-ios.md`, `bad-heading-button`).
- Upstream issue: not searched yet (D25). This may be intended: `InkWell`
  is an ink response and not a control of a given kind.

## FL-402

**A tap is given up by how far the pointer has moved, not by whether it has left the control.**

- Status: Confirmed in a widget test, Flutter 3.47.5. The gesture code is
  the framework's and is the same on every platform (read in the source:
  `gestures/tap.dart`, `gestures/recognizer.dart`
  (`PrimaryPointerGestureRecognizer`), and `gestures/constants.dart`,
  `kTouchSlop`); it was not measured on a device. Asserted by the I01
  widget tests "FL-402" for `good-material`, `good-cupertino`, and
  `good-custom`, written to fail when either half changes, and by one
  with the touch slop set in `MediaQuery`.
- WCAG: none failed. 2.5.2 Pointer Cancellation asks for a way to abort,
  and moving the pointer far enough is one.
- What happens: `onTap` runs when the pointer is released, unless the
  pointer has moved more than the touch slop from where it was pressed.
  Where the pointer is when it is released is not checked. The slop is
  the device's, which a `GestureDetector` takes from `MediaQuery`
  (`gestureSettings.touchSlop`, which the framework fills from the
  view's `physicalTouchSlop` when the engine reports one: read in the
  source, `gestures/gesture_settings.dart`), and 18 logical pixels
  (`kTouchSlop`) where none is given, as in a widget test. With the slop
  at 18:
  - Pressed 4 pixels inside the control's edge, moved 10 pixels out, and
    released 6 pixels outside it: the control acts.
  - Pressed at its centre, moved 40 pixels sideways, and released still
    over it: the control does not act.
- Effect: someone who presses the wrong control near its edge and slides
  just off it still activates it; to take a press back they have to move
  further than the touch slop, in any direction. What the slop is on each
  device was not measured.
- Workaround: none tried. A control could check the release position
  itself (`onTapUp` gives it) before acting.
- Upstream issue: not searched yet (D25).

## FL-410

**A control's semantics node can be bigger than the area that takes taps, and the tap target guidelines read the node.**

- Status: Confirmed, Flutter 3.47.5. Found in the V13 probe
  (`docs/evidence/probes/v13/`, fixtures `p14`, `p16`, and `p18`), and
  asserted by the V13 widget tests "FL-410", written to fail when the node
  and the area agree or the guideline starts to look at the area.
  Framework source read: `flutter_test/lib/src/accessibility.dart`
  (`MinimumTapTargetGuideline`, which measures `SemanticsNode.rect`
  through its transforms and skips links), `rendering/proxy_box.dart` and
  `widgets/gesture_detector.dart` (`HitTestBehavior`), and
  `rendering/paragraph.dart` (`assembleSemanticsNode`).
- Platforms: Android and iOS, where a tap is taken by Flutter's hit test;
  and `flutter_test`. On the web a click on the node's element is the
  node's ([FL-411](#fl-411)), so there the node is the target.
- WCAG: none failed by this alone. It makes a check of 2.5.8 Target Size
  (Minimum), which counts the area that takes the pointer, wrong in the
  direction that passes.
- What happens: the node's rect is the box of the widget that made it; the
  area that takes taps is wherever the hit test finds a render object that
  answers. They differ in three cases seen in the probe, with an 18 pixel
  icon:
  - `Semantics(button: true)` around `Padding(all: 15)` around a
    `GestureDetector` (padding outside the detector): the node is 48 by 48;
    a tap 2 pixels inside its edge does nothing on Android and iOS.
  - `Semantics(button: true)` around a `GestureDetector` with the default
    `HitTestBehavior.deferToChild` around a 48 by 48 `SizedBox` with the
    icon in a `Center`: the node is 48 by 48; only the icon takes taps,
    because an empty `SizedBox` and `Center` do not answer the hit test.
  - A `TextSpan` with a `TapGestureRecognizer`: its node is its text's box,
    floored and ceiled, plus 4 pixels on each side (56 by 26 on Android and
    the web, 57 by 26 on iOS, for a word whose line is 20 high); a tap 2 pixels inside the node's bottom edge,
    below the text, does nothing on Android and iOS.
  Android's bounds and XCUITest's frames are the node, so TalkBack's and
  VoiceOver's focus outline and any tool that reads the tree show the
  bigger area. `androidTapTargetGuideline` and `iOSTapTargetGuideline` read
  48 by 48 for the first two and pass them, and skip links altogether.
- Why it matters: the guidelines in `flutter_test` are the check most
  Flutter projects have for target size, and they pass a control that
  takes taps only on its 18 pixel icon. Laid out in a row of 48 by 48
  nodes, such controls still pass 2.5.8 by spacing; the harm is that the
  check cannot be trusted, and that a person aiming at the edge of what the
  screen reader outlines misses.
- Workaround, in the SDK: put the padding inside the `GestureDetector`, or
  give it `HitTestBehavior.opaque`, as V13 `good-custom` does; then the
  node and the area are the same box. To test the area, tap at points
  inside and outside the edges, as the V13 tests do on every layer.
- How to read this entry: Flutter has not added a check of where a control
  takes taps to its tap target guidelines yet.
- Upstream issue: not searched yet (D25).

## FL-411

**On the web a click is taken by the element of the node under it, and by its label text where that runs out of the element.**

- Status: Confirmed, Flutter 3.47.5, Chromium on macOS. Found in the V13
  probe (`docs/evidence/probes/v13/web.txt` and `web_round2.txt`) and
  asserted by `web_tests/v13_touch_target_size.spec.js` ("FL-411"),
  written to fail when the label stops taking clicks outside the element.
  Engine source read: `lib/web_ui/lib/src/engine/pointer_binding.dart`
  (`ClickDebouncer`) and `semantics/tappable.dart`.
- Platforms: web. On Android and iOS a tap goes to Flutter's hit test
  (V13 probe).
- WCAG: none failed by this alone.
- What happens: with semantics on, which this app turns on at start on the
  web (`lib/main.dart`), a `pointerdown` on an element marked
  `flt-tappable` is held back, and when the browser's `click` follows the
  engine sends `SemanticsAction.tap` to that element's node and drops the
  pointer events. So a click is the node's wherever the browser finds that
  element under the pointer, whatever Flutter's own hit test would find
  there:
  - a click anywhere in the node acts, also where Flutter's hit test would
    miss ([FL-410](#fl-410)'s first two cases act on a click 2 pixels
    inside their 48 pixel node on the web, and not on Android and iOS);
  - the element's label is its text content, and the element lets it run
    out (`overflow: visible`). The probe's 18 by 18 fixtures (`p04`,
    `p05`, `p11`, `p13`, `p17`, labelled with their ids) and the Next
    button of each V13 bad example, also 18 by 18, took a click 2 pixels
    to the right of their box, where `document.elementFromPoint` still
    finds the button's element; for `p04` and `p13`, 6 pixels to the right
    it no longer did. The link of V13 `good-inline-link`, an `<a>`, took a
    click 2 pixels below its box in the same way. A click 2 pixels below
    an 18 pixel button, and 2 pixels above the link, did not act.
- Why it matters: on the web the area that takes a click is the node's box
  and some of its label text, not what is drawn. The text is not drawn, so
  a click beside a small control can press it with nothing to show it
  would. Whether a label that runs over a neighbouring control takes that
  control's clicks was not tested. A check of target size on the web that
  reads element boxes misses the overflow.
- Workaround: none tried for the overflow. Controls at least 24 by 24 with
  labels that fit them are not affected in V13's good examples.
- How to read this entry: this is how the web engine handles clicks with
  semantics on; Flutter has not made the label text fit its element yet.
- Upstream issue: not searched yet (D25).

## FL-412

**In a desktop browser the Material theme does not pad controls to 48 by 48, and is compact.**

- Status: Confirmed, Flutter 3.47.5. Found in the V13 probe
  (`docs/evidence/probes/v13/web.txt`, `web_round3.txt`, and
  `flutter_test.txt`), and asserted by the V13 widget tests "FL-412" and
  the tests of `bad-zero-padding-web` on every layer. Framework source
  read: `material/theme_data.dart` (`materialTapTargetSize` and
  `VisualDensity.defaultDensityForPlatform`); engine source read:
  `lib/web_ui/lib/ui_web/src/ui_web/browser_detection.dart`.
- Platforms: the web in a desktop browser, measured in Chromium on macOS.
  By the same source the macOS, Linux, and Windows apps are the same; they
  are not built here.
- WCAG: 2.5.8 Target Size (Minimum), on the web in a desktop browser, for a
  control whose own size is under 24 by 24 and that relies on the padding:
  `bad-zero-padding-web`. Default controls stay over it: in the probe an
  `IconButton` was 40 by 40, a `TextButton` 56 by 32, a `Checkbox` 40 by 40.
- What happens: `ThemeData` sets `materialTapTargetSize` to `padded` and
  `visualDensity` to standard on Android, iOS, and Fuchsia, and to
  `shrinkWrap` and compact on macOS, Linux, and Windows. A web build takes
  its platform from the browser: the engine reads `navigator.platform`
  first ("MacIntel" is macOS, unless the device has more than two touch
  points, which is an iPad and so iOS), then the user agent for Android.
  So an `IconButton` with `padding: EdgeInsets.zero` and
  `constraints: BoxConstraints()` is 48 by 48 on a phone and the size of
  its icon, 18 by 18, in a desktop browser. In Chromium with
  `navigator.platform` "Linux armv8l" and an Android phone's user agent the
  platform was Android and the padding came back (48 by 48); with the
  user agent alone it stayed macOS.
- Why it matters: a layout checked on a phone, where the padding hides
  small controls, can be under the minimum in a desktop browser, which
  includes laptops with touch screens. Flutter's guidelines in a widget
  test run as Android unless told otherwise, so they do not see it.
- Workaround, in the SDK: give small controls a minimum size of their own
  (an `IconButton`'s `constraints` or `style.minimumSize`), or set
  `materialTapTargetSize: MaterialTapTargetSize.padded` in the app's
  `ThemeData`; the V13 widget test "FL-412: padded in ThemeData" shows the
  second gives 48 by 48 as macOS. Widget tests can run as a desktop
  platform with `debugDefaultTargetPlatformOverride`, as V13's do.
- How to read this entry: this is Flutter's chosen density for desktop
  platforms, not a fault; it is here because the web gets it from the
  browser's operating system.
- Upstream issue: not searched yet (D25).

## FL-413

**The text around a `WidgetSpan` is one node that leaves the widget out, and the widget's node comes after it.**

- Status: Confirmed, Flutter 3.47.5, with a workaround verified on all
  three platforms. Found in the first build of V13
  `/t/V13/good-inline-link`, a sentence "Read the trail rules before you
  set off." whose link is a `WidgetSpan`. Asserted on the SDK alone by the
  V13 widget test "FL-413", written to fail when it is fixed. Framework
  source read: `rendering/paragraph.dart`
  (`RenderParagraph.describeSemanticsConfiguration` and
  `assembleSemanticsNode`).
- What happens, in that first build (the transcripts are kept in
  `docs/evidence/probes/v13/`):
  - iOS: VoiceOver read "Read the before you set off." and then "trail
    rules Link" (`voiceover_ios_round1_widgetspan.md.txt`).
  - Web: the sentence was a `group` whose `aria-label` was "Read the
    before you set off.", with the link inside it; VoiceOver read "Read
    the before you set off. group", "link trail rules", "end of Read the
    before you set off. group" in Chromium and in Playwright's WebKit
    (`voiceover_web_round1_widgetspan.md.txt`).
  - Android: the paragraph's node was "Read the", a line break, and
    "before you set off.", and the link's node followed it
    (`android_link_dump.txt`, a `uiautomator` dump). What TalkBack reads
    when it moves on its own was not tested.
- Cause (source read): a paragraph gives each run of its text a node of
  its own only when some span has a recognizer or a
  `semanticsIdentifier`. Otherwise it puts all its text in one label and
  leaves each `WidgetSpan`'s nodes as children after it. When it does
  split the text, it gives the runs sort keys `OrdinalSortKey(0)`,
  `OrdinalSortKey(1)`, and so on, and gives the `WidgetSpan`'s node none,
  so the widget is still read first (round 2 probe, fixtures `q3` and
  `q4`, `docs/evidence/probes/v13/flutter_test_round2.txt`).
- WCAG: 1.3.2 Meaningful Sequence is the candidate where the words only
  make sense with the widget, as here; not claimed by V13. Left to C04
  Links inline with text.
- Why it matters: a `WidgetSpan` is how a focusable control goes in a line
  of text. A `TextSpan` with a recognizer keeps its place in the
  semantics tree (round 2 probe, fixture `q2`, in `flutter_test` only) but
  takes no keyboard focus, so with the SDK's
  plain parts a link in text is either read out of its sentence or out of
  the keyboard's reach.
- Workaround, in the SDK, verified in V13 `good-inline-link` on all three
  platforms: give one of the sentence's `TextSpan`s a
  `semanticsIdentifier`, so that the paragraph splits its text into runs;
  and put the `WidgetSpan`'s widget in `Semantics(container: true,
  sortKey: OrdinalSortKey(0.5))`, a key between those of the runs before
  and after it. Not inside `MergeSemantics`, which drops the sort key
  (round 2 probe, fixture `q6`). The link then keeps its keyboard focus,
  and is read in its place: VoiceOver on iOS reads "Read the", "trail
  rules Link", "before you set off."
  (`docs/evidence/V13/voiceover-ios.md`), and VoiceOver on the web reads
  "Read the", "link trail rules", "before you set off." in Chromium and in
  Playwright's WebKit (`docs/evidence/V13/voiceover-web.md`); on the web
  the sentence is three elements in that order
  (`docs/evidence/probes/v13/web_round4.txt`). Tab reaches the link and
  Enter and Space activate it in the widget tests, in Chromium, on the
  Android emulator, and on the iOS simulator (the V13 tests on each).
  The widget test "good-inline-link: the sentence is read in order" and
  the web tree test of the same name assert the order. The key has to
  match the run's position: by the source, a link after the second run of
  text would need a key between 1 and 2 (not tested).
- Measured again in C04 Links inline with text (2026-11-21), with two
  links in one sentence, "Read about [links in text] and [stand-alone
  links] first.", each a `WidgetSpan` with an address:
  - Two links with the keys 0.5 and 1.5 are read in place: the widget
    tests (the sentence's nodes in traversal order, on one line and
    wrapped, at 100% and 200% text), the web tree (the sentence's
    elements in the page's order), the Android tree (the sentence node's
    children in order), and the transcripts of C04's good examples. So the
    "between 1 and 2" above is now tested.
  - Without the keys the order rests on where the links land: in the
    probe's widget test (`docs/evidence/probes/c04/flutter_test.txt`,
    "order" lines) both links came first on one line and after the first
    run when wrapped, with and without a container round them, while C04's
    own sentence happened to come out right without them. The keys are
    what makes it hold, and C04's widget tests check each link has its key.
  - A span with the identifier is a run of its own, and the spans after it
    up to the next `WidgetSpan` make one run, whatever their style: with
    the identifier on "Read " and a bold "about " after it, a link after
    them needs 1.5, and 0.5 puts it between the two ("two spans" lines;
    framework source: `combineSemanticsInfo` in `painting/inline_span.dart`).
  - With no workaround (C04 `bad-out-of-order`, probe r02) the sentence
    node is "Read about \n and \n first." holding the links: on Android
    its `View` with the two links as children, on the web a `group` with
    that `aria-label` holding the two `<a href>`, on iOS an element with
    that label and the two links after it (`ios.txt`). VoiceOver on the
    web reads "Read about and first. group", "link links in text", "link
    stand-alone links", "end of Read about and first. group" in Chromium and
    WebKit, as in V13's first build (`docs/evidence/C04/voiceover-web.md`).
    WCAG 1.3.2 Meaningful Sequence, claimed for `bad-out-of-order` on all
    three.
  - The workaround's links are boxes in the line and cannot break across
    lines ([FL-244](#fl-244)), and their text is scaled twice unless told
    not to be ([FL-241](#fl-241)).
- How to read this entry: Flutter has not added a way to read a
  `WidgetSpan` in its place in the text without help yet.
- Upstream issue: not searched yet (D25).

## FL-420

**Tab crosses side-by-side columns row by row by default, and the keyboard's order and the screen reader's are set by separate widgets.**

- Status: Confirmed, Flutter 3.47.5, all platforms. Found in the I02 probe
  (`docs/evidence/probes/i02/`, fixtures `a` to `d`). Asserted by the I02
  widget tests "FL-420" (the SDK alone) and by every I02 layer's tests of
  `bad-columns-mixed`, written to fail when Tab starts to go down a column
  by itself. Framework source read: `widgets/focus_traversal.dart`
  (`ReadingOrderTraversalPolicy`, `FocusTraversalGroup`) and
  `semantics/semantics.dart` (`_childrenInDefaultOrder`).
- WCAG: 2.4.3 Focus Order; for screen readers, 1.3.2 Meaningful Sequence.
- What happens: `WidgetsApp` puts the whole app in one
  `FocusTraversalGroup` with `ReadingOrderTraversalPolicy`, which orders
  controls by position: the highest first, then any others whose
  rectangle overlaps its row, in reading direction, and so on. Two lists
  side by side whose rows are level are reached row by row, back and forth
  between the lists. Android Views and Compose go by the order of the
  layout tree, and HTML by the order of the document, so on those a
  column written as one block is reached as one: in Flutter it is not.
  - The keyboard's order changes only with focus widgets:
    `FocusTraversalGroup` around each column makes Tab go down one, then
    the other. It has no effect on the semantics tree
    (`includeSemantics: false`, read in the source).
  - The screen reader's order changes only with semantics:
    `Semantics(container: true)` around each column makes screen readers
    read one, then the other, and does nothing for Tab. Without it, the
    framework sorts the nodes by position too, in its own way: rows that
    touch or overlap form one band and are read down by column, rows apart
    from each other are read across (read in the source; in the probe both
    happened on different screen sizes). A layout's screen reader order
    can therefore change with the screen size.
- Effect: a keyboard user moves through two lists mixed together, as in
  the failing example of Understanding 2.4.3; and a fix made for one of
  keyboard or screen reader users leaves the other as it was.
- Workaround, in the SDK: a `FocusTraversalGroup` and a semantics
  container around each column (I02 `good-material` and
  `good-cupertino`). Where no widget holds a column, an
  `OrderedTraversalPolicy` with a `FocusTraversalOrder` on every control,
  and an `OrdinalSortKey` with the same numbers (I02 `good-ordered`).
  Verified at every I02 layer.
- How to read this entry: this is how Flutter's default policy is
  documented to work, not a defect in it. It is logged because it differs
  from the platforms Flutter runs on, and because nothing ties the two
  orders together.
- Upstream issue: not searched yet (D25).

## FL-421

**On the web, Tab past Flutter's last control continues in the document's order, and can go round for ever.**

- Status: Confirmed, Flutter 3.47.5, web (Chromium, Playwright). Found in
  the I02 probe (fixture `i`); asserted by `web_tests/i02_focus_order.spec.js`
  ("Tab past First aid goes round"), written to fail when Tab leaves the
  page. Framework source read: `widgets/app.dart` (the root route's
  `routeTraversalEdgeBehavior` is `TraversalEdgeBehavior.leaveFlutterView`
  on the web) and `widgets/focus_traversal.dart`; engine source read:
  `lib/web_ui/lib/src/engine/semantics/focusable.dart`.
- WCAG: 2.4.3 Focus Order.
- What happens: on the web every focusable node is an element with
  `tabindex="0"`, in the document in the semantics order. Flutter handles
  Tab itself and moves focus in its own order. At the last control of
  that order it unfocuses and lets the browser have the key, so that Tab
  can leave the page. The browser then moves to the next element in the
  document. When Flutter's last control is not the document's last, that
  next element is one of Flutter's: the engine passes the element's focus
  to the framework, and Flutter's order carries on from there. In I02
  `bad-order-missing` Flutter's last stop is First aid, which comes before
  Weather in the document: Tab goes First aid, Weather, Closures, Save
  plan, First aid, and round again, and never leaves the page. Shift+Tab
  is not affected. Android and iOS go round to the first control, by
  design.
- Effect: on the web, a keyboard user can never Tab out of the page to
  the browser's own controls, and goes round a part of the screen.
- Workaround, in the SDK: keep the last control of the focus order last
  in the semantics order, which is the document's: give every control
  its place in both orders (FL-420), as I02 `good-ordered` does; there,
  Tab past Save plan leaves the page.
- Upstream issue: not searched yet (D25).

## FL-422

**On a scrolled screen the default focus order puts the app bar's Back button among the content.**

- Status: Confirmed, Flutter 3.47.5, all platforms. Found in the I02 probe
  (`docs/evidence/probes/i02/`): on the web (round 2, forty buttons in a
  `SingleChildScrollView` under an `AppBar`), in a widget test of the same
  screen, and on the Android emulator and the iOS simulator, where Tab
  past the last control of the long probe screen went round to the first
  control of the content and not to Back. Asserted by the I02 widget test
  "FL-422", written to fail when Back stops coming between the buttons.
  Framework source read: `widgets/focus_traversal.dart`.
- WCAG: 2.4.3 Focus Order.
- What happens: `ReadingOrderTraversalPolicy`, the default, sorts the
  controls by their rectangles on the screen at the moment the key is
  pressed (`FocusNode.rect`, in the screen's coordinates), and controls
  scrolled out of view keep rectangles above or below the view. Once a
  list has scrolled, the controls scrolled away above are "higher" than
  the app bar, and the app bar's Back button sorts among the content:
  - Shift+Tab up the list stops on Back between two buttons, and the next
    Shift+Tab goes on from where it was. In the widget test: B10, B9, B8,
    B7, B6, Back, B5, Back, B4, Back, and so on. On the web: s20, Back,
    s19, Back. With each four buttons in a `FocusTraversalGroup`, Back
    came between groups.
  - Tab past the last control goes round to the control highest on the
    screen, which is the first of the list and not Back, and on down the
    list Back comes once in the middle.
  This app's `PageScaffold` now has the workaround below. On an 800 by
  120 screen, where the I02 examples scroll until their first control is
  above the top of the screen, I02 `bad-columns-mixed`, whose controls
  are in no group, went round from Save plan to Map and skipped Back
  without it; the good examples kept their order with and without it,
  because each of their tall groups reaches down into Back's row (read in
  the source: the bands of `ReadingOrderTraversalPolicy`).
- Effect: moving backwards through a long page, a keyboard user is sent
  to the top of the screen at every step or two.
- Workaround, in the SDK: a `FocusTraversalGroup` around the scrolling
  view (outside it, not inside). The group is sorted against Back by its
  own rectangle, the part of the screen the list shows, which is always
  below the app bar; inside it the controls keep their order. Verified in
  the I02 widget test "FL-422 workaround": Tab goes Back, B1 to B12, Back,
  and Shift+Tab the same backwards. Applied in the app's `PageScaffold`
  (`lib/app/widgets.dart`) and asserted by
  `test/app/page_scaffold_focus_test.dart` and by the I02 widget test
  "bad-columns-mixed: Tab past Save plan goes round to Back", which fails
  without it. The I02 web tests at 800 by 120 show the good examples'
  order on a scrolled screen in Chromium, but they pass without the group
  too, so they do not verify it there. Not verified on Android or iOS.
  Also
  tried in the probe, with the same result in a widget test: an
  `OrderedTraversalPolicy` over the screen with the app bar ordered first
  and the grouped body second.
- Upstream issue: not searched yet (D25).

## FL-430

**A Material control with nothing of its own to change shows keyboard focus only with a tint on the page under 3:1: a checked `Checkbox`, a `TextButton`, an `IconButton`, a `ListTile`.**

- Status: Confirmed, Flutter 3.47.5, for the checked `Checkbox`: asserted
  by V14 `bad-checked-checkbox` in the widget tests (light and dark), on
  the web, on iOS, and on Android (with a `uinput` keyboard), written to
  fail when the halo reaches 1.5:1 or anything focus draws reaches 3:1.
  The other three measured in the V14 probe only, in widget tests at a
  device pixel ratio of 3 (`flutter_test_measure3.txt`, fixtures m4, m5,
  m12); the app's Back button, an `IconButton`, is measured as the
  positive control of V14 `bad-indicator-removed` on every layer, with the
  same result. Framework source read: `material/checkbox.dart`
  (`_CheckboxDefaultsM3`: `overlayColor` is `primary` at an opacity of 0.1
  when the box is checked and focused, and the checked box has no border
  to darken), and the M3 defaults of `text_button.dart` and
  `icon_button.dart` (an overlay of the foreground colour at 0.1).
- WCAG: 1.4.11 Non-text Contrast. Measured as V14 measures (the spec,
  section 6): every pixel focus changes, whatever it replaced, taken
  against what is next to it; a tint drawn where the page was is outside
  the control and must contrast with the page.
- What happens: with keyboard focus, each of these draws a tint of a
  tenth of the foreground colour where the page shows round it, and
  nothing else changes. Against the page, light then dark mode: checked
  `Checkbox` 1.15:1 (`#EAE8F4` on `#FBF8FF`) and 1.22:1; `TextButton`
  1.15:1 and 1.22:1; `IconButton` 1.23:1 for the app's Back button
  (1.14:1 and 1.12:1 in the probe's theme); `ListTile` 1.32:1 and 1.41:1.
- How sure the verdict is: for the checked checkbox it rests on nothing
  but the measure, as the box is plainly visible and the halo plainly
  outside it. For the other three it also rests on where the control's
  edge is: they have no visible container, so their tint is read as drawn
  outside them, on the page. If their invisible shape were taken as their
  boundary, the tint would be a change of background within the
  component, which Understanding 1.4.11 puts out of its scope; they would
  then fail nothing as written, and only 2.4.13 (AAA).
- Not the same: an unchecked `Checkbox` or a `Radio` also darkens its
  border or ring with focus, and a `Switch` its thumb, and those are 3:1
  or more against what is next to them, so they meet 1.4.11 as written
  ([FL-434](#fl-434)).
- Effect: someone using a keyboard can hardly see which of these controls
  they are on. Every screen of this app has an `IconButton` so: the app
  bar's Back button.
- Workaround, in the SDK: a ring of the text colour drawn outside the
  control while it has focus, from `ButtonStyle.side` for the focused
  state or from a `Focus` that hears the focus change, as V14
  `good-material` does for a `FilledButton` and a `CheckboxListTile`
  (16.30:1 against the page, 14.35:1 in dark). Verified at every V14
  layer.
- How to read this entry: Flutter has not given these controls a focus
  indicator of 3:1 yet. Re-check when the pinned version changes.
- Upstream issue: not searched yet (D25).

## FL-431

**Cupertino's default focus ring is under 3:1 on a light page, and a `CupertinoCheckbox`'s in dark mode as well.**

- Status: Confirmed, Flutter 3.47.5, for `CupertinoButton` in light mode:
  asserted by V14 `bad-cupertino-ring` in the widget tests (light under
  3:1, dark 3:1 or more), on the web, on iOS, and on Android. The switch
  and the checkbox measured in the V14 probe only (widget tests;
  `flutter_test_measure3.txt`, fixtures c3 and c4, and the earlier
  probe's `flutter_test.txt`, `web.txt`, and `ios.txt`). Framework source
  read: `cupertino/button.dart` (the ring is the control's colour at an
  opacity of 0.80, its HSL lightness set to 0.69 and saturation to 0.835:
  `kCupertinoFocusColorOpacity`, `kCupertinoFocusColorBrightness`, and
  `kCupertinoFocusColorSaturation` in `cupertino/constants.dart`), and the
  same rule in `switch.dart` and `checkbox.dart`.
- WCAG: 1.4.11 Non-text Contrast: each ring is drawn outside the control,
  on the page, and must contrast with the page. Control by control, as
  measured (against the page):

  | Control | Light mode | Dark mode |
  | --- | --- | --- |
  | `CupertinoButton`, default blue | `#8ABCF5`, 1.89:1, fails | `#5C8EC6`, 5.42:1, passes |
  | `CupertinoButton.filled` in this app (primary `#515B92`) | `#8A9AF5`, 2.49:1, fails | `#5C69C6`, 3.79:1, passes |
  | `CupertinoSwitch` | `#8AF3A5`, 1.29:1, fails | `#5CC577`, 8.58:1, passes |
  | `CupertinoCheckbox` | `#8ABCF5`, 1.89:1, fails | a ring of shades over the box's edge, `#424A5D` the commonest; 1.31:1 and 1.68:1 against the shades next to it, 1.44:1 the lowest at its edge (with the measure before the second review, 1.63:1 to 1.91:1 for its largest bands), fails |

  Nothing else changes with focus on any of them. The dark-mode checkbox
  was measured in the widget tests only, not on a device.
- Effect: on a light page someone using a keyboard can hardly see which
  Cupertino control they are on; on a dark page, which checkbox.
- Workaround, in the SDK: `focusColor` on the control, in a colour with
  3:1 against the page in both modes, such as
  `CupertinoColors.label.resolveFrom(context)`, as V14 `good-cupertino`
  does for a `CupertinoSwitch` and a `CupertinoButton.filled` (19.97:1 in
  light, 18.55:1 in dark). Verified in the V14 widget tests, on the web,
  on iOS, and on Android. Not tried on a `CupertinoCheckbox`.
- How to read this entry: Flutter has not made the Cupertino focus ring
  meet 3:1 yet. Re-check when the pinned version changes.
- Upstream issue: not searched yet (D25).

## FL-432

**A control that takes keyboard focus is scrolled into its view without regard to anything drawn over the view, and can end up entirely hidden.**

- Status: Confirmed, Flutter 3.47.5, all platforms. Measured in the V14
  probe (fixtures o1, o4, o5) in a widget test, on the web, on the
  Android emulator, and on the iOS simulator, with the same result on all.
  Asserted by V14 `bad-notice-over-list` at every layer, written to fail
  when a focused trail is no longer entirely under the notice. Framework
  source read: `widgets/focus_traversal.dart`
  (`defaultTraversalRequestFocusCallback` calls `Scrollable.ensureVisible`
  on the newly focused control) and `rendering/viewport.dart`
  (`getOffsetToReveal`, which allows for pinned slivers before the
  control, `maxScrollObstructionExtentBefore`, and for nothing outside
  the viewport).
- WCAG: 2.4.11 Focus Not Obscured (Minimum), where the content drawn over
  the view is the app's and the control is entirely hidden (F110).
- What happens: Tab scrolls the newly focused control just far enough to
  be inside the scrolling view's own rectangle, and does not move one
  that is inside it already. Anything drawn over that rectangle is not
  allowed for:
  - a banner `Positioned` over the bottom of the view in a `Stack` (o1,
    V14 `bad-notice-over-list`): every control that comes to rest under
    it is entirely hidden; in the V14 example, three of six trails;
  - a header over the top of the view in a `Stack` (o4): the first
    control is under it when the screen opens, and Shift+Tab up the list
    puts each control under it;
  - a `Scaffold` with `extendBody: true` and a bottom bar (o5): the body
    runs under the bar, and controls are scrolled to the body's edge,
    under the bar, although the `ListView` pads its end by the bar's
    height.
  Not affected: content laid out beside the view (o2, V14
  `good-notice-below`), and a pinned `SliverAppBar` or other pinned
  sliver in the same `CustomScrollView` (o3, and the V14 widget test).
- Effect: someone using a keyboard moves to a control they cannot see,
  and may activate it without knowing what it is.
- Workaround, in the SDK: lay what would be pinned over the view out
  beside it instead (a `Column` with the scrolling view `Expanded`), as
  V14 `good-notice-below` does; or, for a header, make it a pinned sliver
  of the same scrolling view. Verified at every V14 layer for the first.
  Flutter has no counterpart to CSS `scroll-padding`, the web's way to
  keep focused content clear of a sticky bar (technique C43); a custom
  `FocusTraversalPolicy.requestFocusCallback` that scrolls with an
  `alignment` could serve, and was not tried.
- How to read this entry: Flutter has not added a way to tell scrolling
  what part of a view is covered yet.
- Upstream issue: not searched yet (D25).

## FL-433

**On Android, a key from the virtual keyboard device does not turn focus highlights on, and `input keyevent` and Instrumentation's keys all come from it.**

- Status: Confirmed, Flutter 3.47.5, Android 17 emulator. The framework's
  rule read in the source; its effect measured in the V14 probe
  (`docs/evidence/probes/v14/`, Android rounds 1 to 6) and asserted by
  the V14 Android test "keysFromTheVirtualKeyboardLeaveTheHighlightsOff".
  Framework source read: `widgets/focus_manager.dart`,
  `_HighlightModeManager.handleKeyMessage`, which does not change the
  highlight mode for a key that `_isKeyMessageFromAndroidIME` finds to
  come from an input method: one with the soft keyboard flag, or from
  device id -1, Android's virtual keyboard. The source says this is so
  that Backspace from an on-screen keyboard does not turn highlights on,
  and cites flutter/flutter issue 180746.
- WCAG: none failed as written. 2.4.7 asks for a mode in which the focus
  indicator is visible, and a keyboard of its own turns it on (below).
- What happens: Flutter shows most focus indicators (Material's tints and
  halos, Cupertino's rings, and anything drawn from
  `FocusableActionDetector.onShowFocusHighlight`) only in its traditional
  highlight mode, which a key turns on, unless the key is from device -1.
  - Every key a test sent through Android's injection arrived with device
    id -1, whatever id it was sent with: `adb shell input keyevent`,
    `Instrumentation.sendKeySync` and `UiAutomation.injectInputEvent` with
    device 0 (the emulator's own keyboard) and with 9999 (rounds 1 to 3).
    Focus moved, and the mode stayed touch: nothing that follows the mode
    was drawn. Keys through the emulator console did not reach the app
    (round 5), and no way of moving a mouse, which would also have turned
    the mode on, reached Flutter as a mouse (round 4).
  - A keyboard registered with the shell's `uinput` tool, which goes
    through the kernel as a real USB keyboard does, arrived with a device
    id of its own (24 to 27 in round 6), and its first key turned the
    mode traditional: every indicator was drawn, with the colours the
    widget tests, the web, and iOS give. A hardware keyboard's keys
    therefore turn highlights on, as the source says.
  - Indicators that Flutter draws from the focused state itself are not
    affected either way: a `TextField`'s border, an `OutlinedButton`'s
    outline, `ButtonStyle.side` for the focused state, a ring drawn from
    `Focus.onFocusChange`.
- Effect: for users, by the source, someone who moves focus with an
  on-screen keyboard's Tab or arrow keys sees no highlight that follows
  the mode (not measured with a real input method). For tests: a test
  that presses keys with `input keyevent` or Instrumentation does not see
  what a keyboard user sees. The V14 Android test registers a `uinput`
  keyboard instead (verified at the emulator's own size and at CI's 320
  by 640 at 160 dpi).
- Workaround: for users, draw the indicator from the focused state, with
  `ButtonStyle.side` or `Focus.onFocusChange`, as V14 `good-material`
  does; or set `FocusManager.instance.highlightStrategy` to
  `FocusHighlightStrategy.alwaysTraditional`, which shows every highlight
  after a touch as well (not tried). For tests, a `uinput` keyboard (the
  V14 Android test's `Keyboard`).
- How to read this entry: this is the framework's chosen behaviour; it is
  logged because it decides what a test's keys show and what an
  on-screen keyboard's keys show.
- Upstream issue: not searched yet (D25).

## FL-434

**Material's default focus indicator on a control with a container, a border, or a thumb of its own is a faint tint or halo beside a change that does meet 3:1, or a tint of the container; not a 1.4.11 failure as written.**

- Status: Confirmed, Flutter 3.47.5. Measured in the V14 probe in widget
  tests at a device pixel ratio of 3 (`flutter_test_measure3.txt`) and,
  for the same fixtures, in the earlier probe on the web and on iOS, with
  the same colours; on Android with a `uinput` keyboard for the
  `ElevatedButton` and the unchecked `Checkbox` (`android_round6.txt`).
  Asserted by the V14 widget test "a Checkbox that is not checked", which
  finds the darker border at 3:1 or more against the halo next to it, and
  by the `good-material` widget test, where the checkbox tile's own tint
  is the largest change, at 1.32:1. Framework source read: the M3
  defaults of `checkbox.dart` and `radio.dart` (`side` and `fillColor`
  turn from `onSurfaceVariant` to `onSurface` when focused), `switch.dart`
  (an unfocused thumb that is off is `outline`, a focused one
  `onSurfaceVariant`), and the buttons' and `InkWell`'s overlays (the
  foreground colour at an opacity of 0.1, or `ThemeData.focusColor`).
- WCAG: none failed as written. Understanding 1.4.11 does not compare the
  focused and unfocused states, and puts a change of background within
  the component out of its scope; 2.4.7 sets no contrast. None of these
  would meet 2.4.13 Focus Appearance (AAA), which asks for a change of 3:1
  between the states.
- What happens, measured against what is next to each part in the focused
  state, light then dark mode:
  - Unchecked `Checkbox`: a halo on the page, 1.23:1 and 1.26:1, and the
    box's 2 pixel border, which darkens from `#46464F` to `#1B1B21`: 13.25:1
    against the halo round it (dark 11.38:1). The darkening itself is a
    change of 1.82:1 between the two states, between two colours that are
    both 9:1 or more against the page.
  - `Radio`, not selected: the same halo and a ring darkened the same way,
    13.25:1 against the halo (dark 11.38:1).
  - `Switch`, off: a halo, 1.23:1 on the page, which also tints the
    track, and the thumb, which darkens to `#46464F`: 5.95:1 against the
    tinted track (dark: lightens to `#C7C5D0`, 5.50:1).
  - `FilledButton`: its fill tinted from `#515B92` to `#636C9D`, a change
    of 1.28:1, within its container.
  - `OutlinedButton`: a tint inside its outline, 1.15:1, and the outline
    turning `primary`, 5.32:1 against the tint and 6.12:1 against the page.
  - An `InkWell` card, a `FilterChip`: a tint of the card or chip, 1.31:1
    to 1.38:1 against the page, within the container.
  - `ElevatedButton`: a tint of 1.21:1 within a container that is itself
    1.05:1 against the page and shows its edge by its shadow; the probe's
    measure finds the tint where the page's colour was. This spec takes
    the container as its boundary; read otherwise, it belongs with
    [FL-430](#fl-430).
- Effect: the focused control is visible to someone who looks closely,
  and easy to lose for someone with low vision: what meets 3:1 is a part
  that was nearly as dark before focus. The reference repositories say
  the same of Android's own defaults ("generally low-contrast").
- Workaround, in the SDK: a ring from `ButtonStyle.side` for the focused
  state, drawn outside the shape, or one from `Focus.onFocusChange` (V14
  `good-material`, 16.30:1), verified at every V14 layer; or a stronger
  `overlayColor` for the focused state (probe fixture x4, 3.42:1 against
  the page).
- How to read this entry: this is the Material 3 specification's state
  layer as Flutter implements it, not a defect in it; it is logged because
  it is the default most Flutter apps show.
- Upstream issue: not searched yet (D25).

## FL-435

**A `CupertinoTextField` shows keyboard focus only by its caret.**

- Status: Observed, Flutter 3.47.5, in the V14 probe (fixture c5) in widget
  tests, on the web, and on the iOS simulator: when Tab put focus in the
  field, no pixel changed but the blinking caret's. On the Android
  emulator nothing changed at all, not even a caret (round 2); not looked
  into. No V14 example uses the field, and no test in the repository
  asserts this.
- WCAG: none failed as written: Understanding 1.4.11 accepts a text
  field's caret as its focus indicator, and asks for 3:1 only for a caret
  the author styled. The caret is the theme's primary colour.
- What happens: unlike a Material `TextField`, whose border turns
  `primary` and 2 pixels wide (6.12:1 against the page), a
  `CupertinoTextField` keeps its border when it takes focus.
- Effect: the field is found only by its caret, which blinks.
- Workaround, in the SDK: give the field a `decoration` with a stronger
  border while its `FocusNode` has focus. Not tried.
- Upstream issue: not searched yet (D25).

## FL-440

**A `CupertinoAlertDialog`'s actions take no keyboard focus.**

- Status: Confirmed, Flutter 3.47.5, all platforms. Found in the I03
  probe (`docs/evidence/probes/i03/`, fixture `p5`): in a widget test as
  Android and as iOS (`flutter_test.txt`), on the web in Chromium
  (`web.txt`), on the Android emulator (`android.txt`), and on the iOS
  simulator (`ios.txt`). Asserted by the I03 widget test "FL-440",
  written to fail when Tab reaches an action. Framework source read:
  `cupertino/dialog.dart`, where `CupertinoDialogAction` is a
  `GestureDetector` with `Semantics(button: true, onTap:)` and no `Focus`,
  `FocusableActionDetector`, or actions for the keys.
  `CupertinoActionSheetAction` in the same file has a
  `FocusableActionDetector`.
- WCAG: 2.1.1 Keyboard.
- What happens: `showCupertinoDialog` puts keyboard focus on the dialog
  route's own scope, as every dialog route does, and Tab then finds no
  control in it: focus stays on the scope on Android and iOS, and on the
  web Tab goes back and forth between leaving the page and the dialog's
  scope. Neither action can be reached or pressed from the keyboard. A
  screen reader is not affected: each action is a button with a tap
  action. Escape did not close the dialog either, in the widget test and
  on the web (not tried on Android or iOS); that is I08's subject.
- Added in I08 (2026-11-19): Escape does nothing because
  `showCupertinoDialog`'s barrier cannot be dismissed by default
  ([FL-480](#fl-480)); in the I08 probe (`docs/evidence/probes/i08/`,
  fixture `e3`) Escape left it open in a widget test and on the web. On
  the Android emulator Escape was not measured on it (no key sent to the
  app reached Flutter in the rounds that opened it); the Back key, the
  global Back action, and the keyboard's Meta+Escape and Meta+Left closed
  it (`android_round3.txt`, `android_round4.txt`). So a keyboard user who
  opens one is trapped on iOS (2.1.2), by the widget test and the source:
  Tab reaches nothing, and no key closes it. On Android the keyboard's
  Back gets them out, which nothing tells them; on the web Tab leaves the
  page for the browser's own controls (FL-440 above). With
  `barrierDismissible: true` (fixture `e4`) Escape closed it in the widget
  test and on the web, so the dialog can be left, though still not
  answered.
- Effect: a keyboard or switch user who opens a Cupertino alert can
  neither answer it nor, unless the dialog can be dismissed some other
  way, get out of it.
- Workaround, in the SDK: for a confirmation, a `CupertinoActionSheet`
  shown with `showCupertinoModalPopup`, whose actions take focus, as I03
  `good-cupertino` does; verified at every I03 layer. On the web its
  actions, like `CupertinoButton`, answer Space and not Enter
  ([FL-002](#fl-002)), so the example adds Enter.
- How to read this entry: Flutter has not added keyboard support to
  `CupertinoDialogAction` yet. Re-check when the pinned version changes.
- Upstream issue: not searched yet (D25).

## FL-441

**A `CupertinoActionSheet`'s title and message fail text contrast in light mode.**

- Status: Confirmed in widget tests only, Flutter 3.47.5: Flutter's
  `textContrastGuideline` finds the title and message of a
  `CupertinoActionSheet` with its own colours under 4.5:1 in light mode
  (3.38:1 for the title when I03 `good-cupertino` was first written).
  Asserted by the I03 widget test "FL-441", written to fail when the
  sheet's text passes. Not checked on a device or by eye; the guideline
  reads the colours it can find in the layer tree, and the sheet's
  background is translucent and blurred, so the number is the
  guideline's, not a measurement of the screen. Framework source read:
  `cupertino/dialog.dart`, where the title and message take
  `_kActionSheetContentTextColor`, a grey with an alpha of 0x85 in light
  mode and 0x96 in dark mode. In dark mode the guideline passed.
- WCAG: 1.4.3 Contrast (Minimum).
- Effect: the question an action sheet asks may be too faint to read.
- Workaround, in the SDK: give the title and message a style with
  `CupertinoColors.label`, as I03 `good-cupertino` does; with it the
  widget tests' contrast check passes in light and dark mode.
- This entry belongs with the contrast techniques of wave 5, visual
  preferences, which should measure it properly. It is not verified on a
  device.
- Upstream issue: not searched yet (D25).

## FL-442

**When a route closes, the framework sends the screen reader back to where it was, after the app's own move, even when that control has been removed.**

- Status: the framework's request is Confirmed, Flutter 3.47.5 (source
  read: `widgets/navigator.dart`; the I03 widget test "after Remove, on
  iOS the last request is for Remove Summit path, after the framework's;
  on Android there is only the framework's" records it, on Android and
  iOS as the framework sees them). Its effect is Observed on Android only,
  in the I03 probe (`docs/evidence/probes/i03/`, round 2 row `r1`,
  `android_round2.txt`, and round 3 row `s1`, `android_round3.txt`), and
  was not reproduced in the I03 examples' own TalkBack walk
  (`docs/evidence/probes/i03/mutations/`, runs m1 to m3). What makes the
  difference was not found.
- What happens: the Navigator listens for the engine's `didGainFocus`
  messages and records, for the route on top, the semantics node the
  screen reader is on. When a route above it closes, it sends that node a
  `FocusSemanticEvent` once the closed route has gone (when
  `Route.dispose` runs): at once on iOS, and on Android after another
  300 ms (`_kAndroidRefocusingDelayDuration`). The web is left out; there
  the screen reader follows DOM focus. This is what brings the screen
  reader back to the button that opened a dialog. But the request is made
  whatever the app has done since the dialog returned its answer: if the
  app removed that button and moved focus to the next one, the request
  comes after the move, for a node that no longer exists. In the probe,
  TalkBack activated Remove in a confirmation dialog, the app removed the
  row and called `requestFocus` on the next row's button at once:
  keyboard focus was on the next row, and TalkBack ended on Back, the top
  of the screen (round 3, `s1`), or on the row above (round 2, `r1`);
  waiting, or a `FocusSemanticEvent` to the next row a second later, put
  it on the next row (`s2` to `s4`). In the I03 examples, the same
  `requestFocus` with no event of the app's took TalkBack to the next
  button, and so did an event sent 250 ms after the removal, before the
  framework's request (mutation runs m1 and m2).
- Effect, where it happens: a TalkBack user who confirms a removal is
  sent to the top of the screen, or to the wrong row, and has to find
  their place again.
- On iOS the case is a different one: VoiceOver does not follow
  `requestFocus` at all (probe rows `t`, `s1`, `s2`, `p11`, `p14`), so
  the app has to send a `FocusSemanticEvent` to move it after a removal,
  and it has to come after the framework's request, or the framework's
  is the one VoiceOver is left with. The widget test above shows the
  order: an event sent when `ModalRoute.completed` completes goes before
  the framework's (that future completes in the same `dispose` call,
  first), and one sent a frame later goes after it.
- Workaround, in the SDK: on Android, move keyboard focus with
  `requestFocus` and send nothing more; TalkBack follows it (the I03
  TalkBack walk: TalkBack reads the screen's title, then the next button,
  and stays there). On iOS, also note the question's route
  (`ModalRoute.of` in its builder), wait for its `completed` future and
  then for `WidgetsBinding.instance.endOfFrame`, and send the
  `FocusSemanticEvent` to the next button then, unless keyboard focus has
  left it. There is no fixed delay: until the route has gone the page
  under it is hidden from the screen reader by the route's barrier (read
  in the source: `ModalBarrier` builds a `BlockSemantics`; and seen in
  the I03 widget test "on iOS a request still to come is dropped", where
  the next button is out of the semantics tree while the question is
  closing), so the event is sent one frame after the page is back in the
  tree, before a user can have moved on to it; VoiceOver then takes time
  of its own to act on it (see what is not known, below). Verified in the
  I03 VoiceOver walk on iOS, in all four examples that ask on a press:
  VoiceOver reads the next button and is still on it three seconds
  later; and in `moved on`, VoiceOver's first speech after the double
  tap on Remove is the next button, 1.4 to 1.7 s after it, and a move
  of VoiceOver's own made at once (`moveBackward()`, as a swipe left) is
  still where it went three seconds later. On the web nothing is sent:
  the event does nothing there (read in the source: the web engine's
  handler for `flutter/accessibility` acts only on announcements), and
  VoiceOver follows DOM focus, which follows `requestFocus` (the I03
  VoiceOver walk on the web).
- What is not known: VoiceOver speaks the next button 1.4 to 1.7 s after
  the double tap (the question's closing animation, 150 to 335 ms, is
  part of it), and the walk cannot see when in that time the route has
  gone. A move of VoiceOver's own made about 0.9 s after the double tap,
  before VoiceOver had said anything, ended on the next button
  (`docs/evidence/probes/i03/mutations/`, run `v2`): either it was made while
  the question was still closing, and the event then did what it is
  for, or it was made on the page and undone. A user who moves on that
  fast, before hearing where they are, may be moved again. No slow
  device was measured.
- How to read this entry: Flutter has not added a way to tell the
  Navigator where the screen reader should go when a route closes, or to
  stop its request, yet.
- Upstream issue: not searched yet (D25).

## FL-460

**A shortcut above a text field takes its key before the field can type it, on the web and on iOS; on Android not on the local emulator, and not shown on CI's, where the letter was lost.**

- Status: Confirmed, Flutter 3.47.5. Documented: `EditableText`'s
  documentation, "Interactions Between Shortcuts and Text Input", says a
  `Shortcuts` widget above a field that maps a letter keeps the field from
  receiving it, because the framework is given each key as a key event
  before the platform's text input is. Found in the I04 probe
  (`docs/evidence/probes/i04/`, fixtures `q01`, `q02`, and `q04`).
  Asserted by the I04 web and iOS tests of `bad-page-shortcut` ("Leafy"
  typed in the note becomes "Leay", and a favourite is added), by the I04
  widget test (the key is handled in the note), and by the I04 Android
  tests, which accept either result there and log which (below).
- WCAG: 2.1.4 Character Key Shortcuts: the lost letter is what a shortcut
  that is always on does to someone typing. Not 2.1.1: other keys still
  enter the letter (below).
- What happens: key events reach the framework first, and go on to the
  platform's text input only if nothing handled them. A `CallbackShortcuts`
  or `Shortcuts` binding for F anywhere above the focused field, or a
  `ShortcutRegistry` entry for the whole app, handles the F key, so the
  shortcut runs and no "f" is typed. Measured:
  - Web (Chromium, Playwright's keys): the shortcut ran and the letter was
    lost, for a `CharacterActivator('f')`, a
    `SingleActivator(LogicalKeyboardKey.keyG)`, and a `ShortcutRegistry`
    entry for H. A plain HTML page whose document key handler calls
    `preventDefault` for F loses the letter the same way (the probe's HTML
    control); in Flutter every handled shortcut does that.
  - iOS (simulator, XCUITest's `typeKey`, one key at a time): the same, with
    VoiceOver off and with it on. `typeText` put the letters into the field
    without any key event, past the shortcut, as an on-screen keyboard
    would; an on-screen keyboard itself was not tried.
  - Android, the local emulator (Android 17, Gboard, `hw.keyboard=yes`):
    no letter typed into a field reached the framework as a key event,
    through `input text` in the probe or `Instrumentation.sendStringSync`
    in the I04 tests; the field got every letter and no shortcut ran.
    Read as the input method having the keys first while a field is being
    edited; not confirmed in the Android source. The I04 Android tests
    send the letters both ways, `sendStringSync` and `input keyevent`, each
    in its own launch: in every run on this emulator, at 320 by 640, the
    note got every letter and no favourite was added, and the same way of
    sending an f on the favourite button added one. The same with the
    on-screen keyboard shown beside the hardware one
    (`show_ime_with_hard_keyboard` set to 1 for that run and put back to
    0). Output: `docs/evidence/probes/i04/android_review_*.txt`. (In probe
    round 2, `input keyevent` letters reached neither the framework nor
    the field; not seen again.)
  - Android, CI's emulator (API 35, `google_apis` image, no hardware
    keyboard in its AVD): the I04 test typing "Leafy" with
    `sendStringSync` got "Leay": the f did not reach the note there (CI run
    44472632084, `docs/evidence/probes/i04/ci_android_44472632084.txt`,
    which has the assertion's text). That run did not record the
    favourites line, so that the shortcut took the f, as it does on the
    web and iOS, is inferred and was not seen.
    Which input method it had, and whether its on-screen keyboard was
    showing, was not recorded. Not reproduced on the local emulator, whose
    hardware keyboard setting in its AVD was not changed: it is shared.
  The same shortcut away from the field works on all three platforms.
- Other ways to the letter, under a shortcut for a lowercase f, measured
  with `bad-page-shortcut`: on the web Shift+F types a capital F (a
  `CharacterActivator('f')` does not match "F"), and an f pasted with
  Control or Command+V goes in through the browser's own paste (I04 web
  tests). On iOS Shift+F types a capital F, an f pasted with Command+V
  goes in once iOS's question whether the app may paste is answered, and
  `typeText`, which sends text the way an on-screen keyboard does, puts
  an f in (I04 iOS tests; outcomes in
  `docs/evidence/probes/i04/review_evidence_run.txt`). Each after a plain
  f had been lost in the same launch.
- Effect: someone typing a note on a hardware keyboard sets off the
  shortcut with every f, and the f does not appear; they have to type a
  capital or paste the letter in.
- Workaround, in the SDK and documented: a `Shortcuts` around the field
  that maps the same key to `DoNothingAndStopPropagationIntent`, so the
  shortcut stops there and the key is left for the field (I04
  `good-turn-off` and `good-remap`, `_TypeF`). Verified in the I04 widget,
  web, and iOS tests: "Leafy" is typed whole and the shortcut still works
  on every other control. Better still, put the shortcut on the control it
  acts on, so it is never above a field (I04 `good-on-focus`).
- How to read this entry: this is how Flutter is documented to work, not
  a defect in it. It is logged because a page-wide shortcut, the usual way
  to add one, breaks typing on the web and iOS. On Android it was not
  shown to: the local emulator (Android 17) typed the f, and CI's
  (Android 15) lost it in a run that did not record whether a favourite
  was added.
- Upstream issue: not searched yet (D25).

## FL-461

**A text field's done, go, search, or send action takes keyboard focus away and gives it to no control.**

- Status: Confirmed, Flutter 3.47.5, all platforms. Framework source read:
  `widgets/editable_text.dart` (`_finalizeEditing`): unless the field has
  an `onEditingComplete`, these actions call `FocusNode.unfocus()`, which
  leaves focus on the screen's scope; `next` and `previous` move focus to
  the next or previous control instead. Found in the I04 probe (fixtures
  `q09`, `q12`, and `q13`, on the web, Android, and iOS), and asserted by
  the I04 tests of every example on every layer: after Enter saves the
  note, no control has focus, and the next Tab goes to Back.
- WCAG: none failed as written. A keyboard user loses their place.
- What happens: Enter on a hardware keyboard in a single-line field
  arrives as the field's action, so `onSubmitted` runs, on all three
  platforms (the probe; a multi-line field adds a line instead). The field
  then gives up focus to nothing. With an on-screen keyboard that is what
  hides the keyboard. With a hardware keyboard, focus is nowhere until the
  next Tab, which starts again from the top of the screen.
  - Android's own text field does not do this: for the done action it
    hides the on-screen keyboard and leaves focus on the field (read in
    the Android source: `TextView.onEditorAction`).
  - HTML: Enter in a form's text field submits the form, and the HTML
    standard's implicit submission says nothing of moving focus. In
    Chromium, a plain HTML form's input kept focus after Enter (the
    probe's HTML control).
- Effect: after each note, a hardware keyboard user has to Tab back down
  from the top of the screen to the field.
- Workaround, in the SDK: an `onEditingComplete` that does the work (or
  does nothing, leaving it to `onSubmitted`) keeps focus on the field; the
  on-screen keyboard then stays up as well, since Flutter hides it by
  taking focus away. Not applied in the I04 examples, which keep the
  default and its documented on-screen keyboard behaviour; where focus
  should go after an action is I03's subject.
- Upstream issue: not searched yet (D25).

## FL-463

**A `PageView` takes no keyboard focus and has no keys.**

- Status: Observed, Flutter 3.47.5, in the I04 probe (fixture `q07`): in
  the Tab order recorded on the web, Android, and iOS, Tab never stopped
  on the page view. No example and no test in the repo.
- What happens: the pages change with a swipe. Nothing in the page view
  takes focus, so no key can reach it; a screen reader's scroll actions
  were not tried.
- Effect: a keyboard user cannot turn the pages (2.1.1), unless the app
  adds a control or keys for it.
- Workaround, not built: a `FocusableActionDetector` around the page view
  with Left and Right mapped to the controller's `previousPage` and
  `nextPage`, as the I04 examples do for their strip of photos. Left to
  I14 Scrolling regions and C17 Carousel.
- Upstream issue: not searched yet (D25).

## FL-464

**A `Shortcuts`, `CallbackShortcuts`, or `Focus` around plain text makes that text the name of a node holding every control inside it.**

- Status: Confirmed, Flutter 3.47.5. Asserted by the I04 widget tests
  "the SDK on its own (FL-464)", written to fail when the wrapper stops
  adding a node. Framework source read: `widgets/focus_scope.dart`
  (`Focus` wraps its child in `Semantics(focusable: ...)` when
  `includeSemantics` is true, the default) and `widgets/shortcuts.dart`
  (`Shortcuts` and `CallbackShortcuts` are each a `Focus` that takes no
  focus; `Shortcuts` passes on its own `includeSemantics`, which is true by
  default, and `CallbackShortcuts` has no such parameter). Found in the
  I04 build.
- What happens: the wrapper's `Semantics` forms a node. Text inside it
  that has no node of its own is merged into that node as its name, and
  every control inside it becomes its child. In a widget test, a `Text`
  and a button inside any of the three give one node named by the text,
  with the button under it; without the wrapper, or with the text in a
  `Semantics(container: true)` of its own, they are side by side.
- Seen with VoiceOver, in the I04 examples before the workaround, where a
  `CallbackShortcuts` around the whole example held the line of keys as
  plain text (first transcripts, kept in `docs/evidence/probes/i04/`):
  - Web, Chromium and WebKit: VoiceOver read the line of keys followed by
    "group", then the controls, then "end of" the line and "group": the
    whole example became a group named by that line
    (`voiceover-web-first-run.md.txt`).
  - iOS: VoiceOver read the line before the strip it was written under,
    in those three examples only (`voiceover-ios-first-run.md.txt`).
  - Android: not looked at (the TalkBack walk moves TalkBack's focus to
    each control, not along the tree).
- WCAG: none failed in the I04 examples; on the web a group with a
  misleading name is 1.3.1 Info and Relationships territory.
- Effect: adding a shortcut around a screen can rename and regroup what
  a screen reader hears, with no change to how it looks.
- Workaround, in the SDK: give plain text inside a shortcut its own node,
  `Semantics(container: true)` (I04 `_KeysHint`). Verified in the I04
  widget tests and in the second web and iOS VoiceOver transcripts, where
  the line of keys is a stop of its own before the strip. Not tried:
  `includeSemantics: false` on `Shortcuts` or `Focus`.
- Upstream issue: not searched yet (D25).

## FL-480

**A route closes on Escape only when its barrier can be dismissed, and on Back and VoiceOver's escape gesture whether it can or not.**

- Status: Confirmed, Flutter 3.47.5. Framework source read:
  `widgets/routes.dart`, where every `ModalRoute` puts an action for
  `DismissIntent`, the intent `WidgetsApp` maps Escape to, around its
  content, and that action is enabled only when the route's
  `barrierDismissible` is true; Android's Back and the global Back action
  send `popRoute`, which pops the route on top through
  `Navigator.maybePop` without looking at the barrier (read in the source:
  `widgets/binding.dart`, `handlePopRoute`). On iOS VoiceOver's escape
  gesture, when no element on its way up has the dismiss action, reaches
  the engine's view controller, which sends the same `popRoute` (read in
  the engine source: `accessibilityPerformEscape` in
  `FlutterViewController.mm`; not measured, see I08's spec). Found in the
  I08 probe (`docs/evidence/probes/i08/`, fixtures `e1` to `e6`, `e16` to
  `e19`, and `e22`); where each was measured:
  - Escape: every one of those fixtures in a widget test as Android and as
    iOS, and on the web in Chromium (`flutter_test.txt`,
    `web_round2.txt`); on the Android emulator `e1`, `e2`, `e5`, `e6`,
    `e18`, and `e19` (`android.txt`; in rounds 3 and 4 no key sent to the
    app reached Flutter, so their Escape rows for `e3`, `e4`, `e16`, `e17`,
    and `e22` show nothing); on the iOS simulator `e1`, with Escape sent
    as Command+period (`ios_round3.txt`).
  - Back (the Back key and the global Back action): every one of them on
    the Android emulator (`android.txt`, `android_round3.txt`,
    `android_round4.txt`), and `popRoute` in the widget test. On the web
    the browser's Back, as its history event, closed I08's sheets,
    dismissible or not (`web_back.txt`; the web engine sends `popRoute`
    for it, read in the source: `SingleEntryBrowserHistory`).
  - A hardware keyboard's Back (Meta+Escape and Meta+Left): `e1`, `e2`,
    `e3`, `e6`, `e17`, and `e19` on the Android emulator
    (`android_round3.txt`, `android_round4.txt`).
  Asserted by the I08 widget tests "the SDK on its own", by every I08
  layer's tests of `bad-not-dismissible`, and by the I08 Android tests of
  Back, the global Back action, and the keyboard's Back.
- WCAG: 2.1.2 No Keyboard Trap, when the route has no control that
  closes it.
- What happens:
  - `showDialog`, `showModalBottomSheet`, `showGeneralDialog`,
    `showCupertinoModalPopup`, a popup menu, a dropdown, and the date
    picker close on Escape when their barrier can be dismissed; with
    `barrierDismissible: false` (or `isDismissible: false`), Escape does
    nothing. `showCupertinoDialog`, `showGeneralDialog`, and
    `showCupertinoSheet` cannot be dismissed by default, so Escape does
    nothing to them unless the app says so.
  - The Back key and the global Back action closed every one of them on
    the Android emulator, those that cannot be dismissed included, and so
    did Meta+Escape and Meta+Left on the fixtures they were tried on:
    Android's system shortcuts turn those chords into Back before the app
    sees them (AOSP `InputGestureManager` in `android16-release`; in
    `android15-release`, `PhoneWindowManager`, which also turns
    Meta+Backspace into Back; Meta+Backspace did nothing on the API 37
    emulator). Only a `PopScope` with `canPop: false` stopped them (fixture
    `e19`, which also kept Escape and the barrier's dismiss action from
    closing it).
  - A route whose barrier cannot be dismissed has no node with the dismiss
    action either: a screen reader's Dismiss action has nothing to act
    on (fixtures `e2`, `e6`, `e17`).
  - An Escape that nothing handled did not become Back on the Android
    emulator (the probe's `backControl`, and `e2` and `e6` in
    `android.txt`): the screen stayed. Escape alone is not Back there;
    Meta+Escape is.
  - On the iOS simulator the Escape key typed from XCUITest never reached
    Flutter, with VoiceOver on or off, while Tab in the same launch did
    (`ios.txt`, `ios_round2.txt`); Command+period, iOS's own key for
    cancel, arrived as Escape and closed `e1` and the probe's own overlay
    that handles Escape (`ios_round3.txt`), on iOS 27.0. On CI's iOS 26.5
    simulator it did not close the I08 layers every time, even with
    keyboard focus shown in them: in every place in one run, in one of
    three in the next (`ci_ios_26_5.txt`, `ci_ios_26_5_rerun.txt`; I08's
    spec, section 7), so I08's iOS Escape checks run on iOS 27 only.
    Whether this is XCUITest's or iOS's was not found. Whether a hardware
    keyboard's Escape key reaches the app was not tried.
- Effect: a sheet or dialog made not dismissible, so that a stray tap
  does not close it, is closed by Back and by a screen reader's gesture
  but not by Escape. If it has no button that closes it, a keyboard user
  on iOS cannot leave it: Tab goes round its controls (I08
  `bad-not-dismissible`; measured on the iOS 27.0 simulator, with Escape
  sent as Command+period; on earlier iOS Escape is not verified). On Android the keyboard's Back, Meta+Escape,
  still closes it, but nothing tells the user so, and Escape, the key the
  rest of the app answers, does nothing. On the web the browser's Back
  closes it the same way (measured as the history event, `page.goBack()`,
  in I08's web tests; the browser's keyboard shortcut itself was not
  sent), and Tab leaves the page for the browser's own controls, then
  comes back to it.
- Workaround, in the SDK: leave the barrier dismissible, as I08
  `good-material` and `good-cupertino` do; or, where it must not be, give
  the route a button that closes it, which Tab reaches.
- How to read this entry: this is how the SDK is written, and
  `barrierDismissible` is documented as being about a tap on the barrier;
  it is logged because one flag decides both a tap and the standard
  keyboard exit, and three of the SDK's dialog functions default to no
  keyboard exit at all.
- Upstream issue: not searched yet (D25).

## FL-481

**Nothing closes an overlay that is not a route, and Back pops the screen under it.**

- Status: Confirmed, Flutter 3.47.5. Found in the I08 probe
  (`docs/evidence/probes/i08/`, fixtures `e14`, an `OverlayEntry`, and
  `e15`, an `OverlayPortal`): in a widget test as Android and as iOS, on
  the web (Escape), on the Android emulator (`e14`: Escape, Back, the
  global Back action, Meta+Escape, and Meta+Left; `e15`: Back and the
  global Back action, `android_round3.txt` and `android_round4.txt`). Asserted by the
  I08 widget tests "an OverlayPortal: Escape is not handled, and popRoute
  pops the screen under it" and "an OverlayEntry stays on after popRoute
  pops its screen", and by every I08 layer's tests of `bad-no-escape` and
  `bad-back-leaves`.
- WCAG: 2.1.2 No Keyboard Trap, when the overlay keeps keyboard focus
  and has no control that closes it.
- What happens: an `OverlayEntry` or `OverlayPortal` has no route, so
  nothing in it answers `DismissIntent`: Escape is not handled. Back, and
  VoiceOver's escape gesture when nothing takes it on the way (read in
  the source, FL-480), pop the route on top, which is the screen the
  overlay was shown from. An `OverlayPortal` goes with its screen; an
  `OverlayEntry` inserted from a screen is not part of it and stays on,
  over the screen before (the probe's Home screen on Android, and the
  widget test). No node of the overlay has the dismiss action unless the
  app gives it one.
- Effect: a menu, popover, or panel drawn by hand ignores Escape; on
  Android, Back takes the user off the screen and can leave the panel
  floating over another one. On the web the browser's Back, as its
  history event, did the same in I08 `bad-back-leaves` (`web_back.txt`).
- Workaround, in the SDK, verified at every I08 layer in `good-widgets`:
  an `Actions` with an action for `DismissIntent` around the overlay,
  where keyboard focus is, for Escape; a `PopScope` on the screen, with
  `canPop` false while the overlay is shown and `onPopInvokedWithResult`
  closing it, for Back and the escape gesture at the root;
  `Semantics(onDismiss:)` on the overlay, for TalkBack's Dismiss action
  and for VoiceOver's escape gesture made inside it (read in the source:
  `accessibilityPerformEscape` in the iOS engine's `SemanticsObject.mm`).
  Or show it as a route (`showGeneralDialog`), which does the first two
  by itself (FL-480).
- How to read this entry: an overlay is documented as a stack of
  entries with no navigation of its own; it is logged because the usual
  way to draw a custom menu or popover gets none of what a route gets.
- Upstream issue: not searched yet (D25).

## FL-482

**On the web, Escape does not hide a tooltip while the page has no keyboard focus.**

- Status: Confirmed, Flutter 3.47.5, web (Chromium, Playwright). Found
  in the I08 probe (`docs/evidence/probes/i08/web_round2.txt`, fixture
  `e10`): a `Tooltip` shown by hovering, with no element of the page
  focused, stayed after Escape, and stayed while the pointer stayed;
  with DOM focus on the tooltip's own button, Escape hid it. Framework
  source read: `widgets/app.dart`, where `WidgetsApp` hides tooltips on
  Escape from a `Focus` of its own, which a key reaches only on its way
  up from the focused node, and `widgets/view.dart`, where a view that
  loses focus parks focus on the root scope, above `WidgetsApp`, "so
  that no descendant node will be given focus, and there's no widget
  that can receive keyboard events". Asserted by the I08 widget test "a
  tooltip: Escape hides it while focus is in the app, and not while focus
  is above it", which sends the view's loss of focus.
- WCAG: 1.4.13 Content on Hover or Focus, for content shown on hover that
  must be dismissible without moving the pointer.
- Also seen, on the Android emulator: a tooltip shown by the long-click
  accessibility action, with focus on the screen, stayed after Escape
  (`docs/evidence/probes/i08/android.txt`, `tooltip`); the cause was not
  looked into. In the widget test, as Android, a tooltip shown by a
  long press was hidden by Escape. On the iOS simulator the probe's
  Escape did not reach Flutter at all (FL-480), so the tooltip stayed;
  Command+period was not tried on it.
- The plan (section 2.6) says Escape on tooltips on the web needs
  Flutter 3.50. On the pinned 3.47.5 Escape does hide a tooltip on the web
  when focus is in the page; what 3.50 changes was not checked.
- C12 (2026-11-21) measured it again. On the web, with no element of the
  page focused (`blur()`), Escape left every Material tooltip of the probe
  shown, and after a click on an empty part of the page, which gives
  Flutter focus, Escape hid it (`docs/evidence/probes/c12/web_round2.txt`);
  each C12 good example asserts both (`web_tests/c12_tooltip.spec.js`). On
  the Android emulator Escape hid a tooltip shown by a touch held 800 ms,
  300 ms after the touch ended (`android-tree.txt`, "Escape 300 ms after
  the touch was released"), unlike the long-click action of the I08
  probe; that was one reading per fixture, not asserted. On the load of a
  C12 example the Back button had DOM focus (`web.txt`), so the state
  needs the page to lose focus, for example by a click outside it.
- Where the tooltip covers content, this fails 1.4.13's dismissible
  condition on the web while no element of the page has focus. Every C12
  good example's tooltip does cover content (the widget tests "the shown
  tooltip lies over other text on the screen",
  `docs/evidence/probes/c12/flutter_test_geometry.txt`), so in that state
  they fail 1.4.13 on the web. Escape does work whenever an element of the
  page has focus: the Back button, which has it on a freshly loaded
  example, the Flutter view after any click in it, or the control. The
  tests reach the failing state only with `blur()`; how a real user
  reaches it was not measured.
- Workaround: none in the framework. Flutter has not added a way for
  Escape to reach its tooltips while the page has no focus. A key handler
  of the app's own (`HardwareKeyboard.addHandler` calling
  `Tooltip.dismissAllToolTips()`) did hide it in the probe (t13); it is
  app code, and C12 does not build it.
- Upstream issue: not searched yet (D25).

## FL-483

**A `ModalBarrier` in an `OverlayPortal`'s overlay takes the whole screen out of the semantics tree, the overlay with it.**

- Status: Confirmed in a widget test only, Flutter 3.47.5. Found while
  building I08 `good-widgets`, whose layers were first an `OverlayPortal`
  with a barrier behind them: the semantics tree held only its root.
  Asserted by the I08 widget tests "a ModalBarrier in an OverlayPortal
  empties the semantics tree" and its control "a ModalBarrier in an
  OverlayEntry keeps the panel in the semantics tree".
- What happens: an `OverlayPortal` paints its overlay child in the
  overlay, but in the semantics tree the child sits where the portal
  is, inside the screen (seen in the semantics dump). A `ModalBarrier`
  builds a `BlockSemantics` (read in the source:
  `widgets/modal_barrier.dart`), which is documented to drop the
  semantics of what was painted before it in the same semantics
  container; there, the panel painted after it went too. Why was not
  looked into. In an `OverlayEntry` the
  same barrier hides only the screen.
- Effect, if it holds on devices: a hand-made modal built this way is
  silent to a screen reader. Not checked on a device.
- Workaround, in the SDK: put the barrier and the panel in an
  `OverlayEntry`, as I08 `good-widgets` does.
- Upstream issue: not searched yet (D25).

## FL-484

**While a tooltip counts as open, `WidgetsApp` takes Escape for it before the app's default Escape shortcut reaches the focused layers; a tooltip still hiding when a screen is pushed over it took every Escape.**

- Status: Observed, Flutter 3.47.5, web (Chromium, Playwright, on this
  Mac), in two states, both in probes; no test in the repository
  reproduces either. Found in I08 (`docs/evidence/probes/i08/README.md`,
  round 6; `web_flake.txt`, `web_flake_hover.txt`,
  `web_flake_hover2.txt`, `web_flake_hover3.txt`).
  - The first Escape, with a tooltip shown by hover, in all three good
    examples: on the technique screen the mouse rests on Back for a
    second, until its tooltip shows; then, with the mouse left there, the
    keyboard opens the example (Tab and Enter) and shows its layers (Tab
    and Enter on Map layers). Unthrottled, Flutter seeing Linux, Escape
    sent with no added wait once DOM focus was on Contour lines (for the
    sheet and the popup, after the one Tab from the route's scope, also
    sent at once), timed from Enter on Map layers to Escape
    (`web_flake_hover2.txt`): the first Escape left the layers shown in
    20 of 20 runs of `good-widgets` (152 to 218 ms) and 20 of 20 of
    `good-material` (116 to 199 ms); in `good-cupertino`, whose popup took
    longer to reach Contour lines (282 to 452 ms), in all 11 runs with
    Escape at 383 ms or less, and in none of the 9 at 398 ms or more. A
    second Escape, sent about six seconds after the first (after a 5 s
    wait for the layers to close and a further second), closed them in
    every run where it was sent. Sent 200, 500, or 1000 ms after the first
    (third version, release build, `web_flake_hover3.txt`; the layers
    still shown just before it in every run), it closed `good-widgets`'
    layers in 60 of 60 runs (20 at each gap; within 9 to 30 ms) and
    `good-material`'s sheet in 30 of 30 (10 at each gap; within 193 to
    244 ms). An earlier version of the probe (`web_flake_hover.txt`) saw the
    same in `good-widgets`, with Escape sent within a 50 ms poll of focus
    reaching Contour lines (time not recorded): 28 of 28 runs as Linux, 10
    of 10 as macOS; in its probe build (4 runs, as Linux, Escape after a
    walk of the widget tree) the example screen's own Back tooltip was in
    the tree at the first Escape, in its route under the layers' barrier,
    and gone after it; whether it could be seen there was not checked.
    With 400, 1000, or 3000 ms between focus reaching Contour lines and
    Escape, as Linux, the first Escape closed `good-widgets`' layers in 4
    of 4 runs at each. That version's route runs, as Linux, with about
    six seconds from Enter to Escape, closed in 10 of 10 each, and its
    probe build
    (`good-material`, 3 runs, as long) had no Back tooltip in the tree
    then. So no difference was seen between the overlay and the routes at
    comparable timing, and, going by the `good-cupertino` runs, the state
    lasts about 400 ms from the layers being opened here. With the CPU
    throttled (the same probe, as Linux, 10 runs each,
    `web_flake_hover2.txt`): at two times slower, the first Escape left
    the layers shown in 10 of 10 of `good-widgets` (154 to 220 ms) and of
    `good-material` (128 to 171 ms), and a second Escape, about six
    seconds after the first, closed them in all 20;
    at four times slower, in 10 of 10 of `good-widgets` (199 to 259 ms)
    and 6 of 10 of `good-material` (226 to 317 ms; the 4 that closed were
    at 262 ms or later), and a second Escape about six seconds after the
    first left them shown in 4 of the 10 `good-widgets` runs and 3 of the 6 `good-material`
    runs where it was sent. Made into a test of `good-widgets` in the I08
    web spec, it held unthrottled and at two times slower but not at four
    (`web_flake_test_attempt.txt`), so it is not a test.
  - Every Escape, with a tooltip left open under another screen: on CI
    (GitHub's ubuntu runner) the positive control of I08's "bad-no-escape:
    Escape does nothing" test failed now and then. Here it was reproduced
    only with the probe that does that test's steps
    (`probe_web_flake.spec.js.txt`), Flutter seeing Linux and Chromium's
    CPU throttled (CDP `Emulation.setCPUThrottlingRate`), two workers, in
    release and probe builds: Escape did not close `good-widgets`' layers
    within five seconds in about 15% of runs at four times (4 of 30, 1 of
    10, 3 of 30, 1 of 30, 6 of 40, 7 of 40, 5 of 30) and in 2 of 30 at two
    times. After a mouse click on Back and then on the example's title,
    the technique screen's Back tooltip was still in the tree, in that
    screen's route, now under the pushed example with its tickers off.
    Escape reached Flutter with focus on Contour lines, `WidgetsApp`'s
    tooltip `Focus` returned `handled`, and the layers' `DismissIntent`
    action did not run; a second Escape about six seconds after the first
    (after the 5 s wait and a further second) did the same.
    Controls, with the same steps: 0 of 30 with Flutter seeing macOS at
    four times; 0 of 20 unthrottled as Linux; 40 of 40 closed, as Linux
    at four times, when the mouse was moved off the app bar for a second
    before the title was clicked. In 30 runs as Linux at four times that
    listed tooltips, the Back tooltip was in the tree at the title click
    every time, and still there at the Escape in exactly the 5 that
    failed. The same steps on the `bad-not-dismissible` and
    `good-material` pair, as Linux at four times: 40 of 40 closed.
- What happens, read in the source (`widgets/app.dart`,
  `widgets/raw_tooltip.dart`): `WidgetsApp` wraps the app in a `Focus`
  whose key handler, on an Escape key down, calls
  `RawTooltip.dismissAllToolTips()` and returns `handled` when that
  returns true, which it does whenever any tooltip is in the list of open
  tooltips, wherever it is. That `Focus` is below the app's `Shortcuts`
  that turns Escape into `DismissIntent`, so a key on its way up from the
  focused node reaches it first, and the layers' action never sees that
  Escape (also measured: in the probe's trace of the focus chain, the
  tooltip `Focus` ran before that `Shortcuts`). That is the order for the
  app's default Escape mapping, which every route and the I08 examples
  rely on. A `Shortcuts` nearer the focused node, inside the layers, comes
  before that `Focus`: `FocusManager` sends a key from the focused node
  up through its ancestors and stops at the first that handles it (read
  in the source, `widgets/focus_manager.dart`; measured below, under
  Workaround). A tooltip leaves the list
  only when its hide animation ends
  (`RawTooltipState._handleStatusChanged`). Not measured: that the Back
  tooltip stayed in the list because its route's tickers were off before
  its hide animation ended. The source has a TODO above that `Focus`
  citing flutter/flutter#180319, to use actions and shortcuts for this
  instead; read in the source only, the issue not searched (D25).
- Effect: with the layers open, Escape, their standard way out, does
  nothing: in the first state on the first press, made within about
  400 ms of the layers being opened while the mouse rests on Back, whose
  tooltip is shown, in an overlay or a route; in the second, on every press until the user leaves
  the screen. In `good-widgets` Tab stays in the layers (`closedLoop`).
- WCAG: none as written. 2.1.2 No Keyboard Trap needs focus to be movable
  away with the keyboard: in the first state a second Escape did it,
  every time it was sent (about six seconds after the first in all three
  good examples, and 200, 500, or 1000 ms after it in `good-widgets` and
  `good-material`); in
  the second, whether the browser's Back still closed the layers was not
  measured, so no failure is claimed. 1.4.13 Content on Hover or Focus is
  about dismissing the hover content itself, and in the first state the
  tooltip was gone from the tree after the first Escape (4 runs of
  `good-widgets`); in the second it was under another screen. What a user meets is an Escape that seems to do nothing.
- Not measured: real hardware without throttling, other browsers,
  Android or iOS with a mouse or trackpad, and touch. A keyboard-only
  user: I08's web tests that open an example by its address and show the
  layers from the keyboard alone (Tab passes Back on the way, and each
  key is followed by 400 ms) found Escape closing them every time; in the probes a tooltip was in the tree only
  after the mouse had rested on Back; whether one shows on keyboard focus
  was not checked. Whether a keyboard-only or touch user can reach either
  state was not measured.
- Workaround: none built into the examples. Measured in a probe only: a
  local `Shortcuts` mapping Escape to `DismissIntent` round the layers
  (round `good-widgets`' layers, inside their `Actions`, and round
  `good-material`'s sheet content; `probe_web_local_shortcuts.diff.txt`).
  With the first state's steps and timing (unthrottled, Flutter seeing
  Linux, a profile-mode probe build), the first Escape closed the layers
  in 20 of 20 runs of `good-widgets` (85 to 205 ms from Enter on Map
  layers to Escape) and 20 of 20 of `good-material` (115 to 203 ms); in
  the same probe build without it, in 0 of 10 of each (111 to 233 ms and
  110 to 180 ms) (`web_flake_hover3.txt`). After the layers had closed,
  Back's tooltip was in the tree, with the mouse still resting on Back;
  whether that Escape left it open or it showed again on hover was not
  separated. Not measured with it: the every-Escape state, the other
  examples, throttled CPUs, other browsers and platforms. The examples do
  not use it: by the rule of the register of custom solutions
  ([custom-solutions.md](custom-solutions.md)), a `Shortcuts` or
  `Actions` built round a framework widget to work around a limitation is
  a custom solution (C12 `good-cupertino`'s `Actions` is the precedent),
  and adopting one is the owner's decision. Read in the source, not
  measured: `TooltipVisibility(visible: false)` stops Material tooltips
  from showing, at the cost of the tooltips themselves.
  I08's web tests move the mouse off the app bar and wait until no
  tooltip is shown before they open a good example in the positive
  controls, so that this does not decide them.
- See also [FL-482](#fl-482): the same handler, which a key reaches only
  on its way up from a focused node.
- Upstream issue: not searched yet (D25).

<!-- FL-500 to FL-599: Wave 5, visual preferences. Entries in this range go below, in id order. -->

<!-- FL-600 to FL-699: Wave 6, remaining forms. Entries in this range go below, in id order. -->

<!-- FL-700 to FL-799: Wave 7, dialogs and overlays. Entries in this range go below, in id order. -->

<!-- FL-800 to FL-899: Wave 8, navigation and complex components. Entries in this range go below, in id order. -->

<!-- FL-900 to FL-999: Wave 9, the batch 10 techniques. Entries in this range go below, in id order. -->

<!-- End of the entries. -->
