"""Evidence tool registration for I01 Focusable and clickable controls.

Read by tool/evidence_common.py, which says what each name means."""

ID = "I01"
TITLE = "I01 Focusable and clickable controls"
ANDROID_TEST = "I01FocusableControlsTest"
IOS_TEST = "I01FocusableControlsUITests"
WEB_VO_SPEC = "i01_focusable_controls_vo.spec.js"

# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be). "Button" is matched as a whole sentence, so the name "Ridge
# trail" cannot supply it. The keyboard and pointer defects of bad-no-focus,
# bad-no-key-action, and bad-tap-down are not heard: TalkBack reads those
# cards as it reads the good ones, which is what these lines record.
TALKBACK_EXPECT = {
    "i01-good-material-trail": (["Ridge trail", "Button", "Double-tap to activate"], []),
    "i01-good-cupertino-trail": (["Ridge trail", "Button", "Double-tap to activate"], []),
    "i01-good-custom-trail": (["Ridge trail", "Button", "Double-tap to activate"], []),
    # The defect: no role. TalkBack still offers to activate it, because the
    # node has a click action, but never says what it is.
    "i01-bad-inkwell-no-role-trail": (["Ridge trail", "Double-tap to activate"], ["Button"]),
    "i01-bad-no-focus-trail": (["Ridge trail", "Button", "Double-tap to activate"], []),
    "i01-bad-no-key-action-trail": (["Ridge trail", "Button", "Double-tap to activate"], []),
    "i01-bad-tap-down-trail": (["Ridge trail", "Button", "Double-tap to activate"], []),
}

# tool/voiceover_ios.py: (how the speech was captured, heading of the
# transcript column).
VOICEOVER_IOS_METHOD = (
    "`XCUIVoiceOverService.moveForward()` from the top of the screen to the "
    "activation count, which is the last element of every example. What is shown "
    "is everything between the \"Example\" heading and the count",
    "Spoken, in swipe order",
)

# tool/voiceover_web.py: how the speech was captured.
VOICEOVER_WEB_METHOD = (
    "focus the Back button, wait until VoiceOver has been quiet for two seconds, then "
    "`voiceOver.next()` to the end of the screen. VoiceOver's last phrase and the "
    "position of its cursor are read over AppleScript after every move: a move that "
    "changes the position, or that speaks a different phrase, is a stop; two moves in "
    "a row that do neither are the end. The activation count is the last element of "
    "every example"
)
