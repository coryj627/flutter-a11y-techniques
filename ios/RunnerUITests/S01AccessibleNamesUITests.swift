// L3 (tree) and L4 (VoiceOver) for S01 Accessible names on iOS.
// Spec: docs/specs/S01-accessible-names.md.
//
// iOS has no checkbox element type: Flutter exposes a checkbox and a switch
// alike as a switch, with the value "0" or "1".
import XCTest

final class S01AccessibleNamesUITests: XCTestCase {
  private let app = XCUIApplication()

  override func setUp() {
    continueAfterFailure = true
  }

  private func element(_ id: String) -> XCUIElement {
    app.descendants(matching: .any)[id]
  }

  private func elements(labelled label: String) -> XCUIElementQuery {
    app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label))
  }

  /// Cold-starts the app on one example through the `fluttera11y` URL scheme,
  /// waiting for `firstId`, a control only that example has. Tried up to
  /// three times (see C01ButtonUITests.open).
  private func open(_ slug: String, _ firstId: String, file: StaticString = #filePath, line: UInt = #line) {
    let url = URL(string: "fluttera11y:///t/S01/\(slug)")!
    for attempt in 1...3 {
      app.terminate()
      app.open(url)
      if element(firstId).waitForExistence(timeout: 30) { return }
      print("S01 open \(slug): attempt \(attempt) did not show the example")
    }
    XCTFail("\(slug) did not open after three attempts", file: file, line: line)
  }

  private func expectValue(_ id: String, _ expected: String, file: StaticString = #filePath, line: UInt = #line) {
    let e = element(id)
    let deadline = Date().addingTimeInterval(5)
    while (e.value as? String) != expected && Date() < deadline { usleep(100_000) }
    XCTAssertEqual(e.value as? String, expected, id, file: file, line: line)
  }

  private let named: [(slug: String, controls: [(id: String, name: String)])] = [
    ("good-visible-label", [("s01-good-visible-label-updates", "Email me order updates"),
                            ("s01-good-visible-label-dark", "Dark mode")]),
    ("good-merged-label", [("s01-good-merged-label-remember", "Remember this device"),
                           ("s01-good-merged-label-wifi", "Wi-Fi")]),
    ("good-specific-names", [("s01-good-specific-names-email", "Order updates, email"),
                             ("s01-good-specific-names-sms", "Order updates, text message")]),
    ("good-cupertino", [("s01-good-cupertino-airplane", "Airplane mode")]),
  ]

  func testGoodControlsExposeNameRoleStateAndOperate() {
    for example in named {
      open(example.slug, example.controls[0].id)
      for control in example.controls {
        let e = element(control.id)
        XCTAssertEqual(e.elementType, .switch, control.id)
        XCTAssertEqual(e.label, control.name, control.id)
        XCTAssertTrue(app.switches[control.name].exists, "role and name query for \(control.id)")
        // The visible text is part of the control, not a second element.
        XCTAssertEqual(elements(labelled: control.name).count, 1, control.id)
        expectValue(control.id, "0")
        e.tap()
        expectValue(control.id, "1")
      }
    }
  }

  // VAL-3: each bad example is asserted to have its named defect.

  func testBadUnassociatedLabelHasNoName() {
    let id = "s01-bad-unassociated-label-terms"
    open("bad-unassociated-label", id)
    let e = element(id)
    XCTAssertEqual(e.elementType, .switch)
    XCTAssertEqual(e.label, "")
    // The text is an element of its own.
    XCTAssertTrue(app.staticTexts["I accept the terms"].exists)
    XCTAssertFalse(app.switches["I accept the terms"].exists)
  }

  func testBadDuplicateNamesAreIdentical() {
    open("bad-duplicate-names", "s01-bad-duplicate-names-email")
    let names = ["email", "sms"].map { element("s01-bad-duplicate-names-\($0)").label }
    XCTAssertEqual(names, ["Order updates", "Order updates"])
  }

  func testBadRoleInNameEndsWithRole() {
    let id = "s01-bad-role-in-name-dark"
    open("bad-role-in-name", id)
    XCTAssertEqual(element(id).elementType, .switch)
    XCTAssertTrue(element(id).label.lowercased().hasSuffix("switch"))
  }

  func testSliderIsNamedOnIOS() {
    // FL-028 is a web limitation. On iOS the slider has its name.
    let id = "s01-bad-slider-name-web-volume"
    open("bad-slider-name-web", id)
    XCTAssertEqual(element(id).label, "Volume")
    XCTAssertEqual(element(id).value as? String, "40%")
  }

  // L4. What VoiceOver speaks while swiping through each example. The API
  // cuts an utterance at 64 characters, so phrases are matched as the start
  // of an utterance. (slug, starts that must be spoken, starts that must not).
  private let speech: [(slug: String, first: String, must: [String], mustNot: [String])] = [
    ("good-visible-label", "s01-good-visible-label-updates",
     ["Email me order updates Switch button off", "Dark mode Switch button off"], []),
    ("good-merged-label", "s01-good-merged-label-remember",
     ["Remember this device Switch button off", "Wi-Fi Switch button off"], []),
    ("good-specific-names", "s01-good-specific-names-email",
     ["Order updates, email Switch button off", "Order updates, text message Switch button off"],
     ["Order updates Switch button"]),
    ("good-cupertino", "s01-good-cupertino-airplane", ["Airplane mode Switch button off"], []),
    // Bad examples: the defect must be audible.
    // The checkbox is read with no name, and the text as a separate element.
    ("bad-unassociated-label", "s01-bad-unassociated-label-terms",
     ["Switch button off", "I accept the terms"], ["I accept the terms Switch button"]),
    ("bad-duplicate-names", "s01-bad-duplicate-names-email",
     ["Order updates Switch button off"], ["Order updates, email Switch button"]),
    ("bad-role-in-name", "s01-bad-role-in-name-dark",
     ["Dark mode switch Switch button off"], []),
    // FL-028 is a web limitation: on iOS the slider is read with its name.
    ("bad-slider-name-web", "s01-bad-slider-name-web-volume", ["Volume 40% adjustable"], []),
  ]

  func testVoiceOverSpeech() throws {
    // XCUIVoiceOverService is in the iOS 27 SDK (Xcode 27, Swift 6.4). With an
    // older Xcode the symbol does not exist, so the body is compiled only
    // where the SDK has it.
    #if compiler(>=6.4)
    guard #available(iOS 27.0, *) else { throw XCTSkip("XCUIVoiceOverService needs iOS 27") }
    let voiceOver = XCUIDevice.shared.voiceOverService
    for example in speech {
      open(example.slug, example.first)
      try voiceOver.enable()
      var spoken: [String] = []
      // Swipe right to the end of the screen: the last element repeats.
      for _ in 0..<24 {
        guard let utterance = try? voiceOver.moveForward().utterance else { continue }
        let text = utterance.replacingOccurrences(of: "\n", with: " ")
        if spoken.last == text { break }
        spoken.append(text)
      }
      try voiceOver.disable()
      print("S01VO \(example.slug) | \(spoken.joined(separator: " / "))")
      for phrase in example.must {
        XCTAssertTrue(spoken.contains { $0.hasPrefix(phrase) },
                      "\(example.slug): expected an utterance starting \"\(phrase)\" in \(spoken)")
      }
      for phrase in example.mustNot {
        XCTAssertFalse(spoken.contains { $0.hasPrefix(phrase) },
                       "\(example.slug): did not expect an utterance starting \"\(phrase)\" in \(spoken)")
      }
      if example.slug == "bad-duplicate-names" {
        XCTAssertEqual(spoken.filter { $0.hasPrefix("Order updates Switch button off") }.count, 2,
                       "both switches are read with the same name")
      }
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}
