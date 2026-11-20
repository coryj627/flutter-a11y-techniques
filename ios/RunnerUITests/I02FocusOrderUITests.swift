// L3 (tree and keyboard) and L4 (VoiceOver) for I02 Keyboard focus order
// on iOS.
// Spec: docs/specs/I02-focus-order.md.
//
// The keyboard is driven with XCUIElement.typeKey, which the simulator
// delivers as a hardware keyboard's keys: Tab, Shift+Tab, Space, and the
// arrows reach Flutter (docs/evidence/probes/i01/README.md and
// docs/evidence/probes/i02/README.md). XCUITest does not see where
// Flutter's keyboard focus is (hasFocus is false on every element), so
// every stop is named by what Space does there: it changes the box that
// has focus, which the test reads from that box's value ("0" or "1"),
// presses Save plan, which the count shows, or, on Back, leaves the
// screen. After each Space the test checks every box, so a stop is named
// only when exactly the expected box changed.
import XCTest

final class I02FocusOrderUITests: XCTestCase, CountedTechniqueUITest {
  static let technique = "I02"
  static let countLabel = "Saves"
  let app = XCUIApplication()

  override func setUp() {
    continueAfterFailure = false
  }

  private static let good = ["good-material", "good-cupertino", "good-ordered"]
  private static let all = good + ["bad-columns-mixed", "bad-order-missing"]
  private static let boxes = ["map", "water", "aid", "weather", "closures"]
  private static let names = [
    "map": "Map", "water": "Water", "aid": "First aid", "weather": "Weather",
    "closures": "Closures", "save": "Save plan",
  ]
  private static let columnOrder = ["map", "water", "aid", "weather", "closures", "save"]
  /// Tab, after Back, in each example. The same orders as in the widget tests.
  private static let tabOrder = [
    "good-material": columnOrder,
    "good-cupertino": columnOrder,
    "good-ordered": columnOrder,
    "bad-columns-mixed": ["map", "weather", "water", "closures", "aid", "save"],
    "bad-order-missing": ["map", "water", "weather", "closures", "save", "aid"],
  ]

  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    open(slug, waitingFor: countElement(slug), file: file, line: line)
  }

  private func control(_ slug: String, _ c: String) -> XCUIElement { element("i02-\(slug)-\(c)") }

  private func value(_ slug: String, _ box: String) -> String { control(slug, box).value as? String ?? "" }

  private static let space = XCUIKeyboardKey.space.rawValue
  private static let tab = XCUIKeyboardKey.tab.rawValue

  private func press(_ key: String, _ flags: XCUIElement.KeyModifierFlags = []) {
    app.typeKey(key, modifierFlags: flags)
    usleep(700_000)
  }

  /// Expects exactly the boxes in `on` to be checked.
  private func expectChecked(
    _ slug: String, _ on: Set<String>, _ context: String,
    file: StaticString = #filePath, line: UInt = #line
  ) {
    let deadline = Date().addingTimeInterval(3)
    func matches() -> Bool { Self.boxes.allSatisfy { (value(slug, $0) == "1") == on.contains($0) } }
    while !matches() && Date() < deadline { usleep(100_000) }
    let seen = Self.boxes.filter { value(slug, $0) == "1" }
    XCTAssertTrue(matches(), "\(slug) \(context): checked \(seen), expected \(on.sorted())", file: file, line: line)
  }

  /// Presses Space where focus is and expects it to be on `stop`: that box
  /// changes from `on` and no other does, or the count goes to `saves`.
  private func expectStop(
    _ slug: String, _ stop: String, on: inout Set<String>, saves: inout Int,
    file: StaticString = #filePath, line: UInt = #line
  ) {
    press(Self.space)
    if stop == "save" {
      saves += 1
      expectCount(slug, saves, file: file, line: line)
      expectChecked(slug, on, "after Space on Save plan", file: file, line: line)
    } else {
      if on.contains(stop) { on.remove(stop) } else { on.insert(stop) }
      expectChecked(slug, on, "after Space on \(stop)", file: file, line: line)
    }
  }

  /// Expects focus to be on Back: Space there goes back, so the example
  /// leaves the screen.
  private func expectBack(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    press(Self.space)
    let gone = NSPredicate(format: "exists == false")
    let expectation = XCTNSPredicateExpectation(predicate: gone, object: countElement(slug))
    XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: 5), .completed,
                   "\(slug): Space did not leave the screen, so focus was not on Back", file: file, line: line)
  }

  func testEveryControlHasItsNameAndType() {
    for slug in Self.all {
      open(slug)
      for box in Self.boxes {
        let element = control(slug, box)
        XCTAssertEqual(element.label, Self.names[box], "\(slug) \(box)")
        // A checkbox is a switch to XCUITest and VoiceOver (FL-035).
        XCTAssertEqual(element.elementType, .switch, "\(slug) \(box)")
        XCTAssertEqual(value(slug, box), "0", "\(slug) \(box)")
      }
      XCTAssertEqual(control(slug, "save").label, "Save plan", slug)
      XCTAssertEqual(control(slug, "save").elementType, .button, slug)
    }
  }

  // The example screen has one thing the keyboard can reach before the
  // example: Back. Every test that starts from a fresh screen relies on
  // the first Tab putting focus there; this one checks it for every
  // example, since Space on Back is the only way to see it and leaves the
  // screen.
  func testTheFirstTabGoesToBack() {
    for slug in Self.all {
      open(slug)
      press(Self.tab)
      expectBack(slug)
    }
  }

  // The check above can fail: with focus one stop further on, on Map,
  // Space checks Map and the screen stays, and expectBack reports it.
  func testTheBackCheckFailsWhenFocusIsNotOnBack() {
    // An expected failure must not end the test.
    continueAfterFailure = true
    let slug = "good-material"
    open(slug)
    press(Self.tab)
    press(Self.tab)
    XCTExpectFailure("focus is on Map, not on Back") {
      expectBack(slug)
    }
    expectChecked(slug, ["map"], "after Space with focus on Map")
  }

  func testTabGoesInTheExamplesOrderThenRoundToBack() {
    for slug in Self.all {
      open(slug)
      press(Self.tab)  // Back, as testTheFirstTabGoesToBack shows
      var on = Set<String>()
      var saves = 0
      for stop in Self.tabOrder[slug]! {
        press(Self.tab)
        expectStop(slug, stop, on: &on, saves: &saves)
      }
      press(Self.tab)
      expectBack(slug)
    }
  }

  /// On CI's simulator (iOS 26.5) this test failed in some runs and passed in
  /// others: where it failed, the example's Map checkbox was no longer found
  /// (docs/evidence/probes/i02/ci_ios_26_5_shift_tab.txt; spec, section 7).
  /// I04 and I08 skip their modifier-key tests there too.
  func testShiftTabGoesTheSameWayBackwards() throws {
    if ProcessInfo.processInfo.operatingSystemVersion.majorVersion < 27 {
      throw XCTSkip("Shift+Tab did not arrive with its modifier every time before iOS 27")
    }
    for slug in Self.all {
      let order = Self.tabOrder[slug]!
      open(slug)
      // Forward to the last stop, checking each box on the way.
      press(Self.tab)  // Back
      var on = Set<String>()
      var saves = 0
      for stop in order {
        press(Self.tab)
        expectStop(slug, stop, on: &on, saves: &saves)
      }
      // Then backwards: Space at each stop unchecks the box that has focus.
      for stop in order.reversed().dropFirst() {
        press(Self.tab, .shift)
        expectStop(slug, stop, on: &on, saves: &saves)
      }
      press(Self.tab, .shift)
      expectBack(slug)
    }
  }

  func testEachArrowMovesToTheControlOnThatSide() {
    // From, arrow, to. The arrows move by position.
    let moves: [(String, XCUIKeyboardKey, String)] = [
      ("map", .downArrow, "water"), ("map", .rightArrow, "weather"),
      ("weather", .downArrow, "closures"), ("aid", .downArrow, "save"),
    ]
    for slug in Self.all {
      let order = Self.tabOrder[slug]!
      for (from, arrow, to) in moves {
        open(slug)
        press(Self.tab)  // Back
        // Tab to `from` without pressing Space on the way.
        for _ in 0...order.firstIndex(of: from)! { press(Self.tab) }
        press(arrow.rawValue)
        var on = Set<String>()
        var saves = 0
        expectStop(slug, to, on: &on, saves: &saves)
      }
    }
  }

  // L4. Everything VoiceOver says between the "Example" heading and the
  // count, swiping forward: the order a screen reader follows, which is
  // one column, then the other, in every example. The keyboard's order is
  // not heard: bad-columns-mixed and bad-order-missing read like the good
  // examples. A checkbox is read as a switch (FL-035).
  private static func box(_ name: String) -> String { "\(name) Switch button off Double tap to toggle setting." }
  private static let read = [
    "Pack", box("Map"), box("Water"), box("First aid"),
    "Send me", box("Weather"), box("Closures"), "Save plan Button",
  ]

  func testVoiceOverSpeech() throws {
    #if compiler(>=6.4)
    guard #available(iOS 27.0, *) else { throw XCTSkip("XCUIVoiceOverService needs iOS 27") }
    let voiceOver = XCUIDevice.shared.voiceOverService
    for slug in Self.all {
      open(slug)
      let spoken = try VoiceOverWalk.forward(voiceOver, toUtteranceStartingWith: "Saves:")
      let content = Self.exampleContent(spoken)
      print("I02VO \(slug) | \((content ?? spoken).joined(separator: " / "))")
      XCTAssertNotNil(content, "\(slug): the walk did not run from the heading to the count: \(spoken)")
      XCTAssertEqual(content, Self.read, slug)
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}
