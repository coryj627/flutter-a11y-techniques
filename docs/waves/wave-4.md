# Wave 4: keyboard, focus, and touch

Run from 2026-11-18 to 2026-11-20, partly alongside wave 1, by a principal
and up to two engineers. It built the seven techniques of batch 5 that
were left. It ran before waves 2 and 3 because its techniques shared no
files with theirs.

## What was built

| Technique | Pull request | Limitations added |
| --- | --- | --- |
| I01 Focusable and clickable controls | 168 | FL-400 to FL-402 |
| I02 Keyboard focus order | 174 | FL-420 to FL-422 |
| I03 Focus management | 178 | FL-440 to FL-442 |
| I08 Dismiss and escape | 181 | FL-480 to FL-483 |
| V14 Focus indicators | 185 | FL-430 to FL-435 |
| I04 Keyboard actions and shortcuts | 180 | FL-460, FL-461, FL-463, FL-464 |
| V13 Touch target size | 182 | FL-410 to FL-413 |

## Changes outside the techniques

- `PageScaffold` puts a `FocusTraversalGroup` around its scrolling view, so
  the app bar's Back button stays out of a scrolled page's focus order
  (pull request 169, FL-422).
- The Android CI job has 50 minutes for its tests (186).
- Gradle is given less memory on the Android CI runner (187). Before it,
  the lowest free memory seen during a run was 594 MB; in the runs after
  it, 2.4 GB to 3.1 GB.
- Device tests steadied after failing on CI and passing here: I01's tap
  point on Android (177); F06's whole-page reading on Android, which now
  waits for a settled end of the page (187, 188); F03's wait for the
  keyboard and I03's Tab after a dialog opens, on Android (189); I02's
  Shift+Tab test on iOS, which runs on iOS 27 and later only (195).

## Test-tool findings

- **Modifier keys on CI's iOS 26.5.** Tests that send a key with a
  modifier through XCUITest's `typeKey` passed in some runs and failed in
  others on CI's simulator. They passed on the local iOS 27.0 simulator.
  I08's Escape tests (sent as Command+period), I04's Control+F test, and
  I02's Shift+Tab test are skipped below iOS 27; issue 78 tracks it. Each
  spec says what was measured on iOS 27.0 alone. Whether the modifier was
  lost was not measured.
- **XCUITest could not send Home, End, Page Up, or Page Down**: they never
  reached Flutter (I04's spec). The iOS tests do not send them.
- **On the web, a browser's own keyboard shortcuts were not measured.**
  I08's web tests send the history event that Back causes, and its spec
  keeps the two apart.
- **`TestId` puts a `MergeSemantics` around its child.** Round a field it
  takes in the error text below the field (FL-183). Use
  `Semantics(identifier:)` where the parts must stay separate.
- **A keyboard registered through the shell's `uinput` tool** on the
  Android emulator is what V14's Android test types with: its keys turn
  focus highlights on, which keys from the virtual keyboard device do not
  (FL-433). I01 to I03 were written before this was found and send their
  keys the old way. They have not been moved to it.
- **The text in the app changes the layout on CI's screen.** A longer
  defect text in I04's `bad-page-shortcut` came with that example failing
  to open on the Android CI emulator (320 by 640), three runs in three;
  with the text no longer than before, the runs passed. The cause was
  taken from the timing and not measured.
- **A page that fits the local emulator scrolls on CI's.** F06's
  whole-page reading has two paths, with and without a scroll view. The
  local emulator at its own size runs only the second. A run at the CI
  size, which the wave 1 notes ask for, is not the same as a CI run: the
  F03 and I03 failures steadied in 189 never happened here at that size.

## Failures on CI that passed on a re-run

Each of these failed in one attempt and passed when the failed job was run
again, with no change in between. That does not show a change did not
cause them. Where a cause was looked for, it is given; the rest are
unknown.

- Android emulator "device offline".
- A Gradle build that failed in about 30 seconds, twice. The one looked
  at was HTTP 429 from Maven Central while resolving a plugin.
- F03 on Android: the test found no keys in the keyboard window. The
  cause was not found; 189 changed the test (below).
- I03 on Android: after Tab in an open dialog, focus was read as on no
  stop. The cause was not found; 189 changed the test (below).
- F10 on Android: `aTapOnTheTrackSetsTheValue`, once. Not looked into.
- I04 on iOS: `testBadNoArrowKeysLeftDoesNotMove` read "muxch" where
  "muxd" was typed, once. Not looked into.
- I02 on iOS: the Shift+Tab test, in the first attempt of two runs on
  2026-11-20. The cause was not found. Skipped below iOS 27 in 195.
- `gh` calls timing out in the TLS handshake. No effect on a result.

## V14's measure

V14 measures a focus indicator from screenshots: its thickness, and its
contrast against what is next to it. Five implementations of the measure
run one table of cases,
`test/techniques/v14_focus_indicators_measure_cases.json`, 40 cases and 75
runs.

The review took five rounds, and three of them each found another kind of
pixel the measure passed over without saying so. What ended it was writing
down every pixel the walk skips, each with a case and a limit, in the spec
(section 6, item 4). A measure that skips anything should list its skips,
and what it gives up on, before its first review.

The pixel helpers are copied in each layer. Sharing them, as the test
helpers were shared in wave 0, has not been done.

## For later waves

- The merge pitfalls in the wave 1 notes held. One more check after such a
  merge: count the limitation entries and the index rows. They must be
  equal.
- Keep text in the app no longer than it has to be. When a review asks for
  more words in an example, run it at CI's screen size before pushing.
- The changes made to tests after CI-only failures this wave were of
  six kinds:
  - a bounded wait for the expected state in place of a single reading
    (I01's tap point in 177; F06's end of the page in 188);
  - a different reading: F06 reads the whole page, scrolling, where it
    read one screen (187);
  - a longer wait and one more try of a setup step: F03 waits 20 seconds
    for the keyboard and taps the field once more if no keyboard window
    has come (189);
  - a fixed pause: I03 waits a second after the dialog's first stop
    before Tab (189);
  - a skip by version, which gives up coverage on CI: I02's Shift+Tab,
    I04's Control+F, and I08's Escape tests below iOS 27.
  - a change to what a test accepts: I04's two Android tests that type
    in `bad-page-shortcut`'s note (180). On CI, "Leafy" typed there gave
    "Leay"; the local emulator kept every f. The CI log did not record
    the favourites line, so why the f was lost was not seen. The tests
    now accept either result, need the two readings to agree (an f typed
    or taken, never both or neither), and log which. A pass no longer
    shows which of the two happened.
- When a test fails on CI and passes here, keep the log lines in the
  technique's probe folder and cite them from the spec.

## Follow-ups not done

- I04's web VoiceOver transcript (`docs/evidence/I04/voiceover-web.md`)
  has the defect text of `bad-page-shortcut` as it was before the review
  changed it. It needs recording again.
- Moving the Android keys of I01 to I03 to the `uinput` keyboard.
- Sharing V14's pixel helpers.
- Splitting I04's remap test in two, which a reviewer suggested.
- The app's own Back button shows keyboard focus only as Material's
  default does (FL-430). The owner has not decided whether to change it.
- FL-461 describes what a text field's action does to keyboard focus. The
  form techniques that end a field with an action do not mention it yet.
