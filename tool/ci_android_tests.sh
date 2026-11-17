#!/bin/bash
# Runs the Android instrumented tests on CI and watches them.
#
# The android job used to hang now and then: progress stopped, and nothing
# more was printed until GitHub's job time limit. This script runs Gradle in
# the background and checks every 10 seconds that
#   - a test has started or finished in the last STALL_SECONDS (from the
#     test runner's own log on the device, not Gradle's progress line),
#   - the run has not gone on longer than LIMIT_SECONDS, and
#   - the runner has at least MIN_AVAILABLE_MB of memory available.
# If any check fails it prints why, saves the state of the runner, the
# emulator and the test process to DIAG_DIR, stops Gradle, and fails. It
# also keeps a record of the runner's memory and the emulator's log for
# every run, so a passing run can be compared with a failing one.
#
# Run from android/, as the emulator runner action does. Arguments are
# passed to Gradle.
set -u

DIAG_DIR=${DIAG_DIR:-$PWD/../build/android-diagnostics}
STALL_SECONDS=${STALL_SECONDS:-300}
# Before the first test starts Gradle compiles and installs; allow longer.
FIRST_TEST_SECONDS=${FIRST_TEST_SECONDS:-600}
LIMIT_SECONDS=${LIMIT_SECONDS:-1500}
MIN_AVAILABLE_MB=${MIN_AVAILABLE_MB:-600}
PKG=dev.fluttera11y.flutter_a11y_techniques

mkdir -p "$DIAG_DIR"
HOST_LOG=$DIAG_DIR/host-memory.log
TESTS_LOG=$DIAG_DIR/test-runner.log

say() { echo "WATCHDOG $(date -u +%H:%M:%S) $*"; }

# One line about the runner: memory available, swap used, memory pressure,
# load, the emulator's and the biggest Java process's resident size, disk.
host_line() {
  local avail swap_total swap_free psi load qemu java disk
  avail=$(awk '/^MemAvailable:/ {print int($2/1024)}' /proc/meminfo)
  swap_total=$(awk '/^SwapTotal:/ {print int($2/1024)}' /proc/meminfo)
  swap_free=$(awk '/^SwapFree:/ {print int($2/1024)}' /proc/meminfo)
  psi=$(awk '/^some/ {print $2}' /proc/pressure/memory 2>/dev/null)
  load=$(cut -d' ' -f1 /proc/loadavg)
  qemu=$(ps -eo rss=,comm= | awk '$2 ~ /^qemu-system/ {s+=$1} END {print int(s/1024)}')
  java=$(ps -eo rss=,comm= | awk '$2 == "java" {s+=$1} END {print int(s/1024)}')
  disk=$(df -m --output=avail / | tail -1 | tr -d ' ')
  echo "avail=${avail}MB swap_used=$((swap_total - swap_free))/${swap_total}MB mem_pressure_${psi:-none} load=$load emulator_rss=${qemu}MB java_rss=${java}MB disk_free=${disk}MB"
}

available_mb() { awk '/^MemAvailable:/ {print int($2/1024)}' /proc/meminfo; }

# Everything worth knowing when the run is stuck. Each command has its own
# time limit, since adb itself may be what is stuck.
dump_state() {
  local d=$DIAG_DIR/state
  mkdir -p "$d"
  say "saving the state of the runner and the emulator to $d"
  {
    date -u; uptime; free -m; swapon --show; cat /proc/pressure/memory /proc/pressure/cpu /proc/pressure/io
    echo; df -h; echo; cat /proc/meminfo
  } > "$d/host.txt" 2>&1
  ps aux --sort=-rss > "$d/host-ps.txt" 2>&1
  timeout 20 sudo dmesg -T > "$d/host-dmesg.txt" 2>&1
  for pid in $(pgrep -x java); do
    timeout 30 "$JAVA_HOME/bin/jcmd" "$pid" Thread.print > "$d/host-java-$pid.txt" 2>&1
  done
  timeout 20 adb devices -l > "$d/adb-devices.txt" 2>&1
  local t=40
  timeout $t adb shell uptime > "$d/device-uptime.txt" 2>&1
  timeout $t adb shell dumpsys activity activities > "$d/device-activities.txt" 2>&1
  timeout $t adb shell dumpsys activity processes > "$d/device-processes.txt" 2>&1
  timeout $t adb shell dumpsys window windows > "$d/device-windows.txt" 2>&1
  timeout $t adb shell dumpsys meminfo > "$d/device-meminfo.txt" 2>&1
  timeout $t adb shell dumpsys meminfo $PKG > "$d/device-meminfo-app.txt" 2>&1
  timeout $t adb shell ps -A -T > "$d/device-threads.txt" 2>&1
  timeout $t adb shell top -b -n 1 > "$d/device-top.txt" 2>&1
  timeout $t adb exec-out screencap -p > "$d/device-screen.png" 2>/dev/null
  timeout $t adb logcat -d -b crash > "$d/device-crash-log.txt" 2>&1
  # Thread stacks of the app, which is also the test process. Taking them
  # needs root, and restarting adb as root ends the test run's connection,
  # so this comes after everything that does not.
  timeout $t adb root > "$d/device-app-stacks.txt" 2>&1
  sleep 3
  timeout $t adb wait-for-device
  local pid
  pid=$(timeout $t adb shell pidof $PKG | tr -d '\r')
  echo "app pid: ${pid:-none}" >> "$d/device-app-stacks.txt"
  for p in $pid; do
    timeout $t adb shell debuggerd -j "$p" >> "$d/device-app-stacks.txt" 2>&1
    timeout $t adb shell debuggerd "$p" > "$d/device-app-native-stacks-$p.txt" 2>&1
  done
  timeout $t adb shell 'ls -l /data/anr /data/tombstones' > "$d/device-anr-list.txt" 2>&1
  timeout 300 adb bugreport "$d/device-bugreport.zip" > "$d/device-bugreport.txt" 2>&1
  say "state saved"
}

