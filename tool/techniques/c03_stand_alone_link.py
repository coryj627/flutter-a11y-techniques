"""Evidence tool registration for C03 Stand-alone link.

Read by tool/evidence_common.py, which says what each name means."""

ID = "C03"
TITLE = "C03 Stand-alone link"
ANDROID_TEST = "C03StandAloneLinkTest"
IOS_TEST = "C03StandAloneLinkUITests"
WEB_VO_SPEC = "c03_stand_alone_link_vo.spec.js"

_NAME = "Read about stand-alone links"

# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be). TalkBack says no role for a Flutter link with an address,
# only its name (docs/evidence/probes/c03); the good links' onTapHint makes
# it say "Double-tap to open link" in place of "Double-tap to activate".
_OPEN = "Double-tap to open link"
_ACTIVATE = "Double-tap to activate"
TALKBACK_EXPECT = {
    "c03-good-material-link": ([_NAME, _OPEN], ["Button", _ACTIVATE]),
    "c03-good-cupertino-link": ([_NAME, _OPEN], ["Button", _ACTIVATE]),
    "c03-good-custom-link": ([_NAME, _OPEN], ["Button", _ACTIVATE]),
    "c03-good-image-link-link": ([_NAME, _OPEN], ["Button", _ACTIVATE, "Image"]),
    # Bad examples: the defect must be audible where Android shows it.
    "c03-bad-vague-text-link": (["Read more", _OPEN], [_NAME]),
    # Nothing says it is a link.
    "c03-bad-tap-handler-link": ([_NAME, _ACTIVATE], ["Button", _OPEN]),
    "c03-bad-no-address-link": ([_NAME, "Button"], []),
    # No name, and the address rides on the name, so it is a button.
    "c03-bad-image-no-name-link": (["Button", _OPEN], [_NAME]),
    # The name is on the picture inside the link, which is read as a picture
    # that does nothing. The link round it has no name (the tree test); what
    # TalkBack says for it is not checked, as a check that passes on silence
    # would also pass on a lost capture.
    "c03-bad-label-on-image-image": ([_NAME, "Image"], [_OPEN, _ACTIVATE]),
    "c03-bad-cupertino-button-link": ([_NAME, "Button"], []),
    # The defect is on the web only.
    "c03-bad-app-also-follows-link": ([_NAME, _OPEN], ["Button", _ACTIVATE]),
}

# tool/voiceover_ios.py: (how the speech was captured, heading of the
# transcript column).
VOICEOVER_IOS_METHOD = (
    "`XCUIVoiceOverService.moveForward()` from the top of the screen until the "
    "example's expected last utterance, its link, is heard; what is shown is "
    "everything after the \"Example\" heading. A walk that never hears that "
    "utterance does not finish and fails. Then, for each good example, the "
    "cursor is put on the link, what VoiceOver says there is read, and a double "
    "tap with VoiceOver on is checked to open the technique's page "
    "(`double-tap-` rows)",
    "Spoken, in swipe order",
)

# tool/voiceover_web.py: how the speech was captured.
VOICEOVER_WEB_METHOD = (
    "focus the Back button, then `voiceOver.next()` to the end of the screen. "
    "VoiceOver's last phrase and the position of its cursor are read over "
    "AppleScript after every move: a move that changes the position, or that "
    "speaks a different phrase, is a stop; two moves in a row that do neither are "
    "the end. The link is the last element of every example"
)
