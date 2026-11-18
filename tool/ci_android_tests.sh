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
# The test runner's log comes from `adb logcat` readers in the background,
# and a reader can stop on its own: in one run both had stopped before
# writing a line, with the emulator still attached, and a run in which
# every test passed failed for want of their lines. So the script checks
# the readers every POLL_SECONDS and after every Gradle run, says when one
# has stopped, and starts it again from the time of the last line it wrote
# (logcat -T), leaving out the lines it already has. The device's log is
# cleared at the start, and the script fails before running anything
# unless it then holds no test runner line, so it holds only this run. The
# sweep's lines are told from the batches' by the device's own time: those
# from a line the script writes to the device's log as the sweep starts,
# wherever they end up in the reader's log. When a Gradle run ends
# and the reader has no test runner line for it, or the reader was
# restarted, and before calling a run stalled or a class not run, the
# script adds every test runner line the device still holds that the
# reader's log lacks (logcat -d). Lines are only ever added from the
# device's own log, so a line the reader lost can make a run fail, never
# pass.
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
SETTLE_SECONDS=${SETTLE_SECONDS:-5}
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

# The two readers of the device's log: "full", the whole log, kept for
# diagnosis, and "tests", the test runner's lines, which every check is
# made from. Each has a file it appends to, the logcat filter, what to call
# it, the file adb's own messages go to, and, once started, its process,
# the time it last started from and its restart count.
full_file=$DIAG_DIR/logcat.txt full_filter="" full_what="the device's log"
full_err=$DIAG_DIR/logcat-adb.txt full_pid="" full_since="" full_errpos=0 full_restarts=0
tests_file=$TESTS_LOG tests_filter="-s TestRunner:I" tests_what="the test runner's log"
tests_err=$DIAG_DIR/test-runner-adb.txt tests_pid="" tests_since="" tests_errpos=0 tests_restarts=0
# The tests reader's restart count when its log was last checked against
# the device's; how many such checks, the lines they added, and how many
# could not read the device's log.
TESTS_SYNCED=0 RESYNCS=0 RECOVERED=0 RESYNC_FAILED=0

# Prints the lines of standard input, except that each line of file $1
# leaves out one line equal to it.
drop_held() {
  awk -v f="$1" 'BEGIN { while ((getline l < f) > 0) held[l]++ }
    held[$0] > 0 { held[$0]--; next } { print }'
}

# The latest logcat time near the end of file $1, as -T takes it, or nothing.
last_time() {
  tail -n 2000 "$1" 2>/dev/null | awk '
    /^[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9][.][0-9][0-9][0-9]/ {
      t = substr($0, 1, 18); if (t > max) max = t }
    END { print max }'
}

# Copies standard input, a log logcat gives from time $2 on, to standard
# output as it comes, except that each line of file $1, the lines of time
# $2 already written, leaves out one line equal to it, and a line of an
# earlier time, which logcat should not give, is left out. Only lines of
# time $2 can be held, so once a later line comes the rest is copied as it
# is. (Line by line in the shell: awk would hold lines back until its
# buffer filled.)
skip_repeated() {
  local since=$2 line i n=0 found
  local held=()
  while IFS= read -r line; do held[n]=$line; n=$((n + 1)); done < "$1"
  while [ "$n" -gt 0 ] && IFS= read -r line; do
    case $line in
      [0-9][0-9]-[0-9][0-9]\ *) [[ "${line:0:18}" < "$since" ]] && continue ;;
    esac
    found=""
    for i in "${!held[@]}"; do
      if [ "${held[i]}" = "$line" ]; then
        unset "held[i]"
        n=$((n - 1))
        found=1
        break
      fi
    done
    [ -n "$found" ] || printf '%s\n' "$line"
    [[ "${line:0:18}" > "$since" ]] && break
  done
  exec cat
}

# Starts reader $1. With lines in its file it starts from the time of the
# latest, which logcat gives again, and leaves out the lines of that time
# the file already has; otherwise from the start of the device's log.
start_reader() {
  local name=$1 file filter err since pos
  eval "file=\$${name}_file filter=\$${name}_filter err=\$${name}_err"
  : >> "$err"
  pos=$(wc -l < "$err")
  since=$(last_time "$file")
  if [ -z "$since" ]; then
    adb logcat -v threadtime $filter >> "$file" 2>> "$err" &
  else
    tail -n 2000 "$file" | awk -v s="$since" 'substr($0, 1, 18) == s' > "$file.seam"
    ( adb logcat -v threadtime -T "$since" $filter \
      | skip_repeated "$file.seam" "$since" >> "$file" ) 2>> "$err" &
  fi
  eval "${name}_pid=\$! ${name}_since=\$since ${name}_errpos=\$((\${pos:-0} + 0))"
}

