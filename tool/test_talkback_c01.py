"""Tests for the accessibility-settings handling in talkback_c01.py.

Run: python3 -m unittest discover -s tool -p 'test_*.py'
"""
import unittest
from unittest import mock

import talkback_c01 as tb

OTHER = "com.example.reader/.ReaderService"


class FakeDevice:
    """Stands in for adb: keeps secure settings in a dict."""

    def __init__(self, settings):
        self.settings = dict(settings)
        self.history = []

    def adb(self, *args):
        if args[:3] == ("shell", "settings", "get"):
            return self.settings.get(args[4], "null") + "\n"
        if args[:3] == ("shell", "settings", "put"):
            # The device shell turns the quoted empty string into empty.
            self.settings[args[4]] = "" if args[5] == '""' else args[5]
            self.history.append((args[4], self.settings[args[4]]))
        if args[:3] == ("shell", "settings", "delete"):
            self.settings.pop(args[4], None)
            self.history.append((args[4], None))
        return ""


class RunWithTalkBack(unittest.TestCase):
    def run_on(self, settings, action=lambda: "done"):
        device = FakeDevice(settings)
        with mock.patch.object(tb, "adb", device.adb), \
                mock.patch.object(tb, "ensure_verbose_logging"):
            try:
                result = tb.run_with_talkback(action)
            except BaseException as error:  # SystemExit included
                result = error
        return device, result

    def test_talkback_is_on_and_other_services_kept_during_the_run(self):
        seen = {}
        device = FakeDevice({tb.SERVICES: OTHER, tb.ENABLED: "1"})

        def action():
            seen.update(device.settings)

        with mock.patch.object(tb, "adb", device.adb), \
                mock.patch.object(tb, "ensure_verbose_logging"):
            tb.run_with_talkback(action)
        self.assertEqual(seen[tb.SERVICES], f"{OTHER}:{tb.TALKBACK}")
        self.assertEqual(seen[tb.ENABLED], "1")

    def test_services_are_off_while_the_settings_screen_is_driven(self):
        device = FakeDevice({tb.SERVICES: OTHER, tb.ENABLED: "1"})
        during_setup = {}
        with mock.patch.object(tb, "adb", device.adb), \
                mock.patch.object(tb, "ensure_verbose_logging",
                                  side_effect=lambda: during_setup.update(device.settings)):
            tb.run_with_talkback(lambda: None)
        self.assertEqual(during_setup, {tb.SERVICES: "", tb.ENABLED: "0"})

    def test_restores_existing_services_after_success(self):
        before = {tb.SERVICES: OTHER, tb.ENABLED: "1"}
        device, result = self.run_on(before)
        self.assertEqual(result, "done")
        self.assertEqual(device.settings, before)

    def test_restores_existing_services_when_the_walk_raises(self):
        before = {tb.SERVICES: OTHER, tb.ENABLED: "1"}

        def fail():
            raise OSError("gradlew could not start")

        device, result = self.run_on(before, fail)
        self.assertIsInstance(result, OSError)
        self.assertEqual(device.settings, before)

    def test_restores_when_setup_exits(self):
        before = {tb.SERVICES: OTHER, tb.ENABLED: "1"}
        device = FakeDevice(before)
        with mock.patch.object(tb, "adb", device.adb), \
                mock.patch.object(tb, "ensure_verbose_logging",
                                  side_effect=SystemExit("could not find setting")):
            with self.assertRaises(SystemExit):
                tb.run_with_talkback(lambda: None)
        self.assertEqual(device.settings, before)

    def test_unset_settings_are_unset_again(self):
        device, _ = self.run_on({})
        self.assertEqual(device.settings, {})

    def test_talkback_already_on_is_not_added_twice_and_stays_on(self):
        before = {tb.SERVICES: tb.TALKBACK, tb.ENABLED: "1"}
        device, _ = self.run_on(before)
        self.assertEqual(device.settings, before)
        self.assertEqual(tb.with_talkback(tb.TALKBACK), tb.TALKBACK)


if __name__ == "__main__":
    unittest.main()
