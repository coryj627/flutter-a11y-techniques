"""Evidence tool registration for C12 Tooltip.

Read by tool/evidence_common.py, which says what each name means."""

ID = "C12"
TITLE = "C12 Tooltip"
ANDROID_TEST = "C12TooltipTest"
IOS_TEST = "C12TooltipUITests"
WEB_VO_SPEC = "c12_tooltip_vo.spec.js"

# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be). TalkBack reads a node's tooltip text after its role when it
# differs from the name, and not when it is the same
# (docs/evidence/probes/c12/android-talkback.md, t05 and t06).
_ACTIVATE = "Double-tap to activate"

TALKBACK_EXPECT = {
    # The tooltip's words once, as the button's name.
    "c12-good-material-delete": (["Delete draft", "Button"], []),
    "c12-good-cupertino-delete": (["Delete draft", "Button"], []),
    # The tooltip's words as the button's tooltip text, read after its role
    # (the probe's t05).
    "c12-good-description-download": (["Download", "Button", "Saves a PDF copy"], []),
    # Read as good-material; the defect is the pointer's.
    "c12-bad-not-hoverable-delete": (["Delete draft", "Button"], []),
    # The rule is read as the icon's name; the defect is the keyboard's.
    "c12-bad-hover-only-info": (["At least 8 characters"], ["Button", _ACTIVATE]),
    "c12-bad-hover-only-sign-up": (["Sign up", "Button"], ["At least 8 characters"]),
    # The name and the tooltip are the same words. TalkBack reads them once
    # (the probe's t06), so on Android the defect is not heard.
    "c12-bad-repeats-name-download": (["Download", "Button"], []),
    # The tooltip's words on a node of their own, not a button; then the
    # button, with no name.
    "c12-bad-outside-button-tooltip": (["Delete draft"], ["Button", _ACTIVATE]),
    "c12-bad-outside-button-button": (["Button", _ACTIVATE], ["Delete draft"]),
}

# tool/voiceover_ios.py: (how the speech was captured, heading of the
# transcript column).
VOICEOVER_IOS_METHOD = (
    "`XCUIVoiceOverService.moveForward()` from the top of the screen to its "
    "end, where moving on gives the last utterance again, twice; what is shown "
    "is everything after the \"Example\" heading, and a walk that does not "
    "reach the end fails",
    "Spoken, in swipe order",
)

# tool/voiceover_web.py: how the speech was captured.
VOICEOVER_WEB_METHOD = (
    "focus the Back button, then `voiceOver.next()` to the end of the screen. "
    "VoiceOver's last phrase and the position of its cursor are read over "
    "AppleScript after every move: a move that changes the position, or that "
    "speaks a different phrase, is a stop; two moves in a row that do neither are "
    "the end. Every walk must read the whole screen, each stop in its place "
    "(web_tests/vo/c12_vo_walks.js): the title and the description, the "
    "\"Example\" heading, and the expected list after it to the count. A wrong "
    "stop, or a walk that reached the end with any expected stop not read, fails "
    "the test for good; only a walk cut short before the end with every stop "
    "right so far is walked again, up to three walks, each shown as its own row "
    "(`-walk-<n>`). No runner retries"
)
