"""Evidence tool registration for C26 Progress indicator.

Read by tool/evidence_common.py, which says what each name means."""

ID = "C26"
TITLE = "C26 Progress indicator"
ANDROID_TEST = "C26ProgressIndicatorTest"
IOS_TEST = "C26ProgressIndicatorUITests"
WEB_VO_SPEC = "c26_progress_indicator_vo.spec.js"

_UPLOAD = ["Upload started", "Half uploaded", "Upload complete"]
_LOAD = ["Loading started", "Inbox loaded"]

# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be). "<example>-bar" is TalkBack focus on a bar; "-start" on the
# button; "-run" everything said for nine seconds after the button was
# pressed with the click action, TalkBack focus left on the button. In the
# probe TalkBack read a bar "40.0.", "40,", its name, "Progress bar": the
# value twice, the first time from its range (FL-027); and a spinner by its
# name alone, with no role word (FL-256)
# (docs/evidence/probes/c26/android-talkback.md).
TALKBACK_EXPECT = {
    "c26-good-linear-bar": (["Report upload", "Progress bar"], []),
    "c26-good-linear-start": (["Upload report", "Button"], []),
    # The status line, a live region, at the start, halfway, and the end.
    "c26-good-linear-run": (_UPLOAD, []),
    "c26-good-circular-start": (["Load inbox", "Button"], []),
    "c26-good-circular-run": (_LOAD, []),
    "c26-good-cupertino-start": (["Load inbox", "Button"], []),
    "c26-good-cupertino-run": (_LOAD, []),
    # The bar's value and role, with no name.
    "c26-bad-no-label-bar": (["Progress bar"], ["Report upload"]),
    "c26-bad-no-label-start": (["Upload report", "Button"], []),
    "c26-bad-no-label-run": (_UPLOAD, []),
    "c26-bad-silent-end-bar": (["Report upload", "Progress bar"], []),
    "c26-bad-silent-end-start": (["Upload report", "Button"], []),
    # FL-254: nothing about the upload is announced, neither the status line
    # nor the bar's changes. "(must be silent)" is talkback.SILENT: the row,
    # logged after the click action has returned, must have nothing spoken
    # in it at all, a number included, and the row after it, its liveness
    # control, must be right (talkback.judge_walk).
    "c26-bad-silent-end-run": (["(must be silent)"], []),
    # The liveness control: focus moved to the bar, which reads 100.
    "c26-bad-silent-end-run-live": (["100", "Progress bar"],
                                    ["Upload started", "Half uploaded", "Upload complete"]),
    "c26-bad-silent-end-status": (["Upload complete"], []),
    # The same with TalkBack focus on the bar while its value changes: the
    # bar read once on the focus, then silence through 0 to 100, then the
    # status line as the liveness control.
    "c26-bad-silent-end-bar-again": (["Report upload", "Progress bar"], []),
    "c26-bad-silent-end-bar-run": (["(must be silent)"], []),
    "c26-bad-silent-end-bar-run-live": (["Upload complete"], []),
    # FL-257 is on iOS and in a browser on a Mac: on Android the adaptive
    # spinner is Material's, and the status line is announced.
    "c26-bad-adaptive-start": (["Load inbox", "Button"], []),
    "c26-bad-adaptive-run": (_LOAD, []),
    "c26-bad-cupertino-bar-start": (["Upload report", "Button"], []),
    "c26-bad-cupertino-bar-run": (_UPLOAD, []),
}

# tool/talkback.py: how the speech was captured.
TALKBACK_METHOD = (
    "TalkBack focus moved to the example's bar, where it has one at rest (`-bar`), then to its "
    "button (`-start`); the button pressed with ACTION_CLICK with TalkBack focus left on it, and "
    "everything TalkBack said for nine seconds, the task taking four (`-run`). For "
    "`bad-silent-end` the `-run` marker is logged after the click action has returned and must "
    "be silent: nothing at all may be spoken in it; the row after it is its liveness control, "
    "focus moved to the bar (`-run-live`); then the status line (`-status`); then focus on the "
    "bar (`-bar-again`), the button pressed again with focus left on the bar, nine seconds that "
    "must be silent (`-bar-run`), and focus moved to the status line as their liveness control "
    "(`-bar-run-live`). Speech read from TalkBack's verbose log. Each walk is judged whole: a "
    "wrong reading fails for good, and only a walk shown to be incomplete is walked again"
)

# tool/voiceover_ios.py: (how the speech was captured, heading of the
# transcript column).
VOICEOVER_IOS_METHOD = (
    "`<example>`: `XCUIVoiceOverService.moveForward()` from the top of the screen to its end, "
    "where moving on gives the last utterance again, twice; what is shown is everything after "
    "the \"Example\" heading, and a walk that does not reach the end fails. `-run`: the cursor put "
    "on the button with `tap()`, the button pressed with `doubleTap()` at its place (which acts on "
    "what is under the tap; VoiceOver's own activation was not measured), and every distinct "
    "utterance `currentSpeech()` gave for nine seconds; for `bad-silent-end`, two moves forward "
    "after it, which must read the status line. `-loading`: the button pressed the same way, and "
    "0.8 s later one move back and three forward",
    "Spoken",
)

# tool/voiceover_web.py: how the speech was captured.
VOICEOVER_WEB_METHOD = (
    "`<example>-walk-<n>`: focus the Back button, then `voiceOver.next()` to the end of the "
    "screen; VoiceOver's last phrase and the position of its cursor are read over AppleScript "
    "after every move: a move that changes the position, or that speaks a different phrase, is a "
    "stop; two moves in a row that do neither are the end. Every walk must read the whole screen, "
    "each stop in its place (web_tests/vo/c26_vo_walks.js); a wrong stop, or a walk that reached "
    "the end with any expected stop not read, fails for good; only a walk cut short with every "
    "stop right so far is walked again, up to three walks. `-announced`: keyboard focus on the "
    "example's button, Enter pressed, and VoiceOver's last phrase polled for eight seconds "
    "(Chromium only: Playwright's WebKit build passes no live region changes to VoiceOver). No "
    "runner retries"
)
