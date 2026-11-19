"""Evidence tool registration for V14 Focus indicators.

Read by tool/evidence_common.py, which says what each name means."""

ID = "V14"
TITLE = "V14 Focus indicators"
ANDROID_TEST = "V14FocusIndicatorsTest"
IOS_TEST = "V14FocusIndicatorsUITests"
WEB_VO_SPEC = "v14_focus_indicators_vo.spec.js"

# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be). A focus indicator is drawn, not spoken: none of the defects
# of V14 is heard, and the bad examples are read as the good ones. These
# lines record what each control is to TalkBack. "Button", "Check box",
# "Switch", "off", and "checked" are matched as whole sentences.
TALKBACK_EXPECT = {
    # TalkBack says no state for a Flutter checkbox that is not checked
    # (FL-045).
    "v14-good-material-alerts": (["Weather alerts", "Check box"], ["checked"]),
    "v14-good-material-save": (["Save", "Button"], []),
    "v14-good-cupertino-alerts": (["off", "Weather alerts", "Switch"], ["on", "checked"]),
    "v14-good-cupertino-save": (["Save", "Button"], []),
    "v14-good-widgets-trail": (["Ridge trail", "Button"], []),
    "v14-good-notice-below-trail1": (["Ridge trail", "Button"], []),
    "v14-good-notice-below-trail3": (["Summit path", "Button"], []),
    "v14-bad-indicator-removed-save": (["Save", "Button"], []),
    "v14-bad-checkbox-halo-alerts": (["Weather alerts", "Check box"], ["checked"]),
    "v14-bad-cupertino-ring-save": (["Save", "Button"], []),
    "v14-bad-notice-over-list-trail1": (["Ridge trail", "Button"], []),
    # Under the notice, and read all the same: a screen reader is not
    # hindered by what covers a control.
    "v14-bad-notice-over-list-trail4": (["Forest walk", "Button"], []),
}

# tool/voiceover_ios.py: (how the speech was captured, heading of the
# transcript column).
VOICEOVER_IOS_METHOD = (
    "`XCUIVoiceOverService.moveForward()` from the top of the screen to the "
    "\"Last used\" line, which is the last element of every example. What is shown "
    "is everything between the \"Example\" heading and that line",
    "Spoken, in swipe order",
)

# tool/voiceover_web.py: how the speech was captured.
VOICEOVER_WEB_METHOD = (
    "focus the Back button, wait until VoiceOver has been quiet for two seconds, then "
    "`voiceOver.next()` to the end of the screen. VoiceOver's last phrase and the "
    "position of its cursor are read over AppleScript after every move: a move that "
    "changes the position, or that speaks a different phrase, is a stop; two moves in "
    "a row that do neither are the end. The \"Last used\" line is the last element of "
    "every example"
)
