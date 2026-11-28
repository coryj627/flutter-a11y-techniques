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

# What TalkBack was given to speak for the ornaments: the characters
# themselves (docs/evidence/probes/s12/android-talkback.md, p25, and
# docs/evidence/S12/talkback-android.md). Its log holds the text sent to
# speech, not how the voice pronounced it.
_MARK_SPEECH = "❝"
_ORNAMENT_SPEECH = "✦ ✦ ✦"

# Every row is a whole-utterance row ("== A / B / C" in tool/talkback.py's
# said()): the row's utterances must be exactly these, in this order, and
# nothing else, TalkBack's usage hint "Double-tap to activate" allowed once
# at the end. A substring check would pass a duplicated phrase, an extra
# role word, a wrong number, or a sibling's label that holds the expected
# words (S10's review). Each is what the S12 transcript heard
# (docs/evidence/S12/talkback-android.md); the switch's own hint, "Double-tap
# to toggle", is not the one the form allows, so it is required as heard.
_SWITCH_OFF = (["== off. / Show tracking / Switch / Double-tap to toggle"], [])


def _whole(*utterances):
    return ([f"== {' / '.join(utterances)}"], [])


# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be). The walk (S12HidingContentTest.talkBackWalk) moves TalkBack
# focus to each part of each example in turn. Each walk is judged whole
# (S12 is in tool/talkback.py's STRICT set).
TALKBACK_EXPECT = {
    # The quote and its source, each alone: no ornament with either.
    "s12-good-decoration-quote": _whole(_QUOTE),
    "s12-good-decoration-source": _whole(_SOURCE),
    # The words alone.
    "s12-good-badge-inbox": _whole(_INBOX),
    # Hidden: the switch, off, and the count; the panel is no node, which
    # the tree test shows.
    "s12-good-visibility-show": _SWITCH_OFF,
    "s12-good-visibility-count": _whole("Copies: 0"),
    # Bad examples: the defect must be audible. Each ornament read.
    "s12-bad-decoration-read-mark": _whole(_MARK_SPEECH),
    "s12-bad-decoration-read-quote": _whole(_QUOTE),
    "s12-bad-decoration-read-source": _whole(_SOURCE),
    "s12-bad-decoration-read-ornament": _whole(_ORNAMENT_SPEECH),
    # The quote and the count; no Share.
    "s12-bad-hidden-control-quote": _whole(_QUOTE),
    "s12-bad-hidden-control-count": _whole("Shares: 0"),
    "s12-bad-opacity-show": _SWITCH_OFF,
    "s12-bad-opacity-count": _whole("Copies: 0"),
    # Hidden, and read all the same.
    "s12-bad-maintain-show": _SWITCH_OFF,
    "s12-bad-maintain-tracking": _whole(_TRACKING),
    "s12-bad-maintain-copy": _whole("Copy number", "Button"),
    "s12-bad-maintain-count": _whole("Copies: 0"),
}

# tool/talkback.py: how the speech was captured.
TALKBACK_METHOD = (
    "TalkBack focus moved by ACTION_ACCESSIBILITY_FOCUS to each part of each example in turn, "
    "six seconds each; speech read from TalkBack's verbose log. Each walk is judged whole: a "
    "wrong reading fails for good, and only a walk shown to be incomplete is walked again, up "
    "to three walks. Every row is judged as whole utterances, exactly those heard and in their "
    "order (\"== A / B\"), the usage hint allowed once at the end. What is hidden is not focused: a node that is not there cannot be, "
    "which the tree test shows"
)

# tool/voiceover_ios.py: (how the speech was captured, heading of the
# transcript column).
VOICEOVER_IOS_METHOD = (
    "`XCUIVoiceOverService.moveForward()` from the top of the screen to its "
    "end (S12Walk.collect): every utterance is a stop, a stop read twice in a row "
    "mid-screen fails the walk, and two repeats end it only when a move back reads "
    "the stop before the last and a move forward the last again (the end witness, "
    "shown after the walk). "
    "What is shown is the whole walk, the screen's own stops included, and it is "
    "judged against this example's screen (S12Walk.judge): Back may come first, "
    "then the screen's title as a heading, its description, a bad example's "
    "defect (cut by the service at 64 characters), the \"Example\" heading once, "
    "and exactly the expected content; a walk that does not reach the end fails",
    "Spoken, in swipe order",
)

# tool/voiceover_web.py: how the speech was captured.
VOICEOVER_WEB_METHOD = (
    "focus the Back button, then `voiceOver.next()` to the end of the screen "
    "(collectWalk in web_tests/vo/s12_vo_walks.js). The end is accepted only with "
    "a witness: a move back whose fresh reading is the stop before the last at "
    "another position, then a move forward whose reading is the last stop at its "
    "position; a frozen or empty reading there fails the walk for good, and both "
    "readings are the `-end` row. "
    "VoiceOver's last phrase and the position of its cursor are read over "
    "AppleScript after every move: a move that changes the position, or that "
    "speaks a different phrase, is a stop; two moves in a row that do neither are "
    "the end. A single move that does neither, followed by one that moves on, is an "
    "unresolved read (a capture that may have lost an element): the walk is then "
    "incomplete, walked again, and can never pass; every walk's unresolved reads, "
    "or \"none\", are its `-unresolved` row. Every walk must read the whole screen, each stop in its place "
    "(web_tests/vo/s12_vo_walks.js, S08's judge): the title and the description, the "
    "\"Example\" heading, and the expected list after it. A wrong stop, or a walk "
    "that reached the end with any expected stop not read, or one that ran out of "
    "moves, fails the test for good, and an unresolved read hides no wrong stop: "
    "across it the next stop must be the next expected one or the one after it; "
    "only a walk that reached the end with its witness, nothing wrong read, and a "
    "stop read as an empty phrase or an unresolved read (a failed capture, which "
    "never passes) is walked again, up to three walks, each "
    "shown as its own row (`-walk-<n>`). VoiceOver's own help message (\"You are "
    "currently on ...\") is left out only at the cursor position of the stop before it, "
    "when that stop's spoken role is the help's. No runner retries"
)
