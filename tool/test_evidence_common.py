"""Tests for the technique registrations the evidence tools load from
tool/techniques/. Run: python3 -m unittest discover -s tool -p 'test_*.py'"""
import os
import sys
import tempfile
import textwrap
import unittest
from unittest import mock

import evidence_common as common

VALID = '''
ID = "{id}"
TITLE = "{id} Thing"
ANDROID_TEST = "{id}ThingTest"
IOS_TEST = "{id}ThingUITests"
WEB_VO_SPEC = "{stem}_vo.spec.js"
TALKBACK_EXPECT = {{
    "{prefix}-good-a": (["Save", "Button"], []),
    "{prefix}-bad-b": (["Button"], ["Save"]),
}}
'''


class Loader(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.dir.cleanup)

    def write(self, name, source=None):
        stem = name[:-3]
        tid = stem[:3].upper()
        if source is None:
            source = VALID.format(id=tid, stem=stem, prefix=tid.lower())
        with open(os.path.join(self.dir.name, name), "w") as f:
            f.write(textwrap.dedent(source))

    def load(self):
        return common.load_techniques(self.dir.name)

    def refused(self, *patterns):
        with self.assertRaises(common.RegistrationError) as caught:
            self.load()
        for pattern in patterns:
            self.assertRegex(str(caught.exception), pattern)
        return str(caught.exception)

    def test_a_valid_registration_is_loaded(self):
        self.write("x01_thing.py")
        found = self.load()
        self.assertEqual(list(found), ["X01"])
        r = found["X01"]
        self.assertEqual((r.title, r.android_test, r.ios_test, r.web_vo_spec),
                         ("X01 Thing", "X01ThingTest", "X01ThingUITests", "x01_thing_vo.spec.js"))
        self.assertEqual(r.talkback_expect, {"x01-good-a": (["Save", "Button"], []),
                                             "x01-bad-b": (["Button"], ["Save"])})
        self.assertEqual((r.talkback_method, r.voiceover_ios_method, r.voiceover_web_method),
                         (None, None, None))

    def test_optional_methods_are_read(self):
        self.write("x01_thing.py", VALID.format(id="X01", stem="x01_thing", prefix="x01") + textwrap.dedent('''
            TALKBACK_METHOD = "pressed"
            VOICEOVER_IOS_METHOD = ("swiped", "Spoken")
            VOICEOVER_WEB_METHOD = "walked"
            '''))
        r = self.load()["X01"]
        self.assertEqual((r.talkback_method, r.voiceover_ios_method, r.voiceover_web_method),
                         ("pressed", ("swiped", "Spoken"), "walked"))

    def test_a_platform_without_a_test_is_none(self):
        self.write("x01_thing.py", VALID.format(id="X01", stem="x01_thing", prefix="x01")
                   .replace('IOS_TEST = "X01ThingUITests"', "IOS_TEST = None"))
        self.assertIsNone(self.load()["X01"].ios_test)

    def test_the_order_is_the_file_name_order_whatever_the_directory_gives(self):
        for name in ("s05_b.py", "c01_a.py", "f08_c.py"):
            self.write(name)
        names = os.listdir(self.dir.name)
        for listing in (sorted(names), sorted(names, reverse=True)):
            with mock.patch.object(common.os, "listdir", return_value=listing):
                self.assertEqual(list(self.load()), ["C01", "F08", "S05"])

    def test_two_files_with_the_same_id_are_refused(self):
        self.write("x01_thing.py")
        self.write("x01_other.py")
        message = self.refused(r"id X01 is already registered")
        self.assertIn("x01_other.py", message)
        self.assertIn("x01_thing.py", message)

    def test_an_id_that_does_not_match_the_file_name_is_refused(self):
        self.write("x01_thing.py", VALID.format(id="X02", stem="x01_thing", prefix="x02"))
        self.refused(r"x01_thing\.py: ID is 'X02', but the file name says 'X01'")

    def test_a_badly_named_file_is_refused(self):
        # Not variants of x01_thing.py only in case: macOS file systems would
        # take those for the same file.
        for name in ("thing.py", "X02_other.py", "x3_other.py", "x04.py", "x05-other.py",
                     "x06_other.txt", "x07_Other.py", "x08_other.py.bak"):
            with self.subTest(name=name):
                self.setUp()
                self.write("x01_thing.py")
                with open(os.path.join(self.dir.name, name), "w") as f:
                    f.write("")
                self.refused(r"not a registration")

    def test_bytecode_and_hidden_files_are_ignored(self):
        self.write("x01_thing.py")
        os.mkdir(os.path.join(self.dir.name, "__pycache__"))
        open(os.path.join(self.dir.name, ".DS_Store"), "w").close()
        self.assertEqual(list(self.load()), ["X01"])

    def test_a_file_that_does_not_load_is_refused(self):
        self.write("x01_thing.py", "ID = (\n")
        self.refused(r"x01_thing\.py: could not be loaded: SyntaxError")
        self.write("x01_thing.py", "raise ValueError('broken')\n")
        self.refused(r"could not be loaded: ValueError: broken")

    def test_a_missing_name_is_refused(self):
        source = VALID.format(id="X01", stem="x01_thing", prefix="x01")
        for name in ("ID", "TITLE", "ANDROID_TEST", "IOS_TEST", "WEB_VO_SPEC", "TALKBACK_EXPECT"):
            with self.subTest(name=name):
                lines = source.split("\n")
                start = next(i for i, l in enumerate(lines) if l.startswith(name + " ="))
                end = start + 4 if name == "TALKBACK_EXPECT" else start + 1
                self.write("x01_thing.py", "\n".join(lines[:start] + lines[end:]))
                self.refused(rf"missing {name}")

    def test_an_unknown_name_such_as_a_typo_is_refused(self):
        self.write("x01_thing.py", VALID.format(id="X01", stem="x01_thing", prefix="x01")
                   + 'VOICEOVER_IOS_METHODS = ("swiped", "Spoken")\n')
        self.refused(r"unknown name\(s\) VOICEOVER_IOS_METHODS")

    def test_values_of_the_wrong_shape_are_refused(self):
        base = VALID.format(id="X01", stem="x01_thing", prefix="x01")
        cases = {
            'TITLE = "Thing"': r'TITLE must be a string that starts with "X01 "',
            "ANDROID_TEST = 3": r"ANDROID_TEST must be a class name or None",
            'IOS_TEST = "X01 Thing"': r"IOS_TEST must be a class name or None",
            'WEB_VO_SPEC = "x01_thing.spec.js"': r"WEB_VO_SPEC must be a file name ending in _vo\.spec\.js",
            "TALKBACK_EXPECT = []": r"TALKBACK_EXPECT must be a dict",
            'TALKBACK_EXPECT = {"x02-good-a": (["Save"], [])}': r"identifier 'x02-good-a' does not start with \"x01-\"",
            'TALKBACK_EXPECT = {"x01-": (["Save"], [])}': r"identifier 'x01-' does not start",
            'TALKBACK_EXPECT = {"x01-good-a": ["Save"]}': r"TALKBACK_EXPECT\['x01-good-a'\] must be",
            'TALKBACK_EXPECT = {"x01-good-a": ("Save", [])}': r"TALKBACK_EXPECT\['x01-good-a'\] must be",
            'TALKBACK_EXPECT = {"x01-good-a": ([""], [])}': r"TALKBACK_EXPECT\['x01-good-a'\] must be",
            'TALKBACK_METHOD = ""': r"TALKBACK_METHOD must be a non-empty string",
            "VOICEOVER_WEB_METHOD = None": r"VOICEOVER_WEB_METHOD must be a non-empty string",
            'VOICEOVER_IOS_METHOD = "swiped"': r"VOICEOVER_IOS_METHOD must be \(method, column heading\)",
        }
        for line, pattern in cases.items():
            with self.subTest(line=line):
                self.write("x01_thing.py", base + line + "\n")
                self.refused(pattern)

    def test_a_file_changed_at_once_to_the_same_size_is_read_again(self):
        # Bytecode caching would return the first version here.
        self.write("x01_thing.py")
        first = self.load()["X01"]
        path = os.path.join(self.dir.name, "x01_thing.py")
        with open(path) as f:
            source = f.read()
        stat = os.stat(path)
        with open(path, "w") as f:
            f.write(source.replace("X01ThingTest", "X01OtherTest"))
        os.utime(path, ns=(stat.st_atime_ns, stat.st_mtime_ns))
        self.assertEqual(os.stat(path).st_size, stat.st_size)
        self.assertEqual(first.android_test, "X01ThingTest")
        self.assertEqual(self.load()["X01"].android_test, "X01OtherTest")
        self.assertFalse(os.path.exists(os.path.join(self.dir.name, "__pycache__")))

    def test_an_empty_directory_is_refused(self):
        self.refused(r"no technique registrations found")


