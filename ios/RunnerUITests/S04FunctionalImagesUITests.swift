// L3 (tree) and L4 (VoiceOver) for S04 Functional images on iOS.
// Spec: docs/specs/S04-functional-images.md.
//
// XCUITest cannot read accessibility traits, so a button that is also an
// image looks like any other button in the tree. That defect is checked on
// iOS through what VoiceOver says.
import XCTest

final class S04FunctionalImagesUITests: XCTestCase {
  private let app = XCUIApplication()
  private static let guide = "Open trail guide"

  /// What the walk records for a stop at which VoiceOver said nothing.
  static let silent = "(no speech)"

  override func setUp() {
    continueAfterFailure = true
  }

  /// Cold-starts the app on one example through the `fluttera11y` URL scheme,
  /// trying up to three times (see C01ButtonUITests.open).
  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    let url = URL(string: "fluttera11y:///t/S04/\(slug)")!
    for attempt in 1...3 {
      app.terminate()
      app.open(url)
      if element("s04-\(slug)-count").waitForExistence(timeout: 30) {
        // The picture is decoded after the first frame.
        usleep(500_000)
        return
      }
      print("S04 open \(slug): attempt \(attempt) did not show the example")
    }
    XCTFail("\(slug) did not open after three attempts", file: file, line: line)
  }

  private func element(_ id: String) -> XCUIElement {
    app.descendants(matching: .any)[id]
  }

  private func expectCount(_ slug: String, _ n: Int, file: StaticString = #filePath, line: UInt = #line) {
    let count = element("s04-\(slug)-count")
    let expected = "Activations: \(n)"
    let deadline = Date().addingTimeInterval(5)
    while count.label != expected && Date() < deadline { usleep(100_000) }
    XCTAssertEqual(count.label, expected, slug, file: file, line: line)
  }

  /// The buttons of the example: every button but the app bar's Back.
  private func exampleButtons() -> [XCUIElement] {
    app.buttons.allElementsBoundByIndex.filter { $0.label != "Back" }
  }

  private let good: [(slug: String, buttons: [(id: String, name: String)])] = [
    ("good-image-button", [("s04-good-image-button-guide", guide)]),
    ("good-icon-label", [("s04-good-icon-label-search", "Search")]),
    ("good-image-with-text", [("s04-good-image-with-text-guide", "Trail guide"),
                              ("s04-good-image-with-text-print", "Print")]),
    ("good-cupertino", [("s04-good-cupertino-search", "Search")]),
    ("good-custom", [("s04-good-custom-guide", guide)]),
    ("good-image-regions", [("s04-good-image-regions-west", "West trail"),
                            ("s04-good-image-regions-east", "East trail")]),
  ]

  func testGoodExamplesAreNamedButtonsWithNoImage() {
    for example in good {
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
      XCTAssertEqual(app.images.count, 0, "\(example.slug): image elements")
      XCTAssertEqual(exampleButtons().count, example.buttons.count, "\(example.slug): buttons")
    }
  }

  // Each bad example is asserted to have its named defect.

  func testBadNoNameHasNoName() {
    open("bad-no-name")
    let e = element("s04-bad-no-name-guide")
    XCTAssertEqual(e.elementType, .button)
    XCTAssertEqual(e.label, "")
  }

  func testBadLabelOnImageLeavesTheButtonUnnamed() {
    open("bad-label-on-image")
    let buttons = exampleButtons()
    XCTAssertEqual(buttons.count, 1)
    XCTAssertEqual(buttons.first?.label, "")
    XCTAssertFalse(app.buttons[Self.guide].exists)
    // The name is on a second element, which is an image.
    XCTAssertEqual(app.images.count, 1)
    XCTAssertTrue(app.images[Self.guide].exists)
    buttons.first?.tap()
    expectCount("bad-label-on-image", 1)
  }

  func testBadTapGestureIsAnImageNotAButton() {
    open("bad-tap-gesture")
    XCTAssertEqual(exampleButtons().count, 0)
    XCTAssertEqual(app.images.count, 1)
    XCTAssertTrue(app.images[Self.guide].exists)
    // It still works by touch, which is what hides the defect.
    app.images[Self.guide].tap()
    expectCount("bad-tap-gesture", 1)
  }

  func testBadDescribesPictureIsNamedAfterTheIcon() {
    open("bad-describes-picture")
    let e = element("s04-bad-describes-picture-search")
    XCTAssertEqual(e.elementType, .button)
    XCTAssertEqual(e.label, "Magnifying glass")
  }

  func testBadImageNotExcludedIsStillAButtonInTheTree() {
    // The image trait cannot be read here; testVoiceOverSpeech hears it.
    open("bad-image-not-excluded")
    let e = element("s04-bad-image-not-excluded-guide")
    XCTAssertEqual(e.elementType, .button)
    XCTAssertEqual(e.label, "Trail guide")
  }

  func testBadRedundantLabelNamesTheButtonTwice() {
    open("bad-redundant-label")
    let e = element("s04-bad-redundant-label-print")
    XCTAssertEqual(e.elementType, .button)
    XCTAssertEqual(e.label, "Printer\nPrint")
  }

  // L4. Everything VoiceOver says between the "Example" heading and the
  // activation count, which is the last element of every example. A stop at
  // which VoiceOver says nothing is recorded as "(no speech)".
  private let speech: [(slug: String, content: [String])] = [
    ("good-image-button", ["Open trail guide Button"]),
    ("good-icon-label", ["Search Button"]),
    ("good-image-with-text", ["Trail guide Button", "Print Button"]),
    ("good-cupertino", ["Search Button"]),
    ("good-custom", ["Open trail guide Button"]),
    ("good-image-regions", ["West trail Button", "East trail Button"]),
    // Bad examples: the defect must be audible.
    ("bad-no-name", ["Button Image"]),
    ("bad-label-on-image", ["Button", "Open trail guide Image"]),
    ("bad-tap-gesture", [silent, "Open trail guide Image"]),
    // The name is wrong, but only a person can tell.
    ("bad-describes-picture", ["Magnifying glass Button"]),
    ("bad-image-not-excluded", ["Trail guide Button Image"]),
    ("bad-redundant-label", ["Printer Print Button"]),
  ]

  /// One utterance with every run of whitespace made one space.
  private static func normalized(_ utterance: String) -> String {
    utterance.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
  }

  /// The utterances of the example itself: those after the last "Example
  /// Heading" and before the activation count. Returns nil when the walk
  /// did not pass the heading or did not end on the count, so an incomplete
  /// walk cannot pass.
  static func exampleContent(_ spoken: [String]) -> [String]? {
    guard let last = spoken.last, last.hasPrefix("Activations:"),
          let heading = spoken.lastIndex(of: "Example Heading") else { return nil }
    return Array(spoken[(heading + 1)..<(spoken.count - 1)])
  }

  func testExampleContentNeedsTheHeadingAndTheCount() {
    XCTAssertEqual(
      Self.exampleContent(["Back Button", "Example Heading", "Search Button", "Activations: 0"]),
      ["Search Button"])
    XCTAssertEqual(
      Self.exampleContent(["Example Heading", Self.silent, "Open Image", "Activations: 0"]),
      [Self.silent, "Open Image"])
    XCTAssertEqual(Self.exampleContent(["Example Heading", "Activations: 0"]), [])
    // No count at the end: the walk did not finish.
    XCTAssertNil(Self.exampleContent(["Example Heading", "Search Button"]))
    // No heading: the walk started inside the example.
    XCTAssertNil(Self.exampleContent(["Search Button", "Activations: 0"]))
    XCTAssertNil(Self.exampleContent([]))
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
        } catch let error as NSError
          where error.domain == "com.apple.xctest.voiceoverservice" && error.code == 3 {
          // "No speech available": VoiceOver moved and said nothing.
          spoken.append(Self.silent)
        }
        if spoken.last!.hasPrefix("Activations:") { break }
      }
      try voiceOver.disable()
      voiceOverOn = false
      let content = Self.exampleContent(spoken)
      print("S04VO \(example.slug) | \((content ?? spoken).joined(separator: " / "))")
      XCTAssertNotNil(content, "\(example.slug): the walk did not run from the heading to the count: \(spoken)")
      XCTAssertEqual(content, example.content, example.slug)
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}
