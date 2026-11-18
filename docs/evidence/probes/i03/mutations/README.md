# I03 mutation runs

Run on 2026-11-18, Flutter 3.47.5, after the review of the first
hand-back, to show that the strengthened screen reader checks fail when
they should. Each run built the app with a change to
`lib/techniques/i03_focus_management/examples.dart`, ran
`python3 tool/evidence.py I03 --only <layers> --no-build`, kept the output
here, and the change was then undone. The test code was the code
committed at the time, in `06da7f3`; the app as committed then waited a
second before sending the screen reader on (round two, below, replaced
that).

| Run | Change to the app | Layers | What failed |
| --- | --- | --- | --- |
| m1 | A: the delayed screen reader request sent at once (`_afterTheRoute = Duration.zero`). B: `bad-opens-on-focus` also asks when a screen reader's focus lands on a Remove button (`Semantics(onDidGainAccessibilityFocus:)`) | talkback | B only: "TalkBack's focus is on Remove Ridge trail?, not Remove Ridge trail" and "TalkBack's focus on Remove Ridge trail: the read holds remove-ridge", that is, TalkBack's move asked, and the read of the app's window showed the question and not the list. A did not fail: TalkBack still ended, and stayed, on Remove Summit path (`m1_talkback_log.txt`) |
| m2 | `good-material` sends the request after 250 ms, before the framework's own; `good-cupertino` sends none at all; the others as committed | talkback | Nothing: TalkBack ended, and stayed, on Remove Summit path in every example (`m2_talkback.txt`). In these examples `requestFocus` alone took TalkBack to the next button |
| m3 | `good-material`: the request as committed, and three seconds after the removal a second request, for the first trail, standing in for a later move of the framework's; `good-cupertino`: no request | talkback, voiceover-ios | TalkBack: "good-material: removed: TalkBack's focus over the last interval: [i03-good-material-remove-ridge]", after its focus had first reached Remove Summit path, which the earlier check, which stopped at the first sample on Remove Summit path, would have passed; and "moved on: ... [i03-good-material-remove-summit]", the same late request, this time for Summit path. VoiceOver on iOS: "the cursor is not on Remove Summit path" (one move back read "Saved trails", one forward "Remove Ridge trail Button") after its speech had been "Remove Summit path Button". The iOS run stops at its first failure, so `good-cupertino` without a request was not reached on iOS |

What the runs show:

- The last-interval checks of the TalkBack walk, and the delayed position
  check of the VoiceOver walk on iOS, fail when the screen reader is moved
  away after it first reached the right button (m3).
- The TalkBack check that a screen reader's focus asks nothing, read
  through the app's own window with the list required in that read, fails
  when it does ask (m1, B).
- On the Android emulator, in the I03 examples, the framework's request
  for the removed button did not leave TalkBack away from the next button
  even when the example sent no request of its own (m2, m3) or sent it
  early (m1, m2). That is unlike the probe's rows `r1` and `s1`
  (`../android_round2.txt`, `../android_round3.txt`), where TalkBack ended
  on the row above or on Back. What makes the difference was not found.

## Round two: VoiceOver on iOS after the delay was removed

Run on 2026-11-18, Flutter 3.47.5, iPhone 17 simulator, iOS 27.0, after
the second review. The examples no longer wait a fixed second: on iOS
they send the `FocusSemanticEvent` one frame after the question's route
has gone (`ModalRoute.completed`, then `endOfFrame`), and on Android and
the web they send nothing. The VoiceOver walk on iOS gained a step,
`moved on`: Summit path is removed, and the user moves VoiceOver on with
its own command, keyboard focus staying on Remove Ridge trail.

The runs `v1` to `v3` are measurements of the committed app, made while
the step was being written; the test code differed from what is
committed only in the step itself, as the row says. `m4` and `m5` are
mutation runs of the app, with the committed test code.

