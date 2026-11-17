"""Evidence tool registration for S13 Roles and traits.

Read by tool/evidence_common.py, which says what each name means."""

ID = "S13"
TITLE = "S13 Roles and traits"
ANDROID_TEST = "S13RolesAndTraitsTest"
IOS_TEST = "S13RolesAndTraitsUITests"
WEB_VO_SPEC = "s13_roles_and_traits_vo.spec.js"

# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be).
TALKBACK_EXPECT = {
    # S13 Roles and traits. Each control is read with the role that matches
    # what it does, and TalkBack offers "Double-tap to activate" only where
    # the node has a click action.
    "s13-good-standard-save": (["Save", "Button", "Double-tap to activate"], []),
    "s13-good-standard-wifi": (["Wi-Fi", "Switch"], ["Button"]),
    "s13-good-standard-remember": (["Remember me", "Check box"], ["Switch"]),
    "s13-good-cupertino-save": (["Save", "Button", "Double-tap to activate"], []),
    "s13-good-cupertino-wifi": (["Wi-Fi", "Switch"], ["Button"]),
    "s13-good-custom-button-scan": (["Scan barcode", "Button", "Double-tap to activate"], []),
    "s13-good-custom-switch-dark": (["Dark mode", "Switch"], ["Button", "Disabled"]),
    "s13-good-selected-day": (["Day", "Button"], ["Selected"]),
    "s13-good-selected-week": (["Selected", "Week", "Button"], []),
    "s13-good-selected-month": (["Month", "Button"], ["Selected"]),
    # Bad examples: the defect must be audible.
    "s13-bad-no-role-scan": (["Scan barcode"], ["Button"]),
    "s13-bad-wrong-role-dark": (["Dark mode", "Button"], ["Switch"]),
    "s13-bad-role-on-text-delivery": (["Free delivery", "Button"], ["Double-tap to activate"]),
    # The added role is a node of its own with no name. TalkBack said
    # "Button" for it; only the missing name is checked (see S04).
    "s13-bad-role-on-standard-outer": ([], ["Save"]),
    "s13-bad-role-on-standard-save": (["Save", "Button"], []),
    "s13-bad-action-hidden-scan": (["Scan barcode", "Button"], ["Double-tap to activate"]),
    # The defect is on iOS only: on Android this is an ordinary switch.
    "s13-bad-switch-not-enabled-dark": (["Dark mode", "Switch"], ["Disabled"]),
}

# tool/voiceover_ios.py: (how the speech was captured, heading of the
# transcript column).
VOICEOVER_IOS_METHOD = (
    "`XCUIVoiceOverService.moveForward()` from the top of the screen to the "
    "activation count, which is the last element of every example. What is shown "
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
    "the end. The activation count is the last element of every example"
)
