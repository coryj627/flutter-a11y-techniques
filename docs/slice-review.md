# Vertical slice review

Status: 2026-11-13. Phase 4 of the [plan](plan.md). The slice is the app
scaffold, the Widgetbook, the test and evidence tooling, and four techniques:
C01 Button, S05 Headings, F01 Text fields and labels, and I12 Announcements
and live regions. Flutter 3.47.5.

## 1. Where the screen reader gate landed (VAL-5)

A gate means the run fails when the expected speech is not heard. All of
these run locally on a Mac, not in CI.

| Screen reader | How speech is captured | Gate? | What it can and cannot do |
| --- | --- | --- | --- |
| TalkBack, Android emulator | TalkBack's verbose log, with focus moved or a button pressed by an instrumented test | Yes | Reads what is spoken per element and after an action. Does not exercise swipe order. A system notification is sometimes spoken over an element; a failed element is walked again, up to three walks, and the transcript lists every retry |
| VoiceOver, iOS simulator | `XCUIVoiceOverService` (iOS 27) | Yes, for focus speech | Reads the element VoiceOver is on, in swipe order. Utterances are cut at 64 characters. Cannot observe announcements, so I12 is not verified on iOS |
| VoiceOver, macOS, Chromium | Guidepup for the swipe walk; VoiceOver's "last phrase" polled over AppleScript for announcements | Yes | Both walks and announcements. Guidepup sometimes returns an empty phrase; a failed walk is retried and the transcript says so |
| VoiceOver, macOS, WebKit | Guidepup for the swipe walk | Yes, for focus speech | Playwright's WebKit build passes no live region changes to VoiceOver, even for plain HTML, so announcements cannot be checked there |

Not met from VAL-8: the web runs use Playwright's Chromium and WebKit builds,
not Chrome and Safari themselves. Driving the real browsers has not been
tried.

## 2. Cost

### Per technique

| | C01 | S05 | F01 | I12 |
| --- | --- | --- | --- | --- |
| Examples (good / bad) | 6 / 7 | 2 / 6 | 3 / 6 | 3 / 4 |
| Limitations log entries first recorded | 10 | 4 | 2 | 2 |
| Codex review rounds to "approve" | 10 | 1 | 2 | 4 |
| Examples changed after probing the platforms | 1 added | 1 corrected | none | 2 dropped, 2 moved from good to bad |

The C01 column includes the scaffold, the spikes, the app shell, and the first
version of every tool, so it is not the cost of a technique. S05 and F01 are closer to
the steady state. I12 cost more because announcements needed a new way to
capture speech on web and could not be captured on iOS.

What took the time was not writing examples or tests. It was finding out what
each platform really does, and making the screen reader capture reliable.

### Test run times (local)

| Suite | Time |
| --- | --- |
| Widget tests, all 160 | about 3 seconds |
| Script tests, 59 | about 6 seconds |
| Playwright, all app suites (63 tests) | about 30 seconds, after a 15 second web build |
| Android instrumented tests, all 33 | about 2 minutes, plus emulator start |
| iOS UI tests, all 17 without VoiceOver | about 4 minutes |
| TalkBack transcript, one technique | 4 to 5 minutes |
| VoiceOver on iOS transcript, one technique | about 4 minutes |
| VoiceOver on web transcript, one technique | 3 to 7 minutes, and it takes over the screen |

A full local pass for one technique, all suites and all three transcripts, is
about 25 minutes of machine time. Regenerating every transcript for all four
techniques is about an hour, and the web part cannot run unattended in the
background.

### CI (GitHub Actions, per pull request)

| Job | Typical time |
| --- | --- |
| `analyze-test` | 1 to 2 minutes |
| `web` | 3 to 4 minutes |
| `android` | 7 to 10 minutes |
| `ios` | 6 to 18 minutes, the slowest and most variable |

The iOS job runs on Xcode 26, so the VoiceOver tests compile to a skip there.
No screen reader speech runs in CI.

### What this means for 98 more entries

- Device and screen reader time grows with every technique, because the full
  suites are rerun before each merge. At 100 techniques the full Android and
  iOS suites would be roughly 50 and 100 minutes at today's rate.
- The answer is to run only the changed technique's device suites before a
  merge, and the full device and transcript run on a schedule or before a
  release. This is a change to how the work is done and is proposed in
  section 4.

## 3. What the slice disproved or changed

### Assumptions that were wrong

| Assumed | Found |
| --- | --- |
| `Semantics(header: true)` makes a heading | Not on any platform reliably; only `headingLevel` does (FL-003, FL-004, FL-005) |
| A test identifier can go anywhere | Inside a control it strips the control's name (FL-007). `TestId` is the one safe pattern |
| A Markdown package can render the docs | Its output was not accessible. The docs are parsed and rendered with the shell's own widgets |
| A lazy `ListView` is fine for pages | It exposes only content near the viewport (FL-011). The shell uses a non-lazy layout |
| Espresso would cover part of Android | It cannot see Flutter content. UI Automator only |
| iOS VoiceOver speech could not be automated | It can, for focus speech, with the iOS 27 API |
| Guidepup's defaults would work | Its setup and navigation step do not work on macOS 27; the specs activate the browser and capture announcements themselves |
| A spike finding is a fact | FL-005 was a guess recorded as a cause, and stayed wrong until S05 read the engine source |

### Requirements not met by the slice

These are gaps against [requirements.md](requirements.md), stated plainly.
None has been changed in the requirements; section 4 proposes what to do.

