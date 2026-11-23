# Spec: C26 Progress indicator

Status: Draft 1 (2026-11-22), written with the build. Wave 2, links and
simple components. Flutter pin: 3.47.5.

A progress indicator: a bar that shows how far a task has gone, or a
spinner that shows that something is happening, for as long as it takes.
The source material is Flutter's own `LinearProgressIndicator` and
`CircularProgressIndicator`, determinate and indeterminate, with their
documented `semanticsLabel` and `semanticsValue`; Cupertino's
`CupertinoActivityIndicator` and `CupertinoLinearActivityIndicator`; and,
for telling the status, Flutter's own live region,
`Semantics(liveRegion: true)`. By the owner's rule of 2026-11-21 every
example is the framework's widget through its documented parameters; where
it cannot meet a requirement, that is a limitation entry and nothing is
built to fill it. Live regions and announcements in general are I12's
subject; a slider's value is F10's; a meter (C25) has no role in Flutter
(FL-026). `RefreshIndicator` is not built: it is pull to refresh, a
gesture with a spinner inside, whose spinner is a
`RefreshProgressIndicator` named "Refresh" by default (source read:
`material/refresh_indicator.dart`); the gesture is another technique's.

## 1. Rule

A progress indicator has a name that says what is in progress; a
determinate one has its value; and how the task is going, and that it has
ended, are status messages that a screen reader is given without focus
moving.

## 2. Platforms

| Android | iOS | Web |
| --- | --- | --- |
| Applies, with limitations | Applies, with limitations | Applies, with limitations |

What the framework's indicators cannot do, by platform, with no
workaround in the SDK. Whether any of these makes a platform
`PlatformStatus.limitation` is the owner's decision (section 8); the
catalog says "applies" with a note.

