# Wave 2: links and simple components

Run from 2026-11-20 to 2026-11-26 by a principal and up to two engineers
building at a time, each in a worktree of its own. It built the nine
techniques of batch 3.

## What was built

| Technique | Pull request | Limitations added |
| --- | --- | --- |
| C02 Toggle button | 197 | FL-200 to FL-202 |
| C03 Stand-alone link | 198, 199 | FL-220, FL-221 |
| C04 Links inline with text | 200 | FL-240 to FL-246 |
| C12 Tooltip | 201 | FL-247 to FL-253 |
| C05 Accordion | 202 | FL-260 to FL-267 |
| C18 Card | 206 | FL-269 |
| C13 Snackbar and transient messages | 205 | FL-290 to FL-297 |
| C26 Progress indicator | 207 | FL-254 to FL-259 |
| C06 Disclosure | 210 | FL-280 |

C18 also extended FL-262, FL-026 and FL-401. C06 extended FL-264, FL-265
and FL-267. C26 extended FL-027 and FL-037.

## Decisions the owner made

- 2026-11-21: a technique does not invent a mechanism. Flutter's own
  widget for the pattern, through its documented parameters, is the
  source material. Where it is measured not to meet a requirement, the
  gap is recorded as a Flutter limitation.
- 2026-11-21: hand-built good examples already in the repository are
  kept and flagged "Custom solution: not vetted by a real-world example".
  They are tested here in isolation, with screen-reader transcripts, and
  have not been built into a real app and tested in a user journey. A
  flagged example is never called recommended or vetted.
- 2026-11-23, C06: the good example is
  `ExpansionTile(internalAddSemanticForOnTap: true)`. The missing
  expanded state is a limitation on Android, iOS and the web. A state
  given only as text does not meet 4.1.2.
- 2026-11-23, C26: where Flutter gives no role and no documented
  parameter adds one, the platform is a limitation and has no good
  example. iOS is a limitation for the bar, and there is no good spinner
  example.
- 2026-11-23, I08: the web is a limitation because of FL-484.

Decisions the principal made in review are recorded as the principal's
in each spec and pull request, and the owner may overrule them. The ones
that shaped an example: C26's two named spinners are kept as bad
examples whose defect is the missing role; C13 says what an action did
with a live-region line and builds no second message; C18 has no good
link example, because a Flutter link is hand-built (FL-221).

## Changes outside the techniques

- The custom-solution flag (pull request 204): `customSolution` on a good
  example, a note shown on its screen, and the register
  [Custom solutions](../custom-solutions.md), which needs a row for every
  good example of every technique. A test enforces it.
- TalkBack walks can be judged whole (202, 207). For a technique listed
  in `STRICT` in `tool/talkback.py`, one complete walk must be right on
  its own; a wrong reading fails for good, and only an incomplete walk is
  walked again. A row can be declared silent: any speech in it is wrong,
  and it is right only if the row after it, in the same walk, is right.
  C05, C06, C13, C18 and C26 are strict. The thirty techniques merged
  before them still use `walk_until_heard`, which can pass two walks that
  are each wrong at a different row.
- The Android CI job has 90 minutes for its tests (203) and runs each
  test class in a test process of its own (208). Of the 50 Android jobs
  before 208, 24 failed: 8 when the runner ran low on memory, 7 of those
  in the batch that held both I04 and I08.
- F06's Android tests wait for the soft keyboard and put it away before
  they look for a field (208, 211).
- I08 (209): FL-484, the web as a limitation, and its two web positive
  controls now wait until no tooltip is shown before the good example is
  opened.
- C03 (199): F84 is a failure of 2.4.9, and `bad-vague-text` is not a
  shown failure.

## Findings that reach beyond one technique

- **FL-484: a tooltip takes Escape.** On the web, while a tooltip still
  counts as open after a mouse hover, `WidgetsApp`'s tooltip handler
  takes Escape before the app's default Escape shortcut reaches the
  focused layers. The first Escape within about 400 ms of opening did
  nothing in all three of I08's good examples; a second one closed them.
  It was found from a web test that failed at random on CI. A web test
  should keep the mouse off a control with a tooltip before a keyboard
  step, or wait until no tooltip is shown.
- **FL-297: an announcement after the pressed control goes.** With
  VoiceOver in Chromium, when Enter on a control removes that control,
  VoiceOver's cursor went to Back and the polite announcement Flutter
  wrote was said in some recordings and not in others. TalkBack and
  VoiceOver on iOS said it every time.
- **FL-256: a named spinner has no role.** VoiceOver in Playwright's
  WebKit read Material's spinner "Loading inbox empty group". In
  Chromium, VoiceOver's next-item command passed over it, in three
  recordings.
- **FL-262: on the web a heading is never a button.** A node with both a
  heading level and a button flag, such as a `ListTile(onTap:)` whose
  title is a heading, is a heading only on the web, with no button role.
- **FL-296: a `SnackBar` shown from a `SnackBarAction`'s `onPressed`,
  after `clearSnackBars` or `hideCurrentSnackBar` there,** never appears
  when `accessibleNavigation` is on: the action hides it. Without the
  clearing call the new one is queued and appears. Measured on the web
  and in widget tests.

