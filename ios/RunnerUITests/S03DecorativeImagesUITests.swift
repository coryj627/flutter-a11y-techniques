// L3 (tree) and L4 (VoiceOver) for S03 Decorative images on iOS.
// Spec: docs/specs/S03-decorative-images.md.
//
// Images have no controls to identify, so elements are found by label, or by
// type when they have none.
import XCTest

final class S03DecorativeImagesUITests: XCTestCase {
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
    let url = URL(string: "fluttera11y:///t/S03/\(slug)")!
    for attempt in 1...3 {
      app.terminate()
      app.open(url)
      if elements(labelled: "Example").firstMatch.waitForExistence(timeout: 30) {
        // The photo is decoded after the first frame.
        usleep(500_000)
        return
      }
      print("S03 open \(slug): attempt \(attempt) did not show the example")
    }
    XCTFail("\(slug) did not open after three attempts", file: file, line: line)
  }

  private func assertWelcomeText(file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertEqual(elements(labelled: "Welcome back, Ana.").count, 1, file: file, line: line)
    XCTAssertEqual(elements(labelled: "You have 2 new messages.").count, 1, file: file, line: line)
  }

  func testGoodImageExcludedExposesOnlyTheText() {
    open("good-image-excluded")
    assertWelcomeText()
    XCTAssertEqual(app.images.count, 0)
  }

  func testGoodIconNoLabelExposesOnlyTheWords() {
    open("good-icon-no-label")
    XCTAssertEqual(elements(labelled: "Shipping").count, 1)
    XCTAssertEqual(elements(labelled: "Returns").count, 1)
    XCTAssertEqual(app.images.count, 0)
  }

  func testGoodBackgroundImageExposesOnlyTheText() {
    open("good-background-image")
    assertWelcomeText()
    XCTAssertEqual(app.images.count, 0)
  }

  func testGoodExcludeSemanticsExposesOnlyTheName() {
    open("good-exclude-semantics")
    XCTAssertEqual(elements(labelled: "Ana Kovac").count, 1)
    XCTAssertEqual(labels(containing: "AK").count, 0)
  }

  func testGoodMergedRowIsNotAnImage() {
    open("good-merged-row")
    XCTAssertEqual(elements(labelled: "Trail guide\n12 routes").count, 1)
    XCTAssertEqual(app.images.count, 0)
  }

  // VAL-3: each bad example is asserted to have its named defect.

  private func assertBannerIsAnUnnamedImage(_ slug: String) {
    open(slug)
    assertWelcomeText()
    XCTAssertEqual(app.images.count, 1, slug)
    XCTAssertEqual(app.images.firstMatch.label, "", slug)
  }

  func testBadNotExcludedIsAnUnnamedImage() {
    assertBannerIsAnUnnamedImage("bad-not-excluded")
  }

  func testBadEmptyLabelIsAnUnnamedImage() {
    assertBannerIsAnUnnamedImage("bad-empty-label")
  }

  func testBadRedundantLabelExposesEveryWordTwice() {
    open("bad-redundant-label")
    XCTAssertEqual(elements(labelled: "Shipping").count, 2)
    XCTAssertEqual(elements(labelled: "Returns").count, 2)
  }

  func testBadMergedImageRowIsAnImage() {
    open("bad-merged-image")
    XCTAssertEqual(app.images.count, 1)
    XCTAssertEqual(app.images.firstMatch.label, "Trail guide\n12 routes")
  }

  // L4. What VoiceOver speaks while swiping through each example: the whole
  // list of utterances after the "Example" heading, in order. Because the
  // list is complete, it also shows what is not spoken.
  private static let welcome = ["Welcome back, Ana.", "You have 2 new messages."]
  private static let delivery = "Delivery takes 2 to 4 days."
  private let speech: [(slug: String, spoken: [String])] = [
    ("good-image-excluded", welcome),
    ("good-icon-no-label", ["Shipping", "Returns", delivery]),
    ("good-background-image", welcome),
    ("good-exclude-semantics", ["Ana Kovac"]),
    ("good-merged-row", ["Trail guide 12 routes"]),
    // VoiceOver skips an image with no name, so these two sound the same as
    // the good example. The image is in the tree (see the tests above).
    ("bad-not-excluded", welcome),
    ("bad-empty-label", welcome),
    ("bad-redundant-label", ["Shipping", "Shipping", "Returns", "Returns", delivery]),
    ("bad-merged-image", ["Trail guide 12 routes Image"]),
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
      // Swipe right to the end of the screen. There VoiceOver stays on the
      // last element and repeats it. One repeat could also be two elements
      // that read the same, so the end counts only when two more moves give
      // the same utterance again; anything else is kept as speech. A move
      // that throws, or a walk that never reaches the end, fails the test:
      // what was not heard cannot be said to be absent.
      var reachedEnd = false
      var repeats = 0
      for _ in 0..<30 {
        // `try`, not `try?`: a move that fails ends the test with its error.
        let utterance = try voiceOver.moveForward().utterance
        // VoiceOver separates the label and the role with other whitespace
        // than one space; every run of whitespace becomes one space.
        let text = utterance.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        if spoken.last == text {
          repeats += 1
          if repeats == 3 {
            reachedEnd = true
            break
          }
          continue
        }
        // Repeats that were not the end were elements of their own.
        spoken.append(contentsOf: Array(repeating: spoken.last ?? "", count: repeats))
        repeats = 0
        spoken.append(text)
      }
      try voiceOver.disable()
      print("S03VO \(example.slug) | \(spoken.joined(separator: " / "))")
      XCTAssertTrue(reachedEnd, "\(example.slug): the walk did not reach the end of the screen")
      // What comes after the "Example" heading is the example itself.
      let start = (spoken.firstIndex(of: "Example Heading") ?? -1) + 1
      XCTAssertGreaterThan(start, 0, "\(example.slug): the walk reached the example")
      XCTAssertEqual(Array(spoken[start...]), example.spoken, example.slug)
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}