class RepositoryRegistrations(unittest.TestCase):
    """The registrations in this repository agree with the files they name."""

    def test_every_technique_folder_has_a_registration_and_no_other_exists(self):
        folders = sorted(d for d in os.listdir(os.path.join(common.ROOT, "lib", "techniques"))
                         if os.path.isdir(os.path.join(common.ROOT, "lib", "techniques", d)))
        files = sorted(os.path.basename(r.path)[:-3] for r in common.REGISTRATIONS.values())
        self.assertEqual(files, folders)

    def test_every_named_test_exists(self):
        android = os.path.join(common.ROOT, "android", "app", "src", "androidTest", "kotlin",
                               "dev", "fluttera11y", "flutter_a11y_techniques")
        for tid, r in common.REGISTRATIONS.items():
            with self.subTest(technique=tid):
                if r.android_test:
                    self.assertTrue(os.path.isfile(os.path.join(android, r.android_test + ".kt")))
                if r.ios_test:
                    self.assertTrue(os.path.isfile(os.path.join(
                        common.ROOT, "ios", "RunnerUITests", r.ios_test + ".swift")))
                if r.web_vo_spec:
                    self.assertTrue(os.path.isfile(os.path.join(
                        common.ROOT, "web_tests", "vo", r.web_vo_spec)))

    def test_the_tools_read_the_registrations(self):
        import talkback
        import voiceover_ios
        import voiceover_web
        self.assertIs(common.TECHNIQUES, voiceover_ios.TECHNIQUES)
        f08 = common.REGISTRATIONS["F08"]
        self.assertEqual(common.TECHNIQUES["F08"],
                         (f08.title, f08.android_test, f08.ios_test, f08.web_vo_spec))
        self.assertEqual(talkback.EXPECT["f08-good-group-group"], (["Delivery speed"], ["Radio button"]))
        self.assertEqual(len(talkback.EXPECT),
                         sum(len(r.talkback_expect) for r in common.REGISTRATIONS.values()))
        self.assertIn("I12", talkback.METHODS)
        self.assertEqual(voiceover_ios.METHODS["F08"], f08.voiceover_ios_method)
        self.assertEqual(voiceover_web.METHODS["F08"], f08.voiceover_web_method)


