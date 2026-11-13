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

    def __init__(self, settings, fail=lambda args, count: False, log_level="ERROR"):
        self.settings = dict(settings)
        self.fail = fail
        self.calls = 0
        self.log_level = log_level
        self.during_log_setup = []
        self.fail_log_change = None

    def set_log_level(self, level, on_read=None):
        """Stands in for driving TalkBack's settings screen."""
        self.during_log_setup.append(dict(self.settings))
        previous = self.log_level
        if on_read:
            on_read(previous)
        if self.fail_log_change == level:
            raise SystemExit(f'TalkBack settings: could not find "{level}"')
        self.log_level = level
        return previous

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
                mock.patch.object(tb, "set_log_level", device.set_log_level):
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
                mock.patch.object(tb, "set_log_level", device.set_log_level):
            tb.run_with_talkback(action)
        self.assertEqual(seen[tb.SERVICES], f"{OTHER}:{tb.TALKBACK}")
        self.assertEqual(seen[tb.ENABLED], "1")

    def test_services_are_off_while_the_settings_screen_is_driven(self):
        device = FakeDevice({tb.SERVICES: OTHER, tb.ENABLED: "1"})
        with mock.patch.object(tb, "adb_checked", device.adb), \
                mock.patch.object(tb, "set_log_level", device.set_log_level):
            tb.run_with_talkback(lambda: None)
        # Once to turn verbose logging on, once to put it back.
        self.assertEqual(device.during_log_setup,
                         [{tb.SERVICES: "", tb.ENABLED: "0"}] * 2)

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
        device.fail_log_change = "VERBOSE"
        with mock.patch.object(tb, "adb_checked", device.adb), \
                mock.patch.object(tb, "set_log_level", device.set_log_level):
            with self.assertRaises(SystemExit):
                tb.run_with_talkback(lambda: None)
        self.assertEqual(device.settings, before)
        self.assertEqual(device.log_level, "ERROR")

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
                mock.patch.object(tb, "set_log_level", device.set_log_level), \
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
        # Calls 1-2 read, 3-6 write for the run, 7-8 switch services off to
        # put the log level back, 9 is the first restore.
        device, error = self.run_failing(lambda args, count: count == 9,
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

    def test_no_output_is_an_error_not_an_absent_setting(self):
        with self.assertRaises(tb.AdbError):
            self.read("")

    def test_bare_newline_is_an_empty_value(self):
        self.assertEqual(self.read("\n"), "")


class EmptyServices(unittest.TestCase):
    def test_run_from_an_empty_services_list_restores_it_empty(self):
        before = {tb.SERVICES: "", tb.ENABLED: "0"}
        device = FakeDevice(before)
        during = {}
        puts = []

        def adb(*args):
            if args[:3] == ("shell", "settings", "put"):
                puts.append(args[5])
            return device.adb(*args)

        with mock.patch.object(tb, "adb_checked", adb), \
                mock.patch.object(tb, "set_log_level", device.set_log_level):
            tb.run_with_talkback(lambda: during.update(device.settings))
        self.assertEqual(during, {tb.SERVICES: tb.TALKBACK, tb.ENABLED: "1"})
        self.assertEqual(device.settings, before)
        # Never sent as a bare empty argument, which the device shell drops.
        self.assertNotIn("", puts)


class LogLevel(unittest.TestCase):
    BEFORE = {tb.SERVICES: OTHER, tb.ENABLED: "1"}

    def run_on(self, device, action=lambda: None):
        with mock.patch.object(tb, "adb_checked", device.adb), \
                mock.patch.object(tb, "set_log_level", device.set_log_level), \
                mock.patch("sys.stderr"):
            try:
                tb.run_with_talkback(action)
            except BaseException as error:
                return error

    def test_verbose_during_the_run_and_restored_after_success(self):
        device = FakeDevice(self.BEFORE, log_level="ERROR")
        during = []
        self.run_on(device, lambda: during.append(device.log_level))
        self.assertEqual(during, ["VERBOSE"])
        self.assertEqual(device.log_level, "ERROR")
        self.assertEqual(device.settings, self.BEFORE)

    def test_restored_when_the_walk_raises(self):
        device = FakeDevice(self.BEFORE, log_level="WARN")

        def fail():
            raise OSError("gradlew could not start")

        self.assertIsInstance(self.run_on(device, fail), OSError)
        self.assertEqual(device.log_level, "WARN")
        self.assertEqual(device.settings, self.BEFORE)

    def test_already_verbose_is_left_alone(self):
        device = FakeDevice(self.BEFORE, log_level="VERBOSE")
        self.run_on(device)
        self.assertEqual(device.log_level, "VERBOSE")
        self.assertEqual(len(device.during_log_setup), 1)

    def test_failed_log_restore_is_reported_and_settings_still_restored(self):
        device = FakeDevice(self.BEFORE, log_level="ERROR")
        device.fail_log_change = "ERROR"
        error = self.run_on(device)
        self.assertIsInstance(error, tb.AdbError)
        self.assertIn("log output level should be ERROR", str(error))
        self.assertEqual(device.settings, self.BEFORE)


    def test_any_error_in_log_restore_still_restores_the_settings(self):
        for raised in (ValueError("'Log output level' is not in list"),
                       IndexError("list index out of range"),
                       KeyboardInterrupt()):
            device = FakeDevice(self.BEFORE, log_level="ERROR")
            real = device.set_log_level
            calls = []

            def flaky(level, on_read=None, real=real, calls=calls, raised=raised):
                calls.append(level)
                if len(calls) == 2:  # the restore, in cleanup
                    raise raised
                return real(level, on_read)

            with mock.patch.object(tb, "adb_checked", device.adb), \
                    mock.patch.object(tb, "set_log_level", flaky), \
                    mock.patch("sys.stderr"):
                with self.assertRaises(tb.AdbError) as caught:
                    tb.run_with_talkback(lambda: None)
            self.assertEqual(device.settings, self.BEFORE, type(raised).__name__)
            self.assertIn("log output level should be ERROR", str(caught.exception))


class ReadingTheLogLevel(unittest.TestCase):
    def test_reads_the_level_under_the_label(self):
        texts = ["Developer settings", "Log output level", "WARN", "Other"]
        self.assertEqual(tb.current_log_level(texts), "WARN")

    def test_empty_or_incomplete_screen_dump_is_an_error(self):
        for texts in ([], ["Developer settings"], ["Log output level"],
                      ["Log output level", "Filter accessibility event logging"]):
            with self.assertRaises(tb.AdbError, msg=texts):
                tb.current_log_level(texts)

    def test_a_bad_screen_read_during_cleanup_leaves_settings_restored(self):
        before = {tb.SERVICES: OTHER, tb.ENABLED: "1"}
        device = FakeDevice(before)
        screens = iter([["Log output level", "ERROR"]])  # setup; cleanup gets []
        with mock.patch.object(tb, "adb_checked", device.adb), \
                mock.patch.object(tb, "adb", return_value=""), \
                mock.patch.object(tb, "tap"), \
                mock.patch.object(tb.time, "sleep"), \
                mock.patch.object(tb, "screen",
                                  side_effect=lambda: [(t, 0, 0) for t in next(screens, [])]), \
                mock.patch("sys.stderr"):
            with self.assertRaises(tb.AdbError) as caught:
                tb.run_with_talkback(lambda: None)
        self.assertEqual(device.settings, before)
        self.assertIn("log output level should be ERROR", str(caught.exception))


if __name__ == "__main__":
    unittest.main()
