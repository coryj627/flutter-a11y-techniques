"""Evidence tool registration for S12 Hiding content from AT.

Read by tool/evidence_common.py, which says what each name means."""

ID = "S12"
TITLE = "S12 Hiding content from AT"
ANDROID_TEST = "S12HidingContentTest"
IOS_TEST = "S12HidingContentUITests"
WEB_VO_SPEC = "s12_hiding_content_vo.spec.js"

_QUOTE = "Walk the ridge before the sun is up."
_SOURCE = "Trail guide"
_INBOX = "Inbox: 3 unread"
_TRACKING = "Tracking number: 1Z 999"

# What TalkBack was given to speak for the ornaments in the probe: the
# characters themselves (docs/evidence/probes/s12/android-talkback.md, p25:
# "❝ p25 Quote", "· · ·", "✦ ✦ ✦"). Its log holds the text sent to speech,
# not how the voice pronounced it.
_MARK_SPEECH = "❝"
_ORNAMENT_SPEECH = "✦ ✦ ✦"

# Every other part's whole label, forbidden in a row, so that a row cannot
# pass on another element's speech where one label holds another's words.
_PARTS = [_QUOTE, _SOURCE]


def _switch(slug, state):
    """The switch, read with its state as a sentence of its own (F09)."""
    other = "on" if state == "off" else "off"
    return {f"s12-{slug}-show": ([state, "Show tracking", "Switch"], [other, "checked", _TRACKING, "Copy number"])}


# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be). The walk (S12HidingContentTest.talkBackWalk) moves TalkBack
# focus to each part of each example in turn. Each walk is judged whole
# (S12 is in tool/talkback.py's STRICT set).
TALKBACK_EXPECT = {
    # The quote and its source, and no ornament with either.
    "s12-good-decoration-quote": ([_QUOTE], [_SOURCE, _MARK_SPEECH, _ORNAMENT_SPEECH]),
    "s12-good-decoration-source": ([_SOURCE], [_QUOTE, _MARK_SPEECH, _ORNAMENT_SPEECH]),
    # The words alone.
    "s12-good-badge-inbox": ([_INBOX], []),
    # Hidden: the switch, off, and the count; the panel is no node, which
    # the tree test shows.
    **_switch("good-visibility", "off"),
    "s12-good-visibility-count": (["Copies: 0"], [_TRACKING, "Copy number"]),
    # Bad examples: the defect must be audible. Each ornament read.
    "s12-bad-decoration-read-mark": ([_MARK_SPEECH], [_QUOTE]),
    "s12-bad-decoration-read-quote": ([_QUOTE], [_SOURCE]),
    "s12-bad-decoration-read-source": ([_SOURCE], [_QUOTE]),
    "s12-bad-decoration-read-ornament": ([_ORNAMENT_SPEECH], [_QUOTE, _SOURCE]),
    # The quote and the count; no Share.
    "s12-bad-hidden-control-quote": ([_QUOTE], ["Share", "Button"]),
    "s12-bad-hidden-control-count": (["Shares: 0"], ["Share button", "Button"]),
    **_switch("bad-opacity", "off"),
    "s12-bad-opacity-count": (["Copies: 0"], [_TRACKING, "Copy number"]),
    # Hidden, and read all the same.
    **_switch("bad-maintain", "off"),
    "s12-bad-maintain-tracking": ([_TRACKING], ["Copy number", "Show tracking"]),
    "s12-bad-maintain-copy": (["Copy number", "Button"], [_TRACKING, "Show tracking"]),
    "s12-bad-maintain-count": (["Copies: 0"], [_TRACKING, "Copy number"]),
}

# tool/talkback.py: how the speech was captured.
TALKBACK_METHOD = (
    "TalkBack focus moved by ACTION_ACCESSIBILITY_FOCUS to each part of each example in turn, "
    "six seconds each; speech read from TalkBack's verbose log. Each walk is judged whole: a "
    "wrong reading fails for good, and only a walk shown to be incomplete is walked again, up "
    "to three walks. Where one part's name holds another's words, each row forbids the other "
    "parts' whole labels. What is hidden is not focused: a node that is not there cannot be, "
    "which the tree test shows"
)

# tool/voiceover_ios.py: (how the speech was captured, heading of the
# transcript column).
VOICEOVER_IOS_METHOD = (
    "`XCUIVoiceOverService.moveForward()` from the top of the screen to its "
    "end, where moving on gives the last utterance again, twice (C03's walk); "
    "what is shown is everything after the \"Example\" heading, and a walk "
    "that does not reach the end fails",
    "Spoken, in swipe order",
)

# tool/voiceover_web.py: how the speech was captured.
VOICEOVER_WEB_METHOD = (
    "focus the Back button, then `voiceOver.next()` to the end of the screen. "
    "VoiceOver's last phrase and the position of its cursor are read over "
    "AppleScript after every move: a move that changes the position, or that "
    "speaks a different phrase, is a stop; two moves in a row that do neither are "
    "the end. Every walk must read the whole screen, each stop in its place "
    "(web_tests/vo/s12_vo_walks.js, S08's judge): the title and the description, the "
    "\"Example\" heading, and the expected list after it. A wrong stop, or a walk "
    "that reached the end with any expected stop not read, fails the test for "
    "good; only a walk cut short before the end with every stop right so far, or "
    "one with a stop read as an empty phrase (a failed capture, which never "
    "passes) and nothing wrong read, is walked again, up to three walks, each "
    "shown as its own row (`-walk-<n>`). VoiceOver's own help message (\"You are "
    "currently on ...\") is left out only at the cursor position of the stop before it, "
    "when that stop's spoken role is the help's. No runner retries"
)
