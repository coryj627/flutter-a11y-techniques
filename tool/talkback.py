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
import datetime
import os
import re
import signal
import subprocess
import sys
import time

from evidence_common import TECHNIQUES, flutter_version, technique_argument

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ADB = os.path.expanduser(os.environ.get("ADB", "~/Library/Android/sdk/platform-tools/adb"))
TALKBACK = "com.google.android.marvin.talkback/com.google.android.marvin.talkback.TalkBackService"
PACKAGE = "dev.fluttera11y.flutter_a11y_techniques"
# The instrumented test to run; set from the technique in main().
TEST = f"{PACKAGE}.C01ButtonTest#talkBackWalk"

# identifier -> (phrases that must be spoken, phrases that must not be).
# Compared case-insensitively against everything spoken while the node had
# TalkBack focus.
EXPECT = {
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


# The device log can hold bytes that are not valid UTF-8; replace them
# instead of failing the whole run on a decode error.
DECODE = {"capture_output": True, "encoding": "utf-8", "errors": "replace"}


# No device command may wait forever: a stalled adb would otherwise block the
# restore of the device's settings, which runs with signals held.
ADB_TIMEOUT = 60


def adb(*args):
    """Runs adb and returns its output; "" if it fails or times out."""
    try:
        return subprocess.run([ADB, *args], timeout=ADB_TIMEOUT, **DECODE).stdout
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


def tap(text, scrolls=3):
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
    adb_checked("shell", "am", "force-stop", "com.google.android.marvin.talkback")
    adb_checked("shell", "am", "start", "-n",
                "com.google.android.marvin.talkback/com.android.talkback.TalkBackPreferencesActivity")
    time.sleep(3)
    tap("Advanced settings")
    tap("Developer settings")
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
        run = subprocess.run([ADB, *args], timeout=ADB_TIMEOUT, **DECODE)
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


def walk():
    """Runs the instrumented walk. Returns the Gradle result and the log."""
    time.sleep(5)
    adb("logcat", "-c")
    try:
        run = subprocess.run(
            ["./gradlew", "app:connectedDebugAndroidTest",
             f"-Pandroid.testInstrumentationRunnerArguments.class={TEST}"],
            cwd=os.path.join(ROOT, "android"), timeout=WALK_TIMEOUT, **DECODE)
    except subprocess.TimeoutExpired:
        sys.exit(f"instrumented walk did not finish in {WALK_TIMEOUT // 60} minutes")
    return run, adb("logcat", "-d")


def parse_speech(log):
    """What TalkBack spoke while each identified node had focus."""
    spoken, current = {}, None
    for line in log.splitlines():
        m = re.search(r"[A-Z]\d\dTB\s*: (FOCUS|END) (\S+)", line)
        if m:
            current = m.group(2) if m.group(1) == "FOCUS" else None
            if current:
                spoken[current] = []
            continue
        m = re.search(r'Speaking fragment text="(.*?)", utteranceId', line)
        if m and current:
            spoken[current].append(m.group(1))
    return spoken


def said(fragments, phrase):
    """Role and state words must be spoken as their own sentence, so a name
    such as "Close button" does not count as the role."""
    if phrase.lower() in ("button", "disabled", "heading", "edit box"):
        sentences = [t.strip() for f in fragments for t in f.split(".")]
        return phrase.lower() in sentences
    return phrase.lower() in " | ".join(fragments)


def problems(ident, spoken_fragments):
    """What is wrong with the speech for one element; empty when it is as
    expected. An element with no expectations only has to have been spoken."""
    fragments = [f.lower() for f in spoken_fragments]
    joined = " | ".join(fragments)
    if ident not in EXPECT:
        return [] if fragments else [f"{ident}: nothing was spoken"]
    must, must_not = EXPECT[ident]
    found = [f'{ident}: expected "{phrase}" in "{joined}"'
             for phrase in must if not said(fragments, phrase)]
    found += [f'{ident}: did not expect "{phrase}" in "{joined}"'
              for phrase in must_not if said(fragments, phrase)]
    return found


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
    exit_on_termination_signals()
    try:
        spoken, retried = run_with_talkback(walk_until_heard)
    except AdbError as error:
        sys.exit(str(error))

    if not any(spoken.values()):
        sys.exit("No speech captured. Is TalkBack's log output level VERBOSE?")

    failures = []
    for ident in EXPECT:
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
        "Method": "ACTION_ACCESSIBILITY_FOCUS on each node; speech read from TalkBack's verbose log",
    }
    out = [f"# {title}: TalkBack transcript (Android)", "",
           f"Generated by `python3 tool/talkback.py {technique}`. Do not edit by hand.", ""]
    out += [f"- {k}: {v}" for k, v in meta.items()]
    out += ["", f"Result: {'FAIL' if failures else 'PASS'}"]
    if retried:
        out += ["", "Elements whose speech failed its checks on a walk and were walked again: "
                + ", ".join(f"`{ident}`" for ident in retried) + "."]
    out += ["", "| Element | Spoken |", "| --- | --- |"]
    for ident, fragments in spoken.items():
        out.append(f"| `{ident}` | {' / '.join(fragments) or '(nothing)'} |")
    if failures:
        out += ["", "## Failures", ""] + [f"- {f}" for f in failures]
    os.makedirs(os.path.join(ROOT, "docs", "evidence", technique), exist_ok=True)
    path = os.path.join(ROOT, "docs", "evidence", technique, "talkback-android.md")
    with open(path, "w") as f:
        f.write("\n".join(out) + "\n")
    print("\n".join(out))
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
