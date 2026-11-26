"""Evidence tool registration for C06 Disclosure.

Read by tool/evidence_common.py, which says what each name means."""

ID = "C06"
TITLE = "C06 Disclosure"
ANDROID_TEST = "C06DisclosureTest"
IOS_TEST = "C06DisclosureUITests"
WEB_VO_SPEC = "c06_disclosure_vo.spec.js"

_TEXT = "Orders ship in two days."

# tool/talkback.py: marker -> (phrases that must be spoken, phrases that
# must not be). C06 is in talkback.py's STRICT: each walk is judged whole.
# For each example the walk puts TalkBack's focus on the control (closed),
# activates it with the click action with focus left there (activated: what
# TalkBack says on the change), moves to the panel's text (panel; Back for
# the Cupertino tile, whose open panel text is part of its control), and
# back to the control (open). Phrases are matched without case, as
# substrings, except "Button", which must be a sentence of its own. The
# tile's "Collapsed" is the end of its name (FL-264, FL-039), so the
# expectations cannot forbid the word "collapsed" while it is closed;
# "fully expanded", which TalkBack says for a real expanded state that
# changes (C05), is forbidden on the change, so that a state Flutter starts
# to give is caught. These are what TalkBack 17 says on Android 17, where
# the transcript is recorded.
TALKBACK_EXPECT = {
    # ExpansionTile with internalAddSemanticForOnTap: a button; the state is
    # only words in its name, and the change is announced by its live region.
    "c06-good-material-closed": (["Details,", "Collapsed", "Button", "Double-tap to Expand for more details"],
                                 ["expanded"]),
    "c06-good-material-activated": (["Expanded"], ["fully expanded", "collapsed"]),
    "c06-good-material-panel": ([_TEXT], ["Details"]),
    "c06-good-material-open": (["Details,", "Expanded", "Button", "Double-tap to Collapse"],
                               ["collapsed"]),
    # Bad examples: the defect must be audible where Android shows it.
    # ExpansionTile as it comes: the same words, and no "Button".
    "c06-bad-expansion-tile-closed": (["Details,", "Collapsed", "Double-tap to Expand for more details"],
                                      ["Button", "expanded"]),
    "c06-bad-expansion-tile-activated": (["Expanded"], ["fully expanded", "collapsed"]),
    "c06-bad-expansion-tile-panel": ([_TEXT], ["Details"]),
    "c06-bad-expansion-tile-open": (["Details,", "Expanded", "Double-tap to Collapse"],
                                    ["Button", "collapsed"]),
    # ExpandIcon: a button with no state in any words, before and after. Its
    # click label stays "Expand" once open (FL-280). What is said from the
    # click on is declared silent ("(must be silent)" is talkback.SILENT):
    # its marker is logged just before the click action, nothing at all may
    # be spoken in the row, and the row after it, the panel's text, is its
    # liveness control.
    "c06-bad-expand-icon-closed": (["Details", "Button", "Double-tap to Expand"],
                                   ["collapsed", "expanded"]),
    "c06-bad-expand-icon-activated": (["(must be silent)"], []),
    "c06-bad-expand-icon-panel": ([_TEXT], []),
    "c06-bad-expand-icon-open": (["Details", "Button", "Double-tap to Expand"],
                                 ["collapsed", "expanded", "Double-tap to Collapse"]),
    # CupertinoExpansionTile: no role and no state; open, the panel's text
    # joins the control, so the walk moves to Back before it reads the
    # control again. After the click, declared silent as for ExpandIcon;
    # Back is its liveness control.
    "c06-bad-cupertino-expansion-tile-closed": (["Details", "Double-tap to Expand for more details"],
                                                ["Button", "collapsed", "expanded"]),
    "c06-bad-cupertino-expansion-tile-activated": (["(must be silent)"], []),
    "c06-bad-cupertino-expansion-tile-back": (["Back", "Button"], []),
    "c06-bad-cupertino-expansion-tile-open": (["Details", _TEXT, "Double-tap to Collapse"],
                                              ["Button", "collapsed", "expanded"]),
}

TALKBACK_METHOD = (
    "for each example TalkBack's focus is put on the control (`closed`); a marker is logged and "
    "the control is activated with the click action, as a double tap does, with focus left on "
    "it (`activated`: what TalkBack says on the change); then focus goes to the panel's text "
    "(`panel`) and back to the control (`open`). For `bad-expand-icon` and "
    "`bad-cupertino-expansion-tile`, which have no state to announce, the `activated` row is "
    "declared silent: its marker is logged just before the click action, so speech during "
    "the action is in it, nothing at all may be spoken in it, and the row after it (`panel`, or `back`) is its liveness "
    "control and must be right; `bad-cupertino-expansion-tile`, whose open panel is part of "
    "its control, moves to Back (`back`) in place of the panel. Each walk is judged whole: a wrong reading fails "
    "for good, and only a walk shown to be incomplete is walked again. Speech is read from "
    "TalkBack's verbose log. Recorded on the local emulator, Android 17"
)

# tool/voiceover_ios.py: (how the speech was captured, heading of the
# transcript column).
VOICEOVER_IOS_METHOD = (
    "`XCUIVoiceOverService.moveForward()` from the top of the screen to its end, where moving "
    "on gives the last utterance again, twice; what is shown is everything after the "
    "\"Example\" heading, and a walk that does not reach the end fails. Each example is walked "
    "closed; then the cursor is put on the control by a tap, and XCUITest's `doubleTap()` at "
    "it opens it (`xcuitest-double-tap-` rows: what VoiceOver said with the cursor there, every "
    "raw read of the four seconds after the gesture, a failed read shown as failed, and for "
    "the two examples judged silent the reading after a move on; each row is judged, "
    "`ExpansionTile`'s \"Expanded\" required, silence required of the others). That gesture is "
    "a tap at the control's place, "
    "not VoiceOver's own activation, which XCUIVoiceOverService cannot make (C04 probe round "
    "3), so what VoiceOver's own double tap does is not measured. Then the example is walked "
    "again (`-open` rows)",
    "Spoken, in swipe order",
)

# tool/voiceover_web.py: how the speech was captured.
VOICEOVER_WEB_METHOD = (
    "focus the Back button, then `voiceOver.next()` to the end of the screen. VoiceOver's last "
    "phrase and the position of its cursor are read over AppleScript after every move: a move "
    "that changes the position, or that speaks a different phrase, is a stop; two moves in a "
    "row that do neither are the end. Each example is walked closed, and again after a click "
    "has opened it (`-open` rows). Every stop is judged (web_tests/vo/c06_vo_walks.js); a "
    "walk that fell short is tried again, up to three times, and every try is listed"
)
