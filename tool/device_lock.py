"""One lock for the Android emulator, the iOS simulator, and the host's VoiceOver.

This Mac has one of each, and every worktree of the repository shares them.
Anything that drives a device takes this lock first, so two runs can never
overlap: tool/evidence.py, the transcript tools, and tool/with_devices.py
(for probes and one-off device commands).

The lock is an flock on one file in the user's home folder, so it is the same
for every worktree and clone. The system drops it when the holding process
ends, however it ends, so there is no stale lock to clear. The file's text
says who holds it; that text is only meaningful while the lock is held.

The lock belongs to the open file, not to one process. The holder hands its
descriptor to the commands it starts (child_fds()), so the lock stays taken
for as long as any of them is alive, even if the holder itself is killed.
"""
import contextlib
import datetime
import fcntl
import json
import os
import subprocess
import sys
import time

# Overrides the lock file's path. For tests.
ENV_FILE = "FA11Y_DEVICE_LOCK_FILE"
# Set for child processes by the holder: the holder's pid. A tool started by
# tool/evidence.py finds the lock taken by its own parent and must not wait.
ENV_HELD = "FA11Y_DEVICE_LOCK_HELD"
# Set with it: the number of the lock's descriptor, which the holder passes to
# the commands it starts.
ENV_FD = "FA11Y_DEVICE_LOCK_FD"

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
    """A held lock. Keep it referenced; release() or process exit frees it.

    An inherited lock is the parent run's: this process has a copy of its
    descriptor (or, failing that, is a descendant of the process that holds
    it), and releasing it here changes nothing.
    """

    def __init__(self, fd, inherited=False):
        self.fd = fd
        self.inherited = inherited

    def release(self):
        if self.inherited:
            return
        if self.fd is not None:
            try:
                os.ftruncate(self.fd, 0)
            finally:
                # The flock goes when the last copy of the descriptor is
                # closed: this one, and any a still-running command has.
                os.close(self.fd)
                self.fd = None
        if os.environ.get(ENV_HELD) == str(os.getpid()):
            os.environ.pop(ENV_HELD, None)
            os.environ.pop(ENV_FD, None)
        global _current
        if _current is self:
            _current = None


_current = None  # the Lock this process holds or inherited, for child_fds()


def child_fds():
    """Keyword arguments for subprocess that hand the lock to a command.

    Pass them to every command that drives a device:
    subprocess.run(cmd, **device_lock.child_fds()). The command then holds
    the lock too, so it stays taken until the command has ended, whatever
    happens to this process. {} when this process has no descriptor to give.
    """
    if _current is not None and _current.fd is not None:
        return {"pass_fds": (_current.fd,)}
    return {}


def _try(path):
    """Takes the flock without waiting. Returns the descriptor, or None."""
    fd = os.open(path, os.O_RDWR | os.O_CREAT, 0o644)
    try:
        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        os.close(fd)
        return None
    return fd


def _inherited_fd(path):
    """The lock's descriptor handed down by the holder, or None.

    Only a descriptor that is open in this process and is the lock file
    counts; a number left in the environment proves nothing.
    """
    try:
        fd = int(os.environ.get(ENV_FD, ""))
        ours, lock = os.fstat(fd), os.stat(path)
    except (ValueError, OSError):
        return None
    return fd if (ours.st_dev, ours.st_ino) == (lock.st_dev, lock.st_ino) else None


def _ancestors():
    """The pids of this process's ancestors, nearest first."""
    found, pid = [], os.getppid()
    while pid > 1 and pid not in found:
        found.append(pid)
        try:
            out = subprocess.run(["ps", "-o", "ppid=", "-p", str(pid)],
                                 capture_output=True, text=True, timeout=10).stdout
            pid = int(out.strip())
        except (OSError, ValueError, subprocess.TimeoutExpired):
            break
    return found


def _inherited(path):
    """The parent run's lock, if this process runs under it; else None."""
    fd = _inherited_fd(path)
    if fd is not None:
        return Lock(fd, inherited=True)
    # No descriptor reached us (something in between closed it). The run is
    # still ours if the process the lock file names is a live ancestor.
    claimed = os.environ.get(ENV_HELD)
    holder = read_holder(path)
    if (claimed and holder is not None and str(holder.get("pid")) == claimed
            and claimed in map(str, _ancestors())):
        return Lock(None, inherited=True)
    return None


def acquire(label, wait=True, timeout=None, poll=2.0, remind=60.0, out=None):
    """Takes the device lock and returns a Lock.

    label says what the run is ("evidence F08"); a second caller is shown it.
    With wait=False a held lock raises Busy at once. With a timeout (seconds)
    it raises Busy when the time is up. While waiting, a line saying who holds
    the lock is written to `out` (stderr) at the start and every `remind`
    seconds.
    """
    global _current
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
        inherited = _inherited(path)
        if inherited is not None:
            if _current is None:
                _current = inherited
            return inherited
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
    # Commands started with child_fds() get this descriptor and, with it,
    # the lock.
    os.set_inheritable(fd, True)
    os.environ[ENV_HELD] = str(os.getpid())
    os.environ[ENV_FD] = str(fd)
    _current = Lock(fd)
    return _current


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
