# Wave 1: forms

Run from 2026-11-17 to 2026-11-19, the first wave built in parallel: a
principal and up to two engineers, each engineer in a worktree of its own,
sharing the devices through the lock. It built the five form techniques
that were left.

## What was built

| Technique | Pull request | Limitations added |
| --- | --- | --- |
| F09 Switch | 164 | FL-100 |
| F10 Slider | 166 | FL-120 to FL-127 |
| F02 Input instructions | 167 | FL-140 to FL-142 |
| F03 Keyboard types | 170 | FL-160 to FL-163 |
| F06 Error identification and announcement | 175 | FL-180 to FL-184 |

Decisions the owner made during the wave, recorded in the specs:

- F03: the web is a limitation with no workaround for autofill purpose
  (FL-161), and the spec says so outright. `bad-no-purpose` and
  `good-sign-in` stay in F03.
- F06: Android is recorded as applying, with FL-180 called out, because the
  error is identified, described, and announced there and only the reading
  on the field is missing. F06's fields carry `Semantics(identifier:)` and
  not `TestId`, whose `MergeSemantics` would take in the error text
  (FL-183).

## Changes outside the techniques

- The Android CI job ran the runner out of memory, and lost its log readers
  part way through a run (pull requests 163 and 165). The emulator's system
  error dialogs are turned off (173).
- Three device tests that passed here failed on CI and were steadied (171).
  An F10 slider test read the slider's value once after a key; it now waits
  for the new value (176).
- The shared Android helper that reads an example's count scrolls to it when
  it is out of view (179).
- Until 2026-12-01 a pull request merges on an approving Codex review of its
  final commit and a green CI run on that commit. From that date it needs
  Codoki's "safe to merge" as well, as before.

## Test-tool findings

- The CI Android emulator is 320 by 640 at 160 dpi. The local emulator is
  much larger. Tests that passed locally failed on CI because a control or
  a count was off the screen. A
  technique's Android suite is now run once at the CI size before it is
  pushed: `adb shell wm size 320x640` and `adb shell wm density 160` inside
  the lock, and both reset afterwards.
- CI runs iOS 26.5 on an iPhone 17 Pro with Xcode 26.6. The local simulator
  is iOS 27.0 with Xcode 27.1. A test has to hold on both.
- A value read once, straight after a key or a tap, can be the old value on
  the CI emulator. Read it in a loop with a bound, until it is the expected
  one.
- A failing iOS run on CI spends about ten minutes collecting diagnostics
  before it reports.
- `XCUIVoiceOverService` returns the first 64 characters of an utterance,
  as the wave before found. A check on a longer phrase can only be on its
  start.
- The local simulator now and then loses a typed letter. A letter that is
  part of what a test proves is sent once and never retried; only setup
  typing is retried.
- Hosted-runner failures seen at least three times in the wave and not
  caused by a change: the Android emulator going "device offline", a CMake
  build failure, and HTTP 429 while downloading. A re-run of the failed job
  passed each time.

## For later waves

- Merging one technique makes every other open technique branch conflict in
  `README.md`, `lib/techniques/all_techniques.dart` and
  `docs/flutter-limitations.md`, and a pull request with conflicts gets no
  CI run. Merge main into the branch, take either side of the two generated
  files and regenerate them, and keep both sides of the limitations file in
  id order.
- In that merge git treats the last line of an entry,
  `- Upstream issue: not searched yet (D25).`, as shared by both sides, so
  the last entry of the lower block loses it. Check that every entry still
  has the line. This went wrong twice.
- Review lessons that held for every technique: claim a criterion failed
  only as it is written, with its exceptions, and by platform; commit every
  measurement that is cited; give a test that says "nothing happens" a
  positive control through the same path in the same launch; do not let an
  empty or stale screen-reader capture pass; make a limitation's platforms
  match its probe output.

## Follow-ups not done

- `tool/technique_list.dart` crashes on a technique doc that has no title.
- F02's spec gives the wrong names to F04 and F05.
- F01's placeholder test does not assert the exact value.
- S15's docs still call FL-042 "seen once".
- CI is still on GitHub-hosted runners. Moving it to Namespace runners is
  pull request 172, open, waiting on one question about who may start a job
  on them.
