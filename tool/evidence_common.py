"""Shared helpers for the evidence scripts in tool/."""
import collections
import importlib.util
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
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
        spec = importlib.util.spec_from_file_location(f"technique_registration_{name[:-3]}", path)
        module = importlib.util.module_from_spec(spec)
        try:
            spec.loader.exec_module(module)
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
