"""Evidence tool registration for S15 Hints.

Read by tool/evidence_common.py, which says what each name means."""

ID = "S15"
TITLE = "S15 Hints"
ANDROID_TEST = "S15HintsTest"
IOS_TEST = "S15HintsUITests"
WEB_VO_SPEC = "s15_hints_vo.spec.js"

# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be).
TALKBACK_EXPECT = {
    # S15 Hints. Android has no hint of its own: the hint is the end of the
    # description, so it is read straight after the name, before the role.
    "s15-good-result-favorite": (["Favorite", "Adds this item to your favorites", "Button"], []),
    "s15-good-row-song": (["Night Ferry", "The Lanterns", "Plays the song", "Button"], []),
    "s15-good-cupertino-share": (["Share", "Shares the current page", "Button"], []),
    "s15-good-custom-archive": (["Archive", "Moves this message out of the inbox", "Button"], []),
    "s15-good-field-username": (["Username", "3 to 12 letters or numbers"], []),
    # Once the field has text TalkBack reads neither its name nor its hint
    # (FL-015). Written to fail when either starts being spoken.
    "s15-good-field-username-filled": (["abc", "Edit box"], ["Username", "3 to 12"]),
    "s15-good-field-rule": (["3 to 12 letters or numbers"], ["Username"]),
    # Bad examples: the defect must be audible.
    # TalkBack's own "Double-tap to activate" follows after a pause and is
    # not always inside the listening window, so it is not required.
    "s15-bad-gesture-favorite": (["Favorite", "Double tap to add this item", "Button"], []),
    # "Delete" twice, as two fragments with TalkBack's pause between them.
    "s15-bad-repeats-label-delete": (["delete, |   | delete", "Button"], []),
    "s15-bad-control-type-share": (["Share", "This button shares the current page", "Button"], []),
    "s15-bad-no-hint-song": (["Night Ferry", "The Lanterns", "Button"], ["Plays"]),
    # The hint is an element of its own, and the button has none (FL-040).
    "s15-bad-hint-detached-hint": (["Adds this item to your favorites"], ["Button"]),
    "s15-bad-hint-detached-favorite": (["Favorite", "Button"], ["Adds this item"]),
    # Read as the good field is: the tree test finds no rule on the screen.
    "s15-bad-hint-only-username": (["Username", "3 to 12 letters or numbers"], []),
    "s15-bad-hint-only-username-filled": (["abc", "Edit box"], ["Username", "3 to 12"]),
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
    "focus the Back button, then `voiceOver.next()` to the end of the screen. "
    "VoiceOver's last phrase and the position of its cursor are read over "
    "AppleScript after every move: a move that changes the position, or that "
    "speaks a different phrase, is a stop; two moves in a row that do neither are "
    "the end. The activation count is the last element of every example. Where VoiceOver's last phrase is its own help message for a "
    "text field (\"You are currently on…\"), which follows a described field at "
    "once, the phrase Guidepup logged for that move is shown instead"
)
