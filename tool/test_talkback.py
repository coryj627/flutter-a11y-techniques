"""Tests for the accessibility-settings handling in talkback.py.

Run: python3 -m unittest discover -s tool -p 'test_*.py'
"""
import json
import os
import signal
import subprocess
import sys
import tempfile
import time
import unittest
from unittest import mock

import talkback as tb

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
            raise tb.AdbError(f'TalkBack settings: could not find "{level}"')
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
            with self.assertRaises(tb.AdbError):
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


    def flaky_restore(self, device, raised):
        real, calls = device.set_log_level, []

        def flaky(level, on_read=None):
            calls.append(level)
            if len(calls) == 2:  # the restore, in cleanup
                raise raised
            return real(level, on_read)

        return (mock.patch.object(tb, "adb_checked", device.adb),
                mock.patch.object(tb, "set_log_level", flaky),
                mock.patch("sys.stderr"))

    def test_any_error_in_log_restore_still_restores_the_settings(self):
        for raised in (ValueError("'Log output level' is not in list"),
                       IndexError("list index out of range")):
            device = FakeDevice(self.BEFORE, log_level="ERROR")
            a, b, c = self.flaky_restore(device, raised)
            with a, b, c:
                with self.assertRaises(tb.AdbError) as caught:
                    tb.run_with_talkback(lambda: None)
            self.assertEqual(device.settings, self.BEFORE, type(raised).__name__)
            self.assertIn("log output level should be ERROR", str(caught.exception))

    def test_an_interrupt_in_log_restore_stays_an_interrupt_and_settings_are_restored(self):
        for raised in (KeyboardInterrupt(), SystemExit(143)):
            device = FakeDevice(self.BEFORE, log_level="ERROR")
            a, b, c = self.flaky_restore(device, raised)
            with a, b, c:
                with self.assertRaises(type(raised)):
                    tb.run_with_talkback(lambda: None)
            self.assertEqual(device.settings, self.BEFORE, type(raised).__name__)


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


