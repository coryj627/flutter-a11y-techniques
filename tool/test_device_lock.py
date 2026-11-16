"""Tests for the device lock and tool/with_devices.py.

Run: python3 -m unittest discover -s tool -p 'test_*.py'
"""
import io
import json
import os
import subprocess
import sys
import tempfile
import time
import unittest
from unittest import mock

import device_lock
import with_devices

TOOL = os.path.dirname(os.path.abspath(__file__))

# Holds the lock in another process until its stdin closes.
HOLDER = """
import sys, device_lock
lock = device_lock.acquire(sys.argv[1])
print("held", flush=True)
sys.stdin.read()
"""


class LockTestCase(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.dir.cleanup)
        self.path = os.path.join(self.dir.name, "nested", "device.lock")
        patch = mock.patch.dict(os.environ, {device_lock.ENV_FILE: self.path})
        patch.start()
        self.addCleanup(patch.stop)
        os.environ.pop(device_lock.ENV_HELD, None)

    def env(self):
        env = dict(os.environ)
        env.pop(device_lock.ENV_HELD, None)
        return env

    def start_holder(self, label="other run"):
        holder = subprocess.Popen([sys.executable, "-c", HOLDER, label], cwd=TOOL, env=self.env(),
                                  stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
        self.addCleanup(self.stop, holder)
        self.assertEqual(holder.stdout.readline().strip(), "held")
        return holder

    def stop(self, holder):
        if not holder.stdin.closed:
            holder.stdin.close()
        holder.wait(timeout=10)
        if not holder.stdout.closed:
            holder.stdout.close()


class AcquireTest(LockTestCase):
    def test_free_lock_is_taken_and_names_its_holder(self):
        lock = device_lock.acquire("evidence F08")
        self.addCleanup(lock.release)
        holder = device_lock.read_holder()
        self.assertEqual(holder["label"], "evidence F08")
        self.assertEqual(holder["pid"], os.getpid())
        self.assertEqual(holder["cwd"], os.getcwd())
        self.assertEqual(os.environ[device_lock.ENV_HELD], str(os.getpid()))

    def test_release_clears_the_holder_and_the_environment(self):
        device_lock.acquire("first").release()
        self.assertIsNone(device_lock.read_holder())
        self.assertNotIn(device_lock.ENV_HELD, os.environ)

    def test_second_caller_is_told_who_holds_it_when_not_waiting(self):
        holder = self.start_holder("evidence S05")
        with self.assertRaises(device_lock.Busy) as caught:
            device_lock.acquire("mine", wait=False)
        message = str(caught.exception)
        self.assertIn('"evidence S05"', message)
        self.assertIn(f"pid {holder.pid}", message)
        self.assertNotIn(device_lock.ENV_HELD, os.environ)

    def test_second_caller_waits_and_gets_it_when_the_holder_ends(self):
        holder = self.start_holder("evidence S05")
        out = io.StringIO()
        with mock.patch.object(device_lock.time, "sleep", side_effect=lambda _: self.stop(holder)):
            lock = device_lock.acquire("mine", out=out)
        self.addCleanup(lock.release)
        self.assertIn('in use by "evidence S05"', out.getvalue())
        self.assertIn("Waiting", out.getvalue())
        self.assertEqual(device_lock.read_holder()["label"], "mine")

    def test_waiting_gives_up_at_the_timeout(self):
        self.start_holder()
        started = time.monotonic()
        with self.assertRaises(device_lock.Busy):
            device_lock.acquire("mine", timeout=0.3, poll=0.05, out=io.StringIO())
        self.assertLess(time.monotonic() - started, 5)

    def test_lock_is_free_after_its_holder_is_killed(self):
        holder = self.start_holder()
        holder.kill()
        holder.wait(timeout=10)
        lock = device_lock.acquire("mine", wait=False)
        self.addCleanup(lock.release)
        self.assertEqual(device_lock.read_holder()["label"], "mine")

    def test_child_of_the_holder_that_was_not_given_the_lock_is_refused(self):
        # It could outlive the holder, and so the lock; it must not run.
        lock = device_lock.acquire("evidence F08")
        self.addCleanup(lock.release)
        code = ("import device_lock\n"
                "try:\n    device_lock.acquire('child')\n"
                "except device_lock.NotPassedDown as e:\n    print('refused', e)\n")
        for extra in ({}, {"start_new_session": True}):
            child = subprocess.run([sys.executable, "-c", code], cwd=TOOL, env=dict(os.environ),
                                   capture_output=True, text=True, timeout=30, **extra)
            self.assertIn("refused", child.stdout, child.stderr)
            self.assertIn('"evidence F08"', child.stdout)
            self.assertIn("child_fds()", child.stdout)

    def test_releasing_an_inherited_lock_leaves_the_holder_s_alone(self):
        lock = device_lock.acquire("evidence F08")
        self.addCleanup(lock.release)
        child = subprocess.run(
            [sys.executable, "-c",
             "import device_lock; l = device_lock.acquire('child', wait=False); "
             "l.release(); print(device_lock.read_holder()['label'])"],
            cwd=TOOL, env=dict(os.environ), capture_output=True, text=True,
            **device_lock.child_fds())
        self.assertEqual(child.stdout.strip(), "evidence F08", child.stderr)
        self.assertIsNone(device_lock._try(self.path))

    def test_holder_that_has_ended_is_reported_with_how_to_find_what_holds_it(self):
        dead = subprocess.Popen([sys.executable, "-c", "pass"])
        dead.wait()
        text = device_lock.describe({"label": "evidence S05", "pid": dead.pid,
                                     "since": "now", "cwd": "/w"})
        self.assertIn("has ended", text)
        self.assertIn("lsof", text)
        self.assertNotIn("has ended", device_lock.describe(
            {"label": "x", "pid": os.getpid(), "since": "now", "cwd": "/w"}))

    def test_command_given_the_descriptor_holds_the_lock_itself(self):
        lock = device_lock.acquire("evidence F08")
        child = subprocess.run(
            [sys.executable, "-c",
             "import device_lock; l = device_lock.acquire('child', wait=False); "
             "print(l.inherited, l.fd is not None, device_lock.child_fds() != {})"],
            cwd=TOOL, env=dict(os.environ), capture_output=True, text=True,
            **device_lock.child_fds())
        self.assertEqual(child.stdout.split(), ["True", "True", "True"], child.stderr)
        lock.release()

    def test_lock_stays_taken_while_a_command_that_was_given_it_is_alive(self):
        # The holder is killed outright; its command is still running.
        script = ("import subprocess, sys, device_lock\n"
                  "device_lock.acquire('evidence F08')\n"
                  "child = subprocess.Popen([sys.executable, '-c', "
                  "'import sys; print(1, flush=True); sys.stdin.read()'], "
                  "stdin=subprocess.PIPE, start_new_session=True, **device_lock.child_fds())\n"
                  "print(child.pid, flush=True)\n"
                  "import time; time.sleep(60)\n")
        holder = subprocess.Popen([sys.executable, "-c", script], cwd=TOOL, env=self.env(),
                                  stdout=subprocess.PIPE, text=True)
        self.addCleanup(holder.stdout.close)
        command_pid = int(holder.stdout.readline())
        self.addCleanup(self.kill, command_pid)
        holder.kill()
        holder.wait(timeout=10)
        with self.assertRaises(device_lock.Busy):
            device_lock.acquire("mine", wait=False)
        self.kill(command_pid)
        for _ in range(100):
            fd = device_lock._try(self.path)
            if fd is not None:
                os.close(fd)
                break
            time.sleep(0.05)
        else:
            self.fail("the lock was not freed when the command ended")

    def kill(self, pid):
        try:
            os.kill(pid, 9)
        except ProcessLookupError:
            pass

    def test_claim_by_a_process_that_is_not_an_ancestor_does_not_skip_the_lock(self):
        holder = self.start_holder("evidence S05")
        # The environment names the real holder, but this process is not
        # running under it and has no descriptor from it.
        with mock.patch.dict(os.environ, {device_lock.ENV_HELD: str(holder.pid),
                                          device_lock.ENV_FD: "987"}):
            with self.assertRaises(device_lock.Busy):
                device_lock.acquire("mine", wait=False)

    def test_stale_claim_in_the_environment_does_not_skip_the_lock(self):
        self.start_holder("evidence S05")
        # A claim that names some other process is not the holder's.
        with mock.patch.dict(os.environ, {device_lock.ENV_HELD: "1"}):
            with self.assertRaises(device_lock.Busy):
                device_lock.acquire("mine", wait=False)

    def test_unreadable_holder_text_still_blocks(self):
        self.start_holder()
        with open(self.path, "w") as f:
            f.write("not json")
        with self.assertRaises(device_lock.Busy) as caught:
            device_lock.acquire("mine", wait=False)
        self.assertIn("in use by another run", str(caught.exception))

    def test_default_file_is_outside_any_worktree(self):
        with mock.patch.dict(os.environ):
            del os.environ[device_lock.ENV_FILE]
            path = device_lock.lock_file()
        self.assertTrue(path.startswith(os.path.expanduser("~") + os.sep))
        self.assertNotIn(os.path.dirname(TOOL) + os.sep, path)


class WithDevicesTest(LockTestCase):
    def run_tool(self, *args):
        return subprocess.run([sys.executable, os.path.join(TOOL, "with_devices.py"), *args],
                              cwd=TOOL, env=self.env(), capture_output=True, text=True)

    def test_runs_the_command_under_the_lock_and_returns_its_status(self):
        script = ("import json, os, sys; "
                  f"print(json.load(open({self.path!r}))['label']); "
                  f"print(os.environ[{device_lock.ENV_HELD!r}] != ''); sys.exit(3)")
        run = self.run_tool("--label", "probe f09", "--", sys.executable, "-c", script)
        self.assertEqual(run.returncode, 3, run.stderr)
        self.assertEqual(run.stdout.split("\n")[:2], ["probe f09", "True"])
        self.assertIsNone(device_lock.read_holder())

    def test_busy_devices_with_no_wait_exit_75_and_do_not_run_the_command(self):
        self.start_holder("evidence S05")
        marker = os.path.join(self.dir.name, "ran")
        run = self.run_tool("--no-wait", "--", sys.executable, "-c", f"open({marker!r}, 'w')")
        self.assertEqual(run.returncode, with_devices.BUSY)
        self.assertIn('"evidence S05"', run.stderr)
        self.assertFalse(os.path.exists(marker))

    # A command that starts a second process, which ignores SIGTERM, prints
    # that process's pid, and then does what `then` says.
    LEAVES_ONE = ("import subprocess, sys; p = subprocess.Popen([sys.executable, '-c', "
                  "'import signal, time; signal.signal(signal.SIGTERM, signal.SIG_IGN); "
                  "print(1, flush=True); time.sleep(60)'], stdout=subprocess.PIPE); "
                  "p.stdout.readline(); print(p.pid, flush=True); {then}")

    def assert_gone(self, pid):
        # Reparented to launchd and reaped there; give that a moment.
        for _ in range(100):
            try:
                os.kill(pid, 0)
            except ProcessLookupError:
                return
            time.sleep(0.05)
        self.fail(f"process {pid} was left running")

    def test_a_process_the_command_leaves_behind_is_ended_before_returning(self):
        with mock.patch.object(with_devices, "GRACE", 0.3):
            read, write = os.pipe()
            self.addCleanup(os.close, read)
            status = with_devices.run_group(
                [sys.executable, "-c", self.LEAVES_ONE.format(then="sys.exit(4)")], stdout=write)
            os.close(write)
        self.assertEqual(status, 4)
        self.assert_gone(int(os.read(read, 100)))

    def test_stopping_the_tool_ends_a_descendant_that_ignores_the_signal(self):
        tool = subprocess.Popen(
            [sys.executable, "-c",
             "import sys, with_devices; with_devices.GRACE = 0.3; sys.exit(with_devices.main())",
             "--", sys.executable, "-c", self.LEAVES_ONE.format(then="import time; time.sleep(60)")],
            cwd=TOOL, env=self.env(), stdout=subprocess.PIPE, text=True)
        self.addCleanup(tool.stdout.close)
        descendant = int(tool.stdout.readline())
        self.addCleanup(self.kill, descendant)
        tool.terminate()
        self.assertEqual(tool.wait(timeout=15), 128 + 15)
        # The tool had the lock until it exited, and exited only once the
        # descendant was gone.
        try:
            os.kill(descendant, 0)
            self.fail("the descendant outlived the tool, and so the lock")
        except ProcessLookupError:
            pass
        device_lock.acquire("mine", wait=False).release()

    def kill(self, pid):
        try:
            os.kill(pid, 9)
        except ProcessLookupError:
            pass

    def test_stopped_command_is_given_time_to_put_the_device_back(self):
        # tool/talkback.py restores settings when told to stop; that takes
        # longer than a short grace period would allow.
        self.assertGreaterEqual(with_devices.GRACE, 120)
        marker = os.path.join(self.dir.name, "restored")
        cleanup = ("import signal, sys, time\n"
                   "def stop(*_):\n"
                   "    time.sleep(1.5)\n"
                   f"    open({marker!r}, 'w').close()\n"
                   "    sys.exit(143)\n"
                   "signal.signal(signal.SIGTERM, stop)\n"
                   "print('up', flush=True)\n"
                   "time.sleep(60)\n")
        tool = subprocess.Popen(
            [sys.executable, os.path.join(TOOL, "with_devices.py"), "--", sys.executable, "-c",
             cleanup], cwd=TOOL, env=self.env(), stdout=subprocess.PIPE, text=True)
        self.addCleanup(tool.stdout.close)
        self.assertEqual(tool.stdout.readline().strip(), "up")
        tool.terminate()
        time.sleep(0.5)
        # Still cleaning up: the lock is still taken.
        with self.assertRaises(device_lock.Busy):
            device_lock.acquire("mine", wait=False)
        self.assertEqual(tool.wait(timeout=15), 128 + 15)
        self.assertTrue(os.path.exists(marker), "the command was killed before it had cleaned up")
        device_lock.acquire("mine", wait=False).release()

    def test_missing_command_is_a_usage_error(self):
        self.assertEqual(self.run_tool("--label", "x").returncode, 2)

    def test_command_that_cannot_be_run_exits_127(self):
        self.assertEqual(self.run_tool("--", "no-such-command-fa11y").returncode, 127)

    def test_stopping_the_tool_stops_the_command_and_frees_the_lock(self):
        tool = subprocess.Popen(
            [sys.executable, os.path.join(TOOL, "with_devices.py"), "--", sys.executable, "-c",
             "import os, time; print(os.getpid(), flush=True); time.sleep(60)"],
            cwd=TOOL, env=self.env(), stdout=subprocess.PIPE, text=True)
        child_pid = int(tool.stdout.readline())
        tool.terminate()
        self.assertEqual(tool.wait(timeout=15), 128 + 15)
        tool.stdout.close()
        for _ in range(50):
            try:
                os.kill(child_pid, 0)
            except ProcessLookupError:
                break
            time.sleep(0.1)
        else:
            self.fail("the command was left running")
        device_lock.acquire("mine", wait=False).release()


if __name__ == "__main__":
    unittest.main()
