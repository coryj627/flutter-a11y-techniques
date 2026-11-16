// L3 (tree) and L4 (VoiceOver) for S15 Hints on iOS.
// Spec: docs/specs/S15-hints.md.
//
// iOS keeps an element's hint apart from its label. XCUITest has no way to
// read a hint, so the tree tests check that the hint is not in the label,
// and the hint itself is checked in what VoiceOver says.
import XCTest

final class S15HintsUITests: XCTestCase, CountedTechniqueUITest {
  static let technique = "S15"
  static let countLabel = "Changes"
  let app = XCUIApplication()

  override func setUp() {
    continueAfterFailure = true
  }

  /// Opens an example and waits for its count.
  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    open(slug, waitingFor: countElement(slug), file: file, line: line)
  }

  private static let rule = "3 to 12 letters or numbers."

  // slug, identifier, label
  private let buttons: [(slug: String, id: String, label: String)] = [
    ("good-result", "s15-good-result-favorite", "Favorite"),
    ("good-row", "s15-good-row-song", "Night Ferry\nThe Lanterns"),
    ("good-cupertino", "s15-good-cupertino-share", "Share"),
    ("good-custom", "s15-good-custom-archive", "Archive"),
    ("bad-gesture", "s15-bad-gesture-favorite", "Favorite"),
    ("bad-repeats-label", "s15-bad-repeats-label-delete", "Delete"),
    ("bad-control-type", "s15-bad-control-type-share", "Share"),
    ("bad-no-hint", "s15-bad-no-hint-song", "Night Ferry\nThe Lanterns"),
  ]

  func testButtonsKeepTheHintOutOfTheLabel() {
    for button in buttons {
      open(button.slug)
      let element = element(button.id)
      XCTAssertEqual(element.elementType, .button, button.slug)
      XCTAssertEqual(element.label, button.label, button.slug)
      XCTAssertEqual(element.value as? String ?? "", "", button.slug)
      element.tap()
      expectCount(button.slug, 1)
      XCTAssertEqual(self.element(button.id).label, button.label, button.slug)
    }
  }

  func testGoodFieldShowsTheRuleAsText() {
    open("good-field")
    let field = element("s15-good-field-username")
    XCTAssertEqual(field.elementType, .textField)
    XCTAssertEqual(field.label, "Username")
    XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label == %@", Self.rule)).count, 1)
  }

  func testBadHintOnlyDoesNotShowTheRule() {
    open("bad-hint-only")
    XCTAssertEqual(element("s15-bad-hint-only-username").label, "Username")
    let withRule = app.descendants(matching: .any)
      .matching(NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", "3 to 12", "3 to 12"))
    XCTAssertEqual(withRule.count, 0)
  }

  func testBadHintDetachedButtonStillWorks() {
    open("bad-hint-detached")
    let button = app.buttons["Favorite"]
    XCTAssertTrue(button.exists)
    // The hint is in no label: where it went is heard in the VoiceOver walk.
    let withHint = app.descendants(matching: .any)
      .matching(NSPredicate(format: "label CONTAINS %@", "Adds this item"))
    XCTAssertEqual(withHint.count, 0)
    button.tap()
    expectCount("bad-hint-detached", 1)
  }

  // L4. Everything VoiceOver says between the "Example" heading and the
  // change count, which is the last element of every example. The walk
  // is VoiceOverWalk.forward. XCUIVoiceOverService returns at most the
  // first 64 characters of an utterance, which cuts the longest of these
  // short.
  private let speech: [(slug: String, content: [String])] = [
    ("good-result", ["Favorite Button Adds this item to your favorites."]),
    ("good-row", ["Night Ferry The Lanterns Button Plays the song."]),
    ("good-cupertino", ["Share Button Shares the current page."]),
    ("good-custom", ["Archive Button Moves this message out of the inbox."]),
    ("good-field", ["Username Text field 3 to 12 letters or numbers. Double tap to ed", rule]),
    // Bad examples: the defect must be audible.
    ("bad-gesture", ["Favorite Button Double tap to add this item to your favorites."]),
    // VoiceOver does not read a hint that is the same as the label, so
    // this defect cannot be heard on iOS.
    ("bad-repeats-label", ["Delete Button"]),
    ("bad-control-type", ["Share Button This button shares the current page."]),
    ("bad-no-hint", ["Night Ferry The Lanterns Button"]),
    // The hint is a stop of its own, and the button has none (FL-040).
    ("bad-hint-detached", ["Adds this item to your favorites.", "Favorite Button"]),
    // Read as the good field is: the tree test finds no rule on the screen.
    ("bad-hint-only", ["Username Text field 3 to 12 letters or numbers. Double tap to ed"]),
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
      print("S15VO \(example.slug) | \((content ?? spoken).joined(separator: " / "))")
      XCTAssertNotNil(content, "\(example.slug): the walk did not run from the heading to the count: \(spoken)")
      XCTAssertEqual(content, example.content, example.slug)
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}