class StrictWalks(unittest.TestCase):
    """walk_strictly, which C05 uses: a walk is judged whole. A wrong
    reading fails for good, only a walk shown to be incomplete is walked
    again, and no element's speech is taken from another walk."""
    OK = mock.Mock(returncode=0, stdout="")
    PREFIX = "c05-"

    def setUp(self):
        self.expected = [i for i in tb.EXPECT if i.startswith(self.PREFIX)]
        # A right reading for each element: the phrases it must have.
        self.right = {i: list(tb.EXPECT[i][0]) for i in self.expected}
        for ident, fragments in self.right.items():
            self.assertEqual(tb.problems(ident, fragments), [], ident)

    def walker(self, logs):
        logs = iter(logs)
        self.walks = 0

        def walk_once():
            self.walks += 1
            return self.OK, next(logs)

        return walk_once

    def wrong_at(self, ident):
        """A whole walk, right but for `ident`, which says it is expanded
        while closed."""
        speech = dict(self.right)
        speech[ident] = speech[ident] + ["expanded"]
        self.assertTrue(tb.problems(ident, speech[ident]))
        return log_for(speech)

    def test_two_complete_walks_wrong_at_different_rows_fail(self):
        # The case Codex reproduced: neither walk is right on its own.
        first = self.wrong_at("c05-good-material-closed")
        second = self.wrong_at("c05-good-cupertino-closed")
        tries = tb.walk_strictly(self.PREFIX, self.walker([first, second]))
        self.assertEqual([t.verdict for t in tries], ["wrong"])
        self.assertEqual(self.walks, 1, "no walk after a wrong one")
        failures, out = tb.strict_report(tries)
        self.assertTrue(failures)
        self.assertIn("Result: FAIL", out)
        # walk_until_heard, which other techniques keep, makes the two into
        # one passing composite: the difference this guards.
        spoken, _ = tb.walk_until_heard(self.walker([first, second]))
        self.assertFalse(any(tb.problems(i, spoken[i]) for i in self.expected))

    def test_an_incomplete_walk_then_a_right_one_passes_on_the_second(self):
        short = dict(self.right)
        del short["c05-good-custom-panel"]  # never focused
        tries = tb.walk_strictly(self.PREFIX, self.walker([log_for(short), log_for(self.right)]))
        self.assertEqual([t.verdict for t in tries], ["incomplete", "right"])
        failures, out = tb.strict_report(tries)
        self.assertEqual(failures, [])
        self.assertIn("Result: PASS", out)
        # Both walks are in the transcript.
        self.assertIn("## Walk 1 (incomplete)", out)
        self.assertIn("## Walk 2 (right)", out)
        self.assertIn("- Walk 1: incomplete (c05-good-custom-panel: never focused)", out)

    def test_an_incomplete_walk_then_a_wrong_one_fails(self):
        silent = dict(self.right)
        silent["c05-good-material-open"] = []
        tries = tb.walk_strictly(self.PREFIX, self.walker(
            [log_for(silent), self.wrong_at("c05-good-cupertino-closed")]))
        self.assertEqual([t.verdict for t in tries], ["incomplete", "wrong"])
        failures, _ = tb.strict_report(tries)
        self.assertTrue(any("c05-good-cupertino-closed" in f for f in failures))

    def test_a_cut_off_capture_is_incomplete(self):
        log = log_for(self.right).replace(
            "END slug",
            "FOCUS c05-good-material-closed\n"
            'V talkback: SpeechControllerImpl: Speaking fragment text="Shipping\n'
            "11-13 10:00:02.000  1  1 I C05TB   : END slug")
        verdict, reasons = tb.judge_walk(tb.parse_speech(log), self.expected)
        self.assertEqual(verdict, "incomplete")
        self.assertEqual(reasons, ["c05-good-material-closed: speech capture was cut off"])

    def cut_log(self, ident, whole, captured):
        """A whole walk, right but for `ident`, which speaks the fragments
        `whole` and then one more that is cut off after its lines
        `captured` (logcat splits a fragment at its line breaks)."""
        rest = {i: f for i, f in self.right.items() if i != ident}
        tag = 'V talkback: SpeechControllerImpl: '
        lines = [f"11-13 10:00:00.000  1  1 I C05TB   : FOCUS {ident}"]
        lines += [f'{tag}Speaking fragment text="{f}", utteranceId=x' for f in whole]
        lines.append(f'{tag}Speaking fragment text="{captured[0]}')
        lines += [f"{tag}{line}" for line in captured[1:]]
        return "\n".join(lines) + "\n" + log_for(rest)

    def test_a_forbidden_phrase_beside_a_cut_off_fragment_fails_for_good(self):
        # Codex's case: "expanded", forbidden while closed, is said in a
        # fragment captured whole, and the next fragment is cut off. The
        # walk is wrong, and a right walk after it changes nothing.
        ident = "c05-good-material-closed"
        log = self.cut_log(ident, ["expanded", "Shipping"], ["Button. Heading"])
        tries = tb.walk_strictly(self.PREFIX, self.walker([log, log_for(self.right)]))
        self.assertEqual([t.verdict for t in tries], ["wrong"])
        self.assertEqual(self.walks, 1)
        failures, out = tb.strict_report(tries)
        self.assertEqual(failures, [f'{ident}: did not expect "expanded" in '
                                    f'"expanded | shipping | button. heading"'])
        self.assertIn("Result: FAIL", out)
        # The captured lines are in the transcript.
        self.assertTrue(any('captured of the cut-off speech: "Button. Heading"' in line
                            for line in out))

    def test_a_forbidden_phrase_in_the_captured_lines_of_a_cut_off_fragment_is_wrong(self):
        # A cut-off fragment's captured lines are whole lines of what was
        # said: one that holds the whole forbidden phrase was said.
        ident = "c05-good-material-closed"
        log = self.cut_log(ident, ["Shipping"], ["collapsed, Button", "expanded"])
        tries = tb.walk_strictly(self.PREFIX, self.walker([log, log_for(self.right)]))
        self.assertEqual([t.verdict for t in tries], ["wrong"])
        self.assertEqual(self.walks, 1)

    def test_a_required_phrase_lost_to_the_cut_is_incomplete(self):
        # "Heading" and the hint were in the lost part: nothing heard is
        # wrong, so the walk is incomplete and walked again.
        ident = "c05-good-material-closed"
        log = self.cut_log(ident, ["collapsed. ", "Shipping"], ["Button."])
        tries = tb.walk_strictly(self.PREFIX, self.walker([log, log_for(self.right)]))
        self.assertEqual([t.verdict for t in tries], ["incomplete", "right"])
        self.assertEqual(tries[0].reasons, [f"{ident}: speech capture was cut off"])
        self.assertEqual(tb.strict_report(tries)[0], [])

    def test_a_forbidden_phrase_split_by_the_cut_is_not_heard(self):
        # Only the lines before the cut are known: a phrase whose words are
        # not all in them was not shown to be said.
        ident = "c05-good-material-closed"
        log = self.cut_log(ident, ["collapsed. ", "Shipping"], ["Button. Heading. fully"])
        verdict, _ = tb.judge_walk(tb.parse_speech(log), self.expected)
        cut = {}
        spoken = tb.parse_speech(log, cut)
        self.assertEqual(cut, {ident: ["Button. Heading. fully"]})
        self.assertEqual(tb.judge_walk(spoken, self.expected, cut)[0], "incomplete")
        self.assertEqual(verdict, "incomplete")

    def test_parse_speech_is_the_same_with_or_without_the_cut_lines(self):
        ident = "c05-good-material-closed"
        log = self.cut_log(ident, ["Shipping"], ["Button", "expanded"])
        self.assertEqual(tb.parse_speech(log), tb.parse_speech(log, {}))

    def test_a_wrong_reading_in_an_incomplete_walk_fails_for_good(self):
        speech = dict(self.right)
        del speech["c05-good-custom-panel"]
        speech["c05-good-material-closed"] = speech["c05-good-material-closed"] + ["expanded"]
        tries = tb.walk_strictly(self.PREFIX, self.walker([log_for(speech), log_for(self.right)]))
        self.assertEqual([t.verdict for t in tries], ["wrong"])
        self.assertEqual(self.walks, 1)

    def test_three_incomplete_walks_fail(self):
        short = dict(self.right)
        del short["c05-good-custom-panel"]
        tries = tb.walk_strictly(self.PREFIX, self.walker([log_for(short)] * 5))
        self.assertEqual([t.verdict for t in tries], ["incomplete"] * tb.MAX_WALKS)
        failures, _ = tb.strict_report(tries)
        self.assertEqual(failures, ["c05-good-custom-panel: never focused"])

    def test_the_strict_techniques(self):
        self.assertEqual(tb.STRICT, {"C05", "C06", "C13", "C18", "C26", "S09"})

    def test_c05_has_no_silent_rows(self):
        self.assertEqual([i for i in self.expected if tb.is_silent(i)], [])


