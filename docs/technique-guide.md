# How to add a technique

Written from the four techniques of the vertical slice (C01 Button, S05
Headings, F01 Text fields and labels, I12 Announcements). It describes what
worked. The [checklist](technique-checklist.md) is the short form; the
templates are in [templates/](templates/).

## Order of work

1. **Read the sources.** Fetch the CVS docs, the APG pattern, and the MDN page
   named in the [coverage inventory](coverage-inventory.md). The inventory
   mapped them by title; the text often changes the scope.
2. **Probe before you assert.** Build rough examples, then look at what each
   platform exposes: the DOM on web, the node properties on Android, the
   element tree on iOS, and what each screen reader says. Three of the four
   slice techniques changed shape after this step.
3. **Decide the examples from the evidence.** A good example must work on
   every platform that can be checked. If a mechanism only works on one
   platform, it is a bad example with a limitation entry, not a good one.
   The one exception is a labelled web workaround in a limitation entry
   (D32, under "Examples" below): it is neither good nor bad.
4. **Write the tests at each layer**, then the spec's "what the build found"
   section, then the technique doc.
5. **Run the gates**: this technique's suites and transcripts locally (the
   full device and transcript run is scheduled, not per merge), Codex
   adversarial review until it approves, then the PR with green CI and
   Codoki's "safe to merge".

## Files for a technique

For a technique with id `X00` and name `thing`:

| What | Where |
| --- | --- |
| Examples | `lib/techniques/x00_thing/examples.dart` |
| Registration | `lib/techniques/x00_thing/x00_thing.dart`, added to `lib/techniques/all_techniques.dart` |
| Spec | `docs/specs/X00-thing.md` |
| Technique doc | `docs/techniques/X00.md` |
| Widget tests | `test/techniques/x00_thing_test.dart` |
| Web tree tests | `web_tests/x00_thing.spec.js`, added to the web job in `.github/workflows/ci.yml` |
| Web VoiceOver | `web_tests/vo/x00_thing_vo.spec.js` |
| Android | `android/app/src/androidTest/.../X00ThingTest.kt` |
| iOS | `ios/RunnerUITests/X00ThingUITests.swift`, added to the `RunnerUITests` target |
| Speech expectations and test names | `EXPECT` in `tool/talkback.py`; `TECHNIQUES` in `tool/evidence_common.py` |
| Transcripts | `docs/evidence/X00/`, written by the tools, never by hand |
| Limitations | new or updated entries in `docs/flutter-limitations.md` |

The app, the Widgetbook, and the doc check pick a technique up from the
registry; nothing else needs wiring.

## Examples

- **Slugs** start with `good-` or `bad-` and are stable; they are routes and
  test locators. A workaround (D32) is a third kind and will start with
  `workaround-`; the catalog model, app, Widgetbook, and doc tests do not
  support that kind yet, and it must be added before the first one is
  written.
- **Good examples use SDK APIs only**, and every mechanism traces to a source
  in the spec.
- **A bad example has one defect**, stated as what the user experiences, and
  every layer that can see the defect asserts it. Write those assertions so
  they fail if a Flutter upgrade fixes the defect.
- **Region markers** (`// #region good-x` … `// #endregion`) surround each
  example in `examples.dart`. `dart run tool/doc_code.dart` copies each region
  into the "Example code" section of the technique doc, between the
  `example-code` markers; never edit that section by hand. Code the examples
  share goes in a region named `shared`, which the doc shows first; nothing
  but imports and comments may sit outside a region. `flutter test` fails if
  the section is out of date, if an example has no region, or if code is
  outside one.
- **Give the example something to verify.** The Button examples count
  activations; the text field tests type and re-read; the announcement
  examples have a button that changes a message.
- **If a defect cannot be demonstrated, drop the example** and say so in the
  spec. Two I12 examples went this way. This is about bad examples. A
  workaround has no defect to demonstrate; it is kept only if the tests show
  it does what it claims, and is otherwise recorded in the entry as tried
  and why it failed.

## Locators

- Wrap a control in `TestId('x00-<slug>-<name>', child: …)`
  (`lib/catalog/test_id.dart`). It gives one node with role, name, and
  identifier on all three platforms.
- Never put `Semantics(identifier:)` inside a control (FL-007).
- For non-interactive text under test, such as headings, locate by text.
- Put an identifier straight on a status message with
  `Semantics(identifier:, liveRegion:)`.

