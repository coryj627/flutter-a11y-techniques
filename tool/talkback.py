#!/usr/bin/env python3
"""L4 on Android: capture and check what TalkBack speaks for one technique.

Needs a running emulator with TalkBack installed. Sets TalkBack's developer
"Log output level" to VERBOSE through its settings screen (docs/plan.md,
finding K6), turns TalkBack on (restoring the log level and the device's
accessibility settings afterwards),
runs the technique's talkBackWalk instrumented test, reads the speech from logcat, checks it, and
writes the transcript to docs/evidence/<ID>/talkback-android.md.

Usage: python3 tool/talkback.py <ID>     for example: python3 tool/talkback.py C01
"""
import collections
import datetime
import os
import re
import signal
import subprocess
import sys
import time

import device_lock
from evidence_common import (GRADLE_UNSHARED, REGISTRATIONS, TECHNIQUES, flutter_version,
                             stop_android_tests, technique_argument)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ADB = os.path.expanduser(os.environ.get("ADB", "~/Library/Android/sdk/platform-tools/adb"))
TALKBACK = "com.google.android.marvin.talkback/com.google.android.marvin.talkback.TalkBackService"
PACKAGE = "dev.fluttera11y.flutter_a11y_techniques"
# The instrumented test to run; set from the technique in main().
TEST = f"{PACKAGE}.C01ButtonTest#talkBackWalk"

# identifier -> (phrases that must be spoken, phrases that must not be).
# Compared case-insensitively against everything spoken while the node had
# TalkBack focus. Each technique's entries are in its file in
# tool/techniques/.
EXPECT = {ident: expected for r in REGISTRATIONS.values()
          for ident, expected in r.talkback_expect.items()}


# The device log can hold bytes that are not valid UTF-8; replace them
# instead of failing the whole run on a decode error.
DECODE = {"capture_output": True, "encoding": "utf-8", "errors": "replace"}


# No device command may wait forever: a stalled adb would otherwise block the
# restore of the device's settings, which runs with signals held.
ADB_TIMEOUT = 60


def adb(*args):
    """Runs adb and returns its output; "" if it fails or times out."""
    try:
        return subprocess.run([ADB, *args], timeout=ADB_TIMEOUT, **DECODE, **device_lock.child_fds()).stdout
    except subprocess.TimeoutExpired:
        return ""


