// L3 (tree) and L4 (VoiceOver) for S12 Hiding content from AT on iOS.
// Spec: docs/specs/S12-hiding-content.md.
//
// Texts are found by their labels and the controls and counts by their
// test identifiers. XCUITest cannot see Flutter's keyboard focus: which
// count changed is what shows where a key went.
import XCTest

final class S12HidingContentUITests: XCTestCase, TechniqueUITest {
  static let technique = "S12"
  let app = XCUIApplication()
  private static let quote = "Walk the ridge before the sun is up."
  private static let source = "Trail guide"
  private static let quoteMark = "❝"
  private static let ornament = "✦ ✦ ✦"
  private static let inbox = "Inbox: 3 unread"
  private static let tracking = "Tracking number: 1Z 999"
  private static let show = "Show tracking"
  private static let copy = "Copy number"

  override func setUp() {
    continueAfterFailure = true
  }

  private static let titles = [
    "good-decoration": "Ornaments hidden from AT",
    "good-badge": "Repeated count hidden from AT",
    "good-visibility": "Panel hidden from everyone",
    "bad-decoration-read": "Ornaments read aloud",
    "bad-hidden-control": "Button hidden with an ornament",
    "bad-opacity": "Panel hidden by opacity",
    "bad-maintain": "Panel hidden only from sight",
  ]

  private func title(_ slug: String) -> XCUIElement { element(labelled: Self.titles[slug]!) }

  private func open(_ slug: String, file: StaticString = #filePath, line: UInt = #line) {
    open(slug, waitingFor: title(slug), file: file, line: line)
  }

  /// Waits up to 5 seconds for the count `id` to say `expected`.
  private func expectCount(_ what: String, _ id: String, _ expected: String,
                           file: StaticString = #filePath, line: UInt = #line) {
    let deadline = Date().addingTimeInterval(5)
    while element(id).label != expected && Date() < deadline { usleep(100_000) }
    XCTAssertEqual(element(id).label, expected, what, file: file, line: line)
  }

  /// The count `id` stays `expected` for two seconds: read in a loop.
  private func expectCountStays(_ what: String, _ id: String, _ expected: String,
                                file: StaticString = #filePath, line: UInt = #line) {
    let deadline = Date().addingTimeInterval(2)
    while Date() < deadline {
      if element(id).exists { XCTAssertEqual(element(id).label, expected, what, file: file, line: line) }
      usleep(100_000)
    }
    XCTAssertEqual(element(id).label, expected, what, file: file, line: line)
  }

  /// Every label on the screen, of any type, read from one snapshot.
  private func labels() -> [String] {
    app.descendants(matching: .any).allElementsBoundByIndex.map(\.label).filter { !$0.isEmpty }
  }

  /// How many elements of any type have exactly `label`.
  private func count(labelled label: String) -> Int {
    elements(labelled: label).count
  }

  private func buttonsButBack() -> [String] {
    app.buttons.allElementsBoundByIndex.map(\.label).filter { !$0.isEmpty && $0 != "Back" }
  }

  /// Sends Tab `tabs` times, then `key`, each once, with no modifier.
  private func tabs(_ tabs: Int, then key: String) {
    for _ in 0..<tabs {
      app.typeKey(XCUIKeyboardKey.tab.rawValue, modifierFlags: [])
      usleep(900_000)
    }
    app.typeKey(key, modifierFlags: [])
  }

  /// The switch's value: "0" off, "1" on.
  private func switchValue(_ slug: String) -> String {
    (element("s12-\(slug)-show").value as? String) ?? "(no value)"
  }

  func testGoodDecorationHasTheQuoteAndItsSourceAndNoOrnament() {
    open("good-decoration")
    XCTAssertEqual(count(labelled: Self.quote), 1)
    XCTAssertEqual(count(labelled: Self.source), 1)
    for label in labels() {
      XCTAssertFalse(label.contains(Self.quoteMark), label)
      XCTAssertFalse(label.contains("✦"), label)
    }
  }

