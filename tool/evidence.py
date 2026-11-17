"""Runs every device and screen reader check for one technique, under the device lock.

Usage: python3 tool/evidence.py <ID> [--only LAYERS] [--skip LAYERS] [--no-build] [--no-wait]
       python3 tool/evidence.py --all [...]

Layers, in the order they run:

  android        the technique's Android tree tests (UI Automator, emulator)
  talkback       the TalkBack transcript (tool/talkback.py)
  ios            the technique's iOS tree tests (XCUITest, simulator)
  voiceover-ios  the VoiceOver transcript on iOS (tool/voiceover_ios.py)
  web            the technique's web tree spec (Playwright, headless)
  voiceover-web  the VoiceOver transcript on web (tool/voiceover_web.py),
                 which takes over this Mac's screen and speech

The whole run holds the device lock (tool/device_lock.py), so two runs, from
any worktree, never use the emulator, the simulator, or VoiceOver at once. A
second run waits and says who it is waiting for; --no-wait makes it exit with
status 75 instead. The debug builds each layer needs are made first unless
--no-build is given. A summary with one line per layer is printed at the end;
the exit status is 0 only if every layer that ran passed. Each step's full
output is kept in build/evidence/<ID>/.

One technique takes about 25 minutes. --all runs every technique in turn; that
is the scheduled and before-release run (D23), not something to do per merge.
"""
import argparse
import os
import shutil
import subprocess
import sys
import time

import device_lock
from evidence_common import REGISTRATIONS, ROOT, TECHNIQUES
from with_devices import BUSY, run_group

LAYERS = ("android", "talkback", "ios", "voiceover-ios", "web", "voiceover-web")
PACKAGE = "dev.fluttera11y.flutter_a11y_techniques"
SIMULATOR = "iPhone 17"
# The same per-test limit as CI: a hung test fails with a stack trace.
ANDROID_TEST_TIMEOUT = "180000"
VOICEOVER_FOLDER = os.path.join(os.path.expanduser("~"), "Library", "Group Containers",
                                "group.com.apple.VoiceOver")
VOICEOVER_WARNING = """
==========================================================================
  WARNING: the web VoiceOver recording starts in {seconds} seconds.
  It turns on VoiceOver on this Mac and drives a browser on screen. For
  several minutes VoiceOver will speak and the keyboard focus will move.
  Do not type or click until it finishes. Press Ctrl-C now to stop.
==========================================================================
"""

PASS, FAIL, SKIPPED = "PASS", "FAIL", "SKIPPED"


class Step:
    """One command of a run: a build, or a layer's check."""

    def __init__(self, name, command, cwd, layers, build=False):
        self.name = name
        self.command = command
        self.cwd = cwd
        self.layers = layers  # the layers this step decides or (a build) feeds
        self.build = build


def flutter():
    """The Flutter command: through fvm when it is installed."""
    return ["fvm", "flutter"] if shutil.which("fvm") else ["flutter"]


def tree_spec(technique):
    """The web tree spec's file name: the technique's folder name, as its
    registration file in tool/techniques/ is named."""
    stem = os.path.splitext(os.path.basename(REGISTRATIONS[technique].path))[0]
    return stem + ".spec.js"


def builds(layers, no_build=False):
    """The build steps the chosen layers need."""
    if no_build:
        return []
    steps = []
    for name, target, fed in (
            ("build android", ["apk", "--debug"], ("android", "talkback")),
            ("build ios", ["ios", "--simulator", "--debug"], ("ios", "voiceover-ios")),
            ("build web", ["web"], ("web", "voiceover-web"))):
        needed = tuple(layer for layer in fed if layer in layers)
        if needed:
            steps.append(Step(name, flutter() + ["build", *target], ROOT, needed, build=True))
    return steps