stop_reader() {
  local pid
  eval "pid=\$${1}_pid"
  [ -n "$pid" ] || return 0
  pkill -TERM -P "$pid" 2>/dev/null
  kill -TERM "$pid" 2>/dev/null
  wait "$pid" 2>/dev/null
  eval "${1}_pid=\"\""
}

# If reader $1 has stopped, says so and starts it again.
check_reader() {
  local name=$1 pid err what pos code=unknown said since count from
  eval "pid=\$${name}_pid err=\$${name}_err what=\$${name}_what pos=\$${name}_errpos"
  if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then return 0; fi
  if [ -n "$pid" ]; then wait "$pid" 2>/dev/null; code=$?; fi
  said=$(tail -n "+$((pos + 1))" "$err" 2>/dev/null | tr -s '\r\n' '  ' | cut -c 1-300)
  eval "${name}_restarts=\$((${name}_restarts + 1)) count=\$${name}_restarts"
  start_reader "$name"
  eval "since=\$${name}_since"
  from="the start of the device's log"
  [ -n "$since" ] && from="$since, leaving out the lines it already has"
  say "the reader of $what stopped (exit code $code${said:+; adb said: $said}); restart $count, from $from"
}

check_readers() { check_reader full; check_reader tests; }

# Adds to the test runner's log every test runner line the device still
# holds that the log lacks. The reader is stopped meanwhile, so that no
# line is written twice, and started again after. The device's log held no
# test runner line at the start, so all of them are this run's. Fails if
# the device's log could not be read.
resync_tests_log() {
  local dump=$DIAG_DIR/test-runner-device.txt added ok=0
  RESYNCS=$((RESYNCS + 1))
  # A reader that has stopped is reported, not just started again below.
  check_reader tests
  TESTS_SYNCED=$tests_restarts
  stop_reader tests
  timeout 30 adb wait-for-device > /dev/null 2>&1
  if timeout 60 adb logcat -d -v threadtime -s TestRunner:I > "$dump" 2>> "$tests_err"; then
    drop_held "$TESTS_LOG" < "$dump" > "$dump.new"
    added=$(grep -cF "TestRunner: " "$dump.new")
    cat "$dump.new" >> "$TESTS_LOG"
    RECOVERED=$((RECOVERED + added))
    say "took from the device's log $added test runner lines the reader had not written"
    ok=1
  else
    RESYNC_FAILED=$((RESYNC_FAILED + 1))
    say "could not read the device's log, so any test runner line the reader missed is still missing"
  fi
  start_reader tests
  [ "$ok" -eq 1 ]
}

# The lines of the test runner's log from device time $1 on, in the order
# the log has them. A line taken from the device's log late is still
# classed by the time the device gave it, not by where it was written.
lines_from() { awk -v s="$1" 'substr($0, 1, 18) >= s' "$TESTS_LOG"; }

# Whether the test runner's log has a test runner line for a run: one
# after its line $1, or, with a device time $2, one from that time on.
run_has_line() {
  if [ -n "${2:-}" ]; then
    lines_from "$2" | grep -qF "TestRunner: "
  else
    tail -n "+$(($1 + 1))" "$TESTS_LOG" | grep -qF "TestRunner: "
  fi
}

# Writes a line that no other run has to the device's log and prints the
# time the device gave it, as logcat shows it, or prints nothing and fails
# if it cannot be done or seen. The device's own time marks where a run
# begins, wherever a line ends up in the reader's log.
mark_device() {
  local text="ci_android_tests_$1_$$_$(date +%s)" try line
  for try in 1 2 3; do
    if timeout 30 adb shell log -t CiBoundary -p i "$text" > /dev/null 2>&1; then
      line=$(timeout 60 adb logcat -d -v threadtime -s CiBoundary:I 2>> "$tests_err" \
        | grep -F "CiBoundary: $text" | head -n 1)
      case $line in
        [0-9][0-9]-[0-9][0-9]\ [0-9][0-9]:[0-9][0-9]:[0-9][0-9].[0-9][0-9][0-9]*)
          echo "${line:0:18}"
          return 0 ;;
      esac
    fi
    say "could not mark the $1 in the device's log (try $try of 3)" >&2
    sleep "$POLL_SECONDS"
  done
  return 1
}

