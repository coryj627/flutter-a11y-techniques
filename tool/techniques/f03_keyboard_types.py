"""Evidence tool registration for F03 Keyboard types.

Read by tool/evidence_common.py, which says what each name means."""

ID = "F03"
TITLE = "F03 Keyboard types"
ANDROID_TEST = "F03KeyboardTypesTest"
IOS_TEST = "F03KeyboardTypesUITests"
WEB_VO_SPEC = "f03_keyboard_types_vo.spec.js"

# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be).
TALKBACK_EXPECT = {
    # F03 Keyboard types. TalkBack reads a field's name and "Edit box"; the
    # keyboard a field asks for and its autofill hint are not spoken, so a
    # bad example sounds like a good one.
    "f03-good-contact-name": (["Name", "Edit box"], []),
    "f03-good-contact-email": (["Email", "Edit box"], []),
    "f03-good-contact-phone": (["Phone", "Edit box"], []),
    "f03-good-amount-amount": (["Amount", "Edit box"], []),
    "f03-good-cupertino-email": (["Email", "Edit box"], []),
    "f03-good-cupertino-phone": (["Phone", "Edit box"], []),
    "f03-good-sign-in-username": (["Username", "Edit box"], []),
    # The password flag is spoken as its own "password", after the name and
    # before the role: "Password", "password. Edit box". The phrase is
    # matched with the role so that the name alone cannot pass it.
    "f03-good-sign-in-password": (["Password", "password. Edit box", "Edit box"], []),
    # The password with "abc" typed: the length is read, never the text.
    "f03-good-sign-in-password-filled": (["password. 3 characters", "Edit box"], ["abc"]),
    "f03-bad-number-for-name-name": (["Name", "Edit box"], []),
    "f03-bad-default-keyboard-email": (["Email", "Edit box"], []),
    "f03-bad-no-purpose-name": (["Name", "Edit box"], []),
    "f03-bad-email-no-suggestions-email": (["Email", "Edit box"], []),
}

# tool/voiceover_ios.py: (how the speech was captured, heading of the
# transcript column).
VOICEOVER_IOS_METHOD = (
    "`XCUIVoiceOverService.moveForward()` from the top of the screen to the "
    "change count, which is the last element of every example. What is shown "
    "is everything between the \"Example\" heading and the count. The "
    "`good-sign-in+editing` row is the password while it is being edited, with "
    "\"abc\" typed: one move forward from it, then one back to it",
    "Spoken, in swipe order",
)

# tool/voiceover_web.py: how the speech was captured.
VOICEOVER_WEB_METHOD = (
    "focus the Back button, wait until VoiceOver has been quiet for two seconds, "
    "then `voiceOver.next()` to the end of the screen, reading VoiceOver's last "
    "phrase and cursor after every move; every stop between the \"Example\" heading "
    "and the change count is shown. VoiceOver's cursor moving onto a field also "
    "focuses it, so each field is read as it is while focused"
)
