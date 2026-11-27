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
# opened it (docs/evidence/probes/s06/android-talkback.md, p01 to p13).
#
# The title is judged as a whole utterance, never as words found in the
# row: "Orders" is inside "Open orders", so a word match would pass a row
# where launcher speech came late and no title was said, or a row with a
# wrong title (Codex, review of 788a911). "== A / B / C" is the row's
# utterances, exactly, in order, TalkBack's closing usage hint left out;
# "^= A" is its first utterance (tool/talkback.py, said). An empty part is
# the pane title of a single space that TalkBack speaks where no node names
# the route. On a Cupertino screen TalkBack says no usage hint for Back,
# whose node has no click action (FL-303); the exact form takes the row
# with the hint at its end or without it, so one list holds for both bars.
_OPEN = (["== Open orders / Button"], [])


def _opened(title):
    return ([f"== {title} / Back / Button"], [])


# A closing row is judged by its first utterance alone, the title of the
# screen under the one that closed. Where TalkBack's focus went next
# varied between recordings: to the example's button, "Open orders", in
# the first, and for good-cupertino to the app's Back in the second
# (docs/evidence/probes/s06/talkback-round2-fail.md.txt). Focus after a
# screen closes is I03's subject; it is recorded here and not judged.
def _closed(title):
    return ([f"^= {title}"], [])


TALKBACK_EXPECT = {
    "s06-good-material-open": _OPEN,
    "s06-good-material-opened": _opened("Orders"),
    "s06-good-material-closed": _closed("Material screen title"),
    "s06-good-cupertino-open": _OPEN,
    "s06-good-cupertino-opened": _opened("Orders"),
    "s06-good-cupertino-closed": _closed("Cupertino screen title"),
    # The defect: no name, a pane title of a single space, and then the
    # screen's first control; any title said is a wrong reading.
    "s06-bad-no-title-open": _OPEN,
    "s06-bad-no-title-opened": _opened(""),
    "s06-bad-no-title-closed": _closed("Screen with no title"),
    # The defect is the words: "Details" as the whole title.
    "s06-bad-vague-title-open": _OPEN,
    "s06-bad-vague-title-opened": _opened("Details"),
    "s06-bad-vague-title-closed": _closed("Screen titled Details"),
    # The defect is the web's: TalkBack is told the name.
    "s06-bad-no-document-title-open": _OPEN,
    "s06-bad-no-document-title-opened": _opened("Orders"),
    "s06-bad-no-document-title-closed": _closed("Screen with no document title"),
    # FL-301: as bad-no-title.
    "s06-bad-cupertino-unnamed-open": _OPEN,
    "s06-bad-cupertino-unnamed-opened": _opened(""),
    "s06-bad-cupertino-unnamed-closed": _closed("Cupertino bar that names no screen"),
}

# tool/talkback.py: how the speech was captured.
TALKBACK_METHOD = (
    "TalkBack focus moved to the example's button (`-open`); the marker `-opened` logged, the "
    "button pressed with ACTION_CLICK, and everything TalkBack said for eight seconds as the "
    "screen opened; the marker `-closed` logged, the system Back pressed, and everything said for "
    "eight seconds as the screen closed. Speech read from TalkBack's verbose log. The title is "
    "judged as a whole utterance: `-open` and `-opened` rows must be exactly their list of "
    "utterances (TalkBack's closing usage hint allowed), a `-closed` row's first utterance exactly "
    "the example screen's title; what a `-closed` row says after the title, where focus went, is "
    "recorded and not judged. Each walk is judged whole: a wrong reading fails for good, and "
    "only a walk shown to be incomplete is walked again"
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