def checks(technique, layers):
    """The check steps for one technique, in running order.

    A layer the technique has no test for is left out; summarise() reports it
    as skipped.
    """
    _, android_test, ios_test, vo_spec = TECHNIQUES[technique]
    python = sys.executable or "python3"
    tool = os.path.join(ROOT, "tool")
    available = {
        "android": android_test and Step(
            # --no-daemon: a Gradle daemon left by an earlier build would do
            # the device work outside this run, where stopping the run
            # cannot reach it.
            "android", ["./gradlew", "--no-daemon", "app:connectedDebugAndroidTest",
                        f"-Pandroid.testInstrumentationRunnerArguments.class={PACKAGE}.{android_test}",
                        "-Pandroid.testInstrumentationRunnerArguments.timeout_msec="
                        + ANDROID_TEST_TIMEOUT],
            os.path.join(ROOT, "android"), ("android",)),
        "talkback": android_test and Step(
            "talkback", [python, os.path.join(tool, "talkback.py"), technique], ROOT,
            ("talkback",)),
        # The speech test is the voiceover-ios layer; it is not run twice.
        "ios": ios_test and Step(
            "ios", ["xcodebuild", "test", "-workspace", "Runner.xcworkspace", "-scheme", "Runner",
                    "-configuration", "Debug",
                    "-destination", f"platform=iOS Simulator,name={SIMULATOR}",
                    f"-only-testing:RunnerUITests/{ios_test}",
                    f"-skip-testing:RunnerUITests/{ios_test}/testVoiceOverSpeech",
                    "-derivedDataPath", os.path.join(ROOT, "build", "ios_uitest")],
            os.path.join(ROOT, "ios"), ("ios",)),
        "voiceover-ios": ios_test and Step(
            "voiceover-ios", [python, os.path.join(tool, "voiceover_ios.py"), technique], ROOT,
            ("voiceover-ios",)),
        # Every technique has a tree spec (web_tests/check_spec_selection.js).
        "web": Step(
            "web", ["npx", "playwright", "test", tree_spec(technique)],
            os.path.join(ROOT, "web_tests"), ("web",)),
        "voiceover-web": vo_spec and Step(
            "voiceover-web", [python, os.path.join(tool, "voiceover_web.py"), technique], ROOT,
            ("voiceover-web",)),
    }
    return [available[layer] for layer in LAYERS if layer in layers and available[layer]]


def preflight(layers):
    """Problems that would fail a layer for a reason that is not the technique's.

    Returns {layer: reason}. Checked before anything is built.
    """
    problems = {}
    web = [layer for layer in ("web", "voiceover-web") if layer in layers]
    if web and not os.path.isdir(os.path.join(ROOT, "web_tests", "node_modules")):
        for layer in web:
            problems[layer] = "web_tests/node_modules is missing; run `npm ci` in web_tests/"
    if "voiceover-web" in layers and "voiceover-web" not in problems:
        # A plain listing does not start VoiceOver. If macOS refuses it,
        # Guidepup cannot start VoiceOver either.
        try:
            os.listdir(VOICEOVER_FOLDER)
        except OSError as error:
            problems["voiceover-web"] = (
                f"this process may not read VoiceOver's settings folder ({error.strerror}); "
                "run the recording from a Terminal that has access")
    return problems


def run_logged(step, log_path):
    """Runs a step with its output in a log file. Returns the exit status."""
    os.makedirs(os.path.dirname(log_path), exist_ok=True)
    with open(log_path, "w") as log:
        try:
            return run_group(step.command, cwd=step.cwd, stdout=log, stderr=subprocess.STDOUT)
        except OSError as error:
            log.write(f"cannot run {step.command[0]}: {error.strerror}\n")
            return 127


def tail(path, lines=40):
    try:
        with open(path, errors="replace") as f:
            return "".join(f.readlines()[-lines:])
    except OSError:
        return ""


def run_technique(technique, layers, no_build=False, runner=run_logged, out=None,
                  countdown=10, sleep=time.sleep, check=preflight):
    """Runs one technique's steps. Returns {layer: (result, detail)}.

    The caller holds the device lock.
    """
    out = out or sys.stdout
    say = lambda text: print(text, file=out, flush=True)
    results = {}
    for layer, reason in check(layers).items():
        results[layer] = (FAIL, reason)
    wanted = [layer for layer in layers if layer not in results]
    steps = builds(wanted, no_build) + checks(technique, wanted)
    log_dir = os.path.join(ROOT, "build", "evidence", technique)
    for step in steps:
        pending = [layer for layer in step.layers if layer not in results]
        if not pending:
            continue  # its build failed, or nothing still needs this build
        if step.name == "voiceover-web":
            say(VOICEOVER_WARNING.format(seconds=countdown))
            sleep(countdown)
        log_path = os.path.join(log_dir, step.name.replace(" ", "-") + ".log")
        say(f"[{technique}] {step.name}: running (log: {os.path.relpath(log_path, ROOT)})")
        started = time.monotonic()
        status = runner(step, log_path)
        took = f"{time.monotonic() - started:.0f} s"
        if status == 0:
            say(f"[{technique}] {step.name}: ok, {took}")
            if not step.build:
                results[step.name] = (PASS, took)
            continue
        say(f"[{technique}] {step.name}: FAILED with status {status}, {took}")
        say(tail(log_path))
        detail = (f"{step.name} failed" if step.build else f"exit status {status}") \
            + f"; see {os.path.relpath(log_path, ROOT)}"
        for layer in pending:
            results[layer] = (FAIL, detail)
    for layer in layers:
        results.setdefault(layer, (SKIPPED, "the technique has no test on this layer"))
    return results


