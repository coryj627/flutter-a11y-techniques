"""Tests for tool/ci_android_tests.sh.

The class list is checked everywhere. The runs with a stand-in Gradle, adb
and emulator need Linux, which is where the script runs on CI: it reads
/proc.
"""

import os
import stat
import subprocess
import sys
import tempfile
import textwrap
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parent / "ci_android_tests.sh"
PKG = "dev.fluttera11y.flutter_a11y_techniques"

TEST_CLASS = """\
package dev.fluttera11y.flutter_a11y_techniques

@RunWith(AndroidJUnit4::class)
class {name} : TechniqueTest {{
    @Test
    fun opens() {{}}
}}
"""


# What the test runner logs for a run with no tests in it, as seen on CI.
EMPTY_RUN = ("run started: 1 tests", "run finished: 0 tests, 0 failed, 0 ignored")

# The stand-in device's times: of the line the script writes at the start
# of the run, of the batches' lines, of the line it writes as the sweep
# starts, and of the sweep's lines.
RUN_START_TIME = "11-17 21:20:00.000"
BATCH_TIME = "11-17 21:25:29.060"
MARK_TIME = "11-17 21:28:00.000"
SWEEP_TIME = "11-17 21:30:00.000"


def write_class(folder, name, text=None):
    (folder / f"{name}.kt").write_text(text or TEST_CLASS.format(name=name))


class Workspace:
    """A folder laid out like the checkout, with stand-ins on the PATH."""

    def __init__(self, test):
        self.root = Path(tempfile.mkdtemp())
        test.addCleanup(subprocess.run, ["rm", "-rf", str(self.root)])
        self.android = self.root / "android"
        self.tests = self.root / "tests"
        self.bin = self.root / "bin"
        self.diag = self.root / "diag"
        for folder in (self.android, self.tests, self.bin):
            folder.mkdir()
        # The device's log of the test runner, which the stand-in Gradle
        # writes to and the stand-in adb reads.
        self.runner_log = self.root / "runner.txt"
        self.runner_log.write_text("")
        # Shell that prints the stand-in device's log as `logcat -d` gives
        # it, with the marker lines the script wrote to it; or the markers
        # only, a device that gives none of the test runner's lines.
        self.marks = f'cat "{self.root}/marks" 2>/dev/null'
        self.device = f'{self.marks}; cat "{self.runner_log}"'
        self.adb()
        self.tool("pgrep", "exit 0")
        self.tool("sudo", "exit 0")
        self.gradle("exit 0")

    def adb(self, reader="follow", dump=None, clear=None):
        """A stand-in adb. The reader of the test runner's log runs
        `reader`, with $n its start count and $first the first line logcat
        gives from the -T time on; `follow` reads the device's log from
        there, `read_lines LOSE STOP` reads it but leaves out the first
        line with LOSE in it and stops after the first with STOP in it, each
        once only, `stop_once_after STOP` only stops, and `drop_lines TEXT`
        never writes a line with TEXT in it, however often it starts again
        from an earlier time. `logcat -d` runs
        `dump`, with $d its call count, by default `self.device`;
        `logcat -c` runs `clear`, by default emptying the device's log."""
        log, root = self.runner_log, self.root
        dump = dump or self.device
        clear = clear or f': > "{log}"'
        self.tool("adb", f"""\
            follow() {{ exec tail -s 0.1 -n "+$first" -f "{log}"; }}
            read_lines() {{
              lose=$1 stop=$2
              {{ [ -z "$lose" ] || [ -e "{root}/reader-lost" ]; }} \\
                && {{ [ -z "$stop" ] || [ -e "{root}/reader-stopped" ]; }} && follow
              k=$first
              while :; do
                line=$(sed -n "${{k}}p" "{log}")
                if [ -z "$line" ]; then sleep 0.05; continue; fi
                k=$((k + 1))
                if [ -n "$lose" ] && [ ! -e "{root}/reader-lost" ] && [[ $line == *"$lose"* ]]; then
                  touch "{root}/reader-lost"
                  continue
                fi
                echo "$line"
                if [ -n "$stop" ] && [ ! -e "{root}/reader-stopped" ] && [[ $line == *"$stop"* ]]; then
                  touch "{root}/reader-stopped"
                  exit 0
                fi
              done
            }}
            stop_once_after() {{ read_lines "" "$1"; }}
            drop_lines() {{
              k=$first
              while :; do
                line=$(sed -n "${{k}}p" "{log}")
                if [ -z "$line" ]; then sleep 0.05; continue; fi
                k=$((k + 1))
                [[ $line == *"$1"* ]] || echo "$line"
              done
            }}
            case "$*" in
              "logcat -c") {clear} ;;
              "logcat -G"*|"logcat -d -b"*) exit 0 ;;
              "logcat -d"*TestRunner:I*)
                d=$(($(cat "{root}/dumps" 2>/dev/null || echo 0) + 1))
                echo "$d" > "{root}/dumps"
                {dump} ;;
              "logcat -d"*CiBoundary:I*) cat "{root}/marks" 2>/dev/null ;;
              "shell log -t CiBoundary"*)
                text=${{@: -1}}
                case $text in *run_start*) t="{RUN_START_TIME}" ;; *) t="{MARK_TIME}" ;; esac
                echo "$t  1000  1000 I CiBoundary: $text" >> "{root}/marks" ;;
              *TestRunner:I*)
                n=$(($(cat "{root}/reader-starts" 2>/dev/null || echo 0) + 1))
                echo "$n" > "{root}/reader-starts"
                since=""
                while [ $# -gt 0 ]; do [ "$1" = -T ] && since=$2; shift; done
                first=$(awk -v s="$since" 'substr($0, 1, 18) >= s {{ print NR; exit }}' "{log}")
                first=${{first:-$(($(wc -l < "{log}") + 1))}}
                {reader} ;;
              logcat*) exec sleep 60 ;;
            esac
            exit 0
            """)

    def tool(self, name, body, folder=None):
        path = (folder or self.bin) / name
        path.write_text("#!/bin/bash\n" + textwrap.dedent(body))
        path.chmod(path.stat().st_mode | stat.S_IEXEC)

    def gradle(self, body, sweep=None):
        """A stand-in Gradle. In a batch it logs a finished test for each
        class of the batch given to `finished`, then runs `body`. In the
        sweep it reports a run with no tests, or runs `sweep` in its
        place."""
        sweep = sweep or self.logs(*EMPTY_RUN) + "exit 0"
        self.tool("gradlew", f"""\
            echo "$@" >> "$PWD/calls"
            case "$*" in *notClass=*) {sweep} ;; esac
            for name in $(cat "{self.root}/finished" 2>/dev/null); do
              case "$*" in *class=*"{PKG}.$name"*)
                echo "{BATCH_TIME}  4037  4051 I TestRunner: finished: opens({PKG}.$name)" \\
                  >> "{self.runner_log}" ;;
              esac
            done
            """ + textwrap.dedent(body), self.android)

    def logs(self, *lines, time=SWEEP_TIME):
        """Shell that adds these lines to the test runner's log."""
        return "".join(
            f'echo "{time}  4037  4051 I TestRunner: {line}" >> "{self.runner_log}"; '
            for line in lines)

    def finished(self, *names):
        """A test of each of these classes finishes when its batch runs."""
        (self.root / "finished").write_text("\n".join(names) + "\n")

    def reader_log(self):
        """The test runner's lines the script's reader wrote."""
        return [line for line in (self.diag / "test-runner.log").read_text().splitlines()
                if "TestRunner: " in line]

    def run(self, *args, **env):
        return subprocess.run(
            ["bash", str(SCRIPT), *args],
            cwd=self.android, capture_output=True, text=True, timeout=120,
            env={**os.environ,
                 "PATH": f"{self.bin}{os.pathsep}{os.environ['PATH']}",
                 "TEST_DIR": str(self.tests), "DIAG_DIR": str(self.diag),
                 "POLL_SECONDS": "0.5", "SETTLE_SECONDS": "0.5", **env})


