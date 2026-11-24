# Spec: C13 Snackbar and transient messages

Status: Draft 1 (2026-11-22), written with the build. Wave 2, links and
simple components. Flutter pin: 3.47.5.

A short message about what the app has just done, shown for a while at the
edge of the screen, sometimes with one action: Material's `SnackBar`, shown
through `ScaffoldMessenger.showSnackBar`, and `MaterialBanner`, shown
through `ScaffoldMessenger.showMaterialBanner`. By the owner's rule of
2026-11-21 every example is the framework's widget, configured only through
its own documented parameters; where it cannot meet a requirement, that is a
limitation entry and nothing is built to fill it. Live regions and
announcements in general are I12's subject; Escape across components is
I08's; focus indicators are V14's; dialogs are C08 and C09.

## 1. Rule

A transient message is announced when it appears, without taking keyboard
focus; its action can be reached with a keyboard and a screen reader, and
the message can be dismissed with them; and what it says or offers is not
taken away on a timer the user cannot turn off, adjust, or extend, unless
it is also available elsewhere.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies, with limitations | Applies, with limitations | Applies, with limitations |

What the framework's messages cannot do, by platform, with no workaround
in the SDK beyond what the good examples do. None of these makes a
platform `PlatformStatus.limitation`: each good example meets the rule on
every platform with the framework's own parameters, with the one
qualification below. The catalog says "applies" with a note.

