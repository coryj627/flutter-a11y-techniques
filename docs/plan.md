# Architecture and Vertical-Slice Plan

Status: Draft 1 (2026-11-12). Implements [requirements.md](requirements.md) using
the catalog in [coverage-inventory.md](coverage-inventory.md).

This plan covers the scaffold and the vertical slice (DEL-1). Batches for the
remaining catalog are planned after the slice, once its unknowns are settled.

## 1. What was checked for this plan

| Fact | Source | Status |
| --- | --- | --- |
| Local toolchain: Flutter 3.47.5 (stable, via fvm), Dart 3.13.4, Xcode 27.1, Android SDK, Node 26 | Local machine | Checked |
| Latest stable Flutter is 3.50.0 | [Flutter release notes](https://docs.flutter.dev/release/release-notes) | Checked |
| Web semantics is opt-in; `SemanticsBinding.instance.ensureSemantics()` enables it at startup | [Flutter web accessibility](https://docs.flutter.dev/ui/accessibility/web-accessibility) | Checked |
| `Semantics(role: SemanticsRole.…)` maps to ARIA roles on web; several web fixes (slider, route landmarks, dialog focus, Escape on tooltips, 500% zoom) need Flutter 3.50+ | Same page | Checked |
| `SemanticsRole` in the local 3.47.5 SDK includes tab, tabBar, tabPanel, dialog, alertDialog, table, cell, row, columnHeader, spinButton, comboBox, menuBar, menu, menuItem, list, listItem, form, tooltip, progressBar, radioGroup (list may be incomplete) | Local SDK source | Checked |
| `flutter_test` guidelines: `androidTapTargetGuideline`, `iOSTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline` | [Flutter accessibility testing](https://docs.flutter.dev/ui/accessibility/accessibility-testing), local SDK | Checked |
| Guidepup automates VoiceOver on macOS (and NVDA on Windows) with a Playwright integration; MIT | [guidepup/guidepup](https://github.com/guidepup/guidepup) | Checked (README only) |
| Widgetbook has Text Scale and Theme addons, an experimental Semantics addon, and a deprecated Accessibility addon | [Widgetbook docs index](https://docs.widgetbook.io/llms.txt) | Checked (index only) |
| Widgetbook can show Markdown documentation per use case | — | **Not confirmed** |
| UI Automator can read Flutter's semantics tree without extra setup | Spike K1 | Confirmed on Android and with XCUITest on iOS; Espresso sees only the `FlutterView` |
| `Semantics(identifier:)` surfaces as a stable locator | Spike K2 | Confirmed on web, Android, and iOS; tree position differs on iOS |
| VoiceOver speech can be captured on an iOS Simulator | `XCUIVoiceOverService` (iOS 27), Xcode 27.1 SDK headers and spike K7 | Confirmed for a Flutter app, including announcements (second spike, D27) |
| TalkBack speech can be captured from an emulator | Spike K6 | TalkBack runs; text capture **not yet achieved** |

Everything marked not confirmed is resolved by a spike in phase 1 before anything
is built on top of it.

## 2. Architecture

### 2.1 Repository layout

```
lib/
  main.dart                  entry point; enables web semantics (APP-4)
  app/                       shell: catalog list, technique screen, about, routing
  catalog/                   Technique model, registry, platform applicability
  techniques/<id>/           one folder per technique
    technique.dart           metadata + list of examples
    good_*.dart              good examples (Flutter SDK only, TEC-3)
    bad_*.dart               bad examples
docs/
  techniques/<id>.md         single source for each technique's documentation (DOC-3)
test/techniques/<id>/        widget tests: semantics + guidelines (VAL-1)
(integration_test/ was planned here and dropped, D22)
android/app/src/androidTest/ UI Automator tests (VAL-2)
ios/RunnerUITests/           XCUITest tests (VAL-2)
web_tests/                   Playwright tests; Guidepup VoiceOver tests (VAL-2, VAL-4)
widgetbook/                  Widgetbook project depending on the app package (APP-2)
evidence/<id>/               committed speech transcripts + version metadata (VAL-11)
tool/                        generators and run scripts
.github/workflows/           CI (VAL-7)
```

One Flutter app (D2). Widgetbook is a second Flutter project in the same repo
that imports the technique code by path, so examples are written once.

### 2.2 Technique model

Each technique registers:

- `id` matching the inventory (for example `C01`), title, and group
- platform applicability: Android / iOS / Web, each `applies`, `notApplicable`, or
  `limitation` with a Flutter issue link (CAT-4, TEC-6)
- WCAG success criteria (TEC-1)
- examples: each has a stable slug, kind (good or bad), variant (Material,
  Cupertino, or widgets layer), a builder, and for bad examples the named defect
- sources: every link cited (DOC-1)

Every example is reachable at a stable route, `/t/<id>/<example-slug>`, so each
test layer can open it directly: by URL on web, by deep link or launch argument
on Android and iOS.

Test locators use `Semantics(identifier:)`, never visible text, so tests keep
working when wording changes. Whether this surfaces consistently on all three
platforms is spike K2.

### 2.3 Documentation from one source

`docs/techniques/<id>.md` is the source. It has front matter (id, WCAG,
platforms, sources) and fixed sections (DOC-5). From it:

- **Repo:** read directly on GitHub.
- **App:** bundled as an asset and rendered on the technique screen.
- **Widgetbook:** the same asset rendered beside the use case.

A generator in `tool/` checks that the front matter and `technique.dart` agree
and that every link resolves, and fails CI otherwise. Code shown in the docs is
pulled from the real example files by region markers, so documented code is
always the tested code.

Rendering Markdown in the app needs either a third-party renderer or a small
build step that converts Markdown into SDK widgets. This is shell tooling, not a
technique, so TEC-3 allows a package; the renderer must still produce correct
heading, list, and link semantics (APP-3). Chosen in spike K4.

### 2.4 Validation layers

| Layer | Tool | Runs | Asserts |
| --- | --- | --- | --- |
| L1 Widget | `flutter_test` | CI, every PR | Semantics label, role, flags, actions, value; the four guidelines; text scaling to 200% without overflow; contrast |
| ~~L2 Integration~~ | `integration_test` | Dropped (D22) | Its checks are made at L1 and L3: examples open by route, keyboard focus order and activation, state changes |
| L3 Platform tree | Playwright (web), XCUITest (iOS), UI Automator (Android; Espresso cannot see Flutter content, finding K1) | CI, per platform | What the platform accessibility API exposes: ARIA role and name on web; `accessibilityLabel`, traits, value on iOS; class name, content description, state, actions on Android |
| L4 Screen reader | Guidepup + VoiceOver (web, macOS); TalkBack on emulator; VoiceOver on iOS; computer use | Local Mac | Spoken output. Gate where deterministic, transcript otherwise (VAL-5) |

Bad examples are tested at L1 and L3 by asserting the defect is present (VAL-3).

On Android, Flutter exposes semantics as virtual accessibility nodes rather than
real Views, so UI Automator is expected to do most of the work and Espresso to be
limited to what its accessibility checks can see. Confirmed in spike K1.

### 2.5 CI

| Job | Runner | Contents |
| --- | --- | --- |
| analyze-test | Linux | format, analyze, L1, docs generator checks |
| web | Linux | build web, L3 Playwright |
| android | Linux with emulator | L3 |
| ios | macOS with simulator | L3 |
| widgetbook | Linux | builds for web; Android and iOS builds compile-checked |

L4 runs from `tool/` scripts on a Mac and commits transcripts to `evidence/`.

### 2.6 Flutter version

Pin with `.fvmrc` to **latest stable minus one** (APP-5, D21). Today that is the
3.47 line; the installed 3.47.5 is the pin. 3.50.0 has just been released and is
not adopted until the next stable supersedes it.

Consequence: the web accessibility fixes the Flutter docs tie to 3.50 (slider
semantics, named-route landmarks, dialog focus restoration, Escape on tooltips,
500% zoom) are not available on the pin. Techniques that depend on them are
recorded as limitations "fixed in 3.50" (TEC-6) and re-verified on upgrade.

## 3. Vertical slice

Techniques: **C01 Button, S05 Headings, F01 Text fields and labels, I12
Announcements and live regions.** Together they cover a role, a structural
property, a labelled input with state, and dynamic speech output, which is every
kind of assertion the four layers need to support.

### Phase 0 — Scaffold

1. Pin Flutter; create the app for Android, iOS, Web.
2. Shell: catalog list, technique screen (docs + examples), about screen with the
   independence statement (DOC-6), routing with stable example routes.
3. Technique model, registry, platform filtering.
4. README with purpose, independence statement, and attribution (DOC-6, DOC-7).
5. CI `analyze-test` job.

Exit: empty catalog app runs on all three platforms; the shell passes L1
guideline tests.

### Phase 1 — Spikes

Each spike is a throwaway proof using one button example, and ends with a
written finding added to this plan.

| # | Question | Decides |
| --- | --- | --- |
| K1 | Can XCUITest and UI Automator / Espresso read Flutter's semantics tree, and what triggers Flutter to build it under test? | Shape of L3 on mobile |
| K2 | Does `Semantics(identifier:)` give a stable locator in Playwright, XCUITest, and UI Automator? | Locator strategy |
| K3 | What DOM does Flutter web emit for a button, heading, text field, and live region, and can Playwright role queries find them? | Shape of L3 on web |
| K4 | Markdown rendering: package or build step, judged on resulting semantics? Can Widgetbook show it per use case? | DOC-3 mechanism |
| K5 | Does Guidepup drive VoiceOver against Flutter web in Chrome and Safari with repeatable output across three runs? | Where the VAL-5 gate sits on web |
| K6 | Can TalkBack speech be captured from an emulator repeatably? | Gate or evidence on Android |
| K7 | What is achievable for VoiceOver on iOS: simulator, physical device, or Accessibility Inspector via computer use? Read the CVS VoiceOverAutomationTesting doc first. | Gate or evidence on iOS |

Exit: each not-confirmed row in section 1 is replaced with a finding.

#### Findings (2026-11-12, Flutter 3.47.5)

Fixture: `lib/techniques/spike/spike.dart` (throwaway), opened at
`/t/X00/fixture`. Web spike script: `web_tests/spike/spike.spec.js`.

**K3 Web DOM and Playwright — answered.** Release web build, headless Chromium,
Playwright 1.56.

- With `ensureSemantics()` at startup there is no "Enable accessibility"
  placeholder; the tree is present on load.
- Playwright role queries work: `getByRole('button', {name})`,
  `getByRole('heading')`, `getByRole('textbox', {name: 'Email'})`.
- Buttons are `<flt-semantics role="button" tabindex="0">`. A disabled button has
  `aria-disabled="true"` and no `tabindex`; `toBeDisabled()` passes.
- `IconButton(tooltip:)` gives the button the name "Close".
- `TextField` is a real `<input type="text" aria-label="Email">`; `fill()` works.
- `Semantics(header: true)` and the `AppBar` title are `<h2>`. Every heading is
  level 2, including the page title, so S05 must handle levels explicitly.
- `Semantics(link: true, linkUrl:)` is a real `<a href>`.
- `Semantics(liveRegion: true)` does not put `aria-live` on the node. On change,
  the text is written to a separate `<flt-announcement-polite aria-live="polite">`
  element. Assert on that element.
- A `GestureDetector` tap target has no role; a button role query does not find it.
- Click, Enter, and Space all activate a button.
- `Title` sets `document.title`; deep links (`/#/t/X00/fixture`) open directly.
  Flutter sets `<html lang>` to the app locale (`en-US`).
- Heading levels: `header: true` alone always gives `<h2>`.
  `Semantics(headingLevel: n)` gives the real `<h1>`–`<h6>`.
- Tab order can be read by following `document.activeElement` after each Tab
  press. Order on the fixture: Back, Save, Save copy, Save draft, Close, the
  Email input. The disabled button and the `GestureDetector` target are skipped.

**K1 Android — answered for the tree; instrumented test still to write.**
Emulator Pixel_10a, Android 17, debug APK, `adb shell uiautomator dump`.

- The UI Automator tree contains Flutter's semantics with no app changes.
- A route can be opened at launch with the intent extra `--es route /t/X00/fixture`.
- Buttons report class `android.widget.Button`, `clickable`, and their name in
  `content-desc`. The disabled button reports `enabled=false`.
- `TextField` reports class `android.widget.EditText` with `hint="Email"`.
- The `GestureDetector` target is a plain `android.view.View`.
- The dump format has no heading attribute, but an instrumented UI Automator
  test (`androidx.test.uiautomator` 2.4.1, `SpikeTest.kt`) reads
  `AccessibilityNodeInfo.isHeading`, `liveRegion` (1 for the live region),
  `hintText`, and the rest. `By.res("id")` finds identifiers and `click()`
  activates.
- **Espresso cannot see Flutter content.** Its accessibility checks (3.7.0)
  reported one finding, on the `FlutterView` itself, and nothing for the
  unnamed buttons inside it. Espresso 3.6.1 crashes on Android 17. L3 on
  Android is UI Automator only.
- Running `connectedDebugAndroidTest` uninstalls the app afterwards.

**Headings across platforms — `header: true` alone is not enough.**

| Widget | Web | Android `isHeading` | TalkBack | VoiceOver iOS |
| --- | --- | --- | --- | --- |
| `Semantics(header: true)` | `<h2>` | true | "Heading" | not announced |
| `Semantics(header: true, identifier:)` | `<h2>` | **false** | not announced | not announced |
| `Semantics(headingLevel: n)` (with or without `header`, with identifier) | `<hn>` | true | "Heading" | "Heading" |

So `headingLevel` is the only form that worked everywhere. S05 must confirm
this on a clean screen, find the cause of the `header: true` gaps, and record
them as limitations with issue links if they hold. The shell's own
`SectionHeading` uses `header: true` and needs the same fix.

**K2 Identifier locators — answered on all three platforms.**

- `Semantics(identifier:)` becomes `flt-semantics-identifier` on web,
  `resource-id` on Android, and `accessibilityIdentifier` on iOS.
- **Locator rule: wrap the control in `MergeSemantics` with the identifier.**
  `MergeSemantics(child: Semantics(identifier: 'x', child: FilledButton(...)))`
  gives one node carrying role, name, and identifier on every platform:
  web `<flt-semantics role="button" flt-semantics-identifier="x">Save copy`,
  Android `android.widget.Button` with `resource-id` and `content-desc`,
  iOS `Button` with identifier and label. Activation still works.
- A plain wrapper (no `MergeSemantics`) makes a separate identifier node: a
  parent of the button on web and Android, a sibling on iOS. Do not use it.
- **Never put an identifier inside a button.** On Android and iOS it splits the
  label onto a child node and leaves the `Button` with no name, which is itself
  an accessibility defect.
- Around a `TextField` a plain wrapper identifier already lands on the field
  itself on Android and iOS.
- Caution: `MergeSemantics` changes the tree. It is safe around a single
  control, but each technique must check that the merge does not hide the thing
  being demonstrated (bad examples in particular).

**K1 / K2 iOS — answered.** iPhone 17 simulator, iOS 27.0, Xcode 27.1, debug
build, XCUITest target `RunnerUITests` (throwaway `SpikeUITests.swift`).

- XCUITest sees Flutter's semantics with no app changes. `app.buttons["Save"]`,
  `app.textFields["Email"]`, and `app.staticTexts[...]` find the fixture, and
  `tap()` activates the button.
- Element types: Material buttons are `Button`; `TextField` is `TextField` with
  label `Email`; a `header` and the `GestureDetector` target are both plain
  `StaticText`; the live region is `Other` with its text as label.
- The disabled button reports `Disabled` in the tree.
- XCUITest has no public way to read traits, so **a heading cannot be told from
  plain text at L3 on iOS**. Headings have to be checked through speech (L4).
- `Semantics(identifier:)` becomes `accessibilityIdentifier`.
- **A wrapper identifier is a sibling of the button on iOS, not a parent.** It is
  an `Other` element with the same frame, so "find the identifier, then the
  button inside it" (which works on web and Android) finds nothing.
- `MergeSemantics` around the wrapper gives one `Button` node with label and
  identifier (see K2).
- An identifier inside the button splits it on iOS as on Android: an unnamed
  `Button` plus a `StaticText`.
- Launch-time route on iOS: a custom URL scheme works. With `fluttera11y`
  registered in `Info.plist`, `XCUIApplication().open(URL("fluttera11y:///t/X00/fixture"))`
  cold-starts the app on that screen with a Back button. No Dart code was needed.
  (`XCUIDevice.shared.system.open` failed with a Launch Services error; use
  `app.open`.)

**K7 VoiceOver on iOS — answered: speech capture works for Flutter.**
`XCUIVoiceOverService` is in the Xcode 27.1 SDK (`XCUIAutomation.framework`,
iOS 27+): `enable()`, `disable()`, `isEnabled`, `moveForward()`,
`moveBackward()`, `moveIn()`, `moveOut()`, `currentSpeech()`, each returning an
output with `utterance`. Reached through `XCUIDevice.shared.voiceOverService`.
It was first described to us by the
[CVS VoiceOver Automation Testing doc](https://github.com/cvs-health/ios-swiftui-accessibility-techniques/blob/main/iOSswiftUIa11yTechniques/Documentation/VoiceOverAutomationTesting.md).

- It runs in the Simulator and returns what VoiceOver speaks for the Flutter
  fixture: `Save Button`, `Close Button`, `Email Text field Double tap to edit.`,
  `Saved 0 times`, `Fake button` (no role, as intended for the bad example).
- The unnamed button from the inner-identifier case is spoken as just `Button`,
  so speech catches that defect.
- Utterances are cut at 64 characters (seen on a native Settings screen).
- **`header: true` is not spoken as a heading; `headingLevel` is.**
  `Semantics(header: true)` and the `AppBar` title gave `Spike heading` and
  `Fixture` with no `Heading`. `Semantics(headingLevel: 1)` gave
  `Level one Heading`. Apple's Settings app gave `General Heading` through the
  same API. See the headings table above.
- **Live region announcements were not captured.** After activating Save,
  `currentSpeech()` kept returning the focused element (`Save Button`), not
  `Saved 1 times`. I12 needs another way on iOS, or stays evidence-only.
  (Wrong conclusion: the tap had not activated Save. See "The iOS
  announcement spike" below.)
- One `moveForward()` returned "No speech available" on an element between the
  section heading and the fixture; which element was not identified.
- `XCUIElement.tap()` still works while VoiceOver is on.
- Consequence: iOS speech can be a gate (R2 resolved) for name, role, and
  state. It needs an iOS 27 runtime, so the GitHub macOS runner image must
  have Xcode 27.

**K6 TalkBack on emulator — answered: speech can be captured.**

- TalkBack 17.0 is switched on and off from adb with
  `settings put secure enabled_accessibility_services` and `accessibility_enabled`.
- One-time emulator setup: TalkBack settings → Advanced settings → Developer
  settings → Log output level → VERBOSE (and confirm). I did this by driving
  the settings screen from adb. After that every utterance is in logcat as
  `talkback: SpeechControllerImpl: Speaking fragment text="…"`.
- Swipes and key combinations injected with `adb shell input` do not move
  TalkBack focus. What works: an instrumented test that connects with
  `UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES` (without it the test
  switches TalkBack off) and calls `ACTION_ACCESSIBILITY_FOCUS` on each node.
  The host reads the speech from logcat.
- Transcript from the fixture: `Save` / `Button` / `Double-tap to activate`;
  `Close. Button`; `Email` / `Edit box`; `Level one` / `Heading`; the unnamed
  button as just `Button`.
- **Live region speech is captured:** after `ACTION_CLICK` on Save, TalkBack
  spoke `Saved 1 times`.
- Limits: this focuses nodes directly, so it checks what is spoken per element,
  not swipe order. Name, role, and hint arrive as separate fragments. Elements
  below the fold were not reached; the test must scroll.
- Consequence: Android speech can be a gate. It needs an emulator image with
  TalkBack (Google APIs / Play image) and the one-time log setting, both
  scriptable in CI.

**K4 Docs rendering — answered: parse Markdown, render with our own widgets.**

- Widgetbook needs no special feature: wrap each example in our own
  example-plus-docs widget.
- `flutter_markdown` is discontinued; its successor is `flutter_markdown_plus`
  (1.0.12). Its default output fails our own bar: the Markdown heading is not a
  heading on any platform; the link is an `<a>` with no `href` and is not in
  the Tab order on web, and is announced as "Button" by TalkBack (VoiceOver on
  iOS does say "Link"); list items have no list semantics.
- Decision: use the Dart team's `markdown` package as the parser only and
  render the small subset we need (headings, paragraphs, lists, links, code)
  with the shell's own `SectionHeading`, `BodyText`, and `ExternalLink`
  widgets, which the shell tests already cover. `flutter_markdown_plus` is in
  `pubspec.yaml` only for this spike and comes out with the fixture.

**K5 Guidepup and VoiceOver on macOS — answered: the walk is repeatable.**
Guidepup 0.40.0 and `@guidepup/playwright` 0.21.0, macOS 27.0.1, spec in
`web_tests/vo/`, headed Chromium and Playwright's WebKit build (not Safari
itself).

- Result on C01 `good-text`, three runs in each browser, all identical:
  "heading level 2 Example", "Save button", "Cancel button",
  "Learn more button", "Activations: 0". Web speech can be a gate (VAL-5).
- Machine setup is the hard part. `npx @guidepup/setup setup` could not
  configure automation permissions here ("Unable to configure automation
  permissions", with and without `sudo`), and early runs failed with `EPERM`
  on VoiceOver's preferences folder. A later attempt worked, including from
  an agent session, after further setup by the owner; which change fixed it was
  not recorded. See the [manual setup guide](https://www.guidepup.dev/docs/guides/manual-voiceover-setup).
  `npx @guidepup/setup install` downloads Guidepup's VoiceOver preferences.
- Guidepup's `navigateToWebContent()` does not work with these browser builds
  on macOS 27: it activates the browser inside an AppleScript transaction,
  which times out (-1712). A plain `activate` returns in 85 ms. The spec
  activates the browser itself, moves DOM focus to the first control, and
  walks with `voiceOver.previous()` / `next()`.
- Guidepup records only speech that follows its own commands. The item under
  focus has to be reached with a command to be read, and **live region
  announcements are not captured**: after Enter on Save, "Activations: 1" did
  not reach the log. On web the announcement is asserted at L3 instead.
- The run takes over the screen and speaks aloud; it cannot run headless.
  Whether a GitHub macOS runner allows it is untested.
- All thirteen C01 examples are now walked in both browsers
  (`web_tests/vo/c01_button_vo.spec.js`, run by `python3 tool/voiceover_web.py C01`):
  26 of 26 pass, transcript in `docs/evidence/C01/voiceover-web.md`.
- The capture is not perfectly stable. In discovery runs Guidepup sometimes
  returned an empty phrase for an item, and twice VoiceOver's cursor left the
  page (into the browser toolbar, and once into another app's window). The
  config retries a failed walk twice; the final run needed no retries.

**Left in the repo by the spikes (all throwaway unless noted):**
The spike code was removed when C01 was built; `web_tests/vo/` now holds the
web VoiceOver suite. Kept on purpose: the `RunnerUITests` target, the `fluttera11y` URL
scheme in `Info.plist`, and the `androidTest` dependencies and test runner in
`android/app/build.gradle.kts`.

### Phase 2 — First technique end to end (C01 Button)

1. Write the technique spec (`docs/specs/C01-button.md`): examples, defects,
   WCAG criteria, sources, expected assertions per layer.
2. Read the CVS button docs and the APG and MDN button pages; record sources.
3. Build good examples (Material, Cupertino, custom widgets-layer button) and
   bad examples (for example: unlabelled icon button, gesture-only tap target
   with no button role, undersized target).
4. Write `docs/techniques/C01.md`; wire the in-app and Widgetbook rendering.
5. L1 → L2 → L3 on all three platforms → L4.
6. Add the remaining CI jobs.

Exit: C01 is green in every CI job, has evidence committed, and renders in the
app and Widgetbook on all three platforms.

#### Phase 2 status (2026-11-12)

Done for C01, all passing locally on Flutter 3.47.5:

- Thirteen examples, spec, and `docs/techniques/C01.md`.
- L1: widget tests for the examples, the doc renderer, and a check that each
  doc and its registered technique agree (`test/docs/`).
- L3: web (Playwright), Android (UI Automator), iOS (XCUITest).
- L4: TalkBack, VoiceOver on iOS, and VoiceOver on web, with transcripts in
  `docs/evidence/C01/`.
- In-app documentation: the technique screen renders the Markdown doc from a
  bundled asset (`lib/app/doc_view.dart`).
- Widgetbook: `widgetbook/`, built from the same registry, one use case per
  example with the doc underneath; checked on web with Playwright
  (`web_tests/widgetbook.spec.js`).
- Framework issues are logged in [flutter-limitations.md](flutter-limitations.md).

First CI runs (2026-11-13): GitHub's `macos-latest` image is macOS 26 with
Xcode 26.6, which has neither the iOS 27 SDK nor `XCUIVoiceOverService`. The
VoiceOver test is compiled only on Swift 6.4 or later and skips otherwise, so
iOS speech is checked locally until a hosted image has Xcode 27.

CI status: analyze-test, web, and Android (API 35 emulator) pass on GitHub.
The iOS job ran 8 of 9 tree tests green on an iOS 26 simulator; one failed
because an example did not appear after a cold start by deep link, so the
launch is now retried up to three times. Why the first launch came up without
the example is not known (lost URL or a slow runner). They run for the first time when the branch is
pushed. Known unknowns: the Android job uses an API 35 emulator (local runs
were on Android 17), and the hosted macOS image may not have an iOS 27
simulator, in which case the VoiceOver test skips itself.

Still open in this phase: L2 `integration_test` runs on devices (their
keyboard checks are covered in L1 and on web), getting CI green, and filing
upstream issues for the entries in the limitations log.

### Phase 3 — Remaining slice techniques

S05, F01, I12, each following the phase 2 steps. Extract shared test helpers
only after the second technique shows what actually repeats.

Exit: all four techniques done; a technique template and a per-technique
checklist are written from what the slice taught.

#### Phase 3 status (2026-11-13)

S05 Headings is built: eight examples, spec, doc, and tests at every layer
with transcripts in `docs/evidence/S05/`. What repeated, and was extracted:

- The evidence scripts take a technique id: `tool/talkback.py`,
  `tool/voiceover_ios.py`, `tool/voiceover_web.py` (`TECHNIQUES` in
  `tool/evidence_common.py` lists what each one runs).
- The web VoiceOver walk is in `web_tests/vo/vo_helpers.js`.

Not extracted yet: the Android and iOS test classes each carry their own
`open` helper. Two copies are not enough to see the right shape.

Building S05 corrected a spike finding (FL-005) and changed the shell: screen
titles are now level 1 headings.

F01 Text fields and labels is built the same way: nine examples, spec, doc,
tests at every layer, and transcripts in `docs/evidence/F01/`. Its tests type
into each field and check again, which is how the placeholder defect and
FL-015 (TalkBack drops a filled field's label) were found. The Android tests
now wait for each example's own title before reading the screen; waiting for
text every example has could match the previous screen.

I12 Announcements and live regions completes the four slice techniques: seven
examples, spec, doc, tests, and transcripts for TalkBack and for VoiceOver on
web. What it added to the test approach:

- **Web announcements are captured by polling VoiceOver's "last phrase"** over
  AppleScript after a key press (`web_tests/vo/vo_helpers.js`). Guidepup only
  records speech after its own commands. The keyboard drives and VoiceOver is
  observed, the model used in the author's `slate` project.
- **Playwright's WebKit build announces no live regions**, even for plain
  HTML, so announcement speech is checked in Chromium only.
- **iOS announcements can be captured, once the button is really activated.**
  The slice first concluded they could not: `currentSpeech()` kept returning
  the button. The second spike (D27) found the cause. With VoiceOver on,
  `XCUIElement.tap()` only moves the VoiceOver cursor; the button was never
  pressed, so nothing was announced. `doubleTap()` activates it, and
  `currentSpeech()` then returns the announcement. See "The iOS announcement
  spike" below.
- The Android tests look for nodes in every window and retry, because with
  TalkBack running a system dialog can be the active window.

The template and checklist are written:
[technique-guide.md](technique-guide.md),
[technique-checklist.md](technique-checklist.md), and the two files in
[templates/](templates/). Phase 3 is complete.

### Phase 4 — Slice review

1. Record where the VAL-5 gate landed per screen reader.
2. Measure cost per technique and CI time.
3. Revise requirements and this plan with anything the slice disproved.
4. Plan batches for the remaining 98 entries, probing the 27 unknown-feasibility
   entries early.

#### Phase 4 status (2026-11-13)

Written up in [slice-review.md](slice-review.md): the gate per screen reader,
run times, what the slice disproved, the requirements it did not meet, and a
batch plan for the remaining 98 entries starting with a probe of the 27
unknowns.

The review's eight proposals were decided by the owner on 2026-11-13 (D22 to
D29 in [requirements.md](requirements.md)): `integration_test` is dropped;
device and screen reader runs before a merge are scoped to the changed
technique; docs will show code from the example files; Flutter issues are not
filed yet; Playwright's browser builds are accepted for web; iOS announcements
got another spike, which succeeded; the missing visual checks become their own techniques; and
minimum versions follow the pinned Flutter release.

### The iOS announcement spike (D27)

Done on 2026-11-13, iPhone 17 simulator, iOS 27.0, Xcode 27.1.

Research first:

- Apple's documentation for `XCUIVoiceOverService` lists `enable`, `disable`,
  `isEnabled`, `moveForward`, `moveBackward`, `moveIn`, `moveOut`, and
  `currentSpeech`, with an `Output` that carries an utterance. There is no
  call for observing announcements, no speech history, and no activate call.
- The author's `slate` project checks announcements in two ways: unit tests
  record them at the point where the app posts them, and for real VoiceOver
  on macOS a script polls VoiceOver's "last phrase" after a key press. The
  second is what the web check here already does. The first verifies the
  app's intent, not the screen reader.
- UIKit posts `UIAccessibility.announcementDidFinishNotification` inside the
  app when VoiceOver finishes an announcement, with the text and whether it
  was spoken in full.

What was tried, on the I12 examples:

1. An observer for that notification in the app, logging to the system log.
   With `tap()` on the button, nothing arrived and `currentSpeech()` stayed
   on the button, as in the first spike. A control announcement posted by the
   app itself did arrive, so the observer worked: the examples were not
   announcing anything.
2. The example's visible message had not changed either. With VoiceOver on,
   the tap had moved the VoiceOver cursor and not pressed the button.
3. With `tap()` to place the cursor and `doubleTap()` to activate,
   `currentSpeech()` returned "Link copied", "1 item in cart", and "Message
   archived" for the good examples, and the button's own speech for the three
   bad ones. The in-app observer agreed: one finished, successful
   announcement for each good example, none for the bad ones.

Result: `currentSpeech()` after a real activation is enough, so nothing was
added to the app. I12 has an iOS VoiceOver test and transcript, and the
catalog no longer says iOS is unverified. Two things to keep in mind for
later techniques:

- With VoiceOver on, `tap()` focuses and `doubleTap()` activates. Any VoiceOver
  test that needs to operate a control must use the second and check that the
  control really acted.
- The in-app observer is a second route if `currentSpeech()` ever proves
  unreliable. It sees only announcements the app posts (which is how Flutter
  implements live regions and `sendAnnouncement` on iOS), not other speech.

The code-in-docs step (D24) is built: `dart run tool/doc_code.dart` copies
each example's region from `examples.dart` into the "Example code" section of
its technique doc, and `test/docs/doc_code_test.dart` fails when a doc is out
of date or an example has no region.

Next: batch 0, the probes
of the 27 unknown-feasibility entries.

## 4. Definition of done for a technique

The working version of this list is [technique-checklist.md](technique-checklist.md),
written after the slice. The original, kept for the record:

- Spec written and sources linked
- At least one good and one bad example, SDK-only for good
- Doc written from the single source; renders in repo, app, Widgetbook
- L1, L2, L3 passing on every applicable platform; bad-example defects asserted
- Keyboard and text scaling / contrast / reduced motion checked where applicable
  (VAL-9, VAL-10)
- L4 gate passing or transcript committed, with version metadata (VAL-6)
- Limitations documented with Flutter issue links

## 5. Risks

| # | Risk | Response |
| --- | --- | --- |
| R1 | Native test tools see little of Flutter's tree on Android through Espresso | Lean on UI Automator; record what Espresso can and cannot do as a finding |
| R2 | VoiceOver speech cannot be captured on the iOS Simulator | Resolved for focus speech, including headings, by `XCUIVoiceOverService` on iOS 27. Resolved for announcements too by the second spike (D27) |
| R3 | Screen reader speech is not repeatable enough to gate | Gate on normalised phrases (role and name), keep full transcript as evidence |
| R4 | Four test layers per technique across 102 entries is a large cost | Measured in [slice-review.md](slice-review.md). L2 was never built and is proposed for removal; device and transcript runs are proposed to be scoped to the changed technique |
| R5 | Flutter upgrade changes semantics output | Pinned SDK; upgrade is its own change with every suite re-run (APP-5) |
| R6 | CVS mappings were made from titles only | Each spec starts by reading the source docs |

## 6. Decisions needed

1. ~~Flutter pin~~ — decided: latest stable minus one, currently 3.47.5 (D21).
2. ~~Slice techniques~~ — confirmed: C01, S05, F01, I12.
3. **Physical iOS device:** is one available for VoiceOver evidence if the
   simulator cannot do it (R2)?
