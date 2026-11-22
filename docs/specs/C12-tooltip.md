# Spec: C12 Tooltip

Status: Draft 1 (2026-11-21), written with the build. Wave 2, links and
simple components. Flutter pin: 3.47.5.

A tooltip: text that appears when a pointer rests on a control, or after a
long press on it, and says what the control does or adds to its name. The
source material is Flutter's own `Tooltip` and `IconButton.tooltip`. By the
owner's rule of 2026-11-21 every example is the framework's widget,
configured only through its own documented parameters; where the widget
cannot meet a requirement, that is a limitation entry and nothing is built
to fill it. Naming an icon button is S01, S04, and C01's subject; hints are
S15's; Escape across components is I08's; a popover with content of its
own is C11's.

## 1. Rule

A tooltip appears on hover and on a long press, and where it can on
keyboard focus; the pointer can move onto it without it going; Escape hides
it; it stays until the pointer or focus leaves, or it is dismissed; its
words reach a screen reader once, as the control's name or as its
description; and the control it is on keeps its own name and role.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies, with limitations | Applies, with limitations | Applies, with limitations |

What the framework's tooltip cannot do, by platform, with no workaround in
the SDK. Whether any of these makes a platform `PlatformStatus.limitation`
is the owner's decision (section 8); the catalog says "applies" with a note.

