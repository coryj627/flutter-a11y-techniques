"""Shared helpers for the evidence scripts in tool/."""
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


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
# iOS test class, web VoiceOver spec).
TECHNIQUES = {
    "C01": ("C01 Button", "C01ButtonTest", "C01ButtonUITests", "c01_button_vo.spec.js"),
    "S05": ("S05 Headings", "S05HeadingsTest", "S05HeadingsUITests", "s05_headings_vo.spec.js"),
    "F01": ("F01 Text fields and labels", "F01TextFieldsTest", "F01TextFieldsUITests",
            "f01_text_fields_vo.spec.js"),
}


def technique_argument(argv, usage):
    """The technique id given on the command line, validated."""
    if len(argv) < 2 or argv[1].upper() not in TECHNIQUES:
        raise SystemExit(f"{usage}\nTechniques: {', '.join(sorted(TECHNIQUES))}")
    return argv[1].upper()
