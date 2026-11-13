// L3 (tree) and L4 (VoiceOver) for C01 Button on iOS.
// Spec: docs/specs/C01-button.md.
import XCTest

final class C01ButtonUITests: XCTestCase {
  private let app = XCUIApplication()

  override func setUp() {
    continueAfterFailure = true
  }

  /// Cold-starts the app on one example through the `fluttera11y` URL scheme.
  ///
  /// On a slow simulator the first launch can come up without the example
  /// (seen once on CI: the app started but the screen never appeared), so the
  /// launch is tried up to three times before the test fails.
  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    let url = URL(string: "fluttera11y:///t/C01/\(slug)")!
    for attempt in 1...3 {
      app.terminate()
      app.open(url)
      if element("c01-\(slug)-count").waitForExistence(timeout: 30) { return }
      print("C01 open \(slug): attempt \(attempt) did not show the example")
    }
    XCTFail("\(slug) did not open after three attempts", file: file, line: line)
  }

  private func element(_ id: String) -> XCUIElement {
    app.descendants(matching: .any)[id]
  }

  private func expectCount(_ slug: String, _ n: Int, file: StaticString = #filePath, line: UInt = #line) {
    let count = element("c01-\(slug)-count")
    let expected = "Activations: \(n)"
    let deadline = Date().addingTimeInterval(5)
    while count.label != expected && Date() < deadline { usleep(100_000) }
    XCTAssertEqual(count.label, expected, slug, file: file, line: line)
  }

  private let enabledGood: [(slug: String, buttons: [(id: String, name: String)])] = [
    ("good-text", [("c01-good-text-filled", "Save"), ("c01-good-text-outlined", "Cancel"),
                   ("c01-good-text-text", "Learn more")]),
    ("good-icon", [("c01-good-icon-close", "Close")]),
    ("good-unique-names", [("c01-good-unique-names-username", "Edit username"),
                           ("c01-good-unique-names-email", "Edit email"),
                           ("c01-good-unique-names-password", "Edit password")]),
    ("good-cupertino", [("c01-good-cupertino-save", "Save")]),
    ("good-custom", [("c01-good-custom-save", "Save")]),
  ]

  private let disabledGood: [(slug: String, id: String, name: String)] = [
    ("good-disabled", "c01-good-disabled-submit", "Submit"),
    ("good-cupertino", "c01-good-cupertino-delete", "Delete"),
  ]

  func testGoodButtonsExposeNameRoleStateAndActivate() {
    for example in enabledGood {
      open(example.slug)
      var n = 0
      for button in example.buttons {
        let e = element(button.id)
        XCTAssertEqual(e.elementType, .button, button.id)
        XCTAssertEqual(e.label, button.name, button.id)
        XCTAssertTrue(e.isEnabled, button.id)
        XCTAssertTrue(app.buttons[button.name].exists, "role and name query for \(button.id)")
        e.tap()
        n += 1
        expectCount(example.slug, n)
      }
    }
  }

  func testGoodDisabledButtonsReportDisabledAndDoNotAct() {
    for button in disabledGood {
      open(button.slug)
      let e = element(button.id)
      XCTAssertEqual(e.elementType, .button, button.id)
      XCTAssertEqual(e.label, button.name, button.id)
      XCTAssertFalse(e.isEnabled, button.id)
      e.tap()
      usleep(500_000)
      expectCount(button.slug, 0)
    }
  }

  // VAL-3: each bad example is asserted to have its named defect.

  func testBadUnlabelledIconHasNoName() {
    open("bad-unlabelled-icon")
    let e = element("c01-bad-unlabelled-icon-close")
    XCTAssertEqual(e.elementType, .button)
    XCTAssertEqual(e.label, "")
  }

  func testBadGestureOnlyIsNotAButton() {
    open("bad-gesture-only")
    let e = element("c01-bad-gesture-only-save")
    XCTAssertNotEqual(e.elementType, .button)
    XCTAssertEqual(e.label, "Save")
    XCTAssertFalse(app.buttons["Save"].exists)
  }

  func testBadRoleInNameEndsWithRole() {
    open("bad-role-in-name")
    XCTAssertTrue(element("c01-bad-role-in-name-close").label.lowercased().hasSuffix("button"))
  }

  func testBadDuplicateNamesAreIdentical() {
    open("bad-duplicate-names")
    let names = ["username", "email", "password"].map { element("c01-bad-duplicate-names-\($0)").label }
    XCTAssertEqual(names, ["Edit", "Edit", "Edit"])
  }

  func testBadNameMismatchLacksVisibleText() {
    open("bad-name-mismatch")
    let name = element("c01-bad-name-mismatch-edit").label
    XCTAssertEqual(name, "Change username")
    XCTAssertFalse(name.lowercased().contains("edit"))
  }

  func testBadFakeDisabledReportsEnabledAndActs() {
    open("bad-fake-disabled")
    let e = element("c01-bad-fake-disabled-submit")
    XCTAssertTrue(e.isEnabled)
    e.tap()
    expectCount("bad-fake-disabled", 1)
  }

  func testBadCupertinoDisabledReportsEnabled() {
    // Flutter limitation: no disabled state. If this fails after an upgrade,
    // the limitation is fixed.
    open("bad-cupertino-disabled")
    let e = element("c01-bad-cupertino-disabled-delete")
    XCTAssertEqual(e.elementType, .button)
    XCTAssertTrue(e.isEnabled)
  }

  // L4. What VoiceOver speaks while swiping through each example.
  // (slug, phrases that must be spoken, phrases that must not be).
  private let speech: [(slug: String, must: [String], mustNot: [String])] = [
    ("good-text", ["Save Button", "Cancel Button", "Learn more Button"], []),
    ("good-icon", ["Close Button"], []),
    ("good-disabled", ["Submit dimmed Button"], []),
    ("good-unique-names",
     ["Edit username Button", "Edit email Button", "Edit password Button"], ["Edit Button"]),
    ("good-cupertino", ["Save Button", "Delete dimmed Button"], []),
    ("good-custom", ["Save Button"], []),
    // Bad examples: the defect must be audible.
    ("bad-unlabelled-icon", ["Button"], ["Close Button"]),
    ("bad-gesture-only", ["Save"], ["Save Button"]),
    // VoiceOver does not repeat the role when the name already ends with it,
    // so on iOS this defect is in the tree (label "Close button") but not
    // in the speech.
    ("bad-role-in-name", ["Close Button"], []),
    ("bad-duplicate-names", ["Edit Button"], ["Edit username Button"]),
    ("bad-name-mismatch", ["Change username Button"], ["Edit Button"]),
    ("bad-fake-disabled", ["Submit Button"], ["Submit dimmed Button"]),
    ("bad-cupertino-disabled", ["Delete Button"], ["Delete dimmed Button"]),
  ]

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
      var spoken: [String] = []
      // Swipe right until the activation count, the last element, is read.
      for _ in 0..<20 {
        guard let utterance = try? voiceOver.moveForward().utterance else { continue }
        spoken.append(utterance.replacingOccurrences(of: "\n", with: " "))
        if utterance.hasPrefix("Activations:") { break }
      }
      try voiceOver.disable()
      print("C01VO \(example.slug) | \(spoken.joined(separator: " / "))")
      for phrase in example.must {
        XCTAssertTrue(spoken.contains(phrase), "\(example.slug): expected \"\(phrase)\" in \(spoken)")
      }
      for phrase in example.mustNot {
        XCTAssertFalse(spoken.contains(phrase), "\(example.slug): did not expect \"\(phrase)\" in \(spoken)")
      }
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}
