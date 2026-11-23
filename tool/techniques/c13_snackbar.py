"""Evidence tool registration for C13 Snackbar and transient messages.

Read by tool/evidence_common.py, which says what each name means."""

ID = "C13"
TITLE = "C13 Snackbar and transient messages"
ANDROID_TEST = "C13SnackbarTest"
IOS_TEST = "C13SnackbarUITests"
WEB_VO_SPEC = "c13_snackbar_vo.spec.js"

_ACTIVATE = "Double-tap to activate"

# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be). "-announced" is what TalkBack said after the example's
# button was pressed with the click action, with TalkBack focus parked on
# the example's line; the others are TalkBack focus moved to the message's
# own nodes.
TALKBACK_EXPECT = {
    "c13-good-action-announced": (["Message archived"], []),
    "c13-good-action-message": (["Message archived"], ["Undo"]),
    "c13-good-action-undo": (["Undo", "Button"], ["Message archived"]),
    "c13-good-action-close": (["Close", "Button"], []),
    "c13-good-message-announced": (["Draft saved"], []),
    "c13-good-banner-announced": (["You are offline."], []),
    "c13-good-banner-message": (["You are offline."], ["Go online"]),
    "c13-good-banner-go-online": (["Go online", "Button"], []),
    # The defects of these two are in time, not in what is said.
    "c13-bad-action-times-out-announced": (["Message archived"], []),
    "c13-bad-only-in-message-announced": (["Booked. Code: K7Q2"], []),
    # FL-295: a banner put in the page is not announced; focus moved to it
    # reads it, so its words are there to be found.
    "c13-bad-inline-banner-announced": ([], ["offline"]),
    "c13-bad-inline-banner-message": (["You are offline."], []),
    # What the action did, told by a SnackBar of its own: focus parked on
    # the line again, the action pressed with the click action. For
    # bad-inline-banner this is also the positive control of its silence.
    "c13-good-action-done-announced": (["Archive undone"], []),
    "c13-good-banner-done-announced": (["You are online."], []),
    "c13-bad-inline-banner-done-announced": (["You are online."], []),
}

# tool/talkback.py: how the speech was captured.
TALKBACK_METHOD = (
    "TalkBack focus parked on the example's line, the example's button pressed "
    "with ACTION_CLICK, and what TalkBack then announced read from its verbose "
    "log (`-announced`); then, for the messages that stay, TalkBack focus moved "
    "to each of the message's nodes; then focus parked on the line again and the "
    "message's action (Undo, Go online) pressed with ACTION_CLICK (`-done-announced`)"
)

# tool/voiceover_ios.py: (how the speech was captured, heading of the
# transcript column).
VOICEOVER_IOS_METHOD = (
    "the VoiceOver cursor is put on the example's button with `tap()`, the "
    "button is pressed with `doubleTap()` at its place (which acts on what is "
    "under the tap; VoiceOver's own activation was not measured), and "
    "`XCUIVoiceOverService.currentSpeech()` is read until the message is heard, "
    "or for six seconds when nothing should be said; one move back and one "
    "forward must land on the button again. For the messages that stay, the "
    "cursor is then moved forward from the button to the end of the screen; then put "
    "on the message's action (Undo, Go online), which is pressed with `doubleTap()` at "
    "its place, and the SnackBar that tells what it did must be heard",
    "Spoken: on the button / after the tap at it / back and forward / moves forward / "
    "on the action / after the tap at it",
)

# tool/voiceover_web.py: how the speech was captured.
VOICEOVER_WEB_METHOD = (
    "keyboard focus on the example's button, Enter pressed, and VoiceOver's last "
    "phrase polled over AppleScript for six seconds (`-announced`, Chromium only: "
    "Playwright's WebKit build passes no live region changes to VoiceOver). For "
    "the messages that stay, the screen is then walked from Back with "
    "`voiceOver.next()` to its end, every stop judged against the whole screen "
    "in order (web_tests/vo/c13_vo_walks.js); a wrong stop fails for good, and "
    "only a walk cut short with every stop right so far is walked again, up to "
    "three walks, each shown as its own row (`-walk-<n>`). No runner retries. After "
    "the announcements of the examples with an action, keyboard focus on the "
    "message's action and Enter: what it did must be heard (`-done-announced`)"
)
