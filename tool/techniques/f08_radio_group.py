"""Evidence tool registration for F08 Radio group.

Read by tool/evidence_common.py, which says what each name means."""

ID = "F08"
TITLE = "F08 Radio group"
ANDROID_TEST = "F08RadioGroupTest"
IOS_TEST = "F08RadioGroupUITests"
WEB_VO_SPEC = "f08_radio_group_vo.spec.js"

# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be).
TALKBACK_EXPECT = {
    # F08 Radio group. TalkBack says "checked" before the name of the chosen
    # radio button and no state for the others, as for a checkbox (FL-045).
    # Written to fail when "not checked" starts being spoken.
    "f08-good-group-group": (["Delivery speed"], ["Radio button"]),
    "f08-good-group-standard": (["Standard", "Radio button"], ["checked"]),
    "f08-good-group-express": (["checked", "Express", "Radio button"], ["not checked"]),
    "f08-good-group-standard-changed": (["checked", "Standard", "Radio button"], ["not checked"]),
    "f08-good-cupertino-group": (["Delivery speed"], ["Radio button"]),
    "f08-good-cupertino-standard": (["Standard", "Radio button"], ["checked"]),
    "f08-good-cupertino-express": (["checked", "Express", "Radio button"], ["not checked"]),
    "f08-good-cupertino-standard-changed": (["checked", "Standard", "Radio button"], ["not checked"]),
    "f08-good-custom-group": (["Delivery speed"], ["Radio button"]),
    "f08-good-custom-standard": (["Standard", "Radio button"], ["checked"]),
    "f08-good-custom-express": (["checked", "Express", "Radio button"], ["not checked"]),
    "f08-good-custom-standard-changed": (["checked", "Standard", "Radio button"], ["not checked"]),
    # The answers carry the question.
    "f08-good-context-group": (["Are you at home?"], ["Radio button"]),
    "f08-good-context-yes": (["Yes, I am at home", "Radio button"], ["checked"]),
    "f08-good-context-no": (["checked", "No, I am not at home", "Radio button"], ["not checked"]),
    # Bad examples: the defect must be audible where it can be.
    "f08-bad-unlabelled-first": (["Radio button"], ["Standard", "checked"]),
    "f08-bad-unlabelled-second": (["checked", "Radio button"], ["Express"]),
    "f08-bad-group-unlabelled-question": (["Delivery speed"], ["Radio button"]),
    "f08-bad-group-unlabelled-standard": (["Standard", "Radio button"], ["checked"]),
    "f08-bad-group-unlabelled-express": (["checked", "Express", "Radio button"], ["not checked"]),
    "f08-bad-no-state-standard": (["Standard", "Button"], ["Radio button", "checked", "selected"]),
    "f08-bad-no-state-express": (["Express", "Button"], ["Radio button", "checked", "selected"]),
    "f08-bad-no-state-standard-changed": (["Standard", "Button"], ["Radio button", "checked", "selected"]),
    "f08-bad-checkbox-role-standard": (["Standard", "Check box"], ["Radio button"]),
    "f08-bad-checkbox-role-express": (["checked", "Express", "Check box"], ["Radio button"]),
    # Correct on Android: the defect of this example is on iOS.
    "f08-bad-checked-only-standard": (["Standard", "Radio button"], ["checked"]),
    "f08-bad-checked-only-express": (["checked", "Express", "Radio button"], ["not checked"]),
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
    "focus the Back button, wait until VoiceOver has been quiet for two seconds, then "
    "`voiceOver.next()` to the end of the screen. VoiceOver's last phrase and the "
    "position of its cursor are read over AppleScript after every move: a move that "
    "changes the position, or that speaks a different phrase, is a stop; two moves in "
    "a row that do neither are the end. The change count is the last element of every "
    "example. Where VoiceOver's last phrase is its own help message "
    "(\"You are currently on…\"), which follows a radio button with no name at once, the "
    "phrase Guidepup logged for that move is shown instead"
)
