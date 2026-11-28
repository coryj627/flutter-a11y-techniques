// V12's handling of VoiceOver's on/off state in its iOS tests
// (V12AccessibilitySettingsUITests.swift). A test reads the state before
// it changes anything and puts that state back afterwards, checked; a
// failed change or a failed restore is reported, never swallowed. Kept
// apart from the service behind a protocol, so that made-up doubles can
// drive every path, including a failed walk and a failed cleanup, which
// the real service cannot be made to give on purpose.
import XCTest

/// What V12's tests use of VoiceOver's on/off switch.
protocol VoiceOverSwitch: AnyObject {
  var isEnabled: Bool { get }
  func enable() throws
  func disable() throws
}

#if compiler(>=6.4)
@available(iOS 27.0, *)
extension XCUIVoiceOverService: VoiceOverSwitch {}
#endif

/// A change of VoiceOver's state that did not take, or a restore that
/// failed.
struct VoiceOverStateError: Error, CustomStringConvertible, Equatable {
  let description: String
}

enum VoiceOverState {
  /// How long a change is waited for, in seconds.
  static var timeout: Double = 10

  /// Turns VoiceOver on or off and waits until `isEnabled` says so; throws
  /// if the call fails or the state does not follow.
  static func set(_ voiceOver: VoiceOverSwitch, on: Bool) throws {
    if voiceOver.isEnabled == on { return }
    do {
      if on { try voiceOver.enable() } else { try voiceOver.disable() }
    } catch {
      throw VoiceOverStateError(description: "VoiceOver could not be turned \(on ? "on" : "off"): \(error)")
    }
    let deadline = Date().addingTimeInterval(timeout)
    while voiceOver.isEnabled != on && Date() < deadline { usleep(100_000) }
    if voiceOver.isEnabled != on {
      throw VoiceOverStateError(description: "VoiceOver was told to turn \(on ? "on" : "off") and is still \(on ? "off" : "on")")
    }
  }

  /// Puts VoiceOver back to `original` and checks it; the problem, or nil.
  static func restore(_ voiceOver: VoiceOverSwitch, to original: Bool) -> String? {
    do {
      try set(voiceOver, on: original)
      return nil
    } catch {
      return "VoiceOver not put back \(original ? "on" : "off"): \(error)"
    }
  }

  /// Runs `body` with VoiceOver on, and puts back the state it found,
  /// checked, whether `body` returned or threw. A failed restore is thrown
  /// (with `body`'s own error, when it threw one too).
  static func withOn<T>(_ voiceOver: VoiceOverSwitch, _ body: () throws -> T) throws -> T {
    let original = voiceOver.isEnabled
    let result: Swift.Result<T, Error>
    do {
      try set(voiceOver, on: true)
      result = .success(try body())
    } catch {
      result = .failure(error)
    }
    if let problem = restore(voiceOver, to: original) {
      if case .failure(let error) = result {
        throw VoiceOverStateError(description: "\(problem); and before it: \(error)")
      }
      throw VoiceOverStateError(description: problem)
    }
    return try result.get()
  }
}

extension XCTestCase {
  /// Reads VoiceOver's state, registers at once a teardown block that puts
  /// it back and fails the test if that does not take, and then sets the
  /// off baseline, checked. Returns the state found.
  @discardableResult
  func voiceOverOffBaseline(_ voiceOver: VoiceOverSwitch, file: StaticString = #filePath, line: UInt = #line) throws -> Bool {
    let original = voiceOver.isEnabled
    print("V12 VoiceOver was \(original ? "on" : "off") before the test")
    addTeardownBlock {
      if let problem = VoiceOverState.restore(voiceOver, to: original) {
        XCTFail(problem, file: file, line: line)
      } else {
        print("V12 VoiceOver put back \(original ? "on" : "off")")
      }
    }
    try VoiceOverState.set(voiceOver, on: false)
    return original
  }
}

/// A made-up VoiceOver for the tests of VoiceOverState: never the real
/// service. Each failure is set by the test.
final class FakeVoiceOver: VoiceOverSwitch {
  var isEnabled: Bool
  /// enable() throws.
  var enableThrows = false
  /// disable() throws.
  var disableThrows = false
  /// disable() returns but VoiceOver stays on.
  var disableIgnored = false
  /// Every call, in order: "enable", "disable".
  var calls: [String] = []

  init(on: Bool) { isEnabled = on }

  struct Failure: Error {}

  func enable() throws {
    calls.append("enable")
    if enableThrows { throw Failure() }
    isEnabled = true
  }

  func disable() throws {
    calls.append("disable")
    if disableThrows { throw Failure() }
    if !disableIgnored { isEnabled = false }
  }
}

/// The tests of VoiceOverState, on doubles (FakeVoiceOver), with no
/// simulator state touched. They are in the technique's own test class, so
/// that the iOS layer, which runs that class, runs them.
struct WalkFailed: Error {}