## Test-tool findings

- **A check for silence must not pass on a broken capture.** Reviews
  found this four times: TalkBack rows that combined a silent interval
  with a later reading (C26, C13), and iOS VoiceOver tests that turned a
  capture error into an empty string or logged a reading without
  asserting it (C26, C06). On iOS, `currentSpeech()` keeps returning the
  last utterance while nothing is said, and gave an error only with
  VoiceOver off (C26's probe). So silence is "every raw reading is still
  the previous utterance", with a reading before and after to show the
  capture was live.
- **A predicted screen-reader reading is often wrong.** The first web
  VoiceOver recording failed for C13, C18 and C26, each on a prediction.
  Each failed round is kept in the technique's probe folder. A reading
  that varies between recordings is recorded and not judged (C13's
  after-action rows), and the spec says the row proves nothing.
- **A summary of probe results drifts from the files.** C18 needed four
  review rounds for sentences that named no platform or said more than
  the probe output. What worked: a table per fixture and per platform
  built from the raw files, then every sentence that names a fixture or
  a widget, or gives a condition or advice, compared with it. The
  example texts in the Dart source are part of that.
- **A negative keyboard test must walk a whole focus cycle.** C06's
  Android test stopped at the first Tab that reached Back, so it could
  not have seen the control become reachable.
- **On Android, a wait built on a lookup that throws ends on its first
  miss.** `TechniqueTest.node()` and `revealed()` search only the active
  window and throw. F06's tests were changed; the shared helpers were
  not.
- **The Android CI script's own tests run on Linux only.** They are
  skipped on a Mac. They were run in a Linux container for 208.
- **`XCUIVoiceOverService` returns the first 64 characters**, as before.
  An expected utterance has to be shorter, and C06 and C26 refuse one
  that is not.

## Failures on CI that no change here caused

- HTTP 429 from Maven Central while Gradle downloaded, twice.
- iOS, a tap that did not arrive: C01
  `testGoodButtonsExposeNameRoleStateAndActivate` (twice on pull
  request 201), C02 `testBadSelectedOnlyIsAButtonThatIsSelectedOrNot`
  (202), F08 `testGoodExamplesHaveTheQuestionAsOneElement` ("did not
  open after three attempts", 207).
- iOS, F06 `testBadColorOnlyAddsNoText`: the simulator's typing tip was
  among the texts (201).
- Android, V14 `goodNoticeBelowKeepsEveryFocusedTrailInSight`: "example
  good-notice-below did not open" (210).
- The tool test
  `test_stopping_the_tool_ends_a_descendant_that_ignores_the_signal`
  timed out once (207).

A re-run passed each time. None has been steadied.

## For later waves

- Start a technique's screen-reader checks from raw readings: a wrong
  reading fails for good, an empty, failed or stale capture fails, and a
  claimed silence has a liveness reading on each side.
- Add a new technique to `STRICT` and write its TalkBack walk for the
  whole-walk judge from the start.
- Do the platform-scope pass before the first review, not after.
- When the framework cannot meet a requirement and no documented
  parameter fixes it, the platform is a limitation. Do not offer
  "applies, with a note".
- Each merge makes every other open technique branch conflict in the
  README, the technique list, the limitations log, the register and
  `STRICT`. Take the union of `STRICT`, and recompute the register's
  totals from its technique rows: the automatic merge kept a stale total
  twice.

## Follow-ups not done

- Move the thirty earlier techniques to the whole-walk TalkBack judge.
- C13's `bad-inline-banner` TalkBack silence could be a declared silent
  row.
- A shared Android lookup that searches the app's own window and does
  not throw inside a wait, and a shared "wait for the keyboard, then put
  it away" step. All 35 Android test classes extend `TechniqueTest`,
  where the lookup is, so the change needs every technique's Android
  suite run at CI's screen size.
- The shared iOS helper `VoiceOverWalk.forwardToRepeat` skips a failed
  move. F01, S01 and S05 use it.
- The lost taps on CI's iOS simulator, listed above.
- C12 Tooltip was merged as "applies, with a note" on the keyboard
  platforms, before the owner's rule of 2026-11-23. Whether it becomes a
  limitation has not been decided.
- Twelve good examples are marked borderline in the register. Whether
  they are flagged has not been decided.
- Whether I08's good examples adopt the local Escape shortcut measured
  for FL-484, as a flagged custom solution, has not been decided.
- C02's web VoiceOver judge is the older kind; C04's is the model.
- C01's `good-icon` uses an `IconButton(tooltip:)` that cannot be
  hovered (C12's findings).
- I12's `good-snackbar` has a timed message whose news is nowhere else
  (2.2.1), found while building C13.
- The About screen names the reference repositories' company in prose.
- FL-484 has no test: it held at normal speed and not with the processor
  slowed four times.
- What VoiceOver does with a spinner through the rotor, and in real
  Safari and Chrome, was not measured.
- CI is still on GitHub-hosted runners; pull request 172 is open.
