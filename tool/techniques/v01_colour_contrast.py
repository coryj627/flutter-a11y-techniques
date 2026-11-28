"""Evidence tool registration for V01 Colour contrast.

Read by tool/evidence_common.py, which says what each name means."""

ID = "V01"
TITLE = "V01 Colour contrast"
ANDROID_TEST = "V01ColourContrastTest"
IOS_TEST = "V01ColourContrastUITests"
WEB_VO_SPEC = "v01_colour_contrast_vo.spec.js"

# A colour is drawn, not spoken: no defect of V01 is heard. The rows record
# what each example's controls and texts say, so that the transcripts show
# the bad examples read as the good ones, except where the colour is the
# only sign of a state on the screen and the state still reaches TalkBack
# (bad-colour-only's selected tile).
#
# Every row is a whole-utterance row ("== A / B / C" in tool/talkback.py's
# said()), written from what TalkBack said in the first walk, and said the
# same in every walk since (the committed one is
# docs/evidence/V01/talkback-android.md): the row's utterances must be
# exactly these, in this order, and nothing else; TalkBack's usage hint
# "Double-tap to activate" is allowed once at the end. A field's or a
# toggle's own hint is not that one, so it is written into the row as heard.
# As heard: the Material field says its label alone, "Email", and not its
# hint "Required"; the Cupertino field says "Email Required", its label and
# its placeholder, which Flutter gives as one name; the chosen radio button
# begins "checked." and the chosen tile of bad-colour-only "selected.".
_FIELD_HINT = "Double-tap to edit text. Actions available, use Tap with 3 fingers to view"
_TOGGLE_HINT = "Double-tap to toggle"


def _whole(*utterances):
    return ([f"== {' / '.join(utterances)}"], [])


def _field(name):
    return _whole(name, "Edit box", _FIELD_HINT)


def _radios(slug):
    return {
        f"v01-{slug}-label": _whole("Calendar view"),
        f"v01-{slug}-day": _whole("Day", "Radio button", _TOGGLE_HINT),
        f"v01-{slug}-week": _whole("checked.", "Week", "Radio button", _TOGGLE_HINT),
        f"v01-{slug}-month": _whole("Month", "Radio button", _TOGGLE_HINT),
    }


# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be). The walk (V01ColourContrastTest.talkBackWalk) moves TalkBack
# focus to each text and control of each example in turn. Each walk is judged
# whole (V01 is in tool/talkback.py's STRICT set).
TALKBACK_EXPECT = {
    "v01-good-material-body": _whole("We reply within two days."),
    "v01-good-material-email": _field("Email"),
    "v01-good-material-updates": _whole("Send me updates", "Check box", _TOGGLE_HINT),
    "v01-good-material-send": _whole("Send", "Button"),
    "v01-good-cupertino-email": _field("Email Required"),
    "v01-good-cupertino-send": _whole("Send", "Button"),
    "v01-good-caption-caption": _whole("Harbour"),
    **_radios("good-selection"),
    # Read as good-cupertino's field: the faint placeholder is spoken all the same.
    "v01-bad-cupertino-placeholder-email": _field("Email Required"),
    # Read as good-caption's.
    "v01-bad-caption-caption": _whole("Harbour"),
    # Buttons, Week's state "selected.": the state reaches TalkBack, though
    # on the screen only a colour shows it.
    "v01-bad-colour-only-label": _whole("Calendar view"),
    "v01-bad-colour-only-day": _whole("Day", "Button"),
    "v01-bad-colour-only-week": _whole("selected.", "Week", "Button"),
    "v01-bad-colour-only-month": _whole("Month", "Button"),
    # Read as good-material's field: the faint edge is not heard.
    "v01-bad-faint-edge-email": _field("Email"),
}

# tool/talkback.py: how the speech was captured.
TALKBACK_METHOD = (
    "TalkBack focus moved by ACTION_ACCESSIBILITY_FOCUS to each text and control of each "
    "example in turn, five seconds each, with the device in light mode; speech read from "
    "TalkBack's verbose log. Each walk is judged whole: a wrong reading fails for good, and only "
    "a walk shown to be incomplete is walked again, up to three walks. Every row is judged as "
    "whole utterances, exactly those heard and in their order (\"== A / B\"), the usage hint "
    "allowed once at the end. A colour is not spoken: the rows record what each part is to "
    "TalkBack, and the contrast is measured from the Android tree test's screenshots"
)

