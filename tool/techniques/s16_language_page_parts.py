"""Evidence tool registration for S16 Language of page and parts.

Read by tool/evidence_common.py, which says what each name means."""

ID = "S16"
TITLE = "S16 Language of page and parts"
ANDROID_TEST = "S16LanguagePagePartsTest"
IOS_TEST = "S16LanguagePagePartsUITests"
WEB_VO_SPEC = "s16_language_page_parts_vo.spec.js"

_LEAD = "The sign at the door reads:"
_PASSAGE = "Bienvenue à tous nos visiteurs."
_LANGUAGES = [("fr", "Français", "French"), ("es", "Español", "Spanish"), ("de", "Deutsch", "German")]

# What TalkBack's log can show, and what it cannot. TalkBack logs the
# locale it gives the speech engine with every fragment it speaks
# ("Speaking fragment text=…, locale=fr"), and it speaks a text with parts
# in other languages as one fragment per part (the probe,
# docs/evidence/probes/s16/android-talkback-log.txt: p08 "She said " en_US,
# "bonjour" fr, " to me." en_US). tool/talkback.py keeps the words of each
# fragment and drops the locale, so these rows judge words: where a part is
# marked inside a text, the row is that text's fragments, split where the
# language changes, which an unmarked text is not; where a whole node is in
# one language, the words are the same whatever its language, and the
# language is judged by the Android tree test (the LocaleSpan) and shown in
# the probe's log. Every row is a whole-utterance form ("== A / B",
# tool/talkback.py said()): a name inside another, a duplicated phrase, or
# an extra word is a wrong reading.


def _text(text):
    """A text that is one node in one language: exactly its words."""
    return ([f"== {text}"], [])


def _tile(name):
    """A language menu's tile: its name, then "Button", and TalkBack's usage
    hint, which said() allows once at the end."""
    return ([f"== {name} / Button"], [])


def _passage(slug):
    return {f"s16-{slug}-lead": _text(_LEAD), f"s16-{slug}-passage": _text(_PASSAGE)}


def _menu(slug):
    rows = {f"s16-{slug}-{code}": _tile(name) for code, name, _ in _LANGUAGES}
    rows[f"s16-{slug}-chosen"] = _text("Chosen: none")
    return rows


# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be). Each row is TalkBack focus moved to one text, or to one
# tile, of an example, in order.
TALKBACK_EXPECT = {
    **_passage("good-passage"),
    # The phrase marked French: the sentence in three fragments, split at
    # the phrase's language (p08). Unmarked it would be one (p09).
    "s16-good-phrase-sentence": (["== The guide said / bon voyage / as we left."], []),
    **_menu("good-language-menu"),
    **_passage("bad-unmarked"),
    **_menu("bad-title-in-tile"),
    **_passage("bad-region-tag"),
    **_passage("bad-override"),
}

# tool/talkback.py: how the speech was captured.
TALKBACK_METHOD = (
    "ACTION_ACCESSIBILITY_FOCUS on each text of each example, in order, and on each tile of the "
    "language menus and the line under them, five seconds each; speech read from TalkBack's "
    "verbose log, whose words only are kept: the locale TalkBack logs with each fragment is not "
    "read by the tool. Each row is a whole-utterance form, every fragment in order. Each walk is "
    "judged whole: a wrong reading fails for good, and only a walk shown to be incomplete is "
    "walked again"
)

# tool/voiceover_ios.py: (how the speech was captured, heading of the
# transcript column).
VOICEOVER_IOS_METHOD = (
    "`XCUIVoiceOverService.moveForward()` from the top of the screen to its "
    "end, where moving on gives the last utterance again, twice (C03's walk); "
    "the walk must first read this example's own title and description, and "
    "what is shown is everything after the \"Example\" heading. A walk that "
    "does not reach the end fails. The service gives the words, not the "
    "voice they were spoken in",
    "Spoken, in swipe order",
)

# tool/voiceover_web.py: how the speech was captured.
VOICEOVER_WEB_METHOD = (
    "focus the Back button, then `voiceOver.next()` to the end of the screen. "
    "VoiceOver's last phrase and the position of its cursor are read over "
    "AppleScript after every move: a move that changes the position, or that "
    "speaks a different phrase, is a stop; two moves in a row that do neither are "
    "the end. Every walk must read the whole screen, each stop in its place "
    "(web_tests/vo/s16_vo_walks.js): the title and the description, the "
    "\"Example\" heading, and the expected list after it. A wrong stop, or a walk "
    "that reached the end with any expected stop not read, fails the test for "
    "good; only a walk cut short before the end with every stop right so far, or "
    "one with a stop read as an empty phrase (a failed capture, which never "
    "passes) and nothing wrong read, is walked again, up to three walks, each "
    "shown as its own row (`-walk-<n>`). VoiceOver's own help message (\"You are "
    "currently on ...\") is not a stop when it is about the element just read: the walk puts "
    "the phrase logged for the move in its place and records each stop's cursor "
    "position, and the judge leaves out a help message only at the position of "
    "the stop before it, whose reading speaks the role the help names (from the "
    "reading's role part, never its name); any other is a wrong stop, as is any stop "
    "past the end of the screen, an empty one included. No runner retries. "
    "VoiceOver's last phrase is text: the voice it was spoken in is not recorded"
)
