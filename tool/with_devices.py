"""Runs one command while holding the device lock.

Usage: python3 tool/with_devices.py [--label TEXT] [--no-wait] -- <command> [args...]

For probes and any one-off command that drives the Android emulator, the iOS
simulator, or the host's VoiceOver (installing a probe build, a UI Automator
dump, xcodebuild test, a simctl command). The command runs only once no other
run holds the devices; see tool/device_lock.py and docs/parallel-work.md. The
exit status is the command's; 75 means the devices were busy and --no-wait
was given.
"""
import argparse
import os
import signal
import subprocess
import sys
import time

import device_lock

BUSY = 75  # EX_TEMPFAIL


# Seconds a stopped command gets to end by itself before it is killed. Only
# the command is told to stop, not what it started: a stopped
# tool/talkback.py puts the emulator's accessibility settings and TalkBack's
# log level back with adb commands of its own, which takes 15 to 30 seconds
# and longer if adb is slow. Stopping those commands, or killing the tool
# early, would hand the next run an altered device. The lock is held
# throughout.
GRACE = 300
# Seconds anything the command left behind then gets before it is killed.
STRAGGLER_GRACE = 60


def run_group(command, **kwargs):
    """Runs a command in its own process group; returns its exit status.

    Returns only when the whole group has ended: the command and everything
    it started. If this process is interrupted or told to stop, the command
    is told to stop and given GRACE seconds to clean up; whatever is left of
    the group once the command has ended, then or after a normal exit, is
    told to stop and killed after STRAGGLER_GRACE seconds. The same goes for
    what the command started in process groups of their own (a Gradle
    daemon, a detached server): the process table is read every WATCH
    seconds while the command runs, and whatever was seen and is still alive
    at the end is ended too. So nothing started here is still driving a
    device when the caller gives up the lock. The command is also handed the
    lock itself (device_lock.child_fds()), which covers the case where this
    process is killed outright.
    """
    mark = device_lock.run_mark()
    kwargs["env"] = {**kwargs.get("env", os.environ), device_lock.ENV_RUN: mark}
    child = subprocess.Popen(command, start_new_session=True, **device_lock.child_fds(),
                             **kwargs)
    started = set()

    def stop(signum, _frame):
        raise SystemExit(128 + signum)

    previous = {s: signal.signal(s, stop) for s in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP)}
    try:
        return wait_watching(child, started)
    finally:
        # A second signal must not cut the clean-up short.
        for signum in previous:
            signal.signal(signum, signal.SIG_IGN)
        try:
            end_group(child, started, mark)
        finally:
            for signum, handler in previous.items():
                signal.signal(signum, handler)


# Seconds between looks at what the command has started.
WATCH = 2


def wait_watching(child, started, timeout=None):
    """Waits for the child, adding what it starts to `started` as it goes.

    Returns its exit status, or None if `timeout` seconds pass first.
    """
    deadline = None if timeout is None else time.monotonic() + timeout
    while True:
        device_lock.record(started, child.pid)
        wait = WATCH if deadline is None else min(WATCH, max(0, deadline - time.monotonic()))
        try:
            return child.wait(timeout=wait)
        except subprocess.TimeoutExpired:
            if deadline is not None and time.monotonic() >= deadline:
                return None


def end_group(child, started=None, mark=None):
    """Stops the child, then whatever is left of its process group, of the
    processes in `started`, and of those that carry the run's `mark`."""
    started = set() if started is None else started
    if child.poll() is None:
        # The command first, alone, so that it can clean up with commands of
        # its own.
        device_lock.record(started, child.pid)
        child.terminate()
        if wait_watching(child, started, timeout=GRACE) is None:
            signal_group(child, signal.SIGKILL)
    device_lock.end_group(child.pid, STRAGGLER_GRACE, reap=child.poll, started=started)
    if mark:
        # Found by the mark they inherited, even if their parent ended
        # between two looks at the process table.
        started |= device_lock.marked(mark)
    device_lock.end_processes(started, STRAGGLER_GRACE, mark)


def signal_group(child, signum):
    device_lock.signal_group(child.pid, signum)


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Run one command while holding the device lock.",
        usage="python3 tool/with_devices.py [--label TEXT] [--no-wait] -- <command> [args...]")
    parser.add_argument("--label", help="what this run is, shown to anyone waiting")
    parser.add_argument("--no-wait", action="store_true",
                        help="exit with status 75 if the devices are busy")
    parser.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args(argv)
    command = args.command[1:] if args.command[:1] == ["--"] else args.command
    if not command:
        parser.error("no command given")
    try:
        lock = device_lock.acquire(args.label or " ".join(command)[:60], wait=not args.no_wait)
    except device_lock.Busy as busy:
        print(busy, file=sys.stderr)
        return BUSY
    except device_lock.NotPassedDown as problem:
        print(problem, file=sys.stderr)
        return 1
    try:
        return run_group(command)
    except OSError as error:
        # Not found, or found and not runnable.
        print(f"with_devices: cannot run {command[0]}: {error.strerror}", file=sys.stderr)
        return 127
    finally:
        lock.release()


if __name__ == "__main__":
    sys.exit(main())