class SilentRows(unittest.TestCase):
    """Rows of a strict walk declared silent (tb.SILENT), as C26's are: the
    row must have nothing spoken in it, its capture must be ended by a
    marker, and the row after it, its liveness control, must be right."""
    OK = mock.Mock(returncode=0, stdout="")
    PREFIX = "c26-"
    SILENT = "c26-bad-silent-end-run"
    CONTROL = "c26-bad-silent-end-run-live"

    def setUp(self):
        self.expected = [i for i in tb.EXPECT if i.startswith(self.PREFIX)]
        self.assertEqual([i for i in self.expected if tb.is_silent(i)],
                         ["c26-bad-silent-end-run", "c26-bad-silent-end-bar-run"])
        # A right reading for each element: its required phrases, and
        # nothing for a silent one. log_for logs the rows in this order,
        # each ended by the next marker.
        self.right = {i: [] if tb.is_silent(i) else list(tb.EXPECT[i][0]) for i in self.expected}
        order = list(self.right)
        self.assertEqual(order[order.index(self.SILENT) + 1], self.CONTROL)

    def walker(self, logs):
        logs = iter(logs)
        self.walks = 0

        def walk_once():
            self.walks += 1
            return self.OK, next(logs)

        return walk_once

    def judge(self, log):
        cut, closed = {}, set()
        spoken = tb.parse_speech(log, cut, closed)
        return tb.judge_walk(spoken, self.expected, cut, closed)

    def test_an_empty_silent_row_with_both_markers_and_a_live_control_is_right(self):
        self.assertEqual(self.judge(log_for(self.right)), ("right", []))
        tries = tb.walk_strictly(self.PREFIX, self.walker([log_for(self.right)]))
        self.assertEqual([t.verdict for t in tries], ["right"])

    def test_numbers_in_a_silent_row_are_wrong_and_not_walked_again(self):
        # Codex's case: the bar's values read out while it must be silent.
        speech = dict(self.right)
        speech[self.SILENT] = ["25.0. ", "50.0. ", "75.0. ", "100.0. "]
        tries = tb.walk_strictly(self.PREFIX, self.walker([log_for(speech), log_for(self.right)]))
        self.assertEqual([t.verdict for t in tries], ["wrong"])
        self.assertEqual(self.walks, 1)
        failures, out = tb.strict_report(tries)
        self.assertEqual(failures, [f'{self.SILENT}: expected silence, heard "25.0.  | 50.0.  | 75.0.  | 100.0. "'])
        self.assertIn("Result: FAIL", out)

    def test_any_speech_at_all_in_a_silent_row_is_wrong(self):
        for words in (["Double-tap to activate"], ["Progress bar"]):
            speech = dict(self.right)
            speech[self.SILENT] = words
            self.assertEqual(self.judge(log_for(speech))[0], "wrong", words)

    def test_a_cut_off_fragment_in_a_silent_row_is_wrong(self):
        # A fragment that starts in the silent row and is cut off by the
        # next marker: something was said.
        log = log_for(self.right).replace(
            f"11-13 10:00:00.000  1  1 I C01TB   : FOCUS {self.CONTROL}",
            'V talkback: SpeechControllerImpl: Speaking fragment text="Half\n'
            f"11-13 10:00:00.000  1  1 I C01TB   : FOCUS {self.CONTROL}")
        verdict, reasons = self.judge(log)
        self.assertEqual(verdict, "wrong")
        self.assertEqual(reasons, [f'{self.SILENT}: expected silence, heard "Half"'])

    def test_a_silent_row_whose_end_marker_was_not_captured_is_incomplete(self):
        # The log ends inside the silent row: no marker after it.
        log = log_for(self.right)
        lines = log.splitlines()
        cut_at = lines.index(f"11-13 10:00:00.000  1  1 I C01TB   : FOCUS {self.SILENT}")
        verdict, reasons = self.judge("\n".join(lines[:cut_at + 1]))
        self.assertEqual(verdict, "incomplete")
        self.assertIn(f"{self.SILENT}: the capture was not ended by a marker", reasons)

    def test_a_silent_row_with_an_empty_liveness_control_is_incomplete(self):
        speech = dict(self.right)
        speech[self.CONTROL] = []
        verdict, reasons = self.judge(log_for(speech))
        self.assertEqual(verdict, "incomplete")
        self.assertIn(f"{self.SILENT}: its liveness control, {self.CONTROL}, is not right", reasons)
        self.assertIn(f"{self.CONTROL}: nothing was spoken", reasons)

    def test_a_silent_row_with_no_row_after_it_is_incomplete(self):
        # The walk ends (END) straight after the silent row.
        order = list(self.right)
        speech = {i: self.right[i] for i in order[:order.index(self.SILENT) + 1]}
        verdict, reasons = self.judge(log_for(speech))
        self.assertEqual(verdict, "incomplete")
        self.assertIn(f"{self.SILENT}: no liveness control after it", reasons)

    def test_an_empty_row_not_declared_silent_stays_incomplete(self):
        speech = dict(self.right)
        speech["c26-good-linear-run"] = []
        self.assertEqual(self.judge(log_for(speech)),
                         ("incomplete", ["c26-good-linear-run: nothing was spoken"]))

    def test_parse_speech_is_the_same_with_or_without_the_closed_set(self):
        log = log_for(self.right)
        closed = set()
        self.assertEqual(tb.parse_speech(log), tb.parse_speech(log, {}, closed))
        self.assertEqual(closed, set(self.right))


