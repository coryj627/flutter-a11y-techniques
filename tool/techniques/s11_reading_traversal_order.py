"""Evidence tool registration for S11 Reading and traversal order.

Read by tool/evidence_common.py, which says what each name means."""

ID = "S11"
TITLE = "S11 Reading and traversal order"
ANDROID_TEST = "S11ReadingTraversalOrderTest"
IOS_TEST = "S11ReadingTraversalOrderUITests"
WEB_VO_SPEC = "s11_reading_traversal_order_vo.spec.js"

# Each part of the screen after the "Example" heading, as TalkBack reads it,
# one utterance each: a heading is its text and "Heading"; a button its text,
# "Button", and the usage hint TalkBack gives with a keyboard attached,
# "Press select to activate", which every button row of both recordings had
# (docs/evidence/S11/talkback-android.md).
_PARTS = {
    "route": ["Route", "Heading"],
    "park": ["Park at the gate."],
    "climb": ["Climb the ridge."],
    "back": ["Walk back."],
    "save-route": ["Save route", "Button", "Press select to activate"],
    "bring": ["Bring", "Heading"],
    "water": ["Water"],
    "map": ["A map"],
    "save-list": ["Save list", "Button", "Press select to activate"],
    "route-saves": ["Route saves: 0"],
    "list-saves": ["List saves: 0"],
}
_MEANT = ["route", "park", "climb", "back", "save-route", "bring", "water", "map", "save-list",
          "route-saves", "list-saves"]

# The order each example is read in, one part per press of TalkBack's
# "next" after the "Example" heading: the order the Android tree test
# measures (S11ReadingTraversalOrderTest), on the local emulator.
_ORDERS = {
    "good-columns": _MEANT,
    "good-sort-keys": _MEANT,
    "bad-columns-mixed": ["route", "bring", "park", "water", "climb", "map", "back", "save-route",
                          "save-list", "route-saves", "list-saves"],
    "bad-key-missing": ["route", "bring", "park", "climb", "back", "save-route", "water", "map",
                        "save-list", "route-saves", "list-saves"],
}


# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be). "s11-<example>-<n>" is what TalkBack said after its n-th
# press of "next" (Search and Right on a keyboard), counted from the "Example"
# heading: so each row checks both which part TalkBack moved to and what it
# said there. The one required phrase is S06's whole-utterance form
# ("== A / B / C", talkback.said): what TalkBack said must be exactly the
# part's utterances, in order, each compared whole, and nothing more (only
# "Double-tap to activate" may come once at the end). Labels overlap
# ("Route" is in "Save route" and in "Route saves: 0"), so a phrase found
# anywhere could not tell a row's own label from another part's said beside
# it; a whole utterance can. A capture cut off in the log is judged by S06's
# whole_wrong at its place, so the rows need no phrase list of their own.
TALKBACK_EXPECT = {
    f"s11-{slug}-{n}": (["== " + " / ".join(_PARTS[part])], [])
    for slug, order in _ORDERS.items()
    for n, part in enumerate(order, 1)
}

# tool/talkback.py: how the speech was captured.
TALKBACK_METHOD = (
    "TalkBack focus put on the example's \"Example\" heading by action, then moved with TalkBack's "
    "own \"next\", Search (Meta) and Right on a keyboard registered with the shell's `uinput` tool, once per row: "
    "`<example>-<n>` is everything TalkBack said after the n-th press, so each row shows where "
    "TalkBack moved as well as what it said, and must be exactly that part's utterances, each "
    "whole, and nothing more (S06's whole-utterance form). Speech read "
    "from TalkBack's verbose log. Each walk is judged whole: a wrong reading fails for good, and "
    "only a walk shown to be incomplete is walked again"
)

# tool/voiceover_ios.py: (how the speech was captured, heading of the
# transcript column).
VOICEOVER_IOS_METHOD = (
    "`XCUIVoiceOverService.moveForward()` from the top of the screen to its "
    "end, where moving on gives the last utterance again, twice, and then one "
    "move back, which must read the stop before the last (S11Walk); the whole "
    "walk is shown. It must hold the example's own title, its good or bad line, "
    "and a bad example's defect right before \"Example Heading\", then exactly the "
    "expected content, with no stop read twice in a row",
    "Spoken, in swipe order, from the top",
)

# tool/voiceover_web.py: how the speech was captured.
VOICEOVER_WEB_METHOD = (
    "focus the Back button and capture VoiceOver's last phrase and its cursor's position there "
    "(the walk's start row), then `voiceOver.next()` to the end of the screen, capturing both "
    "over AppleScript after every move (collectWalk, web_tests/vo/s11_vo_walks.js, S16's walk). A "
    "move that changes the position, or that speaks a non-empty phrase other than the stop before "
    "it (or than the start, before the first stop), is a stop, and the position at each stop is "
    "the walk's positions row. A move that does neither is kept: one followed by a move on is an "
    "unresolved read, a gap after the stop before it, and is listed on the walk's unresolved row; "
    "two in a row are the end only when a move back then reads the stop before the last, not "
    "empty, at another position, and a move forward the last again at its position, both on the "
    "walk's end row; a failed witness is wrong for good. Every walk is judged whole (judgeWalk): "
    "the title, the description, the \"Example\" heading, and the expected list after it, each in "
    "its place; a stop past the last expected one, empty or not, is wrong; a wrong stop always "
    "wins, across a gap the next stop must be the next expected one or the one after it, and a "
    "walk that ran out of moves is wrong. Only a walk with no wrong stop and a gap, or a stop read "
    "as an empty phrase, is walked again, up to three walks, each its own row (`-walk-<n>`), and "
    "it never passes. VoiceOver's own help message (\"You are currently on ...\" or \"in ...\") is left out only "
    "at the position of the stop before it, whose reading speaks the role the help names; it stays "
    "in the walk's row, and the web tree spec judges the transcript again from its rows by the "
    "same rule, from the positions row. "
    "No runner retries"
)
