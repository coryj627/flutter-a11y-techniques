# F06 at CI's screen size, with the keyboard up

Run on 2026-11-18, Flutter 3.47.5, after CI run 44386619996 failed in
`F06ErrorIdentificationTest.goodFieldsShowTheirErrorInTheirHintAndAsALiveRegion`
with "no node with id f06-good-form-count". CI's emulator is API 35
(`google_apis`, x86_64), 320 by 640 at 160 dpi, with no hardware keyboard.
This project's emulator is a Pixel 10a, Android 17, 1080 by 2424 at 420
dpi; for these runs it was set to 320x640 and 160 dpi with `adb shell wm
size` and `wm density`, and both were reset after every run, however it
ended (the size before and after each run is in the `size` lines of the
scripts' output and in `class-runs-ci-size.txt`).

Files: `small_screen.sh.txt` runs the F06 class at that size;
`probe_keyboard.py.txt` and `probe_keyboard2.py.txt` run the probe methods
in `probe_methods.kt.txt` (put into the test class for those runs only)
and, at that size, the F06 TalkBack walk. TalkBack's log level is set
through its settings screen, which `tool/talkback.py` could not drive at
320x640 ("could not find Advanced settings"), so the probes set it at the
emulator's own size with `tool/talkback.py`'s `run_with_talkback` and
change the size only for the instrumented runs.

## What was measured

| Run | Result |
| --- | --- |
| The committed F06 class at 320x640 (`class-runs-ci-size.txt`, run 1) | Passed: the CI failure did not happen here. |
| After a failed send in `good-form` and in `bad-color-only`, at 320x640, no TalkBack (`tree-ci.md`) | With the keyboard up, the tree held the fields and not Send or the count. After Back put the keyboard away, Send and the count were back, three seconds later. |
| The first fix, waiting for the count with UI Automator's `Until.hasObject` after Back (`class-runs-ci-size.txt`, run 2) | Failed: "the count of good-form is in the tree", and the same for `bad-color-only`. |
| A form sent with the keyboard still up, TalkBack on, at the emulator's own size (`keyboard-normal.md`) | The count was in the tree throughout; TalkBack said "Forms sent: 1". |
| The same at 320x640 (`keyboard-ci.md`) | After the failed send and after typing, the count was not in the tree; Send was not either, so the probe stopped when it tried to put TalkBack on Send. |
| The same at 320x640, Send reached by one scroll forward on the scrollable, as a TalkBack user's scroll gesture would (`scrolled-ci.md`) | After the scroll, Send and the count were in the tree with the keyboard still up; TalkBack said "Forms sent: 1". |
| The F06 TalkBack walk at 320x640 (`walk-ci.md`) | Every marker's speech met `tool/techniques/f06_error_identification.py`, including "Forms sent: 1" for `f06-good-form-sent-ok`. |

## What it shows

- At CI's size a keyboard up after a failed send covers Send and the count,
  and Flutter leaves them out of the Android tree until they are scrolled
  into view or the keyboard is put away. On CI the committed test found no
  count, which fits the keyboard having come up before it read it. Why it
  passed on this emulator at the same size was not found; a race with the
  keyboard coming up is likely, not shown.
- The test now puts the keyboard away and waits for the count by searching
  every window, as the probe did.
- Not a finding about the examples: with the keyboard up a user reaches
  Send by scrolling, which brings the count into view as well, and the
  form going through was announced there. Not measured: a send started
  from somewhere that leaves the count out of view.
