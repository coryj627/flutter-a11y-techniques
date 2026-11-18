"""Evidence tool registration for F09 Switch.

Read by tool/evidence_common.py, which says what each name means."""

ID = "F09"
TITLE = "F09 Switch"
ANDROID_TEST = "F09SwitchTest"
IOS_TEST = "F09SwitchUITests"
WEB_VO_SPEC = "f09_switch_vo.spec.js"

# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be).
TALKBACK_EXPECT = {
    # F09 Switch. TalkBack says the state first, as its own sentence: "off."
    # or "on.", then the name and "Switch". tool/talkback.py matches "on",
    # "off" and "checked" as whole sentences, so "on" in a name such as
    # "Bluetooth on" does not count. For a switch that is on it says
    # "checked." as well, which it does not say for a native switch
    # (FL-100). Written to fail when "checked." stops being spoken.
    "f09-good-tile-bluetooth": (["off", "Bluetooth", "Switch"], ["on", "checked"]),
    "f09-good-tile-bluetooth-changed": (["checked", "on", "Bluetooth", "Switch"], ["off"]),
    "f09-good-cupertino-bluetooth": (["off", "Bluetooth", "Switch"], ["on", "checked"]),
    "f09-good-cupertino-bluetooth-changed": (["checked", "on", "Bluetooth", "Switch"], ["off"]),
    "f09-good-custom-bluetooth": (["off", "Bluetooth", "Switch"], ["on", "checked"]),
    "f09-good-custom-bluetooth-changed": (["checked", "on", "Bluetooth", "Switch"], ["off"]),
    # The group's question is an element of its own.
    "f09-good-group-notify": (["Notify me about"], ["Switch"]),
    "f09-good-group-messages": (["off", "Messages", "Switch"], ["on", "checked"]),
    "f09-good-group-reminders": (["off", "Reminders", "Switch"], ["on", "checked"]),
    # Bad examples: the defect must be audible where it can be.
    "f09-bad-unlabelled-switch": (["off", "Switch"], ["Bluetooth"]),
    "f09-bad-unlabelled-text": (["Bluetooth"], ["Switch"]),
    # The row is a button with no state, before and after it is used, and
    # the switch inside it has no name.
    "f09-bad-tile-not-merged-tile": (["Bluetooth", "Button"], ["Switch", "off", "on"]),
    "f09-bad-tile-not-merged-switch": (["off", "Switch"], ["Bluetooth"]),
    "f09-bad-tile-not-merged-tile-changed": (["Bluetooth", "Button"], ["Switch", "off", "on"]),
    # The name says the state, so the state is heard twice, and the name
    # is different after a change.
    "f09-bad-label-changes-bluetooth": (["off", "Bluetooth off", "Switch"], ["Bluetooth on"]),
    "f09-bad-label-changes-bluetooth-changed": (["checked", "on", "Bluetooth on", "Switch"], ["Bluetooth off"]),
    "f09-bad-no-state-bluetooth": (["Bluetooth", "Button"], ["Switch", "off", "on"]),
    "f09-bad-no-state-bluetooth-changed": (["Bluetooth", "Button"], ["Switch", "off", "on"]),
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
    "(\"You are currently on…\"), which follows a switch with no name at once, the "
    "phrase Guidepup logged for that move is shown instead"
)
