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
| [FL-007](#fl-007) | `Semantics(identifier:)` inside a button strips the button's name | Android, iOS | Observed |
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
| [FL-028](#fl-028) | A slider has no accessible name on web | Web | Confirmed |
| [FL-029](#fl-029) | A Material `Slider` adds an empty full-screen element that takes pointer events on web | Web | Observed |
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
| [FL-041](#fl-041) | On web a hint on a node with no label is not rendered | Web | Confirmed (source read) |
| [FL-042](#fl-042) | An obscured text field is a plain text field for VoiceOver on iOS | iOS | Observed (source read) |

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
  `web_tests/s13_roles_and_traits.spec.js` requires Space only.
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

- Status: Observed in spike K2, Flutter 3.47.5, Android 17 and iOS 27. The
  spike fixture was removed; no test in the repo reproduces it.
- What happens: `FilledButton(child: Semantics(identifier: 'x', child: Text('Save draft')))`
  produces two nodes on Android and iOS: a `Button` with no name and a
  separate text node carrying the label and the identifier. TalkBack and
  VoiceOver announce just "Button". An identifier added for testing has made
  the control inaccessible (4.1.2).
- Workaround: put the identifier outside the control and merge it:
  `MergeSemantics(child: Semantics(identifier: 'x', child: FilledButton(…)))`.
  This is the project's `TestId` widget (`lib/catalog/test_id.dart`) and gives
  one node with role, name, and identifier on all three platforms. A plain
  outer `Semantics(identifier:)` without `MergeSemantics` makes a separate
  node: a parent of the button on web and Android, a sibling on iOS.
- Upstream issue: not searched yet.

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
- Effect: the CVS iOS techniques for these features cannot be reproduced in
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
  `web_tests/s01_accessible_names.spec.js` (`bad-slider-name-web`) and heard
  in `docs/evidence/S01/voiceover-web.md`. Engine source read:
  `lib/web_ui/lib/src/engine/semantics/incrementable.dart`.
- WCAG: 4.1.2 Name, Role, Value; 1.3.1 Info and Relationships.
- What happens: the framework gives the slider's node its label. On web the
  engine draws that node as a `flt-semantics` element with no role, puts
  `aria-label` on it, and appends an `<input type="range" role="slider">`
  inside it. The input is the element that takes focus and has the role and
  the value, and it gets no `aria-label` and no `aria-labelledby`. Chromium
  computes an empty accessible name for the slider. The same happens for
  `Semantics(label:)` around a `Slider`, for `MergeSemantics` around a
  `Slider` and its text, and for `CupertinoSlider`.
- Not affected: Android (`SeekBar` with description "40%, Volume") and iOS
  (label "Volume", value "40%"). Checkbox, switch, and radio elements on web
  carry `aria-label` on the element that has the role.
- Effect: the slider has no name of its own, so a list of form controls or
  a move by Tab gives a slider and a value with no word on what it adjusts,
  and speech input cannot address it by name. Heard with VoiceOver on macOS
  in Chromium, moving with the VoiceOver cursor: "Volume group" as one stop,
  then "40% dimmed slider". What is spoken when Tab lands on the slider was
  not recorded.
- Also seen, not followed up here: VoiceOver calls the slider "dimmed". The
  engine disables the `input` while the browser is in pointer mode
  (`incrementable.dart`). To check in the slider technique (F10).
- How to reproduce: `/t/S01/bad-slider-name-web` in the app, on web.
- Workaround: none found in the SDK. Not tried: putting the name in the value
  text with `Slider.semanticFormatterCallback`, which would also change what
  Android and iOS say.
- Upstream issue: not searched yet (D25).

## FL-029

**A Material `Slider` adds an empty full-screen element that takes pointer events on web.**

- Status: Observed, Flutter 3.47.5, while recording VoiceOver for
  `/t/S01/bad-slider-name-web`. No test in the repo asserts it. Cause not
  read in the SDK source.
- What happens: on the screen with a `Slider`, the semantics DOM has one more
  `flt-semantics` element than the other S01 screens: no role, no label, no
  children, the size of the whole view (1280 by 720 in the test), with
  `pointer-events: auto`, after the other nodes in document order. It is
  there with and without `divisions`. The other seven S01 example screens,
  which have no slider, have no such element.
- Effect seen: Playwright refuses to click any other semantics element on
  that screen, because this element is on top of it ("intercepts pointer
  events"). Keyboard operation of the slider is not affected (asserted in
  the S01 web test). Whether a person using a mouse, touch, or a screen
  reader's click is affected was not tested.
- Seen on the same screen, not a finding: with Playwright's WebKit build,
  VoiceOver's cursor usually left the page content after the screen title
  and did not reach the slider, with and without a mouse click to put focus
  in the page first. It walked the other seven S01 screens normally, and in
  Chromium it reached the slider. The test cannot tell a fault of the page
  from the test harness losing focus, so this is recorded in
  `docs/evidence/S01/voiceover-web.md` and nothing is asserted. The WebKit
  build is not Safari; Safari was not tried.
- How it is handled here: `walkFromBack` in `web_tests/vo/vo_helpers.js`
  takes a `clickAtPoint` flag for this screen, which clicks with the mouse
  at a position and skips Playwright's check.
- To do in the slider technique (F10): find the widget that creates the
  element, and test pointer and screen reader activation of controls beside
  a slider.
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
- Why it matters: the CVS Health iOS technique lists the keyboard key trait,
  which on iOS lets VoiceOver users type on a custom keypad in the way they
  have chosen for the system keyboard. A Flutter keypad cannot have it. Use
  `button: true` on each key, which is what the SDK's own widgets do.
- Also without a Flutter counterpart, from the same CVS list of traits:
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
  null)` would be read as "off". That is a wrong state (4.1.2) and goes to
  F07 Checkbox to be probed.
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
  subject of the CVS Health Android technique "Custom State Descriptions".
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
  [FL-015](#fl-015)).
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

**On web a hint on a node with no label is not rendered.**

- Status: Confirmed, Flutter 3.47.5, Web (Chromium and WebKit DOM). Seen in
  the [S15 probe](evidence/probes/s15/README.md) (fixtures 02 and 14) and
  asserted through `bad-hint-detached` in `web_tests/s15_hints.spec.js`.
  Engine source read: `LabelAndValue.update()` in
  `lib/web_ui/lib/src/engine/semantics/label_and_value.dart`, which returns
  before `_updateHintDescription` when the computed label is null.
- What happens: a hint becomes `aria-description` on the element. That
  line is reached only when the node has a label, a value, or a tooltip.
  A node with a hint alone gets no description, and since it has no text
  either, the hint is nowhere in the page. Android and iOS read the hint
  of such a node as if it were its name.
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

**An obscured text field is a plain text field for VoiceOver on iOS.**

- Status: Observed, Flutter 3.47.5, iOS 27.0 simulator, in the first build
  of the S15 field examples, which were password fields. No test asserts
  it now: those examples were changed to an ordinary field. Engine source
  read: `SemanticsObject.mm` and `TextInputSemanticsObject.mm` under
  `shell/platform/darwin/ios/framework/Source` have no reference to the
  obscured flag.
- What happens: `TextField(obscureText: true)` is reported by XCUITest as a
  text field (`XCUIElementType.textField`), not a secure text field, and
  VoiceOver reads "Password, Text field". A native `SecureField` is read as
  "Secure text field". On Android TalkBack read "password. Edit box" for
  the same field.
- Why it matters: "secure" tells a VoiceOver user that what they type will
  not be echoed or shown. Without it the field sounds like any other.
- On the web the same field was a secure field to VoiceOver ("This is a
  secure text field").
- Found while building S15. It
  belongs to the text field technique ([F01](techniques/F01.md)) and was
  not explored further here: what VoiceOver echoes while typing in such a
  field was not tested.
- Workaround: none found in the SDK. Flutter has not added a secure text
  field trait on iOS yet.
- Upstream issue: not searched yet (D25).
