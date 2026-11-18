# I03 mutation runs

Run on 2026-11-18, Flutter 3.47.5, after the review of the first
hand-back, to show that the strengthened screen reader checks fail when
they should. Each run built the app with a change to
`lib/techniques/i03_focus_management/examples.dart`, ran
`python3 tool/evidence.py I03 --only <layers> --no-build`, kept the output
here, and the change was then undone. The test code was the code that is
committed.

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
