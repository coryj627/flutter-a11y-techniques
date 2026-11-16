"""Evidence tool registration for S05 Headings.

Read by tool/evidence_common.py, which says what each name means."""

ID = "S05"
TITLE = "S05 Headings"
ANDROID_TEST = "S05HeadingsTest"
IOS_TEST = "S05HeadingsUITests"
WEB_VO_SPEC = "s05_headings_vo.spec.js"

# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be).
TALKBACK_EXPECT = {
    # S05 Headings. "Heading" must be spoken as the role for a real heading,
    # and must not be for text that only looks or reads like one.
    "s05-good-levels-profile": (["Profile", "Heading"], []),
    "s05-good-levels-contact-details": (["Contact details", "Heading"], []),
    "s05-good-levels-email-preferences": (["Email preferences", "Heading"], []),
    "s05-good-levels-security": (["Security", "Heading"], []),
    "s05-good-levels-body": (["Choose which messages you receive"], ["Heading"]),
    "s05-good-cupertino-notifications": (["Notifications", "Heading"], []),
    "s05-bad-visual-only-profile": (["Profile"], ["Heading"]),
    "s05-bad-fake-label-profile": (["Profile, heading"], ["Heading"]),
    # Android has one heading level, so the skipped level cannot be heard.
    "s05-bad-skipped-level-profile": (["Profile", "Heading"], []),
    "s05-bad-skipped-level-contact-details": (["Contact details", "Heading"], []),
    # header: true alone is not a heading on Android
    # (docs/flutter-limitations.md, FL-005).
    "s05-bad-header-only-profile": (["Profile"], ["Heading"]),
    "s05-bad-emphasis-heading-notice": (["Please check your address", "Heading"], []),
    "s05-bad-cupertino-section-header-notifications": (["Notifications"], ["Heading"]),
}
