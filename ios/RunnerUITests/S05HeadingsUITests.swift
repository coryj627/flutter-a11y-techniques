// L3 (tree) and L4 (VoiceOver) for S05 Headings on iOS.
// Spec: docs/specs/S05-headings.md.
//
// XCUITest cannot read accessibility traits, so whether an element is a
// heading can only be checked on iOS through what VoiceOver says. The tree
// test checks that the text is exposed at all; the speech test checks the
// heading.
import XCTest

final class S05HeadingsUITests: XCTestCase {
  private let app = XCUIApplication()

  override func setUp() {
    continueAfterFailure = true
  }

  private func element(labelled label: String) -> XCUIElement {
    app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch
  }

  /// Cold-starts the app on one example through the `fluttera11y` URL scheme,
  /// trying up to three times (see C01ButtonUITests.open).
  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    let url = URL(string: "fluttera11y:///t/S05/\(slug)")!
    for attempt in 1...3 {
      app.terminate()
      app.open(url)
      if element(labelled: "Example").waitForExistence(timeout: 30) { return }
      print("S05 open \(slug): attempt \(attempt) did not show the example")
    }
    XCTFail("\(slug) did not open after three attempts", file: file, line: line)
  }

  func testHeadingTextIsExposed() {
    let expected: [(slug: String, labels: [String])] = [
      ("good-levels", ["Profile", "Contact details", "Email preferences", "Security",
                       "Choose which messages you receive."]),
      ("good-cupertino", ["Notifications", "Order updates"]),
      ("bad-visual-only", ["Profile"]),
      // The defect is in the tree here: the name carries the word "heading".
      ("bad-fake-label", ["Profile, heading"]),
      ("bad-skipped-level", ["Profile", "Contact details"]),
      ("bad-header-only", ["Profile"]),
      ("bad-emphasis-heading", ["Please check your address before you pay."]),
      ("bad-cupertino-section-header", ["Notifications"]),
    ]
    for example in expected {
      open(example.slug)
      for label in example.labels {
        XCTAssertTrue(element(labelled: label).exists, "\(example.slug): \"\(label)\"")
      }
    }
  }

  // L4. What VoiceOver speaks while swiping through each example.
  // (slug, phrases that must be spoken, phrases that must not be).
  private let speech: [(slug: String, must: [String], mustNot: [String])] = [
    ("good-levels",
     ["Profile Heading", "Contact details Heading", "Email preferences Heading",
      "Security Heading", "Choose which messages you receive."],
     ["Choose which messages you receive. Heading"]),
    ("good-cupertino", ["Notifications Heading"], []),
    // Bad examples: the defect must be audible.
    ("bad-visual-only", ["Profile"], ["Profile Heading"]),
    ("bad-fake-label", ["Profile, heading"], ["Profile Heading"]),
    // VoiceOver on iOS does not speak heading levels for these, so the
    // skipped level cannot be heard; it is asserted in the widget and web tests.
    ("bad-skipped-level", ["Profile Heading", "Contact details Heading"], []),
    // Flutter limitation FL-003: header with no level is not a heading here.
    // If "Profile Heading" is spoken after an upgrade, the limitation is fixed.
    ("bad-header-only", ["Profile"], ["Profile Heading"]),
    ("bad-emphasis-heading", ["Please check your address before you pay. Heading"], []),
    // Flutter limitation: CupertinoListSection does not expose its header.
    ("bad-cupertino-section-header", ["Notifications"], ["Notifications Heading"]),
  ]

  func testVoiceOverSpeech() throws {
    // XCUIVoiceOverService is in the iOS 27 SDK (Xcode 27, Swift 6.4). With an
    // older Xcode the symbol does not exist, so the body is compiled only
    // where the SDK has it.
    #if compiler(>=6.4)
    guard #available(iOS 27.0, *) else { throw XCTSkip("XCUIVoiceOverService needs iOS 27") }
    let voiceOver = XCUIDevice.shared.voiceOverService
    for example in speech {
      open(example.slug)
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
      print("S05VO \(example.slug) | \(spoken.joined(separator: " / "))")
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
