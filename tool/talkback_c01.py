#!/usr/bin/env python3
"""L4 for C01 Button on Android: capture and check what TalkBack speaks.

Needs a running emulator with TalkBack installed. Sets TalkBack's developer
"Log output level" to VERBOSE through its settings screen (docs/plan.md,
finding K6), turns TalkBack on (restoring the device's accessibility settings
afterwards),
runs C01ButtonTest#talkBackWalk, reads the speech from logcat, checks it, and
writes the transcript to docs/evidence/C01/talkback-android.md.

Usage: python3 tool/talkback_c01.py
"""
import datetime
import os
import re
import subprocess
import sys
import time

from evidence_common import flutter_version

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ADB = os.path.expanduser(os.environ.get("ADB", "~/Library/Android/sdk/platform-tools/adb"))
TALKBACK = "com.google.android.marvin.talkback/com.google.android.marvin.talkback.TalkBackService"
TEST = "dev.fluttera11y.flutter_a11y_techniques.C01ButtonTest#talkBackWalk"

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
}


def adb(*args):
    return subprocess.run([ADB, *args], capture_output=True, text=True).stdout


def screen():
    """Visible texts on the device, with the centre of each."""
    adb("shell", "uiautomator", "dump", "/sdcard/ui.xml")
    xml = adb("shell", "cat", "/sdcard/ui.xml")
    found = []
    for node in re.findall(r"<node [^>]*>", xml):
        attr = lambda k: re.search(k + r'="([^"]*)"', node).group(1)
        text = attr("text") or attr("content-desc")
        if text:
            x1, y1, x2, y2 = map(int, re.findall(r"\d+", attr("bounds")))
            found.append((text, (x1 + x2) // 2, (y1 + y2) // 2))
    return found


def tap(text, scrolls=3):
    for _ in range(scrolls + 1):
        for found, x, y in screen():
            if found == text:
                adb("shell", "input", "tap", str(x), str(y))
                time.sleep(2)
                return
        adb("shell", "input", "swipe", "500", "1800", "500", "600")
        time.sleep(1)
    sys.exit(f'TalkBack settings: could not find "{text}"')


def ensure_verbose_logging():
    """Set TalkBack's developer log level to VERBOSE through its settings UI.

    The level lives in TalkBack's private preferences, which adb cannot write
    on a non-root image. Done with TalkBack off so plain taps work.
    """
    adb("shell", "am", "force-stop", "com.google.android.marvin.talkback")
    adb("shell", "am", "start", "-n",
        "com.google.android.marvin.talkback/com.android.talkback.TalkBackPreferencesActivity")
    time.sleep(3)
    tap("Advanced settings")
    tap("Developer settings")
    texts = [t for t, _, _ in screen()]
    level = texts[texts.index("Log output level") + 1]
    if level != "VERBOSE":
        tap("Log output level")
        tap("VERBOSE")
        tap("Yes, enable verbose logging")
    adb("shell", "input", "keyevent", "HOME")


SERVICES = "enabled_accessibility_services"
ENABLED = "accessibility_enabled"


class AdbError(RuntimeError):
    """An adb command that had to succeed did not."""


def adb_checked(*args):
    """Like adb(), but raises AdbError when the command fails.

    Used for the accessibility settings, where treating a failed command as
    an empty answer would lead to the wrong value being restored.
    """
    run = subprocess.run([ADB, *args], capture_output=True, text=True)
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
    """Runs action() with TalkBack on, then puts the device's accessibility
    settings back exactly as they were, whether or not anything failed.

    Both settings are read before anything is changed; if either read fails,
    nothing is changed. Services are switched off for the settings-screen
    setup, because plain taps do not work while a screen reader is running.
    If a setting cannot be restored, that is reported with the value it
    should have, and raised.
    """
    original = {name: read_setting(name) for name in (SERVICES, ENABLED)}
    try:
        write_setting(SERVICES, "")
        write_setting(ENABLED, "0")
        ensure_verbose_logging()
        write_setting(SERVICES, with_talkback(original[SERVICES]))
        write_setting(ENABLED, "1")
        return action()
    finally:
        failed = []
        for name, value in original.items():
            try:
                write_setting(name, value)
            except AdbError as error:
                failed.append((name, value, error))
        if failed:
            lines = [f"  {name} should be {value!r} ({error})" for name, value, error in failed]
            message = "Could not restore accessibility settings:\n" + "\n".join(lines)
            print(message, file=sys.stderr)
            raise AdbError(message)


def walk():
    """Runs the instrumented walk. Returns the Gradle result and the log."""
    time.sleep(5)
    adb("logcat", "-c")
    run = subprocess.run(
        ["./gradlew", "app:connectedDebugAndroidTest",
         f"-Pandroid.testInstrumentationRunnerArguments.class={TEST}"],
        cwd=os.path.join(ROOT, "android"), capture_output=True, text=True)
    return run, adb("logcat", "-d")


def main():
    # The Gradle wrapper is generated by Flutter, not committed.
    if not os.path.exists(os.path.join(ROOT, "android", "gradlew")):
        sys.exit("android/gradlew is missing. Run `flutter build apk --debug` once first.")
    run, log = run_with_talkback(walk)
    if run.returncode != 0:
        print(run.stdout[-3000:])
        sys.exit("instrumented walk failed")

    spoken, current = {}, None
    for line in log.splitlines():
        m = re.search(r"C01TB\s*: (FOCUS|END) (\S+)", line)
        if m:
            current = m.group(2) if m.group(1) == "FOCUS" else None
            if current:
                spoken[current] = []
            continue
        m = re.search(r'Speaking fragment text="(.*?)", utteranceId', line)
        if m and current:
            spoken[current].append(m.group(1))

    if not any(spoken.values()):
        sys.exit("No speech captured. Is TalkBack's log output level VERBOSE?")

    def said(fragments, phrase):
        """Role and state words must be spoken as their own sentence, so a
        name such as "Close button" does not count as the role."""
        if phrase.lower() in ("button", "disabled"):
            sentences = [t.strip() for f in fragments for t in f.split(".")]
            return phrase.lower() in sentences
        return phrase.lower() in " | ".join(fragments)

    failures = []
    for ident, (must, must_not) in EXPECT.items():
        if ident not in spoken:
            failures.append(f"{ident}: never focused")
            continue
        fragments = [f.lower() for f in spoken[ident]]
        joined = " | ".join(fragments)
        for phrase in must:
            if not said(fragments, phrase):
                failures.append(f'{ident}: expected "{phrase}" in "{joined}"')
        for phrase in must_not:
            if said(fragments, phrase):
                failures.append(f'{ident}: did not expect "{phrase}" in "{joined}"')

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
    out = ["# C01 Button: TalkBack transcript (Android)", "",
           "Generated by `tool/talkback_c01.py`. Do not edit by hand.", ""]
    out += [f"- {k}: {v}" for k, v in meta.items()]
    out += ["", f"Result: {'FAIL' if failures else 'PASS'}", "",
            "| Element | Spoken |", "| --- | --- |"]
    for ident, fragments in spoken.items():
        out.append(f"| `{ident}` | {' / '.join(fragments) or '(nothing)'} |")
    if failures:
        out += ["", "## Failures", ""] + [f"- {f}" for f in failures]
    path = os.path.join(ROOT, "docs", "evidence", "C01", "talkback-android.md")
    with open(path, "w") as f:
        f.write("\n".join(out) + "\n")
    print("\n".join(out))
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
