"""Evidence tool registration for F01 Text fields and labels.

Read by tool/evidence_common.py, which says what each name means."""

ID = "F01"
TITLE = "F01 Text fields and labels"
ANDROID_TEST = "F01TextFieldsTest"
IOS_TEST = "F01TextFieldsUITests"
WEB_VO_SPEC = "f01_text_fields_vo.spec.js"

# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be).
TALKBACK_EXPECT = {
    # F01 Text fields and labels. A field must be announced with its name and
    # as an edit box. Ids ending in -filled are read after text was typed.
    "f01-good-label-email": (["Email", "Edit box"], []),
    # Flutter limitation FL-015: the label is exposed as Android hint text,
    # which TalkBack does not speak once the field has a value. Written to
    # fail when "Email" starts being spoken for the filled field.
    "f01-good-label-email-filled": (["abc", "Edit box"], ["Email"]),
    "f01-good-label-message": (["Message", "Edit box"], []),
    "f01-good-label-above-name": (["Full name", "Edit box"], []),
    "f01-good-cupertino-email": (["Email", "Edit box"], []),
    # Bad examples: the missing or wrong name must be audible.
    "f01-bad-placeholder-only-email": (["Email", "Edit box"], []),
    "f01-bad-placeholder-only-email-filled": (["abc", "Edit box"], ["Email"]),
    "f01-bad-unassociated-label-email": (["Edit box"], ["Email"]),
    "f01-bad-no-label-search": (["Edit box"], ["Search"]),
    "f01-bad-name-mismatch-email": (["Contact address", "Edit box"], ["Email"]),
    "f01-bad-cupertino-placeholder-email": (["Email", "Edit box"], []),
    "f01-bad-cupertino-placeholder-email-filled": (["abc", "Edit box"], ["Email"]),
    "f01-bad-cupertino-prefix-email": (["Edit box"], ["Email"]),
}
