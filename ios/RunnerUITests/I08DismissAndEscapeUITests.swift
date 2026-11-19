// L3 (tree and keyboard) and L4 (VoiceOver) for I08 Dismiss and escape on
// iOS.
// Spec: docs/specs/I08-dismiss-and-escape.md.
//
// The keyboard is driven with XCUIElement.typeKey; Tab and Space reach
// Flutter, and Enter is typed as "\n" (docs/evidence/probes/i01/README.md).
// The Escape key does not: in the I08 probe no Escape typed from XCUITest
// reached Flutter, with VoiceOver on or off, while Tab in the same launch
// did. Command+period, iOS's own key for cancel, arrives in Flutter as
// Escape and closed what Escape closes (docs/evidence/probes/i08/
// ios_round3.txt), so Escape is sent as Command+period here. Whether a
// hardware keyboard's own Escape key reaches the app is not known.
//
// XCUITest does not see where Flutter's keyboard focus is, so every stop
// is named by what Space does there: on a switch it turns that switch (its
// value goes from "1" to "0" or back), and on Map layers it shows the
// layers.
//
// iOS has no Back key, and VoiceOver's escape gesture (a two-finger scrub)
// cannot be made from XCUITest (docs/evidence/probes/i08/README.md), so
// what the gesture does is left to the widget tests, from the source.
import XCTest

final class I08DismissAndEscapeUITests: XCTestCase, CountedTechniqueUITest {
  static let technique = "I08"
  static let countLabel = "Closed"
  let app = XCUIApplication()

  override func setUp() {
    continueAfterFailure = false
  }

  private static let good = ["good-material", "good-cupertino", "good-widgets"]
  private static let all = good + ["bad-not-dismissible", "bad-no-escape", "bad-back-leaves"]
  /// The examples whose layers are a route of their own: Enter leaves
  /// focus on the route's scope, and the next Tab is the first switch.
  private static let routes = ["good-material", "good-cupertino", "bad-not-dismissible"]
  /// What VoiceOver reads for each example's barrier; bad-not-dismissible's
  /// is no element at all.
  private static let barrier = [
    "good-material": "Scrim", "good-cupertino": "Dismiss", "good-widgets": "Close map layers",
    "bad-no-escape": "Close map layers", "bad-back-leaves": "Close map layers",
  ]

  private static let enter = "\n"
  private static let space = XCUIKeyboardKey.space.rawValue
  private static let tab = XCUIKeyboardKey.tab.rawValue
  private static let escapeCloses = good + ["bad-back-leaves"]