  func testGoodBadgeHasTheWordsAloneAndNoElement3() {
    open("good-badge")
    XCTAssertEqual(labels().filter { $0.contains("3") }, [Self.inbox])
    XCTAssertEqual(app.images.count, 0, "the icon is no element")
  }

  func testGoodVisibilityHiddenHasNoPanelElementShownHasIt() {
    open("good-visibility")
    XCTAssertEqual(element("s12-good-visibility-show").elementType, .switch)
    XCTAssertEqual(switchValue("good-visibility"), "0")
    XCTAssertEqual(count(labelled: Self.tracking), 0, "hidden: no number")
    XCTAssertEqual(count(labelled: Self.copy), 0, "hidden: no Copy")
    XCTAssertEqual(buttonsButBack(), [], "hidden: no button but Back")
    // Positive control, in the same launch: shown, the panel is there.
    element("s12-good-visibility-show").tap()
    let deadline = Date().addingTimeInterval(5)
    while switchValue("good-visibility") != "1" && Date() < deadline { usleep(100_000) }
    XCTAssertEqual(count(labelled: Self.tracking), 1, "shown: the number")
    XCTAssertEqual(element("s12-good-visibility-copy").elementType, .button)
    XCTAssertEqual(element("s12-good-visibility-copy").label, Self.copy)
    element("s12-good-visibility-copy").tap()
    expectCount("good-visibility: a tap on Copy", "s12-good-visibility-count", "Copies: 1")
  }

  /// The probe found the first Tab on Back and each later Tab on the next
  /// control (docs/evidence/probes/s12/ios.txt), and, with the panel
  /// hidden in `Visibility(maintainState: true)`, the third Tab back on Back
  /// (p07: three Tabs and Return left the screen). Hidden, three Tabs and
  /// the key leave the screen: there is no stop between the switch and
  /// Back, so the keyboard does not reach Copy. Positive control, from a
  /// fresh launch, the same keys: shown first, three Tabs and the key copy.
  func testGoodVisibilityTheKeyboardReachesCopyOnlyOnceItIsShown() {
    for (key, name) in [("\n", "Return"), (" ", "Space")] {
      open("good-visibility")
      tabs(3, then: key)
      let deadline = Date().addingTimeInterval(5)
      while title("good-visibility").exists && Date() < deadline { usleep(100_000) }
      XCTAssertFalse(title("good-visibility").exists,
                     "hidden: three Tabs and \(name) landed on Back and left the screen")
      open("good-visibility")
      element("s12-good-visibility-show").tap()
      let shown = Date().addingTimeInterval(5)
      while switchValue("good-visibility") != "1" && Date() < shown { usleep(100_000) }
      tabs(3, then: key)
      expectCount("good-visibility shown: three Tabs then \(name)", "s12-good-visibility-count", "Copies: 1")
      XCTAssertTrue(title("good-visibility").exists, "shown: the screen is still open")
    }
  }

  func testBadDecorationReadHasEachOrnamentAsAnElement() {
    open("bad-decoration-read")
    for text in [Self.quoteMark, Self.quote, Self.source, Self.ornament] {
      XCTAssertEqual(count(labelled: text), 1, text)
    }
  }

  func testBadHiddenControlHasNoShareAndTheKeyboardRunsIt() {
    open("bad-hidden-control")
    XCTAssertEqual(count(labelled: "Share"), 0, "no element is Share")
    XCTAssertEqual(buttonsButBack(), [], "no button but Back")
    for (key, name) in [("\n", "Return"), (" ", "Space")] {
      open("bad-hidden-control")
      tabs(2, then: key)
      expectCount("bad-hidden-control: two Tabs then \(name)", "s12-bad-hidden-control-count", "Shares: 1")
      XCTAssertTrue(title("bad-hidden-control").exists, "the screen is still open")
    }
    // Positive control: one Tab and Return are on Back, and leave the screen.
    open("bad-hidden-control")
    tabs(1, then: "\n")
    let deadline = Date().addingTimeInterval(5)
    while title("bad-hidden-control").exists && Date() < deadline { usleep(100_000) }
    XCTAssertFalse(title("bad-hidden-control").exists, "one Tab and Return left the screen")
  }