class VoiceOverWebGuard(unittest.TestCase):
    def test_the_web_tool_sets_the_variable_the_voiceover_specs_require(self):
        import voiceover_web
        # Nothing here may start a process: a real run takes over the Mac.
        # Popen is closed off as well, in case the tool's way of running the
        # command changes again.
        with mock.patch.object(sys, "argv", ["voiceover_web.py", "F08"]), \
                mock.patch.object(voiceover_web.device_lock, "hold_for_process") as hold, \
                mock.patch.object(voiceover_web.device_lock, "run_to_the_end",
                                  return_value=mock.Mock(returncode=1, stdout="", stderr="")) as run, \
                mock.patch.object(voiceover_web.subprocess, "run",
                                  side_effect=AssertionError("started a process")), \
                mock.patch.object(voiceover_web.subprocess, "Popen",
                                  side_effect=AssertionError("started a process")), \
                mock.patch("builtins.print"), self.assertRaises(SystemExit) as stopped:
            voiceover_web.main()
        self.assertEqual(str(stopped.exception), "No VoiceOver transcript captured.")
        hold.assert_called_once_with("voiceover_web F08")
        self.assertEqual(run.call_args.args[0][:3], ["npx", "playwright", "test"])
        self.assertEqual(run.call_args.kwargs["env"][voiceover_web.VOICEOVER_RUN], "1")
        self.assertEqual(run.call_args.kwargs["cwd"], os.path.join(voiceover_web.WEB_TESTS, "vo"))
        # The name is the one the specs check.
        with open(os.path.join(voiceover_web.WEB_TESTS, "vo", "voiceover_run_guard.js")) as f:
            self.assertIn(f"process.env.{voiceover_web.VOICEOVER_RUN}", f.read())


if __name__ == "__main__":
    unittest.main()
