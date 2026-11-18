// L3 (tree) and L4 (VoiceOver) for F02 Input instructions on iOS.
// Spec: docs/specs/F02-input-instructions.md.
//
// iOS keeps a field's hint apart from its label. XCUITest has no way to read
// a hint, so the tree tests check the label, the value, and the instruction
// as text on the screen, and the hint itself is checked in what VoiceOver
// says. In the tree a good field and `bad-helper-only` look the same; only
// VoiceOver tells them apart.
import XCTest

final class F02InputInstructionsUITests: XCTestCase, CountedTechniqueUITest {
  static let technique = "F02"
  static let countLabel = "Changes"
  let app = XCUIApplication()

  override func setUp() {
    continueAfterFailure = true
  }

  /// Opens an example and waits for its count.
  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    open(slug, waitingFor: countElement(slug), file: file, line: line)
  }

  /// Types into a field and leaves it with Return, so the keyboard is gone.
  private func type(_ text: String, into id: String) {
    let field = element(id)
    field.tap()
    field.typeText(text + "\n")
    let deadline = Date().addingTimeInterval(5)
    while (field.value as? String) != text && Date() < deadline { usleep(100_000) }
  }

  private static let username = "Username"
  private static let rule = "4 to 10 characters, no spaces."
  private static let displayRule = "Shown on your posts. 2 to 30 letters or numbers."

  /// Fields with "Username" as their name and the rule on the screen.
  private let usernames: [(slug: String, id: String)] = [
    ("good-helper", "f02-good-helper-username"),
    ("good-cupertino", "f02-good-cupertino-username"),
    ("good-before", "f02-good-before-username"),
    ("bad-helper-only", "f02-bad-helper-only-username"),
  ]

  func testFieldsKeepTheirLabelAndTheInstructionIsText() {
    for field in usernames {
      open(field.slug)
      let element = element(field.id)
      XCTAssertEqual(element.elementType, .textField, field.slug)
      XCTAssertEqual(element.label, Self.username, field.slug)
      // The instruction is static text of its own, once, and not part of
      // the label.
      XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label == %@", Self.rule)).count, 1, field.slug)
      type("abc", into: field.id)
      XCTAssertEqual(self.element(field.id).value as? String, "abc", field.slug)
      XCTAssertEqual(self.element(field.id).label, Self.username, field.slug)
      XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label == %@", Self.rule)).count, 1, field.slug)
      expectCount(field.slug, 3)
    }
  }

  func testGoodBeforeShowsTheInstructionAboveTheField() {
    open("good-before")
    let rule = app.staticTexts.matching(NSPredicate(format: "label == %@", Self.rule)).firstMatch
    let field = element("f02-good-before-username")
    XCTAssertTrue(rule.exists)
    XCTAssertLessThanOrEqual(rule.frame.maxY, field.frame.minY)
  }

  func testBadPlaceholderFormatIsInTheLabelOnlyWhileEditingAnEmptyField() {
    open("bad-placeholder-format")
    let id = "f02-bad-placeholder-format-birthday"
    XCTAssertEqual(element(id).label, "Date of birth")
    let withFormat = { self.app.descendants(matching: .any)
      .matching(NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", "DD/MM", "DD/MM")).count }
    XCTAssertEqual(withFormat(), 0)
    // Editing and empty: the placeholder is added to the label.
    element(id).tap()
    let deadline = Date().addingTimeInterval(5)
    while element(id).label == "Date of birth" && Date() < deadline { usleep(100_000) }
    XCTAssertEqual(element(id).label, "Date of birth\nDD/MM/YYYY")
    // One character in, and it is gone.
    element(id).typeText("1\n")
    let typed = Date().addingTimeInterval(5)
    while (element(id).value as? String) != "1" && Date() < typed { usleep(100_000) }
    XCTAssertEqual(element(id).label, "Date of birth")
    XCTAssertEqual(withFormat(), 0)
    expectCount("bad-placeholder-format", 1)
  }

  func testBadHelperCutOffHasTheWholeInstructionInTheTree() {
    // The defect is on the screen: at 200% text the helper is cut to one
    // line. The simulator runs at the default text size, and the tree holds
    // the whole text either way, so the cut cannot be seen here; the widget
    // tests assert it.
    open("bad-helper-cut-off")
    XCTAssertEqual(element("f02-bad-helper-cut-off-name").label, "Display name")
    XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label == %@", Self.displayRule)).count, 1)
  }

  // L4. Everything VoiceOver says between the "Example" heading and the
  // change count, which is the last element of every example. The walk is
  // VoiceOverWalk.forward. XCUIVoiceOverService returns at most the first 64
  // characters of an utterance, which cuts the field lines short. A walk
  // with a field id is made after "abc" has been typed into that field.
  private static let field = "Username Text field 4 to 10 characters, no spaces. Double tap to"
  private let speech: [(slug: String, fill: String?, content: [String])] = [
    // The hint is read after the role; the helper text is a stop of its own.
    ("good-helper", nil, [field, rule]),
    // On iOS the hint is still read once the field has a value.
    ("good-helper", "f02-good-helper-username",
     ["Username abc Text field 4 to 10 characters, no spaces. Double ta", rule]),
    ("good-cupertino", nil, [field, rule]),
    // The instruction is read before the field, and again as its hint.
    ("good-before", nil, [rule, field]),
    // Bad examples: the defect must be audible.
    ("bad-helper-only", nil, ["Username Text field Double tap to edit.", rule]),
    ("bad-helper-only", "f02-bad-helper-only-username",
     ["Username abc Text field Double tap to edit.", rule]),
    ("bad-placeholder-format", nil, ["Date of birth Text field Double tap to edit."]),
    // VoiceOver hears all of it; the screen cuts it (widget tests).
    ("bad-helper-cut-off", nil,
     ["Display name Text field Shown on your posts. 2 to 30 letters or", displayRule]),
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
      if let id = example.fill { type("abc", into: id) }
      let name = example.slug + (example.fill == nil ? "" : "+filled")
      // Swipe right until the change count, the last element, is read.
      let spoken = try VoiceOverWalk.forward(voiceOver, toUtteranceStartingWith: "Changes:")
      let content = Self.exampleContent(spoken)
      print("F02VO \(name) | \((content ?? spoken).joined(separator: " / "))")
      XCTAssertNotNil(content, "\(name): the walk did not run from the heading to the count: \(spoken)")
      XCTAssertEqual(content, example.content, name)
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}
