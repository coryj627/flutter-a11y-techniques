// L3 (tree) and L4 (VoiceOver) for S13 Roles and traits on iOS.
// Spec: docs/specs/S13-roles-and-traits.md.
//
// XCUITest reads an element's type, which follows its traits: a button, a
// switch, or static text. It activates elements by touch, so it cannot tell
// whether an element has an accessibility action (bad-action-hidden).
import XCTest

final class S13RolesAndTraitsUITests: XCTestCase {
  private let app = XCUIApplication()

  override func setUp() {
    continueAfterFailure = true
  }

  /// Cold-starts the app on one example through the `fluttera11y` URL scheme,
  /// trying up to three times (see C01ButtonUITests.open).
  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    let url = URL(string: "fluttera11y:///t/S13/\(slug)")!
    for attempt in 1...3 {
      app.terminate()
      app.open(url)
      if element("s13-\(slug)-count").waitForExistence(timeout: 30) { return }
      print("S13 open \(slug): attempt \(attempt) did not show the example")
    }
    XCTFail("\(slug) did not open after three attempts", file: file, line: line)
  }

  private func element(_ id: String) -> XCUIElement {
    app.descendants(matching: .any)[id]
  }

  private func expectCount(_ slug: String, _ n: Int, file: StaticString = #filePath, line: UInt = #line) {
    let count = element("s13-\(slug)-count")
    let expected = "Activations: \(n)"
    let deadline = Date().addingTimeInterval(5)
    while count.label != expected && Date() < deadline { usleep(100_000) }
    XCTAssertEqual(count.label, expected, slug, file: file, line: line)
  }

  /// The buttons of the example: every button but the app bar's Back.
  private func exampleButtons() -> [XCUIElement] {
    app.buttons.allElementsBoundByIndex.filter { $0.label != "Back" }
  }

  // A checkbox is a switch on iOS: Flutter's engine backs both with the
  // same object (FL-035).
  private let good: [(slug: String, controls: [(id: String, name: String, type: XCUIElement.ElementType)])] = [
    ("good-standard", [("s13-good-standard-save", "Save", .button),
                       ("s13-good-standard-wifi", "Wi-Fi", .switch),
                       ("s13-good-standard-remember", "Remember me", .switch)]),
    ("good-cupertino", [("s13-good-cupertino-save", "Save", .button),
                        ("s13-good-cupertino-wifi", "Wi-Fi", .switch)]),
    ("good-custom-button", [("s13-good-custom-button-scan", "Scan barcode", .button)]),
    ("good-custom-switch", [("s13-good-custom-switch-dark", "Dark mode", .switch)]),
    ("good-selected", [("s13-good-selected-day", "Day", .button),
                       ("s13-good-selected-week", "Week", .button),
                       ("s13-good-selected-month", "Month", .button)]),
  ]

  func testGoodExamplesHaveTheirRoleNameAndState() {
    for example in good {
      open(example.slug)
      var n = 0
      for control in example.controls {
        let e = element(control.id)
        XCTAssertEqual(e.elementType, control.type, control.id)
        XCTAssertEqual(e.label, control.name, control.id)
        XCTAssertTrue(e.isEnabled, "\(control.id) enabled")
        if control.type == .switch { XCTAssertEqual(e.value as? String, "0", control.id) }
        e.tap()
        n += 1
        expectCount(example.slug, n)
        if control.type == .switch { XCTAssertEqual(e.value as? String, "1", control.id) }
      }
      XCTAssertEqual(exampleButtons().count, example.controls.filter { $0.type == .button }.count,
                     "\(example.slug): buttons")
    }
  }

  func testGoodSelectedMarksTheChosenButton() {
    open("good-selected")
    func selected() -> [String] {
      ["day", "week", "month"].filter { element("s13-good-selected-\($0)").isSelected }
    }
    XCTAssertEqual(selected(), ["week"])
    element("s13-good-selected-month").tap()
    expectCount("good-selected", 1)
    XCTAssertEqual(selected(), ["month"])
  }

  // Each bad example is asserted to have its named defect.

  func testBadNoRoleIsNotAButton() {
    open("bad-no-role")
    let e = element("s13-bad-no-role-scan")
    XCTAssertEqual(e.label, "Scan barcode")
    XCTAssertEqual(e.elementType, .staticText)
    XCTAssertEqual(exampleButtons().count, 0)
    e.tap()
    expectCount("bad-no-role", 1)
  }

  func testBadWrongRoleIsAButtonWithNoState() {
    open("bad-wrong-role")
    let e = element("s13-bad-wrong-role-dark")
    for n in 1...2 {
      XCTAssertEqual(e.elementType, .button)
      XCTAssertEqual(e.label, "Dark mode")
      XCTAssertEqual(e.value as? String ?? "", "")
      XCTAssertFalse(e.isSelected)
      e.tap()
      expectCount("bad-wrong-role", n)
    }
    XCTAssertEqual(app.switches.count, 0)
  }

  func testBadRoleOnTextIsAButtonThatDoesNothing() {
    open("bad-role-on-text")
    let e = element("s13-bad-role-on-text-delivery")
    XCTAssertEqual(e.elementType, .button)
    XCTAssertEqual(e.label, "Free delivery")
    e.tap()
    usleep(1_000_000)
    expectCount("bad-role-on-text", 0)
  }

  func testBadRoleOnStandardHasAnUnnamedButtonAsWell() {
    open("bad-role-on-standard")
    let buttons = exampleButtons()
    XCTAssertEqual(buttons.count, 2)
    XCTAssertEqual(buttons.filter { $0.label == "Save" }.count, 1)
    XCTAssertEqual(buttons.filter { $0.label.isEmpty }.count, 1)
    app.buttons["Save"].tap()
    expectCount("bad-role-on-standard", 1)
  }

  func testBadActionHiddenIsAButtonInTheTree() {
    // XCUITest taps by touch, which works here. Whether the element has an
    // accessibility action cannot be read from the tree.
    open("bad-action-hidden")
    let e = element("s13-bad-action-hidden-scan")
    XCTAssertEqual(e.elementType, .button)
    XCTAssertEqual(e.label, "Scan barcode")
    XCTAssertTrue(e.isEnabled)
    e.tap()
    expectCount("bad-action-hidden", 1)
  }

  func testBadSwitchNotEnabledIsDisabledInTheTree() {
    open("bad-switch-not-enabled")
    let e = element("s13-bad-switch-not-enabled-dark")
    XCTAssertEqual(e.elementType, .switch)
    XCTAssertEqual(e.label, "Dark mode")
    // Flutter 3.47.5: with no enabled flag the switch is not enabled for
    // iOS, though it works (FL-033).
    XCTAssertFalse(e.isEnabled)
    XCTAssertEqual(e.value as? String, "0")
    e.tap()
    expectCount("bad-switch-not-enabled", 1)
    XCTAssertEqual(e.value as? String, "1")
  }

  // L4. Everything VoiceOver says between the "Example" heading and the
  // activation count, which is the last element of every example. The
  // helpers are S04's: a stop with no speech is recorded only when a move
  // back and forward has shown where the cursor is.
  private let speech: [(slug: String, content: [String])] = [
    ("good-standard", ["Save Button",
                       "Wi-Fi Switch button off Double tap to toggle setting.",
                       // A checkbox is read as a switch (FL-035).
                       "Remember me Switch button off Double tap to toggle setting."]),
    ("good-cupertino", ["Save Button", "Wi-Fi Switch button off Double tap to toggle setting."]),
    ("good-custom-button", ["Scan barcode Button"]),
    ("good-custom-switch", ["Dark mode Switch button off Double tap to toggle setting."]),
    ("good-selected", ["Day Button", "selected Week Button", "Month Button"]),
    // Bad examples: the defect must be audible.
    ("bad-no-role", ["Scan barcode"]),
    ("bad-wrong-role", ["Dark mode Button"]),
    ("bad-role-on-text", ["Free delivery Button"]),
    // VoiceOver stops once: the unnamed button around the real one is in
    // the tree (see the tree test) and is not a stop.
    ("bad-role-on-standard", ["Save Button"]),
    // Read the same as the good custom button. VoiceOver's own double tap
    // could not be sent from the test, so whether it activates the control
    // is not known.
    ("bad-action-hidden", ["Scan barcode Button"]),
    ("bad-switch-not-enabled", ["Dark mode dimmed Switch button off"]),
  ]

  /// One utterance with every run of whitespace made one space.
  private static func normalized(_ utterance: String) -> String {
    utterance.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
  }

  func testVoiceOverSpeech() throws {
    // XCUIVoiceOverService is in the iOS 27 SDK (Xcode 27, Swift 6.4). With an
    // older Xcode the symbol does not exist, so an availability check alone
    // would not compile; the body is compiled only where the SDK has it.
    #if compiler(>=6.4)
    guard #available(iOS 27.0, *) else { throw XCTSkip("XCUIVoiceOverService needs iOS 27") }
    let voiceOver = XCUIDevice.shared.voiceOverService
    for example in speech {
      open(example.slug)
      try voiceOver.enable()
      var voiceOverOn = true
      defer { if voiceOverOn { try? voiceOver.disable() } }
      var spoken: [String] = []
      // Swipe right until the activation count, the last element, is read.
      for _ in 0..<20 {
        do {
          spoken.append(Self.normalized(try voiceOver.moveForward().utterance))
        } catch let error as NSError where S04FunctionalImagesUITests.isNoSpeech(error) {
          let back = Self.normalized(try voiceOver.moveBackward().utterance)
          var again: String? = nil
          do {
            again = Self.normalized(try voiceOver.moveForward().utterance)
          } catch let error as NSError where S04FunctionalImagesUITests.isNoSpeech(error) {}
          spoken.append(S04FunctionalImagesUITests.afterNoSpeech(
            previous: spoken.last, back: back, again: again))
        }
        if spoken.last!.hasPrefix("Activations:") { break }
      }
      try voiceOver.disable()
      voiceOverOn = false
      let content = S04FunctionalImagesUITests.exampleContent(spoken)
      print("S13VO \(example.slug) | \((content ?? spoken).joined(separator: " / "))")
      XCTAssertNotNil(content, "\(example.slug): the walk did not run from the heading to the count: \(spoken)")
      XCTAssertEqual(content, example.content, example.slug)
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}
