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
import shutil
import signal
import subprocess
import sys
import time
import uuid

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
    text = ("The devices are in use by \"{label}\" (pid {pid}, started {since}, "
            "in {cwd}).".format(label=holder.get("label", "?"), pid=holder.get("pid", "?"),
                                since=holder.get("since", "?"), cwd=holder.get("cwd", "?")))
    if not _alive(holder.get("pid")):
        text += (" That process has ended, but a command it started is still running and "
                 f"holds the lock; `lsof \"{lock_file()}\"` shows which.")
    return text


def _alive(pid):
    try:
        os.kill(int(pid), 0)
    except (ProcessLookupError, ValueError, TypeError):
        return False
    except PermissionError:
        pass
    return True


def _start_adb_server():
    """Starts the adb server now, before the lock can be handed to anything.

    The first adb command to find no server starts one, and the server stays
    for good. If that command had been given the lock, the server could
    inherit it and never let go. Started here, it cannot.
    """
    adb = os.path.expanduser(os.environ.get("ADB", "~/Library/Android/sdk/platform-tools/adb"))
    if not os.path.exists(adb):
        adb = shutil.which("adb")
    if adb:
        try:
            subprocess.run([adb, "start-server"], capture_output=True, timeout=60)
        except (OSError, subprocess.TimeoutExpired):
            pass


def read_holder(path=None):
    """What the lock file says about its holder, or None if it says nothing."""
    try:
        with open(path or lock_file()) as f:
            data = json.load(f)
    except (OSError, ValueError):
        return None
    return data if isinstance(data, dict) else None


class NotPassedDown(Exception):
    """This process runs under a run that holds the lock, but was not given it."""

    def __init__(self, holder):
        super().__init__(
            "This command was started by a run that holds the device lock "
            f"(\"{(holder or {}).get('label', '?')}\"), but the lock was not passed down to "
            "it, so it could outlive that run and its lock. Start it through "
            "tool/with_devices.py, or with subprocess's **device_lock.child_fds().")


