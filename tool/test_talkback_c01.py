"""Tests for the accessibility-settings handling in talkback_c01.py.

Run: python3 -m unittest discover -s tool -p 'test_*.py'
"""
import unittest
from unittest import mock

import talkback_c01 as tb

OTHER = "com.example.reader/.ReaderService"


class FakeDevice:
    """Stands in for adb: keeps secure settings in a dict.

    `fail` decides which calls fail: it is given the adb arguments and the
    number of settings calls made so far.
    """

    def __init__(self, settings, fail=lambda args, count: False):
        self.settings = dict(settings)
        self.fail = fail
        self.calls = 0

    def adb(self, *args):
        self.calls += 1
        if self.fail(args, self.calls):
            raise tb.AdbError(f"adb {' '.join(args)} failed")
        if args[:3] == ("shell", "settings", "get"):
            return self.settings.get(args[4], "null") + "\n"
        if args[:3] == ("shell", "settings", "put"):
            # The device shell turns the quoted empty string into empty.
            self.settings[args[4]] = "" if args[5] == '""' else args[5]
        if args[:3] == ("shell", "settings", "delete"):
            self.settings.pop(args[4], None)
        return ""


class RunWithTalkBack(unittest.TestCase):
    def run_on(self, settings, action=lambda: "done"):
        device = FakeDevice(settings)
        with mock.patch.object(tb, "adb_checked", device.adb), \
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

        with mock.patch.object(tb, "adb_checked", device.adb), \
                mock.patch.object(tb, "ensure_verbose_logging"):
            tb.run_with_talkback(action)
        self.assertEqual(seen[tb.SERVICES], f"{OTHER}:{tb.TALKBACK}")
        self.assertEqual(seen[tb.ENABLED], "1")

    def test_services_are_off_while_the_settings_screen_is_driven(self):
        device = FakeDevice({tb.SERVICES: OTHER, tb.ENABLED: "1"})
        during_setup = {}
        with mock.patch.object(tb, "adb_checked", device.adb), \
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
        with mock.patch.object(tb, "adb_checked", device.adb), \
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


class Failures(unittest.TestCase):
    BEFORE = {tb.SERVICES: OTHER, tb.ENABLED: "1"}

    def run_failing(self, fail, action=lambda: "done"):
        device = FakeDevice(self.BEFORE, fail)
        with mock.patch.object(tb, "adb_checked", device.adb), \
                mock.patch.object(tb, "ensure_verbose_logging"), \
                mock.patch("sys.stderr"):
            with self.assertRaises(tb.AdbError) as raised:
                tb.run_with_talkback(action)
        return device, raised.exception

    def test_failed_first_read_changes_nothing(self):
        device, _ = self.run_failing(lambda args, count: args[2] == "get" and count == 1)
        self.assertEqual(device.settings, self.BEFORE)
        self.assertEqual(device.calls, 1)

    def test_failed_second_read_changes_nothing(self):
        device, _ = self.run_failing(lambda args, count: args[2] == "get" and count == 2)
        self.assertEqual(device.settings, self.BEFORE)
        self.assertEqual(device.calls, 2)

    def test_failed_write_during_setup_still_restores(self):
        # The fourth settings call is the write that turns services off.
        device, _ = self.run_failing(lambda args, count: count == 4)
        self.assertEqual(device.settings, self.BEFORE)

    def test_failed_restore_is_reported_with_the_value_to_set(self):
        ran = []
        # Calls 1-2 read, 3-6 write for the run, 7 is the first restore.
        device, error = self.run_failing(lambda args, count: count == 7,
                                         action=lambda: ran.append(True))
        self.assertEqual(ran, [True])
        self.assertIn("Could not restore", str(error))
        self.assertIn(OTHER, str(error))
        # The other setting was still restored.
        self.assertEqual(device.settings[tb.ENABLED], "1")


class Reads(unittest.TestCase):
    def read(self, stdout, returncode=0):
        result = mock.Mock(stdout=stdout, stderr="device offline", returncode=returncode)
        with mock.patch.object(tb.subprocess, "run", return_value=result):
            return tb.read_setting(tb.SERVICES)

    def test_null_means_not_set(self):
        self.assertIsNone(self.read("null\n"))

    def test_value_is_returned(self):
        self.assertEqual(self.read(OTHER + "\n"), OTHER)

    def test_failed_command_is_an_error_not_an_absent_setting(self):
        with self.assertRaises(tb.AdbError):
            self.read("", returncode=1)

    def test_empty_output_is_an_error_not_an_absent_setting(self):
        with self.assertRaises(tb.AdbError):
            self.read("\n")


if __name__ == "__main__":
    unittest.main()