class C06SilentClicks(unittest.TestCase):
    """C06's declared silent rows, the clicks of `bad-expand-icon` and
    `bad-cupertino-expansion-tile`, with their markers logged just before
    the click action (C06DisclosureTest.talkBackWalk). Speech caused by the
    click then falls in the silent row and fails it. The judge itself is
    unchanged: a row that is not silent is checked for its phrases as
    substrings, so extra speech in it passes, which is why the marker must
    come before the click."""
    PREFIX = "c06-"
    SILENT = "c06-bad-expand-icon-activated"

    def setUp(self):
        self.expected = [i for i in tb.EXPECT if i.startswith(self.PREFIX)]
        self.assertEqual([i for i in self.expected if tb.is_silent(i)],
                         ["c06-bad-expand-icon-activated", "c06-bad-cupertino-expansion-tile-activated"])
        self.right = {i: [] if tb.is_silent(i) else list(tb.EXPECT[i][0]) for i in self.expected}
        order = list(self.right)
        self.assertEqual(order[order.index(self.SILENT) - 1], "c06-bad-expand-icon-closed")
        self.assertEqual(order[order.index(self.SILENT) + 1], "c06-bad-expand-icon-panel")

    def judge(self, speech):
        cut, closed = {}, set()
        spoken = tb.parse_speech(log_for(speech), cut, closed)
        return tb.judge_walk(spoken, self.expected, cut, closed)

    def test_the_right_walk_is_right(self):
        self.assertEqual(self.judge(self.right), ("right", []))

    def test_speech_during_the_click_fails_the_silent_row(self):
        # Codex's case: the panel's text said as the click opens it. With
        # the marker before the click it is in the silent row.
        for slug in ("bad-expand-icon", "bad-cupertino-expansion-tile"):
            speech = dict(self.right)
            speech[f"c06-{slug}-activated"] = ["Orders ship in two days."]
            verdict, reasons = self.judge(speech)
            self.assertEqual(verdict, "wrong", slug)
            self.assertIn(f'c06-{slug}-activated: expected silence, heard "Orders ship in two days."', reasons)

    def test_the_same_speech_before_the_marker_would_pass(self):
        # Why the marker is before the click: the closed row's phrases are
        # substrings, so the same speech logged in it is not caught.
        speech = dict(self.right)
        speech["c06-bad-expand-icon-closed"] = self.right["c06-bad-expand-icon-closed"] + ["Orders ship in two days."]
        self.assertEqual(self.judge(speech), ("right", []))


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

    def test_state_in_a_name_does_not_count_as_the_state(self):
        self.assertFalse(tb.said(["bluetooth on.", "switch"], "on"))
        self.assertFalse(tb.said(["bluetooth off"], "off"))
        self.assertTrue(tb.said(["checked. on.  ", "bluetooth on"], "on"))
        self.assertTrue(tb.said(["off, ", "repeat"], "Off"))

    def test_not_checked_does_not_count_as_checked(self):
        self.assertFalse(tb.said(["not checked. on."], "checked"))
        self.assertTrue(tb.said(["not checked. on."], "not checked"))
        self.assertTrue(tb.said(["checked. on."], "checked"))

    def test_a_switch_whose_name_says_its_state_must_say_the_state_as_well(self):
        self.assertTrue(tb.problems(
            "f09-bad-label-changes-bluetooth", ["Bluetooth off.", "Switch"]))
        self.assertTrue(tb.problems(
            "f09-bad-label-changes-bluetooth-changed",
            ["checked.", "Bluetooth on.", "Switch"]))
        self.assertTrue(tb.problems(
            "f09-good-tile-bluetooth-changed",
            ["not checked. on.", "Bluetooth", "Switch"]))
        self.assertEqual(tb.problems(
            "f09-bad-label-changes-bluetooth-changed",
            ["checked. on.  ", "Bluetooth on", "Switch"]), [])

    def test_forbidding_checked_forbids_not_checked_as_well(self):
        self.assertTrue(tb.unwanted(["not checked. off."], "checked"))
        self.assertTrue(tb.unwanted(["checked. on."], "checked"))
        self.assertFalse(tb.unwanted(["off.  ", "bluetooth"], "checked"))
        checked = 0
        for ident, (must, must_not) in tb.EXPECT.items():
            if "checked" not in [p.lower() for p in must_not]:
                continue
            checked += 1
            # Speech with everything the element must say passes; the same
            # speech with "not checked." in front fails, and for that reason.
            speech = [p + "." for p in must]
            self.assertEqual(tb.problems(ident, speech), [], ident)
            found = tb.problems(ident, ["not checked."] + speech)
            self.assertEqual(len(found), 1, ident)
            self.assertIn('did not expect "checked"', found[0])
        self.assertGreater(checked, 20)

    def test_expected_and_unexpected_phrases(self):
        self.assertEqual(tb.problems("c01-good-text-filled", ["Save", "Button"]), [])
        self.assertTrue(tb.problems("c01-good-text-filled", ["Save"]))
        self.assertTrue(tb.problems("c01-bad-gesture-only-save", ["Save", "Button"]))