  /// Escape, as Command+period (see the top of the file).
  private func escape() {
    app.typeKey(".", modifierFlags: .command)
    usleep(700_000)
  }

  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    open(slug, waitingFor: countElement(slug), file: file, line: line)
  }

  private func control(_ slug: String, _ part: String) -> XCUIElement { element("i08-\(slug)-\(part)") }

  private func press(_ key: String, _ flags: XCUIElement.KeyModifierFlags = [], times: Int = 1) {
    for _ in 0..<times {
      app.typeKey(key, modifierFlags: flags)
      usleep(700_000)
    }
  }

  private func value(_ e: XCUIElement) -> String { e.value as? String ?? "" }

  /// Both switches are on the screen.
  private func shown(_ slug: String) -> Bool {
    control(slug, "contours").exists && control(slug, "campsites").exists
  }

  /// Waits up to five seconds for the layers to be shown, or gone.
  private func expectShown(
    _ slug: String, _ expected: Bool, _ context: String, file: StaticString = #filePath, line: UInt = #line
  ) {
    let deadline = Date().addingTimeInterval(5)
    while shown(slug) != expected && Date() < deadline { usleep(200_000) }
    XCTAssertEqual(shown(slug), expected, "\(context): the layers \(expected ? "are not shown" : "are still shown")",
                   file: file, line: line)
  }

  /// Names the stop by Space: which switch it turns. Fails unless it turns
  /// exactly one; the layers stay shown.
  private func stopBySpace(_ slug: String, file: StaticString = #filePath, line: UInt = #line) -> String {
    let before = ["contours": value(control(slug, "contours")), "campsites": value(control(slug, "campsites"))]
    press(Self.space)
    let deadline = Date().addingTimeInterval(3)
    var changed: [String] = []
    repeat {
      changed = before.keys.filter { value(control(slug, $0)) != before[$0] }.sorted()
      if !changed.isEmpty { break }
      usleep(200_000)
    } while Date() < deadline
    XCTAssertEqual(changed.count, 1, "\(slug): Space turned \(changed)", file: file, line: line)
    return changed.first ?? "none"
  }

  /// Opens `slug`, tabs to Map layers (Back first), presses Enter, and
  /// tabs on to the first switch where Enter left focus on a route's scope.
  private func showByKeyboard(_ slug: String) {
    open(slug)
    tabToLayers(slug)
  }

  /// From an example's screen as it opens: Tab to Map layers (Back first),
  /// Enter, and Tab on to the first switch where Enter left focus on a
  /// route's scope.
  private func tabToLayers(_ slug: String) {
    press(Self.tab, times: 2)
    press(Self.enter)
    expectShown(slug, true, "\(slug): Enter on Map layers")
    if Self.routes.contains(slug) { press(Self.tab) }
  }

  /// Before Escape is sent: keyboard focus must be on Contour lines, named
  /// by Space twice (it turns Contour lines, then turns it back). On CI's
  /// simulator, Escape sent at once after the layers appeared, with no key
  /// between, did not close them (run 44502222902); this waits for focus
  /// to be where the key is meant for.
  private func expectFocusOnContours(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    for _ in 0..<2 {
      XCTAssertEqual(stopBySpace(slug, file: file, line: line), "contours",
                     "\(slug): the stop before Escape", file: file, line: line)
    }
  }

  /// Expects the layers closed on `slug`'s own screen: both switches gone,
  /// its count present and at `closed`, and keyboard focus back on Map
  /// layers, from which Space then shows the layers again. Waits up to ten
  /// seconds for the first two.
  private func expectClosed(
    _ slug: String, _ closed: Int, _ context: String, file: StaticString = #filePath, line: UInt = #line
  ) {
    let count = countElement(slug)
    let expected = "\(Self.countLabel): \(closed)"
    func done() -> Bool {
      !control(slug, "contours").exists && !control(slug, "campsites").exists
        && count.exists && count.label == expected
    }
    let deadline = Date().addingTimeInterval(10)
    while !done() && Date() < deadline { usleep(200_000) }
    XCTAssertFalse(control(slug, "contours").exists, "\(context): Contour lines is still there", file: file, line: line)
    XCTAssertFalse(control(slug, "campsites").exists, "\(context): Campsites is still there", file: file, line: line)
    XCTAssertTrue(count.exists, "\(context): \(slug)'s count is not on the screen", file: file, line: line)
    XCTAssertEqual(count.label, expected, context, file: file, line: line)
    press(Self.space)
    expectShown(slug, true, "\(context): Space after it, on Map layers", file: file, line: line)
  }

  func testEveryExampleHasItsButtonAndSwitches() {
    for slug in Self.all {
      open(slug)
      XCTAssertEqual(control(slug, "open").label, "Map layers", slug)
      XCTAssertEqual(control(slug, "open").elementType, .button, slug)
      expectCount(slug, 0)
      control(slug, "open").tap()
      expectShown(slug, true, "\(slug): a tap on Map layers")
      for (part, name, on) in [("contours", "Contour lines", "1"), ("campsites", "Campsites", "0")] {
        XCTAssertEqual(control(slug, part).label, name, "\(slug) \(part)")
        XCTAssertEqual(control(slug, part).elementType, .switch, "\(slug) \(part)")
        XCTAssertEqual(value(control(slug, part)), on, "\(slug) \(part)")
      }
    }
  }

  // The first stop is the first switch, and Tab and Shift+Tab go round the
  // two, each stop named by what Space turns.
  func testTabAndShiftTabGoRoundTheSwitches() {
    for slug in Self.all {
      showByKeyboard(slug)
      var stops = [stopBySpace(slug)]
      for _ in 0..<3 {
        press(Self.tab)
        stops.append(stopBySpace(slug))
      }
      for _ in 0..<3 {
        press(Self.tab, .shift)
        stops.append(stopBySpace(slug))
      }
      XCTAssertEqual(stops, ["contours", "campsites", "contours", "campsites", "contours", "campsites", "contours"], slug)
      expectShown(slug, true, slug)
    }
  }

  func testEscapeClosesTheLayers() {
    for slug in Self.escapeCloses {
      showByKeyboard(slug)
      expectFocusOnContours(slug)
      escape()
      expectClosed(slug, 1, "\(slug): Escape")
    }
  }

  /// The good example each bad one is made from, for the positive control.
  private static let goodOf = ["bad-not-dismissible": "good-material", "bad-no-escape": "good-widgets"]

  // The defects. Escape alone, on each switch; a second later the layers
  // are still shown, and Space turns the same switch, so focus has not
  // moved and keys arrive. Then, in the same launch, the positive control
  // for Escape itself: the good example the bad one is made from is opened
  // over it by its link, and the same Escape closes its layers. Written to
  // fail when Escape closes the bad example's layers.
  func testEscapeDoesNothingInTheBadExamples() {
    for slug in ["bad-not-dismissible", "bad-no-escape"] {
      showByKeyboard(slug)
      expectFocusOnContours(slug)
      for part in ["contours", "campsites"] {
        if part == "campsites" { press(Self.tab) }
        escape()
        sleep(1)
        expectShown(slug, true, "\(slug): Escape on \(part)")
        XCTAssertEqual(stopBySpace(slug), part, "\(slug): the stop after Escape")
      }
      // The good example, opened by its link in the app that is running,
      // which pushes its screen over this one: the same launch.
      let good = Self.goodOf[slug]!
      // 30 seconds, as for every other screen: on the hosted iOS 26.5
      // runner a screen opened by its link took up to 30 seconds to appear.
      app.open(URL(string: "fluttera11y:///t/I08/\(good)")!)
      XCTAssertTrue(countElement(good).waitForExistence(timeout: 30), "\(good) did not open")
      tabToLayers(good)
      expectFocusOnContours(good)
      escape()
      expectClosed(good, 1, "\(good): Escape, the positive control in the launch of \(slug)")
    }
  }

  // bad-no-escape: Tab and Shift+Tab never leave the layers; six of
  // each, every stop named. (Escape is not sent: see the top of the file.)
  func testBadNoEscapeNoKeyLeavesTheLayers() {
    let slug = "bad-no-escape"
    showByKeyboard(slug)
    var stops: [String] = []
    for flags in [XCUIElement.KeyModifierFlags(), .shift] {
      for _ in 0..<6 {
        press(Self.tab, flags)
        stops.append(stopBySpace(slug))
      }
    }
    XCTAssertEqual(Set(stops), ["contours", "campsites"], slug)
    expectShown(slug, true, slug)
  }

  // L4. With VoiceOver on, tap() moves its cursor and doubleTap()
  // activates. After the double tap on Map layers the test reads what
  // VoiceOver said, then moves forward from where VoiceOver went by itself
  // until it reads the barrier, at most eight moves.
  func testVoiceOverSpeech() throws {
    #if compiler(>=6.4)
    guard #available(iOS 27.0, *) else { throw XCTSkip("XCUIVoiceOverService needs iOS 27") }
    let voiceOver = XCUIDevice.shared.voiceOverService
    for slug in Self.all {
      open(slug)
      try voiceOver.enable()
      defer { try? voiceOver.disable() }
      sleep(2)
      let button = control(slug, "open")
      button.tap()
      sleep(2)
      let onButton = VoiceOverWalk.normalized((try? voiceOver.currentSpeech().utterance) ?? VoiceOverWalk.silent)
      button.doubleTap()
      sleep(3)
      let opened = VoiceOverWalk.normalized((try? voiceOver.currentSpeech().utterance) ?? VoiceOverWalk.silent)
      var walk: [String] = []
      let end = Self.barrier[slug]
      for _ in 0..<8 {
        let next = VoiceOverWalk.normalized((try? voiceOver.moveForward().utterance) ?? VoiceOverWalk.silent)
        if walk.last == next { break }
        walk.append(next)
        if let end, next.hasPrefix(end) { break }
      }
      try voiceOver.disable()
      print("I08VO \(slug) | button: \(onButton) / opened: \(opened) / then: \(walk.joined(separator: " / "))")
      XCTAssertEqual(onButton, "Map layers Button", slug)
      let heard = [opened] + walk
      XCTAssertTrue(heard.contains { $0.hasPrefix("Contour lines") && $0.contains("Switch button") }, "\(slug): \(heard)")
      XCTAssertTrue(heard.contains { $0.hasPrefix("Campsites") && $0.contains("Switch button") }, "\(slug): \(heard)")
      if let end {
        XCTAssertTrue(heard.contains { $0.hasPrefix(end) }, "\(slug): the barrier was not read: \(heard)")
      } else {
        // The defect: the sheet's barrier is not an element.
        XCTAssertFalse(heard.contains { $0.hasPrefix("Scrim") || $0.hasPrefix("Dismiss") }, "\(slug): \(heard)")
      }
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}
