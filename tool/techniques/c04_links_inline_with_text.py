"""Evidence tool registration for C04 Links inline with text.

Read by tool/evidence_common.py, which says what each name means."""

ID = "C04"
TITLE = "C04 Links inline with text"
ANDROID_TEST = "C04LinksInlineWithTextTest"
IOS_TEST = "C04LinksInlineWithTextUITests"
WEB_VO_SPEC = "c04_links_inline_with_text_vo.spec.js"

_FIRST = "links in text"
_SECOND = "stand-alone links"

# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be). TalkBack says no role for a Flutter link with an address
# (FL-220); the links' onTapHint makes it say "Double-tap to open link" in
# place of "Double-tap to activate". The words of a sentence have no action.
_OPEN = "Double-tap to open link"
_ACTIVATE = "Double-tap to activate"
_LINK_NOT = ["Button", _ACTIVATE]
_WORDS_NOT = ["Double-tap", _FIRST, _SECOND]


def _sentence(slug):
    """The five stops of a sentence read in order: words, link, words, link,
    words."""
    return {
        f"c04-{slug}-words-1": (["Read about"], _WORDS_NOT),
        f"c04-{slug}-link-1": ([_FIRST, _OPEN], _LINK_NOT + [_SECOND]),
        f"c04-{slug}-words-2": (["and"], _WORDS_NOT),
        f"c04-{slug}-link-2": ([_SECOND, _OPEN], _LINK_NOT + [_FIRST]),
        f"c04-{slug}-words-3": (["first."], _WORDS_NOT),
    }


TALKBACK_EXPECT = {
    **_sentence("good-material"),
    **_sentence("good-cupertino"),
    **_sentence("good-custom"),
    # Bad examples: the defect must be audible where Android shows it. A link
    # with no address is read as a button (FL-032), with no "open link".
    "c04-bad-text-span-link-1": ([_FIRST, "Button"], [_OPEN]),
    # The sentence's node has its words and not its links, which follow.
    "c04-bad-out-of-order-sentence": (["Read about", "and", "first."], [_FIRST, _SECOND, "Double-tap"]),
    "c04-bad-out-of-order-link-1": ([_FIRST, _OPEN], _LINK_NOT),
    "c04-bad-out-of-order-link-2": ([_SECOND, _OPEN], _LINK_NOT),
    # The defect is in what is drawn; what is heard is as in good-material.
    **_sentence("bad-colour-only"),
    # One element: the whole sentence, both links' names in it. In the probe
    # TalkBack read the sentence and no hint within five seconds
    # (docs/evidence/probes/c04/android-talkback.md, r05), so the hint is
    # not required here.
    "c04-bad-merged-sentence": (["Read about", _FIRST, _SECOND, "first."], ["Button", _ACTIVATE]),
}

# tool/voiceover_ios.py: (how the speech was captured, heading of the
# transcript column).
VOICEOVER_IOS_METHOD = (
    "`XCUIVoiceOverService.moveForward()` from the top of the screen to its "
    "end, where moving on gives the last utterance again, twice; what is shown "
    "is everything after the \"Example\" heading, and a walk that does not "
    "reach the end fails. Then, for each link of each good example, the cursor "
    "is moved forward to the link, what VoiceOver says there is read, and a "
    "double tap on the link with VoiceOver on is checked to open the link's "
    "page (`double-tap-` rows); for good-material, a tap at each link's centre "
    "with VoiceOver on and what the cursor lands on (`touch-` rows, FL-246); "
    "and for bad-merged, what a double tap on the sentence opened, recorded and "
    "not checked",
    "Spoken, in swipe order",
)

# tool/voiceover_web.py: how the speech was captured.
VOICEOVER_WEB_METHOD = (
    "focus the Back button, then `voiceOver.next()` to the end of the screen. "
    "VoiceOver's last phrase and the position of its cursor are read over "
    "AppleScript after every move: a move that changes the position, or that "
    "speaks a different phrase, is a stop; two moves in a row that do neither are "
    "the end. Every stop after the \"Example\" heading is compared, with no retry"
)
