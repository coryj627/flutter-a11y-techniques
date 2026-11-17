"""Evidence tool registration for C01 Button.

Read by tool/evidence_common.py, which says what each name means."""

ID = "C01"
TITLE = "C01 Button"
ANDROID_TEST = "C01ButtonTest"
IOS_TEST = "C01ButtonUITests"
WEB_VO_SPEC = "c01_button_vo.spec.js"

# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be).
TALKBACK_EXPECT = {
    "c01-good-text-filled": (["Save", "Button"], ["Disabled"]),
    "c01-good-text-outlined": (["Cancel", "Button"], []),
    "c01-good-text-text": (["Learn more", "Button"], []),
    "c01-good-icon-close": (["Close", "Button"], []),
    "c01-good-disabled-submit": (["Submit", "Button", "Disabled"], []),
    "c01-good-unique-names-username": (["Edit username", "Button"], []),
    "c01-good-unique-names-email": (["Edit email", "Button"], []),
    "c01-good-unique-names-password": (["Edit password", "Button"], []),
    "c01-good-cupertino-save": (["Save", "Button"], ["Disabled"]),
    "c01-good-cupertino-delete": (["Delete", "Button", "Disabled"], []),
    "c01-good-custom-save": (["Save", "Button"], []),
    # Bad examples: the defect must be audible.
    "c01-bad-unlabelled-icon-close": (["Button"], ["Close"]),
    "c01-bad-gesture-only-save": (["Save"], ["Button"]),
    "c01-bad-role-in-name-close": (["Close button", "Button"], []),
    "c01-bad-duplicate-names-username": (["Edit", "Button"], ["username"]),
    "c01-bad-duplicate-names-email": (["Edit", "Button"], ["email"]),
    "c01-bad-duplicate-names-password": (["Edit", "Button"], ["password"]),
    "c01-bad-name-mismatch-edit": (["Change username", "Button"], ["Edit"]),
    "c01-bad-fake-disabled-submit": (["Submit", "Button"], ["Disabled"]),
    "c01-bad-cupertino-disabled-delete": (["Delete", "Button"], ["Disabled"]),
}
