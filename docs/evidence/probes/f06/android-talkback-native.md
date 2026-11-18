# F06 probe: TalkBack on a native EditText with setError

Speech per marker of ProbeF06Test, parsed from logcat with tool/talkback.py's parse_speech. Each stop's focus was forced by the test (ACTION_ACCESSIBILITY_FOCUS), so this shows what is spoken, not the order a swipe would take. TalkBack 17.0, Android 17 emulator, Flutter 3.47.5, 2026-11-18. A line break inside one spoken text is shown as a space.

| Marker | TalkBack spoke |
| --- | --- |
| `f06-native-submit` | N03 SUBMIT. Button / Double-tap to activate |
| `f06-native-after-submit` | Error: Enter an email address. / Error: Enter a phone number using digits only. |
| `f06-native-email` | Error: Enter an email address.. n01 Email. Edit box / Double-tap to edit text. Double-tap and hold to long press. Proofreading is available. 1 misspelled words. Swipe down with 3 fingers and use "Proofread" to view. Actions available, use Tap with 3 fingers to view |
| `f06-native-phone` | Error: Enter a phone number using digits only.. abc. Edit box / Double-tap to edit text. Double-tap and hold to long press. Actions available, use Tap with 3 fingers to view |
