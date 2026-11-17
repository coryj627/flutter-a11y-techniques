"""Shared helpers for the evidence scripts in tool/."""
import collections
import contextlib
import json
import os
import re
import signal
import subprocess
import time
import types

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Gradle arguments for anything run under the device lock. What a command
# starts under the lock is ended with it, so it must start nothing that a
# build in another worktree could come to share: no Gradle daemon, and the
# Kotlin compiler inside Gradle's own process and not in Kotlin's daemon.
KOTLIN_IN_PROCESS = "kotlin.compiler.execution.strategy=in-process"
GRADLE_UNSHARED = ["--no-daemon", "-P" + KOTLIN_IN_PROCESS]
TECHNIQUES_DIR = os.path.join(ROOT, "tool", "techniques")


# Each technique with screen reader evidence has one file in tool/techniques/,
# named like its folder in lib/techniques/: tool/techniques/f08_radio_group.py
# for lib/techniques/f08_radio_group/. The file sets these names and no
# others:
#
#   ID                    "F08". Must match the file name.
#   TITLE                 "F08 Radio group", the title of the transcripts.
#   ANDROID_TEST          the instrumented test class, or None.
#   IOS_TEST              the XCUITest class, or None.
#   WEB_VO_SPEC           the spec in web_tests/vo/, or None. None means that
#                         platform has no screen reader test for the technique.
#   TALKBACK_EXPECT       tool/talkback.py: identifier -> (phrases that must be
#                         spoken, phrases that must not be). Every identifier
#                         starts with the id in lower case and a hyphen.
#   TALKBACK_METHOD       optional; how the TalkBack speech was captured.
#   VOICEOVER_IOS_METHOD  optional; (how the speech was captured, heading of
#                         the transcript column) for tool/voiceover_ios.py.
#   VOICEOVER_WEB_METHOD  optional; how the speech was captured, for
#                         tool/voiceover_web.py.
#
# A missing optional name means the tool's default. A file that breaks any of
# these rules, or two files with the same id, stop every tool with an error.
Registration = collections.namedtuple("Registration", [
    "id", "title", "android_test", "ios_test", "web_vo_spec", "talkback_expect",
    "talkback_method", "voiceover_ios_method", "voiceover_web_method", "path"])

_REQUIRED = ("ID", "TITLE", "ANDROID_TEST", "IOS_TEST", "WEB_VO_SPEC", "TALKBACK_EXPECT")
_OPTIONAL = ("TALKBACK_METHOD", "VOICEOVER_IOS_METHOD", "VOICEOVER_WEB_METHOD")
_FILE_NAME = re.compile(r"([a-z])(\d\d)_[a-z0-9]+(?:_[a-z0-9]+)*\.py")


class RegistrationError(Exception):
    """A file in tool/techniques/ is not a valid registration."""


def _is_text(value):
    return isinstance(value, str) and value.strip() != ""


def _is_phrases(value):
    return isinstance(value, list) and all(_is_text(p) for p in value)


