// L3 (tree) and L4 (VoiceOver) for S22 Semantics identifiers for testing
// on iOS. Spec: docs/specs/S22-semantics-identifiers.md.
//
// On iOS `Semantics(identifier:)` is the element's accessibilityIdentifier,
// which XCUITest finds elements by and VoiceOver does not read.
import XCTest

final class S22SemanticsIdentifiersUITests: XCTestCase, CountedTechniqueUITest {
  static let technique = "S22"
  static let countLabel = "Changes"
  let app = XCUIApplication()

  override func setUp() {
    continueAfterFailure = true
  }

  /// Opens an example and waits for its count.
  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    open(slug, waitingFor: countElement(slug), file: file, line: line)
  }

  private func marked(_ id: String) -> XCUIElementQuery {
    app.descendants(matching: .any).matching(identifier: id)
  }

  /// No label or value on the screen contains an identifier.
  private func expectNoIdentifierInWhatIsRead(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    let leaked = app.descendants(matching: .any)
      .matching(NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", "s22-", "s22-"))
    XCTAssertEqual(leaked.count, 0, slug, file: file, line: line)
  }

  // slug, identifier, label
  private let buttons: [(slug: String, id: String, label: String)] = [
    ("good-merged", "s22-good-merged-save", "Save draft"),
    ("good-cupertino", "s22-good-cupertino-save", "Save draft"),
    ("good-custom", "s22-good-custom-save", "Save draft"),
    ("bad-id-as-name", "s22-bad-id-as-name-close", ""),
  ]

  func testTheElementWithTheIdentifierIsTheButton() {
    for button in buttons {
      open(button.slug)
      XCTAssertEqual(marked(button.id).count, 1, button.slug)
      let element = element(button.id)
      XCTAssertEqual(element.elementType, .button, button.slug)
      XCTAssertEqual(element.label, button.label, button.slug)
      XCTAssertEqual(element.value as? String ?? "", "", button.slug)
      expectNoIdentifierInWhatIsRead(button.slug)
      // The typed query finds the same element.
      XCTAssertTrue(app.buttons[button.id].exists, button.slug)
      element.tap()
      expectCount(button.slug, 1)
      XCTAssertEqual(self.element(button.id).label, button.label, button.slug)
    }
  }

  func testGoodFieldHasItsNameAndTheIdentifier() {
    open("good-field")
    let field = element("s22-good-field-project")
    XCTAssertEqual(field.elementType, .textField)
    XCTAssertEqual(field.label, "Project name")
    XCTAssertTrue(app.textFields["s22-good-field-project"].exists)
    expectNoIdentifierInWhatIsRead("good-field")
  }

  func testBadInsideLeavesTheButtonWithNoName() {
    open("bad-inside")
    // Flutter 3.47.5: the identifier makes the text an element of its own,
    // which takes the label out of the button (FL-007). Written to fail if
    // the identifier stops splitting the button.
    let text = element("s22-bad-inside-save")
    XCTAssertEqual(text.elementType, .staticText)
    XCTAssertEqual(text.label, "Save draft")
    XCTAssertFalse(app.buttons["s22-bad-inside-save"].exists)
    XCTAssertFalse(app.buttons["Save draft"].exists)
    // Back, and a button with no label and no identifier.
    let unnamed = app.buttons.matching(NSPredicate(format: "label == %@ AND identifier == %@", "", ""))
    XCTAssertEqual(unnamed.count, 1)
    unnamed.firstMatch.tap()
    expectCount("bad-inside", 1)
  }

  func testBadWrapperHasTheIdentifierOnAnElementThatIsNotTheButton() {
    open("bad-wrapper")
    // Flutter 3.47.5: FilledButton is a semantics container, so the
    // identifier stays on an element of its own. On iOS that element is a
    // sibling of the button, not its parent, so the button cannot be
    // reached through it. Written to fail if either changes.
    let wrapper = element("s22-bad-wrapper-save")
    XCTAssertEqual(marked("s22-bad-wrapper-save").count, 1)
    XCTAssertEqual(wrapper.elementType, .other)
    XCTAssertEqual(wrapper.label, "")
    XCTAssertFalse(app.buttons["s22-bad-wrapper-save"].exists)
    XCTAssertEqual(wrapper.descendants(matching: .button).count, 0)
    let button = app.buttons["Save draft"]
    XCTAssertTrue(button.exists)
    XCTAssertEqual(button.identifier, "")
    XCTAssertEqual(button.frame, wrapper.frame)
    button.tap()
    expectCount("bad-wrapper", 1)
  }

  func testBadDuplicateHasTwoButtonsWithOneIdentifier() {
    open("bad-duplicate")
    let both = app.buttons.matching(identifier: "s22-bad-duplicate-action")
    XCTAssertEqual(both.count, 2)
    XCTAssertEqual(both.element(boundBy: 0).label, "Save draft")
    XCTAssertEqual(both.element(boundBy: 1).label, "Discard draft")
  }

  // L4. Everything VoiceOver says between the "Example" heading and the
  // change count, which is the last element of every example. The walk
  // is VoiceOverWalk.forward. No utterance may contain an identifier.
  private let speech: [(slug: String, content: [String])] = [
    ("good-merged", ["Save draft Button"]),
    ("good-cupertino", ["Save draft Button"]),
    ("good-custom", ["Save draft Button"]),
    ("good-field", ["Project name Text field Double tap to edit."]),
    // Bad examples: the defect must be audible where there is one to hear.
    // The button has no name, and its text is a stop of its own (FL-007).
    ("bad-inside", ["Button", "Save draft"]),
    // Nothing is different for a VoiceOver user in these two.
    ("bad-wrapper", ["Save draft Button"]),
    ("bad-duplicate", ["Save draft Button", "Discard draft Button"]),
    // The identifier is not a name.
    ("bad-id-as-name", ["Button"]),
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
      print("S22VO \(example.slug) | \((content ?? spoken).joined(separator: " / "))")
      XCTAssertNotNil(content, "\(example.slug): the walk did not run from the heading to the count: \(spoken)")
      XCTAssertEqual(content, example.content, example.slug)
      XCTAssertFalse(spoken.contains { $0.lowercased().contains("s22") }, "\(example.slug): \(spoken)")
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}
