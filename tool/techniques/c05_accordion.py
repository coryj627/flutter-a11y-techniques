"""Evidence tool registration for C05 Accordion.

Read by tool/evidence_common.py, which says what each name means."""

ID = "C05"
TITLE = "C05 Accordion"
ANDROID_TEST = "C05AccordionTest"
IOS_TEST = "C05AccordionUITests"
WEB_VO_SPEC = "c05_accordion_vo.spec.js"

_GOOD = ("good-material", "good-cupertino", "good-custom")
_TEXT = "Orders ship in two days."

# tool/talkback.py: marker -> (phrases that must be spoken, phrases that
# must not be). For each example the walk puts TalkBack's focus on the
# Shipping header (closed), activates it with the click action (activated:
# what TalkBack says on the change), moves to the panel's text (panel), and
# back to the header (open). These are what TalkBack 17 says on Android 17,
# where Flutter passes the expanded state (FL-261); the transcript is
# recorded on that emulator. "Button" and "Heading" are matched as whole
# sentences, so a name cannot supply them.
TALKBACK_EXPECT = {
    **{f"c05-{slug}-closed": (["collapsed", "Shipping", "Button", "Heading", "Double-tap to expand",
                               "Actions available"],
                              ["expanded", "Double-tap to activate"]) for slug in _GOOD},
    **{f"c05-{slug}-activated": (["expanded"], ["collapsed"]) for slug in _GOOD},
    **{f"c05-{slug}-panel": ([_TEXT], ["Shipping"]) for slug in _GOOD},
    **{f"c05-{slug}-open": (["expanded", "Shipping", "Button", "Heading", "Double-tap to collapse"],
                            ["collapsed"]) for slug in _GOOD},
    # Bad examples: the defect must be audible where Android shows it.
    # No state, before or after. What is said on the click is not checked
    # for bad-no-state or bad-cupertino-expansion-tile, which have no state
    # to announce: a check of silence would pass on a lost capture too (the
    # walk drops that speech with an END marker).
    "c05-bad-no-state-closed": (["Shipping", "Button", "Heading", "Double-tap to activate"],
                                ["collapsed", "expanded", "expand"]),
    "c05-bad-no-state-panel": ([_TEXT], []),
    "c05-bad-no-state-open": (["Shipping", "Button", "Heading", "Double-tap to activate"],
                              ["collapsed", "expanded", "collapse"]),
    # The defect is on the web only: on Android it is read as the good ones.
    "c05-bad-heading-on-button-closed": (["collapsed", "Shipping", "Button", "Heading", "Double-tap to expand"],
                                         ["expanded"]),
    "c05-bad-heading-on-button-activated": (["expanded"], ["collapsed"]),
    "c05-bad-heading-on-button-panel": ([_TEXT], []),
    "c05-bad-heading-on-button-open": (["expanded", "Shipping", "Button", "Heading"], ["collapsed"]),
    # No heading.
    "c05-bad-no-heading-closed": (["collapsed", "Shipping", "Button", "Double-tap to expand"], ["Heading"]),
    "c05-bad-no-heading-activated": (["expanded"], ["collapsed"]),
    "c05-bad-no-heading-panel": ([_TEXT], []),
    "c05-bad-no-heading-open": (["expanded", "Shipping", "Button"], ["Heading", "collapsed"]),
    # ExpansionTile: the hint "Collapsed" is part of the name (FL-039), no
    # button role and no expanded state; the change is announced by a live
    # region.
    "c05-bad-expansion-tile-closed": (["Shipping", "Collapsed", "Double-tap to Expand for more details"],
                                      ["Button", "Heading"]),
    "c05-bad-expansion-tile-activated": (["Expanded"], []),
    "c05-bad-expansion-tile-panel": ([_TEXT], []),
    "c05-bad-expansion-tile-open": (["Shipping", "Expanded", "Double-tap to Collapse"], ["Button", "Heading"]),
    # CupertinoExpansionTile: no role and no state; the panel's text joins
    # the header once it is open, so the walk moves to Back in place of a
    # panel node before it reads the header again.
    "c05-bad-cupertino-expansion-tile-closed": (["Shipping", "Double-tap to Expand for more details"],
                                                ["Button", "collapsed", "expanded"]),
    "c05-bad-cupertino-expansion-tile-back": (["Back", "Button"], []),
    "c05-bad-cupertino-expansion-tile-open": (["Shipping", _TEXT], ["Button", "collapsed", "expanded"]),
}

TALKBACK_METHOD = (
    "for each example TalkBack's focus is put on the Shipping header (`closed`); a marker is "
    "logged and the header is activated with the click action, as a double tap does, with "
    "focus left on it (`activated`: what TalkBack says on the change); then focus goes to the "
    "panel's text (`panel`) and back to the header (`open`). For `bad-no-state` and "
    "`bad-cupertino-expansion-tile`, which have no state to announce, what is said on the "
    "click is dropped and not checked, as a check of silence would also pass on a lost "
    "capture; `bad-cupertino-expansion-tile`, whose open panel is part of its header, moves "
    "to Back (`back`) in place of the panel. Speech is read from TalkBack's "
    "verbose log. Recorded on the local emulator, Android 17, where Flutter passes the "
    "expanded state; before Android 16 it does not (FL-261)"
)

# tool/voiceover_ios.py: (how the speech was captured, heading of the
# transcript column).
VOICEOVER_IOS_METHOD = (
    "`XCUIVoiceOverService.moveForward()` from the top of the screen to its end, where moving "
    "on gives the last utterance again, twice; what is shown is everything after the "
    "\"Example\" heading, and a walk that does not reach the end fails. Each example is walked "
    "with both sections closed; then the cursor is put on Shipping by a tap, and XCUITest's "
    "`doubleTap()` at the header opens it (`xcuitest-double-tap-` rows: what VoiceOver said "
    "with the cursor there, and in the three seconds after the gesture). That gesture is a "
    "tap at the header's place, not VoiceOver's own activation, which XCUIVoiceOverService "
    "cannot make (C04 probe round 3), so what VoiceOver's own double tap does is not "
    "measured. Then the example is walked again (`-open` rows)",
    "Spoken, in swipe order",
)

# tool/voiceover_web.py: how the speech was captured.
VOICEOVER_WEB_METHOD = (
    "focus the Back button, then `voiceOver.next()` to the end of the screen. VoiceOver's last "
    "phrase and the position of its cursor are read over AppleScript after every move: a move "
    "that changes the position, or that speaks a different phrase, is a stop; two moves in a "
    "row that do neither are the end. Each example is walked closed, and again after a click "
    "has opened Shipping (`-open` rows). Every stop is judged (web_tests/vo/c05_vo_walks.js); "
    "a walk that fell short is tried again, up to three times, and every try is listed"
)