def _check(module, path, expected_id):
    """The registration in a loaded module. Raises RegistrationError."""
    def fail(message):
        raise RegistrationError(f"{path}: {message}")

    names = {n for n in vars(module) if not n.startswith("_")}
    missing = [n for n in _REQUIRED if n not in names]
    if missing:
        fail(f"missing {', '.join(missing)}")
    unknown = sorted(names - set(_REQUIRED) - set(_OPTIONAL))
    if unknown:
        fail(f"unknown name(s) {', '.join(unknown)}; allowed: {', '.join(_REQUIRED + _OPTIONAL)}")
    get = lambda name: getattr(module, name, None)

    if get("ID") != expected_id:
        fail(f"ID is {get('ID')!r}, but the file name says {expected_id!r}")
    if not _is_text(get("TITLE")) or not get("TITLE").startswith(expected_id + " "):
        fail(f'TITLE must be a string that starts with "{expected_id} "')
    for name in ("ANDROID_TEST", "IOS_TEST"):
        value = get(name)
        if value is not None and not (isinstance(value, str) and re.fullmatch(r"[A-Za-z_]\w*", value)):
            fail(f"{name} must be a class name or None, not {value!r}")
    spec = get("WEB_VO_SPEC")
    if spec is not None and not (isinstance(spec, str) and re.fullmatch(r"[a-z0-9_]+_vo\.spec\.js", spec)):
        fail(f"WEB_VO_SPEC must be a file name ending in _vo.spec.js, or None, not {spec!r}")

    expect = get("TALKBACK_EXPECT")
    if not isinstance(expect, dict):
        fail("TALKBACK_EXPECT must be a dict")
    prefix = expected_id.lower() + "-"
    for ident, value in expect.items():
        if not (isinstance(ident, str) and ident.startswith(prefix) and len(ident) > len(prefix)):
            fail(f'TALKBACK_EXPECT identifier {ident!r} does not start with "{prefix}"')
        if not (isinstance(value, tuple) and len(value) == 2
                and _is_phrases(value[0]) and _is_phrases(value[1])):
            fail(f"TALKBACK_EXPECT[{ident!r}] must be (list of phrases, list of phrases)")

    for name in ("TALKBACK_METHOD", "VOICEOVER_WEB_METHOD"):
        if name in names and not _is_text(get(name)):
            fail(f"{name} must be a non-empty string")
    ios = get("VOICEOVER_IOS_METHOD")
    if "VOICEOVER_IOS_METHOD" in names and not (
            isinstance(ios, tuple) and len(ios) == 2 and all(_is_text(v) for v in ios)):
        fail("VOICEOVER_IOS_METHOD must be (method, column heading)")

    return Registration(
        expected_id, get("TITLE"), get("ANDROID_TEST"), get("IOS_TEST"), spec, dict(expect),
        get("TALKBACK_METHOD"), ios, get("VOICEOVER_WEB_METHOD"), path)


def load_techniques(directory=TECHNIQUES_DIR):
    """Every registration in `directory`, by id, in file name order.

    Raises RegistrationError for a file with a name that is not
    <id>_<name>.py, a file that cannot be loaded or breaks the rules above,
    two files with the same id, or a directory with no registrations.
    """
    found = {}
    for name in sorted(os.listdir(directory)):
        path = os.path.join(directory, name)
        if name == "__pycache__" or name.startswith("."):
            continue
        match = _FILE_NAME.fullmatch(name)
        if not match or not os.path.isfile(path):
            raise RegistrationError(
                f"{path}: not a registration; files here are named like f08_radio_group.py")
        expected_id = (match.group(1) + match.group(2)).upper()
        if expected_id in found:
            raise RegistrationError(
                f"{path}: id {expected_id} is already registered by {found[expected_id].path}")
        # Run from source every time. The import system would keep bytecode
        # in __pycache__, keyed on the file's size and whole-second time, and
        # a file edited twice in a second at the same size would load stale.
        module = types.ModuleType(f"technique_registration_{name[:-3]}")
        module.__file__ = path
        try:
            with open(path, encoding="utf-8") as f:
                exec(compile(f.read(), path, "exec"), module.__dict__)
        except Exception as error:
            raise RegistrationError(f"{path}: could not be loaded: {type(error).__name__}: {error}") from error
        found[expected_id] = _check(module, path, expected_id)
    if not found:
        raise RegistrationError(f"{directory}: no technique registrations found")
    return found


REGISTRATIONS = load_techniques()


def flutter_version():
    """The pinned Flutter version from .fvmrc, or 'unknown'.

    FVM writes .fvmrc as JSON ({"flutter": "3.47.5"}). A file holding only a
    bare version is accepted too. Evidence generation must not abort because
    the pin file is missing or unreadable, so anything else gives 'unknown'.
    """
    try:
        with open(os.path.join(ROOT, ".fvmrc")) as f:
            text = f.read()
    except OSError:
        return "unknown"
    try:
        data = json.loads(text)
    except ValueError:
        data = text
    if isinstance(data, dict):
        data = data.get("flutter")
    if isinstance(data, str):
        candidate = data.strip().strip("\"'")
        # A version or channel name, not arbitrary file content.
        if re.fullmatch(r"[\w.+-]{1,40}", candidate):
            return candidate
    return "unknown"


# Techniques with screen reader evidence: id -> (title, Android test class,
# iOS test class, web VoiceOver spec). None means that platform has no
# screen reader test for the technique.
TECHNIQUES = {tid: (r.title, r.android_test, r.ios_test, r.web_vo_spec)
              for tid, r in REGISTRATIONS.items()}


def technique_argument(argv, usage):
    """The technique id given on the command line, validated."""
    if len(argv) < 2 or argv[1].upper() not in TECHNIQUES:
        raise SystemExit(f"{usage}\nTechniques: {', '.join(sorted(TECHNIQUES))}")
    return argv[1].upper()