class ClassListTest(unittest.TestCase):
    def setUp(self):
        self.space = Workspace(self)

    def listed(self):
        result = self.space.run("--list")
        return result.returncode, result.stdout.split(), result.stderr

    def test_lists_every_class_with_a_test_in_name_order(self):
        for name in ("S01NamesTest", "C01ButtonTest"):
            write_class(self.space.tests, name)
        (self.space.tests / "TechniqueTest.kt").write_text(
            "interface TechniqueTest {\n    fun open() {}\n}\n")
        self.assertEqual(self.listed()[:2], (0, ["C01ButtonTest", "S01NamesTest"]))

    def test_a_class_is_listed_however_its_annotations_are_laid_out(self):
        write_class(self.space.tests, "C01ButtonTest", textwrap.indent(
            TEST_CLASS.format(name="C01ButtonTest"), "  "))
        write_class(self.space.tests, "F01FieldsTest",
                    "class F01FieldsTest {\n\t@Test fun opens() {}\n}\n")
        write_class(self.space.tests, "S01NamesTest",
                    "internal open class S01NamesTest {\n"
                    "    @Ignore @Test fun opens() {}\n}\n")
        self.assertEqual(self.listed()[:2],
                         (0, ["C01ButtonTest", "F01FieldsTest", "S01NamesTest"]))

    def test_the_real_folder_lists_every_test_file(self):
        folder = SCRIPT.parents[1] / "android/app/src/androidTest/kotlin" / PKG.replace(".", "/")
        expected = sorted(p.stem for p in folder.glob("*.kt") if "@Test" in p.read_text())
        self.assertTrue(expected)
        result = self.space.run("--list", TEST_DIR=str(folder))
        self.assertEqual((result.returncode, result.stdout.split()), (0, expected))

    def test_fails_when_no_file_has_a_test(self):
        (self.space.tests / "TechniqueTest.kt").write_text("interface TechniqueTest\n")
        code, names, error = self.listed()
        self.assertEqual((code, names), (1, []))
        self.assertIn("has a @Test", error)

    def test_fails_when_the_folder_is_missing(self):
        result = self.space.run("--list", TEST_DIR=str(self.space.root / "gone"))
        self.assertEqual(result.returncode, 1)
        self.assertIn("no test folder", result.stderr)

    def test_fails_when_a_test_file_has_no_class_of_its_name(self):
        write_class(self.space.tests, "C01ButtonTest",
                    TEST_CLASS.format(name="SomethingElse"))
        code, names, error = self.listed()
        self.assertEqual((code, names), (1, []))
        self.assertIn("no class named C01ButtonTest", error)

    def test_runs_nothing_when_there_are_no_classes(self):
        result = self.space.run()
        self.assertEqual(result.returncode, 1)
        self.assertFalse((self.space.android / "calls").exists())


