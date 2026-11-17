"""Tests for tool/evidence.py: what runs, in what order, and what is reported.

Run: python3 -m unittest discover -s tool -p 'test_*.py'
"""
import contextlib
import io
import os
import tempfile
import unittest
from unittest import mock

import device_lock
import evidence
from with_devices import BUSY

ALL = list(evidence.LAYERS)


def no_problems(_layers):
    return {}


class Runner:
    """Stands in for running a step: records it and returns a chosen status."""

    def __init__(self, failing=()):
        self.failing = set(failing)
        self.steps = []

    def __call__(self, step, log_path):
        self.steps.append(step)
        return 1 if step.name in self.failing else 0

    @property
    def names(self):
        return [step.name for step in self.steps]


def run(technique="F08", layers=ALL, failing=(), **kwargs):
    runner, out, slept = Runner(failing), io.StringIO(), []
    kwargs.setdefault("check", no_problems)
    kwargs.setdefault("stop_android", lambda: True)
    kwargs.setdefault("stop_ios", lambda: True)
    results = evidence.run_technique(technique, layers, runner=runner, out=out,
                                     sleep=slept.append, **kwargs)
    return results, runner, out.getvalue(), slept


class RunTechniqueTest(unittest.TestCase):
    def test_builds_first_then_every_layer_in_order(self):
        results, runner, _, _ = run()
        self.assertEqual(runner.names, ["build android", "build ios", "build web", *ALL])
        self.assertEqual({layer: r for layer, (r, _) in results.items()},
                         dict.fromkeys(ALL, evidence.PASS))

    def test_each_step_is_the_technique_s_own(self):
        _, runner, _, _ = run("F08")
        commands = {step.name: " ".join(step.command) for step in runner.steps}
        self.assertIn("class=dev.fluttera11y.flutter_a11y_techniques.F08RadioGroupTest ",
                      commands["android"] + " ")
        self.assertIn("timeout_msec=180000", commands["android"])
        # No shared Gradle daemon: the run must own what drives the emulator.
        self.assertTrue(commands["android"].startswith(
            "./gradlew --no-daemon -Pkotlin.compiler.execution.strategy=in-process "))
        self.assertIn("-only-testing:RunnerUITests/F08RadioGroupUITests ", commands["ios"])
        self.assertIn("-skip-testing:RunnerUITests/F08RadioGroupUITests/testVoiceOverSpeech",
                      commands["ios"])
        self.assertTrue(commands["talkback"].endswith("talkback.py F08"))
        self.assertTrue(commands["voiceover-ios"].endswith("voiceover_ios.py F08"))
        self.assertTrue(commands["voiceover-web"].endswith("voiceover_web.py F08"))
        # The web step names its spec: Playwright is never run bare.
        self.assertEqual(runner.steps[runner.names.index("web")].command,
                         ["npx", "playwright", "test", "f08_radio_group.spec.js"])

    def test_android_build_starts_no_shared_gradle_daemon(self):
        _, runner, _, _ = run(layers=["android"])
        build = runner.steps[runner.names.index("build android")].command
        self.assertEqual(build[-5:], [
            "build", "apk", "--debug", "--no-android-gradle-daemon",
            "--android-project-arg=kotlin.compiler.execution.strategy=in-process"])

    def test_only_the_builds_the_chosen_layers_need(self):
        _, runner, _, _ = run(layers=["ios", "voiceover-ios"])
        self.assertEqual(runner.names, ["build ios", "ios", "voiceover-ios"])
        _, runner, _, _ = run(layers=["web"], no_build=True)
        self.assertEqual(runner.names, ["web"])

    def test_warning_is_printed_before_the_web_voiceover_step_and_time_is_given(self):
        _, runner, text, slept = run(countdown=10)
        self.assertEqual(slept, [10])
        warning = text.index("WARNING: the web VoiceOver recording starts in 10 seconds")
        self.assertIn("VoiceOver will speak", text)
        self.assertLess(text.index("[F08] web: ok"), warning)
        self.assertLess(warning, text.index("[F08] voiceover-web: running"))

    def test_no_warning_when_the_web_voiceover_layer_is_not_run(self):
        _, _, text, slept = run(layers=[layer for layer in ALL if layer != "voiceover-web"])
        self.assertNotIn("WARNING", text)
        self.assertEqual(slept, [])

    def test_failed_layer_is_reported_and_the_rest_still_run(self):
        results, runner, text, _ = run(failing=["talkback"])
        self.assertEqual(runner.names[-len(ALL):], ALL)
        self.assertEqual(results["talkback"][0], evidence.FAIL)
        self.assertIn("build/evidence/F08/talkback.log", results["talkback"][1])
        self.assertIn("[F08] talkback: FAILED with status 1", text)
        self.assertEqual([r for layer, (r, _) in results.items() if layer != "talkback"],
                         [evidence.PASS] * 5)

    def test_failed_build_fails_its_layers_without_running_them(self):
        results, runner, _, _ = run(failing=["build ios"])
        self.assertNotIn("ios", runner.names)
        self.assertNotIn("voiceover-ios", runner.names)
        for layer in ("ios", "voiceover-ios"):
            self.assertEqual(results[layer][0], evidence.FAIL)
            self.assertIn("build ios failed", results[layer][1])
        self.assertEqual(results["android"][0], evidence.PASS)
        self.assertEqual(results["voiceover-web"][0], evidence.PASS)

    def test_preflight_problem_fails_the_layer_and_skips_its_build_and_warning(self):
        results, runner, text, slept = run(
            layers=["voiceover-web"],
            check=lambda layers: {"voiceover-web": "no access to VoiceOver"})
        self.assertEqual(runner.names, [])
        self.assertEqual(results["voiceover-web"], (evidence.FAIL, "no access to VoiceOver"))
        self.assertNotIn("WARNING", text)
        self.assertEqual(slept, [])

    def test_layer_with_no_test_is_skipped(self):
        entry = ("F08 Radio group", "F08RadioGroupTest", None, None)
        with mock.patch.dict(evidence.TECHNIQUES, {"F08": entry}):
            results, runner, _, _ = run("F08")
        self.assertNotIn("ios", runner.names)
        self.assertNotIn("voiceover-ios", runner.names)
        self.assertEqual(results["ios"][0], evidence.SKIPPED)
        self.assertEqual(results["voiceover-ios"][0], evidence.SKIPPED)
        self.assertEqual(results["voiceover-web"][0], evidence.SKIPPED)
        self.assertEqual(results["web"][0], evidence.PASS)
        self.assertEqual(results["android"][0], evidence.PASS)