@contextlib.contextmanager
def signals_held():
    """Holds SIGINT, SIGTERM and SIGHUP until the block has finished.

    For clean-up that must not be cut short: a signal that arrives during
    it is kept, and sent to this process again once the block is done and
    the handlers that were there before are back.
    """
    pending = []
    names = [s for s in ("SIGINT", "SIGTERM", "SIGHUP") if hasattr(signal, s)]
    try:
        previous = {getattr(signal, n): signal.signal(getattr(signal, n),
                                                      lambda signum, _f: pending.append(signum))
                    for n in names}
    except ValueError:  # not the main thread: nothing to hold
        yield
        return
    try:
        yield
    finally:
        for signum, handler in previous.items():
            signal.signal(signum, handler)
        for signum in pending[:1]:
            os.kill(os.getpid(), signum)


ANDROID_PACKAGE = "dev.fluttera11y.flutter_a11y_techniques"
ADB = os.path.expanduser(os.environ.get("ADB", "~/Library/Android/sdk/platform-tools/adb"))
# Printed by the device itself when pidof found nothing. An empty answer is
# what a device that is offline gives too, and proves nothing.
NOT_RUNNING = "fa11y-not-running"


def stop_android_tests(run=subprocess.run, wait=10.0, sleep=time.sleep):
    """Stops the app and its instrumentation on the emulator, and checks.

    A test runs inside the emulator. Ending the Gradle run on this Mac, as
    happens when a run is stopped or times out, does not end it there, and
    it would go on tapping through the app under the next run. Called after
    every Android step, however it ended, while the device lock is still
    held; a signal that arrives meanwhile is held until it is done. Returns
    True once the device itself has said that neither process is left,
    False if it has not within `wait` seconds: one is still there, or the
    device could not be asked (offline, adb failing).
    """
    import device_lock
    packages = (ANDROID_PACKAGE, ANDROID_PACKAGE + ".test")

    def adb(*args):
        try:
            return run([ADB, *args], capture_output=True, text=True, timeout=30,
                       **device_lock.child_fds())
        except (OSError, subprocess.TimeoutExpired):
            return None

    def stopped(package):
        done = adb("shell", "am", "force-stop", package)
        if done is None or done.returncode != 0:
            return False
        asked = adb("shell", f"pidof {package} || echo {NOT_RUNNING}")
        return (asked is not None and asked.returncode == 0
                and asked.stdout.strip() == NOT_RUNNING)

    with signals_held():
        deadline = time.monotonic() + wait
        while True:
            # Both are asked every time: one can start the other again.
            if all([stopped(package) for package in packages]):
                return True
            if time.monotonic() >= deadline:
                return False
            sleep(0.5)


IOS_BUNDLE = "dev.fluttera11y.flutterA11yTechniques"
IOS_SIMULATOR = "iPhone 17"


def stop_ios_tests(device=IOS_SIMULATOR, run=subprocess.run, wait=10.0, sleep=time.sleep):
    """Stops the app and its UI test runner on the simulator, and checks.

    The iOS counterpart of stop_android_tests(): a UI test runs inside the
    simulator and does not end because xcodebuild was stopped. Returns True
    once simctl says neither is running there (or the simulator is shut
    down), False if that could not be shown within `wait` seconds. A signal
    that arrives meanwhile is held until it is done.
    """
    import device_lock
    bundles = (IOS_BUNDLE, IOS_BUNDLE + ".RunnerUITests.xctrunner")
    with signals_held():
        return _stop_ios(device, bundles, run, wait, sleep, device_lock.child_fds())


def _stop_ios(device, bundles, run, wait, sleep, fds):
    deadline = time.monotonic() + wait
    while True:
        stopped = 0
        for bundle in bundles:
            try:
                done = run(["xcrun", "simctl", "terminate", device, bundle], capture_output=True,
                           text=True, timeout=30, **fds)
            except (OSError, subprocess.TimeoutExpired):
                continue
            said = (done.stderr or "") + (done.stdout or "")
            # simctl ends a running app with status 0; asked again, it says
            # there was nothing to end. Only that, or a simulator that is
            # not running at all, shows that the app is not.
            if done.returncode != 0 and ("found nothing to terminate" in said
                                         or "current state: Shutdown" in said):
                stopped += 1
        if stopped == len(bundles):
            return True
        if time.monotonic() >= deadline:
            return False
        sleep(0.5)
