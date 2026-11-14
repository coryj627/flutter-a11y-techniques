// L3 (tree) and L4 (VoiceOver) for S02 Informative images on iOS.
// Spec: docs/specs/S02-informative-images.md.
//
// Images have no controls to identify, so elements are found by label, or by
// type when they have none.
import XCTest

final class S02InformativeImagesUITests: XCTestCase {
  private let app = XCUIApplication()

  override func setUp() {
    continueAfterFailure = true
  }

  private func elements(labelled label: String) -> XCUIElementQuery {
    app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label))
  }

  private func labels(containing text: String) -> XCUIElementQuery {
    app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS[c] %@", text))
  }

  /// Cold-starts the app on one example through the `fluttera11y` URL scheme,
  /// trying up to three times (see C01ButtonUITests.open).
  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    let url = URL(string: "fluttera11y:///t/S02/\(slug)")!
    for attempt in 1...3 {
      app.terminate()
      app.open(url)
      if elements(labelled: "Example").firstMatch.waitForExistence(timeout: 30) {
        // The photo is decoded after the first frame.
        usleep(500_000)
        return
      }
      print("S02 open \(slug): attempt \(attempt) did not show the example")
    }
    XCTFail("\(slug) did not open after three attempts", file: file, line: line)
  }

  func testGoodImageLabelIsANamedImage() {
    open("good-image-label")
    XCTAssertEqual(app.images.count, 1)
    XCTAssertEqual(app.images.firstMatch.label, "Sunrise over green hills")
    XCTAssertTrue(app.staticTexts["Taken from the east ridge trail."].exists)
  }

  func testGoodIconLabelReadsStatusAndOrderAsOneElement() {
    open("good-icon-label")
    XCTAssertEqual(elements(labelled: "Delivered\nOrder 1042").count, 1)
    XCTAssertEqual(elements(labelled: "Delayed\nOrder 1043").count, 1)
    // The status is not a second element, and the icon is not an unnamed image.
    XCTAssertEqual(elements(labelled: "Delivered").count, 0)
    XCTAssertEqual(elements(labelled: "Order 1042").count, 0)
    XCTAssertEqual(app.images.count, 0)
  }

  func testGoodGroupDescriptionIsOneElement() {
    open("good-group-description")
    XCTAssertEqual(elements(labelled: "Sunrise at 6:35 am").count, 1)
    XCTAssertEqual(labels(containing: "6:35 am").count, 1)
  }

  func testGoodChartIsANamedImageWithItsDataInText() {
    open("good-chart")
    XCTAssertEqual(app.images.count, 1)
    XCTAssertEqual(app.images.firstMatch.label, "Bar chart: orders rose every quarter of 2025")
    XCTAssertTrue(app.staticTexts["Orders in 2025: Q1 20, Q2 35, Q3 50, Q4 80."].exists)
  }

  // VAL-3: each bad example is asserted to have its named defect.

  func testBadNoLabelHasNoTextAlternative() {
    open("bad-no-label")
    // The photo is an image element with no label, and nothing else on the
    // screen says what it shows.
    XCTAssertEqual(app.images.count, 1)
    XCTAssertEqual(app.images.firstMatch.label, "")
    XCTAssertEqual(labels(containing: "sunrise").count, 0)
  }

  func testBadIconNoLabelRowsAreOrderNumbersOnly() {
    open("bad-icon-no-label")
    XCTAssertEqual(elements(labelled: "Order 1042").count, 1)
    XCTAssertEqual(elements(labelled: "Order 1043").count, 1)
    XCTAssertEqual(labels(containing: "Delivered").count, 0)
    XCTAssertEqual(labels(containing: "Delayed").count, 0)
  }

  func testBadRoleInLabelStartsWithRole() {
    open("bad-role-in-label")
    XCTAssertTrue(app.images.firstMatch.label.lowercased().hasPrefix("image"))
  }

  func testBadFilenameLabelIsAFileName() {
    open("bad-filename-label")
    XCTAssertEqual(app.images.firstMatch.label, "IMG_2041.png")
  }

  // L4. What VoiceOver speaks while swiping through each example.
  // (slug, phrases that must be spoken, phrases that must not be). A phrase
  // ending in "*" is matched as the start of an utterance.
  private let speech: [(slug: String, must: [String], mustNot: [String])] = [
    ("good-image-label", ["Sunrise over green hills Image", "Taken from the east ridge trail."], []),
    ("good-icon-label", ["Delivered Order 1042", "Delayed Order 1043"], ["Order 1042", "Delivered"]),
    ("good-group-description", ["Sunrise at 6:35 am"], ["6:35 am"]),
    ("good-chart", ["Bar chart: orders rose every quarter of 2025 Image",
                    "Orders in 2025: Q1 20, Q2 35, Q3 50, Q4 80."], []),
    // Bad examples: the defect must be audible.
    // VoiceOver skips the photo: the text after it follows "Example" directly.
    ("bad-no-label", ["Taken from the east ridge trail."], ["*Image", "Sunrise*"]),
    ("bad-icon-no-label", ["Order 1042", "Order 1043"],
     ["Delivered*", "Delayed*", "*Delivered", "*Delayed"]),
    ("bad-role-in-label", ["Image of a sunrise over green hills Image"], []),
    ("bad-filename-label", ["IMG_2041.png Image"], []),
  ]

  private func matches(_ utterance: String, _ phrase: String) -> Bool {
    if phrase.hasPrefix("*") { return utterance.hasSuffix(String(phrase.dropFirst())) }
    if phrase.hasSuffix("*") { return utterance.hasPrefix(String(phrase.dropLast())) }
    return utterance == phrase
  }

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
        // VoiceOver separates the label and the role with other whitespace
        // than one space; every run of whitespace becomes one space.
        let text = utterance.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        if spoken.last == text { break }
        spoken.append(text)
      }
      try voiceOver.disable()
      print("S02VO \(example.slug) | \(spoken.joined(separator: " / "))")
      // What comes after the "Example" heading is the example itself.
      let start = (spoken.firstIndex(of: "Example Heading") ?? -1) + 1
      XCTAssertGreaterThan(start, 0, "\(example.slug): the walk reached the example")
      let content = Array(spoken[start...])
      for phrase in example.must {
        XCTAssertTrue(content.contains { matches($0, phrase) },
                      "\(example.slug): expected \"\(phrase)\" in \(content)")
      }
      for phrase in example.mustNot {
        XCTAssertFalse(content.contains { matches($0, phrase) },
                       "\(example.slug): did not expect \"\(phrase)\" in \(content)")
      }
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}
