"""Evidence tool registration for S03 Decorative images.

Read by tool/evidence_common.py, which says what each name means."""

ID = "S03"
TITLE = "S03 Decorative images"
ANDROID_TEST = "S03DecorativeImagesTest"
IOS_TEST = "S03DecorativeImagesUITests"
WEB_VO_SPEC = "s03_decorative_images_vo.spec.js"

# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be).
TALKBACK_EXPECT = {
    # S03 Decorative images. Decoration is not read; where it is left in,
    # TalkBack has only "Unlabelled" and the role to say.
    "s03-good-image-excluded-first": (["Welcome back, Ana"], ["Image"]),
    "s03-good-image-excluded-second": (["You have 2 new messages"], ["Image"]),
    "s03-good-icon-no-label-shipping": (["Shipping"], ["Image"]),
    "s03-good-icon-no-label-returns": (["Returns"], ["Image"]),
    "s03-good-background-image-first": (["Welcome back, Ana"], ["Image"]),
    "s03-good-background-image-second": (["You have 2 new messages"], ["Image"]),
    "s03-good-exclude-semantics-name": (["Ana Kovac"], ["AK"]),
    "s03-good-merged-row-row": (["Trail guide", "12 routes"], ["Image"]),
    "s03-bad-not-excluded-banner": (["Unlabelled", "Image"], []),
    "s03-bad-empty-label-banner": (["Unlabelled", "Image"], []),
    "s03-bad-redundant-label-icon": (["Shipping"], []),
    "s03-bad-redundant-label-word": (["Shipping"], []),
    "s03-bad-merged-image-row": (["Trail guide", "12 routes", "Image"], []),
}

# tool/voiceover_ios.py: (how the speech was captured, heading of the
# transcript column).
VOICEOVER_IOS_METHOD = (
    "`XCUIVoiceOverService.moveForward()` until the same utterance is heard four "
    "times in a row, then `moveBackward()` to the \"Example\" heading. The walk back "
    "gives each element of the example once and shows that the walk forward had "
    "reached the end of the screen",
    "Spoken, in swipe order",
)

# tool/voiceover_web.py: how the speech was captured.
VOICEOVER_WEB_METHOD = (
    "focus the Back button, then `voiceOver.next()` to the end of the screen. "
    "VoiceOver's last phrase and the position of its cursor are read over "
    "AppleScript after every move: a move that changes the position, or that "
    "speaks a different phrase, is a stop; two moves in a row that do neither are "
    "the end"
)
