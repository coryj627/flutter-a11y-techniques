"""Evidence tool registration for F07 Checkbox.

Read by tool/evidence_common.py, which says what each name means."""

ID = "F07"
TITLE = "F07 Checkbox"
ANDROID_TEST = "F07CheckboxTest"
IOS_TEST = "F07CheckboxUITests"
WEB_VO_SPEC = "f07_checkbox_vo.spec.js"

# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be).
TALKBACK_EXPECT = {
    # F07 Checkbox. TalkBack says "checked" before the name of a checked
    # box. For a Flutter checkbox that is not checked it says no state at
    # all (FL-045); a native one is read "not checked". Written to fail when
    # "not checked" starts being spoken.
    "f07-good-tile-updates": (["Email me product updates", "Check box"], ["checked"]),
    "f07-good-tile-updates-changed": (["checked", "Email me product updates", "Check box"], ["not checked"]),
    "f07-good-cupertino-updates": (["Email me product updates", "Check box"], ["checked"]),
    "f07-good-cupertino-updates-changed": (["checked", "Email me product updates", "Check box"], ["not checked"]),
    "f07-good-custom-updates": (["Email me product updates", "Check box"], ["checked"]),
    "f07-good-custom-updates-changed": (["checked", "Email me product updates", "Check box"], ["not checked"]),
    # Mixed: the node is partially checked on Android 16 (API 36) and later
    # and not checked before that. TalkBack says no state for it on either
    # (FL-044). Written to fail when it says one.
    "f07-good-mixed-all": (["Select all", "Check box"], ["checked", "partial", "mixed"]),
    "f07-good-mixed-email": (["checked", "Email", "Check box"], ["not checked"]),
    "f07-good-mixed-text": (["Text message", "Check box"], ["checked"]),
    "f07-good-mixed-all-changed": (["checked", "Select all", "Check box"], ["not checked"]),
    # The group's question is an element of its own.
    "f07-good-group-contact": (["Contact me by"], ["Check box"]),
    "f07-good-group-phone": (["Phone", "Check box"], ["checked"]),
    "f07-good-group-post": (["Post", "Check box"], ["checked"]),
    # Bad examples: the defect must be audible where it can be.
    "f07-bad-unlabelled-box": (["Check box"], ["Email me"]),
    "f07-bad-unlabelled-text": (["Email me product updates"], ["Check box"]),
    "f07-bad-no-state-updates": (["Email me product updates", "Button"], ["Check box", "checked"]),
    "f07-bad-no-state-updates-changed": (["Email me product updates", "Button"], ["Check box", "checked"]),
    # Sounds like good-mixed: neither says a state.
    "f07-bad-mixed-as-unchecked-all": (["Select all", "Check box"], ["checked"]),
    "f07-bad-group-unlabelled-question": (["Contact me by"], ["Check box"]),
    "f07-bad-group-unlabelled-phone": (["Phone", "Check box"], ["checked"]),
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
    "(\"You are currently on…\"), which follows the checkbox with no name at once, the "
    "phrase Guidepup logged for that move is shown instead"
)
