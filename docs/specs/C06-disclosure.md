# Spec: C06 Disclosure

Status: Draft 1 (2026-11-23), written with the build. Wave 2, links and
simple components. Flutter pin: 3.47.5.

A disclosure is one control that shows and hides one section of content:
APG's Disclosure (Show/Hide) pattern, HTML's `details` and `summary`. A set
of such sections, each with a header, is [C05 Accordion](C05-accordion.md).
What a button is, is [C01 Button](C01-button.md); how focus is shown, V14.

## 1. Rule

The control that shows and hides a section is a button whose name says what
it shows, that says whether the section is shown (expanded or collapsed),
and that touch, the keyboard (Enter and Space), and a screen reader each
operate. A hidden section is neither read nor focused; a shown one comes
straight after the control.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Limitation | Limitation | Limitation |

The owner's decision (2026-11-23): the good example is Flutter's own
`ExpansionTile(internalAddSemanticForOnTap: true)`, through its documented
parameters, with no hand-built header and no custom solution. Its missing
expanded or collapsed state is recorded as a Flutter limitation on all three
platforms (`PlatformStatus.limitation`), and the state it gives as text, at
the end of its name on Android, as a hint on iOS, and as the accessible
description on the web, is not counted as meeting 4.1.2
([FL-264](../flutter-limitations.md#fl-264); on iOS also
[FL-260](../flutter-limitations.md#fl-260)). Measured on Android 17, iOS
27.0, and Chromium; on Android before 16 Flutter passes no expanded state
to any node (FL-261, source read), which was not measured here.

`internalAddSemanticForOnTap` is what makes the control a button on Android
and iOS (measured on Android 17 and iOS 27.0; without it the control is a
button on the web only). Its documentation calls it "a temporary flag to
help changing the behavior of ListTile onTap semantics", and the source has
a note to remove it after its default is flipped to true (source read). It may change or go in a later
Flutter.

No workaround is built. A native `details` element in an `HtmlElementView`
on the web (D31, D32) was not tried: the catalog has no kind for a
workaround example yet.

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [4.1.2 Name, Role, Value](https://www.w3.org/TR/WCAG22/#name-role-value) | The control has a name and a role (button) that assistive technology can read, and a state (expanded or collapsed) that it can read and is told of when it changes |

`bad-cupertino-expansion-tile` also fails 2.1.1 Keyboard, outside the
entry's criterion (section 5).

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | The control is a button | [APG Disclosure](https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/) (the element that shows and hides the content has role `button`); [MDN `summary`](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/summary) (clicking the `summary` toggles its `details` element open and closed) |
| R2 | The control says whether the content is shown: expanded or collapsed, changed when it is activated | APG (`aria-expanded` true while the content is visible, false while it is hidden); [MDN `details`](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/details) (the `open` attribute says whether the contents are shown); in the probe, Chromium exposes it as `expanded` on the `summary` |
| R3 | The control's name says what it shows | 4.1.2 (a name that can be programmatically determined); MDN `summary` (a summary, caption, or legend for the disclosure box) |
| R4 | Enter and Space show and hide the content; the control is in the Tab order | APG (Enter and Space each activate the control and toggle the content); MDN `summary` names no key |
| R5 | Hidden content is hidden for everyone, and shown content comes after the control | APG (`aria-expanded` false while the content is hidden); MDN `details` (the contents are shown only while it is open) |

APG's `aria-controls` from the button to the content is optional and is
not covered. No reference repository has a
disclosure entry (the inventory's row for C06 has none for iOS, Android
View, or Android Compose).

The plain HTML comparison in the probe
([evidence/probes/c06](../evidence/probes/c06/README.md), `web.txt`, the
`html` lines): Chromium exposes a `summary` as a `DisclosureTriangle` with
`expanded: false`, then `true` once open; Tab reaches it, Enter opens it,
Space closes it. APG's `<button aria-expanded="false">` is a button with
`expanded: false`.

Flutter references for the mechanisms used:

- [`ExpansionTile`](https://api.flutter.dev/flutter/material/ExpansionTile-class.html) and [`ExpansionTile.internalAddSemanticForOnTap`](https://api.flutter.dev/flutter/material/ExpansionTile/internalAddSemanticForOnTap.html)
- Measured and not used for a good example: [`ExpandIcon`](https://api.flutter.dev/flutter/material/ExpandIcon-class.html), [`CupertinoExpansionTile`](https://api.flutter.dev/flutter/cupertino/CupertinoExpansionTile-class.html); C05 measured [`ExpansionPanelList`](https://api.flutter.dev/flutter/material/ExpansionPanelList-class.html) and [`Expansible`](https://api.flutter.dev/flutter/widgets/Expansible-class.html)

Radix comparison bar: Radix Collapsible, a trigger button with
`aria-expanded` and `aria-controls` for one panel. The native element is
`details` with `summary`.

## 5. Examples

Every example is one disclosure, "Details", closed when it opens. Its
panel holds a line of text, "Orders ship in two days.", and a button,
"Change address"; the count under the disclosure, "Presses: n", says how
often that button was pressed, so that a test can tell a key reached it.
The Cupertino tile's panel has no button (below). No example has a
`TestId`: its `MergeSemantics` would take the open panel into the
control's node, as C05 found for the same widgets; the control is found by
its text on every layer.

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-material` | Material | Material's `ExpansionTile` as a button | `ExpansionTile(internalAddSemanticForOnTap: true)` with a `Text` title and its own panel (built only while open, its default), nothing else | R1, R3, R4, R5; R2 only as text (a limitation, section 2) |

`good-material` is not a custom solution: it is a Flutter widget through
its own documented parameters, and nothing is built round it
([custom-solutions.md](../custom-solutions.md#c06-disclosure)). It is good
with a limitation on every platform: it exposes no expanded state (FL-264),
and its focus indicator is `ListTile`'s tint, under 3:1
([FL-430](../flutter-limitations.md#fl-430); 1.32:1 in light mode and
1.46:1 in dark in the widget tests here,
`docs/evidence/probes/c06/focus_widget_test.txt`). It relies on a parameter its
documentation calls "a temporary flag".

No Cupertino good example: `CupertinoExpansionTile`, the only disclosure
widget found in the SDK's Cupertino library (source read), takes no
keyboard focus
([FL-265](../flutter-limitations.md#fl-265)), so it is
`bad-cupertino-expansion-tile`. No widgets-layer good example:
`Expansible`, the widgets layer's own, takes its header from a builder the
app supplies (source read), so a header would have to be built by hand,
which the owner's rule rules out.

### Bad

| Slug | Defect | Violates |
| --- | --- | --- |
| `bad-expansion-tile` | `ExpansionTile` as it comes: on Android and iOS the control is not a button (FL-264) | R1 |
| `bad-expand-icon` | Material's `ExpandIcon` beside its label, merged with it in a `MergeSemantics` as its documentation says: nothing says whether the section is open, not even in words ([FL-267](../flutter-limitations.md#fl-267)) | R2 |
| `bad-cupertino-expansion-tile` | `CupertinoExpansionTile` as it comes: a keyboard cannot reach the control, so it opens nothing (FL-265) | R4 |

The SDK widgets are shown as they come, each with one named defect. Their
other measured shortcomings, which are not their named defects:

- `bad-expansion-tile`: the same missing state as `good-material` (the
  state only as text); the same focus tint (FL-430).
- `bad-expand-icon`: a tap on the label opens nothing, as only the icon
  takes pointer input (widget tests; on iOS 27.0 XCUITest's tap at the
  element's middle); on the web a mouse click at the element's middle
  opened it (probe and web tests), as a click there is taken by the
  node's element ([FL-411](../flutter-limitations.md#fl-411)); on Android a
  tap at the label was not tried. On Android
  its click label stays "Expand" once open
  ([FL-280](../flutter-limitations.md#fl-280)). Its focus tint is
  `IconButton`'s (FL-430; 1.26:1 and 1.38:1 here, `focus_widget_test.txt`).
- `bad-cupertino-expansion-tile`: no button role on Android and iOS; no
  state word on Android (TalkBack says only the click label), and on the web where Flutter finds Linux
  or Windows (measured with `navigator.platform` set to them); the state as
  a hint on iOS and, on the web, as the description where Flutter finds
  macOS; once open the
  panel's text joins the control's name; once opened, an empty element
  over the page on the web ([FL-029](../flutter-limitations.md#fl-029),
  as C05 found). Its panel has no button, so that a closed panel, which
  the tile keeps `Offstage`, has nothing to take keyboard focus
  ([FL-263](../flutter-limitations.md#fl-263)); its count stays 0.

What each example fails, by platform, as the criteria are written, with
the owner's ruling that the state as text does not meet 4.1.2:

| Example | Android | iOS | Web |
| --- | --- | --- | --- |
| `good-material` | 4.1.2: no state (the limitation) | 4.1.2: no state (the limitation) | 4.1.2: no state (the limitation) |
| `bad-expansion-tile` | 4.1.2: not a button (`View`), and no state | 4.1.2: static text, and no state | 4.1.2: no state, as `good-material`; its named defect is not on the web, where it is a button ([FL-006](../flutter-limitations.md#fl-006)) |
| `bad-expand-icon` | 4.1.2: no state, in no words | 4.1.2: no state, in no words | 4.1.2: no state, in no words |
| `bad-cupertino-expansion-tile` | 2.1.1: the control takes no keyboard focus; 4.1.2: not a button, no state | 2.1.1; 4.1.2: static text, no state | 2.1.1; 4.1.2: no state |

`good-material` and `bad-expand-icon` fail the same criterion on every
platform. What tells them apart is what a user hears: `good-material`
says "Collapsed" or "Expanded" in words, and announces the change;
`bad-expand-icon` says neither word, and announces nothing on Android
and iOS: on Android 17 the six seconds after its click action are a
declared silent row of the TalkBack walk, with live rows before and after
(L4 TalkBack); on iOS 27.0 the four seconds after XCUITest's double tap
opened it are judged silent, with live readings before and after (L4
VoiceOver iOS). On the web it was not tested: in the probe nothing was
written to the web's announcement elements when it opened.

2.1.1 Keyboard, outside the entry's criterion, is claimed for
`bad-cupertino-expansion-tile` because it fails as written and the tests
show that no keyboard path opens it: the control has no focus state in the
semantics tree (widget tests) and no `tabindex` on the web; a whole cycle
of focus, by Tab and by Shift+Tab, stops only on Back, where Enter and
Space leave the example, while the same cycle visits `good-material`'s
control (widget tests, the web, Android); and on iOS one, two, or three
Tabs, and on iOS 27 one, two, or three Shift+Tabs, and then Enter or Space
never open it and leave the example, while Tab opens `good-material` and
Shift+Tab moves back onto its control. It opens only by a pointer or a screen
reader's tap action. 2.1.1's exception (input that depends on the path of
the user's movement) does not apply.

1.4.11 Non-text Contrast and 2.4.7 Focus Visible are not claimed for the
focus tint: FL-430 says why the verdict for a control with no visible
container rests on where its edge is taken to be, and C06's criterion is
4.1.2.

## 6. Assertions by layer

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Every example, closed and open: at 200% text on a 320 by 640 screen, no layout overflow and no text cut short (line limit or box); in light and dark, the text contrast guideline. `good-material`, closed and open, in light and dark: the four guidelines. `good-material`: the control is the only button but Back, named "Details", focusable, with a tap action, hint "Collapsed" and tap hint "Expand for more details", no value, and no expanded state; no panel while closed and the reading order "Details" alone; open, hint "Expanded", tap hint "Collapse", still no expanded state, and the reading order "Details", the panel's text, its button; on Android a live region "Collapsed", then "Expanded"; as iOS, hint "Collapsed\n double tap to expand", no announcement straight after the tap action and "Expanded" announced a second later; the tap action opens and closes it; Tab stops are Back, then the control, and Enter, and in another test Space, opens it and closes it with focus kept on it; once open the next Tab goes to the panel's button and Enter presses it (the count). Focus, for `good-material`, `bad-expansion-tile`, and `bad-expand-icon`, closed and open, light and dark: keyboard focus changes pixels on the control, and none of them is 3:1 against what was there before (FL-430). `bad-expansion-tile`, as Android and as iOS: no button flag, no expanded state, before and after a tap that opens it. `bad-expand-icon`: a button named "Details" with no expanded state, no hint, no value, and no live region, before and after its tap action opens it; its tap hint "Expand", then "Collapse"; a tap on the label opens nothing and a tap on the icon opens it. `bad-cupertino-expansion-tile`: no button, no focus state, no expanded state, a tap action, and once open its label "Details\nOrders ship in two days."; a whole cycle of focus, Tab until Back has had focus twice (at most eight presses), stops only on Back with the panel closed, and Enter, and in another test Space, then take the app back (the key acted); the same with Shift+Tab and Enter. The positive control: the same cycle on `good-material` stops on Back, the control, Back with Tab, and on the control, Back, the control, Back with Shift+Tab |
| L3 web | `good-material` and `bad-expansion-tile`: a button named "Details" with no `aria-expanded`, and the description "Collapsed double tap to expand", then "Expanded double tap to collapse", where Flutter's engine finds macOS, and "Collapsed", then "Expanded", on Linux and Windows; the control and Back the only buttons; no panel in the page while closed; a click opens it with the panel straight after it in DOM order, and a second closes it; each also with `navigator.platform` set to "MacIntel", "Linux x86_64", and "Win32". `good-material`: a DOM click with no pointer events opens it; a click writes "Expanded", then a second "Collapsed", to `flt-announcement-polite`; Tab stops are Back and the control, and Enter, and in another test Space, open and close it with focus kept on it; once open, the next Tab goes to the panel's button and Enter presses it. `bad-expand-icon`, as the page's platform has it and with each of the three set: a button named "Details" with no `aria-expanded`, no `aria-description` and an empty description, before and after a click that opens it; Tab and Enter, and Space, open it. `bad-cupertino-expansion-tile`: a whole cycle of focus, Tab until Back has had focus twice (at most ten presses), stops on Back alone in Flutter's tree (stops on the page itself left out, FL-421), with the panel closed, and Enter, and in another test Space, on Back where the cycle ended, leave the example; the same with Shift+Tab and Enter; the positive control, the same cycles on `good-material`, Tab and Shift+Tab, each visit the control; its control has no `tabindex` and no `aria-expanded`, the description "Collapsed double tap to expand" on macOS and none on Linux and Windows, and once a click has opened it one button "Details Orders ship in two days.", still with no `aria-expanded` or `tabindex`. Every example: no empty element over the page while closed; once opened, one for `bad-cupertino-expansion-tile` and none for the others. Also: the VoiceOver walk judge on made-up walks, and that each screen shows the texts the judge expects |
| L3 Android | `good-material`: a `Button` named "Details, Collapsed", focusable, click label "Expand for more details", on Android 16 and later expanded state "undefined", no expand or collapse action, a live region "Collapsed", the only clickable node but Back, no panel while closed, and the reading order "Details, Collapsed" alone; `ACTION_CLICK` opens it ("Details, Expanded", click label "Collapse", still no state, a live region "Expanded", the panel's text and button straight after it) and a second closes it; a tap opens it; Tab to it and Enter, and in another test Space, open and close it with focus kept on it; once open the next Tab goes to the panel's button and Enter presses it (the count). `bad-expansion-tile`: a `View` "Details, Collapsed" with no state, before and after a click that opens it. `bad-expand-icon`: a `Button` "Details" with no state description, no hint, no expanded state, click label "Expand", no live region; after a click that opens it, read for two seconds, the same, the click label still "Expand" (FL-280). `bad-cupertino-expansion-tile`: a whole cycle of focus, Tab until Back has had focus twice (at most eight presses), with the control's focus read at every stop, stops on Back alone (or on no node), with the panel closed, and Enter, and in another test Space, on Back where the cycle ended, leave the example; the same with Shift+Tab (sent as I02 sends it) and Enter; the positive control, the same cycles on `good-material`, Tab and Shift+Tab, each visit the control; the control is a `View` with no state, opened by the click action, after which its name is "Details\nOrders ship in two days." |
| L3 iOS | `good-material`: a button "Details" with no value, the only button but Back, no panel while closed; a tap opens it, the panel's text and button below it on screen, still no value, and a second tap closes it; two Tabs and Enter, and in another launch Space, open it and the same key again closes it, staying on the example; once open, one Tab and Enter press the panel's button (the count). `bad-expansion-tile`: not a button, no value, no button but Back, opened by a tap. `bad-expand-icon`: a button with no value; a tap at its middle opens nothing and a tap at its icon, in the same launch, opens it, still with no value. `bad-cupertino-expansion-tile`: not a button, no value, opened by a tap, after which one element, not a button and with no value, has a label that starts with "Details" and holds the panel's text; one, two, and three Tabs and then Enter or Space, each from a fresh launch, never open it and take the example off the screen (Back acted); on iOS 27 and later, one, two, and three Shift+Tabs and then Enter do the same; the positive control, on `good-material`: two Tabs and Enter open it, one Tab more, then one Shift+Tab and Enter close it, with the panel's button not pressed and the example still on screen, so Shift+Tab came back onto the control. A first version of that control, one Shift+Tab from launch and Enter, left the example, as Enter on Back does (`docs/evidence/probes/c06/ios-shift-tab-first-run.txt`) |
| L4 TalkBack | For each example: what is said with focus on the control, closed; on the click action with focus left there (for `bad-expand-icon` and `bad-cupertino-expansion-tile` a declared silent row, `"(must be silent)"`, logged once the click action has returned: nothing at all may be said in its six seconds, its capture must be ended by the next marker, and the row after it, the panel's text or Back, is its liveness control and must be right); with focus on the panel's text (on Back for `bad-cupertino-expansion-tile`, whose open panel is part of its control); and on the control again, open. Judged whole (`STRICT` in `tool/talkback.py`) |
| L4 VoiceOver iOS | Every utterance after the "Example" heading to the end of the screen, compared as a whole list, closed, and again after XCUITest's double tap at the control, with VoiceOver on, has opened it; and what is said on that change, judged from raw reads (`C06Speech.judge`): with the cursor on the control, the reading before must be the control's closed utterance; then eight reads of `currentSpeech()`, half a second apart, every one readable (a failed or an empty read fails). For `good-material` and `bad-expansion-tile` every read must be the control's utterance or "Expanded", and "Expanded" must be read; for `bad-expand-icon` and `bad-cupertino-expansion-tile` every read must be the control's utterance (silence: with VoiceOver on, `currentSpeech()` keeps giving the last utterance, as C26's probe measured), and the reading after a move on must be the next stop. The expected utterances must differ and be under 64 characters. The judge is tested with no device on named cases (a missing, wrong, failed, empty, or stale announcement; a silence with a dead or wrong reading after) and on every shape of reading before crossed with every shape of one read (`testSpeechJudge…`). The gesture is a tap at the control's place, not VoiceOver's activation, which XCUIVoiceOverService has no way to make (C04 probe round 3) |
| L4 VoiceOver web | Every stop of VoiceOver's cursor from Back to the end of the screen, judged as C05's walks are (`judgeExampleWalk` in `web_tests/vo/c06_vo_walks.js`): the whole screen in order, the title, the description, a bad example's defect, the heading, and every stop after it; a walk that reached the end with a stop missing, or with any stop wrong, fails for good; only a walk cut short with every stop right so far is walked again, up to three times, and every try is logged; no runner retries. Closed, and after a click has opened it, in Chromium and WebKit. The first recording (`docs/evidence/C06/voiceover-web.md`) passed: every walk complete and as expected on its first walk, in both browsers, with the same readings in each |

## 7. What the build found (Flutter 3.47.5)

The probe that came first is in [evidence/probes/c06](../evidence/probes/c06/README.md):
four fixtures on the web (Chromium), Android 17, and iOS 27.0, with
TalkBack and VoiceOver, and plain HTML on the web. It measured what a
single disclosure needs that C05's probe had not.

- **None of Flutter's widgets for a disclosure measured here exposes an
  expanded state, on any platform** (FL-264, FL-265, FL-267; C05 found the
  same for `ExpansionPanelList`, and in the SDK's source no other widget
  for the pattern sets `expanded`): no `aria-expanded` on the web,
  expanded state "undefined" on Android 17, no value on iOS 27.0. Where the
  state reaches a screen reader, it is text. That is the limitation the
  owner recorded on all three platforms.
- **`internalAddSemanticForOnTap: true` makes `ExpansionTile` a button on
  Android 17 and iOS 27.0, and changes nothing else that was measured**
  (FL-264, extended): the same hint (widget tests, Chromium), the same
  live region on Android, the same "Expanded" from TalkBack and from
  VoiceOver on iOS after the change, and the same writes to the web's
  announcement element (probe). On iOS
  27.0 VoiceOver reads it "Details Button Collapsed double tap to expand",
  the same words, in the same place after "Button", as UIKit's own
  expanded status in C05's probe ("Button Collapsed Double-tap to
  expand"); there it is the tile's hint, and XCUITest shows no value.
- **`ExpansionTile` announces the change on every platform measured**:
  TalkBack says "Expanded" on the click from the tile's live region, and
  "Collapsed" on a second click (probe), on Android 17; VoiceOver on iOS
  27.0 says "Expanded" after XCUITest's double tap opened it (asserted
  from raw reads since review: from the second read of eight, half a
  second apart, in `docs/evidence/C06/voiceover-ios.md`; closing was not
  listened for; the widget tests show the one-second timer); and on
  the web "Expanded" and "Collapsed" are written to
  `flt-announcement-polite` on a click, Enter, and Space (Chromium). What
  VoiceOver on macOS says for that write was not listened for separately:
  the web walks start after the click.
- **`ExpandIcon` with its label (`bad-expand-icon`) has no state in any
  words** (FL-267, extended), and on Android 17 its click label stays
  "Expand" once open (FL-280; cause not found), while the widget tests
  show it change.
- **`CupertinoExpansionTile` takes no keyboard focus** (FL-265), as C05
  found in its accordion: on the web, Android 17, iOS 27.0, and in the
  widget tests.
- **The transcripts.** TalkBack (`docs/evidence/C06/talkback-android.md`)
  passed on its first walk, judged whole, the declared silent rows of
  `bad-expand-icon` and `bad-cupertino-expansion-tile` included (nothing
  said in either, and both liveness rows right): `good-material` "Details, /
  Collapsed / Button / Double-tap to Expand for more details", "Expanded"
  on the click, and open "Details, / Expanded / Button / Double-tap to
  Collapse"; `bad-expand-icon` "Details / Button / Double-tap to Expand",
  closed and open. The first iOS VoiceOver run
  (`docs/evidence/probes/c06/voiceover-ios-first-run.md.txt`) heard every
  reading as expected but one: the open Cupertino tile's control and panel
  text are one utterance longer than the 64 characters
  `XCUIVoiceOverService` returns, and it was cut ("… Expanded double tap
  to collaps"), as C05 found for the same tile. The expectation is now that
  cut reading; the transcript is from the second run. VoiceOver on macOS
  (`docs/evidence/C06/voiceover-web.md`) passed on its first recording,
  every walk complete on its first try, with the same readings in Chromium
  and WebKit: `good-material` and `bad-expansion-tile` "Details Collapsed
  double tap to expand button", then "Details Expanded double tap to
  collapse button"; `bad-expand-icon` "Details button", closed and open;
  the open Cupertino tile "Details Orders ship in two days. Expanded double
  tap to collapse button". On iOS, `bad-expand-icon` and
  `bad-cupertino-expansion-tile` were silent in the four seconds after
  XCUITest's double tap opened them: every one of the eight reads was the
  control's own utterance, and the move on read the next stop (the
  transcript's double-tap rows, judged by `C06Speech`).
- **The focus indicator is the SDK's tint**: `ListTile`'s on
  `good-material` and `bad-expansion-tile`, `IconButton`'s on
  `bad-expand-icon`, none of it 3:1 against what was there (FL-430).

C06's Android tree tests were run once at the CI emulator's size, 320 by
640 at 160 dpi, on the local emulator (Android 17), and both were reset
after: 12 tests, none failed, `talkBackWalk` skipped with TalkBack off
(`docs/evidence/probes/c06/android_320x640.txt`). That is not a run on
CI's API 35 emulator, whose branch of the expanded-state checks (no state
read before Android 16) runs only there.

Skips and what they give up, in the tests:

- The widget tests run as Android (`kIsWeb` false), but for one test of
  `good-material` and one of `bad-expansion-tile` that set the iOS target
  platform; the web's description is tested in the web tests only.
- The focus measure in the widget tests reads only the pixels in the
  control's box grown by 4 pixels on each side, and counts a pixel as
  changed only if a channel moved by more than 2. It gives up anything
  focus draws further out, and changes of 2 or less in every channel.
  It compares each changed pixel with its own colour before focus, at the
  same place, and does not look for the colour next to it, as V14's
  measure does.
- Android's expanded state is read on Android 16 and later only (it does
  not exist before); on CI's API 35 emulator the tests check the rest,
  and give up the check that there is no state.
- The TalkBack silent rows of `bad-expand-icon` and
  `bad-cupertino-expansion-tile` start once the click action has
  returned, so anything TalkBack says during the click itself, before the
  marker, is not in them; they last six seconds. In the recording
  (`docs/evidence/C06/talkback-android.md`) both were silent and both
  liveness rows right, on the first walk. On the web, that
  `bad-expand-icon` announces nothing is not asserted: no check of
  silence with a liveness control was written there; its missing state is
  in its attributes.
- TalkBack's expectations match words as substrings: the tile's
  "Collapsed", part of its name, cannot be told from a state word
  "collapsed", so the closed readings do not forbid "collapsed"; a state
  Flutter starts to give would be caught by "fully expanded" on the
  change, which is forbidden. The tree tests check the state itself.
- The iOS tests cannot see Flutter's keyboard focus, so where Tab goes is
  shown by what a key then does: the control opening after two Tabs, the
  count going up after one more, and the example leaving the screen
  (Back acted) in `bad-cupertino-expansion-tile`. They rely on the first
  Tab being on Back.
- The focus cycles stop at the second time Back has focus, at most eight
  presses (ten on the web). A control that only a longer cycle reaches
  would be missed; the positive control shows the cycle reaching
  `good-material`'s control within it. The Android cycle accepts a stop on
  no node of the app; the control's own focus is read at every stop, so
  it cannot have focus there unseen.
- The iOS Shift+Tab tests are skipped below iOS 27, as I02's, I04's, and
  I08's modifier-key tests are: CI's iOS 26.5 gives up that check.
- Where a test turns a missing reading into a value, and what it gives
  up (the sweep after review): on iOS a missing `value` is read as ""
  and an expected "" means no value, so no value and an empty one are not
  told apart; on Android a missing state description or hint is read as
  "" with the same meaning, and a node with no click action has the click
  label "", which no test expects; Android's focus cycle reads "(none)"
  where no node of the app has input focus, and reads the control's own
  focus at every stop; the web's focus reading gives "(page)" for the
  page itself, left out by the cycle (FL-421). No speech read is turned
  into an empty value: the iOS walk handles VoiceOver's "no speech" error
  as the shared walk does (`VoiceOverWalk.afterNoSpeech`), and any other
  error fails the test; the change readings keep a failed read as failed
  (`C06Speech`). Everything the tests log is also asserted.
- `bad-expand-icon` is tapped at its icon, 24 points in from the end of
  its row, on iOS (and by `ExpandIcon` in the widget tests), as a tap at
  its label opens nothing there. On Android it is opened by the click
  action; a tap was not tried.
- The iOS VoiceOver walk goes to the end of the screen, where moving on
  gives the last utterance again, twice (`C06Walk`, tested with no device
  by `testWalkToTheEndSeesAnExtraStop`). It gives up two neighbouring
  elements that VoiceOver reads alike, which it would count as one; no
  example has two.
- The web VoiceOver spec's open walk of `bad-cupertino-expansion-tile`
  starts with a mouse click at the "Example" heading's place, not
  Playwright's checked click on it, and on a fresh load, as C05's spec does
  for the same widget: the empty element over the page refuses the checked
  click (FL-029), and in C05's WebKit probe a second walk on one load of
  that tile did not walk the page. Both change only where the walk starts.
- The web test of `bad-cupertino-expansion-tile`'s Tab stops leaves out
  stops outside Flutter's tree (the page itself, FL-421). It gives up
  nothing a key could act on in the app.
- The web tests of the tiles' descriptions read the platform from
  `navigator.platform` in the page, as Flutter's engine does, and also run
  with it set to "MacIntel", "Linux x86_64" and "Win32" before the app
  starts. A set value gives Flutter's own choice for that platform; it is
  not a browser on that system. A browser on Android is not covered (the
  tests fail there).

**Not done yet.** A web workaround with a native `details` element in an
`HtmlElementView` (D31, D32), which needs a workaround kind in the catalog;
Android before 16, on a device; what VoiceOver on iOS says and does on its
own double tap, made by a person; what VoiceOver on macOS says for the
announcement written on a change; what TalkBack's actions menu offers;
`aria-controls`, which APG makes optional.
