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
