// L3 (tree) and L4 (VoiceOver) for F08 Radio group on iOS.
// Spec: docs/specs/F08-radio-group.md.
//
// iOS has no radio button. Flutter exposes one as a button (FL-047): the
// chosen one is selected, and Flutter's radio widgets give the others the
// hint "Not selected". XCUITest sees `.button` and `isSelected`; it cannot
// read a hint, so that is checked in what VoiceOver says.
import XCTest

final class F08RadioGroupUITests: XCTestCase {
  private let app = XCUIApplication()

  override func setUp() {
    continueAfterFailure = true
  }

  /// Cold-starts the app on one example through the `fluttera11y` URL scheme,
  /// trying up to three times (see C01ButtonUITests.open).
  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    let url = URL(string: "fluttera11y:///t/F08/\(slug)")!
    for attempt in 1...3 {
      app.terminate()
      app.open(url)
      if element("f08-\(slug)-count").waitForExistence(timeout: 30) { return }
      print("F08 open \(slug): attempt \(attempt) did not show the example")
    }
    XCTFail("\(slug) did not open after three attempts", file: file, line: line)
  }

  private func element(_ id: String) -> XCUIElement {
    app.descendants(matching: .any)[id]
  }

  private func expectCount(_ slug: String, _ n: Int, file: StaticString = #filePath, line: UInt = #line) {
    let count = element("f08-\(slug)-count")
    let expected = "Changes: \(n)"
    let deadline = Date().addingTimeInterval(5)
    while count.label != expected && Date() < deadline { usleep(100_000) }
    XCTAssertEqual(count.label, expected, slug, file: file, line: line)
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
  // change count, which is the last element of every example. The helpers
  // are S04's.
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

  /// One utterance with every run of whitespace made one space.
  private static func normalized(_ utterance: String) -> String {
    utterance.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
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
      // Swipe right until the change count, the last element, is read.
      for _ in 0..<20 {
        do {
          spoken.append(Self.normalized(try voiceOver.moveForward().utterance))
        } catch let error as NSError where S04FunctionalImagesUITests.isNoSpeech(error) {
          let back = Self.normalized(try voiceOver.moveBackward().utterance)
          var again: String? = nil
          do {
            again = Self.normalized(try voiceOver.moveForward().utterance)
          } catch let error as NSError where S04FunctionalImagesUITests.isNoSpeech(error) {}
          spoken.append(S04FunctionalImagesUITests.afterNoSpeech(
            previous: spoken.last, back: back, again: again))
        }
        if spoken.last!.hasPrefix("Changes:") { break }
      }
      try voiceOver.disable()
      voiceOverOn = false
      let content = Self.exampleContent(spoken)
      print("F08VO \(example.slug) | \((content ?? spoken).joined(separator: " / "))")
      XCTAssertNotNil(content, "\(example.slug): the walk did not run from the heading to the count: \(spoken)")
      XCTAssertEqual(content, example.content, example.slug)
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }

  /// The utterances after the last "Example Heading" and before the change
  /// count; nil when the walk did not pass the heading or end on the count.
  static func exampleContent(_ spoken: [String]) -> [String]? {
    guard let last = spoken.last, last.hasPrefix("Changes:"),
          let heading = spoken.lastIndex(of: "Example Heading") else { return nil }
    return Array(spoken[(heading + 1)..<(spoken.count - 1)])
  }
}