SIGNAL_SCRIPT = r"""
import json, sys, time
sys.path.insert(0, sys.argv[1])
import talkback as tb

state_file, phase = sys.argv[2], sys.argv[3]
state = {"settings": {tb.SERVICES: "com.example.reader/.ReaderService", tb.ENABLED: "1"},
         "log_level": "ERROR", "ready": False}

def save():
    with open(state_file, "w") as f:
        json.dump(state, f)

walked = []

def adb(*args):
    # Cleanup's first write, before anything has been restored.
    if phase == "restore" and walked and not state["ready"]:
        wait_for_signal()
    if args[:3] == ("shell", "settings", "get"):
        return state["settings"].get(args[4], "null") + "\n"
    if args[:3] == ("shell", "settings", "put"):
        state["settings"][args[4]] = "" if args[5] == '""' else args[5]
    if args[:3] == ("shell", "settings", "delete"):
        state["settings"].pop(args[4], None)
    save()
    return ""

def wait_for_signal():
    state["ready"] = True
    save()
    # In cleanup the signal is deferred, so the wait is not cut short.
    time.sleep(1.5 if phase == "restore" else 30)

def set_log_level(level, on_read=None):
    previous = state["log_level"]
    if on_read:
        on_read(previous)
    state["log_level"] = level
    save()
    if phase == "setup" and level == "VERBOSE":
        wait_for_signal()
    return previous

tb.adb_checked = adb
tb.set_log_level = set_log_level
tb.exit_on_termination_signals()
tb.run_with_talkback(wait_for_signal if phase == "walk" else (lambda: walked.append(True)))
"""