class StopAndroidTest(unittest.TestCase):
    def test_android_step_is_followed_by_stopping_the_tests_on_the_device(self):
        order = []
        runner = Runner()

        def recording(step, log_path):
            order.append(step.name)
            return runner(step, log_path)

        evidence.run_technique("F08", ["android", "ios"], runner=recording, out=io.StringIO(),
                               check=no_problems, no_build=True,
                               stop_android=lambda: order.append("stop android") or True,
                               stop_ios=lambda: order.append("stop ios") or True)
        self.assertEqual(order, ["android", "stop android", "ios", "stop ios"])

    def test_tests_are_stopped_on_the_device_when_the_run_is_stopped_mid_step(self):
        stopped = []

        def interrupted(step, log_path):
            raise SystemExit(143)

        with self.assertRaises(SystemExit):
            evidence.run_technique("F08", ["android"], runner=interrupted, out=io.StringIO(),
                                   check=no_problems, no_build=True,
                                   stop_android=lambda: stopped.append(1) or True,
                                   stop_ios=lambda: True)
        self.assertEqual(stopped, [1])

    def test_a_device_that_does_not_confirm_is_reported(self):
        out = io.StringIO()
        evidence.run_technique("F08", ["android"], runner=Runner(), out=out, check=no_problems,
                               no_build=True, stop_android=lambda: False, stop_ios=lambda: True)
        self.assertIn("could not be shown to have stopped on the emulator", out.getvalue())
        out = io.StringIO()
        evidence.run_technique("F08", ["ios"], runner=Runner(), out=out, check=no_problems,
                               no_build=True, stop_android=lambda: True, stop_ios=lambda: False)
        self.assertIn("could not be shown to have stopped on the simulator", out.getvalue())

    def test_simulator_apps_are_ended_until_simctl_says_nothing_is_left(self):
        import evidence_common as common
        calls = []
        answers = iter([(0, ""), (3, "found nothing to terminate"),
                        (3, "found nothing to terminate"), (3, "found nothing to terminate")])

        def fake(command, **kwargs):
            calls.append(command[3:])
            code, said = next(answers)
            return mock.Mock(returncode=code, stderr=said, stdout="")

        self.assertTrue(common.stop_ios_tests(run=fake, sleep=lambda _: None))
        runner = common.IOS_BUNDLE + ".RunnerUITests.xctrunner"
        self.assertEqual(calls, [["iPhone 17", common.IOS_BUNDLE], ["iPhone 17", runner]] * 2)
        # An error that says something else proves nothing.
        other = lambda command, **kwargs: mock.Mock(returncode=1, stderr="boom", stdout="")
        self.assertFalse(common.stop_ios_tests(run=other, wait=0, sleep=lambda _: None))
        shut = lambda command, **kwargs: mock.Mock(
            returncode=149, stderr="Unable to lookup in current state: Shutdown", stdout="")
        self.assertTrue(common.stop_ios_tests(run=shut, wait=0, sleep=lambda _: None))

    def test_force_stops_both_packages_and_waits_until_the_device_says_neither_runs(self):
        import evidence_common as common
        app, tests = common.ANDROID_PACKAGE, common.ANDROID_PACKAGE + ".test"
        calls, running = [], {app: 1, tests: 0}  # the app survives the first force-stop

        def fake(command, **kwargs):
            calls.append(command[1:])
            if command[2] == "am":
                return mock.Mock(stdout="", returncode=0)
            package = command[2].split()[1]
            if running[package] > 0:
                running[package] -= 1
                return mock.Mock(stdout="4242\n", returncode=0)
            return mock.Mock(stdout=common.NOT_RUNNING + "\n", returncode=0)

        self.assertTrue(common.stop_android_tests(run=fake, sleep=lambda _: None))
        self.assertEqual(calls[:4], [
            ["shell", "am", "force-stop", app],
            ["shell", f"pidof {app} || echo {common.NOT_RUNNING}"],
            ["shell", "am", "force-stop", tests],
            ["shell", f"pidof {tests} || echo {common.NOT_RUNNING}"]])
        self.assertEqual(len(calls), 8)  # asked again, both packages

    def test_no_answer_from_the_device_is_not_taken_for_stopped(self):
        import evidence_common as common
        import subprocess
        quick = dict(wait=0, sleep=lambda _: None)

        def unreachable(command, **kwargs):
            raise subprocess.TimeoutExpired(command, 30)

        self.assertFalse(common.stop_android_tests(run=unreachable, **quick))
        still = lambda command, **kwargs: mock.Mock(stdout="4242\n", returncode=0)
        self.assertFalse(common.stop_android_tests(run=still, **quick))
        # An offline device: every command fails and prints nothing.
        offline = lambda command, **kwargs: mock.Mock(
            stdout="", stderr="error: device offline", returncode=1)
        self.assertFalse(common.stop_android_tests(run=offline, **quick))
        # Nothing printed, even with status 0, is not the device's word.
        silent = lambda command, **kwargs: mock.Mock(stdout="", returncode=0)
        self.assertFalse(common.stop_android_tests(run=silent, **quick))

    def test_a_signal_during_the_device_clean_up_is_held_until_it_is_done(self):
        import evidence_common as common
        import signal
        calls, got = [], []

        def fake(command, **kwargs):
            calls.append(command[1:])
            if len(calls) == 1:
                os.kill(os.getpid(), signal.SIGTERM)  # arrives mid clean-up
                os.kill(os.getpid(), signal.SIGINT)   # and another
            return mock.Mock(stdout=common.NOT_RUNNING, stderr="found nothing to terminate",
                             returncode=0)

        previous = signal.signal(signal.SIGTERM, lambda signum, _f: got.append(signum))
        self.addCleanup(signal.signal, signal.SIGTERM, previous)
        self.assertTrue(common.stop_android_tests(run=fake, sleep=lambda _: None))
        self.assertEqual(len(calls), 4, "the clean-up was cut short")
        self.assertEqual(got, [signal.SIGTERM], "the held signal was not passed on afterwards")

        calls.clear()
        got.clear()
        ended = lambda command, **kwargs: (
            calls.append(1), len(calls) == 1 and os.kill(os.getpid(), signal.SIGTERM),
            mock.Mock(returncode=3, stderr="found nothing to terminate", stdout=""))[2]
        self.assertTrue(common.stop_ios_tests(run=ended, sleep=lambda _: None))
        self.assertEqual((len(calls), got), (2, [signal.SIGTERM]))


