#!/bin/bash
# Runs the Android instrumented tests on CI and watches them.
#
# The test classes run in batches of BATCH_CLASSES, one Gradle run each, so
# that each batch has a test process of its own. In one process that runs
# every test, each example a test opens leaves graphics memory behind in the
# emulator (about 55 MB each); near test 90 the runner ran out of memory and
# froze, and the job sat silent until GitHub's time limit. The memory is
# given back when the test process ends.
#
# Gradle runs in the background, and every 10 seconds this script checks that
#   - a test has started or finished in the last STALL_SECONDS (from the
#     test runner's own log on the device, not Gradle's progress line),
#   - the run has not gone on longer than LIMIT_SECONDS,
#   - the runner has at least MIN_AVAILABLE_MB of memory available, and
#   - the emulator is still running.
# If a check fails it prints why, saves the state of the runner, the
# emulator and the test process to DIAG_DIR, stops Gradle, and fails. It
# also keeps a record of the runner's memory and the emulator's log for
# every run, so a passing run can be compared with a failing one.
#
# The classes to run are every Kotlin file in the test folder that has a
# @Test anywhere in it, a comment included: a file wrongly taken for a test
# fails the run, where a test file wrongly passed over would not be noticed.
#
# After the batches, one more Gradle run asks the test runner for every test
# that is in none of those classes. It should find none. If it runs any, or
# never reaches the test runner, the script fails: the list above missed a
# class, and this is the test runner's own word for it, whatever the file
# looked like. The script fails if it finds none, if such a file does not
# declare a class of its own name, or if, at the end, the test runner's log
# does not show at least one finished test for every one of those classes.
#
# Run from android/, as the emulator runner action does. Arguments are
# passed to Gradle. Every batch runs even if an earlier one failed; the
# script fails if any did. With --list as the only argument it prints the
# classes it would run, one per line, and runs nothing.
set -u

DIAG_DIR=${DIAG_DIR:-$PWD/../build/android-diagnostics}
STALL_SECONDS=${STALL_SECONDS:-300}
# Before a batch's first test starts Gradle compiles and installs; allow longer.
FIRST_TEST_SECONDS=${FIRST_TEST_SECONDS:-600}
LIMIT_SECONDS=${LIMIT_SECONDS:-1800}
MIN_AVAILABLE_MB=${MIN_AVAILABLE_MB:-600}
BATCH_CLASSES=${BATCH_CLASSES:-4}
POLL_SECONDS=${POLL_SECONDS:-10}
PKG=dev.fluttera11y.flutter_a11y_techniques
TEST_DIR=${TEST_DIR:-app/src/androidTest/kotlin/dev/fluttera11y/flutter_a11y_techniques}
REPORTS=$PWD/../build/app/reports/androidTests

