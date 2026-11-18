"""Evidence tool registration for F06 Error identification and announcement.

Read by tool/evidence_common.py, which says what each name means."""

ID = "F06"
TITLE = "F06 Error identification and announcement"
ANDROID_TEST = "F06ErrorIdentificationTest"
IOS_TEST = "F06ErrorIdentificationUITests"
WEB_VO_SPEC = "f06_error_identification_vo.spec.js"

_NAME = "Enter your name."
_EMAIL = "Enter an email address with an @"

# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be). "<example>-send" is TalkBack on Send; "<example>-sent" is
# everything said in the seven seconds after Send was pressed with TalkBack
# focus on it; the rest are each field and error with focus forced onto it,
# which shows what is said, not the order of a swipe.
TALKBACK_EXPECT = {
    # Both errors are live regions on Android, and both are announced; then
    # focus reaches Name, which TalkBack reads with its error.
    "f06-good-form-send": (["Send", "Button"], []),
    "f06-good-form-sent": ([_NAME, _EMAIL, "Edit box"], []),
    "f06-good-form-name": (["Name", _NAME, "Edit box"], []),
    "f06-good-form-name-error": ([_NAME], ["Edit box"]),
    "f06-good-form-email": (["Email", _EMAIL, "Edit box"], []),
    # A field in error that has a value is read as its value alone: the
    # label and the error are in the hint text, which TalkBack does not read
    # once there is a value (FL-015). Written to fail when it starts to.
    "f06-good-form-email-filled": (["abc", "Edit box"], [_EMAIL, "Email"]),
    "f06-good-cupertino-send": (["Send", "Button"], []),
    "f06-good-cupertino-sent": ([_NAME, _EMAIL, "Edit box"], []),
    "f06-good-cupertino-name": (["Name", _NAME, "Edit box"], []),
    "f06-good-cupertino-name-error": ([_NAME], ["Edit box"]),
    # Bad examples. Every "-sent" entry must have speech: focus moves to the
    # field, or the error is announced, so an empty capture fails.
    "f06-bad-color-only-send": (["Send", "Button"], []),
    "f06-bad-color-only-sent": (["Email", "Edit box"], ["Enter", "Invalid"]),
    "f06-bad-color-only-email": (["Email", "Edit box"], ["Enter", "Invalid"]),
    "f06-bad-vague-message-send": (["Send", "Button"], []),
    "f06-bad-vague-message-sent": (["Invalid.", "Edit box"], [_EMAIL]),
    "f06-bad-vague-message-email": (["Email", "Invalid.", "Edit box"], [_EMAIL]),
    # The defect is on iOS and the web; on Android the error text is a live
    # region and is announced. Focus stays on Send.
    "f06-bad-not-announced-send": (["Send", "Button"], []),
    "f06-bad-not-announced-sent": ([_EMAIL], ["Edit box"]),
    "f06-bad-not-announced-email": (["Email", _EMAIL, "Edit box"], []),
    "f06-bad-merged-error-send": (["Send", "Button"], []),
    "f06-bad-merged-error-sent": ([_EMAIL], []),
    "f06-bad-merged-error-email": (["Email", _EMAIL, "Edit box"], []),
}

TALKBACK_METHOD = (
    "TalkBack focus on Send, then ACTION_CLICK on Send and everything TalkBack says for "
    "seven seconds; then the keyboard is closed and ACTION_ACCESSIBILITY_FOCUS is put on each "
    "field and error in turn, which shows what is spoken and not the order of a swipe. "
    "Speech is read from TalkBack's verbose log"
)

VOICEOVER_IOS_METHOD = (
    "the VoiceOver cursor is put on Send and Send is activated with a double tap; every new "
    "utterance of `XCUIVoiceOverService.currentSpeech()` in the next eight seconds is "
    "recorded, then the cursor is moved forward once and back once, which reads the element "
    "it was on. The example must show that Send acted. Utterances are the first 64 characters",
    "Spoken: on Send / after activation / forward / back",
)

VOICEOVER_WEB_METHOD = (
    "keyboard focus on Send, then Enter (Space for the Cupertino button), and VoiceOver's last "
    "phrase is polled over AppleScript for eight seconds; then the cursor is moved once each "
    "way to read where it is. Chromium only: Playwright's WebKit build passes no live region "
    "or announcement to VoiceOver (I12). Silence is checked with the capture proven live"
)