class TalkBackWalkCommandTest(unittest.TestCase):
    def test_the_walk_runs_gradle_unshared_through_the_managed_runner(self):
        import talkback
        result = mock.Mock(returncode=0, stdout="", stderr="")
        with mock.patch.object(talkback, "TEST", "pkg.F08RadioGroupTest#talkBackWalk"), \
                mock.patch.object(talkback.time, "sleep"), \
                mock.patch.object(talkback, "adb", return_value="log") as adb, \
                mock.patch.object(talkback, "stop_android_tests", return_value=True) as stop, \
                mock.patch.object(talkback.subprocess, "run",
                                  side_effect=AssertionError("unmanaged process")), \
                mock.patch.object(talkback.device_lock, "run_to_the_end",
                                  return_value=result) as run:
            self.assertEqual(talkback.walk(), (result, "log"))
        command = run.call_args.args[0]
        self.assertEqual(command, [
            "./gradlew", "--no-daemon", "-Pkotlin.compiler.execution.strategy=in-process",
            "app:connectedDebugAndroidTest",
            "-Pandroid.testInstrumentationRunnerArguments.class=pkg.F08RadioGroupTest#talkBackWalk"])
        self.assertEqual(run.call_args.kwargs["timeout"], talkback.WALK_TIMEOUT)
        self.assertEqual(adb.call_args_list[0].args, ("logcat", "-c"))
        stop.assert_called_once_with()

    def test_a_walk_that_times_out_ends_the_tool_with_a_message(self):
        import subprocess
        import talkback
        with mock.patch.object(talkback.time, "sleep"), \
                mock.patch.object(talkback, "adb", return_value=""), \
                mock.patch.object(talkback, "stop_android_tests", return_value=True) as stop, \
                mock.patch.object(talkback.device_lock, "run_to_the_end",
                                  side_effect=subprocess.TimeoutExpired(["gradlew"], 1)), \
                self.assertRaises(SystemExit) as stopped:
            talkback.walk()
        self.assertIn("did not finish", str(stopped.exception))
        # The test inside the emulator is stopped all the same.
        stop.assert_called_once_with()


