// L3 (tree) and L4 (VoiceOver) for S09 Content grouping on iOS.
// Spec: docs/specs/S09-content-grouping.md.
//
// Texts are found by their labels and the controls and status lines by
// their test identifiers. XCUITest gives no hierarchy and cannot read
// traits, so whether the buttons sit inside the group is not seen here; the
// VoiceOver walk checks what is read, and in what order.
import XCTest

final class S09ContentGroupingUITests: XCTestCase, TechniqueUITest {
  static let technique = "S09"
  let app = XCUIApplication()
  private static let group = "Kitchen light"
  private static let target = "App information"
  private static let facts = [("City", "Boston"), ("Founded", "1630")]

  override func setUp() {
    continueAfterFailure = true
  }

  private static let titles = [
    "good-merged-facts": "Each label merged with its value",
    "good-cupertino": "Cupertino rows, each one element",
    "good-named-group": "Buttons in a group named by its question",
    "good-tap-target": "Icon and text as one button",
    "bad-split-facts": "Labels and values in separate rows",
    "bad-merged-group": "Question and buttons merged",
  ]

  private func title(_ slug: String) -> XCUIElement { element(labelled: Self.titles[slug]!) }

  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    open(slug, waitingFor: title(slug), file: file, line: line)
  }

  /// Waits up to 5 seconds for the status line `id` to say `expected`.
  private func expectStatus(_ what: String, _ id: String, _ expected: String,
                            file: StaticString = #filePath, line: UInt = #line) {
    let deadline = Date().addingTimeInterval(5)
    while element(id).label != expected && Date() < deadline { usleep(100_000) }
    XCTAssertEqual(element(id).label, expected, what, file: file, line: line)
  }

  /// Every element of the screen with a label, of `type`.
  private func labelled(_ type: XCUIElement.ElementType) -> [String] {
    app.descendants(matching: type).allElementsBoundByIndex.map(\.label).filter { !$0.isEmpty }
  }

  /// How many elements of any type have exactly `label`.
  private func count(labelled label: String) -> Int {
    app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).count
  }

  /// Each label and its value: one element with both, none with either alone.
  private func expectMergedFacts(file: StaticString = #filePath, line: UInt = #line) {
    for (label, value) in Self.facts {
      XCTAssertEqual(count(labelled: "\(label)\n\(value)"), 1, "\(label) and its value, one element", file: file, line: line)
      XCTAssertEqual(count(labelled: label), 0, "no element is \(label) alone", file: file, line: line)
      XCTAssertEqual(count(labelled: value), 0, "no element is \(value) alone", file: file, line: line)
    }
    XCTAssertEqual(labelled(.button).filter { $0 != "Back" }, [], "no button but Back", file: file, line: line)
  }

  func testGoodMergedFactsHasEachLabelAndValueAsOneElement() {
    open("good-merged-facts")
    expectMergedFacts()
  }

  func testGoodCupertinoHasEachRowAsOneElement() {
    open("good-cupertino")
    expectMergedFacts()
  }

  func testGoodNamedGroupHasTheQuestionAndTwoButtonsThatDoNotCarryIt() {
    open("good-named-group")
    XCTAssertEqual(count(labelled: Self.group), 1, "the group's name, once")
    XCTAssertEqual(labelled(.button).filter { $0 != "Back" }, ["On", "Off"])
    for id in ["s09-good-named-group-on", "s09-good-named-group-off"] {
      XCTAssertEqual(element(id).elementType, .button, id)
      XCTAssertFalse(element(id).label.contains(Self.group), "\(id) does not carry the group's name")
    }
  }

  func testGoodTapTargetIsOneButtonNamedByItsText() {
    open("good-tap-target")
    let button = element("s09-good-tap-target-info")
    XCTAssertEqual(button.elementType, .button)
    XCTAssertEqual(button.label, Self.target)
    XCTAssertEqual(labelled(.button).filter { $0 != "Back" }, [Self.target])
    XCTAssertEqual(app.images.count, 0, "the icon is no element of its own")
  }

  /// The controls of each example that has any, with the status line each
  /// changes and what it then says.
  private let controls: [(slug: String, id: String, status: String, after: String)] = [
    ("good-named-group", "s09-good-named-group-on", "s09-good-named-group-status", "Light: on"),
    ("good-named-group", "s09-good-named-group-off", "s09-good-named-group-status", "Light: off"),
    ("good-tap-target", "s09-good-tap-target-info", "s09-good-tap-target-opens", "Opens: 1"),
  ]

  func testEachControlDoesItsOwnActionByATap() {
    for c in controls {
      open(c.slug)
      XCTAssertNotEqual(element(c.status).label, c.after, "\(c.slug) before")
      element(c.id).tap()
      expectStatus("\(c.slug): a tap on \(c.id)", c.status, c.after)
    }
  }

  /// XCUITest cannot see Flutter's keyboard focus. The probe found the first
  /// Tab on Back and each later Tab on the next control, in order
  /// (docs/evidence/probes/s09/ios.txt): so `tabs` Tabs reach the control,
  /// and what the status line says tells which control the key reached.
  /// Each key is sent once, from a fresh launch; no modifier is used.
  private let keyStops: [(slug: String, tabs: Int, status: String, after: String)] = [
    ("good-named-group", 2, "s09-good-named-group-status", "Light: on"),
    ("good-named-group", 3, "s09-good-named-group-status", "Light: off"),
    ("good-tap-target", 2, "s09-good-tap-target-opens", "Opens: 1"),
  ]

  func testEachControlDoesItsOwnActionByTabThenEnterOrSpace() {
    for k in keyStops {
      for (key, name) in [("\n", "Enter"), (" ", "Space")] {
        open(k.slug)
        for _ in 0..<k.tabs {
          app.typeKey(XCUIKeyboardKey.tab.rawValue, modifierFlags: [])
          usleep(700_000)
        }
        app.typeKey(key, modifierFlags: [])
        expectStatus("\(k.slug): \(k.tabs) Tabs then \(name)", k.status, k.after)
      }
    }
  }

  func testBadSplitFactsHasFourElementsAndNoMergedOne() {
    open("bad-split-facts")
    for text in ["City", "Founded", "Boston", "1630"] {
      XCTAssertEqual(count(labelled: text), 1, "\(text) on its own")
    }
    for (label, value) in Self.facts {
      XCTAssertEqual(count(labelled: "\(label)\n\(value)"), 0, "\(label) is not joined to its value")
    }
  }

  func testBadMergedGroupIsOneButtonAndOffIsNoElement() {
    open("bad-merged-group")
    let merged = element("s09-bad-merged-group-light")
    XCTAssertEqual(merged.elementType, .button)
    XCTAssertEqual(merged.label, "\(Self.group)\nOn\nOff")
    XCTAssertEqual(labelled(.button).filter { $0 != "Back" }, ["\(Self.group)\nOn\nOff"])
    XCTAssertEqual(count(labelled: "Off"), 0, "no element is Off")
    XCTAssertEqual(count(labelled: "On"), 0, "no element is On")
  }

  // L4. Everything VoiceOver says after the "Example" heading, to the end of
  // the screen (C03Walk), compared as a whole list, so a stop after the
  // expected ones fails the test too. Utterances are cut at 64 characters;
  // every one here is shorter, which the test checks.
  private static let speech: [(slug: String, content: [String])] = [
    ("good-merged-facts", ["City Boston", "Founded 1630"]),
    ("good-cupertino", ["City Boston", "Founded 1630"]),
    // The group's name is a stop of its own, and the buttons are read
    // without it (FL-320).
    ("good-named-group", [group, "On Button", "Off Button", "Light: not set"]),
    ("good-tap-target", ["\(target) Button", "Opens: 0"]),
    // Bad examples: the defect must be audible. Both labels, then both
    // values.
    ("bad-split-facts", ["City", "Founded", "Boston", "1630"]),
    // One button, the question and both buttons' words.
    ("bad-merged-group", ["\(group) On Off Button", "Light: not set"]),
  ]

  func testVoiceOverSpeech() throws {
    for example in Self.speech {
      for utterance in example.content {
        XCTAssertLessThan(utterance.count, 64, "\(example.slug): \"\(utterance)\" is longer than the service returns")
      }
    }
    #if compiler(>=6.4)
    guard #available(iOS 27.0, *) else { throw XCTSkip("XCUIVoiceOverService needs iOS 27") }
    let voiceOver = XCUIDevice.shared.voiceOverService
    for example in Self.speech {
      open(example.slug)
      let walk = try C03Walk.walk(voiceOver)
      let content = C03Walk.content(walk)
      print("S09VO \(example.slug) | \((content ?? walk.stops).joined(separator: " / "))")
      XCTAssertNotNil(content, "\(example.slug): the walk did not run from the heading to the end: \(walk)")
      XCTAssertEqual(content, example.content, example.slug)
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}
