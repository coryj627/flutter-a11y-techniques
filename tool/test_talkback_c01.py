"""Tests for the accessibility-settings handling in talkback_c01.py.

Run: python3 -m unittest discover -s tool -p 'test_*.py'
"""
import sys
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
                mock.patch.object(tb, "tap"), \
                mock.patch.object(tb.time, "sleep"), \
                mock.patch.object(tb, "screen",
                                  side_effect=lambda: [(t, 0, 0) for t in next(screens, [])]), \
                mock.patch("sys.stderr"):
            with self.assertRaises(tb.AdbError) as caught:
                tb.run_with_talkback(lambda: None)
        self.assertEqual(device.settings, before)
        self.assertIn("log output level should be ERROR", str(caught.exception))


class Decoding(unittest.TestCase):
    def test_invalid_utf8_in_device_output_does_not_fail_the_run(self):
        # A real device log contained a byte that is not valid UTF-8.
        script = "import sys; sys.stdout.buffer.write(b'Speaking \\xc0 fragment\\n')"
        with mock.patch.object(tb, "ADB", sys.executable):
            output = tb.adb("-c", script)
        self.assertIn("Speaking", output)
        self.assertIn("fragment", output)


def log_for(speech):
    """A device log in which each element was focused and spoke `speech`."""
    lines = []
    for ident, fragments in speech.items():
        lines.append(f"11-13 10:00:00.000  1  1 I C01TB   : FOCUS {ident}")
        lines += [f'V talkback: SpeechControllerImpl: Speaking fragment text="{f}", utteranceId=x'
                  for f in fragments]
    lines.append("11-13 10:00:01.000  1  1 I C01TB   : END slug")
    return "\n".join(lines)


class Walks(unittest.TestCase):
    OK = mock.Mock(returncode=0, stdout="")

    def walker(self, logs):
        logs = iter(logs)
        self.walks = 0

        def walk_once():
            self.walks += 1
            return self.OK, next(logs)

        return walk_once

    def test_one_walk_when_everything_is_heard(self):
        speech = {"a": ["Save", "Button"], "b": ["Close. Button"]}
        spoken, retried = tb.walk_until_heard(self.walker([log_for(speech)]))
        self.assertEqual((spoken, retried, self.walks), (speech, [], 1))

    def test_a_silent_element_is_walked_again_and_only_it_is_replaced(self):
        first = {"a": ["Save", "Button"], "b": []}
        second = {"a": ["Different"], "b": ["Submit", "Button. disabled"]}
        spoken, retried = tb.walk_until_heard(self.walker([log_for(first), log_for(second)]))
        self.assertEqual(spoken, {"a": ["Save", "Button"], "b": ["Submit", "Button. disabled"]})
        self.assertEqual((retried, self.walks), (["b"], 2))

    def test_an_element_spoken_over_by_a_notification_is_walked_again(self):
        ident = "c01-good-text-filled"
        first = {ident: ["Google Play Protect is turned on"]}
        second = {ident: ["Save", "Button", "Double-tap to activate"]}
        spoken, retried = tb.walk_until_heard(self.walker([log_for(first), log_for(second)]))
        self.assertEqual(spoken[ident], second[ident])
        self.assertEqual((retried, self.walks), ([ident], 2))

    def test_an_element_that_keeps_failing_is_left_failing_after_three_walks(self):
        ident = "c01-good-disabled-submit"
        wrong = log_for({ident: ["Submit", "Button"]})  # never says disabled
        spoken, retried = tb.walk_until_heard(self.walker([wrong] * 5))
        self.assertEqual(spoken[ident], ["Submit", "Button"])
        self.assertEqual((retried, self.walks), ([ident], tb.MAX_WALKS))
        self.assertTrue(tb.problems(ident, spoken[ident]))

    def test_a_bad_example_is_not_retried_for_having_its_defect(self):
        ident = "c01-bad-unlabelled-icon-close"
        speech = {ident: ["Button", "Double-tap to activate"]}
        spoken, retried = tb.walk_until_heard(self.walker([log_for(speech)]))
        self.assertEqual((retried, self.walks), ([], 1))

    def test_a_failed_walk_exits(self):
        failed = mock.Mock(returncode=1, stdout="BUILD FAILED")
        with mock.patch("builtins.print"), self.assertRaises(SystemExit):
            tb.walk_until_heard(lambda: (failed, ""))


