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
    "focus the Back button and capture VoiceOver's last phrase and its cursor's position there "
    "(the walk's start row), then `voiceOver.next()` to the end of the screen, capturing both "
    "over AppleScript after every move (collectWalk, web_tests/vo/s10_vo_walks.js, S16's walk). A "
    "move that changes the position, or that speaks a non-empty phrase other than the stop before "
    "it (or than the start, before the first stop), is a stop, and the position at each stop is "
    "the walk's positions row. A move that does neither is kept: one followed by a move on is an "
    "unresolved read, a gap after the stop before it, and is listed on the walk's unresolved row; "
    "two in a row are the end only when a move back then reads the stop before the last, not "
    "empty, at another position, and a move forward the last again at its position, both on the "
    "walk's end row; the move back may instead read VoiceOver's help about the stop before the "
    "last, naming its spoken role, at exactly that stop's recorded position; a failed witness "
    "is wrong for good. Every walk is judged whole (judgeWalk): "
    "the title, the description, the \"Example\" heading, and the expected list after it, each in "
    "its place; a stop past the last expected one, empty or not, is wrong; a wrong stop always "
    "wins, across a gap the next stop must be the next expected one or the one after it, and a "
    "walk that ran out of moves is wrong. Only a walk with no wrong stop and a gap, or a stop read "
    "as an empty phrase, is walked again, up to three walks, each its own row (`-walk-<n>`), and "
    "it never passes. VoiceOver's own help message (\"You are currently on ...\" or \"in ...\") is left out only "
    "at the position of the stop before it, whose reading speaks the role the help names; it stays "
    "in the walk's row, and the web tree spec judges the transcript again from its rows by the "
    "same rule, from the positions row. "
    "A row with `-after` was walked once a review had been added with a mouse click, and only "
    "once the witness node showed that the click took effect. "
    "No runner retries"
)
