"""Evidence tool registration for S10 Content group replacement.

Read by tool/evidence_common.py, which says what each name means."""

ID = "S10"
TITLE = "S10 Content group replacement"
ANDROID_TEST = "S10ContentGroupReplacementTest"
IOS_TEST = "S10ContentGroupReplacementUITests"
WEB_VO_SPEC = "s10_content_group_replacement_vo.spec.js"

_WORDS = "Rating: 3.4 out of 5 stars, based on 856 reviews"
_WORDS_AFTER = "Rating: 3.4 out of 5 stars, based on 857 reviews"
_ADD = "Add a 5-star review"
# What a piece of the bar row, or the bar itself, would add if it were read.
_PIECES = ["3.4 / 5", "Reviews: 856", "Progress bar", "68"]

# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be). S10 is in talkback.py's STRICT set: each walk is judged whole.
TALKBACK_EXPECT = {
    # The replacement alone: what the rating means, and none of its pieces.
    "s10-good-exclude-semantics-rating": ([_WORDS], _PIECES + ["Button"]),
    "s10-good-exclude-semantics-add": ([_ADD, "Button"], [_WORDS]),
    # After the click action on the button, the replacement says 857.
    "s10-good-exclude-semantics-after": ([_WORDS_AFTER], _PIECES + ["856"]),
    "s10-good-hidden-pieces-rating": ([_WORDS], _PIECES + ["Button"]),
    "s10-good-stars-rating": ([_WORDS], _PIECES + ["Button", "Image"]),
    # Bad examples: the defect must be audible where Android shows it. The
    # two numbers alone, and nothing for the stars.
    "s10-bad-pieces-stars": (["3.4"], ["star", "out of", "Rating", "review"]),
    "s10-bad-pieces-count": (["856"], ["star", "out of", "Rating", "review"]),
    # One node, the bar's value, 68, before the pieces (FL-330). In the probe
    # TalkBack read "68.0.", "68,", and the pieces, and no role word within
    # the dwell (docs/evidence/probes/s10/android-talkback.md, p02); the
    # role is not judged.
    "s10-bad-merged-rating": (["68", "Rating: 3.4 / 5 Reviews: 856"], ["out of 5 stars"]),
    # The bar's value, then the label, then the pieces again (p06).
    "s10-bad-not-excluded-rating": (["68", f"{_WORDS} Rating: 3.4 / 5 Reviews: 856"], []),
    # The rating, then the count; no Reviews button anywhere.
    "s10-bad-hides-control-rating": ([_WORDS], ["Button"] + _PIECES),
    "s10-bad-hides-control-opens": (["Reviews opened: 0"], ["Button"]),
    "s10-bad-stale-rating": ([_WORDS], _PIECES),
    "s10-bad-stale-add": ([_ADD, "Button"], [_WORDS]),
    # After the click action the row shows 857, and the replacement still
    # says 856.
    "s10-bad-stale-after": ([_WORDS], ["857"]),
}

# tool/voiceover_ios.py: (how the speech was captured, heading of the
# transcript column).
VOICEOVER_IOS_METHOD = (
    "`XCUIVoiceOverService.moveForward()` from the top of the screen to its "
    "end, where moving on gives the last utterance again, twice (C03's walk); "
    "what is shown is everything after the \"Example\" heading, and a walk "
    "that does not reach the end fails. A row ending `-after` was walked once "
    "the add button had been tapped, with VoiceOver off",
    "Spoken, in swipe order",
)

# tool/voiceover_web.py: how the speech was captured.
VOICEOVER_WEB_METHOD = (
    "focus the Back button, then `voiceOver.next()` to the end of the screen. "
    "VoiceOver's last phrase and the position of its cursor are read over "
    "AppleScript after every move: a move that changes the position, or that "
    "speaks a different phrase, is a stop; two moves in a row that do neither are "
    "the end. Every walk must read the whole screen, each stop in its place "
    "(web_tests/vo/s10_vo_walks.js, a copy of S08's judge): the title and the "
    "description, the \"Example\" heading, and the expected list after it. A "
    "wrong stop, or a walk that reached the end with any expected stop not "
    "read, fails the test for good; a walk cut short before the end with every "
    "stop right so far, or one with a stop read as an empty phrase and nothing "
    "wrong, is walked again, up to three walks, each shown as its own row "
    "(`-walk-<n>`). VoiceOver's help message is left out. A row with `-after` "
    "was walked once a review had been added with a mouse click. No runner "
    "retries"
)