class PreflightTest(unittest.TestCase):
    def test_missing_node_modules_fails_both_web_layers(self):
        with tempfile.TemporaryDirectory() as root, mock.patch.object(evidence, "ROOT", root):
            problems = evidence.preflight(ALL)
        self.assertEqual(set(problems), {"web", "voiceover-web"})
        self.assertIn("npm ci", problems["web"])

    def test_unreadable_voiceover_folder_fails_only_the_web_voiceover_layer(self):
        with tempfile.TemporaryDirectory() as root, mock.patch.object(evidence, "ROOT", root), \
                mock.patch.object(evidence, "VOICEOVER_FOLDER", os.path.join(root, "missing")):
            os.makedirs(os.path.join(root, "web_tests", "node_modules"))
            problems = evidence.preflight(ALL)
            self.assertEqual(set(problems), {"voiceover-web"})
            self.assertIn("VoiceOver's settings folder", problems["voiceover-web"])
            self.assertEqual(evidence.preflight(["android", "ios", "web"]), {})


class SummaryTest(unittest.TestCase):
    def test_one_line_per_layer_and_an_overall_result(self):
        results, _, _, _ = run(failing=["ios"])
        lines, ok = evidence.summarise({"F08": results}, ALL)
        self.assertFalse(ok)
        text = "\n".join(lines)
        for layer in ALL:
            self.assertRegex(text, rf"(?m)^  {layer}\s+(PASS|FAIL)\b")
        self.assertRegex(text, r"(?m)^  ios\s+FAIL\s+exit status 1; see build/evidence/F08/ios.log$")
        self.assertEqual(lines[-1], "Result: FAIL")

    def test_all_passing_is_a_pass_and_skips_do_not_fail_it(self):
        results, _, _, _ = run()
        results["ios"] = (evidence.SKIPPED, "the technique has no test on this layer")
        lines, ok = evidence.summarise({"F08": results}, ALL)
        self.assertTrue(ok)
        self.assertEqual(lines[-1], "Result: PASS")

    def test_a_run_that_checked_nothing_is_not_a_pass(self):
        results = dict.fromkeys(ALL, (evidence.SKIPPED, "none"))
        self.assertFalse(evidence.summarise({"F08": results}, ALL)[1])


