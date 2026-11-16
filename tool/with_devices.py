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

import device_lock

BUSY = 75  # EX_TEMPFAIL


def run_group(command, **kwargs):
    """Runs a command in its own process group; returns its exit status.

    If this process is interrupted or told to stop, the whole group is
    stopped too, so nothing keeps driving a device after the lock is gone.
    """
    child = subprocess.Popen(command, start_new_session=True, **kwargs)

    def stop(signum, _frame):
        with_group(child, signal.SIGTERM)
        raise SystemExit(128 + signum)

    previous = {s: signal.signal(s, stop) for s in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP)}
    try:
        return child.wait()
    finally:
        for signum, handler in previous.items():
            signal.signal(signum, handler)
        if child.poll() is None:
            with_group(child, signal.SIGTERM)
            try:
                child.wait(timeout=10)
            except subprocess.TimeoutExpired:
                with_group(child, signal.SIGKILL)


def with_group(child, signum):
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
