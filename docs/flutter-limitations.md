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
| [FL-027](#fl-027) | A progress indicator whose value has a percent sign reports an empty range on Android | Android | Observed |
| [FL-028](#fl-028) | A slider has no accessible name on web | Web | Confirmed; fixed in 3.50 by its source, not verified |
| [FL-029](#fl-029) | A Material `Slider` adds an empty full-screen element that takes pointer events on web | Web | Confirmed |
| [FL-030](#fl-030) | A label on an `Image` inside a button does not name the button | Android, iOS | Confirmed (source read) |
| [FL-031](#fl-031) | An `Image` left in a button's semantics makes the button an image as well | Android, iOS | Confirmed |
| [FL-032](#fl-032) | `Semantics(link: true)` without `linkUrl` is a link on iOS only | Android, Web | Observed (source read) |
| [FL-033](#fl-033) | A switch or checkbox with no `enabled` flag is read as dimmed by VoiceOver on iOS | iOS | Confirmed (source read) |
| [FL-034](#fl-034) | `Semantics(keyboardKey: true)` has no effect on any platform | All | Observed (source read) |
| [FL-035](#fl-035) | A checkbox is a switch for VoiceOver on iOS | iOS | Confirmed (source read) |
| [FL-036](#fl-036) | No way to reword the state of a switch or checkbox; `value` on one is handled three different ways | All | Confirmed |
| [FL-037](#fl-037) | On web a `value` is appended to the accessible name | Web | Confirmed |
| [FL-038](#fl-038) | On Android an adjustable node shows `increasedValue` as its value straight after the action | Android | Confirmed (source read) |
| [FL-039](#fl-039) | On Android a hint is the end of the content description, not a hint | Android | Confirmed (source read) |
| [FL-040](#fl-040) | `Semantics(hint:)` around a Material button stays on a node of its own | All | Confirmed |
| [FL-041](#fl-041) | On web a hint on a node with no label is not rendered, unless the node is a text field | Web | Confirmed (source read) |
| [FL-042](#fl-042) | An obscured text field that is not being edited was read as a plain text field by VoiceOver on iOS | iOS | Observed in the S15 build and the F02 probe; no test yet |
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
| **FL-200 to FL-299** | Wave 2, links and simple components | | |
| **FL-300 to FL-399** | Wave 3, structure and order | | |
| **FL-400 to FL-499** | Wave 4, focus and keyboard | | |
| [FL-400](#fl-400) | A `CupertinoListTile` with `onTap` takes no keyboard focus, and is not a button on Android and iOS | All (no focus); Android, iOS (no role) | Confirmed |
| [FL-401](#fl-401) | An `InkWell` with `onTap` is not a button on Android and iOS | Android, iOS | Confirmed |
| [FL-402](#fl-402) | A tap is given up by how far the pointer has moved, not by whether it has left the control | All (widget test only) | Confirmed |
| [FL-420](#fl-420) | Tab crosses side-by-side columns row by row by default, and the keyboard's order and the screen reader's are set by separate widgets | All | Confirmed |
| [FL-421](#fl-421) | On the web, Tab past Flutter's last control continues in the document's order, and can go round for ever | Web | Confirmed |
| [FL-422](#fl-422) | On a scrolled screen the default focus order puts the app bar's Back button among the content | All | Confirmed |
| [FL-440](#fl-440) | A `CupertinoAlertDialog`'s actions take no keyboard focus | All | Confirmed |
| [FL-441](#fl-441) | A `CupertinoActionSheet`'s title and message fail text contrast in light mode | All (widget test only) | Confirmed (widget test only) |
| [FL-442](#fl-442) | When a route closes, the framework sends the screen reader back to where it was, after the app's own move, even when that control has been removed | Android | Confirmed in the source; its effect Observed |
| [FL-460](#fl-460) | A shortcut above a text field takes its key before the field can type it, on the web and on iOS, and on Android depending on the device | Web, iOS; Android on CI's emulator, not on the local one | Confirmed |
| [FL-461](#fl-461) | A text field's done, go, search, or send action takes keyboard focus away and gives it to no control | All | Confirmed |
| [FL-463](#fl-463) | A `PageView` takes no keyboard focus and has no keys | Android, iOS, Web | Observed |
| [FL-464](#fl-464) | A `Shortcuts`, `CallbackShortcuts`, or `Focus` around plain text makes that text the name of a node holding every control inside it | Web, iOS (Android not looked at) | Confirmed |
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
- To examine in the links technique (S-group): whether `url_launcher`'s `Link`
  widget is the better documented mechanism.
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
- How to read this entry: these are roles Flutter has not added yet. Treat
  it as unfinished work in the framework, and re-check it whenever the
  pinned version changes.
- Upstream issue: not searched yet.

## FL-027

**A progress indicator whose value has a percent sign reports an empty range on Android.**

- Status: Observed, Flutter 3.47.5, batch 0 probe (`docs/evidence/probes/batch-0/`);
  `material/progress_indicator.dart` read.
- WCAG: 4.1.2 Name, Role, Value.
- What happens: `LinearProgressIndicator(value: 0.4, semanticsValue: '40%')`
  sets `minValue: '0'` and `maxValue: '100'`, and is an
  `android.widget.ProgressBar` whose `RangeInfo` is 0 to 0 with current 0.
  `Semantics(role: SemanticsRole.progressBar, value: '40', minValue: '0',
  maxValue: '100')` gives 0 to 100 with current 40. On web both give
  `aria-valuenow="40"`. The percent sign in the value is the likely cause
  (a value that is not a number); the engine source was not read. Whether the widget's default value, with no `semanticsValue`, has the same
  result was not probed.
- Effect: anything that reads the range gets nothing. The node's description
  still holds the value ("40%, Storage used"); what TalkBack speaks was not
  recorded.
- Workaround: none found yet. To be checked, with TalkBack, in the progress
  indicator technique.
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
- How it is handled here: `walkFromBack` in `web_tests/vo/vo_helpers.js`
  takes a `clickAtPoint` flag for these screens, which clicks with the
  mouse at a position and skips Playwright's check.
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

- Status: Observed, Flutter 3.47.5, in the S13 probe
  (`docs/evidence/probes/s13/`, round 1, fixtures 02, 03, and 20; and
  fixtures 08 and 09 of `docs/evidence/probes/s04/`). No test in the repo
  yet. Engine source read:
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
- Workaround: give `linkUrl` as well, and handle [FL-013](#fl-013) on the
  web. To be built and verified in C03 Stand-alone link.
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

**An obscured text field that is not being edited was read as a plain text field by VoiceOver on iOS.**

- Status: Observed, Flutter 3.47.5, iOS 27.0 simulator: first in the first
  build of the S15 field examples, which were password fields (those
  examples were changed to an ordinary field), and again in the F02 probe,
  whose fixture is kept (below). No test in the repository yet.
- What was seen: for `TextField(obscureText: true)` with VoiceOver's cursor
  moved onto it and the field not being edited, XCUITest reported
  `XCUIElementType.textField` (not `.secureTextField`) and VoiceOver said
  "Password, Text field". On the web the same field was a secure field to
  VoiceOver ("This is a secure text field"), and TalkBack read "password.
  Edit box".
- What is not known: what the field is while it is being edited. Flutter's
  iOS text input plugin sets `secureTextEntry` from `obscureText`, and a
  focused field is represented by the plugin's input view, so the role and
  what VoiceOver echoes may differ there. That was not tested.
- Why it could matter: "secure" tells a VoiceOver user that what they type
  will not be echoed or shown.
- Probed again in F02 (2026-11-18, iOS 27.0 simulator,
  [F02 probe](evidence/probes/f02/README.md), fixture 10): an obscured
  field with a label and a hint, not being edited, was
  `XCUIElementType.textField` and VoiceOver read "i10 Password Text field
  8 characters minimum, …", with no "secure". While it was being edited,
  with "abc" typed, XCUITest reported `.secureTextField` with the value
  "•••". So the element type follows editing; what VoiceOver says during
  editing was not captured (the probe's walk began on the next element).
  Still no test in the repository: F02's examples have no password field,
  to keep this out of a technique about instructions.
- Next: this belongs to F03 (keyboard and input types), which needs a
  password example: VoiceOver's speech for the field while it is being
  edited, and whether "secure" is ever said.
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

<!-- FL-200 to FL-299: Wave 2, links and simple components. Entries in this range go below, in id order. -->

<!-- FL-300 to FL-399: Wave 3, structure and order. Entries in this range go below, in id order. -->

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

## FL-460

**A shortcut above a text field takes its key before the field can type it, on the web and on iOS, and on Android depending on the device.**

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
    edited; not confirmed in the Android source. What `input keyevent`
    letters do in a field is in the I04 Android test's log
    (`badPageShortcutInputKeyeventInTheNoteThenOnTheButton`); in probe
    round 2 they reached neither the framework nor the field.
  - Android, CI's emulator (API 35, `google_apis` image, no hardware
    keyboard in its AVD): the I04 test typing "Leafy" with
    `sendStringSync` got "Leay", so the shortcut took the f there (CI run
    44472632084, `docs/evidence/probes/i04/ci_android_44472632084.txt`).
    Which input method it had, and whether its on-screen keyboard was
    showing, was not recorded.
  The same shortcut away from the field works on all three platforms.
- Other ways to the letter, under a shortcut for a lowercase f, measured
  with `bad-page-shortcut`: on the web Shift+F types a capital F (a
  `CharacterActivator('f')` does not match "F"), and an f pasted with
  Control or Command+V goes in through the browser's own paste (I04 web
  tests). On iOS `typeText`, which sends text the way an on-screen
  keyboard does, puts an f in (probe), and the I04 iOS suite tests
  Shift+F and Command+V.
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
  to add one, breaks typing on the web and iOS and on some Android
  devices and not others, so testing on one Android device may not find
  it.
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

<!-- FL-500 to FL-599: Wave 5, visual preferences. Entries in this range go below, in id order. -->

<!-- FL-600 to FL-699: Wave 6, remaining forms. Entries in this range go below, in id order. -->

<!-- FL-700 to FL-799: Wave 7, dialogs and overlays. Entries in this range go below, in id order. -->

<!-- FL-800 to FL-899: Wave 8, navigation and complex components. Entries in this range go below, in id order. -->

<!-- FL-900 to FL-999: Wave 9, the batch 10 techniques. Entries in this range go below, in id order. -->

<!-- End of the entries. -->
