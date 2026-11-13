// L3 (tree) and L4 (VoiceOver) for F01 Text fields and labels on iOS.
// Spec: docs/specs/F01-text-fields.md.
import XCTest

final class F01TextFieldsUITests: XCTestCase {
  private let app = XCUIApplication()

  override func setUp() {
    continueAfterFailure = true
  }

  private func element(_ id: String) -> XCUIElement {
    app.descendants(matching: .any)[id]
  }

  private func element(labelled label: String) -> XCUIElement {
    app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch
  }

  /// Cold-starts the app on one example through the `fluttera11y` URL scheme,
  /// trying up to three times (see C01ButtonUITests.open).
  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    let url = URL(string: "fluttera11y:///t/F01/\(slug)")!
    for attempt in 1...3 {
      app.terminate()
      app.open(url)
      if element(labelled: "Example").waitForExistence(timeout: 30) { return }
      print("F01 open \(slug): attempt \(attempt) did not show the example")
    }
    XCTFail("\(slug) did not open after three attempts", file: file, line: line)
  }

  /// Types into a field and leaves it, so the keyboard is gone.
  private func type(_ text: String, into id: String) {
    let field = element(id)
    field.tap()
    field.typeText(text + "\n")
    let deadline = Date().addingTimeInterval(5)
    while (field.value as? String) != text && Date() < deadline { usleep(100_000) }
  }

  private func describe(_ id: String) -> String {
    let e = element(id)
    return "id=\(id) type=\(e.elementType.rawValue) label='\(e.label)' value='\(e.value as? String ?? "nil")' placeholder='\(e.placeholderValue ?? "nil")'"
  }

  private let good: [(slug: String, fields: [(id: String, name: String)])] = [
    ("good-label", [("f01-good-label-email", "Email")]),
    ("good-label-above", [("f01-good-label-above-name", "Full name")]),
    ("good-cupertino", [("f01-good-cupertino-email", "Email")]),
  ]

  func testGoodFieldsKeepTheirNameWhenFilled() {
    for example in good {
      open(example.slug)
      for field in example.fields {
        print("F01TREE EMPTY \(describe(field.id))")
        let e = element(field.id)
        XCTAssertEqual(e.elementType, .textField, field.id)
        XCTAssertEqual(e.label, field.name, field.id)
        type("abc", into: field.id)
        print("F01TREE TYPED \(describe(field.id))")
        XCTAssertEqual(e.value as? String, "abc", field.id)
        XCTAssertEqual(e.label, field.name, "\(field.id) after typing")
      }
    }
  }

  func testGoodMultilineFieldHasAName() {
    open("good-label")
    print("F01TREE EMPTY \(describe("f01-good-label-message"))")
    XCTAssertEqual(element("f01-good-label-message").label, "Message")
  }

  // VAL-3: each bad example is asserted to have its named defect.

  func testBadPlaceholderFieldsLoseTheirNameWhenFilled() {
    for (slug, id) in [("bad-placeholder-only", "f01-bad-placeholder-only-email"),
                       ("bad-cupertino-placeholder", "f01-bad-cupertino-placeholder-email")] {
      open(slug)
      print("F01TREE EMPTY \(describe(id))")
      XCTAssertEqual(element(id).label, "Email", "\(id) while empty")
      type("abc", into: id)
      print("F01TREE TYPED \(describe(id))")
      XCTAssertEqual(element(id).label, "", "\(id) after typing")
    }
  }

  func testBadFieldsWithNoNameHaveNoName() {
    for (slug, id) in [("bad-unassociated-label", "f01-bad-unassociated-label-email"),
                       ("bad-no-label", "f01-bad-no-label-search"),
                       ("bad-cupertino-prefix", "f01-bad-cupertino-prefix-email")] {
      open(slug)
      print("F01TREE EMPTY \(describe(id))")
      XCTAssertEqual(element(id).elementType, .textField, id)
      XCTAssertEqual(element(id).label, "", id)
    }
  }

  func testBadNameMismatchLacksTheVisibleLabel() {
    open("bad-name-mismatch")
    XCTAssertEqual(element("f01-bad-name-mismatch-email").label, "Contact address")
  }

  // L4. What VoiceOver speaks while swiping through each example. A slug
  // listed with a field id is walked after "abc" has been typed into it.
  // (slug, field to fill, phrases that must be spoken, must not be spoken).
  private let speech: [(slug: String, fill: String?, must: [String], mustNot: [String])] = [
    ("good-label", nil, ["Email Text field Double tap to edit.", "Message Text field Double tap to edit."], []),
    // The label is still spoken once the field has a value.
    ("good-label", "f01-good-label-email", ["Email abc Text field Double tap to edit."], []),
    // The visible label is not read a second time as separate text.
    ("good-label-above", nil, ["Full name Text field Double tap to edit."], ["Full name"]),
    ("good-cupertino", nil, ["Email Text field Double tap to edit."], ["Email"]),
    // Bad examples: the defect must be audible.
    ("bad-placeholder-only", nil, ["Email Text field Double tap to edit."], []),
    ("bad-placeholder-only", "f01-bad-placeholder-only-email",
     ["abc Text field Double tap to edit."], ["Email abc Text field Double tap to edit."]),
    // "Email" is read as its own text, then a field with no name.
    ("bad-unassociated-label", nil, ["Email", "Text field Double tap to edit."], ["Email Text field Double tap to edit."]),
    ("bad-no-label", nil, ["Text field Double tap to edit."], []),
    ("bad-name-mismatch", nil, ["Contact address Text field Double tap to edit."], ["Email Text field Double tap to edit."]),
    ("bad-cupertino-placeholder", nil, ["Email Text field Double tap to edit."], []),
    ("bad-cupertino-placeholder", "f01-bad-cupertino-placeholder-email",
     ["abc Text field Double tap to edit."], ["Email abc Text field Double tap to edit."]),
    ("bad-cupertino-prefix", nil, ["Email", "Text field Double tap to edit."], ["Email Text field Double tap to edit."]),
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
      if let id = example.fill { type("abc", into: id) }
      try voiceOver.enable()
      var spoken: [String] = []
      // Swipe right to the end of the screen: the last element repeats.
      for _ in 0..<24 {
        guard let utterance = try? voiceOver.moveForward().utterance else { continue }
        let text = utterance.replacingOccurrences(of: "\n", with: " ")
        if spoken.last == text { break }
        spoken.append(text)
      }
      try voiceOver.disable()
      let name = example.slug + (example.fill == nil ? "" : "+filled")
      print("F01VO \(name) | \(spoken.joined(separator: " / "))")
      for phrase in example.must {
        XCTAssertTrue(spoken.contains(phrase), "\(name): expected \"\(phrase)\" in \(spoken)")
      }
      for phrase in example.mustNot {
        XCTAssertFalse(spoken.contains(phrase), "\(name): did not expect \"\(phrase)\" in \(spoken)")
      }
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}
