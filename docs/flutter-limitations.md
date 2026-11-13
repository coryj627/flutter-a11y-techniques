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
| [FL-003](#fl-003) | `Semantics(header: true)` alone is not a heading for VoiceOver on iOS | iOS | Observed |
| [FL-004](#fl-004) | `header: true` on web is always `<h2>` | Web | Observed |
| [FL-005](#fl-005) | `header: true` with an identifier is not a heading on Android | Android | Observed |
| [FL-006](#fl-006) | Any tappable node is `role="button"` on web | Web | Confirmed |
| [FL-007](#fl-007) | `Semantics(identifier:)` inside a button strips the button's name | Android, iOS | Observed |
| [FL-008](#fl-008) | `IconButton` tooltip is read as a second item by VoiceOver in Chromium | Web (Chromium) | Observed |
| [FL-009](#fl-009) | `textContrastGuideline` checks disabled text | Test framework | Confirmed |
| [FL-010](#fl-010) | Live region text is announced when the screen opens | Android, iOS, Web | Observed |
| [FL-011](#fl-011) | Lazy lists expose only content near the viewport | Web (others not checked) | Confirmed |
| [FL-012](#fl-012) | A web live region announcement can be erased by an earlier one's clear timer | Web | Confirmed (source read) |
| [FL-013](#fl-013) | A web link with `linkUrl` is followed by the browser as well as by `onTap` | Web | Confirmed |

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
- Upstream issue: not found. To be filed.

## FL-003

**`Semantics(header: true)` alone is not a heading for VoiceOver on iOS.**

- Status: Observed in spike K7 (docs/plan.md), Flutter 3.47.5, iOS 27.0
  simulator. No dedicated test yet; S05 Headings must add one.
- WCAG: 1.3.1 Info and Relationships, 2.4.6 Headings and Labels.
- What happens: `Semantics(header: true, child: Text('Spike heading'))` and the
  `AppBar` title were spoken as plain text, with no "Heading".
  `Semantics(headingLevel: 1, …)` was spoken as "Level one Heading". A native
  heading in Apple's Settings app, read through the same API, was spoken as
  "General Heading", so the test API does report the trait.
- Cause: not investigated.
- Workaround: set `headingLevel` (with or without `header: true`). The shell's
  `SectionHeading` does this and is read as "Example Heading"
  (`docs/evidence/C01/voiceover-ios.md`).
- Upstream issue: not searched yet.

## FL-004

**`header: true` on web is always `<h2>`.**

- Status: Observed in spike K3, Flutter 3.47.5. No dedicated test yet (S05).
- WCAG: 1.3.1 Info and Relationships.
- What happens: every `Semantics(header: true)` node becomes `<h2>`, whatever
  its place in the page outline, including the `AppBar` title.
  `Semantics(headingLevel: n)` produces the matching `<h1>`–`<h6>`.
- Workaround: always set `headingLevel`.
- Open question for S05: the `AppBar` title is exposed as `<h2>`
  ("heading level 2 Text buttons" in `docs/evidence/C01/voiceover-web.md`), so
  a screen has no `<h1>` unless the app adds one.
- Upstream issue: not searched yet.

## FL-005

**`header: true` with an identifier on the same node is not a heading on Android.**

- Status: Observed in the Phase 1 instrumented spike, Flutter 3.47.5,
  Android 17 emulator. No dedicated test yet (S05).
- What happens: `Semantics(header: true, child: Text(…))` reports
  `AccessibilityNodeInfo.isHeading == true` and TalkBack says "Heading". The
  same widget with `identifier:` set, or wrapped in the project's `TestId`,
  reports `isHeading == false` and TalkBack does not say "Heading". With
  `headingLevel` set, the identifier makes no difference and it is a heading.
- Cause: not investigated.
- Workaround: set `headingLevel`.
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

- Status: Observed, Flutter 3.47.5. TalkBack on Android 17.
- What happens: a `Semantics(liveRegion: true)` node that is present when a
  route opens is announced immediately ("Activations: 0"), before the user
  has done anything. On Android the announcement can also interrupt or delay
  speech for the element that receives focus.
- Why it matters: 4.1.3 Status Messages is about changes; reading initial
  content is noise. To be examined properly in I12 Announcements, including
  whether iOS and web do the same.
- Workaround: none applied.
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
