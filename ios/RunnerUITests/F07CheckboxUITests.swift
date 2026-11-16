// L3 (tree) and L4 (VoiceOver) for F07 Checkbox on iOS.
// Spec: docs/specs/F07-checkbox.md.
//
// iOS has no checkbox. Flutter exposes one as a switch (FL-035): XCUITest
// sees `.switch` with the value "0" or "1", and VoiceOver reads "Switch
// button, on" or "off". A mixed checkbox is "0" and "off" (FL-044).
import XCTest

final class F07CheckboxUITests: XCTestCase {
  private let app = XCUIApplication()

  override func setUp() {
    continueAfterFailure = true
  }

  /// Cold-starts the app on one example through the `fluttera11y` URL scheme,
  /// trying up to three times (see C01ButtonUITests.open).
  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    let url = URL(string: "fluttera11y:///t/F07/\(slug)")!
    for attempt in 1...3 {
      app.terminate()
      app.open(url)
      if element("f07-\(slug)-count").waitForExistence(timeout: 30) { return }
      print("F07 open \(slug): attempt \(attempt) did not show the example")
    }
    XCTFail("\(slug) did not open after three attempts", file: file, line: line)
  }

  private func element(_ id: String) -> XCUIElement {
    app.descendants(matching: .any)[id]
  }

  private func expectCount(_ slug: String, _ n: Int, file: StaticString = #filePath, line: UInt = #line) {
    let count = element("f07-\(slug)-count")
    let expected = "Changes: \(n)"
    let deadline = Date().addingTimeInterval(5)
    while count.label != expected && Date() < deadline { usleep(100_000) }
    XCTAssertEqual(count.label, expected, slug, file: file, line: line)
  }

  private static let updates = "Email me product updates"

  private func value(_ id: String) -> String { element(id).value as? String ?? "" }

  private func expectValue(_ id: String, _ expected: String, file: StaticString = #filePath, line: UInt = #line) {
    let deadline = Date().addingTimeInterval(5)
    while value(id) != expected && Date() < deadline { usleep(100_000) }
    XCTAssertEqual(value(id), expected, id, file: file, line: line)
  }

  // slug, identifier, label. Each starts not checked.
  private let boxes: [(slug: String, id: String, label: String)] = [
    ("good-tile", "f07-good-tile-updates", updates),
    ("good-cupertino", "f07-good-cupertino-updates", updates),
    ("good-custom", "f07-good-custom-updates", updates),
    ("good-group", "f07-good-group-phone", "Phone"),
    ("good-group", "f07-good-group-post", "Post"),
    ("bad-group-unlabelled", "f07-bad-group-unlabelled-phone", "Phone"),
  ]

  func testCheckboxesHaveTheirNameAndStateAsSwitches() {
    for box in boxes {
      open(box.slug)
      let element = element(box.id)
      // Flutter 3.47.5: a checkbox is a switch on iOS (FL-035). Written to
      // fail if the type changes.
      XCTAssertEqual(element.elementType, .switch, box.id)
      XCTAssertEqual(element.label, box.label, box.id)
      XCTAssertEqual(value(box.id), "0", box.id)
      XCTAssertTrue(element.isEnabled, box.id)
      // The label is part of the control, not a text element of its own.
      XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label == %@", box.label)).count, 0, box.id)
      element.tap()
      expectValue(box.id, "1")
      XCTAssertEqual(self.element(box.id).label, box.label, box.id)
      element.tap()
      expectValue(box.id, "0")
    }
  }

  func testGoodMixedIsExposedAsOff() {
    open("good-mixed")
    let all = "f07-good-mixed-all"
    XCTAssertEqual(element(all).elementType, .switch)
    XCTAssertEqual(element(all).label, "Select all")
    XCTAssertEqual(value("f07-good-mixed-email"), "1")
    XCTAssertEqual(value("f07-good-mixed-text"), "0")
    // Flutter 3.47.5: the iOS engine sets the switch on only for a checked
    // box, so mixed is "0", the same as not checked (FL-044). Written to
    // fail if a mixed checkbox starts to be told apart.
    XCTAssertEqual(value(all), "0")
    // From mixed, "Select all" checks both; from checked, it clears both.
    element(all).tap()
    expectValue(all, "1")
    expectValue("f07-good-mixed-text", "1")
    element(all).tap()
    expectValue(all, "0")
    expectValue("f07-good-mixed-email", "0")
  }

  func testGoodGroupHasTheQuestionAsOneElement() {
    open("good-group")
    let group = element("f07-good-group-contact")
    XCTAssertEqual(group.elementType, .other)
    XCTAssertEqual(group.label, "Contact me by")
    // Once: the visible text is not a second element.
    let withQuestion = app.descendants(matching: .any)
      .matching(NSPredicate(format: "label == %@", "Contact me by"))
    XCTAssertEqual(withQuestion.count, 1)
    XCTAssertEqual(app.switches.count, 2)
  }

  func testBadUnlabelledHasASwitchWithNoLabel() {
    open("bad-unlabelled")
    XCTAssertEqual(app.switches.count, 1)
    XCTAssertEqual(app.switches.firstMatch.label, "")
    XCTAssertTrue(app.staticTexts[Self.updates].exists)
  }

  func testBadNoStateIsAButtonWithNoValue() {
    open("bad-no-state")
    let id = "f07-bad-no-state-updates"
    XCTAssertEqual(app.switches.count, 0)
    for taps in 1...2 {
      XCTAssertEqual(element(id).elementType, .button)
      XCTAssertEqual(element(id).label, Self.updates)
      XCTAssertEqual(value(id), "")
      XCTAssertFalse(element(id).isSelected)
      element(id).tap()
      expectCount("bad-no-state", taps)
    }
  }

  func testBadMixedAsUncheckedIsOffWhileOneBoxIsOn() {
    open("bad-mixed-as-unchecked")
    XCTAssertEqual(value("f07-bad-mixed-as-unchecked-email"), "1")
    XCTAssertEqual(value("f07-bad-mixed-as-unchecked-text"), "0")
    XCTAssertEqual(value("f07-bad-mixed-as-unchecked-all"), "0")
  }

  func testBadGroupUnlabelledHasTheQuestionAsPlainText() {
    open("bad-group-unlabelled")
    XCTAssertTrue(app.staticTexts["Contact me by"].exists)
    XCTAssertEqual(app.switches.count, 2)
  }

  // L4. Everything VoiceOver says between the "Example" heading and the
  // change count, which is the last element of every example. The helpers
  // are S04's. XCUIVoiceOverService returns at most the first 64 characters
  // of an utterance, which cuts the longest of these short.
  private let speech: [(slug: String, content: [String])] = [
    // A checkbox is read as a switch, "off" for not checked (FL-035). The
    // long name leaves no room for the last word of the usage hint.
    ("good-tile", ["Email me product updates Switch button off Double tap to toggle"]),
    ("good-cupertino", ["Email me product updates Switch button off Double tap to toggle"]),
    ("good-custom", ["Email me product updates Switch button off Double tap to toggle"]),
    // "Select all" is mixed and is read "off" (FL-044). Written to fail if
    // VoiceOver starts to say anything else for it.
    ("good-mixed", [
      "Select all Switch button off Double tap to toggle setting.",
      "Email Switch button on Double tap to toggle setting.",
      "Text message Switch button off Double tap to toggle setting.",
    ]),
    // The question is a stop of its own, read once, before the boxes.
    ("good-group", [
      "Contact me by",
      "Phone Switch button off Double tap to toggle setting.",
      "Post Switch button off Double tap to toggle setting.",
    ]),
    // Bad examples: the defect must be audible where it can be.
    ("bad-unlabelled", ["Switch button off Double tap to toggle setting.", "Email me product updates"]),
    ("bad-no-state", ["Email me product updates Button"]),
    // The same words as good-mixed: on iOS the two cannot be told apart.
    ("bad-mixed-as-unchecked", [
      "Select all Switch button off Double tap to toggle setting.",
      "Email Switch button on Double tap to toggle setting.",
      "Text message Switch button off Double tap to toggle setting.",
    ]),
    // The same words as good-group: read in order, the question comes
    // first either way. The difference is in the tree.
    ("bad-group-unlabelled", [
      "Contact me by",
      "Phone Switch button off Double tap to toggle setting.",
      "Post Switch button off Double tap to toggle setting.",
    ]),
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
      print("F07VO \(example.slug) | \((content ?? spoken).joined(separator: " / "))")
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
