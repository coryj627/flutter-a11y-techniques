"""Evidence tool registration for S09 Content grouping.

Read by tool/evidence_common.py, which says what each name means."""

ID = "S09"
TITLE = "S09 Content grouping"
ANDROID_TEST = "S09ContentGroupingTest"
IOS_TEST = "S09ContentGroupingUITests"
WEB_VO_SPEC = "s09_content_grouping_vo.spec.js"

_GROUP = "Kitchen light"
_TARGET = "App information"


def _facts(slug):
    """Each label read with its value, and nothing of the other fact."""
    return {
        f"s09-{slug}-fact1": (["City Boston"], ["Founded", "1630", "Button"]),
        f"s09-{slug}-fact2": (["Founded 1630"], ["City", "Boston", "Button"]),
    }


# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be). The walk (S09ContentGroupingTest.talkBackWalk) moves
# TalkBack focus to each part of each example in turn.
TALKBACK_EXPECT = {
    **_facts("good-merged-facts"),
    **_facts("good-cupertino"),
    # The group's name is a stop of its own, with no role and nothing of
    # the buttons.
    "s09-good-named-group-group": ([_GROUP], ["Button"]),
    # Each button is read without the group's name, whether focus comes to
    # it from the question or straight from the "Example" heading (FL-320,
    # docs/evidence/probes/s09/android-talkback.md, s07 and s08): written to
    # fail if TalkBack starts saying the group's name with them.
    "s09-good-named-group-on": (["On", "Button"], ["Off", _GROUP]),
    "s09-good-named-group-off": (["Off", "Button"], [_GROUP]),
    "s09-good-named-group-heading": (["Example", "Heading"], [_GROUP]),
    "s09-good-named-group-on-direct": (["On", "Button"], ["Off", _GROUP]),
    # One button, named by the text; the icon says nothing of its own.
    "s09-good-tap-target-info": ([_TARGET, "Button"], ["Image"]),
    # Bad examples: the defect must be audible. Each label, and each
    # value, is a stop of its own, both labels first.
    "s09-bad-split-facts-city": (["City"], ["Boston", "Founded"]),
    "s09-bad-split-facts-founded": (["Founded"], ["1630", "City"]),
    "s09-bad-split-facts-boston": (["Boston"], ["City", "1630"]),
    "s09-bad-split-facts-1630": (["1630"], ["Founded", "Boston"]),
    # The question and both buttons are one button.
    "s09-bad-merged-group-light": ([f"{_GROUP} On Off", "Button"], []),
}

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
    "(web_tests/vo/s09_vo_walks.js): the title and the description, the "
    "\"Example\" heading, and the expected list after it. A wrong stop, or a walk "
    "that reached the end with any expected stop not read, fails the test for "
    "good; only a walk cut short before the end with every stop right so far is "
    "walked again, up to three walks, each shown as its own row (`-walk-<n>`). "
    "No runner retries"
)
