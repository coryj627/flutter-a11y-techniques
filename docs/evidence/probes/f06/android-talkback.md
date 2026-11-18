# F06 probe, round 1: TalkBack

Speech per marker of ProbeF06Test, parsed from logcat with tool/talkback.py's parse_speech. Each stop's focus was forced by the test (ACTION_ACCESSIBILITY_FOCUS), so this shows what is spoken, not the order a swipe would take. TalkBack 17.0, Android 17 emulator, Flutter 3.47.5, 2026-11-18. A line break inside one spoken text is shown as a space.

| Marker | TalkBack spoke |
| --- | --- |
| `f06-p01-stop-0` | abc / Edit box / Flutter A11Y Techniques |
| `f06-p01-stop-1` | abc / Edit box / Double-tap to edit text. Actions available, use Tap with 3 fingers to view |
| `f06-p01-stop-2` | p01 End / Button / Double-tap to activate |
| `f06-p02-stop-0` | p02 Email, /   / Enter an email address, like name@example.com. |
| `f06-p02-stop-1` | Enter an email address, like name@example.com. |
| `f06-p02-stop-2` | abc / Edit box / Double-tap to edit text. Actions available, use Tap with 3 fingers to view |
| `f06-p02-stop-3` | Enter a phone number using digits only. |
| `f06-p02-stop-4` | p02 End / Button / Double-tap to activate |
| `f06-p03-submit` | p03 Check / Button / Double-tap to activate |
| `f06-p03-after-submit` | p03 Email Enter an email address, like name@example.com., /   / Enter an email address, like name@example.com. |
| `f06-p03-stop-0` | Edit box / p03 Email Enter an email address, like name@example.com., |
| `f06-p03-stop-1` | p03 Check / Button / Double-tap to activate |
| `f06-p04-submit` | p04 Submit / Button / Double-tap to activate |
| `f06-p04-after-submit` | p04 Email Enter an email address, like name@example.com., /   / Enter an email address, like name@example.com. |
| `f06-p04-stop-0` | Edit box / p04 Email Enter an email address, like name@example.com., |
| `f06-p04-stop-1` | p04 Submit / Button / Double-tap to activate |
| `f06-p05-submit` | p05 Submit / Button / Double-tap to activate |
| `f06-p05-after-submit` | p05 Email Enter an email address, like name@example.com., /   / Enter an email address, like name@example.com. |
| `f06-p05-stop-0` | Edit box / p05 Name Enter your name., |
| `f06-p05-stop-1` |   / Enter your name. / Edit box / p05 Email Enter an email address, like name@example.com., |
| `f06-p05-stop-2` | p05 Submit / Button / Double-tap to activate |
| `f06-p06-submit` | p06 Submit / Button / Double-tap to activate |
| `f06-p06-after-submit` | p06 Email Enter an email address, like name@example.com., /   / Enter an email address, like name@example.com. |
| `f06-p06-stop-0` | p06 Name Enter your name., /   / Enter your name. / Editing. Edit box |
| `f06-p06-stop-1` | Showing English (US) (QWERTY) |
| `f06-p06-stop-2` | keyboard hidden / p06 Submit / Button / Double-tap to activate |
| `f06-p07-submit` | p07 Submit / Button / Double-tap to activate |
| `f06-p07-after-submit` | p07 Email Enter an email address, like name@example.com., /   / Enter an email address, like name@example.com. |
| `f06-p07-stop-0` | Edit box / p07 Name Enter your name., |
| `f06-p07-stop-1` |   / Enter your name. / Edit box / p07 Email Enter an email address, like name@example.com., |
| `f06-p07-stop-2` | p07 Submit / Button / Double-tap to activate |
| `f06-p08-submit` | p08 Submit / Button / Double-tap to activate |
| `f06-p08-after-submit` | abc / Edit box / p08 Email Enter an email address, like name@example.com., /   / Enter an email address, like name@example.com. Enter an email address, like name@example.com. |
| `f06-p08-stop-0` | (nothing) |
| `f06-p08-stop-1` | Edit box / abc |
| `f06-p08-stop-2` | p08 Submit / Button / Double-tap to activate |
| `f06-p09-submit` | p09 Submit / Button / Double-tap to activate |
| `f06-p09-after-submit` | (nothing) |
| `f06-p09-stop-0` | p09 Email name@example.com Enter an email address, like name@example.com. |
| `f06-p09-stop-1` | p09 Submit / Button / Double-tap to activate |
| `f06-p10-submit` | p10 Submit / Button / Double-tap to activate |
| `f06-p10-after-submit` | Enter an email address, like name@example.com. |
| `f06-p10-stop-0` | p10 Email / Edit box / Double-tap to edit text. Actions available, use Tap with 3 fingers to view |
| `f06-p10-stop-1` | Enter an email address, like name@example.com. |
| `f06-p10-stop-2` | p10 Submit / Button / Double-tap to activate |
| `f06-p11-submit` | p11 Submit / Button / Double-tap to activate |
| `f06-p11-after-submit` | p11 2 errors. Name: Enter your name. Email: Enter an email address, like name@example.com. / p11 Email Enter an email address, like name@example.com., |
| `f06-p11-stop-0` |   / Enter an email address, like name@example.com. |
| `f06-p11-stop-1` | Edit box |
| `f06-p11-stop-2` | p11 Name Enter your name., /   / Enter your name. / Edit box |
| `f06-p11-stop-3` | p11 Submit / Button / Double-tap to activate |
| `f06-p12-submit` | p12 Type x / Button / Double-tap to activate |
| `f06-p12-after-submit` | x / Edit box |
| `f06-p12-stop-0` | x / Edit box / Double-tap to edit text. Actions available, use Tap with 3 fingers to view |
| `f06-p12-stop-1` | p12 Type x / Button / Double-tap to activate |
| `f06-p13-submit` | p13 Submit / Button / Double-tap to activate |
| `f06-p13-after-submit` | Enter an email address, like name@example.com. |
| `f06-p13-stop-0` | p13 Email name@example.com / Edit box |
| `f06-p13-stop-1` | Enter an email address, like name@example.com. |
| `f06-p13-stop-2` | p13 Submit / Button / Double-tap to activate |
