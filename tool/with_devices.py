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
    told to stop and killed after STRAGGLER_GRACE seconds. So nothing started here is
    still driving a device when the caller gives up the lock. The command is
    also handed the lock itself (device_lock.child_fds()), which covers the
    case where this process is killed outright.
    """
    child = subprocess.Popen(command, start_new_session=True, **device_lock.child_fds(),
                             **kwargs)

    def stop(signum, _frame):
        raise SystemExit(128 + signum)

    previous = {s: signal.signal(s, stop) for s in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP)}
    try:
        return child.wait()
    finally:
        # A second signal must not cut the clean-up short.
        for signum in previous:
            signal.signal(signum, signal.SIG_IGN)
        try:
            end_group(child)
        finally:
            for signum, handler in previous.items():
                signal.signal(signum, handler)


def end_group(child):
    """Stops the child, then whatever is left of its process group."""
    if child.poll() is None:
        # The command first, alone, so that it can clean up with commands of
        # its own.
        child.terminate()
        try:
            child.wait(timeout=GRACE)
        except subprocess.TimeoutExpired:
            signal_group(child, signal.SIGKILL)
    if not group_alive(child):
        return
    signal_group(child, signal.SIGTERM)
    deadline = time.monotonic() + STRAGGLER_GRACE
    while group_alive(child):
        if time.monotonic() >= deadline:
            signal_group(child, signal.SIGKILL)
            deadline = float("inf")  # killed: now only wait for it to go
        time.sleep(0.05)


def group_alive(child):
    """Whether any process of the child's group is left."""
    child.poll()  # reap the child itself, or it would count for ever
    try:
        os.killpg(child.pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        # macOS answers this for a group that holds only processes that
        # have ended and are waiting to be reaped by someone else.
        return False
    return True


def signal_group(child, signum):
    try:
        os.killpg(child.pid, signum)
    except (ProcessLookupError, PermissionError):
        pass


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