extension V12AccessibilitySettingsUITests {
  /// Runs `body` with a short wait for a change: a double changes at once,
  /// or never.
  func withShortWait(_ body: () throws -> Void) rethrows {
    VoiceOverState.timeout = 0.3
    defer { VoiceOverState.timeout = 10 }
    try body()
  }

  func testVoiceOverStateAWalkFromOffTurnsItOnAndPutsItBackOff() throws {
    try withShortWait {
      let vo = FakeVoiceOver(on: false)
      let seen = try VoiceOverState.withOn(vo) { vo.isEnabled }
      XCTAssertTrue(seen, "on during the walk")
      XCTAssertFalse(vo.isEnabled, "put back off")
      XCTAssertEqual(vo.calls, ["enable", "disable"])
    }
  }

  func testVoiceOverStateAWalkFromOnLeavesItOn() throws {
    try withShortWait {
      let vo = FakeVoiceOver(on: true)
      let seen = try VoiceOverState.withOn(vo) { vo.isEnabled }
      XCTAssertTrue(seen)
      XCTAssertTrue(vo.isEnabled, "found on, left on")
      XCTAssertEqual(vo.calls, [], "nothing to change either way")
    }
  }

  func testVoiceOverStateAFailedWalkStillPutsItBackAndRethrows() throws {
    try withShortWait {
      let vo = FakeVoiceOver(on: false)
      XCTAssertThrowsError(try VoiceOverState.withOn(vo) { () throws -> Int in throw WalkFailed() }) { error in
        XCTAssertTrue(error is WalkFailed, "the walk's own error: \(error)")
      }
      XCTAssertFalse(vo.isEnabled, "put back off after the failed walk")
    }
  }

  func testVoiceOverStateAFailedCleanupFailsAWalkThatPassed() throws {
    try withShortWait {
      let vo = FakeVoiceOver(on: false)
      vo.disableThrows = true
      XCTAssertThrowsError(try VoiceOverState.withOn(vo) { 1 }) { error in
        XCTAssertTrue("\(error)".contains("not put back off"), "\(error)")
      }
      XCTAssertTrue(vo.isEnabled, "left on, and reported")
    }
  }

  func testVoiceOverStateACleanupThatDoesNotTakeIsReported() throws {
    try withShortWait {
      let vo = FakeVoiceOver(on: false)
      vo.disableIgnored = true
      XCTAssertThrowsError(try VoiceOverState.withOn(vo) { 1 }) { error in
        XCTAssertTrue("\(error)".contains("is still on"), "\(error)")
      }
    }
  }

  func testVoiceOverStateAFailedWalkAndAFailedCleanupAreBothReported() throws {
    try withShortWait {
      let vo = FakeVoiceOver(on: false)
      vo.disableThrows = true
      XCTAssertThrowsError(try VoiceOverState.withOn(vo) { () throws -> Int in throw WalkFailed() }) { error in
        let text = "\(error)"
        XCTAssertTrue(text.contains("not put back off") && text.contains("WalkFailed"), text)
      }
    }
  }

  func testVoiceOverStateOneThatWillNotTurnOnFailsTheWalkAndChangesNothing() throws {
    try withShortWait {
      let vo = FakeVoiceOver(on: false)
      vo.enableThrows = true
      var ran = false
      XCTAssertThrowsError(try VoiceOverState.withOn(vo) { ran = true })
      XCTAssertFalse(ran, "the walk is not made")
      XCTAssertFalse(vo.isEnabled)
    }
  }

  func testVoiceOverStateTheRestoreReportsWhatItCouldNotDo() {
    withShortWait {
      let on = FakeVoiceOver(on: true)
      XCTAssertNil(VoiceOverState.restore(on, to: true))
      let off = FakeVoiceOver(on: true)
      XCTAssertNil(VoiceOverState.restore(off, to: false))
      XCTAssertFalse(off.isEnabled)
      let stuck = FakeVoiceOver(on: true)
      stuck.disableThrows = true
      XCTAssertNotNil(VoiceOverState.restore(stuck, to: false))
      let wontStart = FakeVoiceOver(on: false)
      wontStart.enableThrows = true
      XCTAssertNotNil(VoiceOverState.restore(wontStart, to: true))
    }
  }

  func testVoiceOverStateTheOffBaselineFromOnAndFromOff() throws {
    try withShortWait {
      for start in [true, false] {
        let vo = FakeVoiceOver(on: start)
        try VoiceOverState.set(vo, on: false)
        XCTAssertFalse(vo.isEnabled, "baseline off, from \(start ? "on" : "off")")
      }
      let stuck = FakeVoiceOver(on: true)
      stuck.disableIgnored = true
      XCTAssertThrowsError(try VoiceOverState.set(stuck, on: false), "a baseline that does not take fails")
    }
  }
}
