"""Evidence tool registration for S06 Screen and page titles.

Read by tool/evidence_common.py, which says what each name means."""

ID = "S06"
TITLE = "S06 Screen and page titles"
ANDROID_TEST = "S06ScreenTitlesTest"
IOS_TEST = "S06ScreenTitlesUITests"
WEB_VO_SPEC = "s06_screen_titles_vo.spec.js"

# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be). "-open" is TalkBack focus on the example's button;
# "-opened" everything said for eight seconds after the button was pressed
# with the click action (the marker logged before the press); "-closed"
# everything said for eight seconds after the system Back (the marker
# logged before it). In the probe TalkBack said, as a screen opened, its
# pane title (the route's name, or a single space where no node names the
# route) and then the screen's first control, "Back", "Button"; and as it
# closed, the pane title of the screen under it and the button that had
# opened it (docs/evidence/probes/s06/android-talkback.md, p01 to p13). A
# phrase that is not a role word is found anywhere in the row's speech, so
# a row that must not say "Orders" must not say it in any word.
_OPEN = (["Open orders", "Button"], [])


def _closed(title):
    return ([title, "Open orders", "Button"], [])


TALKBACK_EXPECT = {
    "s06-good-material-open": _OPEN,
    "s06-good-material-opened": (["Orders", "Back", "Button"], []),
    "s06-good-material-closed": _closed("Material screen title"),
    "s06-good-cupertino-open": _OPEN,
    "s06-good-cupertino-opened": (["Orders", "Back", "Button"], []),
    "s06-good-cupertino-closed": _closed("Cupertino screen title"),
    # The defect: no name, a pane title of a single space, and then the
    # screen's first control.
    "s06-bad-no-title-open": _OPEN,
    "s06-bad-no-title-opened": (["Back", "Button"], ["Orders"]),
    "s06-bad-no-title-closed": _closed("Screen with no title"),
    # The defect is the words: "Details", and nothing that says orders.
    "s06-bad-vague-title-open": _OPEN,
    "s06-bad-vague-title-opened": (["Details", "Back", "Button"], ["Orders"]),
    "s06-bad-vague-title-closed": _closed("Screen titled Details"),
    # The defect is the web's: TalkBack is told the name.
    "s06-bad-no-document-title-open": _OPEN,
    "s06-bad-no-document-title-opened": (["Orders", "Back", "Button"], []),
    "s06-bad-no-document-title-closed": _closed("Screen with no document title"),
    # FL-301: as bad-no-title.
    "s06-bad-cupertino-unnamed-open": _OPEN,
    "s06-bad-cupertino-unnamed-opened": (["Back", "Button"], ["Orders"]),
    "s06-bad-cupertino-unnamed-closed": _closed("Cupertino bar that names no screen"),
}

# tool/talkback.py: how the speech was captured.
TALKBACK_METHOD = (
    "TalkBack focus moved to the example's button (`-open`); the marker `-opened` logged, the "
    "button pressed with ACTION_CLICK, and everything TalkBack said for eight seconds as the "
    "screen opened; the marker `-closed` logged, the system Back pressed, and everything said for "
    "eight seconds as the screen closed. Speech read from TalkBack's verbose log. Each walk is "
    "judged whole: a wrong reading fails for good, and only a walk shown to be incomplete is "
    "walked again"
)

# tool/voiceover_ios.py: (how the speech was captured, heading of the
# transcript column).
VOICEOVER_IOS_METHOD = (
    "`<example>-opened`: `XCUIVoiceOverService.moveForward()` to the example's button, the button "
    "pressed with `doubleTap()` at its place (which acts on what is under the tap; VoiceOver's own "
    "activation was not measured), and `currentSpeech()` read every 0.15 s for six seconds, every "
    "read judged: the button's utterance, then only where the cursor lands. `-screen`: moves "
    "forward from there to the end of the screen, where moving on gives the last utterance again. "
    "`-closed`: Back pressed with `doubleTap()` at its place, and six seconds of reads judged the "
    "same way",
    "Spoken",
)

# tool/voiceover_web.py: how the speech was captured.
VOICEOVER_WEB_METHOD = (
    "`<example>-walk-<n>`: focus the Back button, then `voiceOver.next()` to the end of the "
    "example screen; VoiceOver's last phrase and the position of its cursor are read over "
    "AppleScript after every move: a move that changes the position, or that speaks a different "
    "phrase, is a stop; two moves in a row that do neither are the end. Every walk must read the "
    "whole screen, each stop in its place (web_tests/vo/s06_vo_walks.js); a wrong stop, or a walk "
    "that reached the end with any stop not read, fails for good; only a walk cut short with "
    "every stop right so far is walked again, up to three walks. `-opening`: keyboard focus on "
    "the button, Enter, and every phrase for six seconds: recorded, not judged, except that "
    "something must be heard. `-opened-walk-<n>`: the opened screen walked the same way from its "
    "Back button. No runner retries"
)