# Every class with a test in it, in name order, in CLASSES. Fails if the
# folder cannot be read, has no tests, or has a file with a @Test that does
# not declare a class named after the file.
find_classes() {
  local files file name
  CLASSES=()
  if [ ! -d "$TEST_DIR" ]; then
    echo "ci_android_tests: no test folder at $TEST_DIR" >&2
    return 1
  fi
  files=$(grep -lE '@Test\b' "$TEST_DIR"/*.kt 2>/dev/null | sort)
  if [ -z "$files" ]; then
    echo "ci_android_tests: no file in $TEST_DIR has a @Test" >&2
    return 1
  fi
  while IFS= read -r file; do
    name=$(basename "$file" .kt)
    if ! grep -qE "^[[:space:]]*([a-z]+[[:space:]]+)*class[[:space:]]+$name\b" "$file"; then
      echo "ci_android_tests: $file has a @Test but no class named $name" >&2
      return 1
    fi
    CLASSES+=("$name")
  done <<EOF_FILES
$files
EOF_FILES
}

find_classes || exit 1
if [ "${1:-}" = --list ]; then
  printf '%s\n' "${CLASSES[@]}"
  exit 0
fi

mkdir -p "$DIAG_DIR"
HOST_LOG=$DIAG_DIR/host-memory.log
TESTS_LOG=$DIAG_DIR/test-runner.log

say() { echo "WATCHDOG $(date -u +%H:%M:%S) $*"; }

# One line about the runner: memory available, swap used, memory pressure,
# load, the emulator's and all Java processes' resident size, disk.
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

# The state of the runner and the emulator, in DIAG_DIR/<name>. Each command
# has its own time limit, since adb itself may be what is stuck. With
# "full", also the test process's thread stacks and a bugreport, which
# restart adb as root and take a few minutes; only for a run that is stuck.
dump_state() {
  local d=$DIAG_DIR/$1 depth=${2:-light}
  mkdir -p "$d"
  say "saving the state of the runner and the emulator to $d"
  {
    date -u; uptime; free -m; swapon --show; cat /proc/pressure/memory /proc/pressure/cpu /proc/pressure/io
    echo; df -h; echo; cat /proc/meminfo
  } > "$d/host.txt" 2>&1
  ps aux --sort=-rss > "$d/host-ps.txt" 2>&1
  timeout 20 sudo dmesg -T > "$d/host-dmesg.txt" 2>&1
  for avd in ~/.android/avd/*.avd; do
    [ -f "$avd/config.ini" ] && cp "$avd/config.ini" "$d/emulator-config-$(basename "$avd" .avd).ini"
  done
  find /tmp ~/.android -name '*.dmp' -newer "$DIAG_DIR/host-info.txt" -exec ls -l {} + > "$d/emulator-crash-dumps.txt" 2>&1
  timeout 20 adb devices -l > "$d/adb-devices.txt" 2>&1
  if ! timeout 20 adb shell true > /dev/null 2>&1; then
    say "the emulator does not answer; saved the runner's state only"
    return
  fi
  local t=40
  timeout $t adb shell uptime > "$d/device-uptime.txt" 2>&1
  timeout $t adb shell dumpsys activity activities > "$d/device-activities.txt" 2>&1
  timeout $t adb shell dumpsys window windows > "$d/device-windows.txt" 2>&1
  timeout $t adb shell dumpsys meminfo > "$d/device-meminfo.txt" 2>&1
  timeout $t adb exec-out screencap -p > "$d/device-screen.png" 2>/dev/null
  timeout $t adb logcat -d -b crash > "$d/device-crash-log.txt" 2>&1
  if [ "$depth" = full ]; then
    for pid in $(pgrep -x java); do
      timeout 30 "${JAVA_HOME:+$JAVA_HOME/bin/}jcmd" "$pid" Thread.print > "$d/host-java-$pid.txt" 2>&1
    done
    timeout $t adb shell dumpsys activity processes > "$d/device-processes.txt" 2>&1
    timeout $t adb shell dumpsys meminfo $PKG > "$d/device-meminfo-app.txt" 2>&1
    timeout $t adb shell ps -A -T > "$d/device-threads.txt" 2>&1
    timeout $t adb shell top -b -n 1 > "$d/device-top.txt" 2>&1
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
  fi
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

progress_lines() {
  local n
  n=$(grep -cE 'TestRunner: (started|finished):' "$TESTS_LOG" 2>/dev/null)
  echo "${n:-0}"
}

# Runs Gradle with one test runner argument, such as class=A,B, and watches
# it. Returns Gradle's exit code; if a check fails, saves the state and ends
# the script.
run_batch() {
  local filter=$1 reason="" now line avail lines window base last_lines last_progress
  ./gradlew app:connectedDebugAndroidTest \
    "-Pandroid.testInstrumentationRunnerArguments.$filter" "${GRADLE_ARGS[@]}" &
  GRADLE_PID=$!
  base=$(progress_lines)
  last_lines=$base
  last_progress=$(date +%s)
  while kill -0 "$GRADLE_PID" 2>/dev/null; do
    sleep "$POLL_SECONDS"
    # Gradle may have finished during the sleep: then its own result
    # stands, and no check below may fail a batch that is already over.
    kill -0 "$GRADLE_PID" 2>/dev/null || break
    now=$(date +%s)
    line=$(host_line)
    echo "$(date -u +%H:%M:%S) $line" >> "$HOST_LOG"
    avail=$(available_mb)
    [ "$avail" -lt "$MIN_SEEN" ] && MIN_SEEN=$avail
    if [ $((now - LAST_PRINT)) -ge 60 ]; then
      say "$line"
      LAST_PRINT=$now
    fi

    lines=$(progress_lines)
    if [ "$lines" -ne "$last_lines" ]; then
      last_lines=$lines
      last_progress=$now
    fi
    window=$STALL_SECONDS
    [ "$lines" -eq "$base" ] && window=$FIRST_TEST_SECONDS

    if ! pgrep -f qemu-system > /dev/null; then
      reason="the emulator has exited"
    elif [ "$avail" -lt "$MIN_AVAILABLE_MB" ]; then
      reason="the runner has only ${avail}MB of memory available (limit ${MIN_AVAILABLE_MB}MB)"
    elif [ $((now - last_progress)) -ge "$window" ]; then
      reason="no test has started or finished for $((now - last_progress)) seconds"
    elif [ $((now - START)) -ge "$LIMIT_SECONDS" ]; then
      reason="the tests have run for $((now - START)) seconds (limit $LIMIT_SECONDS)"
    fi
    if [ -n "$reason" ] && kill -0 "$GRADLE_PID" 2>/dev/null; then
      say "STOPPING THE TESTS: $reason"
      say "the last lines of the test runner's log:"
      tail -6 "$TESTS_LOG"
      say "$(host_line)"
      dump_state stuck full
      stop_gradle
      cleanup
      say "failed: $reason. The state is in the android-diagnostics artifact."
      exit 1
    fi
  done
  wait "$GRADLE_PID"
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

GRADLE_ARGS=("$@")
START=$(date +%s)
LAST_PRINT=0
MIN_SEEN=$(available_mb)
FAILED=0

say "${#CLASSES[@]} test classes, in batches of $BATCH_CLASSES"
batch=0
for ((i = 0; i < ${#CLASSES[@]}; i += BATCH_CLASSES)); do
  batch=$((batch + 1))
  names=""
  for c in "${CLASSES[@]:i:BATCH_CLASSES}"; do names="$names${names:+,}$PKG.$c"; done
  say "batch $batch: ${CLASSES[*]:i:BATCH_CLASSES}"
  run_batch "class=$names"
  rc=$?
  # Each Gradle run replaces the last one's report; keep them all.
  if [ -d "$REPORTS/connected" ]; then
    rm -rf "$REPORTS/batch-$batch"
    mv "$REPORTS/connected" "$REPORTS/batch-$batch"
  fi
  if [ "$rc" -ne 0 ]; then
    FAILED=1
    say "batch $batch failed: Gradle exit code $rc"
    say "$(host_line)"
    pgrep -f qemu-system > /dev/null || say "the emulator has exited"
    dump_state "batch-$batch-failed"
  fi
done

# The sweep: every test that is in none of the classes above. There should
# be none. Gradle's own result is not used, since it may count a run with
# no tests as a failure; the test runner's log is.
all=""
for c in "${CLASSES[@]}"; do all="$all${all:+,}$PKG.$c"; done
sleep "${SETTLE_SECONDS:-5}"
before=$(wc -l < "$TESTS_LOG")
say "sweep: any test outside those ${#CLASSES[@]} classes"
run_batch "notClass=$all"
rc=$?
sleep "${SETTLE_SECONDS:-5}"
swept=$(tail -n "+$((before + 1))" "$TESTS_LOG")
# The only sweep that passes is one the test runner itself reports as empty
# from start to end: it started with 0 tests, finished with 0 tests and 0
# failed, and logged no other start, test or failure. A class that fails
# before its first test starts has a count above 0 and no "started:" line.
other=$(echo "$swept" | grep -F "TestRunner: " \
  | grep -vE "TestRunner: (run started: 0 tests|run finished: 0 tests, 0 failed, 0 ignored)[[:space:]]*$")
if ! echo "$swept" | grep -qF "TestRunner: run started:"; then
  FAILED=1
  say "failed: the sweep never reached the test runner (Gradle exit code $rc), so nothing shows that every test class was in the list"
  dump_state sweep-failed
elif [ -n "$other" ] \
  || ! echo "$swept" | grep -qE "TestRunner: run started: 0 tests[[:space:]]*$" \
  || ! echo "$swept" | grep -qE "TestRunner: run finished: 0 tests, 0 failed, 0 ignored[[:space:]]*$"; then
  FAILED=1
  say "failed: the sweep was not an empty run from start to end (Gradle exit code $rc). A test class is missing from the list, or the sweep did not finish. The test runner logged:"
  echo "$swept" | grep -F "TestRunner: " | sed -E 's/.*TestRunner: //'
  dump_state sweep-failed
else
  say "sweep: no test outside the list"
fi
[ -d "$REPORTS/connected" ] && { rm -rf "$REPORTS/sweep"; mv "$REPORTS/connected" "$REPORTS/sweep"; }

# Every class must have run: the test runner's own log has to show a
# finished test for each one.
for c in "${CLASSES[@]}"; do
  n=$(grep -cF "TestRunner: finished: " "$TESTS_LOG" 2>/dev/null)
  ran=$(grep -F "TestRunner: finished: " "$TESTS_LOG" 2>/dev/null | grep -cF "($PKG.$c)")
  if [ "${ran:-0}" -eq 0 ]; then
    FAILED=1
    say "failed: no test of $c finished (the log shows ${n:-0} finished tests in all)"
  fi
done
say "$(grep -cF 'TestRunner: finished: ' "$TESTS_LOG" 2>/dev/null) tests finished in ${#CLASSES[@]} classes"

cleanup
[ "$FAILED" -ne 0 ] && say "failed: a batch failed or a class did not run; the reports are in the android-test-report artifact"
exit $FAILED
