"""Evidence tool registration for V12 Detecting accessibility settings.

Read by tool/evidence_common.py, which says what each name means."""

ID = "V12"
TITLE = "V12 Detecting accessibility settings"
ANDROID_TEST = "V12AccessibilitySettingsTest"
IOS_TEST = "V12AccessibilitySettingsUITests"
WEB_VO_SPEC = "v12_accessibility_settings_vo.spec.js"

_KEYS = ["navigation", "bold", "contrast", "invert", "animations", "labels", "dark", "scale"]


def _lines(navigation):
    """What a settings list says with nothing changed but accessible
    navigation, which is `navigation`."""
    return [
        f"Accessible navigation: {navigation}", "Bold text: off", "High contrast: off",
        "Invert colours: off", "Disable animations: off", "Switch labels: off", "Dark mode: off",
        "Text scale: 100%",
    ]


def _whole(*utterances):
    """A whole-utterance row ("== A / B" in tool/talkback.py's said()):
    exactly these utterances, in this order, TalkBack's usage hint allowed
    once at the end; a duplicated phrase, an extra word, a wrong number, or
    a sibling's text is wrong."""
    return ([f"== {' / '.join(utterances)}"], [])


def _list(slug, navigation):
    return {f"v12-{slug}-{key}": _whole(text) for key, text in zip(_KEYS, _lines(navigation))}


# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be). The walk (V12AccessibilitySettingsTest.talkBackWalk) opens
# each example with TalkBack already on and moves TalkBack focus to each of
# its lines in turn. good-media-query reads its settings again whenever one
# changes, so it says accessible navigation is on once TalkBack has read the
# screen; bad-read-once read them as its screen was first built, before
# TalkBack had read any node, when the engine still reported accessible
# navigation off (FL-503), and never reads them again. Each walk is judged
# whole (V12 is in tool/talkback.py's STRICT set).
TALKBACK_EXPECT = {
    **_list("good-media-query", "on"),
    "v12-good-motion-motion": _whole("Reduce motion: off"),
    **_list("bad-read-once", "off"),
    "v12-bad-animations-only-motion": _whole("Reduce motion: off"),
}

# tool/talkback.py: how the speech was captured.
TALKBACK_METHOD = (
    "TalkBack on before the app starts; each example opened and TalkBack focus moved by "
    "ACTION_ACCESSIBILITY_FOCUS to each of its lines in turn, five seconds each; speech read from "
    "TalkBack's verbose log. Each walk is judged whole: a wrong reading fails for good, and only "
    "a walk shown to be incomplete is walked again, up to three walks. Every row is judged as "
    "whole utterances, exactly those heard and in their order (\"== A / B\"), the usage hint "
    "allowed once at the end. No setting is changed during the walk: TalkBack itself, on as each "
    "example opens, is the setting the lines show"
)

# tool/voiceover_ios.py: (how the speech was captured, heading of the
# transcript column).
VOICEOVER_IOS_METHOD = (
    "each example opened with VoiceOver off, then VoiceOver turned on and "
    "`XCUIVoiceOverService.moveForward()` from the top of the screen to its end (V12Walk, "
    "S16's walk copied): a stop read twice in a row in the middle of the walk fails, and the "
    "last utterance read again twice is the end only when one move back then reads the stop "
    "before it and one move forward the last again; the walk must first read this example's own "
    "title and description, and what is shown is everything after the \"Example\" heading. A "
    "walk that does not reach the end fails",
    "Spoken, in swipe order",
)

# tool/voiceover_web.py: how the speech was captured.
VOICEOVER_WEB_METHOD = (
    "focus the Back button and capture VoiceOver's last phrase and its cursor's position there "
    "(the walk's start row), then `voiceOver.next()` to the end of the screen, capturing both "
    "over AppleScript after every move (collectWalk, web_tests/vo/v12_vo_walks.js, S16's copied "
    "whole). A move that changes the position, or that speaks a non-empty phrase other than the "
    "stop before it (or than the start, before the first stop), is a stop. A move that does "
    "neither is kept: one followed by a move on is an unresolved read, a gap after the stop "
    "before it, and is listed on the walk's unresolved row; two in a row are the end only when a "
    "move back then reads the stop before the last, not empty, at another position, and a move "
    "forward the last again at its position, both on the walk's end row; a failed witness is "
    "wrong for good. Every walk is judged whole (judgeWalk): the title, the description, the "
    "\"Example\" heading, and the expected list after it, each in its place; a wrong stop always "
    "wins, across a gap the next stop must be the next expected one or the one after it, and a "
    "walk that ran out of moves is wrong. Only a walk with no wrong stop and a gap, or a stop "
    "read as an empty phrase, is walked again, up to three walks, each its own row "
    "(`-walk-<n>`), and it never passes. VoiceOver's own help message (\"You are currently on "
    "...\") is left out only at the position of the stop before it, whose reading speaks the role "
    "the help names. No runner retries. The Mac's VoiceOver state is read with `pgrep -x VoiceOver` "
    "before each test starts VoiceOver and again after Guidepup stops it, put back if it differs, "
    "and read again; a failed stop or restore fails the test (V12's own fixture, "
    "web_tests/vo/v12_vo_state.js)"
)
