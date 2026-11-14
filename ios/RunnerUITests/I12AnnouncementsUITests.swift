// L3 (tree) and L4 (VoiceOver) for I12 Announcements and live regions on iOS.
// Spec: docs/specs/I12-announcements.md.
import XCTest

final class I12AnnouncementsUITests: XCTestCase {
  private let app = XCUIApplication()

  override func setUp() {
    continueAfterFailure = true
  }

  private func element(_ id: String) -> XCUIElement {
    app.descendants(matching: .any)[id]
  }

  private func element(labelled label: String) -> XCUIElement {
    app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch
  }

  /// Cold-starts the app on one example through the `fluttera11y` URL scheme,
  /// trying up to three times (see C01ButtonUITests.open).
  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    let url = URL(string: "fluttera11y:///t/I12/\(slug)")!
    for attempt in 1...3 {
      app.terminate()
      app.open(url)
      if element("i12-\(slug)-action").waitForExistence(timeout: 30) { return }
      print("I12 open \(slug): attempt \(attempt) did not show the example")
    }
    XCTFail("\(slug) did not open after three attempts", file: file, line: line)
  }

  // L3. The message text changes when the button is pressed, and focus is
  // not needed to see it. This is all XCUITest can check here: it cannot read
  // whether an element is a live region.
  func testStatusTextChangesWhenTheButtonIsPressed() {
    for (slug, before, after) in [
      ("good-live-region", "Cart is empty", "1 item in cart"),
      ("good-announce", "", "Link copied"),
      ("bad-silent-update", "Cart is empty", "1 item in cart"),
      ("bad-status-role-only", "Cart is empty", "1 item in cart"),
      ("bad-alert-role-only", "", "Could not save. Attempt 1 failed."),
    ] {
      open(slug)
      let status = element("i12-\(slug)-status")
      if !before.isEmpty { XCTAssertEqual(status.label, before, slug) }
      element("i12-\(slug)-action").tap()
      let deadline = Date().addingTimeInterval(5)
      while status.label != after && Date() < deadline { usleep(100_000) }
      XCTAssertEqual(status.label, after, slug)
    }
  }

  func testSnackBarAppearsWithItsMessage() {
    open("good-snackbar")
    element("i12-good-snackbar-action").tap()
    XCTAssertTrue(element(labelled: "Message archived").waitForExistence(timeout: 5))
  }

  // L4. What VoiceOver says after each example's button is activated.
  //
  // With VoiceOver on, XCUIElement.tap() only moves the VoiceOver cursor to
  // the button; a double tap activates it, as it does for a person. After
  // that, XCUIVoiceOverService.currentSpeech() returns the announcement when
  // there is one, and keeps returning the button when there is none. (An
  // earlier attempt used tap() alone, never activated the button, and wrongly
  // concluded that announcements could not be captured; see docs/plan.md.)
  private let speech: [(slug: String, button: String, announced: String?)] = [
    ("good-live-region", "Add to cart Button", "1 item in cart"),
    ("good-announce", "Copy link Button", "Link copied"),
    ("good-snackbar", "Archive message Button", "Message archived"),
    ("bad-silent-update", "Add to cart Button", nil),
    // Flutter's status and alert roles do nothing on iOS (FL-017).
    ("bad-status-role-only", "Add to cart Button", nil),
    ("bad-alert-role-only", "Save changes Button", nil),
  ]

  func testVoiceOverSpeech() throws {
    #if compiler(>=6.4)
    guard #available(iOS 27.0, *) else { throw XCTSkip("XCUIVoiceOverService needs iOS 27") }
    let voiceOver = XCUIDevice.shared.voiceOverService
    func current() -> String {
      ((try? voiceOver.currentSpeech().utterance) ?? "").replacingOccurrences(of: "\n", with: " ")
    }
    /// Polls until `done` accepts the current speech or `seconds` pass.
    func waitForSpeech(_ seconds: TimeInterval, until done: (String) -> Bool) -> String {
      let deadline = Date().addingTimeInterval(seconds)
      var last = current()
      while !done(last) && Date() < deadline {
        usleep(250_000)
        last = current()
      }
      return last
    }
    for example in speech {
      open(example.slug)
      try voiceOver.enable()
      defer { try? voiceOver.disable() }
      let action = element("i12-\(example.slug)-action")
      // Put the VoiceOver cursor on the button and wait until it is read.
      var before = ""
      for _ in 0..<5 {
        action.tap()
        before = waitForSpeech(4) { $0 == example.button }
        if before == example.button { break }
      }
      XCTAssertEqual(before, example.button, "\(example.slug): cursor is not on the button")
      action.doubleTap()
      let after: String
      if let announced = example.announced {
        after = waitForSpeech(8) { $0 == announced }
        XCTAssertEqual(after, announced, "\(example.slug): the message was not announced")
      } else {
        // Nothing should be said. Wait for the visible change, then give
        // VoiceOver the time in which the good examples do announce.
        if example.slug != "bad-alert-role-only" {
          let status = element("i12-\(example.slug)-status")
          let deadline = Date().addingTimeInterval(5)
          while status.label != "1 item in cart" && Date() < deadline { usleep(100_000) }
          XCTAssertEqual(status.label, "1 item in cart", "\(example.slug): the button was not activated")
        } else {
          XCTAssertTrue(
            element("i12-\(example.slug)-status").waitForExistence(timeout: 5),
            "\(example.slug): the button was not activated")
        }
        after = waitForSpeech(4) { $0 != example.button }
        XCTAssertEqual(after, example.button, "\(example.slug): something was announced")
      }
      print("I12VO \(example.slug) | \(before) / (activate) / \(after)")
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}