class MainTest(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.dir.cleanup)
        patch = mock.patch.dict(os.environ, {
            device_lock.ENV_FILE: os.path.join(self.dir.name, "device.lock")})
        patch.start()
        self.addCleanup(patch.stop)
        os.environ.pop(device_lock.ENV_HELD, None)
        self.calls = []

    def fake_run(self, result=evidence.PASS, detail="1 s"):
        def run(technique, layers, no_build=False):
            # The lock is held for the whole run.
            self.calls.append((technique, list(layers), no_build,
                               device_lock.read_holder()["label"]))
            return dict.fromkeys(layers, (result, detail))
        return run

    def main(self, *argv, **kwargs):
        out = io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(out):
            try:
                status = evidence.main(list(argv), run=self.fake_run(**kwargs))
            except SystemExit as exit_:
                status = exit_.code
        return status, out.getvalue()

    def test_one_technique_runs_under_the_lock_and_passes(self):
        status, text = self.main("f08")
        self.assertEqual(status, 0)
        self.assertEqual(self.calls, [("F08", ALL, False, "evidence F08")])
        self.assertIn("Result: PASS", text)
        self.assertIsNone(device_lock.read_holder())  # released

    def test_a_failed_layer_gives_exit_status_1(self):
        status, text = self.main("F08", result=evidence.FAIL, detail="exit status 1")
        self.assertEqual(status, 1)
        self.assertIn("Result: FAIL", text)

    def test_only_and_skip_choose_layers(self):
        self.main("F08", "--only", "web,android")
        self.main("F08", "--skip", "voiceover-web")
        self.assertEqual(self.calls[0][1], ["android", "web"])
        self.assertEqual(self.calls[1][1], ALL[:-1])

    def test_bad_arguments_are_usage_errors(self):
        for argv in ([], ["F08", "--all"], ["Z99"], ["F08", "--only", "tv"],
                     ["F08", "--only", "web", "--skip", "ios"], ["F08", "--skip", ",".join(ALL)]):
            status, _ = self.main(*argv)
            self.assertEqual(status, 2, argv)
        self.assertEqual(self.calls, [])

    def test_all_runs_every_technique_and_builds_once(self):
        status, text = self.main("--all", "--only", "web")
        self.assertEqual(status, 0)
        self.assertEqual([call[0] for call in self.calls], sorted(evidence.TECHNIQUES))
        self.assertEqual([call[2] for call in self.calls], [False] + [True] * (len(self.calls) - 1))
        self.assertEqual(self.calls[0][3], "evidence all techniques")
        for technique in evidence.TECHNIQUES:
            self.assertIn(f"\n{technique}:\n", text)

    def test_all_stops_after_a_failed_build(self):
        status, _ = self.main("--all", result=evidence.FAIL,
                              detail="build web failed; see build/evidence/C01/build-web.log")
        self.assertEqual(status, 1)
        self.assertEqual(len(self.calls), 1)

    def test_busy_devices_with_no_wait_exit_75_and_run_nothing(self):
        other = device_lock._try(device_lock.lock_file())
        self.addCleanup(os.close, other)
        os.pwrite(other, b'{"label": "evidence S05", "pid": 1, "cwd": "/w", "since": "now"}', 0)
        status, text = self.main("F08", "--no-wait")
        self.assertEqual(status, BUSY)
        self.assertIn('in use by "evidence S05"', text)
        self.assertEqual(self.calls, [])


if __name__ == "__main__":
    unittest.main()
