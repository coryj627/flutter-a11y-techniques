"""Evidence tool registration for I12 Announcements and live regions.

Read by tool/evidence_common.py, which says what each name means."""

ID = "I12"
TITLE = "I12 Announcements and live regions"
ANDROID_TEST = "I12AnnouncementsTest"
IOS_TEST = "I12AnnouncementsUITests"
WEB_VO_SPEC = "i12_announcements_vo.spec.js"

# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be).
TALKBACK_EXPECT = {
    # I12 Announcements. Each entry is what TalkBack said after the example's
    # button was pressed, with focus parked elsewhere.
    "i12-good-live-region-announced": (["1 item in cart"], []),
    # On Android this example falls back to a live region.
    "i12-good-announce-announced": (["Link copied"], []),
    # The same button pressed a second time.
    "i12-good-announce-announced-again": (["Link copied"], []),
    "i12-good-snackbar-announced": (["Message archived"], []),
    # Bad examples.
    "i12-bad-silent-update-announced": ([], ["item in cart"]),
    "i12-bad-chatty-live-region-announced": (
        ["Uploading: 1 seconds", "Uploading: 2 seconds", "Uploading: 3 seconds"], []),
    # Flutter limitations FL-017 and FL-018: silent on Android. Written to
    # fail when TalkBack starts announcing them.
    "i12-bad-status-role-only-announced": ([], ["item in cart"]),
    "i12-bad-alert-role-only-announced": ([], ["Could not save"]),
}

# tool/talkback.py: how the speech was captured.
TALKBACK_METHOD = (
    "ACTION_CLICK on each example's button with TalkBack focus left elsewhere; "
    "what TalkBack then announced is read from its verbose log"
)

# tool/voiceover_ios.py: (how the speech was captured, heading of the
# transcript column).
VOICEOVER_IOS_METHOD = (
    "the VoiceOver cursor is put on the example's button, the button is activated "
    "with a double tap, and `XCUIVoiceOverService.currentSpeech()` is read until the "
    "message is heard, or for four seconds after the visible change when nothing "
    "should be said. The message must be on screen first. The cursor is then moved "
    "back and forward once, which must land on the button again, to show that the "
    "message was announced and not reached by a moved cursor",
    "Spoken: on the button / after it is activated / after one step back and forward",
)

# tool/voiceover_web.py: how the speech was captured.
VOICEOVER_WEB_METHOD = (
    "press the example's button with the keyboard, then poll VoiceOver's last phrase "
    "over AppleScript for what it was given to announce; Chromium only, because "
    "Playwright's WebKit build passes no live region changes to VoiceOver"
)