class FakeSettingsScreen:
    """Stands in for TalkBack's developer settings screen."""

    def __init__(self, level="ERROR"):
        self.level = level
        self.ignore_taps_on = set()   # taps that silently do nothing
        self.fail_taps_on = set()     # taps whose adb command fails
        self.taps = []

    def screen(self):
        return [(t, 0, 0) for t in ("Developer settings", "Log output level", self.level)]

    def tap(self, text, scrolls=3):
        self.taps.append(text)
        if text in self.fail_taps_on:
            raise tb.AdbError(f"adb shell input tap failed for {text}")
        if text in tb.LOG_LEVELS and text not in self.ignore_taps_on:
            self.level = text

    def patches(self, device):
        return (mock.patch.object(tb, "adb_checked", device.adb),
                mock.patch.object(tb, "screen", self.screen),
                mock.patch.object(tb, "tap", self.tap),
                mock.patch.object(tb.time, "sleep"),
                mock.patch("sys.stderr"))


class LogLevelThroughTheScreen(unittest.TestCase):
    BEFORE = {tb.SERVICES: OTHER, tb.ENABLED: "1"}

    def run_with(self, ui, action=lambda: None):
        device = FakeDevice(self.BEFORE)
        patches = ui.patches(device)
        for p in patches:
            p.start()
        try:
            try:
                tb.run_with_talkback(action)
                return device, None
            except tb.AdbError as error:
                return device, error
        finally:
            for p in patches:
                p.stop()

    def test_sets_verbose_then_restores_the_level(self):
        ui = FakeSettingsScreen("WARN")
        during = []
        device, error = self.run_with(ui, lambda: during.append(ui.level))
        self.assertIsNone(error)
        self.assertEqual(during, ["VERBOSE"])
        self.assertEqual(ui.level, "WARN")
        self.assertEqual(device.settings, self.BEFORE)

    def test_a_restore_tap_that_does_nothing_is_reported_not_passed(self):
        ui = FakeSettingsScreen("ERROR")
        ui.ignore_taps_on = {"ERROR"}
        device, error = self.run_with(ui)
        self.assertIsInstance(error, tb.AdbError)
        self.assertIn("log output level should be ERROR", str(error))
        self.assertIn("is VERBOSE, not ERROR", str(error))
        self.assertEqual(device.settings, self.BEFORE)

    def test_a_restore_tap_whose_command_fails_is_reported(self):
        ui = FakeSettingsScreen("ERROR")
        ran = []

        def action():
            ran.append(True)
            ui.fail_taps_on = {"ERROR"}  # fails only during cleanup

        device, error = self.run_with(ui, action)
        self.assertEqual(ran, [True])
        self.assertIsInstance(error, tb.AdbError)
        self.assertIn("log output level should be ERROR", str(error))
        self.assertEqual(device.settings, self.BEFORE)

    def test_a_setup_tap_that_does_nothing_stops_the_run_and_restores(self):
        ui = FakeSettingsScreen("ERROR")
        ui.ignore_taps_on = {"VERBOSE"}
        ran = []
        device, error = self.run_with(ui, lambda: ran.append(True))
        self.assertEqual(ran, [])
        self.assertIsInstance(error, tb.AdbError)
        self.assertEqual(device.settings, self.BEFORE)


class Taps(unittest.TestCase):
    def test_tap_raises_when_the_tap_command_fails(self):
        def adb(*args):
            if args[:3] == ("shell", "input", "tap"):
                raise tb.AdbError("device offline")
            return ""

        with mock.patch.object(tb, "adb_checked", adb), \
                mock.patch.object(tb, "screen", return_value=[("ERROR", 5, 5)]), \
                mock.patch.object(tb.time, "sleep"):
            with self.assertRaises(tb.AdbError):
                tb.tap("ERROR")

    def test_tap_raises_when_the_text_is_not_on_screen(self):
        with mock.patch.object(tb, "adb_checked", return_value=""), \
                mock.patch.object(tb, "screen", return_value=[]), \
                mock.patch.object(tb.time, "sleep"):
            with self.assertRaises(tb.AdbError):
                tb.tap("ERROR")

    def test_screen_retries_a_failed_dump_then_raises(self):
        calls = []

        def adb(*args):
            calls.append(args)
            raise tb.AdbError("could not get idle state")

        with mock.patch.object(tb, "adb_checked", adb), mock.patch.object(tb.time, "sleep"):
            with self.assertRaises(tb.AdbError):
                tb.screen()
        self.assertEqual(len(calls), 3)


class Checks(unittest.TestCase):
    def test_role_in_a_name_does_not_count_as_the_role(self):
        self.assertFalse(tb.said(["close button"], "Button"))
        self.assertTrue(tb.said(["close button. button"], "Button"))

    def test_expected_and_unexpected_phrases(self):
        self.assertEqual(tb.problems("c01-good-text-filled", ["Save", "Button"]), [])
        self.assertTrue(tb.problems("c01-good-text-filled", ["Save"]))
        self.assertTrue(tb.problems("c01-bad-gesture-only-save", ["Save", "Button"]))


if __name__ == "__main__":
    unittest.main()
