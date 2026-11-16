# Wave 0: preparing for parallel work

Run on 2026-11-16 and 2026-11-17. It built no techniques. It changed how a
technique is added and how the devices are shared, so that several
techniques can be built at once. [Working in parallel](../parallel-work.md)
is the result.

## What changed

- Each technique's evidence tool data is in a file of its own in
  `tool/techniques/`; the web job selects tree specs by pattern;
  `RunnerUITests` picks its files up from the folder;
  `all_techniques.dart` and the README lists are generated; the limitations
  log has a range of ids, and a place, for each wave.
- The helpers every test class copied are shared, one set per layer:
  `TechniqueTest.kt`, `TechniqueUITest.swift`, `web_tests/support/techniques.js`,
  and `test/support/examples.dart`.
- One device lock, `tool/evidence.py` for a technique's whole device and
  screen reader run, and `tool/with_devices.py` for anything else that
  touches a device.

## Test-tool findings

- `python3 -m http.server` could take half a minute or more to start
  listening on this Mac, and once seemed to hang after a reboot. It binds
  the port, then looks up the host's name (`socket.getfqdn()`), and listens
  only after that; the lookup took 35 seconds when measured. The Playwright
  configs now start `web_tests/support/static_server.js`, which looks
  nothing up.
- The Playwright configs used fixed ports and reused a server that was
  already running, so a run in one worktree could have tested another
  worktree's build. Each worktree now has its own ports and never reuses a
  server.
- A Python file rewritten within a second, at the same size, is loaded from
  stale bytecode by the import system. The registration loader compiles the
  source each time.
