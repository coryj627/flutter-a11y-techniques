"""Evidence tool registration for C02 Toggle button.

Read by tool/evidence_common.py, which says what each name means."""

ID = "C02"
TITLE = "C02 Toggle button"
ANDROID_TEST = "C02ToggleButtonTest"
IOS_TEST = "C02ToggleButtonUITests"
WEB_VO_SPEC = "c02_toggle_button_vo.spec.js"

# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be).
#
# Each control is read twice: on arriving, and again (marker "-changed")
# after focus has gone to the count, the control has been clicked once, and
# focus has come back. What TalkBack says while that happens (the count's
# live region) is logged under the stop before, so a first stop's phrases
# that must not be spoken leave out what the change itself announces.
#
# tool/talkback.py matches "on", "off", "checked" and "not checked" as
# whole sentences or parts of one, and the roles as whole sentences.
TALKBACK_EXPECT = {
    # Flutter has no pressed state (FL-200): a toggled node is a Switch,
    # read "off." and, once on, "checked. on." (FL-100).
    "c02-good-icon-button-bold": (["off", "Bold", "Switch"], ["on", "checked", "Button"]),
    "c02-good-icon-button-bold-changed": (["checked", "on", "Bold", "Switch"], ["off", "selected"]),
    # ToggleButtons sets checked: a Check box, with no state said while it
    # is not checked (FL-045). Written to fail when "not checked" is said.
    "c02-good-toggle-buttons-bold": (["Bold", "Check box"], ["checked", "Switch"]),
    "c02-good-toggle-buttons-bold-changed": (["checked", "Bold", "Check box"], ["Switch"]),
    "c02-good-toggle-buttons-italic": (["Italic", "Check box"], ["checked", "Switch"]),
    "c02-good-cupertino-mute": (["off", "Mute", "Switch"], ["on", "checked", "Button"]),
    "c02-good-cupertino-mute-changed": (["checked", "on", "Mute", "Switch"], ["off"]),
    "c02-good-custom-mute": (["off", "Mute", "Switch"], ["on", "checked", "Button"]),
    "c02-good-custom-mute-changed": (["checked", "on", "Mute", "Switch"], ["off"]),
    # Bad examples: the defect must be audible. isSelected alone: a Button
    # with no state while off, and "selected" while on (FL-201).
    "c02-bad-selected-only-bold": (["Bold", "Button"], ["off", "on", "checked", "not selected", "Switch"]),
    "c02-bad-selected-only-bold-changed": (["selected", "Bold", "Button"], ["on", "checked", "Switch"]),
    "c02-bad-no-state-mute": (["Mute", "Button"], ["off", "on", "checked", "selected", "Switch"]),
    "c02-bad-no-state-mute-changed": (["Mute", "Button"], ["off", "on", "checked", "selected", "Switch"]),
    # The state is right and the name changes with it.
    "c02-bad-label-changes-mute": (["off", "Mute", "Switch"], ["Unmute", "on", "checked"]),
    "c02-bad-label-changes-mute-changed": (["checked", "on", "Unmute", "Switch"], ["off"]),
}

# tool/talkback.py: how the speech was captured.
TALKBACK_METHOD = (
    "ACTION_ACCESSIBILITY_FOCUS on each node; speech read from TalkBack's verbose "
    "log. A \"-changed\" element is the same node read again after focus went to the "
    "change count, the node was clicked once and the count read 1, and focus came "
    "back; what is said in between is logged under the element before it"
)

# tool/voiceover_ios.py: (how the speech was captured, heading of the
# transcript column).
VOICEOVER_IOS_METHOD = (
    "`XCUIVoiceOverService.moveForward()` from the top of the screen to the "
    "change count, which is the last element of every example. What is shown "
    "is everything between the \"Example\" heading and the count. Each example "
    "is walked as it opens, and again (\"-changed\") after its first control has "
    "been tapped once with VoiceOver off; the second walk must end at "
    "\"Changes: 1\"",
    "Spoken, in swipe order",
)

# tool/voiceover_web.py: how the speech was captured.
VOICEOVER_WEB_METHOD = (
    "focus the Back button, wait until VoiceOver has been quiet for two seconds, then "
    "`voiceOver.next()` to the end of the screen. VoiceOver's last phrase and the "
    "position of its cursor are read over AppleScript after every move: a move that "
    "changes the position, or that speaks a different phrase, is a stop; two moves in "
    "a row that do neither are the end. Each example is walked as it opens, and again "
    "(\"-changed\") after its first control has been clicked once; the change count, "
    "the last element of every example, must then read \"Changes: 1\". No test is "
    "retried by Playwright; a walk that fell short is walked again by the test itself, "
    "up to three times, and a walk with a wrong reading fails the test with no further "
    "walk. Every stop of a walk is judged, the screen's own stops before the heading "
    "included. Every try is a row of its own, `<slug>-walk-<n>`, with the verdict and "
    "the stops after the \"Example\" heading for a complete walk, every stop for any other. "
    "The `control-html-walk-<n>` rows are a plain HTML page with no Flutter, each walk "
    "shown whole"
)