- **All: a SnackBar's time is the app's alone**
  ([FL-290](../flutter-limitations.md#fl-290)). TalkBack, VoiceOver,
  `accessibleNavigation`, Android's "Time to take action" setting, a
  pointer resting on it, and keyboard focus on its action do not change
  it. The documentation's sentence that a SnackBar with an action does
  not time out with a screen reader on describes `persist`'s default,
  which holds for everyone; with `persist: false` it times out with
  TalkBack and VoiceOver on (measured). So a SnackBar that must not time
  out is given an action and the default (`good-action`), or what it
  says is on the page too (`good-message`).
- **All: Escape closes no message, and Back takes it to the screen
  under** ([FL-291](../flutter-limitations.md#fl-291)). `good-action`
  has a Close button; the banner's own action closes it.
- **Where keyboard focus goes when a SnackBar times out from under it**
  ([FL-292](../flutter-limitations.md#fl-292)): back to the button that
  showed it on Android and the web, to no control in widget tests; iOS not
  measured. No good example times out with an action.
- **All, with a keyboard: the SnackBar's Close button shows focus only by
  a faint tint** ([FL-294](../flutter-limitations.md#fl-294)), and no
  parameter changes it. This is `good-action`'s qualification: 1.4.11 as
  [FL-430](../flutter-limitations.md#fl-430) reads an `IconButton`'s
  tint, wherever a keyboard is used (widget tests; not measured on a
  device). Without `showCloseIcon` a keyboard user could take the
  message away only by using Undo. Close was kept with this
  qualification, decided in review by the principal on 2026-11-22; the
  owner can overrule it (section 8).
- **All: a message shown while one that stays is up waits unseen**
  ([FL-293](../flutter-limitations.md#fl-293)), a delay for everyone and
  not a 4.1.3 failure as measured; every example clears the queue and
  the current message first (`clearSnackBars`, `clearMaterialBanners`),
  so that presses that come while a message is still going out leave
  only the newest.
- **With a screen reader on, a SnackBar shown from a `SnackBarAction`'s
  `onPressed` after a clear there is hidden by the action itself**
  ([FL-296](../flutter-limitations.md#fl-296)). No workaround is built:
  what Undo did is told by the example's result line, a live region of
  the page, and no second SnackBar is shown.

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [4.1.3 Status Messages](https://www.w3.org/TR/WCAG22/#status-messages) | A SnackBar is a status message: a change in content, not a change of context, about the result of an action |
| [2.2.1 Timing Adjustable](https://www.w3.org/TR/WCAG22/#timing-adjustable) | A SnackBar goes on a timer the app sets |

4.1.3, as written: status messages "can be programmatically determined
through role or properties such that they can be presented to the user by
assistive technologies without receiving focus". Understanding 4.1.3 sets
no time a status message must stay.

2.2.1, as written: for each time limit set by the content, one of these is
true: the user can turn it off before meeting it; or adjust it over a wide
range, at least ten times the default; or is warned before it expires and
given at least 20 seconds to extend it with a simple action, at least ten
times; or it is a required part of a real-time event with no alternative;
or it is essential, and extending it would invalidate the activity; or it
is longer than 20 hours. Understanding 2.2.1 says what counts as a time
limit here: "Any process that happens without user initiation after a set
time or on a periodic basis is a time limit", and its example is an email
client whose notice of new mail "disappears after 5 seconds": users can
find out about new mail another way, by the inbox, "so the disappearance of
the message does not set a time limit on the ability to determine if new
mail has arrived"; "If the user has no other means of discovering the same
information (or performing the same function)", each message would need to
meet the criterion. So a message whose news is also on the page sets no
time limit, and a message that is the only place for some information, or
the only way to an action, does, and must meet one of the six.

The 20-hour, real-time, and essential exceptions do not apply to any
example here: four seconds is not 20 hours, nothing is a real-time event,
and nothing about an undo or a booking code needs to vanish.

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | The message is announced when it appears, and keyboard focus stays where it was | 4.1.3, [Understanding 4.1.3](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html) (a message is a status message "if they do not take focus"), [APG Alert](https://www.w3.org/WAI/ARIA/apg/patterns/alert/) ("it is crucial they do not affect keyboard focus") |
| R2 | A message with an action stays until the user has had the chance to use it, and its action can be reached with a keyboard and a screen reader | [Android Compose: Popup messages](https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/components/PopupMessages.md) (a limited-time Snackbar makes it unlikely that a user of assistive technology activates its buttons; it advises against a Snackbar for actions), APG Alert ("avoid designing alerts that disappear automatically"), [Understanding 2.2.1](https://www.w3.org/WAI/WCAG22/Understanding/timing-adjustable.html) |
| R3 | What a message says that the user needs, and finds nowhere else, does not go on a timer they cannot turn off, adjust, or extend | 2.2.1, Understanding 2.2.1 (the email example above) |
| R4 | The message can be dismissed with a keyboard and with assistive technology | 2.1.1; Android Compose: Popup messages (its Snackbar has a dismiss button) |
| R5 | The message's time follows the platform's setting for it, where there is one | Android Compose: Popup messages (a Toast and a Snackbar honour Android's "Time to take action (Accessibility timeout)" setting, tied to 2.2.1); Android's [`AccessibilityManager.getRecommendedTimeoutMillis`](https://developer.android.com/reference/android/view/accessibility/AccessibilityManager#getRecommendedTimeoutMillis(int,%20int)) |

The reference repositories: Android Compose has the one entry, Popup
messages, read above: a Toast or a Snackbar is announced by TalkBack and
goes after a time; a Snackbar's buttons are hard to reach with TalkBack; it
recommends a dialog for a message with actions, and text with a live region
for one that should stay. iOS and Android View have no entry: iOS has no
system component for a transient message. APG's Alert pattern is the web's:
`role="alert"`, which does not move focus, and no keyboard interaction.

Flutter references for the mechanisms used:

- [`SnackBar`](https://api.flutter.dev/flutter/material/SnackBar-class.html)
  ("A SnackBar with an action will not time out when TalkBack or VoiceOver
  are enabled. This is controlled by
  `AccessibilityFeatures.accessibleNavigation`"),
  [`SnackBar.persist`](https://api.flutter.dev/flutter/material/SnackBar/persist.html)
  ("If not provided, but the snackbar action is not null, the snackbar will
  persist as well"),
  [`SnackBar.duration`](https://api.flutter.dev/flutter/material/SnackBar/duration.html)
  (4 s by default),
  [`SnackBar.showCloseIcon`](https://api.flutter.dev/flutter/material/SnackBar/showCloseIcon.html),
  [`SnackBarAction`](https://api.flutter.dev/flutter/material/SnackBarAction-class.html)
  (`textColor` and `backgroundColor` take a `WidgetStateColor`)
- [`ScaffoldMessengerState.showSnackBar`](https://api.flutter.dev/flutter/material/ScaffoldMessengerState/showSnackBar.html),
  [`hideCurrentSnackBar`](https://api.flutter.dev/flutter/material/ScaffoldMessengerState/hideCurrentSnackBar.html)
- [`MaterialBanner`](https://api.flutter.dev/flutter/material/MaterialBanner-class.html),
  [`ScaffoldMessengerState.showMaterialBanner`](https://api.flutter.dev/flutter/material/ScaffoldMessengerState/showMaterialBanner.html)
- [`MediaQueryData.accessibleNavigation`](https://api.flutter.dev/flutter/widgets/MediaQueryData/accessibleNavigation.html)

Cupertino has no widget for a transient message: nothing in
`package:flutter/cupertino.dart` is a toast, a snack bar, or a banner
(searched in the 3.47.5 source for "toast", "snack", and "banner": the only
hits are `debugShowCheckedModeBanner`). No Cupertino example is built, and
no widgets-layer one: either would be a message built by hand.

## 5. Examples

Every example is a button that does something, a line of the page that
says what it has done, and the message it shows about it. Every message is
shown by the `ScaffoldMessenger` but `bad-inline-banner`'s. Each example
clears the queue and takes the current message away (`clearSnackBars`,
`clearMaterialBanners`) before it shows a new one, so that a new message
is not queued behind one that stays and a burst of presses leaves only
the newest ([FL-293](../flutter-limitations.md#fl-293); the first build
used `hideCurrentSnackBar` and `hideCurrentMaterialBanner`, which left a
replacement queued, section 7).

What an action in a message did, Undo or Go online, is told by the
example's **result line**, a line of the page in a live region
(`Semantics(liveRegion: true)`, the documented property, as I12
`good-live-region` uses it): "Archive undone. Archived: 0" or "You are
online.". The status line's change alone would not be announced, and
Understanding 4.1.3 counts a change to visible status text as a status
message; the result line is that text, given the property that makes the
framework announce it. Why a line of its own, and not the status line:
archiving changes the status line and shows the SnackBar, which is
announced; a live status line would be announced as well, and the user
told twice ("Archived: 1" and "Message archived"); the result line changes
only when the message's action is used. It is empty, with no node, when
the example opens and whenever the button shows a new message, so nothing
is announced then (measured on every layer below); it says the count after
an undo so that two undos in a row change it each time. This replaced, by
the principal's decision in review (2026-11-23), a second SnackBar shown
from the first one's `closed` future, whose ordering took four rounds of
fixes (section 7); the owner's rule is not to invent, and the live region
is the framework's own. `bad-action-times-out` and `bad-inline-banner`
have the same result line, so that each keeps its one defect:
`bad-inline-banner`'s defect is its banner, which is no live region, and
its result line is, so its silence check has a live region to compare with
in the same page (TalkBack and VoiceOver on iOS said it; VoiceOver in
Chromium did not, in its one web recording, section 7 and
[FL-297](../flutter-limitations.md#fl-297)).

The rules the examples keep for their messages, which the app-wide
`ScaffoldMessenger` shows and which outlive the example that showed them
(FL-291):

- **A newer message replaces an older one.** Every message is shown after
  `clearSnackBars()` (a banner after `clearMaterialBanners()`), whichever
  example shows it.
- **An action used after its example has gone changes nothing and takes
  away its own message only.** Undo after its example has gone (its
  SnackBar followed Back to the technique's screen, the catalog, or
  another example's screen) does nothing, and the `SnackBarAction` hides
  its own SnackBar, as it always does. Go online on a banner whose example
  has gone hides that banner only (`hideCurrentMaterialBanner()`), so a
  banner the example showed again, waiting behind it, stays; on its own
  example, Go online clears every banner (`clearMaterialBanners()`), as
  going online makes every "You are offline." untrue.

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-action` | Material | "Archive message": the line counts it; the SnackBar "Message archived" with Undo and Close; Undo's result on the result line | `clearSnackBars()` and `showSnackBar(SnackBar(content:, action: SnackBarAction('Undo'), showCloseIcon: true))`, `persist` left to its default, which is true with an action; the result line `Semantics(liveRegion: true)`; the action's `textColor` and `backgroundColor` turned round while focused (FL-430); a focus outline on the page's button through its `style` | R1, R2, R4 |
| `good-message` | Material | "Save draft": the SnackBar "Draft saved", which goes after its default 4 s, and the line "Drafts saved: 1" | `showSnackBar(SnackBar(content:))` | R1, R3 |
| `good-banner` | Material | "Go offline": the banner "You are offline." above the page, with Go online, which closes it; its result on the result line | `clearMaterialBanners()` and `showMaterialBanner(MaterialBanner(content:, actions: [TextButton]))`; the result line `Semantics(liveRegion: true)`; a focus outline on its `TextButton` and on the page's button through their `style` | R1, R2, R4 |

What each meets, by platform, as the criteria are written:

| Example | Android | iOS | Web |
| --- | --- | --- | --- |
| `good-action` | 4.1.3: announced (TalkBack), focus not moved; Undo's result announced by the result line, "Archive undone. Archived: 0" (TalkBack). 2.2.1: no time limit (it stays). Qualification: Close's focus tint (FL-294), with a keyboard | the same, with VoiceOver | the same; VoiceOver in Chromium announced it. Qualification on the web, Chromium: with Close's tooltip shown, as a VoiceOver walk leaves it, VoiceOver reads Close "Close Close" with no role word (FL-249); the tree keeps the role, so not 4.1.2 as written (section 7). Undo's result on the web: the result line, a polite live region written once to `flt-announcement-polite` (4.1.3 met in the tree); VoiceOver in Chromium did not say it in its one recording ("Back and 1 more item and 1 more item group", "Back"), so it may not be presented: a qualification of the web, recorded, not judged, until three recordings agree ([FL-297](../flutter-limitations.md#fl-297); the three before were of the SnackBar the first build showed instead, said in one of three) |
| `good-message` | 4.1.3: announced. 2.2.1: its going sets no time limit, as its news is on the page (Understanding 2.2.1) | the same | the same |
| `good-banner` | 4.1.3: announced; going back online announced by the result line, "You are online." (TalkBack). 2.2.1: no time limit | the same, with VoiceOver | the same. On the web going back online is the result line, a polite live region written once to `flt-announcement-polite` (4.1.3 met in the tree); VoiceOver in Chromium did not say it in its one recording ("Back"), so it may not be presented: a qualification of the web, recorded, not judged, until three recordings agree (FL-297; the three before were of the SnackBar the first build showed instead, said in none) |

R5 (the platform's timeout) is met by none of them, as nothing in the SDK
reads it ([FL-290](../flutter-limitations.md#fl-290)); `good-action` and
`good-banner` set no time limit for it to change, and `good-message`'s
news does not depend on it.

No example is a custom solution: every good example is a Flutter widget
through its own documented parameters ([custom-solutions.md](../custom-solutions.md)).

### Bad

| Slug | Defect | Violates | Fails |
| --- | --- | --- | --- |
| `bad-action-times-out` | Undo goes with the message after four seconds, with a screen reader on or off, and nothing gives more time: `SnackBarAction` with `persist: false` | R2 | 2.2.1 |
| `bad-only-in-message` | "Booked. Code: K7Q2": the code is in the SnackBar alone, which goes after four seconds | R3 | 2.2.1 |
| `bad-inline-banner` | A `MaterialBanner` put in the page by `setState`, not shown by the `ScaffoldMessenger`: no live region, so nothing announces it ([FL-295](../flutter-limitations.md#fl-295)) | R1 | 4.1.3 |

By platform, as the criteria are written: `bad-action-times-out` and
`bad-only-in-message` fail 2.2.1 on Android, iOS, and the web;
`bad-inline-banner` fails 4.1.3 on all three.

- `bad-action-times-out` and 2.2.1: the time limit is set by the content
  (the app's `duration`, with `persist: false`); Undo is the only way to
  undo the archiving; nothing lets the user turn the limit off, adjust it,
  or be warned and extend it; and none of the exceptions applies (section
  3). Its message is announced like any other: 4.1.3 is met. With a screen
  reader on it goes at the same time (FL-290: 4.27 s with VoiceOver,
  4.28 s with TalkBack, in the probe).
- `bad-only-in-message` and 2.2.1: the code is information the user has
  no other means of finding out (it is in no other element of the page, on
  any layer), so its going is a time limit (Understanding 2.2.1), and it
  meets none of the six.
- `bad-inline-banner` and 4.1.3: the banner is a status message (a change
  of content that is not a change of context, about the result of an
  action), and it has no role or property that lets assistive technology
  present it without focus: no live region. A screen reader user finds it
  only by moving onto it.

Not built:

- **A message that takes focus.** A SnackBar never moves focus (measured
  on every layer), so the defect cannot be shown with the framework's
  widget; moving focus by hand is I03's subject.
- **A Cupertino example.** Cupertino has no widget for a transient
  message (section 4).
- **A message with an action and no Close.** It would differ from
  `good-action` only in Close, which was kept in review (section 8).

## 6. Assertions by layer

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | The examples, all Material, none flagged. Good, in light and dark: the four guidelines before and while the message is shown; the text contrast guideline with keyboard focus on each control in turn; each control's focus change from screenshots, more than 100 pixels on and within 8 of it changed by 3:1 or more, but Close, where none is (FL-294, written to fail when it is). The message one live region with its words and the dismiss action, none before; Enter on the button shows it and focus stays on the button; Tab after the show goes Back, the button, Undo, Close, Back (`good-action`), Back, Go online, the button (`good-banner`); the dismiss action takes it away. `good-action` and `good-banner` stay 30 s with `accessibleNavigation` off and on; Enter and Space on Undo each undo and take it away; Enter on Close takes it away and undoes nothing; Enter on Go online closes the banner. `good-message` goes 2.9 to 4.5 s after the press's first second, off and on, its news on the page. The result line: no node while empty, at the open and after each new message; after Undo or Go online by Enter, a live region with "Archive undone. Archived: 0" or "You are online.", which stays; the status line no live region, and no SnackBar shown, with `accessibleNavigation` off and on (`good-action`, `good-banner`, `bad-action-times-out`, `bad-inline-banner`); two undos in a row change it each time; the examples with no action have none. FL-291: Escape with focus on Undo or Go online leaves the message, focus, and the line, and Enter in the same launch acts; Back pops the example, the message stays on the technique's screen and, after a second Back, on the catalog, and its action used there closes it and tells nothing. Bad: `bad-action-times-out`'s Undo gone with the message in the same time, off and on (FL-290); with focus on Undo it still goes, then no node has focus and the next Tab goes to Back (FL-292). `bad-only-in-message`: the code shown, gone, and nowhere else; a live region with its words. `bad-inline-banner`: no live region and no dismiss action (FL-295), then, in the same launch, its result line a live region with "You are online."; Go online closes it. FL-290: `accessibleNavigation` turned on while shown, and a mouse resting on it, change nothing. FL-293: a second SnackBar while `good-action`'s is up is not shown 10 s later, and comes, as a live region, when Close is pressed; a burst of two or three presses inside the exit animation, the animations on, leaves one message or banner and none after it (fails with `hideCurrent…`). FL-296, the SDK alone: a SnackBar shown from a `SnackBarAction`'s `onPressed` after `clearSnackBars` is never shown with `accessibleNavigation` on. The orderings that remain, each with the animations on (`accessibleNavigation` off) and with it on where it can happen: replacement (a burst; an outgoing message's Undo pressed while the next comes in undoes its own archive, and the newer message keeps its Undo, which undoes it); an action used after its screen has gone (Undo, Go online, on the technique's screen); `good-action` across Back and a reopen (the old Undo, used after the new archive, changes nothing; the new message keeps its Undo); `good-banner` across Back and a reopen (the old banner's Go online, used during its exit, hides that banner only; the new page stays offline, its banner and Go online shown, which then works); Undo, then Back while the message goes out (the undo was told on its screen; nothing on the screen under); `good-action`'s Undo after `good-message`'s or `good-banner`'s message is shown (neither taken away, nothing told); a banner and a SnackBar together (Go online takes the banner away and leaves the SnackBar). Every example, at 200% text on 320 by 640 with the message shown: no overflow, no text at its line limit or cut short, nothing off the screen. Tests run as Android |
| L3 web | Good: the message written once to `flt-announcement-polite`, nothing more 1.5 s later, and DOM focus still on the button; `good-action`'s message a group named "Message archived" holding exactly Undo and Close; Close named "Close" with keyboard focus, and "Close Close", still a button, with the pointer on it (FL-249); `good-message`'s text alone; the banner a group named by it holding Go online, its Tab stop after Back and before the page's button; Tab after the show goes Undo, then Close; Enter and Space on Undo each undo and take it away; Enter on Close takes it away, undoing nothing; `good-action` and `good-banner` stay 10 s, and 5 s more with focus on their action; Escape there leaves the message, focus, and the line, and Enter in the same load acts; `good-message` goes 2 to 6 s after the line changed. Undo (`good-action`, `bad-action-times-out`) and Go online (`good-banner`), by Enter: the message, then the result line, each written once to `flt-announcement-polite`, nothing more 1.5 s later, the status line no `aria-live`. Bad: `bad-action-times-out` announced, Undo gone with it within 6 s; with focus on Undo, DOM focus is then on the page's button (FL-292). `bad-only-in-message` announced, gone, the code in no element. `bad-inline-banner`: nothing announced, no `aria-live` in the semantics tree, then, in the same document, with the same MutationObserver and the same marked buffer, Go online's result line recorded. The stops the VoiceOver spec expects above each example's heading; the walk judge and the after-action judge on made-up readings |
| L3 Android | Each SnackBar and the banner: one polite live region, named by the message, with the dismiss action, none before; Undo and Close `Button`s, and Go online; the dismiss action takes `good-action`'s and `good-banner`'s away; both stay 10 s; `good-message` goes within 6 s of being seen; Tab to Undo and Enter undoes and takes it away; Tab to Close and Enter takes it away, undoing nothing; FL-291: Escape on Undo and on Go online leaves the message, focus, and the line, and Enter in the same launch acts. The result line: no node while empty; after Undo or Go online by the click action, a polite live region named "Archive undone. Archived: 0" or "You are online.", which stays 6 s; the status line no live region. Bad: `bad-action-times-out`'s Undo gone with the message within 6 s; with focus on Undo, focus on the page's button once it has gone (FL-292); `bad-only-in-message`'s code gone and in no node; `bad-inline-banner` no live region and no dismiss action, then, in the same launch, its result line a live region with "You are online." |
| L3 iOS | Each message an element labelled by it, once; Undo and Close buttons, and Go online; `good-action` and `good-banner` stay 10 s; `good-message`, `bad-action-times-out`, and `bad-only-in-message` go within 6 s of being seen, their lines staying, Undo gone, and the code in no element. Undo and Go online, by a tap: the line changes back, and the result line is labelled "Archive undone. Archived: 0" or "You are online.", and stays. Three Tabs and Return undo; four Tabs and Return close, undoing nothing; two Tabs and Return close the banner (that a Tab reached a control is shown by what Return does; XCUITest cannot read Flutter's focus, nor a live region). No key with a modifier is sent, so Escape is not checked on iOS |
| L4 TalkBack | Focus parked on the example's line, the button pressed with the click action: the message's words for every example but `bad-inline-banner`, which says nothing of "offline"; then focus on `good-action`'s message, Undo, and Close, on `good-banner`'s message and Go online, and on `bad-inline-banner`'s message, which is read when focus is put on it Then, with focus parked on the line again, the action pressed with the click action (`-done-announced`, the result line): "Archive undone" for `good-action`, "You are online." for `good-banner` and `bad-inline-banner`, the last the positive control of its silence in the same launch `bad-inline-banner`'s silence row is the five seconds after the press, then focus moved to its button in the same row, which must be read ("Go offline"), with "You are offline." not said. Each walk is judged whole (`walk_strictly`): a wrong reading anywhere fails for good, only a walk shown to be incomplete is walked again, up to three, the deciding walk judged on its own, and every walk is in the transcript; the judge is tested on made-up logs in `tool/test_talkback.py` (`StrictWalks`) |
| L4 VoiceOver iOS | The cursor on the button, `doubleTap()` at it: the message heard for every example but `bad-inline-banner`, where the button's utterance stays six seconds; one move back and one forward land on the button again; for `good-action`, `good-banner`, and `bad-inline-banner`, the moves forward from the button to where the last utterance repeats, as a whole list Then the cursor on the message's action with `tap()`, `doubleTap()` at it, and what it did must be heard: "Archive undone. Archived: 0", the result line (`good-action`), "You are online." (`good-banner`, `bad-inline-banner`, the last the positive control of its silence in the same launch) |
| L4 VoiceOver web | Chromium only for the announcements (Playwright's WebKit build passes no live region changes): Enter on the button, VoiceOver's last phrase for six seconds must hold the message, or must not hold "offline" for `bad-inline-banner`, with capture shown live after. For `good-action` and `good-banner`, in Chromium and WebKit, the screen walked from Back with the message shown, judged against the whole list in order (`judgeWalk` in `web_tests/vo/c13_vo_walks.js`); no runner retries. The lists are what the first two recordings read (section 7): the same in both browsers but at Close, "Close Close" in Chromium and "Close button" in WebKit, each exact; after `good-action`'s walk, whether Close's tooltip is shown is logged, judged by nobody After each announcement of `good-action`, `good-banner`, and `bad-inline-banner`, keyboard focus on the message's action and Enter, and every phrase heard in six seconds recorded (`-after-undo-recorded`, `-after-go-online-recorded`): nothing is asserted about the result line or about Back, which varied (FL-297); the row fails only on a stale phrase before the press, an empty capture, a line that did not change back, or a capture not live after it (`judgeAfterAction`, `assertCaptureIsLive`; section 7). `bad-inline-banner`'s silence has `assertCaptureIsLive` in the same page as its VoiceOver control, and no positive control of an announcement (section 7) |

## 7. What the build found (Flutter 3.47.5)

The probe that came first is in [evidence/probes/c13](../evidence/probes/c13/README.md).

- **A SnackBar and a banner shown by the `ScaffoldMessenger` are
  announced on every platform, and move no focus.** Each is a polite live
  region named by its message (Android tree; the web's
  `flt-announcement-polite`; widget tests), with its controls as nodes of
  their own. TalkBack, VoiceOver on iOS, and Flutter's web announcer gave
  the message's words, and not its action's (probe; C13 transcripts). On
  the web the SnackBar is a group named by the message (`aria-label`),
  holding its buttons. TalkBack reads the message's node with "Actions
  available, use Tap with 3 fingers to view": its dismiss action.
- **The time is the app's alone** ([FL-290](../flutter-limitations.md#fl-290),
  new): about 4.3 s on every device with or without a screen reader, and
  unchanged by Android's "Time to take action" at 60 s. A SnackBar with
  an action stays, for everyone, by `persist`'s default.
- **Escape closes nothing; Back takes the message along**
  ([FL-291](../flutter-limitations.md#fl-291), new; I08's `e12`).
- **Focus on a timed-out action** ([FL-292](../flutter-limitations.md#fl-292),
  new) goes back to the page's button on the Android emulator and the
  web, and to no node in the widget tests.
- **A message waits behind one that stays**
  ([FL-293](../flutter-limitations.md#fl-293), new, widget tests): a delay
  for everyone, not a 4.1.3 failure as measured. In review (2026-11-22)
  the first build's `hideCurrentSnackBar()` and `hideCurrentMaterialBanner()`
  before each show were found to leave a replacement queued after a burst
  of presses inside the exit animation; the widget tests "a burst of
  presses" fail on that code and pass with `clearSnackBars()` and
  `clearMaterialBanners()` (`flutter_test_burst.txt`).
- **Design A: the result line, and no second SnackBar** (the principal's
  decision in review, 2026-11-23). Codex found a fourth ordering bug (an
  old banner's Go online, after Back and a reopen, cleared the new
  instance's banner) and that the second SnackBar, with its count of
  messages and its deferred callback, was a project-built ordering policy:
  by the register's rule, custom. It was taken out, and what an action did
  is told by a live-region result line (section 5). Measured before it was
  built through, on every layer: one polite write to
  `flt-announcement-polite` per use on the web, none on the load or when
  the line empties (`web_result.txt`); TalkBack said "Message archived"
  once on the show, and "Archive undone. Archived: 0" and "You are
  online." on Undo and Go online, while the control pressed went
  (`docs/evidence/C13/talkback-android.md`, one walk, right); VoiceOver on
  iOS said "Message archived" once, and "Archive undone. Archived: 0" and
  "You are online." after a tap at the action
  (`docs/evidence/C13/voiceover-ios.md`). VoiceOver on the web, in
  Chromium, did not say it: in the seventh recording, the first of the
  result line, Undo gave "Back and 1 more item and 1 more item group",
  "Back", and the usage hint; `good-banner`'s Go online "Back" and the
  hint; `bad-inline-banner`'s "Back" ([FL-297](../flutter-limitations.md#fl-297),
  the rows recording only). The bullets below are the history of the
  removed mechanism. An Android keyboard test failed twice on its second
  launch, which did not show the example's button: it opened the same
  example twice, and the wait for its title passed on the screen being
  replaced. It is two tests now, one launch each, which passed in two
  runs and at 320 by 640 (`android_design_a_flake.txt`).
- **A message's action, used after its example had gone, could take a
  newer message away, and told of an undo that did nothing** (Codex
  review, 2026-11-23, the third ordering bug in this code): the count of
  messages was each example's own, but the messages outlive the example.
  Archive A, go Back, open `good-action` again and archive B, then press
  A's Undo while A goes out: A's example's count was unchanged, so its
  "Archive undone" cleared B and its Undo, and nothing had been undone.
  Across two examples, A's Undo after `good-message`'s "Draft saved" took
  that message away, and after `good-banner`'s banner told of an undo
  that did nothing. The widget tests "messages that outlive their
  example" fail on that code (5 of 9) and pass now
  (`flutter_test_outlive.txt`): the count is the messenger's, and a
  confirmation is told only for an action that changed its example while
  it was there (section 5). No recorded flow on a device or with a screen
  reader goes Back with a message shown or uses an action during a
  message's exit, so none changed.
- **An outgoing message's Undo could take the newer message away**
  (Codex review, 2026-11-23): with the animations on, Undo on a message
  going out while the next came in closed it with the reason `action`,
  and the confirmation's `clearSnackBars()` then took the newer message
  and its Undo away, the line still counting the newer archive. The
  widget tests "the outgoing message's action, during the next one's
  coming" fail on that code and pass now (`flutter_test_outgoing_undo.txt`):
  the outgoing Undo undoes its own archive (2 to 1), the newer message
  and its Undo stay, its Undo undoes it (1 to 0), and "Archive undone"
  comes once it has gone; Close on the newer message lets it come too.
  `good-banner` has no such case: its Go online clears every banner, the
  waiting one included, as going online makes them all untrue, and its
  test shows the page online with no banner. `bad-inline-banner` queues
  nothing. No recorded flow on a device or with a screen reader presses
  an action during a message's exit, and none changed.
- **Going back online, and Undo, said nothing** in the first build: the
  line changed, the banner or the SnackBar went, and nothing was
  announced. The first review build showed a SnackBar that says what it
  did (since replaced by the result line, above), measured on every layer: a polite live region in the widget tests (with
  `accessibleNavigation` off and on) and on Android, written once to
  `flt-announcement-polite` on the web, about 50 ms after Enter
  (`web_done_focus.txt`), and heard by TalkBack and by VoiceOver on iOS.
  **VoiceOver on the web said it in some recordings and not in others**
  ([FL-297](../flutter-limitations.md#fl-297), new). In the fourth
  recording (`voiceover-web-round3-fail.md.txt`) none of the three
  messages was said: after Enter on Undo, "Back and 1 more item and 2 more
  items group", "Back", and the usage hint; on `good-banner`'s Go online,
  "Back" and the hint; on `bad-inline-banner`'s, "Back and 1 more item and
  2 more items group" and "Back". In the fifth (`voiceover-web-round4-fail.md.txt`)
  two of the three were: Undo, "Back and 1 more item and 2 more items
  group", "Archive undone", the hint; `good-banner`'s Go online, "Go
  offline button", "Back", the hint, and not the message;
  `bad-inline-banner`'s, "Back and 1 more item and 2 more items group",
  "You are online.". In the sixth (`voiceover-web-round5.md.txt`, every
  test passing, the transcript until the seventh), one of the three: Undo, "Back" and the hint; `good-banner`'s Go online,
  "Back and 1 more item and 2 more items group", "Back", the hint;
  `bad-inline-banner`'s, "Back and 1 more item and 2 more items group",
  "You are online.". Across the three: "Archive undone" (`good-action`) was said in one, `good-banner`'s "You are online." in none, and `bad-inline-banner`'s "You are online." in two. The control Enter was pressed on goes as it acts;
  without VoiceOver, DOM focus then went to the page's button (Undo:
  "Archive message"; Go online: "Go offline", `web_done_focus.txt`). Why
  the result varies was not measured. So on the web the change back is a
  status message the tree determines (4.1.3 as written: its role and
  property are there), and VoiceOver in Chromium said it in some
  recordings and not in others (`good-banner`'s in none of three), so it
  may not be presented. The principal
  decided in review (2026-11-22) to keep the design, the framework's own
  SnackBar being what is measured, and to record this as a finding; the
  owner can overrule it.
- **The web VoiceOver rows after the action record; they prove nothing
  either way.** `<slug>-after-undo-recorded` and
  `<slug>-after-go-online-recorded` (`good-action`, `good-banner`,
  `bad-inline-banner`; Chromium only, as every announcement check) log
  every phrase VoiceOver gave in the six seconds after Enter. They assert
  nothing about whether what the action did is heard (the second
  SnackBar, now the result line), nor about "Back", as the reading varied
  between recordings, and no single reading could be held; they stay so
  unless three recordings agree. They fail only if the phrase VoiceOver
  last said before the press already held what the action says or was
  "Back" (stale; `heardAfter` also leaves
  out a phrase equal to it), if nothing at all was heard (an empty
  capture; `judgeAfterAction`, tested on made-up readings in
  `web_tests/c13_snackbar.spec.js`), if the page's line did not change
  back (the action did not act), or if the capture is not live after the
  six seconds (`assertCaptureIsLive`). A passing row shows that VoiceOver
  was listened to while the action acted, and what it said that time; it
  does not show that VoiceOver presents it, or that it does not.
  No retries: each recording's row is what that recording heard.
- **`bad-inline-banner`'s web VoiceOver silence has no same-launch
  positive control of an announcement.** What its Go online did, which
  would have been one, was heard in two recordings of three as the second
  SnackBar, and not in the one recording of the result line (FL-297), so
  it cannot be one. The best real control
  in the same page load is `assertCaptureIsLive`, run right after the
  silence: it moves VoiceOver's cursor and requires its last phrase to
  change, which shows that the capture of VoiceOver's speech was working
  in that page. It does not show that VoiceOver would have spoken a live
  region there. The same-document control of the announcement itself is
  the web tree test's: the same MutationObserver and the same marked
  buffer record Go online's result line, "You are online.", after the
  silence. Together they show that Flutter wrote nothing for the banner
  and does write for a live region in that page, and that VoiceOver's speech was being read; not
  that VoiceOver presents a live region there.
- **A SnackBar shown from a `SnackBarAction`'s `onPressed` after a clear
  there is hidden by the action when `accessibleNavigation` is on**
  ([FL-296](../flutter-limitations.md#fl-296), new): Undo's "Archive
  undone", first shown that way, never appeared on the web
  (`web_undo.txt`); it is now shown from the first SnackBar's `closed`
  future.
- **Close's focus tint cannot be changed**
  ([FL-294](../flutter-limitations.md#fl-294), new, widget tests), and the
  `SnackBarAction`'s default tint is under 3:1 too
  ([FL-430](../flutter-limitations.md#fl-430)); `good-action` sets the
  action's own colours.
- **A `MaterialBanner` outside the messenger is not a live region**
  ([FL-295](../flutter-limitations.md#fl-295), new; `bad-inline-banner`).
- **An identifier inside the message takes its words off the live
  region** ([FL-007](../flutter-limitations.md#fl-007), extended): the
  first build put `Semantics(identifier:)` round each message, and the
  widget tests found the live region with no label. The tests now find a
  message by its words.
- **VoiceOver on the web, first recording**
  (`docs/evidence/probes/c13/voiceover-web-round1-fail.md.txt`, recorded
  by the principal; 4 of 10 tests failed, every one a walk, on
  expectations written as predictions; each failed on its first walk, so
  none was walked again). Every announcement passed in Chromium: the
  message's words, then VoiceOver's usage hint for the button that kept
  focus; `bad-inline-banner` gave the hint alone. The walks, the same in
  both browsers but at Close:
  - The message is the group's name, read on entering it ("Message
    archived group", "You are offline. group"), and is not a stop of its
    own inside it; leaving it, VoiceOver says "end of" the group. The
    lists predicted the name again inside the group, after C12's
    `bad-outside-button`, where VoiceOver read it there (C12 did not find
    what that stop was); here it did not.
  - `good-action`: "Archived: 1", "Message archived group", "Undo button",
    then Close, then "end of Message archived group". WebKit read Close
    "Close button" in all seven recordings; Chromium read it "Close Close",
    with no role word, in all seven. After each walk from the second on,
    Close's tooltip was shown, in both browsers (`voiceover-web-round2-fail.md.txt`,
    `good-action-close-tooltip-after-walk`). Close is the `IconButton` that
    `showCloseIcon` adds, with the tooltip "Close". With no tooltip shown
    the tree names it "Close", a button, as it names Undo; while its
    tooltip is shown the button owns the tooltip's element and the tree
    names it "Close Close", still a button (`close_probe.txt`; the tree
    spec asserts both). So the walk leaves the tooltip shown, and
    Chromium's VoiceOver reads the doubled name and leaves out the role
    word, which WebKit's says. What shows the tooltip during the walk, and
    why Chromium's speech drops the role, were not measured beyond that
    correlation ([FL-249](../flutter-limitations.md#fl-249), extended).
    4.1.2: the role is programmatically determinable (the tree has it), so
    it is not a 4.1.2 failure as written; but a Chromium VoiceOver user
    does not hear "button" on Close, and hears its name twice. Nothing in
    the example can change it: `SnackBar` has no parameter for the close
    icon's tooltip (read in the source: `material/snack_bar.dart`, the
    `IconButton`'s `tooltip` is `MaterialLocalizations.closeButtonTooltip`).
    The walks expect each browser's reading exactly: "Close Close" in
    Chromium, "Close button" in WebKit.
  - `good-banner`: the title, then "You are offline. group", "Go online
    button", "end of You are offline. group", then the description, the
    "Example" heading, "Go offline button", "Status: offline".
- **VoiceOver on the web, the transcript**
  ([evidence/C13/voiceover-web.md](../evidence/C13/voiceover-web.md)) is
  the seventh recording, by the principal, at 943c51e, the first of
  design A: 10 tests passed, every walk complete on its first try in both
  browsers, Chromium reading Close "Close Close" and WebKit "Close
  button", with Close's tooltip shown after the walk in both; the
  after-action rows recorded what is listed above, the result line said
  in none. The first recording failed on its four walks, written as
  predictions; the second on `good-action`'s walk in Chromium, at Close,
  before the lists were set per browser; the third passed, before the
  review round added the after-action rows; the fourth and fifth failed
  on those rows, written then as one reading, which did not hold (FL-297);
  the sixth passed, the rows recording only, on the second SnackBar. The
  failed ones are kept in the probe folder
  (`voiceover-web-round1-fail.md.txt` to `voiceover-web-round4-fail.md.txt`),
  and the sixth as `voiceover-web-round5.md.txt`.
- **The banner's reading order is its drawn order.** `showMaterialBanner`
  puts the banner at the top of the `Scaffold`'s body, under the app bar
  and above the page, so it is drawn after the title and before the
  description; VoiceOver read it there, and Tab reaches Go online after
  Back and before the page's button (web tree test, widget tests, the
  probe on every platform). That is not a 1.3.2 failure: the order read
  is the order shown, and nothing in the meaning depends on the banner
  coming after the button that showed it. Nor 2.4.3: focus moves in the
  order things are drawn, top to bottom, which keeps their meaning and
  operation; a keyboard user on the button that showed the banner reaches
  Go online by Shift+Tab, or by Tab round from Back, and is told of the
  banner as it appears (4.1.3). It does mean that a screen reader user who
  goes on from the button does not reach the banner: it is behind them.
- **`accessibleNavigation` was true in every Android run**, TalkBack off
  as well as on (probe, `android-tree.txt`); why was not found. So on
  Android every lifetime measured is with it true; the widget tests
  measure both.

Skips and what they give up, in the tests:

- The widget tests run as Android. Time there is pumped in 100 ms frames,
  so a lifetime is good to 100 ms; the bounds asserted (2.9 to 4.5 s after
  the press's first second) allow for the entrance animation, which is
  left out with `accessibleNavigation`.
- The widget tests' focus measure reads the pixels on and within 8 of the
  control's box only, and counts a pixel as changed by focus when it
  differs between the screenshot before the Tab and after it; a change
  elsewhere, or one that a hover or ink would make as well, is not told
  apart. It is not V14's measure, which compares each changed pixel with
  what is next to it: here a pixel is compared with what it was. The
  outlined buttons pass by their ring (650 to 1,100 pixels at 3:1), and
  Undo by its turned-round colours (over 3,600).
- On the web and Android the message is found by its words (an
  identifier would split it, FL-007); on iOS by its label. A message read
  in other words would count as gone.
- The web's lifetime checks poll every 100 ms after the line changed, so
  they start up to a second after the show; the bounds (2 to 6 s) allow
  for it. Android's and iOS's poll every 100 ms after the message was
  seen, with a bound of 6 s.
- On iOS a Tab is shown to have reached a control only by what Return
  does there; Escape is not sent (no modifier keys on CI's iOS 26.5).
- The TalkBack walk is judged whole (`walk_strictly` in
  `tool/talkback.py`, C13 in its `STRICT` set since 2026-11-23, after
  C05): a walk with any wrong reading fails for good, and only a walk
  shown to be incomplete (an element never focused, nothing spoken for it,
  or its speech cut off in the log with no forbidden phrase in what was
  captured) is walked again, up to three walks; the walk that decides is
  judged on its own, with no element's speech taken from another walk, and
  every walk is in the transcript. Because a row with nothing spoken counts
  as incomplete there, `bad-inline-banner`'s silence row
  (`c13-bad-inline-banner-announced`) is the five seconds after the press
  and then, in the same row, TalkBack focus moved to the page's button,
  which must be read ("Go offline") while "You are offline." must not:
  the capture is shown live in the row itself. What that gives up: a
  banner announcement that came more than five seconds after the press,
  or was cut by the focus move, would not be told apart from silence. Its
  message is then read when focus is put on it (the next row), and Go
  online's SnackBar is announced (`-done-announced`), in the same launch.
- iOS VoiceOver's announcement check is I12's: the utterance polled for
  eight seconds after `doubleTap()`; the words are under 64 characters.

**Not done yet.** Whether a screen reader user moving at their own pace
reaches a timed SnackBar before it goes was not measured: the probe's
VoiceOver walk began after six seconds of listening. Escape on iOS and a
real Android keyboard; Android's dark mode and focus highlights on a
device; FL-292 on iOS; VoiceOver's escape gesture inside a message;
right-to-left.

## 8. Decisions

Decided in review by the principal on 2026-11-22, in answer to the
build. The owner has not been asked about them and can overrule any of
them:

- **Close stays on `good-action`**, with its qualification stated on the
  example. `good-action` has `showCloseIcon: true` so that a keyboard
  user can take away a SnackBar that stays without using its action, since
  Escape closes nothing (FL-291). Its Close button shows keyboard focus
  only by a faint tint that no parameter changes (FL-294), which fails
  1.4.11 as FL-430 reads an `IconButton`'s tint, wherever a keyboard is
  used. The example's code comment, its row in the technique doc, and
  section 5 say so.
- **FL-292 stays an entry of its own.**
- **I12 is left alone**; its `good-snackbar` (section 9) is noted for the
  wave's notes.

## 9. What is handed on

- **I12 Announcements**: its `good-snackbar` is a SnackBar with no action,
  whose news ("Message archived") is nowhere else on its page; by
  Understanding 2.2.1 its going is a time limit (FL-290). I12 is not
  changed here, by the principal's decision in review (section 8).
- **I08 Dismiss and escape**: FL-291 measures what its probe's `e12`
  found, on every layer.
- **V14 Focus indicators**: a `SnackBarAction`'s and Close's default
  focus tints (FL-430, FL-294).
- **C08 and C09 dialogs**: the Android Compose reference repository
  recommends a dialog over a SnackBar for a message with actions.
- **I03 Focus management and I12 Announcements**: FL-297. On the web, when
  Enter on a control removes it (here a SnackBar's or a banner's action),
  DOM focus went to the page's button without VoiceOver; with VoiceOver in
  Chromium the polite announcement Flutter wrote at the same time was said
  in some recordings and not in others, and the move to Back was spoken in
  most. Where
  focus should go when an activated control removes itself, and whether
  an announcement made then is heard, belong to those techniques; their
  files are not changed here.