- **All: a change of an indicator's value is not announced**
  ([FL-254](../flutter-limitations.md#fl-254)), with the screen reader's
  focus on it or not. The good examples tell how the task is going, and
  that it has ended, in a status line in a live region, which every
  platform announced (ARIA25's way).
- **All: a spinner has no role; on iOS no indicator has one**
  ([FL-256](../flutter-limitations.md#fl-256)). The web gives a spinner no
  ARIA role, Android a plain `View`, iOS static text; and iOS gives a bar
  static text too. Under the reading of section 3, this fails 4.1.2's role
  for `good-circular` and `good-cupertino` on every platform, and for
  `good-linear` on iOS. Nothing in the SDK can give the role: the
  progress bar role needs a numeric value ([FL-258](../flutter-limitations.md#fl-258)).
- **Android and iOS: how the value is read** ([FL-027](../flutter-limitations.md#fl-027)).
  With the default value TalkBack reads it twice, "0.0.", then "0,", and
  VoiceOver on iOS reads the bare number, "Report upload 0", with no unit.
  A percent sign in `semanticsValue` reads better and loses Android's
  range. The good examples keep the default.
- **Cupertino: nothing for a screen reader**
  ([FL-255](../flutter-limitations.md#fl-255)); `good-cupertino` names its
  spinner with a label, and the Cupertino bar is shown only as a bad
  example.
- **iOS, and a browser on a Mac: `CircularProgressIndicator.adaptive`
  drops its label** ([FL-257](../flutter-limitations.md#fl-257)).

## 3. WCAG 2.2 success criteria

| Criterion | Why it applies |
| --- | --- |
| [4.1.2 Name, Role, Value](https://www.w3.org/TR/WCAG22/#name-role-value) | The indicator's name, role, and value |
| [4.1.3 Status Messages](https://www.w3.org/TR/WCAG22/#status-messages) | How the task is going, and that it has ended |

4.1.2, as written: "For all user interface components ..., the name and
role can be programmatically determined; states, properties, and values
that can be set by the user can be programmatically set; and notification
of changes to these items is available to user agents, including
assistive technologies." The glossary's user interface component is "a
part of the content that is perceived by users as a single control for a
distinct function". Whether a progress indicator, which takes no input,
is a "control" in that sense, the criterion does not say. WAI-ARIA 1.2
puts `progressbar` among the widget roles, with its accessible name
required, and HTML's `progress` element has that role. This spec reads an
indicator as a user interface component, as ARIA does, and every 4.1.2
verdict below holds only under that reading. Its value cannot be set by
the user, so 4.1.2's "values that can be set" does not cover it; its
value is held to be part of the name, role, and value a component must
expose (ARIA: `aria-valuenow`), again under that reading.

4.1.3, as written: "In content implemented using markup languages, status
messages can be programmatically determined through role or properties
such that they can be presented to the user by assistive technologies
without receiving focus." The glossary's status message is "change in
content that is not a change of context, and that provides information to
the user on the success or results of an action, on the waiting state of
an application, on the progress of a process, or on the existence of
errors". Understanding 4.1.3 has two examples on this: a "busy" icon that
the screen reader announces as "application busy", and a progress bar
whose progress the screen reader announces "intermittently". Its
sufficient techniques for progress are ARIA23 (`role="log"`), ARIA25 (a
live region for a progress bar), ARIA22 with G193, and ARIA27
(`ariaNotify`). ARIA25 notes that the `progressbar` role is not a live
region, so a progress bar alone does not announce.

## 4. Source requirements

| # | Requirement | Source |
| --- | --- | --- |
| R1 | The indicator has a name that says what is in progress, matching any visible label, and a spinner's name is spoken | [iOS: Progress Indicators](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/ProgressIndicators.md) (the label must be spoken and match the visible text), [MDN: progress](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/progress) ("you should provide an accessible label"), [WAI-ARIA 1.2: progressbar](https://www.w3.org/TR/wai-aria-1.2/#progressbar) (name required) |
| R2 | A determinate indicator exposes its value, and its value follows what is drawn | iOS: Progress Indicators (the correct value spoken), WAI-ARIA 1.2 (`aria-valuenow`, updated when the visual indicator is), MDN: progress |
| R3 | An indeterminate indicator has no value | WAI-ARIA 1.2 (omit `aria-valuenow`), MDN: progress (no `value` attribute) |
| R4 | That loading has started, how it is going, and that it has ended are given as status messages, without moving focus | [Understanding 4.1.3](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html), [ARIA25](https://www.w3.org/WAI/WCAG22/Techniques/aria/ARIA25), iOS: Progress Indicators (an announcement of the loading indicator's text) |
| R5 | The indicator has the role of a progress indicator | WAI-ARIA 1.2 (`progressbar`), MDN: progress (implicit role `progressbar`) |

The reference repositories: iOS has Progress Indicators, read above, with
a good spinner (`ProgressView("Updating your information")` and an
announcement of the same words, posted 0.1 s late so that VoiceOver speaks
it), a good bar (`ProgressView("Downloading Purchase Receipt", value: 20,
total: 100)`), and a bad spinner and a bad bar with no label. It says
nothing on announcing completion or progress. Android View and Android
Compose have no entry, and APG has no pattern.

HTML's `progress` element, the inventory's comparison: its implicit role is
`progressbar`; with no `value` it is indeterminate; MDN advises a label,
and, for a region that is loading, `aria-busy` on the region and
`aria-describedby` to the status.

Flutter references for the mechanisms used:

- [`LinearProgressIndicator`](https://api.flutter.dev/flutter/material/LinearProgressIndicator-class.html),
  [`CircularProgressIndicator`](https://api.flutter.dev/flutter/material/CircularProgressIndicator-class.html),
  [`ProgressIndicator.semanticsLabel`](https://api.flutter.dev/flutter/material/ProgressIndicator/semanticsLabel.html)
  ("This value indicates the purpose of the progress bar, and will be read
  out by screen readers")
- [`CupertinoActivityIndicator`](https://api.flutter.dev/flutter/cupertino/CupertinoActivityIndicator-class.html)
- [`Semantics.liveRegion`](https://api.flutter.dev/flutter/widgets/Semantics/liveRegion.html),
  [`ExcludeSemantics`](https://api.flutter.dev/flutter/widgets/ExcludeSemantics-class.html)

## 5. Examples

Every example is a button that starts a task, the task's indicator, and
a line of text under it, the status line. The task runs four steps of
one second. Upload's status line says "Not started", "Upload started",
"Half uploaded" from 50%, and "Upload complete"; a load's says "Inbox not
loaded", "Loading started", and "Inbox loaded". It changes at those
points only, so that a screen reader is told how it is going now and then
(Understanding 4.1.3: "intermittent"), and not at every step: the probe's
p18, which changed every 1.2 s, ran TalkBack's speech seconds behind
(`docs/evidence/probes/c26/android-talkback.md`). A bar is at 0 before
its task starts; a spinner is shown only while its task runs.

### Good

| Slug | Variant | What it shows | Mechanism | Reqs |
| --- | --- | --- | --- | --- |
| `good-linear` | Material | "Upload report": a bar named "Report upload", the words shown above it, and its status line | `LinearProgressIndicator(value:, semanticsLabel:)`, its value the default (the percentage as a number); the shown words in `ExcludeSemantics`, so that they are read once; the status line in `Semantics(liveRegion: true)` | R1, R2, R4, R5 |
| `good-circular` | Material | "Load inbox": a spinner named "Loading inbox" while it loads, and its status line | `CircularProgressIndicator(semanticsLabel:)`, no value; the status line in a live region | R1, R3, R4 |
| `good-cupertino` | Cupertino | The same with Cupertino's spinner | `Semantics(label:)` round a `CupertinoActivityIndicator`, which has no name of its own ([FL-255](../flutter-limitations.md#fl-255)); the status line in a live region | R1, R3, R4 |

Every button is a Material `OutlinedButton` with a 2 pixel focus outline
through its own `style`; `good-cupertino`'s too, because a
`CupertinoButton` takes no Enter on the web
([FL-002](../flutter-limitations.md#fl-002)) and making it would be
hand-built.

No example is a custom solution: each is a Flutter widget through its own
documented parameters, with a name or an exclusion given by `Semantics`
and a live region as its documentation describes
([custom-solutions.md](../custom-solutions.md)).

What each meets and does not, by platform, as section 3 reads the
criteria:

| Example | Android | iOS | Web |
| --- | --- | --- | --- |
| `good-linear` | 4.1.2: a `ProgressBar` named "Report upload" with a range 0 to 100. 4.1.3: start, halfway, and end announced. Qualification: TalkBack reads the value twice (FL-027) | 4.1.2: name and value; no role (FL-256), so it fails 4.1.2's role under section 3's reading. 4.1.3: announced. The value is read as a bare number (FL-027) | 4.1.2: a `progressbar` named "Report upload 0" (the value in the name, FL-037), `aria-valuenow`. 4.1.3: announced |
| `good-circular` | Named; no role (FL-256): fails 4.1.2's role under the reading. 4.1.3: start and end announced | the same | the same |
| `good-cupertino` | the same as `good-circular` | the same | the same |

In none of them is the indicator's own change announced (FL-254); the
live region is what tells the status, and it does on every platform. Each
test of these limits is written to fail when Flutter changes.

No widgets-layer example is built: the widgets layer has no progress
indicator, and one would be drawn by hand.

### Bad

| Slug | Variant | Defect | Violates | Fails |
| --- | --- | --- | --- | --- |
| `bad-no-label` | Material | `good-linear`'s bar with no `semanticsLabel`, the words above it plain text: the bar is read as its value with no name, "0" | R1 | 4.1.2 (name), under the reading of section 3, on all three |
| `bad-silent-end` | Material | `good-linear` with its status line no live region: nothing tells a screen reader that the upload has started, is halfway, or has ended, and the bar's own changes are not announced (FL-254) | R4 | 4.1.3, on all three |
| `bad-adaptive` | Material | `CircularProgressIndicator.adaptive(semanticsLabel:)`: on iOS, and in a browser on a Mac, the spinner has nothing a screen reader can find (FL-257) | R1 | 4.1.2 (name), under the reading, on iOS and the web on a Mac; none on Android, nor on the web elsewhere, where it is Material's spinner, named |
| `bad-cupertino-bar` | Cupertino | `CupertinoLinearActivityIndicator` as it comes: no name, role, or value (FL-255) | R1, R2 | 4.1.2 (name and value), under the reading, on all three |

- `bad-silent-end` and 4.1.3, as written: "Upload complete" is the result
  of an action and the progress of a process, a status message, shown by
  a change of text that is not a change of context; it has no role or
  property by which assistive technology can present it without focus
  (no live region on any platform, measured in the tree on each), and the
  bar's value changes are not announced either (FL-254). A screen reader
  user finds it only by moving to it. The defect is in the example, not
  the framework: `good-linear` is the same with the line a live region.
- `bad-adaptive` and `bad-cupertino-bar` keep the status line, which
  tells the status as text: what they fail is the indicator's own name
  (and the bar's value), not 4.1.3. A spinner is also non-text content;
  1.1.1 is not claimed, as the status line beside it says the same
  ("Loading started").
- `bad-no-label`'s words "Report upload" are on the screen, and a screen
  reader reads them as text before the bar; but they are not the bar's
  name (each platform's tree: the bar's name is empty and the words are a
  node of their own).

Not built:

- **A bar whose value has a percent sign** (FL-027): a defect of Android's
  range alone, which TalkBack reads better than the default; it is in the
  limitation entry and the probe (p03), not an example with one defect a
  user meets.
- **A value in words**, "2 of 5 files" (FL-258): it fails the framework's
  own check, and in a debug build stops the screen's semantics.
- **A live region round the spinner itself** (the probe's p21), announced
  on all three: a different way to the same end as the status line, not
  needed here.
- **An announcement from code** at the end (the probe's p19): I12's
  subject; spoken on iOS, the web, and by TalkBack, which Android calls
  unsupported (FL-018).
- **A chatty live region**, one announcement at every step: I12 has it
  (`bad-chatty-live-region`).
- **Reduced motion**: the indicators keep turning with animations turned
  off (source read: `material/progress_indicator.dart` and
  `cupertino/activity_indicator.dart` do not read `disableAnimations`),
  and what they expose does not change with it (widget test). Nothing a
  screen reader is given depends on it, so no example.

## 6. Assertions by layer

| Layer | What is asserted |
| --- | --- |
| L1 widget tests | Every good example, in light and dark: the four guidelines at rest, while running, and at the end; the button's focus outline 2 wide and 3:1 or more on the page, and the text contrast guideline with focus on it; a tap, the tap action, Enter, and Space each start the task from rest, which then runs to its end; Tab goes Back, the button, Back, and never to the indicator, which can take no focus, while it runs; the status line a live region with its words at each step; with animations turned off, the indicator exposes the same role, name, and value. `good-linear`: a progress bar named "Report upload", value 0 to 100 at each step, min 0, max 100, and one node with the words. The spinners: no node before and after, while loading named "Loading inbox", no value, `good-circular` a loading spinner and `good-cupertino` no role (FL-255). The colours from the theme as the SDK's defaults use them: the bar on its track 5.00 (light) and 5.46 (dark), on the page 6.12 and 10.90; Cupertino's darkest tick 3.18 and 5.81 on the page, its faintest 1.38 and 1.66 (printed and bounded; section 7). Every example, at 200% text on 320 by 640, at rest, while running, and at the end: no overflow, no text at its line limit or cut short, nothing off the screen. Bad: `bad-no-label`'s bar a progress bar with no name, its words one node with no role, `good-linear`'s named in the same test; `bad-silent-end`'s line "Upload complete" with no live region anywhere on the screen, `good-linear`'s a live region in the same test; `bad-adaptive` as iOS and as macOS a Cupertino spinner with no role, name, or value, and no node named "Loading inbox", `good-circular`'s named as a positive control in the same test, and as Android a named loading spinner; `bad-cupertino-bar` no role, name, value, minimum, or maximum, at rest and while running. Tests run as Android, except where they say iOS or macOS |
| L3 web | `good-linear`: a `progressbar` element, `aria-label` "Report upload 0", `aria-valuenow` 0, min 0, max 100, no `tabindex`, named "Report upload 0" by Playwright and Chromium's tree, and its words no element of their own; `aria-valuenow` 25, 50, 75, 100 in turn after Enter. Announcements, recorded from before the press: exactly "Upload started", "Half uploaded", "Upload complete", polite, and DOM focus still on the button; the spinners' exactly "Loading started", "Inbox loaded". The spinners: no element before; while loading, `good-circular` an element with no role, `aria-label` "Loading inbox", no value, `good-cupertino` an element with the text "Loading inbox" and no role or label, and no `progressbar` in Chromium's tree; gone at the end. Tab from Back goes to the button and never to the indicator. Bad: `bad-no-label` a `progressbar` named "0", its words an element of their own, `good-linear`'s named; `bad-silent-end` nothing announced and no `aria-live` in the semantics tree, `good-linear`'s end announced by the same recorder; `bad-cupertino-bar` an element with no role, label, value, or text, at rest and while running, and no `progressbar`; `bad-adaptive` with `navigator.platform` set to "MacIntel" before load, an element with nothing and no element named "Loading inbox", and `good-circular` named in the same page; with "Linux x86_64", named. The stops the VoiceOver spec expects above each example's heading are on each screen; the walk judge on made-up walks (as C04's) |
| L3 Android | `good-linear`: a `ProgressBar` named "0, Report upload", a float range 0 to 100, current 0, not clickable, and no node with its words; after the click action the range's current 25, 50, 75, 100 in turn, and the name "100, Report upload". The good status lines polite live regions, with their words at each point. The spinners: none before; while loading an `android.view.View` named "Loading inbox" with no range (FL-256); gone at the end. Four Tabs reach the button and never the indicator; Tab to the button and Enter start the upload. Bad: `bad-no-label` a `ProgressBar` named "0", its words a node of their own, `good-linear`'s named; `bad-silent-end` no live region anywhere, `good-linear`'s polite; `bad-adaptive` Material's spinner, named (the defect is not on Android); `bad-cupertino-bar` no `ProgressBar` anywhere, and the bar's node, if there, with no name, text, or range, at rest and while running |
| L3 iOS | `good-linear`: a static text element labelled "Report upload", value "0", then "25", "50", "75", "100" after a tap; one element with the words. The good status lines' words at each point. The spinners, read from snapshots: none before; while loading a static text element labelled "Loading inbox" with no value, the only element with that label; gone at the end. Two Tabs and Return start the upload (that a Tab reached the button is shown by Return; no modifier keys). Bad: `bad-no-label` an element with no label and the value "0", the words another element, `good-linear`'s labelled; `bad-adaptive` the spinner's node with no label or value and no element labelled "Loading inbox", `good-circular`'s labelled in the same test; `bad-cupertino-bar` the bar's node, if there, with no label or value, at rest and while running |
| L4 TalkBack | `good-linear`'s and `bad-silent-end`'s bar: "Report upload" and "Progress bar"; `bad-no-label`'s "Progress bar" without "Report upload". Each button its words and "Button". After the click action, with TalkBack focus left on the button, nine seconds: `good-linear`, `bad-no-label`, `bad-cupertino-bar` "Upload started", "Half uploaded", "Upload complete"; the spinners and `bad-adaptive` "Loading started", "Inbox loaded"; `bad-silent-end` none of the upload's words, and then its status line, with focus put on it, "Upload complete" |
| L4 VoiceOver iOS | Each screen at rest, every utterance after the "Example" heading to its end as a whole list: `good-linear` and `bad-silent-end` "Upload report Button", "Report upload 0", "Not started"; `bad-no-label` "Report upload", "0"; `bad-cupertino-bar` "Report upload", "Not started" with no bar. While each task runs, the cursor on the button and the button pressed with a tap at its place: every expected status phrase heard, in order (none for `bad-silent-end`, whose status line two moves forward then reads "Upload complete"). While loading, with the cursor left on the button, one move back and three forward 0.8 s after the tap: the heading, the button, then `good-circular` and `good-cupertino` "Loading inbox", `bad-adaptive` "Loading started", the spinner passed over and never read; the fourth move the status line as it is by then, "Loading started" or "Inbox loaded" (section 7) |
| L4 VoiceOver web | Each screen at rest, walked from Back and judged against the whole screen in order (`judgeExampleWalk` in `web_tests/vo/c26_vo_walks.js`, as C04's), in Chromium and WebKit; no runner retries. Enter on the button with VoiceOver's last phrase polled for eight seconds (Chromium only): the good examples' status phrases, and none of the upload's for `bad-silent-end`, with capture shown live after. The lists are predictions until the first recording (section 7) |

## 7. What the build found (Flutter 3.47.5)

The probe that came first is in [evidence/probes/c26](../evidence/probes/c26/README.md).

- **No indicator's change is announced**
  ([FL-254](../flutter-limitations.md#fl-254), new), with the screen
  reader on the indicator or not, on any platform. A live region is the
  way, and every platform announced one: a status line (p18, p22), a live
  region round the spinner (p21), and, on iOS and the web and by
  TalkBack, an announcement from code (p19).
- **A spinner has no role anywhere, and on iOS no indicator has one**
  ([FL-256](../flutter-limitations.md#fl-256), new).
- **Cupertino's indicators give nothing**
  ([FL-255](../flutter-limitations.md#fl-255), new), and the **adaptive
  spinner drops its label** on iOS and in a browser on a Mac
  ([FL-257](../flutter-limitations.md#fl-257), new).
- **A value in words fails the framework's check**, and in a debug build
  no semantics are sent for the screen
  ([FL-258](../flutter-limitations.md#fl-258), new). The default value is
  the percentage as a number, not "40%" as the documentation says.
- **FL-027, extended**: the cause read in the engine; and how each
  reader reads the default value (TalkBack twice, VoiceOver on iOS as a
  bare number) and a percentage.
- **On the web a node whose role changes loses its identifier**
  ([FL-259](../flutter-limitations.md#fl-259), new): the probe's first
  round lost its changing bars' identifiers when they went from
  indeterminate to determinate. The examples' bars are determinate from
  the start.
- **TalkBack speaks a live region behind time.** In the probe's p18 a
  status line that changed every 1.2 s was spoken seconds late, into the
  next fixture's capture. The examples' status lines change three times
  in four seconds.
- **An animated indicator and XCUITest**: in the probe's first iOS round,
  element queries waited a long time while a spinner turned (each fixture
  took a minute or more; why was not measured). The second round read
  each screen from one `snapshot()`, at once. The iOS tests read the
  spinners from snapshots.
- **The Android suite at CI's size**, 320 by 640 at 160 dpi, passed
  (`docs/evidence/probes/c26/android_320x640.txt`, with the script
  `android_320x640.sh.txt`; the size and density reset after).
- **Colours** (widget tests, from the theme as the SDK's defaults use
  them): Material's bar is 5.00:1 on its track in light mode and 5.46:1 in
  dark, and its track is 1.22:1 and 2.00:1 on the page: where the track
  ends is hard to see. The status line says the same in words, so the
  track is not needed to understand the progress, and no 1.4.11 failure
  is claimed. Cupertino's spinner draws eight ticks at alphas from 47 to
  147 of its tick colour: the darkest is 3.18:1 on the page in light mode
  and 5.81:1 in dark; the faintest 1.38:1 and 1.66:1. Whether the faint
  ticks are needed to see a spinner was not decided; 1.4.11 is not this
  technique's criterion, and no failure is claimed.

Skips and what they give up, in the tests:

- The widget tests run as Android, as iOS and macOS only for
  `bad-adaptive`. Time is pumped in frames of 100 ms.
- The colours are read from the theme as the SDK's defaults use them
  (source read), not from the pixels drawn.
- On the web, Playwright's Chromium runs on Linux in CI and on a Mac
  here; `bad-adaptive`'s tests set `navigator.platform` through Chromium's
  own override before the page loads, and a real Mac's browser was used
  only by the probe.
- The iOS tests read the spinners from one `snapshot()` each time, not
  from element queries. XCUITest cannot read a live region: whether a
  status line is announced on iOS is the VoiceOver test's.
- On iOS a Tab is shown to have reached the button only by what Return
  does; no key with a modifier is sent. Return is sent as "\n" 0.9 s
  after each Tab, as C12's and C03's key tests do: in the first run, two
  Tabs 0.6 s apart and `XCUIKeyboardKey.return` left the status "Not
  started" (`docs/evidence/probes/c26/ios-tab-round1-fail.txt`); which
  key did not arrive was not found.
- `talkback.py` walks an element again, up to three walks, when its
  speech fails its checks (a shared tool, unchanged).
- The iOS VoiceOver reading while loading took three runs to settle
  (`docs/evidence/probes/c26/voiceover-ios-round1-fail.md.txt` to
  `round3-fail`). In the first two, two moves forward made 0.5 s and then
  about 1.5 s after the tap read "Loading started", the status line, twice,
  for the named spinners as for `bad-adaptive`; why was not found. The
  test now moves back once first, which read the heading: the cursor was
  on the button. Then the named spinners were reached. The fourth move
  accepts the status line in either state, because in the third run the
  load had ended by then for `bad-adaptive` ("Inbox loaded"); what it
  gives up is which state the status was in at that moment. Whether a
  VoiceOver user moving on from the button straight after the press
  reaches a new spinner was therefore not settled.
- The iOS VoiceOver walk is C03's: it ends where moving on gives the last
  utterance again, twice. The status phrases are read with
  `currentSpeech()` every 200 ms; a phrase spoken and replaced within
  that time could be missed, and would fail the test. Utterances are cut
  at 64 characters; the longest here is under 30.
- The web VoiceOver lists are predictions until the first recording, which
  the principal makes.

**Not done yet.** What VoiceOver says on the web for a progress bar and
a spinner (the recording, by the principal). A release build on Android
and iOS with a value in words (FL-258). A native Android `ProgressBar`
and a UIKit progress view, for comparison. Right-to-left. A real Android
keyboard.

## 8. Decisions for the owner

- **No role, no workaround.** A spinner has no role on any platform, and
  no indicator has one on iOS ([FL-256](../flutter-limitations.md#fl-256)).
  Under this spec's reading of 4.1.2 (section 3), `good-circular` and
  `good-cupertino` fail its role everywhere, and `good-linear` on iOS,
  with no workaround in the SDK. Open: whether C26 is a
  `PlatformStatus.limitation` there, whether the spinners are still called
  good, and whether the reading itself (an indicator as a user interface
  component) stands. Until decided, the catalog says "applies" with a
  note on each platform, and the examples are kept as built.
- **The value's form** ([FL-027](../flutter-limitations.md#fl-027)): the
  good bar keeps the default value, for Android's range, over a percent
  sign, which TalkBack and VoiceOver read better. Open to the owner.

## 9. What is handed on

- **C25 Meter**: FL-027's cause and the default value's readings apply to
  any `SemanticsRole.progressBar` node.
- **I12 Announcements**: TalkBack speaks a fast-changing live region
  seconds late (the probe's p18).