# After the Gradle run $1, which exited with $2 and began when the test
# runner's log had $3 lines, or, with $4, at that device time: makes sure
# the log holds the run's lines before the run is judged.
after_run() {
  local label=$1 rc=$2 before=$3 from=${4:-} tries
  # Up to SETTLE_SECONDS for the reader to write the run's first line.
  tries=$(awk -v s="$SETTLE_SECONDS" 'BEGIN { print int(s * 5) }')
  check_readers
  while ! run_has_line "$before" "$from" && [ "$tries" -gt 0 ]; do
    sleep 0.2
    tries=$((tries - 1))
    check_readers
  done
  if ! run_has_line "$before" "$from"; then
    if [ "$rc" -eq 0 ]; then
      say "reader fault: Gradle passed $label, but the reader wrote no test runner line for it; taking them from the device's log"
    else
      say "the reader wrote no test runner line for $label (Gradle exit code $rc); looking for them in the device's log"
    fi
    resync_tests_log
  elif [ "$tests_restarts" -ne "$TESTS_SYNCED" ]; then
    say "the reader of the test runner's log was restarted; taking any line it missed from the device's log"
    resync_tests_log
  fi
}

# How the readers did, for the failure messages: nothing if all was well.
reader_note() {
  [ "$tests_restarts" -eq 0 ] && [ "$RESYNC_FAILED" -eq 0 ] && return
  echo " (restarts of the test runner's log reader: $tests_restarts; checks that could not use the device's log: $RESYNC_FAILED, so lines may be missing)"
}

cleanup() {
  stop_reader full
  stop_reader tests
  rm -f "$full_file.seam" "$tests_file.seam"
  gzip -f "$full_file" 2>/dev/null
  say "lowest memory available during the run: ${MIN_SEEN}MB"
  say "log readers: restarts of the test runner's log reader: $tests_restarts, of the whole log's: $full_restarts; checks against the device's log: $RESYNCS, which added $RECOVERED test runner lines; checks that could not use it: $RESYNC_FAILED"
}

progress_lines() {
  local n
  n=$(grep -cE 'TestRunner: (started|finished):' "$TESTS_LOG" 2>/dev/null)
  echo "${n:-0}"
}

