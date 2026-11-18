// L3 (tree) and L4 (VoiceOver) for F09 Switch on iOS.
// Spec: docs/specs/F09-switch.md.
//
// A Flutter switch is backed by a native UISwitch on iOS: XCUITest sees
// `.switch` with the value "0" or "1", and VoiceOver reads "Switch button,
// on" or "off".
import XCTest

final class F09SwitchUITests: XCTestCase, CountedTechniqueUITest {
  static let technique = "F09"
  static let countLabel = "Changes"
  let app = XCUIApplication()

  override func setUp() {
    continueAfterFailure = true
  }

  /// Opens an example and waits for its count.
  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    open(slug, waitingFor: countElement(slug), file: file, line: line)
  }

  private static let bluetooth = "Bluetooth"

  private func value(_ element: XCUIElement) -> String { element.value as? String ?? "" }

  private func expectValue(
    _ element: @autoclosure () -> XCUIElement, _ expected: String, _ what: String,
    file: StaticString = #filePath, line: UInt = #line
  ) {
    let deadline = Date().addingTimeInterval(5)
    while value(element()) != expected && Date() < deadline { usleep(100_000) }
    XCTAssertEqual(value(element()), expected, what, file: file, line: line)
  }

  // slug, identifier, label. Each starts off.
  private let controls: [(slug: String, id: String, label: String)] = [
    ("good-tile", "f09-good-tile-bluetooth", bluetooth),
    ("good-cupertino", "f09-good-cupertino-bluetooth", bluetooth),
    ("good-custom", "f09-good-custom-bluetooth", bluetooth),
    ("good-group", "f09-good-group-messages", "Messages"),
    ("good-group", "f09-good-group-reminders", "Reminders"),
  ]

  func testSwitchesHaveTheirNameAndState() {
    for control in controls {
      open(control.slug)
      let element = element(control.id)
      XCTAssertEqual(element.elementType, .switch, control.id)
      XCTAssertEqual(element.label, control.label, control.id)
      XCTAssertEqual(value(element), "0", control.id)
      // Enabled: good-custom has enabled: true, without which it would not
      // be (FL-033).
      XCTAssertTrue(element.isEnabled, control.id)
      // The label is part of the control, not a text element of its own.
      XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label == %@", control.label)).count, 0, control.id)
      element.tap()
      expectValue(self.element(control.id), "1", control.id)
      XCTAssertEqual(self.element(control.id).label, control.label, control.id)
      element.tap()
      expectValue(self.element(control.id), "0", control.id)
      expectCount(control.slug, 2)
    }
  }

  func testGoodGroupHasTheQuestionAsOneElement() {
    open("good-group")
    let group = element("f09-good-group-notify")
    XCTAssertEqual(group.elementType, .other)
    XCTAssertEqual(group.label, "Notify me about")
    // Once: the visible text is not a second element.
    XCTAssertEqual(elements(labelled: "Notify me about").count, 1)
    XCTAssertEqual(app.switches.count, 2)
  }

  func testBadUnlabelledHasASwitchWithNoLabel() {
    open("bad-unlabelled")
    XCTAssertEqual(app.switches.count, 1)
    XCTAssertEqual(app.switches.firstMatch.label, "")
    XCTAssertTrue(app.staticTexts[Self.bluetooth].exists)
  }

  func testBadTileNotMergedIsAButtonAndASwitchWithNoLabel() {
    open("bad-tile-not-merged")
    let row = app.buttons[Self.bluetooth]
    XCTAssertTrue(row.exists)
    XCTAssertEqual(value(row), "")
    XCTAssertEqual(app.switches.count, 1)
    XCTAssertEqual(app.switches.firstMatch.label, "")
    XCTAssertEqual(value(app.switches.firstMatch), "0")
    row.tap()
    expectCount("bad-tile-not-merged", 1)
    expectValue(self.app.switches.firstMatch, "1", "the switch")
    // The row still says nothing about the state.
    XCTAssertEqual(value(app.buttons[Self.bluetooth]), "")
  }

  func testBadLabelChangesHasALabelThatChangesWithTheState() {
    open("bad-label-changes")
    let id = "f09-bad-label-changes-bluetooth"
    XCTAssertEqual(element(id).elementType, .switch)
    XCTAssertEqual(element(id).label, "Bluetooth off")
    XCTAssertEqual(value(element(id)), "0")
    element(id).tap()
    expectValue(self.element(id), "1", id)
    XCTAssertEqual(element(id).label, "Bluetooth on")
  }

  func testBadNoStateIsAButtonWithNoValue() {
    open("bad-no-state")
    let id = "f09-bad-no-state-bluetooth"
    XCTAssertEqual(app.switches.count, 0)
    for taps in 1...2 {
      XCTAssertEqual(element(id).elementType, .button)
      XCTAssertEqual(element(id).label, Self.bluetooth)
      XCTAssertEqual(value(element(id)), "")
      XCTAssertFalse(element(id).isSelected)
      element(id).tap()
      expectCount("bad-no-state", taps)
    }
  }

  // L4. Everything VoiceOver says between the "Example" heading and the
  // change count, which is the last element of every example. The walk
  // is VoiceOverWalk.forward.
  private let speech: [(slug: String, content: [String])] = [
    ("good-tile", ["Bluetooth Switch button off Double tap to toggle setting."]),
    ("good-cupertino", ["Bluetooth Switch button off Double tap to toggle setting."]),
    ("good-custom", ["Bluetooth Switch button off Double tap to toggle setting."]),
    // The question is a stop of its own, read once, before the switches.
    ("good-group", [
      "Notify me about",
      "Messages Switch button off Double tap to toggle setting.",
      "Reminders Switch button off Double tap to toggle setting.",
    ]),
    // Bad examples: the defect must be audible where it can be.
    ("bad-unlabelled", ["Bluetooth", "Switch button off Double tap to toggle setting."]),
    ("bad-tile-not-merged", ["Bluetooth Button", "Switch button off Double tap to toggle setting."]),
    ("bad-label-changes", ["Bluetooth off Switch button off Double tap to toggle setting."]),
    ("bad-no-state", ["Bluetooth Button"]),
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
      print("F09VO \(example.slug) | \((content ?? spoken).joined(separator: " / "))")
      XCTAssertNotNil(content, "\(example.slug): the walk did not run from the heading to the count: \(spoken)")
      XCTAssertEqual(content, example.content, example.slug)
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}