@unittest.skipUnless(sys.platform.startswith("linux"), "the script reads /proc")
class RunTest(unittest.TestCase):
    def setUp(self):
        self.space = Workspace(self)
        self.names = ["C01ButtonTest", "F01FieldsTest", "S01NamesTest"]
        for name in self.names:
            write_class(self.space.tests, name)
        self.space.gradle("exit 0")

    def calls(self):
        return (self.space.android / "calls").read_text().splitlines()

    def batches(self):
        return [call for call in self.calls() if "notClass=" not in call]

    def test_passes_when_every_class_ran(self):
        self.space.finished(*self.names)
        result = self.space.run("-Pextra=1", BATCH_CLASSES="2")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        calls = self.batches()
        self.assertEqual(len(calls), 2)
        self.assertIn(
            "notClass=" + ",".join(f"{PKG}.{name}" for name in self.names) + " -Pextra=1",
            self.calls()[-1])
        self.assertIn("sweep: no test outside the list", result.stdout)
        self.assertIn(f"class={PKG}.C01ButtonTest,{PKG}.F01FieldsTest -Pextra=1", calls[0])
        self.assertIn(f"class={PKG}.S01NamesTest -Pextra=1", calls[1])

    def test_runs_each_class_in_a_batch_of_its_own_by_default(self):
        self.space.finished(*self.names)
        result = self.space.run()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("3 test classes, in batches of 1", result.stdout)
        self.assertEqual([call.split()[1] for call in self.batches()],
                         [f"-Pandroid.testInstrumentationRunnerArguments.class={PKG}.{name}"
                          for name in self.names])

    def test_fails_when_a_class_never_ran(self):
        self.space.finished("C01ButtonTest", "S01NamesTest")
        result = self.space.run()
        self.assertEqual(result.returncode, 1)
        self.assertIn("no test of F01FieldsTest finished", result.stdout)

    def test_fails_when_a_batch_fails_and_still_runs_the_rest(self):
        self.space.finished(*self.names)
        self.space.gradle('case "$*" in *class=*C01ButtonTest*) exit 3 ;; esac; exit 0')
        result = self.space.run(BATCH_CLASSES="1")
        self.assertEqual(result.returncode, 1)
        self.assertIn("batch 1 failed: Gradle exit code 3", result.stdout)
        self.assertEqual(len(self.batches()), 3)

    def test_fails_when_the_sweep_finds_a_test_the_list_missed(self):
        self.space.finished(*self.names)
        self.space.gradle("exit 0", sweep=self.space.logs(
            "run started: 1 tests", f"started: opens({PKG}.MissedTest)",
            f"finished: opens({PKG}.MissedTest)",
            "run finished: 1 tests, 0 failed, 0 ignored") + "exit 0")
        result = self.space.run()
        self.assertEqual(result.returncode, 1)
        self.assertIn("not an empty run", result.stdout)
        self.assertIn(f"started: opens({PKG}.MissedTest)", result.stdout)

    def test_fails_when_a_missed_class_fails_before_its_first_test(self):
        # A failure in @BeforeClass: a count above 0 and no test ever starts.
        self.space.finished(*self.names)
        self.space.gradle("exit 0", sweep=self.space.logs(
            "run started: 1 tests", f"failed: initializationError({PKG}.MissedTest)",
            "run finished: 0 tests, 1 failed, 0 ignored") + "exit 1")
        result = self.space.run()
        self.assertEqual(result.returncode, 1)
        self.assertIn("not an empty run", result.stdout)

    def test_fails_when_the_sweep_ran_twice(self):
        self.space.finished(*self.names)
        self.space.gradle("exit 0", sweep=self.space.logs(*EMPTY_RUN, *EMPTY_RUN) + "exit 0")
        result = self.space.run()
        self.assertEqual(result.returncode, 1)
        self.assertIn("not an empty run", result.stdout)

    def test_fails_when_a_missed_class_is_ignored(self):
        self.space.finished(*self.names)
        self.space.gradle("exit 0", sweep=self.space.logs(
            "run started: 1 tests", "run finished: 0 tests, 0 failed, 1 ignored") + "exit 0")
        result = self.space.run()
        self.assertEqual(result.returncode, 1)
        self.assertIn("not an empty run", result.stdout)

    def test_fails_when_the_sweep_ends_after_it_started_with_tests(self):
        self.space.finished(*self.names)
        self.space.gradle("exit 0", sweep=self.space.logs("run started: 2 tests") + "exit 1")
        result = self.space.run()
        self.assertEqual(result.returncode, 1)
        self.assertIn("not an empty run", result.stdout)

    def test_fails_when_an_empty_sweep_never_finished(self):
        self.space.finished(*self.names)
        self.space.gradle("exit 0", sweep=self.space.logs(EMPTY_RUN[0]) + "exit 0")
        result = self.space.run()
        self.assertEqual(result.returncode, 1)
        self.assertIn("not an empty run", result.stdout)

    def test_fails_when_the_sweep_never_reaches_the_test_runner(self):
        self.space.finished(*self.names)
        self.space.gradle("exit 0", sweep="exit 1")
        result = self.space.run()
        self.assertEqual(result.returncode, 1)
        self.assertIn("the sweep never reached the test runner", result.stdout)

    def test_a_sweep_gradle_calls_a_failure_passes_when_it_found_no_tests(self):
        self.space.finished(*self.names)
        self.space.gradle(
            "exit 0", sweep=self.space.logs(*EMPTY_RUN) + "exit 1")
        result = self.space.run()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_a_batch_that_ended_during_the_wait_keeps_its_own_result(self):
        # Gradle is over before the first check, and the time limit has
        # passed by then: the batch passed and must not be stopped.
        self.space.finished(*self.names)
        result = self.space.run(LIMIT_SECONDS="0")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotIn("STOPPING THE TESTS", result.stdout)

    def test_stops_a_run_that_is_still_going_past_the_limit(self):
        self.space.finished(*self.names)
        self.space.gradle('[ "$1" = --stop ] && exit 0; exec sleep 60', sweep="exec sleep 60")
        result = self.space.run(LIMIT_SECONDS="0")
        self.assertEqual(result.returncode, 1)
        self.assertIn("STOPPING THE TESTS", result.stdout)


    # A reader of the device's log can stop on its own, or run and write
    # nothing; the result must be the same as with one that never did.

    def assert_passed_once_each(self, result):
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotIn("CiBoundary", (self.space.diag / "test-runner.log").read_text())
        log = self.space.reader_log()
        self.assertEqual(len(log), len(set(log)), "\n".join(log))
        for name in self.names:
            self.assertEqual(sum(f"({PKG}.{name})" in line for line in log), 1, log)

    def test_a_reader_that_stops_at_once_is_started_again(self):
        # The device's log gives nothing: the lines come from the restart.
        self.space.adb(reader='[ "$n" -eq 1 ] && exit 0; follow', dump=self.space.marks)
        self.space.finished(*self.names)
        result = self.space.run()
        self.assert_passed_once_each(result)
        self.assertIn("the reader of the test runner's log stopped (exit code 0); "
                      "restart 1, from the start of the device's log", result.stdout)
        self.assertIn("restarts of the test runner's log reader: 1,", result.stdout)

    def test_a_reader_started_again_at_once_still_fails_a_class_that_did_not_run(self):
        self.space.adb(reader='[ "$n" -eq 1 ] && exit 0; follow', dump=self.space.marks)
        self.space.finished("C01ButtonTest", "S01NamesTest")
        result = self.space.run()
        self.assertEqual(result.returncode, 1)
        self.assertIn("no test of F01FieldsTest finished", result.stdout)
        self.assertIn("restarts of the test runner's log reader: 1;", result.stdout)

    def mid_batch(self, *later):
        """One batch of all three classes that logs C01ButtonTest's test,
        then the classes `later`, while the reader stops after the first."""
        self.space.adb(reader="stop_once_after C01ButtonTest", dump=self.space.marks)
        self.space.gradle(
            self.space.logs(f"finished: opens({PKG}.C01ButtonTest)", time=BATCH_TIME)
            + "sleep 1; "
            + self.space.logs(*(f"finished: opens({PKG}.{name})" for name in later),
                              time=BATCH_TIME)
            + "exit 0")
        return self.space.run(BATCH_CLASSES="3")

    def test_a_reader_that_stops_during_a_batch_goes_on_from_where_it_stopped(self):
        result = self.mid_batch("F01FieldsTest", "S01NamesTest")
        self.assert_passed_once_each(result)
        self.assertIn(f"restart 1, from {BATCH_TIME}, leaving out the lines it already has",
                      result.stdout)

    def test_a_reader_that_stops_during_a_batch_still_fails_a_class_that_did_not_run(self):
        result = self.mid_batch("S01NamesTest")
        self.assertEqual(result.returncode, 1)
        self.assertIn("restart 1, from", result.stdout)
        self.assertIn("no test of F01FieldsTest finished", result.stdout)

    def test_a_reader_that_stops_after_a_one_class_batch_goes_on_from_where_it_stopped(self):
        # One class a batch: the reader stops after batch 1's line and is
        # started again before batch 2 has written anything.
        self.space.adb(reader="stop_once_after C01ButtonTest", dump=self.space.marks)
        self.space.finished(*self.names)
        result = self.space.run()
        self.assert_passed_once_each(result)
        self.assertIn(f"restart 1, from {BATCH_TIME}, leaving out the lines it already has",
                      result.stdout)

    def test_a_line_written_again_after_a_restart_in_the_sweep_is_left_out(self):
        # logcat repeats the sweep's start from the -T time; a second start
        # would fail the sweep.
        self.space.adb(reader='stop_once_after "run started"')
        self.space.finished(*self.names)
        self.space.gradle("exit 0", sweep=self.space.logs(EMPTY_RUN[0]) + "sleep 1; "
                          + self.space.logs(EMPTY_RUN[1]) + "exit 0")
        result = self.space.run()
        self.assert_passed_once_each(result)
        self.assertIn(f"restart 1, from {SWEEP_TIME}", result.stdout)
        self.assertIn("sweep: no test outside the list", result.stdout)
        self.assertEqual(sum("run started" in line for line in self.space.reader_log()), 1)

    def test_a_reader_that_stops_during_the_sweep_still_finds_a_missed_class(self):
        self.space.adb(reader='stop_once_after "run started"')
        self.space.finished(*self.names)
        self.space.gradle("exit 0", sweep=self.space.logs("run started: 1 tests") + "sleep 1; "
                          + self.space.logs(f"started: opens({PKG}.MissedTest)",
                                            f"finished: opens({PKG}.MissedTest)",
                                            "run finished: 1 tests, 0 failed, 0 ignored")
                          + "exit 0")
        result = self.space.run()
        self.assertEqual(result.returncode, 1)
        self.assertIn("restart 1, from", result.stdout)
        self.assertIn("not an empty run", result.stdout)
        self.assertIn(f"finished: opens({PKG}.MissedTest)", result.stdout)

    def test_a_reader_that_writes_nothing_is_made_up_for_from_the_devices_log(self):
        self.space.adb(reader="exec sleep 60")
        self.space.finished(*self.names)
        result = self.space.run()
        self.assert_passed_once_each(result)
        self.assertIn("reader fault: Gradle passed batch 1, but the reader wrote no test "
                      "runner line for it", result.stdout)
        self.assertIn("reader fault: Gradle passed the sweep", result.stdout)
        self.assertIn("sweep: no test outside the list", result.stdout)
        self.assertIn("which added 5 test runner lines", result.stdout)

    def test_a_reader_that_writes_nothing_still_fails_a_class_that_did_not_run(self):
        self.space.adb(reader="exec sleep 60")
        self.space.finished("C01ButtonTest", "S01NamesTest")
        result = self.space.run()
        self.assertEqual(result.returncode, 1)
        self.assertIn("reader fault", result.stdout)
        self.assertIn("no test of F01FieldsTest finished", result.stdout)

    def test_fails_and_says_why_when_neither_the_reader_nor_the_device_has_the_lines(self):
        # The device's log can be read at the start only.
        self.space.adb(reader="exec sleep 60",
                       dump=f'[ "$d" -gt 1 ] && exit 1; {self.space.device}')
        self.space.finished(*self.names)
        result = self.space.run()
        self.assertEqual(result.returncode, 1)
        self.assertIn("could not read the device's log", result.stdout)
        self.assertIn("the sweep could not be confirmed against the device's log", result.stdout)
        self.assertIn("checks that could not use the device's log", result.stdout)
        self.assertIn("no test of C01ButtonTest finished", result.stdout)

    def test_a_reader_that_writes_nothing_is_not_taken_for_a_stalled_run(self):
        self.space.adb(reader="exec sleep 60")
        self.space.finished(*self.names)
        self.space.gradle("sleep 2; exit 0")
        result = self.space.run(FIRST_TEST_SECONDS="1")
        self.assert_passed_once_each(result)
        self.assertIn("the device's log has tests the reader did not write; carrying on",
                      result.stdout)
        self.assertNotIn("STOPPING THE TESTS", result.stdout)


    # The device's log must hold only this run's test runner lines.

    def test_fails_before_any_test_when_the_devices_log_keeps_an_earlier_runs_lines(self):
        # An earlier run finished F01FieldsTest; this one never runs it.
        self.space.runner_log.write_text(
            f"11-16 09:00:00.000  3000  3010 I TestRunner: finished: opens({PKG}.F01FieldsTest)\n")
        self.space.adb(clear="exit 1")
        self.space.finished("C01ButtonTest", "S01NamesTest")
        result = self.space.run()
        self.assertEqual(result.returncode, 1)
        self.assertIn("adb logcat -c failed (try 3 of 3)", result.stdout)
        self.assertIn("failed: the device's log could not be cleared of test runner lines",
                      result.stdout)
        self.assertFalse((self.space.android / "calls").exists())

    def test_runs_when_logcat_reports_a_failed_clear_but_the_log_is_clear(self):
        self.space.adb(clear="exit 1")
        self.space.finished(*self.names)
        result = self.space.run()
        self.assert_passed_once_each(result)
        self.assertIn("adb logcat -c failed (try 1 of 3)", result.stdout)

    # The sweep's lines are the device's from the sweep's start on, wherever
    # a batch's line that comes late ends up in the reader's log.

    def lost_batch_summary(self, sweep, dump=None):
        """One batch of all three classes. The reader leaves out the
        batch's last line and stops in the sweep after its start."""
        self.space.adb(reader='read_lines "run finished: 3 tests" "run started"', dump=dump)
        self.space.finished(*self.names)
        self.space.gradle(self.space.logs("run finished: 3 tests, 0 failed, 0 ignored",
                                          time=BATCH_TIME) + "exit 0", sweep=sweep)
        return self.space.run(BATCH_CLASSES="3")

    def empty_sweep_in_two_parts(self):
        return (self.space.logs(EMPTY_RUN[0]) + "sleep 1; "
                + self.space.logs(EMPTY_RUN[1]) + "exit 0")

    def test_a_batch_line_the_reader_missed_is_not_taken_for_the_sweeps(self):
        result = self.lost_batch_summary(self.empty_sweep_in_two_parts())
        self.assert_passed_once_each(result)
        self.assertIn(f"from {MARK_TIME} on", result.stdout)
        self.assertIn("sweep: no test outside the list", result.stdout)
        self.assertEqual(
            sum("run finished: 3 tests" in line for line in self.space.reader_log()), 1)

    def test_a_late_batch_line_is_not_the_sweeps_when_the_check_before_it_fails(self):
        # The device's log cannot be read just before the sweep (the second
        # dump), so the batch's last line only comes after the sweep.
        result = self.lost_batch_summary(
            self.empty_sweep_in_two_parts(),
            dump=f'[ "$d" -eq 2 ] && exit 1; {self.space.device}')
        self.assert_passed_once_each(result)
        self.assertIn("could not all be checked against the device's log before the sweep",
                      result.stdout)
        self.assertIn("sweep: no test outside the list", result.stdout)
        self.assertEqual(
            sum("run finished: 3 tests" in line for line in self.space.reader_log()), 1)

    def test_a_sweep_that_finds_a_missed_class_fails_after_a_lost_batch_line(self):
        result = self.lost_batch_summary(
            self.space.logs("run started: 1 tests") + "sleep 1; "
            + self.space.logs(f"started: opens({PKG}.MissedTest)",
                              f"finished: opens({PKG}.MissedTest)",
                              "run finished: 1 tests, 0 failed, 0 ignored") + "exit 0")
        self.assertEqual(result.returncode, 1)
        self.assertIn("not an empty run", result.stdout)
        swept = result.stdout.split("The test runner logged:")[1]
        self.assertIn(f"finished: opens({PKG}.MissedTest)", swept)
        self.assertNotIn("run finished: 3 tests", swept)

    # A reader that keeps running but leaves out a line: the device's log
    # makes up for it before anything is failed. (The class check is shown
    # failing a class that really did not run, with a reader that writes
    # every line, by test_fails_when_a_class_never_ran.)

    def test_a_sweep_finish_the_running_reader_left_out_is_taken_from_the_device(self):
        self.space.adb(reader='read_lines "run finished: 0 tests" ""')
        self.space.finished(*self.names)
        result = self.space.run()
        self.assert_passed_once_each(result)
        self.assertIn("sweep: checking its lines against the device's log before judging it",
                      result.stdout)
        self.assertIn("took from the device's log 1 test runner lines", result.stdout)
        self.assertIn("sweep: no test outside the list", result.stdout)
        self.assertIn("restarts of the test runner's log reader: 0,", result.stdout)

    def test_a_sweep_that_finds_a_missed_class_fails_when_the_reader_left_out_its_finish(self):
        self.space.adb(reader='read_lines "run finished: 1 tests" ""')
        self.space.finished(*self.names)
        self.space.gradle("exit 0", sweep=self.space.logs(
            "run started: 1 tests", f"started: opens({PKG}.MissedTest)",
            f"finished: opens({PKG}.MissedTest)",
            "run finished: 1 tests, 0 failed, 0 ignored") + "exit 0")
        result = self.space.run()
        self.assertEqual(result.returncode, 1)
        self.assertIn("sweep: checking its lines against the device's log before judging it",
                      result.stdout)
        self.assertIn("not an empty run", result.stdout)
        self.assertIn("run finished: 1 tests, 0 failed, 0 ignored",
                      result.stdout.split("The test runner logged:")[1])

    def late_dump(self, text):
        """A device's log that gives the lines with `text` in them only
        from its fourth read on. With one batch of every class, whose run
        the reader has lines for, that is not at the start, before the sweep
        or when the sweep is checked, but at the class check."""
        return (f'if [ "$d" -le 3 ]; then {self.space.marks}; '
                f'grep -vF "{text}" "{self.space.runner_log}"; else {self.space.device}; fi')

    def test_a_class_line_the_running_reader_left_out_is_taken_from_the_device(self):
        # The reader never writes the line, even when it is started again
        # from an earlier time, and the device gives it only at the class
        # check.
        self.space.adb(reader=f'drop_lines "({PKG}.F01FieldsTest)"',
                       dump=self.late_dump(f"({PKG}.F01FieldsTest)"))
        self.space.finished(*self.names)
        result = self.space.run(BATCH_CLASSES="3")
        self.assert_passed_once_each(result)
        self.assertIn("a class has no finished test in the reader's log; checking the device's log",
                      result.stdout)
        self.assertIn("restarts of the test runner's log reader: 0,", result.stdout)

    def test_a_one_class_batch_the_running_reader_left_out_is_taken_from_the_device(self):
        # One class a batch: F01FieldsTest's batch has no line in the
        # reader's log, so its line is taken from the device's log as soon
        # as the batch ends.
        self.space.adb(reader=f'drop_lines "({PKG}.F01FieldsTest)"')
        self.space.finished(*self.names)
        result = self.space.run()
        self.assert_passed_once_each(result)
        self.assertIn("reader fault: Gradle passed batch 2, but the reader wrote no test "
                      "runner line for it", result.stdout)
        self.assertNotIn("reader fault: Gradle passed batch 1", result.stdout)
        self.assertNotIn("a class has no finished test in the reader's log", result.stdout)

    def test_a_one_class_batch_the_reader_and_the_device_both_lack_fails_its_class(self):
        # Neither the reader nor the device's log ever has F01FieldsTest's
        # line, though Gradle passed its batch.
        self.space.adb(reader=f'drop_lines "({PKG}.F01FieldsTest)"',
                       dump=f'{self.space.marks}; '
                            f'grep -vF "({PKG}.F01FieldsTest)" "{self.space.runner_log}"')
        self.space.finished(*self.names)
        result = self.space.run()
        self.assertEqual(result.returncode, 1)
        self.assertIn("reader fault: Gradle passed batch 2", result.stdout)
        self.assertIn("no test of F01FieldsTest finished", result.stdout)
        self.assertNotIn("no test of C01ButtonTest finished", result.stdout)

    # A sweep that looks empty in the reader's log is still checked against
    # the device's: the reader can have left out a second run or a test.

    def sweep_with_hidden_lines(self, *hidden, dump=None):
        """An empty sweep run, then `hidden` lines at a later time that the
        running reader never writes; Gradle calls the sweep failed."""
        later = "11-17 21:31:00.000"
        self.space.adb(reader=f'drop_lines "{later}"', dump=dump)
        self.space.finished(*self.names)
        self.space.gradle("exit 0", sweep=self.space.logs(*EMPTY_RUN)
                          + self.space.logs(*hidden, time=later) + "exit 1")
        return self.space.run()

    def test_a_second_failing_run_the_reader_left_out_fails_the_sweep(self):
        result = self.sweep_with_hidden_lines(
            "run started: 1 tests", f"failed: initializationError({PKG}.MissedTest)",
            "run finished: 0 tests, 1 failed, 0 ignored")
        self.assertEqual(result.returncode, 1)
        self.assertIn("sweep: checking its lines against the device's log", result.stdout)
        self.assertIn("not an empty run", result.stdout)
        self.assertIn(f"failed: initializationError({PKG}.MissedTest)",
                      result.stdout.split("The test runner logged:")[1])

    def test_a_missed_class_test_the_reader_left_out_fails_the_sweep(self):
        result = self.sweep_with_hidden_lines(
            f"started: opens({PKG}.MissedTest)", f"finished: opens({PKG}.MissedTest)")
        self.assertEqual(result.returncode, 1)
        self.assertIn("not an empty run", result.stdout)
        self.assertIn(f"started: opens({PKG}.MissedTest)",
                      result.stdout.split("The test runner logged:")[1])

    def test_a_sweep_that_cannot_be_checked_against_the_device_fails(self):
        # The device's log can be read at the start and before the sweep only.
        result = self.sweep_with_hidden_lines(
            f"started: opens({PKG}.MissedTest)", f"finished: opens({PKG}.MissedTest)",
            dump=f'[ "$d" -gt 2 ] && exit 1; {self.space.device}')
        self.assertEqual(result.returncode, 1)
        self.assertIn("failed: the sweep could not be confirmed against the device's log",
                      result.stdout)
        self.assertNotIn("sweep: no test outside the list", result.stdout)

    # A device's log that can be read but has dropped its oldest lines
    # cannot show that nothing is missing.

    def failing_second_run(self, dump):
        return self.sweep_with_hidden_lines(
            "run started: 1 tests", f"failed: initializationError({PKG}.MissedTest)",
            "run finished: 0 tests, 1 failed, 0 ignored", dump=dump)

    def test_a_sweep_fails_when_the_devices_log_comes_back_empty(self):
        # From the check of the sweep on, the device's log is read but empty.
        result = self.failing_second_run(f'[ "$d" -ge 3 ] && exit 0; {self.space.device}')
        self.assertEqual(result.returncode, 1)
        self.assertIn("the device's log no longer goes back to the sweep's start", result.stdout)
        self.assertIn("failed: the sweep could not be confirmed against the device's log: it "
                      "no longer goes back to the sweep's start", result.stdout)
        self.assertNotIn("sweep: no test outside the list", result.stdout)

    def test_a_sweep_fails_when_the_devices_log_has_dropped_its_start(self):
        # From the check of the sweep on, the device's log has only the
        # empty run: the markers and the failing run have been dropped.
        result = self.failing_second_run(
            f'[ "$d" -ge 3 ] && {{ grep -F "{SWEEP_TIME}" "{self.space.runner_log}"; exit 0; }}; '
            f'{self.space.device}')
        self.assertEqual(result.returncode, 1)
        self.assertIn("it no longer goes back to the sweep's start", result.stdout)
        self.assertNotIn("sweep: no test outside the list", result.stdout)

    def test_a_missing_class_fails_when_the_devices_log_has_dropped_the_runs_start(self):
        # The reader never writes F01FieldsTest's line, and from before the
        # sweep on the device's log has dropped it and the run's marker.
        self.space.adb(
            reader=f'drop_lines "({PKG}.F01FieldsTest)"',
            dump=f'if [ "$d" -ge 2 ]; then {self.space.marks} | grep -v _run_start_; '
                 f'grep -vF "({PKG}.F01FieldsTest)" "{self.space.runner_log}"; '
                 f'else {self.space.device}; fi')
        self.space.finished(*self.names)
        result = self.space.run()
        self.assertEqual(result.returncode, 1)
        self.assertIn("sweep: no test outside the list", result.stdout)
        self.assertIn("the device's log no longer goes back to the start of the run",
                      result.stdout)
        self.assertIn("no test of F01FieldsTest finished (the log shows 2 finished tests in "
                      "all; the device's log no longer goes back to the start of the run, so "
                      "its lines may have been dropped from it)", result.stdout)

    def test_a_sweep_line_the_class_check_brings_fails_a_sweep_that_had_passed(self):
        # The device gives a class's line and a test of the sweep only at the
        # class check, after the sweep has passed.
        hidden = "  9999  9999 "
        self.space.adb(reader=f'drop_lines "{hidden}"', dump=self.late_dump(hidden))
        self.space.finished("C01ButtonTest", "S01NamesTest")
        self.space.gradle(
            f'echo "{BATCH_TIME}{hidden}I TestRunner: finished: opens({PKG}.F01FieldsTest)" '
            f'>> "{self.space.runner_log}"; exit 0',
            sweep=self.space.logs(*EMPTY_RUN)
            + f'echo "11-17 21:31:00.000{hidden}I TestRunner: started: opens({PKG}.MissedTest)" '
            f'>> "{self.space.runner_log}"; exit 0')
        result = self.space.run(BATCH_CLASSES="3")
        self.assertEqual(result.returncode, 1)
        self.assertIn("sweep: no test outside the list", result.stdout)
        self.assertIn("with the lines the device's log has just given, the sweep is not an "
                      "empty run", result.stdout)
        self.assertIn(f"started: opens({PKG}.MissedTest)",
                      result.stdout.split("The test runner logged:")[1])
        self.assertNotIn("no test of F01FieldsTest finished", result.stdout)

    def test_a_late_sweep_line_fails_the_sweep_with_one_class_a_batch(self):
        # The same device as above, one class a batch: F01FieldsTest's batch
        # has no line in the reader's log, so the device's log is read once
        # more after it, and the hidden lines come when the sweep is checked.
        hidden = "  9999  9999 "
        self.space.adb(reader=f'drop_lines "{hidden}"', dump=self.late_dump(hidden))
        self.space.finished("C01ButtonTest", "S01NamesTest")
        self.space.gradle(
            f'echo "{BATCH_TIME}{hidden}I TestRunner: finished: opens({PKG}.F01FieldsTest)" '
            f'>> "{self.space.runner_log}"; exit 0',
            sweep=self.space.logs(*EMPTY_RUN)
            + f'echo "11-17 21:31:00.000{hidden}I TestRunner: started: opens({PKG}.MissedTest)" '
            f'>> "{self.space.runner_log}"; exit 0')
        result = self.space.run()
        self.assertEqual(result.returncode, 1)
        self.assertNotIn("sweep: no test outside the list", result.stdout)
        self.assertIn("not an empty run", result.stdout)
        self.assertIn(f"started: opens({PKG}.MissedTest)",
                      result.stdout.split("The test runner logged:")[1])
        self.assertNotIn("no test of F01FieldsTest finished", result.stdout)

    def test_fails_when_the_sweeps_start_cannot_be_marked(self):
        self.space.finished(*self.names)
        stand_in = (self.space.bin / "adb").read_text().split("\n", 1)[1]
        self.space.tool("adb", 'case "$*" in "shell log"*_sweep_*) exit 1 ;; esac\n'
                        + stand_in)
        for batch_classes, batches in (("1", 3), ("3", 1)):
            with self.subTest(batch_classes=batch_classes):
                (self.space.android / "calls").unlink(missing_ok=True)
                result = self.space.run(BATCH_CLASSES=batch_classes)
                self.assertEqual(result.returncode, 1)
                self.assertIn("failed: could not mark the sweep's start", result.stdout)
                # The batches ran; the sweep did not.
                self.assertEqual(len(self.calls()), batches)
                self.assertEqual(self.batches(), self.calls())


if __name__ == "__main__":
    unittest.main()
