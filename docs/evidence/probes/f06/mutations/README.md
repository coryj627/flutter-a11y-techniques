# F06: the iOS VoiceOver test against a broken capture

Run on 2026-11-18, Flutter 3.47.5, iPhone 17 simulator, iOS 27.0, after a
review finding: `currentSpeech()` errors were read as empty speech, and
empty or unchanged speech passed the check that nothing was announced.

`testVoiceOverSpeech` now fails on any `currentSpeech()` error, and ends
each example with a control: the cursor is moved to the count, and
`currentSpeech()`, the read that the eight-second window polls, must report
"Sent: 0" within five seconds.

To show that the test fails when capture is broken, `mutate.py.txt` wrote a
copy of the test in which, from the moment Send is activated,
`currentSpeech()` is replaced by one of three things. `mutations.sh.txt`
ran `python3 tool/voiceover_ios.py F06` once for each under the device lock
and then put the clean test back.

| Mutation | `currentSpeech()` after Send | Result |
| --- | --- | --- |
| throw | an error | The test failed on the first example: `caught error: "Error Domain=F06Mutation Code=1 "(null)""` (failure message read from the run's result bundle with `xcrun xcresulttool`; `voiceover-ios-throw.log` is the tool's output, and since the test stopped there no transcript was written) |
| empty | an empty utterance | Every example failed. `bad-not-announced`, the one that checks for silence, failed only on the control: `("") is not equal to ("Sent: 0") … capture is not live` (`voiceover-ios-empty.md`) |
| stale | always "Send Button", what was said before Send | Every example failed. `bad-not-announced` failed only on the control: `("Send Button") is not equal to ("Sent: 0") … capture is not live` (`voiceover-ios-stale.md`) |

Read from the old code, not run: before the change, the empty and stale
cases would have passed
`bad-not-announced`, because its only checks were that nothing new was
heard and that `moveForward()` and `moveBackward()` returned speech.
