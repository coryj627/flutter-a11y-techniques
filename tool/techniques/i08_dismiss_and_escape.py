"""Evidence tool registration for I08 Dismiss and escape.

Read by tool/evidence_common.py, which says what each name means."""

ID = "I08"
TITLE = "I08 Dismiss and escape"
ANDROID_TEST = "I08DismissAndEscapeTest"
IOS_TEST = "I08DismissAndEscapeUITests"
WEB_VO_SPEC = "i08_dismiss_and_escape_vo.spec.js"

_ALL = ("good-material", "good-cupertino", "good-widgets",
        "bad-not-dismissible", "bad-no-escape", "bad-back-leaves")
# The examples whose layers close on TalkBack's Back gesture.
_BACK_CLOSES = ("good-material", "good-cupertino", "good-widgets",
                "bad-not-dismissible", "bad-no-escape")
# The barrier each example's layers have, by what TalkBack reads; the
# non-dismissible sheet's barrier is no element at all.
_BARRIER = {
    "good-material": "Scrim",
    "good-cupertino": "Dismiss",
    "good-widgets": "Close map layers",
    "bad-no-escape": "Close map layers",
    "bad-back-leaves": "Close map layers",
}

# tool/talkback.py: marker -> (phrases that must be spoken, phrases that
# must not be). "Switch" and "Button" are matched as whole sentences, so a
# name cannot supply them.
TALKBACK_EXPECT = {
    # The button that shows the layers.
    **{f"i08-{slug}-open": (["Map layers", "Button"], []) for slug in _ALL},
    # Each switch: its name, its role, and its state, never the other one.
    **{f"i08-{slug}-contours": (["Contour lines", "Switch", "On"], ["Off"]) for slug in _ALL},
    **{f"i08-{slug}-campsites": (["Campsites", "Switch", "Off"], ["On"]) for slug in _ALL},
    # The barrier, a control of its own that closes the layers.
    **{f"i08-{slug}-barrier": ([name], []) for slug, name in _BARRIER.items()},
    # TalkBack's Back gesture: the layers close and TalkBack's focus goes
    # back to the button, which it reads. Where its focus ends, the test
    # itself checks.
    **{f"i08-{slug}-back": (["Map layers", "Button"], ["Contour lines", "Campsites"])
       for slug in _BACK_CLOSES},
    # In bad-back-leaves the gesture leaves the screen, and TalkBack reads
    # the technique's own screen instead.
    "i08-bad-back-leaves-back": (["Dismiss and escape"], ["Contour lines", "Campsites"]),
}

TALKBACK_METHOD = (
    "TalkBack's focus is put on Map layers, the button is activated with the click action, as "
    "a double tap does, and then TalkBack's focus is put on each switch and on the barrier in "
    "turn; a marker is logged before each, and what TalkBack says next is credited to it. "
    "Then TalkBack's Back gesture is made, through `performGlobalAction(GLOBAL_ACTION_BACK)`, "
    "the call the gesture makes, and what TalkBack says next is credited to the `back` row; "
    "the test also reads where TalkBack's focus is (`isAccessibilityFocused`) and fails "
    "unless it is on Map layers for the last two seconds of an eight-second window (on the "
    "technique's own screen in bad-back-leaves). Speech is read from TalkBack's verbose log"
)

# tool/voiceover_ios.py: (how the speech was captured, heading of the
# transcript column).
VOICEOVER_IOS_METHOD = (
    "with VoiceOver on, `tap()` moves its cursor to Map layers and `doubleTap()` activates "
    "it; then `moveForward()` from where VoiceOver went by itself, until it has read the "
    "barrier, at most eight moves. VoiceOver's escape gesture (a two-finger scrub) cannot "
    "be made from XCUITest, so it is not in this transcript",
    "Spoken after the layers open, in swipe order",
)

# tool/voiceover_web.py: how the speech was captured.
VOICEOVER_WEB_METHOD = (
    "VoiceOver's cursor is put on Map layers by giving the element focus, and the button is "
    "activated with VoiceOver's own command (VO-Space); VoiceOver's last phrases are read "
    "over AppleScript for a few seconds after. Then Escape is pressed through the system "
    "keyboard, as a VoiceOver user presses it, and the phrases after it are read, with "
    "whether the layers closed"
)