  func testBadHiddenControlATapWhereShareIsDrawnShares() {
    open("bad-hidden-control")
    let quote = element(labelled: Self.quote).frame
    let count = element("s12-bad-hidden-control-count").frame
    let y = (quote.maxY + count.minY) / 2
    for fraction in [0.30, 0.40, 0.50] {
      let x = quote.minX + quote.width * fraction
      app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: x, dy: y)).tap()
      usleep(800_000)
      if element("s12-bad-hidden-control-count").label == "Shares: 1" { return }
    }
    XCTFail("no tap between the quote and the count shared")
  }

  func testBadOpacityHiddenHasNoPanelElementAndTheKeyboardAndATapCopy() {
    open("bad-opacity")
    XCTAssertEqual(count(labelled: Self.tracking), 0, "hidden: no number")
    XCTAssertEqual(count(labelled: Self.copy), 0, "hidden: no Copy")
    XCTAssertEqual(buttonsButBack(), [], "hidden: no button but Back")
    for (key, name) in [("\n", "Return"), (" ", "Space")] {
      open("bad-opacity")
      tabs(3, then: key)
      expectCount("bad-opacity hidden: three Tabs then \(name)", "s12-bad-opacity-count", "Copies: 1")
      XCTAssertEqual(switchValue("bad-opacity"), "0", "the switch is still off")
    }
    open("bad-opacity")
    let s = element("s12-bad-opacity-show").frame
    let c = element("s12-bad-opacity-count").frame
    app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: s.minX + 40, dy: c.minY - 20)).tap()
    expectCount("bad-opacity hidden: a tap where Copy is laid out", "s12-bad-opacity-count", "Copies: 1")
    XCTAssertEqual(switchValue("bad-opacity"), "0", "the switch is still off")
  }

  func testBadMaintainHiddenHasThePanelElementsAndTheKeyboardCopies() {
    open("bad-maintain")
    XCTAssertEqual(switchValue("bad-maintain"), "0")
    XCTAssertEqual(count(labelled: Self.tracking), 1, "hidden, and still there: the number")
    XCTAssertEqual(element("s12-bad-maintain-copy").elementType, .button)
    XCTAssertEqual(element("s12-bad-maintain-copy").label, Self.copy)
    open("bad-maintain")
    tabs(3, then: "\n")
    expectCount("bad-maintain hidden: three Tabs then Return", "s12-bad-maintain-count", "Copies: 1")
    XCTAssertEqual(switchValue("bad-maintain"), "0", "the switch is still off")
  }

  // L4. Everything VoiceOver says after the "Example" heading, to the end of
  // the screen (C03Walk), compared as a whole list, so a stop after the
  // expected ones fails the test too. Utterances are cut at 64 characters;
  // every one here is shorter, which the test checks.
  private static let speech: [(slug: String, content: [String])] = [
    ("good-decoration", [quote, source]),
    ("good-badge", [inbox]),
    ("good-visibility", ["\(show) Switch button off Double tap to toggle setting.", "Copies: 0"]),
    ("bad-decoration-read", [quoteMark, quote, source, ornament]),
    ("bad-hidden-control", [quote, "Shares: 0"]),
    ("bad-opacity", ["\(show) Switch button off Double tap to toggle setting.", "Copies: 0"]),
    ("bad-maintain", ["\(show) Switch button off Double tap to toggle setting.", tracking, "\(copy) Button", "Copies: 0"]),
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
      print("S12VO \(example.slug) | \((content ?? walk.stops).joined(separator: " / "))")
      XCTAssertNotNil(content, "\(example.slug): the walk did not run from the heading to the end: \(walk)")
      XCTAssertEqual(content, example.content, example.slug)
    }
    #else
    throw XCTSkip("XCUIVoiceOverService needs Xcode 27 or later")
    #endif
  }
}