@unittest.skipIf(sys.platform == "win32", "POSIX signals")
class Termination(unittest.TestCase):
    """A real process is sent a real signal while the device is changed."""

    def terminate_during(self, phase, signum):
        tool = os.path.dirname(os.path.abspath(__file__))
        with tempfile.TemporaryDirectory() as folder:
            state_file = os.path.join(folder, "state.json")
            process = subprocess.Popen(
                [sys.executable, "-c", SIGNAL_SCRIPT, tool, state_file, phase],
                stderr=subprocess.DEVNULL)
            try:
                deadline = time.time() + 20
                while time.time() < deadline:
                    try:
                        with open(state_file) as f:
                            if json.load(f)["ready"]:
                                break
                    except (OSError, ValueError):
                        pass
                    time.sleep(0.05)
                else:
                    self.fail("the script never reached the point to interrupt")
                with open(state_file) as f:
                    changed = json.load(f)
                process.send_signal(signum)
                code = process.wait(timeout=20)
            finally:
                process.kill()
            with open(state_file) as f:
                return changed, json.load(f), code

    def assert_restored(self, phase, signum):
        changed, after, code = self.terminate_during(phase, signum)
        # The device really was in a changed state when the signal arrived.
        self.assertEqual(changed["log_level"], "VERBOSE")
        self.assertNotEqual(code, 0)
        self.assertEqual(after["log_level"], "ERROR", (phase, signum))
        self.assertEqual(after["settings"],
                         {tb.SERVICES: OTHER, tb.ENABLED: "1"}, (phase, signum))

    def test_sigterm_during_the_walk_restores_the_device(self):
        self.assert_restored("walk", signal.SIGTERM)

    def test_sighup_during_the_walk_restores_the_device(self):
        self.assert_restored("walk", signal.SIGHUP)

    def test_sigterm_during_setup_restores_the_device(self):
        self.assert_restored("setup", signal.SIGTERM)

    def test_sighup_during_setup_restores_the_device(self):
        self.assert_restored("setup", signal.SIGHUP)

    def test_sigterm_during_restoration_still_restores_the_device(self):
        self.assert_restored("restore", signal.SIGTERM)

    def test_sighup_during_restoration_still_restores_the_device(self):
        self.assert_restored("restore", signal.SIGHUP)

    def test_interrupt_during_restoration_still_restores_the_device(self):
        self.assert_restored("restore", signal.SIGINT)

    def test_without_the_handler_a_signal_would_skip_cleanup(self):
        # Guards the test itself: with default handling the state stays changed.
        script = SIGNAL_SCRIPT.replace("tb.exit_on_termination_signals()", "")
        with mock.patch(__name__ + ".SIGNAL_SCRIPT", script):
            changed, after, _ = self.terminate_during("walk", signal.SIGTERM)
        self.assertEqual(after["log_level"], "VERBOSE")


