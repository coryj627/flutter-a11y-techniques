# Working in parallel

Techniques are built in waves. Up to three waves run at once. This page is
the brief for anyone joining one; [the technique guide](technique-guide.md)
and [the checklist](technique-checklist.md) say what a technique must
contain, and nothing here changes that.

## Who does what

- **A wave** is a group of techniques on one theme, with a principal and up
  to two engineers.
- **An engineer** builds one technique at a time, in a worktree of their own,
  and hands it to the principal with every check below run. One technique is
  one pull request.
- **The principal** reviews the engineer's work, runs the Codex adversarial
  review until it approves, opens the pull request, answers Codoki, and
  merges when CI is green on the head commit and Codoki says "Safe to merge".
  The principal merges a wave's pull requests one at a time and rebases the
  next one.
- **The coordinator** starts the waves and talks to the owner.

## Setting up a worktree

Each engineer works in a separate git worktree, on a branch cut from
`origin/main`. In a new worktree:

```
fvm flutter pub get
(cd web_tests && npm ci)
```

`fvm` reads the pinned version from `.fvmrc`. Builds are per worktree.

## What needs the device lock

This Mac has one Android emulator, one iOS simulator, and one VoiceOver, and
every worktree shares them. One lock covers all three
(`tool/device_lock.py`). Whoever holds it has the devices; a second caller
waits and is told who it is waiting for.

**No lock needed**, run these freely and at the same time as anyone else:

- editing, `dart format`, `fvm flutter analyze`, `fvm flutter test`
- `python3 -m unittest discover -s tool -p 'test_*.py'`
- `fvm dart run tool/doc_code.dart` and `fvm dart run tool/technique_list.dart`
- `fvm flutter build web`, and in `web_tests/`: `npx playwright test`, with
  or without spec names, and `npx playwright test -c widgetbook.config.js`.
  Each worktree serves its build on ports of its own, worked out from its
  path (`web_tests/support/ports.js`); set `FA11Y_WEB_PORT` and
  `FA11Y_WIDGETBOOK_PORT` to choose them.
- builds that install nothing: `fvm flutter build apk --debug`,
  `fvm flutter build ios --simulator --debug`,
  `./gradlew app:assembleDebugAndroidTest`, `xcodebuild build-for-testing`

**Lock needed**, anything that touches the emulator, the simulator, or
VoiceOver:

- `python3 tool/evidence.py <ID>` runs everything for one technique under
  the lock: the builds, the Android tree tests, the TalkBack transcript, the
  iOS tree tests, the iOS VoiceOver transcript, the web tree spec, and the
  web VoiceOver transcript. It prints a result per layer. About 25 minutes.
  `--only` and `--skip` choose layers, for example
  `--only android,talkback` while working on one platform.
- `python3 tool/talkback.py <ID>`, `tool/voiceover_ios.py <ID>`, and
  `tool/voiceover_web.py <ID>` take the lock themselves when run alone.
- Everything else goes through `python3 tool/with_devices.py -- <command>`:
  `./gradlew --no-daemon app:connectedDebugAndroidTest …` (no daemon, so
  that the run owns what drives the emulator), `xcodebuild test …`, `adb`,
  `xcrun simctl`, and probes.

Never start a device command without the lock, and do not hold the lock
while thinking: run the command, read the result, release.

When a command run under the lock ends, whatever it started and left
running is ended too, a Gradle daemon included, so the next Gradle build
starts a new one. That is deliberate: nothing started under the lock
outlives it.

The lock is passed down to every command a run starts, so it stays taken
until the last of them has ended, even if the run itself is killed. If a
waiting run says the holder "has ended", something it started is still
alive: `lsof` on the lock file, as the message says, names it. The one
long-lived case is the adb server, which keeps whatever it was started with
(checked on this Mac); the tools start it before they take the lock so that
it never has it, and `adb kill-server` frees a lock it does hold.

The web VoiceOver recording turns VoiceOver on and takes over this Mac's
screen and speech for several minutes. `tool/evidence.py` prints a warning
and waits ten seconds before it. Nothing but `tool/voiceover_web.py` can
start it: the specs in `web_tests/vo/` refuse to load otherwise.

## Probes

A probe is a throwaway `lib/probe.dart`, a second entry point, never
committed; its source is kept as `docs/evidence/probes/<id>/probe.dart.txt`
with what was seen. Build it without the lock, then install and look under
the lock, in one command per platform so that nobody else's build is on the
device in between:

```
fvm flutter build apk --debug -t lib/probe.dart
python3 tool/with_devices.py --label "probe F09 android" -- sh -c \
  'adb install -r build/app/outputs/flutter-apk/app-debug.apk && adb shell monkey -p dev.fluttera11y.flutter_a11y_techniques 1 && sleep 5 && adb exec-out uiautomator dump /dev/tty'

fvm flutter build ios --simulator --debug -t lib/probe.dart
python3 tool/with_devices.py --label "probe F09 ios" -- sh -c \
  'xcrun simctl install booted build/ios/iphonesimulator/Runner.app && xcrun simctl launch booted dev.fluttera11y.flutterA11yTechniques && sleep 60'

fvm flutter build web -t lib/probe.dart   # no lock: a browser on your own port
```

The lock is held for as long as the command runs, so make the command last
as long as the looking does (the `sleep` above, or an `xcodebuild test` of a
probe test class). Rebuild the app without `-t` before running the
technique's own tests.

## Shared files

A technique adds its own files and nothing else, with these exceptions:

- `lib/techniques/all_techniques.dart` and the README lists are generated.
  Run `fvm dart run tool/technique_list.dart`. If a rebase conflicts in
  either, take either side and run it again.
- `docs/flutter-limitations.md`: use the next free id in your wave's range,
  and add the entry at the end of that range in the index and in the
  entries. The ranges are at the top of that file: FL-048 to FL-069 for work
  outside the waves, FL-070 to FL-099 for wave 10, and FL-N00 to FL-N99 for
  wave N from 1 to 9. Two waves never touch the same lines. Two entries from
  one wave can conflict; keep both, in id order.
- `docs/plan.md` is not edited by a wave. A wave's notes (what was built,
  test-tool problems, things for the next wave) go in
  `docs/waves/wave-<n>.md`, one file per wave, which only that wave's
  principal edits.

## Stop and ask

An engineer asks the principal, and the principal asks the coordinator, who
asks the owner, before doing any of these:

- changing what a technique must contain or prove: the checklist's
  requirements, the merge gates, the kinds of example
- dropping evidence the project keeps today
- recording a technique as a limitation with no workaround on a platform
- a decision about scope or design that would need a new numbered decision
- filing anything outside this repository

A disagreement with a review finding is not one of these: fix it, or say
plainly why it is wrong.

## Disk

Each worktree's `build/` grows to about 3 GB once Android and iOS are built.
Keep one `build/` per worktree and one derived-data folder
(`build/ios_uitest`, the path the tools use). When a technique has merged,
delete its worktree, or at least its `build/`, `widgetbook/build/`, and
`android/.gradle/`. Check `df -h /` before a large build; below 10 GB free,
clean first.