def summarise(all_results, layers):
    """The summary lines, and whether everything that ran passed."""
    lines = ["", "Summary", "======="]
    ok = True
    for technique, results in all_results.items():
        lines.append(f"{technique}:")
        for layer in LAYERS:
            if layer not in layers:
                continue
            result, detail = results[layer]
            ok = ok and result != FAIL
            lines.append(f"  {layer:<14} {result:<8} {detail}")
    ran = [r for results in all_results.values() for r, _ in results.values()]
    if not any(r == PASS for r in ran):
        ok = False  # a run that checked nothing has not passed
    lines += ["", "Result: " + ("PASS" if ok else "FAIL")]
    return lines, ok


def parse_layers(text, parser):
    chosen = [part.strip() for part in text.split(",") if part.strip()]
    unknown = [layer for layer in chosen if layer not in LAYERS]
    if unknown or not chosen:
        parser.error(f"unknown layer {', '.join(unknown) or text!r}; layers: {', '.join(LAYERS)}")
    return chosen


def main(argv=None, run=run_technique):
    parser = argparse.ArgumentParser(
        description="Run every device and screen reader check for one technique, "
                    "under the device lock.",
        epilog=f"Layers: {', '.join(LAYERS)}. Techniques: {', '.join(sorted(TECHNIQUES))}.")
    parser.add_argument("technique", nargs="?", help="a technique id, for example F08")
    parser.add_argument("--all", action="store_true", help="run every technique in turn")
    parser.add_argument("--only", help="comma-separated layers to run")
    parser.add_argument("--skip", help="comma-separated layers to leave out")
    parser.add_argument("--no-build", action="store_true",
                        help="use the builds that are already there")
    parser.add_argument("--no-wait", action="store_true",
                        help="exit with status 75 if another run holds the devices")
    args = parser.parse_args(argv)
    if args.all == bool(args.technique):
        parser.error("give one technique id, or --all")
    if args.technique and args.technique.upper() not in TECHNIQUES:
        parser.error(f"unknown technique {args.technique}; techniques: "
                     f"{', '.join(sorted(TECHNIQUES))}")
    if args.only and args.skip:
        parser.error("give --only or --skip, not both")
    layers = list(LAYERS)
    if args.only:
        only = parse_layers(args.only, parser)
        layers = [layer for layer in LAYERS if layer in only]
    if args.skip:
        skip = parse_layers(args.skip, parser)
        layers = [layer for layer in LAYERS if layer not in skip]
        if not layers:
            parser.error("--skip leaves nothing to run")
    techniques = sorted(TECHNIQUES) if args.all else [args.technique.upper()]

    label = "evidence " + ("all techniques" if args.all else techniques[0])
    try:
        lock = device_lock.acquire(label, wait=not args.no_wait, out=sys.stdout)
    except device_lock.Busy as busy:
        print(busy)
        return BUSY
    except device_lock.NotPassedDown as problem:
        print(problem)
        return 1
    all_results = {}
    try:
        for index, technique in enumerate(techniques):
            # Build once; later techniques use the same builds.
            all_results[technique] = run(technique, layers,
                                         no_build=args.no_build or index > 0)
            if index == 0 and any(detail.startswith("build ") for result, detail
                                  in all_results[technique].values() if result == FAIL):
                print("A build failed; not running the remaining techniques.")
                break
    finally:
        lock.release()
    lines, ok = summarise(all_results, layers)
    print("\n".join(lines))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