stop_gradle() {
  pkill -TERM -P "$GRADLE_PID" 2>/dev/null
  kill -TERM "$GRADLE_PID" 2>/dev/null
  sleep 5
  # The test run itself is in Gradle's daemon and its test platform
  # processes; stop them so the step ends.
  timeout 30 ./gradlew --stop > /dev/null 2>&1
  pkill -KILL -f 'com.android.tools.utp' 2>/dev/null
}

cleanup() {
  kill "$LOGCAT_PID" "$TESTLOG_PID" 2>/dev/null
  gzip -f "$DIAG_DIR/logcat.txt" 2>/dev/null
  say "lowest memory available during the run: ${MIN_SEEN}MB"
}

{
  echo "runner: $(nproc) processors, kernel $(uname -r)"
  free -m; swapon --show; df -h /
} > "$DIAG_DIR/host-info.txt" 2>&1
say "runner: $(nproc) processors, $(awk '/^MemTotal:/ {print int($2/1024)}' /proc/meminfo)MB memory, $(awk '/^SwapTotal:/ {print int($2/1024)}' /proc/meminfo)MB swap"
say "$(host_line)"

adb logcat -c
adb logcat -v threadtime > "$DIAG_DIR/logcat.txt" 2>&1 &
LOGCAT_PID=$!
adb logcat -v threadtime -s TestRunner:I > "$TESTS_LOG" 2>&1 &
TESTLOG_PID=$!

./gradlew app:connectedDebugAndroidTest "$@" &
GRADLE_PID=$!

START=$(date +%s)
LAST_PROGRESS=$START
LAST_LINES=0
LAST_PRINT=0
MIN_SEEN=$(available_mb)
REASON=""

while kill -0 "$GRADLE_PID" 2>/dev/null; do
  sleep 10
  now=$(date +%s)
  line=$(host_line)
  echo "$(date -u +%H:%M:%S) $line" >> "$HOST_LOG"
  avail=$(available_mb)
  [ "$avail" -lt "$MIN_SEEN" ] && MIN_SEEN=$avail
  if [ $((now - LAST_PRINT)) -ge 60 ]; then
    say "$line"
    LAST_PRINT=$now
  fi

  lines=$(grep -cE 'TestRunner: (started|finished):' "$TESTS_LOG" 2>/dev/null)
  lines=${lines:-0}
  if [ "$lines" -ne "$LAST_LINES" ]; then
    LAST_LINES=$lines
    LAST_PROGRESS=$now
  fi
  window=$STALL_SECONDS
  [ "$lines" -eq 0 ] && window=$FIRST_TEST_SECONDS

  if [ "$avail" -lt "$MIN_AVAILABLE_MB" ]; then
    REASON="the runner has only ${avail}MB of memory available (limit ${MIN_AVAILABLE_MB}MB)"
  elif [ $((now - LAST_PROGRESS)) -ge "$window" ]; then
    REASON="no test has started or finished for $((now - LAST_PROGRESS)) seconds"
  elif [ $((now - START)) -ge "$LIMIT_SECONDS" ]; then
    REASON="the tests have run for $((now - START)) seconds (limit $LIMIT_SECONDS)"
  fi
  if [ -n "$REASON" ]; then
    say "STOPPING THE TESTS: $REASON"
    say "the last lines of the test runner's log:"
    tail -6 "$TESTS_LOG"
    say "$(host_line)"
    dump_state
    stop_gradle
    cleanup
    say "failed: $REASON. The state is in the android-diagnostics artifact."
    exit 1
  fi
done

wait "$GRADLE_PID"
rc=$?
cleanup
exit $rc
