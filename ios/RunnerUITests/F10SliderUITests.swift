// L3 (tree) and L4 (VoiceOver) for F10 Slider on iOS.
// Spec: docs/specs/F10-slider.md.
//
// A Flutter slider is an adjustable element, which XCUITest reports as
// type Other with a label and a value, not as a Slider. XCUITest cannot
// send the adjust gesture to it or read its traits, so the value is set by
// tapping and dragging, and "adjustable" is checked in what VoiceOver
// says. The keyboard is not checked on iOS.
import XCTest

final class F10SliderUITests: XCTestCase, CountedTechniqueUITest {
  static let technique = "F10"
  static let countLabel = "Changes"
  let app = XCUIApplication()

  override func setUp() {
    continueAfterFailure = true
  }

  /// Opens an example and waits for its count.
  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    open(slug, waitingFor: countElement(slug), file: file, line: line)
  }

  private func sliderId(_ slug: String) -> String {
    slug.hasSuffix("value-text") || slug.hasSuffix("percent-value") ? "f10-\(slug)-rating" : "f10-\(slug)-volume"
  }

  private func slider(_ slug: String) -> XCUIElement { element(sliderId(slug)) }

  private func value(_ slug: String) -> String { slider(slug).value as? String ?? "" }

  private func expectValue(_ slug: String, _ expected: String, file: StaticString = #filePath, line: UInt = #line) {
    let deadline = Date().addingTimeInterval(5)
    while value(slug) != expected && Date() < deadline { usleep(100_000) }
    XCTAssertEqual(value(slug), expected, slug, file: file, line: line)
  }

  /// Where a tap or a drag reaches the track, at `along` of its width. A
  /// custom slider's element is the text above the track as well, inside a
  /// focus ring 8 points wide; its track is the bottom 48 points inside it.
  private func trackPoint(_ slug: String, _ along: CGFloat) -> XCUICoordinate {
    let element = slider(slug)
    let frame = element.frame
    let origin = element.coordinate(withNormalizedOffset: .zero)
    if ["good-custom", "bad-no-keyboard", "bad-drag-only"].contains(slug) {
      return origin.withOffset(CGVector(dx: 8 + (frame.width - 16) * along, dy: frame.height - 8 - 24))
    }
    return origin.withOffset(CGVector(dx: frame.width * along, dy: frame.height / 2))
  }

  // slug -> (label, value at the start).
  private let examples: [(slug: String, label: String, value: String)] = [
    ("good-material", "Volume", "40%"),
    ("good-cupertino", "Volume", "40%"),
    ("good-custom", "Volume", "40%"),
    ("good-value-text", "Rating", "4 out of 10"),
    ("bad-unlabelled", "", "40%"),
    ("bad-indicator-label", "Volume\n4", "40%"),
    ("bad-percent-value", "Rating", "40%"),
    ("bad-no-keyboard", "Volume", "40%"),
    ("bad-drag-only", "Volume", "40%"),
  ]

  func testEverySliderHasItsLabelAndValue() {
    for example in examples {
      open(example.slug)
      let element = slider(example.slug)
      XCTAssertEqual(element.elementType, .other, example.slug)
      XCTAssertEqual(element.label, example.label, example.slug)
      XCTAssertEqual(value(example.slug), example.value, example.slug)
      XCTAssertTrue(element.isEnabled, example.slug)
      // No element is a Slider to XCUITest: Flutter's are adjustable
      // elements of type Other.
      XCTAssertEqual(app.sliders.count, 0, example.slug)
    }
  }

  func testATapOnTheTrackSetsTheValue() {
    for (slug, expected) in [
      ("good-material", "100%"), ("good-custom", "100%"), ("good-value-text", "10 out of 10"),
    ] {
      open(slug)
      trackPoint(slug, 0.99).tap()
      expectValue(slug, expected)
      expectCount(slug, 1)
    }
  }

  func testGoodCupertinoIgnoresATapOnTheTrackAndHasStepButtons() {
    open("good-cupertino")
    // A CupertinoSlider answers a drag of its thumb only (FL-121).
    trackPoint("good-cupertino", 0.95).tap()
    sleep(1)
    XCTAssertEqual(value("good-cupertino"), "40%")
    expectCount("good-cupertino", 0)
    XCTAssertEqual(element("f10-good-cupertino-up").elementType, .button)
    XCTAssertEqual(element("f10-good-cupertino-up").label, "Volume up")
    XCTAssertEqual(element("f10-good-cupertino-down").label, "Volume down")
    element("f10-good-cupertino-up").tap()
    expectValue("good-cupertino", "50%")
    element("f10-good-cupertino-down").tap()
    element("f10-good-cupertino-down").tap()
    expectValue("good-cupertino", "30%")
  }

  // Each bad example is asserted to have its named defect.

  func testBadUnlabelledHasTheTextApart() {
    open("bad-unlabelled")
    XCTAssertEqual(slider("bad-unlabelled").label, "")
    XCTAssertTrue(app.staticTexts["Volume"].exists)
  }

  func testBadIndicatorLabelChangesItsLabel() {
    open("bad-indicator-label")
    trackPoint("bad-indicator-label", 0.99).tap()
    expectValue("bad-indicator-label", "100%")
    XCTAssertEqual(slider("bad-indicator-label").label, "Volume\n10")
  }

  func testBadPercentValueIsAPercentage() {
    open("bad-percent-value")
    XCTAssertEqual(value("bad-percent-value"), "40%")
    trackPoint("bad-percent-value", 0.99).tap()
    expectValue("bad-percent-value", "100%")
  }

  func testBadDragOnlyIgnoresATapAndFollowsADrag() {
    open("bad-drag-only")
    trackPoint("bad-drag-only", 0.99).tap()
    trackPoint("bad-drag-only", 0.01).tap()
    sleep(1)
    XCTAssertEqual(value("bad-drag-only"), "40%")
    expectCount("bad-drag-only", 0)
    trackPoint("bad-drag-only", 0.4).press(forDuration: 0.1, thenDragTo: trackPoint("bad-drag-only", 0.99))
    expectValue("bad-drag-only", "100%")
  }

  // L4. Everything VoiceOver says between the "Example" heading and the
  // change count, which is the last element of every example. The walk is
  // VoiceOverWalk.forward. XCUIVoiceOverService returns at most the first
  // 64 characters of an utterance, which cuts the hint of an adjustable
  // element short; `adjustable` cuts the expected text the same way.
  private static func adjustable(_ text: String) -> String {
    let whole = "\(text) adjustable Swipe up or down with one finger to adjust the value."
    return String(whole.prefix(64)).trimmingCharacters(in: .whitespaces)
  }

  private let speech: [(slug: String, content: [String])] = [
    ("good-material", [adjustable("Volume 40%")]),
    ("good-cupertino", [adjustable("Volume 40%"), "Volume down Button", "Volume up Button"]),
    ("good-custom", [adjustable("Volume 40%")]),
    ("good-value-text", [adjustable("Rating 4 out of 10")]),
    // Bad examples: the defect must be audible where it can be.
    ("bad-unlabelled", ["Volume", adjustable("40%")]),
    ("bad-indicator-label", [adjustable("Volume 4 40%")]),
    ("bad-percent-value", [adjustable("Rating 40%")]),
    // The keyboard and pointer defects are not heard.
    ("bad-no-keyboard", [adjustable("Volume 40%")]),
    ("bad-drag-only", [adjustable("Volume 40%")]),
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
      print("F10VO \(example.slug) | \((content ?? spoken).joined(separator: " / "))")
      XCTAssertNotNil(content, "\(example.slug): the walk did not run from the heading to the count: \(spoken)")
      XCTAssertEqual(content, example.content, example.slug)
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}
