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
        self.runner_log = self.root / "runner.txt"
        self.runner_log.write_text("")
        self.tool("adb", f"""\
            case "$*" in
              *TestRunner:I*) exec tail -n +1 -f "{self.runner_log}" ;;
              "logcat -c"|"logcat -d"*) exit 0 ;;
              logcat*) exec sleep 60 ;;
            esac
            exit 0
            """)
        self.tool("pgrep", "exit 0")
        self.tool("sudo", "exit 0")
        self.gradle("exit 0")

    def tool(self, name, body, folder=None):
        path = (folder or self.bin) / name
        path.write_text("#!/bin/bash\n" + textwrap.dedent(body))
        path.chmod(path.stat().st_mode | stat.S_IEXEC)

    def gradle(self, body, sweep=None):
        """A stand-in Gradle. In the sweep it reports a run with no tests,
        or runs `sweep` in its place."""
        sweep = sweep or self.logs(*EMPTY_RUN) + "exit 0"
        self.tool("gradlew", f"""\
            echo "$@" >> "$PWD/calls"
            case "$*" in *notClass=*) {sweep} ;; esac
            """ + textwrap.dedent(body), self.android)

    def logs(self, *lines):
        """Shell that adds these lines to the test runner's log."""
        return "".join(
            f'echo "11-17 21:30:00.000  4037  4051 I TestRunner: {line}" >> "{self.runner_log}"; '
            for line in lines)

    def finished(self, *names):
        self.runner_log.write_text("".join(
            f"11-17 21:25:29.060  4037  4051 I TestRunner: finished: opens({PKG}.{name})\n"
            for name in names))

    def run(self, *args, **env):
        return subprocess.run(
            ["bash", str(SCRIPT), *args],
            cwd=self.android, capture_output=True, text=True, timeout=120,
            env={**os.environ,
                 "PATH": f"{self.bin}{os.pathsep}{os.environ['PATH']}",
                 "TEST_DIR": str(self.tests), "DIAG_DIR": str(self.diag),
                 "POLL_SECONDS": "2", "SETTLE_SECONDS": "1", **env})


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


if __name__ == "__main__":
    unittest.main()
