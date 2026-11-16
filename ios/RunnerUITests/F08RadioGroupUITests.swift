// L3 (tree) and L4 (VoiceOver) for F08 Radio group on iOS.
// Spec: docs/specs/F08-radio-group.md.
//
// iOS has no radio button. Flutter exposes one as a button (FL-047): the
// chosen one is selected, and Flutter's radio widgets give the others the
// hint "Not selected". XCUITest sees `.button` and `isSelected`; it cannot
// read a hint, so that is checked in what VoiceOver says.
import XCTest

final class F08RadioGroupUITests: XCTestCase, CountedTechniqueUITest {
  static let technique = "F08"
  static let countLabel = "Changes"
  let app = XCUIApplication()

  override func setUp() {
    continueAfterFailure = true
  }

  /// Opens an example and waits for its count.
  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    open(slug, waitingFor: countElement(slug), file: file, line: line)
  }

  private let options: [(id: String, label: String)] = [
    ("standard", "Standard"), ("express", "Express"), ("next-day", "Next day"),
  ]

  /// The id segments of the options that are selected.
  private func selected(_ slug: String) -> [String] {
    options.map(\.id).filter { element("f08-\(slug)-\($0)").isSelected }
  }

  private func expectSelected(_ slug: String, _ expected: [String], file: StaticString = #filePath, line: UInt = #line) {
    let deadline = Date().addingTimeInterval(5)
    while selected(slug) != expected && Date() < deadline { usleep(100_000) }
    XCTAssertEqual(selected(slug), expected, slug, file: file, line: line)
  }

  // Examples built on Flutter's radio widgets, "Express" chosen.
  private let radioExamples = ["good-group", "good-cupertino", "good-custom", "bad-group-unlabelled"]

  func testRadioButtonsAreButtonsWithOneSelected() {
    for slug in radioExamples {
      open(slug)
      for option in options {
        let element = element("f08-\(slug)-\(option.id)")
        // Flutter 3.47.5: a radio button is a button on iOS (FL-047).
        // Written to fail if the type changes.
        XCTAssertEqual(element.elementType, .button, "\(slug) \(option.id)")
        XCTAssertEqual(element.label, option.label, "\(slug) \(option.id)")
        XCTAssertEqual(element.value as? String ?? "", "", "\(slug) \(option.id)")
        XCTAssertTrue(element.isEnabled, "\(slug) \(option.id)")
        // The label is part of the control, not a text element of its own.
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label == %@", option.label)).count, 0, slug)
      }
      expectSelected(slug, ["express"])
      element("f08-\(slug)-standard").tap()
      expectSelected(slug, ["standard"])
      element("f08-\(slug)-next-day").tap()
      expectSelected(slug, ["next-day"])
      expectCount(slug, 2)
    }
  }

  func testGoodExamplesHaveTheQuestionAsOneElement() {
    for (slug, question) in [
      ("good-group", "Delivery speed"), ("good-cupertino", "Delivery speed"),
      ("good-custom", "Delivery speed"), ("good-context", "Are you at home?"),
    ] {
      open(slug)
      // The question is the name of the radio group, which iOS shows as an
      // element of type Other and not as static text.
      let withQuestion = app.descendants(matching: .any)
        .matching(NSPredicate(format: "label == %@", question))
      XCTAssertEqual(withQuestion.count, 1, slug)
      XCTAssertEqual(withQuestion.firstMatch.elementType, .other, slug)
      XCTAssertFalse(app.staticTexts[question].exists, slug)
    }
  }

  func testGoodContextAnswersCarryTheQuestion() {
    open("good-context")
    XCTAssertEqual(element("f08-good-context-yes").label, "Yes, I am at home")
    XCTAssertEqual(element("f08-good-context-no").label, "No, I am not at home")
    XCTAssertTrue(element("f08-good-context-no").isSelected)
    XCTAssertFalse(element("f08-good-context-yes").isSelected)
  }

  func testBadUnlabelledHasButtonsWithNoLabel() {
    open("bad-unlabelled")
    // Back, and three radio buttons with no label.
    let unnamed = app.buttons.matching(NSPredicate(format: "label == %@", ""))
    XCTAssertEqual(unnamed.count, 3)
    XCTAssertFalse(app.buttons["Standard"].exists)
  }

  func testBadGroupUnlabelledHasTheQuestionAsPlainText() {
    open("bad-group-unlabelled")
    XCTAssertTrue(app.staticTexts["Delivery speed"].exists)
    XCTAssertEqual(app.otherElements.matching(NSPredicate(format: "label == %@", "Delivery speed")).count, 0)
  }

  func testBadNoStateHasButtonsNoneSelected() {
    open("bad-no-state")
    for pass in 0..<2 {
      for option in options {
        let element = element("f08-bad-no-state-\(option.id)")
        XCTAssertEqual(element.elementType, .button, "\(pass) \(option.id)")
        XCTAssertEqual(element.label, option.label)
        XCTAssertFalse(element.isSelected, "\(pass) \(option.id)")
        XCTAssertEqual(element.value as? String ?? "", "")
      }
      element("f08-bad-no-state-standard").tap()
      expectCount("bad-no-state", 1)
    }
  }

  func testBadCheckboxRoleHasSwitches() {
    open("bad-checkbox-role")
    // A checkbox is a switch on iOS (FL-035).
    XCTAssertEqual(app.switches.count, 3)
    XCTAssertEqual(element("f08-bad-checkbox-role-express").value as? String, "1")
    XCTAssertEqual(element("f08-bad-checkbox-role-standard").value as? String, "0")
  }

  func testBadCheckedOnlyHasButtonsNoneSelected() {
    open("bad-checked-only")
    for option in options {
      let element = element("f08-bad-checked-only-\(option.id)")
      XCTAssertEqual(element.elementType, .button, option.id)
      XCTAssertEqual(element.label, option.label, option.id)
      // Flutter 3.47.5: the iOS engine reads neither `checked` nor a radio
      // role for a node in a mutually exclusive group (FL-047). "Express"
      // is chosen and nothing says so. Written to fail if that changes.
      XCTAssertFalse(element.isSelected, option.id)
      XCTAssertEqual(element.value as? String ?? "", "", option.id)
    }
  }

  // L4. Everything VoiceOver says between the "Example" heading and the
  // change count, which is the last element of every example. The walk
  // is VoiceOverWalk.forward.
  private let speech: [(slug: String, content: [String])] = [
    // The question is a stop of its own. A radio button is read as a
    // button: "selected" before the chosen one, and the hint "Not
    // selected" after the others (FL-047).
    ("good-group", [
      "Delivery speed",
      "Standard Button Not selected",
      "selected Express Button",
      "Next day Button Not selected",
    ]),
    ("good-cupertino", [
      "Delivery speed",
      "Standard Button Not selected",
      "selected Express Button",
      "Next day Button Not selected",
    ]),
    ("good-custom", [
      "Delivery speed",
      "Standard Button Not selected",
      "selected Express Button",
      "Next day Button Not selected",
    ]),
    ("good-context", [
      "Are you at home?",
      "Yes, I am at home Button Not selected",
      "selected No, I am not at home Button",
    ]),
    // Bad examples: the defect must be audible where it can be.
    // The three texts are read as one stop, then three unnamed buttons.
    ("bad-unlabelled", [
      "Delivery speed",
      "Standard Express Next day",
      "Not selected Button",
      "selected Button",
      "Not selected Button",
    ]),
    // The same words as good-group: read in order, the question comes
    // first either way. The difference is in the tree.
    ("bad-group-unlabelled", [
      "Delivery speed",
      "Standard Button Not selected",
      "selected Express Button",
      "Next day Button Not selected",
    ]),
    ("bad-no-state", ["Delivery speed", "Standard Button", "Express Button", "Next day Button"]),
    // A checkbox is a switch on iOS (FL-035).
    ("bad-checkbox-role", [
      "Delivery speed",
      "Standard Switch button off Double tap to toggle setting.",
      "Express Switch button on Double tap to toggle setting.",
      "Next day Switch button off Double tap to toggle setting.",
    ]),
    // "Express" is chosen and nothing says so (FL-047). Written to fail if
    // VoiceOver starts to say a state here.
    ("bad-checked-only", ["Delivery speed", "Standard Button", "Express Button", "Next day Button"]),
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
      print("F08VO \(example.slug) | \((content ?? spoken).joined(separator: " / "))")
      XCTAssertNotNil(content, "\(example.slug): the walk did not run from the heading to the count: \(spoken)")
      XCTAssertEqual(content, example.content, example.slug)
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}
