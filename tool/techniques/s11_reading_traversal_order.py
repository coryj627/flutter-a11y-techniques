"""Evidence tool registration for S11 Reading and traversal order.

Read by tool/evidence_common.py, which says what each name means."""

ID = "S11"
TITLE = "S11 Reading and traversal order"
ANDROID_TEST = "S11ReadingTraversalOrderTest"
IOS_TEST = "S11ReadingTraversalOrderUITests"
WEB_VO_SPEC = "s11_reading_traversal_order_vo.spec.js"

# Each part of the screen after the "Example" heading, as TalkBack reads it:
# (phrases that must be spoken). A heading is its text and "Heading", a
# button its text and "Button" (the usage hint is not required, as in C18).
_PARTS = {
    "route": ["Route", "Heading"],
    "park": ["Park at the gate."],
    "climb": ["Climb the ridge."],
    "back": ["Walk back."],
    "save-route": ["Save route", "Button"],
    "bring": ["Bring", "Heading"],
    "water": ["Water"],
    "map": ["A map"],
    "save-list": ["Save list", "Button"],
    "route-saves": ["Route saves: 0"],
    "list-saves": ["List saves: 0"],
}
# The words that tell each part from every other, in lower case: a stop must
# say its own and none of another part's, so a stop that lands on the wrong
# part is a wrong reading. "Route" and "Save route" are both in "Route
# saves: 0", so the count's own word is "saves".
_OWN = {
    "route": "route", "park": "park at the gate", "climb": "climb the ridge", "back": "walk back",
    "save-route": "save route", "bring": "bring", "water": "water", "map": "a map",
    "save-list": "save list", "route-saves": "route saves", "list-saves": "list saves",
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


def _forbidden(part):
    """The words of every other part that this part's own words do not hold."""
    mine = " ".join(_PARTS[part]).lower()
    return [w for p, w in _OWN.items() if p != part and w not in mine and _OWN[part] not in w]


# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be). "s11-<example>-<n>" is what TalkBack said after its n-th
# press of "next" (Search and Right on a keyboard), counted from the "Example"
# heading: so each row checks both which part TalkBack moved to and what it
# said there.
TALKBACK_EXPECT = {
    f"s11-{slug}-{n}": (_PARTS[part], _forbidden(part))
    for slug, order in _ORDERS.items()
    for n, part in enumerate(order, 1)
}

# tool/talkback.py: how the speech was captured.
TALKBACK_METHOD = (
    "TalkBack focus put on the example's \"Example\" heading by action, then moved with TalkBack's "
    "own \"next\", Search (Meta) and Right on a keyboard registered with the shell's `uinput` tool, once per row: "
    "`<example>-<n>` is everything TalkBack said after the n-th press, so each row shows where "
    "TalkBack moved as well as what it said, and must name that part and no other. Speech read "
    "from TalkBack's verbose log. Each walk is judged whole: a wrong reading fails for good, and "
    "only a walk shown to be incomplete is walked again"
)

# tool/voiceover_ios.py: (how the speech was captured, heading of the
# transcript column).
VOICEOVER_IOS_METHOD = (
    "`XCUIVoiceOverService.moveForward()` from the top of the screen to its "
    "end, where moving on gives the last utterance again, twice (C03's walk); "
    "what is shown is everything after the \"Example\" heading, in the order "
    "VoiceOver moved, and a walk that does not reach the end fails",
    "Spoken, in swipe order",
)

# tool/voiceover_web.py: how the speech was captured.
VOICEOVER_WEB_METHOD = (
    "focus the Back button, then `voiceOver.next()` to the end of the screen. "
    "VoiceOver's last phrase and the position of its cursor are read over "
    "AppleScript after every move: a move that changes the position, or that "
    "speaks a different phrase, is a stop; two moves in a row that do neither are "
    "the end. Every walk must read the whole screen, each stop in its place "
    "(web_tests/vo/s11_vo_walks.js, S08's judge): the title and the description, "
    "the \"Example\" heading, and the expected list after it. A wrong stop, or a "
    "walk that reached the end with any expected stop not read, fails the test for "
    "good; a walk cut short with every stop right so far, or one with a stop read "
    "as an empty phrase and nothing wrong, is walked again, up to three walks, each "
    "shown as its own row (`-walk-<n>`). VoiceOver's own help message is left out "
    "only when the cursor is still at the stop before it and the role it names is "
    "in that stop's reading; any other fails. "
    "No runner retries"
)
