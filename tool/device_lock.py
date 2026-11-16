"""One lock for the Android emulator, the iOS simulator, and the host's VoiceOver.

This Mac has one of each, and every worktree of the repository shares them.
Anything that drives a device takes this lock first, so two runs can never
overlap: tool/evidence.py, the transcript tools, and tool/with_devices.py
(for probes and one-off device commands).

The lock is an flock on one file in the user's home folder, so it is the same
for every worktree and clone. The system drops it when the holding process
ends, however it ends, so there is no stale lock to clear. The file's text
says who holds it; that text is only meaningful while the lock is held.
"""
import contextlib
import datetime
import fcntl
import json
import os
import sys
import time

# Overrides the lock file's path. For tests.
ENV_FILE = "FA11Y_DEVICE_LOCK_FILE"
# Set for child processes by the holder: the holder's pid. A tool started by
# tool/evidence.py finds the lock taken by its own parent and must not wait.
ENV_HELD = "FA11Y_DEVICE_LOCK_HELD"

DEFAULT_FILE = os.path.join(os.path.expanduser("~"), "Library", "Application Support",
                            "flutter-a11y-techniques", "device.lock")


class Busy(Exception):
    """The lock is held by someone else and the caller chose not to wait."""

    def __init__(self, holder):
        super().__init__(describe(holder))
        self.holder = holder


def lock_file():
    return os.environ.get(ENV_FILE) or DEFAULT_FILE


def describe(holder):
    """One line saying who holds the lock, from the lock file's text."""
    if not holder:
        return "The devices are in use by another run (it has not said which)."
    return ("The devices are in use by \"{label}\" (pid {pid}, started {since}, "
            "in {cwd}).".format(label=holder.get("label", "?"), pid=holder.get("pid", "?"),
                                since=holder.get("since", "?"), cwd=holder.get("cwd", "?")))


def read_holder(path=None):
    """What the lock file says about its holder, or None if it says nothing."""
    try:
        with open(path or lock_file()) as f:
            data = json.load(f)
    except (OSError, ValueError):
        return None
    return data if isinstance(data, dict) else None


class Lock:
    """A held lock. Keep it referenced; release() or process exit frees it."""

    def __init__(self, fd, inherited=False):
        self.fd = fd
        self.inherited = inherited

    def release(self):
        if self.fd is not None:
            try:
                os.ftruncate(self.fd, 0)
            finally:
                os.close(self.fd)  # closing the descriptor drops the flock
                self.fd = None
        if not self.inherited and os.environ.get(ENV_HELD) == str(os.getpid()):
            del os.environ[ENV_HELD]


def _try(path):
    """Takes the flock without waiting. Returns the descriptor, or None."""
    fd = os.open(path, os.O_RDWR | os.O_CREAT, 0o644)
    try:
        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        os.close(fd)
        return None
    return fd


def _held_by_parent(path):
    """True if an ancestor run holds the lock for this process."""
    claimed = os.environ.get(ENV_HELD)
    holder = read_holder(path)
    return bool(claimed) and holder is not None and str(holder.get("pid")) == claimed


def acquire(label, wait=True, timeout=None, poll=2.0, remind=60.0, out=None):
    """Takes the device lock and returns a Lock.

    label says what the run is ("evidence F08"); a second caller is shown it.
    With wait=False a held lock raises Busy at once. With a timeout (seconds)
    it raises Busy when the time is up. While waiting, a line saying who holds
    the lock is written to `out` (stderr) at the start and every `remind`
    seconds.
    """
    out = out or sys.stderr
    path = lock_file()
    os.makedirs(os.path.dirname(path), exist_ok=True)
    started = time.monotonic()
    last_said = None
    while True:
        fd = _try(path)
        if fd is not None:
            break
        # Taken. If it is our own parent run that holds it, carry on under it.
        if _held_by_parent(path):
            return Lock(None, inherited=True)
        holder = read_holder(path)
        waited = time.monotonic() - started
        if not wait or (timeout is not None and waited >= timeout):
            raise Busy(holder)
        if last_said is None or time.monotonic() - last_said >= remind:
            print(f"{describe(holder)} Waiting for it to finish.", file=out, flush=True)
            last_said = time.monotonic()
        time.sleep(poll)
    holder = {"label": label, "pid": os.getpid(), "cwd": os.getcwd(),
              "since": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")}
    os.ftruncate(fd, 0)
    os.pwrite(fd, json.dumps(holder).encode(), 0)
    os.environ[ENV_HELD] = str(os.getpid())
    return Lock(fd)


@contextlib.contextmanager
def held(label, **kwargs):
    lock = acquire(label, **kwargs)
    try:
        yield lock
    finally:
        lock.release()


_process_lock = None


def hold_for_process(label, **kwargs):
    """Takes the lock for the rest of this process. For a tool's main().

    Exits with a message, not a traceback, if the lock is busy and the caller
    chose not to wait.
    """
    global _process_lock
    if _process_lock is None:
        try:
            _process_lock = acquire(label, **kwargs)
        except Busy as busy:
            sys.exit(str(busy))
    return _process_lock
