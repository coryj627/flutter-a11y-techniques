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
  message away only by using Undo. The owner decided (2026-11-22) to keep
  Close with this qualification (section 8).
- **All: a message shown while one that stays is up waits unseen**
  ([FL-293](../flutter-limitations.md#fl-293)); every example takes the
  current message away first.

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
shown by the `ScaffoldMessenger` but `bad-inline-banner`'s, and each
example takes the current message away before it shows a new one
([FL-293](../flutter-limitations.md#fl-293)).

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-action` | Material | "Archive message": the line counts it; the SnackBar "Message archived" with Undo and Close | `showSnackBar(SnackBar(content:, action: SnackBarAction('Undo'), showCloseIcon: true))`, `persist` left to its default, which is true with an action; the action's `textColor` and `backgroundColor` turned round while focused (FL-430); a focus outline on the page's button through its `style` | R1, R2, R4 |
| `good-message` | Material | "Save draft": the SnackBar "Draft saved", which goes after its default 4 s, and the line "Drafts saved: 1" | `showSnackBar(SnackBar(content:))` | R1, R3 |
| `good-banner` | Material | "Go offline": the banner "You are offline." above the page, with Go online, which closes it | `showMaterialBanner(MaterialBanner(content:, actions: [TextButton]))`; a focus outline on its `TextButton` and on the page's button through their `style` | R1, R2, R4 |

What each meets, by platform, as the criteria are written:

| Example | Android | iOS | Web |
| --- | --- | --- | --- |
| `good-action` | 4.1.3: announced (TalkBack), focus not moved. 2.2.1: no time limit (it stays). Qualification: Close's focus tint (FL-294), with a keyboard | the same, with VoiceOver | the same; VoiceOver in Chromium announced it (first recording); the walk's Close stop is open (section 7) |
| `good-message` | 4.1.3: announced. 2.2.1: its going sets no time limit, as its news is on the page (Understanding 2.2.1) | the same | the same |
| `good-banner` | 4.1.3: announced. 2.2.1: no time limit | the same | the same |

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
  `good-action` only in Close, which the owner decided to keep (section
  8).

## 6. Assertions by layer

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | The examples, all Material, none flagged. Good, in light and dark: the four guidelines before and while the message is shown; the text contrast guideline with keyboard focus on each control in turn; each control's focus change from screenshots: more than 100 pixels on and within 8 of it changed by 3:1 or more, except Close, where none is (FL-294, written to fail when it is); the message one live region with its words and the dismiss action, none before; Enter on the button shows it and focus stays on the button; Tab after the show goes Back, the button, Undo, Close, Back (`good-action`), Back, Go online, the button (`good-banner`); the dismiss action takes it away. `good-action` and `good-banner` stay 30 s with `accessibleNavigation` off and on; Enter and Space on Undo each undo and take it away; Enter on Close takes it away and undoes nothing; Enter on Go online closes the banner. `good-message` goes 2.9 to 4.5 s after the press's first second, off and on, and its news stays on the page. FL-291: Escape with focus on Undo or Go online leaves the message, focus, and the line, and Enter in the same launch acts; Back pops the example, the message stays on the technique's screen 30 s, and its action works there. Bad: `bad-action-times-out`'s Undo gone with the message in the same time, off and on (FL-290); with focus on Undo it still goes, then no node has focus and the next Tab goes to Back (FL-292). `bad-only-in-message`: the code shown, gone, and nowhere else; a live region with its words. `bad-inline-banner`: no live region and no dismiss action (FL-295), with `good-banner`'s live region in the same test; Go online closes it. FL-290: `accessibleNavigation` turned on while shown, and a mouse resting on it, change nothing. FL-293: a second SnackBar while `good-action`'s is up is not shown 10 s later, and comes, as a live region, when Close is pressed. Every example, at 200% text on 320 by 640 with the message shown: no overflow, no text at its line limit or cut short in its box, nothing off the screen, the message among the texts. Tests run as Android |
| L3 web | Good: the message written once to `flt-announcement-polite`, nothing more 1.5 s later, and DOM focus still on the button; `good-action`'s message a group named "Message archived" holding exactly Undo and Close; `good-message`'s text alone, no control added; the banner a group named by it holding Go online, its Tab stop after Back and before the page's button; Tab after the show goes Undo, then Close; Close named "Close" with keyboard focus and no tooltip shown, and, with the pointer on it in the same load, owning its tooltip's element and named "Close Close", still a button (FL-249); Enter and Space on Undo each undo and take it away; Enter on Close takes it away, undoing nothing; `good-action` and `good-banner` stay 10 s, and 5 s more with focus on their action; Escape there leaves the message, focus, and the line, and Enter in the same load acts; `good-message` goes 2 to 6 s after the line changed, the line staying. Bad: `bad-action-times-out` announced, Undo gone with it within 6 s; with focus on Undo, DOM focus is then on the page's button (FL-292). `bad-only-in-message` announced, gone, the code in no element's text or name before or after. `bad-inline-banner`: nothing announced, no `aria-live` in the semantics tree, and `good-banner`'s announcement heard by the same recorder in the same test. The stops the VoiceOver spec expects above each example's heading, on each screen; the walk judge on made-up walks (as C04's) |
| L3 Android | Each SnackBar and the banner: one polite live region, named by the message, with the dismiss action, none before; Undo and Close `Button`s, and Go online; the dismiss action takes `good-action`'s and `good-banner`'s away; both stay 10 s; `good-message` goes within 6 s of being seen and its line stays; Tab to Undo and Enter undoes and takes it away; Tab to Close and Enter takes it away, undoing nothing; FL-291: Escape on Undo and on Go online leaves the message, focus, and the line, and Enter in the same launch acts. Bad: `bad-action-times-out`'s Undo gone with the message within 6 s; with focus on Undo, focus on the page's button once it has gone (FL-292); `bad-only-in-message`'s code gone and in no node; `bad-inline-banner` no live region and no dismiss action, and `good-banner`'s is one, in the same test |
| L3 iOS | Each message an element labelled by it, once; Undo and Close buttons, and Go online; `good-action` and `good-banner` stay 10 s; `good-message`, `bad-action-times-out`, and `bad-only-in-message` go within 6 s of being seen, their lines staying, Undo gone, and the code in no element. Three Tabs and Return undo; four Tabs and Return close, undoing nothing; two Tabs and Return close the banner (that a Tab reached a control is shown by what Return does; XCUITest cannot read Flutter's focus, nor a live region). No key with a modifier is sent, so Escape is not checked on iOS |
| L4 TalkBack | Focus parked on the example's line, the button pressed with the click action: the message's words for every example but `bad-inline-banner`, which says nothing of "offline"; then focus on `good-action`'s message, Undo, and Close, on `good-banner`'s message and Go online, and on `bad-inline-banner`'s message, which is read when focus is put on it |
| L4 VoiceOver iOS | The cursor on the button, `doubleTap()` at it: the message heard for every example but `bad-inline-banner`, where the button's utterance stays six seconds; one move back and one forward land on the button again; for `good-action`, `good-banner`, and `bad-inline-banner`, the moves forward from the button to where the last utterance repeats, as a whole list |
| L4 VoiceOver web | Chromium only for the announcements (Playwright's WebKit build passes no live region changes): Enter on the button, VoiceOver's last phrase for six seconds must hold the message, or must not hold "offline" for `bad-inline-banner`, with capture shown live after. For `good-action` and `good-banner`, in Chromium and WebKit, the screen walked from Back with the message shown, judged against the whole list in order (`judgeWalk` in `web_tests/vo/c13_vo_walks.js`); no runner retries. The lists are what the first recording read in both browsers (section 7), with Close as "Close button"; after `good-action`'s walk, whether Close's tooltip is shown is logged, judged by nobody |

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
  ([FL-293](../flutter-limitations.md#fl-293), new, widget tests).
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
    "Close button". Chromium read it "Close Close", with no role. The web
    tree has no reason for it with no tooltip shown: Close is a button
    with its text alone, named "Close", no description, as Undo is, which
    Chromium read "Undo button" (`close_probe.txt`). With the pointer on
    Close its tooltip is shown and the tree names it "Close Close", still
    a button (FL-249); keyboard focus does not show it. Whether the
    tooltip was shown during the walk is not in the log, and even then the
    tree gives the role. The cause was not found. The list keeps "Close
    button" for both browsers, as the tree gives it, and the spec logs
    after the walk whether the tooltip was shown; the second recording
    decides. If Chromium reads "Close Close" again, with no role, that is
    what this spec will say for Chromium, and 4.1.2 for Close's role there
    will be looked at.
  - `good-banner`: the title, then "You are offline. group", "Go online
    button", "end of You are offline. group", then the description, the
    "Example" heading, "Go offline button", "Status: offline".
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
- `talkback.py` walks an element again, up to three walks, when its
  speech fails its checks (a shared tool, unchanged). `bad-inline-banner`'s
  "(nothing)" after the press is followed in the same walk by its message,
  read when TalkBack focus is put on it, which shows the capture was live.
- iOS VoiceOver's announcement check is I12's: the utterance polled for
  eight seconds after `doubleTap()`; the words are under 64 characters.

**Not done yet.** Whether a screen reader user moving at their own pace
reaches a timed SnackBar before it goes was not measured: the probe's
VoiceOver walk began after six seconds of listening. Escape on iOS and a
real Android keyboard; Android's dark mode and focus highlights on a
device; FL-292 on iOS; VoiceOver's escape gesture inside a message;
right-to-left.

## 8. Decisions

Made by the owner on 2026-11-22, in answer to the build:

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
  changed here, by the owner's decision (section 8).
- **I08 Dismiss and escape**: FL-291 measures what its probe's `e12`
  found, on every layer.
- **V14 Focus indicators**: a `SnackBarAction`'s and Close's default
  focus tints (FL-430, FL-294).
- **C08 and C09 dialogs**: the Android Compose reference repository
  recommends a dialog over a SnackBar for a message with actions.
