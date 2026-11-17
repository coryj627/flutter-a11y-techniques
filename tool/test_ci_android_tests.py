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
              *TestRunner:I*) cat "{self.runner_log}"; exec sleep 60 ;;
              "logcat -c") exit 0 ;;
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

    def gradle(self, body):
        self.tool("gradlew", body, self.android)

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
        self.space.gradle('touch "$PWD/ran"; exit 0')
        result = self.space.run()
        self.assertEqual(result.returncode, 1)
        self.assertFalse((self.space.android / "ran").exists())


@unittest.skipUnless(sys.platform.startswith("linux"), "the script reads /proc")
class RunTest(unittest.TestCase):
    def setUp(self):
        self.space = Workspace(self)
        self.names = ["C01ButtonTest", "F01FieldsTest", "S01NamesTest"]
        for name in self.names:
            write_class(self.space.tests, name)
        self.space.gradle('echo "$@" >> "$PWD/calls"; exit 0')

    def calls(self):
        return (self.space.android / "calls").read_text().splitlines()

    def test_passes_when_every_class_ran(self):
        self.space.finished(*self.names)
        result = self.space.run("-Pextra=1", BATCH_CLASSES="2")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        calls = self.calls()
        self.assertEqual(len(calls), 2)
        self.assertIn(f"class={PKG}.C01ButtonTest,{PKG}.F01FieldsTest -Pextra=1", calls[0])
        self.assertIn(f"class={PKG}.S01NamesTest -Pextra=1", calls[1])

    def test_fails_when_a_class_never_ran(self):
        self.space.finished("C01ButtonTest", "S01NamesTest")
        result = self.space.run()
        self.assertEqual(result.returncode, 1)
        self.assertIn("no test of F01FieldsTest finished", result.stdout)

    def test_fails_when_a_batch_fails_and_still_runs_the_rest(self):
        self.space.finished(*self.names)
        self.space.gradle(
            'echo "$@" >> "$PWD/calls"; case "$*" in *C01ButtonTest*) exit 3 ;; esac; exit 0')
        result = self.space.run(BATCH_CLASSES="1")
        self.assertEqual(result.returncode, 1)
        self.assertIn("batch 1 failed: Gradle exit code 3", result.stdout)
        self.assertEqual(len(self.calls()), 3)

    def test_a_batch_that_ended_during_the_wait_keeps_its_own_result(self):
        # Gradle is over before the first check, and the time limit has
        # passed by then: the batch passed and must not be stopped.
        self.space.finished(*self.names)
        result = self.space.run(LIMIT_SECONDS="0")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotIn("STOPPING THE TESTS", result.stdout)

    def test_stops_a_run_that_is_still_going_past_the_limit(self):
        self.space.finished(*self.names)
        self.space.gradle('[ "$1" = --stop ] && exit 0; exec sleep 60')
        result = self.space.run(LIMIT_SECONDS="0")
        self.assertEqual(result.returncode, 1)
        self.assertIn("STOPPING THE TESTS", result.stdout)


if __name__ == "__main__":
    unittest.main()
