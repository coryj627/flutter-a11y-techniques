"""Evidence tool registration for I02 Keyboard focus order.

Read by tool/evidence_common.py, which says what each name means."""

ID = "I02"
TITLE = "I02 Keyboard focus order"
ANDROID_TEST = "I02FocusOrderTest"
IOS_TEST = "I02FocusOrderUITests"
WEB_VO_SPEC = "i02_focus_order_vo.spec.js"


def _box(name):
    # "Check box" is matched as a whole sentence, so a name cannot supply it.
    # TalkBack says no state for a Flutter checkbox that is not checked
    # (FL-045), and "checked" is forbidden, which forbids "not checked" too.
    return ([name, "Check box"], ["checked"])


def _save():
    return (["Save plan", "Button", "Double-tap to activate"], ["Check box"])


# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be). The walk puts TalkBack's focus on each control in turn, so
# this records what is said at each one, not the order: the keyboard's order
# is not something TalkBack speaks, and the two bad examples are read like
# the good ones.
TALKBACK_EXPECT = {
    f"i02-{slug}-{key}": (_save() if key == "save" else _box(name))
    for slug in ("good-material", "good-cupertino", "good-ordered", "bad-columns-mixed",
                 "bad-order-missing")
    for key, name in (("map", "Map"), ("water", "Water"), ("aid", "First aid"),
                      ("weather", "Weather"), ("closures", "Closures"), ("save", "Save plan"))
}

# tool/voiceover_ios.py: (how the speech was captured, heading of the
# transcript column).
VOICEOVER_IOS_METHOD = (
    "`XCUIVoiceOverService.moveForward()` from the top of the screen to the "
    "save count, which is the last element of every example. What is shown is "
    "everything between the \"Example\" heading and the count, in the order "
    "VoiceOver's own moves reached it",
    "Spoken, in swipe order",
)

# tool/voiceover_web.py: how the speech was captured.
VOICEOVER_WEB_METHOD = (
    "focus the Back button, wait until VoiceOver has been quiet for two seconds, then "
    "`voiceOver.next()` to the end of the screen. VoiceOver's last phrase and the "
    "position of its cursor are read over AppleScript after every move: a move that "
    "changes the position, or that speaks a different phrase, is a stop; two moves in "
    "a row that do neither are the end. The save count is the last element of every "
    "example"
)
