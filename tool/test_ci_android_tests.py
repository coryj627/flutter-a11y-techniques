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
        self.adb()
        self.tool("pgrep", "exit 0")
        self.tool("sudo", "exit 0")
        self.gradle("exit 0")

    def adb(self, reader="follow", dump=None):
        """A stand-in adb. The reader of the test runner's log runs
        `reader`, with $n its start count and $first the first line logcat
        gives from the -T time on; `follow` reads the device's log from
        there, and `stop_once_after TEXT` writes lines up to the first with
        TEXT in it and stops, the first time only. `logcat -d` runs `dump`,
        by default printing the device's log."""
        log, root = self.runner_log, self.root
        dump = dump or f'cat "{log}"'
        self.tool("adb", f"""\
            follow() {{ exec tail -s 0.1 -n "+$first" -f "{log}"; }}
            stop_once_after() {{
              [ -e "{root}/reader-stopped" ] && follow
              k=$first
              while :; do
                line=$(sed -n "${{k}}p" "{log}")
                if [ -z "$line" ]; then sleep 0.05; continue; fi
                echo "$line"
                k=$((k + 1))
                case $line in *"$1"*) touch "{root}/reader-stopped"; exit 0 ;; esac
              done
            }}
            case "$*" in
              "logcat -c"|"logcat -G"*|"logcat -d -b"*) exit 0 ;;
              "logcat -d"*TestRunner:I*) {dump} ;;
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
                echo "11-17 21:25:29.060  4037  4051 I TestRunner: finished: opens({PKG}.$name)" \\
                  >> "{self.runner_log}" ;;
              esac
            done
            """ + textwrap.dedent(body), self.android)

    def logs(self, *lines):
        """Shell that adds these lines to the test runner's log."""
        return "".join(
            f'echo "11-17 21:30:00.000  4037  4051 I TestRunner: {line}" >> "{self.runner_log}"; '
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
        log = self.space.reader_log()
        self.assertEqual(len(log), len(set(log)), "\n".join(log))
        for name in self.names:
            self.assertEqual(sum(f"({PKG}.{name})" in line for line in log), 1, log)

    def test_a_reader_that_stops_at_once_is_started_again(self):
        # The device's log gives nothing: the lines come from the restart.
        self.space.adb(reader='[ "$n" -eq 1 ] && exit 0; follow', dump="exit 0")
        self.space.finished(*self.names)
        result = self.space.run()
        self.assert_passed_once_each(result)
        self.assertIn("the reader of the test runner's log stopped (exit code 0); "
                      "restart 1, from the start of the device's log", result.stdout)
        self.assertIn("restarts of the test runner's log reader: 1,", result.stdout)

    def test_a_reader_started_again_at_once_still_fails_a_class_that_did_not_run(self):
        self.space.adb(reader='[ "$n" -eq 1 ] && exit 0; follow', dump="exit 0")
        self.space.finished("C01ButtonTest", "S01NamesTest")
        result = self.space.run()
        self.assertEqual(result.returncode, 1)
        self.assertIn("no test of F01FieldsTest finished", result.stdout)
        self.assertIn("restarts of the test runner's log reader: 1;", result.stdout)

    def mid_batch(self, *later):
        """A batch that logs C01ButtonTest's test, then the classes
        `later`, while the reader stops after the first."""
        self.space.adb(reader="stop_once_after C01ButtonTest", dump="exit 0")
        self.space.gradle(
            self.space.logs(f"finished: opens({PKG}.C01ButtonTest)") + "sleep 1; "
            + self.space.logs(*(f"finished: opens({PKG}.{name})" for name in later))
            + "exit 0")
        return self.space.run()

    def test_a_reader_that_stops_during_a_batch_goes_on_from_where_it_stopped(self):
        result = self.mid_batch("F01FieldsTest", "S01NamesTest")
        self.assert_passed_once_each(result)
        self.assertIn("restart 1, from 11-17 21:30:00.000, leaving out the lines it already has",
                      result.stdout)

    def test_a_reader_that_stops_during_a_batch_still_fails_a_class_that_did_not_run(self):
        result = self.mid_batch("S01NamesTest")
        self.assertEqual(result.returncode, 1)
        self.assertIn("restart 1, from", result.stdout)
        self.assertIn("no test of F01FieldsTest finished", result.stdout)

    def test_a_line_written_again_after_a_restart_in_the_sweep_is_left_out(self):
        # logcat repeats the sweep's start from the -T time; a second start
        # would fail the sweep.
        self.space.adb(reader='stop_once_after "run started"')
        self.space.finished(*self.names)
        self.space.gradle("exit 0", sweep=self.space.logs(EMPTY_RUN[0]) + "sleep 1; "
                          + self.space.logs(EMPTY_RUN[1]) + "exit 0")
        result = self.space.run()
        self.assert_passed_once_each(result)
        self.assertIn("restart 1, from 11-17 21:30:00.000", result.stdout)
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
        self.space.adb(reader="exec sleep 60", dump="exit 1")
        self.space.finished(*self.names)
        result = self.space.run()
        self.assertEqual(result.returncode, 1)
        self.assertIn("could not read the device's log", result.stdout)
        self.assertIn("the sweep never reached the test runner", result.stdout)
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


if __name__ == "__main__":
    unittest.main()
