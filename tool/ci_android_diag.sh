#!/bin/bash
# Throwaway diagnostic for the Android CI hang (experiment branch only).
# Runs the instrumented tests with no per-test timeout, as the two hung
# runs did. If they have not finished in 20 minutes, prints which test was
# running and where the test process is stuck, then fails.
set -u
PKG=dev.fluttera11y.flutter_a11y_techniques
adb logcat -c
timeout 1200 ./gradlew app:connectedDebugAndroidTest
rc=$?
if [ "$rc" -ne 124 ]; then
  echo "DIAG: gradle finished on its own with exit code $rc"
  exit "$rc"
fi
echo "DIAG: ===== the tests did not finish in 20 minutes ====="
echo "DIAG: ----- tests started and finished, from logcat (last 40) -----"
adb logcat -d -s TestRunner:I | grep -E "started:|finished:|failed:" | tail -40
echo "DIAG: ----- window focus and top activity -----"
adb shell dumpsys window | grep -E "mCurrentFocus|mFocusedApp" | head -4
adb shell dumpsys activity activities | grep -E "topResumedActivity|ResumedActivity" | head -4
echo "DIAG: ----- processes -----"
adb shell ps -A | grep -E "fluttera11y|uiautomator|talkback" || true
echo "DIAG: ----- thread stacks of the app and test process -----"
adb root || true
sleep 3
pids=$(adb shell pidof $PKG | tr -d '\r' | tr -s ' \n' ' ')
if [ -z "${pids// /}" ]; then
  echo "DIAG: no process named $PKG is running; no thread stacks to take"
fi
for pid in $pids; do
  echo "DIAG: pid $pid"
  adb shell "ls /data/anr 2>/dev/null | wc -l"
  adb shell kill -3 "$pid"
  sleep 8
  newest=$(adb shell "ls -t /data/anr 2>/dev/null | head -1" | tr -d '\r')
  echo "DIAG: newest trace file: $newest"
  if [ -n "$newest" ]; then
    adb shell "cat /data/anr/$newest" | grep -vE "^\s*$" | awk '/^"main"|^"Instr: |^"AndroidJUnitRunner|^"androidx.test|^"UiAutomation|^"Binder:.*" prio/{p=1} /^$/{p=0} p' | head -260
    echo "DIAG: ----- every thread's first line -----"
    adb shell "cat /data/anr/$newest" | grep -E '^"' | head -80
  fi
done
echo "DIAG: ----- last 300 lines of logcat -----"
adb logcat -d -t 300
echo "DIAG: ----- screen -----"
adb exec-out uiautomator dump /dev/tty 2>/dev/null | tr '>' '>\n' | grep -oE 'class="[^"]*"[^>]*content-desc="[^"]*"' | head -40
exit 1