class Timeouts(unittest.TestCase):
    STALL = [sys.executable, "-c", "import time; time.sleep(30)"]

    def stalled(self):
        """Patches so every adb call is a process that never finishes."""
        real_run = subprocess.run
        return (mock.patch.object(tb, "ADB_TIMEOUT", 0.3),
                mock.patch.object(tb.subprocess, "run",
                                  lambda cmd, **kw: real_run(self.STALL, **kw)))

    def test_a_stalled_checked_command_raises_instead_of_waiting(self):
        patches = self.stalled()
        started = time.time()
        with patches[0], patches[1]:
            with self.assertRaises(tb.AdbError) as caught:
                tb.adb_checked("shell", "settings", "get", "secure", tb.SERVICES)
        self.assertLess(time.time() - started, 5)
        self.assertIn("did not finish", str(caught.exception))

    def test_a_stalled_unchecked_command_returns_nothing(self):
        patches = self.stalled()
        with patches[0], patches[1]:
            self.assertEqual(tb.adb("logcat", "-d"), "")

    def test_a_stall_in_log_level_restore_still_restores_both_settings(self):
        before = {tb.SERVICES: OTHER, tb.ENABLED: "1"}
        device = FakeDevice(before)
        attempts = []

        def set_log_level(level, on_read=None):
            attempts.append(level)
            if len(attempts) == 2:  # the restore: a real stalled adb command
                patches = self.stalled()
                with patches[0], patches[1]:
                    tb.__dict__["_real_adb_checked"]("shell", "input", "tap", "1", "1")
            return device.set_log_level(level, on_read)

        started = time.time()
        with mock.patch.dict(tb.__dict__, {"_real_adb_checked": tb.adb_checked}), \
                mock.patch.object(tb, "adb_checked", device.adb), \
                mock.patch.object(tb, "set_log_level", set_log_level), \
                mock.patch("sys.stderr"):
            with self.assertRaises(tb.AdbError) as caught:
                tb.run_with_talkback(lambda: None)
        self.assertLess(time.time() - started, 5)
        self.assertEqual(device.settings, before)
        self.assertIn("log output level should be ERROR", str(caught.exception))
        self.assertIn("did not finish", str(caught.exception))

    def test_stalled_restore_writes_are_each_attempted_and_reported(self):
        before = {tb.SERVICES: OTHER, tb.ENABLED: "1"}
        device = FakeDevice(before, log_level="VERBOSE")  # no log-level cleanup
        calls = []

        def adb(*args):
            calls.append(args)
            if len(calls) > 6:  # the two restore writes
                raise tb.AdbError(f"adb {' '.join(args)} did not finish in 60 seconds")
            return device.adb(*args)

        with mock.patch.object(tb, "adb_checked", adb), \
                mock.patch.object(tb, "set_log_level", device.set_log_level), \
                mock.patch("sys.stderr"):
            with self.assertRaises(tb.AdbError) as caught:
                tb.run_with_talkback(lambda: None)
        self.assertEqual(len(calls), 8)  # both restores were tried
        message = str(caught.exception)
        self.assertIn(f"{tb.SERVICES} should be {OTHER!r}", message)
        self.assertIn(f"{tb.ENABLED} should be '1'", message)


