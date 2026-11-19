"""Evidence tool registration for I03 Focus management.

Read by tool/evidence_common.py, which says what each name means."""

ID = "I03"
TITLE = "I03 Focus management"
ANDROID_TEST = "I03FocusManagementTest"
IOS_TEST = "I03FocusManagementUITests"
WEB_VO_SPEC = "i03_focus_management_vo.spec.js"

_PRESS_TO_ASK = ("good-material", "good-cupertino", "good-widgets", "bad-focus-left-behind")

# tool/talkback.py: marker -> (phrases that must be spoken, phrases that
# must not be). The walk does not put TalkBack's focus anywhere itself
# after each step: a marker is logged, then a control is activated, and
# what TalkBack says next is where its focus went by itself. "Button" is
# matched as a whole sentence, so a name cannot supply it.
TALKBACK_EXPECT = {
    # Into the question: TalkBack reads its title.
    **{f"i03-{slug}-opened": (["Remove Lake loop?"], []) for slug in _PRESS_TO_ASK},
    # Back on the button: TalkBack reads the screen's title, then the
    # button, and no other row. Where its focus ends, and that it stays
    # there, the test itself checks.
    **{f"i03-{slug}-cancelled": (["Remove Lake loop", "Button"],
                                 ["Remove Lake loop?", "Remove Ridge trail", "Remove Summit path"])
       for slug in _PRESS_TO_ASK},
    **{f"i03-{slug}-removed": (["Remove Summit path", "Button"], ["Remove Ridge trail"])
       for slug in _PRESS_TO_ASK},
    # good-material removes Ridge trail too, and about 400 ms later keyboard
    # focus moves on to Back: TalkBack follows keyboard focus to Back, and
    # nothing sends it to Summit path.
    "i03-good-material-moved-on": (["Back"], []),
    # TalkBack's focus on a Remove button is not keyboard focus, so the
    # defect does not happen: the button is read, and nothing is asked.
    "i03-bad-opens-on-focus-remove-ridge": (["Remove Ridge trail", "Button"], ["Remove Ridge trail?"]),
}

TALKBACK_METHOD = (
    "in each example TalkBack's focus is put on Remove Lake loop and the button is activated "
    "with the click action, as a double tap does; then the same for Cancel, then for Remove "
    "Lake loop and the question's Remove. A marker is logged before each activation, and what "
    "TalkBack says next is credited to it, so each row is what TalkBack read where its focus "
    "went by itself. The test also reads where TalkBack's focus is "
    "(`isAccessibilityFocused`) for eight seconds after it first gets there and then for two "
    "more, and fails unless it stays where the row says for those last two. In "
    "good-material, Ridge trail is then removed and Shift+Tab moves keyboard focus to Back "
    "about 400 ms after the click on the question's Remove (`moved-on`), and TalkBack's "
    "focus must be on Back "
    "itself for the last two seconds; on Android the examples send TalkBack "
    "nothing of their own, so it follows keyboard focus. Speech is read from TalkBack's "
    "verbose log"
)

# tool/voiceover_ios.py: (how the speech was captured, heading of the
# transcript column).
VOICEOVER_IOS_METHOD = (
    "with VoiceOver on, `tap()` moves its cursor to Remove Lake loop and `doubleTap()` "
    "activates it; `currentSpeech()` is then read for what VoiceOver said where its cursor "
    "went by itself. Three seconds after the question opens, before any control is touched, "
    "one `moveForward()` and one `moveBackward()` must both read a part of the question. The "
    "same for Cancel, and for Remove Lake loop and the question's Remove. "
    "Then Summit path is removed, and as soon as VoiceOver first speaks after the double tap "
    "on the question's Remove (it must be Remove Ridge trail), `moveBackward()` moves its "
    "cursor one element back, as a swipe left does, with keyboard focus left on Remove Ridge "
    "trail (`moved on`): the cursor must still be there three seconds later",
    "Spoken after each step",
)

# tool/voiceover_web.py: how the speech was captured.
VOICEOVER_WEB_METHOD = (
    "VoiceOver's cursor is put on Remove Lake loop by giving the element focus, and the "
    "button is activated with VoiceOver's own command (VO-Space); VoiceOver's last phrases "
    "and the element under its cursor are read over AppleScript for a few seconds after. "
    "The same for Cancel, and for Remove Lake loop and the question's Remove"
)
