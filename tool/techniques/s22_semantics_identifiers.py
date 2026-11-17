"""Evidence tool registration for S22 Semantics identifiers for testing.

Read by tool/evidence_common.py, which says what each name means."""

ID = "S22"
TITLE = "S22 Semantics identifiers for testing"
ANDROID_TEST = "S22SemanticsIdentifiersTest"
IOS_TEST = "S22SemanticsIdentifiersUITests"
WEB_VO_SPEC = "s22_semantics_identifiers_vo.spec.js"

# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be).
TALKBACK_EXPECT = {
    # S22 Semantics identifiers for testing. The identifier is the node's
    # resource id and must not be read; the words in each second list are
    # words from the identifier.
    "s22-good-merged-save": (["Save draft", "Button"], ["s22", "merged", "good"]),
    "s22-good-cupertino-save": (["Save draft", "Button"], ["s22", "cupertino", "good"]),
    "s22-good-custom-save": (["Save draft", "Button"], ["s22", "custom", "good"]),
    "s22-good-field-project": (["Project name", "Edit box"], ["s22", "field", "good"]),
    # Bad examples. The button has no name (FL-007); its text is read as a
    # separate element.
    "s22-bad-inside-button": (["Button"], ["Save draft", "s22", "inside"]),
    "s22-bad-inside-save": (["Save draft"], ["Button", "s22", "inside"]),
    # Nothing is different for a TalkBack user here.
    "s22-bad-wrapper-button": (["Save draft", "Button"], ["s22", "wrapper"]),
    # The identifier is not a name.
    "s22-bad-id-as-name-close": (["Button"], ["s22", "close", "name"]),
    "s22-bad-duplicate-save": (["Save draft", "Button"], ["s22", "duplicate", "action"]),
    "s22-bad-duplicate-discard": (["Discard draft", "Button"], ["s22", "duplicate", "action"]),
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
    "focus the Back button, wait until VoiceOver has been quiet for two seconds, then `voiceOver.next()` to the end of the screen. "
    "VoiceOver's last phrase and the position of its cursor are read over "
    "AppleScript after every move: a move that changes the position, or that "
    "speaks a different phrase, is a stop; two moves in a row that do neither are "
    "the end. The activation count is the last element of every example. Where VoiceOver's last phrase is its own help message for a "
    "text field (\"You are currently on…\"), the phrase Guidepup logged for that "
    "move is shown instead"
)
