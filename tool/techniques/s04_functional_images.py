"""Evidence tool registration for S04 Functional images.

Read by tool/evidence_common.py, which says what each name means."""

ID = "S04"
TITLE = "S04 Functional images"
ANDROID_TEST = "S04FunctionalImagesTest"
IOS_TEST = "S04FunctionalImagesUITests"
WEB_VO_SPEC = "s04_functional_images_vo.spec.js"

# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be).
TALKBACK_EXPECT = {
    # S04 Functional images. A good image control is read as a named button
    # and never as an image.
    "s04-good-image-button-guide": (["Open trail guide", "Button"], ["Image"]),
    "s04-good-icon-label-search": (["Search", "Button"], ["Image"]),
    "s04-good-image-with-text-guide": (["Trail guide", "Button"], ["Image"]),
    "s04-good-image-with-text-print": (["Print", "Button"], ["Image"]),
    "s04-good-cupertino-search": (["Search", "Button"], ["Image"]),
    "s04-good-custom-guide": (["Open trail guide", "Button"], ["Image"]),
    "s04-good-image-regions-west": (["West trail", "Button"], ["Image"]),
    "s04-good-image-regions-east": (["East trail", "Button"], ["Image"]),
    # Bad examples: the defect must be audible.
    "s04-bad-no-name-guide": (["Button"], ["Open trail guide"]),
    # The name is on the image inside the button, a second stop.
    "s04-bad-label-on-image-button": (["Button"], ["Open trail guide"]),
    "s04-bad-label-on-image-image": (["Open trail guide", "Image"], ["Button"]),
    # The node that takes the tap has no name and no role. TalkBack said
    # "Button" for it in two recordings and nothing in a third, so only the
    # missing name is checked. The name is on the image inside it.
    "s04-bad-tap-gesture-tappable": ([], ["Open trail guide"]),
    "s04-bad-tap-gesture-image": (["Open trail guide", "Image"], ["Button"]),
    "s04-bad-describes-picture-search": (["Magnifying glass", "Button"], []),
    # The node's class is ImageView, but TalkBack reads it as a button and
    # does not say "Image": on Android this defect is in the tree only.
    # Written to fail if TalkBack starts saying "Image".
    "s04-bad-image-not-excluded-guide": (["Trail guide", "Button"], ["Image"]),
    "s04-bad-redundant-label-print": (["Printer", "Print", "Button"], []),
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
