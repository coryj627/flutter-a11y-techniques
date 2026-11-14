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

  // L4 is not automated on iOS for this technique. XCUIVoiceOverService
  // returns what VoiceOver says for the element it is on (moveForward,
  // currentSpeech); after a button is pressed it keeps returning the button,
  // never the announcement that follows. The simulator's system log does not
  // contain the speech either. Both were tried on iOS 27.0 (docs/plan.md).
  // So on iOS whether these messages are announced is not verified here.
}