## Tests by layer

**L1 widget tests.** Open the example through the real app
(`A11yTechniquesApp` with `initialRoute`). For good examples: the four
accessibility guidelines in light and dark, and no overflow at 200% text on a
320 by 640 screen. Then the semantics that matter. Things learned:

- `getSemanticsData()` gives the merged node; `SemanticsNode.label` does not.
- An `IconButton`'s name is in `tooltip`, not `label`.
- Skip the text contrast guideline for examples with a disabled control
  (FL-009).
- Never press Space or Enter while focus may be on the Back button.

**L3 web (Playwright, Chromium).** Use role queries and
`toHaveAccessibleName`. Things learned:

- Wait about 600 ms after load before typing; Flutter attaches text editing
  late.
- Flutter writes announcements to `flt-announcement-polite` and clears them
  after 300 ms. Record them with a `MutationObserver`; do not read once.
- For heading levels, read Chromium's accessibility tree
  (`outline()` in `web_tests/s05_headings.spec.js`).
- Give each direct-link test a fresh page.

**L3 Android (UI Automator).** Things learned:

- Wait for the example's own title, not text every example has.
- With TalkBack on, look for nodes in every window and retry
  (`I12AnnouncementsTest.kt`).
- Type with `sendStringSync` after a click. Setting text through the
  accessibility action leaves a field's hint in place.
- `connectedDebugAndroidTest` uninstalls the app when it finishes.
- Espresso cannot see Flutter content.

**L3 iOS (XCUITest).** Open examples with the `fluttera11y` URL scheme, with
the three-attempt retry. XCUITest cannot read traits, so headings and live
regions cannot be checked in the tree.

**L4 TalkBack.** `python3 tool/talkback.py <ID>`. The walk moves accessibility
focus with the `talkBackFocus` helper and logs a marker per element; the tool
reads TalkBack's verbose log, checks `EXPECT`, retries an element whose speech
failed, and restores the device. For announcements, leave focus alone and
press the button.

**L4 VoiceOver on iOS.** `python3 tool/voiceover_ios.py <ID>`. Swipe through
the example with `XCUIVoiceOverService` and assert whole utterances. With
VoiceOver on, `tap()` only moves the VoiceOver cursor; use `doubleTap()` to
activate a control, and assert that it acted. For announcements, activate
that way, poll `currentSpeech()`, and confirm the cursor is still on the
control, as `I12AnnouncementsUITests` does.

**L4 VoiceOver on web.** `python3 tool/voiceover_web.py <ID>`. Use
`walkFromBack` and stop at a recognised last phrase; do not count steps. For
announcements, press with the keyboard and poll VoiceOver's last phrase
(`heardAfter`), in Chromium only, and call `assertCaptureIsLive` whenever
silence is asserted.

## Findings

- **A Flutter behaviour that hurts accessibility goes in
  [flutter-limitations.md](flutter-limitations.md)** in the same change, with
  what happens, platforms, version, how to reproduce, the workaround, and the
  status. Technique docs link to it.
- **A test-tool problem goes in [plan.md](plan.md)**, not the limitations log.
- **Say "Observed" until a test in the repo reproduces it**, then
  "Confirmed". One spike finding (FL-005) was wrong for a whole phase because
  it was a guess recorded as a cause.
- **A limitation entry says what Flutter has not added yet**, in those
  words, and shows the closest achievable example. Where native HTML embedded
  with `HtmlElementView` can fill the gap on web, show it as a labelled
  workaround: web only, a lesser option, never a good example, no plugins,
  and verified with the same tests as an example (D31, D32).
- **If a platform cannot be verified, say "not verified"** in the doc and the
  catalog (`PlatformStatus.applies(note: …)`). If a limitation has no
  workaround, mark the platform `PlatformStatus.limitation(…)`.

## Controls before conclusions

Twice in the slice a result looked like a Flutter defect and was the test
tool. Before logging a limitation from a screen reader result, run the same
check against a native control or a plain HTML page:

- Apple's Settings app showed that the iOS VoiceOver API does report
  headings, so the missing "Heading" was Flutter's.
- A plain HTML live region showed that Playwright's WebKit build announces
  nothing, so that silence was not Flutter's.
