"""Evidence tool registration for I04 Keyboard actions and shortcuts.

Read by tool/evidence_common.py, which says what each name means."""

ID = "I04"
TITLE = "I04 Keyboard actions and shortcuts"
ANDROID_TEST = "I04KeyboardActionsTest"
IOS_TEST = "I04KeyboardActionsUITests"
WEB_VO_SPEC = "i04_keyboard_actions_vo.spec.js"

_ALL = ("good-on-focus", "good-turn-off", "good-remap", "bad-page-shortcut", "bad-no-arrow-keys")
_SETTINGS = {
    "good-turn-off": ("Single-key shortcuts", "on"),
    "good-remap": ("Use Control+F for favourites", "off"),
}


def _expect(slug):
    # "Button", "Switch", "on", and "off" are matched as words of their own,
    # so a name cannot supply them. The thumbnail of the photo shown is
    # "selected" and the others are not. The keys are not heard: TalkBack
    # reads every example's strip the same way, which is what these lines
    # record.
    out = {}
    for i, name in enumerate(("Trailhead", "Bridge", "Ridge", "Summit")):
        out[f"i04-{slug}-{name.lower()}"] = (
            ([name, "Button", "selected"], []) if i == 0 else ([name, "Button"], ["selected"]))
    out[f"i04-{slug}-favourite"] = (["Add to favourites", "Button"], [])
    if slug in _SETTINGS:
        label, state = _SETTINGS[slug]
        out[f"i04-{slug}-setting"] = ([label, "Switch", state], ["off" if state == "on" else "on"])
    out[f"i04-{slug}-note"] = (["Note", "Edit box"], [])
    return out


# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be). The walk puts TalkBack's focus on each part in turn.
TALKBACK_EXPECT = {ident: expected for slug in _ALL for ident, expected in _expect(slug).items()}

# tool/voiceover_ios.py: (how the speech was captured, heading of the
# transcript column).
VOICEOVER_IOS_METHOD = (
    "`XCUIVoiceOverService.moveForward()` from the top of the screen to the "
    "count of notes saved, which is the last element of every example. What is "
    "shown is everything between the \"Example\" heading and the count",
    "Spoken, in swipe order",
)

# tool/voiceover_web.py: how the speech was captured.
VOICEOVER_WEB_METHOD = (
    "focus the Back button, wait until VoiceOver has been quiet for two seconds, then "
    "`voiceOver.next()` to the end of the screen. VoiceOver's last phrase and the "
    "position of its cursor are read over AppleScript after every move: a move that "
    "changes the position, or that speaks a different phrase, is a stop; two moves in "
    "a row that do neither are the end. The count of notes saved is the last element "
    "of every example. The `keys-bad-page-shortcut` row is not speech: with VoiceOver "
    "on, keys were pressed through Guidepup on a thumbnail and in the note, and the "
    "row shows what the page then showed"
)
