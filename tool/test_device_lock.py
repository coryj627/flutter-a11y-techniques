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


class RunToTheEndTest(LockTestCase):
    def test_returns_the_command_s_output_and_status(self):
        run = device_lock.run_to_the_end(
            [sys.executable, "-c", "import sys; print('out'); print('err', file=sys.stderr); sys.exit(5)"],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        self.assertEqual((run.returncode, run.stdout, run.stderr), (5, "out\n", "err\n"))

    def test_detached_process_is_ended_when_the_command_ends_by_itself(self):
        # Nobody stopped the tool; the command just finished, or failed.
        for status in (0, 3):
            for extra in (", stdout=subprocess.DEVNULL", ""):  # or holding the output
                with self.subTest(status=status, extra=extra), \
                        mock.patch.object(device_lock, "KILL_AFTER", 0.3):
                    command = ("import subprocess, sys\n"
                               "p = subprocess.Popen([sys.executable, '-c', 'import signal, time; "
                               "signal.signal(signal.SIGTERM, signal.SIG_IGN); time.sleep(60)'], "
                               f"start_new_session=True, close_fds=True{extra})\n"
                               "sys.stderr.write(str(p.pid)); sys.stderr.flush()\n"
                               f"sys.exit({status})\n")
                    run = device_lock.run_to_the_end(
                        [sys.executable, "-c", command], stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE, text=True)
                    self.assertEqual(run.returncode, status)
                    detached = int(run.stderr)
                    self.addCleanup(self.kill, detached)
                    self.assertFalse(device_lock._same_process(detached),
                                     "a detached process outlived run_to_the_end")

    def test_detached_process_with_no_mark_is_found_while_its_command_runs(self):
        # As a program of Apple's, whose environment cannot be read: only
        # having seen it as a descendant, while its parent lived, finds it.
        for status in (0, 3):
            with self.subTest(status=status), mock.patch.object(device_lock, "KILL_AFTER", 0.3), \
                    mock.patch.object(device_lock, "marked", return_value=set()):
                command = ("import subprocess, sys, time\n"
                           "p = subprocess.Popen(['/bin/sleep', '60'], start_new_session=True, "
                           "stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)\n"
                           "sys.stderr.write(str(p.pid)); sys.stderr.flush()\n"
                           "time.sleep(2)\n"
                           f"sys.exit({status})\n")
                run = device_lock.run_to_the_end(
                    [sys.executable, "-c", command], stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE, text=True)
                self.assertEqual(run.returncode, status)
                detached = int(run.stderr)
                self.addCleanup(self.kill, detached)
                self.assertFalse(device_lock._same_process(detached),
                                 "a detached process outlived run_to_the_end")

    def test_detached_process_is_ended_when_reading_the_output_fails(self):
        command = ("import subprocess, sys\n"
                   "p = subprocess.Popen([sys.executable, '-c', 'import time; time.sleep(60)'], "
                   "start_new_session=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)\n"
                   "sys.stderr.write(str(p.pid)); sys.stderr.flush()\n"
                   "sys.stdout.buffer.write(bytes([255])); sys.exit(0)\n")
        read, write = os.pipe()
        self.addCleanup(os.close, read)
        with mock.patch.object(device_lock, "KILL_AFTER", 0.3), \
                self.assertRaises(UnicodeDecodeError):
            try:
                device_lock.run_to_the_end([sys.executable, "-c", command],
                                           stdout=subprocess.PIPE, stderr=write,
                                           encoding="utf-8")
            finally:
                os.close(write)
        detached = int(os.read(read, 100))
        self.addCleanup(self.kill, detached)
        self.assertFalse(device_lock._same_process(detached),
                         "a detached process outlived the failed read")

    def test_at_the_timeout_the_command_and_what_it_started_are_ended(self):
        command = ("import signal, subprocess, sys, time\n"
                   "signal.signal(signal.SIGTERM, signal.SIG_IGN)\n"
                   "p = subprocess.Popen([sys.executable, '-c', 'import time; time.sleep(60)'], "
                   "start_new_session=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)\n"
                   "sys.stderr.write(str(p.pid) + chr(10)); sys.stderr.flush()\n"
                   "time.sleep(60)\n")
        read, write = os.pipe()
        self.addCleanup(os.close, read)
        started = time.monotonic()
        with mock.patch.object(device_lock, "KILL_AFTER", 0.3), \
                self.assertRaises(subprocess.TimeoutExpired):
            try:
                device_lock.run_to_the_end([sys.executable, "-c", command], timeout=1,
                                           stdout=subprocess.PIPE, stderr=write, text=True)
            finally:
                os.close(write)
        self.assertLess(time.monotonic() - started, 15)
        detached = int(os.read(read, 100))
        self.addCleanup(self.kill, detached)
        self.assertFalse(device_lock._same_process(detached),
                         "a detached process outlived the timeout")

    def test_command_that_ends_in_time_is_not_a_timeout(self):
        run = device_lock.run_to_the_end([sys.executable, "-c", "print(1)"], timeout=30,
                                         stdout=subprocess.PIPE, text=True)
        self.assertEqual((run.returncode, run.stdout), (0, "1\n"))

    def test_helper_of_a_worker_that_holds_the_output_is_ended_too(self):
        # The command has ended; a worker it left keeps the captured output
        # open. Told to stop, the worker starts a detached helper with no
        # readable mark, and stays until killed.
        worker = ("import signal, subprocess, sys, time\n"
                  "def stop(*_):\n"
                  "    h = subprocess.Popen(['/bin/sleep', '60'], start_new_session=True, "
                  "stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)\n"
                  "    open(sys.argv[1], 'w').write(str(h.pid))\n"
                  "signal.signal(signal.SIGTERM, stop)\n"
                  "time.sleep(60)\n")
        helper_file = os.path.join(self.dir.name, "helper")
        command = ("import subprocess, sys, time\n"
                   f"subprocess.Popen([sys.executable, '-c', {worker!r}, {helper_file!r}], "
                   "start_new_session=True)\n"
                   "time.sleep(1.5)\n")
        with mock.patch.object(device_lock, "KILL_AFTER", 1), \
                mock.patch.object(device_lock, "marked", return_value=set()):
            run = device_lock.run_to_the_end([sys.executable, "-c", command],
                                             stdout=subprocess.PIPE, text=True)
        self.assertEqual(run.returncode, 0)
        with open(helper_file) as f:
            helper = int(f.read())
        self.addCleanup(self.kill, helper)
        self.assertFalse(device_lock._same_process(helper),
                         "a helper started during the stop outlived run_to_the_end")

    def test_process_found_after_the_kill_still_holding_the_output_is_killed(self):
        # Looks at the process table are stubbed: the helper, which holds
        # the captured output and ignores SIGTERM, is "found" only after
        # the first kill has gone out.
        command = ("import subprocess, sys\n"
                   "p = subprocess.Popen([sys.executable, '-c', 'import signal, time; "
                   "signal.signal(signal.SIGTERM, signal.SIG_IGN); time.sleep(60)'], "
                   "start_new_session=True, stderr=subprocess.DEVNULL)\n"
                   "sys.stderr.write(str(p.pid)); sys.stderr.flush()\n")
        looks = []

        def late(mark):
            looks.append(1)
            return {helper[0]} if helper and len(looks) > 6 else set()

        helper = []
        read, write = os.pipe()
        self.addCleanup(os.close, read)

        def find_helper(started, leader):
            if not helper:
                try:
                    helper.append(int(os.read(read, 100)))
                except (BlockingIOError, ValueError):
                    pass

        os.set_blocking(read, False)
        started = time.monotonic()
        with mock.patch.object(device_lock, "KILL_AFTER", 0.3), \
                mock.patch.object(device_lock, "record", side_effect=find_helper), \
                mock.patch.object(device_lock, "marked", side_effect=late):
            try:
                run = device_lock.run_to_the_end([sys.executable, "-c", command],
                                                 stdout=subprocess.PIPE, stderr=write, text=True)
            finally:
                os.close(write)
        self.assertEqual(run.returncode, 0)
        self.assertLess(time.monotonic() - started, 30)
        self.addCleanup(self.kill, helper[0])
        self.assertFalse(device_lock._same_process(helper[0]))

    def test_command_is_out_of_reach_of_the_terminal_s_interrupts(self):
        # Ctrl-C goes to the terminal's whole process group. The command must
        # not be in it, or it would be interrupted behind the tool's back.
        run = device_lock.run_to_the_end(
            [sys.executable, "-c", "import os; print(os.getpgid(0), os.getsid(0))"],
            stdout=subprocess.PIPE, text=True)
        group, session = map(int, run.stdout.split())
        self.assertNotEqual(group, os.getpgid(0))
        self.assertNotEqual(session, os.getsid(0))

    def test_command_that_ignores_its_interrupt_is_stopped_with_its_session(self):
        # It is outside the tool's process group, so nobody else would.
        command = ("import signal, subprocess, sys, time\n"
                   "signal.signal(signal.SIGINT, signal.SIG_IGN)\n"
                   "signal.signal(signal.SIGTERM, signal.SIG_IGN)\n"
                   "p = subprocess.Popen([sys.executable, '-c', 'import time; time.sleep(60)'])\n"
                   "print(p.pid, flush=True)\n"
                   "time.sleep(60)\n")
        tool_code = ("import os, sys, device_lock\n"
                     "device_lock.INTERRUPT_GRACE = 0.5\n"
                     "device_lock.KILL_AFTER = 0.5\n"
                     f"device_lock.run_to_the_end([sys.executable, '-c', {command!r}])\n")
        tool = subprocess.Popen([sys.executable, "-c", tool_code], cwd=TOOL, env=self.env(),
                                stdout=subprocess.PIPE, text=True)
        self.addCleanup(tool.stdout.close)
        grandchild = int(tool.stdout.readline())
        self.addCleanup(self.kill, grandchild)
        started = time.monotonic()
        tool.terminate()
        self.assertEqual(tool.wait(timeout=30), 128 + 15)
        self.assertLess(time.monotonic() - started, 20)
        for _ in range(100):
            try:
                os.kill(grandchild, 0)
            except ProcessLookupError:
                break
            time.sleep(0.05)
        else:
            self.fail("part of the command's session was left running")

    def kill(self, pid):
        try:
            os.kill(pid, 9)
        except ProcessLookupError:
            pass

    def test_what_an_interrupted_command_leaves_behind_is_ended_before_the_tool_exits(self):
        # The command ends on its interrupt at once; something it started
        # has let go of its output and ignores being told to stop.
        command = ("import subprocess, sys, time\n"
                   "p = subprocess.Popen([sys.executable, '-c', 'import signal, time; "
                   "signal.signal(signal.SIGTERM, signal.SIG_IGN); "
                   "signal.signal(signal.SIGINT, signal.SIG_IGN); print(1, flush=True); "
                   "time.sleep(60)'], stdout=subprocess.PIPE)\n"
                   "p.stdout.readline()\n"
                   "sys.stderr.write(str(p.pid) + chr(10)); sys.stderr.flush()\n"
                   "time.sleep(60)\n")
        tool_code = ("import subprocess, sys, device_lock\n"
                     "device_lock.KILL_AFTER = 0.5\n"
                     f"device_lock.run_to_the_end([sys.executable, '-c', {command!r}], "
                     "stdout=subprocess.PIPE, text=True)\n")
        tool = subprocess.Popen([sys.executable, "-c", tool_code], cwd=TOOL, env=self.env(),
                                stderr=subprocess.PIPE, text=True)
        self.addCleanup(tool.stderr.close)
        left_behind = int(tool.stderr.readline())
        self.addCleanup(self.kill, left_behind)
        tool.terminate()
        self.assertEqual(tool.wait(timeout=30), 128 + 15)
        try:
            os.kill(left_behind, 0)
            self.fail("the tool exited while part of its command was still running")
        except ProcessLookupError:
            pass

    def test_what_the_command_started_in_a_group_of_its_own_is_ended_too(self):
        # Playwright starts its web server and browsers detached. Here the
        # command ignores its interrupt, so it is still there to be asked
        # what it started, and is then stopped by force.
        command = ("import signal, subprocess, sys, time\n"
                   "signal.signal(signal.SIGINT, signal.SIG_IGN)\n"
                   "p = subprocess.Popen([sys.executable, '-c', 'import signal, time; "
                   "signal.signal(signal.SIGTERM, signal.SIG_IGN); time.sleep(60)'], "
                   "start_new_session=True)\n"
                   "print(p.pid, flush=True)\n"
                   "time.sleep(60)\n")
        tool_code = ("import sys, device_lock\n"
                     "device_lock.INTERRUPT_GRACE = 1.5\n"
                     "device_lock.KILL_AFTER = 0.5\n"
                     f"device_lock.run_to_the_end([sys.executable, '-c', {command!r}])\n")
        tool = subprocess.Popen([sys.executable, "-c", tool_code], cwd=TOOL, env=self.env(),
                                stdout=subprocess.PIPE, text=True)
        self.addCleanup(tool.stdout.close)
        detached = int(tool.stdout.readline())
        self.addCleanup(self.kill, detached)
        tool.terminate()
        self.assertEqual(tool.wait(timeout=30), 128 + 15)
        try:
            os.kill(detached, 0)
            self.fail("a detached process of the command outlived the tool")
        except ProcessLookupError:
            pass

    def run_tool_with_detached(self, command_tail, detached_extra=""):
        """Runs a tool whose command starts a detached process that ignores
        SIGTERM; stops the tool; returns the detached pid after the tool exits."""
        command = ("import signal, subprocess, sys, time\n"
                   "p = subprocess.Popen([sys.executable, '-c', 'import signal, time; "
                   "signal.signal(signal.SIGTERM, signal.SIG_IGN); time.sleep(60)'], "
                   f"start_new_session=True{detached_extra})\n"
                   "sys.stderr.write(str(p.pid) + chr(10)); sys.stderr.flush()\n"
                   + command_tail)
        tool_code = ("import subprocess, sys, device_lock\n"
                     "device_lock.KILL_AFTER = 0.5\n"
                     f"device_lock.run_to_the_end([sys.executable, '-c', {command!r}], "
                     "stdout=subprocess.PIPE, text=True)\n")
        tool = subprocess.Popen([sys.executable, "-c", tool_code], cwd=TOOL, env=self.env(),
                                stderr=subprocess.PIPE, text=True)
        self.addCleanup(tool.stderr.close)
        detached = int(tool.stderr.readline())
        self.addCleanup(self.kill, detached)
        time.sleep(0.3)
        tool.terminate()
        self.assertEqual(tool.wait(timeout=30), 128 + 15)
        return detached

    def assert_ended_with_the_tool(self, pid):
        try:
            os.kill(pid, 0)
            self.fail("a detached process of the command outlived the tool")
        except ProcessLookupError:
            pass

    def test_detached_process_is_ended_when_the_command_exits_at_once(self):
        # The command dies on its interrupt before anyone could look again;
        # what it started must have been recorded before the interrupt.
        self.assert_ended_with_the_tool(self.run_tool_with_detached(
            "time.sleep(60)\n", detached_extra=", stdout=subprocess.DEVNULL"))

    def test_detached_process_holding_the_command_s_output_does_not_hang_the_tool(self):
        # It inherits the captured stdout, so the tool's read of the output
        # cannot end until it is gone.
        self.assert_ended_with_the_tool(self.run_tool_with_detached("time.sleep(60)\n"))

    def test_a_recorded_pid_now_used_by_another_process_is_left_alone(self):
        victim = subprocess.Popen([sys.executable, "-c", "import time; time.sleep(30)"])
        self.addCleanup(victim.wait)
        self.addCleanup(victim.kill)
        # As if an earlier process with this pid had been recorded and gone.
        with mock.patch.dict(device_lock._born, {victim.pid: "Mon Jan  1 00:00:00 2001"}):
            self.assertFalse(device_lock._same_process(victim.pid))
            device_lock.end_processes({victim.pid}, 0.1)
        self.assertIsNone(victim.poll(), "an unrelated process was stopped")

    def test_children_of_a_process_that_took_over_a_recorded_pid_are_not_ours(self):
        code = ("import subprocess, sys, time\n"
                "p = subprocess.Popen([sys.executable, '-c', 'import time; time.sleep(30)'])\n"
                "print(p.pid, flush=True)\ntime.sleep(30)\n")
        other = subprocess.Popen([sys.executable, "-c", code], stdout=subprocess.PIPE, text=True)
        self.addCleanup(other.stdout.close)
        self.addCleanup(other.wait)
        self.addCleanup(other.kill)
        child = int(other.stdout.readline())
        self.addCleanup(self.kill, child)
        self.assertEqual(device_lock.descendants({other.pid}), {child})
        with mock.patch.dict(device_lock._born, {other.pid: "Mon Jan  1 00:00:00 2001"}):
            self.assertEqual(device_lock.descendants({other.pid}), set())

    def test_descendants_are_found_across_process_groups(self):
        code = ("import subprocess, sys, time\n"
                "p = subprocess.Popen([sys.executable, '-c', 'import time; time.sleep(30)'], "
                "start_new_session=True)\n"
                "print(p.pid, flush=True)\ntime.sleep(30)\n")
        parent = subprocess.Popen([sys.executable, "-c", code], stdout=subprocess.PIPE, text=True)
        self.addCleanup(parent.stdout.close)
        grandchild = int(parent.stdout.readline())
        try:
            self.assertEqual(device_lock.descendants(os.getpid()) & {parent.pid, grandchild},
                             {parent.pid, grandchild})
            self.assertEqual(device_lock.descendants(parent.pid), {grandchild})
        finally:
            parent.kill()
            parent.wait()
            device_lock.end_processes({grandchild}, 0.2)
        self.assertFalse(device_lock._alive(grandchild) and not device_lock._is_zombie(grandchild))

    def test_stopped_tool_stays_until_its_command_has_cleaned_up_and_keeps_the_lock(self):
        # As tool/voiceover_web.py under tool/evidence.py: the tool is told to
        # stop, and it is its command (Playwright) that restores VoiceOver.
        marker = os.path.join(self.dir.name, "restored")
        command = ("import signal, sys, time\n"
                   "seen = []\n"
                   "def stop(*_):\n"
                   "    seen.append(1)\n"
                   "    if len(seen) > 1: sys.exit(9)  # a second interrupt\n"
                   "    time.sleep(1.5)\n"
                   f"    open({marker!r}, 'w').close()\n"
                   "    sys.exit(0)\n"
                   "# Playwright stops cleanly on SIGINT only; SIGTERM ends it at once.\n"
                   "signal.signal(signal.SIGINT, stop)\n"
                   "print('up', flush=True)\n"
                   "time.sleep(60)\n")
        tool_code = ("import subprocess, sys, device_lock\n"
                     "device_lock.hold_for_process('voiceover_web F08')\n"
                     f"device_lock.run_to_the_end([sys.executable, '-c', {command!r}])\n")
        with mock.patch.object(with_devices, "STRAGGLER_GRACE", 0.2):
            read, write = os.pipe()
            self.addCleanup(os.close, read)
            lock = device_lock.acquire("evidence F08")
            child = subprocess.Popen([sys.executable, "-c", tool_code], cwd=TOOL, stdout=write,
                                     env=dict(os.environ), start_new_session=True,
                                     **device_lock.child_fds())
            os.close(write)
            self.assertEqual(os.read(read, 10).strip(), b"up")
            # Told to stop twice over: the command is still interrupted once.
            child.send_signal(15)
            time.sleep(0.2)
            with_devices.end_group(child)
            lock.release()
        self.assertEqual(child.returncode, 128 + 15)
        self.assertTrue(os.path.exists(marker), "the command's clean-up was cut short")


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
        with mock.patch.object(with_devices, "STRAGGLER_GRACE", 0.3):
            read, write = os.pipe()
            self.addCleanup(os.close, read)
            status = with_devices.run_group(
                [sys.executable, "-c", self.LEAVES_ONE.format(then="sys.exit(4)")], stdout=write)
            os.close(write)
        self.assertEqual(status, 4)
        self.assert_gone(int(os.read(read, 100)))

    # A command that starts a process in a session of its own, which ignores
    # SIGTERM, prints its pid, and then does what `then` says.
    DETACHES_ONE = ("import subprocess, sys, time; p = subprocess.Popen([sys.executable, '-c', "
                    "'import signal, time; signal.signal(signal.SIGTERM, signal.SIG_IGN); "
                    "time.sleep(60)'], start_new_session=True, stdout=subprocess.DEVNULL); "
                    "print(p.pid, flush=True); {then}")

    def test_detached_process_is_ended_after_the_command_returns_normally(self):
        with mock.patch.object(with_devices, "STRAGGLER_GRACE", 0.3), \
                mock.patch.object(with_devices, "WATCH", 0.2):
            read, write = os.pipe()
            self.addCleanup(os.close, read)
            status = with_devices.run_group(
                [sys.executable, "-c", self.DETACHES_ONE.format(then="time.sleep(1)")],
                stdout=write)
            os.close(write)
        self.assertEqual(status, 0)
        detached = int(os.read(read, 100))
        self.addCleanup(self.kill, detached)
        self.assertFalse(device_lock._alive(detached) and not device_lock._is_zombie(detached),
                         "a detached process outlived run_group")

    def test_detached_process_started_just_before_the_command_exits_is_ended(self):
        # No look at the process table falls between its start and its
        # parent's end (the watch interval is long): only its mark finds it.
        with mock.patch.object(with_devices, "STRAGGLER_GRACE", 0.3), \
                mock.patch.object(with_devices, "WATCH", 30):
            read, write = os.pipe()
            self.addCleanup(os.close, read)
            status = with_devices.run_group(
                [sys.executable, "-c", "import time; time.sleep(0.5); "
                 + self.DETACHES_ONE.format(then="sys.exit(0)")], stdout=write)
            os.close(write)
        self.assertEqual(status, 0)
        detached = int(os.read(read, 100))
        self.addCleanup(self.kill, detached)
        self.assertFalse(device_lock._alive(detached) and not device_lock._is_zombie(detached),
                         "a detached process started late outlived run_group")

    def test_helper_started_by_a_detached_process_while_it_is_stopped_is_ended_too(self):
        # The detached worker answers SIGTERM by starting a helper, itself
        # detached and with no mark, and carries on.
        worker = ("import signal, subprocess, sys, time\n"
                  "def stop(*_):\n"
                  "    h = subprocess.Popen(['/bin/sleep', '60'], start_new_session=True, "
                  "stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)\n"
                  "    open(sys.argv[1], 'w').write(str(h.pid))\n"
                  "signal.signal(signal.SIGTERM, stop)\n"
                  "time.sleep(60)\n")
        helper_file = os.path.join(self.dir.name, "helper")
        command = ("import subprocess, sys, time\n"
                   f"subprocess.Popen([sys.executable, '-c', {worker!r}, {helper_file!r}], "
                   "start_new_session=True, stdout=subprocess.DEVNULL)\n"
                   "time.sleep(1)\n")
        with mock.patch.object(with_devices, "STRAGGLER_GRACE", 1), \
                mock.patch.object(with_devices, "WATCH", 0.2):
            self.assertEqual(with_devices.run_group([sys.executable, "-c", command]), 0)
        with open(helper_file) as f:
            helper = int(f.read())
        self.addCleanup(self.kill, helper)
        self.assertFalse(device_lock._same_process(helper),
                         "a helper started during the stop outlived run_group")

    def test_helper_started_by_a_group_member_while_it_is_stopped_is_ended_too(self):
        # The worker is in the command's own group. Told to stop, it starts
        # a detached helper with no readable mark, and stays until killed.
        worker = ("import signal, subprocess, sys, time\n"
                  "def stop(*_):\n"
                  "    h = subprocess.Popen(['/bin/sleep', '60'], start_new_session=True, "
                  "stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)\n"
                  "    open(sys.argv[1], 'w').write(str(h.pid))\n"
                  "signal.signal(signal.SIGTERM, stop)\n"
                  "print(1, flush=True)\n"
                  "time.sleep(60)\n")
        helper_file = os.path.join(self.dir.name, "helper")
        command = ("import subprocess, sys\n"
                   f"p = subprocess.Popen([sys.executable, '-c', {worker!r}, {helper_file!r}], "
                   "stdout=subprocess.PIPE)\n"
                   "p.stdout.readline()\n")
        with mock.patch.object(with_devices, "STRAGGLER_GRACE", 1), \
                mock.patch.object(with_devices, "WATCH", 0.2), \
                mock.patch.object(device_lock, "marked", return_value=set()):
            self.assertEqual(with_devices.run_group([sys.executable, "-c", command]), 0)
        with open(helper_file) as f:
            helper = int(f.read())
        self.addCleanup(self.kill, helper)
        self.assertFalse(device_lock._same_process(helper),
                         "a helper started during the stop outlived run_group")

    def test_helper_of_a_worker_orphaned_while_the_command_runs_is_ended(self):
        # An intermediary starts a detached worker and ends. Later the
        # worker starts a detached helper with no readable mark, and ends
        # itself, all before the command does.
        helper_file = os.path.join(self.dir.name, "helper")
        worker = ("import subprocess, sys, time\n"
                  "time.sleep(1.5)\n"
                  "h = subprocess.Popen(['/bin/sleep', '60'], start_new_session=True, "
                  "stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)\n"
                  "open(sys.argv[1], 'w').write(str(h.pid))\n"
                  "time.sleep(1.5)\n")
        intermediary = ("import subprocess, sys, time\n"
                        f"subprocess.Popen([sys.executable, '-c', {worker!r}, {helper_file!r}], "
                        "start_new_session=True, stdout=subprocess.DEVNULL)\n"
                        "time.sleep(0.8)\n")
        command = ("import subprocess, sys, time\n"
                   f"subprocess.run([sys.executable, '-c', {intermediary!r}])\n"
                   "time.sleep(4)\n")
        with mock.patch.object(with_devices, "STRAGGLER_GRACE", 0.5), \
                mock.patch.object(with_devices, "WATCH", 0.2), \
                mock.patch.object(device_lock, "marked", return_value=set()):
            self.assertEqual(with_devices.run_group([sys.executable, "-c", command]), 0)
        with open(helper_file) as f:
            helper = int(f.read())
        self.addCleanup(self.kill, helper)
        self.assertFalse(device_lock._same_process(helper),
                         "the helper of an orphaned worker outlived run_group")

    def test_detached_process_is_ended_when_the_tool_is_stopped(self):
        tool = subprocess.Popen(
            [sys.executable, "-c",
             "import sys, with_devices; with_devices.STRAGGLER_GRACE = 0.3; "
             "with_devices.WATCH = 0.2; sys.exit(with_devices.main())",
             "--", sys.executable, "-c", self.DETACHES_ONE.format(then="time.sleep(60)")],
            cwd=TOOL, env=self.env(), stdout=subprocess.PIPE, text=True)
        self.addCleanup(tool.stdout.close)
        detached = int(tool.stdout.readline())
        self.addCleanup(self.kill, detached)
        time.sleep(0.5)
        tool.terminate()
        self.assertEqual(tool.wait(timeout=15), 128 + 15)
        try:
            os.kill(detached, 0)
            self.fail("a detached process outlived the tool, and so the lock")
        except ProcessLookupError:
            pass

    def test_stopping_the_tool_ends_a_descendant_that_ignores_the_signal(self):
        tool = subprocess.Popen(
            [sys.executable, "-c",
             "import sys, with_devices; with_devices.STRAGGLER_GRACE = 0.3; "
             "sys.exit(with_devices.main())",
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
        # It cleans up with a command of its own, as talkback.py does with
        # adb; that command must not be stopped either.
        cleanup = ("import signal, subprocess, sys, time\n"
                   "def stop(*_):\n"
                   "    restore = subprocess.run([sys.executable, '-c', 'import time; time.sleep(1.5)'])\n"
                   "    if restore.returncode == 0:\n"
                   f"        open({marker!r}, 'w').close()\n"
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
        self.assertTrue(os.path.exists(marker), "the clean-up was cut short")

    def test_command_that_will_not_stop_is_killed_after_the_grace_period(self):
        stubborn = ("import signal, time; signal.signal(signal.SIGTERM, signal.SIG_IGN); "
                    "print('up', flush=True); time.sleep(60)")
        tool = subprocess.Popen(
            [sys.executable, "-c",
             "import sys, with_devices; with_devices.GRACE = 0.3; sys.exit(with_devices.main())",
             "--", sys.executable, "-c", stubborn],
            cwd=TOOL, env=self.env(), stdout=subprocess.PIPE, text=True)
        self.addCleanup(tool.stdout.close)
        self.assertEqual(tool.stdout.readline().strip(), "up")
        tool.terminate()
        self.assertEqual(tool.wait(timeout=15), 128 + 15)
        device_lock.acquire("mine", wait=False).release()
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
