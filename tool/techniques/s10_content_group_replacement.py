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
_PIECES_ONE_LINE = "Rating: 3.4 / 5 Reviews: 856"

# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be). S10 is in talkback.py's STRICT set: each walk is judged
# whole.
#
# Every row is judged as whole utterances, never as words found in the
# row (Codex, first review: a substring check passed a row with the rating
# said twice, an extra "Image", or "(1856)" for "(856)"). "== A / B / C" is
# the row's utterances, exactly, in order, TalkBack's closing usage hint
# ("Double-tap to activate") allowed once at the end; "^= A" is its first
# utterance (tool/talkback.py, said). The rows are what the committed
# transcript holds (docs/evidence/S10/talkback-android.md).
#
# Two rows cannot be written whole: bad-merged's and bad-not-excluded's
# last utterance holds "3.4 / 5", and the "==" form splits its utterances
# at every "/", with no way to escape one. Those rows are judged by their
# first utterance, "68.0." ("^="), and by the row's text holding the
# pieces in one utterance (a substring), with the words that must not be
# there; an utterance added after the pieces is not caught (the spec,
# section 7, skips).
TALKBACK_EXPECT = {
    # The replacement alone, exactly; then the button; then, after the click
    # action on the button, the replacement saying 857.
    "s10-good-exclude-semantics-rating": ([f"== {_WORDS}"], []),
    "s10-good-exclude-semantics-add": ([f"== {_ADD} / Button"], []),
    "s10-good-exclude-semantics-after": ([f"== {_WORDS_AFTER}"], []),
    "s10-good-hidden-pieces-rating": ([f"== {_WORDS}"], []),
    "s10-good-stars-rating": ([f"== {_WORDS}"], []),
    # Bad examples: the defect must be audible where Android shows it. The
    # two numbers alone, and nothing for the stars.
    "s10-bad-pieces-stars": (["== 3.4"], []),
    "s10-bad-pieces-count": (["== (856)"], []),
    # The bar's value, 68, twice, an empty utterance, then the pieces in one
    # utterance (FL-330). No role word in the probe or the transcript; the
    # role is not judged.
    "s10-bad-merged-rating": (["^= 68.0.", _PIECES_ONE_LINE], ["out of 5 stars", "Image"]),
    # The same, with the replacement's words before the pieces.
    "s10-bad-not-excluded-rating": (["^= 68.0.", f"{_WORDS} {_PIECES_ONE_LINE}"], ["Image"]),
    # The rating, then the count; no Reviews button anywhere.
    "s10-bad-hides-control-rating": ([f"== {_WORDS}"], []),
    "s10-bad-hides-control-opens": (["== Reviews opened: 0"], []),
    "s10-bad-stale-rating": ([f"== {_WORDS}"], []),
    "s10-bad-stale-add": ([f"== {_ADD} / Button"], []),
    # After the click action the row shows 857, and the replacement still
    # says 856, exactly.
    "s10-bad-stale-after": ([f"== {_WORDS}"], []),
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
    "wrong stop, any stop past the end (empty or not), or a walk that reached "
    "the end with any expected stop not read, fails the test for good; a walk "
    "cut short before the end with every stop right so far, or one with a stop "
    "read as an empty phrase and nothing wrong, is walked again, up to three "
    "walks, each shown as its own row (`-walk-<n>`). VoiceOver's help message is "
    "left out only at the position of the stop before it and naming that stop's "
    "spoken role. A row with `-after` was walked once a review had been added "
    "with a mouse click. No runner retries"
)
