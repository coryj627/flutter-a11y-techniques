"""Evidence tool registration for V13 Minimum touch target size.

Read by tool/evidence_common.py, which says what each name means."""

ID = "V13"
TITLE = "V13 Minimum touch target size"
ANDROID_TEST = "V13TouchTargetSizeTest"
IOS_TEST = "V13TouchTargetSizeUITests"
WEB_VO_SPEC = "v13_touch_target_size_vo.spec.js"

_PLAYER = ("previous", "Previous"), ("play", "Play"), ("next", "Next")
_PLAYERS = ("good-material", "good-cupertino", "good-custom", "bad-shrinkwrap",
            "bad-zero-padding-web", "bad-cupertino-small", "bad-custom-small")

# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be). "Button" is matched as a whole sentence. Size is not heard:
# TalkBack reads the 18 pixel buttons of the bad examples as it reads the 48
# pixel ones of the good examples, which is what these lines record.
TALKBACK_EXPECT = {
    **{f"v13-{slug}-{control}": ([name, "Button", "Double-tap to activate"], [])
       for slug in _PLAYERS for control, name in _PLAYER},
    # Semantics(link: true) with no linkUrl is a button on Android (FL-032);
    # what a link is belongs to C03 and C04. This records what is said.
    "v13-good-inline-link-rules": (["trail rules", "Button", "Double-tap to activate"], []),
}

# tool/voiceover_ios.py: (how the speech was captured, heading of the
# transcript column).
VOICEOVER_IOS_METHOD = (
    "`XCUIVoiceOverService.moveForward()` from the top of the screen to the "
    "press count, which is the last element of every example. What is shown "
    "is everything between the \"Example\" heading and the count",
    "Spoken, in swipe order",
)

# tool/voiceover_web.py: how the speech was captured.
VOICEOVER_WEB_METHOD = (
    "focus the Back button, wait until VoiceOver has been quiet for two seconds, then "
    "`voiceOver.next()` to the end of the screen. VoiceOver's last phrase and the "
    "position of its cursor are read over AppleScript after every move: a move that "
    "changes the position, or that speaks a different phrase, is a stop; two moves in "
    "a row that do neither are the end. The press count is the last element of every "
    "example"
)