# Called by run_batch, whose last_lines, last_progress and now it uses,
# when no test has started or finished in the reader's log for too long: a
# reader that runs but writes nothing looks like that too. Whether the
# device's log shows progress the reader did not write.
reader_missed_progress() {
  local lines
  say "no test has started or finished in the reader's log for $((now - last_progress)) seconds; checking the device's log"
  resync_tests_log
  lines=$(progress_lines)
  [ "$lines" -ne "$last_lines" ] || return 1
  say "reader fault: the device's log has tests the reader did not write; carrying on"
  last_lines=$lines
  last_progress=$now
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

    check_readers
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
    elif [ $((now - last_progress)) -ge "$window" ] && ! reader_missed_progress; then
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

# Wait for the device first: a reader started while it is away stops.
timeout 120 adb wait-for-device || say "the emulator is not attached to adb after 120 seconds"
# A larger log on the device, so that it still holds the whole run when a
# reader is restarted or a line is missing. Not every image allows it.
timeout 30 adb logcat -G 16M > /dev/null 2>&1 || say "could not enlarge the device's log; it keeps its own size"
# The device's log must hold no test runner line from before this run:
# one from an earlier run could pass a class this run never ran. logcat -c
# can report a failure for a log it cannot clear and still clear this one,
# so the log itself is looked at.
cleared=0
for try in 1 2 3; do
  timeout 30 adb logcat -c || say "adb logcat -c failed (try $try of 3)"
  if timeout 60 adb logcat -d -v threadtime -s TestRunner:I > "$DIAG_DIR/test-runner-at-start.txt" 2>> "$tests_err"; then
    if ! grep -qF "TestRunner: " "$DIAG_DIR/test-runner-at-start.txt"; then
      cleared=1
      break
    fi
    say "the device's log still holds test runner lines from before this run (try $try of 3)"
  else
    say "could not read the device's log to see that it was cleared (try $try of 3)"
  fi
  [ "$try" -lt 3 ] && sleep "$POLL_SECONDS"
done
if [ "$cleared" -ne 1 ]; then
  say "failed: the device's log could not be cleared of test runner lines from before this run, which could pass a class this run did not run. No test was run; the lines are in test-runner-at-start.txt in the android-diagnostics artifact."
  exit 1
fi
: > "$full_file"
: > "$TESTS_LOG"
start_reader full
start_reader tests

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
  before=$(wc -l < "$TESTS_LOG")
  run_batch "class=$names"
  rc=$?
  after_run "batch $batch" "$rc" "$before"
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
sleep "$SETTLE_SECONDS"
# The batches' lines go into the log before the sweep starts, as far as the
# device still has them. The sweep's lines are then those the device logged
# from a line the script writes to it now: a batch's line that only comes
# later still has the device's earlier time, so it is not taken for the
# sweep's.
resync_tests_log \
  || say "the batches' lines could not be checked against the device's log before the sweep; the sweep is told from them by the device's time, and the classes are checked again at the end"
if ! sweep_from=$(mark_device sweep); then
  FAILED=1
  say "failed: could not mark the sweep's start in the device's log, so its lines cannot be told from the batches'. The sweep was not run, so nothing shows that every test class was in the list."
else
  say "sweep: any test outside those ${#CLASSES[@]} classes (the device's lines from $sweep_from on)"
  run_batch "notClass=$all"
  rc=$?
  sleep "$SETTLE_SECONDS"
  after_run "the sweep" "$rc" "" "$sweep_from"
  # The only sweep that passes is one the test runner itself reports as empty
  # from start to end: one start, a finish with 0 tests, 0 failed and 0
  # ignored, and nothing else logged: no test, failure or second run. The
  # count at the start is not used: the test runner gives 1 for a run with
  # no tests in it. A class that fails before its first test starts logs the
  # failure and finishes with 1 failed.
  judge_sweep() {
    swept=$(lines_from "$sweep_from")
    other=$(echo "$swept" | grep -F "TestRunner: " \
      | grep -vE "TestRunner: (run started: [0-9]+ tests|run finished: 0 tests, 0 failed, 0 ignored)[[:space:]]*$")
    [ -z "$other" ] \
      && [ "$(echo "$swept" | grep -cF "TestRunner: run started:")" -eq 1 ] \
      && echo "$swept" | grep -qE "TestRunner: run finished: 0 tests, 0 failed, 0 ignored[[:space:]]*$"
  }
  # A reader that is still running can have left out a line, such as the
  # sweep's finish: before failing the sweep, take what the device has.
  if ! judge_sweep; then
    say "the sweep's lines in the reader's log are not an empty run from start to end; checking the device's log before judging it"
    resync_tests_log
    judge_sweep
  fi
  if ! echo "$swept" | grep -qF "TestRunner: run started:"; then
    FAILED=1
    say "failed: the sweep never reached the test runner (Gradle exit code $rc), so nothing shows that every test class was in the list$(reader_note)"
    dump_state sweep-failed
  elif ! judge_sweep; then
    FAILED=1
    say "failed: the sweep was not an empty run from start to end (Gradle exit code $rc). A test class is missing from the list, or the sweep did not finish$(reader_note). The test runner logged:"
    echo "$swept" | grep -F "TestRunner: " | sed -E 's/.*TestRunner: //'
    dump_state sweep-failed
  else
    say "sweep: no test outside the list"
  fi
  [ -d "$REPORTS/connected" ] && { rm -rf "$REPORTS/sweep"; mv "$REPORTS/connected" "$REPORTS/sweep"; }
fi

# Every class must have run: the test runner's own log has to show a
# finished test for each one. Before a class is failed for it, the device's
# log is checked for lines the reader did not write.
ran_all() {
  local c
  for c in "${CLASSES[@]}"; do
    grep -F "TestRunner: finished: " "$TESTS_LOG" 2>/dev/null | grep -qF "($PKG.$c)" || return 1
  done
}
if ! ran_all; then
  say "a class has no finished test in the reader's log; checking the device's log"
  resync_tests_log
fi
for c in "${CLASSES[@]}"; do
  n=$(grep -cF "TestRunner: finished: " "$TESTS_LOG" 2>/dev/null)
  ran=$(grep -F "TestRunner: finished: " "$TESTS_LOG" 2>/dev/null | grep -cF "($PKG.$c)")
  if [ "${ran:-0}" -eq 0 ]; then
    FAILED=1
    say "failed: no test of $c finished (the log shows ${n:-0} finished tests in all)$(reader_note)"
  fi
done
say "$(grep -cF 'TestRunner: finished: ' "$TESTS_LOG" 2>/dev/null) tests finished in ${#CLASSES[@]} classes"

cleanup
[ "$FAILED" -ne 0 ] && say "failed: a batch failed or a class did not run; the reports are in the android-test-report artifact"
exit $FAILED