def screen():
    """Visible texts on the device, with the centre of each.

    The UI dump fails now and then while the screen is still settling, so it
    is tried a few times before the failure is raised.
    """
    for attempt in range(3):
        try:
            adb_checked("shell", "uiautomator", "dump", "/sdcard/ui.xml")
            xml = adb_checked("shell", "cat", "/sdcard/ui.xml")
            break
        except AdbError:
            if attempt == 2:
                raise
            time.sleep(1)
    found = []
    for node in re.findall(r"<node [^>]*>", xml):
        attr = lambda k: re.search(k + r'="([^"]*)"', node).group(1)
        text = attr("text") or attr("content-desc")
        if text:
            x1, y1, x2, y2 = map(int, re.findall(r"\d+", attr("bounds")))
            found.append((text, (x1 + x2) // 2, (y1 + y2) // 2))
    return found


def tap(text, scrolls=5):
    """Taps the element showing text, scrolling to find it. Raises AdbError
    if it is not found or the tap command fails."""
    for _ in range(scrolls + 1):
        for found, x, y in screen():
            if found == text:
                adb_checked("shell", "input", "tap", str(x), str(y))
                time.sleep(2)
                return
        adb_checked("shell", "input", "swipe", "500", "1800", "500", "600")
        time.sleep(1)
    raise AdbError(f'TalkBack settings: could not find "{text}"')


LOG_LEVELS = ("NONE", "ASSERT", "ERROR", "WARN", "INFO", "DEBUG", "VERBOSE")


class AdbError(RuntimeError):
    """A device command or screen read that had to succeed did not."""


def current_log_level(texts):
    """The level shown under "Log output level" in the given screen texts.

    Raises AdbError when the screen dump is missing, cut short, or shows
    something that is not a log level, so a bad read is never mistaken for a
    level to restore.
    """
    if "Log output level" not in texts:
        raise AdbError('TalkBack settings: "Log output level" is not on screen')
    index = texts.index("Log output level") + 1
    if index >= len(texts) or texts[index] not in LOG_LEVELS:
        shown = texts[index] if index < len(texts) else "nothing"
        raise AdbError(f"TalkBack settings: expected a log level, found {shown!r}")
    return texts[index]


SETTINGS_TRIES = 3


def open_developer_settings():
    """Opens TalkBack's settings and goes to its developer settings.

    A tap made while the settings screen is still opening is lost, and the
    next screen is then never reached ("could not find Developer settings";
    seen on about half the runs on 2026-11-16, with builds running beside
    the emulator). So the whole way there is tried again from a freshly
    started settings screen, with a longer wait each time. Only getting
    there is repeated: nothing has been changed yet.
    """
    for attempt in range(SETTINGS_TRIES):
        adb_checked("shell", "am", "force-stop", "com.google.android.marvin.talkback")
        adb_checked("shell", "am", "start", "-n",
                    "com.google.android.marvin.talkback/"
                    "com.android.talkback.TalkBackPreferencesActivity")
        time.sleep(3 + 3 * attempt)
        try:
            tap("Advanced settings")
            tap("Developer settings")
            return
        except AdbError as error:
            if attempt + 1 == SETTINGS_TRIES or "could not find" not in str(error):
                raise


def set_log_level(level, on_read=None):
    """Sets TalkBack's developer "Log output level" through its settings UI
    and returns the level it had before.

    The level lives in TalkBack's private preferences, which adb cannot write
    on a non-root image. Must be called with screen readers off so plain taps
    work. on_read, if given, is called with the current level before anything
    is changed, so the caller knows what to restore even if the change fails.

    Every device command is checked, and after a change the level is read
    back from the screen: a tap that did nothing raises AdbError instead of
    passing as success.
    """
    open_developer_settings()
    previous = current_log_level([t for t, _, _ in screen()])
    if on_read:
        on_read(previous)
    if previous != level:
        tap("Log output level")
        tap(level)
        if level == "VERBOSE":
            tap("Yes, enable verbose logging")
        now = current_log_level([t for t, _, _ in screen()])
        if now != level:
            raise AdbError(f"TalkBack log output level is {now}, not {level}, after setting it")
    adb_checked("shell", "input", "keyevent", "HOME")
    return previous


SERVICES = "enabled_accessibility_services"
ENABLED = "accessibility_enabled"


def adb_checked(*args):
    """Like adb(), but raises AdbError when the command fails or times out.

    Used for the accessibility settings, where treating a failed command as
    an empty answer would lead to the wrong value being restored.
    """
    try:
        run = subprocess.run([ADB, *args], timeout=ADB_TIMEOUT, **DECODE, **device_lock.child_fds())
    except subprocess.TimeoutExpired:
        raise AdbError(f"adb {' '.join(args)} did not finish in {ADB_TIMEOUT} seconds") from None
    if run.returncode != 0:
        raise AdbError(f"adb {' '.join(args)} failed: {run.stderr.strip() or run.returncode}")
    return run.stdout


def read_setting(name):
    """A secure setting's value: None when it is not set, "" when it is set
    to nothing (a valid state for the services list).

    `settings get` prints "null" for an unset setting and a bare newline for
    an empty one. No output at all is not an answer, so it is an error.
    """
    output = adb_checked("shell", "settings", "get", "secure", name)
    if output == "":
        raise AdbError(f"adb returned nothing for secure setting {name}")
    value = output.strip()
    return None if value == "null" else value


def write_setting(name, value):
    """Sets a secure setting, or deletes it when value is None."""
    if value is None:
        adb_checked("shell", "settings", "delete", "secure", name)
    else:
        # An empty value must reach the device shell as a quoted empty string.
        adb_checked("shell", "settings", "put", "secure", name, value or '""')


def with_talkback(services):
    """The service list with TalkBack added, keeping what was already on."""
    current = [s for s in (services or "").split(":") if s]
    return ":".join(current if TALKBACK in current else current + [TALKBACK])


def run_with_talkback(action):
    """Runs action() with TalkBack on and logging what it speaks, then puts
    the device back exactly as it was, whether or not anything failed:
    TalkBack's log level first, then the accessibility settings.

    Both settings are read before anything is changed; if either read fails,
    nothing is changed. Services are switched off while the settings screen
    is driven, because plain taps do not work while a screen reader is
    running. Verbose logging is not left on, because it would keep writing
    everything TalkBack speaks to the device log. Anything that cannot be
    restored is reported with the value it should have, and raised.
    """
    original = {name: read_setting(name) for name in (SERVICES, ENABLED)}
    level = {}
    try:
        write_setting(SERVICES, "")
        write_setting(ENABLED, "0")
        set_log_level("VERBOSE", on_read=lambda value: level.update(original=value))
        write_setting(SERVICES, with_talkback(original[SERVICES]))
        write_setting(ENABLED, "1")
        return action()
    finally:
        # Nothing may cut the restore short: signals that arrive during it are
        # held and honoured once the device is back as it was.
        with signals_deferred():
            failed = []
            try:
                if level.get("original", "VERBOSE") != "VERBOSE":
                    write_setting(SERVICES, "")
                    write_setting(ENABLED, "0")
                    set_log_level(level["original"])
            # An error here is reported below. Whatever happens, including an
            # exception this does not catch, the finally underneath still
            # restores the accessibility settings. Interrupts are not caught:
            # signals are held for this whole block, and an interrupt raised
            # some other way keeps its own meaning for the caller.
            except Exception as error:
                failed.append(
                    f"  TalkBack log output level should be {level['original']} "
                    f"({type(error).__name__}: {error})")
            finally:
                for name, value in original.items():
                    try:
                        write_setting(name, value)
                    except AdbError as error:
                        failed.append(f"  {name} should be {value!r} ({error})")
            if failed:
                message = "Could not restore the device:\n" + "\n".join(failed)
                print(message, file=sys.stderr)
                raise AdbError(message)


DEFERRABLE = ("SIGINT", "SIGTERM", "SIGHUP")


class signals_deferred:
    """Holds interrupt and termination signals for the length of a block.

    A signal received inside the block is remembered, not acted on. When the
    block ends the previous handlers are put back and, if a signal arrived,
    the script exits with that signal's status.
    """

    def __enter__(self):
        self.pending = None
        self.previous = {}

        def hold(signum, frame):
            self.pending = signum

        for name in DEFERRABLE:
            if hasattr(signal, name):
                signum = getattr(signal, name)
                self.previous[signum] = signal.signal(signum, hold)
        return self

    def __exit__(self, *exc):
        for signum, handler in self.previous.items():
            signal.signal(signum, handler)
        if self.pending is not None:
            sys.exit(128 + self.pending)
        return False


WALK_TIMEOUT = 20 * 60


UNCONFIRMED_EMULATOR = ("The app or its tests could not be shown to have stopped on the "
                        "emulator. Nothing more was run; check the emulator before running again.")


def walk():
    """Runs the instrumented walk. Returns the Gradle result and the log."""
    # Not on an emulator where an earlier test may still be running.
    if not stop_android_tests():
        sys.exit(UNCONFIRMED_EMULATOR)
    time.sleep(5)
    adb("logcat", "-c")
    try:
        # Holds the device lock too. However it ends (by itself, at the
        # timeout, or because this tool is stopped), everything Gradle
        # started is gone before the device's settings are put back.
        run = device_lock.run_to_the_end(
            # No daemon: one left by an earlier build is not ours to stop,
            # and would go on driving the emulator after a timeout.
            ["./gradlew", *GRADLE_UNSHARED, "app:connectedDebugAndroidTest",
             f"-Pandroid.testInstrumentationRunnerArguments.class={TEST}"],
            cwd=os.path.join(ROOT, "android"), timeout=WALK_TIMEOUT,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, encoding="utf-8", errors="replace")
    except subprocess.TimeoutExpired:
        sys.exit(f"instrumented walk did not finish in {WALK_TIMEOUT // 60} minutes")
    finally:
        # However the Gradle run ended, the test inside the emulator must be
        # over before the device's settings are put back or anyone else
        # gets the device.
        cleaned = stop_android_tests()
    if not cleaned:
        sys.exit(UNCONFIRMED_EMULATOR)
    return run, adb("logcat", "-d")


SPEECH_TAG = "talkback: SpeechControllerImpl: "

# Put in an element's speech when a fragment spoken during its focus was cut
# off in the log. Its words are lost, so nothing may be concluded from what
# was captured: problems() reports it and the element is walked again.
INCOMPLETE = "[speech capture was cut off]"


def parse_speech(log, cut=None, closed=None):
    """What TalkBack spoke while each identified node had focus.

    A spoken text with a line break in it (a merged node such as "Delivered",
    new line, "Order 1042") is split by logcat over several lines, each with
    the same prefix. Those lines are joined, with a space where the break was.
    Only a line from TalkBack's speech controller can continue a fragment. A
    fragment that is cut off by a marker, by another fragment, or by any
    other log line is never credited to an element; INCOMPLETE is recorded
    for the element that had focus, so its speech fails its checks.

    If `cut` is a dict, the lines captured of each cut-off fragment, joined
    as above, are added to cut[element]: whole lines of what was said, since
    logcat splits a fragment where its text has a line break. Only
    walk_strictly uses them; the speech returned is the same either way.

    If `closed` is a set, each element whose capture was ended by a marker
    (the next FOCUS, or END) is added to it: an element missing from it was
    still being captured when the log ended. Only walk_strictly uses it, for
    silent rows (SILENT); the speech returned is the same either way.
    """
    spoken, current, open_fragment = {}, None, None

    def drop():
        nonlocal open_fragment
        if open_fragment is not None and current:
            spoken[current].append(INCOMPLETE)
            if cut is not None:
                cut.setdefault(current, []).append(" ".join(open_fragment))
        open_fragment = None

    for line in log.splitlines():
        marker = re.search(r"[A-Z]\d\dTB\s*: (FOCUS|END) (\S+)", line)
        if marker:
            drop()
            if current and closed is not None:
                closed.add(current)
            current = marker.group(2) if marker.group(1) == "FOCUS" else None
            if current:
                spoken[current] = []
            continue
        whole = re.search(r'Speaking fragment text="(.*?)", utteranceId', line)
        if whole:
            drop()
            if current:
                spoken[current].append(whole.group(1))
            continue
        start = re.search(r'Speaking fragment text="(.*)$', line)
        if start:
            drop()
            if SPEECH_TAG in line:
                open_fragment = [start.group(1)]
            continue
        if open_fragment is None:
            continue
        if SPEECH_TAG not in line:
            # Some other log line: the fragment was not finished.
            drop()
            continue
        rest = line.split(SPEECH_TAG, 1)[1]
        end = re.match(r'(.*?)", utteranceId', rest)
        if end:
            if current:
                spoken[current].append(" ".join(open_fragment + [end.group(1)]))
            open_fragment = None
        else:
            open_fragment.append(rest)
    drop()
    return spoken


def said(fragments, phrase):
    """Role and state words must be spoken on their own, so a name such as
    "Close button" does not count as the role, "Bluetooth on" does not count
    as the state "on", and "not checked" does not count as "checked". A role
    word is a sentence of its own; a state word is a sentence or a part of
    one between commas, since TalkBack says "Off, Repeat" as well as "off."."""
    word = phrase.lower()
    if word in ("button", "disabled", "heading", "edit box", "switch",
                "check box", "slider", "image"):
        sentences = [t.strip() for f in fragments for t in f.split(".")]
        return word in sentences
    if word in ("on", "off", "checked", "not checked"):
        parts = [t.strip() for f in fragments for t in re.split(r"[.,]", f)]
        return word in parts
    return word in " | ".join(fragments)


def problems(ident, spoken_fragments):
    """What is wrong with the speech for one element; empty when it is as
    expected. An element with no expectations only has to have been spoken."""
    if INCOMPLETE in spoken_fragments:
        return [f"{ident}: speech capture was cut off; what was said is not known"]
    fragments = [f.lower() for f in spoken_fragments]
    joined = " | ".join(fragments)
    if ident not in EXPECT:
        return [] if fragments else [f"{ident}: nothing was spoken"]
    must, must_not = EXPECT[ident]
    found = [f'{ident}: expected "{phrase}" in "{joined}"'
             for phrase in must if not said(fragments, phrase)]
    found += [f'{ident}: did not expect "{phrase}" in "{joined}"'
              for phrase in must_not if unwanted(fragments, phrase)]
    return found


def unwanted(fragments, phrase):
    """Whether a phrase that must not be spoken was. An element that must
    not say "checked" must not say "not checked" either: the expectations
    that forbid "checked" mean that no checked state is spoken at all
    (FL-045, FL-100), and are written to fail when one starts to be."""
    if phrase.lower() == "checked" and said(fragments, "not checked"):
        return True
    return said(fragments, phrase)


MAX_WALKS = 3


def walk_until_heard(walk_once=None):
    """Walks the examples until every element's speech is as expected.

    Speech capture on a device is not perfectly repeatable: now and then
    TalkBack says nothing for an element it was moved to, or a system
    notification is spoken over it (both seen on the emulator). An element
    whose speech fails its checks is walked again, up to MAX_WALKS walks, and
    only that element's speech is replaced. One that still fails is reported
    as a failure with what was last heard.

    Returns the speech per element and the elements that needed another walk,
    which the transcript lists so a retry is never hidden.
    """
    walk_once = walk_once or walk
    spoken, retried = {}, []
    for attempt in range(MAX_WALKS):
        run, log = walk_once()
        if run.returncode != 0:
            print(run.stdout[-3000:])
            sys.exit("instrumented walk failed")
        for ident, fragments in parse_speech(log).items():
            if ident not in spoken or problems(ident, spoken[ident]):
                spoken[ident] = fragments
        wrong = sorted(ident for ident, fragments in spoken.items()
                       if problems(ident, fragments))
        if spoken and not wrong:
            break
        retried = sorted(set(retried) | set(wrong))
    return spoken, retried


# Techniques whose TalkBack walk is judged whole (walk_strictly), not row by
# row across walks (walk_until_heard). Every other technique keeps
# walk_until_heard.
STRICT = {"C05", "C06", "C13", "C18", "C26", "S08", "S09", "S10"}

# A row of a strict technique that must be silent declares it with this as
# its only required phrase: (["(must be silent)"], []). judge_walk then
# requires the row to have been captured from its start marker to the next
# marker with nothing spoken at all, and the row after it in the walk, its
# liveness control, to be right; any speech in it is a wrong reading. Only
# walk_strictly knows it: walk_until_heard would look for the phrase.
SILENT = "(must be silent)"


def is_silent(ident):
    """Whether `ident` is declared silent (SILENT)."""
    return ident in EXPECT and list(EXPECT[ident][0]) == [SILENT]

# One walk of walk_strictly: the speech per element, the verdict ("right",
# "wrong", or "incomplete"), what made it so, and the captured lines of each
# cut-off fragment per element (parse_speech's `cut`).
Try = collections.namedtuple("Try", ["spoken", "verdict", "reasons", "cut"], defaults=[{}])


def forbidden(ident, fragments):
    """The phrases that must not be spoken for `ident` that `fragments`
    hold, as problems() words them."""
    if ident not in EXPECT:
        return []
    fragments = [f.lower() for f in fragments]
    joined = " | ".join(fragments)
    return [f'{ident}: did not expect "{phrase}" in "{joined}"'
            for phrase in EXPECT[ident][1] if unwanted(fragments, phrase)]


def judge_walk(spoken, expected, cut=None, closed=None):
    """The verdict on one whole walk: (verdict, reasons).

    "incomplete" only for a capture that is shown to be short: an expected
    element that was never focused, one for which nothing was spoken, or one
    whose speech capture was cut off with nothing wrong in what was
    captured. An element whose capture was cut off is checked for the
    phrases it must not say in every fragment captured whole and in the
    captured lines of the cut-off one (`cut`, from parse_speech): those
    lines are whole lines of what was said, so a forbidden phrase in them
    was said, and the reading is wrong. A required phrase it lacks may be in
    the lost part, so that alone makes it incomplete. Anything else that
    fails its checks is a wrong reading, and a wrong reading anywhere makes
    the walk "wrong", even when other elements of it are incomplete.

    A row declared silent (SILENT) is judged apart. Anything spoken in it,
    a cut-off fragment included, is a wrong reading. It is right only when
    its capture was ended by a marker (`closed`, from parse_speech) and the
    row logged after it, its liveness control, is an expected row that is
    not silent and is right by the rules above; otherwise it is incomplete.
    A walk with no silent rows is judged as before, `closed` unused.
    """
    cut = cut or {}
    closed = closed if closed is not None else set()
    order = list(spoken)
    gaps, wrong = [], []
    for ident in expected:
        fragments = spoken.get(ident)
        if fragments is None:
            gaps.append(f"{ident}: never focused")
        elif is_silent(ident):
            heard = [f for f in fragments if f != INCOMPLETE] + cut.get(ident, [])
            if fragments:
                text = " | ".join(heard) or INCOMPLETE
                wrong.append(f'{ident}: expected silence, heard "{text}"')
                continue
            if ident not in closed:
                gaps.append(f"{ident}: the capture was not ended by a marker")
                continue
            after = order[order.index(ident) + 1] if order.index(ident) + 1 < len(order) else None
            if after is None or after not in expected or is_silent(after):
                gaps.append(f"{ident}: no liveness control after it")
                continue
            control = spoken[after]
            if not control or INCOMPLETE in control or problems(after, control):
                # A wrong control is reported as its own row.
                gaps.append(f"{ident}: its liveness control, {after}, is not right")
        elif not fragments:
            gaps.append(f"{ident}: nothing was spoken")
        elif INCOMPLETE in fragments:
            heard = [f for f in fragments if f != INCOMPLETE] + cut.get(ident, [])
            said_wrong = forbidden(ident, heard)
            if said_wrong:
                wrong += said_wrong
            else:
                gaps.append(f"{ident}: speech capture was cut off")
        else:
            wrong += problems(ident, fragments)
    if wrong:
        return "wrong", wrong
    if gaps:
        return "incomplete", gaps
    return "right", []


def walk_strictly(prefix, walk_once=None):
    """Walks the examples of the technique whose identifiers start with
    `prefix`, judging each walk whole (judge_walk).

    A walk with a wrong reading fails for good: no further walk is made.
    Only an incomplete walk is walked again, up to MAX_WALKS walks, and the
    walk that decides is judged on its own: no element's speech is taken
    from another walk. Returns every walk made, in order (Try), so that the
    transcript lists each one.
    """
    walk_once = walk_once or walk
    expected = [ident for ident in EXPECT if ident.startswith(prefix)]
    tries = []
    for attempt in range(MAX_WALKS):
        run, log = walk_once()
        if run.returncode != 0:
            print(run.stdout[-3000:])
            sys.exit("instrumented walk failed")
        cut, closed = {}, set()
        spoken = parse_speech(log, cut, closed)
        verdict, reasons = judge_walk(spoken, expected, cut, closed)
        tries.append(Try(spoken, verdict, reasons, cut))
        if verdict != "incomplete":
            break
    return tries


def strict_report(tries):
    """The failures and the transcript lines after the metadata for the walks
    of walk_strictly: the result, each walk's verdict, the table of the walk
    that decided, and the table of every earlier walk."""
    last = tries[-1]
    failures = [] if last.verdict == "right" else last.reasons
    out = ["", f"Result: {'FAIL' if failures else 'PASS'}", ""]
    out.append(f"Walks: {len(tries)}. Each walk is judged whole: a wrong reading fails for good, "
               "and only a walk shown to be incomplete (an element never focused, silent, or "
               "cut off in the log) is walked again.")
    out.append("")
    out += [f"- Walk {n}: {t.verdict}" + (f" ({'; '.join(t.reasons)})" if t.reasons else "")
            for n, t in enumerate(tries, 1)]

    def table(walk):
        rows = ["| Element | Spoken |", "| --- | --- |"]
        for ident, fragments in walk.spoken.items():
            text = ' / '.join(fragments) or '(nothing)'
            if walk.cut.get(ident):
                text += " (captured of the cut-off speech: " + " / ".join(
                    f'"{c}"' for c in walk.cut[ident]) + ")"
            rows.append(f"| `{ident}` | {text} |")
        return rows

    out += ["", f"## Walk {len(tries)} ({last.verdict})", ""] + table(last)
    for n, t in enumerate(tries[:-1], 1):
        out += ["", f"## Walk {n} ({t.verdict})", ""] + table(t)
    if failures:
        out += ["", "## Failures", ""] + [f"- {f}" for f in failures]
    return failures, out


DEFAULT_METHOD = "ACTION_ACCESSIBILITY_FOCUS on each node; speech read from TalkBack's verbose log"
METHODS = {tid: r.talkback_method for tid, r in REGISTRATIONS.items() if r.talkback_method}


def exit_on_termination_signals():
    """Makes SIGTERM and SIGHUP end the script by raising SystemExit.

    By default they kill the process outright, skipping every finally block,
    which would leave the device with TalkBack and verbose logging on or with
    its services switched off. Raised as an exception, the signal unwinds
    through run_with_talkback's cleanup like Ctrl-C does. Call before any
    device setting is changed.
    """
    def stop(signum, frame):
        sys.exit(128 + signum)

    for name in ("SIGTERM", "SIGHUP"):
        if hasattr(signal, name):  # SIGHUP does not exist on Windows
            signal.signal(getattr(signal, name), stop)


def main():
    global TEST
    technique = technique_argument(sys.argv, "Usage: python3 tool/talkback.py <ID>")
    title, android_test = TECHNIQUES[technique][:2]
    TEST = f"{PACKAGE}.{android_test}#talkBackWalk"
    prefix = technique.lower() + "-"
    # The Gradle wrapper is generated by Flutter, not committed.
    if not os.path.exists(os.path.join(ROOT, "android", "gradlew")):
        sys.exit("android/gradlew is missing. Run `flutter build apk --debug` once first.")
    # The emulator is shared with every other run (tool/device_lock.py).
    device_lock.hold_for_process(f"talkback {technique}")
    # Before any setting is changed or the settings screen is driven: a test
    # left running by an earlier run would tap through all of it.
    if not stop_android_tests():
        sys.exit(UNCONFIRMED_EMULATOR)
    exit_on_termination_signals()
    strict = technique in STRICT
    try:
        if strict:
            tries = run_with_talkback(lambda: walk_strictly(prefix))
        else:
            spoken, retried = run_with_talkback(walk_until_heard)
    except AdbError as error:
        sys.exit(str(error))

    if strict:
        if not any(any(t.spoken.values()) for t in tries):
            sys.exit("No speech captured. Is TalkBack's log output level VERBOSE?")
    elif not any(spoken.values()):
        sys.exit("No speech captured. Is TalkBack's log output level VERBOSE?")

    failures = []
    for ident in EXPECT if not strict else ():
        if not ident.startswith(prefix):
            continue
        if ident not in spoken:
            failures.append(f"{ident}: never focused")
        else:
            failures += problems(ident, spoken[ident])

    version = re.search(r"versionName=(\S+)", adb("shell", "dumpsys", "package",
                                                   "com.google.android.marvin.talkback"))
    meta = {
        "Date": datetime.date.today().isoformat(),
        "Device": adb("shell", "getprop", "ro.product.model").strip() + " (emulator)",
        "Android": adb("shell", "getprop", "ro.build.version.release").strip(),
        "TalkBack": version.group(1) if version else "unknown",
        "Flutter": flutter_version(),
        "Method": METHODS.get(technique, DEFAULT_METHOD),
    }
    out = [f"# {title}: TalkBack transcript (Android)", "",
           f"Generated by `python3 tool/talkback.py {technique}`. Do not edit by hand.", ""]
    out += [f"- {k}: {v}" for k, v in meta.items()]
    if strict:
        failures, body = strict_report(tries)
        write_transcript(technique, out + body)
        sys.exit(1 if failures else 0)
    out += ["", f"Result: {'FAIL' if failures else 'PASS'}"]
    if retried:
        out += ["", "Elements whose speech failed its checks on a walk and were walked again: "
                + ", ".join(f"`{ident}`" for ident in retried) + "."]
    out += ["", "| Element | Spoken |", "| --- | --- |"]
    for ident, fragments in spoken.items():
        out.append(f"| `{ident}` | {' / '.join(fragments) or '(nothing)'} |")
    if failures:
        out += ["", "## Failures", ""] + [f"- {f}" for f in failures]
    write_transcript(technique, out)
    sys.exit(1 if failures else 0)


def write_transcript(technique, out):
    """Writes the transcript lines `out` to the technique's
    docs/evidence/<ID>/talkback-android.md and prints them."""
    os.makedirs(os.path.join(ROOT, "docs", "evidence", technique), exist_ok=True)
    path = os.path.join(ROOT, "docs", "evidence", technique, "talkback-android.md")
    with open(path, "w") as f:
        f.write("\n".join(out) + "\n")
    print("\n".join(out))


if __name__ == "__main__":
    main()
