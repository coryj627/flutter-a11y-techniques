# Spec: I12 Announcements and live regions

Status: Draft 1 (2026-11-13), written with the build. Fourth vertical-slice
technique ([plan](../plan.md), phase 3). Flutter pin: 3.47.5.

Out of scope here: error messages on form fields (F04), dialogs and alert
dialogs (C-group), and progress indicators.

## 1. Rule

When a status message appears or changes without taking focus, assistive
technology announces it, and it does so without being flooded.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies | Applies | Applies |

Two Flutter limitations shape which mechanisms count as good (FL-017,
FL-018).

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [4.1.3 Status Messages](https://www.w3.org/TR/WCAG22/#status-messages) | A status message can be determined programmatically and presented without receiving focus |

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | Changes that result from a user action or an automatic update must be announced to screen reader users | [CVS View UX Change Announcements](https://github.com/cvs-health/android-view-accessibility-techniques/blob/main/doc/dynamicbehaviors/UXChangeAnnouncements.md), [CVS Compose UX Change Announcements](https://github.com/cvs-health/android-compose-accessibility-techniques/blob/main/doc/interactions/UXChangeAnnouncements.md), [CVS iOS Accessibility Notifications](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/AccessibilityNotifications.md) |
| R2 | Announce without moving focus | CVS iOS Accessibility Notifications; [APG Alert](https://www.w3.org/WAI/ARIA/apg/patterns/alert/) |
| R3 | Use a live region for a value that changes on screen | CVS View and Compose; [MDN live regions](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Guides/Live_regions), [MDN output](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/output) |
| R4 | Announce from code when no on-screen text changes; on Android this is discouraged in favour of live regions | CVS iOS; CVS Compose |
| R5 | Rate-limit automatic updates so they do not overwhelm | CVS View and Compose |
| R6 | Reserve alerts for messages that need immediate attention | APG Alert |

Flutter references for the mechanisms used:

- [`SemanticsProperties.liveRegion`](https://api.flutter.dev/flutter/semantics/SemanticsProperties/liveRegion.html)
- [`SemanticsService.sendAnnouncement`](https://api.flutter.dev/flutter/semantics/SemanticsService/sendAnnouncement.html)
- [`SemanticsRole`](https://api.flutter.dev/flutter/dart-ui/SemanticsRole.html)

Radix comparison bar: Radix Toast renders its message in an `aria-live`
region; the bar is `aria-live`, `role="status"`, and `role="alert"` as
described by MDN and the APG Alert pattern.

## 5. Examples

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-live-region` | Widgets layer | A cart count that updates when a button is pressed | `Semantics(liveRegion: true, child: Text(…))` | R1, R2, R3 |
| `good-announce` | Widgets layer | A confirmation announced from code, with a fallback | `SemanticsService.sendAnnouncement` when `MediaQuery.supportsAnnounceOf` is true; otherwise the visible text is a live region | R1, R2, R4 |
| `good-snackbar` | Material | A SnackBar | `ScaffoldMessenger.showSnackBar` | R1, R2 |

### Bad

| Slug | Defect | Violates | Fails |
| --- | --- | --- | --- |
| `bad-silent-update` | The message changes on screen with no live region and no announcement | R1 | 4.1.3 |
| `bad-chatty-live-region` | A live region that changes every second | R5 | 4.1.3 |
| `bad-status-role-only` | `SemanticsRole.status` alone: silent on Android (Flutter limitation FL-017) | R1 | 4.1.3 |
| `bad-alert-role-only` | `SemanticsRole.alert` alone: silent on Android (Flutter limitation FL-017) | R1 | 4.1.3 |

No Cupertino example: the Cupertino library has no status or toast widget of
its own, and the widgets-layer examples apply unchanged.

## 6. Assertions by layer

The button in each example carries a `TestId`, `i12-<slug>-action`, and the
message an identifier, `i12-<slug>-status`.

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Live region flag and role on the message; that an announcement is or is not sent from code, by recording the accessibility channel; both branches of `good-announce`; guidelines and 200% text for the good examples |
| L3 web | Everything Flutter writes to its polite and assertive announcer elements, recorded with a `MutationObserver`; `role="status"` and `role="alert"` |
| L3 Android | `AccessibilityNodeInfo.liveRegion` and the message text |
| L3 iOS | The message text changes. XCUITest cannot read whether an element is a live region |
| L4 TalkBack | What is spoken after the button is pressed, with focus elsewhere |
| L4 VoiceOver web | What VoiceOver is given to speak after the button is pressed, in Chromium |
| L4 VoiceOver iOS | What VoiceOver says after the button is activated with a double tap |

## 7. What the build found (Flutter 3.47.5)

Detail is in [flutter-limitations.md](../flutter-limitations.md).

| Mechanism | Web (VoiceOver, Chromium) | Android (TalkBack) | iOS |
| --- | --- | --- | --- |
| `liveRegion: true` | announced | announced | announced |
| SnackBar | announced | announced | announced |
| `sendAnnouncement`, support checked | announced | not sent; `supportsAnnounce` is false | announced |
| `sendAnnouncement`, unconditional | announced | announced, though Android deprecates it | not an example; same call as the row above |
| status role alone | announced, twice | silent | silent |
| alert role alone | announced, twice | silent | silent |

- **A live region is the one mechanism announced on Android, iOS, and web.**
- **The status and alert roles are web only** (FL-017), so they are bad
  examples when used alone. They also cannot be combined with `liveRegion` on
  one node.
- **Announcing from code needs a fallback** (FL-018). A fourth bad example,
  an unconditional `sendAnnouncement`, was dropped: TalkBack on this Android
  version does speak it, so its defect could not be demonstrated.
- **No assertive announcement off the web** (FL-018). An example of an alert
  misused for a routine update was dropped for the same reason: the only
  observable difference is on web, where the transcript cannot tell polite
  from assertive.
- **Live regions announce their first content when a screen opens** (FL-010),
  and on web one announcement can erase another within 300 ms (FL-012).

### How announcements are captured

- **Android:** TalkBack's verbose log, as for the other techniques. Focus is
  left where it is; the test only presses the button.
- **Web:** Guidepup records speech only after its own commands, so it never
  sees an announcement. The spec reads VoiceOver's "last phrase" directly
  over AppleScript and polls it after pressing the button with the keyboard.
  The keyboard drives and VoiceOver is observed. "Last phrase" is what
  VoiceOver was given, so the check is that the announcement reached it.
- **WebKit:** Playwright's WebKit build passes no live region changes to
  VoiceOver. A plain HTML page with `aria-live`, `role="status"`, and
  `role="alert"` was silent there too, so this is the test browser and not
  Flutter. Announcements are checked in Chromium only.
- **iOS:** `XCUIVoiceOverService.currentSpeech()`, read after the button is
  activated. With VoiceOver on, `XCUIElement.tap()` only moves the VoiceOver
  cursor to the button; `doubleTap()` activates it. After that
  `currentSpeech()` returns the announcement when there is one and the button
  when there is none. The first attempt used `tap()`, never activated the
  button, and wrongly concluded that announcements could not be captured. A
  second spike (D27) found the cause and cross-checked the result against
  `UIAccessibility.announcementDidFinishNotification` observed inside the
  app: it fired, with success, for the three good examples and for none of
  the bad ones. That observer was spike code and is not in the app.

**Not done yet.** An assertive example; rate-limiting patterns beyond showing the defect.
