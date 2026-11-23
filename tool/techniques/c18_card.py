"""Evidence tool registration for C18 Card.

Read by tool/evidence_common.py, which says what each name means."""

ID = "C18"
TITLE = "C18 Card"
ANDROID_TEST = "C18CardTest"
IOS_TEST = "C18CardUITests"
WEB_VO_SPEC = "c18_card_vo.spec.js"

_TRAIL = "Ridge trail"
_TEXT = "A 6 km climb with a view."
_PICTURE = "Sunrise over the valley"
_ACTIVATE = "Double-tap to activate"


def _parts(slug):
    """A card's heading, text, and picture, each read on its own."""
    return {
        f"c18-{slug}-heading": ([_TRAIL, "Heading"], ["A 6 km", "Button", _ACTIVATE]),
        f"c18-{slug}-text": ([_TEXT], [_TRAIL, "Heading", "Button", _ACTIVATE]),
        f"c18-{slug}-picture": ([_PICTURE, "Image"], [_TRAIL, "Heading", "Button"]),
    }


# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be).
TALKBACK_EXPECT = {
    **_parts("good-material"),
    # TalkBack's usage hint ("Double-tap to activate") is not required on a
    # button: in the probe it was heard for most buttons and not for a
    # ListTile's within the dwell (docs/evidence/probes/c18/android-talkback.md,
    # p05), so its absence is not a defect here.
    "c18-good-material-save": ([f"Save {_TRAIL}", "Button"], ["Heading", _TEXT]),
    "c18-good-material-share": ([f"Share {_TRAIL}", "Button"], ["Heading", _TEXT]),
    # One control, named by its title and its text, and not a heading.
    "c18-good-tappable-card": ([_TRAIL, _TEXT, "Button"], ["Heading"]),
    **_parts("good-cupertino"),
    # Bad examples: the defect must be audible where Android shows it. The
    # heading and the text are one heading.
    "c18-bad-default-container-card": ([_TRAIL, _TEXT, "Heading"], ["Button", _ACTIVATE]),
    "c18-bad-default-container-save": ([f"Save {_TRAIL}", "Button"], [_TEXT]),
    # Android keeps both roles; the defect is the web's (FL-268).
    "c18-bad-heading-button-card": ([_TRAIL, _TEXT, "Heading", "Button"], []),
    # No role: only the usage hint gives it away (FL-401).
    "c18-bad-ink-well-card": ([_TRAIL, _TEXT, _ACTIVATE], ["Button", "Heading"]),
    **{k: v for k, v in _parts("bad-read-more").items() if not k.endswith("-picture")},
    # The link says "Read more", and nothing more: not the trail. Its tap
    # hint, "Double-tap to open link", is C03's.
    "c18-bad-read-more-link": (["Read more", "Double-tap to open link"], [_TRAIL, "Button"]),
}

# tool/voiceover_ios.py: (how the speech was captured, heading of the
# transcript column).
VOICEOVER_IOS_METHOD = (
    "`XCUIVoiceOverService.moveForward()` from the top of the screen to its "
    "end, where moving on gives the last utterance again, twice (C03's walk); "
    "what is shown is everything after the \"Example\" heading, and a walk "
    "that does not reach the end fails. Utterances are cut at 64 characters "
    "by the service",
    "Spoken, in swipe order",
)

# tool/voiceover_web.py: how the speech was captured.
VOICEOVER_WEB_METHOD = (
    "focus the Back button, then `voiceOver.next()` to the end of the screen. "
    "VoiceOver's last phrase and the position of its cursor are read over "
    "AppleScript after every move: a move that changes the position, or that "
    "speaks a different phrase, is a stop; two moves in a row that do neither are "
    "the end. Every walk must read the whole screen, each stop in its place "
    "(web_tests/vo/c18_vo_walks.js): the title and the description, the "
    "\"Example\" heading, and the expected list after it. A wrong stop, or a walk "
    "that reached the end with any expected stop not read, fails the test for "
    "good; only a walk cut short before the end with every stop right so far is "
    "walked again, up to three walks, each shown as its own row (`-walk-<n>`). "
    "No runner retries"
)