- **All: it never shows on keyboard focus**
  ([FL-248](../flutter-limitations.md#fl-248)). No 1.4.13 failure as
  written, as nothing appears on focus; but a keyboard user never sees a
  tooltip, and a sighted keyboard user does not see the words that are an
  icon button's name.
- **All: while shown, its text is read as one more item**
  ([FL-249](../flutter-limitations.md#fl-249)).
- **Web: Escape does not hide it while the page has no keyboard focus**
  ([FL-482](../flutter-limitations.md#fl-482)). Where the tooltip covers
  content (every example here: it lies over the line under its control),
  that fails 1.4.13's dismissible condition for a pointer user on a page
  with no focus, on every Flutter tooltip, good examples included. With
  focus in the page, Escape hides it.
- **iOS and the web: a tooltip is part of the control's name**, not its
  description ([FL-251](../flutter-limitations.md#fl-251)); on the web it
  comes first.
- **iOS: VoiceOver passes over a node whose only text is a tooltip**
  ([FL-252](../flutter-limitations.md#fl-252)).

Touch (Android, iOS): a tooltip shows on a long press and goes 1.5 s after
the touch ends (`showDuration`'s default). 1.4.13 is about content shown by
pointer hover or keyboard focus, and a long press is neither, so it does
not apply to that, and no criterion is claimed for the 1.5 s; the
Understanding document does not mention touch. Android has hover with a
mouse: the probe and the Android tests inject one, and there 1.4.13
applies as on the web. iOS hover (a pointer on iPad) was not measured;
XCUITest has no hover.

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [1.4.13 Content on Hover or Focus](https://www.w3.org/TR/WCAG22/#content-on-hover-or-focus) | A tooltip is content that a hover shows |
| [4.1.2 Name, Role, Value](https://www.w3.org/TR/WCAG22/#name-role-value) | The tooltip's words are a control's name or description, and the control keeps its role |

1.4.13, as written: where receiving and then removing pointer hover or
keyboard focus triggers additional content to become visible and then
hidden,

- **dismissible**: a mechanism dismisses it without moving pointer hover or
  keyboard focus, "unless the additional content communicates an input
  error or does not obscure or replace other content". The Understanding
  document gives Escape as the example mechanism. Every example's tooltip
  lies over the line of text under its control, so the exception does not
  apply to them.
- **hoverable**: if pointer hover can trigger it, the pointer can be moved
  over it without it disappearing. No exception but the one below.
  [F95](https://www.w3.org/WAI/WCAG22/Techniques/failures/F95) is the
  failure.
- **persistent**: it stays until the trigger is removed, the user
  dismisses it, or it is no longer valid.
- The exception: content whose visual presentation is controlled by the
  user agent and not modified by the author. That covers HTML's `title`
  tooltip; it does not cover a Flutter tooltip, which the app draws.

Also used: 2.1.1 Keyboard, for `bad-hover-only`, where the tooltip is the
only place a rule is (section 5).

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | The tooltip appears on hover and on keyboard focus, and Escape dismisses it, with focus staying on the control | [APG Tooltip](https://www.w3.org/WAI/ARIA/apg/patterns/tooltip/) (marked a work in progress without task force consensus: it shows when its element has keyboard focus or the mouse is over it; Escape dismisses it; focus stays on the element) |
| R2 | The pointer can move onto the tooltip, and it stays until hover or focus leaves or it is dismissed | 1.4.13, [Understanding 1.4.13](https://www.w3.org/WAI/WCAG22/Understanding/content-on-hover-or-focus.html), F95 |
| R3 | The tooltip's words describe the control, and reach assistive technology once | APG (the trigger references the tooltip with `aria-describedby`), [MDN `title`](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Global_attributes/title) (a `title` tooltip is "highly problematic" for touch, keyboard, and screen reader users), Flutter's `Tooltip` documentation (its message "can be vocalized by a screen reader") |
| R4 | The control keeps its own name and role, and works by touch, keyboard, and screen reader | 4.1.2; C01 |
| R5 | Information is not only in a tooltip that a keyboard or a screen reader cannot reach | Understanding 1.4.13 (hover content should also be triggerable by focus; 2.1.1), MDN `title` |

The reference repositories have no tooltip: Android View and Android
Compose have no entry, and iOS has [TipKit](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/TipKit.md),
which is a different thing: an onboarding tip, a popover or an inline view
that the app shows once to point at a feature, with a close button, not
shown on hover or focus. Its advice is to give the tip view a label and a
hint that say what it is, and to return VoiceOver's focus to the control
when it is dismissed. 1.4.13 does not apply to it as such, since no hover or
focus shows it. What carries over to C12: the tip's words must reach the
screen reader as something that says what they explain (R3). The rest, a
dismissable view with focus put back, is C11 Popover's.

HTML's `title` attribute, the inventory's comparison, is a tooltip the
browser draws: 1.4.13's exception covers it, and MDN advises against it for
touch, keyboard, and screen reader users. A Flutter tooltip is drawn by the
app, so the exception does not cover it.

Flutter references for the mechanisms used:

- [`Tooltip`](https://api.flutter.dev/flutter/material/Tooltip-class.html),
  [`Tooltip.ignorePointer`](https://api.flutter.dev/flutter/material/Tooltip/ignorePointer.html),
  [`Tooltip.excludeFromSemantics`](https://api.flutter.dev/flutter/material/Tooltip/excludeFromSemantics.html)
  ("Set this property to true if the app is going to provide its own custom
  semantics label"),
  [`IconButton.tooltip`](https://api.flutter.dev/flutter/material/IconButton/tooltip.html)
- [`Icon.semanticLabel`](https://api.flutter.dev/flutter/widgets/Icon/semanticLabel.html),
  [`MergeSemantics`](https://api.flutter.dev/flutter/widgets/MergeSemantics-class.html)
  (FL-040's workaround)

## 5. Examples

Every example is one control, a line of text under it that its tooltip
lies over when shown, and a count of activations. Every tooltip is
Material's `Tooltip`, whether given directly or through `IconButton.tooltip`.

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-material` | Material | An icon button whose tooltip says what it does, "Delete draft" | `Tooltip(message:, ignorePointer: false, excludeFromSemantics: true)` round an `IconButton` with no `tooltip`, named by `Icon(semanticLabel:)`; a 2 pixel focus outline through the button's `style` (FL-430) | R2, R3, R4 |
| `good-cupertino` | Cupertino | The same on an icon-only `CupertinoButton` | `Tooltip(message:, ignorePointer: false)` round a `CupertinoButton`, which is not a semantics container, so the tooltip is its name; `focusColor` (FL-431); C01's Enter action (FL-002) | R2, R3, R4 |
| `good-description` | Material | A tooltip that describes a button with text, "Download" and "Saves a PDF copy" | `MergeSemantics` round `Tooltip(message:, ignorePointer: false)` round an `OutlinedButton` (FL-040; an `OutlinedButton` because a `FilledButton` is under 4.5:1 with focus and a hover, FL-253) | R2, R3, R4 |

What none of them meets, as the framework has no way to: R1's keyboard
focus (FL-248), R1's Escape on the web while the page has no focus
(FL-482), R3's "once" while the tooltip is shown (FL-249), and R3's
"describe" on iOS and the web for `good-description` (FL-251). Each test
of these is written to fail when Flutter changes, so that the examples are
looked at again.

Cupertino has no tooltip widget, so `good-cupertino` uses Material's
`Tooltip`, the framework's only one that draws itself (`RawTooltip`, the
widgets layer's, draws what the app gives it). No widgets-layer example is
built, by the owner's rule: its tooltip would be built by hand.

### Bad

| Slug | Defect | Violates |
| --- | --- | --- |
| `bad-not-hoverable` | `IconButton(tooltip:)` as it comes: the tooltip goes when the pointer moves onto it ([FL-247](../flutter-limitations.md#fl-247)) | R2 |
| `bad-hover-only` | A password rule only in the `Tooltip` of an information `Icon`, which takes no focus: only a pointer or a long press shows it, and VoiceOver on iOS passes over it (FL-252) | R5 |
| `bad-repeats-name` | A tooltip with the button's own text, "Download", merged into the button: its name is "Download Download" on iOS and the web | R3 |
| `bad-outside-button` | `Tooltip(message:)` round an `IconButton` with no name of its own: the tooltip stays on a node outside the button (FL-040), and the button has no name | R4 |

What each fails, by platform, as the criteria are written:

| Example | Android | iOS | Web |
| --- | --- | --- | --- |
| `bad-not-hoverable` | 1.4.13 (F95), with a mouse: the tooltip goes when the pointer moves onto it (the Android test injects a mouse hover) | none measured: XCUITest cannot hover; with touch, 1.4.13 does not apply | 1.4.13 (F95) |
| `bad-hover-only` | 2.1.1: a long press and a mouse show the rule; no Tab stop, Enter, or Space does | 2.1.1, as on Android; VoiceOver passes over the icon (FL-252), so a VoiceOver user does not get the rule at all | 2.1.1: a hover shows it; no key does |
| `bad-repeats-name` | none: TalkBack reads "Download" once (the probe's t06) | none: read "Download Download Button", poor practice | none: name "Download Download", poor practice |
| `bad-outside-button` | 4.1.2: the button has no name; the tooltip is read on its own node before it | 4.1.2: the button has no name, and VoiceOver passes over the tooltip's node (FL-252) | 4.1.2: the button has no name |

`bad-hover-only` and 2.1.1: the rule is information the screen gives only
to a pointer or a touch, through a user action (the hover or the long
press); a keyboard user has no way to the same result: the icon takes no
focus, and Tab, Enter, and Space never show it (each tested alone, with
Sign up's activation by the same keys as the positive control). TalkBack
reads the rule, and so does the web's tree; VoiceOver on iOS does not.

`bad-repeats-name` fails nothing as written: the name holds the visible
text (2.5.3) and is determinable (4.1.2). It is kept as poor practice, as
C03 keeps `bad-vague-text`.

Not built:

- **A tooltip that times out.** Under hover a Flutter tooltip stays (ten
  seconds measured in the widget tests, eight on the web, five on
  Android); it goes on its own only after a touch, 1.5 s after the touch
  ends, which 1.4.13 does not cover. There is no defect of 1.4.13 to show.
- **A tooltip that cannot be dismissed.** Escape hides every Flutter
  tooltip while focus is in the app; where it does not (the web, with no
  focus in the page) it fails for every example alike, good ones included,
  so it is a limitation (FL-482), not one example's defect.

## 6. Assertions by layer

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Good, in light and dark: the four guidelines; the text contrast guideline again with keyboard focus on the control and the tooltip shown by a hover; the focus outline 3:1 or more on the page. Good: the control a button with a tap action, and its label, tooltip, and hint (`good-material` "Delete draft", "", ""; `good-cupertino` "", "Delete draft", ""; `good-description` "Download", "Saves a PDF copy", ""), and no other node with the tooltip's words; while shown by a hover, a node with the tooltip's text below the control in traversal order (FL-249); a hover shows it, and it stays ten seconds and goes when the pointer leaves; the pointer moved onto it in ten steps leaves it shown, five seconds; Tab to the control leaves it hidden three seconds, and a hover in the same launch shows it (FL-248); with focus on the control, Escape hides it with the pointer on the control and on the tooltip, focus stays, and it does not come back; with the view unfocused, Escape is not handled and the tooltip stays (FL-482); a long press shows it, it is there 1.3 s after the touch ends and gone 1.8 s after, and the control was not activated; a tap, the tap action, Enter, and Space each activate it once; Tab goes Back, then the control; at 200% text on 320 by 640 the tooltip is inside the screen, its text not cut, scaled once. Every example, at 200% text on 320 by 640: no overflow, no text at its line limit or shorter than its lines, nothing off the screen. Bad: `bad-not-hoverable` shown by a hover (positive control), gone 500 ms after the pointer reaches it, shown again back on the button; its name is its tooltip. `bad-hover-only`: the icon's node has the tooltip and no focus, role, or tap; four Tabs stop on Back and Sign up only, the tooltip never shown after any, nor after Enter and Space, which activate Sign up; a hover and a long press show it. `bad-repeats-name`: label and tooltip both "Download". `bad-outside-button`: the tooltip on a node that is not a button and has no tap; one button besides Back, with no label, tooltip, or hint. The SDK alone: `IconButton(tooltip:)` and `Tooltip(message:)` go when the pointer moves onto them, and do not show on Tab (a hover the positive control); `richMessage` and `ignorePointer: false` stay; a shown `IconButton` tooltip's text is a node below the button in traversal order and not its child; Escape with the view unfocused hides nothing; a `RawTooltip` by default covers its control from its centre, and Escape with the pointer there hides it for a frame only (FL-250). Tests run as Android |
| L3 web | Good: one button besides Back, its name ("Delete draft", "Delete draft", "Saves a PDF copy Download"), no description; Chromium's own button names over the DevTools protocol the same before and while shown; a hover draws the tooltip (pixels), eight seconds, gone when the pointer leaves; while shown its text is one element of the page outside the control, and none once it has gone (FL-249); the pointer moved onto it leaves it drawn, three seconds; Tab to the control leaves it undrawn two seconds, with focus on it, and a hover then draws it (FL-248); with focus on the control, Escape hides the hovered tooltip and focus stays; with no element focused (`blur()`), Escape leaves it drawn, and after a click on an empty part of the page Escape hides it (FL-482); a click, Enter, and Space each activate once. Bad: `bad-not-hoverable` drawn by a hover, gone after the pointer moves onto it, drawn again back on the button. `bad-hover-only`: the icon's element has the rule as its text, no `tabindex`, no button role; three Tabs never focus it or draw it; Enter and Space on Sign up activate it and draw nothing; a hover draws it. `bad-repeats-name`: name "Download Download" (Playwright and Chromium), and while shown one more "Download" element outside it. `bad-outside-button`: an element named "Delete draft" that is not a button, round the one button besides Back, which has no name. The judge of the VoiceOver spec on made-up walks (as C04's); each screen shows the title and lines the judge expects |
| L3 Android | Good: each control a `Button` with its name and tooltip text ("Delete draft" and none; "Delete draft" and "Delete draft"; "Download" and "Saves a PDF copy"), clickable and focusable, the only clickable node but Back; a touch held 800 ms draws the tooltip (pixels of the box's colour) and it is gone within 4 s of the touch's end, with no activation (also `bad-not-hoverable`); Tab to the control draws nothing in two seconds, and a long press then does (FL-248); a mouse hover draws it, it stays five seconds, and the pointer moved onto it leaves it drawn; it goes when the mouse leaves; the click action, a tap, and Tab then Enter each activate. Bad: `bad-not-hoverable` drawn by a hover, gone when the mouse moves onto it; a `Button` named by its tooltip. `bad-hover-only`: the icon's node named by the rule, with it as its tooltip text, not focusable or clickable; five Tabs never focus it or draw it, Enter on Sign up activates it, a long press draws it. `bad-repeats-name`: a `Button` named "Download" with tooltip text "Download". `bad-outside-button`: a node named "Delete draft", not clickable and not a `Button`, and one `Button` but Back, with no name |
| L3 iOS | Good: each control a button with its label ("Delete draft"; "Delete draft"; "Download\nSaves a PDF copy"), one button but Back, and the tooltip's words once in the screen's labels; a touch held 0.8 s draws the tooltip (pixels of the box's colour), gone within 4 s, with no activation (also `bad-not-hoverable`); two Tabs and Enter activate the control and draw no tooltip, and a long press then does (FL-248); a tap activates. Bad: `bad-not-hoverable` a button labelled "Delete draft". `bad-hover-only`: the icon an element labelled by the rule, not a button; no tooltip drawn after two Tabs, nor after Enter, which activates Sign up; a long press draws it. `bad-repeats-name`: a button labelled "Download\nDownload". `bad-outside-button`: an element labelled "Delete draft" that is not a button, and one button but Back, with no label |
| L4 TalkBack | Focus moved to each control: the name and "Button", for `good-description` "Download", "Button", and "Saves a PDF copy"; `bad-hover-only`'s icon "At least 8 characters" with no "Button", and Sign up; `bad-repeats-name` "Download" and "Button"; `bad-outside-button`'s tooltip node "Delete draft" with no "Button", and its button "Button" without "Delete draft" |
| L4 VoiceOver iOS | Every utterance after the "Example" heading to the end of the screen, compared as a whole list: the good examples and `bad-not-hoverable` "<name> Button", the line, the count; `bad-hover-only` without the rule (FL-252); `bad-repeats-name` "Download Download Button"; `bad-outside-button` "Button" |
| L4 VoiceOver web | Every walk must read the whole screen, each stop in its place (`judgeExampleWalk` in `web_tests/vo/c12_vo_walks.js`, as C04's), in Chromium and WebKit; no runner retries. The lists were written before any recording, as predictions (section 7) |

## 7. What the build found (Flutter 3.47.5)

The probe that came first is in [evidence/probes/c12](../evidence/probes/c12/README.md).

- **A tooltip with a plain message, and every `IconButton.tooltip`, cannot
  be hovered** ([FL-247](../flutter-limitations.md#fl-247), new;
  `bad-not-hoverable`). The pointer that moves onto it has left the
  control and the tooltip goes, on the web and on Android with a mouse,
  as in the widget tests. `ignorePointer: false` or a `richMessage` fixes
  it for a `Tooltip`; `IconButton` has no parameter for it.
- **No Flutter tooltip shows on keyboard focus**
  ([FL-248](../flutter-limitations.md#fl-248), new), on any platform.
- **A shown tooltip's text is read again**
  ([FL-249](../flutter-limitations.md#fl-249), new): a node in traversal
  order inside its control, an element of the page on the web, a
  focusable `View` on Android, a text element on iOS. It may be what C01
  heard as FL-008 (not measured).
- **A tooltip joins its control's name on iOS and the web**
  ([FL-251](../flutter-limitations.md#fl-251), new), first on the web;
  Android gives it as tooltip text, which TalkBack reads after the role,
  and not at all when it repeats the name (the probe's t05 and t06).
- **VoiceOver on iOS passes over a node with only a tooltip**
  ([FL-252](../flutter-limitations.md#fl-252), new; `bad-hover-only`,
  `bad-outside-button`).
- **A `Tooltip` round a Material button misses it**
  ([FL-040](../flutter-limitations.md#fl-040), extended;
  `bad-outside-button`), as a hint does.
- **Escape on the web, with no focus in the page, hides nothing**
  ([FL-482](../flutter-limitations.md#fl-482), extended with C12's
  measurements). On load the Back button had DOM focus, so the state needs
  the page to lose focus first.
- **Under hover a tooltip does not time out**; after a touch it goes 1.5 s
  after the touch ends, on Android and iOS as in the widget tests.
- **A `RawTooltip` sits over its control by default**
  ([FL-250](../flutter-limitations.md#fl-250), new, widget tests only).
  Not used by any example.
- **A `FilledButton` is 4.28:1 with focus and a hover in light mode**
  ([FL-253](../flutter-limitations.md#fl-253), new, widget tests only),
  found when `good-description` was one.
- **Changes during the build, by the owner's rule.** The examples were
  first built with a focus listener that showed the tooltip, a key handler
  that hid it on Escape with no focus, the shown text left out of the
  semantics through a `WidgetSpan`, and a widgets-layer `RawTooltip`. The
  owner ruled (2026-11-21) that nothing is built to fill a gap of the
  framework's; they were taken out. The probe still records what the key
  handler and the focus listener did (t10, t13), as measurements only.

Skips and what they give up, in the tests:

- The widget tests run as Android, with a mouse added by the test.
- The web, Android, and iOS tell a drawn tooltip by pixels: the web by
  pixels of the band under the control (40 by 300) that changed from the
  first screenshot, more than 1000; Android and iOS by pixels of the band
  in the light tooltip box's colour, (112, 112, 113) within 12 (iOS 16),
  more than 1000 dp² or square points (dark mode is not run on devices).
  None sees the tooltip's words; a tooltip drawn elsewhere, or a box of
  another colour, would read as not drawn. The Android probe's
  any-changed-pixel count was given up because a touch's ink left up to
  7600 changed pixels after the tooltip had gone; iOS's tree was given up
  because in the examples a shown tooltip did not change it (FL-249).
- Android's first injected hover of a run showed nothing in the probe and
  in the first C12 run, so each hover is preceded by a mouse entering,
  moving, and leaving at the screen's left edge; and a hover exit alone
  left the tooltip shown, so the mouse is moved off the example before it
  leaves. Why was not found.
- Android's hover is a mouse injected through UiAutomation; the pointer is
  moved onto the tooltip at 16 dp under the control's bottom edge, where
  Material's box is for a 48 dp control. A real mouse was not used.
- Hover is not measured on iOS.
- The iOS key tests cannot see Flutter's focus: that the second Tab reached
  the control is shown by Enter activating it.
- The web's Escape test with no focus uses `blur()`; a real page losing
  focus (a click outside the browser) was not measured.
- `talkback.py` walks an element again, up to three walks, when its speech
  fails its checks (a shared tool, unchanged).
- The iOS VoiceOver walk is C03's: it ends where moving on gives the last
  utterance again, twice; no example has two neighbouring elements read
  alike. Utterances are cut at 64 characters; the longest here is under 40.

**Not done yet.** The web VoiceOver recording (ready to run); a real mouse
or trackpad on Android, and a pointer on iPad; Escape on iOS (FL-480: the
iOS Escape tests of I08 use Command+period, skipped below iOS 27) and
on a real Android keyboard; TalkBack's double-tap-and-hold, which would
send a long press (not automatable here); text scaling on the web; and
right-to-left placement.

## 8. Decisions for the owner

- Whether FL-248 (no tooltip on keyboard focus, all platforms) and
  FL-482 (no Escape on the web with no page focus, a 1.4.13 failure of
  every Flutter tooltip there) make any platform
  `PlatformStatus.limitation`. The catalog says "applies" with a note.
- Whether C01's `good-icon`, `IconButton(tooltip: 'Close')`, stays good:
  its tooltip cannot be hovered (FL-247), a 1.4.13 failure on the web and
  on Android with a mouse.
