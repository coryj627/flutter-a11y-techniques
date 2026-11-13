"""Shared helpers for the evidence scripts in tool/."""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def flutter_version():
    """The pinned Flutter version from .fvmrc, or 'unknown'.

    Evidence generation must not abort because the pin file is missing or its
    format changed, so every failure falls back to 'unknown'.
    """
    try:
        with open(os.path.join(ROOT, ".fvmrc")) as f:
            version = json.load(f).get("flutter")
    except (OSError, ValueError, AttributeError):
        return "unknown"
    return version if isinstance(version, str) and version else "unknown"