| Run | Change | What happened |
| --- | --- | --- |
| v1 | Test: 0.45 s after the double tap on the question's Remove returned, a touch on Back (`XCUICoordinate.tap()`) | In all four examples VoiceOver had gone to Remove Summit path on the earlier removal and stayed. The touch came 6.18 to 6.23 s after the double tap, far too late to race anything; the cursor stayed on Back (`v1_voiceover_ios.txt`). The double tap itself returned after 0.41 s |
| v2 | Test: 0.45 s after the double tap returned, `moveBackward()` | `good-material`: the move ended 1.64 s after the double tap and read "Remove Ridge trail Button", and the cursor was on Remove Ridge trail three seconds later; the run stopped there (`v2_voiceover_ios.txt`). The move was made before VoiceOver had acted on the event; whether the question was still closing then, the walk cannot see |
| v3 | Test: what VoiceOver said, read every 50 ms for four seconds after the double tap, then `moveBackward()` | VoiceOver first spoke after the double tap at 1.38 s (`good-material`), 1.70 s (`good-cupertino`), 1.43 s (`good-widgets`), 1.41 s (`bad-focus-left-behind`), and what it said was "Remove Ridge trail Button" each time; the move back, about 4.5 s after the double tap, read "Saved trails", and the cursor was still there three seconds later (`v3_voiceover_ios.txt`). The differences follow the closing animations: 150 ms, 335 ms, 200 ms, 150 ms |
| m4 | App: the examples as first handed back (`requestFocus`, and the event one second after the question returned, on Android and iOS) | Failed, on its first check: VoiceOver first said "Back Button", 1.36 s after the double tap, not Remove Ridge trail: the framework's request for the removed button had sent it to the top of the screen. The move back, from Back, read "Back Button" again, and VoiceOver was still on Back three seconds later; the one-second event did not move it on to Remove Ridge trail, though on the removal before, of Lake loop, the same event had put VoiceOver on Remove Summit path (`m4_voiceover_ios.txt`). Why it did not this time was not looked into |
| m5 | App: as committed, and a second event to the next button three seconds after the first, standing in for a request still due when the user moves on | Failed where it should: in `good-material` VoiceOver first said "Remove Ridge trail Button", 1.42 s after the double tap; the user's move back ended 1.93 s after it, on "Saved trails"; three seconds later VoiceOver was on Remove Ridge trail again ("VoiceOver was moved after the user's move"; one move forward read "Saved: 1", one back "Remove Ridge trail Button") (`m5_voiceover_ios.txt`). The run stops at its first failure, so the other examples were not reached |

What these runs show:

- Sent one frame after the route has gone, the event put VoiceOver on the
  next button in every example, and it stayed there (v3, and the
  committed walk).
- A move of VoiceOver's own, made at once after VoiceOver has spoken the
  next button (the committed walk) or a few seconds later (v3), is left
  where it went; a request still due at that moment would undo it, and
  the walk fails when one does (m5).
- The walk also fails with the examples as first handed back (m4), but
  on its first check, not by catching a pull-back: VoiceOver had been
  sent to the top of the screen by the framework, and the one-second
  event did not bring it to the next button.
- What is not covered: a move made before VoiceOver has spoken anything
  after the double tap (v2), and TalkBack's own moves, which the walk
  cannot make on the emulator. On Android the examples send nothing
  after a removal, so the only request that could move TalkBack is the
  framework's own.
- The order of the two requests, the framework's and the example's, is
  checked in the widget tests, on iOS as the framework sees it. With the
  wait for `endOfFrame` taken out, the examples' request went first and
  the framework's for the removed button last, and the tests "after
  Remove, on iOS the last request is for Remove Summit path" failed in
  every good example (`[summit, lake]` where `[lake, summit]` is
  expected; run in `flutter test`, not kept).

## Round three: TalkBack's focus on Back in `moved-on`

Run on 2026-11-18, after the third review. Until then the last interval
of the TalkBack walk's `moved-on` step accepted any one stable reading
other than Remove Summit path, so TalkBack's focus lost (`"none"`) or put
anywhere else passed. The step now requires the reading to be Back
itself (commit `3779652`; the committed transcript is from that run).
Both runs changed the test, not the app: each added a step after
Shift+Tab, four seconds after Back had been spoken, and recorded what
happened as an extra failure line so that it shows in the log.

| Run | Change to the test | What happened |
| --- | --- | --- |
| m6a | `ACTION_CLEAR_ACCESSIBILITY_FOCUS` on the node with TalkBack's focus | Did not take: the last interval read Back, and the walk passed but for the run's own line (`m6a_talkback_log.txt`). Clearing TalkBack's focus from the test is not a way to lose it on this emulator |
| m6b | TalkBack's focus put on the example's count ("Saved: 1") | Failed where it should: "good-material: moved on: TalkBack's focus over the last interval: [i03-good-material-count]" (`m6b_talkback_log.txt`). The check before this round, "not Remove Summit path", would have passed that reading. The test's own reading straight after the move still said Back; TalkBack moved a moment later |

A reading of `"none"` was not produced on the device (m6a), so that case
rests on the check itself: it names one value, Back, and `"none"` is not
it.
