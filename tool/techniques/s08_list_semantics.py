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
    "focus the Back button, then `voiceOver.next()` to the end of the screen. "
    "VoiceOver's last phrase and the position of its cursor are read over "
    "AppleScript after every move: a move that changes the position, or that "
    "speaks a different phrase, is a stop; two moves in a row that do neither are "
    "the end. Every walk must read the whole screen, each stop in its place "
    "(web_tests/vo/s08_vo_walks.js): the title and the description, the "
    "\"Example\" heading, and the expected list after it. A wrong stop, or a walk "
    "that reached the end with any expected stop not read, fails the test for "
    "good; only a walk cut short before the end with every stop right so far, or "
    "one with a stop read as an empty phrase (a failed capture, which never "
    "passes) and nothing wrong read, is walked again, up to three walks, each "
    "shown as its own row (`-walk-<n>`). No runner retries"
)
