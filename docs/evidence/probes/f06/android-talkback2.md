# F06 probe, round 2: TalkBack

Speech per marker of ProbeF06Test, parsed from logcat with tool/talkback.py's parse_speech. Each stop's focus was forced by the test (ACTION_ACCESSIBILITY_FOCUS), so this shows what is spoken, not the order a swipe would take. TalkBack 17.0, Android 17 emulator, Flutter 3.47.5, 2026-11-18. A line break inside one spoken text is shown as a space.

| Marker | TalkBack spoke |
| --- | --- |
| `f06-q01-submit` | q01 Submit / Button / Double-tap to activate |
| `f06-q01-after-submit` | Enter an email address, like name@example.com. / Enter your name. |
| `f06-q01-stop-0` | q01 Name, /   / Enter your name. / Edit box / Double-tap to edit text. Actions available, use Tap with 3 fingers to view |
| `f06-q01-stop-1` | Enter your name. |
| `f06-q01-stop-2` | q01 Email, /   / Enter an email address, like name@example.com. / Edit box |
| `f06-q01-stop-3` | Enter an email address, like name@example.com. |
| `f06-q01-stop-4` | q01 Submit / Button / Double-tap to activate |
| `f06-q02-submit` | q02 Submit / Button / Double-tap to activate |
| `f06-q02-after-submit` | Enter an email address, like name@example.com. / Enter your name. / q02 Name, /   / Enter your name. / Editing. Edit box |
| `f06-q02-stop-0` | keyboard hidden |
| `f06-q02-stop-1` | Enter your name. |
| `f06-q02-stop-2` | q02 Email, /   / Enter an email address, like name@example.com. / Edit box |
| `f06-q02-stop-3` | Enter an email address, like name@example.com. |
| `f06-q02-stop-4` | q02 Submit / Button / Double-tap to activate |
| `f06-q03-submit` | q03 Submit / Button / Double-tap to activate |
| `f06-q03-after-submit` | Enter an email address, like name@example.com. / Editing.  / abc / Edit box / Showing English (US) (QWERTY) |
| `f06-q03-stop-0` | keyboard hidden / Ana / Edit box / Double-tap to edit text. Actions available, use Tap with 3 fingers to view |
| `f06-q03-stop-1` | Editing.  / abc / Edit box / Actions available, use Tap with 3 fingers to view |
| `f06-q03-stop-2` | Enter an email address, like name@example.com. |
| `f06-q03-stop-3` | q03 Submit / Button / Double-tap to activate |
| `f06-q04-submit` | q04 Submit / Button / Double-tap to activate |
| `f06-q04-after-submit` | Enter an email address, like name@example.com. / q04 Email name@example.com, /   / Enter an email address, like name@example.com. |
| `f06-q04-stop-0` | Editing. Edit box / Showing English (US) (QWERTY) / keyboard hidden |
| `f06-q04-stop-1` | Enter an email address, like name@example.com. |
| `f06-q04-stop-2` | q04 Submit / Button / Double-tap to activate |
| `f06-q05-submit` | q05 Submit / Button / Double-tap to activate |
| `f06-q05-after-submit` | Enter an email address, like name@example.com. |
| `f06-q05-stop-0` | q05 Email / Edit box / Double-tap to edit text. Actions available, use Tap with 3 fingers to view |
| `f06-q05-stop-1` | Enter an email address, like name@example.com. |
| `f06-q05-stop-2` | q05 Submit / Button / Double-tap to activate |
| `f06-q06-submit` | q06 Submit / Button / Double-tap to activate |
| `f06-q06-after-submit` | (nothing) |
| `f06-q06-stop-0` | q06 Email / Edit box / Double-tap to edit text. Actions available, use Tap with 3 fingers to view |
| `f06-q06-stop-1` | q06 Submit / Button / Double-tap to activate |
| `f06-native-submit` | (nothing) |
