"""Evidence tool registration for S14 Values and state descriptions.

Read by tool/evidence_common.py, which says what each name means."""

ID = "S14"
TITLE = "S14 Values and state descriptions"
ANDROID_TEST = "S14ValuesAndStateDescriptionsTest"
IOS_TEST = "S14ValuesAndStateDescriptionsUITests"
WEB_VO_SPEC = "s14_values_and_state_descriptions_vo.spec.js"

# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be).
TALKBACK_EXPECT = {
    # S14 Values and state descriptions. The value is read with the name,
    # and again, changed, after the control is changed.
    "s14-good-rating-rating": (["Rating", "3 out of 5"], []),
    "s14-good-rating-rating-changed": (["Rating", "4 out of 5"], ["3 out of 5"]),
    "s14-good-step-progress": (["Progress", "Step 2 of 4"], []),
    "s14-good-step-progress-changed": (["Progress", "Step 3 of 4"], ["Step 2 of 4"]),
    "s14-good-button-value-repeat": (["Repeat", "Off", "Button"], []),
    "s14-good-button-value-repeat-changed": (["Repeat", "All", "Button"], []),
    "s14-good-slider-format-timer": (["Timer", "15 minutes"], ["%", "percent"]),
    # Bad examples: the defect must be audible.
    "s14-bad-rating-no-value-rating": (["Rating"], ["out of 5"]),
    "s14-bad-stale-value-rating": (["Rating", "3 out of 5"], []),
    # The rating is 5 by then, and the true value must not be heard. Android
    # says "4 out of 5": the bridge's guess after an increase (FL-038).
    "s14-bad-stale-value-rating-changed": (["Rating"], ["5 out of 5"]),
    "s14-bad-step-no-value-one": (["1"], ["Step", "Progress", "Selected"]),
    "s14-bad-step-no-value-two": (["2"], ["Step", "Progress", "Selected"]),
    "s14-bad-button-no-value-repeat": (["Repeat", "Button"], ["Off", "All"]),
    "s14-bad-button-no-value-repeat-changed": (["Repeat", "Button"], ["Off", "All"]),
    # Both wordings of the state are read.
    "s14-bad-value-on-switch-alarm": (["Home alarm", "Deactivated", "Switch"], []),
}

# tool/voiceover_ios.py: (how the speech was captured, heading of the
# transcript column).
VOICEOVER_IOS_METHOD = (
    "`XCUIVoiceOverService.moveForward()` from the top of the screen to the "
    "change count, which is the last element of every example. What is shown "
    "is everything between the \"Example\" heading and the count; a move at which "
    "VoiceOver said nothing is shown as \"(no speech)\" only when one move back "
    "read the element before it and the move forward again was silent too, which "
    "shows the cursor was on an element of its own",
    "Spoken, in swipe order",
)

# tool/voiceover_web.py: how the speech was captured.
VOICEOVER_WEB_METHOD = (
    "focus the Back button, then `voiceOver.next()` to the end of the screen. "
    "VoiceOver's last phrase and the position of its cursor are read over "
    "AppleScript after every move: a move that changes the position, or that "
    "speaks a different phrase, is a stop; two moves in a row that do neither are "
    "the end. The four examples that are sliders on web are walked only as far "
    "as the slider, and are judged in Chromium only"
)