# tool/voiceover_ios.py: (how the speech was captured, heading of the
# transcript column).
VOICEOVER_IOS_METHOD = (
    "`XCUIVoiceOverService.moveForward()` from the top of the screen to its "
    "end (V01Walk, a copy of S16's S16Walk): a stop read twice in a row in the "
    "middle of the walk fails, and the last utterance read again twice is the "
    "end only when one move back then reads the stop before it and one move "
    "forward the last again; the walk must first read this example's own "
    "title, description and, for a bad example, its defect, then the "
    "\"Example\" heading, and after it exactly the expected stops, each "
    "compared with its runs of white space made one space; the Cupertino "
    "field's utterance is also compared as the service gave it, with the line "
    "break between \"Email\" and \"Required\". A move that gives no speech is "
    "checked by a move back and one forward again; unless the move back reads "
    "the stop before it, the stop is recorded as not known, which fails. What "
    "is shown is everything after the heading, white space made one space. A "
    "walk that does not reach the end fails, and every expected utterance is "
    "under 64 characters (a test refuses a longer one). A colour is not "
    "spoken: these rows record what each example's texts and controls say, "
    "not its defect",
    "Spoken, in swipe order",
)

# tool/voiceover_web.py: how the speech was captured.
VOICEOVER_WEB_METHOD = (
    "focus the Back button and capture VoiceOver's last phrase and its cursor's position there "
    "(the walk's start row), then `voiceOver.next()` to the end of the screen, capturing both "
    "over AppleScript after every move (collectWalk, web_tests/vo/v01_vo_walks.js, S16's walk "
    "with the S08 to S12 judge update). Every phrase is recorded with its white space, a line "
    "break included, made single spaces (the Cupertino fields' names hold one). A move that "
    "changes the position, or that speaks a non-empty phrase other than the stop before it (or "
    "than the start, before the first stop), is a stop, and the position at each stop is the "
    "walk's positions row. A move that does neither is kept: one followed by a move on is an "
    "unresolved read, a gap after the stop before it, and is listed on the walk's unresolved row; "
    "two in a row are the end only when a move back then reads the stop before the last, not "
    "empty, at another position, and a move forward the last again at its position, both on the "
    "walk's end row; the move back may instead read VoiceOver's help about the stop before the "
    "last, naming its spoken role, at exactly that stop's recorded position; a failed witness is "
    "wrong for good. Every walk is judged whole (judgeWalk): the title, the description, a bad "
    "example's defect, the \"Example\" heading, and the expected list after it, each in its "
    "place; a stop past the last expected one, empty or not, is wrong; a wrong stop always wins, "
    "across a gap the next stop must be the next expected one or the one after it, and a walk "
    "that ran out of moves is wrong. Only a walk with no wrong stop and a gap, or a stop read as "
    "an empty phrase, is walked again, up to three walks, each its own row (`-walk-<n>`, a \"/\" "
    "in a stop written \"\\/\"), and it never passes. VoiceOver's own help message (\"You are "
    "currently on ...\" or \"in ...\") is left out only at the position of the stop before it, "
    "whose reading speaks the role the help names; it stays in the walk's row, and the web tree "
    "spec judges the transcript again from its rows by the same rule, from the positions row. "
    "Relaxed for the text fields only, by the principal's decisions of 2026-11-28 after the "
    "first recording (docs/evidence/probes/v01/voiceover-web-round1-fail.md.txt), because a "
    "field with a hint gets aria-label \"Email\\nRequired\" and placeholder \"Required\" when "
    "VoiceOver's cursor gives it focus: the three fields with a hint (good-material's Email "
    "field, good-cupertino's and bad-cupertino-placeholder's) are each one stop judged by the "
    "pattern `^Email( Required){0,2} edit text$`, so how many times \"Required\" is read is "
    "recorded, not judged; such a field read again in a form of that pattern at exactly its "
    "position is that stop read again, not a second stop: it stays in the walk's row and its "
    "position is written \"re-read <bounds>\" on the positions row, and the transcript judge "
    "takes a re-read only from that mark; when the last stop is one of those three fields or "
    "bad-faint-edge's field (no hint, its words judged exactly), the end witness's move forward "
    "may read an empty phrase or another form of that stop, at exactly its recorded position "
    "(for bad-faint-edge only \"Email edit text\" or empty); the move back must still freshly "
    "read the stop before the last, not empty, at another position, and may read it in its "
    "other field form only when that stop is a field with a hint, at exactly its recorded "
    "position (good-cupertino). Every other stop is judged exactly, with no such leniency. "
    "No runner retries. The browser's colour scheme is Playwright's default, light. VoiceOver's "
    "last phrase is text: a colour is not in it, so what is judged is the words and the stops, "
    "not the contrast"
)
