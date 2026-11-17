// L3 (tree) and L4 (VoiceOver) for S14 Values and state descriptions on iOS.
// Spec: docs/specs/S14-values-and-state-descriptions.md.
//
// iOS keeps an element's value apart from its label, and XCUITest reads
// both.
import XCTest

final class S14ValuesAndStateDescriptionsUITests: XCTestCase, CountedTechniqueUITest {
  static let technique = "S14"
  static let countLabel = "Changes"
  let app = XCUIApplication()

  override func setUp() {
    continueAfterFailure = true
  }

  /// Opens an example and waits for its count.
  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    open(slug, waitingFor: countElement(slug), file: file, line: line)
  }

  private func value(_ id: String) -> String {
    element(id).value as? String ?? ""
  }

  /// Taps the fifth star of a rating: the stars are 48 points wide and the
  /// element is a little wider than the five of them.
  private func tapFifthStar(_ id: String) {
    element(id).coordinate(withNormalizedOffset: CGVector(dx: 0.88, dy: 0.5)).tap()
  }

  func testGoodRatingHasItsValue() {
    open("good-rating")
    let id = "s14-good-rating-rating"
    XCTAssertEqual(element(id).label, "Rating")
    XCTAssertEqual(value(id), "3 out of 5")
    tapFifthStar(id)
    expectCount("good-rating", 1)
    XCTAssertEqual(value(id), "5 out of 5")
    XCTAssertEqual(element(id).label, "Rating")
  }

  func testGoodStepHasItsValue() {
    open("good-step")
    let id = "s14-good-step-progress"
    XCTAssertEqual(element(id).label, "Progress")
    XCTAssertEqual(value(id), "Step 2 of 4")
    for n in ["1", "2", "3", "4"] { XCTAssertFalse(app.staticTexts[n].exists, n) }
    element("s14-good-step-next").tap()
    expectCount("good-step", 1)
    XCTAssertEqual(value(id), "Step 3 of 4")
  }

  func testGoodButtonValueFollowsTheMode() {
    open("good-button-value")
    let id = "s14-good-button-value-repeat"
    XCTAssertEqual(element(id).elementType, .button)
    var n = 0
    for mode in ["Off", "All", "One", "Off"] {
      XCTAssertEqual(element(id).label, "Repeat")
      XCTAssertEqual(value(id), mode)
      element(id).tap()
      n += 1
      expectCount("good-button-value", n)
    }
  }

  func testGoodSliderFormatIsInMinutes() {
    open("good-slider-format")
    let id = "s14-good-slider-format-timer"
    XCTAssertEqual(element(id).label, "Timer")
    XCTAssertEqual(value(id), "15 minutes")
  }

  // Each bad example is asserted to have its named defect.

  func testBadRatingNoValueHasNoValue() {
    open("bad-rating-no-value")
    let id = "s14-bad-rating-no-value-rating"
    XCTAssertEqual(element(id).label, "Rating")
    XCTAssertEqual(value(id), "")
    tapFifthStar(id)
    expectCount("bad-rating-no-value", 1)
    XCTAssertEqual(value(id), "")
  }

  func testBadStaleValueKeepsItsFirstValue() {
    open("bad-stale-value")
    let id = "s14-bad-stale-value-rating"
    XCTAssertEqual(value(id), "3 out of 5")
    tapFifthStar(id)
    expectCount("bad-stale-value", 1)
    XCTAssertEqual(value(id), "3 out of 5")
  }

  func testBadStepNoValueIsFourNumbers() {
    open("bad-step-no-value")
    for n in ["1", "2", "3", "4"] {
      let e = app.staticTexts[n]
      XCTAssertTrue(e.exists, n)
      XCTAssertEqual(e.value as? String ?? "", "", n)
      XCTAssertFalse(e.isSelected, n)
    }
    XCTAssertFalse(app.descendants(matching: .any)["Progress"].exists)
  }

  func testBadButtonNoValueHasNoValueInAnyMode() {
    open("bad-button-no-value")
    let id = "s14-bad-button-no-value-repeat"
    for n in 1...3 {
      XCTAssertEqual(element(id).elementType, .button)
      XCTAssertEqual(element(id).label, "Repeat")
      XCTAssertEqual(value(id), "")
      XCTAssertFalse(element(id).isSelected)
      element(id).tap()
      expectCount("bad-button-no-value", n)
    }
  }

  func testBadValueOnSwitchIgnoresTheValue() {
    open("bad-value-on-switch")
    let id = "s14-bad-value-on-switch-alarm"
    XCTAssertEqual(element(id).elementType, .switch)
    XCTAssertEqual(element(id).label, "Home alarm")
    // Flutter 3.47.5: the switch's own 0 or 1 wins; "Deactivated" is not
    // exposed (FL-036).
    XCTAssertEqual(value(id), "0")
    element(id).tap()
    expectCount("bad-value-on-switch", 1)
    XCTAssertEqual(value(id), "1")
  }

  // L4. Everything VoiceOver says between the "Example" heading and the
  // change count, which is the last element of every example. The walk
  // is VoiceOverWalk.forward. XCUIVoiceOverService returns at most the
  // first 64 characters of an utterance, which cuts the hint of an
  // adjustable element short.
  private let speech: [(slug: String, content: [String])] = [
    ("good-rating", ["Rating 3 out of 5 adjustable Swipe up or down with one finger to"]),
    ("good-step", ["Progress Step 2 of 4", "Next step Button"]),
    ("good-button-value", ["Repeat Off Button"]),
    ("good-slider-format", ["Timer 15 minutes adjustable Swipe up or down with one finger to"]),
    // Bad examples: the defect must be audible.
    ("bad-rating-no-value", ["Rating adjustable Swipe up or down with one finger to adjust the"]),
    // Read as the good rating is: the tree test changes the rating and
    // finds the value unchanged.
    ("bad-stale-value", ["Rating 3 out of 5 adjustable Swipe up or down with one finger to"]),
    ("bad-step-no-value", ["1", "2", "3", "4", "Next step Button"]),
    ("bad-button-no-value", ["Repeat Button"]),
    // "Deactivated" is not read (FL-036).
    ("bad-value-on-switch", ["Home alarm Switch button off Double tap to toggle setting."]),
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
      // Swipe right until the change count, the last element, is read.
      let spoken = try VoiceOverWalk.forward(voiceOver, toUtteranceStartingWith: "Changes:")
      let content = Self.exampleContent(spoken)
      print("S14VO \(example.slug) | \((content ?? spoken).joined(separator: " / "))")
      XCTAssertNotNil(content, "\(example.slug): the walk did not run from the heading to the count: \(spoken)")
      XCTAssertEqual(content, example.content, example.slug)
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}
