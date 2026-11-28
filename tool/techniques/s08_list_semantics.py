"""Evidence tool registration for S08 List semantics.

Read by tool/evidence_common.py, which says what each name means."""

ID = "S08"
TITLE = "S08 List semantics"
ANDROID_TEST = "S08ListSemanticsTest"
IOS_TEST = "S08ListSemanticsUITests"
WEB_VO_SPEC = "s08_list_semantics_vo.spec.js"

_GROCERIES = ["Milk", "Eggs", "Bread"]
_STEPS = ["1. Fork the repository", "2. Make the change", "3. Open a pull request"]
_KEYS = [g.lower() for g in _GROCERIES]
_IN_LIST = "In list"
_OUT = "Out of list"
# What TalkBack says of a native list's size and an item's place, which a
# list made with the list role does not say on Android (FL-311): in the
# probe a native ListView's first item was "n01 Milk. 1 of 3. In list. 3
# items" (docs/evidence/probes/s08/android-talkback.md, s08-native-1).
_COUNT = ["3 items", "1 of 3", "2 of 3", "3 of 3"]


def _list(slug, names, keys, role=()):
    """The rows of a list's items, in order. In the probe TalkBack said "In
    list" with the first item that focus moved to inside a list, and
    nothing about the list with the others (p03, p24, p28): the first must
    say it, the others must not, and none may say the list's size or the
    item's place (FL-311)."""
    rows = {}
    for i, (name, key) in enumerate(zip(names, keys)):
        must = [name, *role] + ([_IN_LIST] if i == 0 else [])
        must_not = _COUNT + ([] if i == 0 else [_IN_LIST])
        rows[f"s08-{slug}-{key}"] = (must, must_not)
    return rows


# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be). Each row is TalkBack focus moved to one item of a list, in
# order, or to one line of a bad example.
TALKBACK_EXPECT = {
    **_list("good-bulleted", _GROCERIES, _KEYS),
    **_list("good-numbered", _STEPS, ["1", "2", "3"]),
    **_list("good-material", _GROCERIES, _KEYS, ["Button"]),
    # The line after the list: TalkBack says that the list has ended.
    "s08-good-material-chosen": (["Chosen: none", _OUT], [_IN_LIST]),
    # The list itself, named by its header (p25: "p25 Groceries / List");
    # then its items, the first with the list's name (p25: "In list p25
    # Groceries").
    "s08-good-cupertino-list": (["Groceries", "List"], [_IN_LIST, *_COUNT]),
    **_list("good-cupertino", _GROCERIES, _KEYS),
    # Bad examples: the defect must be audible where Android shows it. One
    # text, and no list.
    "s08-bad-one-text-text": ([" ".join(_GROCERIES)], [_IN_LIST, *_COUNT]),
    # Lines, and no list.
    **{f"s08-bad-no-list-{k}": ([g], [_IN_LIST, *_COUNT]) for g, k in zip(_GROCERIES, _KEYS)},
    # Android keeps the button; the defect is the web's (FL-262).
    **_list("bad-tile-in-item", _GROCERIES, _KEYS, ["Button"]),
    "s08-bad-tile-in-item-chosen": (["Chosen: none", _OUT], [_IN_LIST]),
    # A list that scrolls: nothing about a list at all (p08; FL-313; and FL-312 on the web).
    **{f"s08-bad-lazy-list-{n}": ([f"Order {n}"], [_IN_LIST, "of 30", "30 items"]) for n in (1, 2)},
}

# tool/talkback.py: how the speech was captured.
TALKBACK_METHOD = (
    "ACTION_ACCESSIBILITY_FOCUS on each item of each list, in order, on the line after a list "
    "of tiles, on the Cupertino list itself, and on each line of the bad examples, five seconds "
    "each; speech read from TalkBack's verbose log. Each walk is judged whole: a wrong reading "
    "fails for good, and only a walk shown to be incomplete is walked again"
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
    "focus the Back button and capture VoiceOver's last phrase and its cursor's position there "
    "(the walk's start row), then `voiceOver.next()` to the end of the screen, capturing both "
    "over AppleScript after every move (collectWalk, web_tests/vo/s08_vo_walks.js, S16's walk). A "
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
    "it never passes. VoiceOver's own help message (\"You are currently on ...\") is left out only "
    "at the position of the stop before it, whose reading speaks the role the help names; it stays "
    "in the walk's row, and the web tree spec judges the transcript again from its rows by the "
    "same rule, from the positions row. "
    "At most 60 moves a walk. bad-lazy-list's expected list is by browser: all 30 orders in "
    "Chromium, 13 in WebKit. "
    "No runner retries"
)
