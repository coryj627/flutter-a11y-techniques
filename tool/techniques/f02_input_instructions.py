"""Evidence tool registration for F02 Input instructions.

Read by tool/evidence_common.py, which says what each name means."""

ID = "F02"
TITLE = "F02 Input instructions"
ANDROID_TEST = "F02InputInstructionsTest"
IOS_TEST = "F02InputInstructionsUITests"
WEB_VO_SPEC = "f02_input_instructions_vo.spec.js"

# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be).
TALKBACK_EXPECT = {
    # F02 Input instructions. Flutter puts a field's label and hint into
    # Android's hint text ("Username, 4 to 10 characters, no spaces."), which
    # TalkBack reads with an empty field. Ids ending in -filled are read
    # after "abc" was typed; ids ending in -rule are the instruction as text
    # on the screen. "Edit box" is matched as a sentence of its own.
    "f02-good-helper-username": (["Username", "4 to 10 characters, no spaces", "Edit box"], []),
    # Once the field has a value TalkBack reads neither its name nor the
    # instruction (FL-015). Written to fail when either starts being spoken.
    "f02-good-helper-username-filled": (["abc", "Edit box"], ["Username", "4 to 10"]),
    # The helper text is still there to be read, as text of its own.
    "f02-good-helper-rule": (["4 to 10 characters, no spaces"], ["Edit box", "Username"]),
    "f02-good-cupertino-username": (["Username", "4 to 10 characters, no spaces", "Edit box"], []),
    "f02-good-cupertino-rule": (["4 to 10 characters, no spaces"], ["Edit box", "Username"]),
    "f02-good-before-rule": (["4 to 10 characters, no spaces"], ["Edit box", "Username"]),
    "f02-good-before-username": (["Username", "4 to 10 characters, no spaces", "Edit box"], []),
    # Bad examples: the defect must be audible.
    # The field is read without the instruction, empty or filled.
    "f02-bad-helper-only-username": (["Username", "Edit box"], ["4 to 10"]),
    "f02-bad-helper-only-username-filled": (["abc", "Edit box"], ["Username", "4 to 10"]),
    "f02-bad-helper-only-rule": (["4 to 10 characters, no spaces"], ["Edit box", "Username"]),
    # The format is not in the field until it is being edited.
    "f02-bad-placeholder-format-birthday": (["Date of birth", "Edit box"], ["DD/MM"]),
    # The cut is on the screen only: TalkBack reads the whole instruction.
    "f02-bad-helper-cut-off-name": (["Display name", "Shown on your posts", "2 to 30 letters or numbers", "Edit box"], []),
    "f02-bad-helper-cut-off-rule": (["Shown on your posts", "2 to 30 letters or numbers"], ["Edit box"]),
}

# tool/voiceover_ios.py: (how the speech was captured, heading of the
# transcript column).
VOICEOVER_IOS_METHOD = (
    "`XCUIVoiceOverService.moveForward()` from the top of the screen to the "
    "change count, which is the last element of every example. What is shown "
    "is everything between the \"Example\" heading and the count; a move at which "
    "VoiceOver said nothing is shown as \"(no speech)\" only when one move back "
    "read the element before it and the move forward again was silent too, which "
    "shows the cursor was on an element of its own. A walk marked +filled was "
    "made after \"abc\" had been typed into the field and Return pressed",
    "Spoken, in swipe order",
)

# tool/voiceover_web.py: how the speech was captured.
VOICEOVER_WEB_METHOD = (
    "focus the Back button, wait until VoiceOver has been quiet for two seconds, then "
    "`voiceOver.next()` to the end of the screen. VoiceOver's last phrase and the "
    "position of its cursor are read over AppleScript after every move: a move that "
    "changes the position, or that speaks a different phrase, is a stop; two moves in "
    "a row that do neither are the end. The change count is the last element of every "
    "example. A walk marked +filled was made after \"abc\" had been typed into the "
    "field. Where VoiceOver's last phrase is its own help message for a text field "
    "(\"You are currently on…\"), which follows a described field at once, the phrase "
    "Guidepup logged for that move is shown instead"
)
