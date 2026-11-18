"""Evidence tool registration for F10 Slider.

Read by tool/evidence_common.py, which says what each name means."""

ID = "F10"
TITLE = "F10 Slider"
ANDROID_TEST = "F10SliderTest"
IOS_TEST = "F10SliderUITests"
WEB_VO_SPEC = "f10_slider_vo.spec.js"

# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be).
TALKBACK_EXPECT = {
    # F10 Slider. TalkBack reads the value, the name, and "Slider"; after an
    # increase the slider is focused again and must say the new value.
    "f10-good-material-volume": (["40%", "Volume", "Slider"], []),
    "f10-good-material-volume-changed": (["50%", "Volume", "Slider"], ["40%"]),
    "f10-good-cupertino-volume": (["40%", "Volume", "Slider"], []),
    "f10-good-cupertino-up": (["Volume up", "Button"], ["Slider"]),
    "f10-good-custom-volume": (["40%", "Volume", "Slider"], []),
    "f10-good-custom-volume-changed": (["50%", "Volume", "Slider"], ["40%"]),
    "f10-good-value-text-rating": (["4 out of 10", "Rating", "Slider"], ["%"]),
    "f10-good-value-text-rating-changed": (["5 out of 10", "Rating", "Slider"], ["%"]),
    # Bad examples: the defect must be audible where it can be.
    "f10-bad-unlabelled-text": (["Volume"], ["Slider"]),
    "f10-bad-unlabelled-volume": (["40%", "Slider"], ["Volume"]),
    # The number above the thumb is read as part of the name.
    "f10-bad-indicator-label-volume": (["40%", "Volume 4", "Slider"], []),
    "f10-bad-indicator-label-volume-changed": (["50%", "Volume 5", "Slider"], ["Volume 4"]),
    "f10-bad-percent-value-rating": (["40%", "Rating", "Slider"], ["out of 10"]),
    "f10-bad-percent-value-rating-changed": (["50%", "Rating", "Slider"], ["out of 10"]),
    # The keyboard and pointer defects are not heard: a screen reader reads
    # and adjusts these sliders correctly.
    "f10-bad-no-keyboard-volume": (["40%", "Volume", "Slider"], []),
    "f10-bad-drag-only-volume": (["40%", "Volume", "Slider"], []),
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
    "click the \"Example\" heading with the mouse at its position (a Material slider "
    "puts an empty element over the page, FL-029), focus the Back button, wait until "
    "VoiceOver has been quiet for two seconds, then `voiceOver.next()` until the "
    "change count is read. In the WebKit build the walks of the five screens with a "
    "Material slider leave the page: they pass only if VoiceOver read the Back button "
    "before the walk, then reads at most the title and after it only the page's web "
    "area (\"<title> web content\"), and reads Back again when it is focused after the "
    "walk. Before every WebKit walk VoiceOver must read Back when it is focused. The "
    "`plain-` rows are a control: plain HTML in the shape Flutter gives a slider, "
    "enabled and disabled, and a range input with its own label"
)