| Requirement | Gap |
| --- | --- |
| VAL-1 | `integration_test` on each platform was never built. Its planned checks (routes open, keyboard reach and activation) are covered by the widget tests, the web suites, and the platform tree tests |
| VAL-8 | Web screen reader runs use Playwright's browser builds, not Chrome and Safari |
| VAL-9 | Keyboard is verified in widget tests and on web. Focus visibility is not asserted anywhere. Keyboard on Android and iOS devices is not run |
| VAL-10 | Text scaling to 200% and light and dark contrast are checked. Zoom, high-contrast mode, and reduced motion are not |
| DOC-5 | Technique docs describe the code in a table but do not show the code. The region markers that were meant to feed code into the docs are in place and unused |
| TEC-6 | Limitations are documented with reproduction and workaround, but no Flutter issue has been filed or linked for any of the 18 entries |
| APP-2 | The Widgetbook shows every example on every platform; it does not filter by platform. No technique so far is platform-specific |
| VAL-4 | Agent-driven computer use was not needed and was not used |
| I12 on iOS | Not verified: announcements cannot be captured |

### Things that held

- One catalog feeding the app, the Widgetbook, and the doc check.
- Bad examples asserted to fail: it caught real upgrade-sensitive behaviour
  and forced two examples to be dropped when the defect could not be shown.
- Speech as a gate, not only evidence, on three of four screen reader setups.
- The limitations log as the single place for framework findings.
- An adversarial review before each pull request: it found real defects in
  every technique except one.

## 4. Proposals for the owner

Each of these changes a requirement or how the work is done, so each is a
decision for the project owner, not something to adopt silently.

1. **Drop `integration_test` as a separate layer (VAL-1), or build it once
   for the shell only.** It would repeat what three other layers assert.
   Recommended: drop it and reword VAL-1 to name widget tests plus platform
   tree tests.
2. **Before each merge run the changed technique's device suites; run
   everything on a schedule.** Otherwise run time grows linearly with the
   catalog.
3. **Show code in the technique docs** from the region markers, with a small
   build step, to meet DOC-5.
4. **File the Flutter issues.** The log has 18 entries with reproductions.
   This is public posting under the owner's account, so it needs the owner's
   go-ahead; drafts can be prepared.
5. **Decide the web browsers for VAL-8**: accept Playwright's builds and
   reword the requirement, or spend a spike on driving Chrome and Safari.
6. **Decide how iOS announcements get verified**: a manual check recorded as
   evidence, or a spike on another capture route.
7. **Add the missing VAL-10 checks** (reduced motion, high contrast, zoom) as
   their own techniques (V02, V06, V09 in the inventory) rather than as
   checks on every technique.
8. **Answer the open question on minimum OS and browser versions.**

## 5. Batches for the remaining 98 entries

The inventory has 102 entries; 4 are done. 27 are marked `?` for unknown
feasibility. The slice showed that feasibility is only known after probing,
so the unknowns are probed first, cheaply, before any is built out.

### Batch 0: probe the 27 unknowns

One short probe each: is there an SDK mechanism, and what do the three
platforms expose? The result is a line in the inventory (feasible, limitation,
or not applicable) and, where relevant, a limitations entry. No examples, no
full tests.

S07 Landmarks and regions, S18 Pronunciation, S19 Inline text semantics, S20
Block text structure, S21 Custom content, V04 Inverted colours, V08 Large
content viewer, V10 Reduced transparency, V11 Button shapes and borders, I05
Custom accessibility actions, I06 Action labels, I09 Magic Tap, I10 Rotor, I11
Voice input labels, I17 Assistive Access mode, C15 Menubar, C19 Data table,
C20 Interactive grid, C21 Tree view, C22 Treegrid, C23 Feed, C24 Window
splitter, C25 Meter, C28 Maps, C29 Video and audio, C30 Embedded web and
platform views, C31 Math content.

### Then, in order

Ordered so that each batch reuses what the one before it built, and so the
most common controls come first.

| Batch | Entries | Why together |
| --- | --- | --- |
| 1. Names, roles, and images | S01, S02, S03, S04, S13, S14, S15, S22 | The basic semantics every later technique relies on. S22 documents the `TestId` pattern already in use |
| 2. Form controls | F07, F08, F09, F10, F02, F03, F06 | Reuse the F01 type-and-recheck tests; checkbox, radio, switch, and slider share state and value assertions |
| 3. Links and simple components | C02, C03, C04, C05, C06, C12, C13, C18, C26 | Small components. C04 settles the inline-link question the doc renderer avoided; C13 builds on I12 |
| 4. Structure and order | S06, S08, S09, S10, S11, S12, S16, S17 | Titles, lists, grouping, reading order, hiding, language, and direction. S08 must face lazy lists (FL-011) |
| 5. Focus and keyboard | I01, I02, I03, I04, I08, V14, V13 | Focus order, management, shortcuts, escape, focus indicators, target size. Needs a way to assert focus visibility |
| 6. Dialogs and overlays | C08, C09, C10, C11, C14, C16 | All need focus management from batch 5, and dialog titles left open by S05 |
| 7. Visual preferences | V01, V02, V03, V05, V06, V07, V09, V12 | Contrast, themes, scaling, reflow, orientation, motion. Closes the VAL-10 gaps |
| 8. Remaining forms | F04, F05, F11, F12, F13, F14, F15, F16, F17, F18 | Pickers, comboboxes, and less common inputs |
| 9. Navigation and complex components | I07, I13, I14, I15, I16, C07, C17, C27 | Tabs, carousel, charts, navigation, drag alternatives |
| 10. Whatever batch 0 found feasible | from the 27 | Sized once the probes are in |

Each batch is a set of pull requests, one technique each, through the same
gates. The batch list is a plan, not a commitment: batch 0 will move entries
between "build", "limitation", and "not applicable".