class Lock:
    """A held lock. Keep it referenced; release() or process exit frees it.

    An inherited lock is the parent run's: this process has a copy of its
    descriptor, so the lock lasts at least as long as this process, and
    releasing it here changes nothing.
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
    """The parent run's lock, if this process was given it; else None.

    Raises NotPassedDown if the holder is an ancestor of this process but
    its descriptor did not reach us (something in between closed it).
    Waiting would never end, and carrying on without the lock would let this
    process outlive it.
    """
    fd = _inherited_fd(path)
    if fd is not None:
        return Lock(fd, inherited=True)
    claimed = os.environ.get(ENV_HELD)
    holder = read_holder(path)
    if (claimed and holder is not None and str(holder.get("pid")) == claimed
            and claimed in map(str, _ancestors())):
        raise NotPassedDown(holder)
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
    if ENV_FILE not in os.environ:  # the real lock, not a test's
        _start_adb_server()
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
        except (Busy, NotPassedDown) as problem:
            sys.exit(str(problem))
    return _process_lock


def group_alive(pgid):
    """Whether any process of the group is left."""
    try:
        os.killpg(pgid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        # macOS answers this for a group that holds only processes that
        # have ended and are waiting to be reaped by someone else.
        return False
    return True


def signal_group(pgid, signum):
    try:
        os.killpg(pgid, signum)
    except (ProcessLookupError, PermissionError):
        pass


def group_members(pgid):
    """The pids of the processes in a process group."""
    try:
        table = subprocess.run(["ps", "-axo", "pid=,pgid=,lstart="], capture_output=True,
                               text=True, timeout=10).stdout
    except (OSError, subprocess.TimeoutExpired):
        return set()
    found = set()
    for line in table.splitlines():
        parts = line.split(None, 2)
        if len(parts) == 3 and parts[0].isdigit() and parts[1] == str(pgid):
            found.add(int(parts[0]))
            _born[int(parts[0])] = " ".join(parts[2].split())
    return found


def record(started, leader, mark=None):
    """Adds to `started` everything now traceable to the command `leader`.

    That is the members of its process group, the processes that carry the
    run's `mark`, and whatever it or anything already recorded has started. Called again and again while a command
    runs and while it is ended: a process can only be traced while its
    parent is alive or while it is still in the group, so each look keeps
    what the next could no longer find.
    """
    started |= group_members(leader)
    if mark:
        # First, so that what a marked process has started is followed too.
        started |= marked(mark)
    started |= descendants(started | {leader})


def end_group(pgid, grace, reap=lambda: None, started=None, mark=None):
    """Ends whatever is left of a process group, and returns once it is gone.

    The group is told to stop, and killed if it has not within `grace`
    seconds. `reap` is called before each look, to collect a child of this
    process that has ended; until collected it would count as alive.
    `started`, a set, is the processes already known to have come from the
    group's command. While the group is being ended, whatever they start is
    added to it, so that a helper started by a member that is then killed
    is still known afterwards.
    """
    reap()
    if not group_alive(pgid):
        return
    # Look before signalling, here and everywhere: a process that is
    # stopped can no longer be asked what it started.
    if started is not None:
        record(started, pgid, mark)
    signal_group(pgid, signal.SIGTERM)
    deadline = time.monotonic() + grace
    while True:
        reap()
        if started is not None:
            record(started, pgid, mark)
        if not group_alive(pgid):
            return
        if time.monotonic() >= deadline:
            signal_group(pgid, signal.SIGKILL)
            deadline = float("inf")  # killed: now only wait for it to go
        time.sleep(0.05)


def descendants(pid):
    """The pids of every process started, however indirectly, by `pid`
    (or by any of them, given several).

    Read from the process table, so it finds the ones that have left the
    command's process group: Playwright starts its web server and its
    browsers in groups of their own. A process whose parent has already
    ended is no longer found, which is why run_to_the_end looks while the
    command is still alive.
    """
    try:
        table = subprocess.run(["ps", "-axo", "pid=,ppid=,lstart="], capture_output=True,
                               text=True, timeout=10).stdout
    except (OSError, subprocess.TimeoutExpired):
        return set()
    children, born = {}, {}
    for line in table.splitlines():
        parts = line.split(None, 2)
        if len(parts) == 3 and parts[0].isdigit() and parts[1].isdigit():
            children.setdefault(int(parts[1]), []).append(int(parts[0]))
            born[int(parts[0])] = " ".join(parts[2].split())
    roots = {pid} if isinstance(pid, int) else set(pid)
    # A recorded pid that now belongs to some other process is not a root:
    # what that process starts is none of ours.
    live = {root for root in roots if root not in _born or born.get(root) == _born[root]}
    found, queue = set(), list(live)
    while queue:
        for child in children.get(queue.pop(), []):
            if child not in found:
                found.add(child)
                queue.append(child)
    found -= roots
    for child in found:
        _born[child] = born[child]
    return found


# Set, to a value of its own, in the environment of each command a run
# starts. Everything the command starts inherits it, wherever it ends up.
ENV_RUN = "FA11Y_DEVICE_RUN"


def run_mark():
    """A new mark for one command, and the environment entry that carries it."""
    return uuid.uuid4().hex


def marked(mark):
    """The pids of the processes that carry `mark` in their environment.

    This finds what descendants() cannot: a process whose parent ended
    before anyone looked, so that it is no longer anybody's descendant.
    macOS shows the environment of the user's own processes, but not of
    Apple's own programs (sh, sleep, xcodebuild), so this is a second net
    under descendants(), not a replacement. Between them, what is not
    caught is a process of an Apple program, started detached, whose parent
    then ended within one look of the process table.
    """
    table = ""
    # The first form is macOS's; the second is for Linux, where the tests of
    # this file also run.
    for form in (["ps", "-axEww", "-o", "pid=,lstart=,command="],
                 ["ps", "axeww", "-o", "pid=,lstart=,args="]):
        try:
            run = subprocess.run(form, capture_output=True, text=True, timeout=10)
        except (OSError, subprocess.TimeoutExpired):
            continue
        if run.returncode == 0 and run.stdout:
            table = run.stdout
            break
    found = set()
    for line in table.splitlines():
        if f"{ENV_RUN}={mark}" not in line:
            continue
        parts = line.split(None, 1)
        if len(parts) == 2 and parts[0].isdigit() and int(parts[0]) != os.getpid():
            pid = int(parts[0])
            found.add(pid)
            _born[pid] = " ".join(parts[1].split()[:5])
    return found


# pid -> when the process that descendants() saw with that pid was started.
# A pid is given to a new process once its old one has gone; over a long run
# that can happen, and the new process is none of ours.
_born = {}


def _same_process(pid):
    """Whether `pid` is still the process descendants() recorded."""
    try:
        run = subprocess.run(["ps", "-o", "stat=,lstart=", "-p", str(pid)], capture_output=True,
                             text=True, timeout=10)
    except (OSError, subprocess.TimeoutExpired):
        # Could not look. That is not proof that it has gone: say it is
        # there if anything with that pid is, and let the caller look again.
        return _alive(pid)
    now = run.stdout.strip()
    if not now:
        # ps says nothing both for a pid nothing has and when it fails. Only
        # the system's own answer for the pid settles which.
        return _alive(pid)
    if now.startswith("Z"):
        return False  # ended and waiting to be reaped
    return pid not in _born or " ".join(now.split()[1:]) == _born[pid]


def end_processes(pids, grace, mark=None):
    """Ends the processes that are still alive, and returns once they are gone.

    A process may start another while it is being stopped. So each time
    round, what the remaining ones have started, and whatever carries the
    run's `mark`, is added, told to stop, and waited for like the rest.
    """
    pids = set(pids)
    told = set()
    deadline = time.monotonic() + grace
    while True:
        # Marked ones first, then what any of them has started, and only
        # then is anything signalled: a process is asked for its children
        # while it is still there to be asked.
        if mark:
            pids |= marked(mark)
        left = {pid for pid in pids if _same_process(pid)}
        if left:
            pids |= descendants(left)
        left = {pid for pid in pids if _same_process(pid)}
        if not left:
            return
        killing = time.monotonic() >= deadline
        for pid in left:
            if killing:
                _signal(pid, signal.SIGKILL)
            elif pid not in told:
                _signal(pid, signal.SIGTERM)
                told.add(pid)
        time.sleep(0.05)


def _signal(pid, signum):
    try:
        os.kill(pid, signum)
    except (ProcessLookupError, PermissionError):
        pass


def _is_zombie(pid):
    try:
        state = subprocess.run(["ps", "-o", "stat=", "-p", str(pid)], capture_output=True,
                               text=True, timeout=10).stdout.strip()
    except (OSError, subprocess.TimeoutExpired):
        return False
    return state == "" or state.startswith("Z")


# Seconds an interrupted command gets to end before run_to_the_end stops its
# whole session. Shorter than the time tool/with_devices.py gives a stopped
# tool, so that the tool is still there to do it.
INTERRUPT_GRACE = 240
# Seconds between telling that session to stop and killing it.
KILL_AFTER = 10


def run_to_the_end(command, timeout=None, **kwargs):
    """subprocess.run for a command that drives a device and cleans up after itself.

    The command is given the lock (child_fds()). If this process is told to
    stop or interrupted while it runs, the command is interrupted and this
    process stays until the command has ended, then exits with 128 + the
    number of the signal it was sent. Playwright with Guidepup switches
    VoiceOver off and puts its settings back when it is stopped, and
    xcodebuild ends its test run; a tool that died at once would leave them
    cut off from whoever is waiting for them to finish.

    Whatever stops this process, the command gets one SIGINT. That is what
    Playwright's runner treats as a request to stop cleanly, waiting for its
    workers to tear down; SIGTERM ends the runner at once, and a second
    SIGINT makes it give up on the teardown. The command runs in a session
    of its own, so that Ctrl-C in a terminal reaches only this process and
    pressing it twice still interrupts the command once. A command that has
    not ended INTERRUPT_GRACE seconds after its interrupt is stopped with
    everything in its session, and killed if that does not end it. Once
    the command has ended, whatever is left of its session, and whatever it
    had started outside it, is ended too before this process exits.

    With a timeout (seconds), a command still running then is stopped the
    same way, with its session and what it started, and
    subprocess.TimeoutExpired is raised once all of it has gone.
    """
    begun = time.monotonic()
    timed_out = False
    received = []
    interrupted_at = []
    started = set()  # what the command had started, seen once it was interrupted
    mark = run_mark()
    kwargs["env"] = {**kwargs.get("env", os.environ), ENV_RUN: mark}
    child = subprocess.Popen(command, start_new_session=True, **child_fds(), **kwargs)

    def forward(signum, _frame):
        received.append(signum)
        if len(received) > 1:
            return
        interrupted_at.append(time.monotonic())
        # Before the interrupt: once the command has ended, what it started
        # can no longer be traced to it.
        record(started, child.pid, mark)
        try:
            child.send_signal(signal.SIGINT)
        except ProcessLookupError:
            pass

    previous = {s: signal.signal(s, forward)
                for s in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP)}
    try:
        def signal_all(signum):
            signal_group(child.pid, signum)
            for pid in started:
                if _same_process(pid):
                    _signal(pid, signum)

        stage = 0  # 0 waiting, 1 told to stop, 2 killed
        ended_at = None  # when the interrupted command was seen to have ended
        while True:
            try:
                # Waits for the command and for its output to close, which
                # anything it started and left running can hold open.
                out, err = child.communicate(timeout=0.5)
                break
            except subprocess.TimeoutExpired:
                pass
            now = time.monotonic()
            if child.poll() is not None and ended_at is None:
                ended_at = now
            # What it has started is recorded all the while it runs: once
            # it has ended, they can no longer be traced to it. And what
            # those have started in their turn, and the members of its
            # group, which stay traceable after it has ended.
            record(started, child.pid, mark)
            if timeout is not None and ended_at is None and now - begun >= timeout:
                timed_out = True
            if not interrupted_at and ended_at is None and not timed_out:
                continue  # running, and nobody has asked it to stop
            started |= marked(mark)
            # Force at the deadline after an interrupt, or sooner once the
            # command itself has ended, interrupted or not, and only what it
            # left behind is keeping us here.
            due = min(interrupted_at[0] + INTERRUPT_GRACE if interrupted_at else float("inf"),
                      ended_at if ended_at is not None else float("inf"),
                      begun + timeout if timed_out else float("inf"))
            if stage == 0 and now >= due:
                signal_all(signal.SIGTERM)
                stage = 1
            elif stage >= 1 and now >= due + KILL_AFTER:
                # And again on every look after that: something found only
                # now, holding the output open, is killed like the rest.
                signal_all(signal.SIGKILL)
                stage = 2
    finally:
        # Nothing the command started may outlive this call, however the
        # command ended and whatever went wrong here (output that cannot be
        # decoded, for one): it would be out of everyone's reach, and could
        # go on driving a device after the lock is given up. First its
        # session, then what it had started in groups of their own.
        try:
            record(started, child.pid, mark)
            end_group(child.pid, KILL_AFTER, reap=child.poll, started=started, mark=mark)
            end_processes(started | marked(mark), KILL_AFTER, mark)
        finally:
            for signum, handler in previous.items():
                signal.signal(signum, handler)
    if received:
        sys.exit(128 + received[0])
    if timed_out:
        raise subprocess.TimeoutExpired(command, timeout, output=out, stderr=err)
    return subprocess.CompletedProcess(command, child.returncode, out, err)