class Techniques(unittest.TestCase):
    def test_heading_is_a_role_word_like_button(self):
        self.assertTrue(tb.said(["profile", "heading"], "Heading"))
        # The word inside a name is not the role.
        self.assertFalse(tb.said(["profile, heading"], "Heading"))
        self.assertEqual(tb.problems("s05-bad-fake-label-profile", ["Profile, heading"]), [])
        self.assertTrue(tb.problems("s05-bad-fake-label-profile", ["Profile", "Heading"]))

    def test_log_markers_from_any_technique_are_parsed(self):
        log = "\n".join([
            "I C01TB   : FOCUS c01-a",
            'V talkback: SpeechControllerImpl: Speaking fragment text="Save", utteranceId=x',
            "I S05TB   : FOCUS s05-b",
            'V talkback: SpeechControllerImpl: Speaking fragment text="Profile", utteranceId=x',
            "I S05TB   : END slug",
        ])
        self.assertEqual(tb.parse_speech(log), {"c01-a": ["Save"], "s05-b": ["Profile"]})

    def test_a_fragment_split_over_log_lines_is_joined(self):
        log = "\n".join([
            "I S02TB   : FOCUS s02-a",
            '11-14 14:05:20.227 1 1 V talkback: SpeechControllerImpl: Speaking fragment text="Delayed',
            '11-14 14:05:20.227 1 1 V talkback: SpeechControllerImpl: Order 1043", utteranceId=x',
            'V talkback: SpeechControllerImpl: Speaking fragment text="Image", utteranceId=x',
            "I S02TB   : END slug",
        ])
        self.assertEqual(tb.parse_speech(log), {"s02-a": ["Delayed Order 1043", "Image"]})

    def test_an_unfinished_fragment_never_takes_other_lines(self):
        speech = "11-14 14:05:20.227 1 1 V talkback: SpeechControllerImpl: "
        # Cut off by an unrelated log line that happens to hold the words.
        log = "\n".join([
            "I S02TB   : FOCUS s02-a",
            speech + 'Speaking fragment text="Delayed',
            '11-14 14:05:20.300 9 9 I Other: Order 1043", utteranceId=x',
            "I S02TB   : END slug",
        ])
        self.assertEqual(tb.parse_speech(log), {"s02-a": [tb.INCOMPLETE]})
        # Cut off by the next element's marker: its speech stays its own.
        log = "\n".join([
            "I S02TB   : FOCUS s02-a",
            speech + 'Speaking fragment text="Delayed',
            "I S02TB   : FOCUS s02-b",
            speech + 'Speaking fragment text="Image", utteranceId=x',
            "I S02TB   : END slug",
        ])
        self.assertEqual(tb.parse_speech(log), {"s02-a": [tb.INCOMPLETE], "s02-b": ["Image"]})
        # Cut off by another fragment.
        log = "\n".join([
            "I S02TB   : FOCUS s02-a",
            speech + 'Speaking fragment text="Delayed',
            speech + 'Speaking fragment text="Image", utteranceId=x',
            speech + 'Order 1043", utteranceId=x',
            "I S02TB   : END slug",
        ])
        self.assertEqual(tb.parse_speech(log), {"s02-a": [tb.INCOMPLETE, "Image"]})

    def test_cut_off_speech_fails_even_when_the_required_speech_was_heard(self):
        speech = "11-14 14:05:20.227 1 1 V talkback: SpeechControllerImpl: "
        # "Order 1042" is heard whole; a second fragment, which may have been
        # the forbidden "Delivered", is cut off.
        log = "\n".join([
            "I S02TB   : FOCUS s02-bad-icon-no-label-first",
            speech + 'Speaking fragment text="Order 1042", utteranceId=x',
            speech + 'Speaking fragment text="Delivered',
            "I S02TB   : END slug",
        ])
        heard = tb.parse_speech(log)["s02-bad-icon-no-label-first"]
        self.assertEqual(heard, ["Order 1042", tb.INCOMPLETE])
        self.assertTrue(tb.problems("s02-bad-icon-no-label-first", heard))
        self.assertFalse(tb.problems("s02-bad-icon-no-label-first", ["Order 1042"]))

    def test_a_missing_or_unknown_technique_is_refused(self):
        import evidence_common as common
        for argv in (["tool"], ["tool", "ZZZ"]):
            with self.assertRaises(SystemExit) as caught:
                common.technique_argument(argv, "Usage: x <ID>")
            self.assertIn("C01", str(caught.exception))
        self.assertEqual(common.technique_argument(["tool", "s05"], "Usage"), "S05")

    def test_a_technique_with_no_ios_voiceover_test_is_refused_with_a_reason(self):
        import voiceover_ios
        entry = {"X99": ("X99 Example", "X99Test", None, "x99_vo.spec.js")}
        with mock.patch.object(sys, "argv", ["voiceover_ios.py", "X99"]), \
                mock.patch.dict(voiceover_ios.TECHNIQUES, entry), \
                mock.patch.object(voiceover_ios.subprocess, "run") as run:
            with self.assertRaises(SystemExit) as caught:
                voiceover_ios.main()
        self.assertIn("no VoiceOver test on iOS", str(caught.exception))
        run.assert_not_called()

    def test_the_button_with_an_identifier_inside_must_be_read_without_its_name(self):
        # FL-007: what was captured passes, and a named button would fail.
        ident = "s22-bad-inside-button"
        self.assertEqual(tb.problems(ident, ["Button", "Double-tap to activate"]), [])
        self.assertTrue(tb.problems(ident, ["Save draft", "Button", "Double-tap to activate"]))
        # An identifier that was read aloud fails a good example.
        self.assertEqual(tb.problems("s22-good-merged-save", ["Save draft", "Button"]), [])
        self.assertTrue(tb.problems("s22-good-merged-save", ["s22 good merged save", "Button"]))

    def test_every_listed_technique_has_expectations(self):
        import evidence_common as common
        for technique in common.TECHNIQUES:
            prefix = technique.lower() + "-"
            self.assertTrue(any(k.startswith(prefix) for k in tb.EXPECT), technique)


if __name__ == "__main__":
    unittest.main()
