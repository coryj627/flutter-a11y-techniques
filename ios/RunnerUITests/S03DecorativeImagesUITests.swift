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

  // L4. What VoiceOver speaks in each example: every element after the
  // "Example" heading, in order, to the end of the screen. Because the list
  // is complete, it also shows what is not spoken.
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

  /// One utterance with every run of whitespace made one space: VoiceOver
  /// separates a label and its role with other whitespace than one space.
  private func normalized(_ utterance: String) -> String {
    utterance.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
  }

  /// The elements of the example, last to first, from what was heard while
  /// walking backward from the last element (`backward`, which ends at the
  /// "Example" heading), given the last element's own utterance. Returns nil
  /// when the forward walk did not prove the end of the screen.
  ///
  /// The forward walk stopped after hearing `last` four times in a row
  /// (`forwardRun`). Walking backward shows how many of those were separate
  /// elements: the utterances equal to `last` at the start of `backward`,
  /// and the element the walk began on. If that accounts for all four, no
  /// move was seen to stay on the same element, so the end was not shown.
  static func exampleContent(last: String, forwardRun: Int, backward: [String]) -> [String]? {
    let sameAsLast = backward.prefix { $0 == last }.count
    guard sameAsLast + 1 < forwardRun else { return nil }
    return Array(backward.reversed()) + [last]
  }

  /// exampleContent on made-up walks: no device or VoiceOver is involved.
  func testExampleContentKeepsRepeatsAndNeedsAProvenEnd() {
    typealias T = S03DecorativeImagesUITests
    // One last element: nothing equal to it is heard on the way back.
    XCTAssertEqual(T.exampleContent(last: "B", forwardRun: 4, backward: ["A"]), ["A", "B"])
    // Two elements that read the same at the end are both kept.
    XCTAssertEqual(T.exampleContent(last: "B", forwardRun: 4, backward: ["B", "A"]), ["A", "B", "B"])
    XCTAssertEqual(T.exampleContent(last: "B", forwardRun: 4, backward: ["B", "B", "A"]),
                   ["A", "B", "B", "B"])
    // Four elements that read the same: every forward move reached a new
    // element, so the end of the screen was never shown.
    XCTAssertNil(T.exampleContent(last: "B", forwardRun: 4, backward: ["B", "B", "B", "A"]))
    // Repeats in the middle are kept as they were heard.
    XCTAssertEqual(T.exampleContent(last: "C", forwardRun: 4, backward: ["B", "B", "A"]),
                   ["A", "B", "B", "C"])
  }

  func testVoiceOverSpeech() throws {
    // XCUIVoiceOverService is in the iOS 27 SDK (Xcode 27, Swift 6.4). With an
    // older Xcode the symbol does not exist, so the body is compiled only
    // where the SDK has it.
    #if compiler(>=6.4)
    guard #available(iOS 27.0, *) else { throw XCTSkip("XCUIVoiceOverService needs iOS 27") }
    let voiceOver = XCUIDevice.shared.voiceOverService
    let endRun = 4
    for example in speech {
      open(example.slug)
      try voiceOver.enable()
      // A move that throws leaves this loop early; VoiceOver must not stay
      // on for the tests that follow. On the normal path it is switched off
      // below with `try`, so a failure to stop is still reported.
      var voiceOverOn = true
      defer { if voiceOverOn { try? voiceOver.disable() } }
      // Swipe right until the same utterance has been heard four times in a
      // row. At the end of the screen VoiceOver stays on the last element
      // and repeats it; elements that read the same also repeat. Which it
      // was is settled by the walk back, below. A move that throws fails
      // the test with its error (`try`, not `try?`).
      var heading: [String] = []
      var last = ""
      var run = 0
      for _ in 0..<40 where run < endRun {
        let text = normalized(try voiceOver.moveForward().utterance)
        if text == last {
          run += 1
        } else {
          last = text
          run = 1
        }
        if heading.last != "Example Heading" { heading.append(text) }
      }
      // Swipe left from there to the "Example" heading. This is the record
      // of the example: every element once, last to first.
      var backward: [String] = []
      var reachedHeading = false
      if run == endRun {
        for _ in 0..<40 {
          let text = normalized(try voiceOver.moveBackward().utterance)
          if text == "Example Heading" {
            reachedHeading = true
            break
          }
          backward.append(text)
        }
      }
      try voiceOver.disable()
      voiceOverOn = false
      XCTAssertEqual(run, endRun, "\(example.slug): the walk did not come to rest")
      XCTAssertTrue(reachedHeading, "\(example.slug): the walk back did not reach the heading")
      let content = S03DecorativeImagesUITests.exampleContent(
        last: last, forwardRun: run, backward: backward)
      XCTAssertNotNil(content, "\(example.slug): the end of the screen was not shown")
      print("S03VO \(example.slug) | \((heading + (content ?? [])).joined(separator: " / "))")
      XCTAssertEqual(content, example.spoken, example.slug)
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}
