"""Evidence tool registration for S01 Accessible names.

Read by tool/evidence_common.py, which says what each name means."""

ID = "S01"
TITLE = "S01 Accessible names"
ANDROID_TEST = "S01AccessibleNamesTest"
IOS_TEST = "S01AccessibleNamesUITests"
WEB_VO_SPEC = "s01_accessible_names_vo.spec.js"

# tool/talkback.py: identifier -> (phrases that must be spoken, phrases that
# must not be).
TALKBACK_EXPECT = {
    # S01 Accessible names. A named control is announced with its name and
    # its role; the bad examples must sound as their defects say.
    "s01-good-visible-label-updates": (["Email me order updates", "Check box"], []),
    "s01-good-visible-label-dark": (["Dark mode", "Switch"], []),
    "s01-good-merged-label-remember": (["Remember this device", "Check box"], []),
    "s01-good-merged-label-wifi": (["Wi-Fi", "Switch"], []),
    "s01-good-specific-names-email": (["Order updates, email", "Switch"], []),
    "s01-good-specific-names-sms": (["Order updates, text message", "Switch"], []),
    "s01-good-cupertino-airplane": (["Airplane mode", "Switch"], []),
    "s01-bad-unassociated-label-terms": (["Check box"], ["I accept the terms"]),
    "s01-bad-duplicate-names-email": (["Order updates", "Switch"], ["email"]),
    "s01-bad-duplicate-names-sms": (["Order updates", "Switch"], ["text message"]),
    "s01-bad-role-in-name-dark": (["Dark mode switch", "Switch"], []),
    # FL-028 is a web limitation: on Android the slider is named.
    "s01-bad-slider-name-web-volume": (["Volume", "Slider"], []),
}
